## "New development project" (mockup r3_car.html, screen 2): part, focus,
## approach, priority, units, season and overtime on the left; the live
## forecast on the right. Start is locked with a reason (budget, slots …).
## The project then runs through the development lab (r3_lab.html).
class_name NewProjectDialog
extends Control

signal started

var _team: TeamData
var _part: StringName
var _goal := ""
var _ambition := DevProject.Ambition.NORMAL
var _priority := DevProject.Priority.NORMAL
var _units := 3
var _next_year := false
var _overtime := false
var _body: HBoxContainer


func _init(team: TeamData, part_id: StringName, next_year: bool = false) -> void:
	_team = team
	_part = part_id
	_next_year = next_year or not CarParts.in_season(part_id)
	_goal = CarParts.goals_of(part_id)[0]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UIStyle.BG, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 50)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.BG, UIStyle.ACCENT, 1, 0, 0))
	margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, Color.TRANSPARENT, 0, 20, 10))
	var head_row := HBoxContainer.new()
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var small := Label.new()
	small.text = "New development project"
	small.uppercase = true
	small.theme_type_variation = &"SectionLabel"
	titles.add_child(small)
	var title := Label.new()
	title.name = "Title"
	title.theme_type_variation = &"HeadingLabel"
	titles.add_child(title)
	head_row.add_child(titles)
	var close := Button.new()
	close.text = "✕"
	close.theme_type_variation = &"FlatButton"
	close.pressed.connect(queue_free)
	head_row.add_child(close)
	head.add_child(head_row)
	column.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	scroll.add_child(pad)
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", UIStyle.GAP)
	pad.add_child(_body)
	_rebuild()


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	var history: Array = _team.car.part_history.get(_part, [])
	var title: Label = find_child("Title", true, false)
	title.text = "%s %s" % [tr(CarParts.name_of(_part)), tr("for next season") if _next_year else "v%d" % (history.size() + 1)]
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_child(_part_card())
	left.add_child(_goal_card())
	left.add_child(_approach_card())
	_body.add_child(left)
	var right := _forecast_card()
	right.size_flags_stretch_ratio = 1.0
	_body.add_child(right)


# --- Left: choices -----------------------------------------------------------

func _part_card() -> UICard:
	var card := UICard.new("1 · Part", "rank in the field")
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for id in CarParts.ORDER:
		var b := Button.new()
		b.text = "%s\nP%d" % [tr(CarParts.name_of(id)), CarBuild.part_rank(_team.id, id)]
		b.icon = CarLayout.icon(id)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 22)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 46
		b.set_pressed_no_signal(id == _part)
		b.clip_text = true
		var part_id: StringName = id
		b.pressed.connect(func():
			_part = part_id
			_goal = CarParts.goals_of(part_id)[0]
			if not CarParts.in_season(part_id):
				_next_year = true
			_rebuild())
		grid.add_child(b)
	card.add_padded(grid, 6, 6)
	return card


func _goal_card() -> UICard:
	var card := UICard.new("2 · Focus", "where the design office looks first")
	var goals: Array = CarParts.goals_of(_part)
	var options := []
	for g in goals:
		options.append([tr(CarParts.GOALS[g][0]), tr(CarParts.GOALS[g][1])])
	ChoiceRow.make_group(card.body, options, goals.find(_goal), func(i):
		_goal = goals[i]
		_rebuild())
	return card


func _approach_card() -> UICard:
	var card := UICard.new("3 · Approach")
	var amb := [["Conservative", "Small ideas ×0.6 · few dead ends"], ["Normal", "Ideas ×1.0 · some dead ends"],
		["Aggressive", "Bold ideas ×1.6 · many dead ends · +30 % cost"]]
	var options := amb.map(func(a): return [tr(a[0]), tr(a[1])])
	ChoiceRow.make_group(card.body, options, _ambition, func(i):
		_ambition = i as DevProject.Ambition
		_rebuild())
	_add_segment(card, "Priority", DevProject.PRIORITY_NAMES.map(func(n): return tr(n)), _priority,
		func(i): _priority = i as DevProject.Priority)
	if not _next_year:
		_add_segment(card, "Units to build", ["1", "2", tr("3 (1 spare)"), "4"], _units - 1, func(i): _units = i + 1)
	var seasons := [tr("This season"), tr("Next season's car")]
	_add_segment(card, "For", seasons, 1 if _next_year else 0, func(i): _next_year = i == 1,
		[0] if not CarParts.in_season(_part) or GameState.next_round_index() < 0 else [])
	_add_segment(card, "Overtime", [tr("No"), tr("Yes · ×1.4 speed, ×1.5 cost, team mood −")], 1 if _overtime else 0,
		func(i): _overtime = i == 1)
	return card


func _add_segment(card: UICard, caption: String, labels: Array, selected: int, on_change: Callable, disabled: Array = []) -> void:
	card.add_section(caption)
	var seg := Segmented.new(labels, selected, disabled)
	seg.changed.connect(func(i):
		on_change.call(i)
		_rebuild())
	card.add_padded(seg, 2, 4)


# --- Right: forecast ---------------------------------------------------------

