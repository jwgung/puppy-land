## The 바닷바람 lab's props (#93; apps/lab3d/docs/art-direction.md): meshes only, posed from the model by
## SeaBreezeLab._redraw(). A coast on Hutton Island: the land on the left, the sea on the right
## (LabWorld's shore at SHORE_X: the sand ends there and the island's own sea runs to the horizon).
## - the sun high over the land: a big bright ball with rays, the thing the child presses. While it is
##   pressed by day it swells a little and sunbeams reach down to the land; at night the moon stands in
##   its place (a crescent) and stars come out, the sky turns a deep blue and the coast darkens,
## - two big thermometers, one on the sand and one on a buoy in the sea: a white board, a glass tube and
##   a red column as high as the temperature (no number, no scale words: only tick marks),
## - the wind: fat arrows low over the shore drifting the way the wind blows (from the sea to the land
##   by day, from the land to the sea at night), longer, thicker and quicker the stronger it is, gone
##   when it is calm; over the warmer side an orange arrow rises (warm air goes up),
## - a pinwheel on the shore turning with the wind (its speed follows the wind),
## - a little fishing boat at the end of a wooden pier (it goes out on the night wind: SeaBreezeGame),
## - far out at sea the sailing boat with the piece on its deck (it comes in on a strong sea breeze),
## - the bread cat on the sand, watching the pinwheel.
## Visual only: no body, nothing the model or the mission reads.
class_name SeaBreezeProps
extends RefCounted

## The shore line (LabWorld's edge_x): land at x < SHORE_X, sea beyond.
const SHORE_X := 1.0
## The lab corner of the island (LabWorld's centre): far left, so its trees stand on the land.
const WORLD_CENTER := Vector3(-14.0, 0.0, -4.0)
## The sea's surface under the lab's ground when the island cannot say (LabWorld.SEA_DROP).
const SEA_Y := -0.6
## The sun (and the moon in its place) high over the sea, on the right of the sky where the screen's
## top band leaves room (the title, the card and the mission strip are on the left).
const SUN_AT := Vector3(6.6, 7.4, -3.0)
const SUN_RADIUS := 1.05
const SUN_SHADE := Color(1.0, 0.82, 0.6)
## The pressed sun swells by PRESS_SWELL and its rays turn at RAY_SPIN rad/s.
const PRESS_SWELL := 0.12
const RAY_SPIN := 0.8
## Sunbeams from the sun down to these points of the land (world, on the sand), shown while it shines.
const BEAMS := [Vector3(-4.0, 0.2, 0.2), Vector3(-1.6, 0.2, 1.6), Vector3(4.0, -0.3, 2.0)]
const BEAM_RADIUS := 0.07
const BEAM_COLOR := Color("fff0a0")
const MOON := Color("fff4c2")
const NIGHT_SKY := Color("1c2a62")
const STAR := Color("fff6d0")
## The coast at night: the island and the props darkened by these tints.
const NIGHT_TINT := Vector3(0.32, 0.38, 0.66)
## The thermometers: the land's on the sand, the sea's on a buoy. The tube's height and width, the
## board behind it (m), the bulb's radius.
const LAND_THERMO := Vector3(-4.6, 0.0, 1.4)
const SEA_THERMO := Vector3(5.4, 0.0, 1.0)
const THERMO_H := 2.3
const THERMO_W := 0.2
const BOARD := Vector2(0.62, 2.95)
const BULB := 0.24
const THERMO_FOOT := 0.5
const BOARD_COLOR := Color("fffaf0")
const BOARD_EDGE := Color("dcd0b8")
const GLASS := Color("dff1ff")
const MERCURY := Color("ff3b3b")
const MERCURY_TOP := Color("ff6a5a")
const TICK := Color("9fb0c8")
## The buoy under the sea's thermometer.
const BUOY_RADIUS := 0.55
## The wind's arrows: LANES of them (height, depth) and ARROWS_PER_LANE drifting along each from
## BAND_FROM to BAND_TO (x, centred on the shore), their length and thickness from MIN to MAX with the
## wind's strength, their drift speed (share of the band per second).
const LANES := [Vector2(1.5, 1.4), Vector2(2.9, -0.4)]
const ARROWS_PER_LANE := 3
const BAND_FROM := -4.6
const BAND_TO := 6.4
const ARROW_LENGTH := Vector2(1.8, 3.6)
const ARROW_THICK := Vector2(1.0, 1.8)
const DRIFT := Vector2(0.12, 0.42)
const CALM_SHARE := 0.05
const COOL_AIR := Color("eef8ff")
const COOL_AIR_TOP := Color("ffffff")
const WARM_AIR := Color("ff8a2a")
const WARM_AIR_TOP := Color("ffab5a")
## The rising warm air: over the land or over the sea, its foot and its length (m).
const RISE_LAND := Vector3(-3.4, 3.2, -1.0)
const RISE_SEA := Vector3(4.2, 2.6, -1.0)
const RISE_LENGTH := Vector2(1.6, 3.2)
## The pinwheel on the shore: its foot, its pole, its blades, the turn of its face towards the sea
## (rad: a real one faces the wind; this one also faces the camera) and its spin per m/s of wind.
const PINWHEEL_AT := Vector3(-1.4, 0.0, 2.0)
const POLE_H := 2.9
const BLADE := 1.15
const PINWHEEL_TURN := 0.75
const SPIN_PER_WIND := 1.6
const BLADE_COLORS := [Color("ff3b3b"), Color("ffc61a"), Color("2d7cf6"), Color("4fbf3b")]
## The pier (on the sand into the sea) and the fishing boat at its end, bow out to sea (+x).
const PIER_FROM := 0.2
const PIER_TO := 3.4
const PIER_Z := 3.1
const PIER_W := 0.9
const FISHING_AT := Vector3(3.0, 0.0, 4.4)
const FISHING_HULL := Color("2d7cf6")
const FISHING_ROOF := Color("ff5a4f")
## The sailing boat with the piece, far out (bow to the shore) and how big it is drawn.
const SAIL_AT := Vector3(10.5, 0.0, -2.6)
const SAIL_SIZE := 1.6
const SAIL_HULL := Color("ff7a1a")
## The boats bob by BOB m at BOB_SPEED rad/s.
const BOB := 0.06
const BOB_SPEED := 1.8
const CAT_AT := Vector3(-6.6, 0.0, 3.0)

