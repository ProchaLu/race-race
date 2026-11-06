## The academy (R7, docs/youth_model.md 4 and 9–13): young drivers a team
## trains and places in the junior seats. Places come from the Academy
## building; at most two drivers per team race in F3 and two in F2. Juniors
## choose their academy (interest, promises, signing bonus, rival academies),
## have a contract with a release clause and a mood. The academy sets a
## training focus, a mentor and the young driver test, and decides the way to
## F1: promotion, loan to another team or sale. AI teams run academies too.
class_name Academy
extends RefCounted

## Academy places by building level 0..5.
const PLACES_BY_LEVEL := [0, 2, 3, 4, 6, 8]
## Junior seats per team and series at the same time.
const MAX_PLACED := {&"f3": 2, &"f2": 2}
## Oldest age a driver can join the academy at.
const INTAKE_MAX_AGE := 22
const SIGNING_FEE := 250_000
## Per academy driver and month (the department of youth development).
const FEE_PER_MONTH := 40_000
## Per season, paid when a driver sits in a junior seat.
const PLACEMENT_FEE := {&"f3": 300_000, &"f2": 900_000}
## Paid to the junior team on top when its seat is taken and our driver
## replaces the weaker of its two drivers.
const SEAT_BUYOUT := {&"f3": 250_000, &"f2": 750_000}
## Share of the gap to the potential that the academy adds each winter.
## Scaled by the head's skill (0.6 .. 1.6) and the building level (1.1 .. 1.5).
const GROWTH := 0.15
## Training focus: [name, attributes trained more]. The others grow less.
const FOCUS := {
	&"pace": ["Pace", [&"one_lap_pace", &"cornering", &"braking"]],
	&"racecraft": ["Racecraft", [&"overtaking", &"defending", &"racecraft", &"starts"]],
	&"tyres": ["Tyres and consistency", [&"tyre_management", &"fuel_management", &"consistency"]],
	&"wet": ["Wet weather", [&"wet_skill", &"adaptability"]],
	&"fitness": ["Fitness", [&"fitness", &"reactions"]],
	&"mental": ["Mental strength", [&"composure", &"focus"]],
}
const FOCUS_ON := 1.8
const FOCUS_OFF := 0.7
## Mentor: faster growth, more if the mentor has the Mentor trait.
const MENTOR_BONUS := 0.1
const MENTOR_TRAIT_BONUS := 0.15
## Young driver test at the end of the season.
const TEST_COST := 150_000
const TEST_PLACES := 2
## Contracts: years offered, extension fee per year, release clause.
const YEARS := [1, 2, 3]
const EXTEND_FEE_PER_YEAR := 100_000
const RELEASE_FACTOR := 1.5
## A junior says yes from this interest on (and only above a rival academy).
const MIN_INTEREST := 60
## Signing bonus options and the interest they add (2 per 25 000 $, capped).
const BONUSES := [0, 50_000, 150_000, 300_000]
const BONUS_INTEREST_MAX := 16
const PROMISE_INTEREST := {&"": 0, &"f3_seat": 8, &"f2_seat": 16}
## Mood factors (morale_factors keys and values).
const MOOD := {"No junior seat": -10, "Racing in F2": 6, "Mentor": 6, "Young driver test": 8, "Broken promise": -25,
	"Promise kept": 8, "Joined an academy": 5}
## AI: chance per month and team to sign a junior, value it looks for.
const AI_SIGN_CHANCE := 0.3
const AI_MIN_VALUE := 86.0
## Offers of other academies for our juniors: chance per month and driver.
const OFFER_CHANCE := 0.08
const OFFER_DAYS := 14
## Loan fee the F1 team pays for a junior.
const LOAN_FEE := 300_000


static func places(team: TeamData) -> int:
	return PLACES_BY_LEVEL[clampi(Facilities.level(team, &"academy"), 0, 5)]


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


## Academy drivers of a team in junior seats of one series.
static func placed_in(team: TeamData, series_id: StringName) -> int:
	var n := 0
	for d in drivers(team):
		var t := Youth.team_of(d)
		if t and t.series_id == series_id:
			n += 1
	return n


