## 녹으면 사라질까? (#157, 2026-11-17; Curie Island's second spot, docs/islands/curie-missions.md 2 and
## curie-lines.md 2): Curie Island's kitchen (KitchenSet), a glass of water with a spoonful of salt at its
## bottom and a spoon in it. The child stirs: a finger going round and round over the glass (manipulation
## rule "stir": the hand guide goes round) turns the spoon round the glass and the salt dissolves; the
## water is cloudy while it does and clear once it is all gone. No condition buttons (the mission doc).
##
## The table changes with the stage (as diffusion's): stage 1 the glass (CUP), stage 2 the glass and the
## salt dish on a needle scale (SCALE: the needle stays on the ghost of where it stood), stage 3 (and a
## finished round) the seawater bucket, the sun tray and the time sign (TRAY): the child drags the bucket
## over the tray and lets go; it pours, and the time runs by itself (FastClock, the plan's decision 1
## 안 A: the sign's marker goes from the sun to the moon, the scene goes dark at night, a moon stamp for
## every night) until the water is gone and the salt is left. The time is not touched: the bucket is the
## stage's one thing (the mission doc's "one object changes").
##
## Model: DissolvingModel (rules with textbook values: salt's solubility, mass conserved, seawater 3.5 %
## salt, evaporation by day). The lab only draws it (EarthLab): the stages are judged on its status
## ("clear", "same", "salt"; the misses "dissolving" and "drying"), never on a number on the screen.
##
## The hand: two knobs, one per table. "spoon" (CUP, SCALE): a box at the spoon's handle, dragged on the
## upright plane through the glass's axis facing the camera (STIR surface: its middle over the glass);
## the angle of the finger round that middle is the spoon's place round the glass, and every turn of it
## (either way) stirs (DissolvingModel.stir). "bucket" (TRAY, before the pour): a box on the bucket,
## dragged along a line from its place to over the tray; let go over the tray it pours, anywhere else it
## goes back. Nothing is kept by placements(): stirring and pouring are events.
class_name DissolvingLab
extends EarthLab

const SPOON_ID := "spoon"
const BUCKET_ID := "bucket"
const STIR_SURFACE := "stir"
const POUR_SURFACE := "pour"
## The knobs: the spoon's box (m) and how far from the stir middle a finger still stirs (m); the
## bucket's box and how far right of the tray's edge it may be dragged.
const SPOON_KNOB := 0.8
const STIR_REACH := 1.0
const BUCKET_KNOB := 1.0
const BUCKET_REACH := 1.9
## A finger nearer the stir middle than this (m) does not turn the spoon (its angle is unsure there).
const STIR_DEAD := 0.12
## The upright drag plane: x across, its normal towards the camera, its z down.
const UPRIGHT := Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
## The graph (자세히): the tray's water and salt crust against the days, a point every GRAPH_STEP days.
const GRAPH_STEP := 0.05
## The stage played on each table (0-based): SCALE from stage 2, TRAY from stage 3.
const SCALE_STAGE := 1
const TRAY_STAGE := 2

var props := DissolvingProps.new()
## The spoon's angle round the glass (rad: 0 right, PI/2 the front).
var spoon_angle := 0.0
var _last_angle := NAN          # the finger's angle the last stir step measured from (NAN: none yet)
var _site_due := -1.0           # a table to take at the next reset (a stage just cleared), -1 none
var _pour_x := NAN              # where the bucket was let go to pour (it pours there), NAN none
var _stir_surface: ManipSurface
var _pour_surface: ManipSurface
var _graph_key := Vector3.INF
var _graph_revision := 0
var _lines := {}


func _init() -> void:
	model = DissolvingModel.new()


func _build_world() -> void:
	props.build(self)
	add_knob(SPOON_ID, "SpoonKnob", SPOON_KNOB)
	add_knob(BUCKET_ID, "BucketKnob", BUCKET_KNOB)
	_make_surfaces(model.input("site"))
	game = DissolvingGame.new(self)
	add_child(game)
	game.build()


func _exit_tree() -> void:
	props.night.clear()   # the tint is global: never leave the night on


