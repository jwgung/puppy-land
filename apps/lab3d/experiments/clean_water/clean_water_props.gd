## The 깨끗한 물 만들기 lab's props (#160, 2026-11-18; the approved mockup "샘물 마을 몸 조작" 5): meshes only,
## posed from the model by CleanWaterLab._redraw(). Not the kitchen (no KitchenSet): the spring of the
## village, seen from the side and a little low (ArtKit.add_world):
## - on the left the muddy spring: a stone well with its little roof, a wooden trough running off it;
## - in the middle the filter: a see-through column standing on a clay jar (its layers seen in section:
##   empty, sand, or charcoal under sand; the soil the sand caught lies on top as a brown cake; a small
##   chamber at its foot shows the water come through, drops fall from it into the jar);
## - right of it the kettle of muddy water on a tilting stand (it tips with the tablet: left edge down,
##   the spout goes down and a stream as thick as the tilt runs into the column; tilted the other way it
##   only rocks back a little);
## - the touch stand-in (stages 1 and 2): an upright slot with a yellow ball right of the kettle: the ball
##   dragged down tips the kettle as far (MotionInput "touch");
## - stage 3: a wood fire in a stone ring with a pot of the clear water on it, the bellows on its right
##   (its handle dragged down and up blows the fire up: flames grow, the water steams and bubbles when it
##   boils) and the magnifier window over the pot (the germs: small faceless green rods and lilac balls,
##   paler as they die);
## - the bread cat by the filter (it holds it; it does the lab).
## Visual only: no body, nothing the model or the mission reads.
class_name CleanWaterProps
extends RefCounted

const WORLD_CENTER := Vector3(0.6, 0.0, -0.6)
## The well (its foot's middle), its radius and height, the roof's posts and top.
const WELL_AT := Vector3(-5.0, 0.0, -0.8)
const WELL_R := 0.95
const WELL_H := 1.1
const ROOF_Y := 2.55
const STONE := Color("9aa3b0")
const STONE_TOP := Color("b5bdc8")
const WOOD := Color("8a5a34")
const WOOD_LIGHT := Color("b07a48")
const ROOF := Color("a8573a")
const MUD := Color("8a6a3e")
const MUD_TOP := Color("9c7a4a")
## The trough: from the well's rim down to the spring yard (world).
const TROUGH_FROM := Vector3(-4.1, 1.25, -0.8)
const TROUGH_TO := Vector3(-1.6, 0.95, -0.8)
## The jar (its foot), its radius and height; the column over it (its foot, radius, top), its parts'
## heights (world y): the chamber at its foot, the charcoal, the sand.
const JAR_AT := Vector3(0.0, 0.0, 0.0)
const JAR_R := 0.58
const JAR_H := 0.95
const CLAY := Color("c27a45")
const CLAY_TOP := Color("a3602f")
const COLUMN_AT := Vector3(0.0, 1.25, 0.0)
const COLUMN_R := 0.42
const COLUMN_TOP := 2.85
const CHAMBER_TOP := 1.45
const CHARCOAL_TOP := 1.75
const SAND_TOP := 2.25
const SAND_ONLY_TOP := 2.05
const SAND := Color("e6c98a")
const SAND_TOP_COLOR := Color("f0d8a0")
const COAL := Color("2e2b2b")
const COAL_TOP := Color("4a4545")
const CAKE := Color("7a5a32")
## The water's looks: muddy, yellowish (sand only), clear.
const MUDDY := Color("8f6a3c")
const YELLOWISH := Color("d9c27a")
const CLEAR := Color("8fd0f2")
## The kettle: its stand (two legs and a ring), the pivot it tips about (world), its body and spout
## (relative to the pivot, untipped), how far it tips at a full tilt and back (deg).
const STAND_X := 1.75
const PIVOT := Vector3(1.6, 3.5, 0.0)
const KETTLE_BODY := Vector3(0.15, -0.15, 0.0)
const KETTLE_R := 0.5
const KETTLE_H := 0.85
const SPOUT_ROOT := Vector3(-0.3, -0.05, 0.0)
const SPOUT_TIP := Vector3(-1.2, 0.5, 0.0)
## The yoke holding the kettle's axle: how far under the pivot its cross bar is, how far in front of and
## behind the kettle its arms stand (m).
const YOKE_DROP := 0.6
const YOKE_Z := 0.62
const KETTLE := Color("c8834a")
const KETTLE_DARK := Color("8e5428")
const TIP_MAX := 35.0
const ROCK_BACK := 6.0
## How fast the drawn tip follows the tilt (1/s): the stream is smoothed once more (picture only).
const TIP_RATE := 9.0
## The stream: its links along a falling arc, its thickest and thinnest radius (m).
const STREAM_LINKS := 5
const STREAM_R := 0.14
const STREAM_MIN_R := 0.04
## The touch stand-in: the slot's x (world), top and bottom of its stroke, its z; the ball's radius.
const SLOT_X := 3.0
const SLOT_TOP := 3.9
const SLOT_BOTTOM := 2.3
const SLOT_Z := 0.3
const BALL_R := 0.2
const SLOT := Color("fbe7ee")
const SLOT_EDGE := Color("e8577f")
const BALL := Color("ffcf33")
## Stage 3: the fire's ring (its foot), the pot on it, the bellows (its nozzle's tip at the fire, the
## handle's top up and down, world), the magnifier window.
const HEARTH_AT := Vector3(3.3, 0.0, 0.1)
const HEARTH_R := 0.75
const POT_AT := Vector3(3.3, 0.75, 0.1)
const POT_R := 0.55
const POT_H := 0.55
const POT_METAL := Color("5b6270")
const POT_RIM := Color("3d434e")
const BELLOWS_AT := Vector3(4.55, 0.55, 0.25)
## The top board's hinge at its nozzle end (world), its handle's ball from the hinge with the board shut,
## how far the board opens (deg) with the handle up.
const HINGE := Vector3(4.0, 0.67, 0.25)
const HANDLE_REL := Vector3(1.2, 0.3, 0.0)
const OPEN_DEG := 30.0
const BELLOWS_WOOD := Color("9b6a3f")
const BELLOWS_LEATHER := Color("6b4a2e")
const LENS_AT := Vector3(3.3, 3.25, 0.6)
const LENS_R := 0.62
const LENS_FRAME := Color("6b4423")
const LENS_GLASS := Color("f4fbff")
const GERM_ROD := Color("7cc96a")
const GERM_BALL := Color("b79be6")
## The flames: how tall at a full fire (m), their rate (rad/s).
const FLAME_H := 0.9
const FLAME_RATE := 9.0
## The bread cat by the filter (its foot), Puppy's place when the definition has none.
const CAT_AT := Vector3(-1.25, 0.0, 0.25)
const PUPPY_AT := Vector2(6.6, 1.2)
## Steam puffs over the boiling pot.
const PUFFS := 4
const PUFF_RISE := 0.9
const PUFF_RATE := 0.45

