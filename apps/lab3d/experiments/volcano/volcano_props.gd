## The 화산 lab's props (#98; apps/lab3d/docs/art-direction.md): meshes only, posed from the model by
## VolcanoLab._redraw(). On the valley's grass at the back of Hutton Island:
## - the island's volcano at the back on the right, big, a little smoke over its crater and a golden
##   glint in it (the sundial's needle, VolcanoGame); the sea along its right foot, the fox's village
##   (three little houses) at its left foot;
## - the small volcano model in front on the left: a round wooden table with a sand tray, the vent in
##   its middle, the lava's cone growing round the vent (a hot glowing skin while it flows, then cooled
##   dark rock); the stage goals on the sand: a ring of little flags where a wide mountain reaches
##   (stage 1) and a pole with a dashed line at the tall mountain's height (stage 2);
## - the magma pump in front on the right, the thing the child presses: a squat iron tank with a
##   window on its magma (runny bright yellow, normal orange, sticky dark red: the condition button's
##   magma) and a big red button on top in a ring of light; its pipes run to the table and down into
##   the ground towards the volcano; the hold gauge (ForceGauge) beside it fills while it pumps;
## - on the big volcano (stage 3): normal lava runs down its right flank as a glowing stream, reaches
##   the sea, steams and cools into new land; runny lava spreads into a thin sheet that stops halfway;
##   sticky magma plugs the crater: a dome of cooled lava with glowing cracks rises out of it,
##   swelling while the pump pushes and bubbling on top;
## - the night (stage 3, VolcanoLab: the lab's own clear colour and the shaders' story tint) with
##   stars over the sea; the lava, the crater, the windows, the steam and the stars glow (unshaded,
##   StarArt.glow_material: no night tint);
## - the bread cat in front, watching the pump.
## Visual only: no body, nothing the model or the mission reads.
class_name VolcanoProps
extends RefCounted

## The island's corner round the lab (its trees stand clear of the table, the pump and the sea).
const WORLD_CENTER := Vector3(-2.0, 0.0, -5.0)
## The small model: a round table, its sand tray (the vent in its middle) and its legs.
const TABLE_AT := Vector3(-3.2, 0.0, -0.6)
const TABLE_RADIUS := 3.55
const TABLE_TOP := 0.8
const TRAY_RADIUS := 3.35
const SAND_TOP := TABLE_TOP + 0.06
const VENT := Vector3(TABLE_AT.x, SAND_TOP, TABLE_AT.z)
const VENT_RADIUS := 0.24
const TABLE_WOOD := Color("c98d4f")
const TABLE_TOP_WOOD := Color("dba468")
const SAND := Color("f1dca6")
const SAND_TOP_COLOR := Color("f7e6b8")
## The goals on the sand: GOAL_FLAGS flags round the vent at the wide reach; the pole at the tall
## height, POLE_AWAY m right of the vent, and its dashed line across the vent.
const GOAL_FLAGS := 14
const POLE_AWAY := 1.9
const GOAL_COLOR := Color("ffd23a")
const GOAL_LINE := Color("fff6d0")
## The lava: hot (yellow at the vent, orange, red at the edges) and cooled (dark rock with embers).
const LAVA_CORE := Color("fff07a")
const LAVA_HOT := Color("ffb31a")
const LAVA_EDGE := Color("ff5a1f")
const ROCK_DARK := Color("4a3a37")
const ROCK_LIGHT := Color("66524b")
const EMBER := Color("c8501a")
## The cooled skin fades over COOL_S after the lava stopped.
const COOL_S := 1.6
## The pump: where it stands, its tank, the button.
const PUMP_AT := Vector3(2.4, 0.0, 1.9)
const TANK_RADIUS := 0.55
const TANK_HEIGHT := 1.05
const TANK_BOTTOM := 0.32
const BUTTON_RADIUS := 0.5
const BUTTON_PRESS := 0.12
const PUMP_IRON := Color("5a6273")
const PUMP_IRON_TOP := Color("737d90")
## The magma in the tank window, by stickiness (runny, normal, sticky).
const MAGMA := [Color("ffe14a"), Color("ff8a1f"), Color("c8321f")]
const MAGMA_TOP := [Color("fff3a0"), Color("ffb54a"), Color("e8573a")]
## The pump's hit box (m) round its button and the top of its tank (centred on the button): what a
## finger presses.
const PUMP_BOX := Vector3(1.7, 1.6, 1.6)
## The island's volcano: its foot's centre, radius, height, the crater's rim radius and depth (2026-11-07
## user: it was too small and far on the phone; nearer and bigger, still clear of the top band).
const VOLCANO_AT := Vector3(11.8, 0.0, -8.5)
const VOLCANO_RADIUS := 6.4
const VOLCANO_HEIGHT := 5.6
const RIM_RADIUS := 1.45
const CRATER_DEPTH := 0.8
## The way the lava runs to the sea (deg round the volcano from +x, counter-clockwise seen from above:
## -90 is straight towards the camera) down the volcano's front face, where the sea comes to its foot;
## a little to the left, so the new land stays clear of Dugi at the right foot of the screen.
const FLOW_DEG := -100.0
const STREAM_WIDTH := Vector2(0.9, 1.35)   # at the rim, at the shore
const SHEET_SPREAD_DEG := 50.0
## The lava lies this far over the slope (its facets and lumps stay under it).
const LAVA_LIFT := 0.22
## The sea in front of the volcano's right side (a wavy round bay, its middle and radii; the volcano
## stands over its back edge) and the new land that grows LAND_LENGTH m into it along the flow.
const SEA_Y := 0.05
const SEA_AT := Vector3(15.5, 0.0, -3.0)
const SEA_RADII := Vector2(9.0, 7.2)
const LAND_LENGTH := 3.0
## The sticky plug (2026-11-07 user: the plugged crater showed almost no change): a dome of cooled
## lava rising out of the crater, dark rock with a little glow at its top, swelling while the pump
## pushes and bubbling on top. Its base sits PLUG_SUNK m down the crater; it grows from PLUG_LOW to
## PLUG_HIGH m high with the lava, PLUG_WIDE x the rim wide; it swells by PLUG_SWELL (pumping) or
## PLUG_REST (after) at PLUG_HZ; PLUG_BUBBLES glowing bubbles swell and pop on its top over BUBBLE_S.
const PLUG_SUNK := 0.5
const PLUG_LOW := 0.9
const PLUG_HIGH := 2.3
const PLUG_WIDE := 0.9
const PLUG_SWELL := 0.09
const PLUG_REST := 0.035
const PLUG_HZ := 1.3
const PLUG_BUBBLES := 4
const BUBBLE_S := 1.1
const CRUST := Color("5a2a22")
const CRUST_LIGHT := Color("7c3a2a")
const LAND_WIDTH := 3.0
## The fox's village at the volcano's left foot: [x, z, turn deg].
const HOUSES := [[3.4, -8.4, 15.0], [3.2, -12.4, -10.0], [1.6, -10.4, 30.0]]
const HOUSE_SIZE := 1.6
const CAT_AT := Vector3(5.2, 0.0, 2.6)
## The night sky's stars (count, distance) and the night's colours.
const STARS := 70
const STAR_FAR := 140.0
const NIGHT_SKY := Color("15204a")
## The smoke and steam puffs (the crater's, the shore's, the vent's) and their life (s).
const PUFFS := 9
const PUFF_S := 2.6
const BURST_S := 4.0
const STEAM := Color("f2f5fa")
const SMOKE := Color("b7bcc8")

