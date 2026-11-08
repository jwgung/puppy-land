## 화산 (#98, 2026-11-07; Hutton Island's last spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after seasons), not
##   one of the first island's; no explanation picture (hutton-lines.md 11 has no "[그림: …]"); the
##   question's and the condition buttons' pictures are code-drawn kinds; its Korean lines are
##   docs/islands/hutton-lines.md section 11 word for word (the fox, Puppy's clue and the talk after it,
##   Dugi's two lines, the question, its choices, reason and bridge, the riddle, every stage's
##   condition, mission, explanation, win, miss and wrong-condition line) with the doc's faces; the
##   stages' conditions are hutton-missions.md 11's; Puppy's result lines are short with no science
##   words, digits or symbols; English has every line;
## - the rules (hutton.md "시뮬레이션": no formula, the textbook's relations): with the same lava a
##   stickier one reaches less far and stands taller, more lava reaches farther and stands taller;
##   only runny lava makes the wide mountain, only sticky lava the tall one; on the big volcano sticky
##   magma plugs, runny lava spreads thin and stops before the sea, normal lava reaches the sea at
##   SEA_SHARE of a full pump and not before;
## - the pump (press and hold): the press time sets the amount (fixed steps, PUMP_S for a full pump),
##   nothing is judged while the finger holds, the lava finishes after the finger lets go and the run
##   settles, a new press starts a new eruption; through the Manipulator a press on the pump holds it;
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's miss line), the
##   wrong magma's line;
## - the condition button: 묽은 / 보통 / 끈적한 on every stage set the magma and start the run over;
## - the site: stages 1 and 2 on the model, stage 3 and a finished round on the big volcano at night
##   (a stage just cleared keeps its result until the next reset); the goals on the sand per stage;
## - no number on the screen: the observations are words, no units, the card is what the lava made;
## - what matters is big and in view on the phone, the desktop and the tablet: the pump's button, the
##   table's lava (the widest and the tallest cone) and its goals, the big volcano's crater and stream,
##   the sea's new land and the risen needle;
## - the spot: the hutton map's volcano spot is this experiment, the island is still not playable;
## - the opening (the fox, Puppy's clue and the talk after it, Dugi's two lines) and the piece (the
##   needle in the crater, pushed up in the big scene, the piece out to the cat).
extends RefCounted

const ID := "volcano"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
## In view: inside EDGE of the sides, under TOP_FREE (the title, the card, the mission strip on the
## left) or, right of RIGHT_UNITS UI units (the end of stage 3's long mission strip, about 820 units
## from the left), under TOP_RIGHT (only the 자세히 button there), above BOTTOM_FREE (the dialogue box
## and the buttons).
const EDGE := 0.03
const TOP_FREE := 0.33
const RIGHT_UNITS := 840.0
const TOP_RIGHT := 0.12
const BOTTOM_FREE := 0.8
## The pump's button at least this share of the view's height across (a finger target on a phone).
const BUTTON_MIN := 0.05
## The big volcano on the screen (2026-11-07 user: too small and far on the phone): its foot to its
## crater, the sticky plug over the crater and the risen needle's blade, shares of the height at least.
const VOLCANO_MIN := 0.3
const PLUG_MIN := 0.04
const BLADE_MIN := 0.02
const LINE_MAX := 24
## A press of this long (s) on each magma, and the statuses it comes to on the model.
const STEP_HZ := 60

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
	check_mission_doc()
	check_result_lines()
	check_rules()
	check_big_rules()
	await check_pump()
	await check_judging()
	await check_condition_button()
	await check_site()
	await check_no_numbers()
	await check_in_view()
	await check_backdrop()
	check_spot()
	await check_pictures()
	check_opening()
	await check_hand()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> VolcanoLab:
	var lab := VolcanoLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## The lab's lava as if `share` of a full pump came out (no press: the model only).
