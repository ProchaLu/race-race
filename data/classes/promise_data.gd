## A promise the team principal made to a person (design doc 3.6).
class_name PromiseData
extends Resource

enum Status { OPEN, KEPT, BROKEN }

@export var person_id: StringName
@export var description: String
@export var status: Status = Status.OPEN
## Human-readable date the promise was made, e.g. "Jan 2026".
@export var made_on: String
## Round by which the promise must be fulfilled (0 = no deadline).
@export var deadline_round: int = 0
## Morale change if the promise is broken.
@export var morale_penalty: int = -15
