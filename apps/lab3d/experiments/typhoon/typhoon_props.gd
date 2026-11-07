## The 태풍·비구름 lab's props (#94; apps/lab3d/docs/art-direction.md): meshes only, posed from the model
## by TyphoonLab._redraw(). A round sea basin on Hutton Island's coast, seen from above at a slant:
## - the sea: the open sea in the condition's colour (cold grey-blue, warm teal, very warm bright
##   teal with sun glints), the far strip always cold (pale, with ice floes), a light shallow ring round
##   the island; over a warm sea water vapour rises in little white wisps (more over a very warm one,
##   none over a cold one): what feeds the cloud, shown without a word or a number,
## - the island on the right: a sandy beach, a grassy top, the fox's house and a palm; the bread cat,
## - the child's cloud (Cloud): white puffs while small; a bigger grey rain cloud with rain under it;
##   a typhoon, a flat spiral of cloud arms turning round a clear eye, with rough foam on the sea under
##   it. Its strength (0..1) picks the look smoothly; it never shows as a number,
## - the typhoon's way to the island (the last stage, before it is moved): an orange dashed arrow on
##   the sea from the typhoon to the island's beach.
## Visual only: no body, nothing the model or the mission reads.
class_name TyphoonProps
extends RefCounted

## The sea's surface (world y) and the basin round it.
const SEA_Y := 0.5
const STAGE_CENTER := Vector3(TyphoonModel.BASIN_CENTER.x, 0.0, TyphoonModel.BASIN_CENTER.y)
const STAGE_RADIUS := TyphoonModel.BASIN_RADIUS
const RIM := 0.35
## The cloud floats this high over the sea.
const CLOUD_HEIGHT := 2.6
## The lab corner of the island, behind the basin (its trees stand clear of it).
const WORLD_CENTER := Vector3(0.0, 0.0, -11.5)
const RINGS := 14
const SIDES := 48
const COLD_SEA := Color("8cc4e8")
const COLD_SEA_TOP := Color("b5dcf2")
const WARM_SEA := Color("1fb0c8")
const HOT_SEA := Color("19c6ae")
const SHALLOW := Color("8de6e0")
const ICE := Color("f4fbff")
const ICE_SIDE := Color("cfe8f7")
const GLINT := Color("fff3b0")
const FOAM := ArtPalette.FOAM
## The island (TyphoonModel's ellipse) and what stands on it.
const ISLAND_TOP := SEA_Y + 0.28
const HOUSE_AT := Vector3(5.4, ISLAND_TOP, 0.0)
const HOUSE_SIZE := 3.4
const PALM_AT := Vector3(6.2, ISLAND_TOP, 1.3)
const CAT_AT := Vector3(5.0, ISLAND_TOP, 1.5)
## Water vapour: wisps rising over the open sea (WISP_RISE m in WISP_S), how many show per condition.
const WISPS := 16
const WISP_RISE := 1.5
const WISP_S := 2.4
const WISPS_WARM := 7
## The way to the island (last stage): from the typhoon's edge to the beach.
const WAY_FROM := Vector3(-2.3, SEA_Y + 0.05, 1.2)
const WAY_TO := Vector3(2.0, SEA_Y + 0.05, 0.9)
const WAY_COLOR := Color("ff7a1a")

var cat: CatActor
var cloud: Cloud
var sea: MeshInstance3D
var way: Node3D
var _wisps: Array[Node3D] = []
var _glints: MeshInstance3D
var _sea_key := -1.0
var _t := 0.0
## What shows now (tests): the open sea's condition, the wisps rising.
var shown_sea := -1.0
var shown_wisps := 0