var cat: CatActor
var pump: Node3D
var button: Node3D
var gauge: ForceGauge
var tank_magma: MeshInstance3D
var table: Node3D
var mound: Node3D            # the cooled cone (scaled: reach, height, reach)
var skin: MeshInstance3D     # its hot glowing skin
var wide_goal: Node3D
var tall_goal: Node3D
var volcano: Node3D
var crater_glow: MeshInstance3D
var plug: Node3D
var plug_dome: MeshInstance3D
var stream: MeshInstance3D
var sheet: MeshInstance3D
var land: Node3D
var village_lights: Node3D
var stars: Node3D
var glow_material: StandardMaterial3D
var skin_material: StandardMaterial3D
## What the props show now (tests): the cone (m), the stream's front (0..1+), the land's share, the
## night (0 day .. 1 night), the gauge's fill.
var shown_reach := 0.0
var shown_height := 0.0
var shown_front := 0.0
var shown_land := 0.0
var night := 0.0
## The big scene's own land (VolcanoGame: it grows to all of it) and steam burst (1 .. 0 over BURST_S).
var land_boost := 0.0
var burst := 0.0
var _night_goal := 0.0
var _hot := 0.0               # the skin's glow (1 flowing .. 0 cooled)
var _flowing := false
var _stream_key := Vector3.INF
var _magma_meshes: Array[Mesh] = []
var _bubbles: Array[MeshInstance3D] = []
var _plug_k := 0.0            # the plug's growth (0 just plugged .. 1 a full pump)
var _puffs: Array = []        # [node, source id, phase]
var _sources := {}            # source id -> {"at": Vector3, "rate": puffs per s share 0..1, "size": m}
var _t := 0.0


## The flow's direction on the ground (unit, x/z) from the volcano's middle.
static func flow_dir() -> Vector3:
	var a := deg_to_rad(FLOW_DEG)
	return Vector3(cos(a), 0.0, -sin(a))


## The volcano's slope height at `r` m from its middle (the rim at RIM_RADIUS, the foot at the radius):
## a cone that steepens towards the top.
static func slope_y(r: float) -> float:
	var k := clampf((VOLCANO_RADIUS - r) / (VOLCANO_RADIUS - RIM_RADIUS), 0.0, 1.0)
	return VOLCANO_HEIGHT * pow(k, 1.35)


## The point `s` (0 the rim .. 1 the foot) down the lava's way, `side` m across it, on the slope.
static func flow_point(s: float, side := 0.0) -> Vector3:
	var d := flow_dir()
	var across := Vector3(-d.z, 0.0, d.x)
	var r := lerpf(RIM_RADIUS, VOLCANO_RADIUS, s)
	var wiggle := 0.35 * sin(s * 5.0)
	var p := VOLCANO_AT + d * r + across * (side + wiggle)
	return Vector3(p.x, slope_y(r) + LAVA_LIFT, p.z)


## The shore where the lava meets the sea (the foot of its way).
static func shore() -> Vector3:
	var p := flow_point(1.0)
	return Vector3(p.x, SEA_Y, p.z)


## The crater's top middle (where the needle comes up).
static func crater_top() -> Vector3:
	return VOLCANO_AT + Vector3(0.0, VOLCANO_HEIGHT, 0.0)


func build(lab: Node3D) -> void:
	ArtKit.add_world(lab, WORLD_CENTER, null, 0.0)
	glow_material = StarArt.glow_material()
	skin_material = StandardMaterial3D.new()
	skin_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skin_material.vertex_color_use_as_albedo = true
	skin_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_build_volcano(lab)
	_build_sea(lab)
	_build_village(lab)
	_build_table(lab)
	_build_pump(lab)
	stars = ArtKit.instance(_stars_mesh(), glow_material)
	stars.name = "Stars"
	stars.visible = false
	lab.add_child(stars)
	_build_puffs(lab)
	cat = CatActor.new(BreadCat.new())
	cat.name = "Cat"
	lab.add_child(cat)
	cat.look_target = pump
	cat.stand(CAT_AT)
	cat.advance(0.0)


## Poses everything from the model: the site (small model or big volcano), the magma, the cone, the
## stream or sheet or plug, the land, the pump's button and gauge. `flowing`: the lava is coming out
## (pumping or still gliding).
func show(model: VolcanoModel, pressed: bool, pumped: float, flowing: bool) -> void:
	var kind := roundi(model.stickiness())
	_flowing = flowing
	if flowing:
		_hot = 1.0
	tank_magma.mesh = _magma_meshes[clampi(kind, 0, 2)]
	tank_magma.scale = Vector3(1.0, maxf(0.02, 1.0 - pumped * 0.85), 1.0)
	button.position.y = (-BUTTON_PRESS if pressed else 0.0)
	gauge.visible = pumped > 0.0
	gauge.set_fraction(pumped)
	var big := model.big()
	# The small model's cone (the big volcano's lava never shows on the table).
	shown_reach = 0.0 if big else model.reach()
	shown_height = 0.0 if big else model.height()
	mound.visible = shown_reach > 0.01
	mound.scale = Vector3(maxf(shown_reach, 0.01), maxf(shown_height, 0.01), maxf(shown_reach, 0.01))
	skin.visible = mound.visible and _hot > 0.0
	# The big volcano: the stream (normal), the sheet (runny), the plug (sticky), the land.
	shown_front = model.front() if big and model.input("lava") > 0.0 else 0.0
	var key := Vector3(snappedf(shown_front, 0.005), float(kind), 1.0 if big else 0.0)
	if key != _stream_key:
		_stream_key = key
		stream.mesh = _stream_mesh(minf(shown_front, 1.0)) if big and kind == 1 and shown_front > 0.0 else null
		sheet.mesh = _sheet_mesh(shown_front) if big and kind == 0 and shown_front > 0.0 else null
	var plugged := big and kind == 2 and model.input("lava") > 0.0
	plug.visible = plugged
	_plug_k = clampf(model.input("lava") * 1.5, 0.0, 1.0) if plugged else 0.0
	_pose_plug()
	set_land(maxf(land_boost, 0.35 + 0.65 * model.new_land() if big and model.status() == "sea" else 0.0))
	var smoke_y := lerpf(PLUG_LOW, PLUG_HIGH, _plug_k) - PLUG_SUNK + 0.1 if plugged else 0.2
	_set_source("crater", crater_top() + Vector3(0.0, smoke_y, 0.0), 1.0 if plugged else 0.35, 1.3 if plugged else 0.9)
	_set_source("shore", shore() + flow_dir() * 0.6, 1.0 if shown_front >= 1.0 else 0.0, 1.0)
	_set_source("vent", VENT + Vector3(0.0, shown_height + 0.1, 0.0), 0.6 if flowing and not big else 0.0, 0.35)


