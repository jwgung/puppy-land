## 계절 (#87, 2026-11-07; Hutton Island's third spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after day-night),
##   not one of the first island's; no explanation picture (hutton-lines.md 3 has no "[그림: …]"); the
##   question's and the condition button's pictures are code-drawn kinds; its Korean lines are
##   docs/islands/hutton-lines.md section 3 word for word (the fox's line, Puppy's clue, Dugi's two
##   lines, the question, its choices, reason and bridge, the riddle, every stage's condition, mission,
##   explanation, win, miss and wrong-condition line) with the doc's faces; Puppy's result lines are
##   short with no science words, digits or symbols; English has every line;
## - the model: the four seasons are the orbit's quarters round the solstices and equinoxes
##   (SEASON_HALF_DEG), "ready" until the Earth moves, the upright loop (LOOP_DEG round with the noon
##   sun within SPREAD_MAX_DEG) and never on the tilted Earth, the trail across the March equinox, a
##   reset and a condition starting it over; winter has the lowest noon sun and the shortest day,
##   summer the highest and the longest (SunModel's, not a copy);
## - the judging (MissionRound on the real lab): each stage's hit and misses (Puppy's miss line), the
##   wrong condition's line, nothing while the Earth is held;
## - the condition button: 기울어짐 / 똑바로 (picture buttons on every stage) set the axis and start
##   the run over;
## - no number on the screen: the observations are words, no units, the card is the season; the
##   window's sun and day bar follow the model (higher and longer in summer, the same all round upright);
## - what matters is big and in view: the Earth at the start and at the solstices with the house's flag,
##   big, between the top band and the bottom (the dialogue box, the buttons), the path across the
##   phone, the yard window inside and above the December Earth;
## - the spot: the hutton map's seasons spot is this experiment, the island is still not playable;
## - the opening (the fox first on a first visit), the hand (the Earth follows the finger round its
##   path, a put-down keeps it, a cancel puts it back) and the piece (in the frozen bud until the last
##   stamp, the snowman at the first).
extends RefCounted

const ID := "seasons"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
## The phone (2340 x 1080) and the tablet (1920 x 1200) in UI units at the same height.
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
## A desktop window (1920 x 1080).
const DESKTOP := Vector2(1280, 720)
## In view: inside this margin of the view's sides and top, above the bottom share the dialogue box
## and the buttons take.
const EDGE := 0.03
const BOTTOM_FREE := 0.8
## The Earth also keeps under the top band (the title, the key card and the mission strip under it).
const TOP_FREE := 0.33
## A solstice's globe at least this share of the view's height; the path at least this share of the
## phone's width (#87 Q13).
const GOAL_MIN := 0.28
const PATH_SPAN := 0.4
const LINE_MAX := 24
## How far (deg) the Earth may land from the finger's 50 deg in the drag check (the camera assist).
const DRAG_SLACK := 10.0

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
	check_seasons()
	check_loop()
	await check_judging()
	await check_condition_button()
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


func _lab() -> SeasonsLab:
	var lab := SeasonsLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "seasons: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or island.find(ID) < island.find("day-night"):
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
	var picks: Array = kid.picks.tilt
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["tilted", "upright"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the tilt buttons %s" % str(picks))
	expect.call(problems.is_empty(), "seasons: a valid definition, a Hutton Island lab after day-night (index.json islands), not the first island's; no explanation picture (none in the doc); code-drawn question and tilt pictures",
		"; ".join(problems))


## The section "## 3. 계절" of the lines doc: its numbered lines [who, face, text], the question, the
## riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 3. 계절")
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
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[1] != "계절이 없어요":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.tilt:
		pick_label[p.value] = p.label
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), str(pick_label.get(stage.conditions.tilt, "?")), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "seasons: the Korean lines are hutton-lines.md 3 word for word (the fox, Puppy, Dugi's two lines, the question, the riddle, the three stages with their conditions and wrong-condition lines) with its faces",
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
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/seasons.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/seasons.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.tilt.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "seasons: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