## Takes the driver out of the academy (his junior seat is not touched).
static func forget(d: DriverData) -> void:
	var team: TeamData = GameState.teams.get(d.academy_team_id)
	if team:
		team.academy_driver_ids.erase(d.id)
	d.academy_team_id = &""
	d.academy_until = 0
	d.academy_release_clause = 0
	d.academy_promise = &""
	d.academy_focus = &""
	d.mentor_id = &""
	d.young_driver_test = false
	for key in MOOD:
		d.morale_factors.erase(key)
	d.recalculate_morale()


## What a junior is worth to another academy.
static func fee_for(d: DriverData) -> int:
	return maxi(300_000, roundi((Youth.value(d) - 70.0) * 120_000 / 50_000.0) * 50_000)


# --- Signing ---------------------------------------------------------------------

## The academy that would fight us for this junior: {"team": TeamData or null, "score": int}.
static func rival_for(d: DriverData, except: TeamData = null) -> Dictionary:
	var best := {"team": null, "score": 0}
	for t in GameState.teams.values():
		if t == except or t.id == GameState.player_team_id or free_places(t) <= 0 or t.id == d.academy_team_id:
			continue
		if _ai_estimate(t, d) < AI_MIN_VALUE:
			continue
		var score := _attraction(t) + (hash(str(t.id) + str(d.id)) % 13) - 6
		if score > best.score:
			best = {"team": t, "score": score}
	return best


## How attractive an academy is for juniors (without promises and money).
static func _attraction(team: TeamData) -> int:
	var h := head(team)
	var mentoring: int = h.attribute(&"mentoring") if h else 30
	return roundi(30 + team.reputation * 0.3 + Facilities.level(team, &"academy") * 4 + mentoring * 0.08)


## How much the junior wants to join: {"score", "rival": TeamData, "rival_score",
## "accepted", "reason"}. terms: {"years", "promise", "bonus"}.
static func interest(team: TeamData, d: DriverData, terms: Dictionary) -> Dictionary:
	var score := _attraction(team)
	var promise: StringName = terms.get("promise", &"")
	if promise == &"f3_seat" and d.age(Calendar.year + 1) > Youth.MAX_AGE_F3:
		promise = &""
	score += PROMISE_INTEREST.get(promise, 0)
	score += mini(BONUS_INTEREST_MAX, roundi(terms.get("bonus", 0) / 25_000.0 * 2.0))
	var years: int = terms.get("years", 2)
	score += {1: 4, 2: 0, 3: -4}.get(years, 0)
	# Ambitious kids want a seat now; a wonderkid knows his worth.
	if Youth.team_of(d) == null and not Youth.is_karting(d) and promise == &"":
		score -= roundi(d.ambition / 15.0)
	if d.talent == &"wonderkid":
		score -= 6
	if d.academy_team_id != &"":
		score -= 5
	var rival := rival_for(d, team)
	var out := {"score": score, "rival": rival.team, "rival_score": rival.score, "accepted": false, "reason": ""}
	if score < MIN_INTEREST:
		out.reason = "He is not convinced yet. A promise or a signing bonus could help."
	elif rival.team and rival.score >= score:
		out.reason = "He prefers the academy of %s." % rival.team.name
	else:
		out.accepted = true
	return out


## Can this team try to sign the junior at all? "" or the reason.
static func can_sign(team: TeamData, d: DriverData) -> String:
	if not Youth.is_youth(d) or d.retired or (d.team_id != &"" and Youth.team_of(d) == null):
		return "This person is not a junior."
	if d.age(Calendar.year) > INTAKE_MAX_AGE:
		return "Too old for the academy (up to %d years)." % INTAKE_MAX_AGE
	if d.academy_team_id == team.id:
		return "Already in our academy."
	if free_places(team) <= 0:
		return "All academy places are taken. A larger academy building makes room for more."
	return ""


