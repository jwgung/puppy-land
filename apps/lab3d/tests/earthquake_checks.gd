## 지진 (#97, 2026-11-07; Hutton Island's tenth spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after seasons), not
##   one of the first island's; no explanation picture (hutton-lines.md 10 has no "[그림: …]"); the
##   question's and the buttons' pictures are code-drawn kinds; its Korean lines are
##   docs/islands/hutton-lines.md section 10 word for word (the fox, Puppy's two lines, Dugi's two, the
##   question, its choices, reason and bridge, the riddle, every stage's conditions, mission,
##   explanation, win, miss and wrong-condition line) with the doc's faces; Puppy's result lines are
##   short with no science words, digits or symbols; English has every line;
## - the model: the pull's levels (from PULL_MIN); the plain house stands on rock up to half the pull
##   and falls on sand at every pull (sand shakes twice as far), the braced one stands the full pull on
##   both; the same run twice is
##   the same to the bit; the statuses; a reset clears the run and keeps the conditions;
## - the judging (MissionRound on the real lab): each stage's hits and misses over every pull level, the
##   wrong conditions' lines, nothing while shaking or while the finger pulls;
## - the engine: the house is Jolt rigid bodies, posed on the model's frame every step while it stands
##   (<= 1e-4 m), let go the step the model's house falls and down on the slab by the run's end;
##   a braced house on sand at the full pull stays on the model all the way;
## - the buttons: ground and brace on every stage, a new choice starts the run over, 다시 keeps it;
## - no number on the screen: the observations and the pull's readout are words;
## - in view (phone, desktop, tablet): the house, the knob (at rest and pulled all the way), the hill's
##   piece between the top band and the dialogue box; the volcano's side (the island's volcano as
##   LabWorld places it) is where the stripes come from, on the right of the screen;
## - the stripes: ripple bands run out from the volcano's side while shaking, the crack grows on the
##   strongest shake only and stays until 다시;
## - the pull's word (the slingshot readout) on the real screen: clear of the house (its roof swaying
##   either way) and inside the view on the phone, desktop and tablet; the mechanics labs' readout
##   stays where it was (the view's top middle);
## - the spot, the opening, the slingshot (a pull to the left is the level, a tap is nothing) and the
##   piece (lamps per stamp, the piece hops down at the last).
extends RefCounted

const ID := "earthquake"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const UI_THEME := "res://scripts/app/ui_theme.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
const EDGE := 0.03
const BOTTOM_FREE := 0.8
const TOP_FREE := 0.22
const LINE_MAX := 24
const ENGINE_TOLERANCE := 1e-4
## The fallen house's roof ends at least this far under its standing height (m).
const FALLEN_DROP := 0.8
## The volcano's side as LabWorld puts it and the stripes' source agree within this (deg).
const VOLCANO_SLACK := 1.0

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
	await check_engine()
	await check_buttons()
	await check_no_numbers()
	await check_in_view()
	await check_stripes()
	check_spot()
	await check_pictures()
	check_opening()
	await check_slingshot()
	await check_readout()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> EarthquakeLab:
	var lab := EarthquakeLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## The lab's whole run of `level` at once (the model stepped to its end; the bodies untouched).
static func _run(lab: EarthquakeLab, ground: String, brace: String, level: float) -> void:
	lab.set_control("ground", ground)
	lab.set_control("brace", brace)
	lab.set_control("pull", level)
	lab.run_action("release")
	while lab.model.animating():
		lab.model.step(1.0 / EarthquakeModel.STEPS_PER_SECOND)


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "earthquake: the definition loads", "not found")
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
	if kid.picks.ground.map(func(p: Dictionary) -> String: return str(p.value)) != ["rock", "sand"] \
			or kid.picks.brace.map(func(p: Dictionary) -> String: return str(p.value)) != ["none", "brace"] \
			or (kid.picks.ground + kid.picks.brace).any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the buttons %s" % str(kid.picks))
	if definition.manipulation.get("slingshot", {}).get("object", "") != EarthquakeLab.KNOB_ID:
		problems.append("no slingshot on the table")
	expect.call(problems.is_empty(), "earthquake: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; no explanation picture (none in the doc); code-drawn question, ground and brace pictures; the table is a slingshot",
		"; ".join(problems))


