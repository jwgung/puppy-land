## The drawings of the mission's picture buttons (ConditionPicks): one small picture per setting,
## drawn with the canvas's 2D calls (no textures, nothing downloaded), in the storybook colours of
## the prediction pictures (PredictPictures) and the labs' own toy colours (ArtPalette): the earth,
## the moon and Jupiter, a light or a heavy box, a steel, wooden or rubber slide, a planet near or far
## from its star, a gentle or a steep slope, one, two or four ropes, the hand near or far on the lever,
## a small or a big ball (blue, orange, the free fall's red), a big or a small drum, a weight, a short
## or a long string, a short or a long stick (#86), the Earth with its axis tilted or upright (#87), a weak
## or a strong sun (#91), a humid or a dry day's air (#92), a cold, warm or very warm sea (#94).
## `size` (0..1) and `count` say how much the drawing shows (kid.picks entries). The words under the
## picture say the same thing.
## A mass's picture (a ball, a box, a weight) is drawn like the lab draws the body (2026-10-28,
## MassLook): `size` is its share of the biggest one, the cube root of the mass over the lab's
## heaviest button (tests/easy_controls_checks.gd checks the definitions), so equal masses draw equal
## and a heavier one bigger in the same proportion as in 3D.
class_name PickPictures
extends RefCounted

const KINDS := ["earth", "moon", "jupiter", "box", "slide_steel", "slide_wood", "slide_rubber", "orbit",
	"slope", "pulley", "lever", "ball_blue", "ball_orange", "ball_red", "drum_big", "drum_small", "weight", "rope",
	"stick", "earth_tilted", "earth_upright", "sun_weak", "sun_strong", "air_humid", "air_dry",
	"coast_day", "coast_night", "sea_cold", "sea_warm", "sea_hot"]
const OUTLINE := Color("8a6a46")   # PredictPictures.GROUND: the brown of the storybook lines
const STEEL := ArtPalette.STEEL


