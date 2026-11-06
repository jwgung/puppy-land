## A little storybook sailing boat (#75, 2026-11-06 user: "배는 좀만 더 이쁘게", mock A): a lofted
## hull with a sheer line rising to the bow, a cream band with round windows under a cream rim, a
## darker bottom, a wooden deck, a mast with a gold knob and a boom, a billowed main sail, a small
## fore sail and a gold pennant. One mesh in the map's material; no words or marks on it.
## Local space: bow +z, the waterline y 0, the mast at MAST_Z (the lantern of MapSea at LANTERN_Y on it).
## The map's three boats (MapSea) and the voyage's boat (VoyageScreen, bigger) are this one.
class_name BoatArt
extends RefCounted

## Where the night lantern sits on the mast (MapSea).
const LANTERN_Y := 2.05
const MAST_Z := 0.15
## The hull's stations from the stern to the bow [z, half width, rim y, keel y].
const HULL := [[-1.2, 0.47, 0.66, 0.12], [-0.85, 0.59, 0.59, 0.03], [-0.2, 0.63, 0.555, 0.0],
	[0.5, 0.57, 0.585, 0.02], [1.0, 0.37, 0.67, 0.1], [1.38, 0.05, 0.8, 0.3]]
## A section's band under the rim (m) and its bilge (share of the rim height above the keel).
const BAND_DEPTH := 0.13
const BAND_TUCK := 0.98
const BILGE_TUCK := 0.84
const BILGE_HEIGHT := 0.42
const KEEL_TUCK := 0.48
const KEEL_LIFT := 0.04
## Seen from the side the hull's middle (for which way a side face looks).
const HULL_MIDDLE_Y := 0.35
const RIM := 0.08          # m the rim reaches in from the hull's side
const DECK_DROP := 0.05    # m the deck lies under the rim
const BOTTOM_DARKER := 0.22
const TRANSOM_DARKER := 0.08
const SAIL_BACK_DARKER := 0.06
const PENNANT_BACK_DARKER := 0.08
const AO_MIN := 0.9

const CREAM := Color("fff6e6")
const WINDOW := Color("2f3f8f")
const GOLD := ArtPalette.YELLOW

## Round windows along the cream band: COUNT a side from WINDOW_Z_FROM to WINDOW_Z_TO, under the rim.
const WINDOW_COUNT := 3
const WINDOW_Z_FROM := -0.75
const WINDOW_Z_TO := 0.55
const WINDOW_DROP := 0.2
const WINDOW_OUT := 0.93
const WINDOW_RING := 0.085
const WINDOW_GLASS := 0.058
const WINDOW_DEPTH := 0.03
const WINDOW_SIDES := 8

## The mast (from MAST_FOOT up to MAST_TOP, its knob there) and the boom along the sail's foot.
const MAST_FOOT := 0.5
const MAST_TOP := LANTERN_Y + 0.1
const MAST_RADIUS := [0.055, 0.045]
const KNOB_RADIUS := 0.07
const BOOM_AT := Vector3(0.0, 0.86, -0.83)
const BOOM_RADIUS := 0.035
const BOOM_LENGTH := 0.98

## The main sail: a triangle (tack at the mast foot, head up the mast, clew aft) in SAIL_ROWS rows,
## billowed SAIL_BILLOW m to one side in its middle.
const SAIL_TACK := Vector3(0.0, 0.9, 0.08)
const SAIL_HEAD := Vector3(0.0, 1.92, 0.1)
const SAIL_CLEW := Vector3(0.0, 0.9, -0.78)
const SAIL_ROWS := 4
const SAIL_BILLOW := 0.16
## The fore sail from the mast to the bow, its middle pushed out a little.
const JIB := [Vector3(0.0, 1.75, 0.2), Vector3(0.0, 0.82, 0.28), Vector3(0.0, 0.82, 1.15)]
const JIB_BELLY := Vector3(-0.08, -0.05, 0.0)
## The pennant at the mast head, streaming aft.
const PENNANT := [Vector3(0.0, LANTERN_Y + 0.05, 0.13), Vector3(0.0, LANTERN_Y - 0.13, 0.13), Vector3(0.04, LANTERN_Y - 0.05, -0.32)]


