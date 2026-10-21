## Game time (autoload "Calendar"). Time advances in whole days;
## other systems react to the EventBus signals.
extends Node

const DAYS_PER_SEASON := 364
const START_YEAR := 2026

var year: int = START_YEAR
## Day within the current season (0..DAYS_PER_SEASON-1).
var day: int = 0


func advance_day() -> void:
	day += 1
	EventBus.day_passed.emit(day)
	if day % 7 == 0:
		EventBus.week_passed.emit(day / 7)
	if day >= DAYS_PER_SEASON:
		EventBus.season_ended.emit(year)
		year += 1
		day = 0
		EventBus.season_started.emit(year)


func reset() -> void:
	year = START_YEAR
	day = 0
