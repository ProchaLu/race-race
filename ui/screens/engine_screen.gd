## Engine (docs/engine_model.md 10, mockup r5_engine.html): the power unit
## with its five components and values against the field, the engine units
## and their mileage, the engine lab (licence or own engine) and the
## contracts with the manufacturers.
extends UIScreen

enum Tab { OVERVIEW, UNITS, LAB, CONTRACTS }

static var _years := 2
static var _new_component: int = 0
static var _new_focus: int = 0
static var _new_aggressive := false

var _tab: Tab = Tab.OVERVIEW
var _team: TeamData
var _m: ManufacturerData
var _page: VBoxContainer
var _component: StringName = &"ice"


func setup(args: Dictionary) -> void:
	_tab = args.get("tab", Tab.OVERVIEW)
	_component = StringName(str(args.get("component", "ice")))
	_team = GameState.player_team()
	_m = Engines.manufacturer_of(_team)
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
	var tabs := Segmented.new([tr("Overview"), tr("Units"), tr("Engine lab"), tr("Contracts")], _tab)
	tabs.custom_minimum_size.x = 520
	tabs.changed.connect(func(i):
		shell.update_args({"tab": i})
		shell.refresh_current())
	toolbar.add_child(tabs)
	var info := Label.new()
	info.text = tr("%s · %s engine · spent on engine development: %s") % [_m.name if _m else "–",
		tr(_type_name(_team.engine_deal.get("type", "customer"))), UIStyle.money(GameState.engine_spending.get(_team.id, 0))]
	info.theme_type_variation = &"MutedLabel"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toolbar.add_child(info)
	_page.add_child(toolbar)
	if _m == null:
		_page.add_child(_note_card("This team has no engine yet."))
		return
	match _tab:
		Tab.OVERVIEW:
			_build_overview()
		Tab.UNITS:
			_build_units()
		Tab.LAB:
			_build_lab()
		_:
			_build_contracts()


func screen_title() -> String:
	return "Engine"


func nav_section() -> StringName:
	return &"engine"


static func _type_name(type: String) -> String:
	return {"customer": "Customer", "licence": "Licence", "works": "Works"}.get(type, type)


# --- Overview ------------------------------------------------------------------------

func _build_overview() -> void:
	var row := _row()
	var comps := Engines.available_components(_team)
	var info := {}
	for c in PowerUnit.COMPONENTS:
		var spec := Engines.latest_spec(_m, c, _team)
		var r := _component_rank(c)
		info[c] = ["Spec %d · %d" % [spec.version, roundi(_average(comps[c]))], _rank_color(r, _rivals().size())]
	var pu := UICard.new(tr("Power unit · %s") % _m.name, "click a component · colour = rank among the manufacturers")
	pu.size_flags_stretch_ratio = 1.2
	var diagram := PuDiagram.new(info)
	diagram.selected = _component
	diagram.custom_minimum_size.y = 240
	diagram.component_selected.connect(func(c):
		shell.update_args({"component": c})
		shell.refresh_current())
	pu.add_padded(diagram, 8, 4)
	var spec := Engines.latest_spec(_m, _component, _team)
	pu.add_section(tr("%s · Spec %d") % [tr(PowerUnit.name_of(_component)), spec.version])
	for value in PowerUnit.values_of(_component):
		pu.add_row(FactRow.new(tr(PowerUnit.VALUE_NAMES[value]), "%d" % roundi(spec.values[value]), "", true))
	var place := _component_rank(_component)
	pu.add_row(FactRow.new("Rank among the manufacturers", "P%d of %d" % [place, _rivals().size()], "", true,
		_rank_color(place, _rivals().size())))
	for e in Engines.upcoming(_team).filter(func(entry): return entry[0] == _component):
		pu.add_row(FactRow.new(tr("Next: Spec %d") % e[1].version, tr("for us from %s") % Engines.round_label(e[2]), "", true, UIStyle.ACCENT))
	row.add_child(pu)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UIStyle.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_values_card())
	right.add_child(_contract_card())
	row.add_child(right)
	_page.add_child(row)


