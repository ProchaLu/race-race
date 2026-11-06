## Junior profile (R7, docs/youth_model.md 9–13): who the junior is as far as
## the scouts know, his season and junior career, the scout's report. For
## others' juniors: the academy offer (years, promise, signing bonus) with the
## junior's interest and the rival academy. For our own: the academy plan
## (training focus, mentor, young driver test, seat), contract and mood, and
## the way to F1 (promotion, loan, sale).
extends UIScreen

## Shown once after a click failed (the screen reloads after the click).
static var _error := ""
## The offer being prepared (kept while the screen reloads).
static var _years := 1
static var _promise := 0
static var _bonus := 0

const PROMISES := [&"", &"f3_seat", &"f2_seat"]

var driver: DriverData
var _team: TeamData


func setup(args: Dictionary) -> void:
	driver = GameState.drivers[args.driver_id]
	_team = GameState.player_team()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UIStyle.GAP)
	scroll.add_child(page)
	if _error != "":
		page.add_child(YouthUI.error(tr(_error)))
		_error = ""
	page.add_child(_row([_identity_card(), _season_card()], [1.3, 1.0]))
	var own := driver.academy_team_id == _team.id
	if own:
		page.add_child(_row([_plan_card(), _contract_card(), _future_card()], [1.0, 1.0, 1.0]))
		page.add_child(_row([_history_card(), _report_card()], [1.3, 1.0]))
	else:
		page.add_child(_row([_offer_card(), _report_card()], [1.3, 1.0]))
		page.add_child(_history_card())


func screen_title() -> String:
	return "Junior profile"


func nav_section() -> StringName:
	return &"academy" if driver.academy_team_id == _team.id else &"scouting"


func _row(children: Array, ratios: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.GAP)
	for i in children.size():
		var child: Control = children[i]
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		child.size_flags_stretch_ratio = ratios[i] if i < ratios.size() else 1.0
		row.add_child(child)
	return row


func _reload() -> void:
	shell.refresh_current()


# --- Who he is -----------------------------------------------------------------

func _identity_card() -> UICard:
	var d := driver
	var card := UICard.new(d.full_name(), "%d · %s · %s" % [d.age(Calendar.year), d.nationality,
		tr(Scouting.REGION_NAMES[Scouting.region_of(d)])])
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 22)
	top.add_child(YouthUI.name_box(YouthUI.where(d), tr("Academy: %s") % YouthUI.academy_name(d)
		if d.academy_team_id != &"" else tr("No academy")))
	top.add_child(YouthUI.ability_stars(d))
	top.add_child(YouthUI.potential_stars(d))
	top.add_child(YouthUI.figure(tr(Knowledge.label(d)), tr("%d %% known") % Knowledge.level(d)))
	top.add_child(YouthUI.figure(tr(Scouting.recommendation(d)), tr("advice")))
	top.add_child(YouthUI.watch_button(d, _reload))
	card.add_padded(top, 8, 8)
	card.add_row(FactRow.new(tr("Super licence"), tr("yes") if d.has_superlicence else "%d / %d" % [Youth.licence_points(d),
		Youth.LICENCE_NEEDED], tr("points in the last three seasons"), true, UIStyle.GOOD if d.has_superlicence else UIStyle.TEXT))
	if d.academy_team_id == _team.id or Knowledge.level(d) >= 60:
		card.add_row(FactRow.new(tr("Mood"), "%d" % d.morale, _mood_reasons(d), true, YouthUI.mood_color(d.morale)))
	if Scouting.capacity(_team) > 0 and d.academy_team_id != _team.id and Knowledge.level(d) < Scouting.done_level(Scouting.skill(_team)):
		var one: Array[StringName] = [d.id]
		var reason := tr(Scouting.blocked_reason(_team))
		var b := YouthUI.button(tr("Send a scout (%s · %d weeks)") % [UIStyle.money(Scouting.FEE_PER_TARGET),
			maxi(1, Scouting.weeks_needed(_team, one))], func():
				_error = Scouting.start(_team, &"driver", d.full_name(), one)
				_reload(), reason)
		card.add_padded(b, 6, 8)
	return card


func _mood_reasons(d: DriverData) -> String:
	var parts := []
	for key in d.morale_factors:
		parts.append("%s %+d" % [tr(key), d.morale_factors[key]])
	return ", ".join(parts)


