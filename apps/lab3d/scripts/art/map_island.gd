## The island map's own island (home screen, 2026-10-27 user decision "지도 전체 손보기"): an
## irregular coastline with a sand beach in a sea that fills the view, the zones as ground (a
## meadow, hills, a sandy play yard, a pond), dirt paths between the spots, each spot's landmark
## (MapLandmarks) on a round stage, and trees, rocks, flowers and clouds placed clear of them.
## The hutton island (#72) adds two grounds and its features (Island.features): a sand `coast` zone
## running into the beach with a lighthouse, a `valley` whose grass rises to an asleep volcano with a
## river from its foot to the sea, and the sundial on the square (where its story's pieces gather).
## The labs stand on a close-up corner of this same island (LabWorld: its coast, hills, zones,
## landmarks and material, seen from the lab's spot).
##
## Draw calls: one static opaque mesh (landmarks, water: shallows, surf, pond; land: top, beach,
## overlays, trees with their baked blob shadows, clouds) in map_lit.gdshader (art_lit's light,
## encoded per vertex), no texture, no light, no blending, no animation. The open sea is the clear
## colour. Measured on SM-P200 at a 450 MHz GPU lock (2026-10-27), see map_lit.gdshader and _add_sea. The top is a polar grid over the coast whose vertices are jittered for the
## low-poly facets; height_at() reads that same mesh, so the paths, stages and the cat sit on it.
class_name MapIsland
extends RefCounted

## The layout (zones and spots, the cat's square, the paths, the coast, the decoration) is the
## island's data (Island, content/islands/<island>.json); the constants below are how any island is
## built. Screen up is -z at the default view.

## The top grid: rings as fractions of the coast radius, SECTORS around. Rings from GRASS_EDGE
## out are the beach, at the heights BEACH_Y (the last ring dips under the sea: the shoreline).
const SECTORS := 60
const RINGS := [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.58, 0.66, 0.73, 0.8, 0.86, 0.93, 1.0]
const GRASS_EDGE := 10
const BEACH_Y := [0.0, -0.06, -0.45]
const JITTER := 0.3                 # share of a grid cell the inner vertices move (facets)
const HILL_PLATEAU := 0.35          # share of a hill's radius that is its flat top
const SEA_Y := -0.2
const SHORE_F := 0.955              # coast fraction where the beach meets the sea (BEACH_Y at SEA_Y)
const SHALLOW := 1.0                # m of light shallow water outside the coast
const PATH_WIDTH := 0.8
const PATH_STEP := 0.35             # m between a drawn path's samples (the walk's way uses the same)
const PATH_LIFT := 0.05             # m above the grass (no z-fight at 34 m)
const OVERLAY_LIFT := 0.03          # yard sand, pond shore
const PLAZA_LIFT := 0.07
const PLAZA_RADIUS := 1.35
## Decoration: the island's trees, rocks, clouds and wave strokes; the flowers are scattered
## (seeded) where nothing else stands.
## The sky backdrop: a cylinder SKY_RADIUS m round the island whose foot is the horizon (the sea, the
## clear colour, ends there), hazy towards it; and a haze band on the far sea.
const SKY_RADIUS := 400.0
const FLOWER_SEED := 27
const MEADOW_FLOWERS := 22
const OTHER_FLOWERS := 18
## The hutton island's features (#72). The valley's ground rises VALLEY_HEIGHT m (a zone's `height`
## overrides it) to its volcano, falling off over the zone; the river is a ribbon RIVER_WIDTH m wide
## at its source, RIVER_MOUTH m where it meets the sea; the sundial stands SUNDIAL_AT from the square's
## middle, behind the three friends' row.
const VALLEY_HEIGHT := 1.2
const RIVER_WIDTH := 0.55
const RIVER_MOUTH := 0.95
## The river lies RIVER_LIFT over the ground: between the yard's sand (OVERLAY_LIFT) and the paths
## (PATH_LIFT), so it neither fights the grass nor covers a path's end (LabWorld lifts its own more:
## its ground's faces stray further from the smooth surface, LabWorld.RIVER_LIFT).
const RIVER_LIFT := 0.04
const SUNDIAL_AT := Vector2(0.0, -0.85)
## The volcano's foot ring sits this far under the lowest ground round it (no gap on a slope).
const VOLCANO_SINK := 0.25
## The coast zone's sand edge wavers: [order, share of the radius, phase] round its middle.
const COAST_WAVER := [[3.0, 0.07, 1.0], [5.0, 0.04, 0.3]]
const LIGHTHOUSE_CLEAR := 0.8        # m round the lighthouse kept clear of decoration

var island: Island
var zones: Dictionary
var paths: Array
var home: Vector2
var _grid: Array = []               # rings x sectors of Vector3 (the top's vertices)
var _hills: Array = []              # [centre Vector2, radius, height]
var _valleys: Array = []            # [top Vector2 (the volcano's middle), reach, height]
## Built pieces, for tests: path samples (Vector2), decorations [kind, x, z, radius], per spot.
var path_points := PackedVector2Array()
var decorations: Array = []
var spot_info: Dictionary = {}
## The river as drawn: its samples (x, z) and the ribbon's width at each (#72).
var river_points := PackedVector2Array()
var river_widths := PackedFloat32Array()


## The map of `of` (Island: its zones, paths, square and coast).
func _init(of: Island) -> void:
	island = of
	zones = island.zones
	paths = island.paths
	home = island.home
	for zone in zones:
		var spec: Dictionary = zones[zone]
		if spec.ground == "hill":
			_hills.append([_v2(spec.at), float(spec.radius), float(spec.height)])
		elif spec.ground == "valley":   # rising to the volcano (else the zone's middle) from its far side
			var top := _v2(island.features.volcano.at) if island.features.has("volcano") else _v2(spec.at)
			_valleys.append([top, top.distance_to(_v2(spec.at)) + float(spec.radius), float(spec.get("height", VALLEY_HEIGHT))])
	if island.features.has("river"):
		river_points = path_samples(island.features.river, PATH_STEP)
		var along := PackedFloat32Array([0.0])   # the length up to each sample
		for k in range(1, river_points.size()):
			along.append(along[k - 1] + river_points[k - 1].distance_to(river_points[k]))
		var total := maxf(along[along.size() - 1], 0.001)
		for k in river_points.size():
			river_widths.append(lerpf(RIVER_WIDTH, RIVER_MOUTH, along[k] / total))
	_build_grid()


# --- the shape --------------------------------------------------------------------------------

