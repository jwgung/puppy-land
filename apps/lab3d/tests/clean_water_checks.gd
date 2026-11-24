## 깨끗한 물 만들기 (#160, 2026-11-18; Curie Island's fifth spot, the first played with the body):
## - the data: a valid definition of the curie island; the touch stand-in ball (guide "tilt"), the kettle and
##   the bellows handle (guide "pump") are drag knobs; code-drawn question and filter pictures; its Korean
##   lines are docs/islands/curie-lines.md 5 word for word (야옹이, Puppy's clue, Dugi's explanation, his two
##   warnings with the "(주의) " lead the screen adds, his first-use line, the question, the riddle, every
##   stage's lines) with the doc's faces; the conditions are curie-missions.md 5's; no bold science word;
##   Puppy's result lines short with no science words, digits or symbols; 반말; English has every line;
## - the model against the textbook: sand catches what is bigger than its gaps (the soil) and not the germs,
##   charcoal holds on to the colour and the smell, only boiling clears the germs (at 100 °C, never above);
##   the bellows blows the fire up and it dies down by itself; deterministic;
## - the judging (MissionRound on the real lab): each stage's hit and misses, the wrong filter's line; a tilt of
##   the tablet (an injected accelerometer run), an injected tilt and the touch stand-in dragged down judge
##   the same; still under 4° pours nothing;
## - the bellows through the shell's Manipulator: each drag down past the line is a pump;
## - the places: the kettle and the column (stages 1-2), the fire, the pot, the bellows and the magnifier
##   window (stage 3); a stage just cleared keeps its place until the next reset;
## - no number on the screen; what matters in view (phone, desktop, tablet);
## - the spot (curie's fifth, its own map landmark), the opening (the first-use line on the first visit only)
##   and the piece (in the muddy well until the last stamp, then the well clears and it jumps to the cat).
extends RefCounted

const ID := "clean-water"
const LINES_PATH := "res://../../docs/islands/curie-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/curie-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
const EDGE := 0.03
const BOTTOM_FREE := 0.8
const TOP_FREE := 0.38
const LEFT_BAND := 680.0
const LINE_MAX := 24
const STEP := 1.0 / 60.0
const WARNING := "(주의) "

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var lang := Locale.lang
	if lang != "ko":
		Locale.set_language("ko")
	check_data()
	check_doc_lines()
	check_missions_doc()
	check_result_lines()
	check_banmal()
	check_model()
	check_textbook()
	await check_judging()
	await check_same_by_any_hand()
	await check_bellows()
	await check_places()
	await check_no_numbers()
	await check_in_view()
	await check_pictures()
	check_spot()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> CleanWaterLab:
	var lab := CleanWaterLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


static func _run(lab: CleanWaterLab, seconds: float) -> void:
	for k in int(round(seconds / STEP)):
		lab._feed_tilt()
		lab.model.step(STEP)


## Tilts the lab's tablet (an injected tilt) to `tilt` for `seconds`, stands it up, lets the column drain.
static func _pour(lab: CleanWaterLab, tilt: float, seconds: float) -> void:
	lab.motion.inject_tilt(tilt)
	_run(lab, seconds)
	lab.motion.inject_tilt(0.0)
	_run(lab, 3.0)