static func _pour(lab: VolcanoLab, share: float) -> void:
	lab.model.set_input("magma", share)
	lab.model.set_input("lava", share)
	lab._show()


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "volcano: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or island.find(ID) < island.find("seasons"):
		problems.append("hutton's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var kid: Dictionary = definition.kid
	if kid.has("intro_picture") or kid.intro_more.any(func(l: Dictionary) -> bool: return l.has("picture")) \
			or definition.missions.stages.any(func(s: Dictionary) -> bool: return s.has("say_picture")):
		problems.append("an explanation picture (the doc has none)")
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var picks: Array = kid.picks.magma
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != VolcanoModel.KINDS \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the magma buttons %s" % str(picks))
	var hold: Array = definition.manipulation.objects
	if hold.size() != 1 or hold[0].id != VolcanoLab.KNOB_ID or hold[0].get("hold") != true:
		problems.append("the pump is not a hold object: %s" % str(hold))
	expect.call(problems.is_empty(), "volcano: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; no explanation picture (none in the doc); code-drawn question and magma pictures; the pump is pressed and held",
		"; ".join(problems))


## The section "## 11. 화산" of the lines doc: its numbered lines [who, face, text], the question, the
## riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 11. 화산")
	var end := text.find("\n## ", start + 4)
	if end < 0:
		end = text.length()
	var out := {"lines": [], "rows": [], "question": {}, "pictures": 0}
	if start < 0:
		return out
	var said := RegEx.create_from_string("^\\d+\\. (\\S+)\\((\\S+)\\): (.+)$")
	var asked := RegEx.create_from_string("^\\d+\\. 질문\\((\\S+), (\\S+)\\): (.+)$")
	for raw in text.substr(start, end - start).split("\n"):
		var line := raw.strip_edges()
		if line.contains("[그림:"):
			out.pictures += 1
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
	var faces := {"걱정": "worried", "생각": "thinking", "설명": "explain", "기쁨": "happy", "놀람": "surprised"}
	var who := {"여우": Story.KEEPER, "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition)
	if doc.lines.size() != 7 or opening.size() != 7:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 7:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != want[2] or str(got.get("picture", "")) != "":
				problems.append("line %d: %s/%s '%s' (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(want)])
	if doc.pictures != 0:
		problems.append("the doc has %d pictures now: add them" % doc.pictures)
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
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.magma:
		pick_label[p.value] = p.label
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), str(pick_label.get(stage.conditions.magma, "?")), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "volcano: the Korean lines are hutton-lines.md 11 word for word (the fox, Puppy's clue and the talk after it, Dugi's two lines, the question, the riddle, the three stages with their magma and wrong-magma lines) with its faces",
		"; ".join(problems))


## The missions doc's section 11: the condition of each stage (묽은 / 끈적한 / 보통) is the stage's.
func check_mission_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 11. 화산")
	var end := text.find("\n## ", start + 4)
	var rows := []
	for raw in text.substr(start, end - start).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges()))
	var names := {"묽은": "runny", "보통": "normal", "끈적한": "sticky"}
	var got: Array = _definition().missions.stages.map(func(s: Dictionary) -> String: return str(s.conditions.magma))
	var want: Array = rows.map(func(r: Array) -> String: return str(names.get(r[1], "?")))
	expect.call(start >= 0 and want == got and got == ["runny", "sticky", "normal"],
		"volcano: the stages' magma is hutton-missions.md 11's (묽은, 끈적한, 보통)", "%s (doc %s)" % [str(got), str(want)])


func check_result_lines() -> void:
	var problems := []
	var science := Story.science_words()
	var symbols := RegEx.create_from_string("[0-9%=+×/<>]")
	for stage: Dictionary in _definition().missions.stages:
		for key: String in ["win", "miss", "miss_conditions"]:
			var line := str(stage.get(key, ""))
			if line == "" or line.length() > LINE_MAX or symbols.search(line) != null or science.any(func(w: String) -> bool: return line.contains(w)):
				problems.append("%s '%s'" % [key, line])
	var told: Array = [Story.keeper(_definition()), Story.clue(_definition()), Story.map_clue(_definition())]
	told.append_array(Story.more(_definition()).map(func(l: Dictionary) -> String: return str(l.text)))
	for line: String in told:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/volcano.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/volcano.json")
	var en: Dictionary = Locale.overlay(raw, english)
	var en_more := Story.more(en)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en_more.size() != 3 or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.magma.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "volcano: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the rules ------------------------------------------------------------------------------------

