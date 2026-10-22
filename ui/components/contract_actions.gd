## Contract buttons for a person: extend / release for your own people,
## start talks for free agents and people with a release clause, or the
## status of a pending signature.
## wide = true: buttons fill the width (used in the market preview).
class_name ContractActions
extends VBoxContainer

const PRIMARY_HEIGHT := 46

var _person: PersonData
var _shell: AppShell
var _wide: bool


func _init(person: PersonData, shell: AppShell, wide: bool = false) -> void:
	_person = person
	_shell = shell
	_wide = wide
	add_theme_constant_override("separation", 8)

	var pending := GameState.pending_signing_of(person.id)
	if not pending.is_empty():
		_note(tr("Signature expected on %s") % Calendar.format_date(pending.sign_day), UIStyle.ACCENT)
		if pending.kind == Negotiation.Kind.SIGN:
			_note(tr("Until then, rival teams can still make an offer (risk %d %%).") % roundi(Season.hijack_chance(pending.terms) * 100), UIStyle.MUTED)
		return
	var refuses_until: int = GameState.talk_cooldown.get(person.id, -1)
	if refuses_until > Calendar.day:
		_note(tr("Refuses to talk until %s") % Calendar.format_date(refuses_until), UIStyle.BAD)
		return

	var contract := GameState.contract_of(person.id)
	if person.team_id == GameState.player_team_id and person.team_id != &"":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_button("Extend contract", "handshake", _open_talks))
		row.add_child(_button("Release", "arrow-left-right", _confirm_release))
		add_child(row)
	elif person.team_id == &"":
		add_child(_primary(tr("Start talks")))
		_position_note()
	elif contract and contract.release_clause > 0:
		add_child(_primary(tr("Start talks (clause %s)") % UIStyle.money(contract.release_clause)))
		_position_note()
	else:
		_note(tr("Under contract until %d – no release clause") % contract.end_year if contract else "", UIStyle.MUTED)


## Warns early that someone in the team will have to make room.
func _position_note() -> void:
	var role := ContractData.DriverRole.EQUAL if _person is DriverData else -1
	if ContractLogic.position_full(GameState.player_team(), _person, role):
		_note(tr("Position full: someone has to make room when signing."), UIStyle.WARN)


func _button(text: String, icon_name: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.icon = UIStyle.icon(icon_name)
	b.pressed.connect(action)
	if _wide:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


## The main call to action: large, accent coloured.
func _primary(text: String) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.icon = UIStyle.icon("handshake")
	b.theme_type_variation = &"AccentButton"
	b.custom_minimum_size.y = PRIMARY_HEIGHT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _wide else Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(_open_talks)
	return b


func _note(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"StrongLabel"
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 220
	add_child(l)


func _open_talks() -> void:
	_shell.navigate(&"negotiation", {"person_id": _person.id})


func _confirm_release() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = tr("Release")
	dialog.dialog_text = tr("Release %s? The severance costs %s and the person becomes a free agent.") % [
		_person.full_name(), UIStyle.money(ContractLogic.severance(_person))]
	dialog.ok_button_text = tr("Release")
	dialog.cancel_button_text = tr("Cancel")
	dialog.confirmed.connect(func():
		var cost := ContractLogic.release(_person)
		var msg := InboxMessage.new()
		msg.sender = "Sporting director"
		msg.subject = "Contract ended: %s"
		msg.subject_args = [_person.full_name()]
		msg.icon = "arrow-left-right"
		msg.add_paragraph("%s has left the team. Severance paid: %s.", [_person.full_name(), UIStyle.money(cost)])
		GameState.add_message(msg)
		dialog.queue_free()
		_shell.refresh_current())
	dialog.canceled.connect(dialog.queue_free)
	_shell.add_child(dialog)
	dialog.popup_centered()
