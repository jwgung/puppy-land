extends SceneTree
var _failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	ProgressStore.path = ProgressStore.TEST_PATH
	Locale.app_may_choose = false
	Locale.path = "user://language-test.cfg"
	Locale.set_language("ko")
	DirAccess.remove_absolute(ProgressStore.path)
	var quality_script: GDScript = load("res://scripts/core/quality.gd")
	quality_script.set("settings_path", quality_script.get("SETTINGS_TEST_PATH"))
	DirAccess.remove_absolute(quality_script.get("settings_path"))
	root.get_node("Quality").load_ui_size()
	root.get_node("Quality").apply_root_viewport()
	Story.app_may_enable = false
	Story.enabled = false
	(load("res://scripts/app/title_screen.gd") as GDScript).set("app_may_show", false)
	for n in OS.get_environment("CHECKS").split(","):
		var s: GDScript = load("res://tests/%s.gd" % n)
		await s.new(self, _expect).run()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)
func _expect(ok: bool, label: String, detail: String) -> void:
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:
		_failures += 1
