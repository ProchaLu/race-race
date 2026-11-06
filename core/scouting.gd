## Scouting (R7, docs/youth_model.md, design doc 4.3): the scout network – the
## chief scout and hired scouts – goes after a series, a region, one junior or
## a race weekend. Week by week the team knows the people better; how far that
## goes depends on the scout, and a weak scout can get a person wrong (his
## range is shifted, not just wide). Region trips and karting race visits also
## find hidden karting kids (GameState.discovered).
class_name Scouting
extends RefCounted

const FEE_PER_TARGET := 40_000
## A region trip that also looks for new karting talents.
const DISCOVERY_FEE := 60_000
## Watching one race weekend in person.
const WATCH_FEE := {&"f2": 60_000, &"f3": 50_000, &"karting": 30_000}
## Knowledge gained by everybody in a series when a scout watches the race.
const WATCH_GAIN := 30
## Karting kids a race visit discovers (best finishers first).
const WATCH_DISCOVERIES := 6
## Most people one assignment covers (the best by value come first).
const MAX_TARGETS := 8
## Without any scout the team still looks, but badly.
const NO_SCOUT_SKILL := 10.0
## Knowledge a scout of skill 0 reaches; skill 100 reaches 90 (exact values).
const DONE_BASE := 70.0
const DONE_PER_SKILL := 0.2
## Knowledge gained per week: base plus skill / 12.
const WEEK_BASE := 4.0
## A scout in his home region works this much faster and finds more.
const HOME_BONUS := 1.25
const MIN_REGION_WEEKS := 4
## Scouts for hire at a time; quality range of the candidates.
const CANDIDATES := 3
const CANDIDATE_QUALITY := [35, 78]

const REGIONS := {
	&"europe": ["GB", "DE", "IT", "FR", "ES", "NL", "BE", "AT", "CH", "SE", "NO", "DK", "FI"],
	&"americas": ["US", "CA", "BR", "AR", "MX"],
	&"asia_pacific": ["JP", "CN", "IN", "AU", "NZ"],
}
const REGION_NAMES := {&"europe": "Europe", &"americas": "Americas", &"asia_pacific": "Asia & Pacific"}


static func region_of_nation(nationality: String) -> StringName:
	for region in REGIONS:
		if REGIONS[region].has(nationality):
			return region
	return &"europe"


static func region_of(person: PersonData) -> StringName:
	return region_of_nation(person.nationality)


# --- Scouts --------------------------------------------------------------------

## Assignments at the same time: the level of the scouting office.
static func capacity(team: TeamData) -> int:
	return Facilities.level(team, &"scouting")


## The chief scout and the hired scouts of a team.
static func scouts(team: TeamData) -> Array[StaffData]:
	var out: Array[StaffData] = []
	for s in GameState.staff_of_team(team.id):
		if s.role == StaffData.Role.CHIEF_SCOUT:
			out.push_front(s)
		elif s.role == StaffData.Role.SCOUT:
			out.append(s)
	return out


## Hired scouts on top of the chief scout: one per office level.
static func max_scouts(team: TeamData) -> int:
	return capacity(team)


static func hired(team: TeamData) -> int:
	return scouts(team).filter(func(s): return s.role == StaffData.Role.SCOUT).size()


static func busy(team: TeamData) -> int:
	var n := 0
	for a in GameState.scout_assignments:
		if a.team_id == team.id:
			n += 1
	return n


static func is_busy(s: StaffData) -> bool:
	for a in GameState.scout_assignments:
		if a.get("scout_id", &"") == s.id:
			return true
	return false


## The best scout who is free (null when all are out, or there is none).
static func free_scout(team: TeamData) -> StaffData:
	var best: StaffData = null
	for s in scouts(team):
		if not is_busy(s) and (best == null or scout_skill(s) > scout_skill(best)):
			best = s
	return best


