## 낮과 밤 (#74, 2026-11-06; Hutton Island's first spot):
## - the data: the definition is valid, it is the hutton island's lab (index.json `islands`), not one
##   of the first island's, and its Korean lines are docs/islands/hutton-lines.md section 1 word for
##   word (the fox's line, Puppy's clue, Dugi's three lines with the axis picture on the second, the
##   question, its choices, reason and bridge, every stage's mission, explanation, win and miss; the
##   morning-evening picture on stage 3's), with the doc's faces; Puppy's result lines are short with
##   no science words, digits or symbols; English has the same lines;
## - the model's bands at the equinox, minute by minute: noon within 1 h of 12, midnight within 3 h,
##   the morning within 1 h of the geometric sunrise, the evening within 1 h of the sunset;
## - the judging (MissionRound on the real lab): each stage's hit at its band's middle and inside its
##   edges, its misses (Puppy's miss line), the morning stage's evening miss with "그건 해 지는 쪽이야!
##   반대편!" and no line at all for a noon or a night then; no clock time among the observations;
## - the spot: the hutton map's day-night spot is this experiment;
## - the round's opening on a first visit: the fox, Puppy's clue, Dugi's three lines (the picture on
##   the second), then the question; a later visit: Dugi's three lines only;
## - the hand: a press anywhere on the globe picks the Earth, a drag turns it one to one with the
##   finger (its front point follows the finger on screen) either way, no footprint marker, no turn
##   after the finger stops, a put-down keeps the turn (and restores it), a cancel puts it back;
## - the piece: in the rock's crevice until the last stamp, then out of the globe onto the stage.
extends RefCounted

const ID := "day-night"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const LINE_MAX := 24
const MINUTES := 1440

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
	check_bands()
	await check_judging()
	check_spot()
	check_opening()
	await check_drag()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> DayNightLab:
	var lab := DayNightLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "day-night: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if island.is_empty() or island[0] != ID:
		problems.append("hutton's labs %s (day-night first)" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	if not ExperimentRegistry.island_labs("mechanics").is_empty():
		problems.append("the first island has island labs")
	var kid: Dictionary = definition.kid
	if ExplainPictures.picture_or_none(kid.intro_more[0].get("picture")) != "axis" or kid.intro_more[1].has("picture") or kid.has("intro_picture"):
		problems.append("the axis picture is not on Dugi's second line alone")
	var stages: Array = definition.missions.stages
	for i in stages.size():
		var want := "morning_evening" if i == 2 else ""
		if ExplainPictures.picture_or_none(stages[i].get("say_picture")) != want:
			problems.append("stage %d's picture %s" % [i + 1, str(stages[i].get("say_picture"))])
	expect.call(problems.is_empty(), "day-night: a valid definition, Hutton Island's lab (index.json islands), not the first island's; the axis picture on Dugi's second line, the morning-evening picture on stage 3",
		"; ".join(problems))


## The section "## 1. 낮과 밤" of the lines doc: its numbered lines [who, face, text], the question's
## block and the stage table's rows (cells), the "[그림: …]" notes cut off.
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 1. 낮과 밤")
	var end := text.find("\n## ", start + 4)
	var lines := text.substr(start, end - start).split("\n")
	var out := {"lines": [], "rows": [], "question": {}}
	var said := RegEx.create_from_string("^\\d+\\. (\\S+)\\((\\S+)\\): (.+)$")
	var asked := RegEx.create_from_string("^\\d+\\. 질문\\((\\S+), (\\S+)\\): (.+)$")
	var picture := RegEx.create_from_string(" ?\\[그림: [^\\]]*\\]")
	for raw in lines:
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
		elif line.begins_with("- 이유:"):
			out.question.reason = line.trim_prefix("- 이유:").strip_edges()
		elif line.begins_with("- 다리:"):
			out.question.bridge = line.trim_prefix("- 다리:").strip_edges()
		elif line.begins_with("- 지도 수수께끼(퍼피):"):
			out.riddle = line.trim_prefix("- 지도 수수께끼(퍼피):").strip_edges()
		elif line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			out.rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return picture.sub(c.strip_edges(), "", true)))
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
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != want[2]:
				problems.append("line %d: %s/%s '%s' (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(want)])
	var predict := MissionRound.predict(definition)
	var q: Dictionary = doc.question
	var labels: Array = predict.choices.map(func(c: Dictionary) -> String: return str(c.label))
	if predict.question != q.get("text") or predict.get("question_face") != faces.get(q.get("face")) or labels != q.get("choices") \
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or str(predict.answer) != "earth" or labels[1] != "지구가 돌아":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var row: Array = doc.rows[i]
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), stage.text, stage.say, stage.win, stage.miss, "—"]
			if got != row:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(row)])
	expect.call(problems.is_empty(), "day-night: the Korean lines are hutton-lines.md 1 word for word (the fox, Puppy, Dugi's three lines, the question, the riddle, the three stages) with its faces",
		"; ".join(problems))


