## 구름과 이슬 (#92, 2026-11-07; Hutton Island's fifth spot, docs/islands/hutton-missions.md 5 and
## hutton-lines.md 5): a seaside hill with a table (a glass cup of water, a bowl of ice) and a
## mountain by the sea. Stages 1 and 2: the child drags ice cubes from the bowl into the cup; every
## cube cools the cup, and once it is at the air's dew point dew beads on the glass. Stage 3: the
## child drags a parcel of sea air up the mountain's skyline; it cools as it rises and at its cloud
## base it turns into a cloud. The condition button (왼쪽 아래) picks the day: 눅눅한 날 (humid) or
## 마른 날 (dry): the dry day's lower dew point needs more ice (and its air makes no cloud below the
## summit).
##
## Model: DewCloudModel (the dew point by the Magnus formula, the parcel's lapse rates). The lab only
## draws it (EarthLab): the stages are judged on its status ("dew", "cloud"; the misses "clear",
## "rising"), never on a number on the screen.
##
## The hands: two knobs on upright planes facing the camera, one per part of the round:
## - "ice" (stages 1 and 2, and after the round): the next cube on the bowl's heap. It follows the
##   finger; let go over the cup (or just above it: DROP_SLACK, DROP_ABOVE) it drops in (the model's
##   add_ice), anywhere else it goes back to the heap. A drop is one attempt (the mission judges it once
##   the cup has cooled); it is not a placement (nothing to restore: the cubes are the model's).
## - "air" (stage 3, and after the round): the parcel, dragged along the mountain's right skyline
##   (DewCloudProps.lift_of: the way's point nearest the finger). A put-down keeps its place
##   (placements), a cancel puts it back.
## A knob not in play has no body (manipulation_body null): it cannot be picked and the hand guide
## shows the other. The parcel shows only while its knob is in play.
class_name DewCloudLab
extends EarthLab

const ICE_ID := "ice"
const AIR_ID := "air"
const AIR_CONTROL := "air"
## The stage (0-based) the parcel is played in.
const AIR_STAGE := 2
## The knobs' boxes (m): an ice cube a finger takes, the parcel.
const ICE_BOX := 0.8
const AIR_BOX := 1.8
## A cube let go within this much (m) beside the cup's rim, or up to DROP_ABOVE over it, drops in.
const DROP_SLACK := 0.45
const DROP_ABOVE := 1.5
## The ice plane's reach (m): left of the bowl, right of the cup, over the cup.
const ICE_LEFT := 1.3
const ICE_RIGHT := 1.4
const ICE_UP := 2.2
## The slope plane's reach (m): left of the summit, right of the foot, over the summit.
const AIR_LEFT := 1.6
const AIR_RIGHT := 1.6
const AIR_UP := 2.6
## The cup's and the parcel's words: "cold" past these shares of their range, "icy" past ICE_WORD.
## The lab's own trees keep this clear (m, x/z) of the line from the front view's eye to the air's
## way up the mountain (#114 2026-11-10 user: "세번쨰 실험에서, 공기가 어딨는지 안보여. 나무에 가려져서").
const WAY_CLEAR := 3.8
const COOL_WORD := 0.15
const COLD_WORD := 0.45
const ICY_WORD := 0.75
const LOW_WORD := 0.34
const HIGH_WORD := 0.8

var props := DewCloudProps.new()
var _ice_surface: ManipSurface
var _air_surface: ManipSurface
var _graph_key := Vector3.INF
var _graph_revision := 0


func _init() -> void:
	model = DewCloudModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(ICE_ID, "IceKnob", ICE_BOX)
	add_knob(AIR_ID, "AirKnob", AIR_BOX)
	var basis := Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
	var low := DewCloudProps.TABLE_TOP + 0.15
	var high := DewCloudProps.TABLE_TOP + DewCloudProps.CUP_HEIGHT + ICE_UP
	_ice_surface = ManipSurface.new(Transform3D(basis, Vector3(0.0, 0.0, DewCloudProps.CUP_AT.z - ICE_BOX * 0.5)),
		Vector2(DewCloudProps.BOWL_AT.x - ICE_LEFT, -high), Vector2(DewCloudProps.CUP_AT.x + ICE_RIGHT, -low))
	var foot := DewCloudProps.parcel_point(0.0)
	var top := DewCloudProps.parcel_point(1.0)
	_air_surface = ManipSurface.new(Transform3D(basis, Vector3(0.0, 0.0, DewCloudProps.MOUNTAIN_AT.z - AIR_BOX * 0.5)),
		Vector2(DewCloudProps.MOUNTAIN_AT.x - AIR_LEFT, -(top.y + AIR_UP)), Vector2(foot.x + AIR_RIGHT, -foot.y + 0.4))
	game = DewCloudGame.new(self)
	add_child(game)
	game.build()


## The day: 눅눅한 날 or 마른 날 (the model's humidity start: kept across 다시).
func _apply_control(id: String, value: Variant) -> void:
	if id == AIR_CONTROL:
		model.set_start("humidity", DewCloudModel.DRY if str(value) == "dry" else DewCloudModel.HUMID)


# --- the knobs ------------------------------------------------------------------------------------

## The part of the round in play: the parcel in stage 3, the ice before it; both once the round is
## done (free play).
func in_play(id: String) -> bool:
	if game == null or game.stage >= game.stages:
		return true
	return (game.stage == AIR_STAGE) == (id == AIR_ID)


