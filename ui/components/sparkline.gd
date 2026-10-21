## Small line chart: area fill, faint grid, a value label on every point and
## an emphasised last point.
class_name Sparkline
extends Control

const FONT_SIZE := 11
const VALUE_FONT_SIZE := 12
const LABEL_SPACE_TOP := 18.0
const LABEL_SPACE_BOTTOM := 18.0
const SIDE_PADDING := 16.0

var values: Array[float] = []
var labels: Array[String] = []
## Decimals shown in the point labels (0 for whole attribute values).
var decimals: int


func _init(p_values: Array[float], p_labels: Array[String], height: int = 110, p_decimals: int = 1) -> void:
	values = p_values
	labels = p_labels
	decimals = p_decimals
	custom_minimum_size.y = height
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if values.size() < 2:
		return
	var font := UIStyle.font(&"mono")
	var value_font := UIStyle.font(&"tabular")
	var low := floorf(values.min()) - 1.0
	var high := ceilf(values.max()) + 1.0
	var plot := Rect2(SIDE_PADDING, LABEL_SPACE_TOP, size.x - 2 * SIDE_PADDING,
		size.y - LABEL_SPACE_TOP - LABEL_SPACE_BOTTOM)
	var to_point := func(i: int, v: float) -> Vector2:
		return Vector2(plot.position.x + plot.size.x * i / (values.size() - 1),
			plot.end.y - (v - low) / (high - low) * plot.size.y)

	for g in 3:
		var y: float = to_point.call(0, lerpf(low, high, g / 2.0)).y
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), UIStyle.LINE, 1.0)

	var line := PackedVector2Array()
	for i in values.size():
		line.append(to_point.call(i, values[i]))
	var area := line.duplicate()
	area.append(Vector2(plot.end.x, plot.end.y))
	area.append(Vector2(plot.position.x, plot.end.y))
	draw_colored_polygon(area, Color(UIStyle.ACCENT, 0.12))
	draw_polyline(line, UIStyle.ACCENT, 2.0, true)

	var format := "%d" if decimals == 0 else "%." + str(decimals) + "f"
	for i in values.size():
		var last := i == values.size() - 1
		draw_circle(line[i], 4.0 if last else 2.5, UIStyle.ACCENT)
		var text: String = format % roundi(values[i]) if decimals == 0 else format % values[i]
		draw_string(value_font, Vector2(line[i].x - 20, line[i].y - 8), text,
			HORIZONTAL_ALIGNMENT_CENTER, 40, VALUE_FONT_SIZE, UIStyle.TEXT if last else UIStyle.MUTED)
	for i in labels.size():
		draw_string(font, Vector2(line[i].x - 20, size.y - 3), labels[i],
			HORIZONTAL_ALIGNMENT_CENTER, 40, FONT_SIZE, UIStyle.MUTED)
