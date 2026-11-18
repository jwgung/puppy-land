## The body-motion input (#160, 2026-11-18; the mockup "샘물 마을 몸 조작", 공통 "센서 입력 층"):
## - MotionFilter's tilt: still up to 4°, full at 20°, the same beyond, either way; the low-pass's lag; the
##   same tilt at 30, 60 and 120 samples a second; the rest pose; the hysteresis of "tilting";
## - its shake: a light jolt over two samples is one shake, one sample is none, none again for 0.5 s, a hard
##   one is told as hard, a slow tilt is no shake;
## - no sensor: a second of exact zeros (a desktop, a headless run); a value makes it present;
## - MotionInput: the touch stand-in over the test's value over the sensor's, the injected sample through the
##   filter, off while play is closed (no tilt, no shake);
## - the hand guide's new gestures (tilt: the tablet tips and comes back; pump: down and up three times) and
##   the definition's manipulation rule accepting them.
extends RefCounted

const STEP := 1.0 / 60.0

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	check_tilt()
	check_lag()
	check_rest()
	check_shake()
	check_no_sensor()
	check_input()
	check_guide()
	check_rule()


## The reading of a tablet in landscape tipped `degrees` (left edge down positive), at rest, m/s²: Godot
## hands the vector pointing down (the SM-P200 upright on its stand reads about (0, -8.2, -5.0)), so the
## left edge down is a negative x.
static func reading(degrees: float) -> Vector3:
	var a := deg_to_rad(degrees)
	return Vector3(-sin(a), -cos(a), 0.0) * MotionFilter.G


## Feeds `filter` the reading at `degrees` for `seconds` at `rate` samples a second; the last feed's result.
static func hold(filter: MotionFilter, degrees: float, seconds: float, rate := 60.0) -> String:
	var out := ""
	for i in int(round(seconds * rate)):
		var r := filter.feed(reading(degrees), 1.0 / rate)
		if r != "":
			out = r
	return out


func check_tilt() -> void:
	var problems := []
	var want := {0.0: 0.0, 3.0: 0.0, -3.5: 0.0, 8.0: 0.25, 12.0: 0.5, -12.0: -0.5, 20.0: 1.0, 35.0: 1.0, -40.0: -1.0}
	for degrees: float in want:
		var f := MotionFilter.new()
		hold(f, 0.0, 0.3)
		hold(f, degrees, 1.5)
		if absf(f.tilt() - want[degrees]) > 0.02:
			problems.append("%.1f deg: tilt %.3f (want %.2f)" % [degrees, f.tilt(), want[degrees]])
	if MotionFilter.DEAD_DEG != 4.0 or MotionFilter.FULL_DEG != 20.0:
		problems.append("the band %.0f..%.0f" % [MotionFilter.DEAD_DEG, MotionFilter.FULL_DEG])
	expect.call(problems.is_empty(), "motion filter tilt: still up to 4 deg (hand tremor), half at 12, full at 20 and the same beyond, either way (left edge down positive)", "; ".join(problems))


## A step from level to 20° reaches about 63 % in one time constant and all of it in five; the tilt is the
## same at 30, 60 and 120 samples a second (the filter works on the sample interval).
func check_lag() -> void:
	var problems := []
	var f := MotionFilter.new()
	hold(f, 0.0, 0.3)
	hold(f, 20.0, MotionFilter.LOWPASS_S)
	var share := f.angle_deg() / 20.0
	if share < 0.55 or share > 0.72:
		problems.append("after one time constant %.2f of the way" % share)
	hold(f, 20.0, MotionFilter.LOWPASS_S * 4.0)
	if f.angle_deg() < 19.8:
		problems.append("after five: %.2f deg" % f.angle_deg())
	var seen := []
	for rate: float in [30.0, 60.0, 120.0]:
		var g := MotionFilter.new()
		hold(g, 0.0, 0.3, rate)
		hold(g, 14.0, 0.2, rate)
		seen.append(g.tilt())
	if absf(seen[0] - seen[2]) > 0.03 or absf(seen[1] - seen[2]) > 0.03:
		problems.append("per rate %s" % str(seen))
	expect.call(problems.is_empty(), "motion filter lag: a low-pass of %.2f s (63 %% in one time constant), the same tilt at 30, 60 and 120 samples a second %s" % [MotionFilter.LOWPASS_S, str(seen)], "; ".join(problems))


