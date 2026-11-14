## The curie island's pieces (#154, 2026-11-13 user pick B "무지개 렌즈"): curie.json's `piece` is the
## lens (Island.PIECE_LENS); its first eleven spots each give a wedge of the rainbow lighthouse's round
## lens (LensArt: an eleventh of the disc, 360/11°, standing on its point, each its own rainbow colour by
## its place in the order, two draws) and spot 12 (the flame colours) the lighthouse's flame, which
## never flies (Island.held_spot, as the hutton island's gnomon) and lights the emblem's middle
## (LensEmblem: eleven wedges filling into a rainbow wheel, the flame at set_whole). The hutton island
## keeps its sundial and the mechanics island its star.
extends RefCounted

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	Island.use_index([])
	check_data()
	check_wedges()
	check_emblem()
	await check_card_picture()
	Island.use_index([])


func _body(node: Node) -> MeshInstance3D:
	return node.get_node_or_null("Shape/Body") as MeshInstance3D if node != null else null


## curie gives the lens, its 12th spot the flame (held: never flies); hutton keeps the sundial (its
## gnomon held), mechanics the star (nothing held); slots are the order's places.
func check_data() -> void:
	var problems := []
	var curie := Island.by_id("curie")
	if curie.piece != Island.PIECE_LENS or PieceArt.of_island("curie") != PieceArt.LENS:
		problems.append("curie gives %s" % curie.piece)
	if curie.flame_spot() != "flame-color" or curie.held_spot() != "flame-color" or curie.flame_spot() != str(curie.order[Island.LENS_PIECES]):
		problems.append("curie's flame spot %s, held %s" % [curie.flame_spot(), curie.held_spot()])
	if curie.slot_of("diffusion") != 0 or curie.slot_of("rust") != 10 or curie.slot_of("nowhere") != -1:
		problems.append("slots %d %d %d" % [curie.slot_of("diffusion"), curie.slot_of("rust"), curie.slot_of("nowhere")])
	var hutton := Island.by_id("hutton")
	if hutton.piece != Island.PIECE_SUNDIAL or hutton.held_spot() != hutton.gnomon_spot() or hutton.held_spot() != "volcano" or hutton.flame_spot() != "":
		problems.append("hutton: %s, held %s" % [hutton.piece, hutton.held_spot()])
	var mechanics := Island.by_id("mechanics")
	if mechanics.piece != Island.PIECE_STAR or mechanics.held_spot() != "" or mechanics.flame_spot() != "":
		problems.append("mechanics: %s, held %s" % [mechanics.piece, mechanics.held_spot()])
	if PieceArt.lab_scale(PieceArt.LENS) != PieceArt.SUNDIAL_LAB_SCALE or PieceArt.lab_scale(PieceArt.STAR) != 1.0:
		problems.append("lab scale %.2f" % PieceArt.lab_scale(PieceArt.LENS))
	expect.call(problems.is_empty(), "lens piece: curie gives the rainbow lens and its 12th spot (flame colours) the flame that never flies; hutton keeps the sundial (gnomon held), mechanics the star; slots are the order's places",
		"; ".join(problems))


## Each wedge is an eleventh of the disc on its point, its own rainbow colour; past the lens the flame
## (a teardrop, its heart); every piece is two draws (body, outline) and its meshes are cached.
func check_wedges() -> void:
	var problems := []
	var rim := LensArt.rim()
	var widest := 0.0
	for p: Vector2 in rim:
		var d := p - SundialArt.APEX
		if d.length() > SundialArt.SPAN * 0.9:
			widest = maxf(widest, absf(rad_to_deg(atan2(d.x, d.y))))
	if absf(widest * 2.0 - LensArt.WEDGE_DEG) > 3.0 or absf(LensArt.WEDGE_DEG - 360.0 / 11.0) > 0.01:
		problems.append("wedge %.1f°, want %.1f" % [widest * 2.0, 360.0 / 11.0])
	var colours := {}
	for slot in Island.LENS_PIECES:
		colours[LensArt.color_of(slot).to_html()] = true
	if colours.size() != Island.LENS_PIECES:
		problems.append("%d colours for 11 wedges" % colours.size())
	if LensArt.color_of(Island.LENS_PIECES) != LensArt.FLAME or LensArt.piece_meshes(11) != LensArt.piece_meshes(15):
		problems.append("the flame past the lens")
	for slot: int in [0, 6, 11]:
		var node := PieceArt.make(PieceArt.LENS, 0.5, slot)
		var draws := node.find_children("*", "MeshInstance3D", true, false).size()
		var want_name := "FlamePiece" if slot >= Island.LENS_PIECES else "LensPiece"
		if node.name != want_name or draws != 2 or _body(node) == null or _body(node).mesh != LensArt.piece_meshes(slot)[0]:
			problems.append("slot %d: %s, %d draws" % [slot, node.name, draws])
		node.free()
	if LensArt.piece_meshes(0)[0] == LensArt.piece_meshes(1)[0]:
		problems.append("two wedges share a mesh (one colour)")
	var top := -INF
	var bottom := INF
	for p: Vector2 in LensArt.flame_rim():
		top = maxf(top, p.y)
		bottom = minf(bottom, p.y)
	if top < 1.2 or bottom > -0.8:
		problems.append("flame %.2f..%.2f (want its foot about 1 below, its tip up)" % [bottom, top])
	expect.call(problems.is_empty(), "lens piece: the wedge is an eleventh of the disc on its point, eleven rainbow colours by slot, the flame past the lens; two draws each, meshes cached",
		"; ".join(problems))


