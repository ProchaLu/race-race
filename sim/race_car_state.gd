## Runtime state of one car during a race. Created fresh for every race
## and never saved as a Resource, so career data is not touched by accident.
class_name RaceCarState
extends RefCounted

enum PaceMode { CONSERVE, NORMAL, PUSH }
## Something that will happen to the car later in the current lap.
enum PendingEvent { NONE, MISTAKE, FAILURE }

var driver: DriverData
var team: TeamData
var car_data: CarData
var is_player: bool = false
var grid_position: int = 0

# Position on track. race_distance_m is the total distance since the
# start line; the grid starts slightly negative (behind the line).
var race_distance_m: float = 0.0
var speed_mps: float = 0.0
var laps_completed: int = -1

# Strategy
var tyre: TyreCompound
var tyre_wear: float = 0.0  # 0 = new, 100 = destroyed
var fuel_kg: float = 0.0
var pace_mode: PaceMode = PaceMode.NORMAL
var pit_requested: bool = false
var next_tyre: TyreCompound
var pit_stops: int = 0

# Status
var in_pit: bool = false
## While > 0 the car does not move (start reaction, pit stop).
var stationary_timer: float = 0.0
## While > 0 the car is slowed down by a driving mistake.
var mistake_timer: float = 0.0
var pending_event: PendingEvent = PendingEvent.NONE
var event_at_m: float = 0.0
## Car currently being overtaken (null = not passing).
var pass_target: RaceCarState
var pass_timer: float = 0.0
## Daily form for the current lap, around 1.0.
var form: float = 1.0
var is_retired: bool = false
var retire_reason: String = ""
var is_finished: bool = false
var finish_time_s: float = 0.0

# Timing
var lap_start_time_s: float = 0.0
var last_lap_time_s: float = 0.0
var best_lap_time_s: float = INF
var gap_to_leader_s: float = 0.0
var gap_bucket: int = -1

# Performance multipliers, calculated once at race start.
var corner_factor: float = 1.0
var straight_factor: float = 1.0


func _init(p_driver: DriverData, p_team: TeamData, p_tyre: TyreCompound) -> void:
	driver = p_driver
	team = p_team
	car_data = p_team.car
	tyre = p_tyre
	next_tyre = p_tyre


## Distance from the start/finish line within the current lap.
func lap_distance(lap_length_m: float) -> float:
	return fposmod(race_distance_m, lap_length_m)


func is_running() -> bool:
	return not (is_retired or is_finished)
