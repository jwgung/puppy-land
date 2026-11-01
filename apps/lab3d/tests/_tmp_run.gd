extends SceneTree
var fails := 0
func _expect(ok: bool, what: String, detail: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what + "  " + detail)
	if not ok:
		fails += 1
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	ProgressStore.path = ProgressStore.TEST_PATH
	Story.app_may_enable = false
	Story.enabled = false
	(load("res://scripts/app/title_screen.gd") as GDScript).set("app_may_show", false)
	var which := OS.get_environment("CHECKS")
	if which == "manipulation_checks":
		var vectors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/incline_vectors.json"))
		await load("res://tests/manipulation_checks.gd").new(self, _expect, vectors).run(ExperimentRegistry.find("incline-friction"))
	else:
		var c = load("res://tests/%s.gd" % which).new(self, _expect)
		if OS.get_environment("ROUND") != "":
			await c.check_round(OS.get_environment("ROUND"))
		else:
			await c.run()
	print("FAILS %d" % fails)
	quit()
