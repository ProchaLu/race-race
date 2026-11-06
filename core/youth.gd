## The junior pyramid (R7, docs/youth_model.md): regional karting, F3 and F2
## teams, the yearly cohort of newgens, their seasons (simulated in the
## background), the super licence points and the flow of people from one
## level to the next. Karting kids are hidden until a scout finds them
## (Scouting, GameState.discovered). Junior teams have no budget, staff or car
## of their own; academies place their drivers in their seats (Academy.place).
class_name Youth
extends RefCounted

const F3 := &"f3"
const F2 := &"f2"
## Juniors without a team: drivers who left karting or a junior team.
const POOL := &"youth"
## Kids in the regional karting series (14–15 years, hidden until scouted).
const KARTING := &"karting"
const SERIES := [&"f3", &"f2"]
const SERIES_NAMES := {&"f3": "Apex F3", &"f2": "Apex F2"}
## Karting championships per scouting region (standings keys).
const KART_SERIES := {&"europe": &"kart_europe", &"americas": &"kart_americas", &"asia_pacific": &"kart_asia_pacific"}
const KART_NAMES := {&"kart_europe": "Karting Europe", &"kart_americas": "Karting Americas",
	&"kart_asia_pacific": "Karting Asia & Pacific"}
const SEATS := 2
## Juniors above this age leave the system at the new season.
const MAX_AGE := 24
## F3 seats are for juniors up to this age; older ones move up or leave.
const MAX_AGE_F3 := 20
## Youngest age for an F3 or F2 seat; younger kids race karting.
const MIN_SEAT_AGE := 16
## Karting kids leave karting at this age and join the junior pool.
const KART_LEAVE_AGE := 16
const NEWGEN_AGE := 14
const NEWGENS_PER_YEAR := 24
## Per cohort: wonderkids (very high potential) and late bloomers (weak now,
## fast growth later).
const WONDERKIDS := [1, 2]
const LATE_BLOOMERS := 2
## Race points for the first ten finishers (same as F1).
const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
## Super licence points by final place in the junior championships.
const LICENCE_POINTS := {&"f2": [40, 30, 20, 10, 5], &"f3": [5, 3, 1]}
## Points over the last three seasons that give the super licence.
const LICENCE_NEEDED := 40
const RETIRE_CHANCE := 0.03
const KART_RETIRE_CHANCE := 0.05
## Strength of every kart (karting has no teams).
const KART_STRENGTH := 45
## Race practice for the winter development (Development._practice): a full
## season in a seat counts like this, a junior without races like the pool.
const PRACTICE := {&"f2": 0.9, &"f3": 0.8, &"karting": 0.6}
const PRACTICE_POOL := 0.45
const PRACTICE_ACADEMY := 0.55
## Extra practice for good results: average points per race / 25 × this, capped.
const RESULT_BONUS := 0.3
const RESULT_BONUS_MAX := 0.15
## Paddock talk about a wonderkid after this many wins in a season.
const HYPE_WINS := 3

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
	return d.series_id == POOL or d.series_id == KARTING or SERIES.has(d.series_id)


static func is_karting(d: DriverData) -> bool:
	return d.series_id == KARTING


static func team_of(d: DriverData) -> YouthTeam:
	return GameState.youth_teams.get(d.team_id)


## Worth in a selection: today's level plus half the potential.
static func value(d: DriverData) -> float:
	return d.overall() + d.potential * 0.5


static func max_age(series_id: StringName) -> int:
	return MAX_AGE_F3 if series_id == F3 else MAX_AGE


## The championship a junior races in this season: f3, f2, a karting key or &"".
static func series_key(d: DriverData) -> StringName:
	var t := team_of(d)
	if t:
		return t.series_id
	if is_karting(d):
		return KART_SERIES[Scouting.region_of(d)]
	return &""


static func series_name(key: StringName) -> String:
	return SERIES_NAMES.get(key, KART_NAMES.get(key, ""))


## Every championship key: F2, F3 and the karting regions.
static func all_series() -> Array:
	return [F2, F3] + KART_SERIES.values()


