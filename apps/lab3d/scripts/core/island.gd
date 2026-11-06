## An island's layout as data (ADR 0003: one island per science field). The map home
## (IslandHomeScreen), the title's island, the labs' worlds (LabWorld), MapIsland's shape and the
## story's exploration (Story) read it: the zones and their spots, the cat's square, the dirt paths,
## the coast, the decoration, which way a lab looks when not towards the square, the spot where the
## star pieces gather and the order the spots are found in. The words are not here.
##
## The islands are listed in content/islands/index.json (#69, 2026-11-06): in order, each with its
## layout file, the island it opens after (every spot of that one complete, computed from the stamps:
## nothing is saved for it) and its product (ADR 0005; nothing reads it yet: the payment, #77). `current()` is the island in use: the one
## saved in the progress ([map] island), else the first.
class_name Island
extends RefCounted

const ROOT := "res://content/islands"
const INDEX_PATH := "res://content/islands/index.json"
const GROUNDS := ["meadow", "hill", "yard", "pond"]

## Zone id -> {ground, look (the lab ground's look; default the ground), at [x, z], radius or
## size [w, d], height (hills), spots [[experiment id, [x, z], landmark yaw deg], ...]}, in the
## map's order.
var zones: Dictionary = {}
var home := Vector2.ZERO
var paths: Array = []
## The coast: an ellipse plus harmonics [order, m, phase] and bumps [angle deg, m, width deg].
var radius_x := 0.0
var radius_z := 0.0
var coast_waves: Array = []
var coast_bumps: Array = []
var trees: Array = []        # [x, z, size]
var rocks: Array = []        # [x, z, radius]
var clouds: Array = []       # [x, y, z, size]
var far_clouds: Array = []   # [angle deg, distance, height, size]
var sea_waves: Array = []    # [angle deg, distance, size]
var lab_facing: Dictionary = {}   # experiment id -> map angle deg of the lab's front
var lookout := ""
## The island's id in the list ("" for an island read straight from data).
var id := ""
var order: Array = []
## What is wrong with the file ("" when nothing): tests read it.
var problem := ""

## The list's entries [{id, file, opens_after, product}] (read once; tests may set their own).
static var _index: Array = []
## The islands read so far, by id.
static var _islands: Dictionary = {}
## The island in use ("" until first asked: then read from the progress once, not per frame).
static var _current_id := ""


## The list's entries, in order (the file's, or the tests' list).
static func index() -> Array:
	if _index.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
		var islands: Variant = parsed.get("islands") if parsed is Dictionary else null
		_index = (islands as Array).filter(func(e: Variant) -> bool: return e is Dictionary and e.get("id") is String) \
				if islands is Array else []
		if _index.is_empty():
			push_error("Island: no islands in %s" % INDEX_PATH)
	return _index


## Tests: lay out their own list (an empty one: the file's again). The islands are read again.
static func use_index(entries: Array) -> void:
	_index = entries.duplicate(true)
	_islands = {}
	_current_id = ""


## The island ids, in the list's order.
static func ids() -> Array:
	return index().map(func(e: Dictionary) -> String: return str(e.id))


## The list's entry of `island_id` ({} when it is not an island).
static func entry(island_id: String) -> Dictionary:
	for e in index():
		if e.id == island_id:
			return e
	return {}


## The island `island_id` (read once; an unknown id reads as an island with a problem).
static func by_id(island_id: String) -> Island:
	if not _islands.has(island_id):
		var e := entry(island_id)
		var island := load_file(ROOT.path_join(str(e.file))) if e.has("file") else from_data({})
		island.id = island_id
		if island.problem != "":
			push_error("Island %s: %s" % [island_id, island.problem])
		_islands[island_id] = island
	return _islands[island_id]


## The island in use: the one saved in the progress when it is in the list, else the first.
static func current_id() -> String:
	if _current_id == "":
		var saved := ProgressStore.current_island()
		var all := ids()
		_current_id = saved if saved in all else (str(all[0]) if not all.is_empty() else "")
	return _current_id


