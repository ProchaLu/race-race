## "Salary ............ $4.2M per year" with an optional small second line.
class_name FactRow
extends HoverRow

## The right-hand value, for screens that update it live.
var value_label: Label


func _init(key: String, value: String, sub: String = "", mono: bool = false,
		value_color: Color = UIStyle.TEXT) -> void:
	super()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var key_label := Label.new()
	key_label.text = key
	key_label.theme_type_variation = &"MutedLabel"
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(key_label)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 0)
	value_label = Label.new()
	value_label.text = value
	value_label.theme_type_variation = &"NumberLabel" if mono else &"StrongLabel"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", value_color)
	right.add_child(value_label)
	if sub != "":
		var sub_label := Label.new()
		sub_label.text = sub
		sub_label.theme_type_variation = &"SmallLabel"
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(sub_label)
	row.add_child(right)
	add_child(row)
