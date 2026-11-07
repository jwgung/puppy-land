## The 물의 여행 piece game (#91; hutton-lines.md 4: "마른 바닥에 조각이 박혀 있어!" / "연못에 물이 차오르면
## 조각이 떠오를 것 같아." / "연못이 찰랑! 조각이 떠올랐어!"): the piece is stuck, tilted, in the dry pond's
## mud, and three frogs sit thirsty on the stones round it. Stage 1 (the first cloud): the frogs look
## up at the sky with a little hop. Stage 2 (the rain): they hop for joy. Stage 3 (the pond full): the
## piece floats up to the water and bobs, then jumps out onto the land beside the bread cat, growing to
## the round's size on the way, and the frogs leap into the pond. The screen then flies the piece to
## the cat. Visual only (LabGame).
class_name WaterCycleGame
extends LabGame

## The piece in the mud: its place from the pond's middle, its hidden size and its tilt (rad).
const PIECE_FROM_MIDDLE := Vector3(0.35, 0.1, 0.35)
const HIDDEN_SIZE := 0.2
const STUCK_TILT := 0.75
## The frogs on the stones (deg round the pond, 90 = towards the camera) and their size.
const FROG_AT_DEG := [40.0, 105.0, 160.0]
const FROG_SIZE := 1.0
const FROG := Color("5cc64a")
const FROG_TOP := Color("7cd85e")
const FROG_BELLY := Color("d8f0a0")
## A hop: how high (m) and how long (s); the stage-1 look-up hop is smaller.
const HOP_H := 0.45
const HOP_S := 0.5
const PEEK_H := 0.18
const HOPS := 2
## The float: the piece rises from the mud to the water in FLOAT_S, bobs for BOB_S, then jumps
## (FLIGHT_S) to its landing beside the cat.
const FLOAT_S := 1.2
const BOB_S := 0.8
const BOB_H := 0.06
const FLIGHT_S := 1.0
const LAND_FROM_CAT := Vector3(-1.1, 0.0, 0.3)
## The frogs' leap into the full pond (from the rim to inside it, m) and its time (s).
const LEAP_IN := 0.8
const LEAP_S := 0.7
const HIGHLIGHT_R := 0.7
## The stages that do something in `_cleared` besides the cat's cheer.
const CLOUD_STAGE := 0
const RAIN_STAGE := 1

var frogs: Array[Node3D] = []
var _rims: Array[Vector3] = []
var _piece_rest := Vector3.ZERO
var _peek_at := NEVER
var _hop_at := NEVER
var _float_at := NEVER
var _leap_at := NEVER
var _in_pond := false


func build() -> void:
	var mesh := frog_mesh()
	for i in FROG_AT_DEG.size():
		var a := deg_to_rad(float(FROG_AT_DEG[i]))
		var rim := WaterCycleProps.POND_AT + Vector3(cos(a), 0.0, sin(a)) * (WaterCycleProps.POND_RADIUS + 0.12) + Vector3.UP * 0.32
		var frog := ArtKit.instance(mesh)
		frog.name = "Frog%d" % i
		frog.scale = Vector3.ONE * FROG_SIZE
		add_child(frog)
		frogs.append(frog)
		_rims.append(rim)
	_piece_rest = WaterCycleProps.POND_AT + PIECE_FROM_MIDDLE
	make_piece(_piece_rest, HIDDEN_SIZE)
	_jump(0)


func _cleared(stage_index: int, last: bool) -> void:
	cheer_cat(last)
	match stage_index:
		CLOUD_STAGE:
			_peek_at = _t
		RAIN_STAGE:
			_hop_at = _t
	if last:
		_float_at = _t
		_leap_at = _t + FLOAT_S


func _jump(stamps: int) -> void:
	_in_pond = stamps >= stages
	_peek_at = NEVER
	_hop_at = NEVER
	_float_at = NEVER
	_leap_at = NEVER
	_place_frogs(0.0, 1.0 if _in_pond else 0.0)
	if piece != null and piece_state == "held":
		piece.position = _piece_rest
		piece.rotation.z = STUCK_TILT


