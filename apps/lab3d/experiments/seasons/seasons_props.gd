## The 계절 lab's props (#87; apps/lab3d/docs/art-direction.md): meshes only, posed from the model by
## SeasonsLab._redraw(). A small "space" stage on Hutton Island's hill, like the 낮과 밤 lab's:
## - a deep blue round stage (ArtPalette.SPACE) with star dots,
## - the sun in the middle on its pedestal, always bright, with rays,
## - the Earth's path round it: a ring of light dashes at the Earth's height, with an orange arrow on
##   its far side the way the Earth really goes (counter-clockwise seen from above the north pole),
## - the Earth on the path: the 낮과 밤 globe (DayNightProps.globe_mesh, the fox's house with its bright
##   flag on Hutton Island, turned to face the camera so the island is always in view), lit by the sun
##   from where it is (the half towards the sun is day), and its axis as a thick rod with the red north
##   end. Tilted, the axis leans the same way all year (towards the screen's left: the June solstice
##   is on the right of the sun, where the north end leans towards it; the December solstice on the
##   left); upright, it stands straight,
## - the yard window, high on the right: the sky over Hutton Island at noon. The sun stands as high as
##   the noon sun (a dashed arc is its day's path: wide and high in summer, short and low in winter),
##   a thick bar beside the picture fills with the sun's height, and the day bar under it is as long
##   as the day (a sun at its day end, a moon at its night end). The yard turns white with snow when
##   the noon sun is low. Pictures and bars only: no number of degrees or hours (the user),
## - the bread cat on the stage, watching the Earth.
## Visual only: no body, nothing the model or the mission reads.
class_name SeasonsProps
extends RefCounted

const SUN_CENTER := Vector3(0.0, 2.7, -1.6)
const SUN_RADIUS := 1.05
const SUN_SHADE := Color(1.0, 0.82, 0.6)
## The Earth's path round the sun (m) and the globe on it (m).
const ORBIT_RADIUS := 5.2
const GLOBE_RADIUS := 1.7
## The house on the globe drawn this much bigger than the 낮과 밤 globe's (its flag reads from afar).
const HOUSE_GROW := 2.0
## The house's meridian turned this far from the camera towards the screen's right about the axis:
## the house sits near the globe's right rim, its flag standing out against the sky.
const HOUSE_TURN_DEG := 50.0
## The stage: a low round podium (it covers the lab corner's rocks and flowers under it) round the
## sun. The lab's corner of the island is centred at WORLD_CENTER, where its trees stand clear of
## the podium and the window (ArtKit.TREES round it).
const STAGE_CENTER := Vector3(0.0, 0.0, -1.2)
const STAGE_RADIUS := 8.0
const STAGE_TOP := 0.7
const WORLD_CENTER := Vector3(-1.0, 0.0, -6.0)
## The path's dashes: how many, their width and thickness; the arrow on the far side (deg of the path, as
## path_point: 90 = straight behind the sun) and its look.
const DASHES := 72
const DASH_WIDTH := 0.09
const DASH_THICK := 0.06
const PATH_COLOR := Color("fff1b0")
const ARROW_FROM_DEG := 62.0
const ARROW_TO_DEG := 118.0
const ARROW_TUBE := 0.085
const ARROW_COLOR := Color("ff7a1a")
const ARROW_TOP := Color("ff9440")
## The axis rod beyond the poles (m) and its radius.
const ROD_OUT := 0.75
const ROD_RADIUS := 0.075
const NIGHT := Color("2a3a86")   # the globe's night side: a dusk blue (the lands still read)
const CAT_AT := Vector3(-5.2, STAGE_TOP, 3.6)
## The yard window: its centre (world), the picture's size (m), the frame, the height bar beside the
## picture and the day bar under it (m).
const WINDOW_CENTER := Vector3(9.8, 6.9, -4.8)
const WINDOW_TURN_DEG := -24.0
## The whole window drawn this much bigger than its picture's metres (the bars read on a phone).
const WINDOW_SCALE := 1.3
const WINDOW_SIZE := Vector2(3.2, 1.9)
const FRAME := 0.14
const FRAME_DEPTH := 0.14
const FRAME_COLOR := Color("c98d4f")
const FRAME_TOP := Color("dba468")
const HEIGHT_BAR := Vector2(0.28, 1.9)
const DAY_BAR := Vector2(3.2, 0.36)
const BAR_GAP := 0.14
const BAR_TRACK := Color("23306e")
const DAY_FILL := Color("ffc61a")
const DAY_FILL_TOP := Color("ffe36a")
const HEIGHT_FILL := Color("ff8a2a")
const SKY_TOP := Color("4aa8f5")
const SKY_LOW := Color("c9ecff")
const SKY_COLD_TOP := Color("7fb0e0")    # a low winter sun: a paler, colder sky
const SKY_COLD_LOW := Color("e8f2fb")
const SNOW := Color("f6fbff")
const SNOW_SHADE := Color("dfe9f5")
## The yard is snowy below SNOW_FROM_DEG of noon sun, green above SNOW_TO_DEG (between them it melts).
const SNOW_FROM_DEG := 33.0
const SNOW_TO_DEG := 42.0
const YARD_SHARE := 0.22
const PICTURE_SUN := 0.2

