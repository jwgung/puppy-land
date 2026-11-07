## The 구름과 이슬 piece game (#92; hutton-lines.md 5: "저기 산꼭대기 바위에 조각이 보여! 그런데 먼지에 덮여서
## 잘 안 보여." / "3단계에서 구름의 비가 바위 먼지를 씻어 조각이 반짝이고, 산 위 꽃이 다시 고개를 든다."): on
## the summit a grey rock holds the piece, half covered by brown dust; round it the flowers hang their
## heads. Stages 1 and 2 (dew on the cup): the bread cat cheers and the piece glints once under the
## dust. Stage 3 (the cloud): a cloud cap settles on the summit and rain falls from it; the dust
## washes away, the flowers lift their heads, the piece shines and jumps off the summit onto the hill
## beside the cat, growing to the round's size on the way. A finished spot shows the cap, the flowers
## up and no dust. Visual only (LabGame).
class_name DewCloudGame
extends LabGame

## The piece's rock on the summit (local to the game: its foot at the summit's top), the piece on
## its front, the dust over it.
const ROCK_R := 0.62
const ROCK := Color("9aa3b5")
const ROCK_TOP := Color("b8c0cf")
const PIECE_AT := Vector3(0.0, 0.62, 0.42)
const PIECE_HIDDEN := 0.36
const DUST := Color("b49a78")
const DUST_LIGHT := Color("cdb796")
## The wilted flowers round the rock: how many, their stem, their heads' colours, the droop (rad).
const FLOWERS := 6
const STEM := 0.42
const FLOWER_COLORS := [Color("ff4fa3"), Color("ffc61a"), Color("ffffff"), Color("ff7a1a")]
const DROOP := 1.25
## The cap cloud (its size, how far over the summit), the rain under it (streaks, their fall), the
## wash: the cap settles in CAP_S, the rain falls RAIN_S, the dust and the droop go over WASH_S
## (starting WASH_DELAY_S into the rain); the piece then jumps (FLIGHT_S) to beside the cat.
const CAP_SIZE := 0.95
const CAP_OVER := 1.1
const CAP_FROM := Vector3(1.6, -0.3, 0.0)
## The cap bobs gently once it has settled (m, s a bob), visual only.
const CAP_BOB := 0.06
const CAP_BOB_S := 3.6
const RAIN := Color("8fd3ff")
const STREAKS := 34
const RAIN_DROP := 1.6
const RAIN_SPEED := 4.0
const CAP_S := 0.8
const RAIN_S := 2.6
const WASH_DELAY_S := 0.6
const WASH_S := 1.4
const GLINT_S := 0.45
const GLINT_SWELL := 0.6
const FLIGHT_S := 1.3
const LAND_FROM_CAT := Vector3(1.0, 0.0, 0.3)
const HIGHLIGHT_R := 0.9
## The stage whose stamp brings the rain (the last).
const CLOUD_STAGE := 2

var rock: Node3D
var cap: Node3D
var _dust: Node3D
var _rain: Node3D
var _flowers: Array[Node3D] = []
var _glint_at := NEVER
var _rain_at := NEVER


func build() -> void:
	position = DewCloudProps.summit()
	rock = ArtKit.instance(_rock_mesh())
	rock.name = "SummitRock"
	add_child(rock)
	for i in FLOWERS:
		var hinge := Node3D.new()
		hinge.name = "Flower%d" % i
		var a := PI * (0.15 + 0.7 * i / (FLOWERS - 1))   # round the front half of the rock
		hinge.position = Vector3(cos(a) * (ROCK_R + 0.12), 0.0, sin(a) * (ROCK_R + 0.12) * 0.8)
		hinge.rotation = Vector3(0.0, -a + PI * 0.5, 0.0)
		var flower := ArtKit.instance(_flower_mesh(FLOWER_COLORS[i % FLOWER_COLORS.size()]))
		hinge.add_child(flower)
		add_child(hinge)
		_flowers.append(flower)
	make_piece(PIECE_AT, PIECE_HIDDEN)
	_dust = ArtKit.instance(_dust_mesh())
	_dust.name = "Dust"
	_dust.position = PIECE_AT
	add_child(_dust)
	cap = ArtKit.instance(DewCloudProps.cloud_mesh(CAP_SIZE), MapIsland.cloud_material())
	cap.name = "Cap"
	cap.position = Vector3(0.0, CAP_OVER, 0.0)
	add_child(cap)
	_rain = ArtKit.instance(_rain_mesh(), (host().props as DewCloudProps).bright_material if host() != null else null)
	_rain.name = "Rain"
	_rain.visible = false
	add_child(_rain)
	_jump(0)


## The screen's stamps: the lab's knob in play follows the stage (the parcel in stage 3).
func show_stage(stage_now: int, stamps: int, just_cleared: bool) -> void:
	super(stage_now, stamps, just_cleared)
	if host() != null and host().has_method("stage_changed"):
		host().stage_changed()


## The wash (0 dusty, drooping .. 1 clean, flowers up).
func _set_wash(amount: float) -> void:
	_dust.scale = Vector3.ONE * maxf(0.001, 1.0 - amount)
	_dust.visible = amount < 1.0
	for flower in _flowers:
		flower.rotation = Vector3(DROOP * (1.0 - amount), 0.0, 0.0)