func _season_card() -> UICard:
	var d := driver
	var key := Youth.series_key(d)
	var card := UICard.new(tr("Season %d") % Calendar.year, tr(Youth.series_name(key)) if key != &"" else tr("no races"))
	if key == &"":
		card.add_padded(YouthUI.small(tr("He does not race this season.")), 8, 8)
		return card
	var last := Youth.last_result(d)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(YouthUI.figure("P%d" % Youth.position(d) if Youth.position(d) > 0 else "–", tr("championship")))
	row.add_child(YouthUI.figure("%d" % Youth.season_points(d), tr("points")))
	row.add_child(YouthUI.figure("%d" % Youth.season_wins(d), tr("wins")))
	row.add_child(YouthUI.figure("%d" % Youth.season_starts(d), tr("races")))
	row.add_child(YouthUI.figure("–" if last < 0 else (tr("DNF") if last == 0 else "P%d" % last), tr("last race")))
	card.add_padded(row, 8, 8)
	card.add_row(FactRow.new(tr("Race practice this season"), "×%.2f" % Youth.practice(d),
		tr("drives the winter development"), true))
	return card


func _history_card() -> UICard:
	var card := UICard.new(tr("Junior career"), tr("one line per season"))
	if driver.junior_history.is_empty():
		card.add_padded(YouthUI.small(tr("No finished junior season yet.")), 8, 8)
		return card
	for i in range(driver.junior_history.size() - 1, -1, -1):
		var e: Dictionary = driver.junior_history[i]
		var title := "%d · %s" % [e.year, tr(Youth.series_name(e.series))]
		var row := HoverRow.new()
		row.add_child(YouthUI.box_with(YouthUI.name_box(title, e.team), [
			YouthUI.figure("P%d" % e.position, tr("final place")),
			YouthUI.figure("%d" % e.points, tr("points")),
			YouthUI.figure("%d" % e.wins, tr("wins")),
		]))
		card.add_row(row)
	return card


func _report_card() -> UICard:
	var scout := Knowledge.chief_scout()
	var card := UICard.new(tr("Scouting report"), scout.full_name() if scout else tr("no chief scout"))
	for line in Scouting.report_lines(driver):
		var args: Array = line[1].map(func(a): return tr(str(a)) if a is String else a)
		var label := YouthUI.small(tr(line[0]) % args if not args.is_empty() else tr(line[0]))
		card.add_padded(label, 3, 3)
	return card


# --- Others' juniors: the offer -----------------------------------------------------

func _terms() -> Dictionary:
	return {"years": Academy.YEARS[_years], "promise": PROMISES[_promise], "bonus": Academy.BONUSES[_bonus]}


func _offer_card() -> UICard:
	var d := driver
	var card := UICard.new(tr("Academy offer"), tr("convince him to join"))
	var reason := Academy.can_sign(_team, d)
	if reason != "":
		card.add_padded(YouthUI.small(tr(reason)), 8, 8)
		return card
	card.add_section(tr("Contract length"))
	var years := Segmented.new(Academy.YEARS.map(func(y): return tr("%d seasons") % y if y > 1 else tr("1 season")), _years)
	years.changed.connect(func(i):
		_years = i
		_reload())
	card.add_padded(years, 4, 4)
	card.add_section(tr("Promise"))
	var promise := Segmented.new([tr("None"), tr("Junior seat next season"), tr("F2 seat next season")], _promise)
	promise.changed.connect(func(i):
		_promise = i
		_reload())
	card.add_padded(promise, 4, 4)
	card.add_section(tr("Signing bonus"))
	var bonus := Segmented.new(Academy.BONUSES.map(func(b): return UIStyle.money(b) if b > 0 else tr("None")), _bonus)
	bonus.changed.connect(func(i):
		_bonus = i
		_reload())
	card.add_padded(bonus, 4, 4)
	var answer := Academy.interest(_team, d, _terms())
	var known := Knowledge.level(d) >= 40
	card.add_row(FactRow.new(tr("His interest"), tr(_interest_text(answer.score)) if known else tr("unknown"),
		tr("needs %d, he is at %d") % [Academy.MIN_INTEREST, answer.score] if known else tr("scout him to read him better"),
		true, UIStyle.GOOD if answer.accepted else (UIStyle.BAD if answer.score < Academy.MIN_INTEREST - 10 else UIStyle.ACCENT)))
	if answer.rival:
		card.add_row(FactRow.new(tr("Rival academy"), answer.rival.name, tr("also wants him"), true, UIStyle.BAD))
	var cost: int = Academy.SIGNING_FEE + Academy.BONUSES[_bonus]
	var old: TeamData = GameState.teams.get(d.academy_team_id)
	if old:
		cost += d.academy_release_clause
		card.add_row(FactRow.new(tr("Release clause"), UIStyle.money(d.academy_release_clause), tr("paid to %s") % old.name, true))
	card.add_row(FactRow.new(tr("Cost now"), UIStyle.money(cost), tr("then %s per month") % UIStyle.money(Academy.FEE_PER_MONTH), true))
	if PROMISES[_promise] != &"":
		card.add_padded(YouthUI.small(tr("A promise must be kept by the first junior race of next season, or he will be very disappointed.")), 4, 4)
	var button := YouthUI.accent(tr("Buy out and sign") if old else tr("Make the offer"))
	button.pressed.connect(func():
		var terms := _terms()
		terms["buyout"] = old != null
		_error = Academy.sign_junior(_team, d, terms)
		_reload())
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_END
	line.add_child(button)
	card.add_padded(line, 8, 8)
	return card


