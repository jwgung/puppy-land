## The voyage and 섬 고르기 (#75, 2026-11-06 user-approved mocks A1 and B1): the voyage to the next
## island is due once that island is open and the finale of the one before was seen, plays once
## (again with 이야기 다시 보기 there), its pages set the shots (the keeper only at the landing, the
## next island flickering), 건너뛰기 and Android back skip it, and it ends on the next island's map with
## its prologue; the finale's end leads to it. The title's 시작하기 opens 섬 고르기 only after a voyage
## (before, it goes straight on); the islands' map (#116) shows every island on one sea with its tag
## and 다음 섬 (곧 만나요), a locked one with its lock and condition and no button, an open one's button
## (출발! · 이어서 하기 · 다시 가기), its tag or the island itself makes it the island in use (another one
## after the boat's sail on the map); ← 돌아가기 and Android back close the map. The developer switch --islands=open is ignored in the Play build. Phone and tablet layouts.
extends RefCounted

var tree: SceneTree
var expect: Callable
const APP := "res://scripts/app/app.gd"
const PHONE := Vector2(1560, 720)
const TABLET := Vector2(1152, 720)
const UiScale := preload("res://tests/ui_scale_checks.gd")   # PHONE_ZOOMED (화면 크기)
const NEXT := "hutton"


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var quality_script: GDScript = load("res://scripts/core/quality.gd")
	var saved_args = quality_script.get("_args_cache")
	var saved_path := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH
	ProgressStore.reset_all()
	check_dev_switch()
	check_content()
	check_due_rule()
	TitleScreen.app_may_show = true
	Story.app_may_enable = true
	await check_voyage_flow(quality_script)
	await check_finale_leads_on(quality_script)
	await check_skip_and_replay(quality_script)
	await check_title_islands(quality_script)
	await check_map_back()
	await check_sail()
	await check_layout()
	TitleScreen.app_may_show = false
	Story.app_may_enable = false
	Story.enabled = false
	Island.set_dev_open(false)
	quality_script.set("_args_cache", saved_args)
	ProgressStore.reset_all()
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.path = saved_path


## The next island still in the making (#98 made hutton playable): its entry with no map file, so it
## is not playable; `_made()` puts the real islands back.
func _in_making() -> void:
	Island.use_index([{"id": ProgressStore.FIRST_ISLAND, "file": "mechanics.json"}, {"id": NEXT, "opens_after": ProgressStore.FIRST_ISLAND, "product": "island_hutton"}])


func _made() -> void:
	Island.use_index([])


## Every spot of the first island complete and its finale (and prologue) seen.
func _first_done() -> void:
	ProgressStore.reset_all()
	var store := {}
	for spot in Island.by_id(ProgressStore.FIRST_ISLAND).spots():
		store[spot] = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
	ProgressStore.save(store)
	ProgressStore.set_mark(ProgressStore.STORY, "prologue", true)
	ProgressStore.set_mark(ProgressStore.STORY, "finale", true)
	Island.forget_current()
	Story.forget_loaded()


func check_dev_switch() -> void:
	var args := PackedStringArray(["--islands=open"])
	expect.call(Quality.dev_arg(args, "islands", false) == "open" and Quality.dev_arg(args, "islands", true) == "",
		"voyage: --islands=open is a developer switch (ignored in the Play build)", "")


## The next island's story: the voyage's pages (the shots in order, the keeper last) and its prologue,
## words in every language.
func check_content() -> void:
	var problems := []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Story.content_path(NEXT)))
	problems.append_array(Story.validate(parsed if parsed is Dictionary else {}))
	var voyage := Story.pages_of(NEXT, "voyage")
	var shots := voyage.map(func(e: Dictionary) -> String: return str(e.get("shot", "")))
	var order := []
	for s in shots:
		if order.is_empty() or order[-1] != s:
			order.append(s)
	if order != Story.VOYAGE_SHOTS:
		problems.append("shots %s" % str(order))
	if VoyageScreen.SHOTS.keys() != Story.VOYAGE_SHOTS:
		problems.append("VoyageScreen.SHOTS %s" % str(VoyageScreen.SHOTS.keys()))
	if voyage.is_empty() or str(voyage[-1].get("who")) != "fox":
		problems.append("the keeper does not speak last")
	var prologue := Story.pages_of(NEXT, "prologue")
	if prologue.size() != 12:
		problems.append("prologue %d pages" % prologue.size())
	for lang in ["ko", "en"]:
		var words: Variant = Locale._read("res://content/locale/%s/story/%s.json" % [lang, NEXT])
		for part in ["voyage", "prologue"]:
			var list: Array = words.get(part, []) if words is Dictionary else []
			var want := (voyage if part == "voyage" else prologue).size()
			if list.size() != want or list.any(func(e: Variant) -> bool: return not e is Dictionary or str(e.get("text", "")) == ""):
				problems.append("%s %s words" % [lang, part])
	expect.call(problems.is_empty(), "voyage: the next island's story has the voyage (depart, sea, flicker, arrive; the keeper last) and its prologue, words in ko and en",
		"; ".join(problems))


