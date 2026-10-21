## Builds the tooltip content for a Breakdown: title, factor rows, note.
class_name BreakdownTooltip
extends RefCounted

const NOTE_WIDTH := 300


static func create(b: Breakdown) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = b.title
	title.theme_type_variation = &"StrongLabel"
	box.add_child(title)

	if not b.rows.is_empty():
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 3)
		for row in b.rows:
			var key := Label.new()
			key.text = row[0]
			grid.add_child(key)
			var value := Label.new()
			value.text = row[1]
			value.theme_type_variation = &"NumberLabel"
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			value.add_theme_color_override("font_color", UIStyle.tone_color(row[2]))
			grid.add_child(value)
		box.add_child(grid)

	if b.note != "":
		var note := Label.new()
		note.text = b.note
		note.theme_type_variation = &"SmallLabel"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size.x = NOTE_WIDTH
		box.add_child(note)
	return box
