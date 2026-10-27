## All balancing numbers of the weekend simulation in one place
## (see docs/simulation_model.md). Seconds are given for a 90 s reference
## lap and scaled to the real track with lap_scale().
class_name SimTuning
extends RefCounted

const REFERENCE_LAP_S := 90.0

# --- Car (1.1) -----------------------------------------------------------
## Lap time fraction per rating point (0.05 s on a 90 s lap).
const CAR_FRAC_PER_POINT := 0.00055
## How each corner type uses the car ratings:
## [power, drag, downforce, mech grip, braking, traction]. Braking and
## traction come from the parts (R3); together with mech grip they keep the
## old mechanical share.
const CAR_WEIGHTS := {
	# Exit speed out of the corner before carries along the straight.
	TrackSegment.Type.STRAIGHT: [0.45, 0.3, 0.15, 0.04, 0.0, 0.06],
	TrackSegment.Type.FAST_CORNER: [0.1, 0.0, 0.75, 0.15, 0.0, 0.0],
	TrackSegment.Type.MEDIUM_CORNER: [0.05, 0.0, 0.5, 0.33, 0.07, 0.05],
	TrackSegment.Type.SLOW_CORNER: [0.05, 0.0, 0.25, 0.4, 0.18, 0.12],
}
## Wing level: [straight fraction, corner fraction] per step (high = +1).
const WING_STRAIGHT_FRAC := 0.004
const WING_CORNER_FRAC := -0.003
const WING_TYRE_WEAR := -0.05

# --- Driver (1.2) --------------------------------------------------------
const DRIVER_FRAC_PER_POINT := 0.00022
const DRIVER_PACE_CENTER := 75.0
const DRIVER_QUALI_ONE_LAP_WEIGHT := 0.5
const CONFIDENCE_S := 0.08
const FITNESS_LATE_S := 0.2
const FITNESS_LATE_FROM := 0.6
const ROOKIE_TRACK_S := 0.3
const ROOKIE_RACES := 20
const FORM_SIGMA_MIN_S := 0.15
const FORM_SIGMA_MAX_S := 0.45
## Weekend-to-weekend swing: driver day form and how well the car suits
## the conditions (seconds, 1 sigma). Form 0..100 shifts the driver.
const WEEKEND_DRIVER_SIGMA_MIN_S := 0.08
const WEEKEND_DRIVER_SIGMA_MAX_S := 0.18
const WEEKEND_CAR_SIGMA_S := 0.12
const FORM_ATTRIBUTE_S := 0.06

# --- Setup (1.3): [setup %, seconds] ------------------------------------
const SETUP_CURVE := [[0.0, 1.6], [30.0, 1.0], [50.0, 0.6], [70.0, 0.25], [85.0, 0.0], [100.0, -0.2]]
const SETUP_MAX_MISTAKE := 0.3
const SETUP_MAX_WEAR := 0.12
## Rain gamble: [dry seconds, wet seconds] for DRY, COMPROMISE, WET.
const RAIN_SETUP := [[-0.1, 0.6], [0.0, 0.25], [0.3, -0.15]]

# --- Tyres (2) -----------------------------------------------------------
## id: [base s, deg s/lap, cliff lap, warm-up s, optimal track °C]
const COMPOUNDS := {
	&"soft": [0.0, 0.11, 18.0, 0.5, 30.0],
	&"medium": [0.45, 0.075, 28.0, 0.8, 38.0],
	&"hard": [0.85, 0.05, 40.0, 1.3, 46.0],
	&"inter": [0.0, 0.05, 30.0, 0.8, 25.0],
	&"wet": [0.0, 0.04, 40.0, 1.0, 20.0],
}
const DRY_COMPOUNDS: Array[StringName] = [&"soft", &"medium", &"hard"]
const CLIFF_S_PER_LAP := 0.5
const CLIFF_EXPONENT := 1.6
## Puncture chance per lap once the tyre is this many laps past its cliff.
const PUNCTURE_AFTER_CLIFF_LAPS := 3.0
const PUNCTURE_PER_LAP := 0.02
const TEMP_RANGE_C := 25.0
const TEMP_RESPONSE := 0.5
const TEMP_GRIP_S := 0.4
const TEMP_FREE_ZONE := 0.25
const GRAINING_WEAR := 0.5
const BLISTER_WEAR := 1.0
const DIRTY_AIR_WEAR := 0.1
const DIRTY_AIR_TEMP := 0.2
const ATTACK_TEMP := 0.15
const SC_TEMP := -0.6
const NEW_TYRE_TEMP := -0.5

# --- Fuel (3) ------------------------------------------------------------
const FUEL_KG_PER_KM := 0.33
const FUEL_S_PER_KG := 0.03
const FUEL_SAVE_COST_ACE := 1.0   # s per kg saved, fuel management 100
const FUEL_SAVE_COST_WEAK := 3.0  # s per kg saved, fuel management 0
const FUEL_SAVE_MAX_PER_LAP := 0.12
const SC_FUEL_FACTOR := 0.5