var cat: CatActor
var sun: Node3D            # the sun's place (the ball and the moon under it)
var sun_ball: Node3D
var moon: Node3D
var stars: Node3D
var beams: Node3D
var pinwheel: Node3D       # the wheel (turns about its local z)
var fishing: Node3D        # the fishing boat (SeaBreezeGame moves it)
var sailing: Node3D        # the sailing boat (SeaBreezeGame moves it)
var land_fill: Node3D
var sea_fill: Node3D
var arrows: Array[Node3D] = []
var rise: Node3D
var lit_material: ShaderMaterial
var bright_material: ShaderMaterial
var sea_y := SEA_Y
## What is shown now (tests): the thermometers' fills (0..1), the wind (m/s, signed: + towards the
## land), the arrows' length, the pinwheel's spin (rad/s), night or day, the sun pressed.
var shown_land := 0.0
var shown_sea := 0.0
var shown_wind := 0.0
var shown_length := 0.0
var spin := 0.0
var shown_night := false
var shown_heating := false
## Extra spin the game adds for a while (a cheer: "바람개비가 빙글빙글!").
var spin_boost := 0.0
var _phase := 0.0
var _t := 0.0
var _environment: Environment
var _island_material: ShaderMaterial


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0, SHORE_X)
	for child in lab.get_children():
		if child is WorldEnvironment:
			_environment = (child as WorldEnvironment).environment
		elif child.name == "Island" and child is MeshInstance3D:
			var world: Variant = child.get_meta("world", null)
			if world is LabWorld:
				sea_y = (world as LabWorld).sea_y
			_island_material = ((child as MeshInstance3D).material_override as ShaderMaterial).duplicate()
			(child as MeshInstance3D).material_override = _island_material
	lit_material = ArtKit.lit_material().duplicate()
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var ground := ArtKit.instance(_ground_mesh(), lit_material)
	ground.name = "Shore"
	lab.add_child(ground)
	_build_sky(lab)
	_build_thermometers(lab)
	_build_wind(lab)
	_build_pinwheel(lab)
	fishing = Node3D.new()
	fishing.name = "FishingBoat"
	fishing.position = Vector3(FISHING_AT.x, sea_y, FISHING_AT.z)
	lab.add_child(fishing)
	fishing.add_child(ArtKit.instance(fishing_boat_mesh(), lit_material))
	sailing = Node3D.new()
	sailing.name = "SailingBoat"
	sailing.position = Vector3(SAIL_AT.x, sea_y, SAIL_AT.z)
	sailing.rotation = Vector3(0.0, -PI * 0.5, 0.0)   # bow (+z) towards the shore (-x)
	sailing.scale = Vector3.ONE * SAIL_SIZE
	lab.add_child(sailing)
	sailing.add_child(ArtKit.instance(BoatArt.mesh(SAIL_HULL), lit_material))
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = pinwheel
	cat.stand(CAT_AT)
	cat.advance(0.0)