## Signs a junior into the academy: from karting, the pool or one who already
## drives for an F3/F2 team (he keeps his seat). A junior of another academy
## needs terms.buyout (the release clause is paid). The player's offers must
## convince the junior (interest); AI teams sign directly. Returns "" or the reason.
static func sign_junior(team: TeamData, d: DriverData, terms: Dictionary = {}) -> String:
	var reason := can_sign(team, d)
	if reason != "":
		return reason
	var old: TeamData = GameState.teams.get(d.academy_team_id)
	if old and not terms.get("buyout", false):
		return "This junior belongs to the academy of %s." % old.name
	if team.id == GameState.player_team_id and not terms.get("force", false):
		var answer := interest(team, d, terms)
		if not answer.accepted:
			return answer.reason
	if old:
		var clause := d.academy_release_clause
		Finance.pay(team, &"transfer_out", clause)
		Finance.receive(old, &"transfer_in", clause)
		forget(d)
		if old.id == GameState.player_team_id:
			_message("%s leaves our academy", [d.full_name()], ["%s paid the release clause of %s. He joins their academy.",
				[team.name, UIStyle.money(clause)]], d)
	var years: int = terms.get("years", 2)
	d.academy_team_id = team.id
	team.academy_driver_ids.append(d.id)
	d.academy_until = Calendar.year + years - 1 + (1 if Calendar.date_of().month >= 7 else 0)
	d.academy_release_clause = roundi(fee_for(d) * RELEASE_FACTOR)
	d.academy_promise = terms.get("promise", &"")
	d.academy_promise_year = Calendar.year + (1 if Youth.standings(Youth.F3).rounds > 0 else 0)
	d.morale_factors["Joined an academy"] = MOOD["Joined an academy"]
	if team.id == GameState.player_team_id:
		GameState.knowledge[d.id] = 100
	elif GameState.shortlist.has(d.id) or Knowledge.level(d) >= 50 or GameState.junior_hype.has(d.id):
		_message("%s joins the academy of %s", [d.full_name(), team.name],
			["A junior we were watching is gone: %s signed with %s.", [d.full_name(), team.name]], d)
	Finance.pay(team, &"academy", SIGNING_FEE + int(terms.get("bonus", 0)))
	_update_mood(d)
	return ""


## Ends the academy membership. A driver in a junior seat leaves that seat too.
static func release(d: DriverData) -> void:
	if is_placed(d):
		Youth.unseat(d)
	forget(d)


## Two more seasons. The junior agrees unless he is unhappy. Returns "" or the reason.
static func extend(team: TeamData, d: DriverData, years: int = 2) -> String:
	if d.academy_team_id != team.id:
		return "Not in the academy."
	if d.morale < 35:
		return "He is unhappy and does not want to stay."
	d.academy_until = maxi(d.academy_until, Calendar.year) + years
	d.academy_release_clause = roundi(fee_for(d) * RELEASE_FACTOR)
	Finance.pay(team, &"academy", EXTEND_FEE_PER_YEAR * years)
	return ""


# --- Seats -------------------------------------------------------------------------

## What a seat at a junior team would cost for this driver: {"reason": "" or why not,
## "replaces": DriverData or null, "cost": int}. A taken seat is bought: the
## weaker driver who is not an academy driver makes room.
static func seat_offer(team: TeamData, d: DriverData, t: YouthTeam) -> Dictionary:
	var out := {"reason": "", "replaces": null, "cost": PLACEMENT_FEE[t.series_id]}
	var current := Youth.team_of(d)
	if d.academy_team_id != team.id:
		out.reason = "Not in the academy."
	elif d.team_id == t.id:
		out.reason = "Already drives for %s." % t.name
	elif d.loan_from != &"":
		out.reason = "He is on loan in F1."
	elif d.age(Calendar.year) < Youth.MIN_SEAT_AGE:
		out.reason = "Too young for %s (from %d years)." % [Youth.SERIES_NAMES[t.series_id], Youth.MIN_SEAT_AGE]
	elif d.age(Calendar.year) > Youth.max_age(t.series_id):
		out.reason = "Too old for %s (up to %d years)." % [Youth.SERIES_NAMES[t.series_id], Youth.max_age(t.series_id)]
	elif placed_in(team, t.series_id) - (1 if current and current.series_id == t.series_id else 0) >= MAX_PLACED[t.series_id]:
		out.reason = "Already %d academy drivers in %s." % [MAX_PLACED[t.series_id], Youth.SERIES_NAMES[t.series_id]]
	elif t.driver_ids.size() >= Youth.SEATS:
		var weakest: DriverData = null
		for id in t.driver_ids:
			var other: DriverData = GameState.drivers.get(id)
			if other and other.academy_team_id == &"" and (weakest == null or Youth.value(other) < Youth.value(weakest)):
				weakest = other
		if weakest == null:
			out.reason = "Both seats at %s belong to academy drivers." % t.name
		else:
			out.replaces = weakest
			out.cost += SEAT_BUYOUT[t.series_id]
	return out


