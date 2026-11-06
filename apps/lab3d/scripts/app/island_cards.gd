## 섬 고르기 (#75, 2026-11-06 user-approved mock B1): the title's island picker, one card per island
## of the list (Island) and a last card for the island still to come. A card shows the island (its
## map rendered once, from the title's 3/4 view), its name and field, the star pieces found on it and
## 이어서 하기 (still pieces to find) or 다시 가기 (all found); the island in use has a gold edge. An
## island not open yet (Island.is_open) is grey with a lock and the condition ("뉴턴섬 조각을 다 모으면
## 열려요"); the last card, 다음 섬, has no picture of its own (a grey island and a lock) and opens after
## the last island of the list. A card's button emits `chosen` (App makes it the island in use and
## opens its map); ← 돌아가기 and Android back emit `back_requested`. The payment's words are not
## here yet (#77, ADR 0005).
class_name IslandCards
extends Control

signal chosen(island: String)
signal back_requested

const CARD_MAX := 300.0
const GAP := 24.0
const EDGE := 16.0
const THUMB_ASPECT := 0.72
## The thumbnails' render size (px) and camera (the title's 3/4 view of the island).
const THUMB_PIXELS := Vector2i(400, 288)
const THUMB_PITCH_DEG := -34.0
const THUMB_YAW_DEG := 20.0
const THUMB_DISTANCE := 40.0
const LOCKED_TINT := Color("8fa6c8")
const GREY_SHADER := "shader_type canvas_item;\nuniform vec4 tint : source_color;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), tint.rgb, 0.35), c.a);\n}\n"

var heading: PanelContainer
var back_button: Button
var row: HBoxContainer
## Island id ("" for 다음 섬) -> its card's button (null when locked) (tests).
var buttons: Dictionary = {}
var cards: Dictionary = {}
var _entries: Array = []


## The cards, in order: per island {id, name, about, open, complete, pieces, total, current, after}
## (`after`: the name of the island it waits for), then 다음 섬 {id "", open false, after: the last
## island's name}.
static func entries(progress: Dictionary) -> Array:
	var out := []
	var ids := Island.ids()
	for id in ids:
		var island := Island.by_id(id)
		var after := Island.opens_after(id)
		out.append({"id": id, "name": island_name(id), "about": Locale.t("island.%s.about" % id),
			"open": Island.is_open(id, progress), "complete": island.complete(progress),
			"pieces": island.found(progress).size(), "total": island.spots().size(),
			"current": id == Island.current_id(), "after": island_name(after) if after != "" else ""})
	out.append({"id": "", "name": Locale.t("islands.next"), "about": "", "open": false, "complete": false,
		"pieces": 0, "total": 0, "current": false, "after": island_name(str(ids[-1])) if not ids.is_empty() else ""})
	return out


static func island_name(id: String) -> String:
	return Locale.t("island.%s.name" % id)


## The condition on a locked card.
static func locked_line(entry: Dictionary) -> String:
	return Locale.t("islands.locked") % str(entry.after)


func _ready() -> void:
	name = "IslandCards"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # the title's buttons under it take nothing
	_entries = entries(ProgressStore.load())
	heading = PanelContainer.new()
	heading.name = "IslandsHeading"
	var ribbon := UiTheme._box(UiTheme.TITLE_RED, UiTheme.DIALOGUE_LINE, 18, 34.0, 6.0, Color.TRANSPARENT, 4, 9)
	heading.add_theme_stylebox_override("panel", ribbon)
	var title := Label.new()
	title.text = Locale.t("title.islands")
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", UiTheme.WHITE)
	title.add_theme_color_override("font_outline_color", UiTheme.DIALOGUE_LINE)
	title.add_theme_constant_override("outline_size", 8)
	heading.add_child(title)
	add_child(heading)
	back_button = Ui.button(Locale.t("islands.back"), "TitleButton", 56)
	back_button.name = "IslandsBack"
	back_button.pressed.connect(back_requested.emit)
	add_child(back_button)
	row = HBoxContainer.new()
	row.name = "IslandRow"
	row.add_theme_constant_override("separation", int(GAP))
	add_child(row)
	for entry in _entries:
		var card := _card(entry)
		cards[entry.id] = card
		row.add_child(card)
	_layout()
	resized.connect(_layout)
	_settle()


