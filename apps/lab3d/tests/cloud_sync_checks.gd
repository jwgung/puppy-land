## 기기 사이 기록 맞추기 (#103, ADR 0006): ProgressMerge joins two copies (progress only grows), CloudSync
## keeps the device's copy and the cloud's in step through a stand-in cloud, and the settings card turns
## it on only after the parental gate.
## - merge: stamps the larger, marks either, a flag/piece played on either side played (a pending one
##   stays pending), the cleared controls of the copy with more stamps, the day limit of the later date,
##   the map position this device's only (never sent), a later reset wins over the other's progress;
## - off (the default): the cloud is never started and nothing is sent;
## - on: the cloud's copy joins the device's at once (a new device gets the progress), the joined copy
##   goes back when it differs, a write is sent once SAVE_DELAY_S later, 처음부터 다시 하기 reaches the
##   cloud and a device with the old progress starts over; a cloud that cannot start says so;
## - settings: without Play Games the button is off and says so; 켜기 opens the parental gate and turns
##   it on only once the gate is passed; 끄기 needs no gate.
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const SETTINGS_SCREEN := "res://scripts/app/settings_screen.gd"
const SETTINGS := "user://settings-sync-test.cfg"

var tree: SceneTree
var expect: Callable


## A stand-in for Play Games: one copy in memory.
class FakeCloud:
	extends RefCounted
	var copy := ""
	var starts := 0
	var saves := 0
	var loads := 0
	var can_start := true

	func start(on_ready: Callable) -> void:
		starts += 1
		on_ready.call(can_start)

	func load(on_loaded: Callable) -> void:
		loads += 1
		on_loaded.call(true, copy)

	func save(text: String, on_saved: Callable) -> void:
		saves += 1
		copy = text
		on_saved.call(true)


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	var saved_sync := ProgressStore.sync_path
	var saved_settings := CloudSync.settings_path
	ProgressStore.path = ProgressStore.TEST_PATH
	ProgressStore.sync_path = ProgressStore.TEST_PATH
	CloudSync.settings_path = SETTINGS
	check_merge()
	await check_flow()
	await check_settings()
	ProgressStore.reset_all()
	if FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(SETTINGS)
	ProgressStore.path = saved_path
	ProgressStore.sync_path = saved_sync
	CloudSync.settings_path = saved_settings


static func _text(sections: Dictionary) -> String:
	var config := ConfigFile.new()
	for section in sections:
		for key in sections[section]:
			config.set_value(section, key, sections[section][key])
	return config.encode_to_text()


static func _config(text: String) -> ConfigFile:
	var config := ConfigFile.new()
	config.parse(text)
	return config


