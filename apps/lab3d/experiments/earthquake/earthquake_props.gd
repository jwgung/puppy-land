## The 지진 lab's props (#97; apps/lab3d/docs/art-direction.md): meshes only, posed from the model by
## EarthquakeLab._redraw(). On the valley's slope in the squirrels' village:
## - the shake table in the middle: a steel-blue base with a post at each end, the orange deck that
##   swings on two springs (one round the handle's rod on the left, one on the right), and on the deck a
##   slab of ground, grey rock or yellow sand. The slab's foot moves with the deck and its top with the
##   ground's surface (EarthquakeModel.ground_x): soft sand leans over its foot, rock does not;
## - the handle the child pulls: a big red knob on a rod out of the deck's left end, through the left
##   spring. While a finger pulls it, the deck slides back as far as the pull and white dots run from
##   the knob to where the finger is (PullDots, the collision lab's);
## - the block house's brace, the X of two planks on its front, drawn leaning with the house's
##   frame (the blocks themselves are the lab's rigid bodies, block_mesh());
## - the ground's stripes: ripple bands on the ground that run out from the volcano's side (volcano_dir:
##   the island's volcano as seen from this lab) and cross the clearing while the table shakes, and a
##   crack that runs from that side towards the table on the strongest shake (stage 3's clue);
## - the village: two squirrel houses behind the table (one with a crack from that night);
## - the bread cat in front on the left, watching the house.
## Visual only: no body, nothing the model or the mission reads.
class_name EarthquakeProps
extends RefCounted

## The table's middle (the house stands over it), the base, the deck and the slab (m).
const TABLE_CENTER := Vector3(0.0, 0.0, -1.0)
const BASE := Vector3(6.4, 0.4, 3.2)
const POST_X := 3.3
const POST := Vector3(0.36, 1.0, 1.4)
const DECK := Vector3(5.2, 0.2, 2.8)
const DECK_TOP := 0.6
const SLAB := Vector3(4.8, 0.5, 2.6)
const SLAB_TOP := DECK_TOP + 0.5
## The handle: its rod out of the deck's left end and the knob at its tip (radius); the rod's height.
const HANDLE_Y := 0.62
const ROD_OUT := 1.45
const KNOB_RADIUS := 0.34
## The springs' rest length (deck end to post) and their coil's half height.
const SPRING_COILS := 9
const SPRING_HALF := 0.17
## The finger's full pull (m along the rod, PULL_STEP levels of it): EarthquakeLab maps it to the pull.
const PULL_REACH := 3.6
## The lab corner's centre (LabWorld): its trees stay clear of the table, the hill and the village.
const WORLD_CENTER := Vector3(0.0, 0.0, -2.6)
const CAT_AT := Vector3(2.4, 0.0, 2.3)
## The ripple bands: their source is SOURCE_DIST m from the table towards the volcano; a band is an
## arc of ARC_DEG either side of the line to the table, BAND_WIDTH wide; it runs from BAND_FROM m before
## the table to BAND_TO past it in BAND_S, one every BAND_EVERY s while the table shakes (BANDS at once).
const SOURCE_DIST := 32.0
const ARC_DEG := 22.0
const BAND_WIDTH := 0.5
const BAND_FROM := 13.0
const BAND_TO := 7.0
const BAND_S := 1.4
const BAND_EVERY := 0.45
const BANDS := 4
const BAND_COLOR := Color("8a6a3c")
const BAND_TOP := Color("a8844e")
## The crack of the strongest shake: from CRACK_FROM m out towards the volcano to CRACK_TO m from the
## table's middle, CRACK_STEPS zigzag pieces, drawn in over CRACK_S.
const CRACK_FROM := 11.5
const CRACK_TO := 3.4
const CRACK_STEPS := 12
const CRACK_S := 1.1
const CRACK_COLOR := Color("4c362c")
## The house's brace: two planks across its front between the posts' inner faces.
const BRACE_PLANK := Vector2(0.15, 0.1)
const BRACE_COLOR := Color("8f5a2c")
const BRACE_TOP := Color("b07440")
## The block house (house frame: x across, y up from the slab's top, z towards the camera): the posts'
## cubes, the back wall's planks, the beam and the roof (EarthquakeLab builds a body of each).
const CUBE := Vector3(0.5, 0.5, 1.0)
const POST_CUBE_X := 0.75
const LEVELS := 3
const PLANK := Vector3(1.0, 0.48, 0.16)
const PLANK_Z := -0.38
const BEAM := Vector3(2.1, 0.3, 1.15)
const BEAM_Y := 1.65
const ROOF_BASE := 1.8
const ROOF := Vector3(2.6, 0.95, 1.35)
const POST_COLOR := Color("e3a35e")
const POST_TOP := Color("f0bb7a")
const PLANK_COLOR := Color("fbf4e2")
const BEAM_COLOR := Color("8f5a2c")
const ROOF_COLOR := Color("ff5a4f")
const ROOF_DARK := Color("d8433a")
const WINDOW_COLOR := Color("2d7cf6")
## The village's squirrel houses (where, how big, turned), behind the table.
const VILLAGE := [[Vector3(5.8, 0.0, -3.6), 1.0, -30.0], [Vector3(-0.6, 0.0, -8.4), 0.85, 10.0]]