static func _interest_text(score: int) -> String:
	if score >= Academy.MIN_INTEREST + 10:
		return "Very keen"
	if score >= Academy.MIN_INTEREST:
		return "Interested"
	if score >= Academy.MIN_INTEREST - 10:
		return "Hesitant"
	return "Not interested"


# --- Our juniors: plan, contract, the way to F1 ----------------------------------------

func _plan_card() -> UICard:
	var d := driver
	var card := UICard.new(tr("Academy plan"), tr("training, mentor, seat"))
	card.add_section(tr("Training focus"))
	var focus := OptionButton.new()
	focus.add_item(tr("Balanced"))
	focus.set_item_metadata(0, &"")
	for key in Academy.FOCUS:
		focus.add_item(tr(Academy.FOCUS[key][0]))
		focus.set_item_metadata(focus.item_count - 1, key)
		if key == d.academy_focus:
			focus.select(focus.item_count - 1)
	focus.item_selected.connect(func(i):
		Academy.set_focus(d, focus.get_item_metadata(i))
		_reload())
	card.add_padded(focus, 4, 2)
	card.add_padded(YouthUI.small(tr("The focus attributes grow much more in the winter, the others less.")), 2, 4)
	card.add_section(tr("Mentor"))
	var mentor := OptionButton.new()
	mentor.add_item(tr("No mentor"))
	mentor.set_item_metadata(0, &"")
	for m in Academy.mentors(_team):
		var label := m.full_name() + (" · " + tr("Mentor") if m.traits.has(&"mentor") else "")
		mentor.add_item(label)
		mentor.set_item_metadata(mentor.item_count - 1, m.id)
		if m.id == d.mentor_id:
			mentor.select(mentor.item_count - 1)
	mentor.item_selected.connect(func(i):
		Academy.set_mentor(d, mentor.get_item_metadata(i))
		_reload())
	card.add_padded(mentor, 4, 2)
	card.add_padded(YouthUI.small(tr("Growth this winter: ×%.2f (head, building, mentor)") % Academy.growth_factor(_team, d)), 2, 4)
	card.add_section(tr("Young driver test"))
	var test := CheckBox.new()
	test.text = tr("Drives the F1 car at the end of the season (%s)") % UIStyle.money(Academy.TEST_COST)
	test.button_pressed = d.young_driver_test
	test.toggled.connect(func(on):
		_error = Academy.set_test(_team, d, on)
		_reload())
	card.add_padded(test, 4, 4)
	card.add_section(tr("Junior seat"))
	var seat_line := HBoxContainer.new()
	seat_line.add_theme_constant_override("separation", 8)
	var choice := YouthUI.seat_choice(_team, d)
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seat_line.add_child(choice)
	var place := YouthUI.accent(tr("Move") if Academy.is_placed(d) else tr("Place"))
	place.disabled = choice.disabled
	place.pressed.connect(func():
		_error = Academy.place(_team, d, GameState.youth_teams[choice.get_item_metadata(choice.selected)])
		_reload())
	seat_line.add_child(place)
	card.add_padded(seat_line, 4, 4)
	if Academy.is_placed(d):
		card.add_padded(YouthUI.button(tr("Bring back"), func():
			Academy.bring_back(d)
			_reload()), 2, 8)
	return card


