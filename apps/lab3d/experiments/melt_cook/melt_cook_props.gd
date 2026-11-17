## The 되돌릴 수 있을까? lab's props (#158, 2026-11-17; the approved mockup of #158): meshes only, posed from
## the model by MeltCookLab._redraw(). Curie Island's kitchen (KitchenSet) and on its table:
## - a stove (an iron box with two burners and a big red handle on its front, the thing the child presses:
##   while pressed the handle sinks in, a ring lights and flames lick the pot's sides; let go and the
##   flames go out) with a pot on its left burner and, from stage 2 on, a star mold on its right one;
## - the pot's chocolate (chocolate item): two dark blocks that soften and sink as they warm, a glossy
##   puddle once melted, a flat slab if it sets again in the pot; steam while warm;
## - the star mold: the bread cat tips the pot and pours the melted chocolate into the star (the pour
##   starts with a stage-2 reset: begin_pour()); the star steams and shines while it is runny and turns
##   matte and a little lighter once set; a press melts it again (the right burner's flames);
## - the pot's water and an egg in it (egg item): the water bubbles when it boils; a magnifier window
##   floating above the stove shows the egg's inside only (a clear white and an orange yolk when raw, a
##   milky white and a yellow yolk once cooked: never the egg broken open, 2026-11-16 user); the shiny
##   egg of the basket on the table's right is the one that goes into the pot at stage 3 (hidden in
##   the basket until then); when the round is won the bread cat peels it (shell pieces on the stove);
## - the bread cat on its crates left of the stove (it does the lab: it pours, it peels).
## Where things stand: POT_AT, MOLD_AT, HANDLE_AT, LENS_AT, BASKET_AT. Visual only: no body, nothing the model or the mission reads.
class_name MeltCookProps
extends RefCounted

## The stove: its middle on the table, its size (m) and the height of its top.
const STOVE_AT := Vector3(0.68, KitchenSet.TABLE_TOP, 0.15)
const STOVE_SIZE := Vector3(2.8, 0.7, 1.1)
const STOVE_TOP := KitchenSet.TABLE_TOP + 0.7
const STOVE := Color("3d4049")
const STOVE_PLATE := Color("5b5f6b")
const BURNER := Color("23252b")
## The burners (their middles, world), the pot on the left one and the star mold on the right one.
const POT_AT := Vector3(0.0, STOVE_TOP, 0.15)
const MOLD_AT := Vector3(1.3, STOVE_TOP, 0.15)
## The handle: a big red round knob on the stove's front (its middle, world), its size, how far it sinks.
const HANDLE_AT := Vector3(0.68, KitchenSet.TABLE_TOP + 0.38, STOVE_AT.z + STOVE_SIZE.z * 0.5 + 0.03)
const HANDLE_R := 0.3
const HANDLE_SINK := 0.06
const HANDLE_RED := Color("e34b3f")
const HANDLE_PRESSED := Color("b8322a")
const HANDLE_RING := Color("ffd43b")
## The pot: its radii and height (m), its metal, its handle's end and where the cat grips it (relative to
## the pot's middle at the stove's top), and the pivot it tips about: its right foot.
const POT_RB := 0.5
const POT_RT := 0.58
const POT_H := 0.34
const POT_METAL := Color("8d97a3")
const POT_DARK := Color("5f6a76")
const POT_HANDLE_END := Vector3(-0.85, 0.2, 0.0)
const POT_GRIP := Vector3(-0.7, 0.2, 0.0)
const POT_PIVOT := Vector3(POT_RB, 0.0, 0.0)
## How far the pot tips when pouring (deg), the pour's times (s): tip, pour, tip back.
const TILT_MAX := 28.0
const TIP_S := 0.9
const POUR_S := 1.3
const BACK_S := 0.9
## The pour's stream: how many links it has along its falling arc, where it lands in the star (x off the mold's middle).
const STREAM_LINKS := 5
const STREAM_AT_X := -0.28
## The paws on the pot's handle: how far apart (m) along z.
const PAW_HALF := 0.1
## The chocolate: a block, a puddle, a set slab; what the stages' words call them.
const CHOC_BLOCK := Color("5a2e14")
const CHOC_BLOCK_TOP := Color("7a4424")
const CHOC_MELT := Color("6b3a1e")
const CHOC_SHINE := Color("c58a5c")
const CHOC_SET := Color("4a2814")
const CHOC_SET_TOP := Color("6a3c20")
## The star mold: its tray, the star's outer and inner radius (m).
const MOLD_TRAY := Vector3(1.4, 0.08, 1.0)
const MOLD_METAL := Color("e8edf2")
const MOLD_EDGE := Color("9aa5b1")
const STAR_R := 0.58
const STAR_r := 0.27
## The egg in the pot (its middle, world) and its size, the shell's colours and the shiny egg's gleam.
const EGG_POT := Vector3(POT_AT.x, STOVE_TOP + 0.46, POT_AT.z)
const EGG_R := Vector3(0.28, 0.35, 0.28)
const SHELL := Color("fbf2e2")
const SHELL_SHINY := Color("fff0b8")
const EGG_WHITE := Color("fffdf6")
const WATER := Color("7cc3f0")
## The basket of eggs on the table's right (its foot, world) and the shiny egg on it (its middle).
const BASKET_AT := Vector3(2.75, KitchenSet.TABLE_TOP, -0.2)
const BASKET := Color("c98d4f")
const SHINY_AT := Vector3(2.8, KitchenSet.TABLE_TOP + 0.52, -0.17)
## The magnifier window over the stove: its middle (world), its radius, the egg's inside in it.
const LENS_AT := Vector3(1.9, STOVE_TOP + 1.55, 0.45)
const LENS_R := 0.62
const LENS_FRAME := Color("6b4423")
const RAW_WHITE := Color("e6f3ff")
const COOKED_WHITE := Color("fffdf6")
const RAW_YOLK := Color("ff9f1c")
const COOKED_YOLK := Color("ffd43b")
## The flames: how tall (m) and where (x off the burner's middle) a burner's pair stands, their rate (rad/s).
const FLAME_H := 0.6
const FLAME_X := 0.68
const FLAME_RATE := 9.0
## The steam: puffs over the pot and the mold, how high they rise (m) and how fast (1/s).
const PUFFS := 4
const PUFF_RISE := 0.8
const PUFF_RATE := 0.45
const STEAM_WHITE := Color(1.0, 1.0, 1.0)
## The shell's three pieces (their rest spots, relative to the egg: on the stove's top), how long the peel
## takes (s) and how far the egg's inside lifts the piece out (m).
const SHARDS := [Vector3(0.95, -0.43, 0.55), Vector3(-0.15, -0.43, 0.72), Vector3(1.15, -0.43, -0.1)]
const PEEL_S := 0.8
## The bread cat: how far left of the pot's middle it stands (its crates clear of the stove), how high its
## crates lift it over the table's top, how it grips (CatActor.grab's effort, the most it leans in deg).
const CAT_AT_X := -1.2
const CAT_STAND := 0.8
const CAT_PRESS := 0.4
const CAT_LEAN_MAX := 50.0
## The cast's place when the definition has none (bench runs): Puppy at the table's right end.
const PUPPY_AT := Vector2(4.0, 1.1)

