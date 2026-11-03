## The academy (R7, docs/youth_model.md): young drivers the team trains and
## places in the junior seats. Places come from the Academy building level,
## the academy head decides how fast the drivers grow, and every academy
## driver is ready for the FP1 programme of the race weekend.
class_name Academy
extends RefCounted

## Oldest age a driver can join the academy at.
const INTAKE_MAX_AGE := 22
const SIGNING_FEE := 250_000
## Per academy driver and month (the department of youth development).
const FEE_PER_MONTH := 40_000
## Per season, paid when a driver sits in a junior seat.
const PLACEMENT_FEE := {&"f3": 300_000, &"f2": 900_000}
## Share of the gap to the potential that the academy adds each winter.
## Scaled by the head's skill (0.6 .. 1.6) and the building level (1.1 .. 1.5).
const GROWTH := 0.15


static func places(team: TeamData) -> int:
	return Facilities.level(team, &"academy")


static func free_places(team: TeamData) -> int:
	return maxi(0, places(team) - team.academy_driver_ids.size())


static func drivers(team: TeamData) -> Array[DriverData]:
	var out: Array[DriverData] = []
	if not team:
		return out
	for id in team.academy_driver_ids:
		if GameState.drivers.has(id):
			out.append(GameState.drivers[id])
	return out


static func head(team: TeamData) -> StaffData:
	for s in GameState.staff_of_team(team.id):
		if s.role == StaffData.Role.ACADEMY_HEAD:
			return s
	return null


## Youth development of the academy head, 1..100; 30 without a head.
static func head_skill(team: TeamData) -> int:
	var h := head(team)
	return h.attribute(&"youth_development") if h else 30


## True while the driver sits in a junior seat of a team of the academy.
static func is_placed(d: DriverData) -> bool:
	return d.academy_team_id != &"" and Youth.team_of(d) != null


## Takes the driver out of the academy (his junior seat is not touched).
static func forget(d: DriverData) -> void:
	var team: TeamData = GameState.teams.get(d.academy_team_id)
	if team:
		team.academy_driver_ids.erase(d.id)
	d.academy_team_id = &""


## Signs a junior of the pool into the academy. Returns "" or the reason it failed.
static func sign(team: TeamData, d: DriverData) -> String:
	if not Youth.is_youth(d) or d.team_id != &"" or d.retired:
		return "This person is not free in the junior pool."
	if d.age(Calendar.year) > INTAKE_MAX_AGE:
		return "Too old for the academy (up to %d years)." % INTAKE_MAX_AGE
	if d.academy_team_id != &"":
		return ""
	if free_places(team) <= 0:
		return "All academy places are taken. A larger academy building makes room for more."
	d.academy_team_id = team.id
	team.academy_driver_ids.append(d.id)
	GameState.knowledge[d.id] = 100
	Finance.pay(team, &"academy", SIGNING_FEE)
	return ""


## Ends the academy membership. A driver in a junior seat leaves that seat too.
static func release(d: DriverData) -> void:
	if is_placed(d):
		Youth.unseat(d)
	forget(d)


## Places an academy driver in a free seat of a junior team. Returns "" or the reason.
static func place(team: TeamData, d: DriverData, t: YouthTeam) -> String:
	if d.academy_team_id != team.id:
		return "Not in the academy."
	if t.driver_ids.size() >= Youth.SEATS:
		return "No free seat at %s." % t.name
	if d.age(Calendar.year) > Youth.max_age(t.series_id):
		return "Too old for %s." % Youth.SERIES_NAMES[t.series_id]
	if d.team_id != &"":
		Youth.unseat(d)
	Youth.seat(d, t)
	Finance.pay(team, &"academy", PLACEMENT_FEE[t.series_id])
	return ""


## Takes a placed driver back to the academy (his seat becomes free).
static func bring_back(d: DriverData) -> void:
	if is_placed(d):
		Youth.unseat(d)


## Monthly fees of every academy driver.
static func monthly_fees(team: TeamData) -> void:
	var count := team.academy_driver_ids.size()
	if count > 0:
		Finance.pay(team, &"academy", count * FEE_PER_MONTH)


## New season: the academy drivers grow (head and building), placed drivers
## pay their seat again. Returns [[name, growth], ...] for the report.
static func new_season(team: TeamData, _r: RandomNumberGenerator) -> Array:
	var out := []
	if not team:
		return out
	var factor := (0.6 + head_skill(team) / 100.0) * (1.0 + 0.1 * places(team))
	for d in drivers(team):
		var gap := d.potential - d.overall()
		if gap > 0:
			var bonus := mini(roundi(gap * GROWTH * factor), gap)
			for entry in DriverAttributes.DRIVING:
				d.set(entry[0], clampi(d.get(entry[0]) + bonus, 1, 100))
			out.append([d.full_name(), bonus])
		if is_placed(d):
			var t := Youth.team_of(d)
			Finance.pay(team, &"academy", PLACEMENT_FEE[t.series_id])
	return out
