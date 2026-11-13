## The island home (Plan G2): the 3D island seen from above, with the 5 zones and their 11 spots.
## A tap on a spot (its landmark or its name label) makes the bread cat hop over, then the experiment
## opens; when all its stamps (3) are collected a flag stands there. One finger dragged on the map
## turns it like the 3D labs (two fingers turn and zoom, View3D). 설정 is not on the map (the
## title has it). The stamps are read once when the map opens (refresh_progress), never per frame.
##
## The home is a Control that owns a View3D (top camera, the map's own island: MapIsland, with
## sea, zone ground, paths and one landmark per spot, MapLandmarks) and the bread cat
## (CatActor) who hops between spots. Spot names are 2D labels projected onto the map
## (the key-card / dialogue pattern: the 3D view under, UI on top). It never touches an
## experiment's physics: the map is its own little world. App.gd builds it the way it built the
## ListScreen (its signals, but 설정: that is on the title only since 2026-11-11).
class_name IslandHomeScreen
extends Control

signal experiment_chosen(definition: Dictionary)
## The map's ← 돌아가기 (top left, #114): App goes back as Android back does (the islands' map or the title).
signal back_requested

var definitions: Array[Dictionary] = []
var view: View3D
var cat: CatActor
var dugi: DugiActor
var _back_nudge: Tween              # ← 돌아가기's nudge (nudge_back), null: none
var puppy: PuppyActor
## The island's keeper (the fox on the hutton island, Island.keeper; null on an island without one):
## the guide walks FOLLOW_LAG ahead of the cat along the way and stands with the trio (#120).
var fox: Node3D
var map: MapIsland
var world: Node3D
var env: WorldEnvironment
## The story "별 조각 찾기" (StoryDirector, only when Story.enabled): the prologue, the found pieces'
## flights to the lookout, the finale, the corner emblem. null in measurements and plain tests.
var story: StoryDirector = null
## The hutton island's sundial dial (#106: SundialDial at the sundial's foot; null without a sundial):
## the found wedges in their sectors before the finale (#114), the whole dial after it. The story moves it.
var dial: SundialDial = null
## The grass on the new land (#106, MapIsland.new_land_grass; null without the new land): shown once the
## finale was seen (the finale lets it sprout).
var new_land_grass: MeshInstance3D = null
## App: play the prologue when the map opens (first launch, or 이야기 다시 보기).
var play_prologue_on_open := false
var _cinematic := false
var _spots: Array[Dictionary] = []   # {id, definition, at (stage top), top, radius, stand, zone, marker}
var _flags: Dictionary = {}          # spot id -> flag root (visible at 3 stamps)
var _walking := false
var _walk_from := Vector3.ZERO
var _walk_to := Vector3.ZERO
var _walk_t := 0.0
var _walk_total := 0.0
var _walk_spot := -1
var _route := PackedVector2Array()   # the way (x, z) from the cat to the spot's stand
var _route_at := PackedFloat32Array()   # its length up to each point
var _walk_last: Dictionary = {}      # actor -> its last position on the ground (its steps)
var _walk_heading: Dictionary = {}   # actor -> its recent velocity (x, z; its facing)
var _fox_side := 1.0               # the side of the way the guide leads on this walk (+1 left, -1 right)
var _walk_step := {}             # actor -> its last walk step (x, z), the guide's easing
## The spot the three stand at (its index; -1: the square). Saved as the store's last spot on arrival.
var rest_spot := -1
var _down := [Vector2.INF, false]    # screen point of the press, cancelled (a drag)
var _last := Vector2.INF             # the pointer's last point while it turns the map
var _progress: Dictionary = {}       # ProgressStore.load(), read on open (refresh_progress)
var _labels_for := Vector2.ZERO      # the view size the spot labels were placed for
var _labels_camera := Transform3D()  # the camera they were placed for
var _label_frames := 0               # frames the labels are placed again (their sizes settle)
## The flag raise (2026-10-28): a spot whose round was completed since the map last showed it
## (ProgressStore.pending_flags) gets its flag raised once: the camera eases over to frame the spot
## (a timed close-up that ends exactly on the child's view), the flag grows out of the ground with a
## bounce, then the camera is the child's again. A tap during it skips it (and opens nothing).
var _raise_queue: Array = []         # spot ids still to raise
var _raising: Dictionary = {}        # {id, flag, t} of the raise playing now
var raised_count := 0                # flag raises played (tests)
## Screenshots (--demo-flag=<id>): that spot's round counts as just completed, in the bench store only.
static var _demo_flag_done := false
## The night map (2026-10-28, with the story only): the map's 단서 button (Puppy's riddle again)
## and the tapped locked spot's shake {tag, t} (map_lit shake_spot / shake_offset).
var clue_button: Button
var _shake: Dictionary = {}
var shakes := 0                      # (tests)
const SHAKE_S := 0.45
const SHAKE_M := 0.08
const PUPPY_TAP_M := 0.7             # m round Puppy (on the square) a tap may be and still hit him

const RAISE_DELAY_S := 0.5           # the map is on screen first (its slide-in, the first heavy frames)
const RAISE_IN_S := 0.8              # the camera eases to the spot
const RAISE_HOLD_S := 1.5            # it stays while the flag rises
const RAISE_OUT_S := 0.8             # and eases back to the child's view
const RAISE_START_S := 0.6           # the flag starts to grow (into the ease-in)
const RAISE_GROW_S := 1.0            # the grow with its bounce
const RAISE_FILL := 0.42             # share of the view height the spot (landmark + flag) takes

const TAP_SLOP := 14.0               # UI units a press may move and still count as a tap
## The walk to a tapped spot (2026-10-29 user request: calmer; the three walk together). The cat
## hops along the dirt paths as they are drawn (route: the shortest way on them, off the stages,
## stepping on and off at the nearest clear point) at WALK_SPEED, the whole walk taking at least
## WALK_MIN_S and at most WALK_MAX_S (a far spot: a little quicker, never a long wait), speeding up
## and slowing down over WALK_RAMP_S at its ends (walk_share). Puppy and Dugi follow in single file on
## the same way (Puppy FOLLOW_LAG m behind, Dugi twice that, FOLLOW_SIDE m off its middle; stepping
## aside when the cat comes their way, never nearer each other than KEEP_APART), each facing where it
## goes with its own hop.
## Taps on spots are ignored until they arrive; then the lab opens.
const WALK_SPEED := 2.5              # m/s along the way
const WALK_MIN_S := 1.5
const WALK_MAX_S := 5.5             # (4.0 before 2026-11-01: the far spots were a dash)
const WALK_RAMP_S := 0.5             # s they speed up at the start and slow down at the end
const ROUTE_JOIN := 0.7              # m: a path's end this near another path joins it
const ROUTE_CLEAR := 0.1             # m a step on or off the paths keeps off a stage's edge
const WALK_IN_PLACE_S := 0.7         # the spot they stand at: a hop in place
const HOP_HEIGHT := 0.16             # m the cat rises on a hop (the followers: their own share)
const HOP_HZ := 2.2                  # hops per second while walking
## Puppy, then Dugi, follow the cat in single file on the path (#114, 2026-11-10 user: side by side they
## walked on the grass; the path is MapIsland.PATH_WIDTH 0.8 m wide): FOLLOW_LAG m behind it along the
## way each (Dugi twice), FOLLOW_SIDE m off its middle (Puppy left, Dugi right: a little life, still on it).
const FOLLOW_LAG := 0.8              # m behind the one ahead along the way
const FOLLOW_SIDE := 0.1             # m off the way's middle (0.34 before #114: off the path)
## The prologue's stroll up from the beach (stroll_home): the followers this far behind the cat (m),
## the share of it over which they step into their row; its state (empty: none).
const STROLL_LAG := 0.9
const STROLL_SETTLE := 0.15
var _stroll := {}                  # {route, at (lengths along it), t, total}
## Two places nearer than this go straight there (a short step on the square); farther, by the paths.
const ROUTE_STRAIGHT_MAX := 1.2
const FOLLOW_HOPS := {"Puppy": [0.33, 0.8], "Dugi": [0.66, 0.65], "Fox": [0.5, 0.7]}   # phase (share of a hop), height share
const FOLLOW_SPEED := 4.0            # m/s a follower may go to keep its place
const KEEP_APART := 0.68             # m: no two of the three nearer than this while walking
const HEADING_RATE := 12.0           # 1/s: how fast an actor's heading follows its steps
const SETTLE_SHARE := 0.2            # the last share of the walk they step into the group's places
const TURN_RATE := 14.0              # 1/s the actors turn towards where they go
## The three on the map at this scale of their lab size (2026-10-29 "캐릭터 크기를 조절하는게 맞을거
## 같다": at lab size the cat, 1.4 m, stood over most landmarks (0.5-1.3 m, the tall ones 1.75-2.55 m)
## and was wider than a path, 0.8 m). At 0.7 the cat is 0.98 m, Dugi 1.16 m, Puppy (his flag) 1.09 m:
## about a landmark's height, a body narrower than the path.
const ACTOR_SCALE := 0.7
## The group at a spot: the cat on its stand, Puppy and Dugi GROUP_BACK m behind it (away from the
## landmark), GROUP_SIDE m to its left and right.
const GROUP_BACK := 0.8
const GROUP_SIDE := 0.42
const SPOT_RADIUS := 2.2             # m: how far a tap may be from a spot and still hit it
const LABEL_FULL_DISTANCE := 34.0    # m: a spot name nearer than this is full size
const LABEL_MIN_SCALE := 0.7          # the smallest a far spot name gets
const LABEL_SHORT_UNITS := 720.0      # the screen's short side the names are sized for (_label_keep)

