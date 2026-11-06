## Opens one management screen of the test world and saves a PNG of it.
## Needs a window (no --headless). Environment: SCREEN (section id, e.g. finances),
## SHOT (output file, absolute path), SETUP (optional: youth, dismissed), TAB (optional tab index),
## JUNIOR (junior_profile: own = our academy driver, else an F2 junior),
## NEW_GAME (optional: existing = Kestrel on 1 January, found = own team),
## MENU (optional: a start menu page instead of a screen), UI_LANG (optional: de).
## godot --path . res://tools/screen_shot.tscn
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = load("res://scenes/main/main.tscn").instantiate()
	var start := OS.get_environment("NEW_GAME")
	var menu_page := OS.get_environment("MENU")
	main.skip_menu = start == "" and menu_page == ""
	get_tree().root.add_child(main)
	await get_tree().process_frame
	# After main has applied the saved language (not saved: this is only for the picture).
	if OS.get_environment("UI_LANG") != "":
		TranslationServer.set_locale(OS.get_environment("UI_LANG"))
	if menu_page != "":
		# MENU=title|mode|existing|found: a page of the start menu.
		main.get_node("ScreenRoot").get_child(0).show_page(StringName(menu_page))
		await _save()
		return
	if start == "existing":
		main._on_start_game({"mode": "existing", "team_id": &"kestrel"})
	elif start == "found":
		main._on_start_game({"mode": "found", "name": "Phoenix Racing", "short_name": "PHX",
			"color": TeamFounding.COLORS[0], "manufacturer": TeamFounding.engine_choices()[0][0]})
	await get_tree().process_frame
	var shell = main.get_node("ScreenRoot").get_child(main.get_node("ScreenRoot").get_child_count() - 1)
	if OS.get_environment("SETUP") == "youth":
		_youth_setup()
	elif OS.get_environment("SETUP") == "dismissed":
		_dismissed_setup()
	var screen := StringName(OS.get_environment("SCREEN"))
	if screen == &"junior_profile":
		# JUNIOR=own: first academy driver; otherwise the best known junior of another team.
		var id: StringName = GameState.player_team().academy_driver_ids[0] if OS.get_environment("JUNIOR") == "own" \
			else Scouting.targets_of_series(Youth.F2)[0]
		shell.navigate(screen, {"driver_id": id})
	elif OS.get_environment("TAB") != "":
		shell.navigate(screen, {"tab": int(OS.get_environment("TAB"))})
	else:
		shell.navigate(screen)
	await _save()


func _save() -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT"))
	get_tree().quit()


## SETUP=dismissed: the principal was dismissed and has job offers (Career screen).
func _dismissed_setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var s: SeriesData = GameState.series[GameState.player_team().series_id]
	var table := []
	for id in s.team_ids:
		if id != GameState.player_team_id:
			table.append([id, 0])
	table.append([GameState.player_team_id, 0])
	Career.season_end(table, true, r)


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
	Academy.sign_junior(team, juniors[0], {"force": true, "promise": &"f2_seat"})
	Academy.sign_junior(team, juniors[1], {"force": true})
	juniors[0].academy_focus = &"pace"
	juniors[0].young_driver_test = true
	if not Youth.karting().is_empty():
		GameState.discovered[Youth.karting()[0].id] = true
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
