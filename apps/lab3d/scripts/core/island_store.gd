## The islands bought (#77, ADR 0005): an island with a `product` (content/islands/index.json,
## "island_<id>") is a one-time in-app product of the store; an island without one is free (the first).
## Bought or not, an island opens as Island.is_open says; one not bought opens one new spot a day
## (DailyLimit).
##
## The store is Google Play's billing (the GodotGooglePlayBilling plugin, only in the "Android Play"
## preset's Gradle build: PlayBilling). Outside it there is no store (nothing is bought, no price,
## 구매 does nothing) unless a developer runs the stand-in --store=owned|none|pending|fail (FakeStore,
## Quality.DEV_KEYS: never in the Play build):
##   owned    every product is bought
##   none     nothing is bought; 구매 buys at once
##   pending  nothing is bought; 구매 leaves the purchase waiting for approval
##   fail     nothing is bought; 구매 fails
##
## What the store says is the truth (the purchases are asked for when the app starts and whenever it
## comes back to the front; no restore button): a product counts as bought only in the PURCHASED
## state, and a purchase not yet acknowledged is acknowledged at once (Play refunds it after three
## days otherwise). A pending one (cash, a family member's approval) stays locked until it is
## purchased. The bought products are also kept in cache_file() (left out of Android backups), only
## for a start when the store cannot answer (no connection): its next answer replaces them. Everything is checked on the device (no server): a forged purchase is an
## accepted risk (ADR 0005).
class_name IslandStore
extends Node

## A purchase, a price or a pending purchase changed (the cards and the offer sheet redraw).
signal changed
## 구매 ended without a purchase (cancelled, failed): the offer sheet says so.
signal failed(reason: String)

const QualityScript := preload("res://scripts/core/quality.gd")
## The cache file: on Android in the app's cache folder, which Android Auto Backup leaves out, so a
## backed-up or restored copy can never open an island (Play is asked again on a new device).
const CACHE_NAME := "purchases.cfg"
const FAKE_MODES := ["owned", "none", "pending", "fail"]
## The plugin's purchase states (BillingClient.PurchaseState).
const PURCHASED := 1
const PENDING := 2
## The plugin's response codes used here (BillingClient.BillingResponseCode).
const RESPONSE_OK := 0
const USER_CANCELED := 1
const ITEM_ALREADY_OWNED := 7
## Why 구매 ended without a purchase (failed).
const UNAVAILABLE := "unavailable"
const CANCELLED := "cancelled"
const FAILED := "failed"

## The store in use (App makes it; tests make their own). Null: no store, only free islands are bought.
static var instance: IslandStore

## product id -> true: bought (PURCHASED).
var owned: Dictionary = {}
## product id -> true: waiting for approval (PENDING).
var pending: Dictionary = {}
## product id -> the store's price text (its currency and format; Play's formatted_price).
var prices: Dictionary = {}
## The backend (PlayBilling, FakeStore, or null: no store).
var backend: RefCounted
## The cache file in use (tests: their own).
var cache_path := cache_file()


## Where the cache lives: Android's cache folder (left out of backups), user:// elsewhere.
static func cache_file() -> String:
	var folder := OS.get_cache_dir() if OS.has_feature("android") else ""
	return folder.path_join(CACHE_NAME) if folder != "" else "user://" + CACHE_NAME


## The store of this run: Play's in the Play build when the plugin is there, the stand-in of --store=
## outside it, else none.
static func make() -> IslandStore:
	var store := IslandStore.new()
	store.name = "IslandStore"
	var fake := QualityScript.dev_value("store")
	if fake in FAKE_MODES:
		store.backend = FakeStore.new(store, fake)
	elif Engine.has_singleton(PlayBilling.PLUGIN):
		store.backend = PlayBilling.new(store)
	return store


## The product of `island_id` ("" for a free island).
static func product_of(island_id: String) -> String:
	return str(Island.entry(island_id).get("product", ""))


## Every product of the list.
static func products() -> PackedStringArray:
	var out := PackedStringArray()
	for id in Island.ids():
		if product_of(id) != "":
			out.append(product_of(id))
	return out


## `island_id` is the child's without a day limit: free, bought, or every island open (--islands=open).
static func owns(island_id: String) -> bool:
	var product := product_of(island_id)
	if product == "" or Island.dev_open():
		return true
	return instance != null and instance.owned.has(product)


## The purchase of `island_id` waits for approval.
static func waiting(island_id: String) -> bool:
	return instance != null and instance.pending.has(product_of(island_id))


## The store's price of `island_id` ("" when the store has not said: 구매 cannot be pressed).
static func price(island_id: String) -> String:
	return str(instance.prices.get(product_of(island_id), "")) if instance != null else ""


func _ready() -> void:
	instance = self
	_load_cache()
	if backend != null:
		backend.call("start", products())


func _exit_tree() -> void:
	if instance == self:
		instance = null


## Back to the front (App): the store is asked again (a purchase approved elsewhere, a refund).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and backend != null:
		backend.call("refresh")


## 구매 (after the guardian's check): the store's own purchase screen; the answer comes back through
## purchases_updated or failed.
func buy(island_id: String) -> void:
	var product := product_of(island_id)
	if product == "" or owned.has(product):
		return
	if backend == null:
		failed.emit(UNAVAILABLE)
		return
	backend.call("buy", product)


# --- what the backends report ----------------------------------------------------------------------

