## 섬 고르기 (#75, 2026-11-06 user-approved mock B1): the title's island picker, one card per island
## of the list (Island) and a last card for the island still to come. A card shows the island (its
## map rendered once, from the title's 3/4 view), its name and field, the star pieces found on it and
## 이어서 하기 (still pieces to find) or 다시 가기 (all found); the island in use has a gold edge. An
## island not open yet (Island.is_open) is grey with a lock and the condition ("뉴턴섬 조각을 다 모으면
## 열려요"); the last card, 다음 섬, has no picture of its own (a grey island and a lock) and opens after
## the last island of the list. A card's button emits `chosen` (App makes it the island in use and
## opens its map); ← 돌아가기 emits `back_requested` (TitleScreen closes the cards). Android back
## closes them too, through App (TitleScreen.hide_islands, no signal). The payment (#77):
## an open island not bought has a small 보호자 in its picture's corner (ADR 0005: IslandOffer).
class_name IslandCards
extends Control

signal chosen(island: String)
signal back_requested

const CARD_MAX := 340.0
const GAP := 24.0
const EDGE := 16.0
const TOP := 18.0                  # the heading and ← 돌아가기 from the top
const ROW_GAP := 18.0              # the cards under the heading
const ROW_LIFT := 6.0              # the row a little above the middle of the room left
## The heading: a red ribbon with white words outlined in the storybook brown.
const HEADING_RADIUS := 18
const HEADING_PAD := Vector2(34.0, 6.0)
const HEADING_LINE := 4
const HEADING_LIP := 9
const HEADING_SIZE := 36
const HEADING_OUTLINE := 8
## A card: cream paper (a locked one greyer), the brown outline (the island in use: gold, thicker).
const CARD_RADIUS := 22
const CARD_PAD := 12.0
const CARD_LINE := 4
const CARD_LIP := 9
const CURRENT_LINE := 6
const CURRENT_LIP := 13
const LOCKED_PAPER := Color("efe7da")
const CARD_SEPARATION := 6
const PICTURE_RADIUS := 14
const THUMB_ASPECT := 0.72
const NAME_SIZE := 30
## 보호자 (#77): small, in the picture's top right corner (the star pieces are top left).
const GUARDIAN_INSET := 8
## The star pieces found, small in the picture's corner.
const EMBLEM_SCALE := 0.8
const EMBLEM_AT := Vector2(8.0, 8.0)
## The card's button: 이어서 하기 (the ribbon red, bigger) or 다시 가기 (cream); a locked card keeps its room.
const GO_WIDTH := 200.0
const CONTINUE_HEIGHT := 62.0
const CONTINUE_FONT := 26
const BACK_HEIGHT := 56.0
## The thumbnails' render size (px) and camera (the title's 3/4 view of the island).
const THUMB_PIXELS := Vector2i(400, 288)
const THUMB_PITCH_DEG := -34.0
const THUMB_YAW_DEG := 20.0
const THUMB_DISTANCE := 40.0
const THUMB_FOV := 40.0
## A locked island's picture: grey with a little cool blue-grey (locked_grey.gdshader).
const LOCKED_TINT := Color("8fa6c8")
const GREY_SHADER := preload("res://scripts/app/locked_grey.gdshader")

var heading: PanelContainer
var back_button: Button
var row: HBoxContainer
## Island id ("" for 다음 섬) -> its card's button (null when locked) (tests).
var buttons: Dictionary = {}
var cards: Dictionary = {}
## Island id -> its 보호자 button (an open island not bought, #77; tests).
var guardians: Dictionary = {}
var _entries: Array = []


## The cards, in order: per island {id, name, about, open, complete, pieces, total, piece (its kind,
## PieceArt), current, after}
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
			"pieces": island.found(progress).size(), "total": island.spots().size(), "piece": island.piece,
			"finale": ProgressStore.mark(ProgressStore.STORY, ProgressStore.island_key(id, "finale")),
			"current": id == Island.current_id(), "after": island_name(after) if after != "" else ""})
	out.append({"id": "", "name": Locale.t("islands.next"), "about": "", "open": false, "complete": false,
		"pieces": 0, "total": 0, "piece": PieceArt.STAR, "current": false, "after": island_name(str(ids[-1])) if not ids.is_empty() else ""})
	return out


static func island_name(id: String) -> String:
	return Locale.t("island.%s.name" % id)


## The line under a locked card's name: what opens it; 다음 섬 promises nothing yet (2026-11-09: no
## island opens after the last one, so not "collect them all and it opens").
static func locked_line(entry: Dictionary) -> String:
	if str(entry.id) == "":
		return Locale.t("islands.soon")
	return Locale.t("islands.locked") % str(entry.after)


