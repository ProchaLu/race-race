## Sortable table of all drivers. Click a row to open the profile.
extends UIScreen

## [title, min width, expand]
const COLUMNS := [
	["#", 60, false],
	["Driver", 220, true],
	["Team", 220, true],
	["Nationality", 150, false],
	["Age", 70, false],
	["Ability", 130, false],
	["Potential", 130, false],
	["Morale", 110, false],
	["Points", 90, false],
	["Contract until", 140, false],
]
enum Col { NUMBER, DRIVER, TEAM, NATIONALITY, AGE, ABILITY, POTENTIAL, MORALE, POINTS, CONTRACT }

var _tree: Tree
var _filter: OptionButton
var _count_label: Label
var _sort_column := Col.POINTS
var _sort_descending := true


func setup(_args: Dictionary) -> void:
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(column)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	_filter = OptionButton.new()
	_filter.add_item("All drivers")
	_filter.add_item("Your team")
	_filter.item_selected.connect(func(_i): _rebuild())
	toolbar.add_child(_filter)
	_count_label = Label.new()
	_count_label.theme_type_variation = &"MutedLabel"
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toolbar.add_child(_count_label)
	column.add_child(toolbar)

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
	_tree.column_title_clicked.connect(_on_title_clicked)
	_tree.item_selected.connect(_on_item_selected)
	column.add_child(_tree)
	_rebuild()


func screen_title() -> String:
	return "Drivers"


func nav_section() -> StringName:
	return &"drivers"


func _rebuild() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var list: Array[DriverData] = []
	for driver in GameState.drivers.values():
		# Free agents live on the transfer market.
		if driver.team_id == &"":
			continue
		if _filter.selected == 1 and driver.team_id != GameState.player_team_id:
			continue
		list.append(driver)
	list.sort_custom(func(a, b):
		var ka = _sort_key(a)
		var kb = _sort_key(b)
		return ka > kb if _sort_descending else ka < kb)

	for driver in list:
		_add_row(root, driver)
	_count_label.text = tr("%d drivers · sorted by %s") % [list.size(), tr(COLUMNS[_sort_column][0]).to_lower()]


func _add_row(root: TreeItem, d: DriverData) -> void:
	var team: TeamData = GameState.teams[d.team_id]
	var stats: DriverSeasonStats = GameState.season_stats.get(d.id)
	var contract := GameState.contract_of(d.id)
	var item := _tree.create_item(root)
	item.set_metadata(0, d.id)
	item.set_text(Col.NUMBER, str(d.number))
	item.set_text(Col.DRIVER, d.full_name())
	item.set_icon(Col.DRIVER, UIStyle.portrait(d, 25))
	item.set_text(Col.TEAM, team.name)
	item.set_custom_color(Col.TEAM, team.primary_color.lerp(UIStyle.TEXT, 0.25))
	item.set_text(Col.NATIONALITY, Countries.name_of(d.nationality))
	item.set_text(Col.AGE, str(d.age(Calendar.year)))
	_set_stars(item, Col.ABILITY, DriverAttributes.to_stars(d.overall()))
	_set_stars(item, Col.POTENTIAL, DriverAttributes.to_stars(d.potential))
	item.set_text(Col.MORALE, DriverStatus.level_label(d.morale))
	item.set_custom_color(Col.MORALE, UIStyle.meter_color(d.morale))
	item.set_text(Col.POINTS, str(stats.points) if stats else "-")
	item.set_text(Col.CONTRACT, str(contract.end_year) if contract else "-")
	for col in [Col.NUMBER, Col.AGE, Col.POINTS, Col.CONTRACT]:
		item.set_custom_font(col, UIStyle.font(&"mono"))
	if d.team_id == GameState.player_team_id:
		item.set_custom_color(Col.DRIVER, UIStyle.ACCENT)
		item.set_custom_font(Col.DRIVER, UIStyle.font(&"body_semibold"))


## Stars are a cell icon, so hover and selection never hide them.
func _set_stars(item: TreeItem, col: int, stars: float) -> void:
	var tex := StarRating.texture(stars)
	item.set_icon(col, tex)
	item.set_icon_max_width(col, tex.get_width())


func _sort_key(d: DriverData) -> Variant:
	match _sort_column:
		Col.NUMBER:
			return d.number
		Col.DRIVER:
			return d.last_name
		Col.TEAM:
			return GameState.teams[d.team_id].name
		Col.NATIONALITY:
			return Countries.name_of(d.nationality)
		Col.AGE:
			return d.age(Calendar.year)
		Col.ABILITY:
			return d.overall()
		Col.POTENTIAL:
			return d.potential
		Col.MORALE:
			return d.morale
		Col.CONTRACT:
			var c := GameState.contract_of(d.id)
			return c.end_year if c else 0
	var stats: DriverSeasonStats = GameState.season_stats.get(d.id)
	return stats.points if stats else 0


func _on_title_clicked(column: int, _mouse_button: int) -> void:
	if column == _sort_column:
		_sort_descending = not _sort_descending
	else:
		_sort_column = column as Col
		# Text columns start A-Z, number columns start with the highest.
		_sort_descending = column not in [Col.DRIVER, Col.TEAM, Col.NATIONALITY, Col.NUMBER]
	_rebuild()


func _on_item_selected() -> void:
	var item := _tree.get_selected()
	if item:
		shell.open_driver(item.get_metadata(0))