var cat: CatActor
var cat_stand: CatCrates
var pot_pivot: Node3D           # tips about the pot's right foot (child 0: the pot)
var pot: Node3D
var pot_content: MeshInstance3D
var water: MeshInstance3D
var bubbles: Array[MeshInstance3D] = []
var handle: MeshInstance3D
var handle_ring: MeshInstance3D
var flames: Array[Node3D] = []   # pot's left, pot's right, mold's left, mold's right
var mold: Node3D
var mold_content: MeshInstance3D
var stream: Node3D              # the pour: STREAM_LINKS links along a falling arc (children)
var egg: Node3D
var egg_inner: MeshInstance3D
var egg_shell: MeshInstance3D
var _shell_plain: Mesh
var _shell_shiny: Mesh
var shards: Array[MeshInstance3D] = []
var basket: Node3D
var shiny_egg: Node3D
var lens: Node3D
var lens_inside: MeshInstance3D
var steam_pot: MultiMeshInstance3D
var steam_mold: MultiMeshInstance3D
## What is shown now (tests).
var shown_item := -1.0
var shown_site := -1.0
var shown_soft := -1.0
var shown_molten := false
var shown_slab := false
var shown_done := -1.0
var shown_poured := false
var shown_core := ROOM_START
var shown_heat := false
var shown_boiling := false
var peeled := false
## The pot's tip now (deg), the pot's chocolate level (1 full .. 0 poured out) and the star's (0 empty .. 1 full).
var tilt := 0.0
var pot_level := 1.0
var mold_level := 0.0
## The bread cat grips the pot's handle (true) or stands (false).
var gripping := false
## The pour is under way (it started at _pour_at; -1 none), the peel too.
var _pour_at := -1.0
var _peel_at := -1.0
var _t := 0.0
var _content_key := []
var _mold_key := []
var _lens_key := []
var _handle_k := 0.0
var _flame_k := 0.0
var _pressing := false

const ROOM_START := MeltCookModel.ROOM_C


