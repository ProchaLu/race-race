## Car development of every team – the development lab (docs/car_model.md
## 3a, 4, 9–11). A project starts from the old part: the design office has
## ideas, CFD / simulation measures them roughly, the wind tunnel / rigs
## precisely (combine, refine), a variant is frozen, detailed, tooled and
## built. The team principal decides at milestones; AI teams – and the
## player's team while delegated – decide by the same rules automatically.
## Capacity comes from the key staff, the facilities and the size of every
## department (more money = more people).
class_name CarDevelopment
extends RefCounted

## [idea size, dead-end chance, cost] per DevProject.Ambition.
const AMBITION := [[0.6, 0.10, 1.0], [1.0, 0.22, 1.0], [1.6, 0.35, 1.3]]
const PRIORITY_SHARE := [1.0, 2.0, 3.0]
## Lost capacity per extra project in the same department.
const FRICTION := 0.08
## Projects an average department handles at full speed; one project alone
## never runs faster than its normal pace (1 day per day).
const DEPARTMENT_SIZE := {&"design": 2.5, &"aero": 2.0, &"tunnel": 1.6, &"rig": 2.0, &"factory": 3.0}
## Headcount of an average team; more people = more capacity (not linear).
const REFERENCE_HEADCOUNT := {&"design": 60, &"aero": 80, &"rig": 30, &"factory": 120}
const HEADCOUNT_EXPONENT := 0.75
const PROJECT_MAX_RATE := 1.0
const OVERTIME_SPEED := 1.4
const OVERTIME_COST := 1.5
## Work per variant: CFD / simulation and wind tunnel / rig (days).
const CFD_DAYS := 2.0
const TUNNEL_DAYS := 3.5
const QUALITY_DAYS := 2.0
## Calendar days for moulds and tooling once a design is frozen.
const TOOLING_DAYS := {&"front_wing": 6, &"rear_wing": 5, &"floor": 10, &"diffuser": 6, &"sidepods": 7,
	&"engine_cover": 4, &"monocoque": 20, &"suspension_front": 8, &"suspension_rear": 8, &"brakes": 5,
	&"gearbox": 14, &"cooling": 6, &"exhaust": 4}
## Costs per variant (aero / mechanical) for CFD and the wind tunnel / rigs.
const CFD_COST := [40_000, 25_000]
const TUNNEL_COST := [110_000, 60_000]
## Idea gain relative to the old fixed-goal project, and refinement steps.
const IDEA_SHARE := 0.55
const REFINE_GAIN := 0.15
## Typical result of a project (best variant, maybe combined) relative to
## the old fixed-goal step – the target shown before the ideas exist.
const TARGET_SHARE := 0.75
const STAFF_DEFAULT := 45
## AI teams keep this many months of salaries in the bank.
const RESERVE_MONTHS := 4
const DEPARTMENT_NAMES := {&"design": "Design", &"aero": "CFD / simulation", &"tunnel": "Wind tunnel",
	&"rig": "Test rigs", &"factory": "Factory"}


# --- Departments -------------------------------------------------------------

## Headcount from the budget (until hiring comes with R4/R6): a team with
## twice the money has about 1.7× the people.
## Capped by the room the HQ buildings offer (Facilities.room_for).
static func set_departments(team: TeamData) -> void:
	var money := clampf(team.budget / 200_000_000.0, 0.5, 1.8)
	for d in REFERENCE_HEADCOUNT:
		team.departments[d] = mini(roundi(REFERENCE_HEADCOUNT[d] * pow(money, 0.8)), Facilities.room_for(team, d))


static func headcount(team: TeamData, d: StringName) -> int:
	if d == &"tunnel":
		d = &"aero"
	if team.departments.is_empty():
		set_departments(team)
	return team.departments.get(d, REFERENCE_HEADCOUNT.get(d, 60))


# --- Capacity ----------------------------------------------------------------

## Days of work per calendar day for each department (docs/car_model.md 4).
static func capacities(team: TeamData) -> Dictionary:
	var td := _attr(team, StaffData.Role.TECHNICAL_DIRECTOR, &"organisation")
	var speed := _attr(team, StaffData.Role.CHIEF_DESIGNER, &"design_speed")
	var aero := _attr(team, StaffData.Role.HEAD_OF_AERO, &"aero_knowledge")
	var mech := _attr(team, StaffData.Role.HEAD_OF_CHASSIS, &"mechanical_knowledge")
	var factory := _attr(team, StaffData.Role.FACTORY_MANAGER, &"production_speed")
	var mood := 1.0 + (TeamMood.value(team.id) - 50) / 50.0 * 0.05
	var staff := {
		&"design": (0.6 * speed + 0.4 * td) / 65.0 * Facilities.capacity_factor(team, &"design"),
		&"aero": aero / 65.0 * Facilities.capacity_factor(team, &"aero"),
		&"tunnel": aero / 65.0 * Facilities.capacity_factor(team, &"tunnel"),
		&"rig": mech / 65.0 * Facilities.capacity_factor(team, &"rig"),
		&"factory": factory / 65.0 * Facilities.capacity_factor(team, &"factory"),
	}
	var people_of := {&"design": &"design", &"aero": &"aero", &"tunnel": &"aero", &"rig": &"rig", &"factory": &"factory"}
	var out := {}
	for d in staff:
		var key: StringName = people_of[d]
		var exponent := HEADCOUNT_EXPONENT if d != &"tunnel" else 0.3
		var people := pow(headcount(team, key) / float(REFERENCE_HEADCOUNT[key]), exponent)
		out[d] = DEPARTMENT_SIZE[d] * staff[d] * people * mood
	return out


static func max_projects(team: TeamData) -> int:
	return Facilities.max_projects(team)


static func _attr(team: TeamData, role: StaffData.Role, property: StringName) -> int:
	for s in GameState.staff_of_team(team.id):
		if s.role == role:
			return s.attribute(property)
	return STAFF_DEFAULT


