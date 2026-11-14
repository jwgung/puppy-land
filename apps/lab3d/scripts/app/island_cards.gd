## 섬 고르기 (#75; since 2026-11-09 the title's 시작하기 opens it once there is a second island; since
## #116, 2026-11-10 user: "이 과학섬들 전체 지도를 보여주고 거기서 넘어오게 하는게 낫지 않아?"): the whole
## world's map, every island of the list (Island) out on one sea in a row with a dotted sea way between
## them, and at the row's end the island still to come under a cloud. Under each island its tag: its
## name and field, the pieces found on it and the same big red button on every open island: 출발! (nothing
## found yet; 2026-11-10 user: "가 보기라는 단어가 좀 어색해"), 이어서 하기 (pieces left) or 다시 가기 (all
## found), 이야기 다시 보기 under it; the island in use has the gold edge and the boat at its shore. An
## island not open yet (Island.is_open) is grey with a lock and the condition ("뉴턴섬 조각을 다 모으면
## 열려요"); the island still to come says 곧 만나요 (no island opens after the last yet).
## Only a tag's button chooses (a tap on an island or its tag does nothing, 2026-11-10 user: "섬 근처
## 터치만 돼도 바로 이동해버리네"): the island in use emits `chosen` at once;
## another one first sails the boat along the sea way to it (SAIL_S, a tap ends it) and then emits
## `chosen` (App makes it the island in use and opens its map). ← 돌아가기 emits `back_requested`
## (TitleScreen closes the map); Android back closes it too, through App (TitleScreen.hide_islands, no
## signal). The payment (#77): an open island not bought has a small 보호자 in its tag's top right corner
## (ADR 0005: IslandOffer; its button takes its own taps, never the tag's).
## The name stays IslandCards (the title, the offer and the tests know it by it); its `cards` are the
## islands' tags.
class_name IslandCards
extends Control

signal chosen(island: String)
## 이야기 다시 보기 under an open island's button (2026-11-09): that island's story again.
signal story_chosen(island: String)
signal back_requested

const EDGE := 16.0
const TOP := 18.0                  # the heading and ← 돌아가기 from the top
## The heading: a red ribbon with white words outlined in the storybook brown.
const HEADING_RADIUS := 18
const HEADING_PAD := Vector2(34.0, 6.0)
const HEADING_LINE := 4
const HEADING_LIP := 9
const HEADING_SIZE := 36
const HEADING_OUTLINE := 8
## A tag: cream paper (a locked one greyer), the brown outline (the island in use: gold, thicker).
const TAG_RADIUS := 20
const TAG_PAD := 10.0
const TAG_LINE := 4
const CURRENT_LINE := 6
const LOCKED_PAPER := Color("efe7da")
const TAG_SEPARATION := 4
const TAG_WIDTH := 250.0
const NAME_SIZE := 28
const LOCK_SIZE := 54.0
const EMBLEM_SCALE := 0.62
## The tag's button (the same red one on every open island); a locked tag keeps its room.
const GO_WIDTH := 190.0
const GO_HEIGHT := 58.0
const GO_FONT := 24
const STORY_HEIGHT := 40.0         # 이야기 다시 보기 under it, small
const STORY_FONT := 17
const BACK_HEIGHT := 56.0
## The world: the islands' little models (_mini_island_mesh) SLOT m apart along x (the row centred on
## the origin); the camera looks down at the row from PITCH_DEG and backs off until VIEW_SLOTS slots
## round the island in focus and the tags under them fit (see the carousel below); a tag hangs under
## its island's front coast.
const SLOT := 42.0   # (23, then 34 for "섬이 너무 가까워서 배가 움직이는게 너무 짧아"; 42 with MODEL_SCALE, the same sea between)
## Every other island a little back (z), the sea's radius and its wave strokes; the little islands'
## radius, their trees and how big their landmarks are against the map's.
const ROW_STAGGER := 3.0
const SEA_RADIUS := 220.0
const WAVES := 40
const MINI_RADIUS := 8.0
## The little models are built at MINI_RADIUS and FAR_RADIUS and drawn this many times bigger
## (2026-11-11 user, 섬 고르기: "지도에서는 작아보이는데").
const MODEL_SCALE := 1.5
const MINI_TREES := 5
const MINI_SCALE := 2.0
const COAST_SIDES := 40
## An island's coast radius when it is not known (m), where the sea way leaves its coast (m out past
## the boat's own reach, BoatArt's hull end x BOAT_SCALE, so its bow and stern stay in the water:
## 2026-11-11 user "배가 육지로 올라간다"; m towards the camera), how far the way bends towards the
## camera (m) and its dots' size and lift.
const DEFAULT_REACH := 12.0
const SHORE_OUT := 1.0
const SHORE_FRONT := 4.0
const WAY_BEND := 5.0
const DOT_RADIUS := 0.4
const DOT_LIFT := 0.05
## The camera's aim (a little in front of the row), its first distance and how much a fitting pass
## may bring it nearer at most; a tag hangs at this share of its island's coast radius in front.
const AIM := Vector3(0.0, 0.0, 6.0)
const FIRST_DISTANCE := 60.0
const FIT_PASSES := 4
const FIT_MIN := 0.6
const TAG_UNDER := 0.85
## A tap on the map moves less than this (UI units) between press and release (a drag chooses nothing).
const TAP_SLOP := 18.0
const PITCH_DEG := -52.0
const VIEW_MARGIN := 0.04
const TAG_GAP := 6.0
## The carousel (2026-11-11 user: "섬 여러개 늘어나면 왓다갓다 할 수 잇어야댈거같아. CAROUSEL 쓰는거처럼"):
## the camera centres one island (at first the island in use) and shows VIEW_SLOTS slots (its
## neighbours peek in at the sides), fewer on a narrow screen so a slot is never narrower than a tag
## (TAG_WIDTH + TAG_SPACE); only the tag of the island nearest the middle shows; a drag slides the row
## (no arrows, 2026-11-11 user: "좌우 화살표는 없어도될듯"; ROW_OVERSCROLL slots past its ends) and on
## release it settles on the nearest island, the next one once it moved SNAP_SHARE of a slot
## (SNAP_RATE per second); during a sail the camera follows the boat.
const VIEW_SLOTS := 2.0
const TAG_SPACE := 24.0
const ROW_OVERSCROLL := 0.3
const SNAP_SHARE := 0.2
const SNAP_RATE := 9.0
## A locked island's tint (the map's own_tint), and the island still to come: a plain grey island
## (FAR_RADIUS m, its sand, land and hill in greys) under a cloud.
const LOCKED_TINT := Vector3(0.6, 0.66, 0.78)
## The new island's unlock (#118): the wait before the row slides to it, the slide, its colours' fade,
## the lock's pop, the lock's size against LOCK_SIZE.
const UNLOCK_WAIT_S := 0.8
const UNLOCK_SLIDE_S := 0.6
const UNLOCK_S := 1.2
const UNLOCK_POP_S := 0.6
const UNLOCK_LOCK_SCALE := 1.6
const FAR_RADIUS := 7.0
const FAR_SAND := Color("c4c9d2")
const FAR_LAND := Color("a9b2bf")
const FAR_HILL := Color("b9c0cc")
## The sea way between the islands: dots DOT_STEP m apart over the water, and the boat (BoatArt, bigger)
## at the shore of the island in use, which sails the way in SAIL_S.
const DOT_STEP := 2.4
const DOT := Color("f4fbff")
const BOAT_SCALE := 2.0
const SAIL_S := 3.2
## An island's picture for the island's offer (IslandOffer, thumbnail): its render size (px) and camera
## (the title's 3/4 view of the island).
const THUMB_PIXELS := Vector2i(400, 288)
const THUMB_PITCH_DEG := -34.0
const THUMB_YAW_DEG := 20.0
const THUMB_DISTANCE := 40.0
const THUMB_FOV := 40.0