## Whether the player can see this junior. Karting kids only after a scout found
## them (or when they belong to the player's academy).
static func is_visible(d: DriverData) -> bool:
	if not is_karting(d):
		return true
	return GameState.discovered.has(d.id) or d.academy_team_id == GameState.player_team_id


## Juniors without a team and without an academy that are not retired.
## Academy members wait for the academy to place them (Academy.place).
static func pool() -> Array[DriverData]:
	var out: Array[DriverData] = []
	for d in GameState.drivers.values():
		if d.team_id == &"" and not d.retired and d.academy_team_id == &"" and d.series_id == POOL:
			out.append(d)
	return out


## Karting kids (all, the hidden ones included).
static func karting() -> Array[DriverData]:
	var out: Array[DriverData] = []
	for d in GameState.drivers.values():
		if is_karting(d) and not d.retired:
			out.append(d)
	return out


## Creates the junior teams, their first drivers, a pool and two karting
## cohorts. Called once for a new world, after the F1 people exist.
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
		var d := _newgen(r, r.randi_range(KART_LEAVE_AGE, 17))
		d.series_id = POOL
		GameState.knowledge[d.id] = r.randi_range(5, 25)
	_cohort(r, NEWGEN_AGE)
	_cohort(r, NEWGEN_AGE + 1)
	reset_standings()


## The new season: juniors who are too old leave, karting kids old enough join
## the pool, the new cohort starts karting, every junior seat is filled again
## (academy placements stay), academies grow their drivers and place them.
## Returns the report for the season message.
static func new_season(year: int, r: RandomNumberGenerator) -> Dictionary:
	reset_standings()
	var report := {"left": [], "cohort": NEWGENS_PER_YEAR, "academy": []}
	for d in GameState.drivers.values():
		if d.retired or not is_youth(d):
			continue
		if is_karting(d) and d.age(year) >= KART_LEAVE_AGE:
			# Out of karting: everybody sees him now, the values stay unknown.
			d.series_id = POOL
			GameState.discovered[d.id] = true
			continue
		if d.age(year) <= MAX_AGE:
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
			if d and Academy.is_placed(d) and d.age(year) <= max_age(t.series_id):
				kept.append(id)
			elif d:
				d.team_id = &""
				d.series_id = POOL
		t.driver_ids = kept
		t.strength = clampi(t.strength + r.randi_range(-3, 3), 30, 75)
	_cohort(r, NEWGEN_AGE)
	# Academies place their drivers first, then the championships fill up,
	# F2 before F3: the best juniors go up as far as they can.
	Academy.ai_new_season(year, r)
	_fill(F2, year)
	_fill(F3, year)
	report.academy = Academy.new_season(GameState.player_team(), r)
	return report


## One race weekend of every junior series, same round as the F1 race.
## Every starter gets a start; the finishing place (0 = did not finish) is kept
## as the last result for the academy report.
static func resolve_round() -> void:
	if standings(F3).rounds == 0:
		Academy.check_promises(Calendar.year)
	for key in all_series():
		var entries := []
		if SERIES.has(key):
			for t in GameState.youth_teams.values():
				if t.series_id != key:
					continue
				for id in t.driver_ids:
					var d: DriverData = GameState.drivers[id]
					entries.append([d, t.id, d.overall() * 0.8 + t.strength * 0.3 + randf_range(-6.0, 6.0)])
		else:
			for d in karting():
				if KART_SERIES[Scouting.region_of(d)] == key:
					entries.append([d, &"", d.overall() * 0.8 + KART_STRENGTH * 0.3 + randf_range(-7.0, 7.0)])
		entries.sort_custom(func(a, b): return a[2] > b[2])
		var st := standings(key)
		var starts: Dictionary = st.get_or_add("starts", {})
		var last: Dictionary = st.get_or_add("last", {})
		last.clear()
		var place := 0
		var dnf := RETIRE_CHANCE if SERIES.has(key) else KART_RETIRE_CHANCE
		for e in entries:
			_add(starts, e[0].id, 1)
			_add(st.drivers, e[0].id, 0)
			if randf() < dnf:
				last[e[0].id] = 0
				continue
			place += 1
			last[e[0].id] = place
			var pts: int = POINTS[place - 1] if place <= POINTS.size() else 0
			_add(st.drivers, e[0].id, pts)
			if e[1] != &"":
				_add(st.teams, e[1], pts)
			if place == 1:
				_add(st.wins, e[0].id, 1)
		st.rounds += 1
	Scouting.after_round()
	_paddock_talk()