static func projects_of(team_id: StringName) -> Array[DevProject]:
	var out: Array[DevProject] = []
	for p in GameState.car_projects:
		if p.team_id == team_id:
			out.append(p)
	return out


## Development projects (no spare orders), for the slot limit.
static func design_projects(team_id: StringName) -> Array[DevProject]:
	var out: Array[DevProject] = []
	for p in projects_of(team_id):
		if not p.is_spares():
			out.append(p)
	return out


## Projects waiting for a decision of the team principal.
static func waiting(team_id: StringName) -> Array[DevProject]:
	var out: Array[DevProject] = []
	for p in projects_of(team_id):
		if p.milestone != DevProject.Milestone.NONE:
			out.append(p)
	return out


## Rate (days of work per day) each running project gets right now. The
## next-season share of every department works only on next-year projects.
static func shares(team: TeamData) -> Dictionary:
	var caps := capacities(team)
	var groups := {}
	for p in projects_of(team.id):
		var d := p.department()
		if p.waiting_for_money or d == &"":
			continue
		var key := "%s|%s" % [d, p.next_year]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(p)
	var out := {}
	for key in groups:
		var parts: PackedStringArray = key.split("|")
		var d := StringName(parts[0])
		var next := parts[1] == "true"
		var other := "%s|%s" % [d, not next]
		var share := team.next_year_share if next else 1.0 - team.next_year_share
		if not groups.has(other):
			share = 1.0
		_fill(groups[key], caps[d] * share, out)
	return out


## Shares the capacity by priority; a project that cannot use more passes
## the rest on.
static func _fill(list: Array, capacity: float, out: Dictionary) -> void:
	var available := capacity / (1.0 + FRICTION * (list.size() - 1))
	var open := list.duplicate()
	while not open.is_empty() and available > 0.0001:
		var total := 0.0
		for p in open:
			total += PRIORITY_SHARE[p.priority]
		var capped := []
		var given := 0.0
		for p in open:
			var limit: float = PROJECT_MAX_RATE * (OVERTIME_SPEED if p.overtime else 1.0)
			var rate: float = minf(available * PRIORITY_SHARE[p.priority] / total, limit - out.get(p, 0.0))
			out[p] = out.get(p, 0.0) + rate
			given += rate
			if out[p] >= limit - 0.0001:
				capped.append(p)
		available -= given
		if capped.is_empty():
			break
		for p in capped:
			open.erase(p)


## How busy each department is: {department: [projects, capacity]}.
static func department_load(team: TeamData) -> Dictionary:
	var caps := capacities(team)
	var out := {}
	for d in caps:
		out[d] = [0, caps[d]]
	for p in projects_of(team.id):
		var d := p.department()
		if out.has(d):
			out[d][0] += 1
	return out


# --- Skill, gains, costs -----------------------------------------------------

## Team skill for a part (0.5 .. 1.6): technical director, the specialist and
## the chief designer.
static func skill(team: TeamData, part_id: StringName, goal: String) -> float:
	var td := _attr(team, StaffData.Role.TECHNICAL_DIRECTOR, &"innovation")
	var cd := _attr(team, StaffData.Role.CHIEF_DESIGNER, &"creativity")
	var specialist := _attr(team, StaffData.Role.HEAD_OF_AERO, &"aero_knowledge") if CarParts.test_kind(part_id) == "aero" \
		else _attr(team, StaffData.Role.HEAD_OF_CHASSIS, &"mechanical_knowledge")
	if goal == "power" or part_id == &"cooling":
		specialist = (specialist + _attr(team, StaffData.Role.ENGINE_CHIEF, &"power_development")) / 2
	if goal == "weight":
		specialist = (specialist + _attr(team, StaffData.Role.HEAD_OF_CHASSIS, &"weight_saving")) / 2
	return clampf((td + cd + specialist) / 3.0 / 65.0, 0.5, 1.6)


## How far a wind tunnel / rig measurement can be off (0 = exact). Every
## correlated part teaches the team a little (experience).
static func correlation_error(team: TeamData, part_id: StringName) -> float:
	var aero := CarParts.test_kind(part_id) == "aero"
	var base: float
	if aero:
		base = 0.45 * (1.0 - _attr(team, StaffData.Role.HEAD_OF_AERO, &"correlation") / 100.0) * Facilities.correlation_factor(team, true)
	else:
		base = 0.30 * (1.0 - _attr(team, StaffData.Role.HEAD_OF_CHASSIS, &"mechanical_knowledge") / 100.0) * Facilities.correlation_factor(team, false)
	var learned: int = GameState.correlation_experience.get("%s|%s" % [team.id, "aero" if aero else "rig"], 0)
	return base * maxf(0.6, 1.0 - 0.04 * learned)


## CFD / simulation is much rougher than the wind tunnel.
static func cfd_error(team: TeamData, part_id: StringName) -> float:
	return 0.35 + correlation_error(team, part_id) * 1.5


static func goal_value(goal: String) -> StringName:
	for key in CarParts.GOALS[goal][2]:
		if CarParts.GOALS[goal][2][key] > 0.0:
			return key
	return &"mass"


## Expected gain of a fixed-goal step in part points before luck (planning
## and the AI): base × skill × ambition × room left.
static func expected_gain(team: TeamData, part_id: StringName, goal: String, ambition: int) -> float:
	var part: PartVersion = team.car.parts.get(part_id)
	var key := goal_value(goal)
	var current := part.value(key) if part and key != &"mass" else 50.0
	current += team.next_year_parts.get(part_id, {}).get(key, 0.0)
	var room := clampf((100.0 - current) / 40.0, 0.25, 1.5)
	return CarParts.PARTS[part_id][6] * skill(team, part_id, goal) * AMBITION[ambition][0] * room