## Builds the kitchen and everything on the table for `lab`; Puppy's place from its cast (unused: only the
## definition's cast places him).
func build(lab: Node3D) -> void:
	KitchenSet.build(lab)
	var stove := ArtKit.instance(_stove_mesh())
	stove.name = "Stove"
	lab.add_child(stove)
	handle = ArtKit.instance(_handle_mesh())
	handle.name = "Handle"
	handle.position = HANDLE_AT
	lab.add_child(handle)
	handle_ring = ArtKit.instance(_ring_mesh(), _unshaded())
	handle_ring.name = "HandleRing"
	handle_ring.position = HANDLE_AT + Vector3(0.0, 0.0, 0.01)
	handle_ring.visible = false
	lab.add_child(handle_ring)
	# The pot tips about its right foot: the pivot node stands there, the pot hangs left of it.
	pot_pivot = Node3D.new()
	pot_pivot.name = "PotPivot"
	pot_pivot.position = POT_AT + POT_PIVOT
	lab.add_child(pot_pivot)
	pot = Node3D.new()
	pot.name = "Pot"
	pot.position = -POT_PIVOT
	pot_pivot.add_child(pot)
	pot.add_child(ArtKit.instance(_pot_mesh()))
	pot_content = ArtKit.instance(ArrayMesh.new())
	pot_content.name = "PotContent"
	pot.add_child(pot_content)
	water = ArtKit.instance(_disc_mesh(POT_RT - 0.05, WATER), _unshaded())
	water.name = "Water"
	water.position = Vector3(0.0, POT_H + 0.006, 0.0)
	water.visible = false
	pot.add_child(water)
	for i in 4:
		var bubble := ArtKit.instance(_ball_mesh(0.06 + 0.02 * (i % 2), Color.WHITE), _unshaded())
		bubble.name = "Bubble%d" % i
		bubble.visible = false
		pot.add_child(bubble)
		bubbles.append(bubble)
	for i in 4:
		var burner := POT_AT if i < 2 else MOLD_AT
		var flame := ArtKit.instance(_flame_mesh(), _unshaded())
		flame.name = "Flame%d" % i
		flame.position = burner + Vector3(FLAME_X * (-1.0 if i % 2 == 0 else 1.0), 0.0, 0.0)
		flame.visible = false
		lab.add_child(flame)
		flames.append(flame)
	mold = Node3D.new()
	mold.name = "Mold"
	mold.position = MOLD_AT
	mold.visible = false
	lab.add_child(mold)
	mold.add_child(ArtKit.instance(_mold_mesh()))
	mold_content = ArtKit.instance(ArrayMesh.new())
	mold_content.name = "MoldContent"
	mold.add_child(mold_content)
	stream = Node3D.new()
	stream.name = "Stream"
	stream.visible = false
	lab.add_child(stream)
	for i in STREAM_LINKS:
		var link := ArtKit.instance(_stream_mesh())
		link.name = "Link%d" % i
		stream.add_child(link)
	egg = Node3D.new()
	egg.name = "Egg"
	egg.position = EGG_POT
	egg.visible = false
	lab.add_child(egg)
	egg_inner = ArtKit.instance(_egg_mesh(EGG_WHITE, 0.92))
	egg_inner.name = "Inner"
	egg.add_child(egg_inner)
	_shell_plain = _egg_mesh(SHELL, 1.0)
	_shell_shiny = _egg_mesh(SHELL_SHINY, 1.0, true)
	egg_shell = ArtKit.instance(_shell_plain)
	egg_shell.name = "Shell"
	egg.add_child(egg_shell)
	for i in SHARDS.size():
		var shard := ArtKit.instance(_shard_mesh())
		shard.name = "Shard%d" % i
		shard.visible = false
		lab.add_child(shard)
		shards.append(shard)
	basket = Node3D.new()
	basket.name = "Basket"
	basket.position = BASKET_AT
	lab.add_child(basket)
	basket.add_child(ArtKit.instance(_basket_mesh()))
	shiny_egg = Node3D.new()
	shiny_egg.name = "ShinyEgg"
	shiny_egg.position = SHINY_AT - BASKET_AT
	basket.add_child(shiny_egg)
	shiny_egg.add_child(ArtKit.instance(_shell_shiny))
	lens = Node3D.new()
	lens.name = "Lens"
	lens.position = LENS_AT
	lens.visible = false
	lab.add_child(lens)
	lens.add_child(ArtKit.instance(_lens_mesh()))
	lens_inside = ArtKit.instance(ArrayMesh.new())
	lens_inside.name = "LensInside"
	lens_inside.position = Vector3(0.0, 0.0, 0.09)
	lens.add_child(lens_inside)
	steam_pot = _steam(lab, "SteamPot")
	steam_mold = _steam(lab, "SteamMold")
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = pot
	# Square crates: the bag stays on them facing the front (watching) or the pot (gripping).
	var side := maxf(cat.look.footprint.x, cat.look.footprint.y)
	cat_stand = CatCrates.new(Vector2(side, side))
	lab.add_child(cat_stand)
	_place_cat()


# --- where things stand ---------------------------------------------------------------------------

## Where the bread cat stands (its base on its crates, world).
static func cat_point() -> Vector3:
	return Vector3(CAT_AT_X, KitchenSet.TABLE_TOP + CAT_STAND, POT_AT.z)


## The pot's grip (world) when it is tipped `degrees` about its right foot: the handle's grip point
## turned clockwise (seen from the front) about the foot.
static func grip_point(degrees: float) -> Vector3:
	var rel := POT_GRIP - POT_PIVOT
	var a := deg_to_rad(degrees)
	var turned := Vector3(rel.x * cos(a) + rel.y * sin(a), -rel.x * sin(a) + rel.y * cos(a), 0.0)
	return POT_AT + POT_PIVOT + turned


## The pot's lip (its right rim, world) when it is tipped `degrees`: where the stream leaves.
static func lip_point(degrees: float) -> Vector3:
	var rel := Vector3(POT_RT - POT_RB, POT_H, 0.0)
	var a := deg_to_rad(degrees)
	var turned := Vector3(rel.x * cos(a) + rel.y * sin(a), -rel.x * sin(a) + rel.y * cos(a), 0.0)
	return POT_AT + POT_PIVOT + turned


## Where the cat's paws ([right, left], world) hold the grip at `grip` from `root`: either side of the
## handle across the cat's facing.
static func paw_points(grip: Vector3, root: Vector3) -> Array[Vector3]:
	var f := Vector3(grip.x - root.x, 0.0, grip.z - root.z).normalized()
	var right := Vector3(-f.z, 0.0, f.x)
	return [grip + right * PAW_HALF, grip - right * PAW_HALF] as Array[Vector3]


## The star's outline (a flat polygon in x / z: `points` outer points alternating with inner ones) of
## outer radius `outer` and inner `inner`, point up (towards -z, the back).
static func star_points(outer: float, inner: float, points := 5) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in points * 2:
		var r := outer if i % 2 == 0 else inner
		var a := -PI * 0.5 + PI * i / points
		out.append(Vector3(cos(a) * r, 0.0, sin(a) * r))
	return out


# --- what the lab says ----------------------------------------------------------------------------