## The sailing boat's deck (world) where the piece rides.
func deck_point() -> Vector3:
	return sailing.global_transform * Vector3(0.0, 0.62, 0.55) if sailing.is_inside_tree() else \
		Vector3(SAIL_AT.x - 0.55 * SAIL_SIZE, sea_y + 0.62 * SAIL_SIZE, SAIL_AT.z)


## Poses everything for the model now: the land's and the sea's temperatures (°C), the wind (m/s,
## + from the sea), its share of the strongest (0..1), night, the sun pressed by day.
func show(land: float, sea: float, wind: float, share: float, night: bool, heating: bool) -> void:
	shown_land = SeaBreezeModel.fill_of(land)
	shown_sea = SeaBreezeModel.fill_of(sea)
	shown_wind = wind
	_fill(land_fill, shown_land)
	_fill(sea_fill, shown_sea)
	shown_length = lerpf(ARROW_LENGTH.x, ARROW_LENGTH.y, share) if share >= CALM_SHARE else 0.0
	spin = wind * SPIN_PER_WIND
	_pose_rise(land - sea, share)
	_pose_arrows()
	if night != shown_night:
		shown_night = night
		_show_night(night)
	shown_heating = heating
	beams.visible = heating
	sun_ball.scale = Vector3.ONE * (1.0 + (PRESS_SWELL if heating else 0.0))


## The wind's arrows drift, the pinwheel turns, the boats bob, the sun's rays turn (`delta` s).
func advance(delta: float) -> void:
	_t += delta
	var share := clampf((shown_length - ARROW_LENGTH.x) / (ARROW_LENGTH.y - ARROW_LENGTH.x), 0.0, 1.0)
	if shown_length > 0.0:
		_phase = fposmod(_phase + delta * lerpf(DRIFT.x, DRIFT.y, share), 1.0)
	_pose_arrows()
	pinwheel.rotation.z -= (spin + spin_boost) * delta
	for boat: Node3D in [fishing, sailing]:
		boat.position.y = sea_y + BOB * sin(_t * BOB_SPEED + boat.position.x)
	if sun_ball.get_child_count() > 1:
		(sun_ball.get_child(1) as Node3D).rotation.z += delta * (RAY_SPIN * 3.0 if shown_heating else RAY_SPIN)


# --- the sky -----------------------------------------------------------------------------------------

