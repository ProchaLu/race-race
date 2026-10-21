## Formula-based race simulation. Pure logic: no nodes, no drawing.
## Call step() at a fixed rate; views only read the car states and signals.
class_name RaceSim
extends RefCounted

signal lap_completed(car: RaceCarState)
signal overtake(attacker: RaceCarState, defender: RaceCarState)
signal pit_stop(car: RaceCarState)
signal driver_mistake(car: RaceCarState)
signal car_retired(car: RaceCarState)
signal race_finished()

const TICK_S := 0.1

# Grid and traffic
const GRID_OFFSET_M := 5.0
const GRID_SPACING_M := 8.0
const FOLLOW_GAP_M := 6.0
const DIRTY_AIR_M := 25.0
const DIRTY_AIR_PENALTY := 0.995
const SLIPSTREAM_BONUS := 0.03
const PASS_TIME_S := 5.0
const OVERTAKE_RATE := 0.06
const GAP_BUCKET_M := 50.0

# Fuel and tyres
const FUEL_PER_LAP_KG := 1.8
const FUEL_MARGIN := 1.04
const FUEL_PENALTY_PER_KG := 0.0003
const TYRE_CLIFF := 70.0
const TYRE_END_LIMIT := 80.0
const AI_PIT_WEAR := 65.0

# Randomness
const FORM_SIGMA := 0.003
const MISTAKE_CHANCE := 0.03   # per lap, before skill/pace modifiers
const MISTAKE_SPEED := 0.6
const CRASH_CHANCE := 0.05     # share of mistakes that end in the wall
const FAILURE_CHANCE := 0.004  # per lap, before reliability modifier
const FAILURES := ["Engine failure", "Gearbox failure", "Hydraulics failure"]

# Indexed by RaceCarState.PaceMode (CONSERVE, NORMAL, PUSH).
const PACE_SPEED: Array[float] = [0.99, 1.0, 1.008]
const PACE_WEAR: Array[float] = [0.7, 1.0, 1.5]
const PACE_FUEL: Array[float] = [0.94, 1.0, 1.06]
const PACE_MISTAKE: Array[float] = [0.6, 1.0, 1.8]

var track: TrackData
var profile: TrackProfile
## Available compounds, ordered softest first.
var compounds: Array[TyreCompound]
var cars: Array[RaceCarState] = []
## Current running order, leader first.
var order: Array[RaceCarState] = []
var time_s: float = 0.0
var leader_finished: bool = false
var is_finished: bool = false
var rng := RandomNumberGenerator.new()

## Time at which the leader first reached each GAP_BUCKET_M mark.
var _gap_marks := PackedFloat64Array()


func _init(p_track: TrackData, p_compounds: Array[TyreCompound],
		entries: Array[RaceCarState], seed_value: int = 0) -> void:
	track = p_track
	compounds = p_compounds
	profile = TrackProfile.build(track)
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	cars = entries
	for i in cars.size():
		var car := cars[i]
		car.grid_position = i + 1
		car.race_distance_m = -(GRID_OFFSET_M + i * GRID_SPACING_M)
		car.fuel_kg = FUEL_PER_LAP_KG * track.laps * FUEL_MARGIN
		car.stationary_timer = _reaction_time(car)
		_cache_performance(car)
	order = cars.duplicate()


## Advances the race by one fixed tick.
func step() -> void:
	if is_finished:
		return
	time_s += TICK_S
	for car in order:
		if car.is_running():
			_update_car(car)
	order.sort_custom(_is_ahead)
	_update_gaps()

	if order.all(func(c: RaceCarState): return not c.is_running()):
		is_finished = true
		for car in cars:
			car.pass_target = null  # break reference cycles
		race_finished.emit()


func laps_left(car: RaceCarState) -> int:
	return track.laps - car.laps_completed


# --- Per-tick car update -----------------------------------------------------

func _update_car(car: RaceCarState) -> void:
	if car.stationary_timer > 0.0:
		car.stationary_timer -= TICK_S
		car.speed_mps = 0.0
		if car.stationary_timer <= 0.0 and car.in_pit:
			_complete_pit_stop(car)
		return

	var idx := profile.index_at(car.lap_distance(track.lap_length_m))
	var target := profile.speed[idx] * _performance(car, idx)
	var ahead := _car_ahead(car)
	if ahead:
		var gap := ahead.race_distance_m - car.race_distance_m
		if car.pass_target == ahead:
			target *= 1.0 + SLIPSTREAM_BONUS
		elif gap < DIRTY_AIR_M and profile.cornerness[idx] > 0.3:
			target *= DIRTY_AIR_PENALTY
	if car.mistake_timer > 0.0:
		car.mistake_timer -= TICK_S
		target *= MISTAKE_SPEED

	# Cars cannot accelerate instantly (start, pit exit, after mistakes).
	var speed := minf(target, car.speed_mps + TrackProfile.accel_at(car.speed_mps) * TICK_S)
	var new_dist := car.race_distance_m + speed * TICK_S
	if ahead:
		new_dist = _resolve_traffic(car, ahead, new_dist, target, idx)

	var moved := new_dist - car.race_distance_m
	car.speed_mps = moved / TICK_S
	car.race_distance_m = new_dist
	_consume(car, moved)
	if car.is_retired:
		return
	_check_pending_event(car)
	if car.is_retired:
		return

	var laps := floori(new_dist / track.lap_length_m)
	if laps > car.laps_completed:
		# Interpolate the exact crossing time inside this tick.
		var overshoot := new_dist - laps * track.lap_length_m
		var cross_time := time_s - overshoot / maxf(car.speed_mps, 1.0)
		_on_line_crossed(car, laps, cross_time)


