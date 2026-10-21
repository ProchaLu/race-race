## Compact race result: big position plus track label.
class_name ResultBox
extends HoverRow


func _init(result: String, color: Color, track_label: String) -> void:
	super(&"ResultBox", &"ResultBoxHover")
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	var result_label := Label.new()
	result_label.text = result
	result_label.theme_type_variation = &"ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_color_override("font_color", color)
	column.add_child(result_label)
	var track := Label.new()
	track.text = track_label
	track.theme_type_variation = &"TinyLabel"
	track.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	track.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(track)
	add_child(column)
