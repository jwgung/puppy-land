## The 퍼지는 냄새와 잉크 lab's props (#156, 2026-11-15; the approved mockup of #156): meshes only, posed
## from the model by DiffusionLab._redraw(). Curie Island's kitchen (KitchenSet: the open-air table, its jars and pot, the
## meadow) and on the table:
## - a glass of water (GlassCup) with a dropper over it, its red bulb the thing the child presses: a
##   press squeezes the bulb and a blue drop falls into the water; then the ink spreads as a soft blue
##   cloud (GlassCup.show_spread; 2026-11-16 user "그냥 번지는 걸로 가자": no particles in the scene, the
##   particles card shows them) that starts as a dense blob under the dropper, hangs down in strands
##   and grows until the whole glass is evenly blue. A hot glass steams and its cloud sways faster;
## - stage 2 (the PAIR table): a second glass of cold water beside it gets a drop at the same moment
##   (its own little dropper), to compare;
## - stage 3 (the BREAD table): a loaf fresh from the oven on a board, its smell a soft warm haze (one
##   MultiMesh of SoftCloud lumps, joined like smoke) that drifts along the table to Puppy's nose at its
##   right end (the cast's Puppy), the glass of ink beside it;
## - the bread cat on a stack of bread crates on the table, left of the main glass (2026-11-15 user: the
##   bread cat does the lab): while the child presses the bulb it leans over and squeezes the bulb with
##   both paws (CatActor.grab, pressing), and lets go when the finger does; otherwise it watches the glass.
## Where things stand per table: cup_point(), beside_point(), cat_point(), BREAD_AT. How far the clouds
## reach is the model's share; their sway is a picture. Visual only: no body, nothing the model or the
## mission reads.
class_name DiffusionProps
extends RefCounted

## The glasses: their size (m) and where the main one stands on each table (x on the table's top).
const CUP_BOTTOM := 0.5
const CUP_TOP := 0.6
const CUP_HEIGHT := 1.3
const CUP_FILL := 1.05
const CUP_Z := 0.35
const CUP_X := {0: 0.0, 1: -1.2, 2: -1.9}
const BESIDE_X := 1.2
## The loaf on its board (stage 3) and the smell's way from its top to Puppy's nose.
const BREAD_AT := Vector3(-0.3, KitchenSet.TABLE_TOP, 0.45)
const BREAD := Color("e8a85a")
const BREAD_TOP := Color("f6c27a")
const CRUST := Color("b9702e")
const BOARD := Color("a8693a")
## Puppy's nose over his feet (the cast's `puppy.at`), and how high the smell's way bows over the table.
const NOSE_UP := 1.05
const NOSE_IN := Vector3(-0.35, 0.0, 0.1)
const SMELL_BOW := 0.45
## Puppy's place when the definition has no cast (bench runs): the table's right end.
const PUPPY_AT := Vector2(4.0, 1.1)
## The ink: the drop's colour (the dropper's ink a little lighter), the cloud's colour, how fast the
## cloud sways (rad/s) in cold and hot water.
const INK_DEEP := Color("1f3cc4")
const INK_CLOUD := Color("2f5ee0")
const INK_SWAY_COLD := 0.8
const INK_SWAY_HOT := 2.2
## The smell's haze: how many soft lumps along its way (joined), their radius (m) just after the drop
## and once it reaches the nose (the front lump smaller by SMELL_TIP), its colour and density, how far
## (m) and how fast (rad/s) the lumps drift up and down.
const SMELL_HAZE_LUMPS := 10
const SMELL_HAZE_START := 0.2
const SMELL_HAZE_SIZE := 0.55
const SMELL_TIP := 0.6
const SMELL_HAZE := Color("ffcf8a")
const SMELL_HAZE_ALPHA := 0.45
const SMELL_SWAY := 0.06
const SMELL_SWAY_RATE := 1.2
## The dropper: how far its tip is off the glass's middle (towards the cat, still over the water) and
## how high over the rim it hangs, its tube and bulb (short and low: the cat's paws reach the bulb);
## the drop's fall (s) and the bulb's squeeze (s to squeeze or spring back, share).
const DROPPER_X := -0.35
const DROPPER_UP := 0.04
const TUBE := Vector2(0.075, 0.3)
const BULB := 0.15
const GLASS_TUBE := Color("e9f4fa")
const BULB_RED := Color("e0483f")
const BULB_TOP := Color("ff6a5a")
const FALL_S := 0.35
const SQUEEZE_S := 0.3
const SQUEEZE := 0.35
## The bread cat: how far left of the main glass's foot it stands (its crates clear of the glass) and
## how high its crates lift it over the table's top (its shoulders level with the bulb); how hard it
## presses (CatActor.grab's effort) and how far it may lean forward over the glass (deg).
const CAT_FROM_CUP := 1.0
const CAT_STAND := 1.08
const CAT_PRESS := 1.0
const CAT_LEAN_MAX := 45.0

