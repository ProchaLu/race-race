## Panel with an amber uppercase title, an optional subtitle and a body.
## Rows added with add_row() get alternating backgrounds automatically.
class_name UICard
extends PanelContainer

var body: VBoxContainer
var _row_count := 0


func _init(title: String = "", subtitle: String = "") -> void:
	theme_type_variation = &"Card"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)

	if title != "":
		var header := MarginContainer.new()
		_set_margins(header, UIStyle.ROW_PAD_X, 8, UIStyle.ROW_PAD_X, 7)
		var row := HBoxContainer.new()
		var title_label := Label.new()
		title_label.text = title
		title_label.uppercase = true
		title_label.theme_type_variation = &"CardTitle"
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title_label)
		if subtitle != "":
			var sub := Label.new()
			sub.text = subtitle
			sub.theme_type_variation = &"SmallLabel"
			sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(sub)
		header.add_child(row)
		column.add_child(header)
		column.add_child(HSeparator.new())

	var body_margin := MarginContainer.new()
	_set_margins(body_margin, 0, 4 if title != "" else 0, 0, 8 if title != "" else 0)
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 0)
	body_margin.add_child(body)
	column.add_child(body_margin)


func add(control: Control) -> Control:
	body.add_child(control)
	return control


func add_row(row: HoverRow) -> HoverRow:
	row.set_zebra(_row_count % 2 == 1)
	_row_count += 1
	body.add_child(row)
	return row


## Small uppercase heading inside the card body.
func add_section(text: String) -> void:
	var margin := MarginContainer.new()
	_set_margins(margin, UIStyle.ROW_PAD_X, 10, UIStyle.ROW_PAD_X, 2)
	var label := Label.new()
	label.text = text
	label.uppercase = true
	label.theme_type_variation = &"SectionLabel"
	margin.add_child(label)
	body.add_child(margin)
	_row_count = 0


## Wraps a control in the standard side padding.
func add_padded(control: Control, top: int = 4, bottom: int = 4) -> Control:
	var margin := MarginContainer.new()
	_set_margins(margin, UIStyle.ROW_PAD_X, top, UIStyle.ROW_PAD_X, bottom)
	margin.add_child(control)
	body.add_child(margin)
	return control


static func _set_margins(m: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
