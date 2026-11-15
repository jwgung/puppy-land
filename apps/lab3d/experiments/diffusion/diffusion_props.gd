## The 퍼지는 냄새와 잉크 lab's props (#156, 2026-11-15; the approved mockup of #156): meshes only, posed
## from the model by DiffusionLab._redraw(). Curie Island's kitchen (KitchenSet: the open-air table, its jars and pot, the
## meadow) and on the table:
## - a glass of water (GlassCup) with a dropper over it, its red bulb the thing the child presses: a
##   press squeezes the bulb and a blue drop falls into the water; then the ink spreads as blue dots
##   (ParticleCloud, the 알갱이) jiggling out from under the water's top and a soft blue cloud that grows
##   until the whole glass is blue. A hot glass steams and its dots jiggle harder;
## - stage 2 (the PAIR table): a second glass of cold water beside it gets a drop at the same moment
##   (its own little dropper), to compare;
## - stage 3 (the BREAD table): a loaf fresh from the oven on a board, its smell as golden puffs that go
##   along the table to Puppy's nose at its right end (the cast's Puppy), the glass of ink beside it;
## - the bread cat in front on the left, watching the glass.
## Where things stand per table: cup_point(), beside_point(), BREAD_AT. The dots are random (a picture);
## how far they reach is the model's share. Visual only: no body, nothing the model or the mission reads.
class_name DiffusionProps
extends RefCounted

## The glasses: their size (m) and where the main one stands on each table (x on the table's top).
const CUP_BOTTOM := 0.5
const CUP_TOP := 0.6
const CUP_HEIGHT := 1.3
const CUP_FILL := 1.05
const CUP_Z := 0.35
const CUP_X := {0: 0.0, 1: -1.2, 2: -2.2}
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
## The ink: dots per glass, their size and colour, the cloud's colour; how hard the dots jiggle (m/s
## per axis) in cold and hot water and how far they wander from their place (m).
const INK_DOTS := 70
const INK_DOT := 0.045
const INK := Color("1c2a96")
const INK_CLOUD := Color("2a3cb0")
const JIGGLE_COLD := 0.35
const JIGGLE_HOT := 1.1
const WOBBLE := 0.07
## The smell: puffs, their size and colour, their jiggle, how wide the band along its way is (m).
const SMELL_PUFFS := 46
const SMELL_PUFF := 0.075
const SMELL := Color("f4b86a")
const SMELL_JIGGLE := 1.6
const SMELL_WOBBLE := 0.12
const SMELL_BAND := 0.3
## The dropper: how high its tip hangs over the glass's rim, its tube and bulb; the drop's fall (s) and
## the bulb's squeeze (s, share).
const DROPPER_UP := 0.3
const TUBE := Vector2(0.075, 0.6)
const BULB := 0.17
const GLASS_TUBE := Color("e9f4fa")
const BULB_RED := Color("e0483f")
const BULB_TOP := Color("ff6a5a")
const FALL_S := 0.35
const SQUEEZE_S := 0.3
const SQUEEZE := 0.35
## The bread cat in front on the left.
const CAT_AT := Vector3(-3.7, 0.0, 1.8)

var cat: CatActor
var cup: GlassCup
var beside: GlassCup
var ink: ParticleCloud
var beside_ink: ParticleCloud
var smell: ParticleCloud
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
	ink = ParticleCloud.new(INK_DOTS, INK_DOT, INK, 156)
	ink.name = "Ink"
	cup.add_child(ink)
	beside_ink = ParticleCloud.new(INK_DOTS, INK_DOT, INK, 157)
	beside_ink.name = "Ink"
	beside.add_child(beside_ink)
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
	smell = ParticleCloud.new(SMELL_PUFFS, SMELL_PUFF, SMELL, 158)
	smell.name = "Smell"
	lab.add_child(smell)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = cup
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Where the main glass stands (its foot, world) on table `site`.
static func cup_point(site: float) -> Vector3:
	return KitchenSet.table_point(float(CUP_X.get(int(site), 0.0)), CUP_Z)


static func beside_point() -> Vector3:
	return KitchenSet.table_point(BESIDE_X, CUP_Z)


