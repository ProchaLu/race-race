## A racing series (F1, F2, F3). Only the player's series is shown live;
## the others are simulated in the background.
class_name SeriesData
extends Resource

@export var id: StringName
@export var name: String
## 1 = top tier. Used for driver promotion logic.
@export var tier: int = 1
## True if races are watched live; false = instant background simulation.
@export var is_player_series: bool = false

## Points for positions 1, 2, 3, ...
@export var points_table: Array[int] = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
## Track IDs in calendar order.
@export var calendar: Array[StringName] = []
@export var team_ids: Array[StringName] = []
