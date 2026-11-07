## The 낮과 밤 piece game (#74; hutton-missions.md 1 "조각: 3단계에서 아침 햇살이 닿으면 집 앞 바위 틈에서
## 반짝"): the piece waits in the crevice of the rock in front of the fox's house, on the globe (the
## game is a child of the house's place, so it turns with the Earth). Only a point of it shows ("어두워서
## 잘 안 보여"). Stages 1 and 2: it glints once (a little pop). Stage 3, the morning: the light reaches
## the crevice, a warm glow flashes, the rock's two halves part and the piece jumps out of the globe
## and falls on the lab's gravity to the stage, growing to the round's piece size on the way; the
## screen then flies it to the bread cat. Visual only (LabGame).
class_name DayNightGame
extends LabGame

## The rock in front of the door (the house's local frame: -z east) and the piece in its crevice.
const ROCK_AT := Vector3(0.0, 0.0, -0.2)
const ROCK_RADIUS := 0.06
const HIDDEN_SIZE := 0.05
## A glint: the hidden piece swells by GLINT_SWELL of its size and back in GLINT_S.
const GLINT_S := 0.45
const GLINT_SWELL := 0.8
## The rock's halves part by OPEN_ANGLE (rad, each about its hinge) in OPEN_S.
const OPEN_S := 0.5
const OPEN_ANGLE := 0.5
## The warm flash round the crevice at the last stamp (s); the flying piece grows to the round's
## size on the way (launch_to, LabGame.GROW_RATE).
const FLASH_S := 1.2
## The crevice's halo while Puppy tells the clue (m: the house is small on the globe).
const HIGHLIGHT_R := 0.3
const FLASH_R := 0.32
## The piece's jump out of the globe: its flight time (s) and where it lands from the cat (m).
const FLIGHT_S := 1.1
const LAND_FROM_CAT := Vector3(-0.8, 0.0, 0.3)

var _halves: Array[Node3D] = []
var _glow: ClueGlow
var _glint_at := NEVER
var _open_at := NEVER
var _open := false
var _flash_until := NEVER


func build() -> void:
	for side: float in [-1.0, 1.0]:
		var half := ArtKit.instance(_rock_half(side), (host().props as DayNightProps).globe_material)
		half.name = "RockLeft" if side < 0.0 else "RockRight"
		var hinge := Node3D.new()
		hinge.name = half.name + "Hinge"
		hinge.position = ROCK_AT + Vector3(side * ROCK_RADIUS * 0.1, 0.0, 0.0)
		hinge.add_child(half)
		add_child(hinge)
		_halves.append(hinge)
	make_piece(ROCK_AT + Vector3(0.0, ROCK_RADIUS * 0.9, -ROCK_RADIUS * 0.35), HIDDEN_SIZE)
	_glow = ClueGlow.halo(FLASH_R)
	_glow.position = ROCK_AT + Vector3(0.0, ROCK_RADIUS, -0.05)
	add_child(_glow)
	_jump(0)


## One half of the rock (`side` -1 left, 1 right of the crevice), the house's local frame.
static func _rock_half(side: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = 0.06
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.55, 0.85, 1.0)), Vector3(side * ROCK_RADIUS * 0.45, ROCK_RADIUS * 0.75, 0.0)), ROCK_RADIUS, 3, 6, DayNightProps.ROCK)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.5, 0.6, 0.8)), Vector3(side * ROCK_RADIUS * 0.6, ROCK_RADIUS * 1.15, 0.01)), ROCK_RADIUS * 0.6, 3, 5, DayNightProps.ROCK_TOP)
	return b.commit()


## The rock's halves turned apart by `amount` (0 closed .. 1 open).
func _set_open(amount: float) -> void:
	for i in _halves.size():
		_halves[i].rotation = Vector3(0.0, 0.0, (1.0 if i == 1 else -1.0) * OPEN_ANGLE * amount)


func _cleared(_stage_index: int, last: bool) -> void:
	_glint_at = _t
	cheer_cat(last)
	if last:
		_open_at = _t
		_flash_until = _t + FLASH_S
		_glow.set_on(true)


func _jump(stamps: int) -> void:
	_open = stamps >= stages
	_open_at = NEVER
	_set_open(1.0 if _open else 0.0)


## The halo round the crevice while Puppy tells the clue (the house is small on the globe).
func highlight_radius() -> float:
	return HIGHLIGHT_R


func _process(delta: float) -> void:
	super(delta)
	if _glow != null and due(_flash_until):
		_flash_until = NEVER
		_glow.set_on(false)
	if piece == null or piece_state != "held":
		return
	piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * pulse(_glint_at, GLINT_S))
	if running(_open_at):
		var o := eased(_open_at, OPEN_S)
		_set_open(o)
		if o >= 1.0:
			_open = true
			# Out of the crevice: up from the globe's surface on an arc that lands on the stage beside
			# the bread cat, at the round's size.
			launch_to(cat_spot(LAND_FROM_CAT), FLIGHT_S, 0.0, true)
