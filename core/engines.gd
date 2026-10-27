## Engines of every team (docs/engine_model.md): the manufacturers and their
## specs, engine units with mileage, what the engine does to the car,
## contracts and offers, the monthly engine fee and the season change.
## AI teams and AI manufacturers follow the same rules as the player.
class_name Engines
extends RefCounted

## [id, name, short, colour, works team, price per year, staff level,
##  engine values {power, efficiency, reliability, weight, drivability}, customers]
const START := [
	[&"corsa_motori", "Corsa Alta Motori", "CAM", Color("dc143c"), &"corsa", 22_000_000, 70,
		[72, 55, 58, 52, 57], [&"halcyon", &"tundra"]],
	[&"aurum_pt", "Aurum Powertrains", "AUP", Color("ffd23f"), &"aurum", 21_000_000, 68,
		[69, 64, 66, 55, 60], [&"kestrel"]],
	[&"meridian_hp", "Meridian High Performance", "MHP", Color("1fb5a8"), &"meridian", 18_000_000, 66,
		[66, 72, 74, 49, 63], [&"vortex", &"nordline", &"brightwater"]],
	[&"valkyr", "Valkyr Power Systems", "VPS", Color("8a8fb5"), &"", 14_000_000, 58,
		[60, 62, 63, 58, 68], [&"solace", &"ironbridge"]],
]
## Works teams get a new spec at once, customers later (races).
const CUSTOMER_DELAY_MAX := 3
## Specs per component and season before the rules of R9.
const SPECS_PER_SEASON := 3
const LICENCE_FACTOR := 1.8
## Engine values the AI weighs when it compares manufacturers.
const AI_VALUE_WEIGHTS := {&"power": 0.4, &"efficiency": 0.15, &"reliability": 0.2, &"weight": 0.1, &"drivability": 0.15}
## A manufacturer looks after its customers (per customer and year).
const CUSTOMER_SUPPORT := 4_000_000
const OFFER_VALID_DAYS := 21
## Typical distance of a race weekend on one unit (practice, qualifying, race).
const WEEKEND_KM := 720.0


# --- World ---------------------------------------------------------------------

static func setup_world(r: RandomNumberGenerator) -> void:
	var year := Calendar.year
	for entry in START:
		var m := ManufacturerData.new()
		m.id = entry[0]
		m.name = entry[1]
		m.short_name = entry[2]
		m.color = entry[3]
		m.works_team_id = entry[4]
		m.price = entry[5]
		m.staff_level = entry[6]
		var targets := {}
		for i in PowerUnit.VALUES.size():
			targets[PowerUnit.VALUES[i]] = float(entry[7][i])
		for c in PowerUnit.COMPONENTS:
			var values := {}
			for v in PowerUnit.values_of(c):
				values[v] = clampf(targets[v] + r.randfn(0.0, 4.0), 20.0, 95.0)
			m.specs[c] = [{"version": 1, "values": values, "works": year * 100, "customers": year * 100}]
		# Shift so the engine values hit the targets exactly.
		for v in PowerUnit.VALUES:
			var shift: float = targets[v] - _values_of_specs(m, func(list): return list.back())[v]
			for c in PowerUnit.WEIGHTS[v]:
				m.specs[c][0].values[v] = clampf(m.specs[c][0].values[v] + shift, 5.0, 99.0)
		GameState.manufacturers[m.id] = m
		var teams: Array = entry[8].duplicate()
		if m.works_team_id != &"":
			teams.push_front(m.works_team_id)
		for team_id in teams:
			var team: TeamData = GameState.teams.get(team_id)
			if not team:
				continue
			team.engine_manufacturer = m.id
			var works: bool = team_id == m.works_team_id
			team.engine_deal = {"type": "works" if works else "customer", "price": 0 if works else m.price,
				"until": year + (5 if works else r.randi_range(1, 2)), "since": year - 3}
			m.relationship[team_id] = 80 if works else r.randi_range(50, 70)
			if works:
				team.facilities[&"engine"] = maxi(Facilities.level(team, &"engine"), 3 + r.randi_range(0, 1))
	for team: TeamData in GameState.teams.values():
		refresh_team(team)


