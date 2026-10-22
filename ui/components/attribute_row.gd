## "Cornering ▲   [16]" with the value coloured on the 1-20 scale.
## With an uncertain value (lo < hi) it shows a range bar instead.
class_name AttributeRow
extends HoverRow


func _init(label: String, display_value: int, change: int = 0, known: Vector2i = Vector2i.ZERO) -> void:
	super()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)

	if known != Vector2i.ZERO and known.x != known.y:
		row.add_child(RangeBar.new(known.x, known.y))
		add_child(row)
		return

	if change != 0:
		row.add_child(TrendArrow.new(change > 0))
	var box := PanelContainer.new()
	box.theme_type_variation = &"ValueBox"
	box.custom_minimum_size.x = 46
	var value_label := Label.new()
	value_label.text = str(display_value)
	value_label.theme_type_variation = &"MonoLabel"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", UIStyle.value_color(display_value))
	box.add_child(value_label)
	row.add_child(box)
	add_child(row)
