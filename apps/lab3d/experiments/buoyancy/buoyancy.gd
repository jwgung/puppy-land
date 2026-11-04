## Guided buoyancy lab (Phase 1 Task 4d; web preset "buoyancy", "물체는 언제 물에 뜰까?"): an upright drum
## in a water tank (water 1000 kg/m^3). The finger drags the drum up into the air or down into the
## water (0.05 m grid) and letting go releases it from rest there; "놓기" releases it again from the
## same place. Conditions: the drum's mass (the web's mass input; 5-150 kg) and its volume (100 L or
## 50 L: the same density floats at the same share of its height).
## Motion and every displayed number: BuoyancyModel (the web's BuoyancyRegionLaw and gravity, 4
## semi-implicit Euler substeps per fixed step, the web's floor rule). BodyModelDriver poses the
## engine drum on it every step (method "kinematic_model"): the panel has no engine measurement. The
## floating depth and the judgement (floats / stays / sinks) come from the densities.
## See docs/formula-correction.md (Task 4d).
## The drum's size is its volume; its mass is the iron weight and the number tag on its lid
## (BuoyancyProps.set_mass, 2026-10-28), visual only.
extends ModelDrivenLab

const WATERLINE := 1.5
const FLOOR_Y := 0.2
const TANK_TOP := 2.1
const HOLD_ABOVE := 1.0           # m: the drum's bottom may be held this far above the water
const START_ABOVE := 0.3          # m: the drum's bottom above the water at the start
const WATER_DENSITY := 1000.0     # kg/m^3
const DRUM_LAYER := 3             # pickable; the drum touches nothing in the engine (mask 0)
const SETTLED_SPEED := 0.002      # m/s: slower than this = at rest (sunk on the tank floor, staying under water)
## Floating (2026-11-03 playtest: the floating judgement was too strict for the kids): a drum the densities say floats counts as
## floating once its bob about the formula's floating depth is FLOAT_BOB or less (bob(): the depth error and
## the speed taken as one swing) while it is in the water with its top out of it, and stays floating for the
## rest of the run (no flicker as it bobs on). Before: slower than 0.002 m/s and within 0.002 m of the
## floating depth (8 s after the start drum's release, 26 s for a 5 kg drum). Only the judging: the motion
## is the formula's as before.
const FLOAT_BOB := 0.03           # m
## The load with the bread cat on the drum (kid.picks.mass "빵고양이 태우기", the stages' "mass" min): from
## this mass on the cat rides the drum (2026-11-03 playtest "빵고양이 태우기가 실제로 안 타"). Visual only.
const CAT_RIDE_MASS := 80.0       # kg
const WAY_MARGIN := 0.12          # m around the cat's way (keep_in_sight): its paws and lean as it holds and lets go
const SPLASH_SPEED := 0.5         # m/s: a slower entry into the water gets no splash
const FLOOR_HIT_SPEED := 0.3      # m/s: a slower floor contact gets no bump

var model := BuoyancyModel.new()
var drum: RigidBody3D
## Conditions (64-bit).
var mass := 70.0
var volume_id := "big"
var start_bottom := WATERLINE + START_ABOVE   # height of the drum's bottom it is released from (m)
var splashes := 0
## This run's drum has floated (FLOAT_BOB): it stays "floating" until the run starts over.
var _afloat := false
var _floor: StaticBody3D
var _tank_floor: StaticBody3D
var _shape: CylinderShape3D


func _init() -> void:
	driver = BodyModelDriver.new()
	props = BuoyancyProps.new()


func set_control(id: String, value: Variant) -> void:
	match id:
		"mass":
			var clamped := definition.clamp_value(id, float(value))
			if is_nan(clamped):
				return
			mass = clamped
			props.set_mass(mass)
		"volume":
			if definition.option(id, str(value)).is_empty():
				push_warning("buoyancy: unknown volume %s" % value)
				return
			volume_id = str(value)
			_resize()
		_:
			return
	_restart()


func control_value(id: String) -> Variant:
	match id:
		"mass":
			return mass
		"volume":
			return volume_id
	return super(id)


func run_action(id: String) -> void:
	match id:
		"release":
			release()
		"reset":
			start_bottom = WATERLINE + START_ABOVE
			_placed = false
			reset_run()


## Volume (m^3) and height (m) of the chosen drum; its radius from V = pi r^2 h.
func volume() -> float:
	return float(definition.option("volume", volume_id).get("volume", 0.1))


func drum_height() -> float:
	return float(definition.option("volume", volume_id).get("height", 0.5))


func drum_radius() -> float:
	return sqrt(volume() / (PI * drum_height()))