## The map's island (its zones, square and paths: the labs' worlds read it too, LabWorld).
var island := Island.current()
## Dugi and Puppy wait on the square with the cat (2026-10-27 user requests: they were missing
## from the map; then "why an L shape, why facing different ways"): the three in one row across the
## view like a group photo, the cat in the middle, Puppy on its left, Dugi on its right, TRIO_GAP m
## apart, all three facing the same way: the default camera (+z). They stand still when the map
## turns ("don't turn their bodies with the camera"). The signpost stands outside the row's reach
## (MapIsland: 1.3 m from the square's middle > TRIO_GAP + a body). With a sundial in the square's
## middle the row stands behind it (MapIsland.trio_row), facing it and the view (#114).
const TRIO_GAP := 0.85
const TRIO_YAW := 0.0   # rad about +y from +z: every actor's model faces +z at 0 (BreadCat, labs' cast)


func _ready() -> void:
	# After the CameraRig's _process (priority 0): the names are placed for this frame's camera,
	# not the last one (they trailed the map by a frame while it turned).
	process_priority = 1
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view = View3D.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	view.single_pointer.connect(_on_pointer)

	# The map's own world: environment + the map island (land, sea, landmarks) + the cat + the spots.
	world = Node3D.new()
	world.name = "IslandHome"
	view.set_world(world)
	env = MapIsland.make_environment()
	view.viewport.add_child(env)
	map = MapIsland.new(island)
	var at_start := ProgressStore.load()
	map.new_land = island.gnomon_spot() != "" and island.gnomon_spot() in island.found(at_start)
	var built := map.build(world, island.map_spots())
	if island.has_sundial():
		_add_sundial_dial(at_start)
	cat = CatActor.new(BreadCat.new())
	world.add_child(cat)
	dugi = DugiActor.new()
	puppy = PuppyActor.new()
	world.add_child(dugi)
	world.add_child(puppy)
	if island.keeper == "fox":
		fox = IslandCast.fox_model()
		world.add_child(fox)
	for actor: Node3D in walkers():
		actor.scale = Vector3.ONE * ACTOR_SCALE

	for zone in island.zones:
		for spot in island.zones[zone].spots:
			_add_spot(world, zone, spot[0], built[spot[0]])
	light_spots([])

	view.rig.configure(_map_camera())
	_close_view()
	view.rig.focus_modes = ["three_quarter", "orbit", "front", "top", "side"]   # the flag raise frames the spot from any view
	_demo_flag()
	view.two_finger_pan = true   # one finger turns the map; two move it (and pinch zooms)
	rest_spot = _spot_index(ProgressStore.last_spot(island.id))
	_place_trio(TRIO_YAW)
	refresh_progress()
	_build_map_buttons()
	_layout()
	resized.connect(_layout)
	if Story.enabled:
		story = StoryDirector.new(self)
		add_child(story)
		story.guardian_requested.connect(func() -> void:   # #77: the guardian's check, then the offer
			IslandOffer.open_for_guardian(self, Island.current_id()))
		story.refresh()
		if play_prologue_on_open:
			story.play_prologue()
		elif next_island_waits() and not story.cinematic():
			nudge_back.call_deferred(true)   # (#118: the map opened again while the new island waits)
	if Quality.cmdline_value("demo-story").begins_with("map"):
		get_tree().create_timer(1.5).timeout.connect(_print_spot_points)


## The hutton sundial's dial (#106) at its foot: whole once the island's finale was seen, else the
## wedges already at the square in their sectors (#114; the ones whose flight still waits come later); the
## new land's grass with it, shown after the finale.
func _add_sundial_dial(progress: Dictionary) -> void:
	dial = SundialDial.new()
	dial.position = map.sundial_foot()
	world.add_child(dial)
	var finale := ProgressStore.mark(ProgressStore.STORY, ProgressStore.island_key(island.id, "finale"))
	if finale:
		dial.show_whole()
	else:
		dial.show_filled(placed_wedges(progress))
	if map.new_land:
		new_land_grass = map.new_land_grass()
		new_land_grass.visible = finale
		world.add_child(new_land_grass)


## The sundial wedges at the square now: the found pieces whose flight played (an old save: found),
## past the gnomon's spot (its piece is the gnomon, not a wedge).
func placed_wedges(progress: Dictionary) -> int:
	var flying := ProgressStore.pending(ProgressStore.PIECES)
	var gnomon := island.gnomon_spot()
	var wedges := island.found(progress).filter(func(id: String) -> bool: return id not in flying and id != gnomon)
	return mini(wedges.size(), SundialDial.WEDGES)


## The map's camera definition (CameraRig.configure): a 3/4 view from above by default, then almost
## free (2026-10-27 user decision "거의 제한 없이"): turns all the way round, tilts from straight
## down to almost level (one finger), zooms 2-60 m (pinch) and moves over the ground (two fingers)
## within PAN_RADIUS of the centre, so the island is never lost. Close in like the labs (2026-11-13
## user "지도에서 확대는 왜 여전히 제한되어있나": it stopped at 6 m): the pinch closes in on what is
## under the fingers (CameraRig.zoom_to_point) and the camera keeps out of the landmarks' stages
## (_close_view). The look-at point is TARGET_Y
## above the grass so a close, low camera stays over the hills.
const PITCH_RANGE := [-89.0, -8.0]
const DISTANCE_RANGE := [2.0, 60.0]
const PAN_RADIUS := 15.0
const TARGET_Y := 0.5
## The default distance and PAN_RADIUS are for an island of BASE_RADIUS_X; a wider one gets them that
## many times (both islands 1.3 times since 2026-11-10/11, user: "실험 사이사이 길이 짧아서", "뉴턴
## 섬도 좀 더 크게해줘": the whole island stays in view, the three a little smaller on screen).
const MAP_DISTANCE := 27.0
const BASE_RADIUS_X := 12.8


## How much wider this island is than BASE_RADIUS_X (1 or more).
func island_scale() -> float:
	return maxf(1.0, island.radius_x / BASE_RADIUS_X)


func _map_camera() -> Dictionary:
	return {
		"target": [0.0, TARGET_Y, 0.0],
		"distance": MAP_DISTANCE * island_scale(),
		"distance_range": DISTANCE_RANGE,
		"yaw_range_deg": [-180.0, 180.0],
		"pitch_range_deg": PITCH_RANGE,
		"pan_radius": PAN_RADIUS * island_scale(),
		"pan_ground": true,
		"default_mode": "three_quarter",
		"views": {
			"front": {"yaw_deg": 0.0, "pitch_deg": -55.0},
			"three_quarter": {"yaw_deg": 0.0, "pitch_deg": -55.0},
			"top": {"yaw_deg": 0.0, "pitch_deg": -85.0},
			"side": {"yaw_deg": 90.0, "pitch_deg": -40.0},
			"follow": {"yaw_deg": 0.0, "pitch_deg": -55.0},
		},
	}


## Zooming in like the labs (2026-11-13): toward the point under the fingers, the camera outside every
## landmark's stage (a box of its radius and height round it).
func _close_view() -> void:
	view.rig.zoom_to_point = true
	var boxes := []
	for spot in _spots:
		var r := float(spot.radius)
		if r > 0.0:
			boxes.append(AABB(spot.at - Vector3(r, 0.0, r), Vector3(2.0 * r, maxf(float(spot.top), 0.5), 2.0 * r)))
	view.rig.keep_out_boxes = boxes