## The frogs on their stones lifted `lift` m, `leap` of the way (0..1) into the pond, looking at the
## camera (into the pond: towards its middle).
func _place_frogs(lift: float, leap: float) -> void:
	for i in frogs.size():
		var rim := _rims[i]
		var inward := (WaterCycleProps.POND_AT - rim)
		inward.y = 0.0
		inward = inward.normalized()
		var at := rim + inward * LEAP_IN * leap
		at.y = lerpf(rim.y, WaterCycleProps.POND_AT.y + WaterCycleProps.POND_DEPTH - 0.05, leap) + lift + sin(PI * leap) * HOP_H
		frogs[i].position = at
		var face := Vector3.BACK.lerp(inward, 0.5).normalized()
		frogs[i].rotation = Vector3(0.0, atan2(face.x, face.z), 0.0)


func highlight_radius() -> float:
	return HIGHLIGHT_R


## The frogs are in the full pond (the round's last stamp).
func frogs_in_pond() -> bool:
	return _in_pond


func _process(delta: float) -> void:
	super(delta)
	var lift := 0.0
	if running(_peek_at):
		var k := progress(_peek_at, HOP_S)
		lift = PEEK_H * sin(PI * clampf(k, 0.0, 1.0))
		if k >= 1.0:
			_peek_at = NEVER
	if running(_hop_at):
		var k := progress(_hop_at, HOP_S * HOPS)
		lift = HOP_H * absf(sin(PI * HOPS * clampf(k, 0.0, 1.0)))
		if k >= 1.0:
			_hop_at = NEVER
	var leap := 1.0 if _in_pond else 0.0
	if running(_leap_at) and _t >= _leap_at:
		leap = eased(_leap_at, LEAP_S)
		if leap >= 1.0:
			_leap_at = NEVER
			_in_pond = true
	_place_frogs(lift, leap)
	if piece == null or piece_state != "held" or not running(_float_at):
		return
	# Up out of the mud to the full pond's water, upright, then a little bob and the jump to the cat.
	var surface := WaterCycleProps.POND_AT.y + WaterCycleProps.POND_DEPTH + piece_size * 0.4
	var f := eased(_float_at, FLOAT_S)
	piece.position = Vector3(_piece_rest.x, lerpf(_piece_rest.y, surface, f), _piece_rest.z)
	piece.rotation.z = STUCK_TILT * (1.0 - f)
	if f >= 1.0:
		piece.position.y = surface + BOB_H * sin(progress(_float_at + FLOAT_S, BOB_S) * TAU)
		if progress(_float_at + FLOAT_S, BOB_S) >= 1.0:
			_float_at = NEVER
			var cat := lab_cat()
			var spot := (cat.global_position if cat != null else WaterCycleProps.CAT_AT) + LAND_FROM_CAT
			launch_to(Vector3(spot.x, WaterCycleProps.LAND_TOP, spot.z), FLIGHT_S, WaterCycleProps.LAND_TOP, true)


# --- the meshes -----------------------------------------------------------------------------------

## A little frog sitting, facing +z: a round green body, a pale belly, two eye bumps with dark pupils,
## folded back legs and front feet.
static func frog_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.5
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.72, 1.0)), Vector3(0.0, 0.2, 0.0)), 0.3, 5, 12, FROG)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.8, 0.6, 0.5)), Vector3(0.0, 0.15, 0.17)), 0.24, 4, 10, FROG_BELLY)
	for side: float in [-1.0, 1.0]:
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.7, 0.5, 1.2)), Vector3(side * 0.24, 0.08, -0.04)), 0.17, 3, 8, FROG_TOP)
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.4, 1.3)), Vector3(side * 0.13, 0.02, 0.24)), 0.07, 2, 6, FROG_TOP)
		b.add_sphere(Transform3D(Basis(), Vector3(side * 0.13, 0.4, 0.1)), 0.1, 3, 8, FROG_TOP)
		b.ao_min = 1.0
		b.add_sphere(Transform3D(Basis(), Vector3(side * 0.13, 0.42, 0.17)), 0.065, 3, 8, Color.WHITE)
		b.add_sphere(Transform3D(Basis(), Vector3(side * 0.13, 0.42, 0.22)), 0.035, 2, 6, ArtPalette.RUBBER_RIDGE)
		b.ao_min = 0.85
	return b.commit()
