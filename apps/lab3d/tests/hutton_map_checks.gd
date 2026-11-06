## The hutton island's map (#72, 2026-11-06 layout A): content/islands/hutton.json reads without a
## problem (its 11 spots, every one once in the order, the lookout on the square, its features), it
## never opens in the child's app while its spots are not experiments (Island.playable), its map
## builds like the mechanics one (one static island mesh and the sky, within the mechanics map's
## vertices) with its coast sand, valley, volcano, river, lighthouse and sundial placed clear of the
## spots, paths and the three friends, a tap on a spot opens nothing, and a lab on its coast or in its
## valley stands on that ground within the labs' budget. The mechanics island is unchanged: no
## features, the same checks as before (island_home_checks, lab_world_checks).
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const PHONE := Vector2(1560, 720)
const ORDER := ["day-night", "shadow-clock", "seasons", "water-cycle", "dew-cloud", "sea-breeze", "typhoon",
	"river", "strata", "earthquake", "volcano"]
const ZONES := {"hill": "hill", "coast": "coast", "valley": "valley"}
const LAB_VERTS_MAX := 30000   # lab_world_checks.VERTS_MAX

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH
	ProgressStore.reset_all()
	Island.use_index([])
	check_hutton_data()
	check_features_checked()
	check_never_opens()
	await check_hutton_map()
	await check_hutton_labs()
	ProgressStore.reset_all()
	Island.use_index([])
	Island.forget_current()
	ProgressStore.path = saved_path


## hutton.json: no problem, the three zones on their grounds, the 11 spots in the order (each once),
## the lookout on the square, the four features; the mechanics island has none.
func check_hutton_data() -> void:
	var island := Island.by_id("hutton")
	var problems := []
	if island.problem != "":
		problems.append(island.problem)
	if island.order != ORDER:
		problems.append("order %s" % str(island.order))
	var spots := island.spots()
	spots.sort()
	var want := ORDER.duplicate()
	want.sort()
	if spots != want:
		problems.append("spots %s" % str(island.spots()))
	for zone in ZONES:
		if not island.zones.has(zone) or island.zones[zone].ground != ZONES[zone]:
			problems.append("zone %s" % zone)
	if island.lookout != Island.HOME:
		problems.append("lookout %s (want the square)" % island.lookout)
	for key in ["volcano", "river", "lighthouse", "sundial"]:
		if not island.features.has(key):
			problems.append("no %s" % key)
	if not Island.by_id("mechanics").features.is_empty() or Island.by_id("mechanics").lookout != "orbit":
		problems.append("the mechanics island changed: features %s, lookout %s" % [str(Island.by_id("mechanics").features), Island.by_id("mechanics").lookout])
	expect.call(problems.is_empty(), "hutton island: content/islands/hutton.json reads (3 zones, 11 spots each once in the order, lookout on the square, volcano, river, lighthouse, sundial)",
		"; ".join(problems))


## A broken lookout or feature says what is wrong; the square is a lookout on any island.
func check_features_checked() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/islands/hutton.json"))
	var problems := []
	var broken := {
		"lookout nowhere": {"lookout": "nowhere"},
		"unknown feature": {"features": {"castle": [0.0, 0.0]}},
		"river of one point": {"features": {"river": [[0.0, 0.0]]}},
		"volcano without height": {"features": {"volcano": {"at": [0.0, -8.0], "radius": 2.0}}},
		"lighthouse not a point": {"features": {"lighthouse": 3.0}},
		"sundial not true/false": {"features": {"sundial": "yes"}},
	}
	for name in broken:
		var data := base.duplicate(true)
		data.merge(broken[name], true)
		if Island.from_data(data).problem == "":
			problems.append("%s reads without a problem" % name)
	var on_square: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/islands/mechanics.json"))
	on_square.lookout = Island.HOME
	if Island.from_data(on_square).problem != "":
		problems.append("the square as the mechanics lookout: %s" % Island.from_data(on_square).problem)
	expect.call(problems.is_empty(), "hutton island: a lookout that is not a spot or the square, and a broken feature, say what is wrong",
		"; ".join(problems))


## Its spots are not experiments yet: the island is not playable and never opens, even with every
## mechanics spot complete; the mechanics island is playable and open.
func check_never_opens() -> void:
	var full := {}
	for spot in Island.by_id("mechanics").spots():
		full[spot] = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
	var problems := []
	if Island.by_id("hutton").playable():
		problems.append("hutton is playable")
	if Island.is_open("hutton", full):
		problems.append("hutton opens after the mechanics island")
	if not Island.by_id("mechanics").playable() or not Island.is_open("mechanics", {}):
		problems.append("the mechanics island is not playable or not open")
	if str(Island.entry("hutton").get("opens_after", "")) != "mechanics":
		problems.append("hutton opens after %s" % str(Island.entry("hutton").get("opens_after", "")))
	# A developer's look: --island=<id> of a listed island (App), nothing for another.
	var app: GDScript = load("res://scripts/app/app.gd")
	if app.call("dev_island_of", PackedStringArray(["--island=hutton"])) != "hutton" or app.call("dev_island_of", PackedStringArray(["--island=atlantis"])) != "" \
			or app.call("dev_island_of", PackedStringArray([])) != "":
		problems.append("--island=<id> is not read")
	expect.call(problems.is_empty(), "hutton island: in the making (its spots are not experiments) it never opens in the app, even after the mechanics island; --island=hutton shows its map",
		"; ".join(problems))


