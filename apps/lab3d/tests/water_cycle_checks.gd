## 물의 여행 (#91, 2026-11-07; Hutton Island's fourth spot):
## - the data: the definition is valid, a hutton island lab after seasons (index.json `islands`), not
##   one of the first island's; no explanation picture (hutton-lines.md 4 has no "[그림: …]"); the
##   question's and the condition button's pictures are code-drawn kinds; its Korean lines are
##   docs/islands/hutton-lines.md section 4 word for word (the fox's line, Puppy's two lines, Dugi's
##   two lines, the question, its choices, reason and bridge, the riddle, every stage's condition,
##   mission, explanation, win, miss and wrong-condition line) with the doc's faces; Puppy's result
##   lines are short with no science words, digits or symbols; English has every line;
## - the model (rule-based, docs/islands/hutton.md): water goes up only while the sun shines, a
##   stronger sun evaporates more, the cloud comes before the rain and the rain before the full pond,
##   the day's sunshine is capped: the weak sun never fills the pond, the strong one does;
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's miss line), the
##   wrong sun's line, nothing while the sun is held;
## - the condition button: 약한 해 / 쨍쨍한 해 on every stage, a new day with a new sun, 다시 keeps it;
## - no number on the screen: the observations are words, no units, the card is the water's journey;
## - the hand: a press on the sun holds it (no drag), the sunshine runs while it is held and adds up
##   over presses, stops when let go and at the day's end; the hand guide shows a hold;
## - the first stage (#114): the held sun stops by itself at the first cloud (no rain), judged at once;
##   the next stages go on into rain;
## - the stream (#114): the full pond flows back to the sea, not before;
## - what matters is big and in view on the phone, the desktop and the tablet: the sun, the cloud, the
##   pond with its frogs and piece, the day sign, clear of the top band and the dialogue box;
## - the spot, the opening (the fox first on a first visit) and the piece (stuck in the mud until the
##   pond is full, then it floats up and jumps out for the cat).
extends RefCounted

const ID := "water-cycle"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
## The phone (2340 x 1080), a desktop window (1920 x 1080) and the tablet (1920 x 1200) in UI units.
const PHONE := Vector2(1560, 720)
const DESKTOP := Vector2(1280, 720)
const TABLET := Vector2(1152, 720)
## In view: inside EDGE of the sides, above the bottom share the dialogue box and the buttons take.
const EDGE := 0.03
const BOTTOM_FREE := 0.8
## The top band: the title runs along the top (TITLE_FREE) and on the left the key card and the stamp
## strip come down to TOP_FREE (to LEFT_BAND of the width).
const TITLE_FREE := 0.13
const TOP_FREE := 0.33
const LEFT_BAND := 0.3
## The weak sun's ball at least this share of the view's height (a child's finger target).
const SUN_MIN := 0.1
const LINE_MAX := 24

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
	check_result_lines()
	check_model()
	await check_judging()
	await check_condition_button()
	await check_no_numbers()
	await check_hold()
	await check_cloud_stop()
	check_stream()
	await check_in_view()
	check_spot()
	await check_pictures()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> WaterCycleLab:
	var lab := WaterCycleLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## The lab's model with `seconds` of sunshine of the sun `sun` ("weak" / "strong").
