## Fast, detailed race simulation (docs/simulation_model.md). Cars move
## sector by sector in time order: every car is processed when it enters
## its next sector, so the car ahead on the road is always known. Traffic,
## dirty air, DRS, overtaking attempts, contacts, blue flags, mistakes,
## failures, safety cars, weather and pit stops all act at sector level.
class_name RaceEngine
extends RefCounted

enum Flag { GREEN, SAFETY_CAR, VSC, RED }

const RED_FLAG_PAUSE_S := 1200.0
const FAILURES := ["Engine failure", "Gearbox failure", "Hydraulics failure", "Electrical failure"]
const PARTIAL_FAILURES := [["power", "Power loss", 0.4, 0.8], ["gearbox", "Gearbox problem", 0.3, 0.6],
	["brakes", "Brake problem", 0.2, 0.5]]
const RECORDS_PER_SECTOR := 4

var model: TrackModel
var conditions: RaceConditions
var planner: StrategyPlanner
var rng := RandomNumberGenerator.new()
## Grid order at the start.
var cars: Array[SimCar] = []
var time_s: float = 0.0
var flag: Flag = Flag.GREEN
var flag_laps_left: int = 0
var vsc_end_s: float = 0.0
var drs_from_leader_lap: int = SimTuning.DRS_FROM_LAP
var chequered: bool = false
var is_finished: bool = false
var leader: SimCar
var leader_laps: int = 0
## {"lap", "t", "kind", "driver", "text"}
var events: Array = []
## {"kind": "SC"/"VSC"/"RED", "from_lap", "to_lap"}
var phases: Array = []
## Per leader lap: [wetness, rain]
var lap_weather: Array = []
## Key moments of the player's team (design doc 8.4b): with ask_player on,
## the race pauses at a safety car, a weather change or a fight between the
## teammates until answer_moment() is called. Off: the strategy chief decides.
var ask_player := false
## The open question, or {}: {"kind", "lap", "title", "text", "facts": [[label, value]],
## "options": [[title, description]], "recommended": int, "cars": [SimCar], "actions": [Callable]}.
## Every text is [format, args] so the screen can translate it.
var moment := {}
var moments_asked := 0
## Lasting consequences of the team principal's calls: [[driver, reason, morale delta]]
var morale_effects: Array = []

# Per sector: recent cars as [car, entry_t, exit_t], ordered by exit time.
var _records: Array = []
# Cars that crossed the line per lap number (for positions).
var _line_count := {}
var _line_pending := {}
# Cars still racing (faster than checking every car each step).
var _running: Array[SimCar] = []
var _overtakes: int = 0
var overtakes_by_lap := {}


func _init(p_model: TrackModel, p_conditions: RaceConditions, grid: Array[SimCar], seed_value: int = 0) -> void:
	model = p_model
	conditions = p_conditions
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	conditions.ensure_weather(rng)
	planner = StrategyPlanner.new(model, conditions, rng)
	cars = grid
	_running = grid.duplicate()
	var car_seed := rng.randi()
	for car in cars:
		car.seed_random(car_seed)
	for s in model.sectors:
		_records.append([])
	_setup_start()


# --- Start -----------------------------------------------------------------

func _setup_start() -> void:
	var wet := conditions.weather.wetness_at(0.0)
	for i in cars.size():
		var car := cars[i]
		car.grid_position = i + 1
		car.sector_frac = PaceModel.car_sector_fracs(car, model)
		planner.init_estimates(car)
		var options := [car.chosen_plan.duplicate(true)] if not car.chosen_plan.is_empty() \
			else planner.plans(car, 0, true, 1)
		var first: StringName = options[0].first if not options.is_empty() else &"medium"
		var ideal := PaceModel.ideal_compound_for(wet, first)
		car.start_compound = ideal
		car.compound = ideal
		car.plan = options[0].stops if not options.is_empty() and ideal == first else []
		if not PaceModel.is_wet_compound(ideal):
			car.used_dry_compounds[ideal] = true
		car.tyre_temp = SimTuning.NEW_TYRE_TEMP
		car.fuel_kg = planner.start_fuel(car)
		var reaction := 0.15 + 0.2 * (1.0 - (car.driver.reactions + car.driver.starts) / 200.0) \
			+ absf(car.rng.randfn(0.0, 0.05))
		car.t_next = i * SimTuning.GRID_SLOT_S + reaction
		car.lap_start_t = 0.0
		car.position = i + 1
		_prepare_lap(car, 0.0)
		# Launch: standing start plus the driver's start skill.
		var launch := SimTuning.STANDING_START_S + (50.0 - car.driver.starts) / 50.0 * SimTuning.LAUNCH_SKILL_S \
			+ car.rng.randfn(0.0, SimTuning.LAUNCH_SIGMA_S)
		if car.driver.traits.has(&"rocket_start"):
			launch -= 0.15
		car.lap_incident.append([0, launch, "start"])
	leader = cars[0]
	_log(null, "start", "Lights out – %d laps" % conditions.laps)


# --- Main loop -------------------------------------------------------------

## Runs the whole race.
func run() -> void:
	while step():
		if not moment.is_empty():
			answer_moment(moment.recommended)


## Runs until the next key moment (true) or the end of the race (false).
func run_until_moment() -> bool:
	while step():
		if not moment.is_empty():
			return true
	return false


## Processes one car entering its next sector. Returns false when done.
func step() -> bool:
	var car := _next_car()
	if not car:
		is_finished = true
		return false
	time_s = car.t_next
	_update_flags()
	if car.next_sector == 0 and _line_pending.get(car, false):
		_line_pending[car] = false
		var before := car.t_next
		_on_line(car)
		if not car.is_running() or car.t_next != before:
			return true  # finished, retired or pitted: re-queue
	_process_sector(car)
	return true


func _next_car() -> SimCar:
	var best: SimCar = null
	var best_t := INF
	for car in _running:
		if car.t_next < best_t:
			best_t = car.t_next
			best = car
	return best


