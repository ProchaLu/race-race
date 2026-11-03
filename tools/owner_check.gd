## Checks the owner, investor, reputation and fans rules (docs/finance_model.md 11, 13),
## then plays a full season to check the wiring into the season.
## godot --headless --path . res://tools/owner_check.tscn
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var state = get_tree().root.get_node("GameState")
	var calendar = get_tree().root.get_node("Calendar")
	load("res://core/test_world.gd").build()
	var team: TeamData = state.player_team()
	var series: SeriesData = state.series[team.series_id]
	assert(Owners.has_owner(team), "player has no owner")
	for id in state.teams:
		if id != team.id:
			assert(not Owners.has_owner(state.teams[id]), "AI team has an owner")
	assert(team.owner.goal >= 1 and team.owner.goal <= series.team_ids.size(), "season goal out of range")

	# Money requests: once per season, granted money or lost trust.
	team.owner.trust = 100
	assert(Owners.grant_chance(team, 10_000_000) > Owners.grant_chance(team, 50_000_000), "bigger ask not harder")
	team.owner.trust = 20
	assert(Owners.grant_chance(team, 10_000_000) < 0.3, "low trust still generous")
	team.owner.trust = 60
	var granted := 0
	var refused := 0
	for i in 40:
		team.owner.last_request = 0
		var budget := team.budget
		var trust: int = team.owner.trust
		Owners.request_money(team, 10_000_000)
		if team.budget == budget + 10_000_000:
			granted += 1
			assert(team.owner.trust == trust, "grant changed trust")
		else:
			refused += 1
			assert(team.budget == budget and team.owner.trust == maxi(trust - 3, 0), "refusal wrong")
		team.owner.trust = 60
	assert(granted > 0 and refused > 0, "money requests never change outcome")
	team.owner.last_request = calendar.year
	assert(Owners.request_blocked(team) != "", "second request this season allowed")

	# Season verdict: trust follows the position against the goal (patient owner: losses ×0.7).
	team.owner.personality = "patient"
	team.owner.goal = 5
	team.owner.long_deadline = calendar.year + 3
	team.owner.titles_at_start = 0
	team.owner.titles = 0
	team.owner.trust = 60
	var met := Owners.season_end(team, _table(series, team.id, 3), 0)
	assert(met.met and team.owner.trust == 68, "goal met should give +8, got %d" % team.owner.trust)
	team.owner.trust = 60
	Owners.season_end(team, _table(series, team.id, 7), 0)
	assert(team.owner.trust == 60 - 3, "missed by two: %d" % team.owner.trust)
	team.owner.trust = 60
	Owners.season_end(team, _table(series, team.id, 9), 0)
	assert(team.owner.trust == 60 - 7, "missed badly: %d" % team.owner.trust)
	team.owner.personality = "impatient"
	team.owner.trust = 60
	Owners.season_end(team, _table(series, team.id, 7), 0)
	assert(team.owner.trust == 60 - 5, "impatient owner loses more: %d" % team.owner.trust)
	team.owner.personality = "patient"

	# Long-term goal: a title by the deadline raises trust and sets the next goal five years on.
	team.owner.trust = 60
	team.owner.long_deadline = calendar.year
	team.owner.titles_at_start = 0
	team.owner.titles = 0
	var verdict := Owners.season_end(team, _table(series, team.id, 1), 0)
	assert(verdict.long_met, "title not counted for the long-term goal")
	assert(team.owner.long_deadline == calendar.year + Owners.LONG_GOAL_YEARS)
	assert(team.owner.trust == 60 + 8 + 15, "title trust: %d" % team.owner.trust)
	team.owner.long_deadline = calendar.year
	team.owner.titles_at_start = team.owner.titles
	team.owner.trust = 60
	verdict = Owners.season_end(team, _table(series, team.id, 2), 0)
	assert(not verdict.long_met, "long-term goal met without a title")
	assert(team.owner.trust == 60 + 8 - 10, "missed long-term goal trust: %d" % team.owner.trust)

	# Investor: accepting pays the amount; the share of the prize goes out every season;
	# a missed condition ends the deal and costs trust.
	state.cash_book.clear()
	team.investor = {}
	team.investor_offer = {"name": "Test Capital", "amount": 30_000_000, "share": 0.1, "goal": 6,
		"years": 2, "expires_key": Sponsors.now_key() + 10}
	var budget := team.budget
	Owners.accept_investor(team)
	assert(team.budget == budget + 30_000_000, "investor money not paid")
	assert(team.investor_offer.is_empty() and team.investor.name == "Test Capital")
	assert(not team.investor.has("expires_key"))
	team.owner.trust = 60
	var before := team.budget
	Owners.season_end(team, _table(series, team.id, 2), 100_000_000)
	assert(team.budget == before - 10_000_000, "investor share not paid")
	assert(team.investor.years == 1 and not team.investor.is_empty(), "investor should stay")
	Owners.season_end(team, _table(series, team.id, 11), 0)
	assert(team.investor.is_empty(), "investor stayed after a missed condition")
	assert(team.owner.trust == 68 - 7 - 5, "investor leaving costs trust: %d" % team.owner.trust)

	# Reputation and fans: the best team gains, the last team loses, fans follow.
	var top: TeamData = state.teams[team.id]
	var bottom: TeamData = state.teams[series.team_ids[series.team_ids.size() - 1]]
	var top_rep := top.reputation
	var bottom_rep := bottom.reputation
	TeamReputation.season_end(series, _table(series, bottom.id, 11))
	assert(bottom.reputation <= bottom_rep, "last place gained reputation")
	assert(TeamReputation.merch_per_race(top) == top.fans * TeamReputation.MERCH_PER_FAN)
	TeamReputation.season_end(series, _table(series, top.id, 1))
	assert(top.reputation >= top_rep, "first place lost reputation")
	assert(top.reputation <= 100 and top.fans <= 100)

	# A full season plays through the wiring (finale, verdict, investors, reputation).
	team.owner.trust = 60
	team.owner.long_deadline = calendar.year + 5
	state.season_history.clear()
	var season = get_tree().root.get_node("Season")
	season.advance_one_day()
	var guard := 0
	while state.season_history.is_empty() and guard < 2000:
		guard += 1
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
	assert(not state.season_history.is_empty(), "season did not finish")
	var review: Dictionary = state.season_history.back()
	assert(review.has("owner") and not review.owner.is_empty(), "owner verdict missing from the review")
	print("Owner: requests, trust, long-term goal, investors, reputation and a full season passed. Trust now %d." % team.owner.trust)
	get_tree().quit()


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
