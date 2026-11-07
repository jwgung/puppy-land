## The 태풍·비구름 spot's model (#94, 2026-11-07; docs/islands/hutton-missions.md 7). There is no simple
## formula for a growing cloud, so this is the textbook's relation as a rule (docs/islands/hutton.md
## "시뮬레이션": "바다가 따뜻할수록 구름이 커짐"), checked by tests/typhoon_checks.gd:
## - A cloud over the sea takes the sea's water vapour: the warmer the sea, the more vapour, the faster
##   it grows and the bigger it gets. Each place has the strength the cloud goes to there (cap()):
##   a warm sea feeds a rain cloud (WARM_CAP, past RAIN), a very warm sea a typhoon (HOT_CAP, past
##   TYPHOON); a cold sea or land feeds nothing, and a cloud there loses its strength down to a small
##   cloud (SMALL). It grows at the sea's rate (WARM_RATE, HOT_RATE) and weakens at FADE_RATE.
## - The sea's temperature is the condition ("sea": COLD, WARM or HOT) for the open sea; the far strip
##   of the stage (z < COLD_Z) is always cold water (a cold current, with ice), the island is land.
##
## Inputs: "x", "z" (where the cloud is over the stage, m, world x / z: the child's hand), "sea" (the
## condition), "size" (the cloud's strength 0..1: it changes by itself, step()). Nothing is shown as a
## number (the user): the lab draws the strength as the cloud's look and names it in words.
##
## The cloud starts still (status "ready"); once a finger moves it, it grows or weakens towards its
## place's cap until it gets there (animating(): the lab steps the model, the round waits for it).
## The run's start is a small cloud on the island's beach, or (the last stage: start_storm) the big
## typhoon out at sea heading for the island.
## status(): "ready" (not moved yet), "typhoon" (size >= TYPHOON), "rain" (>= RAIN), "small"; a cloud
## that was a typhoon in this run and has lost its strength (< RAIN) is "calm" over cold water (the
## cold strip, or an open sea picked cold) and "landfall" over the island.
class_name TyphoonModel
extends EarthModel

## The sea conditions (the "sea" input).
const COLD := 0.0
const WARM := 1.0
const HOT := 2.0
## The cloud's strength: a small cloud, the rain cloud's and the typhoon's thresholds (0..1).
const SMALL := 0.15
const RAIN := 0.45
const TYPHOON := 0.85
## The strength a place feeds the cloud up to.
const WARM_CAP := 0.6
const HOT_CAP := 1.0
## How fast (strength per second) a warm and a very warm sea grow it, and how fast it weakens.
const WARM_RATE := 0.15
const HOT_RATE := 0.25
const FADE_RATE := 0.3
## The stage (world x / z, m): the round basin of sea (beyond it the shore: land), the cold strip far
## from the camera, the island on the right (an ellipse), and where the hand may carry the cloud.
const BASIN_CENTER := Vector2(0.0, -1.2)
const BASIN_RADIUS := 8.8
const COLD_Z := -2.6
const ISLAND_CENTER := Vector2(4.6, 0.6)
const ISLAND_RADII := Vector2(2.4, 1.8)
const REACH_MIN := Vector2(-7.0, -5.2)
const REACH_MAX := Vector2(7.0, 3.2)
## The starts: the small cloud on the island's beach; the typhoon out at sea (the last stage).
const CLOUD_START := Vector2(3.4, 1.0)
const STORM_START := Vector2(-4.6, -0.4)
## A change of strength this small has arrived.
const ARRIVED_SIZE := 1e-6

## The run starts from the typhoon at sea (the last stage) instead of the small cloud.
var storm_start := false
## A finger moved the cloud in this run (until then nothing changes by itself).
var _moved := false
## The cloud's highest strength in this run.
var _peak := SMALL


func _init() -> void:
	define_input("x", CLOUD_START.x)
	define_input("z", CLOUD_START.y)
	define_input("size", SMALL)
	define_input("sea", WARM)


