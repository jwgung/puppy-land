## The voyage to the next island (#75, 2026-11-06 user-approved mock A1): a short 3D scene after the
## first island's finale. The trio sail on a little boat from the island before (`from`) to the next
## one (`to`): they leave its shore by day with the guiding star back in the sky, cross the sea, the
## next island goes dark and bright again while they look at it, and they land on its beach where its
## keeper (the fox, speaker `fox`) waits. The words are the next island's story `voyage` pages (Story:
## who, face, shot); each page's `shot` (Story.VOYAGE_SHOTS) sets the camera and how far the boat has
## come. A tap turns the page (anywhere), 건너뛰기 or Android back skips to the end. At the end the
## voyage counts as seen (Story.mark_voyage_seen), the next island becomes the island in use and
## `finished` asks App for its map (which then plays that island's prologue).
##
## Its own small world, only while it plays: both maps' islands (MapIsland: the next one far out on
## the sea, its sky left out), the sea's far islands and boats (MapSea), the trip's boat (MapSea's boat,
## bigger) with the map-size trio aboard, and the keeper. Pictures and words only: nothing is saved
## but the voyage's mark and the island in use, and no lab is touched.
class_name VoyageScreen
extends Control

signal finished(island: String)

## Where the next island lies from the one before (m; the default view looks along -z).
const TO_AT := Vector3(0.0, 0.0, -110.0)
## The boat's way: from the shore of `from` to the beach of `to`, bending out a little (BEND m).
const START := Vector3(3.0, 0.0, -15.5)
const END_FROM_TO := Vector3(4.0, 0.0, 14.2)
const BEND := 6.0
## The trip's boat: MapSea's boat this much bigger, the trio aboard at the map's size
## (IslandHomeScreen.ACTOR_SCALE = BOAT_SCALE x ACTOR_ON_BOAT).
const BOAT_SCALE := 1.7
const ACTOR_ON_BOAT := 0.42
## [puppy, dugi, cat] on the boat's deck (boat local, bow +z).
const ABOARD := [Vector3(0.0, 0.56, 0.62), Vector3(-0.22, 0.52, -0.1), Vector3(0.2, 0.55, -0.72)]
## Each shot's stretch of the way (0 = the shore of `from`, 1 = the beach of `to`); the pages of a
## shot share it, each gliding its part in GLIDE_S.
const SHOT_WAY := {"depart": [0.0, 0.05], "sea": [0.42, 0.5], "flicker": [0.5, 0.58], "arrive": [0.92, 1.0]}
const GLIDE_S := 4.0
## The next island going dark and bright again (the flicker shot): its own tint, one dark beat per FLICKER_S.
const DARK_TINT := Vector3(0.24, 0.28, 0.58)
const FLICKER_S := 1.6
## The keeper on the beach of `to` (from its centre), facing the boat.
const KEEPER_AT := Vector2(4.0, 10.9)
const KEEPER_SCALE := 0.7
## The guiding star over `from` while they leave.
const STAR_AT := Vector3(-2.0, 10.0, 2.0)
const STAR_SIZE := 1.1
const MARGIN := 12.0

var from := ""
var to := ""
var view: View3D
var world: Node3D
var env: WorldEnvironment
var sea: MapSea
var boat: Node3D
var puppy: PuppyActor
var dugi: DugiActor
var cat: CatActor
var keeper: Node3D
var star: Node3D
var to_island: MeshInstance3D
var to_map: MapIsland
var dialogue: DialogueBox
var shield: Control
var skip_button: Button
var page := -1
var shot := ""
var way := 0.0                     # where the boat is on its way (0..1)
var flicker := 0.0                 # the next island's darkness now (0 bright, 1 dark; tests)
var done := false
var _pages: Array = []
var _glide_from := 0.0
var _glide_to := 0.0
var _glide_t := 0.0
var _flicker_t := 0.0
var _clock := 0.0
var _tint_material: ShaderMaterial


## `island`: the island the voyage goes to (its story has the voyage pages).
func _init(island: String) -> void:
	name = "VoyageScreen"
	to = island
	from = Island.opens_after(island)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pages = Story.pages_of(to, "voyage")
	view = View3D.new()
	view.name = "VoyageView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	view.rig.set_process(false)   # the voyage draws the camera itself
	world = Node3D.new()
	world.name = "VoyageWorld"
	view.set_world(world)
	env = MapIsland.make_environment()
	view.viewport.add_child(env)
	_build_world()
	shield = Control.new()
	shield.name = "VoyageShield"
	shield.mouse_filter = Control.MOUSE_FILTER_STOP
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shield.gui_input.connect(_on_shield_input)
	add_child(shield)
	dialogue = DialogueBox.new("")
	dialogue.name = "VoyageDialogue"
	add_child(dialogue)
	dialogue.closed.connect(_on_dialogue_closed)
	skip_button = Ui.button(Locale.t("story.skip"), "", 56)
	skip_button.name = "SkipButton"
	skip_button.pressed.connect(skip)
	add_child(skip_button)
	resized.connect(_layout)
	_open_page(0)


