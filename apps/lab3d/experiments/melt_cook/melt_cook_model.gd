## The 되돌릴 수 있을까? spot's model (#158, 2026-11-17; Curie Island's third spot,
## docs/islands/curie-missions.md 3): a pot on a stove whose red handle the child presses: heat on while
## pressed, off when let go. What is in the pot is the condition: chocolate or an egg.
##
## The rule the spot teaches (curie-lines.md 3): warming or cooling changes how a substance looks; some
## changes can be undone and some cannot.
## - Chocolate: cocoa butter melts at about MELT_C (crystal form V, 34 °C) and sets again below SET_C
##   (about 28 °C). The state follows the temperature both ways (a latch with the two thresholds), so
##   melting and setting can be done over and over: a physical change, reversible.
## - An egg: its proteins fold up for good between SET_START_C (about 60 °C, the white starts to set)
##   and COOK_C (about 70 °C, the yolk is set too). That progress (`doneness`) only ever grows: cooled
##   down again the egg stays cooked, and it cannot become a raw egg again: a chemical change, not
##   reversible.
## - Heating: the pot's contents warm towards the flame's temperature (FIRE_C: a gentle one for the
##   chocolate; the egg's water boils at BOIL_C) and cool towards ROOM_C; the chocolate / the egg
##   inside follows the pot's temperature with a lag (a first-order lag; the time constants are play
##   seconds, one number for each direction: the real times are minutes, the lab shows them faster).
##
## Inputs: "item" (0 chocolate, 1 egg: the condition), "site" (the stage's table: BLOCK the pot holds
## the chocolate block, POURED the bread cat has poured it into the star mold, warm; SHINY the stage of
## the shiny egg: it goes into the pot with the egg item, the poured star stays), "heat" (0 / 1: the
## handle is pressed), "water" (the pot's temperature °C), "core" (the chocolate's or the egg's °C),
## "molten" (0 / 1: the chocolate is liquid), "doneness" (0..1: how much the egg has cooked, never goes
## down), "touched" (0 / 1: the handle was pressed this run, or the star was poured), "slab" (0 / 1: the
## chocolate has been melted: a flat slab, not a block, when it sets in the pot), "held" (s the handle
## has been pressed in a row) and "time" (play seconds since the run's start: the graph).
##
## Its status names what the stages judge: "ready" (nothing pressed yet), "heating" (pressed, nothing
## to judge yet), "melted" (the chocolate is liquid), "solid" (the chocolate block, let go before it
## melted), "set" (the poured chocolate has set again in the star: reversible), "raw" (the egg, let go
## before it was cooked), "cooked" (the egg is cooked and still hot), "cooled" (cooked and cooled down
## again: still cooked, irreversible). No number is shown on the screen.
class_name MeltCookModel
extends EarthModel

const CHOCOLATE := 0.0
const EGG := 1.0
const BLOCK := 0.0
const POURED := 1.0
const SHINY := 2.0
## Temperatures (°C): the room, the chocolate's melting point (cocoa butter form V) and where it sets
## again, the flame under the chocolate (a gentle one: chocolate burns above about 55 °C) and the boiling
## water of the egg, where the egg's white starts to set and where its yolk is set, and how cool it must
## be to hold.
const ROOM_C := 20.0
const MELT_C := 34.0
const SET_C := 28.0
const FIRE_C := 55.0
const BOIL_C := 100.0
const SET_START_C := 60.0
const COOK_C := 70.0
const COOL_C := 35.0
## The poured chocolate's start: warm and runny (°C).
const POUR_START_C := 46.0
## The lags (play seconds): the pot's temperature towards the flame / the room, the contents' towards the
## pot's.
const POT_UP_S := 2.2
const POT_DOWN_S := 3.0
const CORE_UP_S := 1.6
const CORE_DOWN_S := 3.2
## How soft the unmelted chocolate block looks at most (a share of the puddle).
const SOFT_MAX := 0.6
## The pressed handle counts as "held long" (Puppy's "let go and let it cool" hint on the poured star).
const HINT_S := 1.5
## Nothing changes by less than this (°C): the model is at rest.
const REST_C := 0.01


func _init() -> void:
	define_input("item", CHOCOLATE)
	define_input("site", BLOCK)
	define_input("heat", 0.0)
	define_input("water", ROOM_C)
	define_input("core", ROOM_C)
	define_input("molten", 0.0)
	define_input("doneness", 0.0)
	define_input("touched", 0.0)
	define_input("slab", 0.0)
	define_input("held", 0.0)
	define_input("time", 0.0)


# --- conditions -----------------------------------------------------------------------------------

## The condition: chocolate (false) or an egg (true), kept across reset().
func set_egg(egg: bool) -> void:
	set_start("item", EGG if egg else CHOCOLATE)
	_start_state()


