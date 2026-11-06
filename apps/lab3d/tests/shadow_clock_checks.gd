## 그림자 시계 (#86, 2026-11-07; Hutton Island's second spot):
## - the data: the definition is valid, it is the hutton island's second lab (index.json `islands`,
##   after day-night), not one of the first island's; its Korean lines are docs/islands/hutton-lines.md
##   section 2 word for word (the fox, Puppy's clue, the fox's answer, Dugi's two lines, the question
##   with its choices, reason and bridge, the riddle, every stage's condition, mission, explanation,
##   win, miss and wrong-condition line) with the doc's faces; no picture card (the section has none);
##   Puppy's result lines are short with no science words, digits or symbols; English has every line;
##   no words of the lab hold a digit (no clock time on the screen);
## - the model: the judging widths (named constants) are generous (each target about an hour of the
##   sun's path or more), the short stick's tip never comes to the stone nor the long one's to the
##   bed, the bed is reached with the morning sun only, the shadow points away from the sun and
##   shortens as the sun climbs; the start is mid-morning, on no target;
## - the judging (MissionRound on the real lab): each stage's hits and misses, the west-sun miss of
##   stage 2 ("해를 반대쪽 하늘로 옮겨 봐!"), the wrong stick's lines (the short stick in stage 3:
##   never a stamp at any sun, "긴 막대를 골라 봐!"); not judged while held; no clock time observed;
## - the condition button: the stick's height changes and the sun stays (the shadow grows 2.5 times);
##   처음으로 keeps the stick; the picture buttons are the short and the long stick;
## - the spot: hutton's second spot is this experiment, the island still not playable;
## - the opening: first visit the fox, Puppy, the fox (her name tag from ui.json speaker.fox), Dugi's
##   two lines, then the question; later visits Dugi's two lines;
## - the hand: a press on the sun picks it, a drag takes it along its path (to the noon sun, to the
##   path's low end at most), no footprint, a put-down keeps (and restores) it, a cancel puts it back;
## - the view (phone and tablet): the stick, the bed, the stone and the shadow's tip at each goal are
##   on the screen, clear of the dialogue box, the chips and the picture buttons;
## - the piece: in the cage on the stone until the last stamp, then out onto the yard.
extends RefCounted

