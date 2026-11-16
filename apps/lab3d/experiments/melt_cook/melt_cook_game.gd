## The 되돌릴 수 있을까? piece game (#158; curie-lines.md 3: "달걀 바구니에 반짝이는 달걀이 하나 있어! 수상해."
## … "익은 채 그대로! 조각이다!"): the piece is shut in the shiny egg of the basket on the table's right. Each
## of the first two stamps gives the egg a little hop in its basket; at stage 3 (with the egg item) the
## shiny egg is the one in the pot, and the last stamp (cooked, cooled and still cooked) lets the bread
## cat peel it: the shell cracks into pieces on the stove, the piece pops up out of the egg and jumps
## down onto the table in front of the cat; the screen then flies it to the cat. Visual only.
class_name MeltCookGame
extends LabGame

## A stamp's hop of the shiny egg in the basket (m, s), the piece's rise out of the peeled egg (m, s), its
## jump to the table in front of the cat (s; where it lands from the cat's feet, on the table's top).
const HOP := 0.14
const HOP_S := 0.45
const RISE := 0.7
const RISE_S := 0.5
const FLIGHT_S := 1.2
const LAND_FROM_CAT := Vector3(0.0, 0.0, 0.75)
const HIGHLIGHT_R := 0.62
## The piece's size while it hides in the egg (a share of the round's), small enough to be inside the shell.
const HIDDEN := 0.55

var _hop_at := NEVER
var _peel_at := NEVER
var _rise_at := NEVER


func build() -> void:
	make_piece(MeltCookProps.SHINY_AT, PIECE_SIZE * HIDDEN)
	_jump(0)


## Where the shiny egg is now (world): in the pot with the egg item at stage 3, else in the basket.
func egg_center() -> Vector3:
	var l: Variant = lab
	if l != null and "model" in l and l.model != null and l.model.is_egg() and l.model.site() >= MeltCookModel.SHINY:
		return MeltCookProps.EGG_POT
	return MeltCookProps.SHINY_AT


## The egg as it is after `stamps` stamps: at rest (a re-entered spot, a finished round).
func _jump(_stamps: int) -> void:
	_hop_at = NEVER
	_peel_at = NEVER
	_rise_at = NEVER
	if piece != null and piece_state == "held":
		piece.position = egg_center()


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	SoundBoard.play(&"glint")
	if last:
		_peel_at = _t
		var l: Variant = lab
		if l != null and "props" in l and l.props != null:
			l.props.begin_peel()
	else:
		_hop_at = _t


func highlight_radius() -> float:
	return HIGHLIGHT_R


func _process(delta: float) -> void:
	super(delta)
	var l: Variant = lab
	if l == null or not ("props" in l) or l.props == null:
		return
	var egg: Node3D = l.props.shiny_egg
	egg.position = MeltCookProps.SHINY_AT - MeltCookProps.BASKET_AT + Vector3.UP * HOP * pulse(_hop_at, HOP_S)
	if running(_hop_at) and progress(_hop_at, HOP_S) >= 1.0:
		_hop_at = NEVER
	if piece == null or piece_state != "held":
		return
	if running(_peel_at):
		piece.position = egg_center()
		if progress(_peel_at, l.props.PEEL_S) >= 1.0:
			_peel_at = NEVER
			_rise_at = _t
		return
	if running(_rise_at):
		piece.position = egg_center() + Vector3.UP * RISE * eased(_rise_at, RISE_S)
		if progress(_rise_at, RISE_S) >= 1.0:
			_rise_at = NEVER
			# Out of the egg: down onto the table in front of the bread cat, growing to the round's size.
			var at := cat_spot(Vector3.ZERO)
			launch_to(Vector3(at.x, KitchenSet.TABLE_TOP, at.z) + LAND_FROM_CAT, FLIGHT_S, KitchenSet.TABLE_TOP, true)
		return
	piece.position = egg_center()
