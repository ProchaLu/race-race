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
## Current season statistics per driver.
var season_stats: Dictionary[StringName, DriverSeasonStats] = {}
## Relationships between two people. Key: "id_a|id_b" (sorted).
## Value: {"value": -100..100, "factors": {reason: delta}}
var relationships: Dictionary = {}
## Tyre compounds, ordered softest first.
var tyre_compounds: Array[TyreCompound] = []
## Newest message last.
var inbox: Array[InboxMessage] = []
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
	relationships.clear()
	tyre_compounds.clear()
	inbox.clear()
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
		if driver.series_id == series_id and season_stats.has(driver.id):
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
