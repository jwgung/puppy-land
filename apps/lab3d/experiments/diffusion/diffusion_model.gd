## The 퍼지는 냄새와 잉크 spot's model (#156, 2026-11-15; Curie Island's first spot,
## docs/islands/curie-missions.md 1): a drop of ink spreading through a glass of water by itself, and
## the smell of fresh bread spreading through the air to Puppy's nose at the table's end.
##
## The rule the spot teaches (curie-lines.md 1): everything is made of tiny particles that never stop
## moving, so ink and smells spread out on their own (diffusion); they spread faster when it is warm,
## and much faster in air than in water (the particles of a gas are far apart).
## - A spreading front travels x = sqrt(4 D t) (the mean reach of a random walk, Einstein 1905), so a
##   cup of size L is coloured all through at t = L² / (4 D) (full_time()).
## - In water D follows Stokes–Einstein, D ∝ T / η(T), with water's viscosity η from the Vogel
##   equation η = A·10^(B / (T − C)) (A = 2.414e-5 Pa·s, B = 247.8 K, C = 140 K): D_INK at 20 °C,
##   about 2.7 times as fast in hot water (50 °C, 2026-11-16 user: 80 °C was "too fast") (HOT_C) as in cold (COLD_C).
## - In air D grows as T^1.75 (Fuller's correlation); a smell's D is about ten thousand times an ink's
##   in water, so it crosses NOSE_PATH (the table to Puppy's nose) before the ink fills a small cup.
## - The real times are days for the cup (a still glass, no stirring, no warm currents) and hours for
##   the room; the lab shows them PLAYBACK times faster (one number for all three, so the order and the
##   ratios are the textbook's): the cold cup fills in COLD_FULL_S of play.
##
## Inputs: "water" (0 cold, 1 hot: the condition), "site" (the stage's table: SINGLE one cup, PAIR the
## cup and a cold cup beside it to compare, BREAD the cup and the bread whose smell goes to Puppy),
## "dropped" (0 / 1: the drop is in) and "time" (play seconds since the drop). A press on the dropper
## (drop()) starts the run over with a new drop; the time runs until everything on the table has
## spread (animating()).
##
## Its status names what the stages judge: "ready" (no drop yet), "spreading" (the thing judged is still
## on its way), "full" (the cup is coloured all through; on the PAIR table both cups at once: the same
## water), "faster" (PAIR: the cup filled before the cold cup beside it), "smell" (BREAD: the smell
## reached Puppy's nose). No number is shown: the lab draws ink dots and smell puffs ("자세히" has the
## graph with units).
class_name DiffusionModel
extends EarthModel

const SINGLE := 0.0
const PAIR := 1.0
const BREAD := 2.0
## The waters' temperatures (°C) and the room's (the air, the reference).
const COLD_C := 10.0
const HOT_C := 50.0
const ROOM_C := 20.0
const KELVIN := 273.15
## Water's viscosity (Vogel): η = VOGEL_A · 10^(VOGEL_B / (T − VOGEL_C)), T in K, η in Pa·s.
const VOGEL_A := 2.414e-5
const VOGEL_B := 247.8
const VOGEL_C := 140.0
## Diffusion coefficients at ROOM_C (m²/s): a small dye in water, a small smell in air.
const D_INK := 1.0e-9
const D_SMELL := 1.0e-5
## Fuller's exponent of a gas's D in T.
const GAS_EXPONENT := 1.75
## How far each spreads to be "there" (m): across the cup, from the bread to Puppy's nose.
const CUP_SIZE := 0.08
const NOSE_PATH := 3.5
## Play seconds the cold cup takes to colour all through (sets PLAYBACK).
const COLD_FULL_S := 9.0
## The judged run counts as settled (Puppy's "wait" hint) once it has spread this long without its result.
const HINT_S := 1.0


func _init() -> void:
	define_input("water", 0.0)
	define_input("site", SINGLE)
	define_input("dropped", 0.0)
	define_input("time", 0.0)


