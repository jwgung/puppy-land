## The 구름과 이슬 lab's props (#92; apps/lab3d/docs/art-direction.md): meshes only, posed from the model
## by DewCloudLab._redraw(). A seaside hill:
## - on the left, in front, a wooden table with a big glass cup of water and a bowl heaped with ice
##   cubes; the cube on top of the heap is the one a finger takes (it follows the finger while held).
##   The cubes the child dropped float in the cup, the water turns icier as the cup cools, and dew
##   drops bead on the glass (more and bigger the further the cup is under the dew point), a little
##   puddle at its foot when it is wet all over. The glass is see-through (an alpha shell over the
##   water and the ice) with an opaque rim and foot;
## - round the cup, the air's water vapour as small pale dots (many on the humid day, few on the dry
##   one: hutton-lines 5 "공기 속에는 눈에 보이지 않는 수증기가 있어요", drawn so a child can see it);
## - on the right, the mountain (a green cone with a rocky top, the piece's rock and the wilted
##   flowers on its summit: DewCloudGame), its right side towards the sea; a dotted way up its right
##   skyline with an arrow at the top shows where the air goes;
## - the air parcel on that way (stage 3): a soft puff with vapour dots in it, warm peach at the foot
##   and cooler blue as it rises; at its cloud base it turns into a white cloud that grows as it goes
##   higher;
## - the bread cat between the table and the mountain, watching the cup.
## Visual only: no body, nothing the model or the mission reads.
class_name DewCloudProps
extends RefCounted

## The table (its top's height, centre on the floor, size) and the cup and bowl on it.
const TABLE_TOP := 1.0
const TABLE_AT := Vector3(-3.3, 0.0, 1.5)
const TABLE_SIZE := Vector3(4.6, 0.14, 1.7)
const CUP_AT := Vector3(-2.2, TABLE_TOP, 1.5)
const CUP_BOTTOM := 0.52
const CUP_TOP := 0.62
const CUP_HEIGHT := 1.5
const CUP_SIDES := 24
const WATER_HEIGHT := 1.05
const BOWL_AT := Vector3(-4.5, TABLE_TOP, 1.5)
const BOWL_RADIUS := 0.72
const BOWL_HEIGHT := 0.34
## An ice cube's edge (m), the cubes in the bowl's heap, the next cube's place on top of the heap.
const ICE_EDGE := 0.34
const ICE := Color("a9dcff")
const ICE_TOP := Color("e3f4ff")
const NEXT_ICE := Vector3(0.0, BOWL_HEIGHT + 0.36, 0.0)
## The glass: its tint (alpha), the frost it takes on when cold, its rim and foot.
const GLASS := Color(0.86, 0.95, 1.0, 0.26)
const GLASS_COLD := Color(0.93, 0.98, 1.0, 0.42)
const GLASS_SHINE := Color(1.0, 1.0, 1.0, 0.55)
const RIM := Color("e8f6ff")
const WATER_COLD := Color("bfe8ff")
## Dew: DEW_DROPS drops on the cup's front, DEW_R their radius at full dew; the puddle at full dew.
const DEW_DROPS := 40
const DEW_R := 0.1
const DEW := Color("f2faff")
const DEW_RIM := Color("4f9fe0")
const DEW_SHINE := Color("ffffff")
const PUDDLE := Color("9fd8f7")
## The vapour dots round the cup: humid VAPOUR_HUMID, dry VAPOUR_DRY, in VAPOUR_BOX (world, min and
## size) in front of the table.
const VAPOUR_HUMID := 34
const VAPOUR_DRY := 9
const VAPOUR_AT := Vector3(-5.9, 1.25, 2.45)
const VAPOUR_SIZE := Vector2(5.2, 2.4)
const VAPOUR := Color("bfe3ff")
const VAPOUR_EDGE := Color("8cc8f2")
## The mountain: its foot's middle and its profile [height, radius] from the foot to the summit's
## flat top (m). Its summit (the piece's rock, the flowers) is at MOUNTAIN_AT + (0, top, 0).
const MOUNTAIN_AT := Vector3(3.9, 0.0, -1.8)
const PROFILE := [[0.0, 4.4], [2.0, 2.9], [3.6, 1.45], [4.5, 0.8]]
const MOUNTAIN_SIDES := 18
const MOUNTAIN_LOW := Color("4fbf3b")
const MOUNTAIN_MID := Color("3aa83a")
const MOUNTAIN_HIGH := Color("8f9a7c")
const MOUNTAIN_ROCK := Color("a3a8b2")
## The air parcel: its radius, how far off the mountain's surface its centre rides (times its
## radius), its colours from the warm foot to the cool top, and the cloud's.
const PARCEL_R := 0.72
const PARCEL_OFF := 1.0
const PARCEL_WARM := Color("ffe4c8")
const PARCEL_COOL := Color("b7dbff")
const CLOUD := ArtPalette.CLOUD
## The way up: a dot every WAY_STEP of it, its colour, the arrow at its top.
const WAY_DOTS := 26
const WAY_COLOR := Color("fff1b8")
const ARROW_COLOR := Color("ff7a1a")
const CAT_AT := Vector3(-0.2, 0.0, 2.2)
const WORLD_CENTER := Vector3(0.0, 0.0, -1.0)

