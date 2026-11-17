## The 빵 반죽 부풀리기 lab's props (#159, 2026-11-17; the approved mockup of #157-#159, "2-3. #159 반죽"):
## meshes only, posed from the model by DoughLab._redraw(). Curie Island's kitchen (KitchenSet) with:
## - a bowl of dough (a cream bowl with a blue band) in the table's middle, the thing the child moves:
##   dragged along the table to the warm place by the oven (left) or into the fridge (right). The dough
##   is a soft round lump: it rises as a column and its top swells like a mushroom once it is over the
##   rim; a dough with yeast shows little yeast specks at first and gas bubbles as it rises, one without
##   yeast is smooth and stays flat. A dashed orange line round the bowl at twice the dough's height
##   (no word, no number) shows "twice" in the stages that ask for it;
## - the brick oven on the grass behind the table's left end: fire and a warm shimmer in its mouth while
##   the bowl stands by it; in front of it on the table the warm place (an orange dashed ring);
## - the high shelf right over the warm place (a post behind the table, a board reaching over the bowl):
##   the piece lies on it (DoughGame), so only a dough rising by the oven can reach it;
## - the fridge on the grass behind the table's right end: its door swings open while the bowl comes to
##   it and the bowl stands inside (a little smaller: the mockup's), cold mist at its opening; the cold
##   place on the table in front of it (a blue dashed ring). The rings show while the bowl is carried or
##   still on the table;
## - the time sign behind the table on the right (TimeSign: the time runs once the bowl is put down) and
##   the night over the scene (SceneNight);
## - the bread cat on its crates behind the bowl's way, watching the bowl.
## Visual only: no body, nothing the model or the mission reads.
class_name DoughProps
extends RefCounted

## The bowl: its way along the table (z), its start (x), its size (bottom radius, top radius, height),
## colours.
const BOWL_Z := 0.5
const START_X := 0.25
const BOWL := Vector3(0.3, 0.45, 0.42)
const BOWL_COLOR := Color("f4ead8")
const BOWL_BAND := Color("4d8fd6")
## The dough: its top over the bowl's foot per volume unit (m: twice the volume, twice as high), the
## column's radius, the cap's height and its radius at the start and at the shelf (a mushroom), colours.
const DOUGH_UNIT := 0.5
const COLUMN_R := 0.37
const CAP_H := 0.16
const CAP_R := Vector2(0.4, 0.52)
const DOUGH := Color("f1d39b")
const DOUGH_TOP := Color("f6dca9")
const BUBBLE := Color("fff6dc")
const SPECK := Color("c49a5a")
const BUBBLES := 12
## The "twice" mark: an orange dashed line round the bowl's front at twice the start's height.
const MARK := Color("ff7a2f")
## The warm place (by the oven) and the cold place (in front of the fridge) on the table (x), how near
## (m) a let-go counts as there, the rings' radius.
const WARM_X := -2.0
const COLD_X := 2.75
const CATCH := 0.75
const RING_R := 0.62
const WARM_RING := Color("ff7a2f")
const COLD_RING := Color("4dabf7")
## The oven: its foot's middle on the grass, its size, colours.
const OVEN_AT := Vector3(-2.85, 0.0, -1.45)
const OVEN := Vector3(1.3, 1.25, 1.1)
const BRICK := Color("c8643c")
const BRICK_DARK := Color("7a3520")
const MOUTH := Color("3a1a10")
const FIRE := Color("ff8a1a")
const FIRE_CORE := Color("ffd04a")
## The shelf: its board's underside (the dough's top at SHELF_RISE times the start: it touches there),
## the board's size and where its back is (z).
const SHELF_Y := KitchenSet.TABLE_TOP + DOUGH_UNIT * DoughModel.SHELF_RISE
const BOARD := Vector3(1.5, 0.1, 1.55)
const BOARD_BACK := -1.05
## The fridge: its foot's middle on the grass, its size, the main door's top, its colours, the bowl
## inside it (on its shelf at the table's height) and how small it is drawn there.
const FRIDGE_AT := Vector3(3.4, 0.0, -1.35)
const FRIDGE := Vector3(1.3, 2.6, 0.95)
const FRIDGE_DOOR_TOP := 1.95
const FRIDGE_COLOR := Color("f2f6fa")
const FRIDGE_EDGE := Color("9fb0c2")
const FRIDGE_INSIDE := Color("cfe8ff")
const FRIDGE_SCALE := 0.75
const DOOR_OPEN_DEG := 62.0
## The door opens once the carried bowl is this far right.
const DOOR_FROM_X := 1.9
## The time sign (its bar's middle) and the bread cat (its base on its crates).
const SIGN_AT := Vector3(1.2, 2.35, -0.55)
const CAT_AT := Vector3(-0.75, KitchenSet.TABLE_TOP + 0.78, -0.45)

