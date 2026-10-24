## Runtime state of one car in the weekend simulation. Created fresh for
## every session; career data is only changed when results are applied.
class_name SimCar
extends RefCounted

enum Briefing { BRING_HOME, ATTACK, NO_PRESSURE, TEAM_PLAYER, NORMAL }
enum RainSetup { DRY, COMPROMISE, WET }

var driver: DriverData
var team: TeamData
var car_data: CarData
var ops: TeamOps
var is_player: bool = false
## Own random numbers for everything that happens to this car, so one
## car's different decision does not reshuffle the luck of all others.
var rng := RandomNumberGenerator.new()

# --- Weekend inputs --------------------------------------------------------
var setup_pct: float = 75.0
## -1 = low wing (fast on straights), 0 = balanced, 1 = high wing.
var wing: int = 0
var rain_setup: RainSetup = RainSetup.COMPROMISE
## 0..1: how much tyre data the team collected in practice (long runs).
var tyre_data: float = 0.4
var briefing: Briefing = Briefing.NORMAL
## Effects from the 1-on-1 talk, only for this race, e.g.
## {"confidence": 6, "mistake": -0.1, "composure": 6, "aggression": 0.15,
##  "contact": 0.12, "tyre_wear": 0.05, "focus": 5, "team_orders": true}
var talk := {}
## Team orders from the weekend policy: {"yield": true} lets the teammate
## pass, {"hold_after_stops": true} keeps positions once both have stopped.
var orders := {}
## Strategy plan picked by the team principal (StrategyPlanner.plans() entry);
## empty = the strategy chief plans as usual.
var chosen_plan := {}
var start_compound: StringName = &"medium"
## Seconds per lap from this weekend's form: driver day form plus how
## well the car suits the conditions (rolled once per weekend).
var weekend_s: float = 0.0

# --- Position --------------------------------------------------------------
var grid_position: int = 0
var laps_done: int = 0
var next_sector: int = 0
## Time at which the car enters its next sector.
var t_next: float = 0.0
var lap_start_t: float = 0.0
var finished: bool = false
var finish_t: float = 0.0
var retired: bool = false
var retire_reason: String = ""
var retire_lap: int = 0
var position: int = 0

# --- Tyres and fuel ----------------------------------------------------------
var compound: StringName = &"medium"
## Effective age in laps (wear factors make it grow faster or slower).
var tyre_wear_laps: float = 0.0
var tyre_laps: int = 0
## -1 cold .. 0 ideal .. 1 hot.
var tyre_temp: float = 0.0
var used_dry_compounds := {}
var fuel_kg: float = 0.0
var fuel_saving_kg_per_lap: float = 0.0

# --- Damage and failures -----------------------------------------------------
## part -> seconds per lap lost: front_wing, floor, sidepod, rear_wing, brakes, power
var damage := {}
var drs_broken: bool = false
var needs_nose: bool = false
var puncture: bool = false
var penalty_s: float = 0.0

# --- Strategy ----------------------------------------------------------------
## Remaining planned stops: [[lap, compound], ...]
var plan: Array = []
var pit_now: bool = false
var next_compound: StringName = &"hard"
## Strategist's estimate of the real tyre wear (1.0 = exact) per compound.
var deg_estimate := {}
var laps_stuck: int = 0

# --- Per-lap cache -------------------------------------------------------------
## Lap time fraction of the car per sector (car ratings + wing + aero damage).
var sector_frac := PackedFloat32Array()
## Uniform extra seconds this lap (driver, setup, tyres, fuel, weather, damage, form).
var lap_extra_s: float = 0.0
## Pending one-off loss in a given sector this lap: [sector, seconds, kind].
var lap_incident: Array = []
var lap_dirty_air: int = 0
var lap_breakdown := {}
## Time in this lap lost to pit stops and to safety car / VSC phases.
var lap_pit_s: float = 0.0
var lap_flag_s: float = 0.0

# --- Results -------------------------------------------------------------------
var lap_times := PackedFloat32Array()
var lap_positions := PackedInt32Array()
var lap_compounds: Array[StringName] = []
var best_lap: float = INF
## Sum of every lap time component over the race (seconds).
var breakdown_total := {}
## [{"lap", "stationary", "lane", "from", "to", "issue"}]
var stops: Array = []
var overtakes_made: int = 0
var overtakes_lost: int = 0
var mistakes: int = 0


func _init(p_driver: DriverData, p_team: TeamData, p_ops: TeamOps) -> void:
	driver = p_driver
	team = p_team
	car_data = p_team.car
	ops = p_ops


## Seeds the car's random numbers from a session seed and the driver.
func seed_random(session_seed: int) -> void:
	_seed_base = hash("%d:%s" % [session_seed, driver.id])
	rng.seed = _seed_base


## Fresh random numbers per lap: lap 30 gets the same luck no matter
## what the car did before (makes "what if" comparisons fair).
func reseed_lap(lap: int) -> void:
	rng.seed = hash("%d:%d" % [_seed_base, lap])


var _seed_base: int = 0


func is_running() -> bool:
	return not (finished or retired)


func driver_value(property: StringName) -> float:
	return float(driver.get(property))


func talk_value(key: String, default_value: float = 0.0) -> float:
	return talk.get(key, default_value)


func label() -> String:
	return driver.last_name


## Total race time used for the classification.
func race_time() -> float:
	return finish_t + penalty_s
