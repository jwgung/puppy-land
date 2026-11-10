## The 지진 spot's model (#97, 2026-11-07; docs/islands/hutton-missions.md 10): the shake table, the
## ground on it and the block house, as three small oscillators stepped in 64 bit at fixed steps (no
## random number, no engine): the same pull on the same ground and house always shakes the same way.
##
## - The table: the child pulls it back by `pull` (PULL_MIN..1 of the full pull, PULL_STEP levels) and
##   lets go. It swings back and forth like a spring, u'' = -wt² u - 2 zt wt u', from u = -pull x SWING_MAX
##   at rest, dying down over the run (RUN_S).
## - The ground: the ground's surface moves AMPLIFY[ground] times the table (rock 1, soft sand 2: the
##   textbook's "무른 땅은 더 크게 흔들린다", a soft layer shakes more than the rock under it).
## - The house: a one-storey frame on that ground, its top drifting d from its foot:
##   d'' = -wh² d - 2 zh wh d' - a_ground. Without a brace it is soft (HOUSE_HZ, close to the table's
##   swing: it rocks more and more); a diagonal brace makes it stiff (BRACED_HZ). The house falls the
##   first step its drift passes DRIFT_MAX, and stays down.
## - A plain house (no brace) on the same ground with the same shake is stepped beside it: "held" is
##   that plain house falling while the braced one stands.
## The motion is linear in the pull, so a house falls exactly when pull x AMPLIFY x SWING_MAX x its
## response passes DRIFT_MAX: on rock the plain house stands up to half the full pull (falls from 0.6),
## on sand it would stand up to 0.2 and falls from 0.3; the braced house stands on either ground at the
## full pull (tests/earthquake_checks.gd). The lightest pull is PULL_MIN = 0.3 (#114, one condition per
## stage): every light shake that rock stands (0.3-0.5, stage 1) brings the plain house down on sand
## (stage 2), and the brace holds it there even at the full pull (stage 3).
##
## Status ("ready" until a pull is let go, "shaking" for RUN_S, then the result): "toppled" (the house
## fell under a light shake, LIGHT_MAX at most: stage 2's "똑같이 살짝", #114), "fell" (it fell under a
## harder one), "strongest" (it stood the full pull), "held" (it stood a shake the plain house on that
## ground does not), "stood" (it stood a shake the plain house also stands).
## Inputs: "pull" (the shake of the run), "ground" (0 rock, 1 sand) and "brace" (0 none, 1 brace):
## the two conditions are starts (set_start), kept across reset().
class_name EarthquakeModel
extends EarthModel

const ROCK := 0.0
const SAND := 1.0
## The ground surface's swing over the table's (rock, sand).
const AMPLIFY := [1.0, 2.0]
## The table's full swing (m, at the full pull), its frequency (Hz) and damping ratio.
const SWING_MAX := 0.25
const TABLE_HZ := 1.1
const TABLE_DAMPING := 0.07
## The house: its frequency without and with the brace (Hz), its damping ratio, and the drift of its top
## past which it falls (m; the frame is HOUSE_HEIGHT tall).
const HOUSE_HZ := 0.9
const BRACED_HZ := 2.5
const HOUSE_DAMPING := 0.05
const DRIFT_MAX := 0.38
const HOUSE_HEIGHT := 1.8
## The pull: levels of PULL_STEP from PULL_MIN (a real pull is never nothing, and the lightest already
## brings the plain house down on sand) to 1 (the full pull).
const PULL_STEP := 0.1
const PULL_MIN := 0.3
const FULL := 1.0
## The light shakes ("살짝"): every pull the plain house stands on rock, up to half the full pull.
const LIGHT_MAX := 0.5
## One run of the shake (s) and the substeps per fixed step (the oscillators' accuracy).
const RUN_S := 4.0
const SUBSTEPS := 4
const STEPS_PER_SECOND := 60

