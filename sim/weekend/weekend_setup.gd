## Builds weekend simulation cars from the game world.
class_name WeekendSetup
extends RefCounted


## One car per race-seat driver of the series, with the team's staff values.
static func cars_for_series(series_id: StringName) -> Array[SimCar]:
	var out: Array[SimCar] = []
	var series: SeriesData = GameState.series[series_id]
	for team_id in series.team_ids:
		var team: TeamData = GameState.teams[team_id]
		var ops := TeamOps.from_team(team_id)
		for driver in GameState.drivers_of_team(team_id):
			var car := SimCar.new(driver, team, ops)
			car.is_player = team_id == GameState.player_team_id
			out.append(car)
	return out


## Rolls the weekend form: one value per team (car suits the conditions or
## not) plus one per driver (day form, steadier for consistent drivers).
static func roll_weekend(cars: Array[SimCar], model: TrackModel, rng: RandomNumberGenerator) -> void:
	var team_fit := {}
	for car in cars:
		if not team_fit.has(car.team.id):
			team_fit[car.team.id] = rng.randfn(0.0, SimTuning.WEEKEND_CAR_SIGMA_S)
		var d := car.driver
		var sigma := lerpf(SimTuning.WEEKEND_DRIVER_SIGMA_MAX_S, SimTuning.WEEKEND_DRIVER_SIGMA_MIN_S, d.consistency / 100.0)
		var form := -(d.form - 50) / 50.0 * SimTuning.FORM_ATTRIBUTE_S
		car.weekend_s = (team_fit[car.team.id] + rng.randfn(0.0, sigma) + form) * model.scale


## Setup quality and tyre data from practice (docs/simulation_model.md, 10.3).
## programme: 0 = setup work, 1 = long runs, 2 = academy driver in FP1.
static func practice(car: SimCar, programme: int, practice_wetness: float, rng: RandomNumberGenerator) -> void:
	var eng := car.ops.engineer(car.driver.id)
	var setup: float = 38.0 + eng.setup_work * 0.25 + car.driver.technical_feedback * 0.15 + eng.chemistry * 0.08
	setup += [16.0, 8.0, 4.0][programme]
	# Rookies give less useful feedback on a new track.
	if car.driver.races < SimTuning.ROOKIE_RACES:
		setup -= 6.0 * (1.0 - car.driver.adaptability / 100.0)
	setup *= 1.0 - 0.3 * practice_wetness
	car.setup_pct = clampf(setup + rng.randfn(0.0, 4.0), 0.0, 100.0)
	car.tyre_data = clampf([0.3, 0.85, 0.2][programme] * (0.6 + 0.4 * eng.tyre_knowledge / 100.0) \
		* (1.0 - 0.6 * practice_wetness), 0.0, 1.0)
