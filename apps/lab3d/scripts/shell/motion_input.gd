## The lab's body-motion input (#160, 2026-11-18; the mockup's "센서 입력 층"): a lab that is played by
## tilting or shaking the tablet owns one of these and reads only it, never the sensor. Three sources end in
## the same values, so the judging and the tests do not care which one it was:
## - "sensor": Input.get_accelerometer() every physics frame through MotionFilter (the project turns on the
##   accelerometer only: input_devices/sensors/enable_accelerometer; no permission, nothing stored, nothing
##   leaves the device);
## - "touch": the lab's touch stand-in (a handle dragged down, a bottle tapped) writes the same tilt or shake
##   (set_touch_tilt, end_touch, touch_shake); while a finger tilts, the sensor's tilt is not read;
## - "test": inject_accel (a sample, through the filter), inject_tilt, inject_shake: the real sensor is not
##   read from then on.
## Debug builds: ← / → tilt fully, space shakes (desktop trying-out); --motion-log prints the samples
## (a device check through adb logcat). The screen turned upside down (window/handheld/orientation 4, sensor
## landscape) needs nothing here: Godot's Android input turns the axes with the display's rotation
## (GodotInputHandler.onSensorChanged, its cached rotation updated on every configuration change), so the
## samples stay in the screen's axes; DisplayServer.screen_get_orientation() only gives the project's
## setting (4) on the SM-P200, not the rotation.
class_name MotionInput
extends Node

## One shake (sensor, touch or test); `hard` past MotionFilter.HARD_G.
signal shaken(hard: bool)

var filter := MotionFilter.new()
## Where the last value came from: "sensor", "touch" or "test".
var source := "sensor"
## The touch stand-in's tilt (NAN: no finger on it).
var touch_tilt := NAN
## The test's tilt (NAN: none).
var test_tilt := NAN
## Off: tilt() is 0 and no shake is passed on (the dialogue is up; the lab's play is closed).
var enabled := true
var _testing := false
var _key_tilt := 0.0
var _space_down := false
## --motion-log (a device check: adb logcat): the raw sample, the angle and the tilt twice a second.
var _log := false
var _log_left := 0.0


func _init() -> void:
	name = "MotionInput"
	_log = "--motion-log" in load("res://scripts/core/quality.gd").all_args()   # (loaded: the autoload's name is not there under -s)


func _physics_process(delta: float) -> void:
	if _testing:
		return
	var accel := Input.get_accelerometer()
	_feed(accel, delta, "sensor")
	_keys()
	if _log:
		_log_left -= delta
		if _log_left <= 0.0:
			_log_left = 0.5
			print("motion: accel %s angle %.1f rest %.1f tilt %.2f sensor %d" % [accel, filter.angle_deg(), filter.rest_deg, tilt(), filter.sensor])


## The tilt now (-1..1, the left edge down positive): the touch stand-in's while a finger is on it, else the
## test's, else the sensor's (or the debug keys').
func tilt() -> float:
	if not enabled:
		return 0.0
	if not is_nan(touch_tilt):
		return touch_tilt
	if not is_nan(test_tilt):
		return test_tilt
	if _key_tilt != 0.0:
		return _key_tilt
	return filter.tilt()


## The child is acting through the tablet now (tilted past the still band, or a finger on the stand-in).
func active() -> bool:
	return enabled and (not is_nan(touch_tilt) or absf(tilt()) > 0.0 or filter.tilting())


## The tablet has a sensor that sends values (the stand-in is shown anyway).
func has_sensor() -> bool:
	return filter.present()


## Nothing came for MotionFilter.NO_SENSOR_S: no sensor here.
func sensor_absent() -> bool:
	return filter.absent()


## The rest pose is the pose now (a stage or a run starts).
func rest() -> void:
	filter.rest()


# --- the touch stand-in ---------------------------------------------------------------------------

func set_touch_tilt(value: float) -> void:
	touch_tilt = clampf(value, -1.0, 1.0)
	source = "touch"


func end_touch() -> void:
	touch_tilt = NAN


func touch_shake() -> void:
	source = "touch"
	if enabled:
		shaken.emit(false)


# --- tests ----------------------------------------------------------------------------------------

## A sample through the filter (the real sensor is not read from now on).
func inject_accel(accel: Vector3, dt := 1.0 / 60.0) -> void:
	_testing = true
	_feed(accel, dt, "test")


func inject_tilt(value: float) -> void:
	_testing = true
	test_tilt = clampf(value, -1.0, 1.0)
	source = "test"


func clear_tilt() -> void:
	test_tilt = NAN


func inject_shake(hard := false) -> void:
	_testing = true
	source = "test"
	if enabled:
		shaken.emit(hard)


func _feed(accel: Vector3, dt: float, from: String) -> void:
	var shake := filter.feed(accel, dt)
	if accel != Vector3.ZERO:
		source = from
	if shake != "" and enabled:
		shaken.emit(shake == "hard")


func _keys() -> void:
	if not OS.is_debug_build() or DisplayServer.get_name() == "headless":
		return
	_key_tilt = (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0)
	var space := Input.is_key_pressed(KEY_SPACE)
	if space and not _space_down and enabled:
		shaken.emit(false)
	_space_down = space
