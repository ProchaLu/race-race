## Creates new fictional people: market drivers (ex-F1, F2, F3), staff for
## every role, and agents. Also builds plausible past seasons (histories).
class_name PersonGenerator
extends RefCounted

enum DriverTier { EX_F1, F2, F3 }

static var _next_id := 0


static func new_id(prefix: String) -> StringName:
	_next_id += 1
	return StringName("%s_%d_%d" % [prefix, _next_id, randi() % 100000])


# --- Drivers -----------------------------------------------------------------

static func driver(r: RandomNumberGenerator, tier: DriverTier) -> DriverData:
	var d := DriverData.new()
	d.id = new_id("gd")
	d.nationality = NameGenerator.random_nationality(r)
	var names := NameGenerator.full_name(r, d.nationality, false)
	d.first_name = names[0]
	d.last_name = names[1]
	d.number = r.randi_range(2, 99)

	var age: int
	var skill: int
	match tier:
		DriverTier.EX_F1:
			age = r.randi_range(26, 37)
			skill = r.randi_range(60, 74)
			d.series_id = &""
		DriverTier.F2:
			age = r.randi_range(19, 24)
			skill = r.randi_range(54, 68)
			d.series_id = &"f2"
		_:
			age = r.randi_range(16, 19)
			skill = r.randi_range(44, 58)
			d.series_id = &"f3"
	d.birth_year = Calendar.year - age

	for attr in DriverAttributes.DRIVING:
		d.set(attr[0], _spread(r, skill, 8))
	for attr in DriverAttributes.MENTAL:
		d.set(attr[0], _spread(r, skill - 4, 16))
	d.fitness = _spread(r, skill + 6 - maxi(0, age - 32) * 2, 6)
	d.reactions = _spread(r, skill + 4 - maxi(0, age - 30) * 2, 6)

	# Young drivers can have a lot of room to grow; some are hidden gems.
	var growth := maxi(0, 25 - age) * r.randi_range(1, 3) + r.randi_range(0, 6)
	if tier == DriverTier.F3 and r.randf() < 0.08:
		growth += 15
	d.potential = clampi(d.overall() + growth, 0, 95)
	d.peak_start_age = r.randi_range(23, 29)
	d.peak_end_age = d.peak_start_age + r.randi_range(4, 9)
	d.decline_rate = r.randf_range(0.6, 1.4)
	if r.randf() < 0.05:
		d.traits.append(&"evergreen")
		d.peak_end_age = 40
		d.decline_rate = 0.4
	for i in r.randi_range(0, 2):
		var t: StringName = TraitCatalog.DRIVER_TRAITS[r.randi() % TraitCatalog.DRIVER_TRAITS.size()]
		if not d.traits.has(t):
			d.traits.append(t)

	# Young drivers usually still need super licence points (design doc 3.9).
	d.has_superlicence = tier == DriverTier.EX_F1 or (tier == DriverTier.F2 and r.randf() < 0.5)
	d.seasons = maxi(0, age - 22) if tier == DriverTier.EX_F1 else 0
	d.races = d.seasons * 22
	d.form = r.randi_range(35, 75)
	d.confidence = r.randi_range(35, 80)
	d.match_fitness = r.randi_range(85, 100)
	d.morale_factors = {"Looking for a seat": r.randi_range(-8, 4)}
	d.recalculate_morale()
	if not GameState.agents.is_empty():
		var agent_ids := GameState.agents.keys()
		d.agent_id = agent_ids[r.randi() % agent_ids.size()]
	make_driver_history(d, r)
	return d


## Past season values. Young drivers improved a lot; with age the physical
## side declines while the mental side keeps growing.
static func make_driver_history(d: DriverData, r: RandomNumberGenerator) -> void:
	var age := d.age(Calendar.year)
	var years := clampi(age - 16, 1, 6)
	var groups := {"driving": DriverAttributes.DRIVING, "mental": DriverAttributes.MENTAL,
		"physical": DriverAttributes.PHYSICAL}
	for group in groups:
		for entry in groups[group]:
			d.attribute_history[entry[0]] = _walk_back(d.get(entry[0]), years, age, group, r)
	d.ability_history = _walk_back(d.overall(), years, age, "driving", r)


# --- Staff -------------------------------------------------------------------

## Removes earlier jobs at `team_name` (used when hiring for that team, so
## the career does not list the new team twice).
static func drop_jobs_at(person: PersonData, team_name: String) -> void:
	person.career_history.assign(person.career_history.filter(func(job): return job.team != team_name))


