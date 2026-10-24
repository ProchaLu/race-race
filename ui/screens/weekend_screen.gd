## The race weekend (mockup r2_weekend.html, steps 1–3): before practice
## the weekend target, practice programmes and team orders; after
## qualifying the strategy, rain gamble and driver briefing; in the race the
## key moments. Every decision can be left to the responsible staff member.
extends UIScreen

const STEPS := ["Practice", "Qualifying", "Race"]

var _weekend: RaceWeekend
var _page: VBoxContainer


func setup(_args: Dictionary) -> void:
	_weekend = Season.weekend_of_today()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(_page)
	if not _weekend:
		_page.add_child(_no_weekend_card())
		return
	_page.add_child(_header())
	match _weekend.stage:
		RaceWeekend.Stage.PLANNING:
			_build_planning()
		RaceWeekend.Stage.STRATEGY:
			_build_strategy()
		_:
			_build_moment()


func screen_title() -> String:
	return _weekend.track.name if _weekend else "Race weekend"


func nav_section() -> StringName:
	return &"calendar"


func _rebuild() -> void:
	shell.refresh_current()


# --- Header ------------------------------------------------------------------

func _header() -> UICard:
	var w := _weekend
	var card := UICard.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var round_label := Label.new()
	round_label.text = tr("Round %d of %d · %s") % [w.round_index + 1, w.series.calendar.size(), Countries.name_of(w.track.country)]
	round_label.uppercase = true
	round_label.theme_type_variation = &"SectionLabel"
	left.add_child(round_label)
	var name_label := Label.new()
	name_label.text = w.track.name
	name_label.uppercase = true
	name_label.theme_type_variation = &"HeadingLabel"
	left.add_child(name_label)
	var meta := Label.new()
	meta.text = tr("%s · %.2f km · %d laps") % [Calendar.format_date(), w.model.lap_length_m / 1000.0, w.conditions.laps]
	meta.theme_type_variation = &"MutedLabel"
	left.add_child(meta)
	row.add_child(left)

	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 10)
	steps.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var now := 0 if w.stage == RaceWeekend.Stage.PLANNING else 2
	for i in STEPS.size():
		if i > 0:
			var line := ColorRect.new()
			line.color = UIStyle.ACCENT if i <= now else UIStyle.LINE_STRONG
			line.custom_minimum_size = Vector2(36, 2)
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			steps.add_child(line)
		var step := Label.new()
		step.text = ("✓ " if i < now else "%d " % (i + 1)) + tr(STEPS[i])
		step.theme_type_variation = &"StrongLabel"
		step.add_theme_color_override("font_color", UIStyle.ACCENT if i == now else (UIStyle.GOOD if i < now else UIStyle.FAINT))
		steps.add_child(step)
	row.add_child(steps)
	card.add_padded(row, 12, 6)
	return card


func _no_weekend_card() -> UICard:
	var card := UICard.new("Race weekend")
	var note := Label.new()
	var next := GameState.next_round_index()
	if next >= 0:
		var s: SeriesData = GameState.series[GameState.player_team().series_id]
		note.text = tr("No race today. The next race weekend is %s on %s.") % [GameState.tracks[s.calendar[next]].name, Calendar.format_date(s.race_days[next])]
	else:
		note.text = tr("The season is over. The next race weekend comes with the new season.")
	note.theme_type_variation = &"MutedLabel"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_padded(note, 8, 4)
	return card


# --- Step 1: before practice -------------------------------------------------

func _build_planning() -> void:
	var w := _weekend
	var top := _row()
	top.add_child(_track_card())
	top.add_child(_weather_card())
	top.add_child(_target_card())
	var bottom := _row()
	bottom.add_child(_programme_card())
	bottom.add_child(_orders_card())
	_page.add_child(_actions("Start practice & qualifying", func():
		w.run_practice_and_qualifying()
		_rebuild(), func():
		w.staff_planning()
		_rebuild()))


