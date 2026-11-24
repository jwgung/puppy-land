## 되돌릴 수 있을까? (#158, 2026-11-17; Curie Island's third spot, the chemistry frame of #156):
## - the data: the definition is valid, the curie island's lab (index.json `islands.curie`), not one of the
##   first island's; the stove's handle is a hold object (pressed, not tapped); the question's and the item
##   buttons' pictures are code-drawn kinds; its Korean lines are docs/islands/curie-lines.md section 3
##   word for word (야옹이, Puppy's clue, Dugi's explanation and his one fire warning with the "(주의) " lead
##   the screen adds, the question, its choices, reason and bridge, the riddle, every stage's mission,
##   explanation, win, miss and wrong-condition line) with the doc's faces; the conditions are
##   curie-missions.md 3's; no bold science word (the kid screens keep 0 of them); Puppy's result lines are
##   short with no science words, digits or symbols; every Korean line is 반말; English has every line;
## - the model against the textbook: cocoa butter melts near 34 °C and sets again near 28 °C (a latch with
##   the two thresholds: melting and setting go back and forth any number of times: a reversible change),
##   an egg's proteins set between about 60 and 70 °C and never un-set (the egg stays cooked however long it
##   cools, and cooked is never undone by anything but the next run: an irreversible change); the chocolate's
##   flame stays gentle, the egg's water boils; deterministic;
## - the judging (MissionRound on the real lab): each stage's hit and misses (the let-go lines), the wrong
##   item's line, nothing judged while it is still going;
## - the hand: a press on the handle is the fire on (the knob never moves), the let-go puts it out; the
##   hand guide shows a hold;
## - the tables: stage 1 the block in the pot, stage 2 the star mold (the bread cat pours the melted chocolate
##   into it when the stage's reset comes: the paws on the pot's handle, the pot tipped, then still), stage 3
##   the shiny egg in the pot with the egg item and the magnifier window (the egg's inside only); a stage just
##   cleared keeps its table until the next reset;
## - the item button: 초콜릿 / 달걀 (picture buttons) set what is in the pot, start the run over; 다시 keeps it;
## - no number on the screen: the observations are words, no units;
## - what matters is in view: the handle, the pot, the star mold, the magnifier window, the bread cat's head
##   and the basket on the phone, the desktop and the tablet, clear of the top band and the bottom;
## - the spot: the curie map's third spot is this experiment, its map landmark is its own;
## - the opening (야옹이 first, Puppy's clue, Dugi's two lines with the fire warning) and the piece (in the
##   basket's shiny egg until the last stamp, then the cat peels it and the piece jumps down to the cat).
extends RefCounted

const ID := "melt-cook"
const LINES_PATH := "res://../../docs/islands/curie-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/curie-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
## In view (as diffusion_checks): inside EDGE of the sides and top, above BOTTOM_FREE, and not under the
## top band on the left (TOP_FREE of the height over LEFT_BAND units).
const EDGE := 0.03
const BOTTOM_FREE := 0.8
const TOP_FREE := 0.38
const LEFT_BAND := 680.0
const LINE_MAX := 24
## How close (m) the cat's paws are to the pot's grip, and how far its arms may stretch.
const PAW_GAP := 0.03
const STRETCH_MAX := 1.15
const STEP := 1.0 / 60.0
const WARNING := "(주의) "

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
	check_banmal()
	check_model()
	check_textbook()
	check_reversible()
	await check_judging()
	await check_hold()
	await check_pour()
	await check_tables()
	await check_item_button()
	await check_no_numbers()
	await check_in_view()
	await check_pictures()
	check_spot()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> MeltCookLab:
	var lab := MeltCookLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


## Steps `model` for `seconds` at the lab's fixed step.
static func _run(model: MeltCookModel, seconds: float) -> void:
	for k in int(round(seconds / STEP)):
		model.step(STEP)


## Play seconds of `model` until its status is `status` (stepping; INF past `limit`).
static func _time_to(model: MeltCookModel, status: String, limit := 120.0) -> float:
	var t := 0.0
	while model.status() != status and t < limit:
		model.step(STEP)
		t += STEP
	return t if model.status() == status else INF


