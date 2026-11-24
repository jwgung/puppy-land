## The 빵 반죽 부풀리기 piece game (#159; curie-lines.md 4: "높은 선반 위에 조각이 있어! 반죽이 거기까지
## 부풀면 닿겠어." … "선반까지 닿았어! 조각!"): the piece lies on the high shelf over the warm place from
## the start (the mockup: it shows "up to there" before stage 3), three lamps on the shelf board's front.
## Each stamp lights a lamp (and the bread cat cheers); the last one (the dough rose by the oven up to
## the shelf) gives the piece a hop up off the board and it jumps down onto the table in front of the
## bread cat's crates; the screen then flies it to the cat. Visual only.
class_name DoughGame
extends LabGame

## The piece on the board (from the board's front middle), the lamps on the board's front, the hop
## (m, s) and the jump to the table in front of the cat (s; from the cat's feet).
const ON_BOARD := Vector3(0.35, 0.0, -0.2)
const LAMPS_FROM := Vector3(-0.3, 0.0, 0.03)
const HOP := 0.45
const HOP_S := 0.5
const FLIGHT_S := 1.2
const LAND_FROM_CAT := Vector3(0.0, 0.0, 0.8)
const HIGHLIGHT_R := 0.85

var lamps: MeshInstance3D
var _lamps_lit := -1
var _hop_at := NEVER


func build() -> void:
	lamps = MeshInstance3D.new()
	lamps.name = "ShelfLamps"
	lamps.material_override = ArtKit.lit_material()
	lamps.position = board_front() + LAMPS_FROM
	add_child(lamps)
	make_piece(rest_point())
	_jump(0)


## The middle of the shelf board's front edge, on its top's height (world).
static func board_front() -> Vector3:
	return Vector3(DoughProps.WARM_X, DoughProps.SHELF_Y + DoughProps.BOARD.y * 0.5,
		DoughProps.BOARD_BACK + DoughProps.BOARD.z)


## Where the piece lies on the board (its middle, world).
func rest_point() -> Vector3:
	return board_front() + ON_BOARD + Vector3.UP * (DoughProps.BOARD.y * 0.5 + full_size())


func _show_lamps(lit: int) -> void:
	if lit == _lamps_lit:
		return
	_lamps_lit = lit
	var b := ArtKit.builder()
	add_lamps(b, Vector3.ZERO, lit, 0.2, 0.06)
	lamps.mesh = b.commit()


func _jump(stamps: int) -> void:
	_hop_at = NEVER
	_show_lamps(stamps)
	if piece != null and piece_state == "held":
		piece.position = rest_point()


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	SoundBoard.play(&"glint")
	_show_lamps(cleared)
	if last:
		_hop_at = _t


## The clue: the shelf with the piece.
func highlight_spots() -> Array:
	return [{"at": rest_point(), "radius": HIGHLIGHT_R}]


func _process(delta: float) -> void:
	super(delta)
	if piece == null or piece_state != "held" or not running(_hop_at):
		return
	piece.position = rest_point() + Vector3.UP * HOP * sin(PI * 0.5 * minf(progress(_hop_at, HOP_S), 1.0))
	if progress(_hop_at, HOP_S) >= 1.0:
		_hop_at = NEVER
		# Off the shelf: down onto the table in front of the bread cat (up on its crates).
		var at := cat_spot(Vector3.ZERO)
		launch_to(Vector3(at.x, KitchenSet.TABLE_TOP, at.z) + LAND_FROM_CAT, FLIGHT_S, KitchenSet.TABLE_TOP)
