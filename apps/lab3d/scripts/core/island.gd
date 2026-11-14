## An island's layout as data (ADR 0003: one island per science field). The map home
## (IslandHomeScreen), the title's island, the labs' worlds (LabWorld), MapIsland's shape and the
## story's exploration (Story) read it: the zones and their spots, the cat's square, the dirt paths,
## the coast, the decoration, which way a lab looks when not towards the square, the spot where the
## star pieces gather and the order the spots are found in. The words are not here.
##
## The islands are listed in content/islands/index.json (#69, 2026-11-06): in order, each with its
## layout file, the island it opens after (every spot of that one complete, computed from the stamps:
## nothing is saved for it) and its product (ADR 0005, #77: IslandStore; an island not bought opens one
## new spot a day, DailyLimit). `current()` is the island in use: the one saved in the progress
## ([map] island) when it is open, else the first.
##
## An island in the making (#72, 2026-11-06: the hutton island's map before its experiments): its spots
## are laid out but not every spot is an experiment yet (`playable()` false). It never opens in the
## child's app (is_open), whatever the island before it; a developer sees its map with
## --island=<id> (App: this run only, nothing saved, no story, the bench store; never in the Play
## build). Before such an island becomes playable its `product` must be set (#77): else it would have
## no day limit.
class_name Island
extends RefCounted

const ROOT := "res://content/islands"
const INDEX_PATH := "res://content/islands/index.json"
const GROUNDS := ["meadow", "hill", "yard", "pond", "coast", "valley"]
## The lookout may be the cat's square instead of a spot (the hutton island's sundial, #72).
const HOME := "home"
## The pieces an island's spots give (#101, PieceArt): the guiding star's (the default) or the
## sundial's golden wedges (the hutton island).
const PIECE_STAR := "star"
const PIECE_SUNDIAL := "sundial"
const PIECES := [PIECE_STAR, PIECE_SUNDIAL]

## Zone id -> {ground (GROUNDS: the hutton island adds coast and valley, #72), look (the lab ground's look; default the ground), at [x, z], radius or
## size [w, d], height (hills; the valley's rise), spots [[experiment id, [x, z], landmark yaw deg], ...]}, in the
## map's order.
var zones: Dictionary = {}
var home := Vector2.ZERO
var paths: Array = []
## The coast: an ellipse plus harmonics [order, m, phase] and bumps [angle deg, m, width deg].
var radius_x := 0.0
var radius_z := 0.0
var coast_waves: Array = []
var coast_bumps: Array = []
## A flask's neck out of the coast (curie, 2026-11-13 user "섬 모양 자체를 플라스크로"): [angle deg,
## width m, length m from the centre]; straight sides, the mouth at its end. And the top grid's
## sectors round the island (more for a neck, so its sides stay straight; default MapIsland.SECTORS).
var coast_necks: Array = []
var coast_sectors := 0
const MIN_SECTORS := 24     # fewer and the coast is a polygon
const MAX_SECTORS := 240    # more costs the map's one mesh for nothing seen
var trees: Array = []        # [x, z, size]
var rocks: Array = []        # [x, z, radius]
var clouds: Array = []       # [x, y, z, size]
var far_clouds: Array = []   # [angle deg, distance, height, size]
var sea_waves: Array = []    # [angle deg, distance, size]
var lab_facing: Dictionary = {}   # experiment id -> map angle deg of the lab's front
## Where the story's pieces gather: a spot id, or HOME (the square).
var lookout := ""
## The piece each spot gives (PIECES; "star" when the file has none): PieceArt draws it.
var piece := PIECE_STAR
## The island's keeper who walks with the trio on its map and stands in its labs ("" for none; "fox":
## the hutton island's, 2026-11-11 user: "실험 간 이동할때도 여우친구가 있어야지. 길잡이니까").
var keeper := ""
## The island's own landforms and buildings (#72), each optional: volcano {at [x, z], radius, height}
## (a cone, the valley's ground rising to it), river [[x, z], ...] (from its source to past the coast),
## lighthouse [x, z], sundial true (on the square). The curie island's (2026-11-13): lighthouse_rainbow
## true (MapLandmarks.lighthouse rainbow, on the flask's rock lip when it is at a neck's mouth), houses
## [[x, z, yaw deg], ...] (the kitchen village), potions [[x, z, size], ...] (bottles in the grass),
## washing [x, z] (the spring's washing place, facing the pond). Read by MapIsland and LabWorld; {}
## on the mechanics island.
var features: Dictionary = {}
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
## Every island of the list is open, in the making or not (the developer switch --islands=open, #75:
## App sets it for the run, never in the Play build; the voyage demo and tests too): set_dev_open.
static var _dev_open := false


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


