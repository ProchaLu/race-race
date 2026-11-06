## Winter changes between two seasons (design doc 3.2/3.3, sim doc 13):
## every driver and staff member moves along his hidden age curve, the
## season goes into the career records, old people retire, and every car
## changes a little (placeholder until car development comes in R3).
## Returns a report for the new-season message.
class_name Development
extends RefCounted

## Overall points a young driver gains per winter, as a share of the gap to his potential.
const GROWTH_SHARE := 0.3
## A driver is old enough to think about retiring from this age.
const RETIRE_AGE := 35
const STAFF_RETIRE_AGE := 63
## The market keeps at most this many free agents; the weakest leave the sport.
const MARKET_DRIVERS := 45
const MARKET_STAFF := 100
const TECH_ROLES := [StaffData.Role.TECHNICAL_DIRECTOR, StaffData.Role.CHIEF_DESIGNER,
	StaffData.Role.HEAD_OF_AERO, StaffData.Role.HEAD_OF_CHASSIS]


## Runs before the statistics of the old season are cleared.
## Report: own drivers and staff before/after, the player's car per rating,
## the biggest risers and fallers of the grid.
static func winter(year: int, r: RandomNumberGenerator) -> Dictionary:
	var report := {"drivers": [], "staff": [], "cars": {}, "car_detail": {}, "risers": [], "fallers": []}
	_career_records()
	var grid := []
	for d: DriverData in GameState.drivers.values():
		if d.retired:
			continue
		var before := d.overall()
		_develop_driver(d, year, r)
		var team: TeamData = GameState.teams.get(d.team_id)
		if d.team_id == GameState.player_team_id:
			report.drivers.append({"id": d.id, "name": d.full_name(), "age": d.age(year), "before": before,
				"after": d.overall(), "changes": d.attribute_changes.duplicate()})
		if team and team.driver_ids.has(d.id):
			grid.append([d.full_name(), team.short_name, before, d.overall()])
	grid.sort_custom(func(a, b): return a[3] - a[2] > b[3] - b[2])
	report.risers = grid.slice(0, 5).filter(func(e): return e[3] > e[2])
	var falling := grid.filter(func(e): return e[3] < e[2])
	falling.reverse()
	report.fallers = falling.slice(0, 5)
	for s: StaffData in GameState.staff.values():
		if s.retired:
			continue
		var before := s.overall()
		_develop_staff(s, year, r)
		if s.team_id == GameState.player_team_id:
			report.staff.append({"id": s.id, "name": s.full_name(), "role": StaffRoles.name_of(s.role), "before": before, "after": s.overall()})
	var player_car: CarData = GameState.player_team().car
	var car_before := _car_values(player_car)
	report.cars = CarBuild.new_season(year, r)
	for team in GameState.teams.values():
		if not team.car.has_parts():
			report.cars[team.id] = _new_car(team, year, r)
	var car_after := _car_values(player_car)
	for k in car_before:
		report.car_detail[k] = [car_before[k], car_after[k]]
	return report


const CAR_RATINGS := [[&"downforce", "Downforce"], [&"drag_efficiency", "Drag efficiency"], [&"engine_power", "Engine power"],
	[&"mechanical_grip", "Mechanical grip"], [&"braking", "Braking"], [&"traction", "Traction"],
	[&"tyre_preservation", "Tyre preservation"], [&"cooling", "Cooling"], [&"reliability", "Reliability"]]


static func _car_values(car: CarData) -> Dictionary:
	var values := CarBuild.snapshot(car)
	var out := {}
	for entry in CAR_RATINGS:
		out[entry[1]] = roundi(values.get(entry[0], car.get(entry[0])))
	return out