## The dropper's bulb (world) over the glass at `foot`: what the child presses.
static func bulb_point(foot: Vector3) -> Vector3:
	return foot + Vector3(0.0, CUP_HEIGHT + DROPPER_UP + TUBE.y + BULB * 0.6, 0.0)


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
		beside_dropper.position = beside.position + (bulb_point(Vector3.ZERO) - Vector3(0.0, BULB * 0.6, 0.0)) * 0.75 + Vector3(0.0, BULB * 0.6 * 0.75, 0.0) + Vector3(0.0, (CUP_HEIGHT + DROPPER_UP) * 0.25, 0.0)
	shown_hot = hot
	cup.set_hot(hot)
	beside.set_hot(false)
	shown_ink = ink_share
	shown_beside = beside_share
	shown_smell = smell_share
	cup.show_spread(ink_share, INK_CLOUD)
	beside.show_spread(beside_share, INK_CLOUD)
	ink.show_count(ink.capacity() if dropped else 0)
	beside_ink.show_count(beside_ink.capacity() if dropped and beside.visible else 0)
	smell.show_count(smell.capacity() if dropped and bread.visible else 0)
	_place_dots(0.0)


## A new drop: the dots start again at the water's top, the bulbs squeeze and the drops fall.
func _new_drop() -> void:
	_drop_at = _t
	for cloud: ParticleCloud in [ink, beside_ink, smell]:
		cloud.scatter_homes()


## The dots jiggle, the steam rises, the drop falls and the bulbs squeeze (`delta` s).
func advance(delta: float) -> void:
	_t += delta
	cup.advance(delta)
	beside.advance(delta)
	_place_dots(delta)
	var since := _t - _drop_at
	var squeeze := SQUEEZE * sin(PI * clampf(since / SQUEEZE_S, 0.0, 1.0))
	for d: Node3D in [dropper, beside_dropper]:
		var bulb := d.get_child(1) as Node3D
		bulb.scale = Vector3(1.0 + squeeze * 0.4, 1.0 - squeeze, 1.0 + squeeze * 0.4)
	for i in drops.size():
		var glass: GlassCup = cup if i == 0 else beside
		var fall := clampf(since / FALL_S, 0.0, 1.0)
		drops[i].visible = shown_dropped and since < FALL_S and glass.visible
		var top := CUP_HEIGHT + DROPPER_UP
		drops[i].position = Vector3(0.0, lerpf(top, glass.drop_point().y, fall * fall), 0.0)


## Each cloud's dots where the model's shares put them now, with their jiggle.
func _place_dots(delta: float) -> void:
	var speed := JIGGLE_HOT if shown_hot else JIGGLE_COLD
	_spread_in(ink, cup, shown_ink, speed, delta)
	_spread_in(beside_ink, beside, shown_beside, JIGGLE_COLD, delta)
	if smell.shown() > 0:
		var front := shown_smell
		smell.spread(delta, SMELL_JIGGLE, SMELL_WOBBLE, func(home: Vector3, jiggle: Vector3) -> Vector3:
			# Along the way up to the front (the home's x picks how far), across it by the home's y and z.
			var u := front * clampf(home.x * 0.5 + 0.5, 0.0, 1.0)
			return smell_point(u) + Vector3(0.0, home.y, home.z) * SMELL_BAND + jiggle)


## The ink's dots in `glass`: out from under the water's top to `share` of the way through it.
func _spread_in(cloud: ParticleCloud, glass: GlassCup, share: float, speed: float, delta: float) -> void:
	if cloud.shown() == 0:
		return
	var box := glass.water_box()
	var start := glass.drop_point()
	var reach := maxf(share, 0.04) * Vector3(box.z * 1.6, box.y - box.x, box.z * 1.6)
	var centre := start.lerp(Vector3(0.0, (box.x + box.y) * 0.5, 0.0), share)
	cloud.spread(delta, speed, WOBBLE, func(home: Vector3, jiggle: Vector3) -> Vector3:
		return ParticleCloud.in_cylinder(centre + home * reach + jiggle, Vector3.ZERO, box.z, box.x, box.y))


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
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, tube_top - TUBE.y * 0.55, 0.0)), TUBE.x * 0.6, TUBE.x * 0.8, TUBE.y * 0.4, 10, INK_CLOUD.lightened(0.2))
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
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 1.3, 1.0)), Vector3.ZERO), 0.06, 3, 8, INK)
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
