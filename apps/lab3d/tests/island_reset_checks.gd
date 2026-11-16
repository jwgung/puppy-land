## 섬·장소 기록 지우기 (2026-11-16 user): an island's record from the gear on its tag on 섬 고르기, one
## lab's record from the red button at the end of its note; both behind the parental gate and a
## question (ResetConfirm).
## - store: reset_spot erases only that spot's keys (stamps, cleared run, flag, piece, clue, guide),
##   reset_island every spot of the island and its story marks, day limit and map spot; the other
##   islands' and spots' keys, the map's guide, the purchases and the settings stay; the erase times
##   are kept ([reset]); the island in use goes back to the first; an island after it closes again;
## - the gear: on every open island's tag (right of 보호자 when not bought), none on a locked one, clear
##   of the tag's words; nothing is erased without the parental gate (closed, or three wrong answers);
##   the question names the island and, when the next island is open, says it closes; 아니 keeps
##   everything; 지우기 erases and the tags redraw (출발!, the lock);
## - the lab: 이 실험 처음부터 다시 하기, red, at the note's very end under its last card (none in a
##   measurement), narrower than the cards, inside the sheet and the view, clear of 다시; the gate, the question (아니: nothing), 지우기 erases that spot only and the app
##   opens the lab again from its start (no stamps, the clue again);
## - phone, tablet and zoomed phone; the new words: 반말, no numbers.
## Only the test store (ProgressStore.TEST_PATH) and the test settings are written.
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const UiScale := preload("res://tests/ui_scale_checks.gd")   # PHONE_ZOOMED (화면 크기)
const NOW := 1_900_000_000

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	var sound_path := SoundBoard.path
	ProgressStore.path = ProgressStore.TEST_PATH
	SoundBoard.path = SoundBoard.TEST_PATH
	ProgressStore.now_override = NOW
	Island.set_dev_open(false)
	Island.use_index([])
	check_store()
	for setup in [[PHONE, "phone"], [TABLET, "tablet"], [UiScale.PHONE_ZOOMED, "phone zoomed"]]:
		await check_cards(setup[0], setup[1])
		await check_lab(setup[0], setup[1])
	await check_lab_in_app()
	check_words()
	ProgressStore.now_override = 0
	ProgressStore.reset_all()
	DirAccess.remove_absolute(SoundBoard.path)
	SoundBoard.path = sound_path
	ProgressStore.path = saved_path
	Island.forget_current()


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


## The stamps that complete `spot`.
static func _full(spot: String) -> int:
	return MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()


## The first island complete (its story seen), two hutton spots played, the hutton island's story,
## day limit and map spot, the map's guide and the hutton island in use; the sound setting saved.
func _store() -> void:
	ProgressStore.reset_all()
	var store := {}
	for spot in Island.by_id("mechanics").spots():
		store[spot] = _full(spot)
	var hutton: Array = Island.by_id("hutton").spots()
	store[hutton[0]] = _full(hutton[0])
	store[hutton[1]] = 1
	ProgressStore.save(store)
	for spot in [hutton[0], "spring"]:
		ProgressStore.save_cleared(spot, {"x": 1.0})
		ProgressStore.mark_flag_raised(spot)
		ProgressStore.set_mark(ProgressStore.PIECES, spot, true)
		ProgressStore.set_mark(ProgressStore.CLUES, spot, true)
		ProgressStore.set_mark(ProgressStore.GUIDES, spot, true)
	ProgressStore.set_mark(ProgressStore.GUIDES, "map", true)
	for island in ["mechanics", "hutton"]:
		for part in ["prologue", "finale", "voyage", "unlock"]:
			ProgressStore.set_mark(ProgressStore.STORY, ProgressStore.island_key(island, part), true)
		ProgressStore.set_last_spot(island, str(Island.by_id(island).spots()[0]))
	ProgressStore.set_text(ProgressStore.DAY, "hutton.spot", hutton[1])
	ProgressStore.set_text(ProgressStore.DAY, "hutton.date", "2026-11-16")
	Island.set_current("hutton")
	var settings := ConfigFile.new()
	settings.set_value("sound", "sfx_on", false)
	settings.save(SoundBoard.path)


static func _snapshot() -> Dictionary:
	var config := ConfigFile.new()
	config.load(ProgressStore.path)
	var out := {}
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			out["%s/%s" % [section, key]] = config.get_value(section, key)
	return out


