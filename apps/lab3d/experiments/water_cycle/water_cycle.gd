## 물의 여행 (#91, 2026-11-07; Hutton Island's fourth spot, docs/islands/hutton-missions.md 4 and
## hutton-lines.md 4): a seaside table with the sea on the left and the frogs' dry pond on the right.
## The child presses and holds the sun over the sea: while it is held the sun warms the sea, vapour
## rises and gathers into a cloud over the pond, the cloud grows heavy and rains, and the rain fills
## the pond. The condition button (왼쪽 아래) picks a weak or a strong sun. The day sign shows the
## day's sunshine left (a bar, no number): once it is used up the sun sets and only 다시 brings a new
## day, so a weak sun's rain can never fill the pond (stage 3).
##
## Model: WaterCycleModel (rule-based: evaporation at the sun's rate, a cloud, rain past its weight,
## the pond). The lab only draws it (EarthLab): the stages are judged on its status ("cloud", "rain",
## "full"; "vapour" before the first cloud), never on a number on the screen.
##
## The hand: one knob ("sun"), a pickable box on the sun, with the hold rule (manipulation.objects[]
## "hold": true): a press on it starts the sunshine (Experiment.hold_started), lifting the finger stops
## it (hold_ended). Nothing moves under the finger. While the finger is down the lab is not settled
## (nothing is judged), also after the day's sunshine has run out under it; in the first stage the
## sun stops at the first cloud (WaterCycleModel.cloud_stop, #114) and that cloud is judged at once. The sunshine adds up over
## several presses until 다시, a new condition or the next stage (the run starts over).
class_name WaterCycleLab
extends EarthLab

const KNOB_ID := "sun"
const SUN_CONTROL := "sun"
## The knob: a box this big round the sun (m: the ball and its rays, a child's finger anywhere on it).
const KNOB_BOX := 2.8
## The graph: a point every this many seconds of sunshine.
const GRAPH_STEP_S := 0.25

var props := WaterCycleProps.new()
## A finger holds the sun now.
var pressing := false
var _graph_key := Vector3.INF
var _graph_revision := 0
var _curves := {}


func _init() -> void:
	model = WaterCycleModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(KNOB_ID, "SunKnob", KNOB_BOX)
	game = WaterCycleGame.new(self)
	add_child(game)
	game.build()


func set_game_stage(stage_now: int, stamps: int, just_cleared: bool) -> void:
	super(stage_now, stamps, just_cleared)
	(model as WaterCycleModel).cloud_stop = stage_now == 0


## The sun's strength: weak or strong (the model's start: kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == SUN_CONTROL:
		model.set_start("sun", WaterCycleModel.STRONG_SUN if str(value) == "strong" else WaterCycleModel.WEAK_SUN)


# --- the hold ---------------------------------------------------------------------------------------

## The knob sits on the sun.
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), props.sun.global_position if props.sun != null and props.sun.is_inside_tree() else WaterCycleProps.SUN_AT)


## A finger presses the sun: it shines on the sea (unless the day is over).
func hold_started(_id: String) -> void:
	pressing = true
	(model as WaterCycleModel).heat_on()
	_show()
	_update_status(true)


## The finger lets go: the sunshine stops where it is (judged once settled).
func hold_ended(_id: String) -> void:
	pressing = false
	(model as WaterCycleModel).heat_off()
	_show()
	_update_status()


## Nothing is judged while a finger holds the sun (also once the day ran out under it), unless the
## sun stopped by itself at the first cloud (the first stage).
func settled() -> bool:
	return (not pressing or (model as WaterCycleModel).cloud_stopped()) and super()


func reset_run() -> void:
	pressing = false
	super()
	if game != null:
		game.run_reset()


func _process(delta: float) -> void:
	super(delta)
	props.animate(delta)


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as WaterCycleModel
	props.show(WaterCycleModel.is_strong(m.input("sun")), m.heating(), m.cloud_share(), m.evaporated() >= WaterCycleModel.CLOUD_AT,
		m.pond_share(), m.day_left(), m.day_over(), m.raining())


## Words only (no amounts, no seconds: the user): where the water is, the pond, the day.
func observations() -> Dictionary:
	var m := model as WaterCycleModel
	return {
		"state": {
			"ready": Locale.t("water_cycle.status.ready"),
			"vapour": Locale.t("water_cycle.status.vapour"),
			"cloud": Locale.t("water_cycle.status.cloud"),
			"rain": Locale.t("water_cycle.status.rain"),
			"full": Locale.t("water_cycle.status.full"),
		}.get(m.status(), ""),
		"pond": Locale.t("water_cycle.pond.full") if m.pond_share() >= 1.0 else Locale.t("water_cycle.pond.some") if m.pond_share() > 0.0 else Locale.t("water_cycle.pond.dry"),
		"day": Locale.t("water_cycle.day.over") if m.day_over() else Locale.t("water_cycle.day.on"),
	}


## The pond's water (% of full) against the sunshine so far (s) for the weak and the strong sun over
## one day, and where it is now ("자세히": the weak sun's line stops short of full at the day's end).
func graph_series() -> Dictionary:
	var m := model as WaterCycleModel
	if _curves.is_empty():
		for pair: Array in [["weak", WaterCycleModel.WEAK_SUN], ["strong", WaterCycleModel.STRONG_SUN]]:
			_curves[pair[0]] = pond_curve(pair[1])
	return {"weak": _curves["weak"], "strong": _curves["strong"], "now": PackedVector2Array([Vector2(m.input("heat"), m.pond_share() * 100.0)])}


func graph_revision() -> int:
	var key := Vector3(model.input("heat"), model.input("sun"), 0.0)
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## The pond's water (% of full) through one day of sunshine at the evaporation rate `sun`.
static func pond_curve(sun: float) -> PackedVector2Array:
	var probe := WaterCycleModel.new()
	probe.set_start("sun", sun)
	var out := PackedVector2Array()
	var s := 0.0
	while s <= WaterCycleModel.DAY_S + 1e-9:
		probe.set_input("heat", s)
		out.append(Vector2(s, probe.pond_share() * 100.0))
		s += GRAPH_STEP_S
	return out


## Dugi points at the cloud's place over the pond.
func explain_point() -> Vector3:
	return WaterCycleProps.CLOUD_AT


## The camera follows the table (between the sea and the pond).
func follow_point() -> Vector3:
	return Vector3(0.0, 2.6, 0.0)
