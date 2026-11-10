## The hutton island's finale "해시계 다시 세우기" (#106, 2026-11-09 user decisions): its 9 lines word for
## word (docs/islands/hutton-lines.md, in English too), the broken sundial before it (each wedge found
## fills its own sector of the dial, #114), the new land on the map once the volcano is found, the
## gnomon's piece never flying, the finale itself (the gnomon on the new land, the grass sprouting, the
## filled dial glinting, the child's drag planting the gnomon: a short drag puts it back on
## the cat's paws), then the day, the gnomon's shadow, the emblem's gnomon and face, no star in the sky;
## 건너뛰기 to the same end; once only (the next map is whole). The mechanics finale stays the star's
## (tests/story_checks.gd).
extends RefCounted

var tree: SceneTree
var expect: Callable
const UI_THEME := "res://scripts/app/ui_theme.gd"
const HOME_SCREEN := "res://scripts/app/island_home_screen.gd"
const TABLET := Vector2(1152, 720)
const PHONE := Vector2(1560, 720)
const ISLAND := "hutton"
## docs/islands/hutton-lines.md "끝 이야기 (화산 뒤) — 확정 2026-11-06": [who, face, words].
const FINALE := [
	["fox", "surprised", "바늘이 올라왔어… 이제 조각이 다 모였어!"],
	["puppy", "happy", "해시계한테 가자!"],
	["dugi", "explain", "용암이 바다에서 식어 새 땅이 생겼어요. 땅은 부서지기만 하는 게 아니라, 이렇게 새로 생기기도 해요."],
	["fox", "thinking", "화산이 무섭기만 한 줄 알았는데… 섬을 자라게도 하는구나."],
	["dugi", "explain", "이제 바늘을 꽂아 봐요."],
	["puppy", "surprised", "그림자다! 바늘 그림자가 생겼어!"],
	["fox", "happy", "해가 제자리에 떴어… 섬의 시간이 다시 흘러!"],
	["fox", "happy", "정말 고마워. 너희 덕분이야."],
	["puppy", "happy", "다음에 또 놀러 올게!"],
]


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	var was := Story.enabled
	ProgressStore.path = ProgressStore.TEST_PATH
	ProgressStore.reset_all()
	Island.use_index([])
	Island.set_dev_open(true)
	Island.use_for_run(ISLAND)
	Story.forget_loaded()
	Story.enabled = true
	check_content()
	check_lines_doc()
	await check_before()
	await check_flights()
	await check_finale()
	await check_skip()
	await check_leave_and_help()
	Story.enabled = was
	Island.set_dev_open(false)
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.reset_all()
	ProgressStore.path = saved_path


## The hutton story file's finale: 9 pages, the approved words, speakers and faces; English has 9 too.
func check_content() -> void:
	var got := Story.pages("finale").map(func(p: Dictionary) -> Array: return [p.get("who"), Story.face_or_default(p.get("face")), p.get("text")])
	var en: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/locale/en/story/%s.json" % ISLAND))
	var en_pages: Array = en.get("finale", []) if en is Dictionary else []
	var en_ok := en_pages.size() == FINALE.size() and en_pages.all(func(p: Dictionary) -> bool: return str(p.get("text", "")).length() > 3)
	expect.call(str(got) == str(FINALE) and en_ok and Story.validate(JSON.parse_string(FileAccess.get_file_as_string(Story.content_path(ISLAND)))).is_empty(),
		"hutton finale: the 9 approved lines word for word (speakers, faces), English has all 9, the file is valid", "%s / en %d" % [str(got), en_pages.size()])


## The design doc says the same lines (so the two cannot drift apart).
func check_lines_doc() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../../docs/islands/hutton-lines.md").simplify_path()
	var doc := FileAccess.get_file_as_string(path)
	var missing := FINALE.filter(func(line: Array) -> bool: return not str(line[2]) in doc)
	expect.call(doc != "" and missing.is_empty(), "hutton finale: every line is in docs/islands/hutton-lines.md", "%s %s" % [path, str(missing)])


