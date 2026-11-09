## The island map's spot landmarks (2026-10-27 user decision "지도 전체 손보기"): one small,
## chunky model per lab, readable from the map camera (about 1-2 m), so a child sees what is done
## there before reading its name. Built into the caller's builder (MapIsland merges all 11 into one
## mesh); the shapes echo each lab's own props and colours (experiments/*/..._props.gd).
## Visual only: the labs' physics never sees these.
class_name MapLandmarks
extends RefCounted

## Radius of the round stage (MapIsland builds it) each landmark stands on; 0 = no stage (the
## buoyancy dock reaches into the pond instead).
const STAGE := {
	"free-fall": 0.8, "projectile": 0.95, "collision": 1.15, "incline-friction": 1.05,
	"friction": 1.15, "spring": 0.8, "rotation": 1.1, "pulley": 0.95, "constraints": 0.95,
	"buoyancy": 0.0, "orbit": 0.85,
}
const DEFAULT_STAGE := 0.9


static func stage_radius(id: String) -> float:
	return STAGE.get(id, DEFAULT_STAGE)


## Adds the landmark of lab `id` at `xf` (origin = the stage top; for the drum, the pond's water
## with its dock along +x) and returns its height above xf (where the name label goes). Unknown ids get a ball on a post.
static func add(b: ArtMeshBuilder, id: String, xf: Transform3D) -> float:
	b.ao_min = 0.8
	b.ao_height = 0.3
	match id:
		"free-fall":
			return _free_fall(b, xf)
		"projectile":
			return _projectile(b, xf)
		"collision":
			return _collision(b, xf)
		"incline-friction":
			return _incline(b, xf)
		"friction":
			return _friction(b, xf)
		"spring":
			return _spring(b, xf)
		"rotation":
			return _seesaw(b, xf)
		"pulley":
			return _pulley(b, xf)
		"constraints":
			return _pendulum(b, xf)
		"buoyancy":
			return _dock(b, xf)
		"orbit":
			return _star(b, xf)
		"day-night":
			return _globe(b, xf)
		"shadow-clock":
			return _shadow_stick(b, xf)
		"seasons":
			return _orrery(b, xf)
		"water-cycle":
			return _rain_pond(b, xf)
		"dew-cloud":
			return _dew_cup(b, xf)
		"sea-breeze":
			return _pinwheel(b, xf)
		"typhoon":
			return _typhoon(b, xf)
		"river":
			return _river_hill(b, xf)
		"strata":
			return _strata_cliff(b, xf)
		"earthquake":
			return _shake_house(b, xf)
		"volcano":
			return _lava_model(b, xf)
	_rod(b, xf, Vector3.ZERO, Vector3(0.0, 1.0, 0.0), 0.08, ArtPalette.BLUE)
	_ball(b, xf, Vector3(0.0, 1.15, 0.0), 0.2, ArtPalette.WHITE)
	return 1.35


## A drop tower: a striped blue tower, a white ledge at the top and the red ball waiting on it.
static func _free_fall(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(0.0, 1.0, 0.0), Vector3(0.42, 2.0, 0.42), ArtPalette.BLUE, ArtPalette.BLUE)
	for y in [0.55, 1.25]:
		_box(b, xf, Vector3(0.0, y, 0.0), Vector3(0.46, 0.14, 0.46), ArtPalette.WHITE)
	_box(b, xf, Vector3(0.18, 2.05, 0.0), Vector3(0.85, 0.1, 0.5), ArtPalette.ROCK, ArtPalette.WHITE)
	_ball(b, xf, Vector3(0.38, 2.32, 0.0), 0.22, ArtPalette.RED)
	return 2.55


## A slingshot with its ball and, ahead of it, a red and white target.
static func _projectile(b: ArtMeshBuilder, xf: Transform3D) -> float:
	var base := Vector3(-0.45, 0.0, 0.1)
	var fork := base + Vector3(0.0, 0.5, 0.0)
	_rod(b, xf, base, fork, 0.07, ArtPalette.TRUNK)
	var left := fork + Vector3(-0.05, 0.38, -0.2)
	var right := fork + Vector3(-0.05, 0.38, 0.2)
	_rod(b, xf, fork, left, 0.055, ArtPalette.TRUNK)
	_rod(b, xf, fork, right, 0.055, ArtPalette.TRUNK)
	var pouch := fork + Vector3(-0.28, 0.3, 0.0)
	_rod(b, xf, left, pouch, 0.025, ArtPalette.RED)
	_rod(b, xf, right, pouch, 0.025, ArtPalette.RED)
	_ball(b, xf, pouch, 0.15, ArtPalette.ORANGE)
	# The target faces the slingshot and leans back to the sky (the map looks down on it).
	var at := Vector3(0.5, 0.0, -0.1)
	_rod(b, xf, at, at + Vector3(0.05, 0.65, 0.0), 0.05, ArtPalette.TRUNK)
	var face := Basis(Vector3.BACK, deg_to_rad(40.0))   # its axis (local y) towards -x, mostly up
	var center := at + Vector3(0.0, 0.8, 0.0)
	var rings := [[0.42, ArtPalette.RED], [0.29, ArtPalette.WHITE], [0.15, ArtPalette.RED]]
	for i in rings.size():
		var offset := face * Vector3(0.0, 0.03 * i, 0.0)
		b.add_cylinder(xf * Transform3D(face, center + offset), rings[i][0], rings[i][0], 0.05, 14, rings[i][1])
	return 1.3