var cat: CatActor
var kettle_pivot: Node3D
var stream: Node3D
var column_layers: MeshInstance3D
var column_water: MeshInstance3D
var drops: Array[MeshInstance3D] = []
var slot: Node3D
var ball: MeshInstance3D
var hearth: Node3D
var flames: Array[Node3D] = []
var pot_water: MeshInstance3D
var bubbles: Array[MeshInstance3D] = []
var bellows_top: Node3D
var lens: Node3D
var lens_inside: MeshInstance3D
var steam: MultiMeshInstance3D
var well_water: MeshInstance3D
## What is shown now (tests): the kettle's tip (deg), the stream's thickness (0..1), the ball's drop (0 top
## .. 1 bottom), the bellows handle's drop (0 up .. 1 down), the germs' strength in the window, the fire.
var tip := 0.0
var shown_stream := 0.0
var ball_drop := 0.0
var handle_drop := 0.0
var shown_germs := 1.0
var shown_fire := 0.0
var shown_filter := -1.0
var shown_site := -1.0
var _target_tip := 0.0
var _target_stream := 0.0
var _flowing := false
var _boiling := false
var _t := 0.0
var _layers_key := []
var _water_key := []
var _lens_key := -1.0


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	var still := ArtKit.instance(_still_mesh())
	still.name = "Spring"
	lab.add_child(still)
	well_water = ArtKit.instance(_disc_mesh(WELL_R - 0.12, MUD_TOP))
	well_water.name = "WellWater"
	well_water.position = WELL_AT + Vector3(0.0, WELL_H - 0.12, 0.0)
	lab.add_child(well_water)
	column_layers = ArtKit.instance(ArrayMesh.new())
	column_layers.name = "Layers"
	lab.add_child(column_layers)
	column_water = ArtKit.instance(ArrayMesh.new())
	column_water.name = "ColumnWater"
	lab.add_child(column_water)
	var glass := ArtKit.instance(_column_glass_mesh(), GlassCup._see_through(GlassCup.SHELL_PRIORITY))
	glass.name = "ColumnGlass"
	lab.add_child(glass)
	for i in 3:
		var drop := ArtKit.instance(_ball_mesh(0.045, CLEAR))
		drop.name = "Drop%d" % i
		drop.visible = false
		lab.add_child(drop)
		drops.append(drop)
	kettle_pivot = Node3D.new()
	kettle_pivot.name = "KettlePivot"
	kettle_pivot.position = PIVOT
	lab.add_child(kettle_pivot)
	kettle_pivot.add_child(ArtKit.instance(_kettle_mesh()))
	stream = Node3D.new()
	stream.name = "Stream"
	stream.visible = false
	lab.add_child(stream)
	var link := ArtKit.link_mesh(1.0, MUDDY)
	for i in STREAM_LINKS:
		var l := ArtKit.instance(link)
		l.name = "Link%d" % i
		stream.add_child(l)
	slot = Node3D.new()
	slot.name = "TiltSlot"
	lab.add_child(slot)
	slot.add_child(ArtKit.instance(_slot_mesh()))
	ball = ArtKit.instance(_ball_mesh(BALL_R, BALL))
	ball.name = "TiltBall"
	slot.add_child(ball)
	hearth = Node3D.new()
	hearth.name = "Hearth"
	hearth.visible = false
	lab.add_child(hearth)
	hearth.add_child(ArtKit.instance(_hearth_mesh()))
	for i in 3:
		var flame := ArtKit.instance(MeltCookProps._flame_mesh(), ArtKit.lit_material())
		flame.name = "Flame%d" % i
		flame.position = HEARTH_AT + Vector3((i - 1) * 0.32, 0.2, 0.05 * (i % 2))
		flame.scale = Vector3(1.0, 0.001, 1.0)
		hearth.add_child(flame)
		flames.append(flame)
	hearth.add_child(ArtKit.instance(_pot_mesh()))
	pot_water = ArtKit.instance(_disc_mesh(POT_R - 0.07, CLEAR))
	pot_water.name = "PotWater"
	pot_water.position = POT_AT + Vector3(0.0, POT_H - 0.04, 0.0)
	hearth.add_child(pot_water)
	for i in 4:
		var bubble := ArtKit.instance(_ball_mesh(0.05 + 0.02 * (i % 2), Color.WHITE))
		bubble.name = "Bubble%d" % i
		bubble.visible = false
		hearth.add_child(bubble)
		bubbles.append(bubble)
	hearth.add_child(ArtKit.instance(_bellows_base_mesh()))
	bellows_top = Node3D.new()
	bellows_top.name = "BellowsTop"
	bellows_top.position = HINGE
	hearth.add_child(bellows_top)
	bellows_top.add_child(ArtKit.instance(_bellows_top_mesh()))
	lens = Node3D.new()
	lens.name = "Lens"
	lens.position = LENS_AT
	hearth.add_child(lens)
	lens.add_child(ArtKit.instance(MeltCookProps._lens_mesh()))
	lens_inside = ArtKit.instance(ArrayMesh.new())
	lens_inside.name = "LensInside"
	lens_inside.position = Vector3(0.0, 0.0, 0.09)
	lens.add_child(lens_inside)
	steam = MultiMeshInstance3D.new()
	steam.name = "Steam"
	steam.multimesh = MultiMesh.new()
	steam.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	steam.multimesh.mesh = SoftCloud.mesh()
	steam.multimesh.instance_count = PUFFS
	steam.material_override = SoftCloud.material(Color.WHITE, 0.4, GlassCup.STEAM_PRIORITY)
	steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	steam.visible = false
	hearth.add_child(steam)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.stand(CAT_AT)
	cat.advance(0.0)


