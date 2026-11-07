## The 태풍·비구름 piece game (#94; hutton-lines.md 7: "소용돌이 한가운데 조각이 반짝여!"): a big typhoon
## turns out at sea, the piece glinting in its eye. Stages 1 and 2 (the child's cloud grows into a
## rain cloud, then a typhoon): the piece glints and the bread cat cheers. The last stage starts from
## that typhoon (the lab's own cloud takes its place: TyphoonLab.storm_run), the piece riding in its
## eye wherever the child drags it. When it has lost its strength over cold water ("바다가
## 잔잔해졌어! 조각이다!") the piece jumps out of the weakened cloud onto the island beside the cat,
## growing to the round's size on the way, and a rainbow rises over the calm sea. Visual only.
class_name TyphoonGame
extends LabGame

## The piece hides small in the eye, a little over the spiral's middle.
const HIDDEN_SIZE := 0.2
const EYE_LIFT := 0.15
## A glint (stages 1 and 2): the piece swells by GLINT_SWELL over GLINT_S.
const GLINT_S := 0.8
const GLINT_SWELL := 1.2
## The jump out (the last stage): FLIGHT_S onto the island's beach, beside the cat.
const FLIGHT_S := 1.1
const LAND_AT := Vector3(3.9, TyphoonProps.ISLAND_TOP, 0.9)
## The rainbow over the calm sea, on the far shore: its middle RAINBOW_SIDE left or right of the
## basin's middle, on the side away from the weakened cloud (#94 review: it rose behind the cloud),
## its radius (m) and the time it takes to rise.
const RAINBOW_Z := -6.8
const RAINBOW_SIDE := 3.6
const RAINBOW_R := 3.4
const RAINBOW_S := 1.4
const RAINBOW := [Color("ff5a4f"), Color("ff9440"), Color("ffd84a"), Color("5fd04a"), Color("4aa8f5"), Color("7a5cf0")]
const HIGHLIGHT_R := 1.6

## The big typhoon out at sea (the stages before the last one).
var storm: TyphoonProps.Cloud
var rainbow: Node3D
var _glint_at := NEVER
var _rainbow_at := NEVER


func build() -> void:
	storm = TyphoonProps.Cloud.new()
	storm.name = "Storm"
	add_child(storm)
	storm.build()
	storm.set_size(TyphoonModel.HOT_CAP)
	storm.position = TyphoonProps.cloud_point(TyphoonModel.STORM_START.x, TyphoonModel.STORM_START.y)
	rainbow = ArtKit.instance(_rainbow_mesh())
	rainbow.name = "Rainbow"
	rainbow.position = rainbow_at(0.0)
	add_child(rainbow)
	make_piece(_eye(), HIDDEN_SIZE)
	_jump(0)


## The typhoon's eye the piece is in: the game's typhoon, or the lab's cloud once it is that typhoon
## (both in the lab's frame: the game sits at the lab's origin).
func _eye() -> Vector3:
	var lab_: Variant = host()
	var cloud: Node3D = lab_.props.cloud if lab_ != null and lab_.storm_run() else storm
	return cloud.position + Vector3.UP * EYE_LIFT


## The game's typhoon shows until the lab's cloud is it (the last stage's run) or the sea is calm.
func storm_shown() -> bool:
	var lab_: Variant = host()
	return cleared < stages and not (lab_ != null and lab_.storm_run())


func _cleared(_stage_index: int, last: bool) -> void:
	cheer_cat(last)
	_glint_at = _t
	if last:
		_rainbow_at = _t
		rainbow.position = rainbow_at((host().props.cloud as Node3D).position.x)
		rainbow.visible = true
		# Out of the weakened cloud: up on an arc onto the island beside the cat, at the round's size.
		launch_to(LAND_AT, FLIGHT_S, TyphoonProps.ISLAND_TOP, true)


func _jump(stamps: int) -> void:
	_glint_at = NEVER
	_rainbow_at = NEVER
	rainbow.visible = stamps >= stages
	rainbow.scale = Vector3.ONE


## Where the rainbow stands for a weakened cloud at world x `cloud_x`: on the far side of the basin,
## left of its middle for a cloud on the right, else right.
static func rainbow_at(cloud_x: float) -> Vector3:
	return Vector3(-RAINBOW_SIDE if cloud_x > TyphoonModel.BASIN_CENTER.x - 1.0 else RAINBOW_SIDE, TyphoonProps.SEA_Y, RAINBOW_Z)


func highlight_radius() -> float:
	return HIGHLIGHT_R


func _process(delta: float) -> void:
	super(delta)
	storm.visible = storm_shown()
	if storm.visible:
		storm.animate(delta)
	if running(_rainbow_at):
		rainbow.scale = Vector3.ONE * maxf(0.001, eased(_rainbow_at, RAINBOW_S))
		if progress(_rainbow_at, RAINBOW_S) >= 1.0:
			_rainbow_at = NEVER
	if piece == null or piece_state != "held":
		return
	piece.position = _eye()
	piece.scale = Vector3.ONE * (1.0 + GLINT_SWELL * pulse(_glint_at, GLINT_S))
	if running(_glint_at) and progress(_glint_at, GLINT_S) >= 1.0:
		_glint_at = NEVER


## The rainbow: six bands of an arch facing the camera, standing on the sea.
static func _rainbow_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var band := 0.24
	var steps := 24
	for i in RAINBOW.size():
		var outer := RAINBOW_R - band * i
		var inner := outer - band
		var color: Color = RAINBOW[i]
		for k in steps:
			var a0 := PI * k / steps
			var a1 := PI * (k + 1) / steps
			var o0 := Vector3(cos(a0) * outer, sin(a0) * outer, 0.0)
			var o1 := Vector3(cos(a1) * outer, sin(a1) * outer, 0.0)
			var i0 := Vector3(cos(a0) * inner, sin(a0) * inner, 0.0)
			var i1 := Vector3(cos(a1) * inner, sin(a1) * inner, 0.0)
			b.add_triangle([i0, o0, o1], [color, color, color], Vector3.BACK)
			b.add_triangle([i0, o1, i1], [color, color, color], Vector3.BACK)
	return b.commit()
