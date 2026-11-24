## Reading a DialogueBox untouched (2026-11-16: each page types out, stays its read time, then the next
## page comes or the box closes; a tap is only the quicker way). The checks step the box's clock with
## these where they do not test the taps. Load it with preload (no class_name: the runner's autoloads).
## (`box` is untyped: run_tests.gd preloads this before the autoloads its classes use exist.)
extends RefCounted

const DT := 1.0 / 60.0
## Seconds a page may take at most before the helpers give up (a held page never turns).
const LIMIT_S := 120.0


## Steps `box` until its page is fully shown (or it closes). Returns the seconds it took.
static func type_page(box) -> float:
	var t := 0.0
	while box.active and not box.typed() and t < LIMIT_S:
		box.step(DT)
		t += DT
	return t


## Steps `box` until its page turns or it closes (a held last page: until LIMIT_S). Returns the seconds
## it took.
static func read_page(box) -> float:
	var at: int = box.page
	var words: String = box.text
	var t := 0.0
	while box.active and box.page == at and box.text == words and t < LIMIT_S:
		box.step(DT)
		t += DT
	return t


## Reads every page of `box` until it closes or holds on its last page (at most `pages` pages).
static func read_all(box, pages := 40) -> void:
	for i in pages:
		if not box.active or (box.hold and box.page == box.pages().size() - 1):
			return
		read_page(box)
