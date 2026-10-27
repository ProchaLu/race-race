## The strategy chief (docs/simulation_model.md, section 5). Plans stops
## with an *estimated* tyre model – a weak strategist with little tyre data
## gets the wear wrong and picks worse plans. Used identically for AI teams.
class_name StrategyPlanner
extends RefCounted

const MAX_STOPS := 3

var model: TrackModel
var conditions: RaceConditions
var rng: RandomNumberGenerator


func _init(p_model: TrackModel, p_conditions: RaceConditions, p_rng: RandomNumberGenerator) -> void:
	model = p_model
	conditions = p_conditions
	rng = p_rng


## Rolls the strategist's estimate error per compound for this car.
func init_estimates(car: SimCar) -> void:
	var eng := car.ops.engineer(car.driver.id)
	var skill: float = (car.ops.tyre_model * 0.7 + (eng.tyre_knowledge + eng.data_analysis) * 0.15) / 100.0
	var sigma: float = SimTuning.ESTIMATE_SIGMA * (1.0 - skill) * (1.0 - SimTuning.TYRE_DATA_SIGMA_CUT * car.tyre_data)
	for id in SimTuning.COMPOUNDS:
		car.deg_estimate[id] = maxf(0.4, 1.0 + car.rng.randfn(0.0, sigma))


## Each lap on a compound the estimate moves towards the truth.
func learn(car: SimCar) -> void:
	var eng := car.ops.engineer(car.driver.id)
	var rate: float = 0.04 + 0.12 * eng.data_analysis / 100.0
	car.deg_estimate[car.compound] = lerpf(car.deg_estimate[car.compound], 1.0, rate)


# --- Plans -------------------------------------------------------------------

## Cumulative estimated tyre time for stints from new: cost[k] = laps 0..k-1.
func _stint_costs(car: SimCar, id: StringName, laps: int) -> PackedFloat32Array:
	var info := PaceModel.compound_info(id)
	var deg: float = info[1] * conditions.tyre_wear_factor * car.deg_estimate[id]
	var life: float = PaceModel.tyre_life(id, conditions) / car.deg_estimate[id]
	# Wear at the temperature the compound will run at in this race.
	var keep_compound := car.compound
	var keep_temp := car.tyre_temp
	car.compound = id
	car.tyre_temp = PaceModel.tyre_temp_target(car, id, conditions.track_temp_c, 0.2, false)
	var rate := PaceModel.wear_rate(car, 0.2, 0.0)
	var temp_s := SimTuning.TEMP_GRIP_S * maxf(0.0, absf(car.tyre_temp) - SimTuning.TEMP_FREE_ZONE) \
		/ (1.0 - SimTuning.TEMP_FREE_ZONE)
	car.compound = keep_compound
	car.tyre_temp = keep_temp
	var out := PackedFloat32Array()
	out.resize(laps + 2)
	var total := 0.0
	out[0] = 0.0
	for k in laps + 1:
		var age := k * rate
		var t: float = info[0] + temp_s + deg * age
		if age > life:
			t += SimTuning.CLIFF_S_PER_LAP * pow(age - life, SimTuning.CLIFF_EXPONENT)
		if k == 0:
			t += info[3]
		total += t * model.scale
		out[k + 1] = total
	return out


## Seconds lost per stop: pit lane + stationary + lost track position.
func stop_cost(car: SimCar) -> float:
	var stationary := SimTuning.curve(SimTuning.STOP_CURVE, car.ops.stop_speed)
	var overtaking := 0.0
	for s in model.sectors:
		overtaking += s.overtake_chance
	var difficulty := 1.0 - clampf(overtaking / 2.5, 0.0, 1.0)
	return model.pit_lane_loss_s + stationary + SimTuning.TRACK_POSITION_S_PER_STOP * difficulty


