## Sponsors (R6b, docs/finance_model.md 12): the fictional companies, their
## offers and contracts. Offers come every month; the hospitality building and
## the commercial manager decide how many a team can have open and how well
## they pay. Contracts pay after every race, a bonus at season end when the
## constructors' position is good enough, and missed targets lower the
## satisfaction. A satisfied sponsor renews, an unhappy one leaves.
class_name Sponsors
extends RefCounted

## Ad space on the car per tier.
const SLOTS := {
	SponsorData.Tier.TITLE: 1,
	SponsorData.Tier.MAJOR: 2,
	SponsorData.Tier.MINOR: 3,
}
## Position a sponsor usually wants to see (varies by ±1 or ±2 per offer).
const TARGET := {
	SponsorData.Tier.TITLE: 5,
	SponsorData.Tier.MAJOR: 8,
	SponsorData.Tier.MINOR: 10,
}
const TIER_NAMES := {
	SponsorData.Tier.TITLE: "Title sponsor",
	SponsorData.Tier.MAJOR: "Major sponsor",
	SponsorData.Tier.MINOR: "Minor sponsor",
}
const OFFER_DAYS := 60
const START_SATISFACTION := 70
const BONUS_SATISFACTION := 15
const MISS_SATISFACTION := -25
## Satisfaction needed to renew at the end of a contract, and below which a
## sponsor leaves during the contract.
const RENEW_AT := 50
const LEAVE_AT := 10

## [id, name, sector, tier, required reputation, payment per race in $M]
const CATALOG := [
	[&"voltra", "Voltra Energy", "Energy drinks", SponsorData.Tier.TITLE, 70, 1.8],
	[&"helix", "Helix Bank", "Banking", SponsorData.Tier.TITLE, 65, 1.6],
	[&"aeris", "Aeris Telecom", "Telecoms", SponsorData.Tier.TITLE, 75, 2.0],
	[&"quantis", "Quantis Software", "Software", SponsorData.Tier.MAJOR, 55, 0.9],
	[&"norva", "Norva Insurance", "Insurance", SponsorData.Tier.MAJOR, 45, 0.8],
	[&"kairo", "Kairo Watches", "Watches", SponsorData.Tier.MAJOR, 60, 1.0],
	[&"ardent", "Ardent Oil", "Fuels", SponsorData.Tier.MAJOR, 40, 0.8],
	[&"lumen", "Lumen Electronics", "Electronics", SponsorData.Tier.MAJOR, 50, 0.9],
	[&"tessera", "Tessera Coffee", "Food and drink", SponsorData.Tier.MINOR, 20, 0.3],
	[&"sunder", "Sunder Sportswear", "Apparel", SponsorData.Tier.MINOR, 25, 0.35],
	[&"grano", "Grano Bakery", "Food", SponsorData.Tier.MINOR, 0, 0.25],
	[&"ferrum", "Ferrum Tools", "Tools", SponsorData.Tier.MINOR, 15, 0.3],
	[&"oriel", "Oriel Optics", "Optics", SponsorData.Tier.MINOR, 30, 0.4],
	[&"brisk", "Brisk Mobile", "Mobile apps", SponsorData.Tier.MINOR, 10, 0.3],
	[&"halden", "Halden Pharma", "Health", SponsorData.Tier.MINOR, 35, 0.4],
]


## Days since the start of the game (for offer expiry).
static func now_key() -> int:
	return (Calendar.year - Calendar.START_YEAR) * Calendar.DAYS_PER_SEASON + Calendar.day


## Creates the sponsor templates and the first offers of every team.
static func setup_world(r: RandomNumberGenerator) -> void:
	GameState.sponsors.clear()
	GameState.sponsor_offers.clear()
	GameState.sponsor_deals.clear()
	for entry in CATALOG:
		var s := SponsorData.new()
		s.id = entry[0]
		s.name = entry[1]
		s.sector = entry[2]
		s.tier = entry[3]
		s.required_reputation = entry[4]
		s.payment_per_race = roundi(entry[5] * 1_000_000)
		GameState.sponsors[s.id] = s
	for team in GameState.teams.values():
		refresh_offers(team, r)
		if team.id != GameState.player_team_id:
			ai_fill(team)


## Every month: expired offers go, the teams get new ones, AI teams sign the best.
static func monthly_update(r: RandomNumberGenerator) -> void:
	for offer in GameState.sponsor_offers.duplicate():
		if offer.expires_key < now_key():
			GameState.sponsor_offers.erase(offer)
	for team in GameState.teams.values():
		var added := refresh_offers(team, r)
		if team.id == GameState.player_team_id:
			if added > 0:
				_message_new_offers(added)
		else:
			ai_fill(team)