var cat: CatActor
var cat_stand: CatCrates
var bowl: Node3D
var column: MeshInstance3D
var cap: MeshInstance3D
var bubbles: MultiMeshInstance3D
var specks: MeshInstance3D
var mark: MeshInstance3D
var oven: Node3D
var fire: Node3D
var shimmer: Node3D
var shelf: Node3D
var fridge: Node3D
var door: Node3D
var mist: Node3D
var warm_ring: MeshInstance3D
var cold_ring: MeshInstance3D
var sign: TimeSign
var night := SceneNight.new()
## What is shown now (tests): the bowl's place (world), the dough's volume (times the start), the
## yeast's bubbles, the fridge door (deg open), the fire, the rings, the "twice" mark, the night.
var shown_volume := 1.0
var shown_yeast := true
var shown_door := 0.0
var shown_fire := false
var shown_rings := true
var shown_mark := true
var shown_night := 0.0
var _t := 0.0


func build(lab: Node3D) -> void:
	KitchenSet.build(lab)
	night.attach(lab)
	oven = Node3D.new()
	oven.name = "Oven"
	oven.position = OVEN_AT
	lab.add_child(oven)
	oven.add_child(ArtKit.instance(_oven_mesh()))
	var glow := StarArt.glow_material()
	fire = ArtKit.instance(_fire_mesh(), glow)
	fire.name = "Fire"
	fire.position = Vector3(0.0, KitchenSet.TABLE_TOP - 0.02, OVEN.z * 0.5 + 0.02)
	oven.add_child(fire)
	shimmer = ArtKit.instance(_shimmer_mesh(), _soft_material(Color(1.0, 0.7, 0.28, 0.55)))
	shimmer.name = "Shimmer"
	shimmer.position = Vector3(0.45, OVEN.y + 0.35, OVEN.z * 0.5 + 0.1)
	oven.add_child(shimmer)
	shelf = Node3D.new()
	shelf.name = "Shelf"
	lab.add_child(shelf)
	shelf.add_child(ArtKit.instance(_shelf_mesh()))
	fridge = Node3D.new()
	fridge.name = "Fridge"
	fridge.position = FRIDGE_AT
	lab.add_child(fridge)
	fridge.add_child(ArtKit.instance(_fridge_mesh()))
	door = Node3D.new()
	door.name = "Door"
	door.position = Vector3(FRIDGE.x * 0.5, 0.0, FRIDGE.z * 0.5)   # hinged on its right edge
	fridge.add_child(door)
	door.add_child(ArtKit.instance(_door_mesh()))
	mist = ArtKit.instance(_mist_mesh(), _soft_material(Color(0.8, 0.92, 1.0, 0.6)))
	mist.name = "Mist"
	mist.position = Vector3(0.0, KitchenSet.TABLE_TOP + 0.3, FRIDGE.z * 0.5 + 0.12)
	fridge.add_child(mist)
	warm_ring = ArtKit.instance(_ring_mesh(WARM_RING))
	warm_ring.name = "WarmRing"
	warm_ring.position = KitchenSet.table_point(WARM_X, BOWL_Z) + Vector3.UP * 0.012
	lab.add_child(warm_ring)
	cold_ring = ArtKit.instance(_ring_mesh(COLD_RING))
	cold_ring.name = "ColdRing"
	cold_ring.position = KitchenSet.table_point(COLD_X, BOWL_Z) + Vector3.UP * 0.012
	lab.add_child(cold_ring)
	bowl = Node3D.new()
	bowl.name = "Bowl"
	lab.add_child(bowl)
	column = ArtKit.instance(_column_mesh())
	column.name = "DoughColumn"
	bowl.add_child(column)
	cap = ArtKit.instance(_cap_mesh())
	cap.name = "DoughCap"
	bowl.add_child(cap)
	bowl.add_child(ArtKit.instance(_bowl_mesh()))
	bubbles = MultiMeshInstance3D.new()
	bubbles.name = "Bubbles"
	bubbles.multimesh = MultiMesh.new()
	bubbles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	bubbles.multimesh.mesh = _bubble_mesh()
	bubbles.multimesh.instance_count = BUBBLES
	bubbles.material_override = ArtKit.lit_material()
	bubbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bowl.add_child(bubbles)
	specks = ArtKit.instance(_specks_mesh())
	specks.name = "Specks"
	bowl.add_child(specks)
	mark = ArtKit.instance(_mark_mesh(), DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE))
	mark.name = "TwiceMark"
	mark.position = Vector3(0.0, DOUGH_UNIT * 2.0, 0.0)
	bowl.add_child(mark)
	sign = TimeSign.new(SIGN_AT.y - KitchenSet.TABLE_TOP)
	sign.position = SIGN_AT
	lab.add_child(sign)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = bowl
	var side := maxf(cat.look.footprint.x, cat.look.footprint.y)
	cat_stand = CatCrates.new(Vector2(side, side))
	lab.add_child(cat_stand)
	cat.stand(CAT_AT)
	cat.advance(0.0)
	cat_stand.fit(cat, KitchenSet.TABLE_TOP)


