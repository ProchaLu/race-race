## Transfer market: free agents and people with release clauses, filters,
## shortlist and a preview of the selected person (decision 39: unknown
## values are shown as range bars).
extends UIScreen

enum Group { ALL, DRIVERS, STAFF, SHORTLIST }
enum Status { AVAILABLE, FREE_ONLY, EVERYONE }
enum Col { STAR, NAME, POSITION, AGE, NATIONALITY, ABILITY, POTENTIAL, SALARY, STATUS, KNOWN }
const COLUMNS := [
	["", 34, false], ["Name", 190, true], ["Position", 180, false], ["Age", 50, false],
	["Nationality", 125, false], ["Ability", 105, false], ["Potential", 105, false],
	["Salary demand", 115, false], ["Status", 165, false], ["Known", 75, false],
]
const AGE_FILTERS := [["Any age", 0, 99], ["Under 21", 0, 20], ["21–30", 21, 30], ["Over 30", 31, 99]]

var _group := Group.ALL
var _role_filter := -1  # -1 any, -2 drivers only, else StaffData.Role
var _status := Status.AVAILABLE
var _age := 0
var _search := ""
var _sort := Col.ABILITY
var _descending := true
var _selected: StringName

var _tree: Tree
var _role_select: OptionButton
var _count_label: Label
var _preview_slot: VBoxContainer


func setup(args: Dictionary) -> void:
	_selected = args.get("selected", &"")
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	left.add_child(_filter_bar())
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.columns = COLUMNS.size()
	_tree.column_titles_visible = true
	_tree.select_mode = Tree.SELECT_ROW
	_tree.auto_tooltip = false
	for i in COLUMNS.size():
		_tree.set_column_title(i, COLUMNS[i][0])
		_tree.set_column_custom_minimum_width(i, COLUMNS[i][1])
		_tree.set_column_expand(i, COLUMNS[i][2])
		_tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	_tree.item_selected.connect(_on_selected)
	_tree.item_activated.connect(_open_profile)
	_tree.button_clicked.connect(_on_star_clicked)
	_tree.column_title_clicked.connect(_on_title_clicked)
	left.add_child(_tree)
	row.add_child(left)

	_preview_slot = VBoxContainer.new()
	_preview_slot.custom_minimum_size.x = 380
	row.add_child(_preview_slot)
	_rebuild()


func screen_title() -> String:
	return "Transfer market"


func nav_section() -> StringName:
	return &"market"


# --- Filters -----------------------------------------------------------------

func _filter_bar() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.LINE, 1, 12, 10))
	var bar := HFlowContainer.new()
	bar.add_theme_constant_override("h_separation", 10)
	bar.add_theme_constant_override("v_separation", 8)
	panel.add_child(bar)

	var group := ButtonGroup.new()
	group.allow_unpress = false
	for g in [[Group.ALL, "All"], [Group.DRIVERS, "Drivers"], [Group.STAFF, "Staff"], [Group.SHORTLIST, "★ Shortlist"]]:
		var b := Button.new()
		b.text = g[1]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = g[0] == _group
		var value: Group = g[0]
		b.pressed.connect(func():
			_group = value
			_rebuild())
		bar.add_child(b)

	_role_select = OptionButton.new()
	_role_select.add_item("Any role")
	_role_select.set_item_metadata(0, -1)
	for role in StaffData.Role.values():
		_role_select.add_item(StaffRoles.name_of(role))
		_role_select.set_item_metadata(_role_select.item_count - 1, role)
	_role_select.item_selected.connect(func(i):
		_role_filter = _role_select.get_item_metadata(i)
		_rebuild())
	bar.add_child(_role_select)

	var status := OptionButton.new()
	for s in ["Free agents + release clauses", "Free agents only", "Everyone"]:
		status.add_item(s)
	status.item_selected.connect(func(i):
		_status = i
		_rebuild())
	bar.add_child(status)

	var age := OptionButton.new()
	for a in AGE_FILTERS:
		age.add_item(a[0])
	age.item_selected.connect(func(i):
		_age = i
		_rebuild())
	bar.add_child(age)

	var search := LineEdit.new()
	search.placeholder_text = tr("Search name")
	search.custom_minimum_size.x = 200
	search.text_changed.connect(func(t):
		_search = t.to_lower()
		_rebuild())
	bar.add_child(search)

	_count_label = Label.new()
	_count_label.theme_type_variation = &"MutedLabel"
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_count_label)
	return panel


