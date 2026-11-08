## The 화산 spot's model (#98, 2026-11-07; docs/islands/hutton-missions.md 11, docs/islands/hutton.md
## "시뮬레이션": no simple formula, so the textbook's relations are rules the tests check). Its inputs:
## - "stickiness": the magma (the condition button): RUNNY 0, NORMAL 1, STICKY 2;
## - "site": SMALL 0 (the small volcano model on the sand table, stages 1 and 2) or BIG 1 (the island's
##   bubbling volcano by the sea, stage 3 and after);
## - "magma": how much the child pumped up in this press (0..1 of a full pump: the press time over
##   PUMP_S, HoldRamp, the lab sets it);
## - "lava": how much of it came out on the ground (0..1), gliding after "magma" at LAVA_RATE (the
##   lava comes out while the pump runs and finishes a moment after the finger lets go).
##
## The rules (all of them pure functions of the inputs):
## - the small model: the lava piles round the vent as a cone at its stickiness's slope (SLOPE_DEG:
##   runny lava runs out flat, sticky lava stands steep). Its volume is lava x MODEL_VOLUME, so the
##   cone's reach is cbrt(3 V / (pi tan slope)) and its height is reach x tan slope: with the same lava
##   a stickier one reaches less far and stands taller; more lava makes any of them reach farther and
##   stand taller. "wide" = reach >= REACH_WIDE and height < LOW_MAX (stage 1: only runny lava gets
##   there), "tall" = height >= TALL_MIN (stage 2: only sticky lava), else "small".
## - the big volcano (hutton.md "화산(큰 장면)": too runny only runs off, too sticky plugs and bubbles):
##   sticky magma plugs the crater ("plugged": nothing flows, it bubbles); runny lava pours over the
##   rim and spreads into a thin sheet across the slope whose front never passes THIN_STOP of the way
##   down ("thin"); normal lava runs down the valley as one stream, its front lava / SEA_SHARE of the
##   way, and reaches the sea at SEA_SHARE of a full pump ("sea": it cools there into new land), less
##   is "short".
## - "ready" while no lava is out (the start, 다시, a new press before the pump has run a step).
## No number is shown: the lab draws the cone, the stream and the land; the cards are words.
class_name VolcanoModel
extends EarthModel

const RUNNY := 0.0
const NORMAL := 1.0
const STICKY := 2.0
const SMALL := 0.0
const BIG := 1.0
## The condition button's options in stickiness order (the control's ids).
const KINDS := ["runny", "normal", "sticky"]
## A full pump takes PUMP_S seconds of pressing (the press time sets the amount); the lava follows
## at LAVA_RATE (share of a full pump per second, faster than the pump).
const PUMP_S := 4.0
const LAVA_RATE := 0.45
## The slope each lava piles at (deg; runny, normal, sticky): the steeper, the stickier.
const SLOPE_DEG := [6.0, 20.0, 45.0]
## The small model's lava at a full pump (m^3): runny lava then reaches about 3.1 m on the table.
const MODEL_VOLUME := 3.2
## Stage 1: a low, wide mountain reaches REACH_WIDE m from the vent and stays under LOW_MAX m.
const REACH_WIDE := 2.3
const LOW_MAX := 0.6
## Stage 2: a tall, steep one stands TALL_MIN m or more.
const TALL_MIN := 1.1
## The big volcano: normal lava reaches the sea at SEA_SHARE of a full pump; runny lava's thin sheet
## stops THIN_STOP of the way down.
const SEA_SHARE := 0.6
const THIN_STOP := 0.55


func _init() -> void:
	define_input("stickiness", RUNNY)
	define_input("site", SMALL)
	define_input("magma", 0.0)
	define_input("lava", 0.0, LAVA_RATE)


## The stickiness of option `kind` ("runny", "normal", "sticky"; an unknown one: normal).
static func stickiness_of(kind: String) -> float:
	var i := KINDS.find(kind)
	return float(i) if i >= 0 else NORMAL


## The slope (deg) lava of `stickiness` piles at.
static func slope_of(stickiness: float) -> float:
	return float(SLOPE_DEG[clampi(roundi(stickiness), 0, SLOPE_DEG.size() - 1)])


## The cone's reach (m from the vent) of `share` of a full pump of lava at `stickiness` (the model).
static func reach_of(share: float, stickiness: float) -> float:
	var volume := maxf(share, 0.0) * MODEL_VOLUME
	return pow(3.0 * volume / (PI * tan(deg_to_rad(slope_of(stickiness)))), 1.0 / 3.0)


## The cone's height (m) for the same lava.
static func height_of(share: float, stickiness: float) -> float:
	return reach_of(share, stickiness) * tan(deg_to_rad(slope_of(stickiness)))


func stickiness() -> float:
	return input("stickiness")


## The magma's option now ("runny", "normal", "sticky").
func kind() -> String:
	return KINDS[clampi(roundi(stickiness()), 0, KINDS.size() - 1)]


func big() -> bool:
	return input("site") >= BIG - 0.5


## The small model's cone now (m).
func reach() -> float:
	return reach_of(input("lava"), stickiness())


func height() -> float:
	return height_of(input("lava"), stickiness())


## How far down the big volcano the lava's front is (0 the crater .. 1 the shore; past 1 the stream
## builds land into the sea). Sticky lava stays in the crater.
func front() -> float:
	var lava := input("lava")
	if kind() == "sticky":
		return 0.0
	if kind() == "runny":
		return minf(lava / SEA_SHARE, THIN_STOP)
	return lava / SEA_SHARE


## How much new land the stream built into the sea (0..1: none until the front reaches the shore,
## all of it at a full pump).
func new_land() -> float:
	if kind() != "normal":
		return 0.0
	return clampf((input("lava") - SEA_SHARE) / (1.0 - SEA_SHARE), 0.0, 1.0) if front() >= 1.0 else 0.0


func status() -> String:
	if input("lava") <= 0.0:
		return "ready"
	if big():
		if kind() == "sticky":
			return "plugged"
		if kind() == "runny":
			return "thin"
		return "sea" if front() >= 1.0 else "short"
	if height() >= TALL_MIN:
		return "tall"
	if reach() >= REACH_WIDE and height() < LOW_MAX:
		return "wide"
	return "small"


func observations() -> Dictionary:
	return {"state": status(), "amount": input("lava"), "stickiness": stickiness()}
