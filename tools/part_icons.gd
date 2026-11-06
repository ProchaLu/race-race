## Writes assets/parts/<id>.svg (64 × 64, white) from the part shapes in
## ui/car_layout.gd, so the symbols match the car drawing.
## godot --headless --path . res://tools/part_icons.tscn
extends Node


func _ready() -> void:
	for id in CarLayout.ORDER:
		var polys := CarLayout.polygons(id, 1.0)
		var box := Rect2(polys[0][0], Vector2.ZERO)
		for poly in polys:
			for pt in poly:
				box = box.expand(pt)
		var factor := 56.0 / maxf(box.size.x, box.size.y)
		var offset := Vector2(32, 32) - box.get_center() * factor
		var svg := '<?xml version="1.0" encoding="UTF-8"?>\n'
		svg += '<!-- Symbol: %s. Made by tools/part_icons.tscn from ui/car_layout.gd. -->\n' % id
		svg += '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">\n'
		for poly in polys:
			var pts := PackedStringArray()
			for pt in poly:
				var q: Vector2 = pt * factor + offset
				pts.append("%.1f,%.1f" % [q.x, q.y])
			svg += '<polygon points="%s" fill="#ffffff" stroke="#ffffff" stroke-width="0.8" stroke-linejoin="round"/>\n' % " ".join(pts)
		svg += "</svg>\n"
		var f := FileAccess.open("res://assets/parts/%s.svg" % id, FileAccess.WRITE)
		f.store_string(svg)
		f.close()
		print("wrote ", id)
	get_tree().quit()
