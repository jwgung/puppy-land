## The island's offer to the guardian (#77, 2026-11-08 user-approved mock), after ParentalGate: the
## island's picture, its name, what buying changes (said plainly, to the guardian), the store's own
## price, 구매 and 닫기, and "결제는 Google Play에서 해요". 구매 opens the store's purchase screen
## (IslandStore.buy). A purchase waiting for approval shows "결제 승인을 기다리고 있어요" instead of the
## buttons; a bought island closes the offer. No store or no price yet: 구매 cannot be pressed and the
## offer says payment is not possible now.
class_name IslandOffer
extends GuardianModal

const PICTURE_SIZE := Vector2(400.0, 288.0)
const RIGHT_WIDTH := 520.0
const NAME_SIZE := 50
const PRICE_SIZE := 50
const BUY_SIZE := Vector2(230.0, 84.0)
const CLOSE_WIDTH := 200.0
const ROW_GAP := 44
const BUTTON_GAP := 26
const WAITING_PAPER := Color("fdf1d8")
const WAITING_SIZE := 28
## The price is Play's text in the guardian's currency: its signs are kept in the font subset
## (tools/subset_font.sh reads them here).
const CURRENCY_SIGNS := "₩$€£¥₹₽₺₫₱฿₪₴₸₦₡₲₵₭₮"

var island_id := ""
var price_label: Label
var buy_button: Button
var close_text_button: Button
var buttons: HBoxContainer
var waiting_box: PanelContainer
var message: Label
var _picture_rect: TextureRect


## 보호자 → the gate → (passed) this offer, both over `host`.
static func open_for_guardian(host: Control, id: String) -> ParentalGate:
	var gate := ParentalGate.new()
	host.add_child(gate)
	gate.passed.connect(func() -> void:
		if is_instance_valid(host):
			host.add_child(IslandOffer.new(id)))
	return gate


func _init(id: String) -> void:
	super()
	name = "IslandOffer"
	island_id = id
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_GAP)
	var frame := Panel.new()
	frame.name = "Picture"
	frame.custom_minimum_size = PICTURE_SIZE
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var frame_style := UiTheme.outlined_box(MapIsland.sea_color(), UiTheme.DIALOGUE_LINE, 16, Vector2.ZERO, 4, 0)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var picture := TextureRect.new()
	picture.name = "Island"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(picture)
	var edge := Panel.new()   # the brown outline over the picture (the frame's own is under it)
	edge.name = "Edge"
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var edge_style := UiTheme.outlined_box(Color.TRANSPARENT, UiTheme.DIALOGUE_LINE, 16, Vector2.ZERO, 4, 0)
	edge.add_theme_stylebox_override("panel", edge_style)
	frame.add_child(edge)
	row.add_child(frame)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.custom_minimum_size.x = RIGHT_WIDTH
	right.add_child(GuardianModal.text_label(IslandCards.island_name(id), NAME_SIZE, true))
	right.add_child(GuardianModal.text_label(Locale.t("island.%s.offer" % id), GuardianModal.LINE_SIZE, false, UiTheme.INK, RIGHT_WIDTH))
	right.add_child(GuardianModal.text_label(Locale.t("guardian.offer_daily"), GuardianModal.LINE_SIZE, false, UiTheme.INK, RIGHT_WIDTH))
	right.add_child(GuardianModal.text_label(Locale.t("guardian.offer_once"), GuardianModal.LINE_SIZE, false, UiTheme.MUTED, RIGHT_WIDTH))
	price_label = GuardianModal.text_label("", PRICE_SIZE, true)
	price_label.name = "Price"
	right.add_child(price_label)
	buttons = HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", BUTTON_GAP)
	buy_button = Ui.button(Locale.t("guardian.buy"), "TitleStartButton", BUY_SIZE.y)
	buy_button.name = "Buy"
	buy_button.custom_minimum_size = BUY_SIZE
	buy_button.pressed.connect(_buy)
	buttons.add_child(buy_button)
	close_text_button = Ui.button(Locale.t("common.close"), "TitleButton", BUY_SIZE.y)
	close_text_button.name = "CloseWide"
	close_text_button.custom_minimum_size = Vector2(CLOSE_WIDTH, BUY_SIZE.y)
	close_text_button.add_theme_font_size_override("font_size", GuardianModal.BUTTON_FONT)
	close_text_button.pressed.connect(close)
	buttons.add_child(close_text_button)
	waiting_box = PanelContainer.new()
	waiting_box.name = "Waiting"
	waiting_box.add_theme_stylebox_override("panel", UiTheme.outlined_box(WAITING_PAPER, UiTheme.DIALOGUE_LINE, 18, Vector2(24, 16), 3, 0))
	waiting_box.add_child(GuardianModal.text_label(Locale.t("guardian.waiting"), WAITING_SIZE, true))
	right.add_child(waiting_box)   # above 닫기 (the mock): in place of the price
	right.add_child(buttons)
	message = GuardianModal.text_label("", GuardianModal.LINE_SIZE - 2, false, UiTheme.MUTED, RIGHT_WIDTH)
	message.name = "Message"
	right.add_child(message)
	row.add_child(right)
	set_body(row)
	_picture_rect = picture


func _ready() -> void:
	_picture_rect.texture = IslandCards.thumbnail(self, island_id)
	if IslandStore.instance != null:
		IslandStore.instance.changed.connect(refresh)
		IslandStore.instance.failed.connect(_on_failed)
	refresh()
	super()


## The offer as the store says now: bought (closes), waiting, a price (구매), or no store.
func refresh() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if IslandStore.owns(island_id):
		close()
		return
	var waiting := IslandStore.waiting(island_id)
	var price := IslandStore.price(island_id)
	price_label.text = price
	price_label.visible = price != "" and not waiting
	waiting_box.visible = waiting
	buy_button.visible = not waiting
	buy_button.disabled = price == ""
	if waiting:
		message.text = ""
	elif price == "":
		message.text = Locale.t("guardian.unavailable")
	elif message.text == "" or message.text == Locale.t("guardian.unavailable"):
		message.text = Locale.t("guardian.store_note")
	_layout()


func _buy() -> void:
	message.text = Locale.t("guardian.store_note")
	if IslandStore.instance != null:
		IslandStore.instance.buy(island_id)
	else:
		_on_failed(IslandStore.UNAVAILABLE)


func _on_failed(reason: String) -> void:
	if not is_inside_tree():
		return
	match reason:
		IslandStore.FAILED:
			message.text = Locale.t("guardian.failed")
		IslandStore.UNAVAILABLE:
			message.text = Locale.t("guardian.unavailable")
		_:
			message.text = Locale.t("guardian.store_note")
