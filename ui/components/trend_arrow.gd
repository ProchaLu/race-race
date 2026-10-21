## Small triangle: green up or red down.
class_name TrendArrow
extends Control

var up: bool


func _init(p_up: bool) -> void:
	up = p_up
	custom_minimum_size = Vector2(9, 9)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y
	var points := PackedVector2Array([Vector2(w / 2, 0), Vector2(w, h), Vector2(0, h)]) if up \
		else PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w / 2, h)])
	draw_colored_polygon(points, UIStyle.GOOD if up else UIStyle.BAD)
