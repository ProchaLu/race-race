## Builds a fictional development world: 11 teams, 22 drivers, a 24-race
## calendar and a half-finished season. Texts stay English here; they are
## translation keys (see i18n/strings.csv). Will be replaced by the real start
## database (design doc 1.2) later.
class_name TestWorld
extends RefCounted

const ROUNDS_COMPLETED := 13
const FIRST_RACE_DAY := 60
const DAYS_BETWEEN_RACES := 12

## Corner points of the test circuit (screen pixels). Smoothed into a curve.
const TEST_RING_POINTS := [
	Vector2(150, 460), Vector2(450, 460), Vector2(720, 460), Vector2(790, 430),
	Vector2(800, 360), Vector2(760, 300), Vector2(640, 280), Vector2(560, 250),
	Vector2(540, 190), Vector2(600, 130), Vector2(680, 70), Vector2(600, 40),
	Vector2(460, 50), Vector2(300, 60), Vector2(200, 80), Vector2(170, 140),
	Vector2(230, 190), Vector2(320, 220), Vector2(340, 290), Vector2(260, 330),
	Vector2(120, 340), Vector2(70, 390), Vector2(90, 450),
]

## [id, name, short name, country]
const CALENDAR := [
	[&"port_aurel", "Port Aurel Grand Prix", "PORT AUREL", "AE"],
	[&"sandhaven", "Sandhaven Grand Prix", "SANDHAVEN", "SA"],
	[&"kingsbridge", "Kingsbridge Grand Prix", "KINGSBRIDGE", "AU"],
	[&"kaigan", "Kaigan Grand Prix", "KAIGAN", "JP"],
	[&"linhai", "Linhai Grand Prix", "LINHAI", "CN"],
	[&"coral_coast", "Coral Coast Grand Prix", "CORAL COAST", "US"],
	[&"sierra_alta", "Sierra Alta Grand Prix", "SIERRA ALTA", "ES"],
	[&"port_monique", "Port Monique Grand Prix", "PT MONIQUE", "MC"],
	[&"valdera", "Valdera Grand Prix", "VALDERA", "IT"],
	[&"kessling", "Kessling Grand Prix", "KESSLING", "BE"],
	[&"sorrento", "Sorrento Ring Grand Prix", "SORRENTO", "IT"],
	[&"harrow_park", "Harrow Park Grand Prix", "HARROW", "GB"],
	[&"oakmere", "Oakmere Grand Prix", "OAKMERE", "US"],
	[&"monteverde", "Monteverde Grand Prix", "MONTEVERDE", "MX"],
	[&"alpenring", "Alpenring Grand Prix", "ALPENRING", "AT"],
	[&"duinen", "Duinen Grand Prix", "DUINEN", "NL"],
	[&"pusztavar", "Pusztavár Grand Prix", "PUSZTAVÁR", "HU"],
	[&"lakeshore", "Lakeshore Grand Prix", "LAKESHORE", "CA"],
	[&"marina_kota", "Marina Kota Grand Prix", "MARINA KOTA", "SG"],
	[&"caspian", "Caspian City Grand Prix", "CASPIAN", "AZ"],
	[&"lone_star", "Lone Star Grand Prix", "LONE STAR", "US"],
	[&"rio_celeste", "Rio Celeste Grand Prix", "RIO CELESTE", "BR"],
	[&"desert_mirage", "Desert Mirage Grand Prix", "DESERT MIRAGE", "QA"],
	[&"al_noor", "Al Noor Grand Prix", "AL NOOR", "AE"],
]

