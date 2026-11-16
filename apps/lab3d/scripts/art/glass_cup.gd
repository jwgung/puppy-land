## A glass of water for Curie Island's kitchen labs (#156, 2026-11-15; docs/islands/curie-missions.md):
## see-through water in a see-through glass with an opaque rim and foot, so what is inside can be seen
## (an ink cloud). Built at its foot (the origin), facing the front camera (+z).
## - set_hot(): wisps of steam rise over a hot glass (advance() moves them), none over a cold one;
## - show_spread(share, color): something spreading through the water from just under its top where
##   it went in (drop_point(): `drop_x` off the middle; a drop of ink, later the salt or the soap of the
##   next spots). 2026-11-16 user ("그냥 번지는 걸로 가자": no particles, only the spreading): a soft
##   cloud of CLOUD_LUMPS SoftCloud lumps (one MultiMesh; edges fade away, cores deeper). At first they
##   are one dense blob under the drop; as `share` (0..1) grows each lump, the lower ones later
##   (CLOUD_LAG), sinks to its own height and swells, so the ink hangs down in strands, until they fill
##   the water, which takes the colour evenly as they thin out. The lumps sway slowly (advance(),
##   `sway_rate` rad/s: faster in hot water);
## - water_box(): the water's inside (bottom, top, radius).
## The see-through things draw in a fixed order (render_priority, the *_PRIORITY constants): the water,
## the cloud, the glass shell, the steam; so the cloud reads inside the water and the shell over it.
## Visual only.
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
## The cloud: its lumps, how far behind each lower lump starts (a share of the spread), a lump's radius
## (m) as the drop's blob, how far a lump sways (m), how tall it ends against its slice of the water, its alpha at its densest and at a full spread (a
## share of the densest: the water's colour takes over), how much of its colour the whole water takes
## at a full spread.
const CLOUD_LUMPS := 5
const CLOUD_LAG := 0.12
const CLOUD_START := 0.09
const CLOUD_SWAY := 0.035
const CLOUD_TALL := 1.6
const CLOUD_ALPHA := 0.8
const CLOUD_THIN := 0.35
const WATER_TAKES := 0.85
## The draw order of the see-through things (render_priority; see the top).
const WATER_PRIORITY := 0
const CLOUD_PRIORITY := 1
const SHELL_PRIORITY := 2
const STEAM_PRIORITY := 3

var radius_bottom := 0.5
var radius_top := 0.6
var height := 1.3
var water_height := 1.05
var hot := false
## How far off the middle (x, m) things go into the water (under a dropper's tip).
var drop_x := 0.0
## How fast the cloud's lumps sway (rad/s; the lab sets it: faster in hot water).
var sway_rate := 0.8
## What is shown now (tests): the spread's share, each lump's centre and radii (local).
var shown_spread := 0.0
var lump_points := PackedVector3Array()
var lump_sizes := PackedVector3Array()
var water: MeshInstance3D
var cloud: MultiMeshInstance3D
var steam: Node3D
var water_material: StandardMaterial3D
var cloud_material: ShaderMaterial
var _t := 0.0


## A glass `glass_height` m tall, `bottom` and `top` m in radius, filled to `fill` m.
func _init(bottom := 0.5, top := 0.6, glass_height := 1.3, fill := 1.05) -> void:
	name = "Glass"
	radius_bottom = bottom
	radius_top = top
	height = glass_height
	water_height = fill
	water_material = _see_through(WATER_PRIORITY)
	water = ArtKit.instance(_water_mesh(), water_material)
	water.name = "Water"
	add_child(water)
	cloud_material = SoftCloud.material(Color.WHITE, CLOUD_ALPHA, CLOUD_PRIORITY)
	cloud = MultiMeshInstance3D.new()
	cloud.name = "Cloud"
	cloud.multimesh = MultiMesh.new()
	cloud.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	cloud.multimesh.mesh = SoftCloud.mesh()
	cloud.multimesh.instance_count = CLOUD_LUMPS
	cloud.material_override = cloud_material
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cloud.visible = false
	add_child(cloud)
	lump_points.resize(CLOUD_LUMPS)
	lump_sizes.resize(CLOUD_LUMPS)
	var rim := ArtKit.instance(_rim_mesh(), ArtKit.lit_material())
	rim.name = "Rim"
	add_child(rim)
	var shell := ArtKit.instance(_glass_mesh(), _see_through(SHELL_PRIORITY))
	shell.name = "Shell"
	add_child(shell)
	steam = Node3D.new()
	steam.name = "Steam"
	steam.visible = false
	add_child(steam)
	var wisp := _wisp_mesh()
	var steam_material := _see_through(STEAM_PRIORITY)
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


## Where a drop lands (local): the water's top, `drop_x` off its middle.
func drop_point() -> Vector3:
	return Vector3(drop_x, water_height - 0.08, 0.0)


func set_hot(on: bool) -> void:
	hot = on
	steam.visible = on


## Something spreading through the water: its cloud `share` (0..1) of the way through, in `color`.
func show_spread(share: float, color: Color) -> void:
	shown_spread = clampf(share, 0.0, 1.0)
	cloud.visible = share > 0.0
	SoftCloud.set_look(cloud_material, color, CLOUD_ALPHA * lerpf(1.0, CLOUD_THIN, shown_spread * shown_spread))
	var takes := WATER_TAKES * shown_spread * shown_spread
	water_material.albedo_color = Color.WHITE.lerp(Color(color.r, color.g, color.b, 1.0).lightened(0.25), takes)
	_place_lumps()


## How far lump `i` (0 the top one) has grown at spread `share`: the lower ones start later and all
## arrive together at a full spread (eased).
static func lump_share(i: int, share: float) -> float:
	var start := i * CLOUD_LAG
	var k := clampf((share - start) / (1.0 - start), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## Each lump where the spread puts it now, swaying: from the drop's blob down to its own slice of the
## water, as wide as the water and as tall as its slice (overlapping its neighbours), at a full spread.
func _place_lumps() -> void:
	var box := water_box()
	var top := drop_point()
	var slice := (box.y - box.x) / CLOUD_LUMPS
	for i in CLOUD_LUMPS:
		var k := lump_share(i, shown_spread)
		var phase := _t * sway_rate + i * 1.9
		var sway := CLOUD_SWAY * (1.0 - 0.5 * k) * Vector3(sin(phase), 0.0, cos(phase * 0.8))
		var y := lerpf(top.y - CLOUD_START * 0.5, box.y - slice * (i + 0.5), k)
		var centre := Vector3(lerpf(top.x, 0.0, k), y, 0.0) + sway * minf(1.0, shown_spread * 8.0)
		var flat := Vector2(centre.x, centre.z).limit_length(box.z)
		centre = Vector3(flat.x, clampf(centre.y, box.x, box.y), flat.y)
		var breathe := 1.0 + 0.06 * sin(phase * 1.3)
		var size := Vector3(lerpf(CLOUD_START, box.z + 0.05, k), lerpf(CLOUD_START, slice * CLOUD_TALL, k), lerpf(CLOUD_START, box.z + 0.05, k)) * breathe
		lump_points[i] = centre
		lump_sizes[i] = size
		cloud.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(size), centre))


## The cloud's lumps sway, the steam's wisps rise and fade over a hot glass (`delta` s).
func advance(delta: float) -> void:
	_t += delta
	if cloud.visible:
		_place_lumps()
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
