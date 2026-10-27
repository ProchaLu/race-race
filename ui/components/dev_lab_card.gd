## The development lab of one project (mockup r3_lab.html): the steps from
## the old part to the new one and, at every milestone, the team
## principal's decision – which ideas go into CFD, which variants (and
## combinations) into the wind tunnel, then refine, freeze or drop.
class_name DevLabCard
extends UICard

var _team: TeamData
var _p: DevProject
var _changed: Callable
## Ticked ideas / variants per "project|milestone" – kept while the screen
## is rebuilt.
static var _ticks: Dictionary = {}
var _ticked: Dictionary


func _init(team: TeamData, p: DevProject, on_change: Callable) -> void:
	_team = team
	_p = p
	_changed = on_change
	var tick_key := "%d|%d" % [p.id, p.milestone]
	if not _ticks.has(tick_key):
		_ticks[tick_key] = {}
	_ticked = _ticks[tick_key]
	var history: Array = team.car.part_history.get(p.part_id, [])
	var title := tr("%s · next season's car") % p.label() if p.next_year else tr("%s v%d · new development") % [p.label(), history.size() + 1]
	super(title, tr("baseline: %s · P%d in the field") % [team.car.parts[p.part_id].label(), CarBuild.part_rank(team.id, p.part_id)])


func _ready() -> void:
	add_padded(_steps(), 8, 4)
	match _p.milestone:
		DevProject.Milestone.PICK_CFD:
			_build_ideas()
		DevProject.Milestone.PICK_TUNNEL:
			_build_cfd_results()
		DevProject.Milestone.DECIDE:
			_build_tunnel_results()
		_:
			_build_running()
	_build_controls()


# --- Steps -------------------------------------------------------------------

func _steps() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var last := DevProject.Phase.DETAIL if _p.next_year else DevProject.Phase.QUALITY
	for phase in range(DevProject.Phase.CONCEPT, last + 1):
		var box := PanelContainer.new()
		var done := phase < _p.phase or (phase == _p.phase and _p.milestone != DevProject.Milestone.NONE)
		var now := phase == _p.phase and not done
		var bg := Color(UIStyle.GOOD, 0.1) if done else (Color(UIStyle.ACCENT, 0.14) if now else Color.TRANSPARENT)
		box.add_theme_stylebox_override("panel", UIStyle.box(bg, UIStyle.ACCENT if now else UIStyle.LINE_STRONG, 1, 8, 6))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		var t := Label.new()
		t.text = ("✓ " if done else "") + tr(DevProject.PHASE_NAMES[phase])
		t.uppercase = true
		t.theme_type_variation = &"SectionLabel"
		t.clip_text = true
		column.add_child(t)
		var sub := ""
		if now:
			sub = tr("%d %% · %s") % [roundi(_p.phase_progress() * 100), _who(phase)]
		elif phase == _p.phase and _p.milestone != DevProject.Milestone.NONE:
			sub = tr("your decision")
		else:
			sub = _who(phase)
		column.add_child(_small(sub))
		if now:
			column.add_child(Meter.new(_p.phase_progress() * 100.0, UIStyle.ACCENT, 3))
		box.add_child(column)
		row.add_child(box)
	return row


func _who(phase: int) -> String:
	var aero := CarParts.test_kind(_p.part_id) == "aero"
	match phase:
		DevProject.Phase.CONCEPT, DevProject.Phase.DETAIL:
			return tr("Design")
		DevProject.Phase.CFD:
			return tr("CFD") if aero else tr("Simulation")
		DevProject.Phase.TUNNEL:
			return tr("Wind tunnel") if aero else tr("Test rigs")
		DevProject.Phase.TOOLING:
			return tr("%d days") % CarDevelopment.TOOLING_DAYS[_p.part_id]
		DevProject.Phase.PRODUCTION:
			return tr("%d units") % _p.units
		DevProject.Phase.QUALITY:
			return tr("Test rigs")
	return ""


# --- Milestone 1: ideas ------------------------------------------------------

