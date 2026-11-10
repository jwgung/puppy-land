## 섬 고르기 (#75; since 2026-11-09 the title's 시작하기 opens it once there is a second island; since
## #116, 2026-11-10 user: "이 과학섬들 전체 지도를 보여주고 거기서 넘어오게 하는게 낫지 않아?"): the whole
## world's map, every island of the list (Island) out on one sea in a row with a dotted sea way between
## them, and at the row's end the island still to come under a cloud. Under each island its tag: its
## name and field, the pieces found on it and the same big red button on every open island: 출발! (nothing
## found yet; 2026-11-10 user: "가 보기라는 단어가 좀 어색해"), 이어서 하기 (pieces left) or 다시 가기 (all
## found), 이야기 다시 보기 under it; the island in use has the gold edge and the boat at its shore. An
## island not open yet (Island.is_open) is grey with a lock and the condition ("뉴턴섬 조각을 다 모으면
## 열려요"); the island still to come says 곧 만나요 (no island opens after the last yet).
## A tag's button or a tap on its island (or the tag) chooses: the island in use emits `chosen` at once;
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
const TAG_LIP := 8
const CURRENT_LINE := 6
const CURRENT_LIP := 12
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
## The world: the islands' middles SLOT m apart along x (the row centred on the origin), each map
## island at full size; the camera looks down at the row from PITCH_DEG and backs off until the row
## and the tags under it fit (VIEW_MARGIN of the width each side); a tag hangs under its island's
## front coast.
const SLOT := 46.0
## Each island's own sea sinks this much under the one before (no fight between the seas).
const SEA_SINK := 0.02
## An island's coast radius when it is not known (m), where the sea way leaves its coast (m out and
## m towards the camera), how far the way bends towards the camera (m) and its dots' size and lift.
const DEFAULT_REACH := 12.0
const SHORE_OUT := 1.5
const SHORE_FRONT := 4.0
const WAY_BEND := 5.0
const DOT_RADIUS := 0.32
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
## A locked island's tint (the map's own_tint), and the island still to come: a plain grey island
## (FAR_RADIUS m, its sand, land and hill in greys) under a cloud.
const LOCKED_TINT := Vector3(0.6, 0.66, 0.78)
const FAR_RADIUS := 10.0
const FAR_SAND := Color("c4c9d2")
const FAR_LAND := Color("a9b2bf")
const FAR_HILL := Color("b9c0cc")
## The sea way between the islands: dots DOT_STEP m apart over the water, and the boat (BoatArt, bigger)
## at the shore of the island in use, which sails the way in SAIL_S.
const DOT_STEP := 2.4
const DOT := Color("f4fbff")
const BOAT_SCALE := 2.6
const SAIL_S := 2.6
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
var _reach: Dictionary = {}        # id -> its island's coast radius (m, the widest)
var _pressed_at := Vector2.INF     # where the finger came down on the map (INF: none)


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
	if str(entry.id) == "":
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
	view.rig.set_process(false)   # the map frames the camera itself
	view.single_pointer.connect(_on_pointer)
	world = Node3D.new()
	world.name = "World"
	view.set_world(world)
	view.viewport.add_child(MapIsland.make_environment())
	_build_world()
	for entry in _entries:
		var tag := _tag(entry)
		cards[entry.id] = tag
		add_child(tag)
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


## The islands in a row on one sea (the first island's sea and sky; the others' own seas sink a little
## under it), the one to come grey under a cloud, the dotted way between them, the boat.
func _build_world() -> void:
	MapIsland.light_no_spots()
	var n := _entries.size()
	for k in n:
		var entry: Dictionary = _entries[k]
		var middle := Vector3((k - (n - 1) * 0.5) * SLOT, -SEA_SINK * k, 0.0)
		_middles[entry.id] = Vector3(middle.x, 0.0, middle.z)
		var holder := Node3D.new()
		holder.name = "Island_%s" % (entry.id if entry.id != "" else "next")
		holder.position = middle
		world.add_child(holder)
		if entry.id == "":   # the island still to come: a plain grey island, no map of its own yet
			holder.add_child(ArtKit.instance(_far_island_mesh(), MapIsland.material()))
			_reach[entry.id] = FAR_RADIUS
			continue
		var island := Island.by_id(str(entry.id))
		var map := MapIsland.new(island)
		map.build(holder, island.map_spots())
		var reach := 0.0
		for i in 16:
			reach = maxf(reach, map.coast_radius(TAU * i / 16.0))
		_reach[entry.id] = reach
		for child in holder.get_children():
			if child.name == "MapSky" and k > 0:
				child.free()   # one sky: the first island's
		if not entry.open:   # grey: every mesh of it in the map's material (its land, landmarks, sea)
			var grey := MapIsland.material().duplicate() as ShaderMaterial
			grey.set_shader_parameter("own_tint", LOCKED_TINT)
			for mi: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
				if mi.material_override is ShaderMaterial and (mi.material_override as ShaderMaterial).shader == grey.shader:
					mi.material_override = grey
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
	return Vector3(middle.x + side * (float(_reach.get(id, DEFAULT_REACH)) + SHORE_OUT), MapIsland.SEA_Y, middle.z + SHORE_FRONT)


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
	var ribbon := PanelContainer.new()
	ribbon.name = "IslandsHeading"
	ribbon.add_theme_stylebox_override("panel", UiTheme.outlined_box(UiTheme.TITLE_RED, UiTheme.DIALOGUE_LINE, HEADING_RADIUS, HEADING_PAD, HEADING_LINE, HEADING_LIP))
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = Locale.t("title.islands")
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", HEADING_SIZE)
	title.add_theme_color_override("font_color", UiTheme.WHITE)
	title.add_theme_color_override("font_outline_color", UiTheme.DIALOGUE_LINE)
	title.add_theme_constant_override("outline_size", HEADING_OUTLINE)
	ribbon.add_child(title)
	return ribbon


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
		TAG_RADIUS, Vector2(TAG_PAD, TAG_PAD), CURRENT_LINE if entry.current else TAG_LINE, CURRENT_LIP if entry.current else TAG_LIP))
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
		if emblem is SundialEmblem and entry.get("finale", false):
			(emblem as SundialEmblem).set_whole(true)   # #106: the sundial is whole after its finale
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
		var id: String = entry.id
		tag.gui_input.connect(func(event: InputEvent) -> void:
			if _tapped(event):
				choose(id))
	return tag


