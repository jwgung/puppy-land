## Settings: quality tier (ported from the spike's "Q" button), sound (효과음 / 배경 음악, SoundBoard),
## the story (이야기 다시 보기, 처음부터 다시 하기). No 개발자 card (2026-10-31 user: the fps overlay is not a
## child's setting; measurements turn it on with --fps=1). The on/off settings are
## big check boxes (2026-10-29 user request: check boxes, not switches; UiTheme "CheckBox", a 64-unit
## row, the box 44 units). A vertical drag anywhere on the page scrolls it (Ui.scroller: DragScroll).
## Switching between low (Compatibility renderer) and medium/high (Mobile renderer) restarts the app.
class_name SettingsScreen
extends Control

signal back_requested
## 이야기 다시 보기: the map opens and the story's prologue plays again.
signal story_requested
## 처음부터 다시 하기, confirmed: every saved progress is gone (ProgressStore.reset_all); the app goes
## back to the start (App: the title, or the map that plays the prologue).
signal restart_requested


## Applies a tier; true when the app is restarting. Quality.set_tier unless a test replaces it.
var set_tier := Callable()
var _selected := ""
var _buttons: Dictionary = {}
var _apply: Button
var _notice: Label
## The sound check boxes (tests press them): effects and music, each mutes its own bus.
var sfx_switch: CheckBox
var music_switch: CheckBox
## 처음부터 다시 하기 and its confirmation (a second step: the question with 다시 하기 / 아니요).
var restart_button: Button
var restart_confirm: Control
var _scroll: ScrollContainer
var restart_yes: Button
var restart_no: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_selected = Quality.tier
	if not set_tier.is_valid():
		set_tier = Quality.set_tier
	var layout := Ui.vbox(0)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	var bar := Ui.panel("TopBar")
	layout.add_child(bar)
	var row := Ui.hbox(12)
	bar.add_child(row)
	var back := Ui.button(Locale.t("settings.back"), "FlatButton", 60)
	back.pressed.connect(back_requested.emit)
	row.add_child(back)
	row.add_child(Ui.label(Locale.t("common.settings"), "HeadingLabel"))

	var scroll := Ui.scroller()
	_scroll = scroll
	layout.add_child(scroll)
	var pad := Ui.margin(24)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	var column := Ui.vbox(16)
	pad.add_child(column)

	var quality_card := Ui.panel()
	var quality := Ui.vbox(12)
	quality_card.add_child(quality)
	quality.add_child(Ui.label(Locale.t("settings.quality"), "SectionLabel"))
	var group := ButtonGroup.new()
	for tier in Quality.TIER_ORDER:
		var option := Ui.button("", "ChipButton", 0)
		option.toggle_mode = true
		option.button_group = group
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var text := Ui.vbox(4)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
		var title := Ui.label(Locale.map("settings.tiers")[tier], "HeadingLabel")
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var detail := Ui.label(Locale.map("settings.tier_notes")[tier], "MutedLabel", true)
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_child(title)
		text.add_child(detail)
		var holder := MarginContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["left", "right", "top", "bottom"]:
			holder.add_theme_constant_override("margin_" + side, 16)
		holder.add_child(text)
		option.add_child(holder)
		holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		option.resized.connect(func() -> void: option.custom_minimum_size.y = holder.get_combined_minimum_size().y)
		holder.minimum_size_changed.connect(func() -> void: option.custom_minimum_size.y = holder.get_combined_minimum_size().y)
		option.pressed.connect(_select.bind(tier))
		quality.add_child(option)
		_buttons[tier] = option
	_notice = Ui.label("", "MutedLabel", true)
	quality.add_child(_notice)
	_apply = Ui.button(Locale.t("settings.apply"), "PrimaryButton", 64)
	_apply.pressed.connect(_apply_tier)
	quality.add_child(_apply)
	column.add_child(quality_card)
	column.add_child(_build_sound_card())
	column.add_child(_build_story_card())

	_select(_selected)


## 소리: two switches, both on by default (kept in user://settings.cfg by SoundBoard).
func _build_sound_card() -> Control:
	var card := Ui.panel()
	var box := Ui.vbox(8)
	card.add_child(box)
	box.add_child(Ui.label(Locale.t("settings.sound"), "SectionLabel"))
	var board := SoundBoard.instance()
	sfx_switch = check_box(Locale.t("settings.sfx"))
	sfx_switch.name = "SfxSwitch"
	music_switch = check_box(Locale.t("settings.music"))
	music_switch.name = "MusicSwitch"
	for entry in [[sfx_switch, "sfx_on", "set_sfx_on"], [music_switch, "music_on", "set_music_on"]]:
		var check: CheckBox = entry[0]
		check.button_pressed = board == null or bool(board.get(entry[1]))
		check.disabled = board == null
		if board != null:
			check.toggled.connect(Callable(board, entry[2]))
		box.add_child(check)
	return card


