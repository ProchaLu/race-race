## One contract negotiation with a person's agent (design doc 3.8, decisions
## 40/41). The conversation matters as much as the offer:
## satisfaction = offer score + rapport built by talking points.
## Every conversation draws its own set of talking points; answers depend on
## the agent's style and the situation, and risky points swing hard.
class_name Negotiation
extends RefCounted

enum Kind { EXTEND, SIGN }
enum State { OPEN, AGREED, FAILED }

## Talking points visible at the same time (plus "ask" and "final").
const VISIBLE_POINTS := 4
## [what you say, hint, risky, needs] – needs: "", "driver", "staff",
## "extend", "low_morale"
const POINTS := {
	&"ask": ["What matters most to %s?", "Reveals their priorities", false, ""],
	&"final": ["This is our final offer.", "Only works if you are already close", true, ""],
	&"future": ["%s is a key part of our future.", "Builds trust, stronger with a good offer", false, ""],
	&"car": ["Our car is about to make a big step.", "Eases worries about the car", false, "driver"],
	&"others": ["Nobody else can offer %s a role like this.", "Risky with a proud or hard agent", true, ""],
	&"build_around": ["We will build the team around %s.", "Big reward if ambitious, backfires if not", true, ""],
	&"praise": ["%s has been outstanding lately.", "Works if the recent results back it up", false, ""],
	&"form": ["%s's form has dropped lately.", "Can lower the demand, hurts the mood", true, "driver"],
	&"loyalty": ["%s has grown with this team.", "Appeals to loyalty", false, "extend"],
	&"meet": ["Let me talk to %s in person.", "Friendly agents like it, hard ones don't", false, ""],
	&"money_ok": ["Money will not be the problem.", "Better mood, but they will ask for more", false, ""],
	&"deadline": ["We need an answer this week.", "Fair agents respect it, others don't", true, ""],
	&"small_talk": ["How was the summer break?", "A little warmth, or a waste of time", false, ""],
	&"honesty": ["We know we haven't always treated %s well.", "Honesty after a hard time", false, "low_morale"],
	&"bluff": ["We have a cheaper candidate ready to sign.", "Very risky bluff: big win or big loss", true, ""],
	&"parts": ["%s will get new parts at the same time as the No.1.", "Adds a promise to the offer", false, "driver"],
	&"control": ["%s will have full control over the department.", "Ambitious staff love it", false, "staff"],
	&"reputation": ["Look where this team is heading.", "Depends on the team's reputation", false, ""],
}
## Used inside sentences ("Move on the salary ...").
const ASPECT_NAMES := {&"salary": "the salary", &"role": "the role", &"length": "the length", &"bonus": "the bonuses"}
## Used as labels in lists.
const ASPECT_LABELS := {&"salary": "Salary", &"role": "Role", &"length": "Length", &"bonus": "Bonuses"}

var person: PersonData
var agent: AgentData
var team: TeamData
var kind: Kind
var state := State.OPEN
## salary, years, role (drivers), win_bonus (drivers), signing_fee, release_clause, promise
var offer := {}
var demand := {}
## Aspect -> importance 1..3
var importance := {}
var rapport := 0
var patience := 4
var priorities_known := false
## Entries: {"who": "agent"/"you"/"system"/"offer", "key": String, "args": Array, "delta": int, "terms": Dictionary}
var thread: Array[Dictionary] = []
var points: Array[StringName] = []
var _used: Array[StringName] = []
var _rng := RandomNumberGenerator.new()


func _init(p_person: PersonData, p_kind: Kind) -> void:
	person = p_person
	kind = p_kind
	team = GameState.player_team()
	agent = ContractLogic.agent_of(person)
	patience = agent.patience if agent else 4
	_rng.seed = hash(str(person.id) + str(Calendar.day))
	_build_demand()
	_build_first_offer()
	thread.append({"who": "system", "key": "Talks started · %s", "args": [Calendar.format_date()]})
	_say(_opening_line(), [_name()])
	_draw_points()


# --- Setup -------------------------------------------------------------------

func is_driver() -> bool:
	return person is DriverData


func _build_demand() -> void:
	var age := person.age(Calendar.year)
	var ambition: int = person.get("ambition")
	demand.salary = ContractLogic.salary_demand(person)
	demand.years = 3 if age >= 31 else (2 if ambition >= 70 else 3)
	importance = {&"salary": 2, &"length": 1}
	if agent and agent.style == AgentData.Style.HARD:
		importance[&"salary"] = 3
	if age >= 31:
		importance[&"length"] = 3 if not is_driver() else 2
	if is_driver():
		demand.role = _demanded_role()
		demand.win_bonus = int(round(demand.salary * 0.06 / 10_000.0)) * 10_000
		importance[&"role"] = 3 if ambition >= 65 else 2
		importance[&"bonus"] = 1


