## 퍼피랜드's sea around 과학섬 (the story "별 조각 찾기", 2026-10-28): a few small low-poly islands far
## out on the sea and three little boats near the coast, each with a lantern on its mast. The
## prologue's wide shot shows the country of islands; at night the lanterns are what is seen of the
## boats (lost while the star is broken); the finale lights them again and they sail.
##
## Cheap for SM-P200: the far islands are one static mesh in the map's material (MapIsland.material:
## the map's light, the story's night tint), each boat one small mesh, each lantern a tiny glowing
## sphere (StarArt.glow_material: it stays bright at night). All of it lies outside the map's
## default view (the islands 60 m and more away, the boats beyond the shallows), so the child's map
## draws none of it unless the camera is turned low. Nothing moves unless the story moves it.
class_name MapSea
extends RefCounted

## Far islands [x, z, radius, hills]: most behind 과학섬 from the default view (-z), some to the sides.
const ISLANDS := [
	[-62.0, -78.0, 7.0, 2], [58.0, -96.0, 9.0, 3], [-118.0, -150.0, 12.0, 3], [128.0, -36.0, 8.0, 2],
	[12.0, -170.0, 14.0, 4], [-150.0, 18.0, 9.0, 2], [95.0, 70.0, 7.0, 2], [-88.0, -18.0, 5.0, 1],
]
## Boats [x, z, heading deg, hull colour]: around the coast, beyond the shallow ring.
const BOATS := [[-21.0, 15.0, 30.0, ArtPalette.RED], [24.0, 13.0, -60.0, ArtPalette.BLUE], [19.0, -21.0, 150.0, ArtPalette.ORANGE]]
const LANTERN_Y := 2.05
const SEED := 1028

var islands: MeshInstance3D
var boats: Array[Node3D] = []
var lanterns: Array[MeshInstance3D] = []
var boat_homes: Array[Vector3] = []


## Builds the far islands and the boats under `world`.
func build(world: Node3D) -> void:
	var b := ArtKit.builder()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for spec in ISLANDS:
		_island(b, Vector3(spec[0], MapIsland.SEA_Y, spec[1]), float(spec[2]), int(spec[3]), rng)
	islands = ArtKit.instance(b.commit(), MapIsland.material())
	islands.name = "FarIslands"
	world.add_child(islands)
	var lantern_mesh := _lantern_mesh()
	for spec in BOATS:
		var boat := Node3D.new()
		boat.name = "Boat"
		boat.position = Vector3(spec[0], MapIsland.SEA_Y, spec[1])
		boat.rotation.y = deg_to_rad(spec[2])
		boat.add_child(ArtKit.instance(boat_mesh(spec[3]), MapIsland.material()))
		var lantern := ArtKit.instance(lantern_mesh, StarArt.glow_material())
		lantern.name = "Lantern"
		lantern.position = Vector3(0.0, LANTERN_Y, 0.15)
		boat.add_child(lantern)
		world.add_child(boat)
		boats.append(boat)
		lanterns.append(lantern)
		boat_homes.append(boat.position)


## Lanterns on or off (on at night in the prologue and after the finale).
func set_lanterns(on: bool) -> void:
	for lantern in lanterns:
		lantern.visible = on


## The boats back where they rest.
func rest_boats() -> void:
	for i in boats.size():
		boats[i].position = boat_homes[i]


## A far island: a sand ring sloping into the sea, green hills (faceted cones), a tree or two.
func _island(b: ArtMeshBuilder, at: Vector3, radius: float, hills: int, rng: RandomNumberGenerator) -> void:
	b.ao_min = 0.9
	b.ao_height = 0.6
	b.add_cylinder(Transform3D(Basis(), at + Vector3.DOWN * 0.3), radius * 1.12, radius, 0.6, 9, ArtPalette.SAND)
	b.add_cylinder(Transform3D(Basis(), at + Vector3.UP * 0.25), radius * 0.92, radius * 0.7, radius * 0.18, 9, ArtPalette.GRASS, true, ArtPalette.GRASS_TOP)
	for i in hills:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, radius * 0.4)
		var h := radius * rng.randf_range(0.35, 0.7)
		var base := at + Vector3(cos(a) * r, radius * 0.18 + 0.2, sin(a) * r)
		b.add_cylinder(Transform3D(Basis(), base), radius * rng.randf_range(0.3, 0.45), 0.0, h, 7, ArtPalette.GRASS, true, ArtPalette.LEAF_LIGHT)
	for i in 2:
		var a := rng.randf() * TAU
		var p := at + Vector3(cos(a) * radius * 0.55, radius * 0.18 + 0.2, sin(a) * radius * 0.55)
		b.add_cylinder(Transform3D(Basis(), p), 0.35, 0.3, 1.8, 5, ArtPalette.TRUNK)
		b.add_sphere(Transform3D(Basis(), p + Vector3.UP * 2.5), 1.4, 3, 6, ArtPalette.LEAF)


