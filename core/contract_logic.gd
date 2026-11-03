## Money and paperwork around contracts: market values, salary demands,
## severance, signing and releasing people.
class_name ContractLogic
extends RefCounted

const RACE_SEATS := 2
const RESERVE_SEATS := 1


# --- Positions -----------------------------------------------------------------
# Every position has a fixed number of places: two race seats, one reserve
# driver, two race engineers, one of every other staff role. If it is full,
# someone has to make room before a new person can sign.

## Whether a driver contract with this role takes a reserve place.
static func is_reserve_role(driver_role: int) -> bool:
	return driver_role == ContractData.DriverRole.RESERVE


## People who hold the position `person` would take (without `person`).
static func position_holders(team: TeamData, person: PersonData, driver_role: int = -1) -> Array[PersonData]:
	var out: Array[PersonData] = []
	if person is DriverData:
		var ids: Array[StringName] = team.reserve_driver_ids if is_reserve_role(driver_role) else team.driver_ids
		for id in ids:
			if id != person.id and GameState.drivers.has(id):
				out.append(GameState.drivers[id])
	else:
		for s in GameState.staff_of_team(team.id):
			if s != person and s.role == (person as StaffData).role:
				out.append(s)
	return out


static func position_capacity(person: PersonData, driver_role: int = -1) -> int:
	if person is DriverData:
		return RESERVE_SEATS if is_reserve_role(driver_role) else RACE_SEATS
	return StaffRoles.TEAM_POSITIONS.count((person as StaffData).role)


static func position_full(team: TeamData, person: PersonData, driver_role: int = -1) -> bool:
	return position_holders(team, person, driver_role).size() >= position_capacity(person, driver_role)


## Ways to free the position, for the player to choose from:
## [{"id": holder id, "action": "release" | "reserve", "cost": severance}]
## "reserve" moves a race driver to the free reserve place instead.
static func room_options(team: TeamData, person: PersonData, driver_role: int = -1) -> Array:
	if not position_full(team, person, driver_role):
		return []
	var reserve_free := team.reserve_driver_ids.filter(func(id): return id != person.id).size() < RESERVE_SEATS
	var out := []
	for holder in position_holders(team, person, driver_role):
		if person is DriverData and not is_reserve_role(driver_role) and reserve_free:
			out.append({"id": holder.id, "action": "reserve", "cost": 0})
		out.append({"id": holder.id, "action": "release", "cost": severance(holder)})
	return out


## Frees the position before a signing. choice: one of room_options();
## empty = the weakest holder is released (AI teams, fallback).
## Returns {"person": who made room, "action": ...} or {} if nothing was needed.
static func make_room(team: TeamData, person: PersonData, driver_role: int, choice: Dictionary = {}) -> Dictionary:
	if not position_full(team, person, driver_role):
		return {}
	var holders := position_holders(team, person, driver_role)
	var holder: PersonData = null
	var action := "release"
	if not choice.is_empty():
		var chosen := GameState.find_person(choice.id)
		if chosen and chosen in holders:
			holder = chosen
			action = choice.action
	if not holder:
		holders.sort_custom(func(a: PersonData, b: PersonData): return a.overall() < b.overall())
		holder = holders[0]
	if action == "reserve" and team.reserve_driver_ids.size() < RESERVE_SEATS:
		team.driver_ids.erase(holder.id)
		team.reserve_driver_ids.append(holder.id)
		var c := GameState.contract_of(holder.id)
		if c:
			c.role = ContractData.DriverRole.RESERVE
		TeamMood.change_morale(holder, "Moved to reserve driver", -15)
	else:
		action = "release"
		release(holder)
	return {"person": holder, "action": action}


# --- Values ------------------------------------------------------------------

## What a person is worth per year on the market.
static func market_value(person: PersonData) -> int:
	if person is DriverData:
		var d := person as DriverData
		var o := d.overall()
		var value := 400_000 + int(pow(maxf(0.0, o - 55.0), 2.0) * 18_000.0)
		if d.age(Calendar.year) < 21:
			value = int(value * 0.6)
		return _round(value)
	var s := person as StaffData
	var factor := 0.5 + pow(s.overall() / 100.0, 2.0) * 1.2
	return _round(int(StaffRoles.base_salary(s.role) * factor))


## Salary the person (or agent) starts asking for.
static func salary_demand(person: PersonData) -> int:
	var ambition: int = person.get("ambition") if person.get("ambition") != null else 50
	var style_factor := 1.0
	var agent := agent_of(person)
	if agent:
		style_factor = [1.12, 1.0, 0.95, 1.06][agent.style]
	var current := GameState.contract_of(person.id)
	var base := market_value(person)
	if current:
		base = maxi(base, int(current.salary * 1.1))
	return _round(int(base * (1.0 + (ambition - 50) / 200.0) * style_factor))


