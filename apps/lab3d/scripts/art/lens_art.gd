## The curie island's pieces (#154, 2026-11-13 user pick B, the rainbow lens): the rainbow lighthouse's
## round crystal lens cut into Island.LENS_PIECES (11) equal wedges, one per spot 1-11, each its own
## rainbow colour (RAINBOW, by the spot's place in the island's order: the lens fills into a rainbow
## wheel), with a light ring across it (the lens's glass ring), a deeper band along the arc and
## StarArt's cute face; spot 12's piece is the lighthouse's flame (a teardrop of fire with a yellow
## heart and the same face), which lights the lens's middle (LensEmblem).
##
## Drawn like SundialArt (its rim, rounded, at a wedge of 360/11 degrees): a pillow in an unshaded
## material with the light baked into the vertex colours and an outline hull = two draws, no light, no
## texture, no transparency. The 2D card picture (draw_piece_2d) uses the same rims. Visual only.
class_name LensArt
extends RefCounted

const PIECES := Island.LENS_PIECES
const WEDGE_DEG := 360.0 / PIECES
## The eleven colours round the lens (2D: the emblem, the card) from the top clockwise.
const RAINBOW := [Color("ff6b6b"), Color("ff9a3c"), Color("ffd84a"), Color("9ee36a"), Color("5fd38a"),
	Color("4fd1c5"), Color("4fa8ff"), Color("6f8cff"), Color("9b6bff"), Color("d27bff"), Color("ff7bc0")]
## Baked into the 3D pieces this much lighter (the views' tone mapping deepens colours, as SundialArt's).
const LIGHTEN_3D := 0.25
const RING := [0.5, 0.62]            # the glass ring across a wedge (share of the point-to-arc span)
const RING_LIGHT := 0.45             # how much lighter than the wedge
const BAND_DARK := 0.18              # the arc band: how much deeper
const FLAME := Color("ff9a3c")       # the flame piece and the lens's lit middle
const FLAME_HEART := Color("ffe06a")
const FLAME_HEART_K := 0.55          # the heart's share of the flame, about FLAME_HEART_AT
const FLAME_HEART_AT := Vector2(0.0, -0.25)
const FLAME_FACE_AT := Vector2(0.0, -0.3)
const FLAME_STEPS := 48

static var _meshes: Dictionary = {}   # slot -> [body, outline]
static var _flame_rim: Array = []


## The colour of the piece in `slot` (its spot's place in the order, from 0; the flame's past the lens).
static func color_of(slot: int) -> Color:
	return FLAME if slot >= PIECES else RAINBOW[maxi(slot, 0)]


## The wedge's rim: SundialArt's rounded wedge at an eleventh of the disc.
static func rim() -> Array:
	return SundialArt.rim_of(WEDGE_DEG)


## The flame's rim in the xy plane (counter-clockwise): a teardrop, its round foot about 1 below the
## centre (it lands on it like the star on its point) and its tip up.
static func flame_rim() -> Array:
	if _flame_rim.is_empty():
		for i in FLAME_STEPS:
			var t := TAU * (1.0 - float(i) / FLAME_STEPS)   # counter-clockwise from the tip
			var x := 0.95 * sin(t) * pow(absf(sin(t * 0.5)), 1.3)
			_flame_rim.append(Vector2(x, 1.25 * cos(t) + 0.25))
	return _flame_rim


## The glass ring across a wedge face whose rim is shrunk by `k`: the arc strip from RING[0] to RING[1]
## of the span, a little inside the wedge's sides.
static func ring(k: float) -> PackedVector2Array:
	var apex := SundialArt.CENTRE + (SundialArt.APEX - SundialArt.CENTRE) * k
	var half := deg_to_rad(WEDGE_DEG * 0.5) * 0.8
	var steps := 8
	var poly := PackedVector2Array()
	for s in steps + 1:
		var a := lerpf(-half, half, float(s) / steps)
		poly.append(apex + Vector2(sin(a), cos(a)) * SundialArt.SPAN * k * RING[1])
	for s in range(steps, -1, -1):
		var a := lerpf(-half, half, float(s) / steps)
		poly.append(apex + Vector2(sin(a), cos(a)) * SundialArt.SPAN * k * RING[0])
	return poly