## A collision track with two balls rolling at each other.
static func _collision(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(0.0, 0.06, 0.0), Vector3(2.0, 0.12, 0.42), ArtPalette.BLUE_DARK, ArtPalette.WHITE)
	for z in [-0.17, 0.17]:
		_box(b, xf, Vector3(0.0, 0.15, z), Vector3(2.0, 0.06, 0.06), ArtPalette.BLUE)
	_ball(b, xf, Vector3(-0.5, 0.34, 0.0), 0.22, ArtPalette.ORANGE)
	_ball(b, xf, Vector3(0.42, 0.34, 0.0), 0.22, ArtPalette.PURPLE)
	_ball(b, xf, Vector3(-0.03, 0.42, 0.0), 0.07, ArtPalette.YELLOW)   # a little spark where they meet
	return 0.7


## A yellow ramp with a crate on its slope.
static func _incline(b: ArtMeshBuilder, xf: Transform3D) -> float:
	var half := Vector2(0.85, 0.36)
	var top := 0.8
	var a := atan2(top, 2.0 * half.x)
	_wedge(b, xf, half, top, ArtPalette.YELLOW, ArtPalette.YELLOW_TOP)
	var normal := Vector3(-sin(a), cos(a), 0.0)
	var center := Vector3(0.0, top * 0.5, 0.0) + normal * 0.2
	b.add_rounded_box(xf * Transform3D(Basis(Vector3.BACK, a), center), Vector3(0.38, 0.38, 0.38), 0.0, 0, ArtPalette.CRATE, ArtPalette.CRATE_TOP)
	return 1.0


## A crate on a floor strip with a red arrow pushing it.
static func _friction(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(0.0, 0.04, 0.0), Vector3(2.0, 0.08, 0.6), ArtPalette.BLUE, ArtPalette.WHITE)
	_box(b, xf, Vector3(0.1, 0.33, 0.0), Vector3(0.5, 0.5, 0.5), ArtPalette.CRATE, ArtPalette.CRATE_TOP)
	_box(b, xf, Vector3(0.1, 0.585, 0.0), Vector3(0.12, 0.02, 0.52), ArtPalette.TAPE)
	_rod(b, xf, Vector3(-0.85, 0.33, 0.0), Vector3(-0.32, 0.33, 0.0), 0.06, ArtPalette.RED)
	var tip := Basis(Vector3.BACK, -PI * 0.5)   # cone axis (y) along +x
	b.add_cylinder(xf * Transform3D(tip, Vector3(-0.36, 0.33, 0.0)), 0.15, 0.0, 0.2, 6, ArtPalette.RED)
	return 0.75


## A coiled spring on a base with a purple block on top.
static func _spring(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(0.0, 0.06, 0.0), Vector3(0.75, 0.12, 0.75), ArtPalette.BLUE_DARK, ArtPalette.BLUE)
	var turns := 4
	var steps := 7
	var bottom := 0.14
	var height := 0.8
	var radius := 0.24
	var last := Vector3(radius, bottom, 0.0)
	for k in range(1, turns * steps + 1):
		var t := float(k) / (turns * steps)
		var angle := TAU * turns * t
		var p := Vector3(radius * cos(angle), bottom + height * t, radius * sin(angle))
		_rod(b, xf, last, p, 0.04, ArtPalette.WHITE, 4)
		last = p
	_box(b, xf, Vector3(0.0, bottom + height + 0.13, 0.0), Vector3(0.58, 0.26, 0.58), ArtPalette.PURPLE, ArtPalette.PURPLE_TOP)
	return 1.25


## A seesaw: a yellow pivot, a tilted red plank and a block on its low end.
static func _seesaw(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO), 0.32, 0.05, 0.45, 4, ArtPalette.YELLOW)
	var tilt := Basis(Vector3.BACK, deg_to_rad(-12.0))
	var plank := Vector3(0.0, 0.5, 0.0)
	b.add_rounded_box(xf * Transform3D(tilt, plank), Vector3(2.0, 0.1, 0.4), 0.0, 0, ArtPalette.RED, ArtPalette.RED_TOP)
	var low := plank + tilt * Vector3(0.74, 0.2, 0.0)
	b.add_rounded_box(xf * Transform3D(tilt, low), Vector3(0.32, 0.3, 0.32), 0.0, 0, ArtPalette.BLUE, ArtPalette.BLUE)
	var high := plank + tilt * Vector3(-0.78, 0.12, 0.0)
	b.add_rounded_box(xf * Transform3D(tilt, high), Vector3(0.2, 0.14, 0.2), 0.0, 0, ArtPalette.YELLOW, ArtPalette.YELLOW_TOP)
	return 1.0


## A pulley frame: two posts and a beam, the white wheel, its rope and the red load.
static func _pulley(b: ArtMeshBuilder, xf: Transform3D) -> float:
	for x in [-0.55, 0.55]:
		_box(b, xf, Vector3(x, 0.8, 0.0), Vector3(0.14, 1.6, 0.14), ArtPalette.BLUE_DARK)
	_box(b, xf, Vector3(0.0, 1.62, 0.0), Vector3(1.32, 0.13, 0.18), ArtPalette.BLUE_DARK, ArtPalette.BLUE)
	_rod(b, xf, Vector3(0.0, 1.56, 0.0), Vector3(0.0, 1.4, 0.0), 0.03, ArtPalette.INK)
	var wheel := Basis(Vector3.RIGHT, PI * 0.5)   # axis along z
	b.add_cylinder(xf * Transform3D(wheel, Vector3(0.0, 1.34, -0.06)), 0.2, 0.2, 0.12, 12, ArtPalette.WHITE)
	b.add_cylinder(xf * Transform3D(wheel, Vector3(0.0, 1.34, -0.08)), 0.07, 0.07, 0.16, 6, ArtPalette.RED)
	_rod(b, xf, Vector3(0.2, 1.34, 0.0), Vector3(0.2, 0.62, 0.0), 0.025, ArtPalette.INK)
	_box(b, xf, Vector3(0.2, 0.45, 0.0), Vector3(0.34, 0.34, 0.34), ArtPalette.RED, ArtPalette.RED_TOP)
	_rod(b, xf, Vector3(-0.2, 1.34, 0.0), Vector3(-0.2, 0.9, 0.0), 0.025, ArtPalette.INK)
	_ball(b, xf, Vector3(-0.2, 0.86, 0.0), 0.08, ArtPalette.YELLOW)
	return 1.75


