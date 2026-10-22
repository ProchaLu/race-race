## Everything about the setting of one race that is not a car or a person:
## distance, temperatures, tyre wear, weather and incident risk.
## Rounds on the Test Ring differ through these values.
class_name RaceConditions
extends RefCounted

var laps: int = 60
var track_temp_c: float = 35.0
## 0.5 gentle .. 1.5 aggressive.
var tyre_wear_factor: float = 1.0
## Probability of at least one shower during the race.
var rain_chance: float = 0.0
## Scales how often incidents bring out the safety car (1 = normal).
var safety_car_risk: float = 1.0
## Track variant for the sim lab: {"straight":, "corner":, "overtake":}.
var track_variant: Dictionary = {}
var weather: WeatherTimeline


## Race distance of ~305 km like in F1, neutral conditions.
static func standard(model: TrackModel) -> RaceConditions:
	var c := RaceConditions.new()
	c.laps = maxi(10, roundi(305000.0 / model.lap_length_m))
	return c


## Conditions of a calendar track: its distance, tyre wear, safety car risk,
## rain chance and a track temperature from its range.
static func for_track(model: TrackModel, rng: RandomNumberGenerator) -> RaceConditions:
	var c := standard(model)
	var data := model.layout
	if not data.is_empty():
		c.laps = data.get("laps", c.laps)
		c.tyre_wear_factor = data.wear
		c.safety_car_risk = data.sc
		c.rain_chance = data.rain
		c.track_temp_c = rng.randf_range(data.temp[0], data.temp[1])
	c.make_weather(rng)
	return c


## Rolls the race weather. Needs ~2 minutes per lap of buffer.
func make_weather(rng: RandomNumberGenerator) -> void:
	weather = WeatherTimeline.generate(laps * 2 + 30, rain_chance, track_temp_c, rng)


func ensure_weather(rng: RandomNumberGenerator) -> void:
	if not weather:
		make_weather(rng)
