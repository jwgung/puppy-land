## The curie island (#151 the map of tickets, #152 its data and map): content/islands/curie.json reads
## (three zones: the kitchen village on a meadow, the spring village round its pond, the lighthouse
## hill; 12 spots in the story's order; the lighthouse), its map is laid out on land (every stage on
## the grass and out of the pond, 2.5 m apart, the paths on the grass, the trees and rocks clear),
## and while its spots are not labs yet it is an island in the making: never open, even after the
## hutton island, and its card says 곧 만나요 (docs/islands/curie.md). The island is a flask lying on its
## side (2026-11-13 user "섬 모양 자체를 플라스크로"): its neck reaches out to the mouth where the rainbow
## lighthouse stands on the rock lip, not on the sand; broken neck or village data says what is wrong.
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const PHONE := Vector2(1560, 720)
const ORDER := ["diffusion", "dissolving", "melt-cook", "dough", "clean-water", "soap", "cabbage", "tooth",
	"fizz", "candle", "rust", "flame-color"]
const ZONES := {"kitchen": "meadow", "spring": "pond", "lighthouse": "hill"}

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	check_data()
	check_in_making()
	check_flask()
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
		if not screen.in_making(spot):
			problems.append("%s is a lab already" % spot.id)
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
	expect.call(problems.is_empty(), "curie map: 12 stages on the grass, out of the pond, 2.5 m apart and not labs yet; the paths on the grass; trees and rocks clear; the lighthouse on the shore by the flame spot",
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
