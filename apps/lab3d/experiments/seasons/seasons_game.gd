## The 계절 piece game (#87; hutton-lines.md 3: "조각은 언 꽃봉오리 속에 있어서, 꽃이 피는 여름을 마지막
## 단계에 둔다"): a frozen flower bud stands on the stage, ice shards round its foot and frost on its
## tip, the piece's point showing between its closed petals ("꽁꽁 언 꽃봉오리 속에 조각이 보여!").
## Stage 1, winter ("눈이 펑펑! 눈사람 완성!"): snow bursts over the stage and a snowman grows beside
## the bud. Stage 2: the bud gives a little shiver (nothing changes: "계절이 안 바뀌어!"). Stage 3,
## summer: the ice melts away, the petals open and the piece jumps out of the flower onto the stage,
## growing to the round's size on the way; the screen then flies it to the bread cat. Visual only.
class_name SeasonsGame
extends LabGame

## Inside the path, on the podium: the bud on the summer side (right), the snowman on the winter side.
const BUD_AT := Vector3(2.5, SeasonsProps.STAGE_TOP, 0.1)
const SNOWMAN_AT := Vector3(-2.5, SeasonsProps.STAGE_TOP, 0.1)
const STEM := 0.9
const PETALS := 6
const PETAL := Vector3(0.2, 0.42, 0.09)   # a petal's half sizes (across, up, thick)
const PETAL_COLOR := Color("ff7fb5")
const PETAL_TOP := Color("ffa3cb")
const FROST := Color("e9f6ff")
const ICE := Color("a9dcff")
const ICE_TOP := Color("d8f0ff")
const CENTRE := Color("ffd23a")
## The petals' lean from upright: closed and open (rad, about each petal's hinge at the bud's base).
const CLOSED := 0.16
const OPEN := 1.25
const HIDDEN_SIZE := 0.12
## A shiver (stage 2): the bud sways by SHIVER rad SHIVER_TIMES times in SHIVER_S.
const SHIVER_S := 0.9
const SHIVER := 0.12
const SHIVER_TIMES := 3.0
## The snow burst: flakes falling over the stage for SNOW_S, the snowman growing in GROW_S.
const FLAKES := 40
const SNOW_S := 2.2
const SNOW_TOP := 4.5
const GROW_S := 0.8
## The bloom: the ice shrinks and the petals open in BLOOM_S, then the piece jumps (FLIGHT_S) to its
## landing beside the cat.
const BLOOM_S := 1.0
const FLIGHT_S := 1.0
const GROW_RATE := 6.0
const LAND_FROM_CAT := Vector3(1.0, 0.0, 0.2)
const HIGHLIGHT_R := 0.75

var bud: Node3D
var snowman: Node3D
var _petals: Array[Node3D] = []
var _ice: Node3D
var _flakes: Node3D
var _snow_at := -10.0
var _grow_at := -10.0
var _shiver_at := -10.0
var _bloom_at := -10.0
var _launched := false


func build() -> void:
	bud = Node3D.new()
	bud.name = "Bud"
	bud.position = BUD_AT
	add_child(bud)
	bud.add_child(ArtKit.instance(_stem_mesh()))
	for i in PETALS:
		var hinge := Node3D.new()
		hinge.name = "Petal%d" % i
		hinge.position = Vector3(0.0, STEM, 0.0)
		hinge.rotation = Vector3(0.0, TAU * i / PETALS, 0.0)
		var petal := ArtKit.instance(_petal_mesh())
		hinge.add_child(petal)
		bud.add_child(hinge)
		_petals.append(hinge)
	_ice = ArtKit.instance(_ice_mesh())
	_ice.name = "Ice"
	bud.add_child(_ice)
	make_piece(BUD_AT + Vector3(0.0, STEM + PETAL.y * 1.55, 0.0), HIDDEN_SIZE)
	snowman = ArtKit.instance(_snowman_mesh())
	snowman.name = "Snowman"
	snowman.position = SNOWMAN_AT
	add_child(snowman)
	_flakes = ArtKit.instance(_flake_mesh())
	_flakes.name = "Snow"
	_flakes.visible = false
	add_child(_flakes)
	_jump(0)


