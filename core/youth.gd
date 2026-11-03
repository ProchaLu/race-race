## The junior pyramid (R7, docs/youth_model.md): F3 and F2 teams, the yearly
## cohort of newgens, their seasons (simulated in the background), the super
## licence points and the flow of people from one level to the next.
## Junior teams have no budget, staff or car of their own; the player's
## academy places its drivers in their seats (Academy.place).
class_name Youth
extends RefCounted

const F3 := &"f3"
const F2 := &"f2"
## Juniors without a team: newgens and drivers released by a junior team.
const POOL := &"youth"
const SERIES := [&"f3", &"f2"]
const SERIES_NAMES := {&"f3": "Apex F3", &"f2": "Apex F2"}
const SEATS := 2
## Juniors above this age leave the system at the new season.
const MAX_AGE := 24
## F3 seats are for juniors up to this age; older ones move up or leave.
const MAX_AGE_F3 := 20
const NEWGENS_PER_YEAR := 24
## Race points for the first ten finishers (same as F1).
const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
## Super licence points by final place in the junior championships.
const LICENCE_POINTS := {&"f2": [40, 30, 20, 10, 5], &"f3": [5, 3, 1]}
## Points over the last three seasons that give the super licence.
const LICENCE_NEEDED := 40
const RETIRE_CHANCE := 0.03

## [id, name, short name, colour, series, strength]
const TEAMS := [
	[&"f3_kiel", "Kiel Junior Racing", "KJR", Color("f28c28"), F3, 50],
	[&"f3_marlow", "Marlow Academy GP", "MAG", Color("2e8b57"), F3, 56],
	[&"f3_sunridge", "Sunridge Motorsport", "SUN", Color("f4d03f"), F3, 46],
	[&"f3_brisk", "Brisk Racing", "BRK", Color("5dade2"), F3, 52],
	[&"f3_velde", "Velde Talent", "VLD", Color("af7ac5"), F3, 44],
	[&"f3_norcross", "Norcross Racing", "NOR", Color("e74c3c"), F3, 58],
	[&"f3_oakfield", "Oakfield Young Drivers", "OAK", Color("d5dbdb"), F3, 48],
	[&"f3_tessera", "Tessera Motorsport", "TSM", Color("1abc9c"), F3, 54],
	[&"f3_lindberg", "Lindberg Racing", "LIN", Color("7f8c8d"), F3, 42],
	[&"f3_portvale", "Port Vale Junior", "PVJ", Color("c39bd3"), F3, 50],
	[&"f2_ardent", "Ardent Racing", "ARD", Color("e67e22"), F2, 62],
	[&"f2_covell", "Covell Motorsport", "COV", Color("3498db"), F2, 58],
	[&"f2_hallen", "Hallen GP", "HLN", Color("2ecc71"), F2, 66],
	[&"f2_strada", "Strada Corse", "STR", Color("e91e63"), F2, 64],
	[&"f2_rostov", "Rostov Racing", "ROS", Color("95a5a6"), F2, 54],
	[&"f2_halvard", "Halvard Motorsport", "HVD", Color("8e44ad"), F2, 60],
	[&"f2_mistral", "Mistral F2", "MIS", Color("00bcd4"), F2, 60],
	[&"f2_cygnus", "Cygnus Racing", "CYG", Color("9b59b6"), F2, 56],
	[&"f2_pelham", "Pelham Motorsport", "PEL", Color("f1c40f"), F2, 52],
	[&"f2_ostmark", "Ostmark Racing", "OST", Color("34495e"), F2, 60],
]


static func is_youth(d: DriverData) -> bool:
	return d.series_id == POOL or SERIES.has(d.series_id)


static func team_of(d: DriverData) -> YouthTeam:
	return GameState.youth_teams.get(d.team_id)


## Worth in a selection: today's level plus half the potential.
static func value(d: DriverData) -> float:
	return d.overall() + d.potential * 0.5


static func max_age(series_id: StringName) -> int:
	return MAX_AGE_F3 if series_id == F3 else MAX_AGE


## Juniors without a team and without an academy that are not retired.
## Academy members wait for the academy to place them (Academy.place).
static func pool() -> Array[DriverData]:
	var out: Array[DriverData] = []
	for d in GameState.drivers.values():
		if d.team_id == &"" and not d.retired and d.academy_team_id == &"" and is_youth(d):
			out.append(d)
	return out


## Creates the junior teams, their first drivers and the first cohort. Called
## once for a new world, after the F1 people exist.
static func setup_world(r: RandomNumberGenerator) -> void:
	for row in TEAMS:
		var t := YouthTeam.new()
		t.id = row[0]
		t.name = row[1]
		t.short_name = row[2]
		t.color = row[3]
		t.series_id = row[4]
		t.strength = row[5]
		GameState.youth_teams[t.id] = t
	for t in GameState.youth_teams.values():
		var tier := PersonGenerator.DriverTier.F2 if t.series_id == F2 else PersonGenerator.DriverTier.F3
		for i in SEATS:
			var d := PersonGenerator.driver(r, tier)
			GameState.add_driver(d)
			GameState.knowledge[d.id] = r.randi_range(10, 35)
			seat(d, t)
	for i in NEWGENS_PER_YEAR:
		_newgen(r)
	reset_standings()


