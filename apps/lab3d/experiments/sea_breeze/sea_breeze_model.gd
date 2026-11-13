## The 바닷바람 spot's model (#93, 2026-11-07; docs/islands/hutton-missions.md 6): the land and the sea
## of a little coast, each with its own temperature (°C), and the wind between them.
##
## The rule the spot teaches (hutton-lines.md 6): land warms up and cools down faster than the sea;
## the wind blows from the cooler side to the warmer one, the stronger the bigger the difference.
## Each surface relaxes towards its target temperature as a first-order lag (Newton's law of heating
## and cooling, T += (target - T)(1 - e^(-dt/τ))), the land with a short time constant (LAND_TAU) and
## the sea with a long one (SEA_TAU: water stores much more heat for the same warming). The targets:
## - day, the sun pressed (the input "sun" 1): the land towards LAND_HOT, the sea towards SEA_WARM;
## - day, let go: the land back towards the sea's temperature (it cools: "떼면 식음"), the sea back
##   towards DAY_START;
## - night (the condition, the input "night" 1): no sun however long the finger presses; the land
##   towards LAND_NIGHT, the sea towards SEA_NIGHT. A night starts in the evening (EVENING_LAND,
##   EVENING_SEA: the land still a little warmer than the sea after the day) and the land cools past
##   the sea on its own in a few seconds ("땅이 식을 때까지 기다려 봐!").
## The wind (wind()) is WIND_PER_DEG m/s per °C of land minus sea: positive from the sea to the land
## (the sea breeze, 해풍), negative from the land to the sea (the land breeze, 육풍).
##
## Its status names what the stages judge: "calm" (the two within BREEZE_DIFF of each other),
## "sea_breeze" (the land BREEZE_DIFF or more warmer), "strong" (STRONG_DIFF or more warmer: a strong
## sea breeze), "land_breeze" (the land BREEZE_DIFF or more cooler). No temperature or wind speed is
## shown: the lab draws thermometers as bars and the wind as arrows (the user: no numbers on the
## screen; "자세히" has the graph with units).
class_name SeaBreezeModel
extends EarthModel

## Time constants (s) of the land's and the sea's lag: the land is about ten times quicker.
const LAND_TAU := 4.0
const SEA_TAU := 40.0
## The day's start: land and sea the same, no wind.
const DAY_START := 20.0
## The pressed sun's targets (°C).
const LAND_HOT := 36.0
const SEA_WARM := 23.0
## The night's start (the evening) and its targets (°C).
const EVENING_LAND := 23.0
const EVENING_SEA := 21.0
const LAND_NIGHT := 12.0
const SEA_NIGHT := 18.0
## Land minus sea (°C) of a breeze, and of a strong sea breeze.
const BREEZE_DIFF := 4.0
const STRONG_DIFF := 9.0
## m/s of wind per °C of difference (a 5 °C difference: a 3 m/s breeze; the strongest about 8 m/s).
const WIND_PER_DEG := 0.6
## A temperature this close to its target has arrived (the model stops stepping).
const SETTLED_DEG := 0.02
## The thermometers' range (°C): empty at COLDEST, full at HOTTEST.
const COLDEST := 8.0
const HOTTEST := 40.0


func _init() -> void:
	define_input("land", DAY_START)
	define_input("sea", DAY_START)
	define_input("night", 0.0)
	define_input("sun", 0.0)


## The day or the night (a condition: the start temperatures go with it and stay across reset()).
func set_night(night: bool) -> void:
	set_start("night", 1.0 if night else 0.0)
	set_start("land", EVENING_LAND if night else DAY_START)
	set_start("sea", EVENING_SEA if night else DAY_START)


func is_night() -> bool:
	return input("night") > 0.5


## The finger presses the sun (true) or let go (false). At night it warms nothing.
func set_sun(on: bool) -> void:
	set_input("sun", 1.0 if on else 0.0)


## The sun shines on the coast now (pressed, by day).
func heating() -> bool:
	return input("sun") > 0.5 and not is_night()


## The temperature the land and the sea are heading for now [land, sea].
func targets() -> Vector2:
	if is_night():
		return Vector2(LAND_NIGHT, SEA_NIGHT)
	if heating():
		return Vector2(LAND_HOT, SEA_WARM)
	return Vector2(input("sea"), DAY_START)


## Still changing: the sun shines, or the land or the sea is not at its target yet.
func animating() -> bool:
	if heating():
		return true
	var goal := targets()
	return absf(input("land") - goal.x) > SETTLED_DEG or absf(input("sea") - goal.y) > SETTLED_DEG


## One step of `dt` seconds of each surface's lag towards its target.
func step(dt: float) -> void:
	var goal := targets()
	var land := input("land")
	var sea := input("sea")
	set_input("land", land + (goal.x - land) * (1.0 - exp(-dt / LAND_TAU)))
	set_input("sea", sea + (goal.y - sea) * (1.0 - exp(-dt / SEA_TAU)))


## Land minus sea (°C).
func difference() -> float:
	return input("land") - input("sea")


## The wind (m/s): positive from the sea to the land, negative from the land to the sea.
func wind() -> float:
	return WIND_PER_DEG * difference()


## The wind's strength as a share of the strongest sea breeze (0..1).
func wind_share() -> float:
	return clampf(absf(difference()) / (LAND_HOT - DAY_START), 0.0, 1.0)


## A thermometer's fill for `temperature` (0..1 between COLDEST and HOTTEST).
static func fill_of(temperature: float) -> float:
	return clampf((temperature - COLDEST) / (HOTTEST - COLDEST), 0.0, 1.0)


func status() -> String:
	var d := difference()
	if d >= STRONG_DIFF:
		return "strong"
	if d >= BREEZE_DIFF:
		return "sea_breeze"
	if d <= -BREEZE_DIFF:
		return "land_breeze"
	return "calm"
