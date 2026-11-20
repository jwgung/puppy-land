## The 깨끗한 물 만들기 spot's drawings (#160, 2026-11-18), called from PickPictures and PredictPictures: the
## filter buttons (a see-through column: empty, sand, or charcoal under sand, as the mockup's buttons) and the
## question's two pictures (a glass of the sand-filtered water drunk at once, or a pot of it boiling on a
## fire first). Drawn with the canvas's 2D calls (no textures, no words) in the storybook colours.
class_name CleanWaterPictures
extends RefCounted

const GLASS := Color("eaf6ff")
const GLASS_EDGE := Color("7c93a8")
const SAND := Color("e6c98a")
const COAL := Color("2e2b2b")
const WATER := Color("cfe9f8")
const FIRE := Color("ff7a1a")
const FIRE_HEART := Color("ffd43b")
const POT := Color("5b6270")
const OUTLINE := Color("8a6a46")


## The filter button's picture: a column (`kind` 0 empty, 1 sand, 2 charcoal under sand), filling `r`.
static func column(canvas: Control, r: Rect2, kind: int) -> void:
	var h := r.size.y * 0.86
	var w := minf(r.size.x * 0.34, h * 0.5)
	var body := Rect2(r.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))
	canvas.draw_rect(body, GLASS)
	var bottom := body.end.y - h * 0.12
	if kind >= 2:
		canvas.draw_rect(Rect2(body.position.x, bottom - h * 0.2, w, h * 0.2), COAL)
		bottom -= h * 0.2
	if kind >= 1:
		canvas.draw_rect(Rect2(body.position.x, bottom - h * 0.3, w, h * 0.3), SAND)
	canvas.draw_rect(Rect2(body.position.x, body.end.y - h * 0.12, w, h * 0.12), WATER)
	canvas.draw_rect(body, GLASS_EDGE, false, 2.0)


## The question's picture: muddy water through sand, an arrow, then a glass drunk at once (`boil` false)
## or a pot boiling on a fire. The result is the one the choice says (orange, thick), the column pale.
static func predict(canvas: Control, r: Rect2, boil: bool, strong: Color, pale: Color) -> void:
	canvas.draw_line(Vector2(r.position.x, r.end.y), r.end, OUTLINE, 3.0)
	var base := r.end.y - 2.0
	var left := Rect2(r.position.x + r.size.x * 0.14, base - r.size.y * 0.78, r.size.x * 0.16, r.size.y * 0.76)
	column(canvas, left, 1)
	canvas.draw_rect(left.grow(-left.size.x * 0.1), pale, false, 2.0)
	PredictPictures._arrow(canvas, Vector2(r.position.x + r.size.x * 0.4, base - r.size.y * 0.4), Vector2(r.position.x + r.size.x * 0.56, base - r.size.y * 0.4), pale, 3.0)
	var at := Vector2(r.position.x + r.size.x * 0.76, base)
	var s := r.size.y * 0.36
	if boil:
		var pot := Rect2(at + Vector2(-s * 0.8, -s * 1.45), Vector2(s * 1.6, s * 0.9))
		canvas.draw_rect(pot, POT)
		canvas.draw_rect(Rect2(pot.position, Vector2(pot.size.x, s * 0.14)), WATER)
		for k in 3:
			canvas.draw_circle(pot.position + Vector2(pot.size.x * (0.25 + 0.25 * k), -3.0 - 3.0 * (k % 2)), 3.0, Color.WHITE)
		for k in 3:
			var x := at.x + (k - 1) * s * 0.5
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - s * 0.2, base), Vector2(x, base - s * 0.55), Vector2(x + s * 0.2, base)]), FIRE)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - s * 0.1, base), Vector2(x, base - s * 0.3), Vector2(x + s * 0.1, base)]), FIRE_HEART)
		canvas.draw_rect(pot, strong, false, 4.0)
	else:
		var cup := PackedVector2Array([at + Vector2(-s * 0.5, -s * 1.5), at + Vector2(s * 0.5, -s * 1.5), at + Vector2(s * 0.38, 0.0), at + Vector2(-s * 0.38, 0.0)])
		canvas.draw_colored_polygon(cup, GLASS)
		canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-s * 0.46, -s * 1.1), at + Vector2(s * 0.46, -s * 1.1), at + Vector2(s * 0.38, 0.0), at + Vector2(-s * 0.38, 0.0)]), WATER)
		var outline := cup.duplicate()
		outline.append(cup[0])
		canvas.draw_polyline(outline, strong, 4.0, true)
