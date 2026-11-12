## Guided free-fall lab (Phase 1 Task 4a; web preset "free-fall"): balls of different mass dropped
## in the chosen field land at the same time. Since 2026-10-29 (user: "2개만 놓고 하자") two balls:
## the light yellow one (0.5 kg) and the heavy red one (the "mass" control, 3 kg by default); the web's
## third, violet reference ball is not in the 3D lab (the web keeps its three; the law is the same).
## Conditions: gravity (the web's buttons), the drop height of both (slider) and the red ball's
## mass. A finger taps (or drags) either ball ("drop_<ball>" objects) and both drop together. Since
## 2026-11-12 (user: "높이 자꾸 바꾸게 하지 말고, 중력 조건만 바꾸는 걸로 하자") the finger no longer
## changes a height: both start level at DROP_HEIGHT and the piece game's stages change only the world
## (2026-10-29 to 11-12 letting go set that ball's own height and the child lifted the pink one level).
## The "height" control (the "자세히" slider) still sets both, in whole metres (1–8 m).
## A finger does not move a ball sideways (definition: "drag": false).
## Motion: Jolt + UniformFieldCorrector (uniform_field_lab.gd). Displayed numbers: PhysicsLaws at the formula time (the landing at landing_time(0, -g, h0)); the engine is
## only the graph's "시뮬레이션" points and the measured landing times.
## Each ball looks as heavy as it is (2026-10-28, look_radius): the red ball grows and shrinks with
## its mass from its body's bottom; the bodies (BALL_RADIUS spheres), their fall and the landings stay.
extends UniformFieldLab

## Left to right. mass: kg (the red one follows the "mass" control).
const BALLS := {
	"yellow": {"x": -1.5, "mass": 0.5, "color": ArtPalette.PINK},
	"red": {"x": 1.5, "mass": 3.0, "color": ArtPalette.RED},
}
const ORDER := ["yellow", "red"]
const LINE_X := 3.0              # the balls move along the floor line x = -3..3 m (z = 0)
const DROP := "drop_"             # the finger's object of a ball: "drop_red" drags the red ball up and down
const BOUNCE := 0.5               # the web's wood balls (restitution 0.5)
const LOOK_MASS := 1.0            # kg: the mass that looks BALL_RADIUS round (the web's violet reference ball)
const SIGN_AT := Vector3(-5.0, 0.0, -2.2)   # the gravity's signpost (PlanetSign), left of the ruler
## The piece game's two balls (the heavy red and the light yellow one) press their buttons "together"
## when their formula landings are this close (one fixed step: the same height lands at the same step).
const TOGETHER_S := 1.0 / 60.0
const PAIR := ["red", "yellow"]

var balls: Dictionary = {}        # id -> FormulaBody
## id -> start point of the ball's bottom (x, height above the floor, z).
var starts: Dictionary = {}
## The "height" control (both balls); a height handle changes one ball only.
var height := 5.0
## Both balls start level at DROP_HEIGHT and a finger does not move them up or down (2026-11-12 user:
## "높이 자꾸 바꾸게 하지 말고, 중력 조건만 바꾸는 걸로 하자"): a tap (or a drag) on a ball drops both from
## there, and the stages ask only for the world (지구 / 달 / 목성). Until then the two started at
## different heights and the child lifted the pink one to the red one. The 자세히 slider still sets
## both alike.
const DROP_HEIGHT := 5.0
const START_HEIGHTS := {"red": DROP_HEIGHT, "yellow": DROP_HEIGHT}
## Per stage of the piece game: a new stage puts both balls back level at DROP_HEIGHT (after the
## slider moved them). Until 2026-11-12 the red ball waited at the stage's height and the pink one lower.
const STAGE_HEIGHTS := [{"red": DROP_HEIGHT, "yellow": DROP_HEIGHT}, {"red": DROP_HEIGHT, "yellow": DROP_HEIGHT}, {"red": DROP_HEIGHT, "yellow": DROP_HEIGHT}]
var _heights_stage := -1          # the stage whose STAGE_HEIGHTS the balls got
var _heights_pending := false     # a stage just cleared: its next heights wait for the next run
var mass_id := "heavy"
## The signpost showing which world the gravity is (2026-10-28).
var planet_sign: PlanetSign
var _pressed := {}                # the piece game: the balls whose formula landing pressed their button this run


func _init() -> void:
	props = FreeFallProps.new()


## After the controls' defaults (the "height" slider sets both), each ball gets its START_HEIGHTS
## (level since 2026-11-12; the hand guide taps drop_yellow, the definition's first object).
func _ready() -> void:
	super()
	for id in ORDER:
		starts[id].y = float(START_HEIGHTS[id])
	reset_run()