func _process_sector(car: SimCar) -> void:
	var si := car.next_sector
	var sector: TrackModel.Sector = model.sectors[si]
	var t_in := car.t_next
	var last_sector := si == model.sectors.size() - 1
	if last_sector:
		_strategy_decisions(car)

	var free := sector.reference_s * (1.0 + car.sector_frac[si]) \
		+ car.lap_extra_s * sector.reference_s / model.reference_lap_s
	var ahead := _ahead_record(si, car)
	var gap_in := INF
	if not ahead.is_empty():
		gap_in = t_in - ahead[1]

	var normal_free: float = free
	match flag:
		Flag.VSC:
			free = sector.reference_s * SimTuning.VSC_PACE
		Flag.SAFETY_CAR:
			var pace := SimTuning.SC_PACE if car == leader else SimTuning.SC_PACE * (1.0 - SimTuning.SC_CATCH_UP)
			free = sector.reference_s * pace
		_:
			free += _air_effects(car, sector, gap_in)
	if flag != Flag.GREEN:
		car.lap_flag_s += free - normal_free

	# Incidents planned for this sector (start, mistakes, failures).
	for incident in car.lap_incident:
		if incident[0] == si:
			free += incident[1]
			if incident[2] == "crash":
				_retire(car, "Crash", true)
				return
			if incident[2] == "failure":
				_retire(car, incident[3], true)
				return

	var exit := t_in + free
	if not ahead.is_empty():
		exit = _resolve_traffic(car, ahead, si, sector, t_in, exit, gap_in)
		if not car.is_running():
			return

	car.t_next = exit
	car.next_sector = (si + 1) % model.sectors.size()
	if not (last_sector and car.pit_now):
		_add_record(si, car, t_in, exit)
	if last_sector:
		_line_pending[car] = true


## Dirty air, DRS and slipstream (green flag only).
func _air_effects(car: SimCar, sector: TrackModel.Sector, gap_in: float) -> float:
	var extra := 0.0
	if gap_in < SimTuning.DIRTY_AIR_GAP_S:
		extra += sector.reference_s * SimTuning.DIRTY_AIR_FRAC * sector.aero_share \
			* (1.0 - gap_in / SimTuning.DIRTY_AIR_GAP_S)
		car.lap_dirty_air += 1
	var wet := conditions.weather.wetness_at(time_s)
	if sector.is_drs and gap_in < SimTuning.DRS_GAP_S and leader_laps + 1 >= drs_from_leader_lap \
			and wet < SimTuning.DRS_MAX_WETNESS and not car.drs_broken:
		extra -= sector.reference_s * SimTuning.DRS_GAIN_FRAC * model.straight_share(sector)
	if gap_in < SimTuning.SLIPSTREAM_GAP_S:
		extra -= sector.reference_s * SimTuning.SLIPSTREAM_FRAC * model.straight_share(sector)
	return extra


# --- Traffic and overtaking ------------------------------------------------

func _ahead_record(si: int, car: SimCar) -> Array:
	var recs: Array = _records[si]
	for i in range(recs.size() - 1, -1, -1):
		var r: Array = recs[i]
		if r[0] != car and r[0].is_running():
			return r
	return []


func _add_record(si: int, car: SimCar, t_in: float, t_out: float) -> void:
	var recs: Array = _records[si]
	for i in range(recs.size() - 1, -1, -1):
		if recs[i][0] == car:
			recs.remove_at(i)
	_insert_sorted(recs, [car, t_in, t_out])
	while recs.size() > RECORDS_PER_SECTOR:
		recs.pop_front()


## Keeps the records ordered by exit time (new records are usually last).
static func _insert_sorted(recs: Array, record: Array) -> void:
	var i := recs.size()
	while i > 0 and recs[i - 1][2] > record[2]:
		i -= 1
	recs.insert(i, record)


## Pushes a car that already went through this sector further back.
func _delay(si: int, other: SimCar, new_exit: float) -> void:
	other.t_next = new_exit
	var recs: Array = _records[si]
	for i in recs.size():
		if recs[i][0] == other:
			var r: Array = recs[i]
			recs.remove_at(i)
			r[2] = new_exit
			_insert_sorted(recs, r)
			break


