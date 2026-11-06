## The power unit as five clickable components, drawn as a technical
## illustration seen from above: V6 combustion engine with both cylinder banks
## and the intake plenum, turbocharger (turbine and compressor scroll), energy
## recovery motor, battery pack and control electronics, joined by exhaust and
## intake pipes and power cables. Coloured by rank among the manufacturers.
class_name PuDiagram
extends Control

signal component_selected(component: StringName)

## Clickable area of each component (drawing plus caption) in a 520 × 248 design space.
const LAYOUT := {&"ice": Rect2(10, 22, 238, 214), &"turbo": Rect2(262, 8, 120, 114),
	&"battery": Rect2(394, 8, 120, 114), &"ers": Rect2(262, 128, 120, 116), &"control": Rect2(394, 128, 120, 116)}
const DESIGN := Vector2(520, 248)
const CARBON := Color("12161b")
const PIPE := Color("5b6670")
const CABLE := Color("c98a2b")

var selected: StringName = &"ice"
## component -> [label line, colour]
var info: Dictionary = {}
var _hovered: StringName = &""
var _f := 1.0
var _o := Vector2.ZERO


func _init(p_info: Dictionary) -> void:
	info = p_info
	custom_minimum_size = Vector2(420, 200)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP


func _fit() -> void:
	_f = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	_o = (size - DESIGN * _f) / 2.0


func _p(x: float, y: float) -> Vector2:
	return _o + Vector2(x, y) * _f


func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_p(x, y), Vector2(w, h) * _f)


func _rect(component: StringName) -> Rect2:
	_fit()
	var r: Rect2 = LAYOUT[component]
	return _r(r.position.x, r.position.y, r.size.x, r.size.y)


func _component_at(point: Vector2) -> StringName:
	for c in LAYOUT:
		if _rect(c).has_point(point):
			return c
	return &""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := _component_at(event.position)
		if c != _hovered:
			_hovered = c
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if c != &"" else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := _component_at(event.position)
		if c != &"":
			selected = c
			component_selected.emit(c)
			queue_redraw()
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hovered != &"":
		_hovered = &""
		queue_redraw()


func _color(c: StringName) -> Color:
	var col: Color = info.get(c, ["", UIStyle.MUTED])[1]
	return col.lightened(0.12) if c == _hovered else col


func _draw() -> void:
	_fit()
	for c in LAYOUT:
		if c == _hovered or c == selected:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(1, 1, 1, 0.035)
			box.set_corner_radius_all(roundi(8 * _f))
			if c == selected:
				box.border_color = UIStyle.ACCENT
				box.set_border_width_all(2)
			draw_style_box(box, _rect(c))
	_draw_links()
	_draw_ice(_color(&"ice"))
	_draw_turbo(_color(&"turbo"))
	_draw_ers(_color(&"ers"))
	_draw_battery(_color(&"battery"))
	_draw_control(_color(&"control"))
	for c in LAYOUT:
		_caption(c)


# --- Connections -------------------------------------------------------------

func _draw_links() -> void:
	var w := maxf(2.0, 5.0 * _f)
	# Exhaust: both banks into the turbine (around the captions).
	draw_polyline(PackedVector2Array([_p(214, 62), _p(236, 50), _p(276, 50)]), PIPE, w, true)
	draw_polyline(PackedVector2Array([_p(214, 158), _p(236, 150), _p(254, 130), _p(254, 62), _p(276, 52)]), PIPE, w, true)
	# Charge air: from the compressor around the engine into the plenum.
	draw_polyline(PackedVector2Array([_p(376, 48), _p(388, 48), _p(388, 3), _p(4, 3), _p(4, 110), _p(50, 110)]),
		PIPE.darkened(0.25), w, true)
	# Power cables (dashed): motor ↔ battery ↔ electronics, motor ↔ crankshaft.
	var cw := maxf(1.5, 2.5 * _f)
	var dash := 6 * _f
	draw_dashed_line(_p(372, 152), _p(387, 152), CABLE, cw, dash)
	draw_dashed_line(_p(387, 152), _p(387, 54), CABLE, cw, dash)
	draw_dashed_line(_p(387, 54), _p(416, 54), CABLE, cw, dash)
	draw_dashed_line(_p(492, 54), _p(508, 54), CABLE, cw, dash)
	draw_dashed_line(_p(508, 54), _p(508, 164), CABLE, cw, dash)
	draw_dashed_line(_p(508, 164), _p(496, 164), CABLE, cw, dash)
	draw_dashed_line(_p(372, 172), _p(412, 172), CABLE, cw, dash)
	draw_line(_p(228, 160), _p(288, 160), PIPE, maxf(2.0, 7.0 * _f))


# --- Components ----------------------------------------------------------------

## V6 from above: crankcase, two cam covers with three cylinders each, intake plenum with trumpets.
func _draw_ice(col: Color) -> void:
	_box(_r(28, 40, 200, 140), col.darkened(0.35), 14)
	for y in [48.0, 132.0]:
		_box(_r(38, y, 180, 40), col, 10)
		for k in 3:
			var cx := 72.0 + k * 56.0
			draw_circle(_p(cx, y + 20), 14 * _f, col.darkened(0.2))
			draw_circle(_p(cx, y + 20), 9 * _f, col.lightened(0.12))
			draw_circle(_p(cx, y + 20), 3 * _f, col.darkened(0.5))
		draw_line(_p(44, y + 4), _p(212, y + 4), col.lightened(0.25), maxf(1.0, 1.5 * _f))
	_box(_r(50, 94, 164, 32), col.darkened(0.15), 8)
	for k in 6:
		var cx := 66.0 + k * 26.4
		draw_circle(_p(cx, 110), 8 * _f, CARBON)
		draw_arc(_p(cx, 110), 8 * _f, 0, TAU, 20, col.lightened(0.2), maxf(1.0, 1.5 * _f), true)


