## The 녹으면 사라질까? lab's props (#157, 2026-11-17; the approved mockup of #157-#159, "2-1. #157 소금"):
## meshes only, posed from the model by DissolvingLab._redraw(). Curie Island's kitchen (KitchenSet) and on
## the table, per stage's table (DissolvingModel's site):
## - CUP (stage 1): a glass of water (GlassCup) with a spoonful of salt at its bottom and a spoon in it,
##   the thing the child moves: a finger going round and round over the glass stirs (the spoon turns round
##   the glass with it). The salt at the bottom shrinks as it dissolves and the water goes cloudy white
##   while it dissolves, clear once it is all gone. Left of the glass the salt dish, further left the
##   bread cat on its crates watching; right the dark sun tray (empty) and the seawater bucket (just
##   standing there until stage 3);
## - SCALE (stage 2): the glass and the dish stand on a needle scale (a grey box, a round dial in front:
##   no number, ticks only; a pale ghost needle where the needle stood before the stirring and the red
##   needle now: they stay one over the other). No tray (the scale is wide); the bucket stays at the
##   table's right end (the piece is in it);
## - TRAY (stage 3 and a finished round): the glass (clear) on the left, the seawater bucket in the middle
##   (the thing the child moves now: dragged right over the tray it tips and, let go there, pours), the
##   tray on the right and behind it the time sign (TimeSign: the time runs once the seawater is on the
##   tray, the scene goes dark at night: SceneNight). On the tray the water goes down day by day and a
##   white salt crust comes out when it is nearly gone.
## Where things stand per table: cup_point(), dish_point(), cat_point(), bucket_home(), TRAY_AT, SIGN_AT.
## Visual only: no body, nothing the model or the mission reads.
class_name DissolvingProps
extends RefCounted

## The glass (as diffusion's) and where it stands per table (x on the table's top), its z.
const CUP_BOTTOM := 0.5
const CUP_TOP := 0.6
const CUP_HEIGHT := 1.3
const CUP_FILL := 1.05
const CUP_Z := 0.35
const CUP_X := {0: 0.1, 1: 0.35, 2: -0.6}
## The salt: its white, the spoonful's mound at the glass's bottom (radius, height at full, m), the
## cloud's colour while it dissolves.
const SALT := Color("f7f9fb")
const MOUND := Vector2(0.3, 0.16)
const SALT_HAZE := Color("ffffff")
const HAZE_ALPHA := 0.7
## The salt dish left of the glass (x from the glass), its radius, its blue rim.
const DISH_FROM_CUP := -0.85
const DISH_R := 0.3
const DISH_RIM := Color("7aa7d6")
## The spoon: its bowl's way round the glass's axis (radius, height over the glass's foot), its handle's
## length and lean outwards (deg), its metal.
const SPOON_RING := 0.22
const SPOON_UP := 0.3
const SPOON_HANDLE := 1.25
const SPOON_LEAN := 18.0
const STEEL := Color("cfd8df")
const STEEL_DARK := Color("aeb8c2")
## Where a finger stirs: the middle of the circle (over the glass's axis, this high over its foot) and
## the knob's place on it at rest (m from the middle, towards +x).
const STIR_UP := 1.75
const STIR_RING := 0.45
## The scale (stage 2): its box (size), its plate on top, the dial on its front (radius), the needle's
## sweep (deg either side of up for an empty .. a full scale) and the full reading (g).
const SCALE_SIZE := Vector3(2.2, 0.32, 1.1)
const SCALE_BODY := Color("8e99a6")
const SCALE_PLATE := Color("c3ccd5")
const DIAL_R := 0.3
const DIAL := Color("fff8e6")
const DIAL_RIM := Color("6b4423")
const NEEDLE := Color("e34b3f")
const GHOST := Color("9aa5b1")
const NEEDLE_SWEEP := 75.0
const SCALE_FULL_G := 1000.0
## The sun tray (stage 3): its middle on the table, its size, the water's colour and how high it stands
## when full (m), the crust's flakes.
const TRAY_AT := Vector3(1.75, KitchenSet.TABLE_TOP, 0.35)
const TRAY_SIZE := Vector3(1.8, 0.1, 1.0)
const TRAY := Color("2f3540")
const TRAY_RIM := Color("141820")
const SEA := Color(0.29, 0.64, 0.92, 0.85)
const FLAKES := 34
## The seawater bucket: its size (bottom radius, top radius, height), wood and bands, where it stands per
## table, how far right it may be dragged (over the tray: it pours there), its tip over the tray (deg).
const BUCKET := Vector3(0.28, 0.36, 0.72)
const BUCKET_WOOD := Color("a86b3c")
const BUCKET_BAND := Color("6b4423")
const BUCKET_X := {0: 2.75, 2: 0.45}
const BUCKET_Z := 0.4
const POUR_X := 1.15
const TIP_DEG := 55.0
const POUR_S := 1.0
## The time sign behind the tray (its bar's middle) and the bread cat: how far left of the glass it
## stands (per table) and how high its crates lift it.
const SIGN_AT := Vector3(1.55, 2.35, -0.55)
const CAT_FROM_CUP := {0: -1.55, 1: -2.25, 2: -1.2}
const CAT_STAND := 1.08