func _track_card() -> UICard:
	var id := _weekend.track.id
	var card := UICard.new("Track character", "what this track rewards")
	for bar in TrackInfo.bars(id):
		card.add_padded(_bar_row(bar[0], bar[1], bar[2]), 3, 3)
	card.add_row(FactRow.new("Time lost in the pit lane", "%.1f s" % TrackInfo.pit_loss(id), "", true))
	var suit := TrackInfo.suitability(GameState.player_team_id, id)
	card.add_row(FactRow.new("Our car here", tr(suit.label), tr("P%d of the field here (usually P%d)") % [suit.rank, suit.usual],
		false, TrackInfo.suitability_color(suit.label)))
	return card


func _bar_row(label: String, value: float, word: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var key := Label.new()
	key.text = label
	key.theme_type_variation = &"MutedLabel"
	key.custom_minimum_size.x = 150
	row.add_child(key)
	var meter := Meter.new(value * 100.0, UIStyle.ACCENT, 6)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meter)
	var text := Label.new()
	text.text = word
	text.theme_type_variation = &"StrongLabel"
	text.custom_minimum_size.x = 90
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(text)
	return row


func _weather_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Weather forecast", "accuracy depends on your strategy chief")
	var rain := w.forecast_rain
	card.add_row(FactRow.new("Rain in the race", "%d %%" % roundi(rain * 100), tr("± %d %%") % roundi(w.forecast_margin * 100),
		true, UIStyle.RAIN if rain >= 0.25 else UIStyle.TEXT))
	card.add_row(FactRow.new("Track temperature", tr("about %d °C") % roundi(w.conditions.track_temp_c), "", true))
	card.add_row(FactRow.new("Safety car risk", tr("High") if TrackInfo.safety_car_likely(w.track.id) else tr("Normal")))
	var chief := _staff(StaffData.Role.STRATEGY_CHIEF)
	var quote := ""
	if rain < 0.1:
		quote = "Dry all weekend, I'm confident about that."
	elif rain < 0.35:
		quote = "Mostly dry, but keep an eye on the radar on Sunday."
	elif rain < 0.6:
		quote = "Models disagree for Sunday. It could go either way."
	else:
		quote = "Rain is likely on Sunday. Prepare for a wet race."
	card.add_padded(_quote(chief, "Strategy chief", quote), 8, 4)
	return card


func _target_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Weekend target", "sets the risk level")
	var options := []
	for i in RaceWeekend.TARGETS.size():
		options.append([tr(RaceWeekend.TARGETS[i][0]), tr(RaceWeekend.TARGETS[i][1])])
	ChoiceRow.make_group(card.body, options, w.target, func(i): w.target = i as RaceWeekend.Target)
	card.add_padded(_delegate("sporting director", func():
		w.staff_planning()
		_rebuild()), 8, 0)
	return card


func _programme_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Practice programme", "per driver")
	var disabled := [] if w.has_academy_driver() else [2]
	var tips := ["", "", "" if w.has_academy_driver() else tr("You have no academy driver yet.")]
	for car in w.player_cars():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_driver_label(car.driver, 170))
		var labels := RaceWeekend.PROGRAMMES.map(func(p): return tr(p))
		var seg := Segmented.new(labels, w.programmes.get(car.driver.id, 0), disabled, tips)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id := car.driver.id
		seg.changed.connect(func(i): w.programmes[id] = i)
		row.add_child(seg)
		card.add_padded(row, 6, 6)
	card.add_padded(_note("Setup work: better setup (race engineer, feedback, chemistry). Long runs: better tyre data for the strategy – shared by the whole team. Academy driver: experience for your talent, less setup time for the race driver."), 4, 4)
	card.add_padded(_delegate("race engineers", func():
		w.staff_programmes()
		_rebuild()), 8, 0)
	return card


func _orders_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Team orders policy")
	var own := w.player_cars()
	var options := [[tr(RaceWeekend.ORDERS[0][0]), tr(RaceWeekend.ORDERS[0][1])],
		[tr(RaceWeekend.ORDERS[1][0]), tr(RaceWeekend.ORDERS[1][1])]]
	for car in own:
		var mate := own.filter(func(c): return c != car)
		options.append([tr("Priority: %s") % car.driver.last_name,
			tr("%s lets him pass. %s's morale −2 per race.") % [mate[0].driver.last_name, mate[0].driver.last_name] if not mate.is_empty() else ""])
	var selected := int(w.orders)
	if w.orders == RaceWeekend.Orders.PRIORITY:
		for i in own.size():
			if own[i].driver.id == w.priority_driver:
				selected = 2 + i
	ChoiceRow.make_group(card.body, options, selected, func(i):
		if i < 2:
			w.orders = i as RaceWeekend.Orders
			w.priority_driver = &""
		else:
			w.orders = RaceWeekend.Orders.PRIORITY
			w.priority_driver = own[i - 2].driver.id)
	card.add_padded(_delegate("sporting director", func():
		w.staff_planning()
		_rebuild()), 8, 0)
	return card