## The new land's share (0 none .. 1 all of it): it grows from the shore along the flow.
func set_land(share: float) -> void:
	shown_land = clampf(share, 0.0, 1.0)
	land.visible = shown_land > 0.001
	land.scale = Vector3(maxf(shown_land, 0.001), 0.6 + 0.4 * shown_land, 0.5 + 0.5 * shown_land)


## The steam bursts up from the shore (the big scene): bigger and thicker, dying down over BURST_S.
func steam_burst() -> void:
	burst = 1.0


## Turns the night on (1) or off (0): it eases in advance().
func set_night(on: bool, at_once := false) -> void:
	_night_goal = 1.0 if on else 0.0
	if at_once:
		night = _night_goal
	stars.visible = night > 0.01
	village_lights.visible = night > 0.3


## Which site shows its goals: the wide flags (stage 1), the tall pole (stage 2), neither.
func show_goals(wide: bool, tall: bool) -> void:
	wide_goal.visible = wide
	tall_goal.visible = tall


## The clock of the props: the night's ease, the cooling skin, the puffs, the glows' flicker.
func advance(delta: float) -> void:
	_t += delta
	burst = maxf(0.0, burst - delta / BURST_S)
	night = move_toward(night, _night_goal, delta / 1.6)
	stars.visible = night > 0.01
	village_lights.visible = night > 0.3
	if not _flowing:
		_hot = maxf(0.0, _hot - delta / COOL_S)
	skin.visible = mound.visible and _hot > 0.0
	skin_material.albedo_color = Color(1.0, 1.0, 1.0, clampf(_hot * 1.4, 0.0, 1.0))
	var flicker := 0.88 + 0.12 * sin(_t * 7.0) * sin(_t * 3.1)
	crater_glow.scale = Vector3(1.0, 1.0, 1.0) * (0.96 + 0.04 * flicker)
	if plug.visible:
		_pose_plug()
	_advance_puffs()


# --- the table and the pump --------------------------------------------------------------------------

func _build_table(lab: Node3D) -> void:
	table = Node3D.new()
	table.name = "ModelTable"
	lab.add_child(table)
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.4
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		b.add_cylinder(Transform3D(Basis(), TABLE_AT + Vector3(cos(a), 0.0, sin(a)) * (TABLE_RADIUS - 0.6)), 0.14, 0.11, TABLE_TOP - 0.15, 8, ArtPalette.WOOD_GRAIN)
	b.add_cylinder(Transform3D(Basis(), TABLE_AT + Vector3(0.0, TABLE_TOP - 0.18, 0.0)), TABLE_RADIUS - 0.05, TABLE_RADIUS, 0.18, 40, TABLE_WOOD, true, TABLE_TOP_WOOD)
	b.ao_min = 1.0
	b.add_cylinder(Transform3D(Basis(), TABLE_AT + Vector3(0.0, TABLE_TOP, 0.0)), TRAY_RADIUS, TRAY_RADIUS, SAND_TOP - TABLE_TOP, 40, SAND, true, SAND_TOP_COLOR)
	# The vent: a dark hole in a little rim of rock.
	b.add_cylinder(Transform3D(Basis(), VENT + Vector3(0.0, -0.02, 0.0)), VENT_RADIUS + 0.14, VENT_RADIUS + 0.06, 0.08, 14, ROCK_LIGHT)
	ArtKit.flat_disc(b, VENT + Vector3(0.0, 0.065, 0.0), VENT_RADIUS, ArtPalette.CRATER, 14)
	var top := ArtKit.instance(b.commit())
	top.name = "Table"
	table.add_child(top)
	# The lava's cone: the cooled rock and the hot skin over it (a unit mound scaled to the cone).
	mound = Node3D.new()
	mound.name = "Lava"
	mound.position = VENT + Vector3(0.0, 0.004, 0.0)
	mound.visible = false
	table.add_child(mound)
	mound.add_child(ArtKit.instance(_mound_mesh(false)))
	skin = ArtKit.instance(_mound_mesh(true), skin_material)
	skin.name = "HotSkin"
	skin.scale = Vector3(1.0, 1.02, 1.0)
	mound.add_child(skin)
	wide_goal = ArtKit.instance(_wide_goal_mesh())
	wide_goal.name = "WideGoal"
	wide_goal.visible = false
	table.add_child(wide_goal)
	tall_goal = ArtKit.instance(_tall_goal_mesh())
	tall_goal.name = "TallGoal"
	tall_goal.visible = false
	table.add_child(tall_goal)


## A mound of radius 1 and height 1 (lava's cone, a little rounded, a small crater dip on top):
## `hot`: the glowing skin (yellow at the top to red at the foot), else cooled dark rock with embers.
func _mound_mesh(hot: bool) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var rings := [0.0, 0.08, 0.16, 0.3, 0.45, 0.6, 0.75, 0.88, 1.0]
	var sides := 28
	var at := func(d: float, i: int) -> Vector3:
		var a := TAU * i / sides
		var lump := 1.0 + 0.04 * sin(i * 2.7 + d * 9.0) if d > 0.05 and d < 0.99 else 1.0
		var y := pow(1.0 - d, 1.15) if d >= 0.08 else 0.93 + d * 0.4   # the dip of the little crater
		return Vector3(cos(a) * d * lump, maxf(y, 0.0), sin(a) * d * lump)
	var colour := func(d: float, i: int) -> Color:
		if hot:
			return LAVA_CORE.lerp(LAVA_HOT, clampf(d * 1.6, 0.0, 1.0)).lerp(LAVA_EDGE, clampf((d - 0.6) * 2.5, 0.0, 1.0))
		var c := ROCK_DARK.lerp(ROCK_LIGHT, 0.5 + 0.5 * sin(i * 1.9 + d * 7.0))
		return EMBER if (i * 7 + int(d * 10.0)) % 11 == 0 and d > 0.1 else c
	for r in rings.size() - 1:
		for i in sides:
			var p0: Vector3 = at.call(rings[r], i)
			var p1: Vector3 = at.call(rings[r], i + 1)
			var p2: Vector3 = at.call(rings[r + 1], i + 1)
			var p3: Vector3 = at.call(rings[r + 1], i)
			var c0: Color = colour.call(rings[r], i)
			var c1: Color = colour.call(rings[r + 1], i)
			b.add_triangle([p0, p2, p3], [c0, c1, c1], Vector3.UP)
			b.add_triangle([p0, p1, p2], [c0, c0, c1], Vector3.UP)
	return b.commit()