## Where the bowl stands (its foot's middle, world) at spot `spot` (DoughModel.TABLE / WARM / COLD).
static func bowl_point(spot: float) -> Vector3:
	if spot == DoughModel.WARM:
		return KitchenSet.table_point(WARM_X, BOWL_Z)
	if spot == DoughModel.COLD:
		return Vector3(FRIDGE_AT.x, KitchenSet.TABLE_TOP, FRIDGE_AT.z + 0.05)
	return KitchenSet.table_point(START_X, BOWL_Z)


## The bowl's size where it stands (smaller inside the fridge).
static func bowl_scale(spot: float) -> float:
	return FRIDGE_SCALE if spot == DoughModel.COLD else 1.0


## The spot a bowl let go at table x `x` goes to: WARM or COLD when near enough, else -1 (none).
static func spot_at(x: float) -> float:
	if absf(x - WARM_X) <= CATCH:
		return DoughModel.WARM
	if x >= COLD_X - CATCH:
		return DoughModel.COLD
	return -1.0


## The dough's top over the bowl's foot (m) at `volume` times the start.
static func dough_top(volume: float) -> float:
	return DOUGH_UNIT * volume


## Poses everything: the bowl at `spot` (or carried at table x `carried_x`: NAN not carried), the dough
## at `volume` times the start with yeast or not, the "twice" mark shown or not, and the clock.
func show(spot: float, carried_x: float, volume: float, yeast: bool, twice: bool, clock: FastClock) -> void:
	var carried := not is_nan(carried_x)
	if carried:
		bowl.position = KitchenSet.table_point(carried_x, BOWL_Z)
		bowl.scale = Vector3.ONE
	else:
		bowl.position = bowl_point(spot)
		bowl.scale = Vector3.ONE * bowl_scale(spot)
	shown_volume = maxf(volume, 1.0)
	shown_yeast = yeast
	_pose_dough()
	shown_mark = twice
	mark.visible = twice and not (not carried and spot == DoughModel.COLD)
	var open := (not carried and spot == DoughModel.COLD) or (carried and carried_x >= DOOR_FROM_X)
	shown_door = DOOR_OPEN_DEG if open else 0.0
	door.rotation.y = deg_to_rad(shown_door)
	mist.visible = open
	shown_fire = not carried and spot == DoughModel.WARM
	fire.visible = shown_fire
	shimmer.visible = shown_fire
	shown_rings = carried or spot == DoughModel.TABLE
	warm_ring.visible = shown_rings
	cold_ring.visible = shown_rings
	shown_night = clock.night()
	night.set_amount(shown_night)
	sign.show_clock(clock)


