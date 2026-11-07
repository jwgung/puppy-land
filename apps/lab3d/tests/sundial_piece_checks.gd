## The hutton island's pieces (#101, 2026-11-07 user decision B "금빛 부채꼴"): the island's `piece`
## (Island.piece, PieceArt) picks the piece everywhere it shows. The hutton island gives golden sundial
## wedges (SundialArt: a tenth of the round dial, 36°, standing on its point, two draws), the
## mechanics island the star as before. Every hutton lab's piece (LabGame.make_piece), the piece in
## the cat's paws and on the round-done card (ExperimentScreen, RoundDoneCard), the map's flying
## pieces and its corner emblem (StoryDirector: SundialEmblem, ten wedges and the gnomon's empty
## middle) and the island card's emblem (IslandCards) follow the island; the mechanics ones stay stars.
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const HOME_SCREEN := "res://scripts/app/island_home_screen.gd"
const PHONE := Vector2(1560, 720)

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
	check_data()
	check_wedge()
	check_emblem()
	await check_lab_pieces()
	await check_screen_piece_and_card()
	await check_map()
	await check_island_cards()
	ProgressStore.reset_all()
	Island.use_index([])
	Island.forget_current()
	ProgressStore.path = saved_path


func _is_sundial(node: Node) -> bool:
	var body := node.get_node_or_null("Shape/Body") as MeshInstance3D if node != null else null
	return body != null and body.mesh == SundialArt.piece_meshes()[0]


func _is_star_piece(node: Node) -> bool:
	var body := node.get_node_or_null("Shape/Body") as MeshInstance3D if node != null else null
	return body != null and body.mesh == StarArt.piece_meshes()[0]


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame
		await tree.process_frame


func _free(screen: Control) -> void:
	screen.get_parent().queue_free()
	for i in 3:
		await tree.process_frame


## The islands' pieces in their files: hutton sundial, mechanics star (none in its file), a wrong one
## is a problem; every hutton lab gives the sundial, every mechanics lab the star.
func check_data() -> void:
	var problems := []
	if Island.by_id("hutton").piece != PieceArt.SUNDIAL or Island.by_id("mechanics").piece != PieceArt.STAR:
		problems.append("pieces %s / %s" % [Island.by_id("hutton").piece, Island.by_id("mechanics").piece])
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Island.ROOT.path_join("hutton.json")))
	(data as Dictionary)["piece"] = "moon"
	if not "piece" in Island.from_data(data).problem:
		problems.append("an unknown piece is no problem")
	for d: Dictionary in ExperimentRegistry.island_labs("hutton"):
		if PieceArt.of_experiment(str(d.id)) != PieceArt.SUNDIAL:
			problems.append("%s gives %s" % [d.id, PieceArt.of_experiment(str(d.id))])
	for d: Dictionary in ExperimentRegistry.load_all():
		if PieceArt.of_experiment(str(d.id)) != PieceArt.STAR:
			problems.append("%s gives %s" % [d.id, PieceArt.of_experiment(str(d.id))])
	if ExperimentRegistry.island_labs("hutton").size() != 10:
		problems.append("%d hutton labs" % ExperimentRegistry.island_labs("hutton").size())
	expect.call(problems.is_empty(), "sundial piece: the hutton island's file gives the sundial piece, the mechanics island the star; every hutton lab gives the sundial, every mechanics lab the star", "; ".join(problems))


