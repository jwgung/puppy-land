## 화면 크기 (2026-11-04 playtest: "on a phone the UI looks too small"): the UI's zoom on the root
## Window (Quality.ui_zoom, content_scale_factor), docs/ui-resolution.md 8절.
## 1. The zoom rule as a table: the tablet (SM-P200 1200 px / 320 dpi) 1.0, phones the max (1.1),
##    REF_MM / mm between, unknown dpi 1.0, each fixed choice its own zoom, the clamps, and the long
##    side never below UI_MIN_LONG_UNITS (a 16:10 tablet stays 1.0 whatever is chosen).
## 2. On the root: extra_large on a 2340x1080 phone makes it 1418x655 units, a full-screen screen
##    follows at once; the 3D view keeps its screen pixels; the finger radius stays FINGER_MM on the
##    glass; the demo's pulls shrink with the zoom; auto is 1.0 headless; --ui-size is not saved.
## 3. The choice: the settings' 화면 크기 chips save it in [display] of the settings file (the other
##    sections kept), it is read back after a restart and 처음부터 다시 하기 keeps it.
## 4. The settings screen at the largest zoom (PHONE_ZOOMED) and at x1.0: every card's
##    controls inside the page, the 화면 크기 chips in one row without overlapping (Korean, English).
## The other screens at the zoomed size: PHONE_ZOOMED (from here) in the layout checks
## of run_tests.gd and the *_checks.gd files.
## Only the test settings file (Quality.SETTINGS_TEST_PATH) and the test progress store are written.
extends RefCounted

var tree: SceneTree
var expect: Callable
const UI_THEME := "res://scripts/app/ui_theme.gd"
const SETTINGS_SCREEN := "res://scripts/app/settings_screen.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const QualityScript := preload("res://scripts/core/quality.gd")
## The largest zoom's landscape screen in UI units: a 2340x1080 phone at x1.1, 1418x655. It is also the
## narrowest the zoom goes to (UI_MIN_LONG_UNITS): a narrower screen zooms less.
const PHONE_ZOOMED := Vector2(1560, 720) / QualityScript.UI_ZOOM_MAX


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path: String = QualityScript.settings_path
	var saved_size: String = Quality.ui_size
	QualityScript.settings_path = QualityScript.SETTINGS_TEST_PATH
	DirAccess.remove_absolute(QualityScript.settings_path)
	check_rule()
	await check_root()
	await check_choice()
	for setup in [[PHONE_ZOOMED, "phone zoomed"], [Vector2(1560, 720), "phone"], [Vector2(1152, 720), "tablet"]]:
		await check_settings_layout(setup[0], setup[1])
	# The English words are longer (Extra large).
	var lang: String = Locale.lang
	Locale.set_language("en")
	for setup in [[PHONE_ZOOMED, "phone zoomed, English"], [Vector2(1152, 720), "tablet, English"]]:
		await check_settings_layout(setup[0], setup[1])
	Locale.set_language(lang)
	DirAccess.remove_absolute(QualityScript.settings_path)
	QualityScript.settings_path = saved_path
	Quality.ui_size = saved_size
	Quality.apply_root_viewport()


