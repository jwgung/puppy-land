## Dugi's explanation pictures (#73, 2026-11-06 user decisions): a line of his may carry one picture
## (`picture`, `say_picture`, ... in the content's data file, never in the words) of what the 3D view
## cannot show well (the invisible spin axis, where morning and evening are). DialogueBox shows it on
## a card in the middle of the screen while that line is in the box.
##
## Drawn with the canvas's 2D calls like PredictPictures (no picture files: the app does not grow,
## and the pictures are the same in every language). The look is the approved second mockup
## (issue #73): a cream paper card with the dialogue box's brown outline and lip around a scene
## panel; gradients are vertex-coloured or layered shapes, soft shadows and glows are stacked
## semi-transparent circles. No letters inside a picture (user): meaning comes from small drawn
## symbols (sun and moon, a sun rising or setting over a line) and arrows.
##
## Everything is drawn in DESIGN units (the mockup's 432 x 288 card) and scaled to the rect given,
## so a picture draws at any size. Every filled shape is clipped to the scene panel's rounded rect
## (Geometry2D), so nothing spills over the paper border at any size and in any renderer.
class_name ExplainPictures
extends RefCounted

const KINDS := ["axis", "morning_evening", "sea_breeze", "river"]
## The card's width : height (DialogueBox.CARD_SIZE has it too) and its drawing space (the mockup's).
const ASPECT := 1.5
const DESIGN := Vector2(432.0, 432.0 / ASPECT)
const INSET := 9.0           # the paper border around the scene panel
const LIP := 5.0             # the darker bottom edge, like the dialogue box
const PANEL_RADIUS := 12.0
const CARD_RADIUS := 20.0
## Every arrow (Pen.arrow): shaft width, its tail's share of it, the head's length and width as times
## the shaft width, the halo and the dark edge (DESIGN units), the corners' rounding.
const ARROW_WIDTH := 7.0
const ARROW_TAIL_SHARE := 0.72
const ARROW_HEAD_LENGTH := 2.5
const ARROW_HEAD_WIDTH := 2.5
const ARROW_HALO := 3.0
const ARROW_EDGE := 1.1
const ARROW_ROUND := 0.9
## Soft light: GLOW_LAYERS circles from the middle out (strength / GLOW_SPREAD + GLOW_FLOOR of 255 at
## the rim, GLOW_FALL the fall-off), SHADOW_LAYERS circles from SHADOW_OUTER of the radius in by SHADOW_GROW each.
const GLOW_LAYERS := 14
const GLOW_SPREAD := 3.0
const GLOW_FLOOR := 8.0
const GLOW_FALL := 1.2
const SHADOW_LAYERS := 6
const SHADOW_OUTER := 1.08
const SHADOW_GROW := 0.03
const SHADOW_COLOR := Color8(60, 40, 30)
## The globe: GLOBE_OCEAN_LAYERS circles shading the ocean towards the light, GLOBE_SHADE_LAYERS
## crescents darkening the far side (GLOBE_SHADE_ALPHA each), the offset circle that spares the lit
## side (GLOBE_LIT_OFFSET of the radius towards the light).
const GLOBE_OCEAN_LAYERS := 22
const GLOBE_OCEAN_DARK := Color8(30, 104, 208)
const GLOBE_OCEAN_LIGHT := Color8(74, 168, 242)
const GLOBE_SHADE_LAYERS := 6
const GLOBE_SHADE_ALPHA := 0.065
const GLOBE_SHADE := Color8(10, 30, 90)
const GLOBE_LIT_OFFSET := 0.35

const PAPER := UiTheme.DIALOGUE_PAPER
const OUT := UiTheme.DIALOGUE_LINE
const LIP_COLOR := Color8(90, 56, 38)
const INK := Color8(27, 42, 74)
const ORG := Color8(226, 104, 60)
const ORGD := Color8(176, 70, 34)
const YEL := Color8(255, 198, 26)
const YELD := Color8(224, 164, 0)
const SUN_RAY := Color8(255, 214, 60)
const SUN_GLOW := Color8(255, 214, 80)
const GRASS := Color8(79, 191, 59)
const GRASSL := Color8(120, 214, 86)
const GRASSD := Color8(52, 150, 44)
const SAND := Color8(243, 216, 140)
const WHITE := Color(1, 1, 1)

## Filled shapes drawn, and those whose polygon could not be triangulated
## (tests/explain_picture_checks.gd counts both: every picture draws shapes, none fails).
static var shapes := 0
static var failed := 0


## `value` when it names a picture, else "" (no picture).
static func picture_or_none(value: Variant) -> String:
	return str(value) if value is String and value in KINDS else ""


## The problem with the picture field `key` of a content line `holder` (named `path` in the
## message): [] when it has none or names a picture.
static func check(holder: Variant, key: String, path: String) -> PackedStringArray:
	if not (holder is Dictionary and holder.has(key)) or picture_or_none(holder[key]) != "":
		return PackedStringArray()
	return PackedStringArray(["%s must be one of ExplainPictures.KINDS" % path])


