## The 물의 여행 lab's props (#91; apps/lab3d/docs/art-direction.md): meshes only, posed from the model
## by WaterCycleLab._redraw() and moved every frame by animate(). A seaside table on Hutton Island's
## coast, seen from the front (x right, y up, +z towards the camera):
## - a long sand table: the sea on its left (blue water with foam), grass land on its right with the
##   dry frog pond (a ring of stones round a cracked mud bottom; the water rises in it with the rain),
## - the sun high over the sea, big: the thing the child presses and holds. A weak sun is small and
##   pale with short rays, a strong one big and deep yellow with long rays (the condition). While it
##   is held, warm beams reach down to the sea and wavy wisps of vapour rise from the sea and drift to
##   the sky over the pond. Once the day's sunshine is used up it turns a sunset orange.
## - the cloud over the pond: none until the first cloud's water has gone up, then a white cloud that
##   grows and darkens into a grey rain cloud; with a strong sun two more clouds join it when it rains.
##   While it rains (held, heavy) drops fall from it into the pond.
## - the day sign on the beach between the sea and the land: a bar with a sun at its left end and a
##   moon at its right, filled with the day's sunshine left (no number, no clock),
## - the bread cat on the land beside the pond.
## Visual only: no body, nothing the model or the mission reads.
class_name WaterCycleProps
extends RefCounted

## The table: its middle, half size and top (m); the sea's part (x from its left edge to SEA_RIGHT) is
## sunk to SEA_TOP, the land's grass top at LAND_TOP.
const TABLE_CENTER := Vector3(0.0, 0.0, 0.0)
const TABLE_HALF := Vector2(6.6, 3.0)
const TABLE_TOP := 0.5
const SEA_RIGHT := -1.0
const SEA_TOP := 0.58
const LAND_LEFT := -0.1
const LAND_TOP := 0.6
const SEA_DEEP := Color("2f8fdc")
const SEA_LIGHT := Color("5cb8f2")
const FOAM := ArtPalette.FOAM
const TABLE_SIDE := Color("d9b56a")
## The sun (the hold's target): where it is, its ball's radius and its rays' reach for a weak and a
## strong sun, its sunset colour.
const SUN_AT := Vector3(-3.2, 3.65, -0.4)
const WEAK_RADIUS := 0.7
const STRONG_RADIUS := 0.95
const WEAK_RAYS := 0.26
const STRONG_RAYS := 0.5
const SUN_SHADE := Color(1.0, 0.82, 0.6)
const WEAK_LIT := Color(1.0, 0.97, 0.82)
const SUNSET_LIT := Color(1.0, 0.55, 0.38)
## The warm beams from the sun down to the sea while it is held.
const BEAMS := 3
const BEAM_COLOR := Color("fff0a0")
const BEAM_WIDTH := 0.16
## The pond on the land (its stone ring's radius, its bottom and its full water's height over the
## land) and the cracks in its dry mud.
const POND_AT := Vector3(3.0, LAND_TOP, 0.5)
const POND_RADIUS := 1.5
const POND_DEPTH := 0.34
const MUD := Color("a67a4e")
const MUD_TOP := Color("b98b5a")
const CRACK := Color("6e4a2c")
const POND_WATER := ArtPalette.POND
const POND_WATER_TOP := Color("7ccaf7")
const STONE := Color("aab3c4")
const STONE_TOP := Color("c6cdd9")
## The cloud: its place over the pond, its size when it first forms and when heavy (times its mesh),
## its colours.
const CLOUD_AT := Vector3(2.8, 4.3, -0.6)
const CLOUD_SMALL := 0.55
const CLOUD_BIG := 1.0
const CLOUD_WHITE := Color("ffffff")
const CLOUD_GREY := Color("b3bfd1")
## The strong sun's two more clouds (from the main one) when it rains.
const MORE_CLOUDS := [Vector3(-2.1, -0.3, -0.6), Vector3(2.1, -0.2, -0.5)]
## The clouds bob gently up and down (m, s a bob; each one a little out of step), visual only.
const CLOUD_BOB := 0.07
const CLOUD_BOB_S := 3.6
## The rain: drop columns under the cloud (x spread round the pond's middle), the rows' gap, the fall
## speed; a weak sun's rain has every other column.
const RAIN_COLUMNS := 14
const RAIN_SPREAD := 1.25
const RAIN_GAP := 0.7
const RAIN_SPEED := 7.0
## The rain goes on falling this long after the sun is let go (a heavy cloud does not stop at once).
const RAIN_TAIL_S := 5.0
const DROP := Color("4aa8f5")
const DROP_LENGTH := 0.26
## The vapour: wisps rising from the sea along a curve to the cloud, how many (a weak sun shows
## WEAK_WISPS of them), how long one takes.
const WISPS := 10
const WEAK_WISPS := 5
const WISP_S := 2.4
const WISP_COLOR := Color("e9f6ff")
## The day sign on the beach: its bar's centre and size, and the colours.
const SIGN_AT := Vector3(-0.55, 1.9, 2.1)
const DAY_BAR := Vector2(1.6, 0.3)
const DAY_TRACK := Color("23306e")
const DAY_FILL := Color("ffc61a")
const DAY_FILL_TOP := Color("ffe36a")
const MOON := Color("f4f1d0")
const CAT_AT := Vector3(5.5, LAND_TOP, 1.7)
## The lab's corner of the island (its trees stand clear of the table).
const WORLD_CENTER := Vector3(0.0, 0.0, -6.5)

