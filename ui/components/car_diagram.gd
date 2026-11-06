## The car from above with all 13 parts as clickable zones, coloured by a
## callback (e.g. rank in the field). Drawn like a technical illustration:
## drop shadow, tyres, shaded bodywork, cockpit with halo and helmet, wing
## flaps and diffuser strakes. The selected part gets an amber outline.
class_name CarDiagram
extends Control

signal part_selected(part_id: StringName)

const TYRE := Color("1a1f25")
const TYRE_EDGE := Color("2c343d")
const CARBON := Color("12161b")
const HALO := Color("59646f")

var selected: StringName = &""
## Helmet colour (e.g. the team colour).
var helmet_color := UIStyle.ACCENT
## func(part_id) -> Color
var color_of: Callable
## func(part_id) -> String (tooltip)
var tooltip_of: Callable
var _scale := 1.0
var _hovered: StringName = &""


func _init(p_color_of: Callable, p_tooltip_of: Callable, height: float = 620.0) -> void:
	color_of = p_color_of
	tooltip_of = p_tooltip_of
	_scale = height / CarLayout.SIZE.y
	custom_minimum_size = CarLayout.SIZE * _scale
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tooltip_text = " "


func _p(x: float, y: float) -> Vector2:
	return Vector2(x, y) * _scale


func _draw() -> void:
	_draw_shadow()
	_draw_wheels()
	for id in CarLayout.ORDER:
		var base: Color = color_of.call(id)
		if id == _hovered:
			base = base.lightened(0.15)
		for poly in CarLayout.polygons(id, _scale):
			_draw_panel(poly, base)
		_draw_details(id, base)
	_draw_cockpit()
	if selected != &"":
		for poly in CarLayout.polygons(selected, _scale):
			_outline(poly, UIStyle.ACCENT, 3.0)


func _draw_shadow() -> void:
	var off := _p(5, 8)
	for id in [&"floor", &"front_wing", &"rear_wing"]:
		for poly in CarLayout.polygons(id, _scale):
			var shifted := PackedVector2Array()
			for pt in poly:
				shifted.append(pt + off)
			draw_colored_polygon(shifted, Color(0, 0, 0, 0.35))
	for r in CarLayout.wheels(_scale):
		draw_rect(Rect2(r.position + off, r.size), Color(0, 0, 0, 0.35))


func _draw_wheels() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = TYRE
	box.border_color = TYRE_EDGE
	box.set_border_width_all(maxi(1, roundi(1.5 * _scale)))
	box.set_corner_radius_all(roundi(12 * _scale))
	box.anti_aliasing = true
	for r in CarLayout.wheels(_scale):
		draw_style_box(box, r)
		# Sheen on the tread and the shoulders of the tyre.
		var band := Rect2(r.position.x + r.size.x * 0.38, r.position.y + 6 * _scale, r.size.x * 0.24, r.size.y - 12 * _scale)
		draw_rect(band, Color(1, 1, 1, 0.05))
		for k in [0.12, 0.88]:
			var x: float = r.position.x + r.size.x * k
			draw_line(Vector2(x, r.position.y + 10 * _scale), Vector2(x, r.end.y - 10 * _scale), Color(1, 1, 1, 0.06), 1.0)
		# Sidewall stripe (compound marking) on the outer and inner shoulder.
		for k in [0.04, 0.96]:
			var x: float = r.position.x + r.size.x * k
			draw_line(Vector2(x, r.position.y + r.size.y * 0.3), Vector2(x, r.end.y - r.size.y * 0.3),
				Color(1, 1, 1, 0.16), maxf(1.0, 2.0 * _scale))


## A body panel: fill, a highlight towards the middle, a darker edge.
func _draw_panel(poly: PackedVector2Array, base: Color) -> void:
	draw_colored_polygon(poly, base.darkened(0.18))
	var c := Vector2.ZERO
	for pt in poly:
		c += pt
	c /= poly.size()
	var inner := PackedVector2Array()
	for pt in poly:
		inner.append(c + (pt - c) * Vector2(0.72, 0.9))
	draw_colored_polygon(inner, base)
	var sheen := PackedVector2Array()
	for pt in poly:
		sheen.append(c + (pt - c) * Vector2(0.3, 0.8))
	draw_colored_polygon(sheen, base.lightened(0.14))
	_outline(poly, base.darkened(0.55), 1.2)


func _outline(poly: PackedVector2Array, color: Color, width: float) -> void:
	var line := poly.duplicate()
	line.append(poly[0])
	draw_polyline(line, color, width, true)