func _build_sky(lab: Node3D) -> void:
	sun = Node3D.new()
	sun.name = "Sun"
	sun.position = SUN_AT
	lab.add_child(sun)
	sun_ball = Node3D.new()
	sun_ball.name = "Ball"
	sun.add_child(sun_ball)
	var ball := ArtKit.instance(_sun_ball_mesh(), DayNightProps.lit_towards(Vector3(-0.35, 0.45, 0.82), Color.WHITE, SUN_SHADE, 0.03))
	ball.name = "SunBall"
	sun_ball.add_child(ball)
	var rays := ArtKit.instance(_rays_mesh(), bright_material)
	rays.name = "Rays"
	sun_ball.add_child(rays)
	moon = ArtKit.instance(_moon_mesh(), bright_material)
	moon.name = "Moon"
	moon.visible = false
	sun.add_child(moon)
	stars = ArtKit.instance(_stars_mesh(), bright_material)
	stars.name = "Stars"
	stars.visible = false
	lab.add_child(stars)
	beams = Node3D.new()
	beams.name = "Beams"
	beams.visible = false
	lab.add_child(beams)
	var link := ArtKit.link_mesh(BEAM_RADIUS, BEAM_COLOR)
	for to: Vector3 in BEAMS:
		var beam := ArtKit.instance(link, bright_material)
		beams.add_child(beam)
		var from := SUN_AT + (to - SUN_AT).normalized() * SUN_RADIUS * 1.9
		ArtKit.stretch_link(beam, from, to)


## Day or night: the sun or the moon, the stars, the sky's colour, the coast darker at night.
func _show_night(night: bool) -> void:
	sun_ball.visible = not night
	moon.visible = night
	stars.visible = night
	if _environment != null:
		_environment.background_color = NIGHT_SKY if night else ArtPalette.SKY
	var tint := NIGHT_TINT if night else Vector3.ONE
	if _island_material != null:
		_island_material.set_shader_parameter("own_tint", tint)
	lit_material.set_shader_parameter("tint", Color(tint.x, tint.y, tint.z) if night else Color.WHITE)


static func _sun_ball_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), SUN_RADIUS, 6, 14, ArtPalette.YELLOW_TOP)
	return b.commit()


## Short fat rays round the sun in the plane facing the camera.
static func _rays_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in 12:
		var a := TAU * i / 12.0 + PI / 12.0
		var out := Vector3(cos(a), sin(a), 0.0)
		var length := SUN_RADIUS * (0.55 if i % 2 == 0 else 0.4)
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, out)), out * (SUN_RADIUS + 0.1)), SUN_RADIUS * 0.15, 0.0, length, 4, ArtPalette.YELLOW)
	return b.commit()


## A crescent moon facing the camera: the bright disc with the night sky's disc over its right side.
static func _moon_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	ArtKit.disc(b, Vector3.ZERO, SUN_RADIUS * 0.95, MOON, 28)
	ArtKit.disc(b, Vector3(SUN_RADIUS * 0.42, SUN_RADIUS * 0.22, 0.01), SUN_RADIUS * 0.8, NIGHT_SKY, 28)
	return b.commit()


## Star dots high over the coast (a fixed golden-angle scatter), facing the camera.
static func _stars_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in 34:
		var u := fposmod(i * 0.618034, 1.0)
		var v := fposmod(i * 0.414214 + 0.13, 1.0)
		var p := Vector3(lerpf(-16.0, 18.0, u), lerpf(5.0, 12.5, v), -14.0 + 2.0 * fposmod(i * 0.3, 1.0))
		var r := 0.09 if i % 4 == 0 else 0.055
		ArtKit.disc(b, p, r, STAR, 6)
	return b.commit()


# --- the ground: the sand by the shore, the pier --------------------------------------------------

