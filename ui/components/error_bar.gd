## A measured gain with its uncertainty (mockup r3_lab.html): zero line in
## the middle, the ± range as a band (green = better, red = worse than the
## baseline) and the estimate as a tick.
class_name ErrorBar
extends Control

var value: float
var uncertainty: float
## Value at the edge of the bar (both sides).
var span: float
var text: String


func _init(p_value: float, p_uncertainty: float, p_scale: float, p_text: String = "") -> void:
	value = p_value
	uncertainty = p_uncertainty
	span = maxf(p_scale, 0.0001)
	text = p_text
	custom_minimum_size = Vector2(150, 18)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _x(v: float) -> float:
	return size.x * (0.5 + clampf(v / span, -1.0, 1.0) * 0.5)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UIStyle.PANEL_DARK)
	draw_rect(Rect2(Vector2.ZERO, size), UIStyle.LINE, false, 1.0)
	var x0 := _x(value - uncertainty)
	var x1 := _x(value + uncertainty)
	var color := UIStyle.GOOD if value >= 0.0 else UIStyle.BAD
	draw_rect(Rect2(x0, 4, maxf(x1 - x0, 2.0), size.y - 8), Color(color, 0.35))
	draw_rect(Rect2(size.x * 0.5, -2, 1, size.y + 4), UIStyle.MUTED)
	draw_rect(Rect2(_x(value) - 1.5, 2, 3, size.y - 4), UIStyle.TEXT)
	if text != "":
		var font := get_theme_default_font()
		var fs := 11
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(size.x - w - 4, size.y - 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIStyle.MUTED)
