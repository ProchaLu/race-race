## Checks the sponsor rules (docs/finance_model.md 12): offers, slots, signing,
## payments per race, season bonuses, satisfaction, renewal and early exit.
## godot --headless --path . res://tools/sponsor_check.tscn
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var state = get_tree().root.get_node("GameState")
	var calendar = get_tree().root.get_node("Calendar")
	load("res://core/test_world.gd").build()
	var team: TeamData = state.player_team()
	var series: SeriesData = state.series[team.series_id]
	var r := RandomNumberGenerator.new()
	r.seed = 7

	# Every team respects its ad slots and its reputation; AI teams have signed.
	for id in state.teams:
		var t: TeamData = state.teams[id]
		for tier in Sponsors.SLOTS:
			assert(Sponsors.deals_of(id).filter(func(d): return d.tier == tier).size() <= Sponsors.SLOTS[tier],
				"too many sponsors for %s" % id)
		for offer in Sponsors.offers_of(id):
			assert(state.sponsors[offer.sponsor_id].required_reputation <= t.reputation, "offer above reputation")
	assert(Sponsors.offers_of(team.id).size() > 0, "no offers for the player")
	var ai_deals := 0
	for id in state.teams:
		if id != team.id:
			ai_deals += Sponsors.deals_of(id).size()
	assert(ai_deals > 0, "AI teams signed nothing")

	# Signing: the bonus is paid, the contract starts, the offer goes.
	state.sponsor_deals.clear()
	team.sponsor_ids.clear()
	state.cash_book.clear()
	var offer: SponsorDeal = Sponsors.offers_of(team.id)[0]
	var budget := team.budget
	assert(Sponsors.sign_offer(team, offer) == "", "signing failed")
	assert(team.budget == budget + offer.signing_bonus, "signing bonus not paid")
	assert(Sponsors.deals_of(team.id).has(offer) and not state.sponsor_offers.has(offer))
	assert(offer.end_year == calendar.year + offer.years - 1)
	assert(team.sponsor_ids.has(offer.sponsor_id))
	assert(Sponsors.sign_offer(team, offer) != "", "signed the same offer twice")

	# A full tier refuses another offer and pays nothing.
	var tier := offer.tier
	while Sponsors.free_slots(team, tier) > 0:
		var filler := SponsorDeal.new()
		filler.sponsor_id = offer.sponsor_id
		filler.team_id = team.id
		filler.tier = tier
		filler.end_year = calendar.year + 1
		state.sponsor_deals.append(filler)
	var extra := SponsorDeal.new()
	extra.sponsor_id = &"halden"
	extra.team_id = team.id
	extra.tier = tier
	extra.signing_bonus = 500_000
	extra.expires_key = Sponsors.now_key() + 30
	state.sponsor_offers.append(extra)
	var before := team.budget
	assert(Sponsors.sign_offer(team, extra) != "", "signed past the slot limit")
	assert(team.budget == before, "refused signing still paid")
	for d in state.sponsor_deals.duplicate():
		if d.tier == tier and d != offer:
			state.sponsor_deals.erase(d)
	state.sponsor_offers.erase(extra)

	# Race weekend: every contract pays its race money.
	state.cash_book.clear()
	var deal: SponsorDeal = offer
	var per_race := Sponsors.per_race(team.id)
	Finance.race_settlement(series)
	var merch := TeamReputation.merch_per_race(team)
	assert(Finance.total(team.id, true) - Finance.TV_PER_RACE - merch == per_race, "sponsor money per race wrong")

	# Season end with the player in P1: every target is reached, the bonus is paid.
	var first := _table(series, team.id, true)
	var last := _table(series, team.id, false)
	deal.end_year = calendar.year + 2
	deal.satisfaction = 60
	deal.bonus_target = 5
	state.cash_book.clear()
	Sponsors.season_end(series, first)
	assert(Finance.total(team.id, true) >= deal.bonus_amount, "bonus not paid when the target was reached")
	assert(deal.satisfaction == 75, "satisfaction after a reached target: %d" % deal.satisfaction)

	# Season end in last place: no bonus; a contract that ends with low satisfaction is not renewed.
	deal.end_year = calendar.year
	deal.satisfaction = 30
	state.cash_book.clear()
	var offers_before := Sponsors.offers_of(team.id).size()
	Sponsors.season_end(series, last)
	assert(not Sponsors.deals_of(team.id).has(deal), "contract did not end")
	assert(Finance.total(team.id, true) == 0, "bonus paid after a missed target")
	assert(Sponsors.offers_of(team.id).size() == offers_before, "renewal offered at low satisfaction")

	# A satisfied sponsor renews with a two-year offer.
	var happy := SponsorDeal.new()
	happy.sponsor_id = &"quantis"
	happy.team_id = team.id
	happy.tier = SponsorData.Tier.MAJOR
	happy.payment_per_race = 900_000
	happy.signing_bonus = 1_800_000
	happy.bonus_amount = 3_600_000
	happy.bonus_target = 20
	happy.years = 1
	happy.start_year = calendar.year
	happy.end_year = calendar.year
	happy.satisfaction = 80
	state.sponsor_deals.append(happy)
	team.sponsor_ids.append(happy.sponsor_id)
	Sponsors.season_end(series, first)
	var renewal: SponsorDeal = null
	for item in Sponsors.offers_of(team.id):
		if item.sponsor_id == &"quantis" and item.years == 2:
			renewal = item
	assert(renewal != null, "no renewal offer for a satisfied sponsor")
	assert(renewal.payment_per_race == happy.payment_per_race)
	assert(not Sponsors.deals_of(team.id).has(happy))

	# Mid-contract: satisfaction at the floor ends the contract early.
	var unhappy := SponsorDeal.new()
	unhappy.sponsor_id = &"norva"
	unhappy.team_id = team.id
	unhappy.tier = SponsorData.Tier.MAJOR
	unhappy.payment_per_race = 800_000
	unhappy.bonus_target = 1
	unhappy.satisfaction = 30
	unhappy.end_year = calendar.year + 2
	state.sponsor_deals.append(unhappy)
	Sponsors.season_end(series, last)
	assert(not Sponsors.deals_of(team.id).has(unhappy), "unhappy sponsor stayed")

	# Expired offers go in the monthly update.
	var stale := Sponsors.offers_of(team.id)
	for item in stale:
		item.expires_key = Sponsors.now_key() - 1
	Sponsors.monthly_update(r)
	for item in stale:
		assert(not state.sponsor_offers.has(item), "expired offer kept")

	# Hospitality adds open offers.
	var probe := TeamData.new()
	probe.reputation = 100
	var base := Sponsors.offers_wanted(probe)
	probe.facilities[&"hospitality"] = 4
	assert(Sponsors.offers_wanted(probe) > base, "hospitality adds no offers")

	print("Sponsors: offers, slots, signing, race payments, bonuses, satisfaction, renewal and early exit passed.")
	get_tree().quit()


## Standings with the player first or last, the others in between.
func _table(series: SeriesData, player_id: StringName, first: bool) -> Array:
	var table := []
	for id in series.team_ids:
		if id != player_id:
			table.append([id, 5])
	if first:
		table.push_front([player_id, 5])
	else:
		table.append([player_id, 5])
	return table
