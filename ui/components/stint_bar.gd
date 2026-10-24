## Horizontal bar of tyre stints, one coloured block per stint, with the
## compound letter and lap count when there is room ("M24 | H28").
class_name StintBar
extends Control

## [[compound id, laps], ...]
var stints: Array = []
var total_laps: int = 1
var show_labels := true


func _init(p_stints: Array, p_total_laps: int, height: int = 18, p_show_labels: bool = true) -> void:
	stints = p_stints
	total_laps = maxi(p_total_laps, 1)
	show_labels = p_show_labels
	custom_minimum_size = Vector2(80, height)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Stints from a per-lap compound list (race summary "compounds").
static func from_laps(compounds: Array) -> Array:
	var out: Array = []
	for c in compounds:
		if out.is_empty() or out.back()[0] != c:
			out.append([c, 0])
		out.back()[1] += 1
	return out


## Stints of a strategy plan (StrategyPlanner.plans() entry).
static func from_plan(plan: Dictionary, total: int) -> Array:
	var out: Array = []
	var compound: StringName = plan.first
	var from := 0
	for stop in plan.stops:
		out.append([compound, stop[0] - from])
		from = stop[0]
		compound = stop[1]
	out.append([compound, total - from])
	return out


func _draw() -> void:
	var font := UIStyle.font(&"mono_semibold")
	var x := 0.0
	for s in stints:
		var w: float = size.x * s[1] / float(total_laps)
		var rect := Rect2(x, 0, maxf(w - 2.0, 1.0), size.y)
		var color := UIStyle.compound_color(s[0])
		draw_rect(rect, Color(color, 0.85))
		var text := "%s%d" % [UIStyle.compound_letter(s[0]), s[1]]
		var font_size := int(size.y * 0.62)
		if show_labels and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 6 < w:
			draw_string(font, Vector2(x + 4, size.y * 0.5 + font_size * 0.36), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UIStyle.BG)
		x += w
