## Drives the passing of time (autoload "Season"): advancing single days,
## "Continue" to the next important event, and race days.
extends Node

## Safety limit for one press of Continue.
const MAX_DAYS_PER_CONTINUE := 60
## Chance that another team steps in before a new signing is official.
## A signing fee lowers it (up to -75 % at a fee of 30 % of the salary).
const HIJACK_CHANCE := 0.08
const NEW_MARKET_DRIVERS_PER_MONTH := 2
const NEW_MARKET_STAFF_PER_MONTH := 4

## Constructors' prize money by final position, champion first (design doc 13).
const PRIZE_MONEY_M := [140, 125, 112, 100, 90, 81, 73, 66, 60, 57, 55]

var _important_posted := false
var _rng := RandomNumberGenerator.new()
## The race weekend of today, while the player makes the decisions.
var weekend: RaceWeekend


func _ready() -> void:
	_rng.randomize()
	EventBus.inbox_message_added.connect(func(msg: InboxMessage):
		if msg.priority == InboxMessage.Priority.IMPORTANT:
			_important_posted = true)
	EventBus.contract_released.connect(_on_contract_released)
	EventBus.contract_signed.connect(_on_contract_signed)
	EventBus.season_started.connect(_start_new_season)


## Passive step: exactly one day (or the race, if today is race day).
func advance_one_day() -> void:
	_step()


## Active step: keeps advancing until something needs the player.
func continue_to_next_event() -> void:
	for i in MAX_DAYS_PER_CONTINUE:
		if _step():
			return


## One step of time. Returns true if something important happened.
## On race day time stops: the weekend waits for the team principal.
func _step() -> bool:
	_important_posted = false
	var today := round_today()
	if today >= 0:
		weekend_of_today()
		return true
	else:
		Calendar.advance_day()
		_daily_world_update()
		var new_round := round_today()
		if new_round >= 0:
			_announce_race(new_round)
	return _important_posted


# --- People and money --------------------------------------------------------

func _daily_world_update() -> void:
	_process_signings()
	_check_shortlist()
	TeamMood.daily_update()
	CarDevelopment.daily_update(_rng)
	if Calendar.date_of().day == 1:
		_pay_salaries()
		_refresh_market()
	if Calendar.day % 7 == 0:
		_ai_fill_vacancies()
	if Calendar.date_of().month == 9 and Calendar.date_of().day == 1:
		_own_contract_reminder()


## Agreed deals become official after a few days – unless a rival steps in.
func _process_signings() -> void:
	for pending in GameState.pending_signings.duplicate():
		if pending.sign_day > Calendar.day:
			continue
		GameState.pending_signings.erase(pending)
		var person := GameState.find_person(pending.person_id)
		var msg := InboxMessage.new()
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.icon = "handshake"
		msg.link_screen = &"driver_profile" if person is DriverData else &"staff_profile"
		msg.link_args = {"driver_id": person.id} if person is DriverData else {"staff_id": person.id}
		msg.link_label = "Open profile"
		var rival := _rival_team() if pending.kind == Negotiation.Kind.SIGN else null
		if rival and randf() < hijack_chance(pending.terms):
			ContractLogic.sign(person, rival, {"salary": int(pending.terms.salary * 1.15), "years": pending.terms.years})
			msg.sender = "Sporting director"
			msg.subject = "Transfer failed: %s joins %s instead"
			msg.subject_args = [person.full_name(), rival.name]
			msg.add_paragraph("Before %s could sign with us, %s made a better offer. %s has NOT joined our team and is now under contract with %s.",
				[person.full_name(), rival.name, person.first_name, rival.name])
			msg.add_paragraph("A higher signing fee makes it less likely that rivals step in before the signature.")
		else:
			var made_room := ContractLogic.sign(person, GameState.player_team(), pending.terms)
			_record_contract_promise(person, pending.terms)
			if pending.kind == Negotiation.Kind.SIGN and person.overall() >= 70:
				TeamMood.add_event(GameState.player_team_id, "New signing: %s", [person.full_name()], 3)
			msg.sender = "Sporting director"
			msg.subject = "Contract signed: %s"
			msg.subject_args = [person.full_name()]
			msg.add_paragraph("%s has signed the contract: %s per year until the end of %d.",
				[person.full_name(), UIStyle.money(pending.terms.salary), GameState.contract_of(person.id).end_year])
			if not made_room.is_empty():
				var left: PersonData = made_room.person
				if made_room.action == "reserve":
					msg.add_paragraph("To make room, %s has been moved to the reserve driver role.", [left.full_name()])
				else:
					msg.add_paragraph("To make room, %s has been released.", [left.full_name()])
		GameState.add_message(msg)


