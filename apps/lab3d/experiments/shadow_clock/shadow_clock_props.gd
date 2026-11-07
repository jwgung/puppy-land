## The 그림자 시계 lab's props (#86; apps/lab3d/docs/art-direction.md): meshes only, posed from the model
## by ShadowClockLab._redraw(). World axes: x west, y up, z north (the view looks south).
## - a pale sand yard (a round plaza on the hill's grass), the stick in its middle: a wooden pole with
##   a red ball on top, short or long (the condition), on a little stone foot,
## - the sun: a big bright ball with rays, on its sky path (a dotted half-circle over the yard from the
##   east, on the left, through the south, behind the stick, to the west),
## - the stick's shadow: a dark band on the ground from the stick's foot to the tip, with a round dark
##   tip (the ball's shadow); it lies on whatever is under it (the sand, the bed's soil, the stone),
##   so the tip reads where it touches,
## - the flower bed west of the stick (on the right): dark soil ringed with flowers, kept low so the
##   shadow on it shows,
## - the far stone east of it (on the left): a big flat stone with a light ring where the tip must
##   land; the lidded chest with the piece (ShadowClockGame) stands on its far edge,
## - the bread cat behind the yard, watching the stick (it cheers at a stamp, ShadowClockGame).
## Everything the child must follow (the shadow, its tip, the bed, the stone) is in front of the stick
## and big: the shadows fall towards the camera. Visual only: no body, nothing the model reads.
class_name ShadowClockProps
extends RefCounted

const STICK_AT := Vector3.ZERO
## The sun's path's radius round the stick's foot (m), the sun's ball and the path's dots.
const SKY_RADIUS := 5.0
const SUN_RADIUS := 0.62
const SUN_SHADE := Color(1.0, 0.82, 0.6)
const PATH_DOT := 0.075
const PATH_STEP_DEG := 5.0
const PATH_COLOR := Color("fff1b8")
## The yard: a sand plaza on the grass.
const YARD_RADIUS := 5.8
const YARD_TOP := 0.03
const YARD_SAND := Color("f4e2b4")
const YARD_EDGE := Color("dcc58f")
## The stick: its radius, the ball on top, its stone foot.
const STICK_RADIUS := 0.11
const CAP_RADIUS := 0.2
const FOOT_RADIUS := 0.32
const STICK_WOOD := Color("b5793e")
const STICK_TOP := Color("cf9152")
## The shadow: its colour (a deep blue-violet, the style's never-black), its band's half width, the
## tip's radius, how far over what it lies on (m), its strip's pieces, and how far it may reach.
const SHADOW := ArtPalette.CAST_SHADOW
const SHADOW_HALF := 0.14
const TIP_RADIUS := 0.3
const SHADOW_LIFT := 0.018
const SHADOW_PIECES := 40
const SHADOW_MAX := 10.0
## The flower bed: its soil's radius and top, the flowers round its rim.
const BED_RADIUS := 0.78
const BED_TOP := 0.07
const BED_SOIL := Color("8a5a36")
const BED_SOIL_TOP := Color("9c6a40")
const FLOWERS := 11
const FLOWER_COLORS := [Color("ff4fa3"), Color("ffc61a"), Color("ffffff"), Color("ff7a1a")]
## The far stone: a flat stone (radius, top), the ring where the tip lands (lit when it is there).
const STONE_RADIUS := 0.85
const STONE_TOP := 0.13
const STONE := DayNightProps.ROCK
const STONE_FACE := DayNightProps.ROCK_TOP
const RING_COLOR := Color("fff3c4")
const RING_LIT := Color("ffd23a")
const RING_RADIUS := 0.32
const RING_WIDTH := 0.07
## The chest's place on the stone: its far left (south-east) edge, clear of where the tip lands and of
## the shadow coming in from the stick (on the right).
const CHEST_FROM_MIDDLE := Vector3(-0.42, 0.0, -0.42)
const CAT_AT := Vector3(2.6, 0.0, -2.2)

var cat: CatActor
var stick: Node3D               # the stick's place (its two poles under it)
var sun: Node3D                 # the sun's ball, on the path
var bed_at := Vector3.ZERO      # the bed's middle and the stone's middle (world, on the ground)
var stone_at := Vector3.ZERO
var _short: MeshInstance3D
var _long: MeshInstance3D
var _shadow: MeshInstance3D
var _ring: MeshInstance3D
var _key: Array = []
var bright_material: ShaderMaterial


