## 퍼지는 냄새와 잉크 (#156, 2026-11-15; Curie Island's first spot, the frame of its chemistry labs):
## - the data: the definition is valid, the curie island's first lab (index.json `islands.curie`), not one
##   of the first island's; the dropper is a hold object shown as a tap; the question's and the water
##   buttons' pictures are code-drawn kinds; its Korean lines are docs/islands/curie-lines.md section 1
##   word for word (야옹이, the bread cat, Puppy, Dugi's two lines with the particles card, the question,
##   its choices, reason and bridge, the riddle, every stage's mission, explanation, win, miss and
##   wrong-condition line) with the doc's faces, spoken by the island's keeper 야옹이; the conditions are
##   curie-missions.md 1's; Puppy's result lines are short with no science words, digits or symbols; every
##   Korean line is 반말; English has every line;
## - the model: the same steps give the same state (deterministic); the textbook values (water's
##   viscosity at 20 and 80 °C, the spreading front's square root law); hot water spreads the ink faster
##   than cold (Stokes–Einstein, about 2.7 times at 50 °C); the smell in air reaches Puppy's nose before the ink
##   fills even the hot glass (a gas spreads faster than a liquid);
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's wait line), the
##   wrong water's line, nothing while the finger is on the dropper or right after the drop;
## - the hand: a press on the dropper's bulb is a new drop (nothing moves), the ink spreads after the
##   let-go; the hand guide taps it;
## - the bread cat does the lab (2026-11-15 user): on its crates on the table beside the glass, it
##   squeezes the bulb with both paws on it while the finger presses (pressing, the arms not stretched)
##   and lets go with the finger (effort 0); its crates stand on the table clear of the glasses, the loaf,
##   the bread box and the cast on every table;
## - the tables: stage 1 one glass, stage 2 a cold glass beside it, stage 3 the loaf (its smell to
##   Puppy's nose); a stage just cleared keeps its table until the next reset;
## - the water button: 찬물 / 뜨거운 물 (picture buttons on every stage) set the water, start the run over,
##   steam the hot glass; 다시 keeps it;
## - no number on the screen: the observations are words, no units; the ink's cloud and the smell's
##   haze sway but stay where the model's spread allows (in the glass's water, deeper sooner in hot
##   water; along the smell's way up to its front), in their colours and draw order;
## - what matters is in view: the dropper's bulb, the glasses (no smaller than before the cat came up on
##   the table: GLASS_MIN of the height), the bread cat's head, the loaf, Puppy's nose and the bread box
##   on the phone, the desktop and the tablet, clear of the top band and the bottom;
## - the spot: the curie map's first spot is this experiment (the island stays in the making until all
##   12 are labs), its map landmark is its own;
## - the opening (야옹이 first, the bread cat, Puppy's clue, Dugi's two lines) and the piece (in the bread
##   box until the last stamp, a lamp a stamp).
extends RefCounted

const ID := "diffusion"
const LINES_PATH := "res://../../docs/islands/curie-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/curie-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
## In view (as sea_breeze_checks): inside EDGE of the sides and top, above BOTTOM_FREE, and not under the
## top band on the left (TOP_FREE of the height over LEFT_BAND units).
const EDGE := 0.03
const BOTTOM_FREE := 0.8
const TOP_FREE := 0.38
const LEFT_BAND := 680.0
const LINE_MAX := 24
## The glass's least height on the screen (share of the view's height).
const GLASS_MIN := 0.148
## How close (m) the cat's paws are to their points on the bulb, and how far its arms may stretch.
const PAW_GAP := 0.02
const STRETCH_MAX := 1.05
const STEP := 1.0 / 60.0
## Water's viscosity (Pa·s) in the tables (CRC Handbook): 1.002 mPa·s at 20 °C, 0.355 at 80 °C.
const VISCOSITY_20 := 1.002e-3
const VISCOSITY_80 := 0.355e-3

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
	await check_hold()
	await check_cat_press()
	await check_tables()
	await check_condition_button()
	await check_no_numbers()
	await check_dots()
	await check_in_view()
	check_spot()
	await check_pictures()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> DiffusionLab:
	var lab := DiffusionLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## Steps `model` for `seconds` at the lab's fixed step.
static func _run(model: DiffusionModel, seconds: float) -> void:
	for k in int(round(seconds / STEP)):
		model.step(STEP)


