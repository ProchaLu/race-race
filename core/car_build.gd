## The car as the sum of its parts (docs/car_model.md 2): car values are the
## weighted average of the fitted parts, plus weight, cooling and the engine
## bonus of the exhaust. Also builds the parts of the start world and the
## new car over the winter.
class_name CarBuild
extends RefCounted

const MIN_MASS := 798.0
const DRIVER_MASS := 80.0
## Engine, electronics, tank, wheels … – everything but the 13 parts and the driver.
const FIXED_MASS := MIN_MASS - DRIVER_MASS - 222.0
## Ballast below the minimum weight can be placed freely: small grip bonus.
const BALLAST_GRIP_PER_KG := 0.2
const BALLAST_GRIP_MAX := 1.0
## Exhaust power value 50 = no bonus; each point ±0.08 engine points.
const EXHAUST_POWER := 0.08
## Typical share of corner types over the calendar (for lap time estimates).
const TYPICAL_TRACK := {TrackSegment.Type.STRAIGHT: 0.42, TrackSegment.Type.FAST_CORNER: 0.2,
	TrackSegment.Type.MEDIUM_CORNER: 0.22, TrackSegment.Type.SLOW_CORNER: 0.16}
## Winter: share of the development that goes into the new car (R3d replaces this).
const CARRY_OVER := 0.75


# --- Start world -------------------------------------------------------------

## Builds 13 parts that add up to the car's current values. overweight_kg:
## how far the car is over the minimum weight.
static func init_from_ratings(car: CarData, overweight_kg: float, year: int, r: RandomNumberGenerator) -> void:
	car.engine_base = car.engine_power
	var targets := {
		&"downforce": car.downforce, &"drag_efficiency": car.drag_efficiency,
		&"mechanical_grip": car.mechanical_grip, &"tyre_preservation": car.tyre_preservation,
		&"braking": car.mechanical_grip + r.randi_range(-4, 4), &"traction": car.mechanical_grip + r.randi_range(-4, 4),
		&"cooling": clampi(50 + (car.reliability - 70) / 2 + r.randi_range(-6, 6), 35, 75),
	}
	var total_mass := 0.0
	for id in CarParts.ORDER:
		total_mass += CarParts.base_mass(id)
	car.parts.clear()
	car.part_history.clear()
	for id in CarParts.ORDER:
		var p := PartVersion.new()
		p.part_id = id
		p.season = year
		for key in CarParts.values_of(id):
			match key:
				&"reliability":
					p.values[key] = clampf(car.reliability + r.randf_range(-8.0, 8.0), 40.0, 98.0)
				&"power":
					p.values[key] = clampf(50.0 + r.randf_range(-6.0, 6.0), 30.0, 70.0)
				_:
					p.values[key] = float(targets[key]) + r.randfn(0.0, 4.0)
		var base := CarParts.base_mass(id)
		p.mass_kg = base + overweight_kg * base / total_mass + r.randf_range(-0.2, 0.2)
		car.parts[id] = p
		car.part_history[id] = [p]
	# Shift every value so the weighted average hits the target exactly.
	for key in CarParts.WEIGHTS:
		var shift: float = targets[key] - _weighted(car, key)
		for id in CarParts.WEIGHTS[key]:
			var p: PartVersion = car.parts[id]
			p.values[key] = clampf(p.values[key] + shift, 1.0, 100.0)
	recalculate(car)
	car.season_start = snapshot(car)


# --- From the parts to the car -----------------------------------------------

static func recalculate(car: CarData) -> void:
	if not car.has_parts():
		return
	car.downforce = roundi(_weighted(car, &"downforce"))
	car.drag_efficiency = roundi(_weighted(car, &"drag_efficiency"))
	car.tyre_preservation = roundi(_weighted(car, &"tyre_preservation"))
	car.braking = roundi(_weighted(car, &"braking"))
	car.traction = roundi(_weighted(car, &"traction"))
	car.cooling = roundi(_weighted(car, &"cooling"))
	var mass := FIXED_MASS + DRIVER_MASS
	for p in car.parts.values():
		mass += p.mass_kg
	car.mass_kg = mass
	var grip := _weighted(car, &"mechanical_grip")
	if mass < MIN_MASS:
		grip += minf((MIN_MASS - mass) * BALLAST_GRIP_PER_KG, BALLAST_GRIP_MAX)
	car.mechanical_grip = roundi(grip)
	var exhaust: PartVersion = car.parts.get(&"exhaust")
	var bonus := (exhaust.value(&"power") - 50.0) * EXHAUST_POWER if exhaust else 0.0
	car.engine_power = clampi(roundi(car.engine_base + bonus), 1, 100)


