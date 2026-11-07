## The 강물이 깎고 쌓기 lab's props (#95; apps/lab3d/docs/art-direction.md): meshes only, posed from the
## model by RiverLab._redraw(). World axes: x right, y up, z towards the camera (the front view).
## From right to left, one river from the mountain to the sea (the tall mountain and its cloud on the
## right, clear of the title, the card and the mission strip on the top left):
## - the mountain (back right): a ridge whose front face runs down to the left at the land's slope
##   (the condition: gentle or steep, RiverModel.GENTLE_DEG / STEEP_DEG), a heightfield. Down its
##   middle runs the river's channel; the valley the water cuts deepens it (a V of bare soil, as deep
##   as the model's valley_depth() times GROOVE_MAX). At its foot lies the heap of fallen earth that
##   blocked the river (the fox's "흙이 무너져서 강이 막혀 버렸어"); the cut goes through it, and the
##   game washes it away at the first stamp (set_heap);
## - the cloud (the watering can) over the mountain's top: the thing a finger holds; while it is held
##   rain falls from it and the water runs down the channel and the river (white streaks moving along
##   them, faster on the steep land);
## - the river on the plain: in from the mountain's foot, round one bend that swings away from the
##   camera, then out to the sea (front left). The bend's outer bank is a low earth cliff whose face
##   (towards the camera) is cut back by the model's bank_cut() (the piece is buried in it:
##   RiverGame); on its inner side a sand bar grows (inner_bar());
## - the sea (left) with its beach: where the river meets it the sand bar grows (mouth_bar()), or,
##   on the steep land, a muddy plume goes out to sea (washed());
## - the bread cat behind the bend's right end (between it and the mountain), watching the bank; Puppy
##   stands at the bend's left, so the two have room.
## No number anywhere. Visual only: no body, nothing the model reads.
class_name RiverProps
extends RefCounted

## The mountain: its top ridge, its foot (the front face runs from the top down to the foot at the
## land's slope), its back end, the channel's z, the ridge's flat half width and its shoulders.
const TOP_X := 4.3
const FOOT_X := 1.5
const BACK_X := 6.1
const CHANNEL_Z := -0.6
const RIDGE_HALF := 0.75
const SHOULDER := 1.1
## The heightfield's grid: from FIELD_END_X to BACK_X, CHANNEL_Z +- FIELD_HALF_Z, GRID m apart.
const FIELD_END_X := 0.5
const FIELD_HALF_Z := 2.0
const GRID := 0.14
## The channel: always a shallow groove (BASE_GROOVE), cut down by the valley (GROOVE_MAX at the
## steep land's deepest); its half width grows with its depth.
const BASE_GROOVE := 0.06
const GROOVE_MAX := 0.85
const GROOVE_HALF := 0.28
const GROOVE_WIDEN := 0.8
## The heap of fallen earth at the mountain's foot (centre x, z; radius; height).
const HEAP_AT := Vector2(1.25, -0.6)
const HEAP_RADIUS := 0.85
const HEAP_HEIGHT := 0.55
## The cloud over the mountain's top (its middle, its size) and the rain under it (drops in a box).
const CLOUD_AT := Vector3(3.3, 3.3, -0.6)
const CLOUD_RADIUS := 0.85
## The cloud bobs gently up and down (m, s a bob), visual only (the knob stays at CLOUD_AT).
const CLOUD_BOB := 0.07
const CLOUD_BOB_S := 3.6
const DROPS := 46
const RAIN_TOP := 2.8
const RAIN_SPAN := Vector2(1.5, 0.6)   # half extents in x and z under the cloud
const RAIN_SPEED := 6.0
const DROP := Color("7cc6ff")
## The river on the plain: its control points (x, z; a Catmull-Rom line through them), its half width
## (wider at the mouth), how high its water and its sandy edges lie.
const RIVER_POINTS := [Vector2(1.75, -0.6), Vector2(1.0, -0.55), Vector2(0.66, -0.78), Vector2(-0.04, -1.52),
	Vector2(-0.9, -1.9), Vector2(-1.84, -1.52), Vector2(-2.34, -0.71), Vector2(-2.6, 0.0), Vector2(-3.0, 0.45),
	Vector2(-3.45, 0.75), Vector2(-3.95, 0.95)]
