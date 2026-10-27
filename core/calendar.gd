## Game time (autoload "Calendar"). Time advances in whole days;
## other systems react to the EventBus signals.
extends Node

const DAYS_PER_SEASON := 364
const START_YEAR := 2026
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const WEEKDAYS := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

var year: int = START_YEAR
## Day within the current season (0 = 1 January).
var day: int = 0


func advance_day() -> void:
	day += 1
	EventBus.day_passed.emit(day)
	if day % 7 == 0:
		EventBus.week_passed.emit(floori(day / 7.0))
	if day >= DAYS_PER_SEASON:
		EventBus.season_ended.emit(year)
		year += 1
		day = 0
		EventBus.season_started.emit(year)


func reset() -> void:
	year = START_YEAR
	day = 0


## Calendar date for a day of a season (default: today, this season).
func date_of(season_day: int = -1, in_year: int = -1) -> Dictionary:
	var d := day if season_day < 0 else season_day
	var start := Time.get_unix_time_from_datetime_dict({"year": year if in_year < 0 else in_year, "month": 1, "day": 1})
	return Time.get_datetime_dict_from_unix_time(start + d * 86400)


## "Sat 26 Jul 2026" (German: "Sa, 26. Jul 2026")
func format_date(season_day: int = -1, in_year: int = -1) -> String:
	var d := date_of(season_day, in_year)
	return tr("%s %d %s %d") % [tr(WEEKDAYS[d.weekday]), d.day, tr(MONTHS[d.month - 1]), d.year]
