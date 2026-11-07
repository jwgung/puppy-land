## The hutton island's map (#72, 2026-11-06 layout A): content/islands/hutton.json reads without a
## problem (its 11 spots, every one once in the order, the lookout on the square, its features), it
## never opens in the child's app while its spots are not experiments (Island.playable), its map
## builds like the mechanics one (one static island mesh and the sky, within the mechanics map's
## vertices) with its coast sand, valley, volcano, river, lighthouse and sundial placed clear of the
## spots, paths and the three friends, a tap on a spot in the making opens nothing (its first lab,
## day-night #74, is a lab), and a lab on its coast or in its
## valley stands on that ground within the labs' budget. The mechanics island is unchanged: no
## features, the same checks as before (island_home_checks, lab_world_checks).
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const PHONE := Vector2(1560, 720)
const ORDER := ["day-night", "shadow-clock", "seasons", "water-cycle", "dew-cloud", "sea-breeze", "typhoon",
	"river", "strata", "earthquake", "volcano"]
const ZONES := {"hill": "hill", "coast": "coast", "valley": "valley"}
## The hutton spots that are experiments so far (#74, #86, #87, #91, #92); the island opens when all are.
const EXPERIMENTS := ["day-night", "shadow-clock", "seasons", "water-cycle", "dew-cloud"]
const LAB_VERTS_MAX := 30000   # lab_world_checks.VERTS_MAX
## The mechanics island's map and two of its lab worlds (built at the origin) as they were before the
## hutton island (#72). The hutton features add nothing to an island without them; a change here must
## be intentional (update the pin with it). Positions only: a colour change is not seen here.
## The map: vertex count and the md5 of the exact position bytes (the same on CI).
const MECHANICS_MAP_PIN := [42426, "559a1fc33974ff848e90ad9c1883ed6d"]
## The lab worlds: their last float bits differ between machines (CI's md5 differed from a desktop's,
## 2026-11-06; LabWorld finds its coast by bisection, so a last-bit difference moves it by ~1e-5 m).
## So: vertex count exact, and per axis the sum of the coordinates, the sum of their squares and the
## bounding box, each within a tolerance. Measured noise (the coast bisection run 24 steps instead
## of 22, a few 1e-6 m): sums 0.007 m, squares 2.6 m2. Tolerances: LAB_SUM_TOL 0.5 m (about 1.7e-5 m
## a vertex over ~28,000; a landmark of 50+ vertices moved 1 cm along an axis exceeds it), LAB_SQ_TOL
## 50 m2 (about 20x the noise; such a move 30 m out changes it by 2 x 30 x 0.01 x 50 = 30 m2 or more,
## a ground height change by far more), LAB_BOX_TOL 1e-3 m.
const MECHANICS_LAB_PIN := {
	"orbit": {"n": 27702, "sum": [-610410.9302, -6257.6841, -570453.7574], "sq": [162201220.400, 2391417.034, 137194002.678],
		"lo": [-400.0, -65.7, -400.0], "hi": [400.0, 36.908, 400.0]},
	"buoyancy": {"n": 29406, "sum": [-231850.2907, 127951.7308, -791260.2850], "sq": [140852911.084, 3090117.197, 149193259.448],
		"lo": [-400.0, -60.6, -400.0], "hi": [400.0, 42.008, 400.0]},
}
const LAB_SUM_TOL := 0.5
const LAB_SQ_TOL := 50.0
const LAB_BOX_TOL := 1e-3

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
	check_paid_before_playable()
	await check_mechanics_pinned()
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
		"a zone with no spots": {"zones": {"hill": {"at": [0.0, 0.0], "ground": "hill", "radius": 2.0, "height": 1.0, "spots": []}}, "order": [], "lookout": "home"},
		"a coast without its radius": {"zones": {"coast": {"at": [0.0, 0.0], "ground": "coast", "spots": [["typhoon", [1.0, 1.0], 0.0]]}}, "order": ["typhoon"], "lookout": "home"},
	}
	for name in broken:
		var data := base.duplicate(true)
		data.merge(broken[name], true)
		var island := Island.from_data(data)
		if island.problem == "" or island.complete({}) or island.playable():
			problems.append("%s reads without a problem (or counts as complete)" % name)
	var on_square: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/islands/mechanics.json"))
	on_square.lookout = Island.HOME
	if Island.from_data(on_square).problem != "":
		problems.append("the square as the mechanics lookout: %s" % Island.from_data(on_square).problem)
	expect.call(problems.is_empty(), "hutton island: a lookout that is not a spot or the square, a broken feature, a zone with no spots or a coast without its radius say what is wrong (never complete or playable)",
		"; ".join(problems))


