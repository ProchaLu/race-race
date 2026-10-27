## The whole game world (autoload "GameState").
## All entities are stored in dictionaries keyed by ID.
extends Node

## ID used for the player (team principal) in relationships.
const PLAYER_ID := &"player"

var series: Dictionary[StringName, SeriesData] = {}
var teams: Dictionary[StringName, TeamData] = {}
var drivers: Dictionary[StringName, DriverData] = {}
var staff: Dictionary[StringName, StaffData] = {}
var sponsors: Dictionary[StringName, SponsorData] = {}
var tracks: Dictionary[StringName, TrackData] = {}
var contracts: Array[ContractData] = []
var promises: Array[PromiseData] = []
## Constructors' points this season per team.
var team_points: Dictionary[StringName, int] = {}
## Detailed results of the player series this season, one per round (RaceWeekend.summarize).
var race_results: Array[Dictionary] = []
## Current season statistics per driver.
var season_stats: Dictionary[StringName, DriverSeasonStats] = {}
## One review per finished season (Season._season_review), oldest first.
var season_history: Array[Dictionary] = []
## Car development projects of all teams (CarDevelopment), oldest first.
var car_projects: Array[DevProject] = []
var next_project_id: int = 1
## True: the technical director plans the player's car development.
var delegate_car_development: bool = true
## Money spent on car development this season per team.
var car_spending: Dictionary = {}
## Money spent on HQ construction this season per team.
var hq_spending: Dictionary = {}
## Building levels completed this season per team.
var hq_completed: Dictionary = {}
## Correlated parts per "team|aero" / "team|rig" – the team learns its tools.
var correlation_experience: Dictionary = {}
## Year whose end-of-season overlay is still to be shown (-1 = none).
var pending_summary: int = -1
## Relationships between two people. Key: "id_a|id_b" (sorted).
## Value: {"value": -100..100, "factors": {reason: delta}}
var relationships: Dictionary = {}
## Tyre compounds, ordered softest first.
var tyre_compounds: Array[TyreCompound] = []
## Newest message last.
var inbox: Array[InboxMessage] = []
var agents: Dictionary[StringName, AgentData] = {}
## What the player's team knows about each person (0..100), see Knowledge.
var knowledge: Dictionary[StringName, int] = {}
var shortlist: Array[StringName] = []
## Open negotiations by person ID (kept while the player browses).
var negotiations: Dictionary = {}
## Agreed deals waiting for the signature: {"person_id", "terms", "sign_day", "kind"}
var pending_signings: Array[Dictionary] = []
## Person ID -> day until which they refuse new talks.
var talk_cooldown: Dictionary = {}
## One-off events for the team mood: {"team_id", "when", "key", "args", "delta"}
var mood_events: Array = []
## Team ID -> {career day: mood value}, for the trend.
var mood_history: Dictionary = {}
## 1-on-1 talks per driver: {"known": {tone: true}, "last_tone", "history", "last_request"}
var talk_memory: Dictionary = {}
## Shortlist notices already sent: "person_id:kind" -> true
var shortlist_notes: Dictionary = {}
## Number of rounds of the player's series already raced this season.
var resolved_rounds: int = 0

## The team controlled by the player.
var player_team_id: StringName


func clear() -> void:
	series.clear()
	teams.clear()
	drivers.clear()
	staff.clear()
	sponsors.clear()
	tracks.clear()
	contracts.clear()
	promises.clear()
	season_stats.clear()
	season_history.clear()
	pending_summary = -1
	car_projects.clear()
	next_project_id = 1
	delegate_car_development = true
	car_spending.clear()
	hq_spending.clear()
	hq_completed.clear()
	correlation_experience.clear()
	team_points.clear()
	race_results.clear()
	relationships.clear()
	tyre_compounds.clear()
	inbox.clear()
	agents.clear()
	knowledge.clear()
	shortlist.clear()
	negotiations.clear()
	pending_signings.clear()
	talk_cooldown.clear()
	mood_events.clear()
	mood_history.clear()
	shortlist_notes.clear()
	talk_memory.clear()
	resolved_rounds = 0
	player_team_id = &""


func player_team() -> TeamData:
	return teams.get(player_team_id)


func add_team(team: TeamData) -> void:
	teams[team.id] = team


func add_driver(driver: DriverData) -> void:
	drivers[driver.id] = driver


func add_staff(person: StaffData) -> void:
	staff[person.id] = person


func drivers_of_team(team_id: StringName) -> Array[DriverData]:
	var result: Array[DriverData] = []
	var team := teams.get(team_id) as TeamData
	if team:
		for driver_id in team.driver_ids:
			if drivers.has(driver_id):
				result.append(drivers[driver_id])
	return result


## Any person (driver, staff or agent) by ID.
func find_person(id: StringName) -> PersonData:
	if drivers.has(id):
		return drivers[id]
	if staff.has(id):
		return staff[id]
	return agents.get(id)