static func dead_end_chance(team: TeamData, ambition: int) -> float:
	var detail := _attr(team, StaffData.Role.CHIEF_DESIGNER, &"detail_work")
	return AMBITION[ambition][1] * (1.3 - detail / 100.0 * 0.6)


static func design_cost(team: TeamData, part_id: StringName, ambition: int, overtime: bool) -> int:
	return int(CarParts.PARTS[part_id][5][0] * AMBITION[ambition][2] * (OVERTIME_COST if overtime else 1.0))


static func unit_cost(team: TeamData, part_id: StringName) -> int:
	var control := _attr(team, StaffData.Role.FACTORY_MANAGER, &"cost_control")
	return int(CarParts.PARTS[part_id][5][1] * (1.0 - control / 100.0 * 0.15) * Facilities.unit_cost_factor(team))


static func _aero(part_id: StringName) -> int:
	return 0 if CarParts.test_kind(part_id) == "aero" else 1


## Value changes of a part for a gain in points in a direction.
## With a team, the composites department scales the weight saved.
static func _effects(part_id: StringName, goal: String, gain: float, team: TeamData = null) -> Dictionary:
	var out := {}
	var values := CarParts.values_of(part_id)
	var effects: Dictionary = CarParts.GOALS[goal][2]
	for key in effects:
		if key == &"mass" or values.has(key):
			out[key] = gain * effects[key]
	if team and out.get(&"mass", 0.0) < 0.0:
		out[&"mass"] *= Facilities.weight_saving(team)
	return out


static func _add_fx(a: Dictionary, b: Dictionary, factor: float = 1.0) -> Dictionary:
	var out := a.duplicate()
	for key in b:
		out[key] = out.get(key, 0.0) + b[key] * factor
	return out


# --- Planning and starting ---------------------------------------------------

## A new project: the ideas (and their hidden effects) are rolled now and
## shown when the concept phase is done. goal = preferred direction.
static func plan(team: TeamData, part_id: StringName, goal: String, ambition: int, priority: int,
		units: int, overtime: bool, r: RandomNumberGenerator, next_year: bool = false) -> DevProject:
	var p := DevProject.new()
	p.team_id = team.id
	p.part_id = part_id
	p.goal = goal
	p.ambition = ambition as DevProject.Ambition
	p.priority = priority as DevProject.Priority
	p.next_year = next_year
	p.units = 0 if next_year else units
	p.overtime = overtime
	p.unit_work = CarParts.PARTS[part_id][4][3]
	p.unit_cost = unit_cost(team, part_id)
	_set_work(p, CarParts.PARTS[part_id][4][0] + 2.0)
	_make_ideas(team, p, r)
	return p


## 3–6 ideas: more with good staff and many designers. Each has a hidden
## effect; some are dead ends.
static func _make_ideas(team: TeamData, p: DevProject, r: RandomNumberGenerator) -> void:
	var sk := skill(team, p.part_id, p.goal)
	var heads := headcount(team, &"design") / float(REFERENCE_HEADCOUNT[&"design"])
	var count := clampi(3 + roundi((sk - 0.9) * 4.0 + (heads - 1.0) * 2.0) + r.randi_range(0, 1), 3, 6)
	var pool: Array = CarParts.IDEAS[p.part_id].duplicate()
	pool.shuffle()
	# The preferred direction comes first.
	pool.sort_custom(func(a, b): return a[1] == p.goal and b[1] != p.goal)
	var keys := "ABCDEF"
	for i in mini(count, pool.size()):
		var entry: Array = pool[i]
		var base := expected_gain(team, p.part_id, entry[1], p.ambition) * IDEA_SHARE
		var gain := base * maxf(0.05, 1.0 + r.randfn(0.0, 0.55))
		if r.randf() < dead_end_chance(team, p.ambition):
			gain = -r.randf_range(0.1, 0.6) * base
		p.ideas.append({"key": keys[i], "name": entry[0], "goal": entry[1], "complexity": r.randi_range(1, 3),
			"real": _effects(p.part_id, entry[1], gain, team)})


static func _set_work(p: DevProject, days: float) -> void:
	p.work_left = days
	p.phase_total = maxf(days, 0.01)


## Reason why the project cannot start, or "".
static func cannot_start(team: TeamData, p: DevProject) -> String:
	if design_projects(team.id).size() >= max_projects(team):
		return "All design slots are busy."
	for other in design_projects(team.id):
		if other.part_id == p.part_id and other.next_year == p.next_year:
			return "This part is already in development."
	if not CarParts.in_season(p.part_id) and not p.next_year:
		return "The monocoque can only be developed for next season's car."
	if not p.next_year and GameState.next_round_index() < 0:
		return "The season is over – develop for next season's car."
	if team.budget < _concept_cost(team, p):
		return "Not enough budget."
	return ""


static func _concept_cost(team: TeamData, p: DevProject) -> int:
	return int(design_cost(team, p.part_id, p.ambition, p.overtime) * 0.15)


## Starts a project and pays the concept. Returns "" or the reason.
static func start(team: TeamData, p: DevProject) -> String:
	var reason := cannot_start(team, p)
	if reason != "":
		return reason
	var cost := _concept_cost(team, p)
	_pay(team, cost)
	p.cost_spent = cost
	_add(p)
	return ""


static func _add(p: DevProject) -> void:
	p.id = GameState.next_project_id
	GameState.next_project_id += 1
	p.started_day = Calendar.day
	p.started_year = Calendar.year
	GameState.car_projects.append(p)


## Stops a project. Money already spent is lost.
static func cancel(p: DevProject) -> void:
	GameState.car_projects.erase(p)


static func _pay(team: TeamData, amount: int) -> void:
	team.budget -= amount
	GameState.car_spending[team.id] = GameState.car_spending.get(team.id, 0) + amount
	EventBus.budget_changed.emit(team.id, team.budget)


# --- Milestones --------------------------------------------------------------