## The dough at shown_volume: the column up to the cap, the cap (wider as it rises over the rim), the
## yeast's specks at first and its gas bubbles as it rises (none without yeast).
func _pose_dough() -> void:
	var top := dough_top(shown_volume)
	var middle := top - CAP_H
	var grow := clampf((shown_volume - 1.0) / (DoughModel.SHELF_RISE - 1.0), 0.0, 1.0)
	column.scale = Vector3(1.0, maxf(middle - 0.05, 0.01), 1.0)
	column.position = Vector3(0.0, 0.05, 0.0)
	var r := lerpf(CAP_R.x, CAP_R.y, grow)
	cap.scale = Vector3(r, CAP_H, r)
	cap.position = Vector3(0.0, middle, 0.0)
	specks.visible = shown_yeast and shown_volume < 1.2
	specks.position = Vector3(0.0, top, 0.0)
	var shown := int(round(lerpf(0.0, BUBBLES, grow * 1.6))) if shown_yeast else 0
	bubbles.multimesh.visible_instance_count = mini(shown, BUBBLES)
	for i in BUBBLES:
		var u := fposmod(i * 0.618034, 1.0)
		var v := fposmod(i * 0.414214 + 0.13, 1.0)
		var a := lerpf(-1.1, 1.1, u)   # round the front
		var y := lerpf(0.3, maxf(top - 0.05, 0.3), v)
		var radius := COLUMN_R if y < middle else r * sqrt(maxf(1.0 - pow((y - middle) / CAP_H, 2.0), 0.0))
		var size := 0.035 + 0.03 * fposmod(i * 0.37, 1.0)
		bubbles.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * size),
			Vector3(sin(a) * radius, y, cos(a) * radius)))


## The props' clock: the fire flickers, the shimmer and the mist sway.
func advance(delta: float) -> void:
	_t += delta
	if fire.visible:
		fire.scale = Vector3(1.0, 1.0 + 0.12 * sin(_t * 11.0) + 0.06 * sin(_t * 17.0), 1.0)
	if shimmer.visible:
		shimmer.position.y = OVEN.y + 0.35 + 0.08 * fposmod(_t * 0.6, 1.0)
		shimmer.rotation.z = 0.08 * sin(_t * 2.3)
	if mist.visible:
		mist.position.x = 0.06 * sin(_t * 1.4)


# --- meshes -------------------------------------------------------------------------------------------

static func _soft_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## The bowl: a cream bowl with a blue band (its foot's middle at the origin, open at the top).
static func _bowl_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = BOWL.z
	b.add_cylinder(Transform3D(), BOWL.x, BOWL.y, BOWL.z, 18, BOWL_COLOR, false)
	_bowl_floor(b)
	var band_at := 0.62
	var r := lerpf(BOWL.x, BOWL.y, band_at) + 0.008
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, BOWL.z * band_at - 0.03, 0.0)), r, r + 0.012, 0.06, 18, BOWL_BAND, false)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, BOWL.z - 0.02, 0.0)), BOWL.y + 0.015, BOWL.y + 0.02, 0.04, 18, BOWL_COLOR.darkened(0.06), false)
	return b.commit()


## The bowl's floor (a flat disc a little over its foot).
static func _bowl_floor(b: ArtMeshBuilder) -> void:
	b.add_cylinder(Transform3D(), BOWL.x, BOWL.x, 0.04, 18, BOWL_COLOR)


## The dough's column: a unit-high cylinder (the node scales its height).
static func _column_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 1.0
	b.add_cylinder(Transform3D(), COLUMN_R, COLUMN_R, 1.0, 18, DOUGH, false)
	return b.commit()


## The dough's cap: a unit ball (the node scales it to the cap's radius and height).
static func _cap_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.95
	b.add_sphere(Transform3D(), 1.0, 6, 18, DOUGH_TOP)
	return b.commit()


## A gas bubble: a little pale ball (unit size).
static func _bubble_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), 1.0, 3, 8, BUBBLE)
	return b.commit()


## The yeast's specks on a fresh dough's top: three little brown dots (the mockup's).
static func _specks_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for k in 3:
		b.add_sphere(Transform3D(Basis(), Vector3((k - 1) * 0.16, -0.005, 0.12 + 0.04 * (k % 2))), 0.03, 2, 6, SPECK)
	return b.commit()


## The "twice" mark: an orange dashed line across the bowl's front and a dot at its right end (local:
## at its height, the bowl's middle).
static func _mark_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var z := CAP_R.y + 0.08
	var x := -0.62
	while x < 0.6:
		b.add_rounded_box(Transform3D(Basis(), Vector3(x + 0.06, 0.0, z)), Vector3(0.12, 0.035, 0.02), 0.0, 1, MARK)
		x += 0.2
	ArtKit.disc(b, Vector3(0.72, 0.0, z + 0.01), 0.05, MARK, 12)
	return b.commit()


## A dashed ring on the table (a place to put the bowl down).
static func _ring_mesh(color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var dashes := 14
	for k in dashes:
		var a := TAU * k / dashes
		var at := Vector3(cos(a) * RING_R, 0.0, sin(a) * RING_R * 0.7)
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, -a + PI * 0.5), at), Vector3(0.18, 0.012, 0.05), 0.0, 1, color)
	return b.commit()