func _ground_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.5
	# The pier: planks on posts from the sand out over the sea.
	var top := 0.32
	var planks := 9
	for i in planks:
		var x := lerpf(PIER_FROM, PIER_TO, (i + 0.5) / planks)
		var w := (PIER_TO - PIER_FROM) / planks * 0.86
		b.add_rounded_box(Transform3D(Basis(), Vector3(x, top, PIER_Z)), Vector3(w, 0.08, PIER_W), 0.02, 1, ArtPalette.WOOD if i % 2 == 0 else ArtPalette.WOOD.lightened(0.08))
	for x: float in [PIER_FROM + 0.5, (PIER_FROM + PIER_TO) * 0.5 + 0.4, PIER_TO - 0.15]:
		for side: float in [-1.0, 1.0]:
			var post_bottom := minf(0.0, sea_y - 0.6) if x > SHORE_X else 0.0
			b.add_cylinder(Transform3D(Basis(), Vector3(x, post_bottom, PIER_Z + side * PIER_W * 0.42)), 0.08, 0.08, top - post_bottom + 0.06, 6, ArtPalette.WOOD_GRAIN)
	# The buoy under the sea's thermometer: red and white bands.
	var buoy := Vector3(SEA_THERMO.x, sea_y - 0.2, SEA_THERMO.z)
	b.add_cylinder(Transform3D(Basis(), buoy), BUOY_RADIUS, BUOY_RADIUS * 0.9, 0.42, 14, ArtPalette.RED, true, ArtPalette.RED_TOP)
	b.add_cylinder(Transform3D(Basis(), buoy + Vector3(0.0, 0.42, 0.0)), BUOY_RADIUS * 0.9, BUOY_RADIUS * 0.75, 0.2, 14, ArtPalette.WHITE, true, ArtPalette.WHITE)
	# A little post under the land's thermometer.
	b.add_cylinder(Transform3D(Basis(), LAND_THERMO + Vector3(0.0, 0.0, -0.05)), 0.32, 0.26, 0.12, 10, ArtPalette.ROCK, true, ArtPalette.ROCK.lightened(0.1))
	return b.commit()


# --- the thermometers -------------------------------------------------------------------------------

func _build_thermometers(lab: Node3D) -> void:
	var sea_foot := Vector3(SEA_THERMO.x, sea_y + 0.42, SEA_THERMO.z)
	land_fill = _thermometer(lab, "LandThermometer", LAND_THERMO + Vector3(0.0, 0.12, 0.0))
	sea_fill = _thermometer(lab, "SeaThermometer", sea_foot)


## A thermometer standing at `foot` (its board's bottom); returns the red column's node (scaled in y).
func _thermometer(lab: Node3D, thermo_name: String, foot: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = thermo_name
	node.position = foot
	lab.add_child(node)
	node.add_child(ArtKit.instance(thermometer_mesh(), bright_material))
	var column := Node3D.new()
	column.name = "Column"
	column.position = Vector3(0.0, THERMO_FOOT + BULB * 0.6, 0.13)
	node.add_child(column)
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.5, 0.0)), Vector3(THERMO_W * 0.62, 1.0, 0.02), 0.0, 1, MERCURY)
	column.add_child(ArtKit.instance(b.commit(), bright_material))
	return column


## The board, the glass tube with its tick marks and the red bulb (foot at the origin, facing +z).
static func thermometer_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, BOARD.y * 0.5, 0.0)), Vector3(BOARD.x + 0.08, BOARD.y + 0.08, 0.1), 0.05, 2, BOARD_EDGE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, BOARD.y * 0.5, 0.03)), Vector3(BOARD.x, BOARD.y, 0.1), 0.05, 2, BOARD_COLOR)
	var tube_h := THERMO_H
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, THERMO_FOOT + tube_h * 0.5, 0.1)), Vector3(THERMO_W, tube_h, 0.02), 0.0, 1, GLASS)
	for k in 9:
		var y := THERMO_FOOT + BULB * 0.6 + (tube_h - BULB * 0.8) * (k + 0.5) / 9.0
		var w := 0.12 if k % 2 == 0 else 0.07
		b.add_rounded_box(Transform3D(Basis(), Vector3(-THERMO_W * 0.5 - 0.04 - w * 0.5, y, 0.1)), Vector3(w, 0.03, 0.02), 0.0, 1, TICK)
	ArtKit.disc(b, Vector3(0.0, THERMO_FOOT, 0.16), BULB, MERCURY, 20)
	ArtKit.disc(b, Vector3(-BULB * 0.3, THERMO_FOOT + BULB * 0.3, 0.18), BULB * 0.25, MERCURY_TOP, 10)
	return b.commit()


