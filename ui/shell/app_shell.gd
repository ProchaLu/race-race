## The main management UI: sidebar, top bar (date, budget, time controls) and
## a content area that shows one screen at a time, with back history.
class_name AppShell
extends Control

## [section id, label, icon]
const NAV_ITEMS := [
	[&"home", "Home", "house"],
	[&"inbox", "Inbox", "inbox"],
	[&"calendar", "Calendar", "calendar"],
	[&"drivers", "Drivers", "user"],
	[&"staff", "Staff", "users"],
	[&"car", "Car development", "car-front"],
	[&"engine", "Engine", "cog"],
	[&"hq", "Headquarters", "building"],
	[&"finances", "Finances", "wallet"],
	[&"sponsors", "Sponsors", "handshake"],
	[&"scouting", "Scouting", "binoculars"],
	[&"academy", "Academy", "graduation-cap"],
	[&"market", "Transfer market", "arrow-left-right"],
	[&"standings", "Standings", "trophy"],
	[&"owner", "Owner", "briefcase"],
]

## Screens that exist so far; every other section shows a placeholder.
const SCREENS := {
	&"home": preload("res://ui/screens/home_screen.gd"),
	&"inbox": preload("res://ui/screens/inbox_screen.gd"),
	&"drivers": preload("res://ui/screens/driver_list_screen.gd"),
	&"driver_profile": preload("res://ui/screens/driver_profile_screen.gd"),
	&"staff": preload("res://ui/screens/staff_list_screen.gd"),
	&"staff_profile": preload("res://ui/screens/staff_profile_screen.gd"),
	&"market": preload("res://ui/screens/market_screen.gd"),
	&"negotiation": preload("res://ui/screens/negotiation_screen.gd"),
	&"calendar": preload("res://ui/screens/calendar_screen.gd"),
	&"standings": preload("res://ui/screens/standings_screen.gd"),
	&"weekend": preload("res://ui/screens/weekend_screen.gd"),
	&"race_result": preload("res://ui/screens/race_result_screen.gd"),
	&"season_review": preload("res://ui/screens/season_review_screen.gd"),
	&"driver_talk": preload("res://ui/screens/driver_talk_screen.gd"),
	&"car": preload("res://ui/screens/car_screen.gd"),
}
const PlaceholderScreen := preload("res://ui/screens/placeholder_screen.gd")
const LANGUAGES := [["en", "English"], ["de", "Deutsch"]]

var _content: Control
var _current: UIScreen
var _history: Array[Dictionary] = []  # [{"id": StringName, "args": Dictionary}]
var _current_entry: Dictionary = {}
var _nav_buttons := {}
var _language_buttons := {}
var _title_label: Label
var _back_button: Button
var _date_label: Label
var _budget_label: Label
var _next_race_label: Label
var _countdown_label: Label
var _mood_block: HoverRow
var _mood_label: Label
var _mood_meter: Meter
var _day_button: Button
var _continue_button: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = ThemeBuilder.shared()


func _ready() -> void:
	var background := ColorRect.new()
	background.color = UIStyle.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)
	layout.add_child(_build_sidebar())

	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 0)
	main.add_child(_build_top_bar())
	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)
	main.add_child(margin)
	layout.add_child(main)

	EventBus.day_passed.connect(func(_d): _refresh_top_bar())
	EventBus.round_completed.connect(func(_r): _refresh_top_bar())
	EventBus.inbox_changed.connect(_refresh_inbox_badge)
	_refresh_top_bar()
	_refresh_inbox_badge()
	navigate(&"home")


func _notification(what: int) -> void:
	# Texts built with tr() must be rebuilt when the language changes.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for code in _language_buttons:
			_language_buttons[code].set_pressed_no_signal(code == GameSettings.locale())
		_refresh_top_bar()
		_refresh_inbox_badge()
		if not _current_entry.is_empty():
			navigate(_current_entry.id, _current_entry.args, false)


