## 바닷바람 (#93, 2026-11-07; Hutton Island's sixth spot, docs/islands/hutton-missions.md 6 and
## hutton-lines.md 6): a coast, the land on the left and the sea on the right. The child presses and
## holds the sun to warm the coast (manipulation rule "hold": nothing moves under the finger); letting
## go, the land cools again. Two thermometers (on the sand, on a buoy) show the land's and the sea's
## warmth as red columns, and the wind blows between them as drifting arrows: from the cooler side to
## the warmer one, stronger the bigger the difference. A pinwheel on the shore turns with it, a fishing
## boat waits at the pier and far out a sailing boat carries the piece. The condition button (왼쪽 아래)
## picks the time: 낮 or 밤 (at night the moon stands where the sun was, nothing warms the coast and the
## land cools past the sea by itself).
##
## Model: SeaBreezeModel (the land's and the sea's temperatures, lags of their own). The lab only draws
## it (EarthLab): the stages are judged on its status ("sea_breeze", "strong", "land_breeze"; the
## misses on "calm" and the weaker breezes), never on a number on the screen.
##
## The hand: one knob ("sun"), a pickable box on the sun (it is never dragged). hold_started turns the
## model's sun on (by day the land and a little the sea warm up), hold_ended turns it off. The model
## keeps changing after the finger leaves (the land cools; at night it cools the whole time), so the
## lab is settled whenever no finger holds the sun: a let-go is judged on the wind at that moment
## (MissionRound judges a settled run), and the night's land breeze comes while the child waits.
## The night starts cooling only once the child can play (Experiment.set_play_open): a night set while
## the clue, the question or Dugi's mission line is up (the screen's entry conditions on a saved
## second stage) waits in the evening, so no stamp comes while he talks.
class_name SeaBreezeLab
extends EarthLab

const KNOB_ID := "sun"
const TIME_CONTROL := "time"
## The knob: a box this big round the sun (m: big for a finger on a phone).
const KNOB_BOX := 2.6
## The graph (자세히): the wind against the difference, a point every GRAPH_STEP °C up to GRAPH_MAX.
const GRAPH_STEP := 0.5
const GRAPH_MAX := 16.0
## The thermometers' words: warmer than WARM_DEG is "warm", over HOT_DEG "hot", under COOL_DEG "cold".
const HOT_DEG := 30.0
const WARM_DEG := 22.0
const COOL_DEG := 16.0

var props := SeaBreezeProps.new()
## The finger presses the sun now.
var pressing := false
## The child can play now (the screen's set_play_open; true without a screen).
var play_open := true
## The night's run waits in the evening for play_open.
var night_waits := false
var _graph_key := Vector2.INF
var _graph_revision := 0
var _line := PackedVector2Array()


func _init() -> void:
	model = SeaBreezeModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(KNOB_ID, "SunKnob", KNOB_BOX)
	game = SeaBreezeGame.new(self)
	add_child(game)
	game.build()


## 낮 / 밤: the model's night and its start temperatures (kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == TIME_CONTROL:
		(model as SeaBreezeModel).set_night(str(value) == "night")


# --- the hand -------------------------------------------------------------------------------------

## The knob stays on the sun.
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), SeaBreezeProps.SUN_AT)


func hold_started(_id: String) -> void:
	pressing = true
	(model as SeaBreezeModel).set_sun(true)
	_show()
	_update_status(true)


func hold_ended(_id: String) -> void:
	pressing = false
	(model as SeaBreezeModel).set_sun(false)
	_show()
	_update_status()


## A new run (다시, a condition): the sun is not pressed any more; a night waits for the child.
func reset_run() -> void:
	pressing = false
	night_waits = (model as SeaBreezeModel).is_night() and not play_open
	super()


func set_play_open(open: bool) -> void:
	play_open = open
	if open:
		night_waits = false


## The model steps (EarthLab) unless the night still waits for the child.
func _physics_process(delta: float) -> void:
	if not night_waits:
		super(delta)


## Judged whenever no finger presses the sun (the coast keeps warming or cooling after it: the wind at
## the let-go is the attempt's result; the night's breeze comes by itself).
func settled() -> bool:
	return not pressing and holding == ""


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as SeaBreezeModel
	props.show(m.input("land"), m.input("sea"), m.wind(), m.wind_share(), m.is_night(), m.heating())


## Words only (no degrees, no wind speed on the screen): the wind, the land's and the sea's warmth.
func observations() -> Dictionary:
	var m := model as SeaBreezeModel
	var words := {
		"hot": Locale.t("sea_breeze.warmth.hot"),
		"warm": Locale.t("sea_breeze.warmth.warm"),
		"cool": Locale.t("sea_breeze.warmth.cool"),
		"cold": Locale.t("sea_breeze.warmth.cold"),
	}
	return {
		"state": {
			"calm": Locale.t("sea_breeze.status.calm"),
			"sea_breeze": Locale.t("sea_breeze.status.sea_breeze"),
			"strong": Locale.t("sea_breeze.status.strong"),
			"land_breeze": Locale.t("sea_breeze.status.land_breeze"),
		}.get(m.status(), ""),
		"land": words[warmth(m.input("land"))],
		"sea": words[warmth(m.input("sea"))],
	}


## A thermometer's word for `temperature` (°C): "hot", "warm", "cool" or "cold".
static func warmth(temperature: float) -> String:
	if temperature >= HOT_DEG:
		return "hot"
	if temperature >= WARM_DEG:
		return "warm"
	return "cool" if temperature >= COOL_DEG else "cold"


## The wind's speed against how much warmer the land is than the sea (the model's line) and where the
## coast is now (자세히: the units are only there).
func graph_series() -> Dictionary:
	var m := model as SeaBreezeModel
	if _line.is_empty():
		var d := 0.0
		while d <= GRAPH_MAX + 1e-9:
			_line.append(Vector2(d, SeaBreezeModel.WIND_PER_DEG * d))
			d += GRAPH_STEP
	return {"wind": _line, "now": PackedVector2Array([Vector2(absf(m.difference()), absf(m.wind()))])}


func graph_revision() -> int:
	var key := Vector2(snappedf(model.input("land"), 0.05), snappedf(model.input("sea"), 0.05))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## Dugi points at the pinwheel (the wind on the shore).
func explain_point() -> Vector3:
	return props.pinwheel.global_position


## The camera follows the shore (between the sun and the boats).
func follow_point() -> Vector3:
	return Vector3(SeaBreezeProps.SHORE_X, 2.5, 0.0)