## Free assignment places: office slots, and a free scout to send (without any
## scout the team can still run one assignment, badly).
static func free_slots(team: TeamData) -> int:
	var slots := capacity(team) - busy(team)
	if slots <= 0:
		return 0
	var people := scouts(team)
	if people.is_empty():
		return 1 if busy(team) == 0 else 0
	return mini(slots, people.filter(func(s): return not is_busy(s)).size())


## Why no assignment can start now ("" when one can).
static func blocked_reason(team: TeamData) -> String:
	if capacity(team) <= 0:
		return "Build a scouting office first."
	if busy(team) >= capacity(team):
		return "All scouting slots are busy. Wait until an assignment is finished."
	if free_slots(team) <= 0:
		return "All scouts are out. Hire another scout or wait until one is back."
	return ""


## Average of judging ability and potential (1..100).
static func scout_skill(s: StaffData) -> float:
	if not s:
		return NO_SCOUT_SKILL
	return (s.attribute(&"judging_ability") + s.attribute(&"judging_potential")) / 2.0


## Skill of the best free scout (or of the chief scout).
static func skill(team: TeamData) -> float:
	var s := free_scout(team)
	if not s:
		var all := scouts(team)
		s = all[0] if not all.is_empty() else null
	return scout_skill(s)


## Knowledge (0..100) that an assignment reaches with this skill.
static func done_level(scout_skill_value: float) -> int:
	return roundi(DONE_BASE + DONE_PER_SKILL * scout_skill_value)


static func weekly_gain(scout_skill_value: float) -> float:
	return WEEK_BASE + scout_skill_value / 12.0


## Scouts the team could hire now (free people; new ones appear when needed).
static func candidates(r: RandomNumberGenerator = null) -> Array[StaffData]:
	var out: Array[StaffData] = []
	for s in GameState.staff.values():
		if s.role == StaffData.Role.SCOUT and s.team_id == &"" and not s.retired:
			out.append(s)
	if out.size() < CANDIDATES:
		if r == null:
			r = RandomNumberGenerator.new()
			r.randomize()
		while out.size() < CANDIDATES:
			var s := PersonGenerator.staff(r, StaffData.Role.SCOUT, r.randi_range(CANDIDATE_QUALITY[0], CANDIDATE_QUALITY[1]))
			GameState.add_staff(s)
			out.append(s)
	out.sort_custom(func(a, b): return scout_skill(a) > scout_skill(b))
	return out


static func salary_of(s: StaffData) -> int:
	return roundi(StaffRoles.base_salary(StaffData.Role.SCOUT) * (0.6 + scout_skill(s) / 100.0) / 10_000.0) * 10_000


## Hires a scout for two seasons. Returns "" or the reason.
static func hire(team: TeamData, s: StaffData) -> String:
	if s.team_id != &"":
		return "This scout already works for a team."
	if hired(team) >= max_scouts(team):
		return "No room for another scout. A larger scouting office makes room."
	var c := ContractData.new()
	c.person_id = s.id
	c.team_id = team.id
	c.salary = salary_of(s)
	c.start_year = Calendar.year
	c.end_year = Calendar.year + 1
	GameState.contracts.append(c)
	s.team_id = team.id
	team.staff_ids.append(s.id)
	GameState.knowledge[s.id] = 100
	return ""


## Lets a hired scout go (severance as for any staff member).
static func dismiss(s: StaffData) -> void:
	for i in range(GameState.scout_assignments.size() - 1, -1, -1):
		if GameState.scout_assignments[i].get("scout_id", &"") == s.id:
			GameState.scout_assignments[i].scout_id = &""
	ContractLogic.release(s)


# --- Targets -------------------------------------------------------------------

## Juniors of a series: the teams' drivers (F3 or F2 teams), best first.
static func targets_of_series(series_id: StringName) -> Array[StringName]:
	var people: Array[DriverData] = []
	for t in GameState.youth_teams.values():
		if t.series_id == series_id:
			for id in t.driver_ids:
				people.append(GameState.drivers[id])
	return _best(people)