## Returns the allowed new distance, taking the car ahead into account.
## target_speed is what the car could do in free air.
func _resolve_traffic(car: RaceCarState, ahead: RaceCarState, new_dist: float,
		target_speed: float, idx: int) -> float:
	if car.pass_target and car.pass_target != ahead:
		car.pass_target = null
	if car.pass_target == ahead:
		car.pass_timer -= TICK_S
		if new_dist > ahead.race_distance_m:
			car.pass_target = null
			overtake.emit(car, ahead)
			return new_dist
		if car.pass_timer > 0.0:
			return new_dist
		car.pass_target = null  # ran out of road, fall back in line

	var limit := ahead.race_distance_m - FOLLOW_GAP_M
	if new_dist <= limit:
		return new_dist
	if target_speed > ahead.speed_mps and _try_overtake(car, ahead, target_speed, idx):
		car.pass_target = ahead
		car.pass_timer = PASS_TIME_S
		return new_dist
	# Stuck behind: match the speed of the car ahead.
	return minf(new_dist, maxf(limit, car.race_distance_m + ahead.speed_mps * TICK_S))


func _try_overtake(car: RaceCarState, ahead: RaceCarState, speed: float, idx: int) -> bool:
	var advantage := (speed - ahead.speed_mps) / maxf(ahead.speed_mps, 1.0) * 100.0
	var segment := track.segments[profile.segment_index[idx]]
	var skill := 1.0 + (car.driver.overtaking - ahead.driver.defending) / 100.0
	var rate := OVERTAKE_RATE * segment.overtake_chance * minf(advantage, 3.0) * skill
	return rng.randf() < rate * TICK_S


func _car_ahead(car: RaceCarState) -> RaceCarState:
	var i := order.find(car) - 1
	while i >= 0:
		var other := order[i]
		if other.is_running() and not other.in_pit:
			return other
		i -= 1
	return null


# --- Performance model -------------------------------------------------------

## Converts 0..100 ratings into small multipliers around 1.0.
func _cache_performance(car: RaceCarState) -> void:
	var c := car.car_data
	var d := car.driver
	car.corner_factor = 1.0 + 0.025 * (0.4 * _r(c.downforce) + 0.2 * _r(c.mechanical_grip)
		+ 0.3 * _r(d.cornering) + 0.1 * _r(d.braking))
	car.straight_factor = 1.0 + 0.02 * (0.6 * _r(c.engine_power) + 0.4 * _r(c.drag_efficiency))


## Rating 0..100 -> -1..1.
static func _r(rating: int) -> float:
	return (rating - 50) / 50.0


func _performance(car: RaceCarState, idx: int) -> float:
	var f := lerpf(car.straight_factor, car.corner_factor, profile.cornerness[idx])
	f *= car.tyre.grip * _tyre_condition(car.tyre_wear)
	f *= 1.0 - car.fuel_kg * FUEL_PENALTY_PER_KG
	f *= PACE_SPEED[car.pace_mode]
	return f * car.form


## Grip multiplier from wear: slow fade, then a steep "cliff".
func _tyre_condition(wear: float) -> float:
	if wear <= TYRE_CLIFF:
		return 1.0 - 0.0004 * wear
	return maxf(0.75, 1.0 - 0.0004 * TYRE_CLIFF - 0.004 * (wear - TYRE_CLIFF))


func wear_per_m(car: RaceCarState, compound: TyreCompound) -> float:
	var driver_f := 1.3 - 0.6 * car.driver.tyre_management / 100.0
	var car_f := 1.2 - 0.4 * car.car_data.tyre_preservation / 100.0
	return compound.wear_per_km / 1000.0 * track.tyre_wear_factor * driver_f * car_f


func _consume(car: RaceCarState, moved_m: float) -> void:
	var mode := car.pace_mode
	car.tyre_wear = minf(100.0, car.tyre_wear + moved_m * wear_per_m(car, car.tyre) * PACE_WEAR[mode])
	car.fuel_kg -= moved_m / track.lap_length_m * FUEL_PER_LAP_KG * PACE_FUEL[mode]
	if car.fuel_kg <= 0.0:
		car.fuel_kg = 0.0
		_retire(car, "Out of fuel")


func _reaction_time(car: RaceCarState) -> float:
	return 0.2 + (100 - car.driver.starts) / 100.0 * 0.4 + rng.randf() * 0.25


# --- Lap events --------------------------------------------------------------