func _matches(p: PersonData) -> bool:
	if p.team_id == GameState.player_team_id and p.team_id != &"":
		return false
	var is_driver := p is DriverData
	match _group:
		Group.DRIVERS:
			if not is_driver: return false
		Group.STAFF:
			if is_driver: return false
		Group.SHORTLIST:
			if not GameState.shortlist.has(p.id): return false
	if _role_filter >= 0 and (is_driver or (p as StaffData).role != _role_filter):
		return false
	var contract := GameState.contract_of(p.id)
	if _group != Group.SHORTLIST:
		match _status:
			Status.AVAILABLE:
				if p.team_id != &"" and not (contract and contract.release_clause > 0): return false
			Status.FREE_ONLY:
				if p.team_id != &"": return false
	var age := p.age(Calendar.year)
	if age < AGE_FILTERS[_age][1] or age > AGE_FILTERS[_age][2]:
		return false
	if _search != "" and not p.full_name().to_lower().contains(_search):
		return false
	return true


func _people() -> Array[PersonData]:
	var list: Array[PersonData] = []
	for d in GameState.drivers.values():
		if _matches(d):
			list.append(d)
	for s in GameState.staff.values():
		if _matches(s):
			list.append(s)
	list.sort_custom(func(a, b):
		var ka = _sort_key(a)
		var kb = _sort_key(b)
		return ka > kb if _descending else ka < kb)
	return list


func _sort_key(p: PersonData) -> Variant:
	match _sort:
		Col.NAME: return p.last_name
		Col.POSITION: return _position(p)
		Col.AGE: return p.age(Calendar.year)
		Col.NATIONALITY: return Countries.name_of(p.nationality)
		Col.POTENTIAL: return Knowledge.star_range(p, &"potential", p.get("potential")).y
		Col.SALARY: return ContractLogic.salary_demand(p)
		Col.KNOWN: return Knowledge.level(p)
		Col.STATUS: return p.team_id
	return Knowledge.star_range(p, &"overall", p.overall()).y


# --- Table -------------------------------------------------------------------

func _rebuild() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var people := _people()
	var selected_item: TreeItem = null
	for p in people:
		var item := _add_row(root, p)
		if p.id == _selected:
			selected_item = item
	_count_label.text = tr("%d people · %d on your shortlist") % [people.size(), GameState.shortlist.size()]
	if selected_item:
		selected_item.select(0)
	elif not people.is_empty():
		_selected = people[0].id
		root.get_child(0).select(0)
	else:
		_show_preview(null)


func _add_row(root: TreeItem, p: PersonData) -> TreeItem:
	var item := _tree.create_item(root)
	item.set_metadata(0, p.id)
	item.add_button(Col.STAR, StarRating.single(GameState.shortlist.has(p.id)), 0, false, tr("Shortlist"))
	item.set_text(Col.NAME, p.full_name())
	item.set_icon(Col.NAME, UIStyle.portrait(p, 25))
	item.set_text(Col.POSITION, _position(p))
	item.set_custom_color(Col.POSITION, UIStyle.MUTED)
	item.set_text(Col.AGE, str(p.age(Calendar.year)))
	item.set_text(Col.NATIONALITY, Countries.name_of(p.nationality))
	_stars(item, Col.ABILITY, Knowledge.star_range(p, &"overall", p.overall()))
	_stars(item, Col.POTENTIAL, Knowledge.star_range(p, &"potential", p.get("potential")))
	item.set_text(Col.SALARY, UIStyle.money(ContractLogic.salary_demand(p)))
	var status := _status_text(p)
	item.set_text(Col.STATUS, status[0])
	item.set_custom_color(Col.STATUS, status[1])
	item.set_text(Col.KNOWN, "%d %%" % Knowledge.level(p))
	item.set_custom_color(Col.KNOWN, UIStyle.meter_color(Knowledge.level(p)))
	for col in [Col.AGE, Col.SALARY, Col.KNOWN]:
		item.set_custom_font(col, UIStyle.font(&"tabular"))
	return item


