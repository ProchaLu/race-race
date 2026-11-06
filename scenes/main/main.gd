## Root scene. Shows the start menu, builds the world for the chosen start and
## switches between the management UI (AppShell) and the live race view.
extends Node

const RACE_SCENE := preload("res://scenes/race/race_view.tscn")

@onready var screen_root: Node = $ScreenRoot

## Tools and quick tests: skip the menu and build the mid-season development world.
@export var skip_menu := false

var _shell: AppShell
var _race: Node
var _menu: StartMenu


func _ready() -> void:
	GameSettings.load_and_apply()
	EventBus.race_requested.connect(_on_race_requested)
	EventBus.hq_requested.connect(_on_hq_requested)
	if skip_menu:
		TestWorld.build()
		_open_shell()
		return
	_menu = StartMenu.new()
	_menu.start_game.connect(_on_start_game)
	screen_root.add_child(_menu)


func _on_start_game(options: Dictionary) -> void:
	TestWorld.new_game(options)
	_menu.queue_free()
	_menu = null
	_open_shell()


func _open_shell() -> void:
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