var cat: CatActor
var cup: Node3D
var parcel: Node3D
var held_ice: Node3D            # the cube a finger takes (on the heap, or under the finger)
var bright_material: ShaderMaterial
var glass_material: StandardMaterial3D
var _water: MeshInstance3D
var _cubes: MeshInstance3D
var _glass: MeshInstance3D
var _dew: MeshInstance3D
var _vapour: MeshInstance3D
var _puff: MeshInstance3D
var _cloud: MeshInstance3D
var _cup_key := Vector3.INF
var _puff_key := -1.0
var _vapour_key := -1
## What is shown now (tests): ice cubes in the cup, dew drops on it, vapour dots, the cup's cold
## (0..1), the parcel's cool (0..1) and its cloud (0: a puff).
var shown_ice := 0
var shown_drops := 0
var shown_vapour := 0
var shown_cold := 0.0
var shown_cool := 0.0
var shown_cloud := 0.0


## The parcel's centre at `lift` (0 at the mountain's foot .. 1 by its summit): on the mountain's
## right skyline (the plane z = MOUNTAIN_AT.z), PARCEL_OFF radii off its surface.
static func parcel_point(lift: float) -> Vector3:
	var top: float = PROFILE[-1][0]
	var y := clampf(lift, 0.0, 1.0) * top
	var r := radius_at(y)
	# The surface's outward normal there (the profile's slope).
	var n := _normal_at(y)
	return MOUNTAIN_AT + Vector3(r, y, 0.0) + Vector3(n.x, n.y, 0.0) * PARCEL_R * PARCEL_OFF


