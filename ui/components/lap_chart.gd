## Lap time chart: one line per driver, safety car and rain phases as
## shaded bands, pit stops as dots on the bottom edge. Very slow laps (pit
## stops, safety car) are cut off at the top so the racing laps stay readable.
class_name LapChart
extends Control

const PAD_LEFT := 52.0
const PAD_BOTTOM := 22.0
const PAD_TOP := 8.0

## [{"times": Array, "color": Color, "dashed": bool, "stops": Array[int]}]
var lines: Array = []
## [{"from": lap, "to": lap, "color": Color, "label": String}]
var bands: Array = []
var laps: int = 1
var _lo := 0.0
var _hi := 1.0


func _init(p_lines: Array, p_bands: Array, p_laps: int, height: int = 240) -> void:
	lines = p_lines
	bands = p_bands
	laps = maxi(p_laps, 2)
	custom_minimum_size = Vector2(300, height)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_find_range()


func _find_range() -> void:
	var all: Array[float] = []
	for l in lines:
		for t in l.times:
			if t > 0.0 and not is_inf(t):
				all.append(t)
	if all.is_empty():
		return
	all.sort()
	_lo = floorf(all[0] - 0.5)
	# Cut at a little above the typical racing lap (median + 8 %).
	_hi = ceilf(minf(all.back(), all[all.size() / 2] * 1.08))
	if _hi - _lo < 3.0:
		_hi = _lo + 3.0


func _x(lap: float) -> float:
	return PAD_LEFT + (lap - 1.0) / (laps - 1.0) * (size.x - PAD_LEFT - 8.0)


func _y(t: float) -> float:
	var h := size.y - PAD_TOP - PAD_BOTTOM
	return PAD_TOP + (1.0 - (clampf(t, _lo, _hi) - _lo) / (_hi - _lo)) * h


func _draw() -> void:
	var font := UIStyle.font(&"mono")
	var fs := 12
	var bottom := size.y - PAD_BOTTOM
	for b in bands:
		var x0 := _x(b.from)
		var x1 := _x(maxf(b.to, b.from + 0.6))
		draw_rect(Rect2(x0, PAD_TOP, x1 - x0, bottom - PAD_TOP), Color(b.color, 0.13))
		draw_string(font, Vector2(x0 + 3, PAD_TOP + 12), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, b.color)
	# Horizontal grid with lap time labels.
	var step := maxf(1.0, roundf((_hi - _lo) / 5.0))
	var t := ceilf(_lo)
	while t <= _hi:
		var y := _y(t)
		draw_line(Vector2(PAD_LEFT, y), Vector2(size.x - 8, y), UIStyle.LINE)
		draw_string(font, Vector2(2, y + 4), "%d:%02d" % [floori(t / 60.0), int(fmod(t, 60.0))],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIStyle.FAINT)
		t += step
	var lap_step := 5 if laps <= 60 else 10
	for lap in range(1, laps + 1, lap_step):
		draw_string(font, Vector2(_x(lap) - 4, size.y - 6), str(lap), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIStyle.FAINT)

	for l in lines:
		var pts := PackedVector2Array()
		for i in l.times.size():
			if l.times[i] > 0.0:
				pts.append(Vector2(_x(i + 1), _y(l.times[i])))
		if pts.size() >= 2:
			if l.get("dashed", false):
				for i in pts.size() - 1:
					draw_dashed_line(pts[i], pts[i + 1], l.color, 1.5, 4.0)
			else:
				draw_polyline(pts, l.color, 2.0, true)
		for lap in l.get("stops", []):
			draw_circle(Vector2(_x(lap), bottom - 4), 3.5, l.color)
