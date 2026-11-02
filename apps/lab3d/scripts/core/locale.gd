## The app's words, by language (2026-11-02: the words apart from the code and the data, so another
## language is a folder of words, not a change of code). Under content/locale/<lang>/:
##   ui.json                the code's words: key -> text (or a list or a map of texts), `t()`
##   experiments/<id>.json  an experiment's words in the shape of its data file (content/experiments)
##   story.json             the story's words in the shape of content/story.json
## The data files keep everything else (numbers, ids, faces, notes `about`); `overlay()` puts the
## words back into them where they were (tools/split_text.py split them so). A text missing in the
## language is the DEFAULT language's.
##
## There is one language now (ko); `lang` is it.
class_name Locale
extends RefCounted

const ROOT := "res://content/locale"
const DEFAULT := "ko"

static var lang := DEFAULT
static var _ui: Dictionary = {}       # lang -> its ui.json
## Keys asked for that no language has (tests: every key the code uses is in ui.json).
static var missing: Array[String] = []


## The code's text `key` (ui.json). A missing key: the key itself (and it is noted in `missing`).
static func t(key: String) -> String:
	var value: Variant = value_of(key)
	return value if value is String else key


## The code's list or map `key` (ui.json), e.g. the ordinals; [] / {} when missing.
static func value_of(key: String) -> Variant:
	for code in [lang, DEFAULT]:
		var table := _ui_of(code)
		if table.has(key):
			return table[key]
	if key not in missing:
		missing.append(key)
		push_error("Locale: no text %s" % key)
	return null


static func list(key: String) -> Array:
	var value: Variant = value_of(key)
	return value if value is Array else []


static func map(key: String) -> Dictionary:
	var value: Variant = value_of(key)
	return value if value is Dictionary else {}


## The words of content file `rel` (e.g. "experiments/spring.json") in `lang`, else in DEFAULT
## (null when neither has the file).
static func words(rel: String) -> Variant:
	for code in [lang, DEFAULT]:
		var path := ROOT.path_join(code).path_join(rel)
		if FileAccess.file_exists(path):
			return JSON.parse_string(FileAccess.get_file_as_string(path))
	return null


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
		var path := ROOT.path_join(code).path_join("ui.json")
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_ui[code] = parsed if parsed is Dictionary else {}
	return _ui[code]