## Best dry plans for the rest of the race.
## from_lap: laps already done; the current stint uses car.compound with
## car.tyre_laps already driven (at race start: tyre_laps = 0, compound free).
## Returns plans sorted by estimated time: {"stops": [[lap, id]], "time": s, "first": id}
func plans(car: SimCar, from_lap: int, choose_start: bool, count: int = 3) -> Array:
	var laps_left := conditions.laps - from_lap
	var costs := {}
	for id in SimTuning.DRY_COMPOUNDS:
		costs[id] = _stint_costs(car, id, conditions.laps)
	var stop := stop_cost(car)
	var firsts: Array[StringName] = [car.compound]
	if choose_start:
		firsts = SimTuning.DRY_COMPOUNDS
	var age := 0 if choose_start else car.tyre_laps
	var used: Dictionary = car.used_dry_compounds.duplicate()
	var results: Array = []

	for first in firsts:
		var first_cost: PackedFloat32Array = costs[first]
		# No stop (only if the two-compound rule is already met).
		var has_two := used.size() >= 2 or (used.size() == 1 and not used.has(first))
		if has_two and age + laps_left < first_cost.size() - 1:
			results.append({"stops": [], "time": first_cost[age + laps_left] - first_cost[age], "first": first})
		for n_stops in range(1, MAX_STOPS + 1):
			var best := _best_split(first, age, laps_left, n_stops, costs, used, stop)
			if not best.is_empty():
				best.first = first
				results.append(best)
	results.sort_custom(func(a, b): return a.time < b.time)
	# Keep distinct shapes (number of stops + compounds) for the player's choice.
	var out: Array = []
	var seen := {}
	for r in results:
		var key := "%d|%s" % [r.stops.size(), ",".join(r.stops.map(func(s): return s[1]))]
		if seen.has(key):
			continue
		seen[key] = true
		for s in r.stops:
			s[0] += from_lap
		out.append(r)
		if out.size() >= count:
			break
	return out


func _best_split(first: StringName, age: int, laps_left: int, n_stops: int, costs: Dictionary,
		used: Dictionary, stop: float) -> Dictionary:
	var best := {}
	var best_time := INF
	for seq in _sequences(n_stops):
		var all_used := used.duplicate()
		all_used[first] = true
		for id in seq:
			all_used[id] = true
		if all_used.size() < 2:
			continue
		var found := _search(first, age, laps_left, seq, costs)
		if found.time + stop * n_stops < best_time:
			best_time = found.time + stop * n_stops
			best = {"stops": found.stops, "time": best_time}
	return best


## Compound sets for the stints after the first. Order does not change the
## estimated time, so combinations are enough (hardest last looks natural).
func _sequences(n: int) -> Array:
	var out: Array = []
	_combine(n, 0, [], out)
	return out


func _combine(n: int, start: int, current: Array, out: Array) -> void:
	if current.size() == n:
		out.append(current.duplicate())
		return
	for i in range(start, SimTuning.DRY_COMPOUNDS.size()):
		current.append(SimTuning.DRY_COMPOUNDS[i])
		_combine(n, i, current, out)
		current.pop_back()


## Local search over the stop laps (relative to now). Stint costs are
## convex, so moving one stop at a time while it helps finds the optimum.
func _search(first: StringName, age: int, laps_left: int, seq: Array, costs: Dictionary) -> Dictionary:
	var n := seq.size()
	# Start from a split proportional to the compound lives.
	var lives: Array[float] = [maxf(1.0, PaceModel.tyre_life(first, conditions) - age)]
	for id in seq:
		lives.append(PaceModel.tyre_life(id, conditions))
	var total_life := 0.0
	for l in lives:
		total_life += l
	var laps: Array = []
	var acc := 0.0
	for i in n:
		acc += lives[i]
		laps.append(clampi(roundi(acc / total_life * laps_left), i + 1, laps_left - (n - i)))
	var best_time := _evaluate(first, age, laps_left, seq, costs, laps)
	var improved := true
	var guard := 0
	while improved and guard < 200:
		improved = false
		guard += 1
		for i in n:
			for d: int in [-1, 1]:
				var trial: Array = laps.duplicate()
				trial[i] += d
				var t := _evaluate(first, age, laps_left, seq, costs, trial)
				if t < best_time:
					best_time = t
					laps = trial
					improved = true
	return {"time": best_time, "stops": _as_stops(laps, seq)}