func _demanded_role() -> ContractData.DriverRole:
	var d := person as DriverData
	var best := 0
	for other in GameState.drivers_of_team(team.id):
		if other != d:
			best = maxi(best, other.overall())
	if d.overall() >= best + 3:
		return ContractData.DriverRole.NUMBER_ONE
	if d.ambition >= 60 or d.overall() >= best - 2:
		return ContractData.DriverRole.EQUAL
	return ContractData.DriverRole.NUMBER_TWO


func _build_first_offer() -> void:
	var current := GameState.contract_of(person.id)
	var own := current and current.team_id == team.id
	offer.salary = current.salary if own else int(round(demand.salary * 0.8 / 100_000.0)) * 100_000
	offer.years = 2
	offer.signing_fee = 0
	offer.release_clause = true
	offer.promise = false
	# Signing from another team: their release clause must be paid.
	offer.transfer_fee = current.release_clause if current and not own else 0
	if is_driver():
		offer.role = current.role if own else mini(demand.role + 1, ContractData.DriverRole.NUMBER_TWO)
		if not own and team.driver_ids.size() >= ContractLogic.RACE_SEATS:
			offer.role = ContractData.DriverRole.RESERVE
		offer.win_bonus = current.win_bonus if own else int(demand.win_bonus * 0.6)


func _opening_line() -> String:
	if kind == Kind.SIGN:
		return ["%s is listening. Make it worth the move.", "We've heard you're interested in %s. Let's see your proposal."][_rng.randi() % 2]
	if person.morale < 45:
		return "I'll be honest: %s is frustrated and other teams have called me."
	return ["%s is happy here, but this contract has to reflect that.", "Good to sit down. %s wants to stay – on the right terms."][_rng.randi() % 2]


func _draw_points() -> void:
	points.clear()
	if not priorities_known:
		points.append(&"ask")
	var pool: Array[StringName] = []
	for id in POINTS:
		if id in [&"ask", &"final"] or _used.has(id) or not _allowed(id):
			continue
		pool.append(id)
	_shuffle(pool)
	for id in pool:
		if points.size() >= VISIBLE_POINTS + (1 if not priorities_known else 0):
			break
		points.append(id)
	points.append(&"final")


func _allowed(id: StringName) -> bool:
	match POINTS[id][3]:
		"driver":
			return is_driver()
		"staff":
			return not is_driver()
		"extend":
			return kind == Kind.EXTEND
		"low_morale":
			return person.morale < 45
	return true


# --- Scores ------------------------------------------------------------------

## How good the offer is on each aspect (0..1.1).
func aspect_scores() -> Dictionary:
	var scores := {}
	scores[&"salary"] = clampf(1.0 - (demand.salary - offer.salary) / (demand.salary * 0.5), 0.0, 1.15)
	scores[&"length"] = clampf(1.0 - absf(demand.years - offer.years) * 0.22, 0.0, 1.0)
	if is_driver():
		# Lower enum value = better role.
		var diff: int = offer.role - demand.role
		scores[&"role"] = 1.1 if diff < 0 else ([1.0, 0.5, 0.15, 0.0][mini(diff, 3)])
		scores[&"bonus"] = clampf(float(offer.win_bonus) / maxf(demand.win_bonus, 1.0), 0.0, 1.1)
	return scores


func offer_score() -> int:
	var scores := aspect_scores()
	var total := 0.0
	var weights := 0.0
	for aspect in importance:
		total += scores[aspect] * importance[aspect]
		weights += importance[aspect]
	var extras := minf(offer.signing_fee / maxf(demand.salary, 1.0) * 25.0, 10.0)
	extras += 0.0 if offer.release_clause else 4.0
	extras += 5.0 if offer.promise else 0.0
	return roundi(total / weights * 100.0 + extras)


func satisfaction() -> int:
	return clampi(offer_score() + rapport, 0, 100)


func accept_at() -> int:
	return AgentData.accept_threshold(agent.style) if agent else 82


func weakest_aspect() -> StringName:
	var scores := aspect_scores()
	var worst := &"salary"
	for aspect in scores:
		if scores[aspect] * importance[aspect] < scores[worst] * importance[worst]:
			worst = aspect
	return worst


