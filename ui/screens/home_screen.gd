## Start screen: next race, team mood, your drivers and both championships
## (top 3 plus the places around your team).
extends UIScreen


func setup(_args: Dictionary) -> void:
	var team := GameState.player_team()
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(row)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_next_race_card())
	left.add_child(_mood_card())
	left.add_child(_drivers_card(team))
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UIStyle.GAP)
	right.custom_minimum_size.x = 460
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(_team_standings_card())
	right.add_child(_standings_card())
	row.add_child(right)


func screen_title() -> String:
	return "Home"


func nav_section() -> StringName:
	return &"home"


func _next_race_card() -> UICard:
	var card := UICard.new("Next race")
	var next := GameState.next_round_index()
	var s: SeriesData = GameState.series[GameState.player_team().series_id]
	if next >= 0:
		var track: TrackData = GameState.tracks[s.calendar[next]]
		card.add_row(FactRow.new("Round", tr("%d of %d") % [next + 1, s.calendar.size()]))
		card.add_row(FactRow.new("Event", track.name))
		card.add_row(FactRow.new("Country", Countries.name_of(track.country)))
		var days := s.race_days[next] - Calendar.day
		card.add_row(FactRow.new("Date", Calendar.format_date(s.race_days[next]),
			tr("today") if days <= 0 else tr("in %d days") % days))
		if TrackLayouts.has_layout(track.id):
			var suit := TrackInfo.suitability(GameState.player_team_id, track.id)
			card.add_row(FactRow.new("Suits our car", tr(suit.label), tr("%s track") % tr(TrackInfo.character(track.id)),
				false, TrackInfo.suitability_color(suit.label)))
			card.add_row(FactRow.new("Rain risk", "%d %%" % roundi(TrackInfo.rain_chance(track.id) * 100), "", true))
	else:
		card.add_row(FactRow.new("Round", tr("Season finished")))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	if Season.weekend_pending():
		var weekend := Button.new()
		weekend.text = "Open race weekend"
		weekend.icon = UIStyle.icon("trophy")
		weekend.theme_type_variation = &"AccentButton"
		weekend.pressed.connect(func(): shell.navigate(&"weekend"))
		actions.add_child(weekend)
	elif next < 0 and not GameState.season_history.is_empty():
		var review := Button.new()
		review.text = "Season review"
		review.icon = UIStyle.icon("trophy")
		review.pressed.connect(func(): shell.navigate(&"season_review"))
		actions.add_child(review)
	var calendar := Button.new()
	calendar.text = "Calendar"
	calendar.icon = UIStyle.icon("calendar")
	calendar.pressed.connect(func(): shell.navigate(&"calendar"))
	actions.add_child(calendar)
	card.add_padded(actions, 10, 0)
	var button := Button.new()
	button.text = "Watch a test race (Test Ring)"
	button.icon = UIStyle.icon("play")
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(func(): EventBus.race_requested.emit(&"test_ring"))
	card.add_padded(button, 12, 0)
	return card


## Team mood (decision 42): gauge on the left, every factor on the right,
## the five levels underneath.
func _mood_card() -> UICard:
	var team_id := GameState.player_team_id
	var mood := TeamMood.value(team_id)
	var trend := TeamMood.trend(team_id)
	var trend_text := tr("%+d this week") % trend if trend != 0 else tr("No change this week")
	var card := UICard.new("Team mood", trend_text)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var gauge_box := VBoxContainer.new()
	gauge_box.add_theme_constant_override("separation", 0)
	gauge_box.add_child(MoodGauge.new(mood))
	var level := Label.new()
	level.text = TeamMood.level_name(mood)
	level.theme_type_variation = &"HeadingLabel"
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.add_theme_color_override("font_color", UIStyle.mood_color(mood))
	gauge_box.add_child(level)
	var number := Label.new()
	number.text = "%d / 100" % mood
	number.theme_type_variation = &"SmallLabel"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gauge_box.add_child(number)
	row.add_child(gauge_box)

	var factors := VBoxContainer.new()
	factors.add_theme_constant_override("separation", 0)
	factors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var index := 0
	var base := FactRow.new("Neutral base", "50", "", true)
	base.set_zebra(false)
	factors.add_child(base)
	for f in TeamMood.factors(team_id):
		index += 1
		var delta: int = f[1]
		var fact := FactRow.new(f[0], "%+d" % delta, "", true,
			UIStyle.GOOD if delta > 0 else (UIStyle.BAD if delta < 0 else UIStyle.TEXT))
		fact.set_zebra(index % 2 == 1)
		factors.add_child(fact)
	row.add_child(factors)
	card.add_padded(row, 8, 4)

	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 18)
	for i in TeamMood.LEVELS.size():
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var swatch := ColorRect.new()
		swatch.color = UIStyle.mood_color_by_index(i)
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(swatch)
		var low: int = 0 if i == 0 else TeamMood.LEVELS[i - 1][0]
		var high: int = mini(TeamMood.LEVELS[i][0] - 1, 100)
		var text := Label.new()
		text.text = "%s %d–%d" % [tr(TeamMood.LEVELS[i][1]), low, high]
		text.theme_type_variation = &"SmallLabel"
		item.add_child(text)
		legend.add_child(item)
	card.add_padded(legend, 8, 0)
	card.add_padded(_note("Affects the productivity of all departments (up to ±5 %), mistakes in the pit lane and how easily rivals poach your staff."), 4, 0)
	return card


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _drivers_card(team: TeamData) -> UICard:
	var card := UICard.new("Your drivers", "Click a driver to open the profile")
	for driver in GameState.drivers_of_team(team.id):
		var stats := SeasonRecords.stats_of(driver.id)
		var row := InfoRow.new("#%d  %s" % [driver.number, driver.full_name()],
			tr("Championship P%d · %d points") % [GameState.championship_position(driver.id), stats.points],
			tr("Morale: %s") % tr(DriverStatus.level_label(driver.morale)), UIStyle.meter_color(driver.morale))
		row.set_leading_image(UIStyle.portrait(driver, 40))
		row.make_clickable()
		row.clicked.connect(shell.open_driver.bind(driver.id))
		card.add_row(row)
	return card


