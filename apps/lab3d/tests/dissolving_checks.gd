## 녹으면 사라질까? (#157, 2026-11-17; Curie Island's second spot) and the fast-forward time it brings
## (FastClock, TimeSign, SceneNight: the plan's decision 1, 안 A, shared with #159):
## - the data: a valid definition, the curie island's second lab, no condition buttons; the spoon is
##   stirred (guide "stir") and the bucket dragged (to its far end); the question's pictures are code
##   drawn; the Korean lines are docs/islands/curie-lines.md section 2 word for word (야옹이 surprised,
##   Puppy's clue, Dugi with the one bold word 녹는다, the question, the riddle, the three stages); the
##   mission doc's section 2 has the same missions (decision 6) and no condition button; Puppy's lines
##   are short with no science words, digits or symbols; every Korean line is 반말; English has every line;
## - the model: deterministic; the textbook values: salt's solubility (a spoonful all dissolves in a
##   glass, 100 g does not), the weight before and after the same, seawater 3.5 % salt all left on the
##   dry tray, the crust only once the water left cannot hold the salt, the sun drying only by day (the
##   tray dry after two nights);
## - the clock: start / stop / advance / until, the marker's share, the nights, the dark at night, the
##   sunshine by day, the condition lock until reset; the time sign shows it (the marker from the sun to
##   the moon, the lamp while it runs, a moon stamp a night) and 물의 여행's sign is drawn with its meshes;
## - the judging (MissionRound on the real lab): the clear glass, the same needle, the salt on the tray
##   hit; the stirring half done and the drying tray say Puppy's lines; nothing while a finger holds;
## - the hand (the shell's Manipulator): round and round over the glass stirs it clear (either way), the
##   spoon follows; the bucket let go over the tray pours and the time runs to the dry tray (the scene
##   dark at night, two moon stamps), let go short of it goes back; the hand guide goes round / drags;
## - the tables: stage 1 the glass, stage 2 on the scale (the needle on its ghost), stage 3 the tray,
##   the bucket and the time sign; a stage just cleared keeps its table until the next reset;
## - no number on the screen; what matters in view on the phone, the desktop and the tablet;
## - the spot (curie's second, its own map landmark), the opening and the piece (in the bucket, on
##   the tray after the pour, out of the salt at the last stamp).
extends RefCounted

const ID := "dissolving"
const LINES_PATH := "res://../../docs/islands/curie-lines.md"
const MISSIONS_PATH := "res://../../docs/islands/curie-missions.md"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const VIEW_SIZE := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const DESKTOP := Vector2(1280, 720)
const EDGE := 0.03
const BOTTOM_FREE := 0.8
const TOP_FREE := 0.38
const LEFT_BAND := 680.0
const LINE_MAX := 24
const STEP := 1.0 / 60.0

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
	check_clock()
	await check_time_sign()
	await check_judging()
	await check_stir()
	await check_pour()
	await check_tables()
	await check_no_numbers()
	await check_in_view()
	check_spot()
	await check_pictures()
	check_opening()
	await check_piece()
	if Locale.lang != lang:
		Locale.set_language(lang)


func _definition() -> Dictionary:
	return ExperimentRegistry.find(ID)


func _lab() -> DissolvingLab:
	var lab := DissolvingLab.new()
	lab.definition = ExperimentDefinition.new(_definition())
	return lab


static func _run(model: DissolvingModel, seconds: float) -> void:
	for k in int(round(seconds / STEP)):
		model.step(STEP)


# --- the data -------------------------------------------------------------------------------------

func check_data() -> void:
	var definition := _definition()
	var problems := []
	if definition.is_empty():
		expect.call(false, "dissolving: the definition loads", "not found")
		return
	problems.append_array(ExperimentRegistry.validate(definition))
	var island := ExperimentRegistry.island_labs("curie").map(func(d: Dictionary) -> String: return str(d.id))
	if island.size() < 2 or island[1] != ID or ExperimentRegistry.island_of(ID) != "curie":
		problems.append("curie's labs %s" % str(island))
	if ExperimentRegistry.load_all().any(func(d: Dictionary) -> bool: return d.id == ID):
		problems.append("listed with the first island's labs")
	if not definition.controls.is_empty():
		problems.append("condition controls %s" % str(definition.controls))
	var objects: Array = definition.manipulation.objects
	if objects.size() != 2 or objects[0].id != DissolvingLab.SPOON_ID or objects[0].get("guide", "") != "stir" or objects[0].surface != DissolvingLab.STIR_SURFACE \
			or objects[1].id != DissolvingLab.BUCKET_ID or objects[1].surface != DissolvingLab.POUR_SURFACE or objects[1].get("guide_to", "") != "max":
		problems.append("the objects %s" % str(objects))
	for choice: Dictionary in definition.predict.choices:
		if not choice.picture in PredictPictures.KINDS:
			problems.append("question picture %s" % choice.picture)
	if PieceArt.of_experiment(ID) != PieceArt.of_island("curie"):
		problems.append("its piece is %s" % PieceArt.of_experiment(ID))
	var bad := definition.duplicate(true)
	bad.manipulation.objects[0].guide = "swirl"
	if ExperimentRegistry.validate(bad).is_empty():
		problems.append("an unknown guide passes")
	expect.call(problems.is_empty(), "dissolving: a valid definition, the curie island's second lab, no condition buttons; the spoon stirred (guide stir), the bucket dragged to the tray; code-drawn question pictures; the island's lens piece",
		"; ".join(problems))


