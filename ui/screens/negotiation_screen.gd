## Contract talks, conversation first (decisions 40/41): person on the left,
## the conversation with the agent in the middle, mood and offer on the right.
extends UIScreen

const BUBBLE_TEXT_WIDTH := 470

var n: Negotiation
var _thread_box: VBoxContainer
var _thread_scroll: ScrollContainer
var _points_box: HFlowContainer
var _send_button: Button
var _end_button: Button
var _mood_value: Label
var _mood_label: Label
var _mood_meter: Meter
var _from_offer: Label
var _from_talk: Label
var _priorities_box: VBoxContainer
var _patience_box: HBoxContainer
var _offer_controls: Array[Control] = []
var _value_labels := {}
var _cost_label: Label
var _budget_label: Label
var _risk_label: Label
var _result_label: Label
## "Who makes room?" when the position is full.
var _room_box: VBoxContainer
var _room_key := "-"


func setup(args: Dictionary) -> void:
	var person := GameState.find_person(args.person_id)
	n = GameState.negotiation_with(person.id)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(row)
	if not n:
		var refused := UICard.new("Contract talks")
		var l := Label.new()
		l.text = tr("%s does not want to talk right now.") % person.full_name()
		l.theme_type_variation = &"MutedLabel"
		refused.add_padded(l, 10, 0)
		row.add_child(refused)
		return

	var left := _left_column()
	left.custom_minimum_size.x = 290
	row.add_child(left)
	var chat := _conversation_card()
	chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(chat)
	var right := ScrollContainer.new()
	right.custom_minimum_size.x = 380
	right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var right_box := VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", UIStyle.GAP)
	right_box.add_child(_mood_card())
	right_box.add_child(_offer_card())
	right.add_child(right_box)
	row.add_child(right)
	_refresh_all()


func screen_title() -> String:
	return "Contract talks"


func nav_section() -> StringName:
	return &"market"


# --- Left: who and why -------------------------------------------------------

func _left_column() -> Control:
	var p := n.person
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UIStyle.GAP)
	var card := UICard.new("Contract extension" if n.kind == Negotiation.Kind.EXTEND else "New signing")
	# Framed like on the profiles; shrink so the portrait keeps its aspect ratio.
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.LINE_STRONG, 1))
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var picture := TextureRect.new()
	picture.texture = UIStyle.portrait(p, 120)
	frame.add_child(picture)
	card.add_padded(frame, 10, 4)
	var name_label := Label.new()
	name_label.text = p.full_name()
	name_label.uppercase = true
	name_label.theme_type_variation = &"HeadingLabel"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_padded(name_label, 0, 2)
	var role := tr("Driver") if p is DriverData else tr(StaffRoles.name_of((p as StaffData).role))
	var info := Label.new()
	info.text = "%s · %d · %s" % [role, p.age(Calendar.year), Countries.name_of(p.nationality)]
	info.theme_type_variation = &"MutedLabel"
	card.add_padded(info, 0, 6)
	var current := GameState.contract_of(p.id)
	card.add_row(FactRow.new("Current salary", UIStyle.money(current.salary) if current else tr("Free agent"), "", true))
	if current:
		card.add_row(FactRow.new("Contract ends", tr("End of %d") % current.end_year))
	card.add_row(FactRow.new("Morale", tr(DriverStatus.level_label(p.morale)), "", false, UIStyle.meter_color(p.morale)))
	box.add_child(card)

	var why := UICard.new("Why they would sign")
	why.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rank := n.car_rank()
	var car := "Top team" if rank <= 3 else ("Midfield" if rank <= 7 else "Backmarker")
	why.add_row(FactRow.new("Car", tr(car), tr("rank %d of %d") % [rank, GameState.teams.size()], false,
		UIStyle.GOOD if rank <= 3 else (UIStyle.OK if rank <= 7 else UIStyle.WARN)))
	why.add_row(FactRow.new("Team reputation", "%d / 100" % n.team.reputation, "", true))
	if p is StaffData:
		why.add_row(FactRow.new("Other teams interested", str(StaffImpact.rival_interest(p)), "", true))
	var fee: int = n.offer.get("transfer_fee", 0)
	if fee > 0:
		why.add_row(FactRow.new("Release clause to pay", UIStyle.money(fee), "", true, UIStyle.WARN))
	var agent := n.agent
	if agent:
		why.add_section("Agent")
		var agent_row := InfoRow.new(agent.full_name(), "", tr(AgentData.style_name(agent.style)), UIStyle.ACCENT, true)
		agent_row.set_leading_image(PortraitGenerator.texture(agent, UIStyle.LINE_STRONG, 30))
		why.add_row(agent_row)
	box.add_child(why)
	return box