## 1. The rule.
func check_rule() -> void:
	var top := QualityScript.UI_ZOOM_MAX
	var cases := [
		# [label, pixels, dpi, choice, zoom]
		["SM-P200 tablet", Vector2(1920, 1200), 320.0, "auto", 1.0],
		["10-inch tablet", Vector2(2560, 1600), 320.0, "auto", 1.0],
		["4:3 tablet", Vector2(2048, 1536), 320.0, "auto", 1.0],
		["phone 1080 px / 420 dpi", Vector2(2340, 1080), 420.0, "auto", top],
		["phone 1440 px / 560 dpi", Vector2(3120, 1440), 560.0, "auto", top],
		["phone 1080 px / 480 dpi", Vector2(2400, 1080), 480.0, "auto", top],
		["16:9 phone (the long side)", Vector2(1920, 1080), 420.0, "auto", 1.0],
		["18:9 phone (the long side)", Vector2(2160, 1080), 420.0, "auto", 1.01],
		["between, 87.6 mm wide screen", Vector2(2200, 1000), 290.0, "auto", 1.05],
		["16:10, 80 mm (the long side)", Vector2(1280, 800), 254.0, "auto", 1.0],
		["huge screen", Vector2(3840, 2160), 96.0, "auto", 1.0],
		["unknown dpi", Vector2(2340, 1080), 0.0, "auto", 1.0],
		["negative dpi", Vector2(2340, 1080), -1.0, "auto", 1.0],
		["unknown pixels", Vector2(0, 0), 420.0, "auto", 1.0],
		["unknown choice = auto", Vector2(2340, 1080), 420.0, "giant", top],
		["normal on a phone", Vector2(2340, 1080), 420.0, "normal", 1.0],
		["large on a phone", Vector2(2340, 1080), 420.0, "large", 1.05],
		["extra large on a phone", Vector2(2340, 1080), 420.0, "extra_large", 1.1],
		["normal on the tablet", Vector2(1920, 1200), 320.0, "normal", 1.0],
		["large on the tablet (the long side)", Vector2(1920, 1200), 320.0, "large", 1.0],
		["extra large on the tablet (the long side)", Vector2(1920, 1200), 320.0, "extra_large", 1.0],
		["large, unknown screen", Vector2(0, 0), 0.0, "large", 1.05],
	]
	var wrong := []
	for c in cases:
		var pixels: Vector2 = c[1]
		var mm := QualityScript.short_side_mm(pixels, c[2])
		var aspect := pixels.x / pixels.y if pixels.y > 0.0 else 0.0
		var zoom := QualityScript.ui_zoom(mm, aspect, c[3])
		if not is_equal_approx(zoom, c[4]):
			wrong.append("%s: %.1f mm -> %.3f (want %.2f)" % [c[0], mm, zoom, c[4]])
		# Never a long side under UI_MIN_LONG_UNITS from a zoom (a narrower screen stays at 1.0).
		if aspect > 0.0 and zoom > 1.0 and aspect * 720.0 / zoom < QualityScript.UI_MIN_LONG_UNITS - 0.5:
			wrong.append("%s: long side %.0f units" % [c[0], aspect * 720.0 / zoom])
	# The clamps, and the auto ramp in between: never below 1.0 or above the max, falling with the size.
	var last := INF
	for mm in [1.0, 20.0, 60.0, 70.0, 75.0, 85.0, 92.0, 100.0, 300.0]:
		var zoom := QualityScript.ui_zoom(mm, 0.0, "auto")
		if zoom < 1.0 or zoom > top or zoom > last:
			wrong.append("auto at %.0f mm -> %.3f" % [mm, zoom])
		last = zoom
	if not is_equal_approx(QualityScript.short_side_mm(Vector2(1920, 1200), 320.0), 95.25):
		wrong.append("SM-P200 short side %.2f mm" % QualityScript.short_side_mm(Vector2(1920, 1200), 320.0))
	if QualityScript.UI_SIZE_ZOOM.values().any(func(z: float) -> bool: return z > top) \
			or QualityScript.UI_SIZES != ["auto", "normal", "large", "extra_large"] or QualityScript.DEFAULT_UI_SIZE != "auto":
		wrong.append("choices %s %s" % [str(QualityScript.UI_SIZES), str(QualityScript.UI_SIZE_ZOOM)])
	expect.call(wrong.is_empty(), "화면 크기 rule: tablet 1.0, phones %.2f, %.0f mm / short side between, unknown dpi 1.0; 보통 1.0, 크게 1.05, 아주 크게 1.1; the long side never under %.0f units (16:10 and 16:9 stay 1.0)" % [top, QualityScript.UI_ZOOM_REF_MM, QualityScript.UI_MIN_LONG_UNITS],
		"; ".join(wrong))


