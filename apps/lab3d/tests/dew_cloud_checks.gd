## 구름과 이슬 (#92, 2026-11-07; Hutton Island's fifth spot):
## - the data: the definition is valid, a hutton island lab (index.json `islands`, after seasons), not
##   one of the first island's; no explanation picture (hutton-lines.md 5 has no "[그림: …]"); the
##   question's and the condition button's pictures are code-drawn kinds; its Korean lines are
##   docs/islands/hutton-lines.md section 5 word for word (the fox's line, Puppy's clue, Dugi's two
##   lines, the question, its choices, reason and bridge, the riddle, every stage's condition, mission,
##   explanation, win, miss and wrong-condition line) with the doc's faces; the stages' conditions are
##   hutton-missions.md 5's; Puppy's result lines are short with no science words, digits or symbols;
##   English has every line;
## - the textbook values (tests/earth_textbook_values.json "dew_point"): the saturation vapour amounts
##   at 0..30 °C, dew points and relative humidity, a humid day's dew point over a dry day's, the
##   rising air's lapse rates and the cloud base 125 m × (T − Td);
## - the model: the humid day's cup needs 2 cubes, the dry day's 4 (one fewer is "clear"), the cup
##   glides to its cold, the humid parcel makes its cloud below the summit and the dry one none,
##   "ready" until something cools, 다시 and a new day start over;
## - the judging (MissionRound on the real lab): each stage's hit and miss (Puppy's line), the wrong
##   day's line, nothing while a knob is held;
## - the condition button: 눅눅한 날 / 마른 날 (picture buttons on every stage) set the humidity, the
##   vapour dots follow it;
## - no number on the screen: the observations are words, no units, the card is the state; the cup's
##   dew and cold and the parcel's cloud follow the model;
## - what matters is big and in view: the cup, the ice to take, the mountain's summit (the piece) and
##   the parcel's way between the top band and the bottom on the phone, the desktop and the tablet;
## - the spot: the hutton map's dew-cloud spot is this experiment, the island is still not playable;
## - the opening (the fox first on a first visit), the hands (an ice cube dropped over the cup goes
##   in, elsewhere it goes back; the parcel climbs the mountain in stage 3 only; the hand guide shows
##   the part in play) and the piece (under the dust until the last stamp).
extends RefCounted

const ID := "dew-cloud"
const LINES_PATH := "res://../../docs/islands/hutton-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/hutton-missions.md"
const VALUES_PATH := "res://tests/earth_textbook_values.json"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
## The phone (2340 x 1080) and the tablet (1920 x 1200) in UI units at the same height.
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
## A desktop window (1920 x 1080).
const DESKTOP := Vector2(1280, 720)
## In view: inside this margin of the view's sides, under the top band (the title, the key card and
## the mission strip) and above the bottom share the dialogue box and the buttons take.
const EDGE := 0.03
const TOP_FREE := 0.2
## Right of the title strip and the card (they end at TITLE_RIGHT of the width) only the 자세히 button
## sits at the top right: there the sky is free down from TOP_SKY.
const TITLE_RIGHT := 0.4
const TOP_SKY := 0.08
const BOTTOM_FREE := 0.8
## The cup at least this share of the view's height; the parcel at least this share.
const CUP_MIN := 0.14
const PARCEL_MIN := 0.08
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
	check_textbook()
	check_model()
	await check_judging()
	await check_condition_button()
	await check_no_numbers()
	await check_in_view()
	check_spot()
	await check_pictures()
	check_opening()
	await check_hands()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> DewCloudLab:
	var lab := DewCloudLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "dew-cloud: the definition loads", "not found")
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
	var picks: Array = kid.picks.air
	if picks.map(func(p: Dictionary) -> String: return str(p.value)) != ["humid", "dry"] \
			or picks.any(func(p: Dictionary) -> bool: return not p.picture in PickPictures.KINDS):
		problems.append("the air buttons %s" % str(picks))
	var rules: Array = definition.manipulation.objects
	if rules.map(func(o: Dictionary) -> String: return str(o.id)) != [DewCloudLab.ICE_ID, DewCloudLab.AIR_ID]:
		problems.append("the hands %s" % str(rules))
	expect.call(problems.is_empty(), "dew-cloud: a valid definition, a Hutton Island lab after seasons (index.json islands), not the first island's; no explanation picture (none in the doc); code-drawn question and day pictures; two hands (ice, air)",
		"; ".join(problems))


