## Season review after the final round (mockup r2_season.html, screen 4):
## result, prize money, best driver, the season in numbers, big moments,
## the final table and what changes over the winter.
extends UIScreen

var _review: Dictionary
var _page: VBoxContainer


func setup(args: Dictionary) -> void:
	var year: int = args.get("year", -1)
	for r in GameState.season_history:
		if year < 0 or r.year == year:
			_review = r
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)
	if _review.is_empty():
		var card := UICard.new("Season review")
		card.add_padded(_note("The season review is available after the final round."), 8, 4)
		_page.add_child(card)
		return
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	var summary := Button.new()
	summary.text = "Full season summary"
	summary.icon = UIStyle.icon("trophy")
	summary.pressed.connect(func(): shell.show_season_summary(_review.year))
	top.add_child(summary)
	_page.add_child(top)
	_page.add_child(_hero())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	row.add_child(_numbers_card())
	row.add_child(_moments_card())
	row.add_child(_winter_card())
	_page.add_child(row)
	_page.add_child(_table_card())


func screen_title() -> String:
	return tr("Season review %d") % _review.year if not _review.is_empty() else "Season review"


func nav_section() -> StringName:
	return &"standings"


func _hero() -> UICard:
	var r := _review
	var card := UICard.new(tr("Season %d") % r.year, tr("%d rounds") % r.rounds)
	var tiles := HBoxContainer.new()
	var pos_color := UIStyle.GOOD if r.team_position <= 5 else UIStyle.TEXT
	var t1 := StatusTile.new("Constructors", "P%d" % r.team_position, pos_color)
	_sub(t1, tr("%d points") % r.team_points)
	tiles.add_child(t1)
	var t2 := StatusTile.new("Prize money", UIStyle.money(r.prize), UIStyle.GOOD)
	if r.prize_next_lower > 0:
		_sub(t2, tr("+%s vs. one place lower") % UIStyle.money(r.prize - r.prize_next_lower))
	tiles.add_child(t2)
	if not r.drivers.is_empty():
		var best: Dictionary = r.drivers[0]
		var d: DriverData = GameState.drivers.get(best.driver_id)
		var t3 := StatusTile.new("Best driver", "%s P%d" % [d.last_name if d else "–", best.position], UIStyle.ACCENT)
		_sub(t3, tr("%d pts · %d wins") % [best.points, best.wins])
		tiles.add_child(t3)
	var champion: DriverData = GameState.drivers.get(r.champion_driver)
	var champ_team: TeamData = GameState.teams.get(r.champion_team)
	var t4 := StatusTile.new("Champions", champion.last_name if champion else "–", UIStyle.PODIUM[0])
	_sub(t4, tr("Constructors: %s") % (champ_team.name if champ_team else "–"))
	tiles.add_child(t4)
	card.add_padded(tiles, 4, 4)
	return card


func _sub(tile: StatusTile, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	tile.get_child(0).add_child(l)


func _numbers_card() -> UICard:
	var r := _review
	var card := UICard.new("Season in numbers")
	var wins := 0
	var podiums := 0
	var poles := 0
	var dnfs := 0
	for d in r.drivers:
		wins += d.wins
		podiums += d.podiums
		poles += d.poles
		dnfs += d.retirements
	card.add_row(FactRow.new("Points", str(r.team_points), "", true))
	card.add_row(FactRow.new("Wins · podiums · poles", "%d · %d · %d" % [wins, podiums, poles], "", true))
	card.add_row(FactRow.new("Retirements", str(dnfs), "", true))
	if r.average_stop > 0.0:
		card.add_row(FactRow.new("Average pit stop", "%.2f s" % r.average_stop, tr("full race weekends only"), true))
	if r.drivers.size() >= 2:
		var a: Dictionary = r.drivers[0]
		var b: Dictionary = r.drivers[1]
		var da: DriverData = GameState.drivers.get(a.driver_id)
		var db: DriverData = GameState.drivers.get(b.driver_id)
		if da and db:
			card.add_row(FactRow.new(tr("%s vs. %s (quali · race)") % [da.last_name, db.last_name],
				"%d–%d · %d–%d" % [a.quali_ahead, b.quali_ahead, a.race_ahead, b.race_ahead], "", true))
	return card


func _moments_card() -> UICard:
	var card := UICard.new("Big moments")
	if _review.moments.is_empty():
		card.add_padded(_note("No podium this season. Next year will be better."), 6, 4)
		return card
	for m in _review.moments.slice(0, 8):
		card.add_row(FactRow.new("R%d" % m[0], tr(m[1]) % m[2], "", false, UIStyle.ACCENT if m[1].begins_with("Win") else UIStyle.TEXT))
	return card


## What changes over the winter: own contracts that end, old drivers who
## may retire, young talent on the market.
func _winter_card() -> UICard:
	var card := UICard.new("Before next season", "changes over the winter")
	var shown := 0
	if Calendar.year == _review.year:
		for p in GameState.drivers_of_team(GameState.player_team_id) + GameState.player_team().reserve_driver_ids.map(func(id): return GameState.drivers[id]):
			var c := GameState.contract_of(p.id)
			if c and c.end_year <= Calendar.year:
				card.add_row(FactRow.new(tr("Contract ends: %s") % p.full_name(), tr("extend or replace?"), "", false, UIStyle.WARN))
				shown += 1
		for s in GameState.staff_of_team(GameState.player_team_id):
			var c := GameState.contract_of(s.id)
			if c and c.end_year <= Calendar.year:
				card.add_row(FactRow.new(tr("Contract ends: %s") % s.full_name(), tr(StaffRoles.name_of(s.role)), "", false, UIStyle.WARN))
				shown += 1
	var young := GameState.free_drivers().filter(func(d): return d.age(Calendar.year) <= 21).size()
	if young > 0:
		card.add_row(FactRow.new("Young drivers on the market", str(young), "", true, UIStyle.ACCENT))
		shown += 1
	if shown == 0:
		card.add_padded(_note("No contracts end this winter."), 6, 4)
	card.add_padded(_note("Contracts that end this season expire on 1 January. Empty race seats are filled by the reserve driver."), 6, 2)
	var market := Button.new()
	market.text = "Transfer market"
	market.icon = UIStyle.icon("arrow-left-right")
	market.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	market.pressed.connect(func(): shell.navigate(&"market"))
	card.add_padded(market, 6, 0)
	return card


func _table_card() -> UICard:
	var card := UICard.new("Final constructors' table")
	var table: Array = _review.team_table
	for i in table.size():
		var team: TeamData = GameState.teams.get(table[i][0])
		if not team:
			continue
		var prize: int = Season.PRIZE_MONEY_M[mini(i, Season.PRIZE_MONEY_M.size() - 1)]
		var row := InfoRow.new("%d.  %s" % [i + 1, team.name], tr("%d pts") % table[i][1], "$%dM" % prize,
			UIStyle.ACCENT if team.id == _review.get("team_id", GameState.player_team_id) else UIStyle.TEXT, true)
		card.add_row(row)
	return card


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