## Units already used when the world starts mid-season: each ran until about
## 85 % of its life, the last one is fitted.
static func setup_units(r: RandomNumberGenerator) -> void:
	for team: TeamData in GameState.teams.values():
		if team.engine_manufacturer == &"":
			continue
		for d in GameState.drivers_of_team(team.id):
			var km := GameState.resolved_rounds * WEEKEND_KM * r.randf_range(0.9, 1.1)
			var u := new_unit(team, d.id, false)
			while km > u.life_km() * 0.85:
				var share := r.randf_range(0.8, 0.92)
				u.km = u.life_km() * share
				km -= u.km
				u = new_unit(team, d.id, false)
			u.km = km
		refresh_team(team)


static func _values_of_specs(m: ManufacturerData, pick: Callable) -> Dictionary:
	var comps := {}
	for c in PowerUnit.COMPONENTS:
		comps[c] = pick.call(m.specs[c]).values
	return PowerUnit.compute(comps)


## Year * 100 + rounds completed: when a spec becomes available.
static func now_key() -> int:
	return Calendar.year * 100 + GameState.resolved_rounds


static func round_label(key: int) -> String:
	return "R%d" % (key % 100 + 1)


# --- Manufacturers and specs -----------------------------------------------------

static func manufacturer_of(team: TeamData) -> ManufacturerData:
	return GameState.manufacturers.get(team.engine_manufacturer)


static func is_works(team: TeamData) -> bool:
	var m := manufacturer_of(team)
	return m != null and m.works_team_id == team.id


## Can this team develop the engine (licence or own works engine)?
static func develops(team: TeamData) -> bool:
	return team.engine_deal.get("type", "") in ["licence", "works"] and is_works(team)


## Newest spec of a component this team can get right now.
static func latest_spec(m: ManufacturerData, component: StringName, team: TeamData = null) -> Dictionary:
	var works := team != null and m.works_team_id == team.id
	var key := now_key()
	var best: Dictionary = m.specs[component][0]
	for spec in m.specs[component]:
		if (spec.works if works else spec.customers) <= key:
			best = spec
	return best


## Component values of the newest specs this team can get.
static func available_components(team: TeamData) -> Dictionary:
	var m := manufacturer_of(team)
	var out := {}
	if not m:
		return out
	for c in PowerUnit.COMPONENTS:
		out[c] = latest_spec(m, c, team).values
	return out


static func available_values(team: TeamData) -> Dictionary:
	var comps := available_components(team)
	return PowerUnit.compute(comps) if not comps.is_empty() else {}


## Specs a team does not have yet: [[component, spec, round key for this team]].
static func upcoming(team: TeamData) -> Array:
	var m := manufacturer_of(team)
	var out := []
	if not m:
		return out
	var works := m.works_team_id == team.id
	var key := now_key()
	for c in PowerUnit.COMPONENTS:
		for spec in m.specs[c]:
			var when: int = spec.works if works else spec.customers
			if when > key:
				out.append([c, spec, when])
	return out


static func teams_of(m: ManufacturerData) -> Array:
	return GameState.teams.values().filter(func(t): return t.engine_manufacturer == m.id)


## Engine values of every manufacturer (newest works spec), for comparisons.
static func manufacturer_values(m: ManufacturerData) -> Dictionary:
	return _values_of_specs(m, func(list):
		var best: Dictionary = list[0]
		for spec in list:
			if spec.works <= now_key():
				best = spec
		return best)


## Rank of the team's engine value among the teams of the series (1 = best).
static func rank(team: TeamData, value: StringName) -> int:
	var own: float = available_values(team).get(value, 50.0)
	var place := 1
	for id in GameState.series[team.series_id].team_ids:
		var other: TeamData = GameState.teams[id]
		if other != team and available_values(other).get(value, 50.0) > own + 0.01:
			place += 1
	return place


static func field_average(value: StringName) -> float:
	var total := 0.0
	var n := 0
	for t: TeamData in GameState.teams.values():
		if t.engine_manufacturer != &"":
			total += available_values(t).get(value, 50.0)
			n += 1
	return total / maxf(n, 1)