# --- Step 2: after qualifying ------------------------------------------------

func _build_strategy() -> void:
	var w := _weekend
	var top := _row()
	var left := _practice_card()
	left.size_flags_stretch_ratio = 1.0
	top.add_child(left)
	var right := _strategy_card()
	right.size_flags_stretch_ratio = 2.0
	top.add_child(right)
	var bottom := _row()
	var rain := _rain_card()
	rain.size_flags_stretch_ratio = 1.0
	bottom.add_child(rain)
	var brief := _briefing_card()
	brief.size_flags_stretch_ratio = 1.4
	bottom.add_child(brief)
	_page.add_child(_talks_card())
	_page.add_child(_quali_card())
	_page.add_child(_actions("Start race", _start_race, func():
		w.staff_strategy()
		w.coach_talks()
		_rebuild()))


func _start_race() -> void:
	_weekend.start_race(true)
	_continue_race()


## Races on until the next key moment or the flag.
func _continue_race() -> void:
	if _weekend.advance():
		_rebuild()
	else:
		_finish_race()


func _finish_race() -> void:
	var summary := Season.race_weekend()
	shell.navigate(&"race_result", {"round": summary.round}, false)


func _practice_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Practice & qualifying")
	for car in w.player_cars():
		var setup := roundi(car.setup_pct)
		var word := "excellent" if setup >= 88 else ("good" if setup >= 75 else ("average" if setup >= 60 else "poor"))
		card.add_row(FactRow.new(tr("Setup %s") % car.driver.last_name, tr("%d %% · %s") % [setup, tr(word)], "", true,
			UIStyle.GOOD if setup >= 88 else (UIStyle.OK if setup >= 75 else UIStyle.WARN)))
	var own := w.player_cars()
	var tyre: float = own[0].tyre_data if not own.is_empty() else 0.0
	card.add_row(FactRow.new("Tyre data", tr("Good") if tyre >= 0.6 else (tr("Medium") if tyre >= 0.35 else tr("Little")),
		tr("from the long runs") if tyre >= 0.6 else "", false, UIStyle.OK if tyre >= 0.6 else UIStyle.WARN))
	var grid_text := []
	for car in own:
		grid_text.append("%s P%d" % [car.driver.last_name, car.grid_position])
	card.add_row(FactRow.new("Grid", " · ".join(grid_text)))
	card.add_row(FactRow.new("Rain in the race", "%d %%" % roundi(w.forecast_rain * 100), "", true,
		UIStyle.RAIN if w.forecast_rain >= 0.25 else UIStyle.TEXT))
	if w.practice_wet > 0.0:
		card.add_padded(_note("Rain in practice: less dry setup work and fewer tyre data."), 6, 0)
	return card