## The section "## 5. 구름과 이슬" of the lines doc: its numbered lines [who, face, text], the question,
## the riddle and the stage table's rows (cells).
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 5. 구름과 이슬")
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


## The stage table of hutton-missions.md "### 5. 구름과 이슬": [stage, condition] per row.
func _mission_conditions() -> Array:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 5. 구름과 이슬")
	var end := text.find("\n### ", start + 4)
	var out := []
	for raw in text.substr(start, end - start).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			var cells := Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges())
			out.append([cells[0], cells[1]])
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
			or predict.reason != q.get("reason") or predict.bridge != q.get("bridge") or answer != q.get("answer") or labels[0] != "공기에서 왔어요":
		problems.append("the question %s (doc %s)" % [str(predict), str(q)])
	if Story.map_clue(definition) != doc.get("riddle"):
		problems.append("the riddle '%s' (doc '%s')" % [Story.map_clue(definition), doc.get("riddle")])
	var stages: Array = definition.missions.stages
	var pick_label := {}
	for p: Dictionary in definition.kid.picks.air:
		pick_label[p.value] = p.label
	var missions := _mission_conditions()
	if doc.rows.size() != 3 or missions.size() != 3:
		problems.append("%d doc rows, %d mission rows" % [doc.rows.size(), missions.size()])
	else:
		for i in 3:
			var stage: Dictionary = stages[i]
			var day := str(pick_label.get(stage.conditions.air, "?"))
			var got := [str(i + 1), day, stage.text, stage.say, stage.win, stage.miss, stage.miss_conditions]
			if got != doc.rows[i]:
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
			if missions[i] != [str(i + 1), day]:
				problems.append("stage %d condition %s (missions %s)" % [i + 1, day, str(missions[i])])
	expect.call(problems.is_empty(), "dew-cloud: the Korean lines are hutton-lines.md 5 word for word (the fox, Puppy, Dugi's two lines, the question, the riddle, the three stages with their days and wrong-day lines) with its faces; the days are hutton-missions.md 5's",
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
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/dew-cloud.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/dew-cloud.json")
	var en: Dictionary = Locale.overlay(raw, english)
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" or en.kid.intro_more.size() != 1 \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss", "miss_conditions"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en.kid.picks.air.any(func(p: Dictionary) -> bool: return str(p.get("label", "")) == "") or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "dew-cloud: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


# --- the textbook values --------------------------------------------------------------------------

## DewCloudModel against tests/earth_textbook_values.json "dew_point" (as earth_model_checks does for
## SunModel): the saturation amounts, the dew points and humidity, the humid day's higher dew point,
## the lapse rates and the cloud base.
func check_textbook() -> void:
	var values: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VALUES_PATH))
	var block: Dictionary = values.get("dew_point", {})
	var problems := []
	if block.is_empty():
		expect.call(false, "dew-cloud textbook values: the dew_point block", "missing")
		return
	var sat: Dictionary = block.saturation_amount
	var last := -INF
	for case: Dictionary in sat.cases:
		var got := DewCloudModel.saturation_amount(float(case.celsius))
		if absf(got - float(case.amount)) > float(sat.tolerance):
			problems.append("saturation at %.0f °C %.3f (want %.1f)" % [float(case.celsius), got, float(case.amount)])
		if got <= last:
			problems.append("saturation not rising at %.0f °C" % float(case.celsius))
		last = got
	var dew: Dictionary = block.dew_point
	for case: Dictionary in dew.cases:
		var t := float(case.celsius)
		var amount := float(case.amount) if case.has("amount") else DewCloudModel.saturation_amount(t) * float(case.humidity_in) / 100.0
		var td := DewCloudModel.dew_point_of_amount(amount)
		if absf(td - float(case.dew_point)) > float(dew.tolerance_celsius):
			problems.append("%s: dew point %.3f (want %.1f)" % [case.name, td, float(case.dew_point)])
		if case.has("humidity") and absf(DewCloudModel.relative_humidity(t, amount) - float(case.humidity)) > float(dew.humidity_tolerance):
			problems.append("%s: humidity %.2f (want %.1f)" % [case.name, DewCloudModel.relative_humidity(t, amount), float(case.humidity)])
		# The dew point is where the air saturates: its saturation amount is the air's amount.
		if absf(DewCloudModel.saturation_amount(td) - amount) > 1e-6:
			problems.append("%s: saturation at the dew point %.6f" % [case.name, DewCloudModel.saturation_amount(td)])
	# The same air with more vapour (humid) has the higher dew point; the lab's two days at its air.
	var humid := DewCloudModel.dew_point(DewCloudModel.AIR_TEMP, DewCloudModel.HUMID)
	var dry := DewCloudModel.dew_point(DewCloudModel.AIR_TEMP, DewCloudModel.DRY)
	if not (dry < humid and humid < DewCloudModel.AIR_TEMP):
		problems.append("the days' dew points: humid %.2f, dry %.2f" % [humid, dry])
	var lift: Dictionary = block.lifting
	if DewCloudModel.DRY_LAPSE != float(lift.dry_lapse_per_km) or DewCloudModel.DEW_LAPSE != float(lift.dew_lapse_per_km):
		problems.append("lapse rates %.1f / %.1f" % [DewCloudModel.DRY_LAPSE, DewCloudModel.DEW_LAPSE])
	if absf(DewCloudModel.cloud_base(1.0, 0.0) - float(lift.base_per_degree_m)) > 1e-9:
		problems.append("cloud base per degree %.3f" % DewCloudModel.cloud_base(1.0, 0.0))
	for case: Dictionary in lift.cases:
		var t := float(case.celsius)
		var td := float(case.dew_point)
		var base := DewCloudModel.cloud_base(t, td)
		if absf(base - float(case.base_m)) > float(lift.tolerance_m):
			problems.append("cloud base of %.0f/%.0f °C %.2f m (want %.0f)" % [t, td, base, float(case.base_m)])
		# There the rising air is at its own dew point (it starts to condense).
		if absf(DewCloudModel.parcel_temperature(t, td, base) - DewCloudModel.parcel_dew_point(t, td, base)) > 1e-9 \
				or (base > 0.0 and DewCloudModel.parcel_temperature(t, td, base * 0.5) <= DewCloudModel.parcel_dew_point(t, td, base * 0.5)):
			problems.append("the parcel of %.0f/%.0f °C meets its dew point off its base" % [t, td])
	expect.call(problems.is_empty(), "dew-cloud model: the textbook values (%s; dew point and 상대 습도; a humid day's dew point over a dry day's; 건조 단열 감률 %.0f °C/km, 이슬점 감률 %.0f °C/km, 상승 응결 고도 125 (T − Td) m)" % [sat.source.get_slice(" 포화", 0), DewCloudModel.DRY_LAPSE, DewCloudModel.DEW_LAPSE],
		"; ".join(problems))


