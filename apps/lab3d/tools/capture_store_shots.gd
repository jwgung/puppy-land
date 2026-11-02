## Takes the Play Store screenshots (docs/release/store/screenshots/, 1920 x 1080, landscape like the
## app): the island map and labs with the hand guide's paw, as a child sees them on a first visit.
## It uses its own progress file (ProgressStore.TEST_PATH, deleted after), never the child's.
## It needs a real renderer (a display); on a machine without one, under a virtual X server, e.g.
##   xvfb-run -s "-screen 0 1920x1080x24" godot --path apps/lab3d --display-driver x11 \
##     --resolution 1920x1080 -s res://tools/capture_store_shots.gd
extends SceneTree

const OUT := "res://../../docs/release/store/screenshots"
const SIZE := Vector2i(1920, 1080)
## [file name, lab id, seconds after the answer] (the paw is in the middle of its first gesture).
const LABS := [
	["ko-02-throw", "projectile", 1.25],
	["ko-03-push", "friction", 1.3],
	["ko-04-spring", "spring", 1.4],
	["ko-05-float", "buoyancy", 1.4],
	["ko-06-orbit", "orbit", 1.25],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path(OUT).simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	ProgressStore.path = ProgressStore.TEST_PATH
	Story.app_may_enable = false
	Story.enabled = false
	(load("res://scripts/app/title_screen.gd") as GDScript).set("app_may_show", false)
	root.size = SIZE
	await process_frame
	await _map(out)
	for shot: Array in LABS:
		await _lab(out, shot[0], shot[1], shot[2])
	await _scene(out.get_base_dir(), "scene-throw", "projectile")
	DirAccess.remove_absolute(ProgressStore.path)
	quit()


func _host() -> Control:
	var host := Control.new()
	host.theme = load("res://scripts/app/ui_theme.gd").build()
	host.size = root.get_visible_rect().size   # UI units (the window's content scale: 1280 x 720 at 1920 x 1080)
	root.add_child(host)
	return host


## The map after Puppy's first riddle, the paw tapping the next spot.
func _map(out: String) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	Story.enabled = true
	ProgressStore.set_mark(ProgressStore.STORY, "prologue", true)
	var host := _host()
	var home: Control = load("res://scripts/app/island_home_screen.gd").new()
	host.add_child(home)
	await _wait(2.5)
	home.story.riddle.close(true)
	await _wait(0.5)
	await _shot(out, "ko-01-map")
	Story.enabled = false
	host.queue_free()
	await _wait(0.3)


func _lab(out: String, file: String, id: String, after: float) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var host := _host()
	var screen: Control = load("res://scripts/shell/experiment_screen.gd").new()
	screen.setup(ExperimentRegistry.find(id))
	host.add_child(screen)
	await _wait(2.0)
	screen._predict_pick_choice(str(MissionRound.predict(screen.definition.raw).get("answer", "")))
	await _wait(GuideCoach.FIRST_DELAY_S + after)
	await _shot(out, file)
	host.queue_free()
	await _wait(0.3)


## The 3D scene alone (no title, cards or Dugi's box): the feature graphic's background (make_store_art.py).
func _scene(out: String, file: String, id: String) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var host := _host()
	var screen: Control = load("res://scripts/shell/experiment_screen.gd").new()
	screen.setup(ExperimentRegistry.find(id))
	host.add_child(screen)
	await _wait(1.5)
	for child in screen.view.get_children():
		if child is CanvasItem and child != screen.view._display:
			(child as CanvasItem).visible = false
	await _wait(0.2)
	await _shot(out, file)
	host.queue_free()
	await _wait(0.3)


func _shot(out: String, file: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out, file]
	root.get_texture().get_image().save_png(path)
	print("capture_store_shots: ", path)


func _wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		await process_frame
		left -= root.get_process_delta_time()
