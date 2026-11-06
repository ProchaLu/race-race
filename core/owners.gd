## The owner and the investors (R6c, docs/finance_model.md 11). The owner of the
## player's team sets a goal for every season (a constructors' position) and a
## long-term goal (the constructors' title within five years). Trust rises and
## falls with the results and with the money. Trust decides whether the owner
## grants money when asked. Investors offer money for a share of the prize
## money and a goal; they leave when the goal is missed.
## v1 is lenient (R8b, docs/career_model.md 2): the owner dismisses only after a
## final warning or after a massive failure; job offers follow in Career.
class_name Owners
extends RefCounted

## Personality: how much trust a result moves, how generous the owner is with
## money, and how the season goal relates to the team's reputation rank.
const PERSONALITIES := {
	"patient": {"loss": 0.7, "grant": 1.0, "goal_shift": 1, "losses_hurt": false,
		"text": "Gives the team time. Forgives a missed season now and then."},
	"impatient": {"loss": 1.3, "grant": 0.9, "goal_shift": 0, "losses_hurt": false,
		"text": "Wants results now. Trust falls faster after every miss."},
	"ambitious": {"loss": 1.0, "grant": 1.1, "goal_shift": -1, "losses_hurt": false,
		"text": "Expects more than the reputation suggests. Sets the goals high."},
	"frugal": {"loss": 1.0, "grant": 0.7, "goal_shift": 1, "losses_hurt": true,
		"text": "Watches every dollar. A season in the red costs trust, and money is granted less often."},
}
const REQUEST_AMOUNTS := [10_000_000, 25_000_000, 50_000_000]
const LONG_GOAL_YEARS := 5
const INVESTOR_CHANCE := 0.1
const INVESTOR_MIN_REPUTATION := 50
const INVESTOR_OFFER_DAYS := 45
const INVESTOR_NAMES := ["Halden Capital", "Orsini Holdings", "Blackfen Partners", "Ostrava Growth Fund"]
const START_TRUST := 60
## Dismissal: trust at or below this after a final warning the season before …
const DISMISS_TRUST := 10
## … or a goal missed by this many places while trust is below MASSIVE_TRUST.
const MASSIVE_MISS := 6
const MASSIVE_TRUST := 30

## Owner of the player's team (AI teams have none). founder: the player founded
## the team; the owner is the backer and cannot dismiss the co-founder.
static func setup_world(owner_name: String = "Constance Aldridge", kind: String = "patient", founder: bool = false) -> void:
	var team: TeamData = GameState.player_team()
	team.owner = new_owner(team, owner_name, kind)
	team.owner.founder = founder


## A fresh owner for the team the player runs (start of the game or a new job).
static func new_owner(team: TeamData, owner_name: String, kind: String) -> Dictionary:
	team.owner = {"name": owner_name, "personality": kind, "trust": START_TRUST,
		"goal": 0, "long_goal": "title", "long_deadline": Calendar.year + LONG_GOAL_YEARS,
		"titles_at_start": 0, "titles": 0, "last_request": 0, "final_warning": false}
	team.owner.goal = season_goal(team)
	return team.owner


static func has_owner(team: TeamData) -> bool:
	return not team.owner.is_empty()


static func personality(team: TeamData) -> Dictionary:
	return PERSONALITIES[team.owner.personality]


static func trust_level(trust: int) -> String:
	if trust >= 75:
		return "Confident"
	if trust >= 50:
		return "Satisfied"
	if trust >= 30:
		return "Doubtful"
	if trust >= 15:
		return "Impatient"
	return "Final warning"


## Season goal: the team's reputation rank, shifted by the personality.
static func season_goal(team: TeamData) -> int:
	var s: SeriesData = GameState.series[team.series_id]
	var rank := 1
	for id in s.team_ids:
		var other: TeamData = GameState.teams.get(id)
		if other and other != team and other.reputation > team.reputation:
			rank += 1
	var shift: int = PERSONALITIES[team.owner.personality].goal_shift
	return clampi(rank + shift, 1, s.team_ids.size())


## Chance that the owner grants the amount right now (for the screen).
static func grant_chance(team: TeamData, amount: int) -> float:
	var factor: float = personality(team).grant
	return clampf(team.owner.trust / 100.0 * factor * (1.0 - amount / 100_000_000.0), 0.05, 0.9)


