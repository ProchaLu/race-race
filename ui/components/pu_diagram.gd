## The power unit as five clickable blocks (mockup r5_engine.html): combustion
## engine, turbo, energy recovery, battery and control electronics, coloured
## by rank among the manufacturers.
class_name PuDiagram
extends Control

signal component_selected(component: StringName)

## Block positions in a 520 × 230 design space.
const LAYOUT := {&"ice": Rect2(30, 60, 200, 120), &"turbo": Rect2(250, 40, 110, 70), &"ers": Rect2(250, 130, 110, 70),
	&"battery": Rect2(380, 60, 120, 70), &"control": Rect2(380, 150, 120, 50)}
const DESIGN := Vector2(520, 230)

var selected: StringName = &"ice"
## component -> [label line, colour]
var info: Dictionary = {}
var _hovered: StringName = &""


func _init(p_info: Dictionary) -> void:
	info = p_info
	custom_minimum_size = Vector2(420, 200)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP


func _rect(component: StringName) -> Rect2:
	var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	var offset := (size - DESIGN * factor) / 2.0
	var r: Rect2 = LAYOUT[component]
	return Rect2(offset + r.position * factor, r.size * factor)


func _component_at(point: Vector2) -> StringName:
	for c in LAYOUT:
		if _rect(c).has_point(point):
			return c
	return &""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := _component_at(event.position)
		if c != _hovered:
			_hovered = c
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if c != &"" else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := _component_at(event.position)
		if c != &"":
			selected = c
			component_selected.emit(c)
			queue_redraw()
			accept_event()


func _draw() -> void:
	# Connections: the ICE feeds the turbo and the ERS, the ERS the battery and the electronics.
	for pair in [[&"ice", &"turbo"], [&"ice", &"ers"], [&"turbo", &"battery"], [&"ers", &"control"]]:
		var a := _rect(pair[0])
		var b := _rect(pair[1])
		draw_line(Vector2(a.end.x, a.get_center().y), Vector2(b.position.x, b.get_center().y), UIStyle.LINE_STRONG, 3)
	var font := UIStyle.font(&"body_semibold")
	var mono := UIStyle.font(&"mono")
	for c in LAYOUT:
		var r := _rect(c)
		var entry: Array = info.get(c, ["", UIStyle.MUTED])
		draw_rect(r, entry[1] if c != _hovered else (entry[1] as Color).lightened(0.12))
		if c == selected:
			draw_rect(r.grow(2), UIStyle.ACCENT, false, 3)
		draw_string(font, r.position + Vector2(10, 24), PowerUnit.COMPONENT_SHORT[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UIStyle.BG)
		draw_string(mono, r.position + Vector2(10, 44), entry[0], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 14, 13, UIStyle.BG)
