## The 1-on-1 talk with a driver before the race (design doc 11.2, mockup
## r2_driver_talk.html).
## Weekly talk: one topic from his situation, four answers, small effects
## for this race. Talk on the driver's request: rare, three questions and a
## talk mood that rises and falls and scales the lasting effects.
## How a driver reacts to an answer is only known once you have tried it;
## the same line twice in a row works less.
class_name DriverTalk
extends RefCounted

enum Kind { WEEKLY, REQUEST }

## Effect keys. This race (SimCar.talk): confidence, composure, focus (points),
## aggression, mistake, contact (fractions), setup (% setup), team_orders.
## Lasting: morale, relationship (with you), loyalty, promise (text).
const RACE_KEYS := ["confidence", "composure", "focus", "aggression", "mistake", "contact", "setup", "team_orders"]
const LASTING_KEYS := ["morale", "relationship", "loyalty", "promise"]
const REPEAT_FACTOR := 0.7

## Weekly answer tones: [name, what you say, his reply, effects]
const TONES := {
	"ambition": ["Share the ambition", "Then let's go for it. You can beat anyone here.", "That's what I wanted to hear.",
		{"confidence": 4, "aggression": 0.1}],
	"grounded": ["Keep him grounded", "Good feeling, but take what the race gives you. No silly risks.", "Fair. Patience then.",
		{"composure": 4, "mistake": -0.06}],
	"technical": ["Ask about the car", "What exactly does the car need? Go through it with your engineer.", "Good idea. I have a few things for him.",
		{"setup": 1.5, "relationship": 1}],
	"rivalry": ["Rivalry", "The others say you're not quick enough. Prove them wrong.", "Did they now. Tomorrow they'll see.",
		{"aggression": 0.15, "contact": 0.15, "confidence": 2}],
	"reassure": ["Reassure him", "One bad day changes nothing. We believe in you.", "Thanks. I needed that.",
		{"confidence": 5, "morale": 1}],
	"demand": ["Demand more", "That was not good enough. I expect more on Sunday.", "Understood.",
		{"focus": 6, "composure": -3, "morale": -2}],
	"no_pressure": ["Take the pressure off", "No targets today. Just drive your race.", "OK. Just drive.",
		{"composure": 5, "mistake": -0.08, "aggression": -0.1}],
	"team": ["Team spirit", "We win and lose as a team. Help your teammate if you can.", "Sure. Team first.",
		{"team_orders": 1, "relationship": 1}],
}

## Weekly topics: [id, his question, answer tones]
const TOPICS := {
	"good_quali": ["P%d! The car felt great – I think we can fight for the podium tomorrow.", ["ambition", "grounded", "technical", "rivalry"]],
	"bad_quali": ["P%d… I don't know what happened. The car just wasn't there.", ["reassure", "technical", "demand", "no_pressure"]],
	"after_dnf": ["After last weekend I just want a clean race. I still think about that retirement.", ["reassure", "no_pressure", "demand", "technical"]],
	"after_podium": ["Last week's podium felt amazing. I want more of that.", ["ambition", "grounded", "rivalry", "team"]],
	"teammate": ["%s is ahead of me again. I need to find something.", ["technical", "rivalry", "reassure", "demand"]],
	"contract": ["Any news about next year? My manager keeps asking.", ["reassure", "demand", "team", "no_pressure"]],
	"weak_track": ["This track doesn't suit our car. Points will be hard.", ["grounded", "ambition", "technical", "no_pressure"]],
	"generic": ["Ready for the race. Anything special you want from me?", ["ambition", "grounded", "technical", "team"]],
}