## Race practice of a junior this season for the winter development: the share
## of the races he started (F2 counts more than F3, karting least) and a bonus
## for points.
static func practice(d: DriverData) -> float:
	var base := PRACTICE_ACADEMY if d.academy_team_id != &"" else PRACTICE_POOL
	var best := base
	for key in all_series():
		var st := standings(key)
		var rounds: int = st.rounds
		var starts: int = st.get("starts", {}).get(d.id, 0)
		if rounds <= 0 or starts <= 0:
			continue
		var level: float = PRACTICE.get(key, PRACTICE[KARTING])
		var share := minf(1.0, float(starts) / rounds)
		var per_race: float = st.drivers.get(d.id, 0) / float(starts)
		var bonus := minf(RESULT_BONUS_MAX, per_race / 25.0 * RESULT_BONUS)
		best = maxf(best, base + (level - base) * share + bonus)
	return best


## Place of a driver in the championship of his series (0 = not in the table).
static func position(d: DriverData) -> int:
	var key := series_key(d)
	if key == &"":
		return 0
	var rows := table(key)
	for i in rows.size():
		if rows[i][0] == d.id:
			return i + 1
	return 0


## Points and wins this season in his current championship.
static func season_points(d: DriverData) -> int:
	var key := series_key(d)
	return standings(key).drivers.get(d.id, 0) if key != &"" else 0


static func season_wins(d: DriverData) -> int:
	var key := series_key(d)
	return standings(key).wins.get(d.id, 0) if key != &"" else 0


static func season_starts(d: DriverData) -> int:
	var key := series_key(d)
	return standings(key).get("starts", {}).get(d.id, 0) if key != &"" else 0


## Finishing place of the last round (0 = did not finish, -1 = did not race).
static func last_result(d: DriverData) -> int:
	var key := series_key(d)
	if key == &"":
		return -1
	return standings(key).get("last", {}).get(d.id, -1)


## The junior championships are over: history entries, super licence points,
## the season message. Called at the end of the F1 season.
static func season_end() -> void:
	var totals := {}
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Junior seasons finished"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "graduation-cap"
	for key in all_series():
		var rows := table(key)
		var st := standings(key)
		for i in rows.size():
			var id: StringName = rows[i][0]
			var d: DriverData = GameState.drivers.get(id)
			if d:
				var t := team_of(d)
				d.junior_history.append({"year": Calendar.year, "series": key, "team": t.name if t and SERIES.has(key) else "",
					"points": rows[i][1], "position": i + 1, "wins": st.wins.get(id, 0), "starts": st.get("starts", {}).get(id, 0)})
			if SERIES.has(key):
				totals[id] = totals.get(id, 0) + _licence_for(key, i)
		if rows.is_empty():
			continue
		var champion: DriverData = GameState.drivers.get(rows[0][0])
		if champion and (SERIES.has(key) or is_visible(champion)):
			msg.add_paragraph("%s champion: %s (%d points, %d rounds).",
				[series_name(key), champion.full_name(), rows[0][1], st.rounds])
		elif champion:
			msg.add_paragraph("%s: the champion is a kid our scouts have not seen yet.", [series_name(key)])
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
	msg.link_screen = &"standings"
	msg.link_args = {"tab": 2}
	msg.link_label = "Open junior tables"
	GameState.add_message(msg)


## Points over the last three seasons.
static func licence_points(d: DriverData) -> int:
	var sum := 0
	for p in d.superlicence_points:
		sum += p
	return sum


## Drivers' table of a junior championship: [[driver_id, points], ...], best
## first (more wins break a tie).
static func table(key: StringName) -> Array:
	var st := standings(key)
	var out := []
	for id in st.drivers:
		out.append([id, st.drivers[id]])
	out.sort_custom(func(a, b):
		if a[1] != b[1]:
			return a[1] > b[1]
		return st.wins.get(a[0], 0) > st.wins.get(b[0], 0))
	return out


