## The earth labs' base and their first model (#70, 2026-11-06): SunModel against the textbook values
## (tests/earth_textbook_values.json: one rotation 24 h, Seoul's noon sun at the solstices and the
## equinoxes, the day lengths' order, the upright Earth's same noon sun all year, the shortest shadow at noon
## pointing north, sunrise in the east), EarthModel's glides and reset, and EarthLab with a stand-in
## lab: status / settled / observations / control_value are what MissionRound judges, the model is
## stepped only while it animates, and its knob is picked and dragged through the Manipulator.
extends RefCounted

const VALUES_PATH := "res://tests/earth_textbook_values.json"
const VIEW_3D := "res://scripts/shell/view_3d.gd"
const MINUTES_PER_DAY := 1440
const VIEW_SIZE := Vector2(1152, 720)

## A stand-in earth lab: the sun model, one knob ("sun") dragged left and right on an upright plane in
## front of the camera, one metre per hour of the day; a choice control "tilt" (tilted / upright).
const STAND_IN := """extends EarthLab
var surface := ManipSurface.new(Transform3D(Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), Vector3(0.0, 2.0, 0.0)),
	Vector2(-8.0, -3.0), Vector2(8.0, 3.0))
var draws := 0
func _init() -> void:
	model = SunModel.new()
func _build_world() -> void:
	add_knob("sun", "SunKnob")
func _redraw() -> void:
	draws += 1
func _apply_control(id: String, value: Variant) -> void:
	if id == "tilt":
		model.set_start("tilt", SunModel.EARTH_TILT if value == "tilted" else SunModel.UPRIGHT)
	else:
		super(id, value)
func _knob_inputs(_id: String, xf: Transform3D) -> Dictionary:
	return {"rotation": SunModel.NOON_ROTATION + surface.to_plane(xf.origin).x * SunModel.DEG_PER_HOUR}
func _knob_pose(_id: String) -> Transform3D:
	return surface.pose(Vector2(SunModel.hour_angle(model.input("rotation")) / SunModel.DEG_PER_HOUR, 0.0), KNOB_SIZE * 0.5)
func manipulation_surface(_surface_id: String) -> ManipSurface:
	return surface
"""

## The stand-in's definition: the tilt choice, the knob's rule, and a mission block MissionRound judges
## (stage 1: the hour near noon on the tilted Earth; stage 2: night).
const DEFINITION := {
	"id": "earth-stand-in",
	"controls": [{"id": "tilt", "type": "choice", "default": "tilted",
		"options": [{"id": "tilted"}, {"id": "upright"}]}],
	"observations": [{"id": "hour", "digits": 1}, {"id": "altitude", "digits": 0}],
	"manipulation": {"grab_radius": 72.0, "objects": [{"id": "sun", "surface": "sky", "snap": 0.0, "height": false}]},
	"camera": {"target": [0.0, 2.0, 0.0], "distance": 12.0, "default_mode": "front",
		"views": {"front": {"yaw_deg": 0.0, "pitch_deg": -8.0}}},
	"missions": {"judge_on": ["day", "sunrise", "sunset", "night"], "stages": [
		{"observe": "hour", "compare": "near", "threshold": 12.0, "tolerance": 0.5, "conditions": {"tilt": "tilted"}},
		{"observe": "", "judge_on": ["night"]}]},
}

var tree: SceneTree
var expect: Callable
var values: Dictionary


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	values = JSON.parse_string(FileAccess.get_file_as_string(VALUES_PATH))
	check_rotation()
	check_noon_altitude()
	check_day_length()
	check_upright()
	check_shadow()
	check_sunrise()
	check_status()
	check_glide_and_reset()
	await check_lab_round()
	await check_lab_steps()
	await check_knob_drag()


# --- helpers ------------------------------------------------------------------------------------

func _seoul(orbit: float, tilt := SunModel.EARTH_TILT) -> SunModel:
	var model := SunModel.new()
	model.set_start("latitude", float(values.place.latitude))
	model.set_start("tilt", tilt)
	model.set_start("orbit", orbit)
	return model


## |a - b| the short way round (deg).
func _angle_gap(a: float, b: float) -> float:
	return absf(fposmod(a - b + 180.0, 360.0) - 180.0)


func _at_minute(model: SunModel, minute: int) -> void:
	model.set_input("rotation", SunModel.rotation_at(minute / 60.0))


# --- the textbook values ------------------------------------------------------------------------