var cat: CatActor
var sun: Node3D                 # the sun's place (the knob sits here)
var cloud: Node3D               # the main cloud (scaled with its water)
var pond_water: Node3D          # the pond's water disc (raised and widened with the rain)
var day_sign: Node3D            # the day sign's board (its bar)
var bright_material: ShaderMaterial
var sun_material: ShaderMaterial
var _weak_sun: MeshInstance3D
var _strong_sun: MeshInstance3D
var _beams: MeshInstance3D
var _white_cloud: MeshInstance3D
var _grey_cloud: MeshInstance3D
var _more_clouds: Array[MeshInstance3D] = []
var _rain: MeshInstance3D
var _wisps: Array[MeshInstance3D] = []
var _day_fill: MeshInstance3D
var _t := 0.0
var _rain_until := -1.0         # the rain's tail ends then (game clock; -1: no tail)
var _key := []
## What the props show now (tests, animate): the sun strong, held (beams and vapour), raining, the
## cloud's size (0 none .. 1 heavy), the pond's water (0..1), the day left (0..1), the sun set.
var shown_strong := false
var shown_heating := false
var shown_raining := false
var shown_cloud := 0.0
var shown_pond := 0.0
var shown_day := 1.0
var shown_sunset := false


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var table := ArtKit.instance(_table_mesh())
	table.name = "Table"
	lab.add_child(table)
	var pond := ArtKit.instance(_pond_mesh())
	pond.name = "Pond"
	lab.add_child(pond)
	pond_water = ArtKit.instance(_water_mesh())
	pond_water.name = "PondWater"
	pond_water.position = POND_AT
	lab.add_child(pond_water)
	var posts := ArtKit.instance(_sign_posts_mesh())
	posts.name = "DaySignPosts"
	lab.add_child(posts)
	day_sign = Node3D.new()
	day_sign.name = "DaySign"
	day_sign.position = SIGN_AT
	lab.add_child(day_sign)
	day_sign.add_child(ArtKit.instance(_sign_frame_mesh()))
	var track := ArtKit.instance(_sign_face_mesh(), bright_material)
	track.name = "DayTrack"
	day_sign.add_child(track)
	_day_fill = MeshInstance3D.new()
	_day_fill.name = "DayFill"
	_day_fill.material_override = bright_material
	day_sign.add_child(_day_fill)
	sun = Node3D.new()
	sun.name = "Sun"
	sun.position = SUN_AT
	lab.add_child(sun)
	sun_material = DayNightProps.lit_towards(Vector3(-0.35, 0.45, 0.82), Color.WHITE, SUN_SHADE, 0.03)
	_weak_sun = ArtKit.instance(sun_mesh(WEAK_RADIUS, WEAK_RAYS, 8, ArtPalette.YELLOW_TOP.lightened(0.25), ArtPalette.YELLOW_TOP), sun_material)
	_weak_sun.name = "WeakSun"
	sun.add_child(_weak_sun)
	_strong_sun = ArtKit.instance(sun_mesh(STRONG_RADIUS, STRONG_RAYS, 12, ArtPalette.YELLOW, ArtPalette.ORANGE_TOP), sun_material)
	_strong_sun.name = "StrongSun"
	sun.add_child(_strong_sun)
	_beams = ArtKit.instance(_beams_mesh(), bright_material)
	_beams.name = "Beams"
	lab.add_child(_beams)
	cloud = Node3D.new()
	cloud.name = "Cloud"
	cloud.position = CLOUD_AT
	lab.add_child(cloud)
	_white_cloud = ArtKit.instance(MapIsland.cloud_mesh(1.0, CLOUD_WHITE), MapIsland.cloud_material())
	_white_cloud.name = "WhiteCloud"
	cloud.add_child(_white_cloud)
	_grey_cloud = ArtKit.instance(MapIsland.cloud_mesh(1.0, CLOUD_GREY), MapIsland.cloud_material())
	_grey_cloud.name = "RainCloud"
	cloud.add_child(_grey_cloud)
	for i in MORE_CLOUDS.size():
		var more := ArtKit.instance(MapIsland.cloud_mesh(1.0, CLOUD_GREY.lightened(0.15)), MapIsland.cloud_material())
		more.name = "MoreCloud%d" % i
		more.position = MORE_CLOUDS[i]
		more.scale = Vector3.ONE * 0.62
		cloud.add_child(more)
		_more_clouds.append(more)
	_rain = ArtKit.instance(_rain_mesh(), bright_material)
	_rain.name = "Rain"
	lab.add_child(_rain)
	var wisp := _wisp_mesh()
	for i in WISPS:
		var w := ArtKit.instance(wisp, bright_material)
		w.name = "Vapour%d" % i
		w.visible = false
		lab.add_child(w)
		_wisps.append(w)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = pond_water
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses the model's state: the sun (strong, held, set), the cloud's size (0..1, below 0 none), the
## pond's water (0..1), the day left (0..1), raining.
func show(strong: bool, heating: bool, cloud_share: float, has_cloud: bool, pond: float, day_left: float, sunset: bool, raining: bool) -> void:
	shown_strong = strong
	shown_heating = heating
	shown_raining = raining
	shown_cloud = cloud_share if has_cloud else 0.0
	shown_pond = pond
	shown_day = day_left
	shown_sunset = sunset
	_weak_sun.visible = not strong
	_strong_sun.visible = strong
	sun_material.set_shader_parameter("lit_color", SUNSET_LIT if sunset else (Color.WHITE if strong else WEAK_LIT))
	_beams.visible = heating
	cloud.visible = has_cloud
	cloud.scale = Vector3.ONE * lerpf(CLOUD_SMALL, CLOUD_BIG, cloud_share)
	# A heavy cloud is grey; once the pond is full it has rained out and is white again.
	var heavy := has_cloud and cloud_share >= 1.0 and pond < 1.0
	_grey_cloud.visible = heavy
	_white_cloud.visible = has_cloud and not heavy
	var more := strong and heavy
	for c in _more_clouds:
		c.visible = more
	if raining:
		_rain.visible = true
		_rain_until = -1.0
	elif not heavy:
		_rain.visible = false
		_rain_until = -1.0
	elif _rain.visible and _rain_until < 0.0:
		_rain_until = _t + RAIN_TAIL_S
	pond_water.visible = pond > 0.0
	pond_water.position = POND_AT + Vector3.UP * (0.02 + (POND_DEPTH - 0.06) * pond)
	pond_water.scale = Vector3(lerpf(0.72, 1.0, pond), 1.0, lerpf(0.72, 1.0, pond))
	var key := [snappedf(day_left, 0.002)]
	if key != _key:
		_key = key
		_day_fill.mesh = _day_fill_mesh(day_left)


