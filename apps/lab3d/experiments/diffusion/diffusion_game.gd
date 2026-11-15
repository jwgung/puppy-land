## The 퍼지는 냄새와 잉크 piece game (#156; curie-lines.md 1: "부엌에 조각이 떨어진 걸 봤대!" … "킁킁!
## 부엌 찾았어! 조각도!"): the piece is shut in the kitchen's bread box at the back of the table, three
## lamps on its front. Each stamp lights a lamp and the box gives a little hop; the last one (the
## smell reached Puppy's nose: he follows it back to the kitchen) opens its lid, the piece pops up out
## of it and jumps down beside the bread cat; the screen then flies it to the cat. Visual only.
class_name DiffusionGame
extends LabGame

## The bread box on the table (its middle, world) and its size (m).
const BOX_AT := Vector3(2.5, KitchenSet.TABLE_TOP + 0.3, -0.45)
const BOX_SIZE := Vector3(1.0, 0.6, 0.62)
## The lamps on its front, a stamp's hop (m, s), the lid's opening (rad, s), the piece's rise (m, s)
## and its jump to beside the cat (s).
const HOP := 0.14
const HOP_S := 0.45
const LID_OPEN := 1.9
const LID_S := 0.6
const RISE := 0.55
const RISE_S := 0.5
const FLIGHT_S := 1.2
const LAND_FROM_CAT := Vector3(1.1, 0.0, 0.2)
const HIGHLIGHT_R := 0.95

var box: Node3D
var lid: Node3D
var lamps: MeshInstance3D
var _lamps_lit := -1
var _hop_at := NEVER
var _open_at := NEVER
var _rise_at := NEVER


func build() -> void:
	box = Node3D.new()
	box.name = "BreadBox"
	box.position = BOX_AT
	add_child(box)
	box.add_child(ArtKit.instance(chest_mesh(BOX_SIZE, false)))
	lid = Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0.0, BOX_SIZE.y * 0.2, -BOX_SIZE.z * 0.5)
	box.add_child(lid)
	lid.add_child(ArtKit.instance(chest_lid_mesh(BOX_SIZE)))
	lamps = MeshInstance3D.new()
	lamps.name = "Lamps"
	lamps.material_override = ArtKit.lit_material()
	box.add_child(lamps)
	make_piece(BOX_AT, PIECE_SIZE * 0.8)
	_jump(0)


func _show_lamps(lit: int) -> void:
	if lit == _lamps_lit:
		return
	_lamps_lit = lit
	var b := ArtKit.builder()
	add_lamps(b, Vector3(0.0, -BOX_SIZE.y * 0.05, BOX_SIZE.z * 0.5 + 0.06), lit)
	lamps.mesh = b.commit()


## The box after `stamps` stamps: its lamps lit, the lid shut (open once the round is done).
func _jump(stamps: int) -> void:
	_hop_at = NEVER
	_open_at = NEVER
	_rise_at = NEVER
	_show_lamps(stamps)
	box.position = BOX_AT
	lid.rotation.x = -LID_OPEN if stamps >= stages else 0.0
	if piece != null and piece_state == "held":
		piece.position = BOX_AT


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	SoundBoard.play(&"glint")
	_show_lamps(cleared)
	_hop_at = _t
	if last:
		_open_at = _t


func highlight_spots() -> Array:
	return [{"at": BOX_AT, "radius": HIGHLIGHT_R}]


func _process(delta: float) -> void:
	super(delta)
	if box == null:
		return
	box.position = BOX_AT + Vector3.UP * HOP * pulse(_hop_at, HOP_S)
	if running(_hop_at) and progress(_hop_at, HOP_S) >= 1.0:
		_hop_at = NEVER
	if running(_open_at):
		lid.rotation.x = -LID_OPEN * eased(_open_at, LID_S)
		if progress(_open_at, LID_S) >= 1.0:
			_open_at = NEVER
			_rise_at = _t
	if piece == null or piece_state != "held":
		return
	if running(_rise_at):
		piece.position = BOX_AT + Vector3.UP * RISE * eased(_rise_at, RISE_S)
		if progress(_rise_at, RISE_S) >= 1.0:
			_rise_at = NEVER
			# Out of the box: down beside the bread cat, growing to the round's size on the way.
			launch_to(cat_spot(LAND_FROM_CAT), FLIGHT_S, 0.0, true)