## Aspects ordered by importance (most important first).
func priorities() -> Array:
	var list := importance.keys()
	list.sort_custom(func(a, b): return importance[a] > importance[b])
	return list


func cost_per_year() -> int:
	return offer.salary + (offer.get("win_bonus", 0) * 2)


# --- Conversation ------------------------------------------------------------

func use_point(id: StringName) -> void:
	if state != State.OPEN or not points.has(id):
		return
	_used.append(id)
	var line: String = POINTS[id][0]
	thread.append({"who": "you", "key": line, "args": [_name()] if "%s" in line else []})
	var result := _resolve(id)
	var delta: int = _styled(result.delta)
	rapport += delta
	if result.get("patience", 0) != 0:
		patience = maxi(0, patience + result.patience)
	_say(result.reply, result.get("args", []), delta)
	_draw_points()
	_check_patience()


func send_offer() -> void:
	if state != State.OPEN:
		return
	patience = maxi(0, patience - 1)
	thread.append({"who": "offer", "terms": offer.duplicate()})
	var sat := satisfaction()
	if sat >= accept_at():
		state = State.AGREED
		_say(["We have a deal. %s will sign within the next days.", "Done. Get the papers ready – %s will sign this week.", "That works. Congratulations, you've got %s."][_rng.randi() % 3])
		return
	var aspect: String = Loc.t(ASPECT_NAMES[weakest_aspect()])
	if sat >= accept_at() - 20:
		if weakest_aspect() == &"salary":
			_say("Close. But %s won't sign for less than %s per year.", [_name(), UIStyle.money(int(demand.salary * 0.97))])
		else:
			_say(["We're getting closer. Move on %s and we have something.", "Almost there – %s is still the sticking point."][_rng.randi() % 2], [aspect])
	elif sat >= 40:
		if _rng.randi() % 2 == 0:
			_say("That's still far from what %s is worth.", [_name()])
		else:
			_say("I need to see real movement, especially on %s.", [aspect])
	else:
		_say(["Is this a joke? I'll pretend I didn't see that.", "With respect, that offer is an insult to %s."][_rng.randi() % 2])
	_check_patience()


func walk_away() -> void:
	if state != State.OPEN:
		return
	thread.append({"who": "you", "key": "Let's leave it here for now.", "args": []})
	_say("Your call. Don't be surprised if %s listens to other teams now.")
	state = State.FAILED


func _check_patience() -> void:
	if state == State.OPEN and patience <= 0:
		_say("That's enough. We're done talking – for now.", [])
		thread.append({"who": "system", "key": "Talks ended. %s won't negotiate for 30 days.", "args": [_name()]})
		state = State.FAILED


