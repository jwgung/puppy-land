## The talk (2026-11-16 user: first "누르면 넘어가지 말고, 대화를 다 출력시켜주자", then "누르면 완성되게
## 하고, 넘어갈 수도 있게는 해"): untouched it plays to its end; a tap is the quicker way.
## - a tap (a finger or a click; a touch's emulated click is no second step) on the box, the bust or
##   the explanation card: while the page types it shows the page whole at once; for TAP_LOCK_S after
##   that a tap does nothing; then a tap turns the page (past the last: closes); it stays there (it
##   does not reach the view);
## - untouched, a fully shown page stays DialogueBox.READ_S + READ_PER_CHAR_S per character, then the
##   next page comes; after the last the box closes (`closed`) once; a longer page stays longer;
## - a held question (`hold`) turns its earlier pages and waits on its last (a tap does not close it);
## - the story's and the voyage's screens: a tap anywhere is the same tap; untouched they go on;
##   건너뛰기 still ends them.
## (The 3D view, Puppy's clue shield and the map's riddle: tests/kid_flow_checks.gd; the card in a lab:
## tests/explain_picture_checks.gd.)
extends RefCounted

const Reading := preload("res://tests/dialogue_reading.gd")

var tree: SceneTree
var expect: Callable
const UI_THEME := "res://scripts/app/ui_theme.gd"
const HOME_SCREEN := "res://scripts/app/island_home_screen.gd"
const TABLET := Vector2(1152, 720)
const LONG := "퍼피랜드에는 섬이 많아. 그중 하나가 우리 뉴턴섬이야. 밤마다 길잡이 별이 바다를 비춰 줘. 배들이 길을 잃지 않게! 그런데 어느 밤, 별이 산산조각 나 버렸어. 조각들은 섬 곳곳으로 흩어졌지."


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var store := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH   # the checks delete the store: never the child's
	await check_taps()
	await check_read_time()
	await check_hold()
	await check_story_screen()
	await check_voyage_screen()
	ProgressStore.reset_all()   # (the voyage's end made the next island the one in use)
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.path = store


func _box(words: String) -> DialogueBox:
	var box := DialogueBox.new(words)
	box.set_process(false)   # the checks step its clock
	tree.root.add_child(box)
	box.layout(Rect2(Vector2.ZERO, TABLET), TABLET.x - 200.0, 16.0)
	box.visible = true   # (the screens show it once laid out)
	return box


func _presses(at: Vector2) -> Array:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = at
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = at
	var emulated := click.duplicate()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	return [touch, click, emulated]


## Taps on the box, the bust and the card (a touch, a click; a touch's emulated click is not a second
## step): while the page types a tap shows it whole at once; within TAP_LOCK_S after that a tap does
## nothing; after it a tap turns the page, and past the last page closes the box. Each tap is taken
## there (the view behind never sees it).
func check_taps() -> void:
	var problems := []
	for where in ["box", "bust", "card"]:
		var box := _box(LONG)
		box.open(LONG, "", "axis")
		var r := box.rects()
		var at: Vector2 = {"box": r[0].get_center() - box.position, "bust": r[1].position + r[1].size * Vector2(0.5, 0.8) - box.position,
			"card": box.card.size * 0.5}[where]
		var press := func(kind: int) -> void:
			var event: InputEvent = _presses(at)[kind]
			if where == "card":
				box.card.gui_input.emit(event)
			else:
				box._gui_input(event)
		box.step(0.1)
		press.call(0)   # the finger
		press.call(2)   # its emulated click: no second step
		var whole: bool = box.page == 0 and box.typed() and box.label.visible_characters == -1
		press.call(1)   # at once again: locked
		box.step(DialogueBox.TAP_LOCK_S * 0.5)
		press.call(0)
		var locked: bool = box.page == 0
		box.step(DialogueBox.TAP_LOCK_S * 0.5 + 0.05)
		press.call(1)
		var turned: bool = box.page == 1 and not box.typed()
		# The last page: whole, then (after the lock) closed.
		while box.active and box.page < box.pages().size() - 1:
			Reading.read_page(box)
		press.call(0)
		box.step(DialogueBox.TAP_LOCK_S + 0.05)
		press.call(0)
		var closed: bool = not box.active
		if not (whole and locked and turned and closed):
			problems.append("%s: whole %s, locked %s, turned %s, closed %s" % [where, whole, locked, turned, closed])
		box.queue_free()
	# Taken where the box is drawn (the 3D view behind never sees it): through the real window path.
	var box := _box(LONG)
	box.open(LONG, "", "axis")
	var view := Control.new()
	view.size = TABLET
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	var reached := [0]
	view.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventScreenTouch or e is InputEventMouseButton:
			reached[0] += 1)
	tree.root.add_child(view)
	tree.root.move_child(view, box.get_index())   # under the box
	var root_size := tree.root.size
	tree.root.size = Vector2i(TABLET)
	await tree.process_frame
	for at in [box.rects()[0].get_center(), box.card_rect().get_center()]:
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.position = tree.root.get_final_transform() * at
		tree.root.push_input(touch)
		await tree.process_frame
	var swallowed: bool = reached[0] == 0 and box.typed()
	tree.root.size = root_size
	view.queue_free()
	box.queue_free()
	await tree.process_frame
	expect.call(problems.is_empty() and swallowed,
		"dialogue: a tap (touch or click; its emulated click is no second step) on the box, the bust or the card shows the typing page at once, does nothing for TAP_LOCK_S %.1f s, then turns it (past the last: closes); it never reaches the view behind" % DialogueBox.TAP_LOCK_S,
		"; ".join(problems) + " swallowed %s (view got %d)" % [swallowed, reached[0]])