## The cloud's world point for the model's (x, z).
static func cloud_point(x: float, z: float) -> Vector3:
	return Vector3(x, SEA_Y + CLOUD_HEIGHT, z)


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	var basin := ArtKit.instance(_basin_mesh())
	basin.name = "Basin"
	lab.add_child(basin)
	sea = MeshInstance3D.new()
	sea.name = "Sea"
	sea.material_override = ArtKit.lit_material()
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lab.add_child(sea)
	_glints = MeshInstance3D.new()
	_glints.name = "Glints"
	_glints.material_override = ArtKit.lit_material()
	lab.add_child(_glints)
	var island := ArtKit.instance(_island_mesh())
	island.name = "Island"
	lab.add_child(island)
	var house := ArtKit.instance(DayNightProps.house_mesh())
	house.name = "House"
	house.transform = Transform3D(Basis(Vector3.UP, -0.5).scaled(Vector3.ONE * HOUSE_SIZE), HOUSE_AT)
	lab.add_child(house)
	var wisp := _wisp_mesh()
	for i in WISPS:
		var w := ArtKit.instance(wisp)
		w.name = "Wisp%d" % i
		w.position = _wisp_at(i)
		w.visible = false
		lab.add_child(w)
		_wisps.append(w)
	way = ArtKit.instance(_way_mesh())
	way.name = "Way"
	way.visible = false
	lab.add_child(way)
	cloud = Cloud.new()
	cloud.name = "Cloud"
	lab.add_child(cloud)
	cloud.build()
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = cloud
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses the cloud (x, z, strength 0..1) and the sea of condition `sea_condition` (TyphoonModel).
func show(x: float, z: float, size: float, sea_condition: float) -> void:
	cloud.position = cloud_point(x, z)
	cloud.set_size(size)
	if sea_condition != _sea_key:
		_sea_key = sea_condition
		shown_sea = sea_condition
		sea.mesh = _sea_mesh(sea_condition)
		_glints.mesh = _glint_mesh(sea_condition)
		shown_wisps = 0 if sea_condition < TyphoonModel.WARM - 0.5 else WISPS_WARM if sea_condition < TyphoonModel.HOT - 0.5 else WISPS
		for i in WISPS:
			_wisps[i].visible = i < shown_wisps


## The moving bits (visual only): the wisps rise and fade, the cloud turns and rains.
func animate(delta: float) -> void:
	_t += delta
	for i in shown_wisps:
		var k := fposmod(_t / WISP_S + float(i) * 0.37, 1.0)
		var w := _wisps[i]
		w.position = _wisp_at(i) + Vector3.UP * WISP_RISE * k
		w.scale = Vector3.ONE * maxf(0.001, sin(PI * k))
	cloud.animate(delta)


## Wisp `i`'s foot on the open sea: a golden-angle scatter over the sea, kept off the cold strip and
## the island (and the far rim).
static func _wisp_at(i: int) -> Vector3:
	var a := i * 2.399963 + 0.6
	var r := 6.2 * sqrt((i + 0.6) / WISPS)
	var p := Vector2(-0.8 + cos(a) * r, 0.2 + sin(a) * r * 0.42)
	if TyphoonModel.place_at(p.x, p.y) == "land":
		p.x -= 3.6
	return Vector3(p.x, SEA_Y + 0.05, p.y)


# --- the sea and the island -----------------------------------------------------------------------

## The basin: a sandy round rim and its floor (the water is the sea mesh on top).
func _basin_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.3
	b.add_cylinder(Transform3D(Basis(), STAGE_CENTER), STAGE_RADIUS + RIM, STAGE_RADIUS + RIM, SEA_Y - 0.03, 48, ArtPalette.SAND.darkened(0.08), true, ArtPalette.SAND)
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), STAGE_CENTER + Vector3(0.0, SEA_Y - 0.12, 0.0)), STAGE_RADIUS + RIM, STAGE_RADIUS + RIM * 0.85, 0.26, 48, ArtPalette.SAND, false)
	# Ice floes on the cold strip (flat white plates, a golden-angle scatter on the far side).
	for i in 9:
		var a := i * 2.399963
		var p := Vector3(-6.0 + fposmod(i * 3.7, 12.0), SEA_Y, TyphoonModel.COLD_Z - 1.0 - fposmod(i * 1.9, 4.2))
		if Vector2(p.x - STAGE_CENTER.x, p.z - STAGE_CENTER.z).length() > STAGE_RADIUS - 0.8:
			continue
		var r := 0.35 + 0.15 * float(i % 3)
		b.add_cylinder(Transform3D(Basis(Vector3.UP, a), p), r, r * 0.9, 0.1, 6, ICE_SIDE, true, ICE)
	return b.commit()


## The sea's colour at world (x, z) for the condition: the cold strip's, the open sea's, the shallow
## ring round the island.
static func sea_color(x: float, z: float, sea_condition: float) -> Color:
	var open := COLD_SEA if sea_condition < TyphoonModel.WARM - 0.5 else WARM_SEA if sea_condition < TyphoonModel.HOT - 0.5 else HOT_SEA
	var cold := clampf((TyphoonModel.COLD_Z + 0.25 - z) / 0.5, 0.0, 1.0)
	var color := open.lerp(COLD_SEA, cold)
	var d := ((Vector2(x, z) - TyphoonModel.ISLAND_CENTER) / TyphoonModel.ISLAND_RADII).length()
	return color.lerp(SHALLOW, clampf((1.45 - d) / 0.45, 0.0, 1.0) * (1.0 - cold))