func check_merge() -> void:
	var problems := []
	var here := _text({
		"progress": {"free-fall": 3, "spring": 1},
		"cleared": {"free-fall": {"gravity": "moon"}, "spring": {"mass": "light"}},
		"flags": {"free-fall": false},
		"pieces": {"free-fall": true},
		"story": {"prologue": true},
		"clues": {"spring": true},
		"day": {"hutton.spot": "volcano", "hutton.date": "2026-11-10"},
		"map": {"island": "hutton", "last_spot": "spring"},
	})
	var there := _text({
		"progress": {"free-fall": 1, "spring": 3, "orbit": 2},
		"cleared": {"spring": {"mass": "heavy"}},
		"flags": {"free-fall": true, "spring": false},
		"pieces": {"spring": false},
		"story": {"finale": true},
		"guides": {"map": true},
		"day": {"hutton.spot": "strata", "hutton.date": "2026-11-12"},
	})
	var m := _config(ProgressMerge.merge(here, there))
	if m.get_value("progress", "free-fall") != 3 or m.get_value("progress", "spring") != 3 or m.get_value("progress", "orbit") != 2:
		problems.append("stamps %s" % str([m.get_value("progress", "free-fall"), m.get_value("progress", "spring"), m.get_value("progress", "orbit")]))
	if m.get_value("cleared", "free-fall") != {"gravity": "moon"} or m.get_value("cleared", "spring") != {"mass": "heavy"}:
		problems.append("cleared %s / %s" % [m.get_value("cleared", "free-fall"), m.get_value("cleared", "spring")])
	if m.get_value("flags", "free-fall") != true or m.get_value("flags", "spring") != false or m.get_value("pieces", "free-fall") != true or m.get_value("pieces", "spring") != false:
		problems.append("flags / pieces")
	if not (m.get_value("story", "prologue") and m.get_value("story", "finale") and m.get_value("clues", "spring") and m.get_value("guides", "map")):
		problems.append("marks")
	if m.get_value("day", "hutton.spot") != "strata" or m.get_value("day", "hutton.date") != "2026-11-12":
		problems.append("day %s %s" % [m.get_value("day", "hutton.spot"), m.get_value("day", "hutton.date")])
	if m.get_value("map", "island") != "hutton" or m.get_value("map", "last_spot") != "spring":
		problems.append("map not kept")
	var sent := _config(ProgressMerge.for_cloud(here))
	if sent.has_section("map") or sent.get_value("progress", "free-fall") != 3:
		problems.append("for_cloud keeps the map or loses the stamps")
	var from_cloud := _config(ProgressMerge.merge(here, _text({"map": {"island": "mechanics"}})))
	if from_cloud.get_value("map", "island") != "hutton":
		problems.append("the cloud's map position taken")
	# A new device (nothing here) gets the progress; an empty cloud keeps the device's.
	if _config(ProgressMerge.merge("", there)).get_value("progress", "orbit") != 2 or _config(ProgressMerge.merge(here, "")).get_value("progress", "free-fall") != 3:
		problems.append("an empty side")
	# A later reset wins over the other copy's progress, whichever side it is on.
	var reset := _text({"sync": {"reset": 200}, "progress": {"orbit": 1}})
	var old := _text({"sync": {"reset": 100}, "progress": {"free-fall": 3}, "map": {"island": "hutton"}})
	var a := _config(ProgressMerge.merge(old, reset))
	var b := _config(ProgressMerge.merge(reset, old))
	if a.get_value("progress", "free-fall", 0) != 0 or a.get_value("progress", "orbit") != 1 or a.get_value("sync", "reset") != 200 or a.get_value("map", "island") != "hutton":
		problems.append("the cloud's later reset")
	if b.get_value("progress", "free-fall", 0) != 0 or b.get_value("progress", "orbit") != 1 or ProgressMerge.reset_time(ProgressMerge.merge(reset, old)) != 200:
		problems.append("this device's later reset")
	expect.call(problems.is_empty(), "cloud sync: the copies join (stamps the larger, marks either, played flags/pieces win, cleared of the copy with more stamps, the day of the later date, the map stays on the device, a later reset wins)",
		"; ".join(problems))


func _sync(cloud: FakeCloud) -> CloudSync:
	var sync := CloudSync.new()
	sync.backend = cloud
	tree.root.add_child(sync)
	return sync


func _drop(sync: CloudSync) -> void:
	tree.root.remove_child(sync)
	sync.free()


func _seconds(s: float) -> void:
	for i in int(s * 60.0):
		await tree.process_frame


