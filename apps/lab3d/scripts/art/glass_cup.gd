## A glass of water for Curie Island's kitchen labs (#156, 2026-11-15; docs/islands/curie-missions.md):
## see-through water in a see-through glass with an opaque rim and foot, so what is inside can be seen
## (ParticleCloud dots, an ink cloud). Built at its foot (the origin), facing the front camera (+z).
## - set_hot(): wisps of steam rise over a hot glass (advance() moves them), none over a cold one;
## - show_spread(share, color): something spreading through the water from just under its top (a
##   drop of ink, later the salt or the soap of the next spots): a soft cloud that grows with `share`
##   (0..1) up to the whole water, which takes its colour as it fills;
## - water_box(): the water's inside (bottom, top, radius) for a ParticleCloud's `contain`.
## The glass's materials draw in a fixed order (render_priority): the water, then the cloud, then the
## glass shell, so the cloud reads inside the water and the shell over both. Visual only.
class_name GlassCup
extends Node3D

const SIDES := 24
const GLASS := Color(0.86, 0.95, 1.0, 0.24)
const GLASS_SHINE := Color(1.0, 1.0, 1.0, 0.5)
const RIM := Color("e8f6ff")
const FOOT_TOP := Color("f4fbff")
const WATER := Color(0.62, 0.84, 0.96, 0.62)
const WATER_TOP := Color(0.78, 0.92, 1.0, 0.75)
const STEAM := Color(1.0, 1.0, 1.0, 0.7)
## The wisps of steam over a hot glass: how many, how tall (m), how fast they rise and fade (1/s).
const WISPS := 3
const WISP_HEIGHT := 0.55
const WISP_RATE := 0.45
## The cloud's alpha at its densest, and how much of its colour the whole water takes at a full spread.
const CLOUD_ALPHA := 0.6
const WATER_TAKES := 0.85

var radius_bottom := 0.5
var radius_top := 0.6
var height := 1.3
var water_height := 1.05
var hot := false
## What is shown now (tests): the spread's share and the steam.
var shown_spread := 0.0
var water: MeshInstance3D
var cloud: MeshInstance3D
var steam: Node3D
var water_material: StandardMaterial3D
var cloud_material: StandardMaterial3D
var _t := 0.0


## A glass `glass_height` m tall, `bottom` and `top` m in radius, filled to `fill` m.
func _init(bottom := 0.5, top := 0.6, glass_height := 1.3, fill := 1.05) -> void:
	name = "Glass"
	radius_bottom = bottom
	radius_top = top
	height = glass_height
	water_height = fill
	water_material = _see_through(0)
	water = ArtKit.instance(_water_mesh(), water_material)
	water.name = "Water"
	add_child(water)
	cloud_material = _see_through(1)
	cloud = ArtKit.instance(_cloud_mesh(), cloud_material)
	cloud.name = "Cloud"
	cloud.visible = false
	add_child(cloud)
	var rim := ArtKit.instance(_rim_mesh(), ArtKit.lit_material())
	rim.name = "Rim"
	add_child(rim)
	var shell := ArtKit.instance(_glass_mesh(), _see_through(2))
	shell.name = "Shell"
	add_child(shell)
	steam = Node3D.new()
	steam.name = "Steam"
	steam.visible = false
	add_child(steam)
	var wisp := _wisp_mesh()
	var steam_material := _see_through(3)
	for i in WISPS:
		var w := ArtKit.instance(wisp, steam_material)
		w.name = "Wisp%d" % i
		w.position = Vector3((i - (WISPS - 1) * 0.5) * radius_top * 0.55, height, 0.0)
		steam.add_child(w)


