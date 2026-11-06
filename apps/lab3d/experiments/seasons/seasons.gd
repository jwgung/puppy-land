## 계절 (#87, 2026-11-07; Hutton Island's third spot, docs/islands/hutton-missions.md 3 and
## hutton-lines.md 3): the sun stands in the middle of a small space stage and the tilted Earth goes
## round it on its path. The child drags the Earth along the path (a finger anywhere on the globe
## picks it; the Earth stays on its path at the finger's direction from the sun, no inertia, either
## way). The window high on the right shows Hutton Island's noon sky: the sun as high as the noon sun
## and the day's length as a bar (pictures and bars, no numbers). The condition button (왼쪽 아래)
## picks the axis: 기울어짐 (SunModel.EARTH_TILT) or 똑바로 (SunModel.UPRIGHT).
##
## Model: SeasonsModel (SunModel at Seoul's latitude). The lab only draws it (EarthLab): the stages
## are judged on its status ("winter", "summer", the upright "loop"; the misses on the other
## seasons and "upright"), never on a number on the screen.
##
## The hand: one knob ("earth"), a pickable box round the globe, dragged on the flat plane of the
## path (manipulation.objects[].surface "path": half the box under the path, where the Manipulator
## rests its centre on the path; no footprint marker). The orbit follows the knob's
## direction from the sun (SeasonsProps.orbit_of), so the Earth stays on its path wherever the finger
## goes; a put-down keeps the place (EarthLab.placements restores it), a cancel puts it back.
class_name SeasonsLab
extends EarthLab

const KNOB_ID := "earth"
## The knob's box round the globe (m beyond its radius) and the path's plane reach beyond the path.
const KNOB_MARGIN := 0.15
const REACH_OUT := 2.5
## The graph's year curve: one point per this many degrees of the path.
const GRAPH_STEP_DEG := 5.0
## The window's words for the noon sun and the day: "high" / "low" beyond this much from the
## equinox's (deg of noon altitude, hours of day), else "middle".
const SUN_WORD_DEG := 8.0
const DAY_WORD_HOURS := 0.7

var props := SeasonsProps.new()
var _surface: ManipSurface
var _graph_key := Vector2.INF
var _graph_revision := 0
var _year_curve := PackedVector2Array()
var _year_tilt := NAN


func _init() -> void:
	model = SeasonsModel.new()


func _build_world() -> void:
	props.build(self, model.input("latitude"))
	var side := (SeasonsProps.GLOBE_RADIUS + KNOB_MARGIN) * 2.0
	add_knob(KNOB_ID, "EarthKnob", side)
	# The Manipulator rests a knob's centre half its height over the surface: the surface is that much
	# under the path, so the knob's centre (and the finger's plane) is the path's.
	var reach := SeasonsProps.ORBIT_RADIUS + REACH_OUT
	_surface = ManipSurface.new(Transform3D(Basis(), SeasonsProps.SUN_CENTER + Vector3.DOWN * side * 0.5), Vector2(-reach, -reach), Vector2(reach, reach))
	game = SeasonsGame.new(self)
	add_child(game)
	game.build()


## The tilt condition: 기울어짐 or 똑바로 (the model's start: kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == "tilt":
		model.set_start("tilt", SunModel.EARTH_TILT if str(value) == "tilted" else SunModel.UPRIGHT)


# --- the knob -------------------------------------------------------------------------------------

func manipulation_surface(_surface_id: String) -> ManipSurface:
	return _surface


## The orbit for the knob at `xf`: its direction from the sun on the path's plane.
func _knob_inputs(_id: String, xf: Transform3D) -> Dictionary:
	return {"orbit": SeasonsProps.orbit_of(xf.origin)}


## The knob sits on the Earth (its centre on the path).
func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), SeasonsProps.earth_center(model.input("orbit")))


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as SeasonsModel
	props.show(m.input("orbit"), m.input("tilt"), m.noon_height_share(), m.day_share(), m.noon_sun_altitude())


## Words only (no degrees, no hours: the user): the season on Hutton Island, the noon sun's height
## and the day's length in a child's words.
func observations() -> Dictionary:
	var m := model as SeasonsModel
	var even := SunModel.noon_altitude(m.input("latitude"), 0.0)
	var noon := m.noon_sun_altitude() - even
	var day := m.day_hours() - SunModel.HOURS_PER_ROTATION * 0.5
	return {
		"state": {
			"winter": Locale.t("seasons.status.winter"),
			"spring": Locale.t("seasons.status.spring"),
			"summer": Locale.t("seasons.status.summer"),
			"autumn": Locale.t("seasons.status.autumn"),
			"upright": Locale.t("seasons.status.upright"),
			"loop": Locale.t("seasons.status.loop"),
		}.get(m.season(), ""),
		"sun": Locale.t("seasons.sun.high") if noon > SUN_WORD_DEG else Locale.t("seasons.sun.low") if noon < -SUN_WORD_DEG else Locale.t("seasons.sun.middle"),
		"day": Locale.t("seasons.day.long") if day > DAY_WORD_HOURS else Locale.t("seasons.day.short") if day < -DAY_WORD_HOURS else Locale.t("seasons.day.middle"),
	}


## The noon sun's height through one year on this axis (x: the path from the March equinox, deg) and
## where the Earth is now ("자세히": the window shows no number).
func graph_series() -> Dictionary:
	var m := model as SeasonsModel
	if m.input("tilt") != _year_tilt:
		_year_tilt = m.input("tilt")
		_year_curve = year_curve(_year_tilt, m.input("latitude"))
	return {"noon": _year_curve, "now": PackedVector2Array([Vector2(m.input("orbit"), m.noon_sun_altitude())])}


func graph_revision() -> int:
	var key := Vector2(model.input("orbit"), model.input("tilt"))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## The noon sun's altitude round the path (one year from the March equinox) on an axis of `tilt`.
static func year_curve(tilt: float, latitude: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var orbit := 0.0
	while orbit <= 360.0:
		out.append(Vector2(orbit, SunModel.noon_altitude(latitude, SunModel.declination(orbit, tilt))))
		orbit += GRAPH_STEP_DEG
	return out


## Dugi points at the Earth's island (the house on the globe).
func explain_point() -> Vector3:
	return props.house.global_position


## The camera follows the Earth.
func follow_point() -> Vector3:
	return props.earth.global_position