## A spot: its node at the landmark's stage (the landmark itself is in the map's one landmark
## mesh, MapLandmarks) and the flag on the stage's edge that stands at all its stamps (3). The
## landmark's middle is what a tap measures against; the cat hops to `stand`, beside it.
func _add_spot(world: Node3D, zone: String, id: String, info: Dictionary) -> void:
	var definition := ExperimentRegistry.find(id)
	var root := Node3D.new()
	root.name = "Spot_%s" % id
	root.position = info.at
	world.add_child(root)
	var flag := Node3D.new()
	flag.name = "Flag"
	flag.visible = false
	flag.position = info.flag - info.at
	var fb := ArtKit.builder()
	MapFlag.build(fb)
	flag.add_child(ArtKit.instance(fb.commit()))
	root.add_child(flag)
	_flags[id] = flag
	_spots.append({"id": id, "definition": definition, "at": info.at, "top": info.top, "radius": info.radius,
		"stand": info.stand, "zone": zone, "marker": root, "tag": int(info.get("tag", 0))})


## The map's own button, 단서 (설정 left it, see below), floating over its top right corner (2026-10-31 user: no top bar,
## the app's name need not show; the bar ran edge to edge and a phone's rounded corners cut it), and
## its ← 돌아가기 alone in the top left (#114: back to the islands' map; worded as that map's own, #116). They keep MAP_EDGE
## units, plus the screen's safe-area inset, from the edges; the story's emblem sits under ←
## (2026-11-11 user: "돌아가기가 생기면서 해시계나 별이 오른쪽으로 밀리거든? 돌아가기 아래로 두자").
## 설정 is on the title only (2026-11-11 user: "지도에 설정 안보여주기로 했잖아.. 홈에서만 보이게 해줘").
const MAP_EDGE := 20.0
const BACK_GAP := 12.0              # between ← and the emblem under it
## ← 돌아가기's nudge while a new island waits (#118): its swell and its beat (s).
const BACK_NUDGE := 1.1
const BACK_NUDGE_S := 1.2


func _build_map_buttons() -> void:
	var row := Ui.hbox(12)
	row.name = "MapButtons"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	clue_button = Ui.button(Locale.t("map.clue"), "", 60)
	clue_button.name = "ClueButton"
	clue_button.visible = false   # the night map shows it (StoryDirector.refresh)
	clue_button.pressed.connect(func() -> void:
		if story != null:
			story.say_riddle())
	row.add_child(clue_button)
	row.minimum_size_changed.connect(_layout)   # its size comes with the theme: placed again then
	var back := Ui.button(Locale.t("islands.back"), "", 60)   # (as the island map's, 2026-11-10 user: "돌아가기로 맞추자")
	back.name = "MapBackButton"
	back.pressed.connect(back_requested.emit)
	add_child(back)
	back.minimum_size_changed.connect(_layout)
	_layout.call_deferred()


func _layout() -> void:
	var row: Control = find_child("MapButtons", true, false)
	if row == null:
		return
	var inset := Ui.safe_insets(self)
	row.size = row.get_combined_minimum_size()
	row.position = Vector2(size.x - row.size.x - MAP_EDGE - inset.right, MAP_EDGE + inset.top)
	var back: Control = find_child("MapBackButton", true, false)
	if back != null:
		back.size = back.get_combined_minimum_size()
		back.position = Vector2(MAP_EDGE + inset.left, MAP_EDGE + inset.top)


## A new island opened and its voyage waits (#118: the first island's finale seen, Story.voyage_due):
## ← 돌아가기 leads to it.
func next_island_waits() -> bool:
	return story != null and Story.voyage_due(ProgressStore.load()) != ""


## ← 돌아가기 swells and shrinks a little (BACK_NUDGE, BACK_NUDGE_S a beat) while `on` (#118: a new
## island waits on 섬 고르기); off: at rest.
func nudge_back(on: bool) -> void:
	var back: Control = find_child("MapBackButton", true, false)
	if back == null:
		return
	if _back_nudge != null:
		_back_nudge.kill()
		_back_nudge = null
	back.scale = Vector2.ONE
	if not on:
		return
	back.pivot_offset = back.get_combined_minimum_size() * 0.5
	_back_nudge = back.create_tween().set_loops()
	_back_nudge.tween_property(back, "scale", Vector2.ONE * BACK_NUDGE, BACK_NUDGE_S * 0.5).set_trans(Tween.TRANS_SINE)
	_back_nudge.tween_property(back, "scale", Vector2.ONE, BACK_NUDGE_S * 0.5).set_trans(Tween.TRANS_SINE)


## ← 돌아가기 nudges now (nudge_back).
func back_nudged() -> bool:
	return _back_nudge != null


## Where the story's corner emblem goes (its top left): under ← (its place even while ← hides in the story).
func emblem_at() -> Vector2:
	var back: Control = find_child("MapBackButton", true, false)
	var inset := Ui.safe_insets(self)
	return Vector2(MAP_EDGE + inset.left, MAP_EDGE + inset.top + (back.get_combined_minimum_size().y + BACK_GAP if back != null else 0.0))


## The stamps of every spot from the store (one file read), and the flags they stand.
func refresh_progress() -> void:
	_progress = ProgressStore.load()
	for spot in _spots:
		_refresh_flag(spot)
	_raise_queue.clear()
	if story != null:
		story.refresh()
	for id in ProgressStore.pending_flags():
		var flag: Node3D = _flags.get(id)
		if flag != null and flag.visible:   # all its stamps: raise it once (else it stays pending)
			flag.visible = false
			_raise_queue.append(id)
	_next_raise()


## Starts the next queued flag raise: the store says "raised" at once (it never replays, even when
## the app is closed during it).
func _next_raise() -> void:
	if not _raising.is_empty() or _raise_queue.is_empty():
		return
	var id: String = _raise_queue.pop_front()
	var spot: Dictionary = {}
	for s in _spots:
		if s.id == id:
			spot = s
	ProgressStore.mark_flag_raised(id)
	var flag: Node3D = _flags[id]
	flag.visible = true
	flag.scale = Vector3(1.0, 0.01, 1.0)
	_raising = {"id": id, "flag": flag, "t": -RAISE_DELAY_S, "framed": false, "spot": spot}
	raised_count += 1


## The camera's timed close-up on the raising spot (ends exactly on the child's view).
func _frame_raise(spot: Dictionary, flag: Node3D) -> void:
	var top: Vector3 = spot.at + Vector3.UP * maxf(float(spot.top), 2.4)
	var box := AABB(spot.at, Vector3.ZERO).expand(flag.global_position + Vector3.UP * 2.4).expand(top)
	box = box.grow(1.0)
	view.rig.focus({"box": box, "fill": RAISE_FILL, "anchor": Vector2(0.5, 0.55),
		"in_s": RAISE_IN_S, "hold_s": RAISE_HOLD_S, "out_s": RAISE_OUT_S})


## The flag's height share at `t` s into its grow: 0 -> past 1 (a bounce) -> 1.
static func raise_height(t: float) -> float:
	var k := clampf(t / RAISE_GROW_S, 0.0, 1.0)
	if k >= 1.0:
		return 1.0
	return maxf(0.01, 1.0 - exp(-5.0 * k) * cos(2.5 * PI * k))


func _step_raise(delta: float) -> void:
	if _raising.is_empty() or _cinematic:   # the prologue first
		return
	var before: float = _raising.t
	_raising.t += minf(delta, 0.05)   # a long frame never skips the grow
	if before < RAISE_START_S and _raising.t >= RAISE_START_S:
		SoundBoard.play(&"flag")   # the flag starts to grow
	var flag: Node3D = _raising.flag
	if _raising.t >= 0.0 and not _raising.framed:
		_raising.framed = true
		_frame_raise(_raising.spot, flag)
	var h := raise_height(_raising.t - RAISE_START_S)
	flag.scale = Vector3(1.0, h, 1.0)   # grows up with its bounce; no sideways squash (it bent the banner)
	if _raising.t >= RAISE_IN_S + RAISE_HOLD_S + RAISE_OUT_S and _raising.framed and not view.rig.is_framing():
		flag.scale = Vector3.ONE
		_raising = {}
		_next_raise()


## Ends every raise now (a tap): flags up, the camera at once on the child's view.
func skip_raise() -> void:
	if _raising.is_empty():
		return
	for id in [_raising.id] + _raise_queue:
		ProgressStore.mark_flag_raised(id)
		var flag: Node3D = _flags[id]
		flag.visible = true
		flag.scale = Vector3.ONE
	_raise_queue.clear()
	_raising = {}
	view.rig.cut_focus()