var cat: CatActor
var earth: Node3D        # on the path (the globe and the axis under it)
var globe: Node3D        # the globe and the house (leans with the tilt; never spins)
var axis: Node3D         # the rod (leans with the tilt)
var house: Node3D        # the fox's house on the globe
var shadow: Node3D       # the Earth's soft shadow on the stage under it
var window: Node3D
var globe_material: ShaderMaterial
var bright_material: ShaderMaterial
var _sky: MeshInstance3D
var _sun_disc: Node3D
var _day_path: MeshInstance3D
var _yard: MeshInstance3D
var _height_fill: MeshInstance3D
var _day_fill: MeshInstance3D
var _window_key := Vector3.INF
## What the window shows now (tests): the sun's height and the day as shares of their bars (0..1),
## the snow on the yard (0..1).
var shown_height := 0.0
var shown_day := 0.0
var shown_snow := 0.0


## The Earth's centre on its path at orbit angle `orbit` (deg, SunModel's: 0 = the March equinox, in
## front of the sun; 90 the June solstice, on the right; 270 the December solstice, on the left).
static func earth_center(orbit: float) -> Vector3:
	return SUN_CENTER + path_point(orbit - 90.0, ORBIT_RADIUS)


## A point of a circle round the sun's height (deg from +x, counter-clockwise seen from above).
static func path_point(deg: float, radius: float) -> Vector3:
	var a := deg_to_rad(deg)
	return Vector3(cos(a), 0.0, -sin(a)) * radius


## The orbit angle (deg, 0..360) of a world point on the path's plane (the knob's place).
static func orbit_of(point: Vector3) -> float:
	var d := point - SUN_CENTER
	return fposmod(rad_to_deg(atan2(-d.z, d.x)) + 90.0, 360.0)


## The north end's direction for an axis tilt of `tilt` deg (leaning towards -x).
static func north(tilt: float) -> Vector3:
	var e := deg_to_rad(tilt)
	return Vector3(-sin(e), cos(e), 0.0)


## The globe's basis: its own frame (north +y, the house's meridian +x: DayNightProps.globe_mesh) put
## on the leaning axis with the house's meridian towards the camera (+z), turned HOUSE_TURN_DEG
## to the right about the axis (it never spins: the window shows the noon).
static func globe_basis(tilt: float) -> Basis:
	var n := north(tilt)
	var front := Vector3.BACK
	return Basis(n, deg_to_rad(HOUSE_TURN_DEG)) * Basis(front, n, front.cross(n))