func _resolve_traffic(car: SimCar, ahead: Array, si: int, sector: TrackModel.Sector,
		t_in: float, exit: float, _gap_in: float) -> float:
	var other: SimCar = ahead[0]
	var other_exit: float = ahead[2]
	var min_gap := SimTuning.SC_GAP_S if flag == Flag.SAFETY_CAR else SimTuning.MIN_GAP_S
	if exit >= other_exit + min_gap:
		return exit
	if flag != Flag.GREEN:
		return other_exit + min_gap

	# Team orders and blue flags: the car ahead lets the faster car through.
	var let_by: bool = other.orders.get("let_by") == car
	if let_by:
		other.orders.erase("let_by")
		other.orders["yield"] = true
		_log(car, "team_orders", "%s lets %s through" % [other.label(), car.label()])
	if let_by or other.laps_done < car.laps_done:
		var loss := SimTuning.BLUE_FLAG_LOSS_S * (1.3 - other.driver.racecraft / 100.0)
		var my_exit := maxf(exit, other_exit - 0.1) + 0.1
		_delay(si, other, maxf(other_exit + loss, my_exit + SimTuning.MIN_GAP_S))
		return my_exit

	var margin := other_exit - exit
	var aggression := PaceModel.aggression(car)
	var zone := sector.overtake_chance
	var lap1 := car.laps_done == 0
	if lap1:
		zone = maxf(zone * SimTuning.LAP1_PASS_FACTOR, SimTuning.START_PASS_FACTOR if si == 0 else 0.0)
	if _holds_position(car, other):
		zone = 0.0
	var threshold := SimTuning.ATTEMPT_BASE_S - SimTuning.ATTEMPT_AGGRESSION_S * aggression
	if zone <= 0.0 or margin < threshold:
		if other_exit + min_gap - exit > 0.3 * model.scale:
			car.set_meta("held_up", true)
		return other_exit + min_gap

	var wet := conditions.weather.wetness_at(t_in)
	var spray := conditions.weather.rain_at(t_in) > 0.3
	# Contact risk on every attempt.
	var racecraft := (car.driver.racecraft + other.driver.racecraft) / 200.0
	var contact := SimTuning.CONTACT_CHANCE * (aggression + PaceModel.aggression(other)) * (1.6 - racecraft) \
		* (1.0 + car.talk_value("contact") + PaceModel.briefing_value(car, "contact"))
	if wet > 0.3:
		contact *= 2.0
	if lap1:
		contact *= 2.0
	if car.rng.randf() < contact:
		return _contact(car, other, si, exit, other_exit)

	var d := car.driver
	var o := other.driver
	var skill := 1.0 + (d.overtaking + d.braking / 2.0 - o.defending - o.racecraft / 2.0) / 150.0 \
		+ (d.wet_skill - o.wet_skill) / 150.0 * wet
	var chance := zone * SimTuning.PASS_ZONE_FACTOR * skill * (1.0 + SimTuning.WET_PASS_BONUS * wet) \
		/ (1.0 + exp(-(margin - SimTuning.PASS_CENTER_S) / SimTuning.PASS_SIGMOID_S))
	if spray:
		chance *= SimTuning.SPRAY_PASS
	chance = clampf(chance, 0.0, SimTuning.PASS_MAX_CHANCE)
	if car.rng.randf() < chance:
		var my_exit := minf(exit, other_exit - 0.05)
		# Only one pass per sector: respect the car ahead of the passed one.
		var second := _second_record(si, car, other)
		if not second.is_empty():
			my_exit = maxf(my_exit, second[2] + SimTuning.MIN_GAP_S)
		_delay(si, other, maxf(other_exit + SimTuning.PASSED_LOSS_S, my_exit + SimTuning.MIN_GAP_S))
		car.overtakes_made += 1
		other.overtakes_lost += 1
		_overtakes += 1
		overtakes_by_lap[car.laps_done + 1] = overtakes_by_lap.get(car.laps_done + 1, 0) + 1
		if car.is_player or other.is_player or car.laps_done == 0:
			_log(car, "overtake", "%s passes %s" % [d.last_name, o.last_name])
		return my_exit
	# Defended: both lose a little, the defender's tyres suffer.
	_delay(si, other, other_exit + SimTuning.DEFEND_LOSS_S)
	other.tyre_wear_laps += 0.2
	return other_exit + SimTuning.DEFEND_LOSS_S + min_gap + SimTuning.FAILED_PASS_LOSS_S


func _second_record(si: int, car: SimCar, other: SimCar) -> Array:
	var recs: Array = _records[si]
	for i in range(recs.size() - 1, -1, -1):
		var r: Array = recs[i]
		if r[0] != car and r[0] != other and r[0].is_running():
			return r
	return []


## Team orders: a team player (briefing or talk) does not attack his teammate,
## and neither does a driver told to yield or to hold after the last stop.
func _holds_position(car: SimCar, other: SimCar) -> bool:
	if car.team != other.team:
		return false
	if car.orders.get("yield", false):
		return true
	if car.orders.get("hold_after_stops", false) and car.plan.is_empty() and other.plan.is_empty() \
			and not car.stops.is_empty() and not other.stops.is_empty():
		return true
	return car.talk.get("team_orders", false) or car.briefing == SimCar.Briefing.TEAM_PLAYER


func _contact(car: SimCar, other: SimCar, si: int, exit: float, other_exit: float) -> float:
	_log(car, "contact", "Contact between %s and %s" % [car.label(), other.label()])
	var victims: Array[SimCar] = [car, other]
	for victim in victims:
		_apply_damage(victim, victim.rng.randf())
	# A retirement already called the incident; otherwise debris may.
	if car.is_running() and other.is_running() and car.rng.randf() < 0.4:
		_incident("debris")
	if not car.is_running():
		return exit
	# Both lose time; the order stays as it was.
	if other.is_running():
		_delay(si, other, other_exit + car.rng.randf_range(0.5, 2.0))
	return maxf(exit, other.t_next if other.is_running() else exit) + car.rng.randf_range(0.5, 3.0)


## Damage from contacts and off-track moments (section 7).
func _apply_damage(car: SimCar, roll: float) -> void:
	if roll < 0.45:
		car.damage["front_wing"] = car.damage.get("front_wing", 0.0) + car.rng.randf_range(0.1, 0.3) * model.scale
	elif roll < 0.65:
		car.damage["front_wing"] = car.damage.get("front_wing", 0.0) + car.rng.randf_range(1.0, 3.0) * model.scale
		car.needs_nose = true
	elif roll < 0.77:
		car.puncture = true
		# Limps for the rest of the lap, then pits.
		car.lap_extra_s += car.rng.randf_range(15.0, 30.0) * model.scale
		if car.rng.randf() < 0.3:
			car.damage["floor"] = car.damage.get("floor", 0.0) + car.rng.randf_range(0.1, 0.3) * model.scale
	elif roll < 0.88:
		car.damage["floor"] = car.damage.get("floor", 0.0) + car.rng.randf_range(0.1, 0.5) * model.scale
	elif roll < 0.93:
		car.damage["rear_wing"] = 0.2 * model.scale
		car.drs_broken = true
	else:
		_retire(car, "Suspension damage", true)
		return
	if car.is_player:
		_log(car, "damage", "%s damaged" % car.label())


# --- Line crossing ---------------------------------------------------------

func _on_line(car: SimCar) -> void:
	var t := car.t_next
	car.laps_done += 1
	var lap_time := t - car.lap_start_t
	car.lap_times.append(lap_time)
	car.lap_compounds.append(car.compound)
	if car.laps_done > 1 and lap_time < car.best_lap and not car.has_meta("red_lap"):
		car.best_lap = lap_time
	car.remove_meta("red_lap")
	var count: int = _line_count.get(car.laps_done, 0) + 1
	_line_count[car.laps_done] = count
	car.position = count
	car.lap_positions.append(count)
	car.lap_start_t = t
	if count == 1:
		_on_leader_line(car)
	_add_breakdown(car, lap_time)

	if chequered or car.laps_done >= conditions.laps:
		chequered = true
		car.finished = true
		_running.erase(car)
		car.finish_t = t
		return

	_end_of_lap_wear(car, t)
	if not car.is_running():
		return
	if car.pit_now:
		_pit_stop(car)
		if not car.is_running():
			return
	_prepare_lap(car, t)
	_team_orders_moment(car)