## Moves what moves on its own (the rain falling, the vapour rising) by `delta` seconds.
func animate(delta: float) -> void:
	_t += delta
	if _rain_until >= 0.0 and _t > _rain_until:
		_rain.visible = false
		_rain_until = -1.0
	if _rain.visible:
		_rain.position = Vector3(0.0, -fposmod(_t * RAIN_SPEED, RAIN_GAP), 0.0)
	var shown := (WISPS if shown_strong else WEAK_WISPS) if shown_heating else 0
	for i in WISPS:
		var w := _wisps[i]
		w.visible = i < shown
		if not w.visible:
			continue
		var u := fposmod(_t / WISP_S + float(i) / float(shown), 1.0)
		w.position = wisp_point(i, u)
		w.scale = Vector3.ONE * (1.0 + 1.0 * sin(PI * u))
	var bob := Vector3.UP * CLOUD_BOB * sin(TAU * _t / CLOUD_BOB_S)
	_white_cloud.position = bob
	_grey_cloud.position = bob
	for i in _more_clouds.size():
		_more_clouds[i].position = MORE_CLOUDS[i] + Vector3.UP * CLOUD_BOB * sin(TAU * _t / CLOUD_BOB_S + 2.0 + 2.0 * i)


## Where wisp `i` is at `u` (0 on the sea .. 1 at the cloud): up from its spot on the sea, then
## curving over to the cloud's underside.
static func wisp_point(i: int, u: float) -> Vector3:
	var from := Vector3(lerpf(-5.8, -1.7, fposmod(i * 0.618, 1.0)), SEA_TOP + 0.2, lerpf(-1.2, 1.6, fposmod(i * 0.382, 1.0)))
	var to := CLOUD_AT + Vector3(lerpf(-1.4, 0.6, fposmod(i * 0.29, 1.0)), -0.6, 0.2)
	var bend := Vector3(from.x + 0.6, to.y - 0.4, lerpf(from.z, to.z, 0.5))
	var a := from.lerp(bend, u)
	var b := bend.lerp(to, u)
	return a.lerp(b, u)