func check_due_rule() -> void:
	Story.enabled = true
	_first_done()
	Island.set_dev_open(false)
	_in_making()
	var in_making := Story.voyage_due(ProgressStore.load()) == ""   # the next island is not playable yet (#72)
	_made()
	var due := Story.voyage_due(ProgressStore.load()) == NEXT   # every hutton spot a lab (#98): open
	Island.set_dev_open(true)
	due = due and Story.voyage_due(ProgressStore.load()) == NEXT
	ProgressStore.set_mark(ProgressStore.STORY, "finale", false)
	var no_finale := Story.voyage_due(ProgressStore.load()) == ""
	ProgressStore.set_mark(ProgressStore.STORY, "finale", true)
	Story.mark_voyage_seen(NEXT)
	var once := Story.voyage_due(ProgressStore.load()) == "" and Story.any_voyage_seen()
	ProgressStore.reset_all()
	var fresh := Story.voyage_due(ProgressStore.load()) == "" and not Story.any_voyage_seen()
	Story.enabled = false
	Island.set_dev_open(false)
	expect.call(in_making and due and no_finale and once and fresh,
		"voyage: due once the next island is open and the finale was seen, never while it is in the making, once only",
		"%s %s %s %s %s" % [in_making, due, no_finale, once, fresh])


func _app(args: Array) -> Control:
	var quality_script: GDScript = load("res://scripts/core/quality.gd")
	quality_script.set("_args_cache", PackedStringArray(args))
	ProgressStore.path = ProgressStore.TEST_PATH
	var app: Control = load(APP).new()
	tree.root.add_child(app)
	app.size = TABLET
	for i in 2:
		await tree.process_frame
	return app


func _free(app: Control) -> void:
	app.queue_free()
	for i in 3:
		await tree.process_frame
	Story.enabled = false
	Island.set_dev_open(false)


