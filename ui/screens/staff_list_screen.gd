## Your team's key staff, grouped by department, with a department strip
## on top. Click a person to open the staff profile.
extends UIScreen

const DEPARTMENTS := ["Technical", "Engine", "Production", "Race operations", "Youth", "Commercial", "Driver care"]
## [title, min width, expand]
const COLUMNS := [
	["Role", 200, false],
	["Name", 230, true],
	["Age", 70, false],
	["Nationality", 150, false],
	["Ability", 130, false],
	["Morale", 110, false],
	["Salary", 120, false],
	["Contract until", 130, false],
]

enum Col { ROLE, NAME, AGE, NATIONALITY, ABILITY, MORALE, SALARY, CONTRACT }

var _tree: Tree
## ROLE = grouped by department (default); any other column = flat sorted list.
var _sort_column := Col.ROLE
var _sort_descending := false


func setup(_args: Dictionary) -> void:
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(column)
	column.add_child(_department_strip())

	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.columns = COLUMNS.size()
	_tree.column_titles_visible = true
	_tree.select_mode = Tree.SELECT_ROW
	_tree.auto_tooltip = false
	for i in COLUMNS.size():
		_tree.set_column_title(i, COLUMNS[i][0])
		_tree.set_column_custom_minimum_width(i, COLUMNS[i][1])
		_tree.set_column_expand(i, COLUMNS[i][2])
		_tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	_tree.item_selected.connect(_on_selected)
	_tree.column_title_clicked.connect(_on_title_clicked)
	column.add_child(_tree)
	_fill()


func screen_title() -> String:
	return "Staff"


func nav_section() -> StringName:
	return &"staff"


func _staff() -> Array[StaffData]:
	return GameState.staff_of_team(GameState.player_team_id)


func _department_strip() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Card"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	var by_dept := {}
	for s in _staff():
		by_dept.get_or_add(StaffRoles.department_of(s.role), []).append(s)
	for i in DEPARTMENTS.size():
		var dept: String = DEPARTMENTS[i]
		var people: Array = by_dept.get(dept, [])
		var avg := 0.0
		for s in people:
			avg += s.overall()
		avg = avg / people.size() if not people.is_empty() else 0.0
		var tile := StatusTile.new(dept, tr("Key people: %d") % people.size(), UIStyle.TEXT, avg)
		var b := Breakdown.new(tr(dept), "Average ability of the key people. Department size and budget come with HQ and finances.")
		for s in people:
			b.add(s.full_name(), "%d / 100" % s.overall())
		tile.set_breakdown(b)
		if i > 0:
			row.add_child(VSeparator.new())
		row.add_child(tile)
	return panel


func _fill() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var people := _staff()
	for i in COLUMNS.size():
		var arrow := ""
		if i == _sort_column:
			arrow = "  ▼" if _sort_descending else "  ▲"
		_tree.set_column_title(i, tr(COLUMNS[i][0]) + arrow)
	if _sort_column != Col.ROLE:
		# Sorted view: one flat list.
		people.sort_custom(func(a, b):
			var ka = _sort_key(a)
			var kb = _sort_key(b)
			return ka > kb if _sort_descending else ka < kb)
		for s in people:
			_add_row(root, s)
		return
	for dept in DEPARTMENTS:
		var header := _tree.create_item(root)
		header.set_text(0, tr(dept).to_upper())
		header.set_custom_font(0, UIStyle.font(&"display_semibold"))
		header.set_custom_color(0, UIStyle.ACCENT)
		for c in COLUMNS.size():
			header.set_selectable(c, false)
			header.set_custom_bg_color(c, UIStyle.PANEL_DARK)

		var in_dept := people.filter(func(s): return StaffRoles.department_of(s.role) == dept)
		in_dept.sort_custom(func(a, b):
			return StaffRoles.TEAM_POSITIONS.find(a.role) < StaffRoles.TEAM_POSITIONS.find(b.role))
		for s in in_dept:
			_add_row(root, s)

		# Empty positions are shown so the player sees what is missing.
		var filled := {}
		for s in in_dept:
			filled[s.role] = filled.get(s.role, 0) + 1
		for role in StaffRoles.TEAM_POSITIONS:
			if StaffRoles.department_of(role) != dept:
				continue
			if filled.get(role, 0) > 0:
				filled[role] -= 1
				continue
			var item := _tree.create_item(root)
			item.set_text(0, tr(StaffRoles.name_of(role)))
			item.set_text(1, tr("Vacant – find someone on the transfer market"))
			item.set_custom_color(1, UIStyle.BAD)


func _add_row(root: TreeItem, s: StaffData) -> void:
	var c := GameState.contract_of(s.id)
	var item := _tree.create_item(root)
	item.set_metadata(0, s.id)
	item.set_text(0, s.role_label())
	item.set_custom_color(0, UIStyle.MUTED)
	item.set_text(1, s.full_name())
	item.set_icon(1, UIStyle.portrait(s, 25))
	item.set_text(2, str(s.age(Calendar.year)))
	item.set_text(3, Countries.name_of(s.nationality))
	var tex := StarRating.texture(DriverAttributes.to_stars(s.overall()))
	item.set_icon(4, tex)
	item.set_icon_max_width(4, tex.get_width())
	item.set_text(5, DriverStatus.level_label(s.morale))
	item.set_custom_color(5, UIStyle.meter_color(s.morale))
	item.set_text(6, UIStyle.money(c.salary) if c else "-")
	item.set_text(7, str(c.end_year) if c else "-")
	for col in [2, 6, 7]:
		item.set_custom_font(col, UIStyle.font(&"tabular"))


func _sort_key(s: StaffData) -> Variant:
	var c := GameState.contract_of(s.id)
	match _sort_column:
		Col.NAME: return s.last_name
		Col.AGE: return s.age(Calendar.year)
		Col.NATIONALITY: return Countries.name_of(s.nationality)
		Col.ABILITY: return s.overall()
		Col.MORALE: return s.morale
		Col.SALARY: return c.salary if c else 0
		Col.CONTRACT: return c.end_year if c else 0
	return StaffRoles.TEAM_POSITIONS.find(s.role)


## Click a column to sort by it (again to reverse); "Role" groups by department.
func _on_title_clicked(column: int, _mouse_button: int) -> void:
	if column == _sort_column and column != Col.ROLE:
		_sort_descending = not _sort_descending
	else:
		_sort_column = column as Col
		_sort_descending = column not in [Col.NAME, Col.NATIONALITY]
	_fill()


func _on_selected() -> void:
	var item := _tree.get_selected()
	if item and item.get_metadata(0):
		shell.open_staff(item.get_metadata(0))
