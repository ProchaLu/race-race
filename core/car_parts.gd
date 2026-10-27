## The 13 parts of a car (docs/car_model.md, sections 1, 2, 3 and 9): what
## each part affects, how heavy it is, how long it takes to develop and build,
## what it costs and which development goals it offers. Starting numbers of
## the model; balanced with the sim lab.
class_name CarParts
extends RefCounted

const ORDER: Array[StringName] = [&"front_wing", &"rear_wing", &"floor", &"diffuser", &"sidepods",
	&"engine_cover", &"monocoque", &"suspension_front", &"suspension_rear", &"brakes", &"gearbox",
	&"cooling", &"exhaust"]

## [name, area, mass kg, test kind ("aero" = CFD + wind tunnel, "rig" = test rigs),
##  work days [concept, design, test, production per unit], costs [design, per unit],
##  base gain (part points), goals]
const PARTS := {
	&"front_wing": ["Front wing", "Aero", 8.0, "aero", [3, 20, 10, 4], [800_000, 120_000], 10.8,
		["downforce", "efficiency", "drag", "weight"]],
	&"rear_wing": ["Rear wing", "Aero", 7.0, "aero", [3, 16, 8, 3], [700_000, 90_000], 10.8,
		["drag", "downforce", "efficiency", "weight"]],
	&"floor": ["Floor", "Aero", 25.0, "aero", [5, 30, 16, 6], [1_500_000, 250_000], 14.4,
		["downforce", "efficiency", "tyres", "weight"]],
	&"diffuser": ["Diffuser", "Aero", 8.0, "aero", [3, 20, 10, 3], [800_000, 100_000], 10.8,
		["downforce", "efficiency", "traction", "weight"]],
	&"sidepods": ["Sidepods", "Aero", 12.0, "aero", [4, 24, 10, 4], [1_000_000, 150_000], 9.0,
		["drag", "cooling", "weight"]],
	&"engine_cover": ["Engine cover", "Aero", 4.0, "aero", [2, 10, 4, 2], [400_000, 40_000], 5.4,
		["drag", "cooling", "weight"]],
	&"monocoque": ["Monocoque", "Chassis", 45.0, "rig", [10, 75, 25, 20], [4_000_000, 1_200_000], 14.4,
		["mech", "weight", "reliability"]],
	&"suspension_front": ["Front suspension", "Chassis", 18.0, "rig", [4, 24, 10, 5], [1_000_000, 180_000], 9.0,
		["mech", "tyres", "weight", "reliability"]],
	&"suspension_rear": ["Rear suspension", "Chassis", 18.0, "rig", [4, 24, 10, 5], [1_000_000, 180_000], 9.0,
		["mech", "traction", "tyres", "weight", "reliability"]],
	&"brakes": ["Brakes", "Chassis", 14.0, "rig", [3, 14, 8, 2], [600_000, 60_000], 7.2,
		["braking", "brake_cooling", "weight"]],
	&"gearbox": ["Gearbox", "Drivetrain", 40.0, "rig", [5, 36, 14, 8], [2_000_000, 400_000], 7.2,
		["reliability", "traction", "weight"]],
	&"cooling": ["Cooling", "Drivetrain", 15.0, "rig", [3, 16, 8, 3], [600_000, 80_000], 9.0,
		["cooling", "compact", "reliability"]],
	&"exhaust": ["Exhaust", "Drivetrain", 8.0, "rig", [2, 10, 5, 2], [400_000, 30_000], 5.4,
		["power", "reliability", "weight"]],
}

## Share of every part in a car value (docs/car_model.md 2.1).
const WEIGHTS := {
	&"downforce": {&"floor": 0.30, &"front_wing": 0.20, &"rear_wing": 0.20, &"diffuser": 0.15,
		&"sidepods": 0.08, &"engine_cover": 0.07},
	&"drag_efficiency": {&"rear_wing": 0.30, &"sidepods": 0.20, &"cooling": 0.15, &"engine_cover": 0.15,
		&"front_wing": 0.10, &"floor": 0.10},
	&"mechanical_grip": {&"suspension_front": 0.32, &"suspension_rear": 0.32, &"monocoque": 0.18,
		&"brakes": 0.10, &"diffuser": 0.08},
	&"tyre_preservation": {&"suspension_rear": 0.25, &"suspension_front": 0.20, &"floor": 0.20,
		&"diffuser": 0.15, &"monocoque": 0.10, &"brakes": 0.10},
	&"braking": {&"brakes": 0.70, &"suspension_front": 0.20, &"monocoque": 0.10},
	&"traction": {&"suspension_rear": 0.40, &"diffuser": 0.30, &"gearbox": 0.20, &"exhaust": 0.10},
	&"cooling": {&"cooling": 0.55, &"sidepods": 0.30, &"engine_cover": 0.15},
}

