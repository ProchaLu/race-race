## Procedural "flat" portraits for every person in the game (design doc 1.2).
## A face is built as an SVG string from features picked with a random
## generator seeded by the person's ID, so the same person always looks the
## same. Age changes hair colour, hairline, wrinkles and glasses.
class_name PortraitGenerator
extends RefCounted

## SVG canvas size; textures keep this 5:6 aspect ratio.
const VIEW_W := 100.0
const VIEW_H := 120.0
const CX := 50.0

## Possible heritages per nationality with weights.
const HERITAGE := {
	"SE": [["nordic", 1.0]], "NO": [["nordic", 1.0]], "FI": [["nordic", 1.0]], "DK": [["nordic", 1.0]],
	"GB": [["west", 0.78], ["african", 0.14], ["south_asian", 0.08]], "DE": [["west", 0.9], ["med", 0.1]],
	"NL": [["west", 0.9], ["african", 0.1]], "BE": [["west", 0.85], ["african", 0.15]],
	"CH": [["west", 1.0]], "AT": [["west", 1.0]], "FR": [["west", 0.7], ["med", 0.15], ["african", 0.15]],
	"US": [["west", 0.6], ["african", 0.2], ["latam", 0.12], ["east_asian", 0.08]],
	"CA": [["west", 0.8], ["east_asian", 0.1], ["south_asian", 0.1]], "AU": [["west", 0.9], ["east_asian", 0.1]],
	"NZ": [["west", 1.0]], "IT": [["med", 1.0]], "ES": [["med", 1.0]], "MC": [["med", 1.0]],
	"BR": [["latam", 0.7], ["african", 0.3]], "AR": [["latam", 1.0]], "MX": [["latam", 1.0]],
	"JP": [["east_asian", 1.0]], "CN": [["east_asian", 1.0]], "IN": [["south_asian", 1.0]],
}
const SKIN := {
	"nordic": ["f6d7c6", "f0cab4", "f3d0bb", "eec3ab"],
	"west": ["f1c9ae", "e8b896", "f4d2b8", "dfa888", "eab99c"],
	"med": ["e3b08c", "d9a47e", "e8bb98", "cf9a74"],
	"latam": ["c98d63", "d39b72", "b9794f", "e0ae88"],
	"african": ["8d5a3b", "6f432a", "a06a45", "5a3622", "7d4e32"],
	"south_asian": ["b07a52", "a06b45", "c08a60", "966040"],
	"east_asian": ["f0c9a4", "e8bd96", "f3d1af", "deb18a"],
}
const HAIR := {
	"nordic": ["d8b26a", "c9a15e", "b48a55", "7a5535", "a8532c", "e2c58a"],
	"west": ["5a3d28", "2e2119", "c9a15e", "8a6440", "9c4a26", "3d2a1d"],
	"med": ["2a1d16", "1b1512", "4a3324", "3a281c"],
	"latam": ["1b1512", "2e2119", "4a3324"],
	"african": ["161110", "1f1714", "2a1d16"],
	"south_asian": ["141110", "231a15", "2e2119"],
	"east_asian": ["141214", "231b17", "2e2420"],
}
const EYES := {
	"nordic": ["4a78a8", "5b8a6a", "6a8fb0", "7a8a9a"], "west": ["4a78a8", "6b4a2f", "5b8a6a", "7a5a3a"],
	"med": ["5a3a22", "6b4a2f", "4a6a4a"], "latam": ["4a2f1f", "5a3a22"], "african": ["3a2418", "2e1d14"],
	"south_asian": ["3a2418", "4a2f1f"], "east_asian": ["2e1d14", "3a2418"],
}
const FRECKLE_CHANCE := {"nordic": 0.35, "west": 0.2, "med": 0.05}
const MALE_STYLES := ["short", "short", "side", "side", "buzz", "quiff", "slick", "spiky",
	"undercut", "bun", "shaved"]
