## 되돌릴 수 있을까? (#158, 2026-11-17; Curie Island's third spot, docs/islands/curie-missions.md 3 and
## curie-lines.md 3): Curie Island's kitchen (KitchenSet), a stove with a pot on the big table. The child
## presses the stove's big red handle (manipulation rule "hold": a press is the whole action, nothing
## moves under the finger): while it is pressed the fire burns and the pot warms; let go and it cools. The
## condition button (왼쪽 아래) picks what is in the pot: 초콜릿 or 달걀.
##
## The table changes with the stage (like the diffusion lab's): stage 1 the chocolate block in the pot,
## stage 2 the melted chocolate poured by the bread cat into a star mold on the right burner (the pour
## plays when the stage's reset comes), stage 3 the shiny egg of the basket (with the egg item it is in
## the pot). A stage just cleared keeps its table until the next stage's reset (the screen runs "reset").
##
## Model: MeltCookModel (the chocolate's melting and setting follow the temperature both ways, the egg's
## cooking never goes back). The lab only draws it (EarthLab): the stages are judged on its status
## ("melted", "set", "cooled"; the misses on "solid", "heating", "raw"), never on a number on the screen.
##
## The hand: one knob ("flame"), a pickable box round the handle. hold_started puts the fire on, hold_ended
## puts it out. The model keeps warming up and cooling down after the finger leaves; the run counts as
## settled once the judged thing is there or the run has come to its miss (MeltCookModel.decided()).
class_name MeltCookLab
extends EarthLab

const KNOB_ID := "flame"
const ITEM_CONTROL := "item"
## The knob: a box this big round the handle (m: big for a finger on a phone).
const KNOB_BOX := 1.1
## The graph (자세히): the core's temperature against the play time, a point every GRAPH_STEP s.
const GRAPH_STEP := 0.25
const GRAPH_MAX := 24.0
## The stages' tables (0-based): the poured star from stage 2, the shiny egg from stage 3.
const POUR_STAGE := 1
const SHINY_STAGE := 2

var props := MeltCookProps.new()
## The finger presses the handle now.
var pressing := false
var _site_due := -1.0         # a table to take at the next reset (a stage just cleared), -1 none
var _trace := PackedVector2Array()
var _graph_key := Vector3.INF
var _graph_revision := 0


func _init() -> void:
	model = MeltCookModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(KNOB_ID, "FlameKnob", KNOB_BOX)
	game = MeltCookGame.new(self)
	add_child(game)
	game.build()


## 초콜릿 / 달걀: what is in the pot (kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == ITEM_CONTROL:
		(model as MeltCookModel).set_egg(str(value) == "egg")


# --- the table (the stage) ------------------------------------------------------------------------

## The stage changed: its table. A stage just cleared keeps its result until the next reset; opened or
## jumped to, the table is set at once.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	var site := site_of(stage)
	if just_cleared and model.input("site") != site:
		_site_due = site
	else:
		_set_site(site, false)


## The table of stage `stage` (-1: the round is done, the last table).
static func site_of(stage: int) -> float:
	if stage < 0 or stage >= SHINY_STAGE:
		return MeltCookModel.SHINY
	return MeltCookModel.POURED if stage >= POUR_STAGE else MeltCookModel.BLOCK


## Table `site` from now on; a new table starts the run over. `animate`: the bread cat pours the chocolate
## into the star on the way (the table of a stage's reset).
func _set_site(site: float, animate: bool) -> void:
	_site_due = -1.0
	if site == model.input("site"):
		return
	var m := model as MeltCookModel
	var was_poured := m.poured()
	m.set_site(site)
	m.reset()
	if animate and m.poured() and not was_poured:
		props.begin_pour()
	else:
		props.settle(m.poured())
	if is_inside_tree():
		_show()
	_update_status(true)


func reset_run() -> void:
	if _site_due >= 0.0:
		_set_site(_site_due, true)
	pressing = false
	props.press(false)
	super()


# --- the hand -------------------------------------------------------------------------------------

## The knob stays on the stove's handle.
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), MeltCookProps.HANDLE_AT)


