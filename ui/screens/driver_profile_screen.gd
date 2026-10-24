## Football-Manager-style driver profile, "Columns" layout (design doc 15.4b):
## identity + rating, status strip, four attribute/contract columns,
## then season, last races, relationships/promises and development chart.
## Clicking an attribute shows its history in the development chart.
extends UIScreen

var driver: DriverData
## Attribute shown in the development chart (empty = overall rating).
var _chart_attribute: StringName = &""
var _attribute_rows := {}  # property -> AttributeRow
var _chart_slot: VBoxContainer


func setup(args: Dictionary) -> void:
	driver = GameState.drivers[args.driver_id]
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)

	page.add_child(_row([_identity_card(), _rating_card()], [2.6, 1.0]))
	page.add_child(_status_strip())
	page.add_child(_row([
		_attribute_card("Driving", DriverAttributes.DRIVING, "Scale 1–20"),
		_attribute_card("Mental", DriverAttributes.MENTAL),
		_stack([_physical_card(), _traits_card()]),
		_contract_card(),
	]))
	_chart_slot = VBoxContainer.new()
	page.add_child(_row([
		_season_card(),
		_races_card(),
		_stack([_relationships_card(), _promises_card()]),
		_chart_slot,
	], [1.0, 1.15, 1.0, 1.0]))
	_show_chart(&"")


func screen_title() -> String:
	return "Driver profile"


func nav_section() -> StringName:
	return &"drivers" if driver.team_id != &"" else &"market"


# --- Layout helpers ----------------------------------------------------------

