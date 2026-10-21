## A racing team in any series. Holds money, reputation and HQ levels.
## Drivers, staff and sponsors are linked by ID through GameState.
class_name TeamData
extends Resource

@export var id: StringName
@export var name: String
@export var short_name: String  # 3 letters for timing screens, e.g. "VRT"
@export var series_id: StringName
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.BLACK

@export_group("Economy")
@export var budget: int = 0
@export_range(0, 100) var reputation: int = 50

@export_group("Headquarters")
## Facility levels (1..5). Each one boosts a different area.
@export_range(1, 5) var design_center_level: int = 1
@export_range(1, 5) var wind_tunnel_level: int = 1
@export_range(1, 5) var factory_level: int = 1
@export_range(1, 5) var youth_academy_level: int = 1
@export_range(1, 5) var scouting_level: int = 1

@export_group("Links")
@export var driver_ids: Array[StringName] = []
@export var staff_ids: Array[StringName] = []
@export var sponsor_ids: Array[StringName] = []
@export var academy_driver_ids: Array[StringName] = []

## The current season's car.
@export var car: CarData
