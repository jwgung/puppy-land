## The hutton island's piece (#101, 2026-11-07 user decision B, the golden wedge): one wedge of a round
## sundial dial cut into ten equal parts (36° each, SundialEmblem fills the same ten). A golden face
## with a deeper golden band along the arc, three thin hour lines radiating from the point (no words,
## no numbers), StarArt's brown outline and StarArt's cute face (eyes, cheeks, smile) on both sides.
## The point (the dial's centre) faces down, the arc up: the wedge stands on its point like the star
## (the point 1 below the centre, as the star's points are 1 out), and it is longer than the star is
## tall so that its narrow tenth still shows a big face.
##
## Drawn like StarArt (one place for the look of a piece): a pillow (the rim at z = 0 rising to a flat
## face in front and behind) in an unshaded material with the facet light baked into the vertex
## colours, and an outline hull (the rim pushed out along its normals, front faces culled) = two
## draws, no light, no texture, no transparency. The 2D card picture (draw_piece_2d) uses the same rim.
## Visual only.
class_name SundialArt
extends RefCounted

## The colours as the approved picture has them (2D: the card, the emblem) ...
const FACE := Color("ffd45e")        # the golden face
const RIM := Color("e8a93a")         # the deeper golden band along the arc
const LINE := Color("c0862f")        # the hour lines
const LIGHT := Color("fff1a8")       # 2D: the lit edge
const DEEP := Color("e39a2a")        # 2D: the side
## ... and baked into the 3D piece, lighter: the views' tone mapping deepens them (#101 captures: the 2D
## gold rendered orange), as StarArt's pale lemon face shows as the star's yellow.
const FACE_3D := Color("ffeb94")
const RIM_3D := Color("ffc94f")
const LINE_3D := Color("e0a040")
const LIGHT_3D := Color("fff6c8")
const DEEP_3D := Color("ffbe3a")
const WEDGES := Island.SUNDIAL_WEDGES   # the round dial's wedges (spots 1-10; the 11th gives the gnomon; Island.SUNDIAL_WEDGES)
const WEDGE_DEG := 360.0 / WEDGES   # a tenth of the round dial
const ARC_STEPS := 14
const APEX := Vector2(0.0, -1.0)     # the point (before rounding)
const SPAN := 2.4                    # point to arc
const DEPTH := 0.22                  # the flat faces' height (front and back)
const SHRINK := 0.9                  # the flat face's share of the rim, about CENTRE
const CENTRE := Vector2(0.0, 0.3)
const OUTLINE_W := 0.08              # the outline hull's width
const BAND := 0.17                   # the arc band's share of the point-to-arc span
## The hour lines: angles from the middle (deg), where they start (share of the span), their width.
const LINE_ANGLES := [-10.0, 0.0, 10.0]
const LINE_FROM := 0.3
const LINE_W := 0.035
## The face: where it sits on the flat side and its size (share of StarArt's).
const FACE_AT := Vector2(0.0, 0.45)
const FACE_K := 1.0
## The card's picture (draw_piece_2d): the wedge's height (point to arc top) in the star's 2 r.
const CARD_HEIGHT := 2.0
## Rounding of the three corners (edges split to this length, then Chaikin corner cutting twice).
const ROUND_STEP := 0.09

static var _rim: Array = []
static var _meshes: Array = []


## The wedge's rim in the xy plane (Vector2, y up, counter-clockwise): the point at the bottom (APEX),
## the arc at the top (SPAN from it), all three corners softly rounded.
static func rim() -> Array:
	if _rim.is_empty():
		var half := deg_to_rad(WEDGE_DEG * 0.5)
		var apex := APEX
		var raw: Array = [apex]
		for i in ARC_STEPS + 1:
			var ang := PI * 0.5 - half + 2.0 * half * i / ARC_STEPS
			raw.append(apex + Vector2(cos(ang), sin(ang)) * SPAN)
		var dense: Array = []
		for i in raw.size():
			var p0: Vector2 = raw[i]
			var p1: Vector2 = raw[(i + 1) % raw.size()]
			var n := maxi(1, ceili(p0.distance_to(p1) / ROUND_STEP))
			for s in n:
				dense.append(p0.lerp(p1, float(s) / n))
		for pass_i in 2:
			var out: Array = []
			for i in dense.size():
				var q0: Vector2 = dense[i]
				var q1: Vector2 = dense[(i + 1) % dense.size()]
				out.append(q0.lerp(q1, 0.25))
				out.append(q0.lerp(q1, 0.75))
			dense = out
		_rim = dense
	return _rim