var heading: PanelContainer
var back_button: Button
var view: View3D
var world: Node3D
var boat: Node3D
## Island id ("" for the island still to come) -> its tag's button (null when locked) (tests).
var buttons: Dictionary = {}
## Island id -> its tag (tests).
var cards: Dictionary = {}
## Island id -> its 이야기 다시 보기 (open islands; tests).
var story_buttons: Dictionary = {}
## Island id -> its 보호자 button (an open island not bought, #77; tests).
var guardians: Dictionary = {}
## The sail now: {to: id, from: Vector3, to_at: Vector3, t} (empty: none).
var sail := {}
var _entries: Array = []
var _middles: Dictionary = {}      # id -> its island's middle (world)
var _reach: Dictionary = {}        # id -> its model's radius (m: MINI_RADIUS, FAR_RADIUS, x MODEL_SCALE)
var _pressed_at := Vector2.INF     # where the finger came down on the map (INF: none)
## The carousel: the camera's x over the row, the island it settles on.
var focus_x := 0.0
var focus := 0
var _drag_from := 0.0              # focus_x when the finger came down
var _dragging := false
var _distance := FIRST_DISTANCE
var _m_per_px := 0.1               # m along the row per UI unit on screen
var _tag_h := 0.0                  # the tallest tag (_layout)
## The unlock of the island whose voyage is due (#118, once: Story.unlock_shown): {id, t, material,
## lock}; {} when none plays.
var unlock := {}
var _unlocking := ""               # the id whose unlock plays (set before the world is built)


## The islands, in order: per island {id, name, about, open, complete, pieces, total, piece (its kind,
## PieceArt), current, after}
## (`after`: the name of the island it waits for), then 다음 섬 {id "", open false, after: the last
## island's name}.
static func entries(progress: Dictionary) -> Array:
	var out := []
	var ids := Island.ids()
	for id in ids:
		var island := Island.by_id(id)
		var after := Island.opens_after(id)
		out.append({"id": id, "name": island_name(id), "about": Locale.t("island.%s.about" % id),
			"open": Island.is_open(id, progress), "complete": island.complete(progress),
			"pieces": island.found(progress).size(), "total": island.spots().size(), "piece": island.piece,
			"finale": ProgressStore.mark(ProgressStore.STORY, ProgressStore.island_key(id, "finale")),
			"current": id == Island.current_id(), "after": island_name(after) if after != "" else ""})
	out.append({"id": "", "name": Locale.t("islands.next"), "about": "", "open": false, "complete": false,
		"pieces": 0, "total": 0, "piece": PieceArt.STAR, "current": false, "after": island_name(str(ids[-1])) if not ids.is_empty() else ""})
	return out


static func island_name(id: String) -> String:
	return Locale.t("island.%s.name" % id)


## The line under a locked island's name: what opens it; 다음 섬 promises nothing yet (2026-11-09: no
## island opens after the last one, so not "collect them all and it opens").
static func locked_line(entry: Dictionary) -> String:
	# The 다음 섬 card, and an island still in the making (its spots not all labs yet: it would not
	# open even after the island before it, #151): 곧 만나요.
	if str(entry.id) == "" or not Island.by_id(str(entry.id)).playable():
		return Locale.t("islands.soon")
	return Locale.t("islands.locked") % str(entry.after)


