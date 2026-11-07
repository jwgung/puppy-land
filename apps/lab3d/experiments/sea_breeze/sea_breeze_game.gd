## The 바닷바람 piece game (#93; hutton-lines.md 6: "저기 멀리 돛단배 한 척이 떠 있어! 어? 저 배에 조각이
## 실려 있어!"): the piece rides on the deck of the sailing boat far out at sea. Stage 1 (the sea breeze
## turns the pinwheel, "바람개비가 빙글빙글!"): the pinwheel whirls for a while and the piece glints.
## Stage 2 (the night's land breeze, "고깃배가 바다로 슝!"): the fishing boat at the pier sails out to
## sea on it and its lantern stays lit far out. Stage 3 (a strong sea breeze, "돛단배가 왔어!
## 조각이다!"): the sailing boat comes in to the shore and the piece jumps from its deck onto the sand,
## growing to the round's size on the way; the screen then flies it to the bread cat. Visual only.
class_name SeaBreezeGame
extends LabGame

## The pinwheel's cheer: extra spin (rad/s) fading over WHIRL_S.
const WHIRL := 14.0
const WHIRL_S := 2.4
## The piece glints (a swell of GLINT_SWELL of its size) over GLINT_S.
const GLINT_S := 0.5
const GLINT_SWELL := 0.6
## The fishing boat's trip out: OUT_S long to OUT_TO (world x, z), turning a little on the way.
const OUT_S := 2.6
const OUT_TO := Vector2(15.0, -6.0)
const OUT_SIZE := 0.75
## The sailing boat comes in to HOME (world x, z: by the shore, clear of the pier) in IN_S; then the
## piece jumps to the sand beside the cat in FLIGHT_S.
const IN_S := 2.4
const HOME := Vector2(3.4, -0.2)
const FLIGHT_S := 1.1
const LAND_FROM_CAT := Vector3(1.2, 0.0, 0.3)
const PIECE_SCALE := 1.0
const HIGHLIGHT_R := 1.3

var _whirl_at := NEVER
var _glint_at := NEVER
var _out_at := NEVER
var _in_at := NEVER


func _props() -> SeaBreezeProps:
	return (host().props as SeaBreezeProps) if host() != null else null


func build() -> void:
	var p := _props()
	make_piece(Vector3.ZERO, PIECE_SIZE * PIECE_SCALE)
	piece.position = p.deck_point()
	_jump(0)


## Where the boats are after `stamps` stamps (no animation).
func _jump(stamps: int) -> void:
	var p := _props()
	_out_at = NEVER
	_in_at = NEVER
	_whirl_at = NEVER
	p.spin_boost = 0.0
	_place_fishing(1.0 if stamps >= 2 else 0.0)
	_place_sailing(1.0 if stamps >= stages else 0.0)


func _cleared(stage_index: int, last: bool) -> void:
	cheer_cat(last)
	_glint_at = _t
	SoundBoard.play(&"glint")
	match stage_index:
		0:
			_whirl_at = _t
		1:
			_out_at = _t
	if last:
		_in_at = _t


## The fishing boat `k` (0 at the pier .. 1 far out) of its way out.
func _place_fishing(k: float) -> void:
	var p := _props()
	var from := Vector2(SeaBreezeProps.FISHING_AT.x, SeaBreezeProps.FISHING_AT.z)
	var at := from.lerp(OUT_TO, k)
	p.fishing.position = Vector3(at.x, p.fishing.position.y, at.y)
	p.fishing.rotation = Vector3(0.0, 0.45 * sin(PI * k) * 0.5 + 0.35 * k, 0.0)
	p.fishing.scale = Vector3.ONE * lerpf(1.0, OUT_SIZE, k)


## The sailing boat `k` (0 far out .. 1 by the shore) of its way in.
func _place_sailing(k: float) -> void:
	var p := _props()
	var from := Vector2(SeaBreezeProps.SAIL_AT.x, SeaBreezeProps.SAIL_AT.z)
	var at := from.lerp(HOME, k)
	p.sailing.position = Vector3(at.x, p.sailing.position.y, at.y)
	if piece != null and piece_state == "held":
		piece.global_position = p.deck_point() if p.sailing.is_inside_tree() else piece.position


func highlight_spots() -> Array:
	var p := _props()
	if p == null or piece == null:
		return []
	return [{"at": to_local(p.sailing.global_position + Vector3.UP * 1.4) if is_inside_tree() else p.sailing.position, "radius": HIGHLIGHT_R}]


func _process(delta: float) -> void:
	super(delta)
	var p := _props()
	if p == null:
		return
	p.spin_boost = WHIRL * (1.0 - clampf(progress(_whirl_at, WHIRL_S), 0.0, 1.0)) if running(_whirl_at) else 0.0
	if running(_whirl_at) and progress(_whirl_at, WHIRL_S) >= 1.0:
		_whirl_at = NEVER
	if running(_out_at):
		_place_fishing(eased(_out_at, OUT_S))
		if progress(_out_at, OUT_S) >= 1.0:
			_out_at = NEVER
	if piece == null:
		return
	if piece_state == "held":
		piece.global_position = p.deck_point()
		piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * pulse(_glint_at, GLINT_S))
		if running(_in_at):
			_place_sailing(eased(_in_at, IN_S))
			if progress(_in_at, IN_S) >= 1.0:
				_in_at = NEVER
				# Off the deck: up and over onto the sand beside the cat, at the round's size.
				launch_to(lab_cat().global_position + LAND_FROM_CAT, FLIGHT_S, 0.0, true)