## The handle is pressed (true) or let go (false).
func press(on: bool) -> void:
	_pressing = on


## The stage-2 pour starts now: the cat tips the pot over the star mold, pours and sets it back.
func begin_pour() -> void:
	_pour_at = _t
	_peel_at = -1.0


## Whether the pour is going on now.
func pouring() -> bool:
	return _pour_at >= 0.0 and _t - _pour_at < TIP_S + POUR_S + BACK_S


## The round is won with the egg: the bread cat peels it (the shell cracks into pieces, the inside shows).
func begin_peel() -> void:
	_peel_at = _t


func peeling() -> bool:
	return _peel_at >= 0.0 and _t - _peel_at < PEEL_S


## How far the peel has gone (0 shut .. 1 done); 0 when there is none, 1 once peeled.
func peel_share() -> float:
	if peeled and _peel_at < 0.0:
		return 1.0
	if _peel_at < 0.0:
		return 0.0
	return clampf((_t - _peel_at) / PEEL_S, 0.0, 1.0)


## The egg's top (world): where the piece rises from once the shell is off.
func egg_top() -> Vector3:
	return EGG_POT + Vector3(0.0, EGG_R.y, 0.0)


## Back to the first state without any animation (a stage reached by jump or a reset): the pour is over
## (when the site is poured), the shell is back on.
func settle(poured: bool) -> void:
	_pour_at = -1.0
	_peel_at = -1.0
	peeled = false
	tilt = 0.0
	pot_level = 0.0 if poured else 1.0
	mold_level = 1.0 if poured else 0.0
	gripping = false
	_content_key = []
	_mold_key = []


## Poses everything for the model now.
func show(m: MeltCookModel) -> void:
	var egg_item := m.is_egg()
	var poured := m.poured()
	var in_pot := egg_item and m.site() >= MeltCookModel.SHINY
	if shown_item != m.input("item") or shown_site != m.site():
		if poured and not pouring() and mold_level < 1.0:
			mold_level = 1.0
			pot_level = 0.0
		elif not poured and not egg_item:
			mold_level = 0.0
			pot_level = 1.0
			_pour_at = -1.0
		egg_shell.mesh = _shell_shiny if in_pot else _shell_plain
	shown_item = m.input("item")
	shown_site = m.site()
	shown_poured = poured
	shown_soft = m.softness()
	shown_molten = m.molten()
	shown_slab = m.input("slab") > 0.5
	shown_done = m.input("doneness")
	shown_core = m.core_c()
	shown_heat = m.pressing()
	shown_boiling = m.boiling()
	_pressing = m.pressing()
	if shown_done <= 0.0 and not m.touched() and not peeling():
		peeled = false
		_peel_at = -1.0
	mold.visible = poured
	water.visible = egg_item
	egg.visible = egg_item
	lens.visible = egg_item
	shiny_egg.visible = not in_pot
	_draw_pot(m)
	_draw_mold(m)
	_draw_lens(m)
	_pose_heat(m)


# --- drawing --------------------------------------------------------------------------------------

## The pot's content: the chocolate block / puddle / slab (the chocolate's level while it pours out),
## or the water of the egg's pot.
func _draw_pot(m: MeltCookModel) -> void:
	var egg_item := m.is_egg()
	var level := snappedf(pot_level, 0.05)
	var key := [egg_item, snappedf(m.softness(), 0.1), m.molten(), m.input("slab") > 0.5, level]
	if key == _content_key:
		return
	_content_key = key
	if egg_item or level <= 0.0:
		pot_content.mesh = _film_mesh() if (not egg_item and level <= 0.0) else ArrayMesh.new()
		return
	pot_content.mesh = _chocolate_mesh(m.softness(), m.molten(), m.input("slab") > 0.5, level)


## The star mold's chocolate: runny and shiny, or set (matte, lighter), as full as the pour has filled it.
func _draw_mold(m: MeltCookModel) -> void:
	var level := snappedf(mold_level, 0.05)
	var key := [m.molten(), level]
	if key == _mold_key:
		return
	_mold_key = key
	mold_content.mesh = _star_mesh(m.molten(), level) if level > 0.0 else ArrayMesh.new()


## The magnifier window's inside: the egg's white and yolk, milky and yellow as the egg cooks.
func _draw_lens(m: MeltCookModel) -> void:
	var done := snappedf(m.input("doneness"), 0.1)
	if [done] == _lens_key:
		return
	_lens_key = [done]
	lens_inside.mesh = _lens_inside_mesh(done)


## The flames, the ring, the steam, the bubbles: what the heat does.
func _pose_heat(m: MeltCookModel) -> void:
	var on_pot := m.is_egg() or not m.poured()
	for i in flames.size():
		flames[i].visible = _pressing and ((i < 2) == on_pot)
	handle_ring.visible = _pressing
	steam_pot.visible = (m.is_egg() or not m.poured()) and m.steaming()
	steam_mold.visible = m.poured() and m.core_c() >= MeltCookModel.COOL_C + 3.0 and mold_level > 0.5
	for b in bubbles:
		b.visible = m.boiling()


## Steam puffs: a MultiMesh of soft lumps (SoftCloud), one per puff.
func _steam(lab: Node3D, node_name: String) -> MultiMeshInstance3D:
	var steam := MultiMeshInstance3D.new()
	steam.name = node_name
	steam.multimesh = MultiMesh.new()
	steam.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	steam.multimesh.mesh = SoftCloud.mesh()
	steam.multimesh.instance_count = PUFFS
	steam.material_override = SoftCloud.material(STEAM_WHITE, 0.4, GlassCup.STEAM_PRIORITY)
	steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	steam.visible = false
	lab.add_child(steam)
	return steam