## Builds the yard; `bed` and `stone` are the targets' middles (world, the model's), `path` the sun's
## path (world points).
func build(lab: Node3D, bed: Vector3, stone: Vector3, path: PackedVector3Array) -> void:
	bed_at = Vector3(bed.x, 0.0, bed.z)
	stone_at = Vector3(stone.x, 0.0, stone.z)
	ArtKit.add_world(lab, Vector3(0.0, 0.0, -0.5), null, 0.0)
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var yard := ArtKit.instance(_yard_mesh())
	yard.name = "Yard"
	lab.add_child(yard)
	var dots := ArtKit.instance(_path_mesh(path), bright_material)
	dots.name = "SunPath"
	lab.add_child(dots)
	stick = Node3D.new()
	stick.name = "Stick"
	stick.position = STICK_AT
	lab.add_child(stick)
	_short = ArtKit.instance(stick_mesh(ShadowClockModel.SHORT_STICK))
	_short.name = "ShortStick"
	stick.add_child(_short)
	_long = ArtKit.instance(stick_mesh(ShadowClockModel.LONG_STICK))
	_long.name = "LongStick"
	stick.add_child(_long)
	_ring = MeshInstance3D.new()
	_ring.name = "StoneRing"
	_ring.material_override = bright_material
	lab.add_child(_ring)
	_shadow = MeshInstance3D.new()
	_shadow.name = "Shadow"
	_shadow.material_override = bright_material
	lab.add_child(_shadow)
	sun = ArtKit.instance(_sun_mesh(), DayNightProps.lit_towards(Vector3(-0.35, 0.45, 0.82), Color.WHITE, SUN_SHADE, 0.03))
	sun.name = "Sun"
	lab.add_child(sun)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = stick
	cat.stand(CAT_AT)
	cat.advance(0.0)


## The sun at `sun_at`, the stick `height` m tall, its shadow's tip at `tip` (world, on the ground;
## the stick's foot without a shadow), the ring lit while the status is "stone".
func show(sun_at: Vector3, height: float, tip: Vector3, status: String) -> void:
	sun.position = sun_at
	var long := ShadowClockModel.is_long(height)
	_short.visible = not long
	_long.visible = long
	var key := [snappedf(tip.x, 0.001), snappedf(tip.z, 0.001), status == "stone"]
	if key == _key:
		return
	_key = key
	_shadow.mesh = shadow_mesh(Vector3(tip.x, 0.0, tip.z))
	_ring.mesh = _ring_mesh(status == "stone")


# --- the ground under the shadow ------------------------------------------------------------------

## The top of what lies at (x, z): the stone, the bed's soil, the yard's sand (or the grass past it).
func ground_at(x: float, z: float) -> float:
	var p := Vector2(x, z)
	if p.distance_to(Vector2(stone_at.x, stone_at.z)) <= STONE_RADIUS:
		return STONE_TOP
	if p.distance_to(Vector2(bed_at.x, bed_at.z)) <= BED_RADIUS:
		return BED_TOP
	return YARD_TOP if p.distance_to(Vector2(STICK_AT.x, STICK_AT.z)) <= YARD_RADIUS else 0.0


## The shadow from the stick's foot to `tip` (ground point): a band of SHADOW_PIECES pieces, each on
## what is under it, and the round tip (none when the tip is past SHADOW_MAX: the band ends there).
func shadow_mesh(tip: Vector3) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var foot := Vector3(STICK_AT.x, 0.0, STICK_AT.z)
	var along := tip - foot
	var length := along.length()
	if length < 1e-4:
		return b.commit()
	var dir := along / length
	var end := minf(length, SHADOW_MAX)
	var side := Vector3(-dir.z, 0.0, dir.x) * SHADOW_HALF
	var c := [SHADOW, SHADOW, SHADOW]
	for k in SHADOW_PIECES:
		var a := foot + dir * (end * k / SHADOW_PIECES)
		var e := foot + dir * (end * (k + 1) / SHADOW_PIECES)
		var mid := (a + e) * 0.5
		var y := ground_at(mid.x, mid.z) + SHADOW_LIFT
		var a0 := Vector3(a.x, y, a.z)
		var e0 := Vector3(e.x, y, e.z)
		b.add_triangle([a0 - side, e0 + side, e0 - side], c, Vector3.UP)
		b.add_triangle([a0 - side, a0 + side, e0 + side], c, Vector3.UP)
	if length <= SHADOW_MAX:
		ArtKit.flat_disc(b, Vector3(tip.x, ground_at(tip.x, tip.z) + SHADOW_LIFT * 1.5, tip.z), TIP_RADIUS, SHADOW, 16)
	return b.commit()


# --- the pieces -----------------------------------------------------------------------------------

## The stick `height` m tall (local: its foot at the origin): a stone foot, the wooden pole, the red ball.
static func stick_mesh(height: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = height
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, YARD_TOP, 0.0)), FOOT_RADIUS, FOOT_RADIUS * 0.8, 0.1, 10, STONE, true, STONE_FACE)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, YARD_TOP + 0.05, 0.0)), STICK_RADIUS, STICK_RADIUS * 0.85, height - CAP_RADIUS, 8, STICK_WOOD, true, STICK_TOP)
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, height, 0.0)), CAP_RADIUS, 4, 8, ArtPalette.RED)
	return b.commit()


func _sun_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), SUN_RADIUS, 6, 12, ArtPalette.YELLOW_TOP)
	for i in 12:   # rays round it, in the plane facing the camera: alternately long and short
		var a := TAU * i / 12.0 + PI / 12.0
		var out := Vector3(cos(a), sin(a), 0.0)
		var length := 0.34 if i % 2 == 0 else 0.24
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, out)), out * (SUN_RADIUS + 0.06)), 0.09, 0.0, length, 4, ArtPalette.YELLOW)
	return b.commit()


## The sun's path: a dot every PATH_STEP_DEG of it (bright: they read against the sky).
func _path_mesh(path: PackedVector3Array) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for p in path:
		b.add_sphere(Transform3D(Basis(), p), PATH_DOT, 3, 6, PATH_COLOR)
	return b.commit()


## The sand yard, the flower bed and the stone (the stone's ring is _ring_mesh).
func _yard_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.95
	b.ao_height = 0.2
	b.add_cylinder(Transform3D(Basis(), Vector3(STICK_AT.x, -0.02, STICK_AT.z)), YARD_RADIUS + 0.12, YARD_RADIUS + 0.12, 0.04, 40, YARD_EDGE)
	b.add_cylinder(Transform3D(Basis(), Vector3(STICK_AT.x, -0.02, STICK_AT.z)), YARD_RADIUS, YARD_RADIUS, YARD_TOP + 0.02, 40, YARD_SAND)
	# The flower bed: low soil, flowers on its rim (their heads low: the shadow on the soil shows).
	b.ao_min = 0.85
	b.add_cylinder(Transform3D(Basis(), bed_at), BED_RADIUS, BED_RADIUS * 0.96, BED_TOP, 16, BED_SOIL, true, BED_SOIL_TOP)
	for i in FLOWERS:
		var a := TAU * i / FLOWERS + 0.3
		var at := bed_at + Vector3(cos(a), 0.0, sin(a)) * (BED_RADIUS + 0.05)
		b.add_cylinder(Transform3D(Basis(), at), 0.02, 0.02, 0.16, 4, ArtPalette.STEM)
		b.add_sphere(Transform3D(Basis(), at + Vector3(0.0, 0.2, 0.0)), 0.075, 3, 6, FLOWER_COLORS[i % FLOWER_COLORS.size()])
		b.add_sphere(Transform3D(Basis(), at + Vector3(0.0, 0.215, 0.0)), 0.03, 2, 4, ArtPalette.YELLOW)
		b.add_sphere(Transform3D(Basis(Vector3.UP, a).scaled(Vector3(1.0, 0.35, 0.5)), at + Vector3(0.0, 0.07, 0.0)), 0.07, 2, 4, ArtPalette.LEAF_LIGHT)
	# The far stone: a big flat stone with a lighter face.
	b.add_cylinder(Transform3D(Basis(), stone_at), STONE_RADIUS * 1.04, STONE_RADIUS, STONE_TOP, 14, STONE, true, STONE_FACE)
	return b.commit()


## The ring where the tip must land on the stone (lit: the tip is there).
func _ring_mesh(lit: bool) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var color := RING_LIT if lit else RING_COLOR
	var c := stone_at + Vector3.UP * (STONE_TOP + SHADOW_LIFT * 0.5)
	var sides := 28
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var inner := RING_RADIUS - RING_WIDTH * 0.5
		var outer := RING_RADIUS + RING_WIDTH * 0.5
		b.add_triangle([c + d0 * inner, c + d1 * outer, c + d0 * outer], [color, color, color], Vector3.UP)
		b.add_triangle([c + d0 * inner, c + d1 * inner, c + d1 * outer], [color, color, color], Vector3.UP)
	return b.commit()
