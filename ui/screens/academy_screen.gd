## Academy (R7, docs/youth_model.md): the young drivers the team trains. Places
## come from the academy building, the academy head decides how fast they grow.
## From here the drivers go into junior seats (F3, F2), come back, or leave.
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
	if Academy.places(_team) == 0:
		_page.add_child(_small(tr("No academy yet. Build one at the headquarters to get places for young drivers.")))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UIStyle.GAP)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.add_child(_roster_card())
	left.add_child(_standings_card())
	columns.add_child(left)
	columns.add_child(_pool_card())
	_page.add_child(columns)


func screen_title() -> String:
	return "Academy"


func nav_section() -> StringName:
	return &"academy"


func _stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var head := Academy.head(_team)
	var fees := _team.academy_driver_ids.size() * Academy.FEE_PER_MONTH
	var stats := [
		["%d / %d" % [_team.academy_driver_ids.size(), Academy.places(_team)], tr("Places used"), UIStyle.TEXT],
		[head.full_name() if head else tr("None"), tr("Academy head"), UIStyle.TEXT],
		["%d / 20" % DriverAttributes.to_display(Academy.head_skill(_team)), tr("Youth development"), UIStyle.TEXT],
		[UIStyle.money(fees), tr("Academy cost per month"), UIStyle.TEXT],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _roster_card() -> UICard:
	var card := UICard.new(tr("Academy drivers"), tr("in the academy or placed in a junior seat"))
	var people := Academy.drivers(_team)
	if people.is_empty():
		card.add_padded(_small(tr("No academy driver yet. Sign one from the junior pool on the right.")), 8, 8)
		return card
	for d in people:
		card.add_row(_roster_row(d))
	return card


func _roster_row(d: DriverData) -> HoverRow:
	var row := HoverRow.new()
	var placed := Youth.team_of(d)
	var status := tr("Placed at %s") % placed.name if placed else tr("In the academy, no junior seat")
	var box := _box_with(_name_box(d.full_name(), "%s · %d · %s" % [status, d.age(Calendar.year), d.nationality]), [
		_stars_figure(Knowledge.star_range(d, &"ability", d.overall()), tr("ability")),
		_stars_figure(Knowledge.star_range(d, &"potential", d.potential), tr("potential")),
	])
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	if placed:
		var back := Button.new()
		back.text = tr("Bring back")
		back.pressed.connect(func():
			Academy.bring_back(d)
			shell.refresh_current())
		buttons.add_child(back)
	else:
		var choice := _seat_choice(d)
		buttons.add_child(choice)
		var place := _accent(tr("Place"))
		place.disabled = choice.disabled
		place.pressed.connect(func():
			var t: YouthTeam = GameState.youth_teams[choice.get_item_metadata(choice.selected)]
			_error = Academy.place(_team, d, t)
			shell.refresh_current())
		buttons.add_child(place)
	var release := Button.new()
	release.text = tr("Release")
	release.pressed.connect(func():
		Academy.release(d)
		shell.refresh_current())
	buttons.add_child(release)
	box.add_child(buttons)
	row.add_child(box)
	return row


## A drop-down of the junior teams with a free seat that fit the driver's age.
func _seat_choice(d: DriverData) -> OptionButton:
	var choice := OptionButton.new()
	for t in GameState.youth_teams.values():
		if t.driver_ids.size() < Youth.SEATS and d.age(Calendar.year) <= Youth.max_age(t.series_id):
			choice.add_item("%s (%s)" % [t.name, Youth.SERIES_NAMES[t.series_id]])
			choice.set_item_metadata(choice.item_count - 1, t.id)
	if choice.item_count == 0:
		choice.add_item(tr("No junior seat free for this age"))
		choice.disabled = true
	return choice


## The junior pool: people the academy could sign (no team, young enough).
func _pool_card() -> UICard:
	var card := UICard.new(tr("Junior pool"), tr("sign into the academy"))
	var people: Array[DriverData] = []
	for d in Youth.pool():
		if d.age(Calendar.year) <= Academy.INTAKE_MAX_AGE and d.academy_team_id == &"":
			people.append(d)
	people.sort_custom(func(a, b): return Youth.value(a) > Youth.value(b))
	if people.is_empty():
		card.add_padded(_small(tr("No junior free for the academy right now.")), 8, 8)
		return card
	var free := Academy.free_places(_team)
	for d in people.slice(0, 12):
		card.add_row(_pool_row(d, free))
	return card


func _pool_row(d: DriverData, free: int) -> HoverRow:
	var row := HoverRow.new()
	var box := _box_with(_name_box(d.full_name(), "%d · %s" % [d.age(Calendar.year), d.nationality]), [
		_stars_figure(Knowledge.star_range(d, &"ability", d.overall()), tr("ability")),
		_stars_figure(Knowledge.star_range(d, &"potential", d.potential), tr("potential")),
		_figure(tr(Scouting.recommendation(d)), tr("advice")),
	])
	var sign := _accent(tr("Sign"))
	sign.disabled = free <= 0
	sign.tooltip_text = "" if free > 0 else tr("All academy places are taken.")
	sign.pressed.connect(func():
		_error = Academy.sign(_team, d)
		shell.refresh_current())
	box.add_child(sign)
	row.add_child(box)
	return row


## Top five of both junior championships; our drivers are marked.
func _standings_card() -> UICard:
	var card := UICard.new(tr("Junior championships"), tr("top five drivers this season"))
	for series_id in [Youth.F2, Youth.F3]:
		var rows := Youth.table(series_id)
		var title := Label.new()
		title.text = Youth.SERIES_NAMES[series_id]
		title.theme_type_variation = &"StrongLabel"
		card.add_padded(title, 8, 2)
		if rows.is_empty():
			card.add_padded(_small(tr("The season has not started yet.")), 4, 4)
			continue
		for i in mini(5, rows.size()):
			var d: DriverData = GameState.drivers.get(rows[i][0])
			if not d:
				continue
			var own := d.academy_team_id != &"" and d.academy_team_id == _team.id
			card.add_row(_result_row(i + 1, d, rows[i][1], own))
	return card


func _result_row(position: int, d: DriverData, points: int, own: bool) -> HoverRow:
	var row := HoverRow.new()
	var team: YouthTeam = Youth.team_of(d)
	var line := _box_with(_name_box("P%d  %s" % [position, d.full_name()], team.name if team else ""), [
		_figure("%d" % points, tr("points")),
	])
	if own:
		line.get_child(0).get_child(0).add_theme_color_override("font_color", UIStyle.ACCENT)
	row.add_child(line)
	return row


# --- Helpers -----------------------------------------------------------------

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
