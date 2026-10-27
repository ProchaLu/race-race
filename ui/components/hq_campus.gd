## Interactive HQ campus. Full-resolution compositing preserves building art.
## The ground is its own layer behind the buildings (slightly desaturated so
## the dark UI and the buildings stand out); the building layer is only
## re-rendered when something visible changes. Picking uses the same image
## transform as rendering; building data and actions live in Facilities.
class_name HqCampus
extends TextureRect

signal facility_selected(id: StringName)

const CANVAS := Vector2i(1600, 1000)
const SCALE := 2.5
const INK := Color("#273940")
const WALL := Color("#e1dcc7")
const GLASS := Color("#99c9d3")
const BRICK := Color("#ad7658")
const SHADOW := Color("#536e4b")
const ATLAS_PATHS := ["res://assets/hq/engineering_levels.png", "res://assets/hq/development_levels.png", "res://assets/hq/operations_levels.png"]
# Measured source row boundaries: generation does not produce exact grid gutters.
# Source rects stay separate from fixed campus anchors.
const ATLAS_ROWS := [[40, 230, 430, 655, 905, 1190], [40, 255, 500, 755, 997, 1255], [65, 250, 475, 690, 930, 1200]]
## Site anchor and reserved area per facility (world units). The order is
## the order of the art atlases: 5 facilities per sheet, one row per level.
const SITES := [
	[&"design", Vector2i(39, 35), Vector2i(103, 73)],
	[&"wind", Vector2i(172, 24), Vector2i(119, 88)],
	[&"cfd", Vector2i(317, 34), Vector2i(94, 75)],
	[&"factory", Vector2i(454, 28), Vector2i(136, 86)],
	[&"composites", Vector2i(477, 143), Vector2i(107, 74)],
	[&"engine", Vector2i(352, 139), Vector2i(99, 77)],
	[&"lab", Vector2i(224, 143), Vector2i(100, 70)],
	[&"simulator", Vector2i(43, 145), Vector2i(78, 70)],
	[&"performance", Vector2i(37, 244), Vector2i(94, 64)],
	[&"academy", Vector2i(42, 321), Vector2i(106, 58)],
	[&"scouting", Vector2i(176, 338), Vector2i(49, 39)],
	[&"pit", Vector2i(169, 243), Vector2i(162, 51)],
	[&"mission", Vector2i(365, 249), Vector2i(91, 53)],
	[&"hospitality", Vector2i(490, 244), Vector2i(101, 71)],
	[&"staff", Vector2i(479, 340), Vector2i(103, 39)],
]
const GROUND_SHADER := """
shader_type canvas_item;
uniform float saturation = 0.8;
uniform float brightness = 0.9;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(grey), c.rgb, saturation) * brightness, c.a);
}
"""

var levels: Dictionary = {}
var selected: StringName = &""
## Names of all buildings on the campus (otherwise only on hover).
var show_names := false
## Decorative movement (pit-crew drill, people, a transporter). Off = still image.
var animate := true
var _team: TeamData
var _hovered: StringName = &""
var _hit_rects: Dictionary = {}
var _hit_images: Dictionary = {}
var _projects: Dictionary = {}
var _pixels: Image
var _accent := Color("#cc5946")
## What the building layer was rendered from (levels, sites, progress steps).
var _signature := ""
static var _sprites: Array[Image] = []
static var _terrain: Image
static var _terrain_texture: ImageTexture
## "id|level|width|height" -> scaled sprite (resizing is the slow part).
static var _scaled: Dictionary = {}


func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Refined pixel art stays detailed when the viewport is smaller than the canvas.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func():
		_hovered = &""
		queue_redraw())
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(320, 200)
	var ground := TextureRect.new()
	ground.name = "Ground"
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.show_behind_parent = true
	var shader := Shader.new()
	shader.code = GROUND_SHADER
	var material_ground := ShaderMaterial.new()
	material_ground.shader = shader
	ground.material = material_ground
	add_child(ground)


