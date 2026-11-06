## 그림자 시계 (#86, 2026-11-07; Hutton Island's second spot, docs/islands/hutton-missions.md 2 and
## hutton-lines.md 2): a round yard on the hill with a stick in its middle. The child drags the sun
## along its sky path (east -> south -> west, a dotted half-circle over the yard) and the stick's
## shadow follows the model: away from the sun, shorter when the sun is higher. The condition button
## swaps the stick (short / long). West of the stick is a flower bed, far to its east a flat stone
## with a lidded chest (the piece in it).
##
## The view looks south (the sun's side), so east is on the left and west on the right, like the
## 낮과 밤 window; the shadows fall towards the camera. World axes: x west, y up, z north (the sky
## frame turned half round: world_of()).
##
## Model: ShadowClockModel (SunModel, Seoul's latitude, the March equinox). The lab only draws it
## (EarthLab): the stages are judged on its status ("noon", "bed", "stone"; "morning" / "afternoon"
## between), never on a clock time on the screen.
##
## The hand: one knob ("sun"), a pickable box on the sun, dragged on the plane of the sun's path (the
## equinox path is a half-circle in the plane through the stick's foot square to the celestial pole:
## it faces the camera). The knob's place on that plane is an angle round the stick's foot: the hour
## angle (atan2 of its two plane coordinates); the sun goes there on its path (kept between the
## path's two low ends). No inertia, no footprint marker. A put-down keeps the sun's place (and
## restores it: placements()); a cancel puts it back.
##
## The stick: the condition button sets the model's `stick` (its start too, so 처음으로 keeps it) and
## the sun stays where it is (set_control does not restart the run): the child sees the same sun cast
## a longer shadow from the long stick.
class_name ShadowClockLab
extends EarthLab

const KNOB_ID := "sun"
const STICK_CONTROL := "stick"
## The knob: a box this big round the sun (m: the sun is the thing a finger takes).
const KNOB_BOX := 1.5
## Where on the path's plane the finger may take the knob (times SKY_RADIUS from the stick's foot):
## across either way and up past the noon sun PLANE_REACH; down to PLANE_LOW (a little over the
## foot: lower, the knob stays there and the sun at the path's low end). The hand guide drags it
## towards the region's far end (right: the way the sun goes).
const PLANE_REACH := 1.3
const PLANE_LOW := -0.2
## The graph's curves: a point every this many degrees of the sun's height.
const GRAPH_STEP_DEG := 2.0

var props := ShadowClockProps.new()
var _surface: ManipSurface
var _curves := {}   # "short" / "long": the shadow length against the sun height, built once
var _graph_key := Vector2(NAN, NAN)
var _graph_revision := 0


func _init() -> void:
	model = ShadowClockModel.new()


func _build_world() -> void:
	var sun := model as ShadowClockModel
	props.build(self, world_of(sun.bed_spot()), world_of(sun.stone_spot()), sun_path())
	add_knob(KNOB_ID, "SunKnob", KNOB_BOX)
	var r := ShadowClockProps.SKY_RADIUS
	_surface = ManipSurface.new(path_frame(sun.input("latitude")),
		Vector2(-r * PLANE_REACH, -r * PLANE_REACH), Vector2(r * PLANE_REACH, r * PLANE_LOW))
	game = ShadowClockGame.new(self)
	add_child(game)
	game.build()


## A point of the sky frame (x east, y up, z south) in the world (x west, y up, z north), from the
## stick's foot.
static func world_of(sky: Vector3) -> Vector3:
	return ShadowClockProps.STICK_AT + Vector3(-sky.x, sky.y, -sky.z)


## The plane of the equinox sun's path at `latitude`: through the stick's foot, its x along the
## world's x (west), its normal the celestial pole (north and up: towards the camera), its z down
## the plane (the noon sun is at -z). A sun `ha` deg from noon is at (R sin ha, -R cos ha).
static func path_frame(latitude: float) -> Transform3D:
	var phi := deg_to_rad(latitude)
	var x := Vector3.RIGHT
	var pole := Vector3(0.0, sin(phi), cos(phi))
	return Transform3D(Basis(x, pole, x.cross(pole)), ShadowClockProps.STICK_AT)