func _values_card() -> UICard:
	var card := UICard.new("Engine values", "line = field average · P = rank of the teams")
	var values := Engines.available_values(_team)
	var teams: int = GameState.series[_team.series_id].team_ids.size()
	for value in PowerUnit.VALUES:
		var v: float = values[value]
		var rank := Engines.rank(_team, value)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var l := Label.new()
		l.text = tr(PowerUnit.VALUE_NAMES[value])
		l.theme_type_variation = &"MutedLabel"
		l.custom_minimum_size.x = 140
		line.add_child(l)
		line.add_child(RatingBar.new(v, _rank_color(rank, teams), Engines.field_average(value)))
		line.add_child(_number("%d" % roundi(v), 44))
		var r := _number("P%d" % rank, 44)
		r.add_theme_color_override("font_color", _rank_color(rank, teams))
		line.add_child(r)
		card.add_padded(line, 3, 3)
	var car := _team.car
	var life := PowerUnit.life_km(values[&"reliability"])
	card.add_row(FactRow.new("Power unit mass", "%.1f kg" % car.pu_mass_kg, "", true))
	card.add_row(FactRow.new("Fuel use", "%+d %%" % roundi((PowerUnit.fuel_factor(values[&"efficiency"]) - 1.0) * 100), "vs an average engine", true))
	card.add_row(FactRow.new("Unit lifetime", "%d km" % roundi(life), tr("about %d race weekends") % roundi(life / 720.0), true))
	if car.engine_cooling_fit != 0:
		card.add_row(FactRow.new("Integration with the chassis", "%+d cooling · %+.0f kg" % [car.engine_cooling_fit, car.engine_mass_fit],
			"works team" if car.engine_cooling_fit > 0 else "first season with this engine", true,
			UIStyle.GOOD if car.engine_cooling_fit > 0 else UIStyle.WARN))
	return card


func _contract_card() -> UICard:
	var deal := _team.engine_deal
	var card := UICard.new("Contract")
	card.add_row(FactRow.new("Manufacturer", _m.name, "", false))
	card.add_row(FactRow.new("Type", tr(_type_name(deal.get("type", ""))) + tr(" engine"), "", false))
	var price: int = deal.get("price", 0)
	card.add_row(FactRow.new("Price", tr("%s per year") % UIStyle.money(price) if price > 0 else tr("own engine"), "", true))
	card.add_row(FactRow.new("Runs until", tr("end of %d") % deal.get("until", Calendar.year), "", true))
	if _m.works_team_id != _team.id:
		var rel: int = _m.relationship.get(_team.id, 50)
		card.add_row(FactRow.new("Relationship with the manufacturer", "%d" % rel,
			tr("new specs for us %d race(s) after the works team") % Engines.customer_delay(_m, _team),
			true, UIStyle.GOOD if rel >= 65 else (UIStyle.WARN if rel < 40 else UIStyle.TEXT)))
	var next := _team.engine_next
	if not next.is_empty():
		var nm: ManufacturerData = GameState.manufacturers[next.manufacturer]
		card.add_row(FactRow.new("Next season", "%s · %s · %s" % [nm.name, tr(_type_name(next.type)), UIStyle.money(next.price)],
			"", false, UIStyle.ACCENT))
	return card


func _component_rank(c: StringName) -> int:
	var own := _average(Engines.latest_spec(_m, c, _team).values)
	var place := 1
	for other in _rivals():
		if other != _m and _average(Engines.latest_spec(other, c, GameState.teams.get(other.works_team_id)).values) > own + 0.01:
			place += 1
	return place


## Manufacturers that race this season (no unused licence copies).
func _rivals() -> Array:
	return GameState.manufacturers.values().filter(func(m): return not Engines.teams_of(m).is_empty())


static func _average(values: Dictionary) -> float:
	var total := 0.0
	for v in values.values():
		total += v
	return total / maxf(values.size(), 1)


# --- Units ---------------------------------------------------------------------------

