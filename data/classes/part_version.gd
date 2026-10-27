## One version of a car part (e.g. "Floor v3"): its values, mass, how many
## units exist and how well the forecast matched the track.
class_name PartVersion
extends Resource

@export var part_id: StringName
@export var version: int = 1
@export var season: int = 2026
## Value -> 0..100 (see CarParts.values_of).
@export var values: Dictionary = {}
@export var mass_kg: float = 0.0
## Units built (both cars plus spares).
@export var units: int = 3
## Development goal that produced it ("" = start of the season).
@export var goal: String = ""
## Lap time effect compared with the version before (s per 90 s lap; negative = faster).
@export var forecast_s: float = 0.0
@export var real_s: float = 0.0
## False until the part has raced and the team knows the real effect.
@export var correlated: bool = true
## Round of the season in which it was first used.
@export var first_round: int = 0


func label() -> String:
	return "%s v%d" % [TranslationServer.translate(CarParts.name_of(part_id)), version]


func value(key: StringName) -> float:
	return values.get(key, 50.0)
