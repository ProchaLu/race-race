## A car development project – the development lab (docs/car_model.md 3a):
## the old part is the baseline; the team has ideas, simulates them (CFD /
## kinematics), measures the best in the wind tunnel or on the rigs (combine,
## refine), freezes a variant, makes the tooling and builds the units.
## Each idea's real effect is hidden; the team only sees measurements with
## an uncertainty until the part has raced.
class_name DevProject
extends Resource

enum Phase { CONCEPT, CFD, TUNNEL, DETAIL, TOOLING, PRODUCTION, QUALITY, READY }
enum Ambition { CONSERVATIVE, NORMAL, AGGRESSIVE }
enum Priority { LOW, NORMAL, HIGH }
## The project waits for a decision of the team principal.
enum Milestone { NONE, PICK_CFD, PICK_TUNNEL, DECIDE }

const PHASE_NAMES := ["Ideas", "CFD / simulation", "Wind tunnel / rig", "Detail design", "Tooling", "Production",
	"Quality check", "Ready"]
const AMBITION_NAMES := ["Conservative", "Normal", "Aggressive"]
const PRIORITY_NAMES := ["Low", "Normal", "High"]

@export var id: int = 0
@export var team_id: StringName
@export var part_id: StringName
## Preferred direction of the ideas (a CarParts.GOALS key); the chosen
## variant's main direction once frozen.
@export var goal: String
@export var ambition: Ambition = Ambition.NORMAL
@export var priority: Priority = Priority.NORMAL
@export var units: int = 3
@export var overtime: bool = false
@export var phase: Phase = Phase.CONCEPT
@export var milestone: Milestone = Milestone.NONE
## Days of work left in the current phase (production: for the current unit).
@export var work_left: float = 0.0
## Work of the current phase when it started (for its progress bar).
@export var phase_total: float = 1.0
@export var unit_work: float = 1.0
@export var units_built: int = 0
@export var unit_cost: int = 0
## Ideas: {"key": "A", "name", "goal", "complexity": 1..3, "real": {value: Δ}}
@export var ideas: Array = []
## Variants (single ideas and combinations):
## {"key": "A+B", "members": ["A", "B"], "real": {value: Δ}, "cfd": {value: [est, ±]},
##  "tunnel": {value: [est, ±]}, "rounds": int, "cfd_pick": bool, "tunnel_pick": bool}
@export var variants: Array = []
## Key of the frozen variant.
@export var chosen: String = ""
## Real change of the part's values (hidden) and what the team believes.
@export var delta: Dictionary = {}
@export var forecast: Dictionary = {}
@export var forecast_s: float = 0.0
@export var real_s: float = 0.0
@export var cost_spent: int = 0
@export var started_day: int = 0
@export var started_year: int = 2026
@export var waiting_for_money: bool = false
## The material for the unit in production is paid.
@export var unit_paid: bool = false
## Developed for next season's car (no production this year).
@export var next_year: bool = false
## > 0: an order for spare units of this version (production only).
@export var spares_version: int = 0


## Department working on the project right now ("" = waiting / calendar time).
func department() -> StringName:
	if milestone != Milestone.NONE:
		return &""
	match phase:
		Phase.CONCEPT, Phase.DETAIL:
			return &"design"
		Phase.CFD:
			return &"aero" if CarParts.test_kind(part_id) == "aero" else &"rig"
		Phase.TUNNEL:
			return &"tunnel" if CarParts.test_kind(part_id) == "aero" else &"rig"
		Phase.PRODUCTION:
			return &"factory"
		Phase.QUALITY:
			return &"rig"
	return &""


## Progress of the current phase (0..1).
func phase_progress() -> float:
	if phase == Phase.READY or milestone != Milestone.NONE:
		return 1.0
	if phase == Phase.PRODUCTION:
		return clampf((units_built + 1.0 - work_left / maxf(unit_work, 0.01)) / maxf(units, 1), 0.0, 1.0)
	return clampf(1.0 - work_left / maxf(phase_total, 0.01), 0.0, 1.0)


## Rough progress over the whole project (for the workshop cards).
func progress() -> float:
	var last := Phase.TUNNEL if next_year else Phase.QUALITY
	return clampf((phase + phase_progress()) / float(last + 1), 0.0, 1.0)


func variant(key: String) -> Dictionary:
	for v in variants:
		if v.key == key:
			return v
	return {}


func idea(key: String) -> Dictionary:
	for i in ideas:
		if i.key == key:
			return i
	return {}


func label() -> String:
	return TranslationServer.translate(CarParts.name_of(part_id))


func is_spares() -> bool:
	return spares_version > 0
