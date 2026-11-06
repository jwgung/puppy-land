## App root: theme, screen navigation (the title on launch -> island map -> experiment, settings from
## the title or the map; back returns to the map, or to the title from settings opened there and from
## the map; back on the title quits) and the fps overlay. The voyage to the next island (#75,
## VoyageScreen) plays between the first island's finale and the next island's map; 섬 고르기 on the
## title picks the island in use (TitleScreen, IslandCards).
## Landscape only (Task 2d): project.godot locks the screen to sensor landscape on Android and iOS.
## Launch args (command line or Android `opargs`, see Quality.all_args):
##   --experiment=<id>   open that experiment directly (measurements, screenshots)
##   --screen=settings   open the settings screen
##   --fps=1             show the fps overlay
##   --sound=0|1         0 = no sound and no sound setting written (SoundBoard; measurements default to 0)
##   --demo-title        the title screen even in a measurement (screenshots, its fps): the bench store,
##                       never the child's progress
##   --demo-story=<part> screenshots of the story in the bench store only (never the child's progress):
##                       prologue | clue:<id> | found:<id> | flight:<id> | finale | map[:<n>] (Story, _demo_story)
##   --progress=complete  writes the child's progress as all done, once (2026-11-02 user: "apk 다 깬걸로
##                       해줘. 보기 어렵다"): every stamp, the story's prologue, clues and finale seen, every
##                       piece flown and flag up, so every spot opens on a day map. For looking at the app.
##                       Not in the Play build (Quality.DEV_KEYS, like --island and --ask=show).
##   --island=<id>      the map of island <id> for this run only (an island in the making, #72: its spots
##                       need not be experiments yet): nothing saved, no story, the bench store; not in
##                       the Play build
##   --islands=open     every island of the list open for this run (an island in the making too, #75):
##                       its voyage, its card in 섬 고르기, its map; not in the Play build
## plus the experiment screen's --camera / --ctl-<id> / --sidebar / --scroll-to / --auto-release / --auto-drag.
class_name App
extends Control

const RESUME_PATH := "user://resume.txt"   # written by settings before Quality.set_tier() (a restart can end the process at once), removed when it did not restart
## Screen change (art direction): the new screen slides in from SLIDE_UNITS to the right and fades
## in over SLIDE_S. Only the screen's own position/modulate are tweened (no overlay layer).
const SLIDE_UNITS := 48.0
const SLIDE_S := 0.22

var _definitions: Array[Dictionary] = []
var _screen: Control
var _fps_label: Label
var _show_fps := false
var _settings_from_title := false
## Back on the title (tests replace it: quitting would end their run).
var quit := func() -> void: get_tree().quit()
## The process frame of the last Android back handled (-10: none yet). One press of Android back
## arrives twice in the same frame on Godot 4.7.2 (SM-X115, 2026-10-29): the activity's onBackPressed
## (GodotLib.back) and the KEYCODE_BACK key event each send NOTIFICATION_WM_GO_BACK_REQUEST. Without
## this the first took the lab to the map and the second quit the app from the map.
var _back_frame := -10


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The background is the clear color, not a full-screen rect: at native resolution one extra
	# full-screen layer costs SM-P200 the 60 fps budget (docs/ui-resolution.md).
	RenderingServer.set_default_clear_color(UiTheme.BACKGROUND)
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	_fps_label = Ui.label("", "FpsLabel")
	_fps_label.theme = theme
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	_fps_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_fps_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_fps_label)
	Bench.report.connect(_on_bench_report)

	_set_fps(Quality.cmdline_value("fps") == "1")   # measurements only (no setting since 2026-10-31)
	Locale.start()   # the child's language (saved), else the device's, else English
	_definitions = ExperimentRegistry.load_all()
	Island.dev_open = Quality.dev_value("islands") == "open"   # a developer switch: never in the Play build
	var dev_island := dev_island_of(Quality.all_args(), OS.has_feature("play"))
	if dev_island != "":
		Island.use_for_run(dev_island)
	# A measured map never raises the child's flags; another island's map never touches its progress.
	if Quality.cmdline_value("progress") == "bench" or demo_title(Quality.all_args()) or dev_island != "":
		ProgressStore.path = ProgressStore.BENCH_PATH
	if Quality.dev_value("progress") == "complete":   # a developer switch: never in the Play build
		complete_progress()
	# The story plays in the child's app only: never in a measurement (bench store, auto runs, silent).
	Story.enabled = Story.app_may_enable and not Story.measurement_run(Quality.all_args()) and dev_island == ""
	var demo := _demo_story(Quality.cmdline_value("demo-story"))

	var resume := ""
	if FileAccess.file_exists(RESUME_PATH):
		resume = FileAccess.get_file_as_string(RESUME_PATH).strip_edges()
		DirAccess.remove_absolute(RESUME_PATH)
	var requested := ExperimentRegistry.find(Quality.cmdline_value("experiment"))
	if demo.has("experiment"):
		requested = demo.experiment
	if resume == "settings" or Quality.cmdline_value("screen") == "settings":
		show_settings()
	elif not requested.is_empty():
		show_experiment(requested, {}, true)  # the launch args (--ctl-*, --camera) apply to this screen
	elif demo.has("islands"):
		show_title()
		(_screen as TitleScreen).show_islands()
	elif title_on_launch(Quality.all_args()):
		show_title()
	else:
		show_list()