const RIVER_STEPS := 8                # samples between two control points
const RIVER_HALF := 0.36
const MOUTH_HALF := 0.55
const WATER_Y := 0.035
const EDGE_Y := 0.02
const EDGE_WIDTH := 0.16
const WATER := ArtPalette.RIVER
const WATER_EDGE := ArtPalette.RIVER_EDGE
const RIVER_SAND := Color("e8d29a")
## The bend's outer bank: an earth cliff along the river's outer side where it bends (the points
## with z under BEND_Z), BANK_HEIGHT tall, BANK_DEPTH deep, its face cut back by up to BANK_RETREAT
## (at the model's whole side_power, the most at the bend's middle).
const BEND_Z := -1.2
const BANK_HEIGHT := 1.0
const BANK_DEPTH := 1.0
const BANK_RETREAT := 0.9
const BANK_SOIL := Color("b8743f")
const BANK_STRIPE := Color("cf9152")
const BANK_DARK := Color("9a5c2e")
## The sand bars: the bend's inner one, the mouth's (both grow from nothing), the plume's mud.
const SAND := Color("f3d88c")
## The bend's inner bar: its mounds' radius (m, at the bend's middle), how much taller than the
## mouth's they stand, how far in from the water they spread as it grows (#95 review: big on a phone).
const INNER_R := 0.62
const INNER_TALL := 1.4
const INNER_OUT := 0.3
const SAND_TOP := Color("f8e6a8")
const MUD := Color("b08a5a")
## The sea (front left): its middle and half sizes (x, z), its beach around it.
const SEA_AT := Vector3(-4.8, 0.0, 1.15)
const SEA_HALF := Vector2(1.7, 1.6)
const BEACH := 0.45
const SEA := ArtPalette.SEA
const SEA_SHALLOW := ArtPalette.SEA_SHALLOW
## The flow: STREAKS white streaks moving down the channel and the river while it rains (and for
## FLOW_AFTER_S after), FLOW_SPEED m/s times the model's speed.
const STREAKS := 16
const FLOW_SPEED := 2.4
const FLOW_AFTER_S := 1.2
const STREAK := Color("eaf7ff")
## The lab's corner of the island: its trees stand clear of the mountain and the sea.
const WORLD_CENTER := Vector3(-0.6, 0.0, -9.0)
const CAT_AT := Vector3(1.4, 0.0, -2.6)