## Draws the card (paper, lip, outline) with picture `kind` filling `rect` of `canvas`.
static func draw_card(canvas: CanvasItem, kind: String, rect: Rect2) -> void:
	var pen := Pen.new(canvas, rect)
	pen.card_back()
	match kind:
		"axis":
			_axis(pen)
		"morning_evening":
			_morning_evening(pen)
		"sea_breeze":
			_sea_breeze(pen)
		"river":
			_river(pen)
	pen.card_front()
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


# --- the pictures ---------------------------------------------------------------------------------

## The globe on its tilted dashed axis with the turning arrow round it, passing in front from the
## left (west) to the right (east).
static func _axis(p: Pen) -> void:
	p.sky(Color8(214, 238, 255), Color8(160, 208, 250))
	for cloud: Array in [[Vector2(60, 50), 1.0], [Vector2(370, 222), 1.1], [Vector2(344, 48), 0.7]]:
		p.cloud(cloud[0], cloud[1], Color(1, 1, 1, 0.78))
	var c := Vector2(216, 142)
	var r := 76.0
	var tilt := -18.0
	var ring := Vector2(r + 30.0, 24.0)
	var back := arc_points(c, ring.x, ring.y, 180.0, 360.0, tilt)
	p.line(back, WHITE, 7.0)
	p.line(back, Color8(240, 170, 140), 4.5)
	var lands := [[blob(c + Vector2(-20, -28), 30, 20, 2), GRASS], [blob(c + Vector2(24, 16), 26, 32, 5), GRASS],
		[blob(c + Vector2(-36, 40), 16, 12, 8), GRASS]]
	p.globe(c, r, Vector2(-0.5, -0.55), lands)
	var a0 := c + Vector2(0, -r - 48.0).rotated(deg_to_rad(tilt))
	var a1 := c + Vector2(0, r + 48.0).rotated(deg_to_rad(tilt))
	var n := 16
	for i in range(0, n, 2):
		var d0 := a0.lerp(a1, float(i) / n)
		var d1 := a0.lerp(a1, (i + 0.62) / n)
		p.line(PackedVector2Array([d0, d1]), PAPER, 6.5)
		p.line(PackedVector2Array([d0, d1]), INK, 3.6)
	for knob: Vector2 in [a0, a1]:
		p.ellipse(knob, 8.0, 8.0, PAPER)
		p.ellipse(knob, 6.5, 6.5, ORG)
		p.ring(knob, 6.5, 6.5, OUT, 2.0)
		p.ellipse(knob - Vector2(2, 2), 2.0, 2.0, Color(1, 1, 1, 0.8))
	p.arrow(arc_points(c, ring.x, ring.y, 168.0, 12.0, tilt, 120), ORG)


## The Earth from above the north pole with the Sun on the right: the lit day half, the night half,
## the turning arrows (anticlockwise), and the two edges: a setting sun where the turn carries the
## ground from day into night (evening, top) and a rising sun where it comes out of the night
## (morning, bottom). A small sun and moon mark the day and night halves.
static func _morning_evening(p: Pen) -> void:
	p.sky(Color8(34, 52, 108), Color8(72, 104, 178))
	p.stars(26, 3)
	var sun := Vector2(362, 144)
	p.glow(sun, 70.0, SUN_GLOW, 170.0)
	for i in 14:
		var a := TAU * i / 14.0
		var dir := Vector2(cos(a), sin(a))
		p.line(PackedVector2Array([sun + dir * 32.0, sun + dir * (46.0 if i % 2 == 0 else 40.0)]), SUN_RAY, 4.0)
	p.ellipse(sun, 27, 27, Color8(255, 170, 30))
	p.ellipse(sun, 24, 24, YEL)
	p.ellipse(sun, 18, 18, Color8(255, 226, 90))
	p.ring(sun, 27, 27, YELD, 2.0)
	var c := Vector2(186, 144)
	var r := 64.0
	var earth := ellipse_points(c, r, r)
	p.soft_shadow(c + Vector2(0, 6), r, 0.43)
	for i in 20:
		var t := i / 19.0
		var rr := r * (1.2 - 1.0 * t)
		p.fill(ellipse_points(c + Vector2(r * 0.35 * t, 0), rr, rr), Color8(34, 110, 214).lerp(Color8(110, 196, 250), t), earth)
	for land: PackedVector2Array in [blob(c + Vector2(34, -26), 26, 18, 3), blob(c + Vector2(40, 30), 22, 24, 6), blob(c + Vector2(-24, -10), 20, 26, 9),
			blob(c + Vector2(-34, 38), 14, 10, 11)]:
		p.fill(land, GRASS, earth)
	# The night half with a soft edge (alpha linear across the edge band: exact on any triangulation).
	var night := Color8(26, 38, 92)
	var soft := 8.0
	p.fill(rect_points(Rect2(c.x - r - 4, c.y - r - 4, r + 4 - soft, 2 * r + 8)), Color(night, 0.92), earth)
	p.fill_by(rect_points(Rect2(c.x - soft, c.y - r - 4, 2 * soft, 2 * r + 8)),
		func(v: Vector2) -> Color: return Color(night, 0.92 * clampf((c.x + soft - v.x) / (2 * soft), 0.0, 1.0)), earth)
	for city: Vector2 in [Vector2(-40, -20), Vector2(-30, 10), Vector2(-52, 26), Vector2(-22, -44), Vector2(-46, -6)]:
		p.ellipse(c + city, 1.8, 1.8, Color8(255, 224, 120))
	p.ring(c, r, r, OUT, 3.0)
	p.ellipse(c, 5, 5, PAPER)
	p.ring(c, 5, 5, OUT, 1.5)
	var big := r + 20.0
	p.arrow(arc_points(c, big, big, -118.0, -238.0, 0.0, 80), ORG)
	p.arrow(arc_points(c, big, big, 62.0, -12.0, 0.0, 80), ORG)
	for y: float in [c.y - r, c.y + r]:
		p.ellipse(Vector2(c.x, y), 6.5, 6.5, PAPER)
		p.ring(Vector2(c.x, y), 6.5, 6.5, OUT, 2.0)
	p.horizon_sun(Vector2(c.x, c.y - r - 38.0), false)   # evening: the sun goes down
	p.horizon_sun(Vector2(c.x, c.y + r + 38.0), true)    # morning: the sun comes up
	p.small_sun(c + Vector2(33, 2))
	p.moon(c + Vector2(-34, 2))


