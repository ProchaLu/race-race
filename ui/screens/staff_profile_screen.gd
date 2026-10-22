## Staff profile, same "Columns" layout as the driver profile (decision 33):
## identity + rating, status strip, general / role attributes, traits and
## career, contract; then impact on the team, relationships, development.
extends UIScreen

var person: StaffData
var _chart_attribute: StringName = &""
var _attribute_rows := {}
var _chart_slot: VBoxContainer


func setup(args: Dictionary) -> void:
	person = GameState.staff[args.staff_id]
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
		_attribute_card("General", StaffRoles.GENERAL),
		_role_card(),
		_stack([_traits_card(), _career_card()]),
		_contract_card(),
	]))
	_chart_slot = VBoxContainer.new()
	page.add_child(_row([_impact_card(), _relationships_card(), _chart_slot], [1.3, 1.0, 1.0]))
	_show_chart(&"")


func screen_title() -> String:
	return "Staff profile"


func nav_section() -> StringName:
	return &"staff" if person.team_id == GameState.player_team_id else &"market"


func _row(children: Array, ratios: Array = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	for i in children.size():
		var child: Control = children[i]
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		child.size_flags_stretch_ratio = ratios[i] if i < ratios.size() else 1.0
		row.add_child(child)
	return row


func _stack(children: Array) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", UIStyle.GAP)
	for child in children:
		stack.add_child(child)
	(children.back() as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	return stack


# --- Top ---------------------------------------------------------------------

func _identity_card() -> Control:
	var team: TeamData = GameState.teams.get(person.team_id)
	var color := team.primary_color if team else UIStyle.LINE_STRONG
	var panel := PanelContainer.new()
	var style := UIStyle.box(UIStyle.PANEL, UIStyle.LINE, 1, 14, 8)
	style.border_width_left = 5
	style.border_color = color
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1))
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var portrait := TextureRect.new()
	portrait.texture = UIStyle.portrait(person, 90)
	frame.add_child(portrait)
	row.add_child(frame)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var role_line := tr(StaffRoles.name_of(person.role))
	var driver: DriverData = GameState.drivers.get(person.assigned_driver_id)
	if driver:
		role_line += " · " + driver.full_name()
	var role := Label.new()
	role.text = role_line
	role.uppercase = true
	role.theme_type_variation = &"SectionLabel"
	role.add_theme_font_size_override("font_size", 16)
	role.add_theme_color_override("font_color", UIStyle.ACCENT)
	text.add_child(role)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	var first := Label.new()
	first.text = person.first_name
	first.uppercase = true
	first.theme_type_variation = &"SectionLabel"
	first.add_theme_font_size_override("font_size", 18)
	first.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(first)
	var last := Label.new()
	last.text = person.last_name
	last.uppercase = true
	last.theme_type_variation = &"NameLabel"
	name_row.add_child(last)
	text.add_child(name_row)

	var meta := HFlowContainer.new()
	meta.add_theme_constant_override("h_separation", 26)
	_meta_pair(meta, "Nationality", Countries.name_of(person.nationality))
	_meta_pair(meta, "Age", str(person.age(Calendar.year)))
	_meta_pair(meta, "Team", team.name if team else tr("Free agent"))
	_meta_pair(meta, "Department", tr(StaffRoles.department_of(person.role)))
	if not person.career_history.is_empty():
		_meta_pair(meta, "In F1 since", str(person.career_history[0].from))
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
	var card := UICard.new("Rating", tr(Knowledge.label(person)))
	card.add_row(_star_row("Current ability", Knowledge.star_range(person, &"overall", person.overall())))
	card.add_row(_star_row("Potential", Knowledge.star_range(person, &"potential", person.potential)))
	return card


func _star_row(label: String, stars: Vector2) -> HoverRow:
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
	return row