## Starts the runs from the typhoon at sea (`on`) or the small cloud on the beach; the run now starts
## over from there.
func start_storm(on: bool) -> void:
	storm_start = on
	var at := STORM_START if on else CLOUD_START
	set_start("x", at.x)
	set_start("z", at.y)
	set_start("size", HOT_CAP if on else SMALL)
	reset()


## A finger's move (x, z) starts the cloud changing.
func set_input(id: String, value: float) -> void:
	super(id, value)
	if id == "x" or id == "z":
		_moved = true
	_peak = maxf(_peak, input("size"))


func reset() -> void:
	super()
	_moved = false
	_peak = input("size")


## A condition (the sea) starts the run over.
func set_start(id: String, value: float) -> void:
	super(id, value)
	reset()


func moved() -> bool:
	return _moved


func peak() -> float:
	return _peak


## What is under (x, z): "land" (the island, the shore past the basin), "cold" (the cold strip) or
## "sea" (the open sea).
static func place_at(x: float, z: float) -> String:
	if Vector2(x, z).distance_to(BASIN_CENTER) > BASIN_RADIUS:
		return "land"
	if z < COLD_Z:
		return "cold"
	var d := (Vector2(x, z) - ISLAND_CENTER) / ISLAND_RADII
	return "land" if d.length_squared() <= 1.0 else "sea"


## The water or land under the cloud: "cold", "warm", "hot" or "land" (the open sea is the condition).
func under() -> String:
	var place := place_at(input("x"), input("z"))
	if place != "sea":
		return place
	var sea := input("sea")
	return "cold" if sea < WARM - 0.5 else "warm" if sea < HOT - 0.5 else "hot"


## The strength `under` (cold, warm, hot, land) feeds a cloud up to.
static func cap_of(under_what: String) -> float:
	match under_what:
		"warm":
			return WARM_CAP
		"hot":
			return HOT_CAP
	return SMALL


## How fast (per second) `under` grows a cloud (0: it feeds nothing).
static func rate_of(under_what: String) -> float:
	match under_what:
		"warm":
			return WARM_RATE
		"hot":
			return HOT_RATE
	return 0.0


## The strength the cloud goes to where it is now.
func cap() -> float:
	return cap_of(under())


## Moved, and not yet at its place's strength.
func animating() -> bool:
	return _moved and absf(input("size") - cap()) > ARRIVED_SIZE


## One step of `dt` s: the cloud grows at its sea's rate up to the cap, or weakens at FADE_RATE down
## to it (a cloud past a warm sea's cap, carried over, weakens too).
func step(dt: float) -> void:
	if not _moved:
		return
	var size := input("size")
	var goal := cap()
	if size < goal:
		size = minf(goal, size + rate_of(under()) * dt)
	else:
		size = maxf(goal, size - FADE_RATE * dt)
	_values["size"] = size
	_peak = maxf(_peak, size)


## The cloud's look: "small", "rain" or "typhoon" by its strength, "weak" once a typhoon of this run
## has lost its strength.
func cloud() -> String:
	var size := input("size")
	if size >= TYPHOON:
		return "typhoon"
	if size >= RAIN:
		return "rain"
	return "weak" if _peak >= TYPHOON else "small"


func status() -> String:
	if not _moved:
		return "ready"
	var look := cloud()
	if look != "weak":
		return look
	return "landfall" if under() == "land" else "calm" if under() == "cold" else "small"


## How much water vapour rises under the cloud: "lots" (a very warm sea), "some" (a warm one) or
## "none" (cold water, land).
func vapor() -> String:
	return {"hot": "lots", "warm": "some"}.get(under(), "none")


## Words only (TyphoonLab names them): the cloud, what is under it, the vapour rising there.
func observations() -> Dictionary:
	return {"state": cloud(), "under": under(), "vapor": vapor()}
