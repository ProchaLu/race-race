## Employment contract between a team and a person (driver or staff).
## References use IDs instead of object links, which keeps savegames simple.
class_name ContractData
extends Resource

@export var person_id: StringName
@export var team_id: StringName

## Yearly salary in currency units.
@export var salary: int = 0
@export var start_year: int = 2026
## Contract runs until the end of this season.
@export var end_year: int = 2027

# Optional clauses
@export var win_bonus: int = 0
@export var buyout_fee: int = 0
## For drivers: true = guaranteed number-one status.
@export var is_first_driver: bool = false


func is_active(current_year: int) -> bool:
	return current_year >= start_year and current_year <= end_year
