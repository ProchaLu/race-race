## One engine lab project (mockup r5_engine.html, "Engine lab"): the steps
## from idea to homologated spec and, at every milestone, the decision –
## which ideas on the single-cylinder rig, which variants on the full dyno,
## how many endurance distances, then homologate, defuse or drop.
class_name EngineLabCard
extends UICard

## Ticked ideas / variants per "project|milestone" – kept across rebuilds.
static var _ticks: Dictionary = {}
var _p: EngineProject
var _m: ManufacturerData
var _changed: Callable
var _ticked: Dictionary


func _init(p: EngineProject, on_change: Callable) -> void:
	_p = p
	_m = GameState.manufacturers[p.manufacturer_id]
	_changed = on_change
	var key := "%d|%d" % [p.id, p.milestone]
	if not _ticks.has(key):
		_ticks[key] = {}
	_ticked = _ticks[key]
	var current: Dictionary = Engines.latest_spec(_m, p.component, EngineLab.dev_team(_m))
	super(tr("%s · new spec") % p.label(), tr("baseline: Spec %d · focus %s%s") % [current.version,
		tr(PowerUnit.VALUE_NAMES[StringName(p.focus)]), tr(" · aggressive") if p.aggressive else ""])


func _ready() -> void:
	add_padded(_steps(), 8, 4)
	match _p.milestone:
		EngineProject.Milestone.PICK_RIG:
			_build_ideas()
		EngineProject.Milestone.PICK_DYNO:
			_build_rig_results()
		EngineProject.Milestone.PICK_ENDURANCE:
			_build_dyno_results()
		EngineProject.Milestone.DECIDE:
			_build_decision()
		_:
			_build_running()
	var foot := _row()
	foot.add_child(_small(tr("Cost so far %s") % UIStyle.money(_p.cost_spent)))
	var drop := Button.new()
	drop.text = tr("Drop project")
	drop.tooltip_text = tr("Money already spent is lost.")
	drop.pressed.connect(func():
		EngineLab.cancel(_p)
		_changed.call())
	foot.add_child(drop)
	add_padded(foot, 8, 4)


func _steps() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var phases := [EngineProject.Phase.CONCEPT, EngineProject.Phase.RIG, EngineProject.Phase.DYNO,
		EngineProject.Phase.ENDURANCE, EngineProject.Phase.PRODUCTION]
	var notes := ["engine design", "rough ±", "precise power", "race distances", "spec + units"]
	for i in phases.size():
		var phase: int = phases[i]
		var done := phase < _p.phase or (phase == _p.phase and _p.milestone != EngineProject.Milestone.NONE)
		var now := phase == _p.phase and not done
		var box := PanelContainer.new()
		var bg := Color(UIStyle.GOOD, 0.1) if done else (Color(UIStyle.ACCENT, 0.14) if now else Color.TRANSPARENT)
		box.add_theme_stylebox_override("panel", UIStyle.box(bg, UIStyle.ACCENT if now else UIStyle.LINE_STRONG, 1, 8, 6))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		var t := Label.new()
		t.text = ("✓ " if done else "") + tr(EngineProject.PHASE_NAMES[phase])
		t.uppercase = true
		t.theme_type_variation = &"SectionLabel"
		t.clip_text = true
		column.add_child(t)
		var sub := tr("%d %%") % roundi(_p.phase_progress() * 100) if now else (tr("your decision") if phase == _p.phase else tr(notes[i]))
		column.add_child(_small(sub))
		if now:
			column.add_child(Meter.new(_p.phase_progress() * 100.0, UIStyle.ACCENT, 3))
		box.add_child(column)
		row.add_child(box)
	return row


# --- Milestones ----------------------------------------------------------------------

func _build_ideas() -> void:
	add_padded(_small(tr("The engine design office has %d ideas. The single-cylinder rig gives a first, rough number for power and efficiency – durability only shows on the endurance dyno. Pick up to %d.")
		% [_p.ideas.size(), EngineLab.MAX_RIG]), 6, 4)
	if _ticked.is_empty():
		for i in mini(3, _p.ideas.size()):
			_ticked[_p.ideas[i].key] = true
	for i in _p.ideas:
		var row := _row()
		row.add_child(_check(i.key))
		var n := Label.new()
		n.text = "%s · %s" % [i.key, tr(i.name)]
		n.theme_type_variation = &"StrongLabel"
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(n)
		var tag := _small(tr(PowerUnit.VALUE_NAMES[StringName(i.focus)]))
		tag.autowrap_mode = TextServer.AUTOWRAP_OFF
		tag.size_flags_horizontal = Control.SIZE_SHRINK_END
		tag.add_theme_color_override("font_color", UIStyle.ACCENT)
		row.add_child(tag)
		add_padded(row, 2, 2)
	var keys := _keys()
	var foot := _row()
	foot.add_child(_small(tr("%d of %d rig slots · ~%d days · %s") % [keys.size(), EngineLab.MAX_RIG,
		roundi(EngineLab.RIG_DAYS * keys.size()), UIStyle.money(EngineLab.RIG_COST * keys.size())]))
	foot.add_child(_auto_button())
	var go := _accent(tr("Run on the rig"))
	go.disabled = keys.is_empty() or keys.size() > EngineLab.MAX_RIG
	go.pressed.connect(func(): _act(EngineLab.pick_rig(_p, keys)))
	foot.add_child(go)
	add_padded(foot, 8, 4)


