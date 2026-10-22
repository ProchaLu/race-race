## Key staff member (design doc 5.1). General attributes are fixed fields;
## role attributes depend on the role and live in role_attributes.
## All values are stored 0..100 (shown 1..20).
class_name StaffData
extends PersonData

enum Role {
	TECHNICAL_DIRECTOR,
	CHIEF_DESIGNER,
	HEAD_OF_AERO,
	HEAD_OF_CHASSIS,
	ENGINE_CHIEF,
	FACTORY_MANAGER,
	SPORTING_DIRECTOR,
	RACE_ENGINEER,
	STRATEGY_CHIEF,
	PIT_CREW_CHIEF,
	ACADEMY_HEAD,
	CHIEF_SCOUT,
	COMMERCIAL_MANAGER,
	FITNESS_COACH,
	MENTAL_COACH,
}

@export var role: Role = Role.RACE_ENGINEER

@export_group("General")
@export_range(0, 100) var expertise: int = 50
@export_range(0, 100) var leadership: int = 50
@export_range(0, 100) var experience: int = 50
@export_range(0, 100) var work_ethic: int = 50
@export_range(0, 100) var adaptability: int = 50

@export_group("Personality")
@export_range(0, 100) var ambition: int = 50
@export_range(0, 100) var loyalty: int = 50
@export_range(0, 100) var pressure_handling: int = 50

@export_group("Role")
## {&"setup_work": 82, ...} – keys defined per role in StaffRoles.
@export var role_attributes: Dictionary = {}
@export var traits: Array[StringName] = []
## For race engineers: the driver they work with.
@export var assigned_driver_id: StringName

@export_group("Condition")
@export_range(0, 100) var job_satisfaction: int = 70
@export_range(0, 100) var workload: int = 60
@export var potential: int = 60
@export var ability_history: Array[int] = []
@export var attribute_history: Dictionary = {}


## Overall rating 0..100: role skills count most.
func overall() -> int:
	var role_avg := 0.0
	for value in role_attributes.values():
		role_avg += value
	role_avg = role_avg / role_attributes.size() if not role_attributes.is_empty() else float(expertise)
	return roundi(role_avg * 0.5 + expertise * 0.25 + leadership * 0.1 + experience * 0.1 + work_ethic * 0.05)


## Value of a general, personality or role attribute by property name.
func attribute(property: StringName) -> int:
	if role_attributes.has(property):
		return role_attributes[property]
	return get(property)


static func role_name(r: Role) -> String:
	return StaffRoles.name_of(r)


## Role in the current language; race engineers show their driver
## ("Race engineer · Hale") so the two engineers can be told apart.
func role_label() -> String:
	var text := TranslationServer.translate(StaffRoles.name_of(role))
	var driver: DriverData = GameState.drivers.get(assigned_driver_id)
	if driver:
		text += " · " + driver.last_name
	return text
