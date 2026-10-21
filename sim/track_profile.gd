## Pre-computed speed profile of a track, built from its Curve2D.
## The curve is sampled every STEP_M metres; tight curvature limits the
## speed, and acceleration/braking passes turn that into a realistic profile.
class_name TrackProfile
extends RefCounted

const STEP_M := 5.0
const V_MAX := 92.0         # ~330 km/h top speed of an average car
const LAT_ACCEL := 38.0     # m/s², cornering grip of an average car
const BRAKE_DECEL := 45.0   # m/s²
const CURVATURE_WINDOW := 3 # samples on each side used to measure curvature
const MIN_SEGMENT_M := 80.0

var lap_length_m: float
var metres_per_px: float
## Reference speed (m/s) for an average car/driver at each sample.
var speed := PackedFloat32Array()
## 0 = full-throttle straight, 1 = slowest corner. Blends car strengths.
var cornerness := PackedFloat32Array()
## Index into TrackData.segments for each sample.
var segment_index := PackedInt32Array()


## Max acceleration at a given speed (drops towards top speed).
static func accel_at(v: float) -> float:
	return maxf(3.0, 14.0 * (1.0 - v / V_MAX))


static func build(track: TrackData) -> TrackProfile:
	var profile := TrackProfile.new()
	profile._analyze(track)
	return profile


func index_at(lap_distance_m: float) -> int:
	return clampi(int(lap_distance_m / STEP_M), 0, speed.size() - 1)


func _analyze(track: TrackData) -> void:
	lap_length_m = track.lap_length_m
	metres_per_px = lap_length_m / track.curve.get_baked_length()
	var n := int(lap_length_m / STEP_M)

	var pos := PackedVector2Array()
	pos.resize(n)
	for i in n:
		pos[i] = track.curve.sample_baked(i * STEP_M / metres_per_px, true)

	var heading := PackedFloat32Array()
	heading.resize(n)
	for i in n:
		heading[i] = (pos[(i + 1) % n] - pos[(i - 1 + n) % n]).angle()

	# Corner speed limit from curvature: v = sqrt(a_lat * radius).
	var corner_limit := PackedFloat32Array()
	corner_limit.resize(n)
	var w := CURVATURE_WINDOW
	for i in n:
		var turn := absf(angle_difference(heading[(i - w + n) % n], heading[(i + w) % n]))
		var curvature := turn / (2.0 * w * STEP_M)
		corner_limit[i] = V_MAX if curvature < 0.00001 else minf(V_MAX, sqrt(LAT_ACCEL / curvature))

	speed = corner_limit.duplicate()
	# Acceleration pass. Run twice so the profile wraps around the lap.
	for _pass in 2:
		for i in n:
			var prev := speed[(i - 1 + n) % n]
			speed[i] = minf(speed[i], sqrt(prev * prev + 2.0 * accel_at(prev) * STEP_M))
	# Braking pass, backwards.
	for _pass in 2:
		for i in range(n - 1, -1, -1):
			var next := speed[(i + 1) % n]
			speed[i] = minf(speed[i], sqrt(next * next + 2.0 * BRAKE_DECEL * STEP_M))

	cornerness.resize(n)
	for i in n:
		cornerness[i] = clampf((V_MAX - speed[i]) / (V_MAX - 30.0), 0.0, 1.0)

	if track.segments.is_empty():
		track.segments = _build_segments(corner_limit)
	segment_index.resize(n)
	for i in n:
		var seg := track.segment_at(i * STEP_M)
		segment_index[i] = track.segments.find(seg) if seg else 0


## Groups samples into straights and corner types. Overtaking is easiest
## on long straights (which include the braking zone of the next corner).
func _build_segments(corner_limit: PackedFloat32Array) -> Array[TrackSegment]:
	var result: Array[TrackSegment] = []
	for i in corner_limit.size():
		var type := _classify(corner_limit[i])
		var last: TrackSegment = result.back() if not result.is_empty() else null
		if last and (last.type == type or last.length() < MIN_SEGMENT_M):
			last.end_m = (i + 1) * STEP_M
			continue
		var seg := TrackSegment.new()
		seg.type = type
		seg.start_m = i * STEP_M
		seg.end_m = (i + 1) * STEP_M
		result.append(seg)
	result.back().end_m = lap_length_m

	for seg in result:
		var total := 0.0
		var count := 0
		for i in range(int(seg.start_m / STEP_M), mini(int(seg.end_m / STEP_M), speed.size())):
			total += speed[i]
			count += 1
		seg.base_speed_kmh = total / maxi(count, 1) * 3.6
		match seg.type:
			TrackSegment.Type.STRAIGHT:
				seg.overtake_chance = clampf(seg.length() / 800.0, 0.2, 1.0)
			TrackSegment.Type.SLOW_CORNER:
				seg.overtake_chance = 0.2
			TrackSegment.Type.MEDIUM_CORNER:
				seg.overtake_chance = 0.1
			_:
				seg.overtake_chance = 0.05
	return result


func _classify(limit_mps: float) -> TrackSegment.Type:
	var kmh := limit_mps * 3.6
	if limit_mps >= V_MAX * 0.97:
		return TrackSegment.Type.STRAIGHT
	if kmh >= 220.0:
		return TrackSegment.Type.FAST_CORNER
	if kmh >= 140.0:
		return TrackSegment.Type.MEDIUM_CORNER
	return TrackSegment.Type.SLOW_CORNER
