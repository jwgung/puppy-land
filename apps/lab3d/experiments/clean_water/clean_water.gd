## 깨끗한 물 만들기 (#160, 2026-11-18; Curie Island's fifth spot, docs/islands/curie-missions.md 5 and
## curie-lines.md 5; the approved mockup "샘물 마을 몸 조작" 5): the spring village's yard, seen from the side.
## The child tilts the tablet itself (the first spot played with the body): left edge down, the kettle on
## its stand tips the same way and pours the muddy water into the filter column over the jar; the more it
## is tilted the thicker the stream (still up to 4°, the thickest at 20°, no more beyond). The condition
## button (왼쪽 아래) picks the column: 빈 통 / 모래 / 모래·숯. Stage 3 the clear water is in a pot on a wood
## fire, and the child pumps the bellows handle down and up (each pump blows the fire up; stop and it dies
## down) until the water boils and the germs in the magnifier window are gone.
##
## The input (MotionInput, a child of the lab): the sensor's tilt, or the touch stand-in that is always
## there: the yellow ball in the slot right of the kettle (and the kettle itself) dragged down tips the
## kettle as far; let go, it stands up at once. Both end in the same tilt value, so the judging does not
## care which one it was (the tests inject it). The bellows handle is a drag knob: a pump is counted each
## time it goes down past PUMP_DOWN after it was up past PUMP_UP.
##
## Model: CleanWaterModel (states only: soil, colour, smell, germs in the jar's water; the pot's boiling).
## The lab only draws it (EarthLab): the stages are judged on its status ("filtered", "clear", "boiled";
## the misses "little", "muddy", "unboiled"), never on a number on the screen.
class_name CleanWaterLab
extends EarthLab

const TILT_ID := "tilt"
const KETTLE_ID := "kettle"
const BELLOWS_ID := "bellows"
const FILTER_CONTROL := "filter"
## The knobs' boxes (m: big for a finger on a phone) and how far each is dragged for its full value.
const BALL_BOX := 0.75
const KETTLE_BOX := 1.1
const BELLOWS_BOX := 0.8
const KETTLE_STROKE := 1.2
## A pump: the handle down past this share of its stroke after it was up past PUMP_UP.
const PUMP_DOWN := 0.7
const PUMP_UP := 0.3
## The graph (자세히): the pot's water temperature against the play time, a point every GRAPH_STEP s.
const GRAPH_STEP := 0.25
const GRAPH_MAX := 20.0
## The stage played on the fire (0-based).
const BOIL_STAGE := 2
## An upright drag line: its x is down, its normal towards the camera.
const DOWN_LINE := Basis(Vector3.DOWN, Vector3.BACK, Vector3.LEFT)
## An upright drag plane: x across, its normal towards the camera, its z down.
const UPRIGHT := Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)

var props := CleanWaterProps.new()
var motion: MotionInput
## The bellows handle's drop now (0 up .. 1 down) and the touch stand-in's (0 top .. 1 bottom).
var handle_drop := 0.0
var ball_drop := 0.0
## The bellows handle went up since its last pump (the next one down counts).
var _pump_armed := true
var _site_due := -1.0
var _surfaces := {}
var _trace := PackedVector2Array()
var _graph_key := Vector2.INF
var _graph_revision := 0


func _init() -> void:
	model = CleanWaterModel.new()


func _build_world() -> void:
	props.build(self)
	motion = MotionInput.new()
	add_child(motion)
	add_knob(TILT_ID, "TiltKnob", BALL_BOX)
	add_knob(KETTLE_ID, "KettleKnob", KETTLE_BOX)
	add_knob(BELLOWS_ID, "BellowsKnob", BELLOWS_BOX)
	_surfaces[TILT_ID] = _line(CleanWaterProps.ball_point(0.0), CleanWaterProps.SLOT_TOP - CleanWaterProps.SLOT_BOTTOM, BALL_BOX)
	_surfaces[KETTLE_ID] = _line(CleanWaterProps.kettle_center(), KETTLE_STROKE, KETTLE_BOX)
	# The bellows handle goes round its hinge: dragged on the upright plane through it, its angle is the pump.
	_surfaces[BELLOWS_ID] = ManipSurface.new(Transform3D(UPRIGHT, CleanWaterProps.HINGE - Vector3(0.0, 0.0, BELLOWS_BOX * 0.5)),
		Vector2(0.3, -1.4), Vector2(1.6, 0.1))
	game = CleanWaterGame.new(self)
	add_child(game)
	game.build()


