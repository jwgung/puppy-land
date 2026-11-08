## 보호자 확인 (parental gate, #77 Q2/Q4): before the island's offer (and, later, before the AI question
## button is turned on again). A sum a child of this app's age does not do in the head: a × b + c, a
## 12..19, b 3..9, c 10..49 (answers 46..220), new each time, typed with the device's number keyboard
## (2026-11-08 user-approved mock: no on-screen keys) and 확인 or the keyboard's done key. A wrong
## answer brings a new sum; the third wrong one closes the gate. Nothing typed is kept.
## The numbers are the guardian's: the one place the app shows numbers to read (the "no numbers on
## screen" rule is the child's).
class_name ParentalGate
extends GuardianModal

signal passed

const TRIES := 3
const MAX_DIGITS := 3
const SUM_SIZE := 50
const FIELD_SIZE := Vector2(170.0, 76.0)
const FIELD_FONT := 44
const OK_SIZE := Vector2(150.0, 76.0)
const WIDTH := 640.0

var a := 0
var b := 0
var c := 0
var wrong := 0
var sum_label: Label
var field: LineEdit
var ok_button: Button
var note_label: Label
var rng := RandomNumberGenerator.new()


func _init() -> void:
	super()
	name = "ParentalGate"
	rng.randomize()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size.x = WIDTH
	column.add_child(GuardianModal.text_label(Locale.t("guardian.gate_title"), GuardianModal.TITLE_SIZE, true))
	column.add_child(GuardianModal.text_label(Locale.t("guardian.gate_lead"), GuardianModal.LINE_SIZE - 2, false, UiTheme.MUTED, WIDTH))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	sum_label = GuardianModal.text_label("", SUM_SIZE, true)
	sum_label.name = "Sum"
	sum_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sum_label)
	field = LineEdit.new()
	field.name = "Answer"
	field.custom_minimum_size = FIELD_SIZE
	field.max_length = MAX_DIGITS
	field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.context_menu_enabled = false
	field.add_theme_font_override("font", UiTheme.bold_font())
	field.add_theme_font_size_override("font_size", FIELD_FONT)
	field.add_theme_color_override("font_color", UiTheme.INK)
	field.add_theme_color_override("caret_color", UiTheme.INK)
	var box := UiTheme.outlined_box(UiTheme.WHITE, UiTheme.DIALOGUE_LINE, 16, Vector2(14, 4), 4, 0)
	field.add_theme_stylebox_override("normal", box)
	field.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	field.text_changed.connect(_digits_only)
	field.text_submitted.connect(func(_text: String) -> void: submit())
	row.add_child(field)
	ok_button = Ui.button(Locale.t("guardian.ok"), "TitleStartButton", OK_SIZE.y)
	ok_button.name = "Ok"
	ok_button.custom_minimum_size = OK_SIZE
	ok_button.add_theme_font_size_override("font_size", GuardianModal.BUTTON_FONT)
	ok_button.pressed.connect(submit)
	row.add_child(ok_button)
	column.add_child(row)
	note_label = GuardianModal.text_label(Locale.t("guardian.gate_note"), GuardianModal.LINE_SIZE - 2, false, UiTheme.MUTED, WIDTH)
	note_label.name = "Note"
	column.add_child(note_label)
	set_body(column)
	new_sum()


func _ready() -> void:
	super()
	field.grab_focus()   # the keyboard comes up with the gate


## A new sum (the answer cleared).
func new_sum() -> void:
	a = rng.randi_range(12, 19)
	b = rng.randi_range(3, 9)
	c = rng.randi_range(10, 49)
	sum_label.text = "%d × %d + %d =" % [a, b, c]
	field.text = ""


func answer() -> int:
	return a * b + c


## 확인 (or the keyboard's done key): the right answer passes, a wrong one brings a new sum.
func submit() -> void:
	if field.text == "":
		return
	if int(field.text) == answer():
		passed.emit()
		queue_free()
		return
	wrong += 1
	if wrong >= TRIES:
		close()
		return
	note_label.text = Locale.t("guardian.gate_wrong")
	new_sum()
	if field.is_inside_tree():
		field.grab_focus()


## Digits only (a hardware keyboard or a pasted text can bring others).
func _digits_only(text: String) -> void:
	var digits := ""
	for ch in text:
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits != text:
		var caret := field.caret_column
		field.text = digits.left(MAX_DIGITS)
		field.caret_column = mini(caret, field.text.length())
