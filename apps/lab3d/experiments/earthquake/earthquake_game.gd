## The 지진 piece game (#97; hutton-lines.md 10: "어, 마을 뒤 언덕에 조각이 보여! 집들이 튼튼해야 저기까지
## 안전하게 갈 수 있겠어."): a little grassy hill behind the village, the piece glinting on its top in a
## nest of stones, and at the hill's foot a signpost with three lamps. Each stamp lights a lamp and
## the piece glints (the houses are getting sturdy); the last stamp lights the third, the stones fall
## open and the piece hops down off the hill to the table's front, by the bread cat, growing to the round's size on the way.
## Visual only (LabGame).
class_name EarthquakeGame
extends LabGame

## The hill (local to the game = the lab), its radius and height; the piece's nest on its top.
const HILL_AT := Vector3(-4.6, 0.0, -6.6)
const HILL_RADIUS := 2.2
const HILL_HEIGHT := 1.5
const NEST_STONES := 6
const STONE := Color("aab3c4")
const STONE_TOP := Color("c3cad6")
const HIDDEN_SIZE := 0.22
## The signpost with the three lamps at the hill's foot (towards the table).
const SIGN_AT := Vector3(-2.5, 0.0, -5.0)
const SIGN_HEIGHT := 1.5
const LAMP_SIZE := 0.13
const LAMP_SPACING := 0.34
## A glint: the piece swells by GLINT_SWELL and back in GLINT_S. The nest's stones fall open in OPEN_S,
## then the piece hops (FLIGHT_S) to its landing beside the cat.
const GLINT_S := 0.5
const GLINT_SWELL := 0.6
const OPEN_S := 0.5
const FLIGHT_S := 1.1
## Where its arc first lands: the table's front left of the bread cat; its two small hops carry it on
## about a metre and a half towards the camera, still clear of the dialogue box.
const LAND_AT := EarthquakeProps.CAT_AT + Vector3(-1.9, 0.0, -1.6)
const HIGHLIGHT_R := 0.9

var hill: Node3D
var _stones: Array[Node3D] = []
var _lamps: MeshInstance3D
var _lit := 0
var _glint_at := NEVER
var _open_at := NEVER


func build() -> void:
	hill = ArtKit.instance(_hill_mesh())
	hill.name = "Hill"
	hill.position = HILL_AT
	add_child(hill)
	var top := HILL_AT + Vector3(0.0, HILL_HEIGHT, 0.0)
	for i in NEST_STONES:
		var a := TAU * i / NEST_STONES
		var stone := ArtKit.instance(_stone_mesh(i))
		stone.name = "Stone%d" % i
		stone.position = top + Vector3(cos(a) * 0.3, 0.0, sin(a) * 0.3)
		stone.rotation = Vector3(0.0, -a, 0.0)
		add_child(stone)
		_stones.append(stone)
	var post := ArtKit.instance(_sign_mesh())
	post.name = "Sign"
	post.position = SIGN_AT
	add_child(post)
	_lamps = MeshInstance3D.new()
	_lamps.name = "Lamps"
	_lamps.position = SIGN_AT + Vector3(0.0, SIGN_HEIGHT + 0.05, 0.12)
	add_child(_lamps)
	make_piece(top + Vector3(0.0, HIDDEN_SIZE + 0.12, 0.0), HIDDEN_SIZE)
	_jump(0)


func _set_lamps(lit: int) -> void:
	_lit = lit
	var b := ArtKit.builder()
	LabGame.add_lamps(b, Vector3.ZERO, lit, LAMP_SPACING, LAMP_SIZE)
	_lamps.mesh = b.commit()


func lamps_lit() -> int:
	return _lit


## The nest's stones lean out by `open` (0 closed .. 1 fallen open).
func _set_open(open: float) -> void:
	for i in _stones.size():
		_stones[i].rotation = Vector3(0.0, -TAU * i / NEST_STONES, -open * 1.3)


func opened() -> bool:
	return not _stones.is_empty() and _stones[0].rotation.z < -1.2


func _cleared(stage_index: int, last: bool) -> void:
	cheer_cat(last)
	_set_lamps(stage_index + 1)
	_glint_at = _t
	if last:
		_open_at = _t


func _jump(stamps: int) -> void:
	_set_lamps(stamps)
	_set_open(1.0 if stamps >= stages else 0.0)
	_open_at = NEVER
	_glint_at = NEVER


func highlight_spots() -> Array:
	return [{"at": HILL_AT + Vector3(0.0, HILL_HEIGHT + 0.2, 0.0), "radius": HIGHLIGHT_R, "flat": false}]


func _process(delta: float) -> void:
	super(delta)
	if piece == null or piece_state != "held":
		return
	piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * pulse(_glint_at, GLINT_S))
	if due(_glint_at + GLINT_S):
		_glint_at = NEVER
	if running(_open_at):
		var o := eased(_open_at, OPEN_S)
		_set_open(o)
		if o >= 1.0:
			_open_at = NEVER
			launch_to(LAND_AT, FLIGHT_S, 0.0, true)


# --- the meshes -----------------------------------------------------------------------------------

## The hill: a round grassy mound (a few stacked rings), a dirt path up its front.
static func _hill_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.8
	var rings := 4
	for k in rings:
		var r0 := HILL_RADIUS * cos(PI * 0.5 * k / rings)
		var r1 := HILL_RADIUS * cos(PI * 0.5 * (k + 1) / rings)
		var y0 := HILL_HEIGHT * sin(PI * 0.5 * k / rings)
		var y1 := HILL_HEIGHT * sin(PI * 0.5 * (k + 1) / rings)
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, y0, 0.0)), r0, maxf(r1, 0.35), y1 - y0, 16, ArtPalette.GRASS, true, ArtPalette.GRASS_TOP)
	b.ao_min = 1.0
	for k in 5:
		var share := (k + 0.5) / 5.0
		var r := HILL_RADIUS * (1.0 - share) + 0.2
		var y := HILL_HEIGHT * sin(PI * 0.5 * clampf(share * 1.05, 0.0, 1.0))
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, 0.4), Vector3(r * 0.42, y + 0.02, r * 0.92)), Vector3(0.5, 0.05, 0.32), 0.02, 1, ArtPalette.PATH)
	return b.commit()


## A stone of the nest (its foot at the origin, leaning out about its outer foot when opened).
static func _stone_mesh(i: int) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.3
	var h := 0.36 + 0.08 * float(i % 3)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, h * 0.5, 0.0)), Vector3(0.26, h, 0.2), 0.06, 1, STONE, STONE_TOP)
	return b.commit()


## The signpost: a wooden post, a board for the lamps and a little roof over them.
static func _sign_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.4
	b.add_cylinder(Transform3D(), 0.08, 0.07, SIGN_HEIGHT + 0.25, 8, ArtPalette.TRUNK)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SIGN_HEIGHT + 0.05, 0.0)), Vector3(LAMP_SPACING * 3.0 + 0.1, 0.32, 0.12), 0.04, 1, ArtPalette.WOOD, ArtPalette.CRATE_TOP)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SIGN_HEIGHT + 0.27, 0.05)), Vector3(LAMP_SPACING * 3.0 + 0.3, 0.07, 0.3), 0.02, 1, ArtPalette.RED, ArtPalette.RED_TOP)
	return b.commit()