## Draws `kind` filling `canvas` (an unknown kind draws nothing).
static func draw(canvas: Control, kind: String, size := 0.5, count := 1) -> void:
	var r := Rect2(Vector2.ZERO, canvas.size).grow(-4.0)
	var c := r.get_center()
	match kind:
		"earth":
			canvas.draw_circle(c, r.size.y * 0.45, ArtPalette.SEA)
			for blob in [[Vector2(-8, -6), 9.0], [Vector2(9, 6), 8.0], [Vector2(-3, 11), 5.0]]:
				canvas.draw_circle(c + blob[0], blob[1], ArtPalette.GRASS)
			canvas.draw_arc(c, r.size.y * 0.45, 0.0, TAU, 32, OUTLINE, 2.0, true)
		"air_humid", "air_dry":   # #92: a humid day's air full of vapour, a dry day's with little
			_air(canvas, r, kind == "air_humid")
		"earth_tilted", "earth_upright":   # #87: the Earth with its axis leaning or straight
			_earth_axis(canvas, r, SunModel.EARTH_TILT if kind == "earth_tilted" else SunModel.UPRIGHT)
		"sea_cold", "sea_warm", "sea_hot":   # #94: the sea's warmth
			_sea(canvas, r, ["sea_cold", "sea_warm", "sea_hot"].find(kind))
		"moon":
			canvas.draw_circle(c, r.size.y * 0.32, Color("d9dbe2"))
			for crater in [[Vector2(-6, -4), 4.0], [Vector2(6, 5), 3.0], [Vector2(3, -8), 2.5]]:
				canvas.draw_circle(c + crater[0], crater[1], Color("aeb3c0"))
			canvas.draw_arc(c, r.size.y * 0.32, 0.0, TAU, 32, OUTLINE, 2.0, true)
		"jupiter":
			var radius := r.size.y * 0.5
			canvas.draw_circle(c, radius, Color("e8b77d"))
			for band in [-0.45, 0.0, 0.45]:   # stripes as chords of the disc
				var y: float = band * radius
				var half := sqrt(maxf(0.0, radius * radius - y * y)) - 1.0
				canvas.draw_line(c + Vector2(-half, y), c + Vector2(half, y), Color("b9784a"), 4.0, true)
			canvas.draw_circle(c + Vector2(radius * 0.35, radius * 0.25), 3.5, Color("c4573a"))
			canvas.draw_arc(c, radius, 0.0, TAU, 32, OUTLINE, 2.0, true)
		"box":
			_ground(canvas, r)
			var side := (r.size.y - 4.0) * size
			var box := Rect2(c.x - side * 0.5, r.end.y - side, side, side)
			canvas.draw_rect(box, ArtPalette.ORANGE)
			canvas.draw_rect(box, OUTLINE, false, 2.0)
			canvas.draw_line(Vector2(box.position.x, box.position.y + side * 0.3), Vector2(box.end.x, box.position.y + side * 0.3), Color("ffffff", 0.7), 2.0)
		"slide_steel", "slide_wood", "slide_rubber":
			_slide(canvas, r, kind)
		"slope":   # size 1 = 45°, the angle slider's end
			_ground(canvas, r)
			var foot := Vector2(r.end.x - 4.0, r.end.y)
			var run := r.size.x - 10.0
			var top := foot + Vector2(-run, -minf(run * tan(size * PI / 4.0), r.size.y - 4.0))
			canvas.draw_colored_polygon(PackedVector2Array([top, foot, Vector2(top.x, foot.y)]), ArtPalette.YELLOW)
			canvas.draw_line(top, foot, OUTLINE, 2.0, true)
			canvas.draw_line(top, Vector2(top.x, foot.y), OUTLINE, 2.0, true)
		"orbit":
			var star := Vector2(r.position.x + 16.0, c.y)
			canvas.draw_circle(star, 11.0, ArtPalette.YELLOW)
			var d := lerpf(26.0, r.size.x - 22.0, size)
			canvas.draw_arc(star, d, -0.55, 0.55, 12, Color(OUTLINE, 0.6), 2.0, true)
			canvas.draw_circle(star + Vector2(d, 0.0), 7.0, ArtPalette.BLUE)
		"pulley":
			var beam := r.position.y + 2.0
			canvas.draw_line(Vector2(r.position.x + 10.0, beam), Vector2(r.end.x - 10.0, beam), OUTLINE, 4.0)
			var box_y := r.end.y - 18.0
			var span := 34.0
			for i in count:
				var x := c.x if count == 1 else c.x - span * 0.5 + span * i / (count - 1.0)
				canvas.draw_line(Vector2(x, beam), Vector2(x, box_y), ArtPalette.RED if i == 0 else Color("ffffff"), 3.0)
				canvas.draw_line(Vector2(x, beam), Vector2(x, box_y), OUTLINE, 1.0)
			canvas.draw_rect(Rect2(c.x - 22.0, box_y, 44.0, 18.0), Color("5b4636"))
		"lever":
			_ground(canvas, r)
			var y := r.end.y - 20.0
			var left := r.position.x + 4.0
			canvas.draw_line(Vector2(left, y), Vector2(r.end.x - 4.0, y), ArtPalette.YELLOW, 6.0)
			var pivot := left + r.size.x * 0.32
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(pivot, y + 3.0), Vector2(pivot - 9.0, r.end.y), Vector2(pivot + 9.0, r.end.y)]), ArtPalette.BLUE)
			canvas.draw_rect(Rect2(left + 2.0, y - 18.0, 18.0, 15.0), ArtPalette.ORANGE)
			var grip := lerpf(pivot + 10.0, r.end.x - 8.0, size)
			canvas.draw_line(Vector2(grip, y - 4.0), Vector2(grip, r.position.y + 6.0), Color("ffffff"), 3.0)
			canvas.draw_circle(Vector2(grip, r.position.y + 8.0), 7.0, ArtPalette.RED)
			_arrow(canvas, Vector2(grip + 12.0, r.position.y + 4.0), Vector2(grip + 12.0, y - 10.0), ArtPalette.RED, 3.0)
		"ball_blue", "ball_orange", "ball_red":
			_ground(canvas, r)
			var radius := (r.size.y * 0.5 - 2.0) * size
			var at := Vector2(c.x, r.end.y - radius - 1.0)
			canvas.draw_circle(at, radius, {"ball_blue": ArtPalette.BLUE, "ball_orange": ArtPalette.ORANGE, "ball_red": ArtPalette.RED}[kind])
			canvas.draw_arc(at, radius, 0.0, TAU, 24, OUTLINE, 2.0, true)
			canvas.draw_arc(at, radius * 0.6, -2.4, -1.2, 8, Color("ffffff", 0.8), 2.0, true)
		"drum_big", "drum_small":
			var water := r.position.y + r.size.y * 0.55
			canvas.draw_rect(Rect2(r.position.x, water, r.size.x, r.end.y - water), Color("7fb8e0"))
			var drum := Vector2(46.0, 40.0) if kind == "drum_big" else Vector2(28.0, 28.0)
			var rect := Rect2(c.x - drum.x * 0.5, water - drum.y * 0.5, drum.x, drum.y)
			canvas.draw_rect(rect, ArtPalette.ORANGE)
			canvas.draw_line(Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y), Color("ffffff"), 3.0)
			canvas.draw_rect(rect, OUTLINE, false, 2.0)
			canvas.draw_line(Vector2(r.position.x, water), Vector2(r.end.x, water), Color("4f86b3"), 2.0)
		"weight":
			_ground(canvas, r)
			var w := r.size.y * 0.95 * size
			var h := w * 0.75
			var foot := r.end.y
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(c.x - w * 0.5, foot), Vector2(c.x + w * 0.5, foot),
				Vector2(c.x + w * 0.35, foot - h), Vector2(c.x - w * 0.35, foot - h)]), ArtPalette.IRON)
			canvas.draw_arc(Vector2(c.x, foot - h), w * 0.22, PI, TAU, 10, ArtPalette.IRON, 4.0, true)
		"rope":
			var top := Vector2(c.x, r.position.y + 2.0)
			canvas.draw_line(top + Vector2(-26.0, 0.0), top + Vector2(26.0, 0.0), OUTLINE, 4.0)
			var bob := top + Vector2(0.0, lerpf(14.0, r.size.y - 9.0, size)).rotated(-0.35)
			canvas.draw_line(top, bob, Color("ffffff"), 3.0)
			canvas.draw_line(top, bob, OUTLINE, 1.0)
			canvas.draw_circle(bob, 8.0, ArtPalette.BLUE)
		"sun_weak", "sun_strong":   # #91 (물의 여행): a small pale sun with short rays, or a big deep one with long rays
			_sun(canvas, c, r.size.y, kind == "sun_strong")
		"coast_day", "coast_night":   # #93 (바닷바람): the coast under the sun, or under the moon and stars
			_coast(canvas, r, kind == "coast_night")
		"stick":   # #86 (그림자 시계): the yard's stick, `size` of the picture's height (short / long)
			_ground(canvas, r)
			var foot := Vector2(c.x, r.end.y - 2.0)
			var top := foot - Vector2(0.0, lerpf(10.0, r.size.y - 10.0, size))
			canvas.draw_line(foot, top, ArtPalette.WOOD_GRAIN, 7.0, true)
			canvas.draw_line(foot, top, ArtPalette.WOOD, 4.0, true)
			canvas.draw_circle(top, 6.0, ArtPalette.RED)


