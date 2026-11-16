## The 녹으면 사라질까? spot's model (#157, 2026-11-17; Curie Island's second spot,
## docs/islands/curie-missions.md 2 and curie-lines.md 2): a spoonful of salt stirred into a glass of
## water, the same on a scale, and seawater left to dry on a sunny tray.
##
## The rule the spot teaches: dissolved salt is not gone. It spreads through the water too finely to
## see, so the water clears; the weight stays the same; and when the water goes off into the air the
## salt is left behind (the island makes salt from the sea now that the ships do not come).
## - A spoonful (SPOON_G) dissolves as it is stirred: each turn of the spoon dissolves 1 / STIR_TURNS of
##   it (a rule, not a rate law), never more than water holds (solubility: SOLUBILITY g per 100 g of
##   water at 20 °C, so a spoonful in a glass all dissolves, while 100 g would not: dissolvable()).
## - Mass is conserved: the scale reads the glass, the water, the salt still at the bottom and the salt
##   in the water (and the empty salt dish); it reads the same before and after (scale_g()).
## - Seawater is SALINITY salt by mass. Poured on the tray it is DEPTH_MM deep; the sun takes
##   EVAPORATION_MM off it in a day's sunshine (only by day: FastClock.sunshine). The salt stays: it comes
##   out of the water as crystals once the water left cannot hold it (crust()), so the white crust shows
##   near the end and all the salt is there when the tray is dry (2 nights and a morning: the stamps).
##
## Inputs: "site" (the stage's table: CUP the glass, SCALE the glass and the dish on the scale, TRAY the
## sun tray and the seawater bucket), "stir" (turns of the spoon round the glass since the run began),
## "poured" (0 / 1: the seawater is on the tray). The time is the model's FastClock (`clock`: days since
## the pour, stepped while it runs; it stops by itself when the tray is dry).
##
## Its status names what the stages judge: CUP / SCALE "bottom" (salt at the bottom, not stirred yet),
## "dissolving" (some of it dissolved), "clear" (CUP: all dissolved) or "same" (SCALE: all dissolved, the
## scale where it was); TRAY "ready" (not poured), "drying" (water on the tray), "salt" (dry: the salt
## and the piece). No number is shown: the lab draws the salt, the needle, the water and the crust.
class_name DissolvingModel
extends EarthModel

const CUP := 0.0
const SCALE := 1.0
const TRAY := 2.0
## The glass of water and the spoonful (g); the empty glass and the dish (g: the scale's reading).
const WATER_G := 200.0
const SPOON_G := 6.0
const GLASS_G := 250.0
const DISH_G := 80.0
## Sodium chloride's solubility at 20 °C (g per 100 g of water; CRC Handbook 36.0, textbook 35.9).
const SOLUBILITY := 35.9
## Turns of the spoon that dissolve a spoonful.
const STIR_TURNS := 3.0
## Seawater: its salt by mass (3.5 %, about 35 g in a kilogram), the tray's seawater (g) and depth (mm),
## the sun's evaporation from a shallow dark tray in one day's sunshine (mm; a sunny summer day 5 to 8:
## a day's sunshine is the day half of the sign's sweep, FastClock.DUSK days).
const SALINITY := 0.035
const SEA_G := 1000.0
const DEPTH_MM := 15.0
const EVAPORATION_MM := 6.0
## The judged run counts as settled (Puppy's "wait" line can come) once the time has run this long
## (days) without the tray drying.
const HINT_DAYS := 0.3
## Play seconds of one day on the time sign.
const DAY_S := 4.0

var clock := FastClock.new()


func _init() -> void:
	clock.day_s = DAY_S
	define_input("site", CUP)
	define_input("stir", 0.0)
	define_input("poured", 0.0)


## The stage's table (CUP, SCALE or TRAY), kept across reset().
func set_site(site: float) -> void:
	set_start("site", site)


func site() -> float:
	return input("site")


