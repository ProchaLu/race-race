## Translation helpers for code without a Node (static functions, RefCounted).
## Nodes can use tr() directly. English source text is the translation key;
## see i18n/strings.csv.
class_name Loc
extends RefCounted


static func t(text: String) -> String:
	return TranslationServer.translate(text)


## Translates a format string, then fills in the values.
static func f(text: String, args: Variant) -> String:
	return TranslationServer.translate(text) % args