## 이야기: the story's prologue again (the map plays it; nothing found is lost).
func _build_story_card() -> Control:
	var card := Ui.panel()
	var box := Ui.vbox(8)
	card.add_child(box)
	box.add_child(Ui.label(Locale.t("settings.story"), "SectionLabel"))
	var replay := Ui.button(Locale.t("common.replay_story"), "", 60)
	replay.name = "StoryReplay"
	replay.pressed.connect(story_requested.emit.call_deferred)   # after the tap (see restart())
	box.add_child(replay)
	restart_button = Ui.button(Locale.t("settings.restart"), "", 60)
	restart_button.name = "RestartButton"
	restart_button.pressed.connect(func() -> void: show_restart_confirm(true))
	box.add_child(restart_button)
	# The confirmation: nothing is erased until 다시 하기 is pressed here.
	var confirm := Ui.panel("SoftCard")
	confirm.name = "RestartConfirm"
	confirm.visible = false
	var ask := Ui.vbox(10)
	confirm.add_child(ask)
	ask.add_child(Ui.label(Locale.t("settings.restart_question"), "HeadingLabel", true))
	ask.add_child(Ui.label(Locale.t("settings.restart_detail"), "MutedLabel", true))
	var row := Ui.hbox(12)
	ask.add_child(row)
	restart_yes = Ui.button(Locale.t("settings.restart_yes"), "PrimaryButton", 60)
	restart_yes.name = "RestartYes"
	restart_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_yes.pressed.connect(restart)
	row.add_child(restart_yes)
	restart_no = Ui.button(Locale.t("settings.restart_no"), "", 60)
	restart_no.name = "RestartNo"
	restart_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_no.pressed.connect(func() -> void: show_restart_confirm(false))
	row.add_child(restart_no)
	box.add_child(confirm)
	restart_confirm = confirm
	return card


## A big check box in the island style (UiTheme "CheckBox": the box 44 units, the row 64 units).
static func check_box(text: String, on := false) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = on
	check.custom_minimum_size = Vector2(0, 64)
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.add_press_bounce(check)
	check.toggled.connect(func(_on: bool) -> void: SoundBoard.play(&"tap"))
	return check


## Shows (or hides) the question under 처음부터 다시 하기; while it shows, the button itself hides.
func show_restart_confirm(on: bool) -> void:
	restart_confirm.visible = on
	restart_button.visible = not on
	if on and _scroll != null:
		_bring_confirm_in()


## The question is never below the page's end (once it has its size, a frame later).
func _bring_confirm_in() -> void:
	await get_tree().process_frame
	if is_instance_valid(restart_confirm) and restart_confirm.visible:
		_scroll.ensure_control_visible(restart_confirm)


## 다시 하기 (confirmed): the saved progress of the store in use is erased (the bench or test store in
## measurements and tests, never another file), the first-visit tips come back, and the app starts over.
func restart() -> void:
	if not restart_confirm.visible:
		return
	ProgressStore.reset_all()
	ExperimentScreen.reset_tips_shown()
	show_restart_confirm(false)
	# After this input pass: the tap came through the scroller's replay (DragScroll), and changing the
	# screen inside it crashed the app on the phone (2026-11-01, a native crash in the frame step).
	restart_requested.emit.call_deferred()


func _select(tier: String) -> void:
	_selected = tier
	for id in _buttons:
		_buttons[id].set_pressed_no_signal(id == tier)
	_apply.disabled = tier == Quality.tier
	if tier == Quality.tier:
		_notice.text = Locale.t("settings.quality_current")
	elif Quality.needs_restart(tier):
		_notice.text = Locale.t("settings.quality_restarts")
	else:
		_notice.text = Locale.t("settings.quality_now")


func _apply_tier() -> void:
	# A restart reopens the settings screen: the marker is on disk before the restart can end this
	# process (on Android at once, 2026-11-01), and removed when Quality did not restart after all.
	var marker := FileAccess.open(App.RESUME_PATH, FileAccess.WRITE)
	if marker:
		marker.store_string("settings")
		marker.close()
	if not set_tier.call(_selected):
		DirAccess.remove_absolute(App.RESUME_PATH)
	_select(_selected)