## Indices to show: the top 3 plus the places next to the given ones.
## -1 marks a gap ("···").
func _compact_indices(count: int, mine: Array) -> Array:
	var keep := {}
	for i in mini(3, count):
		keep[i] = true
	for m in mine:
		for k in [m - 1, m, m + 1]:
			if k >= 0 and k < count:
				keep[k] = true
	var sorted := keep.keys()
	sorted.sort()
	var out := []
	var last := -1
	for k in sorted:
		if k - last > 1:
			out.append(-1)
		out.append(k)
		last = k
	return out


func _dots() -> Label:
	var dots := Label.new()
	dots.text = "···"
	dots.theme_type_variation = &"SmallLabel"
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return dots


func _team_standings_card() -> UICard:
	var s: SeriesData = GameState.series[GameState.player_team().series_id]
	var table := SeasonRecords.team_standings(s)
	var card := UICard.new("Constructors' standings", tr("after round %d") % GameState.resolved_rounds)
	var mine := -1
	for i in table.size():
		if table[i][0] == GameState.player_team_id:
			mine = i
	var leader: int = table[0][1] if not table.is_empty() else 0
	for i in _compact_indices(table.size(), [mine]):
		if i < 0:
			card.add(_dots())
			continue
		var team: TeamData = GameState.teams[table[i][0]]
		var gap := tr("leader") if i == 0 else "−%d" % (leader - table[i][1])
		var row := InfoRow.new("%d.  %s" % [i + 1, team.name], gap, tr("%d pts") % table[i][1],
			UIStyle.ACCENT if team.id == GameState.player_team_id else UIStyle.TEXT, true)
		row.make_clickable()
		row.clicked.connect(func(): shell.navigate(&"standings", {"tab": 1}))
		card.add_row(row)
	if mine > 0:
		var ahead: TeamData = GameState.teams[table[mine - 1][0]]
		card.add_padded(_note(tr("%s is %d pts ahead · click for the full table") % [ahead.name, table[mine - 1][1] - table[mine][1]]), 6, 0)
	return card


func _standings_card() -> UICard:
	var card := UICard.new("Drivers' championship", tr("after round %d") % GameState.resolved_rounds)
	var standings := GameState.driver_standings(GameState.player_team().series_id)
	var mine := []
	for i in standings.size():
		if GameState.drivers[standings[i]].team_id == GameState.player_team_id:
			mine.append(i)
	var leader: int = GameState.season_stats[standings[0]].points if not standings.is_empty() else 0
	for i in _compact_indices(standings.size(), mine):
		if i < 0:
			card.add(_dots())
			continue
		var driver: DriverData = GameState.drivers[standings[i]]
		var team: TeamData = GameState.teams.get(driver.team_id)
		var points: int = GameState.season_stats[driver.id].points
		var gap := tr("leader") if i == 0 else "−%d" % (leader - points)
		var row := InfoRow.new("%d.  %s" % [i + 1, driver.full_name()], "%s · %s" % [team.short_name if team else "–", gap],
			tr("%d pts") % points, UIStyle.ACCENT if driver.team_id == GameState.player_team_id else UIStyle.TEXT, true)
		row.set_leading_image(UIStyle.portrait(driver, 26))
		row.make_clickable()
		row.clicked.connect(shell.open_driver.bind(driver.id))
		card.add_row(row)
	if standings.is_empty():
		card.add_padded(_note("No race yet this season."), 6, 0)
	var own := GameState.drivers_of_team(GameState.player_team_id)
	if own.size() >= 2:
		var a: DriverSeasonStats = GameState.season_stats.get(own[0].id)
		var b: DriverSeasonStats = GameState.season_stats.get(own[1].id)
		if a and b and a.head_to_head_rounds > 0:
			card.add_padded(_note(tr("%s vs. %s: quali %d–%d · race %d–%d") % [own[0].last_name, own[1].last_name,
				a.quali_ahead, b.quali_ahead, a.race_ahead, b.race_ahead]), 6, 0)
	return card
