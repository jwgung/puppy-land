## Base of the earth labs (#70, 2026-11-06; Hutton Island's sky and weather spots, docs/islands/hutton.md
## "시뮬레이션"): a pure model (EarthModel) holds the state and the 3D only draws it. No rigid body, no
## formula corrector, no engine physics: the lab steps the model at the fixed step while it is
## animating (a glide), draws it, and answers status(), observations() and settled() from it, which is
## all MissionRound reads. ModelDrivenLab stays the base of the labs whose engine bodies follow a
## formula model; this base has no body to drive.
##
## The hand (2026-11-06 decision, issue #70): the child drags a knob, a pickable StaticBody3D that
## touches nothing (mask 0, like the projectile's arrow knob and the pulley's rope end), with the
## shell's Manipulator. The HandGuide gesture and "one manipulation = one attempt" come with it: the
## definition's `manipulation` declares the knob's rule (surface, snap, guide / guide_to) as for any
## lab. While a finger holds the knob the model follows it every frame; the put-down sets the model
## to the knob's place; a cancel puts the knob back and the model with it. When no finger holds it,
## the knob sits where the model says (after a glide, a reset).
##
## A subclass:
## - sets `model` in _init() or _build_world(), builds its world in _build_world() and adds its
##   knobs there (add_knob);
## - draws the model in _redraw() (called after every change and every animating step);
## - maps its knob to the model: _knob_inputs() (a knob's place -> input values), _knob_pose() (the
##   model -> the knob's place) and manipulation_surface() (the surface the knob is dragged on);
## - maps a choice control to the model in _apply_control() (a number control whose id is an
##   input sets that input's start by default).
class_name EarthLab
extends Experiment

## Pickable knobs (mask 0: never hit by anything).
const KNOB_LAYER := 2
const KNOB_SIZE := 0.6

## The lab's model (set by the subclass).
var model: EarthModel
## id -> the knob (StaticBody3D) a finger drags.
var knobs := {}
## The knob a finger holds ("" = none): the model follows it.
var holding := ""
## Run resets (tests).
var reset_count := 0
## Fixed steps the model was stepped (tests).
var step_count := 0
## id -> the control values set (control_value()).
var _controls := {}
## id -> true: knobs put down by hand (or restored), kept by placements().
var _placed := {}
## id -> the knob transform the model last followed while held.
var _followed := {}
## time_scale's steps owed (a faster playback steps more often at the same dt).
var _pace := 0.0


func _ready() -> void:
	_build_world()
	begin_batch()   # the defaults restart the run once, not once per control
	for control in definition.controls():
		set_control(control.id, control.default)
	end_batch()
	_show()


# --- the subclass fills these in --------------------------------------------------------------------

## The lab's 3D world, its model and its knobs (before the controls' defaults are set).
func _build_world() -> void:
	pass


## Draws the model now (meshes, the sky, the shadow). Visual only.
func _redraw() -> void:
	pass


## The model inputs (id -> value) the knob `id` at `xf` stands for.
func _knob_inputs(_id: String, _xf: Transform3D) -> Dictionary:
	return {}


## Where the knob `id` stands for the model now.
func _knob_pose(id: String) -> Transform3D:
	var knob: StaticBody3D = knobs.get(id)
	return knob.global_transform if knob != null else Transform3D.IDENTITY


## A control's value on the model: a number control named like an input sets its start (a
## condition, kept across reset_run). A lab with choices maps them here.
func _apply_control(id: String, value: Variant) -> void:
	if model != null and model.has_input(id) and (value is float or value is int):
		model.set_start(id, float(value))


# --- shared -------------------------------------------------------------------------------------

## Adds a knob for manipulation object `id`: a pickable StaticBody3D (KNOB_LAYER, mask 0) named
## `knob_name`, a box of `size`. It draws nothing; the lab's mesh shows what the finger holds.
func add_knob(id: String, knob_name: String, size := KNOB_SIZE) -> StaticBody3D:
	var knob := _make_knob(knob_name, KNOB_LAYER, size)
	knobs[id] = knob
	return knob


func _physics_process(_delta: float) -> void:
	if model == null or not model.animating():
		_pace = 0.0
		return
	var dt := 1.0 / Engine.physics_ticks_per_second
	_pace += time_scale
	while _pace >= 1.0 and model.animating():
		_pace -= 1.0
		model.step(dt)
		step_count += 1
	_show()
	_update_status()


## The model follows a held knob (the Manipulator moves it between frames).
func _process(_delta: float) -> void:
	if holding == "" or not knobs.has(holding):
		return
	var xf: Transform3D = knobs[holding].global_transform
	if not _followed.has(holding) or _followed[holding] != xf:
		_follow_knob(holding, xf)
		_show()
		_update_status(true)


## The model takes the inputs of knob `id` at `xf`.
func _follow_knob(id: String, xf: Transform3D) -> void:
	_followed[id] = xf
	var inputs := _knob_inputs(id, xf)
	for input_id in inputs:
		model.set_input(input_id, float(inputs[input_id]))


## Draws the model and puts every knob a finger does not hold where the model says.
func _show() -> void:
	for id in knobs:
		if id != holding:
			knobs[id].global_transform = _knob_pose(id)
	_redraw()


func status() -> String:
	return model.status() if model != null else ""


## Nothing is under way: no glide, and no finger holds a knob (a drag is not a result until let go).
func settled() -> bool:
	return holding == "" and (model == null or not model.animating())


func observations() -> Dictionary:
	return model.observations() if model != null else {}


func set_control(id: String, value: Variant) -> void:
	_controls[id] = value
	_apply_control(id, value)
	_restart()


func control_value(id: String) -> Variant:
	return _controls.get(id, definition.default_value(id))


## The run starts over from the conditions: the model's inputs back at their starts, no glide.
func reset_run() -> void:
	reset_count += 1
	if model != null:
		model.reset()
	_placed.clear()
	if is_inside_tree():
		_show()
	_update_status(true)


func run_action(id: String) -> void:
	if id == "reset":
		reset_run()


func manipulation_body(id: String) -> PhysicsBody3D:
	return knobs.get(id)


func manipulation_started(id: String) -> void:
	holding = id
	_followed.erase(id)
	_update_status(true)


## Put down (or a saved placement restored): the model takes the knob's place.
func manipulation_placed(id: String, transform: Transform3D) -> void:
	holding = ""
	if knobs.has(id):
		knobs[id].global_transform = transform
	_follow_knob(id, transform)
	_placed[id] = true
	_show()
	_update_status()


## The shell put the knob back where it was picked up: the model goes back with it.
func manipulation_cancelled(id: String) -> void:
	holding = ""
	if knobs.has(id):
		_follow_knob(id, knobs[id].global_transform)
	_show()
	_update_status(true)


func placements() -> Dictionary:
	var out := {}
	for id in _placed:
		out[id] = knobs[id].global_transform
	return out


func follow_point() -> Vector3:
	for id in knobs:
		return knobs[id].global_position
	return global_position