## The coast's distance from the island centre in the direction `theta` (atan2(z, x)).
func coast_radius(theta: float) -> float:
	var c := cos(theta)
	var s := sin(theta)
	var rx := island.radius_x
	var rz := island.radius_z
	var r := 1.0 / sqrt(c * c / (rx * rx) + s * s / (rz * rz))
	for w in island.coast_waves:
		r += w[1] * sin(w[0] * theta + w[2])
	for bump in island.coast_bumps:
		var t := angle_difference(theta, deg_to_rad(bump[0])) / deg_to_rad(bump[2])
		r += bump[1] * exp(-t * t)
	return r


## How far out (x, z) lies: 0 at the centre, 1 on the coast; the grass ends at RINGS[GRASS_EDGE].
func coast_fraction(x: float, z: float) -> float:
	return Vector2(x, z).length() / coast_radius(atan2(z, x))


static func grass_edge() -> float:
	return RINGS[GRASS_EDGE]


## The top's height at (x, z): the mesh itself (its triangle there), so what stands on it sits on
## the faces drawn, not on the smooth curve they approximate. Off the island: the sunk last ring.
func height_at(x: float, z: float) -> float:
	var theta := atan2(z, x)
	var f := coast_fraction(x, z)
	if f >= 1.0:
		return BEACH_Y[-1]
	var i0 := int(floor(fposmod(theta, TAU) / TAU * SECTORS))
	var j0 := 0
	while j0 < RINGS.size() - 2 and RINGS[j0 + 1] <= f:
		j0 += 1
	var p := Vector2(x, z)
	for dj in [0, -1, 1]:
		var j: int = j0 + dj
		if j < 0 or j >= RINGS.size() - 1:
			continue
		for di in [0, -1, 1, -2, 2]:
			var i := posmod(i0 + di, SECTORS)
			var quad := _quad(j, i)
			for tri in [[quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]]:
				var w := _bary(p, tri)
				if w.x >= -1e-4 and w.y >= -1e-4 and w.z >= -1e-4:
					return w.x * tri[0].y + w.y * tri[1].y + w.z * tri[2].y
	return _ground_height(x, z, f, RINGS.size() - 1)


## Where the cat stands at (x, z): the ground plus the square or path it is on.
func walk_height(x: float, z: float) -> float:
	var lift := PLAZA_LIFT if Vector2(x, z).distance_to(home) < PLAZA_RADIUS else PATH_LIFT
	return height_at(x, z) + lift


## True when (x, z) is in the pond's or the river's water.
func water_at(x: float, z: float) -> bool:
	if not river_points.is_empty() and river_distance(x, z) < 0.0:
		return true
	for zone in zones:
		var spec: Dictionary = zones[zone]
		if spec.ground == "pond" and Vector2(x, z).distance_to(_v2(spec.at)) < _pond_radius(spec, atan2(z - spec.at[1], x - spec.at[0])):
			return true
	return false


## The hills' height at (x, z), fading out towards the beach like the top (the labs' far ground,
## LabWorld, reads it).
func hill_height(x: float, z: float) -> float:
	return _hill_height(x, z) * (1.0 - smoothstep(0.76, grass_edge(), coast_fraction(x, z)))


func _hill_height(x: float, z: float) -> float:
	var h := 0.0
	for hill in _hills:
		var d: float = Vector2(x, z).distance_to(hill[0]) / hill[1]
		if d < 1.0:
			var t := clampf((d - HILL_PLATEAU) / (1.0 - HILL_PLATEAU), 0.0, 1.0)
			h = maxf(h, hill[2] * (1.0 - t * t * (3.0 - 2.0 * t)))
	for valley in _valleys:   # one long slope, no plateau: the volcano stands on its top
		var d: float = Vector2(x, z).distance_to(valley[0]) / valley[1]
		if d < 1.0:
			h = maxf(h, valley[2] * (1.0 - d * d * (3.0 - 2.0 * d)))
	return h


## How far (x, z) is outside the river's ribbon (m; negative inside it). INF without a river.
func river_distance(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := INF
	for k in river_points.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, river_points[k], river_points[k + 1])
		best = minf(best, p.distance_to(q) - river_widths[k] * 0.5)
	return best


## The height of a grid vertex at (x, z) on ring `ring`: hills inside the grass, the beach
## profile from the grass edge out.
func _ground_height(x: float, z: float, f: float, ring: int) -> float:
	if ring >= GRASS_EDGE:
		return BEACH_Y[ring - GRASS_EDGE]
	return _hill_height(x, z) * (1.0 - smoothstep(0.76, RINGS[GRASS_EDGE], f))


func _build_grid() -> void:
	_grid.clear()
	for j in RINGS.size():
		var row: Array = []
		for i in SECTORS:
			var theta := TAU * i / SECTORS
			var f: float = RINGS[j]
			if j > 0 and j < GRASS_EDGE:
				var step: float = minf(RINGS[j + 1] - RINGS[j], RINGS[j] - RINGS[j - 1])
				theta += _hash(i, j, 1) * JITTER * TAU / SECTORS
				f += _hash(i, j, 2) * JITTER * step
			var r := f * coast_radius(theta)
			var x := r * cos(theta)
			var z := r * sin(theta)
			row.append(Vector3(x, _ground_height(x, z, f, j), z))
		_grid.append(row)


func _quad(j: int, i: int) -> Array:
	var i1 := (i + 1) % SECTORS
	return [_grid[j][i], _grid[j][i1], _grid[j + 1][i1], _grid[j + 1][i]]


static func _bary(p: Vector2, tri: Array) -> Vector3:
	var a := Vector2(tri[0].x, tri[0].z)
	var v0 := Vector2(tri[1].x, tri[1].z) - a
	var v1 := Vector2(tri[2].x, tri[2].z) - a
	var v2 := p - a
	var den := v0.x * v1.y - v1.x * v0.y
	if absf(den) < 1e-9:
		return Vector3(-1.0, -1.0, -1.0)
	var v := (v2.x * v1.y - v1.x * v2.y) / den
	var w := (v0.x * v2.y - v2.x * v0.y) / den
	return Vector3(1.0 - v - w, v, w)


## A fixed pseudo-random value in [-1, 1] for grid cell (i, j) (deterministic facets).
static func _hash(i: int, j: int, salt: int) -> float:
	var v := sin(float(i) * 12.9898 + float(j) * 78.233 + float(salt) * 37.719) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


## The map's environment: ArtKit's, with the open sea as the clear colour (SEA as an upward
## face of art_lit.gdshader shows it: lit plus the sky fill, so the shallow ring meets it cleanly).
const SHADER := preload("res://scripts/art/map_lit.gdshader")
static var _material: ShaderMaterial


