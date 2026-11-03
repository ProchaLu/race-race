## Scouting (R7, docs/youth_model.md, design doc 4.3): assignments send the
## chief scout after a series, a region or one junior. Week by week the team
## knows the people better. How far that goes depends on the scout; a weak
## scout can also get a person wrong (his range is shifted, not just wide).
class_name Scouting
extends RefCounted

const FEE_PER_TARGET := 40_000
## Most people one assignment covers (the best by value come first).
const MAX_TARGETS := 8
## Without a chief scout the team still looks, but badly.
const NO_SCOUT_SKILL := 10.0
## Knowledge a scout of skill 0 reaches; skill 100 reaches 90 (exact values).
const DONE_BASE := 70.0
const DONE_PER_SKILL := 0.2
## Knowledge gained per week: base plus skill / 12.
const WEEK_BASE := 4.0

const REGIONS := {
	&"europe": ["GB", "DE", "IT", "FR", "ES", "NL", "BE", "AT", "CH", "SE", "NO", "DK", "FI"],
	&"americas": ["US", "CA", "BR", "AR", "MX"],
	&"asia_pacific": ["JP", "CN", "IN", "AU", "NZ"],
}
const REGION_NAMES := {&"europe": "Europe", &"americas": "Americas", &"asia_pacific": "Asia & Pacific"}


static func capacity(team: TeamData) -> int:
	return Facilities.level(team, &"scouting")


static func busy(team: TeamData) -> int:
	var n := 0
	for a in GameState.scout_assignments:
		if a.team_id == team.id:
			n += 1
	return n


static func free_slots(team: TeamData) -> int:
	return maxi(0, capacity(team) - busy(team))


## Average of the chief scout's judging ability and potential (1..100).
static func skill(team: TeamData) -> float:
	var chief := Knowledge.chief_scout()
	if chief and chief.team_id == team.id:
		return (chief.attribute(&"judging_ability") + chief.attribute(&"judging_potential")) / 2.0
	return NO_SCOUT_SKILL


## Knowledge (0..100) that an assignment reaches with this skill.
static func done_level(scout_skill: float) -> int:
	return roundi(DONE_BASE + DONE_PER_SKILL * scout_skill)


static func weekly_gain(scout_skill: float) -> float:
	return WEEK_BASE + scout_skill / 12.0


## Juniors of a series: the teams' drivers (F3 or F2 teams), best first.
static func targets_of_series(series_id: StringName) -> Array[StringName]:
	var people: Array[DriverData] = []
	for t in GameState.youth_teams.values():
		if t.series_id == series_id:
			for id in t.driver_ids:
				people.append(GameState.drivers[id])
	return _best(people)


## Juniors from a region (any level, the pool included).
static func targets_of_region(region: StringName) -> Array[StringName]:
	var people: Array[DriverData] = []
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and REGIONS[region].has(d.nationality):
			people.append(d)
	return _best(people)


static func _best(people: Array[DriverData]) -> Array[StringName]:
	var live: Array[DriverData] = []
	for d in people:
		if not d.retired:
			live.append(d)
	live.sort_custom(func(a, b): return Youth.value(a) > Youth.value(b))
	var out: Array[StringName] = []
	for d in live:
		if out.size() >= MAX_TARGETS:
			break
		out.append(d.id)
	return out


## The people of ids that still need scouting (the others are known well enough).
static func todo_of(team: TeamData, ids: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	var goal := done_level(skill(team))
	for id in ids:
		var d: DriverData = GameState.drivers.get(id)
		if d and Knowledge.level(d) < goal:
			out.append(id)
	return out


## Weeks until the slowest of ids is scouted (0 when nothing is left to do).
static func weeks_needed(team: TeamData, ids: Array[StringName]) -> int:
	var scout_skill := skill(team)
	var goal := done_level(scout_skill)
	var weeks := 0
	for id in todo_of(team, ids):
		var known := Knowledge.level(GameState.drivers[id])
		weeks = maxi(weeks, ceili((goal - known) / weekly_gain(scout_skill)))
	return weeks


## Starts an assignment for the given people. Returns "" or the reason it cannot start.
static func start(team: TeamData, kind: StringName, label: String, ids: Array[StringName]) -> String:
	if capacity(team) <= 0:
		return "Build a scouting office first."
	if free_slots(team) <= 0:
		return "All scouting slots are busy. Wait until an assignment is finished."
	var todo := todo_of(team, ids)
	if todo.is_empty():
		return "Nothing new to find out there."
	var weeks := weeks_needed(team, todo)
	Finance.pay(team, &"scouting", FEE_PER_TARGET * todo.size())
	GameState.scout_assignments.append({"id": GameState.next_scout_id, "team_id": team.id, "kind": kind,
		"label": label, "targets": todo, "weeks_left": weeks, "weeks_total": weeks, "skill": skill(team)})
	GameState.next_scout_id += 1
	return ""


## Once a week: every running assignment learns a little more about its people.
static func weekly_update(r: RandomNumberGenerator) -> void:
	for a in GameState.scout_assignments.duplicate():
		a.weeks_left -= 1
		var gain := weekly_gain(a.skill)
		var goal := done_level(a.skill)
		for id in a.targets:
			var d: DriverData = GameState.drivers.get(id)
			if d and Knowledge.level(d) < 100:
				GameState.knowledge[id] = mini(goal, roundi(Knowledge.level(d) + gain))
		if a.weeks_left <= 0:
			_finish(a, r)


## Ends an assignment: the knowledge is final, a weak scout may have got a
## person wrong, the chief scout reports to the inbox.
static func _finish(a: Dictionary, r: RandomNumberGenerator) -> void:
	var goal := done_level(a.skill)
	# Chance to misjudge: 50 % with skill 0, none from skill 100 on.
	var miss := clampf(0.5 - a.skill / 200.0, 0.0, 0.5)
	for id in a.targets:
		var d: DriverData = GameState.drivers.get(id)
		if not d or Knowledge.level(d) >= 100:
			continue
		GameState.knowledge[id] = goal
		if r.randf() < miss:
			GameState.scout_bias[id] = {"ability": _shift(r), "potential": _shift(r)}
		else:
			GameState.scout_bias.erase(id)
	for i in range(GameState.scout_assignments.size() - 1, -1, -1):
		if GameState.scout_assignments[i].id == a.id:
			GameState.scout_assignments.remove_at(i)
	_report(a)


static func _shift(r: RandomNumberGenerator) -> int:
	return r.randi_range(1, 3) * (1 if r.randf() < 0.5 else -1)


static func _report(a: Dictionary) -> void:
	var msg := InboxMessage.new()
	msg.sender = "Chief scout"
	msg.subject = "Scouting report: %s"
	msg.subject_args = [a.label]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "binoculars"
	for id in a.targets:
		var d: DriverData = GameState.drivers.get(id)
		if d:
			msg.add_paragraph("%s (%d): %s.", [d.full_name(), d.age(Calendar.year), recommendation(d)])
	msg.link_screen = &"scouting"
	msg.link_args = {}
	msg.link_label = "Open scouting"
	GameState.add_message(msg)


## The chief scout's advice, as a translation key. Based on what is known:
## the potential as the team sees it (range) and the age.
static func recommendation(d: DriverData) -> String:
	if Knowledge.level(d) < 40:
		return "Too little known yet"
	if d.age(Calendar.year) > 21:
		return "Not interesting"
	var stars := Knowledge.star_range(d, &"potential", d.potential)
	var mid := (stars.x + stars.y) / 2.0
	if mid >= 4.0:
		return "Sign now"
	if mid >= 3.0:
		return "Keep watching"
	return "Not interesting"