## The mountain's radius at height `y` (the profile, linear between its points).
static func radius_at(y: float) -> float:
	for i in PROFILE.size() - 1:
		var a: Array = PROFILE[i]
		var b: Array = PROFILE[i + 1]
		if y <= float(b[0]) or i == PROFILE.size() - 2:
			var k := clampf((y - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			return lerpf(float(a[1]), float(b[1]), k)
	return float(PROFILE[-1][1])


## The outward normal (x out, y up) of the profile at height `y`.
static func _normal_at(y: float) -> Vector2:
	var h := 0.25
	var top: float = PROFILE[-1][0]
	var dr := radius_at(minf(y + h, top)) - radius_at(maxf(y - h, 0.0))
	var dy := minf(y + h, top) - maxf(y - h, 0.0)
	return Vector2(dy, -dr).normalized()


## The lift (0..1) of the way's point nearest `p` (x, y of a world point; its z is dropped).
static func lift_of(p: Vector3) -> float:
	var best := 0.0
	var gap := INF
	for k in 201:
		var t := k / 200.0
		var q := parcel_point(t)
		var d := Vector2(q.x - p.x, q.y - p.y).length_squared()
		if d < gap:
			gap = d
			best = t
	return best


## The summit's top (world): the piece's rock stands here.
static func summit() -> Vector3:
	return MOUNTAIN_AT + Vector3(0.0, float(PROFILE[-1][0]), 0.0)


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	glass_material = StandardMaterial3D.new()
	glass_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.vertex_color_use_as_albedo = true
	glass_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var scene := ArtKit.instance(_scene_mesh())
	scene.name = "Table"
	lab.add_child(scene)
	var hill := ArtKit.instance(_mountain_mesh())
	hill.name = "Mountain"
	lab.add_child(hill)
	var way := ArtKit.instance(_way_mesh(), bright_material)
	way.name = "Way"
	lab.add_child(way)
	cup = Node3D.new()
	cup.name = "Cup"
	cup.position = CUP_AT
	lab.add_child(cup)
	_water = MeshInstance3D.new()
	_water.name = "Water"
	_water.material_override = ArtKit.lit_material()
	cup.add_child(_water)
	_cubes = MeshInstance3D.new()
	_cubes.name = "IceInCup"
	_cubes.material_override = ArtKit.lit_material()
	cup.add_child(_cubes)
	var rim := ArtKit.instance(_rim_mesh())
	rim.name = "Rim"
	cup.add_child(rim)
	_glass = MeshInstance3D.new()
	_glass.name = "Glass"
	_glass.material_override = glass_material
	cup.add_child(_glass)
	_dew = MeshInstance3D.new()
	_dew.name = "Dew"
	_dew.material_override = bright_material
	cup.add_child(_dew)
	held_ice = ArtKit.instance(ice_mesh(ICE_EDGE))
	held_ice.name = "NextIce"
	lab.add_child(held_ice)
	_vapour = MeshInstance3D.new()
	_vapour.name = "Vapour"
	_vapour.material_override = bright_material
	lab.add_child(_vapour)
	parcel = Node3D.new()
	parcel.name = "Parcel"
	lab.add_child(parcel)
	_puff = MeshInstance3D.new()
	_puff.name = "Puff"
	_puff.material_override = ArtKit.lit_material()
	parcel.add_child(_puff)
	_cloud = ArtKit.instance(cloud_mesh(PARCEL_R), MapIsland.cloud_material())
	_cloud.name = "Cloud"
	parcel.add_child(_cloud)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = cup
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses everything from the model: the ice in the cup, the cup's cold (0..1), the dew (0..1), the
## vapour (humid or dry), the parcel's lift (0..1), cool (0..1) and cloud (0: none .. 1 full), the
## parcel shown (stage 3), the next cube at `ice_at` (world).
func show(ice: int, cold: float, dew: float, humid: bool, lift: float, cool: float, cloud: float, parcel_on: bool, ice_at: Vector3) -> void:
	held_ice.position = ice_at
	var key := Vector3(ice, snappedf(cold, 0.01), snappedf(dew, 0.01))
	if key != _cup_key:
		_cup_key = key
		shown_ice = ice
		shown_cold = cold
		_water.mesh = _water_mesh(cold)
		_cubes.mesh = _cubes_mesh(ice)
		_glass.mesh = _glass_mesh(cold)
		shown_drops = int(round(dew * DEW_DROPS))
		_dew.mesh = _dew_mesh(dew)
	var dots := VAPOUR_HUMID if humid else VAPOUR_DRY
	if dots != _vapour_key:
		_vapour_key = dots
		shown_vapour = dots
		_vapour.mesh = _vapour_mesh(dots)
	parcel.visible = parcel_on
	parcel.position = parcel_point(lift)
	shown_cool = cool
	shown_cloud = cloud
	var puff_key := snappedf(cool, 0.02) + (100.0 if humid else 0.0)
	if puff_key != _puff_key:
		_puff_key = puff_key
		_puff.mesh = _puff_mesh(cool, humid)
	_puff.visible = cloud <= 0.0
	_cloud.visible = cloud > 0.0
	_cloud.scale = Vector3.ONE * lerpf(1.0, 1.5, cloud)


# --- the table, the bowl, the mountain ------------------------------------------------------------

## The table on its four legs and the bowl with its heap of ice.
func _scene_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = TABLE_TOP
	var half := TABLE_SIZE * 0.5
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.add_cylinder(Transform3D(Basis(), TABLE_AT + Vector3(sx * (half.x - 0.25), 0.0, sz * (half.z - 0.22))), 0.09, 0.08, TABLE_TOP - TABLE_SIZE.y, 6, ArtPalette.WOOD_GRAIN)
	b.ao_min = 0.95
	b.add_rounded_box(Transform3D(Basis(), TABLE_AT + Vector3(0.0, TABLE_TOP - TABLE_SIZE.y * 0.5, 0.0)), TABLE_SIZE, 0.05, 1, ArtPalette.WOOD, Color("dba468"))
	# The bowl: a wide blue bowl and its heap of cubes (the next cube is held_ice, on top).
	b.ao_min = 0.85
	b.ao_height = BOWL_HEIGHT
	b.add_cylinder(Transform3D(Basis(), BOWL_AT), BOWL_RADIUS * 0.62, BOWL_RADIUS, BOWL_HEIGHT, 18, ArtPalette.BLUE, true, Color("dff1ff"))
	b.add_cylinder(Transform3D(Basis(), BOWL_AT + Vector3(0.0, BOWL_HEIGHT - 0.03, 0.0)), BOWL_RADIUS * 1.02, BOWL_RADIUS * 1.02, 0.05, 18, ArtPalette.BLUE_DARK)
	b.ao_min = 1.0
	var heap := [Vector3(-0.3, 0.0, 0.1), Vector3(0.28, 0.0, 0.12), Vector3(0.0, 0.0, -0.22), Vector3(-0.12, 0.2, 0.0), Vector3(0.18, 0.18, -0.08)]
	for i in heap.size():
		var at: Vector3 = BOWL_AT + Vector3(0.0, BOWL_HEIGHT - 0.06, 0.0) + heap[i]
		_add_ice(b, Transform3D(Basis(Vector3.UP, 0.5 * i).rotated(Vector3.RIGHT, 0.2 * (i % 2)), at), ICE_EDGE * 0.9)
	return b.commit()


## The mountain: frustums along PROFILE, green below and rocky at the top, with a flat summit.
func _mountain_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 1.2
	var colors := [MOUNTAIN_LOW, MOUNTAIN_MID, MOUNTAIN_HIGH]
	var tops := [Color("5fd04a"), Color("4fbf3b"), MOUNTAIN_ROCK]
	for i in PROFILE.size() - 1:
		var a: Array = PROFILE[i]
		var c: Array = PROFILE[i + 1]
		b.add_cylinder(Transform3D(Basis(), MOUNTAIN_AT + Vector3(0.0, float(a[0]), 0.0)), float(a[1]), float(c[1]), float(c[0]) - float(a[0]), MOUNTAIN_SIDES, colors[i], i == PROFILE.size() - 2, tops[i])
		b.ao_min = 1.0
	# Bushes and boulders on its slopes (on the camera side, below the way).
	for k in 7:
		var a := deg_to_rad(110.0 + k * 9.0)
		var y := 0.5 + (k % 3) * 0.8
		var r := radius_at(y)
		var at := MOUNTAIN_AT + Vector3(cos(a) * r, y, sin(a) * r)
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.0)), at), 0.35, 3, 8, ArtPalette.LEAF if k % 2 == 0 else ArtPalette.LEAF_LIGHT)
	return b.commit()