## The map's one solid material (map_lit.gdshader: ArtKit.lit_material's light, encoded per vertex).
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter("sun_dir", ArtKit.SUN_DIR)
		_material.set_shader_parameter("lit_color", ArtPalette.LIGHT)
		_material.set_shader_parameter("shade_color", ArtPalette.SHADE)
		_material.set_shader_parameter("threshold", ArtKit.LIGHT_THRESHOLD)
		_material.set_shader_parameter("softness", ArtKit.LIGHT_SOFTNESS)
		_material.set_shader_parameter("sky_fill", ArtKit.SKY_FILL)
		# art_lit encodes where OUTPUT_IS_SRGB: the Compatibility renderer (Mobile converts itself).
		_material.set_shader_parameter("encode_srgb", RenderingServer.get_current_rendering_method() == "gl_compatibility")
	return _material


## The day look of the map's material: no spot lit (the night map lights the found ones).
static func light_no_spots() -> void:
	material().set_shader_parameter("lit_mask", 0)


static var _sky_material: ShaderMaterial


## The sky backdrop's material: map_lit with no light (white both sides, no fill), so its vertex
## colours are what shows: the clear colour's sea and the sky meet exactly.
static func sky_material() -> ShaderMaterial:
	if _sky_material == null:
		_sky_material = material().duplicate()
		_sky_material.set_shader_parameter("shade_color", Color.WHITE)
		_sky_material.set_shader_parameter("sky_fill", 0.0)
	return _sky_material


static func make_environment() -> WorldEnvironment:
	var world := ArtKit.make_environment()
	world.environment.background_color = sea_color()
	return world


static func sea_color() -> Color:
	var lin := ArtPalette.SEA.srgb_to_linear()
	var k := 1.0 + ArtKit.SKY_FILL
	return Color(lin.r * k, lin.g * k, lin.b * k).linear_to_srgb()


static func _v2(at: Array) -> Vector2:
	return Vector2(float(at[0]), float(at[1]))


# --- building ---------------------------------------------------------------------------------

## Builds the map under `world` as ONE mesh, "Island": landmarks, water and land in one builder, in
## the order they cover each other (what lies on the grass first, the grass and beach last), so
## the covered ground fails the depth test instead of being shaded and drawn over (SM-P200 fill).
## `spots` are [id, Vector2 at, yaw deg]; returns spot_info: id -> {at (stage top), top (landmark
## height above at), stand (where the cat waits), flag (where the flag stands), radius, vertices, tag}.
func build(world: Node3D, spots: Array) -> Dictionary:
	var land := ArtKit.builder()
	var water := land
	var marks := land
	for i in spots.size():
		_add_spot(marks, spots[i], i + 1)
	for zone in zones:
		var spec: Dictionary = zones[zone]
		match spec.ground:
			"yard":
				_add_yard(land, spec)
			"pond":
				_add_pond(land, water, spec)
	_add_features(land)
	_add_sea(water)
	_add_paths(land)
	_add_plaza(land)
	_add_decor(land)
	_add_clouds(land)
	# The grass and beach last: drawn after the yard, paths, square and trees that lie on them, the
	# covered grass fails the depth test before it is shaded (overdraw on SM-P200).
	_add_top(land)
	var mi := ArtKit.instance(land.commit(), material())
	mi.name = "Island"
	world.add_child(mi)
	var sky := ArtKit.builder()
	_add_sky(sky)
	var backdrop := ArtKit.instance(sky.commit(), sky_material())
	backdrop.name = "MapSky"
	world.add_child(backdrop)
	return spot_info


## The top: grass (the meadow lighter, a little shade jitter per face for the facets, slopes
## darker as they turn from the sun so a hill reads from above) and the sand beach ring sloping
## into the sea.
func _add_top(b: ArtMeshBuilder) -> void:
	var meadows: Array = []   # the zones with their own ground colour (GROUND_COLORS)
	for zone in zones:
		if zones[zone].ground in GROUND_COLORS:
			meadows.append([_v2(zones[zone].at), float(zones[zone].radius), zones[zone].ground])
	for j in RINGS.size() - 1:
		for i in SECTORS:
			var q := _quad(j, i)
			for k in 2:
				var tri: Array = [q[0], q[1], q[2]] if k == 0 else [q[0], q[2], q[3]]
				var color := _top_color(j, i, k, tri, meadows)
				b.add_triangle(tri, [color, color, color])


func _top_color(j: int, i: int, k: int, tri: Array, meadows: Array) -> Color:
	if j >= GRASS_EDGE:
		return ArtPalette.SAND
	var c: Vector3 = (tri[0] + tri[1] + tri[2]) / 3.0
	var color := ArtPalette.GRASS_TOP
	for m in meadows:
		if in_ground(Vector2(c.x, c.z), m[0], m[1], m[2]):
			color = GROUND_COLORS[m[2]]
	var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
	if n.y < 0.0:
		n = -n
	var sun := n.dot(ArtKit.SUN_DIR.normalized())   # the face's light, 0.83 when flat
	color = color.darkened(clampf((0.83 - sun) * 0.8, 0.0, 0.25)) if sun < 0.83 else color.lightened(clampf((sun - 0.83) * 1.5, 0.0, 0.2))
	return color.lightened(0.05 * (_hash(i, j, 3 + k) * 0.5 + 0.5))


## A zone ground's own colour on the map's top (LabWorld's ground too); the others are grass.
const GROUND_COLORS := {"meadow": ArtPalette.MEADOW, "coast": ArtPalette.SAND, "valley": ArtPalette.VALLEY}


## True when `p` is on the ground of a `ground` zone at `center`, `radius` m round: a circle, whose
## edge wavers on the coast (its sand runs out into the beach).
static func in_ground(p: Vector2, center: Vector2, radius: float, ground: String) -> bool:
	if ground == "coast":
		var t := (p - center).angle()
		var k := 1.0
		for w in COAST_WAVER:
			k += w[1] * sin(w[0] * t + w[2])
		radius *= k
	return p.distance_to(center) < radius


## The sea's geometry: only the light shallow ring (a wavy outer edge) hugging the coast, the white
## surf line along the shore and a few wave strokes. The open sea is the view's clear colour
## (make_environment): the map camera never looks above the horizon, so the background is always
## sea, and a sea plane filling the screen cost the home a third of its frame on SM-P200
## (2026-10-27: 13.5 -> 9.4 M GPU cycles a frame without it).
func _add_sea(b: ArtMeshBuilder) -> void:
	var inner := func(t: float) -> float: return (SHORE_F - 0.015) * coast_radius(t)   # just under the wet sand
	var shallow := func(t: float) -> float: return coast_radius(t) + SHALLOW + 0.45 * sin(4.0 * t + 0.6)
	# Surf along the shoreline and the wave strokes first: the shallows under them are then
	# rejected by depth instead of shaded twice.
	var surf_in := func(t: float) -> float: return SHORE_F * coast_radius(t) - 0.1
	var surf_out := func(t: float) -> float: return SHORE_F * coast_radius(t) + 0.3 + 0.08 * sin(9.0 * t)
	_ring_band(b, [surf_in, ArtPalette.FOAM], [surf_out, ArtPalette.FOAM], SEA_Y + 0.02)
	for w in island.sea_waves:
		_wave(b, deg_to_rad(w[0]), w[1], w[2])
	_ring_band(b, [inner, ArtPalette.SEA_SHALLOW], [shallow, ArtPalette.SEA_SHALLOW], SEA_Y)


