## Money in and out of every team (R6, docs/finance_model.md). Every change of
## a team's budget goes through pay() or receive(), so the cash book shows
## where the money went; race weekends, months and the season end book their
## income and costs here as well.
class_name Finance
extends RefCounted

## Income and costs per race weekend, for every team of the series.
const TV_PER_RACE := 1_500_000
const LOGISTICS_PER_RACE := 2_500_000
## Yearly cost of one person in the departments (design, aero, rig, factory).
const DEPARTMENT_COST_PER_YEAR := 100_000

## Income categories in the order the finance screen shows them.
const INCOME := [
	[&"prize", "Prize money"],
	[&"tv", "TV and start money"],
	[&"sponsor", "Sponsors"],
	[&"merch", "Merchandise"],
	[&"owner", "Owner's grants"],
	[&"investor", "Investors"],
	[&"engine_sales", "Engine supply to customers"],
	[&"transfer_in", "Transfer fees received"],
]

## Cost categories in the order the finance screen shows them.
const EXPENSE := [
	[&"salaries", "Salaries"],
	[&"departments", "Department staff"],
	[&"upkeep", "HQ upkeep"],
	[&"engine_supply", "Engine fee"],
	[&"logistics", "Logistics"],
	[&"car", "Car development and parts"],
	[&"engine_dev", "Engine development"],
	[&"engine_units", "Extra engine units"],
	[&"hq", "HQ construction"],
	[&"signing", "Signing fees and severance"],
	[&"academy", "Academy and junior seats"],
	[&"scouting", "Scouting"],
	[&"transfer_out", "Transfer fees paid"],
	[&"investor_share", "Investor share of prize money"],
]


## Takes money out of a team's budget and books it.
static func pay(team: TeamData, category: StringName, amount: int) -> void:
	if amount <= 0:
		return
	team.budget -= amount
	_book(team, category, -amount)


## Puts money into a team's budget and books it.
static func receive(team: TeamData, category: StringName, amount: int) -> void:
	if amount <= 0:
		return
	team.budget += amount
	_book(team, category, amount)


static func _book(team: TeamData, category: StringName, signed: int) -> void:
	var book: Dictionary = GameState.cash_book.get_or_add(team.id, {})
	book[category] = book.get(category, 0) + signed
	EventBus.budget_changed.emit(team.id, team.budget)


## Income minus costs of a team this season.
static func net(team_id: StringName) -> int:
	var total := 0
	for amount in GameState.cash_book.get(team_id, {}).values():
		total += amount
	return total


## Sum of one side of the cash book: income (positive) or costs (negative).
static func total(team_id: StringName, income: bool) -> int:
	var sum := 0
	var categories := INCOME if income else EXPENSE
	var book: Dictionary = GameState.cash_book.get(team_id, {})
	for entry in categories:
		sum += book.get(entry[0], 0)
	return sum


## Records the budget after a change (monthly and after each race).
static func snapshot(team: TeamData) -> void:
	var history: Array = GameState.budget_history.get_or_add(team.id, [])
	history.append([Calendar.year, Calendar.day, team.budget])


## Income and costs of one race weekend for every team of the series.
static func race_settlement(series: SeriesData) -> void:
	for team_id in series.team_ids:
		var team: TeamData = GameState.teams.get(team_id)
		if not team:
			continue
		receive(team, &"tv", TV_PER_RACE)
		pay(team, &"logistics", LOGISTICS_PER_RACE)
		Sponsors.pay_race(team)
		receive(team, &"merch", TeamReputation.merch_per_race(team))
		snapshot(team)


## Monthly pay of the people in the departments (headcount × cost per year / 12).
static func departments_per_month(team: TeamData) -> int:
	var people := 0
	for d in CarDevelopment.REFERENCE_HEADCOUNT:
		people += CarDevelopment.headcount(team, d)
	return people * DEPARTMENT_COST_PER_YEAR / 12


## What the rest of the season is expected to bring, at today's standings:
## races, monthly costs and the prize money of the current position.
static func forecast(team: TeamData) -> Dictionary:
	var s: SeriesData = GameState.series[team.series_id]
	var races_left := 0
	for i in range(GameState.resolved_rounds, s.race_days.size()):
		if s.race_days[i] >= Calendar.day:
			races_left += 1
	var months_left: int = 12 - int(Calendar.date_of().month)
	var monthly: int = ContractLogic.payroll_per_month(team.id) + departments_per_month(team) + Facilities.upkeep_per_month(team)
	monthly += int(team.engine_deal.get("price", 0)) / 12
	monthly += team.academy_driver_ids.size() * Academy.FEE_PER_MONTH
	var position := _position_of(team, s)
	var prize: int = Season.PRIZE_MONEY_M[mini(position - 1, Season.PRIZE_MONEY_M.size() - 1)] * 1_000_000 if position > 0 else 0
	var sponsors: int = races_left * Sponsors.per_race(team.id) + Sponsors.bonuses_at(team.id, position)
	var merch: int = races_left * TeamReputation.merch_per_race(team)
	var income: int = races_left * TV_PER_RACE + prize + sponsors + merch
	var costs: int = races_left * LOGISTICS_PER_RACE + months_left * monthly
	return {"races_left": races_left, "months_left": months_left, "position": position,
		"prize": prize, "sponsors": sponsors, "merch": merch, "income": income, "costs": costs, "monthly": monthly,
		"budget_end": team.budget + income - costs}


static func _position_of(team: TeamData, s: SeriesData) -> int:
	var table := SeasonRecords.team_standings(s)
	for i in table.size():
		if table[i][0] == team.id:
			return i + 1
	return 0