func build(lab: Node3D, latitude: float) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	globe_material = DayNightProps.lit_towards(Vector3.RIGHT, ArtPalette.LIGHT, NIGHT)
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var stage := ArtKit.instance(_stage_mesh())
	stage.name = "Stage"
	lab.add_child(stage)
	var sun := ArtKit.instance(sun_mesh(SUN_RADIUS), DayNightProps.lit_towards(Vector3(-0.35, 0.45, 0.82), Color.WHITE, SUN_SHADE, 0.03))
	sun.name = "Sun"
	sun.position = SUN_CENTER
	lab.add_child(sun)
	var path := ArtKit.instance(_path_mesh(), bright_material)
	path.name = "Path"
	lab.add_child(path)
	shadow = Node3D.new()
	shadow.name = "EarthShadow"
	lab.add_child(shadow)
	var blob := ArtKit.builder()
	blob.ao_min = 1.0
	blob.add_cylinder(Transform3D(Basis(), Vector3(0.0, STAGE_TOP + 0.014, 0.0)), GLOBE_RADIUS * 0.55, GLOBE_RADIUS * 0.55, 0.004, 20, ArtPalette.SPACE.darkened(0.2))
	shadow.add_child(ArtKit.instance(blob.commit()))
	earth = Node3D.new()
	earth.name = "Earth"
	lab.add_child(earth)
	globe = Node3D.new()
	globe.name = "Globe"
	earth.add_child(globe)
	var grow := GLOBE_RADIUS / DayNightProps.GLOBE_RADIUS
	var ball := ArtKit.instance(DayNightProps.globe_mesh(latitude), globe_material)
	ball.name = "Ball"
	ball.scale = Vector3.ONE * grow
	globe.add_child(ball)
	house = Node3D.new()
	house.name = "House"
	var at := DayNightProps.ground_frame(DayNightProps.house_direction(latitude), GLOBE_RADIUS)
	house.transform = Transform3D(at.basis.scaled(Vector3.ONE * grow * HOUSE_GROW), at.origin)
	globe.add_child(house)
	var home := ArtKit.instance(DayNightProps.house_mesh(), globe_material)
	home.name = "Home"
	house.add_child(home)
	var flag := ArtKit.instance(DayNightProps.flag_mesh(), bright_material)
	flag.name = "Flag"
	house.add_child(flag)
	var lights := ArtKit.instance(DayNightProps.house_windows_mesh(), bright_material)
	lights.name = "Windows"
	house.add_child(lights)
	axis = Node3D.new()
	axis.name = "Axis"
	earth.add_child(axis)
	var rod := ArtKit.instance(_axis_mesh())
	rod.name = "Rod"
	axis.add_child(rod)
	_build_window(lab)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = earth
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses the Earth on its path (orbit, tilt) lit from the sun, and the window's noon sky: the noon
## sun's height share (0..1 of straight overhead), the day's share of the whole day, the noon sun's
## altitude (deg: the snow on the yard).
func show(orbit: float, tilt: float, height_share: float, day_share: float, noon_altitude: float) -> void:
	var at := earth_center(orbit)
	earth.position = at
	shadow.position = Vector3(at.x, 0.0, at.z)
	globe.basis = globe_basis(tilt)
	axis.basis = globe.basis
	globe_material.set_shader_parameter("sun_dir", (SUN_CENTER - at).normalized())
	_show_window(height_share, day_share, noon_altitude)


# --- the stage, the sun and the path --------------------------------------------------------------

func _stage_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.95
	b.ao_height = 0.2
	b.add_cylinder(Transform3D(Basis(), STAGE_CENTER + Vector3(0.0, -0.05, 0.0)), STAGE_RADIUS, STAGE_RADIUS, STAGE_TOP + 0.05, 40, ArtPalette.SPACE.darkened(0.25), true, ArtPalette.SPACE_TOP)
	b.ao_min = 1.0
	for i in 90:   # star dots: a fixed golden-angle scatter, white and yellow
		var r := STAGE_RADIUS * 0.95 * sqrt((i + 0.5) / 90.0)
		var a := i * 2.399963
		var color := ArtPalette.YELLOW if i % 5 == 0 else ArtPalette.WHITE
		var s := 0.08 if i % 5 == 0 else 0.05
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, a), STAGE_CENTER + Vector3(cos(a) * r, STAGE_TOP + 0.012, sin(a) * r)), Vector3(s, 0.012, s), 0.0, 1, color)
	b.ao_min = 0.85
	b.ao_height = 0.6
	var foot := Vector3(SUN_CENTER.x, STAGE_TOP, SUN_CENTER.z)
	b.add_cylinder(Transform3D(Basis(), foot), 0.6, 0.45, 0.14, 10, ArtPalette.BLUE_DARK)
	b.add_cylinder(Transform3D(Basis(), foot + Vector3(0.0, 0.12, 0.0)), 0.14, 0.14, SUN_CENTER.y - SUN_RADIUS - 0.05 - STAGE_TOP, 8, ArtPalette.BLUE)
	_add_window_stand(b)
	return b.commit()


