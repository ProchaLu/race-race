## One driver's results in one season.
class_name DriverSeasonStats
extends Resource

@export var driver_id: StringName
@export var year: int
@export var points: int = 0
@export var wins: int = 0
@export var podiums: int = 0
@export var poles: int = 0
@export var retirements: int = 0
## Each entry: {"round": int, "track_id": StringName, "grid": int, "finish": int}
## finish = 0 means the driver retired.
@export var results: Array[Dictionary] = []
# Head-to-head against the teammate
@export var quali_ahead: int = 0
@export var race_ahead: int = 0
@export var head_to_head_rounds: int = 0


func races() -> int:
	return results.size()


## Average position at the finish; retirements are not counted.
func average_finish() -> float:
	var total := 0
	var finished := 0
	for r in results:
		if r.finish > 0:
			total += r.finish
			finished += 1
	return total / float(finished) if finished > 0 else 0.0


func points_per_race() -> float:
	return points / float(races()) if races() > 0 else 0.0


func last_results(count: int) -> Array[Dictionary]:
	return results.slice(maxi(0, results.size() - count))
