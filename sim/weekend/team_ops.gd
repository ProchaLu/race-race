## The staff values a team brings to a race weekend, read once from its
## staff (missing roles count as 50). The sim lab can set them directly.
class_name TeamOps
extends RefCounted

var team_id: StringName

# Strategy chief
var tyre_model: int = 50
var weather_reading: int = 50
var race_reading: int = 50
var calm_decisions: int = 50
# Pit crew chief
var stop_speed: int = 50
var precision: int = 50
# Sporting director
var regulations: int = 50
# Reliability: engine chief, head of chassis, factory manager
var reliability_staff: int = 50
# Driver care
var pressure_training: int = 50
var motivation: int = 50
var physical_training: int = 50
## Race engineer values per driver id:
## {"setup_work", "communication", "tyre_knowledge", "data_analysis", "chemistry"}
var engineers := {}


static func from_team(id: StringName) -> TeamOps:
	var ops := TeamOps.new()
	ops.team_id = id
	var reliability: Array[int] = []
	for s in GameState.staff_of_team(id):
		match s.role:
			StaffData.Role.STRATEGY_CHIEF:
				ops.tyre_model = s.attribute(&"tyre_model")
				ops.weather_reading = s.attribute(&"weather_reading")
				ops.race_reading = s.attribute(&"race_reading")
				ops.calm_decisions = s.attribute(&"calm_decisions")
			StaffData.Role.PIT_CREW_CHIEF:
				ops.stop_speed = s.attribute(&"stop_speed")
				ops.precision = s.attribute(&"precision")
			StaffData.Role.SPORTING_DIRECTOR:
				ops.regulations = s.attribute(&"regulations")
			StaffData.Role.ENGINE_CHIEF, StaffData.Role.HEAD_OF_CHASSIS:
				reliability.append(s.attribute(&"reliability_focus"))
			StaffData.Role.FACTORY_MANAGER:
				reliability.append(s.attribute(&"quality_control"))
			StaffData.Role.MENTAL_COACH:
				ops.pressure_training = s.attribute(&"pressure_training")
				ops.motivation = s.attribute(&"motivation")
			StaffData.Role.FITNESS_COACH:
				ops.physical_training = s.attribute(&"physical_training")
			StaffData.Role.RACE_ENGINEER:
				if s.assigned_driver_id:
					ops.engineers[s.assigned_driver_id] = {
						"setup_work": s.attribute(&"setup_work"),
						"communication": s.attribute(&"communication"),
						"tyre_knowledge": s.attribute(&"tyre_knowledge"),
						"data_analysis": s.attribute(&"data_analysis"),
						"chemistry": GameState.relationship(s.id, s.assigned_driver_id).value,
					}
	if not reliability.is_empty():
		var total := 0
		for v in reliability:
			total += v
		ops.reliability_staff = total / reliability.size()
	if GameState.teams.has(id):
		_add_facilities(ops, GameState.teams[id])
	return ops


## HQ buildings add to the staff values (docs/r4_review.md).
static func _add_facilities(ops: TeamOps, team: TeamData) -> void:
	var pit := Facilities.ops_bonus(team, &"pit")
	ops.stop_speed = mini(ops.stop_speed + pit, 100)
	ops.precision = mini(ops.precision + pit, 100)
	var mission := Facilities.ops_bonus(team, &"mission")
	ops.race_reading = mini(ops.race_reading + mission, 100)
	ops.weather_reading = mini(ops.weather_reading + mission, 100)
	ops.tyre_model = mini(ops.tyre_model + mission, 100)
	var care := Facilities.ops_bonus(team, &"performance")
	ops.physical_training = mini(ops.physical_training + care, 100)
	ops.pressure_training = mini(ops.pressure_training + care, 100)
	ops.reliability_staff = mini(ops.reliability_staff + Facilities.ops_bonus(team, &"lab"), 100)
	var sim := Facilities.ops_bonus(team, &"simulator")
	for driver_id in ops.engineers:
		ops.engineers[driver_id]["setup_work"] = mini(ops.engineers[driver_id]["setup_work"] + sim, 100)


## Every value set to the same level (sim lab).
static func uniform(id: StringName, level: int) -> TeamOps:
	var ops := TeamOps.new()
	ops.team_id = id
	for p in ["tyre_model", "weather_reading", "race_reading", "calm_decisions", "stop_speed",
			"precision", "regulations", "reliability_staff", "pressure_training", "motivation",
			"physical_training"]:
		ops.set(p, level)
	ops.set_meta("engineer_level", level)
	return ops


func engineer(driver_id: StringName) -> Dictionary:
	if engineers.has(driver_id):
		return engineers[driver_id]
	var level: int = get_meta("engineer_level", 50)
	return {"setup_work": level, "communication": level, "tyre_knowledge": level,
		"data_analysis": level, "chemistry": 0}
