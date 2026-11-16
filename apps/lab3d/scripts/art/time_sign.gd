## The time sign of the labs whose change takes days (#157 소금 말리기 first, #159 반죽 next; the approved
## plan's decision 1, 안 A, and its mockup "시간 빨리 감기 막대"): the wooden sign of Hutton Island's 물의
## 여행 (a bar in a wooden frame, a sun at its left end and a moon at its right), standing on two posts
## in the scene. Here the bar shows the time gone by, not the sunshine left: its left half is the day
## (light yellow), its right half the night (navy), and a white marker with a red ring goes from the
## sun to the moon (FastClock.share()). While the time flows a red fast-forward lamp (▶▶, no words)
## shines over the bar's right end; every night gone by puts a little moon stamp on the board under
## the sign (FastClock.nights(), no number). The child only looks at it: the lab's own object starts
## the time (FastClock.start()).
##
## The node's origin is the bar's middle (its face towards +z, the camera); `posts_to` is how far down
## (m) its two posts reach (to the table's top under it). show() / show_clock() pose it. The static
## frame_mesh() / face_mesh() are the 물의 여행 sign's own (WaterCycleProps draws its sign with them: one
## colour track there). Visual only: no body, nothing a model or a mission reads.
class_name TimeSign
extends Node3D

## The bar (m): as long and tall as the 물의 여행 sign's.
const BAR := Vector2(1.6, 0.3)
## The ends of the bar: the sun's ball and rays, the moon, its dark bite (the frame's wood, a little darker).
const SUN_BALL := Color("ffe36a")
const SUN_RAY := Color("ffc61a")
const MOON := Color("f4f1d0")
## The bar's halves: the day and the night.
const DAY_HALF := Color("ffe58a")
const NIGHT_HALF := Color("23306e")
## The marker: a white disc in a red ring.
const MARKER := Color("ffffff")
const MARKER_RING := Color("e34b3f")
const MARKER_R := 0.13
## The fast-forward lamp over the bar's right end (a red pill, two white triangles).
const LAMP := Color("e34b3f")
const LAMP_SIZE := Vector2(0.5, 0.26)
## The moon stamps: their board under the sign, a stamp's radius and the gap between stamps (m); the
## most stamps the board shows (more nights put no more on it).
const STAMP_BOARD := Vector2(1.1, 0.26)
const STAMP_R := 0.085
const STAMP_GAP := 0.24
const STAMPS_MAX := 4
## The posts (m): their radii, their spread from the bar's middle, how far behind the face.
const POST_R := Vector2(0.05, 0.04)
const POST_SPREAD := 0.38
const POST_BACK := 0.08

## The marker (moved along the bar), the lamp, the stamps' board.
var marker: MeshInstance3D
var lamp: MeshInstance3D
var stamps: MeshInstance3D
var bright_material: ShaderMaterial
## What it shows now (tests): the marker's share (0 sun .. 1 moon), the stamps, the lamp on.
var shown_share := 0.0
var shown_nights := 0
var shown_running := false
var _stamps_built := -1


## A sign whose posts reach `posts_to` m down from the bar's middle.
func _init(posts_to := 1.0) -> void:
	name = "TimeSign"
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var posts := ArtKit.instance(posts_mesh(posts_to))
	posts.name = "Posts"
	add_child(posts)
	var frame := ArtKit.instance(frame_mesh(BAR))
	frame.name = "Frame"
	add_child(frame)
	var face := ArtKit.instance(face_mesh(BAR, DAY_HALF, NIGHT_HALF), bright_material)
	face.name = "Face"
	add_child(face)
	marker = ArtKit.instance(_marker_mesh(), bright_material)
	marker.name = "Marker"
	add_child(marker)
	lamp = ArtKit.instance(_lamp_mesh(), bright_material)
	lamp.name = "FastLamp"
	lamp.position = Vector3(BAR.x * 0.5 - LAMP_SIZE.x * 0.3, BAR.y * 0.5 + 0.14 + LAMP_SIZE.y * 0.5, 0.06)
	lamp.visible = false
	add_child(lamp)
	stamps = MeshInstance3D.new()
	stamps.name = "MoonStamps"
	stamps.material_override = bright_material
	stamps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stamps.position = Vector3(0.0, -BAR.y * 0.5 - 0.14 - 0.06 - STAMP_BOARD.y * 0.5, 0.02)
	add_child(stamps)
	show_time(0.0, 0, false)


## Poses the sign for the clock now.
func show_clock(clock: FastClock) -> void:
	show_time(clock.share(), clock.nights(), clock.running)


## The marker at `share` (0 the sun end .. 1 the moon end), `nights` moon stamps, the lamp on while
## `running`.
func show_time(share: float, nights: int, running: bool) -> void:
	shown_share = clampf(share, 0.0, 1.0)
	shown_nights = maxi(nights, 0)
	shown_running = running
	marker.position = marker_point(shown_share)
	lamp.visible = running
	var n := mini(shown_nights, STAMPS_MAX)
	if n != _stamps_built:
		_stamps_built = n
		stamps.mesh = _stamps_mesh(n)
	stamps.visible = n > 0


## Where the marker's middle is (local) at `share`: inside the bar from its sun end to its moon end.
static func marker_point(share: float) -> Vector3:
	var inner := BAR.x * 0.5 - BAR.y * 0.5
	return Vector3(lerpf(-inner, inner, clampf(share, 0.0, 1.0)), 0.0, 0.07)


## Where moon stamp `i` (0 the first night) sits (local to the sign).
func stamp_point(i: int) -> Vector3:
	var n := maxi(mini(shown_nights, STAMPS_MAX), 1)
	return stamps.position + Vector3((i - (n - 1) * 0.5) * STAMP_GAP, 0.0, 0.03)


