## Fast stand-in race result: ranks drivers by car and driver strength plus
## randomness. Used for background rounds until the full race weekend
## (qualifying + RaceSim) is part of the season loop (roadmap R2).
class_name QuickRace
extends RefCounted

const RETIRE_CHANCE := 0.06


## Resolves one round of a series and updates all season statistics.
## Returns the finishing order (driver IDs, retired drivers last).
static func resolve_round(series: SeriesData, round_index: int) -> Array:
	var ids: Array = []
	for driver in GameState.drivers.values():
		if driver.series_id == series.id:
			ids.append(driver.id)
			if not GameState.season_stats.has(driver.id):
				var fresh := DriverSeasonStats.new()
				fresh.driver_id = driver.id
				fresh.year = Calendar.year
				GameState.season_stats[driver.id] = fresh

	var quali := {}
	var race := {}
	for id in ids:
		var strength := _strength(GameState.drivers[id])
		quali[id] = strength + randf_range(-5.0, 5.0)
		race[id] = strength + randf_range(-7.0, 7.0)
	var grid := ids.duplicate()
	grid.sort_custom(func(a, b): return quali[a] > quali[b])
	var order := ids.duplicate()
	order.sort_custom(func(a, b): return race[a] > race[b])
	var retired := {}
	for id in ids:
		if randf() < RETIRE_CHANCE:
			retired[id] = true

	var finishers: Array = []
	var dnfs: Array = []
	for id in order:
		(dnfs if retired.has(id) else finishers).append(id)

	var position := 1
	for id in finishers + dnfs:
		var stats: DriverSeasonStats = GameState.season_stats[id]
		var result := {"round": round_index + 1, "track_id": series.calendar[round_index],
			"grid": grid.find(id) + 1, "finish": 0}
		if retired.has(id):
			stats.retirements += 1
		else:
			result.finish = position
			if position <= series.points_table.size():
				stats.points += series.points_table[position - 1]
			if position == 1:
				stats.wins += 1
			if position <= 3:
				stats.podiums += 1
			position += 1
		if result.grid == 1:
			stats.poles += 1
		stats.results.append(result)
		GameState.drivers[id].races += 1

	_head_to_head(ids)
	return finishers + dnfs


## Updates the teammate comparison with the newest round.
static func _head_to_head(ids: Array) -> void:
	for id in ids:
		var driver: DriverData = GameState.drivers[id]
		var mate := GameState.teammate_of(driver)
		if not mate:
			continue
		var mine: DriverSeasonStats = GameState.season_stats[id]
		var a: Dictionary = mine.results.back()
		var b: Dictionary = GameState.season_stats[mate.id].results.back()
		mine.head_to_head_rounds += 1
		if a.grid < b.grid:
			mine.quali_ahead += 1
		var a_pos: int = a.finish if a.finish > 0 else 99
		var b_pos: int = b.finish if b.finish > 0 else 99
		if a_pos < b_pos:
			mine.race_ahead += 1


static func _strength(d: DriverData) -> float:
	var c: CarData = GameState.teams[d.team_id].car
	return (c.downforce + c.engine_power + c.drag_efficiency + c.mechanical_grip) / 4.0 + d.overall() * 0.5