## The water: a round grid over the basin coloured by sea_color, gently rippled in tone.
func _sea_mesh(sea_condition: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var points := []
	for ring in RINGS + 1:
		var row := []
		var r := STAGE_RADIUS * float(ring) / RINGS
		for side in SIDES:
			var a := TAU * side / SIDES
			row.append(STAGE_CENTER + Vector3(cos(a) * r, SEA_Y, sin(a) * r))
		points.append(row)
	var color := func(p: Vector3) -> Color:
		var ripple := 0.04 * sin(p.x * 1.7 + p.z * 0.9) + 0.03 * cos(p.z * 2.3 - p.x * 0.6)
		return sea_color(p.x, p.z, sea_condition).lightened(maxf(0.0, ripple)).darkened(maxf(0.0, -ripple))
	for ring in RINGS:
		for side in SIDES:
			var n := (side + 1) % SIDES
			var p00: Vector3 = points[ring][side]
			var p01: Vector3 = points[ring][n]
			var p10: Vector3 = points[ring + 1][side]
			var p11: Vector3 = points[ring + 1][n]
			if ring == 0:
				b.add_triangle([p00, p11, p10], [color.call(p00), color.call(p11), color.call(p10)])
				continue
			b.add_triangle([p00, p11, p10], [color.call(p00), color.call(p11), color.call(p10)])
			b.add_triangle([p00, p01, p11], [color.call(p00), color.call(p01), color.call(p11)])
	return b.commit()


## Sun glints on a warm sea: little light diamonds (a few on a warm sea, many on a very warm one).
func _glint_mesh(sea_condition: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var count := 0 if sea_condition < TyphoonModel.WARM - 0.5 else 10 if sea_condition < TyphoonModel.HOT - 0.5 else 26
	for i in count:
		var a := i * 2.399963 + 1.1
		var r := 7.4 * sqrt((i + 0.5) / 26.0)
		var p := Vector3(-0.6 + cos(a) * r, SEA_Y + 0.015, 0.0 + sin(a) * r * 0.45)
		if TyphoonModel.place_at(p.x, p.z) != "sea" or Vector2(p.x - STAGE_CENTER.x, p.z - STAGE_CENTER.z).length() > STAGE_RADIUS - 0.4:
			continue
		var s := 0.16 + 0.06 * float(i % 3)
		b.add_triangle([p + Vector3(-s, 0.0, 0.0), p + Vector3(0.0, 0.0, s * 0.45), p + Vector3(s, 0.0, 0.0)], [GLINT, GLINT, GLINT])
		b.add_triangle([p + Vector3(-s, 0.0, 0.0), p + Vector3(s, 0.0, 0.0), p + Vector3(0.0, 0.0, -s * 0.45)], [GLINT, GLINT, GLINT])
	return b.commit()


## The island (TyphoonModel's ellipse): a sandy beach, a grassy top and a palm (the house: build()).
func _island_mesh() -> Mesh:
	var b := ArtKit.builder()
	var c := Vector3(TyphoonModel.ISLAND_CENTER.x, 0.0, TyphoonModel.ISLAND_CENTER.y)
	var radii := TyphoonModel.ISLAND_RADII
	b.ao_min = 0.85
	b.ao_height = 0.3
	var beach := Transform3D(Basis.from_scale(Vector3(radii.x, 1.0, radii.y)), c + Vector3(0.0, SEA_Y - 0.05, 0.0))
	b.add_cylinder(beach, 1.0, 0.94, ISLAND_TOP - SEA_Y + 0.05, 28, ArtPalette.SAND.darkened(0.06), true, ArtPalette.SAND)
	var grass := Transform3D(Basis.from_scale(Vector3(radii.x * 0.62, 1.0, radii.y * 0.6)), c + Vector3(0.55, ISLAND_TOP - 0.02, -0.25))
	b.add_cylinder(grass, 1.0, 0.95, 0.12, 24, ArtPalette.GRASS, true, ArtPalette.GRASS_TOP)
	# The palm: a leaning trunk and a crown of drooping leaves.
	b.ao_min = 0.9
	var lean := Basis(Vector3.BACK, 0.18)
	b.add_cylinder(Transform3D(lean, PALM_AT), 0.11, 0.07, 1.6, 6, ArtPalette.TRUNK)
	var top := PALM_AT + lean * Vector3(0.0, 1.6, 0.0)
	for i in 6:
		var a := TAU * i / 6.0
		var out := Vector3(cos(a), 0.0, sin(a))
		var leaf := Basis(out.cross(Vector3.UP).normalized(), -0.45) * Basis.from_scale(Vector3(0.75, 0.12, 0.75))
		b.add_sphere(Transform3D(leaf, top + out * 0.42 + Vector3.DOWN * 0.08), 0.6, 2, 6, ArtPalette.LEAF if i % 2 == 0 else ArtPalette.LEAF_LIGHT)
	b.add_sphere(Transform3D(Basis(), top), 0.13, 2, 6, ArtPalette.TRUNK.darkened(0.2))
	return b.commit()


## A wisp of vapour: three small white puffs, each smaller and a little to the side, rising.
static func _wisp_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, 0.0, 0.0)), 0.17, 3, 8, Color.WHITE)
	b.add_sphere(Transform3D(Basis(), Vector3(0.1, 0.24, 0.0)), 0.13, 3, 8, Color.WHITE)
	b.add_sphere(Transform3D(Basis(), Vector3(-0.02, 0.44, 0.0)), 0.09, 3, 8, Color.WHITE)
	return b.commit()


