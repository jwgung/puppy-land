## 지층 쌓기 (#96, 2026-11-07; Hutton Island's ninth spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after seasons), not
##   one of the first island's; no condition buttons (hutton-missions.md 9: 없음); no explanation picture
##   (hutton-lines.md 9 has no "[그림: …]"); the question's pictures are code-drawn kinds; its Korean
##   lines are docs/islands/hutton-lines.md section 9 word for word (the fox's line, Puppy's clue, Dugi's
##   two lines, the question, its choices, reason and bridge, the riddle, every stage's mission,
##   explanation, win and miss line; the stages have no wrong-condition line, "—") with the doc's faces;
##   Puppy's result lines are short with no science words, digits or symbols; his stage 3 win foreshadows
##   the volcano; English has every line;
## - the model (a rule, no formula): every pour lies on what is there, so the first one poured is the
##   bottom layer whatever the order; the shell is in the layer poured after it; the statuses of the
##   tank (stacking, layered, fossil, mixed, shell_off) and the cliff (found under the ash, dug_off); a
##   done or wrong tank is washed out by the next pour; a reset empties it;
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's miss line), nothing
##   while a pour settles or a bucket is held;
## - each stage's objects: the buckets in stages 1 and 2, the shell in stage 2, the cliff in stage 3, all
##   outside a round; the hand guide shows the stage's gesture (a drag, then a tap on the cliff);
## - no number on the screen: the observations are words, the card is the state;
## - on the real screen (phone, desktop, tablet): Puppy (with his flag) and Dugi whole inside the view,
##   the pouring bucket clear of the title, the card, the mission strip (each stage's text) and 자세히;
## - what matters is big and in view: the buckets, the shell, the tank and every cliff layer inside the
##   phone's, the desktop's and the tablet's front view, above the bottom (the dialogue box) and the
##   left ones under the top band; a cliff layer and a bucket big enough for a finger;
## - the spot: the hutton map's strata spot is this experiment;
## - the opening (the fox first on a first visit), the hand (a bucket dragged onto the tank pours, let go
##   elsewhere it goes back, a tap on a cliff layer digs it) and the piece (hidden in the cliff until the
##   last stamp, then out of its hole).
extends RefCounted

const ID := "strata"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const UI_THEME := "res://scripts/app/ui_theme.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
const EDGE := 0.03
const BOTTOM_FREE := 0.8
## The left part of the view (the title, the card and the mission strip over it) and its band's bottom.
const TOP_FREE := 0.33
const LEFT_BAND := 0.5
## The right top's 자세히 button.
const RIGHT_TOP := 0.14
## A cliff layer at least this tall and a bucket at least this wide on the screen (UI units): a finger.
const LAYER_MIN := 40.0
const BUCKET_MIN := 40.0
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
	check_rule()
	check_model()
	await check_judging()
	await check_stage_objects()
	await check_no_numbers()
	await check_in_view()
	for size: Vector2 in [PHONE, DESKTOP, TABLET]:
		await check_screen(size)
	check_spot()
	await check_pictures()
	check_opening()
	await check_hand()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> StrataLab:
	var lab := StrataLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## Lets the newest pour or dent settle (the model's glides).
static func _settle(model: StrataModel) -> void:
	while model.animating():
		model.step(1.0 / 60.0)


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "strata: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or island.find(ID) < island.find("seasons"):
		problems.append("hutton's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	if not definition.controls.is_empty() or definition.kid.has("picks"):
		problems.append("condition buttons (the doc has none)")
	var kid: Dictionary = definition.kid
	if kid.has("intro_picture") or kid.intro_more.any(func(l: Dictionary) -> bool: return l.has("picture")) \
			or definition.missions.stages.any(func(s: Dictionary) -> bool: return s.has("say_picture")):
		problems.append("an explanation picture (the doc has none)")
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var mission_doc := FileAccess.get_file_as_string(MISSIONS_PATH)
	var section := mission_doc.substr(mission_doc.find("### 9. 지층 쌓기"), 400)
	if not section.contains("**조건 단추**: 없음"):
		problems.append("hutton-missions.md 9 has condition buttons now")
	expect.call(problems.is_empty(), "strata: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; no condition buttons (hutton-missions.md 9) and no explanation picture; code-drawn question pictures",
		"; ".join(problems))


## The section "## 9. 지층 쌓기" of the lines doc: its numbered lines [who, face, text], the question, the
## riddle, the picture cards and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 9. 지층 쌓기")
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
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[0] != "맨 아래 층":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), stage.text, stage.say, stage.win, stage.miss, "—" if not stage.has("miss_conditions") else str(stage.miss_conditions)]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	# The foreshadowing (hutton-lines.md 9 "복선"): Puppy thinks of the volcano for the first time.
	if not str(stages[2].win).contains("화산") or MissionRound.result_line(definition, 2, true)[1] != "surprised":
		problems.append("stage 3's win '%s' does not foreshadow the volcano" % stages[2].win)
	expect.call(problems.is_empty(), "strata: the Korean lines are hutton-lines.md 9 word for word (the fox, Puppy, Dugi's two lines, the question, the riddle, the three stages, no wrong-condition line) with its faces; stage 3's win foreshadows the volcano",
		"; ".join(problems))


