## The 화산 piece game (#98; hutton-lines.md 11: "저기 분화구 안에 뭔가 반짝여! 바늘 같아!"): the sundial's
## needle (the golden pointer of the island's sundial, MapLandmarks.sundial) lies in the big volcano's
## crater, only its tip showing, with the piece glinting on it. Stages 1 and 2 (the small model): the
## needle glints in the crater and the crater puffs. Stage 3, the big scene (hutton.md "화산(큰
## 장면)"): the lava has reached the sea in the night; the steam bursts up, the new land grows out
## into the sea and the needle is pushed up out of the crater, glowing; then the piece jumps off its
## tip and lands beside the bread cat (the screen then flies it to the cat's paws). The needle stays
## up on the rim. Visual only.
class_name VolcanoGame
extends LabGame

## The needle: its length and blade (m), how far it is sunk in the crater at first (only its tip, with
## the piece on it, at the rim) and how far it stands up out of the rim when pushed up. A broad, thick
## blade turned with its face to the front view (2026-11-07 user: edge-on it read as a thin bar).
const NEEDLE_LENGTH := 2.1
const NEEDLE_BLADE := Vector2(1.1, 0.34)
## The blade's turn (rad round y): its broad face towards the front camera.
const NEEDLE_TURN := -0.36
const SUNK := Vector3(-0.3, -NEEDLE_LENGTH - 0.07, 0.1)   # the tip just over the rim: a glint
## Risen: its broad foot at the rim (all of the blade shows), leaning left, clear of the smoke that
## drifts right.
const RISEN := Vector3(-0.3, -0.05, 0.1)
const NEEDLE_COLOR := ArtPalette.YELLOW
const NEEDLE_TOP := ArtPalette.YELLOW_TOP
const HIDDEN_SIZE := 0.13
## A glint (stages 1 and 2): the needle's tip swells for GLINT_S.
const GLINT_S := 0.9
const GLINT_SWELL := 0.8
## The big scene: the land grows over LAND_S, the needle rises from RISE_AT_S for RISE_S, the piece
## jumps at JUMP_AT_S (FLIGHT_S to the cat).
const LAND_S := 2.6
const RISE_AT_S := 0.7
const RISE_S := 1.6
const JUMP_AT_S := 2.7
const FLIGHT_S := 2.0
## Where the piece comes down: AIM_SHARE of the way along the new land (its hops carry it further
## out), whose top is LAND_TOP over the ground.
const AIM_SHARE := 0.15
const LAND_TOP := 0.3
const HIGHLIGHT_R := 1.1
## The needle's little shake on the way up (pushed by the lava): its size and speed.
const SHAKE_SIZE := 0.04
const SHAKE_SPEED := 31.0

var needle: Node3D
var _glint_at := NEVER
var _scene_at := NEVER
var _land_from := 0.0


func build() -> void:
	needle = Node3D.new()
	needle.name = "Needle"
	add_child(needle)
	needle.add_child(ArtKit.instance(_needle_mesh(), StarArt.glow_material()))
	_set_rise(0.0)
	make_piece(_tip(), HIDDEN_SIZE)
	_jump(0)


## The needle between sunk (0) and risen (1) in the crater, leaning a little.
func _set_rise(k: float) -> void:
	var top := VolcanoProps.crater_top()
	needle.position = top + SUNK.lerp(RISEN, k)
	needle.rotation = Vector3(0.0, NEEDLE_TURN, 0.12 + 0.18 * k)   # leaning left, out of the top band


## The needle's tip (game local: the game sits at the lab's origin).
func _tip() -> Vector3:
	return needle.position + needle.basis * Vector3(0.0, NEEDLE_LENGTH + 0.12, 0.0)


func risen() -> bool:
	return needle.position.distance_to(VolcanoProps.crater_top() + RISEN) < 0.05


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	_glint_at = _t
	if last:
		_scene_at = _t
		var props: VolcanoProps = host().props
		_land_from = props.shown_land
		props.steam_burst()


