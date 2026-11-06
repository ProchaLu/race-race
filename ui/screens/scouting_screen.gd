## Scouting (R7, docs/youth_model.md 5 and 9): the scout network (chief scout
## and hired scouts), assignments – a series, a region trip that also finds
## karting kids, a race visit, one junior – and the juniors the team knows.
## Ranges narrow with every week; a weak scout can get a person wrong.
extends UIScreen

## Shown once after a click failed (the screen reloads after the click).
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
		_page.add_child(YouthUI.error(tr(_error)))
		_error = ""
	if Scouting.capacity(_team) == 0:
		_page.add_child(YouthUI.small(tr("No scouting office yet. Build one at the headquarters: the chief scout works from it.")))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UIStyle.GAP)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.add_child(_scouts_card())
	left.add_child(_assignments_card())
	left.add_child(_races_card())
	left.add_child(_single_card())
	left.add_child(_running_card())
	columns.add_child(left)
	var right := _reports_card()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	_page.add_child(columns)


func screen_title() -> String:
	return "Scouting"


func nav_section() -> StringName:
	return &"scouting"


func _stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var found := 0
	for d in Youth.karting():
		if GameState.discovered.has(d.id):
			found += 1
	var stats := [
		["%d" % Scouting.capacity(_team), tr("Scouting office level"), UIStyle.TEXT],
		["%d / %d" % [Scouting.busy(_team), Scouting.capacity(_team)], tr("Assignments running"), UIStyle.TEXT],
		["%d" % Scouting.scouts(_team).size(), tr("Scouts (chief scout included)"), UIStyle.TEXT],
		["%d" % _known_count(), tr("Juniors we know"), UIStyle.GOOD],
		["%d / %d" % [found, Youth.karting().size()], tr("Karting kids found"), UIStyle.ACCENT],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


# --- Scouts --------------------------------------------------------------------------

func _scouts_card() -> UICard:
	var card := UICard.new(tr("Scout network"), tr("%d of %d extra scouts · one per office level") % [Scouting.hired(_team),
		Scouting.max_scouts(_team)])
	var people := Scouting.scouts(_team)
	if people.is_empty():
		card.add_padded(YouthUI.small(tr("No scout yet. Hire a chief scout under Staff, or a scout below.")), 8, 8)
	for s in people:
		card.add_row(_scout_row(s, true))
	if Scouting.capacity(_team) > 0:
		card.add_section(tr("Scouts for hire"))
		for s in Scouting.candidates():
			card.add_row(_scout_row(s, false))
	return card


func _scout_row(s: StaffData, ours: bool) -> HoverRow:
	var row := HoverRow.new()
	var status := ""
	if ours:
		status = tr("free")
		for a in GameState.scout_assignments:
			if a.get("scout_id", &"") == s.id:
				status = tr(a.label)
	var role := tr(StaffRoles.name_of(s.role))
	var home := tr("home: %s") % tr(Scouting.REGION_NAMES[Scouting.region_of(s)])
	var sub := "%s · %s · %s" % [role, home, status] if ours else "%s · %s" % [role, home]
	var box := YouthUI.box_with(YouthUI.name_box(s.full_name(), sub), [
		YouthUI.figure("%d" % DriverAttributes.to_display(s.attribute(&"judging_ability")), tr("ability eye")),
		YouthUI.figure("%d" % DriverAttributes.to_display(s.attribute(&"judging_potential")), tr("potential eye")),
		YouthUI.figure("%d" % DriverAttributes.to_display(s.attribute(&"network")), tr("network")),
	])
	if ours and s.role == StaffData.Role.SCOUT:
		box.add_child(YouthUI.button(tr("Dismiss"), func():
			Scouting.dismiss(s)
			shell.refresh_current()))
	elif not ours:
		box.add_child(YouthUI.figure(UIStyle.money(Scouting.salary_of(s)), tr("per year")))
		var full := Scouting.hired(_team) >= Scouting.max_scouts(_team)
		var hire := YouthUI.accent(tr("Hire"))
		hire.disabled = full
		hire.tooltip_text = tr("No room for another scout. A larger scouting office makes room.") if full else ""
		hire.pressed.connect(func():
			_error = Scouting.hire(_team, s)
			shell.refresh_current())
		box.add_child(hire)
	row.add_child(box)
	return row


# --- Assignments ---------------------------------------------------------------------

func _assignments_card() -> UICard:
	var card := UICard.new(tr("Start an assignment"), tr("the best free scout goes, the weeks pass"))
	for series_id in [Youth.F3, Youth.F2]:
		var ids := Scouting.targets_of_series(series_id)
		card.add_row(_option_row(&"series", tr("All %s juniors") % Youth.SERIES_NAMES[series_id], ids, &""))
	for region in Scouting.REGIONS:
		var ids := Scouting.targets_of_region(region)
		card.add_row(_option_row(&"region", tr("Trip to %s") % tr(Scouting.REGION_NAMES[region]), ids, region))
	return card


func _option_row(kind: StringName, label: String, ids: Array[StringName], region: StringName) -> HoverRow:
	var row := HoverRow.new()
	var todo := Scouting.todo_of(_team, ids)
	var finds := Scouting.discoveries_of(Scouting.free_scout(_team), region) if kind == &"region" else 0
	var sub := tr("also looks for new karting kids") if kind == &"region" else tr("most valuable first")
	if todo.is_empty() and finds == 0:
		row.add_child(YouthUI.box_with(YouthUI.name_box(label, sub), [
			YouthUI.figure(tr("All scouted") if not ids.is_empty() else tr("Nobody"), tr("%d juniors") % ids.size())]))
		return row
	var cost := Scouting.FEE_PER_TARGET * todo.size() + (Scouting.DISCOVERY_FEE if kind == &"region" else 0)
	var weeks := maxi(Scouting.weeks_needed(_team, todo), Scouting.MIN_REGION_WEEKS if kind == &"region" else 1)
	var figures := [YouthUI.figure("%d" % todo.size(), tr("to scout"))]
	if kind == &"region":
		figures.append(YouthUI.figure("~%d" % finds, tr("new kids")))
	figures.append(YouthUI.figure(UIStyle.money(cost), tr("cost")))
	figures.append(YouthUI.figure("%d" % weeks, tr("weeks")))
	var box := YouthUI.box_with(YouthUI.name_box(label, sub), figures)
	var button := YouthUI.accent(tr("Scout"))
	var reason := _blocked_reason()
	button.disabled = reason != ""
	button.tooltip_text = reason
	button.pressed.connect(func():
		_error = Scouting.start(_team, kind, label, ids, region)
		shell.refresh_current())
	box.add_child(button)
	row.add_child(box)
	return row


## Race visits: a scout watches the next race weekend of a series in person.
func _races_card() -> UICard:
	var card := UICard.new(tr("Watch a race"), tr("next race weekend · everybody there becomes better known"))
	for key in [Youth.F2, Youth.F3] + Youth.KART_SERIES.values():
		var row := HoverRow.new()
		var karting := not Youth.SERIES.has(key)
		var sub := tr("finds up to %d karting kids") % Scouting.WATCH_DISCOVERIES if karting \
			else tr("+%d knowledge for every driver") % Scouting.WATCH_GAIN
		var box := YouthUI.box_with(YouthUI.name_box(tr(Youth.series_name(key)), sub), [
			YouthUI.figure(UIStyle.money(Scouting.watch_fee(key)), tr("cost"))])
		var going := GameState.scout_assignments.any(func(a): return a.team_id == _team.id and a.kind == &"race" and a.series == key)
		var button := YouthUI.accent(tr("Going") if going else tr("Send"))
		var reason := tr("A scout is already going to that race.") if going else _blocked_reason()
		button.disabled = reason != ""
		button.tooltip_text = reason
		button.pressed.connect(func():
			_error = Scouting.watch(_team, key)
			shell.refresh_current())
		box.add_child(button)
		row.add_child(box)
		card.add_row(row)
	return card


## Single juniors the team does not know well yet: watchlist first, then by points.
func _single_card() -> UICard:
	var card := UICard.new(tr("Single junior"), tr("one person, a scout goes alone"))
	var people := []
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and not _is_own(d) and Youth.is_visible(d):
			var one: Array[StringName] = [d.id]
			if not Scouting.todo_of(_team, one).is_empty():
				people.append(d)
	people.sort_custom(func(a, b):
		var wa := GameState.shortlist.has(a.id)
		var wb := GameState.shortlist.has(b.id)
		if wa != wb:
			return wa
		return Youth.season_points(a) > Youth.season_points(b))
	for d in people.slice(0, 6):
		var one: Array[StringName] = [d.id]
		card.add_row(_option_row(&"driver", d.full_name(), one, &""))
	if people.is_empty():
		card.add_padded(YouthUI.small(tr("Every junior is well known to us.")), 8, 8)
	return card


func _running_card() -> UICard:
	var card := UICard.new(tr("Running assignments"), tr("week by week"))
	var running := GameState.scout_assignments.filter(func(a): return a.team_id == _team.id)
	if running.is_empty():
		card.add_padded(YouthUI.small(tr("No assignment running.")), 8, 8)
		return card
	for a in running:
		var row := HoverRow.new()
		var s: StaffData = GameState.staff.get(a.get("scout_id", &""))
		var progress := tr("at the next race") if a.kind == &"race" else tr("week %d of %d") % [a.weeks_total - a.weeks_left, a.weeks_total]
		row.add_child(YouthUI.box_with(YouthUI.name_box(tr(a.label), s.full_name() if s else tr("no scout")), [
			YouthUI.figure(progress, tr("progress"))]))
		card.add_row(row)
	return card


func _reports_card() -> UICard:
	var card := UICard.new(tr("Juniors we know"), tr("range of ability and potential, the scout's advice"))
	var people := []
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and not _is_own(d) and Youth.is_visible(d) and Knowledge.level(d) >= 40:
			people.append(d)
	people.sort_custom(func(a, b): return _estimate(a) > _estimate(b))
	if people.is_empty():
		card.add_padded(YouthUI.small(tr("No report yet. Start an assignment on the left.")), 8, 8)
		return card
	for d in people.slice(0, 30):
		card.add_row(_report_row(d))
	return card


func _report_row(d: DriverData) -> HoverRow:
	var row := HoverRow.new()
	var sub := "%s · %d · %s" % [YouthUI.where(d), d.age(Calendar.year), d.nationality]
	if d.academy_team_id != &"":
		sub += " · " + tr("academy of %s") % YouthUI.academy_name(d)
	var box := YouthUI.box_with(YouthUI.name_box(d.full_name(), sub), [
		YouthUI.ability_stars(d),
		YouthUI.potential_stars(d),
		YouthUI.figure(tr(Scouting.recommendation(d)), tr("advice")),
	])
	box.add_child(YouthUI.watch_button(d, shell.refresh_current))
	var profile := YouthUI.accent(tr("Profile"))
	profile.pressed.connect(func(): shell.open_driver(d.id))
	box.add_child(profile)
	row.add_child(box)
	return row


# --- Helpers -----------------------------------------------------------------

func _is_own(d: DriverData) -> bool:
	return d.academy_team_id == _team.id


func _estimate(d: DriverData) -> float:
	var a := Knowledge.star_range(d, &"ability", d.overall())
	var p := Knowledge.star_range(d, &"potential", d.potential)
	return (a.x + a.y) / 2.0 + (p.x + p.y) / 4.0


func _known_count() -> int:
	var n := 0
	for d in GameState.drivers.values():
		if Youth.is_youth(d) and not d.retired and not _is_own(d) and Youth.is_visible(d) and Knowledge.level(d) >= 40:
			n += 1
	return n


## Why no scout can be sent, "" when one can.
func _blocked_reason() -> String:
	return tr(Scouting.blocked_reason(_team))