## Display names of the car values.
const VALUE_NAMES := {
	&"downforce": "Downforce", &"drag_efficiency": "Drag efficiency", &"mechanical_grip": "Mechanical grip",
	&"tyre_preservation": "Tyre preservation", &"braking": "Braking", &"traction": "Traction",
	&"cooling": "Cooling", &"reliability": "Reliability", &"power": "Engine power", &"mass": "Weight",
}

## [name, description, effects]: effects are shares of the gain per value;
## "mass" is kg per gain point (negative = lighter), "reliability" and
## "power" are part values too.
const GOALS := {
	"downforce": ["More downforce", "+Downforce, a little more drag", {&"downforce": 1.0, &"drag_efficiency": -0.3}],
	"efficiency": ["Efficiency", "+Downforce at the same drag (60 % of the gain)", {&"downforce": 0.6}],
	"drag": ["Less drag", "+Drag efficiency, a little less downforce", {&"drag_efficiency": 1.0, &"downforce": -0.3}],
	"weight": ["Save weight", "Lighter part, slightly less reliable", {&"mass": -0.2, &"reliability": -0.3}],
	"mech": ["More mechanical grip", "+Mechanical grip", {&"mechanical_grip": 1.0}],
	"tyres": ["Tyre preservation", "+Tyre preservation", {&"tyre_preservation": 1.0}],
	"traction": ["Traction", "+Traction out of slow corners", {&"traction": 1.0}],
	"braking": ["Braking performance", "+Braking", {&"braking": 1.0}],
	"brake_cooling": ["Brake cooling", "+Reliability, a little more drag", {&"reliability": 1.0, &"drag_efficiency": -0.2}],
	"cooling": ["More cooling", "+Cooling, a little more drag", {&"cooling": 1.0, &"drag_efficiency": -0.3}],
	"compact": ["Compact package", "+Drag efficiency, a little less cooling", {&"drag_efficiency": 0.8, &"cooling": -0.3}],
	"reliability": ["Reliability", "+Reliability", {&"reliability": 1.0}],
	"power": ["More power", "+Engine power, slightly less reliable", {&"power": 1.0, &"reliability": -0.2}],
}