func _ready() -> void:
	name = "IslandCards"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # the title's buttons under it take nothing
	_entries = entries(ProgressStore.load())
	heading = _heading()
	add_child(heading)
	back_button = Ui.button(Locale.t("islands.back"), "TitleButton", BACK_HEIGHT)
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
	if IslandStore.instance != null:
		IslandStore.instance.changed.connect(_on_store_changed)
	_settle()


## 섬 고르기 on the red ribbon.
func _heading() -> PanelContainer:
	var ribbon := PanelContainer.new()
	ribbon.name = "IslandsHeading"
	ribbon.add_theme_stylebox_override("panel", UiTheme.outlined_box(UiTheme.TITLE_RED, UiTheme.DIALOGUE_LINE, HEADING_RADIUS, HEADING_PAD, HEADING_LINE, HEADING_LIP))
	var title := Label.new()
	title.text = Locale.t("title.islands")
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", HEADING_SIZE)
	title.add_theme_color_override("font_color", UiTheme.WHITE)
	title.add_theme_color_override("font_outline_color", UiTheme.DIALOGUE_LINE)
	title.add_theme_constant_override("outline_size", HEADING_OUTLINE)
	ribbon.add_child(title)
	return ribbon


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
	card.add_theme_stylebox_override("panel", UiTheme.outlined_box(LOCKED_PAPER if locked else UiTheme.DIALOGUE_PAPER, line,
		CARD_RADIUS, Vector2(CARD_PAD, CARD_PAD), CURRENT_LINE if entry.current else CARD_LINE, CURRENT_LIP if entry.current else CARD_LIP))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", CARD_SEPARATION)
	card.add_child(col)
	col.add_child(_picture(entry))
	_add_words(col, entry)
	if locked:
		buttons[entry.id] = null
		var room := Control.new()
		room.custom_minimum_size.y = CONTINUE_HEIGHT
		col.add_child(room)
	else:
		buttons[entry.id] = _go_button(entry)
		col.add_child(buttons[entry.id])
		# The whole card goes there too (a tap on the island's picture or name, 2026-11-09).
		var id: String = entry.id
		card.gui_input.connect(func(event: InputEvent) -> void:
			if _tapped(event):
				chosen.emit(id))
	return card


## A finger or the left button let go on the card (a press that was not a drag of the row).
static func _tapped(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not event.pressed and not event.canceled
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed \
		and event.device != InputEvent.DEVICE_ID_EMULATION


## The card's picture: the island (grey when locked) or, for 다음 섬, a far grey island; the lock on a
## locked one, the star pieces found on an open one.
func _picture(entry: Dictionary) -> Panel:
	var locked: bool = not entry.open
	var frame := Panel.new()
	frame.name = "Picture"
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = MapIsland.sea_color()
	frame_style.set_corner_radius_all(PICTURE_RADIUS)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if entry.id != "":
		var picture := TextureRect.new()
		picture.name = "Island"
		picture.texture = _thumbnail(entry.id)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if locked:
			var grey := ShaderMaterial.new()
			grey.shader = GREY_SHADER
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
	if not locked and entry.id != "" and not IslandStore.owns(entry.id):
		frame.add_child(_guardian_button(entry.id))
	if not locked and int(entry.total) > 0:
		var emblem := PieceArt.emblem(str(entry.piece), int(entry.total))
		emblem.set_filled(int(entry.pieces))
		if emblem is SundialEmblem and entry.get("finale", false):
			(emblem as SundialEmblem).set_whole(true)   # #106: the sundial is whole after its finale
		emblem.pivot_offset = Vector2.ZERO
		emblem.scale = Vector2.ONE * EMBLEM_SCALE
		emblem.position = EMBLEM_AT
		frame.add_child(emblem)
	return frame


## The small 보호자 at the picture's top right of an open island not bought (#77): the guardian's check,
## then the island's offer. Gone once the island is bought.
func _guardian_button(id: String) -> Button:
	var guardian := GuardianModal.guardian_button()
	guardian.name = "Guardian"
	guardian.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, GUARDIAN_INSET)
	guardian.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	guardian.pressed.connect(func() -> void: IslandOffer.open_for_guardian(self, id))
	guardians[id] = guardian
	return guardian


## The store changed (a purchase): a bought island's 보호자 goes.
func _on_store_changed() -> void:
	for id in guardians:
		if is_instance_valid(guardians[id]):
			guardians[id].visible = not IslandStore.owns(id)