func raising() -> bool:
	return not _raising.is_empty()


## --demo-flag=<id> (screenshots): the bench store, that spot at all its stamps and its flag pending.
func _demo_flag() -> void:
	var id := Quality.cmdline_value("demo-flag")
	if id == "" or _demo_flag_done or ExperimentRegistry.find(id).is_empty():
		return
	_demo_flag_done = true
	ProgressStore.path = ProgressStore.BENCH_PATH   # never the child's progress
	var store := ProgressStore.load()
	store[id] = MissionRound.missions(ExperimentRegistry.find(id)).get("stages", []).size()
	ProgressStore.save(store)
	ProgressStore.mark_flag_pending(id)


## Screenshots (--demo-story=map...): where each spot and Puppy are on the window (pixels), for taps.
func _print_spot_points() -> void:
	if not is_inside_tree():
		return
	var to_window := get_viewport().get_screen_transform() * view.get_global_transform_with_canvas()
	for spot in _spots:
		var point := _world_to_screen(tap_point(spot))
		if point != Vector2.INF:
			print("[explore] spot %s %d %d" % [spot.id, roundi((to_window * point).x), roundi((to_window * point).y)])
	var at := _world_to_screen(puppy.global_position + Vector3.UP * 0.35)
	if at != Vector2.INF:
		print("[explore] puppy %d %d" % [roundi((to_window * at).x), roundi((to_window * at).y)])


## Back (Android back) on the map: Puppy's open box (a riddle, "not here") closes first. True if it
## did; false: the app goes on to the title (App._go_back).
func handle_back() -> bool:
	return story != null and story.close_riddle()


## The night map's 단서 button shows while a spot is still to find.
func show_clue_button(on: bool) -> void:
	if clue_button != null:
		clue_button.visible = on


## Lights the found spots on the map's night (map_lit lit_mask; by day it changes nothing). The map's
## material is shared with the labs' ground, whose vertices carry no spot tag: they never light.
func light_spots(ids: Array) -> void:
	var mask := 0
	for spot in _spots:
		if spot.id in ids and int(spot.tag) > 0:
			mask |= 1 << (int(spot.tag) - 1)
	MapIsland.material().set_shader_parameter("lit_mask", mask)


## The spots lit now (tests): their ids.
func lit_spots() -> Array:
	var mask := int(MapIsland.material().get_shader_parameter("lit_mask"))
	return _spots.filter(func(spot: Dictionary) -> bool: return int(spot.tag) > 0 and mask & (1 << (int(spot.tag) - 1)) != 0) \
		.map(func(spot: Dictionary) -> String: return spot.id)


## A little side-to-side shake of spot `index`'s stage and landmark (a locked spot tapped).
func shake_spot(index: int) -> void:
	_shake = {"tag": int(_spots[index].tag), "t": 0.0}
	shakes += 1


func _step_shake(delta: float) -> void:
	if _shake.is_empty():
		return
	_shake.t += delta
	var k := clampf(float(_shake.t) / SHAKE_S, 0.0, 1.0)
	var material := MapIsland.material()
	material.set_shader_parameter("shake_spot", _shake.tag if k < 1.0 else 0)
	material.set_shader_parameter("shake_offset", Vector3(sin(float(_shake.t) * 42.0) * SHAKE_M * (1.0 - k), 0.0, 0.0))
	if k >= 1.0:
		_shake = {}


func _exit_tree() -> void:
	# The material is shared with the labs' ground: no light or shake left on it.
	var material := MapIsland.material()
	material.set_shader_parameter("lit_mask", 0)
	material.set_shader_parameter("shake_spot", 0)
	material.set_shader_parameter("shake_offset", Vector3.ZERO)


## The cat's hop, and the 2D spot labels placed over the map when the view size or the camera changed.
func _process(delta: float) -> void:
	if _walking:
		_step_walk(delta)
	_step_stroll(delta)
	_step_raise(delta)
	_step_shake(delta)
	if _cinematic:
		return
	if view != null and view.rig != null and (view.size != _labels_for or view.rig.global_transform != _labels_camera):
		_labels_for = view.size
		_labels_camera = view.rig.global_transform
		_label_frames = 3
	if _label_frames > 0:
		_label_frames -= 1
		_place_labels()
	_fade_labels()


## A spot name over the three fades to LABEL_FADE (2026-10-29: at a yard spot they stand under the
## next spot's name), so they are never hidden; the name is still read and still takes taps.
const LABEL_FADE := 0.3


func _fade_labels() -> void:
	var group := trio_rect()
	for id in _labels:
		var label: Control = _labels[id]
		var a := LABEL_FADE if group.has_area() and label.visible and _label_rect(label).intersects(group) else 1.0
		if not is_equal_approx(label.modulate.a, a):
			label.modulate.a = a


## The screen rect the three (and the keeper) take (their feet to their heads), Rect2() when off screen.
func trio_rect() -> Rect2:
	var out := Rect2()
	var first := true
	for actor: Node3D in walkers():
		for lift in [0.0, 1.1 * ACTOR_SCALE * 1.4]:   # the cat's lab height is 1.4 m (Dugi's head a little above)
			var p := _world_to_screen(actor.position + Vector3.UP * lift)
			if p == Vector2.INF:
				continue
			var r := Rect2(p - Vector2(18.0, 0.0), Vector2(36.0, 0.0))
			out = r if first else out.merge(r)
			first = false
	return out


## Where the three stand: on the square (no spot yet) in a row across the view through the square (island.home) — Puppy
## on the left, the cat in the middle, Dugi on the right — or at the spot they last walked to
## (rest_spot, saved in the store: after a lab they are where they went), in the group's places
## (group_at). They face `yaw` (the camera's: yaw 0 looks along -z from +z), towards the default view.
func _place_trio(yaw: float) -> void:
	for actor: Node3D in walkers():
		if actor == cat and _walking:
			continue
		actor.position = trio_spot(actor)
		actor.rotation.y = yaw


## The story's prologue or finale has the screen: the map's buttons and the spot names hide (the labels are
## placed again when it ends), taps go to the story.
func set_cinematic(on: bool) -> void:
	_cinematic = on
	for name in ["MapButtons", "MapBackButton"]:
		var node: Control = find_child(name, true, false)
		if node != null:
			node.visible = not on
	for id in _labels:
		(_labels[id] as Control).visible = not on and _label_shown(str(id))
	if not on:
		_label_frames = 3


## The three back where they rest (after the story moved the cat).
func reset_trio() -> void:
	_stroll = {}   # (a skipped prologue: the stroll ends where they rest)
	_place_trio(TRIO_YAW)


## The three on the square again, and the store forgets the last spot (the prologue starts there).
func trio_home() -> void:
	_stroll = {}
	rest_spot = -1
	if ProgressStore.last_spot(island.id) != "":
		ProgressStore.set_last_spot(island.id, "")
	_place_trio(TRIO_YAW)


## Where `actor` stands at rest: its place in the row on the square, or in the group at rest_spot.
func trio_spot(actor: Node3D) -> Vector3:
	if rest_spot >= 0:
		return group_at(_spots[rest_spot]).get(actor, _spots[rest_spot].stand)
	var right := Vector2(cos(TRIO_YAW), -sin(TRIO_YAW))
	var place := {puppy: -1.0, cat: 0.0, dugi: 1.0, fox: 2.0} if fox != null else {puppy: -1.0, cat: 0.0, dugi: 1.0}
	var at: Vector2 = map.trio_row() + right * TRIO_GAP * float(place.get(actor, 0.0))
	return Vector3(at.x, map.walk_height(at.x, at.y), at.y)