## The sun at `c` in a picture `height` tall: weak (small, pale, eight short rays) or strong (big,
## deep yellow, twelve long orange rays).
static func _sun(canvas: Control, c: Vector2, height: float, strong: bool) -> void:
	var radius := height * (0.24 if strong else 0.17)
	var rays := 12 if strong else 8
	var reach := radius * (0.85 if strong else 0.4)
	for k in rays:
		var d := Vector2.from_angle(TAU * k / rays)
		canvas.draw_line(c + d * (radius + 3.0), c + d * (radius + 3.0 + reach * (1.0 if k % 2 == 0 else 0.7)), ArtPalette.ORANGE if strong else ArtPalette.YELLOW_TOP, 4.0 if strong else 3.0, true)
	canvas.draw_circle(c, radius, ArtPalette.YELLOW if strong else ArtPalette.YELLOW_TOP.lightened(0.35))
	canvas.draw_arc(c, radius, 0.0, TAU, 32, OUTLINE, 2.0, true)

## The 바닷바람 coast (#93): the land on the left, the sea on the right (as the lab), under a light sky
## and the sun, or under a deep blue sky with a crescent moon and stars (`night`).
static func _coast(canvas: Control, r: Rect2, night: bool) -> void:
	var sky := Color("1c2a62") if night else Color("8fd3ff")
	canvas.draw_rect(r, sky)
	var shore := r.position.x + r.size.x * 0.48
	var top := r.position.y + r.size.y * 0.7
	var dim := 0.45 if night else 0.0
	canvas.draw_rect(Rect2(r.position.x, top, shore - r.position.x, r.end.y - top), ArtPalette.SAND.darkened(dim))
	canvas.draw_rect(Rect2(r.position.x, top, shore - r.position.x, 4.0), ArtPalette.GRASS.darkened(dim))
	canvas.draw_rect(Rect2(shore, top + 4.0, r.end.x - shore, r.end.y - top - 4.0), ArtPalette.SEA.darkened(dim))
	for k in 3:
		var w := Vector2(shore + 14.0 + k * 22.0, top + 12.0 + (k % 2) * 6.0)
		canvas.draw_arc(w, 5.0, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.7 if not night else 0.35), 2.0, true)
	var light := Vector2(r.position.x + r.size.x * 0.3, r.position.y + r.size.y * 0.36)
	if night:
		canvas.draw_circle(light, 13.0, Color("fff4c2"))
		canvas.draw_circle(light + Vector2(6.0, -3.0), 11.0, sky)
		for star: Vector2 in [Vector2(0.62, 0.18), Vector2(0.8, 0.4), Vector2(0.15, 0.15), Vector2(0.5, 0.45), Vector2(0.9, 0.12)]:
			canvas.draw_circle(r.position + star * r.size, 2.2, Color("fff6d0"))
	else:
		for k in 8:
			var d := Vector2.from_angle(TAU * k / 8.0)
			canvas.draw_line(light + d * 16.0, light + d * 22.0, ArtPalette.YELLOW, 3.0, true)
		canvas.draw_circle(light, 12.0, ArtPalette.YELLOW)
	canvas.draw_rect(r, OUTLINE, false, 2.0)


