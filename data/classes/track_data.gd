## Static description of a circuit. The visual path lives in a separate
## track scene (Path2D); this resource only holds the simulation data.
class_name TrackData
extends Resource

@export var id: StringName
@export var name: String
@export var country: String

## Total lap length in metres. Must match the end of the last segment.
@export var lap_length_m: float = 5000.0
@export var laps: int = 50
## Time lost driving through the pit lane (excluding standing time).
@export var pit_lane_loss_s: float = 20.0
## How hard the surface is on tyres (0.5 gentle .. 1.5 aggressive).
@export_range(0.5, 1.5) var tyre_wear_factor: float = 1.0

## Racing line. Used both by the sim (speed profile) and the view (Path2D).
@export var curve: Curve2D
## Generated from the curve if left empty; can be tuned by hand later.
@export var segments: Array[TrackSegment] = []


## Returns the segment at a given lap distance, or null if none matches.
func segment_at(distance_m: float) -> TrackSegment:
	for seg in segments:
		if distance_m >= seg.start_m and distance_m < seg.end_m:
			return seg
	return null