## How many variants fit into one CFD / tunnel batch.
static func batch_size(team: TeamData) -> int:
	return clampi(2 + roundi(capacities(team)[&"aero"]), 3, 5)


static func cfd_cost(p: DevProject, n: int) -> int:
	return CFD_COST[_aero(p.part_id)] * n


static func tunnel_cost(p: DevProject, n: int) -> int:
	return TUNNEL_COST[_aero(p.part_id)] * n


## Milestone 1: the chosen ideas go into CFD / simulation.
static func pick_cfd(team: TeamData, p: DevProject, keys: Array) -> String:
	if keys.is_empty():
		return "Pick at least one idea."
	keys = keys.slice(0, batch_size(team))
	var cost := cfd_cost(p, keys.size())
	if team.budget < cost:
		return "Not enough budget."
	_pay(team, cost)
	p.cost_spent += cost
	for k in keys:
		var i := p.idea(k)
		p.variants.append({"key": k, "members": [k], "real": i.real.duplicate(), "cfd": {}, "tunnel": {}, "rounds": 0,
			"cfd_pick": true, "tunnel_pick": false})
	p.milestone = DevProject.Milestone.NONE
	p.phase = DevProject.Phase.CFD
	_set_work(p, CFD_DAYS * keys.size())
	return ""


## A combination of measured ideas. The real effect is the sum times a
## hidden interaction (0.7 .. 1.2); its CFD estimate is the sum of the parts.
static func combine(p: DevProject, keys: Array) -> Dictionary:
	keys = keys.duplicate()
	keys.sort()
	var key := "+".join(keys)
	if not p.variant(key).is_empty() or keys.size() < 2:
		return p.variant(key)
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d|%s" % [p.id, key])
	var factor := r.randf_range(0.7, 1.2)
	var real := {}
	var cfd := {}
	for k in keys:
		var v := p.variant(k)
		real = _add_fx(real, v.real)
		for value in v.cfd:
			var c: Array = cfd.get(value, [0.0, 0.0])
			cfd[value] = [c[0] + v.cfd[value][0], sqrt(c[1] * c[1] + v.cfd[value][1] * v.cfd[value][1])]
	for value in real:
		real[value] *= factor
	var combo := {"key": key, "members": keys, "real": real, "cfd": cfd, "tunnel": {}, "rounds": 0,
		"cfd_pick": false, "tunnel_pick": false}
	p.variants.append(combo)
	return combo


## Milestone 2: variants (ideas or combinations) go into the wind tunnel / rigs.
static func pick_tunnel(team: TeamData, p: DevProject, keys: Array) -> String:
	if keys.is_empty():
		return "Pick at least one variant."
	keys = keys.slice(0, batch_size(team))
	var cost := tunnel_cost(p, keys.size())
	if team.budget < cost:
		return "Not enough budget."
	_pay(team, cost)
	p.cost_spent += cost
	for v in p.variants:
		v.tunnel_pick = keys.has(v.key)
	p.milestone = DevProject.Milestone.NONE
	p.phase = DevProject.Phase.TUNNEL
	_set_work(p, TUNNEL_DAYS * keys.size())
	return ""


## Milestone 3: one more wind tunnel round on a variant – a bit more gain
## (less every round) and a more precise number.
static func refine(team: TeamData, p: DevProject, key: String) -> String:
	var v := p.variant(key)
	if v.is_empty() or v.tunnel.is_empty():
		return "Measure the variant in the wind tunnel first."
	var cost := tunnel_cost(p, 1)
	if team.budget < cost:
		return "Not enough budget."
	_pay(team, cost)
	p.cost_spent += cost
	v.rounds += 1
	var step: float = REFINE_GAIN / v.rounds
	for value in v.real:
		v.real[value] *= 1.0 + step
	for other in p.variants:
		other.tunnel_pick = other.key == key
	p.milestone = DevProject.Milestone.NONE
	p.phase = DevProject.Phase.TUNNEL
	_set_work(p, TUNNEL_DAYS)
	return ""


## Milestone 3: the design is frozen; detail design, tooling and production follow.
static func freeze(team: TeamData, p: DevProject, key: String) -> String:
	var v := p.variant(key)
	if v.is_empty() or v.tunnel.is_empty():
		return "Measure the variant in the wind tunnel first."
	var detail := int(design_cost(team, p.part_id, p.ambition, p.overtime) * 0.45)
	var tooling := 0 if p.next_year else unit_cost(team, p.part_id) * 2
	if team.budget < detail + tooling:
		return "Not enough budget."
	_pay(team, detail + tooling)
	p.cost_spent += detail + tooling
	p.chosen = key
	p.delta = v.real.duplicate()
	p.forecast = {}
	for value in v.tunnel:
		p.forecast[value] = v.tunnel[value][0]
	p.goal = p.idea(v.members[0]).goal
	var mass := GameState.teams[p.team_id].car.mass_kg
	p.real_s = CarBuild.lap_effect(p.part_id, p.delta, mass)
	p.forecast_s = CarBuild.lap_effect(p.part_id, p.forecast, mass)
	var complexity := 0.0
	for m in v.members:
		complexity += p.idea(m).complexity
	p.milestone = DevProject.Milestone.NONE
	p.phase = DevProject.Phase.DETAIL
	_set_work(p, CarParts.PARTS[p.part_id][4][1] * (0.25 + 0.12 * complexity))
	return ""


## The value a variant is judged by: measured lap time, or the main value.
static func variant_score(p: DevProject, v: Dictionary, source: String) -> float:
	var est := {}
	for value in v[source]:
		est[value] = v[source][value][0]
	var s := -CarBuild.lap_effect(p.part_id, est)
	return s + est.get(&"reliability", 0.0) * 0.003 + est.get(&"cooling", 0.0) * 0.003 + est.get(&"tyre_preservation", 0.0) * 0.0015


