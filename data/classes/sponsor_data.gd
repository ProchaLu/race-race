## A company that pays a team for exposure and results.
class_name SponsorData
extends Resource

enum Tier { TITLE, MAJOR, MINOR }

@export var id: StringName
@export var name: String
@export var tier: Tier = Tier.MINOR

## Paid once per race weekend.
@export var payment_per_race: int = 0
## Extra money when the bonus target is met.
@export var bonus_amount: int = 0
## Target finishing position for the bonus (e.g. 10 = points finish).
@export var bonus_target_position: int = 10

## Minimum team reputation required before the sponsor will talk to you.
@export_range(0, 100) var required_reputation: int = 0
