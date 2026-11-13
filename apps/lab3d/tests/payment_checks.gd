## The payment (#77, ADR 0005, 2026-11-08 decisions): the Play build's launch args, the islands bought
## (IslandStore: PURCHASED only, pending, refunds, acknowledge, the cache), one new spot a day on an
## island not bought (DailyLimit, Story.enterable), Puppy's "today" line with 보호자 on the map, the
## guardian's check (ParentalGate), the island's offer (IslandOffer) and 보호자 on 섬 고르기's island tags (#116).
extends RefCounted

const UI_THEME := "res://scripts/app/ui_theme.gd"
const QualityScript := preload("res://scripts/core/quality.gd")
const SIZES := {"phone": Vector2(1560, 720), "tablet": Vector2(1152, 720), "desktop": Vector2(1280, 720)}
const CACHE := "user://purchases-test.cfg"

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH
	ProgressStore.reset_all()
	check_play_args()
	check_products()
	check_store_states()
	check_daily_limit()
	check_story_today()
	await check_gate()
	await check_offer()
	await check_cards()
	await check_today_box()
	await check_map_flow()
	DailyLimit.today_override = ""
	Island.set_dev_open(false)
	Island.use_index([])
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.reset_all()
	ProgressStore.path = saved_path


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


## Two islands: the mechanics island and a paid one laid out like it (the hutton entry with its product).
static func _paid_index() -> Array:
	return [
		{"id": "mechanics", "file": "mechanics.json"},
		{"id": "hutton", "file": "mechanics.json", "opens_after": "mechanics", "product": "island_hutton"},
	]


## A store with the stand-in backend `mode` (no file but CACHE).
func _store(mode: String) -> IslandStore:
	if FileAccess.file_exists(CACHE):
		DirAccess.remove_absolute(CACHE)
	var store := IslandStore.new()
	store.cache_path = CACHE
	if mode != "":
		store.backend = IslandStore.FakeStore.new(store, mode)
	tree.root.add_child(store)
	return store


func _drop(store: IslandStore) -> void:
	tree.root.remove_child(store)
	store.free()
	if FileAccess.file_exists(CACHE):
		DirAccess.remove_absolute(CACHE)


## The Play build reads only the quality, fps and screen-size args (#77 Q6): a launch intent cannot
## open a lab, a demo, another island, the stand-in store or turn the story off.
func check_play_args() -> void:
	var args := PackedStringArray(["--quality=high", "--q-msaa=2", "--fps=1", "--ui-size=large", "--experiment=sea_breeze",
		"--screen=settings", "--demo-story=map", "--demo-title", "--progress=bench", "--ctl-angle=30", "--camera=top",
		"--sound=0", "--auto-drag=1", "--islands=open", "--island=hutton", "--store=owned", "--ask=show"])
	var kept := Array(QualityScript.play_args(args))
	var problems := []
	if kept != ["--quality=high", "--q-msaa=2", "--fps=1", "--ui-size=large"]:
		problems.append("kept %s" % str(kept))
	if QualityScript.dev_arg(args, "store", true) != "" or QualityScript.dev_arg(args, "store", false) != "owned":
		problems.append("--store= is not a developer switch")
	if Story.measurement_run(QualityScript.play_args(args)):
		problems.append("a Play launch can still turn the story off")
	expect.call(problems.is_empty(), "payment: the Play build reads only --quality / --q-* / --fps / --ui-size (no lab, demo, store or story switch)", "; ".join(problems))


## The hutton island is for sale as island_hutton; the first island is free; every playable island
## after the first has a product (else it would have no day limit).
func check_products() -> void:
	var problems := []
	if IslandStore.product_of("hutton") != "island_hutton":
		problems.append("hutton's product %s" % IslandStore.product_of("hutton"))
	if IslandStore.product_of("mechanics") != "" or not IslandStore.owns("mechanics"):
		problems.append("the first island is not free")
	for id in Island.ids().slice(1):
		if Island.by_id(id).playable() and IslandStore.product_of(id) == "":
			problems.append("%s is playable with no product" % id)
	if IslandStore.owns("hutton"):
		problems.append("hutton owned with no store")
	Island.set_dev_open(true)
	if not IslandStore.owns("hutton"):
		problems.append("--islands=open does not lift the day limit")
	Island.set_dev_open(false)
	expect.call(problems.is_empty(), "payment: hutton is sold as island_hutton, the first island is free, no paid island without a product", "; ".join(problems))