## A typed page stays READ_S + READ_PER_CHAR_S per character, then turns; past the last the box closes
## (`closed`); a longer page stays longer.
func check_read_time() -> void:
	var box := _box(LONG)
	var closes := [0]
	box.closed.connect(func() -> void: closes[0] += 1)
	box.open()
	var pages := box.pages().size()
	var problems := []
	var times := []
	for k in pages:
		var typing := Reading.type_page(box)
		var want_typing := box.page_length(k) / DialogueBox.CHARS_PER_S
		var want := DialogueBox.READ_S + DialogueBox.READ_PER_CHAR_S * box.page_length(k)
		var read := Reading.read_page(box)
		times.append([box.page_length(k), snappedf(read, 0.01)])
		if absf(typing - want_typing) > 2.0 * Reading.DT or absf(read - want) > 2.0 * Reading.DT:
			problems.append("page %d (%d chars): typed in %.2f s (want %.2f), read %.2f s (want %.2f)" % [k, box.page_length(k), typing, want_typing, read, want])
		if k < pages - 1 and (not box.active or box.page != k + 1):
			problems.append("page %d did not turn to %d" % [k, k + 1])
	if box.active or closes[0] != 1:
		problems.append("not closed once after the last page (active %s, closed %d)" % [box.active, closes[0]])
	box.queue_free()
	# Proportional: a long page stays longer than a short one, by READ_PER_CHAR_S per character.
	var short := _box("짧아.")
	short.open()
	Reading.type_page(short)
	var t_short := Reading.read_page(short)
	var long := _box("이 문장은 저 문장보다 훨씬 길어서 읽는 데 시간이 더 걸려.")
	long.open()
	Reading.type_page(long)
	var t_long := Reading.read_page(long)
	var per_char := (t_long - t_short) / float(long.page_length(0) - short.page_length(0)) if long.page_length(0) != short.page_length(0) else 0.0
	if t_long <= t_short or absf(per_char - DialogueBox.READ_PER_CHAR_S) > 0.01:
		problems.append("not proportional: %.2f s for %d chars, %.2f s for %d chars" % [t_short, short.page_length(0), t_long, long.page_length(0)])
	short.queue_free()
	long.queue_free()
	await tree.process_frame
	expect.call(pages >= 2 and problems.is_empty(),
		"dialogue: untouched, each page types out, stays READ_S %.1f s + READ_PER_CHAR_S %.2f s a character, then turns; past the last it closes once; a longer page stays longer" % [DialogueBox.READ_S, DialogueBox.READ_PER_CHAR_S],
		"; ".join(problems) + " %d pages %s" % [pages, str(times)])


