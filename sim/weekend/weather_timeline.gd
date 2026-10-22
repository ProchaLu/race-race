## Weather of one session, minute by minute: rain intensity (0..1), track
## wetness on the racing line (0..1) and track temperature. Wetness rises
## with rain and falls as the track dries (temperature, cars on the line).
class_name WeatherTimeline
extends RefCounted

const WET_PER_RAIN := 0.12
const DRY_BASE := 0.018
const DRY_LINE_BONUS := 0.008

var rain := PackedFloat32Array()
var wetness := PackedFloat32Array()
var track_temp := PackedFloat32Array()
## Rain showers: [{"start": min, "end": min, "peak": 0..1}]
var showers: Array = []


## rain_chance: probability of at least one shower during the session.
static func generate(minutes: int, rain_chance: float, base_track_temp: float,
		rng: RandomNumberGenerator, start_wetness: float = 0.0) -> WeatherTimeline:
	var w := WeatherTimeline.new()
	if rng.randf() < rain_chance:
		w._add_shower(minutes, rng)
		if rng.randf() < 0.3:
			w._add_shower(minutes, rng)
	w._simulate(minutes, base_track_temp, start_wetness, rng)
	return w


## Fixed weather for tests: one shower from start_min to end_min.
static func scripted(minutes: int, base_track_temp: float, shower: Dictionary = {}) -> WeatherTimeline:
	var w := WeatherTimeline.new()
	if not shower.is_empty():
		w.showers.append(shower)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	w._simulate(minutes, base_track_temp, 0.0, rng)
	return w


func _add_shower(minutes: int, rng: RandomNumberGenerator) -> void:
	var start := rng.randf_range(-20.0, minutes * 0.9)
	var length := rng.randf_range(10.0, 50.0)
	var peak := rng.randf_range(0.15, 0.95)
	showers.append({"start": start, "end": start + length, "peak": peak})


func _simulate(minutes: int, base_temp: float, start_wetness: float, rng: RandomNumberGenerator) -> void:
	var n := minutes + 1
	rain.resize(n)
	wetness.resize(n)
	track_temp.resize(n)
	var w := start_wetness
	# Showers that began before the session already made the track wet.
	for shower in showers:
		if shower.start < 0.0:
			w = clampf(w + minf(-shower.start, 20.0) * WET_PER_RAIN * shower.peak, 0.0, 1.0)
	var flicker := 0.0
	for m in n:
		var r := 0.0
		for shower in showers:
			r = maxf(r, _shower_intensity(shower, m))
		flicker = clampf(flicker + rng.randf_range(-0.05, 0.05), -0.1, 0.1)
		r = clampf(r + (flicker if r > 0.0 else 0.0), 0.0, 1.0)
		rain[m] = r
		var temp := base_temp - r * 12.0 - (4.0 if r > 0.0 else 0.0)
		track_temp[m] = temp
		var dry := (DRY_BASE * (1.0 + (temp - 20.0) / 25.0) + DRY_LINE_BONUS) if r < 0.05 else DRY_BASE * 0.2
		w = clampf(w + r * WET_PER_RAIN - dry * (1.0 - r), 0.0, 1.0)
		wetness[m] = w


static func _shower_intensity(shower: Dictionary, minute: float) -> float:
	if minute < shower.start or minute > shower.end:
		return 0.0
	# Builds up, peaks in the middle, eases off.
	var t: float = (minute - shower.start) / maxf(shower.end - shower.start, 1.0)
	return shower.peak * sin(t * PI)


func _sample(arr: PackedFloat32Array, seconds: float) -> float:
	var m := clampf(seconds / 60.0, 0.0, arr.size() - 1.001)
	var i := int(m)
	return lerpf(arr[i], arr[i + 1], m - i)


func wetness_at(seconds: float) -> float:
	return _sample(wetness, seconds)


func rain_at(seconds: float) -> float:
	return _sample(rain, seconds)


func track_temp_at(seconds: float) -> float:
	return _sample(track_temp, seconds)


## Wetness a strategist expects in `ahead_s` seconds. accuracy 0..1:
## 1 = perfect, 0 = guesses with a large error.
func forecast_wetness(now_s: float, ahead_s: float, accuracy: float, noise_seed: int) -> float:
	var truth := wetness_at(now_s + ahead_s)
	if showers.is_empty() and truth <= 0.0:
		return 0.0  # a dry day is easy to forecast
	# Same team, same 10-minute window -> same mistake (no flickering calls).
	var bucket := int((now_s + ahead_s) / 600.0)
	var u := fposmod(sin(float(noise_seed % 100000) * 12.9898 + bucket * 78.233) * 43758.5453, 1.0)
	var error := (u - 0.5) * 2.0 * 0.4 * (1.0 - accuracy) * clampf(ahead_s / 600.0, 0.2, 1.5)
	return clampf(truth + error, 0.0, 1.0)


func max_rain() -> float:
	var best := 0.0
	for r in rain:
		best = maxf(best, r)
	return best
