## The 낮과 밤 lab's props (#74; apps/lab3d/docs/art-direction.md): meshes only, posed from the model by
## DayNightLab._redraw(). The stage is a small "space" on Hutton Island's hill, like the orbit lab's:
## - a deep blue round stage (ArtPalette.SPACE) with star dots,
## - the sun on a pedestal on the right (+x), always bright, with rays,
## - the Earth floating over the stage: a faceted globe (oceans, continents, ice caps; Hutton Island a
##   lighter green patch with the fox's house, its tree and the rock with the piece in front of the
##   house, on its east side). Its light is the art_lit ramp turned towards the lab's sun
##   (globe_material: the half towards the sun is day, the other night; the faceted terminator is the
##   style's two-tone band) and it turns with the model's rotation about its axis,
## - the axis as a rod through the poles, leaning towards the camera by the model's tilt (the
##   equinox: the lean is across the sun's line), with a curved orange arrow round its north end:
##   the way the Earth turns (west to east, counter-clockwise seen from above the north pole). The
##   rod and the arrow do not turn with the globe,
## - the yard window: a framed picture of the sky over the fox's yard on a stand under the globe:
##   the sky's colour (day, dawn / dusk, night), the sun at its altitude and azimuth (the window looks
##   south: east on the left), the stars at night, the yard (grass, the house, the rock) lit by the
##   day and dark at night,
## - the bread cat on the stage, watching the globe (it cheers at a stamp, DayNightGame).
## The house's windows are lit (always bright): they show where the house is on the night side.
## Visual only: no body, nothing the model or the mission reads.
class_name DayNightProps
extends RefCounted

const GLOBE_CENTER := Vector3(-0.9, 2.95, 0.0)
const GLOBE_RADIUS := 1.5
const SUN_CENTER := Vector3(5.0, 2.95, 0.0)
const SUN_RADIUS := 0.8
const SUN_SHADE := Color(1.0, 0.82, 0.6)   # the sun's far facets: warm, never blue
const STAGE_CENTER := Vector3(1.6, 0.0, -0.2)
const STAGE_RADIUS := 7.6
## The globe: RINGS x SIDES faces (faceted), the land's blobs [lon deg, lat deg, radius deg]
## (Hutton Island is the first: under the house), the ice caps beyond ICE_LAT.
const RINGS := 18
const SIDES := 36
const ICE_LAT := 70.0
const HUTTON_ISLAND_DEG := 11.0
const LANDS := [
	[-62.0, 42.0, 22.0], [-95.0, 18.0, 14.0], [-75.0, -18.0, 17.0], [-60.0, -38.0, 11.0],
	[20.0, -8.0, 21.0], [12.0, 22.0, 13.0], [55.0, 38.0, 18.0], [95.0, 44.0, 22.0], [120.0, 12.0, 9.0],
	[135.0, -25.0, 12.0], [165.0, 55.0, 12.0], [-150.0, 62.0, 12.0], [-120.0, -10.0, 7.0],
]
const OCEAN := Color("3c9cf0")
const OCEAN_DEEP := Color("2f86e0")
const LAND := Color("4fbf3b")
const LAND_DRY := Color("9fce55")
const ICE := Color("f4fbff")
const HUTTON_GRASS := Color("8fe066")
## The globe's light (art_lit turned to the lab's sun): full day, the night side deep blue (a quarter
## of the light, the style's never-black), a narrow soft terminator.
const NIGHT := Color("16205a")
const TERMINATOR_SOFTNESS := 0.02
## The house on the globe (m, local: y up from the ground, -z east): scaled up from life to read on
## the globe from the front view.
const HOUSE_SCALE := 1.4
const WALL := Color("fff1d2")
const ROOF := Color("e85a3c")
const ROOF_TOP := Color("ff7a52")
const DOOR := Color("8f5a2c")
const WINDOW_LIT := Color("ffe36a")
const ROCK := Color("9aa3b5")
const ROCK_TOP := Color("b8c0cf")
## The axis rod beyond the poles (m), its radius, the arrow round the north end: its radius, its tube,
## where it sits along the axis (m from the centre), the arc it covers (deg of turn), its colour.
const ROD_OUT := 0.55
const ROD_RADIUS := 0.045
const ARROW_RADIUS := 0.42
const ARROW_TUBE := 0.05
const ARROW_AT := GLOBE_RADIUS + 0.28
const ARROW_FROM_DEG := -215.0
const ARROW_TO_DEG := 15.0
const ARROW_COLOR := Color("ff7a1a")
const ARROW_TOP := Color("ff9440")
const CAT_AT := Vector3(1.5, 0.0, 2.1)
## The yard window: its centre (world), the picture's size (m), the frame's border and depth.
const WINDOW_CENTER := Vector3(-0.9, 0.62, 2.7)
const WINDOW_SIZE := Vector2(2.1, 1.0)
const FRAME := 0.11
const FRAME_DEPTH := 0.12
const FRAME_COLOR := Color("c98d4f")
const FRAME_TOP := Color("dba468")
## The window's sky colours [top, horizon] for the day, the dawn and the night; the sun's altitude
## where the dawn colours are strongest (0) and where the night is complete (TWILIGHT below).
const SKY_DAY := [Color("4aa8f5"), Color("bfe6ff")]
const SKY_DAWN := [Color("6c79c9"), Color("ffb27a")]
const SKY_NIGHT := [Color("101a4f"), Color("26326e")]
const TWILIGHT := 10.0
const DAWN_WIDTH := 14.0
const STAR_COUNT := 16
## The yard's ground share of the picture's height, the sun disc in the picture (m).
const YARD_SHARE := 0.26
const PICTURE_SUN := 0.1

