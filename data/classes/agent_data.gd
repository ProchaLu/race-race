## A player agent (manager) who negotiates contracts for drivers.
## Staff members usually negotiate for themselves.
class_name AgentData
extends PersonData

enum Style { HARD, FAIR, FRIENDLY, PROUD }

@export var style: Style = Style.FAIR
## Offers the agent tolerates before ending the talks.
@export_range(2, 6) var patience: int = 4


static func style_name(s: Style) -> String:
	return ["Hard negotiator", "Fair dealer", "Friendly", "Proud"][s]


## Satisfaction needed before this agent accepts.
static func accept_threshold(s: Style) -> int:
	return [88, 82, 78, 85][s]