func _ready() -> void:
	name = "IslandCards"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # the title's buttons under it take nothing
	_entries = entries(ProgressStore.load())
	view = View3D.new()
	view.name = "WorldView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	# Its own 3D world (#152): the title's turning island under it is in the shared world and showed
	# through between the islands' models once a row had an even count (four with curie).
	view.viewport.own_world_3d = true
	view.rig.set_process(false)   # the map frames the camera itself
	view.single_pointer.connect(_on_pointer)
	focus = _index(Island.current_id())
	var due := Story.voyage_due(ProgressStore.load())
	_unlocking = due if due != "" and not Story.unlock_shown(due) else ""
	world = Node3D.new()
	world.name = "World"
	view.set_world(world)
	view.viewport.add_child(MapIsland.make_environment())
	_build_world()
	focus_x = _focus_at(focus)
	for entry in _entries:
		var tag := _tag(entry)
		tag.mouse_filter = Control.MOUSE_FILTER_PASS   # a drag on a tag slides the row too (_gui_input)
		cards[entry.id] = tag
		add_child(tag)
	if not unlock.is_empty():
		_start_unlock()
	heading = _heading()
	add_child(heading)
	back_button = Ui.button(Locale.t("islands.back"), "TitleButton", BACK_HEIGHT)
	back_button.name = "IslandsBack"
	back_button.pressed.connect(back_requested.emit)
	add_child(back_button)
	_layout()
	resized.connect(_layout)
	if IslandStore.instance != null:
		IslandStore.instance.changed.connect(_on_store_changed)
	_settle()


func _exit_tree() -> void:
	MapIsland.light_no_spots()


## 퍼피랜드 (#116, 2026-11-10 user: "퍼피랜드 지도를 하나 만들어 둘까" → 3D): one sea with a little
## model of every island (MINI_RADIUS; its own landmarks only, not its whole map) set in a loose row,
## every other one a little back (ROW_STAGGER), the one to come grey under a cloud, the far islets and
## boats of the map's sea round them, the dotted way between them and the boat.
func _build_world() -> void:
	MapIsland.light_no_spots()
	var sea := ArtKit.builder()
	sea.ao_min = 1.0
	ArtKit.flat_disc(sea, Vector3(0.0, MapIsland.SEA_Y, 0.0), SEA_RADIUS, MapIsland.sea_color(), 48)
	for w in WAVES:   # little white wave strokes on the sea
		var a := w * 2.399963
		var r := 8.0 + SEA_RADIUS * 0.35 * sqrt((w + 0.5) / WAVES)
		sea.add_rounded_box(Transform3D(Basis(Vector3.UP, 0.25 * sin(w * 1.7)), Vector3(cos(a) * r, MapIsland.SEA_Y + 0.02, sin(a) * r * 0.6)), Vector3(2.2, 0.02, 0.16), 0.0, 1, ArtPalette.FOAM)
	var sea_node := ArtKit.instance(sea.commit(), MapIsland.material())
	sea_node.name = "Sea"
	world.add_child(sea_node)
	var far := MapSea.new()
	far.build(world)
	far.set_lanterns(false)
	var n := _entries.size()
	for k in n:
		var entry: Dictionary = _entries[k]
		var middle := Vector3((k - (n - 1) * 0.5) * SLOT, 0.0, ROW_STAGGER * (1.0 if k % 2 == 0 else -1.0))
		_middles[entry.id] = middle
		_reach[entry.id] = (FAR_RADIUS if entry.id == "" else MINI_RADIUS) * MODEL_SCALE
		var holder := Node3D.new()
		holder.name = "Island_%s" % (entry.id if entry.id != "" else "next")
		holder.position = middle + Vector3.UP * MapIsland.SEA_Y * (1.0 - MODEL_SCALE)   # (sea level stays at SEA_Y)
		holder.scale = Vector3.ONE * MODEL_SCALE
		world.add_child(holder)
		var mesh := _far_island_mesh() if entry.id == "" else _mini_island_mesh(str(entry.id))
		var material := MapIsland.material()
		var unlocks: bool = _unlocking != "" and entry.id == _unlocking
		if (not entry.open and entry.id != "") or unlocks:
			material = MapIsland.material().duplicate() as ShaderMaterial
			material.set_shader_parameter("own_tint", LOCKED_TINT)   # (the unlock brings its colours back)
		if unlocks:
			unlock = {"id": entry.id, "t": 0.0, "material": material}
		holder.add_child(ArtKit.instance(mesh, material))
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for k in n - 1:
		var a: Vector3 = _shore(_entries[k].id, 1.0)
		var c: Vector3 = _shore(_entries[k + 1].id, -1.0)
		var steps := maxi(1, int(a.distance_to(c) / DOT_STEP))
		for i in steps + 1:
			var p := _way(a, c, float(i) / steps)
			ArtKit.flat_disc(b, p + Vector3.UP * DOT_LIFT, DOT_RADIUS, DOT, 10)
	var dots := ArtKit.instance(b.commit(), MapIsland.material())
	dots.name = "SeaWay"
	world.add_child(dots)
	boat = Node3D.new()
	boat.name = "Boat"
	boat.scale = Vector3.ONE * BOAT_SCALE
	boat.add_child(ArtKit.instance(BoatArt.mesh(ArtPalette.RED), MapIsland.material()))
	world.add_child(boat)
	_moor(Island.current_id())