var cat: CatActor
var deck: Node3D
var slab: Node3D
var rock: Node3D
var sand: Node3D
var handle: Node3D
var spring_left: Node3D
var spring_right: Node3D
var brace: Node3D
var pull_dots: PullDots
var bands: Array[Node3D] = []
var crack: Array[Node3D] = []
## The volcano's way from the table (unit, on the ground) and the ripples' source.
var volcano := Vector3.FORWARD
var source := Vector3.ZERO
## What the props show now (tests): the deck's and the ground's swing, the slab's lean, the bands
## crossing the clearing, the crack's pieces shown.
var shown_deck := 0.0
var shown_ground := 0.0
var shown_bands := 0
var shown_crack := 0


## The volcano's direction from the 지진 lab (unit, y 0): the hutton island's volcano mapped into the
## lab as LabWorld does (the lab's spot at WORLD_CENTER, its lab_facing, K lab metres per map metre),
## seen from the table's middle.
static func volcano_dir() -> Vector3:
	var island := Island.by_id("hutton")
	if island == null or not island.features.has("volcano"):
		return Vector3.FORWARD
	var spot := Vector2.ZERO
	for zone in island.zones:
		for s in island.zones[zone].spots:
			if s[0] == "earthquake":
				spot = Vector2(float(s[1][0]), float(s[1][1]))
	var facing := deg_to_rad(float(island.lab_facing["earthquake"])) if island.lab_facing.has("earthquake") else (island.home - spot).angle()
	var f := Vector2.from_angle(facing)
	var r := Vector2(-f.y, f.x)
	var v: Array = island.features.volcano.at
	var o := (Vector2(float(v[0]), float(v[1])) - spot) * LabWorld.K
	var at := Vector2(WORLD_CENTER.x, WORLD_CENTER.z) + Vector2(o.dot(r), -o.dot(f))
	return Vector3(at.x - TABLE_CENTER.x, 0.0, at.y - TABLE_CENTER.z).normalized()


## The house's foot (the middle of its floor) when the ground's surface is `ground_x` off its rest.
static func house_foot(ground_x: float) -> Vector3:
	return TABLE_CENTER + Vector3(ground_x, SLAB_TOP, 0.0)