## Opens a screen. Pass add_history = false when going back or refreshing.
func navigate(id: StringName, args: Dictionary = {}, add_history: bool = true) -> void:
	if add_history and not _current_entry.is_empty():
		_history.append(_current_entry)
	_current_entry = {"id": id, "args": args}
	if _current:
		_current.queue_free()
	# Values like the team mood can change through actions on any screen.
	if is_node_ready():
		_refresh_top_bar()

	var script: GDScript = SCREENS.get(id, PlaceholderScreen)
	_current = script.new()
	_current.shell = self
	if script == PlaceholderScreen:
		args = args.merged({"section": id, "label": _nav_label(id), "icon": _nav_icon(id)})
	_current.setup(args)
	_content.add_child(_current)

	_title_label.text = _current.screen_title()
	_back_button.disabled = _history.is_empty()
	var section := _current.nav_section()
	for key in _nav_buttons:
		_nav_buttons[key].set_pressed_no_signal(key == section)


## End-of-season overlay for a finished season.
func show_season_summary(year: int) -> void:
	for review in GameState.season_history:
		if review.year == year:
			add_child(SeasonSummary.new(review, self))
			return


func go_back() -> void:
	if _history.is_empty():
		return
	var entry: Dictionary = _history.pop_back()
	navigate(entry.id, entry.args, false)


func open_driver(driver_id: StringName) -> void:
	navigate(&"driver_profile", {"driver_id": driver_id})


func open_staff(staff_id: StringName) -> void:
	navigate(&"staff_profile", {"staff_id": staff_id})


## Remembers state of the current screen (e.g. a selection) for "back".
func update_args(args: Dictionary) -> void:
	_current_entry.args = _current_entry.args.merged(args, true)


## Re-opens the current screen with fresh data (after time passed).
func refresh_current() -> void:
	navigate(_current_entry.id, _current_entry.args, false)


# --- Time controls -----------------------------------------------------------

func _on_next_day() -> void:
	if not Season.weekend_pending():
		Season.advance_one_day()
	_after_time_passed()


func _on_continue() -> void:
	if not Season.weekend_pending():
		Season.continue_to_next_event()
	_after_time_passed()


func _after_time_passed() -> void:
	_refresh_top_bar()
	# New season: the review of the old one comes up once.
	if GameState.pending_summary >= 0:
		var year := GameState.pending_summary
		GameState.pending_summary = -1
		show_season_summary(year)
	# Race day: time waits until the weekend has been raced.
	if Season.weekend_pending():
		navigate(&"weekend", {}, _current_entry.get("id") != &"weekend")
		return
	# Open the newest unread important message, otherwise refresh the screen.
	for i in range(GameState.inbox.size() - 1, -1, -1):
		var msg := GameState.inbox[i]
		if not msg.read and msg.priority == InboxMessage.Priority.IMPORTANT:
			navigate(&"inbox", {"message": msg}, _current_entry.get("id") != &"inbox")
			return
	refresh_current()


# --- Building ----------------------------------------------------------------

func _build_sidebar() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Sidebar"
	panel.custom_minimum_size.x = 250
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)

	# Team header with colour stripe
	var team := GameState.player_team()
	var header := PanelContainer.new()
	var header_style := UIStyle.box(UIStyle.SIDEBAR, team.primary_color, 0, 20, 18)
	header_style.border_width_left = 4
	header.add_theme_stylebox_override("panel", header_style)
	var header_text := VBoxContainer.new()
	header_text.add_theme_constant_override("separation", 0)
	var team_name := Label.new()
	team_name.text = team.name
	team_name.uppercase = true
	team_name.theme_type_variation = &"HeadingLabel"
	team_name.add_theme_font_size_override("font_size", 22)
	header_text.add_child(team_name)
	var series_label := Label.new()
	series_label.text = GameState.series[team.series_id].name
	series_label.theme_type_variation = &"SmallLabel"
	header_text.add_child(series_label)
	header.add_child(header_text)
	column.add_child(header)
	column.add_child(HSeparator.new())

	var group := ButtonGroup.new()
	group.allow_unpress = false
	for item in NAV_ITEMS:
		var button := Button.new()
		button.text = item[1]
		button.icon = UIStyle.icon(item[2])
		button.theme_type_variation = &"NavButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		var id: StringName = item[0]
		button.pressed.connect(func(): navigate(id))
		column.add_child(button)
		_nav_buttons[id] = button

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(_build_language_switch())
	return panel