## The keys of `before` gone or changed in `after` (and the keys new in it), as "section/key".
static func _changed(before: Dictionary, after: Dictionary) -> Array:
	var out := []
	for key in before:
		if not after.has(key) or after[key] != before[key]:
			out.append(key)
	for key in after:
		if not before.has(key):
			out.append(key)
	out.sort()
	return out


func check_store() -> void:
	var problems := []
	_store()
	var settings := FileAccess.get_file_as_string(SoundBoard.path)
	var before := _snapshot()
	# One spot: only its keys (and its erase time).
	ProgressStore.reset_spot("spring")
	var want := []
	for section in ProgressStore.SPOT_SECTIONS:
		if before.has("%s/spring" % section):
			want.append("%s/spring" % section)
	want.append("reset/spot:spring")
	want.sort()
	var changed := _changed(before, _snapshot())
	if changed != want:
		problems.append("spot: changed %s, not %s" % [changed, want])
	if ProgressStore.erased_at("spot", "spring") != NOW or ProgressStore.spot_has_record("spring") or not ProgressStore.spot_has_record("orbit"):
		problems.append("spot: erase time %d / records" % ProgressStore.erased_at("spot", "spring"))
	if Island.is_open("hutton", ProgressStore.load()) or Island.current_id() != "mechanics":
		problems.append("spot: the hutton island still open (%s) or in use (%s)" % [Island.is_open("hutton", ProgressStore.load()), Island.current_id()])
	# One island: every spot of it, its story, day limit and map spot; the first island's keys and the
	# map's guide stay; the island in use goes back to the first.
	_store()
	before = _snapshot()
	ProgressStore.reset_island("hutton")
	var after := _snapshot()
	var bad := []
	for key: String in _changed(before, after):
		var section := key.get_slice("/", 0)
		var name := key.get_slice("/", 1)
		var spot_key := section in ProgressStore.SPOT_SECTIONS and name in Island.by_id("hutton").spots()
		var island_key := name.begins_with("hutton.") and section in [ProgressStore.STORY, ProgressStore.DAY, ProgressStore.MAP]
		var reset_key := section == ProgressStore.RESET and (name == "island:hutton" or name.trim_prefix("spot:") in Island.by_id("hutton").spots())
		var in_use := key == "map/island"
		if not (spot_key or island_key or reset_key or in_use):
			bad.append(key)
	if not bad.is_empty():
		problems.append("island: other keys changed %s" % [bad])
	if ProgressStore.island_has_record("hutton") or Story.voyage_seen("hutton") or ProgressStore.last_spot("hutton") != "" \
			or ProgressStore.text(ProgressStore.DAY, "hutton.spot") != "" or ProgressStore.current_island() != "" or Island.current_id() != "mechanics":
		problems.append("island: the hutton record stays")
	if not ProgressStore.mark(ProgressStore.GUIDES, "map") or not ProgressStore.mark(ProgressStore.STORY, "finale") or ProgressStore.last_spot("mechanics") == "" \
			or not Island.by_id("mechanics").complete(ProgressStore.load()) or not Island.is_open("hutton", ProgressStore.load()):
		problems.append("island: the first island's record changed")
	if ProgressStore.erased_at("island", "hutton") != NOW or ProgressStore.erased_at("spot", str(Island.by_id("hutton").spots()[0])) != NOW:
		problems.append("island: erase times")
	# The first island erased: the hutton island closes again.
	ProgressStore.reset_island("mechanics")
	if Island.is_open("hutton", ProgressStore.load()) or ProgressStore.island_has_record("mechanics"):
		problems.append("the first island erased: the hutton island open")
	if FileAccess.get_file_as_string(SoundBoard.path) != settings:
		problems.append("the settings changed")
	expect.call(problems.is_empty(), "island reset: a spot's erase takes only its keys; an island's its spots, story, day limit and map spot (the island in use back to the first); the island after it closes; the rest, the map's guide and the settings stay; erase times kept",
		"; ".join(problems))


func _host(size: Vector2) -> Control:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	return host


func _cards(host: Control, focus_id: String) -> IslandCards:
	var cards := IslandCards.new()
	host.add_child(cards)
	await _frames(3)
	cards.focus = cards._index(focus_id)
	cards.focus_x = cards._focus_at(cards.focus)
	cards._place()
	await _frames(3)
	return cards


func _open(host: Node, type: String) -> Array:
	return host.find_children("*", type, true, false).filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())