## [id, name, short, colour, car level, budget in $M]
const TEAMS := [
	[&"vortex", "Vortex Racing", "VRT", Color("e8471c"), 66, 180],
	[&"nordline", "Nordline GP", "NRD", Color("1e90ff"), 68, 210],
	[&"aurum", "Aurum Motorsport", "AUR", Color("ffd23f"), 74, 330],
	[&"kestrel", "Kestrel Racing", "KES", Color("32cd32"), 60, 150],
	[&"solace", "Solace Racing", "SOL", Color("9370db"), 57, 140],
	[&"ironbridge", "Ironbridge Engineering", "IRB", Color("c0c0c0"), 52, 120],
	[&"meridian", "Meridian F1 Team", "MER", Color("1fb5a8"), 70, 260],
	[&"halcyon", "Halcyon Racing", "HAL", Color("ff69b4"), 55, 130],
	[&"brightwater", "Brightwater Motorsport", "BWM", Color("4a6cf7"), 63, 170],
	[&"corsa", "Scuderia Corsa Alta", "SCA", Color("dc143c"), 72, 300],
	[&"tundra", "Tundra Performance", "TUN", Color("9fd3f0"), 50, 115],
]

## [id, number, first, last, nationality, birth year, skill, team, traits]
const DRIVERS := [
	[&"d_hale", 7, "Marco", "Hale", "IT", 1998, 78, &"vortex", [&"rain_master", &"quali_specialist", &"hot_headed"]],
	[&"d_brandt", 27, "Jonas", "Brandt", "DE", 2002, 71, &"vortex", [&"rocket_start"]],
	[&"d_okafor", 4, "Daniel", "Okafor", "GB", 2000, 75, &"nordline", []],
	[&"d_lindqvist", 31, "Erik", "Lindqvist", "SE", 2004, 66, &"nordline", [&"slow_learner"]],
	[&"d_duarte", 1, "Rafael", "Duarte", "BR", 1996, 82, &"aurum", [&"clutch", &"tyre_whisperer"]],
	[&"d_morita", 22, "Kenji", "Morita", "JP", 2001, 72, &"aurum", [&"team_player"]],
	[&"d_ferrand", 10, "Lucas", "Ferrand", "FR", 1999, 70, &"kestrel", []],
	[&"d_vidal", 18, "Tomas", "Vidal", "ES", 2003, 68, &"kestrel", []],
	[&"d_price", 3, "Aiden", "Price", "AU", 1997, 74, &"solace", [&"media_darling"]],
	[&"d_saari", 44, "Mikael", "Saari", "FI", 2005, 64, &"solace", []],
	[&"d_calder", 12, "Owen", "Calder", "US", 2000, 69, &"ironbridge", []],
	[&"d_dewit", 21, "Pieter", "de Wit", "NL", 2002, 67, &"ironbridge", []],
	[&"d_alstad", 5, "Viktor", "Alstad", "NO", 1986, 79, &"meridian", [&"evergreen", &"mentor"]],
	[&"d_achterberg", 16, "Leon", "Achterberg", "AT", 2003, 70, &"meridian", []],
	[&"d_menon", 9, "Ravi", "Menon", "IN", 2001, 66, &"halcyon", []],
	[&"d_arrieta", 26, "Felipe", "Arrieta", "AR", 2006, 63, &"halcyon", [&"hot_headed"]],
	[&"d_reyes", 8, "Callum", "Reyes", "CA", 1998, 71, &"brightwater", [&"tyre_killer"]],
	[&"d_kessler", 33, "Noah", "Kessler", "CH", 2004, 68, &"brightwater", []],
	[&"d_ferraro", 11, "Matteo", "Ferraro", "IT", 1995, 80, &"corsa", [&"glass_nerves"]],
	[&"d_lemaire", 2, "Hugo", "Lemaire", "BE", 2000, 77, &"corsa", [&"rain_master"]],
	[&"d_koskinen", 14, "Jari", "Koskinen", "FI", 1993, 65, &"tundra", []],
	[&"d_whitlock", 41, "Sam", "Whitlock", "NZ", 2005, 62, &"tundra", []],
]

