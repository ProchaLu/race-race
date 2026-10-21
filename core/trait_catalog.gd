## All driver traits: name, icon, whether positive, and their effects.
class_name TraitCatalog
extends RefCounted

const TRAITS := {
	&"rain_master": {
		"name": "Rain master", "icon": "cloud-rain", "positive": true,
		"desc": "Faster and makes fewer mistakes in the wet",
		"effects": [["Wet driving", "+2"], ["Mistakes in the wet", "-30 %"]],
	},
	&"quali_specialist": {
		"name": "Quali specialist", "icon": "timer", "positive": true,
		"desc": "Extra speed over a single qualifying lap",
		"effects": [["Pace in qualifying", "+1.5 %"]],
	},
	&"tyre_whisperer": {
		"name": "Tyre whisperer", "icon": "clock", "positive": true,
		"desc": "Makes every set of tyres last longer",
		"effects": [["Tyre wear", "-12 %"]],
	},
	&"rocket_start": {
		"name": "Rocket start", "icon": "play", "positive": true,
		"desc": "Often gains places off the line",
		"effects": [["Reaction time at the start", "-25 %"]],
	},
	&"team_player": {
		"name": "Team player", "icon": "users", "positive": true,
		"desc": "Accepts team orders without losing morale",
		"effects": [["Morale loss after team orders", "none"]],
	},
	&"media_darling": {
		"name": "Media darling", "icon": "handshake", "positive": true,
		"desc": "Popular with fans and sponsors",
		"effects": [["Sponsor satisfaction", "+10 %"], ["Fan growth", "+15 %"]],
	},
	&"mentor": {
		"name": "Mentor", "icon": "graduation-cap", "positive": true,
		"desc": "Helps young teammates develop faster",
		"effects": [["Teammate development (under 24)", "+20 %"]],
	},
	&"evergreen": {
		"name": "Evergreen", "icon": "clock", "positive": true,
		"desc": "Stays at his peak far longer than others",
		"effects": [["Age decline", "-60 %"]],
	},
	&"clutch": {
		"name": "Clutch performer", "icon": "trophy", "positive": true,
		"desc": "At his best when it matters most",
		"effects": [["Pace in final laps and title deciders", "+1 %"]],
	},
	&"hot_headed": {
		"name": "Hot-headed", "icon": "flame", "positive": false,
		"desc": "More collisions, reacts badly to team orders",
		"effects": [["Collision risk", "+25 %"], ["Morale loss after team orders", "x2"]],
	},
	&"glass_nerves": {
		"name": "Glass nerves", "icon": "flame", "positive": false,
		"desc": "Makes mistakes under pressure",
		"effects": [["Mistakes when fighting for position", "+40 %"]],
	},
	&"tyre_killer": {
		"name": "Tyre killer", "icon": "timer", "positive": false,
		"desc": "Wears out his tyres quickly",
		"effects": [["Tyre wear", "+15 %"]],
	},
	&"slow_learner": {
		"name": "Slow learner", "icon": "clock", "positive": false,
		"desc": "Needs more time on new tracks",
		"effects": [["Track knowledge gain", "-40 %"]],
	},
}


static func get_trait(id: StringName) -> Dictionary:
	return TRAITS.get(id, {"name": str(id), "icon": "check", "positive": true, "desc": "", "effects": []})


static func breakdown(id: StringName) -> Breakdown:
	var t := get_trait(id)
	var b := Breakdown.new(t.name, t.desc)
	var tone := Breakdown.Tone.POSITIVE if t.positive else Breakdown.Tone.NEGATIVE
	for effect in t.effects:
		b.add(effect[0], effect[1], tone)
	return b