var cat: CatActor
var cat_stand: CatCrates
var cup: GlassCup
var beside: GlassCup
var smell_haze: MultiMeshInstance3D
## Each haze lump's centre (world) now (tests).
var haze_points := PackedVector3Array()
var dropper: Node3D             # the main dropper (its bulb is the press target)
var beside_dropper: Node3D
var bread: Node3D
var drops: Array[MeshInstance3D] = []
var nose := Vector3(PUPPY_AT.x, NOSE_UP, PUPPY_AT.y) + NOSE_IN
## What is shown now (tests): the table, the hot glass, the shares (0..1) of the ink, the cold glass and
## the smell, a drop in.
var shown_site := -1.0
var shown_hot := false
var shown_ink := 0.0
var shown_beside := 0.0
var shown_smell := 0.0
var shown_dropped := false
## The cat squeezes the bulb now (the finger presses it), with this effort (0 when it lets go); how far
## the bulbs are squeezed now (their scale across the paws is 1 - this, up to SQUEEZE).
var pressing := false
var shown_effort := 0.0
var shown_squeeze := 0.0
var _squeeze_k := 0.0           # 0..1 of the way into the squeeze
var _drop_at := -10.0
var _t := 0.0


## Builds the kitchen and everything on the table for `lab`; Puppy's nose from its cast (`puppy.at`).
func build(lab: Node3D, puppy_at: Variant = null) -> void:
	if puppy_at is Array and (puppy_at as Array).size() == 2:
		nose = Vector3(float(puppy_at[0]), NOSE_UP, float(puppy_at[1])) + NOSE_IN
	KitchenSet.build(lab)
	cup = GlassCup.new(CUP_BOTTOM, CUP_TOP, CUP_HEIGHT, CUP_FILL)
	cup.name = "Cup"
	lab.add_child(cup)
	beside = GlassCup.new(CUP_BOTTOM, CUP_TOP, CUP_HEIGHT, CUP_FILL)
	beside.name = "ColdCup"
	lab.add_child(beside)
	for glass: GlassCup in [cup, beside]:
		glass.drop_x = DROPPER_X
	dropper = _dropper(lab, "Dropper")
	beside_dropper = _dropper(lab, "ColdDropper")
	beside_dropper.scale = Vector3.ONE * 0.75
	for parent: Node3D in [cup, beside]:
		var drop := ArtKit.instance(_drop_mesh())
		drop.name = "Drop"
		drop.visible = false
		parent.add_child(drop)
		drops.append(drop)
	bread = Node3D.new()
	bread.name = "Bread"
	bread.position = BREAD_AT
	lab.add_child(bread)
	bread.add_child(ArtKit.instance(bread_mesh()))
	smell_haze = MultiMeshInstance3D.new()
	smell_haze.name = "SmellHaze"
	smell_haze.multimesh = MultiMesh.new()
	smell_haze.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	smell_haze.multimesh.mesh = SoftCloud.mesh()
	smell_haze.multimesh.instance_count = SMELL_HAZE_LUMPS
	smell_haze.material_override = SoftCloud.material(SMELL_HAZE, SMELL_HAZE_ALPHA, GlassCup.CLOUD_PRIORITY)
	smell_haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smell_haze.visible = false
	lab.add_child(smell_haze)
	haze_points.resize(SMELL_HAZE_LUMPS)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = cup
	# Square crates: the bag stays on them facing the front (watching) or the bulb (pressing).
	var side := maxf(cat.look.footprint.x, cat.look.footprint.y)
	cat_stand = CatCrates.new(Vector2(side, side))
	lab.add_child(cat_stand)
	_place_cat()


## Where the main glass stands (its foot, world) on table `site`.
static func cup_point(site: float) -> Vector3:
	return KitchenSet.table_point(float(CUP_X.get(int(site), 0.0)), CUP_Z)


static func beside_point() -> Vector3:
	return KitchenSet.table_point(BESIDE_X, CUP_Z)


