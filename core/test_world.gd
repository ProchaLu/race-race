## Builds a small fictional world for development and testing.
## Will be replaced by a proper world generator / database later.
class_name TestWorld
extends RefCounted

## Corner points of the test circuit (screen pixels). Smoothed into a curve.
const TEST_RING_POINTS := [
	Vector2(150, 460), Vector2(450, 460), Vector2(720, 460), Vector2(790, 430),
	Vector2(800, 360), Vector2(760, 300), Vector2(640, 280), Vector2(560, 250),
	Vector2(540, 190), Vector2(600, 130), Vector2(680, 70), Vector2(600, 40),
	Vector2(460, 50), Vector2(300, 60), Vector2(200, 80), Vector2(170, 140),
	Vector2(230, 190), Vector2(320, 220), Vector2(340, 290), Vector2(260, 330),
	Vector2(120, 340), Vector2(70, 390), Vector2(90, 450),
]


static func build() -> void:
	GameState.clear()
	Calendar.reset()

	var f1 := SeriesData.new()
	f1.id = &"f1"
	f1.name = "Formula Apex"
	f1.tier = 1
	f1.is_player_series = true
	GameState.series[f1.id] = f1

	_make_tyres()
	_make_test_track()

	_make_team(&"vortex", "Vortex Racing", "VRT", Color.ORANGE_RED, 62, f1)
	_make_team(&"nordline", "Nordline GP", "NRD", Color.DODGER_BLUE, 66, f1)
	_make_team(&"aurum", "Aurum Motorsport", "AUR", Color.GOLD, 72, f1)
	_make_team(&"kestrel", "Kestrel Racing", "KES", Color.LIME_GREEN, 58, f1)
	_make_team(&"solace", "Solace Racing", "SOL", Color.MEDIUM_PURPLE, 55, f1)
	_make_team(&"ironbridge", "Ironbridge Engineering", "IRB", Color.SILVER, 50, f1)

	_make_driver(&"d_hale", "Marco", "Hale", "IT", 1998, 78, &"vortex")
	_make_driver(&"d_brandt", "Jonas", "Brandt", "DE", 2002, 71, &"vortex")
	_make_driver(&"d_okafor", "Daniel", "Okafor", "GB", 2000, 75, &"nordline")
	_make_driver(&"d_lindqvist", "Erik", "Lindqvist", "SE", 2004, 66, &"nordline")
	_make_driver(&"d_duarte", "Rafael", "Duarte", "BR", 1996, 80, &"aurum")
	_make_driver(&"d_morita", "Kenji", "Morita", "JP", 2001, 72, &"aurum")
	_make_driver(&"d_ferrand", "Lucas", "Ferrand", "FR", 1999, 70, &"kestrel")
	_make_driver(&"d_vidal", "Tomas", "Vidal", "ES", 2003, 68, &"kestrel")
	_make_driver(&"d_price", "Aiden", "Price", "AU", 1997, 74, &"solace")
	_make_driver(&"d_saari", "Mikael", "Saari", "FI", 2005, 64, &"solace")
	_make_driver(&"d_calder", "Owen", "Calder", "US", 2000, 69, &"ironbridge")
	_make_driver(&"d_dewit", "Pieter", "de Wit", "NL", 2002, 67, &"ironbridge")

	GameState.player_team_id = &"vortex"


static func _make_tyres() -> void:
	# Softest first: more grip, faster wear.
	GameState.tyre_compounds.append(_tyre(&"soft", "Soft", Color.RED, 1.012, 1.1))
	GameState.tyre_compounds.append(_tyre(&"medium", "Medium", Color.YELLOW, 1.0, 0.7))
	GameState.tyre_compounds.append(_tyre(&"hard", "Hard", Color.WHITE, 0.99, 0.45))


static func _tyre(id: StringName, display: String, color: Color, grip: float,
		wear_per_km: float) -> TyreCompound:
	var t := TyreCompound.new()
	t.id = id
	t.display_name = display
	t.color = color
	t.grip = grip
	t.wear_per_km = wear_per_km
	return t


static func _make_test_track() -> void:
	var track := TrackData.new()
	track.id = &"test_ring"
	track.name = "Test Ring"
	track.country = "XX"
	track.lap_length_m = 4800.0
	track.laps = 25
	track.pit_lane_loss_s = 20.0
	track.curve = _smooth_closed_curve(PackedVector2Array(TEST_RING_POINTS))
	GameState.tracks[track.id] = track


## Catmull-Rom style smoothing: each point gets handles parallel to the
## line between its neighbours, which gives round corners.
static func _smooth_closed_curve(points: PackedVector2Array) -> Curve2D:
	var curve := Curve2D.new()
	var n := points.size()
	for i in n + 1:
		var tangent := (points[(i + 1) % n] - points[(i - 1 + n) % n]) / 6.0
		curve.add_point(points[i % n], -tangent, tangent)
	return curve


static func _make_team(id: StringName, team_name: String, short: String,
		color: Color, car_level: int, series: SeriesData) -> void:
	var team := TeamData.new()
	team.id = id
	team.name = team_name
	team.short_name = short
	team.series_id = series.id
	team.primary_color = color
	team.budget = 50_000_000

	var car := CarData.new()
	car.team_id = id
	car.downforce = _spread(car_level, 6)
	car.drag_efficiency = _spread(car_level, 6)
	car.engine_power = _spread(car_level, 6)
	car.mechanical_grip = _spread(car_level, 6)
	car.tyre_preservation = _spread(car_level, 10)
	car.reliability = _spread(car_level + 10, 10)
	team.car = car

	series.team_ids.append(id)
	GameState.add_team(team)


static func _make_driver(id: StringName, first: String, last: String,
		nationality: String, birth_year: int, skill: int, team_id: StringName) -> void:
	var d := DriverData.new()
	d.id = id
	d.first_name = first
	d.last_name = last
	d.nationality = nationality
	d.birth_year = birth_year
	d.team_id = team_id
	d.series_id = GameState.teams[team_id].series_id
	d.cornering = _spread(skill, 5)
	d.braking = _spread(skill, 5)
	d.overtaking = _spread(skill, 5)
	d.defending = _spread(skill, 5)
	d.consistency = _spread(skill, 5)
	d.tyre_management = _spread(skill, 5)
	d.wet_skill = _spread(skill, 5)
	d.starts = _spread(skill, 5)
	d.potential = clampi(skill + randi_range(0, 15), 0, 100)
	GameState.add_driver(d)
	GameState.teams[team_id].driver_ids.append(id)


static func _spread(base: int, amount: int) -> int:
	return clampi(base + randi_range(-amount, amount), 0, 100)