## The section "## 2. 녹으면 사라질까?" of the lines doc.
func _doc_section() -> Dictionary:
	var text := FileAccess.get_file_as_string(LINES_PATH)
	var start := text.find("## 2. 녹으면 사라질까?")
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
	var faces := {"걱정": "worried", "생각": "thinking", "설명": "explain", "기쁨": "happy", "놀람": "surprised"}
	var who := {"야옹이": "yaongi", "빵고양이": "cat", "퍼피": "puppy", "두기두기": "dugi"}
	var opening: Array = MissionRound.first_visit_lines(definition) + MissionRound.intro_lines(definition)
	if doc.lines.size() != 3 or opening.size() != 3:
		problems.append("%d doc lines, %d opening lines" % [doc.lines.size(), opening.size()])
	else:
		for i in 3:
			var want: Array = doc.lines[i]
			var got: Dictionary = opening[i]
			if got.speaker != who.get(want[0], "?") or got.face != faces.get(want[1], "?") or got.text != want[2] or str(got.get("picture", "")) != "":
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
			var got := [str(i + 1), stage.text, stage.say, stage.win, stage.miss, "—"]
			if got != doc.rows[i] or stage.has("miss_conditions"):
				problems.append("stage %d %s (doc %s)" % [i + 1, str(got), str(doc.rows[i])])
	expect.call(problems.is_empty(), "dissolving: the Korean lines are curie-lines.md 2 word for word (야옹이 surprised, Puppy's clue, Dugi, the question, the riddle, the three stages, no wrong-condition line) with its faces",
		"; ".join(problems))


## curie-missions.md 2: the spoon, no condition button, the one science word 녹는다 (Dugi's introduction
## marks it, and only it), the same three missions as the lines doc (decision 6: the lines doc's).
func check_missions_doc() -> void:
	var text := FileAccess.get_file_as_string(MISSIONS_PATH)
	var start := text.find("### 2. 녹으면 사라질까?")
	var section := text.substr(start, text.find("\n### ", start + 4) - start)
	var rows := []
	for raw in section.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("| ") and line.substr(2, 1).is_valid_int():
			rows.append(Array(line.split("|")).slice(1, -1).map(func(c: String) -> String: return c.strip_edges())[1])
	var got: Array = _definition().missions.stages.map(func(s: Dictionary) -> String: return str(s.text))
	var intro := str(_definition().kid.intro)
	var marks := RegEx.create_from_string("\\*\\*([^*]+)\\*\\*").search_all(intro).map(func(m: RegExMatch) -> String: return m.get_string(1))
	var says := " ".join(_definition().missions.stages.map(func(s: Dictionary) -> String: return str(s.say)))
	expect.call(start >= 0 and section.contains("**조건 단추**: 없음") and section.contains("**과학 낱말**: **녹는다**") and rows == got \
			and marks == ["녹는다"] and not says.contains("**"),
		"dissolving: curie-missions.md 2 has the lines doc's three missions, no condition button; the one bold science word is 녹는다",
		"%s / %s, marks %s" % [str(rows), str(got), str(marks)])


