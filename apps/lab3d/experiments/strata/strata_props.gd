## The 지층 쌓기 lab's props (#96; apps/lab3d/docs/art-direction.md): meshes only, posed from the model by
## StrataLab._redraw(). A packed-earth terrace in Hutton Island's valley, seen from the front:
## - on the left, a low wooden bench with four tin buckets, each heaped with what it holds (gravel:
##   grey-brown pebbles, sand: yellow, mud: brown, ash: pale grey with dark specks), and a shell on a
##   flat stone at its right end;
## - in the middle, the water tank on its table: a cut-away tank (no front glass: the layers' faces read
##   from the front) with a wooden frame, pale water behind and a bright waterline. Every pour settles
##   as a layer on what is already there (StrataModel: the first one ends at the bottom); a poured
##   bucket rises over the tank, tips and pours a stream while its layer grows; the shell sinks onto the
##   pile and lies in the face of the layer that buries it, a fossil;
## - on the right, the striped cliff: StrataModel.CLIFF's layers stacked (the grey ash one under the
##   top), each a little in or out of the next (ledges), grass on top, a dark crack down its face where
##   it fell (rubble at its right foot) and a glint deep in the crack on the line between two layers
##   ("어느 줄인지 모르겠어"). A dug layer shows a dark dent (the layer under the ash: a hole, the piece
##   in it, StrataGame);
## - the bread cat between the tank and the cliff, watching the tank.
## Visual only: no body, nothing the model or the mission reads.
class_name StrataProps
extends RefCounted

## The lab corner of the island is centred here (its trees stand back, clear of the bench and the cliff).
const WORLD_CENTER := Vector3(0.0, 0.0, -5.5)
## The terrace under everything.
const TERRACE := Rect2(-6.6, -2.6, 13.2, 5.4)   # x, z
const TERRACE_TOP := 0.03
const TERRACE_COLOR := Color("e2c48e")
const TERRACE_EDGE := Color("c9a46c")
## The vertical plane the buckets and the shell are dragged on (world z of their centres).
const DRAG_Z := 0.9
## The bench: its top and the buckets' places on it (x), the shell's stone (x).
const BENCH_TOP := 0.42
const BUCKET_X := [-5.6, -4.65, -3.7, -2.75]
const SHELL_X := -1.95
const STONE_TOP := 0.24
const BUCKET_RADIUS := 0.4
const BUCKET_HEIGHT := 0.72
const TIN := Color("7cc3ef")
const TIN_TOP := Color("a6d8f6")
const TIN_RIM := Color("e6f4fd")
## The tank: its inside's middle x and z, floor, size (m), the water's height, the frame.
const TANK_X := 0.35
const TANK_Z := -0.25
const TANK_FLOOR := 0.8
const TANK_SIZE := Vector3(3.2, 2.5, 1.2)
const WATER_H := 2.2
const LAYER_H := 0.55
const FRAME_W := 0.14
const WOOD := Color("c98d4f")
const WOOD_TOP := Color("dba468")
const WATER_BACK := Color("8fd0f2")
const WATER_SIDE := Color("6fbde9")
const WATERLINE := Color("e3f6ff")
## The poured bucket over the tank (offset from the tank's top middle) and its tip (rad).
const POUR_AT := Vector3(0.8, 0.15, 0.35)
const POUR_TIP := 1.75
## The cliff: its left and right x, its face's z, its depth back, a layer's height.
const CLIFF_X0 := 2.6
const CLIFF_X1 := 6.0
const CLIFF_Z := 0.25
const CLIFF_DEPTH := 2.2
const CLIFF_LAYER_H := 0.72
## How far each cliff layer's face stands out (m, bottom first): the ledges.
const LEDGES := [0.1, -0.04, 0.06, 0.0, -0.06]
const CRACK_X := 4.95
const DENT := Color("4a3324")
## The cat sits on the cliff's grass, at its right end (clear of the layers a finger taps and of the
## mission strip over the left of the view).
const CAT_AT := Vector3(5.5, CLIFF_LAYER_H * 5.0 + 0.16, -0.45)
## The materials' colours (face, light top) and their grains.
const COLORS := {
	"gravel": [Color("9b8c7c"), Color("b3a593")],
	"sand": [Color("f0cf7e"), Color("f8df9c")],
	"mud": [Color("93623e"), Color("a87650")],
	"ash": [Color("c4c8cf"), Color("dde0e5")],
}
const PEBBLES := [Color("7d7064"), Color("c9bba8"), Color("6b6f78")]
const SPECK := Color("6d7079")
const SHELL := Color("ffd9c4")
const SHELL_RIB := Color("f0a487")

