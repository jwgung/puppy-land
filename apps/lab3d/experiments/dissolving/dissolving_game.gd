## The 녹으면 사라질까? piece game (#157; curie-lines.md 2: "바닷물 통 바닥에 조각이 있어! 물이 가득해서 못
## 꺼내겠어." … "소금이 생겼어! 조각도!"): the piece lies at the bottom of the seawater bucket, three lamps on
## the bucket's front. Each stamp lights a lamp (and the bread cat cheers). In stage 3 the pour
## carries the piece out onto the sun tray, where it lies under the water; the last stamp (the tray dry,
## the salt left) lifts it out of the white crust and it jumps down onto the table in front of the bread
## cat's crates; the screen then flies it to the cat. Visual only.
class_name DissolvingGame
extends LabGame

## The lamps on the bucket's front (over its foot), the piece on the tray (from the
## tray's middle), its rise (m, s) and its jump to the table in front of the cat (s; from the cat's feet).
const LAMPS_UP := 0.42
const ON_TRAY := Vector3(0.25, 0.09, 0.05)
const RISE := 0.55
const RISE_S := 0.6
const FLIGHT_S := 1.2
const LAND_FROM_CAT := Vector3(0.0, 0.0, 0.75)
const HIGHLIGHT_R := 0.75

var lamps: MeshInstance3D
var _lamps_lit := -1
var _rise_at := NEVER
var _on_tray := false


func build() -> void:
	lamps = MeshInstance3D.new()
	lamps.name = "BucketLamps"
	lamps.material_override = ArtKit.lit_material()
	add_child(lamps)
	make_piece(Vector3.ZERO, PIECE_SIZE * 0.8)
	_jump(0)


func _props() -> DissolvingProps:
	var l: Variant = host()
	return l.props if l != null and "props" in l else null


func _show_lamps(lit: int) -> void:
	if lit == _lamps_lit:
		return
	_lamps_lit = lit
	var b := ArtKit.builder()
	add_lamps(b, Vector3.ZERO, lit)
	lamps.mesh = b.commit()


## The bucket after `stamps` stamps: its lamps lit; the piece in it (hidden), or on the tray once poured.
func _jump(stamps: int) -> void:
	_rise_at = NEVER
	_show_lamps(stamps)
	_place()


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	SoundBoard.play(&"glint")
	_show_lamps(cleared)
	if last:
		_rise_at = _t


func run_reset() -> void:
	super()
	_on_tray = false
	_place()


## The clue: the bucket.
func highlight_spots() -> Array:
	var p := _props()
	return [{"at": (p.bucket.global_position if p != null else Vector3.ZERO) + Vector3.UP * 0.4, "radius": HIGHLIGHT_R}]


## Where the piece is while held: in the bucket (hidden) or under the tray's water after the pour.
func _place() -> void:
	var p := _props()
	if p == null or piece == null:
		return
	var poured := p.shown_water > 0.0 or p.shown_crust > 0.0
	_on_tray = poured and not p.pouring()
	if piece_state != "held":
		return
	piece.visible = _on_tray
	piece.position = DissolvingProps.TRAY_AT + ON_TRAY if _on_tray else p.bucket.global_position + Vector3.UP * 0.2


func _process(delta: float) -> void:
	super(delta)
	var p := _props()
	if p == null:
		return
	lamps.visible = p.bucket.visible
	lamps.position = p.bucket.global_position + Vector3(0.0, LAMPS_UP, lerpf(DissolvingProps.BUCKET.x, DissolvingProps.BUCKET.y, LAMPS_UP / DissolvingProps.BUCKET.z) + 0.03)
	if piece == null or piece_state != "held":
		return
	if running(_rise_at):
		piece.visible = true
		piece.position = DissolvingProps.TRAY_AT + ON_TRAY + Vector3.UP * RISE * eased(_rise_at, RISE_S)
		if progress(_rise_at, RISE_S) >= 1.0:
			_rise_at = NEVER
			# Out of the salt: down onto the table in front of the bread cat (up on its crates), growing on
			# the way.
			var at := cat_spot(Vector3.ZERO)
			launch_to(Vector3(at.x, KitchenSet.TABLE_TOP, at.z) + LAND_FROM_CAT, FLIGHT_S, KitchenSet.TABLE_TOP, true)
		return
	_place()
