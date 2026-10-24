## Championship tables (mockup r2_season.html, screen 1): constructors with
## gap, trend and prize money if the season ended now; drivers with a
## results grid per round. Cards below show what is at stake.
extends UIScreen

enum Tab { DRIVERS, TEAMS }

var _tab: Tab = Tab.TEAMS
var _series: SeriesData
var _page: VBoxContainer


func setup(args: Dictionary) -> void:
	_tab = args.get("tab", Tab.TEAMS)
	_series = GameState.series[GameState.player_team().series_id]
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	var tabs := Segmented.new([tr("Drivers"), tr("Teams")], _tab)
	tabs.custom_minimum_size.x = 260
	tabs.changed.connect(func(i):
		shell.update_args({"tab": i})
		shell.refresh_current())
	toolbar.add_child(tabs)
	var info := Label.new()
	info.text = tr("Season %d · after round %d of %d") % [Calendar.year, GameState.resolved_rounds, _series.calendar.size()]
	info.theme_type_variation = &"MutedLabel"
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toolbar.add_child(info)
	_page.add_child(toolbar)

	if _tab == Tab.TEAMS:
		_page.add_child(_teams_card())
	else:
		_page.add_child(_drivers_card())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	row.add_child(_fight_card())
	row.add_child(_available_card())
	row.add_child(_duel_card())
	_page.add_child(row)


func screen_title() -> String:
	return "Standings"


func nav_section() -> StringName:
	return &"standings"


## Points scored in the newest round, per driver (for the trend arrows).
func _last_round_points() -> Dictionary:
	var out := {}
	for id in GameState.season_stats:
		var st: DriverSeasonStats = GameState.season_stats[id]
		if not st.results.is_empty() and st.results.back().round == GameState.resolved_rounds:
			out[id] = SeasonRecords.points_for(_series, st.results.back().finish) if st.results.back().finish > 0 else 0
	return out


func _tree(cols: Array, rows: int) -> Tree:
	var tree := Tree.new()
	tree.hide_root = true
	tree.columns = cols.size()
	tree.column_titles_visible = true
	tree.select_mode = Tree.SELECT_ROW
	tree.scroll_vertical_enabled = false
	tree.custom_minimum_size.y = 34 + rows * 29
	for i in cols.size():
		tree.set_column_title(i, cols[i][0])
		tree.set_column_custom_minimum_width(i, cols[i][1])
		tree.set_column_expand(i, cols[i].size() > 2 and cols[i][2])
		tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	return tree


# --- Constructors ------------------------------------------------------------

func _teams_card() -> UICard:
	var card := UICard.new("Constructors' championship")
	var table := SeasonRecords.team_standings(_series)
	var last := _last_round_points()
	var before := []
	for entry in table:
		var lost := 0
		for d in GameState.drivers_of_team(entry[0]):
			lost += last.get(d.id, 0)
		before.append([entry[0], entry[1] - lost])
	before.sort_custom(func(a, b): return a[1] > b[1])
	var prev_rank := before.map(func(e): return e[0])

	var cols := [["Pos", 74], ["Team", 220, true], ["Points", 80], ["Gap", 80], ["Wins", 66], ["Podiums", 86],
		["Best", 70], ["Drivers", 260, true], ["Prize money now", 150]]
	var tree := _tree(cols, table.size())
	var root := tree.create_item()
	var leader: int = table[0][1] if not table.is_empty() else 0
	for i in table.size():
		var team: TeamData = GameState.teams[table[i][0]]
		var wins := 0
		var podiums := 0
		var best := 99
		var names := []
		for d in GameState.drivers_of_team(team.id):
			var st: DriverSeasonStats = GameState.season_stats.get(d.id)
			if not st:
				continue
			wins += st.wins
			podiums += st.podiums
			for r in st.results:
				if r.finish > 0:
					best = mini(best, r.finish)
			names.append("%s %d" % [d.last_name, st.points])
		var item := tree.create_item(root)
		var moved: int = prev_rank.find(team.id) - i
		item.set_text(0, "%d %s" % [i + 1, "▲" if moved > 0 else ("▼" if moved < 0 else "")])
		item.set_custom_color(0, UIStyle.GOOD if moved > 0 else (UIStyle.BAD if moved < 0 else UIStyle.TEXT))
		item.set_text(1, team.name)
		item.set_custom_color(1, team.primary_color.lerp(UIStyle.TEXT, 0.25))
		item.set_text(2, str(table[i][1]))
		item.set_text(3, "–" if i == 0 else "−%d" % (leader - table[i][1]))
		item.set_text(4, str(wins))
		item.set_text(5, str(podiums))
		item.set_text(6, "P%d" % best if best < 99 else "–")
		item.set_text(7, " · ".join(names))
		item.set_text(8, "$%dM" % Season.PRIZE_MONEY_M[mini(i, Season.PRIZE_MONEY_M.size() - 1)])
		for col in [2, 3, 4, 5, 6, 8]:
			item.set_custom_font(col, UIStyle.font(&"mono"))
		if team.id == GameState.player_team_id:
			for col in cols.size():
				item.set_custom_bg_color(col, Color(UIStyle.ACCENT, 0.10))
			item.set_custom_font(1, UIStyle.font(&"body_semibold"))
	card.add(tree)
	card.add_padded(_note("▲▼ = change since the last race · prize money is paid after the final round"), 6, 2)
	return card


