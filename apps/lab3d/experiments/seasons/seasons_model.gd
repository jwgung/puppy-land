## The 계절 spot's model (#87, 2026-11-07; docs/islands/hutton-missions.md 3): SunModel for Hutton
## Island (Seoul's latitude) with the Earth carried round the sun by the child's hand (the input
## "orbit") and its axis tilted or upright (the condition, "tilt": SunModel.EARTH_TILT or UPRIGHT).
## The noon sun's altitude and the day's length come from SunModel (noon_sun_altitude, day_hours);
## nothing here repeats its math.
##
## Its status names what the stages judge ("ready" until the Earth is moved, then its season()):
## - tilted, the orbit within SEASON_HALF_DEG of a solstice: "winter" (December) or "summer" (June);
##   else "spring" or "autumn" (the half of the orbit round the March or the September equinox).
##   The four seasons are the four quarters of the orbit centred on the solstices and equinoxes, as
##   in the East Asian 24 solar terms (입동 to 입춘 is winter): a generous, child-sized window round
##   each solstice, and the card's season and the judged one never disagree.
## - upright: "loop" once the Earth has been carried LOOP_DEG round (the trail since the run began)
##   with the noon sun's height changing by no more than SPREAD_MAX_DEG on the way ("계절이 안
##   바뀌어!"), else "upright" (no season; the loop is not done yet).
## A tilted loop is never "loop": its noon sun climbs and falls by twice the tilt.
## The trail (how far round the Earth went, the noon sun's lowest and highest on the way) starts
## over with every reset (다시, a condition, the next stage's start is the lab's).
## No number of degrees or hours is shown: the lab draws the sun's height and the day's length as
## pictures and bars only (the user: no over-specified numbers on the screen).
class_name SeasonsModel
extends SunModel

## Each season's half-width round its solstice or equinox (deg of orbit): the quarters of the orbit.
const SEASON_HALF_DEG := 45.0
## The upright stage's loop: carried at least this far round (deg; "a full turn", a little short of
## 360 for a child's finger), the noon sun's height changing by at most SPREAD_MAX_DEG on the way.
const LOOP_DEG := 330.0
const SPREAD_MAX_DEG := 2.0
## The orbit's solstices and equinoxes (SunModel: 0 = March equinox).
const MARCH := 0.0
const JUNE := 90.0
const SEPTEMBER := 180.0
const DECEMBER := 270.0
## The start: the March equinox (spring; the Earth on the near side of its path, in front of the sun).
const START_ORBIT := MARCH
## The noon sun's height and the day's length shown as bars (0..1 of these: full at the sun straight
## overhead, at a whole day of daylight).
const FULL_HEIGHT_DEG := 90.0

## The trail since the run began: the orbit unwrapped (deg), its lowest and highest, the noon sun's
## lowest and highest on the way.
var _trail_at := 0.0
var _trail_min := 0.0
var _trail_max := 0.0
var _noon_min := 0.0
var _noon_max := 0.0


func _init() -> void:
	super()   # SunModel declares the inputs
	set_start("orbit", START_ORBIT)
	set_start("rotation", NOON_ROTATION)
	_start_trail()


func set_input(id: String, value: float) -> void:
	var before := input("orbit")
	super(id, value)
	if id == "orbit":
		_trail_at += wrapf(input("orbit") - before, -180.0, 180.0)
		_trail_min = minf(_trail_min, _trail_at)
		_trail_max = maxf(_trail_max, _trail_at)
	if id == "orbit" or id == "tilt":
		var noon := noon_sun_altitude()
		_noon_min = minf(_noon_min, noon)
		_noon_max = maxf(_noon_max, noon)


## A condition (the tilt) starts the trail over: it is a new run.
func set_start(id: String, value: float) -> void:
	super(id, value)
	if id == "tilt":
		_start_trail()


func reset() -> void:
	super()
	_start_trail()


func _start_trail() -> void:
	_trail_at = 0.0
	_trail_min = 0.0
	_trail_max = 0.0
	_noon_min = noon_sun_altitude()
	_noon_max = _noon_min


## How far round the Earth has been carried since the run began (deg: the trail's span).
func trail_span() -> float:
	return _trail_max - _trail_min


## How much the noon sun's height changed on the trail (deg: its highest minus its lowest).
func noon_spread() -> float:
	return _noon_max - _noon_min


## The axis leans (the "기울어짐" condition).
func tilted() -> bool:
	return input("tilt") > UPRIGHT + 0.5


## The orbit's distance from `at` the short way round (deg, 0..180).
func orbit_from(at: float) -> float:
	return absf(wrapf(input("orbit") - at, -180.0, 180.0))


## "ready" until the Earth was moved in this run (a condition picked, 다시: nothing to judge or to
## miss yet), then season().
func status() -> String:
	return "ready" if trail_span() <= 0.0 else season()


## "winter" / "summer" / "spring" / "autumn" (tilted, the orbit's quarter), "loop" / "upright".
func season() -> String:
	if not tilted():
		return "loop" if trail_span() >= LOOP_DEG and noon_spread() <= SPREAD_MAX_DEG else "upright"
	if orbit_from(DECEMBER) <= SEASON_HALF_DEG:
		return "winter"
	if orbit_from(JUNE) <= SEASON_HALF_DEG:
		return "summer"
	return "spring" if orbit_from(MARCH) < SEASON_HALF_DEG else "autumn"


## The noon sun's height as a share of FULL_HEIGHT_DEG (0..1): the window's sun and its bar.
func noon_height_share() -> float:
	return clampf(noon_sun_altitude() / FULL_HEIGHT_DEG, 0.0, 1.0)


## The day's length as a share of the whole day (0..1): the window's day bar.
func day_share() -> float:
	return clampf(day_hours() / HOURS_PER_ROTATION, 0.0, 1.0)