## Retirements: people without a contract after the old ones expired.
## Call after the contracts ended. Returns "Name (age)" texts.
static func retirements(year: int, r: RandomNumberGenerator) -> Array:
	var out := []
	for d: DriverData in GameState.drivers.values():
		if d.retired or d.team_id != &"" or GameState.shortlist.has(d.id):
			continue
		var age := d.age(year)
		var chance := 0.0
		if age >= RETIRE_AGE:
			chance = (age - RETIRE_AGE + 1) * 0.2
			if d.traits.has(&"evergreen"):
				chance *= 0.5
		elif age > 28 and d.overall() < 55:
			chance = 0.3
		if chance > 0.0 and r.randf() < chance:
			d.retired = true
			if d.seasons > 0 and d.races >= 22:
				out.append("%s (%d)" % [d.full_name(), age])
	for s: StaffData in GameState.staff.values():
		if s.retired or s.team_id != &"":
			continue
		var age := s.age(year)
		if age >= STAFF_RETIRE_AGE and r.randf() < (age - STAFF_RETIRE_AGE + 1) * 0.25:
			s.retired = true
	_trim_market(GameState.free_drivers(), MARKET_DRIVERS, year)
	_trim_market(GameState.free_staff(), MARKET_STAFF, year)
	return out


## Too many free agents: the weakest and oldest find other jobs. Talents
## and people on the shortlist stay.
static func _trim_market(people: Array, limit: int, year: int) -> void:
	var candidates := people.filter(func(p): return not GameState.shortlist.has(p.id) \
		and not (p is DriverData and p.age(year) <= 21 and p.potential >= 70))
	candidates.sort_custom(func(a, b): return a.overall() - a.age(year) * 0.3 < b.overall() - b.age(year) * 0.3)
	var extra := people.size() - limit
	for i in mini(extra, candidates.size()):
		candidates[i].retired = true


# --- Career records ----------------------------------------------------------

static func _career_records() -> void:
	var champion: StringName = &""
	var best := -1
	for id in GameState.season_stats:
		var st: DriverSeasonStats = GameState.season_stats[id]
		var d: DriverData = GameState.drivers.get(id)
		if not d or st.races() == 0:
			continue
		d.wins += st.wins
		d.podiums += st.podiums
		d.poles += st.poles
		d.seasons += 1
		if st.points > best:
			best = st.points
			champion = id
	if champion != &"":
		GameState.drivers[champion].championships += 1


# --- Drivers -----------------------------------------------------------------

static func _develop_driver(d: DriverData, year: int, r: RandomNumberGenerator) -> void:
	var age := d.age(year)
	var old := {}
	for group in [DriverAttributes.DRIVING, DriverAttributes.MENTAL, DriverAttributes.PHYSICAL]:
		for entry in group:
			old[entry[0]] = d.get(entry[0])

	if age < d.peak_start_age:
		# Growing towards the potential: work ethic, race practice and morale help.
		var gap := maxi(0, d.potential - d.overall())
		var practice := _practice(d)
		var drive := (0.6 + d.work_ethic / 100.0 * 0.6) * d.development_rate * practice * (0.8 + d.morale / 250.0)
		var gain := gap * GROWTH_SHARE * drive + r.randfn(0.0, 0.8)
		for entry in DriverAttributes.DRIVING:
			_add(d, entry[0], roundi(gain * r.randf_range(0.5, 1.5)))
		for entry in DriverAttributes.MENTAL:
			_add(d, entry[0], r.randi_range(0, 2))
		for entry in DriverAttributes.PHYSICAL:
			_add(d, entry[0], r.randi_range(0, 2) if age < 24 else r.randi_range(-1, 1))
		# Never beyond the hidden potential.
		var guard := 0
		while d.overall() > d.potential and guard < 200:
			guard += 1
			var entry: Array = DriverAttributes.DRIVING[r.randi() % DriverAttributes.DRIVING.size()]
			_add(d, entry[0], -1)
	elif age <= d.peak_end_age:
		# Peak years: small ups and downs, experience still grows.
		var room := d.potential - d.overall()
		for entry in DriverAttributes.DRIVING:
			_add(d, entry[0], r.randi_range(-1, 1) + (1 if room > 0 and r.randf() < 0.3 else 0))
		for entry in DriverAttributes.MENTAL:
			_add(d, entry[0], r.randi_range(0, 1))
		for entry in DriverAttributes.PHYSICAL:
			_add(d, entry[0], r.randi_range(-1, 0) if age >= 30 else r.randi_range(-1, 1))
	else:
		# Decline: the body first, then the driving; the head keeps learning.
		var k := d.decline_rate * minf(age - d.peak_end_age, 5) / 2.5
		for entry in DriverAttributes.PHYSICAL:
			_add(d, entry[0], -roundi(r.randf_range(1.0, 3.0) * k))
		for entry in DriverAttributes.DRIVING:
			_add(d, entry[0], -roundi(r.randf_range(0.0, 1.5) * k))
		for entry in DriverAttributes.MENTAL:
			_add(d, entry[0], r.randi_range(0, 1))

	d.attribute_changes = {}
	for property in old:
		var delta: int = d.get(property) - old[property]
		if delta != 0:
			d.attribute_changes[property] = delta
		var history: Array = d.attribute_history.get(property, [old[property]])
		history.append(d.get(property))
		d.attribute_history[property] = history
	d.ability_history.append(d.overall())


