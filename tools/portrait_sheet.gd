## Contact sheet for the portrait generator: random people plus one person
## at different ages. Run this scene (F6) to check variety after changes.
extends Control

const NATIONALITIES := ["GB", "DE", "IT", "ES", "FR", "SE", "FI", "NL", "BR", "AR", "MX", "US",
	"JP", "CN", "IN", "AU", "CA", "BE"]
const TEAM_COLORS := ["e8471c", "1e90ff", "ffd23f", "32cd32", "9370db", "c0c0c0", "1fb5a8", "ff69b4", "4a6cf7", "dc143c"]
const COUNT := 48
const AGES := [16, 22, 28, 34, 41, 48, 56, 64]


func _ready() -> void:
	theme = ThemeBuilder.shared()
	var background := ColorRect.new()
	background.color = UIStyle.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 20
	column.offset_top = 20
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var grid := GridContainer.new()
	grid.columns = 16
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var r := RandomNumberGenerator.new()
	r.randomize()
	for i in COUNT:
		var person := PersonData.new()
		person.id = StringName("sheet_%d_%d" % [i, r.randi()])
		person.nationality = NATIONALITIES[r.randi() % NATIONALITIES.size()]
		person.gender = PersonData.Gender.FEMALE if r.randf() < 0.3 else PersonData.Gender.MALE
		person.birth_year = Calendar.year - r.randi_range(17, 62)
		grid.add_child(_cell(person, Color(TEAM_COLORS[r.randi() % TEAM_COLORS.size()]),
			"%s %d" % [person.nationality, person.age(Calendar.year)]))
	column.add_child(grid)

	var ageing := HBoxContainer.new()
	ageing.add_theme_constant_override("separation", 10)
	var talent := PersonData.new()
	talent.id = &"sheet_talent"
	talent.nationality = "SE"
	for age in AGES:
		talent.birth_year = Calendar.year - age
		ageing.add_child(_cell(talent, Color("1e90ff"), "age %d" % age))
	column.add_child(ageing)


func _cell(person: PersonData, team: Color, caption: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var image := TextureRect.new()
	image.texture = PortraitGenerator.texture(person, team, 100)
	box.add_child(image)
	var label := Label.new()
	label.text = caption
	label.theme_type_variation = &"SmallLabel"
	box.add_child(label)
	return box