var cat: CatActor
var tank: Node3D
var cliff: Node3D
## id -> the bucket node (its mesh's place: home, held, pouring).
var buckets := {}
var shell: Node3D
var _layers: MeshInstance3D
var _stream: MeshInstance3D
var _dents: MeshInstance3D
var glint: Node3D
var _tank_key: Array = []
var _dent_key: Array = []
## What is drawn now (tests): the tank's layers bottom first, their heights, the shell's place.
var shown_layers: Array = []
var shown_heights: Array = []


## A bucket's home (its centre, world).
static func bucket_home(material: String) -> Vector3:
	var i := StrataModel.MATERIALS.find(material)
	return Vector3(BUCKET_X[i], BENCH_TOP + BUCKET_HEIGHT * 0.5, DRAG_Z)


static func shell_home() -> Vector3:
	return Vector3(SHELL_X, STONE_TOP + 0.3, DRAG_Z)


## The tank's inside (world box).
static func tank_box() -> AABB:
	return AABB(Vector3(TANK_X - TANK_SIZE.x * 0.5, TANK_FLOOR, TANK_Z - TANK_SIZE.z * 0.5), TANK_SIZE)


## The tank's front face (z).
static func tank_front() -> float:
	return TANK_Z + TANK_SIZE.z * 0.5


## A point over the tank on the drag plane (a bucket let go there pours).
static func over_tank(p: Vector3) -> bool:
	return absf(p.x - TANK_X) <= TANK_SIZE.x * 0.5 + 0.35 and p.y >= TANK_FLOOR - 0.2


## Cliff layer `i`'s middle on its face (world).
static func cliff_layer_center(i: int) -> Vector3:
	return Vector3((CLIFF_X0 + CLIFF_X1) * 0.5, CLIFF_LAYER_H * (i + 0.5), CLIFF_Z + float(LEDGES[i]))


static func cliff_top() -> float:
	return CLIFF_LAYER_H * StrataModel.CLIFF.size()


## Where a dent of cliff layer `i` is (world, on its face): staggered along the layer, left of the crack.
static func dent_at(i: int) -> Vector3:
	var c := cliff_layer_center(i)
	return Vector3(CLIFF_X0 + 0.6 + 0.25 * ((i * 2) % 5), c.y, c.z + 0.012)


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	var ground := ArtKit.instance(_terrace_mesh())
	ground.name = "Terrace"
	lab.add_child(ground)
	var bench := ArtKit.instance(_bench_mesh())
	bench.name = "Bench"
	lab.add_child(bench)
	for material: String in StrataModel.MATERIALS:
		var bucket := ArtKit.instance(bucket_mesh(material))
		bucket.name = "Bucket_" + material
		bucket.position = bucket_home(material)
		lab.add_child(bucket)
		buckets[material] = bucket
	shell = ArtKit.instance(shell_mesh(0.34))
	shell.name = "Shell"
	shell.position = shell_home()
	lab.add_child(shell)
	tank = ArtKit.instance(_tank_mesh())
	tank.name = "Tank"
	lab.add_child(tank)
	_layers = MeshInstance3D.new()
	_layers.name = "TankLayers"
	_layers.material_override = ArtKit.lit_material()
	lab.add_child(_layers)
	_stream = MeshInstance3D.new()
	_stream.name = "Stream"
	_stream.material_override = ArtKit.lit_material()
	lab.add_child(_stream)
	cliff = ArtKit.instance(_cliff_mesh())
	cliff.name = "Cliff"
	lab.add_child(cliff)
	_dents = MeshInstance3D.new()
	_dents.name = "Dents"
	_dents.material_override = ArtKit.lit_material()
	lab.add_child(_dents)
	glint = ArtKit.instance(_glint_mesh(), DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE))
	glint.name = "Glint"
	glint.position = Vector3(CRACK_X, CLIFF_LAYER_H * (StrataModel.TARGET + 1), CLIFF_Z + 0.1)
	lab.add_child(glint)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = tank
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Draws the model: the tank's layers (`layers` bottom first, the newest growing by `settle`), the shell
## (`shell_at` layers under it, -1 none; sinking while it is the newest), the buckets at `places`
## (id -> world centre: home or a finger) with the newest one pouring, the dug cliff layers (`dug`,
## the newest opening by `dig`, `last_dig`).
func show(layers: Array, newest: String, settle: float, shell_at: int, places: Dictionary, dug: Dictionary, last_dig: int, dig: float) -> void:
	var pouring := newest if newest in StrataModel.MATERIALS and settle < 1.0 else ""
	for material: String in buckets:
		var bucket: Node3D = buckets[material]
		if material == pouring:
			# Up over the tank (the first fifth), tipped while it pours, back home (the last fifth).
			var go := LabGame.smooth(settle / 0.2) if settle < 0.2 else (1.0 if settle < 0.8 else 1.0 - LabGame.smooth((settle - 0.8) / 0.2))
			var tip := LabGame.smooth((settle - 0.2) / 0.15) * LabGame.smooth((0.8 - settle) / 0.15)
			var over := Vector3(TANK_X, TANK_FLOOR + TANK_SIZE.y, DRAG_Z) + POUR_AT
			bucket.position = bucket_home(material).lerp(over, go)
			bucket.rotation = Vector3(0.0, 0.0, POUR_TIP * tip)
		else:
			bucket.position = places.get(material, bucket_home(material))
			bucket.rotation = Vector3.ZERO
	var key := [layers.duplicate(), newest, snappedf(settle, 0.02), shell_at]
	if key != _tank_key:
		_tank_key = key
		_draw_tank(layers, newest, settle, shell_at)
	if shell_at < 0:
		shell.position = places.get("shell", shell_home())
		shell.rotation = Vector3.ZERO
	var dkey := [dug.keys(), last_dig, snappedf(dig, 0.02)]
	if dkey != _dent_key:
		_dent_key = dkey
		_dents.mesh = _dents_mesh(dug, last_dig, dig)