func _contract_card() -> UICard:
	var d := driver
	var card := UICard.new(tr("Academy contract"), "")
	card.add_row(FactRow.new(tr("Runs until"), tr("end of %d") % d.academy_until if d.academy_until > 0 else "–", "", true,
		UIStyle.BAD if d.academy_until <= Calendar.year else UIStyle.TEXT))
	card.add_row(FactRow.new(tr("Release clause"), UIStyle.money(d.academy_release_clause), tr("other academies can pay it"), true))
	card.add_row(FactRow.new(tr("Market value"), UIStyle.money(Academy.fee_for(d)), "", true))
	if d.academy_promise != &"":
		card.add_row(FactRow.new(tr("Promise"), tr("F2 seat") if d.academy_promise == &"f2_seat" else tr("Junior seat"),
			tr("by the first junior race of %d") % d.academy_promise_year, true, UIStyle.ACCENT))
	card.add_padded(YouthUI.button(tr("Extend by two seasons (%s)") % UIStyle.money(Academy.EXTEND_FEE_PER_YEAR * 2), func():
		_error = Academy.extend(_team, d)
		_reload()), 8, 4)
	card.add_padded(YouthUI.button(tr("Release from the academy"), func():
		Academy.release(d)
		shell.navigate(&"academy")), 4, 8)
	for offer in GameState.junior_offers.filter(func(o): return o.driver_id == d.id):
		var buyer: TeamData = GameState.teams.get(offer.team_id)
		card.add_section(tr("Offer from %s") % (buyer.name if buyer else "–"))
		card.add_row(FactRow.new(tr("Fee"), UIStyle.money(offer.fee), tr("open until %s") % Calendar.format_date(offer.until_day), true))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		line.add_child(YouthUI.button(tr("Accept"), func():
			_error = Academy.accept_offer(offer)
			shell.navigate(&"academy")))
		line.add_child(YouthUI.button(tr("Decline"), func():
			Academy.decline_offer(offer)
			_reload()))
		card.add_padded(line, 4, 8)
	return card


func _future_card() -> UICard:
	var d := driver
	var card := UICard.new(tr("The way to F1"), tr("needs the super licence"))
	var licence_reason := "" if d.has_superlicence else tr("He needs the super licence first.")
	var reserve_reason := licence_reason if licence_reason != "" else (tr("The reserve place is taken.")
		if _team.reserve_driver_ids.size() >= ContractLogic.RESERVE_SEATS else "")
	var race_reason := licence_reason if licence_reason != "" else (tr("Both race seats are taken.")
		if _team.driver_ids.size() >= ContractLogic.RACE_SEATS else "")
	card.add_padded(YouthUI.button(tr("Make him our reserve driver"), func():
		_error = Academy.promote(_team, d, false)
		if _error == "":
			shell.navigate(&"drivers")
		else:
			_reload(), reserve_reason), 6, 2)
	card.add_padded(YouthUI.button(tr("Give him a race seat"), func():
		_error = Academy.promote(_team, d, true)
		if _error == "":
			shell.navigate(&"drivers")
		else:
			_reload(), race_reason), 2, 6)
	card.add_section(tr("Loan to another F1 team"))
	if d.loan_from != &"":
		card.add_padded(YouthUI.small(tr("On loan until the end of the season.")), 4, 4)
	else:
		var options := Academy.loan_options(_team, d)
		if options.is_empty():
			card.add_padded(YouthUI.small(tr("No team wants him yet: he needs the super licence and the pace of their weakest driver.")), 4, 4)
		else:
			var loan := OptionButton.new()
			for t in options:
				loan.add_item(t.name)
				loan.set_item_metadata(loan.item_count - 1, t.id)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 8)
			loan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(loan)
			line.add_child(YouthUI.button(tr("Loan (+%s)") % UIStyle.money(Academy.LOAN_FEE), func():
				_error = Academy.loan(_team, d, GameState.teams[loan.get_item_metadata(loan.selected)])
				_reload()))
			card.add_padded(line, 4, 4)
	card.add_section(tr("Sell to another academy"))
	var buyers := Academy.sell_offers(_team, d)
	if buyers.is_empty():
		card.add_padded(YouthUI.small(tr("Nobody would pay for him right now.")), 4, 8)
	for b in buyers:
		var row := HoverRow.new()
		var box := YouthUI.box_with(YouthUI.name_box(b.team.name, tr("academy")), [YouthUI.figure(UIStyle.money(b.fee), tr("fee"))])
		box.add_child(YouthUI.button(tr("Sell"), func():
			_error = Academy.sell(_team, d, b.team, b.fee)
			if _error == "":
				shell.navigate(&"academy")
			else:
				_reload()))
		row.add_child(box)
		card.add_row(row)
	return card