## The group's places at a spot: {cat: its stand, puppy: a step behind it on its left, dugi: on its
## right}, "facing": the yaw towards the landmark (how they arrive). Where a place would be on another
## spot's stage or in the water (the yard's spots stand close), the next of GROUP_SHAPES that is clear.
func group_at(spot: Dictionary) -> Dictionary:
	var stand := Vector2(spot.stand.x, spot.stand.z)
	var back := stand - Vector2(spot.at.x, spot.at.z)
	back = back.normalized() if back.length() > 0.01 else Vector2(0.0, 1.0)
	var left := Vector2(-back.y, back.x)   # the left of one facing -back (a model faces +z, its left is +x)
	var out := {"facing": atan2(-back.x, -back.y)}
	var places: Array = []
	for shape: Vector2 in GROUP_SHAPES:
		places = [stand + back * shape.x + left * shape.y, stand + back * shape.x - left * shape.y]
		if places.all(func(p: Vector2) -> bool: return _clear_ground(p)):
			break
	out[cat] = Vector3(stand.x, map.walk_height(stand.x, stand.y), stand.y)
	for i in 2:
		var p: Vector2 = places[i]
		out[[puppy, dugi][i]] = Vector3(p.x, map.walk_height(p.x, p.y), p.y)
	if fox != null:   # the guide: beside the group, out past Puppy or Dugi (the first clear)
		var guide: Vector2 = stand + left * FOX_SIDE
		for shape: Vector2 in FOX_SHAPES:
			var p := stand + back * shape.x + left * shape.y
			if _clear_ground(p) and places.all(func(q: Vector2) -> bool: return q.distance_to(p) >= KEEP_APART):
				guide = p
				break
		out[fox] = Vector3(guide.x, map.walk_height(guide.x, guide.y), guide.y)
	return out


## (back, side) m of Puppy's and Dugi's places from the cat's (Dugi mirrored), in the order tried.
const GROUP_SHAPES := [Vector2(GROUP_BACK, GROUP_SIDE), Vector2(0.35, 0.72), Vector2(0.0, 0.8), Vector2(-0.3, 0.8)]
const STAGE_CLEAR := 0.3             # m a group place keeps off a stage's edge
## The keeper's place at a spot (#120): (back, side) m from the cat's, the ones tried in order.
const FOX_SIDE := 1.25
## On the walk the guide heads FOX_LEAD x FOLLOW_LAG ahead of the cat along the way, at FOX_PACE times a
## follower's top speed (it passes the cat at the start).
const FOX_LEAD := 2.0
const FOX_PACE := 1.6
## The share of a new step the guide takes each frame (the rest is its last step): its walk eases.
const FOX_EASE := 0.15
## m to the side of the way the guide walks while it leads (clear of the cat it passes).
const FOX_WIDE := 0.6
const FOX_SHAPES := [Vector2(0.2, FOX_SIDE), Vector2(0.2, -FOX_SIDE), Vector2(GROUP_BACK + 0.6, 0.0), Vector2(-0.4, 1.0), Vector2(-0.4, -1.0)]


## Grass to stand on: not water, inside the beach, off every stage.
func _clear_ground(p: Vector2) -> bool:
	if map.water_at(p.x, p.y) or map.coast_fraction(p.x, p.y) > MapIsland.grass_edge():
		return false
	for other in _spots:
		if float(other.radius) > 0.0 and p.distance_to(Vector2(other.at.x, other.at.z)) < float(other.radius) + STAGE_CLEAR:
			return false
	return true


## The index of the spot `id` (-1: none).
func _spot_index(id: String) -> int:
	for i in _spots.size():
		if _spots[i].id == id:
			return i
	return -1


## Where the trio stands now: [Dugi, cat, Puppy] (tests).
func trio() -> Array:
	return [dugi, cat, puppy]


## Everyone who walks the map: the trio and the island's keeper (fox) when it has one.
func walkers() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for actor: Node3D in [cat, puppy, dugi, fox]:
		if actor != null:
			out.append(actor)
	return out


## The way from `from` to `to` (x, z), on the dirt paths as they are drawn (2026-11-01 user: "지도에서
## 세마리 이동 경로가 좀 어색함": the way ran over the paths' raw corners, through the landmarks the
## paths ended under, past a stand and back): each path smoothed and sampled as MapIsland draws it,
## a path's end joined to the nearest point of every other path it touches, no piece of it under a
## stage. The ends step on at the nearest point of a path whose step crosses no stage, the shortest
## way runs between them, and its joins are smoothed (two Chaikin passes, the ends kept). Ends
## nearer each other than to the paths and than ROUTE_STRAIGHT_MAX (and nothing between them): straight.
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var nodes := PackedVector2Array()
	var links: Array = []   # node index -> neighbour indices
	var add_node := func(p: Vector2) -> int:
		nodes.append(p)
		links.append([])
		return nodes.size() - 1
	var join := func(i: int, k: int) -> void:
		if not _crosses_stage(nodes[i], nodes[k], 0.0):
			links[i].append(k)
			links[k].append(i)
	var lines: Array = []
	for line in island.paths:
		var row: Array[int] = []
		for p in MapIsland.path_samples(line, MapIsland.PATH_STEP):
			row.append(add_node.call(p))
		for k in row.size() - 1:
			join.call(row[k], row[k + 1])
		lines.append(row)
	for li in lines.size():
		for end: int in [lines[li][0], lines[li][-1]]:
			for lj in lines.size():
				if lj == li:
					continue
				var row: Array = lines[lj]
				var best := 0
				for k in row.size():
					if nodes[row[k]].distance_to(nodes[end]) < nodes[row[best]].distance_to(nodes[end]):
						best = k
				if nodes[row[best]].distance_to(nodes[end]) < ROUTE_JOIN:
					for k in range(maxi(0, best - 1), mini(row.size(), best + 2)):   # (and its neighbours: no step back at the join)
						join.call(end, row[k])
	# Paths that meet under a stage (the hutton island's paths run from spot to spot, #114): each one's
	# last point clear of that stage joined to the others' by steps round its edge, so the way goes round
	# the landmark instead of stopping at it (and then cutting over the grass).
	for stage: Array in _stages():
		var c: Vector2 = stage[0]
		var r: float = stage[1]
		var exits: Array[int] = []
		for row: Array in lines:
			for ends: Array in [[0, 1], [row.size() - 1, -1]]:
				if nodes[row[ends[0]]].distance_to(c) >= r:
					continue
				var k: int = ends[0]
				while k >= 0 and k < row.size() and nodes[row[k]].distance_to(c) < r + ROUTE_RING * 0.5:
					k += ends[1]
				if k >= 0 and k < row.size():
					exits.append(row[k])
		for i in exits.size():
			for j in range(i + 1, exits.size()):
				var a0 := (nodes[exits[i]] - c).angle()
				var turn := angle_difference(a0, (nodes[exits[j]] - c).angle())
				var steps := maxi(1, ceili(absf(turn) / ROUTE_RING_STEP))
				var last := exits[i]
				for k in range(1, steps):
					var m: int = add_node.call(c + Vector2.from_angle(a0 + turn * k / steps) * (r + ROUTE_RING))
					links[last].append(m)
					links[m].append(last)
					last = m
				links[last].append(exits[j])
				links[exits[j]].append(last)
	# Onto the paths: the nearest point of a link whose step from `p` crosses no stage.
	var nearest := func(p: Vector2) -> Array:
		var best := [INF, Vector2.ZERO, -1, -1]
		for i in links.size():
			for k: int in links[i]:
				if k < i:
					continue
				var q := Geometry2D.get_closest_point_to_segment(p, nodes[i], nodes[k])
				if p.distance_to(q) < best[0] and not _crosses_stage(p, q, ROUTE_CLEAR):
					best = [p.distance_to(q), q, i, k]
		return best
	var attach := func(p: Vector2) -> Array:
		var best: Array = nearest.call(p)
		var ring := PackedVector2Array()   # the steps round a stage first (#114), when it stands in the way
		if best[2] < 0:
			# A stand on the far side of its own stage from the paths (the hutton island's spots face away
			# from the path that comes to them): round the stage's edge to where a clear step reaches a path
			# (2026-11-10 user: they walked straight over the grass).
			ring = _round_stage(p, func(w: Vector2) -> bool: return (nearest.call(w) as Array)[2] >= 0)
			if ring.is_empty():
				return [-1, INF]
			best = nearest.call(ring[ring.size() - 1])
		var n: int = add_node.call(best[1])
		links[n] = [best[2], best[3]]
		links[best[2]].append(n)
		links[best[3]].append(n)
		var first := n
		var length: float = best[0]
		for k in range(ring.size() - 1, -1, -1):   # chained from the path back to the stand's side
			var m: int = add_node.call(ring[k])
			links[m].append(first)
			links[first].append(m)
			length += nodes[m].distance_to(nodes[first])
			first = m
		if not ring.is_empty():
			length += p.distance_to(ring[0])   # (the whole way from `p` to the path)
		return [first, length]
	var straight := not _crosses_stage(from, to, ROUTE_CLEAR)
	var start: Array = attach.call(from)
	var end: Array = attach.call(to)
	var points := PackedVector2Array([from])
	if start[0] >= 0 and end[0] >= 0 and not (straight and from.distance_to(to) <= minf(ROUTE_STRAIGHT_MAX, float(start[1]) + float(end[1]))):
		# Dijkstra over the samples (a few hundred: cheap, once per tap).
		var a: int = start[0]
		var b: int = end[0]
		var dist: Dictionary = {a: 0.0}
		var prev: Dictionary = {}
		var open: Array = [a]
		while not open.is_empty():
			open.sort_custom(func(x: int, y: int) -> bool: return dist[x] < dist[y])
			var u: int = open.pop_front()
			if u == b:
				break
			for v: int in links[u]:
				var d: float = dist[u] + nodes[u].distance_to(nodes[v])
				if d < dist.get(v, INF):
					dist[v] = d
					prev[v] = u
					if v not in open:
						open.append(v)
		if dist.has(b):
			var way: Array[Vector2] = []
			var n := b
			while true:
				way.push_front(nodes[n])
				if n == a:
					break
				n = prev[n]
			for p in way:
				if p.distance_to(points[points.size() - 1]) > 0.05:
					points.append(p)
	if to.distance_to(points[points.size() - 1]) > 0.05 or points.size() == 1:
		points.append(to)
	for pass_i in 2:
		if points.size() < 3:
			break
		var out := PackedVector2Array([points[0]])
		for k in points.size() - 1:
			out.append(points[k].lerp(points[k + 1], 0.25))
			out.append(points[k].lerp(points[k + 1], 0.75))
		out.append(points[points.size() - 1])
		points = out
	return points