func _draw_tank(layers: Array, newest: String, settle: float, shell_at: int) -> void:
	var box := tank_box()
	var front := tank_front()
	var b := ArtKit.builder()
	b.ao_min = 0.92
	var y := box.position.y
	shown_layers = layers.duplicate()
	shown_heights = []
	var grow := LabGame.smooth(settle)
	for i in layers.size():
		var material: String = layers[i]
		var h := LAYER_H * (grow if i == layers.size() - 1 and newest == material else 1.0)
		shown_heights.append(h)
		if h > 0.005:
			_add_layer(b, Rect2(box.position.x + 0.02, y, box.size.x - 0.04, h), box.position.z + 0.02, front - 0.02, material, i)
		y += h
	# The stream from a pouring bucket's mouth down to the pile.
	var s := ArtKit.builder()
	s.ao_min = 1.0
	if newest in StrataModel.MATERIALS and settle > 0.3 and settle < 0.75:
		var from := Vector3(TANK_X, TANK_FLOOR + TANK_SIZE.y, DRAG_Z) + POUR_AT + Vector3(-0.55, -0.15, 0.0)
		var top := Vector3(from.x, y, TANK_Z + 0.2)
		var colors: Array = COLORS[newest]
		s.add_cylinder(Transform3D(Basis(), Vector3(from.x, top.y, (from.z + top.z) * 0.5)), 0.08, 0.12, from.y - top.y, 8, colors[0])
		for k in 6:
			var t := fposmod(settle * 3.0 + k / 6.0, 1.0)
			s.add_sphere(Transform3D(Basis(), Vector3(from.x + 0.18 * sin(k * 2.1), lerpf(from.y, top.y, t), top.z + 0.25)), 0.08, 2, 6, colors[0])
	_stream.mesh = s.commit()
	# The shell: on the bench until dropped, then sinking onto the pile, then in its layer's face.
	if shell_at >= 0:
		var rest := Vector3(TANK_X + 0.7, TANK_FLOOR + LAYER_H * shell_at + 0.2, front + 0.02)
		if newest == "shell" and settle < 1.0:
			var water := Vector3(rest.x, TANK_FLOOR + WATER_H, rest.z)
			shell.position = water.lerp(rest, LabGame.smooth(settle))
			shell.rotation = Vector3(0.0, 0.0, 0.6 * sin(settle * TAU) * (1.0 - settle))
		else:
			shell.position = rest
			shell.rotation = Vector3.ZERO
	_layers.mesh = b.commit()