# --- where things are -----------------------------------------------------------------------------

## The spout's tip (world) with the kettle tipped `degrees` (left edge down positive).
static func spout_tip(degrees: float) -> Vector3:
	return PIVOT + Basis(Vector3.BACK, deg_to_rad(degrees)) * SPOUT_TIP


## Where the stream lands: the column's top middle.
static func stream_end() -> Vector3:
	return Vector3(COLUMN_AT.x, COLUMN_TOP - 0.05, COLUMN_AT.z)


## The kettle's body middle (world, untipped): its touch box.
static func kettle_center() -> Vector3:
	return PIVOT + KETTLE_BODY + Vector3(0.0, KETTLE_H * 0.5, 0.0)


## The ball of the touch stand-in at drop `k` (0 top .. 1 bottom, world).
static func ball_point(k: float) -> Vector3:
	return Vector3(SLOT_X, lerpf(SLOT_TOP, SLOT_BOTTOM, clampf(k, 0.0, 1.0)), SLOT_Z)


## The bellows handle's ball at drop `k` (0 up: the board open .. 1 down: shut, world).
static func handle_point(k: float) -> Vector3:
	return HINGE + Basis(Vector3.BACK, deg_to_rad(OPEN_DEG * (1.0 - clampf(k, 0.0, 1.0)))) * HANDLE_REL