## Puppy's win and miss lines: short, no science words, no digits or symbols (the first island's
## rule, hands_on_checks); English has every line too.
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
	var english: Dictionary = Locale.words("experiments/day-night.json")
	Locale.lang = "en"
	var en: Dictionary = Locale.overlay(JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/day-night.json")), Locale.words("experiments/day-night.json"))
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.kid.intro_more.size() != 2 or en.missions.stages.any(func(s: Dictionary) -> bool: return str(s.get("miss", "")) == "" or str(s.get("say", "")) == "") \
			or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "day-night: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model's bands ----------------------------------------------------------------------------

func check_bands() -> void:
	var model := DayNightModel.new()
	var problems := []
	var seen := {}
	for minute in MINUTES:
		model.set_input("rotation", SunModel.rotation_at(minute / 60.0))
		var hour := minute / 60.0
		var want := "night"
		if absf(hour - 6.0) <= 1.0:
			want = "sunrise"
		elif absf(hour - 18.0) <= 1.0:
			want = "sunset"
		elif absf(hour - 12.0) <= 1.0:
			want = "noon"
		elif hour <= 3.0 or hour >= 21.0:
			want = "midnight"
		elif hour > 6.0 and hour < 18.0:
			want = "day"
		# The geometric sunrise at the equinox is 6:00 to within a minute (no refraction): the band's
		# edges are judged a minute away.
		var edge := absf(absf(hour - 6.0) - 1.0) < 0.02 or absf(absf(hour - 18.0) - 1.0) < 0.02
		if model.status() != want and not edge:
			problems.append("%02d:%02d is %s (want %s)" % [minute / 60, minute % 60, model.status(), want])
		seen[model.status()] = true
	model.reset()
	if model.status() != "night" or absf(model.hours_from_noon() + 8.5) > 1e-9 or model.input("orbit") != DayNightModel.EQUINOX_ORBIT:
		problems.append("the start: %s, %.2f h from noon, orbit %.1f" % [model.status(), model.hours_from_noon(), model.input("orbit")])
	expect.call(problems.is_empty() and seen.size() == 6,
		"day-night model at the equinox: noon 11-13 h, midnight 21-3 h, the morning 5-7 h and the evening 17-19 h round the sun's rise and set, day and night between; it starts in the night before the dawn",
		"; ".join(problems.slice(0, 6)))


# --- the judging ----------------------------------------------------------------------------------

func _at(lab: DayNightLab, hour: float) -> void:
	lab.model.set_input("rotation", SunModel.rotation_at(hour))


func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, hour, hit, missed (Puppy's miss line)]
	var cases := [
		[0, 12.0, true, false], [0, 11.1, true, false], [0, 12.9, true, false], [0, 13.2, false, true], [0, 10.7, false, true],
		[0, 6.0, false, true], [0, 0.0, false, true], [0, 19.5, false, true],
		[1, 0.0, true, false], [1, 22.0, true, false], [1, 2.8, true, false], [1, 20.5, false, true], [1, 12.0, false, true],
		[1, 6.3, false, true],
		[2, 6.0, true, false], [2, 5.1, true, false], [2, 6.9, true, false], [2, 18.0, false, true], [2, 17.2, false, true],
		[2, 12.0, false, false], [2, 0.0, false, false], [2, 8.0, false, false],
	]
	for case: Array in cases:
		var stage := int(case[0])
		_at(lab, float(case[1]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[2]) or missed != bool(case[3]):
			problems.append("stage %d at %.1f h (%s): stamps %d missed %s" % [stage + 1, case[1], status, stamps, missed])
	var evening := MissionRound.result_line(definition, 2, false)
	if evening[0] != "그건 해 지는 쪽이야! 반대편!":
		problems.append("the evening line '%s'" % evening[0])
	lab.manipulation_started(DayNightLab.KNOB_ID)
	_at(lab, 12.0)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the Earth is held")
	lab.manipulation_cancelled(DayNightLab.KNOB_ID)
	var shown := lab.observations().keys()
	if shown.any(func(k: String) -> bool: return k in ["hour", "day_length"]) or definition.observations.any(func(o: Dictionary) -> bool: return str(o.get("unit", "")) in ["h", "s"]):
		problems.append("a clock among the observations %s" % str(shown))
	expect.call(problems.is_empty(), "day-night judging: noon / midnight / the morning hit inside their bands and miss outside (Puppy's line), the morning stage's evening miss says \"그건 해 지는 쪽이야! 반대편!\" and a noon or a night says nothing then; not judged while held; no clock time shown",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[0]) != ID:
		problems.append("day-night is not hutton's first spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if Story.SPEAKERS.get(Story.KEEPER, []).is_empty():
		problems.append("the keeper %s is not a speaker" % Story.KEEPER)
	expect.call(problems.is_empty(), "day-night: Hutton Island's first spot is an experiment (a lab on its map)", "; ".join(problems))


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
	while round.phase() == MissionRound.Phase.CLUE:
		var line := round.clue_to_open()
		told.append([line.speaker, line.face, line.picture])
		round.clue_opened()
		round.clue_read()
		if told.size() > 8:
			break
	var first_ok := told == [[Story.KEEPER, "worried", ""], ["puppy", "thinking", ""], ["dugi", "explain", ""], ["dugi", "explain", "axis"], ["dugi", "explain", ""]] \
		and round.phase() == MissionRound.Phase.ASKING and store.clue_seen(ID)
	var again := MissionRound.new(definition, store)
	again.start()
	again.open(true)
	var later := []
	while again.phase() == MissionRound.Phase.CLUE and later.size() < 8:
		later.append(again.clue_to_open().speaker)
		again.clue_opened()
		again.clue_read()
	Story.enabled = was
	expect.call(first_ok and later == ["dugi", "dugi", "dugi"],
		"day-night opening: first visit the fox (worried), Puppy's clue, Dugi's three lines (the axis picture on the second), then the question; later visits Dugi's three lines",
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
	var radius := DayNightProps.GLOBE_RADIUS
	var center: Vector3 = lab.props.globe.global_position
	var front := center + Vector3(0.0, 0.0, radius)
	var screen := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / per_unit
	var problems := []
	var start: float = lab.model.input("rotation")
	# A press on the globe's left part (not its middle) picks the Earth.
	var at: Vector2 = screen.call(center + Vector3(-radius * 0.6, radius * 0.3, radius * 0.7))
	m.handle_pointer("press", at)
	if m.mode != "drag" or m.active_id != DayNightLab.KNOB_ID or lab.holding != DayNightLab.KNOB_ID:
		problems.append("press on the globe: mode '%s' id '%s'" % [m.mode, m.active_id])
	# 30 deg the true way: the front point moves R * 30 deg to the right on its plane.
	var shift := radius * deg_to_rad(30.0)
	var right: Vector2 = screen.call(front + Vector3(shift, 0.0, 0.0)) - screen.call(front)
	m.handle_pointer("move", at + right * 0.5)
	m.handle_pointer("move", at + right)
	await tree.process_frame
	var held := _turn(lab.model.input("rotation") - start)
	if absf(held - 30.0) > 0.5 or lab.settled():
		problems.append("held: turned %.2f deg (want 30)" % held)
	if m.get_children().any(func(n: Node) -> bool: return n is MeshInstance3D and n.name.begins_with("Footprint") and (n as MeshInstance3D).visible):
		problems.append("a footprint marker shows")
	# The finger stays: no turn after it (no inertia).
	for i in 10:
		await tree.physics_frame
	if absf(_turn(lab.model.input("rotation") - start) - held) > 1e-9:
		problems.append("it went on turning")
	m.handle_pointer("release", at + right)
	var placed := _turn(lab.model.input("rotation") - start)
	if absf(placed - 30.0) > 0.5 or lab.holding != "" or not lab.settled() or not lab.placements().has(DayNightLab.KNOB_ID):
		problems.append("put down: %.2f deg, holding '%s'" % [placed, lab.holding])
	# The knob is back over the globe's face: a second drag the other way, 50 deg back.
	await tree.process_frame
	at = screen.call(center + Vector3(radius * 0.4, -radius * 0.2, radius * 0.85))
	m.handle_pointer("press", at)
	var left: Vector2 = screen.call(front + Vector3(-radius * deg_to_rad(50.0), 0.0, 0.0)) - screen.call(front)
	m.handle_pointer("move", at + left)
	await tree.process_frame
	m.handle_pointer("release", at + left)
	var back := _turn(lab.model.input("rotation") - start)
	if absf(back + 20.0) > 0.7:
		problems.append("the other way: %.2f deg (want -20)" % back)
	# A restored place: the same turn on a new lab.
	var saved: Dictionary = lab.placements()
	var other := _lab()
	tree.root.add_child(other)
	await tree.process_frame
	other.manipulation_placed(DayNightLab.KNOB_ID, saved[DayNightLab.KNOB_ID])
	if absf(_turn(other.model.input("rotation") - lab.model.input("rotation"))) > 1e-3:   # (a place is float32)
		problems.append("restored at %.3f (was %.3f)" % [other.model.input("rotation"), lab.model.input("rotation")])
	other.queue_free()
	# A cancel (a second finger) puts it back.
	var before: float = lab.model.input("rotation")
	at = screen.call(center + Vector3(0.0, 0.0, radius))
	m.handle_pointer("press", at)
	m.handle_pointer("move", at + right)
	await tree.process_frame
	m.handle_pointer("cancel", at + right)
	if absf(_turn(lab.model.input("rotation") - before)) > 1e-3 or lab.holding != "":
		problems.append("cancel left it at %.2f deg" % _turn(lab.model.input("rotation") - before))
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != DayNightLab.KNOB_ID or (guide.to as Vector3).x <= (guide.from as Vector3).x:
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "day-night hand: a press anywhere on the globe picks the Earth, a drag turns it one to one with the finger either way (30 deg, then 50 back), no footprint, no turn after the finger stops, a put-down keeps (and restores) it, a cancel puts it back; the hand guide drags it the true way (right)",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


## A turn the short way round (deg, -180..180).
static func _turn(deg: float) -> float:
	return wrapf(deg, -180.0, 180.0)


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: DayNightGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or start.distance_to(lab.props.house.global_position) > 0.6:
		problems.append("not in the crevice by the house at the start")
	# The house's flag (Q10): on the house, standing out of the globe, always bright.
	var flag: MeshInstance3D = lab.props.house.get_node_or_null("Flag")
	if flag == null or flag.material_override != lab.props.bright_material or flag.get_aabb().end.y < DayNightProps.FLAG_POLE - 0.05:
		problems.append("no bright flag on the house")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held":
		problems.append("out before the last stamp (%s)" % game.piece_state)
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or absf(rest.y - LabGame.PIECE_SIZE) > 0.12 or rest.distance_to(start) < 1.0:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	var taken: Variant = game.take_piece()
	if not taken is Vector3 or game.piece.visible:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as DayNightGame).take_piece() != null:
		problems.append("a piece in a finished spot")
	expect.call(problems.is_empty(), "day-night piece and flag: the house has a bright flag standing out of the globe; the piece is in the rock's crevice by the house until the last stamp, then out of the globe onto the stage for the cat; none in a finished spot",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