## [body mesh, outline mesh] of the piece in `slot` (radius 1, the xy plane, facing +z), cached.
static func piece_meshes(slot: int) -> Array:
	var key := clampi(slot, 0, PIECES)   # every slot past the lens is the flame (and none is below the first)
	if not _meshes.has(key):
		var flame := key >= PIECES
		var points := flame_rim() if flame else rim()
		var face := color_of(key).lerp(Color.WHITE, LIGHTEN_3D)
		_meshes[key] = [_pillow(points, SundialArt.DEPTH, face, flame, true),
			_pillow(SundialArt.outset(points, SundialArt.OUTLINE_W), SundialArt.DEPTH * (1.0 + SundialArt.OUTLINE_W * 2.5), face, flame, false)]
	return _meshes[key]


## A pillow: `points` (z = 0) rising to the flat face (shrunk by SundialArt.SHRINK about the wedge's
## or the `flame`'s middle) at z = +-depth in `face`; its decoration (the ring and the band, or the
## flame's heart, and the face) on both sides when `dress` (not on the outline). SundialArt._pillow's
## shape with the piece's own colours.
static func _pillow(points: Array, depth: float, face: Color, flame: bool, dress: bool) -> ArrayMesh:
	var b := ArtKit.builder()
	var sun := Vector3(-0.45, 0.7, 0.55).normalized()
	var about := FLAME_HEART_AT if flame else SundialArt.CENTRE
	var top2: Array = points.map(func(p: Vector2) -> Vector2: return about + (p - about) * SundialArt.SHRINK)
	var centre := Vector3(about.x, about.y, 0.0)
	var deep := face.darkened(0.2)
	var light := face.lerp(Color.WHITE, 0.5)
	var n_rim := points.size()
	for side: float in [1.0, -1.0]:
		var z := depth * side
		var facing := Vector3(0.0, 0.0, side)
		for i in n_rim:
			var p0: Vector2 = points[i]
			var p1: Vector2 = points[(i + 1) % n_rim]
			var q0: Vector2 = top2[i]
			var q1: Vector2 = top2[(i + 1) % n_rim]
			var r0 := Vector3(p0.x, p0.y, 0.0)
			var r1 := Vector3(p1.x, p1.y, 0.0)
			var t0 := Vector3(q0.x, q0.y, z)
			var t1 := Vector3(q1.x, q1.y, z)
			var n := (r1 - r0).cross(t0 - r0).normalized()
			if n.dot(r0 - centre) < 0.0:
				n = -n
			var k := clampf(n.dot(sun) * 0.5 + 0.5, 0.0, 1.0)
			var color := deep.lerp(face, smoothstep(0.2, 0.55, k)).lerp(light, smoothstep(0.6, 0.85, k))
			b.add_triangle([r0, r1, t1], [color, color, color], n)
			b.add_triangle([r0, t1, t0], [color, color, color], n)
			b.add_triangle([centre + Vector3(0.0, 0.0, z), t0, t1], [face, face, face], facing)
		if dress:
			_dress(b, z, side, face, flame, top2)
	return b.commit()


## The decoration just above a flat side at height z: the wedge's glass ring and arc band, or the
## flame's yellow heart; then the face.
static func _dress(b: ArtMeshBuilder, z: float, side: float, face: Color, flame: bool, top2: Array) -> void:
	var facing := Vector3(0.0, 0.0, side)
	var zd := z + side * 0.003
	if flame:
		var heart: Array = top2.map(func(p: Vector2) -> Vector2: return FLAME_HEART_AT + (p - FLAME_HEART_AT) * FLAME_HEART_K)
		_fan(b, FLAME_HEART_AT, heart, zd, FLAME_HEART.lerp(Color.WHITE, LIGHTEN_3D), facing)
		StarArt.add_face(b, z + side * 0.01, side, FLAME_FACE_AT, 0.85)
		return
	SundialArt.strip(b, SundialArt.band(SundialArt.shrunk(rim(), SundialArt.SHRINK), SundialArt.SHRINK), zd, face.darkened(BAND_DARK), facing)
	SundialArt.strip(b, ring(SundialArt.SHRINK), zd, face.lerp(Color.WHITE, RING_LIGHT), facing)
	StarArt.add_face(b, z + side * 0.01, side, SundialArt.FACE_AT, SundialArt.FACE_K)