## A measurement for the screens: [gain, ±, unit] – gain in seconds per lap
## (positive = faster), or in points of the main value for directions that
## do not change the lap time (reliability, cooling, tyres).
static func measured(p: DevProject, v: Dictionary, source: String) -> Array:
	var m: Dictionary = v.get(source, {})
	if m.is_empty():
		return []
	var est := {}
	var unc := 0.0
	for value in m:
		est[value] = m[value][0]
		unc += absf(CarBuild.lap_effect(p.part_id, {value: m[value][1]}))
	var s := -CarBuild.lap_effect(p.part_id, est)
	if absf(s) >= 0.0005 or unc >= 0.0005:
		return [s, unc, "s"]
	var key := goal_value(p.idea(v.members[0]).goal)
	var points: Array = m.get(key, [0.0, 0.0])
	return [points[0], points[1], key]


## What the head of aero / chassis would do at the open milestone.
static func auto_decide(team: TeamData, p: DevProject, r: RandomNumberGenerator) -> void:
	match p.milestone:
		DevProject.Milestone.PICK_CFD:
			# Without numbers he picks by gut feeling – good staff guess better.
			var noise := 0.8 / skill(team, p.part_id, p.goal)
			var guess := {}
			for i in p.ideas:
				guess[i.key] = _guess(p, i, noise, r)
			var keys := guess.keys()
			keys.sort_custom(func(a, b): return guess[a] > guess[b])
			pick_cfd(team, p, keys.slice(0, batch_size(team)))
		DevProject.Milestone.PICK_TUNNEL:
			var measured := p.variants.filter(func(v): return not v.cfd.is_empty())
			measured.sort_custom(func(a, b): return variant_score(p, a, "cfd") > variant_score(p, b, "cfd"))
			var keys := measured.slice(0, 2).map(func(v): return v.key)
			if measured.size() >= 2 and variant_score(p, measured[1], "cfd") > 0.0:
				keys.append(combine(p, [measured[0].key, measured[1].key]).key)
			pick_tunnel(team, p, keys)
		DevProject.Milestone.DECIDE:
			var tested := p.variants.filter(func(v): return not v.tunnel.is_empty())
			tested.sort_custom(func(a, b): return variant_score(p, a, "tunnel") > variant_score(p, b, "tunnel"))
			if tested.is_empty() or variant_score(p, tested[0], "tunnel") <= 0.0:
				_dropped(team, p)
				return
			if freeze(team, p, tested[0].key) != "":
				_dropped(team, p)


static func _guess(p: DevProject, i: Dictionary, noise: float, r: RandomNumberGenerator) -> float:
	return -CarBuild.lap_effect(p.part_id, i.real) * (1.0 + r.randfn(0.0, noise))


static func _dropped(team: TeamData, p: DevProject) -> void:
	cancel(p)
	if team.id == GameState.player_team_id:
		_message(team, "Development dropped: %s", [p.label()],
			"None of the variants was better than the current %s. The project is stopped.", [p.label()])


## Ends the current phase's work: measurements, milestones, next phase.
static func _phase_done(team: TeamData, p: DevProject, r: RandomNumberGenerator) -> void:
	match p.phase:
		DevProject.Phase.CONCEPT:
			p.milestone = DevProject.Milestone.PICK_CFD
			_milestone(team, p, "Ideas ready: %s", "Your team has %d ideas for the %s. Pick which go into CFD.", [p.ideas.size(), p.label()])
		DevProject.Phase.CFD:
			var err := cfd_error(team, p.part_id)
			for v in p.variants:
				if v.cfd_pick and v.cfd.is_empty():
					v.cfd = _measure(v.real, err, 0.4, r)
			p.milestone = DevProject.Milestone.PICK_TUNNEL
			_milestone(team, p, "CFD results: %s", "CFD is done for the %s. Choose what goes into the wind tunnel.", [p.label()])
		DevProject.Phase.TUNNEL:
			var err := correlation_error(team, p.part_id)
			for v in p.variants:
				if v.tunnel_pick:
					v.tunnel = _measure(v.real, err * pow(0.8, v.rounds), 0.15, r)
					v.tunnel_pick = false
			p.milestone = DevProject.Milestone.DECIDE
			_milestone(team, p, "Wind tunnel results: %s", "The wind tunnel / rig results for the %s are in. Refine, freeze or drop.", [p.label()])
		DevProject.Phase.DETAIL:
			if p.next_year:
				p.phase = DevProject.Phase.READY
				_deliver_next_year(team, p)
				return
			p.phase = DevProject.Phase.TOOLING
			_set_work(p, TOOLING_DAYS[p.part_id])
		DevProject.Phase.TOOLING:
			p.phase = DevProject.Phase.PRODUCTION
			_set_work(p, p.unit_work)
		DevProject.Phase.PRODUCTION:
			p.units_built += 1
			p.unit_paid = false
			if p.units_built < p.units:
				_set_work(p, p.unit_work)
			elif p.is_spares():
				p.phase = DevProject.Phase.READY
				_deliver_spares(team, p)
			else:
				p.phase = DevProject.Phase.QUALITY
				_set_work(p, QUALITY_DAYS)
		DevProject.Phase.QUALITY:
			p.phase = DevProject.Phase.READY
			_deliver(team, p)


## A measurement: the real value with relative error and an uncertainty.
static func _measure(real: Dictionary, err: float, base_unc: float, r: RandomNumberGenerator) -> Dictionary:
	var out := {}
	for value in real:
		var t: float = real[value]
		var scale := 0.3 if value == &"mass" else 1.0
		out[value] = [t * (1.0 + r.randfn(0.0, err)) + r.randfn(0.0, base_unc * 0.5 * scale),
			absf(t) * err * 1.6 + base_unc * scale]
	return out