## The sea breeze by day: the sea on the left, the warm land on the right under the sun, and the
## loop of air: along the ground from the sea to the land, up over the land, back high over the
## sea and down again (blue cool air, orange warm air).
static func _sea_breeze(p: Pen) -> void:
	p.sky(Color8(120, 200, 255), Color8(222, 242, 255))
	var surf := 190.0
	var sun := Vector2(372, 52)
	p.glow(sun, 50.0, SUN_GLOW, 150.0)
	for i in 12:
		var dir := Vector2.from_angle(TAU * i / 12.0)
		p.line(PackedVector2Array([sun + dir * 24.0, sun + dir * 34.0]), SUN_RAY, 3.5)
	p.ellipse(sun, 20, 20, YEL)
	p.ring(sun, 20, 20, YELD, 2.0)
	p.ellipse(sun - Vector2(5, 5), 7, 7, Color8(255, 236, 140))
	p.cloud(Vector2(150, 30), 0.85, Color(1, 1, 1, 0.92))
	var sea_top := Color8(96, 184, 236)
	var sea_bottom := Color8(44, 116, 196)
	p.fill_by(rect_points(Rect2(0, surf, 226, DESIGN.y - surf)),
		func(v: Vector2) -> Color: return sea_top.lerp(sea_bottom, clampf((v.y - surf) / (DESIGN.y - surf), 0.0, 1.0)))
	for wave: Vector2 in [Vector2(26, 204), Vector2(84, 214), Vector2(140, 203), Vector2(190, 216), Vector2(52, 230), Vector2(120, 238), Vector2(176, 242)]:
		p.line(arc_points(wave, 12, 5, 200, 340, 0.0, 14), Color(1, 1, 1, 0.86), 2.4)
	# The land's top edge: the sand under it, a strip of grass along it, a light line on the grass.
	var shore := PackedVector2Array([Vector2(226, surf), Vector2(236, surf - 6), Vector2(260, surf - 8), Vector2(DESIGN.x, surf - 8)])
	var sand := shore.duplicate()
	sand.append_array([Vector2(DESIGN.x, DESIGN.y), Vector2(226, DESIGN.y)])
	p.fill(sand, SAND)
	var grass := shore.duplicate()
	grass.append_array([Vector2(DESIGN.x, surf + 2), Vector2(260, surf + 2), Vector2(236, surf + 4)])
	p.fill(grass, GRASS)
	var edge := shore.slice(1)
	edge[edge.size() - 1] = Vector2(DESIGN.x - INSET, surf - 8)
	p.line(edge, GRASSL, 2.2)
	# The house and the tree on the land.
	var h := Vector2(332, surf - 8)
	p.round_rect(Rect2(h.x - 24, h.y - 30, 48, 30), 3, Color8(255, 238, 205), OUT, 2.0)
	var roof := PackedVector2Array([Vector2(h.x - 30, h.y - 28), Vector2(h.x, h.y - 54), Vector2(h.x + 30, h.y - 28)])
	p.fill(roof, Color8(226, 72, 60))
	p.ring_points(roof, OUT, 2.0)
	p.round_rect(Rect2(h.x - 6, h.y - 18, 12, 18), 2, Color8(150, 100, 60), OUT, 1.5)
	p.round_rect(Rect2(h.x + 10, h.y - 24, 9, 9), 1.5, Color8(160, 210, 255), OUT, 1.5)
	var tree := 392.0
	p.fill(rect_points(Rect2(tree - 2.5, surf - 28, 5, 20)), Color8(120, 80, 50))
	for leaf: Vector3 in [Vector3(0, -40, 15), Vector3(-10, -30, 12), Vector3(10, -30, 12)]:
		var at := Vector2(tree + leaf.x, surf + leaf.y - 6)
		p.ellipse(at, leaf.z, leaf.z, Color8(60, 170, 60))
		p.ring(at, leaf.z, leaf.z, GRASSD, 1.5)
	# The loop of air.
	var cool := Color8(66, 142, 255)
	var warm := Color8(240, 110, 56)
	var aloft := Color8(238, 160, 100)
	var high := 76.0
	var left := 52.0
	var right := 292.0
	var bottom := surf - 24.0
	var rc := 24.0
	# Each side is one arrow from the corner before it, its tip short of the next corner.
	var gap := 9.0
	p.arrow(_corner_then(arc_points(Vector2(left + rc, bottom - rc), rc, rc, 180, 90, 0.0, 24), Vector2(right - rc - gap, bottom)), cool)
	p.arrow(_corner_then(arc_points(Vector2(right - rc, bottom - rc), rc, rc, 90, 0, 0.0, 24), Vector2(right, high + rc + gap)), warm)
	p.arrow(_corner_then(arc_points(Vector2(right - rc, high + rc), rc, rc, 0, -90, 0.0, 24), Vector2(left + rc + gap, high)), aloft)
	p.arrow(_corner_then(arc_points(Vector2(left + rc, high + rc), rc, rc, -90, -180, 0.0, 24), Vector2(left, bottom - rc - gap)), cool)


