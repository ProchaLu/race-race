## Detailed race result (mockup r2_weekend.html, step 4): summary for your
## team, full classification, lap time chart with safety car and rain
## phases, every pit stop of your team, all tyre strategies and the events.
## Rounds played before the first full weekend only have the basic result.
extends UIScreen

var _round: int
var _summary: Dictionary
var _page: VBoxContainer
var _series: SeriesData


func setup(args: Dictionary) -> void:
	_series = GameState.series[GameState.player_team().series_id]
	_round = args.get("round", GameState.resolved_rounds)
	for r in GameState.race_results:
		if r.round == _round:
			_summary = r
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)
	if _summary.is_empty():
		_build_basic()
		return
	_page.add_child(_summary_card())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var left := _classification_card()
	left.size_flags_stretch_ratio = 1.45
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UIStyle.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_lap_chart_card())
	right.add_child(_pit_stop_card())
	right.add_child(_events_card())
	row.add_child(right)
	_page.add_child(row)
	_page.add_child(_stints_card())
	_page.add_child(_links())


func screen_title() -> String:
	if _round < 1 or _round > _series.calendar.size():
		return "Race result"
	return tr("Race result – %s") % GameState.tracks[_series.calendar[_round - 1]].name


func nav_section() -> StringName:
	return &"calendar"


# --- Summary -----------------------------------------------------------------

func _summary_card() -> UICard:
	var track: TrackData = GameState.tracks[_summary.track_id]
	var winner: DriverData = GameState.drivers[_summary.entries[0].driver_id]
	var card := UICard.new(tr("Round %d · %s") % [_round, track.name],
		tr("Winner %s · %d laps · %d overtakes") % [winner.full_name(), _summary.laps, _summary.overtakes])
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 0)
	var team_points := 0
	for e in _summary.entries:
		if e.team_id != GameState.player_team_id:
			continue
		team_points += e.points
		var d: DriverData = GameState.drivers[e.driver_id]
		var value := "P%d" % e.finish if e.finish > 0 else tr("DNF")
		var tile := StatusTile.new(d.last_name, value, UIStyle.position_color(e.finish))
		var sub := tr("from P%d · %d pts") % [e.grid, e.points] if e.finish > 0 else tr("lap %d · %s") % [e.retire_lap, tr(e.retire_reason)]
		tile.set_breakdown(_driver_breakdown(e))
		_add_sub(tile, sub)
		tiles.add_child(tile)
	var target: Dictionary = _summary.get("target", {})
	if not target.is_empty():
		var tile := StatusTile.new("Weekend target", tr("Achieved") if target.achieved else tr("Missed"),
			UIStyle.GOOD if target.achieved else UIStyle.BAD)
		_add_sub(tile, tr(target.name) + (tr(" · morale %+d") % target.morale if target.morale != 0 else ""))
		tiles.add_child(tile)
	var standings := SeasonRecords.team_standings(_series)
	var position := 0
	for i in standings.size():
		if standings[i][0] == GameState.player_team_id:
			position = i + 1
	if _round == GameState.resolved_rounds and position > 0:
		var tile := StatusTile.new("Constructors", "P%d" % position, UIStyle.ACCENT)
		var gap := ""
		if position > 1:
			gap = tr(" · gap to P%d: %d pts") % [position - 1, standings[position - 2][1] - standings[position - 1][1]]
		_add_sub(tile, tr("+%d pts") % team_points + gap)
		tiles.add_child(tile)
	card.add_padded(tiles, 4, 4)
	return card