## Only PURCHASED counts; a pending purchase is not bought; a purchase missing from a whole query is
## gone (a refund); an unacknowledged one is acknowledged; the cache keeps what was bought until the
## store answers.
func check_store_states() -> void:
	Island.use_index(_paid_index())
	var problems := []
	var store := _store("")
	var acks := []
	store.backend = Recorder.new(acks)
	store.purchases_updated([{"product_ids": ["island_hutton"], "purchase_state": IslandStore.PENDING, "purchase_token": "p"}], false)
	if IslandStore.owns("hutton") or not IslandStore.waiting("hutton"):
		problems.append("pending: owns %s waiting %s" % [IslandStore.owns("hutton"), IslandStore.waiting("hutton")])
	store.purchases_updated([{"product_ids": ["island_hutton"], "purchase_state": IslandStore.PURCHASED, "purchase_token": "t", "is_acknowledged": false}], false)
	if not IslandStore.owns("hutton") or IslandStore.waiting("hutton"):
		problems.append("purchased: owns %s waiting %s" % [IslandStore.owns("hutton"), IslandStore.waiting("hutton")])
	if acks != ["t"]:
		problems.append("acknowledged %s" % str(acks))
	store.purchases_updated([{"product_ids": ["island_hutton"], "purchase_state": IslandStore.PURCHASED, "purchase_token": "t", "is_acknowledged": true}], true)
	if acks != ["t"]:
		problems.append("acknowledged again %s" % str(acks))
	_drop(store)
	# The cache: a store that cannot answer starts with what was bought.
	var cached := IslandStore.new()
	cached.cache_path = CACHE
	cached.owned = {"island_hutton": true}
	cached._save_cache()
	var again := IslandStore.new()
	again.cache_path = CACHE
	tree.root.add_child(again)
	if not IslandStore.owns("hutton"):
		problems.append("the cache is not read")
	again.purchases_updated([], true)   # the store's whole answer: nothing (a refund)
	if IslandStore.owns("hutton"):
		problems.append("a refund keeps the island")
	cached.free()
	_drop(again)
	# The stand-in modes.
	for pair in [["owned", true, false], ["none", false, false], ["pending", false, false]]:
		var fake := _store(pair[0])
		if IslandStore.owns("hutton") != pair[1] or IslandStore.price("hutton") != "₩990":
			problems.append("--store=%s: owns %s price %s" % [pair[0], IslandStore.owns("hutton"), IslandStore.price("hutton")])
		fake.buy("hutton")
		var want_owned: bool = pair[0] != "pending"
		if IslandStore.owns("hutton") != want_owned or IslandStore.waiting("hutton") != (pair[0] == "pending"):
			problems.append("--store=%s after 구매: owns %s waiting %s" % [pair[0], IslandStore.owns("hutton"), IslandStore.waiting("hutton")])
		_drop(fake)
	var failing := _store("fail")
	var reasons := []
	failing.failed.connect(func(r: String) -> void: reasons.append(r))
	failing.buy("hutton")
	if IslandStore.owns("hutton") or reasons != [IslandStore.FAILED]:
		problems.append("--store=fail: %s" % str(reasons))
	_drop(failing)
	if IslandStore.cache_file_in(true, "/data/user/0/app/cache") != "/data/user/0/app/cache/purchases.cfg" \
			or IslandStore.cache_file_in(false, "/home/me/.cache") != "user://purchases.cfg" \
			or IslandStore.cache_file_in(true, "") != "user://purchases.cfg" or IslandStore.cache_file() != "user://purchases.cfg":
		problems.append("cache file: android %s, desktop %s" % [IslandStore.cache_file_in(true, "/data/user/0/app/cache"), IslandStore.cache_file()])
	Island.use_index([])
	expect.call(problems.is_empty(), "payment: only PURCHASED opens, pending waits, a refund closes, acknowledged once, the cache until the store answers (Android: the cache folder, out of backups), the stand-in modes", "; ".join(problems))


