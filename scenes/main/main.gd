## Root scene. Builds the world and switches between the management UI
## (AppShell) and the live race view.
extends Node

const RACE_SCENE := preload("res://scenes/race/race_view.tscn")

@onready var screen_root: Node = $ScreenRoot

var _shell: AppShell
var _race: Node


func _ready() -> void:
	GameSettings.load_and_apply()
	EventBus.race_requested.connect(_on_race_requested)
	EventBus.hq_requested.connect(_on_hq_requested)
	TestWorld.build()
	_shell = AppShell.new()
	screen_root.add_child(_shell)


func _on_race_requested(track_id: StringName) -> void:
	_race = RACE_SCENE.instantiate()
	_race.track_id = track_id
	_shell.visible = false
	screen_root.add_child(_race)


func _on_hq_requested() -> void:
	if _race:
		_race.queue_free()
		_race = null
	_shell.visible = true