func _strategy_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Race strategy", "proposals by your strategy chief")
	var laps := w.conditions.laps
	for car in w.player_cars():
		var id := car.driver.id
		card.add_section(tr("%s · starts P%d") % [car.driver.full_name(), car.grid_position])
		var plans: Array = w.strategy_options.get(id, [])
		if plans.is_empty():
			card.add_padded(_note("No dry plan possible – the strategy chief decides during the race."), 4, 4)
			continue
		var holder := HBoxContainer.new()
		holder.add_theme_constant_override("separation", 8)
		var rows: Array[HoverRow] = []
		for i in plans.size():
			var plan: Dictionary = plans[i]
			var row := HoverRow.new(&"ResultBox", &"ResultBoxHover")
			row.make_clickable()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", 4)
			var title := Label.new()
			var stops: int = plan.stops.size()
			title.text = "%s · %s" % [["A", "B", "C"][i], tr("One stop") if stops == 1 else (tr("No stop") if stops == 0 else tr("%d stops") % stops)]
			title.theme_type_variation = &"StrongLabel"
			column.add_child(title)
			column.add_child(StintBar.new(StintBar.from_plan(plan, laps), laps, 16))
			var est := Label.new()
			var delta: float = plan.time - plans[0].time
			if i == 0:
				est.text = tr("Recommended · fastest estimate")
			elif delta < 0.05:
				est.text = tr("Estimate: same time as A")
			else:
				est.text = tr("Estimate: +%.1f s") % delta
			est.theme_type_variation = &"SmallLabel"
			est.add_theme_color_override("font_color", UIStyle.GOOD if i == 0 else UIStyle.MUTED)
			column.add_child(est)
			row.add_child(column)
			rows.append(row)
			holder.add_child(row)
		for i in rows.size():
			rows[i].set_selected(i == w.plan_choice.get(id, 0))
			rows[i].clicked.connect(func():
				w.plan_choice[id] = i
				for k in rows.size():
					rows[k].set_selected(k == i))
		card.add_padded(holder, 4, 6)
	var chief := _staff(StaffData.Role.STRATEGY_CHIEF)
	card.add_padded(_quote(chief, "Strategy chief", _strategy_quote()), 6, 4)
	card.add_padded(_note("If the race starts in the wet, the plan is replaced by the weather calls of the strategy chief."), 2, 2)
	card.add_padded(_delegate("strategy chief", func():
		for car in w.player_cars():
			w.plan_choice[car.driver.id] = 0
		_rebuild()), 8, 0)
	return card


## The strategy chief explains his plan A.
func _strategy_quote() -> String:
	var w := _weekend
	var hard := TrackInfo.relative(w.track.id, "overtaking") < 0.3
	var fewest := true
	var a_stops := -1
	for options in w.strategy_options.values():
		if options.is_empty():
			continue
		a_stops = options[0].stops.size()
		for p in options:
			if p.stops.size() < a_stops:
				fewest = false
	if w.forecast_rain >= 0.35:
		return "If the rain comes, every plan changes. Plan A keeps us flexible."
	if hard and fewest:
		return "Overtaking is hard here, track position is king. Fewer stops keep us out of traffic."
	if a_stops >= 2:
		return "The tyres drop off quickly here. Another stop is faster than nursing old tyres."
	return "Plan A is my best estimate. My tyre model is only as good as the data from practice."


func _rain_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Rain gamble · setup direction", tr("rain %d %%") % roundi(w.forecast_rain * 100))
	var rec := RaceWeekend.staff_rain_setup(w.forecast_rain)
	var options := []
	for entry in RaceWeekend.RAIN_SETUPS:
		var tag := tr("Recommended") if entry[0] == rec else ""
		options.append([tr(entry[1]), tr(entry[2]), tag])
	ChoiceRow.make_group(card.body, options, w.rain_setup, func(i): w.rain_setup = RaceWeekend.RAIN_SETUPS[i][0])
	card.add_padded(_delegate("race engineers", func():
		w.rain_setup = rec
		_rebuild()), 8, 0)
	return card


func _briefing_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Driver briefing", "effect depends on personality")
	for car in w.player_cars():
		var id := car.driver.id
		var rec: Array = w.recommended_briefing(car)
		var current: SimCar.Briefing = w.briefings.get(id, rec[0])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_driver_label(car.driver, 150))
		var labels := []
		var selected := 0
		for i in RaceWeekend.BRIEFINGS.size():
			var b: SimCar.Briefing = RaceWeekend.BRIEFINGS[i][0]
			labels.append(tr(RaceWeekend.BRIEFINGS[i][1]) + (" ★" if b == rec[0] else ""))
			if b == current:
				selected = i
		var seg := Segmented.new(labels, selected)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(seg)
		card.add_padded(row, 8, 2)
		var effects := _note(_briefing_effects(car, current))
		effects.add_theme_color_override("font_color", UIStyle.TEXT)
		card.add_padded(effects, 0, 0)
		var engineer := GameState.race_engineer_of(id)
		var who := engineer.full_name() if engineer else tr("Race engineer")
		var advice := _note(tr("★ %s recommends “%s”: %s") % [who, tr(RaceWeekend.briefing_name(rec[0])), tr(rec[1])])
		advice.add_theme_color_override("font_color", UIStyle.GOOD if current == rec[0] else UIStyle.WARN)
		card.add_padded(advice, 0, 6)
		seg.changed.connect(func(i):
			var b: SimCar.Briefing = RaceWeekend.BRIEFINGS[i][0]
			w.briefings[id] = b
			effects.text = _briefing_effects(car, b)
			advice.add_theme_color_override("font_color", UIStyle.GOOD if b == rec[0] else UIStyle.WARN))
	card.add_padded(_delegate("race engineers", func():
		for car in w.player_cars():
			w.briefings[car.driver.id] = w.recommended_briefing(car)[0]
		_rebuild()), 8, 0)
	return card


