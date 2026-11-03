## Finances (R6a, docs/finance_model.md): the budget now, what the season has
## brought in and cost so far, the balance over the season and the forecast
## to the end of the season at today's standings.
extends UIScreen

var _team: TeamData


func setup(_args: Dictionary) -> void:
	_team = GameState.player_team()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)
	page.add_child(_stats_row())
	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", UIStyle.GAP)
	middle.add_child(_balance_card())
	middle.add_child(_forecast_card())
	page.add_child(middle)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", UIStyle.GAP)
	bottom.add_child(_cash_card(Finance.INCOME, true))
	bottom.add_child(_cash_card(Finance.EXPENSE, false))
	page.add_child(bottom)


func screen_title() -> String:
	return "Finances"


func nav_section() -> StringName:
	return &"finances"


func _stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var income := Finance.total(_team.id, true)
	var costs := Finance.total(_team.id, false)
	var end: int = Finance.forecast(_team).budget_end
	var stats := [
		[UIStyle.money(_team.budget), tr("Budget now"), UIStyle.money_color(_team.budget)],
		[UIStyle.money(income), tr("Income this season"), UIStyle.GOOD],
		[UIStyle.money(-costs), tr("Costs this season"), UIStyle.BAD],
		[UIStyle.money(end), tr("Forecast at season end"), UIStyle.money_color(end)],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _balance_card() -> UICard:
	var card := UICard.new(tr("Balance this season"), tr("budget in $M"))
	var points: Array[float] = []
	var labels: Array[String] = []
	for entry in GameState.budget_history.get(_team.id, []):
		if entry[0] != Calendar.year:
			continue
		points.append(entry[2] / 1_000_000.0)
		labels.append(tr(Calendar.MONTHS[Calendar.date_of(entry[1], entry[0]).month - 1]))
	if points.size() < 2:
		card.add_padded(_small(tr("The chart starts with the first race or month of the season.")), 8, 8)
	else:
		card.add_padded(Sparkline.new(points, labels, 170, 0), 8, 8)
	return card


func _forecast_card() -> UICard:
	var f := Finance.forecast(_team)
	var card := UICard.new(tr("Forecast"), tr("at today's standings"))
	card.add_row(FactRow.new(tr("Races left"), "%d" % f.races_left, "", true))
	var prize_label := tr("Prize money at P%d") % f.position if f.position > 0 else tr("Prize money")
	card.add_row(FactRow.new(prize_label, UIStyle.money(f.prize), "", true, UIStyle.GOOD))
	card.add_row(FactRow.new(tr("Sponsors"), UIStyle.money(f.sponsors),
		tr("%s per race") % UIStyle.money(Sponsors.per_race(_team.id)), true, UIStyle.GOOD))
	card.add_row(FactRow.new(tr("Merchandise"), UIStyle.money(f.merch),
		tr("%s per race") % UIStyle.money(TeamReputation.merch_per_race(_team)), true, UIStyle.GOOD))
	card.add_row(FactRow.new(tr("TV and start money"), UIStyle.money(f.races_left * Finance.TV_PER_RACE),
		tr("%s per race") % UIStyle.money(Finance.TV_PER_RACE), true, UIStyle.GOOD))
	card.add_row(FactRow.new(tr("Logistics"), UIStyle.money(-f.races_left * Finance.LOGISTICS_PER_RACE),
		tr("%s per race") % UIStyle.money(Finance.LOGISTICS_PER_RACE), true, UIStyle.BAD))
	card.add_row(FactRow.new(tr("Salaries, departments, upkeep and engine fee"), UIStyle.money(-f.months_left * f.monthly),
		tr("%d months × %s") % [f.months_left, UIStyle.money(f.monthly)], true, UIStyle.BAD))
	card.add_row(FactRow.new(tr("Budget at season end"), UIStyle.money(f.budget_end), "", true,
		UIStyle.money_color(f.budget_end)))
	if f.budget_end < 0:
		card.add_padded(_small(tr("Warning: at this pace the budget runs out before the season ends.")), 8, 8)
	return card


## One side of the cash book: income (true) or costs (false) per category.
func _cash_card(categories: Array, income: bool) -> UICard:
	var card := UICard.new(tr("Income this season") if income else tr("Costs this season"))
	var book: Dictionary = GameState.cash_book.get(_team.id, {})
	var sum := 0
	var rows := 0
	for entry in categories:
		var amount: int = book.get(entry[0], 0)
		if amount == 0:
			continue
		card.add_row(FactRow.new(tr(entry[1]), UIStyle.money(amount), "", true, UIStyle.money_color(amount)))
		sum += amount
		rows += 1
	if rows == 0:
		card.add_padded(_small(tr("Nothing booked yet this season.")), 8, 8)
	else:
		card.add_row(FactRow.new(tr("Total"), UIStyle.money(sum), "", true, UIStyle.money_color(sum)))
	return card


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
