## Pit stop model (docs/simulation_model.md, section 4): stationary time
## from the crew's stop speed, spread and problems from its precision.
## A perfect crew never makes serious mistakes – at worst it hesitates.
class_name PitCrew
extends RefCounted

enum Issue { NONE, HESITATION, SLOW_WHEEL, STUCK_NUT, UNSAFE_RELEASE, LOOSE_WHEEL }

const ISSUE_NAMES := {
	Issue.NONE: "",
	Issue.HESITATION: "Hesitation",
	Issue.SLOW_WHEEL: "Slow wheel change",
	Issue.STUCK_NUT: "Stuck wheel nut",
	Issue.UNSAFE_RELEASE: "Unsafe release",
	Issue.LOOSE_WHEEL: "Loose wheel",
}


## pressure: 1.0 normal; higher for double stacks, safety car, wet stops.
## Returns {"stationary": s, "issue": Issue, "penalty": s, "retire": bool}.
static func stop(ops: TeamOps, extra_work_s: float, pressure: float, rng: RandomNumberGenerator) -> Dictionary:
	var typical := SimTuning.curve(SimTuning.STOP_CURVE, ops.stop_speed)
	var precision := ops.precision / 100.0
	var sigma := lerpf(SimTuning.STOP_SIGMA_MAX, SimTuning.STOP_SIGMA_MIN, precision)
	var t := typical + absf(rng.randfn(0.0, sigma)) - sigma * 0.5
	t = maxf(SimTuning.STOP_MIN_S, t)

	var result := {"stationary": 0.0, "issue": Issue.NONE, "penalty": 0.0, "retire": false}
	# Problem risk grows with the square-ish of imprecision; 95+ = no serious issues.
	var u := clampf((95.0 - ops.precision) / 75.0, 0.0, 1.0)
	var serious := pow(u, SimTuning.ISSUE_EXPONENT) * pressure
	var roll := rng.randf()
	var loose := SimTuning.LOOSE_WHEEL_MAX * serious
	var unsafe := SimTuning.UNSAFE_RELEASE_MAX * serious * (1.3 - ops.regulations / 100.0)
	var stuck := SimTuning.STUCK_NUT_MAX * serious
	var slow := SimTuning.SLOW_WHEEL_MAX * serious
	var hesitation := (SimTuning.HESITATION_BASE + SimTuning.HESITATION_MAX * u) * pressure
	if roll < loose:
		result.issue = Issue.LOOSE_WHEEL
		result.retire = true
	elif roll < loose + unsafe:
		result.issue = Issue.UNSAFE_RELEASE
		result.penalty = SimTuning.UNSAFE_RELEASE_PENALTY_S
	elif roll < loose + unsafe + stuck:
		result.issue = Issue.STUCK_NUT
		t += rng.randf_range(8.0, 25.0)
	elif roll < loose + unsafe + stuck + slow:
		result.issue = Issue.SLOW_WHEEL
		t += rng.randf_range(2.0, 6.0)
	elif roll < loose + unsafe + stuck + slow + hesitation:
		result.issue = Issue.HESITATION
		t += rng.randf_range(0.3, 1.5) * (0.6 if u == 0.0 else 1.0)
	result.stationary = t + extra_work_s
	return result