func _row(children: Array, ratios: Array = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	for i in children.size():
		var child: Control = children[i]
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		child.size_flags_stretch_ratio = ratios[i] if i < ratios.size() else 1.0
		row.add_child(child)
	return row


## Vertical stack; the last card stretches so columns end at the same height.
func _stack(children: Array) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", UIStyle.GAP)
	for child in children:
		stack.add_child(child)
	(children.back() as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	return stack


# --- Top ---------------------------------------------------------------------

func _identity_card() -> Control:
	var team: TeamData = GameState.teams.get(driver.team_id)
	var team_color := team.primary_color if team else UIStyle.LINE_STRONG
	var contract := GameState.contract_of(driver.id)
	var panel := PanelContainer.new()
	var style := UIStyle.box(UIStyle.PANEL, UIStyle.LINE, 1, 14, 8)
	style.border_width_left = 5
	style.border_color = team_color
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var portrait := TextureRect.new()
	portrait.texture = UIStyle.portrait(driver, 90)
	frame.add_child(portrait)
	row.add_child(frame)

	var number := Label.new()
	number.text = str(driver.number)
	number.theme_type_variation = &"NameLabel"
	number.add_theme_font_size_override("font_size", 60)
	number.add_theme_color_override("font_color", team_color)
	number.custom_minimum_size.x = 70
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(number)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var first := Label.new()
	first.text = driver.first_name
	first.uppercase = true
	first.theme_type_variation = &"SectionLabel"
	first.add_theme_font_size_override("font_size", 17)
	text.add_child(first)
	var last := Label.new()
	last.text = driver.last_name
	last.uppercase = true
	last.theme_type_variation = &"NameLabel"
	text.add_child(last)

	var meta := HFlowContainer.new()
	meta.add_theme_constant_override("h_separation", 26)
	meta.add_theme_constant_override("v_separation", 2)
	_meta_pair(meta, "Nationality", Countries.name_of(driver.nationality))
	_meta_pair(meta, "Age", tr("%d (born %d)") % [driver.age(Calendar.year), driver.birth_year])
	_meta_pair(meta, "Team", team.name if team else tr("Free agent"))
	if contract:
		_meta_pair(meta, "Role", ContractData.role_name(contract.role))
	_meta_pair(meta, "Super licence", "Valid" if driver.has_superlicence else "Missing")
	text.add_child(meta)
	row.add_child(text)
	panel.add_child(row)
	return panel


func _meta_pair(parent: Container, key: String, value: String) -> void:
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 6)
	var k := Label.new()
	k.text = key
	k.theme_type_variation = &"MutedLabel"
	pair.add_child(k)
	var v := Label.new()
	v.text = value
	v.theme_type_variation = &"StrongLabel"
	pair.add_child(v)
	parent.add_child(pair)


func _rating_card() -> UICard:
	var exact := Knowledge.is_exact(driver)
	var card := UICard.new("Rating", "" if exact else tr(Knowledge.label(driver)))
	card.add_row(_star_row("Current ability", Knowledge.star_range(driver, &"overall", driver.overall()),
		DriverStatus.ability_breakdown(driver) if exact else null))
	card.add_row(_star_row("Potential", Knowledge.star_range(driver, &"potential", driver.potential),
		DriverStatus.potential_breakdown(driver) if exact else null))
	return card


func _star_row(label: String, stars: Vector2, b: Breakdown) -> HoverRow:
	var row := HoverRow.new()
	var line := HBoxContainer.new()
	var text := Label.new()
	text.text = label
	text.theme_type_variation = &"MutedLabel"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	var image := TextureRect.new()
	image.texture = StarRating.texture_range(stars.x, stars.y, 20)
	line.add_child(image)
	row.add_child(line)
	if b:
		row.set_breakdown(b)
	return row


func _status_strip() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Card"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)

	var tiles: Array[StatusTile] = []
	var t := StatusTile.new("Morale", DriverStatus.level_label(driver.morale),
		UIStyle.meter_color(driver.morale), driver.morale)
	t.set_breakdown(DriverStatus.morale_breakdown(driver))
	tiles.append(t)
	t = StatusTile.new("Form", DriverStatus.form_label(driver.form),
		UIStyle.meter_color(driver.form), driver.form)
	t.set_breakdown(DriverStatus.form_breakdown(driver))
	tiles.append(t)
	t = StatusTile.new("Confidence", DriverStatus.level_label(driver.confidence),
		UIStyle.meter_color(driver.confidence), driver.confidence)
	t.set_breakdown(DriverStatus.confidence_breakdown(driver))
	tiles.append(t)
	t = StatusTile.new("Fitness", "%d %%" % driver.match_fitness,
		UIStyle.meter_color(driver.match_fitness), driver.match_fitness)
	t.set_breakdown(DriverStatus.fitness_breakdown(driver))
	tiles.append(t)
	var injured := driver.injury_weeks > 0
	t = StatusTile.new("Injury", tr("%d weeks") % driver.injury_weeks if injured else "None",
		UIStyle.BAD if injured else UIStyle.GOOD)
	t.set_breakdown(DriverStatus.injury_breakdown(driver))
	tiles.append(t)
	var focus := DriverStatus.attribute_name(driver.training_focus) if driver.training_focus != &"" else "Balanced"
	t = StatusTile.new("Training focus", focus, UIStyle.TEXT)
	t.set_breakdown(DriverStatus.training_breakdown(driver))
	tiles.append(t)

	for i in tiles.size():
		if i > 0:
			row.add_child(VSeparator.new())
		row.add_child(tiles[i])
	return panel


# --- Attribute columns -------------------------------------------------------

func _attribute_card(title: String, group: Array, subtitle: String = "") -> UICard:
	var card := UICard.new(title, subtitle if subtitle != "" else tr("%d attributes") % group.size())
	for entry in group:
		card.add_row(_attribute_row(entry))
	return card


func _attribute_row(entry: Array) -> AttributeRow:
	var property: StringName = entry[0]
	var internal: int = driver.get(property)
	var value := DriverAttributes.to_display(internal)
	var known := Knowledge.display_range(driver, property, internal)
	var row := AttributeRow.new(entry[1], value, driver.attribute_changes.get(property, 0), known)
	if known.x == known.y:
		row.set_breakdown(DriverStatus.attribute_breakdown(driver, property, entry[1]))
	else:
		row.set_breakdown(Breakdown.new("%s %d–%d" % [tr(entry[1]), known.x, known.y],
			tr(DriverAttributes.DESCRIPTIONS.get(property, "")) + " " + tr("Only an estimate: your team does not know this person well.")))
	row.make_clickable()
	row.clicked.connect(_on_attribute_clicked.bind(property))
	_attribute_rows[property] = row
	return row


## Clicking the selected attribute again goes back to the overall rating.
func _on_attribute_clicked(property: StringName) -> void:
	_show_chart(&"" if property == _chart_attribute else property)


func _physical_card() -> UICard:
	var card := UICard.new("Physical & experience")
	for entry in DriverAttributes.PHYSICAL:
		card.add_row(_attribute_row(entry))

	card.add_section("Experience")
	var level := "Rookie" if driver.races < 25 else ("Experienced" if driver.races < 100 \
		else ("Veteran" if driver.races < 250 else "Legend"))
	var experience_text := tr("No Formula Apex races yet") if driver.races == 0 \
		else tr("%d races in %d seasons") % [driver.races, driver.seasons + 1]
	card.add_padded(_bar_with_label(experience_text, level, minf(driver.races / 300.0 * 100.0, 100.0)), 2, 2)

	var next := GameState.next_round_index()
	var s: SeriesData = GameState.series.get(driver.series_id)
	if next >= 0 and s and driver.team_id != &"":
		var track: TrackData = GameState.tracks[s.calendar[next]]
		# Stand-in until track knowledge is tracked per track (simulator, visits).
		var visits := mini(driver.seasons, 6)
		var knowledge := mini(40 + visits * 10, 100)
		card.add_section("Knowledge of next track")
		card.add_padded(_bar_with_label(tr("%s · %d previous visits") % [track.short_name.capitalize(), visits],
			"%d %%" % knowledge, knowledge), 2, 2)
	return card


func _bar_with_label(left: String, right: String, percent: float) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	var line := HBoxContainer.new()
	var l := Label.new()
	l.text = left
	l.theme_type_variation = &"MutedLabel"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(l)
	var r := Label.new()
	r.text = right
	r.theme_type_variation = &"StrongLabel"
	line.add_child(r)
	column.add_child(line)
	column.add_child(Meter.new(percent, UIStyle.ACCENT, 6))
	return column


func _traits_card() -> UICard:
	var card := UICard.new("Traits", tr("%d known") % driver.traits.size())
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for trait_id in driver.traits:
		list.add_child(TraitRow.new(trait_id))
	if driver.traits.is_empty():
		var none := Label.new()
		none.text = "No special traits known."
		none.theme_type_variation = &"MutedLabel"
		list.add_child(none)
	card.add_padded(list, 4, 0)
	return card


func _contract_card() -> UICard:
	var card := UICard.new("Contract")
	var c := GameState.contract_of(driver.id)
	if not c:
		card.add_row(FactRow.new("Status", tr("Free agent"), "", false, UIStyle.GOOD))
		card.add_row(FactRow.new("Salary demand", tr("about %s per year") % UIStyle.money(ContractLogic.salary_demand(driver)), "", true))
		var free_agent := ContractLogic.agent_of(driver)
		if free_agent:
			card.add_row(FactRow.new("Agent", free_agent.full_name(), tr(AgentData.style_name(free_agent.style))))
		card.add_padded(ContractActions.new(driver, shell), 12, 0)
		return card
	var salary_row := FactRow.new("Salary", tr("%s per year") % UIStyle.money(c.salary), "", true)
	salary_row.set_breakdown(Breakdown.new(tr("Salary %s per year") % UIStyle.money(c.salary),
		"Paid monthly. Bonuses are paid after each race.")
		.add("Base salary", UIStyle.money(c.salary))
		.add("Win bonus", UIStyle.money(c.win_bonus))
		.add("Podium bonus", UIStyle.money(c.podium_bonus)))
	card.add_row(salary_row)
	var seasons_left := c.end_year - Calendar.year
	var left_text := "ends this season"
	if seasons_left == 1:
		left_text = tr("1 more season after this one")
	elif seasons_left > 1:
		left_text = tr("%d more seasons after this one") % seasons_left
	card.add_row(FactRow.new("Contract ends", tr("End of %d") % c.end_year, left_text,
		false, UIStyle.WARN if seasons_left <= 0 else UIStyle.TEXT))
	card.add_row(FactRow.new("Role", ContractData.role_name(c.role)))
	card.add_row(FactRow.new("Bonus per win", UIStyle.money(c.win_bonus), "", true))
	card.add_row(FactRow.new("Bonus per podium", UIStyle.money(c.podium_bonus), "", true))
	var release := FactRow.new("Release clause",
		UIStyle.money(c.release_clause) if c.release_clause > 0 else "None", "", true)
	release.set_breakdown(Breakdown.new("Release clause",
		"If another team pays this amount, he may talk to them and leave."))
	card.add_row(release)
	var agent := ContractLogic.agent_of(driver)
	if agent:
		card.add_row(FactRow.new("Agent", agent.full_name(), tr(AgentData.style_name(agent.style))))
	card.add_padded(ContractActions.new(driver, shell), 10, 0)
	return card


# --- Bottom row --------------------------------------------------------------

func _season_card() -> UICard:
	var stats: DriverSeasonStats = GameState.season_stats.get(driver.id)
	var s: SeriesData = GameState.series.get(driver.series_id)
	var card := UICard.new(tr("Season %d") % Calendar.year, tr("after round %d") % GameState.rounds_completed())
	if not stats or not s or stats.races() == 0:
		var none := Label.new()
		none.text = "No Formula Apex races this season."
		none.theme_type_variation = &"MutedLabel"
		card.add_padded(none, 8, 0)
		return card
	var standing := GameState.championship_position(driver.id)
	var big := HBoxContainer.new()
	big.add_child(BigStat.new("P%d" % standing, "Championship", UIStyle.ACCENT))
	big.add_child(BigStat.new(str(stats.points), "Points"))
	big.add_child(BigStat.new(str(stats.wins), "Wins"))
	big.add_child(BigStat.new(str(stats.podiums), "Podiums"))
	card.add_padded(big, 2, 6)

	card.add_row(FactRow.new("Races driven", tr("%d of %d") % [stats.races(), s.calendar.size()], "", true))
	card.add_row(FactRow.new("Poles / retirements", "%d / %d" % [stats.poles, stats.retirements], "", true))
	var avg := FactRow.new("Average finishing position", "P%.1f" % stats.average_finish(), "", true)
	avg.set_breakdown(Breakdown.new(tr("Average finishing position: P%.1f") % stats.average_finish(),
		"The average position he crossed the finish line in. Retirements are not counted.")
		.add("Races finished", str(stats.races() - stats.retirements)))
	card.add_row(avg)
	card.add_row(FactRow.new("Points per race", "%.1f" % stats.points_per_race(), "", true))

	var standings := GameState.driver_standings(driver.series_id)
	var leader_points: int = GameState.season_stats[standings[0]].points
	if standing == 1 and standings.size() > 1:
		var second: int = GameState.season_stats[standings[1]].points
		card.add_row(FactRow.new("Lead over P2", tr("+%d pts") % (stats.points - second), "", true, UIStyle.GOOD))
	else:
		card.add_row(FactRow.new("Gap to championship leader", tr("-%d pts") % (leader_points - stats.points), "", true))
	return card


func _races_card() -> UICard:
	var card := UICard.new("Last 5 races")
	var stats: DriverSeasonStats = GameState.season_stats.get(driver.id)
	if not stats or stats.results.is_empty():
		var none := Label.new()
		none.text = "No Formula Apex races this season."
		none.theme_type_variation = &"MutedLabel"
		card.add_padded(none, 8, 0)
		return card
	var boxes := HBoxContainer.new()
	boxes.add_theme_constant_override("separation", 6)
	for r in stats.last_results(5):
		var track: TrackData = GameState.tracks[r.track_id]
		var finish: int = r.finish
		var text := "P%d" % finish if finish > 0 else "OUT"
		var color := UIStyle.BAD if finish == 0 else (UIStyle.GOOD if finish == 1 \
			else (UIStyle.ACCENT if finish <= 3 else UIStyle.TEXT))
		var box := ResultBox.new(text, color, track.short_name)
		var b := Breakdown.new(tr("Round %d, %s: %s") % [r.round, track.name, tr("retired") if finish == 0 else text])
		b.add("Started", "P%d" % r.grid)
		if finish > 0:
			b.add_delta("Positions gained", r.grid - finish)
		box.set_breakdown(b)
		boxes.add_child(box)
	card.add_padded(boxes, 6, 2)

	var mate := GameState.teammate_of(driver)
	if mate:
		card.add_section(tr("Against teammate %s") % mate.last_name)
		card.add_row(FactRow.new("Ahead in qualifying", tr("%d of %d") % [stats.quali_ahead, stats.head_to_head_rounds], "", true))
		card.add_row(FactRow.new("Ahead in the race", tr("%d of %d") % [stats.race_ahead, stats.head_to_head_rounds], "", true))
	return card


func _relationships_card() -> UICard:
	var card := UICard.new("Relationships")
	var mate := GameState.teammate_of(driver)
	if mate:
		_add_relationship(card, mate.full_name(), "Teammate", mate.id, true)
	var engineer := GameState.race_engineer_of(driver.id)
	if engineer:
		_add_relationship(card, engineer.full_name(), "Race engineer", engineer.id, false)
	if driver.team_id == GameState.player_team_id:
		_add_relationship(card, "You", "Team principal", GameState.PLAYER_ID, false)
	return card


func _add_relationship(card: UICard, person_name: String, role: String, other_id: StringName,
		open_profile: bool) -> void:
	var rel := GameState.relationship(driver.id, other_id)
	var label := DriverStatus.relationship_label(rel.value)
	var color := UIStyle.GOOD if rel.value >= 20 else (UIStyle.BAD if rel.value <= -20 else UIStyle.OK)
	var row := InfoRow.new(person_name, tr(role), label, color, true)
	var other: PersonData = GameState.drivers.get(other_id, GameState.staff.get(other_id))
	if other:
		row.set_leading_image(UIStyle.portrait(other, 20))
	row.set_breakdown(DriverStatus.relationship_breakdown(person_name, rel))
	if open_profile:
		row.make_clickable()
		row.clicked.connect(shell.open_driver.bind(other_id))
	card.add_row(row)


func _promises_card() -> UICard:
	var card := UICard.new("Promises")
	var list := GameState.promises_to(driver.id)
	if list.is_empty():
		card.add_padded(_muted("No promises made."))
	for p in list:
		var status: String = ["Open", "Kept", "Broken"][p.status]
		var color: Color = [UIStyle.WARN, UIStyle.GOOD, UIStyle.BAD][p.status]
		var sub := tr("Made %s") % p.made_on
		if p.status == PromiseData.Status.OPEN and p.deadline_round > 0:
			sub += " · " + tr("deadline round %d") % p.deadline_round
		var row := InfoRow.new(p.description, sub, status, color, true)
		var b := Breakdown.new(tr("Promise: %s") % tr(p.description)).add("Made", p.made_on).add("Status", status)
		if p.status == PromiseData.Status.OPEN:
			b.add_delta("Morale if broken", p.morale_penalty)
		row.set_breakdown(b)
		card.add_row(row)
	return card


## Development chart: the overall rating or one attribute, one value per season.
func _show_chart(property: StringName) -> void:
	_chart_attribute = property
	for key in _attribute_rows:
		_attribute_rows[key].set_selected(key == property)
	for child in _chart_slot.get_children():
		child.queue_free()

	var overall := property == &""
	var history: Array = driver.ability_history if overall else driver.attribute_history.get(property, [])
	var first_year := Calendar.year - history.size() + 1
	var card := UICard.new("Development", tr("%d–%d · scale 1–20") % [first_year, Calendar.year])
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not Knowledge.is_exact(driver):
		var unknown := Label.new()
		unknown.text = "History unknown – this person has not worked for you."
		unknown.theme_type_variation = &"MutedLabel"
		unknown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_padded(unknown, 8, 0)
		_chart_slot.add_child(card)
		return

	var header := HBoxContainer.new()
	var what := Label.new()
	what.text = tr("Overall rating") if overall else tr(DriverStatus.attribute_name(property))
	what.theme_type_variation = &"StrongLabel"
	what.add_theme_color_override("font_color", UIStyle.ACCENT)
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(what)
	if not overall:
		var reset := Button.new()
		reset.text = "Show overall"
		reset.theme_type_variation = &"FlatButton"
		reset.pressed.connect(_show_chart.bind(&""))
		header.add_child(reset)
	card.add_padded(header, 6, 0)

	var values: Array[float] = []
	var labels: Array[String] = []
	for i in history.size():
		# Overall keeps one decimal; attributes are whole numbers on the 1-20 scale.
		values.append(history[i] / 5.0 if overall else float(DriverAttributes.to_display(history[i])))
		labels.append(str(first_year + i))
	card.add_padded(Sparkline.new(values, labels, 120, 1 if overall else 0), 2, 0)

	var hint := Label.new()
	hint.text = "Value at the end of each season. Click any attribute to see its history."
	hint.theme_type_variation = &"SmallLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_padded(hint, 4, 0)
	_chart_slot.add_child(card)


func _muted(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	return label