## One rotation is one day of 24 hours: the hour runs 15 deg per hour, and the sun is where it was a
## rotation later.
func check_rotation() -> void:
	var problems := []
	if SunModel.HOURS_PER_ROTATION != float(values.rotation.hours_per_rotation):
		problems.append("hours per rotation %s" % SunModel.HOURS_PER_ROTATION)
	for hour in [0.0, 6.0, 12.0, 17.25, 23.5]:
		if absf(SunModel.hour_of(SunModel.rotation_at(hour)) - hour) > 1e-9:
			problems.append("hour %s round trip" % hour)
	var model := _seoul(90.0)
	model.set_input("rotation", 100.0)
	var before := [model.sun_altitude(), model.sun_azimuth()]
	model.set_input("rotation", 460.0)
	if absf(model.sun_altitude() - before[0]) > 1e-9 or _angle_gap(model.sun_azimuth(), before[1]) > 1e-9:
		problems.append("a rotation later the sun moved")
	if absf(SunModel.hour_of(SunModel.NOON_ROTATION) - 12.0) > 1e-12:
		problems.append("noon rotation is hour %s" % SunModel.hour_of(SunModel.NOON_ROTATION))
	expect.call(problems.is_empty(), "earth model: one rotation = 24 h (%s)" % values.rotation.source.get_slice(":", 0), "; ".join(problems))


## Seoul's sun at local noon on the solstices and the equinoxes: 90 - latitude + declination.
func check_noon_altitude() -> void:
	var block: Dictionary = values.noon_altitude
	var problems := []
	for case in block.cases:
		var model := _seoul(float(case.orbit))
		model.set_input("rotation", SunModel.NOON_ROTATION)
		var want := float(case.deg)
		for got in [model.sun_altitude(), model.noon_sun_altitude()]:
			if absf(got - want) > float(block.tolerance_deg):
				problems.append("%s %.3f (want %.2f)" % [case.name, got, want])
		# Noon is the day's highest sun.
		for minute in range(0, MINUTES_PER_DAY, 10):
			_at_minute(model, minute)
			if model.sun_altitude() > want + float(block.tolerance_deg):
				problems.append("%s: higher at minute %d" % [case.name, minute])
				break
	expect.call(problems.is_empty(), "earth model: Seoul's noon sun 75.9 / 29.0 / 52.4 deg at the solstices and equinoxes (±%s deg)" % block.tolerance_deg, "; ".join(problems))


## Seoul's day lengths in the textbook's order (June solstice > equinox > December solstice), the
## equinox day about 12 h, and the day length the same as the minutes the model calls day.
func check_day_length() -> void:
	var block: Dictionary = values.day_length
	var problems := []
	var hours := []
	for case in block.order:
		var model := _seoul(float(case.orbit))
		var got := model.day_hours()
		hours.append(got)
		var day_minutes := 0
		for minute in MINUTES_PER_DAY:
			_at_minute(model, minute)
			if model.is_day():
				day_minutes += 1
		if absf(day_minutes - got * 60.0) > 2.0:
			problems.append("%s: %d day minutes, day length %.1f min" % [case.name, day_minutes, got * 60.0])
	if not (hours[0] > hours[1] and hours[1] > hours[2]):
		problems.append("order %s" % str(hours))
	if absf(float(hours[1]) - float(block.equinox_hours)) > float(block.equinox_tolerance_hours):
		problems.append("equinox day %.3f h" % hours[1])
	expect.call(problems.is_empty(), "earth model: Seoul's day longest at the June solstice, about 12 h at the equinox, shortest at the December solstice",
		"%s; %s" % [str(hours), "; ".join(problems)])


## An upright Earth: the same noon sun and a 12-hour day all year (no seasons).
func check_upright() -> void:
	var block: Dictionary = values.upright
	var problems := []
	var lo := INF
	var hi := -INF
	for orbit in range(0, 360, 5):
		var model := _seoul(float(orbit), float(block.tilt))
		model.set_input("rotation", SunModel.NOON_ROTATION)
		lo = minf(lo, model.sun_altitude())
		hi = maxf(hi, model.sun_altitude())
		if absf(model.day_hours() - float(block.day_length_hours)) > float(block.day_length_tolerance_hours):
			problems.append("orbit %d day %.3f h" % [orbit, model.day_hours()])
	if hi - lo > float(block.spread_max_deg) or absf(lo - float(block.noon_altitude)) > 0.05:
		problems.append("noon %.3f..%.3f" % [lo, hi])
	var tilted_spread := _seoul(90.0).noon_sun_altitude() - _seoul(270.0).noon_sun_altitude()
	if tilted_spread < 46.0:
		problems.append("tilted spread %.2f" % tilted_spread)
	expect.call(problems.is_empty(), "earth model: upright Earth, the same noon sun %.2f deg and about 12 h of day all year (tilted: %.1f deg apart)" % [lo, tilted_spread], "; ".join(problems))


