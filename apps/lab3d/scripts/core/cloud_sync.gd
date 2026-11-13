## 기기 사이 기록 맞추기 (#103, ADR 0006): the child's progress kept in the guardian's Google Play
## Games account (Saved Games, one snapshot), so two devices share it and a reinstall gets it back.
##
## Off until a guardian turns it on in the settings behind the parental gate (Play's Families policy:
## nothing reaches Google from a child's play unless an adult chose it). While off the Play Games SDK
## is never started (no sign-in, nothing collected) and the app is exactly as before.
## While on:
##   - at launch and whenever the app comes back to the front: the cloud copy is loaded, joined with
##     the device's (ProgressMerge: progress only grows, nobody is asked), the device's file replaced
##     by the joined copy (the screens read it as they open), and the joined copy sent back when it
##     differs from the cloud's;
##   - SAVE_DELAY_S after the progress changes (ProgressStore.written), and when the app goes to the
##     back: the device's copy is sent (only its progress, ProgressMerge.for_cloud);
##   - 처음부터 다시 하기 marks the reset time (mark_reset), so the other devices drop their progress
##     instead of bringing it back.
## Purchases are not in it (Play's billing knows them), nor the settings or the map position.
##
## The backend is Play Games (the GodotPlayGameServices plugin, only in the "Android Play" preset's
## Gradle build with the game id set: PlayGames). Elsewhere there is none: the switch says it cannot
## be used here. Tests put in their own (a RefCounted with start(on_ready), load(on_loaded),
## save(text, on_saved)).
class_name CloudSync
extends Node

## The state changed (the settings card redraws).
signal changed
## The device's progress was replaced by a joined copy with more in it (a screen may read again).
signal progress_merged

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "sync"
const SNAPSHOT := "progress"
const SAVE_DELAY_S := 3.0
## States (status).
const OFF := "off"
const NO_SERVICE := "no_service"   # this build or device has no Play Games
const SIGNING_IN := "signing_in"
const SYNCING := "syncing"
const SYNCED := "synced"
const FAILED := "failed"

## The sync in use (App makes it; tests make their own).
static var instance: CloudSync
## Tests: the settings file (the switch).
static var settings_path := SETTINGS_PATH

var backend: RefCounted
var status := OFF
var _ready_backend := false
var _save_left := -1.0
var _busy := false


## The sync of this run: Play Games when the plugin is in the build, else no backend.
static func make() -> CloudSync:
	var sync := CloudSync.new()
	sync.name = "CloudSync"
	if Engine.has_singleton(PlayGames.PLUGIN):
		sync.backend = PlayGames.new()
	return sync


## The guardian turned it on (the switch in settings.cfg).
static func is_on() -> bool:
	var config := ConfigFile.new()
	config.load(settings_path)
	return bool(config.get_value(SECTION, "on", false))


static func _store_on(on: bool) -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value(SECTION, "on", on)
	config.save(settings_path)


func _ready() -> void:
	instance = self
	ProgressStore.written = _on_written
	_refresh_status()
	if is_on():
		_start()


func _exit_tree() -> void:
	if instance == self:
		instance = null
	if ProgressStore.written == Callable(self, "_on_written"):
		ProgressStore.written = Callable()


## The settings (after the parental gate): on starts it now, off stops sending (the cloud copy stays
## in the guardian's account; Play Games' own settings delete it).
func set_on(on: bool) -> void:
	_store_on(on)
	if on:
		_start()
	else:
		_save_left = -1.0
		_refresh_status()


## 처음부터 다시 하기 was done (the device's file is gone): with the sync on, the reset time goes in
## the new file and to the cloud, so the other devices start over too.
func mark_reset() -> void:
	if not is_on() or ProgressStore.path != ProgressStore.sync_path:
		return
	var config := ConfigFile.new()
	config.set_value(ProgressMerge.SYNC, ProgressMerge.RESET, int(Time.get_unix_time_from_system()))
	ProgressStore.replace_text(config.encode_to_text())
	_send_now()


func _refresh_status() -> void:
	var was := status
	if not is_on():
		status = OFF
	elif backend == null:
		status = NO_SERVICE
	elif status == OFF or status == NO_SERVICE:
		status = SIGNING_IN
	if status != was:
		changed.emit()


func _set_status(value: String) -> void:
	if value != status:
		status = value
		changed.emit()


func _start() -> void:
	_refresh_status()
	if backend == null:
		return
	if _ready_backend:
		_pull()
		return
	_set_status(SIGNING_IN)
	backend.call("start", func(ok: bool) -> void:
		_ready_backend = ok
		if not ok:
			_set_status(FAILED)
		elif is_on():
			_pull())


