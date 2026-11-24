## The hand guide (2026-10-30 user request: young children need a guide to the controls): the bread cat's
## front paw (2026-10-31 user choice, instead of a hand) over the 3D view shows the gesture the child
## should make on the real object, so no reading is needed. "Finger" below means the paw's tip.
## It is a picture only: it never presses, moves a body or changes a control.
##
## Gestures (play()):
## - "drag": the finger presses on `from`, carries it to `to` and lifts (끌었다 놓기),
## - "pull": the same, then a short arrow from `from` away from the pull shows where it flies (the slingshot),
## - "hold": the finger presses on `from` and stays while a ring fills (꾹 누르기),
## - "tap": the finger taps `from` (지도의 장소 누르기),
## - "stir": the finger presses on `from` and goes round `to` (the circle's middle) twice, a dotted ring
##   with an arrow showing the way round (#157: 숟가락으로 빙글빙글 젓기),
## - "tilt": a small tablet at the top middle of the view, two paws holding its sides, tips its left edge
##   down to TILT_DEG and back TILT_TIMES times (#160: 태블릿을 살살 기울이기); at the same time a fainter
##   paw drags the lab's touch stand-in from `from` to `to` (the same tilt by finger),
## - "pump": the finger presses on `from` and goes to `to` and back PUMP_TIMES times (#160: 풀무를 위아래로
##   펌프질).
## `from` and `to` are callables returning view points (UI units), read every frame, so the hand stays
## on the object while the camera eases. One play shows the gesture `cycles` times, then the hand goes.
class_name HandGuide
extends Control

const KINDS := ["drag", "pull", "hold", "tap", "stir", "tilt", "pump"]
const FADE_S := 0.25
const PRESS_S := 0.2
const MOVE_S := 1.0
const HOLD_S := 1.4
const LIFT_S := 0.25
const REST_S := 0.35
## A stir goes round this many times (in STIR_S) per cycle.
const STIR_TURNS := 2.0
const STIR_S := 2.0
## A tilt (#160): the tablet picture's size (UI units), where its middle is (shares of the view: the top
## middle, under the title band), how far it tips (deg) and how many times per cycle (in TILT_S); the
## stand-in paw's alpha.
const TABLET_SIZE := Vector2(132.0, 86.0)
const TABLET_AT := Vector2(0.5, 0.24)
const TILT_DEG := 20.0
const TILT_TIMES := 2.0
const TILT_S := 2.4
const FAINT := 0.45
const TABLET_EDGE := Color("2f2a33")
const TABLET_GLASS := Color("bfe3ff")
## A pump (#160): down and up this many times in PUMP_S.
const PUMP_TIMES := 3.0
const PUMP_S := 1.8
## The picture: the bread cat's front paw (tools/render_guide_paw.gd makes it from the
## cat's model), one image so its see-through is even. PAW_TIP is the touch point in it: the middle of the
## paw's white tip.
const PAW_TEXTURE: Texture2D = preload("res://assets/ui/guide_paw.png")
const PAW_SIZE := Vector2(54.8, 70.0)       # UI units (the 188 x 240 px picture)
const PAW_TIP := PAW_SIZE * Vector2(0.5, 0.355)
const PRESS_SCALE := 0.88     # the hand a little smaller while pressing (it "goes into" the glass)
const RING_RADIUS := 26.0
const ARROW_LENGTH := 70.0
const PAW_TINT := Color(1.0, 1.0, 1.0, 0.85)   # white: the picture's own colours, at 85 % (the object shows through)
const RING := Color(1.0, 0.85, 0.3, 0.95)
const TRAIL := Color(1.0, 1.0, 1.0, 0.55)
## Where a caller's point goes when it cannot be drawn (behind the camera, off the map): far off the view.
const OFF_VIEW := Vector2(-10000.0, -10000.0)

## The gesture shown now ("" when none).
var kind := ""
## The fingertip on the view now (UI units; tests).
var tip := Vector2.ZERO
## Gestures shown so far (tests).
var plays := 0
var _from := Callable()
var _to := Callable()
var _cycles := 0
var _t := 0.0


func _init() -> void:
	name = "HandGuide"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


