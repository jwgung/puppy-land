## 태풍·비구름 (#94, 2026-11-07; Hutton Island's seventh spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after seasons), not
##   one of the first island's; no explanation picture (hutton-lines.md 7 has no "[그림: …]"); the
##   question's and the sea buttons' pictures are code-drawn kinds; its Korean lines are
##   docs/islands/hutton-lines.md section 7 word for word (the fox's line, Puppy's clue, Dugi's two
##   lines, the question, its choices, reason and bridge, the riddle, every stage's condition, mission,
##   explanation, win, miss and wrong-condition line) with the doc's faces, and the stages' conditions
##   are hutton-missions.md 7's; Puppy's result lines are short with no science words, digits or
##   symbols; English has every line;
## - the rule model (no formula: docs/islands/hutton.md "시뮬레이션"): the warmer the sea, the faster and
##   the bigger the cloud grows (a warm sea to a rain cloud, a very warm one to a typhoon); a cold sea,
##   the cold strip and land feed nothing and weaken it; nothing changes before the cloud is moved;
##   a typhoon weakened over cold water is "calm", over land "landfall";
## - the judging (MissionRound on the real lab): each stage's hit and misses, the wrong sea's line,
##   nothing while the cloud is held or still changing; the last stage starts from the typhoon at sea;
## - the sea button: 차가운 / 따뜻한 / 아주 따뜻한 on every stage, the sea's look and its vapour follow it,
##   a new choice starts the run over;
## - no number on the screen: the observations are words, no units;
## - what matters is big and in view on the phone, the desktop and the tablet: the cloud at its starts,
##   where the hand guide takes it, the cold strip, the typhoon, the island, between the top band and
##   the dialogue box;
## - the spot, the opening (the fox first), the hand (the cloud follows the finger on the sea, a
##   put-down keeps it and it grows there, a cancel puts it back; the hand guide shows the stage's way)
##   and the piece (in the typhoon's eye, riding in it in the last stage, then out by the cat).
extends RefCounted

const ID := "typhoon"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
## The phone (2340 x 1080), a desktop window (1920 x 1080) and the tablet (1920 x 1200) in UI units.
const PHONE := Vector2(1560, 720)
const DESKTOP := Vector2(1280, 720)
const TABLET := Vector2(1152, 720)
## In view: inside this margin of the sides, under the top band (the title, the card, the mission
## strip) and above the bottom share the dialogue box and the buttons take.
const EDGE := 0.03
const TOP_FREE := 0.2
const BOTTOM_FREE := 0.8
## The mission strip at the top left (under the title and the card; #94 review: the stage 3 typhoon
## and its weakening cloud hid under it): what matters keeps out of it, its right end is this many UI
## units from the left (the longest mission line), its bottom this share of the height.
const STRIP_RIGHT := 720.0
const STRIP_BOTTOM := 0.34
## The typhoon at least this share of the view's width (it reads as big on a phone).
const STORM_MIN := 0.2
const LINE_MAX := 24
## Places on the stage (world x, z): the open sea, the cold strip, the island.
const SEA := Vector2(-1.5, 1.0)
const COLD := Vector2(-1.5, -3.3)
const LAND := Vector2(4.8, 0.4)
const DT := 1.0 / 60.0

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
	check_rule()
	check_weakening()
	await check_judging()
	await check_sea_button()
	await check_no_numbers()
	await check_in_view()
	check_spot()
	await check_pictures()
	check_opening()
	await check_drag()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> TyphoonLab:
	var lab := TyphoonLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## The model's cloud put at `at` and left until it got where its place takes it (or `seconds`).
