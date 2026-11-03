## Scouting (R7, docs/youth_model.md, design doc 4.3): the chief scout is sent
## after juniors – a whole series, a region or one person – and the reports
## show what the team knows now. Ranges narrow with every week; a weak scout
## can get a person wrong.
extends UIScreen

## Shown once after a click failed (the screen reloads after the click).
static var _error := ""

var _team: TeamData
var _page: VBoxContainer


func setup(_args: Dictionary) -> void:
	_team = GameState.player_team()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)
	_page.add_child(_stats_row())
	if _error != "":
		var warning := _small(_error)
		warning.add_theme_color_override("font_color", UIStyle.BAD)
		_page.add_child(warning)
		_error = ""
	if Scouting.capacity(_team) == 0:
		_page.add_child(_small(tr("No scouting office yet. Build one at the headquarters: the chief scout works from it.")))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UIStyle.GAP)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.add_child(_assignments_card())
	left.add_child(_single_card())
	left.add_child(_running_card())
	columns.add_child(left)
	columns.add_child(_reports_card())
	_page.add_child(columns)


func screen_title() -> String:
	return "Scouting"


func nav_section() -> StringName:
	return &"scouting"


func _stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var chief := Knowledge.chief_scout()
	var stats := [
		["%d" % Scouting.capacity(_team), tr("Scouting office level"), UIStyle.TEXT],
		["%d / %d" % [Scouting.busy(_team), Scouting.capacity(_team)], tr("Assignments running"), UIStyle.TEXT],
		[chief.full_name() if chief else tr("None"), tr("Chief scout"), UIStyle.TEXT],
		["%d" % _known_count(), tr("Juniors we know"), UIStyle.GOOD],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _assignments_card() -> UICard:
	var card := UICard.new(tr("Start an assignment"), tr("the chief scout travels, the weeks pass"))
	for series_id in [Youth.F3, Youth.F2]:
		var ids := Scouting.targets_of_series(series_id)
		card.add_row(_option_row(&"series", tr("All %s juniors") % Youth.SERIES_NAMES[series_id], ids))
	for region in Scouting.REGIONS:
		var ids := Scouting.targets_of_region(region)
		card.add_row(_option_row(&"region", tr("Juniors from %s") % tr(Scouting.REGION_NAMES[region]), ids))
	return card


func _option_row(kind: StringName, label: String, ids: Array[StringName]) -> HoverRow:
	var row := HoverRow.new()
	var todo := Scouting.todo_of(_team, ids)
	var box := _box_with(_name_box(label, tr("most valuable first")), [
		_figure("%d" % todo.size(), tr("to scout")),
		_figure(UIStyle.money(Scouting.FEE_PER_TARGET * todo.size()), tr("cost")),
		_figure("%d" % Scouting.weeks_needed(_team, todo), tr("weeks")),
	])
	var button := _accent(tr("Scout"))
	var reason := _blocked_reason(todo)
	button.disabled = reason != ""
	button.tooltip_text = reason
	button.pressed.connect(func():
		_error = Scouting.start(_team, kind, label, todo)
		shell.refresh_current())
	box.add_child(button)
	row.add_child(box)
	return row


## Single juniors the team does not know yet, most valuable first.
func _single_card() -> UICard:
	var card := UICard.new(tr("Single junior"), tr("one person, the chief scout goes alone"))
	var people := []
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and not _is_own(d):
			var one: Array[StringName] = [d.id]
			if not Scouting.todo_of(_team, one).is_empty():
				people.append(d)
	people.sort_custom(func(a, b): return Youth.value(a) > Youth.value(b))
	for d in people.slice(0, 6):
		var one: Array[StringName] = [d.id]
		card.add_row(_option_row(&"driver", d.full_name(), one))
	if people.is_empty():
		card.add_padded(_small(tr("Every junior is well known to us.")), 8, 8)
	return card


func _running_card() -> UICard:
	var card := UICard.new(tr("Running assignments"), tr("week by week"))
	var running := GameState.scout_assignments.filter(func(a): return a.team_id == _team.id)
	if running.is_empty():
		card.add_padded(_small(tr("No assignment running.")), 8, 8)
		return card
	for a in running:
		var row := HoverRow.new()
		var box := _box_with(_name_box(tr(a.label), tr("group of juniors")), [
			_figure(tr("week %d of %d") % [a.weeks_total - a.weeks_left, a.weeks_total], tr("progress")),
		])
		row.add_child(box)
		card.add_row(row)
	return card


func _reports_card() -> UICard:
	var card := UICard.new(tr("Juniors we know"), tr("range of ability and potential, the chief scout's advice"))
	var people := []
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and not _is_own(d) and Knowledge.level(d) >= 40:
			people.append(d)
	people.sort_custom(func(a, b): return Youth.value(a) > Youth.value(b))
	if people.is_empty():
		card.add_padded(_small(tr("No report yet. Start an assignment on the left.")), 8, 8)
		return card
	for d in people.slice(0, 25):
		card.add_row(_report_row(d))
	return card


func _report_row(d: DriverData) -> HoverRow:
	var row := HoverRow.new()
	var team: YouthTeam = Youth.team_of(d)
	var where := team.short_name if team else tr("No team")
	var ability := Knowledge.star_range(d, &"ability", d.overall())
	var potential := Knowledge.star_range(d, &"potential", d.potential)
	var box := _box_with(_name_box(d.full_name(), "%s · %d · %s" % [where, d.age(Calendar.year), d.nationality]), [
		_stars_figure(ability, tr("ability")),
		_stars_figure(potential, tr("potential")),
		_figure(tr(Scouting.recommendation(d)), tr("advice")),
	])
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	var profile := Button.new()
	profile.text = tr("Profile")
	profile.pressed.connect(func(): shell.open_driver(d.id))
	buttons.add_child(profile)
	if d.team_id == &"" and Academy.free_places(_team) > 0 and d.age(Calendar.year) <= Academy.INTAKE_MAX_AGE:
		var sign := _accent(tr("Academy"))
		sign.pressed.connect(func():
			_error = Academy.sign(_team, d)
			shell.refresh_current())
		buttons.add_child(sign)
	box.add_child(buttons)
	row.add_child(box)
	return row


# --- Helpers -----------------------------------------------------------------

func _is_own(d: DriverData) -> bool:
	return Knowledge.level(d) >= 100


func _known_count() -> int:
	var n := 0
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and not _is_own(d) and Knowledge.level(d) >= 40:
			n += 1
	return n


## Why the scout cannot be sent, "" when he can.
func _blocked_reason(todo: Array[StringName]) -> String:
	if Scouting.capacity(_team) <= 0:
		return tr("Build a scouting office first.")
	if Scouting.free_slots(_team) <= 0:
		return tr("All scouting slots are busy.")
	if todo.is_empty():
		return tr("Nothing new to find out there.")
	return ""


func _accent(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = &"AccentButton"
	return b


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _name_box(title: String, sub: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	var name_label := Label.new()
	name_label.text = title
	name_label.theme_type_variation = &"StrongLabel"
	column.add_child(name_label)
	var sub_label := Label.new()
	sub_label.text = sub
	sub_label.theme_type_variation = &"SmallLabel"
	column.add_child(sub_label)
	return column


## One row of figures: the name column first, then the figures.
func _box_with(first: Control, figures: Array) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(first)
	for figure in figures:
		box.add_child(figure)
	return box


func _figure(value: String, caption: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var number := Label.new()
	number.text = value
	number.theme_type_variation = &"NumberLabel"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(number)
	var label := Label.new()
	label.text = caption
	label.theme_type_variation = &"SmallLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(label)
	return column


## A star range as a figure (the same star display as the market).
func _stars_figure(stars: Vector2, caption: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var image := TextureRect.new()
	image.texture = StarRating.texture_range(stars.x, stars.y, 18)
	image.size_flags_horizontal = Control.SIZE_SHRINK_END
	column.add_child(image)
	var label := Label.new()
	label.text = caption
	label.theme_type_variation = &"SmallLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(label)
	return column