## The steps round a stage: ROUTE_RING m out from its edge, ROUTE_RING_STEP apart.
const ROUTE_RING := 0.35
const ROUTE_RING_STEP := deg_to_rad(20.0)


## The steps round the stage `p` stands by (ROUTE_RING m out from its edge), turning the shorter way
## until `clear` holds at a step (a clear step onto a path from there): [first step .. last step], or
## empty (no stage there, or no clear step all round).
func _round_stage(p: Vector2, clear: Callable) -> PackedVector2Array:
	var stage: Array = []
	for s: Array in _stages():
		if p.distance_to(s[0]) < float(s[1]) + 1.0 and (stage.is_empty() or p.distance_to(s[0]) < p.distance_to(stage[0])):
			stage = s
	if stage.is_empty():
		return PackedVector2Array()
	var c: Vector2 = stage[0]
	var r: float = float(stage[1]) + ROUTE_RING
	var from := (p - c).angle()
	var best := PackedVector2Array()
	for turn: float in [1.0, -1.0]:
		var steps := PackedVector2Array()
		for k in range(1, int(TAU / ROUTE_RING_STEP)):
			var w := c + Vector2.from_angle(from + turn * ROUTE_RING_STEP * k) * r
			steps.append(w)
			if clear.call(w):
				if best.is_empty() or steps.size() < best.size():
					best = steps
				break
	return best


## The segment a-b comes within `margin` m of a spot's stage (its round plate) or the sundial (_stages).
func _crosses_stage(a: Vector2, b: Vector2, margin: float) -> bool:
	for stage: Array in _stages():
		var c: Vector2 = stage[0]
		if Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) < float(stage[1]) + margin:
			return true
	return false


## What the three's ways go round: [middle (x, z), radius] of every spot's round plate and of the
## square's sundial (MapIsland.SUNDIAL_CLEAR, #114: it stands in the square's middle now).
func _stages() -> Array:
	var out := []
	for spot in _spots:
		if float(spot.radius) > 0.0:
			out.append([Vector2(spot.at.x, spot.at.z), float(spot.radius)])
	if island.has_sundial():
		out.append([island.home, MapIsland.SUNDIAL_CLEAR])
	return out


## The share of the way walked `t` s into a walk of `total` s: it speeds up over WALK_RAMP_S, goes
## on at one pace and slows down over the last WALK_RAMP_S (a third of a short walk each). (Before
## 2026-11-01 one smoothstep over the whole walk: half again as fast in the middle of a long one.)
static func walk_share(t: float, total: float) -> float:
	if total <= 0.0:
		return 1.0
	t = clampf(t, 0.0, total)
	var ramp := minf(WALK_RAMP_S, total / 3.0)
	var top := 1.0 / (total - ramp)   # share per second at full pace
	if t < ramp:
		return 0.5 * top * t * t / ramp
	if t > total - ramp:
		var left := total - t
		return 1.0 - 0.5 * top * left * left / ramp
	return top * (t - 0.5 * ramp)


## How long the walk over `length` m takes (s).
static func walk_seconds(length: float) -> float:
	if length < 0.3:
		return WALK_IN_PLACE_S
	return clampf(length / WALK_SPEED, WALK_MIN_S, WALK_MAX_S)


## The point `s` m along the walk's way (clamped to its ends) and the way's direction there.
func _along(s: float) -> Array:
	return along(_route, _route_at, s)


## The point `s` m along `way` (its lengths `at` from its start, route_lengths; clamped to its ends) and
## its direction there.
static func along(way: PackedVector2Array, at: PackedFloat32Array, s: float) -> Array:
	var n := way.size()
	if n == 1:
		return [way[0], Vector2.ZERO]
	s = clampf(s, 0.0, at[n - 1])
	var k := 1
	while k < n - 1 and at[k] < s:
		k += 1
	var a := way[k - 1]
	var b := way[k]
	var span := at[k] - at[k - 1]
	var t := (s - at[k - 1]) / span if span > 1e-6 else 0.0
	return [a.lerp(b, t), (b - a).normalized()]


## The lengths along `way` from its start to each of its points.
static func route_lengths(way: PackedVector2Array) -> PackedFloat32Array:
	var at := PackedFloat32Array([0.0])
	for k in range(1, way.size()):
		at.append(at[k - 1] + way[k].distance_to(way[k - 1]))
	return at