## The player is asked (unless the technical director plans); everybody
## else decides right away.
static func _milestone(team: TeamData, p: DevProject, subject: String, text: String, args: Array) -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	if team.id != GameState.player_team_id or GameState.delegate_car_development:
		auto_decide(team, p, r)
		return
	var msg := _message(team, subject, [p.label()], text, args)
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.link_args = {"tab": 1, "project": p.id}
	msg.link_label = "Open the development lab"


# --- Track test --------------------------------------------------------------

## After the track test the team can go back to the previous version: the
## new units are scrapped, the old version is raced again.
static func revert(team: TeamData, part_id: StringName) -> String:
	var history: Array = team.car.part_history.get(part_id, [])
	var current: PartVersion = team.car.parts[part_id]
	var i := history.find(current)
	if i < 1:
		return "There is no older version."
	current.units = 0
	team.car.parts[part_id] = history[i - 1]
	CarBuild.assign(team, part_id)
	CarBuild.recalculate(team.car)
	return ""


static func can_revert(team: TeamData, part_id: StringName) -> bool:
	var history: Array = team.car.part_history.get(part_id, [])
	return history.find(team.car.parts[part_id]) >= 1


# --- Spares ------------------------------------------------------------------

## Orders more units of a version (production only, no design slot).
static func order_spares(team: TeamData, part_id: StringName, version: int, units: int) -> DevProject:
	for p in projects_of(team.id):
		if p.is_spares() and p.part_id == part_id and p.spares_version == version:
			p.units += units
			return p
	var p := DevProject.new()
	p.team_id = team.id
	p.part_id = part_id
	p.goal = ""
	p.spares_version = version
	p.units = units
	p.phase = DevProject.Phase.PRODUCTION
	p.unit_work = CarParts.PARTS[part_id][4][3]
	p.unit_cost = unit_cost(team, part_id)
	_set_work(p, p.unit_work)
	_add(p)
	return p


## After a race: keep at least one spare of every fitted version and three
## brake sets per car – the factory manager orders the rest.
static func reorder_spares(team: TeamData) -> void:
	var cars := maxi(GameState.drivers_of_team(team.id).size(), 1)
	for id in CarParts.ORDER:
		var v: PartVersion = team.car.parts[id]
		var want := cars * 3 if id == &"brakes" else cars + 1
		var on_order := 0
		for p in projects_of(team.id):
			if p.part_id == id and (p.spares_version == v.version or (not p.is_spares() and not p.next_year)):
				on_order += p.units - p.units_built
		var missing := want - v.units - on_order
		if missing > 0:
			order_spares(team, id, v.version, missing)


# --- Every day ---------------------------------------------------------------

static func daily_update(r: RandomNumberGenerator) -> void:
	for team in GameState.teams.values():
		if not team.car.has_parts():
			continue
		_advance(team, r)
		var planned_by_td: bool = team.id != GameState.player_team_id or GameState.delegate_car_development
		if planned_by_td:
			for p in waiting(team.id):
				auto_decide(team, p, r)
		if Calendar.day % 7 == 0 and planned_by_td:
			team.next_year_share = recommended_share(team)
			_ai_plan(team, r)


static func _advance(team: TeamData, r: RandomNumberGenerator) -> void:
	var share := shares(team)
	for p in projects_of(team.id):
		if p.milestone != DevProject.Milestone.NONE:
			continue
		if p.phase == DevProject.Phase.PRODUCTION and not p.unit_paid:
			# Material for the next unit has to be paid before it is built.
			if team.budget < p.unit_cost:
				if not p.waiting_for_money and team.id == GameState.player_team_id:
					_message(team, "Production stopped: %s", [p.label()],
						"There is not enough budget to build the next unit (%s).", [UIStyle.money(p.unit_cost)])
				p.waiting_for_money = true
				continue
			_pay(team, p.unit_cost)
			p.cost_spent += p.unit_cost
			p.unit_paid = true
			p.waiting_for_money = false
			share = shares(team)
		var rate: float = share.get(p, 0.0)
		if p.phase == DevProject.Phase.TOOLING:
			rate = OVERTIME_SPEED if p.overtime else 1.0
		if rate <= 0.0:
			continue
		p.work_left -= rate
		if p.work_left <= 0.0 and p.phase != DevProject.Phase.READY:
			_phase_done(team, p, r)


## A new version: fitted to as many cars as there are units (No.1 first).
static func _deliver(team: TeamData, p: DevProject) -> void:
	var car := team.car
	var old: PartVersion = car.parts[p.part_id]
	var v := PartVersion.new()
	v.part_id = p.part_id
	v.season = Calendar.year
	var history: Array = car.part_history.get(p.part_id, [old])
	v.version = history.back().version + 1
	v.values = old.values.duplicate()
	v.mass_kg = old.mass_kg
	for key in p.delta:
		if key == &"mass":
			v.mass_kg = maxf(old.mass_kg + p.delta[key], CarParts.base_mass(p.part_id) * 0.6)
		else:
			v.values[key] = clampf(v.values.get(key, 50.0) + p.delta[key], 1.0, 100.0)
	v.units = p.units
	v.goal = p.goal
	v.forecast_s = p.forecast_s
	v.real_s = p.real_s
	v.correlated = false
	v.first_round = GameState.resolved_rounds + 1
	history.append(v)
	car.part_history[p.part_id] = history
	car.parts[p.part_id] = v
	CarBuild.recalculate(car)
	var fitted := CarBuild.fit_new_version(team, v)
	GameState.car_projects.erase(p)
	if team.id == GameState.player_team_id:
		var variant_name := " + ".join(p.variant(p.chosen).get("members", []).map(func(k): return TranslationServer.translate(p.idea(k).get("name", k))))
		var msg := _message(team, "New part ready: %s", [v.label()],
			"%s (%s) is built: %d units.", [v.label(), variant_name, v.units])
		if fitted.size() < GameState.drivers_of_team(team.id).size():
			msg.add_paragraph("Not enough units for both cars yet: only %s gets it. You can change that in the race weekend.",
				[", ".join(fitted)])
		msg.add_paragraph("Wind tunnel forecast: %s per lap. Test it back-to-back in practice with the programme \"Test new parts\" – otherwise the real effect shows after the race.",
			[_seconds(p.forecast_s)])