## The emblem: eleven wedges fill one by one (the 12th piece fills nothing), the wedges make the whole
## ring, set_whole lights the middle (and every piece counts).
func check_emblem() -> void:
	var problems := []
	var emblem := PieceArt.emblem(PieceArt.LENS, 12)
	if not emblem is LensEmblem or LensEmblem.WEDGES != 11 or emblem.total != 12:
		problems.append("emblem %s" % emblem.name)
	else:
		var lens := emblem as LensEmblem
		lens.set_filled(3)
		var three := lens.wedges_filled()
		lens.set_filled(12)
		var all := lens.wedges_filled()
		if three != 3 or all != 11 or lens.whole:
			problems.append("filled 3 -> %d, 12 -> %d, whole %s" % [three, all, lens.whole])
		var area := 0.0
		for i in LensEmblem.WEDGES:
			var poly := LensEmblem.wedge(Vector2.ZERO, 10.0, 40.0, i)
			for k in poly.size():
				area += poly[k].cross(poly[(k + 1) % poly.size()]) * 0.5
		var ring := PI * (40.0 * 40.0 - 10.0 * 10.0)
		if absf(absf(area) - ring) > ring * 0.02:
			problems.append("wedges cover %.0f of the ring's %.0f" % [absf(area), ring])
		lens.set_filled(0)
		lens.set_whole(true)
		if not lens.whole or lens.filled != 12:
			problems.append("set_whole: whole %s, filled %d" % [lens.whole, lens.filled])
	emblem.free()
	for pair in [[PieceArt.SUNDIAL, "SundialEmblem"], [PieceArt.STAR, "StarEmblem"]]:
		var other := PieceArt.emblem(pair[0], 11)
		if other.name != pair[1]:
			problems.append("%s emblem %s" % [pair[0], other.name])
		other.free()
	expect.call(problems.is_empty(), "lens piece: the emblem's eleven wedges fill one by one into the ring (the 12th fills nothing), set_whole lights the flame in the middle; sundial and star emblems unchanged",
		"; ".join(problems))


## The round-done card's picture of a lens wedge and of the flame draws (no error, inside its box).
func check_card_picture() -> void:
	var problems := []
	var card := RoundDoneCard.new(3, true, PieceArt.LENS, 4)
	if card.piece_kind != PieceArt.LENS or card.piece_slot != 4:
		problems.append("card %s %d" % [card.piece_kind, card.piece_slot])
	card.free()
	var host := Control.new()
	host.size = Vector2(200, 200)
	var drawn := [0]
	host.draw.connect(func() -> void:
		PieceArt.draw_2d(PieceArt.LENS, host, Vector2(60, 100), 40.0, 4)
		PieceArt.draw_2d(PieceArt.LENS, host, Vector2(140, 100), 40.0, 11)
		drawn[0] += 1)
	tree.root.add_child(host)
	for i in 3:
		await tree.process_frame
	if drawn[0] == 0:
		problems.append("not drawn")
	host.queue_free()
	await tree.process_frame
	expect.call(problems.is_empty(), "lens piece: the round-done card keeps the lens and its slot, and draws a wedge and the flame", "; ".join(problems))