## The bread cat watches the globe from the stage's front, between the window and the sun; it
## cheers at every stamp and takes the piece at the end.
var cat: CatActor
var globe: Node3D        # turns with the model (its children: the globe mesh, the house)
var axis: Node3D         # the rod and the arrow (leans with the tilt, never turns)
var house: Node3D        # on the globe: the house's place (its piece game's parent)
var window: Node3D
var _sky: MeshInstance3D
var _sun_disc: MeshInstance3D
var _stars: MeshInstance3D
var _yard_material: ShaderMaterial
var _sky_key := Vector3.INF
var globe_material: ShaderMaterial
var bright_material: ShaderMaterial


## A material of the style's shader (art_lit) lit from `sun_dir` with `shade` on the far side.
static func lit_towards(sun_dir: Vector3, lit: Color, shade: Color, softness := TERMINATOR_SOFTNESS) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = ArtKit.SHADER
	m.set_shader_parameter("sun_dir", sun_dir.normalized())
	m.set_shader_parameter("lit_color", lit)
	m.set_shader_parameter("shade_color", shade)
	m.set_shader_parameter("threshold", 0.5)   # the terminator where the light is edge-on (N.L = 0)
	m.set_shader_parameter("softness", softness)
	m.set_shader_parameter("sky_fill", 0.0)
	return m


## The house's place on the globe in the globe's own frame (north +y, the house's meridian +x).
static func house_direction(latitude: float) -> Vector3:
	var phi := deg_to_rad(latitude)
	return Vector3(cos(phi), sin(phi), 0.0)


## The frame of a point `dir` (unit, globe frame) on the globe's surface: y up (out of the globe),
## -z east (the way the Earth turns), x south (y × z, along the ground away from the north pole).
static func ground_frame(dir: Vector3, radius: float) -> Transform3D:
	var up := dir.normalized()
	var east := Vector3.UP.cross(up)   # +y (north) x up: the way a point on the globe moves
	if east.length() < 1e-6:
		east = Vector3.FORWARD
	east = east.normalized()
	var z := -east
	var x := up.cross(z).normalized()
	return Transform3D(Basis(x, up, z), up * radius)