## Talk on his request: three questions. Answer: [name, say, reply, mood, effects, condition]
const REQUEST_Q1 := {
	"favoured": "Can we talk? Honestly… everything here is built around %s. He gets the better calls. I'm starting to wonder if I have a future here.",
	"low": "Can we talk? Honestly… nothing works for me right now. I'm starting to wonder if I have a future here.",
}
const REQUEST_ROUNDS := [
	[
		["Admit it, fix it", "You're right. From now on you get the same treatment as your teammate.", "…OK. That's more than I expected. Thank you.", 30,
			{"morale": 6, "promise": "Equal treatment with the teammate"}, ""],
		["Show the data", "Look at the numbers with me – here is why things went the way they did.", "Hm. I didn't see it like that. Still feels bad, but OK.", 15,
			{"morale": 2, "confidence": 3}, ""],
		["Back him publicly", "I'll tell the press tomorrow that you are a key part of our future.", "You'd say that? In public?", 25,
			{"morale": 5, "loyalty": 2}, ""],
		["Tough love", "Futures are earned. Beat your teammate and the question answers itself.", "So it's my fault. Great. Really great.", -35,
			{"morale": -5, "focus": 6, "composure": -6}, ""],
		["Talk contract", "Let's sit down about an extension soon.", "Seriously? Yes. Yes, let's do that.", 35,
			{"morale": 8, "promise": "Contract talks soon"}, "contract"],
		["Not now", "This is not the moment. Focus on the race.", "Right. As always.", -50,
			{"morale": -8, "relationship": -4, "composure": -5}, ""],
	],
	[
		["Yes, earn it", "Whoever is ahead after qualifying gets the first call. Same rule for both.", "Fair rules. That's all I want.", 25,
			{"confidence": 5}, ""],
		["Honest no", "No. Your teammate leads for us this year. That won't change.", "…At least you're honest.", -15,
			{"morale": -3, "team_orders": 1}, ""],
		["Dodge", "Let's see how the weekend goes first.", "That's not an answer.", -20,
			{"relationship": -3}, ""],
		["Humour", "Outqualify him first, then I'll buy the dinner too.", "Ha. Deal. I'll pick an expensive place.", 15,
			{"relationship": 2, "confidence": 2}, ""],
	],
	[
		["Give your word", "You have my word. Look me in the eye.", "OK. I'm in.", 15,
			{"confidence": 3, "loyalty": 2}, ""],
		["Results first", "Trust goes both ways. Show me on Sunday.", "Fine. Sunday then.", 0,
			{"focus": 4}, ""],
		["Bring in the coach", "I'd like you to work with our mental coach on the pressure side this month.", "Maybe that's not a bad idea.", 10,
			{"composure": 3, "morale": 1}, ""],
	],
]
const REQUEST_Q2 := "And if I'm faster than him? Do I get the priority then?"
const REQUEST_Q3 := "Can I trust you on this?"

var driver: DriverData
var kind: Kind = Kind.WEEKLY
var topic := ""
## Each round: {"q": [format, args], "answers": [{"tone", "name", "say", "reply", "mood", "fx"}]}
var rounds: Array = []
var picks: Array[int] = []
## The effects each picked answer really had (for the conversation view).
var pick_fx: Array[Dictionary] = []
## Talk mood -100..100 (requested talks; scales all effects at the end).
var mood := 0
var start_mood := 0
## Tones whose reaction the mental coach revealed for this talk.
var revealed: Array = []
var done := false
## Collected effects for this race and lasting ones (already scaled when done).
var race_fx := {}
var lasting_fx := {}


# --- Creating a talk ---------------------------------------------------------

static func weekly(car: SimCar, w: RaceWeekend) -> DriverTalk:
	var t := DriverTalk.new()
	t.driver = car.driver
	t.kind = Kind.WEEKLY
	var pick := _weekly_topic(car, w)
	t.topic = pick[0]
	var entry: Array = TOPICS[t.topic]
	var answers := []
	for tone in entry[1]:
		var data: Array = TONES[tone]
		answers.append({"tone": tone, "name": data[0], "say": data[1], "reply": data[2], "mood": 0, "fx": data[3]})
	t.rounds = [{"q": [entry[0], pick[1]], "answers": answers}]
	t._coach_reveals(w)
	return t


## The mental coach knows the driver: he tells you how he reacts to one
## answer, a good coach to two.
func _coach_reveals(w: RaceWeekend) -> void:
	var memory := memory_of(driver.id)
	var unknown := []
	for a in rounds[0].answers:
		if not memory.known.has(a.tone):
			unknown.append(a.tone)
	var count := 2 if w.coach_skill() >= 0.6 else 1
	while count > 0 and not unknown.is_empty():
		var tone: String = unknown.pop_at(w.rng.randi() % unknown.size())
		memory.known[tone] = true
		revealed.append(tone)
		count -= 1


