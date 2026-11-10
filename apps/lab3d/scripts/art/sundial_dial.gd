## The hutton island's sundial dial on the map (#106, 2026-11-09 user decisions; #114 2026-11-10 user:
## "해시계 조각을 수집하는데, 이걸 바닥에 놓지말구 원래 판에 하나씩 맞춰지게 해줘. 진행하면서 채워지는게
## 보이도록"): before the finale the sundial is broken (the map's static mesh draws only its stone base and
## empty plate) and every golden wedge found so far fills its own sector of the dial (it flies there from
## its spot: slot_transform), so the dial fills as the island is explored; the finale's dial is whole but
## for the gnomon (해시계 바늘), which the bread cat brings and the child plants; after the finale the dial
## is whole with the gnomon's shadow on it.
##
## Draws: the filled sectors are one mesh in the map's material (rebuilt when a wedge lands); the whole
## dial is the plate and the gnomon (one draw) and the shadow (one draw, shown once the sun is back).
## Placed at the sundial's foot (MapIsland.sundial_foot); local +y up. Visual only.
class_name SundialDial
extends Node3D

const WEDGES := SundialArt.WEDGES
## A wedge lying in its place on the plate: SundialArt sizes (its point SPAN from the arc, the dial's
## radius in the plate).
const SLOT_SIZE := MapLandmarks.DIAL_RADIUS / SundialArt.SPAN

var filled := 0                    # wedges in their places on the plate now
var whole := false
var plate: MeshInstance3D          # the filled sectors of the dial (all of them: no gnomon yet)
var full: MeshInstance3D           # the dial with the gnomon
var shadow: MeshInstance3D


func _init() -> void:
	name = "SundialDial"
	plate = MeshInstance3D.new()
	plate.name = "Plate"
	plate.material_override = MapIsland.material()
	add_child(plate)
	var b := ArtKit.builder()
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
	show_filled(0)


## Before the finale: the first `count` wedges in their sectors of the dial, no gnomon.
func show_filled(count: int) -> void:
	filled = clampi(count, 0, WEDGES)
	whole = false
	full.visible = false
	shadow.visible = false
	var b := ArtKit.builder()
	MapLandmarks.sundial_dial(b, Transform3D.IDENTITY, filled)
	plate.mesh = b.commit() if filled > 0 else null
	plate.visible = filled > 0


## The plate is whole again (every wedge in its place), the gnomon not yet planted.
func show_plate() -> void:
	show_filled(WEDGES)


## The whole sundial: the dial and the gnomon; its shadow when `lit` (the sun is back).
func show_whole(lit := true) -> void:
	show_filled(0)
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


## Wedge `i` lying in its place on the plate, its point at the dial's middle, face up (local).
static func slot_transform(i: int) -> Transform3D:
	var a := TAU * (i + 0.5) / WEDGES
	var d := Vector3(cos(a), 0.0, sin(a))
	var basis := Basis(d.cross(Vector3.UP), d, Vector3.UP).scaled(Vector3.ONE * SLOT_SIZE)
	return Transform3D(basis, Vector3.UP * (MapLandmarks.DIAL_Y + 0.03) + d * SLOT_SIZE)


## The gnomon planted (local): where the carried needle (needle_node) ends.
static func gnomon_transform() -> Transform3D:
	return Transform3D.IDENTITY


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