## A new spec is homologated (engine lab): the works team gets it now,
## customers after 1–3 races depending on the relationship.
static func release_spec(m: ManufacturerData, component: StringName, values: Dictionary) -> Dictionary:
	var list: Array = m.specs[component]
	var key := now_key()
	var spec := {"version": list.back().version + 1, "values": values, "works": key, "customers": key + 1}
	list.append(spec)
	m.specs_this_season[component] = m.specs_this_season.get(component, 0) + 1
	var player := GameState.player_team()
	if player.engine_manufacturer == m.id:
		var delay := customer_delay(m, player)
		var own := m.works_team_id == player.id
		var msg := InboxMessage.new()
		msg.sender = "Engine chief"
		msg.icon = "cog"
		msg.subject = "New engine spec: %s %s"
		msg.subject_args = [Loc.t(PowerUnit.name_of(component)), "Spec %d" % spec.version]
		if own:
			msg.add_paragraph("Our %s Spec %d is homologated. New engine units are built with it from now on.",
				[Loc.t(PowerUnit.name_of(component)), spec.version])
		else:
			msg.add_paragraph("%s brings %s Spec %d. Their works team has it now, we get it from %s.",
				[m.name, Loc.t(PowerUnit.name_of(component)), spec.version, round_label(key + delay)])
		msg.add_paragraph("A new spec only reaches the car with a new engine unit.")
		msg.link_screen = &"engine"
		msg.link_label = "Open engine"
		GameState.add_message(msg)
	for team: TeamData in teams_of(m):
		if m.works_team_id != team.id:
			spec.customers = maxi(spec.customers, key + customer_delay(m, team))
	return spec


## Races a customer waits for a new spec: 1 (good relationship) to 3.
static func customer_delay(m: ManufacturerData, team: TeamData) -> int:
	var rel: int = m.relationship.get(team.id, 50)
	return clampi(CUSTOMER_DELAY_MAX - roundi(rel / 40.0), 1, CUSTOMER_DELAY_MAX)


# --- Engine units ----------------------------------------------------------------

static func units_of(team: TeamData, driver_id: StringName) -> Array:
	return team.engine_units.filter(func(u): return u.driver_id == driver_id)


static func fitted_unit(team: TeamData, driver_id: StringName) -> EngineUnit:
	for u: EngineUnit in team.engine_units:
		if u.driver_id == driver_id and u.fitted:
			return u
	return null


static func pool_left(team: TeamData, driver_id: StringName) -> int:
	return PowerUnit.UNITS_PER_SEASON - units_of(team, driver_id).size()


## Builds a unit with the newest spec the team can get and fits it. Units
## beyond the pool cost extra (grid penalties come with R9).
static func new_unit(team: TeamData, driver_id: StringName, pay: bool = true) -> EngineUnit:
	var m := manufacturer_of(team)
	var u := EngineUnit.new()
	u.driver_id = driver_id
	u.season = Calendar.year
	u.number = units_of(team, driver_id).size() + 1
	var comps := {}
	for c in PowerUnit.COMPONENTS:
		var spec := latest_spec(m, c, team)
		comps[c] = spec.values
		u.spec_versions[c] = spec.version
	u.values = PowerUnit.compute(comps)
	if pay and u.number > PowerUnit.UNITS_PER_SEASON:
		team.budget -= PowerUnit.EXTRA_UNIT_COST
		GameState.engine_spending[team.id] = GameState.engine_spending.get(team.id, 0) + PowerUnit.EXTRA_UNIT_COST
		EventBus.budget_changed.emit(team.id, team.budget)
	for other: EngineUnit in team.engine_units:
		if other.driver_id == driver_id:
			other.fitted = false
	u.fitted = true
	team.engine_units.append(u)
	return u


## Refits an older, still usable unit (e.g. after a failure in the new one).
static func refit(team: TeamData, unit: EngineUnit) -> void:
	for other: EngineUnit in team.engine_units:
		if other.driver_id == unit.driver_id:
			other.fitted = other == unit