## The wide goal: GOAL_FLAGS little flags on pegs round the vent at the wide reach, a dashed ring
## between them.
func _wide_goal_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var r := VolcanoModel.REACH_WIDE
	for i in GOAL_FLAGS:
		var a := TAU * (i + 0.5) / GOAL_FLAGS
		var foot := VENT + Vector3(cos(a) * r, 0.0, sin(a) * r)
		b.add_cylinder(Transform3D(Basis(), foot), 0.045, 0.035, 0.42, 6, ArtPalette.WOOD_GRAIN)
		var flag := foot + Vector3(0.0, 0.42, 0.0)
		var out := Vector3(-sin(a), 0.0, cos(a)) * 0.24
		b.add_triangle([flag, flag + Vector3(0.0, -0.17, 0.0), flag + out + Vector3(0.0, -0.085, 0.0)], [GOAL_COLOR, GOAL_COLOR, GOAL_COLOR.lightened(0.3)], Vector3.BACK)
		b.add_triangle([flag, flag + out + Vector3(0.0, -0.085, 0.0), flag + Vector3(0.0, -0.17, 0.0)], [GOAL_COLOR, GOAL_COLOR.lightened(0.3), GOAL_COLOR], Vector3.FORWARD)
	for k in 48:
		if k % 2 == 1:
			continue
		var a0 := TAU * k / 48.0
		var a1 := TAU * (k + 1) / 48.0
		var p0 := VENT + Vector3(cos(a0), 0.0, sin(a0)) * r + Vector3(0.0, 0.012, 0.0)
		var p1 := VENT + Vector3(cos(a1), 0.0, sin(a1)) * r + Vector3(0.0, 0.012, 0.0)
		var out0 := Vector3(cos(a0), 0.0, sin(a0)) * 0.05
		var out1 := Vector3(cos(a1), 0.0, sin(a1)) * 0.05
		b.add_triangle([p0 - out0, p1 - out1, p1 + out1], [GOAL_LINE, GOAL_LINE, GOAL_LINE], Vector3.UP)
		b.add_triangle([p0 - out0, p1 + out1, p0 + out0], [GOAL_LINE, GOAL_LINE, GOAL_LINE], Vector3.UP)
	return b.commit()


## The tall goal: a striped pole right of the vent, a big flag at the tall height and a dashed line at
## that height across the vent (the cone's top must reach it).
func _tall_goal_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var h := VolcanoModel.TALL_MIN
	var foot := VENT + Vector3(POLE_AWAY, 0.0, -0.2)
	var bands := 6
	var top := h + 0.45
	for k in bands:
		b.add_cylinder(Transform3D(Basis(), foot + Vector3(0.0, top * k / bands, 0.0)), 0.07, 0.07, top / bands, 8, ArtPalette.RED if k % 2 == 0 else ArtPalette.WHITE, false)
	b.add_sphere(Transform3D(Basis(), foot + Vector3(0.0, top, 0.0)), 0.1, 3, 8, GOAL_COLOR)
	var flag := foot + Vector3(0.0, h + 0.2, 0.0)
	b.add_triangle([flag, flag + Vector3(0.0, -0.4, 0.0), flag + Vector3(0.55, -0.2, 0.0)], [GOAL_COLOR, GOAL_COLOR, GOAL_COLOR.lightened(0.3)], Vector3.BACK)
	b.add_triangle([flag, flag + Vector3(0.55, -0.2, 0.0), flag + Vector3(0.0, -0.4, 0.0)], [GOAL_COLOR, GOAL_COLOR.lightened(0.3), GOAL_COLOR], Vector3.FORWARD)
	# The dashed line at the tall height, from the pole across the vent.
	var y := VENT.y + h
	var x0 := foot.x - 0.1
	var x1 := VENT.x - 1.3
	var dashes := 12
	for k in dashes:
		var a := lerpf(x0, x1, (k + 0.15) / dashes)
		var c := lerpf(x0, x1, (k + 0.65) / dashes)
		b.add_rounded_box(Transform3D(Basis(), Vector3((a + c) * 0.5, y, VENT.z)), Vector3(absf(c - a), 0.05, 0.05), 0.0, 1, GOAL_LINE)
	return b.commit()


