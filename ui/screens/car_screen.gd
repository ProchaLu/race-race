## Car development (mockup r3_car.html): overview with the car from above,
## the selected part and every car value against the field; the workshop
## board with all projects by phase; the table of all parts per car; and the
## split between this year's and next year's car.
extends UIScreen

enum Tab { OVERVIEW, WORKSHOP, PARTS, NEXT_YEAR }

const VALUES := [&"downforce", &"drag_efficiency", &"mechanical_grip", &"braking", &"traction",
	&"tyre_preservation", &"cooling", &"reliability", &"power"]

var _tab: Tab = Tab.OVERVIEW
var _part: StringName = &"floor"
var _team: TeamData
var _car: CarData
var _page: VBoxContainer
var _selected_project := -1


func setup(args: Dictionary) -> void:
	_tab = args.get("tab", Tab.OVERVIEW)
	_part = args.get("part", &"floor")
	_selected_project = args.get("project", -1)
	_team = GameState.player_team()
	_car = _team.car
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	var tabs := Segmented.new([tr("Overview"), tr("Workshop"), tr("Parts"), tr("Next year")], _tab)
	tabs.custom_minimum_size.x = 500
	tabs.changed.connect(func(i):
		shell.update_args({"tab": i})
		shell.refresh_current())
	toolbar.add_child(tabs)
	var info := Label.new()
	info.text = tr("Season %d · after round %d · spent on the car: %s") % [Calendar.year, GameState.resolved_rounds,
		UIStyle.money(GameState.car_spending.get(_team.id, 0))]
	info.theme_type_variation = &"MutedLabel"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toolbar.add_child(info)
	var delegate := CheckButton.new()
	delegate.text = "Technical director plans the development"
	delegate.button_pressed = GameState.delegate_car_development
	delegate.tooltip_text = "On: the technical director fills free design slots and sets the next-year share. You can still start your own projects."
	delegate.toggled.connect(func(on):
		GameState.delegate_car_development = on
		shell.refresh_current())
	toolbar.add_child(delegate)
	_page.add_child(toolbar)

	if not _car.has_parts():
		_page.add_child(_note_card("This car has no parts yet."))
		return
	match _tab:
		Tab.OVERVIEW:
			_build_overview()
		Tab.WORKSHOP:
			_build_workshop()
		Tab.PARTS:
			_build_parts()
		_:
			_build_next_year()


## Opens the "New project" dialog on top of the screen.
func _open_dialog(part_id: StringName, next_year: bool = false) -> void:
	var dialog := NewProjectDialog.new(_team, part_id, next_year)
	dialog.started.connect(shell.refresh_current)
	add_child(dialog)


func _new_button(part_id: StringName, next_year: bool = false) -> Button:
	var b := Button.new()
	b.text = tr("New project").to_upper()
	b.icon = UIStyle.icon("play")
	b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.theme_type_variation = &"AccentButton"
	b.pressed.connect(func(): _open_dialog(part_id, next_year))
	return b


func screen_title() -> String:
	return "Car development"


func nav_section() -> StringName:
	return &"car"


# --- Overview ----------------------------------------------------------------

func _build_overview() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	_page.add_child(row)
	var car_card := UICard.new(tr("Your car · season %d") % Calendar.year, "parts coloured by rank in the field")
	car_card.size_flags_stretch_ratio = 1.25
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	var diagram := CarDiagram.new(_zone_color, _zone_tooltip, 600.0)
	diagram.selected = _part
	diagram.part_selected.connect(func(id):
		shell.update_args({"part": id})
		shell.refresh_current())
	inner.add_child(diagram)
	inner.add_child(_part_panel(_part))
	car_card.add_padded(inner, 10, 6)
	row.add_child(car_card)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UIStyle.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_values_card())
	right.add_child(_development_card())
	row.add_child(right)


func _rank_color(rank: int) -> Color:
	if rank <= 3:
		return UIStyle.GOOD
	if rank <= 5:
		return UIStyle.OK
	if rank <= 7:
		return UIStyle.WARN
	return UIStyle.BAD


func _zone_color(id: StringName) -> Color:
	var c := _rank_color(CarBuild.part_rank(_team.id, id))
	for p in CarDevelopment.projects_of(_team.id):
		if p.part_id == id:
			return c.lerp(UIStyle.ACCENT, 0.15)
	return c