## The driver asks for a talk: returns the talk or null.
static func request(car: SimCar, w: RaceWeekend) -> DriverTalk:
	var trigger := _request_trigger(car, w)
	if trigger == "":
		return null
	var t := DriverTalk.new()
	t.driver = car.driver
	t.kind = Kind.REQUEST
	t.topic = trigger
	t.mood = -30 if trigger == "favoured" else -20
	t.start_mood = t.mood
	var mate := GameState.teammate_of(car.driver)
	var q1_args := [mate.last_name if mate else "?"] if trigger == "favoured" else []
	var questions := [[REQUEST_Q1[trigger], q1_args], [REQUEST_Q2, []], [REQUEST_Q3, []]]
	var contract := GameState.contract_of(car.driver.id)
	var contract_open := contract and contract.end_year <= Calendar.year + 1
	for i in REQUEST_ROUNDS.size():
		var answers := []
		for a in REQUEST_ROUNDS[i]:
			if a[5] == "contract" and not contract_open:
				continue
			answers.append({"tone": a[0], "name": a[0], "say": a[1], "reply": a[2], "mood": a[3], "fx": a[4]})
		t.rounds.append({"q": questions[i], "answers": answers})
	return t


## [topic id, args] from the driver's situation.
static func _weekly_topic(car: SimCar, w: RaceWeekend) -> Array:
	var d := car.driver
	var stats: DriverSeasonStats = GameState.season_stats.get(d.id)
	var last: Dictionary = stats.results.back() if stats and not stats.results.is_empty() else {}
	if car.grid_position > 0 and car.grid_position <= 5:
		return ["good_quali", [car.grid_position]]
	if not last.is_empty() and last.finish == 0:
		return ["after_dnf", []]
	if not last.is_empty() and last.finish >= 1 and last.finish <= 3:
		return ["after_podium", []]
	if car.grid_position >= 12:
		return ["bad_quali", [car.grid_position]]
	var mate := GameState.teammate_of(d)
	if mate and stats and stats.head_to_head_rounds >= 4 and stats.quali_ahead * 2 < stats.head_to_head_rounds:
		return ["teammate", [mate.last_name]]
	var c := GameState.contract_of(d.id)
	if c and c.end_year <= Calendar.year and Calendar.date_of().month >= 6:
		return ["contract", []]
	if TrackLayouts.has_layout(w.track.id) and TrackInfo.suitability(car.team.id, w.track.id).label == "Weak":
		return ["weak_track", []]
	return ["generic", []]


## Something real makes him ask: team orders against him, very low morale,
## or a run without points while his teammate scores. Not more often than
## every five rounds.
static func _request_trigger(car: SimCar, w: RaceWeekend) -> String:
	var d := car.driver
	var memory := memory_of(d.id)
	if memory.get("last_request", -99) > GameState.resolved_rounds - 5:
		return ""
	var c := GameState.contract_of(d.id)
	var favoured := (w.orders == RaceWeekend.Orders.PRIORITY and w.priority_driver != &"" and w.priority_driver != d.id) \
		or (c and c.role == ContractData.DriverRole.NUMBER_TWO)
	if favoured and d.morale < 60 and w.rng.randf() < 0.35:
		return "favoured"
	if d.morale < 40 and w.rng.randf() < 0.5:
		return "low"
	var stats: DriverSeasonStats = GameState.season_stats.get(d.id)
	var mate := GameState.teammate_of(d)
	if stats and mate and GameState.season_stats.has(mate.id):
		var mine := stats.last_results(3)
		var theirs := GameState.season_stats[mate.id].last_results(3)
		var series: SeriesData = GameState.series[d.series_id]
		var my_points := mine.filter(func(r): return r.finish > 0 and r.finish <= series.points_table.size()).size()
		var their_points := theirs.filter(func(r): return r.finish > 0 and r.finish <= series.points_table.size()).size()
		if mine.size() == 3 and my_points == 0 and their_points >= 2 and w.rng.randf() < 0.4:
			return "low"
	return ""


# --- Memory: known reactions, repetition, history ----------------------------

static func memory_of(driver_id: StringName) -> Dictionary:
	if not GameState.talk_memory.has(driver_id):
		GameState.talk_memory[driver_id] = {"known": {}, "last_tone": "", "history": [], "last_request": -99}
	return GameState.talk_memory[driver_id]


