## The lab stands as its mission says when it opens (2026-11-03 playtest: "가벼운 상자를 밀어서" on the
## 8 kg start box, "막대를 가까이 눌러" on the middle point, the drum and the orbit likewise).
## - data: every stage of every lab has settings that fit its conditions (ConditionPicks.stage_values).
## - every lab with missions, opened fresh: each stage-1 condition holds on the lab, the lit picture
##   buttons fit it, the controls the stage does not name keep their defaults, and the hand guide still
##   waits for the child (the screen set the conditions, the child touched nothing).
## - a lab opened at a later stage (saved stamps) stands as that stage says; a screen rebuilt from its
##   saved state keeps the child's own conditions.
## - the free fall: at every stage both balls wait level and the hand guide taps a ball (2026-11-12
##   user: only the world changes, not the height).
extends RefCounted

var tree: SceneTree
var expect: Callable
const UI_THEME := "res://scripts/app/ui_theme.gd"
const EXPERIMENT_SCREEN := "res://scripts/shell/experiment_screen.gd"
const TABLET := Vector2(1152, 720)


func _init(scene_tree: SceneTree, expect_fn: Callable) -> void:
	tree = scene_tree
	expect = expect_fn


func run() -> void:
	check_stage_values()
	for definition in ExperimentRegistry.load_all():
		if not MissionRound.missions(definition).is_empty():
			await check_first_entry(definition)
	await check_saved_stage("friction", 1, {"mass": "normal"})
	await check_saved_stage("rotation", 2, {"effort": "far"})
	await check_rebuilt()
	await check_free_fall_level()
	DirAccess.remove_absolute(ProgressStore.path)


## The definition's start (its defaults: the web's start case the labs' parity, reset and layout checks
## follow) on a screen that opened on its stage's conditions: set back through the screen's own path,
## before any step. Other checks call it right after the screen is in the tree. An auto_conditions lab
## (the collision) keeps its stage's conditions: it sets them again on every 처음으로.
static func start_case(screen: Control) -> void:
	if ConditionPicks.auto(screen.definition.raw):
		return
	for control in screen.definition.controls():
		if str(screen.experiment.control_value(control.id)) != str(control.default):
			screen._set_control(control.id, control.default)


func _open(definition: Dictionary, state := {}) -> Control:
	var host := Control.new()
	host.theme = load(UI_THEME).build()
	host.size = TABLET
	tree.root.add_child(host)
	var screen: Control = load(EXPERIMENT_SCREEN).new()
	screen.setup(definition, state)
	host.add_child(screen)
	await tree.process_frame
	await tree.physics_frame
	for i in 3:
		await tree.process_frame
	return screen


func _close(screen: Control) -> void:
	screen.get_parent().queue_free()
	await tree.process_frame


## The stage's conditions the lab does not meet now ("id = value (want ...)").
func _unmet(screen: Control, stage: int) -> Array:
	var stages: Array = MissionRound.missions(screen.definition.raw).get("stages", [])
	var conditions: Dictionary = stages[stage].get("conditions", {})
	var out := []
	for id in conditions:
		var have: Variant = screen.experiment.control_value(id)
		if not MissionRound.condition_holds(conditions[id], have):
			out.append("%s = %s (want %s)" % [id, str(have), str(conditions[id])])
	return out


func check_stage_values() -> void:
	var problems := []
	for definition in ExperimentRegistry.load_all():
		var stages: Array = MissionRound.missions(definition).get("stages", [])
		for i in stages.size():
			var conditions: Dictionary = stages[i].get("conditions", {})
			var values := ConditionPicks.stage_values(definition, i)
			if values.keys().size() != conditions.keys().size():
				problems.append("%s %d: %s for %s" % [definition.id, i + 1, str(values), str(conditions)])
			for id in values:
				if not MissionRound.condition_holds(conditions[id], values[id]):
					problems.append("%s %d: %s = %s does not fit %s" % [definition.id, i + 1, id, str(values[id]), str(conditions[id])])
	expect.call(problems.is_empty(), "first entry: every stage of every lab has settings that fit its conditions", "; ".join(problems))


