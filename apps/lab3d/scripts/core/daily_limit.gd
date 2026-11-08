## One new spot a day on an island not bought (#77, ADR 0005 3). The day's allowance goes on the
## first entry into a spot whose piece is not found yet: that spot and the device's date are kept
## ([day] <island>.spot / .date in the progress store). That spot opens again any time (the next day
## too); another unfound spot waits until the date is another one (forwards or back: the device's
## clock is trusted, ADR 0005). Found spots always open. A free, bought or developer-opened island
## (IslandStore.owns) has no limit.
class_name DailyLimit
extends RefCounted

## Tests: the day ("" = the device's date).
static var today_override := ""


## The device's local date (YYYY-MM-DD).
static func today() -> String:
	return today_override if today_override != "" else Time.get_date_string_from_system()


static func applies(island_id: String) -> bool:
	return not IslandStore.owns(island_id)


## The unfound spot `spot` of `island_id` opens today.
static func allows(island_id: String, spot: String) -> bool:
	if not applies(island_id):
		return true
	var used := ProgressStore.text(ProgressStore.DAY, "%s.spot" % island_id)
	return used == "" or used == spot or ProgressStore.text(ProgressStore.DAY, "%s.date" % island_id) != today()


## The child enters the unfound spot `spot`: today's allowance goes to it (once; its own spot again
## changes nothing).
static func use(island_id: String, spot: String) -> void:
	if not applies(island_id) or ProgressStore.text(ProgressStore.DAY, "%s.spot" % island_id) == spot:
		return
	ProgressStore.set_text(ProgressStore.DAY, "%s.spot" % island_id, spot)
	ProgressStore.set_text(ProgressStore.DAY, "%s.date" % island_id, today())
