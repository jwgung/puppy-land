## The 깨끗한 물 만들기 piece game (#160; curie-lines.md 5: "샘 바닥에 조각이 보이는데, 물이 흐려서 잘 안 보여!"
## … "깨끗한 샘물! 조각이다!"): the piece lies at the bottom of the muddy well, a dim glint under the brown
## water. Each of the first two stamps makes it glint (a little bob). The last stamp clears the well's water
## (the spring is clean again), the piece rises out of it and jumps down in front of the bread cat; the
## screen then flies it to the cat. Visual only.
class_name CleanWaterGame
extends LabGame

## Where the piece lies in the well (world), its size there (a share of the round's).
const PIECE_AT := Vector3(CleanWaterProps.WELL_AT.x, CleanWaterProps.WELL_H - 0.18, CleanWaterProps.WELL_AT.z + 0.2)
const HIDDEN := 0.6
## A stamp's bob (m, s), the rise out of the well (m, s), the jump to the cat (s, where it lands from the cat's feet).
const BOB := 0.12
const BOB_S := 0.45
const RISE := 1.0
const RISE_S := 0.6
const FLIGHT_S := 1.2
const LAND_FROM_CAT := Vector3(0.0, 0.0, 0.8)
const HIGHLIGHT_R := 0.8

var _bob_at := NEVER
var _rise_at := NEVER


func build() -> void:
	make_piece(PIECE_AT, PIECE_SIZE * HIDDEN)
	_jump(0)


func _jump(stamps: int) -> void:
	_bob_at = NEVER
	_rise_at = NEVER
	_clear_well(stamps >= 3)
	if piece != null and piece_state == "held":
		piece.position = PIECE_AT


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	SoundBoard.play(&"glint")
	if last:
		_clear_well(true)
		_rise_at = _t
	else:
		_bob_at = _t


## The well's water: muddy, or clear once the round is won.
func _clear_well(clear: bool) -> void:
	var l: Variant = lab
	if l == null or not ("props" in l) or l.props == null or l.props.well_water == null:
		return
	l.props.well_water.mesh = CleanWaterProps._disc_mesh(CleanWaterProps.WELL_R - 0.12, CleanWaterProps.CLEAR if clear else CleanWaterProps.MUD_TOP)


func highlight_radius() -> float:
	return HIGHLIGHT_R


func _process(delta: float) -> void:
	super(delta)
	if piece == null or piece_state != "held":
		return
	if running(_rise_at):
		piece.position = PIECE_AT + Vector3.UP * RISE * eased(_rise_at, RISE_S)
		if progress(_rise_at, RISE_S) >= 1.0:
			_rise_at = NEVER
			var at := cat_spot(Vector3.ZERO)
			launch_to(Vector3(at.x, 0.0, at.z) + LAND_FROM_CAT, FLIGHT_S, 0.0, true)
		return
	piece.position = PIECE_AT + Vector3.UP * BOB * pulse(_bob_at, BOB_S)
	if running(_bob_at) and progress(_bob_at, BOB_S) >= 1.0:
		_bob_at = NEVER
