## A soft see-through cloud (#156, 2026-11-16 user: the ink spreading in water as a soft blue cloud,
## not a dark disc; the bread's smell as a soft warm one): a few overlapping smooth lumps inside the unit
## ball (scale the node to the cloud's size) drawn with soft_cloud.gdshader, whose edges fade away and
## whose core is a little deeper. One mesh, one material per cloud (its colour and density change):
##   var haze := ArtKit.instance(SoftCloud.mesh(), SoftCloud.material(Color("4f7cf0"), 0.6, 1))
##   SoftCloud.set_look(haze.material_override, color, density)
class_name SoftCloud
extends RefCounted

const SHADER := preload("res://scripts/art/soft_cloud.gdshader")
## The lumps: (centre x, y, z, radius) in the unit ball, and their rings and sides (smooth normals: the
## fade follows them, so a few rings are enough).
const LUMPS := [Vector4(0.0, 0.0, 0.0, 0.78), Vector4(0.35, 0.25, 0.1, 0.55), Vector4(-0.38, 0.1, -0.15, 0.55),
	Vector4(0.05, -0.35, 0.2, 0.5)]
const RINGS := 6
const SIDES := 12
## How fast a lump's alpha falls towards its edge, and the core's colour as a share of the edge's.
const EDGE := 1.3
const CORE := 0.7

static var _mesh: Mesh


## The shared lumps (white: the material colours them).
static func mesh() -> Mesh:
	if _mesh == null:
		var b := ArtKit.builder()
		b.flat = false
		b.ao_min = 1.0
		for lump: Vector4 in LUMPS:
			b.add_sphere(Transform3D(Basis(), Vector3(lump.x, lump.y, lump.z)), lump.w, RINGS, SIDES, Color.WHITE)
		_mesh = b.commit()
	return _mesh


## A cloud's own material in `color` (sRGB) at `density` (alpha where it faces the eye), drawn in
## `priority` order among the see-through things (GlassCup's order).
static func material(color: Color, density: float, priority: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.render_priority = priority
	m.set_shader_parameter("edge", EDGE)
	m.set_shader_parameter("core", CORE)
	set_look(m, color, density)
	return m


static func set_look(m: ShaderMaterial, color: Color, density: float) -> void:
	var lin := color.srgb_to_linear()
	m.set_shader_parameter("tint", Vector4(lin.r, lin.g, lin.b, 1.0))
	m.set_shader_parameter("density", density)