## 시작하기 after the first island's finale: the voyage, page by page, then the next island's map with
## its prologue; the voyage's mark and the island in use are saved.
func check_voyage_flow(_quality_script: GDScript) -> void:
	_first_done()
	var app := await _app(["--islands=open"])
	var title_first: bool = app._screen is TitleScreen and not TitleScreen.picks_island()
	(app._screen as TitleScreen).start_button.pressed.emit()
	await tree.process_frame
	var voyage: VoyageScreen = app._screen as VoyageScreen
	var problems := []
	if voyage == null:
		problems.append("no voyage")
	else:
		var pages := Story.pages_of(NEXT, "voyage")
		var max_flicker := 0.0
		for i in pages.size():
			if voyage.page != i or voyage.shot != str(pages[i].shot):
				problems.append("page %d shot %s" % [voyage.page, voyage.shot])
			if voyage.keeper.visible != (voyage.shot == "arrive"):
				problems.append("keeper on %s" % voyage.shot)
			if voyage.star.visible != (voyage.shot == "depart"):
				problems.append("star on %s" % voyage.shot)
			var way_before := voyage.way
			for k in 10:
				voyage.advance(0.25)
				max_flicker = maxf(max_flicker, voyage.flicker)
			if voyage.shot == "sea" and voyage.way <= way_before:
				problems.append("the boat does not sail")
			if voyage.shot != "flicker" and voyage.flicker > 0.0:
				problems.append("flicker on %s" % voyage.shot)
			if not voyage.dialogue.active or voyage.dialogue.speaker != str(pages[i].who):
				problems.append("page %d speaker %s" % [i, voyage.dialogue.speaker])
			voyage.tap_page()   # the whole page
			voyage.tap_page()   # the next
			await tree.process_frame
		if max_flicker < 0.9:
			problems.append("the next island never went dark (%.2f)" % max_flicker)
	await tree.process_frame
	var home: IslandHomeScreen = app._screen as IslandHomeScreen
	var landed := home != null and home.island.id == NEXT and Island.current_id() == NEXT and ProgressStore.current_island() == NEXT \
		and Story.voyage_seen(NEXT) and home.play_prologue_on_open and home.story != null and home.story.part == "prologue"
	# Its prologue: the keeper's words over the square, every page, then the map.
	var pages_seen := 0
	if landed:
		for i in 40:
			if home.story.part != "prologue":
				break
			pages_seen = maxi(pages_seen, home.story.page + 1)
			home.story.tap_page()
			home.story.tap_page()
			for k in 3:
				await tree.process_frame
		for i in 120:
			if home.story.part == "":
				break
			await tree.process_frame
	var prologue_ok := landed and pages_seen == Story.pages_of(NEXT, "prologue").size() and home.story.part == "" and Story.prologue_seen()
	# Once: the map again, no voyage.
	app.show_list()
	await tree.process_frame
	var once: bool = app._screen is IslandHomeScreen
	await _free(app)
	expect.call(title_first and problems.is_empty(), "voyage: 시작하기 after the finale sails: each page's shot (the star as they leave, the keeper only at the landing), the boat moves, the next island flickers dark",
		"%s %s" % [title_first, "; ".join(problems)])
	expect.call(landed and prologue_ok and once, "voyage: it ends on the next island's map (saved as the island in use) with its prologue over the square; once only",
		"landed %s prologue %s (%d pages) once %s" % [landed, prologue_ok, pages_seen, once])


## The finale's end on the first island's map leads to the voyage when the next island is open.
func check_finale_leads_on(_quality_script: GDScript) -> void:
	_first_done()
	var app := await _app(["--islands=open"])
	app._show_map()
	await tree.process_frame
	var home: IslandHomeScreen = app._screen as IslandHomeScreen
	var on_map := home != null and home.story != null
	if on_map:
		home.story.ended.emit("finale")
	await tree.process_frame
	var sails: bool = app._screen is VoyageScreen
	await _free(app)
	# Without the next island open (in the making): the map stays.
	_first_done()
	_in_making()
	app = await _app([])
	app._show_map()
	await tree.process_frame
	home = app._screen as IslandHomeScreen
	if home != null and home.story != null:
		home.story.ended.emit("finale")
	await tree.process_frame
	var stays: bool = app._screen is IslandHomeScreen
	await _free(app)
	_made()
	# The real islands with no switch (#98: every hutton spot a lab): the finale's end sails on.
	_first_done()
	app = await _app([])
	app._show_map()
	await tree.process_frame
	home = app._screen as IslandHomeScreen
	if home != null and home.story != null:
		home.story.ended.emit("finale")
	await tree.process_frame
	var sails_real: bool = app._screen is VoyageScreen
	await _free(app)
	expect.call(on_map and sails and stays and sails_real, "voyage: the finale's end leads to it when the next island is open (with --islands=open and, hutton being whole, without), not while it is in the making",
		"%s %s %s %s" % [on_map, sails, stays, sails_real])