## The drum's collision shape and props for the chosen volume.
func _resize() -> void:
	if _shape == null:
		return
	_shape.radius = drum_radius()
	_shape.height = drum_height()
	props.set_drum(drum_radius(), drum_height())


func _load_model() -> void:
	model.mass = mass
	model.displaced_mass = WATER_DENSITY * volume()
	model.height = drum_height()
	model.waterline = WATERLINE
	model.floor_y = FLOOR_Y
	model.g = engine_g
	model.reset(start_bottom + drum_height() * 0.5, 0.0, 0.0)
	_afloat = false


## The drum's bob about the floating depth (m): its depth error and its speed as one swing of the water's
## spring on it, sqrt(e² + (v / ω)²) with ω² = ρ g A / (its mass and the water it pushes along). Judging
## only (floating, FLOAT_BOB).
func bob() -> float:
	var e := model.depth() - model.floating_depth()
	var w2 := model.displaced_mass * model.g / model.height / model.inertia()
	return sqrt(e * e + model.vy * model.vy / w2)


## The drum floats now: the densities say so, it is in the water with its top out, bobbing FLOAT_BOB or less.
func _floats_now() -> bool:
	var f := model.fraction()
	return model.judgement() == "floats" and f > 0.0 and f < 1.0 and bob() <= FLOAT_BOB


## The bread cat rides the drum with this load (CAT_RIDE_MASS on).
func cat_rides() -> bool:
	return mass >= CAT_RIDE_MASS - 1e-9


func reset_run() -> void:
	if drum == null:
		return
	_clear_run()
	props.reset()
	if game != null:
		game.run_reset()
	_update_status(true)


## (t, submerged depth).
func _graph_point() -> Vector2:
	return Vector2(model.time(), model.depth())


func _physics_process(_delta: float) -> void:
	if not released or holding != "":
		return
	driver.step(1.0 / float(Engine.physics_ticks_per_second))
	if not _afloat and _floats_now():
		_afloat = true
	if model.entered and model.entry_speed >= SPLASH_SPEED:
		splashes += 1
		props.splash(model.entry_speed)
		impact.emit(clampf(model.entry_speed / 6.0, 0.15, 0.6))
	if model.hit_floor and model.hit_speed >= FLOOR_HIT_SPEED:
		props.hit_floor(model.hit_speed)
		impact.emit(clampf(model.hit_speed / 6.0, 0.15, 0.6))
	if _graph_due(model.steps, model.time()):
		_add_graph_point()
	if status() != _last_status:
		_update_status()


func _process(delta: float) -> void:
	if drum == null:
		return
	if game == null or not game.cat_busy():   # (crossing to the islet: the piece game moves the cat)
		props.update_cat(drum.global_position, released, holding != "", cat_rides(), model.judgement() != "floats", delta)
	if holding != "":
		props.hide_forces()
		return
	props.show_forces(drum.global_position, model.weight(), model.buoyant_force(), model.displaced_mass * model.g)


## ready (waiting), held, moving, floating (bobbing FLOAT_BOB or less about the floating depth, then for
## the rest of the run), staying (neutral, at rest under water), sunk (at rest on the tank floor).
func status() -> String:
	if holding != "":
		return "held"
	if not released:
		return "ready"
	# The densities decide what the drum is (a neutral one that touches the floor is not "sunk"; a
	# drum that sinks or stays never floats).
	match model.judgement():
		"floats":
			if _afloat:
				return "floating"
		"sinks":
			if absf(model.vy) < SETTLED_SPEED and model.bottom() <= FLOOR_Y + 1e-9 and model.net_force() <= 0.0:
				return "sunk"
		"neutral":
			if absf(model.vy) < SETTLED_SPEED and model.fraction() == 1.0:
				return "staying"
	return "moving"


## The bread cat's way (2026-11-03 playtest "퍼피의 말풍선에 빵고양이가 이동하는 모습이 가려짐"): one box over
## the cat on its crates, on the lid of the waiting drum and of the drum at the waterline (where it floats
## or the cat jumps off) and on the islet, with its hops' rise and WAY_MARGIN; Puppy's bubble stays clear of it.
func keep_in_sight() -> Array[AABB]:
	var cat: CatActor = props.cat if props != null else null
	if cat == null or not cat.is_inside_tree() or drum == null:
		return []
	var local := cat.bounds()
	local.position -= cat.global_position
	var h := drum_height()
	var floating_top := WATERLINE - minf(model.floating_depth(), h) + h
	var stands: Array[Vector3] = [BuoyancyProps.cat_home(), props.lid_stand(Vector3(0.0, start_bottom + h * 0.5, 0.0)),
		props.lid_stand(Vector3(0.0, floating_top - h * 0.5, 0.0))]
	if game != null:
		stands.append((game as BuoyancyGame).islet_stand())
	var box := AABB(stands[0] + local.position, local.size)
	for p in stands:
		box = box.merge(AABB(p + local.position, local.size))
	box.size.y += BuoyancyProps.RIDE_HOP_UP
	return [box.grow(WAY_MARGIN)]