class Recorder:
	extends RefCounted
	var acks: Array

	func _init(list: Array) -> void:
		acks = list

	func acknowledge(token: String) -> void:
		acks.append(token)


## One new spot a day (#77 Q1): the first entry into an unfound spot uses the day; that spot opens
## again (the next day too); another waits for another date (forwards or back); a bought island has
## no limit.
func check_daily_limit() -> void:
	Island.use_index(_paid_index())
	ProgressStore.reset_all()
	var problems := []
	DailyLimit.today_override = "2026-11-08"
	if not DailyLimit.allows("hutton", "a"):
		problems.append("the first spot is closed")
	DailyLimit.use("hutton", "a")
	if not DailyLimit.allows("hutton", "a") or DailyLimit.allows("hutton", "b"):
		problems.append("same day: a %s b %s" % [DailyLimit.allows("hutton", "a"), DailyLimit.allows("hutton", "b")])
	if not DailyLimit.allows("mechanics", "b"):
		problems.append("the free island is limited")
	DailyLimit.today_override = "2026-11-09"
	if not DailyLimit.allows("hutton", "a") or not DailyLimit.allows("hutton", "b"):
		problems.append("next day: a %s b %s" % [DailyLimit.allows("hutton", "a"), DailyLimit.allows("hutton", "b")])
	DailyLimit.use("hutton", "a")   # a again on the next day: the day is not used again
	if not DailyLimit.allows("hutton", "b"):
		problems.append("going back to yesterday's spot used today")
	DailyLimit.use("hutton", "b")
	if DailyLimit.allows("hutton", "c"):
		problems.append("c opens the day b was entered")
	DailyLimit.today_override = "2026-11-01"   # the clock set back: another date
	if not DailyLimit.allows("hutton", "c"):
		problems.append("an earlier date does not open the next spot")
	DailyLimit.today_override = "2026-11-09"
	var store := _store("owned")
	if not DailyLimit.allows("hutton", "c"):
		problems.append("a bought island is limited")
	_drop(store)
	ProgressStore.reset_all()
	Island.use_index([])
	expect.call(problems.is_empty(), "payment: one new spot a day on an island not bought (its spot again any day, the next on another date, none on a bought or free island)", "; ".join(problems))


## The map's order with the day: the next spot opens only when today's new spot is it or unused.
func check_story_today() -> void:
	Island.use_index(_paid_index())
	ProgressStore.reset_all()   # (forgets the island in use: before use_for_run)
	Island.use_for_run("hutton")
	Story.forget_loaded()
	DailyLimit.today_override = "2026-11-08"
	var problems := []
	var order := Story.order()
	var first: String = order[0]
	var second: String = order[1]
	if not Story.enterable({}, first):
		problems.append("the first spot is closed")
	DailyLimit.use("hutton", first)
	var done := {first: MissionRound.missions(ExperimentRegistry.find(first)).get("stages", []).size()}
	if Story.next_spot(done) != second or Story.enterable(done, second) or not Story.enterable(done, first):
		problems.append("after the first spot today: next %s open %s" % [Story.next_spot(done), Story.enterable(done, second)])
	DailyLimit.today_override = "2026-11-09"
	if not Story.enterable(done, second):
		problems.append("the next day the second spot is closed")
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.reset_all()
	Island.use_index([])
	expect.call(problems.is_empty(), "payment: the map's next spot waits for tomorrow once today's new spot is used", "; ".join(problems))