## Poses the animated parts (`delta` s): the cat, the pour, the peel, the flames, the steam, the bubbles,
## the handle.
func advance(delta: float) -> void:
	_t += delta
	_handle_k = move_toward(_handle_k, 1.0 if _pressing else 0.0, delta / 0.12)
	handle.position = HANDLE_AT + Vector3(0.0, 0.0, -HANDLE_SINK * _handle_k)
	handle.scale = Vector3.ONE * (1.0 - 0.1 * _handle_k)
	_flame_k = move_toward(_flame_k, 1.0 if _pressing else 0.0, delta / 0.15)
	for i in flames.size():
		var flicker := 0.85 + 0.15 * sin(_t * FLAME_RATE + i * 1.7) + 0.08 * sin(_t * FLAME_RATE * 1.9 + i)
		flames[i].scale = Vector3(1.0, _flame_k * flicker, 1.0)
	_advance_pour(delta)
	_advance_peel()
	_advance_steam(steam_pot, POT_AT + Vector3(0.0, POT_H + 0.25, 0.0))
	_advance_steam(steam_mold, MOLD_AT + Vector3(0.0, 0.2, 0.0))
	for i in bubbles.size():
		if bubbles[i].visible:
			var k := fposmod(_t * 1.7 + i * 0.31, 1.0)
			var angle := i * 1.9 + _t * 0.5
			bubbles[i].position = Vector3(cos(angle) * 0.32, POT_H + 0.04 + 0.1 * k, sin(angle) * 0.2) if i % 2 == 0 else Vector3(-cos(angle) * 0.3, POT_H + 0.06 + 0.1 * k, sin(angle) * 0.25)
			bubbles[i].scale = Vector3.ONE * (1.0 - 0.5 * k)
	egg.position = EGG_POT + Vector3(0.0, 0.015 * sin(_t * 4.0) if shown_boiling else 0.0, 0.0)
	_place_cat()


func _advance_steam(steam: MultiMeshInstance3D, base: Vector3) -> void:
	if not steam.visible:
		return
	for i in PUFFS:
		var k := fposmod(_t * PUFF_RATE + i / float(PUFFS), 1.0)
		var at := base + Vector3(0.12 * sin(_t * 1.3 + i * 2.0), k * PUFF_RISE, 0.0)
		var size := lerpf(0.12, 0.26, k) * (1.0 - k * k * k)
		steam.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * maxf(size, 0.001)), at))


## The pour: the pot tips (TIP_S), the chocolate runs from its lip into the star (POUR_S), the pot
## comes back (BACK_S); the chocolate leaves the pot and fills the star as it goes.
func _advance_pour(_delta: float) -> void:
	var since := _t - _pour_at if _pour_at >= 0.0 else -1.0
	var total := TIP_S + POUR_S + BACK_S
	var pouring_now := since >= 0.0 and since < total
	if since >= total:
		_pour_at = -1.0
		tilt = 0.0
		pot_level = 0.0
		mold_level = 1.0
	elif pouring_now:
		if since < TIP_S:
			tilt = TILT_MAX * _smooth(since / TIP_S)
		elif since < TIP_S + POUR_S:
			tilt = TILT_MAX
			var share := _smooth((since - TIP_S) / POUR_S)
			pot_level = 1.0 - share
			mold_level = share
		else:
			tilt = TILT_MAX * (1.0 - _smooth((since - TIP_S - POUR_S) / BACK_S))
			pot_level = 0.0
			mold_level = 1.0
	pot_pivot.rotation.z = -deg_to_rad(tilt)
	pot_content.rotation.z = deg_to_rad(tilt)
	var flowing := pouring_now and since >= TIP_S * 0.7 and since < TIP_S + POUR_S + 0.1
	stream.visible = flowing
	if flowing:
		_stretch_stream(lip_point(tilt), MOLD_AT + Vector3(STREAM_AT_X, MOLD_TRAY.y + 0.02 + 0.05 * mold_level, 0.0))
	gripping = pouring_now
	if pouring_now:
		_content_key = []
		_mold_key = []


## The stream from `from` (the lip) to `to` (the star): links along an arc that starts out level and
## falls faster as it goes.
func _stretch_stream(from: Vector3, to: Vector3) -> void:
	var points: Array[Vector3] = []
	for i in STREAM_LINKS + 1:
		var u := i / float(STREAM_LINKS)
		points.append(Vector3(lerpf(from.x, to.x, u), lerpf(from.y, to.y, u * u), lerpf(from.z, to.z, u)))
	for i in STREAM_LINKS:
		ArtKit.stretch_link(stream.get_child(i) as Node3D, points[i], points[i + 1])


func _advance_peel() -> void:
	var share := peel_share()
	egg_shell.visible = share < 0.5 and not peeled
	egg_shell.scale = Vector3.ONE * (1.0 + 0.2 * clampf(share * 2.0, 0.0, 1.0))
	for i in shards.size():
		var shard := shards[i]
		shard.visible = peeled or share > 0.0
		if not shard.visible:
			continue
		var k := _smooth(clampf(share * 1.4, 0.0, 1.0))
		var rest: Vector3 = EGG_POT + (SHARDS[i] as Vector3)
		var from := EGG_POT + Vector3(0.0, 0.1, 0.0)
		shard.position = from.lerp(rest, k) + Vector3.UP * 0.5 * sin(PI * k)
		shard.rotation = Vector3(0.0, 0.7 * i, 0.5 * k * (i + 1))
	if share >= 1.0:
		peeled = true