# --- Middle: conversation ----------------------------------------------------

func _conversation_card() -> UICard:
	var title := tr("Conversation with %s") % (n.agent.full_name() if n.agent else n.person.full_name())
	var card := UICard.new(title, tr(AgentData.style_name(n.agent.style)) if n.agent else "")
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_thread_scroll = ScrollContainer.new()
	_thread_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_thread_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_theme_constant_override("margin_top", 10)
	_thread_box = VBoxContainer.new()
	_thread_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_thread_box.add_theme_constant_override("separation", 12)
	margin.add_child(_thread_box)
	_thread_scroll.add_child(margin)
	card.add(_thread_scroll)

	var composer := PanelContainer.new()
	var style := UIStyle.box(UIStyle.PANEL, Color.TRANSPARENT, 0, 16, 12)
	style.border_width_top = 1
	style.border_color = UIStyle.LINE
	composer.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	var say := Label.new()
	say.text = "Say something"
	say.uppercase = true
	say.theme_type_variation = &"SectionLabel"
	column.add_child(say)
	_points_box = HFlowContainer.new()
	_points_box.add_theme_constant_override("h_separation", 8)
	_points_box.add_theme_constant_override("v_separation", 8)
	column.add_child(_points_box)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	_send_button = Button.new()
	_send_button.text = tr("Send offer").to_upper()
	_send_button.theme_type_variation = &"AccentButton"
	_send_button.pressed.connect(func():
		n.send_offer()
		_after_action())
	actions.add_child(_send_button)
	_end_button = Button.new()
	_end_button.text = "End talks"
	_end_button.pressed.connect(func():
		n.walk_away()
		_after_action())
	actions.add_child(_end_button)
	_result_label = Label.new()
	_result_label.theme_type_variation = &"StrongLabel"
	_result_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(_result_label)
	column.add_child(actions)
	composer.add_child(column)
	card.add(composer)
	return card


func _render_thread() -> void:
	for child in _thread_box.get_children():
		child.queue_free()
	for entry in n.thread:
		_thread_box.add_child(_entry_view(entry))
	_scroll_to_bottom.call_deferred()


## Shows the newest message once the layout has the new height.
func _scroll_to_bottom() -> void:
	if not is_inside_tree():
		await ready
	await get_tree().process_frame
	_thread_scroll.scroll_vertical = int(_thread_scroll.get_v_scroll_bar().max_value)