func _build_pump(lab: Node3D) -> void:
	pump = Node3D.new()
	pump.name = "Pump"
	pump.position = PUMP_AT
	lab.add_child(pump)
	var b := ArtKit.builder()
	b.ao_min = 0.8
	b.ao_height = 0.5
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.14, 0.0)), Vector3(1.5, 0.28, 1.3), 0.06, 1, PUMP_IRON, PUMP_IRON_TOP)
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, TANK_BOTTOM - 0.04, 0.0)), TANK_RADIUS, TANK_RADIUS, TANK_HEIGHT + 0.08, 16, PUMP_IRON, true, PUMP_IRON_TOP)
	b.ao_min = 1.0
	# Rivet bands and the window's frame (the magma shows through it).
	for y: float in [TANK_BOTTOM + 0.02, TANK_BOTTOM + TANK_HEIGHT]:
		b.add_cylinder(Transform3D(Basis(), Vector3(0.0, y, 0.0)), TANK_RADIUS + 0.04, TANK_RADIUS + 0.04, 0.06, 16, PUMP_IRON_TOP)
	b.add_rounded_box(Transform3D(Basis(), Vector3(0.0, TANK_BOTTOM + TANK_HEIGHT * 0.5, TANK_RADIUS - 0.02)), Vector3(0.62, TANK_HEIGHT * 0.86, 0.1), 0.04, 1, ArtPalette.INK)
	# The button's collar on the tank's top.
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, TANK_BOTTOM + TANK_HEIGHT + 0.04, 0.0)), 0.42, 0.36, 0.14, 14, ArtPalette.STEEL, true, ArtPalette.STEEL_SHINE)
	# The pipes: along the ground to the table's foot, and down into the ground towards the volcano.
	var to_table := Vector3(TABLE_AT.x + TABLE_RADIUS * 0.55, 0.0, TABLE_AT.z + 1.2) - PUMP_AT
	_pipe(b, Vector3(-0.7, 0.16, 0.0), Vector3(to_table.x, 0.16, to_table.z))
	_pipe(b, Vector3(0.0, 0.16, -0.62), Vector3(0.0, 0.16, -1.6))
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, -0.05, -1.6)), 0.3, 0.26, 0.12, 10, PUMP_IRON, true, PUMP_IRON_TOP)
	var body := ArtKit.instance(b.commit())
	body.name = "Body"
	pump.add_child(body)
	for kind in 3:
		var m := ArtKit.builder()
		m.ao_min = 1.0
		m.add_rounded_box(Transform3D(Basis(), Vector3(0.0, 0.5, 0.0)), Vector3(0.5, 1.0, 0.04), 0.0, 1, MAGMA[kind], MAGMA_TOP[kind])
		for k in 3:   # bubbles
			m.add_sphere(Transform3D(Basis(), Vector3(-0.12 + 0.13 * k, 0.25 + 0.22 * k, 0.03)), 0.045 + 0.02 * (k % 2), 2, 6, MAGMA_TOP[kind])
		_magma_meshes.append(m.commit())
	tank_magma = ArtKit.instance(_magma_meshes[0], glow_material)
	tank_magma.name = "TankMagma"
	tank_magma.position = Vector3(0.0, TANK_BOTTOM + TANK_HEIGHT * 0.07, TANK_RADIUS + 0.035)
	tank_magma.scale = Vector3(1.0, 1.0, 1.0)
	pump.add_child(tank_magma)
	var ring := ArtKit.builder()
	ring.ao_min = 1.0
	var ring_y := TANK_BOTTOM + TANK_HEIGHT + 0.19
	for k in 24:
		var a0 := TAU * k / 24.0
		var a1 := TAU * (k + 1) / 24.0
		var r0 := BUTTON_RADIUS + 0.04
		var r1 := BUTTON_RADIUS + 0.16
		var c := GOAL_COLOR
		ring.add_triangle([Vector3(cos(a0) * r0, ring_y, sin(a0) * r0), Vector3(cos(a1) * r0, ring_y, sin(a1) * r0), Vector3(cos(a1) * r1, ring_y, sin(a1) * r1)], [c, c, c], Vector3.UP)
		ring.add_triangle([Vector3(cos(a0) * r0, ring_y, sin(a0) * r0), Vector3(cos(a1) * r1, ring_y, sin(a1) * r1), Vector3(cos(a0) * r1, ring_y, sin(a0) * r1)], [c, c, c], Vector3.UP)
	var lit := ArtKit.instance(ring.commit(), glow_material)
	lit.name = "ButtonLight"
	pump.add_child(lit)
	button = Node3D.new()
	button.name = "PumpButton"
	pump.add_child(button)
	var btn := ArtKit.builder()
	btn.ao_min = 0.9
	btn.ao_height = 0.3
	var base_y := TANK_BOTTOM + TANK_HEIGHT + 0.16
	btn.add_cylinder(Transform3D(Basis(), Vector3(0.0, base_y, 0.0)), 0.2, 0.2, 0.16, 10, ArtPalette.STEEL)
	btn.add_cylinder(Transform3D(Basis(), Vector3(0.0, base_y + 0.14, 0.0)), BUTTON_RADIUS, BUTTON_RADIUS * 0.92, 0.16, 20, ArtPalette.RED, true, ArtPalette.RED_TOP)
	btn.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.32, 1.0)), Vector3(0.0, base_y + 0.3, 0.0)), BUTTON_RADIUS * 0.92, 4, 20, ArtPalette.RED_TOP)
	btn.add_sphere(Transform3D(Basis.from_scale(Vector3(1.0, 0.4, 1.0)), Vector3(-0.17, base_y + 0.38, 0.12)), 0.12, 2, 8, Color("ffb3a8"))
	button.add_child(ArtKit.instance(btn.commit()))
	gauge = ForceGauge.new()
	gauge.position = Vector3(1.05, 0.05, 0.25)
	pump.add_child(gauge)


## The top of the pump's button (world): where a finger presses it.
func button_top() -> Vector3:
	return PUMP_AT + Vector3(0.0, TANK_BOTTOM + TANK_HEIGHT + 0.5, 0.0)


## A pipe (local to the pump) from `a` to `b`, with a flange at each end.
static func _pipe(b: ArtMeshBuilder, from: Vector3, to: Vector3) -> void:
	var along := to - from
	var basis := Basis(Quaternion(Vector3.UP, along.normalized()))
	b.add_cylinder(Transform3D(basis, from), 0.12, 0.12, along.length(), 10, ArtPalette.STEEL, false)
	for end: Vector3 in [from, to]:
		b.add_cylinder(Transform3D(basis, end - along.normalized() * 0.05), 0.17, 0.17, 0.1, 10, ArtPalette.STEEL_SHINE)


# --- the island's volcano, the sea, the village -------------------------------------------------------

func _build_volcano(lab: Node3D) -> void:
	volcano = Node3D.new()
	volcano.name = "Volcano"
	lab.add_child(volcano)
	volcano.add_child(ArtKit.instance(_volcano_mesh()))
	var glow := ArtKit.builder()
	glow.ao_min = 1.0
	ArtKit.flat_disc(glow, Vector3.ZERO, RIM_RADIUS * 0.82, LAVA_HOT, 20)
	ArtKit.flat_disc(glow, Vector3(0.0, 0.01, 0.0), RIM_RADIUS * 0.45, LAVA_CORE, 16)
	crater_glow = ArtKit.instance(glow.commit(), glow_material)
	crater_glow.name = "CraterGlow"
	crater_glow.position = crater_top() + Vector3(0.0, -CRATER_DEPTH + 0.12, 0.0)
	volcano.add_child(crater_glow)
	plug = Node3D.new()
	plug.name = "Plug"
	plug.position = crater_top() + Vector3(0.0, -PLUG_SUNK, 0.0)
	plug.visible = false
	volcano.add_child(plug)
	plug_dome = ArtKit.instance(_dome_mesh(), glow_material)
	plug_dome.name = "Dome"
	plug.add_child(plug_dome)
	var blob := ArtKit.builder()
	blob.ao_min = 1.0
	blob.add_sphere(Transform3D(), 1.0, 3, 10, LAVA_HOT)
	blob.add_sphere(Transform3D(Basis(), Vector3(-0.25, 0.35, 0.45)), 0.4, 2, 8, LAVA_CORE)
	var blob_mesh := blob.commit()
	for k in PLUG_BUBBLES:
		var bubble := ArtKit.instance(blob_mesh, glow_material)
		bubble.name = "Bubble%d" % k
		plug.add_child(bubble)
		_bubbles.append(bubble)
	stream = MeshInstance3D.new()
	stream.name = "Stream"
	stream.material_override = glow_material
	volcano.add_child(stream)
	sheet = MeshInstance3D.new()
	sheet.name = "ThinSheet"
	sheet.material_override = glow_material
	volcano.add_child(sheet)
	land = Node3D.new()
	land.name = "NewLand"
	var s := shore()
	var d := flow_dir()
	land.transform = Transform3D(Basis(Vector3(d.x, 0.0, d.z), Vector3.UP, Vector3(-d.z, 0.0, d.x).cross(Vector3.UP) * -1.0), Vector3(s.x, SEA_Y, s.z))
	land.basis = Basis(d, Vector3.UP, d.cross(Vector3.UP))
	land.visible = false
	volcano.add_child(land)
	land.add_child(ArtKit.instance(_land_mesh()))
	var embers := ArtKit.instance(_land_embers_mesh(), glow_material)
	embers.name = "Embers"
	land.add_child(embers)