## The new season: juniors who are too old leave, the newgens join, every
## junior seat is filled again (academy placements stay), academy drivers
## grow. Returns the report for the season message.
static func new_season(year: int, r: RandomNumberGenerator) -> Dictionary:
	reset_standings()
	var report := {"left": [], "cohort": NEWGENS_PER_YEAR, "academy": []}
	for d in GameState.drivers.values():
		if d.retired or not is_youth(d) or d.age(year) <= MAX_AGE:
			continue
		Academy.forget(d)
		unseat(d)
		# Licence holders go on to the F1 market; the others leave the sport.
		if d.has_superlicence:
			d.series_id = &""
		else:
			d.retired = true
		report.left.append(d.full_name())
	for t in GameState.youth_teams.values():
		var kept: Array[StringName] = []
		for id in t.driver_ids:
			var d: DriverData = GameState.drivers.get(id)
			if d and Academy.is_placed(d):
				kept.append(id)
			elif d:
				d.team_id = &""
				d.series_id = POOL
		t.driver_ids = kept
		t.strength = clampi(t.strength + r.randi_range(-3, 3), 30, 75)
	for i in NEWGENS_PER_YEAR:
		_newgen(r)
	# Championship seats first, F2 before F3: the best juniors go up as far as they can.
	_fill(F2, year)
	_fill(F3, year)
	report.academy = Academy.new_season(GameState.player_team(), r)
	return report


## One race weekend of both junior series, same round as the F1 race.
static func resolve_round() -> void:
	for series_id in SERIES:
		var entries := []
		for t in GameState.youth_teams.values():
			if t.series_id != series_id:
				continue
			for id in t.driver_ids:
				var d: DriverData = GameState.drivers[id]
				var base: float = d.overall() * 0.8 + t.strength * 0.3
				entries.append([d, t, base + randf_range(-6.0, 6.0)])
		entries.sort_custom(func(a, b): return a[2] > b[2])
		var st := standings(series_id)
		var place := 0
		for e in entries:
			if randf() < RETIRE_CHANCE:
				continue
			place += 1
			var pts: int = POINTS[place - 1] if place <= POINTS.size() else 0
			_add(st.drivers, e[0].id, pts)
			_add(st.teams, e[1].id, pts)
			if place == 1:
				_add(st.wins, e[0].id, 1)
		st.rounds += 1


## The junior championships are over: super licence points, the season
## message. Called at the end of the F1 season.
static func season_end() -> void:
	var totals := {}
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Junior seasons finished"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "graduation-cap"
	for series_id in SERIES:
		var rows := table(series_id)
		for i in rows.size():
			var id: StringName = rows[i][0]
			totals[id] = totals.get(id, 0) + _licence_for(series_id, i)
		if rows.is_empty():
			continue
		var champion: DriverData = GameState.drivers.get(rows[0][0])
		if champion:
			msg.add_paragraph("%s champion: %s (%d points, %d rounds).",
				[SERIES_NAMES[series_id], champion.full_name(), rows[0][1], standings(series_id).rounds])
	for id in totals:
		var d: DriverData = GameState.drivers.get(id)
		if not d:
			continue
		d.superlicence_points.append(totals[id])
		while d.superlicence_points.size() > 3:
			d.superlicence_points.pop_front()
		if licence_points(d) >= LICENCE_NEEDED and not d.has_superlicence:
			d.has_superlicence = true
			msg.add_paragraph("%s has earned the super licence (%d points in three seasons).",
				[d.full_name(), licence_points(d)])
	for d in Academy.drivers(GameState.player_team()):
		msg.add_paragraph("Academy: %s – %d super licence points in three seasons.",
			[d.full_name(), licence_points(d)])
	msg.link_screen = &"academy"
	msg.link_args = {}
	msg.link_label = "Open academy"
	GameState.add_message(msg)


## Points over the last three seasons.
static func licence_points(d: DriverData) -> int:
	var sum := 0
	for p in d.superlicence_points:
		sum += p
	return sum


## Drivers' table of a junior series: [[driver_id, points], ...], best first.
static func table(series_id: StringName) -> Array:
	var st := standings(series_id)
	var out := []
	for id in st.drivers:
		out.append([id, st.drivers[id]])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out


## The results of this season of one junior series (created on first access).
static func standings(series_id: StringName) -> Dictionary:
	return GameState.youth_standings.get_or_add(series_id, {"drivers": {}, "teams": {}, "wins": {}, "rounds": 0})


static func reset_standings() -> void:
	GameState.youth_standings.clear()


# --- Helpers -----------------------------------------------------------------

static func _newgen(r: RandomNumberGenerator) -> DriverData:
	var d := PersonGenerator.driver(r, PersonGenerator.DriverTier.NEWGEN)
	GameState.add_driver(d)
	GameState.knowledge[d.id] = r.randi_range(5, 25)
	return d


static func seat(d: DriverData, t: YouthTeam) -> void:
	t.driver_ids.append(d.id)
	d.team_id = t.id
	d.series_id = t.series_id


static func unseat(d: DriverData) -> void:
	var t := team_of(d)
	if t:
		t.driver_ids.erase(d.id)
	d.team_id = &""
	d.series_id = POOL


## Fills the empty seats of one series from the pool, best value first.
static func _fill(series_id: StringName, year: int) -> void:
	var candidates := pool().filter(func(d): return d.age(year) <= max_age(series_id))
	candidates.sort_custom(func(a, b): return value(a) > value(b))
	for t in GameState.youth_teams.values():
		if t.series_id != series_id:
			continue
		while t.driver_ids.size() < SEATS and not candidates.is_empty():
			seat(candidates.pop_front(), t)


static func _licence_for(series_id: StringName, position: int) -> int:
	var points: Array = LICENCE_POINTS[series_id]
	return points[position] if position < points.size() else 0


static func _add(dict: Dictionary, key: StringName, amount: int) -> void:
	dict[key] = dict.get(key, 0) + amount