## Reads the team's campus. Cheap when nothing visible changed (the
## construction badge is drawn on top and always up to date).
func configure(team: TeamData) -> void:
	_team = team
	Facilities.level(team, &"design")
	levels = team.facilities.duplicate()
	_projects = team.facility_projects.duplicate(true)
	_accent = team.primary_color
	_load_sprites()
	_load_terrain()
	($Ground as TextureRect).texture = _terrain_texture
	var signature := "%s|%s" % [levels, _project_steps()]
	if signature != _signature:
		_signature = signature
		_render()
	queue_redraw()


## Construction art changes at 30 % and 65 % progress.
func _project_steps() -> String:
	var parts := PackedStringArray()
	for id in _projects:
		var progress := 1.0 - float(_projects[id].remaining) / float(_projects[id].duration)
		parts.append("%s:%d" % [id, 0 if progress < 0.3 else (1 if progress < 0.65 else 2)])
	return ",".join(parts)


func _box(x: float, y: float, w: float, h: float, color: Color) -> void:
	_pixels.fill_rect(Rect2i(roundi(x * SCALE), roundi(y * SCALE), maxi(1, roundi(w * SCALE)), maxi(1, roundi(h * SCALE))), color)


func _frame(x: float, y: float, w: float, h: float, color: Color) -> void:
	_box(x, y, w, h, INK)
	_box(x + 0.6, y + 0.6, w - 1.2, h - 1.2, color)


func _disc(x: float, y: float, rx: float, ry: float, color: Color) -> void:
	var cx := roundi(x * SCALE)
	var cy := roundi(y * SCALE)
	var radius_x := maxi(1, roundi(rx * SCALE))
	var radius_y := maxi(1, roundi(ry * SCALE))
	for row in range(-radius_y, radius_y + 1):
		var half_width := roundi(radius_x * sqrt(maxf(0, 1.0 - pow(float(row) / radius_y, 2))))
		_pixels.fill_rect(Rect2i(cx - half_width, cy + row, half_width * 2 + 1, 1), color)


func _stroke(points: Array, width: float, color: Color) -> void:
	for index in range(points.size() - 1):
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		var steps := maxi(1, ceili(a.distance_to(b) * SCALE))
		for step in range(steps + 1):
			var point := a.lerp(b, float(step) / steps)
			_disc(point.x, point.y, width / 2, width / 2, color)


func _render() -> void:
	_hit_rects.clear()
	_hit_images.clear()
	_pixels = Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	_pixels.fill(Color.TRANSPARENT)
	for site in SITES:
		var origin: Vector2i = site[1]
		var bounds: Vector2i = site[2]
		if int(levels.get(site[0], 0)) > 0:
			_building(site[0], origin, bounds, int(levels[site[0]]))
		elif not _projects.has(site[0]):
			_empty_plot(SITES.find(site), origin, bounds)
	for site in SITES:
		if _projects.has(site[0]):
			_construction_site(site)
	_details()
	texture = ImageTexture.create_from_image(_pixels)
	queue_redraw()


func _work_rect(id: StringName) -> Rect2:
	for site in SITES:
		if site[0] != id:
			continue
		var rect := Rect2(Vector2(site[1]) * SCALE, Vector2(site[2]) * SCALE)
		if _hit_rects.has(id):
			var used: Rect2i = _hit_images[id].get_used_rect()
			rect = rect.merge(Rect2(_hit_rects[id].position + Vector2(used.position), Vector2(used.size)).grow(5))
		return rect.intersection(Rect2(26, 28, CANVAS.x - 52, CANVAS.y - 66))
	return Rect2()


