## One power unit of a driver's season pool (docs/engine_model.md 4): built
## at the spec of the day, wears with every kilometre.
class_name EngineUnit
extends Resource

@export var number: int = 1
@export var driver_id: StringName
@export var season: int = 2026
## Engine values when it was built (PowerUnit.VALUES).
@export var values: Dictionary = {}
## Component -> spec version it was built with.
@export var spec_versions: Dictionary = {}
@export var km: float = 0.0
## 0..1; 1 = destroyed.
@export var damage: float = 0.0
@export var fitted: bool = false


func life_km() -> float:
	return PowerUnit.life_km(values.get(&"reliability", 50.0)) * (1.0 - damage * 0.6)


func used() -> float:
	return km / maxf(life_km(), 1.0)


func is_dead() -> bool:
	return damage >= 1.0 or used() >= 1.3


## "ICE 2 · TC 1 · ERS 2 · BAT 1 · CE 3"
func spec_label() -> String:
	var parts := PackedStringArray()
	for c in PowerUnit.COMPONENTS:
		parts.append("%s %d" % [PowerUnit.COMPONENT_SHORT[c], spec_versions.get(c, 1)])
	return " · ".join(parts)
