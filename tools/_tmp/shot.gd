extends Node

func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	TestWorld.build()
	var shell := AppShell.new()
	add_child(shell)
	var d: DriverData = GameState.free_drivers()[0]
	shell.navigate(&"negotiation", {"person_id": d.id})
	await get_tree().process_frame
	await get_tree().process_frame
	# Pick the first "make room" option to see the selected state.
	var n: Negotiation = GameState.negotiations[d.id]
	n.offer.role = ContractData.DriverRole.EQUAL
	shell.refresh_current()
	await get_tree().process_frame
	print("needs choice: ", n.needs_room_choice(), " options: ", n.room_options().size())
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("C:/Users/Lukas/AppData/Local/Temp/claude/e--Godot-race-race-race/988b8354-bc50-403d-8bb4-9444702cd94f/scratchpad/neg_room.png")
	get_tree().quit()
