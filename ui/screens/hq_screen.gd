## Headquarters (docs/hq_screen_design.md, docs/r4_review.md): status strip,
## the campus with every building and building site, and an inspector with
## the selected building (current → next level, cost, time, upkeep) or the
## list of all buildings. The action bar under the inspector is always
## visible; construction is confirmed in place.
extends UIScreen

enum Tab { BUILDING, LIST }

## Remembered while the game runs.
static var _show_names := false
static var _animate := true

var _team: TeamData
var _campus: HqCampus
var _selected: StringName = &"design"
var _tab: Tab = Tab.BUILDING
var _confirming := false
var _status: HBoxContainer
var _tabs: Segmented
var _details: VBoxContainer
var _actions: PanelContainer
var _refresh_pending := false


func setup(args: Dictionary) -> void:
	_team = GameState.player_team()
	Facilities.level(_team, &"design")
	_selected = StringName(str(args.get("facility", "design")))
	if not Facilities.CATALOG.has(_selected):
		_selected = &"design"
	_tab = args.get("hq_tab", Tab.BUILDING)
	EventBus.facilities_changed.connect(_on_changed)
	EventBus.budget_changed.connect(func(team_id, _budget): _on_changed(team_id))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(column)
	_status = HBoxContainer.new()
	_status.add_theme_constant_override("separation", 0)
	column.add_child(_status)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UIStyle.GAP)
	column.add_child(body)
	body.add_child(_campus_card())
	body.add_child(_inspector())
	_refresh()


func screen_title() -> String:
	return "Headquarters"


func nav_section() -> StringName:
	return &"hq"


# --- Layout --------------------------------------------------------------------

func _campus_card() -> Control:
	var card := UICard.new(tr("Campus · %s") % _team.name, "click a building or a building site")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var names := CheckButton.new()
	names.text = "Show names"
	names.button_pressed = _show_names
	names.toggled.connect(func(on):
		_show_names = on
		_campus.show_names = on
		_campus.queue_redraw())
	names.size_flags_horizontal = Control.SIZE_SHRINK_END
	var motion := CheckButton.new()
	motion.text = "Animation"
	motion.button_pressed = _animate
	motion.tooltip_text = "Pit-crew drill, people and transporters on the campus."
	motion.toggled.connect(func(on):
		_animate = on
		_campus.animate = on
		_campus.queue_redraw())
	var tools := HBoxContainer.new()
	var hint := _small(tr("Hover a building for its name and level."))
	tools.add_child(hint)
	tools.add_child(motion)
	tools.add_child(names)
	card.add_padded(tools, 0, 0)
	_campus = HqCampus.new()
	_campus.show_names = _show_names
	_campus.animate = _animate
	_campus.facility_selected.connect(_select)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1, 0, 0))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(_campus)
	card.add_padded(frame, 2, 6)
	frame.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return card


func _inspector() -> Control:
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 400
	side.add_theme_constant_override("separation", 8)
	_tabs = Segmented.new([tr("Building"), tr("All buildings")], _tab)
	_tabs.changed.connect(func(i):
		_tab = i as Tab
		_confirming = false
		shell.update_args({"hq_tab": i})
		_refresh())
	side.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(scroll)
	_details = VBoxContainer.new()
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_details)
	_actions = PanelContainer.new()
	_actions.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.LINE_STRONG, 1, 14, 10))
	side.add_child(_actions)
	return side


func _select(id: StringName) -> void:
	_selected = id
	_tab = Tab.BUILDING
	_confirming = false
	shell.update_args({"facility": id, "hq_tab": Tab.BUILDING})
	_refresh()


func _on_changed(team_id: StringName) -> void:
	if team_id == _team.id and is_inside_tree() and not _refresh_pending:
		_refresh_pending = true
		_refresh.call_deferred()


