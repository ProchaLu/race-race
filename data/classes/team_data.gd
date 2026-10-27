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
## Facility ID (Facilities.CATALOG) -> level 0..5 (0 = undeveloped site).
## The only source of facility levels; read through Facilities.level().
@export var facilities: Dictionary = {}
## Facility ID -> {target, remaining, duration, cost}. The current level
## keeps working during construction.
@export var facility_projects: Dictionary = {}

@export_group("Car development (R3)")
## Headcount per department: design, aero, rig, factory (docs/car_model.md 4).
## Set from the budget each season until hiring comes with R4/R6.
@export var departments: Dictionary = {}
## Share of every department working on next season's car (0..1).
@export var next_year_share: float = 0.0
## Part ID -> {value: change} developed for next season's car.
@export var next_year_parts: Dictionary = {}
## Driver ID -> {part ID: version number} fitted to that driver's car.
@export var car_fit: Dictionary = {}

@export_group("Links")
## The two race drivers.
@export var driver_ids: Array[StringName] = []
@export var reserve_driver_ids: Array[StringName] = []
@export var staff_ids: Array[StringName] = []
@export var sponsor_ids: Array[StringName] = []
@export var academy_driver_ids: Array[StringName] = []

## The current season's car.
@export var car: CarData
