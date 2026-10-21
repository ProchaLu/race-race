## Non-driver personnel: engineers, designers, mechanics, scouts, coaches.
class_name StaffData
extends PersonData

enum Role {
	TEAM_PRINCIPAL,
	TECHNICAL_DIRECTOR,
	CHIEF_DESIGNER,
	RACE_ENGINEER,
	PIT_CREW_CHIEF,
	SCOUT,
	YOUTH_COACH,
	COMMERCIAL_MANAGER,
}

@export var role: Role = Role.RACE_ENGINEER

## Main competence for the role (0..100).
@export_range(0, 100) var ability: int = 50
## Secondary traits, interpreted per role (e.g. scout accuracy, pit stop speed).
@export_range(0, 100) var specialty: int = 50
@export_range(0, 100) var leadership: int = 50
## For race engineers: the driver they work with.
@export var assigned_driver_id: StringName


static func role_name(r: Role) -> String:
	return Role.keys()[r].capitalize()
