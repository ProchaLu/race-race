## Runs a full race weekend of the player's series inside the season, step
## by step so the team principal can decide in between (design doc 8.4b):
## decisions -> practice and qualifying -> strategy and briefing -> race.
## Every decision starts as the responsible staff member's choice, so
## run_round() plays a weekend without the player. Stores a detailed summary
## (GameState.race_results) and updates the standings.
## In the race the simulation pauses at key moments (safety car, weather,
## team orders) when the player races it himself.
class_name RaceWeekend
extends RefCounted

enum Stage { PLANNING, STRATEGY, RACE, FINISHED }
enum Target { POINTS, PODIUM, BRING_HOME }
enum Orders { FREE, HOLD_AFTER_STOPS, PRIORITY }

## Practice programmes per driver slot (0 = first driver of the team):
## 0 = setup work, 1 = long runs, 2 = academy driver in FP1.
const DEFAULT_PROGRAMMES := [0, 1]
const PROGRAMMES := ["Setup work", "Long runs & tyres", "Academy driver in FP1", "Test new parts"]
const TEST_PARTS := 3
## Untested new parts cost setup in the first weekend.
const UNTESTED_SETUP := 3.0
## [name, description, morale if achieved, morale if missed]
const TARGETS := [
	["Both cars in the points", "Balanced risk. Morale +3 for both drivers if achieved, −2 if missed.", 3, -2],
	["Attack the podium", "Drivers take more risks: more overtaking attempts and mistakes. Morale +5 if achieved, −3 if missed.", 5, -3],
	["Bring both cars home", "Fewer risks and mistakes, fewer overtaking attempts. Morale +2 if both cars finish.", 2, 0],
]
## Race effects of the weekend target (same keys as the 1-on-1 talk).
const TARGET_EFFECTS := [{}, {"aggression": 0.1, "mistake": 0.05}, {"aggression": -0.1, "mistake": -0.08}]
const ORDERS := [
	["Free racing", "Drivers may fight each other. No morale effect, risk of losing points."],
	["Hold positions after the last stop", "Protects the team result once both cars have stopped."],
	["Priority for one driver", "The teammate lets him pass. The teammate's morale −2 per race."],
]
const BRIEFINGS := [
	[SimCar.Briefing.BRING_HOME, "Bring it home"],
	[SimCar.Briefing.ATTACK, "Attack!"],
	[SimCar.Briefing.NO_PRESSURE, "No pressure"],
	[SimCar.Briefing.TEAM_PLAYER, "Team player"],
]
const RAIN_SETUPS := [
	[SimCar.RainSetup.DRY, "Dry setup", "Fastest if it stays dry. Big loss in the wet."],
	[SimCar.RainSetup.COMPROMISE, "Compromise", "A little slower in both conditions."],
	[SimCar.RainSetup.WET, "Wet setup", "Strong if it rains. Slow if it stays dry."],
]

var series: SeriesData
var round_index: int
var track: TrackData
var model: TrackModel
var conditions: RaceConditions
var cars: Array[SimCar] = []
var rng := RandomNumberGenerator.new()
var stage: Stage = Stage.PLANNING

# Decisions of the player's team. They start as the staff's choice.
var target: Target = Target.POINTS
var orders: Orders = Orders.FREE
var priority_driver: StringName = &""
## Driver ID -> practice programme.
var programmes := {}
## Driver ID -> index into strategy_options.
var plan_choice := {}
var rain_setup: SimCar.RainSetup = SimCar.RainSetup.COMPROMISE
## Driver ID -> SimCar.Briefing
var briefings := {}
## Part ID -> driver ID who gets the only new unit (player's choice).
var parts_choice := {}
## Correlation was done after practice (programme "Test new parts").
var parts_tested := false

## The strategy chief's rain forecast for the race (0..1) and its error margin.
var forecast_rain := 0.0
var forecast_margin := 0.0
var practice_wet := 0.0
var quali: QualifyingSim
var grid: Array[SimCar] = []
## Driver ID -> proposals of the strategy chief (StrategyPlanner.plans()).
var strategy_options := {}
## Driver ID -> DriverTalk (weekly 1-on-1 or a talk he asked for).
var talks := {}
var engine: RaceEngine
var summary := {}