## Adds this lap's components to the race totals. Whatever the components
## do not explain was lost (or gained) in traffic, incidents and stops.
func _add_breakdown(car: SimCar, lap_time: float) -> void:
	var total := car.breakdown_total
	var car_s := PaceModel.car_lap_s(car, model)
	total["car"] = total.get("car", 0.0) + car_s
	var explained := model.reference_lap_s + car_s + car.lap_pit_s + car.lap_flag_s
	for key in car.lap_breakdown:
		total[key] = total.get(key, 0.0) + car.lap_breakdown[key]
		explained += car.lap_breakdown[key]
	total["pit_stops"] = total.get("pit_stops", 0.0) + car.lap_pit_s
	total["safety_car"] = total.get("safety_car", 0.0) + car.lap_flag_s
	total["traffic_and_events"] = total.get("traffic_and_events", 0.0) + lap_time - explained
	car.lap_pit_s = 0.0
	car.lap_flag_s = 0.0


func _on_leader_line(car: SimCar) -> void:
	leader = car
	leader_laps = car.laps_done
	lap_weather.append([conditions.weather.wetness_at(car.t_next), conditions.weather.rain_at(car.t_next)])
	if flag == Flag.SAFETY_CAR:
		flag_laps_left -= 1
		if flag_laps_left <= 0:
			flag = Flag.GREEN
			drs_from_leader_lap = leader_laps + 3
			_end_phase()
			_log(null, "green", "Safety car in – restart")


func _end_of_lap_wear(car: SimCar, t: float) -> void:
	var wet := conditions.weather.wetness_at(t)
	var under_sc := flag == Flag.SAFETY_CAR or flag == Flag.VSC
	var dirty_share := float(car.lap_dirty_air) / model.sectors.size()
	var rate := PaceModel.wear_rate(car, dirty_share, wet)
	car.tyre_wear_laps += rate * (0.3 if under_sc else 1.0)
	car.tyre_laps += 1
	PaceModel.update_tyre_temp(car, conditions.weather.track_temp_at(t), dirty_share, under_sc)
	var use := PaceModel.fuel_per_lap(model) * (SimTuning.SC_FUEL_FACTOR if under_sc else 1.0)
	car.fuel_kg -= maxf(0.0, use - car.fuel_saving_kg_per_lap)
	if car.fuel_kg <= 0.0:
		_retire(car, "Out of fuel", true)
		return
	planner.learn(car)
	if car.has_meta("held_up"):
		car.laps_stuck += 1
		car.remove_meta("held_up")
	else:
		car.laps_stuck = 0


## Lap time extras and random events for the coming lap.
func _prepare_lap(car: SimCar, t: float) -> void:
	car.reseed_lap(car.laps_done + 1)
	var wet := conditions.weather.wetness_at(t)
	var progress := float(car.laps_done) / conditions.laps
	var b := {}
	b["driver"] = PaceModel.driver_pace_s(car, model, false) + PaceModel.briefing_value(car, "pace_s") * model.scale
	b["confidence"] = PaceModel.confidence_s(car, model)
	b["weekend_form"] = car.weekend_s
	b["fitness"] = PaceModel.fitness_s(car, model, progress)
	b["rookie"] = PaceModel.rookie_s(car, model) * (1.0 - progress)
	b["setup"] = PaceModel.setup_s(car, model)
	b["tyres"] = PaceModel.tyre_s(car, model, conditions, wet)
	b["fuel"] = PaceModel.fuel_s(car, model)
	b["weather"] = PaceModel.weather_s(car, model, wet)
	var damage := 0.0
	for v in car.damage.values():
		damage += v
	b["damage"] = damage
	b["form"] = car.rng.randfn(0.0, PaceModel.form_sigma_s(car, model))
	# Fuel saving if the fuel will not last.
	var laps_left := conditions.laps - car.laps_done
	var projected := car.fuel_kg - PaceModel.fuel_per_lap(model) * laps_left
	car.fuel_saving_kg_per_lap = clampf((0.3 - projected) / maxf(laps_left, 1), 0.0, SimTuning.FUEL_SAVE_MAX_PER_LAP)
	b["fuel_saving"] = car.fuel_saving_kg_per_lap * PaceModel.fuel_save_cost(car) * model.scale
	car.lap_breakdown = b
	var total := 0.0
	for v in b.values():
		total += v
	car.lap_extra_s = total
	car.lap_incident.clear()
	var was_in_duel := car.lap_dirty_air > 2
	car.lap_dirty_air = 0
	_roll_lap_events(car, t, wet, progress, was_in_duel)