## One layer of `material` filling `r` (x across, y up) from z `back` to `front`, its grains on the face.
static func _add_layer(b: ArtMeshBuilder, r: Rect2, back: float, front: float, material: String, seed_i: int) -> void:
	var colors: Array = COLORS[material]
	var depth := front - back
	b.add_rounded_box(Transform3D(Basis(), Vector3(r.get_center().x, r.get_center().y, back + depth * 0.5)), Vector3(r.size.x, r.size.y, depth), minf(0.03, r.size.y * 0.4), 1, colors[0], colors[1])
	_add_grains(b, r, front, material, seed_i)


## The grains on a face `r` at z `front`: pebbles for gravel, fine dots for sand, dark specks for ash.
static func _add_grains(b: ArtMeshBuilder, r: Rect2, front: float, material: String, seed_i: int) -> void:
	if r.size.y < 0.12:
		return
	var count := int(r.size.x * {"gravel": 7.0, "sand": 6.0, "mud": 2.5, "ash": 6.0}[material])
	for k in count:
		var u := fposmod((k + 0.5) * 0.618 + seed_i * 0.37, 1.0)
		var v := fposmod((k + 0.5) * 0.414 + seed_i * 0.23, 1.0)
		var p := Vector3(r.position.x + 0.08 + u * (r.size.x - 0.16), r.position.y + 0.06 + v * (r.size.y - 0.12), front + 0.01)
		match material:
			"gravel":
				var rad := 0.055 + 0.03 * float(k % 3)
				_oval(b, p, Vector2(rad * 1.25, rad), PEBBLES[k % 3])
				_oval(b, p + Vector3(-rad * 0.25, rad * 0.3, 0.004), Vector2(rad * 0.45, rad * 0.3), PEBBLES[k % 3].lightened(0.3))
			"sand":
				ArtKit.disc(b, p, 0.025, Color("d9b25f"), 6)
			"mud":
				ArtKit.disc(b, p, 0.04, Color("7d5233"), 6)
			"ash":
				ArtKit.disc(b, p, 0.022, SPECK, 6)


# --- the meshes -----------------------------------------------------------------------------------

func _terrace_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.95
	b.add_rounded_box(Transform3D(Basis(), Vector3(TERRACE.get_center().x, TERRACE_TOP * 0.5 - 0.02, TERRACE.get_center().y)), Vector3(TERRACE.size.x, TERRACE_TOP + 0.04, TERRACE.size.y), 0.03, 1, TERRACE_EDGE, TERRACE_COLOR)
	return b.commit()


## The bench under the buckets and the shell's flat stone.
func _bench_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.5
	var x0: float = BUCKET_X[0] - 0.55
	var x1: float = BUCKET_X[-1] + 0.55
	b.add_rounded_box(Transform3D(Basis(), Vector3((x0 + x1) * 0.5, BENCH_TOP - 0.05, DRAG_Z)), Vector3(x1 - x0, 0.1, 1.0), 0.03, 1, WOOD, WOOD_TOP)
	for x: float in [x0 + 0.2, x1 - 0.2]:
		for z: float in [DRAG_Z - 0.35, DRAG_Z + 0.35]:
			b.add_rounded_box(Transform3D(Basis(), Vector3(x, (BENCH_TOP - 0.1) * 0.5, z)), Vector3(0.12, BENCH_TOP - 0.1, 0.12), 0.02, 1, ArtPalette.WOOD_GRAIN)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.45, 0.8)), Vector3(SHELL_X, 0.08, DRAG_Z)), 0.48, 3, 10, DayNightProps.ROCK)
	return b.commit()