## 보호자 확인: a × b + c in its ranges, new each time; the answer typed in a number field (digits
## only, three at most) and 확인 or the keyboard's done key; a wrong answer a new sum; the third wrong
## one closes; the right one passes. On phone, tablet and desktop the card is inside the view.
func check_gate() -> void:
	var problems := []
	var gate := ParentalGate.new()
	var sums := {}
	for i in 60:
		gate.new_sum()
		if gate.a < 12 or gate.a > 19 or gate.b < 3 or gate.b > 9 or gate.c < 10 or gate.c > 49:
			problems.append("out of range %d %d %d" % [gate.a, gate.b, gate.c])
		sums[gate.sum_label.text] = true
	if sums.size() < 20:
		problems.append("only %d different sums" % sums.size())
	if gate.field.virtual_keyboard_type != LineEdit.KEYBOARD_TYPE_NUMBER or gate.field.max_length != 3:
		problems.append("field keyboard %d max %d" % [gate.field.virtual_keyboard_type, gate.field.max_length])
	gate.field.text = "1a2"
	gate.field.text_changed.emit("1a2")
	if gate.field.text != "12":
		problems.append("digits only: %s" % gate.field.text)
	var passed := [false]
	var closed := [false]
	gate.passed.connect(func() -> void: passed[0] = true)
	gate.closed.connect(func() -> void: closed[0] = true)
	gate.field.text = ""
	gate.submit()
	if gate.wrong != 0:
		problems.append("an empty answer counts as wrong")
	for i in 2:
		gate.field.text = str(gate.answer() + 1)
		gate.submit()
		if closed[0] or gate.field.text != "" or gate.wrong != i + 1:
			problems.append("wrong %d: closed %s typed %s" % [i + 1, closed[0], gate.field.text])
		if gate.note_label.text != Locale.t("guardian.gate_wrong"):
			problems.append("no wrong note")
	gate.field.text = str(gate.answer())
	gate.field.text_submitted.emit(gate.field.text)   # the keyboard's done key
	if not passed[0] or closed[0]:
		problems.append("the right answer: passed %s closed %s" % [passed[0], closed[0]])
	gate.free()
	var third := ParentalGate.new()
	var shut := [false]
	third.closed.connect(func() -> void: shut[0] = true)
	for i in 3:
		third.field.text = str(third.answer() + 1)
		third.ok_button.pressed.emit()
	if not shut[0]:
		problems.append("three wrong answers do not close")
	third.free()
	for size_name in SIZES:
		var host := Control.new()
		host.theme = load(UI_THEME).build()
		host.size = SIZES[size_name]
		tree.root.add_child(host)
		var shown := ParentalGate.new()
		host.add_child(shown)
		await _frames(3)
		for r: Rect2 in shown.rects() + [shown.field.get_global_rect(), shown.ok_button.get_global_rect(), shown.note_label.get_global_rect()]:
			if not Rect2(Vector2.ZERO, host.size).encloses(r):
				problems.append("%s: %s outside %s" % [size_name, r, host.size])
		if shown.field.has_focus():
			problems.append("%s: the answer field takes the focus at once (the keyboard would hide the sum)" % size_name)
		if shown.close_button.get_global_rect().intersects(shown.ok_button.get_global_rect()):
			problems.append("%s: × over 확인" % size_name)
		host.queue_free()
		await _frames(1)
	expect.call(problems.is_empty(), "payment: the guardian's check (a × b + c in range, number keyboard field without focus at first (the sum shows), a new sum when wrong, closed after three)", "; ".join(problems))


