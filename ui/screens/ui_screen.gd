## Base class for every screen shown in the app shell's content area.
class_name UIScreen
extends Control

## Set by the shell before setup() is called.
var shell: AppShell


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


## Receives the navigation arguments, e.g. {"driver_id": &"d_hale"}.
func setup(_args: Dictionary) -> void:
	pass


## Title shown in the top bar.
func screen_title() -> String:
	return ""


## Sidebar entry to highlight while this screen is open.
func nav_section() -> StringName:
	return &""
