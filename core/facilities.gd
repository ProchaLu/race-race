## The HQ (design doc 7, docs/r4_review.md): 15 buildings with levels 0..5,
## construction with cost and build time, monthly upkeep, room for staff and
## the effect of every building on the other systems. The single source of
## facility levels – R3 capacities, the weekend (TeamOps) and team mood read
## them from here. AI teams build by the same rules.
class_name Facilities
extends RefCounted

## name, purpose, base build price, base days, round whose system the
## building feeds ("" = works now; else the building is locked until then).
const CATALOG := {
	&"design": ["Design office", "Engineering studios turn concepts into detailed car designs.", 6_000_000, 35, ""],
	&"wind": ["Wind tunnel", "Tests aerodynamic concepts and improves confidence in their performance.", 12_000_000, 60, ""],
	&"cfd": ["CFD centre", "Computing infrastructure for aerodynamic simulation.", 5_000_000, 30, ""],
	&"factory": ["Factory", "Manufactures car parts and replacement components.", 10_000_000, 50, ""],
	&"composites": ["Composites", "Specialist production space for lightweight composite structures.", 7_000_000, 40, ""],
	&"engine": ["Engine works", "Assembly and testing facilities for a future in-house engine programme.", 20_000_000, 80, "R5"],
	&"lab": ["Test laboratory", "Dedicated test cells for mechanical systems and component validation.", 6_000_000, 35, ""],
	&"simulator": ["Simulator", "A dedicated environment for driver preparation and virtual testing.", 5_000_000, 30, ""],
	&"performance": ["Driver performance centre", "Fitness, recovery and mental preparation for the drivers.", 3_000_000, 25, ""],
	&"academy": ["Academy", "Teaching and training facilities for young drivers.", 4_000_000, 35, "R7"],
	&"scouting": ["Scouting office", "A base for talent analysis and recruitment.", 2_000_000, 20, "R7"],
	&"pit": ["Pit-crew training", "Garage and practice space for race preparation and pit-stop drills.", 3_000_000, 25, ""],
	&"mission": ["Mission control", "Race support, communications and strategy analysis.", 4_000_000, 30, ""],
	&"hospitality": ["Marketing & hospitality", "Welcomes partners and guests and supports commercial activity.", 3_000_000, 25, "R6"],
	&"staff": ["Staff facilities", "Dining, social and wellbeing spaces for the team.", 2_000_000, 20, ""],
}
## Buildings every team has (never level 0).
const CORE := [&"design", &"wind", &"factory"]
## Price of a level relative to the base price (index = target level).
## Every level costs clearly more than the one before; the biggest upgrade
## (wind tunnel level 5) costs $60M – the top of the design doc's range.
const PRICE_FACTOR := [0.0, 1.0, 1.5, 2.3, 3.4, 5.0]
## Build time: base days × (1 + this × (target − 1)).
const TIME_STEP := 0.35
## Upkeep per month: base price × share × level^exponent – big buildings
## cost disproportionately more to run.
const UPKEEP_SHARE := 0.006
const UPKEEP_EXPONENT := 1.3
## Room for staff per level relative to an average department (R3 headcount).
## Level 0: the department squeezes into other buildings.
const ROOM := [0.45, 0.6, 0.8, 1.0, 1.25, 1.55]
## A second construction crew once the campus has this many levels in total.
const SECOND_CREW_LEVELS := 45
## Department -> building that houses it.
const HOUSES := {&"design": &"design", &"aero": &"cfd", &"rig": &"lab", &"factory": &"factory"}
## AI: months of salaries and upkeep a team keeps in the bank.
const RESERVE_MONTHS := 6
## AI preference per building (development first).
const AI_WEIGHT := {&"design": 1.0, &"wind": 1.1, &"cfd": 0.9, &"factory": 0.9, &"composites": 0.7, &"lab": 0.8,
	&"simulator": 0.6, &"performance": 0.4, &"pit": 0.6, &"mission": 0.5, &"staff": 0.4}


static func name_of(id: StringName) -> String:
	return CATALOG[id][0]


static func purpose_of(id: StringName) -> String:
	return CATALOG[id][1]


## "" or the round that brings the system this building feeds ("R5").
static func locked_until(id: StringName) -> String:
	return CATALOG[id][4]


static func level(team: TeamData, id: StringName) -> int:
	if team.facilities.is_empty():
		seed_default(team)
	return int(team.facilities.get(id, 0))


## A team without a campus: the core buildings at level 1.
static func seed_default(team: TeamData) -> void:
	for id in CATALOG:
		team.facilities[id] = 1 if CORE.has(id) else 0


## Starting campus: stronger teams have more and bigger buildings.
static func seed_for_tier(team: TeamData, tier: int, r: RandomNumberGenerator) -> void:
	for id in CATALOG:
		var lv := clampi(tier + r.randi_range(-1, 1), 0, 5)
		if CORE.has(id):
			lv = maxi(lv, 1)
		elif id == &"engine":
			lv = 0 if tier < 5 else 1
		elif lv > 0 and r.randf() < 0.35 - 0.06 * tier:
			lv = 0
		team.facilities[id] = lv