func check_first_entry(definition: Dictionary) -> void:
	DirAccess.remove_absolute(ProgressStore.path)   # stage 1, the question asked
	var screen := await _open(definition)
	var problems := _unmet(screen, 0)
	var named: Dictionary = MissionRound.missions(definition).stages[0].get("conditions", {})
	for control in definition.controls:
		if not named.has(control.id) and str(screen.experiment.control_value(control.id)) != str(control.default):
			problems.append("%s changed to %s (not a stage condition)" % [control.id, str(screen.experiment.control_value(control.id))])
	if screen._guide_touched:
		problems.append("the hand guide counts the screen's setting as the child's touch")
	screen.mission_round.end_question()
	screen._show_stamps(0)
	await tree.process_frame
	var lit_by_control := {}
	for pick in screen.pick_buttons():
		if (pick.button as Button).button_pressed:
			lit_by_control[pick.control] = true
			if not MissionRound.condition_holds(named[pick.control], pick.preset.value):
				problems.append("the lit %s button %s does not fit" % [pick.control, str(pick.preset.value)])
	for pick in screen.pick_buttons():
		if not lit_by_control.has(pick.control):
			problems.append("no %s button lit" % pick.control)
			lit_by_control[pick.control] = true
	expect.call(problems.is_empty(), "first entry (%s): the lab opens as stage 1 says (%s), its buttons lit, the rest as before, the hand guide still waits" % [definition.id, str(named)],
		"; ".join(problems))
	await _close(screen)


func check_saved_stage(id: String, stamps: int, want: Dictionary) -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	ProgressStore.save({id: stamps})
	var screen := await _open(ExperimentRegistry.find(id))
	var have := {}
	for control_id in want:
		have[control_id] = screen.experiment.control_value(control_id)
	expect.call(screen.mission_round.stage() == stamps and _unmet(screen, stamps).is_empty() and str(have) == str(want),
		"first entry (%s): opened at stage %d (saved stamps) it stands as that stage says" % [id, stamps + 1], str(have))
	await _close(screen)
	DirAccess.remove_absolute(ProgressStore.path)


func check_rebuilt() -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var definition := ExperimentRegistry.find("friction")
	var first := await _open(definition)
	first._set_control("mass", "heavy")
	var state: Dictionary = first.capture_state()
	await _close(first)
	var again := await _open(definition, state)
	var mass: Variant = again.experiment.control_value("mass")
	expect.call(str(mass) == "heavy", "first entry: a screen rebuilt from its saved state keeps the child's own conditions", str(mass))
	await _close(again)
	DirAccess.remove_absolute(ProgressStore.path)


func check_free_fall_level() -> void:
	DirAccess.remove_absolute(ProgressStore.path)
	var problems := []
	var screen := await _open(ExperimentRegistry.find("free-fall"))
	var lab: Experiment = screen.experiment
	screen.mission_round.end_question()
	for stage in 3:
		lab.set_game_stage(stage, stage, false)
		await tree.physics_frame
		var red := float(lab.starts.red.y)
		var pink := float(lab.starts.yellow.y)
		var guide: Dictionary = screen.manipulator.guide()
		if not (pink == red and red == lab.DROP_HEIGHT):
			problems.append("stage %d: the balls at %.1f m and %.1f m, not level at %.1f m" % [stage + 1, pink, red, lab.DROP_HEIGHT])
		if not str(guide.get("id", "")).begins_with("drop_") or guide.get("kind", "") != "tap":
			problems.append("stage %d: the hand guide shows %s %s, not a tap on a ball" % [stage + 1, str(guide.get("kind")), str(guide.get("id"))])
	expect.call(problems.is_empty(), "first entry (free-fall): at every stage both balls wait level and the hand guide taps a ball", "; ".join(problems))
	await _close(screen)
	DirAccess.remove_absolute(ProgressStore.path)