## The cat on its crates: gripping the pot's handle while the pour goes, otherwise standing.
func _place_cat() -> void:
	var root := cat_point()
	if gripping:
		var grip := grip_point(tilt)
		cat.grab(root, CatActor.facing(root, grip), paw_points(grip, root), CAT_PRESS, CAT_LEAN_MAX)
	elif cat.mode == "grab":
		cat.let_go(Vector3.ZERO)
	elif cat.mode == "free":
		cat.stand(root)
	cat_stand.fit(cat, KitchenSet.TABLE_TOP)


static func _smooth(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


# --- meshes ---------------------------------------------------------------------------------------

static func _unshaded() -> Material:
	return ArtKit.lit_material()


## The stove: an iron box with a lighter top plate, two dark burners and the handle's collar.
static func _stove_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = STOVE_SIZE.y
	b.add_rounded_box(Transform3D(Basis(), STOVE_AT + Vector3(0.0, STOVE_SIZE.y * 0.5 - 0.03, 0.0)), STOVE_SIZE - Vector3(0.0, 0.06, 0.0), 0.05, 1, STOVE, STOVE.lightened(0.1))
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), Vector3(STOVE_AT.x, STOVE_TOP - 0.03, STOVE_AT.z)), Vector3(STOVE_SIZE.x + 0.08, 0.07, STOVE_SIZE.z + 0.08), 0.03, 1, STOVE_PLATE, STOVE_PLATE.lightened(0.15))
	for at: Vector3 in [POT_AT, MOLD_AT]:
		b.add_cylinder(Transform3D(Basis(), at), 0.7, 0.68, 0.02, 20, BURNER, true, BURNER.lightened(0.12))
	var collar := Vector3(HANDLE_AT.x, HANDLE_AT.y, STOVE_AT.z + STOVE_SIZE.z * 0.5)
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), collar), HANDLE_R + 0.08, HANDLE_R + 0.08, 0.03, 16, STOVE_PLATE, true, STOVE_PLATE.lightened(0.2))
	return b.commit()


## The red handle: a thick round knob facing the front (its middle at the origin) with a lighter dome
## in its middle (a button to press, not a sign).
static func _handle_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, -0.04)), HANDLE_R, HANDLE_R * 0.92, 0.1, 18, HANDLE_RED, true, HANDLE_RED.lightened(0.25))
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.45)), Vector3(0.0, 0.0, 0.06)), HANDLE_R * 0.62, 4, 14, HANDLE_RED.lightened(0.22))
	return b.commit()


## The ring round the pressed handle: a flat yellow band facing the front.
static func _ring_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var r := HANDLE_R + 0.1
	for i in 24:
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		var d0 := Vector3(cos(a0), sin(a0), 0.0)
		var d1 := Vector3(cos(a1), sin(a1), 0.0)
		b.add_triangle([d0 * r, d1 * r, d1 * (r - 0.05)], [HANDLE_RING, HANDLE_RING, HANDLE_RING], Vector3.BACK)
		b.add_triangle([d0 * r, d1 * (r - 0.05), d0 * (r - 0.05)], [HANDLE_RING, HANDLE_RING, HANDLE_RING], Vector3.BACK)
	return b.commit()


## The pot: a steel pot with a dark rim, a handle to the left (its end at POT_HANDLE_END) and a small
## lip on the right; its foot at the origin.
static func _pot_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = POT_H
	b.add_cylinder(Transform3D(), POT_RB, POT_RT, POT_H, 20, POT_METAL, true, POT_DARK)
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, POT_H - 0.03, 0.0)), POT_RT + 0.02, POT_RT + 0.02, 0.04, 20, POT_DARK, true, POT_DARK.lightened(0.1))
	var bar_from := -POT_RT * 0.9
	b.add_rounded_box(Transform3D(Basis(), Vector3((bar_from + POT_HANDLE_END.x) * 0.5, POT_HANDLE_END.y, 0.0)), Vector3(bar_from - POT_HANDLE_END.x, 0.08, 0.1), 0.02, 1, POT_DARK, POT_DARK.lightened(0.2))
	b.add_rounded_box(Transform3D(Basis(), Vector3(POT_RT + 0.04, POT_H - 0.02, 0.0)), Vector3(0.1, 0.05, 0.12), 0.015, 1, POT_DARK)
	return b.commit()