## A press: the fire is on (a table still showing the last stage's result changes first).
func hold_started(id: String) -> void:
	if id != KNOB_ID:
		return
	if _site_due >= 0.0:
		_set_site(_site_due, true)
	pressing = true
	(model as MeltCookModel).press(true)
	props.press(true)
	_show()
	_update_status(true)


func hold_ended(id: String) -> void:
	if id != KNOB_ID:
		return
	pressing = false
	(model as MeltCookModel).press(false)
	props.press(false)
	_show()
	_update_status()


## Judged once the judged thing is there or the run has come to its miss (MeltCookModel.decided), and
## no finger drags the knob.
func settled() -> bool:
	return holding == "" and (model as MeltCookModel).decided()


func _physics_process(delta: float) -> void:
	super(delta)
	_record()


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)
	if props.pouring() or props.peeling():
		_redraw()


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	props.show(model as MeltCookModel)


## Words only (no number on the screen): how the chocolate looks, how the egg is.
func observations() -> Dictionary:
	var m := model as MeltCookModel
	var choc := Locale.t("melt_cook.choc.other")
	var egg := Locale.t("melt_cook.egg.other")
	if m.is_egg():
		if not m.touched():
			egg = Locale.t("melt_cook.egg.fresh")
		elif m.cooked():
			egg = Locale.t("melt_cook.egg.cooled") if m.status() == "cooled" else Locale.t("melt_cook.egg.cooked")
		elif m.pressing():
			egg = Locale.t("melt_cook.egg.cooking")
		elif m.input("doneness") > 0.0:
			egg = Locale.t("melt_cook.egg.half")
		else:
			egg = Locale.t("melt_cook.egg.raw")
	else:
		if m.molten():
			choc = Locale.t("melt_cook.choc.warm") if m.poured() else Locale.t("melt_cook.choc.melted")
		elif m.poured():
			choc = Locale.t("melt_cook.choc.set")
		elif m.softness() > 0.15:
			choc = Locale.t("melt_cook.choc.soft")
		else:
			choc = Locale.t("melt_cook.choc.hard")
	var fire := Locale.t("melt_cook.fire.on") if m.pressing() else Locale.t("melt_cook.fire.off")
	return {"choc": choc, "egg": egg, "fire": fire}


## Dugi points at the pot (what is in it).
func explain_point() -> Vector3:
	return Vector3(MeltCookProps.POT_AT.x, MeltCookProps.STOVE_TOP + 0.5, MeltCookProps.POT_AT.z)


## The camera follows the stove's middle.
func follow_point() -> Vector3:
	return Vector3(0.3, KitchenSet.TABLE_TOP + 1.2, KitchenSet.TABLE_AT.z)


## The core's temperature against the play time (the model's run; 자세히: the units are only there), the
## two temperatures that matter as flat lines, and where the run is now.
func graph_series() -> Dictionary:
	var lines := {"melt": PackedVector2Array([Vector2(0.0, MeltCookModel.MELT_C), Vector2(GRAPH_MAX, MeltCookModel.MELT_C)]),
		"cook": PackedVector2Array([Vector2(0.0, MeltCookModel.COOK_C), Vector2(GRAPH_MAX, MeltCookModel.COOK_C)])}
	var m := model as MeltCookModel
	return {"melt": lines.melt, "cook": lines.cook, "trace": _trace, "now": PackedVector2Array([Vector2(minf(m.input("time"), GRAPH_MAX), m.core_c())])}


func graph_revision() -> int:
	var m := model as MeltCookModel
	var key := Vector3(snappedf(m.input("time"), GRAPH_STEP), m.input("item") + 10.0 * m.input("site"), snappedf(m.core_c(), 0.5))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## The run's trace: a point every GRAPH_STEP s of play time; a new run (the time back at 0) starts it over.
func _record() -> void:
	var m := model as MeltCookModel
	var t := m.input("time")
	if not _trace.is_empty() and t < _trace[_trace.size() - 1].x:
		_trace.clear()
	if _trace.is_empty() or t - _trace[_trace.size() - 1].x >= GRAPH_STEP:
		if t <= GRAPH_MAX:
			_trace.append(Vector2(t, m.core_c()))
