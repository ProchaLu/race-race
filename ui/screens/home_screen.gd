## Start screen: next race, your drivers and the championship top 10.
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
	left.add_child(_drivers_card(team))
	row.add_child(left)
	row.add_child(_standings_card())


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
		card.add_row(FactRow.new("Date", Calendar.format_date(s.race_days[next])))
	else:
		card.add_row(FactRow.new("Round", tr("Season finished")))
	var button := Button.new()
	button.text = "Watch a test race (Test Ring)"
	button.icon = UIStyle.icon("play")
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(func(): EventBus.race_requested.emit(&"test_ring"))
	card.add_padded(button, 12, 0)
	return card


func _drivers_card(team: TeamData) -> UICard:
	var card := UICard.new("Your drivers", "Click a driver to open the profile")
	for driver in GameState.drivers_of_team(team.id):
		var stats: DriverSeasonStats = GameState.season_stats[driver.id]
		var row := InfoRow.new("#%d  %s" % [driver.number, driver.full_name()],
			tr("Championship P%d · %d points") % [GameState.championship_position(driver.id), stats.points],
			tr("Morale: %s") % tr(DriverStatus.level_label(driver.morale)), UIStyle.meter_color(driver.morale))
		row.set_leading_image(UIStyle.portrait(driver, 40))
		row.make_clickable()
		row.clicked.connect(shell.open_driver.bind(driver.id))
		card.add_row(row)
	return card


func _standings_card() -> UICard:
	var card := UICard.new("Drivers' championship", "Top 10")
	card.custom_minimum_size.x = 460
	card.size_flags_horizontal = Control.SIZE_SHRINK_END
	var standings := GameState.driver_standings(GameState.player_team().series_id)
	for i in mini(10, standings.size()):
		var driver: DriverData = GameState.drivers[standings[i]]
		var team: TeamData = GameState.teams[driver.team_id]
		var points: int = GameState.season_stats[driver.id].points
		var row := InfoRow.new("%d.  %s" % [i + 1, driver.full_name()], team.name,
			tr("%d pts") % points, UIStyle.ACCENT if driver.team_id == GameState.player_team_id else UIStyle.TEXT)
		row.set_leading_image(UIStyle.portrait(driver, 30))
		row.make_clickable()
		row.clicked.connect(shell.open_driver.bind(driver.id))
		card.add_row(row)
	return card