## The knob's middle when the deck is `deck_x` off its rest.
static func knob_at(deck_x: float) -> Vector3:
	return TABLE_CENTER + Vector3(-DECK.x * 0.5 - ROD_OUT + deck_x, HANDLE_Y, 0.0)


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	volcano = volcano_dir()
	source = TABLE_CENTER + volcano * SOURCE_DIST
	var base := ArtKit.instance(_base_mesh())
	base.name = "TableBase"
	lab.add_child(base)
	deck = Node3D.new()
	deck.name = "Deck"
	lab.add_child(deck)
	deck.add_child(ArtKit.instance(_deck_mesh()))
	handle = ArtKit.instance(_handle_mesh())
	handle.name = "Handle"
	deck.add_child(handle)
	slab = Node3D.new()
	slab.name = "Slab"
	lab.add_child(slab)
	rock = ArtKit.instance(_rock_mesh())
	rock.name = "Rock"
	slab.add_child(rock)
	sand = ArtKit.instance(_sand_mesh())
	sand.name = "Sand"
	slab.add_child(sand)
	spring_left = ArtKit.instance(_spring_mesh())
	spring_left.name = "SpringLeft"
	lab.add_child(spring_left)
	spring_right = ArtKit.instance(_spring_mesh())
	spring_right.name = "SpringRight"
	lab.add_child(spring_right)
	brace = ArtKit.instance(_brace_mesh())
	brace.name = "Brace"
	lab.add_child(brace)
	pull_dots = PullDots.new()
	lab.add_child(pull_dots)
	var band_mesh := _band_mesh()
	for i in BANDS:
		var band := ArtKit.instance(band_mesh)
		band.name = "Band%d" % i
		band.visible = false
		lab.add_child(band)
		bands.append(band)
	for i in CRACK_STEPS:
		var piece := ArtKit.instance(_crack_mesh(i))
		piece.name = "Crack%d" % i
		piece.visible = false
		lab.add_child(piece)
		crack.append(piece)
	var village := ArtKit.instance(_village_mesh())
	village.name = "Village"
	lab.add_child(village)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses the table: the deck `deck_x` and the ground's surface `ground_x` off their rest (m), the
## slab rock or sand, the brace shown or not and leaning with the frame's `drift` (m at its top,
## the house standing); the pull's dots to `pull_to` (INF: none).
func show(deck_x: float, ground_x: float, sand_ground: bool, braced: bool, drift: float, standing: bool, pull_to := Vector3.INF) -> void:
	shown_deck = deck_x
	shown_ground = ground_x
	deck.position = TABLE_CENTER + Vector3(deck_x, 0.0, 0.0)
	rock.visible = not sand_ground
	sand.visible = sand_ground
	# The slab's foot rides the deck, its top the ground's surface (a lean of the whole slab).
	slab.transform = Transform3D(Basis(Vector3.RIGHT, Vector3((ground_x - deck_x) / SLAB.y, 1.0, 0.0), Vector3.BACK), TABLE_CENTER + Vector3(deck_x, DECK_TOP, 0.0))
	var left_end := TABLE_CENTER.x - DECK.x * 0.5 + deck_x
	var right_end := TABLE_CENTER.x + DECK.x * 0.5 + deck_x
	_stretch(spring_left, TABLE_CENTER.x - POST_X + POST.x * 0.5, left_end)
	_stretch(spring_right, right_end, TABLE_CENTER.x + POST_X - POST.x * 0.5)
	brace.visible = braced and standing
	brace.transform = Transform3D(Basis(Vector3.RIGHT, Vector3(drift / EarthquakeModel.HOUSE_HEIGHT, 1.0, 0.0), Vector3.BACK), house_foot(ground_x))
	if pull_to == Vector3.INF:
		pull_dots.hide_line()
	else:
		pull_dots.show_line(knob_at(deck_x), pull_to)


## A spring from x `from` to x `to` (its coil mesh is 1 m long along +x).
func _stretch(spring: Node3D, from: float, to: float) -> void:
	spring.transform = Transform3D(Basis.from_scale(Vector3(maxf(0.05, to - from), 1.0, 1.0)), Vector3(from, TABLE_CENTER.y + HANDLE_Y, TABLE_CENTER.z))