## quality: rough 0..100 level of the person.
static func staff(r: RandomNumberGenerator, role: StaffData.Role, quality: int) -> StaffData:
	var s := StaffData.new()
	s.id = new_id("gs")
	s.role = role
	s.nationality = NameGenerator.random_nationality(r)
	s.gender = PersonData.Gender.FEMALE if r.randf() < 0.25 else PersonData.Gender.MALE
	var names := NameGenerator.full_name(r, s.nationality, s.gender == PersonData.Gender.FEMALE)
	s.first_name = names[0]
	s.last_name = names[1]
	var age := r.randi_range(27, 62)
	s.birth_year = Calendar.year - age

	s.expertise = _spread(r, quality, 8)
	s.leadership = _spread(r, quality - 5, 14)
	s.experience = clampi(20 + (age - 25) * 2 + r.randi_range(-10, 10), 5, 100)
	s.work_ethic = _spread(r, 62, 22)
	s.adaptability = _spread(r, 58, 20)
	s.ambition = _spread(r, 58, 25)
	s.loyalty = _spread(r, 55, 25)
	s.pressure_handling = _spread(r, quality - 3, 15)
	for entry in StaffRoles.attributes_of(role):
		s.role_attributes[entry[0]] = _spread(r, quality, 10)
	for i in r.randi_range(0, 2):
		var t: StringName = TraitCatalog.STAFF_TRAITS[r.randi() % TraitCatalog.STAFF_TRAITS.size()]
		if not s.traits.has(t):
			s.traits.append(t)

	s.potential = clampi(s.overall() + floori(maxi(0, 45 - age) / 2.0) + r.randi_range(0, 5), 0, 98)
	s.job_satisfaction = r.randi_range(45, 90)
	s.workload = r.randi_range(40, 85)
	s.morale = r.randi_range(40, 80)
	_make_staff_history(s, r, age)
	return s


static func _make_staff_history(s: StaffData, r: RandomNumberGenerator, age: int) -> void:
	var years := clampi(age - 24, 1, 6)
	for entry in StaffRoles.GENERAL + StaffRoles.PERSONALITY:
		s.attribute_history[entry[0]] = _walk_back(s.get(entry[0]), years, age, "staff", r)
	for property in s.role_attributes:
		s.attribute_history[property] = _walk_back(s.role_attributes[property], years, age, "staff", r)
	s.ability_history = _walk_back(s.overall(), years, age, "staff", r)

	# Career: a few earlier jobs at other teams.
	var team_names: Array = []
	for team in GameState.teams.values():
		team_names.append(team.name)
	var year := Calendar.year - r.randi_range(1, 4)
	var jobs := r.randi_range(1, 3)
	var history: Array[Dictionary] = []
	for i in jobs:
		var length := r.randi_range(2, 5)
		var team_name: String = team_names[r.randi() % team_names.size()] if not team_names.is_empty() else "Formula Apex"
		history.push_front({"from": year - length, "to": year - 1, "team": team_name,
			"role": StaffRoles.name_of(s.role) if i == 0 else "Engineer"})
		year -= length
	s.career_history = history


# --- Agents ------------------------------------------------------------------

static func agent(r: RandomNumberGenerator) -> AgentData:
	var a := AgentData.new()
	a.id = new_id("ag")
	a.nationality = NameGenerator.random_nationality(r)
	a.gender = PersonData.Gender.FEMALE if r.randf() < 0.35 else PersonData.Gender.MALE
	var names := NameGenerator.full_name(r, a.nationality, a.gender == PersonData.Gender.FEMALE)
	a.first_name = names[0]
	a.last_name = names[1]
	a.birth_year = Calendar.year - r.randi_range(35, 64)
	a.style = r.randi() % AgentData.Style.size() as AgentData.Style
	a.patience = r.randi_range(3, 5)
	return a


# --- Helpers -----------------------------------------------------------------

## Builds a value history ending in `current`, going back one season at a time.
static func _walk_back(current: int, years: int, age: int, group: String, r: RandomNumberGenerator) -> Array[int]:
	var history: Array[int] = [current]
	var value := current
	for years_ago in range(1, years):
		value -= _yearly_change(group, age - years_ago + 1) + r.randi_range(-1, 1)
		history.push_front(clampi(value, 0, 100))
	return history


## Typical change during the season in which a person turned `age`.
static func _yearly_change(group: String, age: int) -> int:
	match group:
		"physical":
			return 2 if age < 25 else (0 if age < 31 else -2)
		"mental":
			return 2 if age < 30 else 1
		"staff":
			return 2 if age < 40 else (1 if age < 55 else -1)
	return 3 if age < 25 else (1 if age < 31 else 0)


static func _spread(r: RandomNumberGenerator, base: int, amount: int) -> int:
	return clampi(base + r.randi_range(-amount, amount), 1, 100)
