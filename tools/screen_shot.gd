## Opens one management screen of the test world and saves a PNG of it.
## Needs a window (no --headless). Environment: SCREEN (section id, e.g. finances),
## SHOT (output file, absolute path).
## godot --path . res://tools/screen_shot.tscn
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = load("res://scenes/main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var shell = main.get_node("ScreenRoot").get_child(0)
	if OS.get_environment("SETUP") == "youth":
		_youth_setup()
	shell.navigate(StringName(OS.get_environment("SCREEN")))
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT"))
	get_tree().quit()


## SETUP=youth: an academy with two drivers (one placed in a junior seat) and
## a finished scouting assignment, so the R7 screens show their populated states.
func _youth_setup() -> void:
	var team: TeamData = GameState.player_team()
	team.facilities[&"academy"] = 3
	team.facilities[&"scouting"] = 2
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var juniors := []
	for d in Youth.pool():
		if d.age(Calendar.year) <= Academy.INTAKE_MAX_AGE:
			juniors.append(d)
	Academy.sign(team, juniors[0])
	Academy.sign(team, juniors[1])
	var t: YouthTeam = null
	for candidate in GameState.youth_teams.values():
		if candidate.series_id == Youth.F3:
			t = candidate
			break
	Youth.unseat(GameState.drivers[t.driver_ids[0]])
	juniors[0].birth_year = Calendar.year - 18
	Academy.place(team, juniors[0], t)
	var targets := Scouting.targets_of_series(Youth.F3)
	Scouting.start(team, &"series", "All F3 juniors", targets)
	while not GameState.scout_assignments.is_empty():
		Scouting.weekly_update(r)
	Scouting.start(team, &"region", "Juniors from Europe", Scouting.targets_of_region(&"europe"))
