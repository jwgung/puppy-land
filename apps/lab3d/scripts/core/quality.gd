## Render quality tiers (autoload "Quality"), ported from spikes/godot/scripts/quality.gd.
## One place decides renderer, 3D resolution and AA; the experiment screen asks it how large to
## render the 3D view. (No engine light or realtime shadow on any tier: see docs/art-direction.md.)
## Tier comes from `--quality=<tier>` (command line, or on Android the launch intent extra
## `opargs`, see all_args), else user://quality.txt, else DEFAULT_TIER. Single fields can be
## overridden for measurements with `--q-<field>=<value>` (not persisted), e.g. `--q-ui_mode=root`.
## Rationale: spikes/bench/results/phase1-task1/README.md (tiers) and
## apps/lab3d/docs/ui-resolution.md (why the UI stays at native resolution).
extends Node

signal changed

const TIER_ORDER := ["low", "medium", "high"]
const DEFAULT_TIER := "low"
const SAVE_PATH := "user://quality.txt"
## Loaded at startup through application/config/project_settings_override (project.godot).
const RENDERER_OVERRIDE_PATH := "user://renderer_override.cfg"
const RESTART_MARKER_PATH := "user://renderer_restart.txt"
const RESTART_MARKER_TTL_S := 60  # an older marker is left over from a killed restart
const RENDERERS := ["mobile", "gl_compatibility"]
const UI_MODES := ["native", "root", "scale3d"]
## project.godot window/size/viewport_*: the shorter screen side is 720 UI units on every device
## (divided by the screen size's zoom, below).
const BASE_SIZE := Vector2i(720, 720)

## 화면 크기 (screen size, 2026-11-04 playtest: on a phone the words and buttons were 2/3 of the
## tablet's size, both being 720 units on the short side). The root Window's content_scale_factor
## (`zoom`) multiplies the canvas_items stretch: the short side is 720 / zoom units, everything in
## units (text, buttons, the sidebar, cards) is zoom times larger on the glass, the 3D view keeps the
## same screen pixels and framing. "auto" = REF_MM / the screen's short side in mm, kept to
## 1.0..UI_ZOOM_MAX; the others are fixed. The mm come from DisplayServer.screen_get_dpi, on Android
## DisplayMetrics.densityDpi (Android's own size bucket, follows the system's display size setting):
## SM-P200 1200 px / 320 dpi = 95 mm -> 1.0, a phone 1080 px / 420-480 dpi = 57-65 mm -> the max.
## Unknown dpi (headless, desktop without one) -> 1.0. Kept in [display] ui_size of
## user://settings.cfg (처음부터 다시 하기 keeps it).
## UI_ZOOM_MAX 1.1 and UI_MIN_LONG_UNITS 1418: what the layout checks hold (tests/ui_scale_checks.gd,
## docs/ui-resolution.md 8절). At 1.15 a phone already has the buoyancy's riding cat under the title
## bar, at 1.3 many more 2D-over-3D overlaps: the 2D grows over a 3D framed for 720 units, which this
## change leaves as it is. The long side never gets below 1418 units (a 2340x1080 phone at 1.1, the
## shape checked; at 1152 x 655 Puppy's bubble jumped sides, at 1047 x 655 the cat was under the
## title bar): a narrower screen zooms less, 16:9 and 16:10 not at all.
const UI_SIZES := ["auto", "normal", "large", "extra_large"]
const DEFAULT_UI_SIZE := "auto"
const UI_SIZE_ZOOM := {"normal": 1.0, "large": 1.05, "extra_large": 1.1}
const UI_ZOOM_REF_MM := 92.0
const UI_ZOOM_MAX := 1.1
const UI_MIN_LONG_UNITS := 1418.0
const SETTINGS_PATH := "user://settings.cfg"   # the file SoundBoard keeps [sound] in
const SETTINGS_TEST_PATH := "user://settings-test.cfg"
const DISPLAY_SECTION := "display"
static var settings_path := SETTINGS_PATH

## Emitted when the screen size was changed (after the root is scaled).
signal ui_size_changed

## The guardian's 화면 크기 choice (UI_SIZES); `--ui-size=<choice>` overrides it without saving.
var ui_size := DEFAULT_UI_SIZE