## The title shows on every launch of the child's app (2026-10-29 user decision). A measurement
## (Story.measurement_run: bench store, auto runs, silent), a --demo-story screenshot, a direct
## --experiment / --screen launch and the settings' renderer restart (resume, handled before) open
## their screen as before. --demo-title shows it anyway (in the bench store).
static func title_on_launch(args: PackedStringArray) -> bool:
	if not TitleScreen.app_may_show:
		return false
	if demo_title(args):
		return true
	for arg in args:
		for prefix in ["--demo-story=", "--experiment=", "--screen="]:
			if arg.begins_with(prefix):
				return false
	return not Story.measurement_run(args)


## The island of --island=<id> when it is in the list ("" otherwise, and always in the Play build:
## `play`, Quality.dev_arg).
static func dev_island_of(args: PackedStringArray, play: bool) -> String:
	var id := Quality.dev_arg(args, "island", play)
	return id if id != "" and not Island.entry(id).is_empty() else ""


static func demo_title(args: PackedStringArray) -> bool:
	return Array(args).any(func(arg: String) -> bool: return arg.begins_with("--demo-title"))


## The title (on launch): 시작하기 = the prologue the first time (the map plays it), else the map;
## 이야기 다시 보기 = the prologue again (as the settings' entry); 설정 = the settings, back to the title.
func show_title() -> void:
	var screen := TitleScreen.new()
	screen.start_requested.connect(func() -> void: show_list())
	screen.story_requested.connect(func() -> void: show_list(true))
	screen.settings_requested.connect(func() -> void: show_settings(true))
	screen.island_chosen.connect(func(island: String) -> void:
		Island.set_current(island)
		show_list())
	_swap(screen, "title")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back_requested()


## Android back (the notification): one step back per press. A second request in the same or the
## next process frame is the same press (see _back_frame) and does nothing.
func go_back_requested() -> void:
	var frame := Engine.get_process_frames()
	if frame - _back_frame <= 1:
		return
	_back_frame = frame
	_go_back()


func _go_back() -> void:
	if _screen is ExperimentScreen:
		if not (_screen as ExperimentScreen).handle_back():   # an open box, card or sidebar closes first
			show_list()
	elif _screen is VoyageScreen:
		(_screen as VoyageScreen).skip()   # back skips the voyage (to the next island's map)
	elif _screen is TitleScreen and (_screen as TitleScreen).hide_islands():
		pass   # 섬 고르기's cards close first
	elif _screen is SettingsScreen:
		if _settings_from_title:
			show_title()
		else:
			show_list()
	elif _screen is IslandHomeScreen and (_screen as IslandHomeScreen).handle_back():
		pass   # Puppy's open box closed first (2026-10-29)
	elif _screen is IslandHomeScreen and TitleScreen.app_may_show:
		show_title()   # the map goes back to the title (2026-10-29 decision)
	else:
		quit.call()   # the title quits (and the map when the title may not show: tests)