## A finger or the left button let go on a tag (a press that was not a drag).
static func _tapped(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not event.pressed and not event.canceled
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed \
		and event.device != InputEvent.DEVICE_ID_EMULATION


## A tap on the map: on an open island, as its button; during a sail, it ends the sail. A drag (more
## than TAP_SLOP between press and release) chooses nothing.
func _on_pointer(event_type: String, at: Vector2) -> void:
	if event_type == "press":
		_pressed_at = at
		return
	if event_type == "cancel":
		_pressed_at = Vector2.INF
		return
	if event_type != "release":
		return
	if is_finite(_pressed_at.x) and _pressed_at.distance_to(at) > TAP_SLOP:
		_pressed_at = Vector2.INF
		return
	_pressed_at = Vector2.INF
	if not sail.is_empty():
		_end_sail()
		return
	for entry in _entries:
		if entry.open and _island_rect(str(entry.id)).has_point(at):
			choose(str(entry.id))
			return


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
	if id == Island.current_id():
		chosen.emit(id)
		return
	var from := boat.position
	var i := _index(Island.current_id())
	var j := _index(id)
	var to_at := _shore(id, -1.0 if j > i else 1.0)
	sail = {"to": id, "from": from, "to_at": to_at, "t": 0.0}
	for tag: Control in cards.values():
		tag.visible = false
	boat.rotation.y = PI * 0.5 * (1.0 if j > i else -1.0)


func _process(delta: float) -> void:
	if sail.is_empty():
		return
	sail.t += delta
	var k := clampf(float(sail.t) / SAIL_S, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var p := _way(sail.from, sail.to_at, e)
	boat.position = Vector3(p.x, MapIsland.SEA_Y + 0.08 * sin(float(sail.t) * 6.0), p.z)
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


## The screen rect of island `id` (its coast round its middle, at sea level).
func _island_rect(id: String) -> Rect2:
	var middle: Vector3 = _middles.get(id, Vector3.ZERO)
	var r := float(_reach.get(id, DEFAULT_REACH))
	var out := Rect2(_screen(middle), Vector2.ZERO)
	for corner in [Vector3(-r, 0.0, -r), Vector3(r, 0.0, -r), Vector3(-r, 0.0, r), Vector3(r, 0.0, r)]:
		out = out.expand(_screen(middle + corner))
	return out


func _screen(p: Vector3) -> Vector2:
	return view.rig.unproject_position(p) / (Vector2(view.viewport.size) / view.size)


## The camera over the row (backed off until the islands fit the width, VIEW_MARGIN each side, and
## their tags fit under them), the tags under their islands, the heading and ← 돌아가기 at the top.
func _layout() -> void:
	if view == null or size.x < 1.0:
		return
	var inset := Ui.safe_insets(self)
	heading.size = heading.get_combined_minimum_size()
	back_button.size = back_button.get_combined_minimum_size()
	back_button.position = Vector2(EDGE + inset.left, TOP + inset.top)
	heading.position = Vector2((size.x - heading.size.x) * 0.5, TOP + inset.top)
	var first: Vector3 = _middles[_entries[0].id]
	var last: Vector3 = _middles[_entries[-1].id]
	var half := (last.x - first.x) * 0.5 + float(_reach[_entries[0].id])
	var pitch := deg_to_rad(PITCH_DEG)
	var target := AIM
	var tag_h := 0.0
	for tag: Control in cards.values():
		tag.size = tag.get_combined_minimum_size()
		tag_h = maxf(tag_h, tag.size.y)
	var distance := FIRST_DISTANCE
	for _pass in FIT_PASSES:   # back off until the row fits the width and the tags fit under it
		var eye := target + Vector3(0.0, -sin(pitch), cos(pitch)) * distance
		view.rig.look_at_from_position(eye, target)
		var left := _screen(Vector3(-half, 0.0, 0.0)).x
		var right := _screen(Vector3(half, 0.0, 0.0)).x
		var front := _screen(Vector3(0.0, 0.0, float(_reach[_entries[0].id]))).y
		var want := size.x * (1.0 - 2.0 * VIEW_MARGIN)
		var grow := maxf((right - left) / want, (front + TAG_GAP + tag_h) / (size.y - EDGE - inset.bottom))
		distance *= maxf(grow, FIT_MIN)
	for entry in _entries:
		var tag: Control = cards[entry.id]
		var middle: Vector3 = _middles[entry.id]
		var under := _screen(middle + Vector3(0.0, 0.0, float(_reach[entry.id]) * TAG_UNDER))
		var at := Vector2(under.x - tag.size.x * 0.5, minf(under.y + TAG_GAP, size.y - tag.size.y - EDGE - inset.bottom))
		tag.position = Vector2(clampf(at.x, EDGE + inset.left, size.x - tag.size.x - EDGE - inset.right), at.y)


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