## Updates everything in place (no screen rebuild while days pass).
func _refresh() -> void:
	_refresh_pending = false
	_campus.configure(_team)
	_campus.select_facility(_selected)
	_tabs.buttons[_tab].set_pressed_no_signal(true)
	_build_status()
	for child in _details.get_children():
		_details.remove_child(child)
		child.queue_free()
	if _tab == Tab.LIST:
		_details.add_child(_list_card())
	else:
		_build_building()
	_build_actions()


# --- Status strip --------------------------------------------------------------

func _build_status() -> void:
	for child in _status.get_children():
		child.queue_free()
	var built := 0
	for id in Facilities.CATALOG:
		if Facilities.level(_team, id) > 0:
			built += 1
	var t1 := StatusTile.new("In operation", "%d / %d" % [built, Facilities.CATALOG.size()], UIStyle.TEXT)
	_sub(t1, tr("buildings on the campus"))
	_status.add_child(t1)
	var building := tr("None")
	var crews := Facilities.construction_crews(_team)
	var sub := tr("one construction crew") if crews == 1 else tr("%d construction crews") % crews
	if crews == 1:
		sub += " · " + tr("a second from %d campus levels") % Facilities.SECOND_CREW_LEVELS
	var names := PackedStringArray()
	for id in _team.facility_projects:
		var project: Dictionary = _team.facility_projects[id]
		names.append("%s · %d %%" % [tr(Facilities.name_of(id)), roundi(_progress(project) * 100)])
		sub = tr("level %d · ready %s") % [project.target, _completion_date(project.remaining)]
	if not names.is_empty():
		building = " / ".join(names)
	var t2 := StatusTile.new("Construction", building, UIStyle.ACCENT if not _team.facility_projects.is_empty() else UIStyle.MUTED)
	_sub(t2, sub)
	_status.add_child(t2)
	var t3 := StatusTile.new("Upkeep", tr("%s / month") % UIStyle.money(Facilities.upkeep_per_month(_team)), UIStyle.TEXT)
	_sub(t3, tr("paid with the salaries"))
	_status.add_child(t3)
	var teams: int = GameState.series[_team.series_id].team_ids.size()
	var rank := Facilities.campus_rank(_team)
	var t4 := StatusTile.new("Campus rank", "P%d" % rank, UIStyle.GOOD if rank <= 3 else (UIStyle.WARN if rank > teams - 3 else UIStyle.TEXT))
	_sub(t4, tr("of %d teams · invested this season %s") % [teams, UIStyle.money(GameState.hq_spending.get(_team.id, 0))])
	_status.add_child(t4)


# --- Building tab --------------------------------------------------------------

func _build_building() -> void:
	var id := _selected
	var lv := Facilities.level(_team, id)
	var status := tr("Level %d of 5") % lv if lv > 0 else tr("Building site")
	var head := UICard.new(Facilities.name_of(id), status)
	head.add_padded(_small(tr(Facilities.purpose_of(id))), 6, 2)
	var pips := Label.new()
	pips.text = _pips(lv)
	pips.add_theme_color_override("font_color", UIStyle.ACCENT)
	pips.add_theme_font_size_override("font_size", 18)
	head.add_padded(pips, 2, 6)
	if Facilities.locked_until(id) != "":
		head.add_padded(_note(tr("This building feeds a system that comes with %s. Until then it cannot be built or upgraded.")
			% Facilities.locked_until(id)), 2, 6)
	_details.add_child(head)

	if _team.facility_projects.has(id):
		_details.add_child(_project_card(id, lv))
	elif lv >= 5:
		var card := UICard.new("Fully upgraded", "level 5 – the best there is")
		card.add_padded(_pictures(id, lv, lv), 6, 4)
		_effect_rows(card, id, lv, lv)
		_details.add_child(card)
	else:
		var offer := Facilities.quote(_team, id)
		var title := tr("Upgrade to level %d") % offer.target if lv > 0 else tr("Build at level 1")
		var card := UICard.new(title, "what changes")
		card.add_padded(_pictures(id, lv, offer.target), 6, 4)
		_effect_rows(card, id, lv, offer.target)
		card.add_section("Construction")
		card.add_row(FactRow.new("Cost", UIStyle.money(offer.cost), "paid when construction starts", true))
		card.add_row(FactRow.new("Construction time", tr("%d days") % offer.duration, "", true))
		card.add_row(FactRow.new("Ready", _completion_date(offer.duration), "", true))
		card.add_row(FactRow.new("Upkeep", tr("+%s / month") % UIStyle.money(offer.upkeep), "", true, UIStyle.WARN))
		_details.add_child(card)


