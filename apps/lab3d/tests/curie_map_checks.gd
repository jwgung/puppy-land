## The curie island (#151 the map of tickets, #152 its data and map): content/islands/curie.json reads
## (three zones: the kitchen village on a meadow, the spring village round its pond, the lighthouse
## hill; 12 spots in the story's order; the lighthouse), its map is laid out on land (every stage on
## the grass and out of the pond, 2.5 m apart, the paths on the grass, the trees and rocks clear),
## and while its spots are not labs yet it is an island in the making: never open, even after the
## hutton island, and its card says 곧 만나요 (docs/islands/curie.md).
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