## The wedge: a tenth of the dial (36° at the point), the point 1 below the centre (it lands on it like
## the star), the arc on top, the band and the three hour lines inside the face, two draws.
func check_wedge() -> void:
	var problems := []
	var rim := SundialArt.rim()
	var low := 0.0
	var high := 0.0
	for p: Vector2 in rim:
		low = minf(low, p.y)
		high = maxf(high, p.y)
	if low < -1.0 or low > -0.94 or high < 1.3:
		problems.append("bottom %.3f, top %.3f" % [low, high])
	var apex := SundialArt.APEX
	var span := SundialArt.SPAN
	var corner := apex + Vector2(sin(deg_to_rad(18.0)), cos(deg_to_rad(18.0))) * span
	var near_corner := rim.any(func(p: Vector2) -> bool: return p.distance_to(corner) < 0.06)
	var beyond := rim.any(func(p: Vector2) -> bool:
		return absf(rad_to_deg((p - apex).angle_to(Vector2(0.0, 1.0)))) > 18.5 and (p - apex).length() > 0.2)
	if not near_corner or beyond:
		problems.append("not a 36° wedge (corner %s, wider %s)" % [near_corner, beyond])
	var face := SundialArt.shrunk(rim, SundialArt.SHRINK)
	var face_poly := PackedVector2Array(face)
	for pair: Array in SundialArt.hour_lines(SundialArt.SHRINK):
		for p: Vector2 in pair:
			if not Geometry2D.is_point_in_polygon(p, face_poly):
				problems.append("an hour line leaves the face")
	for p: Vector2 in SundialArt.band(face, SundialArt.SHRINK):
		if not Geometry2D.is_point_in_polygon(p * 0.999 + SundialArt.CENTRE * 0.001, face_poly):
			problems.append("the band leaves the face")
			break
	# The face (StarArt's eyes and cheeks at FACE_AT, FACE_K) inside the flat face.
	for x in [-1.0, 1.0]:
		var at := SundialArt.FACE_AT
		var k := SundialArt.FACE_K
		var cheek := at + Vector2(x * StarArt.EYE_X * 1.75, StarArt.EYE_Y - 0.13) * k
		var eye := at + Vector2(x * StarArt.EYE_X, StarArt.EYE_Y) * k
		for edge in [cheek + Vector2(x * StarArt.CHEEK_R * k, 0.0), eye + Vector2(0.0, StarArt.EYE_R * k)]:
			if not Geometry2D.is_point_in_polygon(edge, face_poly):
				problems.append("the face leaves the flat side at %s" % str(edge))
	var node := PieceArt.make(PieceArt.SUNDIAL, 0.5)
	var draws := node.find_children("*", "MeshInstance3D", true, false)
	var body: MeshInstance3D = node.get_node_or_null("Shape/Body")
	var outline: MeshInstance3D = node.get_node_or_null("Shape/Outline")
	if draws.size() != 2 or body == null or outline == null or body.material_override != StarArt.glow_material() \
			or outline.material_override != StarArt.outline_material() or not _is_sundial(node):
		problems.append("not two draws with the star's materials")
	elif not is_equal_approx((node.get_node("Shape") as Node3D).scale.x, 0.5):
		problems.append("size")
	var colours: PackedColorArray = (body.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR] if body != null else PackedColorArray()
	for want: Color in [SundialArt.FACE_3D, SundialArt.RIM_3D, SundialArt.LINE_3D, StarArt.FACE_INK, StarArt.CHEEK]:
		var lin := want.srgb_to_linear()
		if not Array(colours).any(func(c: Color) -> bool: return absf(c.r - lin.r) + absf(c.g - lin.g) + absf(c.b - lin.b) < 0.01):
			problems.append("no %s on the piece" % want.to_html(false))
	node.free()
	var star := PieceArt.make(PieceArt.STAR, 0.5)
	if not _is_star_piece(star) or star.name != "StarPiece":
		problems.append("the star kind is not StarArt's piece")
	star.free()
	expect.call(problems.is_empty(), "sundial piece: a 36° wedge standing on its point 1 below the centre (round corners), the band, the hour lines and the face inside its flat side; two draws with the star's materials, the golden face, band, lines and StarArt's face", "; ".join(problems))


## The hutton emblem: ten wedges (a round dial) filled one per piece, the middle left for the gnomon.
func check_emblem() -> void:
	var problems := []
	var emblem := PieceArt.emblem(PieceArt.SUNDIAL, 11)
	if not emblem is SundialEmblem or SundialEmblem.WEDGES != 10 or emblem.total != 11:
		problems.append("not the sundial emblem of 10 wedges")
	else:
		var sundial := emblem as SundialEmblem
		sundial.set_filled(3)
		if sundial.wedges_filled() != 3:
			problems.append("3 pieces fill %d" % sundial.wedges_filled())
		sundial.set_filled(11)
		if sundial.wedges_filled() != 10:
			problems.append("11 pieces fill %d" % sundial.wedges_filled())
		var c := Vector2.ONE * 50.0
		var area := 0.0
		for i in SundialEmblem.WEDGES:
			var poly := SundialEmblem.wedge(c, 10.0, 40.0, i)
			for j in poly.size():
				area += poly[j].cross(poly[(j + 1) % poly.size()]) * 0.5
		if absf(absf(area) - PI * (40.0 * 40.0 - 10.0 * 10.0)) > 60.0:
			problems.append("the wedges do not fill the dial (area %.0f)" % area)
	emblem.free()
	var star := PieceArt.emblem(PieceArt.STAR, 11)
	if not star is StarEmblem:
		problems.append("the star kind is not StarEmblem")
	star.free()
	expect.call(problems.is_empty(), "sundial piece: the hutton emblem is a round dial of 10 wedges filled one per piece (the 11th, the gnomon's, fills no wedge); the star kind keeps StarEmblem", "; ".join(problems))


## Every hutton lab's piece in its object is the sundial wedge; the mechanics labs' the star.
func check_lab_pieces() -> void:
	var problems := []
	for d: Dictionary in ExperimentRegistry.island_labs("hutton"):
		var lab := ExperimentRegistry.instantiate(d)
		tree.root.add_child(lab)
		await tree.process_frame
		if lab.game == null or not _is_sundial(lab.game.piece):
			problems.append("%s: no sundial piece" % d.id)
		elif not is_equal_approx(lab.game.full_size(), LabGame.PIECE_SIZE * LabGame.SUNDIAL_LAB_SCALE):
			problems.append("%s: full size %.2f, not the bigger lab wedge" % [d.id, lab.game.full_size()])
		lab.queue_free()
		await tree.process_frame
	for id in ["free-fall", "orbit"]:
		var lab := ExperimentRegistry.instantiate(ExperimentRegistry.find(id))
		tree.root.add_child(lab)
		await tree.process_frame
		if lab.game == null or not _is_star_piece(lab.game.piece):
			problems.append("%s: not the star piece" % id)
		elif not is_equal_approx(lab.game.full_size(), LabGame.PIECE_SIZE):
			problems.append("%s: star size changed (%.2f)" % [id, lab.game.full_size()])
		lab.queue_free()
		await tree.process_frame
	expect.call(problems.is_empty(), "sundial piece: every hutton lab hides the sundial wedge (LabGame.make_piece), 1.3 times the star's size in the lab; the mechanics labs keep the star at its size", "; ".join(problems))


