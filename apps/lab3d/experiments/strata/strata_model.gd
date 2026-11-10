## The 지층 쌓기 spot's model (#96, 2026-11-07; docs/islands/hutton-missions.md 9): no formula, a rule
## (docs/islands/hutton.md "시뮬레이션": "아래 층이 먼저 쌓임"). The child pours buckets of gravel, sand,
## mud or grey ash into the water tank and drops a shell in; each pour settles to the bottom of the
## water and lies on what is already there, so the first pour ends up at the bottom (layers(): bottom
## first, in the order poured). A shell lies on the top of the pile when it is dropped and the next
## pour buries it: it is in the layer poured after it (shell_layer()). The pile asked for is `goal`:
## ORDER (stages 1 and 2: 자갈 → 모래 → 진흙) or, in the third stage, the cliff's own layers CLIFF
## (자갈 → 모래 → 회색 재 → 진흙, #114 2026-11-10: the stage goes on from the first two, the child copies
## the cliff in the tank and the piece shows in the cliff's layer just under the ash, TARGET).
##
## Its status (the tank's):
## - "ready" (nothing in it), "stacking" (the goal's first layers so far, the shell where it can still
##   end up in the middle), "mixed" (a layer out of the goal's order);
## - with the goal ORDER: "layered" (gravel, sand, mud, no shell), "fossil" (gravel, sand, mud with the
##   shell in the sand, the middle layer), "shell_off" (the shell where it cannot end up in the middle:
##   on the bare bottom, on the sand or on the whole pile);
## - with the goal CLIFF: "copied" (the cliff's layers, no shell), "shell_off" (a shell in it).
## A tank that is done or wrong (FINISHED) is washed out by the next pour or shell: the new one starts
## a new pile (no 다시 needed to try again).
## The input only animates: "settle" (the newest pour or shell sinking to its place, 0..1). Nothing is
## a number on the screen.
class_name StrataModel
extends EarthModel

const GRAVEL := "gravel"
const SAND := "sand"
const MUD := "mud"
const ASH := "ash"
## The buckets (also the manipulation object ids).
const MATERIALS := [GRAVEL, SAND, MUD, ASH]
## The pile the first two stages ask for, bottom first (hutton-missions.md 9: 자갈 → 모래 → 진흙).
const ORDER: Array[String] = [GRAVEL, SAND, MUD]
## The shell's place in that pile: the middle layer (index, bottom first).
const SHELL_LAYER := 1
## The cliff's layers, bottom first (the third stage's pile): the grey ash under the top layer, the
## piece in the layer just under it (TARGET).
const CLIFF: Array[String] = [GRAVEL, SAND, ASH, MUD]
const TARGET := 1
## How long a pour takes to settle (s).
const SETTLE_S := 1.2
const FINISHED := ["layered", "fossil", "copied", "mixed", "shell_off"]

## The pile asked for (ORDER or CLIFF; StrataLab sets it per stage).
var goal: Array[String] = ORDER

var _layers: Array[String] = []
## The layers under the shell when it was dropped (-1: no shell in the tank).
var _shell_at := -1
## What the newest action added ("" none, a material, "shell").
var newest := ""


func _init() -> void:
	define_input("settle", 1.0, 1.0 / SETTLE_S)


func reset() -> void:
	super()
	_layers.clear()
	_shell_at = -1
	newest = ""


## Pours `material` into the tank (a done or wrong pile is washed out first).
func pour(material: String) -> void:
	if not material in MATERIALS:
		push_error("StrataModel: no material '%s'" % material)
		return
	_wash_if_done()
	_layers.append(material)
	_added(material)


## Drops the shell into the tank: it lies on the pile's top (a done or wrong pile is washed out first).
func drop_shell() -> void:
	_wash_if_done()
	if _shell_at >= 0:
		return
	_shell_at = _layers.size()
	_added("shell")


func _added(what: String) -> void:
	newest = what
	set_input("settle", 0.0)
	glide_to("settle", 1.0)


func _wash_if_done() -> void:
	if tank_status() in FINISHED:
		_layers.clear()
		_shell_at = -1


## The tank's layers, bottom first (the order they were poured).
func layers() -> Array[String]:
	return _layers.duplicate()


## The shell is in the tank.
func has_shell() -> bool:
	return _shell_at >= 0


## The layers under the shell (where it lies; -1 no shell).
func shell_at() -> int:
	return _shell_at


## The layer the shell is buried in (index, bottom first), or -1 (no shell, or nothing on it yet).
func shell_layer() -> int:
	return _shell_at if _shell_at >= 0 and _shell_at < _layers.size() else -1


func tank_status() -> String:
	if _layers.is_empty() and _shell_at < 0:
		return "ready"
	for i in _layers.size():
		if i >= goal.size() or _layers[i] != goal[i]:
			return "mixed"
	var copying := goal == CLIFF
	if _shell_at >= 0 and (copying or _shell_at != SHELL_LAYER):
		return "shell_off"
	if _layers.size() < goal.size():
		return "stacking"
	if copying:
		return "copied"
	return "fossil" if _shell_at == SHELL_LAYER else "layered"


func status() -> String:
	return tank_status()
