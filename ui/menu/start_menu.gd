## Start menu (R8a): new game – take over one of the eleven teams or found a
## twelfth team. Emits start_game with the options for TestWorld.new_game().
class_name StartMenu
extends Control

signal start_game(options: Dictionary)

const LANGUAGES := [["en", "English"], ["de", "Deutsch"]]

var _page: StringName = &"title"
var _root: VBoxContainer
## Take over: chosen team id.
var _team_id: StringName = &""
## Found: the form.
var _found := {"name": TeamFounding.DEFAULT_NAME, "short_name": TeamFounding.short_from(TeamFounding.DEFAULT_NAME),
	"color": TeamFounding.COLORS[0], "manufacturer": &""}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = ThemeBuilder.shared()


func _ready() -> void:
	var background := ColorRect.new()
	background.color = UIStyle.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 80)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", UIStyle.GAP)
	margin.add_child(_root)
	var choices := TeamFounding.engine_choices()
	if not choices.is_empty():
		_found.manufacturer = choices[0][0]
	_team_id = TestWorld.TEAMS[0][0]
	_show(&"title")


func _notification(what: int) -> void:
	# Texts built with tr() must be rebuilt when the language changes.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_show(_page)


## Opens a page: title, mode, existing or found.
func show_page(page: StringName) -> void:
	_show(page)


func _show(page: StringName) -> void:
	_page = page
	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	match page:
		&"title":
			_title_page()
		&"mode":
			_mode_page()
		&"existing":
			_existing_page()
		&"found":
			_found_page()


# --- Title -------------------------------------------------------------------

func _title_page() -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(spacer)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var title := Label.new()
	title.text = "RACE RACE"
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UIStyle.font(&"display"))
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", UIStyle.ACCENT)
	center.add_child(title)
	var sub := Label.new()
	sub.text = "A team principal game – Formula Apex"
	sub.theme_type_variation = &"MutedLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size.y = 28
	center.add_child(gap)
	var new_game := _menu_button("New game", true)
	new_game.pressed.connect(func(): _show(&"mode"))
	center.add_child(new_game)
	var cont := _menu_button("Continue", false)
	cont.disabled = true
	cont.tooltip_text = "Saving and loading come in a later version."
	center.add_child(cont)
	var quit := _menu_button("Quit", false)
	quit.pressed.connect(func(): get_tree().quit())
	center.add_child(quit)
	_root.add_child(center)
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(spacer2)
	_root.add_child(_language_switch())


func _menu_button(text: String, accent: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 48)
	if accent:
		b.theme_type_variation = &"AccentButton"
	return b


func _language_switch() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for lang in LANGUAGES:
		var button := Button.new()
		button.text = lang[1]
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.x = 110
		button.set_pressed_no_signal(GameSettings.locale() == lang[0])
		var code: String = lang[0]
		button.pressed.connect(func(): GameSettings.set_locale(code))
		row.add_child(button)
	return row


# --- Mode --------------------------------------------------------------------