## The ripple bands at `since` s into the shake (`strength` 0..1: none at 0), and the crack drawn in
## by `crack_share` (0..1; 0 hides it).
func show_ground(since: float, shaking: bool, crack_share: float) -> void:
	shown_bands = 0
	for i in BANDS:
		var band := bands[i]
		band.visible = false
		if not shaking:
			continue
		# Band i of every round of BANDS: the newest one that started on this slot.
		var slot := since - i * BAND_EVERY
		if slot < 0.0:
			continue
		var age := fposmod(slot, BAND_EVERY * BANDS)
		if age > BAND_S:
			continue
		var r := SOURCE_DIST - BAND_FROM + (BAND_FROM + BAND_TO) * age / BAND_S
		band.transform = Transform3D(Basis.from_scale(Vector3(r / SOURCE_DIST, 1.0, r / SOURCE_DIST)), Vector3(source.x, 0.0, source.z))
		band.visible = true
		shown_bands += 1
	shown_crack = clampi(ceili(crack_share * CRACK_STEPS - 1e-6), 0, CRACK_STEPS)
	for i in CRACK_STEPS:
		crack[i].visible = i < shown_crack


# --- the house's blocks -------------------------------------------------------------------------

## The house's blocks [name, kind, centre (house frame), size]: the posts' cubes (left and right,
## bottom to top), the back wall's planks, the beam and the roof.
static func blocks() -> Array:
	var out := []
	for side: float in [-1.0, 1.0]:
		for level in LEVELS:
			out.append(["Post%s%d" % ["L" if side < 0.0 else "R", level], "cube", Vector3(side * POST_CUBE_X, CUBE.y * (level + 0.5), 0.0), CUBE])
	for level in LEVELS:
		out.append(["Plank%d" % level, "plank", Vector3(0.0, CUBE.y * (level + 0.5), PLANK_Z), PLANK])
	out.append(["Beam", "beam", Vector3(0.0, BEAM_Y, 0.0), BEAM])
	out.append(["Roof", "roof", Vector3(0.0, ROOF_BASE + ROOF.y / 3.0, 0.0), ROOF])
	return out


## The roof's corners round its body's centre (a prism: its ridge along z, its centroid at the origin).
static func roof_points() -> PackedVector3Array:
	var h := ROOF.y
	var pts := PackedVector3Array()
	for z: float in [-ROOF.z * 0.5, ROOF.z * 0.5]:
		pts.append(Vector3(-ROOF.x * 0.5, -h / 3.0, z))
		pts.append(Vector3(ROOF.x * 0.5, -h / 3.0, z))
		pts.append(Vector3(0.0, h * 2.0 / 3.0, z))
	return pts


## The mesh of a block of `kind` (centred on its body's origin).
static func block_mesh(kind: String, size: Vector3, index := 0) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.3
	match kind:
		"cube":
			b.add_rounded_box(Transform3D(), size, 0.06, 1, POST_COLOR, POST_TOP)
		"plank":
			b.add_rounded_box(Transform3D(), size, 0.04, 1, PLANK_COLOR)
			if index == 1:   # the middle plank: a round blue window on its front
				b.ao_min = 1.0
				b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, size.z * 0.5)), 0.17, 0.17, 0.03, 12, WINDOW_COLOR)
				b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, size.z * 0.5 - 0.005)), 0.21, 0.21, 0.025, 12, BEAM_COLOR)
		"beam":
			b.add_rounded_box(Transform3D(), size, 0.05, 1, BEAM_COLOR, BRACE_TOP)
		"roof":
			var p := roof_points()
			var colors := [ROOF_COLOR, ROOF_COLOR, ROOF_COLOR]
			b.add_triangle([p[0], p[1], p[2]], colors, Vector3.FORWARD)
			b.add_triangle([p[3], p[4], p[5]], [ROOF_DARK, ROOF_DARK, ROOF_DARK], Vector3.BACK)
			for pair in [[0, 2, -1.0], [1, 2, 1.0]]:   # the two slopes
				var a: Vector3 = p[pair[0]]
				var c: Vector3 = p[pair[1]]
				var out := Vector3(float(pair[2]), 1.0, 0.0)
				b.add_triangle([a, c, p[pair[1] + 3]], colors, out)
				b.add_triangle([a, p[pair[1] + 3], p[pair[0] + 3]], colors, out)
			b.add_triangle([p[0], p[1], p[4]], [ROOF_DARK, ROOF_DARK, ROOF_DARK], Vector3.DOWN)
			b.add_triangle([p[0], p[4], p[3]], [ROOF_DARK, ROOF_DARK, ROOF_DARK], Vector3.DOWN)
			b.ao_min = 1.0
			b.add_sphere(Transform3D(Basis(), p[2] + Vector3(0.0, 0.08, 0.0)), 0.13, 3, 8, ArtPalette.YELLOW)   # an acorn-gold knob on the ridge
	return b.commit()


