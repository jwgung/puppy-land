## 화산 (#98, 2026-11-07; Hutton Island's last spot, docs/islands/hutton-missions.md 11 and
## hutton-lines.md 11): the island's volcano stands at the back by the sea, a small volcano model on a
## sand table in front. The child presses and holds the magma pump (press and hold: the press time is
## how much magma comes up, HoldRamp over VolcanoModel.PUMP_S); the lava comes out round the model's
## vent (stages 1 and 2) or out of the big volcano's crater (stage 3). The condition button
## (왼쪽 아래) picks the magma: 묽은 / 보통 / 끈적한.
##
## Model: VolcanoModel (rules, no formula: hutton.md "시뮬레이션"). The lab only draws it (EarthLab):
## the stages are judged on its status ("wide", "tall", "sea"; misses on "small", "thin", "plugged",
## "short"), never on a number on the screen.
##
## The hand: one knob ("pump"), a pickable box round the pump; the rule `"hold": true` makes a press
## on it a hold (Manipulator: Experiment.hold_started / hold_ended), nothing is dragged. Every press
## is a new eruption: the lava of the last one is cleared, the pump runs from empty while the finger
## stays (the gauge fills), the lava comes out after it and finishes a moment after the finger lets go
## (the run is settled then and judged).
##
## The site: stages 1 and 2 are the model on the table, stage 3 and a finished round the big volcano
## at night (hutton-lines.md 11: "1·2단계는 작은 화산 모형으로 먼저 알아보고, 3단계는 이미 부글거리는
## 화산"). The stage comes from the screen (set_game_stage); a stage just cleared keeps its result on
## the screen until the next stage's reset (the screen runs "reset" before it) and the site changes
## then. The night is the lab's clear colour and the shaders' global story tint (StoryDirector's), put
## back to the day when the lab leaves the tree.
class_name VolcanoLab
extends EarthLab

const KNOB_ID := "pump"
const MAGMA_CONTROL := "magma"
## The stage that is played on the big volcano (0-based).
const BIG_STAGE := 2
## The night's clear colour and the story tint (StoryDirector.NIGHT_TINT's blue, a little brighter:
## the pump and the cast must still read; 2026-11-07 user: a step darker).
const NIGHT_TINT := Vector3(0.27, 0.3, 0.58)
## The island ground's own extra night on top of the tint (2026-11-07 user: the night was too bright
## and the grass stayed green): its own copy of the ground's material (map_lit own_tint, as the map's
## sky backdrop does), so the grass, the far land, the haze and the clouds go dark blue while the
## cast and the pump keep the lighter tint above. The map screen's material is not touched.
const GROUND_NIGHT := Vector3(0.5, 0.32, 0.74)
const GRAPH_STEP := 0.05
## The margin (deg) round the big volcano's width in which another spot's far landmark is left out.
const LANDMARK_MARGIN_DEG := 4.0
## How far (m) past the volcano's foot a tree of the lab's own that stood on its slope is moved.
const TREE_CLEAR := 1.6

var props := VolcanoProps.new()
## The press: the pump's share of a full pump while the finger holds (HoldRamp, fixed steps).
var pump := HoldRamp.new(1.0 / VolcanoModel.PUMP_S, 1.0)
## The share pumped in the last press (it stays on the gauge until the next press or a reset).
var pumped := 0.0
var _site_due := -1.0        # a site to take at the next reset (a stage just cleared), -1 none
var _environment: Environment
var _ground: ShaderMaterial    # the island ground's own material (its night)
var _day_color := Color.BLACK
var _can_tint := false
var _graph_key := Vector2.INF
var _graph_revision := 0


func _init() -> void:
	model = VolcanoModel.new()


