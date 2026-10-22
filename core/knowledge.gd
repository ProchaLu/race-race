## What the player's team knows about a person (design doc 4.3).
## Knowledge 0..100 per person: 100 = exact values, lower = wider ranges.
## Ranges always contain the true value for now; scouts in R7 can narrow
## them (or get them wrong).
class_name Knowledge
extends RefCounted

## Widest range in display points (1-20 scale) at zero knowledge.
const MAX_WIDTH := 8
const EXACT_FROM := 90


static func level(person: PersonData) -> int:
	if person.team_id == GameState.player_team_id and person.team_id != &"":
		return 100
	return GameState.knowledge.get(person.id, 20)


static func is_exact(person: PersonData) -> bool:
	return level(person) >= EXACT_FROM


## Known range on the 1-20 display scale for an internal 0..100 value.
## The offset is fixed per person and attribute, so ranges do not jump.
static func display_range(person: PersonData, property: StringName, internal: int) -> Vector2i:
	var value := DriverAttributes.to_display(internal)
	var k := level(person)
	if k >= EXACT_FROM:
		return Vector2i(value, value)
	var width := roundi((EXACT_FROM - k) / float(EXACT_FROM) * MAX_WIDTH)
	if width == 0:
		return Vector2i(value, value)
	var below := hash(str(person.id) + ":" + str(property)) % (width + 1)
	var lo := clampi(value - below, 1, 20)
	var hi := clampi(value + (width - below), 1, 20)
	return Vector2i(lo, hi)


## Known star range (0..5 in half steps) for an internal 0..100 rating.
static func star_range(person: PersonData, property: StringName, internal: int) -> Vector2:
	var r := display_range(person, property, internal)
	# Back to the 0..100 scale (centre of each display step) for the stars.
	var lo := DriverAttributes.to_stars(r.x * 5 - 2)
	var hi := DriverAttributes.to_stars(r.y * 5 - 2)
	if r.x == r.y:
		var exact := DriverAttributes.to_stars(internal)
		return Vector2(exact, exact)
	return Vector2(lo, hi)


## Weeks a scouting assignment needs until values are exact (scouting
## assignments arrive in R7; the estimate already uses your chief scout).
static func weeks_to_scout(person: PersonData) -> int:
	var k := level(person)
	if k >= EXACT_FROM:
		return 0
	var skill := 50.0
	var scout := chief_scout()
	if scout:
		skill = (scout.attribute(&"judging_ability") + scout.attribute(&"judging_potential")) / 2.0
	var per_week := 4.0 + skill / 12.0
	return ceili((EXACT_FROM - k) / per_week)


static func chief_scout() -> StaffData:
	for s in GameState.staff_of_team(GameState.player_team_id):
		if s.role == StaffData.Role.CHIEF_SCOUT:
			return s
	return null


static func label(person: PersonData) -> String:
	var k := level(person)
	if k >= EXACT_FROM:
		return "Well known"
	if k >= 50:
		return "Partly known"
	if k >= 25:
		return "Little known"
	return "Unknown"
