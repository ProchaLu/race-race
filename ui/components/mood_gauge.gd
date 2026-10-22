## Half-circle gauge for the team mood: five coloured steps (Crisis ..
## Euphoria), the current step bright, a needle at the value.
class_name MoodGauge
extends Control

const ARC_WIDTH := 14.0
const GAP := 0.03  # radians between steps

var value: int


func _init(p_value: int) -> void:
	value = p_value
	custom_minimum_size = Vector2(220, 118)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.y - 8.0)
	var radius := minf(size.x / 2.0, size.y) - ARC_WIDTH
	var active := TeamMood.level_index(value)
	for i in TeamMood.LEVELS.size():
		# Arc runs from left (PI) to right (2 PI) across the top.
		var from := PI + PI * i / 5.0 + GAP
		var to := PI + PI * (i + 1) / 5.0 - GAP
		var color := UIStyle.mood_color_by_index(i)
		draw_arc(center, radius, from, to, 24, Color(color, 1.0 if i == active else 0.3), ARC_WIDTH, true)
	var angle := PI + PI * clampf(value / 100.0, 0.0, 1.0)
	var tip := center + Vector2(cos(angle), sin(angle)) * (radius - ARC_WIDTH - 6.0)
	draw_line(center, tip, UIStyle.TEXT, 3.0, true)
	draw_circle(center, 5.0, UIStyle.TEXT)
