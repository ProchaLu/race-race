## The car from above with all 13 parts as clickable zones, coloured by a
## callback (e.g. rank in the field). The selected part gets an amber outline.
class_name CarDiagram
extends Control

signal part_selected(part_id: StringName)

const WHEEL := Color("232a31")
const WHEEL_LINE := Color("34404b")

var selected: StringName = &""
## func(part_id) -> Color
var color_of: Callable
## func(part_id) -> String (tooltip)
var tooltip_of: Callable
var _scale := 1.0


func _init(p_color_of: Callable, p_tooltip_of: Callable, height: float = 620.0) -> void:
	color_of = p_color_of
	tooltip_of = p_tooltip_of
	_scale = height / CarLayout.SIZE.y
	custom_minimum_size = CarLayout.SIZE * _scale
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = " "


func _draw() -> void:
	for w in CarLayout.WHEELS:
		var rect := Rect2(Vector2(w[0], w[1]) * _scale, Vector2(w[2], w[3]) * _scale)
		draw_rect(rect, WHEEL)
		draw_rect(rect, WHEEL_LINE, false, 1.0)
	for id in CarLayout.ZONES:
		for poly in CarLayout.polygons(id, _scale):
			draw_colored_polygon(poly, color_of.call(id))
			var outline := poly.duplicate()
			outline.append(poly[0])
			draw_polyline(outline, UIStyle.BG, 1.5, true)
	if selected != &"":
		for poly in CarLayout.polygons(selected, _scale):
			var outline := poly.duplicate()
			outline.append(poly[0])
			draw_polyline(outline, UIStyle.ACCENT, 3.0, true)


## Topmost zone under the point (drawn last = on top).
func part_at(point: Vector2) -> StringName:
	var ids := CarLayout.ZONES.keys()
	ids.reverse()
	for id in ids:
		for poly in CarLayout.polygons(id, _scale):
			if Geometry2D.is_point_in_polygon(point, poly):
				return id
	return &""


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var id := part_at(mb.position)
		if id != &"":
			selected = id
			queue_redraw()
			part_selected.emit(id)


func _get_tooltip(at_position: Vector2) -> String:
	var id := part_at(at_position)
	return tooltip_of.call(id) if id != &"" else ""