## renderer: "mobile" (Vulkan) or "gl_compatibility" (OpenGL ES 3); applied by restarting the app.
## view_scale: 3D view resolution as a fraction of the screen pixels it covers (low 0.75 = 900 px
## on the 1200 px short side of SM-P200; it was 0.45 = 540 px without MSAA until 2026-10-24, too
## blocky on the tablet: spikes/bench/results/phase1-low-sharp/README.md). msaa: 0 or 2 (x).
## ui_mode (measurement switch, see docs/ui-resolution.md):
##   native  = UI at screen resolution, 3D in a SubViewport at view_scale (chosen),
##   root    = Task 1 method: the whole root viewport (UI too) at root_short px on the short side,
##   scale3d = UI at screen resolution, 3D SubViewport at screen size with scaling_3d_scale.
## root_short: short side of the root viewport in ui_mode=root.
const TIERS := {
	"low": {"renderer": "gl_compatibility", "view_scale": 0.75, "msaa": 2, "ui_mode": "native", "root_short": 540},
	"medium": {"renderer": "mobile", "view_scale": 0.6, "msaa": 2, "ui_mode": "native", "root_short": 720},
	"high": {"renderer": "mobile", "view_scale": 1.0, "msaa": 2, "ui_mode": "native", "root_short": 0},
}

var tier := DEFAULT_TIER
var _overrides: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var requested := cmdline_value("quality")
	# After a renderer restart the launch args are still there; the saved tier (picked in the app) wins.
	if TIERS.has(requested) and not _restart_pending():
		tier = requested
		_save_tier()
	elif FileAccess.file_exists(SAVE_PATH):
		var saved := FileAccess.get_file_as_string(SAVE_PATH).strip_edges()
		if TIERS.has(saved):
			tier = saved
	for arg in all_args():
		if arg.begins_with("--q-") and "=" in arg:
			var key := arg.trim_prefix("--q-").get_slice("=", 0)
			if not TIERS[DEFAULT_TIER].has(key):
				continue
			var text := arg.get_slice("=", 1)
			var default_value: Variant = TIERS[DEFAULT_TIER][key]
			if typeof(default_value) == TYPE_INT and not text.is_valid_int():
				push_warning("Quality: ignoring %s (not an integer)" % arg)
				continue
			if typeof(default_value) == TYPE_FLOAT and not text.is_valid_float():
				push_warning("Quality: ignoring %s (not a number)" % arg)
				continue
			if key == "renderer" and text not in RENDERERS:
				push_warning("Quality: ignoring %s (unknown renderer)" % arg)
				continue
			if key == "ui_mode" and text not in UI_MODES:
				push_warning("Quality: ignoring %s (unknown ui_mode)" % arg)
				continue
			_overrides[key] = _parse_like(default_value, text)
	load_ui_size()
	apply_root_viewport()
	# The window can get its final pixel size after the first frame (Android): auto follows it.
	get_tree().root.size_changed.connect(_apply_ui_zoom)
	_ensure_renderer.call_deferred()


## Value of `--<key>=<value>` from the command line or Android intent ("" when absent).
static func cmdline_value(key: String) -> String:
	var prefix := "--%s=" % key
	for arg in all_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


## The developer switches (DEV_KEYS: another island's map, a finished progress, the AI question
## button) are read only outside the Play build (feature "play"): a launch intent cannot open an
## island, write the child's progress or show the button on a child's device (#72 review).
const DEV_KEYS := ["island", "progress", "ask"]


## Value of the developer switch `--<key>=` (DEV_KEYS) in this build ("" in the Play build).
static func dev_value(key: String) -> String:
	return dev_arg(all_args(), key, OS.has_feature("play"))


## dev_value's rule on given args (tests): "" when `play` or `key` is not a developer switch.
static func dev_arg(args: PackedStringArray, key: String, play: bool) -> String:
	if play or key not in DEV_KEYS:
		return ""
	var prefix := "--%s=" % key
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


## Engine + user command-line args, plus on Android the launch intent's string extra "opargs"
## (comma-separated; the release template ignores Godot's own command_line_params extra):
## adb shell am start -n <pkg>/com.godot.game.GodotAppLauncher --es opargs "--quality=low"
static func all_args() -> PackedStringArray:
	if _args_cache != null:
		return _args_cache
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	if Engine.has_singleton("AndroidRuntime"):
		var activity: Object = Engine.get_singleton("AndroidRuntime").getActivity()
		var intent: Object = activity.getIntent() if activity else null
		var extra = intent.getStringExtra("opargs") if intent else null
		if extra is String:
			args.append_array(extra.split(",", false))
	_args_cache = args
	return args


static var _args_cache = null