# --- meshes -------------------------------------------------------------------------------------------

## The two wooden posts (local: from the bar's middle down `posts_to` m, behind the face).
static func posts_mesh(posts_to: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = posts_to
	for side: float in [-1.0, 1.0]:
		b.add_cylinder(Transform3D(Basis(), Vector3(side * BAR.x * POST_SPREAD, -posts_to, -POST_BACK)), POST_R.x, POST_R.y, posts_to, 6, ArtPalette.WOOD_GRAIN)
	return b.commit()


## The sign's wooden frame round a bar of size `bar` and its two ends (local to the sign, centred on
## the bar). The 물의 여행 sign's.
static func frame_mesh(bar: Vector2) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	WindowArt.add_frame(b, Rect2(Vector2(-bar.x * 0.5 - 0.5, -bar.y * 0.5 - 0.14), Vector2(bar.x + 1.0, bar.y + 0.28)), 0.1, 0.1, 0.025, 0.2)
	return b.commit()


## The bar's track (its left half `left`, its right half `right`: one rounded track when they are the
## same colour, the 물의 여행 sign's), the sun at its left end and the moon at its right (local to the
## sign: bright, facing the camera).
static func face_mesh(bar: Vector2, left: Color, right: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	if left == right:
		b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.0, 0.02)), Vector3(bar.x, bar.y, 0.03), bar.y * 0.49, 3, left)
	else:
		# Two halves meeting in the middle, each round at its outer end only (a straight seam).
		var r := bar.y * 0.49
		b.add_rounded_box(Transform3D(Basis(), Vector3(-bar.x * 0.25, 0.0, 0.02)), Vector3(bar.x * 0.5, bar.y, 0.03), r, 3, left)
		b.add_rounded_box(Transform3D(Basis(), Vector3(bar.x * 0.25, 0.0, 0.02)), Vector3(bar.x * 0.5, bar.y, 0.03), r, 3, right)
		b.add_rounded_box(Transform3D(Basis(), Vector3(-bar.x * 0.125, 0.0, 0.021)), Vector3(bar.x * 0.25, bar.y, 0.03), 0.0, 1, left)
		b.add_rounded_box(Transform3D(Basis(), Vector3(bar.x * 0.125, 0.0, 0.021)), Vector3(bar.x * 0.25, bar.y, 0.03), 0.0, 1, right)
	var sun := Vector3(-bar.x * 0.5 - 0.25, 0.0, 0.05)
	ArtKit.disc(b, sun, bar.y * 0.42, SUN_BALL, 14)
	for k in 8:
		var a := TAU * k / 8.0
		var d := Vector3(cos(a), sin(a), 0.0)
		_ray(b, sun + d * bar.y * 0.5, sun + d * bar.y * 0.68, 0.045, SUN_RAY)
	var moon := Vector3(bar.x * 0.5 + 0.25, 0.0, 0.05)
	ArtKit.disc(b, moon, bar.y * 0.48, MOON, 14)
	ArtKit.disc(b, moon + Vector3(bar.y * 0.2, bar.y * 0.1, 0.003), bar.y * 0.4, WindowArt.FRAME_COLOR.darkened(0.15), 14)
	return b.commit()


## A flat strip from `from` to `to` facing the camera, `width` wide (a sun ray).
static func _ray(b: ArtMeshBuilder, from: Vector3, to: Vector3, width: float, color: Color) -> void:
	var along := to - from
	var side := Vector3(-along.y, along.x, 0.0).normalized() * width * 0.5
	b.add_triangle([from - side, to - side, to + side], [color, color, color], Vector3.BACK)
	b.add_triangle([from - side, to + side, from + side], [color, color, color], Vector3.BACK)


## The marker: a white disc in a red ring (its middle at the origin).
static func _marker_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	ArtKit.disc(b, Vector3.ZERO, MARKER_R, MARKER_RING, 18)
	ArtKit.disc(b, Vector3(0.0, 0.0, 0.004), MARKER_R * 0.68, MARKER, 18)
	return b.commit()


## The fast-forward lamp: a red pill with two white triangles pointing right (▶▶).
static func _lamp_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(), Vector3(LAMP_SIZE.x, LAMP_SIZE.y, 0.04), LAMP_SIZE.y * 0.49, 3, LAMP)
	var h := LAMP_SIZE.y * 0.28
	for k in 2:
		var x := (k - 0.5) * h * 1.7 - h * 0.3
		var w := Color.WHITE
		b.add_triangle([Vector3(x, -h, 0.025), Vector3(x + h * 1.5, 0.0, 0.025), Vector3(x, h, 0.025)], [w, w, w], Vector3.BACK)
	return b.commit()


## The board under the sign with `count` little moons on it (none: no board).
static func _stamps_mesh(count: int) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	if count <= 0:
		return b.commit()
	var width := maxf(STAMP_BOARD.y, STAMP_GAP * count + 0.06)
	b.add_rounded_box(Transform3D(), Vector3(width, STAMP_BOARD.y, 0.04), 0.04, 1, ArtPalette.WOOD_GRAIN, ArtPalette.WOOD)
	for i in count:
		var at := Vector3((i - (count - 1) * 0.5) * STAMP_GAP, 0.0, 0.025)
		ArtKit.disc(b, at, STAMP_R, MOON, 14)
		ArtKit.disc(b, at + Vector3(STAMP_R * 0.42, STAMP_R * 0.2, 0.003), STAMP_R * 0.82, ArtPalette.WOOD_GRAIN, 14)
	return b.commit()
