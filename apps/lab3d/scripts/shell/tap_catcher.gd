## A see-through layer that takes a tap where `wants` says so (2026-10-31 user: a child could not get
## past a dialogue box when tapping beside it). The screens put it over the 3D view, under their other
## overlays: while a box waits for a tap, a tap on the view turns its page (`on_tap`) instead of
## reaching the view; anywhere `wants` is false (no box, a press on a lab's object) the view gets
## the touch as before. It draws nothing.
class_name TapCatcher
extends Control

## (point: Vector2) -> bool: this point's tap is the catcher's now.
var wants: Callable
## () -> void: the tap.
var on_tap: Callable
## Taps taken so far (tests).
var taps := 0


func _init(wants_fn: Callable, on_tap_fn: Callable) -> void:
	name = "TapCatcher"
	wants = wants_fn
	on_tap = on_tap_fn
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)


## A finger's tap or a real left click (a touch's emulated click is not a second tap).
static func is_tap(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
			and event.device != InputEvent.DEVICE_ID_EMULATION)


func _has_point(point: Vector2) -> bool:
	return wants.is_valid() and bool(wants.call(point))


func _gui_input(event: InputEvent) -> void:
	if is_tap(event):
		taps += 1
		accept_event()
		on_tap.call()
	elif event is InputEventScreenTouch or event is InputEventMouseButton:
		accept_event()   # its lift: the view never sees half a touch
