## The 강물이 깎고 쌓기 piece game (#95; hutton-lines.md 8: "저기 굽은 강 바깥 언덕에 조각이 묻혀 있어!"):
## the piece is buried in the bend's outer bank, its point showing from the earth face; as the water
## cuts the face back the piece comes out of it (it stays at the face, less buried the more is cut).
## Stage 1 ("새 물길이 생겼어! 콸콸!"): the water bursts through the heap of fallen earth at the
## mountain's foot (a splash) and the heap washes away for good. Stage 2 ("모래톱이 생겼어! 거북이다!"):
## a turtle climbs onto a sand nest at the river's mouth and lays its eggs (they stay). Stage 3 (the
## outer bank cut): earth flies off the face and the piece jumps out onto the plain beside the bread
## cat, growing to the round's size on the way; the screen then flies it to the cat. Visual only.
class_name RiverGame
extends LabGame

## The piece hides small in the bank's face: its middle INSET m into the earth at the start, out
## (none) once the face is cut back by the stage's goal.
const HIDDEN_SIZE := 0.24
const INSET := 0.12
const PIECE_UP := 0.4
## The splash at the heap (stage 1): DROPLETS thrown up and out over SPLASH_S; the heap washes away in
## WASH_S.
const DROPLETS := 18
const SPLASH_S := 1.1
const SPLASH_UP := 3.2
const SPLASH_OUT := 1.4
const WASH_S := 0.9
## The turtle on its nest (stage 2): it grows in with a bounce over GROW_S.
const GROW_S := 0.8
const GROW_BOUNCE := 0.15
const SHELL := Color("3f9a52")
const SHELL_TOP := Color("6cc46a")
const SKIN := Color("9ad07a")
const EGG := Color("fff8ec")
## The bank's crumble (stage 3) and the piece's jump to the cat.
const CRUMBLE_S := 0.5
const FLIGHT_S := 1.0
const LAND_FROM_CAT := Vector3(0.4, 0.0, 1.0)
const HIGHLIGHT_R := 0.7
const VALLEY_STAGE := 0
const BAR_STAGE := 1

var turtle: Node3D
var nest: Node3D
var splash: Node3D
var _splash_at := NEVER
var _wash_at := NEVER
var _grow_at := NEVER
var _crumble_at := NEVER


func _props() -> RiverProps:
	return (host().props as RiverProps) if host() != null else null


func build() -> void:
	var p := _props()
	make_piece(_buried_at(0.0), HIDDEN_SIZE)
	nest = Node3D.new()
	nest.name = "Nest"
	var m := p.mouth()
	var out := (Vector2(RiverProps.SEA_AT.x, RiverProps.SEA_AT.z) - m).normalized()
	var at := m + out * 0.75
	nest.position = Vector3(at.x, 0.0, at.y)
	add_child(nest)
	nest.add_child(ArtKit.instance(nest_mesh()))
	turtle = ArtKit.instance(turtle_mesh())
	turtle.name = "Turtle"
	turtle.position = Vector3(-0.25, 0.12, -0.05)
	turtle.rotation = Vector3(0.0, -0.5, 0.0)
	nest.add_child(turtle)
	splash = ArtKit.instance(splash_mesh())
	splash.name = "Splash"
	splash.position = Vector3(RiverProps.HEAP_AT.x, 0.3, RiverProps.HEAP_AT.y)
	splash.visible = false
	add_child(splash)
	_jump(0)


## The piece's place for a bank cut `retreat` m back: in the face at the bend's middle, INSET into it
## at first and out of it at the goal's cut.
func _buried_at(retreat: float) -> Vector3:
	var goal := RiverModel.BANK_FULL * RiverProps.BANK_RETREAT
	var k := clampf(retreat / goal, 0.0, 1.0)
	return RiverProps.bank_face(retreat + INSET * (1.0 - k)) + Vector3.UP * PIECE_UP


func _cleared(stage_index: int, last: bool) -> void:
	cheer_cat(last)
	match stage_index:
		VALLEY_STAGE:
			_splash_at = _t
			_wash_at = _t
			splash.visible = true
			SoundBoard.play(&"glint")
		BAR_STAGE:
			_grow_at = _t
			nest.visible = true
	if last:
		_crumble_at = _t


func _jump(stamps: int) -> void:
	_set_heap(0.0 if stamps >= 1 else 1.0)
	nest.visible = stamps >= 2
	turtle.scale = Vector3.ONE
	_grow_at = NEVER
	_crumble_at = NEVER
	_wash_at = NEVER


## The heap of fallen earth (1 whole .. 0 gone): the props redraw the mountain.
func _set_heap(amount: float) -> void:
	var p := _props()
	if p == null or is_equal_approx(p.heap, amount):
		return
	p.heap = amount
	if host() != null and host().is_inside_tree():
		host()._show()