# --- Drivers -----------------------------------------------------------------

func _drivers_card() -> UICard:
	var card := UICard.new("Drivers' championship")
	var ids := GameState.driver_standings(_series.id)
	var cols := [["Pos", 54], ["Driver", 190, true], ["Team", 66], ["Pts", 66], ["Gap", 72], ["Wins", 62],
		["Pod.", 58], ["Poles", 62], ["DNF", 56]]
	var first_round_col := cols.size()
	for r in _series.calendar.size():
		cols.append([str(r + 1), 40])
	var tree := _tree(cols, ids.size())
	# Narrow round cells: less padding than the theme's default.
	tree.add_theme_constant_override("inner_item_margin_left", 5)
	tree.add_theme_constant_override("inner_item_margin_right", 5)
	var root := tree.create_item()
	var leader: int = GameState.season_stats[ids[0]].points if not ids.is_empty() else 0
	for i in ids.size():
		var d: DriverData = GameState.drivers[ids[i]]
		var st: DriverSeasonStats = GameState.season_stats[d.id]
		var team: TeamData = GameState.teams.get(d.team_id)
		var item := tree.create_item(root)
		item.set_metadata(0, d.id)
		item.set_text(0, str(i + 1))
		item.set_custom_color(0, UIStyle.position_color(i + 1) if i < 3 else UIStyle.TEXT)
		item.set_text(1, d.full_name())
		item.set_text(2, team.short_name if team else "–")
		if team:
			item.set_custom_color(2, team.primary_color)
		item.set_text(3, str(st.points))
		item.set_text(4, "–" if i == 0 else "−%d" % (leader - st.points))
		item.set_text(5, str(st.wins))
		item.set_text(6, str(st.podiums))
		item.set_text(7, str(st.poles))
		item.set_text(8, str(st.retirements))
		for col in [3, 4, 5, 6, 7, 8]:
			item.set_custom_font(col, UIStyle.font(&"mono"))
		for r in st.results:
			var col: int = first_round_col + r.round - 1
			if col >= cols.size():
				continue
			item.set_text(col, str(r.finish) if r.finish > 0 else "R")
			item.set_text_alignment(col, HORIZONTAL_ALIGNMENT_CENTER)
			item.set_custom_font(col, UIStyle.font(&"mono_semibold"))
			item.set_custom_bg_color(col, _cell_color(r.finish))
			item.set_custom_color(col, UIStyle.BG if r.finish >= 1 and r.finish <= 3 else UIStyle.TEXT)
			item.set_tooltip_text(col, tr("%s: started P%d, %s") % [GameState.tracks[r.track_id].name, r.grid,
				tr("finished P%d") % r.finish if r.finish > 0 else tr("retired")])
		if d.team_id == GameState.player_team_id:
			item.set_custom_color(1, UIStyle.ACCENT)
			item.set_custom_font(1, UIStyle.font(&"body_semibold"))
	tree.item_selected.connect(func():
		var sel := tree.get_selected()
		if sel:
			shell.open_driver(sel.get_metadata(0)))
	card.add(tree)
	card.add_padded(_note("Gold = win · light = podium · green = points · grey = no points · R = retired. Hover a cell for the race."), 6, 2)
	return card


