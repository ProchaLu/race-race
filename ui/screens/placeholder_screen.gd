## Shown for sections that are planned but not built yet.
extends UIScreen

var _section: StringName
var _label: String


func setup(args: Dictionary) -> void:
	_section = args.section
	_label = args.label
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := TextureRect.new()
	icon.texture = UIStyle.icon(args.icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(56, 56)
	icon.modulate = UIStyle.LINE_STRONG
	column.add_child(icon)

	var title := Label.new()
	title.text = _label
	title.uppercase = true
	title.theme_type_variation = &"HeadingLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var note := Label.new()
	note.text = "This section is planned for a later development round."
	note.theme_type_variation = &"MutedLabel"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)
	center.add_child(column)
	add_child(center)


func screen_title() -> String:
	return _label


func nav_section() -> StringName:
	return _section