## Places an academy driver at a junior team: in a free seat, or a bought one
## (the replaced driver goes back to the pool). Returns "" or the reason.
static func place(team: TeamData, d: DriverData, t: YouthTeam) -> String:
	var offer := seat_offer(team, d, t)
	if offer.reason != "":
		return offer.reason
	if offer.replaces:
		Youth.unseat(offer.replaces)
	if d.team_id != &"":
		Youth.unseat(d)
	Youth.seat(d, t)
	Finance.pay(team, &"academy", offer.cost)
	_update_mood(d)
	return ""


## Takes a placed driver back to the academy (his seat becomes free).
static func bring_back(d: DriverData) -> void:
	if is_placed(d):
		Youth.unseat(d)
		_update_mood(d)


# --- Development and mood ------------------------------------------------------------

static func set_focus(d: DriverData, focus: StringName) -> void:
	d.academy_focus = focus if FOCUS.has(focus) else &""


## Own F1 drivers who can coach juniors.
static func mentors(team: TeamData) -> Array[DriverData]:
	var out: Array[DriverData] = []
	for id in team.driver_ids + team.reserve_driver_ids:
		if GameState.drivers.has(id):
			out.append(GameState.drivers[id])
	return out


static func set_mentor(d: DriverData, mentor_id: StringName) -> void:
	d.mentor_id = mentor_id
	_update_mood(d)


## Picks the junior for the young driver test (at most TEST_PLACES). Returns "" or the reason.
static func set_test(team: TeamData, d: DriverData, on: bool) -> String:
	if on and not d.young_driver_test:
		var picked := drivers(team).filter(func(x): return x.young_driver_test).size()
		if picked >= TEST_PLACES:
			return "Only %d drivers can take part in the young driver test." % TEST_PLACES
	d.young_driver_test = on
	return ""


## Growth factor of a junior in the winter: head, building, mentor.
static func growth_factor(team: TeamData, d: DriverData) -> float:
	var factor := (0.6 + head_skill(team) / 100.0) * (1.0 + 0.1 * Facilities.level(team, &"academy"))
	var mentor: DriverData = GameState.drivers.get(d.mentor_id)
	if mentor and mentor.team_id == team.id:
		factor *= 1.0 + MENTOR_BONUS + (MENTOR_TRAIT_BONUS if mentor.traits.has(&"mentor") else 0.0)
	return factor


## Sets the academy part of the junior's mood (fixed values, not summed up).
static func _update_mood(d: DriverData) -> void:
	if d.academy_team_id == &"":
		return
	var t := Youth.team_of(d)
	if t == null and not Youth.is_karting(d) and d.loan_from == &"" and d.age(Calendar.year) >= Youth.MIN_SEAT_AGE:
		d.morale_factors["No junior seat"] = MOOD["No junior seat"]
	else:
		d.morale_factors.erase("No junior seat")
	if t and t.series_id == Youth.F2:
		d.morale_factors["Racing in F2"] = MOOD["Racing in F2"]
	else:
		d.morale_factors.erase("Racing in F2")
	if d.mentor_id != &"" and GameState.drivers.has(d.mentor_id):
		d.morale_factors["Mentor"] = MOOD["Mentor"]
	else:
		d.morale_factors.erase("Mentor")
	d.recalculate_morale()


