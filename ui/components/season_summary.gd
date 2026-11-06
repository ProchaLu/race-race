## End-of-season overlay, shown once at the switch to the new season (and
## from the season review): how the season went, how good the team and the
## drivers were compared with the car, and what changed over the winter.
class_name SeasonSummary
extends Control

signal closed

var _review: Dictionary
var _shell: AppShell


func _init(review: Dictionary, shell: AppShell) -> void:
	_review = review
	_shell = shell
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UIStyle.BG, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.BG, UIStyle.ACCENT, 1, 0, 0))
	margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	column.add_child(_title_bar())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(pad)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", UIStyle.GAP)
	pad.add_child(page)

	page.add_child(_headline_card())
	var row := _row(page)
	row.add_child(_progress_card())
	row.add_child(_team_card())
	page.add_child(_drivers_card())
	page.add_child(_development_card())
	var row2 := _row(page)
	row2.add_child(_car_card())
	row2.add_child(_grid_card())
	row2.add_child(_table_card())
	column.add_child(_footer())


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	parent.add_child(row)
	return row


func _close() -> void:
	closed.emit()
	queue_free()


# --- Title and footer --------------------------------------------------------

func _title_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, Color.TRANSPARENT, 0, 20, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var small := Label.new()
	var review_team: TeamData = GameState.teams.get(_review.get("team_id", GameState.player_team_id))
	small.text = tr("End of season · %s") % review_team.name
	small.uppercase = true
	small.theme_type_variation = &"SectionLabel"
	titles.add_child(small)
	var title := Label.new()
	title.text = tr("Season %d – the review") % _review.year
	title.uppercase = true
	title.theme_type_variation = &"NameLabel"
	titles.add_child(title)
	row.add_child(titles)
	var close := Button.new()
	close.icon = UIStyle.icon("x") if ResourceLoader.exists(UIStyle.ICON_DIR + "x.svg") else null
	close.text = "" if close.icon else "✕"
	close.theme_type_variation = &"FlatButton"
	close.tooltip_text = "Close"
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close)
	row.add_child(close)
	bar.add_child(row)
	return bar


func _footer() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, Color.TRANSPARENT, 0, 20, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_END
	var review := Button.new()
	review.text = "Season review"
	review.icon = UIStyle.icon("trophy")
	review.pressed.connect(func():
		_close()
		_shell.navigate(&"season_review", {"year": _review.year}))
	row.add_child(review)
	var go := Button.new()
	go.theme_type_variation = &"AccentButton"
	go.icon = UIStyle.icon("play")
	go.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var next_year: int = _review.year + 1
	go.text = (tr("Start season %d") % next_year).to_upper() if Calendar.year == next_year else tr("Close").to_upper()
	go.pressed.connect(_close)
	row.add_child(go)
	bar.add_child(row)
	return bar


# --- Headline ----------------------------------------------------------------

## How the result compares with the car: [title, text, colour].
func _verdict() -> Array:
	var position: int = _review.team_position
	var car: int = _review.get("car_rank", position)
	var diff := car - position
	if diff >= 2:
		return ["An excellent season", tr("P%d with only the car ranked %d in the field – far above expectations.") % [position, car], UIStyle.GOOD]
	if diff == 1:
		return ["A good season", tr("P%d with the car ranked %d – a little more than the car promised.") % [position, car], UIStyle.OK]
	if diff == 0:
		return ["As expected", tr("P%d – exactly where the car ranked %d belongs.") % [position, car], UIStyle.TEXT]
	if diff == -1:
		return ["Below expectations", tr("P%d with the car ranked %d – points were left on the table.") % [position, car], UIStyle.WARN]
	return ["A disappointing season", tr("Only P%d with the car ranked %d – the team must do better.") % [position, car], UIStyle.BAD]