static func _settle(model: TyphoonModel, at: Vector2, seconds := 60.0) -> void:
	model.set_input("x", at.x)
	model.set_input("z", at.y)
	var left := seconds
	while model.animating() and left > 0.0:
		model.step(DT)
		left -= DT


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "typhoon: the definition loads", "not found")
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
	var picks: Array = kid.picks.sea
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["cold", "warm", "hot"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the sea buttons %s" % str(picks))
	expect.call(problems.is_empty(), "typhoon: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; no explanation picture (none in the doc); code-drawn question and sea pictures",
		"; ".join(problems))


## The section "## 7. 태풍·비구름" of the lines doc: its numbered lines [who, face, text], the question,
## the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 7. 태풍·비구름")
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


## The condition column of hutton-missions.md 7's stage table.
func _mission_conditions() -> Array:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 7. 태풍·비구름")
	var end := text.find("\n## ", start + 4)
	var out := []
	if start < 0:
		return out
	for raw in text.substr(start, end - start).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			out.append(Array(line.split("|")).slice(1, -1)[1].strip_edges())
	return out


func check_doc_lines() -> void:
	var doc := _doc_section()
	var definition := _definition()
	var problems := []
	var faces := {"걱정": "worried", "생각": "thinking", "설명": "explain", "기쁨": "happy", "놀람": "surprised"}
	var who := {"여우": Story.KEEPER, "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition)
	if doc.lines.size() != 4 or opening.size() != 4:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 4:
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
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[1] != "잘 안 커져요":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.sea:
		pick_label[p.value] = p.label
	var conditions := _mission_conditions()
	if doc.rows.size() != 3 or conditions.size() != 3:
		problems.append("%d doc rows, %d mission rows" % [doc.rows.size(), conditions.size()])
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var condition := str(pick_label.get(stage.conditions.sea, "?"))
			var got := [str(i + 1), condition, stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
			if condition != conditions[i]:
				problems.append("stage %d condition %s (missions doc %s)" % [i + 1, condition, conditions[i]])
	expect.call(problems.is_empty(), "typhoon: the Korean lines are hutton-lines.md 7 word for word (the fox, Puppy, Dugi's two lines, the question, the riddle, the three stages with their seas and wrong-sea lines) with its faces; the seas are hutton-missions.md 7's",
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
	for line: String in [Story.keeper(_definition()), Story.clue(_definition()), Story.map_clue(_definition())]:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/typhoon.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/typhoon.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.sea.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "typhoon: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the rule model -------------------------------------------------------------------------------

## The textbook's relation as rules: the warmer the sea, the faster and bigger the cloud; cold water
## and land feed nothing; the places of the stage; nothing before the cloud is moved.
func check_rule() -> void:
	var problems := []
	var model := TyphoonModel.new()
	if model.status() != "ready" or model.input("size") != TyphoonModel.SMALL or TyphoonModel.place_at(model.input("x"), model.input("z")) != "land":
		problems.append("the start: %s, size %.2f" % [model.status(), model.input("size")])
	for i in 120:
		model.step(DT)
	if model.input("size") != TyphoonModel.SMALL or model.animating():
		problems.append("it changed before it was moved")
	if not (TyphoonModel.cap_of("hot") > TyphoonModel.cap_of("warm") and TyphoonModel.cap_of("warm") > TyphoonModel.cap_of("cold") \
			and TyphoonModel.cap_of("cold") == TyphoonModel.cap_of("land") and TyphoonModel.rate_of("hot") > TyphoonModel.rate_of("warm") \
			and TyphoonModel.rate_of("cold") == 0.0 and TyphoonModel.rate_of("land") == 0.0):
		problems.append("caps and rates do not rise with the sea's warmth")
	if not (TyphoonModel.SMALL < TyphoonModel.RAIN and TyphoonModel.RAIN < TyphoonModel.WARM_CAP and TyphoonModel.WARM_CAP < TyphoonModel.TYPHOON and TyphoonModel.TYPHOON <= TyphoonModel.HOT_CAP):
		problems.append("thresholds out of order")
	var places := {SEA: "sea", COLD: "cold", LAND: "land", TyphoonModel.ISLAND_CENTER: "land", Vector2(0.0, 8.5): "land",
		TyphoonModel.STORM_START: "sea", TyphoonModel.CLOUD_START: "land"}
	for at: Vector2 in places:
		if TyphoonModel.place_at(at.x, at.y) != places[at]:
			problems.append("%s is %s (want %s)" % [str(at), TyphoonModel.place_at(at.x, at.y), places[at]])
	# The same time over each sea: warmer, bigger (and never smaller on the way).
	var after := {}
	for sea: Array in [["cold", TyphoonModel.COLD], ["warm", TyphoonModel.WARM], ["hot", TyphoonModel.HOT]]:
		var m := TyphoonModel.new()
		m.set_start("sea", float(sea[1]))
		m.set_input("x", SEA.x)
		m.set_input("z", SEA.y)
		var last := m.input("size")
		var sizes := []
		for k in 4:
			for i in 60:
				m.step(DT)
				if m.input("size") < last - 1e-12:
					problems.append("%s: shrank on the way" % sea[0])
				last = m.input("size")
			sizes.append(m.input("size"))
		after[sea[0]] = sizes
		_settle(m, SEA)
		var want: String = {"cold": "small", "warm": "rain", "hot": "typhoon"}[sea[0]]
		if m.status() != want or absf(m.input("size") - m.cap()) > 1e-6:
			problems.append("%s sea settles %s at %.2f (want %s)" % [sea[0], m.status(), m.input("size"), want])
	for k in 4:
		if not (after.hot[k] >= after.warm[k] and after.warm[k] > after.cold[k]):
			problems.append("after %d s: hot %.2f, warm %.2f, cold %.2f" % [k + 1, after.hot[k], after.warm[k], after.cold[k]])
	# Over the cold strip and over land a very warm sea's cloud does not grow.
	for at: Vector2 in [COLD, LAND]:
		var m := TyphoonModel.new()
		m.set_start("sea", TyphoonModel.HOT)
		_settle(m, at)
		if m.input("size") != TyphoonModel.SMALL or m.status() != "small":
			problems.append("grew at %s: %.2f" % [str(at), m.input("size")])
	expect.call(problems.is_empty(), "typhoon rule: nothing changes before the cloud is moved; the warmer the sea the faster and bigger it grows (cold: stays small, warm: a rain cloud, very warm: a typhoon), never shrinking on the way; the cold strip and land feed nothing; the stage's places",
		"; ".join(problems.slice(0, 6)))


## Cold water and land weaken it: a rain cloud or a typhoon carried there loses its strength; a typhoon
## weakened over cold water is "calm", over land "landfall"; back over a warm sea it grows again; a
## reset and a new sea start over.
func check_weakening() -> void:
	var problems := []
	var model := TyphoonModel.new()
	model.set_start("sea", TyphoonModel.WARM)
	_settle(model, SEA)
	var rain := model.input("size")
	model.set_input("x", COLD.x)
	model.set_input("z", COLD.y)
	model.step(0.5)
	if not model.input("size") < rain:
		problems.append("a rain cloud did not weaken over the cold strip")
	_settle(model, COLD)
	if model.status() != "small":
		problems.append("a weakened rain cloud is %s" % model.status())
	model.start_storm(true)
	if model.status() != "ready" or model.input("size") < TyphoonModel.TYPHOON or Vector2(model.input("x"), model.input("z")) != TyphoonModel.STORM_START:
		problems.append("the storm start: %s %.2f" % [model.status(), model.input("size")])
	model.set_start("sea", TyphoonModel.HOT)
	_settle(model, SEA)
	if model.status() != "typhoon":
		problems.append("the storm over the very warm sea: %s" % model.status())
	var held := []
	model.set_input("x", COLD.x)
	model.set_input("z", COLD.y)
	for k in 3:
		model.step(0.5)
		held.append(model.input("size"))
	if not (held[0] > held[1] and held[1] > held[2]):
		problems.append("the typhoon over cold water %s" % str(held))
	_settle(model, COLD)
	if model.status() != "calm" or model.input("size") >= TyphoonModel.RAIN:
		problems.append("weakened over cold water: %s %.2f" % [model.status(), model.input("size")])
	_settle(model, SEA)
	if model.status() != "typhoon":
		problems.append("back over the very warm sea: %s" % model.status())
	_settle(model, LAND)
	if model.status() != "landfall":
		problems.append("over the island: %s" % model.status())
	model.reset()
	if model.status() != "ready" or model.input("size") != TyphoonModel.HOT_CAP:
		problems.append("after a reset: %s %.2f" % [model.status(), model.input("size")])
	model.set_start("sea", TyphoonModel.COLD)
	_settle(model, SEA)
	if model.status() != "calm":
		problems.append("the storm over a cold open sea: %s" % model.status())
	expect.call(problems.is_empty(), "typhoon rule: cold water weakens a rain cloud and a typhoon (step by step), a typhoon weakened over cold water is calm, over the island landfall, back over a very warm sea it grows again; the last stage's start is the typhoon at sea; a reset starts over",
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, sea, place, hit, missed]
	var cases := [
		[0, "warm", SEA, true, false], [0, "warm", COLD, false, true], [0, "warm", LAND, false, true],
		[0, "hot", SEA, false, true], [0, "cold", SEA, false, true],
		[1, "hot", SEA, true, false], [1, "hot", COLD, false, true], [1, "hot", LAND, false, true],
		[1, "warm", SEA, false, true], [1, "cold", SEA, false, true],
		[2, "hot", COLD, true, false], [2, "hot", Vector2(-6.0, -3.6), true, false], [2, "hot", SEA, false, true],
		[2, "hot", LAND, false, true], [2, "cold", SEA, false, true], [2, "warm", COLD, false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.set_control("sea", case[1])
		var at: Vector2 = case[2]
		lab.model.set_input("x", at.x)
		lab.model.set_input("z", at.y)
		if lab.model.animating() and (lab.settled() or MissionRound.judge(definition, stage, lab.status(), lab, lab.observations()) != stage):
			problems.append("stage %d judged while the cloud still changes" % (stage + 1))
		_settle(lab.model, at)
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		# (Puppy's miss line comes only for an attempt that earned no stamp: a calm sea with the wrong
		# condition is a miss, MissionRound.check_miss.)
		var missed := stamps == stage and MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s at %s (%s): stamps %d missed %s" % [stage + 1, case[1], str(at), status, stamps, missed])
	var wants := [["warm", "따뜻한 바다를 골라 봐!"], ["hot", "아주 따뜻한 바다를 골라 봐!"], ["hot", "아주 따뜻한 바다를 골라 봐!"]]
	for i in 3:
		lab.set_control("sea", "cold")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong sea says '%s'" % [i + 1, line[0]])
	lab.set_game_stage(0, 0, false)
	lab.set_control("sea", "warm")
	lab.manipulation_started(TyphoonLab.KNOB_ID)
	_settle(lab.model, SEA)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the cloud is held")
	lab.manipulation_cancelled(TyphoonLab.KNOB_ID)
	expect.call(problems.is_empty(), "typhoon judging: a rain cloud over the warm sea / a typhoon over the very warm sea / the typhoon weakened over cold water hit, the other places and seas miss (Puppy's line), the wrong sea says the doc's \"…바다를 골라 봐!\"; not judged while held or still changing; the last stage starts from the typhoon",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the sea button -------------------------------------------------------------------------------

func check_sea_button() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	for i in 3:
		var groups := ConditionPicks.groups(definition, i)
		if groups.size() != 1 or groups[0].control != "sea" or groups[0].presets.size() != 3:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	if lab.control_value("sea") != "warm" or lab.model.input("sea") != TyphoonModel.WARM:
		problems.append("the start is not the warm sea")
	var wisps := {}
	var colors := {}
	for sea: String in ["cold", "warm", "hot"]:
		lab.model.set_input("x", SEA.x)
		var resets := lab.reset_count
		lab.set_control("sea", sea)
		if lab.reset_count != resets + 1 or lab.status() != "ready" or lab.model.input("x") != TyphoonModel.CLOUD_START.x:
			problems.append("%s did not start the run over" % sea)
		wisps[sea] = lab.props.shown_wisps
		colors[sea] = TyphoonProps.sea_color(SEA.x, SEA.y, lab.model.input("sea"))
		if TyphoonProps.sea_color(COLD.x, COLD.y, lab.model.input("sea")) != TyphoonProps.COLD_SEA:
			problems.append("the cold strip is not cold on the %s sea" % sea)
	if not (wisps.cold == 0 and wisps.warm > 0 and wisps.hot > wisps.warm) or colors.cold == colors.warm or colors.warm == colors.hot:
		problems.append("the sea's look %s %s" % [str(wisps), str(colors)])
	lab.reset_run()
	if lab.model.input("sea") != TyphoonModel.HOT:
		problems.append("다시 lost the sea")
	expect.call(problems.is_empty(), "typhoon sea button: 차가운 / 따뜻한 / 아주 따뜻한 on every stage; the open sea's colour and its rising vapour follow it (none, some, more), the cold strip stays cold; a new choice starts the run over, 다시 keeps it",
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
	var words := {}
	for sea: String in ["cold", "warm", "hot"]:
		lab.set_control("sea", sea)
		for at: Vector2 in [SEA, COLD, LAND]:
			_settle(lab.model, at)
			for key: String in lab.observations():
				var value: Variant = lab.observations()[key]
				words[str(value)] = true
				if not value is String or str(value) == "" or digits.search(str(value)) != null:
					problems.append("%s at %s: %s" % [key, str(at), str(value)])
	if words.size() < 6:
		problems.append("few words %s" % str(words.keys()))
	expect.call(problems.is_empty(), "typhoon: no number on the screen (the cloud and what is under it are words, no units)", "; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

## What matters is big and in the clear on the phone's, the desktop's and the tablet's front view:
## the small cloud's start, where the hand guide takes it (the open sea), the typhoon at its start
## (its whole spiral) and where the guide takes it (the cold strip), the cold strip's middle and the
## island, between the top band (TOP_FREE) and the bottom (BOTTOM_FREE) and inside the sides; the
## typhoon spans STORM_MIN of the width or more.
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
		var m := Manipulator.new()
		view.viewport.add_child(m)
		m.setup(view, lab)
		for i in 2:
			await tree.process_frame
		var per_unit := Vector2(view.viewport.size) / view.size
		var at := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit / size
		var inside := func(world: Vector3, what: String) -> void:
			var p: Vector2 = at.call(world)
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < TOP_FREE or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
			elif p.x < STRIP_RIGHT / size.x and p.y < STRIP_BOTTOM:
				problems.append("%s: %s under the mission strip at %s" % [str(size), what, str(p)])
		var cloud := func(xz: Vector2, radius: float, what: String) -> void:
			var c := TyphoonProps.cloud_point(xz.x, xz.y)
			for d: Vector3 in [Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
				inside.call(c + d * radius, what)
		cloud.call(TyphoonModel.CLOUD_START, TyphoonProps.Cloud.SMALL_R, "the small cloud's start")
		var guide: Dictionary = m.guide()
		var to: Vector3 = guide.get("to", Vector3.ZERO)
		cloud.call(Vector2(to.x, to.z), TyphoonProps.Cloud.RAIN_R, "the stage 1 guide's end")
		if TyphoonModel.place_at(to.x, to.z) != "sea":
			problems.append("%s: the stage 1 guide ends on %s" % [str(size), TyphoonModel.place_at(to.x, to.z)])
		inside.call(Vector3(TyphoonModel.ISLAND_CENTER.x, TyphoonProps.ISLAND_TOP, TyphoonModel.ISLAND_CENTER.y), "the island")
		lab.set_game_stage(TyphoonLab.STORM_STAGE, 2, false)
		cloud.call(TyphoonModel.STORM_START, TyphoonProps.Cloud.SWIRL_R, "the typhoon")
		var c := TyphoonProps.cloud_point(TyphoonModel.STORM_START.x, TyphoonModel.STORM_START.y)
		var width: float = (at.call(c + Vector3.RIGHT * TyphoonProps.Cloud.SWIRL_R) as Vector2).x - (at.call(c + Vector3.LEFT * TyphoonProps.Cloud.SWIRL_R) as Vector2).x
		if width < STORM_MIN:
			problems.append("%s: the typhoon spans %.2f of the width" % [str(size), width])
		guide = m.guide()
		to = guide.get("to", Vector3.ZERO)
		# The cloud weakens there: from a rain cloud's size down to a small one, clear of the strip.
		cloud.call(Vector2(to.x, to.z), TyphoonProps.Cloud.RAIN_R, "the stage 3 guide's end")
		if TyphoonModel.place_at(to.x, to.z) != "cold":
			problems.append("%s: the stage 3 guide ends on %s" % [str(size), TyphoonModel.place_at(to.x, to.z)])
		# The rainbow of the last stamp rises clear of the weakened cloud there.
		var bow := TyphoonGame.rainbow_at(to.x)
		var arch := Rect2(at.call(bow + Vector3.LEFT * TyphoonGame.RAINBOW_R), Vector2.ZERO)
		for p: Vector3 in [Vector3.RIGHT * TyphoonGame.RAINBOW_R, Vector3.UP * TyphoonGame.RAINBOW_R]:
			arch = arch.expand(at.call(bow + p))
		var weak := TyphoonProps.cloud_point(to.x, to.z)
		var puff := Rect2(at.call(weak + Vector3.LEFT * TyphoonProps.Cloud.SMALL_R), Vector2.ZERO)
		for d: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.DOWN]:
			puff = puff.expand(at.call(weak + d * TyphoonProps.Cloud.SMALL_R))
		if arch.intersects(puff):
			problems.append("%s: the rainbow %s meets the weakened cloud %s" % [str(size), str(arch), str(puff)])
		seen.append("%s typhoon %.2f wide" % [str(size), width])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "typhoon in view: the small cloud's start and the stage 1 guide's end (open sea), the typhoon (%.0f%% of the width or more) and the stage 3 guide's end (cold strip) and the island between the top band (%.0f%%) and the bottom %.0f%%, none under the mission strip; the last rainbow clear of the weakened cloud (phone, desktop and tablet)" % [STORM_MIN * 100.0, TOP_FREE * 100.0, (1.0 - BOTTOM_FREE) * 100.0],
		"; ".join(problems.slice(0, 5) + seen))


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["cloud_grows", "cloud_stays"]
	var pick_kinds := ["sea_cold", "sea_warm", "sea_hot"]
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
		"typhoon pictures: the question's cloud kinds (PredictPictures) and the sea kinds (PickPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[6]) != ID:
		problems.append("typhoon is not hutton's seventh spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if hutton.playable():
		problems.append("hutton is playable before all its spots are labs")
	expect.call(problems.is_empty(), "typhoon: Hutton Island's seventh spot is an experiment (a lab on its map); the island is not playable until every spot is", "; ".join(problems))


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
	var first_ok := told == [[Story.KEEPER, "worried"], ["puppy", "worried"], ["dugi", "explain"], ["dugi", "explain"]] \
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
		"typhoon opening: first visit the fox (worried), Puppy's worried clue, Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the hand -------------------------------------------------------------------------------------

func check_drag() -> void:
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
	var start := TyphoonProps.cloud_point(lab.model.input("x"), lab.model.input("z"))
	# A press on the cloud's edge (not its middle) picks it.
	var at: Vector2 = screen.call(start + Vector3(-0.5, 0.3, 0.0))
	m.handle_pointer("press", at)
	if m.mode != "drag" or m.active_id != TyphoonLab.KNOB_ID or lab.holding != TyphoonLab.KNOB_ID:
		problems.append("press on the cloud: mode '%s' id '%s'" % [m.mode, m.active_id])
	var goal := TyphoonProps.cloud_point(SEA.x, SEA.y)
	var shift: Vector2 = screen.call(goal) - screen.call(start)
	m.handle_pointer("move", at + shift * 0.5)
	m.handle_pointer("move", at + shift)
	await tree.process_frame
	var held := Vector2(lab.model.input("x"), lab.model.input("z"))
	if held.distance_to(SEA) > 0.6 or lab.settled():
		problems.append("held at %s (want %s)" % [str(held), str(SEA)])
	m.handle_pointer("release", at + shift)
	var placed := Vector2(lab.model.input("x"), lab.model.input("z"))
	for i in 20:
		await tree.physics_frame
	if Vector2(lab.model.input("x"), lab.model.input("z")) != placed or lab.holding != "" or not lab.placements().has(TyphoonLab.KNOB_ID):
		problems.append("put down: it moved on, or holding '%s'" % lab.holding)
	if lab.model.input("size") <= TyphoonModel.SMALL or not lab.model.animating() or lab.settled():
		problems.append("it does not grow over the warm sea after the put-down (%.3f)" % lab.model.input("size"))
	if lab.props.cloud.position.distance_to(TyphoonProps.cloud_point(placed.x, placed.y)) > 1e-4:
		problems.append("the cloud is not drawn where it was put")
	var saved: Dictionary = lab.placements()
	var other := _lab()
	tree.root.add_child(other)
	await tree.process_frame
	other.manipulation_placed(TyphoonLab.KNOB_ID, saved[TyphoonLab.KNOB_ID])
	if Vector2(other.model.input("x"), other.model.input("z")).distance_to(placed) > 1e-3:
		problems.append("restored at %s" % str(Vector2(other.model.input("x"), other.model.input("z"))))
	other.queue_free()
	await tree.process_frame
	var before := Vector2(lab.model.input("x"), lab.model.input("z"))
	at = screen.call(TyphoonProps.cloud_point(before.x, before.y))
	m.handle_pointer("press", at)
	m.handle_pointer("move", at + Vector2(-120.0, -30.0))
	await tree.process_frame
	m.handle_pointer("cancel", at + Vector2(-120.0, -30.0))
	if Vector2(lab.model.input("x"), lab.model.input("z")).distance_to(before) > 1e-3 or lab.holding != "":
		problems.append("cancel left it at %s" % str(Vector2(lab.model.input("x"), lab.model.input("z"))))
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != TyphoonLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "typhoon hand: a press on the cloud picks it, it follows the finger over the sea, a put-down keeps it there (and restores) and it starts to grow, a cancel puts it back; the hand guide drags it",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: TyphoonGame = lab.game
	var problems := []
	await tree.process_frame
	var eye := TyphoonProps.cloud_point(TyphoonModel.STORM_START.x, TyphoonModel.STORM_START.y)
	if game.piece_state != "held" or not game.piece.visible or game.piece.global_position.distance_to(eye) > 0.5 or not game.storm.visible or game.rainbow.visible:
		problems.append("not in the typhoon's eye at the start")
	game.show_stage(1, 1, true)
	lab.set_game_stage(1, 1, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or not game.storm.visible:
		problems.append("out after stage 1 (%s)" % game.piece_state)
	lab.set_game_stage(2, 2, true)
	if lab.storm_run() or not lab.model.input("size") < TyphoonModel.TYPHOON:
		problems.append("the run changed before the next mission")
	lab.reset_run()
	await tree.process_frame
	if not lab.storm_run() or game.storm.visible or game.piece.global_position.distance_to(lab.props.cloud.global_position) > 0.5:
		problems.append("the last stage's typhoon is not the lab's cloud with the piece")
	_settle(lab.model, COLD)
	lab._show()
	await tree.process_frame
	if game.piece.global_position.distance_to(lab.props.cloud.global_position) > 0.5:
		problems.append("the piece did not ride in the typhoon")
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or not game.rainbow.visible or absf(rest.y - TyphoonProps.ISLAND_TOP - LabGame.PIECE_SIZE) > 0.12 \
			or TyphoonModel.place_at(rest.x, rest.z) != "land" or game.storm.visible:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	await tree.process_frame
	var g2: TyphoonGame = again.game
	if g2.take_piece() != null or not g2.rainbow.visible or g2.storm.visible:
		problems.append("a finished spot: a piece, no rainbow, or the typhoon still there")
	expect.call(problems.is_empty(), "typhoon piece: the piece glints in the big typhoon's eye; the last stage's run is that typhoon, the piece riding in it to the cold water; on the last stamp it jumps onto the island by the cat and a rainbow rises; a finished spot shows the rainbow, no typhoon, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
