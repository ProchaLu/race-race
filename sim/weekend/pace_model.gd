## Lap time components of the weekend simulation (docs/simulation_model.md,
## sections 1–3 and 8–9). Pure functions; every result is in seconds on the
## real track unless the name says "frac" (fraction of the lap time).
class_name PaceModel
extends RefCounted


# --- Car -------------------------------------------------------------------

## Lap time fraction per sector from the car ratings and the wing level.
static func car_sector_fracs(car: SimCar, model: TrackModel) -> PackedFloat32Array:
	var c := car.car_data
	var power := c.engine_power + mode_power(car)
	var out := PackedFloat32Array()
	out.resize(model.sectors.size())
	for i in model.sectors.size():
		var s: TrackModel.Sector = model.sectors[i]
		var frac := 0.0
		for kind in s.type_share:
			var w: Array = SimTuning.CAR_WEIGHTS[kind]
			var drag := c.drag_efficiency - car.cooling_opening * SimTuning.COOLING_OPENING_DRAG
			var rating: float = w[0] * power + w[1] * drag + w[2] * c.downforce \
				+ w[3] * c.mechanical_grip + w[4] * c.braking_value() + w[5] * c.traction_value()
			frac += s.type_share[kind] * -(rating - 50.0) * SimTuning.CAR_FRAC_PER_POINT
		var straight := model.straight_share(s)
		frac += car.wing * (straight * SimTuning.WING_STRAIGHT_FRAC + (1.0 - straight) * SimTuning.WING_CORNER_FRAC)
		out[i] = frac
	return out


## The whole lap of an average driver in this car, in seconds (for the breakdown).
static func car_lap_s(car: SimCar, model: TrackModel) -> float:
	var total := 0.0
	for i in model.sectors.size():
		total += car.sector_frac[i] * model.sectors[i].reference_s
	return total


# --- Driver ----------------------------------------------------------------

static func driver_pace_rating(d: DriverData, qualifying: bool) -> float:
	var one_lap := SimTuning.DRIVER_QUALI_ONE_LAP_WEIGHT if qualifying else 0.2
	var rest := 1.0 - one_lap
	var pace := rest * (0.5625 * d.cornering + 0.4375 * d.braking) + one_lap * d.one_lap_pace
	if qualifying and d.traits.has(&"quali_specialist"):
		pace += 4.0
	return pace


static func driver_pace_s(car: SimCar, model: TrackModel, qualifying: bool) -> float:
	var rating := driver_pace_rating(car.driver, qualifying)
	return -(rating - SimTuning.DRIVER_PACE_CENTER) * SimTuning.DRIVER_FRAC_PER_POINT * model.reference_lap_s


## Confidence and morale, incl. the 1-on-1 talk.
static func confidence_s(car: SimCar, model: TrackModel) -> float:
	var level := (car.driver.confidence + car.talk_value("confidence") + car.driver.morale) / 2.0
	return -(clampf(level, 0.0, 100.0) - 50.0) / 50.0 * SimTuning.CONFIDENCE_S * model.scale


## Fitness costs time late in the race; the fitness coach helps.
static func fitness_s(car: SimCar, model: TrackModel, progress: float) -> float:
	if progress < SimTuning.FITNESS_LATE_FROM:
		return 0.0
	var fitness := clampf(car.driver.fitness + (car.ops.physical_training - 50) * 0.1, 0.0, 100.0)
	var late := (progress - SimTuning.FITNESS_LATE_FROM) / (1.0 - SimTuning.FITNESS_LATE_FROM)
	return SimTuning.FITNESS_LATE_S * (1.0 - fitness / 100.0) * late * model.scale


## Rookies lose time on tracks they do not know yet; practice laps help.
static func rookie_s(car: SimCar, model: TrackModel) -> float:
	var d := car.driver
	if d.races >= SimTuning.ROOKIE_RACES:
		return 0.0
	var unknown := 1.0 - float(d.races) / SimTuning.ROOKIE_RACES
	var learning := 1.0 - d.adaptability / 150.0
	if d.traits.has(&"slow_learner"):
		learning *= 1.4
	return SimTuning.ROOKIE_TRACK_S * unknown * learning * model.scale


static func form_sigma_s(car: SimCar, model: TrackModel) -> float:
	var c := car.driver.consistency / 100.0
	return lerpf(SimTuning.FORM_SIGMA_MAX_S, SimTuning.FORM_SIGMA_MIN_S, c) * model.scale