func is_known(answer: Dictionary) -> bool:
	if kind == Kind.REQUEST:
		# Obvious lines are always known; the risky ones only once tried.
		return answer.mood >= 0 or memory_of(driver.id).known.has(answer.tone)
	return memory_of(driver.id).known.has(answer.tone)


func is_repeated(answer: Dictionary) -> bool:
	return kind == Kind.WEEKLY and memory_of(driver.id).last_tone == answer.tone


## A hint instead of the effects while the reaction is unknown.
func hint() -> String:
	if driver.temperament < 40:
		return "Not known yet – he is hot-headed"
	if driver.temperament > 65:
		return "Not known yet – he is calm, but proud"
	if driver.morale < 45:
		return "Not known yet – his morale is low"
	return "Not known yet"


# --- Effects -----------------------------------------------------------------

## Effects of an answer for this driver: base values changed by his personality.
func effects(answer: Dictionary) -> Dictionary:
	var fx: Dictionary = answer.fx.duplicate()
	var d := driver
	match answer.tone:
		"ambition":
			if d.temperament < 40:
				fx["contact"] = fx.get("contact", 0.0) + 0.1
		"rivalry":
			if d.temperament < 40:
				fx.aggression *= 1.5
				fx.contact *= 1.5
				fx.confidence += 2
			elif d.temperament > 65:
				for k in fx:
					fx[k] = fx[k] * 0.5
		"demand", "Tough love":
			if d.morale < 45 or d.temperament < 40:
				fx["morale"] = fx.get("morale", 0) - 3
				fx["composure"] = fx.get("composure", 0) - 3
		"reassure":
			if d.morale >= 70:
				fx = {"confidence": 2}
		"technical":
			if d.technical_feedback >= 65:
				fx["setup"] = 2.5
		"no_pressure":
			if d.composure < 45 or d.traits.has(&"glass_nerves"):
				fx["composure"] = 8
		"team":
			var c := GameState.contract_of(d.id)
			if c and c.role == ContractData.DriverRole.NUMBER_ONE:
				fx["morale"] = -2
			if d.loyalty >= 65:
				fx["relationship"] = 2
	if is_repeated(answer):
		for k in fx:
			if fx[k] is float or fx[k] is int:
				fx[k] = fx[k] * REPEAT_FACTOR
	return fx


## Readable effect lines: [[label, value text, tone (1 good / -1 bad / 0), lasting]].
## Labels are translation keys; a promise's value is one too.
static func effect_lines(fx: Dictionary) -> Array:
	var out := []
	for k in fx:
		var v = fx[k]
		match k:
			"confidence":
				out.append(["Confidence", "%+d" % roundi(v), signi(roundi(v)), false])
			"composure":
				out.append(["Composure", "%+d" % roundi(v), signi(roundi(v)), false])
			"focus":
				out.append(["Focus", "%+d" % roundi(v), signi(roundi(v)), false])
			"aggression":
				out.append(["Overtaking attempts", "%+d %%" % roundi(v * 100), 0, false])
			"mistake":
				out.append(["Mistakes", "%+d %%" % roundi(v * 100), -signi(roundi(v * 100)), false])
			"contact":
				out.append(["Contact risk", "%+d %%" % roundi(v * 100), -signi(roundi(v * 100)), false])
			"setup":
				out.append(["Setup", "%+.1f %%" % v, 1, false])
			"team_orders":
				out.append(["Accepts team orders", "Yes", 1, false])
			"morale":
				out.append(["Morale", "%+d" % roundi(v), signi(roundi(v)), true])
			"relationship":
				out.append(["Relationship with you", "%+d" % roundi(v), signi(roundi(v)), true])
			"loyalty":
				out.append(["Loyalty", "%+d" % roundi(v), signi(roundi(v)), true])
			"promise":
				out.append(["Promise", v, 0, true])
	return out


# --- Answering ---------------------------------------------------------------

func current_round() -> int:
	return picks.size()