## Juniors from a region the team can see (any level, the pool included).
static func targets_of_region(region: StringName) -> Array[StringName]:
	var people: Array[DriverData] = []
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and Youth.is_visible(d) and region_of(d) == region:
			people.append(d)
	return _best(people)


## Hidden karting kids of a region (nobody of ours has seen them yet).
static func hidden_of_region(region: StringName) -> Array[DriverData]:
	var out: Array[DriverData] = []
	for d in Youth.karting():
		if region_of(d) == region and not Youth.is_visible(d):
			out.append(d)
	return out


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
	var scout_skill_value := skill(team)
	var goal := done_level(scout_skill_value)
	var weeks := 0
	for id in todo_of(team, ids):
		var known := Knowledge.level(GameState.drivers[id])
		weeks = maxi(weeks, ceili((goal - known) / weekly_gain(scout_skill_value)))
	return weeks


## How many karting kids a region trip finds: more with a good network, more
## in the scout's home region, never more than are hidden there.
static func discoveries_of(s: StaffData, region: StringName) -> int:
	var n := 2 + roundi((s.attribute(&"network") if s else 10) / 20.0)
	if s and region_of(s) == region:
		n += 2
	return mini(n, hidden_of_region(region).size())


# --- Assignments ---------------------------------------------------------------

## Starts an assignment for the given people with the best free scout.
## kind: &"series", &"region" (also discovers karting kids), &"driver".
## Returns "" or the reason it cannot start.
static func start(team: TeamData, kind: StringName, label: String, ids: Array[StringName], region: StringName = &"") -> String:
	var blocked := blocked_reason(team)
	if blocked != "":
		return blocked
	var s := free_scout(team)
	var todo := todo_of(team, ids)
	var finds := discoveries_of(s, region) if kind == &"region" and region != &"" else 0
	if todo.is_empty() and finds == 0:
		return "Nothing new to find out there."
	var skill_value := scout_skill(s)
	var home := s != null and region != &"" and region_of(s) == region
	var weeks := maxi(1, weeks_needed(team, todo))
	var cost := FEE_PER_TARGET * todo.size()
	if kind == &"region":
		weeks = maxi(weeks, MIN_REGION_WEEKS)
		cost += DISCOVERY_FEE
	if home:
		weeks = maxi(1, ceili(weeks / HOME_BONUS))
	Finance.pay(team, &"scouting", cost)
	GameState.scout_assignments.append({"id": GameState.next_scout_id, "team_id": team.id, "kind": kind,
		"label": label, "targets": todo, "weeks_left": weeks, "weeks_total": weeks, "skill": skill_value,
		"scout_id": s.id if s else &"", "region": region, "home": home, "found": []})
	GameState.next_scout_id += 1
	return ""


## A scout watches the next race weekend of a series (f2, f3 or a karting key)
## in person: everybody there becomes better known, karting visits find kids.
static func watch(team: TeamData, key: StringName) -> String:
	var blocked := blocked_reason(team)
	if blocked != "":
		return blocked
	for a in GameState.scout_assignments:
		if a.team_id == team.id and a.kind == &"race" and a.series == key:
			return "A scout is already going to that race."
	var s := free_scout(team)
	Finance.pay(team, &"scouting", watch_fee(key))
	GameState.scout_assignments.append({"id": GameState.next_scout_id, "team_id": team.id, "kind": &"race",
		"label": Youth.series_name(key), "targets": [], "weeks_left": 0, "weeks_total": 0, "skill": scout_skill(s),
		"scout_id": s.id if s else &"", "series": key, "region": &"", "home": false, "found": []})
	GameState.next_scout_id += 1
	return ""


static func watch_fee(key: StringName) -> int:
	return WATCH_FEE.get(key, WATCH_FEE[&"karting"])