func _step_walk(delta: float) -> void:
	var hops := floori(_walk_t * HOP_HZ)
	_walk_t += delta
	if floori(_walk_t * HOP_HZ) > hops:
		SoundBoard.play(&"hop")   # each hop's landing (HOP_HZ a second while it walks)
	var k := clampf(_walk_t / _walk_total, 0.0, 1.0)
	var length := _route_at[_route_at.size() - 1]
	var s := length * walk_share(_walk_t, _walk_total)
	var spot: Dictionary = _spots[_walk_spot]
	var group := group_at(spot)
	var here: Array = _along(s)
	var cat_at: Vector2 = here[0]
	var cat_dir: Vector2 = here[1] if here[1] != Vector2.ZERO else _along(0.0)[1]
	_set_walker(cat, cat_at, HOP_HEIGHT * absf(sin(_walk_t * PI * HOP_HZ)), delta)
	# Puppy and Dugi: each heads for its place a step behind the cat on the way (to its left / right),
	# at a walker's pace; one in the cat's way steps aside to its own side, and they keep apart. Over
	# the last SETTLE_SHARE their goal becomes the group's place at the spot.
	var top_speed := maxf(FOLLOW_SPEED, 1.6 * length / maxf(_walk_total, 0.01))
	var settle := smoothstep(1.0 - SETTLE_SHARE, 1.0, k)
	var spots := {}
	for entry in [[puppy, 1.0, 1.0], [dugi, -1.0, 2.0], [fox, _fox_side, -FOX_LEAD]]:   # (the fox leads ahead, #120, on the side it starts on)
		var actor: Node3D = entry[0]
		if actor == null:
			continue
		var side: float = entry[1]
		var lag: float = FOLLOW_LAG * float(entry[2])
		var behind: Array = _along(clampf(s - lag, 0.0, length))
		var dir: Vector2 = behind[1] if behind[1] != Vector2.ZERO else cat_dir
		# (dir.y, -dir.x): the walker's left. The guide walks FOX_WIDE m out to the side, so it passes the
		# cat with room to spare instead of squeezing by it (2026-11-13 user "막 비벼지고").
		var wide := FOX_WIDE if lag < 0.0 else FOLLOW_SIDE
		var goal: Vector2 = behind[0] + Vector2(dir.y, -dir.x) * wide * side
		# (behind the way's start: they wait for their turn where they stand, not further back off the way)
		var place: Vector3 = group[actor]
		var to_place := settle
		if lag < 0.0:   # (the fox) its lead point would end on the cat's own stand: over the last lead it heads for its place
			to_place = maxf(settle, clampf(1.0 - (length - s) / -lag, 0.0, 1.0))
		goal = goal.lerp(Vector2(place.x, place.z), to_place)
		var now: Vector3 = _walk_last.get(actor, actor.position)
		var at := Vector2(now.x, now.z)
		var step := (goal - at).limit_length((top_speed * (FOX_PACE if actor == fox else 1.0) + 4.0 * settle) * delta)
		if actor == fox:   # the fast guide eases its steps (no jerk back and forth when its goal turns, 2026-11-13)
			step = (_walk_step.get(actor, step) as Vector2).lerp(step, lerpf(FOX_EASE, 1.0, settle))   # (into its place at the end)
		var start := at
		at += step
		# Out of the cat's way: never nearer than KEEP_APART, a follower ahead of it to its own side.
		var off := at - cat_at
		if off.length() < KEEP_APART:
			var away := off.normalized() if off.length() > 0.01 else Vector2(cat_dir.y, -cat_dir.x) * side
			if off.dot(cat_dir) > 0.0 or actor == fox:   # (the guide passes the cat to its own side to lead)
				away = (away + Vector2(cat_dir.y, -cat_dir.x) * side * (2.0 if actor == fox else 1.0)).normalized()
			at = cat_at + away * KEEP_APART
		if actor == fox:   # (the step it really took: kept off the cat it does not push on into it)
			_walk_step[actor] = at - start
		spots[actor] = at
	# The followers keep apart from each other too (the fox as well: 2026-11-13 user "여우친구 이동할때 막
	# 비벼지고"), each pair pushed apart half each, then still out of the cat's way.
	var followers: Array = spots.keys()
	for i in followers.size():
		for j in range(i + 1, followers.size()):
			var a: Node3D = followers[i]
			var b: Node3D = followers[j]
			var gap: Vector2 = spots[b] - spots[a]
			if gap.length() < KEEP_APART:
				var push := (gap.normalized() if gap.length() > 0.01 else Vector2(cat_dir.y, -cat_dir.x) * -1.0) * (KEEP_APART - gap.length()) * 0.5
				spots[a] -= push
				spots[b] += push
	for actor: Node3D in spots:   # still out of the cat's way
		var off: Vector2 = spots[actor] - cat_at
		if off.length() < KEEP_APART and off.length() > 0.01:
			spots[actor] = cat_at + off.normalized() * KEEP_APART
	for actor: Node3D in spots:
		var hop: Array = FOLLOW_HOPS[str(actor.name)]
		_set_walker(actor, spots[actor], HOP_HEIGHT * float(hop[1]) * absf(sin((_walk_t + float(hop[0]) / HOP_HZ) * PI * HOP_HZ)), delta)
	# Stepping into the group's places they turn to the landmark (no snap when they get there).
	if settle > 0.0:
		for actor: Node3D in walkers():
			if actor != null:
				actor.rotation.y = lerp_angle(actor.rotation.y, group.facing, settle * (1.0 - exp(-TURN_RATE * delta)))
	if k >= 1.0:
		_walking = false
		rest_spot = _walk_spot
		ProgressStore.set_last_spot(island.id, str(spot.id))
		for actor: Node3D in walkers():
			actor.position = group[actor]
			actor.rotation.y = group.facing
		experiment_chosen.emit(spot.definition)


## The stroll (another island's prologue after the voyage, 2026-11-10 user: "대화중에 갑자기 섬 중앙으로
## 이동해버리는것도 어색하다"): the three walk in `seconds` from where the boat landed (`from`, x/z) along
## the paths to their row on the square, the cat first and Puppy and Dugi STROLL_LAG m behind, hopping;
## over the last STROLL_SETTLE they step into their row places and turn to the view.
func stroll_home(from: Vector2, seconds: float) -> void:
	var way := route(from, map.trio_row())
	_stroll = {"route": way, "at": route_lengths(way), "t": 0.0, "total": maxf(seconds, 0.1)}
	_walk_last.clear()
	_walk_heading.clear()
	_walk_step.clear()
	for actor: Node3D in walkers():
		actor.position = Vector3(from.x, map.walk_height(from.x, from.y), from.y)


## The three are strolling to the square now (tests).
func strolling() -> bool:
	return not _stroll.is_empty()


func _step_stroll(delta: float) -> void:
	if _stroll.is_empty():
		return
	_stroll.t += delta
	var k := clampf(float(_stroll.t) / float(_stroll.total), 0.0, 1.0)
	var at: PackedFloat32Array = _stroll.at
	var way: PackedVector2Array = _stroll.route
	var length := at[at.size() - 1] + 2.0 * STROLL_LAG
	var settle := smoothstep(1.0 - STROLL_SETTLE, 1.0, k)
	for entry in [[cat, 0.0], [puppy, 1.0], [dugi, 2.0], [fox, -1.0]]:   # (the fox leads, #120)
		var actor: Node3D = entry[0]
		if actor == null:
			continue
		var s := length * walk_share(float(_stroll.t), float(_stroll.total)) - STROLL_LAG * float(entry[1])
		var p: Vector2 = along(way, at, s)[0]
		var place := trio_spot(actor)
		# Near the way's end each heads for its own place in the row (the way ends on the cat's): they
		# never bunch up on that one point (2026-11-13 user "막 비벼지고").
		var to_place := maxf(settle, clampf((s - at[at.size() - 1] + 2.0 * STROLL_LAG) / (2.0 * STROLL_LAG), 0.0, 1.0))
		p = p.lerp(Vector2(place.x, place.z), to_place)
		_set_walker(actor, p, HOP_HEIGHT * absf(sin(float(_stroll.t) * PI * HOP_HZ + float(entry[1]))) * (1.0 - settle), delta)
		if settle > 0.0:
			actor.rotation.y = lerp_angle(actor.rotation.y, TRIO_YAW, settle)
	if k >= 1.0:
		_stroll = {}
		_place_trio(TRIO_YAW)


## An actor on the way at `at` (x, z) `lift` m above the ground (up the hills), turning towards where
## it goes (its recent heading, so a small sidestep does not spin it).
func _set_walker(actor: Node3D, at: Vector2, lift: float, delta: float) -> void:
	var last: Vector3 = _walk_last.get(actor, actor.position)
	if delta > 0.0:
		var velocity: Vector2 = (at - Vector2(last.x, last.z)) / delta
		var heading: Vector2 = _walk_heading.get(actor, Vector2.ZERO)
		heading = heading.lerp(velocity, 1.0 - exp(-HEADING_RATE * delta))
		_walk_heading[actor] = heading
		if heading.length() > 0.3:
			actor.rotation.y = lerp_angle(actor.rotation.y, atan2(heading.x, heading.y), 1.0 - exp(-TURN_RATE * delta))
	actor.position = Vector3(at.x, map.walk_height(at.x, at.y) + lift, at.y)
	_walk_last[actor] = Vector3(at.x, actor.position.y, at.y)


## One 2D label per spot (its name), its bottom edge just above its landmark (the landmark stays
## visible under it). Created lazily on the first frame the view has a size. The labels take no
## input: a tap on one reaches the map (_spot_at).
var _labels: Dictionary = {}


func _place_labels() -> void:
	if view == null or view.rig == null or view.size.x < 1.0:
		return
	var eye: Vector3 = view.rig.global_position
	var shown: Array = []   # [depth, label]
	for i in _spots.size():
		var spot: Dictionary = _spots[i]
		if not _labels.has(spot.id):
			_labels[spot.id] = _make_label(spot)
		var label: Control = _labels[spot.id]
		var screen_point := label_point(spot)
		label.visible = screen_point != Vector2.INF and _label_shown(spot.id)   # behind a close, low camera: hidden
		if not label.visible:
			continue
		label.position = screen_point - Vector2(label.size.x * 0.5, label.size.y)
		# Pinned at its bottom centre; a far one shrinks a little, like the landmark under it.
		var depth := eye.distance_to(spot.at)
		label.pivot_offset = Vector2(label.size.x * 0.5, label.size.y)
		label.scale = Vector2.ONE * clampf(LABEL_FULL_DISTANCE / maxf(depth, 0.01), LABEL_MIN_SCALE, 1.0) * _label_keep()
		shown.append([depth, label])
	# Names that meet stay put: the nearer one is drawn over the farther (no jumping aside).
	shown.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var at := view.get_index() + 1
	for entry in shown:
		move_child(entry[1], at)
		at += 1


## The spot names keep the map's 3D scale on a zoomed screen (화면 크기, 2026-11-04): the map is framed
## for a 720-unit short side, and names grown with the UI met each other in the play yard (at x1.1 on
## a phone). So a name is drawn 720 / short side smaller, as large on the glass as at x1.0.
func _label_keep() -> float:
	var short := minf(size.x, size.y)
	return minf(1.0, short / LABEL_SHORT_UNITS) if short > 0.0 else 1.0