const AGENTS := ["Paolo Ricci", "Sarah Klein", "Marcus Dunn", "Ines Duval", "Henrik Berg", "Lucia Romero"]


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
	_make_calendar(f1)
	for t in TEAMS:
		_make_team(t[0], t[1], t[2], t[3], t[4], t[5] * 1_000_000, f1)
	for d in DRIVERS:
		_make_driver(d)
	GameState.player_team_id = &"vortex"

	_make_player_team_details()
	Calendar.day = FIRST_RACE_DAY + (ROUNDS_COMPLETED - 1) * DAYS_BETWEEN_RACES + 3
	for round_index in ROUNDS_COMPLETED:
		QuickRace.resolve_round(f1, round_index)
	GameState.resolved_rounds = ROUNDS_COMPLETED
	_make_welcome_messages()


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
	track.short_name = "TEST RING"
	track.country = "GB"
	track.lap_length_m = 4800.0
	track.laps = 25
	track.pit_lane_loss_s = 20.0
	track.curve = _smooth_closed_curve(PackedVector2Array(TEST_RING_POINTS))
	GameState.tracks[track.id] = track


## Calendar tracks have no racing line yet (track editor comes later).
static func _make_calendar(series: SeriesData) -> void:
	for i in CALENDAR.size():
		var entry: Array = CALENDAR[i]
		var track := TrackData.new()
		track.id = entry[0]
		track.name = entry[1]
		track.short_name = entry[2]
		track.country = entry[3]
		GameState.tracks[track.id] = track
		series.calendar.append(track.id)
		series.race_days.append(FIRST_RACE_DAY + i * DAYS_BETWEEN_RACES)


## Catmull-Rom style smoothing: each point gets handles parallel to the
## line between its neighbours, which gives round corners.
static func _smooth_closed_curve(points: PackedVector2Array) -> Curve2D:
	var curve := Curve2D.new()
	var n := points.size()
	for i in n + 1:
		var tangent := (points[(i + 1) % n] - points[(i - 1 + n) % n]) / 6.0
		curve.add_point(points[i % n], -tangent, tangent)
	return curve


static func _make_team(id: StringName, team_name: String, short: String, color: Color,
		car_level: int, budget: int, series: SeriesData) -> void:
	var team := TeamData.new()
	team.id = id
	team.name = team_name
	team.short_name = short
	team.series_id = series.id
	team.primary_color = color
	team.budget = budget

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


static func _make_driver(entry: Array) -> void:
	var d := DriverData.new()
	d.id = entry[0]
	d.number = entry[1]
	d.first_name = entry[2]
	d.last_name = entry[3]
	d.nationality = entry[4]
	d.birth_year = entry[5]
	var skill: int = entry[6]
	d.team_id = entry[7]
	d.traits.assign(entry[8])
	d.series_id = GameState.teams[d.team_id].series_id
	var age := d.age(Calendar.year)

	for attr in DriverAttributes.DRIVING:
		d.set(attr[0], _spread(skill, 7))
	for attr in DriverAttributes.MENTAL:
		d.set(attr[0], _spread(skill - 5, 15))
	d.fitness = _spread(skill + 5 - maxi(0, age - 32) * 2, 6)
	d.reactions = _spread(skill + 3 - maxi(0, age - 30) * 2, 6)
	# Older drivers: experience shows in the mental side.
	d.composure = clampi(d.composure + maxi(0, age - 26), 0, 100)
	d.consistency = clampi(d.consistency + maxi(0, age - 28), 0, 100)
	if d.traits.has(&"rain_master"):
		d.wet_skill = clampi(d.wet_skill + 12, 0, 100)
	if d.traits.has(&"hot_headed"):
		d.temperament = clampi(d.temperament - 20, 0, 100)
	if d.traits.has(&"evergreen"):
		d.peak_end_age = 41
		d.decline_rate = 0.4

	d.potential = clampi(d.overall() + maxi(0, 26 - age) * 2 + randi_range(0, 6), 0, 100)
	d.seasons = clampi(age - 21, 0, 20)
	d.races = d.seasons * 22  # this season's races are added by QuickRace
	d.form = randi_range(35, 80)
	d.confidence = randi_range(40, 85)
	d.match_fitness = randi_range(86, 99)
	d.morale_factors = {"Recent results": randi_range(-10, 12), "Contract security": randi_range(0, 6)}
	d.recalculate_morale()
	_make_ability_history(d)

	GameState.add_driver(d)
	GameState.teams[d.team_id].driver_ids.append(d.id)
	_make_contract(d, skill)