## The chocolate in the pot at `level` (1 full .. 0): two blocks that soften and sink, a runny puddle when
## melted, a flat slab when it has set again.
static func _chocolate_mesh(soft: float, molten: bool, slab: bool, level: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	# The pot is full to its rim (its lid is the top you look down on): the puddle covers it, the blocks
	# stand in it a little.
	var rim := POT_H - 0.02
	if molten or slab:
		var color := CHOC_MELT if molten else CHOC_SET
		var top := CHOC_MELT.lightened(0.05) if molten else CHOC_SET_TOP
		var r := (POT_RT - 0.05) * lerpf(0.35, 1.0, sqrt(level))
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, rim, 0.0)), r, r, 0.04 if molten else 0.08, 20, color, true, top)
		if molten:
			ArtKit.flat_disc(b, Vector3(-0.18, rim + 0.042, 0.1), r * 0.3, CHOC_SHINE, 10)
	else:
		var k := clampf(soft / MeltCookModel.SOFT_MAX, 0.0, 1.0)
		for block: Array in [[Vector3(-0.15, 0.0, 0.05), Vector3(0.4, 0.36, 0.34)], [Vector3(0.16, 0.0, -0.04), Vector3(0.36, 0.32, 0.32)]]:
			var size: Vector3 = block[1]
			var squash := Vector3(1.0 + 0.2 * k, 1.0 - 0.45 * k, 1.0 + 0.2 * k)
			var s := size * squash * Vector3(1.0, level, 1.0)
			var at: Vector3 = block[0]
			b.add_rounded_box(Transform3D(Basis(), Vector3(at.x, rim + s.y * 0.5 - 0.06, at.z)), s, minf(0.02 + 0.1 * k, minf(s.x, minf(s.y, s.z)) * 0.5 - 0.001), 2, CHOC_BLOCK.lerp(CHOC_MELT, k), CHOC_BLOCK_TOP.lerp(CHOC_MELT.lightened(0.05), k))
	return b.commit()


## What is left in the poured-out pot: a thin film on its floor.
static func _film_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, POT_H + 0.002, 0.0)), POT_RT - 0.05, POT_RT - 0.05, 0.01, 20, POT_DARK.darkened(0.35), true, POT_DARK.darkened(0.35))
	b.add_cylinder(Transform3D(Basis(), Vector3(0.12, POT_H + 0.012, 0.05)), 0.2, 0.2, 0.01, 12, CHOC_MELT, true, CHOC_MELT)
	return b.commit()


## The star mold's tray: a steel tray with a star-shaped dish (its edge), the dish's floor.
static func _mold_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = 0.2
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, MOLD_TRAY.y * 0.5, 0.0)), MOLD_TRAY, 0.03, 1, MOLD_METAL, MOLD_METAL.lightened(0.1))
	var rim := star_points(STAR_R + 0.07, STAR_r + 0.03)
	var inner := star_points(STAR_R + 0.01, STAR_r)
	var y := MOLD_TRAY.y + 0.003
	for i in rim.size():
		var j := (i + 1) % rim.size()
		var p: Array = [rim[i] + Vector3.UP * y, rim[j] + Vector3.UP * y, Vector3.UP * y]
		b.add_triangle(p, [MOLD_EDGE, MOLD_EDGE, MOLD_EDGE], Vector3.UP)
	for i in inner.size():
		var j := (i + 1) % inner.size()
		var p: Array = [inner[i] + Vector3.UP * (y + 0.002), inner[j] + Vector3.UP * (y + 0.002), Vector3.UP * (y + 0.002)]
		b.add_triangle(p, [MOLD_METAL.darkened(0.1), MOLD_METAL.darkened(0.1), MOLD_METAL.darkened(0.1)], Vector3.UP)
	return b.commit()


## The chocolate in the star at `level` (0..1: how full), runny and shiny, or set (matte, lighter, edged).
static func _star_mesh(molten: bool, level: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var color := CHOC_MELT if molten else CHOC_SET
	var top := CHOC_MELT.lightened(0.04) if molten else CHOC_SET_TOP
	var scale := lerpf(0.55, 1.0, sqrt(level))
	var outline := star_points(STAR_R * scale, STAR_r * scale)
	var y := MOLD_TRAY.y + 0.006 + 0.05 * level
	for i in outline.size():
		var j := (i + 1) % outline.size()
		b.add_triangle([outline[i] + Vector3.UP * y, outline[j] + Vector3.UP * y, Vector3.UP * y], [top, top, top], Vector3.UP)
		# The side of the chocolate (the star's thickness).
		var lo := Vector3.UP * (MOLD_TRAY.y + 0.004)
		var q: Array = [outline[i] + lo, outline[j] + lo, outline[j] + Vector3.UP * y, outline[i] + Vector3.UP * y]
		var out := ((outline[i] + outline[j]) * 0.5).normalized()
		b.add_triangle([q[0], q[1], q[2]], [color, color, color], out)
		b.add_triangle([q[0], q[2], q[3]], [color, color, color], out)
	if molten:
		ArtKit.flat_disc(b, Vector3(-0.12, y + 0.002, -0.08) * scale, 0.14 * scale, CHOC_SHINE, 10)
	else:
		var edge := CHOC_SET_TOP.lightened(0.25)
		var a := Vector3(-0.2, y + 0.003, -0.12) * scale
		var c := Vector3(0.0, y + 0.003, -0.34) * scale
		var d := Vector3(0.2, y + 0.003, -0.12) * scale
		b.add_triangle([a, c, c + Vector3(0.0, 0.0, 0.05)], [edge, edge, edge], Vector3.UP)
		b.add_triangle([c, d, c + Vector3(0.0, 0.0, 0.05)], [edge, edge, edge], Vector3.UP)
	return b.commit()


## The stream of melted chocolate from the pot's lip to the star: a link of length 1 stretched between them.
static func _stream_mesh() -> Mesh:
	return ArtKit.link_mesh(0.045, CHOC_MELT)


## A flat disc facing up at the origin, `radius` wide.
static func _disc_mesh(radius: float, color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	ArtKit.flat_disc(b, Vector3.ZERO, radius, color, 20)
	return b.commit()


static func _ball_mesh(radius: float, color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), radius, 3, 8, color)
	return b.commit()


## One flame: two crossing flat tongues (so it shows from the side views too), an orange one with a
## yellow heart, each curling a little to one side; its foot at the origin (scaled in y to flicker).
static func _flame_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for yaw: float in [0.0, PI * 0.5]:
		_flame_sheet(b, FLAME_H, 0.2, 0.0, yaw, Color("ff7a1a"))
		_flame_sheet(b, FLAME_H * 0.6, 0.12, 0.02, yaw, Color("ffd43b"))
	return b.commit()


## A flat tongue of flame `height` tall and `width` half-wide, turned `yaw` about the vertical, `lift` in
## front of the sheet behind it (both faces are drawn).
static func _flame_sheet(b: ArtMeshBuilder, height: float, width: float, lift: float, yaw: float, color: Color) -> void:
	var rows := 7
	var spin := Basis(Vector3.UP, yaw)
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in rows + 1:
		var t := i / float(rows)
		var half := width * sin(PI * pow(t, 0.62)) * (1.0 - 0.3 * t)
		var sway := 0.22 * height * t * t
		left.append(spin * Vector3(-half + sway, height * t, lift))
		right.append(spin * Vector3(half + sway, height * t, lift))
	for i in rows:
		var quad: Array = [left[i], right[i], right[i + 1], left[i + 1]]
		for facing: Vector3 in [spin * Vector3.BACK, spin * Vector3.FORWARD]:
			b.add_triangle([quad[0], quad[1], quad[2]], [color, color, color], facing)
			b.add_triangle([quad[0], quad[2], quad[3]], [color, color, color], facing)


## An egg of the size EGG_R (`scale` of it) at the origin: a cream shell, a small shine; the shiny egg
## also has a golden gleam.
static func _egg_mesh(color: Color, scale: float, shiny := false) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.9
	b.ao_height = EGG_R.y * 2.0
	b.add_sphere(Transform3D(Basis.from_scale(EGG_R * scale), Vector3.ZERO), 1.0, 7, 16, color)
	b.ao_min = 1.0
	b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.05, 0.08, 0.04) * scale), Vector3(-0.11, 0.14, 0.2) * scale), 1.0, 3, 6, Color.WHITE)
	if shiny:
		for spot: Vector3 in [Vector3(0.2, 0.2, 0.2), Vector3(-0.19, -0.1, 0.22)]:
			b.add_sphere(Transform3D(Basis.from_scale(Vector3.ONE * 0.04), spot), 1.0, 3, 6, Color("fff7cf"))
	return b.commit()