## A promise made in the contract talks becomes a real promise (design doc 3.6).
func _record_contract_promise(person: PersonData, terms: Dictionary) -> void:
	if not terms.get("promise", false):
		return
	var p := PromiseData.new()
	p.person_id = person.id
	p.description = "New parts at the same time as the No.1"
	p.made_on = "%s %d" % [Calendar.MONTHS[Calendar.date_of().month - 1], Calendar.year]
	GameState.promises.append(p)


## Promises with a deadline are judged when that round has been raced.
func _check_promises() -> void:
	for p in GameState.promises:
		if p.status != PromiseData.Status.OPEN or p.deadline_round == 0 or GameState.resolved_rounds < p.deadline_round:
			continue
		var person := GameState.find_person(p.person_id)
		if not person:
			continue
		# Only promise type with a deadline so far: "competitive car".
		var kept: bool = TeamMood.car_rank(GameState.player_team_id) <= 5
		p.status = PromiseData.Status.KEPT if kept else PromiseData.Status.BROKEN
		var msg := InboxMessage.new()
		msg.sender = "Sporting director"
		msg.icon = "handshake"
		msg.link_screen = &"driver_profile" if person is DriverData else &"staff_profile"
		msg.link_args = {"driver_id": person.id} if person is DriverData else {"staff_id": person.id}
		msg.link_label = "Open profile"
		if kept:
			TeamMood.change_morale(person, "Promise kept", 8)
			msg.subject = "Promise kept: %s"
			msg.add_paragraph("%s is pleased: you kept your promise (%s).", [person.full_name(), Loc.t(p.description)])
		else:
			TeamMood.change_morale(person, "Promise broken", p.morale_penalty)
			TeamMood.add_event(GameState.player_team_id, "Broken promise to %s", [person.full_name()], -6)
			msg.priority = InboxMessage.Priority.IMPORTANT
			msg.subject = "Promise broken: %s"
			msg.add_paragraph("You did not keep your promise to %s (%s). Morale and trust have dropped.", [person.full_name(), Loc.t(p.description)])
		msg.subject_args = [person.full_name()]
		GameState.add_message(msg)


## 1 September: whose contract in our team ends after this season.
func _own_contract_reminder() -> void:
	var names := []
	var any_driver := false
	for c in GameState.contracts:
		if c.team_id != GameState.player_team_id or c.end_year != Calendar.year:
			continue
		var person := GameState.find_person(c.person_id)
		if person:
			names.append(person.full_name())
			any_driver = any_driver or person is DriverData
	if names.is_empty():
		return
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Contracts ending this season: %d"
	msg.subject_args = [names.size()]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "handshake"
	msg.add_paragraph("These contracts end on 31 December: %s.", [", ".join(names)])
	msg.add_paragraph("Extend them in the profile (Contract talks) or find replacements on the transfer market. Anyone without a new contract leaves on 1 January.")
	msg.link_screen = &"drivers" if any_driver else &"staff"
	msg.link_args = {}
	msg.link_label = "Open drivers" if any_driver else "Open staff"
	GameState.add_message(msg)


# --- Shortlist notices -------------------------------------------------------

func _check_shortlist() -> void:
	for id in GameState.shortlist:
		var person := GameState.find_person(id)
		var c := GameState.contract_of(id)
		if person and c and c.team_id != GameState.player_team_id and c.end_year == Calendar.year \
				and Calendar.date_of().month >= 7:
			_shortlist_note(person, "expiring", "Contract running out: %s", [person.full_name()],
				"%s's contract ends after this season. A good moment to start talks.", [person.full_name()])


func _on_contract_released(person_id: StringName) -> void:
	var person := GameState.find_person(person_id)
	if person and GameState.shortlist.has(person_id):
		_shortlist_note(person, "free_%d" % Calendar.day, "Now a free agent: %s", [person.full_name()],
			"%s from your shortlist is now a free agent and can be signed without a fee.", [person.full_name()])


