## 빵 반죽 부풀리기 (#159, 2026-11-17; Curie Island's fourth spot) and the condition lock it brings to
## the screen (Experiment.conditions_locked, FastClock.locks_conditions):
## - the data: a valid definition, a curie island lab, the yeast button (효모 넣음 / 안 넣음, code-drawn
##   pictures), the bowl dragged towards the oven (guide_to min); the question's pictures are code drawn;
##   the Korean lines are docs/islands/curie-lines.md section 4 word for word (야옹이 worried, the bread
##   cat, Puppy's clue, Dugi with the one bold word 효모 and the yeast card, the question, the riddle,
##   the three stages with their wrong-button lines, stage 2's miss "밤이 …" not "하루"); the mission
##   doc's section 4 has the same missions and conditions (decision 6); Puppy's lines are short with no
##   science words, digits or symbols; every Korean line is 반말; English has every line;
## - the model: deterministic; the textbook values: twice the volume in an hour by the oven (27 °C),
##   the fridge (4 °C) twelve times slower so the same hours give only a little, three times (the shelf)
##   in log2 3 hours, no rising without yeast through a whole day and night; the pace (an hour two play
##   seconds with yeast, a day eight without);
## - the lock: the conditions locked while the time flows and while the bowl is held in the middle of
##   it, free once the result is in and after 다시; the screen dims the buttons, ignores a tap on a
##   locked condition and frees them with the lab;
## - the judging (MissionRound on the real lab): doubled / the same / the shelf hit; the fridge, the
##   wrong button and the waiting day say Puppy's lines; nothing while a finger holds the bowl;
## - the hand (the shell's Manipulator): the bowl dragged to the oven runs the time (the fire, the
##   sign's lamp); picked up again where it stands the time stops, put down it goes on; let go short it
##   goes back; at the fridge the door opens and it stands inside, and is picked up there again; the
##   hand guide drags it towards the oven;
## - the night: a day without yeast goes dark at night and gives one moon stamp;
## - the goals: twice (the dashed line) on stages 1-2, the shelf on 3; a stage just cleared keeps its
##   goal until the next reset; a finished round shows the dough at the shelf ("선반까지 닿았어", not the
##   flat start) until 다시 or a condition;
## - no number on the screen; what matters in view on the phone, the desktop and the tablet;
## - the spot (curie's fourth, its own map landmark), the opening and the piece (on the shelf, a lamp a
##   stamp, off the shelf at the last stamp to the bread cat).
extends RefCounted

const ID := "dough"
const LINES_PATH := "res://../../docs/islands/curie-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/curie-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const UI_THEME := "res://scripts/app/ui_theme.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
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
	check_lock()
	await check_judging()
	await check_drag()
	await check_night()
	await check_goals()
	await check_no_numbers()
	await check_screen_lock()
	await check_in_view()
	await check_rings_on_table()
	await check_rings_clear_of_cast()
	check_spot()
	await check_pictures()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> DoughLab:
	var lab := DoughLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## Steps `model` until its clock stops (at most `limit` play seconds); returns the seconds stepped.
static func _run_out(model: DoughModel, limit := 60.0) -> float:
	var t := 0.0
	while model.clock.running and t < limit:
		model.step(STEP)
		t += STEP
	return t