## Island `id`'s little model on the 퍼피랜드 map (#116): its own coastline (the map's, shrunk: the same
## island as when the child is on it) with its beach and grass, a few trees and only its own landmarks (MapLandmarks: the hutton island's volcano, lighthouse and sundial; the
## first island's star, spring and pulley; any other island its first spots), MINI_SCALE of their map size.
static func _mini_island_mesh(id: String) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 1.0
	var sea := MapIsland.SEA_Y
	var r := MINI_RADIUS
	# The island's own coastline (MapIsland.coast_radius, the map you walk on) shrunk to MINI_RADIUS:
	# the shallows round it, the beach, the grass inside (the map's grass edge).
	var island := Island.by_id(id)
	var map := MapIsland.new(island)
	var widest := 0.0
	var sides := map.sectors if not island.coast_necks.is_empty() else COAST_SIDES   # (a flask's neck needs the map's finer sectors)
	for i in sides:
		widest = maxf(widest, map.coast_radius(TAU * i / sides))
	var shrink := r / maxf(widest, 0.001)
	var coast := func(a: float) -> float: return map.coast_radius(a) * shrink
	_add_shape(b, coast, 1.12, sea - 0.05, sea + 0.01, MapIsland.sea_color().lightened(0.35), MapIsland.sea_color().lightened(0.35), sides)
	_add_shape(b, coast, 1.0, sea - 0.3, sea + 0.2, ArtPalette.SAND.darkened(0.08), ArtPalette.SAND, sides)
	_add_shape(b, coast, MapIsland.grass_edge(), sea + 0.2, sea + 0.5, ArtPalette.GRASS, ArtPalette.GRASS_TOP, sides)
	var top := sea + 0.5
	for t in MINI_TREES:   # trees round the edge of the grass
		var a := TAU * (float(t) + 0.35) / MINI_TREES
		var at := Vector3(cos(a), 0.0, sin(a)) * float(coast.call(a)) * MapIsland.grass_edge() * 0.78 + Vector3.UP * top
		b.add_cylinder(Transform3D(Basis(), at), 0.16, 0.12, 0.5, 6, ArtPalette.TRUNK)
		b.add_cylinder(Transform3D(Basis(), at + Vector3.UP * 0.4), 0.85, 0.0, 1.6, 7, ArtPalette.LEAF)
	var k := MINI_SCALE
	var place := func(x: float, z: float) -> Transform3D:
		return Transform3D(Basis().scaled(Vector3.ONE * k), Vector3(x, top, z))
	match id:
		"hutton":
			MapLandmarks.volcano(b, Transform3D(Basis(), Vector3(-1.6, top - 0.2, -2.0)), 3.4, 4.0, 0.2)
			MapLandmarks.lighthouse(b, place.call(4.0, 1.4))
			MapLandmarks.sundial(b, place.call(-0.6, 2.6))
		"curie":   # (the rainbow lighthouse on its hill: the lighthouse until #154 / #167)
			MapLandmarks.lighthouse(b, place.call(7.6, 0.0), true)   # the rainbow one at the flask's mouth
			MapLandmarks.house(b, place.call(-3.4, -1.6), 0)
			MapLandmarks.potion(b, place.call(-1.0, 2.8), 0.8, 1)
		"mechanics":
			MapLandmarks.add(b, "orbit", place.call(-2.2, -1.6))
			MapLandmarks.add(b, "spring", place.call(2.4, -0.8))
			MapLandmarks.add(b, "pulley", place.call(0.2, 2.4))
		_:
			var spots: Array = island.spots()
			for i in mini(3, spots.size()):
				var a := TAU * i / 3.0
				MapLandmarks.add(b, str(spots[i]), place.call(cos(a) * 2.0, sin(a) * 1.6))
	return b.commit()


## A flat shape round the origin, `share` of the radius `radius(theta)` at every angle (COAST_SIDES of
## them), from `y0` to its top at `y1`: its side in `side`, its top in `top_color`.
static func _add_shape(b: ArtMeshBuilder, radius: Callable, share: float, y0: float, y1: float, side: Color, top_color: Color, sides := COAST_SIDES) -> void:
	var ring: Array[Vector3] = []
	for i in sides:
		var a := TAU * i / sides
		ring.append(Vector3(cos(a), 0.0, sin(a)) * float(radius.call(a)) * share)
	for i in sides:
		var p0 := ring[i]
		var p1 := ring[(i + 1) % sides]
		b.add_triangle([Vector3(0.0, y1, 0.0), p1 + Vector3.UP * y1, p0 + Vector3.UP * y1], [top_color, top_color, top_color])
		var out := ((p0 + p1) * 0.5).normalized()
		b.add_triangle([p0 + Vector3.UP * y1, p1 + Vector3.UP * y1, p1 + Vector3.UP * y0], [side, side, side], out)
		b.add_triangle([p0 + Vector3.UP * y1, p1 + Vector3.UP * y0, p0 + Vector3.UP * y0], [side, side, side], out)


## The island still to come (#116): a grey sand ring, a grey land and a hill under a cloud.
static func _far_island_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 2.0
	var sea := MapIsland.SEA_Y
	b.add_cylinder(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.75)), Vector3(0.0, sea - 0.3, 0.0)), FAR_RADIUS, FAR_RADIUS * 1.04, 0.45, 28, FAR_SAND, true, FAR_SAND.lightened(0.1))
	b.add_cylinder(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.75)), Vector3(0.0, sea + 0.1, 0.0)), FAR_RADIUS * 0.8, FAR_RADIUS * 0.84, 0.5, 24, FAR_LAND, true, FAR_LAND.lightened(0.08))
	b.add_cylinder(Transform3D(Basis(), Vector3(1.5, sea + 0.55, -1.5)), FAR_RADIUS * 0.4, 0.6, 3.6, 12, FAR_HILL, true, FAR_HILL.lightened(0.1))
	b.ao_min = 1.0
	for c in 3:   # the cloud
		var r := 2.4 + 0.5 * c
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.4, 0.8, 1.0)), Vector3(-3.0 + 3.2 * c, sea + 5.2 + 0.7 * (c % 2), 0.5 - 1.0 * c)), r, 4, 10, ArtPalette.CLOUD)
	return b.commit()


