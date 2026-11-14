## The curie island's corner emblem (#154, 2026-11-13 user pick B): the rainbow lighthouse's round
## lens the pieces make, cut into LensArt.PIECES (11) equal wedges, filled from the top clockwise as
## the pieces reach the lookout, each in its rainbow colour (LensArt.RAINBOW: the filled lens is a
## rainbow wheel) with a light glass ring and a deeper band along the rim; the others are pale paper.
## The middle stays an empty round spot: the lighthouse's flame, spot 12's piece (Island.flame_spot),
## which never flies (StoryDirector) and lights there once the lens is whole (set_whole: the island
## card after the finale now; the map's corner when the curie finale comes, #168); before, the pieces
## past the eleventh fill nothing more. Filling and pop: PieceEmblem. Pictures only.
class_name LensEmblem
extends PieceEmblem

const WEDGES := LensArt.PIECES
const HUB := 0.24                      # the flame's empty spot (share of the radius)
const FLAME_K := 0.62                  # the lit flame's scale in the hub (share of the hub: about 1.5 hubs tall)


func _init(count: int) -> void:
	super(count)
	name = "LensEmblem"


## The wedges filled now (the pieces past the eleventh are the flame's).
func wedges_filled() -> int:
	return mini(filled, WEDGES)


## Wedge `i`'s polygon (from the top, clockwise on screen), radius r about c, from `r0` outwards.
static func wedge(c: Vector2, r0: float, r: float, i: int) -> PackedVector2Array:
	return wedge_of(c, r0, r, i, WEDGES)


## The lit flame in 2D (y down) about `c`, `k` px from its middle to its foot: LensArt's teardrop with
## its yellow heart.
static func draw_flame(canvas: CanvasItem, c: Vector2, k: float) -> void:
	var to2d := func(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p: Vector2 in pts:
			out.append(c + Vector2(p.x, -p.y) * k)
		return out
	var flame := LensArt.flame_rim()
	canvas.draw_colored_polygon(to2d.call(SundialArt.outset(flame, 2.5 / k)), ArtPalette.OUTLINE)
	canvas.draw_colored_polygon(to2d.call(flame), LensArt.FLAME)
	var at := LensArt.FLAME_HEART_AT
	canvas.draw_colored_polygon(to2d.call(flame.map(func(p: Vector2) -> Vector2: return at + (p - at) * LensArt.FLAME_HEART_K)), LensArt.FLAME_HEART)


func _draw() -> void:
	var c := size * 0.5
	var r := SIZE * 0.5 - 4.0
	var line := ArtPalette.OUTLINE
	draw_circle(c, r + 4.0, line)
	draw_circle(c, r, PAPER)
	var hub := r * HUB
	var band := r * (1.0 - SundialArt.BAND * 0.8)
	var span := r - hub
	for i in WEDGES:
		if i < wedges_filled():
			var color: Color = LensArt.RAINBOW[i]
			draw_colored_polygon(wedge(c, hub, r, i), color)
			draw_colored_polygon(wedge(c, hub + span * LensArt.RING[0], hub + span * LensArt.RING[1], i), color.lerp(Color.WHITE, LensArt.RING_LIGHT))
			draw_colored_polygon(wedge(c, band, r, i), color.darkened(LensArt.BAND_DARK))
		else:
			draw_colored_polygon(wedge(c, hub, r, i), EMPTY)
	for i in WEDGES:
		var a := -PI * 0.5 + TAU * i / WEDGES
		draw_line(c + Vector2.from_angle(a) * hub, c + Vector2.from_angle(a) * r, Color(line, 0.55), 1.5, true)
	draw_arc(c, r, 0.0, TAU, 48, line, 3.0, true)
	draw_circle(c, hub, LensArt.FLAME_HEART.lerp(Color.WHITE, 0.4) if whole else PAPER)
	draw_arc(c, hub, 0.0, TAU, 24, line, 2.5, true)
	if whole:
		var k := hub * FLAME_K
		draw_flame(self, c + Vector2(0.0, 0.25 * k), k)   # (the teardrop's middle is 0.25 above its origin)