## The section "## 10. 지진" of the lines doc (as seasons_checks._doc_section).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 10. 지진")
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
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[1] != "모래 땅":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	# The doc's condition cell: "바위, 버팀대 없음" (the ground's word without "땅", then the house's button).
	var ground_word := {"rock": "바위", "sand": "모래"}
	var brace_label := {}
	for p: Dictionary in definition.kid.picks.brace:
		brace_label[p.value] = p.label
	var stages: Array = definition.missions.stages
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var cell := "%s, %s" % [ground_word.get(stage.conditions.ground, "?"), brace_label.get(stage.conditions.brace, "?")]
			var got := [str(i + 1), cell, stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	for p: Dictionary in definition.kid.picks.ground:
		if not str(p.label).begins_with(ground_word[p.value]):
			problems.append("ground button %s" % p.label)
	expect.call(problems.is_empty(), "earthquake: the Korean lines are hutton-lines.md 10 word for word (the fox, Puppy's two lines, Dugi's two lines, the question, the riddle, the three stages with their conditions and wrong-condition lines) with its faces",
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
	var told: Array = [Story.keeper(_definition()), Story.clue(_definition()), Story.map_clue(_definition())]
	told.append_array(Story.more(_definition()).map(func(l: Dictionary) -> String: return str(l.text)))
	for line: String in told:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/earthquake.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/earthquake.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or Story.more(en).size() != 1 or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or (en.kid.picks.ground + en.kid.picks.brace).any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "earthquake: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

func check_model() -> void:
	var problems := []
	var stands := {}
	for ground in [EarthquakeModel.ROCK, EarthquakeModel.SAND]:
		for brace in [false, true]:
			var up := []
			for k in range(3, 11):
				var out := EarthquakeModel.outcome(k * 0.1, ground, brace)
				if out[0] != "fell":
					up.append(k)
			stands["%d%s" % [int(ground), "b" if brace else ""]] = up
	# The plain house: rock up to 0.5, sand never (one condition per stage, #114: the light shake that
	# rock stands brings it down on sand); the braced one stands every pull.
	if stands["0"] != [3, 4, 5] or stands["1"] != [] or stands["0b"].size() != 8 or stands["1b"].size() != 8:
		problems.append("stands %s" % str(stands))
	# Sand shakes twice as far as rock under the same pull (the ground's surface), and its house sways more.
	var rock := EarthquakeModel.new()
	var sand := EarthquakeModel.new()
	sand.set_start("ground", EarthquakeModel.SAND)
	for braced in [rock, sand]:   # (braced: the plain house on sand falls, its sway stops counting)
		braced.set_start("brace", 1.0)
	rock.release(0.3)
	sand.release(0.3)
	var swing := Vector2.ZERO
	while rock.running:
		rock.step(1.0 / 60.0)
		sand.step(1.0 / 60.0)
		swing = Vector2(maxf(swing.x, absf(rock.ground_x)), maxf(swing.y, absf(sand.ground_x)))
	if absf(swing.y - 2.0 * swing.x) > 1e-9 or sand.drift_peak <= rock.drift_peak * 1.9:
		problems.append("swings %s, drifts %.3f / %.3f" % [str(swing), rock.drift_peak, sand.drift_peak])
	# The same run twice is the same to the bit.
	var a := EarthquakeModel.outcome(0.7, EarthquakeModel.SAND, true)
	var b := EarthquakeModel.outcome(0.7, EarthquakeModel.SAND, true)
	if a != b:
		problems.append("not repeatable %s %s" % [str(a), str(b)])
	# Statuses and the reset.
	var m := EarthquakeModel.new()
	if m.status() != "ready" or EarthquakeModel.snapped_pull(0.0) != EarthquakeModel.PULL_MIN or absf(EarthquakeModel.snapped_pull(0.12) - 0.3) > 1e-9 or EarthquakeModel.snapped_pull(1.4) != 1.0 or absf(EarthquakeModel.snapped_pull(0.46) - 0.5) > 1e-9:
		problems.append("start %s / levels" % m.status())
	m.set_start("ground", EarthquakeModel.SAND)
	m.set_start("brace", 1.0)
	m.release(0.5)
	m.step(1.0 / 60.0)
	var mid := m.status()
	while m.running:
		m.step(1.0 / 60.0)
	var held := m.status()
	m.release(1.0)
	while m.running:
		m.step(1.0 / 60.0)
	var strongest := m.status()
	m.reset()
	var on_rock := EarthquakeModel.new()
	on_rock.set_start("brace", 1.0)
	on_rock.release(0.3)
	while on_rock.running:
		on_rock.step(1.0 / 60.0)
	var stood := on_rock.status()
	if mid != "shaking" or held != "held" or strongest != "strongest" or stood != "stood" or m.status() != "ready" \
			or m.input("ground") != EarthquakeModel.SAND or m.input("brace") != 1.0 or m.steps != 0:
		problems.append("statuses %s %s %s %s, after reset %s" % [mid, held, strongest, stood, m.status()])
	expect.call(problems.is_empty(), "earthquake model: the lightest pull is 0.3; the plain house stands rock up to half the pull and falls on sand at every pull, the braced one the full pull on both; sand's ground swings twice as far; the same run is the same to the bit; shaking / stood / held / strongest; a reset keeps the conditions",
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# stage -> [ground, brace, the pull levels (tenths) that win]
	# (a pull under PULL_MIN is PULL_MIN: 0.1 and 0.2 are the lightest shake)
	var wins := [["rock", "none", [1, 2, 3, 4, 5]], ["sand", "none", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]], ["sand", "brace", [10]]]
	for stage in 3:
		for k in range(1, 11):
			_run(lab, wins[stage][0], wins[stage][1], k * 0.1)
			var status := lab.status()
			var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
			var missed := MissionRound.missed(definition, stage, status, lab.observations())
			var want: bool = k in wins[stage][2]
			if (stamps == stage + 1) != want or (not want and not missed):
				problems.append("stage %d at %d (%s): stamps %d missed %s" % [stage + 1, k, status, stamps, missed])
	var lines := [["sand", "brace", "바위 땅에 버팀대 없이 해 봐!"], ["rock", "brace", "모래 땅에 버팀대 없이 해 봐!"], ["sand", "none", "모래 땅에 버팀대를 골라 봐!"]]
	for i in 3:
		_run(lab, lines[i][0], lines[i][1], 0.1)
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var stamps := MissionRound.judge(definition, i, lab.status(), lab, lab.observations())
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != lines[i][2] or not off or stamps != i or not MissionRound.missed(definition, i, lab.status(), lab.observations()):
			problems.append("stage %d wrong conditions say '%s'" % [i + 1, line[0]])
	lab.set_control("ground", "rock")
	lab.set_control("brace", "none")
	lab.set_control("pull", 0.2)
	lab.run_action("release")
	lab.model.step(1.0 / 60.0)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while shaking")
	lab.reset_run()
	lab.manipulation_started(EarthquakeLab.KNOB_ID)
	if lab.settled():
		problems.append("settled while the finger pulls")
	lab.manipulation_cancelled(EarthquakeLab.KNOB_ID)
	expect.call(problems.is_empty(), "earthquake judging: stage 1 (rock, no brace) wins the light pulls (up to 0.5) and misses from 0.6 (it falls); stage 2 (sand, no brace: the ground alone changed) wins every pull (the house falls); stage 3 (sand, brace: the brace alone changed) wins the full pull only; the wrong buttons say the doc's lines; nothing while shaking or pulling",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the engine -----------------------------------------------------------------------------------

## A run on the engine: [the worst distance of a block from the model's frame while standing, the
## step it was let go (-1), the roof's height at the end, frozen blocks at the end].
func _engine_run(lab: EarthquakeLab, ground: String, brace: String, level: float) -> Array:
	lab.set_control("ground", ground)
	lab.set_control("brace", brace)
	lab.set_control("pull", level)
	lab.change_from_input(lab.run_action.bind("release"))   # as the screen lets a pull go (BodyResync)
	var worst := 0.0
	var let_go := -1
	while lab.model.animating():
		await tree.physics_frame
		if lab.collapsed:
			if let_go < 0:
				let_go = (lab.model as EarthquakeModel).steps
			continue
		if (lab.model as EarthquakeModel).steps == 0:
			continue   # (the frame of the let-go itself: the engine reports the rest pose until its first step)
		for pair: Array in lab.blocks:
			var body: RigidBody3D = pair[0]
			worst = maxf(worst, body.position.distance_to(lab.posed_origin(body.name)))
	for i in 20:
		await tree.physics_frame
	var frozen := lab.blocks.filter(func(p: Array) -> bool: return (p[0] as RigidBody3D).freeze).size()
	return [worst, let_go, lab.block("Roof").position.y, frozen]


func check_engine() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	if lab.blocks.size() != 11 or lab.blocks.any(func(p: Array) -> bool: return not p[0] is RigidBody3D) or lab.slab_body == null:
		problems.append("%d blocks" % lab.blocks.size())
	var standing_roof: float = lab.block("Roof").position.y
	var fell := await _engine_run(lab, "rock", "none", 1.0)
	var fell_step := (lab.model as EarthquakeModel).fell_step
	if fell[0] > ENGINE_TOLERANCE or fell[1] != fell_step or fell[2] > standing_roof - FALLEN_DROP or fell[3] != 0 or lab.status() != "fell":
		problems.append("rock, no brace, full pull: %s (fell at %d, roof from %.2f)" % [str(fell), fell_step, standing_roof])
	var stood := await _engine_run(lab, "sand", "brace", 1.0)
	if stood[0] > ENGINE_TOLERANCE or stood[1] != -1 or absf(stood[2] - lab.posed_origin("Roof").y) > ENGINE_TOLERANCE or stood[3] != 11 or lab.status() != "strongest":
		problems.append("sand, brace, full pull: %s" % str(stood))
	lab.change_from_input(lab.reset_run)
	await tree.physics_frame
	if lab.collapsed or lab.block("Roof").position.distance_to(lab.posed_origin("Roof")) > ENGINE_TOLERANCE:
		problems.append("다시 did not stand the house up")
	expect.call(problems.is_empty(), "earthquake engine: 11 Jolt blocks on an animatable slab, posed on the model's racking frame every step while standing (<= 1e-4 m); let go the step the model's house falls and down (roof %.1f m lower or more) by the end; the braced house on sand at the full pull stays on the model; 다시 stands it up" % FALLEN_DROP,
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the buttons ----------------------------------------------------------------------------------

func check_buttons() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	for i in 3:
		var groups := ConditionPicks.groups(definition, i)
		var ids := groups.map(func(g: Dictionary) -> String: return str(g.control))
		if ids.size() != 2 or not "ground" in ids or not "brace" in ids or groups.any(func(g: Dictionary) -> bool: return g.presets.size() != 2):
			problems.append("stage %d buttons %s" % [i + 1, str(ids)])
	if lab.control_value("ground") != "rock" or lab.control_value("brace") != "none" or lab.props.sand.visible or lab.props.brace.visible:
		problems.append("the start is not rock without a brace")
	_run(lab, "rock", "none", 0.3)
	var resets := lab.reset_count
	lab.set_control("ground", "sand")
	lab.set_control("brace", "brace")
	if lab.model.input("ground") != EarthquakeModel.SAND or lab.model.input("brace") != 1.0 or lab.reset_count != resets + 2 \
			or lab.status() != "ready" or not lab.props.sand.visible or lab.props.rock.visible or not lab.props.brace.visible:
		problems.append("sand + brace: %s" % lab.status())
	lab.reset_run()
	if lab.model.input("ground") != EarthquakeModel.SAND or not lab.props.brace.visible:
		problems.append("다시 lost the conditions")
	expect.call(problems.is_empty(), "earthquake buttons: ground (rock / sand) and house (no brace / brace) on every stage; a new choice starts the run over and shows the sand slab and the brace; 다시 keeps them",
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
	var seen := {}
	for c: Array in [["rock", "none", 0.0], ["rock", "none", 0.3], ["rock", "none", 0.8], ["sand", "brace", 0.5], ["sand", "brace", 1.0]]:
		if c[2] > 0.0:
			_run(lab, c[0], c[1], c[2])
		else:
			lab.reset_run()
		seen[lab.status()] = true
		for key: String in lab.observations():
			var value: Variant = lab.observations()[key]
			if not value is String or str(value) == "" or digits.search(str(value)) != null:
				problems.append("%s: %s" % [key, str(value)])
	var readout: Callable = lab.slingshot_setup().readout
	var words := {}
	for k in range(1, 11):
		var text: String = readout.call(Vector2(k * 0.1, 0.0))
		words[text] = true
		if text == "" or digits.search(text) != null:
			problems.append("readout %s" % text)
	if seen.size() != 5 or words.size() != 4:
		problems.append("statuses %s, readout words %s" % [str(seen.keys()), str(words.keys())])
	expect.call(problems.is_empty(), "earthquake: no number on the screen (the observations and the pull's readout are words: 4 strengths), the card is the house's state",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

func check_in_view() -> void:
	var problems := []
	var seen := []
	# The volcano's side: LabWorld's placement of the island's volcano agrees with the stripes' source.
	var was := Island.current_id()
	Island.use_for_run("hutton")
	var world := LabWorld.new(ID, EarthquakeProps.WORLD_CENTER)
	Island.use_for_run(was)
	var v: Array = Island.by_id("hutton").features.volcano.at
	var at := world.to_lab(Vector2(float(v[0]), float(v[1])))
	var mapped := Vector3(at.x, 0.0, at.y) - EarthquakeProps.TABLE_CENTER
	var angle := rad_to_deg(mapped.normalized().angle_to(EarthquakeProps.volcano_dir()))
	if angle > VOLCANO_SLACK:
		problems.append("the volcano is %.1f deg off the stripes' source" % angle)
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
		var to_screen := func(world_point: Vector3) -> Vector2: return view.rig.unproject_position(world_point) / per_unit / size
		var inside := func(p: Vector2, what: String) -> void:
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < TOP_FREE or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		var foot := EarthquakeProps.house_foot(0.0)
		for d: float in [-EarthquakeModel.SWING_MAX * 2.0, EarthquakeModel.SWING_MAX * 2.0]:
			inside.call(to_screen.call(foot + Vector3(d - 1.3, 0.0, 0.7)), "house foot")
			inside.call(to_screen.call(foot + Vector3(d + 1.3, EarthquakeProps.ROOF_BASE + EarthquakeProps.ROOF.y, 0.0)), "roof")
		var knob := EarthquakeProps.knob_at(0.0)
		inside.call(to_screen.call(knob), "knob")
		inside.call(to_screen.call(knob - Vector3(EarthquakeProps.PULL_REACH, 0.0, 0.0)), "the full pull")
		var piece: Vector3 = lab.game.piece.global_position
		inside.call(to_screen.call(piece), "the piece")
		for hop: Vector3 in [Vector3.ZERO, Vector3(1.0, 0.0, 1.5)]:   # where it lands and where its hops end
			inside.call(to_screen.call(EarthquakeGame.LAND_AT + hop + Vector3(0.0, LabGame.PIECE_SIZE, 0.0)), "the piece's landing")
		var knob_px: Vector2 = to_screen.call(knob) * size
		var reach_px: Vector2 = to_screen.call(knob - Vector3(EarthquakeProps.PULL_REACH, 0.0, 0.0)) * size
		if knob_px.distance_to(reach_px) < 200.0:
			problems.append("%s: the full pull is %.0f px" % [str(size), knob_px.distance_to(reach_px)])
		var side: Vector2 = to_screen.call(EarthquakeProps.TABLE_CENTER + lab.props.volcano * 8.0)
		if side.x < 0.55:
			problems.append("%s: the volcano's side at %s (not on the right)" % [str(size), str(side)])
		seen.append("%s knob %s pull %.0f px" % [str(size), str(to_screen.call(knob)), knob_px.distance_to(reach_px)])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "earthquake in view: the house swaying either way, the knob at rest and pulled all the way, the hill's piece between the top band (%.0f%%) and the bottom %.0f%% (phone, desktop, tablet); the full pull is 200 px or more; the volcano's side (LabWorld's volcano) on the right" % [TOP_FREE * 100.0, (1.0 - BOTTOM_FREE) * 100.0],
		"; ".join(problems.slice(0, 5) + seen))


# --- the stripes ----------------------------------------------------------------------------------

func check_stripes() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var props: EarthquakeProps = lab.props
	lab.set_control("ground", "sand")
	lab.set_control("brace", "brace")
	lab.set_control("pull", 0.5)
	lab.run_action("release")
	var radii := []
	var bands := 0
	for i in 40:
		await tree.physics_frame
		bands = maxi(bands, props.shown_bands)
		if props.bands[0].visible:
			radii.append(props.bands[0].scale.x)
	var growing: bool = radii.size() > 3 and radii[1] > radii[0] and radii[0] < 1.0
	if bands == 0 or not growing or props.shown_crack != 0:
		problems.append("a middle shake: %d bands, radii %s, crack %d" % [bands, str(radii.slice(0, 3)), props.shown_crack])
	_run(lab, "sand", "brace", 1.0)
	lab._show()
	if props.shown_crack != EarthquakeProps.CRACK_STEPS or props.shown_bands != 0:
		problems.append("after the strongest shake: crack %d, bands %d" % [props.shown_crack, props.shown_bands])
	var far: Vector3 = (props.crack[0] as MeshInstance3D).get_aabb().get_center()
	if far.distance_to(EarthquakeProps.TABLE_CENTER + props.volcano * EarthquakeProps.CRACK_FROM) > 1.0:
		problems.append("the crack does not start on the volcano's side")
	lab.reset_run()
	if props.shown_crack != 0:
		problems.append("다시 kept the crack")
	expect.call(problems.is_empty(), "earthquake stripes: ripple bands run out from the volcano's side while the table shakes; the crack from that side grows on the strongest shake only and stays until 다시",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the spot, the pictures, the opening ----------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[9]) != ID:
		problems.append("earthquake is not hutton's tenth spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	expect.call(problems.is_empty(), "earthquake: Hutton Island's tenth spot is an experiment", "; ".join(problems))


func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["quake_rock", "quake_sand"]
	var pick_kinds := ["ground_rock", "ground_sand", "house_plain", "house_brace"]
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
		"earthquake pictures: the question's rock / sand shakes (PredictPictures) and the ground and house buttons (PickPictures) are listed and draw", str(drawn))


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
		"earthquake opening: first visit the fox (worried), Puppy worried for the squirrels (story.clue), Puppy spots the piece (story.more), Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the hand: the slingshot ----------------------------------------------------------------------

func check_slingshot() -> void:
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
	var spec := lab.slingshot_setup()
	m.set_slingshot(str(spec.object), spec.surface, spec.launch, func() -> Vector2: return Vector2(lab.control_value("pull"), 0.0), spec.value, spec.demo)
	var heard := []
	m.slingshot.connect(func(state: String, value: Variant) -> void:
		heard.append([state, value])
		if state == "pull":
			lab.set_slingshot_preview(value)
		elif state in ["release", "cancel"]:
			lab.set_slingshot_preview(Vector2.INF))
	for i in 3:
		await tree.physics_frame
	await tree.process_frame
	var per_unit := Vector2(view.viewport.size) / view.size
	var screen := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit
	var problems := []
	var knob := EarthquakeProps.knob_at(0.0)
	var at: Vector2 = screen.call(knob)
	var half: Vector2 = screen.call(knob - Vector3(EarthquakeProps.PULL_REACH * 0.5, 0.0, 0.0))
	m.handle_pointer("press", at)
	m.handle_pointer("move", at.lerp(half, 0.5))
	m.handle_pointer("move", half)
	await tree.process_frame
	var pulled := lab.props.shown_deck
	if m.mode != "slingshot" or lab.settled() or absf(pulled + 0.5 * EarthquakeModel.SWING_MAX) > 1e-6 or lab.props.pull_dots.dots() == 0:
		problems.append("pulling: mode '%s', deck %.3f" % [m.mode, pulled])
	m.handle_pointer("release", half)
	var last: Array = heard[-1] if not heard.is_empty() else []
	if last.is_empty() or last[0] != "release" or absf((last[1] as Vector2).x - 0.5) > 1e-9 or lab.props.pull_dots.dots() != 0:
		problems.append("released %s" % str(last))
	# A tap is no pull.
	heard.clear()
	m.handle_pointer("press", at)
	m.handle_pointer("release", at)
	if heard.is_empty() or heard[-1][0] != "cancel":
		problems.append("a tap %s" % str(heard))
	var guide := m.guide()
	if guide.get("kind", "") != "pull" or guide.get("id", "") != EarthquakeLab.KNOB_ID or not (guide.get("to") is Vector3 and (guide.to as Vector3).x < knob.x):
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "earthquake hand: a press on the red knob and a pull to the left is the slingshot (half the reach = 0.5, the deck slides back, dots to the finger), the release gives that level, a tap is no pull; the hand guide pulls to the left",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the pull's word ------------------------------------------------------------------------------

func _open(id: String, size: Vector2) -> Control:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(ExperimentRegistry.find(id))
	host.add_child(screen)
	for i in 4:
		await tree.process_frame
	return screen


## The readout (the longest word, the full pull) on the real screen stays off the house: the house's
## box with the roof swaying either way (sand's swing) and the knob at rest, on the phone, desktop and
## tablet, and inside the view; the collision lab's readout is still centred under the top band.
func check_readout() -> void:
	var problems := []
	var seen := []
	for size: Vector2 in [PHONE, DESKTOP, TABLET]:
		var screen := await _open(ID, size)
		screen._on_slingshot("pull", Vector2(1.0, 0.0))
		await tree.process_frame
		var hud: Label = screen._slingshot_hud
		var box: Rect2 = hud.get_rect()
		var swing := EarthquakeModel.SWING_MAX * 2.0
		var foot := EarthquakeProps.house_foot(0.0)
		var house: Rect2 = screen.view_rect_of(AABB(foot + Vector3(-EarthquakeProps.ROOF.x * 0.5 - swing, 0.0, -0.7), Vector3(EarthquakeProps.ROOF.x + swing * 2.0, EarthquakeProps.ROOF_BASE + EarthquakeProps.ROOF.y + 0.2, 1.4)))
		var knob: Vector2 = screen.view_point(EarthquakeProps.knob_at(0.0))
		var view_box := Rect2(Vector2.ZERO, screen.view.size)
		if not hud.visible or hud.text != Locale.t("earthquake.pull.biggest") or house.has_area() == false \
				or box.intersects(house) or box.has_point(knob) or not view_box.encloses(box):
			problems.append("%s: the word %s, the house %s" % [str(size), str(box), str(house)])
		seen.append("%s word %s house %s" % [str(size), str(box), str(house)])
		screen._on_slingshot("cancel", Vector2(1.0, 0.0))
		screen.get_parent().queue_free()
		await tree.process_frame
	var other := await _open("collision", TABLET)
	other._on_slingshot("pull", Vector2(3.0, 0.0))
	await tree.process_frame
	var centred: Label = other._slingshot_hud
	if absf(centred.position.x + centred.size.x * 0.5 - other.view.size.x * 0.5) > 1.0:
		problems.append("the collision lab's word moved to %s" % str(centred.get_rect()))
	other._on_slingshot("cancel", Vector2(3.0, 0.0))
	other.get_parent().queue_free()
	await tree.process_frame
	expect.call(problems.is_empty(), "earthquake pull's word: off the house (its roof swaying either way) and the knob, inside the view on the phone, desktop and tablet (slingshot_setup readout_at); the collision lab's word still in the top middle",
		"; ".join(problems + seen))


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: EarthquakeGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or game.lamps_lit() != 0 or game.opened() \
			or start.distance_to(EarthquakeGame.HILL_AT + Vector3(0.0, EarthquakeGame.HILL_HEIGHT, 0.0)) > 0.6:
		problems.append("not on the hill's top at the start")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or game.lamps_lit() != 2:
		problems.append("after two stamps: %s, %d lamps" % [game.piece_state, game.lamps_lit()])
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or not game.opened() or game.lamps_lit() != 3 or Vector2(rest.x, rest.z).distance_to(Vector2(EarthquakeGame.LAND_AT.x, EarthquakeGame.LAND_AT.z)) > 2.2 or rest.z < EarthquakeGame.LAND_AT.z:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as EarthquakeGame).take_piece() != null or not (again.game as EarthquakeGame).opened() or (again.game as EarthquakeGame).lamps_lit() != 3:
		problems.append("a finished spot: a piece, or a closed nest")
	expect.call(problems.is_empty(), "earthquake piece: on the hill's top until the last stamp, a lamp lit per stamp, then the stones fall open and it hops down to the table's front (LAND_AT); a finished spot shows the open nest and three lamps, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