const ID := "shadow-clock"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const UI_THEME := "res://scripts/app/ui_theme.gd"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const LINE_MAX := 24
## A target is at least this much of the sun's path wide (h): a child need not be exact.
const MIN_BAND_HOURS := 0.75
const STEP_HOURS := 0.01

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
	await check_condition()
	check_spot()
	check_opening()
	await check_drag()
	for size: Vector2 in [PHONE, TABLET]:
		await check_view(size)
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> ShadowClockLab:
	var lab := ShadowClockLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "shadow-clock: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("hutton").map(func(d: Dictionary) -> String: return str(d.id))
	if island.size() < 2 or island[0] != "day-night" or island[1] != ID:
		problems.append("hutton's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var kid: Dictionary = definition.kid
	if kid.has("intro_picture") or kid.intro_more.any(func(l: Dictionary) -> bool: return l.has("picture")):
		problems.append("a picture card on Dugi's introduction (the doc has none)")
	for stage: Dictionary in definition.missions.stages:
		if stage.has("say_picture"):
			problems.append("a picture card on a stage (the doc has none)")
	var pictures: Array = MissionRound.predict(definition).choices.map(func(c: Dictionary) -> String: return str(c.picture))
	if pictures != ["shadow_short", "shadow_long"] or not pictures.all(func(p: String) -> bool: return p in PredictPictures.KINDS):
		problems.append("the question's pictures %s" % str(pictures))
	var picks: Array = ConditionPicks.picks(definition).get("stick", [])
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["short", "long"] or not picks.all(func(p: Dictionary) -> bool: return p.picture == "stick" and "stick" in PickPictures.KINDS) \
			or float(picks[0].size) >= float(picks[1].size):
		problems.append("the stick buttons %s" % str(picks))
	# No digit in any of the lab's words (no clock time, no number told), in either language.
	for code in Locale.LANGUAGES:
		var text := FileAccess.get_file_as_string("res://content/locale/%s/experiments/%s.json" % [code, ID])
		if RegEx.create_from_string("[0-9]").search(text) != null:
			problems.append("%s words hold a digit" % code)
	expect.call(problems.is_empty(), "shadow-clock: a valid definition, Hutton Island's second lab (after day-night), not the first island's; no picture card (the doc has none); the question's pictures and the stick buttons; no digit in its words",
		"; ".join(problems))


## The section "## 2. 그림자 시계" of the lines doc: its numbered lines [who, face, text], the
## question's block, the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 2. 그림자 시계")
	var end := text.find("\n## ", start + 4)
	var lines := text.substr(start, end - start).split("\n")
	var out := {"lines": [], "rows": [], "question": {}}
	var said := RegEx.create_from_string("^\\d+\\. (\\S+)\\((\\S+)\\): (.+)$")
	var asked := RegEx.create_from_string("^\\d+\\. 질문\\((\\S+), (\\S+)\\): (.+)$")
	for raw in lines:
		var line := raw.strip_edges()
		if line.contains("[그림:"):
			out.picture = true
		var q := asked.search(line)
		if q != null:
			out.question = {"who": q.get_string(1), "face": q.get_string(2), "text": q.get_string(3)}
			continue
		var m := said.search(line)
		if m != null:
			out.lines.append([m.get_string(1), m.get_string(2), m.get_string(3)])
		elif line.begins_with("- 고르기:"):
			out.question.choices = Array(line.trim_prefix("- 고르기:").split("/")).map(func(c: String) -> String: return c.strip_edges().replace("**", ""))
			out.question.answer = Array(line.trim_prefix("- 고르기:").split("/")).map(func(c: String) -> bool: return c.contains("**"))
		elif line.begins_with("- 이유:"):
			out.question.reason = line.trim_prefix("- 이유:").strip_edges()
		elif line.begins_with("- 다리:"):
			out.question.bridge = line.trim_prefix("- 다리:").strip_edges()
		elif line.begins_with("- 지도 수수께끼(퍼피):"):
			out.riddle = line.trim_prefix("- 지도 수수께끼(퍼피):").strip_edges()
		elif line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			out.rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges()))
	return out


## The condition cell of each stage row in hutton-missions.md "### 2. 그림자 시계".
func _missions_conditions() -> Array:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 2. 그림자 시계")
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
	if doc.lines.size() != 5 or opening.size() != 5:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 5:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != want[2] or got.picture != "":
				problems.append("line %d: %s/%s '%s' (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(want)])
	if doc.get("picture", false):
		problems.append("the doc's section has a picture card now: put it on its line")
	var predict := MissionRound.predict(definition)
	var q: Dictionary = doc.question
	var labels: Array = predict.choices.map(func(c: Dictionary) -> String: return str(c.label))
	var answer := labels.find(predict.choices.filter(func(c: Dictionary) -> bool: return c.id == predict.answer)[0].label)
	if predict.question != q.get("text") or predict.get("question_face") != faces.get(q.get("face")) or labels != q.get("choices") \
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or not q.get("answer", [])[answer]:
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	# The stick of each stage: the missions doc's table (| 단계 | 조건 | 미션 | 판정 |).
	var sticks := {"짧은": "short", "긴": "long"}
	var conditions := _missions_conditions()
	var stages: Array = definition.missions.stages
	if doc.rows.size() != 3 or conditions.size() != 3:
		problems.append("%d doc rows, %d mission rows" % [doc.rows.size(), conditions.size()])
	else:
		for i in 3:
			var row: Array = doc.rows[i]
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != row:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(row)])
			var condition: String = sticks.get(conditions[i], "?")
			if stage.conditions.get("stick") != condition:
				problems.append("stage %d's stick %s (doc %s)" % [i + 1, str(stage.conditions), conditions[i]])
	expect.call(problems.is_empty(), "shadow-clock: the Korean lines are hutton-lines.md 2 word for word (the fox, Puppy, the fox's answer, Dugi's two lines, the question and its answer, the riddle, the three stages with their sticks and wrong-condition lines) with its faces",
		"; ".join(problems))


