## Team mood (design doc 5.5): one value 0..100 built from the morale of
## drivers and staff, recent results, the relationship with the team
## principal and recent events (releases, broken promises, ...).
## Events fade out over EVENT_FADE_DAYS.
class_name TeamMood
extends RefCounted

## [upper limit (exclusive), name]
const LEVELS := [[20, "Crisis"], [40, "Tense"], [60, "Calm"], [80, "Good"], [101, "Euphoria"]]
const EVENT_FADE_DAYS := 60
const TREND_DAYS := 7


static func value(team_id: StringName) -> int:
	var total := 50
	for f in factors(team_id):
		total += f[1]
	return clampi(total, 0, 100)


static func level_name(v: int) -> String:
	for level in LEVELS:
		if v < level[0]:
			return level[1]
	return LEVELS.back()[1]


## Index 0..4 of the level (Crisis .. Euphoria).
static func level_index(v: int) -> int:
	for i in LEVELS.size():
		if v < LEVELS[i][0]:
			return i
	return LEVELS.size() - 1


## Each factor: [label (already translated), delta]
static func factors(team_id: StringName) -> Array:
	var out := []
	var drivers := GameState.drivers_of_team(team_id)
	if not drivers.is_empty():
		var avg := 0.0
		for d in drivers:
			avg += d.morale
		avg /= drivers.size()
		out.append([Loc.f("Driver morale (average %d)", [roundi(avg)]), roundi((avg - 50) * 0.4)])
	var staff := GameState.staff_of_team(team_id)
	if not staff.is_empty():
		var avg := 0.0
		for s in staff:
			avg += s.morale
		avg /= staff.size()
		out.append([Loc.f("Staff morale (average %d)", [roundi(avg)]), roundi((avg - 50) * 0.3)])
	var results := _results_factor(team_id, drivers)
	if not results.is_empty():
		out.append(results)
	var relationship := _relationship_factor(team_id, drivers, staff)
	if relationship != 0:
		out.append([Loc.t("Relationship with you"), relationship])
	var now := _today()
	for e in GameState.mood_events:
		if e.team_id != team_id:
			continue
		var fade: float = 1.0 - (now - e.when) / float(EVENT_FADE_DAYS)
		var delta := roundi(e.delta * fade)
		if fade > 0.0 and delta != 0:
			out.append([Loc.f(e.key, e.args) if not e.args.is_empty() else Loc.t(e.key), delta])
	return out


static func breakdown(team_id: StringName) -> Breakdown:
	var v := value(team_id)
	var b := Breakdown.new(Loc.f("Team mood: %s (%d / 100)", [Loc.t(level_name(v)), v]),
		"Affects the productivity of all departments (up to ±5 %), mistakes in the pit lane and how easily rivals poach your staff.")
	b.add("Neutral base", "50")
	for f in factors(team_id):
		b.add_delta(f[0], f[1])
	return b


## Change compared to TREND_DAYS ago (0 if unknown).
static func trend(team_id: StringName) -> int:
	var history: Dictionary = GameState.mood_history.get(team_id, {})
	var past: int = history.get(_today() - TREND_DAYS, -1)
	return value(team_id) - past if past >= 0 else 0


## Records a one-off event, e.g. a release or a broken promise.
static func add_event(team_id: StringName, key: String, args: Array, delta: int) -> void:
	GameState.mood_events.append({"team_id": team_id, "when": _today(), "key": key, "args": args, "delta": delta})


## Changes one person's morale with a visible reason (drivers keep a list
## of reasons that the morale tooltip shows).
static func change_morale(person: PersonData, reason: String, delta: int) -> void:
	if person is DriverData:
		var d := person as DriverData
		d.morale_factors[reason] = d.morale_factors.get(reason, 0) + delta
		d.recalculate_morale()
	else:
		person.morale = clampi(person.morale + delta, 0, 100)


## Called once a day: stores today's value for the trend, drops old events.
static func daily_update() -> void:
	var now := _today()
	for team_id in GameState.teams:
		var history: Dictionary = GameState.mood_history.get_or_add(team_id, {})
		history[now] = value(team_id)
		for day in history.keys():
			if day < now - TREND_DAYS * 2:
				history.erase(day)
	GameState.mood_events = GameState.mood_events.filter(func(e): return now - e.when < EVENT_FADE_DAYS)


## Results of the last three rounds compared with what the car should achieve.
static func _results_factor(team_id: StringName, drivers: Array[DriverData]) -> Array:
	var best_finishes := []
	var round_count := GameState.rounds_completed()
	for r in range(maxi(1, round_count - 2), round_count + 1):
		var best := 99
		for d in drivers:
			var stats: DriverSeasonStats = GameState.season_stats.get(d.id)
			if not stats:
				continue
			for result in stats.results:
				if result.round == r and result.finish > 0:
					best = mini(best, result.finish)
		if best < 99:
			best_finishes.append(best)
	if best_finishes.is_empty():
		return []
	var avg := 0.0
	for f in best_finishes:
		avg += f
	avg /= best_finishes.size()
	var expected := car_rank(team_id) * 1.8
	var labels := PackedStringArray()
	for f in best_finishes:
		labels.append("P%d" % f)
	return [Loc.f("Recent results (%s)", [", ".join(labels)]), clampi(roundi(expected - avg), -10, 10)]


static func _relationship_factor(team_id: StringName, drivers: Array[DriverData], staff: Array[StaffData]) -> int:
	if team_id != GameState.player_team_id:
		return 0
	var total := 0
	var count := 0
	for p in drivers + staff:
		total += GameState.relationship(p.id, GameState.PLAYER_ID).value
		count += 1
	return roundi(total / 10.0 / maxf(count, 1) * 2.0)


static func car_rank(team_id: StringName) -> int:
	var levels := []
	for t in GameState.teams.values():
		levels.append([t.id, t.car.downforce + t.car.engine_power + t.car.mechanical_grip])
	levels.sort_custom(func(a, b): return a[1] > b[1])
	for i in levels.size():
		if levels[i][0] == team_id:
			return i + 1
	return levels.size()


## Days since the start of the career (continues across seasons).
static func _today() -> int:
	return (Calendar.year - Calendar.START_YEAR) * Calendar.DAYS_PER_SEASON + Calendar.day