## The rim pushed out by `w` along its normals (the outline).
static func outset(points: Array, w: float) -> Array:
	var out: Array = []
	var n := points.size()
	for i in n:
		var d: Vector2 = (points[(i + 1) % n] as Vector2) - (points[(i - 1 + n) % n] as Vector2)
		out.append((points[i] as Vector2) + Vector2(d.y, -d.x).normalized() * w)   # counter-clockwise: outward
	return out


## The flat face's rim: the rim shrunk by `k` about CENTRE.
static func shrunk(points: Array, k: float) -> Array:
	return points.map(func(p: Vector2) -> Vector2: return CENTRE + (p - CENTRE) * k)


## The arc band on a face whose rim is `face_rim` (the rim shrunk by `k`): the outer run of the rim
## (as far from the point as the band's inner edge, or farther) and the inner arc, as one polygon.
static func band(face_rim: Array, k: float) -> PackedVector2Array:
	var apex_k := CENTRE + (APEX - CENTRE) * k
	var r_in := SPAN * k * (1.0 - BAND)
	var outer: Array = face_rim.filter(func(p: Vector2) -> bool: return p.distance_to(apex_k) >= r_in)
	var poly := PackedVector2Array(outer)
	for i in range(outer.size() - 1, -1, -1):
		poly.append(apex_k + ((outer[i] as Vector2) - apex_k).normalized() * r_in)
	return poly


## The hour lines on a face shrunk by `k`: [from, to] pairs (rim() units), from the point outwards.
static func hour_lines(k: float) -> Array:
	var apex_k := CENTRE + (APEX - CENTRE) * k
	var r_in := SPAN * k * (1.0 - BAND)
	var out: Array = []
	for deg: float in LINE_ANGLES:
		var dir := Vector2(sin(deg_to_rad(deg)), cos(deg_to_rad(deg)))
		out.append([apex_k + dir * SPAN * k * LINE_FROM, apex_k + dir * (r_in - 0.01)])
	return out


## [body mesh, outline mesh] of a wedge of radius 1 in the xy plane (facing +z), cached.
static func piece_meshes() -> Array:
	if _meshes.is_empty():
		var body := rim()
		_meshes = [_pillow(body, DEPTH, true), _pillow(outset(body, OUTLINE_W), DEPTH * (1.0 + OUTLINE_W * 2.5), false)]
	return _meshes


## A pillow: `points` (z = 0) rising to the flat face (shrunk by SHRINK) at z = +-depth; the band,
## the hour lines and the face on both flat sides when `dress`.
static func _pillow(points: Array, depth: float, dress: bool) -> ArrayMesh:
	var b := ArtKit.builder()
	var sun := Vector3(-0.45, 0.7, 0.55).normalized()
	var top2 := shrunk(points, SHRINK)
	var centre := Vector3(CENTRE.x, CENTRE.y, 0.0)
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
			var color := _lit(n, sun)
			b.add_triangle([r0, r1, t1], [color, color, color], n)
			b.add_triangle([r0, t1, t0], [color, color, color], n)
			b.add_triangle([centre + Vector3(0.0, 0.0, z), t0, t1], [FACE_3D, FACE_3D, FACE_3D], facing)
		if dress:
			_dress(b, z, side)
	return b.commit()