## The tilted Earth's seasons round the path, degree by degree: the quarters round the solstices and
## equinoxes; winter has the lowest noon sun and the shortest days, summer the highest and longest.
func check_seasons() -> void:
	var model := SeasonsModel.new()
	var problems := []
	if model.status() != "ready" or model.input("orbit") != SeasonsModel.START_ORBIT or model.input("tilt") != SunModel.EARTH_TILT:
		problems.append("the start: %s at %.1f" % [model.status(), model.input("orbit")])
	var low := {}
	var high := {}
	for deg in 360:
		model.set_input("orbit", float(deg))
		model.set_input("orbit", float(deg) + 0.5)
		model.set_input("orbit", float(deg))
		var want := "spring"
		var from_dec := absf(wrapf(deg - 270.0, -180.0, 180.0))
		var from_jun := absf(wrapf(deg - 90.0, -180.0, 180.0))
		if from_dec <= SeasonsModel.SEASON_HALF_DEG:
			want = "winter"
		elif from_jun <= SeasonsModel.SEASON_HALF_DEG:
			want = "summer"
		elif deg > 90 and deg < 270:
			want = "autumn"
		if model.status() != want:
			problems.append("%d deg is %s (want %s)" % [deg, model.status(), want])
		var s := model.status()
		low[s] = minf(low.get(s, INF), model.day_share())
		high[s] = maxf(high.get(s, -INF), model.day_share())
		if s == "winter" and model.noon_sun_altitude() >= SunModel.noon_altitude(model.input("latitude"), 0.0):
			problems.append("winter at %d deg has a noon sun as high as the equinox's" % deg)
	# Every winter day is shorter than any spring or autumn one, every summer day longer.
	if not (high.winter <= minf(low.spring, low.autumn) and low.summer >= maxf(high.spring, high.autumn)):
		problems.append("day lengths %s / %s" % [str(low), str(high)])
	model.set_input("orbit", SeasonsModel.DECEMBER)
	var dec := [model.noon_height_share(), model.day_share()]
	model.set_input("orbit", SeasonsModel.JUNE)
	var jun := [model.noon_height_share(), model.day_share()]
	if not (dec[0] < jun[0] and dec[1] < jun[1]) or absf(model.noon_sun_altitude() - SunModel.noon_altitude(SunModel.SEOUL_LATITUDE, SunModel.declination(90.0, SunModel.EARTH_TILT))) > 1e-9:
		problems.append("December %s, June %s" % [str(dec), str(jun)])
	expect.call(problems.is_empty() and SeasonsModel.SEASON_HALF_DEG == 45.0,
		"seasons model: \"ready\" until moved; winter / summer within %.0f deg of the December / June solstice, spring and autumn between; winter's days shortest and its sun low, summer's longest (SunModel's noon sun)" % SeasonsModel.SEASON_HALF_DEG,
		"; ".join(problems.slice(0, 6)))


## Drags `model`'s Earth `deg` degrees (1-degree steps, signed) from where it is.
static func _carry(model: SeasonsModel, deg: float) -> void:
	var steps := int(absf(deg))
	for k in steps:
		model.set_input("orbit", model.input("orbit") + signf(deg))