## At the first junior race of the season: promises made at signing are due.
static func check_promises(year: int) -> void:
	for team in GameState.teams.values():
		for d in drivers(team):
			if d.academy_promise == &"" or d.academy_promise_year > year:
				continue
			var t := Youth.team_of(d)
			var kept := t != null and (t.series_id == Youth.F2 or d.academy_promise == &"f3_seat")
			var key := "Promise kept" if kept else "Broken promise"
			d.morale_factors[key] = MOOD[key]
			d.recalculate_morale()
			if team.id == GameState.player_team_id:
				var f2 := d.academy_promise == &"f2_seat"
				if kept:
					_message("Promise kept: %s", [d.full_name()], ["We promised %s an F2 seat, and he got it. He is happy." if f2
						else "We promised %s a junior seat, and he got it. He is happy.", [d.full_name()]], d)
				else:
					_message("Broken promise: %s", [d.full_name()], ["We promised %s an F2 seat for this season and did not keep it. He is very disappointed." if f2
						else "We promised %s a junior seat for this season and did not keep it. He is very disappointed.", [d.full_name()]], d)
			d.academy_promise = &""


## New season for the player's academy: the drivers grow (head, building,
## focus, mentor), placed drivers pay their seat again, contracts that ran
## out end. Returns [[name, growth], ...] for the report.
static func new_season(team: TeamData, r: RandomNumberGenerator) -> Array:
	var out := []
	if not team:
		return out
	for d in drivers(team):
		out.append([d.full_name(), _grow(team, d, r)])
		d.morale_factors.erase("Young driver test")
		d.morale_factors.erase("Promise kept")
		d.morale_factors.erase("Joined an academy")
		if d.morale_factors.has("Broken promise"):
			d.morale_factors["Broken promise"] = -10
		if is_placed(d):
			var t := Youth.team_of(d)
			Finance.pay(team, &"academy", PLACEMENT_FEE[t.series_id])
		_update_mood(d)
	_end_contracts(team, Calendar.year)
	return out


static func _grow(team: TeamData, d: DriverData, r: RandomNumberGenerator) -> int:
	var gap := d.potential - d.overall()
	if gap <= 0:
		return 0
	var before := d.overall()
	var bonus := gap * GROWTH * growth_factor(team, d)
	var focus: Array = FOCUS.get(d.academy_focus, ["", []])[1]
	var trained: Array = DriverAttributes.DRIVING.map(func(e): return e[0])
	for p in focus:
		if not trained.has(p):
			trained.append(p)
	for p in trained:
		var share: float = bonus
		if not focus.is_empty():
			share *= FOCUS_ON if focus.has(p) else FOCUS_OFF
		d.set(p, clampi(d.get(p) + roundi(share * r.randf_range(0.8, 1.2)), 1, 100))
	var guard := 0
	while d.overall() > d.potential and guard < 200:
		guard += 1
		var entry: Array = DriverAttributes.DRIVING[r.randi() % DriverAttributes.DRIVING.size()]
		d.set(entry[0], clampi(d.get(entry[0]) - 1, 1, 100))
	return d.overall() - before


## Contracts that ran out: unhappy juniors leave, the others extend for two years.
static func _end_contracts(team: TeamData, year: int) -> void:
	for d in drivers(team):
		if d.academy_until == 0 or d.academy_until >= year:
			continue
		if d.morale >= 45:
			d.academy_until = year + 1
			if team.id == GameState.player_team_id:
				_message("%s stays in the academy", [d.full_name()],
					["His academy contract ran out. He was happy and signed for two more seasons.", []], d)
		else:
			if team.id == GameState.player_team_id:
				_message("%s leaves the academy", [d.full_name()],
					["His academy contract ran out and he was unhappy. He leaves us.", []], d)
			release(d)


