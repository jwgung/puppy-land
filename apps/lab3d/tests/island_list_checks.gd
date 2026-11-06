## The islands (#69, 2026-11-06): the island list (content/islands/index.json), the island in use
## ([map] island, the app opens on the last one), an island opens when every spot of the island
## before it is complete (computed from the stamps, nothing saved), the island-level saves keyed by
## island (the first island keeps the bare keys of a save from before the islands) and no experiment
## on two islands (the spot-level saves are keyed by experiment id).
extends RefCounted

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH
	ProgressStore.reset_all()
	check_island_list()
	check_no_spot_on_two_islands()
	check_current_island()
	check_open_after_previous()
	check_island_keys()
	check_story_per_island()
	ProgressStore.reset_all()
	Island.use_index([])
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.path = saved_path


## The list reads from content/islands/index.json: the mechanics island first (the saves' bare keys
## are its), every island's file reads without a problem and opens after an island of the list.
func check_island_list() -> void:
	var problems := []
	var ids := Island.ids()
	if ids.is_empty() or ids[0] != ProgressStore.FIRST_ISLAND:
		problems.append("first island %s (want %s)" % [str(ids), ProgressStore.FIRST_ISLAND])
	for id in ids:
		var island := Island.by_id(id)
		if island.problem != "":
			problems.append("%s: %s" % [id, island.problem])
		if island.id != id:
			problems.append("%s reads as %s" % [id, island.id])
		var after := str(Island.entry(id).get("opens_after", ""))
		if after != "" and after not in ids:
			problems.append("%s opens after %s, not an island" % [id, after])
	if str(Island.entry(ids[0] if not ids.is_empty() else "").get("opens_after", "")) != "":
		problems.append("the first island waits for another")
	expect.call(problems.is_empty(), "islands: the list reads from content/islands/index.json (mechanics first, every file reads)",
		"; ".join(problems) if not problems.is_empty() else str(ids))


## The spot-level saves (stamps, cleared runs, flags, clues, pieces, guides) are keyed by experiment
## id: an experiment on two islands would share them, so no experiment is.
func check_no_spot_on_two_islands() -> void:
	var seen := {}
	var twice := []
	for id in Island.ids():
		for spot in Island.by_id(id).spots():
			if seen.has(spot):
				twice.append("%s (%s, %s)" % [spot, seen[spot], id])
			seen[spot] = id
	expect.call(twice.is_empty(), "islands: no experiment is on two islands (the spot saves are keyed by experiment id)",
		", ".join(twice) if not twice.is_empty() else "%d spots" % seen.size())


## The island in use: the first island when nothing (or an unknown island) is saved; set_current
## saves it and Island.current() / Story read it.
func check_current_island() -> void:
	Island.use_index(_two_islands())
	ProgressStore.reset_all()
	Island.forget_current()
	var problems := []
	if Island.current_id() != "mechanics":
		problems.append("nothing saved: %s" % Island.current_id())
	Island.set_current("hutton")
	if Island.current_id() != "hutton" or ProgressStore.current_island() != "hutton":
		problems.append("set hutton: %s, saved %s" % [Island.current_id(), ProgressStore.current_island()])
	Island.forget_current()
	if Island.current_id() != "hutton":
		problems.append("the app opens on the last island: %s" % Island.current_id())
	if Island.current().id != "hutton":
		problems.append("current() is %s" % Island.current().id)
	ProgressStore.set_current_island("nowhere")
	Island.forget_current()
	if Island.current_id() != "mechanics":
		problems.append("an unknown saved island: %s" % Island.current_id())
	Island.set_current("mechanics")
	expect.call(problems.is_empty(), "islands: the island in use is saved ([map] island) and the app opens on it (else the first)",
		"; ".join(problems))


