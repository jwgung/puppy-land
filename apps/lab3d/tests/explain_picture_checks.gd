## Dugi's explanation pictures (#73, 2026-11-06 user decisions, ExplainPictures):
## - the field: `picture` (story pages) and say_picture / intro_picture / reason_picture /
##   bridge_picture (a lab's data) name one of ExplainPictures.KINDS; an unknown one is rejected by the
##   registry (and Story.validate), a picture on Puppy's page too; the round hands each line's picture on;
## - DialogueBox: a line with a picture shows its card, every page of that line keeps it, the next line
##   without one and the close take it away; the box's own words keep their picture;
## - in a lab (a stand-in line: no content uses a picture yet) the card stands in the middle of the
##   view, clear of the dialogue box (and the bust and name tag) and of the top chips, on phone,
##   tablet and the zoomed phone; a tap on the card turns the page like a tap on the box (the lab's
##   object under it is not touched) and the card goes with the box;
## - a story page with a picture (a stand-in page) shows its card and the next page's does not; a
##   picture on Puppy's page shows no card (Dugi only, Story.page_picture);
## - each picture draws at 1x and 2x with every shape triangulated, the card has the pictures'
##   aspect, and ExplainPictures draws no text (its source calls only shape-drawing APIs).
extends RefCounted

var tree: SceneTree
var expect: Callable
const UI_THEME := "res://scripts/app/ui_theme.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const HOME_SCREEN := "res://scripts/app/island_home_screen.gd"
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const UiScale := preload("res://tests/ui_scale_checks.gd")   # PHONE_ZOOMED


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	check_field()
	await check_box()
	for size in [PHONE, TABLET, UiScale.PHONE_ZOOMED]:
		await check_lab_card(size)
	await check_story_page()
	await check_draws()
	check_no_text()
	DirAccess.remove_absolute(ProgressStore.path)


## A stand-in lab whose Dugi lines carry pictures (no content has one yet).
static func stand_in() -> Dictionary:
	var definition := ExperimentRegistry.find("projectile").duplicate(true)
	definition.kid.intro_picture = "axis"
	definition.kid.say_picture = "river"
	definition.missions.stages[0].say_picture = "morning_evening"
	definition.predict.bridge_picture = "sea_breeze"
	definition.predict.reason_picture = "river"
	return definition


func check_field() -> void:
	var good := stand_in()
	var valid := ExperimentRegistry.validate(good)
	var bad := stand_in()
	bad.kid.intro_picture = "volcano"
	bad.kid.say_picture = 3
	bad.missions.stages[0].say_picture = "Axis"
	bad.predict.bridge_picture = ""
	bad.predict.reason_picture = "bogus"
	var found := Array(ExperimentRegistry.validate(bad))
	var named := ["kid.intro_picture", "kid.say_picture", "missions.stages[0].say_picture", "predict.bridge_picture", "predict.reason_picture"]
	var missed := named.filter(func(key: String) -> bool: return not found.any(func(p: String) -> bool: return p.begins_with(key)))
	var known: bool = ExplainPictures.KINDS == ["axis", "morning_evening", "sea_breeze", "river"] \
		and ExplainPictures.picture_or_none("axis") == "axis" and ExplainPictures.picture_or_none("bogus") == "" \
		and ExplainPictures.picture_or_none(null) == ""
	expect.call(valid.is_empty() and missed.is_empty() and known,
		"explain pictures: a lab line's picture (kid.say / intro, a stage's say, the reason, the bridge) must be one of the 4 kinds; the registry rejects an unknown one",
		"valid %s; not rejected %s" % [str(valid), str(missed)])
	# Story pages: the island's own content is valid; an unknown picture or one on Puppy's page is not.
	var story := {"prologue": [{"who": "dugi", "face": "explain", "picture": "axis"}, {"who": "puppy", "picture": "river"},
		{"who": "dugi", "picture": "volcano"}], "finale": [{"who": "fox", "face": "happy"}]}
	var problems := Array(Story.validate(story))
	var own := Story.validate(Story._load())
	expect.call(own.is_empty() and problems.size() == 2 and problems.any(func(p: String) -> bool: return p.begins_with("prologue[1].picture"))
		and problems.any(func(p: String) -> bool: return p.begins_with("prologue[2].picture")),
		"explain pictures: a story page's picture must be a known kind and only on Dugi's page; the island's story is valid",
		"own %s, found %s" % [str(own), str(problems)])
	# The round hands each line's picture on.
	var intro := MissionRound.intro(good)
	expect.call(intro.picture == "axis" and MissionRound.intro(ExperimentRegistry.find("projectile")).picture == "",
		"explain pictures: Dugi's introduction carries its picture (none without one)", str(intro))