func check_flow() -> void:
	var problems := []
	ProgressStore.reset_all()
	if FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(SETTINGS)
	# Off: never started, nothing sent.
	var cloud := FakeCloud.new()
	var sync := _sync(cloud)
	ProgressStore.save({"free-fall": 2})
	await _seconds(CloudSync.SAVE_DELAY_S + 0.5)
	if cloud.starts != 0 or cloud.saves != 0 or sync.status != CloudSync.OFF:
		problems.append("off: starts %d saves %d status %s" % [cloud.starts, cloud.saves, sync.status])
	# On: the cloud's copy (another device's) joins the device's, the joined copy goes back.
	cloud.copy = _text({"progress": {"orbit": 3}, "story": {"prologue": true}})
	sync.set_on(true)
	var here := ProgressStore.load()
	if not CloudSync.is_on() or here.get("free-fall") != 2 or here.get("orbit") != 3 or not ProgressStore.mark(ProgressStore.STORY, "prologue"):
		problems.append("on: the device has %s" % str(here))
	if _config(cloud.copy).get_value("progress", "free-fall", 0) != 2 or sync.status != CloudSync.SYNCED:
		problems.append("on: the joined copy not sent (%s, %s)" % [cloud.copy.replace("\n", " "), sync.status])
	# A write goes once, SAVE_DELAY_S later.
	var before := cloud.saves
	ProgressStore.save({"free-fall": 3, "orbit": 3})
	ProgressStore.set_mark(ProgressStore.CLUES, "orbit", true)
	await _seconds(CloudSync.SAVE_DELAY_S * 0.5)
	var early := cloud.saves - before
	await _seconds(CloudSync.SAVE_DELAY_S * 0.5 + 0.5)
	if early != 0 or cloud.saves - before != 1 or _config(cloud.copy).get_value("progress", "free-fall") != 3 or not _config(cloud.copy).get_value("clues", "orbit", false):
		problems.append("a write: %d early, %d after" % [early, cloud.saves - before])
	# 처음부터 다시 하기 reaches the cloud; another device with the old progress starts over.
	var other_device := ProgressMerge.for_cloud(ProgressStore.file_text())
	ProgressStore.reset_all()
	sync.mark_reset()
	if ProgressMerge.reset_time(cloud.copy) <= 0 or not ProgressStore.load().is_empty():
		problems.append("reset: cloud %s" % cloud.copy.replace("\n", " "))
	var other := _config(ProgressMerge.merge(other_device, cloud.copy))
	if other.has_section("progress"):
		problems.append("the other device keeps its old progress after the reset")
	_drop(sync)
	# A cloud that cannot start says so; the device's progress stays as it is.
	CloudSync._store_on(true)
	ProgressStore.reset_all()
	ProgressStore.save({"spring": 1})
	var broken := FakeCloud.new()
	broken.can_start = false
	var failing := _sync(broken)
	if failing.status != CloudSync.FAILED or ProgressStore.load() != {"spring": 1} or broken.saves != 0:
		problems.append("no start: %s" % failing.status)
	_drop(failing)
	CloudSync._store_on(false)
	ProgressStore.reset_all()
	expect.call(problems.is_empty(), "cloud sync: off by default (never started, nothing sent); on, the cloud's copy joins the device's, writes go %.0f s later, a reset reaches the other devices, a cloud that cannot start says so" % CloudSync.SAVE_DELAY_S,
		"; ".join(problems))


func check_settings() -> void:
	var problems := []
	if FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(SETTINGS)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = Vector2(1152, 720)
	tree.root.add_child(host)
	# Without Play Games: the button is off and says so.
	var screen: Control = load(SETTINGS_SCREEN).new()
	host.add_child(screen)
	await tree.process_frame
	if not screen.sync_button.disabled or screen.sync_status.text != Locale.t("settings.sync_no_service"):
		problems.append("no service: %s %s" % [screen.sync_button.disabled, screen.sync_status.text])
	screen.queue_free()
	await tree.process_frame
	# With it: 켜기 opens the gate; only the right answer turns it on; 끄기 has no gate.
	var cloud := FakeCloud.new()
	var sync := _sync(cloud)
	screen = load(SETTINGS_SCREEN).new()
	host.add_child(screen)
	await tree.process_frame
	if screen.sync_button.disabled or screen.sync_status.text != Locale.t("settings.sync_off"):
		problems.append("off: %s %s" % [screen.sync_button.disabled, screen.sync_status.text])
	screen.sync_button.pressed.emit()
	await tree.process_frame
	var gates: Array = screen.find_children("*", "ParentalGate", true, false)
	if gates.size() != 1 or CloudSync.is_on() or cloud.starts != 0:
		problems.append("켜기: gates %d, on %s, started %d" % [gates.size(), CloudSync.is_on(), cloud.starts])
	else:
		var gate: ParentalGate = gates[0]
		gate.field.text = str(gate.answer())
		gate.submit()
		await tree.process_frame
		if not CloudSync.is_on() or cloud.starts != 1 or screen.sync_status.text != Locale.t("settings.sync_synced") \
				or screen.sync_button.text != Locale.t("settings.sync_turn_off"):
			problems.append("passed: on %s started %d '%s'" % [CloudSync.is_on(), cloud.starts, screen.sync_status.text])
	screen.sync_button.pressed.emit()
	await tree.process_frame
	if CloudSync.is_on() or not screen.find_children("*", "ParentalGate", true, false).is_empty() or screen.sync_status.text != Locale.t("settings.sync_off"):
		problems.append("끄기: on %s" % CloudSync.is_on())
	host.queue_free()
	_drop(sync)
	await tree.process_frame
	expect.call(problems.is_empty(), "cloud sync: settings — without Play Games the button is off; 켜기 opens the parental gate and turns it on only after it; 끄기 needs no gate",
		"; ".join(problems))
