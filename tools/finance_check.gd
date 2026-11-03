## Checks the money model (docs/finance_model.md): bookkeeping, race
## settlement and a full season of money for every team. Prints the season
## balance per team so the numbers can be read against the targets.
## godot --headless --path . res://tools/finance_check.tscn
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var state = get_tree().root.get_node("GameState")
	var season = get_tree().root.get_node("Season")
	load("res://core/test_world.gd").build()
	var team: TeamData = state.player_team()
	var series: SeriesData = state.series[team.series_id]

	# Every budget change is booked: the cash book explains the budget exactly.
	state.cash_book.clear()
	team.budget = 100_000_000
	var start := team.budget
	Finance.receive(team, &"prize", 7_000_000)
	Finance.pay(team, &"car", 2_500_000)
	Finance.pay(team, &"salaries", 0)
	assert(team.budget == start + 4_500_000, "budget not changed by receive/pay")
	assert(Finance.total(team.id, true) == 7_000_000)
	assert(Finance.total(team.id, false) == -2_500_000)
	assert(Finance.net(team.id) == team.budget - start, "cash book does not explain the budget")

	# One race weekend settles TV money and logistics for every team of the series.
	state.cash_book.clear()
	var before := {}
	for id in series.team_ids:
		before[id] = state.teams[id].budget
	Finance.race_settlement(series)
	var per_race: int = Finance.TV_PER_RACE - Finance.LOGISTICS_PER_RACE
	for id in series.team_ids:
		assert(state.teams[id].budget - before[id] == per_race + Sponsors.per_race(id) + TeamReputation.merch_per_race(state.teams[id]), "race settlement wrong for %s" % id)
	assert(Finance.net(team.id) == per_race + Sponsors.per_race(team.id) + TeamReputation.merch_per_race(team))

	# Forecast: the remaining races, the months and the prize of today's position.
	var fc := Finance.forecast(team)
	assert(fc.races_left > 0 and fc.position > 0)
	assert(fc.budget_end == team.budget + fc.income - fc.costs)

	# A full season of money, played through the player's weekends.
	state.cash_book.clear()
	var starts := {}
	for id in state.teams:
		starts[id] = state.teams[id].budget
	var rounds_left: int = series.calendar.size() - state.resolved_rounds
	var forecast_mid := 0
	var mid_done := false
	var guard := 0
	season.advance_one_day()
	while state.season_history.is_empty() and guard < 2000:
		guard += 1
		if season.weekend_pending():
			season.race_weekend()
		else:
			season.advance_one_day()
		if not mid_done and state.resolved_rounds >= rounds_left / 2:
			mid_done = true
			forecast_mid = Finance.forecast(team).budget_end
	assert(not state.season_history.is_empty(), "season did not finish")

	print("\nSeason money, %d rounds played:" % rounds_left)
	print("  %-24s %10s %10s %10s %10s" % ["team", "start", "income", "costs", "end"])
	for id in state.teams:
		var t: TeamData = state.teams[id]
		var marker := "  <- you" if t.id == team.id else ""
		print("  %-24s %10s %10s %10s %10s%s" % [t.name, _m(starts[t.id]), _m(Finance.total(t.id, true)),
			_m(Finance.total(t.id, false)), _m(t.budget), marker])
	print("\nYour cash book this season:")
	for entry in Finance.INCOME + Finance.EXPENSE:
		var amount: int = state.cash_book.get(team.id, {}).get(entry[0], 0)
		if amount != 0:
			print("  %-34s %10s" % [entry[1], _m(amount)])
	print("Forecast at mid-season: %s, actual end: %s" % [_m(forecast_mid), _m(team.budget)])
	print("\nFinance: bookkeeping, race settlement, forecast and a full season passed.")
	get_tree().quit()


func _m(amount: float) -> String:
	return "%.1f M" % (amount / 1_000_000.0)