## 건너뛰기 and Android back skip to the next island's map; 이야기 다시 보기 there plays it again.
func check_skip_and_replay(_quality_script: GDScript) -> void:
	_first_done()
	var app := await _app(["--islands=open"])
	app.show_list()
	await tree.process_frame
	var voyage := app._screen as VoyageScreen
	var shown := voyage != null and voyage.skip_button.visible
	if voyage != null:
		voyage.skip_button.pressed.emit()
	await tree.process_frame
	var skipped: bool = app._screen is IslandHomeScreen and Island.current_id() == NEXT and Story.voyage_seen(NEXT)
	# Android back skips it too.
	Island.set_current(ProgressStore.FIRST_ISLAND)
	ProgressStore.set_mark(ProgressStore.STORY, ProgressStore.island_key(NEXT, "voyage"), false)
	app.show_list()
	await tree.process_frame
	var again: bool = app._screen is VoyageScreen
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	for i in 3:
		await tree.process_frame
	var back_skips: bool = app._screen is IslandHomeScreen and Island.current_id() == NEXT
	# 이야기 다시 보기 on the next island: the voyage, then its prologue.
	app.show_list(true)
	await tree.process_frame
	var replay: bool = app._screen is VoyageScreen
	if replay:
		(app._screen as VoyageScreen).skip()
	await tree.process_frame
	var replay_prologue: bool = app._screen is IslandHomeScreen and (app._screen as IslandHomeScreen).play_prologue_on_open
	# The first island's replay is its own prologue (no voyage).
	Island.set_current(ProgressStore.FIRST_ISLAND)
	app.show_list(true)
	await tree.process_frame
	var first_replay: bool = app._screen is IslandHomeScreen
	await _free(app)
	expect.call(shown and skipped and again and back_skips, "voyage: 건너뛰기 and Android back skip to the next island's map (the voyage counts as seen)",
		"%s %s %s %s" % [shown, skipped, again, back_skips])
	expect.call(replay and replay_prologue and first_replay, "voyage: 이야기 다시 보기 on the next island plays the voyage then its prologue; on the first island its own prologue",
		"%s %s %s" % [replay, replay_prologue, first_replay])


## 섬 고르기 (one way in since 2026-11-09): 시작하기 goes straight to the island before any voyage and
## opens the cards after one; the cards; a tap on a card or its button chooses; back closes them.
func check_title_islands(_quality_script: GDScript) -> void:
	_first_done()
	var app := await _app([])
	(app._screen as TitleScreen).start_button.pressed.emit()
	await tree.process_frame
	var hidden: bool = not (app._screen is TitleScreen) and not TitleScreen.picks_island()   # (straight on: the map or the voyage)
	await _free(app)
	Story.mark_voyage_seen(NEXT)
	# The next island in the making: its card locked, with the first island's name in the condition.
	_in_making()
	app = await _app([])
	var title := app._screen as TitleScreen
	title.start_button.pressed.emit()
	await tree.process_frame
	var shown: bool = TitleScreen.picks_island() and app._screen == title and title.island_cards != null and title.find_child("IslandsButton", true, false) == null
	var cards := title.island_cards
	var problems := []
	if cards == null or title.logo.visible:
		problems.append("no cards")
	else:
		var entries := IslandCards.entries(ProgressStore.load())
		var ids := entries.map(func(e: Dictionary) -> String: return str(e.id))
		if ids != Island.ids() + [""]:
			problems.append("cards %s" % str(ids))
		if cards.buttons.get(ProgressStore.FIRST_ISLAND) == null or cards.buttons.get(NEXT) != null or cards.buttons.get("") != null:
			problems.append("buttons %s" % str(cards.buttons.keys().map(func(k: String) -> bool: return cards.buttons[k] != null)))
		for id in [NEXT, ""]:
			var card: Control = cards.cards[id]
			if card.find_child("Lock", true, false) == null:
				problems.append("no lock on %s" % id)
		var next_line := (cards.cards[NEXT].find_child("About", true, false) as Label).text
		if not IslandCards.island_name(ProgressStore.FIRST_ISLAND) in next_line:
			problems.append("condition %s" % next_line)
		var last_line := (cards.cards[""].find_child("About", true, false) as Label).text
		if last_line != Locale.t("islands.soon"):   # (no island opens after the last: no promise)
			problems.append("next line %s" % last_line)
		if (cards.buttons[ProgressStore.FIRST_ISLAND] as Button).text != Locale.t("islands.again"):
			problems.append("the finished island's button %s" % (cards.buttons[ProgressStore.FIRST_ISLAND] as Button).text)
	# Back closes the cards first.
	app._go_back()
	await tree.process_frame
	var back_closes: bool = app._screen is TitleScreen and title.island_cards == null and title.logo.visible
	await _free(app)
	_made()
	# The next island open: its card's button makes it the island in use and opens its map.
	app = await _app(["--islands=open"])
	title = app._screen as TitleScreen
	title.show_islands()
	await tree.process_frame
	var go: Button = title.island_cards.buttons.get(NEXT)
	var open_card := go != null and go.text == Locale.t("islands.go")   # (nothing found there yet)
	if go != null:
		go.pressed.emit()
	await tree.process_frame
	var sailed: bool = await _sail_through(app)   # another island: the boat's sail first (#116)
	var chosen: bool = sailed and app._screen is IslandHomeScreen and (app._screen as IslandHomeScreen).island.id == NEXT and ProgressStore.current_island() == NEXT
	# A tap on the first island's card itself (not its button) chooses it too.
	app.show_title()
	await tree.process_frame
	title = app._screen as TitleScreen
	title.start_button.pressed.emit()
	await tree.process_frame
	var release := InputEventScreenTouch.new()
	release.pressed = false
	(title.island_cards.cards[ProgressStore.FIRST_ISLAND] as Control).gui_input.emit(release)
	await tree.process_frame
	await _sail_through(app)
	var tap_chose_first: bool = app._screen is IslandHomeScreen and (app._screen as IslandHomeScreen).island.id == ProgressStore.FIRST_ISLAND
	# 이야기 다시 보기: not on the title any more (two islands), on each open card: the next island's
	# plays its voyage again, the first island's its prologue on its map.
	app.show_title()
	await tree.process_frame
	title = app._screen as TitleScreen
	var no_title_story := not title.story_button.visible
	title.start_button.pressed.emit()
	await tree.process_frame
	(title.island_cards.story_buttons[NEXT] as Button).pressed.emit()
	await tree.process_frame
	var next_story: bool = app._screen is VoyageScreen and Island.current_id() == NEXT
	app.show_title()
	await tree.process_frame
	title = app._screen as TitleScreen
	title.start_button.pressed.emit()
	await tree.process_frame
	(title.island_cards.story_buttons[ProgressStore.FIRST_ISLAND] as Button).pressed.emit()
	await tree.process_frame
	var first_story: bool = app._screen is IslandHomeScreen and (app._screen as IslandHomeScreen).island.id == ProgressStore.FIRST_ISLAND \
		and (app._screen as IslandHomeScreen).play_prologue_on_open
	await _free(app)
	expect.call(no_title_story and next_story and first_story, "섬 고르기: 이야기 다시 보기 is on each island's card (not the title): the next island's plays its voyage again, the first island's its prologue",
		"%s %s %s" % [no_title_story, next_story, first_story])
	expect.call(hidden and shown, "섬 고르기: 시작하기 goes straight on before a voyage, opens the cards after one (no separate 섬 고르기 button)", "%s %s" % [hidden, shown])
	expect.call(problems.is_empty() and back_closes, "섬 고르기: a card per island and 다음 섬; a locked one grey with a lock, its condition (다음 섬: 곧 만나요), no button; 다시 가기 on a finished island; back closes the cards",
		"; ".join(problems) + " back %s" % back_closes)
	expect.call(open_card and chosen and tap_chose_first, "섬 고르기: an open island's 출발! makes it the island in use and opens its map (after the boat's sail); a tap on its tag does the same",
		"%s %s %s" % [open_card, chosen, tap_chose_first])


