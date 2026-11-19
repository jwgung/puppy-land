## 빵 반죽 부풀리기 (#159, 2026-11-17; Curie Island's fourth spot, docs/islands/curie-missions.md 4 and
## curie-lines.md 4): Curie Island's kitchen (KitchenSet), a bowl of bread dough in the table's middle,
## the brick oven behind the table's left end with the high shelf over the warm place in front of it, the
## fridge behind its right end. The child drags the bowl (its one object) along the table and lets it go
## by the oven or at the fridge; the time then runs by itself (FastClock, the plan's decision 1, 안 A:
## the time sign's marker goes from the sun to the moon, the scene goes dark at night, a moon stamp a
## night) and stops once the result is in. Picking the bowl up again stops the time; put down again it
## goes on (the mockup's "그릇을 다시 끌면 시간이 멈추고 놓으면 이어 흐름"). The condition buttons
## (왼쪽 아래): 효모 넣음 / 안 넣음; they are locked while the time flows (conditions_locked: the screen
## dims them).
##
## The goal changes with the stage: stages 1-2 twice the volume (the bowl's dashed line), stage 3 (and
## a finished round) up to the shelf. A stage just cleared keeps its goal until the next reset.
##
## Model: DoughModel (rules with textbook values: an hour to double by the oven at about 27 °C, about
## twelve in the fridge at 4 °C, none without yeast). The lab only draws it (EarthLab): the stages are
## judged on its status ("doubled", "same", "shelf"; the misses "little", "same" / "doubled" with the
## wrong button, "waiting"), never on a number on the screen.
##
## The hand: one knob ("bowl"), a box on the bowl where it stands (by the oven, in the fridge, on the
## table: picked up where it is drawn, #157's lesson), dragged along a line over the table from the warm
## place to the cold one. Let go near one of them it stands there and the time runs; anywhere else it
## goes back to where it was picked up (and the time goes on if it was running there). Nothing is kept
## by placements(): putting the bowl down is an event.
##
## A finished round shows the result, not the flat start (#157's lesson: the status card must not read
## "처음" after the last stamp): the dough risen to the shelf by the oven, until 다시 or a condition.
class_name DoughLab
extends EarthLab

const BOWL_ID := "bowl"
const SHELF_SURFACE := "table"
const YEAST_CONTROL := "yeast"
## The knob: the bowl's box (m) and how high its middle is over the bowl's foot.
const BOWL_KNOB := 1.0
const KNOB_UP := 0.3
## How far past the two places the bowl may be dragged (m).
const REACH := 0.4
## The graph (자세히): the dough's volume (% of the start) against the hours since it was put down.
const GRAPH_STEP := 0.05
const GRAPH_HOURS := 4.0
## The stage played on each goal (0-based): the shelf from stage 3.
const SHELF_STAGE := 2

var props := DoughProps.new()
var _goal_due := -1.0           # a goal to take at the next reset (a stage just cleared), -1 none
var _from_spot := DoughModel.TABLE   # where the bowl was picked up
var _from_done := false         # the run had its result when the bowl was picked up
var _keep_result := false       # the next reset keeps the finished round's result (more play after the card)
var _surface: ManipSurface
var _graph_key := Vector3.INF
var _graph_revision := 0
var _lines := {}


func _init() -> void:
	model = DoughModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(BOWL_ID, "BowlKnob", BOWL_KNOB)
	var origin := KitchenSet.table_point(0.0, DoughProps.BOWL_Z) + Vector3.UP * (KNOB_UP - BOWL_KNOB * 0.5)
	_surface = ManipSurface.new(Transform3D(Basis(), origin), Vector2(DoughProps.WARM_X - REACH, 0.0), Vector2(DoughProps.COLD_X + REACH, 0.0))
	game = DoughGame.new(self)
	add_child(game)
	game.build()


func _exit_tree() -> void:
	props.night.clear()   # the tint is global: never leave the night on


