## Large number with a caption underneath ("P4 / Championship").
class_name BigStat
extends VBoxContainer


func _init(value: String, caption: String, color: Color = UIStyle.TEXT) -> void:
	add_theme_constant_override("separation", 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var value_label := Label.new()
	value_label.text = value
	value_label.theme_type_variation = &"BigNumber"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", color)
	add_child(value_label)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.theme_type_variation = &"SmallLabel"
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(caption_label)