## How far down (0..1) the handle is with its ball at `world` (its angle round the hinge).
static func handle_share(world: Vector3) -> float:
	var rel := world - HINGE
	var a := rad_to_deg(atan2(rel.y, rel.x) - atan2(HANDLE_REL.y, HANDLE_REL.x))
	return clampf(1.0 - a / OPEN_DEG, 0.0, 1.0)


## The tip the kettle shows for tilt `value` (deg): forward up to TIP_MAX, back a little.
static func tip_of(value: float) -> float:
	return TIP_MAX * value if value >= 0.0 else ROCK_BACK * value


## The look of water carrying `soil` and `colour` (0..1 each).
static func water_color(soil: float, colour: float) -> Color:
	return CLEAR.lerp(YELLOWISH, clampf(colour, 0.0, 1.0)).lerp(MUDDY, clampf(soil, 0.0, 1.0))


# --- posing ---------------------------------------------------------------------------------------

## Poses everything for the model now: the kettle's tilt (MotionInput, -1..1), the stand-in ball's drop.
func show(m: CleanWaterModel, tilt_value: float, drop: float, handle: float) -> void:
	var boil := m.boiling_site()
	shown_site = m.site()
	slot.visible = not boil
	hearth.visible = boil
	_target_tip = tip_of(tilt_value) if not boil else 0.0
	_target_stream = m.stream()
	ball_drop = drop
	ball.position = ball_point(drop)
	handle_drop = handle
	_flowing = m.input("column") > 0.0
	_draw_column(m)
	shown_fire = m.input("fire")
	_boiling = m.boiling()
	_draw_lens(m.input("pot_germs"))


func _draw_column(m: CleanWaterModel) -> void:
	var kind := m.filter()
	var caught := (1.0 - m.input("kettle")) * (1.0 - CleanWaterModel.soil_pass(kind))
	var key := [kind, snappedf(caught, 0.05)]
	if key != _layers_key:
		_layers_key = key
		shown_filter = kind
		column_layers.mesh = _layers_mesh(kind, caught)
	var wkey := [kind, snappedf(m.input("column"), 0.02), snappedf(m.input("jar"), 0.05), snappedf(m.input("soil"), 0.1), snappedf(m.input("colour"), 0.1)]
	if wkey != _water_key:
		_water_key = wkey
		column_water.mesh = _column_water_mesh(kind, m.input("column"), m.input("jar"), water_color(m.input("soil"), m.input("colour")))


func _draw_lens(germs: float) -> void:
	var g := snappedf(germs, 0.05)
	if g == _lens_key:
		return
	_lens_key = g
	shown_germs = g
	lens_inside.mesh = _germs_mesh(g)


## Moves what moves (`delta` s): the kettle's tip and its stream, the drops, the flames, the bubbles and the
## steam, the bellows' top board.
func advance(delta: float) -> void:
	_t += delta
	var k := 1.0 - exp(-delta * TIP_RATE)
	tip = lerpf(tip, _target_tip, k) if delta > 0.0 else _target_tip
	shown_stream = lerpf(shown_stream, _target_stream, k) if delta > 0.0 else _target_stream
	if _target_stream <= 0.0 and shown_stream < 0.02:
		shown_stream = 0.0
	kettle_pivot.rotation.z = deg_to_rad(tip)
	var on := shown_stream > 0.0 and tip > 8.0
	stream.visible = on
	if on:
		_stretch_stream(spout_tip(tip), stream_end(), lerpf(STREAM_MIN_R, STREAM_R, shown_stream))
	for i in drops.size():
		drops[i].visible = _flowing
		if _flowing:
			var f := fposmod(_t * 1.6 + i / 3.0, 1.0)
			drops[i].position = Vector3(COLUMN_AT.x, lerpf(COLUMN_AT.y - 0.02, JAR_H + 0.02, f * f), COLUMN_AT.z + 0.1)
	for i in flames.size():
		var flicker := 0.85 + 0.15 * sin(_t * FLAME_RATE + i * 1.7)
		var h := maxf(0.001, (0.15 + 0.85 * shown_fire) * flicker if shown_fire > CleanWaterModel.FIRE_OUT else 0.12 * flicker)
		flames[i].scale = Vector3(0.6 + 0.4 * shown_fire, h * FLAME_H / MeltCookProps.FLAME_H, 0.6 + 0.4 * shown_fire)
	for i in bubbles.size():
		bubbles[i].visible = _boiling
		if _boiling:
			var f := fposmod(_t * 1.7 + i * 0.31, 1.0)
			var a := i * 1.9 + _t * 0.5
			bubbles[i].position = POT_AT + Vector3(cos(a) * 0.3, POT_H + 0.02 + 0.1 * f, sin(a) * 0.2)
			bubbles[i].scale = Vector3.ONE * (1.0 - 0.5 * f)
	steam.visible = _boiling
	if _boiling:
		for i in PUFFS:
			var f := fposmod(_t * PUFF_RATE + i / float(PUFFS), 1.0)
			var at := POT_AT + Vector3(0.12 * sin(_t * 1.3 + i * 2.0), POT_H + 0.2 + f * PUFF_RISE, 0.0)
			var s := lerpf(0.14, 0.3, f) * (1.0 - f * f * f)
			steam.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * maxf(s, 0.001)), at))
	bellows_top.rotation.z = deg_to_rad(OPEN_DEG * (1.0 - handle_drop))