## 효모 넣음 / 안 넣음: the model's yeast (kept across 다시); the run starts over (EarthLab._restart).
func _apply_control(id: String, value: Variant) -> void:
	if id == YEAST_CONTROL:
		_keep_result = false
		(model as DoughModel).set_yeast(str(value) == "yes")


## The condition buttons are locked while the time flows (and while the bowl is held in the middle of
## it), free again once the result is in or after 다시 (FastClock.locks_conditions).
func conditions_locked() -> bool:
	return (model as DoughModel).clock.locks_conditions()


# --- the goal (the stage) -------------------------------------------------------------------------

## The stage changed: its goal. A stage just cleared keeps its result until the next reset; opened or
## jumped to, the goal is set at once. A finished round shows the dough at the shelf.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	var goal := goal_of(stage)
	if stage < 0:
		_goal_due = -1.0
		_keep_result = true
		if not just_cleared:
			_finish()
		return
	_keep_result = false
	if just_cleared and model.input("goal") != goal:
		_goal_due = goal
	else:
		_set_goal(goal)


## The goal of stage `stage` (-1: the round is done, the shelf).
static func goal_of(stage: int) -> float:
	return DoughModel.shelf_goal() if stage < 0 or stage >= SHELF_STAGE else DoughModel.DOUBLE


## Goal `goal` from now on; a new goal starts the run over.
func _set_goal(goal: float) -> void:
	_goal_due = -1.0
	if goal == model.input("goal"):
		return
	(model as DoughModel).set_goal(goal)
	model.reset()
	if is_inside_tree():
		_show()
	_update_status(true)


## The finished round's look: the dough at the shelf by the oven.
func _finish() -> void:
	(model as DoughModel).set_goal(DoughModel.shelf_goal())
	(model as DoughModel).finish_pose()
	if is_inside_tree():
		_show()
	_update_status(true)


func reset_run() -> void:
	if _keep_result:
		# More play after the round's card: the result stays until 다시 or a condition (the next reset).
		_keep_result = false
		reset_count += 1
		_finish()
		if game != null:
			game.run_reset()
		return
	if _goal_due >= 0.0:
		_set_goal(_goal_due)
	super()
	if game != null:
		game.run_reset()


# --- the hand -------------------------------------------------------------------------------------

func manipulation_surface(_surface_id: String) -> ManipSurface:
	return _surface


## The knob sits on the bowl where it is drawn (by the oven, in the fridge, on the table).
func _knob_pose(_id: String) -> Transform3D:
	var spot := (model as DoughModel).spot()
	var s := DoughProps.bowl_scale(spot)
	return Transform3D(Basis(), DoughProps.bowl_point(spot) + Vector3.UP * KNOB_UP * s)


## Picked up: the time stops where it is.
func manipulation_started(id: String) -> void:
	var m := model as DoughModel
	_from_spot = m.spot()
	_from_done = m.finished()
	m.lift()
	super(id)


## The bowl only moves while held (its place is read in _redraw).
func _knob_inputs(_id: String, _xf: Transform3D) -> Dictionary:
	return {}


## Let go by the oven or at the fridge: it stands there and the time runs; anywhere else it goes back
## to where it was picked up (the time goes on there, unless the result was in already).
func manipulation_placed(id: String, transform: Transform3D) -> void:
	var to := DoughProps.spot_at(transform.origin.x)
	if to >= 0.0:
		(model as DoughModel).place(to)
	else:
		_put_back()
	super(id, transform)


## The shell put the knob back where it was picked up: the bowl stands there again.
func manipulation_cancelled(id: String) -> void:
	_put_back()
	super(id)


## The bowl back where it was picked up: the time goes on there if it was running.
func _put_back() -> void:
	var m := model as DoughModel
	m.set_input("spot", _from_spot)
	if not _from_done and _from_spot != DoughModel.TABLE:
		m.clock.start()   # (on to the same stop: `until` is kept while held)


## Putting the bowl down is an event, not a place.
func placements() -> Dictionary:
	return {}


## Judged when no finger holds the bowl and the run has had its say (DoughModel.decided).
func settled() -> bool:
	return holding == "" and (not model.animating() or (model as DoughModel).decided())


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as DoughModel
	var carried := NAN
	if holding == BOWL_ID:
		carried = knobs[BOWL_ID].global_position.x
	props.show(m.spot(), carried, m.volume(), m.has_yeast(), m.goal() < DoughModel.shelf_goal() - DoughModel.EPS, m.clock)


## Words only (no number on the screen): the dough, where the bowl is, the yeast.
func observations() -> Dictionary:
	var m := model as DoughModel
	var spot := Locale.t("dough.spot.table")
	if m.spot() == DoughModel.WARM:
		spot = Locale.t("dough.spot.warm")
	elif m.spot() == DoughModel.COLD:
		spot = Locale.t("dough.spot.cold")
	return {
		"dough": _dough_word(m.status()),
		"spot": spot,
		"yeast": Locale.t("dough.yeast.yes") if m.has_yeast() else Locale.t("dough.yeast.no"),
	}


## The dough card's word for status `status`.
static func _dough_word(status: String) -> String:
	match status:
		"rising":
			return Locale.t("dough.dough.rising")
		"waiting":
			return Locale.t("dough.dough.waiting")
		"doubled":
			return Locale.t("dough.dough.doubled")
		"shelf":
			return Locale.t("dough.dough.shelf")
		"little":
			return Locale.t("dough.dough.little")
		"same":
			return Locale.t("dough.dough.same")
	return Locale.t("dough.dough.ready")


## The dough's volume (% of the start) against the hours since it was put down (자세히: the units are only
## there): by the oven and in the fridge with yeast, and without yeast; where the run is now.
func graph_series() -> Dictionary:
	var m := model as DoughModel
	if _lines.is_empty():
		for id: String in ["warm", "cold", "none"]:
			var line := PackedVector2Array()
			var h := 0.0
			while h <= GRAPH_HOURS + 1e-9:
				var rate := 0.0 if id == "none" else 1.0 / DoughModel.double_hours(DoughModel.WARM if id == "warm" else DoughModel.COLD)
				line.append(Vector2(h, 100.0 * minf(pow(2.0, h * rate), DoughModel.SHELF_RISE)))
				h += GRAPH_STEP
			_lines[id] = line
	var now := PackedVector2Array()
	if m.clock.started:
		now.append(Vector2(minf(m.clock.days * 24.0, GRAPH_HOURS), 100.0 * m.volume()))
	return {"warm": _lines.warm, "cold": _lines.cold, "none": _lines.none, "now": now}


func graph_revision() -> int:
	var m := model as DoughModel
	var key := Vector3(snappedf(m.clock.days, 0.002), m.input("spot") + 10.0 * m.input("yeast"), snappedf(m.doublings, 0.01))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## Puppy's result bubble keeps clear of the bowl and its dough (in the fridge it stands right under
## the bubble's usual place).
func keep_in_sight() -> Array[AABB]:
	var s := props.bowl.scale.x
	var top := DoughProps.dough_top((model as DoughModel).volume()) * s
	var r := DoughProps.CAP_R.y * s
	return [AABB(props.bowl.global_position - Vector3(r, 0.0, r), Vector3(r * 2.0, top, r * 2.0))]


## Dugi points at the dough.
func explain_point() -> Vector3:
	return props.bowl.global_position + Vector3.UP * DoughProps.dough_top((model as DoughModel).volume()) * props.bowl.scale.y


## The camera follows the table's middle.
func follow_point() -> Vector3:
	return Vector3(0.0, KitchenSet.TABLE_TOP + 0.8, KitchenSet.TABLE_AT.z)