func _build_language_switch() -> Control:
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	var caption := Label.new()
	caption.text = "Language"
	caption.uppercase = true
	caption.theme_type_variation = &"TinyLabel"
	column.add_child(caption)
	var row := HBoxContainer.new()
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for lang in LANGUAGES:
		var button := Button.new()
		button.text = lang[1]
		# Language names are always shown in their own language.
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_pressed_no_signal(GameSettings.locale() == lang[0])
		var code: String = lang[0]
		button.pressed.connect(func(): GameSettings.set_locale(code))
		row.add_child(button)
		_language_buttons[code] = button
	column.add_child(row)
	margin.add_child(column)
	return margin


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.theme_type_variation = &"TopBar"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bar.add_child(row)

	_back_button = Button.new()
	_back_button.icon = UIStyle.icon("chevron-left")
	_back_button.theme_type_variation = &"FlatButton"
	_back_button.tooltip_text = "Back"
	_back_button.pressed.connect(go_back)
	row.add_child(_back_button)

	_title_label = Label.new()
	_title_label.theme_type_variation = &"HeadingLabel"
	_title_label.uppercase = true
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Long titles are cut instead of pushing the whole layout wider.
	_title_label.clip_text = true
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_title_label)

	# Fixed widths so the bar never shifts when values change.
	_next_race_label = _add_top_info(row, "Next race", "trophy", 200)
	_countdown_label = Label.new()
	_countdown_label.theme_type_variation = &"StrongLabel"
	_countdown_label.add_theme_color_override("font_color", UIStyle.ACCENT)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.custom_minimum_size.x = 90
	var countdown := PanelContainer.new()
	countdown.add_theme_stylebox_override("panel",
		UIStyle.box(Color(UIStyle.ACCENT, 0.12), Color(UIStyle.ACCENT, 0.5), 1, 10, 4))
	countdown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	countdown.add_child(_countdown_label)
	row.add_child(countdown)
	row.add_child(_top_separator())
	_budget_label = _add_top_info(row, "Budget", "wallet", 110)
	row.add_child(_top_separator())
	row.add_child(_build_mood_block())
	row.add_child(_top_separator())
	_date_label = _add_top_info(row, "Date", "calendar", 160)
	row.add_child(_top_separator())

	var time_controls := HBoxContainer.new()
	time_controls.add_theme_constant_override("separation", 8)
	_day_button = Button.new()
	_day_button.text = "+1 day"
	_day_button.icon = UIStyle.icon("calendar")
	_day_button.tooltip_text = "Advance exactly one day"
	_day_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_day_button.custom_minimum_size.x = 110
	_day_button.pressed.connect(_on_next_day)
	time_controls.add_child(_day_button)
	_continue_button = Button.new()
	_continue_button.icon = UIStyle.icon("play")
	_continue_button.theme_type_variation = &"AccentButton"
	_continue_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_button.tooltip_text = "Advance until the next important event"
	_continue_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_continue_button.custom_minimum_size.x = 160
	_continue_button.pressed.connect(_on_continue)
	time_controls.add_child(_continue_button)
	row.add_child(time_controls)
	return bar


