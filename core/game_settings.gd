## Player settings stored in user://settings.cfg (works on Windows and macOS).
class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"
const LOCALES := ["en", "de"]


static func load_and_apply() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	var fallback := "de" if OS.get_locale_language() == "de" else "en"
	TranslationServer.set_locale(cfg.get_value("general", "locale", fallback))


static func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("general", "locale", locale)
	cfg.save(PATH)


static func locale() -> String:
	return TranslationServer.get_locale().left(2)