func _project_card(id: StringName, lv: int) -> UICard:
	var project: Dictionary = _team.facility_projects[id]
	var card := UICard.new(tr("Under construction · level %d") % project.target, "")
	card.add_padded(_pictures(id, lv, project.target), 6, 4)
	var progress := _progress(project)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var meter := Meter.new(progress * 100.0, UIStyle.ACCENT, 6)
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meter)
	var pct := Label.new()
	pct.text = "%d %%" % roundi(progress * 100)
	pct.theme_type_variation = &"NumberLabel"
	row.add_child(pct)
	card.add_padded(row, 4, 4)
	card.add_row(FactRow.new("Days remaining", str(project.remaining), "", true))
	card.add_row(FactRow.new("Ready", _completion_date(project.remaining), "", true))
	card.add_row(FactRow.new("Paid", UIStyle.money(project.cost), "", true))
	_effect_rows(card, id, lv, project.target)
	card.add_padded(_small("The current level keeps working during construction." if lv > 0
		else "The facility opens when construction is complete."), 4, 4)
	return card


## Current and next appearance side by side.
func _pictures(id: StringName, from_level: int, to_level: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if from_level != to_level:
		row.add_child(_picture(id, from_level))
		var arrow := Label.new()
		arrow.text = "→"
		arrow.theme_type_variation = &"HeadingLabel"
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(arrow)
	row.add_child(_picture(id, to_level))
	return row


func _picture(id: StringName, at_level: int) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE, 1, 6, 6))
	var picture := TextureRect.new()
	picture.custom_minimum_size = Vector2(150, 104)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if at_level > 0:
		picture.texture = _campus.preview(id, at_level)
	frame.add_child(picture)
	column.add_child(frame)
	var caption := _tiny(tr("Level %d") % at_level if at_level > 0 else tr("Building site"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	return column


## "Wind tunnel capacity   ×0.96 → ×1.08   +12 %"
func _effect_rows(card: UICard, id: StringName, from_level: int, to_level: int) -> void:
	var lines_to := Facilities.effect_lines(_team, id, to_level)
	if lines_to.is_empty():
		return
	card.add_section("Effect")
	var lines_from := Facilities.effect_lines(_team, id, from_level)
	for i in lines_to.size():
		var line: Array = lines_to[i]
		var before: float = lines_from[i][1]
		var after: float = line[1]
		var better: int = line[3] if line.size() > 3 else 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var key := Label.new()
		key.text = tr(line[0])
		key.theme_type_variation = &"MutedLabel"
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(key)
		var value := Label.new()
		value.theme_type_variation = &"NumberLabel"
		var format: String = line[2]
		value.text = format % after if from_level == to_level else "%s → %s" % [format % before, format % after]
		row.add_child(value)
		if from_level != to_level and not is_equal_approx(before, after):
			var delta := Label.new()
			delta.theme_type_variation = &"NumberLabel"
			delta.custom_minimum_size.x = 58
			delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			var good := (after - before) * better > 0.0
			delta.add_theme_color_override("font_color", UIStyle.GOOD if good else UIStyle.BAD)
			if format.begins_with("×") and absf(before) > 0.001:
				delta.text = "%+d %%" % roundi((after / before - 1.0) * 100.0)
			else:
				delta.text = "%+d" % roundi(after - before)
			row.add_child(delta)
		card.add_padded(row, 2, 2)


# --- List tab ------------------------------------------------------------------

func _list_card() -> UICard:
	var card := UICard.new("All buildings", "level · status")
	for site in HqCampus.SITES:
		var id: StringName = site[0]
		var lv := Facilities.level(_team, id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var b := Button.new()
		b.text = tr(Facilities.name_of(id))
		b.theme_type_variation = &"FlatButton"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_select.bind(id))
		row.add_child(b)
		var pips := Label.new()
		pips.text = _pips(lv)
		pips.add_theme_color_override("font_color", UIStyle.ACCENT if lv > 0 else UIStyle.FAINT)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pips)
		var state := _tiny(_state_text(id, lv))
		state.custom_minimum_size.x = 120
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if _team.facility_projects.has(id):
			state.add_theme_color_override("font_color", UIStyle.ACCENT)
		row.add_child(state)
		card.add_padded(row, 0, 0)
	return card


func _state_text(id: StringName, lv: int) -> String:
	if _team.facility_projects.has(id):
		return tr("building · %d %%") % roundi(_progress(_team.facility_projects[id]) * 100)
	if Facilities.locked_until(id) != "":
		return tr("comes with %s") % Facilities.locked_until(id)
	if lv == 0:
		return tr("not built")
	return tr("Lv %d") % lv


# --- Action bar ----------------------------------------------------------------

func _build_actions() -> void:
	for child in _actions.get_children():
		child.queue_free()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_actions.add_child(row)
	var id := _selected
	var lv := Facilities.level(_team, id)
	var reason := Facilities.unavailable_reason(_team, id)
	if _team.facility_projects.has(id) or lv >= 5 or _tab == Tab.LIST:
		row.add_child(_small(_state_line(id)))
		return
	var offer := Facilities.quote(_team, id)
	if _confirming and reason == "":
		var ask := _small(tr("%s level %d for %s – ready %s?") % [tr(Facilities.name_of(id)), offer.target,
			UIStyle.money(offer.cost), _completion_date(offer.duration)])
		row.add_child(ask)
		var cancel := Button.new()
		cancel.text = tr("Cancel")
		cancel.pressed.connect(func():
			_confirming = false
			_build_actions())
		row.add_child(cancel)
		var confirm := _accent_button(tr("Confirm"))
		confirm.pressed.connect(func():
			_confirming = false
			var result := Facilities.start(_team, id, offer.target)
			_refresh()
			if result != "":
				_details.add_child(_note(tr(result))))
		row.add_child(confirm)
		return
	var cost := _small(tr("%s · %d days") % [UIStyle.money(offer.cost), offer.duration] if reason == "" else tr(reason))
	if reason != "":
		cost.add_theme_color_override("font_color", UIStyle.BAD if reason == "Insufficient funds" else UIStyle.MUTED)
	row.add_child(cost)
	var go := _accent_button(tr("Upgrade") if lv > 0 else tr("Build"))
	go.disabled = reason != ""
	go.pressed.connect(func():
		_confirming = true
		_build_actions())
	row.add_child(go)


func _state_line(id: StringName) -> String:
	if _tab == Tab.LIST:
		return tr("Budget: %s") % UIStyle.money(_team.budget)
	if _team.facility_projects.has(id):
		return tr("Under construction – ready %s.") % _completion_date(_team.facility_projects[id].remaining)
	return tr("Fully upgraded")


# --- Helpers -------------------------------------------------------------------

func _progress(project: Dictionary) -> float:
	return clampf(1.0 - float(project.remaining) / float(project.duration), 0.0, 1.0)


func _completion_date(days: int) -> String:
	var absolute := Calendar.day + days
	return Calendar.format_date(absolute % Calendar.DAYS_PER_SEASON, Calendar.year + absolute / Calendar.DAYS_PER_SEASON)


func _pips(lv: int) -> String:
	return "●".repeat(lv) + "○".repeat(5 - lv)


func _accent_button(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = &"AccentButton"
	return b


func _note(text: String) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIStyle.box(Color(UIStyle.WARN, 0.1), Color(UIStyle.WARN, 0.5), 1, 10, 6))
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return box


func _sub(tile: StatusTile, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	tile.get_child(0).add_child(l)


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _tiny(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	return l