func check_result_lines() -> void:
	var problems := []
	var science := Story.science_words()
	var symbols := RegEx.create_from_string("[0-9%=+×/<>]")
	for stage: Dictionary in _definition().missions.stages:
		for key: String in ["win", "miss"]:
			var line := str(stage.get(key, ""))
			if line == "" or line.length() > LINE_MAX or symbols.search(line) != null or science.any(func(w: String) -> bool: return line.contains(w)):
				problems.append("%s '%s'" % [key, line])
	for line: String in [Story.keeper(_definition()), Story.clue(_definition()), Story.map_clue(_definition())]:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/strata.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/strata.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "strata: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

## The rule (docs/islands/hutton.md "아래 층이 먼저 쌓임"): for every order of three pours (any of the four
## buckets), the tank's layers bottom first are the pours in the order poured: the first is the bottom.
func check_rule() -> void:
	var problems := []
	var tried := 0
	for a: String in StrataModel.MATERIALS:
		for b: String in StrataModel.MATERIALS:
			for c: String in StrataModel.MATERIALS:
				var model := StrataModel.new()
				for m: String in [a, b, c]:
					if model.tank_status() in StrataModel.FINISHED:
						break
					model.pour(m)
					_settle(model)
				var poured := [a, b, c].slice(0, model.layers().size())
				tried += 1
				if model.layers() != poured or (not poured.is_empty() and model.layers()[0] != a):
					problems.append("%s: %s" % [str([a, b, c]), str(model.layers())])
	expect.call(problems.is_empty() and tried == 64, "strata rule: whatever is poured, the layers bottom first are the pours in their order (the first one poured is the bottom layer), %d orders" % tried,
		"; ".join(problems.slice(0, 4)))