## An unshaded, vertex-coloured, see-through material drawn in `priority` order.
static func _see_through(priority: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.render_priority = priority
	return m


## The glass's radius at height `y` over its foot.
func radius_at(y: float) -> float:
	return lerpf(radius_bottom, radius_top, clampf(y / height, 0.0, 1.0))


## The water's inside, local to the glass: (bottom, top, radius at mid-height minus a margin).
func water_box() -> Vector3:
	return Vector3(0.1, water_height - 0.06, radius_at(water_height * 0.5) - 0.1)


## Where a drop lands (local): the middle of the water's top.
func drop_point() -> Vector3:
	return Vector3(0.0, water_height - 0.08, 0.0)


func set_hot(on: bool) -> void:
	hot = on
	steam.visible = on


## Something spreading through the water: its cloud `share` (0..1) of the way through, in `color`.
func show_spread(share: float, color: Color) -> void:
	shown_spread = share
	cloud.visible = share > 0.0
	var box := water_box()
	var reach := share * maxf(box.y - box.x, box.z * 2.0)
	var rx := minf(maxf(reach, 0.06), box.z + 0.05)
	var ry := minf(maxf(reach, 0.06), (box.y - box.x) * 0.5 + 0.02)
	# From under the top (where the drop went in) down to the water's middle as it grows.
	var top := drop_point().y
	var mid := (box.x + box.y) * 0.5
	cloud.position = Vector3(0.0, lerpf(top - ry * 0.5, mid, clampf(share, 0.0, 1.0)), 0.0)
	cloud.scale = Vector3(rx, ry, rx)
	cloud_material.albedo_color = Color(color.r, color.g, color.b, CLOUD_ALPHA * lerpf(1.0, 0.75, share))
	var takes := WATER_TAKES * share * share
	water_material.albedo_color = Color.WHITE.lerp(Color(color.r, color.g, color.b, 1.0).lightened(0.25), takes)


## The steam's wisps rise and fade over a hot glass (`delta` s).
func advance(delta: float) -> void:
	_t += delta
	if not hot:
		return
	for i in steam.get_child_count():
		var w := steam.get_child(i) as Node3D
		var k := fposmod(_t * WISP_RATE + i / float(WISPS), 1.0)
		w.position.y = height + k * WISP_HEIGHT * 0.6
		w.scale = Vector3.ONE * lerpf(0.7, 1.15, k) * (1.0 - k * 0.35)
		w.rotation.y = 0.6 * sin(_t * 1.3 + i)


func _water_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.07, 0.0)), radius_bottom - 0.04, radius_at(water_height) - 0.04, water_height - 0.07, SIDES, WATER, true, WATER_TOP)
	return b.commit()


## A unit ball (scaled by show_spread to the cloud's reach).
static func _cloud_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 1.0
	b.add_sphere(Transform3D.IDENTITY, 1.0, 6, 14, Color.WHITE)
	return b.commit()


func _rim_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, height - 0.04, 0.0)), radius_top + 0.015, radius_top + 0.015, 0.05, SIDES, RIM, false)
	b.add_cylinder(Transform3D(Basis(), Vector3.ZERO), radius_bottom + 0.02, radius_bottom + 0.01, 0.07, SIDES, RIM, true, FOOT_TOP)
	return b.commit()


## The glass: a see-through shell with two light shine stripes on its front left.
func _glass_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(), radius_bottom + 0.01, radius_top, height, SIDES, GLASS, false)
	for stripe: Array in [[-0.62, 0.07], [-0.4, 0.035]]:   # angle (rad from the front, to the left), width (rad)
		var a: float = float(stripe[0]) + PI * 0.5
		var w: float = stripe[1]
		var y0 := height * 0.12
		var y1 := height * 0.88
		var p := [_point(a - w, y0), _point(a + w, y0), _point(a + w, y1), _point(a - w, y1)]
		b.add_triangle([p[0], p[1], p[2]], [GLASS_SHINE, GLASS_SHINE, GLASS_SHINE], Vector3.BACK)
		b.add_triangle([p[0], p[2], p[3]], [GLASS_SHINE, GLASS_SHINE, GLASS_SHINE], Vector3.BACK)
	return b.commit()


func _point(a: float, y: float) -> Vector3:
	var r := radius_at(y) + 0.012
	return Vector3(cos(a) * r, y, sin(a) * r)


## A wisp of steam: a soft S of small balls rising WISP_HEIGHT from its foot.
static func _wisp_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 1.0
	var n := 7
	for k in n:
		var u := k / float(n - 1)
		var at := Vector3(0.08 * sin(u * TAU), u * WISP_HEIGHT, 0.0)
		b.add_sphere(Transform3D(Basis(), at), lerpf(0.07, 0.04, u), 3, 8, Color(STEAM.r, STEAM.g, STEAM.b, STEAM.a * (1.0 - u * 0.6)))
	return b.commit()