static func _restart_pending() -> bool:
	return FileAccess.file_exists(RESTART_MARKER_PATH) \
		and Time.get_unix_time_from_system() - FileAccess.get_modified_time(RESTART_MARKER_PATH) < RESTART_MARKER_TTL_S


static func _parse_like(default_value: Variant, text: String) -> Variant:
	match typeof(default_value):
		TYPE_BOOL:
			return text in ["1", "true", "on", "yes"]
		TYPE_INT:
			return int(text)
		TYPE_FLOAT:
			return float(text)
	return text


func get_value(key: String) -> Variant:
	return _overrides.get(key, TIERS[tier][key])


## Tier name plus any measurement overrides, e.g. "low" or "low+ui_mode=root".
func label() -> String:
	var text: String = tier
	for key in _overrides:
		text += "+%s=%s" % [key, _overrides[key]]
	return text


## True when switching to `new_tier` needs an app restart (different renderer).
func needs_restart(new_tier: String) -> bool:
	if not TIERS.has(new_tier) or not _can_switch_renderer():
		return false
	return TIERS[new_tier]["renderer"] != RenderingServer.get_current_rendering_method()


## Saves and applies a tier. Returns true when the app is restarting for a renderer change.
func set_tier(new_tier: String) -> bool:
	if not TIERS.has(new_tier) or new_tier == tier:
		return false
	tier = new_tier
	_save_tier()
	if _ensure_renderer():
		return true
	apply_root_viewport()
	changed.emit()
	return false


func _save_tier() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(tier)


## ui_mode=root renders the whole root viewport (2D + 3D) at root_short px on the short side and
## upscales it (Task 1 low tier). Every other mode keeps the root at screen resolution with
## canvas_items stretch so text and lines stay sharp; the 3D view sets its own size.
func apply_root_viewport() -> void:
	var root := get_tree().root
	var short_side: int = get_value("root_short")
	if get_value("ui_mode") == "root" and short_side > 0:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_size = Vector2i(short_side, short_side)
	else:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_size = BASE_SIZE
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	_apply_ui_zoom()


## The screen size's zoom on the root (1.0 in ui_mode=root: that measurement draws the whole root at
## root_short px). Only when it differs: setting it resizes the root, which calls this again.
func _apply_ui_zoom() -> void:
	var root := get_tree().root
	var zoom := 1.0 if root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT else ui_zoom_now()
	if not is_equal_approx(root.content_scale_factor, zoom):
		root.content_scale_factor = zoom


## The screen's short side in mm from its pixels and dpi; 0 when either is unknown.
static func short_side_mm(pixels: Vector2, dpi: float) -> float:
	if dpi <= 0.0 or pixels.x <= 0.0 or pixels.y <= 0.0:
		return 0.0
	return minf(pixels.x, pixels.y) / dpi * 25.4


## The UI zoom for a screen whose short side is `short_mm` (0 = unknown), whose long side is
## `aspect` times the short one (0 = unknown) and a 화면 크기 choice: a fixed choice is its own zoom;
## auto (and an unknown choice) is REF_MM / short_mm in 1.0..MAX, 1.0 for an unknown size. Then no
## more than keeps the long side at UI_MIN_LONG_UNITS (never below 1.0). Down to 0.01.
static func ui_zoom(short_mm: float, aspect: float, choice: String) -> float:
	var zoom := 1.0
	if UI_SIZE_ZOOM.has(choice):
		zoom = UI_SIZE_ZOOM[choice]
	elif short_mm > 0.0:
		zoom = clampf(UI_ZOOM_REF_MM / short_mm, 1.0, UI_ZOOM_MAX)
	if aspect > 0.0:
		zoom = minf(zoom, maxf(1.0, aspect * BASE_SIZE.y / UI_MIN_LONG_UNITS))
	return floorf(zoom * 100.0 + 1e-6) / 100.0   # down, so the long side stays at the floor


## This device's short side in mm (0 headless: its dpi is a placeholder).
static func device_short_mm() -> float:
	if DisplayServer.get_name() == "headless":
		return 0.0
	return short_side_mm(Vector2(DisplayServer.screen_get_size()), float(DisplayServer.screen_get_dpi()))


## The choice in effect: `--ui-size=<choice>` (screenshots, not saved), else the saved one.
func ui_size_in_use() -> String:
	var requested := cmdline_value("ui-size")
	return requested if requested in UI_SIZES else ui_size


## The zoom for this device and choice; the shape is the window's (0 before it has a size).
func ui_zoom_now() -> float:
	var window := Vector2(get_tree().root.size)
	var aspect := maxf(window.x, window.y) / minf(window.x, window.y) if minf(window.x, window.y) > 0.0 else 0.0
	return ui_zoom(device_short_mm(), aspect, ui_size_in_use())


