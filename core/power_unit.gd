## The power unit (docs/engine_model.md 2, 4, 7): five components give five
## engine values; formulas for what the values do in the race, how engine
## units wear and what the engine modes cost. Pure data and maths.
class_name PowerUnit
extends RefCounted

const COMPONENTS := [&"ice", &"turbo", &"ers", &"battery", &"control"]
const COMPONENT_NAMES := {&"ice": "Combustion engine", &"turbo": "Turbocharger", &"ers": "Energy recovery",
	&"battery": "Battery", &"control": "Control electronics"}
const COMPONENT_SHORT := {&"ice": "ICE", &"turbo": "TURBO", &"ers": "ERS", &"battery": "BATT", &"control": "CTRL"}
const VALUES := [&"power", &"efficiency", &"reliability", &"weight", &"drivability"]
const VALUE_NAMES := {&"power": "Power", &"efficiency": "Efficiency", &"reliability": "Reliability",
	&"weight": "Weight", &"drivability": "Drivability"}
## Share of each component in each engine value (docs/engine_model.md 2).
const WEIGHTS := {
	&"power": {&"ice": 0.45, &"turbo": 0.25, &"ers": 0.20, &"battery": 0.10},
	&"efficiency": {&"ice": 0.35, &"turbo": 0.15, &"ers": 0.25, &"battery": 0.10, &"control": 0.15},
	&"reliability": {&"ice": 0.30, &"turbo": 0.15, &"ers": 0.20, &"battery": 0.15, &"control": 0.20},
	&"weight": {&"ice": 0.35, &"turbo": 0.10, &"ers": 0.20, &"battery": 0.30, &"control": 0.05},
	&"drivability": {&"ice": 0.25, &"turbo": 0.25, &"ers": 0.10, &"battery": 0.10, &"control": 0.30},
}
## Ideas of the engine design office per component: [name, focus value].
const IDEAS := {
	&"ice": [["New combustion chamber", "power"], ["Higher compression ratio", "power"], ["Pre-chamber ignition", "efficiency"],
		["Low-friction coatings", "efficiency"], ["Stronger crankshaft", "reliability"], ["Lighter block casting", "weight"]],
	&"turbo": [["Bigger compressor stage", "power"], ["New bearing", "reliability"], ["Lighter housing", "weight"],
		["Electric spool-up", "drivability"], ["Thermal insulation", "efficiency"]],
	&"ers": [["Stronger MGU-K", "power"], ["Better heat recovery", "efficiency"], ["New inverter cooling", "reliability"],
		["Smoother deployment map", "drivability"], ["Lighter motor windings", "weight"]],
	&"battery": [["New cell chemistry", "power"], ["Lighter casing", "weight"], ["Better cell cooling", "reliability"],
		["Higher energy density", "efficiency"], ["Faster charging", "drivability"]],
	&"control": [["New torque map", "drivability"], ["Smarter energy management", "efficiency"], ["Redundant sensors", "reliability"],
		["Faster processor", "drivability"], ["Lighter wiring loom", "weight"]],
}

## Engine units per driver and season in the contract (penalties: R9).
const UNITS_PER_SEASON := 4
const EXTRA_UNIT_COST := 1_500_000
## Distance of a weekend before the race (practice and the qualifying laps).
const PRACTICE_KM := 250.0
const QUALI_KM := 25.0
## Power unit mass at weight value 50 and kg per point.
const MASS_AT_50 := 152.0
const MASS_PER_POINT := 0.25
## [name, power, wear, heat, fuel factor, description]
const MODES := [
	["Qualifying", 3.0, 4.0, 6.0, 1.0, "+3 power · wear ×4 · qualifying only"],
	["Push", 1.5, 1.6, 4.0, 1.04, "+1.5 power · wear ×1.6 · heat +4 · fuel +4 %"],
	["Normal", 0.0, 1.0, 0.0, 1.0, "baseline"],
	["Save", -1.5, 0.7, -4.0, 0.96, "−1.5 power · wear ×0.7 · heat −4 · fuel −4 %"],
]
enum Mode { QUALIFYING, PUSH, NORMAL, SAVE }


static func name_of(component: StringName) -> String:
	return COMPONENT_NAMES[component]


## Engine values (0..100) from component values {component: {value: x}}.
static func compute(components: Dictionary) -> Dictionary:
	var out := {}
	for value in VALUES:
		var total := 0.0
		var weight := 0.0
		for c in WEIGHTS[value]:
			if components.has(c) and components[c].has(value):
				total += components[c][value] * WEIGHTS[value][c]
				weight += WEIGHTS[value][c]
		out[value] = total / weight if weight > 0.0 else 50.0
	return out


## Values a component has (control electronics give no power).
static func values_of(component: StringName) -> Array:
	return VALUES.filter(func(v): return WEIGHTS[v].has(component))


# --- What the values do --------------------------------------------------------

static func mass_kg(weight_value: float) -> float:
	return MASS_AT_50 - (weight_value - 50.0) * MASS_PER_POINT


## Fuel use relative to an average engine.
static func fuel_factor(efficiency: float) -> float:
	return 1.15 - 0.3 * efficiency / 100.0


static func failure_factor(reliability: float) -> float:
	return 1.6 - reliability / 100.0


## Lifetime of a unit in km: 3 500 (reliability 20) to 5 200 (reliability 90) –
## about 5–7 race weekends, so 4 units just cover a season.
static func life_km(reliability: float) -> float:
	return lerpf(3500.0, 5200.0, clampf((reliability - 20.0) / 70.0, 0.0, 1.0))


static func traction_bonus(drivability: float) -> float:
	return (drivability - 50.0) * 0.1


static func tyre_wear_factor(drivability: float) -> float:
	return 1.0 + (50.0 - drivability) / 500.0


static func wet_mistake_factor(drivability: float, wetness: float) -> float:
	return 1.0 + (50.0 - drivability) / 150.0 * wetness


# --- Wear ----------------------------------------------------------------------

## Power lost by a worn unit: from 70 % of its life, −0.5 per 10 % (max −2).
static func wear_power_loss(km: float, life: float) -> float:
	var used := km / maxf(life, 1.0)
	return clampf((used - 0.7) * 5.0, 0.0, 2.0)


## Failure risk multiplier: ×1 up to 70 %, ×2.5 at 100 %, steep beyond.
static func wear_risk(km: float, life: float) -> float:
	var used := km / maxf(life, 1.0)
	if used <= 0.7:
		return 1.0
	if used <= 1.0:
		return lerpf(1.0, 2.5, (used - 0.7) / 0.3)
	return 2.5 + (used - 1.0) * 10.0