func _roll_lap_events(car: SimCar, t: float, wet: float, progress: float, in_duel: bool) -> void:
	var n := model.sectors.size()
	# Failures.
	var reliability := car.car_data.reliability
	var failure := SimTuning.FAILURE_PER_RACE * (1.5 - reliability / 100.0) \
		* (1.3 - car.ops.reliability_staff / 100.0 * 0.6) / conditions.laps
	if car.rng.randf() < failure:
		if car.rng.randf() < SimTuning.FAILURE_FATAL_SHARE:
			car.lap_incident.append([car.rng.randi() % n, 0.0, "failure", FAILURES[car.rng.randi() % FAILURES.size()]])
		else:
			var p: Array = PARTIAL_FAILURES[car.rng.randi() % PARTIAL_FAILURES.size()]
			if not car.damage.has(p[0]):
				car.damage[p[0]] = car.rng.randf_range(p[2], p[3]) * model.scale
				_log(car, "failure", "%s: %s" % [car.label(), p[1]])
	# Tyres far past their cliff can fail.
	var over_cliff := car.tyre_wear_laps - PaceModel.tyre_life(car.compound, conditions) - SimTuning.PUNCTURE_AFTER_CLIFF_LAPS
	if over_cliff > 0.0 and not car.puncture and car.rng.randf() < SimTuning.PUNCTURE_PER_LAP * over_cliff:
		car.puncture = true
		car.lap_extra_s += car.rng.randf_range(15.0, 30.0) * model.scale
		if car.rng.randf() < 0.3:
			car.damage["floor"] = car.damage.get("floor", 0.0) + car.rng.randf_range(0.1, 0.3) * model.scale
		_log(car, "puncture", "%s: puncture on worn tyres" % car.label())
	# Driver mistakes.
	var context := {
		"progress": progress,
		"duel": in_duel,
		"wetness": wet,
		"spray": conditions.weather.rain_at(t) > 0.3,
		"stint_share": clampf(car.tyre_laps / 30.0, 0.0, 1.0),
		"tyre_over_cliff": maxf(0.0, car.tyre_wear_laps - PaceModel.tyre_life(car.compound, conditions)),
	}
	if flag == Flag.GREEN and car.rng.randf() < PaceModel.mistake_chance(car, context):
		car.mistakes += 1
		var roll := car.rng.randf()
		var sector := car.rng.randi() % n
		if roll < SimTuning.MISTAKE_SEVERITY[0]:
			car.lap_incident.append([sector, car.rng.randf_range(SimTuning.MISTAKE_SMALL[0], SimTuning.MISTAKE_SMALL[1]) * model.scale, "mistake"])
			if car.rng.randf() < 0.25:
				car.tyre_wear_laps += 1.5  # flat spot
		elif roll < SimTuning.MISTAKE_SEVERITY[0] + SimTuning.MISTAKE_SEVERITY[1]:
			car.lap_incident.append([sector, car.rng.randf_range(SimTuning.MISTAKE_OFF[0], SimTuning.MISTAKE_OFF[1]) * model.scale, "off"])
			if car.rng.randf() < 0.25:
				_apply_damage(car, car.rng.randf() * 0.65)
			if car.is_player:
				_log(car, "mistake", "%s goes off track" % car.label())
		else:
			car.lap_incident.append([sector, 0.0, "crash"])


# --- Strategy and pit stops --------------------------------------------------

## Decided when the car starts its last sector (pit entry comes before the line).
func _strategy_decisions(car: SimCar) -> void:
	if car.pit_now or chequered:
		return
	var laps_left := conditions.laps - car.laps_done - 1
	# Own random stream for the strategy calls of this lap.
	car.reseed_lap(10000 + car.laps_done)
	if laps_left <= 0:
		return
	if car.puncture or car.needs_nose:
		_request_pit(car, planner.compound_for_stop_now(car) if not PaceModel.is_wet_compound(car.compound) else car.compound)
		return
	var weather := planner.weather_call(car, time_s, laps_left)
	# The team principal said "stay out" a moment ago.
	if weather != &"" and car.get_meta("weather_hold", -1) >= car.laps_done:
		weather = &""
	if weather != &"" and car.is_player and _can_ask() and car.get_meta("weather_asked", &"") != weather:
		_weather_moment(car, weather, laps_left)
		return
	if weather != &"":
		_request_pit(car, weather if PaceModel.is_wet_compound(weather) else planner.compound_for_stop_now(car))
		return
	if PaceModel.is_wet_compound(car.compound):
		return
	# One call per safety car phase, at the first pass of the pit entry.
	if (flag == Flag.SAFETY_CAR or flag == Flag.VSC) and not car.has_meta("flag_call_made"):
		car.set_meta("flag_call_made", true)
		var box: bool = car.get_meta("player_sc_call") if car.has_meta("player_sc_call") \
			else planner.safety_car_call(car, laps_left, flag == Flag.VSC)
		if box:
			_request_pit(car, planner.compound_for_stop_now(car))
			return
	var dry_rule_open := car.used_dry_compounds.size() < 2 and conditions.weather.max_rain() < 0.05
	var planned_now: bool = not car.plan.is_empty() and car.plan[0][0] <= car.laps_done + 1
	if planned_now and planner.clean_air_delay(car, _rejoins_in_traffic(car)):
		car.plan[0][0] += 1
		return
	if planned_now or (not car.plan.is_empty() and (planner.undercut_call(car) \
			or planner.cover_call(car, _undercut_threat(car)))):
		_request_pit(car, car.plan[0][1])
	elif car.plan.is_empty() and dry_rule_open and laps_left <= 2:
		_request_pit(car, planner.compound_for_stop_now(car))


## Would the car come out of the pits right behind a slower car? Estimated
## from when the others will pass the pit exit and how fast they lap.
func _rejoins_in_traffic(car: SimCar) -> bool:
	var stop_s := SimTuning.curve(SimTuning.STOP_CURVE, car.ops.stop_speed)
	var rejoin: float = time_s + model.sectors.back().reference_s + model.pit_lane_loss_s + stop_s
	var my_pace: float = (car.lap_times[-1] if not car.lap_times.is_empty() else model.reference_lap_s) - 1.0 * model.scale
	for other in _running:
		if other == car or other.laps_done < car.laps_done or other.lap_times.is_empty():
			continue
		var pace: float = other.lap_times[-1]
		var cross := other.lap_start_t
		while cross < rejoin - 1.5:
			cross += pace
		# Just ahead of us at the pit exit and clearly slower than us on fresh tyres.
		if cross <= rejoin and pace > my_pace + 0.4 * model.scale:
			return true
	return false


## Gap (s) to a car that was just behind and stopped at the end of the
## last lap – it is trying to undercut us. INF if there is none.
func _undercut_threat(car: SimCar) -> float:
	for other in _running:
		if other == car or other.stops.is_empty():
			continue
		var last: Dictionary = other.stops.back()
		if last.lap == car.laps_done and other.lap_positions.size() >= car.laps_done \
				and other.lap_positions[car.laps_done - 1] in [car.position + 1, car.position + 2] \
				and last.t - car.lap_start_t < 3.0:
			return last.t - car.lap_start_t
	return INF


func _request_pit(car: SimCar, compound: StringName) -> void:
	car.pit_now = true
	car.next_compound = compound