## The globe's basis: its frame (north up, the house's meridian at x) put on the world axis leaning
## `tilt` deg towards +z (the camera), turned `hour_angle` deg the true way about it (0 = the house
## faces the sun at +x).
static func globe_basis(tilt: float, hour_angle: float) -> Basis:
	var e := deg_to_rad(tilt)
	var north := Vector3(0.0, cos(e), sin(e))
	var towards := Vector3(0.0, -sin(e), cos(e))
	var frame := Basis(Vector3.RIGHT, north, towards)
	return Basis(north, deg_to_rad(hour_angle)) * frame


func build(lab: Node3D, latitude: float) -> void:
	ArtKit.add_world(lab, Vector3(0.0, 0.0, -0.5), null, 0.0)
	globe_material = lit_towards(SUN_CENTER - GLOBE_CENTER, ArtPalette.LIGHT, NIGHT)
	bright_material = lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var stage := ArtKit.instance(_stage_mesh())
	stage.name = "Stage"
	lab.add_child(stage)
	var sun := ArtKit.instance(_sun_mesh(), lit_towards(Vector3(-0.35, 0.45, 0.82), Color.WHITE, SUN_SHADE, 0.03))
	sun.name = "Sun"
	lab.add_child(sun)
	globe = Node3D.new()
	globe.name = "Globe"
	globe.position = GLOBE_CENTER
	lab.add_child(globe)
	var ball := ArtKit.instance(globe_mesh(latitude), globe_material)
	ball.name = "Ball"
	globe.add_child(ball)
	house = Node3D.new()
	house.name = "House"
	house.transform = ground_frame(house_direction(latitude), GLOBE_RADIUS)
	globe.add_child(house)
	var home := ArtKit.instance(house_mesh(), globe_material)
	home.name = "Home"
	house.add_child(home)
	var lights := ArtKit.instance(house_windows_mesh(), bright_material)
	lights.name = "Windows"
	house.add_child(lights)
	axis = Node3D.new()
	axis.name = "Axis"
	axis.position = GLOBE_CENTER
	lab.add_child(axis)
	var rod := ArtKit.instance(_axis_mesh())
	rod.name = "Rod"
	axis.add_child(rod)
	_build_window(lab)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = globe
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses the globe and the axis (tilt, hour angle: SunModel's) and the window's sky (the sun's
## altitude and azimuth at the house).
func show(tilt: float, hour_angle: float, altitude: float, azimuth: float) -> void:
	globe.basis = globe_basis(tilt, hour_angle)
	axis.basis = globe_basis(tilt, 0.0)
	_show_sky(altitude, azimuth)


# --- the stage and the sun ------------------------------------------------------------------------

func _stage_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.95
	b.ao_height = 0.2
	b.add_cylinder(Transform3D(Basis(), STAGE_CENTER + Vector3(0.0, -0.05, 0.0)), STAGE_RADIUS, STAGE_RADIUS, 0.058, 32, ArtPalette.SPACE, true, ArtPalette.SPACE_TOP)
	b.ao_min = 1.0
	for i in 80:   # star dots: a fixed golden-angle scatter, white and yellow
		var r := STAGE_RADIUS * 0.95 * sqrt((i + 0.5) / 80.0)
		var a := i * 2.399963
		var color := ArtPalette.YELLOW if i % 5 == 0 else ArtPalette.WHITE
		var s := 0.08 if i % 5 == 0 else 0.05
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, a), STAGE_CENTER + Vector3(cos(a) * r, 0.012, sin(a) * r)), Vector3(s, 0.012, s), 0.0, 1, color)
	# The sun's pedestal: a dark foot and a blue post up to the sun.
	b.ao_min = 0.85
	b.ao_height = 0.6
	var foot := Vector3(SUN_CENTER.x, 0.0, SUN_CENTER.z)
	b.add_cylinder(Transform3D(Basis(), foot), 0.55, 0.42, 0.14, 10, ArtPalette.BLUE_DARK)
	b.add_cylinder(Transform3D(Basis(), foot + Vector3(0.0, 0.12, 0.0)), 0.13, 0.13, SUN_CENTER.y - SUN_RADIUS - 0.05, 8, ArtPalette.BLUE)
	# The globe's soft shadow on the stage is the island's blob (a dark round patch under it).
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(GLOBE_CENTER.x, 0.014, GLOBE_CENTER.z)), 1.0, 1.0, 0.004, 20, ArtPalette.SPACE.darkened(0.18))
	_add_window_stand(b)
	return b.commit()


