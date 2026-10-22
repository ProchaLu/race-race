## Knockout qualifying Q1/Q2/Q3 (docs/simulation_model.md, 10.2). Uses the
## same pace model as the race, plus low fuel, new tyres, track evolution,
## traffic, mistakes on the flying lap and pressure on the last run.
class_name QualifyingSim
extends RefCounted

## [name, minute of run 1, minute of run 2, session end]
const SESSIONS := [["Q1", 4.0, 14.0, 18.0], ["Q2", 26.0, 36.0, 40.0], ["Q3", 48.0, 57.0, 60.0]]

var model: TrackModel
var conditions: RaceConditions
var rng: RandomNumberGenerator
var weather: WeatherTimeline
## car -> {"Q1": best, "Q2": best, "Q3": best, "out": "Q1"/"Q2"/"", "note": text}
var results := {}
var events: Array = []


func _init(p_model: TrackModel, p_conditions: RaceConditions, p_rng: RandomNumberGenerator) -> void:
	model = p_model
	conditions = p_conditions
	rng = p_rng
	weather = WeatherTimeline.generate(70, conditions.rain_chance, conditions.track_temp_c, rng)


## Returns the grid order.
func run(cars: Array[SimCar]) -> Array[SimCar]:
	var n := cars.size()
	var out_q1 := maxi(0, (n - 10) / 2)
	var out_q2 := maxi(0, n - 10 - out_q1)
	var alive: Array[SimCar] = cars.duplicate()
	var eliminated: Array[SimCar] = []
	for car in cars:
		results[car] = {"out": ""}
		car.sector_frac = PaceModel.car_sector_fracs(car, model)

	for si in SESSIONS.size():
		var session: Array = SESSIONS[si]
		var name: String = session[0]
		for car in alive:
			var best := INF
			for run_index in 2:
				var minute: float = session[1 + run_index]
				var last_run := run_index == 1
				best = minf(best, _lap(car, minute, last_run, si))
			results[car][name] = best
		alive.sort_custom(func(a: SimCar, b: SimCar): return results[a][name] < results[b][name])
		var drop := out_q1 if si == 0 else (out_q2 if si == 1 else 0)
		var dropped: Array[SimCar] = alive.slice(alive.size() - drop)
		for car in dropped:
			results[car].out = name
		dropped.reverse()
		eliminated = dropped + eliminated
		alive = alive.slice(0, alive.size() - drop)

	var grid: Array[SimCar] = alive + eliminated
	for i in grid.size():
		grid[i].grid_position = i + 1
	return grid


## One flying lap. Returns INF if the lap was deleted or ruined.
func _lap(car: SimCar, minute: float, last_run: bool, session_index: int) -> float:
	var t_s := minute * 60.0
	var wet := weather.wetness_at(t_s)
	var compound := PaceModel.ideal_compound_for(wet, &"soft")
	var keep := [car.compound, car.tyre_wear_laps, car.tyre_laps, car.tyre_temp, car.fuel_kg]
	car.compound = compound
	car.tyre_wear_laps = 0.0
	car.tyre_laps = 1  # warm-up lap done
	car.tyre_temp = 0.0
	car.fuel_kg = SimTuning.QUALI_FUEL_KG

	var t := model.reference_lap_s + PaceModel.car_lap_s(car, model)
	t += PaceModel.driver_pace_s(car, model, true)
	t += PaceModel.confidence_s(car, model)
	t += car.weekend_s
	t += PaceModel.rookie_s(car, model)
	t += PaceModel.setup_s(car, model)
	t += PaceModel.tyre_s(car, model, conditions, wet)
	t += PaceModel.fuel_s(car, model)
	t += PaceModel.weather_s(car, model, wet)
	# The track gets faster through the session.
	t -= SimTuning.QUALI_EVOLUTION_S * model.scale * (minute / 60.0)
	t += rng.randfn(0.0, PaceModel.form_sigma_s(car, model) * 0.6)

	car.compound = keep[0]
	car.tyre_wear_laps = keep[1]
	car.tyre_laps = keep[2]
	car.tyre_temp = keep[3]
	car.fuel_kg = keep[4]

	# Traffic: a good strategist finds a clear gap.
	if rng.randf() < SimTuning.QUALI_TRAFFIC_CHANCE * (1.5 - car.ops.race_reading / 100.0):
		t += rng.randf_range(0.2, 0.6) * model.scale
	# Mistakes: pressure on the last run, more in the wet.
	var composure := PaceModel.composure_value(car)
	var chance := SimTuning.QUALI_MISTAKE_CHANCE * lerpf(2.0, 0.5, car.driver.consistency / 100.0) \
		* (1.0 + 2.0 * wet) * (1.0 + (0.6 * (1.0 - composure / 100.0) if last_run else 0.0)) \
		* (1.0 + 0.15 * session_index)
	if rng.randf() < chance:
		if rng.randf() < 0.35:
			if car.is_player:
				events.append("%s: lap deleted (track limits)" % car.label())
			return INF
		t += rng.randf_range(0.3, 1.5) * model.scale
	return t