## The brick oven (its foot's middle at the origin, its mouth towards the camera): a brick base, a
## dome, brick lines, a dark arched mouth and a chimney at the back.
static func _oven_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = OVEN.y
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, OVEN.y * 0.5, 0.0)), OVEN, 0.08, 2, BRICK, BRICK.lightened(0.08))
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(OVEN.x * 0.5, 0.7, OVEN.z * 0.5)), Vector3(0.0, OVEN.y, 0.0)), 1.0, 6, 16, BRICK)
	for k in 3:
		var y := 0.3 + k * 0.35
		b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, y, OVEN.z * 0.5 + 0.004)), Vector3(OVEN.x - 0.04, 0.035, 0.01), 0.0, 1, BRICK_DARK.lightened(0.25))
	b.add_cylinder(Transform3D(Basis(), Vector3(0.25, OVEN.y + 0.3, -OVEN.z * 0.3)), 0.14, 0.13, 0.95, 8, BRICK_DARK, true, MOUTH)
	# The mouth: a dark arch on the front, from the table's height up.
	var mouth_z := OVEN.z * 0.5 + 0.012
	var bottom := KitchenSet.TABLE_TOP - 0.1
	var half := 0.36
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, bottom + 0.25, mouth_z)), Vector3(half * 2.0, 0.5, 0.01), 0.0, 1, MOUTH)
	var arch := 12
	for k in arch:
		var a0 := PI * k / arch
		var a1 := PI * (k + 1) / arch
		var c := Vector3(0.0, bottom + 0.5, mouth_z)
		b.add_triangle([c, c + Vector3(cos(a1) * half, sin(a1) * half, 0.0), c + Vector3(cos(a0) * half, sin(a0) * half, 0.0)], [MOUTH, MOUTH, MOUTH], Vector3.BACK)
	return b.commit()


## The fire in the oven's mouth: three orange flames with yellow cores (facing the camera; its foot at
## the origin).
static func _fire_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for f: Array in [[-0.14, 0.32, 0.12], [0.02, 0.46, 0.15], [0.17, 0.3, 0.11]]:
		var x: float = f[0]
		var h: float = f[1]
		var w: float = f[2]
		b.add_triangle([Vector3(x - w, 0.0, 0.0), Vector3(x + w, 0.0, 0.0), Vector3(x, h, 0.0)], [FIRE, FIRE, FIRE], Vector3.BACK)
		b.add_triangle([Vector3(x - w * 0.5, 0.0, 0.01), Vector3(x + w * 0.5, 0.0, 0.01), Vector3(x, h * 0.55, 0.01)], [FIRE_CORE, FIRE_CORE, FIRE_CORE], Vector3.BACK)
	return b.commit()


## The warm shimmer: two wavy ribbons rising (facing the camera).
static func _shimmer_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var c := Color.WHITE
	for side: float in [-0.12, 0.14]:
		var prev := Vector3(side, 0.0, 0.0)
		for k in range(1, 9):
			var u := k / 8.0
			var p := Vector3(side + 0.06 * sin(u * TAU), u * 0.6, 0.0)
			var along := p - prev
			var across := Vector3(-along.y, along.x, 0.0).normalized() * 0.022
			b.add_triangle([prev - across, p - across, p + across], [c, c, c], Vector3.BACK)
			b.add_triangle([prev - across, p + across, prev + across], [c, c, c], Vector3.BACK)
			prev = p
	return b.commit()


## The shelf: a post behind the table from the grass up, the board reaching forward over the warm
## place (its underside at SHELF_Y), two brackets under it.
static func _shelf_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = SHELF_Y
	var post := Vector3(WARM_X, 0.0, BOARD_BACK + 0.08)
	b.add_rounded_box(Transform3D(Basis(), post + Vector3(0.0, SHELF_Y * 0.5, 0.0)), Vector3(0.14, SHELF_Y, 0.14), 0.02, 1, ArtPalette.WOOD_GRAIN)
	var board := Vector3(WARM_X, SHELF_Y + BOARD.y * 0.5, BOARD_BACK + BOARD.z * 0.5)
	b.add_rounded_box(Transform3D(Basis(), board), BOARD, 0.03, 1, ArtPalette.WOOD_GRAIN, ArtPalette.WOOD)
	for side: float in [-1.0, 1.0]:
		var at := post + Vector3(side * 0.07, SHELF_Y, 0.0)
		var c := ArtPalette.WOOD_GRAIN
		b.add_triangle([at, at + Vector3(side * 0.45, 0.0, 0.0), at + Vector3(0.0, -0.4, 0.0)], [c, c, c], Vector3.BACK)
	return b.commit()