func _sun_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis(), SUN_CENTER), SUN_RADIUS, 6, 12, ArtPalette.YELLOW_TOP)
	# Rays round it, in the plane facing the camera: short fat cones, alternately long and short.
	for i in 12:
		var a := TAU * i / 12.0 + PI / 12.0
		var out := Vector3(cos(a), sin(a), 0.0)
		var length := 0.42 if i % 2 == 0 else 0.3
		var basis := Basis(Quaternion(Vector3.UP, out))
		b.add_cylinder(Transform3D(basis, SUN_CENTER + out * (SUN_RADIUS + 0.08)), 0.11, 0.0, length, 4, ArtPalette.YELLOW)
	return b.commit()


# --- the globe ------------------------------------------------------------------------------------

## The land's score at `dir` (globe frame): > 0 on land (the most of the blobs, their rims a little
## wavy), and whether it is Hutton Island's.
static func land_at(dir: Vector3, latitude: float) -> Array:
	var best := -1.0
	var hutton := false
	var island := house_direction(latitude)
	var own := dir.dot(island) - cos(deg_to_rad(HUTTON_ISLAND_DEG))
	if own > 0.0:
		return [own, true]
	var lon := atan2(-dir.z, dir.x)
	var lat := asin(clampf(dir.y, -1.0, 1.0))
	for land: Array in LANDS:
		var c := _dir_of(float(land[0]), float(land[1]))
		var score := dir.dot(c) - cos(deg_to_rad(float(land[2])))
		score += 0.018 * sin(lon * 7.0 + float(land[0])) * cos(lat * 5.0)
		# Keep the open sea round Hutton Island (its patch reads alone).
		if dir.dot(island) > cos(deg_to_rad(HUTTON_ISLAND_DEG * 2.4)):
			score = minf(score, -0.01)
		best = maxf(best, score)
	return [best, hutton]


## The unit direction of longitude `lon` (deg east of the house's meridian) and latitude `lat`.
static func _dir_of(lon: float, lat: float) -> Vector3:
	var l := deg_to_rad(lon)
	var p := deg_to_rad(lat)
	return Vector3(cos(p) * cos(l), sin(p), -cos(p) * sin(l))


## The globe: RINGS x SIDES faceted faces, each one colour (ocean, land, its dry inland, ice, Hutton
## Island's lighter green).
static func globe_mesh(latitude: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var points: Array = []
	for ring in RINGS + 1:
		var row: Array = []
		var phi := PI * ring / RINGS
		for i in SIDES + 1:
			var theta := TAU * i / SIDES
			row.append(Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)))
		points.append(row)
	for ring in RINGS:
		for i in SIDES:
			var a: Vector3 = points[ring][i]
			var c: Vector3 = points[ring + 1][i + 1]
			var tris: Array = []
			if ring > 0:
				tris.append([a, c, points[ring][i + 1]])
			if ring < RINGS - 1:
				tris.append([a, points[ring + 1][i], c])
			for tri: Array in tris:
				var mid: Vector3 = (tri[0] + tri[1] + tri[2]).normalized()
				var color := _globe_color(mid, latitude, ring, i)
				b.add_triangle([tri[0] * GLOBE_RADIUS, tri[1] * GLOBE_RADIUS, tri[2] * GLOBE_RADIUS], [color, color, color], mid)
	return b.commit()


static func _globe_color(dir: Vector3, latitude: float, ring: int, side: int) -> Color:
	if absf(rad_to_deg(asin(clampf(dir.y, -1.0, 1.0)))) > ICE_LAT:
		return ICE
	var land := land_at(dir, latitude)
	if land[1]:
		return HUTTON_GRASS
	if float(land[0]) > 0.06:
		return LAND_DRY
	if float(land[0]) > 0.0:
		return LAND
	return OCEAN