## ADR 0005: every island after the first is paid. An island with `opens_after` that is playable
## (every spot a lab, so it opens) must name its product: until the payment (#77) sets hutton's
## product, making the hutton island playable fails here instead of opening it for free.
func check_paid_before_playable() -> void:
	var problems := []
	for entry: Dictionary in Island.index():
		if str(entry.get("opens_after", "")) != "" and Island.by_id(str(entry.id)).playable() and str(entry.get("product", "")) == "":
			problems.append("%s is playable with no product (#77)" % entry.id)
	expect.call(problems.is_empty(), "islands: a later island (opens_after) is playable only with its product set (ADR 0005, the payment #77)", "; ".join(problems))


## Not every spot is an experiment yet (only EXPERIMENTS): the island is not playable and never
## opens, even with every mechanics spot complete; the mechanics island is playable and open.
func check_never_opens() -> void:
	var full := {}
	for spot in Island.by_id("mechanics").spots():
		full[spot] = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
	var problems := []
	var labs := Island.by_id("hutton").spots().filter(func(spot: String) -> bool: return not ExperimentRegistry.find(spot).is_empty())
	if labs != EXPERIMENTS:
		problems.append("the hutton spots that are experiments: %s (want %s)" % [str(labs), str(EXPERIMENTS)])
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
	if app.call("dev_island_of", PackedStringArray(["--island=hutton"]), false) != "hutton" or app.call("dev_island_of", PackedStringArray(["--island=atlantis"]), false) != "" \
			or app.call("dev_island_of", PackedStringArray([]), false) != "":
		problems.append("--island=<id> is not read")
	# ... and never in the Play build, nor the other developer switches (Quality.DEV_KEYS).
	if app.call("dev_island_of", PackedStringArray(["--island=hutton"]), true) != "":
		problems.append("--island=hutton opens in the Play build")
	for arg in ["--island=hutton", "--progress=complete", "--ask=show"]:
		var key: String = arg.trim_prefix("--").get_slice("=", 0)
		if Quality.dev_arg(PackedStringArray([arg]), key, true) != "" or Quality.dev_arg(PackedStringArray([arg]), key, false) != arg.get_slice("=", 1):
			problems.append("%s: Play build %s, dev build %s" % [arg, Quality.dev_arg(PackedStringArray([arg]), key, true), Quality.dev_arg(PackedStringArray([arg]), key, false)])
	if Quality.dev_arg(PackedStringArray(["--quality=low"]), "quality", false) != "":
		problems.append("--quality is read as a developer switch")
	expect.call(problems.is_empty(), "hutton island: in the making (its spots are not experiments) it never opens in the app, even after the mechanics island; --island=hutton shows its map (never in the Play build, nor --progress=complete or --ask=show)",
		"; ".join(problems))


## The mechanics map and lab worlds are what they were (MECHANICS_MAP_PIN, MECHANICS_LAB_PIN).
func check_mechanics_pinned() -> void:
	var problems := []
	Island.use_for_run("mechanics")
	var screen := await _home(PHONE)
	var map := _pin(screen.find_child("Island", true, false))
	if map != MECHANICS_MAP_PIN:
		problems.append("map %s (pinned %s)" % [str(map), str(MECHANICS_MAP_PIN)])
	await _free(screen)
	for lab in MECHANICS_LAB_PIN:
		var holder := Node3D.new()
		tree.root.add_child(holder)
		LabWorld.new(lab, Vector3.ZERO).build(holder)
		problems.append_array(_lab_pin_problems(lab, _lab_stats(holder.get_child(0)), MECHANICS_LAB_PIN[lab]))
		holder.queue_free()
		await tree.process_frame
	Island.forget_current()
	expect.call(problems.is_empty(), "mechanics island: its map (exact position md5) and lab worlds (vertex count, coordinate sums, squares and bounds within tolerance) are unchanged by the hutton features",
		"; ".join(problems))