## The volcano: a lumpy cone steepening to its rim, the crater inside, its slopes brown with darker
## old lava streaks down them.
func _volcano_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var sides := 40
	var radii := [1.0, 0.85, 0.68, 0.52, 0.38, 0.25, 0.0].map(func(k: float) -> float: return lerpf(RIM_RADIUS, VOLCANO_RADIUS, k))
	var surface := func(r: float, i: int) -> Vector3:
		var a := TAU * i / sides
		var lump := 1.0 + (0.012 * sin(i * 1.7) + 0.008 * sin(i * 4.3)) * (1.0 if r < VOLCANO_RADIUS - 0.01 else 3.0)
		var y := slope_y(r) + (0.08 * sin(i * 2.3 + r) if r > RIM_RADIUS + 0.01 and r < VOLCANO_RADIUS - 0.01 else 0.0)
		return VOLCANO_AT + Vector3(cos(a) * r * lump, y - (0.3 if r >= VOLCANO_RADIUS else 0.0), -sin(a) * r * lump)
	var tone := func(r: float, i: int) -> Color:
		var k := 1.0 - (r - RIM_RADIUS) / (VOLCANO_RADIUS - RIM_RADIUS)
		var c := ArtPalette.VOLCANO.lerp(ArtPalette.VOLCANO_TOP, k)
		return c.darkened(0.22) if i % 7 == 3 or i % 11 == 6 else c
	for k in radii.size() - 1:
		for i in sides:
			var p0: Vector3 = surface.call(radii[k], i)
			var p1: Vector3 = surface.call(radii[k], i + 1)
			var p2: Vector3 = surface.call(radii[k + 1], i + 1)
			var p3: Vector3 = surface.call(radii[k + 1], i)
			var c0: Color = tone.call(radii[k], i)
			var c1: Color = tone.call(radii[k + 1], i)
			b.add_triangle([p0, p1, p2], [c0, c0, c1], Vector3.UP)
			b.add_triangle([p0, p2, p3], [c0, c1, c1], Vector3.UP)
	# The crater: from the rim down its inner wall to a floor.
	var floor_y := VOLCANO_HEIGHT - CRATER_DEPTH
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var r0 := RIM_RADIUS
		var r1 := RIM_RADIUS * 0.7
		var t0 := VOLCANO_AT + Vector3(cos(a0) * r0, VOLCANO_HEIGHT, -sin(a0) * r0)
		var t1 := VOLCANO_AT + Vector3(cos(a1) * r0, VOLCANO_HEIGHT, -sin(a1) * r0)
		var f0 := VOLCANO_AT + Vector3(cos(a0) * r1, floor_y, -sin(a0) * r1)
		var f1 := VOLCANO_AT + Vector3(cos(a1) * r1, floor_y, -sin(a1) * r1)
		var inward := VOLCANO_AT + Vector3(0.0, floor_y, 0.0) - t0
		b.add_triangle([t0, t1, f1], [ArtPalette.VOLCANO_TOP, ArtPalette.VOLCANO_TOP, ArtPalette.CRATER], inward + Vector3.UP)
		b.add_triangle([t0, f1, f0], [ArtPalette.VOLCANO_TOP, ArtPalette.CRATER, ArtPalette.CRATER], inward + Vector3.UP)
		b.add_triangle([VOLCANO_AT + Vector3(0.0, floor_y, 0.0), f0, f1], [ArtPalette.CRATER, ArtPalette.CRATER, ArtPalette.CRATER], Vector3.UP)
	return b.commit()


## The plug now: its height from the lava, a swell (bigger while the pump pushes) and the bubbles
## on its top, each swelling and popping in turn.
func _pose_plug() -> void:
	var high := lerpf(PLUG_LOW, PLUG_HIGH, _plug_k)
	var swell := sin(_t * TAU * PLUG_HZ) * (PLUG_SWELL if _flowing else PLUG_REST)
	var wide := RIM_RADIUS * PLUG_WIDE * (1.0 + 0.5 * swell)
	plug_dome.scale = Vector3(wide, high * (1.0 + swell), wide)
	for k in _bubbles.size():
		var bubble := _bubbles[k]
		var phase := fposmod(_t / BUBBLE_S + float(k) / _bubbles.size(), 1.0)
		var a := TAU * (k * 0.37 + 0.1)
		var d := 0.15 + 0.4 * fposmod(k * 0.618, 1.0)
		var top := high * (1.0 + swell) * pow(1.0 - d * d, 0.7)
		bubble.position = Vector3(cos(a) * d * wide, top - 0.05, sin(a) * d * wide + 0.2 * wide)
		bubble.scale = Vector3.ONE * (0.12 + 0.3 * phase) * (1.0 if phase < 0.85 else (1.0 - phase) / 0.15) * (0.7 + 0.3 * _plug_k) + Vector3.ONE * 0.001


## A dome of radius 1 and height 1 over a skirt down into the crater: lumpy cooled crust (dark red
## rock, 2026-11-07 user: it must read as solid rock) with a hot glow only at its top and a few thin
## ember seams under it.
func _dome_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var rings := [0.0, 0.14, 0.3, 0.45, 0.6, 0.74, 0.87, 1.0, 1.08]
	var sides := 24
	var at := func(d: float, i: int) -> Vector3:
		var a := TAU * i / sides
		var lump := 1.0 + 0.07 * sin(i * 2.3 + d * 7.0) if d > 0.05 and d < 1.0 else 1.0
		var y := pow(maxf(1.0 - d * d, 0.0), 0.7) * (1.0 + 0.05 * sin(i * 3.1)) if d <= 1.0 else -0.6
		return Vector3(cos(a) * minf(d, 1.0) * lump, y, sin(a) * minf(d, 1.0) * lump)
	var colour := func(r: int, i: int) -> Color:
		if r == 0:
			return LAVA_HOT
		if r == 1 and i % 2 == 0:
			return EMBER
		if r in [2, 3] and i % 8 == 3:   # a few thin seams under the top
			return EMBER
		return CRUST.lerp(CRUST_LIGHT, 0.5 + 0.5 * sin(i * 1.7 + r * 2.1))
	for r in rings.size() - 1:
		for i in sides:
			var p0: Vector3 = at.call(rings[r], i)
			var p1: Vector3 = at.call(rings[r], i + 1)
			var p2: Vector3 = at.call(rings[r + 1], i + 1)
			var p3: Vector3 = at.call(rings[r + 1], i)
			var c: Color = colour.call(r, i)
			b.add_triangle([p0, p2, p3], [c, c, c], Vector3.UP)
			b.add_triangle([p0, p1, p2], [c, c, c], Vector3.UP)
	return b.commit()