# --- the boat ------------------------------------------------------------------------------------
# A little storybook sailing boat (#75, 2026-11-06 user: "배는 좀만 더 이쁘게"): a lofted hull with a
# sheer line rising to the bow, a cream band with round windows under a cream rim, a darker bottom, a
# wooden deck, a mast with a gold knob, a billowed main sail on a boom, a small fore sail and a gold
# pennant. Local: bow +z, the waterline y 0, the mast at z 0.15 (the lantern at LANTERN_Y on it). The
# map's boats and the voyage's boat (VoyageScreen, bigger) are this one; no words or marks on it.

## The hull's stations from the stern to the bow [z, half width, rim y, keel y].
const HULL := [[-1.2, 0.47, 0.66, 0.12], [-0.85, 0.59, 0.59, 0.03], [-0.2, 0.63, 0.555, 0.0],
	[0.5, 0.57, 0.585, 0.02], [1.0, 0.37, 0.67, 0.1], [1.38, 0.05, 0.8, 0.3]]
const BOAT_CREAM := Color("fff6e6")
const BOAT_WINDOW := Color("2f3f8f")
const BOAT_GOLD := ArtPalette.YELLOW
const RIM := 0.08          # m the rim reaches in from the hull's side
const DECK_DROP := 0.05    # m the deck lies under the rim


## The boat's mesh with a `hull` colour (its bottom a darker shade of it).
static func boat_mesh(hull: Color) -> ArrayMesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	_hull(b, hull, BOAT_CREAM, hull.darkened(0.22), ArtPalette.WOOD)
	_windows(b, 3)
	_mast(b, LANTERN_Y + 0.1)
	_sail(b)
	_jib(b)
	_pennant(b)
	return b.commit()


## A hull section at station `st` on one `side` (-1 / 1): rim, under the band, bilge, near the keel, keel.
static func _section(st: Array, side: float) -> Array:
	var z: float = st[0]
	var w: float = st[1]
	var top: float = st[2]
	var keel: float = st[3]
	return [Vector3(side * w, top, z), Vector3(side * w * 0.98, top - 0.13, z),
		Vector3(side * w * 0.84, lerpf(keel, top, 0.42), z), Vector3(side * w * 0.48, keel + 0.04, z), Vector3(0.0, keel, z)]


static func _quad(b: ArtMeshBuilder, q: Array, color: Color, facing: Vector3) -> void:
	b.add_triangle([q[0], q[1], q[2]], [color, color, color], facing)
	b.add_triangle([q[0], q[2], q[3]], [color, color, color], facing)


## The hull's sides in bands (the cream band, the hull colour twice, the dark bottom), the transom, the
## closed bow, the cream rim and the deck a little under it.
static func _hull(b: ArtMeshBuilder, color: Color, band: Color, bottom: Color, deck: Color) -> void:
	var bands := [band, color, color, bottom]
	var stern: Array = HULL[0]
	for side in [-1.0, 1.0]:
		for i in HULL.size() - 1:
			var p := _section(HULL[i], side)
			var q := _section(HULL[i + 1], side)
			for k in 4:
				var quad := [p[k], q[k], q[k + 1], p[k + 1]]
				var c: Vector3 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
				_quad(b, quad, bands[k], c - Vector3(0.0, 0.35, c.z))
		var s := _section(stern, side)
		var mid := Vector3(0.0, (float(stern[2]) + float(stern[3])) * 0.5, stern[0])
		var shade := color.darkened(0.08)
		for k in 4:
			b.add_triangle([mid, s[k], s[k + 1]], [shade, shade, shade], Vector3.FORWARD)
		b.add_triangle([mid, s[0], Vector3(0.0, stern[2], stern[0])], [band, band, band], Vector3.FORWARD)
	var l := _section(HULL[-1], -1.0)
	var r := _section(HULL[-1], 1.0)
	for k in 4:
		_quad(b, [l[k], r[k], r[k + 1], l[k + 1]], bands[k], Vector3.BACK)
	for i in HULL.size() - 1:
		var a: Array = HULL[i]
		var c: Array = HULL[i + 1]
		var ia := maxf(float(a[1]) - RIM, 0.0)
		var ic := maxf(float(c[1]) - RIM, 0.0)
		for side in [-1.0, 1.0]:
			_quad(b, [Vector3(side * a[1], a[2], a[0]), Vector3(side * c[1], c[2], c[0]),
				Vector3(side * ic, float(c[2]) - DECK_DROP, c[0]), Vector3(side * ia, float(a[2]) - DECK_DROP, a[0])], BOAT_CREAM, Vector3.UP)
		_quad(b, [Vector3(-ia, float(a[2]) - DECK_DROP, a[0]), Vector3(ia, float(a[2]) - DECK_DROP, a[0]),
			Vector3(ic, float(c[2]) - DECK_DROP, c[0]), Vector3(-ic, float(c[2]) - DECK_DROP, c[0])], deck, Vector3.UP)
	var ist := maxf(float(stern[1]) - RIM, 0.0)
	_quad(b, [Vector3(-stern[1], stern[2], stern[0]), Vector3(stern[1], stern[2], stern[0]),
		Vector3(ist, float(stern[2]) - DECK_DROP, stern[0]), Vector3(-ist, float(stern[2]) - DECK_DROP, stern[0])], BOAT_CREAM, Vector3.UP)