## Share of men with shoulder-length hair (rare in the paddock).
const MALE_LONG_HAIR_CHANCE := 0.05
const FEMALE_STYLES := ["long", "long", "bob", "bun", "ponytail", "pixie", "curly_long", "braid"]
const BEARDS := ["none", "none", "none", "none", "stubble", "stubble", "full", "moustache",
	"goatee", "chinstrap", "short_beard"]

static var _cache := {}


## Portrait texture of a person, cached per person, age, team colour and size.
static func texture(person: PersonData, team_color: Color, width_px: int = 100) -> Texture2D:
	var age := person.age(Calendar.year)
	var key := "%s|%d|%s|%d" % [person.id, age, team_color.to_html(), width_px]
	if _cache.has(key):
		return _cache[key]
	var female := person.gender == PersonData.Gender.FEMALE
	var svg := build_svg(str(person.id), person.nationality, female, age, team_color)
	var image := Image.new()
	image.load_svg_from_string(svg, width_px / VIEW_W)
	var tex := ImageTexture.create_from_image(image)
	_cache[key] = tex
	return tex


static func build_svg(seed_id: String, nationality: String, female: bool, age: int, team: Color) -> String:
	var p := _features(seed_id, nationality, female, age)
	var out := PackedStringArray()
	out.append('<svg xmlns="http://www.w3.org/2000/svg" width="100" height="120" viewBox="0 0 100 120">')
	_background(out, team)
	_hair_back(out, p)
	_suit(out, team)
	_neck_and_ears(out, p)
	_head(out, p)
	_skin_details(out, p)
	_facial_hair(out, p)
	_eyes_and_brows(out, p)
	_nose_and_mouth(out, p)
	_hair_front(out, p)
	_accessories(out, p)
	out.append("</svg>")
	return "".join(out)


# --- Features ----------------------------------------------------------------