func _add_sub(tile: StatusTile, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.get_child(0).add_child(l)


## Where the race time went (seconds over the race, from the simulation).
func _driver_breakdown(e: Dictionary) -> Breakdown:
	var d: DriverData = GameState.drivers[e.driver_id]
	var b := Breakdown.new(tr("%s – race in numbers") % d.full_name())
	b.add("Setup", "%d %%" % roundi(e.setup))
	b.add("Overtakes", str(e.overtakes))
	b.add("Mistakes", str(e.mistakes), Breakdown.Tone.NEGATIVE if e.mistakes > 0 else Breakdown.Tone.NEUTRAL)
	b.add("Pit stops", str(e.stops.size()))
	b.add("Best lap", UIStyle.lap_time(e.best_lap))
	var decisions: Dictionary = _summary.get("decisions", {}).get("drivers", {}).get(e.driver_id, {})
	if not decisions.is_empty():
		b.add("Practice", tr(decisions.programme))
		b.add("Briefing", tr(decisions.briefing))
	return b


# --- Classification ----------------------------------------------------------

func _classification_card() -> UICard:
	var fl: Dictionary = _summary.fastest_lap
	var fl_driver: DriverData = GameState.drivers.get(fl.driver_id)
	var card := UICard.new("Classification", tr("fastest lap %s · %s") % [UIStyle.lap_time(fl.time), fl_driver.last_name if fl_driver else "–"])
	var cols := [["Pos", 58], ["Driver", 170], ["Team", 66], ["Grid", 60], ["+/−", 60], ["Gap", 140], ["Best lap", 110], ["Stops", 66], ["Pts", 56]]
	var tree := _tree(cols, _summary.entries.size())
	var root := tree.create_item()
	var winner_time: float = _summary.entries[0].time
	for e in _summary.entries:
		var d: DriverData = GameState.drivers[e.driver_id]
		var team: TeamData = GameState.teams[e.team_id]
		var item := tree.create_item(root)
		item.set_metadata(0, e.driver_id)
		item.set_text(0, str(e.finish) if e.finish > 0 else "DNF")
		item.set_custom_color(0, UIStyle.position_color(e.finish))
		item.set_text(1, d.full_name())
		item.set_text(2, team.short_name)
		item.set_custom_color(2, team.primary_color)
		item.set_text(3, str(e.grid))
		if e.finish > 0:
			var delta: int = e.grid - e.finish
			item.set_text(4, ("▲%d" % delta) if delta > 0 else (("▼%d" % -delta) if delta < 0 else "–"))
			item.set_custom_color(4, UIStyle.GOOD if delta > 0 else (UIStyle.BAD if delta < 0 else UIStyle.MUTED))
		if e.finish == 1:
			item.set_text(5, UIStyle.race_time(winner_time))
		elif e.finish == 0:
			item.set_text(5, tr(e.retire_reason))
			item.set_custom_color(5, UIStyle.BAD)
			item.set_tooltip_text(5, tr("Retired on lap %d") % e.retire_lap)
		elif e.laps_down > 0:
			item.set_text(5, tr("+%d lap(s)") % e.laps_down)
		else:
			item.set_text(5, "+%.3f" % e.gap)
		item.set_text(6, UIStyle.lap_time(e.best_lap))
		if e.driver_id == fl.driver_id:
			item.set_custom_color(6, UIStyle.FASTEST)
		item.set_text(7, str(e.stops.size()))
		item.set_text(8, str(e.points) if e.points > 0 else "")
		for col in [0, 3, 5, 6, 7, 8]:
			item.set_custom_font(col, UIStyle.font(&"mono"))
		if e.team_id == GameState.player_team_id:
			item.set_custom_color(1, UIStyle.ACCENT)
			item.set_custom_font(1, UIStyle.font(&"body_semibold"))
	tree.item_selected.connect(func():
		var sel := tree.get_selected()
		if sel:
			shell.open_driver(sel.get_metadata(0)))
	card.add(tree)
	return card


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
		tree.set_column_expand(i, i == 1)
		tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	return tree


# --- Lap times, pit stops, stints, events ------------------------------------

func _lap_chart_card() -> UICard:
	var card := UICard.new("Lap times", "winner vs. your drivers")
	var winner: Dictionary = _summary.entries[0]
	var shown := [winner]
	for e in _summary.entries:
		if e.team_id == GameState.player_team_id and e != winner:
			shown.append(e)
	var lines := []
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 16)
	var own_index := 0
	for e in shown:
		var team: TeamData = GameState.teams[e.team_id]
		var color := team.primary_color
		var dashed := false
		if e.team_id == GameState.player_team_id:
			dashed = own_index == 1
			if dashed:
				color = color.lightened(0.35)
			own_index += 1
		var stops := []
		for s in e.stops:
			stops.append(s.lap)
		lines.append({"times": e.lap_times, "color": color, "dashed": dashed, "stops": stops})
		var label := GameState.drivers[e.driver_id].last_name + (tr(" (winner)") if e == winner else "")
		legend.add_child(_legend_item(label, color))
	var bands := _bands()
	legend.add_child(_legend_item("Safety car", UIStyle.SAFETY_CAR))
	legend.add_child(_legend_item("Rain", UIStyle.RAIN))
	card.add_padded(LapChart.new(lines, bands, _summary.laps), 6, 2)
	card.add_padded(legend, 2, 0)
	card.add_padded(_note("● = pit stop · very slow laps (pit stops, safety car) are cut off at the top"), 2, 2)
	return card