## A band between two rings [radius fn, colour] at height y (one quad per sector).
func _ring_band(b: ArtMeshBuilder, a: Array, c: Array, y: float) -> void:
	var sectors := SECTORS * 2
	for i in sectors:
		var t0 := TAU * i / sectors
		var t1 := TAU * (i + 1) / sectors
		var p := [_polar(t0, a[0].call(t0), y), _polar(t1, a[0].call(t1), y), _polar(t1, c[0].call(t1), y), _polar(t0, c[0].call(t0), y)]
		b.add_triangle([p[0], p[1], p[2]], [a[1], a[1], c[1]])
		b.add_triangle([p[0], p[2], p[3]], [a[1], c[1], c[1]])


static func _polar(theta: float, r: float, y: float) -> Vector3:
	return Vector3(r * cos(theta), y, r * sin(theta))


## A wave stroke: a short white arc on the sea, thick in the middle.
func _wave(b: ArtMeshBuilder, theta: float, radius: float, length: float) -> void:
	var steps := 6
	var span := length / radius
	var white := [ArtPalette.FOAM, ArtPalette.FOAM, ArtPalette.FOAM]
	for k in steps:
		var u0 := float(k) / steps
		var u1 := float(k + 1) / steps
		var w0 := 0.16 * sin(PI * u0) + 0.02
		var w1 := 0.16 * sin(PI * u1) + 0.02
		var t0 := theta + span * (u0 - 0.5)
		var t1 := theta + span * (u1 - 0.5)
		var y := SEA_Y + 0.02
		var q := [_polar(t0, radius - w0, y), _polar(t1, radius - w1, y), _polar(t1, radius + w1, y), _polar(t0, radius + w0, y)]
		b.add_triangle([q[0], q[1], q[2]], white)
		b.add_triangle([q[0], q[2], q[3]], white)


## A flat polygon (a fan around `center`) lifted `lift` above the ground under each point.
func _add_flat(b: ArtMeshBuilder, center: Vector2, outline: Array, lift: float, color: Color) -> void:
	var c := Vector3(center.x, height_at(center.x, center.y) + lift, center.y)
	var colors := [color, color, color]
	for i in outline.size():
		var p0: Vector2 = outline[i]
		var p1: Vector2 = outline[(i + 1) % outline.size()]
		b.add_triangle([c, Vector3(p0.x, height_at(p0.x, p0.y) + lift, p0.y), Vector3(p1.x, height_at(p1.x, p1.y) + lift, p1.y)], colors)


## A ring between two outlines of the same point count.
func _add_flat_ring(b: ArtMeshBuilder, inner: Array, outer: Array, lift: float, color: Color) -> void:
	var colors := [color, color, color]
	for i in inner.size():
		var k := (i + 1) % inner.size()
		var p := [inner[i], inner[k], outer[k], outer[i]]
		var q: Array = []
		for v in p:
			q.append(Vector3(v.x, height_at(v.x, v.y) + lift, v.y))
		b.add_triangle([q[0], q[1], q[2]], colors)
		b.add_triangle([q[0], q[2], q[3]], colors)


## The play yard: a rounded sand rectangle with a low white picket fence, open towards the path.
func _add_yard(b: ArtMeshBuilder, spec: Dictionary) -> void:
	var center := _v2(spec.at)
	var outline := yard_outline(spec, 0.0)
	_add_flat(b, center, outline, OVERLAY_LIFT, ArtPalette.YARD_SAND)
	var ring := yard_outline(spec, 0.15)
	ring.append(ring[0])
	var fence := _resample(PackedVector2Array(ring), 0.9)   # a post about every 0.9 m
	var gate := center + Vector2(0.0, float(spec.size[1]) * 0.5)   # the side facing the square
	b.ao_min = 0.85
	b.ao_height = 0.3
	for k in fence.size() - 1:
		var p := fence[k]
		var next := fence[k + 1]
		if p.distance_to(gate) < 1.0:
			continue
		b.add_rounded_box(Transform3D(Basis(), Vector3(p.x, height_at(p.x, p.y) + 0.22, p.y)), Vector3(0.11, 0.44, 0.11), 0.0, 0, ArtPalette.WHITE)
		if next.distance_to(gate) >= 1.0 and p.distance_to(next) > 0.05:
			for h in [0.18, 0.34]:
				_rail(b, p, next, h)


func _rail(b: ArtMeshBuilder, from: Vector2, to: Vector2, h: float) -> void:
	var a := Vector3(from.x, height_at(from.x, from.y) + h, from.y)
	var c := Vector3(to.x, height_at(to.x, to.y) + h, to.y)
	var d := c - a
	var x := d.normalized()
	var basis := Basis(x, Vector3.UP, x.cross(Vector3.UP))
	b.add_rounded_box(Transform3D(basis, (a + c) * 0.5), Vector3(d.length() + 0.04, 0.06, 0.05), 0.0, 0, ArtPalette.WHITE)