# --- the table, the sea and the land ----------------------------------------------------------------

func _table_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.5
	var c := TABLE_CENTER
	b.add_rounded_box(Transform3D(Basis(), c + Vector3(0.0, TABLE_TOP * 0.5, 0.0)), Vector3(TABLE_HALF.x * 2.0, TABLE_TOP, TABLE_HALF.y * 2.0), 0.18, 2, TABLE_SIDE, ArtPalette.SAND)
	b.ao_min = 1.0
	# The sea: a deep water slab sunk into the left of the table with a lighter shallow band and foam
	# along its shore.
	var sea_w := SEA_RIGHT - (c.x - TABLE_HALF.x + 0.25)
	var sea_c := Vector3(c.x - TABLE_HALF.x + 0.25 + sea_w * 0.5, SEA_TOP - 0.02, c.z)
	b.add_rounded_box(Transform3D(Basis(), sea_c), Vector3(sea_w, 0.08, TABLE_HALF.y * 2.0 - 0.5), 0.04, 1, SEA_DEEP, SEA_DEEP)
	b.add_rounded_box(Transform3D(Basis(), Vector3(SEA_RIGHT - 0.45, SEA_TOP - 0.005, c.z)), Vector3(0.9, 0.06, TABLE_HALF.y * 2.0 - 0.5), 0.03, 1, SEA_LIGHT, SEA_LIGHT)
	for i in 9:   # little wave strokes on the sea
		var x := lerpf(sea_c.x - sea_w * 0.4, SEA_RIGHT - 1.3, fposmod(i * 0.618, 1.0))
		var z := lerpf(-2.2, 2.2, fposmod(i * 0.382 + 0.1, 1.0))
		b.add_rounded_box(Transform3D(Basis(), Vector3(x, SEA_TOP + 0.03, z)), Vector3(0.7, 0.025, 0.07), 0.01, 1, FOAM)
	for k in 12:   # the surf: foam blobs along the shore
		var z := lerpf(-2.6, 2.6, float(k) / 11.0)
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.35, 1.0)), Vector3(SEA_RIGHT + 0.02 * sin(k * 2.0), SEA_TOP + 0.03, z)), 0.16, 2, 8, FOAM)
	# The land: a grass top on the right of the table.
	var land_w := c.x + TABLE_HALF.x - 0.2 - LAND_LEFT
	b.add_rounded_box(Transform3D(Basis(), Vector3(LAND_LEFT + land_w * 0.5, LAND_TOP - 0.04, c.z)), Vector3(land_w, 0.1, TABLE_HALF.y * 2.0 - 0.3), 0.05, 1, ArtPalette.GRASS, ArtPalette.GRASS_TOP)
	for t: Array in [[0.6, -2.2, 0.5], [5.3, -2.1, 0.45], [6.0, -0.4, 0.4], [0.8, 2.4, 0.35]]:   # small bushes on the land
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.8, 1.0)), Vector3(t[0], LAND_TOP + float(t[2]) * 0.6, t[1])), t[2], 3, 8, ArtPalette.LEAF_LIGHT)
	return b.commit()


