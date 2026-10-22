## Fast stand-in race result: ranks drivers by car and driver strength plus
## randomness. Only used to fill the rounds already raced when a new game
## starts; the season itself runs full race weekends (RaceWeekend).
class_name QuickRace
extends RefCounted

const RETIRE_CHANCE := 0.06


## Resolves one round of a series and updates all season statistics.
## Returns the finishing order (driver IDs, retired drivers last).
static func resolve_round(series: SeriesData, round_index: int) -> Array:
	# Only drivers in a race seat of a team in this series take part.
	var ids: Array = []
	for team_id in series.team_ids:
		for driver in GameState.drivers_of_team(team_id):
			ids.append(driver.id)

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

	var finishers: Array = []
	var dnfs: Array = []
	for id in order:
		(dnfs if randf() < RETIRE_CHANCE else finishers).append(id)
	SeasonRecords.apply_round(series, round_index, grid, finishers, dnfs)
	return finishers + dnfs


static func _strength(d: DriverData) -> float:
	var c: CarData = GameState.teams[d.team_id].car
	return (c.downforce + c.engine_power + c.drag_efficiency + c.mechanical_grip) / 4.0 + d.overall() * 0.5
