## 지진 (#97, 2026-11-07; Hutton Island's tenth spot, docs/islands/hutton-missions.md 10 and
## hutton-lines.md 10): a shake table in the squirrels' village with a block house on a slab of ground.
## The child pulls the table's red handle back and lets go, like the collision lab's slingshot: the
## farther the pull, the harder the table swings (EarthquakeModel.PULL_STEP levels, no number on the
## screen: the readout says it in words). The condition buttons pick the ground (단단한 바위 / 무른 모래)
## and the house (버팀대 없음 / 버팀대).
##
## Model and judging: EarthquakeModel (the table, the ground and the house as fixed-step oscillators,
## no random number): the stages are judged on its status ("stood", "held", "strongest", "toppled", "fell"),
## never on the engine. The house is ten Jolt rigid bodies (EarthquakeProps.blocks: the posts' cubes,
## the back wall's planks, the beam and the roof) on an AnimatableBody3D slab, the way the collision lab
## poses its engine balls on its formula: while the house stands its blocks are frozen (kinematic) and
## posed on the model's frame every step (racking with the model's drift), so the engine house is the
## model's to the millimetre. The step the model's house falls, the blocks are let go (unfrozen with
## their frame's velocity and a small seeded push, SEED) and Jolt brings them down on the shaking slab;
## the result is still the model's ("toppled" or "fell" from that step).
##
## The hand: one knob ("table") round the handle's knob, the slingshot's object (manipulation.slingshot):
## a press on it and a pull to the left along the rod (the surface "pull", a line through the knob)
## sets the pull, a release lets the table go (the action "release"); after a run a press on the knob
## readies the next shot (the screen's "rearm": 처음으로's reset, the house stands again).
class_name EarthquakeLab
extends EarthLab

const KNOB_ID := "table"
const KNOB_BOX := 1.15
## The block bodies: one layer with the slab, the base and the floor (the knob's layer is apart).
const BLOCK_LAYER := 1
const DENSITY := 300.0
## The fall: every block keeps its frame's velocity and gets a push away from the way it leaned (up to
## KICK m/s at the top), a little spin (up to SPIN rad/s), from a RandomNumberGenerator seeded SEED.
const SEED := 97
const KICK := 1.1
const SPIN := 2.2
## The pull's word (the slingshot readout) from the knob: over the middle of the full pull, up high.
const READOUT_FROM_KNOB := Vector3(-1.6, 2.4, 0.0)
## The graph samples every GRAPH_EVERY steps of a run.
const GRAPH_EVERY := 3

var props := EarthquakeProps.new()
## [body, spec] of the house's blocks (spec: EarthquakeProps.blocks()).
var blocks: Array = []
var slab_body: AnimatableBody3D
var collapsed := false
## The pull's level the next release lets go (the slingshot's control, not a sidebar one).
var pull := EarthquakeModel.PULL_MIN
## The pull's level while a finger pulls (INF: none).
var preview := INF
var _surface: ManipSurface
var _graph := PackedVector3Array()
var _graph_rev := 0


func _init() -> void:
	model = EarthquakeModel.new()


func _build_world() -> void:
	props.build(self)
	var grip := PhysicsMaterial.new()
	grip.friction = 0.9
	grip.bounce = 0.05
	_add_floor(grip, Vector3(40.0, 0.4, 30.0))
	var base := StaticBody3D.new()
	base.name = "TableBaseBody"
	base.physics_material_override = grip
	_add_box_shape(base, EarthquakeProps.BASE)
	base.position = EarthquakeProps.TABLE_CENTER + Vector3(0.0, EarthquakeProps.BASE.y * 0.5, 0.0)
	add_child(base)
	slab_body = AnimatableBody3D.new()
	slab_body.name = "SlabBody"
	slab_body.sync_to_physics = false
	slab_body.physics_material_override = grip
	_add_box_shape(slab_body, Vector3(EarthquakeProps.SLAB.x, 0.2, EarthquakeProps.SLAB.z))
	add_child(slab_body)
	for spec: Array in EarthquakeProps.blocks():
		blocks.append([_make_block(spec, grip), spec])
	add_knob(KNOB_ID, "HandleKnob", KNOB_BOX)
	_surface = ManipSurface.new(Transform3D(Basis(), EarthquakeProps.knob_at(0.0)), Vector2(-30.0, 0.0), Vector2(30.0, 0.0))
	game = EarthquakeGame.new(self)
	add_child(game)
	game.build()