## Pumps the bellows `count` times, one every `every` s, then waits `wait` s.
static func _pump(lab: CleanWaterLab, count: int, every: float, wait: float) -> void:
	var m := lab.model as CleanWaterModel
	for i in count:
		m.pump()
		_run(lab, every)
	_run(lab, wait)


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "clean-water: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("curie").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or ExperimentRegistry.island_of(ID) != "curie":
		problems.append("curie's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var objects: Array = definition.manipulation.objects
	var guides: Array = objects.map(func(o: Dictionary) -> String: return "%s:%s" % [o.id, o.get("guide", "drag")])
	if guides != ["tilt:tilt", "kettle:drag", "bellows:pump"] or objects.any(func(o: Dictionary) -> bool: return o.get("hold", false)):
		problems.append("the knobs %s" % str(guides))
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var picks: Array = definition.kid.picks.filter
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["empty", "sand", "charcoal"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the filter buttons %s" % str(picks))
	if PieceArt.of_experiment(ID) != PieceArt.of_island("curie"):
		problems.append("its piece is not the curie island's")
	if not ProjectSettings.get_setting("input_devices/sensors/enable_accelerometer", false):
		problems.append("the accelerometer is off in the project")
	for other: String in ["input_devices/sensors/enable_gravity", "input_devices/sensors/enable_gyroscope", "input_devices/sensors/enable_magnetometer"]:
		if ProjectSettings.get_setting(other, false):
			problems.append("%s is on" % other)
	var manifest := FileAccess.get_file_as_string("res://export_presets.cfg")
	for permission: String in ["RECORD_AUDIO", "CAMERA", "ACCESS_FINE_LOCATION", "HIGH_SAMPLING_RATE_SENSORS"]:
		if manifest.contains("permissions/%s=true" % permission.to_lower()):
			problems.append("permission %s" % permission)
	expect.call(problems.is_empty(), "clean-water: a valid curie island lab; the stand-in ball (tilt), the kettle and the bellows (pump) are drag knobs; code-drawn pictures; the island's piece; only the accelerometer on, no microphone, camera or location permission",
		"; ".join(problems))


func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 5. 깨끗한 물 만들기")
	var end := text.find("\n## ", start + 4)
	var out := {"lines": [], "rows": [], "question": {}}
	if start < 0:
		return out
	var said := RegEx.create_from_string("^\\d+\\. (\\S+)\\((\\S+)\\): (.+)$")
	var asked := RegEx.create_from_string("^\\d+\\. 질문\\((\\S+), (\\S+)\\): (.+)$")
	for raw in text.substr(start, end - start).split("\n"):
		var line := raw.strip_edges()
		var q := asked.search(line)
		if q != null:
			out.question = {"who": q.get_string(1), "face": q.get_string(2), "text": q.get_string(3)}
			continue
		var m := said.search(line)
		if m != null:
			out.lines.append([m.get_string(1), m.get_string(2), m.get_string(3)])
		elif line.begins_with("- 고르기:"):
			out.question.choices = Array(line.trim_prefix("- 고르기:").split("/")).map(func(c: String) -> String: return c.strip_edges().replace("**", ""))
			out.question.answer = Array(line.trim_prefix("- 고르기:").split("/")).find_custom(func(c: String) -> bool: return c.contains("**"))
		elif line.begins_with("- 이유:"):
			out.question.reason = line.trim_prefix("- 이유:").strip_edges()
		elif line.begins_with("- 다리:"):
			out.question.bridge = line.trim_prefix("- 다리:").strip_edges()
		elif line.begins_with("- 지도 수수께끼(퍼피):"):
			out.riddle = line.trim_prefix("- 지도 수수께끼(퍼피):").strip_edges()
		elif line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			out.rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges()))
	return out


func check_doc_lines() -> void:
	var doc := _doc_section()
	var definition := _definition()
	var problems := []
	var faces := {"걱정": "worried", "생각": "thinking", "설명": "explain", "주의": "explain", "기쁨": "happy", "놀람": "surprised"}
	var who := {"야옹이": "yaongi", "빵고양이": "cat", "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition) + MissionRound.first_use_lines(definition)
	if doc.lines.size() != 6 or opening.size() != 6:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 6:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			var text: String = (WARNING if want[1] == "주의" else "") + str(want[2])
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != text:
				problems.append("line %d: %s/%s '%s' (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(want)])
	var predict := MissionRound.predict(definition)
	var q: Dictionary = doc.question
	var labels: Array = predict.choices.map(func(c: Dictionary) -> String: return str(c.label))
	var answer: int = predict.choices.map(func(c: Dictionary) -> String: return str(c.id)).find(str(predict.answer))
	if predict.question != q.get("text") or predict.get("question_face") != faces.get(q.get("face")) or labels != q.get("choices") \
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer"):
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "clean-water: the Korean lines are curie-lines.md 5 word for word (야옹이, Puppy's clue, Dugi's explanation, the germ and boiling-water warnings, the first-use line, the question, the riddle, the three stages) with its faces",
		"; ".join(problems))


func check_missions_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 5. 깨끗한 물 만들기")
	var section := text.substr(start, text.find("\n### ", start + 4) - start)
	var rows := []
	for raw in section.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges())[1])
	var names := {"empty": "빈 통", "sand": "모래", "charcoal": "모래와 숯"}
	var got: Array = _definition().missions.stages.map(func(s: Dictionary) -> String: return str(names.get(s.conditions.filter, "?")))
	var bold := []
	var walk := func(walk: Callable, value: Variant) -> void:
		if value is String and str(value).contains("**"):
			bold.append(value)
		elif value is Dictionary:
			for key in value:
				walk.call(walk, value[key])
		elif value is Array:
			for item in value:
				walk.call(walk, item)
	walk.call(walk, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/%s.json" % ID)))
	var labels: Array = _definition().kid.picks.filter.map(func(p: Dictionary) -> String: return str(p.label))
	expect.call(start >= 0 and section.contains("**조건 단추**: 거름 통 — 빈 통 / 모래 / 모래와 숯") and got == rows and labels == ["빈 통", "모래", "모래·숯"] and bold.is_empty(),
		"clean-water: the stages' conditions are curie-missions.md 5's (모래, 모래와 숯, 모래와 숯; the buttons 빈 통 / 모래 / 모래·숯); no bold science word",
		"%s / %s, labels %s, bold %s" % [str(rows), str(got), str(labels), str(bold)])


func check_result_lines() -> void:
	var problems := []
	var science := Story.science_words()
	var symbols := RegEx.create_from_string("[0-9%=+×/<>]")
	var definition := _definition()
	for stage: Dictionary in definition.missions.stages:
		for key: String in ["win", "miss", "miss_conditions"]:
			var line := str(stage.get(key, ""))
			if line == "" or line.length() > LINE_MAX or symbols.search(line) != null or science.any(func(w: String) -> bool: return line.contains(w)):
				problems.append("%s '%s'" % [key, line])
	for line: String in [Story.clue(definition), Story.map_clue(definition)]:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/%s.json" % ID))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/%s.json" % ID)
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 2 \
			or str(en.kid.get("first_use", {}).get("text", "")) == "" \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.filter.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "clean-water: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