## Reaction to a talking point: {"delta", "reply", "args", "patience"}.
func _resolve(id: StringName) -> Dictionary:
	var style := agent.style if agent else AgentData.Style.FAIR
	var hard := style in [AgentData.Style.HARD, AgentData.Style.PROUD]
	var ambition: int = person.get("ambition")
	match id:
		&"ask":
			priorities_known = true
			var p := priorities()
			return {"delta": 2, "reply": "For %s it's mainly about %s, then %s.",
				"args": [_name(), Loc.t(ASPECT_NAMES[p[0]]), Loc.t(ASPECT_NAMES[p[1]])]}
		&"final":
			if satisfaction() >= accept_at() - 10:
				return {"delta": 10, "reply": "Alright. You drive a hard bargain – send it over."}
			return {"delta": -9, "patience": -1, "reply": "Then I think we're done here. That doesn't come close."}
		&"future":
			if aspect_scores().get(&"role", 1.0) >= 0.9:
				return {"delta": 6, "reply": _pick(["That's exactly what %s needed to hear.", "Good. %s wants to build something here."])}
			return {"delta": 1, "reply": "Nice words. Show it in the contract."}
		&"car":
			var rank := car_rank()
			if rank <= 4:
				return {"delta": 3, "reply": "%s knows the car is good. That's not the issue."}
			if hard and rank > 8:
				return {"delta": -2, "reply": "Words are cheap. Show me lap times."}
			return {"delta": 5, "reply": _pick(["That helps. %s was worried about the car.", "Encouraging. Keep me updated on that."])}
		&"others":
			if style == AgentData.Style.FRIENDLY:
				return {"delta": 3, "reply": "You may have a point there."}
			if hard:
				return {"delta": -8, "patience": -1, "reply": _pick(["Really? I have two offers on my desk that say otherwise.", "Let's not play games. %s has options."])}
			return {"delta": -3, "reply": "I'm not sure that's true."}
		&"build_around":
			if ambition >= 65:
				return {"delta": 12, "reply": _pick(["Now we're talking. That's what %s wants.", "That changes things. %s wants to lead."])}
			return {"delta": -5, "reply": "%s doesn't want that kind of pressure."}
		&"praise":
			if _recent_success():
				return {"delta": 4, "reply": _pick(["%s appreciates that.", "Kind words – and true."])}
			return {"delta": -3, "reply": "Outstanding? Let's be realistic."}
		&"form":
			if (person as DriverData).form < 45:
				demand.salary = int(demand.salary * 0.92)
				return {"delta": -6, "reply": "That's harsh... but fair. We can adjust our numbers a little."}
			return {"delta": -10, "reply": "%s's form is fine. That was uncalled for."}
		&"loyalty":
			if person.get("loyalty") >= 60:
				return {"delta": 7, "reply": _pick(["That matters to %s. A lot.", "True. %s doesn't forget that."])}
			return {"delta": -2, "reply": "Loyalty doesn't pay the bills."}
		&"meet":
			if hard:
				return {"delta": 0, "reply": "I speak for %s. Talk to me."}
			return {"delta": 6, "reply": "%s would like that. Good idea."}
		&"money_ok":
			demand.salary = int(demand.salary * 1.08)
			return {"delta": 6, "reply": "Then let's talk numbers. %s will want a little more."}
		&"deadline":
			if style == AgentData.Style.FAIR:
				return {"delta": 3, "reply": "Clear words. Fine, we'll be quick."}
			if hard:
				return {"delta": -7, "patience": -1, "reply": "Nobody rushes %s. Remember that."}
			return {"delta": -2, "reply": "That's a bit much, isn't it?"}
		&"small_talk":
			match style:
				AgentData.Style.FRIENDLY:
					return {"delta": 4, "reply": _pick(["Lovely, thanks! Spent it at the lake.", "Too short, as always. Thanks for asking."])}
				AgentData.Style.HARD:
					return {"delta": -2, "reply": "Let's stay focused."}
			return {"delta": 1, "reply": "Fine, thanks. So, the contract."}
		&"honesty":
			return {"delta": 4 if hard else 8, "reply": "I appreciate the honesty. That goes a long way with %s."}
		&"bluff":
			if _rng.randf() < 0.5:
				demand.salary = int(demand.salary * 0.88)
				return {"delta": -2, "reply": "...Fine. We can be flexible on the money."}
			return {"delta": -15, "patience": -1, "reply": "Then sign your cheap candidate. We're not desperate."}
		&"parts":
			offer.promise = true
			return {"delta": 8, "reply": "That would mean a lot to %s. Put it in writing."}
		&"control":
			if ambition >= 60:
				return {"delta": 9, "reply": "That's what %s has been waiting for."}
			return {"delta": 3, "reply": "Good to know. %s values a clear role."}
		&"reputation":
			if team.reputation >= 60:
				return {"delta": 5, "reply": "True, the team has a strong name right now."}
			if team.reputation < 45:
				return {"delta": -4, "reply": "Heading where? The results don't show it yet."}
			return {"delta": 2, "reply": "We'll see. The results will tell."}
	return {"delta": 0, "reply": "I see."}


## Agent style scales reactions: friendly agents forgive, proud ones don't.
func _styled(delta: int) -> int:
	var style := agent.style if agent else AgentData.Style.FAIR
	if delta >= 0:
		return roundi(delta * [0.7, 1.0, 1.3, 0.9][style])
	return roundi(delta * [1.2, 1.0, 0.7, 1.5][style])


func _say(key: String, args: Array = [], delta: int = 0) -> void:
	if args.is_empty() and "%s" in key:
		args = [_name()]
	thread.append({"who": "agent", "key": key, "args": args, "delta": delta})


func _name() -> String:
	return person.first_name


func _pick(options: Array) -> String:
	return options[_rng.randi() % options.size()]


func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := _rng.randi() % (i + 1)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


func car_rank() -> int:
	return TeamMood.car_rank(team.id)


func _recent_success() -> bool:
	if not is_driver():
		return person.morale >= 50
	var stats: DriverSeasonStats = GameState.season_stats.get(person.id)
	if not stats or stats.results.is_empty():
		return false
	var last: Dictionary = stats.results.back()
	return last.finish > 0 and last.finish <= 6


## Display text of a thread entry in the current language.
static func entry_text(entry: Dictionary) -> String:
	var args: Array = entry.get("args", [])
	return Loc.f(entry.key, args) if not args.is_empty() else Loc.t(entry.key)