## The fridge's body (its foot's middle at the origin): a white box, its inside (pale blue, seen when
## the door is open) with a shelf at the table's height, the freezer door on top with its handle.
static func _fridge_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = FRIDGE.y
	var s := FRIDGE
	var wall := 0.06
	# Back, sides, top and bottom round the main compartment; the freezer above it.
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, s.y * 0.5, -s.z * 0.5 + wall * 0.5)), Vector3(s.x, s.y, wall), 0.02, 1, FRIDGE_COLOR)
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(side * (s.x - wall) * 0.5, s.y * 0.5, 0.0)), Vector3(wall, s.y, s.z), 0.02, 1, FRIDGE_COLOR)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, (FRIDGE_DOOR_TOP + s.y) * 0.5, 0.0)), Vector3(s.x, s.y - FRIDGE_DOOR_TOP, s.z), 0.04, 1, FRIDGE_COLOR)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, (KitchenSet.TABLE_TOP - 0.04) * 0.5, 0.0)), Vector3(s.x, KitchenSet.TABLE_TOP - 0.04, s.z), 0.04, 1, FRIDGE_COLOR)
	# The inside: pale blue back and the shelf the bowl stands on.
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, (KitchenSet.TABLE_TOP + FRIDGE_DOOR_TOP) * 0.5, -s.z * 0.5 + wall + 0.005)), Vector3(s.x - wall * 2.0, FRIDGE_DOOR_TOP - KitchenSet.TABLE_TOP, 0.01), 0.0, 1, FRIDGE_INSIDE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, KitchenSet.TABLE_TOP - 0.02, 0.0)), Vector3(s.x - wall * 2.0, 0.04, s.z - 0.04), 0.0, 1, FRIDGE_EDGE, FRIDGE_INSIDE.lightened(0.3))
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, FRIDGE_DOOR_TOP - 0.02, s.z * 0.5 + 0.004)), Vector3(s.x, 0.04, 0.01), 0.0, 1, FRIDGE_EDGE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(s.x * 0.36, FRIDGE_DOOR_TOP + 0.25, s.z * 0.5 + 0.03)), Vector3(0.07, 0.3, 0.05), 0.02, 1, FRIDGE_EDGE)
	return b.commit()


## The main door (local to its hinge on the fridge's right front edge): a white panel to the left with
## a handle near its free edge.
static func _door_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	var h := FRIDGE_DOOR_TOP - KitchenSet.TABLE_TOP + 0.02
	var mid := KitchenSet.TABLE_TOP - 0.02 + h * 0.5
	b.add_rounded_box(Transform3D(Basis(), Vector3(-FRIDGE.x * 0.5, mid, 0.03)), Vector3(FRIDGE.x, h, 0.06), 0.03, 1, FRIDGE_COLOR)
	b.add_rounded_box(Transform3D(Basis(), Vector3(-FRIDGE.x * 0.86, mid + 0.1, 0.09)), Vector3(0.07, 0.4, 0.05), 0.02, 1, FRIDGE_EDGE)
	return b.commit()


## The cold mist at the fridge's opening: a few pale puffs and two little snowflakes (facing the camera).
static func _mist_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var c := Color.WHITE
	for p: Array in [[Vector3(-0.3, 0.0, 0.0), 0.16], [Vector3(-0.05, 0.08, 0.02), 0.2], [Vector3(0.25, -0.02, 0.0), 0.15]]:
		ArtKit.disc(b, p[0], p[1], c, 12)
	for at: Vector3 in [Vector3(-0.32, 0.38, 0.03), Vector3(0.28, 0.5, 0.03)]:
		for k in 3:
			var a := PI * k / 3.0
			var d := Vector3(cos(a), sin(a), 0.0) * 0.07
			var across := Vector3(-d.y, d.x, 0.0).normalized() * 0.012
			b.add_triangle([at - d - across, at + d - across, at + d + across], [c, c, c], Vector3.BACK)
			b.add_triangle([at - d - across, at + d + across, at - d + across], [c, c, c], Vector3.BACK)
	return b.commit()