static func _features(seed_id: String, nationality: String, female: bool, age: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash(seed_id + ":face")
	var heritage := _heritage(r, nationality)
	var p := {"female": female, "age": age, "heritage": heritage}

	p.skin = Color(_pick(r, SKIN[heritage]))
	p.hair_base = Color(_pick(r, HAIR[heritage]))
	p.eye = Color(_pick(r, EYES[heritage]))
	# A few people dye their hair.
	if age < 35 and r.randf() < 0.04:
		p.hair_base = Color(_pick(r, ["e8e2d0", "b23a2a", "2f4f7f"]))

	p.shape = _pick(r, ["oval", "oval", "round", "square", "long"])
	var w := 20.0 + r.randf() * 2.5
	if p.shape == "round":
		w += 1.5
	if female:
		w -= 1.6
	p.w = w
	p.jaw_inset = {"oval": 5.0, "round": 3.2, "square": 2.2, "long": 5.5}[p.shape] + r.randf() * 1.2
	p.top = 26.0 if p.shape == "long" else 27.5
	p.chin = 86.0 if p.shape == "long" else (82.5 if p.shape == "round" else 84.0)

	p.eye_shape = _pick(r, ["round", "almond", "almond", "narrow"])
	if heritage == "east_asian" and r.randf() < 0.6:
		p.eye_shape = "narrow"
	p.eye_gap = 7.4 + r.randf() * 1.8
	p.eye_size = 0.85 + r.randf() * 0.35
	p.brow_shape = _pick(r, ["straight", "arched", "angled", "soft"])
	p.brow = (1.3 if female else 1.8) + r.randf() * 1.4
	p.nose = _pick(r, ["small", "straight", "straight", "wide", "long", "hooked"])
	p.mouth_w = 7.0 + r.randf() * 4.5
	p.smile = r.randf() * 1.5 - 0.35
	p.full_lips = r.randf() < (0.6 if female else 0.25)
	p.ear = 5.4 + r.randf() * 1.8
	p.earring = r.randf() < (0.55 if female else 0.08)
	p.freckles = r.randf() < FRECKLE_CHANCE.get(heritage, 0.02)
	p.mole = Vector2(r.randf_range(-14, 14), r.randf_range(60, 76)) if r.randf() < 0.18 else Vector2.ZERO
	p.scar = r.randf() < 0.07
	p.dimples = r.randf() < 0.12
	p.wrinkle_offset = r.randf() * 8.0
	p.glasses_roll = r.randf()
	p.glasses_round = r.randf() < 0.4
	p.glasses_gold = r.randf() < 0.3

	var curly_chance: float = {"african": 0.75, "latam": 0.3}.get(heritage, 0.08)
	if female:
		p.hair_style = _pick(r, FEMALE_STYLES)
		if r.randf() < curly_chance * 0.6:
			p.hair_style = "curly_long"
	else:
		p.hair_style = _pick(r, MALE_STYLES)
		if r.randf() < MALE_LONG_HAIR_CHANCE:
			p.hair_style = "long"
		if r.randf() < curly_chance:
			p.hair_style = "afro" if heritage == "african" and r.randf() < 0.4 else "curly"
	p.beard = "none" if female else _pick(r, BEARDS)
	p.sideburns = not female and r.randf() < 0.25

	# Age effects (fixed thresholds per person, so ageing is consistent)
	var grey_start := 32.0 + r.randf() * 18.0
	var recede_start := 28.0 + r.randf() * 24.0 if (not female and r.randf() < 0.5) else 999.0
	var grey := clampf((age - grey_start) / 22.0, 0.0, 0.92)
	p.hair = (p.hair_base as Color).lerp(Color("c9c4c0") if female else Color("bdbdbd"), grey)
	p.brow_color = (p.hair_base as Color).darkened(0.2).lerp(Color("9a9a9a"), clampf((age - grey_start - 8.0) / 25.0, 0.0, 0.8))
	p.recede = clampf((age - recede_start) / 26.0, 0.0, 1.0)
	if age < 18:
		p.beard = "none"
		p.sideburns = false
	p.glasses = p.glasses_roll < (0.45 if age > 45 else 0.1)
	return p


static func _heritage(r: RandomNumberGenerator, nationality: String) -> String:
	var options: Array = HERITAGE.get(nationality, [["west", 1.0]])
	var x := r.randf()
	var acc := 0.0
	for option in options:
		acc += option[1]
		if x <= acc:
			return option[0]
	return options[0][0]


static func _pick(r: RandomNumberGenerator, list: Array) -> Variant:
	return list[r.randi() % list.size()]


# --- Drawing -----------------------------------------------------------------

static func _background(out: PackedStringArray, team: Color) -> void:
	out.append('<rect width="100" height="120" fill="%s"/>' % _hex(UIStyle.PANEL.lerp(team, 0.16)))
	out.append('<circle cx="50" cy="58" r="44" fill="%s"/>' % _hex(UIStyle.PANEL.lerp(team, 0.28)))


static func _suit(out: PackedStringArray, team: Color) -> void:
	out.append('<path d="M6,120 C8,104 22,95 38,93 L62,93 C78,95 92,104 94,120Z" fill="%s"/>' % _hex(team))
	out.append('<path d="M38,93 L62,93 L66,99 C60,102 40,102 34,99Z" fill="%s"/>' % _hex(team.darkened(0.35)))
	out.append('<path d="M20,112 L80,112" stroke="%s" stroke-width="2" opacity="0.55"/>' % _hex(team.lightened(0.35)))


static func _neck_and_ears(out: PackedStringArray, p: Dictionary) -> void:
	var nw := 6.0 if p.female else 7.5
	out.append(_fmt('<path d="M%s,70 L%s,95 L%s,95 L%s,70Z" fill="%s"/>',
		[CX - nw, CX - nw, CX + nw, CX + nw, _hex((p.skin as Color).darkened(0.18))]))
	for s: float in [-1.0, 1.0]:
		out.append(_fmt('<ellipse cx="%s" cy="58" rx="3.6" ry="%s" fill="%s"/>',
			[CX + s * (p.w - 0.5), p.ear, _hex((p.skin as Color).darkened(0.06))]))


static func _head_path(p: Dictionary) -> String:
	var w: float = p.w
	var jw: float = w - p.jaw_inset
	var t: float = p.top
	var c: float = p.chin
	return _fmt("M%s,%s C%s,%s %s,%s %s,55 C%s,66 %s,73 %s,77 C%s,%s %s,%s %s,%s " +
		"C%s,%s %s,%s %s,77 C%s,73 %s,66 %s,55 C%s,%s %s,%s %s,%sZ", [
		CX, t, CX + w * 0.82, t, CX + w, t + 12, CX + w,
		CX + w, CX + jw + 2, CX + jw,
		CX + jw - 3, c - 3, CX + 3, c, CX, c,
		CX - 3, c, CX - jw + 3, c - 3, CX - jw,
		CX - jw - 2, CX - w, CX - w,
		CX - w, t + 12, CX - w * 0.82, t, CX, t])


static func _head(out: PackedStringArray, p: Dictionary) -> void:
	out.append('<path d="%s" fill="%s"/>' % [_head_path(p), _hex(p.skin)])


static func _skin_details(out: PackedStringArray, p: Dictionary) -> void:
	var line := _hex((p.skin as Color).darkened(0.3))
	var age: int = p.age
	if age > 38 + p.wrinkle_offset:
		out.append(_fmt('<path d="M%s,55 l-3,-1.5 M%s,57.5 l-3,0.5 M%s,55 l3,-1.5 M%s,57.5 l3,0.5" stroke="%s" stroke-width="0.8" opacity="0.6" fill="none"/>',
			[CX - 18, CX - 18, CX + 18, CX + 18, line]))
	if age > 48 + p.wrinkle_offset * 0.7:
		out.append(_fmt('<path d="M%s,39 q9,-2 18,0 M%s,42.5 q7,-1.5 14,0 M%s,64 q-2,5 -1,9 M%s,64 q2,5 1,9" stroke="%s" stroke-width="0.8" opacity="0.55" fill="none"/>',
			[CX - 9, CX - 7, CX - 8, CX + 8, line]))
	if p.freckles:
		var r := RandomNumberGenerator.new()
		r.seed = hash(str(p.skin) + "freckles")
		for i in 12:
			var side := -1.0 if i % 2 == 0 else 1.0
			out.append(_fmt('<circle cx="%s" cy="%s" r="0.55" fill="%s" opacity="0.55"/>',
				[CX + side * r.randf_range(4, 13), r.randf_range(59, 66), _hex((p.skin as Color).darkened(0.32))]))
	if p.mole != Vector2.ZERO:
		out.append(_fmt('<circle cx="%s" cy="%s" r="0.9" fill="%s"/>',
			[CX + p.mole.x, p.mole.y, _hex((p.skin as Color).darkened(0.5))]))
	if p.scar:
		out.append(_fmt('<path d="M%s,47 L%s,53" stroke="%s" stroke-width="0.9" opacity="0.7"/>',
			[CX + 10, CX + 12.5, _hex((p.skin as Color).lightened(0.35))]))
	if p.dimples:
		for s: float in [-1.0, 1.0]:
			out.append(_fmt('<path d="M%s,72 q%s,1.5 0,3" stroke="%s" stroke-width="0.7" fill="none" opacity="0.6"/>',
				[CX + s * (p.mouth_w / 2 + 2.5), s * 0.8, line]))


static func _facial_hair(out: PackedStringArray, p: Dictionary) -> void:
	var w: float = p.w
	var jw: float = w - p.jaw_inset
	var c: float = p.chin
	var hair := _hex(p.hair)
	var beard := _fmt("M%s,57 C%s,70 %s,76 %s,78 C%s,%s %s,%s %s,%s C%s,%s %s,%s %s,78 C%s,76 %s,70 %s,57 " +
		"C%s,67 %s,70 %s,70 C%s,70 %s,67 %s,57Z", [
		CX - w, CX - w, CX - jw - 1, CX - jw, CX - jw + 3, c, CX - 3, c + 3, CX, c + 3,
		CX + 3, c + 3, CX + jw - 3, c, CX + jw, CX + jw + 1, CX + w, CX + w,
		CX + w - 3, CX + 6, CX, CX - 6, CX - w + 3, CX - w])
	var moustache := _fmt('<path d="M%s,70.5 C%s,67.5 %s,67.5 %s,70.5 C%s,69.5 %s,69.5 %s,70.5Z" fill="%s"/>',
		[CX - 7, CX - 4, CX + 4, CX + 7, CX + 3, CX - 3, CX - 7, hair])
	match p.beard:
		"stubble":
			out.append('<path d="%s" fill="%s" opacity="0.28"/>' % [beard, hair])
		"full":
			out.append('<path d="%s" fill="%s"/>' % [beard, hair])
			out.append(moustache)
		"short_beard":
			out.append('<path d="%s" fill="%s" opacity="0.65"/>' % [beard, hair])
			out.append(moustache)
		"moustache":
			out.append(moustache)
		"goatee":
			out.append(_fmt('<path d="M%s,75 C%s,%s %s,%s %s,75 C%s,77.5 %s,77.5 %s,75Z" fill="%s"/>',
				[CX - 5, CX - 5, c + 2, CX + 5, c + 2, CX + 5, CX + 3, CX - 3, CX - 5, hair]))
			out.append(moustache)
		"chinstrap":
			out.append(_fmt('<path d="M%s,60 C%s,70 %s,76 %s,78 C%s,%s %s,%s %s,78 C%s,76 %s,70 %s,60" stroke="%s" stroke-width="2.4" fill="none"/>',
				[CX - w + 0.5, CX - w + 0.5, CX - jw, CX - jw + 1, CX - 3, c + 1.5, CX + 3, c + 1.5, CX + jw - 1, CX + jw, CX + w - 0.5, CX + w - 0.5, hair]))
	if p.sideburns:
		for s: float in [-1.0, 1.0]:
			out.append(_fmt('<path d="M%s,50 L%s,62 L%s,62 L%s,50Z" fill="%s"/>',
				[CX + s * (w + 0.2), CX + s * (w - 0.3), CX + s * (w - 2.8), CX + s * (w - 2.6), hair]))


static func _eyes_and_brows(out: PackedStringArray, p: Dictionary) -> void:
	var eye_size: float = p.eye_size
	var ry: float = {"round": 2.5, "almond": 2.0, "narrow": 1.4}[p.eye_shape] * eye_size
	var rx := 2.2 * eye_size
	var eye := _hex((p.eye as Color).darkened(0.55))
	for s: float in [-1.0, 1.0]:
		var ex: float = CX + s * p.eye_gap
		out.append(_fmt('<ellipse cx="%s" cy="56" rx="%s" ry="%s" fill="%s"/>', [ex, rx, ry, eye]))
		out.append(_fmt('<circle cx="%s" cy="%s" r="0.5" fill="#ffffff" opacity="0.6"/>', [ex + 0.6, 55.3]))
		# Brow: inner end at the nose side.
		var inner := ex - s * 4.4
		var outer := ex + s * 4.4
		var d := ""
		match p.brow_shape:
			"straight":
				d = _fmt("M%s,50 L%s,50.2", [inner, outer])
			"arched":
				d = _fmt("M%s,50.4 Q%s,47.2 %s,50.6", [inner, ex, outer])
			"angled":
				d = _fmt("M%s,51 L%s,48.6 L%s,50.4", [inner, ex + s * 1.5, outer])
			_:
				d = _fmt("M%s,50 Q%s,48.6 %s,50.6", [inner, ex, outer])
		out.append('<path d="%s" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" fill="none"/>' % [
			d, _hex(p.brow_color), _n(p.brow)])


static func _nose_and_mouth(out: PackedStringArray, p: Dictionary) -> void:
	var col := _hex((p.skin as Color).darkened(0.28))
	var d: String
	match p.nose:
		"small":
			d = _fmt("M%s,59 L%s,65 Q%s,66.3 %s,65.2", [CX + 0.5, CX - 1.2, CX, CX + 1.6])
		"wide":
			d = _fmt("M%s,57 L%s,65 M%s,65.4 Q%s,67.6 %s,65.4", [CX + 0.6, CX - 1.4, CX - 3.4, CX, CX + 3.4])
		"long":
			d = _fmt("M%s,55 L%s,67 Q%s,68.6 %s,67", [CX + 0.6, CX - 1.8, CX, CX + 2.2])
		"hooked":
			d = _fmt("M%s,56 Q%s,61 %s,66 Q%s,67.4 %s,66", [CX + 0.4, CX - 2.6, CX - 1.4, CX, CX + 2.0])
		_:
			d = _fmt("M%s,57 L%s,65.5 Q%s,67.2 %s,65.6", [CX + 0.6, CX - 1.6, CX, CX + 2])
	out.append('<path d="%s" stroke="%s" stroke-width="1.1" stroke-linecap="round" fill="none"/>' % [d, col])

	var mw: float = p.mouth_w
	var my := 74.0 if p.shape == "long" else 73.0
	var curve: float = p.smile * 2.4
	if p.full_lips:
		out.append(_fmt('<path d="M%s,%s Q%s,%s %s,%s Q%s,%s %s,%sZ" fill="%s"/>',
			[CX - mw / 2, my, CX, my + 2.2 + curve, CX + mw / 2, my, CX, my - 1.4, CX - mw / 2, my,
			_hex((p.skin as Color).lerp(Color("9b4a42"), 0.35))]))
	out.append(_fmt('<path d="M%s,%s Q%s,%s %s,%s" stroke="%s" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
		[CX - mw / 2, my, CX, my + curve, CX + mw / 2, my, _hex((p.skin as Color).darkened(0.45))]))


static func _hair_back(out: PackedStringArray, p: Dictionary) -> void:
	var w: float = p.w
	var hair := _hex(p.hair)
	var d := ""
	match p.hair_style:
		"long", "braid":
			d = _fmt("M%s,50 C%s,24 %s,24 %s,50 L%s,98 C%s,104 %s,104 %s,98Z",
				[CX - w - 4, CX - w - 7, CX + w + 7, CX + w + 4, CX + w + 6, CX + 8, CX - 8, CX - w - 6])
		"bob":
			d = _fmt("M%s,50 C%s,24 %s,24 %s,50 L%s,78 C%s,82 %s,82 %s,78Z",
				[CX - w - 4, CX - w - 7, CX + w + 7, CX + w + 4, CX + w + 5, CX + 8, CX - 8, CX - w - 5])
		"curly_long":
			var blobs := PackedStringArray()
			for i in 12:
				var a := PI * (1.0 + i / 11.0)
				blobs.append(_fmt('<circle cx="%s" cy="%s" r="7"/>', [CX + cos(a) * (w + 5), 50 + sin(a) * (w + 6)]))
			for y in [58.0, 68.0, 78.0, 88.0]:
				for s in [-1.0, 1.0]:
					blobs.append(_fmt('<circle cx="%s" cy="%s" r="6.5"/>', [CX + s * (w + 4), y]))
			out.append('<g fill="%s">%s</g>' % [hair, "".join(blobs)])
		"ponytail":
			d = _fmt("M%s,40 C%s,44 %s,76 %s,90 C%s,74 %s,56 %s,48Z",
				[CX + w - 2, CX + w + 12, CX + w + 10, CX + w + 2, CX + w - 2, CX + w + 2, CX + w - 6])
	if p.hair_style == "long" and not p.female:
		d = _fmt("M%s,50 C%s,26 %s,26 %s,50 L%s,84 C%s,88 %s,88 %s,84Z",
			[CX - w - 3, CX - w - 6, CX + w + 6, CX + w + 3, CX + w + 4, CX + 8, CX - 8, CX - w - 4])
	if d != "":
		out.append('<path d="%s" fill="%s"/>' % [d, hair])
	if p.hair_style == "afro":
		out.append(_fmt('<ellipse cx="%s" cy="40" rx="%s" ry="23" fill="%s"/>', [CX, w + 8, hair]))


static func _hair_front(out: PackedStringArray, p: Dictionary) -> void:
	var w: float = p.w
	var hair := _hex(p.hair)
	var recede: float = p.recede
	var hl := 37.0 - recede * 9.0
	var top := 22.0 + recede * 3.0
	var opacity := 0.55 if recede > 0.75 else 1.0
	var cap := _fmt("M%s,54 C%s,30 %s,%s %s,%s C%s,%s %s,30 %s,54 C%s,44 %s,%s %s,%s C%s,%s %s,44 %s,54Z", [
		CX - w - 1, CX - w - 2, CX - w * 0.5, top, CX, top, CX + w * 0.5, top, CX + w + 2, CX + w + 1,
		CX + w - 2, CX + w * 0.45, hl, CX, hl, CX - w * 0.45, hl, CX - w + 2, CX - w - 1])
	match p.hair_style:
		"short", "long":
			if p.female:
				out.append('<path d="%s" fill="%s"/>' % [_fringe(w, 40.0), hair])
			else:
				out.append('<path d="%s" fill="%s" opacity="%s"/>' % [cap, hair, _n(opacity)])
		"side":
			out.append('<path d="%s" fill="%s" opacity="%s"/>' % [_fmt(
				"M%s,54 C%s,29 %s,%s %s,%s C%s,%s %s,30 %s,54 C%s,43 %s,%s %s,%s C%s,%s %s,46 %s,54Z", [
				CX - w - 1, CX - w - 2, CX - w * 0.5, top, CX + 2, top, CX + w * 0.5, top, CX + w + 2, CX + w + 1,
				CX + w - 2, CX + 6, hl - 1, CX - 4, hl + 2, CX - w * 0.5, hl + 4, CX - w + 2, CX - w - 1]), hair, _n(opacity)])
		"buzz":
			out.append('<path d="%s" fill="%s" opacity="0.8"/>' % [cap, hair])
		"quiff":
			out.append('<path d="%s" fill="%s" opacity="%s"/>' % [cap, hair, _n(opacity)])
			out.append(_fmt('<path d="M%s,%s C%s,%s %s,%s %s,%sZ" fill="%s"/>',
				[CX - 8, top + 4, CX - 6, top - 8, CX + 12, top - 9, CX + 13, top + 2, hair]))
		"slick":
			out.append('<path d="%s" fill="%s" opacity="%s"/>' % [cap, hair, _n(opacity)])
			out.append(_fmt('<path d="M%s,%s Q%s,%s %s,%s M%s,%s Q%s,%s %s,%s" stroke="%s" stroke-width="0.8" fill="none" opacity="0.5"/>',
				[CX - 9, top + 6, CX, top + 2, CX + 11, top + 7, CX - 7, top + 10, CX + 2, top + 6, CX + 12, top + 11,
				_hex((p.hair as Color).lightened(0.3))]))
		"spiky":
			out.append('<path d="%s" fill="%s"/>' % [cap, hair])
			var spikes := PackedStringArray()
			for i in 6:
				var x := CX - w * 0.8 + i * w * 0.32
				spikes.append(_fmt("M%s,%s L%s,%s L%s,%s", [x - 3.5, top + 6, x, top - 5 + (i % 2) * 3, x + 3.5, top + 6]))
			out.append('<path d="%s" fill="%s"/>' % [" ".join(spikes), hair])
		"undercut":
			out.append('<path d="%s" fill="%s" opacity="0.35"/>' % [cap, hair])
			out.append(_fmt('<path d="M%s,40 C%s,%s %s,%s %s,40 C%s,36 %s,36 %s,40Z" fill="%s"/>',
				[CX - w * 0.7, CX - w * 0.7, top - 2, CX + w * 0.7, top - 2, CX + w * 0.7, CX + 4, CX - 4, CX - w * 0.7, hair]))
		"bun":
			out.append('<path d="%s" fill="%s"/>' % [cap, hair])
			if p.female:
				out.append(_fmt('<circle cx="%s" cy="%s" r="7" fill="%s"/>', [CX, top - 5, hair]))
			else:
				out.append(_fmt('<circle cx="%s" cy="%s" r="4.5" fill="%s"/>', [CX + 4, top - 2, hair]))
		"shaved":
			out.append('<path d="%s" fill="%s" opacity="0.22"/>' % [cap, hair])
		"curly":
			var blobs := PackedStringArray()
			for i in 11:
				var a := PI * (1.05 + i * 0.09)
				blobs.append(_fmt('<circle cx="%s" cy="%s" r="%s"/>',
					[CX + cos(a) * (w + 1), 45 + sin(a) * (w - 1 - recede * 4), 5.6 - recede * 2]))
			out.append('<g fill="%s">%s</g>' % [hair, "".join(blobs)])
		"afro":
			out.append('<path d="%s" fill="%s"/>' % [cap, hair])
		"bob", "ponytail", "braid":
			out.append('<path d="%s" fill="%s"/>' % [_fringe(w, 38.0), hair])
			if p.hair_style == "braid":
				for i in 5:
					out.append(_fmt('<path d="M%s,%s q3,3 6,0" stroke="%s" stroke-width="0.9" fill="none" opacity="0.6"/>',
						[CX + w + 1, 64 + i * 6, _hex((p.hair as Color).darkened(0.3))]))
		"pixie":
			out.append('<path d="%s" fill="%s"/>' % [_fmt(
				"M%s,52 C%s,28 %s,23 %s,23 C%s,23 %s,28 %s,50 C%s,40 %s,36 %s,38 C%s,42 %s,46 %s,52Z",
				[CX - w - 1, CX - w - 2, CX - w * 0.4, CX + 2, CX + w * 0.6, CX + w + 2, CX + w + 1,
				CX + w - 4, CX + 2, CX - 8, CX - w + 2, CX - w, CX - w - 1]), hair])
		"curly_long":
			var front := PackedStringArray()
			for i in 9:
				var a := PI * (1.1 + i * 0.1)
				front.append(_fmt('<circle cx="%s" cy="%s" r="5"/>', [CX + cos(a) * (w + 0.5), 44 + sin(a) * (w - 3)]))
			out.append('<g fill="%s">%s</g>' % [hair, "".join(front)])


## Women's fringe: swept to one side.
static func _fringe(w: float, depth: float) -> String:
	return _fmt("M%s,56 C%s,27 %s,27 %s,56 C%s,42 %s,34 %s,%s C%s,44 %s,49 %s,56Z",
		[CX - w - 1, CX - w - 2, CX + w + 2, CX + w + 1, CX + w - 3, CX + 4, CX - 8, depth, CX - w + 3, CX - w, CX - w - 1])


static func _accessories(out: PackedStringArray, p: Dictionary) -> void:
	if p.earring:
		for s: float in [-1.0, 1.0]:
			out.append(_fmt('<circle cx="%s" cy="%s" r="1.3" fill="#e8c35a"/>', [CX + s * (p.w - 0.5), 58 + p.ear - 0.5]))
	if p.glasses:
		var col := "#c9a24a" if p.glasses_gold else "#20262c"
		var gap: float = p.eye_gap
		if p.glasses_round:
			out.append(_fmt('<g fill="none" stroke="%s" stroke-width="1.1"><circle cx="%s" cy="56" r="4.6"/><circle cx="%s" cy="56" r="4.6"/><path d="M%s,55.4 Q%s,54 %s,55.4"/></g>',
				[col, CX - gap, CX + gap, CX - gap + 4.6, CX, CX + gap - 4.6]))
		else:
			out.append(_fmt('<g fill="none" stroke="%s" stroke-width="1.2"><rect x="%s" y="52" width="10.6" height="7.6" rx="2.2"/><rect x="%s" y="52" width="10.6" height="7.6" rx="2.2"/><path d="M%s,55 Q%s,53.6 %s,55"/></g>',
				[col, CX - gap - 5.3, CX + gap - 5.3, CX - gap + 5.3, CX, CX + gap - 5.3]))


# --- Helpers -----------------------------------------------------------------

## Fills a template's %s placeholders, writing floats with one decimal.
static func _fmt(template: String, values: Array) -> String:
	var parts := []
	for v in values:
		parts.append(_n(v) if (v is float or v is int) else str(v))
	return template % parts


static func _n(v: float) -> String:
	return "%.1f" % v


static func _hex(c: Color) -> String:
	return "#" + c.to_html(false)
