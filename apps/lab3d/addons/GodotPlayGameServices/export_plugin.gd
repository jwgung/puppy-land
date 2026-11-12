@tool
extends EditorPlugin
## godot-play-game-services v3.4.0 (MIT, https://github.com/godot-sdk-integrations/godot-play-game-services,
## addons.zip sha256 3a1af78f5b9cbf13253b6bffb7795f0c1a9e7d1495052cd456bb6cfb1c265edd), changed for
## puppy-land (#103, ADR 0006):
##   - only the AARs, the LICENSE and this file are kept: its GDScript wrappers need its autoload, which
##     this app does not use (CloudSync talks to the Android singleton itself), so no autoload is added;
##   - the AAR, its dependencies and the APP_ID manifest entry go in only in a Gradle build with the
##     export option godot_play_game_services/game_id set (the "Android Play" preset once Play Console
##     has the games project): elsewhere the app is built without Play Games at all.

var _export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "GodotPlayGameServices"
	const GAME_ID := "godot_play_game_services/game_id"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_name() -> String:
		return PLUGIN_NAME

	## On: a Gradle build with the game id (Play Console > Play Games Services > Configuration).
	func _on() -> bool:
		return bool(get_option("gradle_build/use_gradle_build")) and str(get_option(GAME_ID)) != ""

	func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not _on():
			return
		var file := FileAccess.open("res://android/build/res/values/godot_play_game_services.xml", FileAccess.WRITE)
		if file == null:
			printerr("[%s] cannot write the game id resource" % PLUGIN_NAME)
			return
		file.store_string("<?xml version=\"1.0\" encoding=\"utf-8\"?><resources><string translatable=\"false\" name=\"game_services_project_id\">%s</string></resources>" % str(get_option(GAME_ID)).xml_escape())

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if not _on():
			return PackedStringArray()
		var kind := "debug" if debug else "release"
		return PackedStringArray(["%s/bin/%s/%s-%s.aar" % [PLUGIN_NAME, kind, PLUGIN_NAME, kind]])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not _on():
			return PackedStringArray()
		return PackedStringArray(["com.google.code.gson:gson:2.11.0", "com.google.android.gms:play-services-games-v2:21.0.0"])

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not _on():
			return ""
		return "<meta-data android:name=\"com.google.android.gms.games.APP_ID\" android:value=\"@string/game_services_project_id\"/>"

	func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
		if not _supports_platform(platform):
			return []
		return [{"option": {"name": GAME_ID, "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE,
			"hint_string": "Play Games Services project id (Play Console)"}, "default_value": ""}]