## The island `id`'s shore on the sea way: its east (`side` +1) or west (-1) coast.
func _shore(id: String, side: float) -> Vector3:
	var middle: Vector3 = _middles.get(id, Vector3.ZERO)
	return Vector3(middle.x + side * (float(_reach.get(id, DEFAULT_REACH)) + boat_reach() + SHORE_OUT), MapIsland.SEA_Y, middle.z + SHORE_FRONT)


## How far the map's boat reaches from its middle (m): its hull's far end, bow or stern, at BOAT_SCALE.
static func boat_reach() -> float:
	var hull: Array = BoatArt.HULL
	return maxf(absf(float(hull[0][0])), absf(float(hull[-1][0]))) * BOAT_SCALE


## The sea way at `k` (0..1) from `a` to `b`: bent a little towards the camera (+z).
static func _way(a: Vector3, b: Vector3, k: float) -> Vector3:
	return a.lerp(b, k) + Vector3(0.0, 0.0, sin(PI * k) * WAY_BEND)


## The boat at the shore of island `id` (the one in use), bow towards the next island.
func _moor(id: String) -> void:
	var i := _index(id)
	var side := 1.0 if i < _entries.size() - 2 else -1.0
	boat.position = _shore(id, side)
	boat.rotation.y = PI * 0.5 * side


func _index(id: String) -> int:
	for k in _entries.size():
		if _entries[k].id == id:
			return k
	return 0


## 섬 고르기 on the red ribbon.
func _heading() -> PanelContainer:
	var heading := ribbon(Locale.t("title.islands"), HEADING_SIZE)
	heading.name = "IslandsHeading"
	return heading


## `text` on the red ribbon in white bold letters of `font_size` (섬 고르기's heading; the island's
## "<island> 완성!" at its finale, #118). It takes no touch.
static func ribbon(text: String, font_size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.outlined_box(UiTheme.TITLE_RED, UiTheme.DIALOGUE_LINE, HEADING_RADIUS, HEADING_PAD, HEADING_LINE, HEADING_LIP))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = text
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", font_size)
	title.add_theme_color_override("font_color", UiTheme.WHITE)
	title.add_theme_color_override("font_outline_color", UiTheme.DIALOGUE_LINE)
	title.add_theme_constant_override("outline_size", HEADING_OUTLINE)
	panel.add_child(title)
	return panel


## A wrapped line's height follows its width only after the tags sorted once: the layout again then.
func _settle() -> void:
	for i in 2:
		await get_tree().process_frame
	if is_inside_tree():
		_layout()


## An island's tag: the pieces found, its name, its field (or what opens it), its red button and
## 이야기 다시 보기 (a lock and no button when it is not open).
func _tag(entry: Dictionary) -> PanelContainer:
	var locked: bool = not entry.open
	var tag := PanelContainer.new()
	tag.name = "Card_%s" % (entry.id if entry.id != "" else "next")
	var line := UiTheme.SELECT_LINE if entry.current else UiTheme.DIALOGUE_LINE
	tag.add_theme_stylebox_override("panel", UiTheme.outlined_box(LOCKED_PAPER if locked else UiTheme.DIALOGUE_PAPER, line,
		TAG_RADIUS, Vector2(TAG_PAD, TAG_PAD), CURRENT_LINE if entry.current else TAG_LINE, 0))   # (the same edge all round, no lip: 2026-11-11 user "섬 설명 카드 border를 상하좌우 동일하게")
	tag.custom_minimum_size.x = TAG_WIDTH
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", TAG_SEPARATION)
	tag.add_child(col)
	if locked:
		var lock := Lock.new()
		lock.name = "Lock"
		lock.custom_minimum_size = Vector2(LOCK_SIZE, LOCK_SIZE)
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(lock)
	elif int(entry.total) > 0:
		var holder := Control.new()   # the pieces found (the emblem, scaled into a small square)
		holder.name = "Pieces"
		var emblem := PieceArt.emblem(str(entry.piece), int(entry.total))
		emblem.set_filled(int(entry.pieces))
		if not emblem is StarEmblem and entry.get("finale", false):
			emblem.set_whole(true)   # #106, #154: the sundial's or the lens's middle after its finale
		emblem.pivot_offset = Vector2.ZERO
		emblem.scale = Vector2.ONE * EMBLEM_SCALE
		holder.custom_minimum_size = emblem.get_combined_minimum_size() * EMBLEM_SCALE
		holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(emblem)
		col.add_child(holder)
	_add_words(col, entry)
	if locked:
		buttons[entry.id] = null
	else:
		buttons[entry.id] = _go_button(entry)
		col.add_child(buttons[entry.id])
		story_buttons[entry.id] = _story_button(entry)
		col.add_child(story_buttons[entry.id])
		if not IslandStore.owns(entry.id):
			tag.add_child(_guardian_button(entry.id))
	return tag