static func agent_of(person: PersonData) -> AgentData:
	return GameState.agents.get(person.agent_id)


static func months_left(contract: ContractData) -> int:
	var month: int = Calendar.date_of().month
	return maxi(0, (contract.end_year - Calendar.year) * 12 + (12 - month))


## Cost of ending a contract early.
static func severance(person: PersonData) -> int:
	var c := GameState.contract_of(person.id)
	if not c:
		return 0
	var monthly := c.salary / 12.0
	if person is DriverData:
		return _round(int(monthly * months_left(c) * 0.5))
	return _round(int(monthly * maxi(c.notice_months, int(months_left(c) * 0.3))))


static func payroll_per_month(team_id: StringName) -> int:
	var total := 0
	for c in GameState.contracts:
		if c.team_id == team_id:
			total += c.salary
	return floori(total / 12.0)


# --- Changes -----------------------------------------------------------------

## Signs a person to a team with the agreed terms (new or extended contract).
## If the position is full, terms.make_room (one of room_options()) says who
## makes room; without it the weakest holder is released.
## Returns make_room()'s result ({} if nobody had to leave).
static func sign(person: PersonData, team: TeamData, terms: Dictionary) -> Dictionary:
	var c := GameState.contract_of(person.id)
	var old_team_id := person.team_id
	if c and c.team_id != team.id:
		GameState.contracts.erase(c)
		c = null
	if not c:
		c = ContractData.new()
		c.person_id = person.id
		c.start_year = Calendar.year
		GameState.contracts.append(c)
	c.team_id = team.id
	c.salary = terms.salary
	c.end_year = Calendar.year + terms.years - 1 + (1 if Calendar.date_of().month >= 7 else 0)
	c.win_bonus = terms.get("win_bonus", 0)
	c.podium_bonus = terms.get("win_bonus", 0) / 3
	c.release_clause = int(terms.salary * 3) if terms.get("release_clause", false) else 0
	if person is DriverData:
		c.role = terms.get("role", ContractData.DriverRole.EQUAL)
	Finance.pay(team, &"signing", terms.get("signing_fee", 0))
	# Release clause paid to the old team.
	var transfer_fee: int = terms.get("transfer_fee", 0)
	if transfer_fee > 0:
		Finance.pay(team, &"transfer_out", transfer_fee)
		var old_team: TeamData = GameState.teams.get(person.team_id)
		if old_team and old_team != team:
			Finance.receive(old_team, &"transfer_in", transfer_fee)

	var role: int = c.role if person is DriverData else -1
	var moves_position := old_team_id != team.id
	if person is DriverData and not moves_position:
		# Own driver changing between race seat and reserve place.
		moves_position = is_reserve_role(role) != team.reserve_driver_ids.has(person.id)
	var made_room := {}
	if moves_position:
		_remove_from_team(person)
		made_room = make_room(team, person, role, terms.get("make_room", {}))
		person.team_id = team.id
		if person is DriverData:
			var d := person as DriverData
			d.series_id = team.series_id
			if is_reserve_role(role):
				team.reserve_driver_ids.append(person.id)
			else:
				team.driver_ids.append(person.id)
		else:
			team.staff_ids.append(person.id)
		GameState.knowledge[person.id] = 100
	EventBus.contract_signed.emit(person.id, team.id)
	return made_room


## Ends a contract early: pays severance, person becomes a free agent.
static func release(person: PersonData) -> int:
	var team: TeamData = GameState.teams.get(person.team_id)
	var cost := severance(person)
	if team:
		Finance.pay(team, &"signing", cost)
		TeamMood.add_event(team.id, "%s released", [person.full_name()], -4)
	var c := GameState.contract_of(person.id)
	if c:
		GameState.contracts.erase(c)
	_remove_from_team(person)
	person.team_id = &""
	if person is StaffData:
		(person as StaffData).assigned_driver_id = &""
	EventBus.contract_released.emit(person.id)
	return cost


static func _remove_from_team(person: PersonData) -> void:
	var team: TeamData = GameState.teams.get(person.team_id)
	if not team:
		return
	team.driver_ids.erase(person.id)
	team.reserve_driver_ids.erase(person.id)
	team.staff_ids.erase(person.id)


static func _round(value: int) -> int:
	return int(round(value / 10_000.0)) * 10_000