# --- Setup -------------------------------------------------------------------

static func setup_s(car: SimCar, model: TrackModel) -> float:
	return SimTuning.curve(SimTuning.SETUP_CURVE, car.setup_pct) * model.scale


## 0 = perfect setup, 1 = terrible (for mistake and wear penalties).
static func setup_badness(car: SimCar) -> float:
	return clampf((85.0 - car.setup_pct) / 85.0, 0.0, 1.0)


# --- Tyres -------------------------------------------------------------------

static func compound_info(id: StringName) -> Array:
	return SimTuning.COMPOUNDS[id]


static func is_wet_compound(id: StringName) -> bool:
	return id == &"inter" or id == &"wet"


## Life (laps until the cliff) on this track.
static func tyre_life(id: StringName, conditions: RaceConditions) -> float:
	return compound_info(id)[2] / conditions.tyre_wear_factor


## Seconds per lap from the compound, its age, cliff, temperature and wetness.
static func tyre_s(car: SimCar, model: TrackModel, conditions: RaceConditions, wetness: float) -> float:
	var info := compound_info(car.compound)
	var t: float = info[0]
	var deg: float = info[1] * conditions.tyre_wear_factor
	t += deg * car.tyre_wear_laps
	var life := tyre_life(car.compound, conditions)
	if car.tyre_wear_laps > life:
		t += SimTuning.CLIFF_S_PER_LAP * pow(car.tyre_wear_laps - life, SimTuning.CLIFF_EXPONENT)
	var off_window := maxf(0.0, absf(car.tyre_temp) - SimTuning.TEMP_FREE_ZONE)
	t += SimTuning.TEMP_GRIP_S * off_window / (1.0 - SimTuning.TEMP_FREE_ZONE)
	if car.tyre_laps == 0:
		t += info[3]  # warm-up on the out-lap
	t += wet_tyre_penalty(car.compound, wetness)
	return t * model.scale


## Extra seconds of a compound at a given wetness (0 = the right tyre).
static func wet_tyre_penalty(id: StringName, w: float) -> float:
	match id:
		&"inter":
			if w < 0.45:
				return 3.0 * pow((0.45 - w) / 0.45, 2.0)
			if w > 0.6:
				return 12.0 * pow(w - 0.6, 1.5)
			return 0.0
		&"wet":
			return 1.2 + (6.0 * pow((0.7 - w) / 0.7, 2.0) if w < 0.7 else 0.0)
		_:
			return 0.0 if w < 0.1 else 40.0 * pow(w - 0.1, 1.4)


## Best compound for a wetness (what a perfect strategist would fit).
static func ideal_compound_for(w: float, dry_choice: StringName) -> StringName:
	var best := dry_choice
	var best_s := wet_tyre_penalty(dry_choice, w)
	for id: StringName in [&"inter", &"wet"]:
		var s := wet_tyre_penalty(id, w)
		if s < best_s - 0.3:
			best = id
			best_s = s
	return best


## How fast the tyres age this lap (1.0 = nominal).
static func wear_rate(car: SimCar, dirty_share: float, wetness: float) -> float:
	var d := car.driver
	var rate := 1.25 - 0.5 * d.tyre_management / 100.0
	rate *= 1.15 - 0.3 * car.car_data.tyre_preservation / 100.0
	rate *= 1.0 + SimTuning.SETUP_MAX_WEAR * setup_badness(car)
	rate *= 1.0 + SimTuning.WING_TYRE_WEAR * car.wing
	rate *= 1.0 + car.talk_value("tyre_wear") + _briefing_value(car, "tyre_wear")
	rate *= 1.0 + SimTuning.DIRTY_AIR_WEAR * dirty_share
	rate *= PowerUnit.tyre_wear_factor(car.car_data.engine_drivability)
	if d.traits.has(&"tyre_whisperer"):
		rate *= 0.9
	if d.traits.has(&"tyre_killer"):
		rate *= 1.1
	# Graining when cold, blistering when hot.
	if car.tyre_temp < -0.3:
		rate *= 1.0 + SimTuning.GRAINING_WEAR * (-car.tyre_temp - 0.3)
	elif car.tyre_temp > 0.3:
		rate *= 1.0 + SimTuning.BLISTER_WEAR * (car.tyre_temp - 0.3)
	# Wet tyres on a drying track overheat and wear fast.
	if is_wet_compound(car.compound) and wetness < 0.2:
		rate *= 1.0 + (0.2 - wetness) * 10.0
	return rate