## A pendulum: a post with an arm and a yellow bob swung out on its rod.
static func _pendulum(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(0.0, 0.05, 0.0), Vector3(0.6, 0.1, 0.5), ArtPalette.BLUE_DARK, ArtPalette.BLUE)
	_box(b, xf, Vector3(-0.15, 0.85, 0.0), Vector3(0.14, 1.6, 0.14), ArtPalette.BLUE_DARK)
	_box(b, xf, Vector3(0.15, 1.6, 0.0), Vector3(0.75, 0.12, 0.14), ArtPalette.BLUE_DARK, ArtPalette.BLUE)
	var pivot := Vector3(0.42, 1.54, 0.0)
	var bob := pivot + Vector3(sin(deg_to_rad(28.0)), -cos(deg_to_rad(28.0)), 0.0) * 0.95
	_rod(b, xf, pivot, bob, 0.025, ArtPalette.INK)
	_ball(b, xf, bob, 0.22, ArtPalette.YELLOW)
	return 1.75


## A red and white drum floating in the pond (origin = the water) with a ripple ring, and a
## little dock from it to the shore (+x).
static func _dock(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(1.05, 0.08, 0.0), Vector3(1.5, 0.08, 0.7), ArtPalette.CRATE, ArtPalette.CRATE_TOP)
	for x in [0.6, 1.1, 1.6]:
		_box(b, xf, Vector3(x, 0.125, 0.0), Vector3(0.05, 0.01, 0.7), ArtPalette.TAPE)
	for x in [0.4, 1.7]:
		for z in [-0.29, 0.29]:
			_rod(b, xf, Vector3(x, -0.2, z), Vector3(x, 0.16, z), 0.05, ArtPalette.TRUNK)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.005, 0.0)), 0.55, 0.55, 0.02, 16, ArtPalette.WATER_TOP)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, -0.15, 0.0)), 0.32, 0.32, 0.6, 12, ArtPalette.RED, true, ArtPalette.RED_TOP)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.08, 0.0)), 0.33, 0.33, 0.13, 12, ArtPalette.WHITE, false)
	return 0.5


## The lookout's tower with a star on top and a planet going round it.
static func _star(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.52, 0.42, 1.4, 8, ArtPalette.ROCK, true, ArtPalette.WHITE)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 1.4, 0.0)), 0.6, 0.6, 0.12, 8, ArtPalette.WHITE)
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		_box(b, xf, Vector3(0.52 * cos(a), 1.59, 0.52 * sin(a)), Vector3(0.15, 0.15, 0.15), ArtPalette.WHITE)
	var sun := Vector3(0.0, 2.1, 0.0)
	_ball(b, xf, sun, 0.36, ArtPalette.YELLOW)
	for i in 6:   # star points around the ball, in the plane that faces the map camera
		var a := TAU * i / 6.0
		var dir := Vector3(cos(a), sin(a) * 0.8, sin(a) * 0.6).normalized()
		b.add_cylinder(xf * Transform3D(_along(dir), sun + dir * 0.26), 0.13, 0.0, 0.3, 4, ArtPalette.YELLOW)
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(20.0))
	var ring := 0.72
	var last := sun + tilt * Vector3(ring, 0.0, 0.0)
	for k in range(1, 19):
		var a := TAU * k / 18.0
		var p := sun + tilt * Vector3(ring * cos(a), 0.0, ring * sin(a))
		_rod(b, xf, last, p, 0.02, ArtPalette.WHITE, 4)
		last = p
	_ball(b, xf, sun + tilt * Vector3(ring * cos(2.2), 0.0, ring * sin(2.2)), 0.14, ArtPalette.BLUE)
	return 2.55


# --- the island's features (#72: the hutton island; MapIsland and LabWorld place them) ------------

## The volcano's cone profile [share of the radius, share of the height] from the foot (sunk under
## the ground) to the crater's rim, then down inside the crater.
const VOLCANO_RINGS := [[1.0, 0.0], [0.8, 0.3], [0.58, 0.6], [0.38, 0.88], [0.28, 1.0], [0.19, 0.84]]
const VOLCANO_SIDES := 14
const VOLCANO_JITTER := 0.07         # share of the radius the slope vertices move (facets)
## The thin smoke over the crater: puffs [x, y over the rim, z, radius] in shares of the radius.
const SMOKE_PUFFS := [[0.05, 0.3, 0.0, 0.13], [0.12, 0.62, -0.06, 0.1], [0.24, 0.9, -0.12, 0.075]]
## The sundial's height (its dial's top; where the story's pieces gather, MapIsland.home_lookout).
const SUNDIAL_HEIGHT := 0.9


