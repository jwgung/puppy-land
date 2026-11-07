## The 강물이 깎고 쌓기 spot's model (#95, 2026-11-07; docs/islands/hutton-missions.md 8,
## docs/islands/hutton.md "시뮬레이션": a spot with no simple formula keeps the textbook's relations as
## rules the tests check). Two inputs: the land's slope (the condition, "slope": GENTLE_DEG or
## STEEP_DEG) and the rain that has fallen since the run began ("rain", in seconds of a held cloud:
## the lab adds RAIN_PER_S for every second the finger holds it, up to RAIN_MAX).
##
## The rules (everything below is a pure function of the two inputs):
## - the water runs faster down steeper land: speed() = sqrt(sin slope / sin STEEP_DEG) (1 on the
##   steep land), and its cutting power goes with the speed squared: power() = speed()^2;
## - steep land cuts deep: the valley down the mountain deepens towards power() (as a share of the
##   steep land's deepest cut), so the gentle land's cut never gets deep (valley_depth());
## - slow water drops its sand: on gentle land (speed() under SETTLE_SPEED) the sand the river carries
##   settles where it reaches the sea (the sand bar, mouth_bar()) and on the inner side of the bend
##   (inner_bar()); on steep land the fast water carries it all out to sea (washed(): no bar);
## - a bend's outer bank is cut where the river swings sideways: on gentle land its work goes into the
##   sides of the bend (side_power() = 1 - power()); on steep land it goes mostly into cutting down
##   (the valley above), so the steep land's bend loses only a little of its bank, SIDE_LEAST, never
##   BANK_FULL (bank_cut(); 2026-11-07 user: real rivers on steep ground cut down and a little sideways).
## Each amount grows with the rain as 1 - exp(-rain / its time scale) times its most.
##
## Its status names what the stages judge: "ready" (no rain yet), then "valley" (the cut is DEEP or
## deeper: steep land only), "bank" (the outer bank cut BANK_FULL or more: gentle land only), "bar"
## (the sand bar BAR_FULL or more: gentle land only), else "little" (the steep land's bend: cut a little). The gentle land's bar comes
## before its bank (less rain), so a stage that wants the bar also takes "bank".
## No number is shown: the lab draws the cut, the sand and the bank, and the cards say them in words.
class_name RiverModel
extends EarthModel

## The land's slope (deg): the two condition buttons (the props draw the mountain at this angle).
const GENTLE_DEG := 15.0
const STEEP_DEG := 40.0
## The rain a held cloud gives (per second held) and the most a run keeps.
const RAIN_PER_S := 1.0
const RAIN_MAX := 12.0
## The time scales (s of rain) of the valley's cut, the mouth's sand bar, the bend's bank and bar.
const CUT_S := 2.2
const BAR_S := 2.0
const BEND_S := 2.2
## Sand settles where the water is slower than this (a share of the steep land's speed).
const SETTLE_SPEED := 0.75
## The goals: the valley's cut (share of the steep land's deepest), the sand bar, the outer bank's cut.
const DEEP := 0.6
const BAR_FULL := 0.55
const BANK_FULL := 0.45
## The least share of its work the river puts into its bend's sides (the steep land's: a little cut,
## well short of BANK_FULL, so it never reaches the piece).
const SIDE_LEAST := 0.25


func _init() -> void:
	define_input("slope", STEEP_DEG)
	define_input("rain", 0.0)


## The land is the steep one (the "가파름" condition).
func steep() -> bool:
	return input("slope") > (GENTLE_DEG + STEEP_DEG) * 0.5


## Rain fell for `seconds` more (a held cloud; at most RAIN_MAX in a run).
func rain_for(seconds: float) -> void:
	set_input("rain", minf(input("rain") + RAIN_PER_S * seconds, RAIN_MAX))


## How fast the water runs down this land (a share of the steep land's speed: 1 there).
func speed() -> float:
	return sqrt(sin(deg_to_rad(input("slope"))) / sin(deg_to_rad(STEEP_DEG)))


## The water's cutting power (the speed squared: 1 on the steep land).
func power() -> float:
	return speed() * speed()


## The share of its work the river puts into the sides of its bend (the rest cuts down): 1 - power(),
## at least SIDE_LEAST (the steep land's).
func side_power() -> float:
	return maxf(SIDE_LEAST, 1.0 - power())


## The sand stays (1) where the water is slow, or goes out to sea (0).
func kept() -> float:
	return 1.0 if speed() < SETTLE_SPEED else 0.0


## How far the rain has gone on a process of time scale `scale` (0..1).
func _soak(scale: float) -> float:
	return 1.0 - exp(-input("rain") / scale)


## The valley's cut down the mountain (0..1 of the steep land's deepest).
func valley_depth() -> float:
	return power() * _soak(CUT_S)


## The sand bar where the river meets the sea (0..1).
func mouth_bar() -> float:
	return kept() * _soak(BAR_S)


## The sand the fast water carried out to sea (0..1: the muddy plume past the mouth).
func washed() -> float:
	return (1.0 - kept()) * _soak(BAR_S)


## The bend's outer bank cut away (0..side_power()).
func bank_cut() -> float:
	return side_power() * _soak(BEND_S)


## The sand on the bend's inner side (0..1).
func inner_bar() -> float:
	return kept() * _soak(BEND_S)


## "ready" / "valley" / "bank" / "bar" / "little" (see the class notes).
func status() -> String:
	if input("rain") <= 0.0:
		return "ready"
	if valley_depth() >= DEEP:
		return "valley"
	if bank_cut() >= BANK_FULL:
		return "bank"
	if mouth_bar() >= BAR_FULL:
		return "bar"
	return "little"