func staff_of_team(team_id: StringName) -> Array[StaffData]:
	var result: Array[StaffData] = []
	var team := teams.get(team_id) as TeamData
	if team:
		for staff_id in team.staff_ids:
			if staff.has(staff_id):
				result.append(staff[staff_id])
	return result


func free_drivers() -> Array[DriverData]:
	var result: Array[DriverData] = []
	for d in drivers.values():
		if d.team_id == &"" and not d.retired:
			result.append(d)
	return result


func free_staff() -> Array[StaffData]:
	var result: Array[StaffData] = []
	for s in staff.values():
		if s.team_id == &"" and not s.retired:
			result.append(s)
	return result


func toggle_shortlist(id: StringName) -> void:
	if shortlist.has(id):
		shortlist.erase(id)
	else:
		shortlist.append(id)


## Opens (or continues) talks with a person. Returns null if they refuse.
func negotiation_with(id: StringName) -> Negotiation:
	if negotiations.has(id) and negotiations[id].state == Negotiation.State.OPEN:
		return negotiations[id]
	if talk_cooldown.get(id, -1) > Calendar.day:
		return null
	var p := find_person(id)
	var kind := Negotiation.Kind.EXTEND if p.team_id == player_team_id else Negotiation.Kind.SIGN
	var n := Negotiation.new(p, kind)
	negotiations[id] = n
	return n


## Called by the negotiation screen when talks end.
func close_negotiation(n: Negotiation) -> void:
	var own := n.kind == Negotiation.Kind.EXTEND
	if n.state == Negotiation.State.AGREED:
		pending_signings.append({"person_id": n.person.id, "terms": n.offer.duplicate(),
			"sign_day": Calendar.day + randi_range(2, 4), "kind": n.kind})
		if own:
			TeamMood.change_morale(n.person, "New contract agreed", 6)
	elif n.state == Negotiation.State.FAILED:
		talk_cooldown[n.person.id] = Calendar.day + 30
		if own:
			TeamMood.change_morale(n.person, "Contract talks failed", -10)
			TeamMood.add_event(player_team_id, "Contract talks with %s failed", [n.person.full_name()], -3)
	negotiations.erase(n.person.id)


func pending_signing_of(id: StringName) -> Dictionary:
	for p in pending_signings:
		if p.person_id == id:
			return p
	return {}


func teammate_of(driver: DriverData) -> DriverData:
	for other in drivers_of_team(driver.team_id):
		if other != driver:
			return other
	return null


## Newest active contract of a person, or null.
func contract_of(person_id: StringName) -> ContractData:
	for contract in contracts:
		if contract.person_id == person_id:
			return contract
	return null


func race_engineer_of(driver_id: StringName) -> StaffData:
	for person in staff.values():
		if person.role == StaffData.Role.RACE_ENGINEER and person.assigned_driver_id == driver_id:
			return person
	return null


func promises_to(person_id: StringName) -> Array[PromiseData]:
	var result: Array[PromiseData] = []
	for p in promises:
		if p.person_id == person_id:
			result.append(p)
	return result


# --- Relationships -----------------------------------------------------------

func set_relationship(a: StringName, b: StringName, factors: Dictionary) -> void:
	var value := 0
	for delta in factors.values():
		value += delta
	relationships[_pair_key(a, b)] = {"value": clampi(value, -100, 100), "factors": factors}


## Returns {"value": int, "factors": Dictionary}; neutral if unknown.
func relationship(a: StringName, b: StringName) -> Dictionary:
	return relationships.get(_pair_key(a, b), {"value": 0, "factors": {}})


func _pair_key(a: StringName, b: StringName) -> String:
	return "%s|%s" % [a, b] if String(a) < String(b) else "%s|%s" % [b, a]


# --- Championship ------------------------------------------------------------

## Driver IDs of a series ordered by points (most first).
func driver_standings(series_id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for driver in drivers.values():
		if season_stats.has(driver.id) and season_stats[driver.id].races() > 0 \
				and (driver.series_id == series_id or driver.team_id == &""):
			ids.append(driver.id)
	ids.sort_custom(func(a, b): return season_stats[a].points > season_stats[b].points)
	return ids


func championship_position(driver_id: StringName) -> int:
	var driver: DriverData = drivers.get(driver_id)
	if not driver:
		return 0
	return driver_standings(driver.series_id).find(driver_id) + 1


## Index of the next race in the player's series calendar, or -1.
func next_round_index() -> int:
	var s: SeriesData = series.get(player_team().series_id)
	return resolved_rounds if resolved_rounds < s.calendar.size() else -1


func rounds_completed() -> int:
	return resolved_rounds


# --- Inbox -------------------------------------------------------------------

func add_message(msg: InboxMessage) -> void:
	msg.year = Calendar.year
	msg.day = Calendar.day
	inbox.append(msg)
	EventBus.inbox_message_added.emit(msg)
	EventBus.inbox_changed.emit()


func unread_count() -> int:
	var count := 0
	for msg in inbox:
		if not msg.read:
			count += 1
	return count


func mark_read(msg: InboxMessage) -> void:
	if not msg.read:
		msg.read = true
		EventBus.inbox_changed.emit()