func check_model() -> void:
	var problems := []
	var model := StrataModel.new()
	var steps := [
		[["gravel"], "stacking"], [["sand"], "stacking"], [["mud"], "layered"],
		[["sand"], "mixed"],                                   # a new pile (the old one washed out), sand first
		[["gravel", "sand", "ash"], "mixed"],
		[["gravel", "shell"], "stacking"], [["sand"], "stacking"], [["mud"], "fossil"],
		[["shell"], "shell_off"],                              # on the bare bottom
		[["gravel", "sand", "shell"], "shell_off"],            # on the sand: the top layer
		[["gravel", "sand", "mud"], "layered"],
		[["shell"], "shell_off"],                              # (a done pile is washed out first: the bare bottom)
	]
	for step: Array in steps:
		for what: String in step[0]:
			if what == "shell":
				model.drop_shell()
			else:
				model.pour(what)
			_settle(model)
		if model.status() != step[1]:
			problems.append("%s: %s (want %s, layers %s, shell at %d)" % [str(step[0]), model.status(), step[1], str(model.layers()), model.shell_at()])
	model.reset()
	model.pour("gravel")
	model.drop_shell()
	model.pour("sand")
	if model.shell_layer() != 1 or model.animating() == false:
		problems.append("the shell under the sand is in layer %d" % model.shell_layer())
	_settle(model)
	model.reset()
	if StrataModel.CLIFF[StrataModel.TARGET + 1] != "ash" or StrataModel.CLIFF.count("ash") != 1:
		problems.append("the piece's layer is not just under the only ash: %s" % str(StrataModel.CLIFF))
	for i in StrataModel.CLIFF.size():
		model.dig(i)
		_settle(model)
		if model.status() != ("found" if i == StrataModel.TARGET else "dug_off"):
			problems.append("dig %d: %s" % [i, model.status()])
	model.pour("gravel")
	if model.status() != "stacking" or model.layers() != ["gravel"]:
		problems.append("after a dig the tank is %s %s" % [model.status(), str(model.layers())])
	model.reset()
	if model.status() != "ready" or not model.layers().is_empty() or model.has_shell() or not model.dug.is_empty():
		problems.append("a reset left %s" % model.status())
	expect.call(problems.is_empty(), "strata model: gravel, sand, mud is layered (with the shell after the gravel a fossil in the middle layer), out of order or ash is mixed, the shell elsewhere is shell_off, a done pile is washed out by the next pour; the cliff's piece layer is just under the ash (found, the others dug_off); a reset empties all",
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, actions (a material, "shell" or a cliff index), hit, missed]
	var cases := [
		[0, ["gravel", "sand", "mud"], true, false], [0, ["gravel", "sand"], false, false], [0, ["sand"], false, true],
		[0, ["gravel", "mud"], false, true], [0, ["gravel", "ash"], false, true], [0, ["mud"], false, true],
		[1, ["gravel", "shell", "sand", "mud"], true, false], [1, ["gravel", "sand", "mud"], false, true],
		[1, ["shell"], false, true], [1, ["gravel", "sand", "shell"], false, true], [1, ["gravel", "shell"], false, false],
		[1, ["gravel", "shell", "mud"], false, true],
		[2, [StrataModel.TARGET], true, false], [2, [StrataModel.TARGET + 1], false, true], [2, [StrataModel.TARGET - 1], false, true],
		[2, [0], false, true], [2, [4], false, true], [2, ["gravel", "sand", "mud"], false, false],
		[0, [2], false, false],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.reset_run()
		for what: Variant in case[1]:
			if what is int:
				lab.model.dig(int(what))
			elif str(what) == "shell":
				lab.model.drop_shell()
			else:
				lab.model.pour(str(what))
			_settle(lab.model)
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[2]) or missed != bool(case[3]):
			problems.append("stage %d %s (%s): stamps %d missed %s" % [stage + 1, str(case[1]), status, stamps, missed])
	var lines := [["자갈부터 차례로 쏟아 봐!"], ["자갈 다음에 조개를 넣어 봐!"], ["회색 재 층 바로 아래를 파 봐!"]]
	for i in 3:
		if MissionRound.result_line(definition, i, false)[0] != lines[i][0]:
			problems.append("stage %d's miss line" % (i + 1))
	lab.reset_run()
	lab.model.pour("gravel")
	lab.model.pour("sand")
	lab.model.pour("mud")
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the mud settles")
	_settle(lab.model)
	lab.manipulation_started("gravel")
	if lab.settled():
		problems.append("settled while a bucket is held")
	lab.manipulation_cancelled("gravel")
	expect.call(problems.is_empty(), "strata judging: stage 1 the pile gravel, sand, mud (out of order or ash: Puppy's miss), stage 2 the shell after the gravel (anywhere else, or none: the miss), stage 3 the layer just under the ash (any other: the miss); the other stages' actions say nothing; not judged while a pour settles or a bucket is held",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- each stage's objects -------------------------------------------------------------------------

func check_stage_objects() -> void:
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
	await tree.process_frame
	var problems := []
	var buckets: Array = StrataModel.MATERIALS
	var cliff: Array = range(StrataModel.CLIFF.size()).map(func(i: int) -> String: return StrataLab.cliff_id(i))
	# [stage, offered ids, guide kind]
	var want := [[0, buckets, "drag"], [1, buckets + [StrataLab.SHELL_ID], "drag"], [2, cliff, "tap"], [-1, buckets + [StrataLab.SHELL_ID] + cliff, "drag"]]
	for w: Array in want:
		lab.set_game_stage(int(w[0]), maxi(0, int(w[0])), false)
		var offered := (buckets + [StrataLab.SHELL_ID] + cliff).filter(func(id: String) -> bool: return lab.manipulation_body(id) != null)
		var guide := m.guide()
		if offered != w[1] or guide.get("kind", "") != w[2] or not guide.get("id", "") in w[1]:
			problems.append("stage %d: %s, guide %s" % [int(w[0]) + 1, str(offered), str(guide)])
	lab.set_game_stage(0, 0, false)
	lab.model.pour("gravel")
	if lab.manipulation_body("sand") != null:
		problems.append("a bucket offered while a pour settles")
	expect.call(problems.is_empty(), "strata stages: the buckets in stages 1 and 2, the shell in stage 2, the cliff's layers in stage 3 (all of them outside a round), none while a pour settles; the hand guide drags a bucket, then taps the cliff",
		"; ".join(problems))
	host.queue_free()
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
	for step: Variant in ["", "gravel", "sand", "mud", 3, 2]:
		if step is int:
			lab.model.dig(int(step))
		elif str(step) != "":
			lab.model.pour(str(step))
		_settle(lab.model)
		var seen := lab.observations()
		for key: String in seen:
			if not seen[key] is String or str(seen[key]) == "" or digits.search(str(seen[key])) != null or str(seen[key]).begins_with("strata."):
				problems.append("%s after %s: %s" % [key, str(step), str(seen[key])])
	lab._show()
	if lab.props.shown_layers != ["gravel", "sand", "mud"] or lab.props.shown_heights.any(func(h: float) -> bool: return absf(h - StrataProps.LAYER_H) > 1e-6):
		problems.append("the tank draws %s %s" % [str(lab.props.shown_layers), str(lab.props.shown_heights)])
	var o := lab.observations()
	if o.bottom != "자갈" or o.top != "진흙" or o.state != "조각이 나왔어요":
		problems.append("words %s" % str(o))
	expect.call(problems.is_empty(), "strata: no number on the screen (the observations are words: the state, the bottom and the top layer; the card is the state); the tank draws the poured layers bottom first",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

## What the child touches is in the clear on the phone's, the desktop's and the tablet's front view:
## the buckets, the shell, the tank (its frame's corners) and every cliff layer inside the sides and
## above the bottom (BOTTOM_FREE: the dialogue box, the buttons); those on the left (LEFT_BAND) under the
## top band (TOP_FREE: the title, the card, the mission strip), the cliff under the 자세히 button; the
## pour over the tank under the top band; a cliff layer LAYER_MIN tall and a bucket BUCKET_MIN wide.
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
		var units := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit
		var at := func(world: Vector3) -> Vector2: return units.call(world) / size
		var inside := func(world: Vector3, what: String) -> void:
			var p: Vector2 = at.call(world)
			var top := TOP_FREE if p.x < LEFT_BAND else RIGHT_TOP
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < top or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		var r := StrataProps.BUCKET_RADIUS
		for material: String in StrataModel.MATERIALS:
			var c := StrataProps.bucket_home(material)
			for d: Vector3 in [Vector3(-r, -0.36, 0.0), Vector3(r, 0.5, 0.0)]:
				inside.call(c + d, material)
		var bucket_w: float = (units.call(StrataProps.bucket_home("gravel") + Vector3(r, 0, 0)) - units.call(StrataProps.bucket_home("gravel") - Vector3(r, 0, 0))).x
		inside.call(StrataProps.shell_home(), "shell")
		var box := StrataProps.tank_box()
		for corner: Vector3 in [box.position, box.position + Vector3(box.size.x, box.size.y, 0.0)]:
			inside.call(Vector3(corner.x, corner.y, StrataProps.tank_front()), "tank corner")
		inside.call(Vector3(StrataProps.TANK_X, StrataProps.TANK_FLOOR + StrataProps.TANK_SIZE.y, StrataProps.DRAG_Z) + StrataProps.POUR_AT + Vector3(0.0, StrataProps.BUCKET_HEIGHT * 0.5, 0.0), "the pouring bucket")
		var layer_min := INF
		for i in StrataModel.CLIFF.size():
			var c := StrataProps.cliff_layer_center(i)
			var h := StrataProps.CLIFF_LAYER_H * 0.5
			for d: Vector3 in [Vector3(StrataProps.CLIFF_X0 - c.x, -h, 0.0), Vector3(StrataProps.CLIFF_X1 - c.x, h, 0.0)]:
				inside.call(c + d, "cliff layer %d" % i)
			layer_min = minf(layer_min, (units.call(c - Vector3(0, h, 0)) - units.call(c + Vector3(0, h, 0))).y)
		if layer_min < LAYER_MIN or bucket_w < BUCKET_MIN:
			problems.append("%s: a cliff layer %.0f units tall, a bucket %.0f wide" % [str(size), layer_min, bucket_w])
		seen.append("%s layer %.0f bucket %.0f" % [str(size), layer_min, bucket_w])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "strata in view: the buckets, the shell, the tank, the pour and every cliff layer inside the view and above its bottom %.0f%% (left of the middle under the top band), a cliff layer %.0f units tall and a bucket %.0f wide or more (phone, desktop and tablet)" % [(1.0 - BOTTOM_FREE) * 100.0, LAYER_MIN, BUCKET_MIN],
		"; ".join(problems.slice(0, 4) + seen))


## The real screen of `size`: Puppy (his flag too) and Dugi are whole inside the view (not cut at its
## sides or top), and the bucket pouring over the tank is clear of the title bar, the card, the mission
## pill with each stage's text and the top buttons (자세히).
func check_screen(size: Vector2) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(_definition())
	host.add_child(screen)
	for i in 20:
		await tree.process_frame
	var lab: StrataLab = screen.experiment
	var view: View3D = screen.view
	var per_unit := Vector2(view.viewport.size) / view.size
	var on_screen := func(box: AABB) -> Rect2:
		var r := Rect2()
		for k in 8:
			var p: Vector2 = view.rig.unproject_position(box.get_endpoint(k)) / per_unit
			r = Rect2(p, Vector2.ZERO) if k == 0 else r.expand(p)
		return r
	var problems := []
	var view_rect := Rect2(Vector2.ZERO, view.size)
	var cast: IslandCast = screen.cast
	for pair: Array in [["Puppy", cast.puppy if cast != null else null], ["Dugi", cast.dugi if cast != null else null]]:
		if pair[1] == null:
			problems.append("no %s" % pair[0])
			continue
		var r: Rect2 = on_screen.call(IslandCast.drawn_bounds(pair[1]))
		if r.position.x < 0.0 or r.end.x > view_rect.end.x or r.position.y < 0.0:
			problems.append("%s at %s (view %s)" % [pair[0], str(r), str(view.size)])
	lab.model.pour("gravel")
	lab.model.set_input("settle", 0.5)
	lab._show()
	var bucket: Rect2 = on_screen.call(IslandCast.drawn_bounds(lab.props.buckets["gravel"]))
	var round: MissionRound = screen.mission_round
	for stage in 3:
		screen._mission_text.text = round.stage_text(stage)
		screen._fit_mission_strip()
		await tree.process_frame
		for c: Control in [screen._title_bar, screen._key_row, screen._mission_pill, screen._top_buttons]:
			if c != null and c.is_visible_in_tree() and c.get_rect().intersects(bucket):
				problems.append("stage %d: the pouring bucket %s under %s %s" % [stage + 1, str(bucket), c.name, str(c.get_rect())])
	var name: String = {PHONE: "phone", DESKTOP: "desktop", TABLET: "tablet"}[size]
	expect.call(problems.is_empty(), "strata screen (%s): Puppy with his flag and Dugi whole inside the view; the pouring bucket clear of the title, the card, the mission strip (every stage's text) and 자세히" % name,
		"; ".join(problems.slice(0, 6)))
	host.queue_free()
	for i in 3:
		await tree.process_frame


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var kinds := ["strata_bottom", "strata_top"]
	for kind: String in kinds:
		var draw := func() -> void:
			PredictPictures.draw(canvas, kind)
			drawn.append(kind)
		canvas.draw.connect(draw)
		canvas.queue_redraw()
		await tree.process_frame
		canvas.draw.disconnect(draw)
	canvas.queue_free()
	expect.call(kinds.all(func(k: String) -> bool: return k in PredictPictures.KINDS) and drawn == kinds,
		"strata pictures: the question's layer kinds (PredictPictures) are listed and draw", str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[8]) != ID:
		problems.append("strata is not hutton's ninth spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	expect.call(problems.is_empty(), "strata: Hutton Island's ninth spot is an experiment (a lab on its map)", "; ".join(problems))


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
		"strata opening: first visit the fox (worried), Puppy's clue, Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the hand -------------------------------------------------------------------------------------

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
	# The gravel bucket dragged onto the tank: it follows the finger, and pours when let go there.
	var from: Vector2 = screen.call(StrataProps.bucket_home("gravel"))
	var over: Vector2 = screen.call(StrataProps.tank_box().get_center())
	m.handle_pointer("press", from)
	if m.mode != "drag" or m.active_id != "gravel":
		problems.append("press on the gravel bucket: mode '%s' id '%s'" % [m.mode, m.active_id])
	m.handle_pointer("move", from.lerp(over, 0.5))
	m.handle_pointer("move", over)
	await tree.process_frame
	if not StrataProps.over_tank(lab.props.buckets["gravel"].position) or lab.settled():
		problems.append("held: the bucket at %s" % str(lab.props.buckets["gravel"].position))
	m.handle_pointer("release", over)
	var frames := 0
	while not lab.settled() and frames < 200:
		await tree.physics_frame
		frames += 1
	await tree.process_frame
	if lab.model.layers() != ["gravel"] or lab.props.buckets["gravel"].position.distance_to(StrataProps.bucket_home("gravel")) > 1e-3 or lab.knobs["gravel"].global_position.distance_to(StrataProps.bucket_home("gravel")) > 1e-3:
		problems.append("after the pour: %s, the bucket at %s" % [str(lab.model.layers()), str(lab.props.buckets["gravel"].position)])
	# The sand bucket let go beside the bench: nothing is poured, it goes back.
	from = screen.call(StrataProps.bucket_home("sand"))
	m.handle_pointer("press", from)
	m.handle_pointer("move", from + Vector2(0.0, -120.0))
	m.handle_pointer("release", from + Vector2(0.0, -120.0))
	await tree.process_frame
	if lab.model.layers() != ["gravel"] or lab.props.buckets["sand"].position.distance_to(StrataProps.bucket_home("sand")) > 1e-3:
		problems.append("let go off the tank: %s" % str(lab.model.layers()))
	# A tap on a cliff layer (stage 3) digs it.
	lab.set_game_stage(2, 2, false)
	var layer: Vector2 = screen.call(StrataProps.cliff_layer_center(StrataModel.TARGET) + Vector3(-0.6, 0.0, 0.0))
	m.handle_pointer("press", layer)
	m.handle_pointer("release", layer)
	if lab.model.last_dig != StrataModel.TARGET or lab.status() != "found":
		problems.append("tap on the piece's layer: dug %d (%s)" % [lab.model.last_dig, lab.status()])
	layer = screen.call(StrataProps.cliff_layer_center(StrataModel.TARGET + 1) + Vector3(0.8, 0.0, 0.0))
	m.handle_pointer("press", layer)
	m.handle_pointer("release", layer)
	if lab.model.last_dig != StrataModel.TARGET + 1 or lab.status() != "dug_off":
		problems.append("tap on the ash: dug %d (%s)" % [lab.model.last_dig, lab.status()])
	if not lab.placements().is_empty():
		problems.append("placements kept %s" % str(lab.placements().keys()))
	expect.call(problems.is_empty(), "strata hand: a bucket follows the finger onto the tank and pours its layer when let go there (then goes home), let go elsewhere it goes back with nothing poured; a tap on a cliff layer digs that layer; nothing is kept as a placement",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: StrataGame = lab.game
	var problems := []
	game.show_stage(0, 0, false)
	await tree.process_frame
	if game.piece_state != "held" or game.piece.visible or not lab.props.glint.visible:
		problems.append("not hidden in the cliff at the start (or no glint)")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or game.piece.visible:
		problems.append("out before the last stamp (%s)" % game.piece_state)
	lab.model.dig(StrataModel.TARGET)
	_settle(lab.model)
	lab._show()
	await tree.process_frame
	if not game.piece.visible:
		problems.append("not seen in its dug hole")
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or absf(rest.y - StrataProps.TERRACE_TOP - LabGame.PIECE_SIZE) > 0.12 or rest.distance_to(StrataGame.LAND_AT) > 0.8 or lab.props.glint.visible:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if again.game.take_piece() != null or again.props.glint.visible:
		problems.append("a finished spot: a piece, or the glint")
	expect.call(problems.is_empty(), "strata piece: hidden in the cliff (a glint in the crack) until the last stamp, seen in its dug hole, then it jumps out onto the terrace for the cat; a finished spot shows no piece and no glint",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