## The gear: on open islands' tags only; without the parental gate nothing is erased; the question.
func check_cards(size: Vector2, size_name: String) -> void:
	var problems := []
	_store()
	var host := _host(size)
	var cards := await _cards(host, "hutton")
	var view := Rect2(Vector2.ZERO, size)
	for id in Island.ids() + [""]:
		var open: bool = id != "" and Island.is_open(str(id), ProgressStore.load())
		if cards.gears.has(id) != open:
			problems.append("%s: gear %s, open %s" % [id, cards.gears.has(id), open])
	# The tags' corner: in the tag's top right, the gear right of 보호자, clear of the words and buttons.
	for id in ["hutton", "mechanics"]:
		await _focus(cards, id)
		var tag: Rect2 = (cards.cards[id] as Control).get_global_rect()
		var gear: Rect2 = (cards.gears[id] as Control).get_global_rect()
		_inside(problems, "%s gear" % id, gear, tag)
		_inside(problems, "%s tag" % id, tag, view)
		if gear.get_center().x < tag.get_center().x or gear.get_center().y > tag.get_center().y:
			problems.append("%s gear %s not in the tag's top right %s" % [id, gear, tag])
		if gear.size.x < 44.0 or gear.size.y < 44.0:
			problems.append("%s gear %s smaller than a finger" % [id, gear.size])
		if cards.guardians.has(id):
			var guardian: Rect2 = (cards.guardians[id] as Control).get_global_rect()
			if guardian.intersects(gear) or guardian.get_center().x >= gear.get_center().x:
				problems.append("%s 보호자 %s not left of the gear %s" % [id, guardian, gear])
		for part in ["Pieces", "Name", "About", "Go", "Story"]:
			var node := (cards.cards[id] as Control).find_child(part, true, false) as Control
			if node != null and node.get_global_rect().intersects(gear):
				problems.append("%s gear over %s" % [id, part])
	var full := _snapshot()
	# Closed (×) at the gate, or three wrong answers: no question, nothing erased.
	cards.gears["mechanics"].pressed.emit()
	await _frames(1)
	var gates := _open(cards, "ParentalGate")
	if gates.size() != 1 or not _open(cards, "ResetConfirm").is_empty():
		problems.append("the gear: gates %d, questions %d" % [gates.size(), _open(cards, "ResetConfirm").size()])
	else:
		(gates[0] as ParentalGate).close()
	await _frames(1)
	await _fail_gate(cards.open_reset("mechanics"))
	if not _open(cards, "ParentalGate").is_empty() or not _open(cards, "ResetConfirm").is_empty() or _snapshot() != full:
		problems.append("without the gate: a question opened or the store changed")
	# Passed: the question, the island's name, the next island closing; 아니 keeps everything.
	var question := await _passed(cards, cards.open_reset("mechanics"))
	if question == null or question.kind != ResetConfirm.ISLAND or question.name_label.text != IslandCards.island_name("mechanics") \
			or not question.relock_label.visible or _snapshot() != full:
		problems.append("the question: %s" % (question.name_label.text if question != null else "none"))
	else:
		_check_question(problems, question, view)
		question.no_button.pressed.emit()
		await _frames(2)
		if _snapshot() != full or not _open(cards, "ResetConfirm").is_empty():
			problems.append("아니 erased or kept the question")
	# The hutton island: no warning (the island after it is not open).
	question = await _passed(cards, cards.open_reset("hutton"))
	if question == null or question.relock_label.visible:
		problems.append("hutton's question warns of a closing island")
	elif question != null:
		question.close()
	await _frames(1)
	# 지우기: the first island's record goes; its tag says 출발!, the hutton island is locked again.
	question = await _passed(cards, cards.open_reset("mechanics"))
	if question != null:
		question.yes_button.pressed.emit()
	await _frames(4)
	var go: Button = cards.buttons.get("mechanics")
	if ProgressStore.island_has_record("mechanics") or go == null or go.text != Locale.t("islands.go") \
			or cards.buttons.get("hutton") != null or cards.gears.has("hutton") or ProgressStore.erased_at("island", "mechanics") != NOW:
		problems.append("지우기: record %s, go %s, hutton %s" % [ProgressStore.island_has_record("mechanics"), go.text if go != null else "none", cards.buttons.get("hutton")])
	await _focus(cards, "mechanics")
	var tag := (cards.cards["mechanics"] as Control).get_global_rect()
	if not cards.cards["mechanics"].visible or not view.encloses(tag):
		problems.append("the redrawn tag %s off the view" % tag)
	host.queue_free()
	await _frames(1)
	expect.call(problems.is_empty(), "island reset (%s): the gear on open islands' tags (top right, right of 보호자, clear of the words); no gate, no erase; the question names the island and warns when the next one closes; 아니 keeps all; 지우기 erases and the tags redraw" % size_name,
		"; ".join(problems))