# --- the model ------------------------------------------------------------------------------------

## Drops ice into `model`'s cup until it holds `cubes` and lets the cup finish cooling.
static func _ice(model: DewCloudModel, cubes: int) -> void:
	while model.ice_count() < cubes and model.add_ice():
		pass
	while model.animating():
		model.step(1.0 / 60.0)


func check_model() -> void:
	var problems := []
	var model := DewCloudModel.new()
	if model.status() != "ready" or model.input("cup") != DewCloudModel.AIR_TEMP or not model.humid():
		problems.append("the start: %s, cup %.1f" % [model.status(), model.input("cup")])
	# The humid day: one cube leaves the cup over the dew point, two bring dew.
	var needs := {}
	for day: Array in [["humid", DewCloudModel.HUMID], ["dry", DewCloudModel.DRY]]:
		model.set_start("humidity", day[1])
		model.reset()
		var cubes := 0
		while model.status() != "dew" and cubes < DewCloudModel.ICE_MAX:
			cubes += 1
			model.add_ice()
			if not model.animating() and cubes > 0:
				problems.append("%s: the cup did not glide" % day[0])
			while model.animating():
				model.step(1.0 / 60.0)
			if model.status() != "dew" and model.status() != "clear":
				problems.append("%s with %d cubes: %s" % [day[0], cubes, model.status()])
		needs[day[0]] = cubes if model.status() == "dew" else -1
		if absf(model.input("cup") - (DewCloudModel.AIR_TEMP - DewCloudModel.COOL_PER_ICE * cubes)) > 1e-9 or model.dew_share() <= 0.0:
			problems.append("%s: cup %.2f, dew %.2f" % [day[0], model.input("cup"), model.dew_share()])
	if needs != {"humid": 2, "dry": 4}:
		problems.append("cubes needed %s (want humid 2, dry 4)" % str(needs))
	# The cup holds ICE_MAX cubes.
	_ice(model, DewCloudModel.ICE_MAX)
	if model.add_ice() or model.ice_count() != DewCloudModel.ICE_MAX:
		problems.append("more than %d cubes" % DewCloudModel.ICE_MAX)
	# The parcel: the humid day's cloud below the summit, none on the dry day; it takes over the status.
	model.set_start("humidity", DewCloudModel.HUMID)
	var base := model.base_share()
	if not (base > 0.3 and base < 0.9):
		problems.append("humid cloud base at %.2f of the way" % base)
	for lift: float in [base - 0.03, base + 0.01, 1.0]:
		model.set_input("lift", lift)
		var want := "cloud" if lift >= base else "rising"
		if model.status() != want or (want == "cloud") != (model.parcel_temp() <= model.parcel_dew() + 1e-9):
			problems.append("humid parcel at %.2f: %s (T %.2f, Td %.2f)" % [lift, model.status(), model.parcel_temp(), model.parcel_dew()])
	if model.cloud_share() <= 0.0:
		problems.append("no cloud at the summit")
	model.set_start("humidity", DewCloudModel.DRY)
	model.set_input("lift", 1.0)
	if model.status() != "rising" or model.base_share() <= 1.0:
		problems.append("dry parcel at the summit: %s (base %.2f)" % [model.status(), model.base_share()])
	model.reset()
	if model.status() != "ready" or model.ice_count() != 0 or model.input("lift") != 0.0 or model.humid():
		problems.append("after a reset: %s, ice %d, lift %.2f" % [model.status(), model.ice_count(), model.input("lift")])
	expect.call(problems.is_empty(), "dew-cloud model: \"ready\" until something cools; the humid day's dew takes 2 cubes and the dry day's 4 (the cup glides there), the cup holds %d; the humid parcel's cloud forms below the summit (at its dew point), the dry one's never; 다시 keeps the day" % DewCloudModel.ICE_MAX,
		"; ".join(problems))


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	# [stage, day, cubes or -1, lift, hit, missed]
	var cases := [
		[0, "humid", 1, 0.0, false, true], [0, "humid", 2, 0.0, true, false], [0, "humid", 5, 0.0, true, false], [0, "humid", 0, 0.0, false, false],
		[0, "dry", 2, 0.0, false, true],
		[1, "dry", 3, 0.0, false, true], [1, "dry", 4, 0.0, true, false], [1, "dry", 1, 0.0, false, true],
		[2, "humid", 0, 0.5, false, true], [2, "humid", 0, 1.0, true, false], [2, "humid", 0, 0.8, true, false], [2, "dry", 0, 1.0, false, true],
		[2, "humid", 0, 0.0, false, false],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_control("air", case[1])
		_ice(lab.model, int(case[2]))
		lab.model.set_input("lift", float(case[3]))
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations())
		if (stamps == stage + 1) != bool(case[4]) or missed != bool(case[5]):
			problems.append("stage %d %s, %d cubes, lift %.1f (%s): stamps %d missed %s" % [stage + 1, case[1], case[2], case[3], status, stamps, missed])
	var wants := [["humid", "눅눅한 날을 골라 봐!"], ["dry", "마른 날을 골라 봐!"], ["humid", "눅눅한 날을 골라 봐!"]]
	for i in 3:
		lab.set_control("air", "dry" if wants[i][0] == "humid" else "humid")
		var off := not MissionRound.conditions_met(definition.missions.stages[i].conditions, lab)
		var line := MissionRound.result_line(definition, i, false, off)
		if line[0] != wants[i][1] or not off:
			problems.append("stage %d wrong day says '%s'" % [i + 1, line[0]])
	lab.set_control("air", "humid")
	_ice(lab.model, 3)
	lab.manipulation_started(DewCloudLab.ICE_ID)
	if lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while a cube is held")
	lab.manipulation_cancelled(DewCloudLab.ICE_ID)
	lab.reset_run()
	(lab.model as DewCloudModel).add_ice()
	(lab.model as DewCloudModel).add_ice()
	if lab.settled():
		problems.append("settled while the cup cools")
	expect.call(problems.is_empty(), "dew-cloud judging: dew on the humid day's cup (2 cubes) / the dry day's (4) / the cloud up the mountain hit, too little ice or height misses (Puppy's line), the wrong day says the doc's \"…날을 골라 봐!\"; not judged while held or while the cup cools",
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
		if groups.size() != 1 or groups[0].control != DewCloudLab.AIR_CONTROL or groups[0].presets.size() != 2:
			problems.append("stage %d buttons %s" % [i + 1, str(groups)])
	if lab.control_value("air") != "humid" or lab.model.input("humidity") != DewCloudModel.HUMID or lab.props.shown_vapour != DewCloudProps.VAPOUR_HUMID:
		problems.append("the start is not the humid day")
	_ice(lab.model, 2)
	var resets := lab.reset_count
	lab.set_control("air", "dry")
	if lab.model.input("humidity") != DewCloudModel.DRY or lab.reset_count != resets + 1 or lab.status() != "ready" \
			or lab.props.shown_vapour != DewCloudProps.VAPOUR_DRY or lab.props.shown_ice != 0:
		problems.append("dry: humidity %.0f, %s, vapour %d" % [lab.model.input("humidity"), lab.status(), lab.props.shown_vapour])
	lab.reset_run()
	if lab.model.input("humidity") != DewCloudModel.DRY:
		problems.append("다시 lost the day")
	expect.call(problems.is_empty(), "dew-cloud condition button: 눅눅한 날 / 마른 날 on every stage; the day sets the air's humidity and its vapour dots (many / few), a new day starts the run over, 다시 keeps it",
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
	var colds := []
	var drops := []
	for cubes in DewCloudModel.ICE_MAX + 1:
		_ice(lab.model, cubes)
		lab._show()
		colds.append(lab.props.shown_cold)
		drops.append(lab.props.shown_drops)
		for key: String in lab.observations():
			var value: Variant = lab.observations()[key]
			if not value is String or str(value) == "" or digits.search(str(value)) != null:
				problems.append("%s with %d cubes: %s" % [key, cubes, str(value)])
	for i in range(1, colds.size()):
		if colds[i] <= colds[i - 1] or drops[i] < drops[i - 1]:
			problems.append("the cup's cold %s and drops %s" % [str(colds), str(drops)])
			break
	if drops[1] != 0 or drops[2] <= 0 or lab.props.shown_ice != DewCloudModel.ICE_MAX:
		problems.append("drops %s, cubes shown %d" % [str(drops), lab.props.shown_ice])
	lab.reset_run()
	lab.model.set_input("lift", 0.3)
	lab._show()
	var low := [lab.props.shown_cool, lab.props.shown_cloud]
	lab.model.set_input("lift", 1.0)
	lab._show()
	if not (low[0] < lab.props.shown_cool and low[1] == 0.0 and lab.props.shown_cloud > 0.0):
		problems.append("the parcel low %s, at the top %.2f / %.2f" % [str(low), lab.props.shown_cool, lab.props.shown_cloud])
	for key: String in lab.observations():
		if digits.search(str(lab.observations()[key])) != null:
			problems.append("%s at the top" % key)
	expect.call(problems.is_empty(), "dew-cloud: no number on the screen (the observations are words, no units, the card is the state); the cup gets colder with every cube and its drops come at the dew point and grow; the parcel cools as it rises and turns into a cloud",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

## What matters is big and in the clear on the phone's, the desktop's and the tablet's front view: the
## cup (its foot and its rim with room for the drops), the ice to take on the bowl, the mountain's
## summit with the piece, and the parcel all along its way (the foot, half way, the summit, with the
## grown cloud) stay inside the sides, under the top band (TOP_FREE) and above the bottom (BOTTOM_FREE:
## the dialogue box, the buttons). The cup is CUP_MIN of the height or more, the parcel PARCEL_MIN.
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
			var top := TOP_SKY if p.x > TITLE_RIGHT and p.x < 0.9 else TOP_FREE
			if p.x < EDGE or p.x > 1.0 - EDGE or p.y < top or p.y > BOTTOM_FREE:
				problems.append("%s: %s at %s" % [str(size), what, str(p)])
		var cup := DewCloudProps.CUP_AT
		var foot: Vector2 = at.call(cup + Vector3(0.0, 0.0, DewCloudProps.CUP_BOTTOM))
		var rim: Vector2 = at.call(cup + Vector3(0.0, DewCloudProps.CUP_HEIGHT, DewCloudProps.CUP_TOP))
		inside.call(foot, "the cup's foot")
		inside.call(rim, "the cup's rim")
		for side: float in [-1.0, 1.0]:
			inside.call(at.call(cup + Vector3(side * DewCloudProps.CUP_TOP, DewCloudProps.CUP_HEIGHT, 0.0)), "the cup's side")
		inside.call(at.call(DewCloudProps.BOWL_AT + DewCloudProps.NEXT_ICE + Vector3(-DewCloudProps.ICE_EDGE, 0.0, 0.0)), "the next ice")
		var summit: Vector2 = at.call(DewCloudProps.summit() + DewCloudGame.PIECE_AT)
		inside.call(summit, "the piece on the summit")
		inside.call(at.call(DewCloudProps.summit() + Vector3(0.0, DewCloudGame.CAP_OVER + DewCloudGame.CAP_SIZE, 0.0)), "the cloud cap's top")
		var parcel_size := 1.0
		for lift: float in [0.0, 0.5, 1.0]:
			var c := DewCloudProps.parcel_point(lift)
			var grow := 1.5 if lift >= 1.0 else 1.0   # the full cloud (DewCloudProps.show)
			var r := DewCloudProps.PARCEL_R * grow * 1.4
			for d: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
				inside.call(at.call(c + d * r), "the parcel at %.1f" % lift)
			parcel_size = minf(parcel_size, (at.call(c + Vector3.DOWN * DewCloudProps.PARCEL_R) as Vector2).y - (at.call(c + Vector3.UP * DewCloudProps.PARCEL_R) as Vector2).y)
		var cup_size := foot.y - rim.y
		if cup_size < CUP_MIN:
			problems.append("%s: the cup is only %.2f of the height" % [str(size), cup_size])
		if parcel_size < PARCEL_MIN:
			problems.append("%s: the parcel is only %.2f of the height" % [str(size), parcel_size])
		seen.append("%s cup %.2f, parcel %.2f, summit %s, cup foot %s" % [str(size), cup_size, parcel_size, str(summit), str(foot)])
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "dew-cloud in view: the cup, the ice to take, the summit's piece and its cloud cap, and the parcel all up its way between the top band (%.0f%%; the sky right of the title strip from %.0f%%) and the bottom %.0f%%, the cup %.0f%% of the height or more, the parcel %.0f%% (phone, desktop and tablet)" % [TOP_FREE * 100.0, TOP_SKY * 100.0, (1.0 - BOTTOM_FREE) * 100.0, CUP_MIN * 100.0, PARCEL_MIN * 100.0],
		"; ".join(problems.slice(0, 4) + seen) if not problems.is_empty() else "; ".join(seen))


# --- the pictures ---------------------------------------------------------------------------------

## The question's dew pictures (PredictPictures) and the condition buttons' day pictures
## (PickPictures) draw on a canvas of their button's size without errors.
func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var predict_kinds := ["dew_from_air", "dew_from_inside"]
	var pick_kinds := ["air_humid", "air_dry"]
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
		"dew-cloud pictures: the question's dew kinds (PredictPictures) and the day kinds (PickPictures) are listed and draw",
		str(drawn))


# --- the spot -------------------------------------------------------------------------------------

func check_spot() -> void:
	var hutton := Island.by_id("hutton")
	var problems := []
	if not ID in hutton.spots() or str(hutton.order[4]) != ID:
		problems.append("dew-cloud is not hutton's fifth spot")
	if ExperimentRegistry.find(ID).is_empty():
		problems.append("the spot is not an experiment")
	expect.call(problems.is_empty(), "dew-cloud: Hutton Island's fifth spot is an experiment (a lab on its map)", "; ".join(problems))


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
		"dew-cloud opening: first visit the fox (worried), Puppy's clue, Dugi's two lines, then the question; later visits Dugi's two lines",
		"%s / %s" % [str(told), str(later)])


