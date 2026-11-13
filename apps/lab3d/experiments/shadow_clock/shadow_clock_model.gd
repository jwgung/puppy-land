## The 그림자 시계 spot's model (#86, 2026-11-07; docs/islands/hutton-missions.md 2): SunModel for the
## shadow yard on Hutton Island (Seoul's latitude) at the March equinox, the sun moved along its sky
## path by the child's hand (the input `rotation`: the hour), the stick short or long (the input
## `stick`, the condition button).
##
## The equinox keeps the picture simple: the sun rises due east, crosses the south and sets due west,
## its path is one tilted half-circle, and the stick's shadow tip runs along one straight east-west
## line north of the stick (a stick of height h: h tan(latitude) north of its foot). The two targets
## lie on those lines:
## - the flower bed (stage 2) west of the stick, where the SHORT stick's tip is with the morning sun
##   BED_HOURS from noon (low in the east);
## - the far stone (stage 3) east of it, where the LONG stick's tip is with the afternoon sun
##   STONE_HOURS from noon.
## The short stick's tip line never comes within STONE_REACH of the stone (nor the long one's within
## BED_REACH of the bed): "짧은 막대로는 어떤 해 높이로도 안 닿음".
##
## status() (judged by MissionRound, never shown as a number): "bed" (the shadow's tip within
## BED_REACH of the bed's middle), "stone" (within STONE_REACH of the stone's middle), "noon" (within
## NOON_HOURS of local noon: the sun near due south, highest, the shadow shortest), else "morning"
## (the sun in the east: the shadow points west) or "afternoon" (the sun in the west: the shadow points
## east). The widths are generous for a child (each target is about an hour of the sun's path wide)
## and only judged: no clock time is on the screen (the user: no over-specified times).
class_name ShadowClockModel
extends SunModel

## The equinox (SunModel's orbit 0): the sun over the equator, the path a half-circle east-south-west.
const EQUINOX_ORBIT := 0.0
## The two sticks of the condition button (m).
const SHORT_STICK := 1.0
const LONG_STICK := 2.5
## The shortest shadow: the sun this close to local noon (h).
const NOON_HOURS := 1.0
## The flower bed: where the short stick's tip is with the sun this many hours from noon (morning:
## negative), and how far from that point the tip still touches it (m).
const BED_HOURS := -4.2
const BED_REACH := 0.7
## The far stone: where the long stick's tip is with the sun this many hours from noon (afternoon),
## and how far from that point the tip still touches it (m).
const STONE_HOURS := 2.8
const STONE_REACH := 0.6
## The sun's path ends this high over the ground (deg): the child can lay the sun low, never on the
## horizon (an endless shadow).
const PATH_MIN_ALTITUDE := 12.0
## The start (the fox: the shadows are a mess): the sun in the middle of the morning, its shadow
## pointing west but short of the bed.
const START_HOURS := -3.0


## Whether a stick `height` m tall is the long one (nearer the long stick than the short one).
static func is_long(height: float) -> bool:
	return height > (SHORT_STICK + LONG_STICK) * 0.5


func _init() -> void:
	super()   # SunModel declares the inputs
	set_start("orbit", EQUINOX_ORBIT)
	set_start("stick", SHORT_STICK)
	set_start("rotation", rotation_at(12.0 + START_HOURS))


## The tip of a stick `height` m tall at `latitude` for the sun at declination `decl` and hour angle
## `ha` (deg), from the stick's foot in the sky frame (x east, y 0, z south): SunModel's shadow.
static func tip_at(height: float, latitude: float, decl: float, ha: float) -> Vector3:
	var alt := altitude(latitude, decl, ha)
	var length := shadow_length_of(height, alt)
	if is_inf(length):
		return Vector3.ZERO
	var away := deg_to_rad(azimuth(latitude, decl, ha) + 180.0)
	return Vector3(length * sin(away), 0.0, -length * cos(away))


## The largest hour angle (deg) of the sun's path: where the sun is PATH_MIN_ALTITUDE high
## (cos H = (sin a - sin lat sin decl) / (cos lat cos decl)).
static func path_hour_angle(latitude: float, decl: float) -> float:
	var phi := deg_to_rad(latitude)
	var d := deg_to_rad(decl)
	var c := (sin(deg_to_rad(PATH_MIN_ALTITUDE)) - sin(phi) * sin(d)) / (cos(phi) * cos(d))
	return rad_to_deg(acos(clampf(c, -1.0, 1.0)))


## Hours from local noon, the short way round (-12..12; before noon negative).
func hours_from_noon() -> float:
	return hour_angle(input("rotation")) / DEG_PER_HOUR


## The rotation for the sun `hours` from noon, kept on the path (between its two low ends).
func rotation_on_path(hours: float) -> float:
	var limit := path_hour_angle(input("latitude"), sun_declination())
	return rotation_at(12.0 + clampf(hours * DEG_PER_HOUR, -limit, limit) / DEG_PER_HOUR)


## The flower bed's middle and the stone's middle (sky frame, from the stick's foot).
func bed_spot() -> Vector3:
	return tip_at(SHORT_STICK, input("latitude"), sun_declination(), BED_HOURS * DEG_PER_HOUR)


func stone_spot() -> Vector3:
	return tip_at(LONG_STICK, input("latitude"), sun_declination(), STONE_HOURS * DEG_PER_HOUR)


## The shadow's tip is within `reach` of `spot` (no shadow: never).
func tip_near(spot: Vector3, reach: float) -> bool:
	return has_shadow() and shadow_tip().distance_to(spot) <= reach


## "bed", "stone", "noon", else "morning" / "afternoon" (the sun's side of the sky).
func status() -> String:
	if tip_near(bed_spot(), BED_REACH):
		return "bed"
	if tip_near(stone_spot(), STONE_REACH):
		return "stone"
	var hours := hours_from_noon()
	if absf(hours) <= NOON_HOURS:
		return "noon"
	return "morning" if hours < 0.0 else "afternoon"
