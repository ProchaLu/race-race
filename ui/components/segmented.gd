## Row of toggle buttons where exactly one is pressed ("Setup work |
## Long runs | Academy driver").
class_name Segmented
extends HBoxContainer

signal changed(index: int)

var buttons: Array[Button] = []


## disabled: indices that cannot be picked; tooltips: one per button (optional).
func _init(labels: Array, selected: int, disabled: Array = [], tooltips: Array = []) -> void:
	add_theme_constant_override("separation", 4)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for i in labels.size():
		var b := Button.new()
		b.text = labels[i]
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = i in disabled
		if i < tooltips.size():
			b.tooltip_text = tooltips[i]
		b.set_pressed_no_signal(i == selected)
		b.pressed.connect(func(): changed.emit(i))
		buttons.append(b)
		add_child(b)