## The way up the mountain's right skyline: dots from the foot to the summit and an arrow at the top.
func _way_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for k in WAY_DOTS:
		var p := parcel_point(float(k) / (WAY_DOTS - 1) * 0.9) + Vector3(0.0, 0.0, 0.05)
		b.add_sphere(Transform3D(Basis(), p), 0.07, 3, 6, WAY_COLOR)
	var tip := parcel_point(1.0)
	var back := parcel_point(0.9)
	var along := (tip - back).normalized()
	var side := Vector3(-along.y, along.x, 0.0) * 0.22
	var head := tip
	var foot := tip - along * 0.38
	b.add_triangle([foot + side, foot - side, head], [ARROW_COLOR, ARROW_COLOR, ArtPalette.ORANGE_TOP], Vector3.BACK)
	return b.commit()


# --- the cup --------------------------------------------------------------------------------------

## The cup's radius at height `y` over its foot.
static func cup_radius(y: float) -> float:
	return lerpf(CUP_BOTTOM, CUP_TOP, clampf(y / CUP_HEIGHT, 0.0, 1.0))


## The water in the cup (icier as `cold` grows 0..1).
func _water_mesh(cold: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = WATER_HEIGHT
	var r0 := CUP_BOTTOM - 0.04
	var r1 := cup_radius(WATER_HEIGHT) - 0.04
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.06, 0.0)), r0, r1, WATER_HEIGHT - 0.06, CUP_SIDES, ArtPalette.WATER.lerp(WATER_COLD, cold * 0.7), true, ArtPalette.WATER_TOP.lerp(Color.WHITE, cold * 0.5))
	return b.commit()