## Shows `gesture` (KINDS) `cycles` times. `to` is needed for "drag", "pull", "stir", "tilt" and "pump".
func play(gesture: String, from: Callable, to := Callable(), cycles := 2) -> void:
	if gesture not in KINDS or not from.is_valid() or (gesture in ["drag", "pull", "stir", "tilt", "pump"] and not to.is_valid()):
		return
	kind = gesture
	_from = from
	_to = to
	_cycles = maxi(1, cycles)
	_t = 0.0
	plays += 1
	visible = true
	_place()


## The hand goes at once (a touch, a question, the sidebar).
func stop() -> void:
	kind = ""
	visible = false
	queue_redraw()


func playing() -> bool:
	return kind != ""


## One cycle's length (s).
func cycle_s() -> float:
	match kind:
		"drag", "pull":
			return FADE_S + PRESS_S + MOVE_S + LIFT_S + FADE_S + REST_S
		"stir":
			return FADE_S + PRESS_S + STIR_S + LIFT_S + FADE_S + REST_S
		"tilt":
			return FADE_S + PRESS_S + TILT_S + LIFT_S + FADE_S + REST_S
		"pump":
			return FADE_S + PRESS_S + PUMP_S + LIFT_S + FADE_S + REST_S
		"hold":
			return FADE_S + PRESS_S + HOLD_S + LIFT_S + FADE_S + REST_S
	return FADE_S + PRESS_S + LIFT_S + FADE_S + REST_S


func _process(delta: float) -> void:
	step(delta)


## Advances the gesture (tests call it directly).
func step(delta: float) -> void:
	if kind == "":
		return
	_t += delta
	if _t >= cycle_s() * _cycles:
		stop()
		return
	_place()


## Where the hand is in its cycle: [fingertip, alpha, pressed 0..1, progress of the hold or move 0..1].
func _pose() -> Array:
	var c := fmod(_t, cycle_s())
	var start: Vector2 = _from.call()
	var goal: Vector2 = _to.call() if _to.is_valid() else start
	var moves := kind in ["drag", "pull"]
	var middle := _middle_s()
	var marks: Array[float] = [FADE_S, FADE_S + PRESS_S, FADE_S + PRESS_S + middle, FADE_S + PRESS_S + middle + LIFT_S,
		FADE_S + PRESS_S + middle + LIFT_S + FADE_S]
	if c < marks[0]:
		return [start + Vector2(0.0, 10.0 * (1.0 - c / FADE_S)), c / FADE_S, 0.0, 0.0]
	if c < marks[1]:
		return [start, 1.0, (c - marks[0]) / PRESS_S, 0.0]
	if c < marks[2]:
		var k: float = (c - marks[1]) / middle
		var eased := k * k * (3.0 - 2.0 * k)
		if kind == "stir":
			return [stir_point(start, goal, k), 1.0, 1.0, k]
		if kind == "tilt":
			return [start.lerp(goal, tilt_share(k)), 1.0, 1.0, k]
		if kind == "pump":
			return [start.lerp(goal, pump_share(k)), 1.0, 1.0, k]
		return [start.lerp(goal, eased) if moves else start, 1.0, 1.0, k]
	var end := goal if moves else start
	if c < marks[3]:
		return [end, 1.0, 1.0 - (c - marks[2]) / LIFT_S, 1.0]
	if c < marks[4]:
		return [end + Vector2(0.0, 10.0 * (c - marks[3]) / FADE_S), 1.0 - (c - marks[3]) / FADE_S, 0.0, 1.0]
	return [end, 0.0, 0.0, 1.0]


## How long the gesture's middle part takes (s): the move, the hold, the stir, the tilts, the pumps.
func _middle_s() -> float:
	match kind:
		"drag", "pull":
			return MOVE_S
		"hold":
			return HOLD_S
		"stir":
			return STIR_S
		"tilt":
			return TILT_S
		"pump":
			return PUMP_S
	return 0.0


## How far a tilt is at `k` (0..1 of its middle part): 0 level .. 1 tipped, TILT_TIMES there and back.
static func tilt_share(k: float) -> float:
	return 0.5 - 0.5 * cos(TAU * TILT_TIMES * clampf(k, 0.0, 1.0))


## How far down a pump is at `k` (0..1 of its middle part): 0 up .. 1 down, PUMP_TIMES down and up.
static func pump_share(k: float) -> float:
	return 0.5 - 0.5 * cos(TAU * PUMP_TIMES * clampf(k, 0.0, 1.0))


