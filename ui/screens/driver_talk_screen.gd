## 1-on-1 talk before the race (mockup r2_driver_talk.html): the driver on
## the left, the conversation in the middle, the collected effects on the
## right. Answers whose reaction is not known yet only show a hint.
extends UIScreen

const MOOD_LABELS := [[-50, "Hostile"], [0, "Tense"], [50, "Open"], [101, "Positive"]]

var _weekend: RaceWeekend
var _talk: DriverTalk
var _driver: DriverData


func setup(args: Dictionary) -> void:
	_weekend = Season.weekend_of_today()
	if _weekend:
		_talk = _weekend.talks.get(args.get("driver_id", &""))
	if not _talk:
		var card := UICard.new("1-on-1 talk")
		var note := _small("Talks take place on race day, after qualifying.")
		card.add_padded(note, 8, 4)
		add_child(card)
		return
	_driver = _talk.driver
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)
	page.add_child(_tabs())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	page.add_child(row)
	var left := _driver_card()
	left.custom_minimum_size.x = 320
	left.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(left)
	row.add_child(_talk_card())
	var right := _effects_card()
	right.custom_minimum_size.x = 320
	right.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(right)


func screen_title() -> String:
	return tr("1-on-1 · %s") % _driver.full_name() if _driver else "1-on-1 talk"


func nav_section() -> StringName:
	return &"calendar"


# --- Driver tabs -------------------------------------------------------------

func _tabs() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for id in _weekend.talks:
		var talk: DriverTalk = _weekend.talks[id]
		var b := Button.new()
		var status := tr("✓ done") if talk.done else (tr("⚠ Asked to talk") if talk.kind == DriverTalk.Kind.REQUEST else tr("Weekly 1-on-1"))
		b.text = "%s  ·  %s" % [talk.driver.full_name(), status]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.set_pressed_no_signal(talk == _talk)
		if talk.kind == DriverTalk.Kind.REQUEST and not talk.done:
			b.add_theme_color_override("font_color", UIStyle.WARN)
		var driver_id: StringName = id
		b.pressed.connect(func(): shell.navigate(&"driver_talk", {"driver_id": driver_id}, false))
		row.add_child(b)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var back := Button.new()
	back.text = "Back to the race weekend"
	back.icon = UIStyle.icon("chevron-left")
	back.pressed.connect(func(): shell.navigate(&"weekend"))
	row.add_child(back)
	return row


# --- Left: the driver --------------------------------------------------------

func _driver_card() -> UICard:
	var request := _talk.kind == DriverTalk.Kind.REQUEST
	var card := UICard.new("Asked to talk" if request else "Weekly 1-on-1", _weekend.track.name.trim_suffix(" Grand Prix"))
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 12)
	var portrait := TextureRect.new()
	portrait.texture = UIStyle.portrait(_driver, 64)
	who.add_child(portrait)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = _driver.full_name()
	name_label.theme_type_variation = &"StrongLabel"
	names.add_child(name_label)
	var c := GameState.contract_of(_driver.id)
	var engineer := GameState.race_engineer_of(_driver.id)
	names.add_child(_small(tr("%d · %s") % [_driver.age(Calendar.year), tr(ContractData.role_name(c.role)) if c else "–"]))
	if engineer:
		names.add_child(_small(tr("Race engineer %s") % engineer.last_name))
	who.add_child(names)
	card.add_padded(who, 8, 6)

	var car := _weekend.car_of(_driver.id)
	if car:
		card.add_row(FactRow.new("Grid", "P%d" % car.grid_position, "", true))
	card.add_row(FactRow.new("Morale", "%d · %s" % [_driver.morale, tr(DriverStatus.level_label(_driver.morale))], "", false,
		UIStyle.meter_color(_driver.morale)))
	card.add_row(FactRow.new("Confidence", str(_driver.confidence), "", true, UIStyle.meter_color(_driver.confidence)))
	var rel: int = GameState.relationship(_driver.id, GameState.PLAYER_ID).value
	card.add_row(FactRow.new("Relationship with you", tr(DriverStatus.relationship_label(rel)), "", false,
		UIStyle.GOOD if rel >= 20 else (UIStyle.BAD if rel < 0 else UIStyle.TEXT)))
	var temper := "Short-fused" if _driver.temperament < 40 else ("Calm" if _driver.temperament > 65 else "Balanced")
	card.add_row(FactRow.new("Temperament", tr(temper)))

	card.add_section("What you know about him")
	var memory := DriverTalk.memory_of(_driver.id)
	if not _talk.revealed.is_empty():
		var names_known := _talk.revealed.map(func(t): return "“%s”" % tr(DriverTalk.TONES[t][0]))
		var note := _small(tr("Your mental coach knows how he reacts to %s.") % ", ".join(names_known))
		note.add_theme_color_override("font_color", UIStyle.GOOD)
		card.add_padded(note, 2, 4)
	if memory.known.is_empty():
		card.add_padded(_small("Nothing yet. You learn how he reacts by talking to him."), 2, 2)
	for tone in memory.known:
		var name: String = DriverTalk.TONES[tone][0] if DriverTalk.TONES.has(tone) else tone
		card.add_padded(_small("✓ " + tr("Reaction to “%s” known") % tr(name)), 1, 1)
	card.add_section("Recent talks")
	var history: Array = memory.history
	if history.is_empty():
		card.add_padded(_small("No talks yet."), 2, 4)
	for i in range(history.size() - 1, maxi(-1, history.size() - 4), -1):
		var h: Array = history[i]
		card.add_row(FactRow.new("R%d" % h[0], _translate_summary(h[1])))
	return card