## Past season values. Young drivers improved a lot; with age the physical
## side declines while the mental side keeps growing.
static func _make_ability_history(d: DriverData) -> void:
	var age := d.age(Calendar.year)
	var years := mini(6, d.seasons + 1)
	var groups := {"driving": DriverAttributes.DRIVING, "mental": DriverAttributes.MENTAL,
		"physical": DriverAttributes.PHYSICAL}
	for group in groups:
		for entry in groups[group]:
			var current: int = d.get(entry[0])
			var history: Array[int] = []
			var value := current
			# Walk backwards from today, undoing each year's change.
			for years_ago in range(1, years):
				value -= _yearly_change(group, age - years_ago + 1) + randi_range(-1, 1)
				history.push_front(clampi(value, 0, 100))
			history.append(current)
			d.attribute_history[entry[0]] = history

	d.ability_history.clear()
	for i in years:
		var years_ago := years - 1 - i
		var growth_per_year := 3 if age - years_ago < 25 else (1 if age - years_ago < 31 else 0)
		d.ability_history.append(clampi(d.overall() - years_ago * growth_per_year + randi_range(-1, 1), 0, 100))
	d.ability_history[-1] = d.overall()


## Typical change of an attribute group during the season a driver turned `age`.
static func _yearly_change(group: String, age: int) -> int:
	match group:
		"physical":
			return 2 if age < 25 else (0 if age < 31 else -2)
		"mental":
			return 2 if age < 30 else 1
	return 3 if age < 25 else (1 if age < 31 else 0)


static func _make_contract(d: DriverData, skill: int) -> void:
	var c := ContractData.new()
	c.person_id = d.id
	c.team_id = d.team_id
	c.salary = maxi(800_000, (skill - 55) * 220_000 + randi_range(0, 4) * 100_000)
	c.start_year = Calendar.year - randi_range(0, 2)
	c.end_year = Calendar.year + randi_range(0, 3)
	var teammate_skill := 0
	for other in DRIVERS:
		if other[7] == d.team_id and other[0] != d.id:
			teammate_skill = other[6]
	c.role = ContractData.DriverRole.NUMBER_ONE if skill >= teammate_skill + 5 \
		else (ContractData.DriverRole.NUMBER_TWO if skill <= teammate_skill - 5 else ContractData.DriverRole.EQUAL)
	c.win_bonus = roundi(c.salary * 0.06 / 10_000.0) * 10_000
	c.podium_bonus = roundi(c.salary * 0.02 / 10_000.0) * 10_000
	c.release_clause = c.salary * 3 if skill >= 70 else 0
	c.team_option_year = c.end_year + 1 if randf() < 0.4 else 0
	c.agent_name = AGENTS[randi() % AGENTS.size()]
	GameState.contracts.append(c)


