## The 낮과 밤 spot's model (#74, 2026-11-06; docs/islands/hutton-missions.md 1): SunModel for the
## fox's house on Hutton Island (Seoul's latitude) at the March equinox, the Earth turned by the
## child's hand. Its status adds the two goals of the stages to SunModel's: "noon" (within NOON_HOURS
## of local noon: the house faces the sun) and "midnight" (within MIDNIGHT_HOURS of local midnight:
## the house faces away from it). SunModel's "sunrise" / "sunset" bands (EDGE_HOURS) come first, then
## noon and midnight, then "day" / "night". The judging widths are the user's (issue #74 decision 2:
## noon within about 1 h, night within about 3 h of midnight, the morning within about 1 h of sunrise) and are
## only judged, never shown: no clock time is on the screen (the user: no over-specified times).
class_name DayNightModel
extends SunModel

## The house faces the sun this close to local noon (h).
const NOON_HOURS := 1.0
## The house faces away from the sun this close to local midnight (h).
const MIDNIGHT_HOURS := 3.0
## The equinox: the sun over the equator, the day and the night 12 h each, the terminator through
## the poles (the simplest Earth to read; the axis still leans, towards the camera).
const EQUINOX_ORBIT := 0.0
## The start (the fox: the sun has not come up properly for days): a dark night before the dawn, past the
## midnight band, on the morning side (the house faces the camera; a turn the true way, west to
## east, brings it through the dawn to noon).
const START_HOUR := 3.5


func _init() -> void:
	super()   # SunModel declares the inputs
	set_start("orbit", EQUINOX_ORBIT)
	set_start("rotation", rotation_at(START_HOUR))


## Hours from local noon, the short way round (-12..12; before noon negative).
func hours_from_noon() -> float:
	return hour_angle(input("rotation")) / DEG_PER_HOUR


## "sunrise" / "sunset" (SunModel's bands), "noon", "midnight", else "day" / "night".
func status() -> String:
	var base := super()
	if base == "sunrise" or base == "sunset":
		return base
	var from_noon := absf(hours_from_noon())
	if from_noon <= NOON_HOURS:
		return "noon"
	if from_noon >= HOURS_PER_ROTATION * 0.5 - MIDNIGHT_HOURS:
		return "midnight"
	return base
