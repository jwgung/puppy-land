## The fast-forward clock of the labs whose change takes days (#157 소금 말리기, #159 반죽; the approved
## plan's decision 1, 안 A: docs/islands/curie-missions.md "시간이 오래 걸리는 일"). Pure state, no node,
## no clock of its own: the lab's model owns one and steps it at the fixed step (advance) while it runs.
##
## Time is counted in days: `days` 0 is the first morning; each day is one sweep of the time sign's
## marker from the sun end (share 0) to the moon end (share 1), DAY_S play seconds. The left half of
## the sweep (share < DUSK) is the day, the right half the night; when the marker reaches the moon end a
## night has passed (nights(): one moon stamp under the sign) and the next morning starts at the sun end.
## No number reaches the screen: the sign shows the marker, the sky goes dark, the stamps pile up.
##
## Use (A: the child's job starts it, it runs by itself):
## - start(): the time runs from now (the lab calls it when the child's job is done: a pour, a bowl put
##   down). stop(): it stops where it is (a bowl picked up again; it goes on with the next start()).
##   `until` (days, INF none) stops it by itself there: the moment the lab's judged state is reached.
## - advance(dt): the lab's model steps it (play seconds); returns the days that went by.
## - share() (0..1 the marker), nights() (moon stamps), night() (0 day .. 1 night: the scene's dark),
##   sunshine(a, b) (days of daylight between two times: what the sun dries).
## - locks_conditions(): true from the first start() until the time stops by itself at `until` or
##   reset() (the condition buttons are locked while the time flows, also while the lab's object is
##   held in the middle of it, and 다시 frees them: the mockup's "흐르는 동안 잠김". #159: free again
##   once the result is in, so the miss line's "pick the other button" can be done without 다시).
## - reset(): the first morning again, stopped and unlocked (다시).
class_name FastClock
extends RefCounted

## Play seconds of one day (sun end to moon end) at the default pace.
const DAY_S := 4.0
## The marker's share where the night starts (the bar's moon half).
const DUSK := 0.5
## The scene's dark eases in from EVENING to NIGHT_FULL and out over the last DAWN of the sweep.
const EVENING := 0.42
const NIGHT_FULL := 0.56
const DAWN := 0.08

## Play seconds per day (a lab may set its own pace).
var day_s := DAY_S
## Days since the first morning.
var days := 0.0
## The time flows now.
var running := false
## It has run since the last reset (locks_conditions).
var started := false
## It stops by itself once `days` reaches this (INF: never).
var until := INF


## The time flows from now (until `until`, if it is set and not reached).
func start() -> void:
	started = true
	running = days < until


## The time stops where it is.
func stop() -> void:
	running = false


## The first morning again: stopped, unlocked, no stop point.
func reset() -> void:
	days = 0.0
	running = false
	started = false
	until = INF


## Steps the clock by `dt` play seconds while it runs; returns the days that went by (it stops at
## `until`).
func advance(dt: float) -> float:
	if not running or dt <= 0.0:
		return 0.0
	var step := dt / day_s
	if days + step >= until:
		step = maxf(0.0, until - days)
		running = false
	days += step
	return step


## The marker's place on the sign: 0 at the sun end .. 1 at the moon end (the morning after a night is 0).
func share() -> float:
	return share_at(days)


static func share_at(at_days: float) -> float:
	return fposmod(at_days, 1.0)


## The nights gone by (the moon stamps under the sign).
func nights() -> int:
	return nights_at(days)


static func nights_at(at_days: float) -> int:
	return floori(at_days + 1e-9)


## How dark the scene is now: 0 by day, 1 at night (eased at dusk and dawn).
func night() -> float:
	return night_at(share())


static func night_at(share_now: float) -> float:
	if share_now > 1.0 - DAWN:
		return smoothstep(1.0, 1.0 - DAWN, share_now)
	return smoothstep(EVENING, NIGHT_FULL, share_now)


## The marker is in the bar's night half.
func is_night() -> bool:
	return share() >= DUSK


## The days of daylight (the left half of each sweep) between `from` and `to` days (to >= from).
static func sunshine(from: float, to: float) -> float:
	return _sunshine_to(to) - _sunshine_to(from)


## The daylight from the first morning up to `at` days.
static func _sunshine_to(at: float) -> float:
	if at <= 0.0:
		return 0.0
	var whole := floorf(at)
	return whole * DUSK + minf(at - whole, DUSK)


## The time it takes from the first morning to gather `need` days of daylight (the inverse of
## sunshine(0, ·)).
static func days_for_sunshine(need: float) -> float:
	if need <= 0.0:
		return 0.0
	var whole := floorf(need / DUSK - 1e-9)
	return whole + (need - whole * DUSK)


## The condition buttons are locked: the time has flowed since the last reset and has not yet stopped
## by itself at `until`.
func locks_conditions() -> bool:
	return started and (running or days < until)