## A spot's name shows: always without the story; on the night map only once its piece is found.
func _label_shown(id: String) -> bool:
	return story == null or story.label_shown(id)


## The rect a label covers on screen (its scale about its bottom centre).
func _label_rect(label: Control) -> Rect2:
	return Rect2(label.position + label.pivot_offset * (Vector2.ONE - label.scale), label.size * label.scale)


## Where a spot's label sits on screen (its bottom centre): just above the landmark's top, a fixed
## point of the landmark, so the name rides with it at every camera angle. INF when the map is not
## on screen.
func label_point(spot: Dictionary) -> Vector2:
	return _world_to_screen(spot.at + Vector3.UP * (float(spot.top) + 0.25))


## Where a tap on a spot's landmark is measured from: its middle.
func tap_point(spot: Dictionary) -> Vector3:
	return spot.at + Vector3.UP * (float(spot.top) * 0.5)


## Stands the spot's flag when it has all its stamps (3), otherwise lowers it.
func _refresh_flag(spot: Dictionary) -> void:
	var flag: Node3D = _flags.get(spot.id)
	if flag == null:
		return
	var stages: Array = MissionRound.missions(spot.definition).get("stages", [])
	if stages.is_empty():
		flag.visible = false
		return
	var stamps := ProgressStore.stamps(_progress, str(spot.id))
	flag.visible = stamps >= stages.size()


func _make_label(spot: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.name = "SpotLabel_%s" % spot.id
	box.theme_type_variation = "SpotPanel"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Ui.label(str(spot.id) if in_making(spot) else _spot_name(spot.definition), "SpotLabel")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	add_child(box)
	move_child(box, view.get_index() + 1)   # under the map buttons
	return box


## A spot of an island in the making (--island, #72): a place on the map with no experiment yet. Its
## name is its id and a tap only shakes its model.
static func in_making(spot: Dictionary) -> bool:
	return (spot.definition as Dictionary).is_empty()


## A short name for the spot (the labs' own titles are long questions): the experiment's kid
## `place` ("공 던지기", ExperimentRegistry.kid_text), else its title.
func _spot_name(definition: Dictionary) -> String:
	return ExperimentRegistry.kid_text(definition, "place")


func _on_pointer(kind: String, position: Vector2) -> void:
	match kind:
		"press":
			if _cinematic:
				return   # the story's shield takes the taps
			if raising() or (story != null and story.flying()):
				skip_raise()   # the tap only skips (it opens nothing): the flag and the pieces' flights
				if story != null:
					story.skip_flights()
				_down[0] = Vector2.INF
				return
			_down[0] = position
			_down[1] = false
			_last = position
		"move":
			if _down[0] != Vector2.INF and position.distance_to(_down[0]) > TAP_SLOP:
				_down[1] = true   # a drag, not a tap: it turns the map
			if _down[1] and _last != Vector2.INF:
				view.rig.orbit(position - _last)
			_last = position
		"release":
			if _down[0] != Vector2.INF and not _down[1]:
				var spot := _spot_at(position)
				if story != null and story.next_id != "" and _puppy_at(position):
					story.say_riddle()   # Puppy again: the riddle
				elif spot < 0 and story != null and story.tap_riddle():
					pass   # a tap beside Puppy's box turns its page (2026-10-31 user: a child got stuck)
				else:
					_walk_to_spot(spot)
			_down[0] = Vector2.INF
			_down[1] = false
			_last = Vector2.INF
		"cancel":
			_down[0] = Vector2.INF
			_down[1] = false
			_last = Vector2.INF


## The index of the spot under the screen point: the spot whose name label holds it, else the
## nearest landmark within SPOT_RADIUS, or -1.
func _spot_at(position: Vector2) -> int:
	if view == null or view.rig == null:
		return -1
	var hit := -1
	var hit_order := -1
	for i in _spots.size():   # the topmost name (the nearest, drawn last) wins
		var label: Control = _labels.get(_spots[i].id)
		if label != null and label.visible and _label_rect(label).has_point(position) and label.get_index() > hit_order:
			hit = i
			hit_order = label.get_index()
	if hit >= 0:
		return hit
	var best := -1
	var best_d := INF
	for i in _spots.size():
		var screen_point: Vector2 = _world_to_screen(tap_point(_spots[i]))
		if screen_point == Vector2.INF:
			continue
		var d := screen_point.distance_to(position)
		if d <= _screen_radius(tap_point(_spots[i])) and d < best_d:
			best_d = d
			best = i
	return best


## A spot's tap radius, in screen units: its world radius projected at its distance (a minimum of
## TAP_SLOP so a landmark is always tappable).
func _screen_radius(point: Vector3) -> float:
	if view == null or view.rig == null:
		return TAP_SLOP
	var eye: Vector3 = view.rig.global_position
	var dist: float = eye.distance_to(point)
	var world_h := 2.0 * dist * tan(deg_to_rad(view.rig.fov) * 0.5)
	var screen_per_m := view.size.y / world_h
	return maxf(TAP_SLOP, SPOT_RADIUS * 0.5 * screen_per_m)


## A world point on the view, or INF when the map is being swapped out or the point is behind the
## camera (a low, close view: its label hides, a tap cannot pick it).
func _world_to_screen(world: Vector3) -> Vector2:
	if view == null or view.rig == null or not view.rig.is_inside_tree():   # the map being swapped out
		return Vector2.INF
	if view.rig.is_position_behind(world):
		return Vector2.INF
	return view.rig.unproject_position(world) / (Vector2(view.viewport.size) / view.size)


## The screen point is on Puppy (on the square): within PUPPY_TAP_M of his middle, on screen.
func _puppy_at(position: Vector2) -> bool:
	if puppy == null:
		return false
	var middle := puppy.global_position + Vector3.UP * 0.55 * ACTOR_SCALE
	var point := _world_to_screen(middle)
	if point == Vector2.INF:
		return false
	var eye: Vector3 = view.rig.global_position
	var world_h := 2.0 * eye.distance_to(middle) * tan(deg_to_rad(view.rig.fov) * 0.5)
	return point.distance_to(position) <= maxf(TAP_SLOP * 2.0, PUPPY_TAP_M * view.size.y / world_h)


## Starts the cat's hop to the spot (beside its landmark); opens the experiment when it arrives. On
## the night map a locked spot does not open: Puppy says it is not here and the landmark shakes.
func _walk_to_spot(index: int) -> void:
	if index < 0 or _walking:
		return
	if in_making(_spots[index]):
		shake_spot(index)
		SoundBoard.play(&"stop")
		return
	if story != null and story.locked(_spots[index].id):
		story.say_wrong()
		shake_spot(index)
		SoundBoard.play(&"stop")   # a soft knock
		return
	if story != null and story.waits_for_tomorrow(_spots[index].id):
		story.say_today()   # #77: today's new spot of an island not bought is used
		shake_spot(index)
		SoundBoard.play(&"stop")
		return
	if story != null:
		story.hush()
		if _spots[index].id == story.next_id:
			DailyLimit.use(Island.current_id(), _spots[index].id)   # the day's new spot goes to it
	_walk_spot = index
	_route = route(Vector2(cat.position.x, cat.position.z), Vector2(_spots[index].stand.x, _spots[index].stand.z))
	_route_at = PackedFloat32Array([0.0])
	for i in range(1, _route.size()):
		_route_at.append(_route_at[i - 1] + _route[i - 1].distance_to(_route[i]))
	_walk_from = cat.position
	_walk_to = _spots[index].stand
	_walk_total = walk_seconds(_route_at[_route_at.size() - 1])
	_walk_t = 0.0
	_walk_last = {}
	_walk_heading = {}
	_walk_step = {}
	_fox_side = 1.0
	if fox != null and _route.size() > 1:   # the side it already stands on: it never crosses the group (2026-11-13)
		var d := (_route[1] - _route[0]).normalized()
		var off := Vector2(fox.position.x, fox.position.z) - _route[0]
		_fox_side = -1.0 if d.x * off.y - d.y * off.x > 0.0 else 1.0
	_walking = true
	SoundBoard.play(&"spot")
	var first: Array = _along(0.3)
	var ahead: Vector2 = first[0] - _route[0]
	if ahead.length() > 0.01:
		cat.rotation.y = atan2(ahead.x, ahead.y)