static func _model(yeast: bool, goal: float) -> DoughModel:
	var m := DoughModel.new()
	m.set_yeast(yeast)
	m.set_goal(goal)
	m.reset()
	return m


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "dough: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("curie").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or ExperimentRegistry.island_of(ID) != "curie":
		problems.append("curie's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var picks: Array = definition.kid.picks.yeast
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["yes", "no"] or picks.map(func(p: Dictionary) -> String: return str(p.label)) != ["효모 넣음", "안 넣음"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the yeast buttons %s" % str(picks))
	var objects: Array = definition.manipulation.objects
	if objects.size() != 1 or objects[0].id != DoughLab.BOWL_ID or objects[0].surface != DoughLab.SHELF_SURFACE or objects[0].get("guide_to", "") != "min" or objects[0].get("hold", false):
		problems.append("the bowl %s" % str(objects))
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	if PieceArt.of_experiment(ID) != PieceArt.of_island("curie"):
		problems.append("its piece is %s" % PieceArt.of_experiment(ID))
	expect.call(problems.is_empty(), "dough: a valid definition, a curie island lab, the yeast button (효모 넣음 / 안 넣음, code-drawn pictures), the bowl dragged towards the oven; code-drawn question pictures; the island's lens piece",
		"; ".join(problems))


## The section "## 4. 빵 반죽 부풀리기" of the lines doc: its numbered lines [who, face, text, picture],
## the question, the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 4. 빵 반죽 부풀리기")
	var end := text.find("\n## ", start + 4)
	var out := {"lines": [], "rows": [], "question": {}, "text": ""}
	if start < 0:
		return out
	out.text = text.substr(start, end - start)
	var said := RegEx.create_from_string("^\\d+\\. (\\S+)\\((\\S+)\\): (.+)$")
	var asked := RegEx.create_from_string("^\\d+\\. 질문\\((\\S+), (\\S+)\\): (.+)$")
	for raw in str(out.text).split("\n"):
		var line := raw.strip_edges()
		var q := asked.search(line)
		if q != null:
			out.question = {"who": q.get_string(1), "face": q.get_string(2), "text": q.get_string(3)}
			continue
		var m := said.search(line)
		if m != null:
			var words := m.get_string(3)
			var cut := words.find(" [그림:")
			out.lines.append([m.get_string(1), m.get_string(2), words.substr(0, cut) if cut >= 0 else words, cut >= 0])
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
	var faces := {"걱정": "worried", "생각": "thinking", "설명": "explain", "기쁨": "happy", "놀람": "surprised"}
	var who := {"야옹이": "yaongi", "빵고양이": "cat", "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition)
	if doc.lines.size() != 4 or opening.size() != 4:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 4:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			var picture := "yeast" if want[3] else ""
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != want[2] or str(got.get("picture", "")) != picture:
				problems.append("line %d: %s/%s '%s' %s (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(got.get("picture", "")), str(want)])
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
	if str(stages[1].miss).contains("하루") or str(doc.rows[1][4] if doc.rows.size() > 1 else "").contains("하루"):
		problems.append("stage 2's miss still says 하루")
	expect.call(problems.is_empty(), "dough: the Korean lines are curie-lines.md 4 word for word (야옹이 worried, the bread cat, Puppy, Dugi with the yeast card, the question, the riddle, the three stages with their wrong-button lines; stage 2's miss without 하루) with its faces",
		"; ".join(problems))


## curie-missions.md 4: the conditions 효모 넣음 / 안 넣음 / 효모 넣음 (the buttons' words), the lines doc's
## three missions (decision 6), the one science word 효모 (Dugi's introduction marks it, and only it).
func check_missions_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 4. 빵 반죽 부풀리기")
	var section := text.substr(start, text.find("\n### ", start + 4) - start)
	var rows := []
	for raw in section.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges()))
	var labels := {}
	for p: Dictionary in _definition().kid.picks.yeast:
		labels[p.value] = p.label
	var stages: Array = _definition().missions.stages
	var got_conditions: Array = stages.map(func(s: Dictionary) -> String: return str(labels.get(s.conditions.yeast, "?")))
	var got_texts: Array = stages.map(func(s: Dictionary) -> String: return str(s.text))
	var intro := str(_definition().kid.intro)
	var marks := RegEx.create_from_string("\\*\\*([^*]+)\\*\\*").search_all(intro).map(func(m: RegExMatch) -> String: return m.get_string(1))
	var says := " ".join(stages.map(func(s: Dictionary) -> String: return str(s.say)))
	expect.call(start >= 0 and section.contains("**조건 단추**: 효모 넣음 / 안 넣음") and section.contains("**과학 낱말**: **효모**") \
			and rows.map(func(r: Array) -> String: return str(r[1])) == got_conditions and rows.map(func(r: Array) -> String: return str(r[2])) == got_texts \
			and got_conditions == ["효모 넣음", "안 넣음", "효모 넣음"] and marks == ["효모"] and not says.contains("**") and not rows.any(func(r: Array) -> bool: return str(r[3]).contains("하루")),
		"dough: curie-missions.md 4 has the lines doc's three missions and the conditions 효모 넣음, 안 넣음, 효모 넣음; the one bold science word is 효모",
		"%s / %s %s, marks %s" % [str(rows), str(got_conditions), str(got_texts), str(marks)])


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
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/dough.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/dough.json")
	var en: Dictionary = Locale.overlay(raw, english)
	var en_words := _word_keys().map(func(k: String) -> String: return Locale.t("dough." + k))
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en_words.any(func(w: String) -> bool: return w == "" or w.begins_with("dough.")) or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "dough: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


static func _word_keys() -> Array:
	return ["dough.ready", "dough.rising", "dough.waiting", "dough.doubled", "dough.shelf", "dough.little", "dough.same",
		"spot.table", "spot.warm", "spot.cold", "yeast.yes", "yeast.no"]


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
	walk.call(walk, ID, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/dough.json")))
	for key: String in _word_keys():
		walk.call(walk, key, Locale.t("dough." + key))
	expect.call(found.is_empty(), "dough: every Korean line is 반말 (no 요 / 세요 / 니다)", "; ".join(found))


# --- the model ------------------------------------------------------------------------------------

## The same placing stepped the same way gives the same state; reset keeps the yeast and the goal and
## puts the bowl back on the table with the clock at the first morning.
func check_model() -> void:
	var problems := []
	var runs := []
	for k in 2:
		var m := _model(true, DoughModel.shelf_goal())
		m.place(DoughModel.COLD)
		var seen := []
		for i in 400:
			m.step(STEP)
			if i == 100:
				m.lift()
				m.place(DoughModel.WARM)
			if i % 25 == 0:
				seen.append([m.status(), m.doublings, m.clock.days])
		runs.append(seen)
	if runs[0] != runs[1]:
		problems.append("two runs differ")
	var m := _model(true, DoughModel.DOUBLE)
	if m.status() != "ready" or m.animating() or m.volume() != 1.0:
		problems.append("before the bowl is put down: %s" % m.status())
	m.place(DoughModel.WARM)
	m.step(STEP)
	if m.status() != "rising" or not m.animating() or m.volume() <= 1.0:
		problems.append("by the oven: %s, %.3f" % [m.status(), m.volume()])
	_run_out(m)
	if m.status() != "doubled" or absf(m.volume() - 2.0) > 1e-4:
		problems.append("run out: %s, %.4f" % [m.status(), m.volume()])
	m.reset()
	if m.spot() != DoughModel.TABLE or m.status() != "ready" or not m.has_yeast() or m.goal() != DoughModel.DOUBLE or m.clock.days != 0.0 or m.doublings != 0.0:
		problems.append("reset lost the yeast or the goal or kept the run")
	m.place(DoughModel.TABLE)
	if m.clock.running:
		problems.append("the time runs on the table")
	expect.call(problems.is_empty(), "dough model: deterministic, ready until the bowl is put down, rising by the oven, doubled at the goal; reset keeps the yeast and the goal and puts the bowl back; no time on the table",
		"; ".join(problems))


## Textbook values: by the oven (27 °C) dough with yeast doubles in about an hour, in the fridge (4 °C)
## in about twelve, so in the hour the warm one doubles the cold one grows by only 2^(1/12) (about 6 %);
## three times the volume (the shelf) takes log2 3 = 1.58 hours by the oven; dough without yeast does
## not rise through a whole day and night (one moon stamp); put by the oven after the fridge the dough
## goes on to the shelf. The pace: with yeast an hour is two play seconds, without a day is eight.
func check_textbook() -> void:
	var problems := []
	var warm := _model(true, DoughModel.DOUBLE)
	warm.place(DoughModel.WARM)
	var seconds := _run_out(warm)
	if absf(warm.clock.days * 24.0 - 1.0) > 0.01 or absf(warm.volume() - 2.0) > 1e-4 or absf(seconds - DoughModel.DAY_S_YEAST / 24.0) > 0.05:
		problems.append("warm doubling: %.3f h, %.3f x, %.2f s" % [warm.clock.days * 24.0, warm.volume(), seconds])
	var cold := _model(true, DoughModel.DOUBLE)
	cold.place(DoughModel.COLD)
	_run_out(cold)
	if absf(cold.clock.days * 24.0 - 1.0) > 0.01 or absf(cold.volume() - pow(2.0, 1.0 / 12.0)) > 1e-3 or cold.status() != "little":
		problems.append("cold the same hour: %.3f h, %.3f x, %s" % [cold.clock.days * 24.0, cold.volume(), cold.status()])
	if DoughModel.COLD_DOUBLE_H / DoughModel.WARM_DOUBLE_H != 12.0:
		problems.append("the fridge is not twelve times slower")
	var shelf := _model(true, DoughModel.shelf_goal())
	shelf.place(DoughModel.WARM)
	_run_out(shelf)
	if absf(shelf.clock.days * 24.0 - log(3.0) / log(2.0)) > 0.01 or absf(shelf.volume() - 3.0) > 1e-3 or shelf.status() != "shelf" or shelf.clock.nights() != 0:
		problems.append("to the shelf: %.3f h, %.3f x, %s" % [shelf.clock.days * 24.0, shelf.volume(), shelf.status()])
	var flat := _model(false, DoughModel.DOUBLE)
	flat.place(DoughModel.WARM)
	seconds = _run_out(flat)
	if flat.volume() != 1.0 or flat.status() != "same" or flat.clock.nights() != 1 or absf(seconds - DoughModel.DAY_S_FLAT) > 0.05:
		problems.append("no yeast: %.3f x, %s, %d nights, %.2f s" % [flat.volume(), flat.status(), flat.clock.nights(), seconds])
	var moved := _model(true, DoughModel.shelf_goal())
	moved.place(DoughModel.COLD)
	_run_out(moved)
	var was := moved.status()
	moved.place(DoughModel.WARM)
	_run_out(moved)
	if was != "little" or moved.status() != "shelf" or absf(moved.volume() - 3.0) > 1e-3:
		problems.append("fridge then oven: %s then %s, %.3f x" % [was, moved.status(), moved.volume()])
	expect.call(problems.is_empty(), "dough textbook: twice in an hour by the oven (27 °C), only %.0f %% bigger in that hour in the fridge (4 °C, twelve hours to double), the shelf (three times) in %.2f hours, no rising without yeast through a night; from the fridge to the oven it goes on to the shelf; an hour two play seconds, a flat day eight" \
			% [100.0 * (pow(2.0, 1.0 / 12.0) - 1.0), log(3.0) / log(2.0)],
		"; ".join(problems))


## The lock: free before the time runs, locked while it runs and while the bowl is held in the middle
## of it, free once the result is in and after a reset.
func check_lock() -> void:
	var problems := []
	var m := _model(false, DoughModel.DOUBLE)
	if m.clock.locks_conditions():
		problems.append("locked before")
	m.place(DoughModel.WARM)
	m.step(STEP)
	if not m.clock.locks_conditions():
		problems.append("free while running")
	m.lift()
	if not m.clock.locks_conditions():
		problems.append("free while held in the middle")
	m.place(DoughModel.WARM)
	_run_out(m)
	if m.clock.locks_conditions() or m.status() != "same":
		problems.append("locked after the result (%s)" % m.status())
	m.place(DoughModel.WARM)
	m.step(STEP)
	m.reset()
	if m.clock.locks_conditions():
		problems.append("locked after reset")
	var lab := _lab()
	if lab.conditions_locked():
		problems.append("the lab locked at the start")
	lab.free()
	expect.call(problems.is_empty(), "dough lock: the conditions locked while the time runs (also while the bowl is held in the middle), free once the result is in and after 다시",
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var model := lab.model as DoughModel
	# [stage, yeast, spot, play seconds (-1: run out), hit, missed]
	var cases := [
		[0, "yes", DoughModel.WARM, -1.0, true, false], [0, "yes", DoughModel.COLD, -1.0, false, true],
		[0, "yes", DoughModel.WARM, 0.5, false, false], [0, "no", DoughModel.WARM, -1.0, false, true],
		[1, "no", DoughModel.WARM, -1.0, true, false], [1, "no", DoughModel.WARM, 1.0, false, false],
		[1, "no", DoughModel.WARM, 3.0, false, true], [1, "yes", DoughModel.WARM, -1.0, false, true],
		[2, "yes", DoughModel.WARM, -1.0, true, false], [2, "yes", DoughModel.COLD, -1.0, false, true],
		[2, "no", DoughModel.WARM, -1.0, false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.set_control(DoughLab.YEAST_CONTROL, case[1])
		lab.reset_run()
		model.place(float(case[2]))
		if float(case[3]) < 0.0:
			_run_out(model)
		else:
			for i in int(round(float(case[3]) / STEP)):
				model.step(STEP)
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations()) and lab.settled()
		if (stamps == stage + 1) != bool(case[4]) or missed != bool(case[5]):
			problems.append("stage %d %s (%s, settled %s): stamps %d missed %s" % [stage + 1, str(case), status, lab.settled(), stamps, missed])
	lab.set_game_stage(0, 0, false)
	lab.set_control(DoughLab.YEAST_CONTROL, "yes")
	lab.reset_run()
	model.place(DoughModel.WARM)
	_run_out(model)
	lab.manipulation_started(DoughLab.BOWL_ID)
	if lab.settled():
		problems.append("settled while the finger holds the bowl")
	lab.manipulation_placed(DoughLab.BOWL_ID, Transform3D(Basis(), DoughProps.bowl_point(DoughModel.WARM)))
	if not lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("not judged after the let-go (%s)" % lab.status())
	expect.call(problems.is_empty(), "dough judging: doubled by the oven / the same after a night without yeast / the shelf hit; the fridge, the wrong button and the waiting day say Puppy's lines (after %.1f days); not while rising; not while the finger holds the bowl" % DoughModel.HINT_DAYS,
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the hand -------------------------------------------------------------------------------------

func _hand(size := VIEW_SIZE) -> Dictionary:
	var host := Control.new()
	host.size = size
	tree.root.add_child(host)
	var view: View3D = load(VIEW_3D).new()
	view.size = size
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
	return {"host": host, "view": view, "lab": lab, "m": m, "per_unit": Vector2(view.viewport.size) / view.size}


## The shell's finger drags the bowl from `from` to `to` (world) and lets go.
func _drag(h: Dictionary, from: Vector3, to: Vector3) -> void:
	var view: View3D = h.view
	var m: Manipulator = h.m
	var at := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / h.per_unit
	m.handle_pointer("press", at.call(from))
	for k in range(1, 7):
		m.handle_pointer("move", at.call(from.lerp(to, k / 6.0)))
		await tree.process_frame
	m.handle_pointer("release", at.call(to))
	await tree.process_frame


func check_drag() -> void:
	var h: Dictionary = await _hand()
	var lab: DoughLab = h.lab
	var m: Manipulator = h.m
	var model := lab.model as DoughModel
	var props: DoughProps = lab.props
	var problems := []
	lab.set_game_stage(2, 2, false)
	await tree.process_frame
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != DoughLab.BOWL_ID or (guide.get("to", Vector3.ZERO) as Vector3).x >= (guide.get("from", Vector3.ZERO) as Vector3).x:
		problems.append("hand guide %s" % str(guide))
	if not props.shown_rings or props.shown_fire:
		problems.append("at the start: rings %s, fire %s" % [props.shown_rings, props.shown_fire])
	var up := Vector3.UP * DoughLab.KNOB_UP
	var start := DoughProps.bowl_point(DoughModel.TABLE) + up
	# Let go short of both places: back on the table, no time.
	await _drag(h, start, KitchenSet.table_point(-0.5, DoughProps.BOWL_Z) + up)
	if model.spot() != DoughModel.TABLE or model.clock.started or props.bowl.position.distance_to(DoughProps.bowl_point(DoughModel.TABLE)) > 1e-3:
		problems.append("let go short: spot %.0f, started %s, the bowl at %s" % [model.spot(), model.clock.started, str(props.bowl.position)])
	# To the fridge: the door opens, the bowl stands inside, the time runs.
	await _drag(h, start, KitchenSet.table_point(DoughProps.COLD_X, DoughProps.BOWL_Z) + up)
	if model.spot() != DoughModel.COLD or not model.clock.running or props.shown_door <= 0.0 or not props.mist.visible \
			or props.bowl.position.distance_to(DoughProps.bowl_point(DoughModel.COLD)) > 1e-3 or not props.sign.lamp.visible or props.shown_rings:
		problems.append("at the fridge: spot %.0f, running %s, door %.0f, the bowl at %s" % [model.spot(), model.clock.running, props.shown_door, str(props.bowl.position)])
	if lab.knobs[DoughLab.BOWL_ID].global_position.distance_to(props.bowl.global_position + up * props.bowl.scale.y) > 1e-3:
		problems.append("the knob is not on the bowl in the fridge")
	var frames := 0
	while model.clock.running and frames < 400:
		await tree.physics_frame
		frames += 1
	if model.status() != "little":
		problems.append("in the fridge: %s" % model.status())
	# Picked up in the fridge where it stands, carried to the oven: the fire, the time runs on.
	var inside := props.bowl.global_position + up * props.bowl.scale.y
	var view: View3D = h.view
	var per_unit: Vector2 = h.per_unit
	m.handle_pointer("press", view.rig.unproject_position(inside) / per_unit)
	if lab.holding != DoughLab.BOWL_ID:
		problems.append("not picked up where it stands in the fridge")
	var days := model.clock.days
	for k in range(1, 7):
		m.handle_pointer("move", view.rig.unproject_position(inside.lerp(KitchenSet.table_point(0.0, DoughProps.BOWL_Z) + up, k / 6.0)) / per_unit)
		await tree.process_frame
	if model.clock.running or model.clock.days != days:
		problems.append("the time ran while the bowl was held")
	m.handle_pointer("release", view.rig.unproject_position(KitchenSet.table_point(0.0, DoughProps.BOWL_Z) + up) / per_unit)
	await tree.process_frame
	if model.spot() != DoughModel.COLD:
		problems.append("let go between: not back in the fridge (spot %.0f)" % model.spot())
	await _drag(h, inside, KitchenSet.table_point(DoughProps.WARM_X + 0.1, DoughProps.BOWL_Z) + up)
	if model.spot() != DoughModel.WARM or not model.clock.running or not props.shown_fire or props.shown_door != 0.0:
		problems.append("by the oven: spot %.0f, running %s, fire %s, door %.0f" % [model.spot(), model.clock.running, props.shown_fire, props.shown_door])
	# Picked up by the oven in the middle of the run: the time stops; put back, it goes on to the shelf.
	await tree.physics_frame
	var warm := props.bowl.global_position + up
	m.handle_pointer("press", view.rig.unproject_position(warm) / per_unit)
	await tree.process_frame
	var held_days := model.clock.days
	for i in 10:
		await tree.physics_frame
	if lab.holding != DoughLab.BOWL_ID or model.clock.running or model.clock.days != held_days or not model.clock.locks_conditions():
		problems.append("held by the oven: holding '%s', running %s" % [lab.holding, model.clock.running])
	m.handle_pointer("release", view.rig.unproject_position(warm) / per_unit)
	await tree.process_frame
	frames = 0
	while model.clock.running and frames < 600:
		await tree.physics_frame
		frames += 1
	if model.status() != "shelf" or absf(DoughProps.dough_top(props.shown_volume) + KitchenSet.TABLE_TOP - DoughProps.SHELF_Y) > 0.01 or model.clock.locks_conditions():
		problems.append("after: %s, the dough's top %.3f (shelf %.3f)" % [model.status(), DoughProps.dough_top(props.shown_volume) + KitchenSet.TABLE_TOP, DoughProps.SHELF_Y])
	expect.call(problems.is_empty(), "dough hand: the bowl let go short goes back; at the fridge the door opens and it stands inside (the time runs, a little rise), picked up there where it stands, let go between it goes back in; by the oven the fire and the time; picked up there the time stops, put back it goes on to the shelf; the hand guide drags it to the oven",
		"; ".join(problems))
	(h.host as Control).queue_free()
	await tree.process_frame


## A day without yeast by the oven: the scene goes dark at night and morning comes back with one moon
## stamp under the sign; the dough stays flat.
func check_night() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var model := lab.model as DoughModel
	var props: DoughProps = lab.props
	lab.set_game_stage(1, 1, false)
	lab.set_control(DoughLab.YEAST_CONTROL, "no")
	lab.manipulation_started(DoughLab.BOWL_ID)
	lab.manipulation_placed(DoughLab.BOWL_ID, Transform3D(Basis(), DoughProps.bowl_point(DoughModel.WARM)))
	var darkest := 0.0
	var frames := 0
	while model.clock.running and frames < 1200:
		await tree.physics_frame
		frames += 1
		darkest = maxf(darkest, props.shown_night)
	await tree.process_frame
	var ok := darkest > 0.99 and props.shown_night < 0.01 and props.sign.shown_nights == 1 and not props.sign.lamp.visible \
		and props.shown_volume == 1.0 and model.status() == "same" and props.bubbles.multimesh.visible_instance_count == 0
	expect.call(ok, "dough night: a day without yeast goes dark at night (stars, the tint), morning comes back with one moon stamp, the dough flat and smooth",
		"darkest %.2f, now %.2f, %d stamps, volume %.2f, %s after %d frames" % [darkest, props.shown_night, props.sign.shown_nights, props.shown_volume, model.status(), frames])
	lab.queue_free()
	await tree.process_frame


# --- the goals ------------------------------------------------------------------------------------

func check_goals() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var props: DoughProps = lab.props
	var model := lab.model as DoughModel
	var problems := []
	for stage: int in [0, 1, 2]:
		lab.set_game_stage(stage, stage, false)
		var twice := stage < DoughLab.SHELF_STAGE
		if (model.goal() == DoughModel.DOUBLE) != twice or props.mark.visible != twice or not props.sign.visible:
			problems.append("stage %d: goal %.2f, mark %s" % [stage + 1, model.goal(), props.mark.visible])
	lab.set_game_stage(1, 1, false)
	lab.reset_run()
	model.place(DoughModel.WARM)
	_run_out(model)
	lab.set_game_stage(2, 2, true)
	if model.goal() != DoughModel.DOUBLE:
		problems.append("the cleared stage's goal went at once")
	lab.reset_run()
	if absf(model.goal() - DoughModel.shelf_goal()) > 1e-9:
		problems.append("the next goal did not come with the reset")
	# The round done just now: the result stays through the next reset (more play after the card).
	model.place(DoughModel.WARM)
	_run_out(model)
	lab.set_game_stage(-1, 3, true)
	lab.reset_run()
	if lab.status() != "shelf" or lab.observations().dough != Locale.t("dough.dough.shelf"):
		problems.append("after the round: %s '%s'" % [lab.status(), lab.observations().dough])
	lab.reset_run()
	if lab.status() != "ready":
		problems.append("다시 after the round: %s" % lab.status())
	# A finished spot opened again shows the shelf, not the flat start; a condition starts it over.
	lab.set_game_stage(-1, 3, false)
	if lab.status() != "shelf" or model.spot() != DoughModel.WARM or absf(props.shown_volume - DoughModel.SHELF_RISE) > 1e-3 or lab.conditions_locked():
		problems.append("a finished spot: %s, volume %.2f" % [lab.status(), props.shown_volume])
	lab.set_control(DoughLab.YEAST_CONTROL, "no")
	if lab.status() != "ready" or model.has_yeast():
		problems.append("안 넣음 after the round: %s" % lab.status())
	lab.set_control(DoughLab.YEAST_CONTROL, "yes")
	expect.call(problems.is_empty(), "dough goals: twice (the dashed line) on stages 1-2, the shelf on stage 3; a stage just cleared keeps its goal until the next reset; a finished round shows the dough at the shelf (선반까지 닿았어) through the card's reset, until 다시 or a condition",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- no numbers -----------------------------------------------------------------------------------

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
	for stage in [-1, 0, 1, 2]:
		if ExperimentRegistry.shown_cards(definition, stage) != ["dough"]:
			problems.append("cards %s on stage %d" % [str(ExperimentRegistry.shown_cards(definition, stage)), stage])
	var model := lab.model as DoughModel
	var seen := {}
	for s: Array in [["yes", DoughModel.TABLE, 0, 0.0], ["yes", DoughModel.WARM, 0, 0.5], ["yes", DoughModel.WARM, 0, -1.0], ["yes", DoughModel.COLD, 2, -1.0],
			["yes", DoughModel.WARM, 2, -1.0], ["no", DoughModel.WARM, 1, 1.0], ["no", DoughModel.WARM, 1, -1.0]]:
		lab.set_game_stage(int(s[2]), int(s[2]), false)
		lab.set_control(DoughLab.YEAST_CONTROL, s[0])
		lab.reset_run()
		model.place(float(s[1]))
		if float(s[3]) < 0.0:
			_run_out(model)
		else:
			for i in int(round(float(s[3]) / STEP)):
				model.step(STEP)
		var obs := lab.observations()
		for key: String in obs:
			seen[obs[key]] = true
			if not obs[key] is String or str(obs[key]) == "" or digits.search(str(obs[key])) != null or str(obs[key]).begins_with("dough."):
				problems.append("%s: %s" % [key, str(obs[key])])
	if seen.size() < 10:
		problems.append("only %d different words" % seen.size())
	lab.set_control(DoughLab.YEAST_CONTROL, "yes")
	expect.call(problems.is_empty(), "dough: no number on the screen (the observations are words, no units; the card is the dough on every stage)",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the screen's lock ----------------------------------------------------------------------------

## On the real screen: the yeast buttons dimmed and not taking taps while the time runs, a tap on a
## locked condition changes nothing, the buttons free again once the result is in.
func check_screen_lock() -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(_definition(), {})
	host.add_child(screen)
	await tree.process_frame
	await tree.physics_frame
	for i in 3:
		await tree.process_frame
	screen.mission_round.end_question()
	screen._show_stamps(0)
	await tree.process_frame
	var problems := []
	var lab: DoughLab = screen.experiment
	var buttons: Array = screen.pick_buttons()
	if buttons.size() != 2 or screen.picks_locked() or buttons.any(func(p: Dictionary) -> bool: return (p.button as Button).disabled):
		problems.append("before: %d buttons, locked %s" % [buttons.size(), screen.picks_locked()])
	lab.manipulation_started(DoughLab.BOWL_ID)
	lab.manipulation_placed(DoughLab.BOWL_ID, Transform3D(Basis(), DoughProps.bowl_point(DoughModel.WARM)))
	await tree.process_frame
	await tree.process_frame
	var row: Control = screen._picks_row
	if not screen.picks_locked() or not buttons.all(func(p: Dictionary) -> bool: return (p.button as Button).disabled) or row == null or row.modulate.a > 0.5:
		problems.append("while the time runs: locked %s, row alpha %.2f" % [screen.picks_locked(), row.modulate.a if row != null else -1.0])
	var resets := lab.reset_count
	screen._set_control(DoughLab.YEAST_CONTROL, "no")
	if lab.control_value(DoughLab.YEAST_CONTROL) != "yes" or lab.reset_count != resets or not lab.model.clock.running:
		problems.append("a locked tap changed the yeast (%s) or reset the run" % str(lab.control_value(DoughLab.YEAST_CONTROL)))
	var frames := 0
	while lab.model.clock.running and frames < 400:
		await tree.physics_frame
		frames += 1
	await tree.process_frame
	if screen.picks_locked() or buttons.any(func(p: Dictionary) -> bool: return (p.button as Button).disabled) or (row != null and row.modulate.a < 0.99):
		problems.append("after the result: still locked")
	expect.call(problems.is_empty(), "dough screen lock: the yeast buttons dimmed and not taking taps while the time runs, a tap on the locked condition changes nothing, free again once the result is in",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame
	DirAccess.remove_absolute(ProgressStore.path)


# --- in view --------------------------------------------------------------------------------------

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
		var props: DoughProps = lab.props
		var game: DoughGame = lab.game
		props.cat.advance(0.0)
		var b := props.cat.bounds()
		inside.call(at.call(b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5)), "the cat's head")
		for spot: float in [DoughModel.TABLE, DoughModel.WARM, DoughModel.COLD]:
			inside.call(at.call(DoughProps.bowl_point(spot) + Vector3.UP * DoughLab.KNOB_UP), "the bowl at %.0f" % spot)
		inside.call(at.call(game.rest_point()), "the piece on the shelf")
		inside.call(at.call(DoughGame.board_front() + Vector3(DoughProps.BOARD.x * 0.5, 0.0, 0.0)), "the shelf's right end")
		inside.call(at.call(DoughProps.OVEN_AT + Vector3(0.0, DoughProps.OVEN.y + 0.5, 0.5)), "the oven's dome")
		inside.call(at.call(DoughProps.FRIDGE_AT + Vector3(DoughProps.FRIDGE.x * 0.5, DoughProps.FRIDGE.y, 0.5)), "the fridge's top right")
		for dx: float in [-0.5, 0.5]:
			inside.call(at.call(DoughProps.SIGN_AT + Vector3(dx * (TimeSign.BAR.x + 0.8), 0.0, 0.0)), "the time sign")
		props.sign.show_time(0.5, 3, true)
		inside.call(at.call(props.sign.global_position + props.sign.lamp.position), "the sign's lamp")
		inside.call(at.call(props.sign.global_position + props.sign.stamps.position), "the moon stamps")
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "dough in view: the bowl (on the table, by the oven, in the fridge), the oven, the shelf with the piece, the fridge, the bread cat's head and the time sign (its lamp and stamps) between the top band and the bottom %.0f%% (phone, desktop and tablet)" % ((1.0 - BOTTOM_FREE) * 100.0),
		"; ".join(problems.slice(0, 6)))


## The two rings (the warm and the cold place) lie wholly on the table's top: in the world every point
## of their outline inside the top's rectangle, and on the phone, the desktop and the tablet inside the
## top's four corners as drawn (2026-11-17 user, the tablet: the cold ring stuck out past the table's
## right edge); a let-go inside a ring is caught there, just outside it is not.
func check_rings_on_table() -> void:
	var problems := []
	var half := KitchenSet.TABLE_SIZE * 0.5
	var lo := Vector2(KitchenSet.TABLE_AT.x - half.x, KitchenSet.TABLE_AT.z - half.z)
	var hi := Vector2(KitchenSet.TABLE_AT.x + half.x, KitchenSet.TABLE_AT.z + half.z)
	var rings := {"warm": KitchenSet.table_point(DoughProps.WARM_X, DoughProps.BOWL_Z), "cold": KitchenSet.table_point(DoughProps.COLD_X, DoughProps.BOWL_Z)}
	for name: String in rings:
		for p: Vector3 in DoughProps.ring_outline(rings[name]):
			if p.x < lo.x or p.x > hi.x or p.z < lo.y or p.z > hi.y:
				problems.append("the %s ring at %s past the table" % [name, str(p)])
				break
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
		var at := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world)
		var y := KitchenSet.TABLE_TOP
		var top := PackedVector2Array([at.call(Vector3(lo.x, y, lo.y)), at.call(Vector3(hi.x, y, lo.y)), at.call(Vector3(hi.x, y, hi.y)), at.call(Vector3(lo.x, y, hi.y))])
		for name: String in rings:
			for p: Vector3 in DoughProps.ring_outline(rings[name]):
				if not Geometry2D.is_point_in_polygon(at.call(p), top):
					problems.append("%s: the %s ring drawn past the table's top" % [str(size), name])
					break
		host.queue_free()
		await tree.process_frame
	for name: String in rings:
		var x: float = rings[name].x
		var want := DoughModel.WARM if name == "warm" else DoughModel.COLD
		if DoughProps.spot_at(x + DoughProps.RING_R * 0.95) != want or DoughProps.spot_at(x - DoughProps.RING_R * 0.95) != want \
				or DoughProps.spot_at(x + DoughProps.RING_R * 1.1) == want or DoughProps.spot_at(x - DoughProps.RING_R * 1.1) == want:
			problems.append("the %s ring does not catch what it shows" % name)
	expect.call(problems.is_empty(), "dough rings: the warm and the cold ring lie wholly on the table's top (the world and as drawn on the phone, the desktop and the tablet); a let-go is caught just inside a ring, not just outside",
		"; ".join(problems.slice(0, 6)))


## The two rings stay clear of the cast as drawn on the phone, the desktop and the tablet: the screen
## rectangle of each ring's outline overlaps neither Puppy (his flag's pole and cloth included), nor
## 야옹이, nor Dugi (2026-11-17 user, the tablet: Puppy's flag stood over the cold ring's right end).
func check_rings_clear_of_cast() -> void:
	var problems := []
	var rings := {"warm": KitchenSet.table_point(DoughProps.WARM_X, DoughProps.BOWL_Z), "cold": KitchenSet.table_point(DoughProps.COLD_X, DoughProps.BOWL_Z)}
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
		var cast := IslandCast.create(_definition(), lab)
		lab.add_child(cast)
		for i in 2:
			await tree.process_frame
		var at := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world)
		var rect_of := func(points: Array) -> Rect2:
			var r := Rect2(at.call(points[0]), Vector2.ZERO)
			for p: Vector3 in points:
				r = r.expand(at.call(p))
			return r
		var box_rect := func(b: AABB) -> Rect2:
			var corners := []
			for k in 8:
				corners.append(b.get_endpoint(k))
			return rect_of.call(corners)
		var people := {"Puppy and his flag": cast.puppy.bounds(), "야옹이": IslandCast.drawn_bounds(cast.yaongi), "Dugi": IslandCast.drawn_bounds(cast.dugi)}
		for name: String in rings:
			var ring: Rect2 = rect_of.call(Array(DoughProps.ring_outline(rings[name])))
			for who: String in people:
				var other: Rect2 = box_rect.call(people[who])
				if ring.intersects(other):
					problems.append("%s: the %s ring %s under %s %s" % [str(size), name, str(ring), who, str(other)])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "dough rings clear of the cast: neither ring under Puppy (his flag's pole and cloth), 야옹이 or Dugi on the phone, the desktop and the tablet",
		"; ".join(problems.slice(0, 4)))


# --- the spot, the pictures, the opening, the piece ------------------------------------------------

func check_spot() -> void:
	var curie := Island.by_id("curie")
	var problems := []
	if str(curie.order[3]) != ID or ExperimentRegistry.find(ID).is_empty():
		problems.append("dough is not curie's fourth spot as an experiment")
	if curie.playable():
		problems.append("the island opened before all its spots are labs")
	var own := ArtKit.builder()
	MapLandmarks.add(own, ID, Transform3D())
	var other := ArtKit.builder()
	MapLandmarks.add(other, "no-such-spot", Transform3D())
	if own.vertex_count() <= other.vertex_count():
		problems.append("the map shows the unknown spot's ball on a post")
	expect.call(problems.is_empty(), "dough: the curie island's fourth spot is an experiment with its own map landmark (the oven, the bowl, the shelf); the island stays in the making", "; ".join(problems))


func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var kinds := [["predict", "dough_warm"], ["predict", "dough_cold"], ["pick", "dough_yeast"], ["pick", "dough_plain"], ["explain", "yeast"]]
	for kind: Array in kinds:
		var draw := func() -> void:
			match str(kind[0]):
				"predict":
					PredictPictures.draw(canvas, kind[1])
				"pick":
					PickPictures.draw(canvas, kind[1])
				"explain":
					ExplainPictures.draw_card(canvas, kind[1], Rect2(Vector2.ZERO, canvas.size))
			drawn.append(kind[1])
		canvas.draw.connect(draw)
		canvas.queue_redraw()
		await tree.process_frame
		canvas.draw.disconnect(draw)
	canvas.queue_free()
	var listed := "dough_warm" in PredictPictures.KINDS and "dough_cold" in PredictPictures.KINDS and "dough_yeast" in PickPictures.KINDS \
		and "dough_plain" in PickPictures.KINDS and "yeast" in ExplainPictures.KINDS
	# The question's two cards draw the same bowl and dough (only the place differs: no hint of the answer).
	var same: Variant = (load("res://scripts/shell/predict_pictures.gd") as GDScript).get_script_constant_map().get("DOUGH_QUESTION_RISE")
	listed = listed and same is float and float(same) > 1.0 and float(same) < 2.0
	expect.call(listed and drawn == kinds.map(func(k: Array) -> String: return k[1]),
		"dough pictures: the question's places (oven / fridge, the same bowl on both: no hint of the answer), the yeast buttons (puffy / flat) and Dugi's yeast card are listed and draw", str(drawn))


func check_opening() -> void:
	var definition := _definition()
	var was := Story.enabled
	Story.enabled = true
	var store := MissionRound.MemoryProgress.new()
	var round := MissionRound.new(definition, store)
	round.start()
	round.open(true)
	var told := []
	while round.phase() == MissionRound.Phase.CLUE and told.size() < 8:
		var line := round.clue_to_open()
		told.append([line.speaker, line.face, str(line.get("picture", ""))])
		round.clue_opened()
		round.clue_read()
	Story.enabled = was
	expect.call(told == [["yaongi", "worried", ""], ["cat", "happy", ""], ["puppy", "thinking", ""], ["dugi", "explain", "yeast"]] and round.phase() == MissionRound.Phase.ASKING,
		"dough opening: first visit 야옹이 (worried), the bread cat, Puppy's clue, Dugi with the yeast card, then the question", str(told))


## The piece: on the shelf from the start (a lamp a stamp); the last stamp hops it off the shelf and it
## jumps down in front of the bread cat; a finished spot has no piece.
func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: DoughGame = lab.game
	var problems := []
	await tree.process_frame
	if game.piece_state != "held" or not game.piece.visible or game.piece.global_position.distance_to(game.rest_point()) > 1e-3:
		problems.append("not on the shelf at the start")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	if game._lamps_lit != 2:
		problems.append("lamps %d after two stamps" % game._lamps_lit)
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 500:
		await tree.process_frame
		frames += 1
	if game.piece_state != "out" or game.piece.global_position.distance_to(lab.props.cat.global_position) > 2.2:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(game.piece.global_position)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	expect.call(problems.is_empty(), "dough piece: on the high shelf from the start (a lamp a stamp), off the shelf at the last stamp and down in front of the bread cat",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame
