## The 빵 반죽 부풀리기 spot's model (#159, 2026-11-17; Curie Island's fourth spot,
## docs/islands/curie-missions.md 4 and curie-lines.md 4): a bowl of bread dough left by the warm oven or
## in the cold fridge, with yeast in it or without.
##
## The rule the spot teaches: the yeast in the dough is alive; it eats the dough's sugar and breathes out
## a gas, and the gas's bubbles make the dough rise. Without yeast nothing makes the gas, so the dough
## stays flat however long it waits; with yeast it rises well where it is warm and hardly at all where it
## is cold (the yeast "dozes": curie-lines.md 4's reason).
## - The dough's volume doubles every WARM_DOUBLE_H hours by the oven (about 27 °C: bread recipes'
##   "until doubled, about an hour") and every COLD_DOUBLE_H hours in the fridge (about 4 °C: the
##   overnight "cold rise"); a rule of doublings (exponential growth while the yeast works), not a gas
##   law. Without yeast it does not change.
## - The goal (the stage's): DOUBLE (twice the volume: the bowl's dashed line) or SHELF (SHELF_RISE times:
##   the dough's top under the high shelf). The time runs (FastClock, the plan's decision 1, 안 A) from
##   the moment the bowl is put down by the oven or in the fridge until the goal could be reached by the
##   oven: a yeast dough by the oven reaches it, one in the fridge has risen only a little in the same
##   hours (a fair comparison: the same time, another warmth). A dough without yeast is watched a whole
##   day (NO_YEAST_DAYS: a night goes by, one moon stamp) and stays flat.
## - The pace (play seconds a day) follows the yeast: with yeast DAY_S_YEAST (an hour two seconds: the
##   marker hardly moves, as the real hour or two), without DAY_S_FLAT (a whole day and night in a few
##   seconds).
##
## Inputs: "yeast" (1 in / 0 not: the condition, kept across reset), "goal" (the stage's doublings,
## kept across reset), "spot" (TABLE: on the table, not put down yet; WARM: by the oven; COLD: in the
## fridge). The time is the model's FastClock (`clock`: days since the first morning); `doublings` (the
## dough's volume is 2^doublings of the start) grows while it runs.
##
## Its status names what the stages judge: "ready" (not put down yet), "rising" (the time runs, with
## yeast), "waiting" (the time runs, no yeast), and once the time stopped by itself: "doubled" (the
## DOUBLE goal reached), "shelf" (the SHELF goal reached), "little" (yeast, the time over, short of the
## goal: the fridge), "same" (no yeast, a day gone, flat). No number is shown: the lab draws the dough.
class_name DoughModel
extends EarthModel

const TABLE := 0.0
const WARM := 1.0
const COLD := 2.0
## The warmth of the two spots (°C; the guardian's note only).
const WARM_C := 27.0
const COLD_C := 4.0
## Hours for the dough's volume to double by the oven and in the fridge (with yeast).
const WARM_DOUBLE_H := 1.0
const COLD_DOUBLE_H := 12.0
## The goals as doublings: twice the volume, and up to the shelf (SHELF_RISE times the volume).
const DOUBLE := 1.0
const SHELF_RISE := 3.0
## A dough without yeast is watched this long (days: one night goes by).
const NO_YEAST_DAYS := 1.0
## Play seconds of a day with yeast (an hour = DAY_S_YEAST / 24 s) and without.
const DAY_S_YEAST := 48.0
const DAY_S_FLAT := 8.0
## A dough without yeast counts as settled (Puppy's "wait" line can come) once this many days went by.
const HINT_DAYS := 0.3
const EPS := 1e-6

var clock := FastClock.new()
## The dough's volume is 2^doublings times the start.
var doublings := 0.0


func _init() -> void:
	define_input("yeast", 1.0)
	define_input("goal", DOUBLE)
	define_input("spot", TABLE)
	clock.day_s = DAY_S_YEAST


