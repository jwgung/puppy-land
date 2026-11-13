## Merging two copies of the progress file (#103, ADR 0006: 기기 사이 기록 맞추기): this device's
## (ProgressStore's file text) and the one kept in the cloud (Play Games Saved Games). Pure: text in,
## text out, nothing read or written here.
##
## A child's progress only grows, so the copies are joined and no one is asked which to keep:
##   [progress]          stamps: the larger
##   [cleared]           the controls that cleared a spot's last stage: the copy with more stamps for
##                       that spot (a tie: this device's)
##   [flags] [pieces]    false = still to play on the map, true = played; a missing key is played:
##                       true on either side wins, else a false on either side stays
##   [story] [clues] [guides]  marks: true on either side
##   [day]               the day limit (DailyLimit, #77): the copy with the later `<island>.date`
##                       keeps its `.spot` and `.date` (a tie: this device's)
##   [map]               where the trio stands, the island in use: this device's only, never sent
##   [sync] reset        when 처음부터 다시 하기 was last done (unix seconds, 0: never): the copy reset
##                       later wins over the other's progress altogether (the reset reaches the
##                       other device instead of being undone by it)
##   any other section   (a future one) this device's keys, then the other's keys it lacks
class_name ProgressMerge
extends RefCounted

## Sections that stay on the device (not sent, not taken from the cloud).
const LOCAL_ONLY := ["map"]
const SYNC := "sync"
const RESET := "reset"
const MAX_SECTIONS := ["progress"]
const MARK_SECTIONS := ["story", "clues", "guides"]
const PENDING_SECTIONS := ["flags", "pieces"]


## The progress text to send: the file without its device-only sections.
static func for_cloud(text: String) -> String:
	var config := _parse(text)
	for section in LOCAL_ONLY:
		if config.has_section(section):
			config.erase_section(section)
	return config.encode_to_text()


## When the copy was last reset (0: never).
static func reset_time(text: String) -> int:
	return int(_parse(text).get_value(SYNC, RESET, 0))


## The merged progress for this device: `local` (this device's file text) joined with `remote` (the
## cloud's, already without device-only sections). An empty or unreadable side counts as no progress.
static func merge(local: String, remote: String) -> String:
	var a := _parse(local)
	var b := _parse(remote)
	var out := ConfigFile.new()
	var reset_a := int(a.get_value(SYNC, RESET, 0))
	var reset_b := int(b.get_value(SYNC, RESET, 0))
	if reset_b > reset_a:   # the cloud's copy was reset later: its progress only
		_copy_sections(b, out, [])
	elif reset_a > reset_b:
		_copy_sections(a, out, LOCAL_ONLY)
	else:
		_join(a, b, out)
	for section in LOCAL_ONLY:   # this device's own, whatever happened to the progress
		if a.has_section(section):
			for key in a.get_section_keys(section):
				out.set_value(section, key, a.get_value(section, key))
	var reset := maxi(reset_a, reset_b)
	if reset > 0:
		out.set_value(SYNC, RESET, reset)
	return out.encode_to_text()


static func _join(a: ConfigFile, b: ConfigFile, out: ConfigFile) -> void:
	var sections := []
	for config in [a, b]:
		for section in config.get_sections():
			if section not in sections and section not in LOCAL_ONLY and section != SYNC:
				sections.append(section)
	for section in sections:
		var keys := _keys(a, b, section)
		for key in keys:
			var has_a := a.has_section_key(section, key)
			var has_b := b.has_section_key(section, key)
			var va: Variant = a.get_value(section, key) if has_a else null
			var vb: Variant = b.get_value(section, key) if has_b else null
			var value: Variant
			if not has_b:
				value = va
			elif not has_a:
				value = vb
			elif section in MAX_SECTIONS:
				value = maxi(_int(va), _int(vb))
			elif section in MARK_SECTIONS:
				value = (va is bool and va) or (vb is bool and vb)
			elif section in PENDING_SECTIONS:
				value = (va is bool and va) or (vb is bool and vb)
			elif section == "cleared":
				value = vb if _stamps(b, key) > _stamps(a, key) else va
			elif section == "day":
				continue   # (by island, below)
			else:
				value = va
			out.set_value(section, key, value)
	_join_days(a, b, out)


## [day]: per island, the pair (`<island>.spot`, `<island>.date`) of the later date.
static func _join_days(a: ConfigFile, b: ConfigFile, out: ConfigFile) -> void:
	var islands := []
	for key in _keys(a, b, "day"):
		var island: String = key.get_slice(".", 0) if "." in key else ""
		if key.ends_with(".date") or key == "date":
			if island not in islands:
				islands.append(island)
	for island in islands:
		var prefix: String = island + "." if island != "" else ""
		var date_a := str(a.get_value("day", prefix + "date", ""))
		var date_b := str(b.get_value("day", prefix + "date", ""))
		var from := b if date_b > date_a else a
		for field in ["spot", "date"]:
			if from.has_section_key("day", prefix + field):
				out.set_value("day", prefix + field, from.get_value("day", prefix + field))


static func _copy_sections(from: ConfigFile, out: ConfigFile, skip: Array) -> void:
	for section in from.get_sections():
		if section in skip or section == SYNC:
			continue
		for key in from.get_section_keys(section):
			out.set_value(section, key, from.get_value(section, key))


static func _keys(a: ConfigFile, b: ConfigFile, section: String) -> Array:
	var keys := []
	for config in [a, b]:
		if config.has_section(section):
			for key in config.get_section_keys(section):
				if key not in keys:
					keys.append(key)
	return keys


static func _stamps(config: ConfigFile, id: String) -> int:
	return _int(config.get_value("progress", id, 0))


static func _int(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	if value is String and (value as String).is_valid_int():
		return (value as String).to_int()
	return 0


static func _parse(text: String) -> ConfigFile:
	var config := ConfigFile.new()
	if text.strip_edges() == "" or config.parse(text) != OK:
		return ConfigFile.new()
	return config