# --- the meshes ---------------------------------------------------------------------------------

## The table's base (steel blue, a darker foot), its two end posts with a hole ring for the rod.
func _base_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = 0.4
	b.add_rounded_box(Transform3D(Basis(), TABLE_CENTER + Vector3(0.0, BASE.y * 0.5, 0.0)), BASE, 0.08, 1, ArtPalette.BLUE_DARK, ArtPalette.BLUE)
	for side: float in [-1.0, 1.0]:
		var at := TABLE_CENTER + Vector3(side * POST_X, POST.y * 0.5, 0.0)
		b.add_rounded_box(Transform3D(Basis(), at), POST, 0.07, 1, ArtPalette.BLUE, ArtPalette.STEEL_SHINE)
		b.ao_min = 1.0
		b.add_cylinder(Transform3D(Basis(Vector3.BACK, PI * 0.5), TABLE_CENTER + Vector3(side * (POST_X + POST.x * 0.5) + 0.01 * side, HANDLE_Y, 0.0)), 0.16, 0.16, 0.02, 12, ArtPalette.IRON)
		b.ao_min = 0.8
	# Rollers under the deck (the table rolls side to side).
	for x: float in [-1.9, -0.65, 0.65, 1.9]:
		for z: float in [-1.0, 1.0]:
			b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), TABLE_CENTER + Vector3(x, BASE.y + 0.09, z - 0.12)), 0.09, 0.09, 0.24, 10, ArtPalette.STEEL)
	return b.commit()


## The deck (its own frame: centred on x and z, its foot at the base's top): orange with a yellow
## top and two stripes.
func _deck_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.2
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, DECK_TOP - DECK.y * 0.5, 0.0)), DECK, 0.05, 1, ArtPalette.ORANGE, ArtPalette.ORANGE_TOP)
	b.ao_min = 1.0
	for x: float in [-DECK.x * 0.5 + 0.12, DECK.x * 0.5 - 0.12]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(x, DECK_TOP - DECK.y * 0.5, DECK.z * 0.5)), Vector3(0.12, DECK.y * 0.7, 0.02), 0.0, 1, ArtPalette.YELLOW)
	return b.commit()


## The handle (deck frame): the rod out of the deck's left end and the big red knob.
func _handle_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var end := Vector3(-DECK.x * 0.5, HANDLE_Y, 0.0)
	b.add_cylinder(Transform3D(Basis(Vector3.BACK, PI * 0.5), end), 0.07, 0.07, ROD_OUT, 10, ArtPalette.STEEL)
	b.add_sphere(Transform3D(Basis(), end + Vector3(-ROD_OUT, 0.0, 0.0)), KNOB_RADIUS, 5, 12, ArtPalette.RED)
	b.add_sphere(Transform3D(Basis(), end + Vector3(-ROD_OUT - KNOB_RADIUS * 0.3, KNOB_RADIUS * 0.35, KNOB_RADIUS * 0.45)), KNOB_RADIUS * 0.28, 3, 8, ArtPalette.RED_TOP)
	return b.commit()