## The yard's rounded rectangle, inset by `inset` m, as points (counter-clockwise in x/z).
static func yard_outline(spec: Dictionary, inset: float) -> Array:
	var center := _v2(spec.at)
	var half := Vector2(float(spec.size[0]), float(spec.size[1])) * 0.5 - Vector2.ONE * inset
	var corner := 1.0 - inset
	var inner := half - Vector2.ONE * corner
	var out: Array = []
	var corners := [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
	for ci in 4:
		for s in 7:
			var a := PI * 0.5 * ci + PI * 0.5 * s / 6.0
			out.append(center + corners[ci] * inner + Vector2(cos(a), sin(a)) * corner)
	return out


func _pond_radius(spec: Dictionary, theta: float) -> float:
	return float(spec.radius) * (1.0 + 0.07 * sin(3.0 * theta + 0.5) + 0.04 * sin(5.0 * theta))


## The pond: a sand shore ring, the water (in the water mesh), lily pads and stones on its edge.
func _add_pond(land: ArtMeshBuilder, water: ArtMeshBuilder, spec: Dictionary) -> void:
	var center := _v2(spec.at)
	var edge: Array = []
	var shore: Array = []
	var sides := 22
	for i in sides:
		var t := TAU * i / sides
		var r := _pond_radius(spec, t)
		edge.append(center + Vector2(cos(t), sin(t)) * (r - 0.05))
		shore.append(center + Vector2(cos(t), sin(t)) * (r + 0.45))
	_add_flat_ring(land, edge, shore, OVERLAY_LIFT, ArtPalette.SAND)
	var deep: Array = []
	for p in edge:
		deep.append(center + (p - center) * 0.55)
	_add_flat(water, center, deep, 0.06, ArtPalette.WATER)   # a ring round the deep middle: no layer on another
	_add_flat_ring(water, deep, edge, 0.06, ArtPalette.POND)
	land.ao_min = 1.0
	for pad in [[-0.9, 0.7, 0.32], [0.2, 1.1, 0.25], [0.95, -0.6, 0.28]]:
		var at := center + Vector2(pad[0], pad[1])
		land.add_cylinder(Transform3D(Basis(Vector3.UP, pad[0]), Vector3(at.x, 0.08, at.y)), pad[2], pad[2], 0.02, 7, ArtPalette.LEAF_LIGHT)
	land.ao_min = 0.75
	land.ao_height = 0.3
	for k in 6:
		var t := TAU * (k + 0.3) / 6.0 + 0.4
		var at: Vector2 = center + Vector2(cos(t), sin(t)) * (_pond_radius(spec, t) + 0.35)
		if _near_spot_line(at):
			continue
		var r := 0.16 + 0.06 * (k % 3)
		land.add_sphere(Transform3D(Basis().scaled(Vector3(1.3, 0.7, 1.0)), Vector3(at.x, OVERLAY_LIFT + r * 0.3, at.y)), r, 3, 6, ArtPalette.ROCK)


## True when (at) is by the dock: the line from a stageless spot (the buoyancy drum) to where
## the cat waits ashore.
func _near_spot_line(at: Vector2) -> bool:
	for id in spot_info:
		var info: Dictionary = spot_info[id]
		if info.radius == 0.0:
			var a := Vector2(info.at.x, info.at.z)
			var c := Vector2(info.stand.x, info.stand.z)
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, c)) < 0.8:
				return true
	return false


## The dirt paths: each polyline smoothed (Chaikin), sampled every 0.35 m and laid as a ribbon on
## the ground, with round ends.
func _add_paths(b: ArtMeshBuilder) -> void:
	path_points = PackedVector2Array()
	var colors := [ArtPalette.PATH, ArtPalette.PATH, ArtPalette.PATH]
	for line in paths:
		var samples := path_samples(line, PATH_STEP)
		for p in samples:
			path_points.append(p)
		var left: Array = []
		var right: Array = []
		for k in samples.size():
			var t: Vector2 = (samples[mini(k + 1, samples.size() - 1)] - samples[maxi(k - 1, 0)]).normalized()
			var n := Vector2(-t.y, t.x) * PATH_WIDTH * 0.5
			var l: Vector2 = samples[k] + n
			var r: Vector2 = samples[k] - n
			left.append(Vector3(l.x, height_at(l.x, l.y) + PATH_LIFT, l.y))
			right.append(Vector3(r.x, height_at(r.x, r.y) + PATH_LIFT, r.y))
		for k in samples.size() - 1:
			b.add_triangle([left[k], left[k + 1], right[k + 1]], colors)
			b.add_triangle([left[k], right[k + 1], right[k]], colors)
		for end in [samples[0], samples[samples.size() - 1]]:
			var disc: Array = []
			for s in 10:
				disc.append(end + Vector2(cos(TAU * s / 10.0), sin(TAU * s / 10.0)) * PATH_WIDTH * 0.5)
			_add_flat(b, end, disc, PATH_LIFT, ArtPalette.PATH)


## A path as it is drawn: smoothed and sampled every `step` m (the walk's way follows it).
static func path_samples(line: Array, step: float) -> PackedVector2Array:
	return _resample(_smooth(line), step)


## A polyline sampled every `step` m or less along it (its points kept).
static func resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	return _resample(points, step)


static func _smooth(line: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for p in line:
		points.append(_v2(p))
	for pass_i in 2:
		var out := PackedVector2Array()
		out.append(points[0])
		for k in points.size() - 1:
			out.append(points[k].lerp(points[k + 1], 0.25))
			out.append(points[k].lerp(points[k + 1], 0.75))
		out.append(points[points.size() - 1])
		points = out
	return points


static func _resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(points[0])
	for k in points.size() - 1:
		var a := points[k]
		var c := points[k + 1]
		var n := maxi(1, int(ceil(a.distance_to(c) / step)))
		for s in range(1, n + 1):
			out.append(a.lerp(c, float(s) / n))
	return out


## The cat's home square where the paths meet, with a signpost.
func _add_plaza(b: ArtMeshBuilder) -> void:
	var inner: Array = []
	var outer: Array = []
	for s in 16:
		var d := Vector2(cos(TAU * s / 16.0), sin(TAU * s / 16.0))
		inner.append(home + d * PLAZA_RADIUS)
		outer.append(home + d * (PLAZA_RADIUS + 0.18))
	_add_flat(b, home, inner, PLAZA_LIFT, ArtPalette.PLAZA)
	_add_flat_ring(b, inner, outer, PLAZA_LIFT, ArtPalette.ROCK)
	var post := home + Vector2(-1.05, -0.75)
	var y := height_at(post.x, post.y) + PLAZA_LIFT
	b.ao_min = 0.8
	b.ao_height = 0.4
	b.add_cylinder(Transform3D(Basis(), Vector3(post.x, y, post.y)), 0.06, 0.06, 1.2, 6, ArtPalette.TRUNK)
	for board in [[0.95, 25.0, ArtPalette.CRATE_TOP], [0.7, -30.0, ArtPalette.CRATE], [0.45, 70.0, ArtPalette.CRATE_TOP]]:
		var basis := Basis(Vector3.UP, deg_to_rad(board[1]))
		b.add_rounded_box(Transform3D(basis, Vector3(post.x, y + board[0], post.y) + basis * Vector3(0.22, 0.0, 0.0)),
			Vector3(0.5, 0.16, 0.05), 0.0, 0, board[2])


## A spot: its round stage (levelled over the ground under it) and its landmark on top. Their
## vertices carry the spot's `tag` (UV.x, 1..11 in build order): map_lit lights a found spot at night
## and shakes a locked one that was tapped (lit_mask, shake_spot), all in the one merged mesh.
func _add_spot(b: ArtMeshBuilder, spot: Array, tag := 0) -> void:
	var id: String = spot[0]
	var at: Vector2 = spot[1]
	var yaw := deg_to_rad(float(spot[2]))
	var radius := MapLandmarks.stage_radius(id)
	var low := height_at(at.x, at.y)
	var high := low
	for s in 8:
		var p := at + Vector2(cos(TAU * s / 8.0), sin(TAU * s / 8.0)) * maxf(radius, 0.4)
		var h := height_at(p.x, p.y)
		low = minf(low, h)
		high = maxf(high, h)
	var y := height_at(at.x, at.y) + (OVERLAY_LIFT if radius > 0.0 else 0.06)   # stageless: the pond's water
	var before := b.vertex_count()
	if radius > 0.0:
		y = high + 0.06
		b.ao_min = 0.8
		b.ao_height = 0.25
		b.add_cylinder(Transform3D(Basis(), Vector3(at.x, low - 0.15, at.y)), radius + 0.06, radius, y - low + 0.15, 14, ArtPalette.ROCK, true, ArtPalette.PLATE)
	var top := MapLandmarks.add(b, id, Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, y, at.y)))
	if tag > 0:
		b.tag_from(before, tag)
	var to_home := (home - at).normalized() if home.distance_to(at) > 0.01 else Vector2(0.0, 1.0)
	var stand := at + to_home * (radius + 0.4 if radius > 0.0 else 2.0)   # stageless: ashore, past the dock
	var side := Vector2(-to_home.y, to_home.x)
	var flag := at + (side * 0.75 - to_home * 0.35).normalized() * maxf(radius - 0.1, 0.5)
	spot_info[id] = {
		"at": Vector3(at.x, y, at.y),
		"top": top,
		"radius": radius,
		"stand": Vector3(stand.x, walk_height(stand.x, stand.y), stand.y),
		"flag": Vector3(flag.x, y, flag.y),
		"vertices": b.vertex_count() - before,
		"tag": tag,
	}


