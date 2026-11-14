## The map corner's emblem of the pieces found on an island (the story "별 조각 찾기"; PieceArt picks
## the island's): one wedge per piece fills as the pieces reach the lookout, and a newly filled wedge
## pops (a short bounce of the whole emblem). StarEmblem (the guiding star, the mechanics island),
## SundialEmblem (the sundial's dial, the hutton island, #101) and LensEmblem (the rainbow lighthouse's
## lens, the curie island, #154) draw it. Pictures only, no number and no words; 2D shapes only (one
## canvas item); it takes no touch.
class_name PieceEmblem
extends Control

const SIZE := 104.0
const PAPER := Color("fff6e6")        # UiTheme.DIALOGUE_PAPER
const EMPTY := Color("f1e2c0")
const POP_S := 0.45

var total := 11
var filled := 0
## The last piece is in its middle (set_whole: the sundial's gnomon #106, the lens's flame #154): after
## the finale. The star's emblem draws no middle.
var whole := false
var _pop := -1.0


func _init(count: int) -> void:
	total = count
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = custom_minimum_size
	pivot_offset = size * 0.5


## Shows `count` pieces at the lookout; `pop` when one just arrived.
func set_filled(count: int, pop := false) -> void:
	filled = clampi(count, 0, total)
	if pop:
		_pop = 0.0
		set_process(true)
	queue_redraw()


## Wedge `i` of `count` (from the top, clockwise on screen), radius r about c, from `r0` outwards (the
## sundial's dial and the lens cut their disc so).
static func wedge_of(c: Vector2, r0: float, r: float, i: int, count: int) -> PackedVector2Array:
	var steps := 8
	var a0 := -PI * 0.5 + TAU * i / count
	var a1 := -PI * 0.5 + TAU * (i + 1) / count
	var poly := PackedVector2Array()
	for s in steps + 1:
		poly.append(c + Vector2.from_angle(lerpf(a0, a1, float(s) / steps)) * r)
	for s in range(steps, -1, -1):
		poly.append(c + Vector2.from_angle(lerpf(a0, a1, float(s) / steps)) * r0)
	return poly


## The emblem is whole (every piece in, its middle drawn): after the island's finale.
func set_whole(on: bool) -> void:
	whole = on
	if on:
		filled = total
	queue_redraw()


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_pop += delta
	var k := clampf(_pop / POP_S, 0.0, 1.0)
	scale = Vector2.ONE * (1.0 + 0.35 * sin(PI * k) * (1.0 - k * 0.5))
	if k >= 1.0:
		scale = Vector2.ONE
		set_process(false)