func _status_strip() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Card"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	var tiles: Array[StatusTile] = []
	tiles.append(StatusTile.new("Morale", DriverStatus.level_label(person.morale), UIStyle.meter_color(person.morale), person.morale))
	tiles.append(StatusTile.new("Job satisfaction", "%d %%" % person.job_satisfaction,
		UIStyle.meter_color(person.job_satisfaction), person.job_satisfaction))
	var load_label := "High" if person.workload >= 70 else ("Normal" if person.workload >= 40 else "Low")
	tiles.append(StatusTile.new("Workload", load_label, UIStyle.WARN if person.workload >= 70 else UIStyle.OK, person.workload))
	var driver: DriverData = GameState.drivers.get(person.assigned_driver_id)
	if driver:
		var rel: int = GameState.relationship(person.id, driver.id).value
		tiles.append(StatusTile.new("Chemistry with driver", DriverStatus.relationship_label(rel),
			UIStyle.meter_color(50 + rel / 2.0), 50 + rel / 2.0))
	var interest := StaffImpact.rival_interest(person)
	tiles.append(StatusTile.new("Interest from others", tr("%d teams") % interest if interest > 0 else tr("None"),
		UIStyle.WARN if interest > 0 else UIStyle.GOOD))
	if not Knowledge.is_exact(person):
		tiles.append(StatusTile.new("Known", "%d %%" % Knowledge.level(person), UIStyle.WARN, Knowledge.level(person)))
	for i in tiles.size():
		if i > 0:
			row.add_child(VSeparator.new())
		row.add_child(tiles[i])
	return panel


# --- Attributes --------------------------------------------------------------

func _attribute_card(title: String, group: Array) -> UICard:
	var card := UICard.new(title, "Scale 1–20")
	for entry in group:
		card.add_row(_attribute_row(entry))
	return card


func _role_card() -> UICard:
	var card := UICard.new(StaffRoles.name_of(person.role), "Role attributes")
	for entry in StaffRoles.attributes_of(person.role):
		card.add_row(_attribute_row(entry))
	card.add_section("Personality")
	for entry in StaffRoles.PERSONALITY:
		card.add_row(_attribute_row(entry))
	return card


func _attribute_row(entry: Array) -> AttributeRow:
	var property: StringName = entry[0]
	var internal := person.attribute(property)
	var value := DriverAttributes.to_display(internal)
	var row := AttributeRow.new(entry[1], value, 0, Knowledge.display_range(person, property, internal))
	var b := Breakdown.new("%s %d · %s" % [tr(entry[1]), value, tr(DriverAttributes.band_name(value))], entry[2])
	if Knowledge.is_exact(person):
		b.add("Exact value", "%d / 100" % internal)
	else:
		b.note = tr(entry[2]) + " " + tr("Only an estimate: your team does not know this person well.")
	row.set_breakdown(b)
	row.make_clickable()
	row.clicked.connect(func(): _show_chart(&"" if property == _chart_attribute else property))
	_attribute_rows[property] = row
	return row


func _traits_card() -> UICard:
	var card := UICard.new("Traits", tr("%d known") % person.traits.size())
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for trait_id in person.traits:
		list.add_child(TraitRow.new(trait_id))
	if person.traits.is_empty():
		var none := Label.new()
		none.text = "No special traits known."
		none.theme_type_variation = &"MutedLabel"
		list.add_child(none)
	card.add_padded(list, 4, 0)
	return card


func _career_card() -> UICard:
	var card := UICard.new("Career")
	for job in person.career_history:
		card.add_row(FactRow.new("%d–%d" % [job.from, job.to], "%s · %s" % [job.team, tr(job.role)]))
	var team: TeamData = GameState.teams.get(person.team_id)
	if team:
		var c := GameState.contract_of(person.id)
		card.add_row(FactRow.new("%d–" % (c.start_year if c else Calendar.year), "%s · %s" % [team.name, tr(StaffRoles.name_of(person.role))], "", false, UIStyle.ACCENT))
	return card


func _contract_card() -> UICard:
	var card := UICard.new("Contract")
	var c := GameState.contract_of(person.id)
	if c:
		card.add_row(FactRow.new("Salary", tr("%s per year") % UIStyle.money(c.salary), "", true))
		card.add_row(FactRow.new("Contract ends", tr("End of %d") % c.end_year))
		card.add_row(FactRow.new("Notice period", tr("%d months") % c.notice_months))
		card.add_row(FactRow.new("Release clause", UIStyle.money(c.release_clause) if c.release_clause > 0 else tr("None"), "", true))
		if person.team_id == GameState.player_team_id:
			card.add_row(FactRow.new("Severance if released", UIStyle.money(ContractLogic.severance(person)), "", true, UIStyle.BAD))
	else:
		card.add_row(FactRow.new("Status", tr("Free agent"), "", false, UIStyle.GOOD))
		card.add_row(FactRow.new("Salary demand", tr("about %s per year") % UIStyle.money(ContractLogic.salary_demand(person)), "", true))
	var agent := ContractLogic.agent_of(person)
	if agent:
		card.add_row(FactRow.new("Agent", agent.full_name(), tr(AgentData.style_name(agent.style))))
	card.add_padded(ContractActions.new(person, shell), 12, 0)
	return card


