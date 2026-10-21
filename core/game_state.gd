## The whole game world (autoload "GameState").
## All entities are stored in dictionaries keyed by ID.
extends Node

var series: Dictionary[StringName, SeriesData] = {}
var teams: Dictionary[StringName, TeamData] = {}
var drivers: Dictionary[StringName, DriverData] = {}
var staff: Dictionary[StringName, StaffData] = {}
var sponsors: Dictionary[StringName, SponsorData] = {}
var tracks: Dictionary[StringName, TrackData] = {}
var contracts: Array[ContractData] = []
## Tyre compounds, ordered softest first.
var tyre_compounds: Array[TyreCompound] = []

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
	tyre_compounds.clear()
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
