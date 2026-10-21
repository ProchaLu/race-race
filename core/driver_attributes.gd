## Definition of all driver attributes and the 0-100 <-> 1-20 scale.
## Values are stored internally as 0..100; the UI shows 1..20.
class_name DriverAttributes
extends RefCounted

## [property name, display name]
const DRIVING := [
	[&"cornering", "Cornering"],
	[&"braking", "Braking"],
	[&"one_lap_pace", "One-lap pace"],
	[&"consistency", "Consistency"],
	[&"tyre_management", "Tyre management"],
	[&"fuel_management", "Fuel management"],
	[&"overtaking", "Overtaking"],
	[&"defending", "Defending"],
	[&"starts", "Starts"],
	[&"wet_skill", "Wet driving"],
	[&"racecraft", "Racecraft"],
]

const MENTAL := [
	[&"composure", "Composure"],
	[&"focus", "Focus"],
	[&"aggression", "Aggression"],
	[&"adaptability", "Adaptability"],
	[&"technical_feedback", "Technical feedback"],
	[&"work_ethic", "Work ethic"],
	[&"professionalism", "Professionalism"],
	[&"ambition", "Ambition"],
	[&"loyalty", "Loyalty"],
	[&"temperament", "Temperament"],
]

const PHYSICAL := [
	[&"fitness", "Fitness"],
	[&"reactions", "Reactions"],
]

## What each attribute does, shown in tooltips.
const DESCRIPTIONS := {
	&"cornering": "Speed through medium and slow corners.",
	&"braking": "Speed in braking zones; helps overtaking under braking.",
	&"one_lap_pace": "Extra speed over a single qualifying lap.",
	&"consistency": "Spread of lap times and how often mistakes happen.",
	&"tyre_management": "How slowly the tyres wear.",
	&"fuel_management": "Saving fuel and energy without losing much time.",
	&"overtaking": "Chance that an overtaking attempt succeeds.",
	&"defending": "Chance to keep an attacker behind.",
	&"starts": "Reaction and positions gained at the start.",
	&"wet_skill": "Speed and mistakes in wet conditions.",
	&"racecraft": "Duels, traffic, lapping and restarts.",
	&"composure": "Performance under pressure (title fights, final laps).",
	&"focus": "Mistakes late in races and during long stints.",
	&"aggression": "More overtaking attempts, but a higher crash risk.",
	&"adaptability": "How fast he learns new tracks, cars and rules.",
	&"technical_feedback": "Setup quality and development input for engineers.",
	&"work_ethic": "How much he gets out of training.",
	&"professionalism": "Stable morale and behaviour in the media.",
	&"ambition": "Salary demands and wish to drive for a top team.",
	&"loyalty": "Willingness to extend; resistance to offers.",
	&"temperament": "Reaction to team orders, criticism and bad luck.",
	&"fitness": "Pace drop late in races, injury risk and recovery.",
	&"reactions": "Starts and reacting to incidents.",
}


## 0..100 -> 1..20
static func to_display(internal: int) -> int:
	return clampi(ceili(internal / 5.0), 1, 20)


static func band_name(display_value: int) -> String:
	if display_value <= 5:
		return "Weak"
	if display_value <= 10:
		return "Average"
	if display_value <= 15:
		return "Good"
	return "Elite"


## 0..100 rating -> 0..5 stars in half steps.
static func to_stars(internal: int) -> float:
	return clampf(roundf(internal / 10.0) / 2.0, 0.0, 5.0)