## The engine chief's advice: [new unit?, reason].
static func recommend_new_unit(team: TeamData, driver_id: StringName) -> Array:
	var u := fitted_unit(team, driver_id)
	if u == null or u.is_dead():
		return [true, "The current unit is finished."]
	if u.damage >= 0.3:
		return [true, "The unit was damaged in the last race."]
	var races_left := GameState.series[team.series_id].calendar.size() - GameState.resolved_rounds
	var left := pool_left(team, driver_id)
	if u.used() >= 0.8 and left > 0:
		return [true, "The unit is close to the end of its life."]
	var newer := false
	for c in PowerUnit.COMPONENTS:
		if latest_spec(manufacturer_of(team), c, team).version > u.spec_versions.get(c, 1):
			newer = true
	if newer and left > 0 and races_left > 0 and u.used() >= 0.35 and left * 5 >= races_left - 1:
		return [true, "A newer spec is available – worth fitting now."]
	return [false, "The current unit still has life in it."]


## Before a weekend: the AI teams follow their engine chief; every car gets a working unit.
static func prepare_weekend(team: TeamData, choices: Dictionary = {}) -> void:
	if team.engine_manufacturer == &"":
		return
	# Units of drivers who left the team go back to the manufacturer.
	var ids := GameState.drivers_of_team(team.id).map(func(d): return d.id)
	team.engine_units = team.engine_units.filter(func(u): return ids.has(u.driver_id))
	for d in GameState.drivers_of_team(team.id):
		var fresh: bool = choices.get(d.id, recommend_new_unit(team, d.id)[0])
		var u := fitted_unit(team, d.id)
		if fresh or u == null or u.is_dead():
			new_unit(team, d.id)
	refresh_team(team)


## After the race: kilometres and damage for every fitted unit.
static func after_weekend(cars: Array, lap_km: float, laps: int) -> void:
	for car: SimCar in cars:
		var team := car.team
		var u := fitted_unit(team, car.driver.id)
		if u == null:
			continue
		var race_km: float = car.engine_km if car.engine_km > 0.0 else lap_km * mini(car.laps_done, laps)
		u.km += PowerUnit.PRACTICE_KM + PowerUnit.QUALI_KM * PowerUnit.MODES[PowerUnit.Mode.QUALIFYING][2] + race_km
		if car.retired and car.retire_reason == "Engine failure":
			u.damage = 1.0
		elif car.damage.has("power"):
			u.damage = minf(1.0, u.damage + car.rng.randf_range(0.3, 0.6))
	for team: TeamData in GameState.teams.values():
		refresh_team(team)


# --- The engine in the car ---------------------------------------------------------

## Writes the engine values into a car: the driver's fitted unit (with wear)
## or, without a driver, the newest spec the team has.
static func apply(car: CarData, team: TeamData, driver_id: StringName = &"") -> void:
	var m := manufacturer_of(team)
	if not m or not car.has_parts():
		return
	var values := available_values(team)
	var loss := 0.0
	car.engine_wear_risk = 1.0
	if driver_id != &"":
		var u := fitted_unit(team, driver_id)
		if u:
			values = u.values
			loss = PowerUnit.wear_power_loss(u.km, u.life_km()) + u.damage * 2.0
			car.engine_wear_risk = PowerUnit.wear_risk(u.km, u.life_km())
	car.engine_base = roundi(values[&"power"] - loss)
	car.reliability = roundi(values[&"reliability"])
	car.engine_efficiency = values[&"efficiency"]
	car.engine_drivability = values[&"drivability"]
	car.pu_mass_kg = PowerUnit.mass_kg(values[&"weight"])
	var works := m.works_team_id == team.id
	var first_year: bool = team.engine_deal.get("since", 0) >= Calendar.year
	car.engine_cooling_fit = 2 if works else (-3 if first_year else 0)
	car.engine_mass_fit = -2.0 if works else (3.0 if first_year else 0.0)


static func refresh_team(team: TeamData) -> void:
	apply(team.car, team)
	CarBuild.recalculate(team.car)


# --- Money -------------------------------------------------------------------------