## A held question turns its earlier pages by itself and waits on its last (no ▼ there).
func check_hold() -> void:
	var box := _box(LONG)
	box.hold = true
	box.open()
	var pages := box.pages().size()
	Reading.read_all(box)
	var last := box.page == pages - 1
	for i in 600:
		box.step(0.1)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	box._gui_input(touch)   # a tap does not close it either
	var waits := box.active and box.page == pages - 1 and box.typed() and not box.more.visible
	box.hold = false
	Reading.read_page(box)
	var closes := not box.active
	box.queue_free()
	await tree.process_frame
	expect.call(pages >= 2 and last and waits and closes,
		"dialogue: a held question turns its earlier pages by itself and waits on its last (60 s and a tap, no ▼); let go, it closes",
		"pages %d, reached the last %s, waits %s, closes %s" % [pages, last, waits, closes])


## The story's screen (the prologue): a tap anywhere (its shield) shows the page whole, after
## TAP_LOCK_S the next tap turns it; untouched the pages go on; 건너뛰기 ends it.
func check_story_screen() -> void:
	var was := Story.enabled
	Story.enabled = true
	DirAccess.remove_absolute(ProgressStore.path)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var home: Control = load(HOME_SCREEN).new()
	home.play_prologue_on_open = true
	host.add_child(home)
	for i in 4:
		await tree.process_frame
	var story: StoryDirector = home.story
	var box: DialogueBox = story.dialogue
	var started: bool = story.cinematic() and box.active and story.page == 0
	var words := box.text
	for event: InputEvent in _presses(Vector2(40.0, 200.0)):
		story._on_shield_input(event)
	var kept: bool = box.active and story.page == 0 and box.text == words and box.typed()
	box.step(DialogueBox.TAP_LOCK_S + 0.05)
	story._on_shield_input(_presses(Vector2(40.0, 200.0))[0])
	for i in 20:
		story.advance(0.05)
	var tapped: bool = story.page == 1
	words = box.text
	Reading.read_page(box)
	for i in 20:
		story.advance(0.05)
	var turned: bool = tapped and (story.page == 2 or box.text != words)
	story.skip_button.pressed.emit()
	await tree.process_frame
	var skipped: bool = not story.busy() and Story.prologue_seen() and not box.active
	host.queue_free()
	await tree.process_frame
	Story.enabled = was
	expect.call(started and kept and turned and skipped,
		"dialogue (story): a tap anywhere shows the page whole, the next one (after TAP_LOCK_S) turns it; untouched the next page comes by itself; 건너뛰기 still ends it",
		"started %s, whole after taps %s, turned by a tap then by time %s, skipped %s" % [started, kept, turned, skipped])


## The voyage's screen: a tap anywhere shows the page whole, after TAP_LOCK_S the next tap turns it;
## untouched the pages go on; 건너뛰기 ends it.
func check_voyage_screen() -> void:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var voyage := VoyageScreen.new("hutton")
	var ended := [""]
	voyage.finished.connect(func(to: String) -> void: ended[0] = to)
	host.add_child(voyage)
	for i in 3:
		await tree.process_frame
	var box: DialogueBox = voyage.dialogue
	var started: bool = box.active and voyage.page == 0
	var words := box.text
	for event: InputEvent in _presses(Vector2(300.0, 200.0)):
		voyage._on_shield_input(event)
	var kept: bool = box.active and voyage.page == 0 and box.text == words and box.typed()
	box.step(DialogueBox.TAP_LOCK_S + 0.05)
	voyage._on_shield_input(_presses(Vector2(300.0, 200.0))[0])
	await tree.process_frame
	var tapped: bool = voyage.page == 1
	Reading.read_page(box)
	await tree.process_frame
	var turned: bool = tapped and voyage.page == 2
	voyage.skip_button.pressed.emit()
	await tree.process_frame
	var skipped: bool = voyage.done and ended[0] == "hutton" and not box.active
	host.queue_free()
	await tree.process_frame
	expect.call(started and kept and turned and skipped,
		"dialogue (voyage): a tap anywhere shows the page whole, the next one (after TAP_LOCK_S) turns it; untouched the next page comes by itself; 건너뛰기 still ends it",
		"started %s, whole after taps %s, turned by a tap then by time %s, skipped %s" % [started, kept, turned, skipped])
