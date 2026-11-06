## Checks the real start of a new game (docs/career_model.md 7): taking over a
## team on 1 January, founding a 12th team (24 cars), the founder rule, and a
## full season with the founded team through the season change.
## godot --headless --path . res://tools/new_game_check.tscn
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

	# Take over an existing team: 1 January, nothing raced yet.
	TestWorld.new_game({"mode": "existing", "team_id": &"kestrel"})
	var team: TeamData = state.player_team()
	_check(team.id == &"kestrel", "player runs Kestrel")
	_check(Calendar.day == 0 and Calendar.year == Calendar.START_YEAR, "starts on 1 January")
	_check(state.resolved_rounds == 0 and state.race_results.is_empty(), "no race run yet")
	_check(state.series[team.series_id].team_ids.size() == 11, "eleven teams without founding")
	_check(Owners.has_owner(team) and team.owner.goal >= 1, "owner with a goal")
	_check(not team.owner.get("founder", false), "a taken-over team has no founder")
	_check(not Sponsors.deals_of(team.id).is_empty(), "the team keeps sponsors")
	_check(state.drivers_of_team(team.id).size() == 2, "two drivers")
	for id in state.teams:
		if id != team.id:
			_check(not Owners.has_owner(state.teams[id]), "only the player's team has an owner")
	_check(not state.inbox.is_empty(), "welcome messages")

	# Validation of the founding form.
	_check(TeamFounding.check_options({"name": "Ab", "short_name": "ABC", "manufacturer": &"valkyr"}) != "", "short name refused")
	_check(TeamFounding.check_options({"name": "Vortex Racing", "short_name": "ABC", "manufacturer": &"valkyr"}) != "", "taken name refused")
	_check(TeamFounding.check_options({"name": "Phoenix Racing", "short_name": "VRT", "manufacturer": &"valkyr"}) != "", "taken short name refused")
	_check(TeamFounding.check_options({"name": "Phoenix Racing", "short_name": "PHX", "manufacturer": &"meridian_hp"}) != "", "full manufacturer refused")
	_check(TeamFounding.check_options({"name": "Phoenix Racing", "short_name": "PHX", "manufacturer": &"valkyr"}) == "", "good options accepted")
	_check(TeamFounding.short_from("Phoenix Racing") == "PHO", "short name from the name")

	# Found a team: the 12th team with 24 cars.
	TestWorld.new_game({"mode": "found", "name": "Phoenix Racing", "short_name": "PHX",
		"color": TeamFounding.COLORS[1], "manufacturer": &"valkyr"})
	team = state.player_team()
	var series: SeriesData = state.series[team.series_id]
	_check(team.id == TeamFounding.TEAM_ID and team.name == "Phoenix Racing" and team.short_name == "PHX", "founded team set up")
	_check(series.team_ids.size() == 12 and state.teams.size() == 12, "12 teams")
	var cars := 0
	for id in series.team_ids:
		cars += state.drivers_of_team(id).size()
	_check(cars == 24, "24 cars, got %d" % cars)
	_check(team.budget == TeamFounding.START_BUDGET and team.reputation == TeamFounding.START_REPUTATION, "start money and reputation")
	_check(team.engine_manufacturer == &"valkyr" and team.engine_deal.type == "customer", "customer engine")
	_check(team.engine_units.size() == 2, "engine units for both drivers")
	_check(state.staff_of_team(team.id).size() == StaffRoles.TEAM_POSITIONS.size(), "all key positions filled")
	for d in state.drivers_of_team(team.id):
		_check(state.contract_of(d.id) != null and state.contract_of(d.id).team_id == team.id, "driver contract")
		_check(state.race_engineer_of(d.id) != null, "race engineer for %s" % d.full_name())
	_check(Facilities.level(team, &"design") >= 1, "basic campus")
	_check(team.owner.founder and team.owner.personality == "patient", "patient backer, founder")
	_check(Owners.season_goal(team) >= 10, "modest goal for a new team: P%d" % Owners.season_goal(team))

	# The founder cannot be dismissed.
	team.owner.final_warning = true
	team.owner.trust = 3
	var table := []
	for id in series.team_ids:
		if id != team.id:
			table.append([id, 0])
	table.append([team.id, 0])
	var saved_goal: int = team.owner.goal
	team.owner.goal = 1
	var verdict := Owners.season_end(team, table, 0)
	_check(not verdict.dismissed, "founder not dismissed")
	team.owner.goal = saved_goal
	team.owner.trust = 60
	team.owner.final_warning = false

	# A full season with the founded team, into the next season.
	var start_year: int = Calendar.year
	var guard := 0
	while Calendar.year == start_year and guard < 800:
		guard += 1
		if Career.job_pending():
			break
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
	_check(Calendar.year == start_year + 1, "the season finished and a new one started")
	_check(not state.season_history.is_empty(), "season review")
	var review: Dictionary = state.season_history.back()
	_check(review.team_table.size() == 12, "12 teams in the final table")
	_check(review.rounds == series.calendar.size(), "all rounds raced")
	_check(state.player_team_id == TeamFounding.TEAM_ID, "still the founded team")
	_check(state.drivers_of_team(team.id).size() == 2, "seats filled for the new season: %d" % state.drivers_of_team(team.id).size())

	TranslationServer.set_locale("de")
	_check(TranslationServer.translate("Found your own team") == "Eigenes Team gründen", "German menu")
	_check(TranslationServer.translate("Take over a team") == "Team übernehmen", "German menu 2")
	TranslationServer.set_locale("en")

	if _failures == 0:
		print("New game: takeover on 1 January, founding (12 teams, 24 cars), founder rule and a full season passed.")
	else:
		print("New game check: %d failure(s)." % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