func _forecast_card() -> UICard:
	var f := CarDevelopment.preview(_team, _part, _goal, _ambition, _priority, _units, _overtime, _next_year)
	var card := UICard.new("Forecast")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tiles := HBoxContainer.new()
	var main := CarDevelopment.goal_value(_goal)
	var gain_text := "%+.3f s" % f.expected_s if absf(f.expected_s) >= 0.0005 \
		else "%s %+d" % [tr(CarParts.VALUE_NAMES[main]), roundi(f.fx.get(main, 0.0))]
	var t1 := StatusTile.new("Target", gain_text, UIStyle.GOOD)
	_sub(t1, tr("per lap if the ideas work"))
	tiles.add_child(t1)
	var t2 := StatusTile.new("Ready", f.ready, UIStyle.TEXT)
	_sub(t2, tr("in ~%d days") % roundi(f.days))
	tiles.add_child(t2)
	var t3 := StatusTile.new("Cost", "~" + UIStyle.money(f.cost), UIStyle.TEXT)
	_sub(t3, tr("ideas %s now · the rest step by step") % UIStyle.money(f.concept_cost))
	tiles.add_child(t3)
	var risk: float = f.risk
	var t4 := StatusTile.new("Dead ends", "%d %%" % roundi(risk * 100),
		UIStyle.GOOD if risk < 0.12 else (UIStyle.BAD if risk > 0.28 else UIStyle.WARN))
	_sub(t4, tr("of the ideas make the part worse"))
	tiles.add_child(t4)
	card.add_padded(tiles, 4, 4)

	card.add_row(FactRow.new("Ideas", f.ideas, tr("more with good staff and many designers"), true))
	var corr: float = f.correlation
	card.add_row(FactRow.new("Correlation", tr("Good") if corr < 0.15 else (tr("Medium") if corr < 0.28 else tr("Weak")),
		tr("how far the forecast can be off"), false, UIStyle.GOOD if corr < 0.15 else (UIStyle.WARN if corr < 0.28 else UIStyle.BAD)))
	card.add_section("Timeline")
	card.add_padded(_timeline(f.phase_days), 2, 4)
	var busy := CarDevelopment.department_load(_team)
	for entry in f.phase_days:
		var d: StringName = entry[0]
		if busy.has(d) and busy[d][0] >= int(busy[d][1]):
			card.add_padded(_warning(tr("%s is busy (%d projects) – this project runs at %d %% speed.") % [
				tr(CarDevelopment.DEPARTMENT_NAMES[d]), busy[d][0], roundi(minf(entry[2], 1.0) * 100)]), 4, 2)
			break
	card.add_padded(_quote(), 6, 4)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	var after := _small(tr("Budget after start: %s") % UIStyle.money(_team.budget - f.concept_cost))
	after.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(after)
	var go := Button.new()
	go.text = tr("Start project").to_upper()
	go.icon = UIStyle.icon("play")
	go.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	go.theme_type_variation = &"AccentButton"
	var reason: String = f.reason
	go.disabled = reason != ""
	go.tooltip_text = tr(reason)
	go.pressed.connect(_start)
	actions.add_child(go)
	card.add_padded(actions, 10, 4)
	if reason != "":
		var why := _small(tr(reason))
		why.add_theme_color_override("font_color", UIStyle.BAD)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.add_padded(why, 0, 4)
	return card


func _timeline(phases: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.custom_minimum_size.y = 26
	var colors := {&"design": UIStyle.ACCENT, &"aero": UIStyle.RAIN, &"tunnel": UIStyle.RAIN, &"rig": UIStyle.FASTEST,
		&"tooling": UIStyle.MUTED, &"factory": UIStyle.OK}
	for i in phases.size():
		var d: StringName = phases[i][0]
		var days: float = phases[i][1]
		var block := PanelContainer.new()
		block.add_theme_stylebox_override("panel", UIStyle.box(colors[d], Color.TRANSPARENT, 0, 4, 2))
		block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		block.size_flags_stretch_ratio = maxf(days, 1.0)
		var phase_name := tr(DevProject.PHASE_NAMES[phases[i][3]])
		var l := Label.new()
		l.text = "%s %d d" % [phase_name, roundi(days)]
		l.theme_type_variation = &"TinyLabel"
		l.add_theme_color_override("font_color", UIStyle.BG)
		l.clip_text = true
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		block.add_child(l)
		block.tooltip_text = l.text + ("" if d == &"tooling" else " · " + tr(CarDevelopment.DEPARTMENT_NAMES[d]))
		row.add_child(block)
	return row


## The technical director's opinion of this project.
func _quote() -> Control:
	var rank := CarBuild.part_rank(_team.id, _part)
	var corr := CarDevelopment.correlation_error(_team, _part)
	var part_name := tr(CarParts.name_of(_part))
	var text := ""
	if rank >= 8:
		text = tr("The %s is one of our weakest parts – P%d in the field. There is time to find here.") % [part_name, rank]
	elif rank <= 3:
		text = tr("Our %s is already among the best. Big steps get hard from here.") % part_name
	else:
		text = tr("A sensible project. The %s is P%d in the field.") % [part_name, rank]
	if _ambition == DevProject.Ambition.AGGRESSIVE and corr > 0.25:
		text += " " + tr("Our correlation is not great – I would not go aggressive.")
	var chief := ""
	for s in GameState.staff_of_team(_team.id):
		if s.role == StaffData.Role.TECHNICAL_DIRECTOR:
			chief = s.full_name()
	var box := PanelContainer.new()
	box.theme_type_variation = &"TraitBox"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.add_child(_small("%s · %s" % [chief if chief != "" else tr("Technical director"), tr("technical director")]))
	var said := Label.new()
	said.text = "“%s”" % text
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(said)
	box.add_child(column)
	return box


func _start() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var p := CarDevelopment.plan(_team, _part, _goal, _ambition, _priority, _units, _overtime, r, _next_year)
	if CarDevelopment.start(_team, p) == "":
		started.emit()
		queue_free()


func _warning(text: String) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIStyle.box(Color(UIStyle.WARN, 0.1), Color(UIStyle.WARN, 0.5), 1, 10, 6))
	var l := Label.new()
	l.text = "⚠ " + text
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
	return l