## Play seconds of `model` until its status is `status` (stepping; INF past `limit`).
static func _time_to(model: DiffusionModel, status: String, limit := 60.0) -> float:
	var t := 0.0
	while model.status() != status and t < limit:
		model.step(STEP)
		t += STEP
	return t if model.status() == status else INF


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "diffusion: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("curie").map(func(d: Dictionary) -> String: return str(d.id))
	if island.is_empty() or island[0] != ID or ExperimentRegistry.island_of(ID) != "curie":
		problems.append("curie's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var objects: Array = definition.manipulation.objects
	if objects.size() != 1 or objects[0].id != DiffusionLab.KNOB_ID or not objects[0].get("hold", false) or objects[0].get("guide", "") != "tap":
		problems.append("the dropper is not a hold object shown as a tap: %s" % str(objects))
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var picks: Array = definition.kid.picks.water
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["cold", "hot"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the water buttons %s" % str(picks))
	if PieceArt.of_experiment(ID) != PieceArt.of_island("curie"):
		problems.append("its piece is %s, not the curie island's" % PieceArt.of_experiment(ID))
	expect.call(problems.is_empty(), "diffusion: a valid definition, the curie island's first lab (index.json islands.curie), not the first island's; the dropper is pressed (a tap); code-drawn question and water pictures; the island's lens piece",
		"; ".join(problems))


## The section "## 1. 퍼지는 냄새와 잉크" of the lines doc: its numbered lines [who, face, text, picture],
## the question, the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 1. 퍼지는 냄새와 잉크")
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
	if doc.lines.size() != 5 or opening.size() != 5:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 5:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			var picture := "particles" if want[3] else ""
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
	expect.call(problems.is_empty(), "diffusion: the Korean lines are curie-lines.md 1 word for word (야옹이, the bread cat, Puppy, Dugi's two with the particles card, the question, the riddle, the three stages with their wrong-water lines) with its faces",
		"; ".join(problems))


## curie-missions.md 1: the conditions 찬물 / 뜨거운 물 / 뜨거운 물, the button 찬물 / 뜨거운 물, the one
## science word 알갱이 (Dugi's introduction marks it, and only it).
func check_missions_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 1. 퍼지는 냄새와 잉크")
	var section := text.substr(start, text.find("\n### ", start + 4) - start)
	var rows := []
	for raw in section.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges())[1])
	var labels := {}
	for p: Dictionary in _definition().kid.picks.water:
		labels[p.value] = p.label
	var got: Array = _definition().missions.stages.map(func(s: Dictionary) -> String: return str(labels.get(s.conditions.water, "?")))
	var intro := str(_definition().kid.intro)
	var marks := RegEx.create_from_string("\\*\\*([^*]+)\\*\\*").search_all(intro).map(func(m: RegExMatch) -> String: return m.get_string(1))
	expect.call(start >= 0 and section.contains("**조건 단추**: 찬물 / 뜨거운 물") and section.contains("**과학 낱말**: **알갱이**") and rows == got \
			and got == ["찬물", "뜨거운 물", "뜨거운 물"] and marks == ["알갱이"],
		"diffusion: the stages' conditions are curie-missions.md 1's (찬물, 뜨거운 물, 뜨거운 물; the button 찬물 / 뜨거운 물); the one bold science word is 알갱이",
		"%s / %s, marks %s" % [str(rows), str(got), str(marks)])


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
	var told: Array = [Story.clue(definition), Story.map_clue(definition)]
	for line: String in told:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/diffusion.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/diffusion.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or Story.before(en).size() != 1 or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.water.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "diffusion: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