func _stretch_stream(from: Vector3, to: Vector3, radius: float) -> void:
	var points: Array[Vector3] = []
	for i in STREAM_LINKS + 1:
		var u := i / float(STREAM_LINKS)
		points.append(Vector3(lerpf(from.x, to.x, u), lerpf(from.y, to.y, u * u), lerpf(from.z, to.z, u)))
	for i in STREAM_LINKS:
		var link := stream.get_child(i) as Node3D
		ArtKit.stretch_link(link, points[i], points[i + 1])
		link.transform.basis.x *= radius
		link.transform.basis.z *= radius


# --- meshes ---------------------------------------------------------------------------------------

## What stands still: the well with its roof, the trough, the jar, the kettle's stand.
static func _still_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = WELL_H
	b.add_cylinder(Transform3D(Basis(), WELL_AT), WELL_R, WELL_R, WELL_H, 16, STONE, true, STONE_TOP)
	b.ao_min = 1.0
	for row in 3:
		b.add_cylinder(Transform3D(Basis(), WELL_AT + Vector3(0.0, 0.3 + row * 0.33, 0.0)), WELL_R + 0.012, WELL_R + 0.012, 0.035, 16, STONE.darkened(0.2), false)
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), WELL_AT + Vector3(side * (WELL_R - 0.1), (WELL_H + ROOF_Y) * 0.5, 0.0)), Vector3(0.12, ROOF_Y - WELL_H, 0.12), 0.02, 1, WOOD, WOOD_LIGHT)
	for side: float in [-1.0, 1.0]:
		var slope := Basis(Vector3.BACK, side * deg_to_rad(-28.0))
		b.add_rounded_box(Transform3D(slope, WELL_AT + Vector3(side * 0.6, ROOF_Y + 0.28, 0.0)), Vector3(1.45, 0.08, 1.3), 0.02, 1, ROOF, ROOF.lightened(0.15))
	# The trough: a sloping plank channel with water in it.
	var along := TROUGH_TO - TROUGH_FROM
	var basis := Basis(Vector3.BACK, atan2(along.y, along.x))
	var mid := (TROUGH_FROM + TROUGH_TO) * 0.5
	b.add_rounded_box(Transform3D(basis, mid), Vector3(along.length(), 0.08, 0.36), 0.02, 1, WOOD, WOOD_LIGHT)
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(basis, mid + Vector3(0.0, 0.0, side * 0.16) + basis.y * 0.08), Vector3(along.length(), 0.14, 0.05), 0.01, 1, WOOD.darkened(0.1), WOOD_LIGHT)
	b.add_rounded_box(Transform3D(basis, mid + basis.y * 0.05), Vector3(along.length() - 0.1, 0.02, 0.26), 0.0, 1, MUD, MUD_TOP)
	for x: float in [-3.6, -2.2]:
		var y := lerpf(TROUGH_FROM.y, TROUGH_TO.y, (x - TROUGH_FROM.x) / along.x)
		b.add_rounded_box(Transform3D(Basis(), Vector3(x, y * 0.5, TROUGH_FROM.z)), Vector3(0.1, y, 0.1), 0.02, 1, WOOD)
	# The jar and the column's wooden collar on it.
	b.ao_min = 0.85
	b.ao_height = JAR_H
	b.add_cylinder(Transform3D(Basis(), JAR_AT), JAR_R * 0.7, JAR_R, JAR_H * 0.6, 16, CLAY)
	b.add_cylinder(Transform3D(Basis(), JAR_AT + Vector3(0.0, JAR_H * 0.6, 0.0)), JAR_R, JAR_R * 0.72, JAR_H * 0.4, 16, CLAY, true, CLAY_TOP)
	b.ao_min = 1.0
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(side * (COLUMN_R + 0.02), (JAR_H + COLUMN_AT.y) * 0.5, 0.0)), Vector3(0.07, COLUMN_AT.y - JAR_H + 0.05, 0.07), 0.01, 1, WOOD)
	b.add_cylinder(Transform3D(Basis(), COLUMN_AT + Vector3(0.0, -0.04, 0.0)), COLUMN_R + 0.06, COLUMN_R + 0.06, 0.06, 16, WOOD, true, WOOD_LIGHT)
	# The kettle's stand: two legs to a cross bar under the kettle, a yoke from the bar's ends (in front of and
	# behind the kettle) up to the axle the kettle tips on.
	var bar_y := PIVOT.y - YOKE_DROP
	for side: float in [-1.0, 1.0]:
		var foot := Vector3(STAND_X + side * 0.6, 0.0, 0.0)
		var top := Vector3(STAND_X + side * 0.12, bar_y, 0.0)
		var d := top - foot
		b.add_rounded_box(Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x) - PI * 0.5), (foot + top) * 0.5), Vector3(0.1, d.length(), 0.1), 0.02, 1, WOOD, WOOD_LIGHT)
	b.add_rounded_box(Transform3D(Basis(), Vector3(STAND_X, bar_y, 0.0)), Vector3(0.36, 0.1, YOKE_Z * 2.0 + 0.12), 0.02, 1, WOOD, WOOD_LIGHT)
	for side: float in [-1.0, 1.0]:
		var from := Vector3(STAND_X, bar_y, side * YOKE_Z)
		var to := Vector3(PIVOT.x, PIVOT.y, side * YOKE_Z)
		var d := to - from
		b.add_rounded_box(Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x) - PI * 0.5), (from + to) * 0.5), Vector3(0.07, d.length() + 0.06, 0.07), 0.02, 1, WOOD.darkened(0.1), WOOD_LIGHT)
	return b.commit()