## The fox's house on Hutton Island (local: y up, -z east, x south): cream walls, a red roof, the
## door and the windows facing east (the morning), a round tree on the west. The rock in front of the
## door, with the piece in its crevice, is the piece game's (DayNightGame).
static func house_mesh() -> Mesh:
	var b := ArtKit.builder()
	var s := HOUSE_SCALE
	b.ao_min = 0.85
	b.ao_height = 0.08
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.06, 0.02) * s), Vector3(0.16, 0.12, 0.14) * s, 0.01, 1, WALL)
	# The roof: a ridge along z (east-west), two slopes.
	var roof := Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3(0.0, 0.12, 0.02) * s)
	b.add_rounded_box(roof, Vector3(0.13, 0.13, 0.17) * s, 0.01, 1, ROOF, ROOF_TOP)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.045, 0.19, 0.06) * s), Vector3(0.03, 0.07, 0.03) * s, 0.0, 1, ROOF.darkened(0.25))
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.045, -0.052) * s), Vector3(0.045, 0.08, 0.01) * s, 0.0, 1, DOOR)
	# The tree on the west.
	b.add_cylinder(Transform3D(Basis(), Vector3(-0.02, 0.0, 0.17) * s), 0.018 * s, 0.014 * s, 0.09 * s, 6, ArtPalette.TRUNK)
	b.add_sphere(Transform3D(Basis(), Vector3(-0.02, 0.13, 0.17) * s), 0.065 * s, 3, 6, ArtPalette.LEAF_LIGHT)
	return b.commit()


## The house's windows (always bright: lit at night, where the house is on the dark side).
static func house_windows_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var s := HOUSE_SCALE
	for x: float in [-0.045, 0.045]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(x, 0.07, -0.052) * s), Vector3(0.03, 0.03, 0.008) * s, 0.0, 1, WINDOW_LIT)
	return b.commit()


# --- the axis and its arrow -----------------------------------------------------------------------

## The rod through the poles (the axis node's y) and the curved arrow round its north end, in the
## axis node's frame (y north, x towards the sun when untilted, z towards the camera).
func _axis_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := GLOBE_RADIUS + ROD_OUT
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, -half, 0.0)), ROD_RADIUS, ROD_RADIUS, half * 2.0, 8, ArtPalette.STEEL_SHINE)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, half, 0.0)), ROD_RADIUS * 2.0, 3, 6, ArtPalette.RED)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, -half, 0.0)), ROD_RADIUS * 1.6, 3, 6, ArtPalette.STEEL)
	add_turn_arrow(b, Vector3(0.0, ARROW_AT, 0.0), ARROW_RADIUS, ARROW_TUBE, ARROW_FROM_DEG, ARROW_TO_DEG, ARROW_COLOR, ARROW_TOP)
	return b.commit()