## The box: the card follows the line.
func check_box() -> void:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var box := DialogueBox.new("Dugi explains.")
	host.add_child(box)
	box.layout(Rect2(Vector2.ZERO, TABLET), TABLET.x - 300.0, 16.0)
	await tree.process_frame
	var steps := []
	var long := "The Earth turns around its axis like a top. It turns once a day. It always turns from the west to the east. That is why the Sun comes up in the east every morning."
	box.open(long, "explain", "axis")
	box.layout(Rect2(Vector2.ZERO, TABLET), TABLET.x - 300.0, 16.0)
	steps.append(box.card.visible and box.picture == "axis")
	var pages := box.pages().size()
	var kept := true
	for k in pages - 1:
		box.advance()   # the whole page
		box.advance()   # the next page
		kept = kept and box.active and box.card.visible
	steps.append(pages > 1 and kept)
	box.open("The next line.")
	steps.append(box.active and not box.card.visible and box.picture == "")
	box.open("A river line.", "", "river")
	steps.append(box.card.visible and box.picture == "river")
	box.open("An unknown picture.", "", "volcano")
	steps.append(not box.card.visible and box.picture == "")
	box.open("A picture again.", "", "sea_breeze")
	box.close(true)
	steps.append(not box.card.visible and box.picture == "")
	box.set_words("Its own words.", "happy", "morning_evening")
	box.open()
	steps.append(box.card.visible and box.picture == "morning_evening")
	box.open("Words for once.")
	steps.append(not box.card.visible)
	box.open()
	steps.append(box.card.visible and box.picture == "morning_evening")
	var sized: bool = box.card.size == DialogueBox.CARD_SIZE
	expect.call(not steps.has(false) and sized,
		"explain pictures: the card shows with its line on every page, goes with the next line (none, or an unknown kind) and the close, comes back with the box's own words",
		str(steps))
	host.queue_free()
	await tree.process_frame


## In a lab: the bridge line (a stand-in with a picture) shows the card in the middle, clear of the
## box and the chips; a tap on the card turns the page; the card goes with the box.
func check_lab_card(size: Vector2) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var root_size := tree.root.size
	tree.root.size = Vector2i(size)   # the taps below go through the window
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(stand_in())
	host.add_child(screen)
	for i in 4:
		await tree.process_frame
	var box: DialogueBox = screen.dialogue
	screen._predict_pick_choice(str(MissionRound.predict(screen.definition.raw).get("answer", "")))
	for i in 90:
		await tree.process_frame
		if box.active and box.visible:
			break
	var name := "phone" if size == PHONE else ("tablet" if size == TABLET else "phone zoomed")
	var shown: bool = box.active and box.visible and box.card.is_visible_in_tree() and box.picture == "sea_breeze"
	var card := box.card_rect()
	var view_rect := Rect2(Vector2.ZERO, screen.view.size)
	var problems := []
	# In the middle: across exactly, up or down a little at most (clear of the chips and the box).
	var off := card.get_center() - view_rect.get_center()
	if not is_zero_approx(off.x) or absf(off.y) > 40.0:
		problems.append("not centered: %s in %s" % [str(card), str(view_rect)])
	if not view_rect.encloses(card):
		problems.append("off the view %s" % str(card))
	var tag := Rect2(box.position + box.name_tag.position, box.name_tag.size)
	for r in box.rects() + [tag]:
		if card.intersects(r):
			problems.append("covers the box %s" % str(r))
	for c: Control in [screen._title_bar, screen._key_row, screen._mission_pill, screen._mission_strip, screen._mission_text, screen._top_buttons, screen._action_row]:
		if c != null and c.visible and card.intersects(c.get_rect()):
			problems.append("covers %s %s" % [c.name, str(c.get_rect())])
	# A tap on the card turns the page like a tap on the box (the lab's object under it is not touched).
	var lab: Experiment = screen.experiment
	var status := lab.status()
	var at: Vector2 = tree.root.get_final_transform() * (screen.view.get_global_transform_with_canvas() * card.get_center())
	var turns := 0
	while box.active and turns < 6:
		await _tap(at)
		turns += 1
	var through: bool = turns <= 3 and not box.active and not box.card.is_visible_in_tree() and lab.status() == status \
		and (screen.manipulator == null or screen.manipulator.mode == "")
	expect.call(shown and problems.is_empty() and through,
		"explain pictures (%s): the line's card stands in the middle of the view, clear of the dialogue box, its bust and name tag and the top chips; a tap on it turns the page and the card goes with the box" % name,
		"shown %s %s; through %s (%d taps)" % [shown, "; ".join(problems), through, turns])
	if size == PHONE:
		# Dugi's explanation of the stage being played carries the stage's picture.
		var say: Dictionary = screen.explain_say()
		expect.call(say.picture == "morning_evening", "explain pictures: Dugi's stage explanation carries its picture", str(say))
	host.queue_free()
	tree.root.size = root_size
	for i in 3:
		await tree.process_frame