## The boat's mesh with a `hull` colour (its bottom a darker shade of it).
static func mesh(hull: Color) -> ArrayMesh:
	var b := ArtKit.builder()
	b.ao_min = AO_MIN
	_hull(b, hull, CREAM, hull.darkened(BOTTOM_DARKER), ArtPalette.WOOD)
	_windows(b)
	_mast(b)
	_sail(b)
	_jib(b)
	_pennant(b)
	return b.commit()


## One single-coloured triangle facing `facing`.
static func _tri(b: ArtMeshBuilder, points: Array, color: Color, facing: Vector3) -> void:
	b.add_triangle(points, [color, color, color], facing)


static func _quad(b: ArtMeshBuilder, q: Array, color: Color, facing: Vector3) -> void:
	_tri(b, [q[0], q[1], q[2]], color, facing)
	_tri(b, [q[0], q[2], q[3]], color, facing)


## A hull section at station `st` on one `side` (-1 / 1): rim, under the band, bilge, near the keel, keel.
static func _section(st: Array, side: float) -> Array:
	var z: float = st[0]
	var w: float = st[1]
	var top: float = st[2]
	var keel: float = st[3]
	return [Vector3(side * w, top, z), Vector3(side * w * BAND_TUCK, top - BAND_DEPTH, z),
		Vector3(side * w * BILGE_TUCK, lerpf(keel, top, BILGE_HEIGHT), z), Vector3(side * w * KEEL_TUCK, keel + KEEL_LIFT, z), Vector3(0.0, keel, z)]


## The deck's edge at station `st` on one `side`: RIM in from the side, DECK_DROP under the rim.
static func _deck_edge(st: Array, side: float) -> Vector3:
	return Vector3(side * maxf(float(st[1]) - RIM, 0.0), float(st[2]) - DECK_DROP, st[0])


static func _rim_edge(st: Array, side: float) -> Vector3:
	return Vector3(side * st[1], st[2], st[0])


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
				_quad(b, quad, bands[k], c - Vector3(0.0, HULL_MIDDLE_Y, c.z))
		var s := _section(stern, side)
		var mid := Vector3(0.0, (float(stern[2]) + float(stern[3])) * 0.5, stern[0])
		var shade := color.darkened(TRANSOM_DARKER)
		for k in 4:
			_tri(b, [mid, s[k], s[k + 1]], shade, Vector3.FORWARD)
		_tri(b, [mid, s[0], Vector3(0.0, stern[2], stern[0])], band, Vector3.FORWARD)
	var l := _section(HULL[-1], -1.0)
	var r := _section(HULL[-1], 1.0)
	for k in 4:
		_quad(b, [l[k], r[k], r[k + 1], l[k + 1]], bands[k], Vector3.BACK)
	for i in HULL.size() - 1:
		var a: Array = HULL[i]
		var c: Array = HULL[i + 1]
		for side in [-1.0, 1.0]:
			_quad(b, [_rim_edge(a, side), _rim_edge(c, side), _deck_edge(c, side), _deck_edge(a, side)], CREAM, Vector3.UP)
		_quad(b, [_deck_edge(a, -1.0), _deck_edge(a, 1.0), _deck_edge(c, 1.0), _deck_edge(c, -1.0)], deck, Vector3.UP)
	_quad(b, [_rim_edge(stern, -1.0), _rim_edge(stern, 1.0), _deck_edge(stern, 1.0), _deck_edge(stern, -1.0)], CREAM, Vector3.UP)