## The turning arrow: a tube round the y axis at `center` from `from_deg` to `to_deg` (the true way:
## counter-clockwise seen from +y; 0 = +x, -90 = +z, the side towards the camera), and a cone head
## at its end along the turn. One smooth shape: the tube is swept in many short facets.
static func add_turn_arrow(b: ArtMeshBuilder, center: Vector3, radius: float, tube: float, from_deg: float, to_deg: float, color: Color, top: Color) -> void:
	var steps := 40
	var sides := 8
	var head := tube * 3.2
	var head_deg := rad_to_deg(head / radius)
	var end_deg := to_deg - head_deg
	var rings: Array = []
	for k in steps + 1:
		var a := deg_to_rad(lerpf(from_deg, end_deg, float(k) / steps))
		var p := center + _turn_point(a, radius)
		var tangent := _turn_tangent(a)
		var out := (p - center).normalized()
		var ring: Array = []
		for j in sides:
			var t := TAU * j / sides
			ring.append(p + (out * cos(t) + Vector3.UP * sin(t)) * tube)
		rings.append(ring)
	for k in steps:
		for j in sides:
			var a0: Vector3 = rings[k][j]
			var a1: Vector3 = rings[k][(j + 1) % sides]
			var b0: Vector3 = rings[k + 1][j]
			var b1: Vector3 = rings[k + 1][(j + 1) % sides]
			var mid := (a0 + a1 + b0 + b1) * 0.25
			var axis_point := center + _turn_point(deg_to_rad(lerpf(from_deg, end_deg, (k + 0.5) / steps)), radius)
			var c := top if (mid - axis_point).y > 0.0 else color
			b.add_triangle([a0, b0, b1], [c, c, c], mid - axis_point)
			b.add_triangle([a0, b1, a1], [c, c, c], mid - axis_point)
	# The tail's cap and the head: a cone along the turn's tangent at the end of the tube.
	var tail := deg_to_rad(from_deg)
	var tail_p := center + _turn_point(tail, radius)
	for j in sides:
		var r0: Vector3 = rings[0][j]
		var r1: Vector3 = rings[0][(j + 1) % sides]
		b.add_triangle([tail_p, r1, r0], [color, color, color], -_turn_tangent(tail))
	var end := deg_to_rad(end_deg)
	var base := center + _turn_point(end, radius)
	var dir := _turn_tangent(end)
	var tip := center + _turn_point(deg_to_rad(to_deg), radius)
	var along := (tip - base).normalized()
	var out_e := (base - center).normalized()
	var up := along.cross(out_e).normalized()
	var ring_h: Array = []
	for j in sides:
		var t := TAU * j / sides
		ring_h.append(base + (out_e * cos(t) + up * sin(t)) * tube * 2.3)
	for j in sides:
		var h0: Vector3 = ring_h[j]
		var h1: Vector3 = ring_h[(j + 1) % sides]
		var c := top if ((h0 + h1) * 0.5 - base).y > 0.0 else color
		b.add_triangle([h0, h1, tip], [c, c, c], (h0 + h1) * 0.5 - base + dir * 0.2)
		b.add_triangle([h1, h0, base], [color, color, color], -dir)


## A point of the turn's circle (angle `a` rad from +x, the true way: towards -z... seen from +y,
## counter-clockwise: +x -> -z).
static func _turn_point(a: float, radius: float) -> Vector3:
	return Vector3(cos(a), 0.0, -sin(a)) * radius


static func _turn_tangent(a: float) -> Vector3:
	return Vector3(-sin(a), 0.0, -cos(a))


# --- the yard window ------------------------------------------------------------------------------

func _add_window_stand(b: ArtMeshBuilder) -> void:
	b.ao_min = 0.8
	b.ao_height = 0.4
	var bottom := WINDOW_CENTER.y - WINDOW_SIZE.y * 0.5 - FRAME
	for side: float in [-1.0, 1.0]:
		var x := WINDOW_CENTER.x + side * WINDOW_SIZE.x * 0.36
		b.add_cylinder(Transform3D(Basis(), Vector3(x, 0.0, WINDOW_CENTER.z - 0.05)), 0.05, 0.04, bottom + 0.05, 6, ArtPalette.WOOD_GRAIN)
		b.add_rounded_box(Transform3D(Basis(), Vector3(x, 0.03, WINDOW_CENTER.z - 0.05)), Vector3(0.32, 0.06, 0.24), 0.02, 1, ArtPalette.WOOD_GRAIN)


