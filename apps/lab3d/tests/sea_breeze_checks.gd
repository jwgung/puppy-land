## 바닷바람 (#93, 2026-11-07; Hutton Island's sixth spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after seasons), not
##   one of the first island's; the hold rule on the sun; the question's and the condition button's
##   pictures are code-drawn kinds; its Korean lines are docs/islands/hutton-lines.md section 6 word for
##   word (the fox's line, Puppy's two lines, Dugi's two lines with the sea breeze picture on the
##   second, the question, its choices, reason and bridge, the riddle, every stage's condition,
##   mission, explanation, win, miss and wrong-condition line) with the doc's faces; the conditions are
##   hutton-missions.md 6's; Puppy's result lines are short with no science words, digits or symbols;
##   English has every line;
## - the model: the land warms up and cools down much faster than the sea (the same sun, the same
##   wait); the wind blows from the cooler side to the warmer one and grows with the difference; the
##   breeze and the strong breeze come after a short and a longer press; the night's land cools past the
##   sea by itself (the land breeze) and no press warms it; the day never makes a land breeze;
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's miss line), the
##   wrong condition's line, nothing while the sun is pressed;
## - the hand: a press on the sun holds it (nothing moves), the coast warms while it is held and the
##   let-go is judged; the hand guide presses it;
## - the condition button: 낮 / 밤 (picture buttons on every stage) set the time, start the run over,
##   bring out the moon and the stars; 다시 keeps it;
## - no number on the screen: the observations are words, no units, the card is the wind; the
##   thermometers and the arrows follow the model;
## - what matters is big and in view: the sun (the press target), the thermometers, the pinwheel and
##   the two boats on the phone, the desktop and the tablet, clear of the top band and the bottom;
## - the spot: the hutton map's sea-breeze spot is this experiment, the island is still not playable;
## - the opening (the fox first, Puppy's two lines) and the piece (on the sailing boat until the last
##   stamp, the fishing boat out at the second).
extends RefCounted

const ID := "sea-breeze"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
## The phone (2340 x 1080) and the tablet (1920 x 1200) in UI units at the same height.
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
## A desktop window (1920 x 1080).
const DESKTOP := Vector2(1280, 720)
## In view: inside this margin of the view's sides and top, above the bottom share the dialogue box
## and the buttons take; under the top band on the left (the title, the key card and the mission
## strip: TOP_FREE of the height over the left LEFT_BAND of a tablet's width).
const EDGE := 0.03
const BOTTOM_FREE := 0.8
const TOP_FREE := 0.38
const LEFT_BAND := 680.0
## The sun: its disc at least SUN_MIN of the view's height across (a big target on a phone).
const SUN_MIN := 0.12
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
	check_warming()
	check_night()
	check_wind()
	await check_judging()
	await check_hold()
	await check_condition_button()
	await check_no_numbers()
	await check_in_view()
	check_spot()
	await check_pictures()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> SeaBreezeLab:
	var lab := SeaBreezeLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## Steps `model` for `seconds` at the lab's fixed step.
static func _run(model: SeaBreezeModel, seconds: float) -> void:
	for k in int(round(seconds / STEP)):
		model.step(STEP)