## "" when the owner can be asked now, otherwise the reason.
static func request_blocked(team: TeamData) -> String:
	if team.owner.last_request == Calendar.year:
		return "You already asked the owner this season."
	return ""


## Asks the owner for money. Returns true when granted.
static func request_money(team: TeamData, amount: int) -> bool:
	team.owner.last_request = Calendar.year
	var granted := randf() < grant_chance(team, amount)
	var msg := InboxMessage.new()
	msg.sender = "Owner"
	msg.icon = "briefcase"
	msg.link_screen = &"owner"
	msg.link_args = {}
	msg.link_label = "Open owner"
	if granted:
		Finance.receive(team, &"owner", amount)
		msg.subject = "The owner grants %s"
		msg.subject_args = [UIStyle.money(amount)]
		msg.add_paragraph("%s has been added to the budget. The owner expects results for it.", [UIStyle.money(amount)])
	else:
		team.owner.trust = maxi(team.owner.trust - 3, 0)
		msg.subject = "The owner declines the request"
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.add_paragraph("The owner has no interest in %s right now. Asking again costs trust.", [UIStyle.money(amount)])
	GameState.add_message(msg)
	return granted


## New season: the owner's goals for the year.
static func new_season(year: int) -> void:
	var team: TeamData = GameState.player_team()
	if not has_owner(team):
		return
	team.owner.goal = season_goal(team)
	var msg := InboxMessage.new()
	msg.sender = "Owner"
	msg.icon = "briefcase"
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.subject = "Goals for %d"
	msg.subject_args = [year]
	msg.add_paragraph("Season goal: finish P%d or better in the constructors' championship.", [team.owner.goal])
	msg.add_paragraph("Long-term goal: the constructors' title by %d.", [team.owner.long_deadline])
	msg.add_paragraph("Trust in you: %d (%s).", [team.owner.trust, TranslationServer.translate(trust_level(team.owner.trust))])
	msg.link_screen = &"owner"
	msg.link_args = {}
	msg.link_label = "Open owner"
	GameState.add_message(msg)


## End of the season: the verdict, trust, the investor and the long-term goal.
## table = constructors' standings, best first. Returns the verdict for the season review.
static func season_end(team: TeamData, table: Array, prize: int) -> Dictionary:
	if not has_owner(team):
		return {}
	var position := 0
	for i in table.size():
		if table[i][0] == team.id:
			position = i + 1
	var owner: Dictionary = team.owner
	var before: int = owner.trust
	var missed: int = position - owner.goal
	var change := 0
	if missed <= 0:
		change = 8
	elif missed <= 2:
		change = -4
	else:
		change = -10
	if change < 0:
		change = roundi(change * personality(team).loss)
	if personality(team).losses_hurt and Finance.net(team.id) < 0:
		change -= 5
	if position == 1:
		owner.titles += 1
	var long_met: Variant = null
	if owner.long_deadline <= Calendar.year:
		long_met = owner.titles > owner.titles_at_start
		change += 15 if long_met else -10
		owner.long_deadline = Calendar.year + LONG_GOAL_YEARS
		owner.titles_at_start = owner.titles
	owner.trust = clampi(before + change, 0, 100)
	var dismissed: bool = not owner.get("founder", false) and should_dismiss(owner.get("final_warning", false), owner.trust, missed)
	owner.final_warning = owner.trust <= DISMISS_TRUST
	var investor_left := false
	if not team.investor.is_empty():
		investor_left = _investor_season(team, position, prize)
	_message_verdict(team, position, missed <= 0, before, dismissed)
	return {"goal": owner.goal, "position": position, "met": missed <= 0, "trust_before": before,
		"trust": owner.trust, "long_met": long_met, "investor_left": investor_left, "dismissed": dismissed}


## v1 is lenient: a second bad season after the final warning, or a massive
## failure (goal missed by MASSIVE_MISS places) when trust is already low.
static func should_dismiss(warned_before: bool, trust: int, missed: int) -> bool:
	if warned_before and trust <= DISMISS_TRUST and missed > 0:
		return true
	return missed >= MASSIVE_MISS and trust < MASSIVE_TRUST