## "Weekly 1-on-1 · Share the ambition" -> both parts translated.
func _translate_summary(text: String) -> String:
	var parts := text.split(" · ")
	return " · ".join(Array(parts).map(func(p): return tr(p)))


# --- Middle: the conversation ------------------------------------------------

func _talk_card() -> UICard:
	var request := _talk.kind == DriverTalk.Kind.REQUEST
	var topic := {
		"favoured": "He asked for this talk: he feels the team favours his teammate",
		"low": "He asked for this talk: he is unhappy",
	}
	var title: String = topic.get(_talk.topic, "Topic this week") if request else "Topic this week"
	var card := UICard.new(title, tr("%d of %d answers") % [_talk.picks.size(), _talk.rounds.size()])
	if request:
		card.add_padded(_stakes(), 8, 4)
		card.add_padded(_mood_row(), 4, 4)

	var thread := VBoxContainer.new()
	thread.add_theme_constant_override("separation", 8)
	for k in _talk.rounds.size():
		if k > _talk.picks.size():
			break
		var round: Dictionary = _talk.rounds[k]
		thread.add_child(_bubble(_driver.full_name(), tr(round.q[0]) % round.q[1] if not round.q[1].is_empty() else tr(round.q[0]), false))
		if k >= _talk.picks.size():
			break
		var a: Dictionary = round.answers[_talk.picks[k]]
		thread.add_child(_bubble(tr("You · %s") % tr(a.name), tr(a.say), true))
		var reply := _bubble(_driver.full_name(), tr(a.reply), false)
		reply.get_child(0).get_child(0).add_child(_chips(_talk.pick_fx[k], false, ""))
		thread.add_child(reply)
		if request:
			var m := _small(tr("Talk mood %+d") % a.mood)
			m.add_theme_color_override("font_color", UIStyle.GOOD if a.mood >= 0 else UIStyle.BAD)
			thread.add_child(m)
	card.add_padded(thread, 8, 4)

	if _talk.done:
		var end := _small("Talk finished. The end mood decided how strong the lasting effects are." if request
			else "Talk finished. The effects apply on Sunday.")
		end.add_theme_color_override("font_color", UIStyle.GOOD)
		card.add_padded(end, 8, 4)
	else:
		card.add_section(tr("Your answer · %d of %d") % [_talk.picks.size() + 1, _talk.rounds.size()])
		var answers: Array = _talk.rounds[_talk.picks.size()].answers
		for i in answers.size():
			card.add_row(_answer_row(answers[i], i))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_END
	if not _talk.done:
		var coach := Button.new()
		coach.text = "Let mental coach talk"
		coach.icon = UIStyle.icon("users")
		coach.pressed.connect(func():
			_talk.auto_answer(_weekend.coach_skill(), _weekend.rng)
			shell.refresh_current())
		actions.add_child(coach)
	else:
		var next := _next_open_talk()
		var go := Button.new()
		go.theme_type_variation = &"AccentButton"
		go.icon = UIStyle.icon("play")
		go.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if next:
			go.text = (tr("Next: %s") % next.driver.last_name).to_upper()
			go.pressed.connect(func(): shell.navigate(&"driver_talk", {"driver_id": next.driver.id}, false))
		else:
			go.text = tr("Back to the race weekend").to_upper()
			go.pressed.connect(func(): shell.navigate(&"weekend"))
		actions.add_child(go)
	card.add_padded(actions, 10, 4)
	return card


func _next_open_talk() -> DriverTalk:
	for id in _weekend.talks:
		var t: DriverTalk = _weekend.talks[id]
		if not t.done and t != _talk:
			return t
	return null