## The young driver test at the end of the season: the picked juniors drive the
## F1 car, gain a little and are happier.
static func young_driver_tests(team: TeamData, r: RandomNumberGenerator) -> void:
	if not team:
		return
	var picked := drivers(team).filter(func(x): return x.young_driver_test)
	if picked.is_empty():
		return
	var best: DriverData = null
	for id in team.driver_ids:
		var f1: DriverData = GameState.drivers.get(id)
		if f1 and (best == null or f1.overall() > best.overall()):
			best = f1
	var msg := InboxMessage.new()
	msg.sender = "Academy head"
	msg.icon = "graduation-cap"
	msg.subject = "Young driver test"
	for d in picked:
		Finance.pay(team, &"academy", TEST_COST)
		var attrs := DriverAttributes.DRIVING.duplicate()
		attrs.shuffle()
		for entry in attrs.slice(0, 3):
			d.set(entry[0], clampi(d.get(entry[0]) + 1, 1, 100))
		d.morale_factors["Young driver test"] = MOOD["Young driver test"]
		d.recalculate_morale()
		d.young_driver_test = false
		if best:
			var gap := maxf(0.05, (best.overall() - d.overall()) * 0.06 + r.randf_range(-0.1, 0.3))
			msg.add_paragraph("%s: %s s off the best time of %s. Useful laps in the F1 car.",
				[d.full_name(), "%.2f" % gap, best.full_name()])
		else:
			msg.add_paragraph("%s: useful laps in the F1 car.", [d.full_name()])
	msg.link_screen = &"academy"
	msg.link_args = {}
	msg.link_label = "Open academy"
	GameState.add_message(msg)


# --- Monthly: fees, AI academies, offers --------------------------------------------

static func monthly_fees(team: TeamData) -> void:
	var count := team.academy_driver_ids.size()
	if count > 0:
		Finance.pay(team, &"academy", count * FEE_PER_MONTH)


## Once a month for every academy: fees, the AI signs juniors, other academies
## make offers for our juniors (or pay the release clause of unhappy ones).
static func monthly(r: RandomNumberGenerator) -> void:
	var player := GameState.player_team()
	for team in GameState.teams.values():
		monthly_fees(team)
		if team != player and places(team) > 0 and free_places(team) > 0 and r.randf() < AI_SIGN_CHANCE:
			_ai_sign(team)
	if player:
		for d in drivers(player):
			_update_mood(d)
		_offers_for(player, r)
	GameState.junior_offers = GameState.junior_offers.filter(func(o): return o.until_day >= Calendar.day)


## An AI team estimates a junior: the true value plus a fixed error that is
## smaller with a better scouting office.
static func _ai_estimate(team: TeamData, d: DriverData) -> float:
	var level := Facilities.level(team, &"scouting")
	if Youth.is_karting(d) and level < 2:
		return 0.0
	var noise := float(hash(str(team.id) + ":" + str(d.id)) % 21 - 10) * (1.2 - 0.2 * level)
	return Youth.value(d) + noise


static func _ai_sign(team: TeamData) -> void:
	var best: DriverData = null
	var best_value := AI_MIN_VALUE
	for d in GameState.drivers.values():
		if d.retired or not Youth.is_youth(d) or d.academy_team_id != &"" or d.age(Calendar.year) > 19:
			continue
		var est := _ai_estimate(team, d)
		if est > best_value:
			best_value = est
			best = d
	if best:
		sign_junior(team, best, {"years": 3})


## Other academies want our best juniors: an offer to accept or decline, or –
## with an unhappy junior – they pay his release clause right away.
static func _offers_for(player: TeamData, r: RandomNumberGenerator) -> void:
	for d in drivers(player):
		if d.loan_from != &"" or Youth.value(d) < AI_MIN_VALUE or r.randf() > OFFER_CHANCE * (2.0 if d.morale < 45 else 1.0):
			continue
		if GameState.junior_offers.any(func(o): return o.driver_id == d.id):
			continue
		var rival := rival_for(d, player)
		var buyer: TeamData = rival.team
		if buyer == null:
			continue
		var fee := fee_for(d)
		if d.morale < 45 and d.academy_release_clause <= roundi(fee * 1.3):
			sign_junior(buyer, d, {"buyout": true, "years": 3})
			continue
		GameState.junior_offers.append({"driver_id": d.id, "team_id": buyer.id, "fee": fee, "until_day": Calendar.day + OFFER_DAYS})
		_message("Offer for %s", [d.full_name()], ["%s offers %s for %s. The offer is open for two weeks.",
			[buyer.name, UIStyle.money(fee), d.full_name()]], d)


