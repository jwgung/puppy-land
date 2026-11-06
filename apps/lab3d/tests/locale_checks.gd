## The words by language (2026-11-02, Locale): the code's words are keys into
## content/locale/<lang>/ui.json, the content files' words are in the same shape under
## content/locale/<lang>/ and put back when they load. Every key the code names is in every
## language; the code and the data files hold no words of their own (Hangul) any more; the overlay
## puts words back where they were. English is the base (DEFAULT) and Korean is laid over it
## (2026-11-02): every language has every text of the base, its lab states' words match its own
## status texts, and Puppy's lines in each language avoid its science words.
extends RefCounted

var tree: SceneTree
var expect: Callable
const HANGUL := "[\\x{AC00}-\\x{D7A3}]"
## Data files with their words apart (their `about` notes may be in Korean: they are not shown).
const DATA_DIRS := ["res://content/story", "res://content/experiments", "res://content/islands"]


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	# The checks switch languages (the content is read again): the other checks' loaded definitions
	# and story stay the very objects they were (some checks hold or adjust them).
	var kept := [Locale.lang, ExperimentRegistry._cache, ExperimentRegistry._hidden, ExperimentRegistry._loaded, Story._content]
	check_switch_keeps_state()
	check_keys()
	check_no_words_in_code()
	check_no_words_in_data()
	check_overlay()
	check_languages_complete()
	check_state_words()
	check_puppy_words_each_language()
	check_language_pick()
	Locale.lang = kept[0]
	ExperimentRegistry._cache = kept[1]
	ExperimentRegistry._hidden = kept[2]
	ExperimentRegistry._loaded = kept[3]
	Story._content = kept[4]


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
	var call_in := RegEx.create_from_string("Locale\\.t_in\\([^,]+, \"([^\"]+)\"\\)")
	var named := {}   # key -> kind
	for path in _code_files():
		for m in call.search_all(FileAccess.get_file_as_string(path)):
			named[m.get_string(2)] = m.get_string(1)
		for m in call_in.search_all(FileAccess.get_file_as_string(path)):
			named[m.get_string(1)] = "t"
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
			elif table[key] is String and _slots(table[key]) != _slots(str(Locale.value_of(key)) if Locale.value_of(key) is String else ""):
				problems.append("%s: %s has other %% slots than %s" % [code, key, Locale.DEFAULT])
	expect.call(problems.is_empty() and Locale.DEFAULT in langs and named.size() > 100,
		"locale: every key the code names is in every language's ui.json (and none unused)",
		"; ".join(problems.slice(0, 8)) if not problems.is_empty() else "%d keys, languages %s" % [named.size(), str(langs)])


## The format slots of a text (%s, %d, %.1f ...), in order: a translation keeps them.
static func _slots(text: String) -> Array:
	var out := []
	for m in RegEx.create_from_string("%[-+ 0-9.]*[sdfxXc%]").search_all(text):
		out.append(m.get_string())
	return out


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
	var files: Array = []
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
	expect.call(found.is_empty() and files.size() > 12, "locale: no words in the data files (content/experiments, content/islands, content/story)",
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


## The text paths of a words file (kid.states named by status texts: its own check below).
static func _paths(value: Variant, path: String, out: Dictionary) -> void:
	if path.ends_with("/kid/states"):
		out[path] = true
		return
	if value is Dictionary:
		for key in value:
			_paths(value[key], path + "/" + str(key), out)
	elif value is Array:
		if value.all(func(v: Variant) -> bool: return v is String):
			out[path + "[%d]" % value.size()] = true
			return
		for i in value.size():
			_paths(value[i], path + "[%d]" % i, out)
	else:
		out[path] = true


static func _words_files(code: String) -> Array:
	var root := Locale.ROOT.path_join(code)
	var out := []
	for dir in ["experiments", "story"]:
		for name in DirAccess.get_files_at(root.path_join(dir)):
			if name.ends_with(".json"):
				out.append(dir.path_join(name))
	out.sort()
	return out


## Every language has the base's words files with the same texts in the same places (the experiment
## data files each have the base's words).
func check_languages_complete() -> void:
	var problems := []
	var base := _words_files(Locale.DEFAULT)
	for name in DirAccess.get_files_at("res://content/experiments"):
		if name.ends_with(".json") and name != "index.json" and "experiments".path_join(name) not in base:
			problems.append("%s has no %s words" % [name, Locale.DEFAULT])
	for code in Locale.LANGUAGES:
		if _words_files(code) != base:
			problems.append("%s files %s" % [code, str(_words_files(code))])
			continue
		for rel in base:
			var want := {}
			var got := {}
			_paths(JSON.parse_string(FileAccess.get_file_as_string(Locale.ROOT.path_join(Locale.DEFAULT).path_join(rel))), "", want)
			_paths(JSON.parse_string(FileAccess.get_file_as_string(Locale.ROOT.path_join(code).path_join(rel))), "", got)
			for key in want:
				if not got.has(key):
					problems.append("%s %s: no %s" % [code, rel, key])
			for key in got:
				if not want.has(key):
					problems.append("%s %s: %s is not in %s" % [code, rel, key, Locale.DEFAULT])
	expect.call(problems.is_empty() and Locale.DEFAULT == "en" and Locale.LANGUAGES == ["en", "ko"],
		"locale: English is the base and every language has all its texts in the same places",
		"; ".join(problems.slice(0, 8)) if not problems.is_empty() else "%d files x %s" % [base.size(), str(Locale.LANGUAGES)])


## A lab's kid.states (the key cards' words for its status texts) names status texts of the same
## language: every key is one of the lab's status texts in that language's ui.json.
func check_state_words() -> void:
	var problems := []
	var checked := 0
	for code in Locale.LANGUAGES:
		var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Locale.ROOT.path_join(code).path_join("ui.json")))
		for rel in _words_files(code):
			if not rel.begins_with("experiments/"):
				continue
			var id: String = rel.get_file().get_basename()
			var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Locale.ROOT.path_join(code).path_join(rel)))
			var states: Dictionary = words.get("kid", {}).get("states", {})
			var texts := []
			for key in ui:
				if str(key).begins_with(id + ".") and ui[key] is String:
					texts.append(ui[key])
			for text in states:
				checked += 1
				if text not in texts:
					problems.append("%s %s: %s is not a status text" % [code, id, text])
	# Loaded (the base laid under the language): a lab's kid.states is the language's own, whole.
	var was := Locale.lang
	for code in Locale.LANGUAGES:
		Locale.set_language(code)
		var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Locale.ROOT.path_join(code).path_join("ui.json")))
		for definition in ExperimentRegistry.load_all():
			for text in definition.get("kid", {}).get("states", {}):
				if text not in ui.values():
					problems.append("%s %s loaded: %s is not a status text" % [code, definition.id, text])
	Locale.set_language(was)
	expect.call(problems.is_empty() and checked >= 20, "locale: each language's kid.states names that language's own status texts (in its file and loaded)",
		"; ".join(problems.slice(0, 6)) if not problems.is_empty() else "%d state words" % checked)