func _build_units() -> void:
	var row := _row()
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UIStyle.GAP)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	for d in GameState.drivers_of_team(_team.id):
		left.add_child(_driver_units(d))
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UIStyle.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var plan := UICard.new("Engine chief", "recommendation for the next race")
	for d in GameState.drivers_of_team(_team.id):
		var rec := Engines.recommend_new_unit(_team, d.id)
		plan.add_row(FactRow.new(d.full_name(), tr("new unit") if rec[0] else tr("keep the unit"), tr(rec[1]), false,
			UIStyle.ACCENT if rec[0] else UIStyle.TEXT))
	plan.add_padded(_small(tr("You decide in the race weekend planning. %d units per driver and season are in the contract; every extra unit costs %s. Grid penalties come with the rules (R9).")
		% [PowerUnit.UNITS_PER_SEASON, UIStyle.money(PowerUnit.EXTRA_UNIT_COST)]), 6, 4)
	right.add_child(plan)
	var updates := UICard.new("Spec updates", tr("from %s") % _m.name)
	var coming := Engines.upcoming(_team)
	if coming.is_empty():
		updates.add_padded(_small("No new spec announced."), 6, 4)
	for e in coming:
		updates.add_row(FactRow.new(tr("%s Spec %d") % [tr(PowerUnit.name_of(e[0])), e[1].version],
			tr("for us from %s") % Engines.round_label(e[2]), "", true, UIStyle.ACCENT))
	var running := EngineLab.projects_of(_m.id)
	if not running.is_empty():
		updates.add_section("In development")
		for p in running:
			updates.add_row(FactRow.new(p.label(), "%s %d %%" % [tr(EngineProject.PHASE_NAMES[p.phase]), roundi(p.phase_progress() * 100)], "", false))
	right.add_child(updates)
	row.add_child(right)
	_page.add_child(row)


func _driver_units(d: DriverData) -> UICard:
	var units := Engines.units_of(_team, d.id)
	var card := UICard.new(d.full_name(), tr("%d of %d units used") % [units.size(), PowerUnit.UNITS_PER_SEASON])
	for u: EngineUnit in units:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		line.add_child(_number("#%d" % u.number, 34))
		var spec := _small(u.spec_label())
		spec.autowrap_mode = TextServer.AUTOWRAP_OFF
		spec.custom_minimum_size.x = 250
		spec.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		line.add_child(spec)
		var used := u.used()
		var meter := Meter.new(minf(used, 1.0) * 100.0, UIStyle.BAD if used > 0.9 else (UIStyle.WARN if used > 0.7 else UIStyle.GOOD), 8)
		meter.marker = 70.0
		meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(meter)
		line.add_child(_number("%d / %d km" % [roundi(u.km), roundi(u.life_km())], 130))
		var state := tr("Fitted") if u.fitted else tr("Spare")
		var color := UIStyle.GOOD if u.fitted else UIStyle.MUTED
		if u.is_dead():
			state = tr("Finished")
			color = UIStyle.BAD
		elif u.damage > 0.0:
			state += tr(" · damaged %d %%") % roundi(u.damage * 100)
			color = UIStyle.WARN
		var s := _small(state)
		s.autowrap_mode = TextServer.AUTOWRAP_OFF
		s.custom_minimum_size.x = 140
		s.size_flags_horizontal = Control.SIZE_SHRINK_END
		s.add_theme_color_override("font_color", color)
		line.add_child(s)
		card.add_padded(line, 3, 3)
	if units.is_empty():
		card.add_padded(_small("No unit yet – one is fitted before the next race."), 6, 4)
	return card


# --- Engine lab ----------------------------------------------------------------------