## Round windows (a cream ring round a navy glass) along the cream band, both sides.
static func _windows(b: ArtMeshBuilder, count: int) -> void:
	var across := Basis(Vector3.BACK, PI * 0.5)   # the cylinder's axis along x
	for side in [-1.0, 1.0]:
		for i in count:
			var z := lerpf(-0.75, 0.55, float(i) / maxf(count - 1, 1))
			var w := _along(z, 1)
			var y := _along(z, 2) - 0.2
			b.add_cylinder(Transform3D(across, Vector3(side * (w * 0.93 + 0.004), y, z)), 0.085, 0.085, 0.03, 8, BOAT_CREAM)
			b.add_cylinder(Transform3D(across, Vector3(side * (w * 0.93 + 0.02), y, z)), 0.058, 0.058, 0.03, 8, BOAT_WINDOW)


## The hull's half width (`field` 1) or rim height (`field` 2) at `z`.
static func _along(z: float, field: int) -> float:
	for i in HULL.size() - 1:
		if z <= HULL[i + 1][0]:
			var k := inverse_lerp(HULL[i][0], HULL[i + 1][0], z)
			return lerpf(HULL[i][field], HULL[i + 1][field], k)
	return HULL[-1][field]


## The mast (up to `height`, a gold knob on top) and the boom along the sail's foot.
static func _mast(b: ArtMeshBuilder, height: float) -> void:
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.5, 0.15)), 0.055, 0.045, height - 0.5, 6, ArtPalette.TRUNK)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, height, 0.15)), 0.07, 2, 6, BOAT_GOLD)
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.86, -0.83)), 0.035, 0.035, 0.98, 5, ArtPalette.TRUNK)


## The main sail aft of the mast, billowed to one side: a triangle in 4 rows, both faces.
static func _sail(b: ArtMeshBuilder) -> void:
	var tack := Vector3(0.0, 0.9, 0.08)
	var head := Vector3(0.0, 1.92, 0.1)
	var clew := Vector3(0.0, 0.9, -0.78)
	var rows := 4
	var grid: Array = []
	for j in rows + 1:
		var v := float(j) / rows
		var cols := rows - j
		var row: Array = []
		for i in cols + 1:
			var u := float(i) / cols if cols > 0 else 0.0
			var p := tack.lerp(head, v).lerp(clew.lerp(head, v), u)
			p.x = 0.16 * sin(PI * u) * (1.0 - v)
			row.append(p)
		grid.append(row)
	for j in rows:
		var lo: Array = grid[j]
		var hi: Array = grid[j + 1]
		for facing in [Vector3.RIGHT, Vector3.LEFT]:
			var c: Color = BOAT_CREAM if facing == Vector3.RIGHT else BOAT_CREAM.darkened(0.06)
			for i in hi.size():
				b.add_triangle([lo[i], lo[i + 1], hi[i]], [c, c, c], facing)
				if i + 1 < hi.size():
					b.add_triangle([lo[i + 1], hi[i + 1], hi[i]], [c, c, c], facing)


## The small fore sail from the mast to the bow.
static func _jib(b: ArtMeshBuilder) -> void:
	var p := [Vector3(0.0, 1.75, 0.2), Vector3(0.0, 0.82, 0.28), Vector3(0.0, 0.82, 1.15)]
	var mid: Vector3 = (p[0] + p[2]) * 0.5 + Vector3(-0.08, -0.05, 0.0)
	for facing in [Vector3.RIGHT, Vector3.LEFT]:
		var c: Color = BOAT_CREAM if facing == Vector3.RIGHT else BOAT_CREAM.darkened(0.06)
		b.add_triangle([p[0], p[1], mid], [c, c, c], facing)
		b.add_triangle([p[1], p[2], mid], [c, c, c], facing)


## The pennant at the mast head, streaming aft.
static func _pennant(b: ArtMeshBuilder) -> void:
	var p := [Vector3(0.0, LANTERN_Y + 0.05, 0.13), Vector3(0.0, LANTERN_Y - 0.13, 0.13), Vector3(0.04, LANTERN_Y - 0.05, -0.32)]
	b.add_triangle(p, [BOAT_GOLD, BOAT_GOLD, BOAT_GOLD], Vector3.RIGHT)
	var c := BOAT_GOLD.darkened(0.08)
	b.add_triangle(p, [c, c, c], Vector3.LEFT)


static func _lantern_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D.IDENTITY, 0.22, 3, 6, StarArt.MID)
	return b.commit()
