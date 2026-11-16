## The curie island (#151 the map of tickets, #152 its data and map): content/islands/curie.json reads
## (three zones: the kitchen village on a meadow, the spring village round its pond, the lighthouse
## hill; 12 spots in the story's order; the lighthouse), its map is laid out on land (every stage on
## the grass and out of the pond, 2.5 m apart, the paths on the grass, the trees and rocks clear),
## and while its spots are not all labs yet (LABS: #156 the first) it is an island in the making: never
## open, even after the hutton island, and its card says 곧 만나요 (docs/islands/curie.md). The island is a flask (2026-11-13 user "섬 모양 자체를 플라스크로"): its neck reaches out to the mouth where the rainbow
## lighthouse stands on the rock lip, not on the sand; broken neck or village data says what is wrong.
## The flask lies at a slant (2026-11-16 user "방향을 좀 바꿔줄래? 비스듬하게", pick A): turn_deg -25
## turns the whole island, its neck up and to the right (away from the default view), nothing moved
## against anything else.
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const PHONE := Vector2(1560, 720)
const ORDER := ["diffusion", "dissolving", "melt-cook", "dough", "clean-water", "soap", "cabbage", "tooth",
	"fizz", "candle", "rust", "flame-color"]
const ZONES := {"kitchen": "meadow", "spring": "pond", "lighthouse": "hill"}
## The spots that are labs already (#156 on): the others are places in the making.
const LABS := ["diffusion"]
## The island's turn (curie.json turn_deg, 2026-11-16 user pick A): the flask's neck this far round from +x.
const TURN := -25.0

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	check_data()
	check_in_making()
	check_flask()
	check_turn()
	await check_map()
	Island.use_for_run(ProgressStore.FIRST_ISLAND)


func check_data() -> void:
	var island := Island.by_id("curie")
	var problems := []
	if island.problem != "":
		problems.append(island.problem)
	if island.order != ORDER:
		problems.append("order %s" % str(island.order))
	for zone in ZONES:
		if not island.zones.has(zone) or island.zones[zone].ground != ZONES[zone] or (island.zones[zone].spots as Array).size() != 4:
			problems.append("zone %s" % zone)
	if island.spots() != ORDER:
		problems.append("map order %s (zone by zone, as the story goes)" % str(island.map_spots()))
	if not island.features.has("lighthouse") or island.lookout != "flame-color":
		problems.append("lighthouse %s, lookout %s" % [str(island.features.get("lighthouse")), island.lookout])
	if Island.opens_after("curie") != "hutton":
		problems.append("opens after %s" % Island.opens_after("curie"))
	expect.call(problems.is_empty(), "curie island: content/islands/curie.json reads (kitchen meadow, spring pond, lighthouse hill: 4 spots each, 12 in the story's order, the lighthouse, pieces to the flame spot), after hutton",
		"; ".join(problems))


func check_flask() -> void:
	var problems := []
	var island := Island.by_id("curie")
	var map := MapIsland.new(island)
	if island.coast_necks.size() != 1:
		problems.append("necks %s" % str(island.coast_necks))
	else:
		var neck: Array = island.coast_necks[0]
		var dir := Vector2.from_angle(deg_to_rad(float(neck[0])))
		if not is_equal_approx(map.coast_radius(deg_to_rad(float(neck[0]))), float(neck[2])):
			problems.append("the coast along the neck is %.1f m, not its %.1f" % [map.coast_radius(deg_to_rad(float(neck[0]))), float(neck[2])])
		var light := Vector2(island.features.lighthouse[0], island.features.lighthouse[1])
		if map.neck_at(light).is_empty():
			problems.append("the lighthouse %s is not at the neck's mouth (on the lip)" % str(light))
		if not island.features.get("lighthouse_rainbow", false):
			problems.append("the lighthouse is not the rainbow one")
		var flame: Dictionary = {}
		for zone in island.zones:
			for spot in island.zones[zone].spots:
				if spot[0] == "flame-color":
					flame = {"at": Vector2(spot[1][0], spot[1][1])}
		if flame.is_empty() or flame.at.dot(dir) < map.coast_radius(deg_to_rad(float(neck[0])) + 0.5, false):
			problems.append("the flame spot is not out in the neck")
		if not map.on_neck_beach(dir * (float(neck[2]) - 3.0) + Vector2(-dir.y, dir.x) * (float(neck[1]) * 0.5 - 0.3)):
			problems.append("no beach along the neck's side")
	for other in ["mechanics", "hutton"]:
		var o := Island.by_id(other)
		if not o.coast_necks.is_empty() or MapIsland.new(o).sectors != MapIsland.SECTORS:
			problems.append("%s has a neck or other sectors" % other)
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/islands/curie.json"))
	var broken := {
		"a neck inside the coast": {"coast": {"necks": [[0.0, 6.0, 5.0]]}},
		"a neck angle not a number": {"coast": {"necks": [["east", 6.0, 25.0]]}},
		"too many sectors": {"coast": {"sectors": 100000}},
		"a house of two numbers": {"features": {"houses": [[1.0, 2.0]]}},
		"a potion size not a number": {"features": {"potions": [[1.0, 2.0, "big"]]}},
		"washing not a point": {"features": {"washing": ["here", 1.0]}},
		"rainbow not true/false": {"features": {"lighthouse_rainbow": "yes"}},
	}
	for name in broken:
		var data := base.duplicate(true)
		for key in broken[name]:
			(data[key] as Dictionary).merge(broken[name][key], true)
		var bad := Island.from_data(data)
		if bad.problem == "" or bad.playable():
			problems.append("%s reads without a problem" % name)
	expect.call(problems.is_empty(), "curie flask: the neck reaches its length, the rainbow lighthouse on the lip at its mouth, the flame spot out in the neck, a beach along its sides; the other islands keep their round coasts; a broken neck, sectors or village feature says what is wrong",
		"; ".join(problems))


