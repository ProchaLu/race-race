## Base class for every human in the game world (drivers, staff, scouts, ...).
## Holds identity data only; role-specific stats live in subclasses.
class_name PersonData
extends Resource

enum Gender { MALE, FEMALE }

@export var id: StringName
@export var first_name: String
@export var last_name: String
@export var nationality: String  # ISO country code, e.g. "DE"
@export var birth_year: int = 2000
@export var gender: Gender = Gender.MALE

## 0..100, affects performance and contract negotiations.
@export_range(0, 100) var morale: int = 50
## Team this person currently works for. Empty = free agent.
@export var team_id: StringName
## Agent who negotiates for this person (empty = negotiates alone).
@export var agent_id: StringName
## Ended the career: no longer on the market, kept for history and links.
@export var retired: bool = false
## Earlier jobs, oldest first: {"from": 2016, "to": 2019, "team": "Nordline GP", "role": "Data engineer"}
@export var career_history: Array[Dictionary] = []


func full_name() -> String:
	return "%s %s" % [first_name, last_name]


func age(current_year: int) -> int:
	return current_year - birth_year