func _build_window(lab: Node3D) -> void:
	window = Node3D.new()
	window.name = "YardWindow"
	window.position = WINDOW_CENTER
	lab.add_child(window)
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var w := WINDOW_SIZE.x + FRAME * 2.0
	var h := WINDOW_SIZE.y + FRAME * 2.0
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, side * (h - FRAME) * 0.5, 0.0)), Vector3(w, FRAME, FRAME_DEPTH), 0.025, 1, FRAME_COLOR, FRAME_TOP)
		b.add_rounded_box(Transform3D(Basis(), Vector3(side * (w - FRAME) * 0.5, 0.0, 0.0)), Vector3(FRAME, h - FRAME * 2.0 + 0.002, FRAME_DEPTH), 0.025, 1, FRAME_COLOR, FRAME_TOP)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.0, -FRAME_DEPTH * 0.5 + 0.01)), Vector3(w - 0.02, h - 0.02, 0.02), 0.0, 1, FRAME_COLOR.darkened(0.3))
	var frame := ArtKit.instance(b.commit())
	frame.name = "Frame"
	window.add_child(frame)
	_sky = MeshInstance3D.new()
	_sky.name = "Sky"
	_sky.material_override = bright_material
	window.add_child(_sky)
	_stars = ArtKit.instance(_stars_mesh(), bright_material)
	_stars.name = "Stars"
	window.add_child(_stars)
	var disc := ArtKit.builder()
	disc.ao_min = 1.0
	disc.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), PICTURE_SUN * 1.35, PICTURE_SUN * 1.35, 0.004, 16, ArtPalette.YELLOW.lightened(0.45))
	disc.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, 0.004)), PICTURE_SUN, PICTURE_SUN, 0.004, 16, ArtPalette.YELLOW)
	_sun_disc = ArtKit.instance(disc.commit(), bright_material)
	_sun_disc.name = "SkySun"
	window.add_child(_sun_disc)
	_yard_material = lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var yard := ArtKit.instance(_yard_mesh(), _yard_material)
	yard.name = "Yard"
	window.add_child(yard)
	var lights := ArtKit.builder()
	lights.ao_min = 1.0
	for x: float in [0.33, 0.43]:
		lights.add_rounded_box(Transform3D(Basis(), Vector3(x, _horizon_y() + 0.08, 0.047)), Vector3(0.05, 0.05, 0.004), 0.0, 1, WINDOW_LIT)
	var yard_lights := ArtKit.instance(lights.commit(), bright_material)
	yard_lights.name = "YardLights"
	window.add_child(yard_lights)


## The picture's horizon (window local y).
func _horizon_y() -> float:
	return -WINDOW_SIZE.y * 0.5 + WINDOW_SIZE.y * YARD_SHARE


## The yard in the picture: a green hill along the bottom (in front of the sun: a rising sun is half
## hidden behind it), the fox's house, its tree and the rock, in front of the sky.
func _yard_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := WINDOW_SIZE * 0.5
	var y0 := -half.y
	var hy := _horizon_y()
	var steps := 16
	for k in steps:
		var x0 := lerpf(-half.x, half.x, float(k) / steps)
		var x1 := lerpf(-half.x, half.x, float(k + 1) / steps)
		var t0 := hy + 0.025 * sin(x0 * 3.1) + 0.015 * cos(x0 * 7.0)
		var t1 := hy + 0.025 * sin(x1 * 3.1) + 0.015 * cos(x1 * 7.0)
		var c := ArtPalette.GRASS_TOP
		b.add_triangle([Vector3(x0, y0, 0.03), Vector3(x1, y0, 0.03), Vector3(x1, t1, 0.03)], [ArtPalette.GRASS, ArtPalette.GRASS, c], Vector3.BACK)
		b.add_triangle([Vector3(x0, y0, 0.03), Vector3(x1, t1, 0.03), Vector3(x0, t0, 0.03)], [ArtPalette.GRASS, c, c], Vector3.BACK)
	# The house (front view: its east wall), the roof, the door; the tree; the rock.
	var hx := 0.38
	b.add_rounded_box(Transform3D(Basis(), Vector3(hx, hy + 0.09, 0.04)), Vector3(0.26, 0.2, 0.01), 0.0, 1, WALL)
	b.add_triangle([Vector3(hx - 0.17, hy + 0.185, 0.045), Vector3(hx + 0.17, hy + 0.185, 0.045), Vector3(hx, hy + 0.33, 0.045)], [ROOF, ROOF, ROOF_TOP], Vector3.BACK)
	b.add_rounded_box(Transform3D(Basis(), Vector3(hx - 0.0, hy + 0.04, 0.046)), Vector3(0.06, 0.1, 0.004), 0.0, 1, DOOR)
	b.add_rounded_box(Transform3D(Basis(), Vector3(hx + 0.29, hy + 0.06, 0.035)), Vector3(0.025, 0.14, 0.01), 0.0, 1, ArtPalette.TRUNK)
	_disc(b, Vector3(hx + 0.29, hy + 0.17, 0.04), 0.09, ArtPalette.LEAF_LIGHT)
	_disc(b, Vector3(hx - 0.3, hy + 0.025, 0.05), 0.06, ROCK)
	_disc(b, Vector3(hx - 0.26, hy + 0.02, 0.052), 0.04, ROCK_TOP)
	return b.commit()


