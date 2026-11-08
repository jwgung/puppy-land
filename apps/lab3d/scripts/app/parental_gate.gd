## 보호자 확인 (parental gate, #77 Q2/Q4): before the island's offer (and, later, before the AI question
## button is turned on again). A sum a child of this app's age does not do in the head: a × b + c, a
## 12..19, b 3..9, c 10..49 (answers 46..220), new each time, typed on the number keys (0..9, 지우기,
## 확인). A wrong answer brings a new sum; the third wrong one closes the gate. Nothing typed is kept.
## The numbers are the guardian's: the one place the app shows numbers to read (the "no numbers on
## screen" rule is the child's).
class_name ParentalGate
extends GuardianModal

signal passed

const TRIES := 3
const MAX_DIGITS := 3
const KEY_SIZE := Vector2(104.0, 78.0)
const KEY_FONT := 36
const KEY_GAP := 12
const SUM_SIZE := 54
const ANSWER_SIZE := Vector2(260.0, 82.0)
const LEFT_WIDTH := 420.0

var a := 0
var b := 0
var c := 0
var typed := ""
var wrong := 0
var sum_label: Label
var answer_label: Label
var note_label: Label
## Key text -> its button (tests press them).
var keys: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _init() -> void:
	super()
	name = "ParentalGate"
	rng.randomize()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.custom_minimum_size.x = LEFT_WIDTH
	left.add_child(GuardianModal.text_label(Locale.t("guardian.gate_title"), GuardianModal.TITLE_SIZE, true))
	left.add_child(GuardianModal.text_label(Locale.t("guardian.gate_lead"), GuardianModal.LINE_SIZE - 2, false, UiTheme.MUTED, LEFT_WIDTH))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	left.add_child(spacer)
	sum_label = GuardianModal.text_label("", SUM_SIZE, true)
	sum_label.name = "Sum"
	left.add_child(sum_label)
	var answer := PanelContainer.new()
	answer.name = "Answer"
	answer.custom_minimum_size = ANSWER_SIZE
	answer.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	answer.add_theme_stylebox_override("panel", UiTheme.outlined_box(UiTheme.WHITE, UiTheme.DIALOGUE_LINE, 16, Vector2(16, 6), 4, 0))
	answer_label = GuardianModal.text_label("", 48, true)
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	answer.add_child(answer_label)
	left.add_child(answer)
	note_label = GuardianModal.text_label(Locale.t("guardian.gate_note"), GuardianModal.LINE_SIZE - 2, false, UiTheme.MUTED, LEFT_WIDTH)
	note_label.name = "Note"
	left.add_child(note_label)
	row.add_child(left)
	var grid := GridContainer.new()
	grid.name = "Keys"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", KEY_GAP)
	grid.add_theme_constant_override("v_separation", KEY_GAP)
	grid.size_flags_vertical = Control.SIZE_SHRINK_END
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "erase", "0", "ok"]:
		var words: String = Locale.t("guardian.erase") if key == "erase" else (Locale.t("guardian.ok") if key == "ok" else key)
		var button := Ui.button(words, "TitleStartButton" if key == "ok" else "TitleButton", KEY_SIZE.y)
		button.name = "Key_%s" % key
		button.custom_minimum_size = KEY_SIZE
		button.add_theme_font_size_override("font_size", KEY_FONT if key.is_valid_int() else 26)
		button.pressed.connect(press.bind(key))
		keys[key] = button
		grid.add_child(button)
	row.add_child(grid)
	set_body(row)
	new_sum()


## A new sum (the answer cleared).
func new_sum() -> void:
	a = rng.randi_range(12, 19)
	b = rng.randi_range(3, 9)
	c = rng.randi_range(10, 49)
	typed = ""
	_show()


func answer() -> int:
	return a * b + c


## A key: a digit (up to MAX_DIGITS), "erase" or "ok".
func press(key: String) -> void:
	match key:
		"erase":
			typed = typed.left(-1)
		"ok":
			if typed == "":
				return
			if int(typed) == answer():
				passed.emit()
				queue_free()
				return
			wrong += 1
			if wrong >= TRIES:
				close()
				return
			note_label.text = Locale.t("guardian.gate_wrong")
			new_sum()
			return
		_:
			if typed.length() < MAX_DIGITS:
				typed += key
	_show()


func _show() -> void:
	sum_label.text = "%d × %d + %d =" % [a, b, c]
	answer_label.text = typed
