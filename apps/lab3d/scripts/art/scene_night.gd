## The night over a lab that lets the time run (#157 first, with TimeSign and FastClock; the approved
## mockup "밤이 지나는 중": the sky goes navy with stars and a moon, the scene goes dark). The same way as
## the volcano's night (VolcanoLab): the lab's clear colour, the shaders' global story tint
## (StoryDirector's) and the island ground's own extra tint (its own copy of the ground's material), plus
## a few glowing stars and a crescent moon far over the land (StarArt.glow_material: they keep their
## light). set_amount(0..1) poses it; clear() puts the day back (the lab calls it when it leaves the tree:
## the tint is global). Headless runs keep no global tint (no rendering server parameter there).
## Visual only.
class_name SceneNight
extends RefCounted

## The story tint at full night (a little lighter than the volcano's: the table's things must read),
## the night's clear colour and the ground's own extra tint.
const TINT := Vector3(0.32, 0.36, 0.64)
const SKY := Color("15204a")
const GROUND := Vector3(0.55, 0.38, 0.78)
## The stars: how many, how far (m), and the moon's place (a direction over the land) and size.
const STARS := 46
const STAR_FAR := 140.0
const MOON_DIR := Vector3(-0.35, 0.42, -1.0)
const MOON_R := 6.0
const MOON := Color("f4f1d0")

## How dark it is now (0 day .. 1 night).
var amount := 0.0
var sky: Node3D
var _environment: Environment
var _ground: ShaderMaterial
var _day_color := Color.BLACK
var _can_tint := false


## Takes the lab's world (built already: its WorldEnvironment and "Island" ground) and adds the night
## sky's stars and moon (hidden by day).
func attach(lab: Node3D) -> void:
	_can_tint = DisplayServer.get_name() != "headless"
	for child in lab.get_children():
		if child is WorldEnvironment:
			_environment = (child as WorldEnvironment).environment
			_day_color = _environment.background_color
		elif child is MeshInstance3D and child.name == "Island" and (child as MeshInstance3D).material_override is ShaderMaterial:
			_ground = (child as MeshInstance3D).material_override.duplicate()
			(child as MeshInstance3D).material_override = _ground
	sky = ArtKit.instance(sky_mesh(), StarArt.glow_material())
	sky.name = "NightSky"
	sky.visible = false
	lab.add_child(sky)


## The scene `k` dark (0 day .. 1 night).
func set_amount(k: float) -> void:
	amount = clampf(k, 0.0, 1.0)
	if sky != null:
		sky.visible = amount > 0.02
	if _environment != null:
		_environment.background_color = _day_color.lerp(SKY, amount)
	if _ground != null:
		_ground.set_shader_parameter("own_tint", Vector3.ONE.lerp(GROUND, amount))
	_set_tint(Vector3.ONE.lerp(TINT, amount))


## The day back (the tint is global: never leave the night on).
func clear() -> void:
	set_amount(0.0)


func _set_tint(tint: Vector3) -> void:
	if _can_tint:
		RenderingServer.global_shader_parameter_set(&"story_tint", tint)


## The night sky: little glowing stars over the far land within the camera's turn and a crescent moon.
static func sky_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in STARS:
		var a := deg_to_rad(lerpf(-70.0, 70.0, fposmod(i * 0.618034, 1.0)))
		var up := deg_to_rad(lerpf(10.0, 38.0, fposmod(i * 0.414214 + 0.1, 1.0)))
		var dir := Vector3(sin(a) * cos(up), sin(up), -cos(a) * cos(up))
		var size := 0.5 if i % 6 == 0 else 0.32
		var c := Color("fff3b0") if i % 4 == 0 else Color.WHITE
		_flat(b, dir * STAR_FAR, dir, size, c, 4)
	var moon_dir := MOON_DIR.normalized()
	var at := moon_dir * STAR_FAR * 0.95
	_flat(b, at, moon_dir, MOON_R, MOON, 18)
	var right := moon_dir.cross(Vector3.UP).normalized()
	var upv := right.cross(moon_dir).normalized()
	_flat(b, at + (right * 0.45 + upv * 0.25) * MOON_R - moon_dir * 0.5, moon_dir, MOON_R * 0.86, SKY, 18)
	return b.commit()


## A flat disc (`sides` corners) at `at` facing back along `dir` (towards the camera at the origin).
static func _flat(b: ArtMeshBuilder, at: Vector3, dir: Vector3, r: float, c: Color, sides: int) -> void:
	var right := dir.cross(Vector3.UP).normalized()
	var upv := right.cross(dir).normalized()
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var p0 := at + (right * cos(a0) + upv * sin(a0)) * r
		var p1 := at + (right * cos(a1) + upv * sin(a1)) * r
		b.add_triangle([at, p1, p0], [c, c, c], -dir)