static func _deliver_spares(team: TeamData, p: DevProject) -> void:
	var v := CarBuild.version_of(team.car, p.part_id, p.spares_version)
	if v:
		v.units += p.units
		CarBuild.refit_where_missing(team)
	GameState.car_projects.erase(p)


## Next-year work goes into the concept of next season's car.
static func _deliver_next_year(team: TeamData, p: DevProject) -> void:
	var plan_fx: Dictionary = team.next_year_parts.get(p.part_id, {})
	for key in p.delta:
		plan_fx[key] = plan_fx.get(key, 0.0) + p.delta[key]
	team.next_year_parts[p.part_id] = plan_fx
	GameState.car_projects.erase(p)
	if team.id == GameState.player_team_id:
		_message(team, "Next year's car: %s done", [p.label()],
			"The %s concept for next season is finished. Forecast: %s per lap compared with this year's part.",
			[p.label(), _seconds(p.forecast_s)])


## After practice or a race: the team knows what its new parts really bring,
## and learns how far its wind tunnel / rigs were off.
static func correlate(team: TeamData) -> void:
	for id in team.car.parts:
		for v in team.car.part_history.get(id, []):
			if v.correlated:
				continue
			v.correlated = true
			var area := "aero" if CarParts.test_kind(id) == "aero" else "rig"
			var key := "%s|%s" % [team.id, area]
			GameState.correlation_experience[key] = GameState.correlation_experience.get(key, 0) + 1
			if team.id != GameState.player_team_id:
				continue
			var diff: float = v.real_s - v.forecast_s
			var verdict := "As forecast."
			if v.real_s > 0.005:
				verdict = "The part is slower than the old one – a failed development."
			elif diff < -0.02:
				verdict = "Better than the wind tunnel said."
			elif diff > 0.02:
				verdict = "Less than the wind tunnel promised."
			var msg := _message(team, "Correlation: %s", [v.label()],
				"Back-to-back result: wind tunnel %s per lap, on track %s.", [_seconds(v.forecast_s), _seconds(v.real_s)])
			msg.add_paragraph(verdict)
			if v.real_s > 0.0:
				msg.add_paragraph("You can go back to the previous version in car development.")


static func _seconds(s: float) -> String:
	return "%+.3f s" % s


static func _message(team: TeamData, subject: String, subject_args: Array, text: String, args: Array) -> InboxMessage:
	var msg := InboxMessage.new()
	msg.sender = "Technical director"
	msg.subject = subject
	msg.subject_args = subject_args
	msg.icon = "car-front"
	msg.add_paragraph(text, args)
	msg.link_screen = &"car"
	msg.link_args = {}
	msg.link_label = "Open car development"
	GameState.add_message(msg)
	return msg


# --- Estimates for the screens -----------------------------------------------

## Work still to do: [[department, days, phase]] with typical batch sizes.
static func _remaining(team: TeamData, p: DevProject) -> Array:
	var days: Array = CarParts.PARTS[p.part_id][4]
	var batch := batch_size(team)
	var test_dept: StringName = &"aero" if CarParts.test_kind(p.part_id) == "aero" else &"rig"
	var tunnel_dept: StringName = &"tunnel" if CarParts.test_kind(p.part_id) == "aero" else &"rig"
	var plan := [[&"design", days[0] + 2.0], [test_dept, CFD_DAYS * batch], [tunnel_dept, TUNNEL_DAYS * 3],
		[&"design", days[1] * 0.45], [&"tooling", TOOLING_DAYS[p.part_id]], [&"factory", days[3] * p.units], [&"rig", QUALITY_DAYS]]
	if p.is_spares():
		return [[&"factory", p.work_left + p.unit_work * (p.units - p.units_built - 1), DevProject.Phase.PRODUCTION]]
	var out := []
	for i in plan.size():
		if i < p.phase:
			continue
		if p.next_year and i > DevProject.Phase.DETAIL:
			break
		var work: float = plan[i][1]
		if i == p.phase:
			work = p.work_left if p.phase != DevProject.Phase.PRODUCTION else p.work_left + p.unit_work * (p.units - p.units_built - 1)
		out.append([plan[i][0], work, i])
	return out


## Days until the part is ready at today's pace (milestones not counted).
static func days_left(team: TeamData, p: DevProject, share: Dictionary = {}) -> float:
	var caps := capacities(team)
	var busy := department_load(team)
	var total := 0.0
	for entry in _remaining(team, p):
		var d: StringName = entry[0]
		var rate := 1.0
		if d != &"tooling":
			rate = minf(PROJECT_MAX_RATE * (OVERTIME_SPEED if p.overtime else 1.0), caps[d] / maxf(busy[d][0], 1.0))
		total += entry[1] / maxf(rate, 0.2)
	return total


## "R12" – the first race the part can make – or "after the season".
static func ready_label(days: float) -> String:
	var s: SeriesData = GameState.series[GameState.player_team().series_id]
	var day := Calendar.day + ceili(days)
	for i in s.race_days.size():
		if s.race_days[i] >= day and i >= GameState.resolved_rounds:
			return "R%d" % (i + 1)
	return TranslationServer.translate("after the season")


