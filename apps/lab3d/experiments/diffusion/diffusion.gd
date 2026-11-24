## 퍼지는 냄새와 잉크 (#156, 2026-11-15; Curie Island's first spot, docs/islands/curie-missions.md 1 and
## curie-lines.md 1): Curie Island's kitchen (KitchenSet), a glass of water on the big table and a
## dropper over it. The child presses the dropper's red bulb (manipulation rule "hold" with the hand
## guide's tap: a press is the whole action, nothing moves under the finger): a drop of ink falls in and
## spreads through the still water by itself as a soft blue cloud. The condition button (왼쪽 아래)
## picks the water: 찬물 or 뜨거운 물 (it steams; its cloud sways faster and spreads faster).
##
## The table changes with the stage (like the volcano's site): stage 1 one glass, stage 2 the glass and
## a glass of cold water beside it that gets a drop at the same moment (to compare), stage 3 (and a
## finished round) the glass and a fresh loaf whose smell goes along the table to Puppy's nose at its
## end. A stage just cleared keeps its table until the next stage's reset (the screen runs "reset").
##
## Model: DiffusionModel (the spreading front x = sqrt(4 D t), D from Stokes–Einstein in water and from
## Fuller in air). The lab only draws it (EarthLab): the stages are judged on its status ("full",
## "faster", "smell"; the misses on "spreading" and the cold glass's tie "full"), never on a number on
## the screen.
##
## The hand: one knob ("dropper"), a pickable box round the dropper's bulb. hold_started is a new drop
## (the run starts over: the model's drop()) and the bread cat squeezes the bulb with both paws
## (2026-11-15 user: the cat does the lab), hold_ended lets go (the cat's paws too). The model keeps spreading after the
## finger leaves; the run counts as settled once the judged thing is there or it has spread for
## DiffusionModel.HINT_S (then Puppy's "wait" line can come while it goes on: MissionRound judges a
## settled run, misses included).
class_name DiffusionLab
extends EarthLab

const KNOB_ID := "dropper"
const WATER_CONTROL := "water"
## The knob: a box this big round the dropper's bulb (m: big for a finger on a phone).
const KNOB_BOX := 1.1
## The graph (자세히): each front's share of its way against the play time, a point every GRAPH_STEP s.
const GRAPH_STEP := 0.25
const GRAPH_MAX := 14.0
## The stage played on each table (0-based): the PAIR table from stage 2, the BREAD table from stage 3.
const PAIR_STAGE := 1
const BREAD_STAGE := 2

var props := DiffusionProps.new()
## The finger presses the dropper now.
var pressing := false
var _site_due := -1.0         # a table to take at the next reset (a stage just cleared), -1 none
var _graph_key := Vector2.INF
var _graph_revision := 0
var _lines := {}


func _init() -> void:
	model = DiffusionModel.new()


func _build_world() -> void:
	var cast: Variant = definition.raw.get("cast", {})
	var puppy: Variant = cast.get("puppy", {}).get("at") if cast is Dictionary and cast.get("puppy") is Dictionary else null
	props.build(self, puppy)
	add_knob(KNOB_ID, "DropperKnob", KNOB_BOX)
	game = DiffusionGame.new(self)
	add_child(game)
	game.build()


## 찬물 / 뜨거운 물: the model's water (kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == WATER_CONTROL:
		(model as DiffusionModel).set_hot(str(value) == "hot")


# --- the table (the stage) ------------------------------------------------------------------------

## The stage changed: its table. A stage just cleared keeps its result until the next reset; opened or
## jumped to, the table is set at once.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	var site := site_of(stage)
	if just_cleared and model.input("site") != site:
		_site_due = site
	else:
		_set_site(site)


## The table of stage `stage` (-1: the round is done, the BREAD table).
static func site_of(stage: int) -> float:
	if stage < 0 or stage >= BREAD_STAGE:
		return DiffusionModel.BREAD
	return DiffusionModel.PAIR if stage >= PAIR_STAGE else DiffusionModel.SINGLE