func _answer_row(a: Dictionary, index: int) -> HoverRow:
	var row := HoverRow.new()
	row.make_clickable()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	var top := HBoxContainer.new()
	var tone := Label.new()
	tone.text = tr(a.name)
	tone.theme_type_variation = &"StrongLabel"
	tone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tone)
	var known := _talk.is_known(a)
	var tag := Label.new()
	tag.text = tr("Known reaction") if known else tr("Not known yet")
	tag.theme_type_variation = &"TinyLabel"
	tag.uppercase = true
	tag.add_theme_color_override("font_color", UIStyle.GOOD if known else UIStyle.WARN)
	top.add_child(tag)
	column.add_child(top)
	var say := Label.new()
	say.text = "“%s”" % tr(a.say)
	say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(say)
	if known:
		column.add_child(_chips(_talk.effects(a), _talk.is_repeated(a), tr("Talk mood %+d") % a.mood if _talk.kind == DriverTalk.Kind.REQUEST else ""))
	else:
		var hint := _small("? " + tr(_talk.hint()))
		hint.add_theme_color_override("font_color", UIStyle.WARN)
		column.add_child(hint)
	row.add_child(column)
	row.clicked.connect(func():
		_talk.answer(index)
		shell.refresh_current())
	return row


func _bubble(who: String, text: String, mine: bool) -> Control:
	var holder := HBoxContainer.new()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(Color(UIStyle.ACCENT, 0.10), Color(UIStyle.ACCENT, 0.45), 1, 12, 8) if mine
		else UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1, 12, 8))
	panel.custom_minimum_size.x = 420
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	var w := Label.new()
	w.text = who
	w.theme_type_variation = &"SmallLabel"
	column.add_child(w)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(l)
	panel.add_child(column)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 60
	if mine:
		holder.add_child(spacer)
		holder.add_child(panel)
	else:
		holder.add_child(panel)
		holder.add_child(spacer)
	return holder


## Small coloured effect chips; extra: an additional neutral chip.
func _chips(fx: Dictionary, repeated: bool, extra: String) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	for line in DriverTalk.effect_lines(fx):
		var text := "%s %s" % [tr(line[0]), tr(line[1])] if line[1] != "Yes" else tr(line[0])
		var color := UIStyle.GOOD if line[2] > 0 else (UIStyle.BAD if line[2] < 0 else UIStyle.MUTED)
		flow.add_child(_chip(text, color))
	if extra != "":
		flow.add_child(_chip(extra, UIStyle.MUTED))
	if repeated:
		flow.add_child(_chip(tr("Same line as last week – effect −30 %"), UIStyle.BAD))
	return flow


func _chip(text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(Color(color, 0.12), Color(color, 0.45), 1, 6, 1))
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.add_theme_color_override("font_color", color.lightened(0.15))
	panel.add_child(l)
	return panel


func _stakes() -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIStyle.box(Color(UIStyle.WARN, 0.10), Color(UIStyle.WARN, 0.5), 1, 12, 8))
	var l := Label.new()
	l.text = tr("At stake: morale can move ±10. A bad talk can end in a transfer request; a good one makes him more loyal.")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return box


func _mood_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var caption := _small("Talk mood")
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(caption)
	var mood := _talk.mood
	var color := UIStyle.GOOD if mood >= 50 else (UIStyle.OK if mood >= 0 else (UIStyle.WARN if mood >= -50 else UIStyle.BAD))
	var meter := Meter.new((mood + 100) / 2.0, color, 6)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meter)
	var label := ""
	for entry in MOOD_LABELS:
		if mood < entry[0]:
			label = entry[1]
			break
	var value := Label.new()
	value.text = "%s (%+d)" % [tr(label), mood]
	value.theme_type_variation = &"StrongLabel"
	value.add_theme_color_override("font_color", color)
	row.add_child(value)
	row.add_child(_small("The end mood scales all effects"))
	return row


# --- Right: effects ----------------------------------------------------------

func _effects_card() -> UICard:
	var card := UICard.new("Effects", "exact once known")
	var lines := DriverTalk.effect_lines(_talk.race_fx) + DriverTalk.effect_lines(_talk.lasting_fx)
	if lines.is_empty():
		card.add_padded(_small("No effects yet. Choose an answer."), 8, 4)
	for line in lines:
		var color := UIStyle.GOOD if line[2] > 0 else (UIStyle.BAD if line[2] < 0 else UIStyle.TEXT)
		card.add_row(FactRow.new(tr(line[0]), tr(line[1]), tr("Lasting") if line[3] else tr("This race"), true, color))
	card.add_padded(_small("“This race” ends after the flag. “Lasting” stays: morale, relationship, promises."), 8, 4)
	if _talk.kind == DriverTalk.Kind.REQUEST and not _talk.done:
		card.add_padded(_small("Values before the end mood is applied."), 2, 2)
	return card


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
