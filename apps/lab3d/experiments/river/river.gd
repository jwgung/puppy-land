## 강물이 깎고 쌓기 (#95, 2026-11-07; Hutton Island's eighth spot, docs/islands/hutton-missions.md 8 and
## hutton-lines.md 8): one river from a mountain (back left) round a bend to the sea (front right).
## The child presses and holds the cloud over the mountain's top (the watering can): rain falls while
## the finger stays, the water runs down the mountain's channel and the river, and the land changes
## with the rain that fell (RiverModel: the valley cut down the mountain, the sand bar at the mouth or
## the mud washed out to sea, the bend's outer bank cut and its inner bar). Letting go stops the rain;
## the next press goes on with the same land (the rain adds up until 다시 or a new condition).
## The condition button (왼쪽 아래) picks the land's slope: 완만 (RiverModel.GENTLE_DEG) or 가파름
## (STEEP_DEG); the mountain is drawn at that slope and the run starts over.
##
## Model: RiverModel (rules, no formula). The lab only draws it (EarthLab): the stages are judged on
## its status ("valley", "bar", "bank"; "little" short of them), never on a number on the screen.
##
## The hand: one hold object ("cloud", manipulation.objects[] `"hold": true`): a pickable box round
## the cloud. The Manipulator calls hold_started / hold_ended; while held the lab adds the rain at the
## fixed step (RiverModel.rain_for) and the run is not settled (no judging while it rains).
class_name RiverLab
extends EarthLab

const KNOB_ID := "cloud"
const SLOPE_CONTROL := "slope"
## The knob: a box this big round the cloud (m: the whole cloud is the target).
const KNOB_BOX := 2.4

## The graph's curves: a point every this many seconds of rain.
const GRAPH_STEP_S := 0.25

var props := RiverProps.new()
var raining := false
var _curves := {}
var _curve_slope := NAN
var _graph_key := Vector2.INF
var _graph_revision := 0


func _init() -> void:
	model = RiverModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(KNOB_ID, "CloudKnob", KNOB_BOX)
	game = RiverGame.new(self)
	add_child(game)
	game.build()


## The slope condition: 완만 or 가파름 (the model's start: kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == SLOPE_CONTROL:
		model.set_start("slope", RiverModel.STEEP_DEG if str(value) == "steep" else RiverModel.GENTLE_DEG)


# --- the hold -------------------------------------------------------------------------------------

## The knob stays on the cloud.
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), RiverProps.CLOUD_AT)


## The finger holds the cloud: it rains.
func hold_started(id: String) -> void:
	if id != KNOB_ID:
		return
	holding = id
	raining = true
	props.set_raining(true)
	_update_status(true)


## The finger let go (or the hold was cancelled): the rain stops, the land stays as it is.
func hold_ended(id: String) -> void:
	if id != KNOB_ID:
		return
	holding = ""
	raining = false
	props.set_raining(false)
	_show()
	_update_status()


## Rain while the cloud is held, one fixed step at a time (the frame rate never changes it).
func _physics_process(delta: float) -> void:
	if raining:
		(model as RiverModel).rain_for(1.0 / Engine.physics_ticks_per_second)
		step_count += 1
		_show()
		_update_status(true)
	super(delta)


## The rain falls and the water runs (visual).
func _process(delta: float) -> void:
	props.animate(delta)


## The run starts over: no rain on the land, none falling.
func reset_run() -> void:
	raining = false
	holding = ""
	if props.rain != null:
		props.set_raining(false)
	super()


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as RiverModel
	props.show(m.input("slope"), m.valley_depth(), m.bank_cut(), m.inner_bar(), m.mouth_bar(), m.washed(), m.speed())


## Words only (no numbers: the user): what the rain did (the key card), how much the water cut and how
## much sand it left.
func observations() -> Dictionary:
	var m := model as RiverModel
	var cut := maxf(m.valley_depth() / RiverModel.DEEP, m.bank_cut() / RiverModel.BANK_FULL)
	var sand := maxf(m.mouth_bar() / RiverModel.BAR_FULL, m.inner_bar() / RiverModel.BAR_FULL)
	return {
		"state": Locale.t("river.status." + m.status()),
		"cut": Locale.t("river.amount." + amount_word(cut)),
		"sand": Locale.t("river.amount." + amount_word(sand)),
	}


## "none" / "some" / "much" for a share of its goal (much at the goal).
static func amount_word(share: float) -> String:
	if share < 0.05:
		return "none"
	return "much" if share >= 1.0 else "some"


## "자세히": the valley's depth, the outer bank's cut and the mouth's sand bar against the rain that
## fell (s) on this land (shares of their goals' scale, no unit), and where the land is now.
func graph_series() -> Dictionary:
	var m := model as RiverModel
	if m.input("slope") != _curve_slope:
		_curve_slope = m.input("slope")
		_curves = rain_curves(_curve_slope)
	var now := PackedVector2Array([Vector2(m.input("rain"), m.valley_depth()), Vector2(m.input("rain"), m.bank_cut()), Vector2(m.input("rain"), m.mouth_bar())])
	return {"valley": _curves.valley, "bank": _curves.bank, "bar": _curves.bar, "now": now}


func graph_revision() -> int:
	var key := Vector2(model.input("slope"), model.input("rain"))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## The valley, bank and bar curves over the rain (0..RAIN_MAX, GRAPH_STEP_S apart) on land of `slope` deg.
static func rain_curves(slope: float) -> Dictionary:
	var m := RiverModel.new()
	m.set_start("slope", slope)
	var out := {"valley": PackedVector2Array(), "bank": PackedVector2Array(), "bar": PackedVector2Array()}
	var rain := 0.0
	while rain <= RiverModel.RAIN_MAX + 1e-9:
		m.set_input("rain", rain)
		out.valley.append(Vector2(rain, m.valley_depth()))
		out.bank.append(Vector2(rain, m.bank_cut()))
		out.bar.append(Vector2(rain, m.mouth_bar()))
		rain += GRAPH_STEP_S
	return out


## Dugi points at the bend's bank (where the piece is).
func explain_point() -> Vector3:
	return RiverProps.bank_face(0.0) + Vector3.UP * RiverProps.BANK_HEIGHT


## The camera follows the plain's middle.
func follow_point() -> Vector3:
	return Vector3(0.0, 0.8, -0.6)