## The band, the hour lines and the face just above the flat side at height z (symmetric about x = 0,
## so the back reads the same).
static func _dress(b: ArtMeshBuilder, z: float, side: float) -> void:
	var facing := Vector3(0.0, 0.0, side)
	var zb := z + side * 0.003
	var poly := band(shrunk(rim(), SHRINK), SHRINK)
	for i in (poly.size() >> 1) - 1:   # the band as a strip: outer i, i + 1 against their inner points
		var o0 := poly[i]
		var o1 := poly[i + 1]
		var i0 := poly[poly.size() - 1 - i]
		var i1 := poly[poly.size() - 2 - i]
		b.add_triangle([Vector3(o0.x, o0.y, zb), Vector3(o1.x, o1.y, zb), Vector3(i1.x, i1.y, zb)], [RIM_3D, RIM_3D, RIM_3D], facing)
		b.add_triangle([Vector3(o0.x, o0.y, zb), Vector3(i1.x, i1.y, zb), Vector3(i0.x, i0.y, zb)], [RIM_3D, RIM_3D, RIM_3D], facing)
	var zl := z + side * 0.005
	for pair: Array in hour_lines(SHRINK):
		var a: Vector2 = pair[0]
		var e: Vector2 = pair[1]
		var w := (e - a).orthogonal().normalized() * LINE_W * 0.5
		var v := [a - w, a + w, e + w, e - w].map(func(p: Vector2) -> Vector3: return Vector3(p.x, p.y, zl))
		b.add_triangle([v[0], v[1], v[2]], [LINE_3D, LINE_3D, LINE_3D], facing)
		b.add_triangle([v[0], v[2], v[3]], [LINE_3D, LINE_3D, LINE_3D], facing)
	StarArt.add_face(b, z + side * 0.01, side, FACE_AT, FACE_K)


static func _lit(n: Vector3, sun: Vector3) -> Color:
	var k := clampf(n.dot(sun) * 0.5 + 0.5, 0.0, 1.0)
	return DEEP_3D.lerp(FACE_3D, smoothstep(0.2, 0.55, k)).lerp(LIGHT_3D, smoothstep(0.6, 0.85, k))


## A piece node: the body and its outline, `size` m from the centre down to the point (like StarArt.make:
## it lands on its point).
static func make(size: float) -> Node3D:
	var meshes := piece_meshes()
	var root := Node3D.new()
	root.name = "SundialPiece"
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


## The piece in 2D (the round-done card; y down) in the star's box: `r` px is the star's radius, the
## wedge's height fills CARD_HEIGHT r about `c`.
static func draw_piece_2d(canvas: CanvasItem, c_star: Vector2, r_star: float) -> void:
	var top := 0.0
	for p: Vector2 in rim():
		top = maxf(top, p.y)
	var r := r_star * CARD_HEIGHT / (top - APEX.y)
	var c := c_star + Vector2(0.0, (top + APEX.y) * 0.5 * r)   # the wedge's middle on the star's centre
	var to2d := func(points: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p: Vector2 in points:
			out.append(c + Vector2(p.x, -p.y) * r)
		return out
	var k := 0.9
	var face_rim := shrunk(rim(), k)
	canvas.draw_colored_polygon(to2d.call(outset(rim(), 4.5 / r)), ArtPalette.OUTLINE)
	canvas.draw_colored_polygon(to2d.call(rim()), DEEP)
	canvas.draw_colored_polygon(to2d.call(shrunk(rim(), 0.95).map(func(p: Vector2) -> Vector2: return p + Vector2(-1.0, 1.5) / r)), FACE.lerp(LIGHT, 0.25))
	canvas.draw_colored_polygon(to2d.call(face_rim), FACE)
	canvas.draw_colored_polygon(to2d.call(Array(band(face_rim, k))), RIM)
	for pair: Array in hour_lines(k):
		var ends: PackedVector2Array = to2d.call(pair)
		canvas.draw_line(ends[0], ends[1], LINE, maxf(2.0, LINE_W * r), true)
	StarArt.draw_face_2d(canvas, c + Vector2(FACE_AT.x, -FACE_AT.y) * r, r * FACE_K)
