## An engine manufacturer (docs/engine_model.md 1): its power unit specs,
## the teams it supplies and how it gets on with them.
class_name ManufacturerData
extends Resource

@export var id: StringName
@export var name: String
@export var short_name: String
@export var color: Color = Color.WHITE
## Team whose engine department develops the engine ("" = independent).
@export var works_team_id: StringName = &""
## Price of a customer engine per year.
@export var price: int = 18_000_000
@export var max_teams: int = 4
## A licence copy: only its own team, developed by that team.
@export var licensed_from: StringName = &""
## Development staff of an independent manufacturer (0..100).
@export var staff_level: int = 60
## Component -> every spec, oldest first:
## {"version": int, "values": {value: x}, "works": round key, "customers": round key}
## Round key = year * 100 + rounds completed (Engines.now_key()).
@export var specs: Dictionary = {}
## Team ID -> relationship 0..100 (earlier deliveries, renewals).
@export var relationship: Dictionary = {}
## Specs released this season per component (limit 3 before R9).
@export var specs_this_season: Dictionary = {}


func label() -> String:
	return name


func is_independent() -> bool:
	return works_team_id == &""