func is_egg() -> bool:
	return input("item") > 0.5


## The stage's table (BLOCK, POURED or SHINY), kept across reset().
func set_site(site: float) -> void:
	set_start("site", site)
	_start_state()


func site() -> float:
	return input("site")


func poured() -> bool:
	return not is_egg() and site() >= POURED


## The run starts over: the contents at their start (a raw egg, a block, or the warm poured chocolate).
func reset() -> void:
	super()
	_start_state()


func _start_state() -> void:
	var warm := poured()
	set_start("water", POUR_START_C if warm else ROOM_C)
	set_start("core", POUR_START_C if warm else ROOM_C)
	set_start("molten", 1.0 if warm else 0.0)
	set_start("touched", 1.0 if warm else 0.0)
	set_start("slab", 1.0 if warm else 0.0)
	set_start("doneness", 0.0)
	set_start("heat", 0.0)
	set_start("held", 0.0)
	set_start("time", 0.0)
	for id: String in ["water", "core", "molten", "touched", "slab", "doneness", "heat", "held", "time"]:
		set_input(id, _starts[id])


# --- the hand -------------------------------------------------------------------------------------

## The handle is pressed (true) or let go (false).
func press(on: bool) -> void:
	set_input("heat", 1.0 if on else 0.0)
	if on:
		set_input("touched", 1.0)
	else:
		set_input("held", 0.0)


func pressing() -> bool:
	return input("heat") > 0.5


# --- what is in the pot ---------------------------------------------------------------------------

func core_c() -> float:
	return input("core")


func water_c() -> float:
	return input("water")


func molten() -> bool:
	return input("molten") > 0.5


func cooked() -> bool:
	return input("doneness") >= 1.0


func touched() -> bool:
	return input("touched") > 0.5


## The flame's temperature under the pot now (the pot's target while pressed).
func fire_c() -> float:
	return BOIL_C if is_egg() else FIRE_C


## How soft the chocolate looks (0 a hard block .. 1 a runny puddle): the block softens as it warms,
## runny once molten.
func softness() -> float:
	if molten():
		return 1.0
	return clampf((core_c() - ROOM_C) / (MELT_C - ROOM_C), 0.0, 1.0) * SOFT_MAX


## The pot's water boils (bubbles).
func boiling() -> bool:
	return is_egg() and water_c() >= BOIL_C - 5.0


## Warm enough to steam (the chocolate or the egg's pot).
func steaming() -> bool:
	return core_c() >= COOL_C + 5.0 or (is_egg() and water_c() >= COOL_C + 15.0)


func animating() -> bool:
	if pressing():
		return true
	return absf(water_c() - ROOM_C) > REST_C or absf(core_c() - water_c()) > REST_C


func step(dt: float) -> void:
	var heat := pressing()
	var target := fire_c() if heat else ROOM_C
	var water := water_c()
	water = _toward(water, target, dt, POT_UP_S if target > water else POT_DOWN_S)
	var core := core_c()
	core = _toward(core, water, dt, CORE_UP_S if water > core else CORE_DOWN_S)
	set_input("water", water)
	set_input("core", core)
	if core >= MELT_C:
		set_input("molten", 1.0)
	elif core <= SET_C:
		set_input("molten", 0.0)
	if molten():
		set_input("slab", 1.0)
	if is_egg() or input("doneness") > 0.0:
		var done := clampf((core - SET_START_C) / (COOK_C - SET_START_C), 0.0, 1.0)
		set_input("doneness", maxf(input("doneness"), done))
	set_input("held", input("held") + dt if heat else 0.0)
	set_input("time", input("time") + dt)


## `value` moves to `target` with a lag of `lag` seconds (a first-order lag, exact for any step; the
## last bit lands on it).
static func _toward(value: float, target: float, dt: float, lag: float) -> float:
	var next := target + (value - target) * exp(-dt / lag)
	return target if absf(next - target) < 1e-4 else next


## The judged result is in: the chocolate melted, the poured chocolate set again, the egg cooked and
## cooled; or the run has come to a miss (a chocolate block or an egg let go too early, the poured star
## kept on the fire).
func decided() -> bool:
	var s := status()
	if s == "set" or s == "cooled":
		return true
	if is_egg():
		return s == "raw"
	if not poured():
		return s == "melted" or s == "solid"
	return pressing() and input("held") >= HINT_S


func status() -> String:
	if not touched():
		return "ready"
	if is_egg():
		if cooked():
			return "cooled" if core_c() <= COOL_C else "cooked"
		return "heating" if pressing() else "raw"
	if molten():
		return "melted"
	if poured():
		return "heating" if pressing() else "set"
	return "heating" if pressing() else "solid"