func _build_lab() -> void:
	for p in GameState.engine_projects:
		if p.is_programme() and p.team_id == _team.id:
			_page.add_child(_programme_card(p))
	if not EngineLab.can_develop(_team):
		_page.add_child(_customer_lab())
		return
	var top := _row()
	var cap := UICard.new("Engine department", _m.name)
	var caps := EngineLab.capacities(_m)
	cap.add_row(FactRow.new("Engine engineers", tr("%d · room for %d") % [CarDevelopment.headcount(_team, &"engine"),
		Facilities.room_for(_team, &"engine")], "", true))
	cap.add_row(FactRow.new("Engine design capacity", "%.2f" % caps[&"design"], "", true))
	cap.add_row(FactRow.new("Dyno capacity", tr("%.2f · engine works level %d") % [caps[&"dyno"], Facilities.level(_team, &"engine")], "", true))
	cap.add_row(FactRow.new("Endurance accuracy after 3 distances", "±%.1f" % EngineLab.endurance_error(_m, 3), "", true))
	var delegate := CheckButton.new()
	delegate.text = "Engine chief runs the development"
	delegate.button_pressed = GameState.delegate_engine_development
	delegate.toggled.connect(func(on):
		GameState.delegate_engine_development = on
		shell.refresh_current())
	cap.add_padded(delegate, 6, 4)
	top.add_child(cap)
	top.add_child(_new_project_card())
	_page.add_child(top)
	var projects := EngineLab.projects_of(_m.id).filter(func(p): return not p.is_programme())
	if projects.is_empty():
		_page.add_child(_note_card("No engine project running."))
	for p in projects:
		_page.add_child(EngineLabCard.new(p, shell.refresh_current))


func _new_project_card() -> UICard:
	var card := UICard.new("New engine project", "a new spec for one component")
	card.add_section("Component")
	var comp_seg := Segmented.new(PowerUnit.COMPONENTS.map(func(c): return tr(PowerUnit.COMPONENT_SHORT[c])), _new_component)
	comp_seg.changed.connect(func(i):
		_new_component = i
		shell.refresh_current())
	card.add_padded(comp_seg, 2, 4)
	var component: StringName = PowerUnit.COMPONENTS[_new_component]
	var focuses: Array = PowerUnit.values_of(component)
	_new_focus = mini(_new_focus, focuses.size() - 1)
	card.add_section("Focus")
	var focus_seg := Segmented.new(focuses.map(func(v): return tr(PowerUnit.VALUE_NAMES[v])), _new_focus)
	focus_seg.changed.connect(func(i): _new_focus = i)
	card.add_padded(focus_seg, 2, 4)
	var aggressive := CheckButton.new()
	aggressive.text = "Aggressive (bigger ideas, more hidden weaknesses)"
	aggressive.button_pressed = _new_aggressive
	aggressive.toggled.connect(func(on): _new_aggressive = on)
	card.add_padded(aggressive, 2, 4)
	var used: int = _m.specs_this_season.get(component, 0)
	card.add_row(FactRow.new("Specs this season", "%d of %d" % [used, Engines.SPECS_PER_SEASON], "", true))
	card.add_row(FactRow.new("Ideas", UIStyle.money(EngineLab.CONCEPT_COST), "then rig, dyno, endurance and production step by step", true))
	var reason := EngineLab.cannot_start(_team, component)
	var actions := _row()
	var why := _small(tr(reason))
	why.add_theme_color_override("font_color", UIStyle.BAD)
	actions.add_child(why)
	var go := _accent(tr("Start project"))
	go.disabled = reason != ""
	go.pressed.connect(func():
		var r := RandomNumberGenerator.new()
		r.randomize()
		var focus: StringName = focuses[_new_focus]
		EngineLab.start(EngineLab.plan(_m, component, String(focus), _new_aggressive, r))
		shell.refresh_current())
	actions.add_child(go)
	card.add_padded(actions, 8, 4)
	return card