func _entry_view(entry: Dictionary) -> Control:
	match entry.who:
		"system":
			var l := Label.new()
			l.text = Negotiation.entry_text(entry)
			l.theme_type_variation = &"SmallLabel"
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return l
		"offer":
			return _right_aligned(_offer_view(entry.terms))
		"you":
			return _right_aligned(_bubble(tr("You"), Negotiation.entry_text(entry), true, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var face := TextureRect.new()
	face.texture = PortraitGenerator.texture(n.agent, UIStyle.LINE_STRONG, 40) if n.agent else UIStyle.portrait(n.person, 40)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(face)
	var who := (n.agent.full_name() + " · " + tr("agent")) if n.agent else n.person.full_name()
	row.add_child(_bubble(who, Negotiation.entry_text(entry), false, entry.get("delta", 0)))
	return row


func _bubble(who: String, text: String, mine: bool, delta: int) -> Control:
	var panel := PanelContainer.new()
	var bg := UIStyle.PANEL_DARK.lerp(UIStyle.ACCENT, 0.1) if mine else UIStyle.PANEL_DARK
	var border := Color(UIStyle.ACCENT, 0.4) if mine else UIStyle.LINE
	panel.add_theme_stylebox_override("panel", UIStyle.box(bg, border, 1, 12, 9))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	var who_label := Label.new()
	who_label.text = who
	who_label.uppercase = true
	who_label.theme_type_variation = &"TinyLabel"
	column.add_child(who_label)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = BUBBLE_TEXT_WIDTH
	column.add_child(body)
	if delta != 0:
		var mood := Label.new()
		mood.text = tr("Mood %+d") % delta
		mood.theme_type_variation = &"NumberLabel"
		mood.add_theme_font_size_override("font_size", 13)
		mood.add_theme_color_override("font_color", UIStyle.GOOD if delta > 0 else UIStyle.BAD)
		column.add_child(mood)
	panel.add_child(column)
	return panel


func _offer_view(terms: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL_DARK, UIStyle.ACCENT, 1, 14, 10))
	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = "Offer sent"
	title.uppercase = true
	title.theme_type_variation = &"CardTitle"
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	var lines := [["Salary", tr("%s per year") % UIStyle.money(terms.salary)], ["Length", tr("%d seasons") % terms.years]]
	if terms.has("role"):
		lines.append(["Role", tr(ContractData.role_name(terms.role))])
		lines.append(["Win bonus", UIStyle.money(terms.win_bonus)])
	lines.append(["Signing fee", UIStyle.money(terms.signing_fee) if terms.signing_fee > 0 else tr("None")])
	lines.append(["Release clause", tr("Yes") if terms.release_clause else tr("None")])
	if terms.promise:
		lines.append(["Promise", tr("New parts at the same time as the No.1")])
	var room: Dictionary = terms.get("make_room", {})
	if not room.is_empty():
		var who := GameState.find_person(room.id)
		lines.append(["Makes room", tr("%s to reserve") % who.full_name() if room.action == "reserve" else tr("%s released") % who.full_name()])
	for line in lines:
		var k := Label.new()
		k.text = line[0]
		k.theme_type_variation = &"MutedLabel"
		grid.add_child(k)
		var v := Label.new()
		v.text = line[1]
		v.theme_type_variation = &"StrongLabel"
		grid.add_child(v)
	column.add_child(grid)
	panel.add_child(column)
	return panel


func _right_aligned(control: Control) -> Control:
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(control)
	return row


func _render_points() -> void:
	for child in _points_box.get_children():
		child.queue_free()
	for id in n.points:
		var spec: Array = Negotiation.POINTS[id]
		var box := HoverRow.new(&"TraitBox", &"TraitBoxHover")
		box.make_clickable()
		box.custom_minimum_size.x = 260
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		var say := Label.new()
		var text: String = tr(spec[0])
		say.text = text % n.person.first_name if "%s" in text else text
		say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		say.custom_minimum_size.x = 240
		column.add_child(say)
		var hint := Label.new()
		hint.text = ("⚠ " if spec[2] else "") + tr(spec[1])
		hint.theme_type_variation = &"SmallLabel"
		if spec[2]:
			hint.add_theme_color_override("font_color", UIStyle.WARN)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size.x = 240
		column.add_child(hint)
		box.add_child(column)
		box.clicked.connect(func():
			n.use_point(id)
			_after_action())
		_points_box.add_child(box)


# --- Right: mood and offer ---------------------------------------------------

func _mood_card() -> UICard:
	var card := UICard.new("Mood", "Offer + conversation")
	var top := HBoxContainer.new()
	_mood_value = Label.new()
	_mood_value.theme_type_variation = &"BigNumber"
	_mood_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_mood_value)
	_mood_label = Label.new()
	_mood_label.theme_type_variation = &"HeadingLabel"
	_mood_label.add_theme_font_size_override("font_size", 20)
	_mood_label.uppercase = true
	_mood_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_mood_label)
	card.add_padded(top, 6, 2)
	_mood_meter = Meter.new(0, UIStyle.ACCENT, 10)
	_mood_meter.marker = n.accept_at()
	card.add_padded(_mood_meter, 6, 4)
	var hint := Label.new()
	hint.text = "The white line marks where they accept."
	hint.theme_type_variation = &"SmallLabel"
	card.add_padded(hint, 0, 4)
	var offer_row := FactRow.new("From your offer", "", "", true)
	_from_offer = offer_row.value_label
	card.add_row(offer_row)
	var talk_row := FactRow.new("From the conversation", "", "", true)
	_from_talk = talk_row.value_label
	card.add_row(talk_row)
	card.add_section("What matters to them")
	_priorities_box = VBoxContainer.new()
	_priorities_box.add_theme_constant_override("separation", 0)
	card.add(_priorities_box)
	card.add_section("Patience")
	_patience_box = HBoxContainer.new()
	_patience_box.add_theme_constant_override("separation", 4)
	card.add_padded(_patience_box, 4, 0)
	return card