# --- the hands ------------------------------------------------------------------------------------

func check_hands() -> void:
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
	# Stages 1 and 2: the ice is in play, the parcel is not (hidden, no body); the guide drags the ice.
	if lab.manipulation_body(DewCloudLab.AIR_ID) != null or lab.manipulation_body(DewCloudLab.ICE_ID) == null or lab.props.parcel.visible:
		problems.append("stage 1: the parcel in play or shown")
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != DewCloudLab.ICE_ID or not DewCloudLab.over_cup(guide.get("to", Vector3.ZERO)):
		problems.append("stage 1 hand guide %s" % str(guide))
	# A cube dragged over the cup and let go drops in.
	var next := DewCloudProps.BOWL_AT + DewCloudProps.NEXT_ICE
	var at: Vector2 = screen.call(next)
	m.handle_pointer("press", at)
	if m.mode != "drag" or m.active_id != DewCloudLab.ICE_ID or lab.holding != DewCloudLab.ICE_ID:
		problems.append("press on the ice: mode '%s' id '%s'" % [m.mode, m.active_id])
	var over: Vector2 = screen.call(DewCloudProps.CUP_AT + Vector3(0.0, DewCloudProps.CUP_HEIGHT + 0.5, 0.0))
	m.handle_pointer("move", at.lerp(over, 0.5))
	m.handle_pointer("move", over)
	await tree.process_frame
	if lab.props.held_ice.global_position.distance_to(DewCloudProps.CUP_AT + Vector3(0.0, DewCloudProps.CUP_HEIGHT + 0.5, 0.0)) > 0.6 or lab.settled():
		problems.append("the held cube at %s" % str(lab.props.held_ice.global_position))
	m.handle_pointer("release", over)
	if lab.model.input("ice") != 1.0 or lab.holding != "" or lab.props.held_ice.global_position.distance_to(next) > 1e-3 or not lab.placements().is_empty():
		problems.append("dropped over the cup: %d cubes, cube at %s" % [int(lab.model.input("ice")), str(lab.props.held_ice.global_position)])
	# One let go away from the cup goes back to the heap.
	m.handle_pointer("press", at)
	var away: Vector2 = screen.call(DewCloudProps.BOWL_AT + Vector3(-0.6, 1.6, 0.0))
	m.handle_pointer("move", away)
	await tree.process_frame
	m.handle_pointer("release", away)
	if lab.model.input("ice") != 1.0 or lab.props.held_ice.global_position.distance_to(next) > 1e-3:
		problems.append("dropped away: %d cubes" % int(lab.model.input("ice")))
	# Stage 3: the parcel in play (shown), the ice not; the guide drags the parcel up the mountain.
	lab.game.show_stage(DewCloudLab.AIR_STAGE, DewCloudLab.AIR_STAGE, false)
	lab.reset_run()
	await tree.process_frame
	if lab.manipulation_body(DewCloudLab.ICE_ID) != null or lab.manipulation_body(DewCloudLab.AIR_ID) == null or not lab.props.parcel.visible:
		problems.append("stage 3: the ice in play or the parcel hidden")
	guide = m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != DewCloudLab.AIR_ID \
			or DewCloudProps.lift_of(guide.get("to", Vector3.ZERO)) < DewCloudProps.lift_of(guide.get("from", Vector3.ZERO)) + 0.3:
		problems.append("stage 3 hand guide %s" % str(guide))
	var foot := DewCloudProps.parcel_point(0.0)
	at = screen.call(foot)
	m.handle_pointer("press", at)
	if m.active_id != DewCloudLab.AIR_ID:
		problems.append("press on the parcel: '%s'" % m.active_id)
	var top: Vector2 = screen.call(DewCloudProps.parcel_point(1.0))
	m.handle_pointer("move", at.lerp(top, 0.5))
	m.handle_pointer("move", top)
	await tree.process_frame
	if lab.model.input("lift") < 0.85 or lab.settled():
		problems.append("held at the top: lift %.2f" % lab.model.input("lift"))
	m.handle_pointer("release", top)
	if lab.status() != "cloud" or not lab.placements().has(DewCloudLab.AIR_ID) or lab.props.parcel.position.distance_to(DewCloudProps.parcel_point(lab.model.input("lift"))) > 1e-4:
		problems.append("put down at the top: %s" % lab.status())
	var before: float = lab.model.input("lift")
	at = screen.call(DewCloudProps.parcel_point(before))
	m.handle_pointer("press", at)
	m.handle_pointer("move", screen.call(foot))
	await tree.process_frame
	m.handle_pointer("cancel", screen.call(foot))
	if absf(lab.model.input("lift") - before) > 1e-6 or lab.holding != "":
		problems.append("cancel left it at %.2f (was %.2f)" % [lab.model.input("lift"), before])
	expect.call(problems.is_empty(), "dew-cloud hands: in stages 1-2 the ice only (the guide drags a cube to the cup), a cube let go over the cup drops in and one let go elsewhere goes back (no placement); in stage 3 the parcel only, shown, dragged up the mountain to its cloud (kept, a cancel puts it back)",
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


# --- the piece ------------------------------------------------------------------------------------

func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: DewCloudGame = lab.game
	var problems := []
	var start: Vector3 = game.piece.global_position
	if game.piece_state != "held" or not game.piece.visible or start.distance_to(DewCloudProps.summit()) > 1.5 or game.washed() or game.flowers_up() or game.cap.visible:
		problems.append("not dusty on the summit at the start (or washed, a cap)")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	for i in 30:
		await tree.process_frame
	if game.piece_state != "held" or game.washed():
		problems.append("out before the last stamp (%s)" % game.piece_state)
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 600:
		await tree.process_frame
		frames += 1
	var rest: Vector3 = game.piece.global_position
	if game.piece_state != "out" or not game.washed() or not game.flowers_up() or not game.cap.visible \
			or absf(rest.y - LabGame.PIECE_SIZE) > 0.12 or rest.distance_to(lab.props.cat.global_position) > 2.0:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(rest)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	var again := _lab()
	tree.root.add_child(again)
	await tree.process_frame
	again.game.show_stage(-1, 3, false)
	var done := again.game as DewCloudGame
	if done.take_piece() != null or not done.washed() or not done.cap.visible or not again.in_play(DewCloudLab.ICE_ID) or not again.in_play(DewCloudLab.AIR_ID):
		problems.append("a finished spot: a piece, dust, no cap, or a hand not in play")
	expect.call(problems.is_empty(), "dew-cloud piece: dusty on the summit among drooping flowers until the last stamp, then a cloud cap rains on it, the dust washes away, the flowers lift and it jumps down beside the cat; a finished spot shows the cap, no dust, no piece, both hands free",
		"; ".join(problems))
	lab.queue_free()
	again.queue_free()
	await tree.process_frame
