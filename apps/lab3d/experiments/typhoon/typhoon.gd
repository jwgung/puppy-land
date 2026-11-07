## 태풍·비구름 (#94, 2026-11-07; Hutton Island's seventh spot, docs/islands/hutton-missions.md 7 and
## hutton-lines.md 7): a round sea basin on the coast, the island on its right, the far strip cold
## water. The child drags a small cloud over the sea (no inertia; it stays where it is put). Over a
## warm sea it takes up water vapour and grows into a rain cloud, over a very warm one on into a
## typhoon; over cold water or land it loses its strength. The condition button (왼쪽 아래) picks the
## open sea: 차가운 / 따뜻한 / 아주 따뜻한 (the far strip is always cold).
##
## Model: TyphoonModel, a rule (no simple formula: docs/islands/hutton.md "시뮬레이션"). The lab only
## draws it (EarthLab): the stages are judged on its status ("rain", "typhoon", "calm"; the misses on
## the others), never on a number on the screen. The cloud changes by itself once moved (the model is
## animating), so the round judges it when it has got where its place takes it.
##
## The last stage starts from the big typhoon out at sea, heading for the island (an orange way on the
## sea): the round's stage reaches the lab through set_game_stage, as in the free fall's heights. The
## first two stages start from a small cloud on the island's beach.
##
## The hand: one knob ("cloud"), a pickable box round the cloud, dragged on a flat plane at the cloud's
## height (manipulation.objects[].surface "sea"; no footprint marker). The surface's frame turns with
## the stage so the hand guide's drag (guide_to "min": the region's first corner) shows the stage's way:
## out over the open sea (the first two), up to the cold strip (the last).
class_name TyphoonLab
extends EarthLab

const KNOB_ID := "cloud"
## The knob's box (m): it covers a small cloud and a typhoon's middle.
const KNOB_BOX := 2.4
## The stage (0-based) that starts from the typhoon at sea.
const STORM_STAGE := 2
## The last stage's region reaches this far right (world x, past the basin: the shore is land) so the
## hand guide's corner takes the typhoon up and right, to the cold strip right of the mission strip
## at the top left (#94 review: it hid the weakening cloud on the tablet).
const STORM_REACH_X := 11.5
## The size graph ("자세히"): one point per this many seconds, at most GRAPH_POINTS.
const GRAPH_EVERY := 0.25
const GRAPH_POINTS := 160

var props := TyphoonProps.new()
var _graph := PackedVector2Array()
var _graph_clock := 0.0
var _graph_revision := 0
var _stage := -1
## The next run starts from the typhoon at sea (the round's last stage; the run now keeps its start
## until it is reset).
var _storm_next := false


func _init() -> void:
	model = TyphoonModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(KNOB_ID, "CloudKnob", KNOB_BOX)
	game = TyphoonGame.new(self)
	add_child(game)
	game.build()


## The sea condition: 차가운 / 따뜻한 / 아주 따뜻한 (the model's start: kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == "sea":
		model.set_start("sea", {"cold": TyphoonModel.COLD, "warm": TyphoonModel.WARM, "hot": TyphoonModel.HOT}.get(str(value), TyphoonModel.WARM))


## The round's stage (-1: done): the last one starts from the typhoon at sea, the others from the small
## cloud. A stage just cleared waits for the next run (the screen resets before the next mission).
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	if stage == _stage:
		return
	_stage = stage
	_storm_next = stage == STORM_STAGE
	if _storm_next != storm_run() and not just_cleared:
		reset_run()


## The run starts over from the stage's start (the small cloud, or the typhoon at sea).
func reset_run() -> void:
	(model as TyphoonModel).start_storm(_storm_next)
	_graph = PackedVector2Array()
	_graph_clock = 0.0
	_graph_revision += 1
	super()
	if game != null:
		game.run_reset()


## The run is the typhoon at sea (the last stage's start): the game's own typhoon gives way to it.
func storm_run() -> bool:
	return (model as TyphoonModel).storm_start


func _physics_process(delta: float) -> void:
	super(delta)
	var m := model as TyphoonModel
	if m.moved() and _graph.size() < GRAPH_POINTS and (m.animating() or holding != ""):
		_graph_clock += delta
		if _graph.is_empty() or _graph_clock - _graph[_graph.size() - 1].x >= GRAPH_EVERY:
			_graph.append(Vector2(_graph_clock, m.input("size") * 100.0))
			_graph_revision += 1


func _process(delta: float) -> void:
	super(delta)
	props.animate(delta)


# --- the knob -------------------------------------------------------------------------------------

## The plane at the cloud's height (the Manipulator rests the knob's centre half its box over it). The
## frame turns with the stage: its region's first corner is the near left of the sea (the open sea:
## the hand guide's way in the first stages) or the far right (the cold strip, clear of the mission
## strip at the top left: the last stage's).
func manipulation_surface(_surface_id: String) -> ManipSurface:
	var y := TyphoonProps.SEA_Y + TyphoonProps.CLOUD_HEIGHT - KNOB_BOX * 0.5
	var lo := TyphoonModel.REACH_MIN
	var hi := TyphoonModel.REACH_MAX
	if storm_run():
		# Turned a quarter the other way: plane x = world z, plane z = world -x.
		var back := Basis(Vector3.UP, -PI * 0.5)
		return ManipSurface.new(Transform3D(back, Vector3(0.0, y, 0.0)), Vector2(lo.y, -STORM_REACH_X), Vector2(hi.y, -lo.x))
	# Turned a quarter about y: plane x = world -z, plane z = world x.
	var turn := Basis(Vector3.UP, PI * 0.5)
	return ManipSurface.new(Transform3D(turn, Vector3(0.0, y, 0.0)), Vector2(-hi.y, lo.x), Vector2(-lo.y, hi.x))


func _knob_inputs(_id: String, xf: Transform3D) -> Dictionary:
	return {"x": xf.origin.x, "z": xf.origin.z}


func _knob_pose(_id: String) -> Transform3D:
	return Transform3D(Basis(), TyphoonProps.cloud_point(model.input("x"), model.input("z")))


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as TyphoonModel
	props.show(m.input("x"), m.input("z"), m.input("size"), m.input("sea"))
	props.way.visible = storm_run() and m.status() == "ready"


## Words only (no number: the user): the cloud, what is under it and the vapour rising there.
func observations() -> Dictionary:
	var words: Dictionary = model.observations()
	return {"state": Locale.t("typhoon.cloud." + str(words.state)), "under": Locale.t("typhoon.under." + str(words.under)),
		"vapor": Locale.t("typhoon.vapor." + str(words.vapor))}


## The cloud's strength since it was moved ("자세히": the screen shows no number).
func graph_series() -> Dictionary:
	var m := model as TyphoonModel
	return {"size": _graph, "now": PackedVector2Array([Vector2(_graph_clock, m.input("size") * 100.0)])}


func graph_revision() -> int:
	return _graph_revision


## Dugi points at the cloud; the camera follows it.
func explain_point() -> Vector3:
	return props.cloud.global_position


func follow_point() -> Vector3:
	return props.cloud.global_position
