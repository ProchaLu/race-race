## The engine lab (docs/engine_model.md 5). Power is easy to measure,
## durability takes kilometres: ideas → single-cylinder rig (rough) → full
## dyno (precise power) → endurance runs (reliability, failures) →
## homologation and production of the new spec. Also the power unit
## programme of a team that becomes a manufacturer. AI manufacturers – and
## the player's team while delegated – decide by the same rules.
class_name EngineLab
extends RefCounted

const CONCEPT_DAYS := 8.0
const RIG_DAYS := 1.5
const DYNO_DAYS := 2.5
## Work days per race distance on the endurance dyno.
const ENDURANCE_DAYS := 2.0
const RACE_DISTANCE_KM := 305.0
## Calendar days to homologate and build the first units.
const PRODUCTION_DAYS := {&"ice": 35, &"turbo": 25, &"ers": 30, &"battery": 30, &"control": 20}
const CONCEPT_COST := 400_000
const RIG_COST := 60_000
const DYNO_COST := 150_000
const ENDURANCE_COST := 300_000
const PRODUCTION_COST := 1_000_000
## Power unit programme: design work days and total cost.
const PROGRAMME_WORK := 420.0
const PROGRAMME_COST := 150_000_000
const MAX_RIG := 4
const MAX_DYNO := 3
## Points of an idea before skill, ambition and room.
const IDEA_GAIN := 3.0
## Ideas aiming at power often hide a weakness the endurance dyno can find.
const WEAK_CHANCE := 0.35
const DEAD_END := 0.2
const AI_PROJECTS := 2


# --- Who develops ------------------------------------------------------------------

## Team whose engine department works for the manufacturer (null = independent).
static func dev_team(m: ManufacturerData) -> TeamData:
	return GameState.teams.get(m.works_team_id)


static func _chief(team: TeamData, property: StringName) -> int:
	if team == null:
		return 60
	for s in GameState.staff_of_team(team.id):
		if s.role == StaffData.Role.ENGINE_CHIEF:
			return s.attribute(property)
	return 45


static func works_level(m: ManufacturerData) -> int:
	var team := dev_team(m)
	if team == null:
		return 3
	return Facilities.level(team, &"engine")


## Work days per day: engine design office and dynos.
static func capacities(m: ManufacturerData) -> Dictionary:
	var team := dev_team(m)
	var level := works_level(m)
	var skill := (_chief(team, &"power_development") + _chief(team, &"efficiency")) / 2.0 if team else float(m.staff_level)
	var heads := CarDevelopment.headcount(team, &"engine") if team else 70
	var design := 1.4 * skill / 65.0 * pow(heads / 50.0, 0.75) * (0.6 + 0.2 * level)
	var dyno := 1.3 * (0.6 + 0.2 * level)
	return {&"design": design, &"dyno": dyno}


static func projects_of(m_id: StringName) -> Array:
	return GameState.engine_projects.filter(func(p): return p.manufacturer_id == m_id)


static func department(p: EngineProject) -> StringName:
	if p.milestone != EngineProject.Milestone.NONE:
		return &""
	match p.phase:
		EngineProject.Phase.CONCEPT, EngineProject.Phase.PROGRAMME:
			return &"design"
		EngineProject.Phase.RIG, EngineProject.Phase.DYNO, EngineProject.Phase.ENDURANCE:
			return &"dyno"
	return &""


## Days of work per day this project gets right now.
static func rate(p: EngineProject) -> float:
	if p.is_programme():
		return programme_rate(GameState.teams[p.team_id]) if p.milestone == EngineProject.Milestone.NONE else 0.0
	var m: ManufacturerData = GameState.manufacturers[p.manufacturer_id]
	var d := department(p)
	if d == &"":
		return 1.0 if p.phase == EngineProject.Phase.PRODUCTION else 0.0
	var busy := projects_of(m.id).filter(func(q): return department(q) == d).size()
	return minf(1.0, capacities(m)[d] / maxf(busy, 1))


## How far the endurance dyno's reliability estimate can be off (± points).
static func endurance_error(m: ManufacturerData, runs: int) -> float:
	var base := 3.0 * (1.3 - 0.1 * works_level(m)) * (1.2 - _chief(dev_team(m), &"reliability_focus") / 100.0 * 0.5)
	return base / sqrt(maxf(runs, 1))


static func skill(m: ManufacturerData, focus: String) -> float:
	var team := dev_team(m)
	if team == null:
		return m.staff_level / 65.0
	var prop: StringName = {"power": &"power_development", "efficiency": &"efficiency", "reliability": &"reliability_focus"}.get(focus, &"")
	var v := _chief(team, prop) if prop != &"" else (_chief(team, &"power_development") + _chief(team, &"efficiency")) / 2
	return clampf(v / 65.0 * (0.85 + 0.05 * works_level(m)), 0.5, 1.6)


static func can_develop(team: TeamData) -> bool:
	return Engines.develops(team)


# --- Planning ----------------------------------------------------------------------

static func plan(m: ManufacturerData, component: StringName, focus: String, aggressive: bool, r: RandomNumberGenerator) -> EngineProject:
	var p := EngineProject.new()
	p.manufacturer_id = m.id
	p.team_id = m.works_team_id
	p.component = component
	p.focus = focus
	p.aggressive = aggressive
	_set_work(p, CONCEPT_DAYS)
	var pool: Array = PowerUnit.IDEAS[component].duplicate()
	pool.shuffle()
	pool.sort_custom(func(a, b): return a[1] == focus and b[1] != focus)
	var sk := skill(m, focus)
	var count := clampi(3 + roundi((sk - 0.9) * 3.0) + r.randi_range(0, 1), 3, 5)
	var keys := "ABCDE"
	var current: Dictionary = Engines.latest_spec(m, component, dev_team(m)).values
	for i in mini(count, pool.size()):
		var entry: Array = pool[i]
		var f: String = entry[1]
		var key := StringName(f)
		var room := clampf((100.0 - current.get(key, 50.0)) / 40.0, 0.25, 1.5) if current.has(key) else 1.0
		var gain := IDEA_GAIN * sk * (1.6 if aggressive else 1.0) * room * maxf(0.1, 1.0 + r.randfn(0.0, 0.5))
		var real := {}
		if r.randf() < DEAD_END * (1.6 if aggressive else 1.0) * (1.3 - sk * 0.3):
			gain = -gain * r.randf_range(0.2, 0.6)
		_effect(real, component, f, gain)
		var weak := 0.0
		if (f == "power" or aggressive) and r.randf() < WEAK_CHANCE * (1.5 if aggressive else 1.0):
			weak = r.randf_range(600.0, 2400.0)
			real[&"reliability"] = real.get(&"reliability", 0.0) - r.randf_range(4.0, 9.0)
		p.ideas.append({"key": keys[i], "name": entry[0], "focus": f, "real": real, "weak_km": weak})
	return p


## The change of a component's values for a gain in points in one direction
## (with small side effects – more power costs some efficiency, less weight
## some reliability).
static func _effect(out: Dictionary, component: StringName, focus: String, gain: float) -> void:
	var values := PowerUnit.values_of(component)
	var key := StringName(focus)
	if values.has(key):
		out[key] = out.get(key, 0.0) + gain
	match focus:
		"power":
			if values.has(&"efficiency"):
				out[&"efficiency"] = out.get(&"efficiency", 0.0) - gain * 0.2
		"weight":
			if values.has(&"reliability"):
				out[&"reliability"] = out.get(&"reliability", 0.0) - gain * 0.2
		"efficiency":
			if values.has(&"power"):
				out[&"power"] = out.get(&"power", 0.0) + gain * 0.15


static func _set_work(p: EngineProject, days: float) -> void:
	p.work_left = days
	p.phase_total = maxf(days, 0.01)


static func cannot_start(team: TeamData, component: StringName) -> String:
	if not can_develop(team):
		return "Engine development needs a licence or your own works engine."
	var m := Engines.manufacturer_of(team)
	for p in projects_of(m.id):
		if p.component == component and not p.is_programme():
			return "This component is already in development."
	if m.specs_this_season.get(component, 0) >= Engines.SPECS_PER_SEASON:
		return "All specs for this component are used this season."
	if team.budget < CONCEPT_COST:
		return "Not enough budget."
	return ""


static func start(p: EngineProject) -> void:
	_pay(p, CONCEPT_COST)
	_add(p)


static func _add(p: EngineProject) -> void:
	p.id = GameState.next_engine_project_id
	GameState.next_engine_project_id += 1
	p.started_day = Calendar.day
	p.started_year = Calendar.year
	GameState.engine_projects.append(p)


static func cancel(p: EngineProject) -> void:
	GameState.engine_projects.erase(p)