## The pond: a ring of round stones on the land and the dry mud inside with dark cracks.
func _pond_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.4
	b.add_cylinder(Transform3D(Basis(), POND_AT + Vector3.UP * 0.005), POND_RADIUS, POND_RADIUS, 0.03, 28, MUD, true, MUD_TOP)
	b.ao_min = 1.0
	for k in 7:   # the cracks: zigzags out from near the middle
		var a := TAU * k / 7.0 + 0.3
		var p := POND_AT + Vector3(cos(a), 0.0, sin(a)) * 0.25 + Vector3.UP * 0.04
		for s in 3:
			var turn := a + (0.35 if s % 2 == 0 else -0.35)
			var q := p + Vector3(cos(turn), 0.0, sin(turn)) * 0.42
			var mid := (p + q) * 0.5
			b.add_rounded_box(Transform3D(Basis(Vector3.UP, -turn), mid), Vector3(0.44, 0.012, 0.035), 0.0, 1, CRACK)
			p = q
	b.ao_min = 0.85
	b.ao_height = POND_DEPTH
	var stones := 22
	for k in stones:
		var a := TAU * k / stones
		var r := 0.2 + 0.05 * float(k % 3)
		var at := POND_AT + Vector3(cos(a), 0.0, sin(a)) * (POND_RADIUS + 0.08) + Vector3.UP * r * 0.75
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.1, 0.85, 1.0)), at), r, 3, 8, STONE if k % 2 == 0 else STONE_TOP)
	return b.commit()


## The pond's water: a flat disc (scaled and raised by show()).
func _water_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(), POND_RADIUS - 0.02, POND_RADIUS - 0.02, 0.05, 28, POND_WATER, true, POND_WATER_TOP)
	for k in 3:   # ripples
		var r := 0.35 + 0.42 * k
		var ring := 24
		for i in ring:
			if i % 2 == 1:
				continue
			var a0 := TAU * i / ring
			var a1 := TAU * (i + 1) / ring
			var p0 := Vector3(cos(a0) * r, 0.055, sin(a0) * r)
			var p1 := Vector3(cos(a1) * r, 0.055, sin(a1) * r)
			b.add_rounded_box(Transform3D(Basis(Vector3.UP, -(a0 + a1) * 0.5 + PI * 0.5), (p0 + p1) * 0.5), Vector3(p0.distance_to(p1), 0.008, 0.03), 0.0, 1, FOAM)
	return b.commit()


# --- the sun ---------------------------------------------------------------------------------------

## The sun at the origin: a faceted ball and `count` fat rays round it facing the camera, reaching
## `rays` past the ball.
static func sun_mesh(radius: float, rays: float, count: int, ball: Color, ray_color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), radius, 6, 14, ball)
	for i in count:
		var a := TAU * i / count + PI / count
		var out := Vector3(cos(a), sin(a), 0.0)
		var length := rays * (1.0 if i % 2 == 0 else 0.72)
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, out)), out * (radius + 0.06)), radius * 0.15, 0.0, length, 4, ray_color)
	return b.commit()


## Warm beams from the sun's underside down to the sea: long flat strips facing the camera.
func _beams_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in BEAMS:
		var from := SUN_AT + Vector3((i - 1) * 0.55, -STRONG_RADIUS * 0.9, 0.3)
		var to := Vector3(SUN_AT.x + (i - 1) * 1.5, SEA_TOP + 0.06, 0.6 + (i - 1) * 0.2)
		_strip(b, from, to, BEAM_WIDTH, BEAM_COLOR, 0.0)
	return b.commit()


## A flat strip from `from` to `to` facing the camera (+z), `width` wide, dashed with `dash` gaps (0:
## solid).
static func _strip(b: ArtMeshBuilder, from: Vector3, to: Vector3, width: float, color: Color, dash: float) -> void:
	var along := to - from
	var side := Vector3(-along.y, along.x, 0.0).normalized() * width * 0.5
	var pieces := 9 if dash > 0.0 else 1
	for k in pieces:
		if dash > 0.0 and k % 2 == 1:
			continue
		var a := from + along * (float(k) / pieces)
		var c := from + along * (float(k + 1) / pieces)
		b.add_triangle([a - side, c - side, c + side], [color, color, color], Vector3.BACK)
		b.add_triangle([a - side, c + side, a + side], [color, color, color], Vector3.BACK)


