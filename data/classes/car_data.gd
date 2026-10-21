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
## Lower = higher chance of technical failures.
@export_range(0, 100) var reliability: int = 70
