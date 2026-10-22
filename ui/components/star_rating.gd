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


## A single star (filled or outline), e.g. for shortlist buttons.
static func single(filled: bool, star_size: int = 18) -> Texture2D:
	var key := "single_%s_%d" % [filled, star_size]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var points := PackedStringArray()
	for p in _star_points(Vector2(1, 1), star_size - 2):
		points.append("%.2f,%.2f" % [p.x, p.y])
	var amber := "#" + UIStyle.ACCENT.to_html(false)
	var grey := "#" + UIStyle.MUTED.to_html(false)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"><polygon points="%s" %s/></svg>' % [
		star_size, star_size, " ".join(points),
		('fill="%s"' % amber) if filled else ('fill="none" stroke="%s" stroke-width="1.3"' % grey)]
	var image := Image.new()
	image.load_svg_from_string(svg)
	var tex := ImageTexture.create_from_image(image)
	_texture_cache[key] = tex
	return tex


## Uncertain rating: filled up to `lo`, outlined up to `hi` (decision 39).
static func texture_range(lo: float, hi: float, star_size: int = 15) -> Texture2D:
	if is_equal_approx(lo, hi):
		return texture(lo, star_size)
	var key := "r%s_%s_%d" % [lo, hi, star_size]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var width := 5 * star_size + 4 * int(GAP)
	var amber := "#" + UIStyle.ACCENT.to_html(false)
	var empty := "#" + UIStyle.LINE_STRONG.to_html(false)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">' % [width, star_size]
	for i in 5:
		var origin := Vector2(i * (star_size + GAP), 0)
		var points := PackedStringArray()
		for p in _star_points(origin + Vector2(0.6, 0.6), star_size - 1.2):
			points.append("%.2f,%.2f" % [p.x, p.y])
		var shape := " ".join(points)
		var ghost := clampf(hi - i, 0.0, 1.0)
		var fill := clampf(lo - i, 0.0, 1.0)
		if ghost <= 0.0:
			svg += '<polygon points="%s" fill="%s"/>' % [shape, empty]
		else:
			svg += '<clipPath id="g%d"><rect x="%.2f" y="0" width="%.2f" height="%d"/></clipPath>' % [i, origin.x, star_size * ghost, star_size]
			svg += '<polygon points="%s" fill="none" stroke="%s" stroke-width="1.1" clip-path="url(#g%d)"/>' % [shape, amber, i]
		if fill > 0.0:
			svg += '<clipPath id="f%d"><rect x="%.2f" y="0" width="%.2f" height="%d"/></clipPath>' % [i, origin.x, star_size * fill, star_size]
			svg += '<polygon points="%s" fill="%s" clip-path="url(#f%d)"/>' % [shape, amber, i]
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
