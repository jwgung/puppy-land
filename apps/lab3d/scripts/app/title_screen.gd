## The title screen (2026-10-29 user decision): shown on every launch after the boot splash, before
## the island. Behind it the map's own 3D island (MapIsland: land, sea, landmarks) by day, seen from
## a 3/4 view that slowly turns round it (no names, no Puppy riddle, no input to the map). In the
## middle the boot splash's logo (assets/icon/splash.png: the three faces over the red ribbon
## "빵고양이 과학섬") bobbing gently, under it a big 시작하기 and, smaller, 이야기 다시 보기 and 설정.
##
## App decides where each button goes (시작하기: the prologue the first time, else the map) and when
## the title is skipped (a measurement, a direct --experiment, the settings' renderer restart, a
## --demo-story screenshot). The title only shows; it never touches progress, the story's marks or
## an experiment. Its cost is the map's (one island mesh + the sky, no labels, no characters).
##
## 섬 고르기 (#75; one way in since 2026-11-09, user "게임 시작이랑 섬 선택이 어색해" → A): with more
## than one island (from the first launch since 2026-11-13; before, once a voyage was due or seen, #118)
## 시작하기 opens the islands' map (IslandCards) over the turning island, the logo and the buttons hidden meanwhile; a card emits
## `island_chosen` (App: that island in use, its map). Before, with one island, 시작하기 goes straight
## to it. There is no separate 섬 고르기 button any more, and 이야기 다시 보기 moves onto each island's
## card then (`island_story_chosen`): with two islands the title's one could not say whose story.
class_name TitleScreen
extends Control

signal start_requested
signal story_requested
signal settings_requested
signal island_chosen(island: String)
## 이야기 다시 보기 on an island's card: that island's story (2026-11-09).
signal island_story_chosen(island: String)

## Headless test runs build App without a title unless a check turns it on (like Story.app_may_enable).
static var app_may_show := true

## The logo: the three faces over the red ribbon, one picture for every language, and the app's name
## over the ribbon as text in the language (title_label, ui.json `app.title`; #128, 2026-11-12 user:
## "문자열 처리하면 번역하기도 좋잖아"; until then one picture per language with the name painted in).
## The boot splash shows no picture (only the sky colour; 2026-11-02 user: "타이틀에 또 빈칸생겼다").
const LOGO := preload("res://assets/icon/splash.png")
## Where the ribbon's band is in the picture (fractions; splash_banner.py prints it as RIBBON).
const RIBBON := Rect2(0.12, 0.6214, 0.76, 0.2632)
## The name's letters: TITLE_SIZE of the band's height, smaller until the name fits in TITLE_SHARE of
## the logo's width (the band is 0.76); cream with the characters' brown outline (TITLE_OUTLINE of the
## logo's width) and a dark red drop (TITLE_DROP), as the picture's name was drawn.
const TITLE_SIZE := 0.62
const TITLE_SHARE := 0.68
const TITLE_OUTLINE := 0.010
const TITLE_DROP := 0.0042
const TITLE_DROP_COLOR := Color8(170, 46, 40)
## The camera: a little lower than the map's (-55 deg) so the island fills the screen round the logo,
## turning once every TURN_S seconds (slow, a calm postcard).
const PITCH_DEG := -36.0
const DISTANCE := 25.0
const TURN_S := 100.0
const START_YAW_DEG := 20.0
## The logo: LOGO_SHARE of the screen width, at most LOGO_MAX units wide; it bobs BOB_UNITS up and
## down at BOB_HZ.
const LOGO_SHARE := 0.56
const LOGO_MAX := 660.0
const LOGO_MIN := 320.0
const BOB_UNITS := 7.0
const BOB_HZ := 0.45
const GAP := 18.0

var view: View3D
var map: MapIsland
var env: WorldEnvironment
var logo: TextureRect
var title_label: Label
var start_button: Button
var story_button: Button
var settings_button: Button
var island_cards: IslandCards = null
var _buttons: VBoxContainer
var _clock := 0.0
var _logo_top := 0.0