## Every Korean text of the spot (its locale file) is 반말: no sentence ends in 요 / 세요 / 니다.
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
	walk.call(walk, ID, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/diffusion.json")))
	for key in ["cup.clear", "cup.spreading", "cup.full", "smell.none", "smell.coming", "smell.nose", "water.cold", "water.hot"]:
		walk.call(walk, key, Locale.t("diffusion." + key))
	expect.call(found.is_empty(), "diffusion: every Korean line is 반말 (no 요 / 세요 / 니다)", "; ".join(found))


# --- the model ------------------------------------------------------------------------------------

## The same drop stepped the same way gives the same state (the judging reads only the model); a drop
## starts the run over; reset keeps the conditions.
func check_model() -> void:
	var problems := []
	var runs := []
	for k in 2:
		var m := DiffusionModel.new()
		m.set_site(DiffusionModel.PAIR)
		m.set_hot(true)
		m.drop()
		var seen := []
		for i in 600:
			m.step(STEP)
			if i % 30 == 0:
				seen.append([m.status(), m.ink(), m.beside()])
		runs.append(seen)
	if runs[0] != runs[1]:
		problems.append("two runs differ")
	var m := DiffusionModel.new()
	if m.status() != "ready" or m.animating() or m.ink() != 0.0:
		problems.append("before a drop: %s" % m.status())
	m.set_hot(true)
	m.drop()
	_run(m, 1.0)
	var spread := m.ink()
	m.drop()
	if m.input("time") != 0.0 or m.ink() != 0.0 or not m.dropped() or not m.is_hot():
		problems.append("a new drop did not start over (ink %.2f)" % m.ink())
	m.reset()
	if m.dropped() or not m.is_hot():
		problems.append("reset lost the water or kept the drop")
	if spread <= 0.0 or spread >= 1.0:
		problems.append("the ink after a second: %.2f" % spread)
	expect.call(problems.is_empty(), "diffusion model: deterministic (the same steps, the same state), a drop starts the run over, reset keeps the water", "; ".join(problems))


## Textbook values: water's viscosity (Vogel) within 2% of the tables at 20 and 80 °C; the spreading
## front follows x = sqrt(4 D t) (a quarter of the time, half the way); hot water spreads the ink about
## 2.7 times as fast as cold (Stokes–Einstein: 323 / 283 K times 1.307 / 0.547 mPa·s); a smell's D in air
## is about ten thousand times an ink's in water, so the smell reaches Puppy's nose before even the hot
## glass is all blue, and the stepped model gets there in the same order.
func check_textbook() -> void:
	var problems := []
	var v20 := DiffusionModel.viscosity(20.0)
	var v80 := DiffusionModel.viscosity(80.0)
	if absf(v20 / VISCOSITY_20 - 1.0) > 0.02 or absf(v80 / VISCOSITY_80 - 1.0) > 0.02:
		problems.append("viscosity %.4g / %.4g Pa·s" % [v20, v80])
	var full := DiffusionModel.full_time(DiffusionModel.COLD_C)
	if absf(DiffusionModel.reach(full * 0.25, full) - 0.5) > 1e-9 or DiffusionModel.reach(full, full) != 1.0:
		problems.append("the front is not a square root law")
	var ratio := DiffusionModel.full_time(DiffusionModel.COLD_C) / DiffusionModel.full_time(DiffusionModel.HOT_C)
	if ratio < 2.5 or ratio > 2.95:
		problems.append("hot is %.2f times as fast" % ratio)
	var gas := DiffusionModel.smell_d(20.0) / DiffusionModel.ink_d(20.0)
	if gas < 5e3 or gas > 2e4:
		problems.append("the smell's D is %.0f times the ink's" % gas)
	if not (DiffusionModel.smell_time() < DiffusionModel.full_time(DiffusionModel.HOT_C) and DiffusionModel.full_time(DiffusionModel.HOT_C) < DiffusionModel.full_time(DiffusionModel.COLD_C)):
		problems.append("order smell %.2f, hot %.2f, cold %.2f" % [DiffusionModel.smell_time(), DiffusionModel.full_time(DiffusionModel.HOT_C), DiffusionModel.full_time(DiffusionModel.COLD_C)])
	var times := {}
	for case: Array in [["cold", false, DiffusionModel.SINGLE, "full"], ["hot", true, DiffusionModel.SINGLE, "full"], ["smell", true, DiffusionModel.BREAD, "smell"]]:
		var m := DiffusionModel.new()
		m.set_hot(case[1])
		m.set_site(case[2])
		m.drop()
		times[case[0]] = _time_to(m, case[3])
	if not (times.smell < times.hot and times.hot < times.cold) or absf(times.cold - DiffusionModel.COLD_FULL_S) > 0.05:
		problems.append("stepped %s" % str(times))
	var hot := DiffusionModel.new()
	hot.set_hot(true)
	hot.set_site(DiffusionModel.BREAD)
	hot.drop()
	_time_to(hot, "smell")
	if hot.ink() >= 1.0:
		problems.append("the hot glass was blue before the smell reached the nose")
	expect.call(problems.is_empty(), "diffusion textbook: water's viscosity at 20 / 80 °C, x = sqrt(4 D t), hot water %.1f times as fast as cold, the smell (D %.0f times the ink's) at Puppy's nose in %.1f s before the hot glass is blue (%.1f s; cold %.0f s)" \
			% [ratio, gas, DiffusionModel.smell_time(), DiffusionModel.full_time(DiffusionModel.HOT_C), DiffusionModel.full_time(DiffusionModel.COLD_C)],
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

## [stage, water, seconds after the drop, hit, missed] on the real lab (MissionRound.judge / missed).
func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var cases := [
		[0, "cold", 0.5, false, false], [0, "cold", 3.0, false, true], [0, "cold", 12.5, true, false],
		[0, "hot", 1.5, false, true], [0, "hot", 4.0, false, false],
		[1, "hot", 0.5, false, false], [1, "hot", 1.5, false, true], [1, "hot", 3.6, true, false], [1, "hot", 13.0, true, false],
		[1, "cold", 3.0, false, true], [1, "cold", 13.0, false, true],
		[2, "hot", 0.5, false, false], [2, "hot", 1.2, false, true], [2, "hot", 2.0, true, false], [2, "cold", 2.0, false, false],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.set_control("water", case[1])
		lab.hold_started(DiffusionLab.KNOB_ID)
		lab.hold_ended(DiffusionLab.KNOB_ID)
		_run(lab.model as DiffusionModel, float(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations()) and lab.settled()
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s at %.1f s (%s, settled %s): stamps %d missed %s" % [stage + 1, case[1], float(case[2]), status, lab.settled(), stamps, missed])
	var wants := [["cold", "찬물을 골라 봐!"], ["hot", "뜨거운 물을 골라 봐!"], ["hot", "뜨거운 물을 골라 봐!"]]
	for i in 3:
		lab.set_control("water", "hot" if wants[i][0] == "cold" else "cold")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong water says '%s'" % [i + 1, line[0]])
	lab.set_game_stage(0, 0, false)
	lab.set_control("water", "cold")
	lab.hold_started(DiffusionLab.KNOB_ID)
	_run(lab.model as DiffusionModel, 13.0)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the finger is on the dropper")
	lab.hold_ended(DiffusionLab.KNOB_ID)
	if not lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("not judged after the let-go")
	expect.call(problems.is_empty(), "diffusion judging: the cold glass all blue / the hot glass before the cold one beside it / the smell at the nose hit; while it spreads Puppy says wait (after %.0f s); the wrong water says the doc's \"…을 골라 봐!\" line; not judged while the finger is on the dropper" % DiffusionModel.HINT_S,
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the hand -------------------------------------------------------------------------------------

## A press on the dropper's bulb through the shell's Manipulator is a hold (the knob never moves) and a
## new drop; the ink spreads with the physics steps after the let-go; the hand guide taps the bulb.
func check_hold() -> void:
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
	var per_unit := Vector2(view.viewport.size) / view.size
	var problems := []
	var guide := m.guide()
	if guide.get("kind", "") != "tap" or guide.get("id", "") != DiffusionLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	var bulb: Vector3 = lab.props.dropper.global_position
	var at := view.rig.unproject_position(bulb + Vector3(DiffusionProps.BULB * 0.7, 0.0, 0.0)) / per_unit
	var knob: Vector3 = lab.knobs[DiffusionLab.KNOB_ID].global_position
	m.handle_pointer("press", at)
	var model := lab.model as DiffusionModel
	if m.mode != "hold" or not lab.pressing or not model.dropped() or lab.settled():
		problems.append("press on the bulb: mode '%s', pressing %s, dropped %s" % [m.mode, lab.pressing, model.dropped()])
	m.handle_pointer("release", at)
	if m.mode != "" or lab.pressing or lab.knobs[DiffusionLab.KNOB_ID].global_position != knob:
		problems.append("let go: mode '%s', pressing %s" % [m.mode, lab.pressing])
	for i in 90:
		await tree.physics_frame
	if model.ink() <= 0.2 or not lab.settled() or lab.status() != "spreading":
		problems.append("1.5 s after the drop: ink %.2f, %s, settled %s" % [model.ink(), lab.status(), lab.settled()])
	expect.call(problems.is_empty(), "diffusion hand: a press on the dropper's bulb is a new drop (the knob never moves), the ink spreads after the let-go; the hand guide taps the bulb",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the bread cat -------------------------------------------------------------------------------

## On each table the bread cat stands on its crates on the table left of the glass; a press puts both
## its paws on the bulb's sides (where the squeezed bulb is, the arms not stretched past STRETCH_MAX),
## pressing; the let-go takes its paws off (effort 0) and it stands back up. Its crates stand on the
## table's top, inside its ends, clear of the glasses, the loaf's board, the bread box and the cast.
func check_cat_press() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var props: DiffusionProps = lab.props
	var cat := props.cat
	var cast: Dictionary = _definition().cast
	var problems := []
	var seen := []
	for stage in [0, 1, 2]:
		lab.set_game_stage(stage, stage, false)
		await tree.process_frame
		var foot := props.cup.global_position
		var crates := props.cat_stand
		var half := (crates.footprint + Vector2.ONE * CatCrates.CRATE_RIM) * 0.5
		var span := Vector2(cat.global_position.x - half.x, cat.global_position.x + half.x)
		if not crates.visible or absf(crates.global_position.y - KitchenSet.TABLE_TOP) > 1e-4 or absf(crates.scale.y - (cat.global_position.y - KitchenSet.TABLE_TOP)) > 1e-4:
			problems.append("stage %d: the crates are not from the table's top up to the cat" % (stage + 1))
		if span.x < KitchenSet.TABLE_AT.x - KitchenSet.TABLE_SIZE.x * 0.5 or span.y > foot.x - DiffusionProps.CUP_TOP:
			problems.append("stage %d: the crates at x %s, the table's left end %.2f, the glass's rim %.2f" % [stage + 1, str(span), KitchenSet.TABLE_AT.x - KitchenSet.TABLE_SIZE.x * 0.5, foot.x - DiffusionProps.CUP_TOP])
		var others := {"the cold glass": [props.beside.global_position.x, DiffusionProps.CUP_TOP, props.beside.visible],
			"the loaf's board": [props.bread.global_position.x, 0.75, props.bread.visible],
			"the bread box": [DiffusionGame.BOX_AT.x, DiffusionGame.BOX_SIZE.x * 0.5, true]}
		for who: String in cast:
			others[who] = [float(cast[who].at[0]), 0.5, true]
		for what: String in others:
			var o: Array = others[what]
			if o[2] and absf(float(o[0]) - cat.global_position.x) < float(o[1]) + half.x:
				problems.append("stage %d: the cat's crates on %s" % [stage + 1, what])
		lab.hold_started(DiffusionLab.KNOB_ID)
		for i in 30:
			await tree.process_frame
		var bulb: Vector3 = props.dropper.global_position
		var paws := DiffusionProps.paw_points(bulb, cat.global_position, props.shown_squeeze)
		var gap := maxf(cat.hand_point(0).distance_to(paws[0]), cat.hand_point(1).distance_to(paws[1]))
		var reach := maxf(cat.stretch(0), cat.stretch(1))
		if cat.mode != "grab" or props.shown_effort <= 0.0 or props.shown_squeeze <= 0.0 or gap > PAW_GAP or reach > STRETCH_MAX \
				or paws.any(func(p: Vector3) -> bool: return p.distance_to(bulb) > DiffusionProps.BULB + 1e-4):
			problems.append("stage %d pressing: mode %s, effort %.2f, squeeze %.2f, paws %.3f m off the bulb, arms %.2f" % [stage + 1, cat.mode, props.shown_effort, props.shown_squeeze, gap, reach])
		seen.append("lean %.0f deg" % rad_to_deg(cat.lean()))
		lab.hold_ended(DiffusionLab.KNOB_ID)
		if cat.attached() or props.shown_effort != 0.0:
			problems.append("stage %d let go: mode %s, effort %.2f" % [stage + 1, cat.mode, props.shown_effort])
		for i in 40:
			await tree.process_frame
		if cat.mode != "free" or cat.lean() != 0.0 or props.shown_squeeze != 0.0:
			problems.append("stage %d after the let-go: mode %s, squeeze %.2f" % [stage + 1, cat.mode, props.shown_squeeze])
	expect.call(problems.is_empty(), "diffusion bread cat: on its crates on the table beside the glass, both paws squeeze the dropper's bulb while the finger presses (%s, the arms not stretched), off with the let-go (effort 0); its crates clear of the glasses, the loaf, the bread box and the cast" % ", ".join(seen),
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the tables -----------------------------------------------------------------------------------

func check_tables() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var props: DiffusionProps = lab.props
	var want := {0: [false, false], 1: [true, false], 2: [false, true], -1: [false, true]}
	for stage: int in want:
		lab.set_game_stage(stage, maxi(stage, 0) if stage >= 0 else 3, false)
		var site := DiffusionLab.site_of(stage)
		if [props.beside.visible, props.bread.visible] != want[stage] or lab.model.input("site") != site \
				or props.cup.global_position.distance_to(DiffusionProps.cup_point(site)) > 1e-4 \
				or lab.knobs[DiffusionLab.KNOB_ID].global_position.distance_to(DiffusionProps.bulb_point(DiffusionProps.cup_point(site))) > 1e-4:
			problems.append("stage %d: beside %s, bread %s, site %.0f" % [stage, props.beside.visible, props.bread.visible, lab.model.input("site")])
	# A stage just cleared keeps its table (and its result) until the next reset.
	lab.set_game_stage(0, 0, false)
	lab.set_control("water", "cold")
	lab.hold_started(DiffusionLab.KNOB_ID)
	lab.hold_ended(DiffusionLab.KNOB_ID)
	_run(lab.model as DiffusionModel, 12.5)
	lab.set_game_stage(1, 1, true)
	if lab.model.input("site") != DiffusionModel.SINGLE or lab.status() != "full" or props.beside.visible:
		problems.append("the cleared stage's table changed at once (%s)" % lab.status())
	lab.reset_run()
	if lab.model.input("site") != DiffusionModel.PAIR or not props.beside.visible or lab.status() != "ready":
		problems.append("the next stage's table did not come with the reset")
	expect.call(problems.is_empty(), "diffusion tables: stage 1 one glass, stage 2 a cold glass beside it, stage 3 and a finished round the loaf; the dropper over the glass; a stage just cleared keeps its table until the next reset",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the water button -----------------------------------------------------------------------------

func check_condition_button() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	for i in 3:
		var groups := ConditionPicks.groups(definition, i)
		if groups.size() != 1 or groups[0].control != "water" or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	var model := lab.model as DiffusionModel
	if lab.control_value("water") != "cold" or model.is_hot() or lab.props.cup.steam.visible:
		problems.append("the start is not cold water")
	lab.hold_started(DiffusionLab.KNOB_ID)
	lab.hold_ended(DiffusionLab.KNOB_ID)
	var resets := lab.reset_count
	lab.set_control("water", "hot")
	if not model.is_hot() or lab.reset_count != resets + 1 or model.dropped() or not lab.props.cup.steam.visible:
		problems.append("hot: %s, resets %d, dropped %s, steam %s" % [model.is_hot(), lab.reset_count - resets, model.dropped(), lab.props.cup.steam.visible])
	lab.reset_run()
	if not model.is_hot():
		problems.append("다시 lost the water")
	lab.set_control("water", "cold")
	if model.is_hot() or lab.props.cup.steam.visible:
		problems.append("cold again")
	expect.call(problems.is_empty(), "diffusion water button: 찬물 / 뜨거운 물 on every stage; 뜨거운 물 steams the glass and starts the run over; 다시 keeps it",
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
	if ExperimentRegistry.shown_cards(definition, -1) != ["cup"] or ExperimentRegistry.shown_cards(definition, 2) != ["smell"]:
		problems.append("cards %s / %s" % [str(ExperimentRegistry.shown_cards(definition, -1)), str(ExperimentRegistry.shown_cards(definition, 2))])
	var seen := {}
	for stage in [0, 2]:
		lab.set_game_stage(stage, stage, false)
		lab.hold_started(DiffusionLab.KNOB_ID)
		lab.hold_ended(DiffusionLab.KNOB_ID)
		for t: float in [0.0, 0.8, 14.0]:
			_run(lab.model as DiffusionModel, t)
			lab._show()
			for key: String in lab.observations():
				var value: Variant = lab.observations()[key]
				seen[value] = true
				if not value is String or str(value) == "" or digits.search(str(value)) != null:
					problems.append("%s at %.1f s: %s" % [key, t, str(value)])
	if seen.size() < 6:
		problems.append("only %d different words" % seen.size())
	expect.call(problems.is_empty(), "diffusion: no number on the screen (the observations are words, no units; the card is the glass, the smell on stage 3)",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


## The clouds are a picture but stay where the model's spread allows: the ink's lumps in the glass's
## water, swaying, reaching deeper sooner in hot water and growing from the drop's blob; the smell's haze
## along its way, none past its front, only on the bread table after a drop; their colours and the
## glass's draw order (water, cloud, shell, steam). No particles in the scene (2026-11-16 user).
func check_dots() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var props: DiffusionProps = lab.props
	var problems := []
	lab.set_game_stage(2, 2, false)
	lab.set_control("water", "hot")
	lab.hold_started(DiffusionLab.KNOB_ID)
	lab.hold_ended(DiffusionLab.KNOB_ID)
	var box := props.cup.water_box()
	for i in 30:   # 0.5 s: the smell about half way
		await tree.physics_frame
		await tree.process_frame
	var last := props.cup.lump_points.duplicate()
	for i in 10:
		await tree.physics_frame
		await tree.process_frame
	var hot_low := INF
	var moved := 0.0
	for i in GlassCup.CLOUD_LUMPS:
		var p := props.cup.lump_points[i]
		if Vector2(p.x, p.z).length() > box.z + 1e-4 or p.y < box.x - 1e-4 or p.y > box.y + 1e-4:
			problems.append("an ink lump out of the water at %s" % str(p))
		hot_low = minf(hot_low, p.y)
		moved += p.distance_to(last[i])
		var size := props.cup.lump_sizes[i]
		if size.x > (box.z + 0.05) * 1.07 or size.y > (box.y - box.x) / GlassCup.CLOUD_LUMPS * GlassCup.CLOUD_TALL * 1.07:
			problems.append("an ink lump too big %s" % str(size))
	if not props.cup.cloud.visible or moved <= 0.0 or props.cup.lump_sizes[0].x <= GlassCup.CLOUD_START:
		problems.append("the ink cloud shown %s, moved %.3f, top lump %s" % [props.cup.cloud.visible, moved, str(props.cup.lump_sizes[0])])
	var front: float = props.shown_smell
	var nose_gap := props.smell_point(front).distance_to(props.nose)
	for p: Vector3 in props.haze_points:
		if p.distance_to(props.nose) < nose_gap - DiffusionProps.SMELL_SWAY - 1e-3:
			problems.append("the smell's haze past its front (%.2f of the way) at %s" % [front, str(p)])
			break
	if not props.smell_haze.visible or front <= 0.2 or front >= 1.0:
		problems.append("the smell's haze shown %s at %.2f of the way" % [props.smell_haze.visible, front])
	# Cold: the same drop's cloud stays near the top for longer; no bread, no haze.
	lab.set_control("water", "cold")
	lab.set_game_stage(0, 0, false)
	lab.hold_started(DiffusionLab.KNOB_ID)
	lab.hold_ended(DiffusionLab.KNOB_ID)
	for i in 40:
		await tree.physics_frame
		await tree.process_frame
	var cold_low := INF
	for p: Vector3 in props.cup.lump_points:
		cold_low = minf(cold_low, p.y)
	if not (cold_low > hot_low):
		problems.append("the cold glass's lowest lump %.2f is not above the hot one's %.2f" % [cold_low, hot_low])
	if props.smell_haze.visible:
		problems.append("the smell's haze shows without the bread")
	# Colours and the draw order.
	var ink_tint: Vector4 = props.cup.cloud_material.get_shader_parameter("tint")
	var haze_tint: Vector4 = (props.smell_haze.material_override as ShaderMaterial).get_shader_parameter("tint")
	var want_ink := DiffusionProps.INK_CLOUD.srgb_to_linear()
	var want_haze := DiffusionProps.SMELL_HAZE.srgb_to_linear()
	if not ink_tint.is_equal_approx(Vector4(want_ink.r, want_ink.g, want_ink.b, 1.0)) or not haze_tint.is_equal_approx(Vector4(want_haze.r, want_haze.g, want_haze.b, 1.0)):
		problems.append("cloud tints %s, %s" % [str(ink_tint), str(haze_tint)])
	var order := [props.cup.water_material.render_priority, props.cup.cloud_material.render_priority,
		(props.cup.get_node("Shell") as MeshInstance3D).material_override.render_priority,
		(props.cup.get_node("Steam/Wisp0") as MeshInstance3D).material_override.render_priority]
	if order != [GlassCup.WATER_PRIORITY, GlassCup.CLOUD_PRIORITY, GlassCup.SHELL_PRIORITY, GlassCup.STEAM_PRIORITY] \
			or not (order[0] < order[1] and order[1] < order[2] and order[2] < order[3]) \
			or props.smell_haze.material_override.render_priority != GlassCup.CLOUD_PRIORITY:
		problems.append("draw order %s" % str(order))
	expect.call(problems.is_empty(), "diffusion clouds: the ink's cloud sways inside the glass's water and reaches deeper sooner in hot water; the smell's haze goes along its way up to its front only, on the bread table; their colours; the water, cloud, shell and steam draw in that order",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

func check_in_view() -> void:
	var problems := []
	var seen := []
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
		var props: DiffusionProps = lab.props
		for stage in [0, 1, 2]:
			lab.set_game_stage(stage, stage, false)
			var bulb: Vector3 = props.dropper.global_position
			inside.call(at.call(bulb + Vector3.UP * DiffusionProps.BULB * 1.3), "stage %d the bulb's top" % (stage + 1))
			for press: bool in [false, true]:
				if press:
					lab.hold_started(DiffusionLab.KNOB_ID)
				props.cat.advance(0.0)
				var b := props.cat.bounds()
				inside.call(at.call(b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5)), "stage %d the cat's head%s" % [stage + 1, " pressing" if press else ""])
				if press:
					lab.hold_ended(DiffusionLab.KNOB_ID)
					props.cat.stand(props.cat.position)
			for glass: GlassCup in [props.cup, props.beside]:
				if glass.visible:
					for corner: Vector3 in [Vector3(-glass.radius_top, glass.height, 0.0), Vector3(glass.radius_top, glass.height, 0.0), Vector3(-glass.radius_bottom, 0.0, 0.0), Vector3(glass.radius_bottom, 0.0, 0.0)]:
						inside.call(at.call(glass.global_position + corner), "stage %d %s" % [stage + 1, glass.name])
		inside.call(at.call(props.bread.global_position + Vector3(0.0, 0.5, 0.0)), "the loaf")
		inside.call(at.call(props.nose), "Puppy's nose")
		inside.call(at.call(lab.game.box.global_position + Vector3.UP * DiffusionGame.BOX_SIZE.y * 0.5), "the bread box")
		var glass_share: float = (at.call(props.cup.global_position) as Vector2).y - (at.call(props.cup.global_position + Vector3.UP * props.cup.height) as Vector2).y
		if glass_share < GLASS_MIN:
			problems.append("%s: the glass is %.3f of the height" % [str(size), glass_share])
		seen.append("%s glass %.3f of the height" % [str(size), glass_share])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "diffusion in view: the dropper's bulb, the glasses (at least %.1f%% of the height), the bread cat's head, the loaf, Puppy's nose and the bread box between the top band and the bottom %.0f%% (phone, desktop and tablet)" % [GLASS_MIN * 100.0, (1.0 - BOTTOM_FREE) * 100.0],
		"; ".join(problems.slice(0, 5) + seen))


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["ink_cold_first", "ink_hot_first"]
	var pick_kinds := ["water_cold", "water_hot"]
	for kind: String in predict_kinds + pick_kinds + ["particles"]:
		var draw := func() -> void:
			if kind in predict_kinds:
				PredictPictures.draw(canvas, kind)
			elif kind in pick_kinds:
				PickPictures.draw(canvas, kind)
			else:
				ExplainPictures.draw_card(canvas, kind, Rect2(Vector2.ZERO, canvas.size))
			drawn.append(kind)
		canvas.draw.connect(draw)
		canvas.queue_redraw()
		await tree.process_frame
		canvas.draw.disconnect(draw)
	canvas.queue_free()
	var listed := predict_kinds.all(func(k: String) -> bool: return k in PredictPictures.KINDS) \
			and pick_kinds.all(func(k: String) -> bool: return k in PickPictures.KINDS) and "particles" in ExplainPictures.KINDS
	expect.call(listed and drawn == predict_kinds + pick_kinds + ["particles"],
		"diffusion pictures: the question's glasses (PredictPictures), the cold / hot water glasses (PickPictures) and the particles card (ExplainPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var curie := Island.by_id("curie")
	var problems := []
	if str(curie.order[0]) != ID or ExperimentRegistry.find(ID).is_empty():
		problems.append("diffusion is not curie's first spot as an experiment")
	if curie.playable():
		problems.append("the island opened with one lab")
	var own := ArtKit.builder()
	MapLandmarks.add(own, ID, Transform3D())
	var other := ArtKit.builder()
	MapLandmarks.add(other, "no-such-spot", Transform3D())
	if own.vertex_count() <= other.vertex_count():
		problems.append("the map shows the unknown spot's ball on a post")
	expect.call(problems.is_empty(), "diffusion: the curie island's first spot is an experiment with its own map landmark (a glass, the dropper, a loaf); the island stays in the making", "; ".join(problems))


# --- the opening ----------------------------------------------------------------------------------

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
	var first_ok := told == [["yaongi", "worried", ""], ["cat", "thinking", ""], ["puppy", "thinking", ""], ["dugi", "explain", "particles"], ["dugi", "explain", ""]] \
		and round.phase() == MissionRound.Phase.ASKING and Story.keeper_of(definition) == "yaongi" and Story.keeper_of(ExperimentRegistry.find("sea-breeze")) == Story.KEEPER
	var again := MissionRound.new(definition, store)
	again.start()
	again.open(true)
	var later := []
	while again.phase() == MissionRound.Phase.CLUE and later.size() < 8:
		later.append(again.clue_to_open().speaker)
		again.clue_opened()
		again.clue_read()
	Story.enabled = was
	expect.call(first_ok and later == ["dugi", "dugi"],
		"diffusion opening: first visit 야옹이 (the island's keeper, worried), the bread cat (thinking), Puppy's clue, Dugi's two lines (the first with the particles card), then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: DiffusionGame = lab.game
	var problems := []
	if game.piece_state != "held" or game.piece.global_position.distance_to(DiffusionGame.BOX_AT) > 0.05 or game.lid.rotation.x != 0.0:
		problems.append("not shut in the bread box at the start")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or game.lid.rotation.x != 0.0 or game._lamps_lit != 2:
		problems.append("after two stamps: %s, lamps %d" % [game.piece_state, game._lamps_lit])
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 500:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or game.lid.rotation.x > -1.0 or rest.distance_to(lab.props.cat.global_position) > 2.0:
		problems.append("after the last stamp: %s at %s, lid %.2f" % [game.piece_state, str(rest), game.lid.rotation.x])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as DiffusionGame).take_piece() != null or (again.game as DiffusionGame).lid.rotation.x > -1.0:
		problems.append("a finished spot: a piece, or the box shut")
	expect.call(problems.is_empty(), "diffusion piece: shut in the bread box (a lamp a stamp) until the last stamp, then the lid opens and the piece jumps down onto the table in front of the bread cat; a finished spot shows the box open, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