static func _pay(p: EngineProject, amount: int) -> bool:
	p.cost_spent += amount
	var team: TeamData = GameState.teams.get(p.team_id)
	if team == null:
		return true
	if team.budget < amount:
		return false
	team.budget -= amount
	GameState.engine_spending[team.id] = GameState.engine_spending.get(team.id, 0) + amount
	EventBus.budget_changed.emit(team.id, team.budget)
	return true


# --- Milestones --------------------------------------------------------------------

static func pick_rig(p: EngineProject, keys: Array) -> String:
	keys = keys.slice(0, MAX_RIG)
	if keys.is_empty():
		return "Pick at least one idea."
	if not _can_pay(p, RIG_COST * keys.size()):
		return "Not enough budget."
	_pay(p, RIG_COST * keys.size())
	for k in keys:
		var i := p.idea(k)
		p.variants.append({"key": k, "members": [k], "real": i.real.duplicate(), "weak_km": i.weak_km,
			"rig": {}, "dyno": {}, "runs": 0, "fail_km": 0.0, "rel": [], "defused": 0, "picked": true})
	p.milestone = EngineProject.Milestone.NONE
	p.phase = EngineProject.Phase.RIG
	_set_work(p, RIG_DAYS * keys.size())
	return ""


## Two ideas together: the real effect is the sum times a hidden factor.
static func combine(p: EngineProject, keys: Array) -> Dictionary:
	keys = keys.duplicate()
	keys.sort()
	var key := "+".join(keys)
	if keys.size() < 2 or not p.variant(key).is_empty():
		return p.variant(key)
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d|%s" % [p.id, key])
	var factor := r.randf_range(0.75, 1.15)
	var real := {}
	var rig := {}
	var weak := 0.0
	for k in keys:
		var v := p.variant(k)
		for value in v.real:
			real[value] = real.get(value, 0.0) + v.real[value] * factor
		for value in v.rig:
			var c: Array = rig.get(value, [0.0, 0.0])
			rig[value] = [c[0] + v.rig[value][0], c[1] + v.rig[value][1]]
		if v.weak_km > 0.0:
			weak = v.weak_km if weak == 0.0 else minf(weak, v.weak_km)
	var combo := {"key": key, "members": keys, "real": real, "weak_km": weak, "rig": rig, "dyno": {}, "runs": 0,
		"fail_km": 0.0, "rel": [], "defused": 0, "picked": false}
	p.variants.append(combo)
	return combo


static func pick_dyno(p: EngineProject, keys: Array) -> String:
	keys = keys.slice(0, MAX_DYNO)
	if keys.is_empty():
		return "Pick at least one variant."
	if not _can_pay(p, DYNO_COST * keys.size()):
		return "Not enough budget."
	_pay(p, DYNO_COST * keys.size())
	for v in p.variants:
		v.picked = keys.has(v.key)
	p.milestone = EngineProject.Milestone.NONE
	p.phase = EngineProject.Phase.DYNO
	_set_work(p, DYNO_DAYS * keys.size())
	return ""


## Race distances on the endurance dyno for one variant (more = more precise).
static func endurance(p: EngineProject, key: String, runs: int) -> String:
	var v := p.variant(key)
	if v.is_empty() or v.dyno.is_empty():
		return "Run the variant on the full dyno first."
	if not _can_pay(p, ENDURANCE_COST * runs):
		return "Not enough budget."
	_pay(p, ENDURANCE_COST * runs)
	p.chosen = key
	p.runs_ordered = runs
	p.milestone = EngineProject.Milestone.NONE
	p.phase = EngineProject.Phase.ENDURANCE
	_set_work(p, ENDURANCE_DAYS * runs)
	return ""


## Less power, more margin: removes a weakness most of the time; the
## variant needs new endurance runs.
static func defuse(p: EngineProject, key: String) -> String:
	var v := p.variant(key)
	if v.is_empty():
		return "Unknown variant."
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d|%s|%d" % [p.id, key, v.defused])
	for value in v.real:
		if v.real[value] > 0.0 and value != &"reliability":
			v.real[value] *= 0.7
	v.real[&"reliability"] = v.real.get(&"reliability", 0.0) + 3.0
	if v.weak_km > 0.0 and r.randf() < 0.75:
		v.real[&"reliability"] += 5.0
		v.weak_km = 0.0
	for value in v.dyno:
		if value != &"reliability" and v.dyno[value][0] > 0.0:
			v.dyno[value] = [v.dyno[value][0] * 0.7, v.dyno[value][1]]
	v.defused += 1
	v.runs = 0
	v.fail_km = 0.0
	v.rel = []
	p.milestone = EngineProject.Milestone.PICK_ENDURANCE
	return ""