## The store's purchases: [{product_ids, purchase_state, purchase_token, is_acknowledged}, ...]
## (the plugin's dictionaries). `complete`: the whole list (a query): what is not in it is not bought
## (a refund); else only updates (a purchase just made).
func purchases_updated(purchases: Array, complete: bool) -> void:
	var now_owned := {} if complete else owned.duplicate()
	var now_pending := {} if complete else pending.duplicate()
	for p: Variant in purchases:
		if not p is Dictionary:
			continue
		var state := int(p.get("purchase_state", 0))
		for product: Variant in p.get("product_ids", []):
			if state == PURCHASED:
				now_owned[str(product)] = true
				now_pending.erase(str(product))
			elif state == PENDING and not now_owned.has(str(product)):
				now_pending[str(product)] = true
		if state == PURCHASED and not bool(p.get("is_acknowledged", false)) and backend != null:
			backend.call("acknowledge", str(p.get("purchase_token", "")))
	var moved := now_owned != owned or now_pending != pending
	owned = now_owned
	pending = now_pending
	if moved:
		_save_cache()
		changed.emit()


func prices_updated(new_prices: Dictionary) -> void:
	for product in new_prices:
		prices[product] = new_prices[product]
	changed.emit()


## 구매 ended without a purchase: `reason` CANCELLED or FAILED.
func purchase_failed(reason: String) -> void:
	failed.emit(reason)


func _load_cache() -> void:
	var config := ConfigFile.new()
	if config.load(cache_path) != OK:
		return
	for product in config.get_section_keys("owned") if config.has_section("owned") else PackedStringArray():
		if config.get_value("owned", product) == true:
			owned[product] = true


func _save_cache() -> void:
	var config := ConfigFile.new()
	for product in owned:
		config.set_value("owned", product, true)
	config.save(cache_path)


## Google Play's billing through the GodotGooglePlayBilling plugin (3.3.0, Play Billing Library 9.1.0;
## its BillingClient node script lives in res://addons/GodotGooglePlayBilling).
class PlayBilling:
	extends RefCounted
	const PLUGIN := "GodotGooglePlayBilling"
	var store: IslandStore
	var client: Node
	var _products := PackedStringArray()

	func _init(owner_store: IslandStore) -> void:
		store = owner_store

	func start(products: PackedStringArray) -> void:
		_products = products
		client = (load("res://addons/GodotGooglePlayBilling/BillingClient.gd") as GDScript).new()
		client.name = "BillingClient"
		store.add_child(client)
		client.connect("connected", _on_connected)
		client.connect("query_purchases_response", func(r: Dictionary) -> void:
			if int(r.get("response_code", -1)) == IslandStore.RESPONSE_OK:
				store.purchases_updated(r.get("purchases", []), true))
		client.connect("query_product_details_response", _on_details)
		client.connect("on_purchase_updated", _on_purchase_updated)
		client.call("start_connection")

	func _on_connected() -> void:
		refresh()
		if not _products.is_empty():
			client.call("query_product_details", _products, 0)   # ProductType.INAPP

	func refresh() -> void:
		if client == null:
			return
		if not client.call("is_ready"):
			client.call("start_connection")   # `connected` asks again
			return
		client.call("query_purchases", 0)

	func buy(product: String) -> void:
		if client == null or not client.call("is_ready"):
			store.purchase_failed(IslandStore.FAILED)
			return
		var r: Dictionary = client.call("purchase", product)
		if int(r.get("response_code", -1)) != IslandStore.RESPONSE_OK:
			store.purchase_failed(IslandStore.FAILED)

	func acknowledge(token: String) -> void:
		if client != null and token != "":
			client.call("acknowledge_purchase", token)

	func _on_details(r: Dictionary) -> void:
		if int(r.get("response_code", -1)) != IslandStore.RESPONSE_OK:
			return
		var found := {}
		for details: Variant in r.get("product_details", []):
			var offers: Variant = details.get("one_time_purchase_offer_details_list") if details is Dictionary else null
			if offers is Array and not (offers as Array).is_empty() and offers[0] is Dictionary:
				found[str(details.get("product_id", ""))] = str(offers[0].get("formatted_price", ""))
		store.prices_updated(found)

	func _on_purchase_updated(r: Dictionary) -> void:
		match int(r.get("response_code", -1)):
			IslandStore.RESPONSE_OK:
				store.purchases_updated(r.get("purchases", []), false)
			IslandStore.USER_CANCELED:
				store.purchase_failed(IslandStore.CANCELLED)
			IslandStore.ITEM_ALREADY_OWNED:
				refresh()
			_:
				store.purchase_failed(IslandStore.FAILED)


## The stand-in store of --store=<mode> (FAKE_MODES): answers at once, no money, nothing saved but
## the cache. Its price is the Korean one of ADR 0005.
class FakeStore:
	extends RefCounted
	const PRICE := "₩990"
	var store: IslandStore
	var mode := "none"
	var _made: Array = []

	func _init(owner_store: IslandStore, fake_mode: String) -> void:
		store = owner_store
		mode = fake_mode

	func start(products: PackedStringArray) -> void:
		var found := {}
		for product in products:
			found[product] = PRICE
		store.prices_updated(found)
		refresh()

	func refresh() -> void:
		var bought := []
		if mode == "owned":
			bought.append({"product_ids": IslandStore.products(), "purchase_state": IslandStore.PURCHASED, "is_acknowledged": true})
		bought.append_array(_made)
		store.purchases_updated(bought, true)

	func buy(product: String) -> void:
		match mode:
			"fail":
				store.purchase_failed(IslandStore.FAILED)
			"pending":
				_made.append({"product_ids": [product], "purchase_state": IslandStore.PENDING, "is_acknowledged": false})
				store.purchases_updated(_made, false)
			_:
				_made.append({"product_ids": [product], "purchase_state": IslandStore.PURCHASED, "is_acknowledged": true})
				store.purchases_updated(_made, false)

	func acknowledge(_token: String) -> void:
		pass