static func _put(lab: WaterCycleLab, sun: String, seconds: float) -> void:
	lab.set_control("sun", sun)
	lab.model.set_input("heat", seconds)
	lab._show()


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "water-cycle: the definition loads", "not found")
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
	var picks: Array = kid.picks.sun
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["weak", "strong"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the sun buttons %s" % str(picks))
	var hold: Array = definition.manipulation.objects.filter(func(o: Dictionary) -> bool: return o.id == WaterCycleLab.KNOB_ID and o.get("hold", false))
	if hold.size() != 1:
		problems.append("the sun is not a hold object")
	# The missions doc's section 4: what the child touches and the sun's two conditions.
	var missions := FileAccess.get_file_as_string(MISSIONS_PATH)
	var at := missions.find("### 4. 물의 여행")
	var section := missions.substr(at, missions.find("\n### ", at + 4) - at)
	if at < 0 or not section.contains("해를 꾹 눌러") or not section.contains("약한 해 / 쨍쨍한 해"):
		problems.append("hutton-missions.md 4 changed: %s" % section.left(200))
	expect.call(problems.is_empty(), "water-cycle: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; the sun is held (hutton-missions.md 4); no explanation picture (none in the doc); code-drawn question and sun pictures",
		"; ".join(problems))


## The section "## 4. 물의 여행" of the lines doc: its numbered lines [who, face, text], the question,
## the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 4. 물의 여행")
	var end := text.find("\n## ", start + 4)
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
	if doc.lines.size() != 5 or opening.size() != 5:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 5:
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
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[0] != "하늘로 올라가요":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.sun:
		pick_label[p.value] = p.label
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), str(pick_label.get(stage.conditions.sun, "?")), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "water-cycle: the Korean lines are hutton-lines.md 4 word for word (the fox, Puppy's two lines, Dugi's two lines, the question, the riddle, the three stages with their suns and wrong-sun lines) with its faces",
		"; ".join(problems))


func check_result_lines() -> void:
	var problems := []
	var science := Story.science_words()
	var symbols := RegEx.create_from_string("[0-9%=+×/<>]")
	for stage: Dictionary in _definition().missions.stages:
		for key: String in ["win", "miss", "miss_conditions"]:
			var line := str(stage.get(key, ""))
			if line == "" or line.length() > LINE_MAX or symbols.search(line) != null or science.any(func(w: String) -> bool: return line.contains(w)):
				problems.append("%s '%s'" % [key, line])
	var definition := _definition()
	var told: Array = [Story.keeper(definition), Story.clue(definition), Story.map_clue(definition)]
	told.append_array(Story.more(definition).map(func(l: Dictionary) -> String: return str(l.text)))
	for line: String in told:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/water-cycle.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/water-cycle.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or Story.more(en).size() != 1 or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.sun.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "water-cycle: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