## Teams' table of F3 or F2: [[team_id, points], ...], best first.
static func team_table(series_id: StringName) -> Array:
	var st := standings(series_id)
	var out := []
	for t in GameState.youth_teams.values():
		if t.series_id == series_id:
			out.append([t.id, st.teams.get(t.id, 0)])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out


## The results of this season of one junior championship (created on first access).
static func standings(key: StringName) -> Dictionary:
	return GameState.youth_standings.get_or_add(key, {"drivers": {}, "teams": {}, "wins": {}, "rounds": 0,
		"starts": {}, "last": {}})


static func reset_standings() -> void:
	GameState.youth_standings.clear()


# --- Helpers -----------------------------------------------------------------

## A new cohort of karting kids: a few wonderkids and late bloomers among them.
static func _cohort(r: RandomNumberGenerator, age: int) -> void:
	var kids: Array[DriverData] = []
	for i in NEWGENS_PER_YEAR:
		kids.append(_newgen(r, age))
	kids.shuffle()
	var wonder := r.randi_range(WONDERKIDS[0], WONDERKIDS[1])
	for i in wonder:
		var d := kids[i]
		d.talent = &"wonderkid"
		d.potential = r.randi_range(86, 95)
		d.development_rate = r.randf_range(1.1, 1.4)
	for i in range(wonder, wonder + LATE_BLOOMERS):
		var d := kids[i]
		d.talent = &"late_bloomer"
		for entry in DriverAttributes.DRIVING:
			d.set(entry[0], clampi(d.get(entry[0]) - r.randi_range(5, 10), 1, 100))
		d.potential = clampi(d.overall() + r.randi_range(32, 42), 0, 92)
		d.development_rate = r.randf_range(1.3, 1.5)
		d.peak_start_age = r.randi_range(27, 30)
		d.peak_end_age = d.peak_start_age + r.randi_range(5, 8)


static func _newgen(r: RandomNumberGenerator, age: int) -> DriverData:
	var d := PersonGenerator.driver(r, PersonGenerator.DriverTier.NEWGEN)
	d.birth_year = Calendar.year - age
	d.series_id = KARTING
	GameState.add_driver(d)
	GameState.knowledge[d.id] = r.randi_range(0, 10)
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
	var candidates := pool().filter(func(d): return d.age(year) <= max_age(series_id) and d.age(year) >= MIN_SEAT_AGE)
	candidates.sort_custom(func(a, b): return value(a) > value(b))
	for t in GameState.youth_teams.values():
		if t.series_id != series_id:
			continue
		while t.driver_ids.size() < SEATS and not candidates.is_empty():
			seat(candidates.pop_front(), t)


## A wonderkid with several wins this season: the paddock talks about him.
static func _paddock_talk() -> void:
	for key in all_series():
		var st := standings(key)
		for id in st.wins:
			if st.wins[id] < HYPE_WINS or GameState.junior_hype.has(id):
				continue
			var d: DriverData = GameState.drivers.get(id)
			if not d or d.talent != &"wonderkid" or not is_visible(d):
				continue
			GameState.junior_hype[id] = Calendar.year
			var msg := InboxMessage.new()
			msg.sender = "Chief scout"
			msg.icon = "binoculars"
			msg.subject = "Paddock talk: %s"
			msg.subject_args = [d.full_name()]
			msg.add_paragraph("Everyone is talking about %s (%d, %s): %d wins in %s already this season.",
				[d.full_name(), d.age(Calendar.year), d.nationality, st.wins[id], series_name(key)])
			msg.add_paragraph("Other academies will be watching too. If we want him, we should act now.")
			msg.link_screen = &"junior_profile"
			msg.link_args = {"driver_id": d.id}
			msg.link_label = "Open profile"
			GameState.add_message(msg)


static func _licence_for(series_id: StringName, position: int) -> int:
	var points: Array = LICENCE_POINTS[series_id]
	return points[position] if position < points.size() else 0


static func _add(dict: Dictionary, key: StringName, amount: int) -> void:
	dict[key] = dict.get(key, 0) + amount