## A tin bucket (centred at the origin) heaped with `material`, a handle over it.
static func bucket_mesh(material: String) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = BUCKET_HEIGHT
	var base := Vector3(0.0, -BUCKET_HEIGHT * 0.5, 0.0)
	b.add_cylinder(Transform3D(Basis(), base), BUCKET_RADIUS * 0.78, BUCKET_RADIUS, BUCKET_HEIGHT, 14, TIN, true, TIN_TOP)
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), base + Vector3(0.0, BUCKET_HEIGHT - 0.06, 0.0)), BUCKET_RADIUS + 0.03, BUCKET_RADIUS + 0.03, 0.07, 14, TIN_RIM)
	var colors: Array = COLORS[material]
	# A band of what it holds round its middle, and the heap over the rim.
	b.add_cylinder(Transform3D(Basis(), base + Vector3(0.0, BUCKET_HEIGHT * 0.36, 0.0)), BUCKET_RADIUS * 0.9 + 0.012, BUCKET_RADIUS * 0.94 + 0.012, BUCKET_HEIGHT * 0.22, 14, colors[0], false)
	var top := base + Vector3(0.0, BUCKET_HEIGHT, 0.0)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.42, 1.0)), top), BUCKET_RADIUS * 0.95, 4, 12, colors[1])
	match material:
		"gravel":
			for k in 9:
				var a := k * 2.399963
				var r := BUCKET_RADIUS * 0.7 * sqrt((k + 0.5) / 9.0)
				b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.7, 1.0)), top + Vector3(cos(a) * r, 0.12 + 0.05 * (1.0 - r), sin(a) * r)), 0.09, 2, 7, PEBBLES[k % 3])
		"ash":
			for k in 8:
				var a := k * 2.399963
				var r := BUCKET_RADIUS * 0.7 * sqrt((k + 0.5) / 8.0)
				b.add_sphere(Transform3D(Basis(), top + Vector3(cos(a) * r, 0.15 * (1.0 - r * 1.6), sin(a) * r + 0.12)), 0.035, 2, 5, SPECK)
	# The handle: an arc over the heap, across the front.
	var arc := 10
	for k in arc:
		var a0 := PI * k / arc
		var a1 := PI * (k + 1) / arc
		var p0 := top + Vector3(-cos(a0) * (BUCKET_RADIUS + 0.04), sin(a0) * 0.42, 0.0)
		var p1 := top + Vector3(-cos(a1) * (BUCKET_RADIUS + 0.04), sin(a1) * 0.42, 0.0)
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, (p1 - p0).normalized())), p0), 0.025, 0.025, p0.distance_to(p1), 5, ArtPalette.STEEL)
	return b.commit()


## A scallop shell facing the camera (+z), `size` m tall, centred at the origin: a fan of ribs over a
## little hinge.
static func shell_mesh(size: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var hinge := Vector3(0.0, -size * 0.5, 0.0)
	var ribs := 9
	var spread := 1.25
	for k in ribs:
		var a0 := -spread + 2.0 * spread * k / ribs
		var a1 := -spread + 2.0 * spread * (k + 1) / ribs
		var p0 := hinge + Vector3(sin(a0), cos(a0), 0.0) * size
		var p1 := hinge + Vector3(sin(a1), cos(a1), 0.0) * size
		var mid := hinge + Vector3(sin((a0 + a1) * 0.5), cos((a0 + a1) * 0.5), 0.0) * size * 1.06
		var col := SHELL if k % 2 == 0 else SHELL.lerp(SHELL_RIB, 0.35)
		b.add_triangle([hinge + Vector3(0, 0, 0.06), p1 + Vector3(0, 0, 0.03), p0 + Vector3(0, 0, 0.03)], [SHELL_RIB, col, col], Vector3.BACK)
		b.add_triangle([p0 + Vector3(0, 0, 0.03), p1 + Vector3(0, 0, 0.03), mid + Vector3(0, 0, 0.03)], [col, col, col], Vector3.BACK)
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, (p0 - hinge).normalized())), hinge + Vector3(0, 0, 0.065)), 0.018, 0.008, size * 0.95, 4, SHELL_RIB, false)
	b.add_rounded_box(Transform3D(Basis(), hinge + Vector3(0.0, 0.02, 0.03)), Vector3(size * 0.5, size * 0.14, 0.08), 0.02, 1, SHELL_RIB)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.85, 0.35)), Vector3(0.0, -size * 0.05, -0.01)), size * 0.75, 3, 10, SHELL.darkened(0.08))
	return b.commit()