## Monthly engine fee (paid with the salaries); the works team of the
## manufacturer receives it, minus the support of its customers.
static func pay_month(team: TeamData) -> int:
	var price: int = team.engine_deal.get("price", 0)
	if price <= 0:
		return 0
	var fee := price / 12
	team.budget -= fee
	var m := manufacturer_of(team)
	var receiver_id: StringName = m.works_team_id if m else &""
	if m and m.licensed_from != &"":
		var origin: ManufacturerData = GameState.manufacturers.get(m.licensed_from)
		receiver_id = origin.works_team_id if origin else &""
	if receiver_id != &"" and receiver_id != team.id and GameState.teams.has(receiver_id):
		var receiver: TeamData = GameState.teams[receiver_id]
		receiver.budget += fee - CUSTOMER_SUPPORT / 12
	return fee


# --- Contracts ---------------------------------------------------------------------

## Negotiations for next season: 1 July to the end of the year.
static func window_open() -> bool:
	return Calendar.date_of().month >= 7


## Teams the manufacturer supplies next season (signed or still running).
static func teams_next_season(m: ManufacturerData) -> Array:
	var year := Calendar.year + 1
	var out := []
	for t: TeamData in GameState.teams.values():
		if t.engine_next.get("manufacturer", &"") == m.id:
			out.append(t.id)
		elif t.engine_next.is_empty() and t.engine_manufacturer == m.id and t.engine_deal.get("until", 0) >= year:
			out.append(t.id)
	return out


static func places_next_season(m: ManufacturerData) -> int:
	return m.max_teams - teams_next_season(m).size()


## Asks a manufacturer for an offer; the answer comes after a few days.
## type: "customer" or "licence".
static func request_offer(team: TeamData, m: ManufacturerData, type: String, years: int) -> String:
	if not window_open():
		return "Engine negotiations open on 1 July."
	if type == "licence" and Facilities.level(team, &"engine") < 1:
		return "A licence needs engine works level 1."
	for o in GameState.engine_offers:
		if o.team == team.id and o.manufacturer == m.id and o.state in ["pending", "offer"]:
			return "There is already a request with this manufacturer."
	GameState.engine_offers.append({"team": team.id, "manufacturer": m.id, "type": type, "years": years,
		"price": 0, "answer_day": Calendar.day + 3 + randi() % 4, "expires_day": 0, "state": "pending", "reason": ""})
	return ""


## The manufacturer's answer: price, or a refusal with a reason.
static func _answer(o: Dictionary) -> void:
	var team: TeamData = GameState.teams[o.team]
	var m: ManufacturerData = GameState.manufacturers[o.manufacturer]
	var staying: bool = teams_next_season(m).has(team.id)
	var rank := TeamMood.car_rank(team.id)
	var works_rank := TeamMood.car_rank(m.works_team_id) if m.works_team_id != &"" else 99
	if not staying and places_next_season(m) <= 0:
		o.state = "refused"
		o.reason = "All places for next season are taken."
	elif m.works_team_id != &"" and not staying and rank <= works_rank and o.type == "customer" and rank <= 3:
		o.state = "refused"
		o.reason = "They do not want to supply a direct rival of their works team."
	else:
		var rel: int = m.relationship.get(team.id, 50)
		var price := m.price * (LICENCE_FACTOR if o.type == "licence" else 1.0)
		price *= 1.0 + (50 - rel) / 500.0 + (0.03 if o.years == 1 else 0.0) - (0.03 if o.years == 3 else 0.0)
		o.price = int(roundf(price / 100_000.0) * 100_000)
		o.state = "offer"
		o.expires_day = Calendar.day + OFFER_VALID_DAYS
	if team.id == GameState.player_team_id:
		var msg := InboxMessage.new()
		msg.sender = "Sporting director"
		msg.icon = "cog"
		msg.link_screen = &"engine"
		msg.link_args = {"tab": 3}
		msg.link_label = "Open engine contracts"
		if o.state == "offer":
			msg.priority = InboxMessage.Priority.IMPORTANT
			msg.subject = "Engine offer: %s"
			msg.subject_args = [m.name]
			msg.add_paragraph("%s offers a %s engine for %d year(s) at %s per year. The offer is valid for %d days.",
				[m.name, Loc.t("licence" if o.type == "licence" else "customer"), o.years, UIStyle.money(o.price), OFFER_VALID_DAYS])
		else:
			msg.subject = "Engine request declined: %s"
			msg.subject_args = [m.name]
			msg.add_paragraph(Loc.t(o.reason))
		GameState.add_message(msg)


