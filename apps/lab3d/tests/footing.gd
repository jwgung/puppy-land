## What a cast member stands on in a lab (2026-11-16 user: the hutton keeper stood in the sea, in a pond,
## sunk in a stage): the lab's meshes (not the cast, the bread cat or the flat blob shadows) as triangles,
## and vertical rays through them. A spot is dry ground when, round the feet (y = 0), the topmost surface
## up to HEAD m is the island's ground (GROUND) at the feet's height (within FLAT m: the clearing is flat at
## y = 0, LabWorld): a surface higher sinks the feet in it, a lower one (the sea, a pond, a river bed, all
## below the clearing) leaves them over it, a lab mesh named for water (WATER_WORDS) is water, and any other
## lab mesh there at the feet's height is a floor of the lab (a space stage, the yard, a terrace: flat, the
## cast may stand on it as Puppy does).
extends RefCounted

const BIN := 1.0           # m: the triangles are binned on the ground by this
const HEAD := 1.4          # m above the feet: higher things (clouds, the sun, a tree's top) are not underfoot
const FLAT := 0.04         # m the surface underfoot may be off the feet's height
const FOOT := 0.25         # m round the feet sampled (the middle and 8 round it)
const GROUND := "island"   # the lab's corner of the island (LabWorld): the only ground to stand on
const WATER_WORDS := ["sea", "water", "pond", "river", "lake", "ocean", "basin", "foam", "wave", "rain", "swirl", "wisp", "cloud"]

var _tris := PackedVector3Array()
var _names: PackedStringArray = []
var _bins := {}            # Vector2i -> PackedInt32Array of triangle indices


## The triangles of `lab`'s visible meshes but those under `skip` (the cast) and the shadows.
func _init(lab: Node, skip: Array = []) -> void:
	for m in lab.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or String(mi.name).contains("Shadow"):
			continue
		var skipped := false
		for root: Node in skip:
			if root != null and (root == mi or root.is_ancestor_of(mi)):
				skipped = true
		if skipped or _under_class(mi, "CatActor"):
			continue
		var xf := mi.global_transform
		var name := String(mi.name).to_lower()
		for si in mi.mesh.get_surface_count():
			if mi.mesh.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arrays := mi.mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var index: Variant = arrays[Mesh.ARRAY_INDEX]
			var tri: PackedInt32Array = index if index != null else PackedInt32Array(range(v.size()))
			for t in range(0, tri.size() - 2, 3):
				var a := xf * v[tri[t]]
				var b := xf * v[tri[t + 1]]
				var c := xf * v[tri[t + 2]]
				var k := _names.size()
				_tris.append(a)
				_tris.append(b)
				_tris.append(c)
				_names.append(name)
				var lo := Vector2i(floori(minf(a.x, minf(b.x, c.x)) / BIN), floori(minf(a.z, minf(b.z, c.z)) / BIN))
				var hi := Vector2i(floori(maxf(a.x, maxf(b.x, c.x)) / BIN), floori(maxf(a.z, maxf(b.z, c.z)) / BIN))
				if (hi - lo).x > 40 or (hi - lo).y > 40:   # (a sky dome or the far sea: never underfoot within reach)
					lo = lo.clamp(Vector2i(-40, -40), Vector2i(40, 40))
					hi = hi.clamp(Vector2i(-40, -40), Vector2i(40, 40))
				for x in range(lo.x, hi.x + 1):
					for z in range(lo.y, hi.y + 1):
						var key := Vector2i(x, z)
						if not _bins.has(key):
							_bins[key] = PackedInt32Array()
						var list: PackedInt32Array = _bins[key]
						list.append(k)
						_bins[key] = list


static func _under_class(node: Node, cls: String) -> bool:
	var n := node
	while n != null:
		if n.get_class() == cls or (n.get_script() != null and (n.get_script() as Script).get_global_name() == cls):
			return true
		n = n.get_parent()
	return false


## The surfaces a vertical line at (x, z) meets from `bottom` to `top` m: [[y, mesh name], ...], highest first.
func hits(x: float, z: float, bottom := -1.0, top := HEAD) -> Array:
	var out := []
	var p := Vector2(x, z)
	for k: int in _bins.get(Vector2i(floori(x / BIN), floori(z / BIN)), PackedInt32Array()):
		var a := _tris[3 * k]
		var b := _tris[3 * k + 1]
		var c := _tris[3 * k + 2]
		var bary := _bary(p, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z))
		if bary == Vector3.INF:
			continue
		var y := a.y * bary.x + b.y * bary.y + c.y * bary.z
		if y >= bottom and y <= top:
			out.append([y, _names[k]])
	out.sort_custom(func(u: Array, w: Array) -> bool: return u[0] > w[0])
	return out


static func _bary(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Vector3:
	var d := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	if absf(d) < 1e-9:
		return Vector3.INF
	var u := ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / d
	var v := ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / d
	var w := 1.0 - u - v
	if u < -1e-6 or v < -1e-6 or w < -1e-6:
		return Vector3.INF
	return Vector3(u, v, w)


## Feet that stand: on the island's ground or a lab's floor.
static func stands(kind: String) -> bool:
	return kind in ["dry", "floor"]


## What the feet at (x, z) on y = `feet` stand on: "dry", "sunk" (a surface above the feet: in a stage, a
## basin's water, a cloud), "over" (the topmost surface below the feet: over the sea, a pond, a river),
## "water" (a water mesh at the feet's height), "floor" (a lab's flat floor at the feet's height: standing
## ground too) or "nothing"; with the worst sample's surface [y, name].
func footing(x: float, z: float, feet := 0.0) -> Array:
	var worst := ["dry", []]
	var rank := {"dry": 0, "floor": 1, "over": 2, "water": 3, "nothing": 4, "sunk": 5}
	for i in 9:
		var q := Vector2(x, z) + (Vector2.ZERO if i == 0 else Vector2.from_angle(TAU * i / 8.0) * FOOT)
		var top := hits(q.x, q.y, feet - 1.0, feet + HEAD)
		var kind := "nothing"
		var surface: Array = top[0] if not top.is_empty() else []
		if not top.is_empty():
			var y: float = surface[0]
			if y > feet + FLAT:
				kind = "sunk"
			elif y < feet - FLAT:
				kind = "over"
			elif is_water(str(surface[1])):
				kind = "water"
			elif str(surface[1]) != GROUND:
				kind = "floor"
			else:
				kind = "dry"
		if rank[kind] > rank[worst[0]]:
			worst = [kind, surface]
	return worst


static func is_water(mesh_name: String) -> bool:
	for word in WATER_WORDS:
		if mesh_name.contains(word):
			return true
	return false