func _ready() -> void:
	name = "TitleScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view = View3D.new()
	view.name = "TitleView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE   # a postcard: no finger turns or moves it
	add_child(view)
	var world := Node3D.new()
	world.name = "TitleIsland"
	view.set_world(world)
	env = MapIsland.make_environment()
	view.viewport.add_child(env)
	var island := Island.current()
	map = MapIsland.new(island)
	map.build(world, island.map_spots())
	MapIsland.light_no_spots()   # day: no spot lit (the night map's)
	view.rig.configure({
		"target": [0.0, IslandHomeScreen.TARGET_Y, 0.0],
		"distance": DISTANCE,
		"distance_range": [DISTANCE, DISTANCE],
		"yaw_range_deg": [-180.0, 180.0],
		"pitch_range_deg": [PITCH_DEG, PITCH_DEG],
		"default_mode": "three_quarter",
		"views": {"three_quarter": {"yaw_deg": START_YAW_DEG, "pitch_deg": PITCH_DEG}},
	})

	logo = TextureRect.new()
	logo.name = "TitleLogo"
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	title_label = Label.new()
	title_label.name = "TitleName"
	title_label.text = Locale.t("app.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var letters := LabelSettings.new()
	letters.font = UiTheme.bold_font()
	letters.font_color = UiTheme.DIALOGUE_PAPER
	letters.outline_color = ArtPalette.OUTLINE
	letters.shadow_color = TITLE_DROP_COLOR
	letters.shadow_size = 0
	title_label.label_settings = letters
	logo.add_child(title_label)

	_buttons = Ui.vbox(14)
	_buttons.name = "TitleButtons"
	_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_buttons)
	start_button = Ui.button(Locale.t("title.start"), "TitleStartButton", 92)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.x = 300.0
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_start)
	_buttons.add_child(start_button)
	var row := Ui.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_buttons.add_child(row)
	story_button = Ui.button(Locale.t("common.replay_story"), "TitleButton", 56)
	story_button.name = "StoryButton"
	story_button.pressed.connect(story_requested.emit)
	row.add_child(story_button)
	# With two islands the story to see again is chosen on the island's card (IslandCards), not here
	# (2026-11-09 user: "이야기 다시보기도 애매해짐": which island's?).
	story_button.visible = not picks_island()
	settings_button = Ui.button(Locale.t("common.settings"), "TitleButton", 56)
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size.x = 110.0
	settings_button.pressed.connect(settings_requested.emit)
	row.add_child(settings_button)

	_layout()
	resized.connect(_layout)


## The logo and the buttons, one block centred a little above the middle (the island shows round them).
func _layout() -> void:
	if logo == null or size.x < 1.0:
		return
	var aspect := float(logo.texture.get_height()) / logo.texture.get_width()
	var buttons := _buttons.get_combined_minimum_size()
	var width := clampf(size.x * LOGO_SHARE, LOGO_MIN, LOGO_MAX)
	# A short screen: the logo gives way so the block fits (the buttons keep their size).
	width = minf(width, (size.y - buttons.y - GAP - BOB_UNITS * 2.0 - 40.0) / aspect)
	var height := width * aspect
	var block := height + GAP + buttons.y
	_logo_top = maxf(BOB_UNITS + 8.0, (size.y - block) * 0.45)
	logo.size = Vector2(width, height)
	_fit_title()
	logo.position = Vector2((size.x - width) * 0.5, _logo_top)
	_buttons.size = buttons
	_buttons.position = Vector2((size.x - buttons.x) * 0.5, _logo_top + height + GAP)


## The name on the ribbon at the logo's size (see TITLE_SIZE).
func _fit_title() -> void:
	var w := logo.size.x
	var letters := title_label.label_settings
	var font_size := int(RIBBON.size.y * logo.size.y * TITLE_SIZE)
	while font_size > 8 and letters.font.get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > w * TITLE_SHARE:
		font_size -= 1
	letters.font_size = font_size
	letters.outline_size = maxi(2, roundi(w * TITLE_OUTLINE))
	letters.shadow_offset = Vector2(0.0, w * TITLE_DROP)
	title_label.position = RIBBON.position * logo.size
	title_label.size = RIBBON.size * logo.size


func _process(delta: float) -> void:
	_clock += delta
	# The slow turn: the rig's own orbit (it wraps all the way round), never a finger's.
	view.rig.orbit(Vector2(-TAU / TURN_S * delta / CameraRig.ORBIT_RAD_PER_UNIT, 0.0))
	logo.position.y = _logo_top - BOB_UNITS * sin(TAU * BOB_HZ * _clock)


## 시작하기: the islands' map once there is more than one island to go to, else the island itself.
func _on_start() -> void:
	if picks_island():
		show_islands()
	else:
		start_requested.emit()


## 시작하기 opens the islands' map whenever the app has more than one island (2026-11-13 user "처음
## 시작할 때 왜 섬 고르기 없이 바로 뉴턴섬으로 감?": from the first launch, the next islands locked;
## until then only once a voyage was seen or was due, #118). The first island's 출발! plays its first
## story on its map as before.
static func picks_island() -> bool:
	return Island.ids().size() > 1


## The logo's rect and the buttons' rects (tests: inside the screen, no overlap).
func rects() -> Array[Rect2]:
	var out: Array[Rect2] = [logo.get_rect(), start_button.get_global_rect(), settings_button.get_global_rect()]
	if story_button.visible:
		out.insert(2, story_button.get_global_rect())
	return out


## 섬 고르기: the islands' map (IslandCards, #116) over the title; the title's own island view, logo
## and buttons hide meanwhile (one 3D view drawn at a time).
func show_islands() -> void:
	if island_cards != null:
		return
	island_cards = IslandCards.new()
	island_cards.chosen.connect(island_chosen.emit)
	island_cards.story_chosen.connect(island_story_chosen.emit)
	island_cards.back_requested.connect(hide_islands)
	add_child(island_cards)
	view.visible = false
	logo.visible = false
	_buttons.visible = false


## Back from the islands' map to the title (← 돌아가기, Android back). True when it was open.
func hide_islands() -> bool:
	if island_cards == null:
		return false
	island_cards.queue_free()
	island_cards = null
	view.visible = true
	logo.visible = true
	_buttons.visible = true
	return true