func _exit_tree() -> void:
	MapIsland.material().set_shader_parameter("lit_mask", 0)


func _build_world() -> void:
	MapIsland.material().set_shader_parameter("lit_mask", 0)   # day: no spot lit
	var from_island := Island.by_id(from)
	MapIsland.new(from_island).build(world, _spots(from_island))
	sea = MapSea.new()
	sea.build(world)
	sea.set_lanterns(false)
	var holder := Node3D.new()
	holder.name = "NextIsland"
	holder.position = TO_AT + Vector3(0.0, -0.02, 0.0)   # its shallows just under the first island's sea
	world.add_child(holder)
	to_map = MapIsland.new(Island.by_id(to))
	to_map.build(holder, _spots(Island.by_id(to)))
	for child in holder.get_children():
		if child.name == "MapSky":
			child.free()   # one sky: the first island's
		elif child.name == "Island":
			to_island = child
	_tint_material = MapIsland.material().duplicate()
	to_island.material_override = _tint_material
	boat = Node3D.new()
	boat.name = "TripBoat"
	boat.scale = Vector3.ONE * BOAT_SCALE
	boat.add_child(ArtKit.instance(MapSea.boat_mesh(ArtPalette.RED), MapIsland.material()))
	world.add_child(boat)
	puppy = PuppyActor.new()
	dugi = DugiActor.new()
	cat = CatActor.new(BreadCat.new())
	for i in 3:
		var actor: Node3D = [puppy, dugi, cat][i]
		boat.add_child(actor)
		actor.scale = Vector3.ONE * ACTOR_ON_BOAT
		actor.position = ABOARD[i]
	keeper = keeper_model()
	keeper.scale = Vector3.ONE * KEEPER_SCALE
	world.add_child(keeper)
	var ground := to_map.height_at(KEEPER_AT.x, KEEPER_AT.y)
	keeper.position = TO_AT + Vector3(KEEPER_AT.x, ground, KEEPER_AT.y)
	keeper.visible = false
	star = StarArt.make(false, STAR_SIZE)
	star.position = STAR_AT
	world.add_child(star)
	_place_boat(0.0)


## The island keeper (the fox, #71) in the storybook look of the cast (ArtKit.toon_material).
static func keeper_model() -> Node3D:
	var model: Node3D = (load("res://assets/characters/fox.glb") as PackedScene).instantiate()
	model.name = "Keeper"
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var mat := mi.mesh.surface_get_material(0) as BaseMaterial3D
		if mat != null and mat.albedo_texture != null:
			mi.material_override = ArtKit.toon_material(mat.albedo_texture)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return model


static func _spots(island: Island) -> Array:
	var spots := []
	for zone in island.zones:
		for spot in island.zones[zone].spots:
			spots.append([spot[0], Vector2(spot[1][0], spot[1][1]), spot[2]])
	return spots


## The boat's place on its way (0..1): along the line from the shore to the beach, bent out a little.
static func way_point(k: float) -> Vector3:
	var end := TO_AT + END_FROM_TO
	return START.lerp(end, k) + Vector3(sin(PI * k) * BEND, 0.0, 0.0)


func _place_boat(k: float) -> void:
	way = clampf(k, 0.0, 1.0)
	var at := way_point(way)
	var ahead := way_point(minf(way + 0.01, 1.0)) - way_point(maxf(way - 0.01, 0.0))
	boat.position = Vector3(at.x, MapIsland.SEA_Y + 0.04 * sin(_clock * 2.1), at.z)
	boat.rotation = Vector3(0.0, atan2(ahead.x, ahead.z), 0.03 * sin(_clock * 1.7))


# --- pages ---------------------------------------------------------------------------------------