## The Earth (as "earth") with its axis through it, leaning `tilt` deg to the left (the 계절 lab's
## lean), its north end a red dot.
static func _earth_axis(canvas: Control, r: Rect2, tilt: float) -> void:
	var c := r.get_center()
	var radius := r.size.y * 0.36
	canvas.draw_circle(c, radius, ArtPalette.SEA)
	for blob in [[Vector2(-0.3, -0.25), 0.36], [Vector2(0.38, 0.22), 0.3], [Vector2(-0.1, 0.45), 0.2]]:
		canvas.draw_circle(c + (blob[0] as Vector2) * radius, float(blob[1]) * radius, ArtPalette.GRASS)
	canvas.draw_arc(c, radius, 0.0, TAU, 32, OUTLINE, 2.0, true)
	var up := Vector2(-sin(deg_to_rad(tilt)), -cos(deg_to_rad(tilt))) * (radius + 7.0)
	canvas.draw_line(c - up, c + up, OUTLINE, 3.0, true)
	canvas.draw_circle(c + up, 4.0, ArtPalette.RED)


## A day's air: a soft cloud and many vapour dots (humid), or a bright sun and three dots (dry).
static func _air(canvas: Control, r: Rect2, humid: bool) -> void:
	var c := r.get_center()
	if humid:
		for blob: Array in [[Vector2(-14.0, 0.0), 13.0], [Vector2(2.0, -6.0), 16.0], [Vector2(18.0, 1.0), 12.0]]:
			canvas.draw_circle(c + Vector2(0.0, -r.size.y * 0.12) + blob[0], blob[1], Color("dfe9f5"))
	else:
		var sun := c + Vector2(0.0, -r.size.y * 0.1)
		for k in 8:
			var d := Vector2.from_angle(TAU * k / 8.0)
			canvas.draw_line(sun + d * 14.0, sun + d * 20.0, ArtPalette.YELLOW, 3.0, true)
		canvas.draw_circle(sun, 11.0, ArtPalette.YELLOW)
	var dots := 16 if humid else 3
	for i in dots:
		var u := fposmod(i * 0.618034 + 0.1, 1.0)
		var v := fposmod(i * 0.754878 + 0.2, 1.0)
		var at := Vector2(r.position.x + 8.0 + u * (r.size.x - 16.0), r.position.y + r.size.y * 0.45 + v * r.size.y * 0.5)
		canvas.draw_circle(at, 3.6, Color("8cc8f2"))
		canvas.draw_circle(at, 2.2, Color("dff1ff"))