## Ideas the team can come up with per part (docs/car_model.md 3a):
## [name, direction (a GOALS key)]. The real effect is rolled per project.
const IDEAS := {
	&"front_wing": [["Extra flap element (outer section)", "downforce"], ["Revised endplate with outwash slot", "tyres"],
		["Thinner main plane", "drag"], ["New nose junction", "efficiency"], ["Flap angle optimisation", "downforce"],
		["Lighter carbon layup", "weight"]],
	&"rear_wing": [["Spoon-shaped main plane", "drag"], ["Revised endplate tips", "efficiency"], ["Bigger beam wing", "downforce"],
		["Shallower flap", "drag"], ["Stiffer pillar mount", "efficiency"], ["Lighter layup", "weight"]],
	&"floor": [["New floor edge wing", "downforce"], ["Revised venturi tunnels", "downforce"], ["Floor fences realigned", "efficiency"],
		["Stiffer floor stays", "tyres"], ["Edge vortex generators", "efficiency"], ["Lighter floor body", "weight"]],
	&"diffuser": [["Steeper kick-up", "downforce"], ["Revised diffuser strakes", "efficiency"], ["Gurney flap on the exit", "downforce"],
		["Rear tyre wake management", "traction"], ["Lighter diffuser", "weight"]],
	&"sidepods": [["Downwash ramp", "drag"], ["Smaller inlet", "drag"], ["Bigger inlet", "cooling"], ["Undercut deeper", "drag"],
		["Gill louvres", "cooling"], ["Lighter bodywork", "weight"]],
	&"engine_cover": [["Narrower coke bottle", "drag"], ["Cooling outlet louvres", "cooling"], ["Shark fin trimmed", "drag"],
		["Bigger rear outlet", "cooling"], ["Thinner skin", "weight"]],
	&"monocoque": [["Stiffer tub layup", "mech"], ["Lower driver position", "mech"], ["New survival cell layup", "weight"],
		["Revised side impact structure", "reliability"], ["Packaging for a smaller cooling system", "mech"]],
	&"suspension_front": [["Push-rod to pull-rod", "mech"], ["New wishbone geometry", "mech"], ["Anti-dive geometry", "tyres"],
		["Hydraulic heave element", "mech"], ["Titanium uprights", "weight"], ["Stronger mounts", "reliability"]],
	&"suspension_rear": [["Anti-squat geometry", "traction"], ["New rear upright", "mech"], ["Softer rear roll stiffness", "tyres"],
		["Inerter", "traction"], ["Lighter rocker", "weight"], ["Stronger mounts", "reliability"]],
	&"brakes": [["New caliper design", "braking"], ["Bigger cooling drums", "brake_cooling"], ["Carbon disc with more holes", "braking"],
		["Brake-by-wire mapping", "braking"], ["Lighter calipers", "weight"]],
	&"gearbox": [["Seamless-shift rework", "traction"], ["New bearings", "reliability"], ["Lighter casing", "weight"],
		["Revised oil system", "reliability"], ["Shorter gear stack", "traction"]],
	&"cooling": [["Bigger radiators", "cooling"], ["Compact radiator layout", "compact"], ["Better oil cooler", "reliability"],
		["Electric water pump", "compact"], ["New heat exchanger", "cooling"]],
	&"exhaust": [["Revised tailpipe angle", "power"], ["Thinner primaries", "power"], ["Heat shielding", "reliability"],
		["Inconel to titanium", "weight"], ["Wastegate pipe reshaped", "power"]],
}

## The value a part is judged by (overview colours, field rank).
const MAIN_VALUE := {
	&"front_wing": &"downforce", &"rear_wing": &"drag_efficiency", &"floor": &"downforce",
	&"diffuser": &"downforce", &"sidepods": &"drag_efficiency", &"engine_cover": &"drag_efficiency",
	&"monocoque": &"mechanical_grip", &"suspension_front": &"mechanical_grip", &"suspension_rear": &"traction",
	&"brakes": &"braking", &"gearbox": &"reliability", &"cooling": &"cooling", &"exhaust": &"power",
}

## Failure risk per race at reliability 50 and its texts: [base, fatal, partial]
## (docs/car_model.md 2.4). Sum over an average car ≈ 5 % per driver and race.
const FAILURES := {
	&"gearbox": [0.012, "Gearbox failure", "Gearbox problem"],
	&"cooling": [0.006, "Overheating", "Power loss"],
	&"brakes": [0.005, "Brake failure", "Brake problem"],
	&"suspension_front": [0.003, "Suspension failure", ""],
	&"suspension_rear": [0.003, "Suspension failure", ""],
	&"exhaust": [0.003, "", "Power loss"],
	&"monocoque": [0.008, "Hydraulics failure", "Electrical problem"],
}
## The engine stays a fixed team value until R5.
const ENGINE_FAILURE := 0.010
const AERO_PART_FAILURE := 0.001


static func name_of(part_id: StringName) -> String:
	return PARTS[part_id][0]


static func area_of(part_id: StringName) -> String:
	return PARTS[part_id][1]


static func base_mass(part_id: StringName) -> float:
	return PARTS[part_id][2]


static func test_kind(part_id: StringName) -> String:
	return PARTS[part_id][3]


static func goals_of(part_id: StringName) -> Array:
	return PARTS[part_id][7]


## The values this part has: every car value it has a share in, plus
## reliability (and power for the exhaust).
static func values_of(part_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for value in WEIGHTS:
		if WEIGHTS[value].has(part_id):
			out.append(value)
	out.append(&"reliability")
	if part_id == &"exhaust":
		out.append(&"power")
	return out


## Monocoques are homologated: only next season's car gets a new one (R3d).
static func in_season(part_id: StringName) -> bool:
	return part_id != &"monocoque"