func _on_contract_signed(person_id: StringName, team_id: StringName) -> void:
	var person := GameState.find_person(person_id)
	if person and team_id != GameState.player_team_id and GameState.shortlist.has(person_id):
		var team: TeamData = GameState.teams[team_id]
		_shortlist_note(person, "signed_%s" % team_id, "Shortlist: %s joins %s", [person.full_name(), team.name],
			"%s from your shortlist has signed for %s.", [person.full_name(), team.name])


## Sends one shortlist message per person and kind.
func _shortlist_note(person: PersonData, kind: String, subject: String, subject_args: Array,
		body: String, body_args: Array) -> void:
	var key := "%s:%s" % [person.id, kind]
	if GameState.shortlist_notes.has(key):
		return
	GameState.shortlist_notes[key] = true
	var msg := InboxMessage.new()
	msg.sender = "Chief scout"
	msg.icon = "binoculars"
	msg.subject = subject
	msg.subject_args = subject_args
	msg.add_paragraph(body, body_args)
	msg.link_screen = &"driver_profile" if person is DriverData else &"staff_profile"
	msg.link_args = {"driver_id": person.id} if person is DriverData else {"staff_id": person.id}
	msg.link_label = "Open profile"
	GameState.add_message(msg)


## Risk that a rival steps in before an agreed new signing becomes official.
func hijack_chance(terms: Dictionary) -> float:
	var salary: float = maxf(terms.get("salary", 1), 1.0)
	var protection := minf(terms.get("signing_fee", 0) / (salary * 0.3), 1.0) * 0.75
	return HIJACK_CHANCE * (1.0 - protection)


func _rival_team() -> TeamData:
	var others: Array = []
	for team in GameState.teams.values():
		if team.id != GameState.player_team_id:
			others.append(team)
	return others[randi() % others.size()] if not others.is_empty() else null


func _pay_salaries() -> void:
	for team in GameState.teams.values():
		var payroll := ContractLogic.payroll_per_month(team.id)
		team.budget -= payroll
		if team.id == GameState.player_team_id:
			var msg := InboxMessage.new()
			msg.sender = "Finance department"
			msg.subject = "Salaries paid: %s"
			msg.subject_args = [UIStyle.money(payroll)]
			msg.icon = "wallet"
			msg.add_paragraph("Monthly salaries for drivers and staff have been paid. Budget now: %s.",
				[UIStyle.money(team.budget)])
			GameState.add_message(msg)


## New young drivers and staff appear; old free agents retire.
func _refresh_market() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	for i in NEW_MARKET_DRIVERS_PER_MONTH:
		var tier := PersonGenerator.DriverTier.F3 if r.randf() < 0.6 else PersonGenerator.DriverTier.F2
		var d := PersonGenerator.driver(r, tier)
		GameState.add_driver(d)
		GameState.knowledge[d.id] = r.randi_range(10, 30) if tier == PersonGenerator.DriverTier.F3 else r.randi_range(30, 60)
	for i in NEW_MARKET_STAFF_PER_MONTH:
		var role: StaffData.Role = StaffRoles.TEAM_POSITIONS[r.randi() % StaffRoles.TEAM_POSITIONS.size()]
		var s := PersonGenerator.staff(r, role, r.randi_range(40, 80))
		GameState.add_staff(s)
		GameState.knowledge[s.id] = r.randi_range(20, 60)
	for d in GameState.free_drivers():
		if d.age(Calendar.year) > 37 and r.randf() < 0.3 and not GameState.shortlist.has(d.id):
			d.retired = true


## AI teams fill empty race seats and staff positions with the best free agent.
func _ai_fill_vacancies() -> void:
	for team in GameState.teams.values():
		if team.id == GameState.player_team_id:
			continue
		while team.driver_ids.size() < ContractLogic.RACE_SEATS:
			var best := _best_free_driver()
			if not best:
				break
			ContractLogic.sign(best, team, {"salary": ContractLogic.market_value(best), "years": 2,
				"role": ContractData.DriverRole.EQUAL})
		_fill_staff_vacancies(team, 2)