func _mode_page() -> void:
	_root.add_child(_header("New game", &"title"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_mode_card("Take over a team",
		"Lead one of the eleven teams of the field. Every team has its own budget, car, drivers and an owner with goals – from title contender to backmarker.",
		&"existing"))
	row.add_child(_mode_card("Found your own team",
		"Enter the field as the 12th team (24 cars). You choose the name, the colour and the engine – and start small: basic campus, customer engine, modest staff. As co-founder you cannot be dismissed.",
		&"found"))
	_root.add_child(row)


func _mode_card(title: String, text: String, page: StringName) -> UICard:
	var card := UICard.new(tr(title))
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_padded(_small(tr(text)), 12, 12)
	var b := Button.new()
	b.text = tr(title)
	b.theme_type_variation = &"AccentButton"
	b.pressed.connect(func(): _show(page))
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(b)
	card.add_padded(box, 8, 12)
	return card


# --- Take over a team --------------------------------------------------------

func _existing_page() -> void:
	_root.add_child(_header("Take over a team", &"mode"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_card := UICard.new(tr("Teams"), tr("sorted by reputation"))
	list_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var group := ButtonGroup.new()
	var teams: Array = TestWorld.TEAMS.duplicate()
	teams.sort_custom(func(a, b): return a[4] > b[4])
	for t in teams:
		var b := Button.new()
		b.text = "%s   ·   %s" % [t[1], tr(_tier_text(_expected(t[0])))]
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.button_group = group
		b.icon = _swatch(t[3])
		_true_icon_colors(b)
		b.set_pressed_no_signal(t[0] == _team_id)
		var id: StringName = t[0]
		b.pressed.connect(func():
			_team_id = id
			_show(&"existing"))
		list_card.add_padded(b, 2, 2)
	row.add_child(list_card)
	row.add_child(_team_detail(_team_id))
	_root.add_child(row)


func _team_detail(id: StringName) -> UICard:
	var t: Array = []
	for entry in TestWorld.TEAMS:
		if entry[0] == id:
			t = entry
	var card := UICard.new(t[1], tr(_tier_text(_expected(id))))
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_row(FactRow.new(tr("Budget"), UIStyle.money(t[5] * 1_000_000), "", true))
	card.add_row(FactRow.new(tr("Team reputation"), "%d" % t[4], "", true))
	card.add_row(FactRow.new(tr("Car rating"), "%d" % t[4], tr("P%d of 11") % _expected(id), true))
	card.add_row(FactRow.new(tr("Engine"), _engine_of(id), "", true))
	var drivers := []
	for d in TestWorld.DRIVERS:
		if d[7] == id:
			drivers.append("%s %s" % [d[2], d[3]])
	card.add_row(FactRow.new(tr("Drivers"), ", ".join(drivers), "", false))
	card.add_row(FactRow.new(tr("What the owner expects"), tr("about P%d") % _expected(id), "", true))
	card.add_padded(_small(tr("The season starts on 1 January. The first race is in March.")), 8, 4)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_END
	var start := Button.new()
	start.text = tr("Start the career")
	start.theme_type_variation = &"AccentButton"
	start.pressed.connect(func(): start_game.emit({"mode": "existing", "team_id": id}))
	box.add_child(start)
	card.add_padded(box, 8, 12)
	return card


## Expected position from the team's level (rank among the eleven).
func _expected(id: StringName) -> int:
	var level := 0
	for t in TestWorld.TEAMS:
		if t[0] == id:
			level = t[4]
	var rank := 1
	for t in TestWorld.TEAMS:
		if t[4] > level:
			rank += 1
	return rank


func _tier_text(position: int) -> String:
	if position <= 3:
		return "Title contender"
	if position <= 7:
		return "Midfield"
	return "Backmarker"


func _engine_of(id: StringName) -> String:
	for e in Engines.START:
		if e[4] == id:
			return "%s (%s)" % [e[1], tr("works")]
		if e[8].has(id):
			return "%s (%s)" % [e[1], tr("customer")]
	return "—"


# --- Found a team ------------------------------------------------------------

func _found_page() -> void:
	_root.add_child(_header("Found your own team", &"mode"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_found_form())
	row.add_child(_found_summary())
	_root.add_child(row)


func _found_form() -> UICard:
	var card := UICard.new(tr("Your team"))
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_section(tr("Team name"))
	var name_edit := LineEdit.new()
	name_edit.text = _found.name
	name_edit.max_length = 28
	name_edit.text_changed.connect(func(text: String):
		var old_short := TeamFounding.short_from(_found.name)
		_found.name = text
		if _found.short_name == old_short:
			_found.short_name = TeamFounding.short_from(text)
		_refresh_found_summary())
	card.add_padded(name_edit, 4, 8)
	card.add_section(tr("Short name (3 letters)"))
	var short_edit := LineEdit.new()
	short_edit.name = "ShortEdit"
	short_edit.text = _found.short_name
	short_edit.max_length = 3
	short_edit.text_changed.connect(func(text: String):
		_found.short_name = text.to_upper()
		_refresh_found_summary())
	card.add_padded(short_edit, 4, 8)
	card.add_section(tr("Team colour"))
	var colors := HFlowContainer.new()
	colors.add_theme_constant_override("h_separation", 6)
	var group := ButtonGroup.new()
	for c in TeamFounding.COLORS:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.icon = _swatch(c, 22)
		_true_icon_colors(b)
		b.custom_minimum_size = Vector2(44, 36)
		b.set_pressed_no_signal(c == _found.color)
		var color: Color = c
		b.pressed.connect(func():
			_found.color = color
			_refresh_found_summary())
		colors.add_child(b)
	card.add_padded(colors, 4, 8)
	card.add_section(tr("Engine supplier (customer engine)"))
	var engines := ButtonGroup.new()
	for e in TeamFounding.engine_choices():
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = engines
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = "%s  ·  %s %s  ·  %s %d" % [e[1], UIStyle.money(e[2]), tr("per year"), tr("power"), e[3][0]]
		b.set_pressed_no_signal(e[0] == _found.manufacturer)
		var id: StringName = e[0]
		b.pressed.connect(func():
			_found.manufacturer = id
			_refresh_found_summary())
		card.add_padded(b, 2, 2)
	card.add_padded(Control.new(), 4, 4)
	return card


func _found_summary() -> UICard:
	var card := UICard.new(tr("Start"), tr("12th team · 24 cars"))
	card.name = "FoundSummary"
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_fill_found_summary(card)
	return card


func _fill_found_summary(card: UICard) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var swatch := TextureRect.new()
	swatch.texture = _swatch(_found.color, 32)
	swatch.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	head.add_child(swatch)
	var title := Label.new()
	title.text = "%s  (%s)" % [String(_found.name).strip_edges(), _found.short_name]
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.theme_type_variation = &"HeadingLabel"
	head.add_child(title)
	card.add_padded(head, 10, 8)
	card.add_row(FactRow.new(tr("Budget"), UIStyle.money(TeamFounding.START_BUDGET), tr("from your backer"), true))
	card.add_row(FactRow.new(tr("Team reputation"), "%d" % TeamFounding.START_REPUTATION, tr("the lowest in the field"), true))
	card.add_row(FactRow.new(tr("Car rating"), "%d" % TeamFounding.CAR_LEVEL, tr("a first car, built in a hurry"), true))
	card.add_row(FactRow.new(tr("Campus"), tr("basic buildings"), tr("level 1"), true))
	card.add_row(FactRow.new(tr("Staff"), tr("modest"), tr("about %d") % TeamFounding.STAFF_LEVEL, true))
	card.add_row(FactRow.new(tr("Drivers"), tr("two free drivers, two seasons"), tr("signed by the sporting director"), true))
	card.add_row(FactRow.new(tr("Owner"), tr("a patient backer"), tr("you cannot be dismissed"), true))
	var problem := TeamFounding.check_options(_found)
	if problem != "":
		var warn := _small(tr(problem))
		warn.add_theme_color_override("font_color", UIStyle.BAD)
		card.add_padded(warn, 8, 4)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_END
	var start := Button.new()
	start.text = tr("Found the team")
	start.theme_type_variation = &"AccentButton"
	start.disabled = problem != ""
	start.pressed.connect(func():
		var options := _found.duplicate()
		options.mode = "found"
		options.name = String(options.name).strip_edges()
		start_game.emit(options))
	box.add_child(start)
	card.add_padded(box, 8, 12)


## Rebuilds only the summary, so the text fields keep the focus while typing.
func _refresh_found_summary() -> void:
	var card := find_child("FoundSummary", true, false) as UICard
	if not card:
		return
	for child in card.body.get_children():
		card.body.remove_child(child)
		child.queue_free()
	_fill_found_summary(card)
	var short_edit := find_child("ShortEdit", true, false) as LineEdit
	if short_edit and short_edit.text != _found.short_name and not short_edit.has_focus():
		short_edit.text = _found.short_name


# --- Helpers -----------------------------------------------------------------

func _header(title: String, back: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var b := Button.new()
	b.icon = UIStyle.icon("chevron-left")
	b.tooltip_text = "Back"
	b.pressed.connect(func(): _show(back))
	row.add_child(b)
	var label := Label.new()
	label.text = title
	label.uppercase = true
	label.theme_type_variation = &"HeadingLabel"
	row.add_child(label)
	return row


## Colour swatches keep their real colour in every button state.
func _true_icon_colors(b: Button) -> void:
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)


func _swatch(color: Color, size_px: int = 14) -> Texture2D:
	var img := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