## Puppy never explains science in any language: his lines (story, clues, riddles, the wrong-spot
## line, the result lines) avoid that language's science words (Story.science_words).
func check_puppy_words_each_language() -> void:
	var problems := []
	var was := Locale.lang
	for code in Locale.LANGUAGES:
		Locale.set_language(code)
		var words := Story.science_words()
		var lines := Story.puppy_lines()
		for definition in ExperimentRegistry.load_all():
			for stage in MissionRound.missions(definition).get("stages", []):
				lines.append(str(stage.get("win", "")))
				lines.append(str(stage.get("miss", "")))
				lines.append(str(stage.get("miss_conditions", "")))
		for line in lines:
			for word in words:
				if line.to_lower().contains(str(word).to_lower()):
					problems.append("%s: \"%s\" in %s" % [code, word, line])
		if words.is_empty() or lines.size() < 60:
			problems.append("%s: %d words, %d lines" % [code, words.size(), lines.size()])
	Locale.set_language(was)
	expect.call(problems.is_empty(), "locale: Puppy's lines avoid the science words in every language",
		"; ".join(problems.slice(0, 6)))


## Switching the language reads the words again and keeps the rest of the app's state: the story's
## switches (2026-11-02: a "reload" named like Script.reload recompiled Story and switched the story
## off), the progress file, the island.
func check_switch_keeps_state() -> void:
	var was := [Story.enabled, Story.app_may_enable, ProgressStore.path, Locale.lang]
	Story.enabled = true
	Story.app_may_enable = true
	var island := Island.current()
	Locale.set_language("en")
	Locale.set_language("ko")
	var kept: bool = Story.enabled and Story.app_may_enable and ProgressStore.path == was[2] and Island.current() == island \
		and ExperimentRegistry.find("spring").get("title", "") == "용수철은 에너지를 어떻게 돌려줄까?"
	Story.enabled = was[0]
	Story.app_may_enable = was[1]
	Locale.set_language(was[3])
	expect.call(kept, "locale: switching the language reads the words again and keeps the story's switches, the progress file and the island", "")


## The app's language: the saved choice, else the device's when it is one of LANGUAGES, else English;
## the settings' pick saves it and reads the words again.
func check_language_pick() -> void:
	var picks := [Locale.pick("", "ko"), Locale.pick("", "en"), Locale.pick("", "fr"), Locale.pick("ko", "en"), Locale.pick("en", "ko"), Locale.pick("xx", "fr")]
	var was := Locale.lang
	DirAccess.remove_absolute(Locale.path)
	Locale.choose("en")
	var english: bool = Locale.saved() == "en" and Locale.lang == "en" and ExperimentRegistry.find("spring").get("title", "") == "How does a spring give energy back?" \
		and Locale.t("title.start") == "Start" and Story.wrong_line().begins_with("Hmm")
	Locale.choose("ko")
	var korean: bool = Locale.saved() == "ko" and ExperimentRegistry.find("spring").get("title", "") == "용수철은 에너지를 어떻게 돌려줄까?" and Locale.t("title.start") == "시작하기"
	DirAccess.remove_absolute(Locale.path)
	Locale.set_language(was)
	var ok: bool = picks == ["ko", "en", "en", "ko", "en", "en"] and english and korean and Locale.path != Locale.PATH
	expect.call(ok, "locale: the language is the saved choice, else the device's (ko), else English; picking it reads the words again",
		"picks %s, english %s, korean %s" % [str(picks), english, korean])