## Every island open for this run (`on`) or as the progress says (the only way to change it).
static func set_dev_open(on: bool) -> void:
	_dev_open = on


static func dev_open() -> bool:
	return _dev_open


## The island `island_id` opens after ("" for the first).
static func opens_after(island_id: String) -> String:
	return str(entry(island_id).get("opens_after", ""))


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
		if island.problem != "" and (e.has("file") or e.is_empty()):   # (a listed entry with no map file yet is an island in the making, not an error)
			push_error("Island %s: %s" % [island_id, island.problem])
		_islands[island_id] = island
	return _islands[island_id]


## The island in use: the one saved in the progress when it is in the list, else the first.
static func current_id() -> String:
	if _current_id == "":
		var saved := ProgressStore.current_island()
		var all := ids()
		# A saved island that is not open (#77: a hand-edited or restored save) is not the island in use.
		var usable := saved in all and (saved == str(all[0]) or is_open(saved, ProgressStore.load()))
		_current_id = saved if usable else (str(all[0]) if not all.is_empty() else "")
	return _current_id


static func current() -> Island:
	return by_id(current_id())


## The child goes to `island_id`: saved, so the app opens there next time.
static func set_current(island_id: String) -> void:
	_current_id = island_id
	ProgressStore.set_current_island(island_id)


## A developer's look at `island_id` (--island=<id>, captures, tests): the island in use for this run
## only, nothing saved (the child's island stays as it was).
static func use_for_run(island_id: String) -> void:
	_current_id = island_id


## The island in use is read from the progress again on the next use (tests, a reset progress).
static func forget_current() -> void:
	_current_id = ""


## `island_id` is open when it is playable (every spot an experiment): the first island then always;
## another when every spot of the island it opens after is complete. An unknown island never is.
static func is_open(island_id: String, progress: Dictionary) -> bool:
	if _dev_open and not entry(island_id).is_empty():
		return true
	if entry(island_id).is_empty() or not by_id(island_id).playable():
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
	island.coast_necks = _array(coast.get("necks"))
	island.coast_sectors = int(coast.get("sectors", 0))
	island.trees = _array(data.get("trees"))
	island.rocks = _array(data.get("rocks"))
	island.clouds = _array(data.get("clouds"))
	island.far_clouds = _array(data.get("far_clouds"))
	island.sea_waves = _array(data.get("sea_waves"))
	island.lab_facing = _dict(data.get("lab_facing"))
	island.lookout = str(data.get("lookout", ""))
	island.piece = str(data.get("piece", PIECE_STAR))
	island.keeper = str(data.get("keeper", ""))
	island.features = _dict(data.get("features"))
	island.order = _array(data.get("order")).filter(func(id: Variant) -> bool: return id is String)
	island.problem = island._check()
	return island


## The island has the sundial on its square (features.sundial).
func has_sundial() -> bool:
	return features.get("sundial", false) == true


## Every spot is an experiment (ExperimentRegistry): false for an island in the making, whose
## spots are only places on its map (#72).
func playable() -> bool:
	return problem == "" and spots().all(func(spot: String) -> bool: return not ExperimentRegistry.find(spot).is_empty())


## The spots as MapIsland.build takes them, in the map's order: [[id, Vector2 at, landmark yaw deg], ...].
func map_spots() -> Array:
	var out := []
	for zone in zones:
		for spot in zones[zone].spots:
			out.append([spot[0], Vector2(spot[1][0], spot[1][1]), spot[2]])
	return out


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