## The sun at the origin: a faceted ball and short fat rays round it, in the plane facing the camera.
static func sun_mesh(radius: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), radius, 6, 12, ArtPalette.YELLOW_TOP)
	for i in 12:
		var a := TAU * i / 12.0 + PI / 12.0
		var out := Vector3(cos(a), sin(a), 0.0)
		var length := radius * (0.52 if i % 2 == 0 else 0.38)
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, out)), out * (radius + 0.08)), radius * 0.14, 0.0, length, 4, ArtPalette.YELLOW)
	return b.commit()


## The path: light dashes round the sun at the Earth's height and the orange arrow on its far side.
func _path_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in DASHES:
		if i % 2 == 1:
			continue
		var deg := 360.0 * (i + 0.5) / DASHES
		var p := SUN_CENTER + path_point(deg, ORBIT_RADIUS)
		# Basis(UP, a) turns x out from the sun and z along the path (path_point's tangent).
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, deg_to_rad(deg)), p), Vector3(DASH_WIDTH, DASH_THICK, ORBIT_RADIUS * TAU / DASHES * 0.9), 0.02, 1, PATH_COLOR)
	DayNightProps.add_turn_arrow(b, SUN_CENTER, ORBIT_RADIUS, ARROW_TUBE, ARROW_FROM_DEG, ARROW_TO_DEG, ARROW_COLOR, ARROW_TOP)
	return b.commit()


# --- the axis -------------------------------------------------------------------------------------

## The rod through the poles along the axis node's y (red north end, steel south end).
func _axis_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := GLOBE_RADIUS + ROD_OUT
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, -half, 0.0)), ROD_RADIUS, ROD_RADIUS, half * 2.0, 8, ArtPalette.STEEL_SHINE)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, half, 0.0)), ROD_RADIUS * 2.2, 3, 8, ArtPalette.RED)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, -half, 0.0)), ROD_RADIUS * 1.6, 3, 6, ArtPalette.STEEL)
	return b.commit()


# --- the yard window ------------------------------------------------------------------------------

func _add_window_stand(b: ArtMeshBuilder) -> void:
	b.ao_min = 0.8
	b.ao_height = 0.4
	var turn := Basis(Vector3.UP, deg_to_rad(WINDOW_TURN_DEG))
	var bottom := WINDOW_CENTER.y - (WINDOW_SIZE.y * 0.5 + FRAME + DAY_BAR.y + BAR_GAP * 2.0) * WINDOW_SCALE
	for side: float in [-1.0, 1.0]:
		var foot := WINDOW_CENTER + turn * Vector3(side * WINDOW_SIZE.x * 0.34 * WINDOW_SCALE, 0.0, -0.1 * WINDOW_SCALE)
		foot.y = 0.0
		b.add_cylinder(Transform3D(Basis(), foot), 0.07, 0.055, bottom + 0.05, 6, ArtPalette.WOOD_GRAIN)
		b.add_rounded_box(Transform3D(turn, foot + Vector3(0.0, 0.04, 0.0)), Vector3(0.42, 0.08, 0.3), 0.02, 1, ArtPalette.WOOD_GRAIN)


