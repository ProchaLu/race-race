## Founding a team (R8a, docs/career_model.md 7): the player's own team enters
## the field as the 12th team (24 cars). It starts small: low reputation, a
## basic campus, a customer engine, modest staff and two drivers the sporting
## director signs from the free market for two seasons. A backer is the owner;
## the founder cannot be dismissed. Also: what the start menu shows.
class_name TeamFounding
extends RefCounted

const TEAM_ID := &"founded"
const START_BUDGET := 140_000_000
const START_REPUTATION := 30
const START_FANS := 15
## Car rating (like the car level of the other teams; the weakest has 50).
const CAR_LEVEL := 48
const CAMPUS_TIER := 1
const STAFF_LEVEL := 45
## Colours the founder can choose from.
const COLORS := [Color("ff7a00"), Color("00c2a8"), Color("b4ff39"), Color("ff3864"),
	Color("7d5fff"), Color("2bb5ff"), Color("f5f5f5"), Color("2e3440"), Color("ffb400"), Color("8b5a2b")]
const DEFAULT_NAME := "Phoenix Racing"


## Manufacturers that still have room for a customer: [[id, name, price, values], ...].
static func engine_choices() -> Array:
	var out := []
	for entry in Engines.START:
		var used: int = entry[8].size() + (1 if entry[4] != &"" else 0)
		if used < ManufacturerData.new().max_teams:
			out.append([entry[0], entry[1], entry[5], entry[7]])
	return out


## "" when the options can found a team, otherwise what is wrong.
static func check_options(options: Dictionary) -> String:
	var team_name := String(options.get("name", "")).strip_edges()
	if team_name.length() < 3:
		return "The team name needs at least 3 letters."
	for t in TestWorld.TEAMS:
		if t[1].to_lower() == team_name.to_lower():
			return "This name is taken by another team."
	var short := String(options.get("short_name", "")).strip_edges()
	if short.length() != 3:
		return "The short name needs exactly 3 letters."
	for t in TestWorld.TEAMS:
		if t[2] == short.to_upper():
			return "This short name is taken by another team."
	var engines := engine_choices().map(func(e): return e[0])
	if not engines.has(options.get("manufacturer", &"")):
		return "Choose an engine supplier."
	return ""


## Three letters from the name: "Phoenix Racing" → "PHO".
static func short_from(team_name: String) -> String:
	var letters := ""
	for c in team_name.to_upper():
		if c >= "A" and c <= "Z":
			letters += c
	return letters.left(3)


static func make_team(options: Dictionary, series: SeriesData, r: RandomNumberGenerator) -> TeamData:
	var team := TeamData.new()
	team.id = TEAM_ID
	team.name = String(options.get("name", DEFAULT_NAME)).strip_edges()
	team.short_name = String(options.get("short_name", short_from(team.name))).strip_edges().to_upper()
	team.series_id = series.id
	team.primary_color = options.get("color", COLORS[0])
	team.budget = START_BUDGET
	team.reputation = START_REPUTATION
	team.fans = START_FANS
	var car := CarData.new()
	car.team_id = team.id
	car.downforce = CAR_LEVEL + r.randi_range(-3, 3)
	car.drag_efficiency = CAR_LEVEL + r.randi_range(-3, 3)
	car.engine_power = CAR_LEVEL + r.randi_range(-3, 3)
	car.mechanical_grip = CAR_LEVEL + r.randi_range(-3, 3)
	car.tyre_preservation = CAR_LEVEL + r.randi_range(-5, 5)
	car.reliability = CAR_LEVEL + 5 + r.randi_range(-5, 5)
	team.car = car
	Facilities.seed_for_tier(team, CAMPUS_TIER, r)
	CarBuild.init_from_ratings(car, clampf((72 - CAR_LEVEL) * 0.5, 0.0, 14.0), Calendar.year, r)
	series.team_ids.append(team.id)
	GameState.add_team(team)
	return team


## Customer engine for one season with the chosen manufacturer.
static func engine_deal(team: TeamData, manufacturer_id: StringName, r: RandomNumberGenerator) -> void:
	var m: ManufacturerData = GameState.manufacturers.get(manufacturer_id)
	if not m:
		m = GameState.manufacturers[engine_choices()[0][0]]
	team.engine_manufacturer = m.id
	team.engine_deal = {"type": "customer", "price": m.price, "until": Calendar.year + 1, "since": Calendar.year}
	m.relationship[team.id] = r.randi_range(45, 55)
	Engines.refresh_team(team)


## The sporting director signs the two best free drivers for two seasons.
static func sign_start_drivers(team: TeamData) -> void:
	var free := GameState.free_drivers()
	free.sort_custom(func(a, b): return a.overall() > b.overall())
	for d in free.slice(0, ContractLogic.RACE_SEATS):
		d.team_id = team.id
		d.series_id = team.series_id
		team.driver_ids.append(d.id)
		var c := ContractData.new()
		c.person_id = d.id
		c.team_id = team.id
		c.salary = ContractLogic.market_value(d)
		c.start_year = Calendar.year
		c.end_year = Calendar.year + 1
		c.role = ContractData.DriverRole.EQUAL
		GameState.contracts.append(c)


static func owner_name(r: RandomNumberGenerator) -> String:
	return "%s %s" % [Career.OWNER_FIRST[r.randi() % Career.OWNER_FIRST.size()],
		Career.OWNER_LAST[r.randi() % Career.OWNER_LAST.size()]]


## The first messages of a new game.
static func welcome_messages(founded: bool) -> void:
	var team := GameState.player_team()
	var s: SeriesData = GameState.series[team.series_id]
	var msg := InboxMessage.new()
	msg.sender = "Owner"
	msg.icon = "briefcase"
	msg.priority = InboxMessage.Priority.IMPORTANT
	if founded:
		msg.subject = "%s is born"
		msg.subject_args = [team.name]
		msg.add_paragraph("I am %s. My money and your plan: together we founded %s as the 12th team of the field.", [team.owner.name, team.name])
		msg.add_paragraph("We start small: a basic campus, a customer engine and a modest staff. As co-founder you cannot be dismissed, but my trust decides whether I put in more money.")
		msg.add_paragraph("Our sporting director signed two drivers for two seasons: %s.", [", ".join(GameState.drivers_of_team(team.id).map(func(d): return d.full_name()))])
	else:
		msg.subject = "Welcome to %s"
		msg.subject_args = [team.name]
		msg.add_paragraph("I am %s. Welcome on board – the team is yours from today.", [team.owner.name])
	msg.add_paragraph("Season goal: finish P%d or better in the constructors' championship.", [team.owner.goal])
	msg.add_paragraph("Long-term goal: the constructors' title by %d.", [team.owner.long_deadline])
	msg.link_screen = &"owner"
	msg.link_args = {}
	msg.link_label = "Open owner"
	GameState.add_message(msg)

	var start := InboxMessage.new()
	start.sender = "Sporting director"
	start.icon = "calendar"
	start.subject = "Season %d begins"
	start.subject_args = [Calendar.year]
	start.add_paragraph("The first race is on %s. All statistics and standings start from zero.",
		[Calendar.format_date(s.race_days[0])])
	start.add_paragraph("Before the first race: check the car development, the sponsors and the transfer market.")
	start.link_screen = &"calendar"
	start.link_args = {}
	start.link_label = "Open calendar"
	GameState.add_message(start)