## The run: let go (a pull was released since the last reset), still shaking.
var released := false
var running := false
## Fixed steps since the release.
var steps := 0
## The table (m, m/s), the ground's surface (m) and its acceleration (m/s²).
var table := 0.0
var table_v := 0.0
var ground_x := 0.0
var ground_a := 0.0
## The house's drift (m, its top from its foot) and drift speed; the largest drift so far; the step it fell
## (-1: standing).
var drift := 0.0
var drift_v := 0.0
var drift_peak := 0.0
var fell_step := -1
## The plain house beside it (no brace, the same ground and shake).
var plain := 0.0
var plain_v := 0.0
var plain_fell := false


func _init() -> void:
	define_input("pull", 0.0)
	define_input("ground", ROCK)
	define_input("brace", 0.0)


## The pull let go at `level` (snapped to the PULL_STEP levels, at least PULL_MIN): the run starts.
func release(level: float) -> void:
	_clear_run()
	set_input("pull", snapped_pull(level))
	released = true
	running = true
	table = -input("pull") * SWING_MAX
	ground_x = table * amplify()


## `level` on the pull's levels (PULL_MIN .. FULL).
static func snapped_pull(level: float) -> float:
	return clampf(roundf(level / PULL_STEP) * PULL_STEP, PULL_MIN, FULL)


func amplify() -> float:
	return AMPLIFY[1] if input("ground") >= 0.5 else AMPLIFY[0]


func braced() -> bool:
	return input("brace") >= 0.5


func fell() -> bool:
	return fell_step >= 0


func animating() -> bool:
	return running


## One fixed step: SUBSTEPS semi-implicit Euler substeps of the table, the house and the plain house.
func step(dt: float) -> void:
	if not running:
		return
	var h := dt / SUBSTEPS
	var wt := TAU * TABLE_HZ
	var wh := TAU * (BRACED_HZ if braced() else HOUSE_HZ)
	var wp := TAU * HOUSE_HZ
	var k := amplify()
	for i in SUBSTEPS:
		var a := -wt * wt * table - 2.0 * TABLE_DAMPING * wt * table_v
		table_v += a * h
		table += table_v * h
		ground_a = k * a
		drift_v += (-wh * wh * drift - 2.0 * HOUSE_DAMPING * wh * drift_v - ground_a) * h
		drift += drift_v * h
		plain_v += (-wp * wp * plain - 2.0 * HOUSE_DAMPING * wp * plain_v - ground_a) * h
		plain += plain_v * h
	ground_x = k * table
	steps += 1
	if not fell():
		drift_peak = maxf(drift_peak, absf(drift))
		if absf(drift) > DRIFT_MAX:
			fell_step = steps
	if absf(plain) > DRIFT_MAX:
		plain_fell = true
	if steps >= run_steps():
		running = false


static func run_steps() -> int:
	return roundi(RUN_S * STEPS_PER_SECOND)


## Every input back to its start (the conditions keep theirs) and no run.
func reset() -> void:
	super()
	_clear_run()


func _clear_run() -> void:
	released = false
	running = false
	steps = 0
	table = 0.0
	table_v = 0.0
	ground_x = 0.0
	ground_a = 0.0
	drift = 0.0
	drift_v = 0.0
	drift_peak = 0.0
	fell_step = -1
	plain = 0.0
	plain_v = 0.0
	plain_fell = false


func status() -> String:
	if not released:
		return "ready"
	if running:
		return "shaking"
	if fell():
		return "toppled" if input("pull") <= LIGHT_MAX + 1e-9 else "fell"
	if input("pull") >= FULL - 1e-9:
		return "strongest"
	return "held" if plain_fell else "stood"


## The whole run of a pull `level` on `ground` with or without the brace, at once (tests, the
## judging widths): [status, the house's peak drift, the plain house fell].
static func outcome(level: float, ground: float, brace: bool) -> Array:
	var m := EarthquakeModel.new()
	m.set_start("ground", ground)
	m.set_start("brace", 1.0 if brace else 0.0)
	m.release(level)
	while m.running:
		m.step(1.0 / STEPS_PER_SECOND)
	return [m.status(), m.drift_peak, m.plain_fell]
