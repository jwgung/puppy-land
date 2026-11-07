## The hutton island's corner emblem (#101, 2026-11-07): the round sundial dial the pieces make, cut
## into WEDGES equal wedges (36° each, the wedge SundialArt draws). Spots 1–10 each give one wedge,
## filled from the top clockwise in the order the pieces reach the square (golden face, the deeper
## golden band along the rim, an hour line); the others are pale paper. The middle stays an empty
## round spot: the gnomon (해시계 바늘) of spot 11, the volcano, goes there later (not built yet, so a
## piece past the tenth fills nothing more). Filling and pop: PieceEmblem. Pictures only.
class_name SundialEmblem
extends PieceEmblem

const WEDGES := SundialArt.WEDGES
const HUB := 0.2                       # the gnomon's empty spot (share of the radius)
const FILL_LIGHT := Color("ffe08a")    # every other filled wedge, a touch lighter

func _init(count: int) -> void:
	super(count)
	name = "SundialEmblem"


## The wedges filled now (the pieces past the tenth are the gnomon's).
func wedges_filled() -> int:
	return mini(filled, WEDGES)


## Wedge `i`'s polygon (from the top, clockwise on screen), radius r about c, from `r0` outwards.
static func wedge(c: Vector2, r0: float, r: float, i: int) -> PackedVector2Array:
	var steps := 8
	var a0 := -PI * 0.5 + TAU * i / WEDGES
	var a1 := -PI * 0.5 + TAU * (i + 1) / WEDGES
	var poly := PackedVector2Array()
	for s in steps + 1:
		var a := lerpf(a0, a1, float(s) / steps)
		poly.append(c + Vector2(cos(a), sin(a)) * r)
	for s in range(steps, -1, -1):
		var a := lerpf(a0, a1, float(s) / steps)
		poly.append(c + Vector2(cos(a), sin(a)) * r0)
	return poly


func _draw() -> void:
	var c := size * 0.5
	var r := SIZE * 0.5 - 4.0
	var line := ArtPalette.OUTLINE
	draw_circle(c, r + 4.0, line)
	draw_circle(c, r, PAPER)
	var hub := r * HUB
	var band := r * (1.0 - SundialArt.BAND)
	for i in WEDGES:
		if i < wedges_filled():
			draw_colored_polygon(wedge(c, hub, r, i), SundialArt.FACE if i % 2 == 0 else FILL_LIGHT)
			draw_colored_polygon(wedge(c, band, r, i), SundialArt.RIM)
			var mid := -PI * 0.5 + TAU * (i + 0.5) / WEDGES
			var dir := Vector2(cos(mid), sin(mid))
			draw_line(c + dir * (hub + r * 0.12), c + dir * (band - 2.0), SundialArt.LINE, 2.0, true)
		else:
			draw_colored_polygon(wedge(c, hub, r, i), EMPTY)
	for i in WEDGES:
		var a := -PI * 0.5 + TAU * i / WEDGES
		draw_line(c + Vector2(cos(a), sin(a)) * hub, c + Vector2(cos(a), sin(a)) * r, Color(line, 0.55), 1.5, true)
	draw_arc(c, r, 0.0, TAU, 48, line, 3.0, true)
	# The gnomon's spot: an empty round middle with its own ring.
	draw_circle(c, hub, PAPER)
	draw_arc(c, hub, 0.0, TAU, 24, line, 2.5, true)