static func accept_offer(offer: Dictionary) -> String:
	var d: DriverData = GameState.drivers.get(offer.driver_id)
	var buyer: TeamData = GameState.teams.get(offer.team_id)
	GameState.junior_offers.erase(offer)
	if not d or not buyer or d.academy_team_id != GameState.player_team_id:
		return "The offer is no longer valid."
	return sell(GameState.player_team(), d, buyer, offer.fee)


static func decline_offer(offer: Dictionary) -> void:
	GameState.junior_offers.erase(offer)


## Who would buy the junior now: [{"team": TeamData, "fee": int}], best first.
static func sell_offers(team: TeamData, d: DriverData) -> Array:
	var out := []
	for t in GameState.teams.values():
		if t == team or free_places(t) <= 0:
			continue
		var est := _ai_estimate(t, d)
		if est < AI_MIN_VALUE - 10:
			continue
		var fee := roundi(fee_for(d) * clampf(est / Youth.value(d), 0.7, 1.2) / 50_000.0) * 50_000
		out.append({"team": t, "fee": fee})
	out.sort_custom(func(a, b): return a.fee > b.fee)
	return out.slice(0, 3)


## Sells the junior to another academy: he keeps his seat.
static func sell(team: TeamData, d: DriverData, buyer: TeamData, fee: int) -> String:
	if d.academy_team_id != team.id:
		return "Not in the academy."
	if free_places(buyer) <= 0:
		return "%s has no free academy place." % buyer.name
	forget(d)
	Finance.receive(team, &"transfer_in", fee)
	Finance.pay(buyer, &"transfer_out", fee)
	d.academy_team_id = buyer.id
	buyer.academy_driver_ids.append(d.id)
	d.academy_until = Calendar.year + 2
	d.academy_release_clause = roundi(fee_for(d) * RELEASE_FACTOR)
	GameState.knowledge[d.id] = 90
	return ""


# --- The way to F1 -------------------------------------------------------------------

## Makes the junior our reserve or race driver (needs the super licence).
## Returns "" or the reason.
static func promote(team: TeamData, d: DriverData, race_seat: bool) -> String:
	if d.academy_team_id != team.id:
		return "Not in the academy."
	if not d.has_superlicence:
		return "He needs the super licence first (%d of %d points)." % [Youth.licence_points(d), Youth.LICENCE_NEEDED]
	if race_seat and team.driver_ids.size() >= ContractLogic.RACE_SEATS:
		return "Both race seats are taken."
	if not race_seat and team.reserve_driver_ids.size() >= ContractLogic.RESERVE_SEATS:
		return "The reserve place is taken."
	if is_placed(d):
		Youth.unseat(d)
	forget(d)
	d.loan_from = &""
	ContractLogic.sign(d, team, {"salary": maxi(400_000, ContractLogic.market_value(d)), "years": 2,
		"role": ContractData.DriverRole.EQUAL if race_seat else ContractData.DriverRole.RESERVE})
	return ""


## F1 teams that would take the junior on loan for a season: their weakest race
## driver is not much better.
static func loan_options(team: TeamData, d: DriverData) -> Array[TeamData]:
	var out: Array[TeamData] = []
	if not d.has_superlicence or d.loan_from != &"":
		return out
	for t in GameState.teams.values():
		if t == team or t.series_id != team.series_id:
			continue
		var weakest := 100
		for id in t.driver_ids:
			var other: DriverData = GameState.drivers.get(id)
			if other:
				weakest = mini(weakest, other.overall())
		if d.overall() >= weakest - 4:
			out.append(t)
	return out


## Lends the junior to an F1 team until the end of the season; he stays ours.
static func loan(team: TeamData, d: DriverData, to: TeamData) -> String:
	if not loan_options(team, d).has(to):
		return "%s does not want him on loan." % to.name
	if is_placed(d):
		Youth.unseat(d)
	d.young_driver_test = false
	d.loan_from = team.id
	ContractLogic.sign(d, to, {"salary": 250_000, "years": 1, "role": ContractData.DriverRole.EQUAL})
	Finance.receive(team, &"transfer_in", LOAN_FEE)
	Finance.pay(to, &"transfer_out", LOAN_FEE)
	return ""


