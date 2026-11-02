## Press-and-hold force (2026-10-28 user decision "손잡이 없이 물체에 직접"): while a finger holds the
## object, the applied force grows from 0 at `rate` N/s up to `cap` N; letting go puts it back to 0 at
## once. The force is counted in fixed steps (steps * rate / ticks per second, 64-bit), so the frame
## rate never changes it. The labs give force() to the formula models as the applied force they
## already take (PushFrictionModel.step, LeverLabModel.hand, PulleyLabModel.hand); the gauge beside
## the object shows fraction() (ForceGauge). Rates per lab: apps/lab3d/README.md "조작".
## Once the object starts to move (the box slides, the beam lifts, the rope comes down) the lab calls
## hold_there(): the force stays at that step's value until the finger lets go, so the gauge stops at
## the force it took (2026-11-01 user: "그 움직이기 시작하는 힘, 거기에서 게이지가 멈추게해줘").
class_name HoldRamp
extends RefCounted

var rate := 0.0     # N per second while held
var cap := 0.0      # N, the most the hold gives
var held := false
## Fixed steps since the hold began.
var steps := 0
var _held_at := -1.0   # N the force stays at (hold_there), < 0: still growing


func _init(rate_n_per_s := 0.0, cap_n := 0.0) -> void:
	rate = rate_n_per_s
	cap = cap_n


func start() -> void:
	held = true
	steps = 0
	_held_at = -1.0


func stop() -> void:
	held = false
	steps = 0
	_held_at = -1.0


## The object moved with this step's force: from now on the force stays there (no more growth).
func hold_there() -> void:
	if held and _held_at < 0.0:
		_held_at = force()


## The force has stopped growing (hold_there; tests read it).
func stopped() -> bool:
	return _held_at >= 0.0


## One fixed step (call it before reading force() in the step).
func tick() -> void:
	if held:
		steps += 1


## The applied force now (N): rate x held time, at most cap; 0 when not held.
func force() -> float:
	if not held:
		return 0.0
	if _held_at >= 0.0:
		return _held_at
	return minf(cap, rate * steps / float(Engine.physics_ticks_per_second))


## The gauge's fill (0..1 of cap).
func fraction() -> float:
	return force() / cap if cap > 0.0 else 0.0
