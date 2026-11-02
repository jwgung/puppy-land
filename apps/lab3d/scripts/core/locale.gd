## The app's words, by language (2026-11-02: the words apart from the code and the data, so another
## language is a folder of words, not a change of code). Under content/locale/<lang>/:
##   ui.json                the code's words: key -> text (or a list or a map of texts), `t()`
##   experiments/<id>.json  an experiment's words in the shape of its data file (content/experiments)
##   story.json             the story's words in the shape of content/story.json
## The data files keep everything else (numbers, ids, faces, notes `about`); `overlay()` puts the
## words back into them where they were (tools/split_text.py split them so). A text missing in the
## language is the DEFAULT language's (ui.json key by key; a content file's words laid over DEFAULT's).
##
## English is the base language (2026-11-02 user: "기본을 영어로 하자. 그리고 한글이 거기에 추가되는
## 식"); Korean is laid over it. The app's language (`start()`): the child's choice in the settings
## (saved in `path`), else the device's language when it is one of LANGUAGES, else English.
class_name Locale
extends RefCounted

const ROOT := "res://content/locale"
const DEFAULT := "en"
const LANGUAGES := ["en", "ko"]   # the settings' order
const PATH := "user://language.cfg"
## Tests keep their own file (and never pick the device's language: run_tests sets `lang`).
static var path := PATH
static var app_may_choose := true

static var lang := DEFAULT
static var _ui: Dictionary = {}       # lang -> its ui.json
## Keys asked for that no language has (tests: every key the code uses is in ui.json).
static var missing: Array[String] = []


## The app's language at launch (App): the saved choice, else the device's (OS locale), else English.
static func start() -> void:
	if not app_may_choose:
		return
	lang = pick(saved(), OS.get_locale_language())


## The language for a saved choice and a device language: the choice when it is one of LANGUAGES,
## else the device's when it is, else DEFAULT.
static func pick(choice: String, device: String) -> String:
	if choice in LANGUAGES:
		return choice
	return device if device in LANGUAGES else DEFAULT


## The child's saved choice ("" when none).
static func saved() -> String:
	return FileAccess.get_file_as_string(path).strip_edges() if FileAccess.file_exists(path) else ""


## The child picks `code` in the settings: saved, and the words read again (the definitions, the
## story). The screens built from now on are in it.
static func choose(code: String) -> void:
	if code not in LANGUAGES:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(code)
	set_language(code)


## `lang` = `code` and the content read in it again (ExperimentRegistry, Story).
static func set_language(code: String) -> void:
	lang = code
	ExperimentRegistry.forget_loaded()
	Story.forget_loaded()


## Text `key` in language `code` itself (the settings name each language in its own words).
static func t_in(code: String, key: String) -> String:
	var value: Variant = _ui_of(code).get(key)
	return value if value is String else t(key)


## The code's text `key` (ui.json). A missing key: the key itself (and it is noted in `missing`).
static func t(key: String) -> String:
	var value: Variant = value_of(key)
	return value if value is String else key


## The code's text, list or map `key` (ui.json) in `lang`, else in DEFAULT (null when neither has it).
static func value_of(key: String) -> Variant:
	for code in [lang, DEFAULT]:
		var table := _ui_of(code)
		if table.has(key):
			return table[key]
	if key not in missing:
		missing.append(key)
		push_error("Locale: no text %s" % key)
	return null


## The code's list `key` (ui.json), e.g. the mission ordinals; [] when missing.
static func list(key: String) -> Array:
	var value: Variant = value_of(key)
	return value if value is Array else []


## The code's map `key` (ui.json), e.g. the camera views' names; {} when missing.
static func map(key: String) -> Dictionary:
	var value: Variant = value_of(key)
	return value if value is Dictionary else {}


## The words of content file `rel` (e.g. "experiments/spring.json"): DEFAULT's, with `lang`'s laid
## over them (null when neither has the file). A map keyed by texts (TEXT_KEYED: a lab's kid.states,
## its status texts -> the card's words) is the language's own, whole: its keys are that language's.
const TEXT_KEYED := [["kid", "states"]]


static func words(rel: String) -> Variant:
	var out: Variant = _read(ROOT.path_join(DEFAULT).path_join(rel))
	if lang != DEFAULT:
		var own: Variant = _read(ROOT.path_join(lang).path_join(rel))
		out = overlay(out, own)
		for path in TEXT_KEYED:
			_replace_at(out, own, path)
	return out


## out[path] = own[path] where both have the path's parent (own's map replaces, not merges).
static func _replace_at(out: Variant, own: Variant, path: Array) -> void:
	for key in path.slice(0, -1):
		if not (out is Dictionary and own is Dictionary and out.get(key) is Dictionary and own.get(key) is Dictionary):
			return
		out = out[key]
		own = own[key]
	if out is Dictionary and own is Dictionary and own.has(path[-1]):
		out[path[-1]] = own[path[-1]]


static func _read(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null


## `data` with `words` put back where they were: objects key by key, lists item by item, a text in
## place of what is missing. Neither is changed.
static func overlay(data: Variant, text: Variant) -> Variant:
	if text == null:
		return data
	if data == null:
		return text
	if data is Dictionary and text is Dictionary:
		var out: Dictionary = data.duplicate()
		for key in text:
			out[key] = overlay(data.get(key), text[key])
		return out
	if data is Array and text is Array:
		var out := []
		for i in maxi(data.size(), text.size()):
			out.append(overlay(data[i] if i < data.size() else null, text[i] if i < text.size() else null))
		return out
	return text


static func _ui_of(code: String) -> Dictionary:
	if not _ui.has(code):
		var parsed: Variant = _read(ROOT.path_join(code).path_join("ui.json"))
		_ui[code] = parsed if parsed is Dictionary else {}
	return _ui[code]
