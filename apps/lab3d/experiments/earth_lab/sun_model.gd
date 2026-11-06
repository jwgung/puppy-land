## The sun seen from one place on the Earth (#70, 2026-11-06): the model the Hutton Island spots 낮과 밤,
## 그림자 시계 and 계절 share (docs/islands/hutton-missions.md 1-3). Inputs: the Earth's rotation (the
## time of day), its place on the orbit (the day of the year), the axial tilt and the latitude of the
## place; out of them the sun's altitude and azimuth there, day or night, the day length, and the
## shadow of an upright stick. Checked against textbook values: tests/earth_model_checks.gd,
## tests/earth_textbook_values.json.
##
## Model (decided 2026-11-06, the simplest one that gives the textbook numbers):
## - rotation is measured from the sun, not the stars: one rotation is one solar day of 24 h, the
##   sun is due south (north of the tropics) at local noon, rotation 180 deg. No time zone, no
##   equation of time: the hour is local solar time.
## - the orbit is a circle walked at an even pace: the sun's ecliptic longitude is the orbit angle
##   (0 = March equinox, 90 = June solstice, 180 = September equinox, 270 = December solstice) and
##   its declination is asin(sin tilt * sin orbit).
## - the sky frame of the place: x east, y up, z south (Godot's -z is north). Azimuth is degrees from
##   north towards east (N 0, E 90, S 180, W 270).
## - day and night: the sun's centre above the geometric horizon (altitude > 0). No refraction and no
##   sun's radius (2026-11-06 user decision: no almanac precision, no sunrise-time comparisons); the
##   day length is that geometric one.
## - a shadow needs the sun's centre above the ground (altitude > 0); its length is the stick's
##   height / tan(altitude), pointing away from the sun.
## Angles are degrees and every number is a 64-bit float (Vector3 is only for drawing).
class_name SunModel
extends EarthModel

const HOURS_PER_ROTATION := 24.0
const DEG_PER_HOUR := 360.0 / HOURS_PER_ROTATION
## The Earth's axial tilt (obliquity of the ecliptic, J2000: 23.439 deg).
const EARTH_TILT := 23.44
## The upright Earth of the 계절 spot's "똑바로" condition.
const UPRIGHT := 0.0
## Hutton Island's stand-in place: Seoul (37 deg 34 min N).
const SEOUL_LATITUDE := 37.57
## Within this many hours of the geometric sunrise (sunset) the sun is rising ("sunrise") or setting
## ("sunset"): the 낮과 밤 spot's morning band (#74, 2026-11-06 user decision: about 1 h either side of sunrise; the
## evening band of the same width is the stage's "그건 해 지는 쪽이야!" miss). Measured in hour angle
## from the sunrise's, so it is an hour at every latitude and season (an altitude band, 7.5 deg before
## #74, was about 40 minutes at Seoul). A polar day or night has no sunrise and no band.
const EDGE_HOURS := 1.0
## Glide rates (deg/s) when the lab shows a change happen (glide_to): a day in 4 s, a year in 6 s.
const ROTATION_RATE := 90.0
const ORBIT_RATE := 60.0
## Rotation at local solar noon (0 = midnight).
const NOON_ROTATION := 180.0



func _init() -> void:
	define_input("rotation", NOON_ROTATION, ROTATION_RATE, 360.0)   # deg, 0 = local midnight
	define_input("orbit", 0.0, ORBIT_RATE, 360.0)                   # deg, 0 = March equinox
	define_input("tilt", EARTH_TILT)                                # deg
	define_input("latitude", SEOUL_LATITUDE)                        # deg, north +
	define_input("stick", 1.0)                                      # m, the shadow stick's height


# --- pure functions -----------------------------------------------------------------------------

## Local solar time (h, [0, 24)) at Earth rotation `rotation` (deg, 0 = midnight).
static func hour_of(rotation: float) -> float:
	return fposmod(rotation, 360.0) / DEG_PER_HOUR


## The Earth rotation (deg, [0, 360)) at local solar time `hour`.
static func rotation_at(hour: float) -> float:
	return fposmod(hour * DEG_PER_HOUR, 360.0)


## The sun's hour angle (deg, [-180, 180): negative before noon) at Earth rotation `rotation`.
static func hour_angle(rotation: float) -> float:
	return fposmod(rotation - NOON_ROTATION + 180.0, 360.0) - 180.0


## The sun's declination (deg) at orbit angle `orbit` (deg from the March equinox) with axial tilt `tilt`.
static func declination(orbit: float, tilt: float) -> float:
	return rad_to_deg(asin(sin(deg_to_rad(tilt)) * sin(deg_to_rad(orbit))))


## The sun's altitude (deg above the horizon) at `latitude` for `decl` and hour angle `ha`.
static func altitude(latitude: float, decl: float, ha: float) -> float:
	var phi := deg_to_rad(latitude)
	var d := deg_to_rad(decl)
	var s := sin(phi) * sin(d) + cos(phi) * cos(d) * cos(deg_to_rad(ha))
	return rad_to_deg(asin(clampf(s, -1.0, 1.0)))


## The sun's azimuth (deg from north towards east, [0, 360)) at `latitude` for `decl` and hour angle `ha`.
static func azimuth(latitude: float, decl: float, ha: float) -> float:
	var phi := deg_to_rad(latitude)
	var d := deg_to_rad(decl)
	var h := deg_to_rad(ha)
	var east := -cos(d) * sin(h)
	var north := sin(d) * cos(phi) - cos(d) * cos(h) * sin(phi)
	return fposmod(rad_to_deg(atan2(east, north)), 360.0)