func _all_stamps() -> Dictionary:
	var store := {}
	for id in Story.spots():
		store[id] = MissionRound.missions(ExperimentRegistry.find(id)).stages.size()
	return store


## The dial's plate mesh covers the first `count` sectors and none of the others: a point in each
## sector's face (half way out, at its middle angle) is inside the mesh's triangles for those only.
func _sectors_filled(dial: SundialDial, count: int) -> bool:
	var faces := dial.plate.mesh.get_faces()
	for i in SundialDial.WEDGES:
		var a := TAU * (i + 0.5) / SundialDial.WEDGES
		var p := Vector2(cos(a), sin(a)) * MapLandmarks.DIAL_RADIUS * 0.45
		var inside := false
		for k in range(0, faces.size(), 3):
			var tri := PackedVector2Array([Vector2(faces[k].x, faces[k].z), Vector2(faces[k + 1].x, faces[k + 1].z), Vector2(faces[k + 2].x, faces[k + 2].z)])
			if Geometry2D.is_point_in_polygon(p, tri):
				inside = true
				break
		if inside != (i < count):
			return false
	return true


## Spots found: the first `count` of the order (as a child finds them), their flights played.
func _found(count: int) -> Dictionary:
	var all := _all_stamps()
	var store := {}
	for id in Story.order().slice(0, count):
		store[id] = all[id]
	return store


## Before the finale: the dial drawn only as far as its wedges were found (a sector each, #114: "원래
## 판에 하나씩 맞춰지게"), no gnomon; no new land before the volcano is found, the new land (grass hidden)
## after.
func check_before() -> void:
	var problems := []
	DirAccess.remove_absolute(ProgressStore.path)
	Story.mark_seen("prologue")
	ProgressStore.save(_found(6))
	var home := await _home(TABLET)
	var dial: SundialDial = home.dial
	if dial == null or dial.whole or dial.filled != 6 or dial.full.visible or not dial.plate.visible or dial.shadow.visible:
		problems.append("6 found: dial %s" % (str([dial.whole, dial.filled]) if dial != null else "none"))
	elif dial.plate.mesh == null or not _sectors_filled(dial, 6):
		problems.append("the plate does not show the 6 found sectors and no more")
	if home.map.new_land or home.new_land_grass != null:
		problems.append("new land before the volcano")
	await _free(home)
	ProgressStore.save(_found(11))
	for id in Story.order():
		ProgressStore.set_mark(ProgressStore.PIECES, id, true)
	ProgressStore.set_mark(ProgressStore.STORY, ProgressStore.island_key(ISLAND, "finale"), true)   # (no finale now: the map as found)
	home = await _home(TABLET)
	if not home.map.new_land or home.new_land_grass == null or not home.new_land_grass.visible:
		problems.append("after the finale: new land %s, grass %s" % [home.map.new_land, home.new_land_grass != null and home.new_land_grass.visible])
	var line: Array = home.map.new_land_line()
	var points: PackedVector2Array = line[0]
	var sea_end := points[points.size() - 1] if not points.is_empty() else Vector2.ZERO
	if points.is_empty() or home.map.coast_fraction(sea_end.x, sea_end.y) < 1.0 or home.map.coast_fraction(points[0].x, points[0].y) > 0.9:
		problems.append("the new land does not run from the volcano into the sea")
	for d in home.map.decorations:
		if not home.map.new_land_clear(Vector2(d[1], d[2]), float(d[3]) * 0.5):
			problems.append("a %s stands on the new land" % d[0])
	if home.dial == null or not home.dial.whole or not home.dial.shadow.visible:
		problems.append("after the finale the sundial is not whole")
	if home.story.sky_star != null or not (home.story.emblem as SundialEmblem).whole:
		problems.append("after the finale: a star in the sky, or the emblem without the gnomon")
	await _free(home)
	expect.call(problems.is_empty(), "hutton finale: before it the dial shows only the found wedges' sectors (6 of 10), no gnomon; no new land before the volcano, the new land from the volcano into the sea after it (nothing on it); after it the dial is whole with its shadow, no star, the emblem's gnomon",
		"; ".join(problems))