func check_result_lines() -> void:
	var problems := []
	var science := Story.science_words()
	var symbols := RegEx.create_from_string("[0-9%=+×/<>]")
	var definition := _definition()
	for stage: Dictionary in definition.missions.stages:
		for key: String in ["win", "miss"]:
			var line := str(stage.get(key, ""))
			if line == "" or line.length() > LINE_MAX or symbols.search(line) != null or science.any(func(w: String) -> bool: return line.contains(w)):
				problems.append("%s '%s'" % [key, line])
	for line: String in [Story.clue(definition), Story.map_clue(definition)]:
		if science.any(func(w: String) -> bool: return line.contains(w)):
			problems.append("science word in '%s'" % line)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/experiments/dissolving.json"))
	Locale.lang = "en"
	var english: Dictionary = Locale.words("experiments/dissolving.json")
	var en: Dictionary = Locale.overlay(raw, english)
	var en_words := ["salt.bottom", "salt.melting", "salt.clear", "scale.same", "tray.empty", "tray.full", "tray.drying", "tray.salt"].map(func(k: String) -> String: return Locale.t("dissolving." + k))
	Locale.lang = "ko"
	if english.is_empty() or en.story.get("keeper", "") == "" or en.story.get("clue", "") == "" \
			or en.missions.stages.any(func(s: Dictionary) -> bool: return ["text", "say", "win", "miss"].any(func(k: String) -> bool: return str(s.get(k, "")) == "")) \
			or en_words.any(func(w: String) -> bool: return w == "" or w.begins_with("dissolving.")) or not ExperimentRegistry.validate(en).is_empty():
		problems.append("English lines missing or invalid: %s" % str(ExperimentRegistry.validate(en)))
	expect.call(problems.is_empty(), "dissolving: Puppy's lines short (<= %d) with no science words, digits or symbols; English has every line" % LINE_MAX, "; ".join(problems))


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
	walk.call(walk, ID, JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/experiments/dissolving.json")))
	for key in ["salt.bottom", "salt.melting", "salt.clear", "scale.same", "tray.empty", "tray.full", "tray.drying", "tray.salt"]:
		walk.call(walk, key, Locale.t("dissolving." + key))
	expect.call(found.is_empty(), "dissolving: every Korean line is 반말 (no 요 / 세요 / 니다)", "; ".join(found))


# --- the model ------------------------------------------------------------------------------------

## The same stirring and pour stepped the same way give the same state; reset keeps the table and
## starts the clock over; stirring on the tray's table does nothing.
func check_model() -> void:
	var problems := []
	var runs := []
	for k in 2:
		var m := DissolvingModel.new()
		m.stir(1.7)
		var seen: Array = [m.status(), m.dissolved_g(), m.scale_g()]
		m.set_site(DissolvingModel.TRAY)
		m.pour()
		for i in 700:
			m.step(STEP)
			if i % 50 == 0:
				seen.append([m.status(), m.water_mm(), m.crust(), m.clock.days])
		runs.append(seen)
	if runs[0] != runs[1]:
		problems.append("two runs differ")
	var m := DissolvingModel.new()
	if m.status() != "bottom" or m.animating() or m.dissolved_g() != 0.0:
		problems.append("before stirring: %s" % m.status())
	m.stir(1.0)
	if m.status() != "dissolving" or absf(m.dissolved_share() - 1.0 / DissolvingModel.STIR_TURNS) > 1e-9:
		problems.append("a turn: %s, %.3f dissolved" % [m.status(), m.dissolved_share()])
	m.stir(5.0)
	if m.status() != "clear" or not m.all_dissolved():
		problems.append("stirred on: %s" % m.status())
	m.set_site(DissolvingModel.SCALE)
	if m.status() != "same":
		problems.append("on the scale, all dissolved: %s" % m.status())
	m.reset()
	if m.site() != DissolvingModel.SCALE or m.status() != "bottom":
		problems.append("reset lost the table or kept the stirring")
	m.set_site(DissolvingModel.TRAY)
	m.stir(4.0)
	if m.input("stir") != 0.0 or m.status() != "ready":
		problems.append("stirred on the tray's table")
	m.pour()
	_run(m, 1.0)
	m.reset()
	if m.poured() or m.clock.days != 0.0 or m.clock.running or m.clock.locks_conditions():
		problems.append("reset kept the pour or the clock")
	expect.call(problems.is_empty(), "dissolving model: deterministic, a turn dissolves a third, all clear after three (the same on the scale), reset keeps the table and starts the clock over, no stirring on the tray's table",
		"; ".join(problems))


## Textbook values: salt's solubility 35.9 g in 100 g of water (20 °C): a 6 g spoonful all dissolves in a
## 200 g glass, 100 g would leave about 28 g at the bottom; the scale reads the same before, while and
## after (mass is conserved); seawater is 3.5 % salt, so a kilogram leaves 35 g, all of it on the dry
## tray and none lost on the way; the crust comes out only once the water left cannot hold the salt
## (about the last tenth); the sun takes 6 mm a sunny day and nothing at night, so the 15 mm tray is dry
## on the third morning (two nights).
func check_textbook() -> void:
	var problems := []
	if absf(DissolvingModel.dissolvable(6.0, 200.0) - 6.0) > 1e-9 or absf(DissolvingModel.dissolvable(100.0, 200.0) - 71.8) > 1e-9:
		problems.append("solubility: %.1f / %.1f g" % [DissolvingModel.dissolvable(6.0, 200.0), DissolvingModel.dissolvable(100.0, 200.0)])
	var m := DissolvingModel.new()
	m.set_site(DissolvingModel.SCALE)
	var before := m.scale_g()
	for i in 12:
		m.stir(0.3)
		if absf(m.scale_g() - before) > 1e-9:
			problems.append("the scale moved at %.1f turns" % m.input("stir"))
			break
	if absf(before - DissolvingModel.before_g()) > 1e-9 or m.status() != "same":
		problems.append("the scale %.1f g (before %.1f), %s" % [m.scale_g(), DissolvingModel.before_g(), m.status()])
	if absf(DissolvingModel.sea_salt_g() - 35.0) > 1e-9:
		problems.append("seawater's salt %.1f g" % DissolvingModel.sea_salt_g())
	var tray := DissolvingModel.new()
	tray.set_site(DissolvingModel.TRAY)
	tray.pour()
	var first_crust := -1.0
	var night_drop := false
	var last_mm := tray.water_mm()
	while tray.clock.running:
		tray.step(STEP)
		if tray.crust() > 0.0 and first_crust < 0.0:
			first_crust = tray.water_share()
		if tray.clock.is_night() and tray.water_mm() < last_mm - 1e-9:
			night_drop = true
		last_mm = tray.water_mm()
		var salt := tray.crystal_g() + minf(DissolvingModel.sea_salt_g(), DissolvingModel.holds(tray.water_g()))
		if absf(salt - DissolvingModel.sea_salt_g()) > 1e-9:
			problems.append("salt lost on the way: %.3f g" % salt)
			break
	if not tray.dry() or absf(tray.crystal_g() - 35.0) > 1e-9 or tray.status() != "salt":
		problems.append("the dry tray: %s, %.1f g of salt" % [tray.status(), tray.crystal_g()])
	if first_crust < 0.0 or first_crust > 0.12:
		problems.append("the crust came out with %.2f of the water left" % first_crust)
	if night_drop:
		problems.append("the water dried at night")
	if absf(DissolvingModel.dry_days() - 2.25) > 1e-9 or tray.clock.nights() != 2 or absf(tray.clock.days - 2.25) > 1e-6:
		problems.append("dry after %.3f days, %d nights" % [tray.clock.days, tray.clock.nights()])
	expect.call(problems.is_empty(), "dissolving textbook: solubility 35.9 g / 100 g (a spoonful all dissolves, 100 g leaves %.1f g), the weight the same before and after, seawater 3.5 %% leaves 35 g (none lost), the crust only in the last tenth of the water, 6 mm a sunny day and none at night: dry in %.2f days (two nights)" \
			% [100.0 - DissolvingModel.dissolvable(100.0, 200.0), DissolvingModel.dry_days()],
		"; ".join(problems))


# --- the clock and the sign -----------------------------------------------------------------------

func check_clock() -> void:
	var problems := []
	var c := FastClock.new()
	c.day_s = 4.0
	if c.advance(1.0) != 0.0 or c.locks_conditions() or c.running:
		problems.append("ran before start")
	c.start()
	c.advance(1.0)
	if absf(c.days - 0.25) > 1e-9 or absf(c.share() - 0.25) > 1e-9 or c.nights() != 0 or c.is_night() or c.night() != 0.0 or not c.locks_conditions():
		problems.append("a quarter day: %.3f days, share %.3f, night %.2f" % [c.days, c.share(), c.night()])
	c.advance(1.5)
	if not c.is_night() or c.night() < 0.99:
		problems.append("at 0.625 days: not night (%.2f)" % c.night())
	c.stop()
	c.advance(5.0)
	if absf(c.days - 0.625) > 1e-9:
		problems.append("ran while stopped")
	c.start()
	c.advance(1.5)
	if c.nights() != 1 or absf(c.share()) > 1e-6 or c.night() > 0.01:
		problems.append("the next morning: %d nights, share %.3f, night %.2f" % [c.nights(), c.share(), c.night()])
	c.until = 1.5
	c.advance(10.0)
	if c.running or absf(c.days - 1.5) > 1e-9:
		problems.append("did not stop at until: %.3f" % c.days)
	c.start()
	if c.running:
		problems.append("started past until")
	c.reset()
	if c.days != 0.0 or c.running or c.locks_conditions() or c.until != INF:
		problems.append("reset")
	if absf(FastClock.sunshine(0.0, 2.25) - 1.25) > 1e-9 or absf(FastClock.sunshine(0.5, 1.0)) > 1e-9 or absf(FastClock.days_for_sunshine(1.25) - 2.25) > 1e-9:
		problems.append("sunshine %.3f, %.3f, %.3f" % [FastClock.sunshine(0.0, 2.25), FastClock.sunshine(0.5, 1.0), FastClock.days_for_sunshine(1.25)])
	expect.call(problems.is_empty(), "fast clock: still until start, a day is a sweep from the sun to the moon (night in its right half, a night gone at the moon end), stop holds it, until stops it, the conditions locked until reset, sunshine only by day",
		"; ".join(problems))


## The sign: the marker from the sun end to the moon end, the lamp while the time runs, a moon stamp a
## night (at most STAMPS_MAX); 물의 여행's sign is drawn with the same frame and face (one colour).
func check_time_sign() -> void:
	var sign := TimeSign.new(1.0)
	tree.root.add_child(sign)
	await tree.process_frame
	var problems := []
	sign.show_time(0.0, 0, false)
	var at_sun := sign.marker.position.x
	sign.show_time(1.0, 2, true)
	var at_moon := sign.marker.position.x
	if not (at_sun < -TimeSign.BAR.x * 0.3 and at_moon > TimeSign.BAR.x * 0.3) or not sign.lamp.visible or not sign.stamps.visible or sign.shown_nights != 2:
		problems.append("marker %.2f -> %.2f, lamp %s, stamps %s" % [at_sun, at_moon, sign.lamp.visible, sign.stamps.visible])
	sign.show_time(0.5, 0, false)
	if absf(sign.marker.position.x) > 1e-6 or sign.lamp.visible or sign.stamps.visible:
		problems.append("the middle: %.3f, lamp %s, stamps %s" % [sign.marker.position.x, sign.lamp.visible, sign.stamps.visible])
	var one := TimeSign.face_mesh(TimeSign.BAR, Color.RED, Color.RED).surface_get_arrays(0)
	var two := TimeSign.face_mesh(TimeSign.BAR, Color.RED, Color.BLUE).surface_get_arrays(0)
	var water: Array = (load("res://experiments/water_cycle/water_cycle_props.gd") as GDScript).call("_sign_face_mesh").surface_get_arrays(0)
	var mine := TimeSign.face_mesh(WaterCycleProps.DAY_BAR, WaterCycleProps.DAY_TRACK, WaterCycleProps.DAY_TRACK).surface_get_arrays(0)
	if (one[Mesh.ARRAY_COLOR] as PackedColorArray).has(Color.BLUE) or not (two[Mesh.ARRAY_COLOR] as PackedColorArray).has(Color.BLUE) or var_to_str(water) != var_to_str(mine):
		problems.append("the faces")
	expect.call(problems.is_empty(), "time sign: the marker goes from the sun end to the moon end, the fast-forward lamp only while the time runs, the moon stamps for the nights; 물의 여행's sign is TimeSign's one-colour face",
		"; ".join(problems))
	sign.queue_free()
	await tree.process_frame


# --- the judging ----------------------------------------------------------------------------------

func check_judging() -> void:
	var definition := _definition()
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	var model := lab.model as DissolvingModel
	# [stage, turns stirred (or -1: poured and stepped `days`), days, hit, missed]
	var cases := [
		[0, 0.0, 0.0, false, false], [0, 1.0, 0.0, false, true], [0, 3.2, 0.0, true, false],
		[1, 1.5, 0.0, false, true], [1, 3.0, 0.0, true, false],
		[2, -1.0, 0.1, false, false], [2, -1.0, 1.0, false, true], [2, -1.0, 3.0, true, false],
	]
	for case: Array in cases:
		var stage := int(case[0])
		lab.set_game_stage(stage, stage, false)
		lab.reset_run()
		if float(case[1]) >= 0.0:
			model.stir(float(case[1]))
		else:
			model.pour()
			_run(model, float(case[2]) * DissolvingModel.DAY_S)
		var status := lab.status()
		var stamps := MissionRound.judge(definition, stage, status, lab, lab.observations())
		var missed := MissionRound.missed(definition, stage, status, lab.observations()) and lab.settled()
		if (stamps == stage + 1) != bool(case[3]) or missed != bool(case[4]):
			problems.append("stage %d %s (%s, settled %s): stamps %d missed %s" % [stage + 1, str(case), status, lab.settled(), stamps, missed])
	lab.set_game_stage(0, 0, false)
	lab.reset_run()
	lab.manipulation_started(DissolvingLab.SPOON_ID)
	model.stir(4.0)
	if lab.settled():
		problems.append("settled while the finger holds the spoon")
	lab.manipulation_placed(DissolvingLab.SPOON_ID, lab.knobs[DissolvingLab.SPOON_ID].global_transform)
	if not lab.settled() or MissionRound.judge(definition, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("not judged after the let-go")
	expect.call(problems.is_empty(), "dissolving judging: the clear glass / the same needle / the salt on the dry tray hit; half stirred and the drying tray say Puppy's lines (after %.1f days); not before stirring or right after the pour; not while the finger holds the spoon" % DissolvingModel.HINT_DAYS,
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- the hand -------------------------------------------------------------------------------------

## A view, a lab and the shell's Manipulator on it.
func _hand(size := VIEW_SIZE) -> Dictionary:
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
	for i in 3:
		await tree.physics_frame
	await tree.process_frame
	return {"host": host, "view": view, "lab": lab, "m": m, "per_unit": Vector2(view.viewport.size) / view.size}


## Round and round over the glass with the shell's finger (either way) stirs it clear and the spoon goes
## round with it; the hand guide goes round the stir middle from the spoon.
func check_stir() -> void:
	var h: Dictionary = await _hand()
	var lab: DissolvingLab = h.lab
	var view: View3D = h.view
	var m: Manipulator = h.m
	var to_view := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / h.per_unit
	var problems := []
	var guide := m.guide()
	var middle := DissolvingProps.stir_center(DissolvingModel.CUP)
	if guide.get("kind", "") != "stir" or guide.get("id", "") != DissolvingLab.SPOON_ID or (guide.get("to", Vector3.INF) as Vector3).distance_to(middle) > 1e-3:
		problems.append("hand guide %s" % str(guide))
	var model := lab.model as DissolvingModel
	var start: Vector2 = to_view.call(lab.knobs[DissolvingLab.SPOON_ID].global_position)
	var centre: Vector2 = to_view.call(middle)
	var arm := start - centre
	m.handle_pointer("press", start)
	if m.mode == "" or lab.holding != DissolvingLab.SPOON_ID:
		problems.append("the spoon not taken (mode '%s')" % m.mode)
	var angles := []
	for way: float in [1.0, -1.0]:
		for k in range(1, 25):
			m.handle_pointer("move", centre + arm.rotated(way * TAU * k / 24.0))
			await tree.process_frame
			angles.append(lab.spoon_angle)
		if way > 0.0 and absf(model.input("stir") - 1.0) > 0.08:
			problems.append("one turn round stirred %.2f" % model.input("stir"))
	m.handle_pointer("release", start)
	await tree.process_frame
	if model.status() != "dissolving" or absf(model.input("stir") - 2.0) > 0.15 or lab.holding != "":
		problems.append("two turns: %s, %.2f stirred" % [model.status(), model.input("stir")])
	var spread := 0.0
	for a: float in angles:
		spread = maxf(spread, absf(wrapf(a - angles[0], -PI, PI)))
	if spread < PI * 0.8 or absf(lab.props.spoon.position.length() - Vector2(DissolvingProps.SPOON_RING, DissolvingProps.SPOON_UP).length()) > 1e-3:
		problems.append("the spoon did not go round (%.2f rad)" % spread)
	m.handle_pointer("press", to_view.call(lab.knobs[DissolvingLab.SPOON_ID].global_position))
	start = to_view.call(lab.knobs[DissolvingLab.SPOON_ID].global_position)
	arm = start - centre
	for k in range(1, 30):
		m.handle_pointer("move", centre + arm.rotated(TAU * k / 24.0))
		await tree.process_frame
	m.handle_pointer("release", centre + arm.rotated(TAU * 29.0 / 24.0))
	await tree.process_frame
	if model.status() != "clear" or not lab.settled() or lab.props.mound.visible or lab.props.shown_haze > 0.01:
		problems.append("stirred on: %s, mound %s, haze %.2f" % [model.status(), lab.props.mound.visible, lab.props.shown_haze])
	expect.call(problems.is_empty(), "dissolving stirring: the shell's finger going round over the glass (either way) stirs a turn a turn and the spoon goes round; stirred on, the salt is gone and the water clear; the hand guide goes round the glass from the spoon",
		"; ".join(problems))
	(h.host as Control).queue_free()
	await tree.process_frame


## On the tray's table the bucket is the object: let go short of the tray it goes back, over the tray
## it tips, pours and the time runs by itself (the lamp on, the scene dark at night, the conditions
## locked) to the dry tray (two moon stamps, the salt and the piece); the hand guide drags it right.
func check_pour() -> void:
	var h: Dictionary = await _hand()
	var lab: DissolvingLab = h.lab
	var view: View3D = h.view
	var m: Manipulator = h.m
	var to_view := func(world: Vector3) -> Vector2: return view.rig.unproject_position(world) / h.per_unit
	lab.set_game_stage(2, 2, false)
	await tree.process_frame
	var problems := []
	var model := lab.model as DissolvingModel
	var props: DissolvingProps = lab.props
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != DissolvingLab.BUCKET_ID or (guide.get("to", Vector3.ZERO) as Vector3).x <= (guide.get("from", Vector3.ZERO) as Vector3).x:
		problems.append("hand guide %s" % str(guide))
	if lab.manipulation_body(DissolvingLab.SPOON_ID) != null:
		problems.append("the spoon takes a finger on the tray's table")
	var home: Vector3 = lab.knobs[DissolvingLab.BUCKET_ID].global_position
	var short := home + Vector3(0.3, 0.0, 0.0)
	m.handle_pointer("press", to_view.call(home))
	m.handle_pointer("move", to_view.call(home.lerp(short, 0.5)))
	m.handle_pointer("move", to_view.call(short))
	m.handle_pointer("release", to_view.call(short))
	await tree.process_frame
	if model.poured() or props.bucket.position.distance_to(DissolvingProps.bucket_home(DissolvingModel.TRAY)) > 1e-3:
		problems.append("let go short of the tray: poured %s, the bucket at %s" % [model.poured(), str(props.bucket.position)])
	var over := Vector3(DissolvingProps.TRAY_AT.x - 0.2, home.y, home.z)
	m.handle_pointer("press", to_view.call(home))
	m.handle_pointer("move", to_view.call(home.lerp(over, 0.5)))
	m.handle_pointer("move", to_view.call(over))
	await tree.process_frame
	if props.shown_tip <= 0.0:
		problems.append("not tipping over the tray")
	m.handle_pointer("release", to_view.call(over))
	await tree.process_frame
	if not model.poured() or not model.clock.running or not props.sign.lamp.visible or not model.clock.locks_conditions() or lab.manipulation_body(DissolvingLab.BUCKET_ID) != null:
		problems.append("over the tray: poured %s, running %s, lamp %s" % [model.poured(), model.clock.running, props.sign.lamp.visible])
	var darkest := 0.0
	var frames := 0
	while model.clock.running and frames < 1200:
		await tree.physics_frame
		frames += 1
		darkest = maxf(darkest, props.shown_night)
	await tree.process_frame
	if model.clock.running or model.status() != "salt" or props.sign.shown_nights != 2 or props.sign.lamp.visible or darkest < 0.99 or props.shown_night > 0.01:
		problems.append("after %d frames: %s, %d stamps, lamp %s, darkest %.2f, now %.2f" % [frames, model.status(), props.sign.shown_nights, props.sign.lamp.visible, darkest, props.shown_night])
	if props.shown_water > 0.0 or props.shown_crust < 1.0 or not props.flakes.visible or props.bucket.position.distance_to(DissolvingProps.bucket_home(DissolvingModel.TRAY)) > 1e-3:
		problems.append("the dry tray: water %.2f, crust %.2f, the bucket at %s" % [props.shown_water, props.shown_crust, str(props.bucket.position)])
	if not lab.settled() or MissionRound.judge(_definition(), 2, lab.status(), lab, lab.observations()) != 3:
		problems.append("the dry tray not judged")
	lab.reset_run()
	if model.clock.locks_conditions() or model.poured() or props.sign.stamps.visible:
		problems.append("다시 kept the time")
	expect.call(problems.is_empty(), "dissolving pour: the bucket let go short of the tray goes back; over the tray it tips, pours and the time runs by itself (the lamp on, the conditions locked, the scene dark at night) to the dry tray with two moon stamps and the salt crust; 다시 starts the time over; the hand guide drags it to the tray",
		"; ".join(problems))
	(h.host as Control).queue_free()
	await tree.process_frame


# --- the tables -----------------------------------------------------------------------------------

func check_tables() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var props: DissolvingProps = lab.props
	var problems := []
	var want := {0: [true, false, true, false], 1: [true, true, false, false], 2: [false, false, true, true]}
	for stage: int in want:
		lab.set_game_stage(stage, stage, false)
		var got := [props.spoon.visible, props.scale_box.visible, props.tray.visible, props.sign.visible]
		if got != want[stage] or not props.bucket.visible or props.cup.position.distance_to(DissolvingProps.cup_point(DissolvingLab.site_of(stage))) > 1e-6:
			problems.append("stage %d: spoon, scale, tray, sign %s" % [stage + 1, str(got)])
	lab.set_game_stage(1, 1, false)
	lab.reset_run()
	(lab.model as DissolvingModel).stir(3.0)
	lab._show()
	if absf(props.shown_needle - props.shown_ghost) > 1e-9 or props.cup.position.y <= KitchenSet.TABLE_TOP + 0.1:
		problems.append("on the scale: needle %.2f, ghost %.2f, the glass at %.2f" % [props.shown_needle, props.shown_ghost, props.cup.position.y])
	lab.set_game_stage(2, 2, true)
	if lab.model.input("site") != DissolvingModel.SCALE:
		problems.append("the cleared stage's table went at once")
	lab.reset_run()
	if lab.model.input("site") != DissolvingModel.TRAY:
		problems.append("the next table did not come with the reset")
	lab.set_game_stage(-1, 3, false)
	if lab.model.input("site") != DissolvingModel.TRAY:
		problems.append("a finished round's table")
	expect.call(problems.is_empty(), "dissolving tables: stage 1 the glass with the spoon, stage 2 on the scale (the needle on its ghost), stage 3 and a finished round the tray, the bucket and the time sign; a stage just cleared keeps its table until the next reset",
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
	if ExperimentRegistry.shown_cards(definition, 0) != ["salt"] or ExperimentRegistry.shown_cards(definition, 1) != ["scale"] or ExperimentRegistry.shown_cards(definition, 2) != ["tray"]:
		problems.append("cards %s / %s / %s" % [str(ExperimentRegistry.shown_cards(definition, 0)), str(ExperimentRegistry.shown_cards(definition, 1)), str(ExperimentRegistry.shown_cards(definition, 2))])
	var model := lab.model as DissolvingModel
	var seen := {}
	var states := [[0, 0.0, -1.0], [0, 1.0, -1.0], [0, 3.0, -1.0], [2, 0.0, -1.0], [2, 0.0, 0.1], [2, 0.0, 1.0], [2, 0.0, 3.0]]
	for s: Array in states:
		lab.set_game_stage(int(s[0]), int(s[0]), false)
		lab.reset_run()
		model.stir(float(s[1]))
		if float(s[2]) >= 0.0:
			model.pour()
			_run(model, float(s[2]) * DissolvingModel.DAY_S)
		var obs := lab.observations()
		for key: String in obs:
			seen[obs[key]] = true
			if not obs[key] is String or str(obs[key]) == "" or digits.search(str(obs[key])) != null:
				problems.append("%s: %s" % [key, str(obs[key])])
	if seen.size() < 8:
		problems.append("only %d different words" % seen.size())
	expect.call(problems.is_empty(), "dissolving: no number on the screen (the observations are words, no units; the card is the salt, the scale on stage 2, the tray on stage 3)",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame


# --- in view --------------------------------------------------------------------------------------

func check_in_view() -> void:
	var problems := []
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
		var props: DissolvingProps = lab.props
		for stage in [0, 1, 2]:
			lab.set_game_stage(stage, stage, false)
			props.cat.advance(0.0)
			var b := props.cat.bounds()
			inside.call(at.call(b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5)), "stage %d the cat's head" % (stage + 1))
			for corner: Vector3 in [Vector3(-props.cup.radius_top, props.cup.height, 0.0), Vector3(props.cup.radius_top, props.cup.height, 0.0), Vector3(0.0, 0.0, 0.0)]:
				inside.call(at.call(props.cup.global_position + corner), "stage %d the glass" % (stage + 1))
			inside.call(at.call(props.bucket.global_position + Vector3.UP * DissolvingProps.BUCKET.z), "stage %d the bucket" % (stage + 1))
			if stage < 2:
				inside.call(at.call(lab.knobs[DissolvingLab.SPOON_ID].global_position), "stage %d the spoon's handle" % (stage + 1))
		lab.set_game_stage(1, 1, false)
		inside.call(at.call(props.scale_box.global_position + DissolvingProps.dial_point()), "the scale's dial")
		lab.set_game_stage(2, 2, false)
		for dx: float in [-0.5, 0.5]:
			inside.call(at.call(DissolvingProps.TRAY_AT + Vector3(dx * DissolvingProps.TRAY_SIZE.x, 0.0, 0.0)), "the tray")
		for dx: float in [-0.5, 0.5]:
			inside.call(at.call(DissolvingProps.SIGN_AT + Vector3(dx * (TimeSign.BAR.x + 0.8), 0.0, 0.0)), "the time sign")
		props.sign.show_time(0.5, 3, true)
		inside.call(at.call(props.sign.global_position + props.sign.lamp.position), "the sign's lamp")
		inside.call(at.call(props.sign.global_position + props.sign.stamps.position), "the moon stamps")
		host.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "dissolving in view: the glass, the spoon's handle, the bread cat's head, the bucket, the scale's dial, the tray and the time sign (its lamp and stamps) between the top band and the bottom %.0f%% (phone, desktop and tablet)" % ((1.0 - BOTTOM_FREE) * 100.0),
		"; ".join(problems.slice(0, 6)))


# --- the spot, the pictures, the opening, the piece ------------------------------------------------

func check_spot() -> void:
	var curie := Island.by_id("curie")
	var problems := []
	if str(curie.order[1]) != ID or ExperimentRegistry.find(ID).is_empty():
		problems.append("dissolving is not curie's second spot as an experiment")
	if curie.playable():
		problems.append("the island opened before all its spots are labs")
	var own := ArtKit.builder()
	MapLandmarks.add(own, ID, Transform3D())
	var other := ArtKit.builder()
	MapLandmarks.add(other, "no-such-spot", Transform3D())
	if own.vertex_count() <= other.vertex_count():
		problems.append("the map shows the unknown spot's ball on a post")
	expect.call(problems.is_empty(), "dissolving: the curie island's second spot is an experiment with its own map landmark (a glass, the salt dish, the bucket); the island stays in the making", "; ".join(problems))


func check_pictures() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(190.0, 100.0)
	tree.root.add_child(canvas)
	var drawn := []
	var kinds := ["salt_gone", "salt_stays"]
	for kind: String in kinds:
		var draw := func() -> void:
			PredictPictures.draw(canvas, kind)
			drawn.append(kind)
		canvas.draw.connect(draw)
		canvas.queue_redraw()
		await tree.process_frame
		canvas.draw.disconnect(draw)
	canvas.queue_free()
	var guide := HandGuide.new()
	guide.size = Vector2(400, 300)
	tree.root.add_child(guide)
	guide.play("stir", func() -> Vector2: return Vector2(250, 150), func() -> Vector2: return Vector2(200, 150), 1)
	var far := 0.0
	var gap := 0.0
	for i in 200:
		guide.step(1.0 / 60.0)
		if not guide.playing():
			break
		far = maxf(far, guide.tip.distance_to(Vector2(250, 150)))
		gap = maxf(gap, absf(guide.tip.distance_to(Vector2(200, 150)) - 50.0))
	guide.queue_free()
	expect.call(kinds.all(func(k: String) -> bool: return k in PredictPictures.KINDS) and drawn == kinds and far > 95.0 and gap < 11.0,
		"dissolving pictures: the question's glasses (salt gone / salt stays) are listed and draw; the hand guide's stir goes round its middle (the paw on the circle, across it)",
		"%s, across %.1f, off the circle %.1f" % [str(drawn), far, gap])


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
	Story.enabled = was
	expect.call(told == [["yaongi", "surprised"], ["puppy", "thinking"], ["dugi", "explain"]] and round.phase() == MissionRound.Phase.ASKING,
		"dissolving opening: first visit 야옹이 (surprised), Puppy's clue, Dugi's line, then the question", str(told))


## The piece: in the bucket (hidden) until the pour, then under the tray's water; the last stamp lifts it
## out of the salt and it jumps down in front of the bread cat; a finished spot has no piece.
func check_piece() -> void:
	var lab := _lab()
	tree.root.add_child(lab)
	await tree.process_frame
	var game: DissolvingGame = lab.game
	var problems := []
	await tree.process_frame
	if game.piece_state != "held" or game.piece.visible:
		problems.append("not hidden in the bucket at the start")
	game.show_stage(1, 1, true)
	game.show_stage(2, 2, true)
	lab.set_game_stage(2, 2, false)
	(lab.model as DissolvingModel).pour()
	lab._show()
	for i in int(DissolvingProps.POUR_S * 60.0) + 30:
		await tree.process_frame
	if game.piece_state != "held" or game.piece.visible or game.piece.global_position.distance_to(DissolvingProps.TRAY_AT) > 0.6 or game._lamps_lit != 2:
		problems.append("after the pour: %s at %s, shown %s, lamps %d" % [game.piece_state, str(game.piece.global_position), game.piece.visible, game._lamps_lit])
	_run(lab.model as DissolvingModel, DissolvingModel.dry_days() * DissolvingModel.DAY_S + 0.5)
	lab._show()
	await tree.process_frame
	if not game.piece.visible:
		problems.append("not in the salt on the dry tray")
	game.show_stage(-1, 3, true)
	var frames := 0
	while game.piece_state != "out" and frames < 500:
		await tree.process_frame
		frames += 1
	if game.piece_state != "out" or game.piece.global_position.distance_to(lab.props.cat.global_position) > 2.2:
		problems.append("after the last stamp: %s at %s" % [game.piece_state, str(game.piece.global_position)])
	if not game.take_piece() is Vector3:
		problems.append("not taken")
	expect.call(problems.is_empty(), "dissolving piece: hidden in the bucket (a lamp a stamp), on the tray under the water out of sight after the pour, in the salt on the dry tray, out of the salt at the last stamp and down in front of the bread cat",
		"; ".join(problems))
	lab.queue_free()
	await tree.process_frame