## The surfaces of table `site`: the stir plane over its glass, the pour line from its bucket's place.
func _make_surfaces(site: float) -> void:
	var middle := DissolvingProps.stir_center(site)
	_stir_surface = ManipSurface.new(Transform3D(UPRIGHT, Vector3(middle.x, middle.y, middle.z - SPOON_KNOB * 0.5)),
		Vector2(-STIR_REACH, -STIR_REACH), Vector2(STIR_REACH, STIR_REACH))
	var home := DissolvingProps.bucket_home(DissolvingModel.TRAY) + Vector3.UP * (DissolvingProps.BUCKET.z * 0.55 - BUCKET_KNOB * 0.5)
	_pour_surface = ManipSurface.new(Transform3D(Basis(), home), Vector2(0.0, 0.0), Vector2(BUCKET_REACH, 0.0))


# --- the table (the stage) ------------------------------------------------------------------------

## The stage changed: its table. A stage just cleared keeps its result until the next reset; opened or
## jumped to, the table is set at once.
func set_game_stage(stage: int, stamps: int, just_cleared: bool) -> void:
	super(stage, stamps, just_cleared)
	var site := site_of(stage)
	if just_cleared and model.input("site") != site:
		_site_due = site
	else:
		_set_site(site)


## The table of stage `stage` (-1: the round is done, the TRAY table).
static func site_of(stage: int) -> float:
	if stage < 0 or stage >= TRAY_STAGE:
		return DissolvingModel.TRAY
	return DissolvingModel.SCALE if stage >= SCALE_STAGE else DissolvingModel.CUP


## Table `site` from now on; a new table starts the run over.
func _set_site(site: float) -> void:
	_site_due = -1.0
	if site == model.input("site"):
		return
	(model as DissolvingModel).set_site(site)
	_make_surfaces(site)
	model.reset()
	_pour_x = NAN
	if is_inside_tree():
		_show()
	_update_status(true)


func reset_run() -> void:
	if _site_due >= 0.0:
		_set_site(_site_due)
	_pour_x = NAN
	_last_angle = NAN
	super()
	if game != null:
		game.run_reset()


# --- the hand -------------------------------------------------------------------------------------

## The table's object takes a finger: the spoon by the glass, the bucket until it has poured.
func offered(id: String) -> bool:
	var m := model as DissolvingModel
	if m.site() == DissolvingModel.TRAY:
		return id == BUCKET_ID and not m.poured()
	return id == SPOON_ID


func manipulation_body(id: String) -> PhysicsBody3D:
	return knobs.get(id) if offered(id) or holding == id else null


func manipulation_surface(surface_id: String) -> ManipSurface:
	return _stir_surface if surface_id == STIR_SURFACE else _pour_surface


## The spoon's knob sits at its handle (on the stir circle at its angle); the bucket's on the bucket at
## its place (home, or where it pours).
func _knob_pose(id: String) -> Transform3D:
	if id == SPOON_ID:
		return _stir_surface.pose(Vector2(cos(spoon_angle), sin(spoon_angle)) * DissolvingProps.STIR_RING, SPOON_KNOB * 0.5)
	var x := 0.0 if is_nan(_pour_x) else _pour_x - DissolvingProps.bucket_home(DissolvingModel.TRAY).x
	return _pour_surface.pose(Vector2(x, 0.0), BUCKET_KNOB * 0.5)


func manipulation_started(id: String) -> void:
	if id == SPOON_ID:
		_last_angle = spoon_angle   # (the knob rests on the stir circle at the spoon's angle)
	super(id)


## The spoon follows the finger's angle round the stir middle and stirs by the turn it made (either
## way); the bucket only moves (its place is read in _redraw).
func _knob_inputs(id: String, xf: Transform3D) -> Dictionary:
	if id != SPOON_ID or holding != SPOON_ID:
		return {}
	var p := _stir_surface.to_plane(xf.origin)
	if p.length() < STIR_DEAD:
		return {}
	var a := atan2(p.y, p.x)
	spoon_angle = a
	var turns := 0.0
	if not is_nan(_last_angle):
		turns = absf(wrapf(a - _last_angle, -PI, PI)) / TAU
	_last_angle = a
	if turns <= 0.0:
		return {}
	return {"stir": model.input("stir") + turns}


