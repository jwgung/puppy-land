## Puppy and his line beside Dugi's box in every Hutton Island lab (#114, 2026-11-10 user: "계절
## 실험해서, 퍼피 말풍선이 대화창을 가림"): on the real screen of the tablet and the phone, with Dugi's box
## open (his explanation) and Puppy's result bubble shown, the bubble is clear of the box and Dugi's
## portrait, and Puppy himself is at most HIDDEN_MAX under them (in 계절 he stood in the bottom left
## corner where the portrait goes: his bubble had no side left but over the box).
extends RefCounted

const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const UI_THEME := "res://scripts/app/ui_theme.gd"
const SIZES := {"tablet": Vector2(1152, 720), "phone": Vector2(1560, 720)}
## The share of Puppy's drawn rect that may be under Dugi's box and portrait (his feet behind the box).
const HIDDEN_MAX := 0.5

var tree: SceneTree
var expect: Callable


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	var saved_path := ProgressStore.path
	ProgressStore.path = ProgressStore.TEST_PATH
	var problems := []
	var seen := 0
	for name: String in SIZES:
		for definition: Dictionary in ExperimentRegistry.island_labs("hutton"):
			var out: Variant = await _check(definition, SIZES[name])
			if out == null:
				continue
			seen += 1
			for p: String in out:
				problems.append("%s %s: %s" % [name, definition.id, p])
	DirAccess.remove_absolute(ProgressStore.path)
	ProgressStore.path = saved_path
	expect.call(problems.is_empty() and seen == ExperimentRegistry.island_labs("hutton").size() * SIZES.size(),
		"hutton cast: in every lab (tablet, phone), with Dugi's box open, Puppy's result bubble is clear of the box and his portrait, and Puppy is at most %d%% under them (%d screens)" % [int(HIDDEN_MAX * 100.0), seen],
		"; ".join(problems))


## The problems of lab `definition` on a screen of `size` (null: no Puppy and Dugi there).
func _check(definition: Dictionary, size: Vector2) -> Variant:
	var store := {}
	store[definition.id] = 1   # (a visited lab: no opening lines)
	ProgressStore.save(store)
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = size
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(definition)
	host.add_child(screen)
	for i in 30:
		await tree.process_frame
	var cast: IslandCast = screen.cast
	if cast == null or cast.puppy == null or cast.dugi == null:
		host.queue_free()
		await tree.process_frame
		return null
	cast.dugi.explain(screen.experiment.explain_point)
	for i in 120:
		if screen.dialogue.active and screen.dialogue.visible:
			break
		await tree.process_frame
	screen.show_result(0, true)
	for i in 40:
		await tree.process_frame
	var problems := []
	if not (screen.dialogue.active and screen.dialogue.visible):
		problems.append("Dugi's box did not open")
	var puppy: Rect2 = screen.view_rect_of(IslandCast.drawn_bounds(cast.puppy))
	var bubble: ResultBubble = screen.result_bubble()
	if bubble == null:
		problems.append("no bubble")
	var hidden := 0.0
	for r: Rect2 in screen.dialogue.rects():
		if r.intersects(puppy):
			hidden += r.intersection(puppy).get_area()
		if bubble != null and r.intersects(bubble.get_rect()):
			problems.append("the bubble %s over Dugi's %s" % [str(bubble.get_rect()), str(r)])
	if hidden > puppy.get_area() * HIDDEN_MAX:
		problems.append("Puppy %s %d%% under Dugi's box" % [str(puppy), int(100.0 * hidden / maxf(puppy.get_area(), 1.0))])
	host.queue_free()
	await tree.process_frame
	return problems