static func homologate(p: EngineProject, key: String) -> String:
	var v := p.variant(key)
	if v.is_empty() or v.runs == 0:
		return "Run the variant on the endurance dyno first."
	var m: ManufacturerData = GameState.manufacturers[p.manufacturer_id]
	if m.specs_this_season.get(p.component, 0) >= Engines.SPECS_PER_SEASON:
		return "All specs for this component are used this season."
	if not _can_pay(p, PRODUCTION_COST):
		return "Not enough budget."
	_pay(p, PRODUCTION_COST)
	p.chosen = key
	p.milestone = EngineProject.Milestone.NONE
	p.phase = EngineProject.Phase.PRODUCTION
	var days: float = PRODUCTION_DAYS[p.component] * (1.2 - 0.06 * works_level(m))
	_set_work(p, days)
	return ""


static func _can_pay(p: EngineProject, amount: int) -> bool:
	var team: TeamData = GameState.teams.get(p.team_id)
	return team == null or team.budget >= amount


# --- Measurements --------------------------------------------------------------------

static func _measure(real: Dictionary, err: float, base: float, r: RandomNumberGenerator, skip_reliability: bool) -> Dictionary:
	var out := {}
	for value in real:
		if skip_reliability and value == &"reliability":
			continue
		var t: float = real[value]
		out[value] = [t * (1.0 + r.randfn(0.0, err)) + r.randfn(0.0, base * 0.5), absf(t) * err * 1.6 + base]
	return out


## Endurance runs: kilometres pile up; a weakness shows as a failure.
static func _endurance_result(m: ManufacturerData, v: Dictionary, runs: int, r: RandomNumberGenerator) -> void:
	var before: float = v.runs * RACE_DISTANCE_KM
	v.runs += runs
	var after: float = v.runs * RACE_DISTANCE_KM
	if v.weak_km > 0.0 and v.fail_km == 0.0 and after >= v.weak_km and before < v.weak_km + RACE_DISTANCE_KM:
		v.fail_km = v.weak_km + r.randf_range(-60.0, 60.0)
	var err := endurance_error(m, v.runs)
	v.rel = [v.real.get(&"reliability", 0.0) + r.randfn(0.0, err * 0.5), err]


## Score of a variant from what the team believes (dyno + endurance).
static func believed(v: Dictionary) -> Dictionary:
	var out := {}
	var source: Dictionary = v.dyno if not v.dyno.is_empty() else v.rig
	for value in source:
		out[value] = source[value][0]
	if not v.rel.is_empty():
		out[&"reliability"] = v.rel[0]
	return out


static func score(fx: Dictionary) -> float:
	var s := 0.0
	for value in fx:
		s += fx[value] * Engines.AI_VALUE_WEIGHTS.get(value, 0.1)
	return s


# --- Every day ---------------------------------------------------------------------

static func daily_update(r: RandomNumberGenerator) -> void:
	for p: EngineProject in GameState.engine_projects.duplicate():
		if p.milestone != EngineProject.Milestone.NONE:
			if _auto(p):
				auto_decide(p, r)
			continue
		var work := rate(p)
		if p.phase == EngineProject.Phase.PROGRAMME:
			# The programme is paid as the work is done.
			var share := minf(work, p.work_left) / PROGRAMME_WORK
			if not _pay(p, int(PROGRAMME_COST * 0.8 * share)):
				continue
		p.work_left -= work
		if p.work_left <= 0.0:
			_phase_done(p, r)
	if Calendar.day % 7 == 5:
		for m: ManufacturerData in GameState.manufacturers.values():
			if _ai_controlled(m):
				_ai_plan(m, r)


## AI manufacturers and the player's own engine while delegated decide alone.
static func _auto(p: EngineProject) -> bool:
	return p.team_id != GameState.player_team_id or GameState.delegate_engine_development


static func _ai_controlled(m: ManufacturerData) -> bool:
	return m.works_team_id != GameState.player_team_id or GameState.delegate_engine_development


