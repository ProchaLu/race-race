## Checks the junior pyramid, academy and scouting (R7, docs/youth_model.md):
## junior teams and seats, the junior races, the season change, the academy
## (places, signing, placing, fees, growth), scouting (assignments, weeks,
## misjudgement), the super licence and the F1 market filter.
## godot --headless --path . res://tools/youth_check.tscn
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
	load("res://core/test_world.gd").build()
	var team: TeamData = state.player_team()
	var r := RandomNumberGenerator.new()
	r.seed = 11

	# World: 20 junior teams with two drivers each, pool of newgens, no juniors in F1.
	_check(state.youth_teams.size() == 20, "20 junior teams, got %d" % state.youth_teams.size())
	for t in state.youth_teams.values():
		_check(t.driver_ids.size() == Youth.SEATS, "two drivers in %s" % t.id)
		for id in t.driver_ids:
			var d: DriverData = state.drivers[id]
			_check(d.team_id == t.id and d.series_id == t.series_id, "driver seated in %s" % t.id)
	_check(Youth.pool().size() >= 20, "newgen pool filled, got %d" % Youth.pool().size())
	for d in state.free_drivers():
		_check(not Youth.is_youth(d), "junior %s in the F1 market" % d.full_name())
	for series_id in Youth.SERIES:
		var st := Youth.standings(series_id)
		_check(st.rounds == TestWorld.ROUNDS_COMPLETED, "%s ran %d rounds" % [series_id, st.rounds])
		_check(Youth.table(series_id).size() > 0, "%s has a table" % series_id)

	# Season change: cohort, seats refilled inside the age limits.
	var year := Calendar.year + 1
	var report := Youth.new_season(year, r)
	_check(report.cohort == Youth.NEWGENS_PER_YEAR, "cohort size")
	for t in state.youth_teams.values():
		_check(t.driver_ids.size() == Youth.SEATS, "seats refilled in %s" % t.id)
		for id in t.driver_ids:
			var d: DriverData = state.drivers[id]
			_check(d.age(year) <= Youth.max_age(t.series_id), "%s too old for %s" % [d.full_name(), t.series_id])
	_check(Youth.table(Youth.F2).is_empty(), "standings reset at the season change")

	# Too old: a junior without licence retires, one with a licence joins the F1 market.
	var old := PersonGenerator.driver(r, PersonGenerator.DriverTier.NEWGEN)
	old.birth_year = year - 30
	old.series_id = Youth.POOL
	state.add_driver(old)
	var old_licence := PersonGenerator.driver(r, PersonGenerator.DriverTier.NEWGEN)
	old_licence.birth_year = year - 30
	old_licence.series_id = Youth.POOL
	old_licence.has_superlicence = true
	state.add_driver(old_licence)
	Youth.new_season(year, r)
	_check(old.retired, "old junior without licence leaves the sport")
	_check(not old_licence.retired and old_licence.series_id == &"", "old junior with licence joins the F1 market")
	_check(state.free_drivers().has(old_licence), "licence holder is on the F1 market")

	# Academy: places, signing, placing, fees, growth, release.
	team.facilities[&"academy"] = 3
	_check(Academy.places(team) == 3, "academy places follow the building")
	var cands: Array[DriverData] = []
	for d in Youth.pool():
		if d.age(year) <= Academy.INTAKE_MAX_AGE:
			cands.append(d)
	_check(cands.size() >= 4, "enough juniors for the academy, got %d" % cands.size())
	for i in 3:
		_check(Academy.sign(team, cands[i]) == "", "sign %d into the academy" % i)
	_check(Academy.sign(team, cands[3]) != "", "a full academy refuses")
	_check(Academy.drivers(team).size() == 3, "three academy drivers")
	_check(Knowledge.level(cands[0]) == 100, "academy drivers are known exactly")
	_check(not Youth.pool().has(cands[0]), "academy drivers leave the junior pool")

	var a := cands[0]
	a.birth_year = year - 18
	var t3: YouthTeam
	for t in state.youth_teams.values():
		if t.series_id == Youth.F3:
			t3 = t
			break
	Youth.unseat(state.drivers[t3.driver_ids[0]])
	_check(t3.driver_ids.size() == 1, "one free seat in %s" % t3.id)
	_check(Academy.place(team, a, t3) == "", "place an academy driver in a junior seat")
	_check(a.team_id == t3.id and t3.driver_ids.has(a.id) and Academy.is_placed(a), "placed driver sits in the seat")
	_check(Academy.place(team, cands[1], t3) != "", "a full junior team refuses")

	var fees_before: int = state.cash_book.get(team.id, {}).get(&"academy", 0)
	Academy.monthly_fees(team)
	var fees_after: int = state.cash_book.get(team.id, {}).get(&"academy", 0)
	_check(fees_before - fees_after == 3 * Academy.FEE_PER_MONTH, "monthly academy fees")

	var overall_before := a.overall()
	Academy.new_season(team, r)
	_check(a.overall() >= overall_before, "academy drivers do not shrink")
	_check(a.overall() <= a.potential, "academy growth stops at the potential")

	Academy.bring_back(a)
	_check(a.team_id == &"" and not t3.driver_ids.has(a.id), "bring back frees the seat")
	_check(Academy.drivers(team).has(a), "bring back keeps the academy place")
	Academy.release(a)
	_check(a.academy_team_id == &"" and not team.academy_driver_ids.has(a.id), "release leaves the academy")

	# Scouting: one office, one assignment at a time; the chief scout finishes it in time.
	team.facilities[&"scouting"] = 1
	_check(Knowledge.chief_scout() != null, "chief scout exists")
	var targets := Scouting.targets_of_series(Youth.F3)
	_check(targets.size() == Scouting.MAX_TARGETS, "assignment covers %d people" % Scouting.MAX_TARGETS)
	var err := Scouting.start(team, &"series", "F3", targets)
	_check(err == "", "scouting starts: %s" % err)
	_check(state.scout_assignments.size() == 1, "one assignment running")
	var weeks: int = state.scout_assignments[0].weeks_total
	_check(weeks >= 1, "assignment takes weeks")
	var second := Scouting.start(team, &"region", "Europe", Scouting.targets_of_region(&"europe"))
	_check(second != "", "one office, one assignment at a time")
	for w in weeks:
		Scouting.weekly_update(r)
	_check(state.scout_assignments.is_empty(), "assignment finished after %d weeks" % weeks)
	var goal := Scouting.done_level(Scouting.skill(team))
	for id in targets:
		var d: DriverData = state.drivers[id]
		_check(Knowledge.level(d) >= goal, "%s scouted to %d" % [d.full_name(), goal])
		_check(Scouting.recommendation(d) in ["Sign now", "Keep watching", "Not interesting"], "advice for %s" % d.full_name())

	# A misjudged person: the displayed range is shifted by the scout's bias.
	var probe: DriverData = state.drivers[targets[0]]
	state.scout_bias[probe.id] = {"ability": 3, "potential": -2}
	var internal := probe.overall()
	var shifted := clampi(DriverAttributes.to_display(internal) + 3, 1, 20)
	var range := Knowledge.display_range(probe, &"overall", internal)
	_check(range.x <= shifted and shifted <= range.y, "bias shifts the range")
	state.scout_bias.erase(probe.id)

	# No office, no scouting.
	team.facilities[&"scouting"] = 0
	_check(Scouting.start(team, &"series", "F3", targets) != "", "no scouting office, no assignment")

	# Super licence: the junior champion earns 40 points and the licence.
	for i in 5:
		Youth.resolve_round()
	var champion: DriverData = state.drivers[Youth.table(Youth.F2)[0][0]]
	champion.has_superlicence = false
	var inbox_before: int = state.inbox.size()
	Youth.season_end()
	_check(Youth.licence_points(champion) >= Youth.LICENCE_NEEDED, "F2 champion earns the licence points")
	_check(champion.has_superlicence, "F2 champion has the super licence")
	_check(state.inbox.size() > inbox_before, "junior season message")

	# A whole season through the real wiring: the juniors race with the F1 rounds,
	# the season change refills the seats and starts new standings.
	var season = get_tree().root.get_node("Season")
	state.season_history.clear()
	var start_year := Calendar.year
	var guard := 0
	while Calendar.year == start_year and guard < 800:
		guard += 1
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
	_check(Calendar.year == start_year + 1, "a season passed in %d days" % guard)
	_check(not state.season_history.is_empty(), "the F1 season finished")
	for t in state.youth_teams.values():
		_check(t.driver_ids.size() == Youth.SEATS, "seats filled after the real season change in %s" % t.id)
	_check(Youth.standings(Youth.F2).rounds == 0, "junior standings restarted")
	_check(Youth.pool().size() >= 20, "newgens joined the pool in the real season change")

	# The German texts of the new screens are in the compiled translation file.
	TranslationServer.set_locale("de")
	_check(TranslationServer.translate("Sign now") == "Sofort verpflichten", "German advice text")
	_check(TranslationServer.translate("Scouting office level") == "Stufe des Scouting-Büros", "German scouting label")
	TranslationServer.set_locale("en")

	if _failures == 0:
		print("Youth: junior teams, seats, junior races, season change, academy, scouting and licence passed.")
	else:
		print("Youth check: %d failure(s)." % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