## An upright line from `top` down `stroke` m (its knob of `box` sits on it, in front by half its size).
static func _line(top: Vector3, stroke: float, box: float) -> ManipSurface:
	return ManipSurface.new(Transform3D(DOWN_LINE, top - Vector3(0.0, 0.0, box * 0.5)), Vector2.ZERO, Vector2(stroke, 0.0))


func motion_input() -> MotionInput:
	return motion


## The child tilts the tablet now (not on the fire's stage: there the tilt does nothing).
func body_input_active() -> bool:
	return motion != null and motion.active() and is_nan(motion.touch_tilt) and not (model as CleanWaterModel).boiling_site()


## The tilt is read only while the child can play (not while Dugi's box or the question is up); the rest
## pose is taken when play opens.
func set_play_open(open: bool) -> void:
	if motion == null:
		return
	motion.enabled = open
	if open:
		motion.rest()


## 빈 통 / 모래 / 모래·숯: the column (kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == FILTER_CONTROL:
		var kind := {"empty": CleanWaterModel.EMPTY, "sand": CleanWaterModel.SAND, "charcoal": CleanWaterModel.CHARCOAL}
		(model as CleanWaterModel).set_filter(float(kind.get(str(value), CleanWaterModel.SAND)))


# --- the place (the stage) ------------------------------------------------------------------------

## The stage changed: its place. A stage just cleared keeps its result until the next reset; opened or
## jumped to, the place is set at once.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	var site := site_of(stage)
	if just_cleared and model.input("site") != site:
		_site_due = site
	else:
		_set_site(site)


## The place of stage `stage` (-1: the round is done, the fire).
static func site_of(stage: int) -> float:
	return CleanWaterModel.BOIL if stage < 0 or stage >= BOIL_STAGE else CleanWaterModel.FILTER


func _set_site(site: float) -> void:
	_site_due = -1.0
	if site == model.input("site"):
		return
	(model as CleanWaterModel).set_site(site)
	model.reset()
	if is_inside_tree():
		_show()
	_update_status(true)


func reset_run() -> void:
	if _site_due >= 0.0:
		_set_site(_site_due)
	handle_drop = 0.0
	ball_drop = 0.0
	_pump_armed = true
	if motion != null:
		motion.end_touch()
		motion.rest()
	super()


# --- the hand -------------------------------------------------------------------------------------

## The place's objects take a finger: the stand-in ball and the kettle by the filter, the bellows by the fire.
func offered(id: String) -> bool:
	if (model as CleanWaterModel).boiling_site():
		return id == BELLOWS_ID
	return id == TILT_ID or id == KETTLE_ID


func manipulation_body(id: String) -> PhysicsBody3D:
	return knobs.get(id) if offered(id) or holding == id else null


func manipulation_surface(surface_id: String) -> ManipSurface:
	return _surfaces.get(surface_id)


## Every knob rests at the top of its line (the ball up, the kettle as it hangs), the bellows' on its handle.
func _knob_pose(id: String) -> Transform3D:
	var box := {TILT_ID: BALL_BOX, KETTLE_ID: KETTLE_BOX, BELLOWS_ID: BELLOWS_BOX}
	var surface: ManipSurface = _surfaces[id]
	var at := surface.to_plane(CleanWaterProps.handle_point(handle_drop)) if id == BELLOWS_ID else Vector2.ZERO
	return surface.pose(at, float(box[id]) * 0.5)


## How far down knob `id` at `xf` is (0..1): along its line, or round the bellows' hinge.
func knob_share(id: String, xf: Transform3D) -> float:
	if id == BELLOWS_ID:
		return CleanWaterProps.handle_share(xf.origin)
	var surface: ManipSurface = _surfaces[id]
	return clampf(surface.to_plane(xf.origin).x / surface.region_max.x, 0.0, 1.0)


func manipulation_started(id: String) -> void:
	if id == BELLOWS_ID:
		_pump_armed = true
	super(id)


## The ball and the kettle dragged down tilt the kettle as far (MotionInput "touch"); the bellows handle
## counts a pump each time it goes down (MotionInput is not used: the bellows is a thing on the screen).
func _knob_inputs(id: String, xf: Transform3D) -> Dictionary:
	if holding != id:
		return {}
	var k := knob_share(id, xf)
	if id == BELLOWS_ID:
		handle_drop = k
		if k >= PUMP_DOWN and _pump_armed:
			_pump_armed = false
			(model as CleanWaterModel).pump()
		elif k <= PUMP_UP:
			_pump_armed = true
		return {}
	if id == TILT_ID:
		ball_drop = k
	motion.set_touch_tilt(k)
	_feed_tilt()
	return {}