func _offer_card() -> UICard:
	var card := UICard.new("Your offer")
	var demand_salary: int = n.demand.salary
	_add_slider(card, "Salary per year", &"salary", int(demand_salary * 0.4), int(demand_salary * 1.6), 50_000, true)
	_add_choice(card, "Length", &"years", [[1, "1"], [2, "2"], [3, "3"], [4, "4"], [5, "5"]])
	if n.is_driver():
		var roles := [[ContractData.DriverRole.NUMBER_ONE, "No.1"], [ContractData.DriverRole.EQUAL, "Equal"],
			[ContractData.DriverRole.NUMBER_TWO, "No.2"], [ContractData.DriverRole.RESERVE, "Reserve"]]
		_add_choice(card, "Role", &"role", roles)
	_room_box = VBoxContainer.new()
	_room_box.add_theme_constant_override("separation", 4)
	card.add_padded(_room_box, 6, 4)
	if n.is_driver():
		_add_slider(card, "Bonus per win", &"win_bonus", 0, maxi(n.demand.win_bonus * 3, 100_000), 10_000, true)
	_add_slider(card, "Signing fee (one-off)", &"signing_fee", 0, mini(3_000_000, maxi(n.team.budget, 0)), 50_000, true)
	_add_check(card, "Release clause", &"release_clause")
	if n.is_driver():
		_add_check(card, "Promise: new parts at the same time as the No.1", &"promise")
	var cost := FactRow.new("Cost per year", "", "", true)
	_cost_label = cost.value_label
	card.add_row(cost)
	var budget := FactRow.new("Budget after one-off payments", "", "", true)
	_budget_label = budget.value_label
	card.add_row(budget)
	if n.kind == Negotiation.Kind.SIGN:
		var risk := FactRow.new("Risk that a rival steps in", "", "", true)
		risk.set_breakdown(Breakdown.new("Risk that a rival steps in",
			"Between the agreement and the signature other teams can still make an offer. A higher signing fee lowers the risk."))
		_risk_label = risk.value_label
		card.add_row(risk)
	return card


func _add_slider(card: UICard, label: String, key: StringName, low: int, high: int, step: int, money: bool) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.theme_type_variation = &"MutedLabel"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(l)
	var value := Label.new()
	value.theme_type_variation = &"NumberLabel"
	top.add_child(value)
	_value_labels[key] = [value, money]
	box.add_child(top)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = n.offer[key]
	slider.value_changed.connect(func(v):
		n.offer[key] = int(v)
		_refresh_offer())
	box.add_child(slider)
	_offer_controls.append(slider)
	card.add_padded(box, 6, 4)


func _add_choice(card: UICard, label: String, key: StringName, options: Array) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var l := Label.new()
	l.text = label
	l.theme_type_variation = &"MutedLabel"
	box.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for option in options:
		var b := Button.new()
		b.text = option[1]
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.button_pressed = n.offer[key] == option[0]
		var value: int = option[0]
		b.pressed.connect(func():
			n.offer[key] = value
			_refresh_offer())
		row.add_child(b)
		_offer_controls.append(b)
	box.add_child(row)
	card.add_padded(box, 6, 4)


func _add_check(card: UICard, label: String, key: StringName) -> void:
	var c := CheckBox.new()
	c.text = label
	c.button_pressed = n.offer[key]
	c.toggled.connect(func(on):
		n.offer[key] = on
		_refresh_offer())
	_offer_controls.append(c)
	card.add_padded(c, 2, 2)


# --- Refresh -----------------------------------------------------------------

func _after_action() -> void:
	if n.state != Negotiation.State.OPEN:
		GameState.close_negotiation(n)
	_refresh_all()


func _refresh_all() -> void:
	_render_thread()
	_render_points()
	_refresh_offer()
	var open := n.state == Negotiation.State.OPEN
	_send_button.disabled = not open or n.needs_room_choice()
	_end_button.disabled = not open
	for c in _offer_controls:
		if c is BaseButton:
			(c as BaseButton).disabled = not open
		elif c is Range:
			(c as Range).editable = open
	_points_box.visible = open
	match n.state:
		Negotiation.State.AGREED:
			var pending := GameState.pending_signing_of(n.person.id)
			_result_label.text = tr("Agreement – signature expected on %s") % Calendar.format_date(pending.get("sign_day", Calendar.day))
			if n.kind == Negotiation.Kind.SIGN:
				_result_label.text += "\n" + tr("Until then, rival teams can still make an offer (risk %d %%).") % roundi(Season.hijack_chance(n.offer) * 100)
			_result_label.add_theme_color_override("font_color", UIStyle.GOOD)
		Negotiation.State.FAILED:
			_result_label.text = tr("Talks ended")
			_result_label.add_theme_color_override("font_color", UIStyle.BAD)