## Table `site` from now on; a new table starts the run over (no drop on it yet).
func _set_site(site: float) -> void:
	_site_due = -1.0
	if site == model.input("site"):
		return
	(model as DiffusionModel).set_site(site)
	model.reset()
	if is_inside_tree():
		_show()
	_update_status(true)


func reset_run() -> void:
	if _site_due >= 0.0:
		_set_site(_site_due)
	pressing = false
	props.press(false)
	super()


# --- the hand -------------------------------------------------------------------------------------

## The knob stays on the dropper's bulb over the glass.
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), DiffusionProps.bulb_point(DiffusionProps.cup_point(model.input("site"))))


## A press: a new drop (a table still showing the last stage's result changes first).
func hold_started(id: String) -> void:
	if id != KNOB_ID:
		return
	if _site_due >= 0.0:
		_set_site(_site_due)
	pressing = true
	(model as DiffusionModel).drop()
	if game != null:
		game.run_reset()
	_show()
	props.press(true)
	_update_status(true)


func hold_ended(id: String) -> void:
	if id != KNOB_ID:
		return
	pressing = false
	props.press(false)
	_show()
	_update_status()


## Judged whenever no finger presses the dropper and the drop has had its say: the judged thing is
## there, or it has spread long enough for Puppy's hint (DiffusionModel.decided).
func settled() -> bool:
	return not pressing and holding == "" and (model as DiffusionModel).decided()


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as DiffusionModel
	props.show(m.site(), m.is_hot(), m.ink(), m.beside(), m.smell(), m.dropped())


## Words only (no number on the screen): how the glass looks, the smell, the water.
func observations() -> Dictionary:
	var m := model as DiffusionModel
	var cup := Locale.t("diffusion.cup.clear")
	if m.dropped():
		cup = Locale.t("diffusion.cup.full") if m.ink() >= 1.0 else Locale.t("diffusion.cup.spreading")
	var smell := Locale.t("diffusion.smell.none")
	if m.site() == DiffusionModel.BREAD and m.dropped():
		smell = Locale.t("diffusion.smell.nose") if m.smell() >= 1.0 else Locale.t("diffusion.smell.coming")
	return {
		"cup": cup,
		"smell": smell,
		"water": Locale.t("diffusion.water.hot") if m.is_hot() else Locale.t("diffusion.water.cold"),
	}


## Each front's share of its way against the play time (the model's curves: the cold and the hot
## glass, the smell to the nose) and where the run is now (자세히: the units are only there).
func graph_series() -> Dictionary:
	var m := model as DiffusionModel
	if _lines.is_empty():
		var fulls := {"cold": DiffusionModel.full_time(DiffusionModel.COLD_C), "hot": DiffusionModel.full_time(DiffusionModel.HOT_C),
			"smell": DiffusionModel.smell_time()}
		for id: String in fulls:
			var line := PackedVector2Array()
			var t := 0.0
			while t <= GRAPH_MAX + 1e-9:
				line.append(Vector2(t, 100.0 * DiffusionModel.reach(t, fulls[id])))
				t += GRAPH_STEP
			_lines[id] = line
	var now := PackedVector2Array()
	if m.dropped():
		now.append(Vector2(m.input("time"), 100.0 * (m.smell() if m.site() == DiffusionModel.BREAD else m.ink())))
	return {"cold": _lines.cold, "hot": _lines.hot, "smell": _lines.smell, "now": now}


func graph_revision() -> int:
	var key := Vector2(snappedf(model.input("time"), 0.05), model.input("site") + 10.0 * model.input("water") + 100.0 * model.input("dropped"))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## Dugi points at the glass (the ink spreading in it).
func explain_point() -> Vector3:
	return props.cup.global_position + Vector3.UP * DiffusionProps.CUP_FILL * 0.6


## The camera follows the table's middle.
func follow_point() -> Vector3:
	return Vector3(0.0, KitchenSet.TABLE_TOP + 0.8, KitchenSet.TABLE_AT.z)