## Trees, rocks and flowers: each placed only where nothing else is (clear()); the flowers seeded
## in the meadow and over the rest of the grass.
func _add_decor(b: ArtMeshBuilder) -> void:
	decorations.clear()
	for t in island.trees:
		var x: float = t[0]
		var z: float = t[1]
		var k: float = t[2]
		if not clear(x, z, 1.0 * k):
			continue
		var y := height_at(x, z)
		b.ao_min = 0.8
		b.ao_height = 0.4 * k
		b.add_cylinder(_at(x, y, z), 0.2 * k, 0.16 * k, 0.8 * k, 6, ArtPalette.TRUNK)
		b.ao_min = 0.85
		b.add_cylinder(_at(x, y + 0.7 * k, z, 15.0), 1.1 * k, 0.0, 1.5 * k, 7, ArtPalette.LEAF)
		b.add_cylinder(_at(x, y + 1.5 * k, z, 40.0), 0.8 * k, 0.0, 1.2 * k, 7, ArtPalette.LEAF_LIGHT)
		_ground_blob(b, Vector3(x, y, z), 1.3 * k)
		decorations.append(["tree", x, z, 1.0 * k])
	b.ao_min = 0.75
	b.ao_height = 0.3
	for r in island.rocks:
		var x: float = r[0]
		var z: float = r[1]
		var radius: float = r[2]
		if not clear(x, z, radius * 1.3):
			continue
		var y := height_at(x, z)
		b.add_sphere(Transform3D(Basis().scaled(Vector3(1.3, 0.75, 1.0)), Vector3(x, y + radius * 0.5, z)), radius, 4, 6, ArtPalette.ROCK)
		_ground_blob(b, Vector3(x, y, z), radius * 1.8)
		decorations.append(["rock", x, z, radius * 1.3])
	var rng := RandomNumberGenerator.new()
	rng.seed = FLOWER_SEED
	var placed := 0
	b.ao_min = 1.0
	for zone in zones:
		var spec: Dictionary = zones[zone]
		if spec.ground != "meadow":
			continue
		var meadow_tries := 0
		while placed < MEADOW_FLOWERS and meadow_tries < 400:
			meadow_tries += 1
			var p := _v2(spec.at) + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(spec.radius)
			if clear(p.x, p.y, 0.2):
				_flower(b, p, placed)
				placed += 1
	var tries := 0
	while placed < MEADOW_FLOWERS + OTHER_FLOWERS and tries < 600:
		tries += 1
		var p := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 11.0
		if coast_fraction(p.x, p.y) < 0.78 and clear(p.x, p.y, 0.2):
			_flower(b, p, placed)
			placed += 1


## A blob shadow on the grass without blending: ArtKit's blob (full SHADOW_ALPHA inside 35 % of the
## radius, fading out) as an opaque gradient from the shadowed grass to the grass colour itself.
## The ground under a tree or rock is known grass, so it looks the same, and the map has no
## alpha-blended layer over the island (fill on SM-P200, 2026-10-27).
func _ground_blob(b: ArtMeshBuilder, at: Vector3, radius: float) -> void:
	var ground := ArtPalette.GRASS_TOP.lightened(0.025)
	for zone in zones:
		var spec: Dictionary = zones[zone]
		if spec.ground in GROUND_COLORS and in_ground(Vector2(at.x, at.z), _v2(spec.at), float(spec.radius), spec.ground):
			ground = (GROUND_COLORS[spec.ground] as Color).lightened(0.025)
	var dark := ground.lerp(ArtPalette.SHADOW, ArtKit.shadow_alpha())
	var c := at + Vector3(0.0, 0.012, 0.0)
	var sides := 12
	for i in sides:
		var d0 := Vector3(cos(TAU * i / sides), 0.0, sin(TAU * i / sides))
		var d1 := Vector3(cos(TAU * (i + 1) / sides), 0.0, sin(TAU * (i + 1) / sides))
		var i0 := c + d0 * radius * 0.35
		var i1 := c + d1 * radius * 0.35
		var o0 := c + d0 * radius
		var o1 := c + d1 * radius
		o0.y = height_at(o0.x, o0.z) + 0.012
		o1.y = height_at(o1.x, o1.z) + 0.012
		b.add_triangle([c, i0, i1], [dark, dark, dark])
		b.add_triangle([i0, o0, o1], [dark, ground, ground])
		b.add_triangle([i0, o1, i1], [dark, ground, dark])


func _flower(b: ArtMeshBuilder, p: Vector2, i: int) -> void:
	var y := height_at(p.x, p.y)
	# Seen from 27 m a flower is a dot: a 3-sided stem and a diamond head (a tenth of the lab's).
	b.add_cylinder(_at(p.x, y, p.y), 0.035, 0.035, 0.3, 3, ArtPalette.STEM, false)
	b.add_sphere(_at(p.x, y + 0.34, p.y), 0.14, 2, 4, ArtPalette.FLOWERS[i % ArtPalette.FLOWERS.size()])
	decorations.append(["flower", p.x, p.y, 0.2])


