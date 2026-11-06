## The 16 key staff positions of a team (design doc 5.1): names, departments,
## role attributes and how many of each role a team has.
class_name StaffRoles
extends RefCounted

const R := StaffData.Role

## Positions of a full team, in display order (race engineer twice).
const TEAM_POSITIONS := [
	R.TECHNICAL_DIRECTOR, R.CHIEF_DESIGNER, R.HEAD_OF_AERO, R.HEAD_OF_CHASSIS,
	R.ENGINE_CHIEF, R.FACTORY_MANAGER,
	R.SPORTING_DIRECTOR, R.RACE_ENGINEER, R.RACE_ENGINEER, R.STRATEGY_CHIEF, R.PIT_CREW_CHIEF,
	R.ACADEMY_HEAD, R.CHIEF_SCOUT, R.COMMERCIAL_MANAGER, R.FITNESS_COACH, R.MENTAL_COACH,
]

## [display name, department, base salary in $, role attributes [[property, name, description]]]
const ROLES := {
	R.TECHNICAL_DIRECTOR: ["Technical director", "Technical", 4_000_000, [
		[&"innovation", "Innovation", "New ideas that find big gains."],
		[&"organisation", "Organisation", "Runs the technical departments efficiently."],
		[&"aero_knowledge", "Aero knowledge", "Understanding of aerodynamics."],
		[&"mechanical_knowledge", "Mechanical knowledge", "Understanding of chassis and suspension."]]],
	R.CHIEF_DESIGNER: ["Chief designer", "Technical", 2_500_000, [
		[&"creativity", "Creativity", "Bold design concepts."],
		[&"detail_work", "Detail work", "Small gains everywhere, fewer design flaws."],
		[&"design_speed", "Design speed", "How fast new parts are designed."]]],
	R.HEAD_OF_AERO: ["Head of aerodynamics", "Technical", 2_000_000, [
		[&"aero_knowledge", "Aero knowledge", "Downforce and drag efficiency of new parts."],
		[&"correlation", "Correlation", "How well wind tunnel and track results match."],
		[&"innovation", "Innovation", "New aero concepts."]]],
	R.HEAD_OF_CHASSIS: ["Head of chassis", "Technical", 1_600_000, [
		[&"mechanical_knowledge", "Mechanical knowledge", "Suspension and mechanical grip."],
		[&"weight_saving", "Weight saving", "Lighter parts."],
		[&"reliability_focus", "Reliability focus", "Parts that do not break."]]],
	R.ENGINE_CHIEF: ["Engine chief", "Engine", 2_200_000, [
		[&"power_development", "Power development", "More horsepower."],
		[&"efficiency", "Efficiency", "Less fuel and energy for the same power."],
		[&"reliability_focus", "Reliability focus", "Engines that last."]]],
	R.FACTORY_MANAGER: ["Factory manager", "Production", 900_000, [
		[&"production_speed", "Production speed", "How fast parts are built."],
		[&"quality_control", "Quality control", "Fewer faulty parts."],
		[&"cost_control", "Cost control", "Cheaper production."]]],
	R.SPORTING_DIRECTOR: ["Sporting director", "Race operations", 1_500_000, [
		[&"negotiation", "Negotiation", "Better contracts when delegated."],
		[&"regulations", "Regulations", "Knows the rules, avoids penalties."],
		[&"people_management", "People management", "Keeps drivers and staff happy."]]],
	R.RACE_ENGINEER: ["Race engineer", "Race operations", 900_000, [
		[&"setup_work", "Setup work", "Quality of the car setup."],
		[&"communication", "Communication", "Clear radio calls, fewer misunderstandings."],
		[&"tyre_knowledge", "Tyre knowledge", "Understanding of tyre behaviour."],
		[&"data_analysis", "Data analysis", "Finds time in the telemetry."]]],
	R.STRATEGY_CHIEF: ["Strategy chief", "Race operations", 1_000_000, [
		[&"tyre_model", "Tyre model", "Accuracy of tyre wear predictions."],
		[&"weather_reading", "Weather reading", "Right calls when rain comes."],
		[&"race_reading", "Race reading", "Reacts to safety cars and rivals."],
		[&"calm_decisions", "Calm decisions", "Good calls under pressure."]]],
	R.PIT_CREW_CHIEF: ["Pit crew chief", "Race operations", 600_000, [
		[&"stop_speed", "Stop speed", "Average pit stop time."],
		[&"precision", "Precision", "Fewer slow or unsafe stops."],
		[&"crew_training", "Crew training", "How fast the crew improves."]]],
	R.ACADEMY_HEAD: ["Academy head", "Youth", 700_000, [
		[&"youth_development", "Youth development", "How fast academy drivers improve."],
		[&"talent_eye", "Talent eye", "Picks the right young drivers."],
		[&"mentoring", "Mentoring", "Keeps young drivers motivated."]]],
	R.CHIEF_SCOUT: ["Chief scout", "Youth", 500_000, [
		[&"judging_ability", "Judging ability", "Accuracy when rating current ability."],
		[&"judging_potential", "Judging potential", "Accuracy when rating potential."],
		[&"network", "Network", "Finds more talents in more countries."]]],
	R.SCOUT: ["Scout", "Youth", 180_000, [
		[&"judging_ability", "Judging ability", "Accuracy when rating current ability."],
		[&"judging_potential", "Judging potential", "Accuracy when rating potential."],
		[&"network", "Network", "Finds more talents in more countries."]]],
	R.COMMERCIAL_MANAGER: ["Commercial manager", "Commercial", 1_200_000, [
		[&"negotiation", "Negotiation", "Better sponsor deals."],
		[&"networking", "Networking", "More sponsor offers."],
		[&"brand_building", "Brand building", "Grows the team's reputation and fans."]]],
	R.FITNESS_COACH: ["Fitness coach", "Driver care", 300_000, [
		[&"physical_training", "Physical training", "Driver fitness."],
		[&"injury_prevention", "Injury prevention", "Fewer and shorter injuries."],
		[&"recovery", "Recovery", "Fitness between back-to-back races."]]],
	R.MENTAL_COACH: ["Mental coach", "Driver care", 300_000, [
		[&"motivation", "Motivation", "Keeps morale and confidence up."],
		[&"pressure_training", "Pressure training", "Drivers handle pressure better."],
		[&"conflict_resolution", "Conflict resolution", "Calms tension between people."]]],
}

