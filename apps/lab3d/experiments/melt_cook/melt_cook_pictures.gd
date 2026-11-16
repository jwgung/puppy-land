## The 되돌릴 수 있을까? spot's drawings (#158, 2026-11-17), called from PickPictures and PredictPictures:
## the item buttons (a bar of chocolate, an egg) and the question's two pictures (melted chocolate in a pot
## and what it becomes once it cools: a hard star, or still a puddle). Drawn with the canvas's 2D calls
## (no textures), in the storybook colours of the other pictures; the numbers and words come from them.
class_name MeltCookPictures
extends RefCounted

const CHOC := Color("5a2e14")
const CHOC_TOP := Color("7a4424")
const CHOC_MELT := Color("6b3a1e")
const CHOC_SHINE := Color("c58a5c")
const SHELL := Color("fbf2e2")
const POT := Color("8d97a3")
const POT_DARK := Color("5f6a76")
const OUTLINE := Color("8a6a46")


## The item button's picture: a bar of chocolate (`egg` false) or an egg, filling `r`.
static func item(canvas: Control, r: Rect2, egg: bool) -> void:
	var c := r.get_center()
	if egg:
		_egg(canvas, c, r.size.y * 0.36)
		return
	var w := minf(r.size.x * 0.62, r.size.y * 1.1)
	var h := w * 0.72
	var bar := Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))
	canvas.draw_rect(bar, CHOC)
	# Three by two squares, each a little lighter on its top left.
	for col in 3:
		for row in 2:
			var cell := Rect2(bar.position + Vector2(col * w / 3.0, row * h / 2.0), Vector2(w / 3.0, h / 2.0)).grow(-2.0)
			canvas.draw_rect(cell, CHOC_TOP)
			canvas.draw_rect(Rect2(cell.position, Vector2(cell.size.x, 3.0)), CHOC_SHINE)
	canvas.draw_rect(bar, OUTLINE, false, 2.0)
	# A corner of silver paper.
	canvas.draw_colored_polygon(PackedVector2Array([bar.position + Vector2(w, 0.0), bar.position + Vector2(w - w * 0.18, 0.0), bar.position + Vector2(w, h * 0.26)]), Color("e8edf2"))


## The question's picture: a pot of melted chocolate, an arrow, and what comes after it cools: a hard
## star (`sets`) or still a puddle. The result is the one the choice says (orange, thick), the pot pale.
static func predict(canvas: Control, r: Rect2, sets: bool, strong: Color, pale: Color) -> void:
	canvas.draw_line(Vector2(r.position.x, r.end.y), r.end, OUTLINE, 3.0)
	var base := r.end.y - 2.0
	var left := Vector2(r.position.x + r.size.x * 0.26, base)
	var right := Vector2(r.position.x + r.size.x * 0.76, base)
	_pot(canvas, left, r.size.y * 0.36, pale)
	PredictPictures._arrow(canvas, Vector2(r.position.x + r.size.x * 0.44, base - r.size.y * 0.3), Vector2(r.position.x + r.size.x * 0.6, base - r.size.y * 0.3), pale, 3.0)
	if sets:
		_star(canvas, right + Vector2(0.0, -r.size.y * 0.3), r.size.y * 0.3, strong)
	else:
		_puddle(canvas, right + Vector2(0.0, -r.size.y * 0.08), r.size.y * 0.3, strong)


## A pot (its foot at `at`, `size` tall) with melted chocolate and two wisps of steam.
static func _pot(canvas: Control, at: Vector2, size: float, edge: Color) -> void:
	var w := size * 1.5
	var body := Rect2(at + Vector2(-w * 0.5, -size * 0.8), Vector2(w, size * 0.8))
	canvas.draw_rect(body, POT)
	canvas.draw_rect(Rect2(body.position + Vector2(-size * 0.25, size * 0.15), Vector2(size * 0.25, size * 0.1)), POT_DARK)
	canvas.draw_rect(Rect2(body.position + Vector2(w, size * 0.15), Vector2(size * 0.25, size * 0.1)), POT_DARK)
	canvas.draw_rect(Rect2(body.position, Vector2(w, size * 0.14)), CHOC_MELT)
	canvas.draw_rect(Rect2(body.position + Vector2(w * 0.15, 2.0), Vector2(w * 0.3, 3.0)), CHOC_SHINE)
	canvas.draw_rect(body, edge, false, 2.0)
	for k in 2:
		var x := at.x + (k - 0.5) * w * 0.45
		var wisp := PackedVector2Array()
		for j in 8:
			var u := j / 7.0
			wisp.append(Vector2(x + 3.0 * sin(u * TAU), body.position.y - 3.0 - u * size * 0.5))
		canvas.draw_polyline(wisp, Color("c9d3dd"), 2.0, true)


## A hard star of chocolate (its middle at `c`, `radius` out to its points), edged in `edge`.
static func _star(canvas: Control, c: Vector2, radius: float, edge: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + PI * i / 5.0
		points.append(c + Vector2(cos(a), sin(a)) * radius * (1.0 if i % 2 == 0 else 0.45))
	canvas.draw_colored_polygon(points, CHOC)
	var inner := PackedVector2Array()
	for p in points:
		inner.append(c + (p - c) * 0.72)
	canvas.draw_colored_polygon(inner, CHOC_TOP)
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, edge, 4.0, true)


## A puddle of melted chocolate (its middle at `c`), shiny, edged in `edge`.
static func _puddle(canvas: Control, c: Vector2, radius: float, edge: Color) -> void:
	var points := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		points.append(c + Vector2(cos(a) * radius * 1.25, sin(a) * radius * 0.55))
	canvas.draw_colored_polygon(points, CHOC_MELT)
	canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-radius * 0.6, -radius * 0.15), c + Vector2(-radius * 0.1, -radius * 0.3), c + Vector2(-radius * 0.15, -radius * 0.1)]), CHOC_SHINE)
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, edge, 4.0, true)


static func _egg(canvas: Control, c: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(c + Vector2(cos(a) * radius * 0.82, sin(a) * radius * (1.12 if sin(a) < 0.0 else 1.0)))
	canvas.draw_colored_polygon(points, SHELL)
	canvas.draw_circle(c + Vector2(-radius * 0.28, -radius * 0.4), radius * 0.16, Color.WHITE)
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, Color("d6c3a3"), 3.0, true)