## Hires the best free person for every empty staff position.
## Returns "Name (role)" texts.
func _fill_staff_vacancies(team: TeamData, years: int) -> Array:
	var hired := []
	var counts := {}
	for s in GameState.staff_of_team(team.id):
		counts[s.role] = counts.get(s.role, 0) + 1
	for role in StaffRoles.TEAM_POSITIONS:
		if counts.get(role, 0) > 0:
			counts[role] -= 1
			continue
		var hire := _best_free_staff(role)
		if hire:
			ContractLogic.sign(hire, team, {"salary": ContractLogic.market_value(hire), "years": years})
			hired.append("%s (%s)" % [hire.full_name(), tr(StaffRoles.name_of(role))])
	return hired


## Race engineers without a driver take the drivers without an engineer.
func _assign_race_engineers(team: TeamData) -> void:
	var free_engineers := GameState.staff_of_team(team.id).filter(func(s: StaffData):
		return s.role == StaffData.Role.RACE_ENGINEER and not team.driver_ids.has(s.assigned_driver_id))
	for driver in GameState.drivers_of_team(team.id):
		if free_engineers.is_empty():
			return
		if not GameState.race_engineer_of(driver.id):
			free_engineers.pop_front().assigned_driver_id = driver.id


func _best_free_driver() -> DriverData:
	var best: DriverData = null
	for d in GameState.free_drivers():
		if GameState.pending_signing_of(d.id).is_empty() and (not best or d.overall() > best.overall()):
			best = d
	return best


func _best_free_staff(role: StaffData.Role) -> StaffData:
	var best: StaffData = null
	for s in GameState.free_staff():
		if s.role == role and GameState.pending_signing_of(s.id).is_empty() and (not best or s.overall() > best.overall()):
			best = s
	return best


## Index of the round raced today that is not resolved yet, or -1.
func round_today() -> int:
	var s := _player_series()
	var next := GameState.resolved_rounds
	if next < s.race_days.size() and s.race_days[next] == Calendar.day:
		return next
	return -1


func _announce_race(round_index: int) -> void:
	var s := _player_series()
	var track: TrackData = GameState.tracks[s.calendar[round_index]]
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Race weekend: %s"
	msg.subject_args = [track.name]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "trophy"
	msg.add_paragraph("The team has arrived for round %d of %d.", [round_index + 1, s.calendar.size()])
	msg.add_paragraph("Press Continue to open the race weekend and make your decisions.")
	msg.link_screen = &"weekend"
	msg.link_args = {}
	msg.link_label = "Open race weekend"
	GameState.add_message(msg)


## The weekend raced today (created on first access), or null.
func weekend_of_today() -> RaceWeekend:
	var today := round_today()
	if today < 0:
		return null
	if not weekend or weekend.round_index != today:
		_emergency_signings()
		weekend = RaceWeekend.create(_player_series(), today)
	return weekend


## Race day without two race drivers: the reserve driver moves up, or the
## sporting director signs the best free driver for one year.
func _emergency_signings() -> void:
	_ai_fill_vacancies()
	var team := GameState.player_team()
	for promoted in _promote_reserves():
		_seat_message("%s moves up from reserve driver to a race seat for this race weekend.", [promoted])
	while team.driver_ids.size() < ContractLogic.RACE_SEATS:
		var best := _best_free_driver()
		if not best:
			return
		var salary := ContractLogic.market_value(best)
		ContractLogic.sign(best, team, {"salary": salary, "years": 1, "role": ContractData.DriverRole.EQUAL})
		_seat_message("We had only %d race driver(s). The sporting director signed %s for one year (%s per year).",
			[team.driver_ids.size() - 1, best.full_name(), UIStyle.money(salary)])
	var hired := _fill_staff_vacancies(team, 1)
	if not hired.is_empty():
		_seat_message("Empty positions in the team were filled by the sporting director for one year: %s.", [", ".join(hired)])
	_assign_race_engineers(team)


func _seat_message(text: String, args: Array) -> void:
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Race seat filled"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "user"
	msg.add_paragraph(text, args)
	GameState.add_message(msg)


## True while today's race weekend has not been raced yet.
func weekend_pending() -> bool:
	return round_today() >= 0


## Finishes the race of today's weekend (with whatever the player decided;
## the staff takes any decision still open) and does the bookkeeping.
## Returns the summary.
func race_weekend() -> Dictionary:
	var w := weekend_of_today()
	var summary := w.run_race()
	_after_race(w.round_index, summary)
	weekend = null
	return summary