## The sundial's wedges (#101): the first SUNDIAL_WEDGES spots of the order each give one; the next
## (the hutton island's last, the volcano) gives the gnomon (#106).
const SUNDIAL_WEDGES := 10


## The spot that gives the sundial's gnomon ("" on an island of star pieces, or with too few spots):
## its piece never flies on the map (it stands on the new land until the finale, #106).
func gnomon_spot() -> String:
	if piece != PIECE_SUNDIAL or order.size() <= SUNDIAL_WEDGES:
		return ""
	return str(order[SUNDIAL_WEDGES])


## What is wrong with the data ("" when nothing).
func _check() -> String:
	if zones.is_empty():
		return "no zones"
	if radius_x <= 0.0 or radius_z <= 0.0:
		return "no coast"
	for neck: Variant in coast_necks:
		if not _numbers(neck, 3) or float(neck[1]) <= 0.0 or float(neck[2]) <= maxf(radius_x, radius_z):
			return "coast: a neck is not [angle, width, length past the coast]"
	if coast_sectors != 0 and (coast_sectors < MIN_SECTORS or coast_sectors > MAX_SECTORS):
		return "coast: sectors not %d..%d" % [MIN_SECTORS, MAX_SECTORS]
	for zone in zones:
		var spec: Variant = zones[zone]
		if not spec is Dictionary or str(spec.get("ground", "")) not in GROUNDS or _array(spec.get("at")).size() != 2 \
				or not spec.get("spots") is Array:
			return "zone %s: ground, at or spots" % zone
		if (spec.spots as Array).is_empty():   # else complete() and playable() would hold for nothing
			return "zone %s has no spots" % zone
		if spec.ground in ["coast", "valley"] and float(spec.get("radius", 0.0)) <= 0.0:
			return "zone %s: a %s needs its radius" % [zone, spec.ground]
		for spot: Variant in spec.spots:
			if not spot is Array or spot.size() != 3 or not spot[0] is String or _array(spot[1]).size() != 2:
				return "zone %s: a spot is not [id, [x, z], yaw]" % zone
	if piece not in PIECES:
		return "piece %s is not one of %s" % [piece, ", ".join(PIECES)]
	var ids := spots()
	if lookout not in ids and lookout != HOME:
		return "lookout %s is not a spot or the square" % lookout
	var sorted_order := order.duplicate()
	sorted_order.sort()
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()
	if sorted_order != sorted_ids:
		return "order is not every spot once"
	return _check_features()


## What is wrong with `features` ("" when nothing): known keys only, each in its shape.
func _check_features() -> String:
	for key in features:
		var v: Variant = features[key]
		match key:
			"volcano":
				if not v is Dictionary or _array(v.get("at")).size() != 2 or float(v.get("radius", 0.0)) <= 0.0 \
						or float(v.get("height", 0.0)) <= 0.0:
					return "features.volcano: at [x, z], radius and height"
			"river":
				if not v is Array or v.size() < 2 or not v.all(func(p: Variant) -> bool: return _array(p).size() == 2):
					return "features.river: two or more [x, z] points"
			"lighthouse":
				if _array(v).size() != 2:
					return "features.lighthouse: [x, z]"
			"sundial", "lighthouse_rainbow":
				if not v is bool:
					return "features.%s: true or false" % key
			"houses", "potions":   # the curie island's (MapLandmarks.house, potion): [x, z, yaw] / [x, z, size]
				if not v is Array or not v.all(func(p: Variant) -> bool: return _numbers(p, 3)):
					return "features.%s: [x, z, n] each" % key
			"washing":
				if not _numbers(v, 2):
					return "features.washing: [x, z]"
			_:
				return "features.%s is not a feature" % key
	return ""


## True when `v` is an array of `n` numbers.
static func _numbers(v: Variant, n: int) -> bool:
	return v is Array and v.size() == n and v.all(func(x: Variant) -> bool: return x is float or x is int)


static func _dict(v: Variant) -> Dictionary:
	return v if v is Dictionary else {}


static func _array(v: Variant) -> Array:
	return v if v is Array else []