## The red column `fill` (0..1) of the tube.
func _fill(column: Node3D, fill: float) -> void:
	column.scale = Vector3(1.0, maxf(0.001, fill * (THERMO_H - BULB * 0.8)), 1.0)


# --- the wind ----------------------------------------------------------------------------------------

func _build_wind(lab: Node3D) -> void:
	var cool := arrow_mesh(COOL_AIR, COOL_AIR_TOP)
	for lane: Vector2 in LANES:
		for k in ARROWS_PER_LANE:
			var arrow := ArtKit.instance(cool, lit_material)
			arrow.name = "Wind%d" % arrows.size()
			lab.add_child(arrow)
			arrows.append(arrow)
	rise = ArtKit.instance(arrow_mesh(WARM_AIR, WARM_AIR_TOP), lit_material)
	rise.name = "WarmAir"
	lab.add_child(rise)


## An arrow one metre long along +x from the origin: a round shaft and a cone head (scaled by its node).
static func arrow_mesh(color: Color, top: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var along := Basis(Vector3.BACK, -PI * 0.5)   # the cylinder's +y along +x
	b.add_cylinder(Transform3D(along, Vector3(0.0, 0.0, 0.0)), 0.16, 0.16, 0.64, 12, color, true, top)
	b.add_cylinder(Transform3D(along, Vector3(0.62, 0.0, 0.0)), 0.4, 0.0, 0.38, 14, top, true, color)
	return b.commit()


## The surface wind's arrows along their lanes: each at its share of the band (drifting with _phase),
## pointing the way the wind blows, growing in at the band's start and shrinking out at its end.
func _pose_arrows() -> void:
	var calm := shown_length <= 0.0
	var dir := 1.0 if shown_wind < 0.0 else -1.0   # + wind blows from the sea (right) to the land (left)
	var share := clampf((shown_length - ARROW_LENGTH.x) / (ARROW_LENGTH.y - ARROW_LENGTH.x), 0.0, 1.0)
	var thick := lerpf(ARROW_THICK.x, ARROW_THICK.y, share)
	for i in arrows.size():
		var arrow := arrows[i]
		arrow.visible = not calm
		if calm:
			continue
		var lane: Vector2 = LANES[i / ARROWS_PER_LANE]
		var u := fposmod(_phase + float(i % ARROWS_PER_LANE) / ARROWS_PER_LANE + 0.17 * (i / ARROWS_PER_LANE), 1.0)
		var grow := sin(PI * u)
		var start := lerpf(BAND_TO, BAND_FROM, u) if dir < 0.0 else lerpf(BAND_FROM, BAND_TO, u)
		arrow.position = Vector3(start - dir * shown_length * 0.5, lane.x, lane.y)
		var k := maxf(grow, 0.05)
		arrow.basis = Basis(Vector3.UP, 0.0 if dir > 0.0 else PI) * Basis.from_scale(Vector3(shown_length * k, thick * k, thick * k))


## The warm air rising over the warmer side (`difference`: land minus sea, °C).
func _pose_rise(difference: float, share: float) -> void:
	rise.visible = share >= CALM_SHARE
	if not rise.visible:
		return
	var foot := RISE_LAND if difference > 0.0 else RISE_SEA
	var length := lerpf(RISE_LENGTH.x, RISE_LENGTH.y, share)
	var thick := lerpf(ARROW_THICK.x, ARROW_THICK.y, share)
	rise.position = foot
	rise.basis = Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3(length, thick, thick))


# --- the pinwheel ------------------------------------------------------------------------------------