## A flat fan of `points` about `c` at height z (the flame's heart).
static func _fan(b: ArtMeshBuilder, c: Vector2, points: Array, z: float, color: Color, facing: Vector3) -> void:
	var colors := [color, color, color]
	for i in points.size():
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[(i + 1) % points.size()]
		b.add_triangle([Vector3(c.x, c.y, z), Vector3(p0.x, p0.y, z), Vector3(p1.x, p1.y, z)], colors, facing)


## A piece node of `slot` (a lens wedge, or the flame past the lens): the body and its outline, `size`
## m from the centre down to its point (like StarArt.make: it lands on it).
static func make(size: float, slot: int) -> Node3D:
	var meshes := piece_meshes(slot)
	var root := Node3D.new()
	root.name = "FlamePiece" if slot >= PIECES else "LensPiece"
	var body := ArtKit.instance(meshes[0], StarArt.glow_material())
	body.name = "Body"
	var outline := ArtKit.instance(meshes[1], StarArt.outline_material())
	outline.name = "Outline"
	var holder := Node3D.new()
	holder.name = "Shape"
	holder.scale = Vector3.ONE * size
	holder.add_child(body)
	holder.add_child(outline)
	root.add_child(holder)
	return root


## The piece of `slot` in 2D (the round-done card; y down) in the star's box: `r` px is the star's
## radius, the piece's height fills SundialArt.CARD_HEIGHT r about `c`.
static func draw_piece_2d(canvas: CanvasItem, c_star: Vector2, r_star: float, slot: int) -> void:
	var flame := slot >= PIECES
	var points := flame_rim() if flame else rim()
	var lo := INF
	var hi := -INF
	for p: Vector2 in points:
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	var r := r_star * SundialArt.CARD_HEIGHT / (hi - lo)
	var c := c_star + Vector2(0.0, (hi + lo) * 0.5 * r)   # the piece's middle on the star's centre
	var to2d := func(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p: Vector2 in pts:
			out.append(c + Vector2(p.x, -p.y) * r)
		return out
	var color := color_of(slot)
	canvas.draw_colored_polygon(to2d.call(SundialArt.outset(points, 4.5 / r)), ArtPalette.OUTLINE)
	canvas.draw_colored_polygon(to2d.call(points), color.darkened(0.15))
	var k := 0.9
	if flame:
		var face_rim: Array = points.map(func(p: Vector2) -> Vector2: return FLAME_HEART_AT + (p - FLAME_HEART_AT) * k)
		canvas.draw_colored_polygon(to2d.call(face_rim), color)
		canvas.draw_colored_polygon(to2d.call(face_rim.map(func(p: Vector2) -> Vector2: return FLAME_HEART_AT + (p - FLAME_HEART_AT) * FLAME_HEART_K)), FLAME_HEART)
		StarArt.draw_face_2d(canvas, c + Vector2(FLAME_FACE_AT.x, -FLAME_FACE_AT.y) * r, r * 0.85)
		return
	var face_rim := SundialArt.shrunk(points, k)
	canvas.draw_colored_polygon(to2d.call(face_rim), color)
	canvas.draw_colored_polygon(to2d.call(Array(SundialArt.band(face_rim, k))), color.darkened(BAND_DARK))
	canvas.draw_colored_polygon(to2d.call(Array(ring(k))), color.lerp(Color.WHITE, RING_LIGHT))
	StarArt.draw_face_2d(canvas, c + Vector2(SundialArt.FACE_AT.x, -SundialArt.FACE_AT.y) * r, r * SundialArt.FACE_K)