## The rules (docs/islands/hutton.md: rule-based relations the tests check): nothing goes up without
## sunshine; at every moment the strong sun has sent up more water than the weak one; the order is
## vapour -> cloud -> rain -> full; the cloud only grows, the pond only fills; the day's cap leaves the
## weak sun's pond short of full and lets the strong one fill it; holding and letting go.
func check_model() -> void:
	var problems := []
	var order := ["ready", "vapour", "cloud", "rain", "full"]
	for sun: float in [WaterCycleModel.WEAK_SUN, WaterCycleModel.STRONG_SUN]:
		var m := WaterCycleModel.new()
		m.set_start("sun", sun)
		var last := 0
		var cloud := 0.0
		var pond := 0.0
		var s := 0.0
		while s <= WaterCycleModel.DAY_S + 1e-9:
			m.set_input("heat", s)
			var at := order.find(m.status())
			if at < last or m.cloud_share() < cloud - 1e-12 or m.pond_share() < pond - 1e-12:
				problems.append("sun %.1f at %.2f s: %s after %s" % [sun, s, m.status(), order[last]])
			if m.status() in ["rain", "full"] and m.cloud_share() < 1.0:
				problems.append("rain from a light cloud at %.2f s" % s)
			last = maxi(last, at)
			cloud = m.cloud_share()
			pond = m.pond_share()
			s += 0.05
		var full_ok := (m.status() == "full") == WaterCycleModel.is_strong(sun)
		if not full_ok:
			problems.append("sun %.1f ends the day %s" % [sun, m.status()])
	var weak := WaterCycleModel.new()
	var strong := WaterCycleModel.new()
	strong.set_start("sun", WaterCycleModel.STRONG_SUN)
	for s: float in [0.5, 2.0, 5.0, 9.0]:
		weak.set_input("heat", s)
		strong.set_input("heat", s)
		if strong.evaporated() <= weak.evaporated() or strong.pond_share() < weak.pond_share():
			problems.append("the strong sun is not ahead at %.1f s" % s)
	weak.set_input("heat", 0.0)
	if weak.status() != "ready" or weak.evaporated() != 0.0:
		problems.append("water went up without sunshine")
	# A weak sun's day: a cloud after a few seconds, rain later, never full (the most is short of it).
	weak.set_input("heat", WaterCycleModel.DAY_S)
	if weak.pond_share() > 0.8 or weak.pond_share() <= 0.0:
		problems.append("the weak sun's day ends with the pond at %.2f" % weak.pond_share())
	# Held: the sunshine runs at one second per second and stops at the day's end; let go, it stops.
	var h := WaterCycleModel.new()
	h.heat_on()
	for i in 60:
		h.step(1.0 / 60.0)
	if absf(h.input("heat") - 1.0) > 1e-6 or not h.heating():
		problems.append("one second held: %.3f s of sunshine" % h.input("heat"))
	h.heat_off()
	h.step(0.5)
	if absf(h.input("heat") - 1.0) > 1e-6 or h.heating():
		problems.append("let go: %.3f s" % h.input("heat"))
	h.heat_on()
	for i in 1000:
		h.step(1.0 / 60.0)
	if not h.day_over() or h.heating() or h.day_left() != 0.0 or h.input("heat") > WaterCycleModel.DAY_S:
		problems.append("the day does not end: %.3f s" % h.input("heat"))
	h.reset()
	if h.input("heat") != 0.0 or h.day_left() != 1.0:
		problems.append("다시 keeps the day's sunshine")
	expect.call(problems.is_empty(), "water-cycle model: vapour -> cloud -> rain -> full in order (rain only from a heavy cloud, the cloud and the pond never shrink), the strong sun always ahead, no water without sunshine; the day's cap (%.0f s): the weak sun's pond stays short of full, the strong one fills it; held one second = one second of sunshine, let go stops it, the day ends, 다시 starts a new one" % WaterCycleModel.DAY_S,
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, sun, seconds of sunshine, hit, missed]
	var cases := [
		[0, "weak", 0.0, false, false], [0, "weak", 1.0, false, true], [0, "weak", 2.4, false, true], [0, "weak", 2.6, true, true],
		[0, "weak", 6.0, true, true], [0, "strong", 1.2, false, true],
		[1, "weak", 2.6, false, true], [1, "weak", 4.9, false, true], [1, "weak", 5.1, true, true], [1, "weak", 10.0, true, true],
		[1, "strong", 3.0, false, true],
		[2, "strong", 1.5, false, true], [2, "strong", 4.0, false, true], [2, "strong", 5.0, true, true], [2, "strong", 10.0, true, true],
		[2, "weak", 10.0, false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		_put(lab, case[1], float(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s %.1f s (%s): stamps %d missed %s" % [stage + 1, case[1], case[2], status, stamps, missed])
	var wants := [["weak", "약한 해를 골라 봐!"], ["weak", "약한 해를 골라 봐!"], ["strong", "쨍쨍한 해를 골라 봐!"]]
	for i in 3:
		lab.set_control("sun", "strong" if wants[i][0] == "weak" else "weak")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong sun says '%s'" % [i + 1, line[0]])
	var miss := MissionRound.result_line(definition, 2, false, false)
	if miss[0] != "조금 더 오래 꾹 눌러 봐!":
		problems.append("stage 3's miss '%s'" % miss[0])
	_put(lab, "weak", 3.0)
	lab.hold_started(WaterCycleLab.KNOB_ID)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the sun is held")
	lab.model.set_input("heat", WaterCycleModel.DAY_S)
	if lab.settled():
		problems.append("settled under the finger after the day ended")
	lab.hold_ended(WaterCycleLab.KNOB_ID)
	if not lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("not judged after the finger let go")
	expect.call(problems.is_empty(), "water-cycle judging: one cloud / rain / the full pond hit from their amounts on and miss before (Puppy's line), the wrong sun says the doc's \"…해를 골라 봐!\" line, the weak sun's whole day never fills the pond; not judged while the sun is held",
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
		if groups.size() != 1 or groups[0].control != "sun" or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	if lab.control_value("sun") != "weak" or lab.model.input("sun") != WaterCycleModel.WEAK_SUN or lab.props.shown_strong:
		problems.append("the start is not the weak sun")
	_put(lab, "weak", 4.0)
	var resets := lab.reset_count
	lab.set_control("sun", "strong")
	lab._show()
	if lab.model.input("sun") != WaterCycleModel.STRONG_SUN or lab.reset_count != resets + 1 or lab.model.input("heat") != 0.0 \
			or lab.status() != "ready" or not lab.props.shown_strong:
		problems.append("strong: sun %.2f, heat %.2f, %s" % [lab.model.input("sun"), lab.model.input("heat"), lab.status()])
	lab.reset_run()
	if lab.model.input("sun") != WaterCycleModel.STRONG_SUN:
		problems.append("다시 lost the condition")
	expect.call(problems.is_empty(), "water-cycle condition button: 약한 해 / 쨍쨍한 해 on every stage; a new sun is a new day (the sunshine back to none), 다시 keeps it",
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
	var states := []
	for pair: Array in [["weak", 0.0], ["weak", 1.0], ["weak", 3.0], ["weak", 7.0], ["strong", 10.0]]:
		_put(lab, pair[0], pair[1])
		var seen: Dictionary = lab.observations()
		states.append(seen.state)
		for key: String in seen:
			var value: Variant = seen[key]
			if not value is String or str(value) == "" or digits.search(str(value)) != null:
				problems.append("%s at %s: %s" % [key, str(pair), str(value)])
	if states.size() != 5 or Array(states).any(func(s: String) -> bool: return Array(states).count(s) > 1):
		problems.append("the card does not change: %s" % str(states))
	# The pictures follow the model: no cloud before its water went up, then a growing cloud, the
	# pond filling, the day bar going down.
	_put(lab, "weak", 1.0)
	var before := [lab.props.cloud.visible, lab.props.shown_pond, lab.props.shown_day]
	_put(lab, "weak", 4.0)
	var middle := [lab.props.cloud.visible, lab.props.cloud.scale.x, lab.props.shown_pond, lab.props.shown_day]
	_put(lab, "weak", 8.0)
	var after := [lab.props.cloud.scale.x, lab.props.shown_pond, lab.props.shown_day]
	if before[0] or not middle[0] or middle[1] >= after[0] or before[1] != 0.0 or middle[2] != 0.0 or after[1] <= 0.0 \
			or not (before[2] > middle[3] and middle[3] > after[2]):
		problems.append("the pictures %s %s %s" % [str(before), str(middle), str(after)])
	expect.call(problems.is_empty(), "water-cycle: no number on the screen (the observations are words, no units, the card is the water's journey and names each step); the cloud, the pond and the day bar follow the model",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the hand -------------------------------------------------------------------------------------

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
	if guide.get("kind", "") != "hold" or guide.get("id", "") != WaterCycleLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	# A press on the sun's upper right ray (not its middle) holds it.
	var at := view.rig.unproject_position(WaterCycleProps.SUN_AT + Vector3(0.7, 0.6, 0.0)) / per_unit
	m.handle_pointer("press", at)
	if m.mode != "hold" or m.active_id != WaterCycleLab.KNOB_ID or not lab.pressing:
		problems.append("press on the sun: mode '%s' id '%s'" % [m.mode, m.active_id])
	for i in 60:
		await tree.physics_frame
	var held: float = lab.model.input("heat")
	if held < 0.7 or held > 1.3 or lab.settled() or not lab.props.shown_heating:
		problems.append("held a second: %.2f s of sunshine, settled %s" % [held, lab.settled()])
	m.handle_pointer("move", at + Vector2(40.0, 20.0))
	m.handle_pointer("release", at + Vector2(40.0, 20.0))
	var let_go: float = lab.model.input("heat")
	for i in 20:
		await tree.physics_frame
	if lab.pressing or not lab.settled() or lab.model.input("heat") != let_go or lab.props.shown_heating \
			or lab.props.sun.global_position.distance_to(WaterCycleProps.SUN_AT) > 1e-4:
		problems.append("let go: %.2f -> %.2f s, the sun moved or still shining" % [let_go, lab.model.input("heat")])
	m.handle_pointer("press", at)
	for i in 30:
		await tree.physics_frame
	m.handle_pointer("release", at)
	if lab.model.input("heat") <= let_go + 0.3:
		problems.append("a second press does not add up: %.2f s" % lab.model.input("heat"))
	expect.call(problems.is_empty(), "water-cycle hand: a press anywhere on the sun holds it (no drag, it does not move), the sunshine runs while held (one second a second) and stops when let go, a second press adds to it; not settled while held; the hand guide shows a hold",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


## The first stage asks for one cloud (#114 2026-11-10 user: "첫번째 실험을 하는데 갑자기 비가 내림"):
## the held sun stops by itself as the first cloud forms, no rain, and it is judged while the finger is
## still down; a longer hold changes nothing. From the second stage the held sun goes on into rain.
func check_cloud_stop() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	for sun: String in ["weak", "strong"]:   # (the strong one: the wrong sun for the stage, not judged)
		lab.set_game_stage(0, 0, false)
		_put(lab, sun, 0.0)
		lab.hold_started(WaterCycleLab.KNOB_ID)
		for i in 480:   # (8 s held: past the rain on either sun)
			await tree.physics_frame
		var m := lab.model as WaterCycleModel
		if lab.status() != "cloud" or m.raining() or lab.props.shown_raining or lab.props.shown_heating or not lab.pressing \
				or not lab.settled() or (sun == "weak" and MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1):
			problems.append("%s sun held in stage 1: %s, %.2f s, raining %s, settled %s" % [sun, lab.status(), m.input("heat"), m.raining(), lab.settled()])
		lab.hold_ended(WaterCycleLab.KNOB_ID)
	lab.set_game_stage(1, 1, false)
	_put(lab, "weak", 0.0)
	lab.hold_started(WaterCycleLab.KNOB_ID)
	for i in 330:
		await tree.physics_frame
	if lab.status() != "rain" or lab.settled():
		problems.append("stage 2 held 5.5 s: %s settled %s" % [lab.status(), lab.settled()])
	lab.hold_ended(WaterCycleLab.KNOB_ID)
	expect.call(problems.is_empty(), "water-cycle stage 1: the held sun stops at the first cloud (no rain, the sun no longer shines), judged with the finger still down; stage 2's held sun goes on into rain",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


## The full pond flows back to the sea (#114 2026-11-10 user: "연못에서 왜 물이 다시 바다로 안가지? 그래야
## 여행이되지"): the stream shows only once the pond is full, it runs from inside the pond's ring out to
## the sea, and its ripples move along it.
func check_stream() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	var problems := []
	_put(lab, "strong", 4.0)
	if lab.props.stream.visible or lab.props.shown_stream:
		problems.append("a stream before the pond is full")
	_put(lab, "strong", WaterCycleModel.DAY_S)
	if not lab.props.stream.visible:
		problems.append("no stream from the full pond")
	var from: Vector3 = WaterCycleProps.stream_point(0.0)
	var to: Vector3 = WaterCycleProps.stream_point(1.0)
	var pond := Vector2(WaterCycleProps.POND_AT.x, WaterCycleProps.POND_AT.z)
	if Vector2(from.x, from.z).distance_to(pond) >= WaterCycleProps.POND_RADIUS or to.x >= WaterCycleProps.SEA_RIGHT:
		problems.append("the stream from %s to %s" % [str(from), str(to)])
	var ripple: Node3D = lab.props.stream.get_child(0)
	var before := ripple.position
	lab.props.animate(0.3)
	if ripple.position.distance_to(before) < 0.05:
		problems.append("the ripples do not run")
	expect.call(problems.is_empty(), "water-cycle stream: only from the full pond, from inside its ring into the sea, its ripples running down it", "; ".join(problems))
	lab.queue_free()


# --- in view --------------------------------------------------------------------------------------

## The sun (weak, the smallest), the heavy cloud, the pond with its frogs and the piece, and the day
## sign are inside the view, below the title, clear of the key card and stamp strip on the left and
## above the dialogue box (phone, desktop, tablet). The weak sun is a big target.
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
			var top := TOP_FREE if p.x < LEFT_BAND else TITLE_FREE
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < top or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		_put(lab, "weak", 6.0)
		var sun := WaterCycleProps.SUN_AT
		for d: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
			inside.call(at.call(sun + d * WaterCycleProps.WEAK_RADIUS), "sun")
		var ball: float = (at.call(sun + Vector3.DOWN * WaterCycleProps.WEAK_RADIUS) as Vector2).y - (at.call(sun + Vector3.UP * WaterCycleProps.WEAK_RADIUS) as Vector2).y
		if ball < SUN_MIN:
			problems.append("%s: the weak sun is %.2f of the height" % [str(size), ball])
		var c := WaterCycleProps.CLOUD_AT
		for d: Vector3 in [Vector3(0.0, 1.2, 0.0), Vector3(-1.9, 0.0, 0.0), Vector3(1.9, 0.0, 0.0)]:
			inside.call(at.call(c + d), "cloud")
		var pond := WaterCycleProps.POND_AT
		for d: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.BACK, Vector3.FORWARD]:
			inside.call(at.call(pond + d * (WaterCycleProps.POND_RADIUS + 0.3)), "pond")
		for frog: Node3D in (lab.game as WaterCycleGame).frogs:
			inside.call(at.call(frog.global_position + Vector3.UP * 0.4), "frog")
		inside.call(at.call(lab.game.piece.global_position), "piece")
		var sign: Vector3 = lab.props.day_sign.global_position
		for d: Vector3 in [Vector3.LEFT, Vector3.RIGHT]:
			inside.call(at.call(sign + d * (WaterCycleProps.DAY_BAR.x * 0.5 + 0.5)), "day sign")
		inside.call(at.call(WaterCycleProps.CAT_AT + Vector3.UP * 0.8), "cat")
		seen.append("%s sun %.2f at %s" % [str(size), ball, str(at.call(sun))])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "water-cycle in view: the sun (%.0f%% of the height or more), the cloud, the pond with its frogs and piece, the day sign and the cat between the top band and the bottom %.0f%%, inside the sides (phone, desktop and tablet)" % [SUN_MIN * 100.0, (1.0 - BOTTOM_FREE) * 100.0],
		"; ".join(problems.slice(0, 4) + seen))


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["water_rises", "water_stays"]
	var pick_kinds := ["sun_weak", "sun_strong"]
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
		"water-cycle pictures: the question's water kinds (PredictPictures) and the sun kinds (PickPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[3]) != ID:
		problems.append("water-cycle is not hutton's fourth spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	expect.call(problems.is_empty(), "water-cycle: Hutton Island's fourth spot is an experiment (a lab on its map)", "; ".join(problems))


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
		told.append([line.speaker, line.face])
		round.clue_opened()
		round.clue_read()
	var first_ok := told == [[Story.KEEPER, "worried"], ["puppy", "worried"], ["puppy", "thinking"], ["dugi", "explain"], ["dugi", "explain"]] \
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
		"water-cycle opening: first visit the fox (worried), Puppy's two lines (worried, thinking), Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: WaterCycleGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or start.distance_to(WaterCycleProps.POND_AT) > WaterCycleProps.POND_RADIUS or game.frogs_in_pond():
		problems.append("not stuck in the dry pond at the start (or the frogs in it)")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 40:
		await tree.process_frame
	if game.piece_state != "held" or game.piece.global_position.distance_to(start) > 1e-3:
		problems.append("out before the last stamp (%s)" % game.piece_state)
	_put(lab, "strong", WaterCycleModel.DAY_S)
	game.show_stage(-1, 3, true)
	var rose := false
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
		rose = rose or game.piece.global_position.y > start.y + WaterCycleProps.POND_DEPTH * 0.6
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or not rose or not game.frogs_in_pond() or absf(rest.y - WaterCycleProps.LAND_TOP - LabGame.PIECE_SIZE) > 0.12 \
			or rest.distance_to(start) < 1.0:
		problems.append("after the last stamp: %s at %s (rose %s)" % [game.piece_state, str(rest), rose])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as WaterCycleGame).take_piece() != null or not (again.game as WaterCycleGame).frogs_in_pond():
		problems.append("a finished spot: a piece, or the frogs still waiting")
	expect.call(problems.is_empty(), "water-cycle piece: stuck in the dry pond's mud until the last stamp, then it floats up to the full pond's water and jumps out onto the land for the cat, the frogs leap in; a finished spot shows the frogs in the pond, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