## The sun's path in the world: a point every ShadowClockProps.PATH_STEP_DEG of hour angle between
## its two low ends.
func sun_path() -> PackedVector3Array:
	var sun := model as ShadowClockModel
	var lat := sun.input("latitude")
	var decl := sun.sun_declination()
	var limit := ShadowClockModel.path_hour_angle(lat, decl)
	var out := PackedVector3Array()
	var steps := int(floor(limit * 2.0 / ShadowClockProps.PATH_STEP_DEG))
	for k in steps + 1:
		var ha := -limit + (limit * 2.0) * k / steps
		var alt := deg_to_rad(SunModel.altitude(lat, decl, ha))
		var az := deg_to_rad(SunModel.azimuth(lat, decl, ha))
		out.append(world_of(Vector3(cos(alt) * sin(az), sin(alt), -cos(alt) * cos(az)) * ShadowClockProps.SKY_RADIUS))
	return out


# --- the knob -------------------------------------------------------------------------------------

func manipulation_surface(_surface_id: String) -> ManipSurface:
	return _surface


## The sun at the knob's angle round the stick's foot on the path's plane (kept on the path).
func _knob_inputs(_id: String, xf: Transform3D) -> Dictionary:
	var p := _surface.to_plane(xf.origin)
	var ha := rad_to_deg(atan2(p.x, -p.y))
	return {"rotation": (model as ShadowClockModel).rotation_on_path(ha / SunModel.DEG_PER_HOUR)}


## The knob sits on the sun, half its size in front of the path's plane (the Manipulator holds a
## body half its size over its surface).
func _knob_pose(_id: String) -> Transform3D:
	var ha := deg_to_rad(SunModel.hour_angle(model.input("rotation")))
	var r := ShadowClockProps.SKY_RADIUS
	return _surface.pose(Vector2(r * sin(ha), -r * cos(ha)), KNOB_BOX * 0.5)


## The sun stays where it is when the stick changes (the run is not started over): the shadow grows
## or shrinks under the same sun. The start keeps the stick too (처음으로 moves only the sun).
func set_control(id: String, value: Variant) -> void:
	if id != STICK_CONTROL:
		super(id, value)
		return
	_controls[id] = value
	_apply_control(id, value)
	if is_inside_tree():
		_show()
	_update_status(true)


func _apply_control(id: String, value: Variant) -> void:
	if id == STICK_CONTROL:
		var height := ShadowClockModel.LONG_STICK if str(value) == "long" else ShadowClockModel.SHORT_STICK
		model.set_start("stick", height)
		model.set_input("stick", height)
		return
	super(id, value)


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var sun := model as ShadowClockModel
	props.show(world_of(sun.sky_direction() * ShadowClockProps.SKY_RADIUS), sun.input("stick"),
		world_of(sun.shadow_tip()) if sun.has_shadow() else ShadowClockProps.STICK_AT, sun.status())


## The shadow in words (the key card), the sun's height and the shadow's length. No clock time.
func observations() -> Dictionary:
	var sun := model as ShadowClockModel
	return {
		"state": {
			"noon": Locale.t("shadow_clock.status.noon"),
			"morning": Locale.t("shadow_clock.status.morning"),
			"afternoon": Locale.t("shadow_clock.status.afternoon"),
			"bed": Locale.t("shadow_clock.status.bed"),
			"stone": Locale.t("shadow_clock.status.stone"),
		}.get(sun.status(), ""),
		"altitude": sun.sun_altitude(),
		"shadow": sun.shadow_length(),
	}


## The shadow's length (m) against the sun's height (deg) for the short and the long stick, over the
## heights of the sun's path, and where it is now.
func graph_series() -> Dictionary:
	var sun := model as ShadowClockModel
	if _curves.is_empty():
		for pair: Array in [["short", ShadowClockModel.SHORT_STICK], ["long", ShadowClockModel.LONG_STICK]]:
			var stick: float = pair[1]
			var curve := PackedVector2Array()
			var alt := ShadowClockModel.PATH_MIN_ALTITUDE
			while alt <= sun.noon_sun_altitude() + 1e-9:
				curve.append(Vector2(alt, SunModel.shadow_length_of(stick, alt)))
				alt += GRAPH_STEP_DEG
			_curves[pair[0]] = curve
	return {"short": _curves["short"], "long": _curves["long"], "now": PackedVector2Array([Vector2(sun.sun_altitude(), sun.shadow_length())])}


func graph_revision() -> int:
	var now := Vector2(model.input("rotation"), model.input("stick"))
	if now != _graph_key:
		_graph_key = now
		_graph_revision += 1
	return _graph_revision


## The next stage goes on from where the sun was put (the noon sun, then the morning, then on).
func keeps_run_between_stages() -> bool:
	return true


## Dugi points at the stick.
func explain_point() -> Vector3:
	return props.stick.global_position + Vector3.UP * 0.5


## The camera follows the yard (the stick's foot).
func follow_point() -> Vector3:
	return ShadowClockProps.STICK_AT
