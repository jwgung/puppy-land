## The hutton island's sundial dial on the map (#106, 2026-11-09 user decisions): before the finale the
## sundial is broken (the map's static mesh draws only its stone base and empty plate) and the golden
## wedges found so far lean round the base, glinting (they arrive there from the spots); the finale
## flies them one by one into their places on the plate, the bread cat brings the gnomon (해시계 바늘) and
## the child plants it; after the finale the dial is whole with the gnomon's shadow on it.
##
## Draws: the leaning wedges are ONE merged pair (body and outline in the star pieces' glow and outline materials, StarArt: two draws
## whatever their number); the whole dial is the golden plate and the gnomon in the map's material (one
## draw) and the shadow (one draw, shown once the sun is back). Placed at the sundial's foot
## (MapIsland.sundial_foot); local +y up. Visual only.
class_name SundialDial
extends Node3D

const WEDGES := SundialArt.WEDGES
## A wedge lying in its place on the plate, and one leaning on the base: SundialArt sizes (its point
## SPAN from the arc, the dial's radius in the plate).
const SLOT_SIZE := MapLandmarks.DIAL_RADIUS / SundialArt.SPAN
const LEAN_SIZE := 0.22
const LEAN_RADIUS := 0.72          # m from the base's middle to a leaning wedge's point (outside its wide step)
const LEAN_TILT := deg_to_rad(16.0)   # its lean towards the base
const LEAN_FRONT := 0.9            # its face turned this much towards the front (+z: the map's default view)
## The leaning wedges' places round the base (deg, 0 = +x, the map's screen right, 90 = +z the front):
## on its two sides, filling in turn (the front is the three friends' row, the back hides behind it).
const LEAN_ANGLES := [181.0, -1.0, 163.0, 17.0, 199.0, -19.0, 145.0, 35.0, 217.0, -37.0]

var leaning := 0                   # wedges leaning on the base now
var whole := false
var loose: Node3D = null           # the merged leaning wedges
var plate: MeshInstance3D          # the golden dial on the plate (no gnomon)
var full: MeshInstance3D           # the dial with the gnomon
var shadow: MeshInstance3D


func _init() -> void:
	name = "SundialDial"
	var b := ArtKit.builder()
	MapLandmarks.sundial_dial(b, Transform3D.IDENTITY)
	plate = ArtKit.instance(b.commit(), MapIsland.material())
	plate.name = "Plate"
	add_child(plate)
	b = ArtKit.builder()
	MapLandmarks.sundial_dial(b, Transform3D.IDENTITY)
	MapLandmarks.gnomon(b, Transform3D.IDENTITY)
	full = ArtKit.instance(b.commit(), MapIsland.material())
	full.name = "Whole"
	add_child(full)
	b = ArtKit.builder()
	MapLandmarks.gnomon_shadow(b, Transform3D.IDENTITY)
	shadow = ArtKit.instance(b.commit(), MapIsland.material())
	shadow.name = "Shadow"
	add_child(shadow)
	show_leaning(0)


## Before the finale: `count` wedges lean on the base (the first `count` of LEAN_ANGLES), no dial.
func show_leaning(count: int) -> void:
	leaning = clampi(count, 0, WEDGES)
	whole = false
	plate.visible = false
	full.visible = false
	shadow.visible = false
	if loose != null:
		loose.queue_free()
		loose = null
	if leaning > 0:
		var places: Array = []
		for i in leaning:
			places.append(lean_transform(i))
		loose = merged(places)
		loose.name = "Leaning"
		add_child(loose)


## The plate is golden again (the wedges in their places), the gnomon not yet planted.
func show_plate() -> void:
	show_leaning(0)
	plate.visible = true


## The whole sundial: the dial and the gnomon; its shadow when `lit` (the sun is back).
func show_whole(lit := true) -> void:
	show_leaning(0)
	whole = true
	full.visible = true
	shadow.visible = lit
	shadow.transform = Transform3D.IDENTITY


## The shadow widens sideways from the gnomon's foot line as the sun rises (`share` 0..1 of its reach).
func grow_shadow(share: float) -> void:
	var k := clampf(share, 0.0, 1.0)
	shadow.visible = k > 0.0
	# Widened sideways from the fin's foot line (x = 0, where the shadow starts) to its full reach.
	shadow.transform = Transform3D(Basis().scaled(Vector3(maxf(k, 0.001), 1.0, 1.0)), Vector3.ZERO)


## Wedge `i` leaning on the base, standing on its point, its face outwards and to the front (local).
static func lean_transform(i: int) -> Transform3D:
	var a := deg_to_rad(float(LEAN_ANGLES[i % LEAN_ANGLES.size()]))
	var out := Vector3(cos(a), 0.0, sin(a))
	var up := Vector3.UP * cos(LEAN_TILT) - out * sin(LEAN_TILT)
	var facing := (out + Vector3.BACK * LEAN_FRONT).normalized()
	var side := up.cross(facing).normalized()
	var basis := Basis(side, up, side.cross(up)).scaled(Vector3.ONE * LEAN_SIZE)
	var point := out * LEAN_RADIUS + Vector3.UP * 0.02
	return Transform3D(basis, point + up * LEAN_SIZE)   # the point 1 size below the wedge's centre


## Wedge `i` lying in its place on the plate, its point at the dial's middle, face up (local).
static func slot_transform(i: int) -> Transform3D:
	var a := TAU * (i + 0.5) / WEDGES
	var d := Vector3(cos(a), 0.0, sin(a))
	var basis := Basis(d.cross(Vector3.UP), d, Vector3.UP).scaled(Vector3.ONE * SLOT_SIZE)
	return Transform3D(basis, Vector3.UP * (MapLandmarks.DIAL_Y + 0.03) + d * SLOT_SIZE)


## The gnomon planted (local): where the carried needle (needle_node) ends.
static func gnomon_transform() -> Transform3D:
	return Transform3D.IDENTITY


## The wedges at `places` (local transforms of a radius-1 wedge) as one body and one outline.
static func merged(places: Array) -> Node3D:
	var meshes := SundialArt.piece_meshes()
	var root := Node3D.new()
	for k in 2:
		var st := SurfaceTool.new()
		for xf: Transform3D in places:
			st.append_from(meshes[k], 0, xf)
		var mi := ArtKit.instance(st.commit(), StarArt.glow_material() if k == 0 else StarArt.outline_material())
		mi.name = "Body" if k == 0 else "Outline"
		root.add_child(mi)
	return root


## The gnomon as a node of its own (the finale: it stands on the new land, the cat carries it, the
## child plants it), in the map's material; its origin is the sundial's foot it is drawn for (so
## gnomon_transform puts it in place).
static func needle_node() -> MeshInstance3D:
	var b := ArtKit.builder()
	MapLandmarks.gnomon(b, Transform3D.IDENTITY)
	var mi := ArtKit.instance(b.commit(), MapIsland.material())
	mi.name = "Needle"
	return mi


## The gnomon's middle (local to needle_node): to hold it by.
static func needle_middle() -> Vector3:
	var g := MapLandmarks.GNOMON_AT
	return Vector3(g.x, g.y + MapLandmarks.GNOMON_HEIGHT * 0.4, g.z - 0.05)   # (about the fin's middle: its tall edge is north, -z)