## Adds offers until the team has as many open as it can attract. Returns the number added.
static func refresh_offers(team: TeamData, r: RandomNumberGenerator) -> int:
	var added := 0
	var start := r.randi() % CATALOG.size()
	for i in CATALOG.size():
		if offers_of(team.id).size() >= offers_wanted(team):
			break
		var entry: Array = CATALOG[(start + i) % CATALOG.size()]
		var s: SponsorData = GameState.sponsors[entry[0]]
		if s.required_reputation > team.reputation or _has_deal_or_offer(team.id, s.id):
			continue
		if free_slots(team, s.tier) - _offers_in_tier(team.id, s.tier) <= 0:
			continue
		GameState.sponsor_offers.append(_make_offer(team, s, r))
		added += 1
	return added


## Open offers a team can have at once: 2, more with a hospitality building
## and with a strong networking commercial manager.
static func offers_wanted(team: TeamData) -> int:
	var extra := 0
	var manager := _commercial_manager(team)
	if manager:
		extra = roundi((manager.attribute(&"networking") - 50) / 25.0)
	return clampi(2 + Facilities.level(team, &"hospitality") / 2 + extra, 1, 5)


## Signs an offer: the team gets the signing bonus and the contract starts.
## Returns "" or the reason it failed.
static func sign_offer(team: TeamData, offer: SponsorDeal) -> String:
	if not GameState.sponsor_offers.has(offer):
		return "The offer is no longer available."
	if free_slots(team, offer.tier) <= 0:
		return "All %s slots are taken." % TIER_NAMES[offer.tier]
	GameState.sponsor_offers.erase(offer)
	offer.start_year = Calendar.year
	offer.end_year = Calendar.year + offer.years - 1
	offer.satisfaction = START_SATISFACTION
	offer.expires_key = 0
	GameState.sponsor_deals.append(offer)
	team.sponsor_ids.append(offer.sponsor_id)
	Finance.receive(team, &"sponsor", offer.signing_bonus)
	if team.id == GameState.player_team_id:
		var msg := InboxMessage.new()
		msg.sender = "Commercial manager"
		msg.subject = "New sponsor: %s"
		msg.subject_args = [_name_of(offer)]
		msg.icon = "handshake"
		msg.add_paragraph("%s signed for %d years: %s per race, signing bonus %s.",
			[_name_of(offer), offer.years, UIStyle.money(offer.payment_per_race), UIStyle.money(offer.signing_bonus)])
		msg.add_paragraph("Bonus of %s if we finish in P%d or better at the end of the season.",
			[UIStyle.money(offer.bonus_amount), offer.bonus_target])
		msg.link_screen = &"sponsors"
		msg.link_args = {}
		msg.link_label = "Open sponsors"
		GameState.add_message(msg)
	return ""


static func decline(offer: SponsorDeal) -> void:
	GameState.sponsor_offers.erase(offer)


## AI teams sign the best offers whose tier still has a free slot.
static func ai_fill(team: TeamData) -> void:
	var offers := offers_of(team.id)
	offers.sort_custom(func(a, b): return a.payment_per_race > b.payment_per_race)
	for offer in offers:
		if free_slots(team, offer.tier) > 0:
			sign_offer(team, offer)


## Paid after every race weekend.
static func pay_race(team: TeamData) -> void:
	for deal in deals_of(team.id):
		Finance.receive(team, &"sponsor", deal.payment_per_race)


## Income per race from all contracts of a team.
static func per_race(team_id: StringName) -> int:
	var total := 0
	for deal in deals_of(team_id):
		total += deal.payment_per_race
	return total


## Bonuses the team would get at its current position.
static func bonuses_at(team_id: StringName, position: int) -> int:
	var total := 0
	for deal in deals_of(team_id):
		if position > 0 and position <= deal.bonus_target:
			total += deal.bonus_amount
	return total


## End of the season: bonuses, satisfaction, renewals and early exits.
## table = constructors' standings, best first.
static func season_end(series: SeriesData, table: Array) -> void:
	for team_id in series.team_ids:
		var team: TeamData = GameState.teams.get(team_id)
		if not team:
			continue
		var position := 0
		for i in table.size():
			if table[i][0] == team_id:
				position = i + 1
		var lines: Array = []
		for deal in deals_of(team_id):
			lines.append_array(_settle(team, deal, position))
		if team_id == GameState.player_team_id and not lines.is_empty():
			_message_season(position, lines)


static func free_slots(team: TeamData, tier: SponsorData.Tier) -> int:
	return SLOTS[tier] - _deals_in_tier(team.id, tier)


static func deals_of(team_id: StringName) -> Array[SponsorDeal]:
	var result: Array[SponsorDeal] = []
	for deal in GameState.sponsor_deals:
		if deal.team_id == team_id:
			result.append(deal)
	return result


static func offers_of(team_id: StringName) -> Array[SponsorDeal]:
	var result: Array[SponsorDeal] = []
	for offer in GameState.sponsor_offers:
		if offer.team_id == team_id:
			result.append(offer)
	return result


# --- Internals -------------------------------------------------------------------------

