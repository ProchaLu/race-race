## Micro-sector view of a track for the weekend simulation. Built either
## from a placeholder layout (TrackLayouts, the 24 calendar tracks) or from
## the TrackProfile of a track with a racing line (read only – the track
## itself is never changed). Variants let the sim lab stretch a layout.
class_name TrackModel
extends RefCounted

class Sector:
	var start_m: float
	var end_m: float
	var type: TrackSegment.Type
	## Time of an average car in free air.
	var reference_s: float
	## Time share per segment type inside this sector (sums to 1).
	var type_share := {}
	## Share of time in fast/medium corners (dirty air hurts here).
	var aero_share: float
	## 0 = no overtaking, 1 = very easy (only at the end of straights).
	var overtake_chance: float
	var is_drs: bool = false

const MERGE_BELOW_M := 40.0
const DRS_MIN_LENGTH_M := 350.0
## Straights shorter than this allow almost no overtaking; this much
## longer makes it very easy.
const OVERTAKE_MIN_STRAIGHT_M := 300.0
const OVERTAKE_EASY_EXTRA_M := 900.0
const STEP_M := TrackProfile.STEP_M

var track: TrackData
var sectors: Array[Sector] = []
var lap_length_m: float
var reference_lap_s: float
var pit_lane_loss_s: float
var scale: float = 1.0
## Placeholder data (wear, temperatures, rain, safety car risk), empty for
## tracks built from a racing line.
var layout := {}
## Share of lap time per car rating: {"power":, "drag":, "downforce":, "mech":}.
var rating_share := {}
## Reference speed per 5 m sample (m/s).
var speed := PackedFloat32Array()


## variant: {"straight": 1.0, "corner": 1.0, "overtake": 1.0} scales sector
## times and overtaking (1.0 = the layout as it is).
static func build(p_track: TrackData, variant: Dictionary = {}) -> TrackModel:
	var model := TrackModel.new()
	model.track = p_track
	if TrackLayouts.has_layout(p_track.id):
		model._build_from_layout(TrackLayouts.get_layout(p_track.id), variant)
	else:
		model._build_from_profile(variant)
	return model


# --- Placeholder layouts -----------------------------------------------------

func _build_from_layout(data: Dictionary, variant: Dictionary) -> void:
	layout = data
	pit_lane_loss_s = data.pit
	var parts: Array = data.layout
	var corner_total := 0.0
	var straight_total := 0.0
	for p in parts:
		if p is Array:
			corner_total += p[1]
		else:
			straight_total += p
	var straight_scale: float = (float(data.length) - corner_total) / straight_total

	# Speed limit per sample: top speed on straights, apex speed in corners.
	var limits := PackedFloat32Array()
	var defs: Array = []  # [first sample, end sample, is corner]
	for p in parts:
		var corner: bool = p is Array
		var length: float = p[1] if corner else p * straight_scale
		var first := limits.size()
		for k in maxi(1, roundi(length / STEP_M)):
			limits.append(minf(TrackProfile.V_MAX, p[0] / 3.6) if corner else TrackProfile.V_MAX)
		defs.append([first, limits.size(), corner])
	lap_length_m = limits.size() * STEP_M
	speed = _speed_profile(limits)

	var overtake_factor: float = data.overtake * variant.get("overtake", 1.0)
	for d in defs:
		var s := Sector.new()
		s.start_m = d[0] * STEP_M
		s.end_m = d[1] * STEP_M
		if d[2]:
			var slowest := TrackProfile.V_MAX
			for i in range(d[0], d[1]):
				slowest = minf(slowest, speed[i])
			s.type = _sample_type(slowest)
			s.overtake_chance = 0.0
		else:
			s.type = TrackSegment.Type.STRAIGHT
			s.overtake_chance = clampf((s.end_m - s.start_m - OVERTAKE_MIN_STRAIGHT_M) / OVERTAKE_EASY_EXTRA_M \
				* overtake_factor, 0.0, 1.0)
		_fill_times(s, d[0], d[1], variant)
		sectors.append(s)
	_finish(data.get("drs", 2))


## Acceleration and braking passes (twice, so the lap wraps around).
static func _speed_profile(limits: PackedFloat32Array) -> PackedFloat32Array:
	var n := limits.size()
	var v := limits.duplicate()
	for _pass in 2:
		for i in n:
			var prev := v[(i - 1 + n) % n]
			v[i] = minf(v[i], sqrt(prev * prev + 2.0 * TrackProfile.accel_at(prev) * STEP_M))
	for _pass in 2:
		for i in range(n - 1, -1, -1):
			var next := v[(i + 1) % n]
			v[i] = minf(v[i], sqrt(next * next + 2.0 * TrackProfile.BRAKE_DECEL * STEP_M))
	return v


# --- Tracks with a racing line (Test Ring) -------------------------------------

