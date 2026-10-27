## Run headless to check spending, construction, rollover, upkeep, R3 levels,
## picking and HQ navigation:
## godot --headless --path . res://tools/hq_construction_check.tscn
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var state = get_tree().root.get_node("GameState")
	var calendar = get_tree().root.get_node("Calendar")
	load("res://core/test_world.gd").build()
	var team: TeamData = state.player_team()
	var r := RandomNumberGenerator.new()
	team.facilities[&"composites"] = 0
	team.facility_projects.clear()
	team.budget = 200_000_000
	var offer := Facilities.quote(team, &"composites")
	var budget: int = team.budget
	assert(Facilities.start(team, &"bogus") != "")
	assert(Facilities.start(team, &"composites", 2) != "", "stale quote accepted")
	assert(team.budget == budget)
	assert(Facilities.start(team, &"composites", 1) == "")
	assert(team.budget == budget - offer.cost)
	assert(team.facilities[&"composites"] == 0)
	var paid := team.budget
	assert(Facilities.start(team, &"composites") != "", "duplicate accepted")
	assert(Facilities.start(team, &"wind") != "", "second project accepted")
	assert(Facilities.start(team, &"engine") != "", "locked building accepted")
	assert(team.budget == paid)
	# Progress survives the season rollover; completion posts an inbox link.
	calendar.day = calendar.DAYS_PER_SEASON - 2
	var start_year: int = calendar.year
	for i in range(offer.duration - 1):
		calendar.advance_day()
		Facilities.daily_update(r)
	assert(team.facilities[&"composites"] == 0)
	assert(team.facility_projects[&"composites"].remaining == 1)
	calendar.advance_day()
	Facilities.daily_update(r)
	assert(calendar.year == start_year + 1)
	assert(team.facilities[&"composites"] == 1)
	assert(not team.facility_projects.has(&"composites"))
	var found := false
	for message: InboxMessage in state.inbox:
		if message.link_screen == &"hq" and message.link_args.get("facility") == &"composites":
			found = true
	assert(found, "no completion message")
	# R3 reads the level directly: a design office upgrade adds a project slot.
	team.facilities[&"design"] = 4
	var slots := CarDevelopment.max_projects(team)
	assert(Facilities.start(team, &"design", 5) == "")
	assert(CarDevelopment.max_projects(team) == slots, "effect before completion")
	while team.facility_projects.has(&"design"):
		Facilities.daily_update(r)
	assert(CarDevelopment.max_projects(team) == slots + 1)
	assert(Facilities.start(team, &"design") != "", "level 6 accepted")
	team.budget = 0
	assert(Facilities.start(team, &"wind") != "", "built without money")
	assert(Facilities.upkeep_per_month(team) > 0)
	# Picking respects letterboxing and real sprite alpha at two viewport shapes.
	var campus := HqCampus.new()
	campus.configure(team)
	for extent in [Vector2(1000, 700), Vector2(600, 800)]:
		campus.size = extent
		assert(campus._site_at(Vector2(-1, -1)) == &"")
		var rect: Rect2 = campus._hit_rects[&"design"]
		var image: Image = campus._hit_images[&"design"]
		var found_pixel := Vector2.ZERO
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				if image.get_pixel(x, y).a > 0.9:
					found_pixel = Vector2(x, y)
					break
			if found_pixel != Vector2.ZERO:
				break
		var display: Rect2 = campus._image_rect()
		var local := display.position + (rect.position + found_pixel + Vector2(0.5, 0.5)) * display.size / Vector2(HqCampus.CANVAS)
		assert(campus._site_at(local) == &"design")
	campus.free()
	# The screen opens on a building and starts construction from the action bar.
	var shell = load("res://ui/shell/app_shell.gd").new()
	get_tree().root.add_child(shell)
	team.budget = 200_000_000
	team.facilities[&"pit"] = 2
	shell.navigate(&"hq", {"facility": &"pit"})
	await get_tree().process_frame
	var screen = shell._current
	assert(screen._selected == &"pit")
	var cost := int(Facilities.quote(team, &"pit").cost)
	screen._confirming = true
	screen._build_actions()
	await get_tree().process_frame
	var confirm: Button = screen._actions.get_child(screen._actions.get_child_count() - 1).get_child(2)
	confirm.pressed.emit()
	await get_tree().process_frame
	assert(team.facility_projects.has(&"pit"))
	assert(team.budget == 200_000_000 - cost)
	print("HQ construction: spending, stale quote, duplicate/locked rejection, rollover, inbox, R3 levels, upkeep, picking and screen passed.")
	get_tree().quit()
