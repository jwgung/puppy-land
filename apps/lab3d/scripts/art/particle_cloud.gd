## Particles a child can see (#156, 2026-11-15; Curie Island's labs, docs/islands/curie-missions.md:
## "물질은 눈에 안 보이는 작은 알갱이"): many small round dots in one MultiMesh, each jiggling on its own
## (a random walk about its place). The ink in a glass, the smell over the table, and the salt in water
## or the gas in a balloon of the later spots are the same few calls:
##   var ink := ParticleCloud.new(60, 0.045, Color("2a3cb0"), 7)
##   glass.add_child(ink)
##   ink.scatter_homes()                       # each dot's place in the unit ball, at random
##   ink.show_count(ink.capacity())
##   # every frame: where each dot is for the model's state now (its home scaled by the spread) plus its
##   # jiggle, which grows by up to `speed` × delta per axis and stays within `wobble` m of its place:
##   ink.spread(delta, speed, wobble, func(home: Vector3, jiggle: Vector3) -> Vector3:
##       return drop + home * reach + jiggle)
## The dots are a picture only: their homes and jiggles are random (each cloud has its own seeded
## generator, so a test can repeat them), and nothing a mission judges reads them. The lab's model says
## how far the stuff has spread (its deterministic state); the lab passes that through `at`.
class_name ParticleCloud
extends MultiMeshInstance3D

## A dot's ring and sides (a low-poly ball reads round at a dot's size).
const RINGS := 3
const SIDES := 6

## The dots' positions (local to the cloud), kept here: the MultiMesh keeps its copy on the server.
var points := PackedVector3Array()
## Each dot's place (scatter_homes: a random point in the unit ball) and its jiggle about it.
var homes := PackedVector3Array()
var jiggles := PackedVector3Array()
var rng := RandomNumberGenerator.new()
var radius := 0.05


## `count` dots of `dot_radius` m in `color` (a lighter top), random with generator seed `seed_value`.
func _init(count := 40, dot_radius := 0.05, color := ArtPalette.BLUE, seed_value := 1) -> void:
	name = "Particles"
	radius = dot_radius
	rng.seed = seed_value
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = dot_mesh(dot_radius, color)
	multimesh.instance_count = count
	multimesh.visible_instance_count = 0
	material_override = ArtKit.lit_material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	points.resize(count)
	homes.resize(count)
	jiggles.resize(count)


## One dot: a small ball in `color`.
static func dot_mesh(dot_radius: float, color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D.IDENTITY, dot_radius, RINGS, SIDES, color)
	return b.commit()


## How many dots there are (the MultiMesh's instances).
func capacity() -> int:
	return multimesh.instance_count


## How many dots show now.
func shown() -> int:
	return multimesh.visible_instance_count


## Shows the first `count` dots (0 hides them all).
func show_count(count: int) -> void:
	multimesh.visible_instance_count = clampi(count, 0, capacity())


## Every dot a new home, evenly at random in the unit ball (uniform in volume), and no jiggle.
func scatter_homes() -> void:
	for i in capacity():
		var dir := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		homes[i] = dir * pow(rng.randf(), 1.0 / 3.0)
		jiggles[i] = Vector3.ZERO


## Every shown dot's jiggle takes a random step of up to `speed` × `delta` m per axis (warmer: a bigger
## speed), kept within `wobble` m, and the dot goes to at(home, jiggle) (local to the cloud).
func spread(delta: float, speed: float, wobble: float, at: Callable) -> void:
	var step := speed * delta
	for i in shown():
		var j := jiggles[i] + Vector3(rng.randf_range(-step, step), rng.randf_range(-step, step), rng.randf_range(-step, step))
		jiggles[i] = j.limit_length(wobble)
		set_point(i, at.call(homes[i], jiggles[i]))


## Dot `i` at `p` (local) now.
func set_point(i: int, p: Vector3) -> void:
	points[i] = p
	multimesh.set_instance_transform(i, Transform3D(Basis(), p))


## `p` kept inside the upright cylinder of `r` round the y axis through `centre`'s x and z, between
## heights `bottom` and `top` (a glass's water).
static func in_cylinder(p: Vector3, centre: Vector3, r: float, bottom: float, top: float) -> Vector3:
	var flat := Vector2(p.x - centre.x, p.z - centre.z)
	if flat.length() > r:
		flat = flat.normalized() * r
	return Vector3(centre.x + flat.x, clampf(p.y, bottom, top), centre.z + flat.y)