# --- Pit stops (4) -------------------------------------------------------
const STOP_MIN_S := 2.0
## [crew stop speed, typical stationary time]
const STOP_CURVE := [[0.0, 4.0], [25.0, 3.4], [50.0, 2.9], [75.0, 2.5], [100.0, 2.1]]
const STOP_SIGMA_MIN := 0.05
const STOP_SIGMA_MAX := 0.3
const HESITATION_BASE := 0.04
const HESITATION_MAX := 0.11
const SLOW_WHEEL_MAX := 0.08
const STUCK_NUT_MAX := 0.03
const UNSAFE_RELEASE_MAX := 0.015
const LOOSE_WHEEL_MAX := 0.004
const ISSUE_EXPONENT := 1.6
const PRESSURE_DOUBLE_STACK := 1.5
const PRESSURE_SC := 1.3
const PRESSURE_WET := 1.3
const DOUBLE_STACK_WAIT_S := 1.5
const NOSE_CHANGE_S := 8.0
const PIT_LOSS_SC := 0.55
const PIT_LOSS_VSC := 0.7
const UNSAFE_RELEASE_PENALTY_S := 5.0

# --- Strategy (5) --------------------------------------------------------
const ESTIMATE_SIGMA := 0.4
const TYRE_DATA_SIGMA_CUT := 0.5
const TRACK_POSITION_S_PER_STOP := 4.0

# --- Traffic and overtaking (6) -----------------------------------------
const MIN_GAP_S := 0.25
const DIRTY_AIR_GAP_S := 1.0
const DIRTY_AIR_FRAC := 0.035
const DRS_GAP_S := 1.0
const DRS_GAIN_FRAC := 0.015
const DRS_FROM_LAP := 3
const DRS_MAX_WETNESS := 0.35
const SLIPSTREAM_GAP_S := 0.6
const SLIPSTREAM_FRAC := 0.006
## Attempt if the margin beats ATTEMPT_BASE_S - ATTEMPT_AGGRESSION_S * aggression.
const ATTEMPT_BASE_S := 0.15
const ATTEMPT_AGGRESSION_S := 0.3
## Margin (s) at which an attempt succeeds half the time (before zone/skill).
const PASS_CENTER_S := 0.6
const PASS_SIGMOID_S := 0.12
const PASS_ZONE_FACTOR := 0.45
const PASS_MAX_CHANCE := 0.92
const FAILED_PASS_LOSS_S := 0.25
const DEFEND_LOSS_S := 0.12
const PASSED_LOSS_S := 0.15
const CONTACT_CHANCE := 0.004
const BLUE_FLAG_LOSS_S := 0.35
const LAP1_PASS_FACTOR := 1.5
const START_PASS_FACTOR := 0.8

# --- Start (10.1) --------------------------------------------------------
const GRID_SLOT_S := 0.2
const STANDING_START_S := 2.0
const LAUNCH_SKILL_S := 0.25
const LAUNCH_SIGMA_S := 0.15

# --- Mistakes, failures (8) ---------------------------------------------
const MISTAKE_BASE := 0.004
const MISTAKE_SMALL := [0.5, 1.5]
const MISTAKE_OFF := [3.0, 8.0]
const MISTAKE_SEVERITY := [0.78, 0.17, 0.05]   # small, off track, crash
const FAILURE_PER_RACE := 0.05

# --- Cooling (docs/car_model.md 2.3) --------------------------------------
const COOLING_BASE := 45.0
const COOLING_PER_DEGREE := 0.8
const COOLING_PER_POWER := 0.3
const COOLING_TRAFFIC := 3.0
## Cooling openings: one step changes the heat to get rid of by 5 and drag by 0.8 points.
const COOLING_OPENING := 5.0
const COOLING_OPENING_DRAG := 0.8
const COOLING_S_PER_POINT := 0.015
const COOLING_FAILURE_PER_POINT := 0.1
const FAILURE_FATAL_SHARE := 0.5

# --- Safety car (8.3) ----------------------------------------------------
const SC_PACE := 1.45
const SC_CATCH_UP := 0.25
const SC_GAP_S := 0.8
const VSC_PACE := 1.35
const SC_LAPS := [3, 6]
const VSC_TIME_S := [60.0, 150.0]

# --- Weather (9) ---------------------------------------------------------
const WET_GENERAL_FRAC := 0.12
const WET_SKILL_S := 0.025
const WET_SKILL_CENTER := 60.0
const SPRAY_MISTAKE := 1.5
const SPRAY_PASS := 0.85
## Wet braking zones make passing easier for whoever is faster.
const WET_PASS_BONUS := 0.6

# --- Qualifying (10.2) ---------------------------------------------------
const QUALI_FUEL_KG := 5.0
const QUALI_EVOLUTION_S := 0.4
const QUALI_TRAFFIC_CHANCE := 0.1
const QUALI_MISTAKE_CHANCE := 0.03


## Seconds on a 90 s lap -> seconds on this track.
static func lap_scale(reference_lap_s: float) -> float:
	return reference_lap_s / REFERENCE_LAP_S


## Linear interpolation in a sorted [[x, y], ...] table.
static func curve(table: Array, x: float) -> float:
	if x <= table[0][0]:
		return table[0][1]
	for i in range(1, table.size()):
		if x <= table[i][0]:
			var t: float = (x - table[i - 1][0]) / (table[i][0] - table[i - 1][0])
			return lerpf(table[i - 1][1], table[i][1], t)
	return table.back()[1]