func _focus(cards: IslandCards, id: String) -> void:
	cards.focus = cards._index(id)
	cards.focus_x = cards._focus_at(cards.focus)
	cards._place()
	await _frames(2)


## Three wrong answers at `gate` (it closes).
func _fail_gate(gate: ParentalGate) -> void:
	for i in ParentalGate.TRIES:
		gate.field.text = str(gate.answer() + 1)
		gate.submit()
	await _frames(1)


## `gate` passed: the question it opens under `host` (null when none).
func _passed(host: Node, gate: ParentalGate) -> ResetConfirm:
	gate.field.text = str(gate.answer())
	gate.submit()
	await _frames(3)
	var questions := _open(host, "ResetConfirm")
	return questions[0] if questions.size() == 1 else null


## The question inside the view, its buttons inside it and apart.
static func _check_question(problems: Array, question: ResetConfirm, view: Rect2) -> void:
	var r := question.card.get_global_rect()
	_inside(problems, "the question", r, view)
	_inside(problems, "지우기", question.yes_button.get_global_rect(), r)
	_inside(problems, "아니", question.no_button.get_global_rect(), r)
	_inside(problems, "×", question.close_button.get_global_rect(), r)
	if question.yes_button.get_global_rect().intersects(question.no_button.get_global_rect()):
		problems.append("아니 and 지우기 overlap")


## `inner` inside `outer`, or the problem.
static func _inside(problems: Array, what: String, inner: Rect2, outer: Rect2) -> void:
	if not outer.grow(0.5).encloses(inner):
		problems.append("%s %s outside %s" % [what, inner, outer])


func _lab(host: Control, id: String) -> ExperimentScreen:
	var screen := ExperimentScreen.new()
	screen.setup(ExperimentRegistry.find(id))
	screen.measurement = false
	host.add_child(screen)
	await tree.process_frame
	await tree.physics_frame
	await _frames(3)
	return screen


## The lab's button: red at the note's end, inside the sheet and the view, clear of 다시; the gate, the
## question, 아니, then 지우기: this spot only, and record_erased.
func check_lab(size: Vector2, size_name: String) -> void:
	var problems := []
	_store()
	var host := _host(size)
	var view := Rect2(Vector2.ZERO, size)
	var screen := await _lab(host, "spring")
	var button := screen.reset_record_button
	var column: Control = screen._sections.law.get_parent()
	var page: Control = column.get_parent()
	if button == null or button.get_parent() != page or button.get_index() != page.get_child_count() - 1 or column.get_index() != button.get_index() - 1:
		problems.append("no button at the note's end (under its last card)")
	else:
		screen.open_sidebar(false)
		await _frames(2)
		var below := button.get_global_rect().position.y - screen._scroll.get_global_rect().position.y - 200.0
		screen._scroll.scroll_vertical += int(below)   # (scrolled to the button: at the page end it rests at the bottom)
		await _frames(2)
		var r := button.get_global_rect()
		_inside(problems, "the sheet", screen._sidebar.get_global_rect(), view)   # (its end on the screen)
		_inside(problems, "the button", r, view)
		_inside(problems, "the button", r, screen._scroll.get_global_rect())
		if r.size.y < 44.0:
			problems.append("the button %s lower than a finger" % r.size)
		var cards := column.get_global_rect()
		if absf(r.size.x - cards.size.x) > 1.0 or absf(r.get_center().x - cards.get_center().x) > 1.0 or r.position.y < cards.end.y:
			problems.append("the button %s not as wide as the cards, under them %s" % [r, cards])
		if button.theme_type_variation != &"TitleStartButton":
			problems.append("the button is not the red one")
		var again: Button = screen._action_buttons.get("reset")
		if again != null and again.is_visible_in_tree() and again.get_global_rect().intersects(r):
			problems.append("the button over 다시")
		if button.text != Locale.t("screen.reset_record"):
			problems.append("the button says %s" % button.text)
		var full := _snapshot()
		var erased := [0]
		screen.record_erased.connect(func() -> void: erased[0] += 1)
		await _fail_gate(screen.open_reset())
		var question := await _passed(screen, screen.open_reset())
		if question != null and (question.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text).find(Locale.t("reset.title")) < 0 \
				or question.yes_button.text != Locale.t("reset.yes") or question.yes_button.theme_type_variation != &"TitleStartButton"):
			problems.append("the question's title or 다시 하기")
		if question == null or question.kind != ResetConfirm.SPOT or question.target != "spring" or _snapshot() != full:
			problems.append("the question: %s" % (question.target if question != null else "none"))
		else:
			if question.name_label.text != ExperimentRegistry.kid_text(ExperimentRegistry.find("spring"), "place") or question.relock_label.visible:
				problems.append("the question's words")
			_check_question(problems, question, view)
			question.no_button.pressed.emit()
			await _frames(2)
			if _snapshot() != full or erased[0] != 0:
				problems.append("아니 erased")
		question = await _passed(screen, screen.open_reset())
		if question != null:
			question.yes_button.pressed.emit()
		await _frames(3)
		var want := []
		for section in ProgressStore.SPOT_SECTIONS:
			if full.has("%s/spring" % section):
				want.append("%s/spring" % section)
		want.append("reset/spot:spring")
		want.sort()
		var changed := _changed(full, _snapshot())
		if changed != want or erased[0] != 1:
			problems.append("지우기: changed %s, erased %d" % [changed, erased[0]])
	host.queue_free()
	await _frames(1)
	# A measurement has no button.
	host = _host(size)
	screen = ExperimentScreen.new()
	screen.setup(ExperimentRegistry.find("spring"))
	screen.measurement = true
	host.add_child(screen)
	await _frames(3)
	if screen.reset_record_button != null:
		problems.append("a measurement has the button")
	host.queue_free()
	await _frames(1)
	expect.call(problems.is_empty(), "lab reset (%s): 이 실험 처음부터 다시 하기, red at the note's end under its last card (narrower, in the middle, inside the sheet, clear of 다시, none in a measurement); the gate, the question (아니: nothing), 지우기 erases this spot only" % size_name,
		"; ".join(problems))