## The tablet picture's middle on the view (UI units).
func tablet_center() -> Vector2:
	return size * TABLET_AT


## Where a stir's finger is at `k` (0..1 of its move) going round `middle` from `start` (STIR_TURNS
## times, the way a clock's hands go on the screen: down the front of the glass from its right side).
static func stir_point(start: Vector2, middle: Vector2, k: float) -> Vector2:
	var arm := start - middle
	return middle + arm.rotated(TAU * STIR_TURNS * k)


func _place() -> void:
	var pose := _pose()
	tip = pose[0]
	modulate.a = clampf(pose[1], 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if kind == "":
		return
	var pose := _pose()
	var start: Vector2 = _from.call()
	var pressed: float = pose[2]
	var progress: float = pose[3]
	if kind in ["drag", "pull"] and _to.is_valid():
		var goal: Vector2 = _to.call()
		_dotted(start, goal, TRAIL)
		if kind == "pull" and progress >= 1.0:
			# Where the throw goes: away from the pull.
			var away := (start - goal).normalized() * ARROW_LENGTH
			_arrow(start, start + away)
	if kind == "stir" and _to.is_valid():
		var middle: Vector2 = _to.call()
		var radius := start.distance_to(middle)
		var n := maxi(12, int(TAU * radius / 14.0))
		for i in n:
			draw_circle(middle + (start - middle).rotated(TAU * i / n), 3.0, TRAIL)
		var ahead := stir_point(start, middle, 0.08)
		_arrow(stir_point(start, middle, 0.02), ahead)
	if kind == "tilt":
		_tablet(tilt_share(progress) if pressed >= 1.0 and progress < 1.0 else 0.0)
		if _to.is_valid():
			_dotted(start, _to.call(), Color(TRAIL, TRAIL.a * FAINT))
		draw_texture_rect(PAW_TEXTURE, Rect2(pose[0] - PAW_TIP, PAW_SIZE), false, Color(PAW_TINT, PAW_TINT.a * FAINT))
		return
	if kind == "pump" and _to.is_valid():
		_dotted(start, _to.call(), TRAIL)
	if kind == "hold" and pressed > 0.0:
		draw_arc(start, RING_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * progress, 32, RING, 6.0, true)
	if pressed > 0.0 and kind != "hold":
		draw_arc(pose[0], RING_RADIUS * (0.6 + 0.4 * pressed), 0.0, TAU, 32, Color(RING, 0.6 * pressed), 3.0, true)
	_hand(pose[0], lerpf(1.0, PRESS_SCALE, pressed))


## The tablet picture tipped `share` of TILT_DEG (its left edge down), a paw on each side holding it.
func _tablet(share: float) -> void:
	var c := tablet_center()
	var a := -deg_to_rad(TILT_DEG) * share
	draw_set_transform(c, a, Vector2.ONE)
	var body := Rect2(-TABLET_SIZE * 0.5, TABLET_SIZE)
	draw_rect(body, TABLET_EDGE)
	draw_rect(body.grow(-8.0), TABLET_GLASS)
	for side: float in [-1.0, 1.0]:
		var tip := Vector2(side * (TABLET_SIZE.x * 0.5 + 4.0), 6.0)
		draw_set_transform(c + tip.rotated(a), a + side * PI * 0.5, Vector2.ONE * 0.8)
		draw_texture_rect(PAW_TEXTURE, Rect2(-PAW_TIP, PAW_SIZE), false, PAW_TINT)
		draw_set_transform(c, a, Vector2.ONE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The paw with its tip at `at` (the touch point), a little smaller while pressing.
func _hand(at: Vector2, scale_k: float) -> void:
	draw_texture_rect(PAW_TEXTURE, Rect2(at - PAW_TIP * scale_k, PAW_SIZE * scale_k), false, PAW_TINT)


func _dotted(a: Vector2, b: Vector2, color: Color) -> void:
	var length := a.distance_to(b)
	if length < 1.0:
		return
	var n := int(length / 14.0)
	for i in n + 1:
		draw_circle(a.lerp(b, float(i) / maxf(1.0, float(n))), 3.0, color)


func _arrow(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, RING, 6.0, true)
	var d := (b - a).normalized()
	var side := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([b + d * 12.0, b - d * 6.0 + side * 10.0, b - d * 6.0 - side * 10.0]), RING)