## Once a week: every running assignment learns a little more about its people.
static func weekly_update(r: RandomNumberGenerator) -> void:
	for a in GameState.scout_assignments.duplicate():
		if a.kind == &"race":
			continue
		a.weeks_left -= 1
		var gain := weekly_gain(a.skill) * (HOME_BONUS if a.get("home", false) else 1.0)
		var goal := done_level(a.skill)
		for id in a.targets:
			var d: DriverData = GameState.drivers.get(id)
			if d and Knowledge.level(d) < 100:
				GameState.knowledge[id] = mini(goal, roundi(Knowledge.level(d) + gain))
		if a.weeks_left <= 0:
			_finish(a, r)


## After each junior round: the scouts at the race report.
static func after_round() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	for a in GameState.scout_assignments.duplicate():
		if a.kind != &"race":
			continue
		var key: StringName = a.series
		var goal := done_level(a.skill)
		var st := Youth.standings(key)
		var finishers: Array = st.get("last", {}).keys()
		finishers.sort_custom(func(x, y):
			var px: int = st.last[x] if st.last[x] > 0 else 99
			var py: int = st.last[y] if st.last[y] > 0 else 99
			return px < py)
		var found := 0
		for id in finishers:
			var d: DriverData = GameState.drivers.get(id)
			if not d or Knowledge.level(d) >= 100:
				continue
			if not Youth.is_visible(d):
				if found >= WATCH_DISCOVERIES:
					continue
				_discover(d, a, r)
				found += 1
			GameState.knowledge[id] = mini(goal, Knowledge.level(d) + WATCH_GAIN)
			a.targets.append(id)
		_finish(a, r)


## Ends an assignment: the knowledge is final, a weak scout may have got a
## person wrong, a region trip finds karting kids, the scout reports.
static func _finish(a: Dictionary, r: RandomNumberGenerator) -> void:
	var goal := done_level(a.skill)
	if a.kind == &"region" and a.get("region", &"") != &"":
		var s: StaffData = GameState.staff.get(a.get("scout_id", &""))
		var hidden := hidden_of_region(a.region)
		# Good kids stand out more; a good eye for potential spots the gems.
		var eye: float = s.attribute(&"judging_potential") if s else 10.0
		var scored := []
		for d in hidden:
			var stand_out := Youth.season_points(d) * 0.4 + d.overall() * 0.5 + r.randf() * 25.0
			stand_out += (d.potential - d.overall()) * eye / 250.0
			scored.append([d, stand_out])
		scored.sort_custom(func(x, y): return x[1] > y[1])
		for i in mini(discoveries_of(s, a.region), scored.size()):
			var d: DriverData = scored[i][0]
			_discover(d, a, r)
			GameState.knowledge[d.id] = maxi(Knowledge.level(d), goal - 20)
	# Chance to misjudge: 50 % with skill 0, none from skill 100 on.
	var miss := clampf(0.5 - a.skill / 200.0, 0.0, 0.5)
	for id in a.targets:
		var d: DriverData = GameState.drivers.get(id)
		if not d or Knowledge.level(d) >= 100:
			continue
		if a.kind != &"race":
			GameState.knowledge[id] = goal
		if r.randf() < miss:
			GameState.scout_bias[id] = {"ability": _shift(r), "potential": _shift(r)}
		else:
			GameState.scout_bias.erase(id)
	for i in range(GameState.scout_assignments.size() - 1, -1, -1):
		if GameState.scout_assignments[i].id == a.id:
			GameState.scout_assignments.remove_at(i)
	if a.team_id == GameState.player_team_id:
		_report(a)


static func _discover(d: DriverData, a: Dictionary, r: RandomNumberGenerator) -> void:
	GameState.discovered[d.id] = true
	a.found.append(d.id)
	if not a.targets.has(d.id):
		a.targets.append(d.id)
	if r.randf() < clampf(0.5 - a.skill / 200.0, 0.0, 0.5):
		GameState.scout_bias[d.id] = {"ability": _shift(r), "potential": _shift(r)}


static func _shift(r: RandomNumberGenerator) -> int:
	return r.randi_range(1, 3) * (1 if r.randf() < 0.5 else -1)