## Customers cannot develop: what the manufacturer is working on, and the ways in.
func _customer_lab() -> Control:
	var row := _row()
	var info := UICard.new("Engine development", "customer engine")
	info.add_padded(_small(tr("As a customer of %s we race their engine – they develop it, we get their new specs. To develop ourselves we need a licence engine (engine works level 1) or our own power unit (engine works level 3, power unit programme).") % _m.name), 6, 4)
	info.add_row(FactRow.new("Engine works", tr("level %d") % Facilities.level(_team, &"engine"), "", true))
	var lic := Button.new()
	lic.text = tr("Licence offers in Contracts")
	lic.pressed.connect(func():
		shell.update_args({"tab": Tab.CONTRACTS})
		shell.refresh_current())
	info.add_padded(lic, 6, 2)
	var reason := EngineLab.programme_reason(_team)
	var actions := _row()
	var why := _small(tr(reason) if reason != "" else tr("Power unit programme: about %s over ~2 seasons; 20 %% now.") % UIStyle.money(EngineLab.PROGRAMME_COST))
	if reason != "":
		why.add_theme_color_override("font_color", UIStyle.MUTED)
	actions.add_child(why)
	var start := _accent(tr("Start power unit programme"))
	start.disabled = reason != ""
	start.pressed.connect(func():
		EngineLab.start_programme(_team)
		shell.refresh_current())
	actions.add_child(start)
	info.add_padded(actions, 8, 4)
	row.add_child(info)
	var roadmap := UICard.new(tr("%s in development") % _m.name, "their projects – we get the results")
	var running := EngineLab.projects_of(_m.id)
	if running.is_empty():
		roadmap.add_padded(_small("Nothing announced."), 6, 4)
	for p in running:
		roadmap.add_row(FactRow.new(p.label(), "%s %d %%" % [tr(EngineProject.PHASE_NAMES[p.phase]), roundi(p.phase_progress() * 100)], "", false))
	row.add_child(roadmap)
	return row


func _programme_card(p: EngineProject) -> UICard:
	var card := UICard.new("Power unit programme", "all five components from scratch")
	var line := _row()
	line.add_child(Meter.new(p.phase_progress() * 100.0, UIStyle.ACCENT, 6))
	line.add_child(_number("%d %%" % roundi(p.phase_progress() * 100), 60))
	card.add_padded(line, 6, 4)
	var rate := EngineLab.programme_rate(_team)
	card.add_row(FactRow.new("Days of work left", "%d" % roundi(p.work_left),
		tr("at %.2f per day ≈ %d days") % [rate, roundi(p.work_left / maxf(rate, 0.05))], true))
	card.add_row(FactRow.new("Spent", UIStyle.money(p.cost_spent), tr("of about %s") % UIStyle.money(EngineLab.PROGRAMME_COST), true))
	card.add_padded(_small("When it is done, our own engine replaces the customer engine from the next season."), 4, 4)
	return card


# --- Contracts -----------------------------------------------------------------------