## Grey rock (slab frame: its foot at y 0): a stone block with a few lighter stones on top.
func _rock_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = 0.5
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SLAB.y * 0.5, 0.0)), SLAB, 0.1, 1, Color("8d97a8"), ArtPalette.ROCK)
	b.ao_min = 1.0
	for i in 9:
		var a := i * 2.399963
		var r := 0.45 + 0.9 * sqrt((i + 0.5) / 9.0)
		var at := Vector3(cos(a) * r * 1.6, SLAB.y + 0.01, sin(a) * r * 0.8)
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, a), at), Vector3(0.36, 0.06, 0.26), 0.02, 1, Color("c3cad6"))
	return b.commit()


## Yellow sand (slab frame): a soft heap with ripple lines on top.
func _sand_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.5
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SLAB.y * 0.5, 0.0)), SLAB, 0.18, 2, Color("e8c46a"), ArtPalette.SAND)
	b.ao_min = 1.0
	for k in 5:
		var z := -SLAB.z * 0.5 + 0.3 + k * (SLAB.z - 0.6) / 4.0
		b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, SLAB.y + 0.005, z)), Vector3(SLAB.x - 0.5, 0.02, 0.06), 0.0, 1, Color("e2b95a"))
	return b.commit()


## A coil spring 1 m long along +x (scaled to its length): a zigzag of thin steel rods round the rod.
func _spring_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var points := []
	for i in SPRING_COILS * 2 + 1:
		var x := float(i) / (SPRING_COILS * 2)
		var a := PI * i
		points.append(Vector3(x, cos(a) * SPRING_HALF, sin(a + PI * 0.5) * SPRING_HALF * 0.6))
	for i in points.size() - 1:
		var from: Vector3 = points[i]
		var to: Vector3 = points[i + 1]
		var d := to - from
		b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), from), 0.035, 0.035, d.length(), 6, ArtPalette.STEEL_SHINE)
	return b.commit()


## The brace (house frame, its foot at the floor's middle): two planks crossing on the front between
## the posts' inner faces, from the floor to under the beam.
func _brace_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var x := POST_CUBE_X - CUBE.x * 0.5
	var top := CUBE.y * LEVELS
	var z := CUBE.z * 0.5 + BRACE_PLANK.y * 0.5 + 0.01
	for k in 2:
		var from := Vector3(-x if k == 0 else x, 0.05, z + k * 0.02)
		var to := Vector3(x if k == 0 else -x, top - 0.05, z + k * 0.02)
		var d := to - from
		var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
		b.add_rounded_box(Transform3D(basis, (from + to) * 0.5), Vector3(BRACE_PLANK.x, d.length(), BRACE_PLANK.y), 0.02, 1, BRACE_COLOR, BRACE_TOP)
	return b.commit()


## A ripple band: an arc of the circle of SOURCE_DIST round the source (local: the source at the
## origin), ARC_DEG either side of the line to the table, its edges in small waves.
func _band_mesh() -> Mesh:
	var b := ArtKit.builder()
	var toward := Vector2(-volcano.x, -volcano.z).angle()
	var n := 40
	for i in n:
		var a0 := toward + deg_to_rad(ARC_DEG) * (2.0 * i / n - 1.0)
		var a1 := toward + deg_to_rad(ARC_DEG) * (2.0 * (i + 1) / n - 1.0)
		var w0 := BAND_WIDTH * (0.75 + 0.25 * sin(i * 1.7))
		var w1 := BAND_WIDTH * (0.75 + 0.25 * sin((i + 1) * 1.7))
		var p := [Vector3(cos(a0), 0.035, sin(a0)) * Vector3(SOURCE_DIST - w0, 1.0, SOURCE_DIST - w0),
			Vector3(cos(a1), 0.035, sin(a1)) * Vector3(SOURCE_DIST - w1, 1.0, SOURCE_DIST - w1),
			Vector3(cos(a1), 0.035, sin(a1)) * Vector3(SOURCE_DIST + w1, 1.0, SOURCE_DIST + w1),
			Vector3(cos(a0), 0.035, sin(a0)) * Vector3(SOURCE_DIST + w0, 1.0, SOURCE_DIST + w0)]
		b.add_triangle([p[0], p[1], p[2]], [BAND_COLOR, BAND_COLOR, BAND_TOP], Vector3.UP)
		b.add_triangle([p[0], p[2], p[3]], [BAND_COLOR, BAND_TOP, BAND_TOP], Vector3.UP)
	return b.commit()


