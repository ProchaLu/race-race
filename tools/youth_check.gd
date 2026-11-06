## Checks the junior pyramid, academy and scouting (R7, docs/youth_model.md):
## junior teams and seats, karting (hidden kids, discovery), the junior races,
## the season change, the academy (places, seat limit, offers and interest,
## rival academies, contracts, promises, seats, training focus, mentor, young
## driver test, mood, sale, offers, promotion, loan), scouting (scouts,
## assignments, race visits, misjudgement, reports), the super licence and the
## F1 market filter – and a whole season through the real wiring.
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

	# World: 20 junior teams with two drivers each, a pool, two karting cohorts, no juniors in F1.
	_check(state.youth_teams.size() == 20, "20 junior teams, got %d" % state.youth_teams.size())
	for t in state.youth_teams.values():
		_check(t.driver_ids.size() == Youth.SEATS, "two drivers in %s" % t.id)
		for id in t.driver_ids:
			var d: DriverData = state.drivers[id]
			_check(d.team_id == t.id and d.series_id == t.series_id, "driver seated in %s" % t.id)
	_check(Youth.pool().size() >= 20, "junior pool filled, got %d" % Youth.pool().size())
	var karting := Youth.karting()
	_check(karting.size() == 2 * Youth.NEWGENS_PER_YEAR, "two karting cohorts, got %d" % karting.size())
	_check(karting.filter(func(d): return Youth.is_visible(d)).is_empty(), "karting kids are hidden at the start")
	var wonderkids := karting.filter(func(d): return d.talent == &"wonderkid")
	var bloomers := karting.filter(func(d): return d.talent == &"late_bloomer")
	_check(wonderkids.size() >= 2 and wonderkids.size() <= 4, "1-2 wonderkids per cohort, got %d" % wonderkids.size())
	_check(bloomers.size() == 4, "2 late bloomers per cohort, got %d" % bloomers.size())
	_check(wonderkids.all(func(d): return d.potential >= 86), "wonderkids have a very high potential")
	for d in state.free_drivers():
		_check(not Youth.is_youth(d), "junior %s in the F1 market" % d.full_name())
	for key in Youth.all_series():
		var st := Youth.standings(key)
		_check(st.rounds == TestWorld.ROUNDS_COMPLETED, "%s ran %d rounds" % [key, st.rounds])
		_check(Youth.table(key).size() > 0, "%s has a table" % key)

	# Race practice: juniors with races get more than the pool.
	var pool_driver: DriverData = Youth.pool()[0]
	var f2_driver: DriverData = state.drivers[state.youth_teams[&"f2_hallen"].driver_ids[0]]
	_check(is_equal_approx(Youth.practice(pool_driver), Youth.PRACTICE_POOL), "pool juniors get the pool practice")
	_check(Youth.practice(f2_driver) > Youth.PRACTICE[Youth.KARTING], "an F2 season gives more practice than karting")
	_check(Youth.position(f2_driver) > 0 and Youth.last_result(f2_driver) >= 0, "table position and last result")

	# Season change: karting kids move up, a new cohort starts, seats are refilled.
	var year := Calendar.year + 1
	var old_kart: DriverData = karting.filter(func(d): return d.age(year) >= Youth.KART_LEAVE_AGE)[0]
	var report := Youth.new_season(year, r)
	_check(report.cohort == Youth.NEWGENS_PER_YEAR, "cohort size")
	_check(not Youth.is_karting(old_kart) and Youth.is_visible(old_kart), "16-year-olds leave karting and become visible")
	for t in state.youth_teams.values():
		_check(t.driver_ids.size() == Youth.SEATS, "seats refilled in %s" % t.id)
		for id in t.driver_ids:
			var d: DriverData = state.drivers[id]
			_check(d.age(year) <= Youth.max_age(t.series_id) and d.age(year) >= Youth.MIN_SEAT_AGE,
				"%s age fits %s" % [d.full_name(), t.series_id])
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

	_academy(state, team, r)
	_scouting(state, team, r)

	# Super licence: the junior champion earns 40 points and the licence.
	for i in 5:
		Youth.resolve_round()
	var champion: DriverData = state.drivers[Youth.table(Youth.F2)[0][0]]
	champion.has_superlicence = false
	var inbox_before: int = state.inbox.size()
	Youth.season_end()
	_check(Youth.licence_points(champion) >= Youth.LICENCE_NEEDED, "F2 champion earns the licence points")
	_check(champion.has_superlicence, "F2 champion has the super licence")
	_check(not champion.junior_history.is_empty() and champion.junior_history.back().position == 1, "junior history entry")
	_check(state.inbox.size() > inbox_before, "junior season message")

	_full_season(state)

	# The German texts of the new screens are in the compiled translation file.
	TranslationServer.set_locale("de")
	_check(TranslationServer.translate("Sign now") == "Sofort verpflichten", "German advice text")
	_check(TranslationServer.translate("Scouting office level") == "Stufe des Scouting-Büros", "German scouting label")
	_check(TranslationServer.translate("Karting kids found") != "Karting kids found", "German karting label")
	_check(TranslationServer.translate("Make the offer") != "Make the offer", "German offer button")
	TranslationServer.set_locale("en")

	if _failures == 0:
		print("Youth: junior teams, karting and discovery, seats, junior races, season change, academy (offers, rivals, "
			+ "seats, plan, mood, promises, sale, loan, promotion), scouting network and licence passed.")
	else:
		print("Youth check: %d failure(s)." % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _academy(state, team: TeamData, r: RandomNumberGenerator) -> void:
	team.facilities[&"academy"] = 3
	_check(Academy.places(team) == Academy.PLACES_BY_LEVEL[3], "academy places follow the building")
	var cands: Array[DriverData] = []
	for d in Youth.pool():
		if d.age(Calendar.year) <= Academy.INTAKE_MAX_AGE and d.age(Calendar.year) >= Youth.MIN_SEAT_AGE:
			cands.append(d)
	_check(cands.size() >= 6, "enough juniors for the academy, got %d" % cands.size())

	# Interest: promise and bonus help, an unattractive team is refused, a rival can win.
	var kid := cands[0]
	kid.ambition = 90
	kid.talent = &""
	var bare := Academy.interest(team, kid, {"years": 2})
	var rich := Academy.interest(team, kid, {"years": 1, "promise": &"f2_seat", "bonus": 300_000})
	_check(rich.score > bare.score + 20, "promise and bonus raise the interest (%d → %d)" % [bare.score, rich.score])
	team.reputation = 10
	var weak := Academy.interest(team, kid, {"years": 2})
	_check(not weak.accepted and Academy.sign_junior(team, kid, {"years": 2}) != "", "an unattractive offer is refused")
	team.reputation = 80
	var offer := {"years": 1, "promise": &"f2_seat", "bonus": 300_000}
	var answer := Academy.interest(team, kid, offer)
	if answer.accepted:
		_check(Academy.sign_junior(team, kid, offer) == "", "a convincing offer is accepted")
	else:
		_check(answer.rival != null, "only a rival academy beats the best offer")
		Academy.sign_junior(team, kid, {"force": true, "promise": &"f2_seat"})
	_check(kid.academy_team_id == team.id and Knowledge.level(kid) == 100, "signed junior is known exactly")
	_check(kid.academy_until >= Calendar.year and kid.academy_release_clause > 0, "academy contract and release clause")
	for i in range(1, Academy.places(team)):
		_check(Academy.sign_junior(team, cands[i], {"force": true}) == "", "sign %d into the academy" % i)
	_check(Academy.sign_junior(team, cands[Academy.places(team)], {"force": true}) != "", "a full academy refuses")
	_check(not Youth.pool().has(kid), "academy drivers leave the junior pool")

	# Seats: buying a taken seat, at most two per series.
	var t3: YouthTeam = state.youth_teams[&"f3_kiel"]
	for id in t3.driver_ids.duplicate():
		if state.drivers[id].academy_team_id != &"":
			Academy.forget(state.drivers[id])
	var seat := Academy.seat_offer(team, kid, t3)
	_check(seat.reason == "" and seat.replaces != null, "a taken seat can be bought")
	_check(seat.cost == Academy.PLACEMENT_FEE[Youth.F3] + Academy.SEAT_BUYOUT[Youth.F3], "bought seat costs fee + buyout")
	_check(Academy.place(team, kid, t3) == "", "buy a seat for an academy driver")
	_check(t3.driver_ids.has(kid.id) and Academy.is_placed(kid), "placed driver sits in the seat")
	var second: DriverData = cands[1]
	var third: DriverData = cands[2]
	second.birth_year = Calendar.year - 17
	third.birth_year = Calendar.year - 17
	_check(Academy.place(team, second, state.youth_teams[&"f3_marlow"]) == "", "second academy driver in F3")
	_check(Academy.place(team, third, state.youth_teams[&"f3_brisk"]) != "", "at most two academy drivers in F3")
	var little := Youth.karting()[0]
	little.birth_year = Calendar.year - 14
	little.academy_team_id = team.id
	_check(Academy.seat_offer(team, little, state.youth_teams[&"f3_brisk"]).reason != "", "karting kids are too young for a seat")
	little.academy_team_id = &""

	# Mood and promises: a kept promise pleases, a broken one hurts.
	kid.academy_promise = &"f2_seat"
	kid.academy_promise_year = Calendar.year
	second.academy_promise = &"f3_seat"
	second.academy_promise_year = Calendar.year
	Academy.check_promises(Calendar.year)
	_check(kid.morale_factors.has("Broken promise"), "an F2 promise kept in F3 is broken")
	_check(second.morale_factors.has("Promise kept"), "an F3 seat keeps the junior seat promise")
	_check(kid.academy_promise == &"" and second.academy_promise == &"", "promises are settled once")

	# Plan: focus, mentor, young driver test.
	Academy.set_focus(second, &"pace")
	var mentor: DriverData = Academy.mentors(team)[0]
	var base_factor := Academy.growth_factor(team, second)
	Academy.set_mentor(second, mentor.id)
	_check(Academy.growth_factor(team, second) > base_factor, "a mentor speeds up the growth")
	_check(second.morale_factors.has("Mentor"), "a mentor lifts the mood")
	var pace_before := second.one_lap_pace
	var wet_before := second.wet_skill
	second.potential = mini(95, second.overall() + 30)
	Academy._grow(team, second, r)
	_check(second.one_lap_pace - pace_before > second.wet_skill - wet_before, "the focus attributes grow more")
	_check(Academy.set_test(team, kid, true) == "" and Academy.set_test(team, second, true) == "", "two juniors for the test")
	_check(Academy.set_test(team, third, true) != "", "only two juniors for the young driver test")
	var msgs: int = state.inbox.size()
	Academy.young_driver_tests(team, r)
	_check(state.inbox.size() == msgs + 1 and not kid.young_driver_test, "young driver test report")
	_check(kid.morale_factors.has("Young driver test"), "the test lifts the mood")

	# Fees, contracts, extension.
	var fees_before: int = state.cash_book.get(team.id, {}).get(&"academy", 0)
	Academy.monthly_fees(team)
	var fees_after: int = state.cash_book.get(team.id, {}).get(&"academy", 0)
	_check(fees_before - fees_after == team.academy_driver_ids.size() * Academy.FEE_PER_MONTH, "monthly academy fees")
	var until := third.academy_until
	_check(Academy.extend(team, third) == "" and third.academy_until == maxi(until, Calendar.year) + 2, "contract extended")
	third.morale_factors["Test unhappy"] = -60
	third.recalculate_morale()
	third.academy_until = Calendar.year - 1
	Academy._end_contracts(team, Calendar.year)
	_check(third.academy_team_id == &"", "an unhappy junior leaves when his contract ends")
	third.morale_factors.erase("Test unhappy")
	third.recalculate_morale()

	# AI academies: they sign juniors, a rival's junior needs a buy-out, they place their drivers.
	var ai: TeamData = state.teams.values().filter(func(t): return t != team)[0]
	ai.facilities[&"academy"] = 3
	ai.facilities[&"scouting"] = 3
	var ai_before: int = ai.academy_driver_ids.size()
	for i in 6:
		Academy._ai_sign(ai)
	_check(ai.academy_driver_ids.size() > ai_before, "an AI academy signs juniors")
	if not ai.academy_driver_ids.is_empty():
		var ai_junior: DriverData = state.drivers[ai.academy_driver_ids[0]]
		_check(Academy.sign_junior(team, ai_junior, {"force": true}) != "", "another academy's junior needs a buy-out")
		Academy.ai_new_season(Calendar.year, r)
		_check(Academy.is_placed(ai_junior) or ai_junior.age(Calendar.year) < Youth.MIN_SEAT_AGE or Youth.is_karting(ai_junior)
			or ai_junior.academy_team_id != ai.id, "an AI academy places its drivers")

	# Sale and buying back with the release clause.
	var buyers := Academy.sell_offers(team, kid)
	if not buyers.is_empty():
		var cash: int = team.budget
		_check(Academy.sell(team, kid, buyers[0].team, buyers[0].fee) == "", "sell a junior to another academy")
		_check(kid.academy_team_id == buyers[0].team.id and team.budget == cash + buyers[0].fee, "the buyer pays the fee")
		var clause := kid.academy_release_clause
		var cash2: int = team.budget
		_check(Academy.sign_junior(team, kid, {"buyout": true, "force": true}) == "", "buy a junior out of another academy")
		_check(kid.academy_team_id == team.id and cash2 - team.budget >= clause, "the release clause is paid")

	# Offers of other academies for our best juniors.
	for d in Academy.drivers(team):
		d.potential = 95
	state.junior_offers.clear()
	var members_before: int = team.academy_driver_ids.size()
	for i in 60:
		Academy._offers_for(team, r)
	_check(not state.junior_offers.is_empty() or team.academy_driver_ids.size() < members_before,
		"other academies make offers for (or poach) our best juniors")
	if not state.junior_offers.is_empty():
		var o: Dictionary = state.junior_offers[0]
		var target: DriverData = state.drivers[o.driver_id]
		Academy.decline_offer(o)
		_check(target.academy_team_id == team.id, "a declined offer keeps the junior")

	# The way to F1: promotion needs the licence, a loan returns at the season change.
	var star: DriverData = Academy.drivers(team)[0]
	star.has_superlicence = false
	_check(Academy.promote(team, star, false) != "", "promotion needs the super licence")
	star.has_superlicence = true
	for e in DriverAttributes.DRIVING:
		star.set(e[0], 85)
	var lenders := Academy.loan_options(team, star)
	_check(not lenders.is_empty(), "a strong junior with a licence finds a loan team")
	if not lenders.is_empty():
		var to: TeamData = lenders[0]
		_check(Academy.loan(team, star, to) == "", "loan to an F1 team")
		_check(to.driver_ids.has(star.id) and star.loan_from == team.id, "loaned junior races in F1")
		Academy.return_loans(Calendar.year + 2)
		_check(star.loan_from == &"" and not to.driver_ids.has(star.id) and star.academy_team_id == team.id,
			"the loan ends and he is back in the academy")
	if team.reserve_driver_ids.size() < ContractLogic.RESERVE_SEATS:
		_check(Academy.promote(team, star, false) == "" and team.reserve_driver_ids.has(star.id), "promoted to reserve driver")
	else:
		_check(Academy.promote(team, star, false) != "", "no reserve place, no promotion")
	# A junior with a seat in our academy gets his results reported after each round.
	team.facilities[&"academy"] = 5
	var racer: DriverData = null
	for t in state.youth_teams.values():
		for id in t.driver_ids:
			var d: DriverData = state.drivers[id]
			if racer == null and d.academy_team_id == &"" and d.age(Calendar.year) <= Academy.INTAKE_MAX_AGE:
				racer = d
	if racer:
		Academy.sign_junior(team, racer, {"force": true})
	Youth.reset_standings()
	for i in 3:
		Youth.resolve_round()
	var count: int = state.inbox.size()
	Academy.round_report(team)
	_check(state.inbox.size() == count + 1, "round report for our juniors")


func _scouting(state, team: TeamData, r: RandomNumberGenerator) -> void:
	state.scout_assignments.clear()
	team.facilities[&"scouting"] = 2
	_check(Knowledge.chief_scout() != null, "chief scout exists")
	_check(Scouting.scouts(team).size() == 1, "only the chief scout at the start")
	var targets := Scouting.targets_of_series(Youth.F3)
	_check(targets.size() == Scouting.MAX_TARGETS, "assignment covers %d people" % Scouting.MAX_TARGETS)
	var err := Scouting.start(team, &"series", "F3", targets)
	_check(err == "", "scouting starts: %s" % err)
	_check(Scouting.free_slots(team) == 0, "one scout, one assignment (two slots)")
	_check(Scouting.blocked_reason(team).begins_with("All scouts are out"), "the reason says to hire a scout")
	# Hire scouts: the second slot works now; one scout per office level.
	var candidates := Scouting.candidates(r)
	_check(candidates.size() == Scouting.CANDIDATES, "scouts for hire")
	_check(Scouting.hire(team, candidates[0]) == "", "hire a scout")
	_check(Scouting.scouts(team).size() == 2 and Scouting.free_slots(team) == 1, "the new scout fills the second slot")
	_check(state.contract_of(candidates[0].id) != null, "the scout has a contract (salary)")
	_check(Scouting.hire(team, candidates[1]) == "" and Scouting.hire(team, candidates[2]) != "", "one scout per office level")
	# A region trip finds karting kids.
	var region := Scouting.region_of(candidates[0])
	var hidden_before := Scouting.hidden_of_region(region).size()
	_check(Scouting.start(team, &"region", "Trip", Scouting.targets_of_region(region), region) == "", "region trip starts")
	var weeks := 0
	while not state.scout_assignments.is_empty() and weeks < 40:
		weeks += 1
		Scouting.weekly_update(r)
	_check(state.scout_assignments.is_empty(), "assignments finished after %d weeks" % weeks)
	_check(Scouting.hidden_of_region(region).size() < hidden_before, "the trip discovered karting kids")
	for id in targets:
		var d: DriverData = state.drivers[id]
		_check(Knowledge.level(d) >= 70, "%s scouted" % d.full_name())
		_check(Scouting.recommendation(d) in ["Sign now", "Keep watching", "Not interesting"], "advice for %s" % d.full_name())
	# A race visit: knowledge for everybody, kids found in karting.
	var kart_key: StringName = Youth.KART_SERIES[&"europe"]
	var hidden_eu := Scouting.hidden_of_region(&"europe").size()
	_check(Scouting.watch(team, kart_key) == "", "send a scout to a karting race")
	_check(Scouting.watch(team, kart_key) != "", "one scout per race")
	Youth.resolve_round()
	_check(state.scout_assignments.filter(func(a): return a.kind == &"race").is_empty(), "the race visit ends after the race")
	_check(Scouting.hidden_of_region(&"europe").size() < hidden_eu or hidden_eu == 0, "the race visit found karting kids")
	# The report: lines grow with knowledge.
	var probe: DriverData = null
	for id in targets:
		if probe == null and state.drivers[id].academy_team_id != team.id:
			probe = state.drivers[id]
	_check(Scouting.report_lines(probe).size() >= 3, "a scouted junior has a full report")
	state.knowledge[probe.id] = 10
	_check(Scouting.report_lines(probe).size() == 1, "an unknown junior only has a first impression")
	# A misjudged person: the displayed range is shifted by the scout's bias.
	state.knowledge[probe.id] = 60
	state.scout_bias[probe.id] = {"ability": 3, "potential": -2}
	var internal := probe.overall()
	var shifted := clampi(DriverAttributes.to_display(internal) + 3, 1, 20)
	var range := Knowledge.display_range(probe, &"overall", internal)
	_check(range.x <= shifted and shifted <= range.y, "bias shifts the range")
	state.scout_bias.erase(probe.id)
	# Dismiss a scout; no office, no scouting.
	Scouting.dismiss(candidates[1])
	_check(Scouting.scouts(team).size() == 2, "a dismissed scout leaves")
	team.facilities[&"scouting"] = 0
	_check(Scouting.start(team, &"series", "F3", targets) != "", "no scouting office, no assignment")
	team.facilities[&"scouting"] = 2


## A whole season through the real wiring: the juniors race with the F1 rounds,
## academies sign and place, the season change refills the seats.
func _full_season(state) -> void:
	var season = get_tree().root.get_node("Season")
	state.season_history.clear()
	var start_year := Calendar.year
	var ai_academies := 0
	for t in state.teams.values():
		if t.id != state.player_team_id:
			ai_academies += t.academy_driver_ids.size()
	var guard := 0
	while Calendar.year == start_year and guard < 800:
		guard += 1
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
	_check(Calendar.year == start_year + 1, "a season passed in %d days" % guard)
	_check(not state.season_history.is_empty(), "the F1 season finished")
	var after := 0
	for t in state.teams.values():
		if t.id != state.player_team_id:
			after += t.academy_driver_ids.size()
	_check(after > ai_academies, "AI academies signed juniors during the season (%d → %d)" % [ai_academies, after])
	for t in state.youth_teams.values():
		_check(t.driver_ids.size() == Youth.SEATS, "seats filled after the real season change in %s" % t.id)
	_check(Youth.standings(Youth.F2).rounds == 0, "junior standings restarted")
	_check(Youth.karting().size() >= Youth.NEWGENS_PER_YEAR, "a new karting cohort")
	for d in state.drivers.values():
		if d.academy_team_id != &"":
			var owner: TeamData = state.teams.get(d.academy_team_id)
			_check(owner != null and owner.academy_driver_ids.has(d.id), "academy membership is consistent for %s" % d.full_name())