## Weekly 1-on-1 with each driver, or a talk he asked for.
func _talks_card() -> UICard:
	var w := _weekend
	var card := UICard.new("1-on-1 talks", "before every race")
	for id in w.talks:
		var talk: DriverTalk = w.talks[id]
		var request := talk.kind == DriverTalk.Kind.REQUEST
		var status := ""
		var color := UIStyle.MUTED
		if talk.done:
			var last: Dictionary = talk.rounds[talk.picks.size() - 1].answers[talk.picks.back()]
			status = tr("✓ done · %s") % tr(last.name)
			color = UIStyle.GOOD
		elif request:
			status = tr("⚠ Asked to talk – more is at stake")
			color = UIStyle.WARN
		else:
			status = tr("Weekly 1-on-1 · not held yet")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_driver_label(talk.driver, 190))
		var label := Label.new()
		label.text = status
		label.add_theme_color_override("font_color", color)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(label)
		var b := Button.new()
		b.text = "Open talk" if talk.done else ("Talk to him" if not request else "Answer his request")
		b.icon = UIStyle.icon("user")
		if request and not talk.done:
			b.theme_type_variation = &"AccentButton"
		var driver_id: StringName = id
		b.pressed.connect(func(): shell.navigate(&"driver_talk", {"driver_id": driver_id}))
		row.add_child(b)
		card.add_padded(row, 6, 6)
	card.add_padded(_delegate("mental coach", func():
		w.coach_talks()
		_rebuild()), 6, 0)
	card.add_padded(_note("Talks not held before the race are held by your mental coach."), 2, 2)
	return card


## "Mistakes −15 % · Overtaking attempts −30 % · Tyre wear −5 %"
func _briefing_effects(car: SimCar, b: SimCar.Briefing) -> String:
	var parts := []
	var fx: Dictionary = PaceModel.BRIEFING_EFFECTS[b]
	for key in fx:
		var v: float = fx[key]
		match key:
			"mistake":
				parts.append(tr("Mistakes %+d %%") % roundi(v * 100))
			"aggression":
				parts.append(tr("Overtaking attempts %+d %%") % roundi(v * 100))
			"tyre_wear":
				parts.append(tr("Tyre wear %+d %%") % roundi(v * 100))
			"contact":
				var c := v * (1.5 if car.driver.temperament < 40 else 1.0)
				parts.append(tr("Contact risk %+d %%") % roundi(c * 100) + (tr(" (hot-headed)") if car.driver.temperament < 40 else ""))
			"pace_s":
				parts.append(tr("Pace on the limit %+.2f s/lap") % v)
			"composure":
				parts.append(tr("Composure %+d") % roundi(v))
			"team_orders":
				parts.append(tr("Accepts team orders, helps his teammate"))
	return " · ".join(parts) if not parts.is_empty() else tr("No special instructions.")