static func create(p_series: SeriesData, p_round_index: int, seed_value: int = 0) -> RaceWeekend:
	var w := RaceWeekend.new()
	if seed_value != 0:
		w.rng.seed = seed_value
	else:
		w.rng.randomize()
	w.series = p_series
	w.round_index = p_round_index
	w.track = GameState.tracks[p_series.calendar[p_round_index]]
	w.model = TrackModel.build(w.track)
	w.conditions = RaceConditions.for_track(w.model, w.rng)
	for team_id in p_series.team_ids:
		var team: TeamData = GameState.teams[team_id]
		if team.car.has_parts():
			var cost := CarBuild.ensure_raceable(team)
			if cost > 0 and team_id == GameState.player_team_id:
				var msg := InboxMessage.new()
				msg.sender = "Factory manager"
				msg.subject = "Emergency build for the race weekend"
				msg.icon = "factory"
				msg.add_paragraph("Not every car had all its parts. The factory built the missing ones overnight for %s.", [UIStyle.money(cost)])
				GameState.add_message(msg)
	w.cars = WeekendSetup.cars_for_series(p_series.id)
	w._make_forecast()
	w.staff_planning()
	return w


## Plays a whole weekend with every decision left to the staff.
static func run_round(p_series: SeriesData, p_round_index: int, seed_value: int = 0) -> Dictionary:
	var w := create(p_series, p_round_index, seed_value)
	w.run_practice_and_qualifying()
	return w.run_race()


func player_cars() -> Array[SimCar]:
	var out: Array[SimCar] = []
	for car in cars:
		if car.is_player:
			out.append(car)
	return out


func car_of(driver_id: StringName) -> SimCar:
	for car in cars:
		if car.driver.id == driver_id:
			return car
	return null


## The player team's staff values (strategy chief, crew, engineers).
func ops() -> TeamOps:
	var own := player_cars()
	return own[0].ops if not own.is_empty() else TeamOps.from_team(GameState.player_team_id)


# --- Before practice ---------------------------------------------------------

## The weather forecast of the strategy chief: a good weather reader knows
## better whether the shower really comes.
func _make_forecast() -> void:
	var accuracy := ops().weather_reading / 100.0
	var actual := 1.0 if conditions.weather.max_rain() > 0.05 else 0.0
	forecast_margin = lerpf(0.25, 0.05, accuracy)
	var guess := lerpf(conditions.rain_chance, actual, 0.15 + 0.45 * accuracy)
	forecast_rain = clampf(guess + rng.randfn(0.0, forecast_margin * 0.5), 0.0, 0.95)
	if conditions.rain_chance < 0.03 and actual == 0.0:
		forecast_rain = minf(forecast_rain, 0.03)


## What the sporting director and the race engineers would choose.
func staff_planning() -> void:
	var rank := TeamMood.car_rank(GameState.player_team_id)
	target = Target.PODIUM if rank <= 2 else (Target.POINTS if rank <= 7 else Target.BRING_HOME)
	orders = Orders.FREE
	priority_driver = &""
	for car in player_cars():
		var c := GameState.contract_of(car.driver.id)
		if c and c.role == ContractData.DriverRole.NUMBER_ONE:
			orders = Orders.PRIORITY
			priority_driver = car.driver.id
	staff_programmes()


## The driver with the better technical feedback works on the setup.
func staff_programmes() -> void:
	var own := player_cars()
	own.sort_custom(func(a: SimCar, b: SimCar): return a.driver.technical_feedback > b.driver.technical_feedback)
	for i in own.size():
		programmes[own[i].driver.id] = DEFAULT_PROGRAMMES[mini(i, DEFAULT_PROGRAMMES.size() - 1)]


## Parts whose newest version does not have a unit for every car yet:
## [[part ID, version, units], ...]
func scarce_parts() -> Array:
	var team := GameState.player_team()
	var cars := player_cars().size()
	var out := []
	for id in CarParts.ORDER:
		var v: PartVersion = team.car.parts[id]
		if v.version > 1 and v.units < cars:
			out.append([id, v.version, v.units])
	return out