func _build_from_profile(variant: Dictionary) -> void:
	var profile := TrackProfile.build(track)
	lap_length_m = track.lap_length_m
	pit_lane_loss_s = track.pit_lane_loss_s
	speed = profile.speed
	var overtake_scale: float = variant.get("overtake", 1.0)
	for seg in track.segments:
		if not sectors.is_empty() and seg.length() < MERGE_BELOW_M:
			sectors.back().end_m = seg.end_m
			continue
		var s := Sector.new()
		s.start_m = seg.start_m
		s.end_m = seg.end_m
		s.type = seg.type
		s.overtake_chance = clampf((seg.length() - OVERTAKE_MIN_STRAIGHT_M) / OVERTAKE_EASY_EXTRA_M * overtake_scale, 0.0, 1.0) \
			if seg.type == TrackSegment.Type.STRAIGHT else 0.0
		sectors.append(s)
	for s in sectors:
		_fill_times(s, int(s.start_m / STEP_M), mini(int(s.end_m / STEP_M), speed.size()), variant)
	_finish(2)


# --- Shared ----------------------------------------------------------------------

## Reference time and time share per corner type for one sector.
func _fill_times(s: Sector, first: int, last: int, variant: Dictionary) -> void:
	var straight_scale: float = variant.get("straight", 1.0)
	var corner_scale: float = variant.get("corner", 1.0)
	var times := {}
	var total := 0.0
	for i in range(first, last):
		var dt := STEP_M / speed[i]
		# On straights everything is acceleration and top speed.
		var kind := TrackSegment.Type.STRAIGHT if s.type == TrackSegment.Type.STRAIGHT else _sample_type(speed[i])
		dt *= straight_scale if kind == TrackSegment.Type.STRAIGHT else corner_scale
		times[kind] = times.get(kind, 0.0) + dt
		total += dt
	s.reference_s = total
	for kind in times:
		s.type_share[kind] = times[kind] / total
	s.aero_share = s.type_share.get(TrackSegment.Type.FAST_CORNER, 0.0) \
		+ s.type_share.get(TrackSegment.Type.MEDIUM_CORNER, 0.0) * 0.6


func _finish(drs_zones: int) -> void:
	reference_lap_s = 0.0
	for s in sectors:
		reference_lap_s += s.reference_s
	# Placeholder layouts are scaled to a realistic lap time.
	if layout.has("lap"):
		var factor: float = layout.lap / reference_lap_s
		for s in sectors:
			s.reference_s *= factor
		for i in speed.size():
			speed[i] /= factor
		reference_lap_s = layout.lap
	scale = SimTuning.lap_scale(reference_lap_s)
	_mark_drs_zones(drs_zones)
	_compute_rating_share()


static func _sample_type(speed_mps: float) -> TrackSegment.Type:
	var kmh := speed_mps * 3.6
	if kmh >= 220.0:
		return TrackSegment.Type.FAST_CORNER
	if kmh >= 140.0:
		return TrackSegment.Type.MEDIUM_CORNER
	return TrackSegment.Type.SLOW_CORNER


func _mark_drs_zones(count: int) -> void:
	var straights := sectors.filter(func(s: Sector):
		return s.type == TrackSegment.Type.STRAIGHT and s.end_m - s.start_m >= DRS_MIN_LENGTH_M)
	straights.sort_custom(func(a: Sector, b: Sector): return a.end_m - a.start_m > b.end_m - b.start_m)
	for i in mini(count, straights.size()):
		straights[i].is_drs = true


func _compute_rating_share() -> void:
	rating_share = {"power": 0.0, "drag": 0.0, "downforce": 0.0, "mech": 0.0}
	for s in sectors:
		for kind in s.type_share:
			var w: Array = SimTuning.CAR_WEIGHTS[kind]
			var share: float = s.type_share[kind] * s.reference_s / reference_lap_s
			rating_share.power += w[0] * share
			rating_share.drag += w[1] * share
			rating_share.downforce += w[2] * share
			rating_share.mech += w[3] * share


## Fraction of lap time spent on straights (for wing level effects).
func straight_share(s: Sector) -> float:
	return s.type_share.get(TrackSegment.Type.STRAIGHT, 0.0)


## Sum of all overtaking chances (rough "how easy is it to pass here").
func overtaking_index() -> float:
	var total := 0.0
	for s in sectors:
		total += s.overtake_chance
	return total


## Short description for logs and the sim lab.
func describe() -> String:
	return "%-14s %5.0f m  lap %s  power %2.0f %%  downforce %2.0f %%  mech %2.0f %%  overtaking %.2f  DRS %d" % [
		track.name.replace(" Grand Prix", ""), lap_length_m, _fmt(reference_lap_s),
		(rating_share.power + rating_share.drag) * 100.0, rating_share.downforce * 100.0, rating_share.mech * 100.0,
		overtaking_index(), sectors.filter(func(s: Sector): return s.is_drs).size()]


static func _fmt(seconds: float) -> String:
	return "%d:%06.3f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]