func _quali_card() -> UICard:
	var w := _weekend
	var card := UICard.new("Qualifying", "starting grid")
	var flow := GridContainer.new()
	flow.columns = 4
	flow.add_theme_constant_override("h_separation", 24)
	flow.add_theme_constant_override("v_separation", 2)
	for car in w.grid:
		var q: Dictionary = w.quali.results.get(car, {})
		var best: float = q.get("Q3", INF)
		if is_inf(best):
			best = q.get("Q2", INF)
		if is_inf(best):
			best = q.get("Q1", INF)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pos := Label.new()
		pos.text = "%2d" % car.grid_position
		pos.theme_type_variation = &"MonoLabel"
		pos.custom_minimum_size.x = 26
		row.add_child(pos)
		row.add_child(UIStyle.team_stripe(car.team.id, 16))
		var name_label := Label.new()
		name_label.text = car.driver.last_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if car.is_player:
			name_label.add_theme_color_override("font_color", UIStyle.ACCENT)
		row.add_child(name_label)
		var time := Label.new()
		time.text = UIStyle.lap_time(best)
		time.theme_type_variation = &"SmallLabel"
		row.add_child(time)
		row.custom_minimum_size.x = 260
		flow.add_child(row)
	card.add_padded(flow, 6, 6)
	return card


# --- Step 3: key moments in the race -----------------------------------------

func _build_moment() -> void:
	var w := _weekend
	var m: Dictionary = w.engine.moment
	if m.is_empty():
		# Opened again after the race was decided: finish it.
		_continue_race.call_deferred()
		return
	var row := _row()
	var tower := _tower_card(m)
	tower.size_flags_stretch_ratio = 0.8
	row.add_child(tower)
	var card := UICard.new()
	card.size_flags_stretch_ratio = 2.0
	row.add_child(card)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var lap := Label.new()
	lap.text = tr("Lap %d / %d") % [m.lap, w.conditions.laps]
	lap.theme_type_variation = &"HeadingLabel"
	head.add_child(lap)
	var flag_text := {"sc": "Safety car", "vsc": "Virtual safety car", "weather": "Weather", "orders": "Team orders"}
	var flag := Label.new()
	flag.text = tr(flag_text.get(m.kind, "")).to_upper()
	flag.theme_type_variation = &"StrongLabel"
	flag.add_theme_color_override("font_color", UIStyle.SAFETY_CAR if m.kind in ["sc", "vsc"] else (UIStyle.RAIN if m.kind == "weather" else UIStyle.ACCENT))
	flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(flag)
	var paused := _note("Simulation paused for your decision")
	paused.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(paused)
	card.add_padded(head, 10, 2)
	card.add_padded(Meter.new(100.0 * m.lap / w.conditions.laps, UIStyle.ACCENT, 4), 2, 6)

	var title := Label.new()
	title.text = _t(m.title)
	title.theme_type_variation = &"HeadingLabel"
	title.add_theme_font_size_override("font_size", 24)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_padded(title, 4, 0)
	if m.text[0] != "":
		card.add_padded(_note(_t(m.text)), 0, 4)
	for f in m.facts:
		card.add_row(FactRow.new(_t(f[0]), _t(f[1])))

	card.add_section("Your call")
	var options := []
	for i in m.options.size():
		options.append([_t(m.options[i][0]), _t(m.options[i][1]), tr("Recommended") if i == m.recommended else ""])
	var choice := [m.recommended]
	ChoiceRow.make_group(card.body, options, m.recommended, func(i): choice[0] = i)
	var chief := _staff(StaffData.Role.STRATEGY_CHIEF)
	card.add_padded(_quote(chief, "Strategy chief", tr("My call: %s.") % _t(m.options[m.recommended][0])), 8, 4)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_END
	var rest := Button.new()
	rest.text = "Simulate to the end"
	rest.tooltip_text = "The strategy chief takes all remaining decisions."
	rest.pressed.connect(func():
		w.finish_with_staff()
		_finish_race())
	actions.add_child(rest)
	var delegate := Button.new()
	delegate.text = tr("Let %s decide") % tr("strategy chief")
	delegate.icon = UIStyle.icon("users")
	delegate.pressed.connect(func():
		w.answer(m.recommended)
		_continue_race())
	actions.add_child(delegate)
	var go := Button.new()
	go.text = tr("Confirm").to_upper()
	go.icon = UIStyle.icon("play")
	go.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	go.theme_type_variation = &"AccentButton"
	go.pressed.connect(func():
		w.answer(choice[0])
		_continue_race())
	actions.add_child(go)
	card.add_padded(actions, 10, 4)

	card.add_section("Race events")
	var shown := 0
	var events: Array = w.engine.events
	for i in range(events.size() - 1, -1, -1):
		var ev: Dictionary = events[i]
		var own: bool = ev.driver != &"" and GameState.drivers.has(ev.driver) \
			and GameState.drivers[ev.driver].team_id == GameState.player_team_id
		if not own and not ev.kind in ["sc", "vsc", "red", "retired"]:
			continue
		card.add_row(FactRow.new(tr("Lap %d") % ev.lap, ev.text, "", false, UIStyle.ACCENT if own else UIStyle.TEXT))
		shown += 1
		if shown >= 6:
			break