## `corner` and then a straight run to `to`.
static func _corner_then(corner: PackedVector2Array, to: Vector2) -> PackedVector2Array:
	var out := corner.duplicate()
	out.append(to)
	return out


## A bend of a river seen from above: the fast water on the outside (a long arrow) wears the bank
## into a crumbling cliff (bits of it in the water); the slow water inside (a short arrow) leaves a
## sand bar.
static func _river(p: Pen) -> void:
	p.sky(Color8(118, 208, 92), Color8(88, 182, 68))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 40:
		var at := Vector2(rng.randf_range(16, DESIGN.x - 16), rng.randf_range(16, DESIGN.y - 20))
		p.line(PackedVector2Array([at + Vector2(-3, 0), at + Vector2(0, -5), at + Vector2(3, 0)]), Color8(60, 150, 50), 1.6, false)
	for flower: Array in [[Vector2(40, 60), WHITE], [Vector2(380, 70), Color8(255, 210, 60)], [Vector2(60, 230), Color8(255, 120, 170)],
			[Vector2(392, 230), WHITE], [Vector2(330, 40), Color8(255, 120, 170)]]:
		p.ellipse(flower[0], 3, 3, flower[1])
		p.ellipse(flower[0], 1.2, 1.2, YEL)
	var c := Vector2(216, 176)
	var mid := 76.0
	var width := 60.0
	var outer := mid + width / 2.0
	var inner := mid - width / 2.0
	# The worn outer bank.
	p.fill(bend_band(c, outer + 7.0, 16.0), Color8(120, 84, 52))
	p.fill(bend_band(c, outer + 4.0, 10.0), Color8(176, 128, 84))
	p.fill(bend_band(c, outer + 10.0, 3.0), Color8(86, 58, 36, 160))
	# The water, lighter towards its middle.
	var waters := [Color8(92, 160, 214), Color8(112, 176, 226), Color8(134, 192, 236), Color8(158, 208, 244)]
	for k in waters.size():
		p.fill(bend_band(c, mid, width + 2.0 - k * 13.0), waters[k])
	# Bits of the outer bank in the water (worn away).
	for bit: Vector3 in [Vector3(198, 3.6, 0), Vector3(212, 2.6, 1), Vector3(236, 3.2, 0), Vector3(318, 3.0, 1), Vector3(334, 3.8, 0), Vector3(350, 2.6, 1)]:
		var at := c + Vector2.from_angle(deg_to_rad(bit.x)) * (outer - 5.0 - bit.z * 5.0)
		p.ellipse(at, bit.y * 1.25, bit.y, Color8(150, 104, 64))
		p.ring(at, bit.y * 1.25, bit.y, Color8(96, 64, 40), 1.0)
	# The sand bar on the inside.
	p.ellipse(c, inner + 3.0, inner + 3.0, Color8(214, 184, 110))
	p.ellipse(c + Vector2(0, -2), inner - 1.0, inner - 1.0, SAND)
	p.ellipse(c + Vector2(-4, -8), inner - 12.0, inner - 12.0, Color8(250, 228, 160))
	for dot: Vector2 in [Vector2(-22, -30), Vector2(-8, -34), Vector2(10, -30), Vector2(26, -22), Vector2(-30, -10), Vector2(30, -6),
			Vector2(-14, -18), Vector2(12, -12), Vector2(0, -4)]:
		p.ellipse(c + dot, 2.2, 2.2, Color8(214, 176, 100))
	for ripple: Vector2 in [Vector2(200, mid - 12), Vector2(250, mid + 16), Vector2(300, mid - 14), Vector2(330, mid + 14)]:
		p.line(arc_points(c, ripple.y, ripple.y, ripple.x, ripple.x + 16, 0.0, 8), Color(1, 1, 1, 0.8), 2.0)
	var fast := PackedVector2Array([c + Vector2(-mid - 14, 62), c + Vector2(-mid - 14, 0)])
	fast.append_array(arc_points(c, mid + 14, mid + 14, 180, 332, 0.0, 120).slice(1))
	p.arrow(fast, ORG)
	# The slow water inside: a shorter, thinner arrow.
	p.arrow(arc_points(c, mid - 16, mid - 16, 228, 292, 0.0, 40), WHITE, ARROW_WIDTH * 0.7, Color8(120, 166, 204), Color8(70, 130, 186))