func _stars(item: TreeItem, col: int, stars: Vector2) -> void:
	var tex := StarRating.texture_range(stars.x, stars.y)
	item.set_icon(col, tex)
	item.set_icon_max_width(col, tex.get_width())


func _position(p: PersonData) -> String:
	if p is DriverData:
		var d := p as DriverData
		var where := ""
		if d.team_id != &"":
			where = GameState.teams[d.team_id].short_name
		elif d.series_id == &"f2":
			where = "F2"
		elif d.series_id == &"f3":
			where = "F3"
		else:
			where = tr("ex-F1")
		return "%s · %s" % [tr("Driver"), where]
	var s := p as StaffData
	var team: TeamData = GameState.teams.get(s.team_id)
	return s.role_label() + (" · " + team.short_name if team else "")


## [text, colour]
func _status_text(p: PersonData) -> Array:
	var pending := GameState.pending_signing_of(p.id)
	if not pending.is_empty():
		return [tr("Signs on %s") % Calendar.format_date(pending.sign_day), UIStyle.ACCENT]
	if p.team_id == &"":
		return [tr("Free agent"), UIStyle.GOOD]
	var c := GameState.contract_of(p.id)
	if c and c.release_clause > 0:
		return [tr("Clause %s") % UIStyle.money(c.release_clause), UIStyle.ACCENT]
	return [tr("Under contract · %d") % c.end_year if c else tr("Under contract"), UIStyle.MUTED]


# --- Preview -----------------------------------------------------------------

func _show_preview(p: PersonData) -> void:
	for child in _preview_slot.get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_preview_slot.add_child(scroll)
	var card := UICard.new("Preview", tr(Knowledge.label(p)) if p else "")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(card)
	if not p:
		var none := Label.new()
		none.text = "Nobody matches these filters."
		none.theme_type_variation = &"MutedLabel"
		card.add_padded(none, 8, 0)
		return

	card.add_padded(_preview_head(p), 10, 6)
	card.add_row(_star_row("Current ability", Knowledge.star_range(p, &"overall", p.overall())))
	card.add_row(_star_row("Potential", Knowledge.star_range(p, &"potential", p.get("potential"))))
	card.add_row(_knowledge_row(p))

	card.add_section("Key attributes")
	for entry in _key_attributes(p):
		var internal: int = (p as StaffData).attribute(entry[0]) if p is StaffData else p.get(entry[0])
		card.add_row(AttributeRow.new(entry[1], DriverAttributes.to_display(internal), 0,
			Knowledge.display_range(p, entry[0], internal)))

	card.add_section("Traits")
	var traits: Array = p.get("traits")
	if Knowledge.level(p) < 50:
		card.add_padded(_muted("Unknown until the person is scouted."), 4, 0)
	elif traits.is_empty():
		card.add_padded(_muted("No special traits known."), 4, 0)
	else:
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 6)
		for t in traits:
			list.add_child(TraitRow.new(t))
		card.add_padded(list, 4, 0)

	card.add_section("Contract")
	var team: TeamData = GameState.teams.get(p.team_id)
	var contract := GameState.contract_of(p.id)
	card.add_row(FactRow.new("Team", team.name if team else tr("Free agent"), "", false,
		UIStyle.TEXT if team else UIStyle.GOOD))
	if contract:
		card.add_row(FactRow.new("Contract ends", tr("End of %d") % contract.end_year))
		card.add_row(FactRow.new("Release clause", UIStyle.money(contract.release_clause) if contract.release_clause > 0 else tr("None"), "", true))
	card.add_row(FactRow.new("Salary demand", tr("about %s per year") % UIStyle.money(ContractLogic.salary_demand(p)), "", true))
	var agent := ContractLogic.agent_of(p)
	if agent:
		card.add_row(FactRow.new("Agent", agent.full_name(), tr(AgentData.style_name(agent.style))))

	card.add_padded(_preview_buttons(p), 14, 4)