## A wrapped line's height follows its width only after the row sorted once: the layout again then.
func _settle() -> void:
	for i in 2:
		await get_tree().process_frame
	if is_inside_tree():
		_layout()


func card_width() -> float:
	var n := maxi(_entries.size(), 1)
	return minf(CARD_MAX, (size.x - 2.0 * EDGE - GAP * (n - 1)) / n)


func _card(entry: Dictionary) -> PanelContainer:
	var locked: bool = not entry.open
	var card := PanelContainer.new()
	card.name = "Card_%s" % (entry.id if entry.id != "" else "next")
	var line := UiTheme.SELECT_LINE if entry.current else UiTheme.DIALOGUE_LINE
	var style := UiTheme._box(Color("efe7da") if locked else UiTheme.DIALOGUE_PAPER, line, 22, 12.0, 12.0,
		Color.TRANSPARENT, 6 if entry.current else 4, 13 if entry.current else 9)
	card.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)
	var frame := Panel.new()
	frame.name = "Picture"
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = MapIsland.sea_color()
	frame_style.set_corner_radius_all(14)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(frame)
	if entry.id != "":
		var picture := TextureRect.new()
		picture.name = "Island"
		picture.texture = _thumbnail(entry.id)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if locked:
			var grey := ShaderMaterial.new()
			grey.shader = Shader.new()
			grey.shader.code = GREY_SHADER
			grey.set_shader_parameter("tint", LOCKED_TINT)
			picture.material = grey
		frame.add_child(picture)
	else:
		var far := FarIsland.new()
		far.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_child(far)
	if locked:
		var lock := Lock.new()
		lock.name = "Lock"
		lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_child(lock)
	elif int(entry.total) > 0:
		var emblem := StarEmblem.new(int(entry.total))
		emblem.set_filled(int(entry.pieces))
		emblem.pivot_offset = Vector2.ZERO
		emblem.scale = Vector2.ONE * 0.6
		emblem.position = Vector2(8.0, 8.0)
		frame.add_child(emblem)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = entry.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", UiTheme.bold_font())
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", UiTheme.MUTED if locked else UiTheme.INK)
	col.add_child(name_label)
	var sub := Label.new()
	sub.name = "About"
	sub.text = locked_line(entry) if locked else str(entry.about)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	sub.add_theme_color_override("font_color", UiTheme.SUBTLE if locked else UiTheme.MUTED)
	col.add_child(sub)
	if locked:
		buttons[entry.id] = null
		var room := Control.new()
		room.custom_minimum_size.y = 62.0
		col.add_child(room)
	else:
		var again: bool = entry.complete
		var go := Ui.button(Locale.t("islands.again" if again else "islands.continue"), "TitleButton" if again else "TitleStartButton", 56 if again else 62)
		go.name = "Go"
		go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		go.custom_minimum_size.x = 200.0
		if not again:
			go.add_theme_font_size_override("font_size", 26)
		var id: String = entry.id
		go.pressed.connect(func() -> void: chosen.emit(id))
		col.add_child(go)
		buttons[id] = go
	return card


func _layout() -> void:
	if row == null or size.x < 1.0:
		return
	var inset := Ui.safe_insets(self)
	heading.size = heading.get_combined_minimum_size()
	heading.position = Vector2((size.x - heading.size.x) * 0.5, 18.0 + inset.top)
	back_button.size = back_button.get_combined_minimum_size()
	back_button.position = Vector2(EDGE + inset.left, 18.0 + inset.top)
	var w := card_width()
	for card: PanelContainer in row.get_children():
		card.custom_minimum_size.x = w
		var frame := card.find_child("Picture", true, false) as Control
		frame.custom_minimum_size = Vector2(w - 24.0, (w - 24.0) * THUMB_ASPECT)
		(card.find_child("About", true, false) as Label).custom_minimum_size.x = w - 24.0
	row.reset_size()
	row.size = row.get_combined_minimum_size()
	var top := heading.position.y + heading.size.y + 12.0
	row.position = Vector2((size.x - row.size.x) * 0.5, maxf(top, top + (size.y - top - row.size.y) * 0.5 - 6.0))


