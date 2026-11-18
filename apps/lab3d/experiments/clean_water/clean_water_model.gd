## The 깨끗한 물 만들기 spot's model (#160, 2026-11-18; Curie Island's fifth spot, docs/islands/curie-missions.md 5
## and curie-lines.md 5): muddy spring water poured from a kettle into a filter column over a jar, and (stage 3)
## the clear water boiled in a pot on a wood fire that the child blows up with a bellows.
##
## The rule the spot teaches (curie-lines.md 5): a mixture can be separated because its bits differ.
## - Sand catches what is bigger than the gaps it leaves (SAND_CATCH_UM: a sand bed holds back particles of
##   about 5 um and up): the soil of muddy water (silt and clay flocks, SOIL_UM about 20 um) stays on the sand.
##   Germs (bacteria, GERM_UM about 1 um) and what colours the water and smells (dissolved stuff, far smaller)
##   go through.
## - Charcoal has a great many tiny pores that hold on to the colour and the smell (adsorption): water through
##   sand and charcoal is clear and smells of nothing. Germs still go through.
## - Boiling: at a rolling boil the germs die (BOIL_C 100 °C; a minute of boiling is the usual advice, the lab
##   shows it in KILL_S play seconds). Only boiling clears them here; no filter does.
## - The bellows: each pump blows the fire up by PUMP_KICK (at most 1); the fire dies down by itself (a
##   first-order lag, FIRE_FADE_S). The pot's water warms towards the fire's temperature (FLAME_C: a fire
##   blown up keeps the pot boiling) and cools towards ROOM_C (lags POT_UP_S / POT_DOWN_S); it never passes
##   BOIL_C (boiling water stays at 100 °C).
##
## Inputs: "filter" (EMPTY, SAND, CHARCOAL: sand and charcoal; the condition), "site" (FILTER the kettle over
## the filter: stages 1 and 2; BOIL the pot on the fire: stage 3), "tilt" (the kettle's tilt now, -1..1:
## MotionInput, pouring past 0), "kettle" (the muddy water left in it, 1 full .. 0), "column" (water in the
## filter on its way down), "jar" (water come through into the jar), "soil" / "colour" / "smell" / "germs"
## (how much of each the jar's water carries, 0 none .. 1 as in the spring), "fire" (0 out .. 1 roaring),
## "water" (the pot's °C), "pot_germs" (the pot's germs, 1 .. 0), "pumps" (bellows pumps this run),
## "touched" (0 / 1: the kettle tipped or the bellows pumped this run) and "time" (play seconds since the run's
## start).
##
## Its status names what the stages judge: FILTER "ready" (nothing poured yet), "pouring" (water on its way),
## "little" (stopped with too little come through: Puppy's "거름 통에 부어 봐!"), "muddy" (the empty column:
## the soil came through), "filtered" (sand: no soil, still yellowish and smelly), "clear" (sand and charcoal:
## clear, no smell); BOIL "ready", "heating" (the fire is going or the water is still hot), "unboiled" (the
## fire died before the germs were gone: "보글보글 끓을 때까지!"), "boiled" (the germs are gone). No number is
## shown on the screen.
class_name CleanWaterModel
extends EarthModel

const EMPTY := 0.0
const SAND := 1.0
const CHARCOAL := 2.0
const FILTER := 0.0
const BOIL := 1.0
## Sizes (um): a silt particle of the muddy water, a germ (bacterium), what a sand bed still holds back.
const SOIL_UM := 20.0
const GERM_UM := 1.0
const SAND_CATCH_UM := 5.0
## What passes the charcoal of the colour and the smell (a share: it holds on to nearly all of it).
const CHARCOAL_PASS := 0.05
## The pour (kettles per play second at a full tilt), how long the column takes to let water through (a
## first-order lag, s), how much must come through for the jar to count (of a kettle), what is "nothing
## left on its way".
const POUR_RATE := 0.3
const DRAIN_S := 0.9
const ENOUGH := 0.6
const DRAINED := 0.01
## The jar's water counts as muddy / coloured past these shares.
const MUDDY := 0.5
const COLOURED := 0.5
## Temperatures (°C): the room, boiling water, the blown-up fire's (it keeps the pot boiling); the lags (s).
const ROOM_C := 20.0
const BOIL_C := 100.0
const FLAME_C := 130.0
const POT_UP_S := 3.0
const POT_DOWN_S := 4.0
## The fire: what one pump adds, how fast it dies down (s), "out" below this.
const PUMP_KICK := 0.45
const FIRE_FADE_S := 3.0
const FIRE_OUT := 0.05
## The germs die in this many play seconds at a rolling boil (a minute of boiling, shown faster).
const KILL_S := 2.0
## Nothing changes by less than this: the model is at rest.
const REST := 1e-4


func _init() -> void:
	define_input("filter", SAND)
	define_input("site", FILTER)
	define_input("tilt", 0.0)
	define_input("kettle", 1.0)
	define_input("column", 0.0)
	define_input("jar", 0.0)
	define_input("soil", 0.0)
	define_input("colour", 0.0)
	define_input("smell", 0.0)
	define_input("germs", 0.0)
	define_input("fire", 0.0)
	define_input("water", ROOM_C)
	define_input("pot_germs", 1.0)
	define_input("pumps", 0.0)
	define_input("touched", 0.0)
	define_input("time", 0.0)