## The driver the technical director would give a scarce part to.
func recommended_driver(part_id: StringName) -> StringName:
	var order := CarBuild.priority_order(GameState.player_team())
	return order[0].id if not order.is_empty() else &""


## True if a car has a new part whose real effect is not known yet.
func has_untested_parts(team: TeamData = null) -> bool:
	if not team:
		team = GameState.player_team()
	for id in team.car.part_history:
		for v in team.car.part_history[id]:
			if not v.correlated:
				return true
	return false


func has_academy_driver() -> bool:
	return not GameState.player_team().academy_driver_ids.is_empty()


# --- Practice and qualifying -------------------------------------------------

func run_practice_and_qualifying() -> void:
	_apply_parts_choice()
	practice_wet = 0.0 if rng.randf() > conditions.rain_chance * 0.5 else rng.randf_range(0.3, 0.9)
	var slot := {}
	var tested := {}
	for car in cars:
		var programme: int
		if car.is_player:
			programme = programmes.get(car.driver.id, 0)
		else:
			var index: int = slot.get(car.team.id, 0)
			slot[car.team.id] = index + 1
			programme = DEFAULT_PROGRAMMES[mini(index, DEFAULT_PROGRAMMES.size() - 1)]
			# The second driver tests new parts when there are any.
			if index == 1 and has_untested_parts(car.team):
				programme = TEST_PARTS
		WeekendSetup.practice(car, programme, practice_wet, rng)
		if programme == TEST_PARTS:
			tested[car.team.id] = true
	for car in cars:
		if not tested.has(car.team.id) and _untested_on(car):
			car.setup_pct = maxf(0.0, car.setup_pct - UNTESTED_SETUP)
	for team_id in tested:
		CarDevelopment.correlate(GameState.teams[team_id])
	parts_tested = tested.has(GameState.player_team_id)
	# Long runs of one driver help the whole team's strategy.
	for car in cars:
		for other in cars:
			if other.team == car.team:
				car.tyre_data = maxf(car.tyre_data, other.tyre_data)
	WeekendSetup.roll_weekend(cars, model, rng)

	quali = QualifyingSim.new(model, conditions, rng)
	grid = quali.run(cars)
	_make_strategy_options()
	staff_strategy()
	for car in player_cars():
		var request := DriverTalk.request(car, self)
		talks[car.driver.id] = request if request else DriverTalk.weekly(car, self)
	stage = Stage.STRATEGY


func _untested_on(car: SimCar) -> bool:
	for id in car.car_data.parts:
		if not car.car_data.parts[id].correlated:
			return true
	return false


## The player's choice who gets scarce new parts, with the morale effects
## (docs/car_model.md 8). Rebuilds the player's cars.
func _apply_parts_choice() -> void:
	var team := GameState.player_team()
	if not team.car.has_parts():
		return
	for entry in scarce_parts():
		var id: StringName = entry[0]
		var chosen: StringName = parts_choice.get(id, recommended_driver(id))
		CarBuild.assign(team, id, chosen)
		for car in player_cars():
			if car.driver.id == chosen:
				continue
			var d := car.driver
			var promise_broken := false
			for p in GameState.promises_to(d.id):
				if p.status == PromiseData.Status.OPEN and p.description == "Equal treatment with the teammate":
					p.status = PromiseData.Status.BROKEN
					TeamMood.change_morale(d, "Promise broken", p.morale_penalty)
					promise_broken = true
			if not promise_broken:
				var c := GameState.contract_of(d.id)
				var no1 := c and c.role == ContractData.DriverRole.NUMBER_ONE
				TeamMood.change_morale(d, "Teammate got the new part first", -4 if no1 else -2)
	for car in player_cars():
		car.car_data = CarBuild.car_for(team, car.driver.id)