## The window's frame (the picture, the height bar on its left, the day bar under it), the sky, the
## sun with its day's path, the yard, the bars' fills.
func _build_window(lab: Node3D) -> void:
	window = Node3D.new()
	window.name = "YardWindow"
	window.position = WINDOW_CENTER
	window.rotation = Vector3(0.0, deg_to_rad(WINDOW_TURN_DEG), 0.0)
	window.scale = Vector3.ONE * WINDOW_SCALE
	lab.add_child(window)
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var inner := _inner_rect()
	var w := inner.size.x + FRAME * 2.0
	var h := inner.size.y + FRAME * 2.0
	var c := inner.get_center()
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(c.x, c.y + side * (h - FRAME) * 0.5, 0.0)), Vector3(w, FRAME, FRAME_DEPTH), 0.03, 1, FRAME_COLOR, FRAME_TOP)
		b.add_rounded_box(Transform3D(Basis(), Vector3(c.x + side * (w - FRAME) * 0.5, c.y, 0.0)), Vector3(FRAME, h - FRAME * 2.0 + 0.002, FRAME_DEPTH), 0.03, 1, FRAME_COLOR, FRAME_TOP)
	# The board behind (it shows between the picture and the bars) and the bars' dividers.
	b.add_rounded_box(Transform3D(Basis(), Vector3(c.x, c.y, -FRAME_DEPTH * 0.5 + 0.01)), Vector3(w - 0.02, h - 0.02, 0.02), 0.0, 1, FRAME_COLOR.darkened(0.15))
	var frame := ArtKit.instance(b.commit())
	frame.name = "Frame"
	window.add_child(frame)
	var tracks := ArtKit.builder()
	tracks.ao_min = 1.0
	_pill(tracks, _height_rect(), 0.012, BAR_TRACK)
	_pill(tracks, _day_rect(), 0.012, BAR_TRACK)
	# The day bar's ends: a sun on its left (day), a moon on its right (night).
	var day := _day_rect()
	_disc(tracks, Vector3(day.position.x - 0.0, day.get_center().y, 0.05), DAY_BAR.y * 0.62, DAY_FILL_TOP)
	var moon_at := Vector3(day.end.x, day.get_center().y, 0.05)
	_disc(tracks, moon_at, DAY_BAR.y * 0.55, Color("f4f1d0"))
	_disc(tracks, moon_at + Vector3(DAY_BAR.y * 0.22, DAY_BAR.y * 0.12, 0.003), DAY_BAR.y * 0.45, FRAME_COLOR.darkened(0.15))
	# The height bar's top: a little sun (straight overhead).
	var hb := _height_rect()
	_disc(tracks, Vector3(hb.get_center().x, hb.end.y + 0.02, 0.05), HEIGHT_BAR.x * 0.75, DAY_FILL_TOP)
	var track := ArtKit.instance(tracks.commit(), bright_material)
	track.name = "BarTracks"
	window.add_child(track)
	_sky = MeshInstance3D.new()
	_sky.name = "Sky"
	_sky.material_override = bright_material
	window.add_child(_sky)
	_day_path = MeshInstance3D.new()
	_day_path.name = "DayPath"
	_day_path.material_override = bright_material
	window.add_child(_day_path)
	var disc := ArtKit.builder()
	disc.ao_min = 1.0
	_disc(disc, Vector3.ZERO, PICTURE_SUN * 1.45, ArtPalette.YELLOW.lightened(0.5), 20)
	_disc(disc, Vector3(0.0, 0.0, 0.004), PICTURE_SUN, ArtPalette.YELLOW, 20)
	_sun_disc = ArtKit.instance(disc.commit(), bright_material)
	_sun_disc.name = "SkySun"
	window.add_child(_sun_disc)
	_yard = MeshInstance3D.new()
	_yard.name = "Yard"
	_yard.material_override = bright_material
	window.add_child(_yard)
	_height_fill = MeshInstance3D.new()
	_height_fill.name = "HeightFill"
	_height_fill.material_override = bright_material
	window.add_child(_height_fill)
	_day_fill = MeshInstance3D.new()
	_day_fill.name = "DayFill"
	_day_fill.material_override = bright_material
	window.add_child(_day_fill)


## The picture (window local, x across, y up): the sky and the yard.
func _picture_rect() -> Rect2:
	return Rect2(-WINDOW_SIZE * 0.5, WINDOW_SIZE)


## The height bar left of the picture.
func _height_rect() -> Rect2:
	var p := _picture_rect()
	return Rect2(p.position.x - BAR_GAP - HEIGHT_BAR.x, p.position.y + 0.06, HEIGHT_BAR.x, p.size.y - 0.32)


