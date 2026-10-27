## Sim lab: runs many weekends without graphics and measures the
## simulation against its target values (docs/simulation_model.md, 14).
## Race i runs on calendar track i % 24, like a season. Only changes the
## in-memory test world.
## Usage: godot --headless --path . res://tools/sim_lab.tscn -- <scenario> [races] [track id]
## Scenarios: single, tracks, baseline, dominant_top, dominant_weak, close_field,
##            top_driver_midfield, staff, engineers, rain, setup, strategy, track, all
extends Node

const DEFAULT_RACES := 48
const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
const ALL := ["baseline", "dominant_top", "dominant_weak", "close_field", "top_driver_midfield",
	"staff", "crew", "strategist", "engineers", "rain", "setup", "strategy", "track"]

var races := DEFAULT_RACES
var single_track: StringName = &"harrow_park"
var calendar: Array[StringName] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := args[0] if args.size() > 0 else "single"
	if args.size() > 1:
		races = int(args[1])
	if args.size() > 2:
		single_track = StringName(args[2])
	var started := Time.get_ticks_msec()
	for s in (ALL if scenario == "all" else [scenario]):
		_run_scenario(s)
	print("\nDone in %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	get_tree().quit()


func _run_scenario(name: String) -> void:
	TestWorld.build()
	calendar = GameState.series[&"f1"].calendar
	print("\n==================== %s ====================" % name.to_upper())
	call("_scenario_" + name)


# --- Running weekends ------------------------------------------------------

func track_of(i: int) -> TrackData:
	return GameState.tracks[calendar[i % calendar.size()]]


## Practice + qualifying + race on one track. make_conditions(model, rng)
## returns the RaceConditions (default: the track's own conditions).
func weekend(cars: Array[SimCar], track: TrackData, seed_value: int, make_conditions := Callable(),
		variant := {}) -> RaceEngine:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var model := TrackModel.build(track, variant)
	var conditions: RaceConditions = make_conditions.call(model, rng) if make_conditions.is_valid() \
		else RaceConditions.for_track(model, rng)
	conditions.ensure_weather(rng)
	var practice_wet := 0.0 if rng.randf() > conditions.rain_chance * 0.5 else rng.randf_range(0.3, 0.9)
	for i in cars.size():
		var car := cars[i]
		_reset(car)
		if car.has_meta("fixed_setup"):
			car.setup_pct = car.get_meta("fixed_setup")
		else:
			WeekendSetup.practice(car, 0 if i % 2 == 0 else 1, practice_wet, rng)
	# Long runs of one driver help the whole team's strategy.
	for car in cars:
		for other in cars:
			if other.team == car.team:
				car.tyre_data = maxf(car.tyre_data, other.tyre_data)
	WeekendSetup.roll_weekend(cars, model, rng)
	var quali := QualifyingSim.new(model, conditions, rng)
	var grid := quali.run(cars)
	var engine := RaceEngine.new(model, conditions, grid, rng.randi())
	engine.run()
	return engine


## Fresh runtime state, same object (keeps identities for the statistics).
func _reset(car: SimCar) -> void:
	var fresh := SimCar.new(car.driver, car.team, car.ops)
	for p in ["setup_pct", "wing", "rain_setup", "briefing", "talk", "is_player"]:
		fresh.set(p, car.get(p))
	for prop in car.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			car.set(prop.name, fresh.get(prop.name))


func world_cars() -> Array[SimCar]:
	return WeekendSetup.cars_for_series(&"f1")


## Track conditions without rain (controlled tests).
func dry(model: TrackModel, rng: RandomNumberGenerator) -> RaceConditions:
	var c := RaceConditions.for_track(model, rng)
	c.rain_chance = 0.0
	c.make_weather(rng)
	return c


# --- Even world for controlled tests ----------------------------------------

## Every car 70, every driver 75, all staff 60 – then scenarios change one thing.
func even_world() -> Array[SimCar]:
	for team in GameState.teams.values():
		set_car(team, 70)
		team.car.tyre_preservation = 50
		team.car.reliability = 80
	for d in GameState.drivers.values():
		set_driver(d, 75)
	var cars := world_cars()
	var by_team := {}
	for car in cars:
		if not by_team.has(car.team.id):
			by_team[car.team.id] = TeamOps.uniform(car.team.id, 60)
		car.ops = by_team[car.team.id]
	return cars


static func set_driver(d: DriverData, level: int) -> void:
	for entry in DriverAttributes.DRIVING:
		d.set(entry[0], level)
	for entry in DriverAttributes.MENTAL:
		d.set(entry[0], 60)
	d.fitness = 80
	d.reactions = level
	d.confidence = 55
	d.morale = 55
	d.form = 50
	d.races = 100
	d.traits.clear()


## Even car without parts: no weight, cooling or part failures in the lab.
static func set_car(team: TeamData, level: int) -> void:
	for p in ["downforce", "drag_efficiency", "engine_power", "mechanical_grip", "braking", "traction"]:
		team.car.set(p, level)
	team.car.parts = {}
	team.car.mass_kg = 0.0
	team.car.cooling = -1


func team_cars(cars: Array[SimCar], team_id: StringName) -> Array[SimCar]:
	var out: Array[SimCar] = []
	for car in cars:
		if car.team.id == team_id:
			out.append(car)
	return out


# --- Statistics --------------------------------------------------------------

class Stats:
	var races := 0
	var wins := {}
	var podiums := {}
	var points := {}
	var finish_sum := {}
	var finishes := {}
	var poles := {}
	var pole_wins := 0
	var overtakes := 0
	var sc_races := 0
	var sc_total := 0
	var vsc_total := 0
	var red_total := 0
	var starters := 0
	var dnfs := 0
	var dnf_reasons := {}
	var winner_stops := {}
	var stops_hist := {}
	var stationary := {}
	var stop_issues := {}
	var race_seconds := 0.0
	var best_lap := 0.0

	func add(engine: RaceEngine) -> void:
		races += 1
		var order := engine.classification()
		overtakes += engine.overtake_count()
		var sc := engine.phases.filter(func(p): return p.kind == "SC").size()
		sc_total += sc
		if sc > 0:
			sc_races += 1
		vsc_total += engine.phases.filter(func(p): return p.kind == "VSC").size()
		red_total += engine.phases.filter(func(p): return p.kind == "RED").size()
		var fastest := INF
		for i in order.size():
			var car: SimCar = order[i]
			var id := car.driver.last_name
			starters += 1
			fastest = minf(fastest, car.best_lap)
			if car.retired:
				dnfs += 1
				dnf_reasons[car.retire_reason] = dnf_reasons.get(car.retire_reason, 0) + 1
			else:
				finish_sum[id] = finish_sum.get(id, 0) + i + 1
				finishes[id] = finishes.get(id, 0) + 1
				var pts: int = POINTS[i] if i < POINTS.size() else 0
				points[id] = points.get(id, 0) + pts
				points["team:" + car.team.short_name] = points.get("team:" + car.team.short_name, 0) + pts
				if i == 0:
					wins[id] = wins.get(id, 0) + 1
					winner_stops[car.stops.size()] = winner_stops.get(car.stops.size(), 0) + 1
					if car.grid_position == 1:
						pole_wins += 1
				if i < 3:
					podiums[id] = podiums.get(id, 0) + 1
			stops_hist[car.stops.size()] = stops_hist.get(car.stops.size(), 0) + 1
			for s in car.stops:
				var team := car.team.short_name
				if not stationary.has(team):
					stationary[team] = []
				stationary[team].append(s.stationary)
				if s.issue != "":
					stop_issues[s.issue] = stop_issues.get(s.issue, 0) + 1
			if car.grid_position == 1:
				poles[id] = poles.get(id, 0) + 1
		race_seconds += order[0].finish_t
		best_lap += fastest

	func share(dict: Dictionary, key: String) -> String:
		return "%5.1f %%" % (100.0 * dict.get(key, 0) / maxf(races, 1))

	func avg_finish(key: String) -> String:
		return "%.1f" % (float(finish_sum.get(key, 0)) / maxi(finishes.get(key, 0), 1))

	func avg_stationary(team: String) -> float:
		var arr: Array = stationary.get(team, [])
		var total := 0.0
		for v in arr:
			total += v
		return total / maxi(arr.size(), 1)

	func print_summary() -> void:
		print("Races %d · overtakes/race %.1f · SC %.0f %% of races (%.2f per race) · VSC %.2f · red %.2f · DNF %.1f %% · pole→win %.0f %%" % [
			races, float(overtakes) / races, 100.0 * sc_races / races, float(sc_total) / races,
			float(vsc_total) / races, float(red_total) / races, 100.0 * dnfs / starters, 100.0 * pole_wins / races])
		print("Race length %.1f min · stops per car %s · winner stops %s" % [
			race_seconds / races / 60.0, hist(stops_hist), hist(winner_stops)])

	func hist(h: Dictionary) -> String:
		var keys := h.keys()
		keys.sort()
		var total := 0
		for k in keys:
			total += h[k]
		return ", ".join(keys.map(func(k): return "%d:%.0f%%" % [k, 100.0 * h[k] / total]))

	func print_drivers(names: Array) -> void:
		for n in names:
			print("  %-12s wins %s · podium %s · pole %s · avg finish %s · points %d" % [
				n, share(wins, n), share(podiums, n), share(poles, n), avg_finish(n), points.get(n, 0)])

	func print_top_wins(count: int) -> void:
		var keys := wins.keys()
		keys.sort_custom(func(a, b): return wins[a] > wins[b])
		for i in mini(count, keys.size()):
			print("  %-12s wins %s · avg finish %s" % [keys[i], share(wins, keys[i]), avg_finish(keys[i])])


## Runs `races` weekends, race i on calendar track i % 24.
func run_many(cars: Array[SimCar], make_conditions := Callable(), variant := {}) -> Stats:
	var stats := Stats.new()
	for i in races:
		stats.add(weekend(cars, track_of(i), 50000 + i, make_conditions, variant))
	return stats


# --- Scenarios ---------------------------------------------------------------

func _scenario_single() -> void:
	var cars := world_cars()
	var track: TrackData = GameState.tracks[single_track]
	var started := Time.get_ticks_msec()
	var engine := weekend(cars, track, 4242)
	print(engine.model.describe())
	print("Simulated in %d ms · %d laps · %d overtakes · track %.0f °C · wear %.2f" % [Time.get_ticks_msec() - started,
		engine.conditions.laps, engine.overtake_count(), engine.conditions.track_temp_c, engine.conditions.tyre_wear_factor])
	for e in engine.events:
		if e.kind != "overtake":
			print("  L%-3d %s" % [e.lap, e.text])
	var order := engine.classification()
	var winner := order[0]
	print("\nPos Driver       Team Grid Laps  Gap        Best      Stops")
	for i in order.size():
		var car := order[i]
		var gap: String = car.retire_reason if car.retired else ("%.3f" % (car.race_time() - winner.race_time()) \
			if car.laps_done == winner.laps_done else "+%d lap" % (winner.laps_done - car.laps_done))
		var stops := " ".join(car.stops.map(func(s): return "L%d %s>%s %.1fs" % [s.lap, s.from.substr(0, 1).to_upper(),
			s.to.substr(0, 1).to_upper(), s.stationary]))
		print("%2d. %-12s %-4s %2d   %2d  %-10s %s  %s" % [i + 1, car.label(), car.team.short_name, car.grid_position,
			car.laps_done, gap, _fmt(car.best_lap), stops])
	print("\nLap time breakdown per lap (winner):")
	for key in winner.breakdown_total:
		print("  %-20s %+.3f s" % [key, winner.breakdown_total[key] / maxi(winner.laps_done, 1)])


## Every calendar track: its character and how its races turn out.
func _scenario_tracks() -> void:
	var cars := world_cars()
	var per_track := maxi(1, races / calendar.size())
	print("%d races per track\n" % per_track)
	for t in calendar.size():
		var stats := Stats.new()
		var model: TrackModel
		for k in per_track:
			var engine := weekend(cars, track_of(t), 70000 + t * 100 + k)
			model = engine.model
			stats.add(engine)
		print("%s  laps %d" % [model.describe(), RaceConditions.for_track(model, RandomNumberGenerator.new()).laps])
		print("      overtakes %5.1f · SC %3.0f %% · VSC %.1f · DNF %4.1f %% · pole→win %3.0f %% · winner stops %s · race %.0f min · best lap %s" % [
			float(stats.overtakes) / stats.races, 100.0 * stats.sc_races / stats.races, float(stats.vsc_total) / stats.races,
			100.0 * stats.dnfs / stats.starters, 100.0 * stats.pole_wins / stats.races, stats.hist(stats.winner_stops),
			stats.race_seconds / stats.races / 60.0, _fmt(stats.best_lap / stats.races)])


func _scenario_baseline() -> void:
	var stats := run_many(world_cars())
	stats.print_summary()
	var team_points := []
	for team in GameState.teams.values():
		team_points.append([team.short_name, stats.points.get("team:" + team.short_name, 0),
			(team.car.downforce + team.car.engine_power + team.car.drag_efficiency + team.car.mechanical_grip) / 4,
			stats.avg_stationary(team.short_name)])
	team_points.sort_custom(func(a, b): return a[1] > b[1])
	print("Team points (car rating, average stationary time):")
	for t in team_points:
		print("  %-4s %5d  (car %d, stops %.2f s)" % t)
	print("Most wins:")
	stats.print_top_wins(6)


func _scenario_dominant_top() -> void:
	var cars := even_world()
	set_car(GameState.teams[&"aurum"], 80)
	var a := team_cars(cars, &"aurum")
	set_driver(a[0].driver, 92)
	var stats := run_many(cars, dry)
	print("Aurum car +10 (≈0.5 s), %s = elite (92), %s = average (75). Target: elite 70–85 %% wins" % [a[0].label(), a[1].label()])
	stats.print_summary()
	stats.print_drivers([a[0].label(), a[1].label()])


func _scenario_dominant_weak() -> void:
	var cars := even_world()
	set_car(GameState.teams[&"aurum"], 80)
	var a := team_cars(cars, &"aurum")
	var b := team_cars(cars, &"corsa")
	set_driver(a[0].driver, 62)
	set_driver(b[0].driver, 92)
	set_driver(b[1].driver, 82)
	var stats := run_many(cars, dry)
	print("Aurum car +10 with weak %s (62) and average %s; Corsa normal car with elite %s (92). Target weak driver 15–30 %%" % [
		a[0].label(), a[1].label(), b[0].label()])
	stats.print_summary()
	stats.print_drivers([a[0].label(), a[1].label(), b[0].label(), b[1].label()])


func _scenario_close_field() -> void:
	var cars := even_world()
	var names := []
	var levels := [92, 80, 84, 78, 82, 76]
	var i := 0
	for id in [&"aurum", &"corsa", &"meridian"]:
		set_car(GameState.teams[id], 78)
		for car in team_cars(cars, id):
			set_driver(car.driver, levels[i])
			names.append(car.label())
			i += 1
	var stats := run_many(cars, dry)
	print("Three equal top cars; drivers 92 / 80 / 84 / 78 / 82 / 76. Target best driver 30–40 % (Verstappen 2021: 45 %)")
	stats.print_summary()
	stats.print_drivers(names)


func _scenario_top_driver_midfield() -> void:
	var cars := even_world()
	set_car(GameState.teams[&"aurum"], 80)
	set_car(GameState.teams[&"corsa"], 78)
	set_car(GameState.teams[&"meridian"], 76)
	set_car(GameState.teams[&"kestrel"], 68)
	for id in [&"aurum", &"corsa", &"meridian"]:
		for car in team_cars(cars, id):
			set_driver(car.driver, 82)
	var k := team_cars(cars, &"kestrel")
	set_driver(k[0].driver, 95)
	var stats := run_many(cars)
	print("Elite %s (95) in a midfield car (68; top cars 80/78/76 with good drivers (82), rest 70); teammate %s average. Target 0–5 %% wins, clearly ahead of the car" % [
		k[0].label(), k[1].label()])
	stats.print_summary()
	stats.print_drivers([k[0].label(), k[1].label()])
	stats.print_top_wins(5)


## Pit crew and strategy chief together (engineers stay at 60).
func _scenario_staff() -> void:
	_paired_staff(["tyre_model", "weather_reading", "race_reading", "calm_decisions", "stop_speed", "precision"],
		"pit crew + strategist")


## Only the pit crew.
func _scenario_crew() -> void:
	_paired_staff(["stop_speed", "precision"], "pit crew")


## Only the strategy chief.
func _scenario_strategist() -> void:
	_paired_staff(["tyre_model", "weather_reading", "race_reading", "calm_decisions"], "strategy chief")


## One staff value, e.g. `-- attr 48 race_reading`.
func _scenario_attr() -> void:
	_paired_staff([String(single_track)], String(single_track))


## Race engineers only (setup quality).
func _scenario_engineers() -> void:
	_paired_staff(["engineer_level"], "race engineers")


## Paired comparison: the same races (same random numbers) once with all
## staff at 60 and once with Aurum's values at 95 and Corsa's at 25.
## Comparing a team with itself removes most of the luck.
func _paired_staff(props: Array, label: String) -> void:
	var base := run_many(even_world())
	var cars := even_world()
	for p in props:
		_set_ops(team_cars(cars, &"aurum")[0].ops, p, 95)
		_set_ops(team_cars(cars, &"corsa")[0].ops, p, 25)
	var stats := run_many(cars)
	print("Identical cars and drivers, same races twice. %s: Aurum 95, Corsa 25, everyone else 60." % label)
	stats.print_summary()
	var seasons := races / 24.0
	for row in [["AUR", "95"], ["SCA", "25"]]:
		var key: String = "team:" + row[0]
		var delta: int = stats.points.get(key, 0) - base.points.get(key, 0)
		print("  %s (%s): %+d points vs. 60 (%+.1f per race, %+.0f per 24-race season) · stops %.2f s (with 60: %.2f s)" % [
			row[0], row[1], delta, float(delta) / races, delta / seasons,
			stats.avg_stationary(row[0]), base.avg_stationary(row[0])])


static func _set_ops(ops: TeamOps, property: String, value: int) -> void:
	if property == "engineer_level":
		ops.set_meta("engineer_level", value)
	else:
		ops.set(property, value)


func _scenario_rain() -> void:
	var cars := even_world()
	var v := team_cars(cars, &"vortex")
	v[0].driver.wet_skill = 95
	v[1].driver.wet_skill = 35
	var wet := func(model: TrackModel, rng: RandomNumberGenerator) -> RaceConditions:
		var c := RaceConditions.for_track(model, rng)
		c.weather = WeatherTimeline.scripted(c.laps * 2 + 30, 25.0,
			{"start": rng.randf_range(10.0, 40.0), "end": rng.randf_range(60.0, 90.0), "peak": rng.randf_range(0.5, 0.9)})
		return c
	var stats := run_many(cars, wet)
	print("Rain every race. %s wet skill 95, %s wet skill 35, all else equal." % [v[0].label(), v[1].label()])
	stats.print_summary()
	stats.print_drivers([v[0].label(), v[1].label()])


func _scenario_setup() -> void:
	var cars := even_world()
	var a := team_cars(cars, &"aurum")
	var b := team_cars(cars, &"corsa")
	for car in a:
		car.set_meta("fixed_setup", 90.0)
	for car in b:
		car.set_meta("fixed_setup", 60.0)
	var stats := run_many(cars, dry)
	print("Same everything; Aurum setup 90 %, Corsa setup 60 %.")
	stats.print_summary()
	stats.print_drivers([a[0].label(), a[1].label(), b[0].label(), b[1].label()])


func _scenario_strategy() -> void:
	var cars := world_cars()
	for wear in [0.7, 1.0, 1.3]:
		var make := func(model: TrackModel, rng: RandomNumberGenerator) -> RaceConditions:
			var c := dry(model, rng)
			c.tyre_wear_factor = wear
			return c
		var stats := run_many(cars, make)
		print("Tyre wear %.1f on every track:" % wear)
		stats.print_summary()


func _scenario_track() -> void:
	var cars := even_world()
	var down: TeamData = GameState.teams[&"aurum"]
	var power: TeamData = GameState.teams[&"corsa"]
	down.car.downforce = 85
	down.car.mechanical_grip = 80
	down.car.engine_power = 60
	down.car.drag_efficiency = 60
	power.car.downforce = 60
	power.car.mechanical_grip = 60
	power.car.engine_power = 85
	power.car.drag_efficiency = 80
	print("AUR = downforce car, SCA = power car, same average rating. Points per track:")
	var per_track := maxi(1, races / calendar.size())
	var rows := []
	for t in calendar.size():
		var stats := Stats.new()
		var model: TrackModel
		for k in per_track:
			var engine := weekend(cars, track_of(t), 90000 + t * 100 + k, dry)
			model = engine.model
			stats.add(engine)
		rows.append([model.track.short_name, (model.rating_share.power + model.rating_share.drag) * 100.0,
			stats.points.get("team:AUR", 0), stats.points.get("team:SCA", 0)])
	rows.sort_custom(func(a, b): return a[1] < b[1])
	for r in rows:
		print("  %-14s power %2.0f %%   AUR %4d   SCA %4d" % r)


static func _fmt(seconds: float) -> String:
	if is_inf(seconds):
		return "-"
	return "%d:%06.3f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]