## Unused plots are not empty lawn: a storage yard, overflow parking or a
## landscaped corner – cleared when construction starts.
func _empty_plot(index: int, p: Vector2i, bounds: Vector2i) -> void:
	var left := p.x + 10.0
	var top := p.y + 10.0
	var w := bounds.x - 20.0
	var h := bounds.y - 20.0
	if w < 20 or h < 14:
		return
	match index % 3:
		0:
			# Storage yard: gravel, containers, pallets.
			_box(left, top, w, h, Color("#a39a84"))
			_box(left + 1, top + 1, w - 2, h - 2, Color("#b5ad97"))
			var colors := [Color("#4f6d7a"), Color("#a1543c"), Color("#c9a54a"), _accent.darkened(0.2)]
			var x := left + 4
			var k := 0
			while x + 12 < left + w - 4:
				_frame(x, top + 4, 11, 6, colors[k % colors.size()])
				if h > 24:
					_frame(x, top + 12, 11, 6, colors[(k + 2) % colors.size()])
				x += 14
				k += 1
			for i in range(3):
				_frame(left + 4 + i * 6, top + h - 7, 4.5, 4, Color("#b19167"))
		1:
			# Overflow parking with a few cars.
			_box(left, top, w, h, Color("#5d6566"))
			var cars := [Color("#d9d6bf"), Color("#3f4f63"), Color("#9b2f2f"), Color("#d9d6bf"), Color("#2f6b4f")]
			var x := left + 3
			var k := 0
			while x + 6 < left + w - 2:
				_box(x - 1, top + 2, 0.5, h * 0.45, WALL)
				if (k * 7 + index) % 3 != 0:
					_frame(x, top + 3, 5, 8, cars[k % cars.size()])
				x += 8
				k += 1
		2:
			# Landscaped corner: trees, a path and a bench.
			_stroke([Vector2(left, top + h * 0.7), Vector2(left + w * 0.5, top + h * 0.45), Vector2(left + w, top + h * 0.6)], 2.5, Color("#c9c1a6"))
			for i in range(int(w / 18.0)):
				var tx := left + 8 + i * 18 + (i % 2) * 4
				var ty := top + 6 + (i % 2) * (h * 0.5)
				_disc(tx + 1.5, ty + 2.5, 6.5, 4.5, SHADOW)
				_disc(tx, ty, 6.6, 5.6, Color("#2c4a28"))
				_disc(tx, ty, 6, 5, Color("#3f6b35"))
				_disc(tx - 1.5, ty - 1.5, 3.5, 3, Color("#5c8f47"))
				_disc(tx - 2.5, ty - 2.5, 1.5, 1.2, Color("#7fb05e"))
			_frame(left + w * 0.5 - 4, top + h * 0.45 - 4, 8, 2.5, Color("#8a6a4a"))


func _construction_site(site: Array) -> void:
	var id: StringName = site[0]
	var native := _work_rect(id)
	var rect := Rect2(native.position / SCALE, native.size / SCALE)
	var left := rect.position.x
	var top := rect.position.y
	var right := rect.end.x
	var bottom := rect.end.y
	var project: Dictionary = _projects[id]
	var progress := 1.0 - float(project.remaining) / float(project.duration)
	var upgrade := int(levels.get(id, 0)) > 0
	if not upgrade:
		# The enclosed worksite is visible from day one; structure rises later.
		_box(left + 2, top + 3, rect.size.x - 4, rect.size.y - 6, Color("#a19578"))
		_box(left + 9, top + 12, rect.size.x - 25, rect.size.y - 26, Color("#bbb8a3"))
		for x in range(roundi(left + 11), roundi(right - 14), 9):
			_box(x, top + 13, 0.5, rect.size.y - 28, Color("#8b9187"))
		for y in range(roundi(top + 14), roundi(bottom - 13), 9):
			_box(left + 10, y, rect.size.x - 27, 0.5, Color("#8b9187"))
		# Foundations and the rising structural frame communicate progress.
		for x in range(roundi(left + 12), roundi(right - 14), 14):
			_frame(x, top + 15, 5, 5, WALL)
			_frame(x, bottom - 18, 5, 5, WALL)
			if progress >= 0.3:
				_box(x + 2, top + 7, 1, rect.size.y - 21, Color("#687b80"))
		if progress >= 0.65:
			_box(left + 12, top + 9, rect.size.x - 28, 3, Color("#53666c"))
			_box(left + 12, top + 12, 3, rect.size.y - 29, Color("#d3c9ab"))
	else:
		# Transparent safety netting preserves the operating building underneath.
		var net := Image.create(maxi(1, roundi((rect.size.x - 8) * SCALE)), roundi(12 * SCALE), false, Image.FORMAT_RGBA8)
		net.fill(Color(0.23, 0.44, 0.48, 0.32))
		_pixels.blend_rect(net, Rect2i(Vector2i.ZERO, net.get_size()), Vector2i(roundi((left + 4) * SCALE), roundi((bottom - 17) * SCALE)))
		for x in range(roundi(left + 5), roundi(right - 3), 12):
			_box(x + 1, bottom - 24, 0.8, 24, INK)
			_box(x, bottom - 25, 0.8, 24, Color("#d3d2b9"))
			_stroke([Vector2(x, bottom - 22), Vector2(minf(x + 12, right - 4), bottom - 6)], 0.5, WALL)
		_box(left + 4, bottom - 21, rect.size.x - 8, 1.4, Color("#b6a67f"))
		_box(left + 4, bottom - 11, rect.size.x - 8, 1.4, Color("#b6a67f"))
	# Continuous hoarding, posts and hazard panels, with a front access opening.
	_box(left, top, rect.size.x, 1.2, Color("#627a7d"))
	_box(left, top, 1.2, rect.size.y, Color("#627a7d"))
	_box(right - 1.2, top, 1.2, rect.size.y, Color("#627a7d"))
	for x in range(roundi(left), roundi(right), 8):
		_box(x, top - 1, 1, 3, WALL)
		if absf(x - rect.get_center().x) > 8:
			_box(x, bottom - 3, 7.5, 3, Color("#e7b34c"))
			_box(x + 1, bottom - 3, 2.5, 3, INK)
	for y in range(roundi(top), roundi(bottom), 9):
		_box(left - 0.3, y, 1.8, 1, WALL)
		_box(right - 1.5, y, 1.8, 1, WALL)
	# Materials and a cabin stay inside the site instead of blocking public roads.
	for offset in [0, 4, 8]:
		_frame(left + 6, bottom - 14 - offset, 12, 2.5, Color("#b19167"))
	_frame(right - 19, bottom - 14, 14, 8, Color("#d9d6bf"))
	_box(right - 17, bottom - 12, 5, 3, GLASS)
	_crane(right - 9, top + minf(34, rect.size.y * 0.5), minf(37, rect.size.x * 0.42))
	_person(left + 8, bottom - 6, Color("#eab04a"))


