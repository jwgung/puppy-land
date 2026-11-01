## A young child's way through the talk (2026-10-31 user, watching a child play: "뭘 어떻게 눌러야 할지 잘
## 몰라", "대화창도 자꾸 못 넘어감", "설명이 너무 휙 지나감"), through the real input path:
## - a tap anywhere behind Puppy's clue turns its page (the question follows), as a tap on his box does,
## - while Dugi asks, a tap beside the picture buttons makes them hop and the paw taps one; so does
##   waiting NUDGE_S; the question still waits for a pick,
## - a tap on the 3D view while Dugi's box waits turns its page and takes nothing of the lab; a press
##   on the lab's object still takes it,
## - on the map, a tap beside Puppy's riddle (not on a spot) turns its page,
## - the words type slower and Puppy's result line stays longer than before,
## - Dugi tells what the lab is and which force it shows (kid.intro) before his question,
## - a won stage sets the lab up again for the next one (as 다시 does) once Dugi has explained.
extends RefCounted

var tree: SceneTree
var expect: Callable
const UI_THEME := "res://scripts/app/ui_theme.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const HOME_SCREEN := "res://scripts/app/island_home_screen.gd"
const TABLET := Vector2(1152, 720)


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var store := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH   # the checks delete the store: never the child's
	var root_size := tree.root.size
	tree.root.size = Vector2i(TABLET)   # the taps go through the window
	await check_clue_tap_anywhere()
	await check_question_nudge()
	await check_box_tap_on_view()
	await check_map_riddle_tap()
	await check_intro()
	await check_next_stage_reset()
	await check_reason_waits()
	await check_bubble_tail()
	check_pace()
	tree.root.size = root_size
	DirAccess.remove_absolute(ProgressStore.path)
	ProgressStore.path = store


func _open(id: String, keep_store := false) -> Control:
	if not keep_store:
		DirAccess.remove_absolute(ProgressStore.path)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(ExperimentRegistry.find(id))
	host.add_child(screen)
	await _frames(4)
	return screen