## A sail on the islands' map now (IslandCards.sail): ended by a tap; true when there was one.
func _sail_through(app: Control) -> bool:
	var title := app._screen as TitleScreen
	if title == null or title.island_cards == null or title.island_cards.sail.is_empty():
		return false
	title.island_cards._on_pointer("release", Vector2.ZERO)
	await tree.process_frame
	return true


## The islands' map (#116 2026-11-10 user: "이 과학섬들 전체 지도를 보여주고 거기서 넘어오게 하는게 낫지
## 않아?"): every island on one sea with its tag, the boat at the island in use; choosing the island in
## use opens its map at once; another one sails the boat along the sea way (no words, no other screen)
## and opens that island's map when it lands (SAIL_S), a tap lands it at once; a tap on an island
## itself chooses it; Android back during the sail closes the map. --demo-story=islands counts every
## island's prologue as seen too.
func check_sail() -> void:
	_first_done()
	Story.mark_voyage_seen(NEXT)
	ProgressStore.set_mark(ProgressStore.STORY, ProgressStore.island_key(NEXT, "prologue"), true)
	var app := await _app(["--islands=open"])
	var title := app._screen as TitleScreen
	title.show_islands()
	await tree.process_frame
	await tree.process_frame
	var problems := []
	var map := title.island_cards
	if map.view == null or map.boat == null or title.view.visible:
		problems.append("no world view and boat, or the title's view still drawn")
	elif map.boat.position.distance_to(map._shore(ProgressStore.FIRST_ISLAND, 1.0)) > 0.5:
		problems.append("the boat is not at the island in use (%s)" % str(map.boat.position))
	for entry in IslandCards.entries(ProgressStore.load()):
		var tag: Control = map.cards[entry.id]
		var island := map._island_rect(str(entry.id))
		if tag.get_global_rect().get_center().y < island.get_center().y or absf(tag.get_global_rect().get_center().x - island.get_center().x) > island.size.x * 0.6 + 20.0:
			problems.append("the tag of %s is not under its island" % entry.id)
	# The island in use: its map at once.
	(map.buttons[ProgressStore.FIRST_ISLAND] as Button).pressed.emit()
	await tree.process_frame
	if not app._screen is IslandHomeScreen:
		problems.append("the island in use did not open at once (%s)" % app._screen)
	# Another: the boat sails the sea way (the same screen, the tags hidden) and lands by itself.
	app.show_title(true)
	await tree.process_frame
	map = (app._screen as TitleScreen).island_cards
	(map.buttons[NEXT] as Button).pressed.emit()
	await tree.process_frame
	var start := map.boat.position
	for i in 40:
		await tree.process_frame
	if map.sail.is_empty() or map.boat.position.distance_to(start) < 1.0 or map.cards[NEXT].visible or not app._screen is TitleScreen:
		problems.append("no sail on the map (%s)" % str(map.sail))
	for i in roundi(IslandCards.SAIL_S * 60.0) + 30:
		if not app._screen is TitleScreen:
			break
		await tree.process_frame
	if not (app._screen is IslandHomeScreen and Island.current_id() == NEXT and not (app._screen as IslandHomeScreen).play_prologue_on_open):
		problems.append("the sail did not land on %s's map (%s)" % [NEXT, app._screen])
	# A tap on an island itself chooses it; a tap during the sail lands it at once.
	app.show_title(true)
	await tree.process_frame
	await tree.process_frame
	map = (app._screen as TitleScreen).island_cards
	map._on_pointer("release", map._island_rect(ProgressStore.FIRST_ISLAND).get_center())
	await tree.process_frame
	var tap_sails := not map.sail.is_empty()
	map._on_pointer("release", Vector2(5.0, 5.0))
	await tree.process_frame
	if not (tap_sails and app._screen is IslandHomeScreen and Island.current_id() == ProgressStore.FIRST_ISLAND):
		problems.append("a tap on the island %s, then a tap: %s" % [tap_sails, app._screen])
	# Android back during a sail closes the map (the title again).
	app.show_title(true)
	await tree.process_frame
	((app._screen as TitleScreen).island_cards.buttons[NEXT] as Button).pressed.emit()
	await tree.process_frame
	app._go_back()
	await tree.process_frame
	if not (app._screen is TitleScreen and (app._screen as TitleScreen).island_cards == null and Island.current_id() == ProgressStore.FIRST_ISLAND):
		problems.append("back during the sail: %s" % app._screen)
	await _free(app)
	# --demo-story=islands: the next island's prologue counts as seen (the sail lands on its map).
	ProgressStore.reset_all()
	app = await _app(["--demo-story=islands", "--islands=open"])
	if not ProgressStore.mark(ProgressStore.STORY, ProgressStore.island_key(NEXT, "prologue")):
		problems.append("--demo-story=islands left %s's prologue unseen" % NEXT)
	await _free(app)
	expect.call(problems.is_empty(), "섬 고르기 map: the islands on one sea, tags under them, the boat at the island in use; the island in use opens at once, another after the boat sails there (a tap lands it, a tap on an island chooses it, back closes the map); --demo-story=islands sees every prologue",
		"; ".join(problems))