## The upright loop: LOOP_DEG round the path (either way, across the March equinox) is "loop", less is
## "upright"; back and forth only counts the span; a tilted loop is never one; 다시 and a new tilt
## start the trail over.
func check_loop() -> void:
	var problems := []
	var model := SeasonsModel.new()
	model.set_start("tilt", SunModel.UPRIGHT)
	_carry(model, 10.0)
	if model.status() != "upright":
		problems.append("10 deg: %s" % model.status())
	_carry(model, SeasonsModel.LOOP_DEG - 30.0)
	if model.status() != "upright":
		problems.append("%.0f deg: %s" % [SeasonsModel.LOOP_DEG - 20.0, model.status()])
	_carry(model, 20.0)
	if model.status() != "loop" or model.noon_spread() > 1e-9:
		problems.append("%.0f deg: %s (spread %.4f)" % [SeasonsModel.LOOP_DEG, model.status(), model.noon_spread()])
	model.reset()
	if model.status() != "ready" or model.trail_span() != 0.0:
		problems.append("after a reset: %s, span %.1f" % [model.status(), model.trail_span()])
	_carry(model, -(SeasonsModel.LOOP_DEG + 1.0))   # the other way, across the March equinox
	if model.status() != "loop":
		problems.append("the other way: %s" % model.status())
	model.reset()
	for k in 10:   # back and forth: 200 deg of finger but 20 deg of path
		_carry(model, 20.0 if k % 2 == 0 else -20.0)
	if model.status() != "upright" or absf(model.trail_span() - 20.0) > 1e-6:
		problems.append("back and forth: %s, span %.1f" % [model.status(), model.trail_span()])
	model.set_start("tilt", SunModel.EARTH_TILT)
	_carry(model, 359.0)
	if model.status() == "loop" or model.noon_spread() < SunModel.EARTH_TILT * 1.9:
		problems.append("tilted loop: %s, spread %.1f" % [model.status(), model.noon_spread()])
	model.set_start("tilt", SunModel.UPRIGHT)
	if model.trail_span() != 0.0:
		problems.append("a new tilt kept the trail")
	expect.call(problems.is_empty() and SeasonsModel.LOOP_DEG >= 300.0 and SeasonsModel.SPREAD_MAX_DEG <= 5.0,
		"seasons model: upright, %.0f deg round the path (either way, over the March equinox) is the loop with the noon sun unchanged, less is not, back and forth counts the span; a tilted loop is never one (its sun changes by twice the tilt); 다시 and a new tilt start over" % SeasonsModel.LOOP_DEG,
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, tilt, orbit (deg; "loop": upright, carried round), hit, missed, wrong-condition line]
	var cases := [
		[0, "tilted", 270.0, true, false], [0, "tilted", 230.0, true, false], [0, "tilted", 312.0, true, false],
		[0, "tilted", 225.0, true, false], [0, "tilted", 315.0, true, false], [0, "tilted", 224.0, false, true], [0, "tilted", 316.0, false, true],
		[0, "tilted", 0.0, false, true], [0, "tilted", 320.0, false, true], [0, "tilted", 90.0, false, true], [0, "tilted", 180.0, false, true],
		[0, "upright", 270.0, false, true],
		[1, "upright", "loop", true, false], [1, "upright", 200.0, false, true], [1, "tilted", "loop", false, true], [1, "tilted", 270.0, false, true],
		[2, "tilted", 90.0, true, false], [2, "tilted", 50.0, true, false], [2, "tilted", 130.0, true, false],
		[2, "tilted", 45.0, true, false], [2, "tilted", 135.0, true, false], [2, "tilted", 44.0, false, true], [2, "tilted", 136.0, false, true],
		[2, "tilted", 140.0, false, true], [2, "tilted", 270.0, false, true], [2, "tilted", 0.0, false, true],
		[2, "upright", 90.0, false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_control("tilt", case[1])
		if str(case[2]) == "loop":
			_carry(lab.model, 360.0)
		else:
			lab.model.set_input("orbit", float(case[2]) + 1.0)
			lab.model.set_input("orbit", float(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s at %s (%s): stamps %d missed %s" % [stage + 1, case[1], str(case[2]), status, stamps, missed])
	var wants := [["tilted", "기울어진 지구를 골라 봐!"], ["upright", "똑바로 선 지구를 골라 봐!"], ["tilted", "기울어진 지구를 골라 봐!"]]
	for i in 3:
		lab.set_control("tilt", "upright" if wants[i][0] == "tilted" else "tilted")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong condition says '%s'" % [i + 1, line[0]])
	lab.set_control("tilt", "tilted")
	lab.manipulation_started(SeasonsLab.KNOB_ID)
	lab.model.set_input("orbit", 270.0)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the Earth is held")
	lab.manipulation_cancelled(SeasonsLab.KNOB_ID)
	expect.call(problems.is_empty(), "seasons judging: winter / the upright loop / summer hit inside their windows and miss outside (Puppy's line), the wrong axis says the doc's \"…지구를 골라 봐!\" line; not judged while held",
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
		if groups.size() != 1 or groups[0].control != "tilt" or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	if lab.control_value("tilt") != "tilted" or absf(lab.props.axis.basis.y.angle_to(Vector3.UP) - deg_to_rad(SunModel.EARTH_TILT)) > 1e-4 or lab.props.axis.basis.y.x <= 0.0:
		problems.append("the start is not the tilted axis (leaning right)")
	lab.model.set_input("orbit", 200.0)
	var resets := lab.reset_count
	lab.set_control("tilt", "upright")
	if lab.model.input("tilt") != SunModel.UPRIGHT or lab.props.axis.basis.y.angle_to(Vector3.UP) > 1e-4 or lab.reset_count != resets + 1 \
			or lab.model.input("orbit") != SeasonsModel.START_ORBIT or lab.status() != "ready":
		problems.append("upright: tilt %.2f, axis %s, orbit %.1f, %s" % [lab.model.input("tilt"), str(lab.props.axis.basis.y), lab.model.input("orbit"), lab.status()])
	lab.reset_run()
	if lab.model.input("tilt") != SunModel.UPRIGHT:
		problems.append("다시 lost the condition")
	lab.set_control("tilt", "tilted")
	if lab.model.input("tilt") != SunModel.EARTH_TILT:
		problems.append("tilted again: %.2f" % lab.model.input("tilt"))
	expect.call(problems.is_empty(), "seasons condition button: 기울어짐 / 똑바로 on every stage; the axis leans by the Earth's tilt (to the right) or stands straight, a new choice starts the run over, 다시 keeps it",
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
	var heights := []
	var days := []
	for orbit: float in [SeasonsModel.DECEMBER, SeasonsModel.MARCH, SeasonsModel.JUNE]:
		lab.model.set_input("orbit", orbit)
		lab._show()
		heights.append(lab.props.shown_height)
		days.append(lab.props.shown_day)
		for key: String in lab.observations():
			var value: Variant = lab.observations()[key]
			if not value is String or str(value) == "" or digits.search(str(value)) != null:
				problems.append("%s at %.0f: %s" % [key, orbit, str(value)])
	if not (heights[0] < heights[1] and heights[1] < heights[2] and days[0] < days[1] and days[1] < days[2]):
		problems.append("the window's sun %s and day %s" % [str(heights), str(days)])
	lab.model.set_input("orbit", SeasonsModel.DECEMBER)
	lab._show()
	if lab.props.shown_snow < 0.99:
		problems.append("no snow in winter")
	lab.set_control("tilt", "upright")
	var same := []
	for orbit: float in [0.0, 90.0, 180.0, 270.0]:
		lab.model.set_input("orbit", orbit)
		lab._show()
		same.append(Vector2(lab.props.shown_height, lab.props.shown_day))
	if same.any(func(v: Vector2) -> bool: return v.distance_to(same[0]) > 1e-3):
		problems.append("upright window %s" % str(same))
	expect.call(problems.is_empty(), "seasons: no number on the screen (the observations are words, no units, the card is the season); the window's noon sun and day bar are lower and shorter in winter (with snow), higher and longer in summer, the same all round upright",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

## What matters is big and in the clear on the phone's, the desktop's and the tablet's front view
## (#87 Q13: the globe 1.65 times bigger; Q14: all the way round): the Earth with the house's flag, at
## every place of its path (the start behind the sun, the solstices of the stages, the near September
## side), stays between the top band (TOP_FREE: the title, the card and the mission strip) and the
## bottom (BOTTOM_FREE: the dialogue box, the buttons) and inside the sides. A solstice's globe is
## GOAL_MIN of the height or more, the path spans PATH_SPAN of the phone's width or more, and the yard
## window is inside the view, above the December globe, its flag and its axis (the window never hides behind
## the Earth). The start Earth, behind the sun, shows its upper half above the sun and its rays.
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
		var inside := func(p: Vector2, what: String, top: float) -> void:
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < top or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		var span := Vector2(1.0, 0.0)
		var goal := 1.0
		var flag_top := 1.0
		for k in 24:   # every 15 deg all the way round (Q14: the near side too)
			var orbit := 15.0 * k
			lab.model.set_input("orbit", orbit)
			lab._show()
			var c := SeasonsProps.earth_center(orbit)
			var box := []
			for d: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
				var p: Vector2 = at.call(c + d * SeasonsProps.GLOBE_RADIUS)
				inside.call(p, "globe at %.0f" % orbit, TOP_FREE)
				box.append(p)
			var flag: Vector2 = at.call((lab.props.house.get_node("Flag") as MeshInstance3D).global_transform * Vector3(0.0, DayNightProps.FLAG_POLE, 0.0))
			inside.call(flag, "flag at %.0f" % orbit, TOP_FREE)
			span = Vector2(minf(span.x, box[2].x), maxf(span.y, box[3].x))
			if orbit in [90.0, 270.0]:
				goal = minf(goal, box[1].y - box[0].y)
			if orbit == 270.0:
				var tip: Vector2 = at.call(c + SeasonsProps.north(SunModel.EARTH_TILT) * (SeasonsProps.GLOBE_RADIUS + SeasonsProps.ROD_OUT))
				flag_top = minf(minf(box[0].y, flag.y), tip.y)
		# The start Earth (behind the sun) shows its upper half over the sun and its rays.
		var sun_top: Vector2 = at.call(SeasonsProps.SUN_CENTER + Vector3.UP * SeasonsProps.SUN_RADIUS * 1.55)
		var start: Vector2 = at.call(SeasonsProps.earth_center(SeasonsModel.START_ORBIT))
		if sun_top.y <= start.y:
			problems.append("%s: the sun (top %.2f) covers the start Earth's middle (%.2f)" % [str(size), sun_top.y, start.y])
		var window: Node3D = lab.props.window
		var half := SeasonsProps.WINDOW_SIZE * 0.5 + Vector2(0.5, 0.65)   # (window local: its scale is the node's)
		var low := 0.0
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var p: Vector2 = at.call(window.global_transform * Vector3(corner.x * half.x, corner.y * half.y, 0.0))
			inside.call(p, "window corner", EDGE)
			low = maxf(low, p.y)
		if low >= flag_top:
			problems.append("%s: the window (to %.2f) comes down over the December Earth (%.2f)" % [str(size), low, flag_top])
		if goal < GOAL_MIN:
			problems.append("%s: a solstice's globe is only %.2f of the height" % [str(size), goal])
		if size == PHONE and span.y - span.x < PATH_SPAN:
			problems.append("the path spans %.2f of the phone's width" % (span.y - span.x))
		seen.append("%s solstice globe %.2f, path %.2f..%.2f, window to %.2f" % [str(size), goal, span.x, span.y, low])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "seasons in view: the Earth all the way round its path (the start, the solstices, the near side) with its flag between the top band (%.0f%%) and the bottom %.0f%%, a solstice's globe %.0f%% of the height or more, the path across %.0f%% of the phone's width or more, the start Earth's upper half over the sun, the yard window inside and above the December Earth (phone, desktop and tablet)" % [TOP_FREE * 100.0, (1.0 - BOTTOM_FREE) * 100.0, GOAL_MIN * 100.0, PATH_SPAN * 100.0],
		"; ".join(problems.slice(0, 4) + seen))


# --- the pictures ---------------------------------------------------------------------------------

## The question's seasons pictures (PredictPictures) and the condition buttons' earth axis pictures
## (PickPictures) draw on a canvas of their button's size without errors.
func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["seasons_change", "seasons_same"]
	var pick_kinds := ["earth_tilted", "earth_upright"]
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
		"seasons pictures: the question's seasons kinds (PredictPictures) and the earth axis kinds (PickPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[2]) != ID:
		problems.append("seasons is not hutton's third spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if hutton.playable():
		problems.append("hutton is playable before all its spots are labs")
	expect.call(problems.is_empty(), "seasons: Hutton Island's third spot is an experiment (a lab on its map); the island is not playable until every spot is", "; ".join(problems))


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
	expect.call(first_ok and later == ["dugi", "dugi"] and Story.KEEPER == "fox" and Locale.t("speaker.fox") == "여우친구",
		"seasons opening: first visit the fox (여우친구, worried), Puppy's clue, Dugi's two lines, then the question; later visits Dugi's two lines",
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
	var start: float = lab.model.input("orbit")
	# A press on the globe's upper left (not its middle) picks the Earth.
	var at: Vector2 = screen.call(SeasonsProps.earth_center(start) + Vector3(-0.8, 0.6, 0.6))
	m.handle_pointer("press", at)
	if m.mode != "drag" or m.active_id != SeasonsLab.KNOB_ID or lab.holding != SeasonsLab.KNOB_ID:
		problems.append("press on the globe: mode '%s' id '%s'" % [m.mode, m.active_id])
	# 50 deg the true way: the finger moves as the Earth's centre would.
	var shift: Vector2 = screen.call(SeasonsProps.earth_center(start + 50.0)) - screen.call(SeasonsProps.earth_center(start))
	m.handle_pointer("move", at + shift * 0.5)
	m.handle_pointer("move", at + shift)
	await tree.process_frame
	# (The flat front view looks along the path's plane: the shell's drag assist tips the camera to it
	# while the finger holds, so the same finger point lands a little farther round: DRAG_SLACK.)
	var held := wrapf(lab.model.input("orbit") - start, -180.0, 180.0)
	if absf(held - 50.0) > DRAG_SLACK or lab.settled():
		problems.append("held: %.2f deg (want 50)" % held)
	m.handle_pointer("release", at + shift)
	var placed := wrapf(lab.model.input("orbit") - start, -180.0, 180.0)
	for i in 10:
		await tree.physics_frame
	if absf(wrapf(lab.model.input("orbit") - start, -180.0, 180.0) - placed) > 1e-9:
		problems.append("it went on moving after the finger left")
	if lab.holding != "" or not lab.settled() or not lab.placements().has(SeasonsLab.KNOB_ID) \
			or lab.props.earth.position.distance_to(SeasonsProps.earth_center(lab.model.input("orbit"))) > 1e-4:
		problems.append("put down: holding '%s'" % lab.holding)
	var saved: Dictionary = lab.placements()
	var other := _lab()
	tree.root.add_child(other)
	await tree.process_frame
	other.manipulation_placed(SeasonsLab.KNOB_ID, saved[SeasonsLab.KNOB_ID])
	if absf(wrapf(other.model.input("orbit") - lab.model.input("orbit"), -180.0, 180.0)) > 1e-3:
		problems.append("restored at %.3f (was %.3f)" % [other.model.input("orbit"), lab.model.input("orbit")])
	other.queue_free()
	await tree.process_frame
	var before: float = lab.model.input("orbit")
	at = screen.call(SeasonsProps.earth_center(before))
	m.handle_pointer("press", at)
	m.handle_pointer("move", at + Vector2(-120.0, -30.0))
	await tree.process_frame
	m.handle_pointer("cancel", at + Vector2(-120.0, -30.0))
	if absf(wrapf(lab.model.input("orbit") - before, -180.0, 180.0)) > 1e-3 or lab.holding != "":
		problems.append("cancel left it %.2f deg away" % wrapf(lab.model.input("orbit") - before, -180.0, 180.0))
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != SeasonsLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "seasons hand: a press on the globe picks the Earth, it follows the finger round its path (50 deg), no motion after the finger leaves, a put-down keeps (and restores) it, a cancel puts it back; the hand guide drags it",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: SeasonsGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or start.distance_to(game.bud.global_position) > 2.6 or game.snowman.visible or game.bloomed():
		problems.append("not in the closed bud at the start (or a snowman already)")
	var flag: MeshInstance3D = lab.props.house.get_node_or_null("Flag")
	if flag == null or flag.material_override != lab.props.bright_material:
		problems.append("no bright flag on the house")
	game.show_stage(1, 1, true)
	for i in 60:
		await tree.process_frame
	if not game.snowman.visible or game.snowman.scale.x < 0.99:
		problems.append("no snowman after winter")
	game.show_stage(2, 2, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or game.bloomed():
		problems.append("out before the last stamp (%s)" % game.piece_state)
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 400:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or not game.bloomed() or absf(rest.y - SeasonsProps.STAGE_TOP - LabGame.PIECE_SIZE) > 0.12 or rest.distance_to(start) < 1.0:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as SeasonsGame).take_piece() != null or not (again.game as SeasonsGame).bloomed() or not (again.game as SeasonsGame).snowman.visible:
		problems.append("a finished spot: a piece, or a closed bud")
	expect.call(problems.is_empty(), "seasons piece: the piece in the frozen bud until the last stamp (a snowman after winter), then the flower opens and it jumps out onto the stage for the cat; a finished spot shows the flower open and the snowman, no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