# --- Bottom ------------------------------------------------------------------

func _impact_card() -> UICard:
	var card := UICard.new("Impact on the team", "What this person brings")
	for r in StaffImpact.rows(person):
		var row := InfoRow.new(r[0], r[3], r[1], UIStyle.tone_color(r[2]), false)
		card.add_row(row)
	return card


func _relationships_card() -> UICard:
	var card := UICard.new("Relationships")
	var driver: DriverData = GameState.drivers.get(person.assigned_driver_id)
	if driver:
		_relationship(card, driver, "Driver")
	for colleague in GameState.staff_of_team(person.team_id):
		if colleague != person and colleague.role in [StaffData.Role.TECHNICAL_DIRECTOR, StaffData.Role.STRATEGY_CHIEF] \
				and card.body.get_child_count() < 4:
			_relationship(card, colleague, StaffRoles.name_of(colleague.role))
	if person.team_id == GameState.player_team_id:
		var rel := GameState.relationship(person.id, GameState.PLAYER_ID)
		var row := InfoRow.new("You", tr("Team principal"), tr(DriverStatus.relationship_label(rel.value)),
			UIStyle.GOOD if rel.value >= 20 else (UIStyle.BAD if rel.value <= -20 else UIStyle.OK), true)
		row.set_breakdown(DriverStatus.relationship_breakdown("You", rel))
		card.add_row(row)
	return card


func _relationship(card: UICard, other: PersonData, role: String) -> void:
	var rel := GameState.relationship(person.id, other.id)
	var row := InfoRow.new(other.full_name(), tr(role), tr(DriverStatus.relationship_label(rel.value)),
		UIStyle.GOOD if rel.value >= 20 else (UIStyle.BAD if rel.value <= -20 else UIStyle.OK), true)
	row.set_leading_image(UIStyle.portrait(other, 20))
	row.set_breakdown(DriverStatus.relationship_breakdown(other.full_name(), rel))
	row.make_clickable()
	if other is DriverData:
		row.clicked.connect(shell.open_driver.bind(other.id))
	else:
		row.clicked.connect(shell.open_staff.bind(other.id))
	card.add_row(row)


func _show_chart(property: StringName) -> void:
	_chart_attribute = property
	for key in _attribute_rows:
		_attribute_rows[key].set_selected(key == property)
	for child in _chart_slot.get_children():
		child.queue_free()
	var overall := property == &""
	var history: Array = person.ability_history if overall else person.attribute_history.get(property, [])
	var first_year := Calendar.year - history.size() + 1
	var card := UICard.new("Development", tr("%d–%d · scale 1–20") % [first_year, Calendar.year])
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var what := Label.new()
	what.text = tr("Overall rating") if overall else tr(_attribute_label(property))
	what.theme_type_variation = &"StrongLabel"
	what.add_theme_color_override("font_color", UIStyle.ACCENT)
	card.add_padded(what, 6, 0)
	if not Knowledge.is_exact(person):
		var unknown := Label.new()
		unknown.text = "History unknown – this person has not worked for you."
		unknown.theme_type_variation = &"MutedLabel"
		unknown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_padded(unknown, 8, 0)
	else:
		var values: Array[float] = []
		var labels: Array[String] = []
		for i in history.size():
			values.append(history[i] / 5.0 if overall else float(DriverAttributes.to_display(history[i])))
			labels.append(str(first_year + i))
		card.add_padded(Sparkline.new(values, labels, 120, 1 if overall else 0), 2, 0)
		var hint := Label.new()
		hint.text = "Value at the end of each season. Click any attribute to see its history."
		hint.theme_type_variation = &"SmallLabel"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_padded(hint, 4, 0)
	_chart_slot.add_child(card)


func _attribute_label(property: StringName) -> String:
	for group in [StaffRoles.GENERAL, StaffRoles.PERSONALITY, StaffRoles.attributes_of(person.role)]:
		for entry in group:
			if entry[0] == property:
				return entry[1]
	return str(property)