## The map's ← (top left, #114) and Android back on the map: the islands' map once a voyage was seen,
## the title before. The story's emblem sits right of ←, both clear of the top left edges.
func check_map_back() -> void:
	_first_done()
	var app := await _app([])
	app._show_map()   # (the map itself, not the voyage due)
	await tree.process_frame
	await tree.process_frame
	var home := app._screen as IslandHomeScreen
	var back: Button = home.find_child("MapBackButton", true, false) if home != null else null
	var problems := []
	if back == null or not back.visible:
		problems.append("no ←")
	else:
		var rect := back.get_global_rect()
		if rect.position.x < IslandHomeScreen.MAP_EDGE - 0.5 or rect.position.y < IslandHomeScreen.MAP_EDGE - 0.5 or rect.get_center().x > home.size.x * 0.25:
			problems.append("← not in the top left %s" % str(rect))
		if back.text != Locale.t("islands.back"):   # (worded as the islands' map's, #116)
			problems.append("← text %s" % back.text)
		if home.story != null and home.story.emblem.visible and home.story.emblem.get_global_rect().intersects(rect):
			problems.append("the emblem over ← %s" % str(home.story.emblem.get_global_rect()))
		back.pressed.emit()
	await tree.process_frame
	var title_before: bool = app._screen is TitleScreen and (app._screen as TitleScreen).island_cards == null
	await _free(app)
	Story.mark_voyage_seen(NEXT)
	_in_making()
	app = await _app([])
	app._show_map()   # (the map itself, not the voyage due)
	await tree.process_frame
	(app._screen.find_child("MapBackButton", true, false) as Button).pressed.emit()
	await tree.process_frame
	var cards_button: bool = app._screen is TitleScreen and (app._screen as TitleScreen).island_cards != null
	app._show_map()   # (the map itself, not the voyage due)
	await tree.process_frame
	app._go_back()
	await tree.process_frame
	var cards_android: bool = app._screen is TitleScreen and (app._screen as TitleScreen).island_cards != null
	await _free(app)
	_made()
	expect.call(problems.is_empty() and title_before and cards_button and cards_android,
		"map ← 돌아가기 (worded as the islands' map's, #116): top left, the emblem beside it; ← and Android back go to the title before a voyage, to the islands' map after one",
		"; ".join(problems) + " %s %s %s" % [title_before, cards_button, cards_android])