## The found piece over the cat and the round-done card follow the lab's island.
func check_screen_piece_and_card() -> void:
	var problems := []
	var was := Story.enabled
	Story.enabled = true
	for pair in [["seasons", PieceArt.SUNDIAL], ["free-fall", PieceArt.STAR]]:
		DirAccess.remove_absolute(ProgressStore.path)
		var host := Control.new()
		host.theme = load(UI_THEME).build()
		host.size = PHONE
		tree.root.add_child(host)
		var screen: Control = load(EXPERIMENT_SCREEN).new()
		screen.setup(ExperimentRegistry.find(pair[0]))
		host.add_child(screen)
		await _frames(4)
		screen._show_piece()
		var found: Node3D = screen.found_piece()
		if pair[1] == PieceArt.SUNDIAL and not _is_sundial(found) or pair[1] == PieceArt.STAR and not _is_star_piece(found):
			problems.append("%s: the cat's piece is not the %s" % pair)
		screen._show_done_card()
		var card: RoundDoneCard = screen._done_card
		if card == null or card.piece_kind != pair[1] or not card.piece:
			problems.append("%s: the card's piece is not the %s" % pair)
		await _free(screen)
	Story.enabled = was
	DirAccess.remove_absolute(ProgressStore.path)
	expect.call(problems.is_empty(), "sundial piece: on a hutton lab the piece in the bread cat's paws and on the round-done card are the sundial wedge; on a mechanics lab the star", "; ".join(problems))


## The hutton map's story: its corner emblem is the dial with the pieces at the square, its flying
## pieces are wedges; the mechanics map keeps the star emblem and star pieces.
func check_map() -> void:
	var problems := []
	var was := Story.enabled
	Story.enabled = true
	Island.set_dev_open(true)
	for pair in [["hutton", PieceArt.SUNDIAL], ["mechanics", PieceArt.STAR]]:
		DirAccess.remove_absolute(ProgressStore.path)
		Island.use_for_run(pair[0])
		var host := Control.new()
		host.theme = load(UI_THEME).build()
		host.size = PHONE
		tree.root.add_child(host)
		var home: Control = load(HOME_SCREEN).new()
		home.play_prologue_on_open = false
		host.add_child(home)
		await _frames(4)
		var story: StoryDirector = home.story
		if story == null:
			problems.append("%s: no story" % pair[0])
		else:
			var want_emblem: bool = story.emblem is SundialEmblem if pair[1] == PieceArt.SUNDIAL else story.emblem is StarEmblem
			if not want_emblem or story.emblem.total != home.island.spots().size():
				problems.append("%s: emblem %s of %d" % [pair[0], story.emblem.name, story.emblem.total])
			story._add_piece(Vector3.ZERO, Vector3.UP, Vector3.ONE, 1.0, 0.0)
			var node: Node3D = story._pieces[-1].node
			if pair[1] == PieceArt.SUNDIAL and not _is_sundial(node) or pair[1] == PieceArt.STAR and not _is_star_piece(node):
				problems.append("%s: the flying piece is not the %s" % pair)
		await _free(home)
	Island.set_dev_open(false)
	Island.forget_current()
	Story.enabled = was
	DirAccess.remove_absolute(ProgressStore.path)
	expect.call(problems.is_empty(), "sundial piece: the hutton map's corner emblem is the 10-wedge dial and its flying pieces are wedges; the mechanics map keeps the star emblem and star pieces", "; ".join(problems))


## 섬 고르기: the hutton card's emblem is the dial, the mechanics card's the star.
func check_island_cards() -> void:
	var problems := []
	Island.set_dev_open(true)
	DirAccess.remove_absolute(ProgressStore.path)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = PHONE
	tree.root.add_child(host)
	var cards := IslandCards.new()
	host.add_child(cards)
	await _frames(3)
	for pair in [["hutton", "SundialEmblem"], ["mechanics", "StarEmblem"]]:
		var card: Control = cards.cards.get(pair[0])
		var emblems := card.find_children("*", "PieceEmblem", true, false) if card != null else []
		if emblems.size() != 1 or emblems[0].name != pair[1]:
			problems.append("%s: %s" % [pair[0], emblems.map(func(e: Node) -> String: return e.name)])
	host.queue_free()
	await _frames(2)
	Island.set_dev_open(false)
	expect.call(problems.is_empty(), "sundial piece: the island card of hutton shows the sundial dial emblem, the mechanics card the star emblem", "; ".join(problems))