## The petals' lean (0 closed .. 1 open) and the ice's size (1 frozen .. 0 melted).
func _set_bloom(amount: float) -> void:
	for petal in _petals:
		petal.get_child(0).rotation = Vector3(lerpf(CLOSED, OPEN, amount), 0.0, 0.0)
	_ice.scale = Vector3.ONE * maxf(0.001, 1.0 - amount)
	_ice.visible = amount < 1.0


func _cleared(stage_index: int, last: bool) -> void:
	var cat: CatActor = (host().props as SeasonsProps).cat
	if cat != null:
		cat.cheer(true, 2 if last else 1)
	match stage_index:
		0:
			_snow_at = _t
			_grow_at = _t + 0.4
			_flakes.visible = true
		1:
			_shiver_at = _t
	if last:
		_bloom_at = _t


func _jump(stamps: int) -> void:
	snowman.visible = stamps >= 1
	snowman.scale = Vector3.ONE
	_set_bloom(1.0 if stamps >= stages else 0.0)
	_grow_at = -10.0
	_bloom_at = -10.0


func highlight_radius() -> float:
	return HIGHLIGHT_R


## The bud is open (the round's last stamp).
func bloomed() -> bool:
	return not _ice.visible


func _process(delta: float) -> void:
	super(delta)
	_run_snow()
	if _shiver_at > 0.0:
		var k := (_t - _shiver_at) / SHIVER_S
		bud.rotation.z = SHIVER * sin(k * TAU * SHIVER_TIMES) * (1.0 - k) if k < 1.0 else 0.0
		if k >= 1.0:
			_shiver_at = -10.0
	if piece == null:
		return
	if piece_state == "held" and _bloom_at > 0.0:
		var o := smooth((_t - _bloom_at) / BLOOM_S)
		_set_bloom(o)
		if o >= 1.0 and not _launched:
			_launched = true
			_launch()
	elif piece_state in ["flying", "out"]:
		var grow := PIECE_SIZE / HIDDEN_SIZE
		piece.scale = piece.scale.lerp(Vector3.ONE * grow, clampf(delta * GROW_RATE, 0.0, 1.0))


## The snow burst (flakes falling and fading out) and the snowman growing with a little bounce.
func _run_snow() -> void:
	if _snow_at > 0.0:
		var k := (_t - _snow_at) / SNOW_S
		if k >= 1.0:
			_snow_at = -10.0
			_flakes.visible = false
		else:
			_flakes.position = Vector3(0.0, -SNOW_TOP * k, 0.0)
	if _grow_at > 0.0 and _t >= _grow_at:
		snowman.visible = true
		var g := clampf((_t - _grow_at) / GROW_S, 0.0, 1.0)
		snowman.scale = Vector3.ONE * maxf(0.001, (1.0 - pow(1.0 - g, 3.0)) * (1.0 + 0.15 * sin(g * PI)))
		if g >= 1.0:
			_grow_at = -10.0
			snowman.scale = Vector3.ONE


## Out of the open flower: up on an arc (the lab's gravity) that lands on the stage beside the cat.
func _launch() -> void:
	piece_size = PIECE_SIZE
	var from := piece.global_position
	var land := (host().props as SeasonsProps).cat.global_position + LAND_FROM_CAT + Vector3.UP * piece_size
	var g := lab_g()
	var v := (land - from) / FLIGHT_S + Vector3.UP * 0.5 * g * FLIGHT_S
	launch_piece(v, g, SeasonsProps.STAGE_TOP)


# --- the meshes -----------------------------------------------------------------------------------

## The stem, two leaves, the green cup under the petals and the bud's yellow heart.
static func _stem_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.4
	b.add_cylinder(Transform3D(), 0.42, 0.36, 0.12, 10, ArtPalette.SOIL, true, ArtPalette.SOIL_DEEP)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.1, 0.0)), 0.06, 0.05, STEM - 0.1, 8, ArtPalette.STEM)
	for side: float in [-1.0, 1.0]:
		var leaf := Transform3D(Basis(Vector3.BACK, side * 0.9).scaled(Vector3(1.0, 0.35, 0.6)), Vector3(side * 0.2, STEM * 0.45, 0.0))
		b.add_sphere(leaf, 0.26, 3, 8, ArtPalette.LEAF)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.6, 1.0)), Vector3(0.0, STEM, 0.0)), 0.16, 3, 8, ArtPalette.STEM)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, STEM + 0.12, 0.0)), 0.1, 3, 8, CENTRE)
	return b.commit()


