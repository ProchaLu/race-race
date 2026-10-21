## Inbox: message list on the left, the selected message on the right.
extends UIScreen

var _list: VBoxContainer
var _detail: UICard
var _selected: InboxMessage


func setup(args: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", UIStyle.GAP)
	add_child(row)

	var list_card := UICard.new("Messages", tr("%d unread") % GameState.unread_count())
	list_card.custom_minimum_size.x = 520
	list_card.size_flags_horizontal = Control.SIZE_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 0)
	scroll.add_child(_list)
	list_card.add(scroll)
	list_card.body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(list_card)

	_detail = UICard.new("Message")
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_detail)

	_selected = args.get("message")
	if not _selected and not GameState.inbox.is_empty():
		_selected = GameState.inbox.back()
	_build_list()
	_show_message(_selected)


func screen_title() -> String:
	return "Inbox"


func nav_section() -> StringName:
	return &"inbox"


func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	if GameState.inbox.is_empty():
		var empty := Label.new()
		empty.text = "No messages."
		empty.theme_type_variation = &"MutedLabel"
		_list.add_child(empty)
		return
	var index := 0
	for i in range(GameState.inbox.size() - 1, -1, -1):
		var msg := GameState.inbox[i]
		var item := _message_row(msg)
		item.set_zebra(index % 2 == 1)
		_list.add_child(item)
		index += 1


func _message_row(msg: InboxMessage) -> HoverRow:
	var item := HoverRow.new()
	item.make_clickable()
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)

	var icon := TextureRect.new()
	icon.texture = UIStyle.icon(msg.icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	icon.modulate = UIStyle.ACCENT if not msg.read else UIStyle.FAINT
	line.add_child(icon)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var subject := Label.new()
	subject.text = msg.subject_text()
	subject.theme_type_variation = &"StrongLabel" if not msg.read else &"MutedLabel"
	subject.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if msg == _selected:
		subject.add_theme_color_override("font_color", UIStyle.ACCENT)
	text.add_child(subject)
	var meta := Label.new()
	meta.text = "%s · %s" % [tr(msg.sender), Calendar.format_date(msg.day)]
	meta.theme_type_variation = &"SmallLabel"
	text.add_child(meta)
	line.add_child(text)

	if msg.priority == InboxMessage.Priority.IMPORTANT and not msg.read:
		var dot := ColorRect.new()
		dot.color = UIStyle.ACCENT
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(dot)
	item.add_child(line)
	item.clicked.connect(func():
		_selected = msg
		_show_message(msg)
		_build_list())
	return item


func _show_message(msg: InboxMessage) -> void:
	for child in _detail.body.get_children():
		child.queue_free()
	if not msg:
		_detail.add_padded(_label("Select a message.", &"MutedLabel"), 8, 0)
		return
	GameState.mark_read(msg)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	var subject := _label(msg.subject_text(), &"HeadingLabel")
	subject.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subject)
	column.add_child(_label("%s %s · %s" % [tr("From"), tr(msg.sender), Calendar.format_date(msg.day)], &"MutedLabel"))
	column.add_child(HSeparator.new())
	var body := _label(msg.body_text(), &"Label")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 400
	column.add_child(body)

	if msg.link_screen != &"":
		var button := Button.new()
		button.text = msg.link_label
		button.icon = UIStyle.icon("chevron-right")
		button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(func(): shell.navigate(msg.link_screen, msg.link_args))
		column.add_child(button)
	_detail.add_padded(column, 12, 8)


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	if variation != &"Label":
		label.theme_type_variation = variation
	return label