static func _weighted(car: CarData, key: StringName) -> float:
	var total := 0.0
	var weight := 0.0
	for id in CarParts.WEIGHTS[key]:
		var p: PartVersion = car.parts.get(id)
		if p:
			total += p.value(key) * CarParts.WEIGHTS[key][id]
			weight += CarParts.WEIGHTS[key][id]
	return total / weight if weight > 0.0 else 50.0


## Car values for comparisons: {value: number}; mass in kg.
static func snapshot(car: CarData) -> Dictionary:
	return {&"downforce": car.downforce, &"drag_efficiency": car.drag_efficiency,
		&"mechanical_grip": car.mechanical_grip, &"tyre_preservation": car.tyre_preservation,
		&"braking": car.braking_value(), &"traction": car.traction_value(), &"cooling": car.cooling,
		&"reliability": average_reliability(car), &"power": car.engine_power, &"mass": car.mass_kg}


## Average reliability of the parts that can fail, with the engine.
static func average_reliability(car: CarData) -> int:
	if not car.has_parts():
		return car.reliability
	var total := float(car.reliability)
	var n := 1
	for id in CarParts.FAILURES:
		total += car.parts[id].value(&"reliability")
		n += 1
	return roundi(total / n)


# --- Lap time --------------------------------------------------------------

## Seconds per 90 s lap for one point of a car value on a typical track.
static func seconds_per_point(key: StringName) -> float:
	var index := {&"engine_power": 0, &"power": 0, &"drag_efficiency": 1, &"downforce": 2, &"mechanical_grip": 3,
		&"braking": 4, &"traction": 5}
	if not index.has(key):
		return 0.0
	var s := 0.0
	for kind in TYPICAL_TRACK:
		s += TYPICAL_TRACK[kind] * SimTuning.CAR_WEIGHTS[kind][index[key]]
	return s * SimTuning.CAR_FRAC_PER_POINT * SimTuning.REFERENCE_LAP_S


## Lap time effect (s per 90 s lap; negative = faster) of changes to a part:
## {value: change} with "mass" in kg. Tyres, cooling and reliability do not
## change the pure lap time and count 0 here. car_mass: weight only counts
## above the minimum (0 = always counts).
static func lap_effect(part_id: StringName, delta: Dictionary, car_mass: float = 0.0) -> float:
	var s := 0.0
	for key in delta:
		if key == &"mass":
			var kg: float = delta[key]
			if car_mass > 0.0:
				var over := maxf(0.0, car_mass - MIN_MASS)
				kg = clampf(kg, -over, maxf(0.0, car_mass + kg - MIN_MASS))
			s += kg * SimTuning.FUEL_S_PER_KG
		elif key == &"power":
			s -= delta[key] * EXHAUST_POWER * seconds_per_point(&"power")
		elif CarParts.WEIGHTS.has(key) and CarParts.WEIGHTS[key].has(part_id):
			s -= delta[key] * CarParts.WEIGHTS[key][part_id] * seconds_per_point(key)
	return s


## A car's lap time compared with the field average (s per 90 s lap).
static func lap_vs_field(team_id: StringName) -> float:
	var car: CarData = GameState.teams[team_id].car
	var s := 0.0
	for key in [&"engine_power", &"drag_efficiency", &"downforce", &"mechanical_grip", &"braking", &"traction"]:
		s -= (_car_value(car, key) - field_average(key)) * seconds_per_point(key)
	s += (maxf(car.mass_kg, MIN_MASS) - field_average(&"mass")) * SimTuning.FUEL_S_PER_KG
	return s