func _refresh_offer() -> void:
	for key in _value_labels:
		var entry: Array = _value_labels[key]
		var v: int = n.offer[key]
		(entry[0] as Label).text = (UIStyle.money(v) if v > 0 else tr("None")) if entry[1] else str(v)
	var sat := n.satisfaction()
	var accept := n.accept_at()
	_mood_value.text = "%d %%" % sat
	var state_text := "Will accept" if sat >= accept else ("Close to a deal" if sat >= accept - 20 else ("Far apart" if sat >= 40 else "Insulting offer"))
	var color := UIStyle.GOOD if sat >= accept else (UIStyle.WARN if sat >= 40 else UIStyle.BAD)
	_mood_label.text = tr(state_text)
	_mood_value.add_theme_color_override("font_color", color)
	_mood_label.add_theme_color_override("font_color", color)
	_mood_meter.set_value(sat, color)
	_from_offer.text = str(n.offer_score())
	_from_talk.text = "%+d" % n.rapport
	_from_talk.add_theme_color_override("font_color", UIStyle.GOOD if n.rapport >= 0 else UIStyle.BAD)
	var fee: int = n.offer.get("transfer_fee", 0)
	_cost_label.text = tr("%s per year") % UIStyle.money(n.cost_per_year())
	var budget: int = n.team.budget - n.offer.signing_fee - fee
	_budget_label.text = UIStyle.money(budget)
	_budget_label.add_theme_color_override("font_color", UIStyle.money_color(budget))
	if _risk_label:
		var risk := roundi(Season.hijack_chance(n.offer) * 100)
		_risk_label.text = "%d %%" % risk
		_risk_label.add_theme_color_override("font_color", UIStyle.GOOD if risk <= 3 else UIStyle.WARN)
	_refresh_room()
	_send_button.disabled = n.state != Negotiation.State.OPEN or n.needs_room_choice()
	_refresh_priorities()
	_refresh_patience()


## Rebuilt only when the options change (e.g. a different driver role).
func _refresh_room() -> void:
	var options: Array = n.room_options()
	var key := str(options)
	if key == _room_key:
		return
	_room_key = key
	for child in _room_box.get_children():
		child.queue_free()
	_room_box.visible = not options.is_empty()
	if options.is_empty():
		return
	var title := Label.new()
	title.text = tr("Who makes room?")
	title.theme_type_variation = &"MutedLabel"
	_room_box.add_child(title)
	var hint := Label.new()
	hint.text = tr("This position is full. The choice takes effect when the contract is signed.")
	hint.theme_type_variation = &"MutedLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", UIStyle.WARN)
	_room_box.add_child(hint)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	var chosen: Dictionary = n.offer.get("make_room", {})
	for option in options:
		var who := GameState.find_person(option.id)
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = tr("Move %s to reserve driver") % who.full_name() if option.action == "reserve" \
			else tr("Release %s (severance %s)") % [who.full_name(), UIStyle.money(option.cost)]
		b.button_pressed = chosen.get("id", &"") == option.id and chosen.get("action", "") == option.action
		b.pressed.connect(func():
			n.offer.make_room = option.duplicate()
			_refresh_offer())
		_room_box.add_child(b)
		_offer_controls.append(b)


func _refresh_priorities() -> void:
	for child in _priorities_box.get_children():
		child.queue_free()
	if not n.priorities_known:
		var row := FactRow.new("Unknown", tr("Ask what matters most"), "", false, UIStyle.MUTED)
		_priorities_box.add_child(row)
		return
	var scores := n.aspect_scores()
	for aspect in n.priorities():
		var s: float = scores[aspect]
		var state := "Happy" if s >= 0.95 else ("Close" if s >= 0.7 else "Far apart")
		var color := UIStyle.GOOD if s >= 0.95 else (UIStyle.WARN if s >= 0.7 else UIStyle.BAD)
		var dots := "●".repeat(n.importance[aspect]) + "○".repeat(3 - n.importance[aspect])
		var row := FactRow.new(Negotiation.ASPECT_LABELS[aspect], tr(state), dots, false, color)
		_priorities_box.add_child(row)


func _refresh_patience() -> void:
	for child in _patience_box.get_children():
		child.queue_free()
	var total := n.agent.patience if n.agent else 4
	for i in total:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(22, 7)
		pip.color = UIStyle.ACCENT if i < n.patience else UIStyle.LINE_STRONG
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_patience_box.add_child(pip)
	var left := Label.new()
	left.text = tr("%d left") % n.patience
	left.theme_type_variation = &"SmallLabel"
	_patience_box.add_child(left)
