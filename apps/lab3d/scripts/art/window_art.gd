## The framed picture window of a Hutton Island lab (낮과 밤, 계절: #74, #87): a flat picture of the
## sky over the fox's yard in a wooden frame on a stand, drawn in the window's own local frame (x
## across, y up, +z towards the camera; the picture centred at the origin). Static mesh helpers only,
## sized by the caller's window: the props own the window node, its sky colours and what it shows.
## Visual only, like every prop (art-direction.md section 1).
class_name WindowArt
extends RefCounted

const FRAME_COLOR := Color("c98d4f")
const FRAME_TOP := Color("dba468")


## The picture's sky: a rectangle of `size` (m) centred at the origin, `low` at the bottom and `top`
## at the top (a vertical gradient). Rebuild it when the colours change.
static func sky_mesh(size: Vector2, top: Color, low: Color) -> Mesh:
	var b := ArtKit.builder()
	b.ao_min = 1.0
	var half := size * 0.5
	var corners: Array[Vector3] = [Vector3(-half.x, -half.y, 0.0), Vector3(half.x, -half.y, 0.0), Vector3(half.x, half.y, 0.0), Vector3(-half.x, half.y, 0.0)]
	b.add_triangle([corners[0], corners[1], corners[2]], [low, low, top], Vector3.BACK)
	b.add_triangle([corners[0], corners[2], corners[3]], [low, top, top], Vector3.BACK)
	return b.commit()


## The picture's horizon (window local y) when the yard takes `yard_share` of its height `size.y`.
static func horizon_y(size: Vector2, yard_share: float) -> float:
	return -size.y * 0.5 + size.y * yard_share


## The wooden frame round `inner` (window local: the picture, or the picture and its bars), `border`
## wide and `depth` deep, with a darker board behind (`board_darken`). `round`: the bars' rounding.
static func add_frame(b: ArtMeshBuilder, inner: Rect2, border: float, depth: float, round := 0.025, board_darken := 0.3, color := FRAME_COLOR, top := FRAME_TOP) -> void:
	var w := inner.size.x + border * 2.0
	var h := inner.size.y + border * 2.0
	var c := inner.get_center()
	for side: float in [-1.0, 1.0]:
		b.add_rounded_box(Transform3D(Basis(), Vector3(c.x, c.y + side * (h - border) * 0.5, 0.0)), Vector3(w, border, depth), round, 1, color, top)
		b.add_rounded_box(Transform3D(Basis(), Vector3(c.x + side * (w - border) * 0.5, c.y, 0.0)), Vector3(border, h - border * 2.0 + 0.002, depth), round, 1, color, top)
	b.add_rounded_box(Transform3D(Basis(), Vector3(c.x, c.y, -depth * 0.5 + 0.01)), Vector3(w - 0.02, h - 0.02, 0.02), 0.0, 1, color.darkened(board_darken))


## The window's stand (world frame, on the floor y = 0): two wooden posts from the floor up to
## `bottom` (the frame's lower edge, world y), `half_span` either side of the window's centre
## `center` and `back` behind it, each on a foot box. `turn_deg`: the window's turn about y (the posts
## follow it). `post`: the posts' radii (foot, top); `foot`: the foot box's size.
static func add_stand(b: ArtMeshBuilder, center: Vector3, bottom: float, half_span: float, back := 0.05, turn_deg := 0.0, post := Vector2(0.05, 0.04), foot := Vector3(0.32, 0.06, 0.24)) -> void:
	b.ao_min = 0.8
	b.ao_height = 0.4
	var turn := Basis(Vector3.UP, deg_to_rad(turn_deg))
	for side: float in [-1.0, 1.0]:
		var at := center + turn * Vector3(side * half_span, 0.0, -back)
		at.y = 0.0
		b.add_cylinder(Transform3D(Basis(), at), post.x, post.y, bottom + 0.05, 6, ArtPalette.WOOD_GRAIN)
		b.add_rounded_box(Transform3D(turn, at + Vector3(0.0, foot.y * 0.5, 0.0)), foot, 0.02, 1, ArtPalette.WOOD_GRAIN)