## Signs an offer for next season.
static func accept_offer(o: Dictionary) -> String:
	if o.state != "offer":
		return "This offer is no longer open."
	var team: TeamData = GameState.teams[o.team]
	var m: ManufacturerData = GameState.manufacturers[o.manufacturer]
	if not teams_next_season(m).has(team.id) and places_next_season(m) <= 0:
		return "All places for next season are taken."
	var same: bool = team.engine_manufacturer == m.id and team.engine_deal.get("type", "") == o.type
	team.engine_next = {"manufacturer": m.id, "type": o.type, "price": o.price, "until": Calendar.year + o.years,
		"since": team.engine_deal.get("since", Calendar.year + 1) if same else Calendar.year + 1}
	o.state = "signed"
	for other in GameState.engine_offers:
		if other.team == team.id and other != o and other.state in ["pending", "offer"]:
			other.state = "withdrawn"
	if team.engine_manufacturer != m.id:
		var old := manufacturer_of(team)
		if old:
			old.relationship[team.id] = maxi(0, old.relationship.get(team.id, 50) - 10)
	m.relationship[team.id] = mini(100, m.relationship.get(team.id, 50) + 5)
	return ""


static func offers_of(team: TeamData) -> Array:
	return GameState.engine_offers.filter(func(o): return o.team == team.id)


## How much an AI team likes a manufacturer's engine for its money.
static func _ai_score(team: TeamData, m: ManufacturerData) -> float:
	var values := manufacturer_values(m)
	var score := 0.0
	for v in AI_VALUE_WEIGHTS:
		score += values[v] * AI_VALUE_WEIGHTS[v]
	var budget_m := team.budget / 1_000_000.0
	return score - m.price / 1_000_000.0 * clampf(60.0 / maxf(budget_m, 30.0), 0.15, 2.0)


static func _ai_contracts() -> void:
	for team: TeamData in GameState.teams.values():
		if team.id == GameState.player_team_id or not team.engine_next.is_empty() or is_works(team):
			continue
		if team.engine_deal.get("until", 0) > Calendar.year:
			continue
		var best: ManufacturerData = null
		var best_score := -INF
		for m: ManufacturerData in GameState.manufacturers.values():
			if m.licensed_from != &"" or (places_next_season(m) <= 0 and not teams_next_season(m).has(team.id)):
				continue
			var score := _ai_score(team, m) + (3.0 if m.id == team.engine_manufacturer else 0.0)
			if score > best_score:
				best_score = score
				best = m
		if best:
			var same := best.id == team.engine_manufacturer
			team.engine_next = {"manufacturer": best.id, "type": "customer", "price": best.price,
				"until": Calendar.year + 1 + randi() % 2, "since": team.engine_deal.get("since", Calendar.year + 1) if same else Calendar.year + 1}


# --- Every day / new season --------------------------------------------------------

static func daily_update() -> void:
	for o in GameState.engine_offers:
		if o.state == "pending" and Calendar.day >= o.answer_day:
			_answer(o)
		elif o.state == "offer" and Calendar.day > o.expires_day:
			o.state = "expired"
	if Calendar.day == 260:
		_ai_contracts()
		_expiry_warning()


static func _expiry_warning() -> void:
	var team := GameState.player_team()
	if team.engine_next.is_empty() and team.engine_deal.get("until", 0) <= Calendar.year:
		var msg := InboxMessage.new()
		msg.sender = "Sporting director"
		msg.icon = "cog"
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.subject = "Engine contract expires"
		msg.add_paragraph("Our engine deal with %s ends with this season. Without a new deal I will extend it for one year at the end of the season.",
			[manufacturer_of(team).name])
		msg.link_screen = &"engine"
		msg.link_args = {"tab": 3}
		msg.link_label = "Open engine contracts"
		GameState.add_message(msg)


