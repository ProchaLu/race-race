## An engine development project – the engine lab (docs/engine_model.md 5):
## ideas for one component, the single-cylinder rig (rough), the full dyno
## (precise power), endurance runs that reveal durability, homologation and
## production of the new spec. Or the power unit programme of a new
## manufacturer (all five components from scratch).
class_name EngineProject
extends Resource

enum Phase { CONCEPT, RIG, DYNO, ENDURANCE, PRODUCTION, READY, PROGRAMME }
## The project waits for a decision of the team principal.
enum Milestone { NONE, PICK_RIG, PICK_DYNO, PICK_ENDURANCE, DECIDE }

const PHASE_NAMES := ["Ideas", "Single-cylinder rig", "Performance run", "Endurance run", "Homologation & production",
	"Ready", "Power unit programme"]

@export var id: int = 0
## Manufacturer whose spec is developed; team whose staff does the work and pays.
@export var manufacturer_id: StringName
@export var team_id: StringName = &""
@export var component: StringName
## Preferred direction (a PowerUnit.VALUES key as String).
@export var focus: String = "power"
@export var aggressive: bool = false
@export var phase: Phase = Phase.CONCEPT
@export var milestone: Milestone = Milestone.NONE
@export var work_left: float = 0.0
@export var phase_total: float = 1.0
## {"key", "name", "focus", "real": {value: Δ}, "weak_km": km where it breaks (0 = sound)}
@export var ideas: Array = []
## {"key", "members", "real", "weak_km", "rig": {value: [est, ±]}, "dyno": {...},
##  "runs": race distances on the endurance dyno, "fail_km": first failure seen (0 = none),
##  "rel": [est, ±] of the reliability change, "defused": int, "picked": bool}
@export var variants: Array = []
## Variant on the endurance dyno / frozen variant.
@export var chosen: String = ""
## Race distances ordered for the current endurance run.
@export var runs_ordered: int = 0
@export var cost_spent: int = 0
@export var started_day: int = 0
@export var started_year: int = 2026


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


func phase_progress() -> float:
	if milestone != Milestone.NONE or phase == Phase.READY:
		return 1.0
	return clampf(1.0 - work_left / maxf(phase_total, 0.01), 0.0, 1.0)


func is_programme() -> bool:
	return phase == Phase.PROGRAMME


func label() -> String:
	if is_programme():
		return TranslationServer.translate("Power unit programme")
	return TranslationServer.translate(PowerUnit.name_of(component))
