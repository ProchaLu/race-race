## A sponsor contract, or an offer for one (docs/finance_model.md 12).
class_name SponsorDeal
extends Resource

@export var sponsor_id: StringName
@export var team_id: StringName
@export var tier: SponsorData.Tier = SponsorData.Tier.MINOR
## Paid after every race weekend while the contract runs.
@export var payment_per_race: int = 0
## Paid once when the contract is signed.
@export var signing_bonus: int = 0
## Paid at the end of a season whose constructors' position is good enough.
@export var bonus_amount: int = 0
## Constructors' position the bonus needs at the end of the season.
@export var bonus_target: int = 10
@export var years: int = 1
@export var start_year: int = 0
## Last season of the contract.
@export var end_year: int = 0
## 0..100. Missed targets lower it; a low value ends the contract early.
@export var satisfaction: int = 70
## Offers only: the date key (Sponsors.now_key) until which the offer stands.
@export var expires_key: int = 0