## Seconds of `model` until its status is `status` (stepping; INF past `limit`).
static func _time_to(model: SeaBreezeModel, status: String, limit := 60.0) -> float:
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
		expect.call(false, "sea breeze: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or island.find(ID) < island.find("seasons"):
		problems.append("hutton's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var objects: Array = definition.manipulation.objects
	if objects.size() != 1 or objects[0].id != SeaBreezeLab.KNOB_ID or not objects[0].get("hold", false):
		problems.append("the sun is not a hold object: %s" % str(objects))
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var picks: Array = definition.kid.picks.time
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["day", "night"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the time buttons %s" % str(picks))
	expect.call(problems.is_empty(), "sea breeze: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; the sun is pressed and held; code-drawn question and day / night pictures",
		"; ".join(problems))


## The section "## 6. 바닷바람" of the lines doc: its numbered lines [who, face, text, picture] (the
## text without its "[그림: …]"), the question, the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 6. 바닷바람")
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
	var who := {"여우": Story.KEEPER, "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition)
	if doc.lines.size() != 5 or opening.size() != 5:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 5:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			var picture := "sea_breeze" if want[3] else ""
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != want[2] or str(got.get("picture", "")) != picture:
				problems.append("line %d: %s/%s '%s' %s (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(got.get("picture", "")), str(want)])
	var predict := MissionRound.predict(definition)
	var q: Dictionary = doc.question
	var labels: Array = predict.choices.map(func(c: Dictionary) -> String: return str(c.label))
	var answer: int = predict.choices.map(func(c: Dictionary) -> String: return str(c.id)).find(str(predict.answer))
	if predict.question != q.get("text") or predict.get("question_face") != faces.get(q.get("face")) or labels != q.get("choices") \
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[0] != "바다에서 땅으로":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.time:
		pick_label[p.value] = p.label
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), str(pick_label.get(stage.conditions.time, "?")), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "sea breeze: the Korean lines are hutton-lines.md 6 word for word (the fox, Puppy's two lines, Dugi's two with the sea breeze picture, the question, the riddle, the three stages with their conditions and wrong-condition lines) with its faces",
		"; ".join(problems))


## hutton-missions.md 6: the conditions 낮 / 밤 / 낮 and the time button 때 — 낮 / 밤.
func check_missions_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 6. 바닷바람")
	var section := text.substr(start, text.find("\n### ", start + 4) - start)
	var rows := []
	for raw in section.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges())[1])
	var labels := {}
	for p: Dictionary in _definition().kid.picks.time:
		labels[p.value] = p.label
	var got: Array = _definition().missions.stages.map(func(s: Dictionary) -> String: return str(labels.get(s.conditions.time, "?")))
	expect.call(start >= 0 and section.contains("**조건 단추**: 때 — 낮 / 밤") and rows == got and got == ["낮", "밤", "낮"],
		"sea breeze: the stages' conditions are hutton-missions.md 6's (낮, 밤, 낮; the button 때 — 낮 / 밤)", "%s / %s" % [str(rows), str(got)])


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
	for line: String in [Story.keeper(definition), Story.clue(definition), Story.clue_more(definition), Story.map_clue(definition)]:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/sea-breeze.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/sea-breeze.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.story.get("clue_more", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.time.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "sea breeze: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

## The same sun on both: the land warms up much faster than the sea and cools down much faster after;
## a short press makes a breeze, a longer one a strong breeze (the same press, a bigger difference);
## a let-go day never turns into a land breeze.
func check_warming() -> void:
	var problems := []
	var model := SeaBreezeModel.new()
	if model.status() != "calm" or model.animating() or model.wind() != 0.0:
		problems.append("the start: %s, animating %s" % [model.status(), model.animating()])
	model.set_sun(true)
	var breeze := _time_to(model, "sea_breeze")
	var strong := breeze + _time_to(model, "strong")
	model.reset()
	model.set_sun(true)
	_run(model, 2.0)
	var land := model.input("land") - SeaBreezeModel.DAY_START
	var sea := model.input("sea") - SeaBreezeModel.DAY_START
	if not (land > 0.0 and sea > 0.0 and land > sea * 8.0):
		problems.append("after 2 s of sun the land is up %.2f, the sea %.2f" % [land, sea])
	_run(model, 3.0)
	model.set_sun(false)
	var hot := Vector2(model.input("land"), model.input("sea"))
	_run(model, 2.0)
	var land_drop := hot.x - model.input("land")
	var sea_drop := hot.y - model.input("sea")
	if not (land_drop > 0.0 and land_drop > sea_drop * 8.0):
		problems.append("2 s after the let-go the land is down %.2f, the sea %.2f" % [land_drop, sea_drop])
	var lowest := INF
	for k in 3000:   # 50 s: the day cools back without a land breeze
		model.step(STEP)
		lowest = minf(lowest, model.difference())
	if lowest <= -SeaBreezeModel.BREEZE_DIFF or model.status() != "calm":
		problems.append("the day turned to %s (land minus sea down to %.2f)" % [model.status(), lowest])
	if not (breeze > 0.6 and breeze < 2.0 and strong > breeze + 1.2 and strong < 6.0):
		problems.append("a breeze after %.2f s, a strong one after %.2f s of sun" % [breeze, strong])
	expect.call(problems.is_empty() and SeaBreezeModel.LAND_TAU * 5.0 <= SeaBreezeModel.SEA_TAU,
		"sea breeze model: the land warms up and cools down far faster than the sea under the same sun; a breeze after %.1f s of pressing, a strong one after %.1f s; a let-go day cools back without a land breeze" % [breeze, strong],
		"; ".join(problems))


## The night: no press warms the coast; it starts in the evening (no wind to speak of) and the land
## cools past the sea by itself in a few seconds (the land breeze).
func check_night() -> void:
	var problems := []
	var model := SeaBreezeModel.new()
	model.set_night(true)
	model.reset()
	if model.status() != "calm" or model.difference() <= 0.0 or not model.animating():
		problems.append("the evening: %s, land minus sea %.2f" % [model.status(), model.difference()])
	model.set_sun(true)
	if model.heating():
		problems.append("the moon warms the coast")
	var t := _time_to(model, "land_breeze")
	if not (t > 2.0 and t < 8.0):
		problems.append("a land breeze after %.2f s" % t)
	_run(model, 30.0)
	if model.status() != "land_breeze" or model.wind() >= 0.0 or model.input("land") >= model.input("sea"):
		problems.append("the night's end: %s, wind %.2f" % [model.status(), model.wind()])
	model.set_night(false)
	if model.is_night() or model.input("land") != SeaBreezeModel.DAY_START or model.input("sea") != SeaBreezeModel.DAY_START:
		problems.append("back to day: night %s, land %.1f" % [model.is_night(), model.input("land")])
	expect.call(problems.is_empty(), "sea breeze model: at night nothing warms the coast; the evening is calm and the land cools past the sea by itself in %.1f s (the land breeze)" % t,
		"; ".join(problems))


## The wind blows from the cooler side to the warmer one, the stronger the bigger the difference;
## the statuses follow the difference's bands.
func check_wind() -> void:
	var problems := []
	var model := SeaBreezeModel.new()
	var last := -INF
	for k in 41:
		var d := -16.0 + 0.8 * k
		model.set_input("land", SeaBreezeModel.DAY_START + d)
		var w := model.wind()
		if w <= last or signf(w) != signf(d):
			problems.append("difference %.1f: wind %.2f" % [d, w])
		last = w
		var want := "strong" if d >= SeaBreezeModel.STRONG_DIFF else "sea_breeze" if d >= SeaBreezeModel.BREEZE_DIFF \
			else "land_breeze" if d <= -SeaBreezeModel.BREEZE_DIFF else "calm"
		if model.status() != want:
			problems.append("difference %.1f is %s (want %s)" % [d, model.status(), want])
	expect.call(problems.is_empty() and SeaBreezeModel.STRONG_DIFF > SeaBreezeModel.BREEZE_DIFF,
		"sea breeze model: the wind blows from the cooler side to the warmer one, growing with the difference; calm under %.0f °C, a breeze from %.0f °C, a strong sea breeze from %.0f °C" % [SeaBreezeModel.BREEZE_DIFF, SeaBreezeModel.BREEZE_DIFF, SeaBreezeModel.STRONG_DIFF],
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, time, land minus sea (°C), hit, missed]
	var cases := [
		[0, "day", 5.0, true, false], [0, "day", 12.0, true, false], [0, "day", 3.0, false, true], [0, "day", 0.0, false, true],
		[0, "night", 5.0, false, false], [0, "night", -6.0, false, true],
		[1, "night", -5.0, true, false], [1, "night", -2.0, false, true], [1, "night", 2.0, false, true],
		[1, "day", -5.0, false, false], [1, "day", 5.0, false, true],
		[2, "day", 10.0, true, false], [2, "day", 7.0, false, true], [2, "day", 1.0, false, true], [2, "night", 10.0, false, false],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_control("time", case[1])
		lab.model.set_input("land", lab.model.input("sea") + float(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s at %+.0f (%s): stamps %d missed %s" % [stage + 1, case[1], float(case[2]), status, stamps, missed])
	var wants := [["day", "낮을 골라 봐!"], ["night", "밤을 골라 봐!"], ["day", "낮을 골라 봐!"]]
	for i in 3:
		lab.set_control("time", "night" if wants[i][0] == "day" else "day")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong condition says '%s'" % [i + 1, line[0]])
	lab.set_control("time", "day")
	lab.hold_started(SeaBreezeLab.KNOB_ID)
	lab.model.set_input("land", lab.model.input("sea") + 10.0)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the sun is pressed")
	lab.hold_ended(SeaBreezeLab.KNOB_ID)
	if not lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("not judged at the let-go")
	expect.call(problems.is_empty(), "sea breeze judging: the sea breeze / the night's land breeze / the strong sea breeze hit, the weaker winds miss (Puppy's line), the wrong time says the doc's \"…을 골라 봐!\" line; not judged while the sun is pressed, judged at the let-go",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the hand -------------------------------------------------------------------------------------

## A press on the sun holds it through the shell's Manipulator (nothing moves under the finger): the
## coast warms while it is held (the physics steps), the let-go cools it again; the hand guide presses.
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
	if guide.get("kind", "") != "hold" or guide.get("id", "") != SeaBreezeLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	# A press on the sun's rim (not its middle) holds it.
	var at := view.rig.unproject_position(SeaBreezeProps.SUN_AT + Vector3(SeaBreezeProps.SUN_RADIUS * 0.8, 0.0, 0.0)) / per_unit
	var knob: Vector3 = lab.knobs[SeaBreezeLab.KNOB_ID].global_position
	m.handle_pointer("press", at)
	if m.mode != "hold" or not lab.pressing or lab.settled() or not lab.props.beams.visible:
		problems.append("press on the sun: mode '%s', pressing %s" % [m.mode, lab.pressing])
	var held := 0
	while lab.status() != "strong" and held < 600:
		await tree.physics_frame
		held += 1
	if lab.status() != "strong" or lab.knobs[SeaBreezeLab.KNOB_ID].global_position != knob or lab.settled():
		problems.append("held %d steps: %s" % [held, lab.status()])
	m.handle_pointer("release", at)
	var warm: float = lab.model.input("land")
	if m.mode != "" or lab.pressing or not lab.settled() or lab.props.beams.visible:
		problems.append("let go: mode '%s', pressing %s" % [m.mode, lab.pressing])
	for i in 60:
		await tree.physics_frame
	if lab.model.input("land") >= warm - 1.0:
		problems.append("the land did not cool after the let-go (%.2f -> %.2f)" % [warm, lab.model.input("land")])
	expect.call(problems.is_empty(), "sea breeze hand: a press on the sun holds it (the knob never moves), the coast warms to a strong sea breeze in %.1f s of holding, the let-go stops the sunbeams and the land cools; the hand guide presses the sun" % (held / 60.0),
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the condition button -------------------------------------------------------------------------

func check_condition_button() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	for i in 3:
		var groups := ConditionPicks.groups(definition, i)
		if groups.size() != 1 or groups[0].control != "time" or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	if lab.control_value("time") != "day" or lab.model.is_night() or not lab.props.sun_ball.visible or lab.props.moon.visible:
		problems.append("the start is not the day")
	lab.model.set_input("land", 30.0)
	var resets := lab.reset_count
	lab.set_control("time", "night")
	if not lab.model.is_night() or lab.reset_count != resets + 1 or lab.model.input("land") != SeaBreezeModel.EVENING_LAND \
			or not lab.props.moon.visible or lab.props.sun_ball.visible or not lab.props.stars.visible:
		problems.append("night: %s, land %.1f, moon %s" % [lab.model.is_night(), lab.model.input("land"), lab.props.moon.visible])
	lab.reset_run()
	if not lab.model.is_night():
		problems.append("다시 lost the condition")
	lab.set_control("time", "day")
	if lab.model.is_night() or lab.props.moon.visible or lab.model.input("land") != SeaBreezeModel.DAY_START:
		problems.append("day again")
	expect.call(problems.is_empty(), "sea breeze condition button: 낮 / 밤 on every stage; 밤 brings the moon and the stars and starts the run over in the evening, 낮 the sun; 다시 keeps it",
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
	if ExperimentRegistry.shown_cards(definition, -1) != ["state"]:
		problems.append("cards %s" % str(ExperimentRegistry.shown_cards(definition, -1)))
	var shown := {}
	for d: float in [0.0, 6.0, 12.0, -6.0]:
		lab.model.set_input("land", lab.model.input("sea") + d)
		lab._show()
		shown[d] = [lab.props.shown_land, lab.props.shown_sea, lab.props.shown_wind, lab.props.shown_length]
		for key: String in lab.observations():
			var value: Variant = lab.observations()[key]
			if not value is String or str(value) == "" or digits.search(str(value)) != null:
				problems.append("%s at %+.0f: %s" % [key, d, str(value)])
	lab.model.set_input("land", lab.model.input("sea"))
	lab._show()
	if shown[0.0][3] != 0.0 or lab.props.arrows.any(func(a: Node3D) -> bool: return a.visible) or lab.props.rise.visible:
		problems.append("arrows when calm")
	if not (shown[6.0][0] > shown[6.0][1] and shown[6.0][2] > 0.0 and shown[12.0][3] > shown[6.0][3] and shown[-6.0][0] < shown[-6.0][1] and shown[-6.0][2] < 0.0):
		problems.append("thermometers / wind %s" % str(shown))
	expect.call(problems.is_empty(), "sea breeze: no number on the screen (the observations are words, no units, the card is the wind); the land's thermometer is higher when the land is warmer, the arrows point from the cooler side, longer with a bigger difference, none when calm",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

## What matters is big and in the clear on the phone's, the desktop's and the tablet's front view: the
## sun (the press target) at least SUN_MIN of the height across, inside the view and clear of the top
## band on the left (the title, the card, the mission strip: TOP_FREE of the height over LEFT_BAND
## units) and of the bottom (BOTTOM_FREE: the dialogue box, the buttons); the thermometers' boards,
## the pinwheel, the fishing boat and the sailing boat with the piece inside the view, under the top
## band and over the bottom.
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
		var props: SeaBreezeProps = lab.props
		var sun: Vector2 = at.call(SeaBreezeProps.SUN_AT)
		var r := SeaBreezeProps.SUN_RADIUS * (1.0 + 0.55)   # with its rays
		var across: float = (at.call(SeaBreezeProps.SUN_AT + Vector3.DOWN * r) as Vector2).y - (at.call(SeaBreezeProps.SUN_AT + Vector3.UP * r) as Vector2).y
		for d: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
			inside.call(at.call(SeaBreezeProps.SUN_AT + d * r), "the sun's rim")
		if across < SUN_MIN:
			problems.append("%s: the sun is %.2f of the height across" % [str(size), across])
		for thermo: Node3D in [props.land_fill.get_parent(), props.sea_fill.get_parent()]:
			for y: float in [0.0, SeaBreezeProps.BOARD.y]:
				for x: float in [-SeaBreezeProps.BOARD.x * 0.5, SeaBreezeProps.BOARD.x * 0.5]:
					inside.call(at.call(thermo.global_position + Vector3(x, y, 0.0)), thermo.name)
		inside.call(at.call(props.pinwheel.global_position + Vector3.UP * SeaBreezeProps.BLADE), "the pinwheel's top")
		inside.call(at.call(props.pinwheel.global_position - Vector3(0.0, SeaBreezeProps.POLE_H, 0.0)), "the pinwheel's foot")
		for boat: Node3D in [props.fishing, props.sailing]:
			inside.call(at.call(boat.global_position + Vector3(0.0, -0.2, 0.0)), boat.name + " (waterline)")
			inside.call(at.call(boat.global_position + Vector3(0.0, 2.0 * boat.scale.y, 0.0)), boat.name + " (top)")
		inside.call(at.call(lab.game.piece.global_position), "the piece")
		seen.append("%s sun at %s, %.2f across" % [str(size), str(sun), across])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "sea breeze in view: the sun (%.0f%% of the height or more across) right of the top band, the thermometers, the pinwheel, both boats and the piece between the top band and the bottom %.0f%% (phone, desktop and tablet)" % [SUN_MIN * 100.0, (1.0 - BOTTOM_FREE) * 100.0],
		"; ".join(problems.slice(0, 5) + seen))


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["breeze_from_sea", "breeze_from_land"]
	var pick_kinds := ["coast_day", "coast_night"]
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
	var listed := predict_kinds.all(func(k: String) -> bool: return k in PredictPictures.KINDS) \
			and pick_kinds.all(func(k: String) -> bool: return k in PickPictures.KINDS) and "sea_breeze" in ExplainPictures.KINDS
	expect.call(listed and drawn == predict_kinds + pick_kinds,
		"sea breeze pictures: the question's wind kinds (PredictPictures) and the day / night coast kinds (PickPictures) are listed and draw; the explanation card sea_breeze exists",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[5]) != ID:
		problems.append("sea-breeze is not hutton's sixth spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if hutton.playable():
		problems.append("hutton is playable before all its spots are labs")
	expect.call(problems.is_empty(), "sea breeze: Hutton Island's sixth spot is an experiment (a lab on its map); the island is not playable until every spot is", "; ".join(problems))


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
	var first_ok := told == [[Story.KEEPER, "worried", ""], ["puppy", "worried", ""], ["puppy", "thinking", ""], ["dugi", "explain", ""], ["dugi", "explain", "sea_breeze"]] \
		and round.phase() == MissionRound.Phase.ASKING
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
		"sea breeze opening: first visit the fox (worried), Puppy's two lines (worried, thinking), Dugi's two lines (the second with the sea breeze card), then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: SeaBreezeGame = lab.game
	var props: SeaBreezeProps = lab.props
	var problems := []
	var start: Vector3 = game.piece.global_position
	var fishing_at: Vector3 = props.fishing.global_position
	var sailing_at: Vector3 = props.sailing.global_position
	if game.piece_state != "held" or not game.piece.visible or start.distance_to(props.deck_point()) > 0.05:
		problems.append("not on the sailing boat's deck at the start")
	game.show_stage(1, 1, true)
	for i in 30:
		await tree.process_frame
	if props.spin_boost <= 0.0 or game.piece_state != "held":
		problems.append("no whirl after the first stamp (or the piece left)")
	game.show_stage(2, 2, true)
	for i in 200:
		await tree.process_frame
	if props.fishing.global_position.x < fishing_at.x + 8.0 or game.piece_state != "held" or props.sailing.global_position.distance_to(sailing_at) > 0.2:
		problems.append("after the night: fishing boat at %s, the piece %s" % [str(props.fishing.global_position), game.piece_state])
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 500:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or props.sailing.global_position.x > SeaBreezeProps.SHORE_X + 3.5 or absf(rest.y - LabGame.PIECE_SIZE) > 0.12 \
			or rest.x > SeaBreezeProps.SHORE_X:
		problems.append("after the last stamp: %s at %s, the sailing boat at %s" % [game.piece_state, str(rest), str(props.sailing.global_position)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	var p2: SeaBreezeProps = again.props
	if (again.game as SeaBreezeGame).take_piece() != null or p2.sailing.global_position.x > SeaBreezeProps.SHORE_X + 3.5 or p2.fishing.global_position.x < fishing_at.x + 8.0:
		problems.append("a finished spot: a piece, or the boats where they started")
	expect.call(problems.is_empty(), "sea breeze piece: the piece rides the sailing boat until the last stamp (the pinwheel whirls at the first, the fishing boat goes out at the second), then the boat comes in and the piece jumps onto the sand for the cat; a finished spot shows both boats moved, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
