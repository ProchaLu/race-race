## Global signal hub (autoload "EventBus").
## Systems emit and listen here instead of referencing each other directly.
extends Node

# Signals are emitted by other scripts, so "unused" warnings don't apply here.
@warning_ignore_start("unused_signal")

# Time
signal day_passed(day: int)
signal week_passed(week: int)
signal season_started(year: int)
signal season_ended(year: int)

# Navigation
signal race_requested(track_id: StringName)
signal hq_requested()

# Race weekend
signal race_weekend_started(track_id: StringName)
signal race_finished(track_id: StringName, results: Array)
signal round_completed(round_index: int)

# Inbox
signal inbox_message_added(message: InboxMessage)
signal inbox_changed()

# Management
signal budget_changed(team_id: StringName, new_budget: int)
## A team started, advanced or finished construction at its HQ.
signal facilities_changed(team_id: StringName)
signal contract_expiring(contract: ContractData)
signal contract_signed(person_id: StringName, team_id: StringName)
signal contract_released(person_id: StringName)
signal driver_scouted(driver_id: StringName)