func _on_line_crossed(car: RaceCarState, laps: int, cross_time: float) -> void:
	car.laps_completed = laps
	if laps >= 1:
		car.last_lap_time_s = cross_time - car.lap_start_time_s
		# The standing-start lap does not count for the best lap.
		if laps >= 2:
			car.best_lap_time_s = minf(car.best_lap_time_s, car.last_lap_time_s)
		lap_completed.emit(car)
	car.lap_start_time_s = cross_time

	if leader_finished or laps >= track.laps:
		leader_finished = true
		car.is_finished = true
		car.finish_time_s = cross_time
		car.pass_target = null
		return

	_roll_lap_events(car)
	if not car.is_player:
		_ai_strategy(car)
	if car.pit_requested:
		_enter_pit(car)


## Rolls form, mistakes and failures for the coming lap.
func _roll_lap_events(car: RaceCarState) -> void:
	var consistency := car.driver.consistency / 100.0
	car.form = 1.0 + rng.randfn(0.0, FORM_SIGMA * (1.5 - consistency))
	car.pending_event = RaceCarState.PendingEvent.NONE

	var failure := FAILURE_CHANCE * (1.1 - car.car_data.reliability / 100.0)
	var mistake := MISTAKE_CHANCE * (1.2 - consistency) * PACE_MISTAKE[car.pace_mode]
	if rng.randf() < failure:
		car.pending_event = RaceCarState.PendingEvent.FAILURE
	elif rng.randf() < mistake:
		car.pending_event = RaceCarState.PendingEvent.MISTAKE
	car.event_at_m = rng.randf_range(0.0, track.lap_length_m)


func _check_pending_event(car: RaceCarState) -> void:
	if car.pending_event == RaceCarState.PendingEvent.NONE:
		return
	if car.lap_distance(track.lap_length_m) < car.event_at_m:
		return
	var event := car.pending_event
	car.pending_event = RaceCarState.PendingEvent.NONE
	if event == RaceCarState.PendingEvent.FAILURE:
		_retire(car, FAILURES[rng.randi() % FAILURES.size()])
	elif rng.randf() < CRASH_CHANCE:
		_retire(car, "Crash")
	else:
		car.mistake_timer = rng.randf_range(1.0, 3.0)
		driver_mistake.emit(car)


func _retire(car: RaceCarState, reason: String) -> void:
	car.is_retired = true
	car.retire_reason = reason
	car.pass_target = null
	car.speed_mps = 0.0
	car_retired.emit(car)


# --- Strategy and pit stops --------------------------------------------------

func _ai_strategy(car: RaceCarState) -> void:
	var left := laps_left(car)
	if left <= 1:
		return
	var wear_per_lap := wear_per_m(car, car.tyre) * track.lap_length_m
	if car.tyre_wear + wear_per_lap * left <= TYRE_END_LIMIT:
		return  # tyres will make it to the end
	if car.tyre_wear < AI_PIT_WEAR:
		return
	car.pit_requested = true
	car.next_tyre = _best_compound(car, left)


## Softest compound that lasts the given number of laps, else the hardest.
func _best_compound(car: RaceCarState, laps: int) -> TyreCompound:
	for compound in compounds:
		if wear_per_m(car, compound) * track.lap_length_m * laps <= TYRE_END_LIMIT:
			return compound
	return compounds.back()


func _enter_pit(car: RaceCarState) -> void:
	car.in_pit = true
	car.pit_requested = false
	car.pass_target = null
	car.pit_stops += 1
	car.stationary_timer = track.pit_lane_loss_s + rng.randf_range(2.2, 3.8)
	pit_stop.emit(car)


func _complete_pit_stop(car: RaceCarState) -> void:
	car.in_pit = false
	car.tyre = car.next_tyre
	car.tyre_wear = 0.0
	car.speed_mps = 22.0  # pit lane speed limit


# --- Order and gaps ----------------------------------------------------------

## Sort comparator: finished cars by laps then finish time, running cars by
## distance, retired cars last.
func _is_ahead(a: RaceCarState, b: RaceCarState) -> bool:
	if a.is_retired != b.is_retired:
		return b.is_retired
	if a.is_finished and b.is_finished and a.laps_completed == b.laps_completed:
		return a.finish_time_s < b.finish_time_s
	return _effective_distance(a) > _effective_distance(b)


func _effective_distance(car: RaceCarState) -> float:
	if car.is_finished:
		return car.laps_completed * track.lap_length_m
	return car.race_distance_m


## Gap = time the car reached a distance mark minus the leader's time there.
func _update_gaps() -> void:
	var winner_time := order[0].finish_time_s if order[0].is_finished else 0.0
	for car in order:
		if car.is_finished:
			car.gap_to_leader_s = car.finish_time_s - winner_time
			continue
		if car.is_retired:
			continue
		var bucket := floori(car.race_distance_m / GAP_BUCKET_M)
		if bucket < 0 or bucket == car.gap_bucket:
			continue
		car.gap_bucket = bucket
		while _gap_marks.size() <= bucket:
			_gap_marks.append(time_s)
		car.gap_to_leader_s = time_s - _gap_marks[bucket]
