## Employment contract between a team and a person (driver or staff).
## References use IDs instead of object links, which keeps savegames simple.
class_name ContractData
extends Resource

enum DriverRole { NUMBER_ONE, EQUAL, NUMBER_TWO, RESERVE }

@export var person_id: StringName
@export var team_id: StringName

## Yearly salary in currency units.
@export var salary: int = 0
@export var start_year: int = 2026
## Contract runs until the end of this season.
@export var end_year: int = 2027
@export var role: DriverRole = DriverRole.EQUAL

# Optional clauses
@export var win_bonus: int = 0
@export var podium_bonus: int = 0
## 0 = no release clause.
@export var release_clause: int = 0
## Extra year the team may add (0 = none).
@export var team_option_year: int = 0
@export var agent_name: String = ""


func is_active(current_year: int) -> bool:
	return current_year >= start_year and current_year <= end_year


static func role_name(r: DriverRole) -> String:
	return ["No.1 driver", "Equal status", "No.2 driver", "Reserve driver"][r]
