## 강물이 깎고 쌓기 (#95, 2026-11-07; Hutton Island's eighth spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after day-night),
##   not one of the first island's; the bend picture (ExplainPictures "river") on stage 3's explanation
##   alone, where hutton-lines.md 8 has its "[그림: …]"; the question's and the slope buttons' pictures
##   are code-drawn kinds; its Korean lines are docs/islands/hutton-lines.md section 8 word for word
##   (the fox's line, Puppy's clue, Dugi's two lines, the question, its choices, reason and bridge, the
##   riddle, every stage's condition, mission, explanation, win, miss and wrong-condition line) with the
##   doc's faces, and the stages' conditions are hutton-missions.md 8's; Puppy's result lines are short
##   with no science words, digits or symbols; English has every line;
## - the rules (RiverModel): steep land cuts deeper than gentle land at any rain, and only the steep
##   land's cut gets DEEP; gentle land drops its sand (the mouth's bar and the bend's inner bar grow),
##   steep land washes it to sea (no bar, the plume); the gentle land's bend loses its outer bank and the
##   steep land's keeps it; every amount grows with the rain; "ready" until it rains; the gentle land's
##   bar comes before its bank;
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's miss line), the
##   wrong slope's line, nothing while it rains;
## - the condition button: 완만 / 가파름 (picture buttons on every stage) set the slope (the mountain's
##   face drawn at it) and start the run over (no rain on the land);
## - no number on the screen: the observations are words, no units, the card is what the river did;
## - what matters is big and in view on the phone, the desktop and the tablet, clear of the dialogue
##   box, the top band and the buttons: the cloud (big), the mountain's channel, the heap, the bank's
##   face where the piece is, the bend's inner bar and the mouth's bar;
## - the spot: the hutton map's river spot is this experiment, the island is still not playable;
## - the opening (the fox first on a first visit), the hand (a press on the cloud holds it: it rains
##   at the fixed step while held, the land stays when the finger lets go, the presses add up; the
##   hand guide shows a hold) and the piece (in the bank until the last stamp; the heap washed away
##   at the first, the turtle at the second).
extends RefCounted

const ID := "river"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const UI_THEME := "res://scripts/app/ui_theme.gd"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
## The phone (2340 x 1080), a desktop window (1920 x 1080) and the tablet (1920 x 1200) in UI units.
const PHONE := Vector2(1560, 720)
const DESKTOP := Vector2(1280, 720)
const TABLET := Vector2(1152, 720)
const LINE_MAX := 24
## The cloud's radius on the screen at least this many UI units (a child's finger finds it at once).
const CLOUD_MIN := 45.0
## A spot must be this far inside the view's edges and clear of the boxes (UI units, its half size).
const SPOT := 14.0
const EDGE := 8.0

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
	check_rules()
	await check_judging()
	await check_condition_button()
	await check_no_numbers()
	for size: Vector2 in [PHONE, DESKTOP, TABLET]:
		await check_view(size)
	check_spot()
	await check_pictures()
	check_opening()
	await check_hold()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> RiverLab:
	var lab := RiverLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## `seconds` of rain on `lab` (as a held cloud would give them).
