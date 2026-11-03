## Sponsors (R6b, docs/finance_model.md 12): the contracts on the car, the ad
## slots they use, and the offers to sign or decline.
extends UIScreen

## Shown once after a signing failed (the screen reloads after the click).
static var _error := ""

var _team: TeamData
var _page: VBoxContainer


func setup(_args: Dictionary) -> void:
	_team = GameState.player_team()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)
	_page.add_child(_stats_row())
	if _error != "":
		var warning := _small(_error)
		warning.add_theme_color_override("font_color", UIStyle.BAD)
		_page.add_child(warning)
		_error = ""
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UIStyle.GAP)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.1
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.add_child(_deals_card())
	left.add_child(_slots_card())
	columns.add_child(left)
	columns.add_child(_offers_card())
	_page.add_child(columns)


func screen_title() -> String:
	return "Sponsors"


func nav_section() -> StringName:
	return &"sponsors"


func _stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var used := Sponsors.deals_of(_team.id).size()
	var slots := 0
	for count in Sponsors.SLOTS.values():
		slots += count
	var book: Dictionary = GameState.cash_book.get(_team.id, {})
	var stats := [
		[UIStyle.money(Sponsors.per_race(_team.id)), tr("Sponsor income per race"), UIStyle.GOOD],
		[UIStyle.money(book.get(&"sponsor", 0)), tr("Sponsor income this season"), UIStyle.GOOD],
		["%d / %d" % [used, slots], tr("Ad slots used"), UIStyle.TEXT],
		["%d" % Sponsors.offers_of(_team.id).size(), tr("Open offers"), UIStyle.TEXT],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _deals_card() -> UICard:
	var card := UICard.new(tr("Contracts"), tr("paid after every race"))
	var deals := Sponsors.deals_of(_team.id)
	if deals.is_empty():
		card.add_padded(_small(tr("No sponsor yet. Sign an offer on the right.")), 8, 8)
		return card
	deals.sort_custom(func(a, b): return a.payment_per_race > b.payment_per_race)
	for deal in deals:
		card.add_row(_deal_row(deal))
	return card


func _deal_row(deal: SponsorDeal) -> HoverRow:
	var row := HoverRow.new()
	var box := _box()
	box.add_child(_who(deal))
	box.add_child(_figure(UIStyle.money(deal.payment_per_race), tr("per race")))
	box.add_child(_figure("P%d" % deal.bonus_target, tr("bonus %s") % UIStyle.money(deal.bonus_amount)))
	var satisfaction := _figure("%d" % deal.satisfaction, tr("satisfaction"))
	satisfaction.get_child(0).add_theme_color_override("font_color", UIStyle.meter_color(deal.satisfaction))
	box.add_child(satisfaction)
	box.add_child(_figure(tr("until %d") % deal.end_year, tr("contract")))
	row.add_child(box)
	return row


func _slots_card() -> UICard:
	var card := UICard.new(tr("Ad slots on the car"), tr("used / free"))
	for tier in [SponsorData.Tier.TITLE, SponsorData.Tier.MAJOR, SponsorData.Tier.MINOR]:
		var names := []
		for deal in Sponsors.deals_of(_team.id):
			if deal.tier == tier:
				names.append(_name_of(deal))
		var used: int = names.size()
		var text := ", ".join(names) if not names.is_empty() else tr("free")
		card.add_row(FactRow.new(tr(Sponsors.TIER_NAMES[tier]), "%d / %d" % [used, Sponsors.SLOTS[tier]], text, true))
	return card


func _offers_card() -> UICard:
	var card := UICard.new(tr("Offers"), tr("sign or decline"))
	var offers := Sponsors.offers_of(_team.id)
	if offers.is_empty():
		card.add_padded(_small(tr("No offers right now. New offers come at the start of every month.")), 8, 8)
		return card
	offers.sort_custom(func(a, b): return a.payment_per_race > b.payment_per_race)
	for offer in offers:
		card.add_row(_offer_row(offer))
	return card


func _offer_row(offer: SponsorDeal) -> HoverRow:
	var row := HoverRow.new()
	var box := _box_with(_who(offer), [
		_figure(UIStyle.money(offer.payment_per_race), tr("per race")),
		_figure(UIStyle.money(offer.signing_bonus), tr("signing bonus")),
		_figure("P%d" % offer.bonus_target, tr("bonus %s") % UIStyle.money(offer.bonus_amount)),
		_figure(tr("%d years") % offer.years, tr("expires in %d days") % (offer.expires_key - Sponsors.now_key())),
	])
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	var free := Sponsors.free_slots(_team, offer.tier)
	var sign_button := _accent(tr("Sign"))
	sign_button.disabled = free <= 0
	sign_button.tooltip_text = "" if free > 0 else tr("All %s slots are taken.") % tr(Sponsors.TIER_NAMES[offer.tier])
	sign_button.pressed.connect(func():
		_error = Sponsors.sign_offer(_team, offer)
		shell.refresh_current())
	buttons.add_child(sign_button)
	var decline := Button.new()
	decline.text = tr("Decline")
	decline.pressed.connect(func():
		Sponsors.decline(offer)
		shell.refresh_current())
	buttons.add_child(decline)
	box.add_child(buttons)
	row.add_child(box)
	return row


func _who(deal: SponsorDeal) -> VBoxContainer:
	var s: SponsorData = GameState.sponsors.get(deal.sponsor_id)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	var name_label := Label.new()
	name_label.text = _name_of(deal)
	name_label.theme_type_variation = &"StrongLabel"
	column.add_child(name_label)
	var sub := Label.new()
	sub.text = "%s · %s" % [s.sector if s else "", tr(Sponsors.TIER_NAMES[deal.tier])]
	sub.theme_type_variation = &"SmallLabel"
	column.add_child(sub)
	return column


func _box() -> HBoxContainer:
	return _box_with(null, [])


## One row of figures: the name column first (or none), then the figures.
func _box_with(first: Control, figures: Array) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if first:
		box.add_child(first)
	for figure in figures:
		box.add_child(figure)
	return box


func _figure(value: String, caption: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var number := Label.new()
	number.text = value
	number.theme_type_variation = &"NumberLabel"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(number)
	var label := Label.new()
	label.text = caption
	label.theme_type_variation = &"SmallLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(label)
	return column


func _name_of(deal: SponsorDeal) -> String:
	var s: SponsorData = GameState.sponsors.get(deal.sponsor_id)
	return s.name if s else String(deal.sponsor_id)


func _accent(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = &"AccentButton"
	return b


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