## Hand-made details for the player's team so the profile shows every feature.
static func _make_player_team_details() -> void:
	var hale: DriverData = GameState.drivers[&"d_hale"]
	hale.training_focus = &"tyre_management"
	hale.form = 70
	hale.confidence = 80
	hale.match_fitness = 94
	hale.attribute_changes = {&"cornering": 1, &"tyre_management": 1, &"temperament": -1, &"reactions": -1}
	hale.morale_factors = {
		"Results above expectations": 12,
		"No.1 status (promise kept)": 8,
		"Contract security": 5,
		"Tension with teammate": -6,
		"Car not competitive": -4,
	}
	hale.recalculate_morale()

	var brandt: DriverData = GameState.drivers[&"d_brandt"]
	brandt.training_focus = &"overtaking"
	brandt.morale_factors = {"Treated as No.2 driver": -8, "Good recent races": 6, "Tension with teammate": -6}
	brandt.recalculate_morale()

	_make_engineer(&"s_lund", "Sofia", "Lund", "SE", 1988, 82, &"d_hale")
	_make_engineer(&"s_becker", "Tom", "Becker", "DE", 1992, 66, &"d_brandt")
	GameState.staff[&"s_lund"].gender = PersonData.Gender.FEMALE

	GameState.set_relationship(&"d_hale", &"d_brandt",
		{"Team order at Valdera": -15, "Comments in the media": -5, "Close fights on track": -4})
	GameState.set_relationship(&"d_hale", &"s_lund", {"Years working together": 30, "Successful strategies": 22})
	GameState.set_relationship(&"d_hale", GameState.PLAYER_ID, {"No.1 status given": 15, "Promises kept": 10})
	GameState.set_relationship(&"d_brandt", &"s_becker", {"New pairing this season": 8})
	GameState.set_relationship(&"d_brandt", GameState.PLAYER_ID, {"Team order at Valdera": -12, "Contract extended": 10})

	var p1 := PromiseData.new()
	p1.person_id = &"d_hale"
	p1.description = "No.1 status"
	p1.status = PromiseData.Status.KEPT
	p1.made_on = "Jan 2026"
	GameState.promises.append(p1)
	var p2 := PromiseData.new()
	p2.person_id = &"d_hale"
	p2.description = "Competitive car by mid-season"
	p2.made_on = "Mar 2026"
	p2.deadline_round = 14
	GameState.promises.append(p2)

	var contract := GameState.contract_of(&"d_hale")
	contract.salary = 4_200_000
	contract.end_year = 2028
	contract.role = ContractData.DriverRole.NUMBER_ONE
	contract.win_bonus = 250_000
	contract.podium_bonus = 80_000
	contract.release_clause = 12_000_000
	contract.team_option_year = 2029
	contract.agent_name = "Paolo Ricci"


static func _make_engineer(id: StringName, first: String, last: String, nationality: String,
		birth_year: int, ability: int, driver_id: StringName) -> void:
	var s := StaffData.new()
	s.id = id
	s.first_name = first
	s.last_name = last
	s.nationality = nationality
	s.birth_year = birth_year
	s.role = StaffData.Role.RACE_ENGINEER
	s.ability = ability
	s.team_id = GameState.player_team_id
	s.assigned_driver_id = driver_id
	GameState.add_staff(s)
	GameState.teams[s.team_id].staff_ids.append(id)


static func _make_welcome_messages() -> void:
	var team := GameState.player_team()
	var welcome := InboxMessage.new()
	welcome.sender = "Owner"
	welcome.subject = "Welcome to %s"
	welcome.subject_args = [team.name]
	welcome.icon = "briefcase"
	welcome.add_paragraph("Welcome on board. You take over the team after round %d of the season.", [ROUNDS_COMPLETED])
	welcome.add_paragraph("The board expects a top-5 finish in the constructors' championship. We trust you to get the most out of the team.")
	GameState.add_message(welcome)

	var report := InboxMessage.new()
	report.sender = "Sofia Lund"
	report.subject = "Training report: %s"
	report.subject_args = ["Marco Hale"]
	report.icon = "user"
	report.add_paragraph("%s is focusing on tyre management. Progress is good and we expect another step within about three months.", ["Marco Hale"])
	report.link_screen = &"driver_profile"
	report.link_args = {"driver_id": &"d_hale"}
	report.link_label = "Open driver profile"
	GameState.add_message(report)

	var contract := InboxMessage.new()
	contract.sender = "Sporting director"
	contract.subject = "Contract situation: %s"
	contract.subject_args = ["Jonas Brandt"]
	contract.icon = "users"
	contract.add_paragraph("%s is unhappy with his No.2 role. His morale is low and his agent has started to listen to other teams.", ["Jonas Brandt"])
	contract.link_screen = &"driver_profile"
	contract.link_args = {"driver_id": &"d_brandt"}
	contract.link_label = "Open driver profile"
	GameState.add_message(contract)


static func _spread(base: int, amount: int) -> int:
	return clampi(base + randi_range(-amount, amount), 0, 100)
