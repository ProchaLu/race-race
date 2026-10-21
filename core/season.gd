## Drives the passing of time (autoload "Season"): advancing single days,
## "Continue" to the next important event, and race days.
extends Node

## Safety limit for one press of Continue.
const MAX_DAYS_PER_CONTINUE := 60

var _important_posted := false


func _ready() -> void:
	EventBus.inbox_message_added.connect(func(msg: InboxMessage):
		if msg.priority == InboxMessage.Priority.IMPORTANT:
			_important_posted = true)


## Passive step: exactly one day (or the race, if today is race day).
func advance_one_day() -> void:
	_step()


## Active step: keeps advancing until something needs the player.
func continue_to_next_event() -> void:
	for i in MAX_DAYS_PER_CONTINUE:
		if _step():
			return


## One step of time. Returns true if something important happened.
func _step() -> bool:
	_important_posted = false
	var today := round_today()
	if today >= 0:
		_run_race(today)
	else:
		Calendar.advance_day()
		var new_round := round_today()
		if new_round >= 0:
			_announce_race(new_round)
	return _important_posted


## Index of the round raced today that is not resolved yet, or -1.
func round_today() -> int:
	var s := _player_series()
	var next := GameState.resolved_rounds
	if next < s.race_days.size() and s.race_days[next] == Calendar.day:
		return next
	return -1


func _announce_race(round_index: int) -> void:
	var s := _player_series()
	var track: TrackData = GameState.tracks[s.calendar[round_index]]
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Race weekend: %s"
	msg.subject_args = [track.name]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "trophy"
	msg.add_paragraph("The team has arrived for round %d of %d.", [round_index + 1, s.calendar.size()])
	msg.add_paragraph("Press Continue to run the race.")
	GameState.add_message(msg)


func _run_race(round_index: int) -> void:
	var s := _player_series()
	var order := QuickRace.resolve_round(s, round_index)
	GameState.resolved_rounds += 1
	EventBus.round_completed.emit(round_index)

	var track: TrackData = GameState.tracks[s.calendar[round_index]]
	var msg := InboxMessage.new()
	msg.sender = "Race engineering"
	msg.subject = "Race result: %s"
	msg.subject_args = [track.name]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "trophy"
	var winner: DriverData = GameState.drivers[order[0]]
	msg.add_paragraph("%s won the race.", [winner.full_name()])
	var first_own: StringName = &""
	for driver in GameState.drivers_of_team(GameState.player_team_id):
		var result: Dictionary = GameState.season_stats[driver.id].results.back()
		if result.finish > 0:
			msg.add_paragraph("%s finished P%d.", [driver.full_name(), result.finish])
		else:
			msg.add_paragraph("%s retired.", [driver.full_name()])
		if first_own == &"":
			first_own = driver.id
	msg.link_screen = &"driver_profile"
	msg.link_args = {"driver_id": first_own}
	msg.link_label = "Open driver profile"
	GameState.add_message(msg)


func _player_series() -> SeriesData:
	return GameState.series[GameState.player_team().series_id]