## A sea of warmth `heat` (0 cold, 1 warm, 2 very warm; the typhoon lab's colours, TyphoonProps): the
## water's wavy band; a cold sea has an ice floe and a snowflake, a warm one a sun (bigger when very
## warm) and wisps of water vapour rising (one, or three).
static func _sea(canvas: Control, r: Rect2, heat: int) -> void:
	var water: Color = [TyphoonProps.COLD_SEA, TyphoonProps.WARM_SEA, TyphoonProps.HOT_SEA][heat]
	var top := r.position.y + r.size.y * 0.62
	var band := PackedVector2Array()
	for i in 25:
		var x := lerpf(r.position.x, r.end.x, i / 24.0)
		band.append(Vector2(x, top + 3.0 * sin(i * 0.9)))
	band.append(r.end)
	band.append(Vector2(r.position.x, r.end.y))
	canvas.draw_colored_polygon(band, water)
	canvas.draw_polyline(band.slice(0, 25), water.lightened(0.45), 2.0, true)
	var sun := Vector2(r.end.x - r.size.y * 0.32, r.position.y + r.size.y * 0.3)
	if heat == 0:
		var floe := Vector2(r.position.x + r.size.x * 0.62, top + r.size.y * 0.12)
		canvas.draw_set_transform(floe, 0.0, Vector2(1.0, 0.4))
		canvas.draw_circle(Vector2.ZERO, r.size.y * 0.24, Color.WHITE)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		PredictPictures._snowflake(canvas, Vector2(r.position.x + r.size.x * 0.36, r.position.y + r.size.y * 0.3), Color("7fb0e0"), 1.2)
		return
	var radius := r.size.y * (0.12 if heat == 1 else 0.19)
	for k in 8:
		var d := Vector2.from_angle(TAU * k / 8.0)
		canvas.draw_line(sun + d * (radius + 3.0), sun + d * (radius + 3.0 + radius * 0.6), ArtPalette.YELLOW, 2.5, true)
	canvas.draw_circle(sun, radius, ArtPalette.YELLOW)
	var wisps: Array = [0.4] if heat == 1 else [0.22, 0.42, 0.62]
	for share: float in wisps:
		var foot := Vector2(r.position.x + r.size.x * share, top - 3.0)
		var wisp := PackedVector2Array()
		for i in 9:
			var k := i / 8.0
			wisp.append(foot + Vector2(4.0 * sin(k * TAU), -k * r.size.y * 0.42))
		canvas.draw_polyline(wisp, Color("9fb3c8"), 3.0, true)


static func _ground(canvas: Control, r: Rect2) -> void:
	canvas.draw_line(Vector2(r.position.x, r.end.y), r.end, OUTLINE, 3.0)


## An arrow from `from` to `to` with a small head.
static func _arrow(canvas: Control, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	canvas.draw_line(from, to, color, width, true)
	var d := (to - from).normalized() * (4.0 + width * 1.5)
	var side := Vector2(-d.y, d.x) * 0.6
	canvas.draw_colored_polygon(PackedVector2Array([to + d * 0.5, to - d + side, to - d - side]), color)


## A slide with a box on it: shiny grey steel, brown wood with grain lines, dark bumpy rubber.
static func _slide(canvas: Control, r: Rect2, kind: String) -> void:
	_ground(canvas, r)
	var top := Vector2(r.position.x + 6.0, r.position.y + 6.0)
	var foot := Vector2(r.end.x - 4.0, r.end.y)
	var color: Color = {"slide_steel": STEEL, "slide_wood": ArtPalette.WOOD, "slide_rubber": ArtPalette.RUBBER}[kind]
	canvas.draw_colored_polygon(PackedVector2Array([top, foot, Vector2(top.x, foot.y)]), color)
	var down := (foot - top).normalized()
	var normal := Vector2(down.y, -down.x)
	match kind:
		"slide_steel":
			for k in [0.3, 0.62]:
				var p := top.lerp(foot, k) - normal * 4.0
				canvas.draw_line(p, p + down * 12.0, Color("ffffff"), 2.0)
		"slide_wood":
			for k in [0.35, 0.7]:
				var a := Vector2(top.x + 4.0, top.lerp(foot, k).y)
				canvas.draw_line(a, Vector2(top.lerp(foot, k).x - 4.0, a.y), ArtPalette.WOOD_GRAIN, 2.0)
		"slide_rubber":
			var bumps := PackedVector2Array()
			for i in 9:
				bumps.append(top.lerp(foot, i / 8.0) + normal * (2.0 if i % 2 == 0 else -1.0))
			canvas.draw_polyline(bumps, ArtPalette.RUBBER_RIDGE, 3.0, true)
	canvas.draw_line(top, foot, OUTLINE, 2.0, true)
	var box_at := top.lerp(foot, 0.3) + normal * 9.0
	canvas.draw_set_transform(box_at, down.angle(), Vector2.ONE)
	canvas.draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), ArtPalette.ORANGE)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