func _after_race(round_index: int, summary: Dictionary) -> void:
	var s := _player_series()
	GameState.resolved_rounds += 1
	EventBus.round_completed.emit(round_index)
	_check_promises()

	var track: TrackData = GameState.tracks[s.calendar[round_index]]
	var msg := InboxMessage.new()
	msg.sender = "Race engineering"
	msg.subject = "Race result: %s"
	msg.subject_args = [track.name]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "trophy"
	var winner: DriverData = GameState.drivers[summary.entries[0].driver_id]
	msg.add_paragraph("%s won the race.", [winner.full_name()])
	for driver in GameState.drivers_of_team(GameState.player_team_id):
		var entry := RaceWeekend.entry_of(summary, driver.id)
		if entry.is_empty():
			continue
		if entry.finish > 0:
			msg.add_paragraph("%s started P%d and finished P%d (%d pts).", [driver.full_name(), entry.grid, entry.finish, entry.points])
		else:
			msg.add_paragraph("%s retired on lap %d: %s.", [driver.full_name(), entry.retire_lap, tr(entry.retire_reason)])
	var sc: int = summary.phases.filter(func(p): return p.kind == "SC").size()
	if sc > 0:
		msg.add_paragraph("Safety car periods: %d.", [sc])
	var standings := SeasonRecords.team_standings(s)
	for i in standings.size():
		if standings[i][0] == GameState.player_team_id:
			msg.add_paragraph("Constructors' championship: P%d with %d points.", [i + 1, standings[i][1]])
	msg.link_screen = &"race_result"
	msg.link_args = {"round": round_index + 1}
	msg.link_label = "Open race result"
	# Read on the result screen right away; the message stays as a record.
	msg.priority = InboxMessage.Priority.INFO
	GameState.add_message(msg)
	if GameState.resolved_rounds >= s.calendar.size():
		_season_finale()


# --- End of the season -------------------------------------------------------

## After the final round: prize money for every team and the season review.
func _season_finale() -> void:
	var s := _player_series()
	var team_table := SeasonRecords.team_standings(s)
	var prize := {}
	for i in team_table.size():
		var team: TeamData = GameState.teams[team_table[i][0]]
		var amount: int = PRIZE_MONEY_M[mini(i, PRIZE_MONEY_M.size() - 1)] * 1_000_000
		team.budget += amount
		prize[team.id] = amount
	var review := _season_review(s, team_table, prize)
	GameState.season_history.append(review)
	EventBus.budget_changed.emit(GameState.player_team_id, GameState.player_team().budget)

	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Season %d finished: P%d in the constructors' championship"
	msg.subject_args = [review.year, review.team_position]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "trophy"
	var champion: DriverData = GameState.drivers.get(review.champion_driver)
	if champion:
		msg.add_paragraph("%s is the drivers' champion, %s won the constructors' title.",
			[champion.full_name(), GameState.teams[review.champion_team].name])
	msg.add_paragraph("We finished P%d with %d points. Prize money received: %s.",
		[review.team_position, review.team_points, UIStyle.money(review.prize)])
	msg.add_paragraph("The new season starts on 1 January. Contracts that end this year expire then.")
	msg.link_screen = &"season_review"
	msg.link_args = {}
	msg.link_label = "Open season review"
	GameState.add_message(msg)