func set_control(id: String, value: Variant) -> void:
	match id:
		"height":
			set_height(float(value))
		"mass":
			set_red_mass(str(value))
		_:
			super(id, value)
			if id == "gravity":
				planet_sign.show_planet(gravity_id)


func control_value(id: String) -> Variant:
	match id:
		"height":
			return height
		"mass":
			return mass_id
	return super(id)


## Both balls start `h` metres above the floor (their bottoms), limited to the slider's range (not
## snapped: the slider's 1 m step is the UI's; the web-parity cases drop from 2.5 m).
func set_height(h: float) -> void:
	var clamped := definition.clamp_value("height", h)
	if is_nan(clamped):
		return
	height = clamped
	_heights_pending = false   # the slider's height for both wins over a stage's waiting heights
	for id in ORDER:
		starts[id].y = height
	reset_run()


func set_red_mass(option_id: String) -> void:
	var option := definition.option("mass", option_id)
	if option.is_empty():
		push_warning("free-fall: unknown mass %s" % option_id)
		return
	balls.red.mass = float(option.kg)
	mass_id = option_id
	fall_props().set_look("red", look_radius("red"))
	reset_run()


func fall_props() -> FreeFallProps:
	return props as FreeFallProps


func mass_of(id: String) -> float:
	return balls[id].mass


## Radius ball `id` looks (m): one stuff, the cube root of its mass against LOOK_MASS.
func look_radius(id: String) -> float:
	return BALL_RADIUS * MassLook.factor(mass_of(id), LOOK_MASS)


## The stage changed (opened, or one just cleared): its STAGE_HEIGHTS, now or (the balls still lie
## where the win landed them) at the next run.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	if stage < 0 or stage >= STAGE_HEIGHTS.size() or stage == _heights_stage:
		return
	_heights_stage = stage
	_heights_pending = true
	if not released:
		reset_run()


func reset_run() -> void:
	_pressed = {}
	if _heights_pending and _heights_stage >= 0:
		_heights_pending = false
		for id in ORDER:
			starts[id].y = definition.clamp_value("height", float(STAGE_HEIGHTS[_heights_stage][id]))
	if game != null:
		game.run_reset()
		(game as FreeFallGame).place_buttons(starts)
	for id in ORDER:
		var ball: FormulaBody = balls[id]
		hold_ball(ball, starts[id] + Vector3.UP * BALL_RADIUS)
		apply_field(ball)
		fall_props().place_pad(id, starts[id])
	fall_props().place_cat(starts)
	_mark_reset()


func release() -> void:
	if released:
		reset_run()
	for id in ORDER:
		var ball: FormulaBody = balls[id]
		apply_field(ball)
		(ball.corrector as UniformFieldCorrector).release(ball, Vector3.ZERO)
	var first := PackedVector2Array()
	for id in ORDER:
		first.append(Vector2(0.0, starts[id].y))
	_mark_released(first)


func corrector_of(id: String) -> UniformFieldCorrector:
	return balls[id].corrector


## Formula time (s) of the free fall of ball `id` until `landing_time` (INF without a field).
func landing_time(id: String) -> float:
	return PhysicsLaws.landing_time(0.0, -g, starts[id].y)


## Seconds since the release on the fixed-step clock (the time of the last recorded sample).
func clock() -> float:
	if not released:
		return 0.0
	return maxi(0, corrector_of("red").steps - 1) * step_dt()


## The ball has landed: the clock reached its formula landing time, or the engine reported it
## (has_landed_by).
func has_landed(id: String) -> bool:
	return has_landed_by(corrector_of(id), landing_time(id), clock())


## Formula time of one ball: the clock, but never past its landing (the landing once it landed).
func ball_time(id: String) -> float:
	var landing := landing_time(id)
	return landing if has_landed(id) else minf(clock(), landing)


## Formula height of a ball's bottom above the floor at time t (0 from the landing on).
func formula_height(id: String, t: float) -> float:
	if t >= landing_time(id):
		return 0.0
	return maxf(0.0, starts[id].y + PhysicsLaws.constant_acceleration_displacement(0.0, -g, t))


## The time shown: the clock while a ball is still falling, the last formula landing once all landed
## (without a field no ball lands, also not one on the floor: the clock).
func shown_time() -> float:
	if not released:
		return 0.0
	var last := 0.0
	for id in ORDER:
		if not has_landed(id):
			return clock()
		last = maxf(last, landing_time(id))
	return last


func _status_changed(previous: String, current: String) -> void:
	fall_props().status_changed(previous, current)


func status() -> String:
	if not released:
		return "ready"
	if g <= 0.0:
		return "floating"
	for id in ORDER:
		if not has_landed(id):
			return "falling"
	return "landed"