var cat: CatActor
var cat_stand: CatCrates
var cup: GlassCup
var mound: MeshInstance3D
var dish: Node3D
var spoon: Node3D
var scale_box: Node3D
var needle: Node3D
var ghost: Node3D
var tray: Node3D
var tray_water: MeshInstance3D
var flakes: MultiMeshInstance3D
var bucket: Node3D
var bucket_water: MeshInstance3D
var pour_stream: MeshInstance3D
var sign: TimeSign
var night := SceneNight.new()
## What is shown now (tests): the table, the spoon's angle (rad round the glass), the salt at the bottom
## and the cloud (0..1), the needle and the ghost (deg from up), the tray's water and crust (0..1), the
## bucket's tip (deg) and place (world), the night (0..1).
var shown_site := -1.0
var shown_spoon := 0.0
var shown_bottom := 1.0
var shown_haze := 0.0
var shown_needle := 0.0
var shown_ghost := 0.0
var shown_water := 0.0
var shown_crust := 0.0
var shown_tip := 0.0
var shown_night := 0.0
var _pour_at := -10.0
var _poured := false
var _t := 0.0


func build(lab: Node3D) -> void:
	KitchenSet.build(lab)
	night.attach(lab)
	cup = GlassCup.new(CUP_BOTTOM, CUP_TOP, CUP_HEIGHT, CUP_FILL)
	cup.name = "Cup"
	lab.add_child(cup)
	mound = ArtKit.instance(_mound_mesh())
	mound.name = "SaltMound"
	mound.position = Vector3(0.0, 0.07, 0.0)
	cup.add_child(mound)
	spoon = Node3D.new()
	spoon.name = "Spoon"
	cup.add_child(spoon)
	spoon.add_child(ArtKit.instance(_spoon_mesh()))
	dish = Node3D.new()
	dish.name = "SaltDish"
	lab.add_child(dish)
	dish.add_child(ArtKit.instance(_dish_mesh()))
	scale_box = Node3D.new()
	scale_box.name = "Scale"
	lab.add_child(scale_box)
	scale_box.add_child(ArtKit.instance(_scale_mesh()))
	var bright := DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	var dial := ArtKit.instance(_dial_mesh(), bright)
	dial.name = "Dial"
	dial.position = dial_point()
	scale_box.add_child(dial)
	ghost = ArtKit.instance(_needle_mesh(GHOST, 0.03), bright)
	ghost.name = "GhostNeedle"
	ghost.position = dial_point() + Vector3(0.0, 0.0, 0.01)
	scale_box.add_child(ghost)
	needle = ArtKit.instance(_needle_mesh(NEEDLE, 0.04), bright)
	needle.name = "Needle"
	needle.position = dial_point() + Vector3(0.0, 0.0, 0.02)
	scale_box.add_child(needle)
	tray = Node3D.new()
	tray.name = "SunTray"
	tray.position = TRAY_AT
	lab.add_child(tray)
	tray.add_child(ArtKit.instance(_tray_mesh()))
	var sea_material := StandardMaterial3D.new()
	sea_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sea_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sea_material.vertex_color_use_as_albedo = true
	tray_water = ArtKit.instance(_tray_water_mesh(), sea_material)
	tray_water.name = "TrayWater"
	tray.add_child(tray_water)
	flakes = MultiMeshInstance3D.new()
	flakes.name = "SaltCrust"
	flakes.multimesh = MultiMesh.new()
	flakes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	flakes.multimesh.mesh = _flake_mesh()
	flakes.multimesh.instance_count = FLAKES
	flakes.material_override = ArtKit.lit_material()
	flakes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tray.add_child(flakes)
	bucket = Node3D.new()
	bucket.name = "Bucket"
	lab.add_child(bucket)
	var tipper := Node3D.new()
	tipper.name = "Tip"
	tipper.position = Vector3(BUCKET.y, 0.0, 0.0)   # it tips over its right foot
	bucket.add_child(tipper)
	var body := ArtKit.instance(_bucket_mesh())
	body.position = Vector3(-BUCKET.y, 0.0, 0.0)
	tipper.add_child(body)
	bucket_water = ArtKit.instance(_bucket_water_mesh())
	bucket_water.name = "BucketWater"
	bucket_water.position = Vector3(-BUCKET.y, 0.0, 0.0)
	tipper.add_child(bucket_water)
	pour_stream = ArtKit.instance(_stream_mesh(), sea_material)
	pour_stream.name = "PourStream"
	pour_stream.visible = false
	lab.add_child(pour_stream)
	sign = TimeSign.new(SIGN_AT.y - KitchenSet.TABLE_TOP)
	sign.position = SIGN_AT
	lab.add_child(sign)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = cup
	var side := maxf(cat.look.footprint.x, cat.look.footprint.y)
	cat_stand = CatCrates.new(Vector2(side, side))
	lab.add_child(cat_stand)