static func _rain(lab: RiverLab, seconds: float) -> void:
	lab.model.set_input("rain", 0.0)
	(lab.model as RiverModel).rain_for(seconds)
	lab._show()


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "river: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or island.find(ID) < island.find("day-night"):
		problems.append("hutton's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var kid: Dictionary = definition.kid
	var stages: Array = definition.missions.stages
	if kid.has("intro_picture") or kid.intro_more.any(func(l: Dictionary) -> bool: return l.has("picture")):
		problems.append("an explanation picture on Dugi's opening (the doc has none there)")
	for i in stages.size():
		var want := "river" if i == 2 else ""
		if ExplainPictures.picture_or_none(stages[i].get("say_picture")) != want:
			problems.append("stage %d's picture %s" % [i + 1, str(stages[i].get("say_picture"))])
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var picks: Array = kid.picks.slope
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["gentle", "steep"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS) or float(picks[0].size) >= float(picks[1].size):
		problems.append("the slope buttons %s" % str(picks))
	if definition.manipulation.objects.size() != 1 or definition.manipulation.objects[0].get("hold") != true or definition.manipulation.objects[0].id != RiverLab.KNOB_ID:
		problems.append("the cloud is not a hold object: %s" % str(definition.manipulation.objects))
	expect.call(problems.is_empty(), "river: a valid definition, a Hutton Island lab after day-night (index.json islands), not the first island's; the bend picture on stage 3's explanation alone; code-drawn question and slope pictures (gentle drawn lower); the cloud is a hold object",
		"; ".join(problems))


## The section "## 8. 강물이 깎고 쌓기" of the lines doc: its numbered lines [who, face, text], the
## question, the riddle, the stage table's rows (cells), the "[그림: …]" notes cut off and counted.
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 8. 강물이 깎고 쌓기")
	var end := text.find("\n## ", start + 4)
	var out := {"lines": [], "rows": [], "question": {}, "pictures": 0}
	if start < 0:
		return out
	var said := RegEx.create_from_string("^\\d+\\. (\\S+)\\((\\S+)\\): (.+)$")
	var asked := RegEx.create_from_string("^\\d+\\. 질문\\((\\S+), (\\S+)\\): (.+)$")
	var picture := RegEx.create_from_string(" ?\\[그림: [^\\]]*\\]")
	for raw in text.substr(start, end - start).split("\n"):
		if raw.contains("[그림:"):
			out.pictures += 1
		var line := picture.sub(raw.strip_edges(), "", true)
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


## The conditions of hutton-missions.md 8's stage table (the second column of each row).
func _missions_conditions() -> Array:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 8. 강물이 깎고 쌓기")
	var end := text.find("\n### ", start + 4)
	var out := []
	for raw in text.substr(start, end - start).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			out.append(line.split("|")[2].strip_edges())
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
	if doc.pictures != 1:
		problems.append("the doc has %d pictures now (one: stage 3's bend)" % doc.pictures)
	var predict := MissionRound.predict(definition)
	var q: Dictionary = doc.question
	var labels: Array = predict.choices.map(func(c: Dictionary) -> String: return str(c.label))
	var answer: int = predict.choices.map(func(c: Dictionary) -> String: return str(c.id)).find(str(predict.answer))
	if predict.question != q.get("text") or predict.get("question_face") != faces.get(q.get("face")) or labels != q.get("choices") \
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[0] != "가파른 곳":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.slope:
		pick_label[p.value] = p.label
	var missions := _missions_conditions()
	if doc.rows.size() != 3 or missions.size() != 3:
		problems.append("%d doc rows, %d mission rows" % [doc.rows.size(), missions.size()])
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var condition := str(pick_label.get(stage.conditions.slope, "?"))
			var got := [str(i + 1), condition, stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			var row: Array = doc.rows[i].duplicate()
			row[3] = RegEx.create_from_string(" ?\\[그림: [^\\]]*\\]").sub(row[3], "", true)
			if got != row:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(row)])
			if condition != missions[i]:
				problems.append("stage %d's condition %s (missions doc %s)" % [i + 1, condition, missions[i]])
	expect.call(problems.is_empty(), "river: the Korean lines are hutton-lines.md 8 word for word (the fox, Puppy, Dugi's two lines, the question, the riddle, the three stages with their conditions and wrong-condition lines) with its faces; the conditions are hutton-missions.md 8's",
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
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/river.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/river.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.slope.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "river: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the rules ------------------------------------------------------------------------------------

func check_rules() -> void:
	var problems := []
	var gentle := RiverModel.new()
	gentle.set_start("slope", RiverModel.GENTLE_DEG)
	var steep := RiverModel.new()
	if gentle.status() != "ready" or steep.status() != "ready" or not steep.steep() or gentle.steep():
		problems.append("the start: %s / %s" % [gentle.status(), steep.status()])
	if not (steep.speed() > gentle.speed() and steep.power() > gentle.power()):
		problems.append("the steep land's water is not faster")
	var before := {}
	var first := {"bar": INF, "bank": INF, "valley": INF}
	var rain := 0.05
	while rain <= RiverModel.RAIN_MAX + 1e-9:
		gentle.set_input("rain", rain)
		steep.set_input("rain", rain)
		# Steep land cuts deeper; only it gets DEEP.
		if steep.valley_depth() <= gentle.valley_depth() or gentle.valley_depth() >= RiverModel.DEEP:
			problems.append("%.2f s: valley %.3f steep / %.3f gentle" % [rain, steep.valley_depth(), gentle.valley_depth()])
		# Gentle land drops its sand, steep land washes it to sea.
		if gentle.mouth_bar() <= 0.0 or gentle.inner_bar() <= 0.0 or steep.mouth_bar() != 0.0 or steep.inner_bar() != 0.0 or steep.washed() <= 0.0 or gentle.washed() != 0.0:
			problems.append("%.2f s: sand gentle %.3f/%.3f steep %.3f/%.3f washed %.3f" % [rain, gentle.mouth_bar(), gentle.inner_bar(), steep.mouth_bar(), steep.inner_bar(), steep.washed()])
		# The gentle land's bend loses its outer bank, the steep land's keeps it.
		if gentle.bank_cut() <= 0.0 or steep.bank_cut() != 0.0:
			problems.append("%.2f s: bank gentle %.3f steep %.3f" % [rain, gentle.bank_cut(), steep.bank_cut()])
		# Every amount grows with the rain.
		var now := [gentle.mouth_bar(), gentle.inner_bar(), gentle.bank_cut(), gentle.valley_depth(), steep.valley_depth(), steep.washed()]
		if not before.is_empty():
			for k in now.size():
				if now[k] <= before.now[k]:
					problems.append("%.2f s: amount %d did not grow" % [rain, k])
		before.now = now
		for model: RiverModel in [gentle, steep]:
			var s := model.status()
			if s in first:
				first[s] = minf(first[s], rain)
			if model == steep and s in ["bar", "bank"] or model == gentle and s == "valley":
				problems.append("%.2f s: %s on the %s land" % [rain, s, "steep" if model == steep else "gentle"])
		rain += 0.05
	if not (first.bar < first.bank and first.valley < RiverModel.RAIN_MAX and first.bank < RiverModel.RAIN_MAX):
		problems.append("first reached %s" % str(first))
	# The rain adds up and stops at RAIN_MAX.
	var m := RiverModel.new()
	m.rain_for(1.0)
	m.rain_for(1.5)
	var added := m.input("rain")
	m.rain_for(100.0)
	if absf(added - 2.5) > 1e-9 or m.input("rain") != RiverModel.RAIN_MAX:
		problems.append("rain adds %.3f, tops at %.3f" % [added, m.input("rain")])
	m.reset()
	if m.status() != "ready":
		problems.append("a reset keeps the rain")
	expect.call(problems.is_empty(),
		"river rules: steep land cuts deeper at any rain and only it gets the deep valley (%.1f s of rain); gentle land drops its sand (the bar %.1f s, the inner bar) while steep land washes it to sea; the gentle bend loses its outer bank (%.1f s), the steep one keeps it; everything grows with the rain, which adds up" % [first.valley, first.bar, first.bank],
		"; ".join(problems.slice(0, 6)))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, slope, seconds of rain, hit, missed]
	var cases := [
		[0, "steep", 3.0, true, false], [0, "steep", 0.8, false, true], [0, "gentle", 6.0, false, true], [0, "gentle", 0.8, false, true],
		[1, "gentle", 2.0, true, false], [1, "gentle", 5.0, true, false], [1, "gentle", 0.6, false, true], [1, "steep", 6.0, false, true], [1, "steep", 0.5, false, true],
		[2, "gentle", 4.0, true, false], [2, "gentle", 2.0, false, true], [2, "gentle", 0.5, false, true], [2, "steep", 8.0, false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_control("slope", case[1])
		_rain(lab, float(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s %.1f s (%s): stamps %d missed %s" % [stage + 1, case[1], case[2], status, stamps, missed])
	var wants := [["steep", "가파른 땅을 골라 봐!"], ["gentle", "완만한 땅을 골라 봐!"], ["gentle", "완만한 땅을 골라 봐!"]]
	for i in 3:
		lab.set_control("slope", "gentle" if wants[i][0] == "steep" else "steep")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong condition says '%s'" % [i + 1, line[0]])
	lab.set_control("slope", "steep")
	lab.hold_started(RiverLab.KNOB_ID)
	(lab.model as RiverModel).rain_for(4.0)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while it rains")
	lab.hold_ended(RiverLab.KNOB_ID)
	if not lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("not judged after the rain (%s)" % lab.status())
	expect.call(problems.is_empty(), "river judging: the deep valley (steep) / the sand bar (gentle) / the cut outer bank (gentle) hit with enough rain and miss short of it (Puppy's line), the wrong slope says the doc's \"…땅을 골라 봐!\" line; not judged while it rains",
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
		if groups.size() != 1 or groups[0].control != "slope" or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	var top := func() -> float: return RiverProps.height_at(lab.props.shown_slope, 0.0, 0.0, RiverProps.TOP_X, RiverProps.CHANNEL_Z + 1.0)
	if lab.control_value("slope") != "steep" or lab.model.input("slope") != RiverModel.STEEP_DEG or lab.props.shown_slope != RiverModel.STEEP_DEG:
		problems.append("the start is not the steep land")
	var steep_top: float = top.call()
	_rain(lab, 2.0)
	var resets := lab.reset_count
	lab.set_control("slope", "gentle")
	if lab.model.input("slope") != RiverModel.GENTLE_DEG or lab.props.shown_slope != RiverModel.GENTLE_DEG or lab.reset_count != resets + 1 \
			or lab.model.input("rain") != 0.0 or lab.status() != "ready" or float(top.call()) >= steep_top * 0.5:
		problems.append("gentle: slope %.1f drawn %.1f, rain %.2f, %s, top %.2f (steep %.2f)" % [lab.model.input("slope"), lab.props.shown_slope, lab.model.input("rain"), lab.status(), top.call(), steep_top])
	_rain(lab, 1.0)
	lab.reset_run()
	if lab.model.input("slope") != RiverModel.GENTLE_DEG or lab.model.input("rain") != 0.0:
		problems.append("다시 lost the condition or kept the rain")
	expect.call(problems.is_empty(), "river condition button: 완만 / 가파름 on every stage; the mountain drawn at the slope (the gentle one less than half as high), a new choice starts the run over with no rain, 다시 keeps it",
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
	for slope: String in ["steep", "gentle"]:
		lab.set_control("slope", slope)
		for seconds: float in [0.0, 0.6, 2.5, 6.0]:
			_rain(lab, seconds)
			for key: String in lab.observations():
				var value: Variant = lab.observations()[key]
				if not value is String or str(value) == "" or digits.search(str(value)) != null:
					problems.append("%s %s at %.1f s: %s" % [key, slope, seconds, str(value)])
	expect.call(problems.is_empty(), "river: no number on the screen (the observations are words, no units, the card is what the river did)",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the view -------------------------------------------------------------------------------------

## On a phone, a desktop and a tablet, with the dialogue box open (the first line), the things a child
## must follow are on the view and clear of the box, its bust, the top band (the title, the card, the
## mission strip) and the buttons: the cloud (its middle and its foot, big), the channel down the
## steep mountain, the heap, the bank's face where the piece is, the bend's inner bar and the mouth.
func check_view(size: Vector2) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(_definition())
	host.add_child(screen)
	for i in 30:
		await tree.process_frame
	var lab: RiverLab = screen.experiment
	var view: View3D = screen.view
	var per_unit := Vector2(view.viewport.size) / view.size
	var box: DialogueBox = screen.dialogue
	var blocks: Array[Rect2] = []
	if box.active and box.visible:
		blocks.append_array(box.rects())
	for c: Control in [screen._title_bar, screen._key_row, screen._mission_pill, screen._mission_strip, screen._mission_text, screen._top_buttons, screen._action_row, screen._picks_row]:
		if c != null and c.is_visible_in_tree():
			blocks.append(c.get_rect())
	var steep := RiverModel.STEEP_DEG
	var line := RiverProps.river_line()
	var inner := RiverProps.bank_face(0.0) - Vector3(RiverProps.outward(line, RiverProps.bend_samples(line)[RiverProps.bend_samples(line).size() / 2]).x, 0.0, RiverProps.outward(line, RiverProps.bend_samples(line)[RiverProps.bend_samples(line).size() / 2]).y) * 1.2
	var mouth: Vector2 = lab.props.mouth()
	var points := {
		"cloud": RiverProps.CLOUD_AT,
		"cloud's foot": RiverProps.CLOUD_AT + Vector3.DOWN * RiverProps.CLOUD_RADIUS * 0.6,
		"channel's top": RiverProps.channel_point(steep, 0.0, 1.0, RiverProps.TOP_X - 0.4),
		"channel's middle": RiverProps.channel_point(steep, 0.0, 1.0, (RiverProps.TOP_X + RiverProps.FOOT_X) * 0.5),
		"heap": Vector3(RiverProps.HEAP_AT.x, RiverProps.HEAP_HEIGHT, RiverProps.HEAP_AT.y),
		"bank's face (the piece)": RiverProps.bank_face(0.0) + Vector3.UP * RiverGame.PIECE_UP,
		"inner bar": inner,
		"mouth": Vector3(mouth.x, 0.0, mouth.y),
	}
	var view_rect := Rect2(Vector2.ZERO, view.size).grow(-EDGE)
	var problems := []
	for name: String in points:
		var at: Vector2 = view.rig.unproject_position(points[name]) / per_unit
		var spot := Rect2(at - Vector2(SPOT, SPOT), Vector2(SPOT, SPOT) * 2.0)
		if not view_rect.encloses(spot):
			problems.append("%s off the view at %s" % [name, str(at)])
		for r in blocks:
			if r.intersects(spot):
				problems.append("%s at %s under %s" % [name, str(at), str(r)])
	var c: Vector2 = view.rig.unproject_position(RiverProps.CLOUD_AT) / per_unit
	var e: Vector2 = view.rig.unproject_position(RiverProps.CLOUD_AT + Vector3.RIGHT * RiverProps.CLOUD_RADIUS) / per_unit
	if c.distance_to(e) < CLOUD_MIN:
		problems.append("the cloud is small (%.0f units)" % c.distance_to(e))
	var name: String = {PHONE: "phone", DESKTOP: "desktop", TABLET: "tablet"}.get(size, str(size))
	expect.call(box.active and problems.is_empty(), "river view (%s): the cloud (big), the steep mountain's channel, the heap, the bank's face with the piece, the inner bar and the mouth are on the view, clear of the dialogue box, the top band and the buttons" % name,
		"box %s; cloud %.0f units; %s" % [box.active, c.distance_to(e), "; ".join(problems.slice(0, 6))])
	host.queue_free()
	for i in 3:
		await tree.process_frame


# --- the pictures ---------------------------------------------------------------------------------

## The question's cut pictures (PredictPictures) and the slope buttons (PickPictures) draw on a canvas
## of their button's size without errors.
func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["cut_steep", "cut_flat"]
	for kind: String in predict_kinds + ["slope"]:
		var draw := func() -> void:
			if kind in predict_kinds:
				PredictPictures.draw(canvas, kind)
			else:
				PickPictures.draw(canvas, kind, 0.9)
			drawn.append(kind)
		canvas.draw.connect(draw)
		canvas.queue_redraw()
		await tree.process_frame
		canvas.draw.disconnect(draw)
	canvas.queue_free()
	var listed := predict_kinds.all(func(k: String) -> bool: return k in PredictPictures.KINDS)
	expect.call(listed and drawn == predict_kinds + ["slope"],
		"river pictures: the question's cut kinds (PredictPictures) are listed and draw, and so does the slope button",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[7]) != ID:
		problems.append("river is not hutton's eighth spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if hutton.playable():
		problems.append("hutton is playable before all its spots are labs")
	expect.call(problems.is_empty(), "river: Hutton Island's eighth spot is an experiment (a lab on its map); the island is not playable until every spot is", "; ".join(problems))


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
	var first_ok := told == [[Story.KEEPER, "worried"], ["puppy", "thinking"], ["dugi", "explain"], ["dugi", "explain"]] \
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
		"river opening: first visit the fox (worried), Puppy's clue, Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


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
	var screen := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit
	var problems := []
	# A press on the cloud's left puff (not its middle) holds it: it rains.
	var at: Vector2 = screen.call(RiverProps.CLOUD_AT + Vector3(-0.9, -0.1, 0.0))
	m.handle_pointer("press", at)
	if m.mode != "hold" or m.active_id != RiverLab.KNOB_ID or lab.holding != RiverLab.KNOB_ID or not lab.raining or not lab.props.rain.visible:
		problems.append("press on the cloud: mode '%s' id '%s' raining %s" % [m.mode, m.active_id, lab.raining])
	var steps := 45
	for i in steps:
		await tree.physics_frame
	var rained: float = lab.model.input("rain")
	if absf(rained - lab.step_count / float(Engine.physics_ticks_per_second)) > 1e-9 or rained < (steps - 2) / float(Engine.physics_ticks_per_second) or lab.settled():
		problems.append("held %d steps: rain %.4f (%d steps counted), settled %s" % [steps, rained, lab.step_count, lab.settled()])
	m.handle_pointer("release", at)
	var after: float = lab.model.input("rain")
	for i in 20:
		await tree.physics_frame
	if lab.model.input("rain") != after or lab.raining or lab.holding != "" or not lab.settled() or lab.props.rain.visible:
		problems.append("after the let-go: rain %.4f -> %.4f, raining %s" % [after, lab.model.input("rain"), lab.raining])
	# The next press goes on from there; a cancel stops the rain too.
	m.handle_pointer("press", at)
	for i in 30:
		await tree.physics_frame
	m.handle_pointer("cancel", at)
	if lab.model.input("rain") <= after + 0.4 or lab.raining or lab.holding != "":
		problems.append("the second press: rain %.4f (was %.4f)" % [lab.model.input("rain"), after])
	# A press far from the cloud does nothing.
	m.handle_pointer("press", screen.call(Vector3(-5.0, 0.0, 2.0)))
	if m.mode != "" or lab.raining:
		problems.append("a press on the sea holds '%s'" % m.mode)
	m.handle_pointer("release", Vector2.ZERO)
	var guide := m.guide()
	if guide.get("kind", "") != "hold" or guide.get("id", "") != RiverLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "river hand: a press on the cloud holds it and it rains one fixed step at a time (not settled), the let-go stops it and keeps the land, a second press adds more, a cancel stops it, a press elsewhere does nothing; the hand guide shows a hold on the cloud",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: RiverGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or start.distance_to(RiverProps.bank_face(0.0)) > 0.8 or game.turtle_out() or game.heap_gone():
		problems.append("not in the bank at the start (or a turtle, or no heap)")
	# Cutting the bank brings the piece out of the face (it stays with the face).
	lab.set_control("slope", "gentle")
	_rain(lab, 6.0)
	await tree.process_frame
	var cut: Vector3 = game.piece.global_position
	if game.piece_state != "held" or cut.distance_to(start) < lab.props.shown_retreat * 0.5:
		problems.append("the piece did not follow the cut face (%.2f m)" % cut.distance_to(start))
	game.show_stage(1, 1, true)
	for i in 80:
		await tree.process_frame
	if not game.heap_gone():
		problems.append("the heap is still there after stage 1")
	game.show_stage(2, 2, true)
	for i in 60:
		await tree.process_frame
	if not game.turtle_out() or game.turtle.scale.x < 0.99 or game.piece_state != "held":
		problems.append("no turtle after stage 2, or the piece out early (%s)" % game.piece_state)
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or absf(rest.y - LabGame.PIECE_SIZE) > 0.12 or rest.distance_to(cut) < 1.0:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	var done: RiverGame = again.game
	if done.take_piece() != null or not done.turtle_out() or not done.heap_gone():
		problems.append("a finished spot: a piece, no turtle or a heap")
	expect.call(problems.is_empty(), "river piece: buried in the bend's outer bank (it comes out with the cut face) until the last stamp, then it jumps out onto the plain for the cat; the heap washes away at the first stamp, the turtle comes at the second; a finished spot shows them, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