func _pit_stop(car: SimCar) -> void:
	car.pit_now = false
	car.reseed_lap(20000 + car.laps_done)
	var pressure := 1.0
	var wait := 0.0
	# Double stack: the teammate stopped moments ago.
	for other in cars:
		if other != car and other.team == car.team and not other.stops.is_empty():
			var last: Dictionary = other.stops.back()
			if last.lap == car.laps_done and absf(last.t - car.t_next) < last.stationary + 3.0:
				pressure *= SimTuning.PRESSURE_DOUBLE_STACK
				wait = SimTuning.DOUBLE_STACK_WAIT_S
	if flag == Flag.SAFETY_CAR:
		pressure *= SimTuning.PRESSURE_SC
	if PaceModel.is_wet_compound(car.next_compound) or PaceModel.is_wet_compound(car.compound):
		pressure *= SimTuning.PRESSURE_WET
	var extra := SimTuning.NOSE_CHANGE_S if car.needs_nose else 0.0
	var result := PitCrew.stop(car.ops, extra + wait, pressure, car.rng)
	var lane := model.pit_lane_loss_s
	if flag == Flag.SAFETY_CAR:
		lane *= SimTuning.PIT_LOSS_SC
	elif flag == Flag.VSC:
		lane *= SimTuning.PIT_LOSS_VSC
	var stop := {"lap": car.laps_done, "t": car.t_next, "stationary": result.stationary, "lane": lane + result.stationary,
		"from": car.compound, "to": car.next_compound, "issue": PitCrew.ISSUE_NAMES[result.issue], "flag": Flag.keys()[flag]}
	car.stops.append(stop)
	car.t_next += lane + result.stationary
	car.lap_pit_s += lane + result.stationary
	car.penalty_s += result.penalty
	car.compound = car.next_compound
	if not PaceModel.is_wet_compound(car.compound):
		car.used_dry_compounds[car.compound] = true
	car.tyre_wear_laps = 0.0
	car.tyre_laps = 0
	car.tyre_temp = SimTuning.NEW_TYRE_TEMP
	car.puncture = false
	if car.needs_nose:
		car.needs_nose = false
		car.damage.erase("front_wing")
	if result.issue != PitCrew.Issue.NONE and (car.is_player or result.issue >= PitCrew.Issue.STUCK_NUT):
		_log(car, "pit_issue", "%s: %s (%.1f s)" % [car.label(), PitCrew.ISSUE_NAMES[result.issue], result.stationary])
	if result.retire:
		_retire(car, "Loose wheel", true)
		return
	planner.replan_after_stop(car)


# --- Key moments ---------------------------------------------------------------

const MAX_MOMENTS := 4


func _can_ask() -> bool:
	return ask_player and moment.is_empty() and moments_asked < MAX_MOMENTS and not chequered


func answer_moment(index: int) -> void:
	var m := moment
	moment = {}
	var actions: Array = m.get("actions", [])
	if index >= 0 and index < actions.size():
		(actions[index] as Callable).call()


func _player_running() -> Array[SimCar]:
	var out: Array[SimCar] = []
	for car in _running:
		if car.is_player:
			out.append(car)
	out.sort_custom(func(a: SimCar, b: SimCar): return a.position < b.position)
	return out


## Current running order: most laps first, then who crossed the line first;
## retired cars at the end.
func running_order() -> Array[SimCar]:
	var out: Array[SimCar] = cars.duplicate()
	out.sort_custom(func(a: SimCar, b: SimCar):
		if a.is_running() != b.is_running():
			return a.is_running()
		if a.laps_done != b.laps_done:
			return a.laps_done > b.laps_done
		return a.lap_start_t < b.lap_start_t)
	return out


## Gap to the leader, measured where both crossed the line on the same lap:
## [laps behind, seconds]. The leader gets [0, 0.0].
func gap_to_leader(car: SimCar) -> Array:
	var order := running_order()
	var lead: SimCar = order[0]
	if car == lead or car.laps_done == 0:
		return [0, 0.0]
	var k := mini(car.laps_done, lead.laps_done)
	var lead_t := 0.0
	for i in k:
		lead_t += lead.lap_times[i]
	var gap: float = car.lap_start_t - lead_t
	var laps := lead.laps_done - car.laps_done
	# One lap less but still within a lap of the leader: same lap, not lapped.
	if laps == 1 and k < lead.lap_times.size() and gap < lead.lap_times[k]:
		laps = 0
	return [laps, gap]


func _open_moment(m: Dictionary) -> void:
	moments_asked += 1
	m["lap"] = leader_laps + 1
	moment = m


## A translatable text: format plus arguments.
static func _tx(format: String, args: Array = []) -> Array:
	return [format, args]


const COMPOUND_NAMES := {&"soft": "Soft", &"medium": "Medium", &"hard": "Hard", &"inter": "Intermediate", &"wet": "Wet"}


static func _tyre_text(car: SimCar) -> Array:
	return _tx("%s · %d laps", [COMPOUND_NAMES.get(car.compound, String(car.compound)), car.tyre_laps])