## The tank's table, its wooden frame (corner posts, bottom and top rails), the water behind and at its
## sides (no front glass: the layers are seen through the open front) and the bright waterline.
func _tank_mesh() -> Mesh:
	var b := ArtKit.builder()
	var box := tank_box()
	var front := tank_front()
	b.ao_min = 0.85
	b.ao_height = TANK_FLOOR
	b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, TANK_FLOOR - 0.12, TANK_Z)), Vector3(box.size.x + 0.6, 0.14, box.size.z + 0.5), 0.04, 1, WOOD, WOOD_TOP)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X + sx * (box.size.x * 0.5 + 0.1), (TANK_FLOOR - 0.19) * 0.5, TANK_Z + sz * (box.size.z * 0.5 + 0.05))), Vector3(0.16, TANK_FLOOR - 0.19, 0.16), 0.03, 1, ArtPalette.WOOD_GRAIN)
	b.ao_min = 1.0
	var water_top := TANK_FLOOR + WATER_H
	# The water: the back and the two sides (pale blue), the floor.
	b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, TANK_FLOOR + WATER_H * 0.5, box.position.z - 0.02)), Vector3(box.size.x, WATER_H, 0.04), 0.0, 1, WATER_BACK)
	for sx: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X + sx * (box.size.x * 0.5 + 0.02), TANK_FLOOR + WATER_H * 0.5, TANK_Z)), Vector3(0.04, WATER_H, box.size.z), 0.0, 1, WATER_SIDE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, TANK_FLOOR - 0.025, TANK_Z)), Vector3(box.size.x, 0.05, box.size.z), 0.0, 1, Color("5aa9d9"))
	# The empty glass above the water: a lighter back.
	b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, (water_top + TANK_FLOOR + box.size.y) * 0.5, box.position.z - 0.02)), Vector3(box.size.x, box.size.y - WATER_H, 0.04), 0.0, 1, Color("dff2fb"))
	# The waterline along the back and the front edge (the water's surface seen nearly edge-on).
	b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, water_top, TANK_Z)), Vector3(box.size.x, 0.03, box.size.z), 0.0, 1, WATERLINE)
	b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, water_top, front)), Vector3(box.size.x, 0.06, 0.04), 0.01, 1, Color("ffffff"))
	# The frame: four posts and the top and bottom rails, front and back.
	for sx: float in [-1.0, 1.0]:
		for z: float in [box.position.z - 0.04, front + 0.02]:
			b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X + sx * (box.size.x * 0.5 + FRAME_W * 0.5), TANK_FLOOR + box.size.y * 0.5, z)), Vector3(FRAME_W, box.size.y + FRAME_W, FRAME_W), 0.03, 1, WOOD, WOOD_TOP)
	for y: float in [TANK_FLOOR - FRAME_W * 0.3, TANK_FLOOR + box.size.y]:
		for z: float in [box.position.z - 0.04, front + 0.02]:
			b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X, y, z)), Vector3(box.size.x + FRAME_W * 2.0, FRAME_W * 0.8, FRAME_W), 0.03, 1, WOOD, WOOD_TOP)
		for sx: float in [-1.0, 1.0]:
			b.add_rounded_box(Transform3D(Basis(), Vector3(TANK_X + sx * (box.size.x * 0.5 + FRAME_W * 0.5), y, TANK_Z)), Vector3(FRAME_W, FRAME_W * 0.8, box.size.z), 0.03, 1, WOOD, WOOD_TOP)
	return b.commit()