func _headline_card() -> UICard:
	var v := _verdict()
	var card := UICard.new()
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = tr(v[0])
	title.uppercase = true
	title.theme_type_variation = &"HeadingLabel"
	title.add_theme_color_override("font_color", v[2])
	head.add_child(title)
	var text := Label.new()
	text.text = v[1]
	text.theme_type_variation = &"MutedLabel"
	head.add_child(text)
	card.add_padded(head, 12, 6)

	var tiles := HBoxContainer.new()
	var last: int = _review.get("last_position", 0)
	var position: int = _review.team_position
	var t1 := StatusTile.new("Constructors", "P%d" % position, v[2])
	if last > 0:
		_sub(t1, tr("last year P%d") % last + (" ▲" if position < last else (" ▼" if position > last else "")))
	tiles.add_child(t1)
	var t2 := StatusTile.new("Points", str(_review.team_points), UIStyle.TEXT)
	_sub(t2, tr("%d rounds") % _review.rounds)
	tiles.add_child(t2)
	var wins := 0
	var podiums := 0
	var poles := 0
	for d in _review.drivers:
		wins += d.wins
		podiums += d.podiums
		poles += d.poles
	var t3 := StatusTile.new("Wins · podiums · poles", "%d · %d · %d" % [wins, podiums, poles], UIStyle.ACCENT)
	tiles.add_child(t3)
	var t4 := StatusTile.new("Prize money", UIStyle.money(_review.prize), UIStyle.GOOD)
	if _review.prize_next_lower > 0:
		_sub(t4, tr("+%s vs. one place lower") % UIStyle.money(_review.prize - _review.prize_next_lower))
	tiles.add_child(t4)
	var champion: DriverData = GameState.drivers.get(_review.champion_driver)
	var t5 := StatusTile.new("Drivers' champion", champion.full_name() if champion else "–", UIStyle.PODIUM[0])
	tiles.add_child(t5)
	var champ_team: TeamData = GameState.teams.get(_review.champion_team)
	var t6 := StatusTile.new("Constructors' champion", champ_team.name if champ_team else "–", UIStyle.PODIUM[0])
	tiles.add_child(t6)
	card.add_padded(tiles, 4, 4)
	return card