## Info block: icon, small caption and a large value. Returns the value label.
## value_width keeps the block the same size whatever the value is.
func _add_top_info(row: HBoxContainer, caption: String, icon_name: String, value_width: int) -> Label:
	var block := HBoxContainer.new()
	block.add_theme_constant_override("separation", 10)
	block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := TextureRect.new()
	icon.texture = UIStyle.icon(icon_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(22, 22)
	icon.modulate = UIStyle.MUTED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	block.add_child(icon)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -2)
	column.custom_minimum_size.x = value_width
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.uppercase = true
	caption_label.theme_type_variation = &"SectionLabel"
	caption_label.add_theme_font_size_override("font_size", 13)
	column.add_child(caption_label)
	var value := Label.new()
	value.theme_type_variation = &"StrongLabel"
	value.add_theme_font_size_override("font_size", 18)
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value.clip_text = true
	column.add_child(value)
	block.add_child(column)
	row.add_child(block)
	return value


## Team mood block (decision 42): level and value, a small meter and the
## full breakdown as tooltip. Fixed width like the other blocks.
func _build_mood_block() -> Control:
	_mood_block = HoverRow.new(&"TopInfo", &"TopInfoHover")
	_mood_block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var block := HBoxContainer.new()
	block.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.texture = UIStyle.icon("users")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(22, 22)
	icon.modulate = UIStyle.MUTED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	block.add_child(icon)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -2)
	column.custom_minimum_size.x = 120
	var caption := Label.new()
	caption.text = "Team mood"
	caption.uppercase = true
	caption.theme_type_variation = &"SectionLabel"
	caption.add_theme_font_size_override("font_size", 13)
	column.add_child(caption)
	_mood_label = Label.new()
	_mood_label.theme_type_variation = &"StrongLabel"
	_mood_label.add_theme_font_size_override("font_size", 18)
	_mood_label.clip_text = true
	column.add_child(_mood_label)
	_mood_meter = Meter.new(0, UIStyle.OK, 4)
	column.add_child(_mood_meter)
	block.add_child(column)
	_mood_block.add_child(block)
	return _mood_block


func _top_separator() -> VSeparator:
	var line := VSeparator.new()
	line.custom_minimum_size.y = 36
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line


func _refresh_top_bar() -> void:
	_date_label.text = Calendar.format_date()
	var budget := GameState.player_team().budget
	_budget_label.text = UIStyle.money(budget)
	_budget_label.add_theme_color_override("font_color", UIStyle.money_color(budget))
	var race_day := Season.weekend_pending()
	_continue_button.text = tr("Race weekend").to_upper() if race_day else tr("Continue").to_upper()
	_continue_button.tooltip_text = "Open today's race weekend" if race_day else "Advance until the next important event"
	_day_button.disabled = race_day
	var mood := TeamMood.value(GameState.player_team_id)
	var mood_color := UIStyle.mood_color(mood)
	_mood_label.text = "%s · %d" % [tr(TeamMood.level_name(mood)), mood]
	_mood_label.add_theme_color_override("font_color", mood_color)
	_mood_meter.set_value(mood, mood_color)
	_mood_block.set_breakdown(TeamMood.breakdown(GameState.player_team_id))
	var next := GameState.next_round_index()
	if next == -1:
		_next_race_label.text = tr("Season finished")
		_countdown_label.get_parent().visible = false
		return
	var s: SeriesData = GameState.series[GameState.player_team().series_id]
	var track: TrackData = GameState.tracks[s.calendar[next]]
	var days := s.race_days[next] - Calendar.day
	_next_race_label.text = "R%d · %s" % [next + 1, track.name.trim_suffix(" Grand Prix")]
	_countdown_label.text = tr("today") if days <= 0 else (tr("tomorrow") if days == 1 else tr("in %d days") % days)
	_countdown_label.get_parent().visible = true


func _refresh_inbox_badge() -> void:
	var unread := GameState.unread_count()
	var button: Button = _nav_buttons[&"inbox"]
	button.text = tr("Inbox") + ("  (%d)" % unread if unread > 0 else "")


func _nav_label(id: StringName) -> String:
	for item in NAV_ITEMS:
		if item[0] == id:
			return item[1]
	return str(id)


func _nav_icon(id: StringName) -> String:
	for item in NAV_ITEMS:
		if item[0] == id:
			return item[2]
	return "check"
