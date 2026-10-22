## Thin horizontal bar for 0..100 values.
class_name Meter
extends Control

var value: float
var color: Color
## Optional target line (0..100), e.g. where an agent accepts. -1 = none.
var marker: float = -1.0


func _init(p_value: float = 0.0, p_color: Color = UIStyle.ACCENT, height: int = 6) -> void:
	value = p_value
	color = p_color
	custom_minimum_size.y = height
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_value(p_value: float, p_color: Color) -> void:
	value = p_value
	color = p_color
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UIStyle.LINE)
	draw_rect(Rect2(0, 0, size.x * clampf(value / 100.0, 0.0, 1.0), size.y), color)
	if marker >= 0.0:
		var x := size.x * marker / 100.0
		draw_rect(Rect2(x - 1, -4, 2, size.y + 8), UIStyle.TEXT)