## The strategy chief's proposals, estimated with his own (imperfect) tyre model.
func _make_strategy_options() -> void:
	var plan_rng := RandomNumberGenerator.new()
	plan_rng.seed = rng.randi()
	var planner := StrategyPlanner.new(model, conditions, plan_rng)
	for car in player_cars():
		planner.init_estimates(car)
		strategy_options[car.driver.id] = planner.plans(car, 0, true, 3)


## Strategy chief picks his best plan, the engineers the setup direction
## and the briefing.
func staff_strategy() -> void:
	for car in player_cars():
		plan_choice[car.driver.id] = 0
		briefings[car.driver.id] = recommended_briefing(car)[0]
	rain_setup = staff_rain_setup(forecast_rain)


static func staff_rain_setup(rain: float) -> SimCar.RainSetup:
	if rain < 0.2:
		return SimCar.RainSetup.DRY
	if rain > 0.6:
		return SimCar.RainSetup.WET
	return SimCar.RainSetup.COMPROMISE


## The race engineer's advice: [briefing, reason].
func recommended_briefing(car: SimCar) -> Array:
	var d := car.driver
	if orders == Orders.PRIORITY and priority_driver != &"" and d.id != priority_driver:
		return [SimCar.Briefing.TEAM_PLAYER, "Team orders favour his teammate – he should help, not fight."]
	if d.morale < 45 or d.traits.has(&"glass_nerves"):
		return [SimCar.Briefing.NO_PRESSURE, "Low morale or weak nerves: pressure now makes mistakes more likely."]
	var position := car.grid_position if car.grid_position > 0 else 10
	if d.temperament < 40 and position <= 10:
		return [SimCar.Briefing.BRING_HOME, "Hot-headed and in the points: protect the result, avoid contact."]
	if position > 10:
		return [SimCar.Briefing.ATTACK, "Starts outside the points – he has to gain places."]
	if position <= 6:
		return [SimCar.Briefing.BRING_HOME, "Good starting position: no mistakes, bring the points home."]
	return [SimCar.Briefing.ATTACK, "Points are close – a little more aggression can pay off."]


static func briefing_name(b: SimCar.Briefing) -> String:
	for entry in BRIEFINGS:
		if entry[0] == b:
			return entry[1]
	return "Normal"


static func rain_setup_name(r: SimCar.RainSetup) -> String:
	return RAIN_SETUPS[r][1]


# --- Race --------------------------------------------------------------------

## Lights out. ask_player: pause at key moments (see advance()).
func start_race(ask_player: bool) -> void:
	if stage == Stage.PLANNING:
		run_practice_and_qualifying()
	for car in cars:
		if car.is_player:
			_apply_player_decisions(car)
		else:
			car.rain_setup = staff_rain_setup(conditions.rain_chance)
	engine = RaceEngine.new(model, conditions, grid, rng.randi())
	engine.ask_player = ask_player
	stage = Stage.RACE


## Races on to the next key moment. Returns true while a decision is
## waiting (engine.moment), false once the race is over and summarized.
func advance() -> bool:
	if engine.run_until_moment():
		return true
	_finish_race()
	return false


func answer(index: int) -> void:
	engine.answer_moment(index)


## The strategy chief takes every remaining decision.
func finish_with_staff() -> Dictionary:
	if stage != Stage.RACE:
		start_race(false)
	engine.ask_player = false
	if not engine.moment.is_empty():
		engine.answer_moment(engine.moment.recommended)
	engine.run()
	_finish_race()
	return summary


## Plays the race without the player (the staff decides the key moments).
func run_race() -> Dictionary:
	if stage == Stage.FINISHED:
		return summary
	return finish_with_staff()


func _finish_race() -> void:
	summary = summarize(engine, quali, round_index, track)
	_wear_and_damage()
	_apply(series, round_index, engine)
	summary.points = {}
	for entry in summary.entries:
		summary.points[entry.driver_id] = entry.points
	summary.target = _judge_target()
	summary.decisions = _decision_notes()
	_orders_morale()
	for effect in engine.morale_effects:
		TeamMood.change_morale(effect[0], effect[1], effect[2])
	summary.moments = engine.moments_asked
	GameState.race_results.append(summary)
	stage = Stage.FINISHED