## A block of the house: a rigid body (frozen, kinematic, until the house falls) with its mesh.
func _make_block(spec: Array, material: PhysicsMaterial) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = str(spec[0])
	body.collision_layer = 1 << (BLOCK_LAYER - 1)
	body.collision_mask = 1 << (BLOCK_LAYER - 1)
	body.physics_material_override = material
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	body.can_sleep = false
	var size: Vector3 = spec[3]
	if spec[1] == "roof":
		var shape := CollisionShape3D.new()
		var hull := ConvexPolygonShape3D.new()
		hull.points = EarthquakeProps.roof_points()
		shape.shape = hull
		body.add_child(shape)
		body.mass = DENSITY * size.x * size.y * size.z * 0.5
	else:
		_add_box_shape(body, size)
		body.mass = DENSITY * size.x * size.y * size.z
	var level := int(str(spec[0]).right(1)) if str(spec[0]).begins_with("Plank") else 0
	body.add_child(ArtKit.instance(EarthquakeProps.block_mesh(spec[1], size, level)))
	add_child(body)
	return body


## The conditions: the ground (rock / sand) and the house (no brace / brace), the model's starts.
func _apply_control(id: String, value: Variant) -> void:
	match id:
		"ground":
			model.set_start("ground", EarthquakeModel.SAND if str(value) == "sand" else EarthquakeModel.ROCK)
		"brace":
			model.set_start("brace", 1.0 if str(value) == "brace" else 0.0)


## The pull (the slingshot's value) is kept for the release and starts nothing; the conditions start
## the run over.
func set_control(id: String, value: Variant) -> void:
	if id == "pull":
		pull = EarthquakeModel.snapped_pull(float(value))
		return
	super(id, value)


func control_value(id: String) -> Variant:
	return pull if id == "pull" else super(id)


func run_action(id: String) -> void:
	match id:
		"release":
			release()
		"reset":
			reset_run()


## The pull let go: the house stands, the table swings from the pull.
func release() -> void:
	preview = INF
	_stand_house()
	model.release(pull)
	_graph.clear()
	_graph_rev += 1
	_show()
	_update_status()


## The house stands again and the table rests (처음으로, a new condition, the next shot's rearm).
func reset_run() -> void:
	_stand_house()
	_graph.clear()
	_graph_rev += 1
	if game != null:
		game.run_reset()
	super()


func _stand_house() -> void:
	collapsed = false
	for pair: Array in blocks:
		var body: RigidBody3D = pair[0]
		body.freeze = true
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	var m := model as EarthquakeModel
	var was := m.steps
	super(delta)
	if m.fell() and not collapsed:
		_collapse()
	if m.steps != was and m.steps % GRAPH_EVERY == 0:
		_graph.append(Vector3(m.steps / float(EarthquakeModel.STEPS_PER_SECOND), m.ground_x * 100.0, m.drift * 100.0))
		_graph_rev += 1


## The model's house just fell: every block is let go with its frame's velocity now (the ground's
## and the frame's racking) and a seeded push away from its lean; Jolt takes over.
func _collapse() -> void:
	collapsed = true
	var m := model as EarthquakeModel
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var lean := signf(m.drift) if m.drift != 0.0 else 1.0
	var ground_v := m.table_v * m.amplify()
	var height := EarthquakeModel.HOUSE_HEIGHT
	for pair: Array in blocks:
		var body: RigidBody3D = pair[0]
		var at: Vector3 = pair[1][2]
		var share := minf(at.y, height) / height
		body.freeze = false
		body.linear_velocity = Vector3(ground_v + m.drift_v * share + lean * KICK * share * rng.randf_range(0.6, 1.0), rng.randf_range(0.0, 0.5), rng.randf_range(-0.5, 0.5))
		body.angular_velocity = Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6), -lean * SPIN * rng.randf_range(0.4, 1.0))
	_redraw()


# --- drawing ---------------------------------------------------------------------------------------

func _redraw() -> void:
	var m := model as EarthquakeModel
	var deck_x := m.table
	var ground_x := m.ground_x
	var pull_to := Vector3.INF
	if preview != INF:   # a finger pulls: the deck (and the ground on it) slides back as far as the pull
		deck_x = -preview * EarthquakeModel.SWING_MAX
		ground_x = deck_x
		pull_to = EarthquakeProps.knob_at(0.0) + Vector3(-preview * EarthquakeProps.PULL_REACH, 0.0, 0.0)
	var standing := not collapsed
	props.show(deck_x, ground_x, m.amplify() > 1.0, m.braced(), m.drift if standing else 0.0, standing, pull_to)
	var since := m.steps / float(EarthquakeModel.STEPS_PER_SECOND)
	var strongest := m.released and m.input("pull") >= EarthquakeModel.FULL - 1e-9
	props.show_ground(since, m.running, clampf(since / EarthquakeProps.CRACK_S, 0.0, 1.0) if strongest else 0.0)
	slab_body.transform = Transform3D(Basis(), EarthquakeProps.house_foot(ground_x) + Vector3(0.0, -0.1, 0.0))
	if standing:
		_pose_house(ground_x, m.drift)