static func monthly_update(r: RandomNumberGenerator) -> void:
	var team: TeamData = GameState.player_team()
	if not has_owner(team):
		return
	if not team.investor_offer.is_empty() and team.investor_offer.expires_key < Sponsors.now_key():
		team.investor_offer = {}
	if not team.investor.is_empty() or not team.investor_offer.is_empty():
		return
	if team.reputation < INVESTOR_MIN_REPUTATION or r.randf() >= INVESTOR_CHANCE:
		return
	team.investor_offer = {"name": INVESTOR_NAMES[r.randi() % INVESTOR_NAMES.size()],
		"amount": snappedi((20 + r.randi() % 31) * 1_000_000.0 * team.reputation / 60.0, 1_000_000),
		"share": snappedf(0.1 + r.randf() * 0.1, 0.01), "goal": team.owner.goal,
		"years": r.randi_range(2, 3), "expires_key": Sponsors.now_key() + INVESTOR_OFFER_DAYS}
	var msg := InboxMessage.new()
	msg.sender = "Owner"
	msg.icon = "briefcase"
	msg.subject = "Investor interested: %s"
	msg.subject_args = [team.investor_offer.name]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.add_paragraph("%s offers %s for %d%% of our prize money, with the condition: finish P%d or better.",
		[team.investor_offer.name, UIStyle.money(team.investor_offer.amount),
		roundi(team.investor_offer.share * 100), team.investor_offer.goal])
	msg.link_screen = &"owner"
	msg.link_args = {}
	msg.link_label = "Open owner"
	GameState.add_message(msg)


static func accept_investor(team: TeamData) -> void:
	var offer := team.investor_offer
	if offer.is_empty():
		return
	Finance.receive(team, &"investor", offer.amount)
	team.investor = offer.duplicate()
	team.investor.erase("expires_key")
	team.investor_offer = {}


static func decline_investor(team: TeamData) -> void:
	team.investor_offer = {}


## Share of the prize money goes to the investor; a missed goal ends the deal.
## Returns true when the investor leaves.
static func _investor_season(team: TeamData, position: int, prize: int) -> bool:
	var share := roundi(prize * team.investor.share)
	Finance.pay(team, &"investor_share", share)
	team.investor.years -= 1
	var left := false
	if position > team.investor.goal:
		left = true
		team.owner.trust = maxi(team.owner.trust - 5, 0)
	elif team.investor.years <= 0:
		left = true
	if left:
		var msg := InboxMessage.new()
		msg.sender = "Owner"
		msg.icon = "briefcase"
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.subject = "%s leaves" % team.investor.name
		if position > team.investor.goal:
			msg.add_paragraph("%s withdraws: we finished P%d, the condition was P%d or better. Trust in you drops.",
				[team.investor.name, position, team.investor.goal])
		else:
			msg.add_paragraph("%s's contract ends after this season.", [team.investor.name])
		msg.link_screen = &"owner"
		msg.link_args = {}
		msg.link_label = "Open owner"
		GameState.add_message(msg)
		team.investor = {}
	return left


static func _message_verdict(team: TeamData, position: int, met: bool, before: int, dismissed: bool) -> void:
	var owner: Dictionary = team.owner
	var msg := InboxMessage.new()
	msg.sender = "Owner"
	msg.icon = "briefcase"
	msg.link_screen = &"owner"
	msg.link_args = {}
	msg.link_label = "Open owner"
	msg.subject = "Owner's verdict: goal %s" % ("met" if met else "missed")
	msg.add_paragraph("Season goal P%d, we finished P%d. Trust %d → %d (%s).",
		[owner.goal, position, before, owner.trust, TranslationServer.translate(trust_level(owner.trust))])
	if dismissed:
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.add_paragraph("The owner has lost all patience and dismisses you.")
	elif owner.trust <= DISMISS_TRUST:
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.add_paragraph("This is a final warning. One more season like this and the owner may end your time as team principal.")
	elif owner.trust <= 25:
		msg.priority = InboxMessage.Priority.IMPORTANT
		msg.add_paragraph("The owner is losing patience. Money requests will be refused more often.")
	GameState.add_message(msg)
