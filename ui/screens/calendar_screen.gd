## All rounds of the season (mockup r2_season.html, screen 3): done, next
## and upcoming, with track character, rain and heat risk, how well the
## track suits our car, the winner and our best result. Click a round
## that was raced to open its result.
extends UIScreen

const COLUMNS := 4


func setup(_args: Dictionary) -> void:
	var s: SeriesData = GameState.series[GameState.player_team().series_id]
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)

	var info := Label.new()
	info.text = tr("Season %d · %d rounds · %d raced") % [Calendar.year, s.calendar.size(), GameState.resolved_rounds]
	info.theme_type_variation = &"MutedLabel"
	page.add_child(info)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", UIStyle.GAP)
	grid.add_theme_constant_override("v_separation", UIStyle.GAP)
	page.add_child(grid)
	var results := _results_by_round()
	for r in s.calendar.size():
		grid.add_child(_round_box(s, r, results.get(r + 1, {})))


func screen_title() -> String:
	return "Calendar"


func nav_section() -> StringName:
	return &"calendar"


## round -> {"winner": driver_id, "best": our best finish (0 = DNF, -1 = none)}
func _results_by_round() -> Dictionary:
	var out := {}
	for id in GameState.season_stats:
		var d: DriverData = GameState.drivers.get(id)
		for r in GameState.season_stats[id].results:
			var entry: Dictionary = out.get(r.round, {"winner": &"", "best": -1})
			if r.finish == 1:
				entry.winner = id
			if d and d.team_id == GameState.player_team_id:
				var best: int = entry.best
				if r.finish > 0 and (best <= 0 or r.finish < best):
					entry.best = r.finish
				elif best == -1:
					entry.best = 0
			out[r.round] = entry
	return out


func _round_box(s: SeriesData, r: int, result: Dictionary) -> Control:
	var track: TrackData = GameState.tracks[s.calendar[r]]
	var done := r < GameState.resolved_rounds
	var next := r == GameState.resolved_rounds
	var box := HoverRow.new(&"ResultBox", &"ResultBoxHover")
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if next:
		box.set_selected(true)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	box.add_child(column)

	var top := HBoxContainer.new()
	var rn := Label.new()
	rn.text = "R%d · %s" % [r + 1, track.country]
	rn.theme_type_variation = &"SectionLabel"
	rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(rn)
	var status := Label.new()
	status.theme_type_variation = &"SmallLabel"
	var days := s.race_days[r] - Calendar.day
	if done:
		status.text = "✓"
		status.add_theme_color_override("font_color", UIStyle.GOOD)
	elif next:
		status.text = (tr("NEXT · today") if days <= 0 else tr("NEXT · in %d days") % days)
		status.add_theme_color_override("font_color", UIStyle.ACCENT)
	else:
		status.text = Calendar.format_date(s.race_days[r])
	top.add_child(status)
	column.add_child(top)

	var name_label := Label.new()
	name_label.text = track.name.trim_suffix(" Grand Prix")
	name_label.uppercase = true
	name_label.theme_type_variation = &"HeadingLabel"
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(name_label)
	var country := Label.new()
	country.text = Countries.name_of(track.country)
	country.theme_type_variation = &"SmallLabel"
	column.add_child(country)

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	if TrackLayouts.has_layout(track.id):
		chips.add_child(_chip(tr(TrackInfo.character(track.id)), UIStyle.MUTED))
		var rain := TrackInfo.rain_chance(track.id)
		if rain >= 0.25:
			chips.add_child(_chip(tr("Rain %d %%") % roundi(rain * 100), UIStyle.RAIN))
		if TrackInfo.is_hot(track.id):
			chips.add_child(_chip(tr("Hot"), UIStyle.WARN))
		if TrackInfo.safety_car_likely(track.id):
			chips.add_child(_chip(tr("Safety car likely"), UIStyle.BAD))
	column.add_child(chips)

	if TrackLayouts.has_layout(track.id):
		var suit := TrackInfo.suitability(GameState.player_team_id, track.id)
		var suit_row := HBoxContainer.new()
		var suit_label := Label.new()
		suit_label.text = "Suits our car"
		suit_label.theme_type_variation = &"SmallLabel"
		suit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		suit_row.add_child(suit_label)
		var suit_value := Label.new()
		suit_value.text = tr(suit.label)
		suit_value.theme_type_variation = &"SmallLabel"
		suit_value.add_theme_color_override("font_color", TrackInfo.suitability_color(suit.label))
		suit_row.add_child(suit_value)
		column.add_child(suit_row)
		column.add_child(Meter.new(suit.value, TrackInfo.suitability_color(suit.label), 4))

	var res := HBoxContainer.new()
	var left := Label.new()
	left.theme_type_variation = &"SmallLabel"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := Label.new()
	right.theme_type_variation = &"StrongLabel"
	if done:
		var winner: DriverData = GameState.drivers.get(result.get("winner", &""))
		left.text = tr("Winner: %s") % (winner.last_name if winner else "–")
		var best: int = result.get("best", -1)
		right.text = tr("Us: %s") % ("P%d" % best if best > 0 else "DNF")
		right.add_theme_color_override("font_color", UIStyle.position_color(best))
		box.make_clickable()
		box.tooltip_text = tr("Open race result")
		box.clicked.connect(func(): shell.navigate(&"race_result", {"round": r + 1}))
	elif next:
		left.text = "Practice, qualifying and race on race day"
		if Season.weekend_pending():
			box.make_clickable()
			box.clicked.connect(func(): shell.navigate(&"weekend"))
	else:
		left.text = "Not raced yet"
	res.add_child(left)
	res.add_child(right)
	column.add_child(res)
	if done:
		box.modulate = Color(1, 1, 1, 0.85)
	return box


func _chip(text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(Color(color, 0.12), Color(color, 0.5), 1, 6, 1))
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"TinyLabel"
	l.add_theme_color_override("font_color", color.lightened(0.2))
	panel.add_child(l)
	return panel
