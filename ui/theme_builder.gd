## Builds the global Godot Theme from the UIStyle tokens.
## Type variations (e.g. "CardTitle", "NavButton") are assigned to controls
## via theme_type_variation.
class_name ThemeBuilder
extends RefCounted


static var _shared: Theme


## The game's theme, built once. Assign it to every root UI control
## (themes only propagate through Control/Window parents).
static func shared() -> Theme:
	if not _shared:
		_shared = build()
	return _shared


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = UIStyle.font(&"body")
	t.default_font_size = UIStyle.FONT_SIZE
	_labels(t)
	_panels(t)
	_buttons(t)
	_tree(t)
	_scrollbars(t)
	_misc(t)
	return t


static func _labels(t: Theme) -> void:
	t.set_color(&"font_color", &"Label", UIStyle.TEXT)
	_label(t, &"MutedLabel", UIStyle.MUTED, null, 15)
	_label(t, &"SmallLabel", UIStyle.MUTED, null, 13)
	_label(t, &"StrongLabel", UIStyle.TEXT, UIStyle.font(&"body_semibold"), 15)
	_label(t, &"NumberLabel", UIStyle.TEXT, UIStyle.font(&"tabular"), 15)
	_label(t, &"MonoLabel", UIStyle.TEXT, UIStyle.font(&"mono_semibold"), 15)
	_label(t, &"ValueLabel", UIStyle.TEXT, UIStyle.font(&"body_semibold"), 19)
	_label(t, &"CardTitle", UIStyle.ACCENT, UIStyle.font(&"display"), 17)
	_label(t, &"SectionLabel", UIStyle.MUTED, UIStyle.font(&"display_semibold"), 14)
	_label(t, &"TinyLabel", UIStyle.MUTED, UIStyle.font(&"display_semibold"), 12)
	_label(t, &"ResultLabel", UIStyle.TEXT, UIStyle.font(&"display"), 24)
	_label(t, &"BigNumber", UIStyle.TEXT, UIStyle.font(&"display"), 36)
	_label(t, &"HeadingLabel", UIStyle.TEXT, UIStyle.font(&"display"), 28)
	_label(t, &"NameLabel", UIStyle.TEXT, UIStyle.font(&"display"), 40)


static func _label(t: Theme, type_name: StringName, color: Color, font: Font, size: int) -> void:
	t.set_type_variation(type_name, &"Label")
	t.set_color(&"font_color", type_name, color)
	if font:
		t.set_font(&"font", type_name, font)
	t.set_font_size(&"font_size", type_name, size)


static func _panels(t: Theme) -> void:
	var x := UIStyle.ROW_PAD_X
	_panel(t, &"Card", UIStyle.box(UIStyle.PANEL, UIStyle.LINE, 1))
	_panel(t, &"RowPlain", UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, x, 4))
	_panel(t, &"RowZebra", UIStyle.box(UIStyle.ZEBRA, Color.TRANSPARENT, 0, x, 4))
	_panel(t, &"RowHover", UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, x, 4))
	var selected := UIStyle.box(Color(UIStyle.ACCENT, 0.14), UIStyle.ACCENT, 0, x, 4)
	selected.border_width_left = 3
	_panel(t, &"RowSelected", selected)
	_panel(t, &"Tile", UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, x, 10))
	_panel(t, &"TopInfo", UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 6, 4))
	_panel(t, &"TopInfoHover", UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, 6, 4))
	_panel(t, &"TileHover", UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, x, 10))
	_panel(t, &"ValueBox", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1, 4, 1))
	_panel(t, &"ResultBox", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE, 1, 4, 8))
	_panel(t, &"ResultBoxHover", UIStyle.box(UIStyle.HOVER, UIStyle.LINE_STRONG, 1, 4, 8))
	_panel(t, &"TraitBox", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE, 1, 8, 4))
	_panel(t, &"TraitBoxHover", UIStyle.box(UIStyle.HOVER, UIStyle.LINE_STRONG, 1, 8, 4))

	var sidebar := UIStyle.box(UIStyle.SIDEBAR)
	sidebar.border_width_right = 1
	sidebar.border_color = UIStyle.LINE
	_panel(t, &"Sidebar", sidebar)

	var top_bar := UIStyle.box(UIStyle.PANEL, Color.TRANSPARENT, 0, 20, 10)
	top_bar.border_width_bottom = 1
	top_bar.border_color = UIStyle.LINE
	_panel(t, &"TopBar", top_bar)

	t.set_stylebox(&"panel", &"TooltipPanel",
		UIStyle.box(UIStyle.TOOLTIP_BG, UIStyle.ACCENT, 1, 12, 10))
	t.set_color(&"font_color", &"TooltipLabel", UIStyle.TEXT)