## The day bar under the picture.
func _day_rect() -> Rect2:
	var p := _picture_rect()
	return Rect2(p.position.x + 0.3, p.position.y - BAR_GAP - DAY_BAR.y, p.size.x - 0.6, DAY_BAR.y)


## Everything inside the frame.
func _inner_rect() -> Rect2:
	return _picture_rect().merge(_height_rect().grow(0.08)).merge(_day_rect().grow(0.1))


func _horizon_y() -> float:
	return -WINDOW_SIZE.y * 0.5 + WINDOW_SIZE.y * YARD_SHARE


## The window for the noon sun at `height` (0..1), the day `day` (0..1), the noon altitude (deg).
func _show_window(height: float, day: float, noon_altitude: float) -> void:
	var key := Vector3(snappedf(height, 0.001), snappedf(day, 0.001), snappedf(noon_altitude, 0.1))
	if key == _window_key:
		return
	_window_key = key
	shown_height = height
	shown_day = day
	shown_snow = clampf((SNOW_TO_DEG - noon_altitude) / (SNOW_TO_DEG - SNOW_FROM_DEG), 0.0, 1.0)
	var p := _picture_rect()
	var hy := _horizon_y()
	_sky.mesh = _sky_mesh(SKY_TOP.lerp(SKY_COLD_TOP, shown_snow), SKY_LOW.lerp(SKY_COLD_LOW, shown_snow))
	# The noon sun over the middle of the yard (the window looks south), as high as its share of the
	# sky (the top of the picture is straight overhead).
	var top := p.end.y - PICTURE_SUN * 1.2
	var sun_y := lerpf(hy, top, height)
	_sun_disc.position = Vector3(0.0, sun_y, 0.03)
	_day_path.mesh = _day_path_mesh(sun_y, day)
	_yard.mesh = _yard_mesh(shown_snow)
	var hb := _height_rect()
	var fill := ArtKit.builder()
	fill.ao_min = 1.0
	_pill(fill, Rect2(hb.position, Vector2(hb.size.x, maxf(hb.size.x, hb.size.y * height))).grow(-0.035), 0.02, HEIGHT_FILL)
	_height_fill.mesh = fill.commit()
	var db := _day_rect()
	var dayfill := ArtKit.builder()
	dayfill.ao_min = 1.0
	_pill(dayfill, Rect2(db.position, Vector2(maxf(db.size.y, db.size.x * day), db.size.y)).grow(-0.04), 0.02, DAY_FILL)
	_day_fill.mesh = dayfill.commit()