## A story page with a picture (stand-in: the prologue's second page, Dugi's) shows its card; the
## next page (Puppy's) has none.
func check_story_page() -> void:
	var was := Story.enabled
	Story.enabled = true
	DirAccess.remove_absolute(ProgressStore.path)
	Story.forget_loaded()
	var content := Story._load().duplicate(true)
	content.prologue[1].picture = "axis"
	content.prologue[2].picture = "river"   # Puppy's page: no card (Dugi only)
	Story._content = content
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
	var seen := []
	var clear := true
	for p in 3:
		for i in 70:
			story.advance(0.05)
		var box: DialogueBox = story.dialogue
		seen.append("%s:%s" % [box.speaker, box.picture if box.card.is_visible_in_tree() else "-"])
		if box.card.is_visible_in_tree():
			var card := box.card_rect()
			for r in box.rects():
				clear = clear and not card.intersects(r)
			for c: Control in [story.emblem, story.skip_button]:
				clear = clear and not (c != null and c.visible and card.intersects(c.get_rect()))
		var words := box.text
		for k in 6:
			if not box.active or box.text != words:
				break
			box.advance()
	expect.call(str(seen) == str(["dugi:-", "dugi:axis", "puppy:-"]) and clear,
		"explain pictures: a story page's picture shows on its card (clear of the box, the emblem and the skip button); Puppy's page with a picture shows none",
		"%s clear %s" % [str(seen), clear])
	host.queue_free()
	await tree.process_frame
	Story.forget_loaded()
	Story.enabled = was
	DirAccess.remove_absolute(ProgressStore.path)


## Every picture at 1x and 2x: drawn, every shape triangulated, the canvas's transform reset.
func check_draws() -> void:
	var problems := []
	for scale in [1.0, 2.0]:
		for kind in ExplainPictures.KINDS:
			var before := ExplainPictures.shapes
			var failed := ExplainPictures.failed
			var card := Control.new()
			card.size = DialogueBox.CARD_SIZE * scale
			card.draw.connect(func() -> void: ExplainPictures.draw_card(card, kind, Rect2(Vector2.ZERO, card.size)))
			tree.root.add_child(card)
			await tree.process_frame
			await tree.process_frame
			var drawn := ExplainPictures.shapes - before
			if drawn < 60 or ExplainPictures.failed != failed:
				problems.append("%s x%d: %d shapes, %d failed" % [kind, scale, drawn, ExplainPictures.failed - failed])
			card.queue_free()
	await tree.process_frame
	var aspect_ok := is_equal_approx(DialogueBox.CARD_SIZE.aspect(), ExplainPictures.ASPECT) and is_equal_approx(ExplainPictures.DESIGN.aspect(), ExplainPictures.ASPECT)
	expect.call(problems.is_empty() and aspect_ok, "explain pictures: each of the 4 pictures draws at 1x and 2x, every shape triangulated; the card has the pictures' aspect",
		"%s aspect %s" % ["; ".join(problems), aspect_ok])


## No letters inside a picture (2026-11-06 user): ExplainPictures's drawing calls are shapes only
## (no draw_string / draw_char / fonts / labels), so a label cannot slip in later unseen.
func check_no_text() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/shell/explain_pictures.gd")
	var allowed := ["draw_polygon", "draw_polyline", "draw_style_box", "draw_set_transform", "draw_set_transform_matrix", "draw_card", "draw_center"]
	var used := {}
	for m in RegEx.create_from_string("\\bdraw_\\w+").search_all(source):
		used[m.get_string()] = true
	var bad: Array = used.keys().filter(func(name: String) -> bool: return not name in allowed)
	for word in ["Font", "Label", "TextServer", "TextLine", "TextParagraph", "RichText", "Locale."]:
		if source.contains(word):
			bad.append(word)
	expect.call(source != "" and used.has("draw_polygon") and bad.is_empty(),
		"explain pictures: no text in a picture (only shape drawing calls, no fonts, labels or words)", str(bad))


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