## The normal lava's stream down the flow way to `front` (0..1), wider towards the foot: a yellow core
## and orange-red edges.
func _stream_mesh(front: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var steps := maxi(2, int(ceil(front * 30.0)))
	for k in steps:
		var s0 := front * k / steps
		var s1 := front * (k + 1) / steps
		var w0 := lerpf(STREAM_WIDTH.x, STREAM_WIDTH.y, s0) * 0.5
		var w1 := lerpf(STREAM_WIDTH.x, STREAM_WIDTH.y, s1) * 0.5
		if k == steps - 1:
			w1 *= 0.6   # a round-ish tip
		var l0 := flow_point(s0, -w0)
		var r0 := flow_point(s0, w0)
		var l1 := flow_point(s1, -w1)
		var r1 := flow_point(s1, w1)
		var m0 := flow_point(s0) + Vector3(0.0, 0.03, 0.0)
		var m1 := flow_point(s1) + Vector3(0.0, 0.03, 0.0)
		for side: Array in [[l0, l1], [r0, r1]]:
			b.add_triangle([side[0], m0, m1], [LAVA_EDGE, LAVA_CORE, LAVA_CORE], Vector3.UP)
			b.add_triangle([side[0], m1, side[1]], [LAVA_EDGE, LAVA_CORE, LAVA_EDGE], Vector3.UP)
	return b.commit()


## The runny lava's thin sheet: a fan across the flank from the rim down to `front` (0..1).
func _sheet_mesh(front: float) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var spokes := 16
	var steps := 10
	var point := func(s: float, u: float) -> Vector3:
		var a := deg_to_rad(FLOW_DEG + SHEET_SPREAD_DEG * u * (0.4 + 0.6 * s / maxf(front, 0.01)))
		var r := lerpf(RIM_RADIUS, VOLCANO_RADIUS, s)
		var p := VOLCANO_AT + Vector3(cos(a), 0.0, -sin(a)) * r
		return Vector3(p.x, slope_y(r) + LAVA_LIFT, p.z)
	for k in steps:
		var s0 := front * k / steps
		var s1 := front * (k + 1) / steps
		for j in spokes:
			var u0 := lerpf(-1.0, 1.0, float(j) / spokes)
			var u1 := lerpf(-1.0, 1.0, float(j + 1) / spokes)
			var c0 := LAVA_HOT.lerp(LAVA_EDGE, float(k) / steps)
			var c1 := LAVA_HOT.lerp(LAVA_EDGE, float(k + 1) / steps)
			b.add_triangle([point.call(s0, u0), point.call(s0, u1), point.call(s1, u1)], [c0, c0, c1], Vector3.UP)
			b.add_triangle([point.call(s0, u0), point.call(s1, u1), point.call(s1, u0)], [c0, c1, c1], Vector3.UP)
	return b.commit()


## The new land (local: x along the flow from the shore, z across): a low lumpy tongue of dark rock
## LAND_LENGTH long (the node's x scale grows it), rounded at its tip.
func _land_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 0.85
	b.ao_height = 0.3
	for k in 7:
		var x := LAND_LENGTH * (0.08 + 0.14 * k)
		var w := LAND_WIDTH * 0.5 * (1.0 - 0.1 * k) * (0.9 + 0.12 * sin(k * 2.1))
		b.add_sphere(Transform3D(Basis.from_scale(Vector3(0.75, 0.22, 1.0)), Vector3(x, -0.05, 0.25 * sin(k * 1.3))), w, 3, 10, ROCK_DARK.lerp(ROCK_LIGHT, 0.3 * (k % 2)))
	return b.commit()


## The new land's embers: glowing cracks on its top (they read in the night).
func _land_embers_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for k in 9:
		var x := LAND_LENGTH * (0.1 + 0.09 * k)
		var z := 0.5 * sin(k * 2.4)
		b.add_rounded_box(Transform3D(Basis(Vector3.UP, 0.6 * sin(k * 1.7)), Vector3(x, 0.17, z)), Vector3(0.5, 0.03, 0.08), 0.0, 1, LAVA_EDGE if k % 2 == 0 else LAVA_HOT)
	return b.commit()


func _build_sea(lab: Node3D) -> void:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var sides := 48
	var ring := func(k: int, grow: float) -> Vector3:
		var a := TAU * k / sides
		var wave := 1.0 + 0.04 * sin(k * 5.0) + 0.03 * sin(k * 2.0 + 1.0)
		return SEA_AT + Vector3(cos(a) * (SEA_RADII.x + grow) * wave, SEA_Y, sin(a) * (SEA_RADII.y + grow) * wave)
	var mid := SEA_AT + Vector3(0.0, SEA_Y, 0.0)
	for k in sides:
		var shallow0: Vector3 = ring.call(k, -1.2)
		var shallow1: Vector3 = ring.call(k + 1, -1.2)
		var edge0: Vector3 = ring.call(k, 0.0)
		var edge1: Vector3 = ring.call(k + 1, 0.0)
		var foam0: Vector3 = ring.call(k, 0.25) + Vector3(0.0, 0.004, 0.0)
		var foam1: Vector3 = ring.call(k + 1, 0.25) + Vector3(0.0, 0.004, 0.0)
		var sand0: Vector3 = ring.call(k, 1.1) + Vector3(0.0, -0.02, 0.0)
		var sand1: Vector3 = ring.call(k + 1, 1.1) + Vector3(0.0, -0.02, 0.0)
		b.add_triangle([mid, shallow0, shallow1], [ArtPalette.SEA, ArtPalette.SEA, ArtPalette.SEA], Vector3.UP)
		b.add_triangle([shallow0, edge0, edge1], [ArtPalette.SEA, ArtPalette.SEA_SHALLOW, ArtPalette.SEA_SHALLOW], Vector3.UP)
		b.add_triangle([shallow0, edge1, shallow1], [ArtPalette.SEA, ArtPalette.SEA_SHALLOW, ArtPalette.SEA], Vector3.UP)
		b.add_triangle([edge0, foam0, foam1], [ArtPalette.FOAM, ArtPalette.FOAM, ArtPalette.FOAM], Vector3.UP)
		b.add_triangle([edge0, foam1, edge1], [ArtPalette.FOAM, ArtPalette.FOAM, ArtPalette.FOAM], Vector3.UP)
		b.add_triangle([foam0, sand0, sand1], [ArtPalette.SAND, ArtPalette.SAND, ArtPalette.SAND], Vector3.UP)
		b.add_triangle([foam0, sand1, foam1], [ArtPalette.SAND, ArtPalette.SAND, ArtPalette.SAND], Vector3.UP)
	for k in 9:   # a few wave strokes
		var a := TAU * fposmod(k * 0.381966, 1.0)
		var r := 0.25 + 0.5 * fposmod(k * 0.618, 1.0)
		var at := SEA_AT + Vector3(cos(a) * SEA_RADII.x * r, SEA_Y + 0.01, sin(a) * SEA_RADII.y * r)
		b.add_rounded_box(Transform3D(Basis(), at), Vector3(1.1, 0.01, 0.08), 0.0, 1, ArtPalette.FOAM)
	var sea := ArtKit.instance(b.commit())
	sea.name = "Sea"
	lab.add_child(sea)


func _build_village(lab: Node3D) -> void:
	var b := ArtKit.builder()
	var lights := ArtKit.builder()
	lights.ao_min = 1.0
	for h: Array in HOUSES:
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(h[2]))).scaled(Vector3.ONE * HOUSE_SIZE), Vector3(float(h[0]), 0.0, float(h[1])))
		b.ao_min = 0.85
		b.ao_height = 0.4
		b.add_rounded_box(xf * Transform3D(Basis(), Vector3(0.0, 0.35, 0.0)), Vector3(0.9, 0.7, 0.75), 0.04, 1, DayNightProps.WALL)
		var roof := DayNightProps.ROOF
		var ridge := Vector3(0.0, 1.05, 0.0)
		for side: float in [-1.0, 1.0]:
			var eave := Vector3(side * 0.56, 0.66, 0.0)
			var front := Vector3(0.0, 0.0, 0.46)
			b.add_triangle([xf * (eave - front), xf * (eave + front), xf * (ridge + front)], [roof, roof, DayNightProps.ROOF_TOP], xf.basis * Vector3(side, 1.0, 0.0))
			b.add_triangle([xf * (eave - front), xf * (ridge + front), xf * (ridge - front)], [roof, DayNightProps.ROOF_TOP, DayNightProps.ROOF_TOP], xf.basis * Vector3(side, 1.0, 0.0))
		for side: float in [-1.0, 1.0]:
			var gable := Vector3(0.0, 0.0, side * 0.375)
			b.add_triangle([xf * (Vector3(-0.45, 0.7, 0.0) + gable), xf * (Vector3(0.45, 0.7, 0.0) + gable), xf * (ridge + gable * 1.0)], [DayNightProps.WALL, DayNightProps.WALL, DayNightProps.WALL], xf.basis * Vector3(0.0, 0.0, side))
		b.add_rounded_box(xf * Transform3D(Basis(), Vector3(-0.2, 0.2, 0.38)), Vector3(0.2, 0.4, 0.02), 0.0, 1, DayNightProps.DOOR)
		lights.add_rounded_box(xf * Transform3D(Basis(), Vector3(0.18, 0.42, 0.385)), Vector3(0.24, 0.2, 0.02), 0.0, 1, Color("ffd65a"))
	var houses := ArtKit.instance(b.commit())
	houses.name = "Village"
	lab.add_child(houses)
	village_lights = ArtKit.instance(lights.commit(), glow_material)
	village_lights.name = "VillageLights"
	village_lights.visible = false
	lab.add_child(village_lights)