func _crane(x: float, y: float, reach: float) -> void:
	var steel := Color("#e1ad42")
	var light := Color("#f3d67f")
	_box(x - 3, y + 17, 7, 5, Color("#677273"))
	_box(x - 1.5, y - 17, 3, 36, steel)
	for step in range(-15, 18, 5):
		_stroke([Vector2(x - 1.5, y + step), Vector2(x + 1.5, y + step + 4)], 0.5, INK)
	_box(x - reach, y - 18, reach + 12, 3, steel)
	_box(x - reach, y - 18, reach + 12, 0.6, light)
	_stroke([Vector2(x, y - 25), Vector2(x - reach, y - 17)], 0.5, INK)
	_stroke([Vector2(x, y - 25), Vector2(x + 11, y - 17)], 0.5, INK)
	_box(x, y - 25, 0.7, 9, steel)
	_box(x - reach + 4, y - 16, 0.5, 24, INK)
	_box(x - reach + 3, y + 7, 2, 2, steel)
	_frame(x + 5, y - 19, 7, 5, Color("#65757a"))


func _load_terrain() -> void:
	if _terrain == null:
		var source: Image = load("res://assets/hq/campus_ground_v3.png").get_image()
		source.convert(Image.FORMAT_RGBA8)
		# Align authored road bands to world coordinates. The source artwork is
		# continuous; texture resampling preserves the same asphalt and curb style.
		# No second road/path renderer paints across it.
		var source_y := [0.0, 122.0, 229.0, 331.0, 375.0, 400.0]
		var world_y := [0.0, 122.0, 233.0, 326.0, 388.0, 400.0]
		_terrain = Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
		for band in range(source_y.size() - 1):
			var top := roundi(source_y[band] / 400.0 * source.get_height())
			var bottom := roundi(source_y[band + 1] / 400.0 * source.get_height())
			var destination_top := roundi(world_y[band] * SCALE)
			var destination_bottom := roundi(world_y[band + 1] * SCALE)
			var strip := source.get_region(Rect2i(0, top, source.get_width(), bottom - top))
			strip.resize(CANVAS.x, destination_bottom - destination_top, Image.INTERPOLATE_LANCZOS)
			_terrain.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, destination_top))
		_terrain_texture = ImageTexture.create_from_image(_terrain)