## The kettle (relative to its pivot): a copper body, a spout to the left, a handle on the right.
static func _kettle_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = KETTLE_H
	b.add_cylinder(Transform3D(Basis(), KETTLE_BODY), KETTLE_R, KETTLE_R * 0.8, KETTLE_H, 18, KETTLE, true, KETTLE_DARK)
	b.ao_min = 1.0
	var d := SPOUT_TIP - SPOUT_ROOT
	b.add_cylinder(Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x) - PI * 0.5), SPOUT_ROOT + KETTLE_BODY + Vector3(0.0, 0.3, 0.0)), 0.13, 0.07, d.length(), 10, KETTLE, true, KETTLE_DARK)
	b.add_rounded_box(Transform3D(Basis(), KETTLE_BODY + Vector3(KETTLE_R + 0.12, KETTLE_H * 0.55, 0.0)), Vector3(0.1, KETTLE_H * 0.6, 0.1), 0.03, 1, KETTLE_DARK)
	b.add_rounded_box(Transform3D(Basis(), KETTLE_BODY + Vector3(KETTLE_R * 0.6, KETTLE_H * 0.85, 0.0)), Vector3(0.36, 0.08, 0.1), 0.03, 1, KETTLE_DARK)
	b.add_cylinder(Transform3D(Basis(), KETTLE_BODY + Vector3(0.0, KETTLE_H, 0.0)), KETTLE_R * 0.8, KETTLE_R * 0.7, 0.05, 18, KETTLE_DARK, true, MUD)
	# The axle the kettle tips on, through to the yoke's arms.
	b.add_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, -YOKE_Z)), 0.06, 0.06, YOKE_Z * 2.0, 8, KETTLE_DARK)
	return b.commit()