## The salt (g) `water_g` of water at 20 °C can hold.
static func holds(water_g: float) -> float:
	return SOLUBILITY * water_g / 100.0


## How much of `salt_g` dissolves in `water_g` of water at 20 °C (the rest stays at the bottom).
static func dissolvable(salt_g: float, water_g: float) -> float:
	return minf(salt_g, holds(water_g))


# --- the glass --------------------------------------------------------------------------------------

## The spoon went round the glass `turns` more times (only the glass's salt is stirred: not on the tray).
func stir(turns: float) -> void:
	if site() != TRAY and turns > 0.0:
		set_input("stir", input("stir") + turns)


## The salt dissolved in the glass (g).
func dissolved_g() -> float:
	return minf(SPOON_G * clampf(input("stir") / STIR_TURNS, 0.0, 1.0), dissolvable(SPOON_G, WATER_G))


## The salt still at the bottom of the glass (g).
func bottom_g() -> float:
	return SPOON_G - dissolved_g()


## The share (0..1) of the spoonful dissolved.
func dissolved_share() -> float:
	return dissolved_g() / SPOON_G


## All the spoonful is dissolved (the water is clear).
func all_dissolved() -> bool:
	return bottom_g() <= 1e-9


## The scale's reading (g): the glass, its water, the salt at the bottom and in the water, the empty dish.
func scale_g() -> float:
	return GLASS_G + WATER_G + bottom_g() + dissolved_g() + DISH_G


## The reading before any stirring (the ghost needle).
static func before_g() -> float:
	return GLASS_G + WATER_G + SPOON_G + DISH_G


# --- the tray ---------------------------------------------------------------------------------------

## The seawater goes on the tray: the time flows (until the tray is dry).
func pour() -> void:
	if site() != TRAY or poured():
		return
	set_input("poured", 1.0)
	clock.until = dry_days()
	clock.start()


func poured() -> bool:
	return input("poured") > 0.5


## Days from the pour until the tray is dry (its depth taken off by the sun, by day only).
static func dry_days() -> float:
	return FastClock.days_for_sunshine(DEPTH_MM / EVAPORATION_MM * FastClock.DUSK)


## The water's depth on the tray now (mm; 0 before the pour).
func water_mm() -> float:
	if not poured():
		return 0.0
	return maxf(0.0, DEPTH_MM - EVAPORATION_MM * FastClock.sunshine(0.0, clock.days) / FastClock.DUSK)


## The water left on the tray as a share of the poured (0..1).
func water_share() -> float:
	return water_mm() / DEPTH_MM


## The water (g) on the tray now, and the salt (g) in all (it never leaves).
func water_g() -> float:
	return SEA_G * (1.0 - SALINITY) * water_share()


static func sea_salt_g() -> float:
	return SEA_G * SALINITY


## The salt come out as crystals (g): what the water left cannot hold.
func crystal_g() -> float:
	if not poured():
		return 0.0
	return maxf(0.0, sea_salt_g() - holds(water_g()))


## The white crust's share (0..1) of all the salt.
func crust() -> float:
	return crystal_g() / sea_salt_g()


func dry() -> bool:
	return poured() and water_mm() <= 1e-9


# --- the run ----------------------------------------------------------------------------------------

## Every input back to its start and the clock to the first morning (the site stays).
func reset() -> void:
	super()
	clock.reset()


func animating() -> bool:
	return super() or clock.running


func step(dt: float) -> void:
	super(dt)
	clock.advance(dt)


## The judged result is in, or the time has run long enough to tell Puppy's "wait" line.
func decided() -> bool:
	if site() == TRAY:
		return poured() and (dry() or clock.days >= HINT_DAYS)
	return true


func status() -> String:
	if site() == TRAY:
		if not poured():
			return "ready"
		return "salt" if dry() else "drying"
	if input("stir") <= 0.0:
		return "bottom"
	if not all_dissolved():
		return "dissolving"
	if site() == SCALE:
		return "same" if absf(scale_g() - before_g()) < 1e-9 else "dissolving"
	return "clear"