# --- shapes ---------------------------------------------------------------------------------------

## Points on an ellipse arc about `c` from `a0` to `a1` degrees (y down), turned by `rot` degrees.
static func arc_points(c: Vector2, rx: float, ry: float, a0: float, a1: float, rot := 0.0, n := 60) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := deg_to_rad(a0 + (a1 - a0) * i / n)
		out.append(c + Vector2(rx * cos(a), ry * sin(a)).rotated(deg_to_rad(rot)))
	return out


static func ellipse_points(c: Vector2, rx: float, ry: float, n := 48) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(rx * cos(a), ry * sin(a)))
	return out


static func rect_points(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func round_rect_points(r: Rect2, radius: float, steps := 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	var corners := [[r.end - Vector2(radius, radius), 0.0], [Vector2(r.position.x + radius, r.end.y - radius), 90.0],
		[r.position + Vector2(radius, radius), 180.0], [Vector2(r.end.x - radius, r.position.y + radius), 270.0]]
	for corner: Array in corners:
		for i in steps + 1:
			out.append(corner[0] + Vector2.from_angle(deg_to_rad(corner[1] + 90.0 * i / steps)) * radius)
	return out


## A rounded land or cloud outline about `c` (the same `seed`, the same shape).
static func blob(c: Vector2, rx: float, ry: float, seed: int, n := 14, jitter := 0.28) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var ph := [rng.randf_range(0, TAU), rng.randf_range(0, TAU), rng.randf_range(0, TAU)]
	var out := PackedVector2Array()
	for i in n * 4:
		var a := TAU * i / (n * 4)
		var k := 1.0 + jitter * (sin(2 * a + ph[0]) * 0.5 + sin(3 * a + ph[1]) * 0.35 + sin(5 * a + ph[2]) * 0.2)
		out.append(c + Vector2(rx * k * cos(a), ry * k * sin(a)))
	return out


## An arrow's shape along `path` of shaft `width`: {"outline": one simple polygon (the round tail,
## the tapering shaft, the head), "spine": the shaft's middle line, "normals" and "halves": its
## normal and half width at each spine point}.
static func arrow_shape(path: PackedVector2Array, width: float) -> Dictionary:
	var points := resample(path, 1.5)
	var head_length := width * ARROW_HEAD_LENGTH
	# The head's base: on the path, head_length back from the tip along it.
	var tip := points[-1]
	var left := head_length
	var k := points.size() - 1
	while k > 0 and left > points[k].distance_to(points[k - 1]):
		left -= points[k].distance_to(points[k - 1])
		k -= 1
	var base := points[k].lerp(points[maxi(k - 1, 0)], left / maxf(points[k].distance_to(points[maxi(k - 1, 0)]), 0.001)) if k > 0 else points[0]
	var spine := points.slice(0, k)
	spine.append(base)
	if spine.size() < 2:
		spine = PackedVector2Array([base - (tip - base).normalized(), base])
	var dir := (tip - base).normalized()   # the head lies along the path over its own length
	var total := 0.0
	var at := PackedFloat32Array([0.0])
	for i in range(1, spine.size()):
		total += spine[i].distance_to(spine[i - 1])
		at.append(total)
	var normals := PackedVector2Array()
	var halves := PackedFloat32Array()
	for i in spine.size():
		var t := (spine[mini(i + 1, spine.size() - 1)] - spine[maxi(i - 1, 0)]).normalized()
		if i == spine.size() - 1:
			t = (t + dir).normalized()   # the shaft meets the head square
		normals.append(Vector2(-t.y, t.x))
		halves.append(width * 0.5 * lerpf(ARROW_TAIL_SHARE, 1.0, at[i] / maxf(total, 0.001)))
	var side := Vector2(-dir.y, dir.x)
	var half_head := width * ARROW_HEAD_WIDTH * 0.5
	var outline := PackedVector2Array()
	for i in spine.size():
		outline.append(spine[i] + normals[i] * halves[i])
	outline.append(base + side * half_head)
	outline.append(tip)
	outline.append(base - side * half_head)
	for i in range(spine.size() - 1, -1, -1):
		outline.append(spine[i] - normals[i] * halves[i])
	# The round tail: from the right side round the back to the left side.
	var back := -normals[0]
	for j in range(1, 12):
		outline.append(spine[0] + back.rotated(-PI * j / 12.0) * halves[0])
	# Slightly rounded corners (the tip and the head's wings).
	var rounded := Geometry2D.offset_polygon(outline, -ARROW_ROUND)
	if rounded.size() == 1:
		var grown := Geometry2D.offset_polygon(rounded[0], ARROW_ROUND, Geometry2D.JOIN_ROUND)
		if grown.size() == 1:
			outline = grown[0]
	return {"outline": outline, "spine": spine, "normals": normals, "halves": halves}


## `path` with its points every `step` (or closer) along it.
static func resample(path: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array([path[0]])
	for i in range(1, path.size()):
		var a := path[i - 1]
		var b := path[i]
		var n := maxi(1, ceili(a.distance_to(b) / step))
		for j in range(1, n + 1):
			out.append(a.lerp(b, float(j) / n))
	return out


## The river's bend as a band `width` wide about radius `r` round `c`: up the left, over the top
## and down the right, both legs running `leg` below `c`.
static func bend_band(c: Vector2, r: float, width: float, leg := 130.0) -> PackedVector2Array:
	var ro := r + width / 2.0
	var ri := r - width / 2.0
	var out := PackedVector2Array([c + Vector2(-ro, leg)])
	out.append_array(arc_points(c, ro, ro, 180, 360, 0.0, 48))
	out.append(c + Vector2(ro, leg))
	out.append(c + Vector2(ri, leg))
	var back := arc_points(c, ri, ri, 180, 360, 0.0, 48)
	back.reverse()
	out.append_array(back)
	out.append(c + Vector2(-ri, leg))
	return out


## Draws in DESIGN units on one canvas: the card frame and the scene's shapes, filled shapes
## clipped to the scene panel.
class Pen:
	var canvas: CanvasItem
	var panel: PackedVector2Array

	func _init(on: CanvasItem, rect: Rect2) -> void:
		canvas = on
		canvas.draw_set_transform(rect.position, 0.0, rect.size / ExplainPictures.DESIGN)
		panel = ExplainPictures.round_rect_points(_panel_rect(), ExplainPictures.PANEL_RADIUS)

	func _panel_rect() -> Rect2:
		var inset := ExplainPictures.INSET
		return Rect2(inset, inset, ExplainPictures.DESIGN.x - inset * 2.0, ExplainPictures.DESIGN.y - inset * 2.0 - ExplainPictures.LIP)

	func _box(bg: Color, line: Color, radius: float, border: float) -> StyleBoxFlat:
		var box := StyleBoxFlat.new()
		box.bg_color = bg
		box.draw_center = bg.a > 0.0
		box.border_color = line
		box.set_border_width_all(int(border))
		box.set_corner_radius_all(int(radius))
		box.anti_aliasing = true
		return box

	## The lip, the paper and its outline (under the scene).
	func card_back() -> void:
		var d := ExplainPictures.DESIGN
		var lip := ExplainPictures.LIP
		var radius := ExplainPictures.CARD_RADIUS
		canvas.draw_style_box(_box(ExplainPictures.LIP_COLOR, Color.TRANSPARENT, radius, 0), Rect2(0, lip, d.x, d.y - lip))
		canvas.draw_style_box(_box(ExplainPictures.PAPER, Color.TRANSPARENT, radius, 0), Rect2(0, 0, d.x, d.y - lip))
		canvas.draw_style_box(_box(Color.TRANSPARENT, ExplainPictures.OUT, radius - 1.0, 4), Rect2(2, 2, d.x - 4, d.y - lip - 4))

	## The scene panel's outline (over the scene).
	func card_front() -> void:
		canvas.draw_style_box(_box(Color.TRANSPARENT, ExplainPictures.OUT, ExplainPictures.PANEL_RADIUS, 3), _panel_rect())

	## Fills `points` clipped to `clip` (optional) and the panel. Opaque fills get an antialiased rim.
	func fill(points: PackedVector2Array, color: Color, clip := PackedVector2Array()) -> void:
		fill_by(points, func(_v: Vector2) -> Color: return color, clip)

	## Fills `points` (clipped) with each vertex coloured by `color_at` (a linear gradient is exact).
	func fill_by(points: PackedVector2Array, color_at: Callable, clip := PackedVector2Array()) -> void:
		var parts: Array = [points]
		if not clip.is_empty():
			parts = Geometry2D.intersect_polygons(points, clip)
		for part: PackedVector2Array in parts:
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(part, panel):
				ExplainPictures.shapes += 1
				if piece.size() < 3 or Geometry2D.triangulate_polygon(piece).is_empty():
					ExplainPictures.failed += 1
					continue
				var colors := PackedColorArray()
				for v: Vector2 in piece:
					colors.append(color_at.call(v))
				canvas.draw_polygon(piece, colors)
				if colors[0].a >= 0.99 and _flat(colors):
					var rim := piece.duplicate()
					rim.append(piece[0])
					canvas.draw_polyline(rim, colors[0], 1.0, true)

	func _flat(colors: PackedColorArray) -> bool:
		for k: Color in colors:
			if k != colors[0]:
				return false
		return true

	func ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
		fill(ExplainPictures.ellipse_points(c, rx, ry), color)

	func ring(c: Vector2, rx: float, ry: float, color: Color, width: float) -> void:
		ring_points(ExplainPictures.ellipse_points(c, rx, ry, 64), color, width)

	func ring_points(points: PackedVector2Array, color: Color, width: float) -> void:
		var closed := points.duplicate()
		closed.append(points[0])
		canvas.draw_polyline(closed, color, width, true)

	func round_rect(r: Rect2, radius: float, color: Color, line: Color, width: float) -> void:
		var points := ExplainPictures.round_rect_points(r, radius, 3)
		fill(points, color)
		ring_points(points, line, width)

	## A polyline `width` wide with round ends.
	func line(points: PackedVector2Array, color: Color, width: float, caps := true) -> void:
		canvas.draw_polyline(points, color, width, true)
		if caps:
			for end: Vector2 in [points[0], points[-1]]:
				fill(ExplainPictures.ellipse_points(end, width / 2.0, width / 2.0, 16), color)

	## The scene's sky: a vertical gradient over the whole panel.
	func sky(top: Color, bottom: Color) -> void:
		var h := ExplainPictures.DESIGN.y
		fill_by(ExplainPictures.rect_points(Rect2(Vector2.ZERO, ExplainPictures.DESIGN)),
			func(v: Vector2) -> Color: return top.lerp(bottom, clampf(v.y / h, 0.0, 1.0)))

	func stars(count: int, seed: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		for i in count:
			var at := Vector2(rng.randf_range(16, ExplainPictures.DESIGN.x - 16), rng.randf_range(16, ExplainPictures.DESIGN.y - 20))
			var r := rng.randf_range(0.8, 1.9)
			fill(ExplainPictures.ellipse_points(at, r, r, 10), Color(1, 1, 1, rng.randf_range(0.43, 0.9)))

	func cloud(at: Vector2, scale: float, color: Color) -> void:
		var puffs := ExplainPictures.ellipse_points(at, 16 * scale, 16 * scale)
		for puff: Vector3 in [Vector3(16, -6, 13), Vector3(-16, -3, 11), Vector3(30, 2, 9)]:
			var more := ExplainPictures.ellipse_points(at + Vector2(puff.x, puff.y) * scale, puff.z * scale, puff.z * scale)
			puffs = Geometry2D.merge_polygons(puffs, more)[0]
		fill(puffs, color)

	## A soft glow: stacked translucent circles, strongest in the middle.
	func glow(c: Vector2, r: float, color: Color, strength: float) -> void:
		var n := ExplainPictures.GLOW_LAYERS
		for i in range(n, 0, -1):
			var t := float(i) / n
			var alpha := strength * pow(1.0 - t, ExplainPictures.GLOW_FALL) / ExplainPictures.GLOW_SPREAD + ExplainPictures.GLOW_FLOOR
			fill(ExplainPictures.ellipse_points(c, r * t, r * t), Color(color, alpha / 255.0))

	## A soft shadow under a round thing: stacked translucent circles growing outwards.
	func soft_shadow(c: Vector2, r: float, alpha: float) -> void:
		var n := ExplainPictures.SHADOW_LAYERS
		for i in n:
			var rr := r * (ExplainPictures.SHADOW_OUTER - ExplainPictures.SHADOW_GROW * i)
			fill(ExplainPictures.ellipse_points(c, rr, rr), Color(ExplainPictures.SHADOW_COLOR, alpha / n))

	## The globe: shadow, an ocean lit from `lit`, its lands, the far side's soft shade, a highlight, the rim.
	func globe(c: Vector2, r: float, lit: Vector2, lands: Array) -> void:
		var earth := ExplainPictures.ellipse_points(c, r, r, 64)
		soft_shadow(c + Vector2(4, 7), r, 0.35)
		var layers := ExplainPictures.GLOBE_OCEAN_LAYERS
		for i in layers:
			var t := float(i) / (layers - 1)
			var rr := r * (1.2 - 1.05 * t)
			fill(ExplainPictures.ellipse_points(c + lit * r * 0.55 * t, rr, rr), ExplainPictures.GLOBE_OCEAN_DARK.lerp(ExplainPictures.GLOBE_OCEAN_LIGHT, t), earth)
		for land: Array in lands:
			fill(land[0], land[1], earth)
		for k in ExplainPictures.GLOBE_SHADE_LAYERS:
			var spare := r * (0.8 + 0.06 * k)
			var lit_side := ExplainPictures.ellipse_points(c + lit * r * ExplainPictures.GLOBE_LIT_OFFSET, spare, spare, 64)
			for shade: PackedVector2Array in Geometry2D.clip_polygons(earth, lit_side):   # (no hole: lit_side reaches past the rim)
				fill(shade, Color(ExplainPictures.GLOBE_SHADE, ExplainPictures.GLOBE_SHADE_ALPHA))
		var spot := c + Vector2(lit.x * r * 0.62, lit.y * r * 0.66)
		for k in 2:
			var hl := PackedVector2Array()
			for v: Vector2 in ExplainPictures.ellipse_points(Vector2.ZERO, r * (0.16 + 0.04 * k), r * (0.09 + 0.03 * k), 32):
				hl.append(spot + v.rotated(deg_to_rad(-30.0)))
			fill(hl, Color(1, 1, 1, 0.3 if k == 0 else 0.15))
		ring(c, r, r, ExplainPictures.OUT, 3.0)

	## An arrow along `path` (#73 2026-11-06: the user found the first arrows clumsy): one silhouette (the
	## shaft along the finely resampled path, tapering from TAIL_SHARE of `width` at its round tail to
	## `width` at the head, then a triangle head ARROW_HEAD_LENGTH x ARROW_HEAD_WIDTH times the width,
	## its tip at the path's end and its base on the path, along the path over the head's length), its
	## corners slightly rounded. Drawn as an even `halo` all round (the silhouette grown), a thin
	## `dark` edge, the colour, and a soft light stripe along the shaft.
	func arrow(path: PackedVector2Array, color: Color, width := ExplainPictures.ARROW_WIDTH, dark := Color(0, 0, 0, 0), halo := ExplainPictures.PAPER) -> void:
		if dark.a == 0.0:
			dark = color.lerp(Color.BLACK, 0.35)
		var shape: Dictionary = ExplainPictures.arrow_shape(path, width)
		var outline: PackedVector2Array = shape.outline
		for part: PackedVector2Array in Geometry2D.offset_polygon(outline, ExplainPictures.ARROW_HALO, Geometry2D.JOIN_ROUND):
			fill(part, halo)
		fill(outline, dark)
		for part: PackedVector2Array in Geometry2D.offset_polygon(outline, -ExplainPictures.ARROW_EDGE, Geometry2D.JOIN_ROUND):
			fill(part, color)
		# The light stripe: the shaft's middle nudged towards the light (top left), fading out at both ends.
		var spine: PackedVector2Array = shape.spine
		var normals: PackedVector2Array = shape.normals
		var halves: PackedFloat32Array = shape.halves
		var stripe := PackedVector2Array()
		var light := Vector2(-0.6, -0.8)
		var from := int(spine.size() * 0.12)
		var to := int(spine.size() * 0.9)
		for i in range(from, to):
			stripe.append(spine[i] + normals[i] * normals[i].dot(light) * halves[i] * 0.42)
		if stripe.size() >= 2:
			canvas.draw_polyline(stripe, Color(color.lerp(Color.WHITE, 0.5), 0.7), maxf(1.2, width * 0.2), true)

	## The badge of a morning or an evening: a sun half over a line, with an arrow up (rising) or
	## down (setting), on a small cream tag.
	func horizon_sun(at: Vector2, rising: bool) -> void:
		var tag := Rect2(at - Vector2(30, 19), Vector2(60, 38))
		round_rect(tag, 10, ExplainPictures.PAPER, ExplainPictures.OUT, 2.0)
		var ground := at.y + 8.0
		var sun := Vector2(at.x - 9.0, ground)
		var color := Color8(255, 190, 40) if rising else Color8(240, 112, 48)
		var rays := Color8(255, 170, 30) if rising else Color8(226, 90, 40)
		for i in 5:
			var dir := Vector2.from_angle(deg_to_rad(-160.0 + 35.0 * i))
			line(PackedVector2Array([sun + dir * 14.0, sun + dir * 18.5]), rays, 2.4)
		fill(ExplainPictures.arc_points(sun, 11, 11, 180, 360, 0.0, 24), color)
		canvas.draw_polyline(ExplainPictures.arc_points(sun, 11, 11, 180, 360, 0.0, 24), color.lerp(Color.BLACK, 0.25), 1.6, true)
		line(PackedVector2Array([Vector2(tag.position.x + 7, ground), Vector2(tag.end.x - 7, ground)]), ExplainPictures.OUT, 2.6)
		var x := at.x + 16.0
		var y0 := ground - 3.0
		var y1 := tag.position.y + 6.0
		var from := Vector2(x, y0 if rising else y1)
		var to := Vector2(x, y1 if rising else y0)
		var dir := (to - from).normalized()
		line(PackedVector2Array([from, to - dir * 5.0]), ExplainPictures.ORGD, 3.0)
		fill(PackedVector2Array([to + dir * 1.5, to - dir * 6.0 + Vector2(5.5, 0), to - dir * 6.0 - Vector2(5.5, 0)]), ExplainPictures.ORGD)

	## The day half's mark: a small sun.
	func small_sun(c: Vector2) -> void:
		for i in 8:
			var dir := Vector2.from_angle(TAU * i / 8.0)
			line(PackedVector2Array([c + dir * 11.5, c + dir * 15.5]), ExplainPictures.SUN_RAY, 2.6)
		ellipse(c, 9, 9, ExplainPictures.YEL)
		ring(c, 9, 9, ExplainPictures.YELD, 1.8)

	## The night half's mark: a crescent moon and two small stars.
	func moon(c: Vector2) -> void:
		var disc := ExplainPictures.ellipse_points(c, 11, 11)
		var bite := ExplainPictures.ellipse_points(c + Vector2(5.5, -3.5), 9.5, 9.5)
		for part: PackedVector2Array in Geometry2D.clip_polygons(disc, bite):   # (no hole: the bite reaches past the disc)
			fill(part, Color8(255, 236, 150))
			ring_points(part, Color8(214, 176, 60), 1.4)
		for star: Vector3 in [Vector3(12, -12, 2.2), Vector3(14, 6, 1.6)]:
			fill(ExplainPictures.ellipse_points(c + Vector2(star.x, star.y), star.z, star.z, 10), Color8(255, 244, 200))