## The flights: a wedge flies into its own sector of the dial (one more filled, the piece landing on
## the slot); the gnomon's piece (the volcano's) never flies.
func check_flights() -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	Story.mark_seen("prologue")
	var store := _found(11)
	ProgressStore.save(store)
	var order := Story.order()
	for id in order:
		ProgressStore.set_mark(ProgressStore.PIECES, id, id not in [order[9], order[10]])
	var home := await _home(TABLET)
	var story: StoryDirector = home.story
	var before: int = home.dial.filled
	var landed_at := -1
	var slot_gap := INF
	var open_gap := false   # the gnomon handled (nothing pending) while the finale has not started
	for i in 200:
		story.advance(0.05)
		open_gap = open_gap or (ProgressStore.pending(ProgressStore.PIECES).is_empty() and not story.cinematic())
		await tree.process_frame   # (the map's own frame steps the story too)
		open_gap = open_gap or (ProgressStore.pending(ProgressStore.PIECES).is_empty() and not story.cinematic())
		if not story._flight.is_empty() and story._flight.t > 0.0:
			var slot: Transform3D = home.dial.transform * SundialDial.slot_transform(before)
			slot_gap = minf(slot_gap, (story._flight.node as Node3D).global_position.distance_to(slot.origin))
		if landed_at < 0 and home.dial.filled == before + 1:
			landed_at = story.flights_played
		if story.cinematic():
			break
	var flown := ProgressStore.pending(ProgressStore.PIECES).is_empty()
	expect.call(before == 9 and landed_at == 1 and slot_gap < 0.1 and story.flights_played == 1 and flown and story.cinematic() and not open_gap,
		"hutton finale: the 10th wedge flies into its own sector of the dial (9 -> 10 filled, it comes down on the slot), the gnomon's piece does not fly (one flight), then the finale starts in that same step (no open map in between)",
		"before %d, landed at flight %d, slot gap %.2f, flights %d, flown %s, finale %s, gap %s" % [before, landed_at, slot_gap, story.flights_played, flown, story.cinematic(), open_gap])
	await _free(home)