func _sub(tile: StatusTile, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	tile.get_child(0).add_child(l)


# --- Progress and team -------------------------------------------------------

func _progress_card() -> UICard:
	var progress: Array = _review.get("progress", [])
	var card := UICard.new("Season progress", "constructors' points after every round")
	card.size_flags_stretch_ratio = 1.6
	if progress.size() < 2:
		card.add_padded(_small("No data."), 8, 4)
		return card
	var values: Array[float] = []
	var labels: Array[String] = []
	var best := 99
	var best_round := 0
	var worst := 0
	var worst_round := 0
	for i in progress.size():
		values.append(float(progress[i][0]))
		labels.append(str(i + 1) if (i + 1) % 2 == 1 or progress.size() <= 12 else "")
		if progress[i][1] < best:
			best = progress[i][1]
			best_round = i + 1
		if progress[i][1] > worst:
			worst = progress[i][1]
			worst_round = i + 1
	card.add_padded(Sparkline.new(values, labels, 150, 0), 6, 2)
	var line := HFlowContainer.new()
	line.add_theme_constant_override("h_separation", 6)
	for i in progress.size():
		var p: int = progress[i][1]
		var chip := Label.new()
		chip.text = "P%d" % p
		chip.theme_type_variation = &"MonoLabel"
		chip.add_theme_font_size_override("font_size", 12)
		chip.add_theme_color_override("font_color", UIStyle.position_color(p) if p <= 3 else (UIStyle.OK if p <= 5 else UIStyle.MUTED))
		chip.tooltip_text = tr("Constructors' position after round %d") % (i + 1)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		line.add_child(chip)
	card.add_padded(line, 2, 2)
	card.add_padded(_small(tr("Best position: P%d after round %d · worst: P%d after round %d") % [best, best_round, worst, worst_round]), 2, 4)
	return card


func _team_card() -> UICard:
	var t: Dictionary = _review.get("team_stats", {})
	var card := UICard.new("Team performance", "full race weekends")
	card.add_row(FactRow.new("Car ranked in the field", "%d." % _review.get("car_rank", 0), "", true))
	card.add_row(FactRow.new("Result", "P%d" % _review.team_position, "", true, _verdict()[2]))
	if t.get("stops", 0) > 0:
		card.add_row(FactRow.new("Pit stops", str(t.stops), "", true))
		card.add_row(FactRow.new("Average pit stop", "%.2f s" % _review.average_stop, "", true,
			UIStyle.GOOD if _review.average_stop < 2.6 else (UIStyle.WARN if _review.average_stop > 3.2 else UIStyle.TEXT)))
		card.add_row(FactRow.new("Fastest pit stop", "%.2f s" % t.best_stop, "", true))
		card.add_row(FactRow.new("Pit stop mistakes", str(t.pit_issues), "", true, UIStyle.BAD if t.pit_issues > 3 else UIStyle.TEXT))
	card.add_row(FactRow.new("Retirements: technical · crashes", "%d · %d" % [t.get("technical_dnf", 0), t.get("crash_dnf", 0)], "", true))
	card.add_row(FactRow.new("Overtakes · driver mistakes", "%d · %d" % [t.get("overtakes", 0), t.get("mistakes", 0)], "", true))
	card.add_row(FactRow.new("Key moments decided", str(t.get("moments", 0)), "", true))
	card.add_row(FactRow.new("New parts this season", str(_review.get("new_parts", 0)), "", true))
	card.add_row(FactRow.new("Spent on the car", UIStyle.money(_review.get("car_spent", 0)), "", true))
	if _review.get("owner", {}).has("goal"):
		var o: Dictionary = _review.owner
		card.add_row(FactRow.new("Owner's goal: P%d" % o.goal, "P%d" % o.position, "trust %d → %d" % [o.trust_before, o.trust],
			true, UIStyle.GOOD if o.met else UIStyle.BAD))
		if o.get("dismissed", false):
			card.add_row(FactRow.new("Owner's decision", "Dismissed", "", true, UIStyle.BAD))
	if _review.get("job_offers", 0) > 0:
		card.add_row(FactRow.new("Job offers from other teams", str(_review.job_offers), "", true))
	if _review.has("cash"):
		var net := 0
		for amount in _review.cash.values():
			net += amount
		card.add_row(FactRow.new("Money: net this season", UIStyle.money(net), "", true, UIStyle.money_color(net)))
	if _review.has("hq_spent"):
		card.add_row(FactRow.new("HQ: building levels completed", str(_review.hq_completed), "", true))
		card.add_row(FactRow.new("HQ: invested", UIStyle.money(_review.hq_spent), "", true))
		card.add_row(FactRow.new("Campus rank", "P%d" % _review.campus_rank, "", true))
	if _review.get("engine_name", "") != "":
		card.add_row(FactRow.new("Engine", "%s · power P%d" % [_review.engine_name, _review.engine_power_rank], "", true))
		card.add_row(FactRow.new("Engine units used", str(_review.engine_units), "", true))
		if _review.get("engine_spent", 0) > 0:
			card.add_row(FactRow.new("Engine development and extra units", UIStyle.money(_review.engine_spent), "", true))
	return card


# --- Drivers -----------------------------------------------------------------

## Driver result vs. what the car allowed: [label, colour].
func _driver_grade(d: Dictionary) -> Array:
	var diff: int = d.get("expected", d.position) - d.position
	if diff >= 3:
		return ["Outstanding", UIStyle.GOOD]
	if diff >= 1:
		return ["Above expectations", UIStyle.OK]
	if diff >= -1:
		return ["As expected", UIStyle.TEXT]
	if diff >= -3:
		return ["Below expectations", UIStyle.WARN]
	return ["Disappointing", UIStyle.BAD]


func _drivers_card() -> UICard:
	var card := UICard.new("Your drivers", "result compared with the car")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	for d in _review.drivers:
		row.add_child(_driver_box(d))
	if _review.drivers.is_empty():
		row.add_child(_small("No driver raced for the team at the end of the season."))
	card.add_padded(row, 8, 8)
	return card


func _driver_box(d: Dictionary) -> Control:
	var driver: DriverData = GameState.drivers.get(d.driver_id)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1, 14, 10))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	box.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	if driver:
		var portrait := TextureRect.new()
		portrait.texture = UIStyle.portrait(driver, 56)
		top.add_child(portrait)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = driver.full_name() if driver else "–"
	name_label.theme_type_variation = &"StrongLabel"
	names.add_child(name_label)
	names.add_child(_small(tr("%d years · overall %d · morale %d") % [d.get("age", 0), d.get("overall", 0), d.get("morale", 0)]))
	var grade := _driver_grade(d)
	var grade_label := Label.new()
	grade_label.text = tr(grade[0])
	grade_label.theme_type_variation = &"StrongLabel"
	grade_label.add_theme_color_override("font_color", grade[1])
	names.add_child(grade_label)
	top.add_child(names)
	var big := BigStat.new("P%d" % d.position, "Championship", UIStyle.position_color(d.position) if d.position <= 3 else UIStyle.ACCENT)
	big.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(big)
	column.add_child(top)
	var facts := [
		["Points", str(d.points)],
		["Wins · podiums · poles", "%d · %d · %d" % [d.wins, d.podiums, d.poles]],
		["Average finish", "P%.1f" % d.get("avg_finish", 0.0)],
		["Best result", "P%d" % d.best if d.get("best", 0) > 0 else "–"],
		["Retirements", str(d.retirements)],
		["Expected from the car", "P%d" % d.get("expected", 0)],
	]
	if d.get("rounds", 0) > 0:
		facts.append(["Teammate duel (quali · race)", "%d–%d · %d–%d" % [d.quali_ahead, d.rounds - d.quali_ahead, d.race_ahead, d.rounds - d.race_ahead]])
	for i in facts.size():
		var fact := FactRow.new(facts[i][0], facts[i][1], "", true)
		fact.set_zebra(i % 2 == 1)
		column.add_child(fact)
	return box