## `count` cubes floating at the water's top (the first ones in the middle).
func _cubes_mesh(count: int) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var spots := [Vector3(0.0, 0.0, 0.1), Vector3(-0.24, 0.02, -0.1), Vector3(0.24, -0.02, -0.08), Vector3(-0.12, 0.06, 0.26), Vector3(0.16, 0.08, 0.24)]
	for i in mini(count, spots.size()):
		var at: Vector3 = Vector3(0.0, WATER_HEIGHT - ICE_EDGE * 0.15, 0.0) + spots[i]
		_add_ice(b, Transform3D(Basis(Vector3.UP, 0.7 * i + 0.3).rotated(Vector3.FORWARD, 0.15 * (i % 3 - 1)), at), ICE_EDGE * 0.85)
	return b.commit()


## The cup's opaque rim and foot.
func _rim_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, CUP_HEIGHT - 0.04, 0.0)), CUP_TOP + 0.015, CUP_TOP + 0.015, 0.05, CUP_SIDES, RIM, false)
	b.add_cylinder(Transform3D(Basis(), Vector3.ZERO), CUP_BOTTOM + 0.02, CUP_BOTTOM + 0.01, 0.07, CUP_SIDES, RIM, true, Color("f4fbff"))
	return b.commit()


## The glass: a see-through shell (more frosted when `cold`), with two light shine stripes.
func _glass_mesh(cold: float) -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(), CUP_BOTTOM + 0.01, CUP_TOP, CUP_HEIGHT, CUP_SIDES, GLASS.lerp(GLASS_COLD, cold), false)
	for stripe: Array in [[-0.62, 0.07], [-0.4, 0.035]]:   # angle (rad from the front, to the left), width (rad)
		var a: float = float(stripe[0]) + PI * 0.5
		var w: float = stripe[1]
		var y0 := CUP_HEIGHT * 0.12
		var y1 := CUP_HEIGHT * 0.88
		var p := [_cup_point(a - w, y0, 0.012), _cup_point(a + w, y0, 0.012), _cup_point(a + w, y1, 0.012), _cup_point(a - w, y1, 0.012)]
		b.add_triangle([p[0], p[1], p[2]], [GLASS_SHINE, GLASS_SHINE, GLASS_SHINE], Vector3.BACK)
		b.add_triangle([p[0], p[2], p[3]], [GLASS_SHINE, GLASS_SHINE, GLASS_SHINE], Vector3.BACK)
	return b.commit()


## A point on the glass at angle `a` (rad round y from +x; PI/2 faces the camera), height `y`, `out`
## m outside it.
static func _cup_point(a: float, y: float, out: float) -> Vector3:
	var r := cup_radius(y) + out
	return Vector3(cos(a) * r, y, sin(a) * r)