## An asleep volcano at `xf` (origin = the ground at its middle): a faceted cone `radius` m round and
## `height` m high whose foot ring sits `sink` m under the origin (into the ground round it), brown
## slopes darker towards the rim, a dark crater and a thin wisp of smoke.
static func volcano(b: ArtMeshBuilder, xf: Transform3D, radius: float, height: float, sink: float) -> void:
	var rings: Array = []
	for k in VOLCANO_RINGS.size():
		var row: Array = []
		for i in VOLCANO_SIDES:
			var j := 0.0 if k == 0 or k >= VOLCANO_RINGS.size() - 2 else 1.0
			var theta := TAU * (i + 0.5 * j * MapIsland._hash(i, k, 11)) / VOLCANO_SIDES
			var r: float = radius * float(VOLCANO_RINGS[k][0]) * (1.0 + j * VOLCANO_JITTER * MapIsland._hash(i, k, 12))
			var y: float = -sink if k == 0 else height * float(VOLCANO_RINGS[k][1]) * (1.0 + j * 0.05 * MapIsland._hash(i, k, 13))
			row.append(xf * Vector3(r * cos(theta), y, r * sin(theta)))
		rings.append(row)
	var top := xf * Vector3(0.0, height, 0.0)
	var up := xf.basis * Vector3.UP
	for k in rings.size() - 1:
		var inside := k == rings.size() - 2   # the rim down into the crater
		var color: Color = ArtPalette.CRATER if inside else (ArtPalette.VOLCANO if k < 2 else ArtPalette.VOLCANO_TOP)
		for i in VOLCANO_SIDES:
			var n := (i + 1) % VOLCANO_SIDES
			var q: Array = [rings[k][i], rings[k][n], rings[k + 1][n], rings[k + 1][i]]
			var mid: Vector3 = (q[0] + q[1] + q[2] + q[3]) * 0.25
			var out: Vector3 = mid - top
			out.y = 0.0
			var facing: Vector3 = (up - out.normalized() * 0.3) if inside else (out.normalized() + up * 0.6)
			var c := color.lightened(0.04 * (MapIsland._hash(i, k, 14) * 0.5 + 0.5))
			b.add_triangle([q[0], q[1], q[2]], [c, c, c], facing)
			b.add_triangle([q[0], q[2], q[3]], [c, c, c], facing)
	var floor_y := height * 0.78
	var centre := xf * Vector3(0.0, floor_y, 0.0)
	var last: Array = rings[rings.size() - 1]
	for i in VOLCANO_SIDES:
		var c := ArtPalette.CRATER.darkened(0.15)
		b.add_triangle([centre, last[i], last[(i + 1) % VOLCANO_SIDES]], [c, c, c], up)
	var was_flat := b.flat
	b.flat = false   # soft round puffs (the clouds')
	b.ao_min = 0.9
	b.ao_height = 0.3 * radius
	for puff in SMOKE_PUFFS:
		b.add_sphere(xf * Transform3D(Basis(), Vector3(puff[0] * radius, height + puff[1] * radius, puff[2] * radius)), puff[3] * radius, 4, 8, ArtPalette.SMOKE)
	b.flat = was_flat


## A lighthouse on its rock: a red and white striped tower, a white gallery, the yellow lamp and a
## red roof (about 2.4 m).
static func lighthouse(b: ArtMeshBuilder, xf: Transform3D) -> void:
	b.ao_min = 0.8
	b.ao_height = 0.3
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, -0.2, 0.0)), 0.58, 0.48, 0.42, 8, ArtPalette.ROCK)
	var bands := 4
	var tower := 1.5
	for k in bands:
		var t0 := float(k) / bands
		var t1 := float(k + 1) / bands
		var r0 := lerpf(0.33, 0.24, t0)
		var r1 := lerpf(0.33, 0.24, t1)
		b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.2 + tower * t0, 0.0)), r0, r1, tower / bands, 10,
			ArtPalette.RED if k % 2 == 0 else ArtPalette.WHITE, false)
	var deck := 0.2 + tower
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, deck, 0.0)), 0.36, 0.36, 0.08, 10, ArtPalette.WHITE)
	b.ao_min = 1.0
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, deck + 0.08, 0.0)), 0.2, 0.2, 0.26, 8, ArtPalette.YELLOW, false)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, deck + 0.34, 0.0)), 0.3, 0.0, 0.32, 10, ArtPalette.RED)


## The sundial's dial (#106): the stone plate's top at DIAL_Y over the drum's foot, its golden face
## DIAL_RADIUS round (the ten wedges' dial, SundialArt.WEDGES), the gnomon standing on it.
const DIAL_Y := 0.53
const DIAL_RADIUS := 0.5
const GNOMON_HALF := Vector2(0.3, 0.025)
const GNOMON_AT := Vector3(0.0, DIAL_Y, -0.12)
const GNOMON_HEIGHT := SUNDIAL_HEIGHT - 0.54   # its high end over its foot
## The gnomon's fixed shadow on the dial after the finale (#106): from the gnomon's middle across the
## dial, away from the morning sun (towards the map's screen left, a little to the front), this long.
const SHADOW_LENGTH := 0.4
const SHADOW_YAW := deg_to_rad(-161.0)


## The sundial on the square, whole (the labs after the hutton finale) or broken (before it, and on
## the map, where SundialDial draws the dial itself): the stone drum and plate; whole adds the golden
## dial and the gnomon, SUNDIAL_HEIGHT high.
static func sundial(b: ArtMeshBuilder, xf: Transform3D, whole := true) -> void:
	sundial_base(b, xf)
	if whole:
		sundial_dial(b, xf)
		gnomon(b, xf)