## The map (--island=hutton): one static island mesh and the sky within the mechanics map's vertices,
## 11 spots apart on the grass and out of the water, paths on land and dry, decoration clear of the
## features and off the coast's sand, the volcano behind the island, the river from its foot downhill
## into the sea, the lighthouse on the beach, the sundial behind the three on the square; the spot
## names are the ids and a tap opens nothing.
func check_hutton_map() -> void:
	var mechanics_verts := await _map_vertices("mechanics")
	Island.use_for_run("hutton")
	var screen := await _home(PHONE)
	var map: MapIsland = screen.map
	var problems := []
	var world: Node3D = screen.find_child("IslandHome", true, false)
	var statics: Array = world.get_children().filter(func(n: Node) -> bool: return n is MeshInstance3D).map(func(n: Node) -> String: return str(n.name))
	statics.sort()
	if statics != ["Island", "MapSky"]:
		problems.append("static map meshes %s" % str(statics))
	var verts := _vertices(world.find_child("Island", true, false))
	if verts > mechanics_verts:
		problems.append("%d vertices (the mechanics map has %d)" % [verts, mechanics_verts])
	if screen._spots.size() != 11:
		problems.append("%d spots" % screen._spots.size())
	var edge := MapIsland.grass_edge()
	var on_grass := func(p: Vector2, margin: float) -> bool: return p.length() + margin <= edge * map.coast_radius(atan2(p.y, p.x))
	for spot in screen._spots:
		var at := Vector2(spot.at.x, spot.at.z)
		var stand := Vector2(spot.stand.x, spot.stand.z)
		if not on_grass.call(at, float(spot.radius)) or map.water_at(at.x, at.y) or map.water_at(stand.x, stand.y):
			problems.append("%s stage past the grass or in water" % spot.id)
		if map.river_distance(at.x, at.y) < float(spot.radius) + 0.2:
			problems.append("%s stage on the river" % spot.id)
		if at.distance_to(Vector2(map.island.features.volcano.at[0], map.island.features.volcano.at[1])) < float(map.island.features.volcano.radius) + float(spot.radius):
			problems.append("%s stage on the volcano" % spot.id)
		for other in screen._spots:
			if other.id != spot.id and at.distance_to(Vector2(other.at.x, other.at.z)) < 2.5:
				problems.append("%s and %s closer than 2.5 m" % [spot.id, other.id])
		var label: Label = _find_label(screen._labels.get(spot.id))
		if label == null or label.text != spot.id:
			problems.append("%s's name %s (want its id: no experiment yet)" % [spot.id, label.text if label != null else "none"])
	for q in map.path_points:
		if not on_grass.call(q, MapIsland.PATH_WIDTH * 0.5) or map.water_at(q.x, q.y):
			problems.append("path point %s off the grass or in the river" % str(q))
			break
	var trees := 0
	for d in map.decorations:
		trees += 1 if d[0] == "tree" else 0
		if not map._features_clear(Vector2(d[1], d[2]), 0.0) or map.water_at(d[1], d[2]):
			problems.append("%s at (%.1f, %.1f) on a feature" % [d[0], d[1], d[2]])
		var coast: Dictionary = map.zones.coast
		if MapIsland.in_ground(Vector2(d[1], d[2]), Vector2(coast.at[0], coast.at[1]), float(coast.radius), "coast"):
			problems.append("%s at (%.1f, %.1f) on the coast's sand" % [d[0], d[1], d[2]])
	if trees < 6 or map.decorations.size() < 30:
		problems.append("%d trees, %d decorations (want a dressed island)" % [trees, map.decorations.size()])
	var volcano: Dictionary = map.island.features.volcano
	if float(volcano.at[1]) > -6.0:
		problems.append("the volcano is not behind the island")
	var source := map.river_points[0]
	var mouth := map.river_points[map.river_points.size() - 1]
	if map.coast_fraction(mouth.x, mouth.y) < 1.0 or source.distance_to(Vector2(volcano.at[0], volcano.at[1])) > float(volcano.radius) + 0.5:
		problems.append("the river does not run from the volcano's foot into the sea")
	var downhill := true
	for k in range(4, map.river_points.size(), 4):
		var a := map.river_points[k - 4]
		var b := map.river_points[k]
		downhill = downhill and map.height_at(b.x, b.y) <= map.height_at(a.x, a.y) + 0.02
	if not downhill:
		problems.append("the river runs uphill")
	var light: Array = map.island.features.lighthouse
	var light_f := map.coast_fraction(float(light[0]), float(light[1]))
	if light_f < edge or light_f > MapIsland.SHORE_F:
		problems.append("the lighthouse is not on the beach (%.2f of the coast)" % light_f)
	var dial: Dictionary = map.home_lookout()
	if dial.top < 0.5 or Vector2(dial.at.x, dial.at.z).distance_to(map.home) > MapIsland.PLAZA_RADIUS:
		problems.append("the sundial is not on the square (%s)" % str(dial))
	for actor: Node3D in screen.trio():
		if Vector2(actor.position.x, actor.position.z).distance_to(Vector2(dial.at.x, dial.at.z)) < 0.85:
			problems.append("%s stands in the sundial" % actor.name)
	# A tap on a spot with no experiment: a shake, no walk, nothing opened.
	var opened := []
	screen.experiment_chosen.connect(func(d: Dictionary) -> void: opened.append(d))
	screen._walk_to_spot(0)
	if screen._walking or not opened.is_empty():
		problems.append("a tap walks or opens something")
	expect.call(problems.is_empty(), "hutton map: 1 island mesh + sky (no more vertices than the mechanics map), 11 spots clear, coast sand, valley, volcano, river to the sea, lighthouse, sundial; a tap opens nothing",
		"; ".join(problems.slice(0, 8)) if not problems.is_empty() else "%d vertices (mechanics %d), %d trees, %d decorations" % [verts, mechanics_verts, trees, map.decorations.size()])
	await _free(screen)
	Island.forget_current()


