## A guardian's screen over the map or 섬 고르기 (#77, 2026-11-08 user-approved mock): a dim backdrop
## that takes every tap, a cream card with the storybook brown outline in the middle and a round ×
## at its top right. ParentalGate and IslandOffer are its two screens; the words are the guardian's,
## never the child's (no "buy" urged on the child). Android back closes the top one (App, close_top).
class_name GuardianModal
extends Control

signal closed

const GROUP := "guardian_modal"
const DIM := Color(0.06, 0.1, 0.2, 0.55)
const CARD_RADIUS := 26
const CARD_PAD := Vector2(44.0, 34.0)
const CARD_LINE := 4
const CARD_LIP := 9
const EDGE := 16.0
const CLOSE_SIZE := 56.0
const CLOSE_INSET := 14.0
## The words on the screens' wide buttons (닫기, 확인) and the ×.
const BUTTON_FONT := 30
## The small 보호자 button (Puppy's box on the map, 섬 고르기's card).
const GUARDIAN_HEIGHT := 48.0
const TITLE_SIZE := 40
const LINE_SIZE := 22

var card: PanelContainer
var body: Control
var close_button: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(GROUP)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	card = PanelContainer.new()
	card.name = "Card"
	card.add_theme_stylebox_override("panel", UiTheme.outlined_box(UiTheme.DIALOGUE_PAPER, UiTheme.DIALOGUE_LINE,
		CARD_RADIUS, CARD_PAD, CARD_LINE, CARD_LIP))
	add_child(card)
	close_button = Ui.button("×", "TitleButton", CLOSE_SIZE)
	close_button.name = "Close"
	close_button.custom_minimum_size = Vector2(CLOSE_SIZE, CLOSE_SIZE)
	close_button.add_theme_font_size_override("font_size", BUTTON_FONT)
	close_button.pressed.connect(close)
	add_child(close_button)
	resized.connect(_layout)


func _ready() -> void:
	_layout()
	_settle()


## The card's content (the screens put theirs here once).
func set_body(content: Control) -> void:
	body = content
	var room := MarginContainer.new()   # the × at the top right keeps clear of the content
	room.add_theme_constant_override("margin_right", int(CLOSE_SIZE))
	room.add_child(content)
	card.add_child(room)
	_layout()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


## Android back (App): the top guardian screen under `root` closes. True when one did.
static func close_top(root: Node) -> bool:
	var open := root.get_tree().get_nodes_in_group(GROUP).filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
	if open.is_empty():
		return false
	(open[-1] as GuardianModal).close()
	return true


## A wrapped label's height follows its width only after a frame: lay out again then.
func _settle() -> void:
	for i in 2:
		await get_tree().process_frame
	if is_inside_tree():
		_layout()


func _layout() -> void:
	if card == null or size.x < 1.0:
		return
	var inset := Ui.safe_insets(self)
	card.reset_size()
	card.size = card.get_combined_minimum_size()
	var room := Rect2(Vector2(inset.left + EDGE, inset.top + EDGE),
		size - Vector2(inset.left + inset.right + 2.0 * EDGE, inset.top + inset.bottom + 2.0 * EDGE))
	card.position = (room.position + (room.size - card.size) * 0.5).round()
	close_button.size = close_button.get_combined_minimum_size()
	close_button.position = card.position + Vector2(card.size.x - close_button.size.x - CLOSE_INSET, CLOSE_INSET)


## The small 보호자 button that opens the guardian's check (#77): Puppy's box and 섬 고르기's card.
static func guardian_button() -> Button:
	return Ui.button(Locale.t("guardian.button"), "TitleButton", GUARDIAN_HEIGHT)


## A label in the screens' words: `size` px, bold or not, the ink colour or `color`.
static func text_label(words: String, font_size: int, bold := false, color := UiTheme.INK, wrap_width := 0.0) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", UiTheme.bold_font())
	if wrap_width > 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = wrap_width
	return label


## Rects of the card and × (tests: inside the view).
func rects() -> Array[Rect2]:
	return [card.get_global_rect(), close_button.get_global_rect()]
