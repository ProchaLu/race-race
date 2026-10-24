## What a calendar track is like, for the weekend hub, the calendar and the
## home screen: character, risks and how well it suits a team's car.
## Values come from the weekend simulation's track model, so the screens
## show what really matters in the race.
class_name TrackInfo
extends RefCounted

static var _models := {}
static var _ranges := {}


static func model(track_id: StringName) -> TrackModel:
	if not _models.has(track_id):
		_models[track_id] = TrackModel.build(GameState.tracks[track_id])
	return _models[track_id]


static func layout(track_id: StringName) -> Dictionary:
	return TrackLayouts.get_layout(track_id) if TrackLayouts.has_layout(track_id) else {}


## Raw values used for the bars: downforce share, power share, overtaking, tyre wear.
static func _values(track_id: StringName) -> Dictionary:
	var m := model(track_id)
	var data := layout(track_id)
	return {"downforce": m.rating_share.downforce, "power": m.rating_share.power + m.rating_share.drag,
		"mech": m.rating_share.mech, "overtaking": m.overtaking_index(), "wear": data.get("wear", 1.0)}


## Min and max of every value over all calendar tracks (for 0..1 bars).
static func _range(key: String) -> Vector2:
	if _ranges.is_empty():
		for id in TrackLayouts.LAYOUTS:
			if not GameState.tracks.has(id):
				continue
			var v := _values(id)
			for k in v:
				var r: Vector2 = _ranges.get(k, Vector2(INF, -INF))
				_ranges[k] = Vector2(minf(r.x, v[k]), maxf(r.y, v[k]))
	return _ranges.get(key, Vector2(0, 1))


## 0..1: where this track lies between the lowest and highest on the calendar.
static func relative(track_id: StringName, key: String) -> float:
	var r := _range(key)
	if r.y - r.x < 0.0001:
		return 0.5
	return clampf((_values(track_id)[key] - r.x) / (r.y - r.x), 0.0, 1.0)


static func level_word(v: float) -> String:
	if v >= 0.8:
		return "Very high"
	if v >= 0.6:
		return "High"
	if v >= 0.4:
		return "Medium"
	if v >= 0.2:
		return "Low"
	return "Very low"


## Bars for the "track character" card: [label, 0..1, word].
static func bars(track_id: StringName) -> Array:
	var out := []
	for entry in [["Downforce", "downforce"], ["Engine power", "power"], ["Mechanical grip", "mech"], ["Tyre wear", "wear"]]:
		var v := relative(track_id, entry[1])
		out.append([entry[0], v, level_word(v)])
	var o := relative(track_id, "overtaking")
	out.append(["Overtaking", o, "Easy" if o >= 0.6 else ("Medium" if o >= 0.3 else "Difficult")])
	return out


## One word for the calendar: "Power", "Downforce", "Mech. grip" or "Balanced".
static func character(track_id: StringName) -> String:
	var best := "Balanced"
	var best_v := 0.68
	for entry in [["Power", "power"], ["Downforce", "downforce"], ["Mech. grip", "mech"]]:
		var v := relative(track_id, entry[1])
		if v > best_v:
			best_v = v
			best = entry[0]
	return best


static func rain_chance(track_id: StringName) -> float:
	return layout(track_id).get("rain", 0.0)


static func is_hot(track_id: StringName) -> bool:
	var temp: Array = layout(track_id).get("temp", [30, 40])
	return temp[1] >= 50


static func safety_car_likely(track_id: StringName) -> bool:
	return layout(track_id).get("sc", 1.0) >= 1.5


static func pit_loss(track_id: StringName) -> float:
	return model(track_id).pit_lane_loss_s


## A car's strength at this track, weighted by what the track rewards.
static func car_score(car: CarData, track_id: StringName) -> float:
	var share := model(track_id).rating_share
	var total: float = share.power + share.drag + share.downforce + share.mech
	if total <= 0.0:
		return (car.engine_power + car.drag_efficiency + car.downforce + car.mechanical_grip) / 4.0
	return (car.engine_power * share.power + car.drag_efficiency * share.drag
		+ car.downforce * share.downforce + car.mechanical_grip * share.mech) / total


## How well the track suits a team's car compared with its usual place in
## the field: {"rank": int, "usual": int, "value": 0..100, "label": String}.
static func suitability(team_id: StringName, track_id: StringName) -> Dictionary:
	var team: TeamData = GameState.teams[team_id]
	var s: SeriesData = GameState.series[team.series_id]
	var here := []
	var usual := []
	for id in s.team_ids:
		var car: CarData = GameState.teams[id].car
		here.append([id, car_score(car, track_id)])
		usual.append([id, (car.engine_power + car.drag_efficiency + car.downforce + car.mechanical_grip) / 4.0])
	here.sort_custom(func(a, b): return a[1] > b[1])
	usual.sort_custom(func(a, b): return a[1] > b[1])
	var rank := 1 + here.map(func(e): return e[0]).find(team_id)
	var usual_rank := 1 + usual.map(func(e): return e[0]).find(team_id)
	var n := s.team_ids.size()
	var value := 100.0 * (n - rank) / maxf(n - 1, 1)
	var label := "OK"
	if rank < usual_rank:
		label = "Good"
	elif rank > usual_rank:
		label = "Weak"
	return {"rank": rank, "usual": usual_rank, "value": value, "label": label}


static func suitability_color(label: String) -> Color:
	return {"Good": UIStyle.GOOD, "Weak": UIStyle.BAD}.get(label, UIStyle.WARN)