# --- Winter development ------------------------------------------------------

func _development_card() -> UICard:
	var winter: Dictionary = _review.get("winter", {})
	var card := UICard.new("Development over the winter", "overall rating and biggest changes")
	if winter.is_empty():
		card.add_padded(_small("The winter development is shown at the start of the new season."), 8, 4)
		return card
	for d in winter.drivers:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var name_label := Label.new()
		name_label.text = "%s (%d)" % [d.name, d.age]
		name_label.theme_type_variation = &"StrongLabel"
		name_label.custom_minimum_size.x = 220
		row.add_child(name_label)
		row.add_child(_delta_label(d.before, d.after))
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 6)
		chips.add_theme_constant_override("v_separation", 4)
		chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var changes: Array = d.changes.keys()
		changes.sort_custom(func(a, b): return absi(d.changes[a]) > absi(d.changes[b]))
		for property in changes.slice(0, 8):
			var delta: int = d.changes[property]
			chips.add_child(_chip("%s %+d" % [tr(DriverStatus.attribute_name(property)), delta],
				UIStyle.GOOD if delta > 0 else UIStyle.BAD))
		if changes.is_empty():
			chips.add_child(_small("No changes"))
		row.add_child(chips)
		var left := not GameState.player_team().driver_ids.has(d.id) and not GameState.player_team().reserve_driver_ids.has(d.id)
		if left:
			row.add_child(_small("left the team"))
		card.add_padded(row, 6, 6)
	if not winter.staff.is_empty():
		card.add_section("Staff")
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 28)
		grid.add_theme_constant_override("v_separation", 4)
		var staff: Array = winter.staff.duplicate()
		staff.sort_custom(func(a, b): return a.after - a.before > b.after - b.before)
		for s in staff:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			row.custom_minimum_size.x = 380
			var l := Label.new()
			l.text = "%s · %s" % [s.name, tr(s.role)]
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row.add_child(l)
			row.add_child(_delta_label(s.before, s.after))
			if not GameState.player_team().staff_ids.has(s.get("id", &"")):
				l.text += "  · " + tr("left the team")
				l.add_theme_color_override("font_color", UIStyle.MUTED)
			grid.add_child(row)
		card.add_padded(grid, 4, 6)
	card.add_padded(_small("Overall rating 0–100. Young people grow towards their potential, older drivers lose physical strength first; experience keeps growing."), 4, 4)
	return card


