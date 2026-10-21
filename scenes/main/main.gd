## Root scene. Owns the currently visible screen (HQ, race, menus)
## and swaps it when the EventBus asks for another one.
extends Node

const HQ_SCENE := preload("res://scenes/hq/hq.tscn")
const RACE_SCENE := preload("res://scenes/race/race_view.tscn")

@onready var screen_root: Node = $ScreenRoot

var _current_screen: Node


func _ready() -> void:
	EventBus.race_requested.connect(_on_race_requested)
	EventBus.hq_requested.connect(_on_hq_requested)
	TestWorld.build()
	_set_screen(HQ_SCENE.instantiate())


func _set_screen(screen: Node) -> void:
	if _current_screen:
		_current_screen.queue_free()
	_current_screen = screen
	screen_root.add_child(screen)


func _on_race_requested(track_id: StringName) -> void:
	var view := RACE_SCENE.instantiate()
	view.track_id = track_id
	_set_screen(view)


func _on_hq_requested() -> void:
	_set_screen(HQ_SCENE.instantiate())