## The broken sundial (#106: before the finale the dial is gone): the stone drum and its plate, the
## plate's top an empty grey ring round a darker hollow where the dial sat.
static func sundial_base(b: ArtMeshBuilder, xf: Transform3D) -> void:
	b.ao_min = 0.8
	b.ao_height = 0.3
	b.add_cylinder(xf, 0.34, 0.3, 0.45, 10, ArtPalette.ROCK)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.45, 0.0)), 0.55, 0.55, 0.08, 16, ArtPalette.ROCK, true, ArtPalette.ROCK_TOP)
	b.ao_min = 1.0


## The golden dial on the plate: ten wedges (SundialArt's gold, every other one a touch lighter), the
## lines between them, and the deeper golden band round the rim, just over the plate.
static func sundial_dial(b: ArtMeshBuilder, xf: Transform3D) -> void:
	var y := DIAL_Y + 0.006
	var n := SundialArt.WEDGES
	var steps := 4
	for i in n:
		var face := SundialArt.FACE if i % 2 == 0 else SundialArt.FACE.lerp(SundialArt.LIGHT, 0.35)
		for s in steps:
			var a0 := TAU * (i + float(s) / steps) / n
			var a1 := TAU * (i + float(s + 1) / steps) / n
			var p0 := Vector3(cos(a0), 0.0, sin(a0))
			var p1 := Vector3(cos(a1), 0.0, sin(a1))
			var inner := DIAL_RADIUS * (1.0 - SundialArt.BAND)
			b.add_triangle([xf * Vector3(0.0, y, 0.0), xf * (p1 * inner + Vector3.UP * y), xf * (p0 * inner + Vector3.UP * y)], [face, face, face])
			var rim := SundialArt.RIM
			b.add_triangle([xf * (p0 * inner + Vector3.UP * y), xf * (p1 * inner + Vector3.UP * y), xf * (p1 * DIAL_RADIUS + Vector3.UP * y)], [rim, rim, rim])
			b.add_triangle([xf * (p0 * inner + Vector3.UP * y), xf * (p1 * DIAL_RADIUS + Vector3.UP * y), xf * (p0 * DIAL_RADIUS + Vector3.UP * y)], [rim, rim, rim])
	for i in n:
		var a := TAU * i / n
		var mid := Vector3(cos(a), 0.0, sin(a)) * DIAL_RADIUS * 0.5
		b.add_rounded_box(xf * Transform3D(Basis(Vector3.UP, -a), mid + Vector3.UP * (y + 0.006)), Vector3(DIAL_RADIUS, 0.012, 0.018), 0.0, 0, SundialArt.LINE)


## The gnomon (해시계 바늘) standing on the dial at `xf` (the sundial's foot): a thin golden wedge from
## the dial's middle, rising towards -z. Also the carried needle of the finale (SundialDial.needle_node).
static func gnomon(b: ArtMeshBuilder, xf: Transform3D) -> void:
	_wedge(b, xf * Transform3D(Basis(Vector3.UP, PI * 0.5), GNOMON_AT), GNOMON_HALF, GNOMON_HEIGHT, ArtPalette.YELLOW, ArtPalette.YELLOW_TOP)


## The gnomon's shadow on the dial (#106, after the finale): a long thin dark triangle from its foot.
static func gnomon_shadow(b: ArtMeshBuilder, xf: Transform3D) -> void:
	var y := DIAL_Y + 0.02
	var dir := Vector3(cos(SHADOW_YAW), 0.0, -sin(SHADOW_YAW))
	var side := Vector3(-dir.z, 0.0, dir.x) * 0.065
	var foot := Vector3(GNOMON_AT.x, y, GNOMON_AT.z)
	var tip := foot + dir * SHADOW_LENGTH
	var c := ArtPalette.SUNDIAL_SHADOW
	b.add_triangle([xf * (foot + side), xf * tip, xf * (foot - side)], [c, c, c])
	b.add_triangle([xf * (foot - side), xf * tip, xf * (foot + side)], [c, c, c])   # (either winding: it shows from above)


## The globe landmark's lands [direction from its centre, radius] (a few big blobs that read at
## the map's distance; not the lab's continents, DayNightProps.LANDS, which are too small here).
const LAND_BLOBS := [[Vector3(0.6, 0.5, 0.62), 0.24], [Vector3(-0.7, 0.2, 0.7), 0.2], [Vector3(0.2, -0.6, 0.8), 0.18], [Vector3(0.9, 0.1, -0.4), 0.2]]


## The hutton island's 낮과 밤 (#74, "커다란 지구본이 있는 곳"): a big globe on a wooden stand, its
## axis a leaning rod with the red north end, green lands on the blue sea.
static func _globe(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.42, 0.36, 0.14, 8, ArtPalette.WOOD_GRAIN, true, ArtPalette.WOOD)
	_rod(b, xf, Vector3(0.0, 0.1, 0.0), Vector3(0.0, 0.62, 0.0), 0.07, ArtPalette.WOOD_GRAIN)
	var center := Vector3(0.0, 1.15, 0.0)
	var axis := Vector3(0.0, cos(deg_to_rad(SunModel.EARTH_TILT)), sin(deg_to_rad(SunModel.EARTH_TILT)))
	_ball(b, xf, center, 0.5, ArtPalette.BLUE)
	for land: Array in LAND_BLOBS:
		var dir: Vector3 = (land[0] as Vector3).normalized()
		b.add_sphere(xf * Transform3D(_along(dir).scaled_local(Vector3(1.0, 0.35, 1.0)), center + dir * 0.47), float(land[1]), 3, 6, ArtPalette.GRASS)
	_rod(b, xf, center - axis * 0.62, center + axis * 0.66, 0.035, ArtPalette.STEEL_SHINE)
	_ball(b, xf, center + axis * 0.68, 0.07, ArtPalette.RED)
	return 1.9