## Race drivers learn most, reserve drivers some, free agents little.
static func _practice(d: DriverData) -> float:
	# Juniors: races in F3/F2 this season and their results (Youth.practice).
	if Youth.is_youth(d):
		return Youth.practice(d)
	var team: TeamData = GameState.teams.get(d.team_id)
	if team and team.driver_ids.has(d.id):
		return 1.0
	if team:
		return 0.7
	return 0.45


static func _add(person: PersonData, property: StringName, delta: int) -> void:
	if delta != 0:
		person.set(property, clampi(person.get(property) + delta, 1, 100))


# --- Staff -------------------------------------------------------------------

static func _develop_staff(s: StaffData, year: int, r: RandomNumberGenerator) -> void:
	var age := s.age(year)
	var change := 0
	if age < 40:
		change = roundi(maxi(0, s.potential - s.overall()) * 0.25 * (0.6 + s.work_ethic / 100.0 * 0.6))
	elif age < 56:
		change = r.randi_range(0, 1)
	elif age >= 60:
		change = -r.randi_range(0, 2)
	for property in s.role_attributes.keys():
		var before: int = s.role_attributes[property]
		var value := clampi(before + change + r.randi_range(-1, 1), 1, 100)
		s.role_attributes[property] = value
		var history: Array = s.attribute_history.get(property, [before])
		history.append(value)
		s.attribute_history[property] = history
	s.experience = clampi(s.experience + r.randi_range(1, 2), 1, 100)
	if age < 40:
		s.expertise = clampi(s.expertise + r.randi_range(0, 2), 1, 100)
	s.ability_history.append(s.overall())


# --- Cars --------------------------------------------------------------------

## Cars without parts only (sim lab): the new car is a little better or worse, depending on
## the technical staff and the budget; strong cars find less to gain.
## Returns [old average, new average].
static func _new_car(team: TeamData, year: int, r: RandomNumberGenerator) -> Array:
	var car := team.car
	var tech := 0.0
	var count := 0
	var engine := 60.0
	for s in GameState.staff_of_team(team.id):
		if s.role in TECH_ROLES:
			tech += s.overall()
			count += 1
		elif s.role == StaffData.Role.ENGINE_CHIEF:
			engine = s.overall()
	tech = tech / count if count > 0 else 55.0
	# Money matters, but budgets are not balanced yet (R6): small effect only.
	var money := clampf(team.budget / 200_000_000.0, 0.75, 1.25)
	var before := (car.downforce + car.drag_efficiency + car.engine_power + car.mechanical_grip) / 4.0
	for property in [&"downforce", &"drag_efficiency", &"mechanical_grip", &"tyre_preservation", &"engine_power"]:
		var value: int = car.get(property)
		var staff_bonus := (engine if property == &"engine_power" else tech) - 60.0
		var delta := r.randi_range(-4, 3) + roundi(staff_bonus / 12.0) + roundi((money - 1.0) * 2.0) \
			+ roundi((66 - value) * 0.15)
		car.set(property, clampi(value + delta, 35, 95))
	car.reliability = clampi(car.reliability + r.randi_range(-3, 3), 50, 95)
	car.season = year
	var after := (car.downforce + car.drag_efficiency + car.engine_power + car.mechanical_grip) / 4.0
	return [before, after]