func _evaluate(first: StringName, age: int, laps_left: int, seq: Array, costs: Dictionary, laps: Array) -> float:
	var prev := 0
	var total := 0.0
	for i in laps.size() + 1:
		var end: int = laps[i] if i < laps.size() else laps_left
		if end <= prev or end > laps_left:
			return INF
		var id: StringName = first if i == 0 else seq[i - 1]
		var c: PackedFloat32Array = costs[id]
		var start_age := age if i == 0 else 0
		var length := end - prev
		if start_age + length >= c.size():
			return INF
		total += c[start_age + length] - c[start_age]
		prev = end
	return total


func _as_stops(laps: Array, seq: Array) -> Array:
	var out: Array = []
	for i in laps.size():
		out.append([laps[i], seq[i]])
	return out


## Fuel for the start: full distance plus a margin; a brave strategist
## underfuels a little and relies on lift and coast later.
func start_fuel(car: SimCar) -> float:
	var need := PaceModel.car_fuel_per_lap(car, model) * conditions.laps
	# Only worth it with a driver who saves fuel cheaply.
	var underfuel := (car.ops.race_reading - 40) / 60.0 * (car.driver.fuel_management - 40) / 60.0 * 3.0
	return need * 1.01 - clampf(underfuel, 0.0, 2.5)


# --- Decisions in the race -----------------------------------------------------

## Compound the strategist would fit for the expected wetness.
## A good weather reader looks up to three laps ahead and calls the stop
## before the conditions change; a weak one only reacts to what the track
## is doing now and needs a lap or two longer to make up their mind.
func weather_call(car: SimCar, now_s: float, laps_left: int) -> StringName:
	var accuracy := (car.ops.weather_reading * 0.8 + car.ops.calm_decisions * 0.2) / 100.0
	var ahead := model.reference_lap_s * lerpf(0.5, 3.0, accuracy)
	var expected := conditions.weather.forecast_wetness(now_s, ahead, accuracy, hash(car.team.id))
	var dry_choice := _dry_compound_for(laps_left)
	var ideal := PaceModel.ideal_compound_for(expected, dry_choice)
	var change := not (ideal == car.compound \
		or (not PaceModel.is_wet_compound(ideal) and not PaceModel.is_wet_compound(car.compound)))
	if change:
		# Only change if the gain over the next laps beats the stop.
		var gain := PaceModel.wet_tyre_penalty(car.compound, expected) - PaceModel.wet_tyre_penalty(ideal, expected)
		change = gain * model.scale * mini(laps_left, 12) > model.pit_lane_loss_s * 0.8
	if not change:
		car.set_meta("weather_doubt", 0)
		return &""
	# Hesitation: the call has to hold for a few laps with a weak reader.
	var laps_needed := 1 if accuracy > 0.7 else (2 if accuracy > 0.4 else 3)
	var doubt: int = car.get_meta("weather_doubt", 0) + 1
	car.set_meta("weather_doubt", doubt)
	if doubt < laps_needed:
		return &""
	car.set_meta("weather_doubt", 0)
	return ideal


func _dry_compound_for(laps_left: int) -> StringName:
	for id: StringName in [&"soft", &"medium", &"hard"]:
		if PaceModel.tyre_life(id, conditions) * 1.1 >= laps_left:
			return id
	return &"hard"


## Should the car stop under the safety car? Good race readers spot it.
func safety_car_call(car: SimCar, laps_left: int, is_vsc: bool) -> bool:
	if laps_left < 4:
		return false
	var life := PaceModel.tyre_life(car.compound, conditions)
	var used_share := car.tyre_wear_laps / life
	if used_share < 0.15:
		return false  # just stopped
	var planned_soon: bool = not car.plan.is_empty() and car.plan[0][0] - car.laps_done <= (7 if not is_vsc else 5)
	# A fresh set must reach the end, or a later stop must still be planned anyway.
	var reaches_end := PaceModel.tyre_life(&"hard", conditions) * 1.15 >= laps_left
	var worth: bool = (planned_soon or used_share > 0.55) and (reaches_end or car.plan.size() > 1)
	var reading := (car.ops.race_reading * 0.7 + car.ops.calm_decisions * 0.3) / 100.0
	# Good race readers take every chance; weak ones miss some and
	# now and then stop when it does not pay off.
	if worth:
		return car.rng.randf() < 0.45 + 0.55 * reading
	return car.rng.randf() < 0.12 * (1.0 - reading)