func check_banmal() -> void:
	var polite := RegEx.create_from_string("(요|세요|니다)([.!?…,*\\s]|$)")
	var found := []
	var walk := func(walk: Callable, where: String, value: Variant) -> void:
		if value is String:
			if polite.search(value) != null:
				found.append("%s: %s" % [where, value])
		elif value is Dictionary:
			for key in value:
				walk.call(walk, where + "." + str(key), value[key])
		elif value is Array:
			for i in value.size():
				walk.call(walk, "%s[%d]" % [where, i], value[i])
	walk.call(walk, ID, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/%s.json" % ID)))
	for key in ["water.none", "water.muddy", "water.yellow", "water.clear", "germs.none_yet", "germs.there", "germs.dying", "germs.gone", "fire.off", "fire.small", "fire.big"]:
		walk.call(walk, key, Locale.t("clean_water." + key))
	expect.call(found.is_empty(), "clean-water: every Korean line is 반말 (no 요 / 세요 / 니다)", "; ".join(found))


# --- the model ------------------------------------------------------------------------------------

func check_model() -> void:
	var problems := []
	var runs := []
	for k in 2:
		var m := CleanWaterModel.new()
		var seen := []
		m.set_tilt(0.7)
		for i in 400:
			m.step(STEP)
			if i == 200:
				m.set_tilt(0.0)
			if i % 20 == 0:
				seen.append([m.status(), m.input("jar"), m.input("soil")])
		runs.append(seen)
	if runs[0] != runs[1]:
		problems.append("two runs differ")
	var m := CleanWaterModel.new()
	if m.status() != "ready" or m.animating():
		problems.append("before a pour: %s" % m.status())
	m.set_filter(CleanWaterModel.CHARCOAL)
	m.set_site(CleanWaterModel.BOIL)
	m.pump()
	m.step(1.0)
	m.reset()
	if m.status() != "ready" or m.filter() != CleanWaterModel.CHARCOAL or m.site() != CleanWaterModel.BOIL or m.input("fire") != 0.0 or m.input("pot_germs") != 1.0:
		problems.append("reset: %s" % m.status())
	var flat := CleanWaterModel.new()
	flat.set_tilt(-0.8)
	flat.step(1.0)
	if flat.touched() or flat.input("kettle") != 1.0:
		problems.append("tilted the other way it poured")
	expect.call(problems.is_empty(), "clean-water model: deterministic, reset keeps the filter and the place, a tilt the other way pours nothing", "; ".join(problems))


## Textbook: sand (a bed holds back about 5 µm and up) catches silt (about 20 µm) but not bacteria (about
## 1 µm); charcoal holds on to colour and smell; only boiling clears the germs (100 °C, never above); the
## bellows' fire dies down by itself, so the water boils only while it is kept up.
func check_textbook() -> void:
	var problems := []
	if not (CleanWaterModel.SOIL_UM > CleanWaterModel.SAND_CATCH_UM and CleanWaterModel.GERM_UM < CleanWaterModel.SAND_CATCH_UM and CleanWaterModel.GERM_UM <= 2.0):
		problems.append("the sizes")
	var result := {}
	for kind: float in [CleanWaterModel.EMPTY, CleanWaterModel.SAND, CleanWaterModel.CHARCOAL]:
		var m := CleanWaterModel.new()
		m.set_filter(kind)
		m.set_tilt(1.0)
		var t := 0.0
		while m.input("kettle") > 0.0 and t < 20.0:
			m.step(STEP)
			t += STEP
		m.set_tilt(0.0)
		for i in 300:
			m.step(STEP)
		result[kind] = [m.status(), snappedf(m.input("soil"), 0.01), snappedf(m.input("colour"), 0.01), snappedf(m.input("smell"), 0.01), snappedf(m.input("germs"), 0.01)]
	var want := {CleanWaterModel.EMPTY: ["muddy", 1.0, 1.0, 1.0, 1.0], CleanWaterModel.SAND: ["filtered", 0.0, 1.0, 1.0, 1.0], CleanWaterModel.CHARCOAL: ["clear", 0.0, 0.05, 0.05, 1.0]}
	for kind: float in want:
		if result[kind] != want[kind]:
			problems.append("filter %d: %s" % [kind, str(result[kind])])
	var pot := CleanWaterModel.new()
	pot.set_site(CleanWaterModel.BOIL)
	var hottest := 0.0
	var t := 0.0
	var pumps := 0
	while pot.status() != "boiled" and t < 30.0:
		if fmod(t, 0.5) < STEP:
			pot.pump()
			pumps += 1
		pot.step(STEP)
		t += STEP
		hottest = maxf(hottest, pot.input("water"))
	if pot.status() != "boiled" or hottest > CleanWaterModel.BOIL_C or t < 3.0 or t > 12.0:
		problems.append("pumped twice a second: %s in %.1f s (%d pumps), hottest %.1f" % [pot.status(), t, pumps, hottest])
	var weak := CleanWaterModel.new()
	weak.set_site(CleanWaterModel.BOIL)
	for i in 3:
		weak.pump()
		for k in 30:
			weak.step(STEP)
	for k in 1200:
		weak.step(STEP)
	if weak.status() != "unboiled" or weak.input("pot_germs") < 1.0 or weak.fire_on():
		problems.append("three pumps then nothing: %s, germs %.2f" % [weak.status(), weak.input("pot_germs")])
	expect.call(problems.is_empty(), "clean-water textbook: sand catches the soil (20 um > 5 um) but not the germs (1 um), charcoal holds the colour and smell, only boiling clears the germs (never above 100); pumped twice a second it boils clean in %.1f s, three pumps and the fire dies before" % t,
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, filter, steps, hit, missed]; a step: "pour T S" (tilt T for S s), "pump N" (twice a second, then 1 s), "wait S".
	var cases := [
		[0, "sand", ["pour 1 4"], true, false], [0, "sand", ["pour 0.6 6"], true, false], [0, "sand", ["pour 1 0.6"], false, true],
		[0, "sand", ["pour 0.05 1"], false, true], [0, "empty", ["pour 1 4"], false, true], [0, "charcoal", ["pour 1 4"], false, true],
		[1, "charcoal", ["pour 1 4"], true, false], [1, "sand", ["pour 1 4"], false, true], [1, "charcoal", ["pour 1 0.5"], false, true],
		[2, "charcoal", ["pump 16"], true, false], [2, "charcoal", ["pump 3", "wait 30"], false, true], [2, "charcoal", ["pump 2"], false, false],
		[2, "sand", ["pump 16"], false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.set_control("filter", case[1])
		for step: String in case[2]:
			var parts := step.split(" ")
			match parts[0]:
				"pour":
					_pour(lab, float(parts[1]), float(parts[2]))
				"pump":
					_pump(lab, int(parts[1]), 0.5, 1.0)
				"wait":
					_run(lab, float(parts[1]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		# (A hit's attempt is done: the round tells no miss after it, MissionRound.judged_run.)
		var missed := MissionRound.missed(definition, stage, status, lab.observations()) and lab.settled() and stamps != stage + 1
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s %s (%s, settled %s): stamps %d missed %s" % [stage + 1, case[1], str(case[2]), status, lab.settled(), stamps, missed])
		lab.reset_run()
	var wants := [["empty", "모래를 골라 봐!"], ["sand", "모래와 숯을 골라 봐!"], ["sand", "모래와 숯을 골라 봐!"]]
	for i in 3:
		lab.set_control("filter", wants[i][0])
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong filter says '%s'" % [i + 1, line[0]])
	var told := [MissionRound.result_line(definition, 0, false, false)[0], MissionRound.result_line(definition, 1, false, false)[0], MissionRound.result_line(definition, 2, false, false)[0]]
	if told != ["거름 통에 부어 봐!", "숯 통으로 걸러 봐!", "보글보글 끓을 때까지!"]:
		problems.append("the miss lines %s" % str(told))
	# Not judged while the tablet is still tilted (the child is still pouring).
	lab.set_game_stage(0, 0, false)
	lab.set_control("filter", "sand")
	lab.motion.inject_tilt(1.0)
	_run(lab, 5.0)
	if lab.settled() or not lab.body_input_active():
		problems.append("judged while still tilted (%s)" % lab.status())
	lab.motion.inject_tilt(0.0)
	_run(lab, 3.0)
	if not lab.settled() or lab.status() != "filtered":
		problems.append("stood up: %s settled %s" % [lab.status(), lab.settled()])
	lab.motion.clear_tilt()
	expect.call(problems.is_empty(), "clean-water judging: sand filters (stage 1), sand and charcoal clear (stage 2), boiling clears the germs (stage 3); too little poured, the wrong filter and the fire let die say the doc's lines; nothing judged while the tablet is still tilted",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


## The same pour three ways: the tablet tilted 20° (an injected accelerometer run through the filter), an
## injected tilt of 1, and the touch stand-in ball dragged to the bottom of its slot (and the kettle dragged
## down): the same state and judgement. Under 4° nothing pours.
func check_same_by_any_hand() -> void:
	var results := {}
	var problems := []
	for how: String in ["sensor", "test", "ball", "kettle", "still"]:
		var lab := _lab()
		tree.root.add_child(lab)
		await tree.process_frame
		lab.set_game_stage(0, 0, false)
		lab.set_control("filter", "sand")
		var reading := func(degrees: float) -> Vector3: return Vector3(-sin(deg_to_rad(degrees)), -cos(deg_to_rad(degrees)), 0.0) * MotionFilter.G
		match how:
			"sensor", "still":
				for i in 30:
					lab.motion.inject_accel(reading.call(0.0))
				lab.motion.rest()
				var degrees := 20.0 if how == "sensor" else 3.0
				for i in 60:
					lab.motion.inject_accel(reading.call(degrees))
				for i in int(4.0 / STEP):
					lab.motion.inject_accel(reading.call(degrees))
					lab._feed_tilt()
					lab.model.step(STEP)
				for i in 30:
					lab.motion.inject_accel(reading.call(0.0))
				_run(lab, 3.0)
			"test":
				lab.motion.inject_tilt(1.0)
				_run(lab, 1.0 + 4.0)
				lab.motion.inject_tilt(0.0)
				_run(lab, 3.0)
			"ball", "kettle":
				var id := CleanWaterLab.TILT_ID if how == "ball" else CleanWaterLab.KETTLE_ID
				var surface := lab.manipulation_surface(id)
				lab.manipulation_started(id)
				var xf := surface.pose(Vector2(surface.region_max.x, 0.0), 0.3)
				lab.knobs[id].global_transform = xf
				lab._process(0.0)
				_run(lab, 5.0)
				lab.manipulation_placed(id, xf)
				_run(lab, 3.0)
		var m := lab.model as CleanWaterModel
		results[how] = [lab.status(), snappedf(m.input("jar"), 0.05), lab.motion.source]
		if how == "ball" and (lab.ball_drop != 0.0 or lab.props.ball.position.y < CleanWaterProps.SLOT_TOP - 0.01):
			problems.append("the ball did not go back up")
		lab.queue_free()
		await tree.process_frame
	for how: String in ["sensor", "test", "ball", "kettle"]:
		if results[how][0] != "filtered":
			problems.append("%s: %s" % [how, str(results[how])])
	if results.still[0] != "ready" or results.sensor[2] != "test" or results.ball[2] != "touch":
		problems.append("still %s, sources %s / %s" % [str(results.still), results.sensor[2], results.ball[2]])
	expect.call(problems.is_empty(), "clean-water by any hand: the tablet tilted 20 deg, an injected tilt, the stand-in ball and the kettle dragged down all filter the same (%s); 3 deg pours nothing; let go, the ball goes back up" % str(results),
		"; ".join(problems))


# --- the bellows ----------------------------------------------------------------------------------

func check_bellows() -> void:
	var host := Control.new()
	host.size = VIEW_SIZE
	tree.root.add_child(host)
	var view: View3D = load(VIEW_3D).new()
	view.size = VIEW_SIZE
	host.add_child(view)
	var lab := _lab()
	view.set_world(lab)
	view.rig.configure(_definition().camera)
	var m := Manipulator.new()
	view.viewport.add_child(m)
	m.setup(view, lab)
	for i in 3:
		await tree.physics_frame
	await tree.process_frame
	var problems := []
	var guide := m.guide()
	if guide.get("kind", "") != "tilt" or guide.get("id", "") != CleanWaterLab.TILT_ID:
		problems.append("stage 1 hand guide %s" % str(guide))
	lab.set_game_stage(2, 2, false)
	await tree.process_frame
	guide = m.guide()
	if guide.get("kind", "") != "pump" or guide.get("id", "") != CleanWaterLab.BELLOWS_ID:
		problems.append("stage 3 hand guide %s" % str(guide))
	var per_unit := Vector2(view.viewport.size) / view.size
	var up := view.rig.unproject_position(lab.knobs[CleanWaterLab.BELLOWS_ID].global_position) / per_unit
	var down := view.rig.unproject_position(lab.knobs[CleanWaterLab.BELLOWS_ID].global_position + CleanWaterProps.handle_point(1.0) - CleanWaterProps.handle_point(0.0)) / per_unit
	m.handle_pointer("press", up)
	if m.mode != "drag":
		problems.append("press on the handle: mode '%s'" % m.mode)
	for k in 3:
		for f in 6:
			m.handle_pointer("move", up.lerp(down, (f + 1) / 6.0))
			await tree.process_frame
		for f in 6:
			m.handle_pointer("move", down.lerp(up, (f + 1) / 6.0))
			await tree.process_frame
	m.handle_pointer("release", up)
	var model := lab.model as CleanWaterModel
	if model.input("pumps") != 3.0 or not model.fire_on() or lab.handle_drop != 0.0:
		problems.append("three strokes: %d pumps, fire %.2f, handle %.2f" % [model.input("pumps"), model.input("fire"), lab.handle_drop])
	expect.call(problems.is_empty(), "clean-water bellows: the hand guide shows the tablet tilt on stages 1-2 and a pump on stage 3; three drags down and up the handle are three pumps and the fire is going; let go, the handle goes up",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the places -----------------------------------------------------------------------------------

func check_places() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var props: CleanWaterProps = lab.props
	for stage: int in [0, 1, 2, -1]:
		lab.set_game_stage(stage, maxi(stage, 0) if stage >= 0 else 3, false)
		var boil := stage == 2 or stage == -1
		var seen := [props.slot.visible, props.hearth.visible, lab.manipulation_body(CleanWaterLab.TILT_ID) != null, lab.manipulation_body(CleanWaterLab.BELLOWS_ID) != null]
		if seen != [not boil, boil, not boil, boil]:
			problems.append("stage %d: slot, hearth, ball, bellows %s" % [stage, str(seen)])
	lab.set_game_stage(1, 1, false)
	lab.set_control("filter", "charcoal")
	_pour(lab, 1.0, 4.0)
	lab.set_game_stage(2, 2, true)
	if lab.model.input("site") != CleanWaterModel.FILTER or lab.status() != "clear":
		problems.append("the cleared stage's place changed at once (%s)" % lab.status())
	lab.reset_run()
	if lab.model.input("site") != CleanWaterModel.BOIL or not props.hearth.visible:
		problems.append("the next stage's place did not come with the reset")
	# The column's layers follow the button; the stream shows while pouring, as thick as the tilt.
	lab.set_game_stage(0, 0, false)
	var kinds := []
	for f: String in ["empty", "sand", "charcoal"]:
		lab.set_control("filter", f)
		lab._show()
		kinds.append(props.shown_filter)
	if kinds != [CleanWaterModel.EMPTY, CleanWaterModel.SAND, CleanWaterModel.CHARCOAL]:
		problems.append("layers %s" % str(kinds))
	lab.motion.inject_tilt(1.0)
	lab._feed_tilt()
	for i in 40:
		props.advance(STEP)
	var thick := props.shown_stream
	var tipped := props.tip
	lab.motion.inject_tilt(0.3)
	lab._feed_tilt()
	for i in 40:
		props.advance(STEP)
	if not props.stream.visible or thick < 0.95 or props.shown_stream > 0.35 or tipped < CleanWaterProps.TIP_MAX - 1.0:
		problems.append("stream %.2f then %.2f, tip %.1f" % [thick, props.shown_stream, tipped])
	lab.motion.inject_tilt(-1.0)
	lab._feed_tilt()
	for i in 40:
		props.advance(STEP)
	if props.stream.visible or props.tip > 0.0 or props.tip < -CleanWaterProps.ROCK_BACK - 0.1:
		problems.append("tilted back: tip %.1f, stream %s" % [props.tip, props.stream.visible])
	lab.motion.clear_tilt()
	expect.call(problems.is_empty(), "clean-water places: the kettle, the slot and the column on stages 1-2, the fire, the pot, the bellows and the window on stage 3; a cleared stage keeps its place until the reset; the layers follow the button; the stream is as thick as the tilt; tilted back the kettle only rocks",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


func check_no_numbers() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var digits := RegEx.create_from_string("[0-9]")
	for o: Dictionary in definition.observations:
		if str(o.get("unit", "")) != "" or o.has("digits"):
			problems.append("observation %s has a unit" % o.id)
	if ExperimentRegistry.shown_cards(definition, 0) != ["water"] or ExperimentRegistry.shown_cards(definition, 2) != ["germs"]:
		problems.append("cards %s / %s" % [str(ExperimentRegistry.shown_cards(definition, 0)), str(ExperimentRegistry.shown_cards(definition, 2))])
	var seen := {}
	var collect := func() -> void:
		for key: String in lab.observations():
			var value: Variant = lab.observations()[key]
			seen[value] = true
			if not value is String or str(value) == "" or digits.search(str(value)) != null:
				problems.append("%s: %s" % [key, str(value)])
	for f: String in ["empty", "sand", "charcoal"]:
		lab.set_game_stage(0, 0, false)
		lab.set_control("filter", f)
		collect.call()
		_pour(lab, 1.0, 4.0)
		collect.call()
	lab.set_game_stage(2, 2, false)
	collect.call()
	for k in 12:
		(lab.model as CleanWaterModel).pump()
		_run(lab, 0.5)
		collect.call()
	if seen.size() < 9:
		problems.append("only %d different words" % seen.size())
	expect.call(problems.is_empty(), "clean-water: no number on the screen (the observations are words, no units; the card is the water, the germs on stage 3)", "; ".join(problems))
	lab.queue_free()
	await tree.process_frame


func check_in_view() -> void:
	var problems := []
	for size: Vector2 in [PHONE, DESKTOP, TABLET]:
		var host := Control.new()
		host.size = size
		tree.root.add_child(host)
		var view: View3D = load(VIEW_3D).new()
		view.size = size
		host.add_child(view)
		var lab := _lab()
		view.set_world(lab)
		view.rig.configure(_definition().camera)
		for i in 2:
			await tree.process_frame
		var per_unit := Vector2(view.viewport.size) / view.size
		var at := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit / size
		var inside := func(p: Vector2, what: String) -> void:
			var band := p.x * size.x < LEFT_BAND and p.y < TOP_FREE
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < EDGE or p.y > BOTTOM_FREE or band:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		inside.call(at.call(Vector3(-CleanWaterProps.COLUMN_R, CleanWaterProps.COLUMN_TOP, 0.0)), "the column's top")
		inside.call(at.call(Vector3(0.0, CleanWaterProps.COLUMN_AT.y, 0.0)), "the column's foot")
		inside.call(at.call(Vector3(0.0, CleanWaterProps.JAR_H, CleanWaterProps.JAR_R)), "the jar")
		inside.call(at.call(CleanWaterProps.spout_tip(CleanWaterProps.TIP_MAX)), "the tipped spout")
		inside.call(at.call(CleanWaterProps.PIVOT + Vector3(0.0, CleanWaterProps.KETTLE_H * 0.7, 0.0)), "the kettle's top")
		inside.call(at.call(CleanWaterProps.ball_point(0.0) + Vector3.UP * CleanWaterProps.BALL_R), "the ball at the top")
		inside.call(at.call(CleanWaterProps.ball_point(1.0)), "the ball at the bottom")
		inside.call(at.call(CleanWaterProps.WELL_AT + Vector3(CleanWaterProps.WELL_R, CleanWaterProps.WELL_H, 0.0)), "the well")
		inside.call(at.call(CleanWaterProps.POT_AT + Vector3(0.0, CleanWaterProps.POT_H, 0.0)), "the pot")
		inside.call(at.call(CleanWaterProps.handle_point(0.0)), "the bellows handle")
		for corner: Vector3 in [Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, -1.0, 0.0)]:
			inside.call(at.call(CleanWaterProps.LENS_AT + corner * CleanWaterProps.LENS_R), "the magnifier window")
		var b := lab.props.cat.bounds()
		inside.call(at.call(b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5)), "the cat's head")
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "clean-water in view: the column, the jar, the kettle (tipped too), the stand-in's slot, the well, the pot, the bellows, the window and the bread cat between the top band and the bottom (phone, desktop and tablet)",
		"; ".join(problems.slice(0, 8)))


func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["drink_ok", "drink_boil"]
	var pick_kinds := ["filter_empty", "filter_sand", "filter_charcoal"]
	for kind: String in predict_kinds + pick_kinds:
		var draw := func() -> void:
			if kind in predict_kinds:
				PredictPictures.draw(canvas, kind)
			else:
				PickPictures.draw(canvas, kind)
			drawn.append(kind)
		canvas.draw.connect(draw)
		canvas.queue_redraw()
		await tree.process_frame
		canvas.draw.disconnect(draw)
	canvas.queue_free()
	var listed := predict_kinds.all(func(k: String) -> bool: return k in PredictPictures.KINDS) and pick_kinds.all(func(k: String) -> bool: return k in PickPictures.KINDS)
	expect.call(listed and drawn == predict_kinds + pick_kinds, "clean-water pictures: the question's two pictures and the three filter buttons are listed and draw", str(drawn))


func check_spot() -> void:
	var curie := Island.by_id("curie")
	var problems := []
	if str(curie.order[4]) != ID or ExperimentRegistry.find(ID).is_empty():
		problems.append("clean-water is not curie's fifth spot as an experiment")
	if curie.playable():
		problems.append("the island opened with the labs so far")
	var own := ArtKit.builder()
	MapLandmarks.add(own, ID, Transform3D())
	var other := ArtKit.builder()
	MapLandmarks.add(other, "no-such-spot", Transform3D())
	if own.vertex_count() <= other.vertex_count():
		problems.append("the map shows the unknown spot's ball on a post")
	expect.call(problems.is_empty(), "clean-water: the curie island's fifth spot is an experiment with its own map landmark (a well, a filter column, a kettle); the island stays in the making", "; ".join(problems))


## First visit: 야옹이, Puppy's clue, Dugi's explanation and his two warnings, his first-use line, then the
## question; later visits: Dugi's three lines without the first-use line.
func check_opening() -> void:
	var definition := _definition()
	var was := Story.enabled
	Story.enabled = true
	var store := MissionRound.MemoryProgress.new()
	var round := MissionRound.new(definition, store)
	round.start()
	round.open(true)
	var told := []
	while round.phase() == MissionRound.Phase.CLUE and told.size() < 10:
		var line := round.clue_to_open()
		told.append([line.speaker, line.face, str(line.text).begins_with(WARNING)])
		round.clue_opened()
		round.clue_read()
	var first_ok := told == [["yaongi", "worried", false], ["puppy", "thinking", false], ["dugi", "explain", false], ["dugi", "explain", true], ["dugi", "explain", true], ["dugi", "explain", false]] \
		and round.phase() == MissionRound.Phase.ASKING
	var again := MissionRound.new(definition, store)
	again.start()
	again.open(true)
	var later := []
	while again.phase() == MissionRound.Phase.CLUE and later.size() < 10:
		later.append(str(again.clue_to_open().text))
		again.clue_opened()
		again.clue_read()
	Story.enabled = was
	var first_use: String = MissionRound.first_use_lines(definition)[0].text
	expect.call(first_ok and later.size() == 3 and not first_use in later,
		"clean-water opening: first visit 야옹이, Puppy's clue, Dugi's explanation, his germ and boiling-water warnings and his first-use line (\"%s\"), then the question; later visits his three lines without it" % first_use,
		"%s / %s" % [str(told), str(later)])


func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: CleanWaterGame = lab.game
	var problems := []
	if game.piece_state != "held" or game.piece.global_position.distance_to(CleanWaterGame.PIECE_AT) > 0.05:
		problems.append("not in the well at the start")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 40:
		await tree.process_frame
	if game.piece_state != "held" or game.piece.global_position.distance_to(CleanWaterGame.PIECE_AT) > 0.05:
		problems.append("after two stamps: %s" % game.piece_state)
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 600:
		await tree.process_frame
		frames += 1
	if game.piece_state != "out" or game.piece.global_position.distance_to(lab.props.cat.global_position) > 2.5:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(game.piece.global_position)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as CleanWaterGame).take_piece() != null:
		problems.append("a finished spot still has a piece")
	expect.call(problems.is_empty(), "clean-water piece: at the bottom of the muddy well until the last stamp, then the well clears and it rises and jumps down in front of the bread cat; a finished spot has no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