func _zone_tooltip(id: StringName) -> String:
	var v: PartVersion = _car.parts[id]
	return "%s · P%d %s" % [v.label(), CarBuild.part_rank(_team.id, id), tr("in the field")]


func _part_panel(id: StringName) -> Control:
	var v: PartVersion = _car.parts[id]
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var icon := TextureRect.new()
	icon.texture = CarLayout.icon(id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(44, 44)
	icon.modulate = UIStyle.ACCENT
	head.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = tr(CarParts.name_of(id))
	title.uppercase = true
	title.theme_type_variation = &"HeadingLabel"
	names.add_child(title)
	var main: StringName = CarParts.MAIN_VALUE[id]
	names.add_child(_small(tr("%s · version %d · main value: %s") % [tr(CarParts.area_of(id)), v.version, tr(CarParts.VALUE_NAMES[main])]))
	head.add_child(names)
	column.add_child(head)
	column.add_child(_spacer(8))

	var rank := CarBuild.part_rank(_team.id, id)
	var rows := []
	for key in CarParts.values_of(id):
		var value := roundi(v.value(key))
		rows.append([tr(CarParts.VALUE_NAMES[key]), str(value), key == main])
	var i := 0
	for r in rows:
		var fact := FactRow.new(r[0], r[1], "", true, UIStyle.ACCENT if r[2] else UIStyle.TEXT)
		fact.set_zebra(i % 2 == 1)
		column.add_child(fact)
		i += 1
	var extra := [
		["Rank in the field", tr("P%d of %d") % [rank, GameState.series[_team.series_id].team_ids.size()], _rank_color(rank)],
		["Mass", "%.1f kg" % v.mass_kg, UIStyle.TEXT],
		["Units", str(v.units), UIStyle.TEXT],
	]
	if v.version > 1:
		var last := tr("forecast %s") % _seconds(v.forecast_s)
		if v.correlated:
			last += " · " + tr("on track %s") % _seconds(v.real_s)
		extra.append(["Last update", last, UIStyle.GOOD if v.real_s < -0.005 and v.correlated else UIStyle.TEXT])
	for e in extra:
		var fact := FactRow.new(tr(e[0]), e[1], "", true, e[2])
		fact.set_zebra(i % 2 == 1)
		column.add_child(fact)
		i += 1

	column.add_child(_section("In development"))
	var running := false
	for p in CarDevelopment.projects_of(_team.id):
		if p.part_id != id:
			continue
		running = true
		var line := _small(tr("%s · %s %d %% · ready %s · %s") % [tr(CarParts.GOALS[p.goal][0]) if CarParts.GOALS.has(p.goal) else tr("spares"),
			tr(DevProject.PHASE_NAMES[p.phase]), roundi(p.phase_progress() * 100),
			CarDevelopment.ready_label(CarDevelopment.days_left(_team, p)), _forecast_text(p)])
		line.add_theme_color_override("font_color", UIStyle.ACCENT)
		column.add_child(_pad(line))
	if not running:
		column.add_child(_pad(_small("No project for this part.")))
	column.add_child(_section("Versions this season"))
	var history: Array = _car.part_history.get(id, [])
	for k in range(history.size() - 1, maxi(-1, history.size() - 5), -1):
		var h: PartVersion = history[k]
		var text := tr("v%d · start of the season") % h.version if h.version == 1 else \
			tr("v%d · R%d · %s · %s") % [h.version, h.first_round, tr(CarParts.GOALS[h.goal][0]) if CarParts.GOALS.has(h.goal) else "",
			_seconds(h.real_s) if h.correlated else tr("forecast %s") % _seconds(h.forecast_s)]
		column.add_child(_pad(_small(text)))
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	if CarDevelopment.can_revert(_team, id):
		var history_now: Array = _car.part_history.get(id, [])
		var back := Button.new()
		var older: PartVersion = history_now[history_now.find(v) - 1]
		back.text = tr("Back to v%d") % older.version
		back.tooltip_text = tr("Scrap the %s units and race the previous version again.") % v.label()
		back.pressed.connect(func():
			CarDevelopment.revert(_team, id)
			shell.refresh_current())
		actions.add_child(back)
	actions.add_child(_new_button(id))
	column.add_child(_pad(actions, 10))
	column.add_child(_spacer(8))
	column.add_child(_legend())
	return column


func _legend() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	for entry in [["top 3", UIStyle.GOOD], ["P4–5", UIStyle.OK], ["P6–7", UIStyle.WARN], ["P8+", UIStyle.BAD]]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var sw := ColorRect.new()
		sw.color = entry[1]
		sw.custom_minimum_size = Vector2(10, 10)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(sw)
		item.add_child(_tiny(entry[0]))
		flow.add_child(item)
	flow.add_child(_tiny("click a part"))
	return _pad(flow)


func _values_card() -> UICard:
	var card := UICard.new("Car values", "line = field average · season = change since the start")
	var values := CarBuild.snapshot(_car)
	for key in VALUES:
		var value: float = values[key]
		var rank := CarBuild.field_rank(_team.id, &"engine_power" if key == &"power" else key)
		var avg := CarBuild.field_average(&"engine_power" if key == &"power" else key)
		var start: float = _car.season_start.get(key, value)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var name_label := Label.new()
		name_label.text = tr(CarParts.VALUE_NAMES[key]) + (tr(" (fixed until R5)") if key == &"power" else "")
		name_label.theme_type_variation = &"MutedLabel"
		name_label.custom_minimum_size.x = 210
		row.add_child(name_label)
		row.add_child(RatingBar.new(value, _rank_color(rank), avg))
		row.add_child(_number("%d" % roundi(value), 44))
		var r := _number("P%d" % rank, 44)
		r.add_theme_color_override("font_color", _rank_color(rank))
		row.add_child(r)
		var delta := roundi(value - start)
		var d := _number(("%+d" % delta) if delta != 0 else "–", 44)
		d.add_theme_color_override("font_color", UIStyle.GOOD if delta > 0 else (UIStyle.BAD if delta < 0 else UIStyle.MUTED))
		row.add_child(d)
		card.add_padded(row, 3, 3)
	var over := _car.mass_kg - CarBuild.MIN_MASS
	var mass_text := tr("%.1f kg · %.1f kg over the limit (%+.2f s/lap)") % [_car.mass_kg, over, over * SimTuning.FUEL_S_PER_KG] if over > 0.05 \
		else tr("%.1f kg · under the limit, ballast placed for balance") % _car.mass_kg
	card.add_row(FactRow.new("Weight", mass_text, "", false, UIStyle.WARN if over > 3.0 else UIStyle.TEXT))
	var lap := CarBuild.lap_vs_field(_team.id)
	var lap_rank := 1
	for id in GameState.series[_team.series_id].team_ids:
		if CarBuild.lap_vs_field(id) < lap:
			lap_rank += 1
	card.add_row(FactRow.new("Lap time vs. field average", "%+.2f s · P%d" % [lap, lap_rank], "", true,
		UIStyle.GOOD if lap < 0.0 else UIStyle.BAD))
	return card


func _development_card() -> UICard:
	var card := UICard.new("Development", "capacity per department")
	var projects := CarDevelopment.projects_of(_team.id)
	card.add_row(FactRow.new("Active projects", tr("%d of %d possible") % [projects.size(), CarDevelopment.max_projects(_team)], "", true))
	card.add_padded(_capacity_rows(), 4, 4)
	card.add_row(FactRow.new("Spent on the car this season", UIStyle.money(GameState.car_spending.get(_team.id, 0)), "", true))
	card.add_row(FactRow.new("Budget", UIStyle.money(_team.budget), "", true, UIStyle.money_color(_team.budget)))
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	var board := Button.new()
	board.text = "Workshop"
	board.icon = UIStyle.icon("factory")
	board.pressed.connect(func():
		shell.update_args({"tab": Tab.WORKSHOP})
		shell.refresh_current())
	actions.add_child(board)
	card.add_padded(actions, 6, 0)
	return card


const DEPARTMENTS := [[&"design", "Design"], [&"aero", "CFD / simulation"], [&"tunnel", "Wind tunnel"], [&"rig", "Test rigs"],
	[&"factory", "Factory"]]
## Workshop board: [title, phases]; projects waiting for a decision get their own column.
const BOARD := [["Ideas & CFD", [DevProject.Phase.CONCEPT, DevProject.Phase.CFD]], ["Wind tunnel / rig", [DevProject.Phase.TUNNEL]],
	["Detail & tooling", [DevProject.Phase.DETAIL, DevProject.Phase.TOOLING]],
	["Production", [DevProject.Phase.PRODUCTION, DevProject.Phase.QUALITY]]]


func _capacity_rows() -> Control:
	var busy := CarDevelopment.department_load(_team)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	for d in DEPARTMENTS:
		var entry: Array = busy[d[0]]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var l := Label.new()
		l.text = tr(d[1])
		l.theme_type_variation = &"MutedLabel"
		l.custom_minimum_size.x = 140
		l.tooltip_text = tr("%d people · key person, facilities and headcount set the capacity") % CarDevelopment.headcount(_team, d[0])
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(l)
		var heads := _small(tr("%d people") % CarDevelopment.headcount(_team, d[0]))
		heads.autowrap_mode = TextServer.AUTOWRAP_OFF
		heads.custom_minimum_size.x = 80
		heads.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(heads)
		# Full speed for about as many projects as the capacity allows.
		var used: float = clampf(entry[0] / maxf(entry[1], 0.1), 0.0, 1.0)
		row.add_child(RatingBar.new(used * 100.0, UIStyle.WARN if entry[0] > entry[1] else UIStyle.OK))
		var t := _small(tr("%d projects · capacity %.2f") % [entry[0], entry[1]])
		t.autowrap_mode = TextServer.AUTOWRAP_OFF
		t.size_flags_horizontal = Control.SIZE_SHRINK_END
		t.custom_minimum_size.x = 170
		row.add_child(t)
		column.add_child(row)
	return column


# --- Workshop ----------------------------------------------------------------

func _build_workshop() -> void:
	var cap := UICard.new("Capacity", "more projects than capacity = each runs slower")
	cap.add_padded(_capacity_rows(), 6, 4)
	cap.add_padded(_small(tr("%d of %d parallel projects (design office level %d). Each project runs at most at its normal pace; priority decides who gets more when a department is full.")
		% [CarDevelopment.design_projects(_team.id).size(), CarDevelopment.max_projects(_team), _team.design_center_level]), 4, 4)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_child(_new_button(_part))
	cap.add_padded(bar, 4, 4)
	_page.add_child(cap)
	var selected := _find_project(_selected_project)
	if selected == null:
		var waiting := CarDevelopment.waiting(_team.id)
		if not waiting.is_empty():
			selected = waiting[0]
			_selected_project = selected.id
	if selected and selected.is_spares():
		_page.add_child(_project_controls(selected))
	elif selected:
		_page.add_child(DevLabCard.new(_team, selected, shell.refresh_current))

	var board := HBoxContainer.new()
	board.add_theme_constant_override("separation", 10)
	var share := CarDevelopment.shares(_team)
	var columns := [["Your decision", []]] + BOARD
	for c in columns.size():
		var col := PanelContainer.new()
		col.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE, 1, 0, 0))
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size.y = 360
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		col.add_child(v)
		var phases: Array = columns[c][1]
		var list := CarDevelopment.projects_of(_team.id).filter(func(p):
			var waiting: bool = p.milestone != DevProject.Milestone.NONE
			return waiting if c == 0 else (not waiting and phases.has(p.phase)))
		var head := HBoxContainer.new()
		var t := Label.new()
		t.text = tr(columns[c][0])
		if c == 0 and not list.is_empty():
			t.add_theme_color_override("font_color", UIStyle.ACCENT)
		t.uppercase = true
		t.theme_type_variation = &"SectionLabel"
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(t)
		head.add_child(_small(str(list.size())))
		v.add_child(_pad(head))
		v.add_child(HSeparator.new())
		for p in list:
			v.add_child(_project_card(p, share))
		board.add_child(col)
	_page.add_child(board)


