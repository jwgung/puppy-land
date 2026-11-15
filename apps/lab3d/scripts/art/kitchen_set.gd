## The kitchen of Curie Island's kitchen village (#156, 2026-11-15; docs/islands/curie.md "부엌 마을",
## the approved mockup of #156): an open-air kitchen corner on the meadow, the stage of the island's
## kitchen labs (diffusion, then dissolving, melting and cooking, the dough). One static mesh:
## - a big wooden table (its top at TABLE_TOP), long enough for two glasses and a loaf, with a row of
##   jars (the island's potion colours) and a copper pot on the grass at its left (2026-11-15 user: no wall standing
##   in the meadow "집처럼").
## build() adds the sky, the island's corner (ArtKit.add_world) and this set to a lab; a lab places its
## own things on the table (table_point()). Visual only: no body.
class_name KitchenSet
extends RefCounted

## The island's corner round this point.
const WORLD_CENTER := Vector3(0.0, 0.0, -2.0)
const TABLE_TOP := 1.0
const TABLE_AT := Vector3(0.0, 0.0, 0.3)
const TABLE_SIZE := Vector3(6.6, 0.14, 2.2)
const TABLE_TOP_COLOR := Color("dba468")
const JARS := [Color("ff5fa2"), Color("36c2b4"), Color("ffc61a"), Color("9b6bff")]
const POT := Color("d9824a")


## Adds the sky, the island's corner round WORLD_CENTER and the kitchen set to `lab`; returns the set.
static func build(lab: Node3D) -> MeshInstance3D:
	ArtKit.add_world(lab, WORLD_CENTER)
	var room := ArtKit.instance(room_mesh())
	room.name = "Kitchen"
	lab.add_child(room)
	return room


## A point on the table's top at (x, z) (world).
static func table_point(x: float, z := TABLE_AT.z) -> Vector3:
	return Vector3(x, TABLE_TOP, z)


## The jars, the pot and the table.
static func room_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 1.2
	# A row of jars (the island's potion colours) and the pot on the grass at the back left of the table.
	var back := Vector3(-4.6, 0.0, -0.6)   # on the grass, left of the table (the glasses stand in front of the table's back)
	for k in JARS.size():
		var at := back + Vector3(k * 0.45, 0.0, 0.0)
		var c: Color = JARS[k]
		b.add_cylinder(Transform3D(Basis(), at), 0.15, 0.15, 0.36 + 0.06 * (k % 2), 10, c, true, c.lightened(0.3))
		b.add_cylinder(Transform3D(Basis(), at + Vector3(0.0, 0.36 + 0.06 * (k % 2), 0.0)), 0.1, 0.1, 0.08, 8, ArtPalette.WOOD)
	b.add_cylinder(Transform3D(Basis(), back + Vector3(-0.8, 0.0, 0.0)), 0.3, 0.24, 0.42, 14, POT, true, POT.lightened(0.2))
	# The table: four legs and a thick top.
	b.ao_min = 0.8
	b.ao_height = TABLE_TOP
	var half := TABLE_SIZE * 0.5
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.add_cylinder(Transform3D(Basis(), TABLE_AT + Vector3(sx * (half.x - 0.3), 0.0, sz * (half.z - 0.25))), 0.1, 0.09, TABLE_TOP - TABLE_SIZE.y, 6, ArtPalette.WOOD_GRAIN)
	b.ao_min = 0.95
	b.add_rounded_box(Transform3D(Basis(), TABLE_AT + Vector3(0.0, TABLE_TOP - TABLE_SIZE.y * 0.5, 0.0)), TABLE_SIZE, 0.05, 1, ArtPalette.WOOD, TABLE_TOP_COLOR)
	return b.commit()
