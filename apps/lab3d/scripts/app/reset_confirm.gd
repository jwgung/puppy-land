## 섬·장소 기록 지우기 (2026-11-16 user): the question before one island's or one lab's record is erased,
## always behind the parental gate (open_for_guardian). The island's comes from the gear on its tag on
## 섬 고르기 (IslandCards); a lab's from the red button at the end of its note (ExperimentScreen). The
## question (처음부터 다시 할까?) names the island or the lab, says what goes and that it cannot be undone
## and, for an island whose next island is open now, that it closes again; 아니 keeps everything, 다시
## 하기 erases (erase: the store, then the sync) and tells `confirmed`.
class_name ResetConfirm
extends GuardianModal

signal confirmed

const ISLAND := "island"
const SPOT := "spot"
const WIDTH := 560.0
const GAP := 12
const NAME_SIZE := 30
const BUTTON_SIZE := Vector2(200.0, 70.0)
const BUTTON_GAP := 20
## The warning lines' box (soft orange).
const WARN_PAPER := Color("ffe9d8")
const WARN_LINE := Color("e8a37a")
const WARN_RADIUS := 12
const WARN_PAD := Vector2(14, 8)

var kind := ""
var target := ""
var name_label: Label
var relock_label: Label
var yes_button: Button
var no_button: Button


## The parental gate over `host`, then (passed) the question for `kind` (ISLAND / SPOT) `id`; its
## 지우기 erases and calls `on_erased`. Nothing is erased before both.
static func open_for_guardian(host: Control, what: String, id: String, on_erased := Callable()) -> ParentalGate:
	var gate := ParentalGate.new()
	host.add_child(gate)
	gate.passed.connect(func() -> void:
		if is_instance_valid(host):
			var question := ResetConfirm.new(what, id)
			question.confirmed.connect(func() -> void:
				if on_erased.is_valid():
					on_erased.call())
			host.add_child(question))
	return gate


func _init(what: String, id: String) -> void:
	super()
	name = "ResetConfirm"
	kind = what
	target = id
	var island := what == ISLAND
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	column.custom_minimum_size.x = WIDTH
	column.add_child(GuardianModal.text_label(Locale.t("reset.title"), GuardianModal.TITLE_SIZE - 4, true, UiTheme.INK, WIDTH))
	name_label = GuardianModal.text_label(IslandCards.island_name(id) if island else ExperimentRegistry.kid_text(ExperimentRegistry.find(id), "place"),
		NAME_SIZE, true, UiTheme.INK, WIDTH)
	name_label.name = "Target"
	column.add_child(name_label)
	column.add_child(GuardianModal.text_label(Locale.t("reset.island_detail") if island else Locale.t("reset.spot_detail"),
		GuardianModal.LINE_SIZE, false, UiTheme.INK, WIDTH))
	var warn := PanelContainer.new()
	warn.name = "Warn"
	warn.add_theme_stylebox_override("panel", UiTheme.outlined_box(WARN_PAPER, WARN_LINE, WARN_RADIUS, WARN_PAD, 2, 0))
	var lines := VBoxContainer.new()
	warn.add_child(lines)
	relock_label = GuardianModal.text_label(Locale.t("reset.relock"), GuardianModal.LINE_SIZE - 2, true, UiTheme.INK, WIDTH - 2.0 * WARN_PAD.x)
	relock_label.name = "Relock"
	relock_label.visible = island and closing_island(id) != ""
	lines.add_child(relock_label)
	lines.add_child(GuardianModal.text_label(Locale.t("reset.undo"), GuardianModal.LINE_SIZE - 2, false, UiTheme.INK, WIDTH - 2.0 * WARN_PAD.x))
	column.add_child(warn)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", BUTTON_GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	no_button = Ui.button(Locale.t("reset.no"), "TitleButton", BUTTON_SIZE.y)
	no_button.name = "No"
	no_button.custom_minimum_size = BUTTON_SIZE
	no_button.add_theme_font_size_override("font_size", GuardianModal.BUTTON_FONT)
	no_button.pressed.connect(close)
	row.add_child(no_button)
	yes_button = Ui.button(Locale.t("reset.yes"), "TitleStartButton", BUTTON_SIZE.y)
	yes_button.name = "Yes"
	yes_button.custom_minimum_size = BUTTON_SIZE
	yes_button.add_theme_font_size_override("font_size", GuardianModal.BUTTON_FONT)
	yes_button.pressed.connect(_yes)
	row.add_child(yes_button)
	column.add_child(row)
	set_body(column)


## The island that opens after `island_id` and is open now ("" when none): erasing it closes that one.
static func closing_island(island_id: String) -> String:
	if Island.dev_open():
		return ""
	var progress := ProgressStore.load()
	for id in Island.ids():
		if Island.opens_after(str(id)) == island_id and Island.is_open(str(id), progress):
			return str(id)
	return ""


## The record of `what` `id` goes: the store (with its erase time), then the sync sends it at once.
static func erase(what: String, id: String) -> void:
	if what == ISLAND:
		ProgressStore.reset_island(id)
	elif what == SPOT:
		ProgressStore.reset_spot(id)
	else:
		return
	if CloudSync.instance != null:
		CloudSync.instance.mark_partial_reset(what, id)


func _yes() -> void:
	if is_queued_for_deletion():
		return
	erase(kind, target)
	confirmed.emit()
	close()