# --- Effects -------------------------------------------------------------------

## Capacity factor of an R3 department.
static func capacity_factor(team: TeamData, department: StringName) -> float:
	# Level 1 → 5 doubles a department (level 3 ≈ the old average).
	match department:
		&"design":
			return 0.6 + 0.2 * level(team, &"design")
		&"aero":
			return 0.6 + 0.2 * level(team, &"cfd")
		&"tunnel":
			return 0.45 + 0.2 * level(team, &"wind")
		&"rig":
			return 0.6 + 0.2 * level(team, &"lab")
		&"factory":
			return 0.6 + 0.2 * level(team, &"factory")
	return 1.0


static func max_projects(team: TeamData) -> int:
	return 1 + level(team, &"design")


## Multiplier on how far the wind tunnel / rigs can be off.
static func correlation_factor(team: TeamData, aero: bool) -> float:
	return 1.5 - 0.2 * level(team, &"wind") if aero else 1.4 - 0.15 * level(team, &"lab")


## Multiplier on the weight saved by new parts.
static func weight_saving(team: TeamData) -> float:
	return 0.7 + 0.15 * level(team, &"composites")


static func unit_cost_factor(team: TeamData) -> float:
	return 1.15 - 0.07 * level(team, &"factory")


## Headcount the building has room for (R3 departments; hiring R6).
static func room_for(team: TeamData, department: StringName) -> int:
	var reference: int = CarDevelopment.REFERENCE_HEADCOUNT[department]
	return roundi(reference * ROOM[level(team, HOUSES[department])] * 1.3)


## Points added to the weekend staff values (TeamOps).
static func ops_bonus(team: TeamData, id: StringName) -> int:
	var per_level := {&"pit": 5, &"mission": 4, &"simulator": 4, &"performance": 5, &"lab": 3}
	return per_level.get(id, 0) * level(team, id)


## Team mood factor of the staff facilities (−4 .. +6).
static func mood_bonus(team: TeamData) -> int:
	return 2 * level(team, &"staff") - 4


## What a building does at a level: [[label, value, format, better]] – the
## values are compared between levels in the HQ screen; better = 1 when
## higher is better, -1 when lower is better.
static func effect_lines(team: TeamData, id: StringName, at_level: int) -> Array:
	var probe := TeamData.new()
	probe.facilities = team.facilities.duplicate()
	probe.facilities[id] = at_level
	match id:
		&"design":
			return [["Design capacity", capacity_factor(probe, &"design"), "×%.2f"],
				["Parallel development projects", max_projects(probe), "%d"],
				["Room for designers", room_for(probe, &"design"), "%d"]]
		&"wind":
			return [["Wind tunnel capacity", capacity_factor(probe, &"tunnel"), "×%.2f"],
				["Aero forecast error", correlation_factor(probe, true), "×%.2f", -1]]
		&"cfd":
			return [["CFD capacity", capacity_factor(probe, &"aero"), "×%.2f"],
				["Room for aerodynamicists", room_for(probe, &"aero"), "%d"]]
		&"factory":
			return [["Production capacity", capacity_factor(probe, &"factory"), "×%.2f"],
				["Cost per part", unit_cost_factor(probe), "×%.2f", -1],
				["Room for factory staff", room_for(probe, &"factory"), "%d"]]
		&"composites":
			return [["Weight saved by new parts", weight_saving(probe), "×%.2f"]]
		&"lab":
			return [["Test rig capacity", capacity_factor(probe, &"rig"), "×%.2f"],
				["Mechanical forecast error", correlation_factor(probe, false), "×%.2f", -1],
				["Reliability work", ops_bonus(probe, &"lab"), "+%d"],
				["Room for rig engineers", room_for(probe, &"rig"), "%d"]]
		&"simulator":
			return [["Race engineers' setup work", ops_bonus(probe, &"simulator"), "+%d"]]
		&"performance":
			return [["Physical and mental training", ops_bonus(probe, &"performance"), "+%d"]]
		&"pit":
			return [["Pit stop speed and precision", ops_bonus(probe, &"pit"), "+%d"]]
		&"mission":
			return [["Strategy: race, weather and tyre reading", ops_bonus(probe, &"mission"), "+%d"]]
		&"staff":
			return [["Team mood", mood_bonus(probe), "%+d"]]
	return []


# --- Construction --------------------------------------------------------------

static func quote(team: TeamData, id: StringName) -> Dictionary:
	if not CATALOG.has(id):
		return {}
	var target := mini(level(team, id) + 1, 5)
	return {"target": target, "cost": roundi(CATALOG[id][2] * PRICE_FACTOR[target]),
		"duration": roundi(CATALOG[id][3] * (1.0 + TIME_STEP * (target - 1))),
		"upkeep": upkeep_of(id, target) - upkeep_of(id, level(team, id))}


