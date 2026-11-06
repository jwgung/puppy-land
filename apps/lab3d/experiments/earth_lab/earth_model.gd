## The model of an earth lab (#70, 2026-11-06; Hutton Island, docs/islands/hutton.md "시뮬레이션"): the
## state the lab draws and the mission round reads. No node, no engine body, no clock of its own: the
## lab (EarthLab) steps it at the fixed step while it is animating and draws it after.
##
## A model is a few named inputs (numbers, 64-bit) and what follows from them. An input is set at
## once (set_input: a finger on the lab's knob, a condition) or glides to a target at its rate
## (glide_to: the lab shows the change happen; the model is animating until every glide arrived).
## reset() puts every input back to its start value (set_start: the conditions keep theirs).
## A subclass declares its inputs in _init() (define_input) and answers status() and observations()
## from them; both are pure functions of the inputs, so the same inputs read the same numbers.
class_name EarthModel
extends RefCounted

## A glide this close to its target (in the input's unit) has arrived.
const ARRIVED := 1e-9

## id -> current value.
var _values := {}
## id -> start value (reset() returns here).
var _starts := {}
## id -> glide rate (units per second; 0 = the input never glides, glide_to sets it at once).
var _rates := {}
## id -> period of a wrapping input (360 for an angle: kept in [0, period), a glide takes the shorter
## way round); 0 = no wrap.
var _periods := {}
## id -> target of a glide under way.
var _targets := {}


## Declares input `id` at `start` (also its value now), gliding at `rate` units/s, wrapping at `period`.
func define_input(id: String, start: float, rate := 0.0, period := 0.0) -> void:
	_periods[id] = period
	_rates[id] = rate
	_starts[id] = _wrapped(id, start)
	_values[id] = _starts[id]


func has_input(id: String) -> bool:
	return _values.has(id)


## The value of input `id` now.
func input(id: String) -> float:
	return float(_values.get(id, 0.0))


## The start value of input `id` (where reset() puts it).
func start_of(id: String) -> float:
	return float(_starts.get(id, 0.0))


## Sets input `id` now (a glide on it stops).
func set_input(id: String, value: float) -> void:
	if not has_input(id):
		push_error("EarthModel: no input '%s'" % id)
		return
	_targets.erase(id)
	_values[id] = _wrapped(id, value)


## Sets input `id` and its start value (a condition: it stays across reset()).
func set_start(id: String, value: float) -> void:
	set_input(id, value)
	if has_input(id):
		_starts[id] = _values[id]


## Input `id` moves to `value` at its rate from the next step (at once when its rate is 0).
func glide_to(id: String, value: float) -> void:
	if not has_input(id):
		push_error("EarthModel: no input '%s'" % id)
		return
	if float(_rates[id]) <= 0.0:
		set_input(id, value)
		return
	_targets[id] = _wrapped(id, value)
	if absf(_gap(id)) <= ARRIVED:
		set_input(id, value)


## A glide is under way.
func animating() -> bool:
	return not _targets.is_empty()


## One step of `dt` seconds: every glide moves its rate * dt towards its target (the last step lands
## on it exactly).
func step(dt: float) -> void:
	for id in _targets.keys():
		var gap := _gap(id)
		var most: float = float(_rates[id]) * dt
		if absf(gap) <= most + ARRIVED:
			_values[id] = _targets[id]
			_targets.erase(id)
		else:
			_values[id] = _wrapped(id, input(id) + signf(gap) * most)


## Every input back to its start value, no glide.
func reset() -> void:
	_targets.clear()
	for id in _starts:
		_values[id] = _starts[id]


## The state that names the panels' texts and the stages' judge_on (the lab's status()).
func status() -> String:
	return ""


## Observation id -> number (or String) of the inputs now (the lab's observations()).
func observations() -> Dictionary:
	return {}


## The signed way from the value to the target of input `id` (the shorter way round when it wraps).
func _gap(id: String) -> float:
	var gap: float = float(_targets[id]) - input(id)
	var period: float = _periods[id]
	if period > 0.0:
		gap = fposmod(gap + period * 0.5, period) - period * 0.5
	return gap


func _wrapped(id: String, value: float) -> float:
	var period: float = _periods.get(id, 0.0)
	return fposmod(value, period) if period > 0.0 else value