## The stick's shadow: shortest at local noon, pointing north then, away from the sun all day, the noon
## lengths 1 m / tan(noon altitude), none at night.
func check_shadow() -> void:
	var block: Dictionary = values.shadow
	var problems := []
	for case in block.noon_length:
		var model := _seoul(float(case.orbit))
		model.set_start("stick", float(block.stick))
		var shortest := INF
		var shortest_minute := -1
		for minute in MINUTES_PER_DAY:
			_at_minute(model, minute)
			if not model.has_shadow():
				if model.shadow_length() != INF or model.observations().has("shadow_length"):
					problems.append("%s: a shadow number at night (minute %d)" % [case.name, minute])
				continue
			if _angle_gap(model.shadow_azimuth(), model.sun_azimuth()) < 180.0 - 1e-9:
				problems.append("%s: shadow not opposite the sun at minute %d" % [case.name, minute])
			if model.shadow_length() < shortest:
				shortest = model.shadow_length()
				shortest_minute = minute
		if absf(shortest_minute - float(block.shortest_at_hour) * 60.0) > 1.0:
			problems.append("%s shortest at minute %d" % [case.name, shortest_minute])
		model.set_input("rotation", SunModel.NOON_ROTATION)
		if _angle_gap(model.shadow_azimuth(), float(block.noon_azimuth_deg)) > float(block.azimuth_tolerance_deg):
			problems.append("%s noon shadow azimuth %.3f" % [case.name, model.shadow_azimuth()])
		if absf(model.shadow_length() - float(case.m)) > float(block.length_tolerance_m):
			problems.append("%s noon shadow %.4f m (want %.4f)" % [case.name, model.shadow_length(), case.m])
		var tip := model.shadow_tip()
		if tip.z > -0.9 * float(case.m) or absf(tip.x) > 1e-3:
			problems.append("%s noon tip %s (want north, -z)" % [case.name, tip])
	# A longer stick, a longer shadow (the same sun).
	var model := _seoul(0.0)
	model.set_input("rotation", SunModel.rotation_at(15.0))
	var short_shadow := model.shadow_length()
	model.set_start("stick", 2.0)
	if absf(model.shadow_length() - 2.0 * short_shadow) > 1e-9:
		problems.append("2 m stick %.4f vs 1 m %.4f" % [model.shadow_length(), short_shadow])
	expect.call(problems.is_empty(), "earth model: the shadow shortest at noon pointing north, away from the sun, 0.25 / 1.80 m at the solstices", "; ".join(problems))


## The sun rises in the east: due east at the equinox, north of east in June, south of east in
## December; morning shadows point west.
func check_sunrise() -> void:
	var block: Dictionary = values.sunrise
	var problems := []
	var east: Array = block.east_half_deg
	var cases: Array = [{"name": "equinox", "orbit": 0.0, "deg": block.equinox_azimuth_deg}]
	cases.append_array(block.solstice_azimuths)
	for case in cases:
		var model := _seoul(float(case.orbit))
		var rise := -1
		for minute in MINUTES_PER_DAY:
			_at_minute(model, minute)
			if model.is_day():
				rise = minute
				break
		var az := model.sun_azimuth()
		if rise < 0 or az <= float(east[0]) or az >= float(east[1]):
			problems.append("%s rises at azimuth %.2f" % [case.name, az])
		var tolerance := float(block.equinox_tolerance_deg if case.name == "equinox" else block.solstice_tolerance_deg)
		if absf(az - float(case.deg)) > tolerance:
			problems.append("%s sunrise azimuth %.2f (want %.1f)" % [case.name, az, case.deg])
		_at_minute(model, rise + 60)
		if model.shadow_azimuth() < 180.0:
			problems.append("%s morning shadow azimuth %.1f" % [case.name, model.shadow_azimuth()])
		if not model.is_morning():
			problems.append("%s sunrise not in the morning" % case.name)
	expect.call(problems.is_empty(), "earth model: the sun rises in the east (equinox 90, June 60, December 120 deg)", "; ".join(problems))