static func _panel(t: Theme, type_name: StringName, style: StyleBox) -> void:
	t.set_type_variation(type_name, &"PanelContainer")
	t.set_stylebox(&"panel", type_name, style)


static func _buttons(t: Theme) -> void:
	for type_name in [&"Button", &"OptionButton"]:
		t.set_stylebox(&"normal", type_name, UIStyle.box(UIStyle.PANEL, UIStyle.LINE_STRONG, 1, 14, 7))
		t.set_stylebox(&"hover", type_name, UIStyle.box(UIStyle.HOVER, UIStyle.LINE_STRONG, 1, 14, 7))
		t.set_stylebox(&"pressed", type_name, UIStyle.box(UIStyle.HOVER, UIStyle.ACCENT, 1, 14, 7))
		t.set_stylebox(&"hover_pressed", type_name, UIStyle.box(UIStyle.HOVER, UIStyle.ACCENT, 1, 14, 7))
		t.set_stylebox(&"disabled", type_name, UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE, 1, 14, 7))
		var focus := UIStyle.box(Color.TRANSPARENT, UIStyle.ACCENT, 1)
		focus.draw_center = false
		t.set_stylebox(&"focus", type_name, focus)
		t.set_color(&"font_color", type_name, UIStyle.TEXT)
		t.set_color(&"font_hover_color", type_name, UIStyle.TEXT)
		t.set_color(&"font_pressed_color", type_name, UIStyle.ACCENT)
		t.set_color(&"font_hover_pressed_color", type_name, UIStyle.ACCENT)
		t.set_color(&"font_disabled_color", type_name, UIStyle.FAINT)
		t.set_color(&"icon_normal_color", type_name, UIStyle.MUTED)
		t.set_color(&"icon_hover_color", type_name, UIStyle.TEXT)
		t.set_color(&"icon_pressed_color", type_name, UIStyle.ACCENT)
		t.set_color(&"icon_hover_pressed_color", type_name, UIStyle.ACCENT)
		t.set_constant(&"h_separation", type_name, 10)
		t.set_constant(&"icon_max_width", type_name, 20)

	# Sidebar navigation
	t.set_type_variation(&"NavButton", &"Button")
	var nav_pressed := UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, 20, 9)
	nav_pressed.border_width_left = 3
	nav_pressed.border_color = UIStyle.ACCENT
	t.set_stylebox(&"normal", &"NavButton", UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 20, 9))
	t.set_stylebox(&"hover", &"NavButton", UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, 20, 9))
	t.set_stylebox(&"pressed", &"NavButton", nav_pressed)
	t.set_stylebox(&"hover_pressed", &"NavButton", nav_pressed)
	t.set_color(&"font_color", &"NavButton", UIStyle.MUTED)
	t.set_color(&"font_hover_color", &"NavButton", UIStyle.TEXT)
	t.set_constant(&"h_separation", &"NavButton", 14)

	# Primary action ("Continue")
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", UIStyle.box(UIStyle.ACCENT, Color.TRANSPARENT, 0, 22, 9))
	t.set_stylebox(&"hover", &"AccentButton", UIStyle.box(UIStyle.ACCENT.lightened(0.12), Color.TRANSPARENT, 0, 22, 9))
	t.set_stylebox(&"pressed", &"AccentButton", UIStyle.box(UIStyle.ACCENT.darkened(0.15), Color.TRANSPARENT, 0, 22, 9))
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(state, &"AccentButton", UIStyle.BG)
	for state in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_focus_color"]:
		t.set_color(state, &"AccentButton", UIStyle.BG)
	t.set_font(&"font", &"AccentButton", UIStyle.font(&"display"))
	t.set_font_size(&"font_size", &"AccentButton", 19)

	# Borderless icon button (back arrow)
	t.set_type_variation(&"FlatButton", &"Button")
	t.set_stylebox(&"normal", &"FlatButton", UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 6))
	t.set_stylebox(&"hover", &"FlatButton", UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, 8, 6))
	t.set_stylebox(&"pressed", &"FlatButton", UIStyle.box(UIStyle.HOVER, Color.TRANSPARENT, 0, 8, 6))
	t.set_stylebox(&"disabled", &"FlatButton", UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 6))
	t.set_color(&"icon_disabled_color", &"FlatButton", UIStyle.LINE_STRONG)


