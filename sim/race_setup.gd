## Helpers to turn the game world into race entries.
class_name RaceSetup
extends RefCounted


## Creates one entry per driver of a series. The grid is ordered by a rough
## pace estimate plus randomness (stand-in until qualifying exists).
static func entries_for_series(series_id: StringName, start_tyres: Array[TyreCompound],
		rng: RandomNumberGenerator) -> Array[RaceCarState]:
	var entries: Array[RaceCarState] = []
	var series: SeriesData = GameState.series[series_id]
	for team_id in series.team_ids:
		var team: TeamData = GameState.teams[team_id]
		for driver in GameState.drivers_of_team(team_id):
			var tyre := start_tyres[rng.randi() % start_tyres.size()]
			var entry := RaceCarState.new(driver, team, tyre)
			entry.is_player = team_id == GameState.player_team_id
			entries.append(entry)

	var score := {}
	for entry in entries:
		score[entry] = _pace_estimate(entry) + rng.randf_range(-4.0, 4.0)
	entries.sort_custom(func(a, b): return score[a] > score[b])
	return entries


static func _pace_estimate(entry: RaceCarState) -> float:
	var c := entry.car_data
	return (c.downforce + c.engine_power + c.drag_efficiency + c.mechanical_grip) / 4.0 \
		+ entry.driver.overall() * 0.5