## The small model's cone: the textbook's relations at every amount (stickier: less far, taller; more
## lava: farther, taller), and what each magma can make.
func check_rules() -> void:
	var problems := []
	var model := VolcanoModel.new()
	if model.status() != "ready":
		problems.append("the start is %s" % model.status())
	var made := {"runny": {}, "normal": {}, "sticky": {}}
	for step in range(1, 101):
		var share := step / 100.0
		for k in 3:
			var s := float(k)
			if k < 2 and not (VolcanoModel.reach_of(share, s) > VolcanoModel.reach_of(share, s + 1.0) and VolcanoModel.height_of(share, s) < VolcanoModel.height_of(share, s + 1.0)):
				problems.append("%.2f: magma %d is not farther and lower than %d" % [share, k, k + 1])
			if step > 1 and not (VolcanoModel.reach_of(share, s) > VolcanoModel.reach_of(share - 0.01, s) and VolcanoModel.height_of(share, s) > VolcanoModel.height_of(share - 0.01, s)):
				problems.append("%.2f: more magma %d is not farther and taller" % [share, k])
			model.set_start("stickiness", s)
			model.set_input("lava", share)
			made[VolcanoModel.KINDS[k]][model.status()] = true
	if not (made.runny.has("wide") and not made.runny.has("tall")) or not (made.sticky.has("tall") and not made.sticky.has("wide")) \
			or made.normal.has("wide") or made.normal.has("tall"):
		problems.append("made %s" % str(made))
	# Slope: the cone's height over its reach is its magma's slope.
	for k in 3:
		var slope := rad_to_deg(atan(VolcanoModel.height_of(0.5, float(k)) / VolcanoModel.reach_of(0.5, float(k))))
		if absf(slope - float(VolcanoModel.SLOPE_DEG[k])) > 1e-6:
			problems.append("magma %d piles at %.2f deg" % [k, slope])
	# The press time a stage takes (s): a child-sized hold, under a full pump.
	var wide_s := pow(VolcanoModel.REACH_WIDE / VolcanoModel.reach_of(1.0, VolcanoModel.RUNNY), 3.0) * VolcanoModel.PUMP_S
	var tall_s := pow(VolcanoModel.TALL_MIN / VolcanoModel.height_of(1.0, VolcanoModel.STICKY), 3.0) * VolcanoModel.PUMP_S
	if wide_s < 1.0 or wide_s > 3.0 or tall_s < 1.0 or tall_s > 3.0:
		problems.append("presses %.2f s (wide), %.2f s (tall)" % [wide_s, tall_s])
	expect.call(problems.is_empty() and VolcanoModel.SLOPE_DEG[0] < VolcanoModel.SLOPE_DEG[1] and VolcanoModel.SLOPE_DEG[1] < VolcanoModel.SLOPE_DEG[2],
		"volcano rules (small model): with the same lava a stickier one reaches less far and stands taller, more lava farther and taller (every 1%%); only runny lava makes the wide mountain (%.1f m, under %.1f m), only sticky the tall one (%.1f m); a stage takes about %.1f / %.1f s of pressing" % [VolcanoModel.REACH_WIDE, VolcanoModel.LOW_MAX, VolcanoModel.TALL_MIN, wide_s, tall_s],
		"; ".join(problems.slice(0, 6)))


## The big volcano (hutton.md: too runny only runs off, too sticky plugs and bubbles): sticky plugs at
## any amount, runny spreads thin and never reaches the sea, normal reaches it at SEA_SHARE and not
## before; nothing out is "ready".
func check_big_rules() -> void:
	var problems := []
	var model := VolcanoModel.new()
	model.set_start("site", VolcanoModel.BIG)
	for step in range(0, 101):
		var share := step / 100.0
		for k in 3:
			model.set_start("stickiness", float(k))
			model.set_input("lava", share)
			var want := "ready"
			if share > 0.0:
				want = ["thin", "sea" if share >= VolcanoModel.SEA_SHARE - 1e-9 else "short", "plugged"][k]
			if model.status() != want:
				problems.append("%s at %.2f: %s (want %s)" % [VolcanoModel.KINDS[k], share, model.status(), want])
			if k == 0 and model.front() > VolcanoModel.THIN_STOP + 1e-9:
				problems.append("runny front %.2f" % model.front())
	expect.call(problems.is_empty() and VolcanoModel.THIN_STOP < 1.0,
		"volcano rules (big volcano): sticky magma plugs the crater, runny lava spreads thin and stops before the sea (%.0f%% of the way), normal lava reaches the sea at %.0f%% of a full pump and not before" % [VolcanoModel.THIN_STOP * 100.0, VolcanoModel.SEA_SHARE * 100.0],
		"; ".join(problems.slice(0, 6)))


# --- the pump ---------------------------------------------------------------------------------------

## Presses of `seconds` on the lab's pump (physics steps, as the finger's hold), then waits until the
## lava has finished; returns [the share pumped, the status, settled while held, steps to settle].
func _press(lab: VolcanoLab, seconds: float) -> Array:
	lab.hold_started(VolcanoLab.KNOB_ID)
	var settled_held := false
	for i in roundi(seconds * STEP_HZ):
		await tree.physics_frame
		settled_held = settled_held or lab.settled()
	lab.hold_ended(VolcanoLab.KNOB_ID)
	var share := lab.pumped
	var steps := 0
	while not lab.settled() and steps < 600:
		await tree.physics_frame
		steps += 1
	return [share, lab.status(), settled_held, steps]


