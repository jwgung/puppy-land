## The round-done card (2026-10-28): when the child finishes a spot's last stage in this visit, a
## card in the middle of the view shows the round's stamps, big, and two big buttons: [더 해 보기] (the card
## goes, the lab is set up again) and [다음으로] (blue; back to the map, like ← 지도). Pictures only (2026-10-28
## user decision: no headline or caption). While it is up nothing behind it takes a touch: a dim
## over the whole view stops every press (the QuestionShield pattern), and it lets go of input in the
## frame it closes (MOUSE_FILTER_IGNORE before queue_free).
class_name RoundDoneCard
extends Control

signal to_map
signal stay

const DIM := Color(0.08, 0.12, 0.2, 0.38)   # ExperimentScreen.QUESTION_DIM
const DIM_FADE := 0.2
const STAMP_R := 46.0
const STAMP_GAP := 22.0
## The found star piece stands over the stamps, centred (2026-10-31 user: not in their row), this big.
const STAR_R := 62.0
const STAR_GAP := 14.0
const POP_S := 0.35

var stamps := 3
## The story: the round's piece (piece_kind) is drawn over the stamps (the piece the child just found).
var piece := false
## Which piece (PieceArt: the island's, #101): the star, the hutton island's sundial wedge or the curie
## island's lens wedge; `piece_slot` its place in the order (the lens's colour, #154).
var piece_kind := PieceArt.STAR
var piece_slot := 0
var dim: ColorRect
var card: PanelContainer
var stamp_row: Control
var map_button: Button
var stay_button: Button
var closed := false


func _init(stamp_count: int, with_piece := false, kind := PieceArt.STAR, slot := 0) -> void:
	name = "RoundDoneCard"
	stamps = stamp_count
	piece = with_piece
	piece_kind = kind
	piece_slot = slot
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.modulate.a = 0.0
	add_child(dim)
	card = Ui.panel("DialogueBox")
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(card)
	var stack := Ui.vbox(22)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := Ui.margin(22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	card.add_child(margin)
	stamp_row = Control.new()
	stamp_row.name = "Stamps"
	stamp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row_w := stamps * STAMP_R * 2.0 + maxi(0, stamps - 1) * STAMP_GAP
	var star_h := (STAR_R * 2.0 + 8.0 + STAR_GAP) if piece else 0.0
	stamp_row.custom_minimum_size = Vector2(maxf(row_w, STAR_R * 2.0 + 8.0), star_h + STAMP_R * 2.0 + 8.0)
	stamp_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stamp_row.draw.connect(_draw_stamps)
	stack.add_child(stamp_row)
	var buttons := Ui.hbox(16)
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(buttons)
	# [더 해 보기] first and quiet (the card goes, the lab is set up again); [다음으로] last and blue, the way on
	# (back to the map, like ← 지도): the two no longer look alike.
	stay_button = Ui.button(Locale.t("done.stay"), "ChoiceButton", 84)
	stay_button.name = "Stay"
	stay_button.custom_minimum_size.x = 190
	stay_button.pressed.connect(func() -> void: _close(stay))
	buttons.add_child(stay_button)
	map_button = Ui.button(Locale.t("done.next"), "PrimaryButton", 84)
	map_button.name = "ToMap"
	map_button.custom_minimum_size.x = 190
	map_button.pressed.connect(func() -> void: _close(to_map))
	buttons.add_child(map_button)
	for b: Button in [map_button, stay_button]:
		b.add_theme_font_size_override("font_size", 26)


func _ready() -> void:
	create_tween().tween_property(dim, "modulate:a", 1.0, DIM_FADE)
	resized.connect(_fit)
	_fit()
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE * 0.75
	create_tween().tween_property(card, "scale", Vector2.ONE, POP_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The card in the middle of the view.
func _fit() -> void:
	card.size = card.get_combined_minimum_size()
	card.position = ((size - card.size) * 0.5).round()
	card.pivot_offset = card.size * 0.5


func _draw_stamps() -> void:
	var w := stamp_row.custom_minimum_size.x
	var row_w := stamps * STAMP_R * 2.0 + maxi(0, stamps - 1) * STAMP_GAP
	var row_y := (STAR_R * 2.0 + 8.0 + STAR_GAP if piece else 0.0) + STAMP_R + 4.0
	for i in stamps:
		var c := Vector2((w - row_w) * 0.5 + STAMP_R + i * (STAMP_R * 2.0 + STAMP_GAP), row_y)
		StampSlam.draw_stamp(stamp_row, c, STAMP_R, true)
	if piece:   # the found piece, drawn like the 3D one (StarArt, 2026-10-29 user; the island's kind, #101)
		PieceArt.draw_2d(piece_kind, stamp_row, Vector2(w * 0.5, STAR_R + 4.0), STAR_R, piece_slot)


## Closes now: the touch of this same frame already reaches what is behind (IGNORE before the free).
func close() -> void:
	_close(Signal())


func _close(then: Signal) -> void:
	if closed:
		return
	closed = true
	for c: Control in [self, dim, card, map_button, stay_button]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	queue_free()
	if not then.is_null():
		then.emit()
