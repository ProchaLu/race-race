## One tile of the status strip: label, coloured value, optional meter.
class_name StatusTile
extends HoverRow


func _init(key: String, value: String, value_color: Color, meter_value: float = -1.0) -> void:
	super(&"Tile", &"TileHover")
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)

	var key_label := Label.new()
	key_label.text = key
	key_label.uppercase = true
	key_label.theme_type_variation = &"SectionLabel"
	column.add_child(key_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.theme_type_variation = &"ValueLabel"
	value_label.add_theme_color_override("font_color", value_color)
	column.add_child(value_label)

	if meter_value >= 0.0:
		column.add_child(Meter.new(meter_value, UIStyle.meter_color(meter_value), 4))
	add_child(column)
