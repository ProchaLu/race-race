## Academy (R7, docs/youth_model.md 4 and 9–13): the young drivers the team
## trains, with their seat, results, mood and contract; offers of other
## academies; and the list of juniors to sign (free, karting kids our scouts
## found, F3, F2, the watchlist). Every junior opens his profile, where offers,
## seats, training and the way to F1 are decided.
extends UIScreen

enum Tab { ACADEMY, JUNIORS }
## Junior list filter: free, karting, F3, F2, watchlist.
const FILTERS := ["Free juniors", "Karting", "Apex F3", "Apex F2", "Watchlist"]

## Shown once after a click failed (the screen reloads after the click).
static var _error := ""
static var _filter := 0

var _team: TeamData
var _page: VBoxContainer
var _tab: Tab = Tab.ACADEMY


func setup(args: Dictionary) -> void:
	_team = GameState.player_team()
	_tab = args.get("tab", Tab.ACADEMY)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)
	var tabs := Segmented.new([tr("Academy"), tr("Junior drivers")], _tab)
	tabs.custom_minimum_size.x = 360
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tabs.changed.connect(func(i):
		shell.update_args({"tab": i})
		shell.refresh_current())
	_page.add_child(tabs)
	if _error != "":
		_page.add_child(YouthUI.error(tr(_error)))
		_error = ""
	if _tab == Tab.ACADEMY:
		_page.add_child(_stats_row())
		if Academy.places(_team) == 0:
			_page.add_child(YouthUI.small(tr("No academy yet. Build one at the headquarters to get places for young drivers.")))
		_page.add_child(_roster_card())
		if not GameState.junior_offers.is_empty():
			_page.add_child(_offers_card())
	else:
		_page.add_child(_juniors_card())


func screen_title() -> String:
	return "Academy"


func nav_section() -> StringName:
	return &"academy"


func _stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	var head := Academy.head(_team)
	var fees := _team.academy_driver_ids.size() * Academy.FEE_PER_MONTH
	var stats := [
		["%d / %d" % [_team.academy_driver_ids.size(), Academy.places(_team)], tr("Places used"), UIStyle.TEXT],
		["%d / %d" % [Academy.placed_in(_team, Youth.F3), Academy.MAX_PLACED[Youth.F3]], tr("Seats in Apex F3"), UIStyle.TEXT],
		["%d / %d" % [Academy.placed_in(_team, Youth.F2), Academy.MAX_PLACED[Youth.F2]], tr("Seats in Apex F2"), UIStyle.TEXT],
		[head.full_name() if head else tr("None"), tr("Academy head · youth development %d / 20") % DriverAttributes.to_display(
			Academy.head_skill(_team)), UIStyle.TEXT],
		[UIStyle.money(fees), tr("Academy cost per month"), UIStyle.TEXT],
	]
	for stat in stats:
		var card := UICard.new()
		card.add_padded(BigStat.new(stat[0], stat[1], stat[2]), 12, 12)
		row.add_child(card)
	return row


func _roster_card() -> UICard:
	var card := UICard.new(tr("Academy drivers"), tr("click a driver to plan his season"))
	var people := Academy.drivers(_team)
	if people.is_empty():
		card.add_padded(YouthUI.small(tr("No academy driver yet. Find juniors under \"Junior drivers\" or with the scouts.")), 8, 8)
		return card
	for d in people:
		card.add_row(_roster_row(d))
	return card


func _roster_row(d: DriverData) -> HoverRow:
	var row := HoverRow.new()
	var key := Youth.series_key(d)
	var last := Youth.last_result(d)
	var flags := []
	if d.academy_promise != &"":
		flags.append(tr("promise"))
	if d.young_driver_test:
		flags.append(tr("young driver test"))
	if d.mentor_id != &"":
		flags.append(tr("mentor"))
	if d.academy_focus != &"":
		flags.append(tr(Academy.FOCUS[d.academy_focus][0]))
	var sub := "%s · %d · %s" % [YouthUI.where(d), d.age(Calendar.year), d.nationality]
	if not flags.is_empty():
		sub += " · " + ", ".join(flags)
	var box := YouthUI.box_with(YouthUI.name_box(d.full_name(), sub), [
		YouthUI.figure("P%d" % Youth.position(d) if Youth.position(d) > 0 else "–",
			tr("%d pts") % Youth.season_points(d) if key != &"" else tr("no races")),
		YouthUI.figure("–" if last < 0 else (tr("DNF") if last == 0 else "P%d" % last), tr("last race")),
		YouthUI.ability_stars(d),
		YouthUI.potential_stars(d),
		YouthUI.figure("%d" % d.morale, tr("mood"), YouthUI.mood_color(d.morale)),
		YouthUI.figure("%d" % d.academy_until if d.academy_until > 0 else "–", tr("contract"),
			UIStyle.BAD if d.academy_until > 0 and d.academy_until <= Calendar.year else Color(0, 0, 0, 0)),
	])
	var manage := YouthUI.accent(tr("Plan"))
	manage.pressed.connect(func(): shell.open_driver(d.id))
	box.add_child(manage)
	row.add_child(box)
	return row