func answer(index: int) -> void:
	if done:
		return
	var a: Dictionary = rounds[picks.size()].answers[index]
	picks.append(index)
	mood = clampi(mood + a.mood, -100, 100)
	var fx := effects(a)
	pick_fx.append(fx)
	for k in fx:
		var target := race_fx if k in RACE_KEYS else lasting_fx
		if k == "promise":
			target[k] = fx[k]
		else:
			target[k] = target.get(k, 0) + fx[k]
	var memory := memory_of(driver.id)
	memory.known[a.tone] = true
	if picks.size() >= rounds.size():
		_finish(a)


## Requested talks: the end mood scales everything (0.5x .. 1.5x for good
## effects, the other way round for bad ones).
func _finish(last: Dictionary) -> void:
	done = true
	var memory := memory_of(driver.id)
	if kind == Kind.REQUEST:
		var scale := 1.0 + mood / 200.0
		for dict in [race_fx, lasting_fx]:
			for k in dict:
				if dict[k] is float or dict[k] is int:
					var v: float = dict[k]
					dict[k] = v * (scale if v > 0 else 2.0 - scale)
		if mood <= -60:
			lasting_fx["morale"] = lasting_fx.get("morale", 0) - 5
		elif mood >= 60:
			lasting_fx["loyalty"] = lasting_fx.get("loyalty", 0) + 5
		memory.last_request = GameState.resolved_rounds
	else:
		memory.last_tone = last.tone
	_apply_lasting()
	var summary := "%s · %s" % ["Asked to talk" if kind == Kind.REQUEST else "Weekly 1-on-1", last.name]
	memory.history.append([GameState.resolved_rounds + 1, summary, mood if kind == Kind.REQUEST else 0])
	if kind == Kind.REQUEST and mood <= -60:
		_transfer_request_message()


func _apply_lasting() -> void:
	var morale := roundi(lasting_fx.get("morale", 0))
	if morale != 0:
		TeamMood.change_morale(driver, "1-on-1 talk", morale)
	var rel := roundi(lasting_fx.get("relationship", 0))
	if rel != 0:
		var r := GameState.relationship(driver.id, GameState.PLAYER_ID)
		var factors: Dictionary = r.factors.duplicate()
		factors["1-on-1 talks"] = factors.get("1-on-1 talks", 0) + rel
		GameState.set_relationship(driver.id, GameState.PLAYER_ID, factors)
	var loyalty := roundi(lasting_fx.get("loyalty", 0))
	if loyalty != 0:
		driver.loyalty = clampi(driver.loyalty + loyalty, 0, 100)
	if lasting_fx.has("promise"):
		var p := PromiseData.new()
		p.person_id = driver.id
		p.description = lasting_fx.promise
		p.made_on = "%s %d" % [Calendar.MONTHS[Calendar.date_of().month - 1], Calendar.year]
		p.morale_penalty = -12
		GameState.promises.append(p)


func _transfer_request_message() -> void:
	var msg := InboxMessage.new()
	msg.sender = "Sporting director"
	msg.subject = "%s wants to leave"
	msg.subject_args = [driver.full_name()]
	msg.priority = InboxMessage.Priority.IMPORTANT
	msg.icon = "user"
	msg.add_paragraph("After your talk %s told his manager he wants to leave the team. His morale has dropped.", [driver.full_name()])
	msg.link_screen = &"driver_profile"
	msg.link_args = {"driver_id": driver.id}
	msg.link_label = "Open profile"
	GameState.add_message(msg)


## The mental coach talks instead: picks what he thinks works best. A good
## coach knows the driver better (less noise).
func auto_answer(coach_skill: float, rng: RandomNumberGenerator) -> void:
	while not done:
		var answers: Array = rounds[picks.size()].answers
		var best := 0
		var best_score := -INF
		for i in answers.size():
			var score := _score(answers[i]) + rng.randfn(0.0, (1.0 - coach_skill) * 4.0)
			if score > best_score:
				best_score = score
				best = i
		answer(best)


func _score(a: Dictionary) -> float:
	var fx := effects(a)
	return a.mood * 0.08 + fx.get("confidence", 0) * 0.4 + fx.get("composure", 0) * 0.4 + fx.get("focus", 0) * 0.25 \
		- fx.get("mistake", 0.0) * 25.0 - fx.get("contact", 0.0) * 20.0 + fx.get("morale", 0) * 0.8 \
		+ fx.get("relationship", 0) * 0.5 + fx.get("setup", 0.0) * 0.8 + fx.get("loyalty", 0) * 0.3