## One petal standing on its hinge (local y up, leaning out along +z when the hinge tips it), its
## tip white with frost.
static func _petal_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = PETAL.y * 2.0
	b.add_sphere(Transform3D(Basis.from_scale(PETAL), Vector3(0.0, PETAL.y, 0.07)), 1.0, 4, 8, PETAL_COLOR)
	b.add_sphere(Transform3D(Basis.from_scale(PETAL * Vector3(0.7, 0.35, 1.05)), Vector3(0.0, PETAL.y * 1.7, 0.08)), 1.0, 3, 8, PETAL_TOP)
	return b.commit()


## Ice shards leaning on the bud and frost on its tip.
static func _ice_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var lean := Basis(Vector3(cos(a), 0.0, -sin(a)).cross(Vector3.UP).normalized(), -0.35)
		var height := 0.55 + 0.25 * float(i % 3)
		var foot := Vector3(cos(a), 0.0, -sin(a)) * 0.34 + Vector3(0.0, 0.08, 0.0)
		b.add_cylinder(Transform3D(lean, foot), 0.13, 0.0, height, 5, ICE, true, ICE_TOP)
	for i in 5:
		var a := TAU * i / 5.0
		b.add_sphere(Transform3D(Basis(), Vector3(cos(a) * 0.14, STEM + PETAL.y * 1.75, -sin(a) * 0.14)), 0.1, 3, 6, FROST)
	return b.commit()


## A snowman: three balls, coal eyes, a carrot nose, a red scarf, twig arms.
static func _snowman_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 1.6
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, 0.42, 0.0)), 0.45, 5, 12, FROST)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, 1.05, 0.0)), 0.33, 5, 12, FROST)
	b.add_sphere(Transform3D(Basis(), Vector3(0.0, 1.55, 0.0)), 0.25, 5, 12, FROST)
	b.ao_min = 1.0
	for x: float in [-0.08, 0.08]:
		b.add_sphere(Transform3D(Basis(), Vector3(x, 1.6, 0.22)), 0.035, 2, 6, ArtPalette.RUBBER_RIDGE)
	for k in 3:
		b.add_sphere(Transform3D(Basis(), Vector3(0.0, 1.18 - k * 0.14, 0.31 - k * 0.012)), 0.035, 2, 6, ArtPalette.RUBBER_RIDGE)
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 1.55, 0.22)), 0.045, 0.0, 0.22, 6, ArtPalette.ORANGE)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 1.3, 0.0)), 0.3, 0.3, 0.1, 12, ArtPalette.RED, true, ArtPalette.RED_TOP)
	b.add_rounded_box(Transform3D(Basis(Vector3.BACK, 0.2), Vector3(0.14, 1.12, 0.26)), Vector3(0.1, 0.32, 0.04), 0.02, 1, ArtPalette.RED)
	for side: float in [-1.0, 1.0]:
		b.add_cylinder(Transform3D(Basis(Vector3.BACK, side * -1.0), Vector3(side * 0.3, 1.1, 0.0)), 0.025, 0.018, 0.5, 5, ArtPalette.TRUNK)
	return b.commit()


## The snow burst's flakes: a golden-angle scatter over the front of the stage, from SNOW_TOP up.
static func _flake_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in FLAKES:
		var r := 4.5 * sqrt((i + 0.5) / FLAKES)
		var a := i * 2.399963
		var p := Vector3(-2.5 + cos(a) * r * 0.6, SNOW_TOP + fposmod(i * 0.618, 1.0) * 2.5, 0.5 + sin(a) * r * 0.5)
		b.add_sphere(Transform3D(Basis(), p), 0.07 + 0.03 * (i % 3), 2, 6, Color.WHITE)
	return b.commit()