## Live timing tower: position, team colour, driver, gap, tyre.
func _tower_card(m: Dictionary) -> UICard:
	var card := UICard.new(tr("Running order · lap %d") % m.lap, "your cars highlighted")
	var order := _weekend.engine.running_order()
	var leader: SimCar = order[0]
	for i in order.size():
		var car: SimCar = order[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var pos := Label.new()
		pos.text = "%2d" % (i + 1) if car.is_running() else "–"
		pos.theme_type_variation = &"MonoLabel"
		pos.custom_minimum_size.x = 26
		row.add_child(pos)
		row.add_child(UIStyle.team_stripe(car.team.id, 16))
		var name_label := Label.new()
		name_label.text = car.driver.last_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if car.is_player:
			name_label.add_theme_color_override("font_color", UIStyle.ACCENT)
		row.add_child(name_label)
		var gap := Label.new()
		gap.theme_type_variation = &"SmallLabel"
		if not car.is_running():
			gap.text = tr("Out")
		elif car == leader:
			gap.text = tr("Leader")
		else:
			var g: Array = _weekend.engine.gap_to_leader(car)
			gap.text = tr("+%d lap(s)") % g[0] if g[0] > 0 else "+%.1f" % g[1]
		row.add_child(gap)
		var tyre := Label.new()
		tyre.text = UIStyle.compound_letter(car.compound)
		tyre.theme_type_variation = &"MonoLabel"
		tyre.custom_minimum_size.x = 16
		tyre.add_theme_color_override("font_color", UIStyle.compound_color(car.compound))
		row.add_child(tyre)
		card.add_padded(row, 1, 1)
	return card


## Translates an engine text [format, args]; string args with a key
## (tyre names) are translated too.
func _t(text: Array) -> String:
	var args: Array = text[1].map(func(a): return tr(a) if a is String else a)
	return tr(text[0]) % args if not args.is_empty() else tr(text[0])


# --- Helpers -----------------------------------------------------------------

func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	_page.add_child(row)
	return row


func _actions(primary: String, on_primary: Callable, on_delegate: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_END
	var delegate := Button.new()
	delegate.text = "Let staff decide everything"
	delegate.icon = UIStyle.icon("users")
	delegate.pressed.connect(on_delegate)
	row.add_child(delegate)
	var go := Button.new()
	go.text = tr(primary).to_upper()
	go.icon = UIStyle.icon("play")
	go.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	go.theme_type_variation = &"AccentButton"
	go.pressed.connect(on_primary)
	row.add_child(go)
	return row


func _delegate(who: String, action: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var text := _note(tr("Not sure? Your %s will decide, as well as their skill allows.") % tr(who))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var button := Button.new()
	button.text = tr("Let %s decide") % tr(who)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	row.add_child(button)
	return row


func _quote(person: StaffData, role: String, text: String) -> Control:
	var box := PanelContainer.new()
	box.theme_type_variation = &"TraitBox"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	var who := Label.new()
	who.text = "%s · %s" % [person.full_name() if person else tr(role), tr(role).to_lower()]
	who.theme_type_variation = &"SmallLabel"
	column.add_child(who)
	var said := Label.new()
	said.text = "“%s”" % tr(text)
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(said)
	box.add_child(column)
	return box


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _driver_label(driver: DriverData, width: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.x = width
	row.add_child(UIStyle.team_stripe(driver.team_id, 18))
	var l := Label.new()
	l.text = driver.full_name()
	l.theme_type_variation = &"StrongLabel"
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	return row


func _staff(role: StaffData.Role) -> StaffData:
	for s in GameState.staff_of_team(GameState.player_team_id):
		if s.role == role:
			return s
	return null