## Load the cloud copy, join it with the device's, keep and send the joined copy.
func _pull() -> void:
	if _busy or not _ready_backend:
		return
	_busy = true
	_set_status(SYNCING)
	backend.call("load", func(ok: bool, remote: String) -> void:
		_busy = false
		if not ok:
			_set_status(FAILED)
			return
		var local := ProgressStore.file_text()
		var merged := ProgressMerge.merge(local, remote)
		if ProgressMerge.for_cloud(merged) != ProgressMerge.for_cloud(local):
			ProgressStore.replace_text(merged)
			progress_merged.emit()
		if ProgressMerge.for_cloud(merged) != ProgressMerge.for_cloud(remote):
			_send(ProgressMerge.for_cloud(merged))
		else:
			_set_status(SYNCED))


func _on_written() -> void:
	if is_on() and _ready_backend:
		_save_left = SAVE_DELAY_S


func _process(delta: float) -> void:
	if _save_left < 0.0:
		return
	_save_left -= delta
	if _save_left < 0.0:
		_send_now()


func _send_now() -> void:
	_save_left = -1.0
	if is_on() and _ready_backend:
		_send(ProgressMerge.for_cloud(ProgressStore.file_text()))


func _send(text: String) -> void:
	_set_status(SYNCING)
	backend.call("save", text, func(ok: bool) -> void: _set_status(SYNCED if ok else FAILED))


## To the back: the copy goes now. To the front: the cloud copy is joined again (another device may
## have played meanwhile).
func _notification(what: int) -> void:
	if not is_on() or backend == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _save_left >= 0.0:
			_send_now()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_start()


## Google Play Games (the GodotPlayGameServices plugin's Android singleton, v3.4.0): started only
## here (PlayGamesSdk.initialize happens in the plugin's initialize()), signed in automatically, or
## through Play Games' sign-in sheet when the guardian has no profile yet. One snapshot SNAPSHOT;
## its progress value is the stamp total (Play keeps the higher one in a conflict it settles itself).
class PlayGames:
	extends RefCounted
	const PLUGIN := "GodotPlayGameServices"
	var plugin: Object
	var _on_ready := Callable()
	var _on_loaded := Callable()
	var _on_saved := Callable()
	var _asked_sign_in := false

	func start(on_ready: Callable) -> void:
		_on_ready = on_ready
		if plugin == null:
			plugin = Engine.get_singleton(PLUGIN)
			plugin.connect("userAuthenticated", _authenticated)
			plugin.connect("gameLoaded", _loaded)
			plugin.connect("gameSaved", func(ok: bool, _name: String, _description: String) -> void:
				if _on_saved.is_valid():
					_on_saved.call(ok))
			plugin.connect("conflictEmitted", func(_json: String) -> void:
				if _on_loaded.is_valid():   # (Play settles it on the next open; we join on load anyway)
					_on_loaded.call(false, ""))
			plugin.call("initialize")
		_asked_sign_in = false
		plugin.call("isAuthenticated")

	func _authenticated(ok: bool) -> void:
		if not ok and not _asked_sign_in:
			_asked_sign_in = true
			plugin.call("signIn")   # (the guardian just turned it on: Play Games' sheet)
			return
		if _on_ready.is_valid():
			_on_ready.call(ok)

	func load(on_loaded: Callable) -> void:
		_on_loaded = on_loaded
		plugin.call("loadGame", SNAPSHOT, true)

	func _loaded(json: String) -> void:
		var parsed: Variant = JSON.parse_string(json)
		var text := ""
		if parsed is Dictionary:
			text = CloudSync.content_text(parsed.get("content"))
		if _on_loaded.is_valid():
			_on_loaded.call(parsed is Dictionary or json == "", text)

	func save(text: String, on_saved: Callable) -> void:
		_on_saved = on_saved
		var stamps := 0
		var config := ConfigFile.new()
		if config.parse(text) == OK and config.has_section("progress"):
			for key in config.get_section_keys("progress"):
				stamps += int(config.get_value("progress", key, 0))
		plugin.call("saveGame", SNAPSHOT, Locale.t("app.title"), text.to_utf8_buffer(), 0, stamps)


## A snapshot's content as the plugin hands it over (bytes, a list of byte values, or text) as text.
static func content_text(content: Variant) -> String:
	if content is PackedByteArray:
		return (content as PackedByteArray).get_string_from_utf8()
	if content is Array:
		var bytes := PackedByteArray()
		for b in content:
			bytes.append(int(b) & 0xff)
		return bytes.get_string_from_utf8()
	if content is String:
		return content
	return ""