## A tap on the map during a sail ends it (the boat lands at once). Only an island's button sails
## (2026-11-10 user: "섬 근처 터치만 돼도 바로 이동해버리네"): a tap on the island in the middle or its
## tag does nothing; a tap on one beside it brings that one to the middle (2026-11-11 user: "그 섬
## 눌러도 포커스 이동 되게 해줘"). A drag (more than TAP_SLOP from the press) slides the row and on
## release settles (_snap).
func _on_pointer(event_type: String, at: Vector2) -> void:
	if event_type == "press":
		_pressed_at = at
		_drag_from = focus_x
		_dragging = false
		return
	if event_type == "move":
		if not sail.is_empty() or not is_finite(_pressed_at.x):
			return
		_dragging = _dragging or _pressed_at.distance_to(at) > TAP_SLOP
		if _dragging:   # the row follows the finger
			var ends := Vector2(_focus_at(0), _focus_at(_entries.size() - 1)) + Vector2(-1.0, 1.0) * ROW_OVERSCROLL * SLOT
			focus_x = clampf(_drag_from - (at.x - _pressed_at.x) * _m_per_px, ends.x, ends.y)
			_place()
		return
	if event_type == "cancel":
		_pressed_at = Vector2.INF
		if _dragging:
			_snap()
		_dragging = false
		return
	if event_type != "release":
		return
	var dragged := _dragging or (is_finite(_pressed_at.x) and _pressed_at.distance_to(at) > TAP_SLOP)
	_pressed_at = Vector2.INF
	_dragging = false
	if dragged:
		if sail.is_empty():
			_snap()
		return
	if not sail.is_empty():
		_end_sail()
		return
	var near := nearest()
	for k in _entries.size():
		if k != near and _island_rect(str(_entries[k].id)).has_point(at):
			focus = k
			return


## A drag or a click on a tag (MOUSE_FILTER_PASS) comes up here: the view takes it as its own, so the
## row slides under a finger on a tag too. (Its buttons take their own taps.)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion:
		view._gui_input(event)


## After a drag: the island the row settles on (the next one once it moved SNAP_SHARE of a slot).
func _snap() -> void:
	var moved := (focus_x - _focus_at(focus)) / SLOT
	var step := roundi(moved)
	if step == 0 and absf(moved) > SNAP_SHARE:
		step = 1 if moved > 0.0 else -1
	focus = clampi(focus + step, 0, _entries.size() - 1)


## The camera's x when island `k` of the row is in focus.
func _focus_at(k: int) -> float:
	return (_middles[_entries[k].id] as Vector3).x if not _middles.is_empty() else 0.0


## The small 보호자 at the tag's top right of an open island not bought (#77): the guardian's check,
## then the island's offer. Gone once the island is bought.
func _guardian_button(id: String) -> Button:
	var guardian := GuardianModal.guardian_button()
	guardian.name = "Guardian"
	guardian.size_flags_horizontal = Control.SIZE_SHRINK_END
	guardian.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	guardian.pressed.connect(func() -> void: IslandOffer.open_for_guardian(self, id))
	guardians[id] = guardian
	return guardian


## The store changed (a purchase): a bought island's 보호자 goes.
func _on_store_changed() -> void:
	for id in guardians:
		if is_instance_valid(guardians[id]):
			guardians[id].visible = not IslandStore.owns(id)


## The island's name and, under it, its field (or, when locked, what opens it).
func _add_words(col: VBoxContainer, entry: Dictionary) -> void:
	var locked: bool = not entry.open
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = entry.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", UiTheme.bold_font())
	name_label.add_theme_font_size_override("font_size", NAME_SIZE)
	name_label.add_theme_color_override("font_color", UiTheme.MUTED if locked else UiTheme.INK)
	col.add_child(name_label)
	var sub := Label.new()
	sub.name = "About"
	sub.text = locked_line(entry) if locked else str(entry.about)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = TAG_WIDTH - 2.0 * TAG_PAD
	sub.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	sub.add_theme_color_override("font_color", UiTheme.SUBTLE if locked else UiTheme.MUTED)
	col.add_child(sub)


## 이야기 다시 보기 of the island (small, under its button; 2026-11-09 user: the title's one was unclear
## with two islands): `story_chosen` with the island.
func _story_button(entry: Dictionary) -> Button:
	var story := Ui.button(Locale.t("common.replay_story"), "TitleButton", STORY_HEIGHT)
	story.name = "Story"
	story.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	story.add_theme_font_size_override("font_size", STORY_FONT)
	var id: String = entry.id
	story.pressed.connect(func() -> void: story_chosen.emit(id))
	return story


## The way in, the same big red button on every open island (2026-11-09: one look; the island in use
## is the gold edge): 출발! (nothing found yet), 이어서 하기 (pieces left) or 다시 가기 (all found).
func _go_button(entry: Dictionary) -> Button:
	var words := Locale.t("islands.again") if entry.complete else (Locale.t("islands.go") if int(entry.pieces) == 0 else Locale.t("islands.continue"))
	var go := Ui.button(words, "TitleStartButton", GO_HEIGHT)
	go.name = "Go"
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.custom_minimum_size.x = GO_WIDTH
	go.add_theme_font_size_override("font_size", GO_FONT)
	var id: String = entry.id
	go.pressed.connect(func() -> void: choose(id))
	return go


## The child chose island `id`: the island in use at once, another after the boat has sailed there.
func choose(id: String) -> void:
	if not sail.is_empty() or not bool(_entries[_index(id)].open) or _entries[_index(id)].id != id:
		return   # (sailing already, or not an open island of the map)
	if id == Island.current_id() or id == Story.voyage_due(ProgressStore.load()):
		chosen.emit(id)   # (the island in use opens; the first trip is the voyage itself, #118)
		return
	var from := boat.position
	var i := _index(Island.current_id())
	var j := _index(id)
	var to_at := _shore(id, -1.0 if j > i else 1.0)
	sail = {"to": id, "from": from, "to_at": to_at, "t": 0.0}
	focus = j
	for tag: Control in cards.values():
		tag.visible = false
	boat.rotation.y = PI * 0.5 * (1.0 if j > i else -1.0)
	_place()