## An island opens when every spot of the island before it is complete (all its stages stamped);
## the first is always open. Nothing is saved for it: a child who finished the mechanics island before
## the update finds the next island open.
func check_open_after_previous() -> void:
	Island.use_index(_two_islands())
	var mechanics := Island.by_id("mechanics")
	var full := {}
	for spot in mechanics.spots():
		full[spot] = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
	var one_short := full.duplicate()
	one_short[mechanics.order[-1]] = int(one_short[mechanics.order[-1]]) - 1
	var problems := []
	if not Island.is_open("mechanics", {}):
		problems.append("the first island is closed")
	if Island.is_open("hutton", {}):
		problems.append("hutton open with no stamps")
	if Island.is_open("hutton", one_short):
		problems.append("hutton open with one stage short")
	if not Island.is_open("hutton", full):
		problems.append("hutton closed with every mechanics spot complete")
	if Island.is_open("nowhere", full):
		problems.append("an unknown island is open")
	if Island.from_data({}).complete(full):
		problems.append("a broken island (no spots) counts as complete")
	ProgressStore.set_current_island("hutton")
	Island.set_current("hutton")
	ProgressStore.reset_all()
	if Island.current_id() != "mechanics":
		problems.append("after a reset the island in use is %s" % Island.current_id())
	if mechanics.complete(one_short) or not mechanics.complete(full):
		problems.append("complete(): one short %s, full %s" % [mechanics.complete(one_short), mechanics.complete(full)])
	expect.call(problems.is_empty(), "islands: an island opens when every spot of the one before is complete (computed from the stamps)",
		"; ".join(problems))


## The island-level saves: the first island keeps the bare keys (a save from before the islands reads
## as the mechanics island's, nothing to move); another island's key carries its id.
func check_island_keys() -> void:
	Island.use_index(_two_islands())
	ProgressStore.reset_all()
	var problems := []
	if ProgressStore.island_key("mechanics", "prologue") != "prologue":
		problems.append("mechanics key %s" % ProgressStore.island_key("mechanics", "prologue"))
	if ProgressStore.island_key("hutton", "prologue") != "hutton.prologue":
		problems.append("hutton key %s" % ProgressStore.island_key("hutton", "prologue"))
	# A save from before the islands: the bare keys.
	var config := ConfigFile.new()
	config.set_value(ProgressStore.STORY, "prologue", true)
	config.set_value(ProgressStore.MAP, "last_spot", "spring")
	config.save(ProgressStore.path)
	Island.set_current("mechanics")
	if not Story.prologue_seen() or ProgressStore.last_spot("mechanics") != "spring":
		problems.append("an old save is not the mechanics island's: prologue %s, last spot %s" % [Story.prologue_seen(), ProgressStore.last_spot("mechanics")])
	Island.set_current("hutton")
	if Story.prologue_seen() or Story.finale_seen() or ProgressStore.last_spot("hutton") != "":
		problems.append("hutton reads the mechanics island's marks")
	Story.mark_seen("prologue")
	ProgressStore.set_last_spot("hutton", "friction")
	Island.set_current("mechanics")
	if Story.finale_seen() or ProgressStore.last_spot("mechanics") != "spring":
		problems.append("hutton's marks changed the mechanics island's")
	config = ConfigFile.new()
	config.load(ProgressStore.path)
	if config.get_value(ProgressStore.STORY, "hutton.prologue", false) != true or config.get_value(ProgressStore.MAP, "hutton.last_spot", "") != "friction":
		problems.append("hutton's keys: %s" % str(config.get_section_keys(ProgressStore.STORY)))
	ProgressStore.set_last_spot("hutton", "")
	if ProgressStore.last_spot("hutton") != "" or ProgressStore.last_spot("mechanics") != "spring":
		problems.append("clearing hutton's last spot")
	expect.call(problems.is_empty(), "islands: the island-level saves carry the island id (the first island keeps the bare keys of an old save)",
		"; ".join(problems))


## The story's file is the island's (content/story/<id>.json, its words content/locale/<lang>/story/<id>.json).
func check_story_per_island() -> void:
	Island.use_index([])
	Island.forget_current()
	Story.forget_loaded()
	var problems := []
	if Story.content_path("mechanics") != "res://content/story/mechanics.json":
		problems.append(Story.content_path("mechanics"))
	if Story.pages("prologue").is_empty() or Story.wrong_line() == "":
		problems.append("the mechanics story has no prologue or wrong-spot line")
	expect.call(problems.is_empty(), "islands: the story is the island's file (content/story/<id>.json and its words)",
		"; ".join(problems))


## The real first island plus a second laid out like it (the real hutton island's spots are not
## experiments yet, so it never opens: hutton_map_checks): enough to check the list's logic.
static func _two_islands() -> Array:
	return [
		{"id": "mechanics", "file": "mechanics.json"},
		{"id": "hutton", "file": "mechanics.json", "opens_after": "mechanics"},
	]