const MILESTONE_TEXT := ["", "Decision: which ideas go into CFD", "Decision: what goes into the wind tunnel",
	"Decision: refine, freeze or drop"]


func _find_project(id: int) -> DevProject:
	for p in CarDevelopment.projects_of(_team.id):
		if p.id == id:
			return p
	return null


## Priority, overtime and cancel for the selected project.
func _project_controls(p: DevProject) -> UICard:
	var title := tr("Spare units: %s v%d") % [p.label(), p.spares_version] if p.is_spares() else p.label()
	var card := UICard.new(title, tr(DevProject.PHASE_NAMES[p.phase]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var prio := Segmented.new(DevProject.PRIORITY_NAMES.map(func(n): return tr(n)), p.priority)
	prio.custom_minimum_size.x = 300
	prio.changed.connect(func(i):
		p.priority = i as DevProject.Priority
		shell.refresh_current())
	row.add_child(_small("Priority"))
	row.add_child(prio)
	var overtime := CheckButton.new()
	overtime.text = "Overtime (×1.4 speed)"
	overtime.button_pressed = p.overtime
	overtime.toggled.connect(func(on):
		p.overtime = on
		shell.refresh_current())
	row.add_child(overtime)
	var cancel := Button.new()
	cancel.text = "Cancel project"
	cancel.tooltip_text = "Money already spent is lost."
	cancel.pressed.connect(func():
		CarDevelopment.cancel(p)
		shell.update_args({"project": -1})
		shell.refresh_current())
	row.add_child(cancel)
	card.add_padded(row, 8, 4)
	card.add_padded(_small(tr("Cost so far %s · %s · %s") % [UIStyle.money(p.cost_spent), _forecast_text(p) if not p.is_spares() else "–",
		tr("next season's car") if p.next_year else tr("this season")]), 2, 4)
	return card


func _project_card(p: DevProject, share: Dictionary) -> Control:
	var box := HoverRow.new(&"ResultBox", &"ResultBoxHover")
	box.make_clickable()
	box.set_selected(p.id == _selected_project)
	box.clicked.connect(func():
		shell.update_args({"project": p.id})
		shell.refresh_current())
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	margin.add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	box.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = CarLayout.icon(p.part_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(24, 24)
	icon.modulate = UIStyle.ACCENT
	top.add_child(icon)
	var name_label := Label.new()
	var history: Array = _car.part_history.get(p.part_id, [])
	if p.is_spares():
		name_label.text = tr("%s v%d · spares") % [p.label(), p.spares_version]
	elif p.next_year:
		name_label.text = tr("%s · next year") % p.label()
	else:
		name_label.text = "%s v%d" % [p.label(), history.size() + 1]
	name_label.theme_type_variation = &"StrongLabel"
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	column.add_child(top)
	if p.is_spares():
		column.add_child(_small(tr("%d of %d units") % [p.units_built, p.units]))
	else:
		column.add_child(_small(tr(DevProject.PHASE_NAMES[p.phase]) + " · " + tr(CarParts.GOALS[p.goal][0]) + " · " + tr(DevProject.AMBITION_NAMES[p.ambition])))
	column.add_child(Meter.new(p.progress() * 100.0, UIStyle.ACCENT, 4))
	var bottom := HBoxContainer.new()
	var prio := Label.new()
	prio.text = tr(DevProject.PRIORITY_NAMES[p.priority]).to_upper()
	prio.theme_type_variation = &"TinyLabel"
	prio.add_theme_color_override("font_color", UIStyle.BAD if p.priority == DevProject.Priority.HIGH else UIStyle.ACCENT)
	prio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(prio)
	var eta := _small(tr("ready %s") % CarDevelopment.ready_label(CarDevelopment.days_left(_team, p, share)))
	eta.autowrap_mode = TextServer.AUTOWRAP_OFF
	eta.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom.add_child(eta)
	column.add_child(bottom)
	if not p.is_spares():
		var forecast := _small(_forecast_text(p))
		forecast.add_theme_color_override("font_color", UIStyle.GOOD if p.forecast_s < 0.0 else UIStyle.MUTED)
		column.add_child(forecast)
	if p.milestone != DevProject.Milestone.NONE:
		var m := _small(tr(MILESTONE_TEXT[p.milestone]))
		m.add_theme_color_override("font_color", UIStyle.ACCENT)
		column.add_child(m)
	if p.waiting_for_money:
		var w := _small("Waiting for budget")
		w.add_theme_color_override("font_color", UIStyle.BAD)
		column.add_child(w)
	box.tooltip_text = tr("%s · %s · cost so far %s · %d units") % [p.label(), tr(CarParts.GOALS[p.goal][0]) if CarParts.GOALS.has(p.goal) else tr("spares"),
		UIStyle.money(p.cost_spent), p.units]
	return margin


# --- Parts table -------------------------------------------------------------

func _build_parts() -> void:
	var card := UICard.new("Parts", "fitted to both cars")
	var drivers := GameState.drivers_of_team(_team.id)
	var cols := [["", 40], ["Part", 180, true], ["Version", 80], ["Main value", 150], ["Value", 64],
		["Rank", 64], ["Mass", 90], ["Reliability", 96]]
	for d in drivers:
		cols.append(["#%d %s" % [d.number, d.last_name], 120])
	cols.append(["Spare", 70])
	cols.append(["Last update", 200, true])
	var tree := Tree.new()
	tree.hide_root = true
	tree.columns = cols.size()
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_ROW
	tree.scroll_vertical_enabled = false
	tree.custom_minimum_size.y = 34 + CarParts.ORDER.size() * 34
	for i in cols.size():
		tree.set_column_title(i, cols[i][0])
		tree.set_column_custom_minimum_width(i, cols[i][1])
		tree.set_column_expand(i, cols[i].size() > 2)
		tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	var root := tree.create_item()
	for id in CarParts.ORDER:
		var v: PartVersion = _car.parts[id]
		var main: StringName = CarParts.MAIN_VALUE[id]
		var rank := CarBuild.part_rank(_team.id, id)
		var item := tree.create_item(root)
		item.set_metadata(0, id)
		item.set_icon(0, CarLayout.icon(id))
		item.set_icon_max_width(0, 20)
		item.set_icon_modulate(0, UIStyle.ACCENT)
		item.set_text(1, tr(CarParts.name_of(id)))
		item.set_text(2, "v%d" % v.version)
		item.set_text(3, tr(CarParts.VALUE_NAMES[main]))
		item.set_text(4, str(roundi(v.value(main))))
		item.set_text(5, "P%d" % rank)
		item.set_custom_color(5, _rank_color(rank))
		item.set_text(6, "%.1f kg" % v.mass_kg)
		item.set_text(7, str(roundi(v.value(&"reliability"))))
		if v.value(&"reliability") < 75:
			item.set_custom_color(7, UIStyle.WARN)
		var col := 8
		for d in drivers:
			var fitted := CarBuild.fitted_version(_team, d.id, id)
			item.set_text(col, "v%d" % fitted.version)
			item.set_custom_color(col, UIStyle.GOOD if fitted.version == v.version else UIStyle.WARN)
			item.set_custom_font(col, UIStyle.font(&"mono"))
			col += 1
		var spares := 0
		for h in _car.part_history.get(id, []):
			spares += h.units - CarBuild.fitted_count(_team, id, h.version)
		item.set_text(col, str(spares))
		item.set_custom_color(col, UIStyle.BAD if spares <= 0 else UIStyle.TEXT)
		if v.version > 1:
			item.set_text(col + 1, "R%d · %s" % [v.first_round, _seconds(v.real_s) if v.correlated else tr("forecast %s") % _seconds(v.forecast_s)])
		for c in [2, 4, 5, 6, 7, col]:
			item.set_custom_font(c, UIStyle.font(&"mono"))
	tree.item_selected.connect(func():
		var sel := tree.get_selected()
		if sel:
			shell.navigate(&"car", {"tab": Tab.OVERVIEW, "part": sel.get_metadata(0)}))
	card.add(tree)
	card.add_padded(_small("Green = the newest version, amber = an older one. Crashes destroy parts; the factory manager orders spares after every race. Brakes are used up every weekend."), 6, 2)
	_page.add_child(card)


# --- Next year ---------------------------------------------------------------

func _build_next_year() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	_page.add_child(row)
	var card := UICard.new(tr("Resources for the %d car") % (Calendar.year + 1), "share of every department")
	card.size_flags_stretch_ratio = 1.2
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 90
	slider.step = 5
	slider.value = roundi(_team.next_year_share * 100)
	slider.editable = not GameState.delegate_car_development
	slider.custom_minimum_size.y = 28
	var track := StyleBoxFlat.new()
	track.bg_color = UIStyle.LINE_STRONG
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", track)
	var filled := StyleBoxFlat.new()
	filled.bg_color = UIStyle.RAIN
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var value := Label.new()
	value.theme_type_variation = &"StrongLabel"
	value.text = tr("%d %% this year · %d %% next year") % [100 - roundi(slider.value), roundi(slider.value)]
	slider.value_changed.connect(func(v):
		_team.next_year_share = v / 100.0
		value.text = tr("%d %% this year · %d %% next year") % [100 - roundi(v), roundi(v)])
	card.add_padded(slider, 10, 2)
	card.add_padded(value, 2, 4)
	var rec := CarDevelopment.recommended_share(_team)
	card.add_row(FactRow.new("Technical director recommends", "%d %%" % roundi(rec * 100), "", true, UIStyle.ACCENT))
	if GameState.delegate_car_development:
		card.add_padded(_small("The technical director sets the share while he plans the development. Switch delegation off to set it yourself."), 4, 4)
	card.add_padded(_small("The share only works on next-year projects. Without next-year projects everybody works on this year's car."), 4, 4)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_child(_new_button(&"monocoque", true))
	card.add_padded(actions, 8, 4)
	row.add_child(card)

	var plan := UICard.new(tr("%d car · concept") % (Calendar.year + 1), "developed so far")
	var any := false
	for id in CarParts.ORDER:
		var fx: Dictionary = _team.next_year_parts.get(id, {})
		if fx.is_empty():
			continue
		any = true
		var s := CarBuild.lap_effect(id, fx)
		var main: StringName = CarParts.MAIN_VALUE[id]
		var text := "%+.3f s" % s if absf(s) >= 0.0005 else "%s %+d" % [tr(CarParts.VALUE_NAMES[main]), roundi(fx.get(main, 0.0))]
		plan.add_row(FactRow.new(tr(CarParts.name_of(id)), text, "", true, UIStyle.GOOD))
	if not any:
		plan.add_padded(_small("Nothing developed for next season yet."), 6, 4)
	for p in CarDevelopment.design_projects(_team.id):
		if p.next_year:
			plan.add_row(FactRow.new(tr("%s · in development") % p.label(),
				"%s %d %%" % [tr(DevProject.PHASE_NAMES[p.phase]), roundi(p.progress() * 100)], "", false, UIStyle.ACCENT))
	plan.add_padded(_small(tr("New part value = 50 + 75 % of this year's lead + next-year development. Every car moves towards the average over the winter; early work on the new car is the lead.")), 8, 4)
	row.add_child(plan)


# --- Helpers -----------------------------------------------------------------

## "forecast −0.025 s per lap", or the value change for goals that do not
## change the lap time directly (reliability, cooling, tyres).
func _forecast_text(p: DevProject) -> String:
	if p.forecast.is_empty():
		return tr("not measured yet")
	if absf(p.forecast_s) >= 0.0005:
		return tr("forecast %s per lap") % _seconds(p.forecast_s)
	var key := CarDevelopment.goal_value(p.goal)
	return tr("forecast %s %+d") % [tr(CarParts.VALUE_NAMES[key]), roundi(p.forecast.get(key, 0.0))]


func _tiny(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	return l


func _seconds(s: float) -> String:
	return "%+.3f s" % s


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _number(text: String, width: int) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"NumberLabel"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.custom_minimum_size.x = width
	return l


func _section(text: String) -> Control:
	var l := Label.new()
	l.text = text
	l.uppercase = true
	l.theme_type_variation = &"SectionLabel"
	return _pad(l, 10)


func _pad(control: Control, top: int = 2) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", UIStyle.ROW_PAD_X)
	m.add_theme_constant_override("margin_right", UIStyle.ROW_PAD_X)
	m.add_theme_constant_override("margin_top", top)
	m.add_child(control)
	return m


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _note_card(text: String) -> UICard:
	var card := UICard.new("Car development")
	card.add_padded(_small(text), 8, 4)
	return card