## The offer: price and 구매 from the store, waiting in place of the price and 구매, a bought island
## closes it, no store: 구매 cannot be pressed, a failed purchase says so and a cancelled one shows the
## store line. On phone, tablet and desktop the card and × are inside the view.
func check_offer() -> void:
	Island.use_index(_paid_index())
	var problems := []
	for mode in ["none", "pending", "fail", ""]:
		var store := _store(mode)
		for size_name in SIZES:
			var host := Control.new()
			host.theme = load(UI_THEME).build()
			host.size = SIZES[size_name]
			tree.root.add_child(host)
			var offer := IslandOffer.new("hutton")
			host.add_child(offer)
			await _frames(3)
			for r: Rect2 in offer.rects():
				if not Rect2(Vector2.ZERO, host.size).encloses(r):
					problems.append("%s %s: %s outside %s" % [mode, size_name, r, host.size])
			if mode == "none" and (offer.price_label.text != "₩990" or offer.buy_button.disabled or offer.waiting_box.visible):
				problems.append("none: price %s disabled %s" % [offer.price_label.text, offer.buy_button.disabled])
			if mode == "" and (not offer.buy_button.disabled or offer.message.text != Locale.t("guardian.unavailable")):
				problems.append("no store: 구매 %s message %s" % [offer.buy_button.disabled, offer.message.text])
			if size_name == "desktop" and mode == "pending":
				offer.buy_button.pressed.emit()
				await _frames(1)
				if not offer.waiting_box.visible or offer.buy_button.visible:
					problems.append("pending: no waiting line")
			if size_name == "desktop" and mode == "fail":
				offer.buy_button.pressed.emit()
				await _frames(1)
				var failed_text := offer.message.text
				store.purchase_failed(IslandStore.CANCELLED)
				if failed_text != Locale.t("guardian.failed") or offer.message.text != Locale.t("guardian.store_note"):
					problems.append("fail: message %s, then cancelled %s" % [failed_text, offer.message.text])
			if size_name == "desktop" and mode == "none":
				offer.buy_button.pressed.emit()
				await _frames(1)
				if is_instance_valid(offer) and not offer.is_queued_for_deletion():
					problems.append("bought: the offer stays")
			host.queue_free()
			await _frames(1)
		_drop(store)
	Island.use_index([])
	expect.call(problems.is_empty(), "payment: the island's offer (store price, 구매, waiting for approval, closes when bought, no store: 구매 off) inside the view on phone, tablet and desktop", "; ".join(problems))


## 섬 고르기: an open island not bought has 보호자 in its tag's top right (the islands' map, #116); it opens
## the guardian's check; a bought (or free) island has none, and buying takes it away.
func check_cards() -> void:
	Island.use_index(_paid_index())
	var full := {}
	for spot in Island.by_id("mechanics").spots():
		full[spot] = MissionRound.missions(ExperimentRegistry.find(spot)).get("stages", []).size()
	ProgressStore.save(full)
	var problems := []
	var store := _store("none")
	for size_name in SIZES:
		var host := Control.new()
		host.theme = load(UI_THEME).build()
		host.size = SIZES[size_name]
		tree.root.add_child(host)
		var cards := IslandCards.new()
		host.add_child(cards)
		await _frames(4)
		cards.focus = cards._index("hutton")   # (the carousel: hutton's tag in view)
		await _frames(60)
		var guardian: Button = cards.guardians.get("hutton")
		if guardian == null or cards.guardians.has("mechanics"):
			problems.append("%s: guardians %s" % [size_name, cards.guardians.keys()])
		else:
			var tag := (cards.cards["hutton"] as Control).get_global_rect()   # (its tag on the islands' map, #116)
			var r := guardian.get_global_rect()
			if not tag.encloses(r) or r.get_center().x < tag.get_center().x or r.get_center().y > tag.get_center().y:
				problems.append("%s: 보호자 %s not in the tag's top right %s" % [size_name, r, tag])
			if size_name == "desktop":   # the last size: buying takes 보호자 away
				guardian.pressed.emit()
				await _frames(1)
				if cards.find_children("ParentalGate", "", true, false).is_empty():
					problems.append("보호자 opens no check")
				store.buy("hutton")
				await _frames(1)
				if guardian.visible:
					problems.append("bought: 보호자 stays")
		host.queue_free()
		await _frames(1)
	_drop(store)
	ProgressStore.reset_all()
	Island.use_index([])
	expect.call(problems.is_empty(), "payment: 보호자 on an open island card not bought (its tag's top right), opens the check, gone when bought", "; ".join(problems))