## The cliff: CLIFF's layers stacked with ledges, the grass on top, the crack and the rubble.
func _cliff_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = cliff_top()
	var w := CLIFF_X1 - CLIFF_X0
	var cx := (CLIFF_X0 + CLIFF_X1) * 0.5
	for i in StrataModel.CLIFF.size():
		var material: String = StrataModel.CLIFF[i]
		var colors: Array = COLORS[material]
		var front: float = CLIFF_Z + float(LEDGES[i])
		var y0 := CLIFF_LAYER_H * i
		var wide := w + 0.12 * sin(i * 1.7)
		b.add_rounded_box(Transform3D(Basis(), Vector3(cx, y0 + CLIFF_LAYER_H * 0.5, front - CLIFF_DEPTH * 0.5)), Vector3(wide, CLIFF_LAYER_H, CLIFF_DEPTH), 0.04, 1, colors[0], colors[1])
		_add_grains(b, Rect2(cx - wide * 0.5, y0, wide, CLIFF_LAYER_H), front, material, i + 7)
	var top := cliff_top()
	b.add_rounded_box(Transform3D(Basis(), Vector3(cx, top + 0.08, CLIFF_Z - CLIFF_DEPTH * 0.5)), Vector3(w + 0.2, 0.16, CLIFF_DEPTH + 0.1), 0.06, 1, ArtPalette.GRASS, ArtPalette.GRASS_TOP)
	for k in 4:
		b.add_sphere(Transform3D(Basis(), Vector3(CLIFF_X0 + 0.5 + k * 0.9, top + 0.22, CLIFF_Z - 0.9 - 0.3 * (k % 2))), 0.25, 3, 8, ArtPalette.LEAF_LIGHT)
	# The crack: a dark zigzag down the face from the top to the second layer.
	b.ao_min = 1.0
	var pts := PackedVector2Array()
	var steps := 9
	for k in steps + 1:
		var y := top - (top - CLIFF_LAYER_H * 0.6) * k / steps
		pts.append(Vector2(CRACK_X + 0.12 * (1.0 if k % 2 == 0 else -1.0), y))
	for k in steps:
		var a := pts[k]
		var c := pts[k + 1]
		var layer := clampi(int(minf(a.y, c.y) / CLIFF_LAYER_H), 0, LEDGES.size() - 1)
		var z: float = CLIFF_Z + maxf(float(LEDGES[layer]), float(LEDGES[mini(layer + 1, LEDGES.size() - 1)])) + 0.015
		var half := 0.09 * (1.0 - 0.5 * k / steps) + 0.02
		var col := DENT
		b.add_triangle([Vector3(a.x - half, a.y, z), Vector3(c.x - half * 0.8, c.y, z), Vector3(c.x + half * 0.8, c.y, z)], [col, col, col], Vector3.BACK)
		b.add_triangle([Vector3(a.x - half, a.y, z), Vector3(c.x + half * 0.8, c.y, z), Vector3(a.x + half, a.y, z)], [col, col, col], Vector3.BACK)
	# The rubble at the right foot: fallen lumps of the layers.
	b.ao_min = 0.85
	for k in 9:
		var material: String = StrataModel.CLIFF[k % StrataModel.CLIFF.size()]
		var x := CLIFF_X1 - 0.2 + 0.32 * (k % 3) - 0.1 * float(k / 3)
		var r := 0.2 + 0.07 * float(k % 2)
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.7, 0.9)), Vector3(x, r * 0.6 + 0.12 * float(k / 3), CLIFF_Z + 0.45 - 0.15 * float(k / 3))), r, 3, 8, COLORS[material][0])
	return b.commit()


## The dug layers' dents (the newest opening by `dig`): the layer under the ash a big dark hole, the
## others a small dent with crumbs under it.
func _dents_mesh(dug: Dictionary, last_dig: int, dig: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i: int in dug:
		var open := LabGame.smooth(dig) if i == last_dig else 1.0
		if open <= 0.01:
			continue
		var at := dent_at(i)
		var big := i == StrataModel.TARGET
		var r := (0.3 if big else 0.2) * open
		_oval(b, at, Vector2(1.3, 0.85) * (r + 0.05), COLORS[StrataModel.CLIFF[i]][1].lightened(0.15))
		_oval(b, at + Vector3(0.0, -0.01, 0.006), Vector2(1.3, 0.85) * r, DENT)
		_oval(b, at + Vector3(0.0, -0.04 * open, 0.012), Vector2(1.1, 0.6) * r * 0.75, DENT.darkened(0.35))
		for k in 3:
			b.add_sphere(Transform3D(Basis(), Vector3(at.x - 0.15 + 0.15 * k, CLIFF_LAYER_H * i + 0.06, at.z + 0.18)), 0.06 * open, 2, 6, COLORS[StrataModel.CLIFF[i]][0])
	return b.commit()


## The glint in the crack: a small four-pointed sparkle facing the camera.
static func _glint_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var col := Color("fff2a8")
	for k in 4:
		var a := PI * 0.5 * k
		var tip := Vector3(cos(a), sin(a), 0.0) * 0.26
		var side := Vector3(-sin(a), cos(a), 0.0) * 0.06
		b.add_triangle([Vector3.ZERO + side, tip, Vector3.ZERO - side], [col, Color.WHITE, col], Vector3.BACK)
	ArtKit.disc(b, Vector3(0.0, 0.0, 0.005), 0.07, Color.WHITE, 10)
	return b.commit()


## A flat oval facing the camera (+z) at `c`, half sizes `half`: a pebble's face, a dent.
static func _oval(b: ArtMeshBuilder, c: Vector3, half: Vector2, color: Color, sides := 14) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		b.add_triangle([c, c + Vector3(cos(a0) * half.x, sin(a0) * half.y, 0.0), c + Vector3(cos(a1) * half.x, sin(a1) * half.y, 0.0)], [color, color, color], Vector3.BACK)
