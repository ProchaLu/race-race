## A message in the player's inbox. Texts are stored as translation keys
## plus values, so they show in the current language even after switching.
class_name InboxMessage
extends Resource

enum Priority { INFO, IMPORTANT }

@export var year: int
@export var day: int
## Translation key of the sender, e.g. "Owner".
@export var sender: String
@export var subject: String
@export var subject_args: Array = []
## Paragraphs: each entry is [translation key, args array].
@export var body: Array = []
@export var priority: Priority = Priority.INFO
@export var icon: String = "inbox"
@export var read: bool = false
## Optional button that opens a screen.
@export var link_screen: StringName
@export var link_args: Dictionary = {}
@export var link_label: String


func subject_text() -> String:
	return Loc.f(subject, subject_args) if not subject_args.is_empty() else Loc.t(subject)


func body_text() -> String:
	var parts := PackedStringArray()
	for paragraph in body:
		var args: Array = paragraph[1]
		parts.append(Loc.f(paragraph[0], args) if not args.is_empty() else Loc.t(paragraph[0]))
	return "\n\n".join(parts)


## Adds a paragraph and returns self for chaining.
func add_paragraph(key: String, args: Array = []) -> InboxMessage:
	body.append([key, args])
	return self