func _load_sprites() -> void:
	if not _sprites.is_empty():
		return
	for group in range(ATLAS_PATHS.size()):
		var path: String = ATLAS_PATHS[group]
		var atlas: Image = load(path).get_image()
		for row in range(5):
			for column in range(5):
				var left := roundi(column * atlas.get_width() / 5.0)
				var right := roundi((column + 1) * atlas.get_width() / 5.0)
				var top := roundi(ATLAS_ROWS[group][row] * atlas.get_height() / 1280.0)
				var bottom := roundi(ATLAS_ROWS[group][row + 1] * atlas.get_height() / 1280.0)
				var tile := atlas.get_region(Rect2i(left, top, right - left, bottom - top))
				var clean := _isolated_sprite(tile)
				var used := clean.get_used_rect()
				# A shared source scale across all five levels, with a common baseline.
				var normalized := Image.create(256, 320, false, Image.FORMAT_RGBA8)
				normalized.fill(Color.TRANSPARENT)
				normalized.blit_rect(clean, used, Vector2i((256 - used.size.x) / 2, 310 - used.size.y))
				_sprites.append(normalized)


func _isolated_sprite(tile: Image) -> Image:
	# Import-time isolation drops stray disconnected pixels in transparent gutters.
	var width := tile.get_width()
	var height := tile.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var largest := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			var pixel := y * width + x
			if visited[pixel] or tile.get_pixel(x, y).a < 0.35:
				continue
			var component := PackedInt32Array([pixel])
			visited[pixel] = 1
			var cursor := 0
			while cursor < component.size():
				var current := component[cursor]
				cursor += 1
				for offset in [-1, 1, -width, width]:
					var next: int = current + offset
					if next < 0 or next >= visited.size() or visited[next]:
						continue
					if abs(next % width - current % width) > 1:
						continue
					if tile.get_pixel(next % width, next / width).a < 0.35:
						continue
					visited[next] = 1
					component.append(next)
			if component.size() > largest.size():
				largest = component
	var clean := Image.create(width, height, false, Image.FORMAT_RGBA8)
	clean.fill(Color.TRANSPARENT)
	for pixel in largest:
		clean.set_pixel(pixel % width, pixel / width, tile.get_pixel(pixel % width, pixel / width))
	return clean