func _delta_label(before: int, after: int) -> Label:
	var l := Label.new()
	var delta := after - before
	l.text = "%d → %d  (%+d)" % [before, after, delta]
	l.theme_type_variation = &"MonoLabel"
	l.add_theme_color_override("font_color", UIStyle.GOOD if delta > 0 else (UIStyle.BAD if delta < 0 else UIStyle.MUTED))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _chip(text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(Color(color, 0.12), Color(color, 0.45), 1, 6, 1))
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.add_theme_color_override("font_color", color.lightened(0.15))
	panel.add_child(l)
	return panel


# --- Car, grid, table --------------------------------------------------------

func _car_card() -> UICard:
	var winter: Dictionary = _review.get("winter", {})
	var card := UICard.new("The new car", tr("season %d") % (_review.year + 1))
	var detail: Dictionary = winter.get("car_detail", {})
	if detail.is_empty():
		card.add_padded(_small("Shown at the start of the new season."), 8, 4)
		return card
	for k in detail:
		var pair: Array = detail[k]
		var delta: int = pair[1] - pair[0]
		card.add_row(FactRow.new(tr(k), "%d → %d  (%+d)" % [pair[0], pair[1], delta], "", true,
			UIStyle.GOOD if delta > 0 else (UIStyle.BAD if delta < 0 else UIStyle.TEXT)))
	card.add_padded(_small("Until car development arrives, the car changes over the winter with the quality of the technical staff."), 4, 4)
	return card


func _grid_card() -> UICard:
	var winter: Dictionary = _review.get("winter", {})
	var card := UICard.new("Around the grid")
	if winter.is_empty():
		card.add_padded(_small("Shown at the start of the new season."), 8, 4)
		return card
	if not winter.risers.is_empty():
		card.add_section("Biggest steps forward")
		for e in winter.risers:
			card.add_row(FactRow.new("%s · %s" % [e[0], e[1]], "%d → %d" % [e[2], e[3]], "", true, UIStyle.GOOD))
	if not winter.fallers.is_empty():
		card.add_section("Losing ground")
		for e in winter.fallers:
			card.add_row(FactRow.new("%s · %s" % [e[0], e[1]], "%d → %d" % [e[2], e[3]], "", true, UIStyle.BAD))
	card.add_section("Changes")
	if not winter.retired.is_empty():
		card.add_padded(_small(tr("Retired: %s.") % ", ".join(winter.retired)), 2, 2)
	if not winter.ended.is_empty():
		card.add_padded(_small(tr("Our contracts ended: %s.") % ", ".join(winter.ended)), 2, 2)
	for p in winter.promoted:
		card.add_padded(_small(tr("%s moves up from reserve driver to a race seat.") % p), 2, 2)
	if winter.retired.is_empty() and winter.ended.is_empty() and winter.promoted.is_empty():
		card.add_padded(_small("No retirements and no contracts ended in our team."), 2, 2)
	return card


func _table_card() -> UICard:
	var card := UICard.new("Final constructors' table")
	var table: Array = _review.team_table
	for i in table.size():
		var team: TeamData = GameState.teams.get(table[i][0])
		if not team:
			continue
		var row := InfoRow.new("%d.  %s" % [i + 1, team.name], "", tr("%d pts") % table[i][1],
			UIStyle.ACCENT if team.id == _review.get("team_id", GameState.player_team_id) else UIStyle.TEXT, true)
		card.add_row(row)
	return card


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
