## Runs one full race without graphics and prints the result.
## Usage: godot --headless --path . res://tools/sim_test.tscn
extends Node


func _ready() -> void:
	TestWorld.build()
	var track: TrackData = GameState.tracks[&"test_ring"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var start_tyres: Array[TyreCompound] = [GameState.tyre_compounds[0], GameState.tyre_compounds[1]]
	var entries := RaceSetup.entries_for_series(&"f1", start_tyres, rng)
	var sim := RaceSim.new(track, GameState.tyre_compounds, entries, 12345)

	_print_profile(sim)

	var stats := {"overtakes": 0, "mistakes": 0}
	sim.overtake.connect(func(_a, _b): stats.overtakes += 1)
	sim.driver_mistake.connect(func(_c): stats.mistakes += 1)
	sim.car_retired.connect(func(c: RaceCarState):
		print("  L%d  %s OUT: %s" % [c.laps_completed + 1, c.driver.last_name, c.retire_reason]))
	sim.pit_stop.connect(func(c: RaceCarState):
		print("  L%d  %s pits -> %s" % [c.laps_completed, c.driver.last_name, c.next_tyre.display_name]))

	var started := Time.get_ticks_msec()
	while not sim.is_finished:
		sim.step()
	print("\nSimulated %.0f s of racing in %d ms" % [sim.time_s, Time.get_ticks_msec() - started])
	print("Overtakes: %d, mistakes: %d\n" % [stats.overtakes, stats.mistakes])

	for i in sim.order.size():
		var c := sim.order[i]
		var result := c.retire_reason if c.is_retired else "+%.1fs" % c.gap_to_leader_s
		print("%2d. %-10s %-4s grid %2d  best %s  stops %d  %s" % [
			i + 1, c.driver.last_name, c.team.short_name, c.grid_position,
			_fmt(c.best_lap_time_s), c.pit_stops, result])
	get_tree().quit()


func _print_profile(sim: RaceSim) -> void:
	var p := sim.profile
	var ideal := 0.0
	for v in p.speed:
		ideal += TrackProfile.STEP_M / v
	print("Track: %s, %.0f m, %.2f m/px, reference lap %s" % [
		sim.track.name, p.lap_length_m, p.metres_per_px, _fmt(ideal)])
	for seg in sim.track.segments:
		print("  %6.0f-%6.0f m  %-13s %3.0f km/h  overtake %.2f" % [
			seg.start_m, seg.end_m, TrackSegment.Type.keys()[seg.type],
			seg.base_speed_kmh, seg.overtake_chance])


static func _fmt(seconds: float) -> String:
	if is_inf(seconds):
		return "-"
	return "%d:%06.3f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]