# --- conditions -----------------------------------------------------------------------------------

## The filter column: EMPTY, SAND or CHARCOAL (sand and charcoal), kept across reset().
func set_filter(kind: float) -> void:
	set_start("filter", kind)


func filter() -> float:
	return input("filter")


## The stage's place (FILTER or BOIL), kept across reset().
func set_site(site: float) -> void:
	set_start("site", site)


func site() -> float:
	return input("site")


func boiling_site() -> bool:
	return site() >= BOIL


# --- what the filter lets through (the textbook part) ----------------------------------------------

## The share of the spring's soil that comes through the filter `kind` (sand catches what is bigger than
## its gaps).
static func soil_pass(kind: float) -> float:
	return 0.0 if kind >= SAND and SOIL_UM >= SAND_CATCH_UM else 1.0


## The share of the germs that comes through (they are smaller than the sand's gaps; charcoal holds on to
## colour and smell, not to germs).
static func germ_pass(kind: float) -> float:
	return 0.0 if kind >= SAND and GERM_UM >= SAND_CATCH_UM else 1.0


## The share of the colour and the smell that comes through (only charcoal holds on to them).
static func colour_pass(kind: float) -> float:
	return CHARCOAL_PASS if kind >= CHARCOAL else 1.0


# --- the hand -------------------------------------------------------------------------------------

## The kettle's tilt now (-1..1: MotionInput; past 0 it pours).
func set_tilt(value: float) -> void:
	set_input("tilt", clampf(value, -1.0, 1.0))
	if value > 0.0 and not boiling_site() and input("kettle") > 0.0:
		set_input("touched", 1.0)


## One pump of the bellows: the fire grows.
func pump() -> void:
	if not boiling_site():
		return
	set_input("fire", minf(1.0, input("fire") + PUMP_KICK))
	set_input("pumps", input("pumps") + 1.0)
	set_input("touched", 1.0)


func touched() -> bool:
	return input("touched") > 0.5


func pouring() -> bool:
	return not boiling_site() and input("tilt") > 0.0 and input("kettle") > 0.0


## How thick the stream from the kettle is now (0 none .. 1 the most).
func stream() -> float:
	return maxf(0.0, input("tilt")) if pouring() else 0.0


func boiling() -> bool:
	return boiling_site() and input("water") >= BOIL_C - 0.5


func fire_on() -> bool:
	return input("fire") > FIRE_OUT


func animating() -> bool:
	if boiling_site():
		return fire_on() or absf(input("water") - ROOM_C) > 0.05
	return pouring() or input("column") > 0.0


func step(dt: float) -> void:
	set_input("time", input("time") + dt)
	if boiling_site():
		_step_fire(dt)
	else:
		_step_pour(dt)


func _step_pour(dt: float) -> void:
	var out := minf(input("kettle"), POUR_RATE * stream() * dt)
	set_input("kettle", input("kettle") - out)
	var column := input("column") + out
	var through := column * (1.0 - exp(-dt / DRAIN_S))
	if column - through < DRAINED:
		through = column
	set_input("column", column - through)
	if through <= 0.0:
		return
	var kind := filter()
	var jar := input("jar")
	var total := jar + through
	# The jar's water: what it had, and what came through now with what the filter lets pass.
	for id: String in ["soil", "colour", "smell", "germs"]:
		var passed: float = {"soil": soil_pass(kind), "colour": colour_pass(kind), "smell": colour_pass(kind), "germs": germ_pass(kind)}[id]
		set_input(id, (input(id) * jar + passed * through) / total)
	set_input("jar", total)


func _step_fire(dt: float) -> void:
	var fire := input("fire") * exp(-dt / FIRE_FADE_S)
	set_input("fire", 0.0 if fire < REST else fire)
	var target := ROOM_C + input("fire") * (FLAME_C - ROOM_C)
	var water := input("water")
	var lag := POT_UP_S if target > water else POT_DOWN_S
	water = minf(BOIL_C, target + (water - target) * exp(-dt / lag))
	if absf(water - ROOM_C) < 0.05 and not fire_on():
		water = ROOM_C
	set_input("water", water)
	if boiling():
		set_input("pot_germs", maxf(0.0, input("pot_germs") - dt / KILL_S))


# --- the result -----------------------------------------------------------------------------------

func jar_has() -> bool:
	return input("jar") >= ENOUGH


## The judged result is in (or the run has come to its miss): enough came through and nothing is on its
## way, or the pour stopped short; the germs are gone, or the fire died before.
func decided() -> bool:
	return status() in ["muddy", "filtered", "clear", "little", "boiled", "unboiled"]


func status() -> String:
	if not touched():
		return "ready"
	if boiling_site():
		if input("pot_germs") <= 0.0:
			return "boiled"
		if fire_on() or boiling():
			return "heating"
		return "unboiled"
	if pouring() or input("column") > DRAINED:
		return "pouring"
	if not jar_has():
		return "little" if input("kettle") < 1.0 else "ready"
	if input("soil") > MUDDY:
		return "muddy"
	if input("colour") > COLOURED:
		return "filtered"
	return "clear"
