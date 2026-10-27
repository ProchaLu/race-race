## Where the 13 parts sit on the car seen from above (300 × 720, nose up).
## Same coordinates as assets/car/car_top.svg and docs/ui_mockups/r3_car.html,
## so the final artwork can replace the placeholder and the zones still fit.
class_name CarLayout
extends RefCounted

const SIZE := Vector2(300, 720)
## Drawn in this order (floor under the bodywork, brakes on the wheels).
const ZONES := {
	&"floor": [[[68, 282], [232, 282], [238, 520], [214, 562], [86, 562], [62, 520]]],
	&"sidepods": [[[90, 322], [124, 322], [124, 505], [106, 528], [92, 470]], [[210, 322], [176, 322], [176, 505], [194, 528], [208, 470]]],
	&"cooling": [[[90, 298], [124, 298], [124, 320], [90, 320]], [[176, 298], [210, 298], [210, 320], [176, 320]]],
	&"engine_cover": [[[124, 380], [176, 380], [172, 520], [160, 560], [140, 560], [128, 520]]],
	&"monocoque": [[[138, 60], [162, 60], [172, 150], [178, 300], [176, 380], [124, 380], [122, 300], [128, 150]]],
	&"suspension_front": [[[76, 120], [128, 110], [128, 148], [76, 142]], [[224, 120], [172, 110], [172, 148], [224, 142]]],
	&"suspension_rear": [[[80, 548], [134, 540], [134, 575], [80, 585]], [[220, 548], [166, 540], [166, 575], [220, 585]]],
	&"gearbox": [[[138, 560], [162, 560], [160, 630], [140, 630]]],
	&"exhaust": [[[143, 630], [157, 630], [157, 648], [143, 648]]],
	&"diffuser": [[[96, 615], [138, 605], [138, 652], [100, 656]], [[204, 615], [162, 605], [162, 652], [200, 656]]],
	&"front_wing": [[[30, 18], [270, 18], [270, 52], [200, 60], [100, 60], [30, 52]]],
	&"rear_wing": [[[55, 662], [245, 662], [245, 702], [55, 702]]],
	&"brakes": [[[46, 124], [58, 124], [58, 146], [46, 146]], [[242, 124], [254, 124], [254, 146], [242, 146]],
		[[38, 558], [50, 558], [50, 582], [38, 582]], [[250, 558], [262, 558], [262, 582], [250, 582]]],
}
## Wheels: [x, y, width, height]
const WHEELS := [[28, 95, 48, 80], [224, 95, 48, 80], [20, 525, 60, 90], [220, 525, 60, 90]]


static func polygons(part_id: StringName, scale: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for poly in ZONES[part_id]:
		var p := PackedVector2Array()
		for pt in poly:
			p.append(Vector2(pt[0], pt[1]) * scale)
		out.append(p)
	return out


## Placeholder symbol of a part (assets/parts/<id>.svg).
static func icon(part_id: StringName) -> Texture2D:
	return load("res://assets/parts/%s.svg" % part_id)
