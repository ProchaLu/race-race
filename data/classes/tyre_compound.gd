## A tyre type (soft, medium, hard, intermediate, wet).
class_name TyreCompound
extends Resource

@export var id: StringName
@export var display_name: String
@export var color: Color = Color.WHITE

## Speed multiplier on fresh tyres (1.0 = baseline).
@export var grip: float = 1.0
## Wear per kilometre in percent of tyre life.
@export var wear_per_km: float = 0.5
## True for intermediates/wets.
@export var is_wet_tyre: bool = false
