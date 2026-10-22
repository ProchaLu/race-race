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

var _important_posted := false


func _ready() -> void:
	EventBus.inbox_message_added.connect(func(msg: InboxMessage):
		if msg.priority == InboxMessage.Priority.IMPORTANT:
			_important_posted = true)
	EventBus.contract_released.connect(_on_contract_released)
	EventBus.contract_signed.connect(_on_contract_signed)


## Passive step: exactly one day (or the race, if today is race day).
func advance_one_day() -> void:
	_step()


## Active step: keeps advancing until something needs the player.
func continue_to_next_event() -> void:
	for i in MAX_DAYS_PER_CONTINUE:
		if _step():
			return


## One step of time. Returns true if something important happened.
func _step() -> bool:
	_important_posted = false
	var today := round_today()
	if today >= 0:
		_run_race(today)
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
	if Calendar.date_of().day == 1:
		_pay_salaries()
		_refresh_market()
	if Calendar.day % 7 == 0:
		_ai_fill_vacancies()


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
			GameState.drivers.erase(d.id)


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
		var counts := {}
		for s in GameState.staff_of_team(team.id):
			counts[s.role] = counts.get(s.role, 0) + 1
		for role in StaffRoles.TEAM_POSITIONS:
			if counts.get(role, 0) > 0:
				counts[role] -= 1
				continue
			var hire := _best_free_staff(role)
			if hire:
				ContractLogic.sign(hire, team, {"salary": ContractLogic.market_value(hire), "years": 2})


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
	msg.add_paragraph("Press Continue to run the race.")
	GameState.add_message(msg)


func _run_race(round_index: int) -> void:
	var s := _player_series()
	var order := QuickRace.resolve_round(s, round_index)
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
	var winner: DriverData = GameState.drivers[order[0]]
	msg.add_paragraph("%s won the race.", [winner.full_name()])
	var first_own: StringName = &""
	for driver in GameState.drivers_of_team(GameState.player_team_id):
		var result: Dictionary = GameState.season_stats[driver.id].results.back()
		if result.finish > 0:
			msg.add_paragraph("%s finished P%d.", [driver.full_name(), result.finish])
		else:
			msg.add_paragraph("%s retired.", [driver.full_name()])
		if first_own == &"":
			first_own = driver.id
	msg.link_screen = &"driver_profile"
	msg.link_args = {"driver_id": first_own}
	msg.link_label = "Open driver profile"
	GameState.add_message(msg)


func _player_series() -> SeriesData:
	return GameState.series[GameState.player_team().series_id]