## Puppy's win, miss and wrong-condition lines: short, no science words, no digits or symbols;
## English has every line too.
func check_result_lines() -> void:
	var problems := []
	var science := Story.science_words()
	var symbols := RegEx.create_from_string("[0-9%=+×/<>]")
	for stage: Dictionary in _definition().missions.stages:
		for key: String in ["win", "miss", "miss_conditions"]:
			var line := str(stage.get(key, ""))
			if line == "" or line.length() > LINE_MAX or symbols.search(line) != null or science.any(func(w: String) -> bool: return line.contains(w)):
				problems.append("%s '%s'" % [key, line])
	for line: String in [Story.keeper(_definition()), Story.clue(_definition()), Story.keeper_reply(_definition()), Story.map_clue(_definition())]:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	Locale.lang = "en"
	var en: Dictionary = Locale.overlay(JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/shadow-clock.json")), Locale.words("experiments/shadow-clock.json"))
	Locale.lang = "ko"
	if en.story.get("keeper", "") == "" or en.story.get("keeper_reply", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return str(s.get("miss", "")) == "" or str(s.get("say", "")) == "" or str(s.get("miss_conditions", "")) == "") \
			or en.kid.picks.stick.size() != 2 or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "shadow-clock: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

## The hours (from noon) of the sun's path, every STEP_HOURS, where `stick` gives `status`.
func _band(stick: float, status: String) -> Array:
	var model := ShadowClockModel.new()
	model.set_input("stick", stick)
	var limit := ShadowClockModel.path_hour_angle(model.input("latitude"), model.sun_declination()) / SunModel.DEG_PER_HOUR
	var out := []
	var h := -limit
	while h <= limit:
		model.set_input("rotation", SunModel.rotation_at(12.0 + h))
		if model.status() == status:
			out.append(h)
		h += STEP_HOURS
	return out


func check_model() -> void:
	var problems := []
	var short := ShadowClockModel.SHORT_STICK
	var long := ShadowClockModel.LONG_STICK
	var noon := _band(short, "noon")
	var bed := _band(short, "bed")
	var stone := _band(long, "stone")
	var width := func(band: Array) -> float: return band.back() - band.front() if not band.is_empty() else 0.0
	if noon.is_empty() or absf(noon.front() + ShadowClockModel.NOON_HOURS) > 0.02 or absf(noon.back() - ShadowClockModel.NOON_HOURS) > 0.02:
		problems.append("noon %s" % str([noon.front(), noon.back()] if not noon.is_empty() else []))
	for pair: Array in [["bed", bed, ShadowClockModel.BED_HOURS], ["stone", stone, ShadowClockModel.STONE_HOURS]]:
		var band: Array = pair[1]
		if band.is_empty() or width.call(band) < MIN_BAND_HOURS or float(pair[2]) < band.front() or float(pair[2]) > band.back():
			problems.append("%s band %s (want >= %.2f h round %.1f)" % [pair[0], str([band.front(), band.back()] if not band.is_empty() else []), MIN_BAND_HOURS, pair[2]])
	if not bed.is_empty() and bed.back() >= -ShadowClockModel.NOON_HOURS:
		problems.append("the bed is reached without the morning sun")
	if not stone.is_empty() and stone.front() <= ShadowClockModel.NOON_HOURS:
		problems.append("the stone is reached before the afternoon")
	if not _band(short, "stone").is_empty():
		problems.append("the short stick reaches the stone")
	if not _band(long, "bed").is_empty():
		problems.append("the long stick reaches the bed")
	var model := ShadowClockModel.new()
	if model.status() != "morning" or absf(model.hours_from_noon() - ShadowClockModel.START_HOURS) > 1e-9 or model.input("stick") != short:
		problems.append("the start: %s at %.2f h" % [model.status(), model.hours_from_noon()])
	# The shadow away from the sun, shorter as the sun climbs through the morning; the west sun's
	# shadow points east; the path's low end at PATH_MIN_ALTITUDE.
	var last := INF
	var h := -4.9
	while h <= 0.0:
		model.set_input("rotation", SunModel.rotation_at(12.0 + h))
		var away := absf(wrapf(model.shadow_azimuth() - model.sun_azimuth(), -180.0, 180.0))
		if absf(away - 180.0) > 1e-6 or model.shadow_length() >= last or model.shadow_tip().x >= 0.0:
			problems.append("at %.1f h: away %.1f, length %.2f after %.2f, tip %s" % [h, away, model.shadow_length(), last, str(model.shadow_tip())])
			break
		last = model.shadow_length()
		h += 0.1
	model.set_input("rotation", SunModel.rotation_at(15.0))
	if model.shadow_tip().x <= 0.0 or model.status() != "afternoon":
		problems.append("the afternoon sun's shadow %s (%s)" % [str(model.shadow_tip()), model.status()])
	model.set_input("rotation", model.rotation_on_path(-12.0))
	if absf(model.sun_altitude() - ShadowClockModel.PATH_MIN_ALTITUDE) > 1e-6:
		problems.append("the path's low end at %.2f deg" % model.sun_altitude())
	expect.call(problems.is_empty(),
		"shadow-clock model: noon within %.1f h; the bed (short stick, morning) and the stone (long stick, afternoon) each at least %.2f h of the sun's path wide; the short stick never reaches the stone nor the long the bed; the shadow away from the sun and shorter as it climbs; the start mid-morning" % [ShadowClockModel.NOON_HOURS, MIN_BAND_HOURS],
		"; ".join(problems) if not problems.is_empty() else "bed %.2f..%.2f h, stone %.2f..%.2f h" % [bed.front(), bed.back(), stone.front(), stone.back()])


# --- the judging ----------------------------------------------------------------------------------

func _at(lab: ShadowClockLab, hours: float, stick: String) -> void:
	lab.set_control(ShadowClockLab.STICK_CONTROL, stick)
	lab.model.set_input("rotation", SunModel.rotation_at(12.0 + hours))


func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var bed := ShadowClockModel.BED_HOURS
	var stone := ShadowClockModel.STONE_HOURS
	# [stage, hours from noon, stick, hit, missed (a line), the line]
	var cases := [
		[0, 0.0, "short", true, false, ""], [0, -0.9, "short", true, false, ""], [0, 0.9, "short", true, false, ""],
		[0, 1.3, "short", false, true, "해를 더 높이 올려 봐!"], [0, -2.5, "short", false, true, "해를 더 높이 올려 봐!"],
		[0, bed, "short", false, true, "해를 더 높이 올려 봐!"], [0, 0.0, "long", false, true, "짧은 막대를 골라 봐!"],
		[1, bed, "short", true, false, ""], [1, bed - 0.3, "short", true, false, ""], [1, bed + 0.3, "short", true, false, ""],
		[1, 3.0, "short", false, true, "해를 반대쪽 하늘로 옮겨 봐!"], [1, -bed, "short", false, true, "해를 반대쪽 하늘로 옮겨 봐!"],
		[1, -2.0, "short", false, false, ""], [1, 0.0, "short", false, false, ""],
		[1, 3.0, "long", false, true, "짧은 막대를 골라 봐!"],
		[2, stone, "long", true, false, ""], [2, stone - 0.3, "long", true, false, ""], [2, stone + 0.3, "long", true, false, ""],
		[2, 1.5, "long", false, true, "해 높이를 조금씩 바꿔 봐!"], [2, 4.5, "long", false, true, "해 높이를 조금씩 바꿔 봐!"],
		[2, stone, "short", false, true, "긴 막대를 골라 봐!"], [2, -3.0, "short", false, true, "긴 막대를 골라 봐!"],
	]
	for case: Array in cases:
		var stage := int(case[0])
		_at(lab, float(case[1]), str(case[2]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		# (a stamp is judged first: a run that earns it is never a miss, MissionRound.check_miss)
		var missed := stamps == stage and MissionRound.missed(definition, stage, status, lab.observations())
		var off := not MissionRound.conditions_met(definition.missions.stages[stage].get("conditions", {}), lab)
		var line: String = MissionRound.result_line(definition, stage, false, off)[0] if missed else ""
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]) or line != str(case[5]):
			problems.append("stage %d at %.1f h, %s stick (%s): stamps %d missed %s '%s'" % [stage + 1, case[1], case[2], status, stamps, missed, line])
	# The short stick never earns stage 3, wherever the sun is on its path.
	var h := -5.0
	while h <= 5.0:
		lab.model.set_input("rotation", (lab.model as ShadowClockModel).rotation_on_path(h))
		if MissionRound.judge(definition, 2, lab.status(), lab, lab.observations()) != 2:
			problems.append("the short stick earned stage 3 at %.2f h" % h)
			break
		h += STEP_HOURS
	_at(lab, 0.0, "short")
	lab.manipulation_started(ShadowClockLab.KNOB_ID)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the sun is held")
	lab.manipulation_cancelled(ShadowClockLab.KNOB_ID)
	var shown := lab.observations().keys()
	shown.sort()
	if shown != ["altitude", "shadow", "state"] or definition.observations.any(func(o: Dictionary) -> bool: return str(o.get("unit", "")) in ["h", "s", "min"]):
		problems.append("the observations %s" % str(shown))
	expect.call(problems.is_empty(), "shadow-clock judging: the noon sun, the bed with the morning sun and the stone with the long stick hit inside their bands; a west sun in stage 2 says \"해를 반대쪽 하늘로 옮겨 봐!\"; the wrong stick says which to pick and the short stick never earns stage 3; not judged while held; no clock time observed",
		"; ".join(problems.slice(0, 6)))
	lab.queue_free()
	await tree.process_frame


# --- the condition button -------------------------------------------------------------------------

func check_condition() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var model: ShadowClockModel = lab.model
	model.set_input("rotation", SunModel.rotation_at(12.0 + ShadowClockModel.STONE_HOURS))
	var before := model.input("rotation")
	var short_length := model.shadow_length()
	lab.set_control(ShadowClockLab.STICK_CONTROL, "long")
	if model.input("rotation") != before or absf(model.shadow_length() / short_length - ShadowClockModel.LONG_STICK / ShadowClockModel.SHORT_STICK) > 1e-9:
		problems.append("long stick: the sun moved or the shadow is %.2f of before" % (model.shadow_length() / short_length))
	if lab.control_value(ShadowClockLab.STICK_CONTROL) != "long" or not lab.props.stick.get_node("LongStick").visible or lab.props.stick.get_node("ShortStick").visible:
		problems.append("the long stick does not show")
	if lab.status() != "stone":
		problems.append("the long stick's tip is not on the stone (%s)" % lab.status())
	lab.run_action("reset")
	if model.input("stick") != ShadowClockModel.LONG_STICK or absf(model.hours_from_noon() - ShadowClockModel.START_HOURS) > 1e-9:
		problems.append("처음으로: stick %.1f, sun at %.2f h" % [model.input("stick"), model.hours_from_noon()])
	lab.set_control(ShadowClockLab.STICK_CONTROL, "short")
	if model.input("stick") != ShadowClockModel.SHORT_STICK or not lab.props.stick.get_node("ShortStick").visible:
		problems.append("back to the short stick")
	expect.call(problems.is_empty(), "shadow-clock condition: the long stick shows, its shadow 2.5 times the short one's under the same sun (on the stone in the afternoon); 처음으로 moves the sun back and keeps the stick",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[1]) != ID:
		problems.append("shadow-clock is not hutton's second spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	if hutton.playable():
		problems.append("hutton is playable before all its spots are labs")
	expect.call(problems.is_empty(), "shadow-clock: Hutton Island's second spot is an experiment (a lab on its map); the island is not playable until every spot is", "; ".join(problems))


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
	while round.phase() == MissionRound.Phase.CLUE and told.size() < 9:
		var line := round.clue_to_open()
		told.append([line.speaker, line.face])
		round.clue_opened()
		round.clue_read()
	var first_ok := told == [[Story.KEEPER, "worried"], ["puppy", "thinking"], [Story.KEEPER, "thinking"], ["dugi", "explain"], ["dugi", "explain"]] \
		and round.phase() == MissionRound.Phase.ASKING and store.clue_seen(ID)
	var again := MissionRound.new(definition, store)
	again.start()
	again.open(true)
	var later := []
	while again.phase() == MissionRound.Phase.CLUE and later.size() < 9:
		later.append(again.clue_to_open().speaker)
		again.clue_opened()
		again.clue_read()
	Story.enabled = was
	var tag := Locale.t("speaker." + Story.KEEPER)
	expect.call(first_ok and later == ["dugi", "dugi"] and tag == "여우친구",
		"shadow-clock opening: first visit the fox (worried), Puppy's clue, the fox's answer (her name tag 여우친구 from ui.json), Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s / %s" % [str(told), str(later), tag])


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
	var model: ShadowClockModel = lab.model
	var problems := []
	var start := model.hours_from_noon()
	# A press on the sun (a little off its middle) picks it.
	var at: Vector2 = screen.call(lab.props.sun.global_position + Vector3(0.25, -0.2, 0.0))
	m.handle_pointer("press", at)
	if m.mode != "drag" or m.active_id != ShadowClockLab.KNOB_ID or lab.holding != ShadowClockLab.KNOB_ID:
		problems.append("press on the sun: mode '%s' id '%s'" % [m.mode, m.active_id])
	# The finger moves to where the noon sun is drawn: the sun follows it there along its path.
	var noon_sun := ShadowClockLab.world_of(Vector3(0.0, cos(deg_to_rad(model.input("latitude"))), sin(deg_to_rad(model.input("latitude")))) * ShadowClockProps.SKY_RADIUS)
	var to: Vector2 = at + (screen.call(noon_sun) - screen.call(lab.props.sun.global_position))
	m.handle_pointer("move", at.lerp(to, 0.5))
	m.handle_pointer("move", to)
	await tree.process_frame
	if absf(model.hours_from_noon()) > 0.35 or lab.settled():
		problems.append("held at the noon sun: %.2f h (from %.2f)" % [model.hours_from_noon(), start])
	if m.get_children().any(func(n: Node) -> bool: return n is MeshInstance3D and n.name.begins_with("Footprint") and (n as MeshInstance3D).visible):
		problems.append("a footprint marker shows")
	for i in 10:
		await tree.physics_frame
	var held := model.hours_from_noon()
	m.handle_pointer("release", to)
	if absf(model.hours_from_noon() - held) > 1e-6 or lab.holding != "" or not lab.settled() or lab.status() != "noon" or not lab.placements().has(ShadowClockLab.KNOB_ID):
		problems.append("put down: %.2f h, holding '%s', %s" % [model.hours_from_noon(), lab.holding, lab.status()])
	if lab.props.sun.global_position.distance_to(noon_sun) > 0.3:
		problems.append("the sun is drawn at %s (the noon sun %s)" % [str(lab.props.sun.global_position), str(noon_sun)])
	# A drag far down to the right (under the western horizon) takes it to the path's west end.
	await tree.process_frame
	at = screen.call(lab.props.sun.global_position)
	m.handle_pointer("press", at)
	var low: Vector2 = screen.call(ShadowClockProps.STICK_AT + Vector3(ShadowClockProps.SKY_RADIUS * 1.2, -0.5, 1.0))
	m.handle_pointer("move", low)
	await tree.process_frame
	m.handle_pointer("release", low)
	if absf(model.sun_altitude() - ShadowClockModel.PATH_MIN_ALTITUDE) > 0.5 or model.hours_from_noon() <= 0.0:
		problems.append("dragged under the west: %.2f h, %.1f deg" % [model.hours_from_noon(), model.sun_altitude()])
	# A restored place: the same sun on a new lab.
	var saved: Dictionary = lab.placements()
	var other := _lab()
	tree.root.add_child(other)
	await tree.process_frame
	other.manipulation_placed(ShadowClockLab.KNOB_ID, saved[ShadowClockLab.KNOB_ID])
	if absf(other.model.hours_from_noon() - model.hours_from_noon()) > 1e-3:
		problems.append("restored at %.3f h (was %.3f)" % [other.model.hours_from_noon(), model.hours_from_noon()])
	other.queue_free()
	# A cancel puts it back.
	var before := model.input("rotation")
	at = screen.call(lab.props.sun.global_position)
	m.handle_pointer("press", at)
	m.handle_pointer("move", at + Vector2(-200.0, -120.0))
	await tree.process_frame
	m.handle_pointer("cancel", at + Vector2(-200.0, -120.0))
	if absf(model.input("rotation") - before) > 1e-3 or lab.holding != "":
		problems.append("cancel left it at %.2f h" % model.hours_from_noon())
	lab.run_action("reset")
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != ShadowClockLab.KNOB_ID or (guide.to as Vector3).x <= (guide.from as Vector3).x:
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "shadow-clock hand: a press on the sun picks it, a drag takes it along its path (to the noon sun; under the horizon to the path's low end), no footprint, a put-down keeps (and restores) it, a cancel puts it back; the hand guide drags the morning sun right (the way it goes)",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the view -------------------------------------------------------------------------------------

## On a phone and a tablet, with the dialogue box open (Dugi's question at the start), the things a
## child must follow are on the view and clear of the box, its bust, the chips and the picture
## buttons: the stick's foot and its ball, the bed, the stone and the shadow's tip at each goal (the
## noon sun with the short stick, the morning sun on the bed, the long stick's tip on the stone).
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
	var lab: ShadowClockLab = screen.experiment
	var view: View3D = screen.view
	var per_unit := Vector2(view.viewport.size) / view.size
	var box: DialogueBox = screen.dialogue
	var blocks: Array[Rect2] = []
	if box.active and box.visible:
		blocks.append_array(box.rects())
	for c: Control in [screen._title_bar, screen._key_row, screen._mission_pill, screen._mission_strip, screen._mission_text, screen._top_buttons, screen._action_row, screen._picks_row]:
		if c != null and c.is_visible_in_tree():
			blocks.append(c.get_rect())
	var model := ShadowClockModel.new()
	var points := {
		"stick foot": ShadowClockProps.STICK_AT,
		"long stick's ball": ShadowClockProps.STICK_AT + Vector3.UP * ShadowClockModel.LONG_STICK,
		"bed": lab.props.bed_at,
		"stone": lab.props.stone_at,
	}
	for goal: Array in [["noon tip", 0.0, ShadowClockModel.SHORT_STICK], ["bed tip", ShadowClockModel.BED_HOURS, ShadowClockModel.SHORT_STICK],
			["stone tip", ShadowClockModel.STONE_HOURS, ShadowClockModel.LONG_STICK]]:
		model.set_input("stick", float(goal[2]))
		model.set_input("rotation", SunModel.rotation_at(12.0 + float(goal[1])))
		points[goal[0]] = ShadowClockLab.world_of(model.shadow_tip())
	var view_rect := Rect2(Vector2.ZERO, view.size).grow(-8.0)
	var problems := []
	for name: String in points:
		var at: Vector2 = view.rig.unproject_position(points[name]) / per_unit
		var spot := Rect2(at - Vector2(12.0, 12.0), Vector2(24.0, 24.0))
		if not view_rect.encloses(spot):
			problems.append("%s off the view at %s" % [name, str(at)])
		for r in blocks:
			if r.intersects(spot):
				problems.append("%s at %s under %s" % [name, str(at), str(r)])
	# The bed and the stone are big on the screen (their radius at least this many units).
	for pair: Array in [["bed", lab.props.bed_at, ShadowClockProps.BED_RADIUS], ["stone", lab.props.stone_at, ShadowClockProps.STONE_RADIUS]]:
		var c: Vector2 = view.rig.unproject_position(pair[1]) / per_unit
		var e: Vector2 = view.rig.unproject_position(pair[1] + Vector3.RIGHT * float(pair[2])) / per_unit
		if c.distance_to(e) < 30.0:
			problems.append("the %s is small (%.0f units)" % [pair[0], c.distance_to(e)])
	var name := "phone" if size == PHONE else "tablet"
	expect.call(box.active and problems.is_empty(), "shadow-clock view (%s): the stick, the bed, the stone and the shadow's tip at each goal are on the view, big, clear of the dialogue box, the chips and the stick buttons" % name,
		"box %s; %s" % [box.active, "; ".join(problems.slice(0, 6))])
	host.queue_free()
	for i in 3:
		await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: ShadowClockGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or Vector2(start.x, start.z).distance_to(Vector2(lab.props.stone_at.x, lab.props.stone_at.z)) > ShadowClockProps.STONE_RADIUS:
		problems.append("not in the cage on the stone at the start")
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
	var lid: Node3D = game.get_node("LidHinge")
	if game.piece_state != "out" or absf(rest.y - game.piece_size) > 0.12 or rest.distance_to(start) < 1.0 or absf(lid.rotation.x) < 1.0:
		problems.append("after the last stamp: %s at %s, lid %.2f" % [game.piece_state, str(rest), lid.rotation.x])
	if not game.take_piece() is Vector3 or game.piece.visible:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as ShadowClockGame).take_piece() != null:
		problems.append("a piece in a finished spot")
	expect.call(problems.is_empty(), "shadow-clock piece: in the cage on the far stone until the last stamp, then the lid opens and it jumps out onto the yard for the cat; none in a finished spot",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
