## Reputation and fans (R6d, docs/finance_model.md 13). Reputation opens doors:
## sponsors need a minimum, and the best offers go to the best-known teams.
## Fans bring merchandise money after every race. Both move with the season's
## position; the marketing building and a strong brand-building commercial
## manager add a little on top. The team principal's reputation (for the next
## job, R8) moves with the position of the player's team.
class_name TeamReputation
extends RefCounted

## Largest change of reputation or fans in one season.
const MAX_STEP := 4
## Merchandise income per race for every fan point.
const MERCH_PER_FAN := 15_000


static func merch_per_race(team: TeamData) -> int:
	return team.fans * MERCH_PER_FAN


## Extra reputation per season from the marketing building and the commercial manager.
static func brand_bonus(team: TeamData) -> int:
	var bonus := Facilities.level(team, &"hospitality") / 3
	for s in GameState.staff_of_team(team.id):
		if s.role == StaffData.Role.COMMERCIAL_MANAGER and s.attribute(&"brand_building") >= 75:
			bonus += 1
	return bonus


## End of the season: reputation and fans move with the position; the drivers'
## fame adds to the fans; the team principal's reputation follows the player's team.
static func season_end(series: SeriesData, table: Array) -> void:
	var n := series.team_ids.size()
	for id in series.team_ids:
		var team: TeamData = GameState.teams.get(id)
		if not team:
			continue
		var position := 0
		for i in table.size():
			if table[i][0] == id:
				position = i + 1
		var step := clampi(roundi((n + 1) / 2.0 - position), -MAX_STEP, MAX_STEP)
		team.reputation = clampi(team.reputation + step + brand_bonus(team), 0, 100)
		var fame := 0
		for driver in GameState.drivers_of_team(id):
			if driver.traits.has(&"media_darling"):
				fame = 1
		team.fans = clampi(team.fans + step + fame, 0, 100)
		if Owners.has_owner(team):
			team.owner.boss_reputation = clampi(team.owner.boss_reputation + step, 0, 100)