## The dew on the glass: drops (white with a blue rim: they read over the blue water) over its front (more and bigger as `dew` grows 0..1), each with a
## light shine, and the puddle at its foot when it is wet all over.
func _dew_mesh(dew: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var count := int(round(dew * DEW_DROPS))
	for i in count:
		# A fixed scatter over the front of the glass (golden angle on the half cylinder).
		var u := fposmod(i * 0.618034, 1.0)
		var v := fposmod(i * 0.381966 + 0.13, 1.0)
		var a := PI * 0.5 + (u - 0.5) * PI * 0.95
		var y := lerpf(0.15, CUP_HEIGHT - 0.12, v)
		var r := DEW_R * lerpf(0.55, 1.0, dew) * (0.75 + 0.25 * float(i % 3))
		var at := _cup_point(a, y, r * 0.55)
		var basis := Basis.from_scale(Vector3(1.0, 1.25, 0.75))
		b.add_sphere(Transform3D(basis, at - Vector3(0.0, 0.0, r * 0.25)), r * 1.22, 3, 8, DEW_RIM)
		b.add_sphere(Transform3D(basis, at), r, 3, 8, DEW)
		b.add_sphere(Transform3D(Basis(), at + Vector3(-r * 0.3, r * 0.4, r * 0.45)), r * 0.32, 2, 6, DEW_SHINE)
	if dew >= 0.6:
		var k := (dew - 0.6) / 0.4
		ArtKit.flat_disc(b, Vector3(0.0, 0.005, 0.0), CUP_BOTTOM + 0.12 + 0.2 * k, PUDDLE, 24)
	return b.commit()


## An ice cube of edge `edge` at `xf`: a light blue rounded block with a white top.
static func _add_ice(b: ArtMeshBuilder, xf: Transform3D, edge: float) -> void:
	b.add_rounded_box(xf, Vector3.ONE * edge, edge * 0.18, 1, ICE, ICE_TOP)


static func ice_mesh(edge: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	_add_ice(b, Transform3D(Basis(Vector3.UP, 0.4), Vector3.ZERO), edge)
	return b.commit()


# --- the air --------------------------------------------------------------------------------------

## `count` vapour dots in front of the table (a fixed scatter), each a pale ring with a light middle.
func _vapour_mesh(count: int) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in count:
		var u := fposmod(i * 0.618034 + 0.05, 1.0)
		var v := fposmod(i * 0.754878 + 0.31, 1.0)
		var at := VAPOUR_AT + Vector3(u * VAPOUR_SIZE.x, v * VAPOUR_SIZE.y, 0.0)
		# Keep the cup's own front clear: the dew reads there.
		if absf(at.x - CUP_AT.x) < CUP_TOP + 0.15 and at.y < CUP_AT.y + CUP_HEIGHT + 0.1:
			at.x += (CUP_TOP + 0.35) * (1.0 if at.x >= CUP_AT.x else -1.0)
		var r := 0.055 + 0.015 * float(i % 3)
		ArtKit.disc(b, at, r, VAPOUR_EDGE, 12)
		ArtKit.disc(b, at + Vector3(0.0, 0.0, 0.004), r * 0.68, VAPOUR, 12)
	return b.commit()


## The air puff (radius PARCEL_R round the origin): soft balls in a warm (0) to cool (1) colour with
## vapour dots on its front (many on a humid day).
func _puff_mesh(cool: float, humid: bool) -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 0.9
	b.ao_height = PARCEL_R
	var color := PARCEL_WARM.lerp(PARCEL_COOL, cool)
	for ball: Array in [[Vector3.ZERO, 1.0], [Vector3(-0.55, -0.12, 0.0), 0.7], [Vector3(0.55, -0.1, 0.0), 0.72], [Vector3(0.2, 0.42, -0.05), 0.66]]:
		b.add_sphere(Transform3D(Basis(), (ball[0] as Vector3) * PARCEL_R), PARCEL_R * float(ball[1]), 5, 12, color)
	b.ao_min = 1.0
	var dots := 9 if humid else 3
	for i in dots:
		var a := i * 2.399963
		var r := PARCEL_R * 0.62 * sqrt((i + 0.5) / dots)
		var at := Vector3(cos(a) * r, sin(a) * r * 0.7, PARCEL_R * 0.92)
		ArtKit.disc(b, at, 0.06, VAPOUR_EDGE, 10)
		ArtKit.disc(b, at + Vector3(0.0, 0.0, 0.004), 0.04, VAPOUR, 10)
	return b.commit()


## A white cloud of about `size` (m; about 3.7 * size wide) round the origin: the sky clouds' round
## puffs and soft light (MapIsland.cloud_mesh, 2026-11-07 user).
static func cloud_mesh(size: float) -> Mesh:
	return MapIsland.cloud_mesh(size, CLOUD)