var cat: CatActor
var cloud: Node3D
var cloud_body: MeshInstance3D
var mountain: MeshInstance3D
var stream: MeshInstance3D           # the water down the channel (while it flows)
var bank: MeshInstance3D
var inner_bar: MeshInstance3D
var mouth_bar: MeshInstance3D
var plume: MeshInstance3D
var rain: Node3D
var bright_material: ShaderMaterial
## The heap of fallen earth (1: whole, 0: washed away; the game's).
var heap := 1.0
## What show() drew last (tests): the slope (deg), the valley's depth (m), the bank's retreat at the
## bend's middle (m), the bars' sizes (0..1).
var shown_slope := 0.0
var shown_depth := 0.0
var shown_retreat := 0.0
var shown_inner := 0.0
var shown_mouth := 0.0
var shown_washed := 0.0
var raining := false
var _line := PackedVector2Array()     # the river's middle (x, z)
var _flow := PackedVector3Array()     # the water's way: down the channel, then the river to the sea
var _flow_length := 0.0
var _streaks: Array[MeshInstance3D] = []
var _flow_speed := 1.0
var _flow_s := 0.0
var _flow_left := 0.0
var _rain_s := 0.0
var _bob_s := 0.0
var _drops: Array[MeshInstance3D] = []
var _key := []


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	bright_material = DayNightProps.lit_towards(Vector3.BACK, Color.WHITE, Color.WHITE)
	_line = river_line()
	var sea := ArtKit.instance(_sea_mesh())
	sea.name = "Sea"
	lab.add_child(sea)
	var river := ArtKit.instance(_river_mesh(_line))
	river.name = "River"
	lab.add_child(river)
	mountain = MeshInstance3D.new()
	mountain.name = "Mountain"
	mountain.material_override = ArtKit.lit_material()
	lab.add_child(mountain)
	stream = MeshInstance3D.new()
	stream.name = "Stream"
	stream.material_override = ArtKit.lit_material()
	lab.add_child(stream)
	bank = MeshInstance3D.new()
	bank.name = "Bank"
	bank.material_override = ArtKit.lit_material()
	lab.add_child(bank)
	inner_bar = MeshInstance3D.new()
	inner_bar.name = "InnerBar"
	inner_bar.material_override = ArtKit.lit_material()
	lab.add_child(inner_bar)
	mouth_bar = MeshInstance3D.new()
	mouth_bar.name = "MouthBar"
	mouth_bar.material_override = ArtKit.lit_material()
	lab.add_child(mouth_bar)
	plume = MeshInstance3D.new()
	plume.name = "Plume"
	plume.material_override = ArtKit.lit_material()
	lab.add_child(plume)
	cloud = Node3D.new()
	cloud.name = "Cloud"
	cloud.position = CLOUD_AT
	lab.add_child(cloud)
	cloud_body = ArtKit.instance(MapIsland.cloud_mesh(CLOUD_RADIUS), MapIsland.cloud_material())
	cloud_body.name = "Puffs"
	cloud.add_child(cloud_body)
	rain = Node3D.new()
	rain.name = "Rain"
	rain.visible = false
	lab.add_child(rain)
	var drop := _drop_mesh()
	for i in DROPS:
		var d := ArtKit.instance(drop, bright_material)
		d.name = "Drop%d" % i
		d.position = drop_at(i, 0.0)
		rain.add_child(d)
		_drops.append(d)
	var streak := _streak_mesh()
	for i in STREAKS:
		var s := ArtKit.instance(streak, bright_material)
		s.name = "Streak%d" % i
		s.visible = false
		lab.add_child(s)
		_streaks.append(s)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = bank
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Draws the land at `slope` deg with the valley cut `valley` (0..1 of the steep land's deepest), the
## bend's bank cut `bank_cut` (model units: BANK_RETREAT at 1), its inner bar `inner`, the mouth's bar
## `mouth` and the sand washed out to sea `washed` (0..1). `water_speed`: the flow's speed share.
func show(slope: float, valley: float, bank_cut: float, inner: float, mouth: float, washed: float, water_speed: float) -> void:
	_flow_speed = water_speed
	var depth := valley * GROOVE_MAX
	var key := [snappedf(slope, 0.01), snappedf(depth, 0.005), snappedf(bank_cut, 0.005), snappedf(inner, 0.01),
		snappedf(mouth, 0.01), snappedf(washed, 0.01), snappedf(heap, 0.01)]
	if key == _key:
		return
	_key = key
	shown_slope = slope
	shown_depth = depth
	shown_retreat = bank_cut * BANK_RETREAT
	shown_inner = inner
	shown_mouth = mouth
	shown_washed = washed
	mountain.mesh = mountain_mesh(slope, depth, heap)
	stream.mesh = _stream_mesh(slope, depth)
	_flow = _flow_line(slope, depth)
	_flow_length = 0.0
	for i in range(1, _flow.size()):
		_flow_length += _flow[i].distance_to(_flow[i - 1])
	bank.mesh = _bank_mesh(shown_retreat)
	inner_bar.mesh = _inner_bar_mesh(inner)
	mouth_bar.mesh = _mouth_bar_mesh(mouth)
	plume.mesh = _plume_mesh(washed)


## Rain falls (and the water flows) while `on`; the water keeps running FLOW_AFTER_S after.
func set_raining(on: bool) -> void:
	raining = on
	rain.visible = on
	if on:
		_flow_left = FLOW_AFTER_S


## The rain and the flow streaks move (the lab's _process).
func animate(delta: float) -> void:
	_bob_s += delta
	cloud_body.position = Vector3.UP * CLOUD_BOB * sin(TAU * _bob_s / CLOUD_BOB_S)
	if raining:
		_rain_s = fposmod(_rain_s + RAIN_SPEED * delta, RAIN_TOP)
		for i in _drops.size():
			_drops[i].position = drop_at(i, _rain_s)
		cloud_body.scale = Vector3(1.06, 0.93, 1.06)
	else:
		_flow_left = maxf(0.0, _flow_left - delta)
		cloud_body.scale = Vector3.ONE
	var flowing := raining or _flow_left > 0.0
	stream.visible = flowing
	if _flow_length <= 0.0:
		return
	_flow_s = fposmod(_flow_s + FLOW_SPEED * _flow_speed * delta, _flow_length)
	for i in _streaks.size():
		var s: MeshInstance3D = _streaks[i]
		s.visible = flowing
		if not flowing:
			continue
		var along := fposmod(_flow_s + _flow_length * i / _streaks.size(), _flow_length)
		s.transform = _on_flow(along)


## The water is running now (rain, or just after).
func flowing() -> bool:
	return raining or _flow_left > 0.0


# --- the mountain ---------------------------------------------------------------------------------

## The mountain's height at (x, z) for the land at `slope` deg before its channel is cut: the front face
## falls at the slope from TOP_X (its top) left to FOOT_X, the back falls to BACK_X, the sides round off.
static func land_height(slope: float, x: float, z: float) -> float:
	var top := (TOP_X - FOOT_X) * tan(deg_to_rad(slope))
	var along := 0.0
	if x >= FOOT_X and x <= TOP_X:
		along = (x - FOOT_X) / (TOP_X - FOOT_X)
		along += 0.04 * sin(PI * along)   # a little round over the face
	elif x > TOP_X and x < BACK_X:
		along = LabGame.smooth((BACK_X - x) / (BACK_X - TOP_X))
	var across := LabGame.smooth((RIDGE_HALF + SHOULDER - absf(z - CHANNEL_Z)) / SHOULDER)
	return top * clampf(along, 0.0, 1.0) * across


## The heap's height at (x, z) (`heap` 0..1 of it).
static func heap_height(x: float, z: float, heap_share: float) -> float:
	var d := Vector2(x, z).distance_to(HEAP_AT) / HEAP_RADIUS
	return HEAP_HEIGHT * heap_share * LabGame.smooth(1.0 - d) if d < 1.0 else 0.0


## How much the channel takes off at (x, z) when the valley is `depth` m deep: a V round CHANNEL_Z,
## starting just under the top and running on through the heap.
static func groove(x: float, z: float, depth: float) -> float:
	var d := BASE_GROOVE + depth
	var half := GROOVE_HALF + GROOVE_WIDEN * depth
	var start := LabGame.smooth(((TOP_X - 0.1) - x) / 0.5)
	return d * start * maxf(0.0, 1.0 - absf(z - CHANNEL_Z) / half)


## The ground's height at (x, z): the land and the heap less the channel (never under the plain where
## there is land; the plain itself stays under the island's ground).
static func height_at(slope: float, depth: float, heap_share: float, x: float, z: float) -> float:
	var raw := land_height(slope, x, z) + heap_height(x, z, heap_share)
	if raw <= 0.03:
		return raw - 0.04
	return maxf(raw - groove(x, z, depth), 0.04)


## The mountain (and the heap) as one heightfield: grass, the cut soil where the channel took the
## ground off, the heap's earth.
static func mountain_mesh(slope: float, depth: float, heap_share: float) -> Mesh:
	var b := ArtKit.builder()
	var nx := int(round((BACK_X - FIELD_END_X) / GRID))
	var nz := int(round(FIELD_HALF_Z * 2.0 / GRID))
	var points := []
	var colors := []
	for i in nx + 1:
		var row := []
		var tint := []
		var x := FIELD_END_X + GRID * i
		for k in nz + 1:
			var z := CHANNEL_Z - FIELD_HALF_Z + GRID * k
			var land := land_height(slope, x, z)
			var pile := heap_height(x, z, heap_share)
			var h := height_at(slope, depth, heap_share, x, z)
			row.append(Vector3(x, h, z))
			var cut := clampf((land + pile - h) / 0.25, 0.0, 1.0) if land + pile > 0.03 else 0.0
			var c := ArtPalette.GRASS.lerp(ArtPalette.GRASS_TOP, clampf(h / 2.5, 0.0, 1.0))
			c = c.lerp(BANK_STRIPE, clampf(pile / maxf(land + pile, 0.01), 0.0, 1.0) * 0.9)
			c = c.lerp(BANK_SOIL.lerp(BANK_DARK, clampf(depth / GROOVE_MAX, 0.0, 1.0)), cut)
			tint.append(c)
		points.append(row)
		colors.append(tint)
	for i in nx:
		for k in nz:
			var a: Vector3 = points[i][k]
			var e: Vector3 = points[i + 1][k]
			var f: Vector3 = points[i + 1][k + 1]
			var g: Vector3 = points[i][k + 1]
			if maxf(maxf(a.y, e.y), maxf(f.y, g.y)) < 0.0:
				continue   # under the island's ground
			b.add_triangle([a, e, f], [colors[i][k], colors[i + 1][k], colors[i + 1][k + 1]], Vector3.UP)
			b.add_triangle([a, f, g], [colors[i][k], colors[i + 1][k + 1], colors[i][k + 1]], Vector3.UP)
	return b.commit()


## The channel's bottom at x (world), a little over the ground.
static func channel_point(slope: float, depth: float, heap_share: float, x: float) -> Vector3:
	return Vector3(x, height_at(slope, depth, heap_share, x, CHANNEL_Z) + 0.035, CHANNEL_Z)


## The water down the channel: a blue strip on its bottom from just under the top to the foot.
func _stream_mesh(slope: float, depth: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := 0.1 + 0.12 * depth
	var steps := 30
	var from := TOP_X - 0.35
	for i in steps:
		var x0 := lerpf(from, FIELD_END_X + 0.1, float(i) / steps)
		var x1 := lerpf(from, FIELD_END_X + 0.1, float(i + 1) / steps)
		var p0 := channel_point(slope, depth, heap, x0)
		var p1 := channel_point(slope, depth, heap, x1)
		var side := Vector3(0.0, 0.0, half)
		var c := [WATER, WATER, WATER]
		b.add_triangle([p0 - side, p1 - side, p1 + side], c, Vector3.UP)
		b.add_triangle([p0 - side, p1 + side, p0 + side], c, Vector3.UP)
	return b.commit()


## The water's way for the streaks: down the channel, then along the river into the sea.
func _flow_line(slope: float, depth: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var x := TOP_X - 0.35
	while x > _line[0].x:
		out.append(channel_point(slope, depth, heap, x) + Vector3.UP * 0.02)
		x -= 0.15
	for p in _line:
		out.append(Vector3(p.x, WATER_Y + 0.02, p.y))
	return out


## A streak's place `along` m down the water's way, lying along it.
func _on_flow(along: float) -> Transform3D:
	var left := along
	for i in range(1, _flow.size()):
		var a := _flow[i - 1]
		var e := _flow[i]
		var step := a.distance_to(e)
		if left <= step or i == _flow.size() - 1:
			var dir := (e - a).normalized()
			var p := a.lerp(e, clampf(left / maxf(step, 1e-6), 0.0, 1.0))
			var side := Vector3.UP.cross(dir).normalized()
			if side.length() < 0.5:
				side = Vector3.BACK
			return Transform3D(Basis(dir, side.cross(dir).normalized(), side), p)
		left -= step
	return Transform3D(Basis(), _flow[_flow.size() - 1])


# --- the river ------------------------------------------------------------------------------------

## The river's middle (x, z): a Catmull-Rom line through RIVER_POINTS, RIVER_STEPS samples per span.
static func river_line() -> PackedVector2Array:
	var out := PackedVector2Array()
	var pts: Array = RIVER_POINTS
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		for s in RIVER_STEPS:
			var t := float(s) / RIVER_STEPS
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


## The river's half width at sample `i` of `line`.
static func half_width(line: PackedVector2Array, i: int) -> float:
	return lerpf(RIVER_HALF, MOUTH_HALF, LabGame.smooth((float(i) / (line.size() - 1) - 0.75) / 0.25))


## The unit side of `line` at sample `i` (the left of the way down: x, z).
static func side_at(line: PackedVector2Array, i: int) -> Vector2:
	var a := line[maxi(i - 1, 0)]
	var e := line[mini(i + 1, line.size() - 1)]
	var d := (e - a).normalized()
	return Vector2(d.y, -d.x)


## The samples of the bend (the river's middle behind BEND_Z) and the share (0..1..0) of each along it.
static func bend_samples(line: PackedVector2Array) -> Array:
	var out := []
	for i in line.size():
		if line[i].y < BEND_Z:
			out.append(i)
	return out


## The outward side (away from the bend's inside: towards the back) at sample `i`.
static func outward(line: PackedVector2Array, i: int) -> Vector2:
	var s := side_at(line, i)
	return s if s.y < 0.0 else -s


## The bend's middle (its farthest point back) and the bank's face there for a cut `retreat` m back:
## where the piece is buried (RiverGame).
static func bank_face(retreat: float) -> Vector3:
	var line := river_line()
	var samples := bend_samples(line)
	var mid: int = samples[samples.size() / 2]
	var out := outward(line, mid)
	var p := line[mid] + out * (half_width(line, mid) + retreat)
	return Vector3(p.x, 0.0, p.y)


## The water and its sandy edges along `line`, widening into the sea.
static func _river_mesh(line: PackedVector2Array) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in line.size() - 1:
		var s0 := side_at(line, i)
		var s1 := side_at(line, i + 1)
		var w0 := half_width(line, i)
		var w1 := half_width(line, i + 1)
		var a := line[i]
		var e := line[i + 1]
		for band: Array in [[w0 + EDGE_WIDTH, w1 + EDGE_WIDTH, EDGE_Y, RIVER_SAND], [w0, w1, WATER_Y - 0.008, WATER_EDGE], [w0 * 0.7, w1 * 0.7, WATER_Y, WATER]]:
			var y: float = band[2]
			var c: Color = band[3]
			var l0 := a + s0 * float(band[0])
			var r0 := a - s0 * float(band[0])
			var l1 := e + s1 * float(band[1])
			var r1 := e - s1 * float(band[1])
			var cs := [c, c, c]
			b.add_triangle([Vector3(l0.x, y, l0.y), Vector3(l1.x, y, l1.y), Vector3(r1.x, y, r1.y)], cs, Vector3.UP)
			b.add_triangle([Vector3(l0.x, y, l0.y), Vector3(r1.x, y, r1.y), Vector3(r0.x, y, r0.y)], cs, Vector3.UP)
	return b.commit()


## The bend's outer bank: an earth cliff along the river's outer side, its face `retreat` m back at
## the bend's middle (less towards its ends), its top grass, its face striped earth.
func _bank_mesh(retreat: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = BANK_HEIGHT
	var samples := bend_samples(_line)
	var n := samples.size()
	var face := []
	var back := []
	for j in n:
		var i: int = samples[j]
		var share := sin(PI * (j + 0.5) / n)
		var out := outward(_line, i)
		var edge := half_width(_line, i) + EDGE_WIDTH * 0.5
		var f := _line[i] + out * (edge + retreat * share)
		var k := _line[i] + out * (edge + BANK_DEPTH)
		face.append(Vector3(f.x, 0.0, f.y))
		back.append(Vector3(k.x, 0.0, k.y))
	var up := Vector3.UP * BANK_HEIGHT
	var stripes := [[0.0, 0.3, BANK_DARK], [0.3, 0.55, BANK_SOIL], [0.55, 0.8, BANK_STRIPE], [0.8, 1.0, BANK_SOIL]]
	for j in n - 1:
		var f0: Vector3 = face[j]
		var f1: Vector3 = face[j + 1]
		var k0: Vector3 = back[j]
		var k1: Vector3 = back[j + 1]
		var towards := (_line[samples[j]] - Vector2(f0.x, f0.z))
		var facing := Vector3(towards.x, 0.0, towards.y).normalized()
		for s: Array in stripes:
			var lo: Vector3 = up * float(s[0])
			var hi: Vector3 = up * float(s[1])
			var c: Color = s[2]
			b.add_triangle([f0 + lo, f1 + lo, f1 + hi], [c, c, c], facing)
			b.add_triangle([f0 + lo, f1 + hi, f0 + hi], [c, c, c], facing)
		var g := ArtPalette.GRASS_TOP
		b.add_triangle([f0 + up, f1 + up, k1 + up], [g, g, g], Vector3.UP)
		b.add_triangle([f0 + up, k1 + up, k0 + up], [g, g, g], Vector3.UP)
		var slope_out := (k0 - f0).normalized() * 0.6
		var gs := ArtPalette.GRASS
		b.add_triangle([k0 + up, k1 + up, k1 + slope_out], [gs, gs, gs], Vector3.UP)
		b.add_triangle([k0 + up, k1 + slope_out, k0 + slope_out], [gs, gs, gs], Vector3.UP)
	for end: Array in [[face[0], back[0]], [face[n - 1], back[n - 1]]]:   # the two ends: earth
		var f: Vector3 = end[0]
		var k: Vector3 = end[1]
		var c := BANK_SOIL
		var facing := (f - k).cross(Vector3.UP).normalized()
		b.add_triangle([f, k, k + up], [c, c, c], facing)
		b.add_triangle([f, k + up, f + up], [c, c, c], facing)
		b.add_triangle([f, k, k + up], [c, c, c], -facing)
		b.add_triangle([f, k + up, f + up], [c, c, c], -facing)
	# The earth that fell off the face: lumps at its foot in the water (more as it is cut back).
	if retreat > 0.02:
		for j in range(1, n - 1, 2):
			var i: int = samples[j]
			var share := sin(PI * (j + 0.5) / n) * retreat / BANK_RETREAT
			if share < 0.05:
				continue
			var p := _line[i] + outward(_line, i) * (half_width(_line, i) * 0.55)
			b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.45, 1.0)), Vector3(p.x, WATER_Y, p.y)), 0.12 + 0.1 * share, 3, 7, BANK_SOIL)
	return b.commit()


