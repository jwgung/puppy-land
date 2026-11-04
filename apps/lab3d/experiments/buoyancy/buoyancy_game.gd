## The buoyancy's piece game (2026-11-02 user: the chest pulled up out of the water read oddly for
## finding a star piece; chosen: "통 뗏목으로 연못 건너기"): the star piece lies on a little rock islet
## at the far side of the pond, out of the bread cat's reach on its crates. The stages (one change a
## stage, the conditions as before): the small empty barrel floats, the same barrel with the cat on
## it sinks (that stage's goal: "sunk"), the big barrel floats with the cat. On the last stamp the
## cat hops onto the floating barrel and on to the islet, where the piece waits for its paws
## (piece_ready, like the push's walk).
## Visual only: the islet has no body and the cat no mass in the model (the mass slider is the
## barrel's whole load, the cat included); the barrel and every number are the model's as before.
class_name BuoyancyGame
extends LabGame

const FLOOR_Y := 0.2                     # the tank floor (BuoyancyLab FLOOR_Y)
const ROCK_AT := Vector2(0.95, 0.15)     # x, z of the islet in the tank (right of the barrel's way)
const ROCK_R := 0.24                     # its radius at the waterline
const ROCK_TOP := 1.66                   # its flat top (the waterline is 1.5)
const HOP_S := 0.55                      # s per hop (crates -> barrel, barrel -> islet)
const HOP_UP := 0.35                     # m the hop rises over the higher end
const WALK_AFTER := 0.6                  # s after the last stamp before the first hop
const ROCK_COLOR := Color("8f98a6")
const ROCK_LIGHT := Color("b8c0cc")

var _rock: MeshInstance3D
## The cat's crossing: "" (none), "pending" (after the last stamp), "hopping", "there".
var walk_state := ""
var _walk_after := 0.0
var _hop_t := 0.0
var _from := Vector3.ZERO


func build() -> void:
	_rock = ArtKit.instance(rock_mesh())
	_rock.name = "Islet"
	_rock.position = Vector3(ROCK_AT.x, FLOOR_Y, ROCK_AT.y)
	add_child(_rock)
	make_piece(piece_home(), PIECE_SIZE * 0.55)
	_jump(0)


## The islet: a stack of facetted stones from the tank floor up to a flat top above the water.
static func rock_mesh() -> Mesh:
	var b := ArtKit.builder()
	var h := ROCK_TOP - FLOOR_Y
	b.add_cylinder(Transform3D(Basis(), Vector3(0.0, 0.0, 0.0)), ROCK_R * 1.25, ROCK_R * 1.05, h * 0.55, 7, ROCK_COLOR)
	b.add_cylinder(Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.0, h * 0.55, 0.0)), ROCK_R * 1.05, ROCK_R * 0.9, h * 0.45 - 0.04, 7, ROCK_LIGHT)
	b.add_cylinder(Transform3D(Basis(Vector3.UP, 0.2), Vector3(0.0, h - 0.04, 0.0)), ROCK_R * 0.98, ROCK_R * 0.92, 0.04, 7, ArtPalette.MEADOW)   # a tuft of grass: an islet
	return b.commit()


## Where the piece waits: on the islet's top.
func piece_home() -> Vector3:
	return Vector3(ROCK_AT.x, ROCK_TOP + piece_size, ROCK_AT.y)


## Where the cat stands on the islet (its base) and on the barrel's lid (the load's top, live).
func islet_stand() -> Vector3:
	return Vector3(ROCK_AT.x - 0.05, ROCK_TOP, ROCK_AT.y - 0.18)


func barrel_stand() -> Vector3:
	var l: Variant = host()
	if l == null or l.drum == null:
		return Vector3(0.0, 1.6, 0.0)
	var at: Vector3 = l.drum.global_position
	var top: float = at.y + l.drum_height() * 0.5
	return Vector3(at.x, top, at.z - BuoyancyProps.LID_BACK)


func _cat() -> CatActor:
	var l: Variant = host()
	if l == null or not ("props" in l) or l.props == null:
		return null
	return l.props.cat


## The cat crosses (or will): the lab leaves its pose to the game meanwhile.
func cat_busy() -> bool:
	return walk_state != ""


func piece_ready() -> bool:
	return walk_state not in ["pending", "hopping"]


func _cleared(_stage_index: int, last: bool) -> void:
	SoundBoard.play(&"glint")
	if last:
		walk_state = "pending"
		_walk_after = _t + WALK_AFTER


func _jump(stamps: int) -> void:
	walk_state = ""
	if stamps < stages and piece != null and piece_state != "taken":
		piece.position = piece_home()
		set_piece_state("held")


## The run starts over: a crossing still to come or under way is over (the cat goes back to its
## crates: the lab poses it again).
func run_reset() -> void:
	super()
	if walk_state in ["pending", "hopping"]:
		walk_state = ""


func _process(delta: float) -> void:
	super(delta)
	match walk_state:
		"pending":
			var cat := _cat()
			if cat == null:
				_arrive()
			elif _t >= _walk_after:
				_from = cat.position
				# Riding the barrel already (2026-11-03): only the hop on to the islet.
				_hop_t = HOP_S if _from.distance_to(barrel_stand()) < 0.05 else 0.0
				walk_state = "hopping"
		"hopping":
			_hop_t += delta
			_step_cat()


## The cat at _hop_t along its two hops: crates -> the barrel's lid -> the islet (each an arc over
## the higher end; a cat riding the barrel makes only the second), facing where it goes; then it stands
## on the islet facing the camera.
func _step_cat() -> void:
	var cat := _cat()
	if cat == null:
		_arrive()
		return
	var hops := [_from, barrel_stand(), islet_stand()]
	var k := _hop_t / HOP_S
	var i := mini(int(k), 1)
	if k >= 2.0:
		cat.walk(hops[2], 0.0, 0.0)
		cat.mode = "free"
		_arrive()
		return
	var a: Vector3 = hops[i]
	var e: Vector3 = hops[i + 1]
	var f := clampf(k - i, 0.0, 1.0)
	var at := a.lerp(e, smooth(f))
	at.y = lerpf(a.y, e.y, f) + HOP_UP * sin(PI * f)
	cat.walk(at, CatActor.facing(a, e), 0.0)


func _arrive() -> void:
	walk_state = "there"
	if piece != null and piece_state == "held":
		_rest_at = piece.global_position   # it waits on the islet for the cat's paws (the screen hands it over)
		piece_state = "out"


## The clue's glow (LabGame.highlight): the piece on its islet.
func highlight_radius() -> float:
	return 0.45