## True when a thing of footprint `radius` at (x, z) stands on open grass: inside the grass edge,
## off the paths, the square, the yard, the pond and its shore, clear of every spot's stage and of
## the decorations already placed.
func clear(x: float, z: float, radius: float) -> bool:
	var p := Vector2(x, z)
	if p.length() + radius * 0.6 > grass_edge() * coast_radius(atan2(z, x)):   # crowns may lean over the sand
		return false
	if p.distance_to(home) < PLAZA_RADIUS + 0.3 + radius:
		return false
	for q in path_points:
		if p.distance_to(q) < PATH_WIDTH * 0.5 + 0.15 + radius:
			return false
	for id in spot_info:
		var info: Dictionary = spot_info[id]
		var at := Vector2(info.at.x, info.at.z)
		if p.distance_to(at) < maxf(info.radius, 1.0) + 0.5 + radius:
			return false
	for zone in zones:
		var spec: Dictionary = zones[zone]
		var c := _v2(spec.at)
		match spec.ground:
			"pond":
				if p.distance_to(c) < float(spec.radius) * 1.15 + 0.6 + radius:
					return false
			"yard":
				var half := Vector2(float(spec.size[0]), float(spec.size[1])) * 0.5 + Vector2.ONE * (0.3 + radius)
				if absf(x - c.x) < half.x and absf(z - c.y) < half.y:
					return false
			"coast":   # the sand: no grass things
				if in_ground(p, c, float(spec.radius) + 0.3 + radius, "coast"):
					return false
	if not features_clear(p, radius):
		return false
	for d in decorations:
		if p.distance_to(Vector2(d[1], d[2])) < d[3] + radius:
			return false
	return true


## True when nothing of the island's features (#72) is within `radius` of `p`: the volcano's
## foot, the river and its banks, the lighthouse (the sundial is on the square, kept clear anyway).
func features_clear(p: Vector2, radius: float) -> bool:
	var f := island.features
	if f.has("volcano") and p.distance_to(_v2(f.volcano.at)) < float(f.volcano.radius) + 0.4 + radius:
		return false
	if not river_points.is_empty() and river_distance(p.x, p.y) < 0.4 + radius:
		return false
	if f.has("lighthouse") and p.distance_to(_v2(f.lighthouse)) < LIGHTHOUSE_CLEAR + radius:
		return false
	return true


# --- the hutton island's features (#72) -------------------------------------------------------

## The volcano, the lighthouse, the sundial and the river, when the island has them (the mechanics
## island has none: its mesh is what it was).
func _add_features(b: ArtMeshBuilder) -> void:
	_add_volcano(b)
	_add_marks(b)
	if not river_points.is_empty():
		_add_river(b)


## The volcano on the ground at its middle, its foot sunk under the lowest ground round it.
func _add_volcano(b: ArtMeshBuilder) -> void:
	if not island.features.has("volcano"):
		return
	var v: Dictionary = island.features.volcano
	var at := _v2(v.at)
	var radius := float(v.radius)
	var y := height_at(at.x, at.y)
	var low := y
	for i in 16:
		var p := at + Vector2.from_angle(TAU * i / 16.0) * radius
		low = minf(low, height_at(p.x, p.y))
	MapLandmarks.volcano(b, Transform3D(Basis(), Vector3(at.x, y, at.y)), radius, float(v.height), y - low + VOLCANO_SINK)


## The lighthouse on the beach and the sundial on the square.
func _add_marks(b: ArtMeshBuilder) -> void:
	if island.features.has("lighthouse"):
		var at := _v2(island.features.lighthouse)
		MapLandmarks.lighthouse(b, Transform3D(Basis(), Vector3(at.x, height_at(at.x, at.y), at.y)))
	if island.has_sundial():
		var info := home_lookout()
		MapLandmarks.sundial(b, Transform3D(Basis(), info.at - Vector3.UP * float(info.top)))


## The river: a ribbon on the ground from its source to under the sea, widening towards the mouth,
## with a round source.
func _add_river(b: ArtMeshBuilder) -> void:
	add_ribbon(b, ribbon_rows(river_points, river_widths, func(q: Vector2) -> float: return height_at(q.x, q.y) + RIVER_LIFT))
	var source := river_points[0]
	var disc: Array = []
	for s in 10:
		disc.append(source + Vector2.from_angle(TAU * s / 10.0) * river_widths[0] * 0.5)
	_add_flat(b, source, disc, RIVER_LIFT, ArtPalette.RIVER)


## A river's cross-sections [left edge, middle, right edge] (Vector3) at `points` (x, z), `widths`
## wide, at `height`(x, z) (MapIsland and LabWorld share them).
static func ribbon_rows(points: PackedVector2Array, widths: PackedFloat32Array, height: Callable) -> Array:
	var n := points.size()
	var rows: Array = []
	for k in n:
		var p := points[k]
		var t: Vector2 = (points[mini(k + 1, n - 1)] - points[maxi(k - 1, 0)]).normalized()
		var side := Vector2(-t.y, t.x) * widths[k] * 0.5
		var row: Array = []
		for q: Vector2 in [p + side, p, p - side]:
			row.append(Vector3(q.x, height.call(q), q.y))
		rows.append(row)
	return rows


## The river ribbon between consecutive `rows` (ribbon_rows): light at its edges (RIVER_EDGE), the
## water's colour in the middle (RIVER).
static func add_ribbon(b: ArtMeshBuilder, rows: Array) -> void:
	var edge := ArtPalette.RIVER_EDGE
	var mid := ArtPalette.RIVER
	for k in rows.size() - 1:
		var a: Array = rows[k]
		var c: Array = rows[k + 1]
		b.add_triangle([a[0], c[0], c[1]], [edge, edge, mid])
		b.add_triangle([a[0], c[1], a[1]], [edge, mid, mid])
		b.add_triangle([a[1], c[1], c[2]], [mid, mid, edge])
		b.add_triangle([a[1], c[2], a[2]], [mid, edge, edge])


## Where the story's pieces gather when the island's lookout is the square (Island.HOME), like a
## spot's {at, top, stand}: the sundial's top (the square's middle without one), its height over the
## square, and where the cat stands (the square's middle).
func home_lookout() -> Dictionary:
	var dial := island.has_sundial()
	var at := home + SUNDIAL_AT if dial else home
	var top := MapLandmarks.SUNDIAL_HEIGHT if dial else 0.0
	return {"at": Vector3(at.x, height_at(at.x, at.y) + PLAZA_LIFT + top, at.y), "top": top,
		"stand": Vector3(home.x, walk_height(home.x, home.y), home.y)}