## Undercut: stuck behind a slower car with the stop window open.
func undercut_call(car: SimCar) -> bool:
	if car.plan.is_empty() or car.laps_stuck < 3:
		return false
	var to_stop: int = car.plan[0][0] - car.laps_done
	if to_stop > 5 or to_stop <= 0:
		return false
	return car.rng.randf() < car.ops.race_reading / 100.0 * 0.5


## Cover: the car behind just stopped. Answer next lap only if its fresh
## tyres would really make up the gap – a good race reader judges that
## well, a weak one reacts to the wrong threats and misses real ones.
func cover_call(car: SimCar, gap_s: float) -> bool:
	if is_inf(gap_s) or car.plan.is_empty():
		return false
	var to_stop: int = car.plan[0][0] - car.laps_done
	if to_stop > 7 or to_stop <= 0:
		return false
	var next: StringName = car.plan[0][1]
	var now := PaceModel.compound_info(car.compound)
	var fresh := PaceModel.compound_info(next)
	# Estimated time per lap the old tyres lose against a fresh set.
	var deficit: float = now[0] + now[1] * conditions.tyre_wear_factor * car.deg_estimate[car.compound] \
		* car.tyre_wear_laps - fresh[0]
	var gain: float = (2.0 * deficit - fresh[3]) * model.scale
	var reading := (car.ops.race_reading * 0.7 + car.ops.calm_decisions * 0.3) / 100.0
	gain += car.rng.randfn(0.0, 1.0 * (1.0 - reading))
	return gain > gap_s and car.rng.randf() < 0.3 + 0.7 * reading


## Clean air: if the car would rejoin behind a slower car, a good race
## reader keeps it out a lap longer (twice at most, while the tyres last).
func clean_air_delay(car: SimCar, in_traffic: bool) -> bool:
	if not in_traffic:
		return false
	var delays: int = car.get_meta("stop_delays", 0)
	if delays >= 2 or car.tyre_wear_laps > PaceModel.tyre_life(car.compound, conditions) - 1.0:
		return false
	var reading := (car.ops.race_reading * 0.7 + car.ops.calm_decisions * 0.3) / 100.0
	if car.rng.randf() > reading * reading:
		return false  # weak readers do not see it coming
	car.set_meta("stop_delays", delays + 1)
	return true


## Re-plans the remaining race after a stop.
func replan_after_stop(car: SimCar) -> void:
	car.set_meta("stop_delays", 0)
	# On wet tyres the weather calls decide the next stop.
	if PaceModel.is_wet_compound(car.compound):
		car.plan = []
		return
	var options := plans(car, car.laps_done, false, 1)
	car.plan = options[0].stops if not options.is_empty() else []


## Best dry compound for an unplanned stop right now.
func compound_for_stop_now(car: SimCar) -> StringName:
	var keep_compound := car.compound
	var keep_laps := car.tyre_laps
	var keep_wear := car.tyre_wear_laps
	var best: StringName = &"hard"
	var best_time := INF
	for id in SimTuning.DRY_COMPOUNDS:
		car.compound = id
		car.tyre_laps = 0
		car.tyre_wear_laps = 0.0
		var added := not car.used_dry_compounds.has(id)
		car.used_dry_compounds[id] = true
		var options := plans(car, car.laps_done, false, 1)
		if added:
			car.used_dry_compounds.erase(id)
		if not options.is_empty() and options[0].time < best_time:
			best_time = options[0].time
			best = id
	car.compound = keep_compound
	car.tyre_laps = keep_laps
	car.tyre_wear_laps = keep_wear
	return best
