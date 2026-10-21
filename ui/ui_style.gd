## Central "Pit Wall" design tokens: colours, fonts, sizes and small helpers.
## Change the look of the whole game here (and in ThemeBuilder).
class_name UIStyle
extends RefCounted

# --- Palette ---
const BG := Color("0e1216")
const PANEL := Color("141a20")
const PANEL_DARK := Color("10151a")
const SIDEBAR := Color("0b0e12")
const TOOLTIP_BG := Color("0a0d10")
const TEXT := Color("dfe5ea")
const MUTED := Color("7f8b96")
const FAINT := Color("56616c")
const LINE := Color("232c35")
const LINE_STRONG := Color("34404b")
const ZEBRA := Color("171e25")
const HOVER := Color("1d2731")
const ACCENT := Color("f2a93b")

# Value scale colours (1-5, 6-10, 11-15, 16-20) and their semantic aliases.
const LV1 := Color("ef5b5b")
const LV2 := Color("e0a13a")
const LV3 := Color("8fc46a")
const LV4 := Color("4fd1a5")
const GOOD := LV4
const OK := LV3
const WARN := LV2
const BAD := LV1

# --- Sizes ---
const RADIUS := 2
const GAP := 14
const ROW_PAD_X := 16
const FONT_SIZE := 15

const FONT_DIR := "res://assets/fonts/"
const ICON_DIR := "res://assets/icons/"

static var _fonts: Dictionary = {}


## Fonts by role: display, display_semibold, body, body_semibold, tabular,
## mono, mono_semibold.
static func font(role: StringName) -> Font:
	if _fonts.is_empty():
		_load_fonts()
	return _fonts[role]


static func _load_fonts() -> void:
	_fonts[&"display"] = load(FONT_DIR + "BarlowCondensed-Bold.ttf")
	_fonts[&"display_semibold"] = load(FONT_DIR + "BarlowCondensed-SemiBold.ttf")
	var plex: Font = load(FONT_DIR + "IBMPlexSans-Variable.ttf")
	_fonts[&"body"] = _weighted(plex, 400)
	_fonts[&"body_semibold"] = _weighted(plex, 600)
	# Same face with equal-width digits, so numbers line up in columns.
	var tabular := _weighted(plex, 600)
	tabular.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
	_fonts[&"tabular"] = tabular
	var mono: Font = load(FONT_DIR + "JetBrainsMono-Variable.ttf")
	_fonts[&"mono"] = _weighted(mono, 400)
	_fonts[&"mono_semibold"] = _weighted(mono, 600)


## Picks a weight from a variable font.
static func _weighted(base: Font, weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = base
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f


static func icon(icon_name: String) -> Texture2D:
	return load(ICON_DIR + icon_name + ".svg")


## Portrait of a person in their team's colours. width_px: 5:6 aspect ratio.
static func portrait(person: PersonData, width_px: int) -> Texture2D:
	var team: TeamData = GameState.teams.get(person.team_id)
	var color := team.primary_color if team else UIStyle.LINE_STRONG
	return PortraitGenerator.texture(person, color, width_px)


## Colour for a value on the 1-20 display scale.
static func value_color(display_value: int) -> Color:
	if display_value <= 5:
		return LV1
	if display_value <= 10:
		return LV2
	if display_value <= 15:
		return LV3
	return LV4


## Colour for a 0-100 meter (morale, fitness, ...).
static func meter_color(value: float) -> Color:
	if value >= 75.0:
		return GOOD
	if value >= 50.0:
		return OK
	if value >= 30.0:
		return WARN
	return BAD


static func tone_color(tone: Breakdown.Tone) -> Color:
	match tone:
		Breakdown.Tone.POSITIVE:
			return GOOD
		Breakdown.Tone.NEGATIVE:
			return BAD
	return TEXT


## Flat style box with the game's corner radius.
static func box(bg: Color, border: Color = Color.TRANSPARENT, border_width: int = 0,
		margin_x: float = 0.0, margin_y: float = 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = margin_x
	sb.content_margin_right = margin_x
	sb.content_margin_top = margin_y
	sb.content_margin_bottom = margin_y
	return sb


## Green for money you have or gain, red for debt or losses.
static func money_color(amount: int) -> Color:
	if amount > 0:
		return GOOD
	if amount < 0:
		return BAD
	return TEXT


## "$4.2M", "$250,000", "$310M".
static func money(amount: int) -> String:
	var a := absi(amount)
	var prefix := "-$" if amount < 0 else "$"
	if a >= 100_000_000:
		return "%s%dM" % [prefix, roundi(a / 1_000_000.0)]
	if a >= 1_000_000:
		return "%s%.1fM" % [prefix, a / 1_000_000.0]
	return prefix + _thousands(a)


static func _thousands(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out


## Makes a control and all its descendants transparent to the mouse, so the
## parent row receives hover and tooltip events.
static func ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_mouse(child)