## The night's stars: little glowing dots over the far land and sea within the camera's turn.
func _stars_mesh() -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	for i in STARS:
		var a := deg_to_rad(lerpf(-75.0, 75.0, fposmod(i * 0.618034, 1.0)))
		var up := deg_to_rad(lerpf(8.0, 40.0, fposmod(i * 0.414214 + 0.1, 1.0)))
		var dir := Vector3(sin(a) * cos(up), sin(up), -cos(a) * cos(up))
		var size := 0.45 if i % 6 == 0 else 0.28
		var c := Color("fff3b0") if i % 4 == 0 else Color.WHITE
		var at := dir * STAR_FAR
		var right := dir.cross(Vector3.UP).normalized() * size
		var upv := right.cross(dir).normalized() * size
		b.add_triangle([at + upv, at + right, at - upv], [c, c, c], -dir)
		b.add_triangle([at + upv, at - upv, at - right], [c, c, c], -dir)
	return b.commit()


# --- smoke and steam ------------------------------------------------------------------------------------

func _build_puffs(lab: Node3D) -> void:
	var steam := ArtKit.builder()
	steam.ao_min = 1.0
	steam.add_sphere(Transform3D(), 1.0, 4, 10, STEAM)
	var smoke := ArtKit.builder()
	smoke.ao_min = 1.0
	smoke.add_sphere(Transform3D(), 1.0, 4, 10, SMOKE)
	var meshes := {"crater": smoke.commit(), "shore": steam.commit()}
	meshes["vent"] = meshes["crater"]
	for source: String in ["crater", "shore", "vent"]:
		_sources[source] = {"at": Vector3.ZERO, "rate": 0.0, "size": 1.0}
		for k in PUFFS:
			var puff := ArtKit.instance(meshes[source], glow_material)
			puff.name = "Puff_%s_%d" % [source, k]
			puff.visible = false
			lab.add_child(puff)
			_puffs.append([puff, source, float(k) / PUFFS])


func _set_source(id: String, at: Vector3, rate: float, size: float) -> void:
	_sources[id] = {"at": at, "rate": rate, "size": size}


## Every puff rises from its source over PUFF_S, growing and drifting right, then shrinks away; a
## source at rate r shows only that share of its puffs.
func _advance_puffs() -> void:
	for p: Array in _puffs:
		var src: Dictionary = _sources[p[1]]
		var phase: float = p[2]
		var node: MeshInstance3D = p[0]
		var k := fposmod(_t / PUFF_S + phase, 1.0)
		var boost := burst if p[1] == "shore" else 0.0
		var on := phase < maxf(float(src.rate), ceilf(boost)) - 1e-6
		node.visible = on
		if not on:
			continue
		var size: float = float(src.size) * (1.0 + 0.8 * boost)
		var spread := Vector3(sin(phase * 17.0) * 0.4, 0.0, cos(phase * 11.0) * 0.3) * size
		node.position = (src.at as Vector3) + spread + Vector3(0.6 * k * size, 2.4 * k * size, 0.0)
		node.scale = Vector3.ONE * size * (0.35 + 0.65 * k) * sin(PI * minf(1.0, k * 1.15)) + Vector3.ONE * 0.001