static func _phase_done(p: EngineProject, r: RandomNumberGenerator) -> void:
	var m: ManufacturerData = GameState.manufacturers[p.manufacturer_id]
	match p.phase:
		EngineProject.Phase.CONCEPT:
			p.milestone = EngineProject.Milestone.PICK_RIG
			_milestone(p, "Engine ideas ready: %s", "The engine design office has %d ideas for the %s. Pick which go on the single-cylinder rig.", [p.ideas.size(), p.label()])
		EngineProject.Phase.RIG:
			for v in p.variants:
				if v.picked and v.rig.is_empty():
					v.rig = _measure(v.real, 0.45, 0.8, r, true)
			p.milestone = EngineProject.Milestone.PICK_DYNO
			_milestone(p, "Rig results: %s", "The single-cylinder rig results for the %s are in. Choose what goes on the full dyno.", [p.label()])
		EngineProject.Phase.DYNO:
			for v in p.variants:
				if v.picked:
					v.dyno = _measure(v.real, 0.08, 0.2, r, true)
					v.picked = false
			p.milestone = EngineProject.Milestone.PICK_ENDURANCE
			_milestone(p, "Dyno results: %s", "Power and efficiency of the %s variants are measured. Which goes on the endurance dyno?", [p.label()])
		EngineProject.Phase.ENDURANCE:
			_endurance_result(m, p.variant(p.chosen), p.runs_ordered, r)
			p.milestone = EngineProject.Milestone.DECIDE
			var v := p.variant(p.chosen)
			if v.fail_km > 0.0:
				_milestone(p, "Endurance failure: %s", "Variant %s failed on the endurance dyno after %d km. Defuse it, run more distances, homologate anyway or drop it.", [p.chosen, roundi(v.fail_km)])
			else:
				_milestone(p, "Endurance run done: %s", "Variant %s ran %d race distances without a failure. Homologate it, run more distances or drop it.", [p.chosen, v.runs])
		EngineProject.Phase.PRODUCTION:
			_release(p)
		EngineProject.Phase.PROGRAMME:
			_programme_done(p, r)


static func _release(p: EngineProject) -> void:
	var m: ManufacturerData = GameState.manufacturers[p.manufacturer_id]
	var v := p.variant(p.chosen)
	var values: Dictionary = Engines.latest_spec(m, p.component, dev_team(m)).values.duplicate()
	for value in v.real:
		if values.has(value):
			values[value] = clampf(values[value] + v.real[value], 5.0, 99.0)
	Engines.release_spec(m, p.component, values)
	GameState.engine_projects.erase(p)
	for team: TeamData in Engines.teams_of(m):
		Engines.refresh_team(team)


static func _milestone(p: EngineProject, subject: String, text: String, args: Array) -> void:
	if p.team_id != GameState.player_team_id or GameState.delegate_engine_development:
		return
	var msg := InboxMessage.new()
	msg.sender = "Engine chief"
	msg.icon = "cog"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.subject = subject
	msg.subject_args = [p.label()]
	msg.add_paragraph(text, args)
	msg.link_screen = &"engine"
	msg.link_args = {"tab": 2}
	msg.link_label = "Open the engine lab"
	GameState.add_message(msg)


## What the engine chief would do at the open milestone.
static func auto_decide(p: EngineProject, r: RandomNumberGenerator) -> void:
	match p.milestone:
		EngineProject.Milestone.PICK_RIG:
			var guess := {}
			for i in p.ideas:
				guess[i.key] = score(i.real) * (1.0 + r.randfn(0.0, 0.8))
			var keys := guess.keys()
			keys.sort_custom(func(a, b): return guess[a] > guess[b])
			if pick_rig(p, keys.slice(0, 3)) != "":
				cancel(p)
		EngineProject.Milestone.PICK_DYNO:
			var measured := p.variants.filter(func(v): return not v.rig.is_empty())
			measured.sort_custom(func(a, b): return score(believed(a)) > score(believed(b)))
			var keys := measured.slice(0, 2).map(func(v): return v.key)
			if measured.size() >= 2 and score(believed(measured[1])) > 0.0:
				keys.append(combine(p, [measured[0].key, measured[1].key]).key)
			if pick_dyno(p, keys) != "":
				cancel(p)
		EngineProject.Milestone.PICK_ENDURANCE:
			var tested := p.variants.filter(func(v): return not v.dyno.is_empty())
			tested.sort_custom(func(a, b): return score(believed(a)) > score(believed(b)))
			if tested.is_empty() or score(believed(tested[0])) <= 0.0 or endurance(p, tested[0].key, 3) != "":
				cancel(p)
		EngineProject.Milestone.DECIDE:
			var v := p.variant(p.chosen)
			if v.fail_km > 0.0:
				if v.defused < 1:
					defuse(p, p.chosen)
				else:
					cancel(p)
			elif score(believed(v)) > 0.0:
				if homologate(p, p.chosen) != "":
					cancel(p)
			else:
				cancel(p)