func _build_rig_results() -> void:
	add_padded(_small("Rig numbers are rough – the bar is the range the real value can be in. Combine ideas; the full dyno measures them precisely."), 6, 4)
	var rows := _p.variants.filter(func(v): return not v.rig.is_empty())
	_table(rows, "rig", true)
	var keys := _keys()
	var foot := _row()
	foot.add_child(_small(tr("%d of %d dyno slots · ~%d days · %s") % [keys.size(), EngineLab.MAX_DYNO,
		roundi(EngineLab.DYNO_DAYS * keys.size()), UIStyle.money(EngineLab.DYNO_COST * keys.size())]))
	var singles := keys.filter(func(k): return not k.contains("+"))
	var combine := Button.new()
	combine.text = tr("Combine ticked")
	combine.disabled = singles.size() < 2
	combine.pressed.connect(func():
		var combo := EngineLab.combine(_p, singles)
		if not combo.is_empty():
			_ticked[combo.key] = true
		_changed.call())
	foot.add_child(combine)
	foot.add_child(_auto_button())
	var go := _accent(tr("On the full dyno"))
	go.disabled = keys.is_empty() or keys.size() > EngineLab.MAX_DYNO
	go.pressed.connect(func(): _act(EngineLab.pick_dyno(_p, keys)))
	foot.add_child(go)
	add_padded(foot, 8, 4)


func _build_dyno_results() -> void:
	add_padded(_small("Power and efficiency are measured. Durability is unknown until the variant has run race distances on the endurance dyno – more distances, more certainty, more time."), 6, 4)
	var rows := _p.variants.filter(func(v): return not v.dyno.is_empty())
	_table(rows, "dyno", false)
	for v in rows:
		var row := _row()
		row.add_child(_small(tr("Endurance for %s:") % v.key))
		for runs in [1, 3, 6]:
			var b := Button.new()
			b.text = tr("%d race distance(s) · %d days · %s") % [runs, roundi(EngineLab.ENDURANCE_DAYS * runs), UIStyle.money(EngineLab.ENDURANCE_COST * runs)]
			var key: String = v.key
			var count: int = runs
			b.pressed.connect(func(): _act(EngineLab.endurance(_p, key, count)))
			row.add_child(b)
		add_padded(row, 2, 2)
	var foot := _row()
	foot.add_child(_small(""))
	foot.add_child(_auto_button())
	add_padded(foot, 8, 4)


func _build_decision() -> void:
	var v := _p.variant(_p.chosen)
	_table([v], "dyno", false)
	add_padded(_endurance_strip(v), 6, 2)
	var verdict := tr("Variant %s failed after %d km on the endurance dyno.") % [v.key, roundi(v.fail_km)] if v.fail_km > 0.0 \
		else tr("Variant %s ran %d race distances (%d km) without a failure.") % [v.key, v.runs, roundi(v.runs * EngineLab.RACE_DISTANCE_KM)]
	var l := _small(verdict)
	l.add_theme_color_override("font_color", UIStyle.BAD if v.fail_km > 0.0 else UIStyle.GOOD)
	add_padded(l, 2, 4)
	var foot := _row()
	var defuse := Button.new()
	defuse.text = tr("Defuse (−power, +reliability)")
	defuse.pressed.connect(func(): _act(EngineLab.defuse(_p, v.key)))
	foot.add_child(defuse)
	var more := Button.new()
	more.text = tr("3 more distances · %s") % UIStyle.money(EngineLab.ENDURANCE_COST * 3)
	more.pressed.connect(func(): _act(EngineLab.endurance(_p, v.key, 3)))
	foot.add_child(more)
	foot.add_child(_auto_button())
	var homologate := _accent(tr("Homologate %s") % v.key)
	homologate.tooltip_text = tr("Homologation and first units: %s, %d days") % [UIStyle.money(EngineLab.PRODUCTION_COST),
		EngineLab.PRODUCTION_DAYS[_p.component]]
	homologate.pressed.connect(func(): _act(EngineLab.homologate(_p, v.key)))
	foot.add_child(homologate)
	add_padded(foot, 8, 4)


