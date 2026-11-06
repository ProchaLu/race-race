## Where the 13 parts sit on the car seen from above (300 × 720, nose up).
## The shapes are smooth outlines (Catmull-Rom through the control points) of a
## modern single-seater; symmetric parts are given as the right half and
## mirrored. Hit zones are the drawn shapes, except for the thin suspension arms.
class_name CarLayout
extends RefCounted

const SIZE := Vector2(300, 720)
## Drawing order: floor under the bodywork, the nose over the front wing,
## the rear wing on top.
const ORDER := [&"floor", &"front_wing", &"suspension_front", &"brakes", &"suspension_rear", &"diffuser",
	&"gearbox", &"exhaust", &"sidepods", &"cooling", &"monocoque", &"engine_cover", &"rear_wing"]
## Wheels: [x, y, width, height] (left side; the right side is mirrored).
const WHEELS := [[34, 100, 46, 88], [22, 552, 62, 104]]

static var _shapes: Dictionary = {}


## Smooth outline polygons of a part, scaled.
static func polygons(part_id: StringName, scale: float) -> Array[PackedVector2Array]:
	return _scaled(_all()[part_id].draw, scale)


## Polygons used for clicking (the same as the drawing for most parts).
static func hit_polygons(part_id: StringName, scale: float) -> Array[PackedVector2Array]:
	var s: Dictionary = _all()[part_id]
	return _scaled(s.get("hit", s.draw), scale)


## Wheel rectangles (both sides), scaled.
static func wheels(scale: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for w in WHEELS:
		out.append(Rect2(Vector2(w[0], w[1]) * scale, Vector2(w[2], w[3]) * scale))
		out.append(Rect2(Vector2(SIZE.x - w[0] - w[2], w[1]) * scale, Vector2(w[2], w[3]) * scale))
	return out


## Symbol of a part (assets/parts/<id>.svg, made by tools/part_icons.tscn).
static func icon(part_id: StringName) -> Texture2D:
	return load("res://assets/parts/%s.svg" % part_id)


static func _scaled(polys: Array, scale: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for poly in polys:
		var p := PackedVector2Array()
		for pt in poly:
			p.append(pt * scale)
		out.append(p)
	return out


static func _all() -> Dictionary:
	if _shapes.is_empty():
		_shapes = _build()
	return _shapes


static func _build() -> Dictionary:
	var s := {}
	s[&"floor"] = {"draw": [_sym([[150, 286], [196, 286], [232, 300], [250, 338], [255, 420], [252, 482],
		[238, 522], [214, 548], [206, 600], [186, 614], [150, 616]])]}
	s[&"front_wing"] = {"draw": [_sym([[150, 48], [200, 44], [248, 38], [272, 36], [276, 60], [252, 70],
		[208, 74], [168, 70], [150, 68]]),
		_rect(270, 22, 10, 56), _rect(20, 22, 10, 56)]}
	s[&"suspension_front"] = {"draw": _pair(_raw([[168, 124], [84, 142], [84, 150], [170, 134]]))
		+ _pair(_raw([[172, 172], [84, 152], [84, 160], [172, 182]])),
		"hit": _pair(_raw([[164, 118], [176, 186], [80, 156], [80, 138]]))}
	s[&"brakes"] = {"draw": _pair(_rounded(210, 126, 10, 40)) + _pair(_rounded(206, 584, 10, 42))}
	s[&"suspension_rear"] = {"draw": _pair(_raw([[160, 604], [216, 596], [216, 604], [160, 614]]))
		+ _pair(_raw([[162, 636], [216, 608], [216, 616], [162, 646]])),
		"hit": _pair(_raw([[156, 598], [218, 592], [218, 620], [160, 652]]))}
	s[&"diffuser"] = {"draw": _pair(_raw([[166, 630], [208, 624], [214, 662], [206, 694], [166, 696]]))}
	s[&"gearbox"] = {"draw": [_sym([[150, 598], [163, 602], [166, 640], [162, 670], [150, 674]])]}
	s[&"exhaust"] = {"draw": [_sym([[150, 666], [158, 668], [159, 684], [150, 690]])]}
	s[&"sidepods"] = {"draw": _pair(_smooth([[188, 314], [230, 314], [242, 336], [246, 400], [238, 462],
		[220, 512], [198, 548], [182, 556], [178, 460], [182, 360]]))}
	var cooling := _pair(_smooth([[188, 310], [232, 310], [242, 326], [240, 334], [190, 332]]))
	for i in 4:
		var y := 404.0 + i * 13.0
		cooling += _pair(_raw([[202 + i * 1.5, y], [228 - i * 2.5, y - 2], [228 - i * 2.5, y + 4], [202 + i * 1.5, y + 6]]))
	s[&"cooling"] = {"draw": cooling}
	s[&"monocoque"] = {"draw": [_sym([[150, 28], [157, 32], [161, 64], [165, 124], [171, 184], [180, 232],
		[187, 280], [186, 320], [178, 356], [150, 362]])]}
	s[&"engine_cover"] = {"draw": [_sym([[150, 314], [168, 318], [182, 352], [189, 420], [186, 494],
		[174, 556], [163, 606], [150, 622]])]}
	s[&"rear_wing"] = {"draw": [_raw([[64, 680], [236, 680], [238, 712], [62, 712]]),
		_rect(236, 670, 10, 48), _rect(54, 670, 10, 48)]}
	return s


# --- Shape helpers (design space) -----------------------------------------------

## Right half from the top centre to the bottom centre, mirrored and smoothed.
static func _sym(half: Array) -> PackedVector2Array:
	var pts := []
	for p in half:
		pts.append(p)
	for i in range(half.size() - 2, 0, -1):
		pts.append([SIZE.x - half[i][0], half[i][1]])
	return _smooth(pts)


## A right-side polygon (or several) and the mirror images on the left.
static func _pair(right) -> Array:
	var polys: Array = right if right is Array else [right]
	var out := []
	for poly in polys:
		out.append(poly)
		var m := PackedVector2Array()
		for i in range(poly.size() - 1, -1, -1):
			m.append(Vector2(SIZE.x - poly[i].x, poly[i].y))
		out.append(m)
	return out


static func _raw(points: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for pt in points:
		p.append(Vector2(pt[0], pt[1]))
	return p


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return _raw([[x, y], [x + w, y], [x + w, y + h], [x, y + h]])


static func _rounded(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	var r := minf(w, h) * 0.45
	return _smooth([[x + r, y], [x + w - r, y], [x + w, y + r], [x + w, y + h - r], [x + w - r, y + h],
		[x + r, y + h], [x, y + h - r], [x, y + r]], 3)


## Closed Catmull-Rom curve through the points.
static func _smooth(points: Array, steps: int = 6) -> PackedVector2Array:
	var pts: Array[Vector2] = []
	for p in points:
		pts.append(Vector2(p[0], p[1]))
	var n := pts.size()
	var out := PackedVector2Array()
	for i in n:
		var p0 := pts[(i - 1 + n) % n]
		var p1 := pts[i]
		var p2 := pts[(i + 1) % n]
		var p3 := pts[(i + 2) % n]
		for k in steps:
			var t := float(k) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out