## The sky for low views: the backdrop cylinder (haze at its foot, the horizon, fading into SKY)
## and a haze band on the far sea from the clear colour to the horizon tint. Nothing of it is in
## the default view (it starts about 4 degrees below level), so it costs only the low views.
func _add_sky(b: ArtMeshBuilder) -> void:
	var sea := sea_color()
	var haze := ArtPalette.SKY.lerp(Color.WHITE, 0.45)
	var bands := [[SEA_Y - 3.0, haze], [12.0, haze], [45.0, ArtPalette.SKY], [700.0, ArtPalette.SKY]]
	var sides := 48
	for i in sides:
		var d0 := Vector3(cos(TAU * i / sides), 0.0, sin(TAU * i / sides))
		var d1 := Vector3(cos(TAU * (i + 1) / sides), 0.0, sin(TAU * (i + 1) / sides))
		var inward := -(d0 + d1).normalized()
		for k in bands.size() - 1:
			var y0: float = bands[k][0]
			var y1: float = bands[k + 1][0]
			var c0: Color = bands[k][1]
			var c1: Color = bands[k + 1][1]
			var p := [d0 * SKY_RADIUS + Vector3.UP * y0, d1 * SKY_RADIUS + Vector3.UP * y0, d1 * SKY_RADIUS + Vector3.UP * y1, d0 * SKY_RADIUS + Vector3.UP * y1]
			b.add_triangle([p[0], p[1], p[2]], [c0, c0, c1], inward)
			b.add_triangle([p[0], p[2], p[3]], [c0, c1, c1], inward)
		var near := 150.0
		var q := [d0 * near, d1 * near, d1 * SKY_RADIUS, d0 * SKY_RADIUS]
		for v in q.size():
			q[v].y = SEA_Y
		var far := sea.lerp(haze, 0.6)
		b.add_triangle([q[0], q[1], q[2]], [sea, sea, far])
		b.add_triangle([q[0], q[2], q[3]], [sea, far, far])


## A cloud's round puffs [x, y, radius] in its size units (2026-10-31 user: "구름 좀 더 둥글둥글"): four
## overlapping balls, a big one in the middle, smaller ones beside and on top; each ball smooth enough
## (CLOUD_RINGS x CLOUD_SIDES, was 3 x 6) that its outline reads round, within the labs' vertex budget.
const CLOUD_PUFFS := [[0.0, 0.0, 1.0], [1.05, -0.18, 0.78], [-1.05, -0.22, 0.75], [0.35, 0.5, 0.72]]
const CLOUD_RINGS := 5
const CLOUD_SIDES := 12
## The labs' clouds are coarser (their world mesh has a 30,000 vertex budget, lab_world_checks).
const LAB_CLOUD_RINGS := 4
const LAB_CLOUD_SIDES := 8
## The sky clouds' shading (smooth, b.flat = false): their base darkened to CLOUD_AO, fading out over
## CLOUD_AO_HEIGHT of a puff's unit (0.6 m at the lab sky's size 4.5).
const CLOUD_AO := 0.85
const CLOUD_AO_HEIGHT := 0.13
## A spot's near cloud (cloud_mesh): finer balls than the sky's far ones and a softer light ramp, so
## the light rolls round it instead of showing its triangles close up.
const NEAR_CLOUD_RINGS := 8
const NEAR_CLOUD_SIDES := 16
const NEAR_CLOUD_SOFTNESS := 0.16

static var _cloud_material: ShaderMaterial


## One cloud of round puffs (CLOUD_PUFFS) into `b`: its middle at `at`, the puffs spread along `side`
## (unit, across the view), `size` times the puffs' units (about 3.7 * size wide), squashed to 0.8 tall.
## The one cloud shape of the map's far clouds, the lab's sky (LabWorld) and the spots' clouds
## (cloud_mesh, 2026-11-07 user: the spots' clouds look like the sky's). The builder's flat and AO
## settings stay the caller's.
static func add_cloud(b: ArtMeshBuilder, at: Vector3, side: Vector3, size: float, color: Color, rings := LAB_CLOUD_RINGS, sides := LAB_CLOUD_SIDES) -> void:
	for puff in CLOUD_PUFFS:
		b.add_sphere(Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0)), at + side * puff[0] * size + Vector3.UP * puff[1] * size),
			puff[2] * size, rings, sides, color)


## A spot's cloud (a mesh round the origin, spread along x, about 3.7 * size wide) in the sky clouds'
## look: add_cloud, smooth shading, their base shade, the finer balls of a near cloud. Draw it with
## cloud_material() (or a copy of it with a `tint`).
static func cloud_mesh(size: float, color := ArtPalette.CLOUD) -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = CLOUD_AO
	b.ao_height = CLOUD_AO_HEIGHT * size
	add_cloud(b, Vector3.ZERO, Vector3.RIGHT, size, color, NEAR_CLOUD_RINGS, NEAR_CLOUD_SIDES)
	return b.commit()


## The spots' clouds' material: the props' light (ArtKit.lit_material, the sky clouds' sun and colours)
## with a softer ramp (NEAR_CLOUD_SOFTNESS). Shared; duplicate it to tint one cloud.
static func cloud_material() -> ShaderMaterial:
	if _cloud_material == null:
		_cloud_material = ArtKit.lit_material().duplicate()
		_cloud_material.set_shader_parameter("softness", NEAR_CLOUD_SOFTNESS)
	return _cloud_material


## A few clouds far around the island (the low views see them; the top view does not).
func _add_clouds(b: ArtMeshBuilder) -> void:
	b.ao_min = CLOUD_AO
	b.ao_height = 0.6
	var was_flat := b.flat
	b.flat = false   # smooth shading: soft round puffs, not facets (2026-10-31 user)
	for c in island.clouds:
		var k: float = c[3]
		for puff in CLOUD_PUFFS:
			b.add_sphere(_at(c[0] + puff[0] * k, c[1] + puff[1] * k, c[2]), puff[2] * k, CLOUD_RINGS, CLOUD_SIDES, ArtPalette.CLOUD)
	for c in island.far_clouds:
		var at := Vector3(cos(deg_to_rad(c[0])), 0.0, sin(deg_to_rad(c[0]))) * float(c[1]) + Vector3.UP * float(c[2])
		var side := Vector3(-sin(deg_to_rad(c[0])), 0.0, cos(deg_to_rad(c[0])))   # spread across the view
		add_cloud(b, at, side, c[3], ArtPalette.CLOUD, CLOUD_RINGS, CLOUD_SIDES)
	b.flat = was_flat


static func _at(x: float, y: float, z: float, yaw_deg := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(x, y, z))
