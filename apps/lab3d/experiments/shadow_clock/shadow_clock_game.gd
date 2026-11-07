## The 그림자 시계 piece game (#86; hutton-lines.md 2: "저기 먼 돌 위에 조각이 있어! 그런데 뚜껑이 꽉 닫혀
## 있네." / "그림자 끝이 그 돌에 닿으면 뚜껑이 열린다고 들었어." / "딱 맞았어! 뚜껑이 열렸어!"): on the far
## stone's far edge stands a little cage, a wooden box with gold bars and a closed lid; the piece shows
## between the bars. Stages 1 and 2: a lamp on the box lights and the piece glints. Stage 3 (the long
## stick's shadow tip on the stone): the lid flips open, a warm flash, and the piece jumps out over
## the stone onto the yard; the screen then flies it to the bread cat. Visual only (LabGame).
class_name ShadowClockGame
extends LabGame

## The cage (local to the game, its foot on the stone's top): the box, the bars' height, the lid.
const BOX := Vector3(0.62, 0.22, 0.5)
const BARS_H := 0.42
const BAR_R := 0.022
## The bars stand on a grid of fractions of the box (x, z in -0.5..0.5), inset BAR_INSET from its edge;
## the front has four, the back only its corners, the sides one in the middle.
const BAR_INSET := 0.06
const BAR_EDGE := 0.5
const BAR_INNER := 0.17
const BAR_SIDES := 6
const LID := Vector3(0.62, 0.3, 0.5)
const GOLD := Color("ffc61a")
const PIECE_SCALE := 0.55
## The lid opens by OPEN_ANGLE (rad, about its back hinge) in OPEN_S; a glint swells the piece by
## GLINT_SWELL of its size and back in GLINT_S; the warm flash lasts FLASH_S.
const OPEN_S := 0.45
const OPEN_ANGLE := 1.9
const GLINT_S := 0.45
const GLINT_SWELL := 0.6
const FLASH_S := 1.2
const HIGHLIGHT_R := 0.75
## The piece's jump out of the cage: its flight time (s) and where it lands from the stone's middle
## (towards the camera and the stick: in clear view).
const FLIGHT_S := 1.0
const LAND_FROM_STONE := Vector3(1.2, 0.0, 1.2)

var _lid: Node3D
var _lamps: MeshInstance3D
var _glow: ClueGlow
var _glint_at := -10.0
var _open_at := -10.0
var _flash_until := -10.0


func _props() -> ShadowClockProps:
	return (host().props as ShadowClockProps) if host() != null else null


func build() -> void:
	var p := _props()
	position = p.stone_at + ShadowClockProps.CHEST_FROM_MIDDLE + Vector3.UP * ShadowClockProps.STONE_TOP
	var cage := ArtKit.instance(cage_mesh())
	cage.name = "Cage"
	add_child(cage)
	_lamps = ArtKit.instance(lamps_mesh(0))
	_lamps.name = "Lamps"
	add_child(_lamps)
	_lid = Node3D.new()
	_lid.name = "LidHinge"
	_lid.position = Vector3(0.0, BOX.y + BARS_H, -BOX.z * 0.5)
	add_child(_lid)
	var lid := ArtKit.instance(chest_lid_mesh(LID))
	lid.name = "Lid"
	_lid.add_child(lid)
	make_piece(Vector3(0.0, BOX.y + BARS_H * 0.5, 0.0), PIECE_SIZE * PIECE_SCALE)
	_glow = ClueGlow.halo(HIGHLIGHT_R)
	_glow.position = Vector3(0.0, BOX.y + BARS_H * 0.5, 0.0)
	add_child(_glow)
	_jump(0)


## The box (no lid of its own) and the gold bars round the piece, its foot at the origin.
static func cage_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_height = BOX.y + BARS_H
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, BOX.y * 0.5, 0.0)), BOX, 0.03, 1, CHEST_WOOD, CHEST_WOOD.lightened(0.12))
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, BOX.y * 0.5, BOX.z * 0.5 + 0.005)), Vector3(BOX.x * 0.9, BOX.y * 0.25, 0.012), 0.0, 1, CHEST_DARK)
	b.ao_min = 1.0
	var xs: Array[float] = [-BAR_EDGE, -BAR_INNER, BAR_INNER, BAR_EDGE]
	var spots: Array[Vector2] = [Vector2(-BAR_EDGE, -BAR_EDGE), Vector2(BAR_EDGE, -BAR_EDGE)]   # the back's corners
	for x in xs:
		spots.append(Vector2(x, BAR_EDGE))   # the front
	spots.append(Vector2(-BAR_EDGE, 0.0))   # the sides' middles
	spots.append(Vector2(BAR_EDGE, 0.0))
	for spot in spots:
		b.add_cylinder(Transform3D(Basis(), Vector3(spot.x * (BOX.x - BAR_INSET), BOX.y, spot.y * (BOX.z - BAR_INSET))), BAR_R, BAR_R, BARS_H, BAR_SIDES, GOLD)
	return b.commit()


## Three lamps on the box's front, `lit` of them on (one per stamp).
static func lamps_mesh(lit: int) -> Mesh:
	var b := ArtKit.builder()
	LabGame.add_lamps(b, Vector3(0.0, BOX.y * 0.5, BOX.z * 0.5 + 0.03), lit, 0.17, 0.05)
	return b.commit()


func _set_open(amount: float) -> void:
	_lid.rotation = Vector3(-OPEN_ANGLE * amount, 0.0, 0.0)


func _cleared(stage_index: int, last: bool) -> void:
	_glint_at = _t
	_lamps.mesh = lamps_mesh(stage_index + 1)
	SoundBoard.play(&"glint")
	var cat := _props().cat
	if cat != null:
		cat.cheer(true, 2 if last else 1)
	if last:
		_open_at = _t
		_flash_until = _t + FLASH_S
		_glow.set_on(true)


func _jump(stamps: int) -> void:
	_lamps.mesh = lamps_mesh(mini(stamps, stages))
	_open_at = -10.0
	_set_open(1.0 if stamps >= stages else 0.0)


func highlight_radius() -> float:
	return HIGHLIGHT_R


func _process(delta: float) -> void:
	super(delta)
	if _glow != null and _flash_until > 0.0 and _t > _flash_until:
		_flash_until = -10.0
		_glow.set_on(false)
	if piece == null or piece_state != "held":
		return
	var k := (_t - _glint_at) / GLINT_S
	piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * sin(PI * clampf(k, 0.0, 1.0)))
	if _open_at > 0.0:
		var o := smooth((_t - _open_at) / OPEN_S)
		_set_open(o)
		if o >= 1.0:
			_open_at = -10.0
			_launch()


## Out of the open cage: up and over onto the yard in front of the stone in FLIGHT_S (the lab's g).
func _launch() -> void:
	var land := _props().stone_at + LAND_FROM_STONE + Vector3.UP * piece_size
	var from := piece.global_position
	var g := lab_g()
	var v := (land - from) / FLIGHT_S + Vector3.UP * 0.5 * g * FLIGHT_S
	launch_piece(v, g, 0.0)