func _build_world() -> void:
	_can_tint = DisplayServer.get_name() != "headless"
	props.build(self)
	for child in get_children():
		if child is WorldEnvironment:
			_environment = (child as WorldEnvironment).environment
			_day_color = _environment.background_color
		elif child is MeshInstance3D and child.name == "Island":
			_ground = (child as MeshInstance3D).material_override.duplicate()
			(child as MeshInstance3D).material_override = _ground
	var knob := add_knob(KNOB_ID, "PumpKnob")
	(knob.get_child(0) as CollisionShape3D).shape.size = VolcanoProps.PUMP_BOX
	game = VolcanoGame.new(self)
	add_child(game)
	game.build()


func _exit_tree() -> void:
	_set_tint(Vector3.ONE)   # never leave the night on (StoryDirector does the same)


## The magma condition: 묽은 / 보통 / 끈적한 (the model's start: kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == MAGMA_CONTROL:
		model.set_start("stickiness", VolcanoModel.stickiness_of(str(value)))


# --- the site (the stage) ---------------------------------------------------------------------------

## The stage changed: stage 3 (and a finished round) is the big volcano at night. A stage just cleared
## keeps its result until the next reset; opened or jumped to, the site is set at once.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	var site := VolcanoModel.BIG if stage < 0 or stage >= BIG_STAGE else VolcanoModel.SMALL
	if just_cleared and model.input("site") != site:
		_site_due = site
	else:
		_set_site(site, not just_cleared)
	_show_goals(stage)


func _set_site(site: float, at_once := false) -> void:
	_site_due = -1.0
	model.set_start("site", site)
	props.set_night(site >= VolcanoModel.BIG, at_once)
	if is_inside_tree():
		_show()


func _show_goals(stage: int) -> void:
	props.show_goals(stage == 0, stage == 1)


func reset_run() -> void:
	if _site_due >= 0.0:
		_set_site(_site_due)
	pump.stop()
	pumped = 0.0
	super()
	if game != null:
		game.run_reset()


# --- the hand: press and hold the pump -----------------------------------------------------------

## A press: a new eruption. The last lava is cleared and the pump runs from empty.
func hold_started(id: String) -> void:
	if id != KNOB_ID:
		return
	if _site_due >= 0.0:
		_set_site(_site_due)
	holding = id
	model.reset()
	pumped = 0.0
	pump.start()
	if game != null:
		game.run_reset()
	_show()
	_update_status(true)


## Let go (or cancelled): the pump stops; the lava already pumped still comes out.
func hold_ended(id: String) -> void:
	if id != KNOB_ID or holding != id:
		return
	holding = ""
	pump.stop()
	_show()
	_update_status()


## While the finger holds, the pump runs a fixed step at a time and the lava follows (EarthLab steps
## the glide); after, EarthLab finishes the lava's glide.
func _physics_process(delta: float) -> void:
	if holding == KNOB_ID:
		pump.tick()
		pumped = pump.force()
		model.set_input("magma", pumped)
		model.glide_to("lava", pumped)
		if not model.animating():
			_show()
			_update_status(true)
	super(delta)


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)
	var tint := Vector3.ONE.lerp(NIGHT_TINT, props.night)
	_set_tint(tint)
	if _environment != null:
		_environment.background_color = _day_color.lerp(VolcanoProps.NIGHT_SKY, props.night)
	if _ground != null:
		_ground.set_shader_parameter("own_tint", Vector3.ONE.lerp(GROUND_NIGHT, props.night))


func _set_tint(tint: Vector3) -> void:
	if _can_tint:
		RenderingServer.global_shader_parameter_set(&"story_tint", tint)


## LabWorld asks: one of the lab's own trees (ArtKit.TREES) on the big volcano's slope stands off it,
## pushed out from the volcano's middle to its foot and TREE_CLEAR m more (2026-11-07 user: a tree
## stood half buried in the slope).
func near_tree_at(at: Vector2) -> Vector2:
	var middle := Vector2(VolcanoProps.VOLCANO_AT.x, VolcanoProps.VOLCANO_AT.z)
	var reach := VolcanoProps.VOLCANO_RADIUS + TREE_CLEAR
	if at.distance_to(middle) >= reach:
		return at
	return middle + (at - middle).normalized() * reach