## The table's top under things on table `site` (the scale's plate on the SCALE table).
static func top_y(site: float) -> float:
	return KitchenSet.TABLE_TOP + (SCALE_SIZE.y + 0.04 if site == DissolvingModel.SCALE else 0.0)


## Where the glass stands (its foot, world) on table `site`.
static func cup_point(site: float) -> Vector3:
	return Vector3(float(CUP_X.get(int(site), 0.0)), top_y(site), CUP_Z)


## Where the salt dish stands (world) on table `site`.
static func dish_point(site: float) -> Vector3:
	return cup_point(site) + Vector3(DISH_FROM_CUP, 0.0, -0.05)


## The middle of the circle a finger stirs on (world) over the glass on table `site`.
static func stir_center(site: float) -> Vector3:
	return cup_point(site) + Vector3.UP * STIR_UP


## The scale's middle on the table (its foot) and its dial's middle (local to the scale).
static func scale_point() -> Vector3:
	return KitchenSet.table_point(0.0, CUP_Z)


static func dial_point() -> Vector3:
	return Vector3(0.0, SCALE_SIZE.y * 0.5, SCALE_SIZE.z * 0.5 + 0.03)


## Where the bucket stands (its foot's middle, world) on table `site` (none on the scale's).
static func bucket_home(site: float) -> Vector3:
	return KitchenSet.table_point(float(BUCKET_X.get(int(site), BUCKET_X[0])), BUCKET_Z)


## The bucket is over the tray (dragged that far right): it tips and, let go, pours.
static func over_tray(x: float) -> bool:
	return x >= POUR_X


## Where the bread cat stands (its base on its crates, world) on table `site`.
static func cat_point(site: float) -> Vector3:
	return Vector3(cup_point(site).x + float(CAT_FROM_CUP.get(int(site), -1.4)), KitchenSet.TABLE_TOP + CAT_STAND, CUP_Z - 0.1)