func _status_changed(previous: String, current: String) -> void:
	props.status_changed(previous, current)


func observations() -> Dictionary:
	var state_text: String = {
		"ready": Locale.t("buoyancy.status.ready"),
		"held": Locale.t("buoyancy.status.held"),
		"moving": Locale.t("buoyancy.status.moving"),
		"floating": Locale.t("buoyancy.status.floating"),
		"staying": Locale.t("buoyancy.status.staying"),
		"sunk": Locale.t("buoyancy.status.sunk"),
	}.get(status(), "")
	var judgement_text: String = {
		"floats": Locale.t("buoyancy.judgement.floats"),
		"neutral": Locale.t("buoyancy.judgement.neutral"),
		"sinks": Locale.t("buoyancy.judgement.sinks"),
	}.get(model.judgement(), "")
	return {
		"state": state_text,
		"judgement": judgement_text,
		"density": PhysicsLaws.density(model.mass, volume()),
		"floating_depth": model.floating_depth(),
		"depth": model.depth(),
		"buoyant": model.buoyant_force(),
		"weight": model.weight(),
		"net": model.net_force(),
		"speed": absf(model.vy),
	}


## Submerged depth over time since the release, and the floating depth of the formula (a level line).
func graph_series() -> Dictionary:
	var depth := PackedVector2Array()
	for p in _graph:
		depth.append(p)
	var level := model.floating_depth()
	return {"depth": depth, "floating": PackedVector2Array([Vector2(0.0, level), Vector2(graph_x_max(), level)])}


func _main_body() -> RigidBody3D:
	return drum


## Height of the drum's bottom for a centre at world y on the drum's grid (manipulation snap, whole cells),
## between the tank floor and HOLD_ABOVE over the water.
func bottom_at(centre_y: float) -> float:
	return _snap_to_grid("drum", centre_y - drum_height() * 0.5, FLOOR_Y, WATERLINE + HOLD_ABOVE)


# --- world --------------------------------------------------------------------------------------

func _build_world() -> void:
	_floor = _add_floor(null, Vector3(30.0, 0.4, 22.0))
	# The tank floor (the drum's shadow lands on it; the drum itself touches nothing).
	_tank_floor = StaticBody3D.new()
	_tank_floor.name = "TankFloor"
	_add_box_shape(_tank_floor, Vector3(BuoyancyProps.HALF_X * 2.0, FLOOR_Y, BuoyancyProps.HALF_Z * 2.0))
	_tank_floor.position = Vector3(0.0, FLOOR_Y * 0.5, 0.0)
	add_child(_tank_floor)
	_shape = CylinderShape3D.new()
	drum = _make_driven_body("Drum", _shape, DRUM_LAYER)
	drum.position = Vector3(0.0, start_bottom + drum_height() * 0.5, 0.0)
	add_child(drum)
	props.dress(self, drum, drum_radius(), drum_height(), FLOOR_Y, WATERLINE, TANK_TOP)
	_resize()
	_load_model()
	driver.history_steps = _history_steps()
	driver.bind(model, drum)
	driver.reset()
	game = BuoyancyGame.new(self)   # the piece game: the islet with the piece, the cat's crossing (visual only)
	add_child(game)
	game.build()


# --- manipulation -------------------------------------------------------------------------------

func manipulation_body(id: String) -> PhysicsBody3D:
	return drum if id == "drum" else null


## A vertical line through the tank's middle: the drum's centre from resting on the tank floor to
## HOLD_ABOVE over the water.
func manipulation_surface(surface_id: String) -> ManipSurface:
	if surface_id != "tank":
		return null
	var half := drum_height() * 0.5
	var surface := UprightLineSurface.new(Vector3.ZERO, FLOOR_Y + half, WATERLINE + HOLD_ABOVE + half, definition.grid_step("drum"), half)
	surface.exclude = [_floor.get_rid(), _tank_floor.get_rid(), drum.get_rid()]
	return surface


func manipulation_juice(id: String) -> ArtJuice:
	return props.juice if id == "drum" else null


## Put down = let go: released from rest there (a restored placement only sets the height).
func manipulation_placed(_id: String, transform: Transform3D) -> void:
	holding = ""
	_placed = true
	start_bottom = bottom_at(transform.origin.y)
	_release_or_defer()


func _placement_transforms() -> Dictionary:
	return {"drum": Transform3D(Basis(), Vector3(0.0, start_bottom + drum_height() * 0.5, 0.0))}