## Piece `i` of the crack (world): a zigzag from CRACK_FROM m out towards the volcano to CRACK_TO m
## from the table's middle, a dark groove a little wider at the far end.
func _crack_mesh(i: int) -> Mesh:
	var b := ArtKit.builder()
	var along := func(k: int) -> Vector3:
		var share := float(k) / CRACK_STEPS
		var side := Vector3(-volcano.z, 0.0, volcano.x) * (0.0 if k == 0 or k == CRACK_STEPS else (0.35 if k % 2 == 0 else -0.35))
		return TABLE_CENTER + volcano * lerpf(CRACK_FROM, CRACK_TO, share) + side + Vector3(0.0, 0.04, 0.0)
	var from: Vector3 = along.call(i)
	var to: Vector3 = along.call(i + 1)
	var d := (to - from).normalized()
	var across := Vector3(-d.z, 0.0, d.x)
	var w0 := lerpf(0.2, 0.08, float(i) / CRACK_STEPS)
	var w1 := lerpf(0.2, 0.08, float(i + 1) / CRACK_STEPS)
	var c := [CRACK_COLOR, CRACK_COLOR, CRACK_COLOR]
	b.add_triangle([from - across * w0, to - across * w1, to + across * w1], c, Vector3.UP)
	b.add_triangle([from - across * w0, to + across * w1, from + across * w0], c, Vector3.UP)
	return b.commit()


## The squirrels' village behind the table: little round-roofed houses with a door, a window and an
## acorn on top; the first one has a crack down its wall from that night.
func _village_mesh() -> Mesh:
	var b := ArtKit.builder()
	for k in VILLAGE.size():
		var spec: Array = VILLAGE[k]
		var s: float = spec[1]
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(spec[2]))).scaled(Vector3.ONE * s), spec[0])
		b.ao_min = 0.8
		b.ao_height = 0.6
		b.add_rounded_box(xf * Transform3D(Basis(), Vector3(0.0, 0.6, 0.0)), Vector3(1.6, 1.2, 1.3), 0.08, 1, PLANK_COLOR)
		for side: float in [-1.0, 1.0]:   # a pitched roof: two slopes meeting over the middle
			b.add_rounded_box(xf * Transform3D(Basis(Vector3.BACK, -side * 0.62), Vector3(side * 0.47, 1.5, 0.0)), Vector3(1.15, 0.12, 1.55), 0.03, 1, ROOF_COLOR, ROOF_DARK)
		b.ao_min = 1.0
		b.add_rounded_box(xf * Transform3D(Basis(), Vector3(-0.35, 0.42, 0.66)), Vector3(0.42, 0.84, 0.04), 0.04, 1, BEAM_COLOR)
		b.add_cylinder(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.35, 0.72, 0.66)), 0.18, 0.18, 0.03, 10, WINDOW_COLOR)
		b.add_sphere(xf * Transform3D(Basis.from_scale(Vector3(1.0, 1.2, 1.0)), Vector3(0.0, 1.98, 0.0)), 0.16, 3, 8, Color("a8662f"))
		b.add_sphere(xf * Transform3D(Basis.from_scale(Vector3(1.0, 0.5, 1.0)), Vector3(0.0, 2.14, 0.0)), 0.17, 3, 8, Color("6b4423"))
		if k == 0:   # the crack from that night: a dark zigzag down the wall
			var pts := [Vector3(0.45, 1.15, 0.66), Vector3(0.3, 0.9, 0.66), Vector3(0.48, 0.7, 0.66), Vector3(0.36, 0.45, 0.66)]
			for i in pts.size() - 1:
				var from: Vector3 = xf * pts[i]
				var to: Vector3 = xf * pts[i + 1]
				var d := to - from
				b.add_cylinder(Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), from), 0.025, 0.025, d.length(), 4, CRACK_COLOR)
	return b.commit()