## The sun's day path in the picture: a dashed arc from the horizon up through the noon sun and down
## again, as wide as the day is long (a long summer day reaches past the picture's edges).
func _day_path_mesh(sun_y: float, day: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var hy := _horizon_y()
	var half := WINDOW_SIZE.x * 0.5 * lerpf(0.35, 1.35, clampf((day - 0.3) / 0.4, 0.0, 1.0))
	var rise := sun_y - hy
	var steps := 28
	for k in steps:
		if k % 2 == 1:
			continue
		var u0 := lerpf(-1.0, 1.0, float(k) / steps)
		var u1 := lerpf(-1.0, 1.0, float(k + 1) / steps)
		var a := Vector3(u0 * half, hy + rise * (1.0 - u0 * u0), 0.02)
		var c := Vector3(u1 * half, hy + rise * (1.0 - u1 * u1), 0.02)
		if absf(a.x) > WINDOW_SIZE.x * 0.5 - 0.02 or absf(c.x) > WINDOW_SIZE.x * 0.5 - 0.02:
			continue
		var along := (c - a).normalized()
		var side := Vector3(-along.y, along.x, 0.0) * 0.022
		var col := Color("fff6c8")
		b.add_triangle([a - side, c - side, c + side], [col, col, col], Vector3.BACK)
		b.add_triangle([a - side, c + side, a + side], [col, col, col], Vector3.BACK)
	return b.commit()


## The yard along the bottom of the picture: a hill (green, or white with snow), the fox's house, a
## tree, all in front of the sky.
func _yard_mesh(snow: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := WINDOW_SIZE * 0.5
	var y0 := -half.y
	var hy := _horizon_y()
	var low := ArtPalette.GRASS.lerp(SNOW_SHADE, snow)
	var high := ArtPalette.GRASS_TOP.lerp(SNOW, snow)
	var steps := 20
	for k in steps:
		var x0 := lerpf(-half.x, half.x, float(k) / steps)
		var x1 := lerpf(-half.x, half.x, float(k + 1) / steps)
		var t0 := hy + 0.04 * sin(x0 * 2.6) + 0.02 * cos(x0 * 6.0)
		var t1 := hy + 0.04 * sin(x1 * 2.6) + 0.02 * cos(x1 * 6.0)
		b.add_triangle([Vector3(x0, y0, 0.04), Vector3(x1, y0, 0.04), Vector3(x1, t1, 0.04)], [low, low, high], Vector3.BACK)
		b.add_triangle([Vector3(x0, y0, 0.04), Vector3(x1, t1, 0.04), Vector3(x0, t0, 0.04)], [low, high, high], Vector3.BACK)
	var hx := half.x * 0.55
	var roof := DayNightProps.ROOF.lerp(SNOW, snow * 0.6)
	b.add_rounded_box(Transform3D(Basis(), Vector3(hx, hy + 0.13, 0.05)), Vector3(0.38, 0.28, 0.01), 0.0, 1, DayNightProps.WALL)
	b.add_triangle([Vector3(hx - 0.25, hy + 0.26, 0.056), Vector3(hx + 0.25, hy + 0.26, 0.056), Vector3(hx, hy + 0.46, 0.056)], [roof, roof, roof.lightened(0.15)], Vector3.BACK)
	b.add_rounded_box(Transform3D(Basis(), Vector3(hx, hy + 0.06, 0.057)), Vector3(0.09, 0.14, 0.004), 0.0, 1, DayNightProps.DOOR)
	var tx := -half.x * 0.6
	b.add_rounded_box(Transform3D(Basis(), Vector3(tx, hy + 0.09, 0.045)), Vector3(0.04, 0.2, 0.01), 0.0, 1, ArtPalette.TRUNK)
	_disc(b, Vector3(tx, hy + 0.27, 0.05), 0.15, ArtPalette.LEAF_LIGHT.lerp(SNOW, snow * 0.7))
	return b.commit()


static func _sky_mesh(top: Color, low: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := WINDOW_SIZE * 0.5
	var corners := [Vector3(-half.x, -half.y, 0.0), Vector3(half.x, -half.y, 0.0), Vector3(half.x, half.y, 0.0), Vector3(-half.x, half.y, 0.0)]
	b.add_triangle([corners[0], corners[1], corners[2]], [low, low, top], Vector3.BACK)
	b.add_triangle([corners[0], corners[2], corners[3]], [low, top, top], Vector3.BACK)
	return b.commit()


## A flat rounded bar (a pill) filling `r` (window local) at depth `z`.
static func _pill(b: ArtMeshBuilder, r: Rect2, z: float, color: Color) -> void:
	var radius := minf(r.size.x, r.size.y) * 0.5
	var inner := r.grow(-radius)
	var poly := PackedVector2Array()
	var corners := [[inner.end, 0.0], [Vector2(inner.position.x, inner.end.y), 0.5 * PI], [inner.position, PI], [Vector2(inner.end.x, inner.position.y), 1.5 * PI]]
	for corner: Array in corners:
		for k in 7:
			var a: float = corner[1] + PI * 0.5 * k / 6.0
			poly.append((corner[0] as Vector2) + Vector2(cos(a), sin(a)) * radius)
	var c := r.get_center()
	for i in poly.size():
		var p0 := poly[i]
		var p1 := poly[(i + 1) % poly.size()]
		b.add_triangle([Vector3(c.x, c.y, z), Vector3(p0.x, p0.y, z), Vector3(p1.x, p1.y, z)], [color, color, color], Vector3.BACK)


static func _disc(b: ArtMeshBuilder, c: Vector3, r: float, color: Color, sides := 14) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		b.add_triangle([c, c + Vector3(cos(a0), sin(a0), 0.0) * r, c + Vector3(cos(a1), sin(a1), 0.0) * r], [color, color, color], Vector3.BACK)