## Round windows (a cream ring round a navy glass) along the cream band, both sides.
static func _windows(b: ArtMeshBuilder) -> void:
	var across := Basis(Vector3.BACK, PI * 0.5)   # the cylinder's axis along x
	for side in [-1.0, 1.0]:
		for i in WINDOW_COUNT:
			var z := lerpf(WINDOW_Z_FROM, WINDOW_Z_TO, float(i) / maxf(WINDOW_COUNT - 1, 1))
			var w := _along(z, 1)
			var y := _along(z, 2) - WINDOW_DROP
			b.add_cylinder(Transform3D(across, Vector3(side * (w * WINDOW_OUT + 0.004), y, z)), WINDOW_RING, WINDOW_RING, WINDOW_DEPTH, WINDOW_SIDES, CREAM)
			b.add_cylinder(Transform3D(across, Vector3(side * (w * WINDOW_OUT + 0.02), y, z)), WINDOW_GLASS, WINDOW_GLASS, WINDOW_DEPTH, WINDOW_SIDES, WINDOW)


## The hull's half width (`field` 1) or rim height (`field` 2) at `z`.
static func _along(z: float, field: int) -> float:
	for i in HULL.size() - 1:
		if z <= HULL[i + 1][0]:
			var k := inverse_lerp(HULL[i][0], HULL[i + 1][0], z)
			return lerpf(HULL[i][field], HULL[i + 1][field], k)
	return HULL[-1][field]


static func _mast(b: ArtMeshBuilder) -> void:
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, MAST_FOOT, MAST_Z)), MAST_RADIUS[0], MAST_RADIUS[1], MAST_TOP - MAST_FOOT, 6, ArtPalette.TRUNK)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, MAST_TOP, MAST_Z)), KNOB_RADIUS, 2, 6, GOLD)
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), BOOM_AT), BOOM_RADIUS, BOOM_RADIUS, BOOM_LENGTH, 5, ArtPalette.TRUNK)


## The main sail aft of the mast, billowed to one side: SAIL_ROWS rows of triangles, both faces.
static func _sail(b: ArtMeshBuilder) -> void:
	var grid: Array = []
	for j in SAIL_ROWS + 1:
		var v := float(j) / SAIL_ROWS
		var cols := SAIL_ROWS - j
		var row: Array = []
		for i in cols + 1:
			var u := float(i) / cols if cols > 0 else 0.0
			var p := SAIL_TACK.lerp(SAIL_HEAD, v).lerp(SAIL_CLEW.lerp(SAIL_HEAD, v), u)
			p.x = SAIL_BILLOW * sin(PI * u) * (1.0 - v)
			row.append(p)
		grid.append(row)
	for j in SAIL_ROWS:
		var lo: Array = grid[j]
		var hi: Array = grid[j + 1]
		for facing in [Vector3.RIGHT, Vector3.LEFT]:
			var c: Color = CREAM if facing == Vector3.RIGHT else CREAM.darkened(SAIL_BACK_DARKER)
			for i in hi.size():
				_tri(b, [lo[i], lo[i + 1], hi[i]], c, facing)
				if i + 1 < hi.size():
					_tri(b, [lo[i + 1], hi[i + 1], hi[i]], c, facing)


static func _jib(b: ArtMeshBuilder) -> void:
	var mid: Vector3 = (JIB[0] + JIB[2]) * 0.5 + JIB_BELLY
	for facing in [Vector3.RIGHT, Vector3.LEFT]:
		var c: Color = CREAM if facing == Vector3.RIGHT else CREAM.darkened(SAIL_BACK_DARKER)
		_tri(b, [JIB[0], JIB[1], mid], c, facing)
		_tri(b, [JIB[1], JIB[2], mid], c, facing)


static func _pennant(b: ArtMeshBuilder) -> void:
	_tri(b, PENNANT, GOLD, Vector3.RIGHT)
	_tri(b, PENNANT, GOLD.darkened(PENNANT_BACK_DARKER), Vector3.LEFT)