## [vertex count, md5 of the exact position bytes].
static func _pin(node: Node) -> Array:
	var verts: PackedVector3Array = (node as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(verts.to_byte_array())
	return [verts.size(), ctx.finish().hex_encode()]


## A mesh's positions as {n, sum, sq, lo, hi}: per axis the sum of the coordinates and of their
## squares (64-bit, in vertex order) and the bounding box.
static func _lab_stats(node: Node) -> Dictionary:
	var verts: PackedVector3Array = (node as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var sum := [0.0, 0.0, 0.0]
	var sq := [0.0, 0.0, 0.0]
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for v in verts:
		for a in 3:
			sum[a] += v[a]
			sq[a] += v[a] * v[a]
		lo = lo.min(v)
		hi = hi.max(v)
	return {"n": verts.size(), "sum": sum, "sq": sq, "lo": [lo.x, lo.y, lo.z], "hi": [hi.x, hi.y, hi.z]}


static func _lab_pin_problems(lab: String, got: Dictionary, pin: Dictionary) -> Array:
	var out := []
	if got.n != pin.n:
		out.append("%s: %d vertices (pinned %d)" % [lab, got.n, pin.n])
	for a in 3:
		for check in [["sum", LAB_SUM_TOL], ["sq", LAB_SQ_TOL], ["lo", LAB_BOX_TOL], ["hi", LAB_BOX_TOL]]:
			var diff := absf(float(got[check[0]][a]) - float(pin[check[0]][a]))
			if diff > check[1]:
				out.append("%s: %s[%d] %.4f (pinned %.4f, off %.4f > %s)" % [lab, check[0], a, got[check[0]][a], pin[check[0]][a], diff, str(check[1])])
	return out


## The map (--island=hutton): one static island mesh and the sky within the mechanics map's vertices,
## 11 spots apart on the grass and out of the water, paths on land and dry, decoration clear of the
## features and off the coast's sand, the volcano behind the island, the river from its foot downhill
## into the sea, the lighthouse on the beach, the sundial behind the three on the square; the spot
## names are the ids (a lab's spot: its place name) and a tap opens nothing (a lab's spot: the cat walks there).
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
		var name: String = ExperimentRegistry.kid_text(ExperimentRegistry.find(spot.id), "place") if spot.id in EXPERIMENTS else spot.id
		if label == null or label.text != name:
			problems.append("%s's name %s (want %s)" % [spot.id, label.text if label != null else "none", name])
	for q in map.path_points:
		if not on_grass.call(q, MapIsland.PATH_WIDTH * 0.5) or map.water_at(q.x, q.y):
			problems.append("path point %s off the grass or in the river" % str(q))
			break
	var trees := 0
	for d in map.decorations:
		trees += 1 if d[0] == "tree" else 0
		if not map.features_clear(Vector2(d[1], d[2]), 0.0) or map.water_at(d[1], d[2]):
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
	for k in range(1, map.river_points.size()):
		var a := map.river_points[k - 1]
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
	# A tap on a spot with no experiment: a shake, no walk, nothing opened. A spot that is an
	# experiment (#74: day-night) is a lab: the cat walks there.
	var opened := []
	screen.experiment_chosen.connect(func(d: Dictionary) -> void: opened.append(d))
	for i in screen._spots.size():
		if not screen._spots[i].id in EXPERIMENTS:
			screen._walk_to_spot(i)
			if screen._walking or not opened.is_empty():
				problems.append("a tap on %s walks or opens something" % screen._spots[i].id)
			break
	var lab: int = screen._spots.map(func(spot: Dictionary) -> String: return spot.id).find(EXPERIMENTS[0])
	screen._walk_to_spot(lab)
	if not (screen._walking or not opened.is_empty()):
		problems.append("a tap on %s neither walks nor opens it" % EXPERIMENTS[0])
	expect.call(problems.is_empty(), "hutton map: 1 island mesh + sky (no more vertices than the mechanics map), 11 spots clear, coast sand, valley, volcano, river to the sea, lighthouse, sundial; a tap on a spot in the making opens nothing, the lab's spot (day-night) is a lab",
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
