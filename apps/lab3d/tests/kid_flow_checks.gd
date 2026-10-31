## A young child's way through the talk (2026-10-31 user, watching a child play: "뭘 어떻게 눌러야 할지 잘
## 몰라", "대화창도 자꾸 못 넘어감", "설명이 너무 휙 지나감"), through the real input path:
## - a tap anywhere behind Puppy's clue turns its page (the question follows), as a tap on his box does,
## - while Dugi asks, a tap beside the picture buttons makes them hop and the paw taps one; so does
##   waiting NUDGE_S; the question still waits for a pick,
## - a tap on the 3D view while Dugi's box waits turns its page and takes nothing of the lab; a press
##   on the lab's object still takes it,
## - on the map, a tap beside Puppy's riddle (not on a spot) turns its page,
## - the words type slower and Puppy's result line stays longer than before.
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
	var root_size := tree.root.size
	tree.root.size = Vector2i(TABLET)   # the taps go through the window
	await check_clue_tap_anywhere()
	await check_question_nudge()
	await check_box_tap_on_view()
	await check_map_riddle_tap()
	check_pace()
	tree.root.size = root_size
	DirAccess.remove_absolute(ProgressStore.path)


func _open(id: String) -> Control:
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
	var asked: bool = box.active and box.speaker == "dugi" and r.phase() == MissionRound.Phase.ASKING
	expect.call(clue_up and asked, "kid flow: a tap anywhere behind Puppy's clue turns it, and Dugi's question follows",
		"clue %s, then asking %s (%s)" % [clue_up, asked, box.speaker])
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


func check_pace() -> void:
	expect.call(DialogueBox.CHARS_PER_S <= 18.0 and ResultBubble.SHOW_S >= 5.0,
		"kid flow: the words type at most 18 a second and Puppy's result line shows at least 5 s",
		"%.0f/s, %.1f s" % [DialogueBox.CHARS_PER_S, ResultBubble.SHOW_S])