## 2. The zoom on the root window.
func check_root() -> void:
	var root := tree.root
	var root_size := root.size
	root.size = Vector2i(2340, 1080)
	Quality.set_ui_size("normal")
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(ExperimentRegistry.find("incline-friction"))
	host.add_child(screen)
	for i in 3:
		await tree.process_frame
	var problems := []
	var normal_units := root.get_visible_rect().size
	var normal_pixels: Vector2i = screen.view.render_size()
	var normal_per_unit: float = screen.manipulator._pixels_per_unit().y
	var normal_demo: float = screen.manipulator.demo_scale()
	var signals := [0]
	var count := func() -> void: signals[0] += 1
	Quality.ui_size_changed.connect(count)
	Quality.set_ui_size("extra_large")
	await tree.process_frame
	var zoomed_units := root.get_visible_rect().size
	var top := QualityScript.UI_ZOOM_MAX
	if not zoomed_units.is_equal_approx(PHONE_ZOOMED) or not is_equal_approx(root.content_scale_factor, top) or signals[0] != 1:
		problems.append("extra large: root %s units, factor %.2f, signals %d" % [str(zoomed_units), root.content_scale_factor, signals[0]])
	if not normal_units.is_equal_approx(Vector2(1560, 720)) or not is_equal_approx(normal_demo, 1.0):
		problems.append("normal: root %s units" % str(normal_units))
	if not screen.size.is_equal_approx(PHONE_ZOOMED) or not screen.view.size.is_equal_approx(PHONE_ZOOMED):
		problems.append("the screen did not follow: %s, view %s" % [str(screen.size), str(screen.view.size)])
	# The 3D view keeps its screen pixels (same area, same pixel scale); the finger radius in units
	# shrinks by the zoom, so it stays FINGER_MM on the glass.
	var zoomed_pixels: Vector2i = screen.view.render_size()
	if absi(zoomed_pixels.x - normal_pixels.x) > 1 or absi(zoomed_pixels.y - normal_pixels.y) > 1:
		problems.append("3D render target %s -> %s" % [str(normal_pixels), str(zoomed_pixels)])
	var zoomed_per_unit: float = screen.manipulator._pixels_per_unit().y
	var finger_normal := Manipulator.finger_units(420.0, normal_per_unit)
	var finger_zoomed := Manipulator.finger_units(420.0, zoomed_per_unit)
	if not is_equal_approx(zoomed_per_unit / normal_per_unit, top) or absf(finger_zoomed * top - finger_normal) > 0.01:
		problems.append("pixels per unit %.3f -> %.3f, finger %.1f -> %.1f units" % [normal_per_unit, zoomed_per_unit, finger_normal, finger_zoomed])
	# The --auto-drag demo's pulls (UI units of a 720-unit short side) shrink with the zoom.
	if not is_equal_approx(screen.manipulator.demo_scale(), 1.0 / top):
		problems.append("demo scale %.3f" % screen.manipulator.demo_scale())
	# Auto headless (no dpi): 1.0.
	Quality.set_ui_size("auto")
	await tree.process_frame
	if not is_equal_approx(root.content_scale_factor, 1.0) or not root.get_visible_rect().size.is_equal_approx(Vector2(1560, 720)):
		problems.append("auto headless: factor %.2f" % root.content_scale_factor)
	# --ui-size=large: in effect, not saved.
	var quality_script: GDScript = QualityScript
	var saved_args = quality_script.get("_args_cache")
	quality_script.set("_args_cache", PackedStringArray(["--ui-size=large"]))
	Quality.apply_root_viewport()
	await tree.process_frame
	var config := ConfigFile.new()
	config.load(QualityScript.settings_path)
	if not is_equal_approx(root.content_scale_factor, QualityScript.UI_SIZE_ZOOM.large) or Quality.ui_size != "auto" or config.get_value("display", "ui_size", "") != "auto":
		problems.append("--ui-size=large: factor %.2f, choice %s, saved %s" % [root.content_scale_factor, Quality.ui_size, config.get_value("display", "ui_size", "")])
	quality_script.set("_args_cache", saved_args)
	Quality.apply_root_viewport()
	Quality.ui_size_changed.disconnect(count)
	host.queue_free()
	await tree.process_frame
	root.size = root_size
	expect.call(problems.is_empty(), "화면 크기 on the root: 아주 크게 makes a 2340x1080 phone %.0fx%.0f units at once (the screen follows), the 3D view keeps its pixels, the finger radius stays %.0f mm, the demo's pulls shrink with it; auto is 1.0 headless; --ui-size is not saved" % [PHONE_ZOOMED.x, PHONE_ZOOMED.y, Manipulator.FINGER_MM],
		"; ".join(problems))


