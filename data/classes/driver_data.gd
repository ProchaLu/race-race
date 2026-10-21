## A racing driver, from young talent to world champion.
## All attributes are stored 0..100 (shown as 1..20, see DriverAttributes).
class_name DriverData
extends PersonData

@export var number: int = 0

@export_group("Driving")
@export_range(0, 100) var cornering: int = 50
@export_range(0, 100) var braking: int = 50
@export_range(0, 100) var one_lap_pace: int = 50
@export_range(0, 100) var consistency: int = 50   # lower = more mistakes
@export_range(0, 100) var tyre_management: int = 50
@export_range(0, 100) var fuel_management: int = 50
@export_range(0, 100) var overtaking: int = 50
@export_range(0, 100) var defending: int = 50
@export_range(0, 100) var starts: int = 50
@export_range(0, 100) var wet_skill: int = 50
@export_range(0, 100) var racecraft: int = 50

@export_group("Mental")
@export_range(0, 100) var composure: int = 50
@export_range(0, 100) var focus: int = 50
@export_range(0, 100) var aggression: int = 50
@export_range(0, 100) var adaptability: int = 50
@export_range(0, 100) var technical_feedback: int = 50
@export_range(0, 100) var work_ethic: int = 50
@export_range(0, 100) var professionalism: int = 50
@export_range(0, 100) var ambition: int = 50
@export_range(0, 100) var loyalty: int = 50
@export_range(0, 100) var temperament: int = 50

@export_group("Physical")
@export_range(0, 100) var fitness: int = 50
@export_range(0, 100) var reactions: int = 50

@export_group("Development")
## Hidden maximum overall rating the driver can reach. Scouts estimate it.
@export_range(0, 100) var potential: int = 60
## How fast the driver grows towards the potential (0.5 slow .. 1.5 fast).
@export_range(0.5, 1.5) var development_rate: float = 1.0
## Hidden age curve (see design doc 3.3).
@export var peak_start_age: int = 26
@export var peak_end_age: int = 32
@export_range(0.2, 2.0) var decline_rate: float = 1.0
## Series the driver currently races in, e.g. &"f1", &"f2", &"f3".
@export var series_id: StringName
## Team academy the driver belongs to (empty = none).
@export var academy_team_id: StringName

@export_group("Condition")
## Short-term form, 0..100 (50 = as expected).
@export_range(0, 100) var form: int = 50
@export_range(0, 100) var confidence: int = 50
## Current physical condition in percent.
@export_range(0, 100) var match_fitness: int = 100
@export var injury_weeks: int = 0
## Attribute the driver focuses on in training (empty = balanced).
@export var training_focus: StringName
## Reasons behind the current morale: {"Results above expectations": 12, ...}
@export var morale_factors: Dictionary = {}
@export var traits: Array[StringName] = []
## Change of each attribute since the start of the season: {&"cornering": 1}
@export var attribute_changes: Dictionary = {}
@export var has_superlicence: bool = true

@export_group("Career")
@export var races: int = 0
@export var seasons: int = 0
@export var wins: int = 0
@export var podiums: int = 0
@export var poles: int = 0
@export var championships: int = 0
## Overall rating at the end of each past season (oldest first) plus the current one.
@export var ability_history: Array[int] = []
## Same for every attribute: {&"cornering": [61, 66, 70, 74, 80, 82], ...}
@export var attribute_history: Dictionary = {}


## Overall rating 0..100. Driving skills dominate; some mental and
## physical attributes add to it.
func overall() -> int:
	var driving := 0.0
	for entry in DriverAttributes.DRIVING:
		driving += get(entry[0])
	driving /= DriverAttributes.DRIVING.size()
	var mental := (composure + focus + adaptability + technical_feedback) / 4.0
	var physical := (fitness + reactions) / 2.0
	return roundi(driving * 0.75 + mental * 0.15 + physical * 0.1)


## Recomputes morale from its factors (50 = neutral).
func recalculate_morale() -> void:
	var total := 50
	for delta in morale_factors.values():
		total += delta
	morale = clampi(total, 0, 100)