static func _tree(t: Theme) -> void:
	t.set_stylebox(&"panel", &"Tree", UIStyle.box(UIStyle.PANEL, UIStyle.LINE, 1, 0, 0))
	t.set_stylebox(&"focus", &"Tree", StyleBoxEmpty.new())
	# Hover: soft amber tint with an amber outline; selection: stronger tint.
	var hovered := UIStyle.box(Color(UIStyle.ACCENT, 0.08), Color(UIStyle.ACCENT, 0.45), 1)
	t.set_stylebox(&"hovered", &"Tree", hovered)
	t.set_stylebox(&"hovered_dimmed", &"Tree", hovered)
	t.set_stylebox(&"selected", &"Tree", UIStyle.box(Color(UIStyle.ACCENT, 0.16), UIStyle.ACCENT, 1))
	t.set_stylebox(&"selected_focus", &"Tree", UIStyle.box(Color(UIStyle.ACCENT, 0.16), UIStyle.ACCENT, 1))
	t.set_stylebox(&"cursor", &"Tree", StyleBoxEmpty.new())
	t.set_stylebox(&"cursor_unfocused", &"Tree", StyleBoxEmpty.new())
	var title := UIStyle.box(UIStyle.PANEL_DARK, Color.TRANSPARENT, 0, 12, 10)
	title.border_width_bottom = 1
	title.border_color = UIStyle.LINE
	t.set_stylebox(&"title_button_normal", &"Tree", title)
	var title_hover := title.duplicate()
	title_hover.bg_color = UIStyle.HOVER
	t.set_stylebox(&"title_button_hover", &"Tree", title_hover)
	t.set_stylebox(&"title_button_pressed", &"Tree", title_hover)
	t.set_font(&"title_button_font", &"Tree", UIStyle.font(&"display_semibold"))
	t.set_font_size(&"title_button_font_size", &"Tree", 15)
	t.set_color(&"title_button_color", &"Tree", UIStyle.MUTED)
	t.set_color(&"font_color", &"Tree", UIStyle.TEXT)
	t.set_color(&"font_selected_color", &"Tree", UIStyle.TEXT)
	t.set_color(&"font_hovered_color", &"Tree", Color.WHITE)
	t.set_color(&"guide_color", &"Tree", UIStyle.LINE)
	t.set_constant(&"draw_guides", &"Tree", 1)
	t.set_constant(&"draw_relationship_lines", &"Tree", 0)
	t.set_constant(&"v_separation", &"Tree", 8)
	t.set_constant(&"h_separation", &"Tree", 8)
	t.set_constant(&"item_margin", &"Tree", 0)
	t.set_constant(&"inner_item_margin_left", &"Tree", 12)
	t.set_constant(&"inner_item_margin_right", &"Tree", 12)


static func _scrollbars(t: Theme) -> void:
	for type_name in [&"VScrollBar", &"HScrollBar"]:
		var track := UIStyle.box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, 4)
		t.set_stylebox(&"scroll", type_name, track)
		t.set_stylebox(&"scroll_focus", type_name, track)
		t.set_stylebox(&"grabber", type_name, UIStyle.box(UIStyle.LINE_STRONG))
		t.set_stylebox(&"grabber_highlight", type_name, UIStyle.box(UIStyle.MUTED))
		t.set_stylebox(&"grabber_pressed", type_name, UIStyle.box(UIStyle.ACCENT))
	t.set_stylebox(&"panel", &"ScrollContainer", StyleBoxEmpty.new())


static func _misc(t: Theme) -> void:
	var h_line := StyleBoxLine.new()
	h_line.color = UIStyle.LINE
	h_line.thickness = 1
	t.set_stylebox(&"separator", &"HSeparator", h_line)
	t.set_constant(&"separation", &"HSeparator", 1)
	var v_line := StyleBoxLine.new()
	v_line.color = UIStyle.LINE
	v_line.thickness = 1
	v_line.vertical = true
	t.set_stylebox(&"separator", &"VSeparator", v_line)
	t.set_constant(&"separation", &"VSeparator", 1)

	t.set_stylebox(&"panel", &"PopupMenu", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1, 4, 4))
	t.set_stylebox(&"hover", &"PopupMenu", UIStyle.box(UIStyle.HOVER))
	t.set_color(&"font_color", &"PopupMenu", UIStyle.TEXT)
	t.set_color(&"font_hover_color", &"PopupMenu", UIStyle.ACCENT)

	t.set_stylebox(&"normal", &"LineEdit", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1, 10, 6))
	t.set_stylebox(&"focus", &"LineEdit", UIStyle.box(Color.TRANSPARENT, UIStyle.ACCENT, 1))
	t.set_color(&"font_color", &"LineEdit", UIStyle.TEXT)