## The typhoon's way to the island: orange dashes on the sea and an arrow head at the beach.
static func _way_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var d := WAY_TO - WAY_FROM
	var along := d.normalized()
	var basis := Basis(along.cross(Vector3.UP).normalized(), Vector3.UP, -along).orthonormalized()
	var dashes := 5
	var head := 0.55
	var span := d.length() - head
	for k in dashes:
		var u0 := span * (float(k) + 0.15) / dashes
		var u1 := span * (float(k) + 0.75) / dashes
		var mid := WAY_FROM + along * (u0 + u1) * 0.5
		b.add_rounded_box(Transform3D(basis, mid), Vector3(0.22, 0.06, u1 - u0), 0.03, 1, WAY_COLOR, ArtPalette.ORANGE_TOP)
	var tip := WAY_TO
	var back := tip - along * head
	var side := along.cross(Vector3.UP).normalized() * 0.42
	b.add_triangle([back + side, tip, back - side], [WAY_COLOR, ArtPalette.ORANGE_TOP, WAY_COLOR])
	return b.commit()


# --- the cloud ------------------------------------------------------------------------------------

## The child's cloud (and the game's big typhoon): puffs, a typhoon's spiral arms round its eye, rain
## under it and the rough sea it whips up. set_size() picks the look from the strength (0..1).
class Cloud:
	extends Node3D

	const PUFF_COLOR := Color("ffffff")
	const RAIN_GREY := Color("97a3b8")
	const RAIN_SHADE := Color("5d6a86")
	const LIGHT_SHADE := Color("c9d6ec")
	const DROP := Color("cfe9ff")
	## The puffs' radius at a small cloud and at a full rain cloud (m), the spiral's at a full typhoon.
	const SMALL_R := 0.75
	const RAIN_R := 1.45
	const SWIRL_R := 2.8
	const ARMS := 3
	## The eye's radius (a share of the spiral's).
	const EYE := 0.22
	## How fast a full typhoon turns (rad/s; counter-clockwise from above, as in the north).
	const SPIN := 1.2
	const RAIN_FALL_S := 0.5

	var puffs: MeshInstance3D
	var swirl: MeshInstance3D
	var rain: MeshInstance3D
	var foam: MeshInstance3D
	var shadow: MeshInstance3D
	var material: ShaderMaterial
	var size := TyphoonModel.SMALL
	var _t := 0.0
	## What shows now (tests): the puffs' radius, the spiral's, raining.
	var puff_radius := 0.0
	var swirl_radius := 0.0
	var raining := false

	func build() -> void:
		material = DayNightProps.lit_towards(Vector3(-0.3, 0.8, 0.5), PUFF_COLOR, LIGHT_SHADE, 0.2)
		puffs = ArtKit.instance(_puff_mesh(), material)
		puffs.name = "Puffs"
		add_child(puffs)
		swirl = ArtKit.instance(_swirl_mesh(), material)
		swirl.name = "Swirl"
		add_child(swirl)
		rain = ArtKit.instance(_rain_mesh())
		rain.name = "Rain"
		add_child(rain)
		foam = ArtKit.instance(_foam_mesh())
		foam.name = "Foam"
		foam.position = Vector3(0.0, -CLOUD_HEIGHT + 0.02, 0.0)
		add_child(foam)
		# A round soft shadow (radius 1): the builder's blob is a rounded square, which read as a grey
		# square on the pale cold strip under a far, high cloud (#94 review).
		shadow = ArtKit.instance(_shadow_mesh(), ArtKit.shadow_material())
		shadow.name = "Shadow"
		shadow.position = Vector3(0.0, -CLOUD_HEIGHT + 0.03, 0.0)
		add_child(shadow)
		set_size(size)

	## The look for strength `s`: puffs grow and darken up to a rain cloud; past it the spiral opens
	## and the puffs flatten into its middle; rain under a rain cloud and a typhoon.
	func set_size(s: float) -> void:
		size = s
		var grow := clampf((s - TyphoonModel.SMALL) / (TyphoonModel.WARM_CAP - TyphoonModel.SMALL), 0.0, 1.0)
		var storm := clampf((s - TyphoonModel.RAIN) / (TyphoonModel.HOT_CAP - TyphoonModel.RAIN), 0.0, 1.0)
		# Past a rain cloud the heap spreads out into the spiral's arms: it shrinks away and leaves the
		# typhoon's eye clear.
		puff_radius = lerpf(SMALL_R, RAIN_R, grow) * (1.0 - storm)
		puffs.visible = puff_radius > 0.02
		puffs.scale = Vector3.ONE * maxf(0.001, puff_radius)
		swirl_radius = SWIRL_R * storm
		swirl.visible = storm > 0.02
		swirl.scale = Vector3(maxf(0.001, swirl_radius), 1.0, maxf(0.001, swirl_radius))
		var dark := clampf((s - TyphoonModel.SMALL) / (TyphoonModel.RAIN - TyphoonModel.SMALL), 0.0, 1.0)
		material.set_shader_parameter("lit_color", PUFF_COLOR.lerp(RAIN_GREY, dark * (1.0 - 0.45 * storm)))
		material.set_shader_parameter("shade_color", LIGHT_SHADE.lerp(RAIN_SHADE, dark))
		raining = s >= TyphoonModel.RAIN
		rain.visible = raining
		var spread := maxf(puff_radius, swirl_radius * 0.7)
		rain.scale = Vector3(spread, 1.0, spread)
		foam.visible = storm > 0.05
		foam.scale = Vector3.ONE * maxf(0.001, swirl_radius)
		var shade := maxf(puff_radius, swirl_radius) * 1.1
		shadow.scale = Vector3(shade, 1.0, shade)
		# Only under a rain cloud or a typhoon, joined to the sea by its rain: under a small or a weakened
		# cloud high over the far sea it floated apart from it as a grey patch (#94 review).
		shadow.visible = raining

	## The spiral and the foam turn (faster the stronger), the rain falls.
	func animate(delta: float) -> void:
		_t += delta
		var storm := clampf((size - TyphoonModel.RAIN) / (TyphoonModel.HOT_CAP - TyphoonModel.RAIN), 0.0, 1.0)
		swirl.rotation.y += SPIN * storm * delta
		foam.rotation.y += SPIN * 0.5 * storm * delta
		puffs.rotation.y += SPIN * 0.4 * storm * delta
		rain.position.y = -fposmod(_t / RAIN_FALL_S, 1.0) * 0.6

	## The cloud's shadow on the sea (radius 1): a round patch, darkest in the middle, fading to nothing
	## at its rim.
	static func _shadow_mesh() -> Mesh:
		var b := ArtKit.shadow_builder()
		var alpha := ArtKit.shadow_alpha()
		var rings: Array[Vector2] = [Vector2(0.0, alpha), Vector2(0.55, alpha * 0.8), Vector2(1.0, 0.0)]
		var c := ArtPalette.SHADOW
		var sides := 24
		for ring in rings.size() - 1:
			var r0: float = rings[ring].x
			var r1: float = rings[ring + 1].x
			var c0 := Color(c.r, c.g, c.b, rings[ring].y)
			var c1 := Color(c.r, c.g, c.b, rings[ring + 1].y)
			for k in sides:
				var a0 := TAU * k / sides
				var a1 := TAU * (k + 1) / sides
				var i0 := Vector3(cos(a0), 0.0, sin(a0)) * r0
				var i1 := Vector3(cos(a1), 0.0, sin(a1)) * r0
				var o0 := Vector3(cos(a0), 0.0, sin(a0)) * r1
				var o1 := Vector3(cos(a1), 0.0, sin(a1)) * r1
				# (Wound to face up, as ArtKit.flat_disc: the material culls back faces.)
				if r0 > 0.0:
					b.add_triangle([i0, i1, o1], [c0, c0, c1])
				b.add_triangle([i0, o1, o0], [c0, c1, c1])
		return b.commit()

	## The puffs (radius 1): a round heap of balls, the top ones bigger.
	static func _puff_mesh() -> Mesh:
		var b := ArtKit.builder()
		b.flat = false
		b.ao_min = 0.9
		b.ao_height = 0.6
		var balls := [[Vector3(0.0, 0.1, 0.0), 0.62], [Vector3(-0.5, -0.05, 0.12), 0.46], [Vector3(0.52, -0.04, 0.05), 0.48],
			[Vector3(0.12, -0.08, 0.45), 0.42], [Vector3(-0.15, -0.06, -0.45), 0.44], [Vector3(0.38, 0.22, -0.28), 0.4],
			[Vector3(-0.32, 0.3, 0.22), 0.38]]
		for ball: Array in balls:
			b.add_sphere(Transform3D(Basis(), ball[0]), float(ball[1]), 5, 10, Color.WHITE)
		return b.commit()

	## The spiral (radius 1, flat): ARMS arms of flattened puffs on a widening spiral round an empty eye.
	static func _swirl_mesh() -> Mesh:
		var b := ArtKit.builder()
		b.flat = false
		b.ao_min = 1.0
		# The eye wall: a ring of puffs round the clear eye.
		for k in 10:
			var a := TAU * k / 10.0
			b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.7, 1.0)), Vector3(cos(a), 0.0, -sin(a)) * EYE), 0.15, 4, 10, Color.WHITE)
		# The arms wind out from the wall, thinning towards their ends (counter-clockwise seen from
		# above, the way the cloud turns: the arms trail behind).
		for arm in ARMS:
			for k in 14:
				var u := float(k) / 13.0
				var a := TAU * arm / ARMS - u * 2.8
				var r := lerpf(EYE + 0.08, 0.95, u)
				var p := Vector3(cos(a) * r, -0.04 - 0.1 * u, -sin(a) * r)
				var s := lerpf(0.19, 0.09, u)
				b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.5, 1.0)), p), s, 4, 10, Color.WHITE)
		return b.commit()

	## Rain (radius 1): pale streaks falling from the cloud's bottom to the sea.
	static func _rain_mesh() -> Mesh:
		var b := ArtKit.builder()
		b.ao_min = 1.0
		for i in 26:
			var a := i * 2.399963
			var r := 0.9 * sqrt((i + 0.5) / 26.0)
			var top := Vector3(cos(a) * r, -0.45 - fposmod(i * 0.53, 1.5), sin(a) * r)
			b.add_cylinder(Transform3D(Basis(), top + Vector3.DOWN * 0.5), 0.035, 0.035, 0.5, 4, DROP)
		return b.commit()

	## The rough sea under a typhoon (radius 1, flat on the water): white foam crescents round it.
	static func _foam_mesh() -> Mesh:
		var b := ArtKit.builder()
		b.ao_min = 1.0
		for ring: float in [0.55, 0.85, 1.1]:
			for k in 7:
				var a0 := TAU * k / 7.0 + ring * 2.0
				var steps := 4
				for s in steps:
					var t0 := a0 + 0.5 * s / steps
					var t1 := a0 + 0.5 * (s + 1) / steps
					var w := 0.05
					var p0 := Vector3(cos(t0), 0.0, -sin(t0)) * ring
					var p1 := Vector3(cos(t1), 0.0, -sin(t1)) * ring
					var o0 := Vector3(cos(t0), 0.0, -sin(t0)) * (ring + w)
					var o1 := Vector3(cos(t1), 0.0, -sin(t1)) * (ring + w)
					b.add_triangle([p0, o1, o0], [FOAM, FOAM, FOAM])
					b.add_triangle([p0, p1, o1], [FOAM, FOAM, FOAM])
		return b.commit()