## Let go: the bucket over the tray pours there (and stands back home after); the spoon stays where it
## is round the glass (the knob goes back onto its handle).
func manipulation_placed(id: String, transform: Transform3D) -> void:
	if id == BUCKET_ID and DissolvingProps.over_tray(transform.origin.x):
		_pour_x = transform.origin.x
		(model as DissolvingModel).pour()
	_last_angle = NAN
	super(id, transform)


## The shell put the knob back where it was picked up: no stir for that jump (nothing follows a knob no
## finger holds).
func manipulation_cancelled(id: String) -> void:
	_last_angle = NAN
	super(id)


## Stirring and pouring are events, not places.
func placements() -> Dictionary:
	return {}


## Judged when no finger holds anything and the run has had its say: the glass as it is, or the tray
## dry (or drying long enough for Puppy's wait line, DissolvingModel.decided).
func settled() -> bool:
	return holding == "" and (not model.animating() or (model as DissolvingModel).decided())


func _process(delta: float) -> void:
	super(delta)
	props.advance(delta)
	# The pour plays out where the bucket was let go, then the bucket stands back home.
	if not is_nan(_pour_x) and not props.pouring():
		_pour_x = NAN
		_show()


# --- what the panels and the cast read ------------------------------------------------------------

func _redraw() -> void:
	var m := model as DissolvingModel
	var bucket_x := NAN
	if holding == BUCKET_ID:
		bucket_x = knobs[BUCKET_ID].global_position.x
	elif not is_nan(_pour_x):
		bucket_x = _pour_x
	props.show(m.site(), spoon_angle, m.bottom_g() / DissolvingModel.SPOON_G, m.dissolved_share(), m.scale_g(), DissolvingModel.before_g(),
		m.water_share(), m.crust(), m.poured(), bucket_x, m.clock)


## Words only (no number on the screen): the salt in the glass, the scale's needle, the tray.
func observations() -> Dictionary:
	var m := model as DissolvingModel
	var salt := Locale.t("dissolving.salt.bottom")
	if m.input("stir") > 0.0:
		salt = Locale.t("dissolving.salt.clear") if m.all_dissolved() else Locale.t("dissolving.salt.melting")
	var tray := Locale.t("dissolving.tray.empty")
	if m.poured():
		tray = Locale.t("dissolving.tray.salt") if m.dry() else (Locale.t("dissolving.tray.full") if m.clock.days < DissolvingModel.HINT_DAYS else Locale.t("dissolving.tray.drying"))
	return {
		"salt": salt,
		"scale": Locale.t("dissolving.scale.same"),
		"tray": tray,
	}


## The tray's water and its salt crust (% of the poured water, of all the salt) against the days since
## the pour, and where the run is now (자세히: the units are only there).
func graph_series() -> Dictionary:
	var m := model as DissolvingModel
	if _lines.is_empty():
		var probe := DissolvingModel.new()
		probe.set_site(DissolvingModel.TRAY)
		probe.pour()
		var water := PackedVector2Array()
		var crust := PackedVector2Array()
		var d := 0.0
		var end := DissolvingModel.dry_days()
		while d <= end + GRAPH_STEP:
			probe.clock.days = minf(d, end)
			water.append(Vector2(probe.clock.days, 100.0 * probe.water_share()))
			crust.append(Vector2(probe.clock.days, 100.0 * probe.crust()))
			d += GRAPH_STEP
		_lines = {"water": water, "crust": crust}
	var now := PackedVector2Array()
	if m.poured():
		now.append(Vector2(m.clock.days, 100.0 * m.water_share()))
	return {"water": _lines.water, "crust": _lines.crust, "now": now}


func graph_revision() -> int:
	var m := model as DissolvingModel
	var key := Vector3(snappedf(m.clock.days, 0.02), m.input("site"), m.input("poured"))
	if key != _graph_key:
		_graph_key = key
		_graph_revision += 1
	return _graph_revision


## Dugi points at the glass (stages 1-2) or the tray (stage 3).
func explain_point() -> Vector3:
	if model.input("site") == DissolvingModel.TRAY:
		return DissolvingProps.TRAY_AT + Vector3.UP * 0.3
	return props.cup.global_position + Vector3.UP * DissolvingProps.CUP_FILL * 0.5


## The camera follows the table's middle.
func follow_point() -> Vector3:
	return Vector3(0.0, KitchenSet.TABLE_TOP + 0.8, KitchenSet.TABLE_AT.z)