## The whole finale, page by page.
func check_finale() -> void:
	var problems := []
	DirAccess.remove_absolute(ProgressStore.path)
	Story.mark_seen("prologue")
	ProgressStore.save(_all_stamps())
	var home := await _home(PHONE)
	var story: StoryDirector = home.story
	var rig: CameraRig = home.view.rig
	if not (story.cinematic() and story.part == "finale" and not Story.finale_seen()):
		problems.append("the finale does not start, or is marked seen at its start (%s)" % story.part)
	_advance(story, 0.5)
	var needle_land: bool = story.needle != null and home.map.new_land \
		and story.needle.position.distance_to(home.map.new_land_point(StoryDirector.NEEDLE_LAND_AT, 0.0)) < 3.0
	if not needle_land:
		problems.append("the gnomon does not stand on the new land")
	if home.dial.filled != SundialDial.WEDGES or not home.dial.plate.visible:
		problems.append("%d of the dial's wedges in at the start" % home.dial.filled)
	var words := []
	var grass_grew := false
	var glinted := false
	var guide := ""
	var short_kept := false
	var planted := false
	var shadow_grew := false
	var day_after_plant := false
	var emblem_whole := false
	for p in FINALE.size():
		for i in 80:
			if story.dialogue.active and story.page == p:
				break
			story.advance(0.05)
		words.append([story.dialogue.speaker, story.dialogue.face, story.dialogue.text])
		_advance(story, 1.0)
		if p == 3:
			grass_grew = home.new_land_grass != null and home.new_land_grass.visible
		_tap_through(story.dialogue)
		if p == 3:
			# The dial the wedges filled glints (no assembly any more, #114): it swells a little and back.
			var swell := 0.0
			for i in 60:
				story.advance(0.05)
				swell = maxf(swell, home.dial.plate.scale.x)
			glinted = swell > 1.02 and home.dial.plate.visible and home.dial.filled == SundialDial.WEDGES and not home.dial.full.visible
		if p == StoryDirector.PLANT_PAGE:
			_advance(story, 1.0)
			guide = story.launch_guide.kind if story.launch_guide != null else ""
			var waits := story.plant_waits and story.needle != null and story.plants == 0
			# A short drag: the gnomon goes back over the paws, nothing planted, the paw shows it again.
			var paws: Vector2 = home._world_to_screen(story._needle_point())
			var dial_at: Vector2 = home._world_to_screen(story._dial_top())
			_drag(story, paws, paws.lerp(dial_at, 0.3))
			_advance(story, 0.6)
			short_kept = waits and story.plants == 0 and story.plant_waits and story.launch_guide.kind == "drag" \
				and story.needle.position.distance_to(story._needle_held_xf().origin) < 0.05
			var night_before: float = story.night
			_drag(story, paws, paws.lerp(dial_at, 1.0))
			_advance(story, 0.5)
			planted = story.plants == 1 and not story.plant_waits and story.needle == null and home.dial.whole and night_before > 0.0
			_advance(story, 0.6)
			shadow_grew = home.dial.shadow.visible
			_advance(story, 2.5)
			day_after_plant = story.night == 0.0
			emblem_whole = (story.emblem as SundialEmblem).whole
	_advance(story, 4.0)
	await tree.process_frame
	if str(words) != str(FINALE):
		problems.append("words %s" % str(words))
	if not grass_grew:
		problems.append("no grass sprouting at line 4")
	if not glinted:
		problems.append("the filled dial did not glint before the plant")
	if guide != "drag" or not short_kept:
		problems.append("the plant: guide %s, short drag kept %s" % [guide, short_kept])
	if not (planted and shadow_grew and day_after_plant and emblem_whole):
		problems.append("planted %s, shadow %s, day %s, emblem %s" % [planted, shadow_grew, day_after_plant, emblem_whole])
	if story.busy() or story.sky_star != null or not home.dial.whole or not home.dial.shadow.visible or story.night != 0.0 \
			or not home.new_land_grass.visible or not rig.is_processing():
		problems.append("the end: busy %s, sky star %s, whole %s, night %.2f" % [story.busy(), story.sky_star != null, home.dial.whole, story.night])
	if not home.find_child("MapButtons", true, false).visible:
		problems.append("the map buttons do not come back")
	if not Story.finale_seen():
		problems.append("not marked seen at its end")
	await _free(home)
	# Once: the next map plays nothing and is whole.
	home = await _home(PHONE)
	if home.story.busy() or not home.dial.whole or home.story.sky_star != null or not (home.story.emblem as SundialEmblem).whole:
		problems.append("the next map: busy %s, whole %s" % [home.story.busy(), home.dial.whole])
	await _free(home)
	expect.call(problems.is_empty(), "hutton finale: the gnomon on the new land, the 9 lines in order, the grass sprouts, the wedges fly into their places, the child's drag plants the gnomon (a short drag puts it back), then the day, the shadow and the emblem's gnomon and face; no star; the map is the child's again; once only",
		"; ".join(problems))


