## The 물의 여행 spot's model (#91, 2026-11-07; docs/islands/hutton-missions.md 4): the sun warms the
## sea while the child presses and holds it, and the water goes round: it evaporates (invisible
## vapour rising), cools high up into a cloud, the cloud grows until its drops are too heavy and it
## rains, and the rain fills the dry pond. A weak or a strong sun (the condition) evaporates slowly or
## fast. One day has DAY_S seconds of sunshine: once they are used up the sun has set and nothing more
## evaporates until 다시 (the day's cap: a weak sun's day ends before the pond is full).
##
## Inputs (EarthModel):
## - "sun": the evaporation rate (cloud units per second of sunshine): WEAK_SUN or STRONG_SUN (the
##   condition button: its start, kept across reset()).
## - "heat": seconds of sunshine so far today (0..DAY_S). A held sun glides it towards DAY_S at one
##   second per second (heat_on); letting go stops it where it is (heat_off). It never goes back
##   except by reset() (다시, a new condition, the next stage).
##
## The water (pure functions of the two inputs, in cloud units: one unit is one small cloud's water):
## - evaporated() = sun * heat: all the water that went up from the sea today;
## - cloud: the evaporated water up to RAIN_AT (the cloud grows from CLOUD_AT, one small cloud, to
##   RAIN_AT, a heavy rain cloud); past RAIN_AT the cloud stays heavy and every more drop rains down;
## - rained() = evaporated() - RAIN_AT (0 before): the water in the pond, full at POND_FULL.
## A rule-based model, not a weather formula (docs/islands/hutton.md "시뮬레이션": the relations are
## the textbook's: a warmer sea evaporates more, a cloud rains once its drops are heavy, a stronger
## sun brings more rain; tests/water_cycle_checks.gd checks them).
##
## status() (judged by MissionRound; no number is on the screen):
## "ready" (no sunshine yet today), "vapour" (water went up, no cloud yet), "cloud" (a cloud, not yet
## heavy), "rain" (it has rained, the pond not full), "full" (the pond is full).
## The numbers make the stages' feel (the user: a weak sun can never fill the pond):
## - a weak sun makes its first cloud after CLOUD_AT / WEAK_SUN = 2.5 s, rains after 5 s, and by the
##   day's end (10 s) has rained 2 of the pond's 3: never full;
## - a strong sun makes a cloud in 1 s, rains after 2 s and fills the pond after 5 s.
class_name WaterCycleModel
extends EarthModel

## The evaporation rates of the condition's two suns (cloud units per second of sunshine).
const WEAK_SUN := 0.4
const STRONG_SUN := 1.0
## One day's sunshine (s): the most the sun can be held before it sets.
const DAY_S := 10.0
## The water (cloud units) for the first small cloud, for a heavy cloud that rains, and the rain
## that fills the pond.
const CLOUD_AT := 1.0
const RAIN_AT := 2.0
const POND_FULL := 3.0
## The sun's day goes by at one second of sunshine per second held.
const HEAT_RATE := 1.0


func _init() -> void:
	define_input("sun", WEAK_SUN)
	define_input("heat", 0.0, HEAT_RATE)


## Whether `rate` is the strong sun (nearer it than the weak one).
static func is_strong(rate: float) -> bool:
	return rate > (WEAK_SUN + STRONG_SUN) * 0.5


## The sun shines on the sea from now (a finger holds it): the day's sunshine runs on to its end.
func heat_on() -> void:
	glide_to("heat", DAY_S)


## The sun is let go: the sunshine stops where it is.
func heat_off() -> void:
	set_input("heat", input("heat"))


## The sun is shining on the sea now (held, the day not over).
func heating() -> bool:
	return animating()


## The day's sunshine is used up: the sun has set (until 다시).
func day_over() -> bool:
	return input("heat") >= DAY_S - ARRIVED


## The share of the day's sunshine left (1 at dawn .. 0 at sunset): the day bar.
func day_left() -> float:
	return clampf(1.0 - input("heat") / DAY_S, 0.0, 1.0)


## All the water that went up from the sea today (cloud units).
func evaporated() -> float:
	return input("sun") * input("heat")


## The water in the sky's cloud (cloud units, 0..RAIN_AT): it grows until it rains.
func cloud_water() -> float:
	return minf(evaporated(), RAIN_AT)


## The cloud's size, 0 (no cloud) .. 1 (a heavy rain cloud): 0 below CLOUD_AT, then growing.
func cloud_share() -> float:
	if evaporated() < CLOUD_AT:
		return 0.0
	return clampf((cloud_water() - CLOUD_AT) / (RAIN_AT - CLOUD_AT), 0.0, 1.0)


## The rain that fell into the pond (cloud units, 0..POND_FULL).
func rained() -> float:
	return clampf(evaporated() - RAIN_AT, 0.0, POND_FULL)


## The pond's water as a share of full (0..1).
func pond_share() -> float:
	return rained() / POND_FULL


## The cloud rains now: it is heavy and the sun still sends it water (held, the pond not yet full).
func raining() -> bool:
	return heating() and evaporated() >= RAIN_AT and pond_share() < 1.0


func status() -> String:
	var water := evaporated()
	if water <= 0.0:
		return "ready"
	if water < CLOUD_AT:
		return "vapour"
	if water < RAIN_AT:
		return "cloud"
	return "full" if pond_share() >= 1.0 - 1e-9 else "rain"