func _build_ideas() -> void:
	var batch := CarDevelopment.batch_size(_team)
	add_padded(_small(tr("The design office has %d ideas. Nobody knows yet what they bring – CFD gives a first, rough number. Pick up to %d.")
		% [_p.ideas.size(), batch]), 6, 4)
	if _ticked.is_empty():
		for i in mini(batch, _p.ideas.size()):
			_ticked[_p.ideas[i].key] = true
	for i in _p.ideas:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var check := CheckBox.new()
		check.button_pressed = _ticked.get(i.key, false)
		var key: String = i.key
		check.toggled.connect(func(on):
			_ticked[key] = on
			_changed.call())
		row.add_child(check)
		var names := VBoxContainer.new()
		names.add_theme_constant_override("separation", 0)
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n := Label.new()
		n.text = "%s · %s" % [key, tr(i.name)]
		n.theme_type_variation = &"StrongLabel"
		names.add_child(n)
		names.add_child(_small(tr(CarParts.GOALS[i.goal][1])))
		row.add_child(names)
		var tag := _small(tr(CarParts.GOALS[i.goal][0]))
		tag.size_flags_horizontal = Control.SIZE_SHRINK_END
		tag.autowrap_mode = TextServer.AUTOWRAP_OFF
		tag.add_theme_color_override("font_color", UIStyle.ACCENT)
		row.add_child(tag)
		var cx := _small(tr("complexity %s") % ("●".repeat(i.complexity) + "○".repeat(3 - i.complexity)))
		cx.size_flags_horizontal = Control.SIZE_SHRINK_END
		cx.autowrap_mode = TextServer.AUTOWRAP_OFF
		cx.custom_minimum_size.x = 110
		row.add_child(cx)
		add_padded(row, 2, 2)
	var footer := _footer()
	var keys := _keys()
	var info := _small(tr("%d of %d CFD slots · ~%d days · %s") % [keys.size(), batch,
		roundi(CarDevelopment.CFD_DAYS * keys.size()), UIStyle.money(CarDevelopment.cfd_cost(_p, keys.size()))])
	info.add_theme_color_override("font_color", UIStyle.BAD if keys.size() > batch else UIStyle.MUTED)
	footer.add_child(info)
	footer.add_child(_auto_button())
	var go := _accent(tr("Run CFD") if CarParts.test_kind(_p.part_id) == "aero" else tr("Run simulation"))
	go.disabled = keys.is_empty() or keys.size() > batch
	go.pressed.connect(func(): _act(CarDevelopment.pick_cfd(_team, _p, keys)))
	footer.add_child(go)
	add_padded(footer, 8, 4)


# --- Milestone 2: CFD results ------------------------------------------------

func _build_cfd_results() -> void:
	add_padded(_small("CFD numbers are rough – the bar is the range the real value can be in. Combine ideas that work together; the wind tunnel shows what they really do."), 6, 4)
	var rows := _p.variants.filter(func(v): return not v.cfd.is_empty())
	var scale := _scale(rows, ["cfd"])
	add_padded(_table_head(["", "Variant", "CFD"]), 2, 0)
	for v in rows:
		var row := _variant_row(v, true)
		row.add_child(_bar(v, "cfd", scale))
		add_padded(row, 1, 1)
	var footer := _footer()
	var keys := _keys()
	var batch := CarDevelopment.batch_size(_team)
	footer.add_child(_small(tr("%d of %d wind tunnel slots · ~%d days · %s") % [keys.size(), batch,
		roundi(CarDevelopment.TUNNEL_DAYS * keys.size()), UIStyle.money(CarDevelopment.tunnel_cost(_p, keys.size()))]))
	var combine := Button.new()
	combine.text = tr("Combine ticked")
	combine.tooltip_text = tr("Ideas rarely add up exactly – some work together, some get in each other's way.")
	var singles := keys.filter(func(k): return not k.contains("+"))
	combine.disabled = singles.size() < 2
	combine.pressed.connect(func():
		var combo := CarDevelopment.combine(_p, singles)
		if not combo.is_empty():
			_ticked[combo.key] = true
		_changed.call())
	footer.add_child(combine)
	footer.add_child(_auto_button())
	var go := _accent(tr("Into the wind tunnel") if CarParts.test_kind(_p.part_id) == "aero" else tr("Onto the rigs"))
	go.disabled = keys.is_empty() or keys.size() > batch
	go.pressed.connect(func(): _act(CarDevelopment.pick_tunnel(_team, _p, keys)))
	footer.add_child(go)
	add_padded(footer, 8, 4)


# --- Milestone 3: wind tunnel ------------------------------------------------