## The dropper's tip (world) over the glass at `foot`: where its drop falls from.
static func tip_point(foot: Vector3) -> Vector3:
	return foot + Vector3(DROPPER_X, CUP_HEIGHT + DROPPER_UP, 0.0)


## The dropper's bulb (world) over the glass at `foot`: what the child presses (and the cat squeezes).
static func bulb_point(foot: Vector3) -> Vector3:
	return tip_point(foot) + Vector3(0.0, TUBE.y + BULB * 0.6, 0.0)


## Where the bread cat stands (its base on its crates, world) beside the glass at `foot`.
static func cat_point(foot: Vector3) -> Vector3:
	return foot + Vector3(-CAT_FROM_CUP, CAT_STAND, 0.0)


## Where the cat's paws ([right, left], world) squeeze the bulb at `bulb` from `root`: on its sides
## across the cat's facing, pressed in as far as the bulb is squeezed (`squeeze`: its scale across the
## paws is 1 - squeeze).
static func paw_points(bulb: Vector3, root: Vector3, squeeze: float) -> Array[Vector3]:
	var f := Vector3(bulb.x - root.x, 0.0, bulb.z - root.z).normalized()
	var right := Vector3(-f.z, 0.0, f.x)   # the actor's right paw side (facing +z: -x)
	var half := BULB * (1.0 - squeeze)
	return [bulb + right * half, bulb - right * half] as Array[Vector3]


## The finger presses the bulb (`on`): the cat squeezes it, or lets go and stands back up.
func press(on: bool) -> void:
	if on == pressing:
		return
	pressing = on
	shown_effort = CAT_PRESS if on else 0.0
	if on:
		_grab()
	else:
		cat.let_go(Vector3.ZERO)


## The smell's way (world) at `u` (0 over the loaf .. 1 at Puppy's nose): a low arc over the table.
func smell_point(u: float) -> Vector3:
	var from := BREAD_AT + Vector3(0.0, 0.55, 0.0)
	return from.lerp(nose, u) + Vector3.UP * SMELL_BOW * sin(PI * u)


## Poses everything for the model now: the table (`site`), hot water, how far the ink (0..1), the cold
## glass's ink and the smell have spread, and whether a drop is in.
func show(site: float, hot: bool, ink_share: float, beside_share: float, smell_share: float, dropped: bool) -> void:
	if dropped and not shown_dropped:
		_new_drop()
	shown_dropped = dropped
	if site != shown_site:
		shown_site = site
		cup.position = cup_point(site)
		beside.position = beside_point()
		beside.visible = site == DiffusionModel.PAIR
		beside_dropper.visible = beside.visible
		bread.visible = site == DiffusionModel.BREAD
		dropper.position = bulb_point(cup.position)
		beside_dropper.position = tip_point(beside.position) + Vector3(0.0, TUBE.y + BULB * 0.6, 0.0) * beside_dropper.scale.y
		_place_cat()
	shown_hot = hot
	cup.set_hot(hot)
	beside.set_hot(false)
	shown_ink = ink_share
	shown_beside = beside_share
	shown_smell = smell_share
	cup.sway_rate = INK_SWAY_HOT if hot else INK_SWAY_COLD
	beside.sway_rate = INK_SWAY_COLD
	cup.show_spread(ink_share, INK_CLOUD)
	beside.show_spread(beside_share, INK_CLOUD)
	smell_haze.visible = dropped and bread.visible and smell_share > 0.0
	_place_haze()


## A new drop: the bulbs squeeze and the drops fall.
func _new_drop() -> void:
	_drop_at = _t


## The cat on its crates beside the main glass: squeezing the bulb while the finger presses it,
## otherwise standing (facing the front, watching the glass).
func _place_cat() -> void:
	var root := cat_point(cup.position)
	if pressing:
		_grab()
	else:
		cat.stand(root)
		cat.advance(0.0)
	cat_stand.fit(cat, KitchenSet.TABLE_TOP)


## Both paws on the bulb's sides (squeezed in as far as the bulb now), the cat facing it, pressing.
func _grab() -> void:
	var root := cat_point(cup.position)
	var bulb := dropper.position
	cat.grab(root, CatActor.facing(root, bulb), paw_points(bulb, root, shown_squeeze), CAT_PRESS, CAT_LEAN_MAX)