## The SHELF goal in doublings (log2 of SHELF_RISE).
static func shelf_goal() -> float:
	return log(SHELF_RISE) / log(2.0)


## The condition: yeast in the dough or not (kept across reset()).
func set_yeast(on: bool) -> void:
	set_start("yeast", 1.0 if on else 0.0)
	clock.day_s = DAY_S_YEAST if on else DAY_S_FLAT


func has_yeast() -> bool:
	return input("yeast") > 0.5


## The stage's goal (DOUBLE or shelf_goal()), kept across reset().
func set_goal(goal: float) -> void:
	set_start("goal", goal)


func goal() -> float:
	return input("goal")


func spot() -> float:
	return input("spot")


## Hours for the volume to double at spot `at` (INF: no rising, on the table).
static func double_hours(at: float) -> float:
	if at == WARM:
		return WARM_DOUBLE_H
	if at == COLD:
		return COLD_DOUBLE_H
	return INF


## The doublings an hour now (0 without yeast or on the table).
func rate() -> float:
	return 1.0 / double_hours(spot()) if has_yeast() else 0.0


## The dough's volume now as times the start (1 at the start).
func volume() -> float:
	return pow(2.0, doublings)


## Hours by the oven from `from` doublings to `to` (the time a fair comparison watches).
static func warm_hours(from: float, to: float) -> float:
	return maxf(to - from, 0.0) * WARM_DOUBLE_H


# --- the bowl ---------------------------------------------------------------------------------------

## The bowl is put down at `at` (WARM or COLD): the time runs from now until the goal could be reached
## by the oven (with yeast) or a day has gone by (without). TABLE: it stands on the table, no time.
func place(at: float) -> void:
	set_input("spot", at)
	if at == TABLE:
		clock.stop()
		return
	if has_yeast():
		clock.until = clock.days + warm_hours(doublings, goal()) / 24.0
	else:
		clock.until = maxf(NO_YEAST_DAYS, clock.days)
	clock.start()


## The bowl is picked up: the time stops where it is (it goes on when the bowl is put down again).
func lift() -> void:
	clock.stop()


## The time ran to its stop: the result is in (the bowl put down at least once).
func finished() -> bool:
	return clock.started and not clock.running and clock.days >= clock.until - EPS


func reached() -> bool:
	return doublings >= goal() - EPS


# --- the run ----------------------------------------------------------------------------------------

## Every input back to its start (the yeast and the goal stay), the dough flat, the clock to the first
## morning.
func reset() -> void:
	super()
	clock.reset()
	clock.day_s = DAY_S_YEAST if has_yeast() else DAY_S_FLAT
	doublings = 0.0


## The round is done: the dough risen to the shelf by the oven, the time stopped there (what a finished
## spot shows: not the flat start).
func finish_pose() -> void:
	reset()
	set_input("yeast", 1.0)
	set_input("spot", WARM)
	set_input("goal", shelf_goal())
	doublings = shelf_goal()
	clock.days = warm_hours(0.0, shelf_goal()) / 24.0
	clock.started = true
	clock.until = clock.days


func animating() -> bool:
	return super() or clock.running


func step(dt: float) -> void:
	super(dt)
	var days := clock.advance(dt)
	if days > 0.0:
		doublings += days * 24.0 * rate()
		if not clock.running and absf(doublings - goal()) < 1e-4:
			doublings = goal()   # (the last step lands on the goal exactly)


## The judged result is in, or (no yeast) the time has run long enough for Puppy's "wait" line.
func decided() -> bool:
	if finished():
		return true
	return clock.started and not has_yeast() and clock.days >= HINT_DAYS


func status() -> String:
	if not clock.started:
		return "ready"
	if not finished():
		return "rising" if has_yeast() else "waiting"
	if reached() and has_yeast():
		return "doubled" if goal() < shelf_goal() - EPS else "shelf"
	return "little" if has_yeast() else "same"