func _close(screen: Control) -> void:
	screen.get_parent().queue_free()
	await tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func _tap(at: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.position = at
	press.pressed = true
	tree.root.push_input(press)
	await tree.process_frame
	var lift := InputEventScreenTouch.new()
	lift.position = at
	tree.root.push_input(lift)
	await tree.process_frame


## An empty spot of the view: the upper middle (sky), clear of the title, cards and buttons.
func _empty(screen: Control) -> Vector2:
	return Vector2(screen.view.size.x * 0.62, screen.view.size.y * 0.3)


func check_clue_tap_anywhere() -> void:
	var was := Story.enabled
	Story.enabled = true
	var screen := await _open("projectile")
	var r: MissionRound = screen.mission_round
	var box: DialogueBox = screen.dialogue
	var clue_up: bool = box.active and box.speaker == "puppy" and r.clue_open()
	for i in 4:
		if box.speaker != "puppy":
			break
		await _tap(_empty(screen))
	await _frames(3)
	var intro_up: bool = box.active and box.speaker == "dugi" and box.text == MissionRound.intro(screen.definition.raw)[0]
	for i in 6:
		if r.phase() == MissionRound.Phase.ASKING:
			break
		await _tap(_empty(screen))
	await _frames(3)
	var asked: bool = box.active and box.speaker == "dugi" and r.phase() == MissionRound.Phase.ASKING
	expect.call(clue_up and intro_up and asked, "kid flow: a tap anywhere behind Puppy's clue turns it, Dugi's introduction follows (turned the same way), then his question",
		"clue %s, intro %s, then asking %s (%s)" % [clue_up, intro_up, asked, box.speaker])
	await _close(screen)
	Story.enabled = was


func check_question_nudge() -> void:
	var screen := await _open("projectile")
	var r: MissionRound = screen.mission_round
	await _frames(3)
	var before: int = screen.nudges
	await _tap(_empty(screen))
	var tapped: bool = screen.nudges == before + 1 and r.asking() and screen.hand_guide.playing() and screen.hand_guide.kind == "tap"
	var first: Control = screen._choices.get_child(0)
	var on_button: bool = first.get_global_rect().grow(4.0).has_point(screen.view.global_position + screen.hand_guide.tip) \
		or screen.hand_guide.tip.distance_to(screen._choices.position + first.position + first.size * 0.5) < 20.0
	var over: bool = screen.hand_guide.get_index() > screen._choices.get_index()
	# Waiting is a nudge too.
	for i in 30:
		await tree.process_frame
	screen.hand_guide.stop()
	var waited := 0
	for i in roundi((ExperimentScreen.NUDGE_S + 3.0) * 60.0):
		await tree.process_frame
		if screen.nudges > before + 1:
			waited = i
			break
	var picked_none: bool = r.asking() and r.pick == ""
	screen._predict_pick_choice(str(MissionRound.predict(screen.definition.raw).get("answer", "")))
	await _frames(2)
	var back: bool = not screen._nudging and screen.hand_guide.get_index() < screen._tip.get_index() + 3
	expect.call(tapped and on_button and over and waited > 0 and picked_none and back,
		"kid flow: during the question a tap beside the pictures, or waiting %.0f s, makes them hop and the paw taps one (over the dim); the question waits for a pick; the paw goes back after" % ExperimentScreen.NUDGE_S,
		"tap %s, on button %s, over %s, waited %d frames, still asking %s, back %s" % [tapped, on_button, over, waited, picked_none, back])
	await _close(screen)


func check_box_tap_on_view() -> void:
	var screen := await _open("spring")
	var box: DialogueBox = screen.dialogue
	screen._predict_pick_choice(str(MissionRound.predict(screen.definition.raw).get("answer", "")))
	for i in 60:
		await tree.process_frame
		if box.active and box.visible:
			break
	var open: bool = box.active and box.visible and not box.hold
	var lab: Experiment = screen.experiment
	var status := lab.status()
	var turns := 0
	while box.active and turns < 6:
		await _tap(_empty(screen))
		turns += 1
	var closed: bool = not box.active and screen.manipulator.mode == "" and lab.status() == status and screen._tap_catcher.taps == turns
	expect.call(open and closed, "kid flow: a tap on the 3D view turns Dugi's page and closes his box; the lab is not touched",
		"open %s, closed after %d taps %s" % [open, turns, closed])
	await _close(screen)


func check_map_riddle_tap() -> void:
	var was := Story.enabled
	Story.enabled = true
	DirAccess.remove_absolute(ProgressStore.path)
	ProgressStore.set_mark(ProgressStore.STORY, "prologue", true)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var home: IslandHomeScreen = load(HOME_SCREEN).new()
	host.add_child(home)
	await _frames(4)
	var story: StoryDirector = home.story
	story.advance(0.6)
	var open: bool = story.riddle != null and story.riddle.active
	var sea := Vector2(home.size.x * 0.06, home.size.y * 0.5)   # the sea at the left edge: no spot there
	for i in 4:
		if not story.riddle.active:
			break
		home._on_pointer("press", sea)
		home._on_pointer("release", sea)
	expect.call(open and home._spot_at(sea) < 0 and not story.riddle.active and not home._walking,
		"kid flow: on the map a tap beside Puppy's riddle (not on a spot) turns its page", "open %s" % open)
	host.queue_free()
	await tree.process_frame
	Story.enabled = was


## The name each lab's introduction teaches ("이 힘을 마찰력이라고 해요", 2026-10-31 user: "용어를
## 알려는 줘야지").
const INTRO_TERMS := {"buoyancy": "부력", "collision": "작용 반작용", "constraints": "진자",
	"free-fall": "중력", "friction": "마찰력", "incline-friction": "마찰력", "orbit": "중력",
	"projectile": "중력", "pulley": "도르래", "rotation": "받침점", "spring": "탄성력"}


## Every lab has Dugi's introduction (what the lab is, the force it shows, by its name); with the
## story on, a second visit (no clue) still opens on it before the question.
func check_intro() -> void:
	var missing := []
	for definition in ExperimentRegistry.load_all():
		var text: String = MissionRound.intro(definition)[0]
		if definition.has("missions") and (text.length() < 40 or not INTRO_TERMS.get(definition.id, "\n") in text):
			missing.append(definition.id)
	var was := Story.enabled
	Story.enabled = true
	DirAccess.remove_absolute(ProgressStore.path)
	ProgressStore.set_mark(ProgressStore.CLUES, "spring", true)   # the clue was told before
	var screen := await _open("spring", true)
	await _frames(4)
	var box: DialogueBox = screen.dialogue
	var first: bool = box.active and box.speaker == "dugi" and box.text == MissionRound.intro(screen.definition.raw)[0] \
		and screen.mission_round.phase() == MissionRound.Phase.CLUE
	var seen := "%s %s '%s' %s" % [box.active, box.speaker, box.text.left(20), screen.mission_round.phase()]
	await _close(screen)
	Story.enabled = was
	expect.call(missing.is_empty() and first, "kid flow: every game lab has Dugi's introduction; a later visit opens on it before the question",
		"missing %s, opens on it %s (%s)" % [str(missing), first, seen])


## A won stage (its stamp in): after Dugi's explanation the lab is back at its start for the next
## stage; a child who already took the lab again keeps the try.
func check_next_stage_reset() -> void:
	var screen := await _open("free-fall")
	var r: MissionRound = screen.mission_round
	r.end_question()
	var lab: Experiment = screen.experiment
	screen.experiment_action("release")
	for i in 240:
		await tree.process_frame
		if lab.status() == "landed":
			break
	var landed: bool = lab.status() == "landed"
	r.stamp_earned.emit(1)
	var reset_at := -1
	for i in 60 * 8:
		await tree.process_frame
		if screen.dialogue.active:
			screen.dialogue.advance()
			screen.dialogue.advance()
		if lab.status() == "ready":
			reset_at = i
			break
	var once: bool = screen.next_resets == 1
	expect.call(landed and reset_at > roundi(ExperimentScreen.NEXT_WAIT_MIN_S * 60.0) - 2 and once,
		"kid flow: a won stage sets the lab up again (ready) after Dugi has explained, by itself",
		"landed %s, ready after %d frames, resets %d" % [landed, reset_at, screen.next_resets])
	await _close(screen)
	# A child who goes on by herself (here a new drop) before the lab is set up again keeps her try.
	screen = await _open("free-fall")
	r = screen.mission_round
	r.end_question()
	lab = screen.experiment
	screen.experiment_action("release")
	for i in 240:
		await tree.process_frame
		if lab.status() == "landed":
			break
	r.stamp_earned.emit(1)
	await _frames(2)
	screen.experiment_action("release")   # the child's own next try
	for i in 60 * 4:
		await tree.process_frame
		if screen.dialogue.active:
			screen.dialogue.advance()
			screen.dialogue.advance()
	expect.call(screen.next_resets == 0,
		"kid flow: a child's own next try after the stamp cancels setting the lab up again",
		"resets %d, status %s" % [screen.next_resets, lab.status()])
	await _close(screen)
	# Dugi explains a later stage by himself after the cast's delay_s (incline-friction waits 4.5 s): the
	# lab is set up again only after that explanation, never under it (2026-11-01 review).
	screen = await _open("free-fall")
	r = screen.mission_round
	r.end_question()
	lab = screen.experiment
	var cast: IslandCast = screen.cast
	for run in 2:   # the first run has the prediction's reason (Dugi at once); the second is a later stage's
		if run == 1:
			cast.delay_s = ExperimentScreen.NEXT_WAIT_MIN_S + 2.0   # longer than the stamp's flight + the wait
		screen.experiment_action("release")
		for i in 240:
			await tree.process_frame
			if lab.status() == "landed":
				break
		if run == 0:
			for i in 60 * 6:
				await tree.process_frame
				if screen.dialogue.active:
					screen.dialogue.advance()
					screen.dialogue.advance()
			screen.experiment_action("reset")
			await _frames(2)
	cast.rearm()
	var explained := cast.explain_count
	r.stamp_earned.emit(1)
	var explained_at := -1
	var read_at := -1
	reset_at = -1
	for i in 60 * 10:
		await tree.process_frame
		if explained_at < 0 and cast.explain_count > explained:
			explained_at = i
		if screen.dialogue.active:
			if explained_at >= 0:
				read_at = i   # his box with the stage's explanation, read
			screen.dialogue.advance()
			screen.dialogue.advance()
		if lab.status() == "ready":
			reset_at = i
			break
	expect.call(explained_at >= 0 and read_at >= explained_at and reset_at > read_at,
		"kid flow: the lab is set up again after Dugi's own explanation of the stage is read (a long delay_s), not before it",
		"explained at frame %d, read at %d, set up again at %d" % [explained_at, read_at, reset_at])
	await _close(screen)


func check_pace() -> void:
	expect.call(DialogueBox.CHARS_PER_S <= 18.0 and ResultBubble.SHOW_S >= 5.0,
		"kid flow: the words type at most 18 a second and Puppy's result line shows at least 5 s",
		"%.0f/s, %.1f s" % [DialogueBox.CHARS_PER_S, ResultBubble.SHOW_S])


## The prediction's reason after the first result line never cuts the box the child is reading
## (2026-11-01 user: "설명 읽는데 넘어가는 장면"): the open box keeps its words until it is closed, then
## Dugi tells the reason; with the sidebar open it waits for the sidebar and is told in his box.
func check_reason_waits() -> void:
	var reason := ""
	var results := []
	for with_sidebar in [false, true]:
		var screen := await _open("free-fall")
		screen.mission_round.end_question()
		reason = MissionRound.predict(screen.definition.raw).get("reason", "")
		var box: DialogueBox = screen.dialogue
		var cast: IslandCast = screen.cast
		var waiting := false
		if with_sidebar:
			screen.open_sidebar(false)
			await _frames(2)
			screen.show_result(0, false)   # the first result line: the reason is due
			await _frames(60)
			waiting = screen.reason_waits() and not box.active
			screen.close_sidebar(false)
		else:
			cast.dugi.explain(screen.experiment.explain_point)
			for i in 60 * 3:
				await tree.process_frame
				if box.active:
					break
			var reading := box.text
			screen.show_result(0, false)
			await _frames(60)
			waiting = box.active and box.text == reading and screen.reason_waits()
			for i in 6:
				box.advance()
		for i in 60 * 3:
			await tree.process_frame
			if box.active and box.joined() == reason:
				break
		var told: bool = box.active and box.joined() == reason and not screen.reason_waits()
		results.append([with_sidebar, waiting, told])
		await _close(screen)
	var ok := results.all(func(r: Array) -> bool: return r[1] and r[2])
	expect.call(ok, "kid flow: the prediction's reason waits for the box the child is reading (and an open sidebar), then Dugi tells it in his box",
		"[sidebar, waited, told] %s" % str(results))


## Puppy's result bubble beside him points at him from its side, above him from its bottom, below him
## from its top (2026-11-01 user: the tail went the wrong way), and never covers him: in every game lab,
## a win and a miss, on the tablet.
func check_bubble_tail() -> void:
	var problems := []
	var want := ["bottom", "left", "right", "top"]
	var sides := {}
	for definition in ExperimentRegistry.load_all():
		if MissionRound.missions(definition).is_empty():
			continue
		var screen := await _open(definition.id)
		screen.mission_round.end_question()
		for won in [true, false]:
			screen.show_result(0, won)
			for i in 3:
				await tree.process_frame
			var bubble: ResultBubble = screen.result_bubble()
			if bubble == null:
				problems.append("%s: no bubble" % definition.id)
				continue
			var side: int = screen._bubble_side
			sides[side] = true
			if bubble.tail_side() != want[side]:
				problems.append("%s %s: side %d, tail %s" % [definition.id, won, side, bubble.tail_side()])
			var puppy: Rect2 = screen.view_rect_of(screen.cast.puppy.bounds())
			if puppy.grow(-2.0).intersects(bubble.bubble_rect()):
				problems.append("%s %s: the bubble over Puppy (side %d)" % [definition.id, won, side])
		await _close(screen)
	expect.call(problems.is_empty(), "kid flow: Puppy's bubble tail leaves the edge facing him (above, beside, below) and the bubble stays off him, every game lab",
		"; ".join(problems) + " sides used %s" % str(sides.keys()))