## The status the stages judge on: day at noon, night at midnight, sunrise / sunset near the horizon
## before / after noon.
func check_status() -> void:
	var model := _seoul(0.0)
	var seen := {}
	for hour in [0.0, 6.0, 12.0, 18.0]:
		model.set_input("rotation", SunModel.rotation_at(hour))
		seen[hour] = model.status()
	var want := {0.0: "night", 6.0: "sunrise", 12.0: "day", 18.0: "sunset"}
	var obs := model.observations()
	expect.call(seen == want and obs.has("hour") and obs.has("altitude") and obs.has("day_length") and obs.has("noon_altitude"),
		"earth model: status night / sunrise / day / sunset at 0 / 6 / 12 / 18 h, the observations' numbers", str(seen))


## Glides: an input moves at its rate and lands on its target exactly, an angle the short way round
## across 0; reset() returns the inputs to their starts, a condition's start stays.
func check_glide_and_reset() -> void:
	var problems := []
	var model := SunModel.new()
	model.set_input("rotation", 350.0)
	model.glide_to("rotation", 10.0)
	model.step(1.0 / 60.0)
	if absf(model.input("rotation") - 351.5) > 1e-9:
		problems.append("first step %.4f (want 351.5, the short way)" % model.input("rotation"))
	var steps := 1
	while model.animating() and steps < 1000:
		model.step(1.0 / 60.0)
		steps += 1
	if model.input("rotation") != 10.0 or steps != 14:
		problems.append("landed %.6f after %d steps (want 10 after 14)" % [model.input("rotation"), steps])
	model.glide_to("tilt", 0.0)   # no rate: at once
	if model.animating() or model.input("tilt") != 0.0:
		problems.append("tilt glide %.2f animating %s" % [model.input("tilt"), model.animating()])
	model.set_start("latitude", 10.0)
	model.reset()
	if model.input("rotation") != SunModel.NOON_ROTATION or model.input("tilt") != SunModel.EARTH_TILT or model.input("latitude") != 10.0:
		problems.append("reset %s %s %s" % [model.input("rotation"), model.input("tilt"), model.input("latitude")])
	expect.call(problems.is_empty(), "earth model: a glide at its rate lands exactly (the short way round), reset keeps the conditions", "; ".join(problems))


# --- the base ------------------------------------------------------------------------------------

func _stand_in() -> EarthLab:
	var script := GDScript.new()
	script.source_code = STAND_IN
	script.reload()
	var lab: EarthLab = script.new()
	lab.definition = ExperimentDefinition.new(DEFINITION)
	return lab