## In the app: 지우기 opens the lab again from its start (a new screen, no stamps, the clue again).
func check_lab_in_app() -> void:
	var quality_script: GDScript = load("res://scripts/core/quality.gd")
	var saved_args = quality_script.get("_args_cache")
	quality_script.set("_args_cache", PackedStringArray([]))
	_store()
	var problems := []
	var app: Control = load("res://scripts/app/app.gd").new()
	tree.root.add_child(app)
	await _frames(2)
	ProgressStore.path = ProgressStore.TEST_PATH
	Locale.set_language("ko")
	app.show_experiment(ExperimentRegistry.find("spring"))
	await _frames(3)
	var before: ExperimentScreen = app._screen
	var stamped: bool = before.mission_round != null and before.mission_round.stamps > 0
	var question := await _passed(before, before.open_reset())
	if question != null:
		question.yes_button.pressed.emit()
	await _frames(4)
	var after: Control = app._screen
	if not stamped or not after is ExperimentScreen or after == before or (after as ExperimentScreen).definition.id() != "spring":
		problems.append("no new spring screen (stamped before %s)" % stamped)
	elif (after as ExperimentScreen).mission_round == null or (after as ExperimentScreen).mission_round.stamps != 0 \
			or (after as ExperimentScreen).mission_round.stage() != 0 or Story.clue_seen("spring"):
		problems.append("the new screen is not at its start")
	if ProgressStore.stamps(ProgressStore.load(), "orbit") != _full("orbit") or not ProgressStore.mark(ProgressStore.STORY, "finale"):
		problems.append("the other spots or the island's marks changed")
	app.queue_free()
	await _frames(3)
	quality_script.set("_args_cache", saved_args)
	ProgressStore.path = ProgressStore.TEST_PATH
	Locale.set_language("ko")
	TitleScreen.app_may_show = false
	Story.enabled = false
	expect.call(problems.is_empty(), "lab reset in the app: 지우기 opens the lab again from its start (no stamps, its clue again); the other spots and the island's marks stay",
		"; ".join(problems))


## The new words: 반말 (no 해요체) and no numbers (the kid words' rules).
func check_words() -> void:
	var problems := []
	var polite := RegEx.create_from_string("(요|세요)([.!?…,*\\s]|$)")
	var digit := RegEx.create_from_string("[0-9]")
	var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/ko/ui.json"))
	var count := 0
	for key: String in ui:
		if not (key.begins_with("reset.") or key == "screen.reset_record"):
			continue
		count += 1
		var text := str(ui[key])
		if polite.search(text) != null:
			problems.append("%s 해요체: %s" % [key, text])
		if digit.search(text) != null:
			problems.append("%s has a number: %s" % [key, text])
	expect.call(problems.is_empty() and count >= 8, "island reset: the panel's words are 반말 with no numbers (%d texts)" % count, "; ".join(problems))