## At the new season: loans that ran out end, the juniors come back (or, too
## old for the juniors, leave as free drivers).
static func return_loans(year: int) -> void:
	for d in GameState.drivers.values():
		if d.loan_from == &"":
			continue
		var c := GameState.contract_of(d.id)
		if c and c.end_year >= year:
			continue
		if c:
			GameState.contracts.erase(c)
		var t: TeamData = GameState.teams.get(d.team_id)
		if t:
			t.driver_ids.erase(d.id)
			t.reserve_driver_ids.erase(d.id)
		var home: TeamData = GameState.teams.get(d.loan_from)
		d.team_id = &""
		d.loan_from = &""
		if d.age(year) <= Youth.MAX_AGE and d.academy_team_id != &"":
			d.series_id = Youth.POOL
			if home and home.id == GameState.player_team_id:
				_message("%s is back from his loan", [d.full_name()],
					["His season at %s is over. He is back in our academy.", [t.name if t else "–"]], d)
		else:
			forget(d)
			d.series_id = &""


## AI academies at the new season: drivers grow, contracts end, unplaced
## drivers get a seat (F2 for the stronger ones).
static func ai_new_season(year: int, r: RandomNumberGenerator) -> void:
	for team in GameState.teams.values():
		if team.id == GameState.player_team_id:
			continue
		for d in drivers(team):
			_grow(team, d, r)
			if (d.academy_until > 0 and d.academy_until < year) or d.age(year) > INTAKE_MAX_AGE + 2:
				release(d)
		for d in drivers(team):
			if is_placed(d) or Youth.is_karting(d) or d.loan_from != &"" or d.age(year) < Youth.MIN_SEAT_AGE:
				continue
			var order := [Youth.F2, Youth.F3] if d.overall() >= 56 else [Youth.F3, Youth.F2]
			var done := false
			for series_id in order:
				for t in GameState.youth_teams.values():
					if t.series_id == series_id and seat_offer(team, d, t).reason == "":
						place(team, d, t)
						done = true
						break
				if done:
					break


# --- Reports ---------------------------------------------------------------------------

## After each junior round: one message with the results of our juniors and
## the wins of juniors on the watchlist.
static func round_report(team: TeamData) -> void:
	if not team:
		return
	var racing := drivers(team).filter(func(d): return Youth.series_key(d) != &"")
	var watched := []
	for id in GameState.shortlist:
		var w: DriverData = GameState.drivers.get(id)
		if w and Youth.is_youth(w) and w.academy_team_id != team.id and Youth.last_result(w) == 1:
			watched.append(w)
	if racing.is_empty() and watched.is_empty():
		return
	var msg := InboxMessage.new()
	msg.sender = "Academy head"
	msg.icon = "graduation-cap"
	msg.subject = "Junior races: round %d"
	msg.subject_args = [Youth.standings(Youth.F3).rounds]
	for d in racing:
		var key := Youth.series_key(d)
		var t := Youth.team_of(d)
		var where: String = "%s, %s" % [t.name, Youth.series_name(key)] if t else Youth.series_name(key)
		var last := Youth.last_result(d)
		if last > 0:
			msg.add_paragraph("%s (%s): P%d. Championship: P%d with %d points.",
				[d.full_name(), where, last, Youth.position(d), Youth.season_points(d)])
		elif last == 0:
			msg.add_paragraph("%s (%s): did not finish. Championship: P%d with %d points.",
				[d.full_name(), where, Youth.position(d), Youth.season_points(d)])
	for w in watched:
		msg.add_paragraph("Watchlist: %s won in %s.", [w.full_name(), Youth.series_name(Youth.series_key(w))])
	msg.link_screen = &"academy"
	msg.link_args = {}
	msg.link_label = "Open academy"
	GameState.add_message(msg)


static func _message(subject: String, subject_args: Array, paragraph: Array, d: DriverData) -> void:
	var msg := InboxMessage.new()
	msg.sender = "Academy head"
	msg.icon = "graduation-cap"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.subject = subject
	msg.subject_args = subject_args
	msg.add_paragraph(paragraph[0], paragraph[1])
	msg.link_screen = &"junior_profile"
	msg.link_args = {"driver_id": d.id}
	msg.link_label = "Open profile"
	GameState.add_message(msg)
