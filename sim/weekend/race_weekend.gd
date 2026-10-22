## Runs a full race weekend of the player's series inside the season:
## practice, weekend form, qualifying and the race, then stores a detailed
## summary (GameState.race_results) and updates the standings.
## The weekend screens (decisions, 1-on-1, key moments) plug in here later;
## until then every decision is left to the staff.
class_name RaceWeekend
extends RefCounted

## Practice programmes per driver slot (0 = first driver of the team).
const DEFAULT_PROGRAMMES := [0, 1]


static func run_round(series: SeriesData, round_index: int, seed_value: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var track: TrackData = GameState.tracks[series.calendar[round_index]]
	var model := TrackModel.build(track)
	var conditions := RaceConditions.for_track(model, rng)
	var cars := WeekendSetup.cars_for_series(series.id)

	# Practice: one driver works on the setup, the other does long runs.
	var practice_wet := 0.0 if rng.randf() > conditions.rain_chance * 0.5 else rng.randf_range(0.3, 0.9)
	var slot := {}
	for car in cars:
		var index: int = slot.get(car.team.id, 0)
		slot[car.team.id] = index + 1
		WeekendSetup.practice(car, DEFAULT_PROGRAMMES[mini(index, DEFAULT_PROGRAMMES.size() - 1)], practice_wet, rng)
	for car in cars:
		for other in cars:
			if other.team == car.team:
				car.tyre_data = maxf(car.tyre_data, other.tyre_data)
	WeekendSetup.roll_weekend(cars, model, rng)

	var quali := QualifyingSim.new(model, conditions, rng)
	var grid := quali.run(cars)
	var engine := RaceEngine.new(model, conditions, grid, rng.randi())
	engine.run()

	var summary := summarize(engine, quali, round_index, track)
	_apply(series, round_index, engine)
	summary.points = {}
	for entry in summary.entries:
		summary.points[entry.driver_id] = entry.points
	GameState.race_results.append(summary)
	return summary


static func _apply(series: SeriesData, round_index: int, engine: RaceEngine) -> void:
	var grid: Array = []
	var by_grid := engine.cars.duplicate()
	by_grid.sort_custom(func(a: SimCar, b: SimCar): return a.grid_position < b.grid_position)
	for car in by_grid:
		grid.append(car.driver.id)
	var classified: Array = []
	var retired: Array = []
	for car in engine.classification():
		(retired if car.retired else classified).append(car.driver.id)
	SeasonRecords.apply_round(series, round_index, grid, classified, retired)


## Everything the result screens need, as plain data (no runtime objects).
static func summarize(engine: RaceEngine, quali: QualifyingSim, round_index: int, track: TrackData) -> Dictionary:
	var order := engine.classification()
	var winner := order[0]
	var series: SeriesData = GameState.series[GameState.teams[winner.team.id].series_id]
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
		var q: Dictionary = quali.results.get(car, {})
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
			"points": 0 if car.retired else SeasonRecords.points_for(series, finish_position),
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
			"quali": {"Q1": q.get("Q1", INF), "Q2": q.get("Q2", INF), "Q3": q.get("Q3", INF), "out": q.get("out", "")},
		})
	return {
		"round": round_index + 1,
		"track_id": track.id,
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
static func entry_of(summary: Dictionary, driver_id: StringName) -> Dictionary:
	for e in summary.entries:
		if e.driver_id == driver_id:
			return e
	return {}