## Puppy's box with 보호자 at its right end: inside the box, clear of the words, on every size; the box's
## next open has none.
func check_today_box() -> void:
	var problems := []
	for size_name in SIZES:
		var host := Control.new()
		host.theme = load(UI_THEME).build()
		host.size = SIZES[size_name]
		tree.root.add_child(host)
		var box := DialogueBox.new("")
		host.add_child(box)
		box.set_speaker("puppy", "explain")
		box.open("오늘 새 장소는 여기까지야. 내일 또 같이 찾자!")
		var button := GuardianModal.guardian_button()
		box.set_side_button(button)
		box.layout(Rect2(Vector2.ZERO, host.size), host.size.x - 16.0, 16.0)
		await _frames(2)
		var b := button.get_global_rect()
		var inner := box.box.get_global_rect()
		var widest := 0.0
		for line in box.page_text(box.page).split("\n"):
			widest = maxf(widest, box.line_width(line))
		var words := Rect2(box.label.global_position, Vector2(widest, box.label.size.y))
		if not inner.encloses(b):
			problems.append("%s: 보호자 %s outside the box %s" % [size_name, b, inner])
		if words.intersects(b):
			problems.append("%s: 보호자 over the words" % size_name)
		box.open("다음")
		if is_instance_valid(button) and not button.is_queued_for_deletion():
			problems.append("%s: 보호자 stays on the next line" % size_name)
		host.queue_free()
		await _frames(1)
	expect.call(problems.is_empty(), "payment: Puppy's today box has 보호자 at its right end, inside the box and clear of the words, only for that line", "; ".join(problems))


## The whole way on the map (#77 Q7): today's new spot used, the next spot tapped: Puppy says today is
## done with 보호자 at his box's end; 보호자 opens the check, the right answer the island's offer;
## Android back closes the offer and then nothing is left over the map.
func check_map_flow() -> void:
	var was_enabled := Story.enabled
	Island.use_index(_paid_index())
	ProgressStore.reset_all()
	Island.use_for_run("hutton")
	Story.forget_loaded()
	Story.enabled = true
	Story.mark_seen("prologue")
	DailyLimit.today_override = "2026-11-08"
	var problems := []
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = SIZES.phone
	tree.root.add_child(host)
	var screen: Control = load("res://scripts/app/island_home_screen.gd").new()
	host.add_child(screen)
	await _frames(4)
	var story: StoryDirector = screen.story
	var next: String = story.next_id
	DailyLimit.use("hutton", Story.order()[1])   # today's new spot went elsewhere
	var index := -1
	for i in screen._spots.size():
		if screen._spots[i].id == next:
			index = i
	if next == "" or index < 0 or not story.waits_for_tomorrow(next):
		problems.append("next %s (index %d) does not wait for tomorrow" % [next, index])
	else:
		screen._walk_to_spot(index)
		await _frames(2)
		var guardian: Button = story.riddle.side_button
		if guardian == null or story.riddle.text != Story.today_line():
			problems.append("Puppy's today box: words %s, 보호자 %s" % [story.riddle.text if story.riddle != null else "none", guardian])
		else:
			guardian.pressed.emit()
			await _frames(1)
			var gates := screen.find_children("ParentalGate", "", true, false)
			if gates.size() != 1:
				problems.append("보호자 opens %d checks" % gates.size())
			else:
				var gate: ParentalGate = gates[0]
				gate.field.text = str(gate.answer())
				gate.submit()
				await _frames(2)
				if screen.find_children("IslandOffer", "", true, false).size() != 1:
					problems.append("the right answer opens no offer")
				if not GuardianModal.close_top(screen):
					problems.append("back closes nothing")
				await _frames(1)
				if not screen.get_tree().get_nodes_in_group(GuardianModal.GROUP).filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).is_empty():
					problems.append("a guardian screen stays after back")
	host.queue_free()
	await _frames(2)
	Story.enabled = was_enabled
	DailyLimit.today_override = ""
	Island.forget_current()
	Story.forget_loaded()
	ProgressStore.reset_all()
	Island.use_index([])
	expect.call(problems.is_empty(), "payment: on the map, the next spot tapped after today's: Puppy's box with 보호자, the check, the offer, back closes it", "; ".join(problems))