## Safety car or VSC: stop now for a cheap pit stop?
func _safety_car_moment(is_vsc: bool) -> void:
	if not _can_ask():
		return
	var own := _player_running().filter(func(c: SimCar): return not PaceModel.is_wet_compound(c.compound) and not c.pit_now)
	var laps_left := conditions.laps - leader_laps - 1
	if own.is_empty() or laps_left < 4:
		return
	# What the strategy chief would do (without using up the car's luck).
	var calls := {}
	for car: SimCar in own:
		var state := car.rng.state
		calls[car] = planner.safety_car_call(car, conditions.laps - car.laps_done - 1, is_vsc)
		car.rng.state = state
	var normal := model.pit_lane_loss_s + 2.5
	var cheap := model.pit_lane_loss_s * (SimTuning.PIT_LOSS_VSC if is_vsc else SimTuning.PIT_LOSS_SC) + 2.5
	var options := []
	var plans := []
	if own.size() == 1:
		options.append([_tx("Box now"), _tx("A cheap stop under the virtual safety car." if is_vsc else "A cheap stop under the safety car.")])
		plans.append({own[0]: true})
	else:
		options.append([_tx("Box both now"), _tx("Cheap stop for both cars. The second car may wait behind the first (double stop, +3 s).")])
		plans.append({own[0]: true, own[1]: true})
		for car: SimCar in own:
			var other: SimCar = own[1] if car == own[0] else own[0]
			options.append([_tx("Box %s only", [car.driver.last_name]), _tx("%s keeps track position and stays out on his tyres.", [other.driver.last_name])])
			plans.append({car: true, other: false})
	options.append([_tx("Stay out"), _tx("Keep track position. Stop later at full pit lane loss.")])
	var stay := {}
	for car in own:
		stay[car] = false
	plans.append(stay)
	var recommended := plans.size() - 1
	for i in plans.size():
		var same := true
		for car in own:
			if plans[i][car] != calls[car]:
				same = false
		if same:
			recommended = i
	var facts := []
	for car: SimCar in own:
		var tyres: Array = _tyre_text(car)[1]
		var planned := _tx("%s · %d laps · no stop planned", tyres) if car.plan.is_empty() \
			else _tx("%s · %d laps · next stop planned on lap %d", tyres + [car.plan[0][0]])
		facts.append([_tx("%s · P%d", [car.driver.last_name, car.position]), planned])
	facts.append([_tx("Pit stop now"), _tx("about %d s instead of %d s", [roundi(cheap), roundi(normal)])])
	facts.append([_tx("Laps left"), _tx("%d", [laps_left])])
	var actions := []
	for p in plans:
		actions.append(func():
			for car in p:
				car.set_meta("player_sc_call", p[car]))
	var cause := _tx("")
	for i in range(events.size() - 1, -1, -1):
		if events[i].kind in ["retired", "contact", "damage", "mistake"]:
			cause = _tx(events[i].text)
			break
	_open_moment({"kind": "vsc" if is_vsc else "sc", "title": _tx("Virtual safety car" if is_vsc else "Safety car"),
		"text": cause, "facts": facts, "options": options, "recommended": recommended, "cars": own, "actions": actions})


## Rain starts or the track dries: change tyres now?
func _weather_moment(car: SimCar, compound: StringName, laps_left: int) -> void:
	var to_wet := PaceModel.is_wet_compound(compound)
	var target := compound if to_wet else planner.compound_for_stop_now(car)
	var wet := conditions.weather.wetness_at(time_s)
	var name: String = COMPOUND_NAMES.get(target, String(target))
	var title := _tx("Rain – change to %s?", [name]) if to_wet else _tx("Track drying – back to %s?", [name])
	var options := [
		[_tx("Box now for %s", [name]), _tx("The strategy chief's call: the new tyres are faster from now on.")],
		[_tx("Stay out two more laps"), _tx("Wait and see. After that the strategy chief decides.")],
	]
	var facts := [
		[_tx("%s · P%d", [car.driver.last_name, car.position]), _tyre_text(car)],
		[_tx("Track"), _tx("%d %% wet", [roundi(wet * 100)])],
		[_tx("Rain now"), _tx("Yes" if conditions.weather.rain_at(time_s) > 0.1 else "No")],
		[_tx("Laps left"), _tx("%d", [laps_left])],
	]
	var actions := [
		func():
			car.set_meta("weather_asked", compound)
			_request_pit(car, target),
		func():
			car.set_meta("weather_asked", compound)
			car.set_meta("weather_hold", car.laps_done + 2),
	]
	_open_moment({"kind": "weather", "title": title, "text": _tx(""), "facts": facts, "options": options,
		"recommended": 0, "cars": [car], "actions": actions})


## The faster teammate is stuck behind the other: swap them?
func _team_orders_moment(car: SimCar) -> void:
	if not car.is_player or not _can_ask() or flag != Flag.GREEN or car.position <= 1:
		return
	var laps_left := conditions.laps - car.laps_done
	if laps_left < 5 or car.lap_times.size() < 4:
		return
	var mate: SimCar = null
	for other in _running:
		if other != car and other.team == car.team:
			mate = other
	if not mate or mate.laps_done != car.laps_done or mate.position != car.position - 1:
		return
	if not car.orders.is_empty() or not mate.orders.is_empty() or car.briefing == SimCar.Briefing.TEAM_PLAYER:
		return
	if car.get_meta("orders_asked_lap", -99) > car.laps_done - 12:
		return
	var gap := car.lap_start_t - mate.lap_start_t
	var mine := _recent_pace(car)
	var theirs := _recent_pace(mate)
	if gap > 1.5 or theirs - mine < 0.25 * model.scale:
		return
	car.set_meta("orders_asked_lap", car.laps_done)
	var fast := car.driver.last_name
	var slow := mate.driver.last_name
	var gain := (theirs - mine) * laps_left
	var options := [
		[_tx("Swap positions"), _tx("%s lets %s through. %s's morale −3 – and he may refuse.", [slow, fast, slow])],
		[_tx("Let them race"), _tx("They may fight. Risk of contact between your own cars.")],
		[_tx("Hold positions"), _tx("%s stays behind. %s's morale −2.", [fast, fast])],
	]
	var facts := [
		[_tx("%s · P%d", [slow, mate.position]), _tx("%s · %d laps · %.3f s per lap", _tyre_text(mate)[1] + [theirs])],
		[_tx("%s · P%d", [fast, car.position]), _tx("%s · %d laps · %.3f s per lap", _tyre_text(car)[1] + [mine])],
		[_tx("Gap"), _tx("%.1f s", [gap])],
		[_tx("Laps left"), _tx("%d", [laps_left])],
	]
	var actions := [
		func():
			# Hot heads and unhappy drivers may ignore the call.
			var refuse := clampf((50.0 - mate.driver.temperament) / 120.0 + (45.0 - mate.driver.morale) / 120.0
				+ (50.0 - mate.driver.loyalty) / 200.0, 0.0, 0.45)
			if car.rng.randf() < refuse:
				_log(mate, "team_orders", "%s ignores the team order" % mate.label())
				morale_effects.append([car.driver, "Teammate ignored team orders", -3])
			else:
				mate.orders["let_by"] = car
				morale_effects.append([mate.driver, "Team orders: let teammate pass", -3]),
		func(): pass,
		func():
			car.orders["yield"] = true
			morale_effects.append([car.driver, "Team orders: hold position", -2]),
	]
	_open_moment({"kind": "orders", "title": _tx("Team orders – %s is faster than %s", [fast, slow]), "text": _tx(""),
		"facts": facts, "options": options, "recommended": 0 if gain > 3.0 * model.scale else 1,
		"cars": [mate, car], "actions": actions})