## The shadow yard (#86): a stick with a red ball, its dark shadow along the ground to a flat stone,
## a little flower bed on the other side and the sun on a curved wire over it.
static func _shadow_stick(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_rod(b, xf, Vector3.ZERO, Vector3(0.0, 1.0, 0.0), 0.06, ArtPalette.WOOD)
	_ball(b, xf, Vector3(0.0, 1.05, 0.0), 0.12, ArtPalette.RED)
	_box(b, xf, Vector3(-0.45, 0.012, 0.25), Vector3(0.9, 0.025, 0.16), ArtPalette.CAST_SHADOW)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(-0.95, 0.0, 0.5)), 0.24, 0.22, 0.07, 8, ArtPalette.ROCK)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.6, 0.0, 0.35)), 0.2, 0.2, 0.05, 8, ArtPalette.SOIL)
	_ball(b, xf, Vector3(0.6, 0.12, 0.35), 0.08, ArtPalette.PINK)
	var arc := [Vector3(0.75, 0.2, -0.35), Vector3(0.55, 1.1, -0.45), Vector3(0.0, 1.55, -0.5), Vector3(-0.55, 1.1, -0.45), Vector3(-0.75, 0.2, -0.35)]
	for k in arc.size() - 1:
		_rod(b, xf, arc[k], arc[k + 1], 0.02, ArtPalette.STEEL_SHINE)
	_ball(b, xf, Vector3(0.45, 1.25, -0.46), 0.18, ArtPalette.YELLOW)
	return 1.8


## The hutton island's 계절 (#87, "해 둘레에 길이 있는 곳"): the sun on a post in the middle of a ring
## (the Earth's path) and a small tilted globe on the ring.
static func _orrery(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.5, 0.42, 0.12, 10, ArtPalette.WOOD_GRAIN, true, ArtPalette.WOOD)
	_rod(b, xf, Vector3(0.0, 0.1, 0.0), Vector3(0.0, 0.85, 0.0), 0.06, ArtPalette.WOOD_GRAIN)
	var center := Vector3(0.0, 1.05, 0.0)
	_ball(b, xf, center, 0.26, ArtPalette.YELLOW)
	for i in 16:
		var a := TAU * i / 16.0
		var a1 := TAU * (i + 1) / 16.0
		_rod(b, xf, center + Vector3(cos(a), 0.0, sin(a)) * 0.62, center + Vector3(cos(a1), 0.0, sin(a1)) * 0.62, 0.025, ArtPalette.STEEL_SHINE)
	var earth := center + Vector3(0.44, 0.0, 0.44)
	var axis := Vector3(-sin(deg_to_rad(SunModel.EARTH_TILT)), cos(deg_to_rad(SunModel.EARTH_TILT)), 0.0)
	_ball(b, xf, earth, 0.2, ArtPalette.BLUE)
	_rod(b, xf, earth - axis * 0.3, earth + axis * 0.32, 0.025, ArtPalette.STEEL_SHINE)
	_ball(b, xf, earth + axis * 0.33, 0.045, ArtPalette.RED)
	return 1.6


## The hutton island's 물의 여행 (#91, "바닷가, 마른 연못이 있는 곳"): a little pond in a ring of stones, a
## rain cloud over it on a post with drops falling, a small sun beside it.
static func _rain_pond(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.55, 0.5, 0.1, 12, ArtPalette.ROCK, true, ArtPalette.STEEL_SHINE)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.1, 0.0)), 0.42, 0.42, 0.03, 12, ArtPalette.POND)
	_rod(b, xf, Vector3(-0.45, 0.1, -0.2), Vector3(-0.45, 1.25, -0.2), 0.04, ArtPalette.WOOD_GRAIN)
	for puff: Array in [[Vector3(-0.22, 1.35, 0.0), 0.22], [Vector3(0.05, 1.45, 0.0), 0.27], [Vector3(0.3, 1.35, 0.0), 0.2]]:
		_ball(b, xf, puff[0], puff[1], ArtPalette.WHITE)
	for drop: Vector3 in [Vector3(-0.15, 0.9, 0.05), Vector3(0.1, 0.7, 0.0), Vector3(0.3, 0.95, -0.05), Vector3(-0.05, 0.5, 0.1)]:
		_rod(b, xf, drop, drop + Vector3(0.0, -0.14, 0.0), 0.03, ArtPalette.BLUE)
	_ball(b, xf, Vector3(0.55, 1.05, -0.15), 0.14, ArtPalette.YELLOW)
	return 1.75

## The hutton island's 구름과 이슬 (#92, "바닷가 언덕, 유리컵이 놓인 곳이야!"): a glass cup of iced water on
## a little table, dew drops on its front, and a small cloud over it.
static func _dew_cup(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.5, 0.42, 0.12, 10, ArtPalette.WOOD_GRAIN, true, ArtPalette.WOOD)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.12, 0.0)), 0.26, 0.31, 0.62, 12, Color("cdeeff"), true, Color("8fd3ff"))
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.7, 0.0)), 0.32, 0.32, 0.04, 12, ArtPalette.WHITE)
	_ball(b, xf, Vector3(0.05, 0.72, 0.02), 0.09, Color("e3f4ff"))
	for k in 5:
		var a := deg_to_rad(60.0 + k * 15.0)
		_ball(b, xf, Vector3(cos(a) * 0.31, 0.25 + 0.08 * (k % 3), sin(a) * 0.31), 0.04, Color("4aa8f5"))
	for puff: Array in [[Vector3(-0.15, 1.15, 0.0), 0.16], [Vector3(0.05, 1.22, 0.0), 0.2], [Vector3(0.24, 1.14, 0.0), 0.15]]:
		_ball(b, xf, puff[0], puff[1], ArtPalette.CLOUD)
	return 1.45

