## One section of a track, defined by distance along the racing line.
## The race sim reads these to decide speed, overtaking chances and DRS.
class_name TrackSegment
extends Resource

enum Type { STRAIGHT, FAST_CORNER, MEDIUM_CORNER, SLOW_CORNER }

@export var type: Type = Type.STRAIGHT
## Start/end in metres from the start/finish line.
@export var start_m: float = 0.0
@export var end_m: float = 100.0

## Reference speed for an average car/driver in km/h.
@export var base_speed_kmh: float = 250.0
## 0 = overtaking impossible, 1 = very easy.
@export_range(0.0, 1.0) var overtake_chance: float = 0.1
@export var is_drs_zone: bool = false


func length() -> float:
	return end_m - start_m