func _building(id: StringName, p: Vector2i, bounds: Vector2i, level: int) -> void:
	var facility := 0
	for site in SITES:
		if site[0] == id:
			break
		facility += 1
	var group := facility / 5
	var column := facility % 5
	# Full-resolution sprites retain detail; no 640px intermediary or fake annexes.
	var extent := Vector2i(roundi(bounds.x * SCALE), roundi(bounds.y * SCALE))
	# Fit the largest architectural variant inside its reserved parcel. All levels
	# share that world scale, so roofs never grow across a street when upgraded.
	var maximum := Vector2i.ONE
	for variant in range(5):
		var used := _sprites[group * 25 + variant * 5 + column].get_used_rect().size
		maximum.x = maxi(maximum.x, used.x)
		maximum.y = maxi(maximum.y, used.y)
	var ratio := minf(float(extent.x) / maximum.x, float(extent.y) / maximum.y)
	var key := "%s|%d|%d|%d" % [id, level, extent.x, extent.y]
	if not _scaled.has(key):
		var source := _sprites[group * 25 + (level - 1) * 5 + column].duplicate() as Image
		source.resize(maxi(1, roundi(source.get_width() * ratio)), maxi(1, roundi(source.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
		_scaled[key] = source
	var sprite: Image = _scaled[key]
	var position := Vector2i(roundi((p.x + bounds.x / 2.0) * SCALE - sprite.get_width() / 2.0), roundi((p.y + bounds.y) * SCALE - 310.0 * ratio))
	_pixels.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), position)
	_hit_rects[id] = Rect2(Vector2(position), Vector2(sprite.get_size()))
	_hit_images[id] = sprite


func _details() -> void:
	for x in [203, 253, 303]:
		_car(x, 302)
		_person(x - 9, 300, _accent)
		_person(x + 8, 306, _accent)
		for y in [297, 302, 307]:
			_disc(x + 16, y, 2, 1.6, INK)
		_frame(x + 14, 310, 5, 4, Color("#53646c"))
	_truck(544, 117)
	_truck(453, 321)
	for p in [Vector2(143, 133), Vector2(329, 222), Vector2(406, 328), Vector2(583, 230), Vector2(158, 354), Vector2(364, 125)]:
		_person(p.x, p.y, WALL)
	for x in [377, 391, 405, 419]:
		_frame(x, 310, 6, 12, Color("#425867"))
		_box(x + 0.6, 312, 4.8, 3, GLASS)
	for p in [Vector2(146, 126), Vector2(342, 218), Vector2(465, 328), Vector2(597, 124)]:
		_box(p.x, p.y, 0.7, 8, INK)
		_box(p.x - 1, p.y, 3, 1.3, WALL)
	# Perimeter entry and team flags are separate from facility level art.
	_frame(317, 369, 14, 13, WALL)
	_box(319, 371, 9, 4, GLASS)
	for x in [305, 370, 377]:
		_box(x, 367, 0.7, 20, INK)
		_box(x + 1, 367, 5, 10, _accent if x != 377 else WALL)


func _person(x: float, y: float, color: Color) -> void:
	_disc(x + 1, y + 5, 2, 1, SHADOW)
	_box(x, y, 1.6, 1.5, WALL)
	_box(x - 0.5, y + 1.5, 2.6, 2.8, color)
	_box(x, y + 4, 0.6, 1.7, INK)
	_box(x + 1.3, y + 4, 0.6, 1.7, INK)


func _car(x: float, y: float) -> void:
	_disc(x + 1, y + 2, 5, 9, Color("#536364"))
	for offset in [-5, 4]:
		_frame(x + offset, y - 5, 2.7, 4, INK)
		_frame(x + offset, y + 3, 2.7, 4, INK)
	_box(x - 2, y - 7, 5, 15, _accent)
	_box(x - 1.5, y - 5, 1, 9, _accent.lightened(0.3))
	_box(x + 2, y - 4, 1, 10, _accent.darkened(0.3))
	_box(x - 5, y - 6, 11, 1.7, _accent)
	_box(x - 5, y - 6, 11, 0.5, WALL)
	_box(x - 4, y + 7, 9, 1.7, INK)
	_box(x - 0.7, y - 2, 2.4, 4, INK)
	_box(x - 0.3, y - 6, 1, 3, WALL)


func _truck(x: float, y: float) -> void:
	_box(x + 1, y + 2, 36, 12, SHADOW)
	_frame(x, y, 27, 11, WALL)
	_box(x + 1, y + 1, 25, 0.5, WALL.lightened(0.2))
	_box(x + 1, y + 9.5, 25, 0.6, Color("#a3acaa"))
	_box(x + 1, y + 6, 25, 3, _accent)
	_frame(x + 28, y + 1, 9, 10, _accent)
	_box(x + 33, y + 2, 3, 6, GLASS)
	for wx in [x + 4, x + 20, x + 30]:
		_box(wx, y + 10, 3, 2, INK)


func select_facility(id: StringName) -> void:
	selected = id
	queue_redraw()


func preview(id: StringName, at_level: int) -> Texture2D:
	_load_sprites()
	for index in range(SITES.size()):
		if SITES[index][0] == id:
			var image := _sprites[(index / 5) * 25 + (clampi(at_level, 1, 5) - 1) * 5 + index % 5]
			return ImageTexture.create_from_image(image.get_region(image.get_used_rect()))
	return null


func _image_rect() -> Rect2:
	var factor := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	var extent := Vector2(CANVAS) * factor
	return Rect2((size - extent) / 2, extent)


func _site_at(local: Vector2) -> StringName:
	var display := _image_rect()
	if not display.has_point(local):
		return &""
	var point := (local - display.position) * (Vector2(CANVAS) / display.size)
	for id in _projects:
		if _work_rect(id).has_point(point):
			return id
	for index in range(SITES.size() - 1, -1, -1):
		var id: StringName = SITES[index][0]
		if _hit_rects.has(id):
			var rect: Rect2 = _hit_rects[id]
			if rect.has_point(point):
				var pixel := Vector2i(point - rect.position)
				if _hit_images[id].get_pixelv(pixel).a > 0.2:
					return id
	for site in SITES:
		if int(levels.get(site[0], 0)) == 0:
			if Rect2(Vector2(site[1]) * SCALE, Vector2(site[2]) * SCALE).has_point(point):
				return site[0]
	return &""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := _site_at(event.position)
		if hovered != _hovered:
			_hovered = hovered
			queue_redraw()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _hovered != &"" else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var id := _site_at(event.position)
		if id != &"":
			select_facility(id)
			facility_selected.emit(id)
			accept_event()


## Visible area of a site on screen: building pixels, worksite or plot.
func _shown_rect(id: StringName, display: Rect2) -> Rect2:
	var factor := display.size.x / CANVAS.x
	var rect := Rect2()
	for site in SITES:
		if site[0] == id:
			rect = Rect2(Vector2(site[1]) * SCALE, Vector2(site[2]) * SCALE)
	if _hit_rects.has(id):
		var used: Rect2i = _hit_images[id].get_used_rect()
		rect = Rect2(_hit_rects[id].position + Vector2(used.position), Vector2(used.size))
	if _projects.has(id):
		rect = _work_rect(id)
	return Rect2(display.position + rect.position * factor, rect.size * factor)


func _process(_delta: float) -> void:
	if animate and is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	var display := _image_rect()
	if animate:
		_draw_life(display, Time.get_ticks_msec() / 1000.0)
	for site in SITES:
		var id: StringName = site[0]
		var shown := _shown_rect(id, display)
		if _projects.has(id):
			_construction_badge(shown, _projects[id])
		elif int(levels.get(id, 0)) == 0:
			_plot_marker(shown.get_center(), id)
		if id == selected or id == _hovered or _projects.has(id):
			var color := UIStyle.ACCENT if id == selected or _projects.has(id) else UIStyle.TEXT
			draw_rect(shown.grow(3), color, false, 2)
	# Labels on top of everything.
	for site in SITES:
		var id: StringName = site[0]
		var built := int(levels.get(id, 0)) > 0
		if id == _hovered or (show_names and built):
			var shown := _shown_rect(id, display)
			_chip(Vector2(shown.get_center().x, shown.position.y - 4), _label(id), id == _hovered)


func _label(id: StringName) -> String:
	var lv := int(levels.get(id, 0))
	if lv > 0:
		return "%s · %s" % [tr(Facilities.name_of(id)), tr("Lv %d") % lv]
	if Facilities.locked_until(id) != "":
		return tr("Building site: %s · comes with %s") % [tr(Facilities.name_of(id)), Facilities.locked_until(id)]
	var cost := 0
	if _team:
		cost = int(Facilities.quote(_team, id).cost)
	return tr("Building site: %s · %s") % [tr(Facilities.name_of(id)), UIStyle.money(cost)]


## A small name tag centred above a point.
func _chip(bottom_center: Vector2, text: String, strong: bool) -> void:
	var font := UIStyle.font(&"body_semibold")
	var font_size := 13 if strong else 11
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 14
	var height := font_size + 9.0
	var rect := Rect2(Vector2(bottom_center.x - width / 2, bottom_center.y - height), Vector2(width, height))
	rect.position.x = clampf(rect.position.x, 2, size.x - width - 2)
	rect.position.y = maxf(rect.position.y, 2)
	draw_rect(rect, Color(UIStyle.BG, 0.9))
	draw_rect(rect, UIStyle.ACCENT if strong else UIStyle.LINE_STRONG, false, 1)
	draw_string(font, rect.position + Vector2(7, font_size + 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		UIStyle.TEXT if strong else UIStyle.MUTED)


func _plot_marker(center: Vector2, id: StringName) -> void:
	var locked := Facilities.locked_until(id) != ""
	draw_circle(center, 12, Color(UIStyle.BG, 0.85))
	draw_arc(center, 12, 0, TAU, 32, UIStyle.FAINT if locked else UIStyle.ACCENT, 1.5)
	var mark := UIStyle.FAINT if locked else UIStyle.TEXT
	draw_line(center - Vector2(5, 0), center + Vector2(5, 0), mark, 2)
	if not locked:
		draw_line(center - Vector2(0, 5), center + Vector2(0, 5), mark, 2)


func _construction_badge(shown: Rect2, project: Dictionary) -> void:
	var progress: float = clampf(1.0 - float(project.remaining) / project.duration, 0.0, 1.0)
	var width := clampf(shown.size.x - 8, 132, 210)
	var badge := Rect2(Vector2(shown.get_center().x - width / 2, shown.end.y - 36), Vector2(width, 32))
	draw_rect(badge, Color(UIStyle.BG, 0.92))
	draw_rect(badge, UIStyle.ACCENT.darkened(0.35), false, 1)
	var font := UIStyle.font(&"body_semibold")
	var label := tr("Under construction")
	if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > width - 47:
		label = tr("Construction")
	draw_string(font, badge.position + Vector2(8, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIStyle.ACCENT)
	draw_string(font, badge.position + Vector2(width - 37, 15), "%d%%" % roundi(progress * 100), HORIZONTAL_ALIGNMENT_RIGHT, 29, 12, UIStyle.TEXT)
	var bar := Rect2(badge.position + Vector2(8, 22), Vector2(width - 16, 4))
	draw_rect(bar, UIStyle.LINE_STRONG)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), UIStyle.ACCENT)


# --- Campus life (drawn every frame, never part of the picking) ----------------

const WALK_PATHS := [
	[Vector2(40, 128), Vector2(600, 128)],
	[Vector2(40, 239), Vector2(600, 239)],
	[Vector2(161, 132), Vector2(161, 318)],
	[Vector2(350, 132), Vector2(350, 386)],
	[Vector2(160, 336), Vector2(600, 336)],
]


func _draw_life(display: Rect2, t: float) -> void:
	var factor := display.size.x / CANVAS.x * SCALE
	var to_screen := func(world: Vector2) -> Vector2: return display.position + world * factor
	# Pit-crew drill around the middle car while the pit building exists.
	if int(levels.get(&"pit", 0)) > 0 and not _projects.has(&"pit"):
		var car := Vector2(253, 302)
		var cycle := fmod(t, 6.0) / 6.0
		var run := clampf(sin(cycle * TAU) * 1.6, 0.0, 1.0)
		var wheels := [Vector2(-6, -4), Vector2(6, -4), Vector2(-6, 5), Vector2(6, 5)]
		for i in wheels.size():
			var waiting := car + Vector2(16 + (i % 2) * 4, -8 + i * 4)
			var spot: Vector2 = car + wheels[i] * 1.4
			_draw_person(to_screen.call(waiting.lerp(spot, run)), factor, _accent)
	# People walking the paths, back and forth.
	for i in WALK_PATHS.size():
		var path: Array = WALK_PATHS[i]
		var length: float = path[0].distance_to(path[1])
		for k in 2:
			var travelled := fmod(t * 9.0 + i * 70.0 + k * length * 0.5, length * 2.0)
			var along := travelled if travelled < length else length * 2.0 - travelled
			var point: Vector2 = path[0].move_toward(path[1], along)
			_draw_person(to_screen.call(point), factor, WALL if (i + k) % 3 else _accent)
	# A transporter on the main road every 30 s.
	var trip := fmod(t, 30.0)
	if trip < 14.0:
		var x := lerpf(20.0, 620.0, trip / 14.0)
		var origin: Vector2 = to_screen.call(Vector2(x, 228))
		var body := Rect2(origin, Vector2(26, 8) * factor)
		draw_rect(body, WALL)
		draw_rect(Rect2(body.position + Vector2(0, body.size.y * 0.55), Vector2(body.size.x, body.size.y * 0.25)), _accent)
		draw_rect(Rect2(body.end.x, body.position.y + 1, 8 * factor, body.size.y - 1), _accent.darkened(0.2))
		draw_rect(body, INK, false, 1)


func _draw_person(at: Vector2, factor: float, color: Color) -> void:
	var r := maxf(1.2, 1.1 * factor)
	draw_circle(at + Vector2(0, r * 2.2), r * 1.2, Color(SHADOW, 0.6))
	draw_rect(Rect2(at - Vector2(r, 0), Vector2(r * 2, r * 2.4)), color)
	draw_circle(at - Vector2(0, r * 0.6), r * 0.8, WALL)
