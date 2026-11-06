## Owner (R6c, docs/finance_model.md 11): the owner's personality and trust,
## the goals for the season and the long term, asking for money, the investor,
## and the team's reputation and fans (R6d).
extends UIScreen

var _team: TeamData


func setup(_args: Dictionary) -> void:
	_team = GameState.player_team()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)
	if not Owners.has_owner(_team):
		page.add_child(_small(tr("This team has no owner.")))
		return
	page.add_child(_stats_row())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UIStyle.GAP)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.add_child(_owner_card())
	left.add_child(_goals_card())
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", UIStyle.GAP)
	right.add_child(_money_card())
	right.add_child(_investor_card())
	columns.add_child(right)
	page.add_child(columns)
	page.add_child(_reputation_card())


func screen_title() -> String:
	return "Owner"


func nav_section() -> StringName:
	return &"owner"


func _stats_row() -> HBoxContainer:
	var owner: Dictionary = _team.owner
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var stats := [
		["%d" % owner.trust, tr(Owners.trust_level(owner.trust)), UIStyle.GOOD if owner.trust >= 50 else UIStyle.BAD],
		["P%d" % owner.goal, tr("Season goal"), UIStyle.TEXT],
		["%d" % Career.reputation(), tr("Team principal's reputation"), UIStyle.TEXT],
		["%d" % _team.reputation, tr("Team reputation"), UIStyle.TEXT],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _owner_card() -> UICard:
	var owner: Dictionary = _team.owner
	var card := UICard.new(tr("Owner"), owner.name)
	card.add_padded(_small(tr(Owners.PERSONALITIES[owner.personality].text)), 8, 4)
	var trust := Meter.new(owner.trust, UIStyle.meter_color(owner.trust), 8)
	card.add_padded(trust, 8, 4)
	card.add_row(FactRow.new(tr("Trust"), "%d / 100" % owner.trust, tr(Owners.trust_level(owner.trust)), true))
	card.add_row(FactRow.new(tr("Personality"), tr(owner.personality.capitalize()), "", false))
	return card


func _goals_card() -> UICard:
	var owner: Dictionary = _team.owner
	var card := UICard.new(tr("Goals"), tr("standings are live"))
	var position := _position()
	var season_color := UIStyle.GOOD if position > 0 and position <= owner.goal else UIStyle.WARN
	card.add_row(FactRow.new(tr("Season goal"), tr("finish P%d or better") % owner.goal,
		tr("now P%d") % position if position > 0 else "", true, season_color))
	card.add_section(tr("Long-term goal"))
	card.add_row(FactRow.new(tr("Constructors' title by %d") % owner.long_deadline,
		"%d / 1" % mini(owner.titles - owner.titles_at_start, 1),
		tr("won within the goal period") if owner.titles > owner.titles_at_start else tr("still open"), true))
	card.add_padded(_small(tr("Met goals raise trust, missed goals lower it. A title raises it a lot; a missed long-term goal costs trust.")), 8, 8)
	return card


func _money_card() -> UICard:
	var card := UICard.new(tr("Ask for money"), tr("once per season"))
	var blocked := Owners.request_blocked(_team)
	if blocked != "":
		card.add_padded(_small(tr(blocked)), 8, 4)
	for amount in Owners.REQUEST_AMOUNTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var text := Label.new()
		text.text = tr("Chance %d %%") % roundi(Owners.grant_chance(_team, amount) * 100)
		text.theme_type_variation = &"MutedLabel"
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var button := Button.new()
		button.text = tr("Ask for %s") % UIStyle.money(amount)
		button.disabled = blocked != ""
		button.pressed.connect(func():
			Owners.request_money(_team, amount)
			shell.refresh_current())
		row.add_child(button)
		card.add_padded(row, 4, 4)
	return card


func _investor_card() -> UICard:
	var card := UICard.new(tr("Investors"), tr("money for a share of the prize"))
	if not _team.investor.is_empty():
		var inv: Dictionary = _team.investor
		card.add_row(FactRow.new(inv.name, tr("%d%% of prize money") % roundi(inv.share * 100),
			tr("condition: P%d or better · %d years left") % [inv.goal, inv.years], true))
	elif not _team.investor_offer.is_empty():
		var offer: Dictionary = _team.investor_offer
		card.add_row(FactRow.new(offer.name, UIStyle.money(offer.amount),
			tr("%d%% of prize money · P%d or better · %d years") % [roundi(offer.share * 100), offer.goal, offer.years], true,
			UIStyle.GOOD))
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		buttons.alignment = BoxContainer.ALIGNMENT_END
		var accept := Button.new()
		accept.text = tr("Accept")
		accept.theme_type_variation = &"AccentButton"
		accept.pressed.connect(func():
			Owners.accept_investor(_team)
			shell.refresh_current())
		buttons.add_child(accept)
		var decline := Button.new()
		decline.text = tr("Decline")
		decline.pressed.connect(func():
			Owners.decline_investor(_team)
			shell.refresh_current())
		buttons.add_child(decline)
		card.add_padded(buttons, 8, 8)
	else:
		card.add_padded(_small(tr("No investor is interested right now.")), 8, 8)
	return card


func _reputation_card() -> UICard:
	var card := UICard.new(tr("Reputation and fans"), tr("moves with the season's position"))
	card.add_row(FactRow.new(tr("Team reputation"), "%d" % _team.reputation, tr("needed for better sponsors"), true))
	card.add_row(FactRow.new(tr("Fans"), "%d" % _team.fans, tr("%s merchandise per race") % UIStyle.money(TeamReputation.merch_per_race(_team)), true))
	card.add_row(FactRow.new(tr("Team principal's reputation"), "%d" % Career.reputation(),
		tr("decides your job offers (Career)"), true))
	return card


func _position() -> int:
	var table := SeasonRecords.team_standings(GameState.series[_team.series_id])
	for i in table.size():
		if table[i][0] == _team.id:
			return i + 1
	return 0


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