static func upkeep_of(id: StringName, at_level: int) -> int:
	return roundi(CATALOG[id][2] * UPKEEP_SHARE * pow(at_level, UPKEEP_EXPONENT))


static func upkeep_per_month(team: TeamData) -> int:
	var total := 0
	for id in CATALOG:
		total += upkeep_of(id, level(team, id))
	return total


static func unavailable_reason(team: TeamData, id: StringName) -> String:
	if not CATALOG.has(id):
		return "Unknown facility."
	if team.facility_projects.has(id):
		return "Construction is already underway here."
	if level(team, id) >= 5:
		return "Fully upgraded"
	if locked_until(id) != "":
		return Loc.f("Its system comes with %s – building it now would bring nothing.", [locked_until(id)])
	if team.facility_projects.size() >= construction_crews(team):
		return "All construction crews are busy." if construction_crews(team) > 1 else "Finish the current construction project first."
	if team.budget < int(quote(team, id).cost):
		return "Insufficient funds"
	return ""


## Starts building; expected_target guards against a stale quote.
static func start(team: TeamData, id: StringName, expected_target: int = -1) -> String:
	var reason := unavailable_reason(team, id)
	if reason != "":
		return reason
	var offer := quote(team, id)
	if expected_target >= 0 and expected_target != offer.target:
		return "The facility changed. Review the new construction proposal."
	team.budget -= int(offer.cost)
	GameState.hq_spending[team.id] = GameState.hq_spending.get(team.id, 0) + int(offer.cost)
	team.facility_projects[id] = {"target": offer.target, "remaining": offer.duration,
		"duration": offer.duration, "cost": offer.cost}
	EventBus.budget_changed.emit(team.id, team.budget)
	EventBus.facilities_changed.emit(team.id)
	return ""


## Construction projects at the same time: a second crew for big campuses.
static func construction_crews(team: TeamData) -> int:
	return 2 if _total(team) >= SECOND_CREW_LEVELS else 1


## Rank of the campus in the series (sum of levels).
static func campus_rank(team: TeamData) -> int:
	var own := _total(team)
	var rank := 1
	for id in GameState.series[team.series_id].team_ids:
		if _total(GameState.teams[id]) > own:
			rank += 1
	return rank


static func _total(team: TeamData) -> int:
	var total := 0
	for id in CATALOG:
		total += level(team, id)
	return total


# --- Every day / month ---------------------------------------------------------

static func daily_update(r: RandomNumberGenerator) -> void:
	for team: TeamData in GameState.teams.values():
		if team.facility_projects.size() < construction_crews(team) and Calendar.day % 7 == 3 \
				and team.id != GameState.player_team_id:
			_ai_plan(team, r)
		if team.facility_projects.is_empty():
			continue
		for id in team.facility_projects.keys():
			var project: Dictionary = team.facility_projects[id]
			project.remaining -= 1
			if project.remaining <= 0:
				_complete(team, id, int(project.target))
		EventBus.facilities_changed.emit(team.id)


static func _complete(team: TeamData, id: StringName, target: int) -> void:
	team.facilities[id] = target
	team.facility_projects.erase(id)
	GameState.hq_completed[team.id] = GameState.hq_completed.get(team.id, 0) + 1
	if team.id != GameState.player_team_id:
		return
	var msg := InboxMessage.new()
	msg.sender = "Headquarters"
	msg.subject = "Construction complete: %s"
	msg.subject_args = [Loc.t(name_of(id))]
	msg.add_paragraph("%s is now operating at level %d.", [Loc.t(name_of(id)), target])
	for line in effect_lines(team, id, target):
		msg.add_paragraph("%s: %s", [Loc.t(line[0]), line[2] % line[1]])
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "building"
	msg.link_screen = &"hq"
	msg.link_args = {"facility": id}
	msg.link_label = "Open headquarters"
	GameState.add_message(msg)


## AI: builds what helps most for the money while keeping a reserve.
static func _ai_plan(team: TeamData, r: RandomNumberGenerator) -> void:
	if r.randf() > 0.4:
		return
	var reserve := (ContractLogic.payroll_per_month(team.id) + upkeep_per_month(team)) * RESERVE_MONTHS
	var best: StringName = &""
	var best_score := 0.0
	for id in AI_WEIGHT:
		if unavailable_reason(team, id) != "":
			continue
		var offer := quote(team, id)
		if team.budget - int(offer.cost) < reserve:
			continue
		var score: float = AI_WEIGHT[id] * (6 - offer.target) / (offer.cost / 1_000_000.0 + 5.0) * r.randf_range(0.8, 1.2)
		if score > best_score:
			best_score = score
			best = id
	if best != &"":
		start(team, best)
