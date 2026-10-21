## Headquarters screen: the management hub (placeholder for now).
extends Control

@onready var info_label: Label = $InfoLabel
@onready var start_race_button: Button = $StartRaceButton


func _ready() -> void:
	var team := GameState.player_team()
	var lines := PackedStringArray([
		"%s" % team.name,
		"Budget: %d" % team.budget,
		"Season %d, day %d" % [Calendar.year, Calendar.day],
		"",
	])
	for driver in GameState.drivers_of_team(team.id):
		lines.append("%s  (age %d, OVR %d)" % [
			driver.full_name(), driver.age(Calendar.year), driver.overall()])
	info_label.text = "\n".join(lines)
	start_race_button.pressed.connect(func(): EventBus.race_requested.emit(&"test_ring"))
