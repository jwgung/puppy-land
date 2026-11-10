## 지층 쌓기 (#96, 2026-11-07; Hutton Island's ninth spot, docs/islands/hutton-missions.md 9 and
## hutton-lines.md 9): a terrace in the valley under the striped cliff. The child drags a bucket of
## gravel, sand, mud or grey ash from the bench onto the water tank and lets go: it pours, and the
## layer settles on what is already there (the first one poured ends at the bottom). The shell is
## dragged in the same way and lies on the pile until the next pour buries it. In the third stage the
## child copies the striped cliff in the tank (자갈, 모래, 회색 재, 진흙: #114, the stage goes on from the
## first two) and the piece shows in the cliff's layer under the ash (StrataGame). No condition buttons
## (hutton-missions.md 9).
##
## Model: StrataModel (a rule, no formula: docs/islands/hutton.md "시뮬레이션"). The lab only draws it
## (EarthLab) and sets the pile the stage asks for (StrataModel.goal); the stages are judged on its
## status ("layered", "fossil", "copied"; the misses "mixed", "shell_off", and "layered" in the third),
## never on a number on the screen.
##
## The hand: one knob per bucket and one for the shell, dragged on the vertical plane in front of the
## bench and the tank (no footprint marker). A knob let go over the tank pours (or drops the shell);
## anywhere else the bucket goes back to the bench. Each stage offers only its own objects
## (set_game_stage: the buckets in every stage, the shell in stage 2; all of them outside a round).
## Nothing is kept by placements(): a pour is an event, not a place (a rebuilt screen starts with an
## empty tank).
class_name StrataLab
extends EarthLab

const SHELL_ID := "shell"
const BUCKET_KNOB := 1.0
const SHELL_KNOB := 0.8
## The drag plane's frame: x across, its normal towards the camera, its z down (plane (x, -y)).
const UPRIGHT := Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
## Where the buckets may be dragged (world x and y of their centres).
const REACH_X := Vector2(-6.4, 2.3)
const REACH_Y := Vector2(0.6, 4.6)

var props := StrataProps.new()
## The stage being played (-1: no round, or the round is done: every object).
var stage := -1
var _drag: ManipSurface


func _init() -> void:
	model = StrataModel.new()


func _build_world() -> void:
	props.build(self)
	for material: String in StrataModel.MATERIALS:
		add_knob(material, "Bucket_%s_Knob" % material, BUCKET_KNOB)
	add_knob(SHELL_ID, "ShellKnob", SHELL_KNOB)
	_drag = ManipSurface.new(Transform3D(UPRIGHT, Vector3(0.0, 0.0, StrataProps.DRAG_Z - BUCKET_KNOB * 0.5)),
		Vector2(REACH_X.x, -REACH_Y.y), Vector2(REACH_X.y, -REACH_Y.x))
	game = StrataGame.new(self)
	add_child(game)
	game.build()


# --- the stage's objects --------------------------------------------------------------------------

func set_game_stage(stage_now: int, stamps: int, just_cleared: bool) -> void:
	super(stage_now, stamps, just_cleared)
	stage = stage_now
	(model as StrataModel).goal = StrataModel.CLIFF if stage_now == 2 else StrataModel.ORDER
	if is_inside_tree():
		_show()


## The object `id` takes a finger in this stage (and not while a pour settles).
func offered(id: String) -> bool:
	var m := model as StrataModel
	if m.animating():
		return false
	if id == SHELL_ID:
		return (stage < 0 or stage == 1) and not (m.has_shell() and m.tank_status() not in StrataModel.FINISHED)
	return true


func manipulation_body(id: String) -> PhysicsBody3D:
	return knobs.get(id) if offered(id) or holding == id else null


func manipulation_surface(_surface_id: String) -> ManipSurface:
	return _drag


func _knob_pose(id: String) -> Transform3D:
	if id == SHELL_ID:
		return Transform3D(UPRIGHT, StrataProps.shell_home())
	return Transform3D(UPRIGHT, StrataProps.bucket_home(id))


## Let go: over the tank a bucket pours and the shell drops in. The knob then goes back to its place
## (EarthLab._show).
func manipulation_placed(id: String, transform: Transform3D) -> void:
	var m := model as StrataModel
	if StrataProps.over_tank(transform.origin):
		if id == SHELL_ID:
			m.drop_shell()
		elif id in StrataModel.MATERIALS:
			m.pour(id)
	super(id, transform)


## A pour is an event, not a place: nothing to restore on a rebuilt screen.
func placements() -> Dictionary:
	return {}


func reset_run() -> void:
	super()
	if game != null:
		game.run_reset()


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as StrataModel
	var places := {}
	if holding != "":
		places[holding] = knobs[holding].global_position
	props.show(m.layers(), m.newest, m.input("settle"), m.shell_at(), places)


## Words only: what the tank shows, the bottom layer and the top layer.
func observations() -> Dictionary:
	var m := model as StrataModel
	var layers := m.layers()
	var none := Locale.t("strata.layer.none")
	return {
		"state": Locale.t("strata.status." + m.status()),
		"bottom": Locale.t("strata.layer." + layers[0]) if not layers.is_empty() else none,
		"top": Locale.t("strata.layer." + layers[-1]) if not layers.is_empty() else none,
	}


## "자세히": each layer's place from the bottom against the order it was poured (the line y = x: the
## first poured is the bottom one).
func graph_series() -> Dictionary:
	var points := PackedVector2Array()
	for i in (model as StrataModel).layers().size():
		points.append(Vector2(i + 1, i + 1))
	return {"order": points}


func graph_revision() -> int:
	return (model as StrataModel).layers().hash()


## Dugi points at the tank (stages 1 and 2) or at the cliff's ash (stage 3).
func explain_point() -> Vector3:
	if stage == 2:
		return StrataProps.cliff_layer_center(StrataModel.TARGET + 1)
	return StrataProps.tank_box().get_center()


func follow_point() -> Vector3:
	return StrataProps.tank_box().get_center()