func check_turn() -> void:
	var problems := []
	var island := Island.by_id("curie")
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/islands/curie.json"))
	var flat_data := base.duplicate(true)
	flat_data.turn_deg = 0.0
	var flat := Island.from_data(flat_data)
	var t := deg_to_rad(TURN)
	if not is_equal_approx(island.turn_deg, TURN) or island.coast_necks.size() != 1 or not is_equal_approx(float(island.coast_necks[0][0]), TURN):
		problems.append("turn %.1f, neck %s (not %.0f deg)" % [island.turn_deg, str(island.coast_necks), TURN])
	else:
		var mouth := Vector2.from_angle(deg_to_rad(float(island.coast_necks[0][0]))) * float(island.coast_necks[0][2])
		if mouth.x <= 0.0 or mouth.y >= 0.0:
			problems.append("the neck's mouth %s is not up and to the right" % str(mouth))
		var light := Vector2(island.features.lighthouse[0], island.features.lighthouse[1])
		if light.distance_to(mouth) > MapIsland.LIP_DEPTH * 2.0:
			problems.append("the lighthouse %s is not at the neck's end %s" % [str(light), str(mouth)])
	if flat.problem != "":
		problems.append("the island before the turn: %s" % flat.problem)
	# Every place is the unturned one turned (the distances between them kept), the yaws with it.
	var ours := island.map_spots()
	var theirs := flat.map_spots()
	var places := [[island.home, flat.home], [_v2(island.features.lighthouse), _v2(flat.features.lighthouse)], [_v2(island.features.washing), _v2(flat.features.washing)]]
	for i in ours.size():
		places.append([ours[i][1], theirs[i][1]])
		if not is_equal_approx(float(ours[i][2]), float(theirs[i][2]) - TURN):
			problems.append("%s yaw %.1f, not %.1f" % [ours[i][0], ours[i][2], float(theirs[i][2]) - TURN])
	for key in ["houses", "potions"]:
		for i in (island.features[key] as Array).size():
			places.append([_v2(island.features[key][i]), _v2(flat.features[key][i])])
	for i in island.trees.size():
		places.append([_v2(island.trees[i]), _v2(flat.trees[i])])
	for i in island.rocks.size():
		places.append([_v2(island.rocks[i]), _v2(flat.rocks[i])])
	for i in island.paths.size():
		for k in (island.paths[i] as Array).size():
			places.append([_v2(island.paths[i][k]), _v2(flat.paths[i][k])])
	for pair in places:
		if pair[0].distance_to(pair[1].rotated(t)) > 0.001:
			problems.append("%s is not %s turned" % [str(pair[0]), str(pair[1])])
	for i in places.size():
		for k in range(i + 1, places.size()):
			if absf(places[i][0].distance_to(places[k][0]) - places[i][1].distance_to(places[k][1])) > 0.001:
				problems.append("%s to %s changed with the turn" % [str(places[i][1]), str(places[k][1])])
	var map := MapIsland.new(island)
	var flat_map := MapIsland.new(flat)
	for i in 72:
		var a := TAU * i / 72.0
		if absf(map.coast_radius(a + t) - flat_map.coast_radius(a)) > 0.001:
			problems.append("the coast at %.0f deg is not the unturned one turned" % rad_to_deg(a))
			break
	var bad := base.duplicate(true)
	bad.turn_deg = "a lot"
	if Island.from_data(bad).problem == "":
		problems.append("turn_deg not a number reads without a problem")
	bad.turn_deg = 400.0
	if Island.from_data(bad).problem == "":
		problems.append("turn_deg past 180 reads without a problem")
	expect.call(problems.is_empty(), "curie turn: turn_deg %.0f turns the whole island (the neck at %.0f deg, its mouth up and to the right with the lighthouse at its end; every place, path, decoration, yaw and the coast the unturned one turned, the distances kept); a broken turn says what is wrong" % [TURN, TURN],
		"; ".join(problems.slice(0, 8)))