func _build_contracts() -> void:
	var row := _row()
	row.add_child(_contract_card())
	var requests := UICard.new("Requests & offers", "for next season")
	var offers := Engines.offers_of(_team)
	if offers.is_empty():
		requests.add_padded(_small("No requests yet."), 6, 4)
	for o in offers:
		var m: ManufacturerData = GameState.manufacturers[o.manufacturer]
		var line := _row()
		var text := "%s · %s · %d %s" % [m.name, tr(_type_name(o.type)), o.years, tr("year(s)")]
		var state := ""
		match o.state:
			"pending":
				state = tr("answer in %d days") % maxi(0, o.answer_day - Calendar.day)
			"offer":
				state = tr("%s per year · valid %d days") % [UIStyle.money(o.price), o.expires_day - Calendar.day]
			"refused":
				state = tr("declined: %s") % tr(o.reason)
			"signed":
				state = tr("signed")
			_:
				state = tr(o.state)
		line.add_child(_small(text + " — " + state))
		if o.state == "offer":
			var accept := _accent(tr("Sign"))
			var offer: Dictionary = o
			accept.pressed.connect(func():
				if Engines.accept_offer(offer) == "":
					shell.refresh_current())
			line.add_child(accept)
		requests.add_padded(line, 3, 3)
	row.add_child(requests)
	_page.add_child(row)

	var market := UICard.new("Engine supply next season", "values of the newest works spec")
	var open := Engines.window_open()
	var tools := _row()
	tools.add_child(_small(tr("Negotiation window open – ask for offers.") if open else tr("Negotiations open on 1 July.")))
	tools.add_child(_small(tr("Contract length")))
	var years := Segmented.new([tr("1 year"), tr("2 years"), tr("3 years")], _years - 1)
	years.custom_minimum_size.x = 260
	years.changed.connect(func(i): _years = i + 1)
	tools.add_child(years)
	market.add_padded(tools, 6, 4)
	var head := _row()
	for t in ["Manufacturer", "Power", "Effic.", "Reliab.", "Weight", "Driv.", "Price / year", "Places", ""]:
		var l := Label.new()
		l.text = tr(t)
		l.uppercase = true
		l.theme_type_variation = &"SectionLabel"
		l.custom_minimum_size.x = 200 if t == "Manufacturer" else 70
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL if t in ["Manufacturer", ""] else Control.SIZE_SHRINK_BEGIN
		head.add_child(l)
	market.add_padded(head, 4, 0)
	for m: ManufacturerData in GameState.manufacturers.values():
		if m.licensed_from != &"" or m.works_team_id == _team.id:
			continue
		var line := _row()
		var n := Label.new()
		n.text = m.name + ("  ·  " + tr("current") if m == _m else "")
		n.custom_minimum_size.x = 200
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if m == _m:
			n.add_theme_color_override("font_color", UIStyle.RAIN)
		line.add_child(n)
		var values := Engines.manufacturer_values(m)
		for v in PowerUnit.VALUES:
			line.add_child(_number("%d" % roundi(values[v]), 70))
		line.add_child(_number(UIStyle.money(m.price), 70))
		var places := Engines.places_next_season(m)
		var p := _number("%d of %d" % [maxi(0, places), m.max_teams], 70)
		p.add_theme_color_override("font_color", UIStyle.GOOD if places > 0 else UIStyle.BAD)
		line.add_child(p)
		var buttons := HBoxContainer.new()
		buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.alignment = BoxContainer.ALIGNMENT_END
		var ask := Button.new()
		ask.text = tr("Ask for an offer")
		ask.disabled = not open
		var manufacturer: ManufacturerData = m
		ask.pressed.connect(func():
			Engines.request_offer(_team, manufacturer, "customer", _years)
			shell.refresh_current())
		buttons.add_child(ask)
		var lic := Button.new()
		lic.text = tr("Licence")
		lic.tooltip_text = tr("Develop the engine yourself · needs engine works level 1 · about %s per year") % UIStyle.money(int(m.price * Engines.LICENCE_FACTOR))
		lic.disabled = not open or Facilities.level(_team, &"engine") < 1
		lic.pressed.connect(func():
			Engines.request_offer(_team, manufacturer, "licence", _years)
			shell.refresh_current())
		buttons.add_child(lic)
		line.add_child(buttons)
		market.add_padded(line, 3, 3)
	market.add_padded(_small(tr("Manufacturers decide by places, your car's level and the relationship. A switch costs one season of adaptation (−3 cooling, +3 kg). Without a new deal the sporting director extends the current one for a year.")), 6, 4)
	_page.add_child(market)
	if Engines.is_works(_team) and _team.engine_deal.get("type", "") == "works":
		var customers := UICard.new("Our customers", "they pay us per year")
		var list := Engines.teams_of(_m).filter(func(t): return t != _team)
		if list.is_empty():
			customers.add_padded(_small("No customers yet – AI teams consider our engine in the negotiation window."), 6, 4)
		for t: TeamData in list:
			customers.add_row(FactRow.new(t.name, UIStyle.money(t.engine_deal.get("price", 0)), tr("until %d") % t.engine_deal.get("until", 0), true))
		_page.add_child(customers)


# --- Helpers -------------------------------------------------------------------------

func _rank_color(rank: int, count: int) -> Color:
	var share := float(rank - 1) / maxf(count - 1, 1)
	if share <= 0.25:
		return UIStyle.GOOD
	if share <= 0.5:
		return UIStyle.OK
	if share <= 0.75:
		return UIStyle.WARN
	return UIStyle.BAD


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	return row


func _accent(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = &"AccentButton"
	return b


func _number(text: String, width: int) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"NumberLabel"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.custom_minimum_size.x = width
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _note_card(text: String) -> UICard:
	var card := UICard.new("Engine")
	card.add_padded(_small(text), 8, 4)
	return card
