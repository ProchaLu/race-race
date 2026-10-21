## An explained value: a title plus the factors it is made of.
## Game systems return these so the UI can show "why" in a tooltip.
class_name Breakdown
extends RefCounted

enum Tone { NEUTRAL, POSITIVE, NEGATIVE }

var title: String
## Each row: [label: String, value: String, tone: Tone]
var rows: Array = []
var note: String


func _init(p_title: String = "", p_note: String = "") -> void:
	title = p_title
	note = p_note


## Adds a row and returns self, so calls can be chained.
func add(label: String, value: String, tone: Tone = Tone.NEUTRAL) -> Breakdown:
	rows.append([label, value, tone])
	return self


## Adds a signed number row, coloured by its sign.
func add_delta(label: String, delta: int) -> Breakdown:
	var tone := Tone.POSITIVE if delta > 0 else (Tone.NEGATIVE if delta < 0 else Tone.NEUTRAL)
	return add(label, "%+d" % delta, tone)