static func _disc(b: ArtMeshBuilder, c: Vector3, r: float, color: Color, sides := 10) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		b.add_triangle([c, c + Vector3(cos(a0), sin(a0), 0.0) * r, c + Vector3(cos(a1), sin(a1), 0.0) * r], [color, color, color], Vector3.BACK)


func _stars_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := WINDOW_SIZE * 0.5
	var hy := _horizon_y()
	for i in STAR_COUNT:
		var u := fposmod(i * 0.618034 + 0.13, 1.0)
		var v := fposmod(i * 0.7548777 + 0.31, 1.0)
		var p := Vector3(lerpf(-half.x + 0.08, half.x - 0.08, u), lerpf(hy + 0.12, half.y - 0.06, v), 0.02)
		var r := 0.035 if i % 4 == 0 else 0.022
		var color := Color("fff3a6") if i % 3 == 0 else Color.WHITE
		for k in 4:   # a four-point twinkle: two thin diamonds
			var a := PI * 0.5 * k
			var tip := p + Vector3(cos(a), sin(a), 0.0) * r
			var side := Vector3(-sin(a), cos(a), 0.0) * r * 0.3
			b.add_triangle([p + side, tip, p - side], [color, color, color], Vector3.BACK)
	return b.commit()


## The window's sky for the sun at `altitude` / `azimuth` (deg): the colours, the stars at night, the
## sun's disc where it stands (east on the left: the window looks south).
func _show_sky(altitude: float, azimuth: float) -> void:
	var key := Vector3(snappedf(altitude, 0.1), snappedf(azimuth, 0.1), 0.0)
	if key == _sky_key:
		return
	_sky_key = key
	var day := clampf((altitude + TWILIGHT * 0.3) / TWILIGHT, 0.0, 1.0)
	var dawn := clampf(1.0 - absf(altitude) / DAWN_WIDTH, 0.0, 1.0)
	var top := (SKY_NIGHT[0] as Color).lerp(SKY_DAY[0], day).lerp(SKY_DAWN[0], dawn * 0.55)
	var low := (SKY_NIGHT[1] as Color).lerp(SKY_DAY[1], day).lerp(SKY_DAWN[1], dawn * 0.9)
	_sky.mesh = _sky_mesh(top, low)
	_stars.visible = altitude < -TWILIGHT * 0.6
	var light := lerpf(0.32, 1.0, day)
	_yard_material.set_shader_parameter("tint", Color(light, light, lerpf(0.55, 1.0, day)))
	var half := WINDOW_SIZE * 0.5
	var hy := _horizon_y()
	# Azimuth 90 (east) -> the left edge, 180 (south) -> the middle, 270 (west) -> the right edge.
	var x := clampf((azimuth - 180.0) / 90.0, -1.0, 1.0) * (half.x - PICTURE_SUN * 1.6)
	var y := hy + clampf(altitude / 60.0, -0.5, 1.0) * (half.y - PICTURE_SUN * 1.5 - hy)
	_sun_disc.position = Vector3(x, y, 0.012)
	_sun_disc.visible = altitude > -PICTURE_SUN * 30.0


static func _sky_mesh(top: Color, low: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := WINDOW_SIZE * 0.5
	var corners := [Vector3(-half.x, -half.y, 0.0), Vector3(half.x, -half.y, 0.0), Vector3(half.x, half.y, 0.0), Vector3(-half.x, half.y, 0.0)]
	b.add_triangle([corners[0], corners[1], corners[2]], [low, low, top], Vector3.BACK)
	b.add_triangle([corners[0], corners[2], corners[3]], [low, top, top], Vector3.BACK)
	return b.commit()