## Average of the last three green laps (s).
func _recent_pace(car: SimCar) -> float:
	var n := mini(3, car.lap_times.size())
	var total := 0.0
	for i in n:
		total += car.lap_times[car.lap_times.size() - 1 - i]
	return total / maxf(n, 1)


# --- Flags and incidents -------------------------------------------------------

func _update_flags() -> void:
	if flag == Flag.VSC and time_s >= vsc_end_s:
		flag = Flag.GREEN
		_end_phase()
		_log(null, "green", "VSC ending – green flag")
	# Heavy rain stops the race.
	if flag != Flag.RED and conditions.weather.rain_at(time_s) > 0.95 and conditions.weather.wetness_at(time_s) > 0.97:
		_red_flag("Heavy rain")


## Decides the flag after an incident (section 8.3).
func _incident(kind: String) -> void:
	if flag == Flag.RED or chequered:
		return
	var risk := conditions.safety_car_risk
	var roll := rng.randf()
	match kind:
		"crash":
			if rng.randf() < 0.08 * risk:
				_red_flag("Barrier repairs")
			elif roll < 0.7 * minf(risk, 1.3):
				_deploy_sc()
			elif roll < 0.95:
				_deploy_vsc()
		"stopped":
			if roll < 0.5 * minf(risk, 1.6):
				_deploy_vsc()
		"debris":
			if roll < 0.15 * risk:
				_deploy_sc()
			elif roll < 0.3 * risk:
				_deploy_vsc()


func _deploy_sc() -> void:
	if flag == Flag.SAFETY_CAR:
		flag_laps_left = maxi(flag_laps_left, 2)
		return
	if flag == Flag.VSC:
		_end_phase()
	flag = Flag.SAFETY_CAR
	flag_laps_left = rng.randi_range(SimTuning.SC_LAPS[0], SimTuning.SC_LAPS[1])
	_clear_flag_stops()
	phases.append({"kind": "SC", "from_lap": leader_laps + 1, "to_lap": leader_laps + 1})
	_log(null, "sc", "Safety car deployed")
	_safety_car_moment(false)


func _deploy_vsc() -> void:
	if flag != Flag.GREEN:
		return
	flag = Flag.VSC
	vsc_end_s = time_s + rng.randf_range(SimTuning.VSC_TIME_S[0], SimTuning.VSC_TIME_S[1])
	_clear_flag_stops()
	phases.append({"kind": "VSC", "from_lap": leader_laps + 1, "to_lap": leader_laps + 1})
	_log(null, "vsc", "Virtual safety car")
	_safety_car_moment(true)


func _clear_flag_stops() -> void:
	for car in cars:
		car.remove_meta("flag_call_made")
		car.remove_meta("player_sc_call")


func _end_phase() -> void:
	if not phases.is_empty():
		phases.back().to_lap = maxi(phases.back().from_lap, leader_laps)


## Stops the race; cars line up in order and restart behind the safety car
## with a free tyre change.
func _red_flag(reason: String) -> void:
	if flag == Flag.SAFETY_CAR or flag == Flag.VSC:
		_end_phase()
	phases.append({"kind": "RED", "from_lap": leader_laps + 1, "to_lap": leader_laps + 1})
	_log(null, "red", "Red flag – %s" % reason)
	var running := cars.filter(func(c: SimCar): return c.is_running())
	running.sort_custom(func(a: SimCar, b: SimCar):
		if a.laps_done != b.laps_done:
			return a.laps_done > b.laps_done
		if a.next_sector != b.next_sector:
			return a.next_sector > b.next_sector
		return a.t_next < b.t_next)
	var restart := time_s + RED_FLAG_PAUSE_S
	var wet := conditions.weather.wetness_at(restart)
	for i in running.size():
		var car: SimCar = running[i]
		car.next_sector = 0
		car.t_next = restart + i * SimTuning.SC_GAP_S
		car.lap_incident.clear()
		car.pit_now = false
		car.set_meta("red_lap", true)
		_line_pending[car] = false
		# Free tyre change for the conditions.
		var dry := planner.compound_for_stop_now(car)
		car.compound = PaceModel.ideal_compound_for(wet, dry)
		if not PaceModel.is_wet_compound(car.compound):
			car.used_dry_compounds[car.compound] = true
		car.tyre_wear_laps = 0.0
		car.tyre_laps = 0
		car.tyre_temp = SimTuning.NEW_TYRE_TEMP
		car.lap_start_t = car.t_next
		_prepare_lap(car, car.t_next)
		planner.replan_after_stop(car)
	for recs in _records:
		recs.clear()
	_end_phase()
	flag = Flag.SAFETY_CAR
	flag_laps_left = 1
	phases.append({"kind": "SC", "from_lap": leader_laps + 1, "to_lap": leader_laps + 1})


func _retire(car: SimCar, reason: String, on_track: bool) -> void:
	car.retired = true
	_running.erase(car)
	car.retire_reason = reason
	car.retire_lap = car.laps_done + 1
	for recs in _records:
		for i in range(recs.size() - 1, -1, -1):
			if recs[i][0] == car:
				recs.remove_at(i)
	_log(car, "retired", "%s retires: %s" % [car.label(), reason])
	if on_track:
		_incident("crash" if reason == "Crash" or reason.contains("damage") else "stopped")


func _log(car: SimCar, kind: String, text: String) -> void:
	events.append({"lap": leader_laps + 1, "t": time_s, "kind": kind,
		"driver": car.driver.id if car else &"", "text": text})


# --- Results -------------------------------------------------------------------

## Final classification: finishers by laps and time (incl. penalties), then retirements.
func classification() -> Array[SimCar]:
	var out: Array[SimCar] = cars.duplicate()
	out.sort_custom(func(a: SimCar, b: SimCar):
		if a.retired != b.retired:
			return b.retired
		if a.laps_done != b.laps_done:
			return a.laps_done > b.laps_done
		if a.retired:
			return a.retire_lap > b.retire_lap
		return a.race_time() < b.race_time())
	return out


func overtake_count() -> int:
	return _overtakes