## Everything the season review shows, kept after the reset.
func _season_review(s: SeriesData, team_table: Array, prize: Dictionary) -> Dictionary:
	var team_id := GameState.player_team_id
	var position := 0
	for i in team_table.size():
		if team_table[i][0] == team_id:
			position = i + 1
	var drivers := SeasonRecords.driver_standings()
	var car_rank := TeamMood.car_rank(team_id)
	var own := []
	for i in drivers.size():
		var d: DriverData = GameState.drivers.get(drivers[i][0])
		if d and d.team_id == team_id:
			var st: DriverSeasonStats = GameState.season_stats[d.id]
			var best := 0
			for res in st.results:
				if res.finish > 0 and (best == 0 or res.finish < best):
					best = res.finish
			own.append({"driver_id": d.id, "position": i + 1, "points": st.points, "wins": st.wins,
				"podiums": st.podiums, "poles": st.poles, "retirements": st.retirements,
				"quali_ahead": st.quali_ahead, "race_ahead": st.race_ahead, "rounds": st.head_to_head_rounds,
				"races": st.races(), "avg_finish": st.average_finish(), "best": best,
				"expected": car_rank * 2 - (1 if own.is_empty() else 0), "overall": d.overall(),
				"morale": d.morale, "age": d.age(Calendar.year)})
	var stops := []
	var moments := []
	for r in GameState.race_results:
		for e in r.entries:
			if e.team_id != team_id:
				continue
			for stop in e.stops:
				stops.append(stop.stationary)
			if e.finish == 1:
				moments.append([r.round, "Win at %s – %s", [GameState.tracks[r.track_id].name, GameState.drivers[e.driver_id].full_name()]])
			elif e.finish >= 2 and e.finish <= 3:
				moments.append([r.round, "Podium at %s – %s P%d", [GameState.tracks[r.track_id].name, GameState.drivers[e.driver_id].full_name(), e.finish]])
			elif e.grid == 1:
				moments.append([r.round, "Pole position at %s – %s", [GameState.tracks[r.track_id].name, GameState.drivers[e.driver_id].full_name()]])
	var avg_stop := 0.0
	for v in stops:
		avg_stop += v
	return {
		"car_rank": car_rank,
		"last_position": GameState.season_history.back().team_position if not GameState.season_history.is_empty() else 0,
		"progress": _team_progress(s, team_id),
		"team_stats": _team_stats(team_id),
		"car_spent": GameState.car_spending.get(team_id, 0),
		"new_parts": _new_parts(team_id),
		"year": Calendar.year,
		"team_position": position,
		"team_points": GameState.team_points.get(team_id, 0),
		"prize": prize.get(team_id, 0),
		"prize_next_lower": PRIZE_MONEY_M[mini(position, PRIZE_MONEY_M.size() - 1)] * 1_000_000 if position < team_table.size() else 0,
		"team_table": team_table.duplicate(true),
		"champion_driver": drivers[0][0] if not drivers.is_empty() else &"",
		"champion_team": team_table[0][0] if not team_table.is_empty() else &"",
		"drivers": own,
		"average_stop": avg_stop / stops.size() if not stops.is_empty() else 0.0,
		"moments": moments,
		"rounds": s.calendar.size(),
	}


## The team's points and constructors' position after every round:
## [[points, position], ...]. Uses the drivers' current teams.
func _team_progress(s: SeriesData, team_id: StringName) -> Array:
	var points := {}
	for id in s.team_ids:
		points[id] = 0
	var out := []
	for round_number in range(1, s.calendar.size() + 1):
		for id in GameState.season_stats:
			var d: DriverData = GameState.drivers.get(id)
			if not d or not points.has(d.team_id):
				continue
			for res in GameState.season_stats[id].results:
				if res.round == round_number and res.finish > 0:
					points[d.team_id] += SeasonRecords.points_for(s, res.finish)
		var mine: int = points[team_id]
		var position := 1
		for id in points:
			if points[id] > mine:
				position += 1
		out.append([mine, position])
	return out


## Part versions developed this season (start versions do not count).
func _new_parts(team_id: StringName) -> int:
	var n := 0
	var car: CarData = GameState.teams[team_id].car
	for id in car.part_history:
		n += car.part_history[id].size() - 1
	return n


## Pit stops, retirements and decisions over the full race weekends.
func _team_stats(team_id: StringName) -> Dictionary:
	var stats := {"stops": 0, "best_stop": INF, "pit_issues": 0, "technical_dnf": 0, "crash_dnf": 0,
		"moments": 0, "weekends": 0, "overtakes": 0, "mistakes": 0}
	for r in GameState.race_results:
		stats.weekends += 1
		stats.moments += r.get("moments", 0)
		for e in r.entries:
			if e.team_id != team_id:
				continue
			stats.overtakes += e.overtakes
			stats.mistakes += e.mistakes
			for stop in e.stops:
				stats.stops += 1
				stats.best_stop = minf(stats.best_stop, stop.stationary)
				if stop.issue != "" and stop.issue != "None":
					stats.pit_issues += 1
			if e.finish == 0:
				if e.retire_reason in ["Crash", "Collision damage", "Suspension damage"]:
					stats.crash_dnf += 1
				else:
					stats.technical_dnf += 1
	return stats