## A lab on the coast and one in the valley: their world is one mesh within the labs' vertices, flat
## at y = 0 round the lab, on the coast's sand / the valley's grass, and the valley's far ground rises
## to the volcano standing beyond the clearing.
func check_hutton_labs() -> void:
	Island.use_for_run("hutton")
	for setup in [["sea-breeze", "coast", ArtPalette.SAND], ["strata", "valley", ArtPalette.VALLEY], ["volcano", "valley", ArtPalette.VALLEY]]:
		var holder := Node3D.new()
		tree.root.add_child(holder)
		var world := LabWorld.new(setup[0], Vector3.ZERO)
		world.build(holder)
		var problems := []
		var meshes := holder.get_children().filter(func(n: Node) -> bool: return n is MeshInstance3D)
		if meshes.size() != 1 or meshes[0].name != "Island":
			problems.append("meshes %s" % str(meshes.map(func(n: Node) -> String: return str(n.name))))
		var verts := _vertices(meshes[0]) if not meshes.is_empty() else 0
		if verts > LAB_VERTS_MAX:
			problems.append("%d vertices (max %d)" % [verts, LAB_VERTS_MAX])
		if world.theme != setup[1]:
			problems.append("theme %s" % world.theme)
		if world.ground_color(Vector2(0.3, 0.2)) != setup[2]:
			problems.append("ground %s" % str(world.ground_color(Vector2(0.3, 0.2))))
		var worst := 0.0
		for i in 12:
			worst = maxf(worst, absf(world.ground_y(Vector2.from_angle(TAU * i / 12.0) * ArtKit.ISLAND_RADIUS * 0.9)))
		if worst > 0.002:
			problems.append("the clearing is not flat (%.3f m)" % worst)
		if setup[1] == "valley":
			var volcano: Array = world.far_things.filter(func(f: Array) -> bool: return f[0] == "volcano")
			if volcano.is_empty():
				problems.append("no volcano")
			elif Vector2(volcano[0][1], volcano[0][2]).length() < LabWorld.CLEAR + LabWorld.BLEND + float(volcano[0][3]) - 0.01:
				problems.append("the volcano stands in the clearing")
			var up := world.to_lab(Vector2(map_volcano()[0], map_volcano()[1]))
			if world.ground_y(up.normalized() * 16.0) <= 0.0:
				problems.append("the ground does not rise towards the volcano")
		expect.call(problems.is_empty(), "hutton lab world (%s): one mesh within %d vertices, flat at y = 0, on the %s's ground%s" % [setup[0], LAB_VERTS_MAX, setup[1], ", rising to the volcano" if setup[1] == "valley" else ""],
			"; ".join(problems) if not problems.is_empty() else "%d vertices" % verts)
		holder.queue_free()
		await tree.process_frame
	Island.forget_current()


static func map_volcano() -> Array:
	return Island.by_id("hutton").features.volcano.at


func _map_vertices(island_id: String) -> int:
	Island.use_for_run(island_id)
	var screen := await _home(PHONE)
	var verts := _vertices(screen.find_child("Island", true, false))
	await _free(screen)
	Island.forget_current()
	return verts


static func _vertices(node: Node) -> int:
	var mesh: Mesh = (node as MeshInstance3D).mesh
	return (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()


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


func _find_label(node: Node) -> Label:
	if node == null:
		return null
	if node is Label:
		return node
	for child in node.get_children():
		var found := _find_label(child)
		if found != null:
			return found
	return null
