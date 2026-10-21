## Top-down race view. Runs the RaceSim at the chosen time scale and draws
## what it calculates; it never decides anything about the race itself.
extends Node2D

const TIME_SCALES: Array[float] = [0.0, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0]
const DEFAULT_TIME_SCALE := 4.0
const MAX_STEPS_PER_FRAME := 1000
const UI_REFRESH_S := 0.2
const PARK_OFFSET_PX := 20.0
const PASS_OFFSET_PX := 7.0
const LOG_LINES := 14
const CAR_SHAPE := [Vector2(-7, -3.5), Vector2(7, -2), Vector2(7, 2), Vector2(-7, 3.5)]

## Set by Main before the scene enters the tree.
var track_id: StringName = &"test_ring"

var sim: RaceSim
var time_scale := DEFAULT_TIME_SCALE
var _accumulator := 0.0
var _ui_timer := 0.0
var _car_nodes := {}      # RaceCarState -> PathFollow2D
var _prev_distance := {}  # RaceCarState -> race distance before the last tick
var _player_rows: Array[Dictionary] = []
var _log: Array[String] = []
var _fastest_lap := INF

@onready var track_layer: Node2D = $TrackLayer
@onready var path: Path2D = $TrackLayer/Path2D
@onready var header: Label = $UI/Header
@onready var speed_bar: HBoxContainer = $UI/SpeedBar
@onready var tower: RichTextLabel = $UI/Tower
@onready var log_label: RichTextLabel = $UI/Log
@onready var player_panel: VBoxContainer = $UI/PlayerPanel
@onready var results_panel: PanelContainer = $UI/Results
@onready var results_label: RichTextLabel = $UI/Results/VBox/Text
@onready var back_button: Button = $UI/Results/VBox/BackButton


func _ready() -> void:
	# Allows running this scene on its own (F6) for quick testing.
	if GameState.tracks.is_empty():
		TestWorld.build()
	var track: TrackData = GameState.tracks[track_id]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var start_tyres: Array[TyreCompound] = [GameState.tyre_compounds[0], GameState.tyre_compounds[1]]
	var entries := RaceSetup.entries_for_series(GameState.player_team().series_id, start_tyres, rng)
	sim = RaceSim.new(track, GameState.tyre_compounds, entries, rng.randi())

	sim.overtake.connect(_on_overtake)
	sim.pit_stop.connect(_on_pit_stop)
	sim.driver_mistake.connect(_on_mistake)
	sim.car_retired.connect(_on_retired)
	sim.lap_completed.connect(_on_lap_completed)
	sim.race_finished.connect(_on_race_finished)
	back_button.pressed.connect(func(): EventBus.hq_requested.emit())

	_build_track()
	_build_cars()
	_build_speed_bar()
	_build_player_panel()
	_refresh_ui()


func _process(delta: float) -> void:
	if not sim.is_finished:
		_accumulator += delta * time_scale
		var steps := 0
		while _accumulator >= RaceSim.TICK_S and steps < MAX_STEPS_PER_FRAME:
			for car in sim.cars:
				_prev_distance[car] = car.race_distance_m
			sim.step()
			_accumulator -= RaceSim.TICK_S
			steps += 1
		if steps == MAX_STEPS_PER_FRAME:
			_accumulator = 0.0  # machine too slow for this time scale

	# Interpolate between the last two ticks so cars move smoothly.
	var alpha := clampf(_accumulator / RaceSim.TICK_S, 0.0, 1.0)
	_update_cars(delta, alpha)

	_ui_timer -= delta
	if _ui_timer <= 0.0:
		_ui_timer = UI_REFRESH_S
		_refresh_ui()


# --- Building the scene ------------------------------------------------------