## The needle's angle (deg from up, clockwise to the right) for a reading of `grams`.
static func needle_deg(grams: float) -> float:
	return lerpf(-NEEDLE_SWEEP, NEEDLE_SWEEP, clampf(grams / SCALE_FULL_G, 0.0, 1.0))


## Poses everything for the model now: the table, the spoon's angle (rad), the salt at the bottom and
## the cloud (0..1), the scale's reading and the reading before (g), the tray's water and crust (0..1),
## poured, the bucket's place along its drag (world x; NAN: at home) and the clock.
func show(site: float, spoon_angle: float, bottom: float, dissolved: float, grams: float, before: float,
		water: float, crust_share: float, poured: bool, bucket_x: float, clock: FastClock) -> void:
	if site != shown_site:
		shown_site = site
		_place_site(site)
	shown_spoon = spoon_angle
	spoon.rotation.y = -spoon_angle
	spoon.position = Vector3(cos(spoon_angle), 0.0, sin(spoon_angle)) * SPOON_RING + Vector3.UP * SPOON_UP
	shown_bottom = clampf(bottom, 0.0, 1.0)
	mound.visible = shown_bottom > 0.01 and site != DissolvingModel.TRAY
	mound.scale = Vector3(lerpf(0.35, 1.0, sqrt(shown_bottom)), maxf(shown_bottom, 0.05), lerpf(0.35, 1.0, sqrt(shown_bottom)))
	# Cloudy while it dissolves, clear once it is all gone (and before the stirring starts).
	shown_haze = sin(PI * clampf(dissolved, 0.0, 1.0)) if site != DissolvingModel.TRAY else 0.0
	cup.show_spread(shown_haze, SALT_HAZE)
	SoftCloud.set_look(cup.cloud_material, SALT_HAZE, HAZE_ALPHA * shown_haze)
	cup.water_material.albedo_color = Color.WHITE
	shown_needle = needle_deg(grams)
	shown_ghost = needle_deg(before)
	needle.rotation.z = -deg_to_rad(shown_needle)
	ghost.rotation.z = -deg_to_rad(shown_ghost)
	shown_water = water if poured else 0.0
	shown_crust = crust_share if poured else 0.0
	tray_water.visible = shown_water > 0.0
	tray_water.scale = Vector3(1.0, maxf(shown_water, 0.05), 1.0)
	_place_flakes()
	if poured and not _poured:
		_pour_at = _t
	_poured = poured
	bucket_water.visible = not poured
	if site == DissolvingModel.TRAY and not is_nan(bucket_x):
		bucket.position = Vector3(bucket_x, KitchenSet.TABLE_TOP, BUCKET_Z)
	else:
		bucket.position = bucket_home(site)
	_tip_bucket()
	shown_night = clock.night() if site == DissolvingModel.TRAY else 0.0
	night.set_amount(shown_night)
	sign.show_clock(clock)


## The things of table `site` where they stand on it.
func _place_site(site: float) -> void:
	var on_scale := site == DissolvingModel.SCALE
	cup.position = cup_point(site)
	dish.position = dish_point(site)
	dish.visible = site != DissolvingModel.TRAY
	scale_box.visible = on_scale
	scale_box.position = scale_point()
	spoon.visible = site != DissolvingModel.TRAY
	tray.visible = not on_scale
	bucket.visible = true   # (the piece is in it: on every table)
	sign.visible = site == DissolvingModel.TRAY
	cat.stand(cat_point(site))
	cat.advance(0.0)
	cat_stand.fit(cat, KitchenSet.TABLE_TOP)


## The bucket tips over its right foot while it is over the tray (dragged) and pours for POUR_S after it
## was let go there, then stands back up empty at home.
func _tip_bucket() -> void:
	var tip := 0.0
	var since := _t - _pour_at
	if _poured and since < POUR_S:
		tip = TIP_DEG * sin(PI * clampf(since / POUR_S, 0.0, 1.0))
	elif not _poured and over_tray(bucket.position.x) and shown_site == DissolvingModel.TRAY:
		tip = TIP_DEG * 0.45
	shown_tip = tip
	(bucket.get_child(0) as Node3D).rotation.z = -deg_to_rad(tip)
	pour_stream.visible = _poured and since < POUR_S * 0.85 and since > POUR_S * 0.1
	if pour_stream.visible:
		pour_stream.position = TRAY_AT + Vector3(-TRAY_SIZE.x * 0.25, 0.0, 0.0)