static func current() -> Island:
	return by_id(current_id())


## The child goes to `island_id`: saved, so the app opens there next time.
static func set_current(island_id: String) -> void:
	_current_id = island_id
	ProgressStore.set_current_island(island_id)


## The island in use is read from the progress again on the next use (tests, a reset progress).
static func forget_current() -> void:
	_current_id = ""


## `island_id` is open: the first island always; another when every spot of the island it opens
## after is complete. An unknown island never is.
static func is_open(island_id: String, progress: Dictionary) -> bool:
	if entry(island_id).is_empty():
		return false
	var after := str(entry(island_id).get("opens_after", ""))
	return after == "" or by_id(after).complete(progress)


static func load_file(path: String) -> Island:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_data(parsed if parsed is Dictionary else {})


static func from_data(data: Dictionary) -> Island:
	var island := Island.new()
	island.zones = _dict(data.get("zones"))
	var at: Array = _array(data.get("home"))
	island.home = Vector2(float(at[0]), float(at[1])) if at.size() == 2 else Vector2.ZERO
	island.paths = _array(data.get("paths"))
	var coast := _dict(data.get("coast"))
	island.radius_x = float(coast.get("radius_x", 0.0))
	island.radius_z = float(coast.get("radius_z", 0.0))
	island.coast_waves = _array(coast.get("waves"))
	island.coast_bumps = _array(coast.get("bumps"))
	island.trees = _array(data.get("trees"))
	island.rocks = _array(data.get("rocks"))
	island.clouds = _array(data.get("clouds"))
	island.far_clouds = _array(data.get("far_clouds"))
	island.sea_waves = _array(data.get("sea_waves"))
	island.lab_facing = _dict(data.get("lab_facing"))
	island.lookout = str(data.get("lookout", ""))
	island.order = _array(data.get("order")).filter(func(id: Variant) -> bool: return id is String)
	island.problem = island._check()
	return island


## The spot ids in the map's order (zone by zone).
func spots() -> Array:
	var out := []
	for zone in zones:
		for spot in zones[zone].spots:
			out.append(spot[0])
	return out


## Every spot's stages are stamped (its piece found; an old save counts too). A broken island (no
## spots) never is: the island after it stays closed.
func complete(progress: Dictionary) -> bool:
	return problem == "" and found(progress).size() == spots().size()


## The spots whose every stage is stamped.
func found(progress: Dictionary) -> Array:
	return spots().filter(func(spot: String) -> bool:
		var stages: Array = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", [])
		return not stages.is_empty() and ProgressStore.stamps(progress, spot) >= stages.size())


## The lab ground's look of `zone`: its `look`, else its ground. The look of a zone may also be
## "lookout" (LabWorld's railing over the sea).
func look_of(zone: String) -> String:
	var spec: Dictionary = zones.get(zone, {})
	return str(spec.get("look", spec.get("ground", "")))


## What is wrong with the data ("" when nothing).
func _check() -> String:
	if zones.is_empty():
		return "no zones"
	if radius_x <= 0.0 or radius_z <= 0.0:
		return "no coast"
	for zone in zones:
		var spec: Variant = zones[zone]
		if not spec is Dictionary or str(spec.get("ground", "")) not in GROUNDS or _array(spec.get("at")).size() != 2 \
				or not spec.get("spots") is Array:
			return "zone %s: ground, at or spots" % zone
		for spot: Variant in spec.spots:
			if not spot is Array or spot.size() != 3 or not spot[0] is String or _array(spot[1]).size() != 2:
				return "zone %s: a spot is not [id, [x, z], yaw]" % zone
	var ids := spots()
	if lookout not in ids:
		return "lookout %s is not a spot" % lookout
	var sorted_order := order.duplicate()
	sorted_order.sort()
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()
	if sorted_order != sorted_ids:
		return "order is not every spot once"
	return ""


static func _dict(v: Variant) -> Dictionary:
	return v if v is Dictionary else {}


static func _array(v: Variant) -> Array:
	return v if v is Array else []