static func _v2(v: Array) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))


func check_in_making() -> void:
	var problems := []
	var island := Island.by_id("curie")
	var done := {}
	for id in Island.by_id("hutton").spots():
		done[id] = MissionRound.missions(ExperimentRegistry.find(id)).get("stages", []).size()
	if island.playable() or Island.is_open("curie", done):
		problems.append("open in the making (playable %s)" % island.playable())
	if IslandStore.product_of("curie") != "":
		problems.append("a product before it is playable: %s" % IslandStore.product_of("curie"))
	var entry := {}
	for e in IslandCards.entries({}):
		if str(e.id) == "curie":
			entry = e
	if entry.is_empty() or IslandCards.locked_line(entry) != Locale.t("islands.soon"):
		problems.append("its card %s" % (IslandCards.locked_line(entry) if not entry.is_empty() else "missing"))
	expect.call(problems.is_empty(), "curie island in the making: not playable, never open (also after hutton is done), no product yet, its card says 곧 만나요", "; ".join(problems))


func check_map() -> void:
	Island.use_for_run("curie")
	var screen := await _home(PHONE)
	var map: MapIsland = screen.map
	var problems := []
	if screen._spots.size() != 12:
		problems.append("%d spots" % screen._spots.size())
	var edge := MapIsland.grass_edge()
	var on_grass := func(p: Vector2, margin: float) -> bool: return p.length() + margin <= edge * map.coast_radius(atan2(p.y, p.x))
	for spot in screen._spots:
		var at := Vector2(spot.at.x, spot.at.z)
		var stand := Vector2(spot.stand.x, spot.stand.z)
		if not on_grass.call(at, float(spot.radius)) or map.water_at(at.x, at.y) or map.water_at(stand.x, stand.y):
			problems.append("%s stage past the grass or in water" % spot.id)
		for other in screen._spots:
			if other.id != spot.id and at.distance_to(Vector2(other.at.x, other.at.z)) < 2.5:
				problems.append("%s and %s closer than 2.5 m" % [spot.id, other.id])
		if screen.in_making(spot) == (spot.id in LABS):
			problems.append("%s is %s" % [spot.id, "not a lab yet" if spot.id in LABS else "a lab already"])
	for q in map.path_points:
		if not on_grass.call(q, MapIsland.PATH_WIDTH * 0.5) or map.water_at(q.x, q.y):
			problems.append("path point %s off the grass or in the pond" % str(q))
			break
	for d in map.decorations:
		if not map.features_clear(Vector2(d[1], d[2]), 0.0) or map.water_at(d[1], d[2]):
			problems.append("%s at (%.1f, %.1f) on a feature or in the pond" % [d[0], d[1], d[2]])
	var light: Array = map.island.features.lighthouse
	var light_f := map.coast_fraction(float(light[0]), float(light[1]))
	if light_f < edge or light_f > MapIsland.SHORE_F:
		problems.append("the lighthouse is not on the shore (%.2f of the coast)" % light_f)
	if Vector2(float(light[0]), float(light[1])).distance_to(Vector2(screen._spots[11].at.x, screen._spots[11].at.z)) > 4.0:
		problems.append("the lighthouse is not by the flame spot")
	await _free(screen)
	expect.call(problems.is_empty(), "curie map: 12 stages on the grass, out of the pond, 2.5 m apart, the labs so far (%s) labs and the others not yet; the paths on the grass; trees and rocks clear; the lighthouse on the shore by the flame spot" % ", ".join(LABS),
		"; ".join(problems.slice(0, 8)))


func _home(size: Vector2) -> Control:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load("res://scripts/app/island_home_screen.gd").new()
	host.add_child(screen)
	for i in 4:
		await tree.process_frame
	return screen


func _free(screen: Control) -> void:
	screen.get_parent().queue_free()
	for i in 3:
		await tree.process_frame
