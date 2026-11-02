## An island's layout as data (ADR 0003: one island per science field). The map home
## (IslandHomeScreen), the title's island, the labs' worlds (LabWorld), MapIsland's shape and the
## story's exploration (Story) read it: the zones and their spots, the cat's square, the dirt paths,
## the coast, the decoration, which way a lab looks when not towards the square, the spot where the
## star pieces gather and the order the spots are found in. The words are not here.
##
## There is one island now (the mechanics island, content/islands/mechanics.json); `current()` is it.
class_name Island
extends RefCounted

const CURRENT_PATH := "res://content/islands/mechanics.json"
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
var order: Array = []
## What is wrong with the file ("" when nothing): tests read it.
var problem := ""

static var _current: Island = null


static func current() -> Island:
	if _current == null:
		_current = load_file(CURRENT_PATH)
		if _current.problem != "":
			push_error("Island %s: %s" % [CURRENT_PATH, _current.problem])
	return _current


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


## The lab ground's look of `zone`: its `look`, else its ground.
func look_of(zone: String) -> String:
	var spec: Dictionary = zones.get(zone, {})
	return str(spec.get("look", spec.get("ground", "")))


## The look of a zone may also be "lookout" (LabWorld's railing over the sea).
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
