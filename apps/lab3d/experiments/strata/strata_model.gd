## The 지층 쌓기 spot's model (#96, 2026-11-07; docs/islands/hutton-missions.md 9): no formula, a rule
## (docs/islands/hutton.md "시뮬레이션": "아래 층이 먼저 쌓임"). The child pours buckets of gravel, sand,
## mud or grey ash into the water tank and drops a shell in; each pour settles to the bottom of the
## water and lies on what is already there, so the first pour ends up at the bottom (layers(): bottom
## first, in the order poured). A shell lies on the top of the pile when it is dropped and the next
## pour buries it: it is in the layer poured after it (shell_layer()). In the third stage the child
## taps a layer of the cliff to dig it (dig()): the cliff's layers are CLIFF, bottom first, and the
## piece is in the layer just under the grey ash (TARGET).
##
## Its status is the last thing the hand did:
## - the tank (tank_status()): "ready" (nothing in it), "stacking" (gravel, then sand, so far, the shell
##   where it can still end up in the middle), "layered" (gravel, sand, mud, no shell), "fossil" (gravel,
##   sand, mud with the shell in the sand, the middle layer), "mixed" (a layer out of that order, the
##   ash too), "shell_off" (the shell where it cannot end up in the middle: on the bare bottom, on the
##   sand or on the whole pile);
## - the cliff: "found" (the layer under the ash dug), "dug_off" (another layer).
## A tank that is done ("layered", "fossil") or wrong ("mixed", "shell_off") is washed out by the next
## pour or shell: the new one starts a new pile (no 다시 needed to try again).
## The inputs only animate: "settle" (the newest pour or shell sinking to its place, 0..1) and "dig"
## (the newest dent opening, 0..1). Nothing is a number on the screen.
class_name StrataModel
extends EarthModel

const GRAVEL := "gravel"
const SAND := "sand"
const MUD := "mud"
const ASH := "ash"
## The buckets (also the manipulation object ids).
const MATERIALS := [GRAVEL, SAND, MUD, ASH]
## The pile the first two stages ask for, bottom first (hutton-missions.md 9: 자갈 → 모래 → 진흙).
const ORDER := [GRAVEL, SAND, MUD]
## The shell's place in that pile: the middle layer (index, bottom first).
const SHELL_LAYER := 1
## The cliff's layers, bottom first: the grey ash under the top layer, the piece in the layer just under
## it (TARGET).
const CLIFF := [GRAVEL, SAND, MUD, ASH, SAND]
const TARGET := 2
## How long a pour takes to settle and a dent to open (s).
const SETTLE_S := 1.2
const DIG_S := 0.6
const FINISHED := ["layered", "fossil", "mixed", "shell_off"]

var _layers: Array[String] = []
## The layers under the shell when it was dropped (-1: no shell in the tank).
var _shell_at := -1
## What the newest action added ("" none, a material, "shell").
var newest := ""
## The cliff's dug layers (index -> true) and the last one.
var dug := {}
var last_dig := -1
## "tank" or "cliff": where the last action was ("" none since the start).
var _last := ""


func _init() -> void:
	define_input("settle", 1.0, 1.0 / SETTLE_S)
	define_input("dig", 1.0, 1.0 / DIG_S)


func reset() -> void:
	super()
	_layers.clear()
	_shell_at = -1
	newest = ""
	dug.clear()
	last_dig = -1
	_last = ""


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


## Digs cliff layer `index` (bottom first).
func dig(index: int) -> void:
	if index < 0 or index >= CLIFF.size():
		return
	dug[index] = true
	last_dig = index
	_last = "cliff"
	set_input("dig", 0.0)
	glide_to("dig", 1.0)


func _added(what: String) -> void:
	newest = what
	_last = "tank"
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
		if i >= ORDER.size() or _layers[i] != ORDER[i]:
			return "mixed"
	if _shell_at >= 0 and _shell_at != SHELL_LAYER:
		return "shell_off"
	if _layers.size() < ORDER.size():
		return "stacking"
	return "fossil" if _shell_at == SHELL_LAYER else "layered"


## The last action's result: the tank's, or the cliff's "found" / "dug_off".
func status() -> String:
	if _last == "cliff":
		return "found" if last_dig == TARGET else "dug_off"
	return tank_status()


## The piece's layer was dug.
func found() -> bool:
	return dug.has(TARGET)