## AI manufacturers keep up to two projects running on their weakest values.
static func _ai_plan(m: ManufacturerData, r: RandomNumberGenerator) -> void:
	var running := projects_of(m.id)
	if running.size() >= AI_PROJECTS or r.randf() > 0.5:
		return
	if running.any(func(p): return p.is_programme()):
		return
	var team := dev_team(m)
	if team and team.budget < 40_000_000:
		return
	var values := Engines.manufacturer_values(m)
	var focus := "power"
	var weakest := INF
	for value in Engines.AI_VALUE_WEIGHTS:
		var v: float = values[value] - Engines.AI_VALUE_WEIGHTS[value] * 40.0
		if v < weakest:
			weakest = v
			focus = String(value)
	var weights: Dictionary = PowerUnit.WEIGHTS[StringName(focus)]
	var options := PowerUnit.COMPONENTS.filter(func(c):
		var busy: bool = running.any(func(q): return q.component == c)
		return not busy and m.specs_this_season.get(c, 0) < Engines.SPECS_PER_SEASON and weights.has(c))
	if options.is_empty():
		return
	options.sort_custom(func(a, b): return weights[a] > weights[b])
	var p := plan(m, options[0], focus, r.randf() < 0.25, r)
	start(p)


# --- Power unit programme ------------------------------------------------------------

static func programme_reason(team: TeamData) -> String:
	if Engines.is_works(team) and team.engine_deal.get("type", "") == "works":
		return "You already build your own engine."
	if Facilities.level(team, &"engine") < 3:
		return "The programme needs engine works level 3."
	for p in GameState.engine_projects:
		if p.is_programme() and p.team_id == team.id:
			return "The programme is already running."
	if team.budget < int(PROGRAMME_COST * 0.2):
		return "Not enough budget."
	return ""


## Starts the programme: 20 % now, the rest as the work is done.
static func start_programme(team: TeamData) -> String:
	var reason := programme_reason(team)
	if reason != "":
		return reason
	var p := EngineProject.new()
	p.manufacturer_id = team.engine_manufacturer
	p.team_id = team.id
	p.component = &"ice"
	p.phase = EngineProject.Phase.PROGRAMME
	_set_work(p, PROGRAMME_WORK)
	_pay(p, int(PROGRAMME_COST * 0.2))
	_add(p)
	return ""


## Speed of the programme: the team's own engine design office.
static func programme_rate(team: TeamData) -> float:
	var level := Facilities.level(team, &"engine")
	var skill := (_chief(team, &"power_development") + _chief(team, &"efficiency")) / 2.0
	return 1.4 * skill / 65.0 * pow(CarDevelopment.headcount(team, &"engine") / 50.0, 0.75) * (0.6 + 0.2 * level)


static func _programme_done(p: EngineProject, r: RandomNumberGenerator) -> void:
	var team: TeamData = GameState.teams[p.team_id]
	var base := 38.0 + (_chief(team, &"power_development") + _chief(team, &"efficiency") + _chief(team, &"reliability_focus")) / 3.0 * 0.2 \
		+ Facilities.level(team, &"engine") * 2.0
	var comps := {}
	for c in PowerUnit.COMPONENTS:
		var values := {}
		for v in PowerUnit.values_of(c):
			values[v] = clampf(base + r.randfn(0.0, 4.0), 20.0, 90.0)
		comps[c] = values
	var m := Engines.create_own_manufacturer(team, comps)
	GameState.engine_projects.erase(p)
	if team.id == GameState.player_team_id:
		var msg := InboxMessage.new()
		msg.sender = "Engine chief"
		msg.icon = "cog"
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.subject = "Our own power unit is ready"
		msg.add_paragraph("The power unit programme is finished. From next season we race our own engine: %s.", [m.name])
		msg.add_paragraph("We can also sell it to other teams – they can ask us for offers in the negotiation window.")
		msg.link_screen = &"engine"
		msg.link_label = "Open engine"
		GameState.add_message(msg)