## How well the mental coach talks for you (0..1).
func coach_skill() -> float:
	for s in GameState.staff_of_team(GameState.player_team_id):
		if s.role == StaffData.Role.MENTAL_COACH:
			return s.attribute(&"motivation") / 100.0
	return 0.3


## Talks not held by the team principal are held by the mental coach.
func coach_talks() -> void:
	for id in talks:
		var talk: DriverTalk = talks[id]
		if not talk.done:
			talk.auto_answer(coach_skill(), rng)


func _apply_player_decisions(car: SimCar) -> void:
	var id := car.driver.id
	var talk: DriverTalk = talks.get(id)
	if talk:
		if not talk.done:
			talk.auto_answer(coach_skill(), rng)
		for key in talk.race_fx:
			match key:
				"setup":
					car.setup_pct = clampf(car.setup_pct + talk.race_fx.setup, 0.0, 100.0)
				"team_orders":
					car.talk["team_orders"] = true
				_:
					car.talk[key] = car.talk.get(key, 0.0) + talk.race_fx[key]
	car.rain_setup = rain_setup
	car.briefing = briefings.get(id, SimCar.Briefing.NORMAL)
	var options: Array = strategy_options.get(id, [])
	var choice: int = plan_choice.get(id, 0)
	car.chosen_plan = options[choice] if choice < options.size() else {}
	for key in TARGET_EFFECTS[target]:
		car.talk[key] = car.talk.get(key, 0.0) + TARGET_EFFECTS[target][key]
	car.orders = {}
	match orders:
		Orders.HOLD_AFTER_STOPS:
			car.orders = {"hold_after_stops": true}
		Orders.PRIORITY:
			if priority_driver != &"" and id != priority_driver:
				car.orders = {"yield": true}


## Crashes and contacts destroy parts, every car uses a set of brakes; the
## teams learn what their new parts bring and reorder spares (docs/car_model.md 7).
func _wear_and_damage() -> void:
	var lost := []
	for car in engine.cars:
		var team := car.team
		if not team.car.has_parts():
			continue
		var gone := []
		if car.retired and car.retire_reason == "Crash":
			gone.append(&"front_wing")
			for entry in [[&"suspension_front", 0.5], [&"floor", 0.3], [&"rear_wing", 0.25], [&"diffuser", 0.25], [&"monocoque", 0.15]]:
				if rng.randf() < entry[1]:
					gone.append(entry[0])
		else:
			if car.damage.has("front_wing"):
				gone.append(&"front_wing")
			if car.damage.has("floor") and rng.randf() < 0.5:
				gone.append(&"floor")
			if car.damage.has("rear_wing"):
				gone.append(&"rear_wing")
		for id in gone:
			CarBuild.consume(team, car.driver.id, id)
		CarBuild.consume(team, car.driver.id, &"brakes")
		if team.id == GameState.player_team_id and not gone.is_empty():
			lost.append("%s: %s" % [car.driver.last_name, ", ".join(gone.map(func(i): return TranslationServer.translate(CarParts.name_of(i))))])
	for team_id in series.team_ids:
		var team: TeamData = GameState.teams[team_id]
		if team.car.has_parts():
			CarDevelopment.correlate(team)
			CarDevelopment.reorder_spares(team)
	summary["parts_lost"] = lost


## Did the team reach the weekend target? Morale moves for both drivers.
func _judge_target() -> Dictionary:
	var own: Array = summary.entries.filter(func(e): return e.team_id == GameState.player_team_id)
	var achieved := false
	match target:
		Target.POINTS:
			achieved = own.all(func(e): return e.points > 0)
		Target.PODIUM:
			achieved = own.any(func(e): return e.finish >= 1 and e.finish <= 3)
		Target.BRING_HOME:
			achieved = own.all(func(e): return e.finish > 0)
	var delta: int = TARGETS[target][2] if achieved else TARGETS[target][3]
	if delta != 0:
		for e in own:
			TeamMood.change_morale(GameState.drivers[e.driver_id],
				"Weekend target achieved" if achieved else "Weekend target missed", delta)
	return {"kind": target, "name": TARGETS[target][0], "achieved": achieved, "morale": delta}