## One shell piece: a small curved chip.
static func _shard_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), Vector3.ZERO), Vector3(0.16, 0.03, 0.12), 0.01, 1, SHELL, SHELL.lightened(0.05))
	return b.commit()


## The basket on the table: a woven tub with the plain eggs in it (the shiny one is its own node).
static func _basket_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.4
	b.add_cylinder(Transform3D(), 0.42, 0.5, 0.34, 14, BASKET, true, BASKET.darkened(0.25))
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.3, 0.0)), 0.52, 0.52, 0.05, 14, BASKET.lightened(0.1), true, BASKET.lightened(0.2))
	for k in 3:
		var a := 0.4 + k * 2.1
		var at := Vector3(cos(a) * 0.2, 0.42, sin(a) * 0.16 + 0.04)
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.2, 0.26, 0.2)), at), 1.0, 4, 8, SHELL.darkened(0.04 * k))
	return b.commit()


## The magnifier window: a round frame facing the front with a handle, a pale glass, three dots from the
## stove up to it (this is the egg's inside).
static func _lens_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, 0.0)), LENS_R, LENS_R, 0.07, 24, LENS_FRAME, true, LENS_FRAME)
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, 0.0)), LENS_R - 0.07, LENS_R - 0.07, 0.085, 24, Color("f4fbff"), true, Color("f4fbff"))
	b.add_rounded_box(Transform3D(Basis(Vector3.BACK, deg_to_rad(40.0)), Vector3(LENS_R * 0.9, -LENS_R * 0.95, 0.0)), Vector3(0.12, 0.5, 0.1), 0.03, 1, LENS_FRAME)
	var toward := (EGG_POT - LENS_AT).normalized()
	for k in 3:
		b.add_sphere(Transform3D(Basis(), toward * (LENS_R + 0.2 + k * 0.2)), 0.035, 3, 6, LENS_FRAME)
	return b.commit()


## The egg's inside in the window at cooking share `done` (0 raw .. 1 cooked): a clear white (or milky)
## oval and a yolk.
static func _lens_inside_mesh(done: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var white := RAW_WHITE.lerp(COOKED_WHITE, done)
	var yolk := RAW_YOLK.lerp(COOKED_YOLK, done)
	var rim := white.darkened(0.08)
	_oval(b, Vector2(0.4, 0.5), rim, 0.0)
	_oval(b, Vector2(0.36, 0.46), white, 0.004)
	_oval(b, Vector2(0.19, 0.19), yolk, 0.008, Vector2(0.0, -0.03))
	return b.commit()


## A flat oval facing the front: radii, colour, a hair off the window (so they do not fight), centre shift.
static func _oval(b: ArtMeshBuilder, r: Vector2, color: Color, z: float, shift := Vector2.ZERO) -> void:
	var c := Vector3(shift.x, shift.y, z)
	for i in 20:
		var a0 := TAU * i / 20.0
		var a1 := TAU * (i + 1) / 20.0
		b.add_triangle([c, c + Vector3(cos(a0) * r.x, sin(a0) * r.y, 0.0), c + Vector3(cos(a1) * r.x, sin(a1) * r.y, 0.0)], [color, color, color], Vector3.BACK)
