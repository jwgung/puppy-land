## The words by language (2026-11-02, Locale): the code's words are keys into
## content/locale/<lang>/ui.json, the content files' words are in the same shape under
## content/locale/<lang>/ and put back when they load. Every key the code names is in every
## language; the code and the data files hold no words of their own (Hangul) any more; the overlay
## puts words back where they were.
extends RefCounted

var tree: SceneTree
var expect: Callable
const HANGUL := "[\\x{AC00}-\\x{D7A3}]"
## Data files with their words apart (their `about` notes may be in Korean: they are not shown).
const DATA_DIRS := ["res://content/experiments", "res://content/islands"]
const DATA_FILES := ["res://content/story.json"]


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	check_keys()
	check_no_words_in_code()
	check_no_words_in_data()
	check_overlay()


func _gd_files(dir: String, out: Array) -> void:
	for name in DirAccess.get_files_at(dir):
		if name.ends_with(".gd"):
			out.append(dir.path_join(name))
	for sub in DirAccess.get_directories_at(dir):
		_gd_files(dir.path_join(sub), out)


func _code_files() -> Array:
	var out := []
	for dir in ["res://scripts", "res://experiments", "res://tests"]:
		_gd_files(dir, out)
	return out


## The code part of a line (before a # that is not in a string).
static func _code(line: String) -> String:
	var in_str := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if c == "\\" and in_str:
			i += 2
			continue
		if c == "\"":
			in_str = not in_str
		elif c == "#" and not in_str:
			return line.substr(0, i)
		i += 1
	return line


## Every Locale.t / map / list key named in the code (and the keys named through data: the
## speakers' names, the free-fall balls' names) is in every language's ui.json, of its kind.
func check_keys() -> void:
	var call := RegEx.create_from_string("Locale\\.(t|map|list)\\(\"([^\"]+)\"\\)")
	var named := {}   # key -> kind
	for path in _code_files():
		for m in call.search_all(FileAccess.get_file_as_string(path)):
			named[m.get_string(2)] = m.get_string(1)
	for who in Story.SPEAKERS:
		named[str(Story.SPEAKERS[who][0])] = "t"
	var balls: Dictionary = (load("res://experiments/free_fall/free_fall.gd") as GDScript).get_script_constant_map().BALLS
	for id in balls:
		named["free-fall.ball." + id] = "t"
	var problems := []
	var langs := DirAccess.get_directories_at(Locale.ROOT)
	for code in langs:
		var table: Variant = JSON.parse_string(FileAccess.get_file_as_string(Locale.ROOT.path_join(code).path_join("ui.json")))
		if not table is Dictionary:
			problems.append("%s: no ui.json" % code)
			continue
		for key in named:
			var value: Variant = table.get(key)
			var ok: bool = {"t": value is String, "map": value is Dictionary, "list": value is Array}[named[key]]
			if not ok:
				problems.append("%s: %s (%s)" % [code, key, named[key]])
		for key in table:
			if not named.has(key):
				problems.append("%s: %s is not used" % [code, key])
	expect.call(problems.is_empty() and Locale.DEFAULT in langs and named.size() > 100,
		"locale: every key the code names is in every language's ui.json (and none unused)",
		"; ".join(problems.slice(0, 8)) if not problems.is_empty() else "%d keys, languages %s" % [named.size(), str(langs)])


## No code line (outside comments) has a word of its own in a string: the words are the language's.
func check_no_words_in_code() -> void:
	var hangul := RegEx.create_from_string("\"[^\"]*" + HANGUL + "[^\"]*\"")
	var found := []
	for path in _code_files():
		if path.begins_with("res://tests/"):
			continue   # (the tests check the Korean words themselves)
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			if hangul.search(_code(lines[i])) != null:
				found.append("%s:%d" % [path, i + 1])
	expect.call(found.is_empty(), "locale: no words in the code (scripts, experiments): every text is a ui.json key",
		", ".join(found.slice(0, 8)))


## The data files hold no words (their `about` notes aside): the words are in content/locale.
func check_no_words_in_data() -> void:
	var hangul := RegEx.create_from_string(HANGUL)
	var files: Array = DATA_FILES.duplicate()
	for dir in DATA_DIRS:
		for name in DirAccess.get_files_at(dir):
			if name.ends_with(".json"):
				files.append(dir.path_join(name))
	var found := []
	var walk := func(walk: Callable, value: Variant, path: String) -> void:
		if value is Dictionary:
			for key in value:
				if key == "about" or str(key).ends_with("_about"):
					continue
				if hangul.search(str(key)) != null:
					found.append("%s key %s" % [path, key])
				walk.call(walk, value[key], path + "/" + str(key))
		elif value is Array:
			for item in value:
				walk.call(walk, item, path + "[]")
		elif value is String and hangul.search(value) != null:
			found.append(path)
	for file in files:
		walk.call(walk, JSON.parse_string(FileAccess.get_file_as_string(file)), file)
	expect.call(found.is_empty() and files.size() > 12, "locale: no words in the data files (content/experiments, content/islands, content/story.json)",
		", ".join(found.slice(0, 8)) if not found.is_empty() else "%d files" % files.size())


## The overlay puts words back where they were: objects key by key, lists item by item, a missing
## side taken from the other; neither input changes.
func check_overlay() -> void:
	var data := {"id": "x", "steps": null, "controls": [{"id": "a", "min": 1.0}, {"id": "b"}], "law": {"equation": "F = ma"}}
	var words := {"title": "제목", "steps": ["하나", "둘"], "controls": [{"label": "가"}, {}, {"label": "다"}], "law": {"title": "법칙"}}
	var want := {"id": "x", "steps": ["하나", "둘"], "controls": [{"id": "a", "min": 1.0, "label": "가"}, {"id": "b"}, {"label": "다"}],
		"law": {"equation": "F = ma", "title": "법칙"}, "title": "제목"}
	var data_copy := data.duplicate(true)
	var got: Variant = Locale.overlay(data, words)
	var none: Variant = Locale.overlay(data, null)
	var ok: bool = got == want and none == data and data == data_copy and Locale.t("common.settings") == "설정"
	expect.call(ok, "locale: the overlay puts the words back where they were (and changes neither side)", str(got))
