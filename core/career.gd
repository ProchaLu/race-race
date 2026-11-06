## The team principal's career (R8b, docs/career_model.md): the principal's
## reputation, dismissal by the owner, job offers from other teams and the
## move to a new team. The state lives in GameState.career:
## {"boss_reputation": int, "dismissed": bool, "offers": [offer, ...],
##  "history": [{"team_id", "from_year", "to_year", "reason"}]}
## An offer: {"team_id", "owner_name", "personality", "goal", "reason": "dismissal"|"interest"}
class_name Career
extends RefCounted

const START_REPUTATION := 50
## A dismissal costs the principal reputation before the offers are made.
const DISMISSAL_PENALTY := 10
## A team wants a principal whose reputation is at most this far below its own.
const REPUTATION_GAP := 15
const MAX_OFFERS := 3
## Offers without a dismissal: only good principals, only from better teams.
const INTEREST_MIN_REPUTATION := 55
const INTEREST_CHANCE := 0.5
const MAX_INTEREST_OFFERS := 2
const OWNER_FIRST := ["Margot", "Henrik", "Ilse", "Victor", "Ramona", "Aurelio", "Ines", "Torben", "Celeste", "Dario"]
const OWNER_LAST := ["Vance", "Lindqvist", "Okafor", "Brenner", "Castellan", "Moreau", "Kask", "Delacroix", "Ashby", "Ferrante"]


static func setup_world() -> void:
	GameState.career = {"boss_reputation": START_REPUTATION, "dismissed": false, "offers": [],
		"history": [{"team_id": GameState.player_team_id, "from_year": Calendar.year, "to_year": 0, "reason": "start"}]}


static func reputation() -> int:
	return GameState.career.get("boss_reputation", START_REPUTATION)


static func change_reputation(delta: int) -> void:
	GameState.career.boss_reputation = clampi(reputation() + delta, 0, 100)


static func offers() -> Array:
	return GameState.career.get("offers", [])


static func is_dismissed() -> bool:
	return GameState.career.get("dismissed", false)


## True while the dismissed principal has not chosen a new team: time waits.
static func job_pending() -> bool:
	return is_dismissed()


## The team's expected constructors' position from its reputation rank (no owner shift).
static func expected_position(team: TeamData) -> int:
	var s: SeriesData = GameState.series[team.series_id]
	var rank := 1
	for id in s.team_ids:
		var other: TeamData = GameState.teams.get(id)
		if other and other != team and other.reputation > team.reputation:
			rank += 1
	return rank


## Lowest principal reputation the team accepts.
static func required_reputation(team: TeamData) -> int:
	return maxi(team.reputation - REPUTATION_GAP, 0)


## End of the season, after the owner's verdict. Dismissal and the offers.
## table = constructors' standings, best first. Returns the offers made.
static func season_end(table: Array, dismissed: bool, r: RandomNumberGenerator) -> Array:
	GameState.career.offers = []
	var own: TeamData = GameState.player_team()
	if dismissed:
		GameState.career.dismissed = true
		change_reputation(-DISMISSAL_PENALTY)
	var made := []
	var searching := []
	for i in table.size():
		var team: TeamData = GameState.teams.get(table[i][0])
		if not team or team == own:
			continue
		if dismissed:
			# Teams that missed their own goal look for a new principal.
			if i + 1 > expected_position(team) and reputation() >= required_reputation(team):
				searching.append(team)
		elif reputation() >= INTEREST_MIN_REPUTATION and team.reputation > own.reputation \
				and reputation() >= required_reputation(team) and r.randf() < INTEREST_CHANCE:
			searching.append(team)
	searching.sort_custom(func(a, b): return a.reputation > b.reputation)
	var limit := MAX_OFFERS if dismissed else MAX_INTEREST_OFFERS
	for team in searching.slice(0, limit):
		made.append(_offer(team, "dismissal" if dismissed else "interest", r))
	if dismissed and made.is_empty():
		# Nobody is left without a job: the weakest team always takes a chance.
		var weakest: TeamData = null
		for id in GameState.series[own.series_id].team_ids:
			var team: TeamData = GameState.teams.get(id)
			if team and team != own and (weakest == null or team.reputation < weakest.reputation):
				weakest = team
		made.append(_offer(weakest, "dismissal", r))
	GameState.career.offers = made
	_message_offers(made, dismissed)
	return made


