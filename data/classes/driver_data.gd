## A racing driver, from young talent to world champion.
class_name DriverData
extends PersonData

# --- Racing skills (0..100) ---
@export_group("Skills")
@export_range(0, 100) var cornering: int = 50
@export_range(0, 100) var braking: int = 50
@export_range(0, 100) var overtaking: int = 50
@export_range(0, 100) var defending: int = 50
@export_range(0, 100) var consistency: int = 50   # lower = more mistakes
@export_range(0, 100) var tyre_management: int = 50
@export_range(0, 100) var wet_skill: int = 50
@export_range(0, 100) var starts: int = 50

# --- Development / youth system ---
@export_group("Development")
## Hidden maximum overall rating the driver can reach. Scouts estimate it.
@export_range(0, 100) var potential: int = 60
## How fast the driver grows towards the potential (0.5 slow .. 1.5 fast).
@export_range(0.5, 1.5) var development_rate: float = 1.0
## Series the driver currently races in, e.g. &"f1", &"f2", &"f3".
@export var series_id: StringName
## Team academy the driver belongs to (empty = none).
@export var academy_team_id: StringName

# --- Career stats ---
@export_group("Career")
@export var races: int = 0
@export var wins: int = 0
@export var podiums: int = 0
@export var championships: int = 0


## Simple average of all racing skills. Used for UI and AI decisions.
func overall() -> int:
	var total := cornering + braking + overtaking + defending \
		+ consistency + tyre_management + wet_skill + starts
	return roundi(total / 8.0)