## The home is the 3D island (Plan G2): tap a spot, the cat hops over, the experiment opens. The
## story's prologue plays over it the first time (or again from the settings: `replay`). Before it,
## the voyage to the next island when it is due (Story.voyage_due: that island opened after this
## one's finale), or on a replay of an island that has a voyage to it (#75).
func show_list(replay := false) -> void:
	var island := Island.current_id()
	if replay and Story.enabled and island != ProgressStore.FIRST_ISLAND and Story.has_voyage(island):
		show_voyage(island, true)
		return
	var due := Story.voyage_due(ProgressStore.load()) if not replay else ""
	if due != "":
		show_voyage(due)
		return
	_show_map(replay)


func _show_map(replay := false) -> void:
	var screen := IslandHomeScreen.new()
	screen.definitions = _definitions
	screen.play_prologue_on_open = Story.should_play_prologue(replay)
	screen.experiment_chosen.connect(show_experiment)
	screen.settings_requested.connect(show_settings)
	_swap(screen, "home")
	if screen.story != null:
		# The finale just played and the next island is open: the voyage there.
		screen.story.ended.connect(func(part: String) -> void:
			if part == "finale" and _screen == screen and Story.voyage_due(ProgressStore.load()) != "":
				show_list())


## The voyage to `island` (VoyageScreen); then that island's map, its prologue the first time (or
## again: `replay`, 이야기 다시 보기 there).
func show_voyage(island: String, replay := false) -> void:
	var screen := VoyageScreen.new(island)
	screen.finished.connect(func(_to: String) -> void: _show_map(replay))
	_swap(screen, "voyage")


func show_experiment(definition: Dictionary, state := {}, launch_args := false) -> void:
	var screen := ExperimentScreen.new()
	screen.setup(definition, state, launch_args)
	screen.back_requested.connect(show_list)
	_swap(screen, "")  # the screen resets Bench with the experiment's bench id


func show_settings(from_title := false) -> void:
	_settings_from_title = from_title
	var screen := SettingsScreen.new()
	# Settings opens from the map (Plan G2) or the title and goes back to where it opened.
	screen.back_requested.connect(func() -> void:
		if from_title:
			show_title()
		else:
			show_list())
	screen.story_requested.connect(func() -> void: show_list(true))   # 이야기 다시 보기
	# A language picked: the words are read again and the settings built again in it.
	screen.language_changed.connect(func() -> void:
		_definitions = ExperimentRegistry.load_all()
		show_settings(from_title))
	# 처음부터 다시 하기 (confirmed, the store already empty): the start, as on a first launch — the
	# title when it may show, else the map (which plays the prologue: it was never seen now).
	screen.restart_requested.connect(func() -> void:
		if TitleScreen.app_may_show:
			show_title()
		else:
			show_list())
	_swap(screen, "settings")


func _swap(screen: Control, bench_scene: String) -> void:
	if _screen:
		remove_child(_screen)
		_screen.queue_free()
		SoundBoard.play(&"whoosh")   # a change of screen (not the first one)
	# The music: the map's loop, quieter in a lab (SoundBoard.MUSIC_DB).
	SoundBoard.music_for(&"lab" if screen is ExperimentScreen else &"map")
	_screen = screen
	add_child(screen)
	_slide_in(screen)
	if bench_scene != "":
		Bench.reset(bench_scene)


func _slide_in(screen: Control) -> void:
	# A screen that comes back (re-added) stops its previous slide so two tweens never fight.
	var old: Tween = screen.get_meta("slide_tween") if screen.has_meta("slide_tween") else null
	if old and old.is_valid():
		old.kill()
	screen.position.x = SLIDE_UNITS
	screen.modulate.a = 0.0
	var tween := screen.create_tween().set_parallel()
	screen.set_meta("slide_tween", tween)
	tween.tween_property(screen, "position:x", 0.0, SLIDE_S).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(screen, "modulate:a", 1.0, SLIDE_S * 0.7)


