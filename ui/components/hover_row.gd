## Base for every interactive row/box: highlights on hover and shows a
## Breakdown tooltip. Subclasses add their content as children.
class_name HoverRow
extends PanelContainer

signal clicked

var breakdown: Breakdown
var base_style: StringName
var hover_style: StringName
## Style when neither hovered nor selected (plain or zebra).
var _rest_style: StringName


func _init(p_base_style: StringName = &"RowPlain", p_hover_style: StringName = &"RowHover") -> void:
	base_style = p_base_style
	hover_style = p_hover_style
	_rest_style = p_base_style
	theme_type_variation = base_style
	mouse_entered.connect(func(): theme_type_variation = hover_style)
	mouse_exited.connect(func(): theme_type_variation = base_style)


func _ready() -> void:
	# Children must not swallow hover/tooltip events.
	UIStyle.ignore_mouse(self)


## Alternating background in lists.
func set_zebra(on: bool) -> void:
	_rest_style = &"RowZebra" if on else &"RowPlain"
	base_style = _rest_style
	theme_type_variation = base_style


## Marks the row as the current choice (amber tint and left border).
func set_selected(on: bool) -> void:
	base_style = &"RowSelected" if on else _rest_style
	theme_type_variation = base_style


func set_breakdown(b: Breakdown) -> void:
	breakdown = b
	tooltip_text = b.title if b else ""


func make_clickable() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()


func _make_custom_tooltip(_for_text: String) -> Object:
	return BreakdownTooltip.create(breakdown) if breakdown else null