## Moves the tyre temperature towards its target for this lap.
static func update_tyre_temp(car: SimCar, track_temp_c: float, dirty_share: float, under_sc: bool) -> void:
	var target := tyre_temp_target(car, car.compound, track_temp_c, dirty_share, under_sc)
	car.tyre_temp = lerpf(car.tyre_temp, target, SimTuning.TEMP_RESPONSE)


## Temperature a compound settles at (-1 cold .. 0 ideal .. 1 hot).
static func tyre_temp_target(car: SimCar, id: StringName, track_temp_c: float, dirty_share: float,
		under_sc: bool) -> float:
	var optimal: float = compound_info(id)[4]
	var target := (track_temp_c - optimal) / SimTuning.TEMP_RANGE_C
	target += SimTuning.DIRTY_AIR_TEMP * dirty_share
	if car.briefing == SimCar.Briefing.ATTACK:
		target += SimTuning.ATTACK_TEMP
	if under_sc:
		target += SimTuning.SC_TEMP
	# Good tyre management keeps the tyres closer to the window.
	target *= 1.0 - 0.4 * car.driver.tyre_management / 100.0
	return clampf(target, -1.0, 1.0)


# --- Fuel ----------------------------------------------------------------------

## Weight above the minimum costs time like fuel (docs/car_model.md 2.2).
static func weight_s(car: SimCar, model: TrackModel) -> float:
	var mass := car.car_data.mass_kg
	if mass <= 0.0:
		return 0.0
	return maxf(0.0, mass - CarBuild.MIN_MASS) * SimTuning.FUEL_S_PER_KG * model.scale


## Heat the car has to get rid of minus its cooling capacity (> 0 = overheating).
static func heat_deficit(car: SimCar, track_temp_c: float, in_traffic: bool) -> float:
	var c := car.car_data
	if c.cooling < 0:
		return 0.0
	var demand: float = SimTuning.COOLING_BASE + (track_temp_c - 30.0) * SimTuning.COOLING_PER_DEGREE \
		+ (c.engine_power - 60.0) * SimTuning.COOLING_PER_POWER \
		+ (SimTuning.COOLING_TRAFFIC if in_traffic else 0.0) - car.cooling_opening * SimTuning.COOLING_OPENING \
		+ PowerUnit.MODES[car.engine_mode][3]
	return demand - c.cooling


## Overheating: the engine is turned down.
static func cooling_s(deficit: float, model: TrackModel) -> float:
	return maxf(0.0, deficit) * SimTuning.COOLING_S_PER_POINT * model.scale


## The race engineer picks the cooling openings for the hottest part of the
## race. A good data analyst rarely gets it wrong.
static func choose_cooling(car: SimCar, track_temp_c: float, engineer_skill: float) -> int:
	if car.car_data.cooling < 0:
		return 0
	var reserve := -heat_deficit(car, track_temp_c + 4.0, false)
	reserve += car.rng.randfn(0.0, (1.0 - engineer_skill) * 5.0)
	if reserve > 9.0:
		return -1
	if reserve < 1.0:
		return 1
	return 0


static func fuel_s(car: SimCar, model: TrackModel) -> float:
	return car.fuel_kg * SimTuning.FUEL_S_PER_KG * model.scale


static func fuel_per_lap(model: TrackModel) -> float:
	return model.lap_length_m / 1000.0 * SimTuning.FUEL_KG_PER_KM


## Fuel of this car per lap: engine efficiency and engine mode (R5).
static func car_fuel_per_lap(car: SimCar, model: TrackModel) -> float:
	var factor := PowerUnit.fuel_factor(car.car_data.engine_efficiency) if car.car_data.has_parts() else 1.0
	return fuel_per_lap(model) * factor * PowerUnit.MODES[car.engine_mode][4]


## Extra engine power of the engine mode (R5).
static func mode_power(car: SimCar) -> float:
	return PowerUnit.MODES[car.engine_mode][1] if car.car_data.has_parts() else 0.0


## Seconds lost per kg saved by lift and coast.
static func fuel_save_cost(car: SimCar) -> float:
	return lerpf(SimTuning.FUEL_SAVE_COST_WEAK, SimTuning.FUEL_SAVE_COST_ACE, car.driver.fuel_management / 100.0)


# --- Weather -------------------------------------------------------------------