func _process(delta: float) -> void:
	_step_unlock(delta)
	if sail.is_empty():
		if not _dragging and not is_equal_approx(focus_x, _focus_at(focus)):   # settling on `focus`
			focus_x = lerpf(focus_x, _focus_at(focus), 1.0 - exp(-SNAP_RATE * delta))
			if absf(focus_x - _focus_at(focus)) < 0.01:
				focus_x = _focus_at(focus)
			_place()
		return
	sail.t += delta
	var k := clampf(float(sail.t) / SAIL_S, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var p := _way(sail.from, sail.to_at, e)
	boat.position = Vector3(p.x, MapIsland.SEA_Y + 0.08 * sin(float(sail.t) * 6.0), p.z)
	focus_x = lerpf(focus_x, p.x, 1.0 - exp(-SNAP_RATE * delta))   # the camera follows the boat (eased from where the row was)
	_place()
	if k >= 1.0:
		_end_sail()


## The sail ends (at the far shore, or a tap): `chosen` with its island.
func _end_sail() -> void:
	if sail.is_empty():
		return
	var id: String = sail.to
	boat.position = sail.to_at
	sail = {}
	chosen.emit(id)


## The unlock (#118, 2026-11-11 user: "지도에서 다음 허턴섬이 해금되고"): the new island's tag wears a
## lock; after UNLOCK_WAIT_S the row slides to it (UNLOCK_SLIDE_S), then its grey (LOCKED_TINT) fades
## to its own colours over UNLOCK_S while the lock swells and fades (UNLOCK_POP_S), confetti falls and
## the fanfare plays.
## Marked seen at its start (a map closed half way does not play it again).
func _start_unlock() -> void:
	Story.mark_unlock_shown(str(unlock.id))
	var lock := Lock.new()
	lock.name = "UnlockLock"
	lock.custom_minimum_size = Vector2(LOCK_SIZE, LOCK_SIZE) * UNLOCK_LOCK_SCALE
	lock.size = lock.custom_minimum_size
	add_child(lock)   # (over its tag, not in it: the tag is a container)
	unlock["lock"] = lock


func _step_unlock(delta: float) -> void:
	if unlock.is_empty():
		return
	unlock.t += delta
	var t: float = unlock.t
	var tag: Control = cards[unlock.id]
	var lock: Control = unlock.lock
	lock.position = tag.position + (tag.size - lock.size) * 0.5
	lock.pivot_offset = lock.size * 0.5
	lock.visible = tag.visible
	if t >= UNLOCK_WAIT_S and not unlock.has("going"):
		unlock["going"] = true
		focus = _index(str(unlock.id))   # the row slides to it (_process settles)
	if t >= UNLOCK_WAIT_S + UNLOCK_SLIDE_S and not unlock.has("opened"):
		unlock["opened"] = true
		SoundBoard.play(&"fanfare")
		add_child(Confetti.new())
	var opened := t - UNLOCK_WAIT_S - UNLOCK_SLIDE_S   # once the row is there
	var k := clampf(opened / UNLOCK_S, 0.0, 1.0)
	(unlock.material as ShaderMaterial).set_shader_parameter("own_tint", LOCKED_TINT.lerp(Vector3.ONE, k * k * (3.0 - 2.0 * k)))
	var p := clampf(opened / UNLOCK_POP_S, 0.0, 1.0)
	lock.scale = Vector2.ONE * (1.0 + 0.8 * p)
	lock.modulate.a = 1.0 - p
	if k >= 1.0 and p >= 1.0:
		lock.queue_free()
		unlock = {}


## The screen rect of island `id` (its coast round its middle, at sea level): a tap on it brings it to
## the middle; the tests check the tags against it.
func _island_rect(id: String) -> Rect2:
	var middle: Vector3 = _middles.get(id, Vector3.ZERO)
	var r := float(_reach.get(id, DEFAULT_REACH))
	var out := Rect2(_screen(middle), Vector2.ZERO)
	for corner in [Vector3(-r, 0.0, -r), Vector3(r, 0.0, -r), Vector3(-r, 0.0, r), Vector3(r, 0.0, r)]:
		out = out.expand(_screen(middle + corner))
	return out


func _screen(p: Vector3) -> Vector2:
	return view.rig.unproject_position(p) / (Vector2(view.viewport.size) / view.size)


## The heading and ← 돌아가기 at the top; the camera's distance (backed off until VIEW_SLOTS slots, fewer
## on a narrow screen, fit the width with VIEW_MARGIN each side and the tags fit under the row), then
## _place (the camera at focus_x and the tag).
func _layout() -> void:
	if view == null or size.x < 1.0:
		return
	var inset := Ui.safe_insets(self)
	heading.size = heading.get_combined_minimum_size()
	back_button.size = back_button.get_combined_minimum_size()
	back_button.position = Vector2(EDGE + inset.left, TOP + inset.top)
	heading.position = Vector2((size.x - heading.size.x) * 0.5, TOP + inset.top)
	var slots := clampf(size.x / (TAG_WIDTH + TAG_SPACE), 1.0, VIEW_SLOTS)   # a slot never narrower than a tag
	var half := slots * SLOT * 0.5
	_tag_h = 0.0
	for tag: Control in cards.values():
		tag.size = tag.get_combined_minimum_size()
		_tag_h = maxf(_tag_h, tag.size.y)
	_distance = FIRST_DISTANCE
	for _pass in FIT_PASSES:   # back off until the slots fit the width and the tags fit under them
		_aim(0.0)
		var left := _screen(Vector3(-half, 0.0, 0.0)).x
		var right := _screen(Vector3(half, 0.0, 0.0)).x
		var front := _screen(Vector3(0.0, 0.0, ROW_STAGGER + MINI_RADIUS * MODEL_SCALE)).y
		var want := size.x * (1.0 - 2.0 * VIEW_MARGIN)
		var grow := maxf((right - left) / want, (front + TAG_GAP + _tag_h) / (size.y - EDGE - inset.bottom))
		_distance *= maxf(grow, FIT_MIN)
	_aim(0.0)
	_m_per_px = SLOT / maxf(_screen(Vector3(SLOT, 0.0, 0.0)).x - _screen(Vector3.ZERO).x, 1.0)
	_place()


## The camera over the row at `x` (PITCH_DEG, _distance back from AIM).
func _aim(x: float) -> void:
	var target := AIM + Vector3(x, 0.0, 0.0)
	var pitch := deg_to_rad(PITCH_DEG)
	view.rig.look_at_from_position(target + Vector3(0.0, -sin(pitch), cos(pitch)) * _distance, target)


## The camera at focus_x, the tag of the island nearest the middle under it.
func _place() -> void:
	if view == null or size.x < 1.0:
		return
	_aim(focus_x)
	var inset := Ui.safe_insets(self)
	# The tag of the island nearest the middle under it (its top level for every island, under the
	# lowest of the staggered row, 2026-11-11 user: "뉴턴섬이랑 허턴섬 딱지가 높이가 다른게 별로임"); the
	# others hidden; none during a sail.
	var top := 0.0
	for entry in _entries:
		top = maxf(top, _screen(_middles[entry.id] + Vector3(0.0, 0.0, float(_reach[entry.id]) * TAG_UNDER)).y + TAG_GAP)
	var y := minf(top, size.y - _tag_h - EDGE - inset.bottom)
	var near := nearest()
	for k in _entries.size():
		var entry: Dictionary = _entries[k]
		var tag: Control = cards[entry.id]
		var x := _screen(_middles[entry.id]).x - tag.size.x * 0.5
		tag.position = Vector2(clampf(x, EDGE + inset.left, size.x - tag.size.x - EDGE - inset.right), y)
		tag.visible = sail.is_empty() and k == near


## The island of the row nearest the middle of the view now (its tag shows).
func nearest() -> int:
	return clampi(roundi((focus_x - _focus_at(0)) / SLOT), 0, _entries.size() - 1)


## The picture of `id`, its small world under `host` (the island's offer: IslandOffer).
static func thumbnail(host: Node, id: String) -> Texture2D:
	var sub := SubViewport.new()
	sub.name = "Thumb_%s" % id
	sub.size = THUMB_PIXELS
	sub.own_world_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(sub)
	sub.add_child(MapIsland.make_environment())
	var world := Node3D.new()
	sub.add_child(world)
	var island := Island.by_id(id)
	MapIsland.new(island).build(world, island.map_spots())
	var camera := Camera3D.new()
	camera.fov = THUMB_FOV
	sub.add_child(camera)
	var pitch := deg_to_rad(THUMB_PITCH_DEG)
	var yaw := deg_to_rad(THUMB_YAW_DEG)
	var target := Vector3(0.0, IslandHomeScreen.TARGET_Y, 0.0)
	var eye := target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * THUMB_DISTANCE
	camera.look_at_from_position(eye, target)
	camera.current = true
	return sub.get_texture()


## The rects of the tags, the heading and ← 돌아가기 (tests: on screen, no overlap).
func rects() -> Array[Rect2]:
	var out: Array[Rect2] = [heading.get_global_rect(), back_button.get_global_rect()]
	for tag: Control in cards.values():
		if tag.visible:
			out.append(tag.get_global_rect())
	return out


## A padlock (gold body, steel shackle, brown storybook outline) in the middle of a locked picture.
## Its drawing is in units of a 110-unit square (scaled to the picture).
class Lock extends Control:
	const DESIGN := 110.0
	const STEEL := Color("c9ced8")
	const OUTLINE_WIDTH := 13.0
	const STEEL_WIDTH := 7.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y) / DESIGN
		var c := size * 0.5 + Vector2(0.0, -4.0) * s
		var line := UiTheme.DIALOGUE_LINE
		for pass_width in [OUTLINE_WIDTH, STEEL_WIDTH]:
			var color := line if pass_width == OUTLINE_WIDTH else STEEL
			draw_arc(c + Vector2(0, -8) * s, 17.0 * s, PI, TAU, 24, color, pass_width * s, true)
			draw_line(c + Vector2(-17, -8) * s, c + Vector2(-17, 4) * s, color, pass_width * s, true)
			draw_line(c + Vector2(17, -8) * s, c + Vector2(17, 4) * s, color, pass_width * s, true)
		var body := StyleBoxFlat.new()
		body.bg_color = ArtPalette.YELLOW
		body.border_color = line
		body.set_border_width_all(maxi(2, int(4 * s)))
		body.set_corner_radius_all(int(9 * s))
		body.anti_aliasing = true
		draw_style_box(body, Rect2(c + Vector2(-27, -2) * s, Vector2(54, 40) * s))
		draw_rect(Rect2(c + Vector2(-21, 3) * s, Vector2(42, 7) * s), ArtPalette.YELLOW_TOP)
		draw_circle(c + Vector2(0, 14) * s, 5.5 * s, line, true, -1.0, true)
		draw_line(c + Vector2(0, 16) * s, c + Vector2(0, 26) * s, line, 5.0 * s, true)
