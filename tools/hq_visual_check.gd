## Run: godot --headless --path . res://tools/hq_visual_check.tscn
## Exports actual campus renders; verifies 75 distinct level sprites and navigation.
extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var campus_script = load("res://ui/components/hq_campus.gd")
	var previous: Dictionary = {}
	for level in range(1, 6):
		var team := TeamData.new()
		for id in Facilities.CATALOG:
			team.facilities[id] = level
		team.primary_color = Color("#d45545")
		var campus = campus_script.new()
		campus.configure(team)
		assert(campus.texture.get_size() == Vector2(1600, 1000))
		assert(campus.levels.size() == 15)
		campus._render()
		assert(campus._sprites.size() == 75)
		for site in campus_script.SITES:
			var rect: Rect2 = campus._hit_rects[site[0]]
			var used: Rect2i = campus._hit_images[site[0]].get_used_rect()
			var visible := Rect2(rect.position + Vector2(used.position), Vector2(used.size))
			var parcel := Rect2(Vector2(site[1]) * campus_script.SCALE, Vector2(site[2]) * campus_script.SCALE)
			assert(parcel.grow(4).encloses(visible), "Building extends outside its reserved parcel")
			# Keep roof/façade silhouettes out of public traffic lanes at every level.
			for road in [Rect2(28, 115, 587, 14), Rect2(28, 226, 587, 14),
					Rect2(153, 323, 455, 14), Rect2(334, 122, 15, 278),
					Rect2(601, 122, 15, 111), Rect2(146, 122, 14, 197),
					Rect2(226, 326, 13, 62), Rect2(29, 384, 579, 8),
					Rect2(361, 304, 71, 22)]:
				var traffic := Rect2(road.position * campus_script.SCALE, road.size * campus_script.SCALE)
				if traffic.intersects(visible):
					var overlap := traffic.intersection(visible)
					var art: Image = campus._hit_images[site[0]]
					for y in range(ceili(overlap.position.y), floori(overlap.end.y)):
						for x in range(ceili(overlap.position.x), floori(overlap.end.x)):
							var pixel := Vector2i(Vector2(x, y) - rect.position)
							assert(art.get_pixelv(pixel).a < 0.35, "Building overlaps a public road: %s" % site[0])
		for facility in range(15):
			var sprite: Image = campus._sprites[(facility / 5) * 25 + (level - 1) * 5 + facility % 5]
			assert(sprite.get_used_rect().has_area(), "Empty facility sprite")
			var digest := hash(sprite.get_data())
			assert(previous.get(facility, -1) != digest, "Duplicated adjacent level sprite")
			previous[facility] = digest
		var output := "/tmp/race_hq_level_%d.png" % level
		assert(campus.texture.get_image().save_png(output) == OK)
		campus.free()
	var main = load("res://scenes/main/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var shell = main.get_node("ScreenRoot").get_child(0)
	shell.navigate(&"hq")
	await get_tree().process_frame
	assert(shell._current.nav_section() == &"hq")
	# GUI capture is available when run with a real rendering driver.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/race_hq_screen.png")
	print("HQ: 75 sprites, five full-campus renders, and navigation passed.")
	get_tree().quit()