func _released_step() -> void:
	# samples[k] is the drop after k steps; this runs before the balls' own step (tree order).
	var steps := corrector_of("red").steps - 1
	if _graph_sample_time(steps) < 0.0:
		return
	for id in ORDER:
		_append_sample(corrector_of(id), steps, starts[id].y, landing_time(id))


func observations() -> Dictionary:
	var t_red := ball_time("red") if released else 0.0
	var m := mass_of("red")
	var speed := absf(PhysicsLaws.constant_acceleration_velocity(0.0, -g, t_red))
	var h_red := formula_height("red", t_red)
	var fall: Variant = landing_time("red")
	var state_text: String = {
		"ready": Locale.t("free-fall.status.ready"),
		"falling": Locale.t("free-fall.status.falling"),
		"landed": Locale.t("free-fall.status.landed"),
		"floating": Locale.t("free-fall.status.floating"),
	}.get(status(), "")
	return {
		"g": g,
		"time": shown_time(),
		"red_time": t_red,   # the red ball's own time (its landing once it landed): the kid card and the stamp
		"state": state_text,
		"height_red": h_red,
		"height_yellow": formula_height("yellow", ball_time("yellow") if released else 0.0),
		"fall_time": fall if is_finite(fall) else Locale.t("free-fall.no_landing"),
		"speed": speed,
		"momentum": PhysicsLaws.momentum(m, speed),
		"kinetic": PhysicsLaws.kinetic_energy(m, speed),
		"potential": PhysicsLaws.gravitational_potential_energy(m, g, h_red),
		"landing": measured_landings(),
		"together_time": together_time(),
	}


## The piece game's value (2026-10-29): once the red and the yellow ball have both landed, their
## common formula landing time √(2h/g) when the two landings are within TOGETHER_S of each other
## (mass does not enter it: the same height lands together), else "따로 닿았어요". Read only.
func together_time() -> Variant:
	if not released:
		return "—"
	if g <= 0.0:
		return Locale.t("free-fall.no_landing")
	if not (has_landed("red") and has_landed("yellow")):
		return Locale.t("free-fall.status.falling")
	var t_red := landing_time("red")
	if absf(t_red - landing_time("yellow")) > TOGETHER_S:
		return Locale.t("free-fall.apart")
	return t_red


## A ball's colour word (the language's: free-fall.ball.<id>, "분홍" / "빨강").
static func ball_name(id: String) -> String:
	return Locale.t("free-fall.ball." + id)


## Engine landing times of the two balls (the "시뮬레이션" readout): "분홍 1.02 · 빨강 … s"; a
## ball shows "—" until it has a measured landing step (measured_landing_step).
func measured_landings() -> String:
	if not released:
		return "—"
	var parts := PackedStringArray()
	for id in ORDER:
		var step := measured_landing_step(corrector_of(id), landing_time(id), clock())
		parts.append("%s %s" % [ball_name(id), "%.2f" % (step * step_dt()) if step >= 0 else "—"])
	return " · ".join(parts) + " s"


func graph_series() -> Dictionary:
	var series := {"measured": _measured.duplicate()}
	for id in ORDER:
		series[id] = _formula_line(func(t: float) -> float: return formula_height(id, t), landing_time(id))
	return series


func follow_point() -> Vector3:
	return balls.red.global_position if balls.has("red") else global_position


func _build_world() -> void:
	make_floor(Vector3(30.0, 0.4, 22.0))
	var visuals := {}
	for id in ORDER:
		var spec: Dictionary = BALLS[id]
		var ball := make_ball(id.capitalize(), spec.mass, BOUNCE)
		var visual := ball_visual(spec.color)
		visual.name = "Visual"
		ball.add_child(visual)
		add_child(ball)
		balls[id] = ball
		visuals[id] = [ball, visual]
		starts[id] = Vector3(spec.x, height, 0.0)
	fall_props().dress(self, visuals, BALL_RADIUS * 2.0)
	planet_sign = PlanetSign.new()
	planet_sign.position = SIGN_AT
	add_child(planet_sign)
	for id in ORDER:
		fall_props().set_look(id, look_radius(id))
	for juice: ArtJuice in fall_props().juices.values():
		juice.landed.connect(impact.emit)
	game = FreeFallGame.new(self)   # the piece game: two floor buttons and the barred house (visual only)
	add_child(game)
	game.build()
	(game as FreeFallGame).place_buttons(starts)


## The piece game's buttons light when their formula ball lands (has_landed); two that do not land
## together rattle the house's door.
func _process(_delta: float) -> void:
	if game == null or not released:
		return
	for id in PAIR:
		if not _pressed.has(id) and has_landed(id):
			_pressed[id] = true
			(game as FreeFallGame).press(id)
			if _pressed.size() == PAIR.size() and together_time() is String:
				(game as FreeFallGame).rattle()


