## Selectable option: bold title, short description and an optional tag
## ("Recommended", "Risky"). make_group() wires several rows so exactly one
## is chosen.
class_name ChoiceRow
extends HoverRow


func _init(title: String, description: String = "", tag: String = "", tag_color: Color = UIStyle.GOOD) -> void:
	super()
	make_clickable()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var title_label := Label.new()
	title_label.text = title
	title_label.theme_type_variation = &"StrongLabel"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(title_label)
	if tag != "":
		var tag_label := Label.new()
		tag_label.text = tag
		tag_label.uppercase = true
		tag_label.theme_type_variation = &"TinyLabel"
		tag_label.add_theme_color_override("font_color", tag_color)
		tag_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(tag_label)
	column.add_child(top)
	if description != "":
		var desc := Label.new()
		desc.text = description
		desc.theme_type_variation = &"SmallLabel"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(desc)
	add_child(column)


## Adds the rows to parent and keeps exactly one selected.
## options: [[title, description, tag, tag_color], ...] (tag optional).
## on_select(index) is called when the player picks another option.
static func make_group(parent: Control, options: Array, selected: int, on_select: Callable) -> Array[ChoiceRow]:
	var rows: Array[ChoiceRow] = []
	for i in options.size():
		var o: Array = options[i]
		var row := ChoiceRow.new(o[0], o[1] if o.size() > 1 else "", o[2] if o.size() > 2 else "",
			o[3] if o.size() > 3 else UIStyle.GOOD)
		row.set_zebra(i % 2 == 1)
		row.set_selected(i == selected)
		rows.append(row)
		parent.add_child(row)
	for i in rows.size():
		rows[i].clicked.connect(func():
			for k in rows.size():
				rows[k].set_selected(k == i)
			on_select.call(i))
	return rows