func _jump(stamps: int) -> void:
	_scene_at = NEVER
	_glint_at = NEVER
	var done := stamps >= stages
	_set_rise(1.0 if done else 0.0)
	var l: Variant = host()
	if l != null and l.props != null:
		var props: VolcanoProps = l.props
		props.land_boost = 1.0 if done else 0.0
		props.set_land(1.0 if done else props.shown_land)


func highlight_spots() -> Array:
	return [{"at": VolcanoProps.crater_top() + Vector3(0.0, 0.2, 0.0), "radius": HIGHLIGHT_R}]


func _process(delta: float) -> void:
	super(delta)
	if piece != null and piece_state == "held":
		piece.position = _tip()
		piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * pulse(_glint_at, GLINT_S))
	if due(_glint_at + GLINT_S):
		_glint_at = NEVER
	if running(_scene_at):
		_run_scene()


## The big scene: the steam bursts, the land grows to all of it, the needle rises, the piece jumps.
func _run_scene() -> void:
	var props: VolcanoProps = host().props
	var grow := eased(_scene_at, LAND_S)
	props.land_boost = lerpf(_land_from, 1.0, grow)
	props.set_land(maxf(props.land_boost, props.shown_land))
	var rise := smooth(progress(_scene_at + RISE_AT_S, RISE_S))
	_set_rise(rise)
	if rise > 0.0:   # a little shake on the way up, pushed by the lava
		needle.position.x += SHAKE_SIZE * sin(_t * SHAKE_SPEED) * (1.0 - rise)
	if piece_state == "held" and _t >= _scene_at + JUMP_AT_S:
		var spot := VolcanoProps.shore() + VolcanoProps.flow_dir() * VolcanoProps.LAND_LENGTH * AIM_SHARE
		launch_to(Vector3(spot.x, LAND_TOP, spot.z), FLIGHT_S, LAND_TOP, true)
	if progress(_scene_at, JUMP_AT_S + FLIGHT_S) >= 1.0:
		_scene_at = NEVER
		_set_rise(1.0)


## The needle: a golden blade (the sundial's gnomon: a long thin wedge) on a round foot, along +y.
static func _needle_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := NEEDLE_BLADE.y * 0.5
	var edge := NEEDLE_COLOR.darkened(0.3)   # the blade's thick edges a deeper gold: it reads solid
	var edge_top := NEEDLE_TOP.darkened(0.25)
	var w := NEEDLE_BLADE.x
	var tip := Vector3(0.0, NEEDLE_LENGTH, 0.0)
	for side: float in [-1.0, 1.0]:
		var z := Vector3(0.0, 0.0, side * half)
		b.add_triangle([Vector3.ZERO + z, Vector3(w, 0.0, 0.0) + z, tip + z], [NEEDLE_COLOR, NEEDLE_COLOR, NEEDLE_TOP], Vector3(0.0, 0.0, side))
	b.add_triangle([Vector3(w, 0.0, -half), Vector3(w, 0.0, half), tip + Vector3(0.0, 0.0, half)], [edge, edge, edge_top], Vector3(1.0, 0.3, 0.0))
	b.add_triangle([Vector3(w, 0.0, -half), tip + Vector3(0.0, 0.0, half), tip + Vector3(0.0, 0.0, -half)], [edge, edge_top, edge_top], Vector3(1.0, 0.3, 0.0))
	b.add_triangle([Vector3(0.0, 0.0, -half), tip + Vector3(0.0, 0.0, half), Vector3(0.0, 0.0, half)], [edge, edge_top, edge], Vector3.LEFT)
	b.add_triangle([Vector3(0.0, 0.0, -half), tip + Vector3(0.0, 0.0, -half), tip + Vector3(0.0, 0.0, half)], [edge, edge_top, edge_top], Vector3.LEFT)
	b.add_cylinder(Transform3D(Basis(), Vector3(w * 0.4, -0.12, 0.0)), 0.5, 0.42, 0.18, 12, NEEDLE_COLOR.darkened(0.2), true, NEEDLE_COLOR)
	return b.commit()