## General and personality attributes shared by all staff.
const GENERAL := [
	[&"expertise", "Expertise", "Overall skill in the job."],
	[&"leadership", "Leadership", "Gets the best out of the department."],
	[&"experience", "Experience", "Years at the top level."],
	[&"work_ethic", "Work ethic", "Effort and reliability every day."],
	[&"adaptability", "Adaptability", "Copes with new rules, teams and people."],
]
const PERSONALITY := [
	[&"ambition", "Ambition", "Wants to win and to move up; salary demands."],
	[&"loyalty", "Loyalty", "Willingness to stay; resistance to offers."],
	[&"pressure_handling", "Pressure handling", "Performance in stressful moments."],
]


static func name_of(role: StaffData.Role) -> String:
	return ROLES[role][0]


static func department_of(role: StaffData.Role) -> String:
	return ROLES[role][1]


static func base_salary(role: StaffData.Role) -> int:
	return ROLES[role][2]


static func attributes_of(role: StaffData.Role) -> Array:
	return ROLES[role][3]


static func description(property: StringName) -> String:
	for group in [GENERAL, PERSONALITY]:
		for entry in group:
			if entry[0] == property:
				return entry[2]
	for role in ROLES:
		for entry in ROLES[role][3]:
			if entry[0] == property:
				return entry[2]
	return ""