func _build_running() -> void:
	match _p.phase:
		EngineProject.Phase.CONCEPT:
			add_padded(_small(tr("The engine design office is working on ideas for the %s.") % _p.label()), 6, 4)
		EngineProject.Phase.RIG, EngineProject.Phase.DYNO:
			var shown := _p.variants.filter(func(v): return not v.rig.is_empty())
			if not shown.is_empty():
				_table(shown, "dyno" if _p.phase == EngineProject.Phase.ENDURANCE else "rig", false)
			add_padded(_small(tr("On the %s.") % tr(EngineProject.PHASE_NAMES[_p.phase])), 4, 4)
		EngineProject.Phase.ENDURANCE:
			var v := _p.variant(_p.chosen)
			_table([v], "dyno", false)
			add_padded(_small(tr("Variant %s is running %d race distances on the endurance dyno.") % [v.key, _p.runs_ordered]), 4, 4)
		EngineProject.Phase.PRODUCTION:
			add_padded(_small(tr("Variant %s is homologated – the first units are being built.") % _p.chosen), 6, 4)


# --- Helpers ---------------------------------------------------------------------------

## Variant rows with bars per engine value of this component.
func _table(rows: Array, source: String, tickable: bool) -> void:
	var values: Array = PowerUnit.values_of(_p.component)
	var head := _row()
	if tickable:
		var pad := Control.new()
		pad.custom_minimum_size.x = 24
		head.add_child(pad)
	for t in [tr("Variant")] + values.map(func(v): return tr(PowerUnit.VALUE_NAMES[v])):
		var l := Label.new()
		l.text = t
		l.uppercase = true
		l.theme_type_variation = &"SectionLabel"
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(l)
	add_padded(head, 2, 0)
	var span := 0.5
	for v in rows:
		for value in values:
			var m := _measure(v, source, value)
			if not m.is_empty():
				span = maxf(span, absf(m[0]) + m[1])
	for v in rows:
		var row := _row()
		if tickable:
			row.add_child(_check(v.key))
		var n := Label.new()
		n.text = v.key + (tr(" · defused") if v.defused > 0 else "")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.tooltip_text = " + ".join(v.members.map(func(k): return tr(_p.idea(k).get("name", k))))
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(n)
		for value in values:
			var m := _measure(v, source, value)
			if m.is_empty():
				var dash := _small("?" if value == &"reliability" else "–")
				dash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(dash)
				continue
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override("separation", 0)
			box.add_child(ErrorBar.new(m[0], m[1], span * 1.1))
			var t := Label.new()
			t.text = "%+.1f ±%.1f" % [m[0], m[1]]
			t.theme_type_variation = &"MonoLabel"
			t.add_theme_font_size_override("font_size", 11)
			box.add_child(t)
			row.add_child(box)
		add_padded(row, 2, 2)


## [estimate, ±] of one value; reliability comes from the endurance runs.
func _measure(v: Dictionary, source: String, value: StringName) -> Array:
	if value == &"reliability":
		return v.rel if not v.rel.is_empty() else []
	var data: Dictionary = v.get(source, {})
	if data.is_empty() and source == "dyno":
		data = v.rig
	return data.get(value, [])


func _endurance_strip(v: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for i in maxi(6, v.runs):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(0, 14)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var failed_here: bool = v.fail_km > 0.0 and int(v.fail_km / EngineLab.RACE_DISTANCE_KM) == i
		cell.color = Color(UIStyle.BAD, 0.7) if failed_here else (Color(UIStyle.GOOD, 0.45) if i < v.runs else UIStyle.LINE)
		row.add_child(cell)
	return row


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


func _check(key: String) -> CheckBox:
	var check := CheckBox.new()
	if not _ticked.has(key):
		_ticked[key] = false
	check.button_pressed = _ticked[key]
	check.toggled.connect(func(on):
		_ticked[key] = on
		_changed.call())
	return check


func _auto_button() -> Button:
	var b := Button.new()
	b.text = tr("Let the engine chief decide")
	b.pressed.connect(func():
		var r := RandomNumberGenerator.new()
		r.randomize()
		EngineLab.auto_decide(_p, r)
		_changed.call())
	return b


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
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
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l