## The crust's flakes on the tray (their size the crust's share).
func _place_flakes() -> void:
	flakes.visible = shown_crust > 0.0
	for i in FLAKES:
		var u := fposmod(i * 0.618034, 1.0)
		var v := fposmod(i * 0.414214 + 0.3, 1.0)
		var at := Vector3((u - 0.5) * (TRAY_SIZE.x - 0.25), TRAY_SIZE.y * 0.55, (v - 0.5) * (TRAY_SIZE.z - 0.2))
		var r := (0.07 + 0.05 * fposmod(i * 0.37, 1.0)) * maxf(shown_crust, 0.001)
		flakes.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, i * 1.7).scaled(Vector3(r, r * 0.6, r * 0.8)), at))


## The bucket is still pouring (let go over the tray POUR_S ago at most).
func pouring() -> bool:
	return _poured and _t - _pour_at < POUR_S


## The clock of the props: the glass's cloud sways, the bucket pours.
func advance(delta: float) -> void:
	_t += delta
	cup.advance(delta)
	_tip_bucket()


# --- meshes -------------------------------------------------------------------------------------------

## The spoonful at the glass's bottom: a low white mound (unit height: the node scales it).
static func _mound_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 1.0
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(MOUND.x, 1.0, MOUND.x * 0.8)), Vector3.ZERO), 1.0, 4, 14, SALT)
	return b.commit()


## The spoon: its bowl (the node's origin) in the water and its handle up and out over the rim (+x).
static func _spoon_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.3, 0.45, 1.0)), Vector3.ZERO), 0.11, 3, 10, STEEL)
	var lean := Basis(Vector3.BACK, -deg_to_rad(SPOON_LEAN))
	b.add_cylinder(Transform3D(lean, Vector3(0.06, 0.02, 0.0)), 0.035, 0.03, SPOON_HANDLE, 8, STEEL_DARK, true, STEEL)
	return b.commit()


## The salt dish: a little white bowl with a blue rim and a heap of salt in it.
static func _dish_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.3
	b.add_cylinder(Transform3D(), DISH_R * 0.6, DISH_R, 0.16, 16, Color.WHITE, true, Color("eef3f8"))
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.14, 0.0)), DISH_R + 0.01, DISH_R + 0.02, 0.04, 16, DISH_RIM)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.45, 1.0)), Vector3(0.0, 0.14, 0.0)), DISH_R * 0.8, 3, 12, SALT)
	return b.commit()


## The scale: a grey box with a light plate on top (local: its foot's middle at the origin).
static func _scale_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = SCALE_SIZE.y
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SCALE_SIZE.y * 0.5, 0.0)), SCALE_SIZE, 0.06, 2, SCALE_BODY, SCALE_PLATE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SCALE_SIZE.y + 0.02, 0.0)), Vector3(SCALE_SIZE.x + 0.1, 0.04, SCALE_SIZE.z + 0.06), 0.02, 1, SCALE_PLATE)
	return b.commit()


## The dial: a cream disc in a brown ring with seven ticks round its top (no number).
static func _dial_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	ArtKit.disc(b, Vector3.ZERO, DIAL_R, DIAL_RIM, 24)
	ArtKit.disc(b, Vector3(0.0, 0.0, 0.004), DIAL_R * 0.84, DIAL, 24)
	for k in 7:
		var a := deg_to_rad(90.0 - NEEDLE_SWEEP + NEEDLE_SWEEP * 2.0 * k / 6.0)
		var d := Vector3(cos(a), sin(a), 0.0)
		var from := d * DIAL_R * 0.62
		var to := d * DIAL_R * 0.78
		var side := Vector3(-d.y, d.x, 0.0) * 0.012
		var c := Color("a08a6a")
		b.add_triangle([from - side + Vector3(0, 0, 0.008), to - side + Vector3(0, 0, 0.008), to + side + Vector3(0, 0, 0.008)], [c, c, c], Vector3.BACK)
		b.add_triangle([from - side + Vector3(0, 0, 0.008), to + side + Vector3(0, 0, 0.008), from + side + Vector3(0, 0, 0.008)], [c, c, c], Vector3.BACK)
	ArtKit.disc(b, Vector3(0.0, 0.0, 0.03), 0.035, Color("3a2a1c"), 12)
	return b.commit()


