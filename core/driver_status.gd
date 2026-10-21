## Labels and explanations (Breakdowns) for a driver's state.
## Keeps the "why" of every number in one place for the UI.
## Plain English texts are translated by the labels showing them; texts
## with values are translated here with Loc.f().
class_name DriverStatus
extends RefCounted


## Five-step label for 0..100 values like morale and confidence.
static func level_label(value: int) -> String:
	if value >= 80:
		return "Very high"
	if value >= 65:
		return "High"
	if value >= 45:
		return "Okay"
	if value >= 30:
		return "Low"
	return "Very low"


static func form_label(form: int) -> String:
	if form >= 60:
		return "Rising"
	if form <= 40:
		return "Falling"
	return "Stable"


static func relationship_label(value: int) -> String:
	if value >= 50:
		return "Excellent"
	if value >= 20:
		return "Good"
	if value > -20:
		return "Neutral"
	if value > -50:
		return "Tense"
	return "Hostile"


static func attribute_breakdown(d: DriverData, property: StringName, display_name: String) -> Breakdown:
	var internal: int = d.get(property)
	var shown := DriverAttributes.to_display(internal)
	var b := Breakdown.new("%s %d · %s" % [Loc.t(display_name), shown, Loc.t(DriverAttributes.band_name(shown))],
		DriverAttributes.DESCRIPTIONS.get(property, ""))
	b.add("Exact value", "%d / 100" % internal)
	var change: int = d.attribute_changes.get(property, 0)
	b.add_delta("Change this season", change)
	if d.training_focus == property:
		b.add("Training focus", Loc.t("yes"), Breakdown.Tone.POSITIVE)
	if property == &"wet_skill" and d.traits.has(&"rain_master"):
		b.add("Trait: Rain master", Loc.t("included"), Breakdown.Tone.POSITIVE)
	return b


static func morale_breakdown(d: DriverData) -> Breakdown:
	var b := Breakdown.new(Loc.f("Morale: %s (%d / 100)", [Loc.t(level_label(d.morale)), d.morale]),
		"Morale changes race pace by up to ±1.5 %.")
	b.add("Neutral base", "50")
	for reason in d.morale_factors:
		b.add_delta(reason, d.morale_factors[reason])
	return b


static func form_breakdown(d: DriverData) -> Breakdown:
	var b := Breakdown.new(Loc.f("Form: %s", [Loc.t(form_label(d.form))]),
		"Short-term trend from the last 3 to 5 race weekends.")
	var stats: DriverSeasonStats = GameState.season_stats.get(d.id)
	if stats:
		var line := PackedStringArray()
		for r in stats.last_results(5):
			line.append("P%d" % r.finish if r.finish > 0 else Loc.t("OUT"))
		b.add("Last results", " ".join(line))
	b.add("Form value", "%d / 100" % d.form)
	return b


static func confidence_breakdown(d: DriverData) -> Breakdown:
	return Breakdown.new(Loc.f("Confidence: %s (%d / 100)", [Loc.t(level_label(d.confidence)), d.confidence]),
		"Rises with wins and beating the teammate, drops after crashes.")


static func fitness_breakdown(d: DriverData) -> Breakdown:
	var b := Breakdown.new(Loc.f("Fitness %d %%", [d.match_fitness]),
		"Below 85 % the driver loses pace late in races.")
	b.add("Fitness attribute", str(DriverAttributes.to_display(d.fitness)))
	b.add_delta("Race schedule", d.match_fitness - 100)
	return b


static func injury_breakdown(d: DriverData) -> Breakdown:
	if d.injury_weeks > 0:
		return Breakdown.new(Loc.f("Injured for %d weeks", [d.injury_weeks]), "A reserve driver must race instead.")
	return Breakdown.new("No injury", "Injury risk depends on crash severity and fitness.")


static func training_breakdown(d: DriverData) -> Breakdown:
	var focus := attribute_name(d.training_focus) if d.training_focus != &"" else "Balanced"
	var b := Breakdown.new(Loc.f("Training focus: %s", [Loc.t(focus)]),
		"You set the focus. How much he improves depends on the driver himself.")
	b.add("Work ethic", str(DriverAttributes.to_display(d.work_ethic)))
	b.add("Professionalism", str(DriverAttributes.to_display(d.professionalism)))
	return b


static func ability_breakdown(d: DriverData) -> Breakdown:
	var b := Breakdown.new(Loc.f("Current ability %d / 100", [d.overall()]),
		"Weighted mix of all attributes. Shown as stars in lists.")
	var driving := 0.0
	for entry in DriverAttributes.DRIVING:
		driving += d.get(entry[0])
	b.add("Driving attributes (75 %)", "%.0f" % (driving / DriverAttributes.DRIVING.size()))
	b.add("Composure, focus, adaptability, feedback (15 %)", "%.0f" % ((d.composure + d.focus + d.adaptability + d.technical_feedback) / 4.0))
	b.add("Fitness, reactions (10 %)", "%.0f" % ((d.fitness + d.reactions) / 2.0))
	return b


static func potential_breakdown(d: DriverData) -> Breakdown:
	var age := d.age(Calendar.year)
	var b := Breakdown.new(Loc.f("Potential %d / 100", [d.potential]),
		"Hidden for other teams' drivers until scouting exists; then shown as an estimate.")
	b.add("Room to grow", "%+d" % (d.potential - d.overall()))
	b.add("Age", Loc.f("%d (peak %d–%d)", [age, d.peak_start_age, d.peak_end_age]))
	return b


static func relationship_breakdown(title: String, rel: Dictionary) -> Breakdown:
	var b := Breakdown.new("%s: %s (%+d)" % [Loc.t(title), Loc.t(relationship_label(rel.value)), rel.value])
	for reason in rel.factors:
		b.add_delta(reason, rel.factors[reason])
	return b


static func attribute_name(property: StringName) -> String:
	for group in [DriverAttributes.DRIVING, DriverAttributes.MENTAL, DriverAttributes.PHYSICAL]:
		for entry in group:
			if entry[0] == property:
				return entry[1]
	return str(property)