## 건너뛰기 in the middle (while the child should plant): the end state at once.
func check_skip() -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	Story.mark_seen("prologue")
	ProgressStore.save(_all_stamps())
	var home := await _home(TABLET)
	var story: StoryDirector = home.story
	for i in 400:
		if story.plant_waits:
			break
		story.advance(0.05)
		if story.dialogue.active:
			_tap_through(story.dialogue)
	var waited := story.plant_waits
	story.skip()
	await tree.process_frame
	var ok: bool = waited and not story.busy() and story.needle == null and home.dial.whole \
		and home.dial.shadow.visible and story.night == 0.0 and story.sky_star == null and (story.emblem as SundialEmblem).whole \
		and home.new_land_grass.visible and Story.finale_seen()
	expect.call(ok, "hutton finale: 건너뛰기 while it waits for the plant ends it as played (whole dial and shadow, day, grass, emblem; no star)",
		"waited %s, busy %s, whole %s" % [waited, story.busy(), home.dial.whole])
	await _free(home)


## #108 (2026-11-09 user): left half way (the map freed while it waits for the plant: Android back, the
## app closed), the finale is not seen and plays again from the start on the next map; there, 3 drags
## let go short of the dial help the child: a drag of 30 % of the way (short of PLANT_SHARE) then plants.
func check_leave_and_help() -> void:
	var problems := []
	DirAccess.remove_absolute(ProgressStore.path)
	Story.mark_seen("prologue")
	ProgressStore.save(_all_stamps())
	var home := await _home(TABLET)
	await _until_plant(home.story)
	if not home.story.plant_waits or Story.finale_seen():
		problems.append("first map: waits %s, seen %s" % [home.story.plant_waits, Story.finale_seen()])
	await _free(home)
	home = await _home(TABLET)
	var story: StoryDirector = home.story
	if not (story.cinematic() and story.part == "finale" and story.page <= 0 and home.dial.filled == SundialDial.WEDGES and not home.dial.whole):
		problems.append("left half way, the next map: finale %s page %d, filled %d" % [story.cinematic(), story.page, home.dial.filled])
	await _until_plant(story)
	var paws: Vector2 = home._world_to_screen(story._needle_point())
	var dial_at: Vector2 = home._world_to_screen(story._dial_top())
	for i in StoryDirector.HELP_AFTER_MISSES:
		_drag(story, paws, paws.lerp(dial_at, 0.3))
		_advance(story, 0.6)
	var kept := story.plants == 0 and story.plant_waits and story.helped()
	_drag(story, paws, paws.lerp(dial_at, 0.3))
	_advance(story, 0.6)
	if not kept or story.plants != 1:
		problems.append("help: kept after %d short drags %s, then planted %d" % [StoryDirector.HELP_AFTER_MISSES, kept, story.plants])
	await _free(home)
	expect.call(problems.is_empty(), "hutton finale: left half way it is not seen and plays again from the start; after 3 short drags a short drag plants the gnomon (#108)",
		"; ".join(problems))


func _until_plant(story: StoryDirector) -> void:
	for i in 400:
		if story.plant_waits:
			return
		story.advance(0.05)
		if story.dialogue.active:
			_tap_through(story.dialogue)


# --- helpers ---------------------------------------------------------------------------------------

func _advance(story: StoryDirector, seconds: float) -> void:
	for i in int(round(seconds / 0.05)):
		story.advance(0.05)


func _tap_through(box: DialogueBox) -> void:
	var words := box.text
	for i in 6:
		if not box.active or box.text != words:
			return
		box.advance()


## A finger on the shield: presses at `from`, drags to `to`, lets go.
func _drag(story: StoryDirector, from: Vector2, to: Vector2) -> void:
	for e in [[true, from], [null, from.lerp(to, 0.5)], [null, to], [false, to]]:
		var event: InputEvent
		if e[0] == null:
			event = InputEventScreenDrag.new()
		else:
			event = InputEventScreenTouch.new()
			event.pressed = e[0]
		event.position = e[1]
		story._on_shield_input(event)
		story.advance(0.02)


func _home(size: Vector2) -> Control:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load(HOME_SCREEN).new()
	screen.play_prologue_on_open = false
	host.add_child(screen)
	for i in 4:
		await tree.process_frame
	return screen


func _free(screen: Control) -> void:
	screen.get_parent().queue_free()
	for i in 3:
		await tree.process_frame
