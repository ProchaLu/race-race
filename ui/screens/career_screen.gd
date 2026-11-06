## Career (R8b, docs/career_model.md): the team principal's reputation, the
## dismissal, job offers from other teams and the teams run so far.
extends UIScreen


func setup(_args: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)
	page.add_child(_stats_row())
	if Career.is_dismissed():
		var card := UICard.new(tr("You have been dismissed"), GameState.player_team().name)
		card.add_padded(_small(tr("Choose one of the job offers below. Time stands still until you take a new job.")), 8, 8)
		page.add_child(card)
	page.add_child(_offers_card())
	page.add_child(_history_card())


func screen_title() -> String:
	return "Career"


func nav_section() -> StringName:
	return &"career"


func _stats_row() -> HBoxContainer:
	var team := GameState.player_team()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var stats := [
		["%d" % Career.reputation(), tr("Team principal's reputation"), UIStyle.TEXT],
		[team.name, tr("Current team"), UIStyle.BAD if Career.is_dismissed() else UIStyle.TEXT],
		["%d" % GameState.career.get("history", []).size(), tr("Teams so far"), UIStyle.TEXT],
		["%d" % Career.offers().size(), tr("Job offers"), UIStyle.GOOD if not Career.offers().is_empty() else UIStyle.TEXT],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _offers_card() -> UICard:
	var card := UICard.new(tr("Job offers"), tr("after the season"))
	if Career.offers().is_empty():
		card.add_padded(_small(tr("No team is offering you a job right now. Offers come at the end of a season: after a dismissal from teams that missed their goals, otherwise from better teams when your reputation is high.")), 8, 8)
		return card
	var last_table := _last_table()
	for offer in Career.offers():
		var team: TeamData = GameState.teams[offer.team_id]
		card.add_section(team.name)
		card.add_row(FactRow.new(tr("Team reputation"), "%d" % team.reputation,
			tr("needs %d from you") % Career.required_reputation(team), true))
		var position: int = last_table.find(team.id) + 1
		if position > 0:
			card.add_row(FactRow.new(tr("Constructors' championship"), "P%d" % position,
				tr("expected P%d") % Career.expected_position(team), true))
		card.add_row(FactRow.new(tr("Budget"), UIStyle.money(team.budget), "", true, UIStyle.money_color(team.budget)))
		card.add_row(FactRow.new(tr("Car ranked in the field"), "%d." % TeamMood.car_rank(team.id), "", true))
		card.add_row(FactRow.new(tr("Owner"), offer.owner_name, tr(offer.personality.capitalize()), true))
		card.add_padded(_small(tr(Owners.PERSONALITIES[offer.personality].text)), 8, 4)
		card.add_row(FactRow.new(tr("Season goal"), tr("finish P%d or better") % offer.goal, "", true))
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		buttons.alignment = BoxContainer.ALIGNMENT_END
		var accept := Button.new()
		accept.text = tr("Take the job")
		accept.theme_type_variation = &"AccentButton"
		accept.pressed.connect(func():
			Career.accept(offer)
			shell.navigate(&"owner"))
		buttons.add_child(accept)
		if not (Career.is_dismissed() and Career.offers().size() <= 1):
			var decline := Button.new()
			decline.text = tr("Decline")
			decline.pressed.connect(func():
				Career.decline(offer)
				shell.refresh_current())
			buttons.add_child(decline)
		card.add_padded(buttons, 8, 8)
	return card


func _history_card() -> UICard:
	var card := UICard.new(tr("Career history"), tr("teams run as team principal"))
	var history: Array = GameState.career.get("history", [])
	for i in range(history.size() - 1, -1, -1):
		var entry: Dictionary = history[i]
		var team: TeamData = GameState.teams.get(entry.team_id)
		var years := "%d–" % entry.from_year if entry.to_year == 0 else "%d–%d" % [entry.from_year, entry.to_year]
		var note := ""
		match entry.reason:
			"dismissed":
				note = tr("dismissed")
			"moved":
				note = tr("moved to a new team")
		if entry.to_year == 0:
			note = tr("current team")
		card.add_row(FactRow.new(team.name if team else String(entry.team_id), years, note, true,
			UIStyle.BAD if entry.reason == "dismissed" else UIStyle.TEXT))
	return card


## Team IDs of the last finished season's constructors' table, best first.
func _last_table() -> Array:
	var ids := []
	if GameState.season_history.is_empty():
		return ids
	for row in GameState.season_history.back().get("team_table", []):
		ids.append(row[0])
	return ids


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