## The column's layers (world): charcoal and sand as the filter has them, the soil caught on the sand.
static func _layers_mesh(kind: float, caught: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var r := COLUMN_R - 0.03
	var top := CHAMBER_TOP
	if kind >= CleanWaterModel.CHARCOAL:
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, CHAMBER_TOP, 0.0)), r, r, CHARCOAL_TOP - CHAMBER_TOP, 16, COAL, true, COAL_TOP)
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, CHARCOAL_TOP, 0.0)), r, r, SAND_TOP - CHARCOAL_TOP, 16, SAND, true, SAND_TOP_COLOR)
		top = SAND_TOP
	elif kind >= CleanWaterModel.SAND:
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, CHAMBER_TOP, 0.0)), r, r, SAND_ONLY_TOP - CHAMBER_TOP, 16, SAND, true, SAND_TOP_COLOR)
		top = SAND_ONLY_TOP
	# The mesh the layers lie on (the chamber's roof), a few holes drawn as dots.
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, CHAMBER_TOP - 0.03, 0.0)), r, r, 0.03, 16, WOOD_LIGHT)
	if caught > 0.0:
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, top, 0.0)), r, r, 0.02 + 0.16 * clampf(caught, 0.0, 1.0), 16, CAKE, true, CAKE.lightened(0.08))
	return b.commit()


## The water in the column: muddy water standing on the layers while it goes through (`column`), and the
## water come through in the chamber at its foot (`jar` > 0) in its colour.
static func _column_water_mesh(kind: float, column: float, jar: float, color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var r := COLUMN_R - 0.05
	var top := CHAMBER_TOP
	if kind >= CleanWaterModel.CHARCOAL:
		top = SAND_TOP
	elif kind >= CleanWaterModel.SAND:
		top = SAND_ONLY_TOP
	if column > 0.0:
		var h := clampf(column * 1.6, 0.04, COLUMN_TOP - top - 0.1)
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, top + (0.18 if kind >= CleanWaterModel.SAND else 0.0), 0.0)), r, r, h, 16, MUDDY, true, MUDDY.lightened(0.08))
	if jar > 0.0:
		var h := clampf(jar, 0.1, 1.0) * (CHAMBER_TOP - COLUMN_AT.y - 0.06)
		b.add_cylinder(Transform3D(Basis(), COLUMN_AT + Vector3(0.0, 0.02, 0.0)), r, r, h, 16, color, true, color.lightened(0.1))
	return b.commit()


## The column's see-through glass (world).
static func _column_glass_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.flat = false
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), COLUMN_AT), COLUMN_R, COLUMN_R, COLUMN_TOP - COLUMN_AT.y, 20, GlassCup.GLASS, false)
	for stripe: float in [-0.55, -0.35]:
		var a := stripe + PI * 0.5
		var w := 0.035
		var p := []
		for c: Array in [[a - w, COLUMN_AT.y + 0.1], [a + w, COLUMN_AT.y + 0.1], [a + w, COLUMN_TOP - 0.1], [a - w, COLUMN_TOP - 0.1]]:
			p.append(Vector3(cos(c[0]) * (COLUMN_R + 0.01), c[1], sin(c[0]) * (COLUMN_R + 0.01)))
		b.add_triangle([p[0], p[1], p[2]], [GlassCup.GLASS_SHINE, GlassCup.GLASS_SHINE, GlassCup.GLASS_SHINE], Vector3.BACK)
		b.add_triangle([p[0], p[2], p[3]], [GlassCup.GLASS_SHINE, GlassCup.GLASS_SHINE, GlassCup.GLASS_SHINE], Vector3.BACK)
	return b.commit()


## The touch stand-in's slot (world): a pale upright groove with a pink edge, beside the kettle.
static func _slot_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var mid := Vector3(SLOT_X, (SLOT_TOP + SLOT_BOTTOM) * 0.5, SLOT_Z - 0.06)
	var tall := SLOT_TOP - SLOT_BOTTOM + BALL_R * 2.6
	b.add_rounded_box(Transform3D(Basis(), mid), Vector3(BALL_R * 2.9, tall + 0.08, 0.05), 0.12, 2, SLOT_EDGE)
	b.add_rounded_box(Transform3D(Basis(), mid + Vector3(0.0, 0.0, 0.02)), Vector3(BALL_R * 2.5, tall, 0.05), 0.1, 2, SLOT)
	return b.commit()


## The fire's stone ring and logs, the pot's stand.
static func _hearth_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.3
	for i in 9:
		var a := TAU * i / 9.0
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.22, 0.16, 0.2)), HEARTH_AT + Vector3(cos(a) * HEARTH_R, 0.1, sin(a) * HEARTH_R * 0.7)), 1.0, 3, 7, STONE)
	b.ao_min = 1.0
	for i in 3:
		var yaw := Basis(Vector3.UP, PI * i / 3.0)
		b.add_cylinder(Transform3D(yaw * Basis(Vector3.BACK, PI * 0.5), HEARTH_AT + Vector3(0.0, 0.12, 0.0)), 0.08, 0.08, 1.0, 8, WOOD.darkened(0.2), true, WOOD_LIGHT)
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), POT_AT + Vector3(side * (POT_R + 0.08), -POT_AT.y * 0.5, 0.0)), Vector3(0.08, POT_AT.y, 0.08), 0.02, 1, POT_RIM)
	return b.commit()