func _cell_color(finish: int) -> Color:
	if finish == 1:
		return UIStyle.PODIUM[0]
	if finish >= 2 and finish <= 3:
		return UIStyle.PODIUM[1].darkened(0.1)
	if finish >= 4 and finish <= 10:
		return Color(UIStyle.OK, 0.42)
	if finish == 0:
		return Color(UIStyle.BAD, 0.35)
	return Color(UIStyle.LINE, 0.9)


# --- What is at stake --------------------------------------------------------

func _fight_card() -> UICard:
	var card := UICard.new("Constructors' fight", "every point is money")
	var table := SeasonRecords.team_standings(_series)
	var i := 0
	for k in table.size():
		if table[k][0] == GameState.player_team_id:
			i = k
	card.add_row(FactRow.new("Your position", "P%d" % (i + 1), "", true, UIStyle.ACCENT))
	if i > 0:
		card.add_row(FactRow.new("To the team ahead", tr("−%d pts") % (table[i - 1][1] - table[i][1]),
			GameState.teams[table[i - 1][0]].name, true, UIStyle.WARN))
	if i < table.size() - 1:
		card.add_row(FactRow.new("Lead over the team behind", tr("+%d pts") % (table[i][1] - table[i + 1][1]),
			GameState.teams[table[i + 1][0]].name, true, UIStyle.GOOD))
	var prize := Season.PRIZE_MONEY_M
	if i > 0:
		card.add_row(FactRow.new("One place higher is worth", "+$%dM" % (prize[i - 1] - prize[i]), "", true, UIStyle.GOOD))
	return card


func _available_card() -> UICard:
	var card := UICard.new("Points still available")
	var left := _series.calendar.size() - GameState.resolved_rounds
	var per_team: int = left * (_series.points_table[0] + _series.points_table[1])
	card.add_row(FactRow.new("Rounds left", str(left), "", true))
	card.add_row(FactRow.new("Per team", tr("%d pts") % per_team, "", true))
	card.add_row(FactRow.new("Per driver", tr("%d pts") % (left * _series.points_table[0]), "", true))
	var table := SeasonRecords.team_standings(_series)
	var possible := table.filter(func(e): return table[0][1] - e[1] <= per_team).size()
	card.add_row(FactRow.new("Title still possible for", tr("%d teams") % possible, "", true))
	return card


func _duel_card() -> UICard:
	var card := UICard.new("Teammate duel")
	var own := GameState.drivers_of_team(GameState.player_team_id)
	if own.size() < 2:
		card.add_padded(_note("You need two race drivers for the duel."), 6, 4)
		return card
	var a: DriverSeasonStats = GameState.season_stats.get(own[0].id)
	var b: DriverSeasonStats = GameState.season_stats.get(own[1].id)
	if not a or not b or a.head_to_head_rounds == 0:
		card.add_padded(_note("No race together yet this season."), 6, 4)
		return card
	card.add_row(FactRow.new(tr("%s vs. %s") % [own[0].last_name, own[1].last_name], "", ""))
	card.add_row(FactRow.new("Qualifying", "%d – %d" % [a.quali_ahead, b.quali_ahead], "", true))
	card.add_row(FactRow.new("Race", "%d – %d" % [a.race_ahead, b.race_ahead], "", true))
	card.add_row(FactRow.new("Points", "%d – %d" % [a.points, b.points], "", true))
	return card


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