## 3. The settings' chips save the choice; restart reads it; 처음부터 다시 하기 keeps it.
func check_choice() -> void:
	DirAccess.remove_absolute(QualityScript.settings_path)
	Quality.load_ui_size()
	var problems := []
	if Quality.ui_size != "auto":
		problems.append("default %s" % Quality.ui_size)
	var keep := ConfigFile.new()
	keep.set_value("sound", "sfx", false)
	keep.save(QualityScript.settings_path)
	var host := _host(Vector2(1152, 720))
	var screen: Control = load(SETTINGS_SCREEN).new()
	host.add_child(screen)
	await tree.process_frame
	var buttons: Dictionary = screen.ui_size_buttons
	if buttons.keys() != QualityScript.UI_SIZES or not buttons.auto.button_pressed or buttons.large.button_pressed:
		problems.append("chips %s, auto pressed %s" % [str(buttons.keys()), buttons.auto.button_pressed if buttons.has("auto") else false])
	var names: Dictionary = Locale.map("settings.ui_sizes")
	for choice in buttons:
		if (buttons[choice] as Button).text != str(names.get(choice, "")):
			problems.append("%s reads '%s'" % [choice, buttons[choice].text])
	(buttons.large as Button).emit_signal("pressed")   # as a tap
	await tree.process_frame
	var config := ConfigFile.new()
	config.load(QualityScript.settings_path)
	if Quality.ui_size != "large" or config.get_value("display", "ui_size", "") != "large" or config.get_value("sound", "sfx", true) != false \
			or not buttons.large.button_pressed or buttons.auto.button_pressed:
		problems.append("after 크게: choice %s, saved %s, sound kept %s, factor %.2f" % [Quality.ui_size, config.get_value("display", "ui_size", ""),
			config.get_value("sound", "sfx", true) == false, tree.root.content_scale_factor])
	host.queue_free()
	await tree.process_frame
	# A restart: the autoload reads the file again.
	Quality.ui_size = "auto"
	Quality.load_ui_size()
	if Quality.ui_size != "large":
		problems.append("read back %s" % Quality.ui_size)
	# 처음부터 다시 하기 erases the progress store only.
	ProgressStore.save({"spring": 2})
	ProgressStore.reset_all()
	Quality.ui_size = "auto"
	Quality.load_ui_size()
	if Quality.ui_size != "large" or FileAccess.file_exists(ProgressStore.path):
		problems.append("after 처음부터 다시 하기: %s, store left %s" % [Quality.ui_size, FileAccess.file_exists(ProgressStore.path)])
	# The settings screen built again shows it.
	host = _host(Vector2(1152, 720))
	screen = load(SETTINGS_SCREEN).new()
	host.add_child(screen)
	await tree.process_frame
	if not screen.ui_size_buttons.large.button_pressed or screen.ui_size_buttons.auto.button_pressed:
		problems.append("the screen built again does not show 크게")
	host.queue_free()
	await tree.process_frame
	# A file with an unknown value: auto.
	config.set_value("display", "ui_size", "giant")
	config.save(QualityScript.settings_path)
	Quality.load_ui_size()
	if Quality.ui_size != "auto":
		problems.append("unknown saved value read as %s" % Quality.ui_size)
	Quality.set_ui_size("auto")
	expect.call(problems.is_empty(), "화면 크기 choice: 자동 by default; 크게 is saved in [display] of the settings file (sound kept) and applied at once, read back after a restart, kept by 처음부터 다시 하기; an unknown saved value is 자동",
		"; ".join(problems))


## 4. The settings screen: the page's controls inside it, the 화면 크기 chips in one row, apart.
func check_settings_layout(size: Vector2, name: String) -> void:
	var host := _host(size)
	var screen: Control = load(SETTINGS_SCREEN).new()
	host.add_child(screen)
	for i in 3:
		await tree.process_frame
	var problems := []
	var page := Rect2(Vector2.ZERO, size)
	var scroll: ScrollContainer = screen.find_children("*", "ScrollContainer", true, false)[0]
	for control: Control in screen.find_children("*", "Control", true, false):
		if not control.is_visible_in_tree() or control is ScrollBar or control.size.x <= 0.0:
			continue
		var r := control.get_global_rect()
		if r.position.x < -0.5 or r.end.x > page.end.x + 0.5:
			problems.append("%s %s past the side" % [control.name, str(r)])
			break
	var chips: Array = screen.ui_size_buttons.values()
	var card: Control = screen.find_child("UiSizeCard", true, false)
	for i in chips.size():
		var a: Rect2 = (chips[i] as Control).get_global_rect()
		if not card.get_global_rect().encloses(a) or absf(a.position.y - (chips[0] as Control).get_global_rect().position.y) > 0.5:
			problems.append("chip %d %s not in the card's row" % [i, str(a)])
		for j in range(i + 1, chips.size()):
			if a.intersects((chips[j] as Control).get_global_rect()):
				problems.append("chips %d and %d overlap" % [i, j])
	if scroll.get_h_scroll_bar().visible:
		problems.append("the page scrolls sideways")
	expect.call(problems.is_empty(), "settings (%s, %.0fx%.0f units): every card inside the page, the 화면 크기 chips in one row, apart" % [name, size.x, size.y],
		"; ".join(problems))
	host.queue_free()
	await tree.process_frame


func _host(size: Vector2) -> Control:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	return host