func _build_pinwheel(lab: Node3D) -> void:
	var stand := Node3D.new()
	stand.name = "Pinwheel"
	stand.position = PINWHEEL_AT
	stand.rotation = Vector3(0.0, PINWHEEL_TURN, 0.0)
	lab.add_child(stand)
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = POLE_H
	b.add_cylinder(Transform3D(), 0.09, 0.075, POLE_H, 8, ArtPalette.WOOD, true, ArtPalette.WOOD.lightened(0.1))
	stand.add_child(ArtKit.instance(b.commit(), lit_material))
	pinwheel = ArtKit.instance(pinwheel_mesh(), lit_material)
	pinwheel.name = "Wheel"
	pinwheel.position = Vector3(0.0, POLE_H, 0.12)
	stand.add_child(pinwheel)


## Four curled blades round a hub, facing +z (it turns about its z).
static func pinwheel_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in 4:
		var a := TAU * i / 4.0
		var out := Vector3(cos(a), sin(a), 0.0)
		var side := Vector3(-sin(a), cos(a), 0.0)
		var c: Color = BLADE_COLORS[i]
		# A blade: a triangle from the hub out to its tip, its curled half tipped towards the camera.
		var tip := out * BLADE
		var root := side * BLADE * 0.06
		var curl := out * BLADE * 0.55 + side * BLADE * 0.5 + Vector3(0.0, 0.0, 0.18)
		b.add_triangle([Vector3(0.0, 0.0, 0.02), tip, curl], [c, c, c.lightened(0.25)], Vector3.BACK)
		b.add_triangle([Vector3(0.0, 0.0, 0.02), curl, tip], [c.darkened(0.15), c.darkened(0.15), c], Vector3.FORWARD)
		b.add_triangle([root, Vector3.ZERO, tip], [c.darkened(0.1), c.darkened(0.1), c.darkened(0.1)], Vector3.BACK)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, 0.0, 0.06)), 0.1, 3, 8, ArtPalette.WHITE)
	return b.commit()


# --- the fishing boat ---------------------------------------------------------------------------------

## A little fishing boat (bow +x, waterline y 0): a round hull with a cream band, a white wheelhouse with
## a red roof, a short mast with a lantern and a flag.
static func fishing_boat_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 1.6
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.25, 0.5, 0.55)), Vector3(0.0, 0.05, 0.0)), 1.0, 5, 16, FISHING_HULL)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.2, 0.18, 0.53)), Vector3(0.0, 0.42, 0.0)), 1.0, 3, 16, BoatArt.CREAM)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.5, 0.0)), Vector3(2.0, 0.06, 0.8), 0.02, 1, ArtPalette.WOOD)
	b.add_rounded_box(Transform3D(Basis(), Vector3(-0.35, 0.85, 0.0)), Vector3(0.7, 0.6, 0.62), 0.05, 1, ArtPalette.WHITE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(-0.35, 1.2, 0.0)), Vector3(0.86, 0.1, 0.76), 0.04, 1, FISHING_ROOF)
	b.ao_min = 1.0
	for z: float in [-0.315, 0.315]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(-0.3, 0.92, z)), Vector3(0.24, 0.2, 0.02), 0.0, 1, BoatArt.WINDOW)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.45, 0.5, 0.0)), 0.04, 0.035, 1.3, 6, ArtPalette.WOOD_GRAIN)
	b.add_sphere(Transform3D(Basis(), Vector3(0.45, 1.5, 0.0)), 0.09, 3, 8, ArtPalette.YELLOW)
	b.add_triangle([Vector3(0.45, 1.78, 0.0), Vector3(0.45, 1.56, 0.0), Vector3(0.9, 1.67, 0.0)], [ArtPalette.RED, ArtPalette.RED, ArtPalette.RED_TOP], Vector3.BACK)
	b.add_triangle([Vector3(0.45, 1.56, 0.0), Vector3(0.45, 1.78, 0.0), Vector3(0.9, 1.67, 0.0)], [ArtPalette.RED, ArtPalette.RED, ArtPalette.RED_TOP], Vector3.FORWARD)
	return b.commit()