## The pot on the fire.
static func _pot_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = POT_H
	b.add_cylinder(Transform3D(Basis(), POT_AT), POT_R * 0.9, POT_R, POT_H, 18, POT_METAL, true, POT_RIM)
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), POT_AT + Vector3(0.0, POT_H - 0.03, 0.0)), POT_R + 0.02, POT_R + 0.02, 0.05, 18, POT_RIM, false)
	return b.commit()


## The bellows' bottom board and its nozzle towards the fire, the leather fold (world).
static func _bellows_base_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), BELLOWS_AT), Vector3(1.0, 0.07, 0.55), 0.02, 1, BELLOWS_WOOD, BELLOWS_WOOD.lightened(0.1))
	b.add_cylinder(Transform3D(Basis(Vector3.BACK, PI * 0.5), BELLOWS_AT + Vector3(-0.5, 0.0, 0.0)), 0.08, 0.04, 0.5, 8, POT_RIM)
	b.add_rounded_box(Transform3D(Basis(), BELLOWS_AT + Vector3(0.0, -BELLOWS_AT.y * 0.5, 0.0)), Vector3(0.12, BELLOWS_AT.y, 0.12), 0.02, 1, BELLOWS_WOOD)
	b.add_rounded_box(Transform3D(Basis(), BELLOWS_AT + Vector3(0.1, 0.12, 0.0)), Vector3(0.8, 0.16, 0.5), 0.05, 1, BELLOWS_LEATHER)
	return b.commit()


## The bellows' top board, hinged at its nozzle end (the node's origin), a short post at its far end with
## the handle's yellow ball on it (HANDLE_REL).
static func _bellows_top_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_rounded_box(Transform3D(Basis(), Vector3(HANDLE_REL.x * 0.5, 0.04, 0.0)), Vector3(HANDLE_REL.x, 0.07, 0.55), 0.02, 1, BELLOWS_WOOD, BELLOWS_WOOD.lightened(0.12))
	b.add_rounded_box(Transform3D(Basis(), Vector3(HANDLE_REL.x, HANDLE_REL.y * 0.5 + 0.04, 0.0)), Vector3(0.09, HANDLE_REL.y, 0.09), 0.03, 1, BELLOWS_WOOD.darkened(0.15))
	b.add_sphere(Transform3D(Basis(), HANDLE_REL), 0.15, 3, 8, BALL)
	return b.commit()


## The germs in the window at strength `germs` (1 all there .. 0 gone): faceless green rods and lilac
## balls, fading into the glass as they die.
static func _germs_mesh(germs: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	if germs <= 0.0:
		ArtKit.flat_disc(b, Vector3(0.0, 0.0, 0.0), 0.01, LENS_GLASS, 6)
		return b.commit()
	var rod := LENS_GLASS.lerp(GERM_ROD, germs)
	var dot := LENS_GLASS.lerp(GERM_BALL, germs)
	var spots := [[Vector2(-0.25, 0.18), 0.5], [Vector2(0.18, 0.26), -0.4], [Vector2(0.05, -0.2), 1.2], [Vector2(-0.22, -0.18), -1.0]]
	for s: Array in spots:
		var c: Vector2 = s[0]
		var basis := Basis(Vector3.BACK, float(s[1])) * Basis.from_scale(Vector3(0.16, 0.055, 0.02))
		b.add_sphere(Transform3D(basis, Vector3(c.x, c.y, 0.0)), 1.0, 3, 8, rod)
	for c: Vector2 in [Vector2(0.3, -0.05), Vector2(-0.05, 0.05), Vector2(0.24, -0.3), Vector2(-0.35, 0.0), Vector2(0.0, 0.36)]:
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.07, 0.07, 0.02)), Vector3(c.x, c.y, 0.0)), 1.0, 3, 8, dot)
	return b.commit()


static func _disc_mesh(radius: float, color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	ArtKit.flat_disc(b, Vector3.ZERO, radius, color, 20)
	return b.commit()


static func _ball_mesh(radius: float, color: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	b.add_sphere(Transform3D(), radius, 4, 10, color)
	return b.commit()