## The rest pose is where a stage starts (lying down, on a lap): the tilt counts from it; "tilting" turns
## on past 4° and off only under 2°.
func check_rest() -> void:
	var problems := []
	var f := MotionFilter.new()
	hold(f, 10.0, 1.0)
	f.rest()
	if absf(f.tilt()) > 0.001:
		problems.append("at the rest pose tilt %.3f" % f.tilt())
	hold(f, 22.0, 1.0)
	if absf(f.tilt() - 0.5) > 0.02:
		problems.append("12 deg past a 10 deg rest: %.3f" % f.tilt())
	var g := MotionFilter.new()
	hold(g, 0.0, 0.5)
	var states := []
	for degrees: float in [5.0, 3.0, 1.5, 3.0]:
		hold(g, degrees, 1.0)
		states.append(g.tilting())
	if states != [true, true, false, false]:
		problems.append("tilting at 5, 3, 1.5, 3: %s" % str(states))
	var fresh := MotionFilter.new()
	hold(fresh, 15.0, 1.0)
	if absf(fresh.tilt()) > 0.001:
		problems.append("the first sample is not the rest pose: %.3f" % fresh.tilt())
	expect.call(problems.is_empty(), "motion filter rest pose: the tilt counts from the pose a stage starts in; tilting turns on past 4 deg and off under 2", "; ".join(problems))


## A jolt (the reading plus `g` g across the screen) for `samples` samples, then still for `after` s.
static func jolt(filter: MotionFilter, g: float, samples: int, after := 0.05) -> Array:
	var out := []
	for i in samples:
		var r := filter.feed(reading(0.0) + Vector3(g * MotionFilter.G, 0.0, 0.0), STEP)
		if r != "":
			out.append(r)
	var r2 := hold(filter, 0.0, after)
	if r2 != "":
		out.append(r2)
	return out


func check_shake() -> void:
	var problems := []
	var f := MotionFilter.new()
	hold(f, 0.0, 0.5)
	var one := jolt(f, 0.45, 1, 0.6)
	var two := jolt(f, 0.45, 2, 0.1)
	var again := jolt(f, 0.45, 2, 0.6)
	var later := jolt(f, 0.45, 2, 0.6)
	var hard := jolt(f, 2.2, 2, 0.6)
	var light := jolt(f, 0.15, 4, 0.6)
	if one != [] or two != ["shake"] or again != [] or later != ["shake"] or hard != ["hard"] or light != []:
		problems.append("one sample %s, two %s, within 0.5 s %s, after %s, hard %s, too light %s" % [one, two, again, later, hard, light])
	var slow := MotionFilter.new()
	hold(slow, 0.0, 0.5)
	var during := []
	for i in 60:
		var r := slow.feed(reading(i * 0.4), STEP)
		if r != "":
			during.append(r)
	if not during.is_empty():
		problems.append("a slow tilt shook %s" % str(during))
	if MotionFilter.COOLDOWN_S != 0.5 or MotionFilter.SHAKE_G > 0.3:
		problems.append("cool-down %.2f, threshold %.2f g" % [MotionFilter.COOLDOWN_S, MotionFilter.SHAKE_G])
	expect.call(problems.is_empty(), "motion filter shake: a light jolt (%.2f g) over two samples is one shake, one sample none, none again for %.1f s, a hard one (%.1f g) is told hard, a slow tilt is no shake" % [MotionFilter.SHAKE_G, MotionFilter.COOLDOWN_S, MotionFilter.HARD_G], "; ".join(problems))


func check_no_sensor() -> void:
	var f := MotionFilter.new()
	for i in 54:
		f.feed(Vector3.ZERO, STEP)
	var early := f.sensor
	for i in 8:
		f.feed(Vector3.ZERO, STEP)
	var after := f.sensor
	var g := MotionFilter.new()
	g.feed(Vector3.ZERO, STEP)
	g.feed(reading(0.0), STEP)
	expect.call(early == MotionFilter.Sensor.UNKNOWN and after == MotionFilter.Sensor.ABSENT and g.present() and f.tilt() == 0.0,
		"motion filter: a second of exact zeros is no sensor (desktop, web, headless), a value is a sensor; no sensor tilts nothing",
		"%d / %d / %s" % [early, after, g.present()])


