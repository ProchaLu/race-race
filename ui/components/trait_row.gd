## Trait with icon badge, name and a one-line description.
class_name TraitRow
extends HoverRow


func _init(trait_id: StringName) -> void:
	super(&"TraitBox", &"TraitBoxHover")
	var info := TraitCatalog.get_trait(trait_id)
	var color: Color = UIStyle.GOOD if info.positive else UIStyle.BAD

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel",
		UIStyle.box(Color(color, 0.12), Color(color, 0.55), 1, 5, 5))
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := TextureRect.new()
	icon.texture = UIStyle.icon(info.icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(18, 18)
	icon.modulate = color
	badge.add_child(icon)
	row.add_child(badge)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = info.name
	name_label.theme_type_variation = &"StrongLabel"
	name_label.add_theme_color_override("font_color", color)
	text.add_child(name_label)
	var desc := Label.new()
	desc.text = info.desc
	desc.theme_type_variation = &"SmallLabel"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 120
	text.add_child(desc)
	row.add_child(text)
	add_child(row)
	set_breakdown(TraitCatalog.breakdown(trait_id))