## Phone, tablet, phone zoomed: the title's buttons, 섬 고르기's map (its tags) and the voyage's box and
## 건너뛰기 all on screen, nothing overlapping.
func check_layout() -> void:
	_first_done()
	Story.mark_voyage_seen(NEXT)
	Island.set_dev_open(true)
	Story.enabled = true
	for size in [PHONE, TABLET, UiScale.PHONE_ZOOMED]:
		var host := Control.new()
		host.theme = UiTheme.build()
		host.size = size
		tree.root.add_child(host)
		var title := TitleScreen.new()
		host.add_child(title)
		for i in 3:
			await tree.process_frame
		var screen := Rect2(Vector2.ZERO, size)
		var problems := []
		var rects := title.rects()
		if rects.size() != 3:   # (a voyage seen: 이야기 다시 보기 is on the islands' map's tags, not the title)
			problems.append("title rects %d" % rects.size())
		for r in rects:
			if not screen.encloses(r):
				problems.append("title %s off screen" % r)
		for a in range(1, rects.size()):
			for b in range(a + 1, rects.size()):
				if rects[a].intersects(rects[b]):
					problems.append("title buttons %d %d overlap" % [a, b])
		title.show_islands()
		for i in 3:
			await tree.process_frame
		var card_rects := title.island_cards.rects()
		for r in card_rects:
			if not screen.encloses(r):
				problems.append("cards %s off screen" % r)
		for a in card_rects.size():
			for b in range(a + 1, card_rects.size()):
				if card_rects[a].intersects(card_rects[b]):
					problems.append("cards %d %d overlap" % [a, b])
		host.queue_free()
		for i in 3:
			await tree.process_frame
		host = Control.new()
		host.theme = UiTheme.build()
		host.size = size
		tree.root.add_child(host)
		var voyage := VoyageScreen.new(NEXT)
		voyage.finished.connect(func(_to: String) -> void: pass)
		host.add_child(voyage)
		for i in 3:
			await tree.process_frame
		var v := voyage.rects()
		for r in v:
			if not screen.encloses(r):
				problems.append("voyage %s off screen" % r)
		if v[0].intersects(v[1]):
			problems.append("건너뛰기 over the box")
		host.queue_free()
		for i in 3:
			await tree.process_frame
		expect.call(problems.is_empty(), "섬 고르기 and voyage (%s): the title's buttons, the cards, the voyage's box and 건너뛰기 on screen, no overlap"
			% ("phone" if size == PHONE else ("tablet" if size == TABLET else "phone zoomed")), "; ".join(problems))
	Story.enabled = false
	Island.set_dev_open(false)
	ProgressStore.reset_all()
