## 0..5 stars in half steps, drawn as polygons (no font glyphs needed).
class_name StarRating
extends Control

const STAR_SIZE := 18.0
const GAP := 3.0

var value: float


func _init(p_value: float = 0.0, star_size: float = STAR_SIZE) -> void:
	value = p_value
	custom_minimum_size = Vector2(5 * star_size + 4 * GAP, star_size)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_stars(self, Rect2(Vector2.ZERO, size), value, size.y)


static var _texture_cache := {}


## Star rating as a texture, for table cells (Tree icons). Built from SVG
## once per value and size, then cached.
static func texture(stars: float, star_size: int = 15) -> Texture2D:
	var key := "%s_%d" % [stars, star_size]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var width := 5 * star_size + 4 * int(GAP)
	var full := "#" + UIStyle.ACCENT.to_html(false)
	var empty := "#" + UIStyle.LINE_STRONG.to_html(false)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">' % [width, star_size]
	for i in 5:
		var origin := Vector2(i * (star_size + GAP), 0)
		var points := PackedStringArray()
		for p in _star_points(origin, star_size):
			points.append("%.2f,%.2f" % [p.x, p.y])
		var shape := " ".join(points)
		svg += '<polygon points="%s" fill="%s"/>' % [shape, empty]
		var fill := clampf(stars - i, 0.0, 1.0)
		if fill > 0.0:
			svg += '<clipPath id="c%d"><rect x="%.2f" y="0" width="%.2f" height="%d"/></clipPath>' % [
				i, origin.x, star_size * fill, star_size]
			svg += '<polygon points="%s" fill="%s" clip-path="url(#c%d)"/>' % [shape, full, i]
	svg += "</svg>"
	var image := Image.new()
	image.load_svg_from_string(svg)
	var tex := ImageTexture.create_from_image(image)
	_texture_cache[key] = tex
	return tex


static func draw_stars(canvas: CanvasItem, rect: Rect2, stars: float, star_size: float) -> void:
	var y := rect.position.y + (rect.size.y - star_size) / 2.0
	for i in 5:
		var origin := Vector2(rect.position.x + i * (star_size + GAP), y)
		var shape := _star_points(origin, star_size)
		canvas.draw_colored_polygon(shape, UIStyle.LINE_STRONG)
		var fill := clampf(stars - i, 0.0, 1.0)
		if fill >= 1.0:
			canvas.draw_colored_polygon(shape, UIStyle.ACCENT)
		elif fill > 0.0:
			var clip := PackedVector2Array([origin, origin + Vector2(star_size * fill, 0),
				origin + Vector2(star_size * fill, star_size), origin + Vector2(0, star_size)])
			for part in Geometry2D.intersect_polygons(shape, clip):
				canvas.draw_colored_polygon(part, UIStyle.ACCENT)


static func _star_points(origin: Vector2, s: float) -> PackedVector2Array:
	var center := origin + Vector2(s, s) / 2.0
	var points := PackedVector2Array()
	for k in 10:
		var angle := -PI / 2.0 + k * PI / 5.0
		var radius := s / 2.0 if k % 2 == 0 else s * 0.22
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