## Water's viscosity (Pa·s) at `celsius` (Vogel's equation).
static func viscosity(celsius: float) -> float:
	return VOGEL_A * pow(10.0, VOGEL_B / (celsius + KELVIN - VOGEL_C))


## The ink's diffusion coefficient (m²/s) in water at `celsius` (Stokes–Einstein: D ∝ T / η).
static func ink_d(celsius: float) -> float:
	return D_INK * (celsius + KELVIN) / (ROOM_C + KELVIN) * viscosity(ROOM_C) / viscosity(celsius)


## The smell's diffusion coefficient (m²/s) in air at `celsius` (Fuller: D ∝ T^1.75).
static func smell_d(celsius: float) -> float:
	return D_SMELL * pow((celsius + KELVIN) / (ROOM_C + KELVIN), GAS_EXPONENT)


## The real seconds a front takes to cover `distance` m with diffusion coefficient `d` (x² = 4 D t).
static func real_time(distance: float, d: float) -> float:
	return distance * distance / (4.0 * d)


## Play seconds per real second (the cold cup's real time shown in COLD_FULL_S).
static func playback() -> float:
	return COLD_FULL_S / real_time(CUP_SIZE, ink_d(COLD_C))


## Play seconds until a cup of water at `celsius` is coloured all through.
static func full_time(celsius: float) -> float:
	return real_time(CUP_SIZE, ink_d(celsius)) * playback()


## Play seconds until the bread's smell reaches Puppy's nose (the room's air).
static func smell_time() -> float:
	return real_time(NOSE_PATH, smell_d(ROOM_C)) * playback()


## The share (0..1) of the way a front with full time `full_s` has gone after `t` play seconds.
static func reach(t: float, full_s: float) -> float:
	return clampf(sqrt(maxf(t, 0.0) / full_s), 0.0, 1.0)


## The condition: cold (false) or hot water (true), kept across reset().
func set_hot(hot: bool) -> void:
	set_start("water", 1.0 if hot else 0.0)


func is_hot() -> bool:
	return input("water") > 0.5


## The stage's table (SINGLE, PAIR or BREAD), kept across reset().
func set_site(site: float) -> void:
	set_start("site", site)


func site() -> float:
	return input("site")


## A new drop: the run starts over with the drop in the cup (and, on the BREAD table, the bread's
## smell let out at the same moment).
func drop() -> void:
	reset()
	set_input("dropped", 1.0)


func dropped() -> bool:
	return input("dropped") > 0.5


## The cup's water temperature (°C).
func water_c() -> float:
	return HOT_C if is_hot() else COLD_C


## How far the ink has spread through the cup (0..1), through the cold cup beside it (PAIR), and the
## smell along its way to the nose (BREAD).
func ink() -> float:
	return reach(input("time"), full_time(water_c())) if dropped() else 0.0


func beside() -> float:
	return reach(input("time"), full_time(COLD_C)) if dropped() else 0.0


func smell() -> float:
	return reach(input("time"), smell_time()) if dropped() else 0.0


## Play seconds until everything on the table has spread (the run's end).
func end_time() -> float:
	var t := full_time(water_c())
	if site() == PAIR:
		t = maxf(t, full_time(COLD_C))
	elif site() == BREAD:
		t = maxf(t, smell_time())
	return t


## Play seconds until the thing the stage judges is there (the cup full; on the BREAD table the smell
## at the nose).
func decide_time() -> float:
	return smell_time() if site() == BREAD else full_time(water_c())


## The judged result is in (or the run has spread long enough to tell Puppy's hint).
func decided() -> bool:
	return dropped() and input("time") >= minf(decide_time(), HINT_S)


func animating() -> bool:
	return dropped() and input("time") < end_time()


func step(dt: float) -> void:
	set_input("time", minf(input("time") + dt, end_time()))


func status() -> String:
	if not dropped():
		return "ready"
	var t := input("time")
	if site() == BREAD:
		return "smell" if t >= smell_time() else "spreading"
	var own := full_time(water_c())
	if t < own:
		return "spreading"
	if site() == PAIR and own < full_time(COLD_C):
		return "faster"
	return "full"