func check_input() -> void:
	var m := MotionInput.new()
	var problems := []
	var shakes := []
	m.shaken.connect(func(hard: bool) -> void: shakes.append(hard))
	m.inject_tilt(0.5)
	if m.tilt() != 0.5 or m.source != "test" or not m.active():
		problems.append("injected tilt %.2f %s" % [m.tilt(), m.source])
	m.set_touch_tilt(0.8)
	if m.tilt() != 0.8 or m.source != "touch":
		problems.append("touch over test: %.2f" % m.tilt())
	m.end_touch()
	if m.tilt() != 0.5:
		problems.append("after the touch: %.2f" % m.tilt())
	m.enabled = false
	m.inject_shake()
	if m.tilt() != 0.0 or not shakes.is_empty() or m.active():
		problems.append("closed: tilt %.2f, shakes %s" % [m.tilt(), str(shakes)])
	m.enabled = true
	m.inject_shake(true)
	m.touch_shake()
	if shakes != [true, false]:
		problems.append("shakes %s" % str(shakes))
	m.clear_tilt()
	for i in 20:
		m.inject_accel(reading(0.0))
	m.rest()
	for i in 90:
		m.inject_accel(reading(20.0))
	if absf(m.tilt() - 1.0) > 0.02 or not m.filter.present() or not m.has_sensor():
		problems.append("an injected 20 deg sample run: %.3f" % m.tilt())
	m.free()
	expect.call(problems.is_empty(), "motion input: the touch stand-in over the test's value over the sensor's (one tilt value for the lab), injected samples through the filter, nothing while play is closed, shakes from the sensor, the touch and the test alike", "; ".join(problems))


func check_guide() -> void:
	var problems := []
	var g := HandGuide.new()
	tree.root.add_child(g)
	if not ("tilt" in HandGuide.KINDS and "pump" in HandGuide.KINDS):
		problems.append("kinds %s" % str(HandGuide.KINDS))
	var from := func() -> Vector2: return Vector2(900, 200)
	var to := func() -> Vector2: return Vector2(900, 400)
	g.play("tilt", from, Callable())
	if g.playing():
		problems.append("a tilt without its stand-in's end played")
	g.play("tilt", from, to)
	g.step(HandGuide.FADE_S + HandGuide.PRESS_S + HandGuide.TILT_S * 0.25)
	var tipped := HandGuide.tilt_share(0.25)
	if not g.playing() or g.kind != "tilt" or absf(tipped - 1.0) > 0.01 or g.tip.distance_to(Vector2(900, 400)) > 1.0:
		problems.append("tilt at a quarter: share %.2f, paw %s" % [tipped, str(g.tip)])
	g.step(HandGuide.TILT_S * 0.25)
	if HandGuide.tilt_share(0.5) > 0.01 or g.tip.distance_to(Vector2(900, 200)) > 1.0:
		problems.append("tilt at half: back level (paw %s)" % str(g.tip))
	var c := g.tablet_center()
	if absf(c.x - g.size.x * 0.5) > 0.5 or c.y > g.size.y * 0.3:
		problems.append("the tablet is not at the top middle: %s" % str(c))
	g.play("pump", from, to)
	var downs := 0
	var was := 0.0
	for i in 200:
		var k := i / 199.0
		var s := HandGuide.pump_share(k)
		if s > 0.95 and was <= 0.95:
			downs += 1
		was = s
	if downs != int(HandGuide.PUMP_TIMES) or g.cycle_s() <= HandGuide.PUMP_S:
		problems.append("pump downs %d" % downs)
	g.queue_free()
	expect.call(problems.is_empty(), "hand guide: \"tilt\" tips a small tablet at the top middle (two paws on its sides) and back while a faint paw drags the stand-in down; \"pump\" goes down and up %d times" % int(HandGuide.PUMP_TIMES), "; ".join(problems))


func check_rule() -> void:
	var good := {"objects": [{"id": "a", "surface": "s", "guide": "tilt"}, {"id": "b", "surface": "s", "guide": "pump"}]}
	var bad := {"objects": [{"id": "a", "surface": "s", "guide": "wiggle"}]}
	var ok := ExperimentRegistry._validate_manipulation(good).is_empty()
	var refused := not ExperimentRegistry._validate_manipulation(bad).is_empty()
	expect.call(ok and refused, "manipulation rule: \"guide\" may be \"tilt\" or \"pump\" (#160), not anything else", "%s %s" % [ok, refused])