func _build_tunnel_results() -> void:
	add_padded(_small("The wind tunnel / rigs are much more precise. Refine a variant for a little more (less every round), freeze the best one – or drop the project if nothing beats the old part."), 6, 4)
	var rows := _p.variants.filter(func(v): return not v.tunnel.is_empty())
	var scale := _scale(rows, ["cfd", "tunnel"])
	add_padded(_table_head(["Variant", "CFD", "Wind tunnel", ""]), 2, 0)
	var detail := int(CarDevelopment.design_cost(_team, _p.part_id, _p.ambition, _p.overtime) * 0.45)
	var tooling := 0 if _p.next_year else CarDevelopment.unit_cost(_team, _p.part_id) * 2
	for v in rows:
		var row := _variant_row(v, false)
		row.add_child(_bar(v, "cfd", scale))
		row.add_child(_bar(v, "tunnel", scale))
		var refine := Button.new()
		refine.text = tr("Refine")
		refine.tooltip_text = tr("One more wind tunnel round: %s · %d rounds so far") % [UIStyle.money(CarDevelopment.tunnel_cost(_p, 1)), v.rounds]
		var key: String = v.key
		refine.pressed.connect(func(): _act(CarDevelopment.refine(_team, _p, key)))
		row.add_child(refine)
		var freeze := _accent(tr("Freeze"))
		freeze.tooltip_text = tr("Detail design and tooling: %s") % UIStyle.money(detail + tooling)
		freeze.pressed.connect(func(): _act(CarDevelopment.freeze(_team, _p, key)))
		row.add_child(freeze)
		add_padded(row, 1, 1)
	var footer := _footer()
	footer.add_child(_small(tr("Freezing costs %s (detail design%s).") % [UIStyle.money(detail + tooling), tr(" and tooling") if tooling > 0 else ""]))
	var drop := Button.new()
	drop.text = tr("Drop project")
	drop.tooltip_text = tr("Money already spent is lost.")
	drop.pressed.connect(func():
		CarDevelopment.cancel(_p)
		_changed.call())
	footer.add_child(drop)
	footer.add_child(_auto_button())
	add_padded(footer, 8, 4)


# --- Running phases ----------------------------------------------------------

func _build_running() -> void:
	var share := CarDevelopment.shares(_team)
	var ready := CarDevelopment.ready_label(CarDevelopment.days_left(_team, _p, share))
	match _p.phase:
		DevProject.Phase.CONCEPT:
			add_padded(_small(tr("The design office is working on ideas for the %s (%d designers). Milestone: you pick which go into CFD.")
				% [_p.label(), CarDevelopment.headcount(_team, &"design")]), 6, 4)
		DevProject.Phase.CFD, DevProject.Phase.TUNNEL:
			var source := "cfd" if _p.phase == DevProject.Phase.CFD else "tunnel"
			var running := _p.variants.filter(func(v): return v.cfd_pick if source == "cfd" and v.cfd.is_empty() else v.tunnel_pick)
			add_padded(_small(tr("Measuring: %s") % ", ".join(running.map(func(v): return _variant_name(v)))), 6, 4)
			var shown := _p.variants.filter(func(v): return not v.cfd.is_empty())
			if not shown.is_empty():
				var scale := _scale(shown, ["cfd", "tunnel"])
				add_padded(_table_head(["Variant", "CFD", "Wind tunnel"]), 2, 0)
				for v in shown:
					var row := _variant_row(v, false)
					row.add_child(_bar(v, "cfd", scale))
					row.add_child(_bar(v, "tunnel", scale))
					add_padded(row, 1, 1)
		_:
			var v := _p.variant(_p.chosen)
			if not v.is_empty():
				var row := _variant_row(v, false)
				row.add_child(_bar(v, "tunnel", _scale([v], ["tunnel"])))
				add_padded(row, 4, 2)
			add_padded(_small(tr("Frozen: %s. Forecast %+.3f s per lap. Ready %s – then test it back-to-back in practice.")
				% [_variant_name(v), _p.forecast_s, ready] if not _p.next_year else
				tr("Frozen: %s. Goes into next season's car.") % _variant_name(v)), 4, 4)
	if _p.milestone == DevProject.Milestone.NONE and _p.phase < DevProject.Phase.DETAIL:
		add_padded(_small(tr("Next milestone in about %d days.") % ceili(_p.work_left / maxf(share.get(_p, 0.0), 0.2))), 2, 4)


# --- Priority, overtime, cancel ----------------------------------------------

