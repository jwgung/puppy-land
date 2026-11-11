## Fireworks over the view when an island's mission is complete (#118, 2026-11-11 user: "섬 미션 완성을
## 알리는 좀 더 이펙트도 추가해주고"): BURSTS bursts in the upper part of the view, one after another
## (BURST_GAP_S), each SPARKS sparks flying out from its middle, falling a little and fading over
## SPARK_S, in Confetti's toy colours; then the node frees itself. 2D only (one canvas item, small
## circles: no particles, no 3D), it never takes a touch. The same bursts every time (seeded).
class_name Fireworks
extends Control

const BURSTS := 6
const SPARKS := 22
const BURST_GAP_S := 0.42
const SPARK_S := 1.25
const SPEED := 260.0             # UI units per second a spark leaves its burst with
const FALL := 140.0              # UI units per second squared it falls
const RADIUS := 5.0

var t := 0.0
var _bursts: Array = []   # [x share, y share, start s, colour]


func _init() -> void:
	name = "Fireworks"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261111
	for i in BURSTS:
		_bursts.append([rng.randf_range(0.18, 0.82), rng.randf_range(0.14, 0.42), i * BURST_GAP_S, Confetti.COLORS[(i * 3) % Confetti.COLORS.size()]])


func _ready() -> void:
	SoundBoard.play(&"glint")


func _process(delta: float) -> void:
	advance(delta)


## The time `delta` on (tests step it); each burst's sound as it starts; freed after the last.
func advance(delta: float) -> void:
	var before := t
	t += delta
	for burst in _bursts:
		if before < float(burst[2]) and t >= float(burst[2]) and burst[2] > 0.0:
			SoundBoard.play(&"glint")
	if t >= life():
		queue_free()
		return
	queue_redraw()


## How long it shows (s): the last burst's start and its sparks' fade.
static func life() -> float:
	return (BURSTS - 1) * BURST_GAP_S + SPARK_S


func _draw() -> void:
	for burst in _bursts:
		var age := t - float(burst[2])
		if age < 0.0 or age > SPARK_S:
			continue
		var middle := Vector2(size.x * float(burst[0]), size.y * float(burst[1]))
		var fade := 1.0 - age / SPARK_S
		var color: Color = burst[3]
		for s in SPARKS:
			var dir := Vector2.from_angle(TAU * s / SPARKS + float(burst[0]) * 7.0)
			var at := middle + dir * SPEED * age * (1.0 - 0.35 * age) + Vector2.DOWN * FALL * age * age
			draw_circle(at, RADIUS * (0.6 + 0.4 * fade), Color(color, fade))
			draw_circle(middle + (at - middle) * 0.82, RADIUS * 0.5 * fade, Color(Color.WHITE, fade * 0.8))