## 1 January: everybody develops over the winter, contracts end, old
## people retire, statistics start from zero, empty race seats are filled
## from the reserve driver and the AI teams fill their vacancies.
func _start_new_season(year: int) -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	var winter := Development.winter(year, r)
	GameState.season_stats.clear()
	GameState.team_points.clear()
	GameState.race_results.clear()
	GameState.car_spending.clear()
	# Development projects of the old car end with the season (R3d: next year's car).
	GameState.car_projects.clear()
	GameState.resolved_rounds = 0
	weekend = null

	var gone := []
	for c in GameState.contracts.duplicate():
		if c.end_year >= year:
			continue
		var person := GameState.find_person(c.person_id)
		if not person:
			GameState.contracts.erase(c)
			continue
		if c.team_id == GameState.player_team_id:
			gone.append(person.full_name())
		_expire(person)

	var retired := Development.retirements(year, r)
	var promoted := _promote_reserves()
	_ai_fill_vacancies()
	for team in GameState.teams.values():
		for driver in GameState.drivers_of_team(team.id):
			SeasonRecords.stats_of(driver.id)

	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "Season %d begins"
	msg.subject_args = [year]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "calendar"
	var s := _player_series()
	msg.add_paragraph("The first race is on %s. All statistics and standings start from zero.",
		[Calendar.format_date(s.race_days[0])])
	if not gone.is_empty():
		msg.add_paragraph("Contracts ended: %s. They are now free agents.", [", ".join(gone)])
	for p in promoted:
		msg.add_paragraph("%s moves up from reserve driver to a race seat.", [p])
	var seats := GameState.player_team().driver_ids.size()
	if seats < ContractLogic.RACE_SEATS:
		msg.add_paragraph("Warning: we only have %d race driver(s). Sign a driver on the transfer market before the first race – otherwise the sporting director signs the best free driver on race day.", [seats])
	var changes := []
	for c in winter.drivers + winter.staff:
		if c.after != c.before:
			changes.append("%s %d → %d" % [c.name, c.before, c.after])
	if not changes.is_empty():
		msg.add_paragraph("Over the winter (overall rating): %s.", [", ".join(changes)])
	var car: Array = winter.cars.get(GameState.player_team_id, [])
	if not car.is_empty():
		msg.add_paragraph("Our new car: average rating %d → %d.", [roundi(car[0]), roundi(car[1])])
	if not retired.is_empty():
		msg.add_paragraph("Retired: %s.", [", ".join(retired)])
	msg.link_screen = &"calendar"
	msg.link_args = {}
	msg.link_label = "Open calendar"
	GameState.add_message(msg)
	# Everything the end-of-season overlay shows about the winter.
	if not GameState.season_history.is_empty():
		var review: Dictionary = GameState.season_history.back()
		winter["retired"] = retired
		winter["ended"] = gone
		winter["promoted"] = promoted
		winter["year"] = year
		review["winter"] = winter
		GameState.pending_summary = review.year


## A contract ran out: the person becomes a free agent, no severance.
func _expire(person: PersonData) -> void:
	var c := GameState.contract_of(person.id)
	if c:
		GameState.contracts.erase(c)
	var team: TeamData = GameState.teams.get(person.team_id)
	if team:
		team.driver_ids.erase(person.id)
		team.reserve_driver_ids.erase(person.id)
		team.staff_ids.erase(person.id)
	person.team_id = &""
	if person is StaffData:
		(person as StaffData).assigned_driver_id = &""
	EventBus.contract_released.emit(person.id)


## Empty race seats are taken by the team's reserve driver. Returns the
## names of the player's promoted drivers.
func _promote_reserves() -> Array:
	var names := []
	for team in GameState.teams.values():
		while team.driver_ids.size() < ContractLogic.RACE_SEATS and not team.reserve_driver_ids.is_empty():
			var id: StringName = team.reserve_driver_ids.pop_front()
			team.driver_ids.append(id)
			var c := GameState.contract_of(id)
			if c:
				c.role = ContractData.DriverRole.EQUAL
			if team.id == GameState.player_team_id:
				names.append(GameState.drivers[id].full_name())
	return names


func _player_series() -> SeriesData:
	return GameState.series[GameState.player_team().series_id]
