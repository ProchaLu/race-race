## Horizontal bar for a 0..100 value with a tick for a reference value
## (e.g. the field average).
class_name RatingBar
extends Control

var value := 0.0
var reference := -1.0
var color := UIStyle.ACCENT


func _init(p_value: float, p_color: Color, p_reference: float = -1.0) -> void:
	value = p_value
	color = p_color
	reference = p_reference
	custom_minimum_size = Vector2(80, 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var y := size.y * 0.5 - 3.0
	draw_rect(Rect2(0, y, size.x, 6), UIStyle.LINE)
	draw_rect(Rect2(0, y, size.x * clampf(value / 100.0, 0.0, 1.0), 6), color)
	if reference >= 0.0:
		var x := size.x * clampf(reference / 100.0, 0.0, 1.0)
		draw_rect(Rect2(x - 1, y - 3, 2, 12), UIStyle.TEXT)