func highlight_radius() -> float:
	return HIGHLIGHT_R


## The turtle is on its nest (the second stamp).
func turtle_out() -> bool:
	return nest.visible


## The heap is gone (the first stamp).
func heap_gone() -> bool:
	return _props().heap <= 0.0


func _process(delta: float) -> void:
	super(delta)
	if running(_splash_at):
		var k := progress(_splash_at, SPLASH_S)
		if k >= 1.0:
			_splash_at = NEVER
			splash.visible = false
		else:
			splash.scale = Vector3(0.4 + k, 0.4 + k, 0.4 + k)
			splash.position.y = 0.3 + SPLASH_UP * k * (1.0 - k)
	if running(_wash_at):
		var w := eased(_wash_at, WASH_S)
		_set_heap(1.0 - w)
		if w >= 1.0:
			_wash_at = NEVER
	if running(_grow_at):
		var g := clampf(progress(_grow_at, GROW_S), 0.0, 1.0)
		turtle.scale = Vector3.ONE * maxf(0.001, (1.0 - pow(1.0 - g, 3.0)) * (1.0 + GROW_BOUNCE * sin(g * PI)))
		if g >= 1.0:
			_grow_at = NEVER
			turtle.scale = Vector3.ONE
	if piece == null or piece_state != "held":
		return
	var p := _props()
	piece.position = to_local(_buried_at(p.shown_retreat))
	if running(_crumble_at):
		var c := progress(_crumble_at, CRUMBLE_S)
		piece.scale = Vector3.ONE * (1.0 + 0.4 * sin(PI * clampf(c, 0.0, 1.0)))
		if c >= 1.0:
			_crumble_at = NEVER
			piece.scale = Vector3.ONE
			launch_to(lab_cat().global_position + LAND_FROM_CAT, FLIGHT_S, 0.0, true)


# --- the meshes -----------------------------------------------------------------------------------

## The turtle's sand nest: a low mound with three eggs half in it.
static func nest_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.3, 0.85)), Vector3(0.0, 0.0, 0.0)), 0.62, 4, 14, RiverProps.SAND)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.8, 0.3, 0.7)), Vector3(0.0, 0.02, 0.0)), 0.5, 3, 12, RiverProps.SAND_TOP)
	b.ao_min = 1.0
	for e: Vector3 in [Vector3(0.22, 0.17, 0.12), Vector3(0.36, 0.16, -0.04), Vector3(0.2, 0.15, -0.16)]:
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.9, 1.0, 0.9)), e), 0.075, 4, 8, EGG)
	return b.commit()


## A little sea turtle facing +z: a domed shell with lighter plates, a head with two eyes, four flippers.
static func turtle_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.3
	for f: Array in [[Vector3(0.2, 0.0, 0.14), 0.6], [Vector3(-0.2, 0.0, 0.14), -0.6], [Vector3(0.17, 0.0, -0.15), 2.4], [Vector3(-0.17, 0.0, -0.15), -2.4]]:
		b.add_sphere(Transform3D(Basis(Vector3.UP, float(f[1])).scaled(Vector3(0.55, 0.22, 1.0)), f[0]), 0.13, 3, 8, SKIN)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, 0.03, 0.27)), 0.09, 4, 10, SKIN)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.55, 1.15)), Vector3(0.0, 0.02, 0.0)), 0.24, 5, 12, SHELL)
	b.ao_min = 1.0
	for plate: Vector3 in [Vector3(0.0, 0.15, 0.0), Vector3(0.1, 0.12, 0.1), Vector3(-0.1, 0.12, 0.1), Vector3(0.1, 0.12, -0.1), Vector3(-0.1, 0.12, -0.1)]:
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.35, 1.0)), plate), 0.065, 3, 6, SHELL_TOP)
	for x: float in [-0.04, 0.04]:
		b.add_sphere(Transform3D(Basis(), Vector3(x, 0.07, 0.34)), 0.018, 2, 6, ArtPalette.RUBBER_RIDGE)
	return b.commit()


## The splash: DROPLETS water drops on a ring, thrown up and out (the node grows and rises).
static func splash_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in DROPLETS:
		var a := TAU * i / DROPLETS
		var r := SPLASH_OUT * (0.45 + 0.55 * fposmod(i * 0.618, 1.0))
		var up := 0.2 + 0.5 * fposmod(i * 0.414, 1.0)
		b.add_sphere(Transform3D(Basis(), Vector3(cos(a) * r * 0.6, up, sin(a) * r * 0.4)), 0.08 + 0.04 * (i % 3), 3, 6, RiverProps.DROP if i % 2 == 0 else RiverProps.STREAK)
	return b.commit()