# --- the cloud, the rain and the vapour --------------------------------------------------------------

## The rain: drop columns from the cloud's underside down past the pond's bottom, rows RAIN_GAP apart
## (the node slides them down by up to one gap: an endless fall).
func _rain_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var top := CLOUD_AT.y - 0.5
	var rows := int(ceil((top - POND_AT.y) / RAIN_GAP)) + 1
	for col in RAIN_COLUMNS:
		var x := POND_AT.x + lerpf(-RAIN_SPREAD, RAIN_SPREAD, (col + 0.5) / RAIN_COLUMNS)
		var z := POND_AT.z + lerpf(-0.8, 0.8, fposmod(col * 0.618, 1.0))
		var offset := fposmod(col * 0.37, 1.0) * RAIN_GAP
		for row in rows:
			var y := top - offset - row * RAIN_GAP
			if y < POND_AT.y:
				continue
			_strip(b, Vector3(x, y, z), Vector3(x - 0.05, y - DROP_LENGTH, z), 0.07, DROP, 0.0)
	return b.commit()


## One wisp of vapour: a short wavy upright line facing the camera.
static func _wisp_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var steps := 8
	var prev := Vector3(0.0, -0.3, 0.0)
	for k in range(1, steps + 1):
		var t := float(k) / steps
		var p := Vector3(0.09 * sin(t * TAU * 1.25), -0.3 + 0.6 * t, 0.0)
		_strip(b, prev, p, 0.06, WISP_COLOR, 0.0)
		prev = p
	return b.commit()


# --- the day sign ------------------------------------------------------------------------------------

## The sign's two wooden posts standing on the table (world).
func _sign_posts_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = SIGN_AT.y
	for side: float in [-1.0, 1.0]:
		b.add_cylinder(Transform3D(Basis(), Vector3(SIGN_AT.x + side * DAY_BAR.x * 0.38, TABLE_TOP, SIGN_AT.z - 0.08)), 0.05, 0.04, SIGN_AT.y - TABLE_TOP, 6, ArtPalette.WOOD_GRAIN)
	return b.commit()


## The sign's wooden frame round the bar and its two ends (local to the sign, centred on the bar).
static func _sign_frame_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	WindowArt.add_frame(b, Rect2(Vector2(-DAY_BAR.x * 0.5 - 0.5, -DAY_BAR.y * 0.5 - 0.14), Vector2(DAY_BAR.x + 1.0, DAY_BAR.y + 0.28)), 0.1, 0.1, 0.025, 0.2)
	return b.commit()


## The bar's track, the sun at its left end and the moon at its right (local to the sign: bright,
## facing the camera).
static func _sign_face_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.0, 0.02)), Vector3(DAY_BAR.x, DAY_BAR.y, 0.03), DAY_BAR.y * 0.49, 3, DAY_TRACK)
	var left := Vector3(-DAY_BAR.x * 0.5 - 0.25, 0.0, 0.05)
	ArtKit.disc(b, left, DAY_BAR.y * 0.42, DAY_FILL_TOP, 14)
	for k in 8:
		var a := TAU * k / 8.0
		var d := Vector3(cos(a), sin(a), 0.0)
		_strip(b, left + d * DAY_BAR.y * 0.5, left + d * DAY_BAR.y * 0.68, 0.045, DAY_FILL, 0.0)
	var right := Vector3(DAY_BAR.x * 0.5 + 0.25, 0.0, 0.05)
	ArtKit.disc(b, right, DAY_BAR.y * 0.48, MOON, 14)
	ArtKit.disc(b, right + Vector3(DAY_BAR.y * 0.2, DAY_BAR.y * 0.1, 0.003), DAY_BAR.y * 0.4, WindowArt.FRAME_COLOR.darkened(0.15), 14)
	return b.commit()


## The bar's fill (local to the sign): the day's sunshine left, from the sun's end.
static func _day_fill_mesh(left: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	if left > 0.0:
		var h := DAY_BAR.y - 0.08
		var w := maxf(h, (DAY_BAR.x - 0.08) * left)
		b.add_rounded_box(Transform3D(Basis(), Vector3(-DAY_BAR.x * 0.5 + 0.04 + w * 0.5, 0.0, 0.04)), Vector3(w, h, 0.03), h * 0.49, 3, DAY_FILL, DAY_FILL_TOP)
	return b.commit()