## Reads [display] ui_size from the settings file (missing or unknown = auto).
func load_ui_size() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	var saved := str(config.get_value(DISPLAY_SECTION, "ui_size", DEFAULT_UI_SIZE))
	ui_size = saved if saved in UI_SIZES else DEFAULT_UI_SIZE


## 화면 크기 picked in the settings: saved (the file's other sections kept) and applied at once.
func set_ui_size(choice: String) -> void:
	if choice not in UI_SIZES:
		return
	ui_size = choice
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value(DISPLAY_SECTION, "ui_size", choice)
	config.save(settings_path)
	_apply_ui_zoom()
	ui_size_changed.emit()


## Configures a 3D SubViewport for the tier: MSAA and (ui_mode=scale3d) 3D resolution scaling.
func configure_view(view: SubViewport) -> void:
	view.msaa_3d = Viewport.MSAA_2X if get_value("msaa") >= 2 else Viewport.MSAA_DISABLED
	if get_value("ui_mode") == "scale3d":
		view.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		view.scaling_3d_scale = get_value("view_scale")
	else:
		view.scaling_3d_scale = 1.0


## Render-target pixels per UI unit for a 3D view (the SubViewport size is its rect size times this).
func view_pixels_per_unit() -> float:
	var root := get_tree().root
	if root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT:
		return 1.0  # the root itself is already low resolution; draw the 3D at its pixel size
	var screen_scale := root.get_final_transform().get_scale().x
	if get_value("ui_mode") == "scale3d":
		return screen_scale  # full size target, scaling_3d_scale shrinks the 3D buffer
	return screen_scale * float(get_value("view_scale"))


func _can_switch_renderer() -> bool:
	var current := RenderingServer.get_current_rendering_method()
	return not OS.has_feature("web") and current in ["mobile", "forward_plus", "gl_compatibility"]


## The renderer is fixed at startup, so a tier with another renderer writes the override file
## and restarts the app once. Returns true when a restart was requested.
func _ensure_renderer() -> bool:
	if not _can_switch_renderer():
		return false  # Web is always Compatibility; headless runs use the dummy renderer.
	var current := RenderingServer.get_current_rendering_method()
	var wanted: String = get_value("renderer")
	if wanted not in RENDERERS:
		return false
	var file := FileAccess.open(RENDERER_OVERRIDE_PATH, FileAccess.WRITE)
	if file:
		file.store_string('[rendering]\n\nrenderer/rendering_method="%s"\nrenderer/rendering_method.mobile="%s"\n' % [wanted, wanted])
		file.close()
	if current == wanted:
		DirAccess.remove_absolute(RESTART_MARKER_PATH)
		return false
	if _restart_pending():
		push_warning("Quality: renderer %s requested but %s is running; not restarting again" % [wanted, current])
		DirAccess.remove_absolute(RESTART_MARKER_PATH)
		return false
	var marker := FileAccess.open(RESTART_MARKER_PATH, FileAccess.WRITE)
	if marker:
		marker.store_string(wanted)
		marker.close()   # on disk before this process ends
	var restart_args := OS.get_cmdline_args()
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		restart_args.append("--")
		restart_args.append_array(user_args)
	if android_restart():
		# The new process ends this one; if nothing does within a while, quit (the next launch uses
		# the renderer), never stay on the old one saying it restarts.
		get_tree().create_timer(3.0, true, false, true).timeout.connect(get_tree().quit)
		return true
	OS.set_restart_on_exit(true, restart_args)   # desktop (Godot restarts only there)
	get_tree().quit()
	return true


## Android: Godot's own restart (its library's ProcessPhoenix, declared in every export's manifest)
## starts the app again in a new process and ends this one, so the new renderer is used (2026-11-01
## user: on the phone the app only closed; OS.set_restart_on_exit works on desktop only). False when
## it is not there (then the app quits as before and the next launch uses the renderer).
static func android_restart() -> bool:
	if not Engine.has_singleton("AndroidRuntime"):
		return false
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity: Object = runtime.call("getActivity")
	var phoenix: Object = JavaClassWrapper.wrap("org.godotengine.godot.utils.ProcessPhoenix")
	if activity == null or phoenix == null or JavaClassWrapper.get_exception() != null:
		return false
	phoenix.call("triggerRebirth", activity)
	return JavaClassWrapper.get_exception() == null
