## The map corner's emblem of the pieces found on an island (the story "별 조각 찾기"; PieceArt picks
## the island's): one wedge per piece fills as the pieces reach the lookout, and a newly filled wedge
## pops (a short bounce of the whole emblem). StarEmblem (the guiding star, the mechanics island) and
## SundialEmblem (the sundial's dial, the hutton island, #101) draw it. Pictures only, no number and
## no words; 2D shapes only (one canvas item); it takes no touch.
class_name PieceEmblem
extends Control

const SIZE := 104.0
const PAPER := Color("fff6e6")        # UiTheme.DIALOGUE_PAPER
const EMPTY := Color("f1e2c0")
const POP_S := 0.45

var total := 11
var filled := 0
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


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_pop += delta
	var k := clampf(_pop / POP_S, 0.0, 1.0)
	scale = Vector2.ONE * (1.0 + 0.35 * sin(PI * k) * (1.0 - k * 0.5))
	if k >= 1.0:
		scale = Vector2.ONE
		set_process(false)