## What MissionRound reads: the status, the settled state, the observations and the controls are the
## model's; a stage is judged on them (at noon on the tilted Earth: stamp; upright: no; held: no).
func check_lab_round() -> void:
	var lab = _stand_in()   # untyped: the stand-in's own members (surface, draws)
	tree.root.add_child(lab)
	await tree.process_frame
	var problems := []
	if lab.control_value("tilt") != "tilted" or lab.model.input("tilt") != SunModel.EARTH_TILT:
		problems.append("default tilt %s %s" % [lab.control_value("tilt"), lab.model.input("tilt")])
	if lab.status() != lab.model.status() or lab.observations() != lab.model.observations() or not lab.settled():
		problems.append("status / observations / settled not the model's")
	if not lab.find_children("*", "RigidBody3D", true, false).is_empty():
		problems.append("a rigid body")
	if MissionRound.judge(DEFINITION, 0, lab.status(), lab, lab.observations()) != 1:
		problems.append("noon on the tilted Earth not judged a stamp (%s %s)" % [lab.status(), lab.observations().hour])
	lab.set_control("tilt", "upright")
	if lab.model.input("tilt") != 0.0 or MissionRound.judge(DEFINITION, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("upright: tilt %s, or judged against the stage's condition" % lab.model.input("tilt"))
	lab.set_control("tilt", "tilted")
	lab.manipulation_started("sun")
	if lab.settled() or MissionRound.judge(DEFINITION, 0, lab.status(), lab, lab.observations()) != 0:
		problems.append("judged while the knob is held")
	lab.manipulation_cancelled("sun")
	lab.model.set_input("rotation", 0.0)
	if MissionRound.judge(DEFINITION, 1, lab.status(), lab, lab.observations()) != 2:
		problems.append("midnight not judged night (%s)" % lab.status())
	var resets: int = lab.reset_count
	lab.run_action("reset")
	if lab.reset_count != resets + 1 or lab.model.input("rotation") != SunModel.NOON_ROTATION or lab.model.input("tilt") != SunModel.EARTH_TILT:
		problems.append("reset rotation %s tilt %s" % [lab.model.input("rotation"), lab.model.input("tilt")])
	expect.call(problems.is_empty(), "earth lab: status, settled, observations and controls from the model are what MissionRound judges", "; ".join(problems))
	lab.queue_free()
	await tree.process_frame


## The model is stepped at the fixed step only while it glides; the knob follows it and the lab is
## settled when it lands.
func check_lab_steps() -> void:
	var lab = _stand_in()   # untyped: the stand-in's own members (surface, draws)
	tree.root.add_child(lab)
	await tree.physics_frame
	await tree.physics_frame
	var problems := []
	if lab.step_count != 0:
		problems.append("%d steps while still" % lab.step_count)
	lab.model.glide_to("rotation", 270.0)   # 90 deg at 90 deg/s: 60 fixed steps
	if lab.settled():
		problems.append("settled while gliding")
	var frames := 0
	while not lab.settled() and frames < 200:
		await tree.physics_frame
		frames += 1
	var draws: int = lab.draws
	for i in 5:
		await tree.physics_frame
	var knob_x: float = lab.surface.to_plane(lab.knobs.sun.global_position).x
	if lab.step_count != 60 or lab.draws != draws or absf(knob_x - 6.0) > 1e-4 or lab.status() != "sunset":
		problems.append("steps %d, draws after %d, knob x %.4f, status %s" % [lab.step_count, lab.draws - draws, knob_x, lab.status()])
	expect.call(problems.is_empty(), "earth lab: the model stepped only while it glides (60 fixed steps for 6 h), the knob where the model says", "; ".join(problems))
	lab.queue_free()
	await tree.process_frame


## The knob through the shell's Manipulator: a press on it picks it, a drag of one hour to the right
## turns the model to 13 h while held, the put-down keeps it (placements), and a cancel puts both back.
func check_knob_drag() -> void:
	var host := Control.new()
	host.size = VIEW_SIZE
	tree.root.add_child(host)
	var view: View3D = load(VIEW_3D).new()
	view.size = VIEW_SIZE
	host.add_child(view)
	var lab = _stand_in()   # untyped: the stand-in's own members (surface, draws)
	view.set_world(lab)
	view.rig.configure(DEFINITION.camera)
	var m := Manipulator.new()
	view.viewport.add_child(m)
	m.setup(view, lab)
	for i in 3:
		await tree.physics_frame
	await tree.process_frame
	var per_unit := Vector2(view.viewport.size) / view.size
	var at := view.rig.unproject_position(lab.knobs.sun.global_position) / per_unit
	var hour_right := view.rig.unproject_position(lab.knobs.sun.global_position + Vector3(1.0, 0.0, 0.0)) / per_unit
	var problems := []
	if lab.knobs.sun.collision_mask != 0 or lab.knobs.sun.collision_layer != 1 << (EarthLab.KNOB_LAYER - 1):
		problems.append("knob layers %d / %d" % [lab.knobs.sun.collision_layer, lab.knobs.sun.collision_mask])
	m.handle_pointer("press", at)
	if m.mode != "drag" or m.active_id != "sun" or lab.holding != "sun":
		problems.append("press: mode '%s' id '%s' holding '%s'" % [m.mode, m.active_id, lab.holding])
	m.handle_pointer("move", (at + hour_right) * 0.5)
	m.handle_pointer("move", hour_right)
	await tree.process_frame
	var held_hour: float = lab.model.hour()
	if absf(held_hour - 13.0) > 0.05 or lab.settled():
		problems.append("held: hour %.3f settled %s" % [held_hour, lab.settled()])
	m.handle_pointer("release", hour_right)
	if lab.holding != "" or absf(lab.model.hour() - 13.0) > 0.05 or not lab.placements().has("sun") or not lab.settled():
		problems.append("put down: hour %.3f holding '%s' placements %s" % [lab.model.hour(), lab.holding, lab.placements().keys()])
	# A second drag cancelled by a second finger: the knob and the model go back to 13 h.
	at = view.rig.unproject_position(lab.knobs.sun.global_position) / per_unit
	m.handle_pointer("press", at)
	m.handle_pointer("move", at + (hour_right - at).normalized() * 120.0)
	await tree.process_frame
	m.handle_pointer("cancel", at)
	if absf(lab.model.hour() - 13.0) > 0.05 or lab.holding != "":
		problems.append("cancelled: hour %.3f holding '%s'" % [lab.model.hour(), lab.holding])
	var guide := m.guide()
	if guide.get("kind", "") != "drag" or guide.get("id", "") != "sun":
		problems.append("hand guide %s" % str(guide))
	expect.call(problems.is_empty(), "earth lab: the knob is picked and dragged through the Manipulator, the model follows, put down and cancel, the drag hand guide", "; ".join(problems))
	host.queue_free()
	await tree.process_frame