func manipulation_body(id: String) -> PhysicsBody3D:
	return knobs.get(id) if in_play(id) else null


func manipulation_surface(surface_id: String) -> ManipSurface:
	return _air_surface if surface_id == "slope" else _ice_surface


func _knob_inputs(id: String, xf: Transform3D) -> Dictionary:
	if id == AIR_ID:
		return {"lift": DewCloudProps.lift_of(xf.origin)}
	return {}


func _knob_pose(id: String) -> Transform3D:
	if id == AIR_ID:
		var p := DewCloudProps.parcel_point(model.input("lift"))
		return _air_surface.pose(Vector2(p.x, -p.y), AIR_BOX * 0.5)
	var at := DewCloudProps.BOWL_AT + DewCloudProps.NEXT_ICE
	return _ice_surface.pose(Vector2(at.x, -at.y), ICE_BOX * 0.5)


## A cube at `at` (world) is over the cup's mouth: beside its rim by DROP_SLACK at most, from its
## foot up to DROP_ABOVE over it.
static func over_cup(at: Vector3) -> bool:
	var cup := DewCloudProps.CUP_AT
	return absf(at.x - cup.x) <= DewCloudProps.CUP_TOP + DROP_SLACK \
		and at.y >= cup.y and at.y <= cup.y + DewCloudProps.CUP_HEIGHT + DROP_ABOVE


## A cube let go: over the cup it drops in (one more cube, the cup cools), anywhere else it goes
## back to the heap. Nothing to restore later (not a placement).
func manipulation_placed(id: String, transform: Transform3D) -> void:
	if id != ICE_ID:
		super(id, transform)
		return
	holding = ""
	var dropped := over_cup(transform.origin) and (model as DewCloudModel).add_ice()
	if dropped:
		SoundBoard.play(&"glint")
	_show()
	_update_status(true)


## The stage changed (DewCloudGame.show_stage): the knob in play and the parcel's showing follow it.
## LabWorld asks (its near_tree_at hook, as the volcano's): a tree of the lab's own standing between the
## front view's eye and the air's way up the mountain is moved to the right until it is clear of it.
func near_tree_at(at: Vector2) -> Vector2:
	var moved := at
	for k in 24:
		if not hides_way(moved):
			return moved
		moved.x += 0.5
	return moved


## A tree at `at` (x/z) stands in front of the air's way, within WAY_CLEAR of a sight line from the
## front eye to it.
func hides_way(at: Vector2) -> bool:
	var eye3 := IslandCast.front_eye(definition.camera() if definition != null else {})
	var eye := Vector2(eye3.x, eye3.z)
	for k in 11:
		var p3 := DewCloudProps.parcel_point(k / 10.0)
		var p := Vector2(p3.x, p3.z)
		var closest := Geometry2D.get_closest_point_to_segment(at, eye, p)
		if closest.distance_to(at) < WAY_CLEAR and (at - p).dot(eye - p) > 0.0:   # (in front of the way)
			return true
	return false


func stage_changed() -> void:
	if is_inside_tree():
		_show()


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as DewCloudModel
	var ice_at := DewCloudProps.BOWL_AT + DewCloudProps.NEXT_ICE
	if holding == ICE_ID and knobs.has(ICE_ID):
		ice_at = (knobs[ICE_ID] as Node3D).global_position
	props.show(m.ice_count(), m.cold_share(), m.dew_share(), m.humid(), m.input("lift"), m.parcel_cool_share(), m.cloud_share(), in_play(AIR_ID), ice_at)


## Words only (no degrees: the user): what happened (dew, a cloud), how cold the cup is, how high
## the air went.
func observations() -> Dictionary:
	var m := model as DewCloudModel
	var cold := m.cold_share()
	var lift := m.input("lift")
	return {
		"state": Locale.t("dew_cloud.status." + m.status()),
		"cup": Locale.t("dew_cloud.cup." + ("icy" if cold >= ICY_WORD else "cold" if cold >= COLD_WORD else "cool" if cold >= COOL_WORD else "warm")),
		"height": Locale.t("dew_cloud.height." + ("top" if lift >= HIGH_WORD else "middle" if lift >= LOW_WORD else "low")),
	}


## "자세히": the cup's temperature for 0..ICE_MAX cubes, the day's dew point across it, and the cup
## now (cubes, °C). The window shows no number; the graph has its units, as the earlier labs'.
func graph_series() -> Dictionary:
	var m := model as DewCloudModel
	var cup := PackedVector2Array()
	for n in DewCloudModel.ICE_MAX + 1:
		cup.append(Vector2(n, m.input("air") - DewCloudModel.COOL_PER_ICE * n))
	var td := m.air_dew_point()
	return {"cup": cup, "dew": PackedVector2Array([Vector2(0.0, td), Vector2(DewCloudModel.ICE_MAX, td)]),
		"now": PackedVector2Array([Vector2(m.ice_count(), m.input("cup"))])}


func graph_revision() -> int:
	var key := Vector3(model.input("ice"), model.input("cup"), model.input("humidity"))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## Dugi points at the cup, or at the parcel in its stage.
func explain_point() -> Vector3:
	if in_play(AIR_ID) and not in_play(ICE_ID):
		return props.parcel.global_position
	return props.cup.global_position + Vector3.UP * DewCloudProps.CUP_HEIGHT * 0.6


## The camera looks at the middle of the hill (the cup and the mountain both in view).
func follow_point() -> Vector3:
	return Vector3(0.4, 2.3, 0.0)
