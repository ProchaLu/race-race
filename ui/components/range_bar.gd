## Known range of a 1-20 value (decision 39): a band on the full scale,
## coloured by the middle of the range, plus the numbers next to it.
class_name RangeBar
extends HBoxContainer

const BAR_WIDTH := 70


func _init(lo: int, hi: int) -> void:
	add_theme_constant_override("separation", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := _Band.new()
	bar.lo = lo
	bar.hi = hi
	bar.custom_minimum_size = Vector2(BAR_WIDTH, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(bar)
	var label := Label.new()
	label.text = "%d–%d" % [lo, hi]
	label.theme_type_variation = &"MonoLabel"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UIStyle.value_color(roundi((lo + hi) / 2.0)).lerp(UIStyle.MUTED, 0.3))
	label.custom_minimum_size.x = 44
	add_child(label)


class _Band:
	extends Control
	var lo: int
	var hi: int

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UIStyle.LINE)
		var x0 := (lo - 1) / 19.0 * size.x
		var x1 := (hi - 1) / 19.0 * size.x
		var color := UIStyle.value_color(roundi((lo + hi) / 2.0))
		draw_rect(Rect2(x0, 0, maxf(x1 - x0, 3.0), size.y), Color(color, 0.8))