static func _car_value(car: CarData, key: StringName) -> float:
	match key:
		&"braking":
			return car.braking_value()
		&"traction":
			return car.traction_value()
		&"mass":
			return maxf(car.mass_kg, MIN_MASS)
		&"reliability":
			return average_reliability(car)
	return float(car.get(key))


static func _series_cars(team_id: StringName) -> Array:
	var s: SeriesData = GameState.series[GameState.teams[team_id].series_id]
	return s.team_ids.map(func(id): return GameState.teams[id].car)


static func field_average(key: StringName, team_id: StringName = &"") -> float:
	var cars := _series_cars(team_id if team_id != &"" else GameState.player_team_id)
	var total := 0.0
	for car in cars:
		total += _car_value(car, key)
	return total / maxf(cars.size(), 1)


## 1 = best in the field. Lighter is better for mass.
static func field_rank(team_id: StringName, key: StringName) -> int:
	var mine := _car_value(GameState.teams[team_id].car, key)
	var rank := 1
	for car in _series_cars(team_id):
		var v := _car_value(car, key)
		if (v < mine if key == &"mass" else v > mine):
			rank += 1
	return rank


## Rank of one part among the same part of all teams (by its main value).
static func part_rank(team_id: StringName, part_id: StringName) -> int:
	var key: StringName = CarParts.MAIN_VALUE[part_id]
	var mine: PartVersion = GameState.teams[team_id].car.parts.get(part_id)
	if not mine:
		return 0
	var rank := 1
	for car in _series_cars(team_id):
		var other: PartVersion = car.parts.get(part_id)
		if other and other.value(key) > mine.value(key):
			rank += 1
	return rank


# --- Parts per car (docs/car_model.md 7–8) ------------------------------------

static func version_of(car: CarData, part_id: StringName, number: int) -> PartVersion:
	for v in car.part_history.get(part_id, []):
		if v.version == number:
			return v
	return null


## The version fitted to a driver's car (default: the newest).
static func fitted_version(team: TeamData, driver_id: StringName, part_id: StringName) -> PartVersion:
	var fit: Dictionary = team.car_fit.get(driver_id, {})
	var v := version_of(team.car, part_id, fit.get(part_id, -1))
	return v if v else team.car.parts[part_id]


static func fitted_count(team: TeamData, part_id: StringName, number: int) -> int:
	var n := 0
	for d in GameState.drivers_of_team(team.id):
		if fitted_version(team, d.id, part_id).version == number:
			n += 1
	return n


## The car a driver races: the team car with his fitted versions.
static func car_for(team: TeamData, driver_id: StringName) -> CarData:
	var base := team.car
	if not base.has_parts():
		return base
	var c: CarData = base.duplicate()
	c.parts = {}
	for id in CarParts.ORDER:
		c.parts[id] = fitted_version(team, driver_id, id)
	recalculate(c)
	return c


## Drivers in the order they get scarce parts: the given one first, then the
## No.1, then the better placed driver.
static func priority_order(team: TeamData, first: StringName = &"") -> Array[DriverData]:
	var drivers := GameState.drivers_of_team(team.id)
	drivers.sort_custom(func(a: DriverData, b: DriverData):
		if a.id == first or b.id == first:
			return a.id == first
		var ca := GameState.contract_of(a.id)
		var cb := GameState.contract_of(b.id)
		var a1 := ca and ca.role == ContractData.DriverRole.NUMBER_ONE
		var b1 := cb and cb.role == ContractData.DriverRole.NUMBER_ONE
		if a1 != b1:
			return a1
		var pa := GameState.championship_position(a.id)
		var pb := GameState.championship_position(b.id)
		return (pa if pa > 0 else 99) < (pb if pb > 0 else 99))
	return drivers