func _offers_card() -> UICard:
	var card := UICard.new(tr("Offers for our juniors"), tr("from other academies"))
	for offer in GameState.junior_offers:
		var d: DriverData = GameState.drivers.get(offer.driver_id)
		var buyer: TeamData = GameState.teams.get(offer.team_id)
		if not d or not buyer:
			continue
		var row := HoverRow.new()
		var box := YouthUI.box_with(YouthUI.name_box(d.full_name(), tr("%s · open until %s") % [buyer.name,
			Calendar.format_date(offer.until_day)]), [YouthUI.figure(UIStyle.money(offer.fee), tr("fee"))])
		box.add_child(YouthUI.button(tr("Accept"), func():
			_error = Academy.accept_offer(offer)
			shell.refresh_current()))
		box.add_child(YouthUI.button(tr("Decline"), func():
			Academy.decline_offer(offer)
			shell.refresh_current()))
		row.add_child(box)
		card.add_row(row)
	return card


## Juniors to look at: free, karting kids we found, F3, F2 or the watchlist.
func _juniors_card() -> UICard:
	var card := UICard.new(tr("Junior drivers"), tr("open a profile to make an offer · up to %d years") % Academy.INTAKE_MAX_AGE)
	var tabs := Segmented.new(FILTERS.map(func(f): return tr(f)), _filter)
	tabs.changed.connect(func(i):
		_filter = i
		shell.refresh_current())
	card.add_padded(tabs, 8, 4)
	var people: Array[DriverData] = []
	for d in GameState.drivers.values():
		if d.retired or not Youth.is_youth(d) or d.academy_team_id == _team.id or not Youth.is_visible(d):
			continue
		var ok := false
		match _filter:
			0:
				ok = d.series_id == Youth.POOL and d.team_id == &""
			1:
				ok = Youth.is_karting(d)
			2:
				ok = d.series_id == Youth.F3
			3:
				ok = d.series_id == Youth.F2
			4:
				ok = GameState.shortlist.has(d.id)
		if ok:
			people.append(d)
	people.sort_custom(func(a, b):
		var ka := Knowledge.level(a) >= 40
		var kb := Knowledge.level(b) >= 40
		if ka != kb:
			return ka
		return _estimate(a) > _estimate(b))
	if people.is_empty():
		var empty := "Our scouts have not found any karting kid yet. Send a scout on a region trip or to a karting race." if _filter == 1 \
			else ("The watchlist is empty. Mark juniors with the star." if _filter == 4 else "Nobody here right now.")
		card.add_padded(YouthUI.small(tr(empty)), 8, 8)
		return card
	for d in people.slice(0, 30):
		card.add_row(_junior_row(d))
	if people.size() > 30:
		card.add_padded(YouthUI.small(tr("%d more not shown.") % (people.size() - 30)), 4, 8)
	return card


## What the team believes a junior is worth: middle of both star ranges.
func _estimate(d: DriverData) -> float:
	var a := Knowledge.star_range(d, &"ability", d.overall())
	var p := Knowledge.star_range(d, &"potential", d.potential)
	return (a.x + a.y) / 2.0 + (p.x + p.y) / 4.0


func _junior_row(d: DriverData) -> HoverRow:
	var row := HoverRow.new()
	var sub := "%s · %d · %s" % [YouthUI.where(d), d.age(Calendar.year), d.nationality]
	if d.academy_team_id != &"":
		sub += " · " + tr("academy of %s") % YouthUI.academy_name(d)
	var pos := Youth.position(d)
	var box := YouthUI.box_with(YouthUI.name_box(d.full_name(), sub), [
		YouthUI.figure("P%d" % pos if pos > 0 else "–", tr("%d pts") % Youth.season_points(d) if Youth.series_key(d) != &"" else tr("no races")),
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