## The island's name and, under it, its field (or, when locked, what opens it).
func _add_words(col: VBoxContainer, entry: Dictionary) -> void:
	var locked: bool = not entry.open
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = entry.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", UiTheme.bold_font())
	name_label.add_theme_font_size_override("font_size", NAME_SIZE)
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


## The way in, the same big red button on every open island (2026-11-09: one look; the island in use
## is the gold edge): 가 보기 (nothing found yet), 이어서 하기 (pieces left) or 다시 가기 (all found).
## `chosen` with the island.
func _go_button(entry: Dictionary) -> Button:
	var key := "islands.again" if entry.complete else ("islands.go" if int(entry.pieces) == 0 else "islands.continue")
	var go := Ui.button(Locale.t(key), "TitleStartButton", CONTINUE_HEIGHT)
	go.name = "Go"
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.custom_minimum_size.x = GO_WIDTH
	go.add_theme_font_size_override("font_size", CONTINUE_FONT)
	var id: String = entry.id
	go.pressed.connect(func() -> void: chosen.emit(id))
	return go


func _layout() -> void:
	if row == null or size.x < 1.0:
		return
	var inset := Ui.safe_insets(self)
	heading.size = heading.get_combined_minimum_size()
	back_button.size = back_button.get_combined_minimum_size()
	back_button.position = Vector2(EDGE + inset.left, TOP + inset.top)
	var w := card_width()
	for card: PanelContainer in row.get_children():
		card.custom_minimum_size.x = w
		var frame := card.find_child("Picture", true, false) as Control
		var inner := w - 2.0 * CARD_PAD
		frame.custom_minimum_size = Vector2(inner, inner * THUMB_ASPECT)
		(card.find_child("About", true, false) as Label).custom_minimum_size.x = inner
	row.reset_size()
	row.size = row.get_combined_minimum_size()
	# The heading sits just over the cards, the two as one block in the middle (2026-11-09 user: the
	# heading alone at the top looked too high); never over ← 돌아가기's line.
	var block := heading.size.y + ROW_GAP + row.size.y
	var lowest: float = TOP + inset.top
	var top := maxf(lowest, (size.y - block) * 0.5 - ROW_LIFT)
	heading.position = Vector2((size.x - heading.size.x) * 0.5, top)
	row.position = Vector2((size.x - row.size.x) * 0.5, top + heading.size.y + ROW_GAP)


## The island's picture: its map rendered once in its own small world from the title's 3/4 view.
func _thumbnail(id: String) -> Texture2D:
	return thumbnail(self, id)


## The picture of `id`, its small world under `host` (the cards, the island's offer: IslandOffer).
static func thumbnail(host: Node, id: String) -> Texture2D:
	var sub := SubViewport.new()
	sub.name = "Thumb_%s" % id
	sub.size = THUMB_PIXELS
	sub.own_world_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(sub)
	sub.add_child(MapIsland.make_environment())
	var world := Node3D.new()
	sub.add_child(world)
	var island := Island.by_id(id)
	MapIsland.new(island).build(world, island.map_spots())
	var camera := Camera3D.new()
	camera.fov = THUMB_FOV
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
## Its drawing is in units of a 110-unit square (scaled to the picture).
class Lock extends Control:
	const DESIGN := 110.0
	const STEEL := Color("c9ced8")
	const OUTLINE_WIDTH := 13.0
	const STEEL_WIDTH := 7.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y) / DESIGN
		var c := size * 0.5 + Vector2(0.0, -4.0) * s
		var line := UiTheme.DIALOGUE_LINE
		for pass_width in [OUTLINE_WIDTH, STEEL_WIDTH]:
			var color := line if pass_width == OUTLINE_WIDTH else STEEL
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
	const SEA := Color("9aa6b8")
	const SAND := Color("c4c9d2")
	const LAND := Color("aab3c0")
	const HILL := Color("b8bfcb")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), SEA)
		var c := Vector2(size.x * 0.5, size.y * 0.62)
		var sand := PackedVector2Array()
		var land := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			sand.append(c + Vector2(cos(a) * size.x * 0.34, sin(a) * size.y * 0.16))
			land.append(c + Vector2(cos(a) * size.x * 0.28, sin(a) * size.y * 0.12 - 4.0))
		draw_colored_polygon(sand, SAND)
		draw_colored_polygon(land, LAND)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-size.x * 0.16, -6.0), c + Vector2(0.0, -size.y * 0.3), c + Vector2(size.x * 0.14, -6.0)]), HILL)