func _open_page(i: int) -> void:
	if i >= _pages.size():
		finish()
		return
	page = i
	var entry: Dictionary = _pages[i]
	var new_shot := str(entry.get("shot", "depart"))
	var same: Array = _pages.filter(func(e: Dictionary) -> bool: return str(e.get("shot", "")) == new_shot)
	var j := 0
	for k in i:
		if str(_pages[k].get("shot", "")) == new_shot:
			j += 1
	var span: Array = SHOT_WAY.get(new_shot, [0.0, 0.0])
	_glide_from = lerpf(span[0], span[1], float(j) / same.size())
	_glide_to = lerpf(span[0], span[1], float(j + 1) / same.size())
	_glide_t = 0.0
	if new_shot != shot:
		shot = new_shot
		_flicker_t = 0.0
		_place_boat(_glide_from)
		_pose_cast()
	var who := str(entry.get("who", "dugi"))
	var face := Story.face_or_default(entry.get("face"))
	if who == "puppy" and face == "happy":
		puppy.celebrate()
	dialogue.set_speaker(who, face)
	dialogue.open(str(entry.get("text", "")))
	_layout()


## Who stands where for the shot: the trio look back to the shore as they leave, ahead on the sea,
## at the keeper on the beach; the keeper shows only there.
func _pose_cast() -> void:
	keeper.visible = shot == "arrive"
	star.visible = shot == "depart"
	match shot:
		"depart":
			for actor in [puppy, dugi, cat]:
				_face(actor, view_eye())
		"sea", "flicker":
			puppy.rotation.y = deg_to_rad(-30.0)
			dugi.rotation.y = deg_to_rad(20.0)
			cat.rotation.y = deg_to_rad(-20.0)
		"arrive":
			for actor in [puppy, dugi, cat]:
				_face(actor, keeper.position)
			_face(keeper, way_point(1.0))


func _face(actor: Node3D, target: Vector3) -> void:
	var d := target - actor.global_position if actor.is_inside_tree() else target
	actor.global_rotation.y = atan2(d.x, d.z)


func _on_dialogue_closed() -> void:
	if done:
		return
	_open_page(page + 1)


## Skips to the end (건너뛰기, Android back).
func skip() -> void:
	finish()


## The end: the voyage is seen, the next island is the one in use, App opens its map.
func finish() -> void:
	if done:
		return
	done = true
	if dialogue.active:
		dialogue.close(true)
	Story.mark_voyage_seen(to)
	Island.set_current(to)
	finished.emit(to)


func tap_page() -> void:
	if dialogue.active:
		dialogue.advance()


func _on_shield_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
			and event.device != InputEvent.DEVICE_ID_EMULATION)
	if tap:
		tap_page()
		shield.accept_event()


# --- each frame ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if done:
		return
	_clock += delta
	_glide_t = minf(_glide_t + delta, GLIDE_S)
	var k := _glide_t / GLIDE_S
	_place_boat(lerpf(_glide_from, _glide_to, k * k * (3.0 - 2.0 * k)))
	if shot == "flicker":
		_flicker_t += delta
		flicker = 0.5 - 0.5 * cos(TAU * _flicker_t / FLICKER_S)
	else:
		flicker = 0.0
	_tint_material.set_shader_parameter("own_tint", Vector3.ONE.lerp(DARK_TINT, flicker))
	var eye := view_eye()
	view.rig.look_at_from_position(eye, view_target())
	if star.visible:
		StarArt.face_camera(star, view.rig, _clock)


## The camera of the shot now: from the shore of `from` back at it as they leave, behind the boat
## out on the sea, past the boat at the next island while it flickers, from the beach at the landing.
func view_eye() -> Vector3:
	var at := boat.position
	match shot:
		"sea":
			return at + Vector3(4.5, 3.4, 7.0)
		"flicker":
			return at + Vector3(3.0, 3.0, 6.0)
		"arrive":
			return TO_AT + Vector3(12.0, 3.0, 17.5)
	return START + Vector3(5.5, 2.4, -8.5)


func view_target() -> Vector3:
	var at := boat.position
	match shot:
		"sea":
			return at + Vector3(-0.5, 0.2, -25.0)
		"flicker":
			return TO_AT + Vector3(0.0, 1.5, 0.0)
		"arrive":
			return TO_AT + Vector3(3.2, 0.8, 13.0)
	return START + Vector3(-0.8, 1.6, 4.0)


func _layout() -> void:
	if skip_button == null:
		return
	var inset := Ui.safe_insets(self)
	skip_button.size = skip_button.get_combined_minimum_size()
	skip_button.position = Vector2(size.x - skip_button.size.x - MARGIN - inset.right, MARGIN + inset.top)
	if dialogue.active:
		dialogue.visible = dialogue.layout(Rect2(Vector2.ZERO, size), size.x - MARGIN - inset.right, MARGIN)


## The rects the child sees (tests: on screen, the box clear of 건너뛰기).
func rects() -> Array[Rect2]:
	return [skip_button.get_global_rect(), dialogue.get_global_rect()]