## Let go (or put back): the ball, the kettle and the handle go up at once; the kettle stands up.
func manipulation_placed(id: String, transform: Transform3D) -> void:
	super(id, transform)
	_let_go()


func manipulation_cancelled(id: String) -> void:
	super(id)
	_let_go()


func _let_go() -> void:
	motion.end_touch()
	ball_drop = 0.0
	handle_drop = 0.0
	_pump_armed = true
	_feed_tilt()
	_show()
	_update_status(true)


## Pours and pumps are events, not places.
func placements() -> Dictionary:
	return {}


## Judged when no finger holds anything, the tablet is not being tilted and the run has its result (or
## has come to its miss: CleanWaterModel.decided).
func settled() -> bool:
	return holding == "" and not body_input_active() and (model as CleanWaterModel).decided()


## The model takes the tilt now (sensor, touch or test).
func _feed_tilt() -> void:
	var m := model as CleanWaterModel
	var t := motion.tilt() if motion != null and not m.boiling_site() else 0.0
	if t != m.input("tilt"):
		m.set_tilt(t)
		if is_inside_tree():
			_show()
		_update_status(true)


func _physics_process(delta: float) -> void:
	_feed_tilt()
	super(delta)


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)
	_record()


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as CleanWaterModel
	props.show(m, m.input("tilt"), ball_drop, handle_drop)


## Words only (no number on the screen): the water come through, the germs, the fire.
func observations() -> Dictionary:
	var m := model as CleanWaterModel
	var water := Locale.t("clean_water.water.none")
	var germs := Locale.t("clean_water.germs.none_yet")
	var fire := Locale.t("clean_water.fire.off")
	if m.boiling_site():
		water = Locale.t("clean_water.water.clear")
		var left := m.input("pot_germs")
		germs = Locale.t("clean_water.germs.gone") if left <= 0.0 else (Locale.t("clean_water.germs.dying") if left < 1.0 else Locale.t("clean_water.germs.there"))
		if m.fire_on():
			fire = Locale.t("clean_water.fire.big") if m.input("fire") >= 0.6 else Locale.t("clean_water.fire.small")
	elif m.input("jar") > 0.0:
		germs = Locale.t("clean_water.germs.there")
		if m.input("soil") > CleanWaterModel.MUDDY:
			water = Locale.t("clean_water.water.muddy")
		elif m.input("colour") > CleanWaterModel.COLOURED:
			water = Locale.t("clean_water.water.yellow")
		else:
			water = Locale.t("clean_water.water.clear")
	return {"water": water, "germs": germs, "fire": fire}


## Dugi points at the column (stages 1-2) or the pot (stage 3).
func explain_point() -> Vector3:
	if (model as CleanWaterModel).boiling_site():
		return CleanWaterProps.POT_AT + Vector3(0.0, CleanWaterProps.POT_H, 0.0)
	return Vector3(0.0, CleanWaterProps.SAND_TOP, 0.0)


## The camera follows the yard's middle.
func follow_point() -> Vector3:
	return Vector3(0.8, 2.0, 0.0)


## The pot's water against the play time (자세히: the units are only there), the boiling line, and where
## the run is now. Flat at the room's temperature by the filter (stages 1-2).
func graph_series() -> Dictionary:
	var m := model as CleanWaterModel
	var boil := PackedVector2Array([Vector2(0.0, CleanWaterModel.BOIL_C), Vector2(GRAPH_MAX, CleanWaterModel.BOIL_C)])
	return {"boil": boil, "trace": _trace, "now": PackedVector2Array([Vector2(minf(m.input("time"), GRAPH_MAX), m.input("water"))])}


func graph_revision() -> int:
	var m := model as CleanWaterModel
	var key := Vector2(snappedf(m.input("time"), GRAPH_STEP), snappedf(m.input("water"), 0.5) + 1000.0 * m.site())
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## A point every GRAPH_STEP s of play time; a new run (the time back at 0) starts it over.
func _record() -> void:
	var m := model as CleanWaterModel
	var t := m.input("time")
	if not _trace.is_empty() and t < _trace[_trace.size() - 1].x:
		_trace.clear()
	if (_trace.is_empty() or t - _trace[_trace.size() - 1].x >= GRAPH_STEP) and t <= GRAPH_MAX:
		_trace.append(Vector2(t, m.input("water")))