func _build_track() -> void:
	var curve := sim.track.curve
	path.curve = curve
	var points := curve.get_baked_points()
	track_layer.add_child(_make_line(points, 22.0, Color(0.55, 0.55, 0.5)))
	track_layer.add_child(_make_line(points, 16.0, Color(0.22, 0.22, 0.24)))
	track_layer.move_child(path, -1)

	# Start/finish line across the track.
	var start := curve.sample_baked(0.0)
	var normal := (curve.sample_baked(2.0) - start).normalized().orthogonal()
	var line := _make_line(PackedVector2Array([start - normal * 9.0, start + normal * 9.0]),
		3.0, Color.WHITE)
	line.closed = false
	track_layer.add_child(line)
	track_layer.move_child(path, -1)


func _make_line(points: PackedVector2Array, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.closed = true
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	return line


func _build_cars() -> void:
	for car in sim.cars:
		var follow := PathFollow2D.new()
		follow.loop = true
		follow.rotates = true
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array(CAR_SHAPE)
		body.color = car.team.primary_color
		follow.add_child(body)
		if car.is_player:
			var outline := Line2D.new()
			outline.points = PackedVector2Array(CAR_SHAPE)
			outline.closed = true
			outline.width = 1.5
			outline.default_color = Color.WHITE
			follow.add_child(outline)
		path.add_child(follow)
		_car_nodes[car] = follow
		_prev_distance[car] = car.race_distance_m


func _build_speed_bar() -> void:
	var group := ButtonGroup.new()
	for factor in TIME_SCALES:
		var button := Button.new()
		button.text = "II" if factor == 0.0 else "%dx" % factor
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = factor == time_scale
		button.pressed.connect(func(): time_scale = factor)
		speed_bar.add_child(button)


func _build_player_panel() -> void:
	for car in sim.cars:
		if car.is_player:
			_add_player_row(car)


func _add_player_row(car: RaceCarState) -> void:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = car.driver.full_name()
	name_label.custom_minimum_size.x = 120
	row.add_child(name_label)

	var pace_group := ButtonGroup.new()
	for mode in RaceCarState.PaceMode.values():
		var button := Button.new()
		button.text = RaceCarState.PaceMode.keys()[mode].capitalize()
		button.toggle_mode = true
		button.button_group = pace_group
		button.button_pressed = mode == car.pace_mode
		button.pressed.connect(func(): car.pace_mode = mode)
		row.add_child(button)

	var tyre_select := OptionButton.new()
	for compound in sim.compounds:
		tyre_select.add_item(compound.display_name)
	tyre_select.selected = 1
	tyre_select.item_selected.connect(func(i: int): car.next_tyre = sim.compounds[i])
	row.add_child(tyre_select)

	var box_button := Button.new()
	box_button.text = "Box this lap"
	box_button.toggle_mode = true
	box_button.toggled.connect(func(on: bool):
		car.pit_requested = on
		car.next_tyre = sim.compounds[tyre_select.selected])
	row.add_child(box_button)

	var status := Label.new()
	row.add_child(status)
	player_panel.add_child(row)
	_player_rows.append({"car": car, "box": box_button, "status": status})


# --- Per-frame updates -------------------------------------------------------

func _update_cars(delta: float, alpha: float) -> void:
	var lap_length := sim.track.lap_length_m
	var px_per_m := 1.0 / sim.profile.metres_per_px
	for car: RaceCarState in sim.cars:
		var follow: PathFollow2D = _car_nodes[car]
		var distance := lerpf(_prev_distance[car], car.race_distance_m, alpha)
		follow.progress = fposmod(distance, lap_length) * px_per_m

		var offset := 0.0
		if car.in_pit or car.is_finished or car.is_retired:
			offset = PARK_OFFSET_PX
		elif car.pass_target:
			offset = -PASS_OFFSET_PX
		follow.v_offset = lerpf(follow.v_offset, offset, minf(1.0, delta * 6.0))
		follow.modulate.a = 0.3 if car.is_retired else 1.0


func _refresh_ui() -> void:
	var leader := sim.order[0]
	var lap := mini(leader.laps_completed + 1, sim.track.laps)
	header.text = "%s   Lap %d/%d   %s" % [
		sim.track.name, maxi(lap, 1), sim.track.laps, _fmt_time(sim.time_s)]
	if sim.is_finished:
		header.text += "   FINISHED"

	var lines := PackedStringArray()
	for i in sim.order.size():
		lines.append(_tower_row(i, sim.order[i], leader))
	tower.text = "\n".join(lines)

	for row in _player_rows:
		var car: RaceCarState = row.car
		(row.box as Button).set_pressed_no_signal(car.pit_requested)
		var fuel_laps := car.fuel_kg / (RaceSim.FUEL_PER_LAP_KG * RaceSim.PACE_FUEL[car.pace_mode])
		var margin := fuel_laps - sim.laps_left(car)
		var state := "IN PIT" if car.in_pit else "%s %d%%" % [car.tyre.display_name, car.tyre_wear]
		(row.status as Label).text = "  %s   Fuel %+.1f laps" % [state, margin]


func _tower_row(pos: int, car: RaceCarState, leader: RaceCarState) -> String:
	var team_color := car.team.primary_color.to_html(false)
	var tyre_color := car.tyre.color.to_html(false)
	var gap := ""
	if car.is_retired:
		gap = "OUT"
	elif pos == 0:
		gap = "Leader"
	else:
		var laps_down := leader.laps_completed - car.laps_completed
		if laps_down >= 1 and leader.race_distance_m - car.race_distance_m > sim.track.lap_length_m:
			gap = "+%d Lap" % laps_down
		else:
			gap = "+%.1f" % car.gap_to_leader_s
	var flag := ""
	if car.in_pit:
		flag = " PIT"
	elif car.is_finished:
		flag = " F"
	var row := "%2d [color=#%s]■[/color] %-3s %-10s %8s [color=#%s]%s[/color]%3d%%%s" % [
		pos + 1, team_color, car.team.short_name, car.driver.last_name.left(10), gap,
		tyre_color, car.tyre.display_name.left(1), car.tyre_wear, flag]
	return "[b]%s[/b]" % row if car.is_player else row


# --- Race events -------------------------------------------------------------

func _on_overtake(attacker: RaceCarState, defender: RaceCarState) -> void:
	_add_log(attacker, "%s passes %s" % [attacker.driver.last_name, defender.driver.last_name])


func _on_pit_stop(car: RaceCarState) -> void:
	_add_log(car, "%s pits for %s" % [car.driver.last_name, car.next_tyre.display_name])


func _on_mistake(car: RaceCarState) -> void:
	_add_log(car, "%s makes a mistake" % car.driver.last_name)


func _on_retired(car: RaceCarState) -> void:
	_add_log(car, "[color=#ff6060]%s OUT: %s[/color]" % [car.driver.last_name, car.retire_reason])


func _on_lap_completed(car: RaceCarState) -> void:
	if car.laps_completed >= 2 and car.last_lap_time_s < _fastest_lap:
		_fastest_lap = car.last_lap_time_s
		_add_log(car, "[color=#c080ff]Fastest lap: %s %s[/color]" % [
			car.driver.last_name, _fmt_time(_fastest_lap)])


func _add_log(car: RaceCarState, text: String) -> void:
	var line := "L%d  %s" % [maxi(car.laps_completed + 1, 1), text]
	if car.is_player:
		line = "[b]%s[/b]" % line
	_log.push_front(line)
	if _log.size() > LOG_LINES:
		_log.pop_back()
	log_label.text = "\n".join(_log)


func _on_race_finished() -> void:
	var lines := PackedStringArray(["[b]Race result - %s[/b]\n" % sim.track.name])
	for i in sim.order.size():
		var car := sim.order[i]
		var result := car.retire_reason if car.is_retired else \
			(_fmt_time(car.finish_time_s) if i == 0 else "+%.1fs" % car.gap_to_leader_s)
		lines.append("%2d. %-18s %-3s %12s  best %s  stops %d" % [
			i + 1, car.driver.full_name(), car.team.short_name, result,
			_fmt_time(car.best_lap_time_s), car.pit_stops])
	results_label.text = "\n".join(lines)
	results_panel.visible = true
	_refresh_ui()


static func _fmt_time(seconds: float) -> String:
	if is_inf(seconds):
		return "-"
	return "%d:%06.3f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]