func _orders_morale() -> void:
	if orders != Orders.PRIORITY or priority_driver == &"":
		return
	for car in player_cars():
		if car.driver.id != priority_driver:
			TeamMood.change_morale(car.driver, "Team orders against him", -2)


func _decision_notes() -> Dictionary:
	var notes := {"orders": ORDERS[orders][0], "rain_setup": rain_setup_name(rain_setup), "drivers": {}}
	for car in player_cars():
		var id := car.driver.id
		notes.drivers[id] = {"programme": PROGRAMMES[programmes.get(id, 0)],
			"briefing": briefing_name(briefings.get(id, SimCar.Briefing.NORMAL)),
			"plan": plan_choice.get(id, 0)}
	return notes


static func _apply(p_series: SeriesData, p_round_index: int, engine: RaceEngine) -> void:
	var start_order: Array = []
	var by_grid := engine.cars.duplicate()
	by_grid.sort_custom(func(a: SimCar, b: SimCar): return a.grid_position < b.grid_position)
	for car in by_grid:
		start_order.append(car.driver.id)
	var classified: Array = []
	var retired: Array = []
	for car in engine.classification():
		(retired if car.retired else classified).append(car.driver.id)
	SeasonRecords.apply_round(p_series, p_round_index, start_order, classified, retired)


## Everything the result screens need, as plain data (no runtime objects).
static func summarize(engine: RaceEngine, p_quali: QualifyingSim, p_round_index: int, p_track: TrackData) -> Dictionary:
	var order := engine.classification()
	var winner := order[0]
	var s: SeriesData = GameState.series[GameState.teams[winner.team.id].series_id]
	var entries := []
	var fastest := INF
	var fastest_id: StringName = &""
	var finish_position := 0
	for i in order.size():
		var car := order[i]
		if not car.retired:
			finish_position += 1
		if car.best_lap < fastest:
			fastest = car.best_lap
			fastest_id = car.driver.id
		var q: Dictionary = p_quali.results.get(car, {})
		entries.append({
			"driver_id": car.driver.id,
			"team_id": car.team.id,
			"grid": car.grid_position,
			"finish": 0 if car.retired else finish_position,
			"laps": car.laps_done,
			"time": car.race_time(),
			"gap": car.race_time() - winner.race_time() if car.laps_done == winner.laps_done and not car.retired else -1.0,
			"laps_down": winner.laps_done - car.laps_done,
			"best_lap": car.best_lap,
			"retire_reason": car.retire_reason,
			"retire_lap": car.retire_lap,
			"points": 0 if car.retired else SeasonRecords.points_for(s, finish_position),
			"penalty": car.penalty_s,
			"stops": car.stops.duplicate(true),
			"lap_times": Array(car.lap_times),
			"positions": Array(car.lap_positions),
			"compounds": car.lap_compounds.duplicate(),
			"start_compound": car.start_compound,
			"breakdown": car.breakdown_total.duplicate(),
			"overtakes": car.overtakes_made,
			"mistakes": car.mistakes,
			"setup": car.setup_pct,
			"cooling": car.cooling_opening,
			"quali": {"Q1": q.get("Q1", INF), "Q2": q.get("Q2", INF), "Q3": q.get("Q3", INF), "out": q.get("out", "")},
		})
	return {
		"round": p_round_index + 1,
		"track_id": p_track.id,
		"laps": engine.conditions.laps,
		"track_temp": engine.conditions.track_temp_c,
		"reference_lap": engine.model.reference_lap_s,
		"entries": entries,
		"fastest_lap": {"driver_id": fastest_id, "time": fastest},
		"phases": engine.phases.duplicate(true),
		"weather": engine.lap_weather.duplicate(true),
		"events": engine.events.filter(func(e): return e.kind != "overtake"),
		"overtakes": engine.overtake_count(),
	}


## The result entry of a driver in a summary, or {}.
static func entry_of(p_summary: Dictionary, driver_id: StringName) -> Dictionary:
	for e in p_summary.entries:
		if e.driver_id == driver_id:
			return e
	return {}