func _build_controls() -> void:
	add_section("Project")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_small("Priority"))
	var prio := Segmented.new(DevProject.PRIORITY_NAMES.map(func(n): return tr(n)), _p.priority)
	prio.custom_minimum_size.x = 300
	prio.changed.connect(func(i):
		_p.priority = i as DevProject.Priority
		_changed.call())
	row.add_child(prio)
	var overtime := CheckButton.new()
	overtime.text = "Overtime (×1.4 speed)"
	overtime.button_pressed = _p.overtime
	overtime.toggled.connect(func(on):
		_p.overtime = on
		_changed.call())
	row.add_child(overtime)
	var cancel := Button.new()
	cancel.text = "Cancel project"
	cancel.tooltip_text = "Money already spent is lost."
	cancel.pressed.connect(func():
		CarDevelopment.cancel(_p)
		_changed.call())
	row.add_child(cancel)
	add_padded(row, 6, 2)
	add_padded(_small(tr("Cost so far %s · %s") % [UIStyle.money(_p.cost_spent),
		tr("next season's car") if _p.next_year else tr("this season")]), 2, 4)


# --- Helpers -----------------------------------------------------------------

func _act(reason: String) -> void:
	if reason != "":
		var l := _small(tr(reason))
		l.add_theme_color_override("font_color", UIStyle.BAD)
		add_padded(l, 2, 4)
		return
	_changed.call()


func _keys() -> Array:
	var out := []
	for k in _ticked:
		if _ticked[k]:
			out.append(k)
	return out


func _auto_button() -> Button:
	var b := Button.new()
	var aero := CarParts.test_kind(_p.part_id) == "aero"
	b.text = tr("Let head of aero decide") if aero else tr("Let head of chassis decide")
	b.pressed.connect(func():
		var r := RandomNumberGenerator.new()
		r.randomize()
		CarDevelopment.auto_decide(_team, _p, r)
		_changed.call())
	return b


func _footer() -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	return footer


func _variant_name(v: Dictionary) -> String:
	if v.is_empty():
		return ""
	var names: Array = v.members.map(func(k): return tr(_p.idea(k).get("name", k)))
	return "%s · %s" % [" + ".join(v.members), " + ".join(names)]


## Checkbox (optional) and name of a variant; the bars are added after it.
func _variant_row(v: Dictionary, tickable: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if tickable:
		var check := CheckBox.new()
		var key: String = v.key
		if not _ticked.has(key):
			_ticked[key] = _p.variants.filter(func(x): return not x.cfd.is_empty()).find(v) < 2
		check.button_pressed = _ticked[key]
		check.toggled.connect(func(on):
			_ticked[key] = on
			_changed.call())
		row.add_child(check)
	var n := Label.new()
	n.text = _variant_name(v) + (tr(" · refined ×%d") % v.rounds if v.rounds > 0 else "")
	n.clip_text = true
	n.custom_minimum_size.x = 320
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.tooltip_text = n.text
	n.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(n)
	return row


func _bar(v: Dictionary, source: String, scale: Dictionary) -> Control:
	var m := CarDevelopment.measured(_p, v, source)
	if m.is_empty():
		var l := _small("–" if source == "cfd" else tr("not measured"))
		l.custom_minimum_size.x = 150
		return l
	var unit: String = m[2]
	var text := "%+.3f s ±%.3f" % [m[0], m[1]] if unit == "s" else \
		"%s %+.1f ±%.1f" % [tr(CarParts.VALUE_NAMES[StringName(unit)]), m[0], m[1]]
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(ErrorBar.new(m[0], m[1], scale.get(unit, 1.0)))
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"MonoLabel"
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", UIStyle.GOOD if m[0] - m[1] > 0.0 else (UIStyle.BAD if m[0] + m[1] < 0.0 else UIStyle.TEXT))
	l.custom_minimum_size.x = 120
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(l)
	return box


## Bar scale per unit so all rows of a table compare.
func _scale(rows: Array, sources: Array) -> Dictionary:
	var out := {}
	for v in rows:
		for source in sources:
			var m := CarDevelopment.measured(_p, v, source)
			if m.is_empty():
				continue
			out[m[2]] = maxf(out.get(m[2], 0.0), absf(m[0]) + m[1])
	for unit in out:
		out[unit] *= 1.15
	return out


func _table_head(titles: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for t in titles:
		var l := Label.new()
		l.text = tr(t)
		l.uppercase = true
		l.theme_type_variation = &"SectionLabel"
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if t == "":
			l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			l.custom_minimum_size.x = 24
		row.add_child(l)
	return row


func _accent(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = &"AccentButton"
	return b


func _small(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