## The island's picture: its map rendered once in its own small world from the title's 3/4 view.
func _thumbnail(id: String) -> Texture2D:
	var sub := SubViewport.new()
	sub.name = "Thumb_%s" % id
	sub.size = THUMB_PIXELS
	sub.own_world_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(sub)
	sub.add_child(MapIsland.make_environment())
	var world := Node3D.new()
	sub.add_child(world)
	var island := Island.by_id(id)
	MapIsland.new(island).build(world, VoyageScreen._spots(island))
	var camera := Camera3D.new()
	camera.fov = 40.0
	sub.add_child(camera)
	var pitch := deg_to_rad(THUMB_PITCH_DEG)
	var yaw := deg_to_rad(THUMB_YAW_DEG)
	var target := Vector3(0.0, IslandHomeScreen.TARGET_Y, 0.0)
	var eye := target + Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * THUMB_DISTANCE
	camera.look_at_from_position(eye, target)
	camera.current = true
	return sub.get_texture()


## The rects of the cards, the heading and ← 돌아가기 (tests: on screen, no overlap).
func rects() -> Array[Rect2]:
	var out: Array[Rect2] = [heading.get_global_rect(), back_button.get_global_rect()]
	for card: Control in row.get_children():
		out.append(card.get_global_rect())
	return out


## A padlock (gold body, steel shackle, brown storybook outline) in the middle of a locked picture.
class Lock extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y) / 110.0
		var c := size * 0.5 + Vector2(0.0, -4.0) * s
		var line := UiTheme.DIALOGUE_LINE
		var steel := Color("c9ced8")
		for pass_width in [13.0, 7.0]:
			var color := line if pass_width > 10.0 else steel
			draw_arc(c + Vector2(0, -8) * s, 17.0 * s, PI, TAU, 24, color, pass_width * s, true)
			draw_line(c + Vector2(-17, -8) * s, c + Vector2(-17, 4) * s, color, pass_width * s, true)
			draw_line(c + Vector2(17, -8) * s, c + Vector2(17, 4) * s, color, pass_width * s, true)
		var body := StyleBoxFlat.new()
		body.bg_color = ArtPalette.YELLOW
		body.border_color = line
		body.set_border_width_all(maxi(2, int(4 * s)))
		body.set_corner_radius_all(int(9 * s))
		body.anti_aliasing = true
		draw_style_box(body, Rect2(c + Vector2(-27, -2) * s, Vector2(54, 40) * s))
		draw_rect(Rect2(c + Vector2(-21, 3) * s, Vector2(42, 7) * s), ArtPalette.YELLOW_TOP)
		draw_circle(c + Vector2(0, 14) * s, 5.5 * s, line, true, -1.0, true)
		draw_line(c + Vector2(0, 16) * s, c + Vector2(0, 26) * s, line, 5.0 * s, true)


## The island still to come: a grey island far on a grey sea (no name, no picture of its own).
class FarIsland extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("9aa6b8"))
		var c := Vector2(size.x * 0.5, size.y * 0.62)
		var sand := PackedVector2Array()
		var land := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			sand.append(c + Vector2(cos(a) * size.x * 0.34, sin(a) * size.y * 0.16))
			land.append(c + Vector2(cos(a) * size.x * 0.28, sin(a) * size.y * 0.12 - 4.0))
		draw_colored_polygon(sand, Color("c4c9d2"))
		draw_colored_polygon(land, Color("aab3c0"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-size.x * 0.16, -6.0), c + Vector2(0.0, -size.y * 0.3), c + Vector2(size.x * 0.14, -6.0)]), Color("b8bfcb"))
