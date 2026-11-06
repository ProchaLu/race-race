## Checks the team principal's career (docs/career_model.md): dismissal rule,
## job offers, time waiting for a dismissed principal, the move to a new team,
## offers without a dismissal, and a full season through the real finale.
## godot --headless --path . res://tools/career_check.tscn
extends Node

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		print("FAILED: " + what)


func _run() -> void:
	var state = get_tree().root.get_node("GameState")
	var season = get_tree().root.get_node("Season")
	load("res://core/test_world.gd").build()
	var r := RandomNumberGenerator.new()
	r.seed = 8
	var start: TeamData = state.player_team()
	var series: SeriesData = state.series[start.series_id]
	_check(Career.reputation() == Career.START_REPUTATION, "start reputation")
	_check(state.career.history.size() == 1 and state.career.history[0].team_id == start.id, "history starts with the first team")

	# Dismissal rule: lenient – after a final warning or a massive failure only.
	_check(not Owners.should_dismiss(false, 5, 3), "no dismissal without a warning")
	_check(Owners.should_dismiss(true, 5, 1), "warned, low trust, missed again: dismissed")
	_check(not Owners.should_dismiss(true, 5, 0), "warned but goal met: stays")
	_check(not Owners.should_dismiss(true, 20, 2), "warned but trust recovered: stays")
	_check(Owners.should_dismiss(false, 20, Owners.MASSIVE_MISS), "massive failure with low trust: dismissed")
	_check(not Owners.should_dismiss(false, 60, Owners.MASSIVE_MISS), "massive failure with high trust: stays")

	# The verdict sets the warning and dismisses after the second bad season.
	start.owner.goal = 3
	start.owner.trust = 14
	start.owner.final_warning = false
	var v := Owners.season_end(start, _table(series, start.id, 6), 0)
	_check(not v.dismissed and start.owner.final_warning, "first bad season: final warning, got trust %d" % start.owner.trust)
	v = Owners.season_end(start, _table(series, start.id, 6), 0)
	_check(v.dismissed, "second bad season after the warning: dismissed")

	# Dismissal: reputation drops, offers come, time waits.
	var rep_before := Career.reputation()
	var table := _table(series, start.id, 11)
	var made := Career.season_end(table, true, r)
	_check(Career.reputation() == rep_before - Career.DISMISSAL_PENALTY, "dismissal costs reputation")
	_check(not made.is_empty() and made.size() <= Career.MAX_OFFERS, "1–3 offers after a dismissal, got %d" % made.size())
	for offer in made:
		_check(offer.team_id != start.id, "no offer from the old team")
		var team: TeamData = state.teams[offer.team_id]
		_check(offer.goal >= 1 and offer.goal <= series.team_ids.size(), "offer goal in range")
		_check(Owners.PERSONALITIES.has(offer.personality), "offer personality known")
		if made.size() > 1 or Career.reputation() >= Career.required_reputation(team):
			_check(Career.reputation() >= Career.required_reputation(team), "team accepts the reputation")
	_check(Career.job_pending(), "dismissed principal must choose")
	var day: int = Calendar.day
	season.advance_one_day()
	season.continue_to_next_event()
	_check(Calendar.day == day, "time stands still while dismissed")
	while Career.offers().size() > 1:
		Career.decline(Career.offers().back())
	Career.decline(Career.offers()[0])
	_check(Career.offers().size() == 1, "the last offer cannot be declined")

	# Taking the job: new team, new owner, the old team is AI.
	state.negotiations[&"x"] = null
	state.scout_assignments.append({"id": 1})
	var offer: Dictionary = Career.offers()[0]
	Career.accept(offer)
	var now: TeamData = state.player_team()
	_check(now.id == offer.team_id, "player runs the new team")
	_check(not Owners.has_owner(start), "old team has no owner")
	_check(Owners.has_owner(now) and now.owner.name == offer.owner_name and now.owner.trust == Owners.START_TRUST, "new owner set up")
	_check(not Career.job_pending() and Career.offers().is_empty(), "no longer dismissed")
	_check(state.negotiations.is_empty() and state.scout_assignments.is_empty(), "old team's work ended")
	_check(state.career.history.size() == 2 and state.career.history[0].reason == "dismissed" \
			and state.career.history[0].to_year == Calendar.year, "history records the dismissal")
	season.advance_one_day()
	_check(Calendar.day == day + 1, "time runs again")
	for id in state.teams:
		if id != now.id:
			_check(not Owners.has_owner(state.teams[id]), "only the player's team has an owner")

	# Offers without a dismissal: only good principals, only better teams; they expire.
	state.career.boss_reputation = 10
	_check(Career.season_end(_table(series, now.id, 5), false, r).is_empty(), "weak principal gets no unasked offers")
	state.career.boss_reputation = 95
	var got := []
	for i in 20:
		got = Career.season_end(_table(series, now.id, 5), false, r)
		if not got.is_empty():
			break
	_check(not got.is_empty() and got.size() <= Career.MAX_INTEREST_OFFERS, "strong principal gets offers")
	for o in got:
		_check(state.teams[o.team_id].reputation > now.reputation, "unasked offers come from better teams")
	_check(not Career.job_pending(), "unasked offers do not stop time")
	Career.new_season()
	_check(Career.offers().is_empty(), "unasked offers expire with the new season")

	# The reputation follows the player's (new) team.
	state.career.boss_reputation = 50
	TeamReputation.season_end(series, _table(series, now.id, 1))
	_check(Career.reputation() > 50, "winning the title raises the principal's reputation")

	# A full season through the real finale: forced dismissal, new job, next season runs.
	now.owner.final_warning = true
	now.owner.trust = 5
	now.owner.goal = 1
	state.career.boss_reputation = 50
	var start_year: int = Calendar.year
	var guard := 0
	while not Career.job_pending() and guard < 800:
		guard += 1
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
	_check(Career.job_pending(), "the real finale dismissed the principal")
	var review: Dictionary = state.season_history.back()
	_check(review.owner.get("dismissed", false) and review.team_id == now.id, "review records the dismissal")
	var old_id: StringName = now.id
	Career.accept(Career.offers()[0])
	_check(state.player_team_id != old_id, "moved after the real finale")
	guard = 0
	while Calendar.year == start_year and guard < 200:
		guard += 1
		season.advance_one_day()
	_check(Calendar.year == start_year + 1, "new season started with the new team")
	_check(state.player_team().owner.goal >= 1, "new owner set goals for the new season")
	guard = 0
	while state.resolved_rounds == 0 and guard < 200:
		guard += 1
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
	_check(state.resolved_rounds >= 1, "the new team races: %d rounds" % state.resolved_rounds)

	TranslationServer.set_locale("de")
	_check(TranslationServer.translate("Career") == "Karriere", "German nav label")
	_check(TranslationServer.translate("Take the job") == "Job annehmen", "German button")
	_check(TranslationServer.translate("You have been dismissed") == "Du wurdest entlassen", "German subject")
	TranslationServer.set_locale("en")

	if _failures == 0:
		print("Career: dismissal rule, offers, waiting time, new team, unasked offers and a full season passed.")
	else:
		print("Career check: %d failure(s)." % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


## Standings with the player on the given position; the others fill the rest.
func _table(series: SeriesData, player_id: StringName, position: int) -> Array:
	var table := []
	var others := []
	for id in series.team_ids:
		if id != player_id:
			others.append(id)
	for i in series.team_ids.size():
		if i + 1 == position:
			table.append([player_id, 0])
		else:
			table.append([others.pop_front(), 0])
	return table