static func weather_s(car: SimCar, model: TrackModel, wetness: float) -> float:
	if wetness <= 0.0:
		return SimTuning.RAIN_SETUP[car.rain_setup][0] * model.scale
	var general := model.reference_lap_s * SimTuning.WET_GENERAL_FRAC * wetness
	var skill := (SimTuning.WET_SKILL_CENTER - car.driver.wet_skill) * SimTuning.WET_SKILL_S * wetness * model.scale
	var setup_pair: Array = SimTuning.RAIN_SETUP[car.rain_setup]
	var setup := lerpf(setup_pair[0], setup_pair[1], clampf(wetness * 2.0, 0.0, 1.0)) * model.scale
	return general + skill + setup


# --- Mistakes ------------------------------------------------------------------

## Chance of a mistake this lap. context: {"progress", "duel", "wetness",
## "spray", "stint_share", "title_fight"}
static func mistake_chance(car: SimCar, context: Dictionary) -> float:
	var d := car.driver
	var p := SimTuning.MISTAKE_BASE
	p *= lerpf(2.0, 0.5, d.consistency / 100.0)
	# Focus fades late in a stint.
	var focus := clampf(d.focus + car.talk_value("focus"), 0.0, 100.0)
	p *= 1.0 + context.get("stint_share", 0.0) * (1.0 - focus / 100.0)
	# Pressure: duels, last laps, title fights.
	var pressure := 0.0
	if context.get("duel", false):
		pressure += 0.5
	if context.get("progress", 0.0) > 0.92:
		pressure += 0.4
	if context.get("title_fight", false):
		pressure += 0.3
	var composure := composure_value(car)
	p *= 1.0 + pressure * (1.0 - composure / 100.0)
	var w: float = context.get("wetness", 0.0)
	p *= 1.0 + 3.0 * w * (1.2 - d.wet_skill / 100.0)
	p *= PowerUnit.wet_mistake_factor(car.car_data.engine_drivability, w)
	if context.get("spray", false):
		p *= SimTuning.SPRAY_MISTAKE
	var life_used: float = context.get("tyre_over_cliff", 0.0)
	if life_used > 0.0 or absf(car.tyre_temp) > 0.6:
		p *= 2.0
	p *= 1.0 + SimTuning.SETUP_MAX_MISTAKE * setup_badness(car)
	var fitness := d.fitness + (car.ops.physical_training - 50) * 0.1
	if context.get("progress", 0.0) > SimTuning.FITNESS_LATE_FROM:
		p *= 1.0 + 0.6 * (1.0 - fitness / 100.0)
	p *= 1.0 + car.talk_value("mistake") + _briefing_value(car, "mistake")
	return maxf(p, 0.0)


## Composure incl. traits, talk and the mental coach.
static func composure_value(car: SimCar) -> float:
	var d := car.driver
	var c := d.composure + car.talk_value("composure") + _briefing_value(car, "composure") \
		+ (car.ops.pressure_training - 50) * 0.1
	if d.traits.has(&"clutch"):
		c += 10.0
	if d.traits.has(&"glass_nerves"):
		c -= 15.0
	return clampf(c, 0.0, 100.0)


## Aggression 0..1 incl. briefing, talk and traits.
static func aggression(car: SimCar) -> float:
	var a := car.driver.aggression / 100.0
	a += car.talk_value("aggression") + _briefing_value(car, "aggression")
	if car.driver.traits.has(&"hot_headed"):
		a += 0.15
	return clampf(a, 0.0, 1.0)


# --- Briefing ------------------------------------------------------------------

## Effects of the tactical briefing (design doc 11.1).
const BRIEFING_EFFECTS := {
	SimCar.Briefing.BRING_HOME: {"mistake": -0.15, "aggression": -0.3, "tyre_wear": -0.05},
	SimCar.Briefing.ATTACK: {"aggression": 0.3, "tyre_wear": 0.08, "contact": 0.1, "pace_s": -0.05},
	SimCar.Briefing.NO_PRESSURE: {"mistake": -0.08, "aggression": -0.1, "composure": 6.0},
	SimCar.Briefing.TEAM_PLAYER: {"team_orders": 1.0},
	SimCar.Briefing.NORMAL: {},
}


static func _briefing_value(car: SimCar, key: String) -> float:
	var effects: Dictionary = BRIEFING_EFFECTS[car.briefing]
	var v: float = effects.get(key, 0.0)
	# Hot heads take "attack" further than calm drivers.
	if key == "contact" and car.driver.temperament < 40:
		v *= 1.5
	return v


static func briefing_value(car: SimCar, key: String) -> float:
	return _briefing_value(car, key)