## The standing house on the ground at `ground_x`, its frame racked by `drift` (m at its top): the
## posts and the back wall lean with it, the beam and the roof ride its top.
func _pose_house(ground_x: float, drift: float) -> void:
	var foot := EarthquakeProps.house_foot(ground_x)
	var height := EarthquakeModel.HOUSE_HEIGHT
	var lean := Basis(Vector3.BACK, -atan2(drift, height))
	for pair: Array in blocks:
		var body: RigidBody3D = pair[0]
		var spec: Array = pair[1]
		var at: Vector3 = spec[2]
		if spec[1] in ["cube", "plank"]:
			body.transform = Transform3D(lean, foot + at + Vector3(drift * at.y / height, 0.0, 0.0))
		else:
			body.transform = Transform3D(Basis(), foot + at + Vector3(drift, 0.0, 0.0))


## Where block `name` stands on the model's frame now (tests: the engine body against it).
func posed_origin(body_name: String) -> Vector3:
	var m := model as EarthquakeModel
	var height := EarthquakeModel.HOUSE_HEIGHT
	for pair: Array in blocks:
		var spec: Array = pair[1]
		if spec[0] == body_name:
			var at: Vector3 = spec[2]
			var shift := m.drift * at.y / height if spec[1] in ["cube", "plank"] else m.drift
			return EarthquakeProps.house_foot(m.ground_x) + at + Vector3(shift, 0.0, 0.0)
	return Vector3.INF


func block(body_name: String) -> RigidBody3D:
	for pair: Array in blocks:
		if pair[0].name == body_name:
			return pair[0]
	return null


# --- the hand: the slingshot ---------------------------------------------------------------------

func manipulation_surface(_surface_id: String) -> ManipSurface:
	return _surface


## The knob stays round the handle's rest (a press there pulls; the pull's look is the props').
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), EarthquakeProps.knob_at(0.0))


## The pull's level for a finger `pull_x` m along the rod from the press (left: negative): the length
## to the left over PULL_REACH, on the PULL_STEP levels, at least PULL_MIN.
static func pull_level(pull_x: float) -> float:
	return EarthquakeModel.snapped_pull(-pull_x / EarthquakeProps.PULL_REACH)


## The pull's word ("살짝" .. "가장 세게"): no number on the screen. "살짝" is every pull the plain
## house stands on rock (up to half, stages 1-2 "살짝 흔들어", #114).
static func shake_word(level: float) -> String:
	if level >= EarthquakeModel.FULL - 1e-9:
		return "biggest"
	if level > 0.75:
		return "big"
	if level > EarthquakeModel.LIGHT_MAX + 1e-9:
		return "medium"
	return "small"


## The slingshot (the collision lab's): the knob pulled to the left along the rod; its value is
## (pull level, 0); a release sets "pull" and runs "release". The readout says the shake in words.
func slingshot_setup() -> Dictionary:
	var spec: Dictionary = definition.slingshot()
	if spec.is_empty():
		return {}
	return {"object": KNOB_ID, "surface": _surface, "launch": func() -> Vector3: return EarthquakeProps.knob_at(0.0),
		"controls": ["pull"], "value": func(p: Vector2) -> Vector2: return Vector2(pull_level(p.x), 0.0),
		"readout": func(value: Vector2) -> String: return Locale.t("earthquake.pull." + shake_word(value.x)),
		"demo": [Vector2(-120.0, 0.0), Vector2(-200.0, 0.0)], "readout_at": readout_point}


## Where the pull's word stands: over the pull, left of the house and above the knob (the screen's
## default spot, the view's top middle, is over the house's roof the child watches).
static func readout_point() -> Vector3:
	return EarthquakeProps.knob_at(0.0) + READOUT_FROM_KNOB


## The pull's value while a finger holds the knob (INF when the pull ends): the deck slides back.
func set_slingshot_preview(value: Variant) -> void:
	preview = (value as Vector2).x if value is Vector2 and value != Vector2.INF else INF
	_show()


# --- what the panels and the cast read ------------------------------------------------------------

## Words only (no number: the user): the run's result, the shake's strength, the ground.
func observations() -> Dictionary:
	var m := model as EarthquakeModel
	return {
		"state": Locale.t("earthquake.status." + m.status()),
		"shake": Locale.t("earthquake.shake." + (shake_word(m.input("pull")) if m.released else "none")),
		"ground": Locale.t("earthquake.ground." + ("sand" if m.amplify() > 1.0 else "rock")),
	}


## The ground's swing and the house's lean (cm) over the run ("자세히").
func graph_series() -> Dictionary:
	var ground := PackedVector2Array()
	var house := PackedVector2Array()
	for s in _graph:
		ground.append(Vector2(s.x, s.y))
		house.append(Vector2(s.x, s.z))
	return {"ground": ground, "house": house}


func graph_revision() -> int:
	return _graph_rev


## Dugi points at the house's roof; the camera follows the house.
func explain_point() -> Vector3:
	return EarthquakeProps.house_foot((model as EarthquakeModel).ground_x) + Vector3(0.0, EarthquakeProps.ROOF_BASE, 0.0)


func follow_point() -> Vector3:
	return EarthquakeProps.house_foot(0.0) + Vector3(0.0, 1.0, 0.0)