## Contracts change, licences are set up, every driver gets a fresh pool.
static func new_season(year: int) -> void:
	for m: ManufacturerData in GameState.manufacturers.values():
		m.specs_this_season = {}
	GameState.engine_offers = GameState.engine_offers.filter(func(o): return o.state == "pending")
	for team: TeamData in GameState.teams.values():
		if team.engine_manufacturer == &"":
			continue
		if not team.engine_next.is_empty():
			var next := team.engine_next.duplicate()
			var m_id: StringName = next.manufacturer
			if next.type == "licence":
				m_id = _licence_copy(team, GameState.manufacturers[m_id]).id
			team.engine_manufacturer = m_id
			next.erase("manufacturer")
			team.engine_deal = next
			team.engine_next = {}
		elif team.engine_deal.get("until", 0) < year:
			_extend(team, year)
		team.engine_units.clear()
		for d in GameState.drivers_of_team(team.id):
			new_unit(team, d.id, false)
		refresh_team(team)


## No new deal: the sporting director extends the old one for a year.
static func _extend(team: TeamData, year: int) -> void:
	var m := manufacturer_of(team)
	if m.works_team_id != team.id and teams_next_season(m).size() > m.max_teams:
		for other: ManufacturerData in GameState.manufacturers.values():
			if other.licensed_from == &"" and teams_next_season(other).size() < other.max_teams:
				m = other
				break
	var switched := m.id != team.engine_manufacturer
	team.engine_manufacturer = m.id
	team.engine_deal = {"type": team.engine_deal.get("type", "customer") if not switched else "customer",
		"price": int(team.engine_deal.get("price", m.price) * 1.05) if not switched else m.price,
		"until": year, "since": year if switched else team.engine_deal.get("since", year)}
	if team.id == GameState.player_team_id:
		var msg := InboxMessage.new()
		msg.sender = "Sporting director"
		msg.icon = "cog"
		msg.subject = "Engine deal extended"
		msg.add_paragraph("Without a new deal I extended our engine supply with %s for one year at %s.",
			[m.name, UIStyle.money(team.engine_deal.price)])
		msg.link_screen = &"engine"
		msg.link_label = "Open engine"
		GameState.add_message(msg)


## A licence: the team gets its own copy of the manufacturer's engine and
## develops it itself; the fee goes to the original manufacturer.
static func _licence_copy(team: TeamData, origin: ManufacturerData) -> ManufacturerData:
	var id := StringName("%s_licence" % team.id)
	var m: ManufacturerData = GameState.manufacturers.get(id)
	if m == null:
		m = ManufacturerData.new()
		m.id = id
		GameState.manufacturers[id] = m
	m.name = TranslationServer.translate("%s (%s licence)") % [team.short_name, origin.short_name]
	m.short_name = team.short_name
	m.color = team.primary_color
	m.works_team_id = team.id
	m.licensed_from = origin.id
	m.max_teams = 1
	m.price = origin.price
	m.specs = {}
	for c in PowerUnit.COMPONENTS:
		var spec := latest_spec(origin, c, null)
		m.specs[c] = [{"version": spec.version, "values": spec.values.duplicate(), "works": 0, "customers": 0}]
	return m


## The power unit programme is finished: the team becomes a manufacturer
## from next season (docs/engine_model.md 3).
static func create_own_manufacturer(team: TeamData, components: Dictionary) -> ManufacturerData:
	var m := ManufacturerData.new()
	m.id = StringName("%s_power" % team.id)
	m.name = TranslationServer.translate("%s Power") % team.name.split(" ")[0]
	m.short_name = team.short_name
	m.color = team.primary_color
	m.works_team_id = team.id
	m.price = 16_000_000
	m.relationship[team.id] = 100
	var key := (Calendar.year + 1) * 100
	for c in PowerUnit.COMPONENTS:
		m.specs[c] = [{"version": 1, "values": components[c], "works": key, "customers": key}]
	GameState.manufacturers[m.id] = m
	team.engine_next = {"manufacturer": m.id, "type": "works", "price": 0, "until": Calendar.year + 6, "since": Calendar.year + 1}
	return m