## Gives every car the newest version that still has a unit for it.
## Returns the names of the drivers who get the newest version.
static func assign(team: TeamData, part_id: StringName, first: StringName = &"") -> Array:
	var history: Array = team.car.part_history.get(part_id, [])
	var left := {}
	for v in history:
		left[v.version] = v.units
	var newest: int = team.car.parts[part_id].version if team.car.parts.has(part_id) else 1
	var names := []
	for d in priority_order(team, first):
		var pick := -1
		for i in range(history.size() - 1, -1, -1):
			var v: PartVersion = history[i]
			if v.version <= newest and left[v.version] > 0:
				pick = v.version
				left[v.version] -= 1
				break
		if pick < 0:
			pick = newest
		if not team.car_fit.has(d.id):
			team.car_fit[d.id] = {}
		team.car_fit[d.id][part_id] = pick
		if pick == newest:
			names.append(d.full_name())
	return names


static func fit_new_version(team: TeamData, v: PartVersion) -> Array:
	return assign(team, v.part_id)


static func refit_where_missing(team: TeamData) -> void:
	for id in CarParts.ORDER:
		assign(team, id)


## A unit of the driver's fitted part is destroyed (crash, wear).
static func consume(team: TeamData, driver_id: StringName, part_id: StringName) -> void:
	var v := fitted_version(team, driver_id, part_id)
	v.units = maxi(0, v.units - 1)
	assign(team, part_id)


## Before a race weekend: every car needs a unit of every part. Missing
## ones are built overnight at double cost.
static func ensure_raceable(team: TeamData) -> int:
	var cost := 0
	var cars := GameState.drivers_of_team(team.id).size()
	for id in CarParts.ORDER:
		var total := 0
		for v in team.car.part_history.get(id, []):
			total += v.units
		if total < cars:
			var newest: PartVersion = team.car.parts[id]
			var missing := cars - total
			newest.units += missing
			cost += CarDevelopment.unit_cost(team, id) * 2 * missing
			assign(team, id)
	if cost > 0:
		CarDevelopment._pay(team, cost)
	return cost


# --- Winter ------------------------------------------------------------------

## New car for every team: each part moves back towards the field average
## (CARRY_OVER of the lead is kept) plus what was developed for next season;
## versions start again at 1 and three units of every part are built.
## Returns team ID -> [old average, new average] of the four main values.
static func new_season(year: int, r: RandomNumberGenerator) -> Dictionary:
	var out := {}
	var teams: Array = GameState.teams.values().filter(func(t): return t.car.has_parts())
	var means := {}
	for id in CarParts.ORDER:
		for key in CarParts.values_of(id):
			var total := 0.0
			for t in teams:
				total += t.car.parts[id].value(key)
			means["%s|%s" % [id, key]] = total / maxf(teams.size(), 1)
	for t in teams:
		var car: CarData = t.car
		var before := (car.downforce + car.drag_efficiency + car.engine_power + car.mechanical_grip) / 4.0
		for id in CarParts.ORDER:
			var old: PartVersion = car.parts[id]
			var p := PartVersion.new()
			p.part_id = id
			p.season = year
			p.version = 1
			p.mass_kg = old.mass_kg
			var next: Dictionary = t.next_year_parts.get(id, {})
			for key in old.values:
				var mean: float = means["%s|%s" % [id, key]]
				var target := 50.0 if key != &"reliability" else mean
				p.values[key] = clampf(target + CARRY_OVER * (old.values[key] - mean) + next.get(key, 0.0)
					+ r.randfn(0.0, 1.5), 1.0, 100.0)
			p.mass_kg = maxf(old.mass_kg + next.get(&"mass", 0.0), CarParts.base_mass(id) * 0.6)
			p.units = 3
			car.parts[id] = p
			car.part_history[id] = [p]
		car.season = year
		t.next_year_parts = {}
		t.car_fit = {}
		t.next_year_share = 0.0
		CarDevelopment.set_departments(t)
		# The new car: three units of every part.
		var build := 0
		for id in CarParts.ORDER:
			build += CarDevelopment.unit_cost(t, id) * 3
		CarDevelopment._pay(t, build)
		recalculate(car)
		car.season_start = snapshot(car)
		out[t.id] = [before, (car.downforce + car.drag_efficiency + car.engine_power + car.mechanical_grip) / 4.0]
	return out