## A low sand mound of `size` (0..1 of its whole) at a ground point, flattened.
static func _sand(b: ArtMeshBuilder, at: Vector2, radius: float, size: float, tall := 1.0) -> void:
	if size < 0.02:
		return
	var r := radius * (0.35 + 0.65 * size)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, (0.28 * size + 0.04) * tall, 1.0)), Vector3(at.x, 0.02, at.y)), r, 3, 10, SAND)
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.7, (0.3 * size + 0.04) * tall, 0.7)), Vector3(at.x, 0.03, at.y)), r * 0.8, 3, 10, SAND_TOP)


## The bend's inner sand bar (`size` 0..1): mounds along the inside of the bend.
func _inner_bar_mesh(size: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	var samples := bend_samples(_line)
	var n := samples.size()
	for j in range(1, n - 1, 2):
		var i: int = samples[j]
		var share := sin(PI * (j + 0.5) / n)
		var p := _line[i] - outward(_line, i) * (half_width(_line, i) + 0.12 + INNER_OUT * size * share)
		_sand(b, p, INNER_R * share, size * share, INNER_TALL)
	return b.commit()


## Where the river meets the sea: the last river point before the beach.
func mouth() -> Vector2:
	var best := _line[_line.size() - 1]
	for p in _line:
		var e := Vector2((p.x - SEA_AT.x) / SEA_HALF.x, (p.y - SEA_AT.z) / SEA_HALF.y)
		if e.length() <= 1.0 + BEACH / SEA_HALF.x:
			return p
		best = p
	return best


## The sand bar at the river's mouth (`size` 0..1): a crescent across it, on the beach's edge.
func _mouth_bar_mesh(size: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	var m := mouth()
	var out := (Vector2(SEA_AT.x, SEA_AT.z) - m).normalized()
	var across := Vector2(-out.y, out.x)
	for k in 5:
		var t := (k - 2) / 2.0
		var p := m + out * (0.55 + 0.25 * (1.0 - t * t)) + across * t * 0.75
		_sand(b, p, 0.5 - 0.1 * absf(t), size)
	return b.commit()


## The sand the fast water carried out to sea (`size` 0..1): muddy patches past the mouth.
func _plume_mesh(size: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	if size < 0.02:
		return b.commit()
	var m := mouth()
	var out := (Vector2(SEA_AT.x, SEA_AT.z) - m).normalized()
	for k in 4:
		var p := m + out * (0.6 + 0.55 * k * (0.4 + 0.6 * size))
		ArtKit.flat_disc(b, Vector3(p.x, 0.045 + 0.002 * k, p.y), (0.42 - 0.06 * k) * (0.4 + 0.6 * size), MUD.lerp(SEA_SHALLOW, 0.2 * k), 14)
	return b.commit()


## The sea: a rounded bay with a beach round it.
static func _sea_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var sides := 40
	for ring: Array in [[BEACH, 0.012, SAND], [0.0, 0.03, SEA_SHALLOW], [-0.35, 0.034, SEA]]:
		var grow: float = ring[0]
		var y: float = ring[1]
		var c: Color = ring[2]
		var mid := Vector3(SEA_AT.x, y, SEA_AT.z)
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var p0 := mid + Vector3(cos(a0) * (SEA_HALF.x + grow), 0.0, sin(a0) * (SEA_HALF.y + grow))
			var p1 := mid + Vector3(cos(a1) * (SEA_HALF.x + grow), 0.0, sin(a1) * (SEA_HALF.y + grow))
			b.add_triangle([mid, p1, p0], [c, c, c], Vector3.UP)
	for wave: Array in [[Vector2(-0.35, -0.25), 0.5], [Vector2(0.3, 0.2), 0.42], [Vector2(-0.2, 0.5), 0.36]]:   # foam waves
		var at := Vector3(SEA_AT.x + (wave[0] as Vector2).x * SEA_HALF.x, 0.04, SEA_AT.z + (wave[0] as Vector2).y * SEA_HALF.y)
		var r: float = wave[1]
		for k in 6:
			var a0 := PI * (0.15 + 0.7 * k / 6.0)
			var a1 := PI * (0.15 + 0.7 * (k + 1) / 6.0)
			var p0 := at + Vector3(cos(a0) * r, 0.0, -sin(a0) * r * 0.5)
			var p1 := at + Vector3(cos(a1) * r, 0.0, -sin(a1) * r * 0.5)
			var side := Vector3(0.0, 0.0, 0.05)
			var f := ArtPalette.FOAM
			b.add_triangle([p0 - side, p1 - side, p1 + side], [f, f, f], Vector3.UP)
			b.add_triangle([p0 - side, p1 + side, p0 + side], [f, f, f], Vector3.UP)
	return b.commit()


# --- the cloud and the rain -----------------------------------------------------------------------


## Drop `i` of the rain `fallen` m into its fall: scattered under the cloud (a golden-ratio spread),
## falling from RAIN_TOP to the plain and starting over (the mountain hides it under its ground).
static func drop_at(i: int, fallen: float) -> Vector3:
	var u := fposmod(i * 0.618034, 1.0)
	var v := fposmod(i * 0.414214 + 0.3, 1.0)
	var w := fposmod(i * 0.732051 + 0.1, 1.0)
	return Vector3(CLOUD_AT.x + (u * 2.0 - 1.0) * RAIN_SPAN.x, RAIN_TOP - fposmod(RAIN_TOP * w + fallen, RAIN_TOP), CLOUD_AT.z + (v * 2.0 - 1.0) * RAIN_SPAN.y)


## A rain drop: a short light-blue streak, its point down.
static func _drop_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(), 0.04, 0.012, 0.28, 5, DROP)
	return b.commit()


## A flow streak: a thin white dash along +x.
static func _streak_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.22, 0.32)), Vector3.ZERO), 0.2, 3, 8, STREAK)
	return b.commit()