## The sun's altitude at local noon (deg; the highest of the day): 90 - |latitude - decl|.
static func noon_altitude(latitude: float, decl: float) -> float:
	return 90.0 - absf(latitude - decl)


## Hours of the day the sun's centre is above the geometric horizon (0 in a polar night, 24 in a
## polar day): cos H0 = -tan(latitude) tan(decl).
static func day_length(latitude: float, decl: float) -> float:
	var h0 := sunset_hour_angle(latitude, decl)
	if is_nan(h0):
		return 0.0 if sun_altitude_at_noon_below(latitude, decl) else HOURS_PER_ROTATION
	return 2.0 * h0 / DEG_PER_HOUR


## The hour angle (deg, 0..180) of the geometric sunset (the sunrise is at minus it): cos H0 =
## -tan(latitude) tan(decl). NAN in a polar day or night (the sun never crosses the horizon).
static func sunset_hour_angle(latitude: float, decl: float) -> float:
	var phi := deg_to_rad(latitude)
	var d := deg_to_rad(decl)
	var c := -sin(phi) * sin(d) / (cos(phi) * cos(d))
	if c >= 1.0 or c <= -1.0:
		return NAN
	return rad_to_deg(acos(c))


## The sun stays below the horizon all day (a polar night; else, without a sunset, a polar day).
static func sun_altitude_at_noon_below(latitude: float, decl: float) -> bool:
	return noon_altitude(latitude, decl) <= 0.0


## The shadow's length (m) of an upright stick `height` m tall with the sun at `altitude_deg`; INF
## when the sun is not above the ground.
static func shadow_length_of(height: float, altitude_deg: float) -> float:
	if altitude_deg <= 0.0:
		return INF
	return height / tan(deg_to_rad(altitude_deg))


# --- the place now ------------------------------------------------------------------------------

func hour() -> float:
	return hour_of(input("rotation"))


func sun_declination() -> float:
	return declination(input("orbit"), input("tilt"))


func sun_altitude() -> float:
	return altitude(input("latitude"), sun_declination(), hour_angle(input("rotation")))


func sun_azimuth() -> float:
	return azimuth(input("latitude"), sun_declination(), hour_angle(input("rotation")))


func noon_sun_altitude() -> float:
	return noon_altitude(input("latitude"), sun_declination())


## Hours of daylight of the day the orbit is at (sun's centre above the geometric horizon).
func day_hours() -> float:
	return day_length(input("latitude"), sun_declination())


func is_day() -> bool:
	return sun_altitude() > 0.0


## Before local noon (the sun climbing): the morning side of the Earth.
func is_morning() -> bool:
	return hour_angle(input("rotation")) < 0.0


## The stick casts a shadow: while it is day (the sun's centre above the ground).
func has_shadow() -> bool:
	return is_day()


## The stick's shadow length (m; INF without a shadow).
func shadow_length() -> float:
	return shadow_length_of(input("stick"), sun_altitude())


## The direction the shadow points (deg from north towards east): away from the sun.
func shadow_azimuth() -> float:
	return fposmod(sun_azimuth() + 180.0, 360.0)


## Unit vector towards the sun in the place's sky frame (x east, y up, z south). For drawing only.
func sky_direction() -> Vector3:
	var alt := deg_to_rad(sun_altitude())
	var az := deg_to_rad(sun_azimuth())
	return Vector3(cos(alt) * sin(az), sin(alt), -cos(alt) * cos(az))


## The shadow's tip on the ground from the stick's foot (sky frame, y = 0; zero without a shadow).
## For drawing only.
func shadow_tip() -> Vector3:
	if not has_shadow():
		return Vector3.ZERO
	var az := deg_to_rad(shadow_azimuth())
	var length := shadow_length()
	return Vector3(length * sin(az), 0.0, -length * cos(az))


## Hours from the geometric sunrise (before it: negative; the short way round the day, -12..12) and
## from the sunset; NAN in a polar day or night.
func hours_from_sunrise() -> float:
	return _hours_from(-sunset_hour_angle(input("latitude"), sun_declination()))


func hours_from_sunset() -> float:
	return _hours_from(sunset_hour_angle(input("latitude"), sun_declination()))


func _hours_from(event_hour_angle: float) -> float:
	if is_nan(event_hour_angle):
		return NAN
	return wrapf(hour_angle(input("rotation")) - event_hour_angle, -180.0, 180.0) / DEG_PER_HOUR


## "sunrise" / "sunset" (within EDGE_HOURS of the geometric sunrise / sunset), else "day" or "night"
## (the sun's centre above or below the horizon).
func status() -> String:
	if absf(hours_from_sunrise()) <= EDGE_HOURS:
		return "sunrise"
	if absf(hours_from_sunset()) <= EDGE_HOURS:
		return "sunset"
	return "day" if is_day() else "night"


## hour (h), altitude, azimuth, noon_altitude, declination (deg), day_length (h), the inputs orbit,
## tilt, latitude (deg) and stick (m), and with a shadow shadow_length (m) and shadow_azimuth (deg).
## A sun below the ground has no shadow numbers (a mission on them is not judged then).
func observations() -> Dictionary:
	var values := {
		"hour": hour(),
		"altitude": sun_altitude(),
		"azimuth": sun_azimuth(),
		"noon_altitude": noon_sun_altitude(),
		"declination": sun_declination(),
		"day_length": day_hours(),
		"orbit": input("orbit"),
		"tilt": input("tilt"),
		"latitude": input("latitude"),
		"stick": input("stick"),
	}
	if has_shadow():
		values["shadow_length"] = shadow_length()
		values["shadow_azimuth"] = shadow_azimuth()
	return values
