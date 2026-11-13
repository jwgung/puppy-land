## 낮과 밤 (#74, 2026-11-06; Hutton Island's first spot, docs/islands/hutton-missions.md 1 and
## hutton-lines.md 1): the Earth floats over a small space stage, the sun stands fixed on its right.
## The half towards the sun is day, the other night. The fox's house on Hutton Island is on the globe,
## and the window under it shows the sky over the house's yard. The child drags the Earth left or right
## and it turns with the finger, one to one (a point of its front follows the finger), no inertia,
## either way (issue #74 decision 1); the arrow round the axis's north end shows the way it really
## turns (west to east).
##
## Model: DayNightModel (SunModel at Seoul's latitude, the March equinox). The lab only draws it
## (EarthLab): the stages are judged on its status ("noon", "midnight", "sunrise", and the evening's
## "sunset" for the morning stage's miss), never on a clock time on the screen.
##
## The hand: one knob ("earth"), a flat pickable box over the globe's face (EarthLab.add_knob, its
## box flattened to the globe's size: a finger anywhere on the globe picks it), dragged along a
## horizontal line in front of the globe (manipulation.objects[].surface "turn", no footprint
## marker). The knob rests in the middle of the line; a drag of x metres turns the Earth x / R
## radians from where it was picked up (R = the globe's radius: its front follows the finger), so
## every drag starts in the middle and the Earth can be turned round and round. A put-down keeps the
## turn (placements(): the knob's place from the start rotation, so a rebuilt screen restores it);
## a cancel puts it back.
class_name DayNightLab
extends EarthLab

const KNOB_ID := "earth"
const KNOB_THICKNESS := 0.2
## How far one drag may turn the Earth (deg either way): a little over half a turn, so noon to
## midnight is one drag.
const DRAG_TURN_DEG := 200.0
## The day's altitude curve in the graph: one point per this many degrees of turn.
const GRAPH_STEP_DEG := 5.0

var props := DayNightProps.new()
## The rotation the drag under way started from (NAN when no drag is under way: a put-down then
## restores a saved place, measured from the start).
var _drag_base := NAN
var _surface: ManipSurface
var _day_curve := PackedVector2Array()
var _graph_key := NAN
var _graph_revision := 0


func _init() -> void:
	model = DayNightModel.new()


func _build_world() -> void:
	props.build(self, model.input("latitude"))
	var knob := add_knob(KNOB_ID, "EarthKnob")
	var shape: CollisionShape3D = knob.get_child(0)
	var box := BoxShape3D.new()
	var across := DayNightProps.GLOBE_RADIUS * 2.0 + 0.2
	box.size = Vector3(across, KNOB_THICKNESS, across)   # knob local: x across, y towards the camera, z down
	shape.shape = box
	var radius := DayNightProps.GLOBE_RADIUS
	var reach := radius * deg_to_rad(DRAG_TURN_DEG)
	_surface = ManipSurface.new(Transform3D(Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN),
		DayNightProps.GLOBE_CENTER + Vector3(0.0, 0.0, radius - KNOB_THICKNESS * 0.5)),
		Vector2(-reach, 0.0), Vector2(reach, 0.0))
	_day_curve = day_curve()
	game = DayNightGame.new(self)
	props.house.add_child(game)
	game.build()


# --- the knob -------------------------------------------------------------------------------------

func manipulation_surface(_surface_id: String) -> ManipSurface:
	return _surface


## The Earth's rotation for the knob at `xf`: the drag's start (or the model's start for a restored
## place) turned by the knob's way along the line over the globe's radius.
func _knob_inputs(_id: String, xf: Transform3D) -> Dictionary:
	var base := _drag_base if not is_nan(_drag_base) else start_rotation()
	var x := _surface.to_plane(xf.origin).x
	return {"rotation": base + rad_to_deg(x / DayNightProps.GLOBE_RADIUS)}


## The knob rests in the middle of its line (over the globe's face).
func _knob_pose(_id: String) -> Transform3D:
	return _surface.pose(Vector2.ZERO, KNOB_THICKNESS * 0.5)


func manipulation_started(id: String) -> void:
	_drag_base = model.input("rotation")
	super(id)


func manipulation_placed(id: String, transform: Transform3D) -> void:
	super(id, transform)
	_drag_base = NAN


func manipulation_cancelled(id: String) -> void:
	super(id)
	_drag_base = NAN


## The turn as a knob place (from the start rotation, the short way round): restored by
## manipulation_placed when the screen is built again.
func placements() -> Dictionary:
	if not _placed.has(KNOB_ID):
		return {}
	var turn := wrapf(model.input("rotation") - start_rotation(), -180.0, 180.0)
	return {KNOB_ID: _surface.pose(Vector2(DayNightProps.GLOBE_RADIUS * deg_to_rad(turn), 0.0), KNOB_THICKNESS * 0.5)}


func start_rotation() -> float:
	return SunModel.rotation_at(DayNightModel.START_HOUR)


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var sun := model as SunModel
	props.show(sun.input("tilt"), SunModel.hour_angle(sun.input("rotation")), sun.sun_altitude(), sun.sun_azimuth())


## The sky over the house in words (the key card), the sun's altitude and azimuth there.
func observations() -> Dictionary:
	var sun := model as SunModel
	return {
		"state": {
			"noon": Locale.t("day_night.status.noon"),
			"day": Locale.t("day_night.status.day"),
			"sunrise": Locale.t("day_night.status.sunrise"),
			"sunset": Locale.t("day_night.status.sunset"),
			"night": Locale.t("day_night.status.night"),
			"midnight": Locale.t("day_night.status.midnight"),
		}.get(status(), ""),
		"altitude": sun.sun_altitude(),
		"azimuth": sun.sun_azimuth(),
	}


## The sun's altitude over the house through one turn (x: the turn from midnight, deg) and where it
## is now.
func graph_series() -> Dictionary:
	var sun := model as SunModel
	return {"altitude": _day_curve, "now": PackedVector2Array([Vector2(sun.input("rotation"), sun.sun_altitude())])}


func graph_revision() -> int:
	var now := model.input("rotation")
	if now != _graph_key:
		_graph_key = now
		_graph_revision += 1
	return _graph_revision


## The day's curve of the sun's altitude at the house (one turn from midnight).
func day_curve() -> PackedVector2Array:
	var probe := DayNightModel.new()
	probe.set_start("latitude", model.input("latitude"))
	var out := PackedVector2Array()
	var turn := 0.0
	while turn <= 360.0:
		probe.set_input("rotation", turn)
		out.append(Vector2(turn, probe.sun_altitude()))
		turn += GRAPH_STEP_DEG
	return out


## The next stage goes on from where the Earth was turned (noon, then on to midnight, then the morning).
func keeps_run_between_stages() -> bool:
	return true


## Dugi points at the house.
func explain_point() -> Vector3:
	return props.house.global_position


## The camera follows the globe.
func follow_point() -> Vector3:
	return props.globe.global_position
