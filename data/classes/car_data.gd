## Performance profile of a team's car for one season.
## Values are ratings (0..100); the race sim turns them into speeds.
class_name CarData
extends Resource

@export var team_id: StringName
@export var season: int = 2026

@export_group("Performance")
## Grip in medium/fast corners.
@export_range(0, 100) var downforce: int = 50
## Low drag = higher top speed on straights.
@export_range(0, 100) var drag_efficiency: int = 50
@export_range(0, 100) var engine_power: int = 50
## Grip in slow corners and over kerbs.
@export_range(0, 100) var mechanical_grip: int = 50
## How gently the car treats its tyres.
@export_range(0, 100) var tyre_preservation: int = 50

@export_group("Reliability")
## Lower = higher chance of technical failures. With parts: the engine's
## reliability (fixed until R5); every part has its own.
@export_range(0, 100) var reliability: int = 70

@export_group("Parts (R3)")
## Values calculated from the parts (docs/car_model.md 2). -1 / 0 = this car
## has no parts (sim lab): braking and traction then follow the mechanical
## grip, and weight and cooling are not simulated.
@export var braking: int = -1
@export var traction: int = -1
@export var cooling: int = -1
@export var mass_kg: float = 0.0
## Engine power without the exhaust (from the power unit, R5).
@export var engine_base: int = -1

@export_group("Power unit (R5)")
## Engine values besides power (reliability is the field above).
@export var engine_efficiency: float = 50.0
@export var engine_drivability: float = 50.0
@export var pu_mass_kg: float = PowerUnit.MASS_AT_50
## Integration with the chassis: works team +2 cooling / −2 kg; first season
## after a switch −3 / +3 kg (docs/engine_model.md 1).
@export var engine_cooling_fit: int = 0
@export var engine_mass_fit: float = 0.0
## Failure risk from the fitted unit's wear (×1 = fresh).
@export var engine_wear_risk: float = 1.0
## Part ID -> fitted PartVersion.
@export var parts: Dictionary = {}
## Part ID -> every version of the season, oldest first.
@export var part_history: Dictionary = {}
## Car values at the start of the season (for "change this season").
@export var season_start: Dictionary = {}


func has_parts() -> bool:
	return not parts.is_empty()


func braking_value() -> int:
	return braking if braking >= 0 else mechanical_grip


func traction_value() -> int:
	return traction if traction >= 0 else mechanical_grip