## Lines and openings that make a part read as what it is.
func _draw_details(id: StringName, base: Color) -> void:
	var dark := base.darkened(0.5)
	match id:
		&"front_wing":
			# Flaps: three elements across each half.
			for k in 3:
				var y := 52.0 + k * 6.0
				for side in [1, -1]:
					draw_line(_p(_mx(166, side), y + 2), _p(_mx(266, side), y - 8 + k * 2), dark, 1.0, true)
		&"rear_wing":
			draw_line(_p(66, 696), _p(234, 696), dark, 1.5, true)
			draw_line(_p(150, 680), _p(150, 712), dark, 1.0, true)
		&"diffuser":
			for x in [176, 188, 198]:
				for side in [1, -1]:
					draw_line(_p(_mx(x, side), 632), _p(_mx(x, side), 694), dark, 1.0, true)
		&"floor":
			# Edge of the floor and the fences in front of the sidepods.
			for side in [1, -1]:
				draw_line(_p(_mx(240, side), 340), _p(_mx(246, side), 480), dark, 1.0, true)
				for k in 3:
					draw_line(_p(_mx(196 + k * 10, side), 292 + k * 3), _p(_mx(204 + k * 10, side), 330), dark, 1.0, true)
		&"sidepods":
			# Undercut line along the downwash ramp.
			for side in [1, -1]:
				var pts := PackedVector2Array([_p(_mx(236, side), 350), _p(_mx(238, side), 410),
					_p(_mx(226, side), 470), _p(_mx(204, side), 525)])
				draw_polyline(pts, dark, 1.2, true)
		&"cooling":
			for side in [1, -1]:
				var mouth := PackedVector2Array([_p(_mx(192, side), 316), _p(_mx(230, side), 316),
					_p(_mx(236, side), 326), _p(_mx(194, side), 328)])
				if side == -1:
					mouth.reverse()
				draw_colored_polygon(mouth, CARBON)
		&"engine_cover":
			# Airbox above the driver and the fin along the spine.
			draw_colored_polygon(_ellipse(150, 334, 11, 7), CARBON)
			draw_line(_p(150, 350), _p(150, 600), base.lightened(0.3), maxf(1.0, 2.0 * _scale), true)
		&"monocoque":
			draw_line(_p(150, 40), _p(150, 220), base.lightened(0.25), maxf(1.0, 1.5 * _scale), true)
			# Mirrors on stalks.
			for side in [1, -1]:
				draw_line(_p(_mx(178, side), 240), _p(_mx(196, side), 236), dark, maxf(1.0, 2.0 * _scale), true)
				draw_colored_polygon(_ellipse(_mx(200, side), 236, 8, 4), base.darkened(0.3))
		&"exhaust":
			draw_colored_polygon(_ellipse(150, 679, 4, 4), CARBON)


## Cockpit opening, helmet and halo (on top of the monocoque, not a part).
func _draw_cockpit() -> void:
	var opening := PackedVector2Array()
	for pt in CarLayout._sym([[150, 236], [164, 242], [170, 276], [166, 306], [150, 312]]):
		opening.append(pt * _scale)
	draw_colored_polygon(opening, CARBON)
	draw_colored_polygon(_ellipse(150, 284, 12, 13), helmet_color)
	draw_colored_polygon(_ellipse(150, 280, 8, 5), helmet_color.darkened(0.45))
	var halo := PackedVector2Array([_p(150, 228), _p(150, 240), _p(140, 250), _p(134, 280), _p(138, 306),
		_p(150, 312), _p(162, 306), _p(166, 280), _p(160, 250), _p(150, 240)])
	draw_polyline(halo, HALO, maxf(2.0, 5.0 * _scale), true)


func _ellipse(x: float, y: float, rx: float, ry: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		out.append(_p(x + cos(a) * rx, y + sin(a) * ry))
	return out


## x on the right side (side 1) or mirrored to the left (side -1).
func _mx(x: float, side: int) -> float:
	return x if side == 1 else CarLayout.SIZE.x - x


## Topmost zone under the point (drawn last = on top).
func part_at(point: Vector2) -> StringName:
	var ids := CarLayout.ORDER.duplicate()
	ids.reverse()
	for id in ids:
		for poly in CarLayout.hit_polygons(id, _scale):
			if Geometry2D.is_point_in_polygon(point, poly):
				return id
	return &""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var id := part_at(event.position)
		if id != _hovered:
			_hovered = id
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != &"" else Control.CURSOR_ARROW
			queue_redraw()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var id := part_at(mb.position)
		if id != &"":
			selected = id
			queue_redraw()
			part_selected.emit(id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hovered != &"":
		_hovered = &""
		queue_redraw()


func _get_tooltip(at_position: Vector2) -> String:
	var id := part_at(at_position)
	return tooltip_of.call(id) if id != &"" else ""