## --demo-story=<part> (screenshots): the story on, in the bench store set up for that part. Returns
## {"experiment": definition} when the part is a lab's ({} otherwise: the map).
##   prologue      the map plays the prologue (nothing found yet)
##   clue:<id>     the lab opens with Puppy's clue (its round not started)
##   found:<id>    the lab opens and its three stamps play (--demo-celebrate's way), then its piece
##   flight:<id>   the map: that spot just completed (its flag, then its piece's flight); 4 others found
##   finale        the map: the orbit spot just completed with the 10 others found: flag, flight, finale
##   map[:<n>]     the night map with the first n pieces of the order found (5 by default) and at the
##                 lookout, nothing but Puppy's riddle playing: fps measurements, screenshots
##   voyage        the first island all found and its finale seen, the next island open (not in the
##                 Play build): the voyage plays, then the next island's map and prologue (#75)
##   islands       as voyage, the voyage already seen: the title with 섬 고르기's cards open (#75)
## Every spot done (--progress=complete): full stamps, the story seen, the pieces at the lookout.
static func complete_progress() -> void:
	var store := {}
	for spot in Story.spots():
		store[spot] = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
		ProgressStore.set_mark(ProgressStore.CLUES, spot, true)
	ProgressStore.save(store)
	for part in ["prologue", "finale"]:
		Story.mark_seen(part)


func _demo_story(value: String) -> Dictionary:
	if value == "":
		return {}
	ProgressStore.path = ProgressStore.BENCH_PATH
	Story.enabled = true
	var kind := value.get_slice(":", 0)
	var id := value.get_slice(":", 1) if ":" in value else ""
	var config := ConfigFile.new()   # a fresh bench store
	config.save(ProgressStore.path)
	Island.forget_current()   # the fresh store's island: the first
	if kind != "prologue":
		Story.mark_seen("prologue")
	var store := {}
	var full := func(spot: String) -> int:
		return MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
	if kind in ["voyage", "islands"]:
		Island.dev_open = not OS.has_feature("play")   # the next island is still in the making (#72)
		for spot in Story.spots():
			store[spot] = full.call(spot)
		ProgressStore.save(store)
		Story.mark_seen("finale")
		if kind == "islands":
			for island in Island.ids():
				if island != ProgressStore.FIRST_ISLAND:
					Story.mark_voyage_seen(island)
			return {"islands": true}
		return {}
	match kind:
		"clue", "found":
			if kind == "found":
				ProgressStore.set_mark(ProgressStore.CLUES, id, true)
			ProgressStore.save(store)
			var definition := ExperimentRegistry.find(id)
			return {"experiment": definition} if not definition.is_empty() else {}
		"flight", "map":
			# The pieces found are the first of the order (the night map's fixed order), as a child finds them.
			var count := 4
			if kind == "map":
				count = clampi(id.to_int(), 0, Story.spots().size()) if id.is_valid_int() else 5
			for spot in Story.order().filter(func(s: String) -> bool: return s != id).slice(0, count):
				store[spot] = full.call(spot)
		"finale":
			id = Island.current().lookout
			for spot in Story.spots():
				store[spot] = full.call(spot)
	if kind in ["flight", "finale"] and ExperimentRegistry.find(id).size() > 0:
		store[id] = full.call(id)
		ProgressStore.save(store)
		ProgressStore.mark_flag_pending(id)
		ProgressStore.set_mark(ProgressStore.PIECES, id, false)
	else:
		ProgressStore.save(store)
	return {}


func _set_fps(on: bool) -> void:
	_show_fps = on
	_fps_label.visible = on


func _on_bench_report(_line: String, fps: float, scene: String, p95_ms: float) -> void:
	if not _show_fps:
		return
	_fps_label.text = "%s %s  %.1f fps  p95 %.1f ms" % [scene, Quality.label(), fps, p95_ms]