## The hutton island's 바닷바람 (#93, "바람개비가 서 있는 곳"): a pinwheel on a pole, four coloured blades
## round a white hub facing the front.
static func _pinwheel(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.34, 0.3, 0.1, 10, ArtPalette.WOOD_GRAIN, true, ArtPalette.WOOD)
	_rod(b, xf, Vector3(0.0, 0.1, 0.0), Vector3(0.0, 1.1, 0.0), 0.05, ArtPalette.WOOD)
	var hub := Vector3(0.0, 1.15, 0.08)
	var colors := [ArtPalette.RED, ArtPalette.YELLOW, ArtPalette.BLUE, ArtPalette.GRASS]
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var out := Vector3(cos(a), sin(a), 0.0)
		var side := Vector3(-sin(a), cos(a), 0.0)
		var c: Color = colors[i]
		var p := [xf * hub, xf * (hub + out * 0.45), xf * (hub + out * 0.25 + side * 0.24 + Vector3(0.0, 0.0, 0.08))]
		b.add_triangle(p, [c, c, c.lightened(0.2)], xf.basis * Vector3.BACK)
		b.add_triangle([p[0], p[2], p[1]], [c, c, c], xf.basis * Vector3.FORWARD)
	_ball(b, xf, hub + Vector3(0.0, 0.0, 0.04), 0.07, ArtPalette.WHITE)
	return 1.6

## The hutton island's 태풍·비구름 (#94, "파도가 높은 곳"): a round pool of warm sea with white wave
## caps and, over it on a thin post, a grey swirl of cloud arms round an eye.
static func _typhoon(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.55, 0.5, 0.1, 12, ArtPalette.SAND, true, TyphoonProps.WARM_SEA)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		_box(b, xf, Vector3(cos(a) * 0.32, 0.11, sin(a) * 0.32), Vector3(0.16, 0.025, 0.05), ArtPalette.FOAM)
	_rod(b, xf, Vector3(0.0, 0.1, 0.0), Vector3(0.0, 0.95, 0.0), 0.03, ArtPalette.STEEL_SHINE)
	var center := Vector3(0.0, 1.05, 0.0)
	for arm in 3:
		for k in 5:
			var u := k / 4.0
			var a := TAU * arm / 3.0 - u * 2.4
			var r := lerpf(0.14, 0.5, u)
			b.add_sphere(xf * Transform3D(Basis.from_scale(Vector3(1.0, 0.55, 1.0)), center + Vector3(cos(a) * r, 0.0, -sin(a) * r)), lerpf(0.13, 0.07, u), 3, 6, Color("c9d3e3"))
	return 1.4

## The hutton island's 강물이 깎고 쌓기 (#95, "골짜기 입구, 강이 굽이치는 곳"): a little green mountain
## with a brown cut down its face, a cloud over it and a blue river winding from its foot.
static func _river_hill(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(-0.3, 0.0, -0.15)), 0.62, 0.08, 0.9, 7, ArtPalette.GRASS, true, ArtPalette.GRASS_TOP)
	_rod(b, xf, Vector3(-0.3, 0.86, -0.1), Vector3(0.12, 0.08, 0.32), 0.05, ArtPalette.SOIL)
	var river := [Vector3(0.12, 0.03, 0.32), Vector3(0.45, 0.03, 0.12), Vector3(0.75, 0.03, 0.35), Vector3(0.95, 0.03, 0.7)]
	for k in river.size() - 1:
		_rod(b, xf, river[k], river[k + 1], 0.07, ArtPalette.RIVER, 6)
	_ball(b, xf, Vector3(0.45, 0.06, 0.32), 0.1, ArtPalette.SAND)
	for puff: Array in [[Vector3(-0.3, 1.35, -0.1), 0.22], [Vector3(-0.55, 1.28, -0.1), 0.16], [Vector3(-0.05, 1.28, -0.1), 0.16]]:
		_ball(b, xf, puff[0], puff[1], ArtPalette.CLOUD)
	return 1.65

## The hutton island's 지층 쌓기 (#96, "줄무늬 절벽이 있는 곳"): a little cliff of coloured stripes (the
## lab's gravel, sand, mud, grey ash, sand) with grass on top.
static func _strata_cliff(b: ArtMeshBuilder, xf: Transform3D) -> float:
	var h := 0.26
	for i in StrataModel.CLIFF.size():
		var colors: Array = StrataProps.COLORS[StrataModel.CLIFF[i]]
		_box(b, xf, Vector3(0.0, h * (i + 0.5), 0.0), Vector3(1.0 - 0.03 * (i % 2), h, 0.7), colors[0], colors[1])
	_box(b, xf, Vector3(0.0, h * StrataModel.CLIFF.size() + 0.05, 0.0), Vector3(1.04, 0.1, 0.74), ArtPalette.GRASS, ArtPalette.GRASS_TOP)
	return h * StrataModel.CLIFF.size() + 0.25