## Forecast for the "New project" dialog (before any idea exists).
static func preview(team: TeamData, part_id: StringName, goal: String, ambition: int, priority: int,
		units: int, overtime: bool, next_year: bool) -> Dictionary:
	var base := expected_gain(team, part_id, goal, ambition) * TARGET_SHARE
	var fx := _effects(part_id, goal, base, team)
	var expected := CarBuild.lap_effect(part_id, fx, team.car.mass_kg)
	var probe := DevProject.new()
	probe.part_id = part_id
	probe.next_year = next_year
	probe.ambition = ambition as DevProject.Ambition
	probe.overtime = overtime
	probe.priority = priority as DevProject.Priority
	probe.units = 0 if next_year else units
	probe.unit_work = CarParts.PARTS[part_id][4][3]
	_set_work(probe, CarParts.PARTS[part_id][4][0] + 2.0)
	var caps := capacities(team)
	var busy := department_load(team)
	var phases := []
	for entry in _remaining(team, probe):
		var d: StringName = entry[0]
		var rate := 1.0
		if d != &"tooling":
			rate = minf(PROJECT_MAX_RATE * (OVERTIME_SPEED if overtime else 1.0), caps[d] / (busy[d][0] + 1.0))
		phases.append([d, entry[1] / maxf(rate, 0.2), rate, entry[2]])
	var total := days_left(team, probe)
	var batch := batch_size(team)
	var costs := _concept_cost(team, probe) + cfd_cost(probe, batch) + tunnel_cost(probe, 3) \
		+ int(design_cost(team, part_id, ambition, overtime) * 0.45) + (0 if next_year else unit_cost(team, part_id) * (2 + units))
	return {
		"expected_s": expected,
		"gain": base,
		"fx": fx,
		"risk": dead_end_chance(team, ambition),
		"ideas": "3–6",
		"cost": costs,
		"concept_cost": _concept_cost(team, probe),
		"phase_days": phases,
		"days": total,
		"ready": TranslationServer.translate("next season") if next_year else ready_label(total),
		"correlation": correlation_error(team, part_id),
		"reason": cannot_start(team, probe),
	}


# --- Technical director's planning -------------------------------------------

## How much of the team works on next season's car: nothing in the first
## half, more after the summer, most at the end – sooner if the season is lost.
static func recommended_share(team: TeamData) -> float:
	var s: SeriesData = GameState.series[team.series_id]
	var done := GameState.resolved_rounds / float(maxi(s.calendar.size(), 1))
	var share := 0.0
	if done >= 0.85:
		share = 0.7
	elif done >= 0.65:
		share = 0.45
	elif done >= 0.45:
		share = 0.2
	var position := 1
	var table := SeasonRecords.team_standings(s)
	for i in table.size():
		if table[i][0] == team.id:
			position = i + 1
	if done >= 0.45 and position >= 7:
		share += 0.15
	return clampf(share, 0.0, 0.9)


## Keeps the design slots busy with the parts that promise the most lap
## time for the money; part of the slots goes to next year's car.
static func _ai_plan(team: TeamData, r: RandomNumberGenerator) -> void:
	var s: SeriesData = GameState.series[team.series_id]
	var reserve := ContractLogic.payroll_per_month(team.id) * RESERVE_MONTHS
	var slots := max_projects(team) - design_projects(team.id).size()
	var season_left := GameState.resolved_rounds < s.calendar.size() - 2
	var guard := 0
	while slots > 0 and guard < 4:
		guard += 1
		var next_running := design_projects(team.id).filter(func(p): return p.next_year).size()
		var next_year := not season_left or (team.next_year_share > 0.0 and next_running < ceili(max_projects(team) * team.next_year_share))
		var pick := best_option(team, next_year)
		if pick.is_empty():
			return
		var ambition := _ai_ambition(team, r)
		var cost := design_cost(team, pick[0], ambition, false) + (0 if next_year else unit_cost(team, pick[0]) * 5)
		if team.budget - cost < reserve:
			return
		var p := plan(team, pick[0], pick[1], ambition, DevProject.Priority.NORMAL, 3, false, r, next_year)
		if start(team, p) != "":
			return
		slots -= 1


## [part, goal] with the best expected lap time per million, or [].
static func best_option(team: TeamData, next_year: bool = false) -> Array:
	var busy := design_projects(team.id).filter(func(p): return p.next_year == next_year).map(func(p): return p.part_id)
	var best := []
	var best_score := 0.0
	for id in CarParts.ORDER:
		if busy.has(id) or (not next_year and not CarParts.in_season(id)):
			continue
		for goal in CarParts.goals_of(id):
			var score: float = _goal_value(team, id, goal) / (CarParts.PARTS[id][5][0] / 1_000_000.0 + 0.5)
			if score > best_score:
				best_score = score
				best = [id, goal]
	return best


## What a goal is worth to this team (seconds, plus weight for reliability and cooling needs).
static func _goal_value(team: TeamData, part_id: StringName, goal: String) -> float:
	var gain := expected_gain(team, part_id, goal, DevProject.Ambition.NORMAL)
	var fx := _effects(part_id, goal, gain, team)
	var car := team.car
	# Weight already being saved by running projects does not count twice.
	var mass := car.mass_kg
	for other in projects_of(team.id):
		mass += other.forecast.get(&"mass", 0.0)
	var value := -CarBuild.lap_effect(part_id, fx, mass)
	if fx.has(&"reliability") and fx[&"reliability"] > 0.0 and car.parts[part_id].value(&"reliability") < 80.0:
		value += 0.04
	if fx.has(&"cooling") and fx[&"cooling"] > 0.0 and car.cooling < 55:
		value += 0.05
	if fx.has(&"tyre_preservation"):
		value += fx[&"tyre_preservation"] * 0.0015
	return value


static func _ai_ambition(team: TeamData, r: RandomNumberGenerator) -> int:
	var rank := TeamMood.car_rank(team.id)
	if rank >= 8 and r.randf() < 0.5:
		return DevProject.Ambition.AGGRESSIVE
	if rank <= 2 and r.randf() < 0.3:
		return DevProject.Ambition.AGGRESSIVE
	if r.randf() < 0.15:
		return DevProject.Ambition.CONSERVATIVE
	return DevProject.Ambition.NORMAL