func check_pump() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	lab.set_control("magma", "runny")
	var short: Array = await _press(lab, 1.0)
	if absf(float(short[0]) - 1.0 / VolcanoModel.PUMP_S) > 0.02 or short[1] != "small" or short[2] or int(short[3]) > 60:
		problems.append("runny 1 s: %s" % str(short))
	var long: Array = await _press(lab, 2.5)
	if absf(float(long[0]) - 2.5 / VolcanoModel.PUMP_S) > 0.02 or long[1] != "wide" or absf(lab.model.input("lava") - float(long[0])) > 1e-9:
		problems.append("runny 2.5 s: %s (lava %.3f)" % [str(long), lab.model.input("lava")])
	var full: Array = await _press(lab, VolcanoModel.PUMP_S + 1.0)
	if absf(float(full[0]) - 1.0) > 1e-9:
		problems.append("a long press pumps past full: %.3f" % float(full[0]))
	lab.set_control("magma", "sticky")
	if lab.status() != "ready" or lab.pumped != 0.0:
		problems.append("a new magma kept the lava (%s)" % lab.status())
	var tall: Array = await _press(lab, 2.5)
	if tall[1] != "tall":
		problems.append("sticky 2.5 s: %s" % str(tall))
	# A new press clears the last eruption and starts the pump from empty.
	lab.hold_started(VolcanoLab.KNOB_ID)
	await tree.physics_frame
	if lab.model.input("lava") > 0.05 or lab.pumped > 0.05 or lab.settled():
		problems.append("a new press kept the lava %.2f" % lab.model.input("lava"))
	lab.hold_ended(VolcanoLab.KNOB_ID)
	expect.call(problems.is_empty(), "volcano pump: the press time sets the amount (fixed steps: %.0f s is a full pump, no more), nothing settles while held, the lava finishes within a second after the finger lets go; runny 1 s is a small mountain, 2.5 s a wide one; sticky 2.5 s a tall one; a new press or magma starts over" % VolcanoModel.PUMP_S,
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, magma, lava share, hit, missed]
	var cases := [
		[0, "runny", 0.6, true, false], [0, "runny", 1.0, true, false], [0, "runny", 0.2, false, true],
		[0, "sticky", 0.8, false, true], [0, "normal", 1.0, false, true],
		[1, "sticky", 0.6, true, false], [1, "sticky", 1.0, true, false], [1, "sticky", 0.2, false, true],
		[1, "runny", 1.0, false, true], [1, "normal", 1.0, false, true],
		[2, "normal", 0.6, true, false], [2, "normal", 1.0, true, false], [2, "normal", 0.4, false, true],
		[2, "runny", 1.0, false, true], [2, "sticky", 1.0, false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.set_control("magma", case[1])
		_pour(lab, float(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s %.1f (%s): stamps %d missed %s" % [stage + 1, case[1], case[2], status, stamps, missed])
	var wants := [["sticky", "묽은 마그마를 골라 봐!"], ["runny", "끈적한 마그마를 골라 봐!"], ["sticky", "보통 마그마를 골라 봐!"]]
	for i in 3:
		lab.set_control("magma", wants[i][0])
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong magma says '%s'" % [i + 1, line[0]])
	lab.set_game_stage(0, 0, false)
	lab.set_control("magma", "runny")
	lab.hold_started(VolcanoLab.KNOB_ID)
	_pour(lab, 0.8)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the pump is held")
	lab.hold_ended(VolcanoLab.KNOB_ID)
	expect.call(problems.is_empty(), "volcano judging: the wide / tall mountain and the sea hit with their magma and enough of it, too little or another magma misses (Puppy's line), the wrong magma says the doc's \"…마그마를 골라 봐!\" line; not judged while the pump is held",
		"; ".join(problems))
	lab.queue_free()
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
		if groups.size() != 1 or groups[0].control != VolcanoLab.MAGMA_CONTROL or groups[0].presets.size() != 3:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	if lab.control_value("magma") != "runny" or lab.model.stickiness() != VolcanoModel.RUNNY:
		problems.append("the start is not runny magma")
	_pour(lab, 0.7)
	var resets := lab.reset_count
	lab.set_control("magma", "sticky")
	if lab.model.stickiness() != VolcanoModel.STICKY or lab.reset_count != resets + 1 or lab.status() != "ready" \
			or lab.props.tank_magma.mesh != lab.props._magma_meshes[2]:
		problems.append("sticky: %.1f, %s" % [lab.model.stickiness(), lab.status()])
	lab.reset_run()
	if lab.model.stickiness() != VolcanoModel.STICKY:
		problems.append("다시 lost the magma")
	expect.call(problems.is_empty(), "volcano condition button: 묽은 / 보통 / 끈적한 on every stage; a new magma starts the run over (the tank shows it), 다시 keeps it",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the site ---------------------------------------------------------------------------------------

## Stages 1 and 2 on the model (their goals on the sand), stage 3 and a finished round on the big
## volcano at night; the stage-2 win stays on the table until the next stage's reset.
func check_site() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	lab.set_game_stage(0, 0, false)
	if lab.model.big() or not lab.props.wide_goal.visible or lab.props.tall_goal.visible or lab.props.night != 0.0:
		problems.append("stage 1: big %s, goals %s/%s" % [lab.model.big(), lab.props.wide_goal.visible, lab.props.tall_goal.visible])
	lab.set_game_stage(1, 1, true)
	if lab.model.big() or lab.props.wide_goal.visible or not lab.props.tall_goal.visible:
		problems.append("stage 2: goals %s/%s" % [lab.props.wide_goal.visible, lab.props.tall_goal.visible])
	lab.set_control("magma", "sticky")
	_pour(lab, 0.8)
	lab.set_game_stage(2, 2, true)   # stage 2 just won: the tall mountain stays
	if lab.model.big() or lab.status() != "tall" or lab.props.shown_height < VolcanoModel.TALL_MIN:
		problems.append("the stage-2 win was cleared at once (%s)" % lab.status())
	lab.reset_run()   # the screen's reset before stage 3
	if not lab.model.big() or lab.status() != "ready" or lab.props.mound.visible:
		problems.append("stage 3 is not on the big volcano")
	for i in 120:
		await tree.process_frame
	if lab.props.night < 0.99 or not lab.props.stars.visible or not lab.props.village_lights.visible:
		problems.append("no night on stage 3 (%.2f)" % lab.props.night)
	lab.set_game_stage(0, 0, false)
	if lab.model.big() or lab.props.night != 0.0:
		problems.append("back to stage 1 kept the big volcano")
	lab.set_game_stage(-1, 3, false)
	if not lab.model.big() or lab.props.night != 1.0 or lab.props.wide_goal.visible or lab.props.tall_goal.visible:
		problems.append("a finished round is not the big volcano at night")
	expect.call(problems.is_empty(), "volcano site: stages 1 and 2 on the model (the wide flags, then the tall pole), stage 3 and a finished round on the big volcano at night (stars, the village's windows); the stage-2 win stays until the next reset",
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
	for site: float in [VolcanoModel.SMALL, VolcanoModel.BIG]:
		lab.model.set_start("site", site)
		for kind: String in VolcanoModel.KINDS:
			lab.set_control("magma", kind)
			for share: float in [0.0, 0.3, 0.7, 1.0]:
				_pour(lab, share)
				for key: String in lab.observations():
					var value: Variant = lab.observations()[key]
					if not value is String or str(value) == "" or str(value).begins_with("volcano.") or digits.search(str(value)) != null:
						problems.append("%s %s %.1f: %s" % [kind, key, share, str(value)])
	expect.call(problems.is_empty(), "volcano: no number on the screen (the observations are words for every magma, amount and site, no units; the card is what the lava made)",
		"; ".join(problems.slice(0, 6)))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

## What matters is big and in the clear on the phone's, the desktop's and the tablet's front view:
## the pump's button (BUTTON_MIN of the height or more), the table's vent, the widest runny cone's
## edges, the tallest sticky cone's top and the tall pole's flag; the big volcano's crater, the
## stream's top and its shore, the new land's tip and the risen needle's tip.
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
		var inside := func(world: Vector3, what: String) -> void:
			var p: Vector2 = at.call(world)
			var top := TOP_RIGHT if p.x * size.x > RIGHT_UNITS else TOP_FREE
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < top or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		var vent := VolcanoProps.VENT
		var reach := VolcanoModel.reach_of(1.0, VolcanoModel.RUNNY)
		var tall := VolcanoModel.height_of(1.0, VolcanoModel.STICKY)
		inside.call(lab.props.button_top(), "the pump's button")
		inside.call(VolcanoProps.PUMP_AT, "the pump's foot")
		inside.call(vent + Vector3(-reach, 0.0, 0.0), "the wide cone's left")
		inside.call(vent + Vector3(reach, 0.0, 0.0), "the wide cone's right")
		inside.call(vent + Vector3(0.0, 0.0, reach), "the wide cone's front")
		inside.call(vent + Vector3(0.0, tall, 0.0), "the tall cone's top")
		inside.call(vent + Vector3(VolcanoProps.POLE_AWAY, VolcanoModel.TALL_MIN + 0.45, -0.2), "the tall pole's top")
		inside.call(VolcanoProps.crater_top(), "the crater")
		inside.call(VolcanoProps.flow_point(0.0), "the stream's top")
		inside.call(VolcanoProps.shore(), "the shore")
		inside.call(VolcanoProps.shore() + VolcanoProps.flow_dir() * VolcanoProps.LAND_LENGTH, "the new land's tip")
		inside.call(VolcanoProps.crater_top() + VolcanoGame.RISEN + Vector3(0.0, VolcanoGame.NEEDLE_LENGTH, 0.0), "the risen needle")
		# The sticky plug at its biggest swell (its top and its sides) and the risen needle's leaning tip.
		var swell := VolcanoProps.PLUG_SWELL
		var dome_wide := VolcanoProps.RIM_RADIUS * VolcanoProps.PLUG_WIDE * (1.0 + 0.5 * swell)
		var dome_base := VolcanoProps.crater_top() - Vector3(0.0, VolcanoProps.PLUG_SUNK, 0.0)
		inside.call(dome_base + Vector3(0.0, VolcanoProps.PLUG_HIGH * (1.0 + swell), 0.0), "the plug's top")
		inside.call(dome_base + Vector3(-dome_wide, 0.0, 0.0), "the plug's left")
		inside.call(dome_base + Vector3(dome_wide, 0.0, 0.0), "the plug's right")
		var game: VolcanoGame = lab.game
		game._set_rise(1.0)
		inside.call(game._tip(), "the risen needle's tip")
		# Big enough on the screen: the volcano's height (its foot under the crater to the crater), the
		# plug's height and the needle's blade, as shares of the screen's height.
		var foot: Vector2 = at.call(VolcanoProps.VOLCANO_AT + Vector3(0.0, 0.0, VolcanoProps.VOLCANO_RADIUS))
		var crater: Vector2 = at.call(VolcanoProps.crater_top())
		var volcano := foot.y - crater.y
		var plug_top: Vector2 = at.call(dome_base + Vector3(0.0, VolcanoProps.PLUG_HIGH, 0.0))
		var plug := crater.y - plug_top.y
		var n0: Vector2 = at.call(game.needle.transform * Vector3.ZERO)
		var n1: Vector2 = at.call(game.needle.transform * Vector3(VolcanoGame.NEEDLE_BLADE.x, 0.0, 0.0))
		var blade := Vector2((n1.x - n0.x) * size.x / size.y, n1.y - n0.y).length()
		if volcano < VOLCANO_MIN or plug < PLUG_MIN or blade < BLADE_MIN:
			problems.append("%s: the volcano %.3f, the plug %.3f, the needle's blade %.3f of the height" % [str(size), volcano, plug, blade])
		seen.append("%s volcano %.3f plug %.3f blade %.3f" % [str(size), volcano, plug, blade])
		var a: Vector2 = at.call(lab.props.button_top() + Vector3(-VolcanoProps.BUTTON_RADIUS, 0.0, 0.0))
		var b: Vector2 = at.call(lab.props.button_top() + Vector3(VolcanoProps.BUTTON_RADIUS, 0.0, 0.0))
		var button := (b.x - a.x) * size.x / size.y
		if button < BUTTON_MIN:
			problems.append("%s: the pump's button is %.3f of the height" % [str(size), button])
		seen.append("%s button %.3f, crater %s" % [str(size), button, str(at.call(VolcanoProps.crater_top()))])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "volcano in view (phone, desktop, tablet): the pump's button (%.0f%% of the height or more), the widest and the tallest cone on the table and the tall pole, the big volcano's crater, its stream to the shore, the new land, the swollen plug and the risen needle, all inside the sides, under the top band (%.0f%%, %.0f%% on the right) and above the bottom %.0f%%; the volcano %.0f%%, the plug %.0f%% and the needle's blade %.0f%% of the height or more" % [BUTTON_MIN * 100.0, TOP_FREE * 100.0, TOP_RIGHT * 100.0, (1.0 - BOTTOM_FREE) * 100.0, VOLCANO_MIN * 100.0, PLUG_MIN * 100.0, BLADE_MIN * 100.0],
		"; ".join(problems.slice(0, 5) + seen))


# --- the backdrop ---------------------------------------------------------------------------------

## The night's ground (2026-11-07 user: too bright, the grass still green) and the far landmarks
## (another spot's showed through over the volcano): the lab's ground has its own copy of the map's
## material, darkened at night (own_tint GROUND_NIGHT) and back to the day after; the map's own
## material is never touched. On Hutton Island the lab's world leaves out the other spots' landmarks
## right behind the big volcano (a world without the lab's say has one there); the rest stay.
func check_backdrop() -> void:
	var problems := []
	Island.use_for_run("hutton")
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var island: MeshInstance3D = lab.get_node("Island")
	var ground := island.material_override as ShaderMaterial
	if ground == null or ground == MapIsland.material():
		problems.append("the lab's ground shares the map's material")
	else:
		lab.set_game_stage(2, 2, false)
		for i in 120:
			await tree.process_frame
		if not (ground.get_shader_parameter("own_tint") as Vector3).is_equal_approx(VolcanoLab.GROUND_NIGHT):
			problems.append("the night's ground %s" % str(ground.get_shader_parameter("own_tint")))
		lab.set_game_stage(0, 0, false)
		for i in 120:
			await tree.process_frame
		if not (ground.get_shader_parameter("own_tint") as Vector3).is_equal_approx(Vector3.ONE):
			problems.append("the day's ground %s" % str(ground.get_shader_parameter("own_tint")))
	var shared: Variant = MapIsland.material().get_shader_parameter("own_tint")
	if shared != null and shared != Vector3.ONE:
		problems.append("the map's material was darkened (%s)" % str(shared))
	var world: LabWorld = island.get_meta("world")
	var plain := LabWorld.new(ID, VolcanoProps.WORLD_CENTER)
	var holder := Node3D.new()
	tree.root.add_child(holder)
	plain.build(holder)
	var behind := func(w: LabWorld) -> Array:
		return w.far_things.filter(func(f: Array) -> bool: return f[0] == "landmark" and lab.hides_far_landmark(Vector2(f[1], f[2])))
	var others := func(w: LabWorld) -> int:
		return w.far_things.filter(func(f: Array) -> bool: return f[0] == "landmark").size()
	if (behind.call(plain) as Array).is_empty():
		problems.append("no landmark behind the volcano to leave out (the check checks nothing)")
	if not (behind.call(world) as Array).is_empty():
		problems.append("landmarks behind the volcano: %s" % str(behind.call(world)))
	if others.call(world) != others.call(plain) - (behind.call(plain) as Array).size() or others.call(world) == 0:
		problems.append("landmarks %d of %d" % [others.call(world), others.call(plain)])
	var middle := Vector2(VolcanoProps.VOLCANO_AT.x, VolcanoProps.VOLCANO_AT.z)
	for t in ArtKit.TREES:
		var tree_at: Vector2 = lab.near_tree_at(Vector2(VolcanoProps.WORLD_CENTER.x + t[0], VolcanoProps.WORLD_CENTER.z + t[1]))
		if tree_at.distance_to(middle) < VolcanoProps.VOLCANO_RADIUS + 1.3 * float(t[2]):
			problems.append("a tree on the volcano's slope at %s" % str(tree_at))
	expect.call(problems.is_empty(), "volcano backdrop: the lab's trees stand off the volcano's slope; the night darkens the lab's own ground (not the map's material) and the day brings it back; the other spots' landmarks right behind the big volcano are left out of the lab, the rest stay",
		"; ".join(problems) if not problems.is_empty() else "%d of %d landmarks" % [others.call(world), others.call(plain)])
	holder.queue_free()
	lab.queue_free()
	await tree.process_frame
	Island.forget_current()


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["mountain_tall", "mountain_wide"]
	var pick_kinds := ["magma_runny", "magma_normal", "magma_sticky"]
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
			and pick_kinds.all(func(k: String) -> bool: return k in PickPictures.KINDS)
	expect.call(listed and drawn == predict_kinds + pick_kinds,
		"volcano pictures: the question's mountains (PredictPictures) and the magma kinds (PickPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[10]) != ID:
		problems.append("volcano is not hutton's last spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if not hutton.playable():
		problems.append("hutton is not playable with every spot a lab")
	expect.call(problems.is_empty(), "volcano: Hutton Island's last spot is an experiment (a lab on its map); with it every spot is, so the island is playable", "; ".join(problems))


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
	while round.phase() == MissionRound.Phase.CLUE and told.size() < 10:
		var line := round.clue_to_open()
		told.append([line.speaker, line.face])
		round.clue_opened()
		round.clue_read()
	var first_ok := told == [[Story.KEEPER, "worried"], ["puppy", "thinking"], ["puppy", "surprised"], [Story.KEEPER, "surprised"],
		["puppy", "thinking"], ["dugi", "explain"], ["dugi", "explain"]] and round.phase() == MissionRound.Phase.ASKING
	var again := MissionRound.new(definition, store)
	again.start()
	again.open(true)
	var later := []
	while again.phase() == MissionRound.Phase.CLUE and later.size() < 10:
		later.append(again.clue_to_open().speaker)
		again.clue_opened()
		again.clue_read()
	Story.enabled = was
	var wrong := ExperimentRegistry._validate_story({"more": [{"speaker": "cat", "text": "…"}, {"speaker": "puppy"}, {"speaker": "fox", "text": "…", "face": "angry"}]})
	expect.call(first_ok and later == ["dugi", "dugi"] and wrong.size() == 3,
		"volcano opening: first visit the fox (worried), Puppy's clue, Puppy and the fox in turn (story.more), Puppy's glint, Dugi's two lines, then the question; later visits Dugi's two lines; story.more checks its speakers, texts and faces",
		"%s / %s / %s" % [str(told), str(later), str(wrong)])


# --- the hand -------------------------------------------------------------------------------------

## Through the Manipulator: a press on the pump's button holds it (nothing is dragged), the pump runs
## while it holds, a let-go ends it; the hand guide presses and holds the button.
func check_hand() -> void:
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
	var screen := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit
	var problems := []
	var at: Vector2 = screen.call(lab.props.button_top())
	m.handle_pointer("press", at)
	if m.mode != "hold" or m.active_id != VolcanoLab.KNOB_ID or lab.holding != VolcanoLab.KNOB_ID:
		problems.append("press on the button: mode '%s' id '%s'" % [m.mode, m.active_id])
	for i in 60:
		await tree.physics_frame
	if lab.pumped < 0.2 or lab.settled() or not lab.props.gauge.visible or lab.props.gauge.fraction < 0.2:
		problems.append("held 1 s: pumped %.2f" % lab.pumped)
	m.handle_pointer("move", at + Vector2(80.0, 0.0))
	m.handle_pointer("release", at + Vector2(80.0, 0.0))
	if lab.holding != "" or m.mode != "":
		problems.append("let go: holding '%s'" % lab.holding)
	for i in 60:
		await tree.physics_frame
	if not lab.settled() or lab.status() != "small":
		problems.append("after: %s" % lab.status())
	# The top of the tank (under the button) is the pump too.
	m.handle_pointer("press", screen.call(VolcanoProps.PUMP_AT + Vector3(0.3, VolcanoProps.TANK_BOTTOM + VolcanoProps.TANK_HEIGHT * 0.7, VolcanoProps.TANK_RADIUS)))
	if m.mode != "hold":
		problems.append("a press on the tank did not hold the pump")
	m.handle_pointer("cancel", Vector2.ZERO)
	if lab.holding != "":
		problems.append("a cancel left the pump held")
	var guide := m.guide()
	if guide.get("kind", "") != "hold" or guide.get("id", "") != VolcanoLab.KNOB_ID or (guide.get("from", Vector3.ZERO) as Vector3).distance_to(lab.props.button_top()) > 1e-4:
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "volcano hand: a press on the pump (its button or its tank) holds it, the pump runs while held (the gauge fills), a let-go or a cancel ends it and the lava settles; the hand guide presses and holds the button",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: VolcanoGame = lab.game
	var problems := []
	var crater := VolcanoProps.crater_top()
	if game.piece_state != "held" or not game.piece.visible or game.piece.global_position.distance_to(crater) > 1.5 or game.risen() or lab.props.land.visible:
		problems.append("not in the crater at the start (or the needle up, or new land)")
	if game.piece.global_position.y > crater.y + 0.3:
		problems.append("the piece sticks out of the crater (%.2f over its rim)" % (game.piece.global_position.y - crater.y))
	game.show_stage(1, 1, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or game.risen():
		problems.append("out before the last stamp (%s)" % game.piece_state)
	lab.set_game_stage(2, 2, true)
	lab.reset_run()
	lab.set_control("magma", "normal")
	_pour(lab, VolcanoModel.SEA_SHARE)
	lab.set_game_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 600:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	var land := VolcanoProps.shore() + VolcanoProps.flow_dir() * VolcanoProps.LAND_LENGTH * 0.5
	if game.piece_state != "out" or not game.risen() or lab.props.shown_land < 0.99 or absf(rest.y - VolcanoGame.LAND_TOP - LabGame.PIECE_SIZE) > 0.12 \
			or Vector2(rest.x, rest.z).distance_to(Vector2(land.x, land.z)) > VolcanoProps.LAND_LENGTH * 0.5:
		problems.append("after the last stamp: %s at %s, land %.2f, needle up %s" % [game.piece_state, str(rest), lab.props.shown_land, game.risen()])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.set_game_stage(-1, 3, false)
	if (again.game as VolcanoGame).take_piece() != null or not (again.game as VolcanoGame).risen() or again.props.shown_land < 0.99:
		problems.append("a finished spot: a piece, a sunk needle or no land")
	expect.call(problems.is_empty(), "volcano piece: the needle in the crater with the piece on its tip until the last stamp; then the land grows into the sea, the needle is pushed up and the piece jumps down onto the new land; a finished spot shows the needle up and the new land, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