static func _report(a: Dictionary) -> void:
	var msg := InboxMessage.new()
	var s: StaffData = GameState.staff.get(a.get("scout_id", &""))
	msg.sender = s.full_name() if s else "Chief scout"
	msg.subject = "Scouting report: %s"
	msg.subject_args = [a.label]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "binoculars"
	if not a.found.is_empty():
		var names := []
		for id in a.found:
			var d: DriverData = GameState.drivers.get(id)
			if d:
				names.append("%s (%d, %s)" % [d.full_name(), d.age(Calendar.year), d.nationality])
		msg.add_paragraph("New talents found in karting: %s.", [", ".join(names)])
	for id in a.targets:
		var d: DriverData = GameState.drivers.get(id)
		if d:
			msg.add_paragraph("%s (%d): %s.", [d.full_name(), d.age(Calendar.year), recommendation(d)])
	if a.targets.is_empty() and a.found.is_empty():
		msg.add_paragraph("Nobody new caught the eye this time.")
	msg.link_screen = &"scouting"
	msg.link_args = {}
	msg.link_label = "Open scouting"
	GameState.add_message(msg)


# --- Advice and reports ----------------------------------------------------------

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


## The scout's written report: [[translation key, args], ...]. What it says
## depends on how well the junior is known.
static func report_lines(d: DriverData) -> Array:
	var k := Knowledge.level(d)
	var out := []
	if k < 30:
		out.append(["Only a first impression so far. Send a scout to learn more.", []])
		return out
	var known := []
	for entry in DriverAttributes.DRIVING:
		var rng := Knowledge.display_range(d, entry[0], d.get(entry[0]))
		known.append([TranslationServer.translate(entry[1]), (rng.x + rng.y) / 2.0])
	known.sort_custom(func(a, b): return a[1] > b[1])
	out.append(["Strengths: %s.", [", ".join([known[0][0], known[1][0], known[2][0]])]])
	out.append(["Weaknesses: %s.", [", ".join([known[-1][0], known[-2][0]])]])
	if k >= 60:
		if d.work_ethic >= 65:
			out.append(["Works very hard.", []])
		if d.composure >= 65:
			out.append(["Calm under pressure.", []])
		if d.temperament <= 35:
			out.append(["Hot-headed, can lose his temper.", []])
		if d.ambition >= 70:
			out.append(["Very ambitious, wants to reach F1 quickly.", []])
		if d.professionalism <= 35:
			out.append(["Not always professional.", []])
		var like := _similar_f1_driver(d)
		if like:
			out.append(["Drives a bit like %s.", [like.full_name()]])
	if k >= 70 and d.talent == &"late_bloomer":
		out.append(["Still raw, but he learns fast. He could bloom late.", []])
	if k >= 70 and d.talent == &"wonderkid":
		out.append(["A rare talent. I have not seen anything like it for years.", []])
	if k >= 80:
		out.append(["I am sure about this assessment.", []])
	elif k >= 55:
		out.append(["Fairly sure about this assessment.", []])
	else:
		out.append(["A rough assessment, it can still be wrong.", []])
	return out


## The F1 race driver whose driving profile looks most like the junior's.
static func _similar_f1_driver(d: DriverData) -> DriverData:
	var best: DriverData = null
	var best_score := INF
	var mine := _profile(d)
	for t in GameState.teams.values():
		for id in t.driver_ids:
			var other: DriverData = GameState.drivers.get(id)
			if not other:
				continue
			var theirs := _profile(other)
			var score := 0.0
			for i in mine.size():
				score += absf(mine[i] - theirs[i])
			if score < best_score:
				best_score = score
				best = other
	return best


## Driving attributes relative to the driver's own average (style, not level).
static func _profile(d: DriverData) -> Array:
	var values := []
	var sum := 0.0
	for entry in DriverAttributes.DRIVING:
		values.append(float(d.get(entry[0])))
		sum += d.get(entry[0])
	var mean := sum / values.size()
	return values.map(func(v): return v - mean)
