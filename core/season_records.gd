## Season bookkeeping after a round: driver statistics, constructors'
## points and the teammate comparison. Used by the full race weekend and
## by QuickRace (background rounds).
class_name SeasonRecords
extends RefCounted


## grid: driver IDs in starting order. classified: finishers in order.
## retired: drivers who did not finish.
static func apply_round(series: SeriesData, round_index: int, grid: Array, classified: Array, retired: Array) -> void:
	var all_ids := classified + retired
	for id in all_ids:
		stats_of(id)
	var position := 1
	for id in all_ids:
		var stats: DriverSeasonStats = GameState.season_stats[id]
		var driver: DriverData = GameState.drivers[id]
		var result := {"round": round_index + 1, "track_id": series.calendar[round_index],
			"grid": grid.find(id) + 1, "finish": 0}
		if id in retired:
			stats.retirements += 1
		else:
			result.finish = position
			var pts := points_for(series, position)
			stats.points += pts
			GameState.team_points[driver.team_id] = GameState.team_points.get(driver.team_id, 0) + pts
			if position == 1:
				stats.wins += 1
			if position <= 3:
				stats.podiums += 1
			position += 1
		if result.grid == 1:
			stats.poles += 1
		stats.results.append(result)
		driver.races += 1
	_head_to_head(all_ids)


static func points_for(series: SeriesData, position: int) -> int:
	return series.points_table[position - 1] if position >= 1 and position <= series.points_table.size() else 0


## This season's statistics of a driver, created empty on first access.
static func stats_of(id: StringName) -> DriverSeasonStats:
	if not GameState.season_stats.has(id):
		var fresh := DriverSeasonStats.new()
		fresh.driver_id = id
		fresh.year = Calendar.year
		GameState.season_stats[id] = fresh
	return GameState.season_stats[id]


## Updates the teammate comparison with the newest round.
static func _head_to_head(ids: Array) -> void:
	for id in ids:
		var driver: DriverData = GameState.drivers[id]
		var mate := GameState.teammate_of(driver)
		if not mate or not GameState.season_stats.has(mate.id):
			continue
		var mine: DriverSeasonStats = GameState.season_stats[id]
		var theirs: DriverSeasonStats = GameState.season_stats[mate.id]
		if mine.results.is_empty() or theirs.results.is_empty():
			continue
		var a: Dictionary = mine.results.back()
		var b: Dictionary = theirs.results.back()
		if a.round != b.round:
			continue
		mine.head_to_head_rounds += 1
		if a.grid < b.grid:
			mine.quali_ahead += 1
		var a_pos: int = a.finish if a.finish > 0 else 99
		var b_pos: int = b.finish if b.finish > 0 else 99
		if a_pos < b_pos:
			mine.race_ahead += 1


## Constructors' standings: [[team_id, points], ...] best first.
static func team_standings(series: SeriesData) -> Array:
	var out := []
	for team_id in series.team_ids:
		out.append([team_id, GameState.team_points.get(team_id, 0)])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out


## Drivers' standings: [[driver_id, points], ...] best first (all drivers who raced).
static func driver_standings() -> Array:
	var out := []
	for id in GameState.season_stats:
		out.append([id, GameState.season_stats[id].points])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out