## The clouds sway, the steam rises, the drop falls and the bulbs squeeze (`delta` s): squeezed in
## while the cat presses (a new drop), springing back once it lets go; squeezed across the paws (the
## bulb narrows along z between them and bulges the other ways).
func advance(delta: float) -> void:
	_t += delta
	cup.advance(delta)
	beside.advance(delta)
	_place_haze()
	var since := _t - _drop_at
	# Held at least SQUEEZE_S after a drop, so a quick tap still squeezes the bulb.
	var target := 1.0 if shown_dropped and (pressing or since < SQUEEZE_S) else 0.0
	_squeeze_k = move_toward(_squeeze_k, target, delta / SQUEEZE_S)
	shown_squeeze = SQUEEZE * sin(PI * 0.5 * _squeeze_k)
	var s := shown_squeeze
	for d: Node3D in [dropper, beside_dropper]:
		var bulb := d.get_child(1) as Node3D
		bulb.scale = Vector3(1.0 + s * 0.4, 1.0 + s * 0.2, 1.0 - s)
	if pressing:
		_grab()
	for i in drops.size():
		var glass: GlassCup = cup if i == 0 else beside
		var fall := clampf(since / FALL_S, 0.0, 1.0)
		drops[i].visible = shown_dropped and since < FALL_S and glass.visible
		var top := CUP_HEIGHT + DROPPER_UP
		drops[i].position = Vector3(glass.drop_x, lerpf(top, glass.drop_point().y, fall * fall), 0.0)


## The smell's haze where the model's share puts its front now: lumps evenly along the way from over
## the loaf to the front, growing as it goes, the front one smaller, drifting gently up and down.
func _place_haze() -> void:
	if not smell_haze.visible:
		return
	var front := shown_smell
	var size := lerpf(SMELL_HAZE_START, SMELL_HAZE_SIZE, front)
	for i in SMELL_HAZE_LUMPS:
		var u := i / float(SMELL_HAZE_LUMPS - 1)
		var phase := _t * SMELL_SWAY_RATE + i * 1.3
		var at := smell_point(front * u) + Vector3.UP * SMELL_SWAY * sin(phase)
		var r := size * lerpf(1.0, SMELL_TIP, u) * (1.0 + 0.06 * sin(phase * 1.4))
		haze_points[i] = at
		smell_haze.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * r), at))


# --- meshes -------------------------------------------------------------------------------------------

## A dropper (named `node_name`) added to `lab`: its glass tube (child 0) under its red bulb (child 1).
## The node's origin is the bulb's middle.
func _dropper(lab: Node3D, node_name: String) -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	lab.add_child(node)
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var tube_top := -BULB * 0.6
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, tube_top - TUBE.y, 0.0)), TUBE.x * 0.45, TUBE.x, TUBE.y, 10, GLASS_TUBE, true, Color.WHITE)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, tube_top - TUBE.y * 0.55, 0.0)), TUBE.x * 0.6, TUBE.x * 0.8, TUBE.y * 0.4, 10, INK_DEEP.lightened(0.15))
	node.add_child(ArtKit.instance(b.commit()))
	var bulb := ArtKit.builder()
	bulb.ao_min = 0.9
	bulb.ao_height = BULB
	bulb.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 1.25, 1.0)), Vector3.ZERO), BULB, 5, 12, BULB_RED)
	bulb.add_cylinder(Transform3D(Basis(), Vector3(0.0, -BULB * 1.1, 0.0)), TUBE.x * 1.25, TUBE.x * 1.25, BULB * 0.4, 10, BULB_TOP)
	node.add_child(ArtKit.instance(bulb.commit()))
	return node


static func _drop_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 1.3, 1.0)), Vector3.ZERO), 0.06, 3, 8, INK_DEEP)
	return b.commit()


## A round loaf on a wooden board (its foot at the origin): a golden dome, three slashes in its crust
## and wisps of warmth over it.
static func bread_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.4
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.04, 0.0)), Vector3(1.5, 0.08, 0.9), 0.03, 1, BOARD, BOARD.lightened(0.15))
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.6, 0.62)), Vector3(0.0, 0.1, 0.0)), 0.62, 5, 16, BREAD)
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.9, 0.5, 0.55)), Vector3(0.0, 0.16, 0.0)), 0.62, 4, 16, BREAD_TOP)
	for k in 3:
		var x := (k - 1) * 0.3
		b.add_rounded_box(Transform3D(Basis(Vector3.FORWARD, 0.5), Vector3(x, 0.47 - 0.04 * absf(k - 1), 0.12)), Vector3(0.05, 0.22, 0.05), 0.02, 1, CRUST)
	return b.commit()