## Turbine and compressor scrolls on one shaft.
func _draw_turbo(col: Color) -> void:
	draw_rect(_r(312, 42, 26, 12), col.darkened(0.4))
	_scroll(Vector2(298, 48), 26.0, col.darkened(0.1), false)
	_scroll(Vector2(354, 48), 22.0, col, true)


func _scroll(c: Vector2, radius: float, col: Color, flip: bool) -> void:
	var sx := -1.0 if flip else 1.0
	var outer := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		var rr := radius * (0.82 + 0.18 * k / 32.0)
		outer.append(_p(c.x + cos(a) * rr * sx, c.y + sin(a) * rr))
	draw_colored_polygon(outer, col)
	draw_polyline(outer, col.darkened(0.5), maxf(1.0, 1.5 * _f), true)
	var spiral := PackedVector2Array()
	for k in 40:
		var a := TAU * 1.6 * k / 40.0
		var rr := radius * (0.15 + 0.6 * k / 40.0)
		spiral.append(_p(c.x + cos(a) * rr * sx, c.y + sin(a) * rr))
	draw_polyline(spiral, col.darkened(0.45), maxf(1.0, 1.5 * _f), true)
	draw_circle(_p(c.x, c.y), radius * 0.2 * _f, CARBON)


## Motor generator: a finned cylinder with end caps and a shaft.
func _draw_ers(col: Color) -> void:
	draw_rect(_r(276, 156, 16, 8), PIPE)
	_box(_r(290, 140, 78, 46), col, 10)
	for k in 9:
		var x := 300.0 + k * 7.5
		draw_line(_p(x, 144), _p(x, 182), col.darkened(0.35), maxf(1.0, 1.5 * _f))
	_box(_r(286, 144, 10, 38), col.darkened(0.3), 4)
	_box(_r(362, 144, 10, 38), col.darkened(0.3), 4)
	var bolt := PackedVector2Array([_p(332, 146), _p(322, 165), _p(330, 165), _p(326, 180), _p(340, 160),
		_p(332, 160), _p(338, 146)])
	draw_colored_polygon(bolt, CARBON)


## Battery pack: case, a grid of cells, two terminals.
func _draw_battery(col: Color) -> void:
	_box(_r(416, 22, 76, 64), col.darkened(0.3), 8)
	for row in 3:
		for k in 4:
			_box(_r(422 + k * 17.5, 28 + row * 18.5, 14, 15), col.lightened(0.06 if (row + k) % 2 == 0 else 0.0), 3)
	draw_rect(_r(426, 14, 12, 8), CARBON)
	draw_rect(_r(470, 14, 12, 8), CARBON)
	var w := maxf(1.0, 1.5 * _f)
	draw_line(_p(429, 18), _p(435, 18), col, w)
	draw_line(_p(473, 18), _p(479, 18), col, w)
	draw_line(_p(476, 15), _p(476, 21), col, w)


## Control electronics: circuit board with chips and traces.
func _draw_control(col: Color) -> void:
	_box(_r(412, 140, 84, 48), col, 6)
	var trace := col.darkened(0.35)
	var w := maxf(1.0, 1.2 * _f)
	for y in [150.0, 164.0, 178.0]:
		draw_line(_p(418, y), _p(490, y), trace, w)
	_box(_r(426, 148, 26, 26), CARBON, 3)
	for k in 4:
		draw_line(_p(429 + k * 6, 145), _p(429 + k * 6, 148), trace, w)
		draw_line(_p(429 + k * 6, 174), _p(429 + k * 6, 177), trace, w)
	_box(_r(460, 152, 14, 14), CARBON, 2)
	_box(_r(478, 168, 12, 12), CARBON, 2)
	for k in 3:
		draw_circle(_p(466 + k * 8, 180), 2 * _f, col.lightened(0.3))


func _box(r: Rect2, col: Color, radius: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = col
	box.border_color = col.darkened(0.5)
	box.set_border_width_all(1)
	box.set_corner_radius_all(roundi(radius * _f))
	box.anti_aliasing = true
	draw_style_box(box, r)


## Name and spec under each drawing.
func _caption(c: StringName) -> void:
	var r: Rect2 = LAYOUT[c]
	var entry: Array = info.get(c, ["", UIStyle.MUTED])
	var font := UIStyle.font(&"body_semibold")
	var mono := UIStyle.font(&"mono")
	var y := r.end.y - 22.0
	var width := r.size.x * _f
	draw_string(font, _p(r.position.x, y), tr(PowerUnit.name_of(c)), HORIZONTAL_ALIGNMENT_CENTER, width,
		roundi(maxf(11.0, 13.0 * _f)), UIStyle.TEXT)
	draw_string(mono, _p(r.position.x, y + 15), entry[0], HORIZONTAL_ALIGNMENT_CENTER, width,
		roundi(maxf(10.0, 11.0 * _f)), entry[1])