# --- manipulation -----------------------------------------------------------------------------

func manipulation_body(id: String) -> PhysicsBody3D:
	return balls.get(id.trim_prefix(DROP))


## "line": the floor line under the balls in front of the ruler (0.5 m grid, the balls' `snap` rule).
## "drop_<ball>": the ball's own point on its drop line, plane x = the height of the ball's bottom (a
## single point since 2026-11-12: the finger does not change it; before, the slider's range). The frame stands
## upright (x up, its normal towards the front camera) one radius behind the ball, so a ball lifted
## by its radius off the frame is on its own drop line.
func manipulation_surface(surface_id: String) -> ManipSurface:
	var surface: ManipSurface
	if surface_id == "line":
		surface = ManipSurface.new(Transform3D.IDENTITY, Vector2(-LINE_X, 0.0), Vector2(LINE_X, 0.0))
	elif surface_id.begins_with(DROP) and starts.has(surface_id.trim_prefix(DROP)):
		var x: float = starts[surface_id.trim_prefix(DROP)].x
		var h: float = starts[surface_id.trim_prefix(DROP)].y   # (the ball stays at its height: 2026-11-12)
		var frame := Transform3D(Basis(Vector3.UP, Vector3.BACK, Vector3.RIGHT), Vector3(x, BALL_RADIUS, -BALL_RADIUS))
		surface = ManipSurface.new(frame, Vector2(h, 0.0), Vector2(h, 0.0))
	else:
		return null
	surface.exclude = [floor_body.get_rid()]
	return surface


func manipulation_juice(id: String) -> ArtJuice:
	return fall_props().juices.get(id.trim_prefix(DROP))


## Picked up (also a falling or landed ball): the run stops and every ball waits at its start, so
## the picked one stays at its start height; the bread cat
## stands where it stands (between the balls).
func manipulation_started(id: String) -> void:
	if released:
		reset_run()
	id = id.trim_prefix(DROP)
	fall_props().juices[id].rearm()


## A ball's drop line is its own: no other ball straight above or below it (the two would collide
## in the air, which the per-ball formula does not describe). Neighbours on the 0.5 m grid (sides
## touching) fall side by side and stay allowed. A drop line keeps its ball where it is.
func placement_allowed(id: String, transform: Transform3D) -> bool:
	if id.begins_with(DROP):
		return true
	for other in ORDER:
		if other != id and absf(transform.origin.x - starts[other].x) < BALL_RADIUS * 2.0 - 0.001:
			return false
	return true


## A ball moved onto the other one stops beside it (two radii apart, on the side it came from).
func nearest_placement(id: String, transform: Transform3D) -> Transform3D:
	var at := transform
	if id.begins_with(DROP):
		return at
	for other in ORDER:
		if other != id and absf(at.origin.x - starts[other].x) < BALL_RADIUS * 2.0 - 0.001:
			var side := signf(starts[id].x - starts[other].x)
			at.origin.x = starts[other].x + (side if side != 0.0 else 1.0) * BALL_RADIUS * 2.0
	return at


func manipulation_placed(id: String, transform: Transform3D) -> void:
	if id.begins_with(DROP):
		# A ball let go on its drop line stays at its height (2026-11-12; before, it took the finger's
		# height), and the lifted finger drops both balls together (2026-10-29 user: no "공 놓기" button; a new drag after
		# a drop starts a fresh run, manipulation_started). A restored placement (a batch) only places.
		var ball_id := id.trim_prefix(DROP)
		var h: float = starts[ball_id].y   # the finger does not change the height (2026-11-12)
		manipulation_placed(ball_id, Transform3D(Basis(), Vector3(starts[ball_id].x, h + BALL_RADIUS, starts[ball_id].z)))
		if _batch == 0:
			release()
		return
	_placed = true
	starts[id] = transform.origin - Vector3.UP * BALL_RADIUS
	starts[id].y = snapped_height(starts[id].y)
	var ball: FormulaBody = balls[id]
	hold_ball(ball, starts[id] + Vector3.UP * BALL_RADIUS)
	apply_field(ball)
	fall_props().place_pad(id, starts[id])
	if game != null:
		(game as FreeFallGame).place_buttons(starts)
	_graph_revision += 1
	_update_status(true)


## Every ball's start once one was moved (kept across a screen rebuild).
func placements() -> Dictionary:
	if not _placed:
		return {}
	var result := {}
	for id in ORDER:
		result[id] = Transform3D(Basis(), starts[id] + Vector3.UP * BALL_RADIUS)
	return result
