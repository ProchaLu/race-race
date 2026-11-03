## A junior team of the feeder series (F3, F2). Two seats, a strength rating
## and nothing else: juniors are simulated in the background (docs/youth_model.md).
class_name YouthTeam
extends Resource

@export var id: StringName
@export var name: String
@export var short_name: String
@export var color: Color = Color.WHITE
## "f3" or "f2" (see Youth).
@export var series_id: StringName
## 0..100: machinery and staff. Drifts a little from season to season.
@export_range(0, 100) var strength: int = 50
## The two drivers of the season (team_id of each driver points here).
@export var driver_ids: Array[StringName] = []