## Safety car / VSC / red flag phases and rain from the lap weather.
func _bands() -> Array:
	var out := []
	for p in _summary.phases:
		out.append({"from": p.from_lap, "to": p.get("to_lap", p.from_lap), "color": UIStyle.SAFETY_CAR if p.kind != "RED" else UIStyle.BAD, "label": p.kind})
	var start := -1
	var weather: Array = _summary.weather
	for i in weather.size():
		var raining: bool = weather[i][1] > 0.1
		if raining and start < 0:
			start = i + 1
		elif not raining and start >= 0:
			out.append({"from": start, "to": i, "color": UIStyle.RAIN, "label": tr("RAIN")})
			start = -1
	if start >= 0:
		out.append({"from": start, "to": weather.size(), "color": UIStyle.RAIN, "label": tr("RAIN")})
	return out


func _legend_item(text: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(12, 3)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	row.add_child(l)
	return row


func _pit_stop_card() -> UICard:
	var card := UICard.new("Pit stops · your team")
	var own := []
	var fastest := INF
	for e in _summary.entries:
		for s in e.stops:
			fastest = minf(fastest, s.stationary)
			if e.team_id == GameState.player_team_id:
				own.append([e.driver_id, s])
	if own.is_empty():
		card.add_padded(_note("No pit stops."), 6, 4)
		return card
	var cols := [["Driver", 100], ["Lap", 56], ["Tyres", 190], ["Standstill", 104], ["Pit lane", 92], ["Note", 120]]
	var tree := _tree(cols, own.size())
	tree.set_column_expand(1, false)
	tree.set_column_expand(5, true)
	var root := tree.create_item()
	var total := 0.0
	for pair in own:
		var s: Dictionary = pair[1]
		total += s.stationary
		var item := tree.create_item(root)
		item.set_text(0, GameState.drivers[pair[0]].last_name)
		item.set_text(1, str(s.lap))
		item.set_text(2, "%s → %s" % [tr(UIStyle.compound_name(s.from)), tr(UIStyle.compound_name(s.to))])
		item.set_custom_color(2, UIStyle.compound_color(s.to))
		item.set_text(3, "%.2f s" % s.stationary)
		item.set_custom_color(3, UIStyle.BAD if s.stationary > 4.0 else (UIStyle.GOOD if s.stationary < 2.4 else UIStyle.TEXT))
		item.set_text(4, "%.1f s" % s.lane)
		var note := tr(s.issue) if s.issue != "" and s.issue != "None" else ""
		if s.get("flag", "GREEN") == "SAFETY_CAR":
			note = tr("under safety car") if note == "" else note
		elif s.get("flag", "GREEN") == "VSC":
			note = tr("under VSC") if note == "" else note
		item.set_text(5, note)
		for col in [1, 3, 4]:
			item.set_custom_font(col, UIStyle.font(&"mono"))
	card.add(tree)
	var crew := _staff_name(StaffData.Role.PIT_CREW_CHIEF)
	card.add_padded(_note(tr("Fastest stop of the race: %.2f s · your crew average: %.2f s") % [fastest, total / own.size()]
		+ (tr(" (pit crew chief %s)") % crew if crew != "" else "")), 6, 2)
	return card


func _stints_card() -> UICard:
	var card := UICard.new("Tyre strategies", "all drivers, in finishing order")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	for e in _summary.entries:
		var name_label := Label.new()
		name_label.text = GameState.drivers[e.driver_id].last_name
		name_label.custom_minimum_size.x = 120
		name_label.theme_type_variation = &"SmallLabel"
		if e.team_id == GameState.player_team_id:
			name_label.add_theme_color_override("font_color", UIStyle.ACCENT)
		grid.add_child(name_label)
		var bar := StintBar.new(StintBar.from_laps(e.compounds), _summary.laps, 14)
		grid.add_child(bar)
	card.add_padded(grid, 6, 4)
	var legend := HFlowContainer.new()
	legend.add_theme_constant_override("h_separation", 16)
	for id in [&"soft", &"medium", &"hard", &"inter", &"wet"]:
		legend.add_child(_legend_item(UIStyle.compound_name(id), UIStyle.compound_color(id)))
	card.add_padded(legend, 2, 2)
	return card


const EVENT_ICONS := {"sc": "SC", "vsc": "VSC", "red": "RED", "green": "▶", "retired": "✕", "failure": "!",
	"contact": "!", "damage": "!", "mistake": "~", "puncture": "!", "pit_issue": "⏱", "start": "▶"}


func _events_card() -> UICard:
	var card := UICard.new("Race events")
	var shown := 0
	for ev in _summary.events:
		if not EVENT_ICONS.has(ev.kind):
			continue
		var own := false
		if ev.driver != &"" and GameState.drivers.has(ev.driver):
			own = GameState.drivers[ev.driver].team_id == GameState.player_team_id
		var color := UIStyle.ACCENT if own else (UIStyle.SAFETY_CAR if ev.kind in ["sc", "vsc"] else UIStyle.TEXT)
		var row := FactRow.new(tr("Lap %d") % ev.lap, ev.text, "", false, color)
		card.add_row(row)
		shown += 1
		if shown >= 14:
			break
	if shown == 0:
		card.add_padded(_note("A quiet race."), 6, 4)
	return card


func _links() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_END
	for entry in [["Standings", "trophy", &"standings"], ["Calendar", "calendar", &"calendar"], ["Home", "house", &"home"]]:
		var b := Button.new()
		b.text = entry[0]
		b.icon = UIStyle.icon(entry[1])
		var id: StringName = entry[2]
		b.pressed.connect(func(): shell.navigate(id))
		row.add_child(b)
	return row


# --- Rounds without detailed data --------------------------------------------

func _build_basic() -> void:
	if _round < 1 or _round > _series.calendar.size():
		var card := UICard.new("Race result")
		card.add_padded(_note("This round has not been raced yet."), 8, 4)
		_page.add_child(card)
		return
	var rows := []
	for id in GameState.season_stats:
		for r in GameState.season_stats[id].results:
			if r.round == _round:
				rows.append([id, r])
	rows.sort_custom(func(a, b):
		var fa: int = a[1].finish if a[1].finish > 0 else 99
		var fb: int = b[1].finish if b[1].finish > 0 else 99
		return fa < fb)
	var card := UICard.new("Classification", "detailed data from the first full race weekend on")
	var tree := _tree([["Pos", 58], ["Driver", 200], ["Team", 70], ["Grid", 60], ["Pts", 56]], rows.size())
	var root := tree.create_item()
	for pair in rows:
		var d: DriverData = GameState.drivers.get(pair[0])
		if not d:
			continue
		var r: Dictionary = pair[1]
		var item := tree.create_item(root)
		item.set_metadata(0, d.id)
		item.set_text(0, str(r.finish) if r.finish > 0 else "DNF")
		item.set_custom_color(0, UIStyle.position_color(r.finish))
		item.set_text(1, d.full_name())
		var team: TeamData = GameState.teams.get(d.team_id)
		item.set_text(2, team.short_name if team else "–")
		item.set_text(3, str(r.grid))
		item.set_text(4, str(SeasonRecords.points_for(_series, r.finish)) if r.finish > 0 and r.finish <= 10 else "")
		if d.team_id == GameState.player_team_id:
			item.set_custom_color(1, UIStyle.ACCENT)
	tree.item_selected.connect(func():
		var sel := tree.get_selected()
		if sel:
			shell.open_driver(sel.get_metadata(0)))
	card.add(tree)
	_page.add_child(card)
	_page.add_child(_links())


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _staff_name(role: StaffData.Role) -> String:
	for s in GameState.staff_of_team(GameState.player_team_id):
		if s.role == role:
			return s.full_name()
	return ""
