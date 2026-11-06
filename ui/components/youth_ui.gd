## Small building blocks shared by the youth screens (academy, scouting,
## junior profile): name column, figures, star ranges, buttons.
class_name YouthUI
extends RefCounted


static func accent(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = &"AccentButton"
	return b


static func button(text: String, on_press: Callable, disabled_reason: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled_reason != ""
	b.tooltip_text = disabled_reason
	b.pressed.connect(on_press)
	return b


static func small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func error(text: String) -> Label:
	var label := small(text)
	label.add_theme_color_override("font_color", UIStyle.BAD)
	return label


static func name_box(title: String, sub: String, title_color: Color = Color(0, 0, 0, 0)) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	var name_label := Label.new()
	name_label.text = title
	name_label.theme_type_variation = &"StrongLabel"
	if title_color.a > 0:
		name_label.add_theme_color_override("font_color", title_color)
	column.add_child(name_label)
	var sub_label := Label.new()
	sub_label.text = sub
	sub_label.theme_type_variation = &"SmallLabel"
	column.add_child(sub_label)
	return column


## One row of figures: the name column first, then the figures.
static func box_with(first: Control, figures: Array) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(first)
	for figure_control in figures:
		box.add_child(figure_control)
	return box


static func figure(value: String, caption: String, color: Color = Color(0, 0, 0, 0)) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var number := Label.new()
	number.text = value
	number.theme_type_variation = &"NumberLabel"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if color.a > 0:
		number.add_theme_color_override("font_color", color)
	column.add_child(number)
	var label := Label.new()
	label.text = caption
	label.theme_type_variation = &"SmallLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(label)
	return column


## A star range as a figure (the same star display as the market).
static func stars_figure(stars: Vector2, caption: String) -> VBoxContainer:
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


static func ability_stars(d: DriverData) -> VBoxContainer:
	return stars_figure(Knowledge.star_range(d, &"ability", d.overall()), TranslationServer.translate("ability"))


static func potential_stars(d: DriverData) -> VBoxContainer:
	return stars_figure(Knowledge.star_range(d, &"potential", d.potential), TranslationServer.translate("potential"))


## Where a junior races now: "Hallen GP · Apex F2", "Karting Europe", "No seat".
static func where(d: DriverData) -> String:
	var t := Youth.team_of(d)
	if t:
		return "%s · %s" % [t.name, Youth.SERIES_NAMES[t.series_id]]
	if d.loan_from != &"":
		var f1: TeamData = GameState.teams.get(d.team_id)
		return TranslationServer.translate("On loan at %s") % (f1.name if f1 else "–")
	if Youth.is_karting(d):
		return TranslationServer.translate(Youth.series_name(Youth.series_key(d)))
	return TranslationServer.translate("No seat")


## The academy a junior belongs to ("" = none).
static func academy_name(d: DriverData) -> String:
	var t: TeamData = GameState.teams.get(d.academy_team_id)
	return t.name if t else ""


## Watchlist star toggle.
static func watch_button(d: DriverData, on_change: Callable) -> Button:
	var b := Button.new()
	var on := GameState.shortlist.has(d.id)
	b.text = "★" if on else "☆"
	b.tooltip_text = TranslationServer.translate("Remove from the watchlist" if on else "Add to the watchlist")
	b.add_theme_color_override("font_color", UIStyle.ACCENT if on else UIStyle.MUTED)
	b.pressed.connect(func():
		GameState.toggle_shortlist(d.id)
		on_change.call())
	return b


static func mood_color(morale: int) -> Color:
	if morale >= 60:
		return UIStyle.GOOD
	if morale >= 40:
		return UIStyle.TEXT
	return UIStyle.BAD


## A drop-down of the junior teams that fit the driver, F2 first and the
## strongest first: a free seat costs the placement fee, a taken one is bought.
static func seat_choice(team: TeamData, d: DriverData) -> OptionButton:
	var choice := OptionButton.new()
	choice.fit_to_longest_item = false
	choice.clip_text = true
	choice.custom_minimum_size.x = 210
	var teams := GameState.youth_teams.values()
	teams.sort_custom(func(a, b):
		if a.series_id != b.series_id:
			return a.series_id == Youth.F2
		return a.strength > b.strength)
	var first_reason := ""
	for t in teams:
		var offer := Academy.seat_offer(team, d, t)
		if offer.reason != "":
			if first_reason == "":
				first_reason = offer.reason
			continue
		var seat_text: String = TranslationServer.translate("free seat") if offer.replaces == null \
			else TranslationServer.translate("replaces %s") % offer.replaces.full_name()
		choice.add_item("%s %s · %s · %s" % [Youth.SERIES_NAMES[t.series_id].trim_prefix("Apex "), t.name,
			UIStyle.money(offer.cost), seat_text])
		choice.set_item_metadata(choice.item_count - 1, t.id)
		choice.set_item_tooltip(choice.item_count - 1, TranslationServer.translate("Team strength %d. Cost this season: %s.")
			% [t.strength, UIStyle.money(offer.cost)])
	if choice.item_count == 0:
		choice.add_item(TranslationServer.translate(first_reason) if first_reason != "" else "–")
		choice.disabled = true
	return choice