func _cleared(stage_index: int, last: bool) -> void:
	cheer_cat(last)
	_glint_at = _t
	if last or stage_index == CLOUD_STAGE:
		_rain_at = _t
		cap.visible = true
		cap.position = Vector3(0.0, CAP_OVER, 0.0) + CAP_FROM
		cap.scale = Vector3.ONE * 0.4


func _jump(stamps: int) -> void:
	var done := stamps >= stages
	_set_wash(1.0 if done else 0.0)
	cap.visible = done
	cap.position = Vector3(0.0, CAP_OVER, 0.0)
	cap.scale = Vector3.ONE
	_rain.visible = false
	_rain_at = NEVER


func highlight_radius() -> float:
	return HIGHLIGHT_R


## The rain washed the summit (the dust gone, the flowers up).
func washed() -> bool:
	return not _dust.visible


func flowers_up() -> bool:
	return _flowers.all(func(f: Node3D) -> bool: return absf(f.rotation.x) < 0.01)


func _process(delta: float) -> void:
	super(delta)
	if piece != null and piece_state == "held":
		piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * pulse(_glint_at, GLINT_S))
	if not running(_rain_at):
		if cap.visible:
			cap.position = Vector3(0.0, CAP_OVER + CAP_BOB * sin(TAU * _t / CAP_BOB_S), 0.0)
		return
	var k := progress(_rain_at, CAP_S)
	cap.position = Vector3(0.0, CAP_OVER, 0.0) + CAP_FROM * (1.0 - smooth(k))
	cap.scale = Vector3.ONE * lerpf(0.4, 1.0, smooth(k))
	var raining := _t - _rain_at - CAP_S * 0.6
	_rain.visible = raining > 0.0 and raining < RAIN_S
	if _rain.visible:
		_rain.position = Vector3(0.0, -fposmod(raining * RAIN_SPEED, RAIN_DROP), 0.0)
	var wash := clampf((_t - _rain_at - WASH_DELAY_S - CAP_S) / WASH_S, 0.0, 1.0)
	_set_wash(smooth(wash))
	if wash >= 1.0 and piece != null and piece_state == "held":
		_glint_at = _t
		var cat := lab_cat()
		var land := (cat.global_position if cat != null else global_position + Vector3(-4.0, -position.y, 3.0)) + LAND_FROM_CAT
		launch_to(land, FLIGHT_S, 0.0, true)
	if raining >= RAIN_S and wash >= 1.0:
		_rain_at = NEVER
		_rain.visible = false


# --- the meshes -----------------------------------------------------------------------------------

## The summit's rock: a rounded grey boulder the piece leans on.
static func _rock_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = ROCK_R
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.75, 0.85)), Vector3(0.0, ROCK_R * 0.45, 0.0)), ROCK_R, 4, 9, ROCK)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.8, 0.5, 0.7)), Vector3(-0.15, ROCK_R * 0.95, -0.05)), ROCK_R * 0.6, 3, 8, ROCK_TOP)
	return b.commit()


## Brown dust over the piece (round the origin, the piece's place): lumps on its front.
static func _dust_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 0.9
	b.ao_height = 0.4
	for lump: Array in [[Vector3(-0.16, 0.08, 0.12), 0.2, DUST], [Vector3(0.18, -0.06, 0.13), 0.19, DUST_LIGHT], [Vector3(0.02, -0.2, 0.1), 0.17, DUST], [Vector3(0.12, 0.22, 0.06), 0.13, DUST_LIGHT], [Vector3(-0.22, -0.14, 0.04), 0.12, DUST_LIGHT]]:
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.85, 0.6)), lump[0]), float(lump[1]), 3, 8, lump[2])
	return b.commit()


## A flower on its hinge (local y up; the hinge tips it forward along +z): a stem, a leaf, a head.
static func _flower_mesh(color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = STEM
	b.add_cylinder(Transform3D(), 0.03, 0.025, STEM, 5, ArtPalette.STEM)
	b.add_sphere(Transform3D(Basis(Vector3.BACK, 0.8).scaled(Vector3(1.0, 0.35, 0.55)), Vector3(0.06, STEM * 0.4, 0.0)), 0.1, 2, 6, ArtPalette.LEAF)
	b.ao_min = 1.0
	for n in 5:
		var d := Vector3(cos(TAU * n / 5.0), 0.0, sin(TAU * n / 5.0))
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.45, 1.0)), Vector3(0.0, STEM, 0.0) + d * 0.08), 0.07, 2, 6, color)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, STEM + 0.03, 0.0)), 0.05, 2, 6, ArtPalette.YELLOW)
	return b.commit()


## The rain under the cap: streaks over the summit in two rows of RAIN_DROP (the node slides them down
## and wraps).
static func _rain_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in STREAKS:
		var x := (fposmod(i * 0.618034, 1.0) - 0.5) * CAP_SIZE * 2.6
		var z := (fposmod(i * 0.381966, 1.0) - 0.5) * 0.8 + 0.3
		var y := CAP_OVER - 0.4 - fposmod(i * 0.27, 1.0) * RAIN_DROP * 2.0 + RAIN_DROP
		b.add_rounded_box(Transform3D(Basis(Vector3.BACK, 0.12), Vector3(x, y, z)), Vector3(0.035, 0.26, 0.035), 0.012, 1, RAIN)
	return b.commit()