## LabWorld asks: another spot's landmark on the far land right behind the big volcano (seen from the
## front view's eye, within the volcano's width and LANDMARK_MARGIN_DEG) is left out of this lab's
## view (2026-11-07 user: it showed through over the volcano). The map screen keeps it.
func hides_far_landmark(at: Vector2) -> bool:
	var eye := _front_eye()
	var to_volcano := Vector2(VolcanoProps.VOLCANO_AT.x - eye.x, VolcanoProps.VOLCANO_AT.z - eye.z)
	var to_mark := Vector2(at.x - eye.x, at.y - eye.z)
	if to_mark.length() <= to_volcano.length():
		return false
	var half := asin(clampf(VolcanoProps.VOLCANO_RADIUS / to_volcano.length(), 0.0, 1.0)) + deg_to_rad(LANDMARK_MARGIN_DEG)
	return absf(to_volcano.angle_to(to_mark)) <= half


## The front view's camera position (the lab's camera: its target, distance and front pitch).
func _front_eye() -> Vector3:
	var camera: Dictionary = definition.camera() if definition != null else {}
	var t: Array = camera.get("target", [0.0, 0.0, 0.0])
	var pitch := deg_to_rad(float(camera.get("views", {}).get("front", {}).get("pitch_deg", 0.0)))
	var d := float(camera.get("distance", 0.0))
	return Vector3(float(t[0]), float(t[1]) - d * sin(pitch), float(t[2]) + d * cos(pitch))


## The pump's top (the button) is where a finger presses it and where the hand guide shows.
func manipulation_pick_point(_id: String) -> Vector3:
	return props.button_top()


## The knob covers the pump's button and the top of its tank, centred on the button (its pick point:
## a finger anywhere on the box takes it, Manipulator._pick).
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), props.button_top())


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	props.show(model as VolcanoModel, holding == KNOB_ID, pumped, holding == KNOB_ID or model.animating())


## Words only (no amounts, no metres: the user): what the lava made, how much magma came up, and how
## sticky it is.
func observations() -> Dictionary:
	var m := model as VolcanoModel
	var lava := m.input("lava")
	var amount := "none" if lava <= 0.0 else "little" if lava < 0.34 else "middle" if lava < 0.67 else "lots"
	return {
		"state": Locale.t("volcano.status." + m.status()),
		"amount": Locale.t("volcano.amount." + amount),
		"magma": Locale.t("volcano.magma." + m.kind()),
	}


## The small model's cone against the lava (x: the lava, m^3; y: m) for the magma now: its height and
## its reach, and where the lava is now ("자세히": the screen shows no number).
func graph_series() -> Dictionary:
	var m := model as VolcanoModel
	var high := PackedVector2Array()
	var far := PackedVector2Array()
	var share := 0.0
	while share <= 1.0 + 1e-9:
		var volume := share * VolcanoModel.MODEL_VOLUME
		high.append(Vector2(volume, VolcanoModel.height_of(share, m.stickiness())))
		far.append(Vector2(volume, VolcanoModel.reach_of(share, m.stickiness())))
		share += GRAPH_STEP
	var now := m.input("lava") * VolcanoModel.MODEL_VOLUME
	return {"height": high, "reach": far, "now": PackedVector2Array([Vector2(now, m.height()), Vector2(now, m.reach())])}


func graph_revision() -> int:
	var key := Vector2(model.input("lava"), model.input("stickiness"))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## Dugi points at the lava: the model's vent, or the big volcano's crater.
func explain_point() -> Vector3:
	var m := model as VolcanoModel
	return VolcanoProps.crater_top() if m.big() else VolcanoProps.VENT + Vector3(0.0, m.height() * 0.5, 0.0)


## The camera follows the pump (the thing the finger presses).
func follow_point() -> Vector3:
	return VolcanoProps.PUMP_AT + Vector3(0.0, 1.0, 0.0)