static func _settle(team: TeamData, deal: SponsorDeal, position: int) -> Array:
	var lines := []
	var name := _name_of(deal)
	if position > 0 and position <= deal.bonus_target:
		Finance.receive(team, &"sponsor", deal.bonus_amount)
		deal.satisfaction = mini(deal.satisfaction + BONUS_SATISFACTION, 100)
		lines.append("%s paid the bonus of %s: P%d reached (target P%d)." % [name,
			UIStyle.money(deal.bonus_amount), position, deal.bonus_target])
	else:
		deal.satisfaction = maxi(deal.satisfaction + MISS_SATISFACTION, 0)
		lines.append("%s paid no bonus: P%d, target was P%d. Satisfaction %d." % [name,
			position, deal.bonus_target, deal.satisfaction])
	var ends := deal.end_year <= Calendar.year
	if ends or deal.satisfaction <= LEAVE_AT:
		GameState.sponsor_deals.erase(deal)
		team.sponsor_ids.erase(deal.sponsor_id)
	if ends and deal.satisfaction >= RENEW_AT:
		var offer := SponsorDeal.new()
		offer.sponsor_id = deal.sponsor_id
		offer.team_id = team.id
		offer.tier = deal.tier
		offer.payment_per_race = deal.payment_per_race
		offer.signing_bonus = deal.signing_bonus
		offer.bonus_amount = deal.bonus_amount
		offer.bonus_target = deal.bonus_target
		offer.years = 2
		offer.expires_key = now_key() + OFFER_DAYS
		GameState.sponsor_offers.append(offer)
		lines.append("%s offers a new contract." % name)
	elif ends:
		lines.append("%s does not renew." % name)
	elif deal.satisfaction <= LEAVE_AT:
		lines.append("%s terminates the contract early." % name)
	return lines


static func _make_offer(team: TeamData, s: SponsorData, r: RandomNumberGenerator) -> SponsorDeal:
	var base := s.payment_per_race * (0.9 + r.randf() * 0.2) * _commercial_factor(team)
	var offer := SponsorDeal.new()
	offer.sponsor_id = s.id
	offer.team_id = team.id
	offer.tier = s.tier
	offer.payment_per_race = snappedi(base, 10_000)
	offer.signing_bonus = snappedi(base * 2.0, 10_000)
	offer.bonus_amount = snappedi(base * 4.0, 10_000)
	offer.bonus_target = clampi(TARGET[s.tier] + r.randi_range(-1, 1), 1, 20)
	offer.years = r.randi_range(1, 3)
	offer.expires_key = now_key() + OFFER_DAYS
	return offer


## Commercial manager's negotiation: 0.8 without one, up to 1.2 with a strong one.
static func _commercial_factor(team: TeamData) -> float:
	var manager := _commercial_manager(team)
	if not manager:
		return 0.8
	return 0.8 + 0.4 * manager.attribute(&"negotiation") / 100.0


static func _commercial_manager(team: TeamData) -> StaffData:
	for s in GameState.staff_of_team(team.id):
		if s.role == StaffData.Role.COMMERCIAL_MANAGER:
			return s
	return null


static func _deals_in_tier(team_id: StringName, tier: SponsorData.Tier) -> int:
	return deals_of(team_id).filter(func(d): return d.tier == tier).size()


static func _offers_in_tier(team_id: StringName, tier: SponsorData.Tier) -> int:
	return offers_of(team_id).filter(func(o): return o.tier == tier).size()


static func _has_deal_or_offer(team_id: StringName, sponsor_id: StringName) -> bool:
	for deal in deals_of(team_id):
		if deal.sponsor_id == sponsor_id:
			return true
	for offer in offers_of(team_id):
		if offer.sponsor_id == sponsor_id:
			return true
	return false


static func _name_of(deal: SponsorDeal) -> String:
	var s: SponsorData = GameState.sponsors.get(deal.sponsor_id)
	return s.name if s else String(deal.sponsor_id)


static func _message_new_offers(count: int) -> void:
	var msg := InboxMessage.new()
	msg.sender = "Commercial manager"
	msg.subject = "New sponsor offers: %d"
	msg.subject_args = [count]
	msg.icon = "handshake"
	msg.add_paragraph("Companies want to put their name on our car. Compare the offers and sign the ones that suit us.")
	msg.link_screen = &"sponsors"
	msg.link_args = {}
	msg.link_label = "Open sponsors"
	GameState.add_message(msg)


static func _message_season(position: int, lines: Array) -> void:
	var msg := InboxMessage.new()
	msg.sender = "Commercial manager"
	msg.subject = "Sponsors after the season: P%d"
	msg.subject_args = [position]
	msg.icon = "handshake"
	msg.priority = InboxMessage.Priority.IMPORTANT
	for line in lines:
		msg.add_paragraph(line)
	msg.link_screen = &"sponsors"
	msg.link_args = {}
	msg.link_label = "Open sponsors"
	GameState.add_message(msg)