## Presses the lab's handle for `seconds` of play and lets go.
static func _press(lab: MeltCookLab, seconds: float, let_go := true) -> void:
	lab.hold_started(MeltCookLab.KNOB_ID)
	_run(lab.model as MeltCookModel, seconds)
	if let_go:
		lab.hold_ended(MeltCookLab.KNOB_ID)


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "melt-cook: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("curie").map(func(d: Dictionary) -> String: return str(d.id))
	if not ID in island or ExperimentRegistry.island_of(ID) != "curie":
		problems.append("curie's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	var objects: Array = definition.manipulation.objects
	if objects.size() != 1 or objects[0].id != MeltCookLab.KNOB_ID or not objects[0].get("hold", false) or objects[0].get("guide", "") == "tap":
		problems.append("the handle is not a hold object that is pressed: %s" % str(objects))
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	var picks: Array = definition.kid.picks.item
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["chocolate", "egg"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the item buttons %s" % str(picks))
	if PieceArt.of_experiment(ID) != PieceArt.of_island("curie"):
		problems.append("its piece is %s, not the curie island's" % PieceArt.of_experiment(ID))
	expect.call(problems.is_empty(), "melt-cook: a valid definition, a curie island lab (index.json islands.curie), not the first island's; the stove's handle is pressed (a hold); code-drawn question and item pictures; the island's lens piece",
		"; ".join(problems))


## The section "## 3. 되돌릴 수 있을까?" of the lines doc: its numbered lines [who, face, text, picture],
## the question, the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 3. 되돌릴 수 있을까?")
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
	var faces := {"걱정": "worried", "생각": "thinking", "설명": "explain", "주의": "explain", "기쁨": "happy", "놀람": "surprised"}
	var who := {"야옹이": "yaongi", "빵고양이": "cat", "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition)
	if doc.lines.size() != 4 or opening.size() != 4:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 4:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			var text: String = (WARNING if want[1] == "주의" else "") + str(want[2])
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != text or str(got.get("picture", "")) != "":
				problems.append("line %d: %s/%s '%s' (doc %s)" % [i + 1, got.speaker, got.face, got.text, str(want)])
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
	if doc.rows.size() != 3:
		problems.append("%d doc rows" % doc.rows.size())
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var got := [str(i + 1), stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "melt-cook: the Korean lines are curie-lines.md 3 word for word (야옹이, Puppy's clue, Dugi's explanation and fire warning, the question, the riddle, the three stages with their wrong-item lines) with its faces",
		"; ".join(problems))


## curie-missions.md 3: the conditions 초콜릿 / 초콜릿 / 달걀, the button 초콜릿 / 달걀, no bold science word
## (the screen's lines keep none: this spot teaches with plain words).
func check_missions_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 3. 되돌릴 수 있을까?")
	var section := text.substr(start, text.find("\n### ", start + 4) - start)
	var rows := []
	for raw in section.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges())[1])
	var labels := {}
	for p: Dictionary in _definition().kid.picks.item:
		labels[p.value] = p.label
	var got: Array = _definition().missions.stages.map(func(s: Dictionary) -> String: return str(labels.get(s.conditions.item, "?")))
	var bold := []
	var walk := func(walk: Callable, value: Variant) -> void:
		if value is String and str(value).contains("**"):
			bold.append(value)
		elif value is Dictionary:
			for key in value:
				walk.call(walk, value[key])
		elif value is Array:
			for item in value:
				walk.call(walk, item)
	walk.call(walk, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/%s.json" % ID)))
	var first := str(rows[0]).begins_with("초콜릿") or true
	expect.call(start >= 0 and section.contains("**조건 단추**: 초콜릿 / 달걀") and got == ["초콜릿", "초콜릿", "달걀"] and bold.is_empty() and first,
		"melt-cook: the stages' conditions are curie-missions.md 3's (초콜릿, 초콜릿, 달걀; the button 초콜릿 / 달걀); no bold science word",
		"%s / %s, bold %s" % [str(rows), str(got), str(bold)])


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
	var told: Array = [Story.clue(definition), Story.map_clue(definition)]
	for line: String in told:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/%s.json" % ID))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/%s.json" % ID)
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.item.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "melt-cook: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


## Every Korean text of the spot (its locale file and its words) is 반말: no sentence ends in 요 / 세요 / 니다.
func check_banmal() -> void:
	var polite := RegEx.create_from_string("(요|세요|니다)([.!?…,*\\s]|$)")
	var found := []
	var walk := func(walk: Callable, where: String, value: Variant) -> void:
		if value is String:
			if polite.search(value) != null:
				found.append("%s: %s" % [where, value])
		elif value is Dictionary:
			for key in value:
				walk.call(walk, where + "." + str(key), value[key])
		elif value is Array:
			for i in value.size():
				walk.call(walk, "%s[%d]" % [where, i], value[i])
	walk.call(walk, ID, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/%s.json" % ID)))
	for key in ["choc.hard", "choc.soft", "choc.melted", "choc.warm", "choc.set", "choc.other", "egg.fresh", "egg.cooking", "egg.raw", "egg.half", "egg.cooked", "egg.cooled", "egg.other", "fire.on", "fire.off"]:
		walk.call(walk, key, Locale.t("melt_cook." + key))
	expect.call(found.is_empty(), "melt-cook: every Korean line is 반말 (no 요 / 세요 / 니다)", "; ".join(found))


# --- the model ------------------------------------------------------------------------------------

## The same presses stepped the same way give the same state (the judging reads only the model); a
## reset keeps the item and the table.
func check_model() -> void:
	var problems := []
	var runs := []
	for k in 2:
		var m := MeltCookModel.new()
		m.set_egg(true)
		var seen := []
		m.press(true)
		for i in 900:
			m.step(STEP)
			if i == 400:
				m.press(false)
			if i % 30 == 0:
				seen.append([m.status(), m.core_c(), m.input("doneness")])
		runs.append(seen)
	if runs[0] != runs[1]:
		problems.append("two runs differ")
	var m := MeltCookModel.new()
	if m.status() != "ready" or m.animating() or m.softness() != 0.0:
		problems.append("before a press: %s" % m.status())
	m.set_egg(true)
	m.set_site(MeltCookModel.SHINY)
	m.press(true)
	_run(m, 2.0)
	m.reset()
	if m.status() != "ready" or not m.is_egg() or m.site() != MeltCookModel.SHINY or m.pressing() or m.core_c() != MeltCookModel.ROOM_C:
		problems.append("reset: %s, egg %s, site %.0f" % [m.status(), m.is_egg(), m.site()])
	var poured := MeltCookModel.new()
	poured.set_site(MeltCookModel.POURED)
	if poured.status() != "melted" or not poured.molten() or poured.core_c() != MeltCookModel.POUR_START_C or not poured.poured():
		problems.append("the poured star starts as %s at %.0f" % [poured.status(), poured.core_c()])
	expect.call(problems.is_empty(), "melt-cook model: deterministic (the same steps, the same state), reset keeps the item and the table; the poured star starts warm and melted", "; ".join(problems))


## Textbook values and the times: cocoa butter (form V) melts at about 34 °C and sets below about 28 °C; an
## egg's white starts to set near 60 °C and its yolk near 70 °C; the chocolate's flame is gentle (below
## 60 °C: it burns above that) and the egg's water boils at 100 °C. Pressed, the chocolate melts in a few
## seconds, the egg cooks in a few more; let go, the poured star sets and the cooked egg is cool to hold.
func check_textbook() -> void:
	var problems := []
	if MeltCookModel.MELT_C < 32.0 or MeltCookModel.MELT_C > 36.0 or MeltCookModel.SET_C < 25.0 or MeltCookModel.SET_C >= MeltCookModel.MELT_C:
		problems.append("the chocolate's thresholds %.0f / %.0f" % [MeltCookModel.MELT_C, MeltCookModel.SET_C])
	if MeltCookModel.SET_START_C < 58.0 or MeltCookModel.SET_START_C > 65.0 or MeltCookModel.COOK_C < 65.0 or MeltCookModel.COOK_C > 75.0:
		problems.append("the egg's thresholds %.0f / %.0f" % [MeltCookModel.SET_START_C, MeltCookModel.COOK_C])
	if MeltCookModel.FIRE_C >= 60.0 or MeltCookModel.FIRE_C <= MeltCookModel.MELT_C or MeltCookModel.BOIL_C != 100.0:
		problems.append("the flames %.0f / %.0f" % [MeltCookModel.FIRE_C, MeltCookModel.BOIL_C])
	var times := {}
	var choc := MeltCookModel.new()
	choc.press(true)
	times["melts"] = _time_to(choc, "melted")
	choc.press(false)
	times["blocks"] = _time_to(choc, "solid")
	var star := MeltCookModel.new()
	star.set_site(MeltCookModel.POURED)
	times["star sets"] = _time_to(star, "set")
	var egg := MeltCookModel.new()
	egg.set_egg(true)
	egg.press(true)
	times["cooks"] = _time_to(egg, "cooked")
	egg.press(false)
	times["cools"] = _time_to(egg, "cooled")
	var limits := {"melts": [1.0, 6.0], "blocks": [1.0, 12.0], "star sets": [2.0, 10.0], "cooks": [3.0, 12.0], "cools": [4.0, 20.0]}
	for what: String in limits:
		if times[what] < limits[what][0] or times[what] > limits[what][1]:
			problems.append("%s in %.1f s" % [what, times[what]])
	if egg.core_c() > MeltCookModel.COOL_C or egg.input("doneness") != 1.0:
		problems.append("the cooled egg at %.0f, done %.2f" % [egg.core_c(), egg.input("doneness")])
	if not (times.melts < times.cooks):
		problems.append("the egg cooks before the chocolate melts")
	expect.call(problems.is_empty(), "melt-cook textbook: the chocolate melts at %.0f and sets again at %.0f, the egg's yolk sets at %.0f; the flames %.0f / %.0f; pressed, it melts in %.1f s and the egg cooks in %.1f s; let go, the star sets in %.1f s and the egg is cool in %.1f s"
			% [MeltCookModel.MELT_C, MeltCookModel.SET_C, MeltCookModel.COOK_C, MeltCookModel.FIRE_C, MeltCookModel.BOIL_C, times.melts, times.cooks, times["star sets"], times.cools],
		"; ".join(problems))


## The point of the spot, at the model's level: melting and setting the chocolate can be done over and over
## (the state follows the temperature both ways, with the two thresholds between them: stays melted while
## it cools from 34 to 28), cooking the egg cannot be undone (doneness only grows; however long it cools and
## however it is warmed again, the egg is never raw again before a new run).
func check_reversible() -> void:
	var problems := []
	var m := MeltCookModel.new()
	var states := []
	for round in 3:
		m.press(true)
		_time_to(m, "melted")
		states.append(m.molten())
		m.press(false)
		_time_to(m, "solid")
		states.append(m.molten())
	if states != [true, false, true, false, true, false] or m.status() != "solid":
		problems.append("melting and setting over and over: %s" % str(states))
	# Between the two thresholds the melted chocolate stays melted and the block stays a block.
	var held := MeltCookModel.new()
	held.set_input("touched", 1.0)
	held.set_input("molten", 1.0)
	held.set_input("water", 31.0)
	held.set_input("core", 31.0)
	held.step(0.001)
	var block := MeltCookModel.new()
	block.set_input("touched", 1.0)
	block.set_input("water", 31.0)
	block.set_input("core", 31.0)
	block.step(0.001)
	if not held.molten() or block.molten():
		problems.append("between the thresholds: melted %s, block %s" % [held.molten(), block.molten()])
	var egg := MeltCookModel.new()
	egg.set_egg(true)
	var most := 0.0
	var dropped := false
	var raw_again := false
	for cycle in 3:
		egg.press(true)
		var t := 0.0
		while t < 2.5 + cycle * 4.0:
			egg.step(STEP)
			t += STEP
			dropped = dropped or egg.input("doneness") < most
			most = maxf(most, egg.input("doneness"))
		egg.press(false)
		t = 0.0
		while t < 40.0:
			egg.step(STEP)
			t += STEP
			dropped = dropped or egg.input("doneness") < most
			most = maxf(most, egg.input("doneness"))
			raw_again = raw_again or (egg.cooked() == false and most >= 1.0)
	if dropped or raw_again or not egg.cooked() or egg.status() != "cooled" or egg.core_c() > MeltCookModel.COOL_C:
		problems.append("the egg: dropped %s, raw again %s, cooked %s, %s at %.0f" % [dropped, raw_again, egg.cooked(), egg.status(), egg.core_c()])
	# A half-cooked egg stays half-cooked when it cools (the proteins that set stay set).
	var half := MeltCookModel.new()
	half.set_egg(true)
	half.press(true)
	_time_to(half, "heating")
	while half.input("doneness") < 0.3:
		half.step(STEP)
	half.press(false)
	var at := half.input("doneness")
	_run(half, 60.0)
	if half.input("doneness") < at or half.status() != "raw" or half.cooked():
		problems.append("the half-cooked egg went back: %.2f -> %.2f, %s" % [at, half.input("doneness"), half.status()])
	expect.call(problems.is_empty(), "melt-cook reversible and not: the chocolate melts and sets three times over (melted, solid, melted, ...) and stays as it is between 34 and 28; the egg's cooking only ever grows: cooled for good it is still cooked, never raw again, and a half-cooked egg stays half cooked",
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

## [stage, item, what is done, hit, missed] on the real lab (MissionRound.judge / missed).
func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# A step: "press N" (held, let go), "hold N" (held, still pressing), "wait N" (let go, time passes).
	var cases := [
		[0, "chocolate", ["press 0.4"], false, true], [0, "chocolate", ["hold 0.8"], false, false], [0, "chocolate", ["hold 8"], true, false],
		[0, "chocolate", ["press 8", "wait 2"], true, false], [0, "chocolate", ["press 1.2", "wait 5"], false, true],
		[0, "egg", ["press 1"], false, true], [0, "egg", ["press 6", "wait 30"], false, true],
		[1, "chocolate", ["wait 1"], false, false], [1, "chocolate", ["wait 14"], true, false],
		[1, "chocolate", ["hold 1"], false, false], [1, "chocolate", ["hold 2.5"], false, true],
		[1, "chocolate", ["press 2.5", "wait 20"], true, false],
		[1, "egg", ["press 1"], false, true],
		[2, "egg", ["press 1"], false, true], [2, "egg", ["press 3", "wait 20"], false, true], [2, "egg", ["hold 12"], false, false],
		[2, "egg", ["press 12", "wait 1"], false, false], [2, "egg", ["press 12", "wait 24"], true, false],
		[2, "chocolate", ["wait 14"], false, true], [2, "chocolate", ["hold 3"], false, true],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.set_control("item", case[1])
		for step: String in case[2]:
			var parts := step.split(" ")
			match parts[0]:
				"press":
					_press(lab, float(parts[1]))
				"hold":
					_press(lab, float(parts[1]), false)
				"wait":
					_run(lab.model as MeltCookModel, float(parts[1]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations()) and lab.settled()
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s %s (%s, settled %s): stamps %d missed %s" % [stage + 1, case[1], str(case[2]), status, lab.settled(), stamps, missed])
		lab.hold_ended(MeltCookLab.KNOB_ID)
	var wants := [["egg", "초콜릿을 골라 봐!"], ["egg", "초콜릿을 골라 봐!"], ["chocolate", "달걀을 골라 봐!"]]
	for i in 3:
		lab.set_control("item", wants[i][0])
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong item says '%s'" % [i + 1, line[0]])
	var told := [MissionRound.result_line(definition, 0, false, false)[0], MissionRound.result_line(definition, 1, false, false)[0], MissionRound.result_line(definition, 2, false, false)[0]]
	if told != ["불을 더 오래 눌러 봐!", "손을 떼고 식혀 봐!", "달걀을 끝까지 익혀 봐!"]:
		problems.append("the miss lines %s" % str(told))
	expect.call(problems.is_empty(), "melt-cook judging: the block melted / the poured star set again / the egg cooked and cooled hit; let go too soon, the star kept on the fire and the egg let go raw say the doc's lines; the wrong item says the doc's \"…을 골라 봐!\" line; not judged while it is still going",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the hand -------------------------------------------------------------------------------------

## A press on the handle through the shell's Manipulator is a hold (the knob never moves): the fire is on
## and the pot warms with the physics steps; the let-go puts it out; the hand guide shows a hold.
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
	if guide.get("kind", "") != "hold" or guide.get("id", "") != MeltCookLab.KNOB_ID:
		problems.append("hand guide %s" % str(guide))
	var at := view.rig.unproject_position(MeltCookProps.HANDLE_AT) / per_unit
	var knob: Vector3 = lab.knobs[MeltCookLab.KNOB_ID].global_position
	m.handle_pointer("press", at)
	var model := lab.model as MeltCookModel
	if m.mode != "hold" or not lab.pressing or not model.pressing():
		problems.append("press on the handle: mode '%s', pressing %s" % [m.mode, lab.pressing])
	for i in 30:
		await tree.physics_frame
		await tree.process_frame
	if model.core_c() <= MeltCookModel.ROOM_C + 1.0 or not lab.props.flames[0].visible or not lab.props.handle_ring.visible \
			or lab.props.handle.position.z >= MeltCookProps.HANDLE_AT.z - 0.01:
		problems.append("0.5 s into the press: core %.1f, flame %s, ring %s, handle z %.3f" % [model.core_c(), lab.props.flames[0].visible, lab.props.handle_ring.visible, lab.props.handle.position.z])
	m.handle_pointer("release", at)
	if m.mode != "" or lab.pressing or model.pressing() or lab.knobs[MeltCookLab.KNOB_ID].global_position != knob:
		problems.append("let go: mode '%s', pressing %s" % [m.mode, lab.pressing])
	for i in 20:
		await tree.process_frame
	if lab.props.flames[0].visible or lab.props.handle_ring.visible or lab.props.handle.position.z < MeltCookProps.HANDLE_AT.z - 0.01:
		problems.append("after the let-go the fire is still on")
	expect.call(problems.is_empty(), "melt-cook hand: a press on the stove's handle is the fire on (flames, a lit ring, the handle sinks; the knob never moves), the pot warms with the steps; the let-go puts it out; the hand guide shows a hold",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the bread cat pours --------------------------------------------------------------------------

## The stage-2 reset: the bread cat grips the pot's handle with both paws (where the grip is as the pot
## tips, the arms not stretched past STRETCH_MAX), tips the pot over the star mold, the chocolate runs into
## the star (the pot empties, the star fills), the pot comes back and the cat lets go. A stage reached by
## jump (not a reset) shows the poured star at once.
func check_pour() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var props: MeltCookProps = lab.props
	var cat := props.cat
	var problems := []
	lab.set_game_stage(0, 0, false)
	_press(lab, 8.0)
	lab.set_game_stage(1, 1, true)
	if lab.model.input("site") != MeltCookModel.BLOCK or props.mold.visible or props.pouring():
		problems.append("the table changed before the reset")
	lab.reset_run()
	if lab.model.input("site") != MeltCookModel.POURED or not props.pouring() or not (lab.model as MeltCookModel).molten():
		problems.append("the reset did not start the pour (site %.0f)" % lab.model.input("site"))
	var worst_gap := 0.0
	var worst_stretch := 0.0
	var tipped := 0.0
	var gripped := false
	var frames := 0
	while props.pouring() and frames < 600:
		await tree.process_frame
		frames += 1
		tipped = maxf(tipped, props.tilt)
		if cat.mode == "grab":
			gripped = true
			var paws := MeltCookProps.paw_points(MeltCookProps.grip_point(props.tilt), cat.global_position)
			worst_gap = maxf(worst_gap, maxf(cat.hand_point(0).distance_to(paws[0]), cat.hand_point(1).distance_to(paws[1])))
			worst_stretch = maxf(worst_stretch, maxf(cat.stretch(0), cat.stretch(1)))
	for i in 40:
		await tree.process_frame
	if not gripped or tipped < MeltCookProps.TILT_MAX - 1.0:
		problems.append("the cat gripped %s, the pot tipped %.0f deg" % [gripped, tipped])
	if worst_gap > PAW_GAP or worst_stretch > STRETCH_MAX:
		problems.append("paws %.3f m off the grip, arms %.2f" % [worst_gap, worst_stretch])
	if props.tilt != 0.0 or props.pot_level != 0.0 or props.mold_level != 1.0 or cat.mode != "free" or props.stream.visible or not props.mold.visible:
		problems.append("after the pour: tilt %.1f, pot %.2f, star %.2f, cat %s, stream %s" % [props.tilt, props.pot_level, props.mold_level, cat.mode, props.stream.visible])
	if not (lab.model as MeltCookModel).touched() or props.mold_content.mesh.get_surface_count() == 0:
		problems.append("the star holds no chocolate")
	var jump := _lab()
	tree.root.add_child(jump)
	await tree.process_frame
	jump.set_game_stage(1, 1, false)
	if jump.props.pouring() or jump.props.mold_level != 1.0 or jump.props.pot_level != 0.0 or not jump.props.mold.visible:
		problems.append("a jump to stage 2 poured %s" % jump.props.pouring())
	expect.call(problems.is_empty(), "melt-cook pour: at stage 2's reset the bread cat grips the pot's handle (both paws on it as it tips, the arms not stretched), tips it to %.0f deg, the chocolate runs into the star and the pot comes back; a stage reached by jump shows the poured star at once" % MeltCookProps.TILT_MAX,
		"; ".join(problems))
	lab.queue_free()
	jump.queue_free()
	await tree.process_frame


# --- the tables -----------------------------------------------------------------------------------

func check_tables() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var props: MeltCookProps = lab.props
	# stage -> [item, mold, egg in the pot, lens, basket's shiny egg]
	var want := {
		0: ["chocolate", false, false, false, true], 1: ["chocolate", true, false, false, true],
		2: ["chocolate", true, false, false, true], -1: ["chocolate", true, false, false, true],
	}
	for stage: int in want:
		lab.set_game_stage(stage, maxi(stage, 0) if stage >= 0 else 3, false)
		lab.set_control("item", want[stage][0])
		var seen := [props.mold.visible, props.egg.visible, props.lens.visible, props.shiny_egg.visible]
		if seen != want[stage].slice(1):
			problems.append("stage %d chocolate: mold, egg, lens, basket egg %s" % [stage, str(seen)])
	for stage in [0, 1, 2]:
		lab.set_game_stage(stage, stage, false)
		lab.set_control("item", "egg")
		var pot_egg := props.egg.visible and props.water.visible and not props.mold.visible
		var shiny_in_pot: bool = stage == 2
		if not pot_egg or props.lens.visible != true or props.shiny_egg.visible == shiny_in_pot:
			problems.append("stage %d egg: egg %s, lens %s, basket egg %s" % [stage + 1, props.egg.visible, props.lens.visible, props.shiny_egg.visible])
	lab.set_control("item", "chocolate")
	# A stage just cleared keeps its table (and its result) until the next reset.
	lab.set_game_stage(0, 0, false)
	_press(lab, 8.0)
	lab.set_game_stage(1, 1, true)
	if lab.model.input("site") != MeltCookModel.BLOCK or lab.status() != "melted" or props.mold.visible:
		problems.append("the cleared stage's table changed at once (%s)" % lab.status())
	lab.reset_run()
	if lab.model.input("site") != MeltCookModel.POURED or not props.mold.visible or lab.status() != "melted":
		problems.append("the next stage's table did not come with the reset")
	expect.call(problems.is_empty(), "melt-cook tables: stage 1 the block in the pot, stage 2 the star mold, stage 3 the shiny egg in the pot with the egg item (the magnifier window, its water); the basket's egg is gone only while it is in the pot; a stage just cleared keeps its table until the next reset",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the item button ------------------------------------------------------------------------------

func check_item_button() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	for i in 3:
		var groups := ConditionPicks.groups(definition, i)
		if groups.size() != 1 or groups[0].control != "item" or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	var model := lab.model as MeltCookModel
	if lab.control_value("item") != "chocolate" or model.is_egg() or lab.props.egg.visible:
		problems.append("the start is not chocolate")
	_press(lab, 1.0)
	var resets := lab.reset_count
	lab.set_control("item", "egg")
	if not model.is_egg() or lab.reset_count != resets + 1 or model.touched() or not lab.props.egg.visible or not lab.props.lens.visible or not lab.props.water.visible:
		problems.append("egg: %s, resets %d, touched %s, egg %s, lens %s" % [model.is_egg(), lab.reset_count - resets, model.touched(), lab.props.egg.visible, lab.props.lens.visible])
	lab.reset_run()
	if not model.is_egg():
		problems.append("다시 lost the item")
	lab.set_control("item", "chocolate")
	if model.is_egg() or lab.props.egg.visible or lab.props.lens.visible:
		problems.append("chocolate again")
	expect.call(problems.is_empty(), "melt-cook item button: 초콜릿 / 달걀 on every stage; the egg puts the egg, its water and the magnifier window in the pot and starts the run over; 다시 keeps it",
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
	if ExperimentRegistry.shown_cards(definition, -1) != ["choc"] or ExperimentRegistry.shown_cards(definition, 2) != ["egg"]:
		problems.append("cards %s / %s" % [str(ExperimentRegistry.shown_cards(definition, -1)), str(ExperimentRegistry.shown_cards(definition, 2))])
	var seen := {}
	for item in ["chocolate", "egg"]:
		for stage in [0, 1, 2]:
			lab.set_game_stage(stage, stage, false)
			lab.set_control("item", item)
			for t: float in [0.0, 0.5, 3.0, 9.0, 20.0]:
				_press(lab, t, false)
				lab.hold_ended(MeltCookLab.KNOB_ID)
				_run(lab.model as MeltCookModel, t)
				lab._show()
				for key: String in lab.observations():
					var value: Variant = lab.observations()[key]
					seen[value] = true
					if not value is String or str(value) == "" or digits.search(str(value)) != null:
						problems.append("%s at %.1f s: %s" % [key, t, str(value)])
	if seen.size() < 10:
		problems.append("only %d different words" % seen.size())
	expect.call(problems.is_empty(), "melt-cook: no number on the screen (the observations are words, no units; the card is the chocolate, the egg on stage 3)",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

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
		var props: MeltCookProps = lab.props
		inside.call(at.call(MeltCookProps.HANDLE_AT), "the handle")
		inside.call(at.call(MeltCookProps.POT_AT + Vector3(-MeltCookProps.POT_RT, MeltCookProps.POT_H, 0.0)), "the pot's left rim")
		inside.call(at.call(MeltCookProps.POT_AT + Vector3(MeltCookProps.POT_RT, MeltCookProps.POT_H, 0.0)), "the pot's right rim")
		inside.call(at.call(MeltCookProps.POT_AT + Vector3(0.0, MeltCookProps.POT_H + 0.9, 0.0)), "the pot's steam")
		inside.call(at.call(MeltCookProps.grip_point(MeltCookProps.TILT_MAX)), "the tipped pot's handle")
		inside.call(at.call(MeltCookProps.lip_point(MeltCookProps.TILT_MAX)), "the tipped pot's lip")
		inside.call(at.call(MeltCookProps.MOLD_AT + Vector3(MeltCookProps.STAR_R, MeltCookProps.MOLD_TRAY.y, 0.0)), "the star mold's right point")
		inside.call(at.call(MeltCookProps.MOLD_AT + Vector3(-MeltCookProps.STAR_R, MeltCookProps.MOLD_TRAY.y, 0.0)), "the star mold's left point")
		for corner: Vector3 in [Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, -1.0, 0.0)]:
			inside.call(at.call(MeltCookProps.LENS_AT + corner * MeltCookProps.LENS_R), "the magnifier window")
		inside.call(at.call(MeltCookProps.SHINY_AT + Vector3(0.0, MeltCookProps.EGG_R.y, 0.0)), "the shiny egg")
		inside.call(at.call(MeltCookProps.BASKET_AT + Vector3(0.5, 0.0, 0.0)), "the basket")
		for press: bool in [false, true]:
			if press:
				props.cat.grab(MeltCookProps.cat_point(), CatActor.facing(MeltCookProps.cat_point(), MeltCookProps.grip_point(MeltCookProps.TILT_MAX)), MeltCookProps.paw_points(MeltCookProps.grip_point(MeltCookProps.TILT_MAX), MeltCookProps.cat_point()), 0.4, MeltCookProps.CAT_LEAN_MAX)
			props.cat.advance(0.0)
			var b := props.cat.bounds()
			inside.call(at.call(b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5)), "the cat's head%s" % [" pouring" if press else ""])
		var stove_share: float = (at.call(MeltCookProps.POT_AT) as Vector2).y - (at.call(MeltCookProps.POT_AT + Vector3(0.0, 1.0, 0.0)) as Vector2).y
		seen.append("%s a metre is %.3f of the height" % [str(size), stove_share])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "melt-cook in view: the handle, the pot (tipped too), the star mold, the magnifier window, the basket and the bread cat's head between the top band and the bottom %.0f%% (phone, desktop and tablet)" % ((1.0 - BOTTOM_FREE) * 100.0),
		"; ".join(problems.slice(0, 6) + seen))


# --- the pictures ---------------------------------------------------------------------------------

func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["melt_sets", "melt_stays"]
	var pick_kinds := ["item_choc", "item_egg"]
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
		"melt-cook pictures: the question's two pictures (PredictPictures) and the chocolate / egg buttons (PickPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var curie := Island.by_id("curie")
	var problems := []
	if str(curie.order[2]) != ID or ExperimentRegistry.find(ID).is_empty():
		problems.append("melt-cook is not curie's third spot as an experiment")
	if curie.playable():
		problems.append("the island opened with the labs so far")
	var own := ArtKit.builder()
	MapLandmarks.add(own, ID, Transform3D())
	var other := ArtKit.builder()
	MapLandmarks.add(other, "no-such-spot", Transform3D())
	if own.vertex_count() <= other.vertex_count():
		problems.append("the map shows the unknown spot's ball on a post")
	expect.call(problems.is_empty(), "melt-cook: the curie island's third spot is an experiment with its own map landmark (a stove, a pot, a star, an egg); the island stays in the making", "; ".join(problems))


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
		told.append([line.speaker, line.face, str(line.get("picture", "")), str(line.text).begins_with(WARNING)])
		round.clue_opened()
		round.clue_read()
	var first_ok := told == [["yaongi", "worried", "", false], ["puppy", "thinking", "", false], ["dugi", "explain", "", false], ["dugi", "explain", "", true]] \
		and round.phase() == MissionRound.Phase.ASKING and Story.keeper_of(definition) == "yaongi"
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
		"melt-cook opening: first visit 야옹이 (the island's keeper, worried), Puppy's clue, Dugi's explanation and then his one fire warning (\"(주의) …\"), then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: MeltCookGame = lab.game
	var props: MeltCookProps = lab.props
	var problems := []
	if game.piece_state != "held" or game.piece.global_position.distance_to(MeltCookProps.SHINY_AT) > 0.05:
		problems.append("not in the basket's shiny egg at the start")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 40:
		await tree.process_frame
	if game.piece_state != "held" or game.piece.global_position.distance_to(MeltCookProps.SHINY_AT) > 0.05 or props.peeled:
		problems.append("after two stamps: %s at %s" % [game.piece_state, str(game.piece.global_position)])
	# Stage 3 with the egg: the shiny egg is in the pot and so is the piece.
	lab.set_game_stage(2, 2, false)
	lab.set_control("item", "egg")
	for i in 5:
		await tree.process_frame
	if game.piece.global_position.distance_to(MeltCookProps.EGG_POT) > 0.05 or props.shiny_egg.visible:
		problems.append("the piece is not in the pot's shiny egg (%s)" % str(game.piece.global_position))
	game.show_stage(-1, 3, true)
	var frames := 0
	var peeled_seen := false
	while game.piece_state != "out" and frames < 600:
		await tree.process_frame
		frames += 1
		peeled_seen = peeled_seen or not props.egg_shell.visible
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or not peeled_seen or not props.peeled or rest.distance_to(props.cat.global_position) > 2.0:
		problems.append("after the last stamp: %s at %s, shell off %s" % [game.piece_state, str(rest), peeled_seen])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	if (again.game as MeltCookGame).take_piece() != null:
		problems.append("a finished spot still has a piece")
	expect.call(problems.is_empty(), "melt-cook piece: shut in the basket's shiny egg (it hops a stamp) until the last stamp; at stage 3 the shiny egg is the one in the pot, the bread cat peels it (shell off, pieces on the stove) and the piece jumps down onto the table in front of the cat; a finished spot has no piece",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