func _preview_head(p: PersonData) -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var picture := TextureRect.new()
	picture.texture = UIStyle.portrait(p, 80)
	frame.add_child(picture)
	head.add_child(frame)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = p.full_name()
	name_label.uppercase = true
	name_label.theme_type_variation = &"HeadingLabel"
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(name_label)
	var info := Label.new()
	info.text = "%s · %d · %s" % [_position(p), p.age(Calendar.year), Countries.name_of(p.nationality)]
	info.theme_type_variation = &"MutedLabel"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(info)
	var status := _status_text(p)
	var status_label := Label.new()
	status_label.text = status[0]
	status_label.theme_type_variation = &"StrongLabel"
	status_label.add_theme_color_override("font_color", status[1])
	text.add_child(status_label)
	head.add_child(text)
	return head


## How well the person is known and how long scouting would take.
func _knowledge_row(p: PersonData) -> FactRow:
	var k := Knowledge.level(p)
	var weeks := Knowledge.weeks_to_scout(p)
	var sub := tr("Values are exact") if weeks == 0 else tr("Fully scouted in about %d weeks") % weeks
	var row := FactRow.new("Known", "%d %%" % k, sub, true, UIStyle.meter_color(k))
	var scout := Knowledge.chief_scout()
	var b := Breakdown.new(tr("Known: %d %%") % k,
		"Scouting assignments arrive in a later round. The estimate already uses your chief scout.")
	if scout:
		b.add("Chief scout", scout.full_name())
		b.add("Judging ability", str(DriverAttributes.to_display(scout.attribute(&"judging_ability"))))
		b.add("Judging potential", str(DriverAttributes.to_display(scout.attribute(&"judging_potential"))))
	b.add("Weeks until exact", str(weeks))
	row.set_breakdown(b)
	return row


## Two equal buttons side by side, the call to action below at full width.
func _preview_buttons(p: PersonData) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var profile := Button.new()
	profile.text = "Open profile"
	profile.icon = UIStyle.icon("user")
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.pressed.connect(_open_profile)
	row.add_child(profile)
	var star := Button.new()
	star.text = "★ On shortlist" if GameState.shortlist.has(p.id) else "☆ Add to shortlist"
	star.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star.pressed.connect(func():
		GameState.toggle_shortlist(p.id)
		_rebuild())
	row.add_child(star)
	column.add_child(row)
	column.add_child(ContractActions.new(p, shell, true))
	return column


func _key_attributes(p: PersonData) -> Array:
	if p is DriverData:
		var d := DriverAttributes.DRIVING
		return [d[0], d[1], d[2], d[3], d[4], d[6], d[9], d[10], DriverAttributes.MENTAL[0], DriverAttributes.MENTAL[5]]
	return StaffRoles.attributes_of((p as StaffData).role) + [StaffRoles.GENERAL[0], StaffRoles.GENERAL[1],
		StaffRoles.GENERAL[3], StaffRoles.PERSONALITY[1]]


func _muted(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"MutedLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _star_row(label: String, stars: Vector2) -> HoverRow:
	var row := HoverRow.new()
	var line := HBoxContainer.new()
	var text := Label.new()
	text.text = label
	text.theme_type_variation = &"MutedLabel"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	var image := TextureRect.new()
	image.texture = StarRating.texture_range(stars.x, stars.y, 18)
	line.add_child(image)
	row.add_child(line)
	return row


# --- Events ------------------------------------------------------------------

func _on_selected() -> void:
	var item := _tree.get_selected()
	if not item:
		return
	_selected = item.get_metadata(0)
	shell.update_args({"selected": _selected})
	_show_preview(GameState.find_person(_selected))


func _open_profile() -> void:
	var p := GameState.find_person(_selected)
	if p is DriverData:
		shell.open_driver(p.id)
	elif p:
		shell.open_staff(p.id)


func _on_star_clicked(item: TreeItem, _column: int, _id: int, _mouse_button: int) -> void:
	GameState.toggle_shortlist(item.get_metadata(0))
	item.set_button(Col.STAR, 0, StarRating.single(GameState.shortlist.has(item.get_metadata(0))))
	_count_label.text = tr("%d people · %d on your shortlist") % [_tree.get_root().get_child_count(), GameState.shortlist.size()]


func _on_title_clicked(column: int, _mouse_button: int) -> void:
	if column == Col.STAR:
		return
	if column == _sort:
		_descending = not _descending
	else:
		_sort = column as Col
		_descending = column not in [Col.NAME, Col.POSITION, Col.NATIONALITY, Col.STATUS]
	_rebuild()