static func _offer(team: TeamData, reason: String, r: RandomNumberGenerator) -> Dictionary:
	var personality: String = Owners.PERSONALITIES.keys()[r.randi() % Owners.PERSONALITIES.size()]
	var s: SeriesData = GameState.series[team.series_id]
	var goal := clampi(expected_position(team) + Owners.PERSONALITIES[personality].goal_shift, 1, s.team_ids.size())
	return {"team_id": team.id, "personality": personality, "goal": goal, "reason": reason,
		"owner_name": "%s %s" % [OWNER_FIRST[r.randi() % OWNER_FIRST.size()], OWNER_LAST[r.randi() % OWNER_LAST.size()]]}


## New season: offers without a dismissal expire.
static func new_season() -> void:
	if not is_dismissed() and not offers().is_empty():
		GameState.career.offers = []


## Turns an offer down. A dismissed principal cannot turn down the last one.
static func decline(offer: Dictionary) -> void:
	if is_dismissed() and offers().size() <= 1:
		return
	offers().erase(offer)


## Takes the job: the player becomes principal of the offer's team.
static func accept(offer: Dictionary) -> void:
	var old: TeamData = GameState.player_team()
	var team: TeamData = GameState.teams.get(offer.team_id)
	if not team or team == old:
		return
	var reason := "dismissed" if is_dismissed() else "moved"
	for entry in GameState.career.history:
		if entry.team_id == old.id and entry.to_year == 0:
			entry.to_year = Calendar.year
			entry.reason = reason
	GameState.career.history.append({"team_id": team.id, "from_year": Calendar.year, "to_year": 0, "reason": offer.reason})
	# The old team is run by the AI from now on: AI teams have no owner.
	old.owner = {}
	old.investor_offer = {}
	team.owner = Owners.new_owner(team, offer.owner_name, offer.personality)
	team.owner.goal = offer.goal
	team.investor_offer = {}
	# Everything the principal was doing for the old team ends.
	GameState.negotiations.clear()
	GameState.pending_signings.clear()
	GameState.promises.clear()
	GameState.scout_assignments.clear()
	GameState.delegate_car_development = true
	GameState.delegate_engine_development = true
	GameState.player_team_id = team.id
	GameState.career.dismissed = false
	GameState.career.offers = []
	_message_welcome(team, old, reason)
	EventBus.budget_changed.emit(team.id, team.budget)


static func _message_offers(made: Array, dismissed: bool) -> void:
	if made.is_empty():
		return
	var msg := InboxMessage.new()
	msg.sender = "Owner" if dismissed else "Career"
	msg.icon = "briefcase"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.link_screen = &"career"
	msg.link_args = {}
	msg.link_label = "Open career"
	if dismissed:
		msg.subject = "You have been dismissed"
		msg.add_paragraph("The owner has ended your time as team principal of %s.", [GameState.player_team().name])
		msg.add_paragraph("Your reputation as team principal drops to %d. Choose one of the job offers to continue – time stands still until you do.", [reputation()])
	else:
		msg.subject = "Job offers for you"
		msg.add_paragraph("Other teams have noticed your work. You can accept an offer until 31 December or stay with your team.")
	for offer in made:
		var team: TeamData = GameState.teams[offer.team_id]
		msg.add_paragraph("%s: reputation %d, owner's goal P%d.", [team.name, team.reputation, offer.goal])
	GameState.add_message(msg)


static func _message_welcome(team: TeamData, old: TeamData, reason: String) -> void:
	var msg := InboxMessage.new()
	msg.sender = "Owner"
	msg.icon = "briefcase"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.subject = "Welcome to %s"
	msg.subject_args = [team.name]
	if reason == "moved":
		msg.add_paragraph("You leave %s and take over %s.", [old.name, team.name])
	else:
		msg.add_paragraph("After your dismissal at %s you take over %s.", [old.name, team.name])
	msg.add_paragraph("I am %s. Season goal: finish P%d or better in the constructors' championship.", [team.owner.name, team.owner.goal])
	msg.add_paragraph("Open negotiations, promises and scouting assignments from your old team have ended. Car and engine development are delegated to the staff until you take them over.")
	msg.link_screen = &"owner"
	msg.link_args = {}
	msg.link_label = "Open owner"
	GameState.add_message(msg)
