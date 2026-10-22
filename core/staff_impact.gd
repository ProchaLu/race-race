## "Impact on the team": turns a staff member's attributes into concrete
## effects per role. Each row: [effect, value text, tone, made from].
## The numbers drive the related systems as they are built (R2-R7).
class_name StaffImpact
extends RefCounted


static func rows(s: StaffData) -> Array:
	var a := func(p: StringName) -> int: return s.attribute(p)
	var out := []
	match s.role:
		StaffData.Role.TECHNICAL_DIRECTOR:
			out.append(_pct("Development speed of all parts", (a.call(&"organisation") + s.expertise) / 2, 0.4, "Organisation, expertise"))
			out.append(_pct("Chance of a breakthrough", a.call(&"innovation"), 0.5, "Innovation"))
			out.append(_pct("Output of the technical departments", s.leadership, 0.3, "Leadership"))
		StaffData.Role.CHIEF_DESIGNER:
			out.append(_pct("Design time per part", a.call(&"design_speed"), -0.4, "Design speed", true))
			out.append(_pct("Quality of new parts", a.call(&"detail_work"), 0.3, "Detail work"))
			out.append(_pct("Chance of a bold new concept", a.call(&"creativity"), 0.5, "Creativity"))
		StaffData.Role.HEAD_OF_AERO:
			out.append(_pct("Downforce gain per upgrade", a.call(&"aero_knowledge"), 0.4, "Aero knowledge"))
			out.append(_pct("Wind tunnel prediction accuracy", a.call(&"correlation"), 0.6, "Correlation"))
		StaffData.Role.HEAD_OF_CHASSIS:
			out.append(_pct("Mechanical grip gain per upgrade", a.call(&"mechanical_knowledge"), 0.4, "Mechanical knowledge"))
			out.append(_pct("Weight saved per part", a.call(&"weight_saving"), 0.3, "Weight saving"))
			out.append(_pct("Part failures", a.call(&"reliability_focus"), -0.5, "Reliability focus", true))
		StaffData.Role.ENGINE_CHIEF:
			out.append(_pct("Power gain per upgrade", a.call(&"power_development"), 0.4, "Power development"))
			out.append(_pct("Fuel use", a.call(&"efficiency"), -0.2, "Efficiency", true))
			out.append(_pct("Engine failures", a.call(&"reliability_focus"), -0.5, "Reliability focus", true))
		StaffData.Role.FACTORY_MANAGER:
			out.append(_pct("Production time", a.call(&"production_speed"), -0.4, "Production speed", true))
			out.append(_pct("Faulty parts", a.call(&"quality_control"), -0.6, "Quality control", true))
			out.append(_pct("Production cost", a.call(&"cost_control"), -0.3, "Cost control", true))
		StaffData.Role.SPORTING_DIRECTOR:
			out.append(_pct("Contract terms when delegated", a.call(&"negotiation"), 0.3, "Negotiation"))
			out.append(_pct("Risk of penalties", a.call(&"regulations"), -0.6, "Regulations", true))
			out.append(_pct("Morale of drivers and staff", a.call(&"people_management"), 0.2, "People management"))
		StaffData.Role.RACE_ENGINEER:
			var driver: DriverData = GameState.drivers.get(s.assigned_driver_id)
			var who := driver.last_name if driver else Loc.t("the driver")
			var chemistry: int = GameState.relationship(s.id, s.assigned_driver_id).value if driver else 0
			var seconds: float = (a.call(&"setup_work") - 50) / 250.0 + chemistry / 1000.0
			out.append([Loc.f("Setup quality for %s", [who]), "%+.2f s/lap" % -seconds,
				_tone(seconds), Loc.t("Setup work, chemistry with the driver")])
			out.append(_pct("Strategy communication errors", a.call(&"communication"), -0.7, "Communication", true))
			out.append(_pct("Tyre data accuracy before the race", (a.call(&"tyre_knowledge") + a.call(&"data_analysis")) / 2, 0.4, "Tyre knowledge, data analysis"))
		StaffData.Role.STRATEGY_CHIEF:
			out.append(_pct("Tyre wear prediction accuracy", a.call(&"tyre_model"), 0.5, "Tyre model"))
			out.append(_pct("Right calls in changing weather", a.call(&"weather_reading"), 0.6, "Weather reading"))
			out.append(_pct("Gains under safety car", a.call(&"race_reading"), 0.5, "Race reading"))
		StaffData.Role.PIT_CREW_CHIEF:
			var stop: float = 2.6 - (a.call(&"stop_speed") - 50) / 100.0
			out.append([Loc.t("Average pit stop"), "%.2f s" % stop, _tone(2.6 - stop), Loc.t("Stop speed")])
			out.append(_pct("Slow or unsafe stops", a.call(&"precision"), -0.7, "Precision", true))
			out.append(_pct("Crew improvement per month", a.call(&"crew_training"), 0.3, "Crew training"))
		StaffData.Role.ACADEMY_HEAD:
			out.append(_pct("Development speed of academy drivers", a.call(&"youth_development"), 0.5, "Youth development"))
			out.append(_pct("Morale of academy drivers", a.call(&"mentoring"), 0.3, "Mentoring"))
		StaffData.Role.CHIEF_SCOUT:
			out.append(_pct("Accuracy of ability estimates", a.call(&"judging_ability"), 0.6, "Judging ability"))
			out.append(_pct("Accuracy of potential estimates", a.call(&"judging_potential"), 0.6, "Judging potential"))
			out.append(_pct("Talents found per month", a.call(&"network"), 0.5, "Network"))
		StaffData.Role.COMMERCIAL_MANAGER:
			out.append(_pct("Sponsor income", a.call(&"negotiation"), 0.3, "Negotiation"))
			out.append(_pct("Sponsor offers", a.call(&"networking"), 0.5, "Networking"))
			out.append(_pct("Reputation growth", a.call(&"brand_building"), 0.3, "Brand building"))
		StaffData.Role.FITNESS_COACH:
			out.append(_pct("Driver fitness", a.call(&"physical_training"), 0.2, "Physical training"))
			out.append(_pct("Time out with injuries", a.call(&"injury_prevention"), -0.5, "Injury prevention", true))
		StaffData.Role.MENTAL_COACH:
			out.append(_pct("Morale stability", a.call(&"motivation"), 0.3, "Motivation"))
			out.append(_pct("Mistakes under pressure", a.call(&"pressure_training"), -0.4, "Pressure training", true))
			out.append(_pct("Tension between people", a.call(&"conflict_resolution"), -0.5, "Conflict resolution", true))
	for t in s.traits:
		var info := TraitCatalog.get_trait(t)
		for effect in info.effects:
			out.append([Loc.t(effect[0]), effect[1], Breakdown.Tone.POSITIVE if info.positive else Breakdown.Tone.NEGATIVE,
				Loc.f("Trait: %s", [Loc.t(info.name)])])
	return out


## Percentage effect around an average person (value 50 = ±0 %).
## lower_is_better: a negative change is good (e.g. fewer failures).
static func _pct(label: String, value: int, factor: float, source: String, lower_is_better: bool = false) -> Array:
	var pct := roundi((value - 50) * factor)
	var good := pct < 0 if lower_is_better else pct > 0
	var tone := Breakdown.Tone.NEUTRAL if pct == 0 else (Breakdown.Tone.POSITIVE if good else Breakdown.Tone.NEGATIVE)
	return [Loc.t(label), "%+d %%" % pct, tone, Loc.t(source)]


static func _tone(value: float) -> Breakdown.Tone:
	if is_zero_approx(value):
		return Breakdown.Tone.NEUTRAL
	return Breakdown.Tone.POSITIVE if value > 0 else Breakdown.Tone.NEGATIVE


## Number of rival teams interested in this person (shown as a status tile).
static func rival_interest(s: StaffData) -> int:
	return clampi((s.overall() - 58) / 6 + (70 - s.job_satisfaction) / 20, 0, 4)
