## Row with a title, a muted sub text and a coloured status on the right, e.g.
## "Sofia Lund · Race engineer ........ Excellent".
## compact = true puts the sub text next to the title (one line).
class_name InfoRow
extends HoverRow

var _row: HBoxContainer


func _init(title: String, sub: String, status: String, status_color: Color,
		compact: bool = false) -> void:
	super()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_row = row
	var left: BoxContainer
	if compact:
		left = HBoxContainer.new()
	else:
		left = VBoxContainer.new()
	left.add_theme_constant_override("separation", 8 if compact else 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_label := Label.new()
	title_label.text = title
	left.add_child(title_label)
	if sub != "":
		var sub_label := Label.new()
		sub_label.text = sub
		sub_label.theme_type_variation = &"SmallLabel"
		sub_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sub_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
		left.add_child(sub_label)
	row.add_child(left)

	var status_label := Label.new()
	status_label.text = status
	status_label.theme_type_variation = &"StrongLabel"
	status_label.add_theme_color_override("font_color", status_color)
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(status_label)
	add_child(row)


## Puts a small picture (e.g. a portrait) in front of the text.
func set_leading_image(tex: Texture2D) -> InfoRow:
	var image := TextureRect.new()
	image.texture = tex
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(image)
	_row.move_child(image, 0)
	return self