## The hutton island's 지진 (#97, "블록 집이 서 있는 곳"): the shake table (blue base, orange deck, the red
## handle's knob on the left) and the block house on it, its X brace and red roof.
static func _shake_house(b: ArtMeshBuilder, xf: Transform3D) -> float:
	_box(b, xf, Vector3(0.0, 0.08, 0.0), Vector3(1.3, 0.16, 0.8), ArtPalette.BLUE_DARK, ArtPalette.BLUE)
	_box(b, xf, Vector3(0.0, 0.2, 0.0), Vector3(1.1, 0.08, 0.7), ArtPalette.ORANGE, ArtPalette.ORANGE_TOP)
	_rod(b, xf, Vector3(-0.55, 0.2, 0.0), Vector3(-0.72, 0.2, 0.0), 0.03, ArtPalette.STEEL)
	_ball(b, xf, Vector3(-0.76, 0.2, 0.0), 0.1, ArtPalette.RED)
	for x: float in [-0.3, 0.3]:
		_box(b, xf, Vector3(x, 0.52, 0.0), Vector3(0.14, 0.56, 0.36), Color("e3a35e"))
	_box(b, xf, Vector3(0.0, 0.84, 0.0), Vector3(0.78, 0.09, 0.4), ArtPalette.WOOD_GRAIN)
	_rod(b, xf, Vector3(-0.22, 0.26, 0.2), Vector3(0.22, 0.78, 0.2), 0.03, ArtPalette.WOOD_GRAIN)
	_rod(b, xf, Vector3(0.22, 0.26, 0.2), Vector3(-0.22, 0.78, 0.2), 0.03, ArtPalette.WOOD_GRAIN)
	for side: float in [-1.0, 1.0]:   # the roof's two slopes
		b.add_rounded_box(xf * Transform3D(Basis(Vector3.BACK, -side * 0.6), Vector3(side * 0.2, 1.02, 0.0)), Vector3(0.56, 0.07, 0.5), 0.0, 0, ArtPalette.RED, ArtPalette.RED_TOP)
	return 1.4

## The hutton island's 화산 (#98, "연기 나는 산"): the lab's little volcano model on its round table,
## an orange stream of lava down its side, and the red button of the magma pump beside it.
static func _lava_model(b: ArtMeshBuilder, xf: Transform3D) -> float:
	b.add_cylinder(xf, 0.62, 0.62, 0.14, 12, ArtPalette.WOOD_GRAIN, true, ArtPalette.WOOD)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.0, 0.14, 0.0)), 0.52, 0.12, 0.62, 10, ArtPalette.VOLCANO, true, ArtPalette.CRATER)
	_rod(b, xf, Vector3(0.1, 0.72, 0.06), Vector3(0.42, 0.2, 0.26), 0.06, ArtPalette.ORANGE)
	_ball(b, xf, Vector3(0.0, 0.8, 0.0), 0.1, ArtPalette.YELLOW)
	_ball(b, xf, Vector3(0.06, 1.05, 0.0), 0.13, ArtPalette.SMOKE)
	b.add_cylinder(xf * Transform3D(Basis(), Vector3(0.55, 0.0, 0.45)), 0.16, 0.16, 0.3, 8, ArtPalette.IRON)
	_ball(b, xf, Vector3(0.55, 0.33, 0.45), 0.12, ArtPalette.RED)
	return 1.25


# --- helpers ---------------------------------------------------------------------------------

## A plain box: a bevel (108 triangles instead of 12) does not show at the map's distance.
static func _box(b: ArtMeshBuilder, xf: Transform3D, at: Vector3, size: Vector3, color: Color, top: Variant = null) -> void:
	b.add_rounded_box(xf * Transform3D(Basis(), at), size, 0.0, 0, color, top)


static func _ball(b: ArtMeshBuilder, xf: Transform3D, at: Vector3, radius: float, color: Color) -> void:
	b.add_sphere(xf * Transform3D(Basis(), at), radius, 4, 7, color)


## A cylinder from `from` to `to` (local to xf).
static func _rod(b: ArtMeshBuilder, xf: Transform3D, from: Vector3, to: Vector3, radius: float, color: Color, sides := 6) -> void:
	var d := to - from
	if d.length() < 1e-5:
		return
	b.add_cylinder(xf * Transform3D(_along(d.normalized()), from), radius, radius, d.length(), sides, color)


## A basis whose y axis is `dir` (unit).
static func _along(dir: Vector3) -> Basis:
	var x := dir.cross(Vector3.BACK if absf(dir.z) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, dir, x.cross(dir))


## A ramp: a wedge over [-half.x, half.x] x [-half.y, half.y] rising to `top` at +x.
static func _wedge(b: ArtMeshBuilder, xf: Transform3D, half: Vector2, top: float, color: Color, slope_color: Color) -> void:
	var p := func(x: float, y: float, z: float) -> Vector3: return xf * Vector3(x, y, z)
	var a0: Vector3 = p.call(-half.x, 0.0, -half.y)
	var a1: Vector3 = p.call(-half.x, 0.0, half.y)
	var b0: Vector3 = p.call(half.x, 0.0, -half.y)
	var b1: Vector3 = p.call(half.x, 0.0, half.y)
	var c0: Vector3 = p.call(half.x, top, -half.y)
	var c1: Vector3 = p.call(half.x, top, half.y)
	var up := xf.basis * Vector3(-top, 2.0 * half.x, 0.0).normalized()
	var back := xf.basis * Vector3.RIGHT
	var side := xf.basis * Vector3.BACK
	var sc := [slope_color, slope_color, slope_color]
	var cc := [color, color, color]
	b.add_triangle([a0, a1, c1], sc, up)
	b.add_triangle([a0, c1, c0], sc, up)
	b.add_triangle([b0, b1, c1], cc, back)
	b.add_triangle([b0, c1, c0], cc, back)
	b.add_triangle([a1, b1, c1], cc, side)
	b.add_triangle([a0, b0, c0], cc, -side)
