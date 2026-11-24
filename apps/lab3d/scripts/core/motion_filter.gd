## The body-motion filter (#160, 2026-11-18; the Curie Island spring village's "몸으로 하는 조작", the
## approved mockup's "센서 입력 층"): pure arithmetic on the device's accelerometer samples, no node and no
## engine call, so the tests feed it sample by sample. MotionInput (scripts/shell) is its thin adapter.
##
## Only the accelerometer (the SM-P200 has no gyroscope, no magnetometer and no fused gravity sensor):
## - gravity: a low-pass filter (time constant LOWPASS_S, per sample interval `dt`, so devices with other
##   sample rates behave the same) estimates the gravity vector from the samples;
## - the left-right tilt: the angle of that estimate across the screen (asin of its x share), measured from
##   the rest pose taken when a stage starts (rest(): lying down or on a lap is 0 as well). Below DEAD_DEG it
##   counts as still (hand tremor); the tilt value grows from there to 1 at FULL_DEG and stays 1 beyond
##   (tilting further changes nothing). tilting() turns on past DEAD_DEG and off below DEAD_DEG - RETURN_DEG;
## - a shake: what is left once the gravity estimate is taken off (the high-pass part) passes SHAKE_G for
##   SHAKE_SAMPLES samples in a row: one shake, then nothing for COOLDOWN_S (shaking harder or longer gives
##   no more). A shake past HARD_G is reported as hard (the lab may say "살살");
## - no sensor: the samples stay exactly zero for NO_SENSOR_S (a desktop, the web, a headless run).
##
## Units: m/s² (Android, Input.get_accelerometer). Godot's Android input already turns the axes with the
## screen's rotation (GodotInputHandler.onSensorChanged), so x is the screen's right in landscape and in
## upside-down landscape alike. Godot hands the vector pointing down (the SM-P200 on its stand, upright in
## landscape: about (0, -8.2, -5.0), 2026-11-18 adb logcat), so tilting the screen's left edge down gives a
## negative x; the angle and tilt() count that way as positive.
class_name MotionFilter
extends RefCounted

const G := 9.80665
## The low-pass time constant (s): the gravity estimate.
const LOWPASS_S := 0.12
## The still band, where the tilt is full, and the way back before "tilting" turns off (deg).
const DEAD_DEG := 4.0
const FULL_DEG := 20.0
const RETURN_DEG := 2.0
## A shake: the high-pass part over this (in g) for this many samples in a row; then none for COOLDOWN_S.
const SHAKE_G := 0.25
const SHAKE_SAMPLES := 2
const COOLDOWN_S := 0.5
## A shake this strong (g) is a hard one.
const HARD_G := 1.5
## Exactly zero samples for this long (s): there is no sensor.
const NO_SENSOR_S := 1.0

enum Sensor { UNKNOWN, PRESENT, ABSENT }

var sensor := Sensor.UNKNOWN
## The gravity estimate (m/s², device axes) and whether it has a first sample.
var gravity := Vector3.ZERO
## The rest pose's angle (deg); NAN until a sample takes it.
var rest_deg := NAN
## Shakes so far (tests).
var shakes := 0
var _started := false
var _zero_s := 0.0
var _over := 0
var _peak := 0.0
var _cooldown := 0.0
var _tilting := false


## One sample `accel` (m/s²) `dt` s after the last. Returns "" or, when this sample completes a shake,
## "shake" / "hard".
func feed(accel: Vector3, dt: float) -> String:
	_cooldown = maxf(0.0, _cooldown - dt)
	if accel == Vector3.ZERO:
		_zero_s += dt
		if sensor == Sensor.UNKNOWN and _zero_s >= NO_SENSOR_S:
			sensor = Sensor.ABSENT
		return ""
	_zero_s = 0.0
	sensor = Sensor.PRESENT
	if not _started:
		_started = true
		gravity = accel
	else:
		gravity += (accel - gravity) * (1.0 - exp(-maxf(dt, 0.0) / LOWPASS_S))
	if is_nan(rest_deg):
		rest_deg = angle_deg()
	var rel := absf(relative_deg())
	if rel > DEAD_DEG:
		_tilting = true
	elif rel < DEAD_DEG - RETURN_DEG:
		_tilting = false
	return _shake((accel - gravity).length() / G)


func _shake(high_g: float) -> String:
	if high_g < SHAKE_G:
		_over = 0
		_peak = 0.0
		return ""
	_over += 1
	_peak = maxf(_peak, high_g)
	if _over < SHAKE_SAMPLES or _cooldown > 0.0:
		return ""
	var hard := _peak >= HARD_G
	_over = 0
	_peak = 0.0
	_cooldown = COOLDOWN_S
	shakes += 1
	return "hard" if hard else "shake"


## The rest pose is the pose now (a stage starts, the screen turned): the tilt counts from here.
func rest() -> void:
	rest_deg = angle_deg() if _started else NAN
	_tilting = false


## Forget everything (the screen turned: the old estimate is in the old axes).
func clear() -> void:
	_started = false
	gravity = Vector3.ZERO
	rest_deg = NAN
	_tilting = false
	_over = 0
	_peak = 0.0


## The gravity estimate's angle across the screen (deg, + the left edge down).
func angle_deg() -> float:
	var length := gravity.length()
	if length <= 0.0:
		return 0.0
	return rad_to_deg(asin(clampf(-gravity.x / length, -1.0, 1.0)))


## The angle from the rest pose (deg).
func relative_deg() -> float:
	return 0.0 if is_nan(rest_deg) else angle_deg() - rest_deg


## The tilt (-1..1): 0 inside the still band, 1 (or -1) from FULL_DEG on, the left edge down positive.
func tilt() -> float:
	return tilt_of(relative_deg())


## The tilt value of an angle `degrees` from rest.
static func tilt_of(degrees: float) -> float:
	var a := absf(degrees)
	if a <= DEAD_DEG:
		return 0.0
	return signf(degrees) * clampf((a - DEAD_DEG) / (FULL_DEG - DEAD_DEG), 0.0, 1.0)


## The device is being tilted (past the still band; off again a little inside it).
func tilting() -> bool:
	return _tilting


func present() -> bool:
	return sensor == Sensor.PRESENT


func absent() -> bool:
	return sensor == Sensor.ABSENT