## A needle from the dial's middle straight up (the node turns it), `width` wide.
static func _needle_mesh(color: Color, width: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var tip := Vector3(0.0, DIAL_R * 0.72, 0.0)
	var side := Vector3(width * 0.5, 0.0, 0.0)
	b.add_triangle([-side, side, tip], [color, color, color], Vector3.BACK)
	b.add_triangle([-side, Vector3(0.0, -DIAL_R * 0.12, 0.0), side], [color, color, color], Vector3.BACK)
	return b.commit()


## The sun tray: a wide shallow dark tray (local: its foot's middle at the origin).
static func _tray_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = TRAY_SIZE.y
	var s := TRAY_SIZE
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.02, 0.0)), Vector3(s.x, 0.04, s.z), 0.02, 1, TRAY_RIM, TRAY)
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(side * (s.x - 0.06) * 0.5, s.y * 0.5, 0.0)), Vector3(0.06, s.y, s.z), 0.015, 1, TRAY_RIM, TRAY)
		b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, s.y * 0.5, side * (s.z - 0.06) * 0.5)), Vector3(s.x, s.y, 0.06), 0.015, 1, TRAY_RIM, TRAY)
	return b.commit()


## The tray's water: a flat blue sheet over its bottom (unit depth up to the rim: the node scales y).
static func _tray_water_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var s := TRAY_SIZE
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.04 + (s.y - 0.06) * 0.5, 0.0)), Vector3(s.x - 0.12, s.y - 0.06, s.z - 0.12), 0.0, 1, SEA, SEA.lightened(0.2))
	return b.commit()


## A salt flake (a flat white lump, unit size).
static func _flake_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), 1.0, 2, 6, SALT)
	return b.commit()


## The wooden bucket (its foot's middle at the origin): staves, two dark bands.
static func _bucket_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = BUCKET.z
	b.add_cylinder(Transform3D(), BUCKET.x, BUCKET.y, BUCKET.z, 14, BUCKET_WOOD, true, BUCKET_BAND)
	for k: float in [0.22, 0.78]:
		var r := lerpf(BUCKET.x, BUCKET.y, k) + 0.012
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, BUCKET.z * k - 0.035, 0.0)), r, r, 0.07, 14, BUCKET_BAND)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, BUCKET.z - 0.03, 0.0)), BUCKET.y + 0.02, BUCKET.y + 0.02, 0.05, 14, BUCKET_BAND)
	return b.commit()


## The seawater in the bucket: a blue disc just under its rim.
static func _bucket_water_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, BUCKET.z - 0.1, 0.0)), BUCKET.y - 0.03, BUCKET.y - 0.03, 0.05, 14, Color("2f86d6"), true, Color("4aa3ea"))
	return b.commit()


## The pouring stream: a blue ribbon from over the tray's left half down onto it (facing the camera).
static func _stream_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var c := Color(0.29, 0.64, 0.92, 0.9)
	var prev := Vector3(-0.35, 0.95, 0.0)
	for k in range(1, 9):
		var u := k / 8.0
		var p := Vector3(-0.35 + 0.35 * u, 0.95 * (1.0 - u * u) + 0.06, 0.0)
		var along := p - prev
		var side := Vector3(-along.y, along.x, 0.0).normalized() * 0.07
		b.add_triangle([prev - side, p - side, p + side], [c, c, c], Vector3.BACK)
		b.add_triangle([prev - side, p + side, prev + side], [c, c, c], Vector3.BACK)
		prev = p
	return b.commit()
