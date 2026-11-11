## The story on the island map (the story "별 조각 찾기", 2026-10-28; the words and saved marks: Story).
## It plays three things over the map, each with its own camera moves:
## - the prologue (first launch, or 이야기 다시 보기 in the settings): 8 pages in the dialogue box, the
##   camera gliding from the far sea of 퍼피랜드 to 과학섬, night falling, the guiding star breaking into
##   11 pieces that land at the 11 spots, the dark sea and the lost boats' lanterns, a sweep over the
##   island, then the bread cat on the square as the day comes back. A tap turns the page; 건너뛰기
##   skips it all. Afterwards the map is as it was (no piece on it, the day, the child's camera).
##   Another island's prologue (#75: the hutton island's lines after the voyage) is its words over its
##   square by day, the camera easing between a few views of it; the map's night comes on the last page.
## - a found piece's flight (a round completed in a lab): after the spot's flag rises, a star piece
##   flies from the spot to the lookout (전망대) and the corner emblem (StarEmblem) fills a wedge.
## - the finale (the 11th piece at the lookout, once): the pieces gather into the whole star, Puppy and
##   Dugi speak, the bread cat lifts the star, and the child sends it up like the slingshot in the labs
##   (2026-11-01 user: "여기서 배운 물리 실험을 이용해서 올려보내면 좋겟다"): pull the star down and let
##   go; it flies straight up at the pull's speed under gravity (y = y0 + v t - g t^2 / 2). A weak pull
##   rises and comes back down (Dugi: gravity pulled it back, pull harder); one that reaches the sky
##   (its top y0 + v^2 / 2g reaches SKY_HIGH.y) stays there: the sea sparkles, the boats light their lanterns and sail,
##   and the island's mission is complete (#118): fireworks, confetti, the "<island> 완성!" ribbon, the trio
##   cheer; then the words after the sky on the square (Story.finale_after, and Puppy's finale_next once
##   the next island opened). The star then stays in the map's sky and the trio stay on the island
##   (← 돌아가기 nudges while the next island waits on 섬 고르기).
##
## The finale is saved as seen only at its end or 건너뛰기 (#108, 2026-11-09 user): left half way (back,
## the app closed) it plays again the next time the map opens. After HELP_AFTER_MISSES misses in it the
## child is helped (an easier pull or drag, helped).
##
## The camera: while a prologue or the finale plays the director draws the rig itself (the rig's own
## easing is paused; the child's view, goal_* and pan, is never touched) with eased moves between
## shots, and at the end it eases back to the child's view and hands the rig back exactly there
## (CameraRig.snap). A flight uses the rig's own timed close-up (CameraRig.focus), like the flag raise.
## The night is a global multiplier on the map's shaders (story_tint) and the map's sea colour, put
## back to the day when the map goes away (the labs are always bright).
##
## The night map (2026-10-28 user-approved "explore the night map in a fixed order"): after the
## prologue the map stays night; it lifts a step per piece at the lookout and the finale brings the
## day (Story.night_level; derived from the pieces, nothing new saved). Found spots are lit (map_lit
## lit_mask). Only the next spot (Story.order) and the found ones open; Puppy says the next one's riddle
## in his box at the bottom when the map is free (after a flag raise, a flight, the prologue), again
## on a tap on him or 단서; a tapped locked spot gets "음… 여긴 아닌 것 같아." and a small shake; after
## HINT_DELAY_S without finding it the next spot glints (a small star twinkling, again and again).
##
## The sundial's finale (#106, 2026-11-09 user decisions; the hutton island, home.dial): the pages are
## its story file's 9 lines. The camera starts at the volcano where the gnomon stands on the new land
## (lines 1-2), glides over the new land, whose grass sprouts (3-4), to the square, where the dial the
## found wedges filled one by one (each in its own sector as it flew in, #114) glints; Dugi says to
## plant the gnomon (5)
## and the child drags it from over the cat's paws into the dial's middle (a short drag back: it goes
## back to the paws, the paw shows it again). Then the day comes, the gnomon's shadow grows on the dial
## and the emblem gets its gnomon and face (6-9). No star: the hutton sky stays empty. The gnomon's own
## piece (the volcano's) never flies on the map: it is the gnomon of this scene.
##
## Pictures and words only: the director never opens a lab, sets a control or reads a body (the
## finale's launch is its own formula, no physics body). Its 3D nodes are outside the map's default
## view or gone after the story (the map stays clean), apart from the sky star after the finale.
class_name StoryDirector
extends Node

signal ended(part: String)
## 보호자 on Puppy's "today's new spot is used" box was pressed (#77): the map opens the guardian's check.
signal guardian_requested

const NIGHT_TINT := Vector3(0.42, 0.5, 0.82)
## The 보호자 button's height on Puppy's box (#77): small, the words stay the box's.
const DARK_TINT := Vector3(0.26, 0.31, 0.6)
const NIGHT_SEA := Color("1b4478")
const DARK_SEA := Color("0e2649")
## The sky backdrop's own extra night on top of the tint (2026-10-28 device check: the tinted day sky
## still read as day, a light blue over the dark sea): night and the darker night.
const NIGHT_SKY := Vector3(0.22, 0.24, 0.4)
const DARK_SKY := Vector3(0.16, 0.18, 0.32)
## The guiding star in the prologue's night sky, above and behind the island (default view: -z).
const STAR_AT := Vector3(0.0, 24.0, -16.0)
const STAR_SIZE := 2.4
## Where the star rests in the map's sky after the finale: high over the island's middle, inside the
## map's default view (tests), and where it first rises to.
const SKY_STAR_AT := Vector3(2.5, 8.5, -3.0)
const SKY_STAR_SIZE := 0.9
const SKY_HIGH := Vector3(3.0, 21.0, -6.0)
## The finale's launch (2026-11-01): the pull straight down (UI units) gives the speed up, a full pull
## LAUNCH_PULL_FULL the most, LAUNCH_V_MAX; the star flies y = y0 + v t - LAUNCH_G t^2 / 2 and reaches
## the sky when its top y0 + v^2 / 2g gets to SKY_HIGH.y (about three quarters of a full pull).
const LAUNCH_G := 9.8
const LAUNCH_V_MAX := 25.0
const LAUNCH_PULL_FULL := 170.0
const LAUNCH_DEAD_ZONE := Manipulator.PULL_DEAD_ZONE   # UI units a press may move and still be a tap
const LAUNCH_DIP_M := 1.2          # m the star comes down under the paws at a full pull
const LAUNCH_GUIDE_SHARE := 0.8    # of a full pull the paw shows
const AIM_DOT_SCALE := 3.0         # the aim dots: three times the pull dots' size and spacing
const PIECE_SIZE := 0.42
## The star finale's end (#118): when the celebration starts after the star reached the sky (s), the
## ribbon's pop in (from RIBBON_FROM of its size over RIBBON_IN_S), stay and fade (s), font and height
## (share of the view from the top), and when the words after the sky start once the cat hopped home (s).
const CELEBRATE_AT_S := 0.5
const RIBBON_FROM := 0.3
const RIBBON_IN_S := 0.35
const RIBBON_S := 2.4
const RIBBON_OUT_S := 0.5
const RIBBON_FONT := 46
const RIBBON_Y := 0.18
const AFTER_WORDS_S := 1.2
const FLIGHT_IN_S := 0.6
const FLIGHT_S := 1.3
const FLIGHT_OUT_S := 0.6
const RETURN_S := 1.4
const FIRST_SHOT := {"yaw": 0.0, "pitch": -8.0, "dist": 150.0, "target": Vector3(0.0, 6.0, -55.0)}
const DIALOGUE_MARGIN := 12.0
const DIALOGUE_SHARE := 0.8        # of the view width the box may take (the scene stays in view)
## Another island's prologue (#75): its square seen from these [yaw deg, pitch deg, distance m] in turn.
const SQUARE_SHOTS := [[15.0, -20.0, 9.0], [-25.0, -24.0, 8.0], [40.0, -30.0, 11.0], [-5.0, -16.0, 7.5]]
## Another island's prologue starts on the beach (BEACH_YAW: looking in from the sea, the voyage's
## landing view) and the three walk up to the square over STROLL_S (IslandHomeScreen.stroll_home).
const BEACH_YAW := 20.0
const STROLL_S := 7.0
## The night map's hint: the next spot glints this long after the riddle, a twinkle every period.
const HINT_DELAY_S := 20.0
const HINT_PERIOD_S := 2.4
const HINT_TWINKLE_S := 1.1
const HINT_SIZE := 0.42
const GLOW_MARGIN := 0.35          # the riddle's ring reaches this far past the spot's stage (m)
## The sundial's finale (#106, the header).
const NEEDLE_LAND_AT := 0.4       # where on the new land the gnomon stands (share along it)
const NEEDLE_LAND_SCALE := 2.4     # it stands big there (the volcano lab pushed it up)
const NEEDLE_HELD_SCALE := 1.3     # held up by the cat
const NEEDLE_HOLD_Y := 0.95        # m over the cat's feet where it holds the gnomon's middle
const PLANT_SHARE := 0.6           # of the way from the paws to the dial a drag must reach to plant
## The child is helped after this many misses in a finale (#108, 2026-11-09 user): the star that came
## back down, the gnomon let go short of the dial. Then the star reaches the sky with any pull past a tap
## and the gnomon goes in from PLANT_SHARE_HELPED of the way.
const HELP_AFTER_MISSES := 3
const PLANT_SHARE_HELPED := 0.2
const HELP_SKY_MARGIN := 1.02     # the helped star's speed this much over the one that just reaches the sky (float error)
const PLANT_PAGE := 4              # the page after which the child plants the gnomon (Dugi: 이제 바늘을 꽂아 봐요)
## The filled dial's glint before Dugi's "plant it" (#114: the wedges are in their places already):
## the camera's glide to it, the swell of the glint and how long it lasts.
const DIAL_GLINT_IN_S := 1.4
const DIAL_GLINT_SWELL := 0.08
const DIAL_GLINT_S := 0.6
const NEEDLE_MOVE_S := 0.35        # the gnomon easing into the dial (or back to the paws)
const SHADOW_GROW_S := 1.6
const GRASS_GROW_S := 0.8

var home: IslandHomeScreen
var part := ""                     # "", "prologue", "flight", "finale"
var page := -1                     # the prologue / finale page now (-1: none)
var sea: MapSea
var emblem: PieceEmblem
var sky_star: Node3D
var dialogue: DialogueBox
var shield: Control
var skip_button: Button
## Night: 0 day, 1 night, 2 the darker night after the star broke. The tint it puts on (tests).
var night := 0.0
var _sky_t := 0.0     # the sky star's and the guiding star's sway clocks (StarArt.face_camera)
var _star_t := 0.0
var tint := Vector3.ONE
var placed_count := 0              # pieces at the lookout shown on the emblem
var _glint_t := -1.0               # the filled dial's glint before the plant (s; -1: none)
var flights_played := 0            # (tests)
var _night_from := 0.0
var _night_to := 0.0
var _night_t := 0.0
var _night_s := 0.0
var _day_sea := Color.BLACK
var _can_tint := false
## The camera while the director draws it: an eased move from one shot to another.
var _driving := false
var _cam_from: Dictionary = {}
var _cam_to: Dictionary = {}
var _cam_t := 0.0
var _cam_s := 0.0
var _returning := false
## Timed beats of the current page: [[seconds left, Callable], ...].
var _beats: Array = []
var _clock := 0.0
var _star: Node3D = null           # the guiding star while it is whole in a story
var _star_motion: Dictionary = {}  # {from, to, t, s} a move of _star
var _pieces: Array = []            # [{node, from, ctrl, to, t, s, spin}]
var _sparkles: Array = []          # [node, phase]
var _cat_hop: Dictionary = {}      # {from, to, t, s, height}
var _boats_wander := false
var _boats_sail := -1.0
var _flight_queue: Array = []
var _flight: Dictionary = {}       # {id, node, from, to, slot (the sundial's sector), spin, t}
var _lift := false                 # the finale's star rides above the cat's paws
var launch_waits := false          # the finale waits for the child's pull on the star
var launches := 0                  # pulls let go (tests)
var misses := 0                    # this finale's misses: the star came back down, the gnomon let go short (HELP_AFTER_MISSES)
var _pull: Dictionary = {}         # {press, now} the finger pulling the star (screen, UI units)
var _launch: Dictionary = {}       # {from, v, t} the star flying up
var _retry_open := false           # Dugi's "pull harder" line is in the box
var _pull_dots: PullDots = null    # the pull, from the paws down to the star
var _aim_dots: PullDots = null     # how high this pull sends it (larger dots, up from the star)
var launch_guide: HandGuide = null  # the paw showing the pull on the star (its own: the map's guide stops in a story)
var _finale_due := false           # all pieces found, the finale not played: after the flights
var _finale_done := false          # the star is back in the sky: the map is day
var _after := -1                   # the line of the star finale's words after the sky (_after_lines), -1: none
var ribbon: Control                # the island's "<island> 완성!" ribbon (#118), while it shows
## The sundial's finale (#106, the hutton island: home.dial): the gnomon (해시계 바늘) node while it
## stands on the new land, rides over the cat's paws and is planted; the wedges flying to their places.
var needle: Node3D = null
var plant_waits := false           # the finale waits for the child to drag the gnomon into the dial
var plants := 0                    # the gnomon planted (tests)
var _plant: Dictionary = {}        # {press, now} the finger dragging the gnomon (screen, UI units)
var _needle_motion: Dictionary = {}   # {from, to, t, s, then} an eased move of the needle, `then` called at its end
var _held := false                 # the needle rides over the cat's paws
var _shadow_t := -1.0              # the gnomon's shadow growing (s since the sun came back; -1: not)
var _grass_t := -1.0               # the new land's grass sprouting (s; -1: not)
## The night map's exploration (refresh): the next spot ("" when all are found) and the found ones.
var next_id := ""
var found_ids: Array = []
var riddle: DialogueBox            # Puppy's box on the map (no shield: the map stays live)
var riddles_told := 0              # (tests)
var wrongs_told := 0               # (tests)
var hint: Node3D                   # the next spot's glint (null until the first hint)
var _riddle_due := false           # say the riddle as soon as the map is free
var _hint_t := 0.0                 # seconds since the riddle was last said
## The hand guide's tap on the next spot (HandGuide, 2026-10-30): once after Puppy's first riddle
## closes (ProgressStore GUIDES "map"), and each time the hint starts to glint.
var map_guide: HandGuide = null
var _riddle_was_open := false
## While Puppy's riddle is in his box the next spot's stage faintly glows (2026-10-29 user "해당
## 포인트를 희미하게 강조": a soft warm ring, slowly pulsing; ClueGlow), fading out when the box closes.
## Subtle on purpose: it does not name the spot (the 20 s hint glint stays the loud help).
var spot_glow: ClueGlow            # null until the first riddle
var _riddle_open := false          # the box holds the riddle (not the "not here" line)


func _init(screen: IslandHomeScreen) -> void:
	name = "StoryDirector"
	home = screen


func _ready() -> void:
	_can_tint = DisplayServer.get_name() != "headless"
	_day_sea = home.env.environment.background_color if home.env != null else MapIsland.sea_color()
	sea = MapSea.new()
	sea.build(home.world)
	sea.set_lanterns(Story.finale_seen())
	emblem = PieceArt.emblem(home.island.piece, Story.spots().size())
	home.add_child(emblem)
	placed_count = Story.placed(ProgressStore.load()).size()
	emblem.set_filled(placed_count)
	_finale_done = Story.finale_seen()
	if _finale_done:
		if _sundial():
			(emblem as SundialEmblem).set_whole(true)
		else:
			_place_sky_star()
	if not home.play_prologue_on_open:   # the prologue starts by day and ends on the map's night
		_set_night(map_night())
	_layout()
	home.resized.connect(_layout)
	var back: Control = home.find_child("MapBackButton", true, false)
	if back != null:
		back.minimum_size_changed.connect(_layout)   # the emblem keeps under the map's ← (#114)


func _exit_tree() -> void:
	_set_night(0.0)   # never leave the night on (the map is swapped out mid-story)


# --- state -------------------------------------------------------------------------------------

## A prologue or the finale plays: the director has the camera and the screen (the map's labels,
## map buttons and taps wait).
func cinematic() -> bool:
	return part == "prologue" or part == "finale"


## Anything of the story plays (a flight too).
func busy() -> bool:
	return part != ""


func flying() -> bool:
	return part == "flight"


## After the map's progress is read (and its flag raises queued): queue the found pieces' flights;
## the finale follows the last one. Nothing starts while the prologue or a flag raise plays.
func refresh() -> void:
	var progress := ProgressStore.load()
	_flight_queue = Story.to_fly(progress)
	_finale_due = Story.found(progress).size() >= Story.spots().size() and not Story.finale_seen()
	found_ids = Story.found(progress)
	next_id = Story.next_spot(progress)
	home.light_spots(found_ids)
	home.show_clue_button(next_id != "")
	_riddle_due = next_id != ""


## The map's night now: the story's night lifting a step per piece at the lookout, day after the finale.
func map_night() -> float:
	return Story.night_level(placed_count, _finale_done)


# --- the night map: locks, Puppy's riddle, the hint --------------------------------------------

## The spot does not open yet: neither found nor the next one.
func locked(id: String) -> bool:
	return next_id != "" and id != next_id and id not in found_ids


## The next spot waits for tomorrow: an island not bought whose new spot of today is used (#77).
func waits_for_tomorrow(id: String) -> bool:
	return id == next_id and next_id != "" and not DailyLimit.allows(Island.current_id(), id)


## The spot's name shows on the map: its piece is found (an unfound spot's name stays a secret).
func label_shown(id: String) -> bool:
	return id in found_ids


## Puppy says the next spot's riddle (one page, his box at the bottom); the hint waits again.
func say_riddle() -> void:
	if next_id == "" or cinematic():
		return
	_riddle_due = false
	_hint_t = 0.0
	_hide_hint()
	if map_guide != null:
		map_guide.stop()
	var spot := ExperimentRegistry.find(next_id)
	if Story.map_clue(spot) == "":
		return   # a spot with no riddle (an island in the making, #72)
	_say(Story.map_clue(spot), Story.map_clue_face(spot))
	_riddle_open = true
	riddles_told += 1


## A locked spot was tapped: Puppy's "not here" line (the riddle's timer goes on).
func say_wrong() -> void:
	if cinematic():
		return
	_riddle_due = false
	_riddle_open = false
	if Story.wrong_line() == "":
		return   # an island whose story has no such line yet
	_say(Story.wrong_line(), Story.wrong_face())
	wrongs_told += 1


## The next spot waits for tomorrow (#77): Puppy's calm "that's all for today" with the small 보호자
## button at his box's right end (the guardian's check, then the island's offer). Nothing urges buying.
func say_today() -> void:
	if cinematic():
		return
	_riddle_due = false
	_riddle_open = false
	if Story.today_line() == "":
		return
	_say(Story.today_line(), Story.today_face())
	var guardian := GuardianModal.guardian_button()
	guardian.name = "GuardianButton"
	guardian.pressed.connect(guardian_requested.emit)
	riddle.set_side_button(guardian)
	_layout()


## The child is on the way to a spot: Puppy's box closes.
func hush() -> void:
	_riddle_due = false
	if map_guide != null:
		map_guide.stop()
	if riddle != null and riddle.active:
		riddle.close(true)
	_step_spot_glow(0.0)


## A tap on the map beside Puppy's open box (not on a spot): his page turns as a tap on the box does.
## True if a box was open.
func tap_riddle() -> bool:
	if riddle == null or not riddle.active:
		return false
	riddle.advance()
	return true


## Back on the map (Android back): Puppy's open box closes first. True if it did.
func close_riddle() -> bool:
	if riddle == null or not riddle.active:
		return false
	hush()
	return true


## The next spot glows while its riddle is told (the box open with the riddle).
func riddle_glowing() -> bool:
	return spot_glow != null and spot_glow.on


func _step_spot_glow(delta: float) -> void:
	var on := _riddle_open and riddle != null and riddle.active and next_id != "" and not cinematic()
	if not on:
		_riddle_open = _riddle_open and riddle != null and riddle.active
	if on and spot_glow == null:
		spot_glow = ClueGlow.ring(1.0)
		spot_glow.name = "RiddleGlow"
		spot_glow.set_process(false)   # stepped here with the story (tests step it)
		home.world.add_child(spot_glow)
	if spot_glow == null:
		return
	if on:
		for spot in home._spots:
			if spot.id == next_id:
				spot_glow.position = spot.at + Vector3.UP * 0.04
				spot_glow.scale = Vector3.ONE * (maxf(float(spot.radius), 0.9) + GLOW_MARGIN)   # the pond has no stage (0)
	spot_glow.set_on(on)
	spot_glow.step(delta)


func _say(words: String, face := "") -> void:
	if riddle == null:
		riddle = DialogueBox.new("")
		riddle.name = "PuppyRiddle"
		home.add_child(riddle)
	riddle.set_speaker("puppy", face)
	riddle.open(words)
	_layout()


## The hint's little star over the next spot, twinkling a moment every HINT_PERIOD_S.
func _step_hint(delta: float) -> void:
	if next_id == "" or _riddle_due or busy() or home.raising():
		return
	_hint_t += delta
	if _hint_t < HINT_DELAY_S:
		return
	if _hint_t - delta < HINT_DELAY_S:
		tap_next_spot()   # the hint starts: the hand taps the spot too
	if hint == null:
		hint = StarArt.make(false, HINT_SIZE)
		hint.name = "HintGlint"
		home.world.add_child(hint)
		SoundBoard.play(&"glint")
	for spot in home._spots:
		if spot.id == next_id:
			hint.position = spot.at + Vector3.UP * (float(spot.top) + 0.55)
	var phase := fmod(_hint_t - HINT_DELAY_S, HINT_PERIOD_S)
	var k := clampf(phase / HINT_TWINKLE_S, 0.0, 1.0)
	hint.visible = k < 1.0
	hint.scale = Vector3.ONE * maxf(0.01, sin(PI * k))
	StarArt.face_camera(hint, home.view.rig, _hint_t)


func _hide_hint() -> void:
	if hint != null:
		hint.visible = false


## The hand taps the next spot (the map's guide): its top on the view, while it is on screen and the
## trio is not already walking there. True when it plays.
func tap_next_spot() -> bool:
	if next_id == "" or busy() or home._walking or Story.measurement_run(Quality.all_args()):
		return false
	var top := Vector3.INF
	for spot in home._spots:
		if spot.id == next_id:
			top = spot.at + Vector3.UP * float(spot.top)
	if top == Vector3.INF or not Rect2(Vector2.ZERO, home.size).has_point(home._world_to_screen(top)):
		return false
	if map_guide == null:
		map_guide = HandGuide.new()
		home.add_child(map_guide)
	if riddle != null and map_guide.get_index() > riddle.get_index():
		home.move_child(map_guide, riddle.get_index())   # under Puppy's box: his words stay readable
	map_guide.play("tap", func() -> Vector2:
		var at := home._world_to_screen(top)
		return at if at != Vector2.INF else HandGuide.OFF_VIEW)
	return true


## Puppy's riddle just closed for the first time on this device (by a tap or its timer, not because the
## child is already walking to a spot): the hand shows where to tap; kept only once it really played.
## The hand goes when a new riddle or line opens, a cinematic starts or the trio walks.
func _step_map_guide() -> void:
	var open := riddle != null and riddle.active
	if _riddle_was_open and not open and not home._walking and not ProgressStore.mark(ProgressStore.GUIDES, "map"):
		if tap_next_spot():
			ProgressStore.set_mark(ProgressStore.GUIDES, "map", true)
	var opened := open and not _riddle_was_open
	_riddle_was_open = open
	if map_guide != null and (opened or busy() or home._walking):
		map_guide.stop()


## The hint glints now (tests).
func hinting() -> bool:
	return hint != null and hint.visible


# --- the prologue -------------------------------------------------------------------------------

func play_prologue() -> void:
	if cinematic():
		return
	_begin("prologue")
	home.trio_home()   # the story starts on the square (its last page shows the cat there)
	if _first_island():
		_set_camera(FIRST_SHOT)
	else:
		# Another island: on the beach where the voyage's boat landed (the keeper waited there), then
		# the three walk up to the square while they talk (2026-11-10 user: no jump to the middle).
		var beach := VoyageScreen.keeper_spot(home.map)
		home.stroll_home(beach, STROLL_S)
		_set_camera(_beach_shot(beach))
	_open_page(0)


## The story is the first island's (its prologue's star and boats); another island's is words over its square.
func _first_island() -> bool:
	return home.island.id == "" or home.island.id == ProgressStore.FIRST_ISLAND


## Another island's first prologue view: the beach where the boat landed, from the sea's side.
func _beach_shot(beach: Vector2) -> Dictionary:
	return {"yaw": BEACH_YAW, "pitch": -18.0, "dist": 9.0, "target": Vector3(beach.x, 0.6, beach.y)}


## Another island's prologue view `i` of its square (SQUARE_SHOTS), `far` times the distance.
func _square_shot(i: int, far := 1.0) -> Dictionary:
	var home_at := Vector3(home.island.home.x, 0.5, home.island.home.y)
	var s: Array = SQUARE_SHOTS[i % SQUARE_SHOTS.size()]
	return {"yaw": s[0], "pitch": s[1], "dist": float(s[2]) * far, "target": home_at}


## The page `i` of the current part: its words (if any) and its camera, night and beats.
func _open_page(i: int) -> void:
	page = i
	_beats.clear()
	var pages := Story.pages(part)
	if part == "prologue":
		_prologue_page(i)
	elif _sundial():
		_dial_page(i)
	else:
		_finale_page(i)
	if i < pages.size():
		var entry: Dictionary = pages[i]
		dialogue.set_speaker(str(entry.get("who", "dugi")), Story.face_or_default(entry.get("face")))
		dialogue.open(str(entry.get("text", "")), "", Story.page_picture(entry))
		_layout()


func _prologue_page(i: int) -> void:
	if not _first_island():
		if i == 0:   # the camera follows the three up from the beach to the square over STROLL_S
			_move(_square_shot(0), STROLL_S)
		elif i > 1 or not home.strolling():
			_move(_square_shot(i), 2.2)
		if i == Story.pages("prologue").size() - 1:
			_beat(1.2, func() -> void: _night(map_night(), 2.0))
		return
	var home_at := Vector3(home.island.home.x, 0.0, home.island.home.y)
	match i:
		0:   # the far sea of 퍼피랜드: islands, boats; a slow drift
			_move({"yaw": 6.0, "pitch": -9.0, "dist": 138.0, "target": FIRST_SHOT.target}, 7.0)
		1:   # gliding in towards 과학섬
			_move({"yaw": 0.0, "pitch": -32.0, "dist": 36.0, "target": Vector3(0.0, 0.5, 0.0)}, 3.4)
		2:   # night falls; the guiding star; the camera tilts up to it
			_night(1.0, 1.8)
			sea.set_lanterns(true)
			_beat(0.7, _show_star)
			_move({"yaw": 0.0, "pitch": 24.0, "dist": 34.0, "target": STAR_AT}, 3.0)
		3:   # it cracks and breaks; the pieces fall to the spots; the camera pulls back to see them land
			_beat(0.0, func() -> void: _shake_star(0.6))
			_beat(0.6, _break_star)
			_move({"yaw": 0.0, "pitch": -12.0, "dist": 58.0, "target": Vector3(0.0, 9.0, -5.0)}, 2.4)
		4:   # the sea goes darker, the lost boats' lanterns wander
			_night(2.0, 1.5)
			_boats_wander = true
			_move({"yaw": 40.0, "pitch": -13.0, "dist": 52.0, "target": Vector3.ZERO}, 3.0)
		5:   # a sweep over the island: the pieces glint at the spots
			_move({"yaw": -30.0, "pitch": -42.0, "dist": 25.0, "target": Vector3(0.0, 0.5, 0.0)}, 5.0, true)
		6:   # the sweep goes on
			_move({"yaw": -110.0, "pitch": -45.0, "dist": 23.0, "target": Vector3(0.0, 0.5, 0.0)}, 6.0, true)
		7:   # the square: the bread cat hops out and lifts a paw; the day comes back
			_move({"yaw": 0.0, "pitch": -24.0, "dist": 7.0, "target": home_at + Vector3(0.0, 0.5, 0.0)}, 2.2)   # the map-size trio (IslandHomeScreen.ACTOR_SCALE)
			_beat(1.0, func() -> void:
				_night(map_night(), 2.0)   # the map's night (no star in the sky yet; day only once explored)
				_boats_wander = false)
			_beat(1.5, func() -> void:
				_hop_cat(home.cat.position, home.cat.position, 0.6, 0.8)
				SoundBoard.play(&"hop"))
			_beat(2.1, func() -> void: home.cat.cheer(true, 2))
			_beat(2.0, _fade_pieces)


## The words of the page closed (a tap past it, or its read timer): the next page, or the end.
func _on_dialogue_closed() -> void:
	if not cinematic() or _returning:
		return
	var pages := Story.pages(part)
	if part == "prologue":
		if page < pages.size() - 1:
			_open_page(page + 1)
		else:
			_end_cinematic()
	elif part == "finale":
		if _after >= 0:
			_open_after(_after + 1)
		elif _sundial():
			_dial_page_closed()
		elif _retry_open:
			_retry_open = false
			_wait_launch()
		elif page < pages.size() - 1:
			_open_page(page + 1)
		elif page == pages.size() - 1:
			_open_page(pages.size())   # the last part has no words: the child's pull


# --- the finale ---------------------------------------------------------------------------------

func play_finale() -> void:
	if cinematic():
		return
	misses = 0
	_begin("finale")   # (seen once it ends or is skipped, _finish: left half way, it plays again, #108)
	if _sundial():
		_dial_intro()
	else:
		_finale_intro()


## The island's finale is the sundial's (#106: the hutton island's dial on the map and its sundial
## pieces, so its emblem is the dial), not the star's.
func _sundial() -> bool:
	return home.dial != null and emblem is SundialEmblem


func _lookout() -> Dictionary:
	if home.island.lookout == Island.HOME:   # the square's sundial (the hutton island, #72)
		return home.map.home_lookout()
	for spot in home._spots:
		if spot.id == home.island.lookout:
			return spot
	return home._spots[0]


func _lookout_point() -> Vector3:
	var spot := _lookout()
	return spot.at + Vector3.UP * (float(spot.top) + 1.6)


## Before the words: the camera goes to the lookout, the pieces gather into the whole star there.
func _finale_intro() -> void:
	page = -1
	var at := _lookout_point()
	_move({"yaw": -25.0, "pitch": -20.0, "dist": 10.5, "target": at}, 1.8)
	_beat(0.6, _gather_pieces)
	_beat(2.9, func() -> void: _open_page(0))


func _finale_page(i: int) -> void:
	var at := _lookout_point()
	match i:
		0:
			_move({"yaw": -15.0, "pitch": -16.0, "dist": 9.0, "target": at}, 2.0)
		1:
			_move({"yaw": -35.0, "pitch": -18.0, "dist": 10.0, "target": at}, 2.5)
		2:   # Dugi: pull it like the slingshot; the cat hops over and lifts the star meanwhile
			var spot := _lookout()
			_hop_cat(home.cat.position, spot.stand, 1.1, 1.2)
			SoundBoard.play(&"hop")
			_move(_launch_shot(), 1.4)
			_beat(1.1, func() -> void:
				home.cat.cheer(true, 3)
				_lift = true)
		3:   # no words: the child pulls the star down and lets go
			_wait_launch()


## The shot while the child pulls: the cat, the star and the sky above them.
func _launch_shot() -> Dictionary:
	var paws: Vector3 = _lookout().stand + Vector3.UP * (2.0 * IslandHomeScreen.ACTOR_SCALE + 0.3)
	return {"yaw": -25.0, "pitch": -6.0, "dist": 13.0, "target": paws + Vector3.UP * 1.6}


## Waits for the pull (the paw shows it: press anywhere, pull down, let go), once the cat stands at
## the lookout with the star over its paws.
func _wait_launch() -> void:
	if not _cat_hop.is_empty():
		_beat(0.1, _wait_launch)   # (the page was tapped through while the cat still hopped over)
		return
	if not launch_waits and launches == 0:
		home.cat.cheer(true, 3)
	_lift = true
	launch_waits = true
	if Quality.cmdline_value("demo-story").get_slice(":", 0) == "finale":
		_beat(2.0, func() -> void: launch_star(LAUNCH_V_MAX))   # the screenshot run: a full pull by itself
	_pull = {}
	_move(_launch_shot(), 1.0)
	if launch_guide == null:
		launch_guide = HandGuide.new()
		home.add_child(launch_guide)
	home.move_child(launch_guide, shield.get_index() + 1)   # over the shield (the paw takes no touch)
	_show_guide()


func _show_guide() -> void:
	var star_at := func() -> Vector2:
		var at := home._world_to_screen(_star.global_position) if _star != null else Vector2.INF
		return at if at != Vector2.INF else HandGuide.OFF_VIEW
	launch_guide.play("pull", star_at, func() -> Vector2: return star_at.call() + Vector2(0.0, LAUNCH_PULL_FULL * LAUNCH_GUIDE_SHARE), 3)


## The speed (m/s) a pull of `pixels` straight down gives (0 inside the dead zone).
static func launch_speed(pixels: float) -> float:
	if pixels <= LAUNCH_DEAD_ZONE:
		return 0.0
	return LAUNCH_V_MAX * clampf(pixels / LAUNCH_PULL_FULL, 0.0, 1.0)


## The speed this finale's pull of `pixels` gives: launch_speed, and once the child was helped
## (HELP_AFTER_MISSES) at least the speed that reaches the sky from the paws, sqrt(2 g (sky - y0))
## (times HELP_SKY_MARGIN).
func pull_speed(pixels: float) -> float:
	var speed := launch_speed(pixels)
	if speed > 0.0 and helped():
		speed = maxf(speed, sqrt(2.0 * LAUNCH_G * maxf(SKY_HIGH.y - _paws_top().y, 0.0)) * HELP_SKY_MARGIN)
	return speed


## The child missed HELP_AFTER_MISSES times in this finale: the easier rule (any pull past a tap reaches
## the sky, pull_speed; the gnomon goes in from PLANT_SHARE_HELPED of the way).
func helped() -> bool:
	return misses >= HELP_AFTER_MISSES


## The star's highest point (y) when it leaves `from_y` at `speed` up: y0 + v^2 / 2g.
static func launch_top(from_y: float, speed: float) -> float:
	return from_y + speed * speed / (2.0 * LAUNCH_G)


## The finger on the screen (anywhere) while the finale waits: press, pull down (the star comes down
## under the paws, dots show how high it will go), let go (it flies; a tap or an upward pull does
## not, and the paw shows the pull again).
func _launch_input(kind: String, position: Vector2) -> void:
	match kind:
		"press":
			_pull = {"press": position, "now": position}
			if launch_guide != null:
				launch_guide.stop()
		"move":
			if not _pull.is_empty():
				_pull.now = position
		"release":
			if _pull.is_empty():
				return
			var pixels: float = maxf(0.0, (_pull.now as Vector2).y - (_pull.press as Vector2).y)
			_pull = {}
			_hide_pull()
			var speed := pull_speed(pixels)
			if speed > 0.0:
				launch_star(speed)
			elif launch_guide != null:
				_show_guide()
		"cancel":
			_pull = {}
			_hide_pull()


## The star leaves the paws straight up at `speed` m/s (the pull's; tests call it too).
func launch_star(speed: float) -> void:
	if _star == null or not launch_waits:
		return
	launch_waits = false
	launches += 1
	_lift = false
	_star.position = _paws_top()   # it leaves from the paws (also when the cat had only just got there)
	_launch = {"from": _star.position, "v": speed, "t": 0.0}
	SoundBoard.play(&"launch")
	home.cat.cheer(true, 2)
	var top := minf(launch_top(_star.position.y, speed), SKY_HIGH.y)
	var look := Vector3(_star.position.x, (_star.position.y + top) * 0.5, _star.position.z)
	_move({"yaw": -15.0, "pitch": 8.0, "dist": maxf(16.0, (top - _star.position.y) * 1.6), "target": look}, 0.9)


func _step_launch(delta: float) -> void:
	if not _pull.is_empty() and _star != null and home.cat != null:
		var pixels: float = maxf(0.0, (_pull.now as Vector2).y - (_pull.press as Vector2).y)
		var share := clampf(pixels / LAUNCH_PULL_FULL, 0.0, 1.0)
		var cradle := _paws_top()
		_star.position = cradle + Vector3.DOWN * LAUNCH_DIP_M * share   # (after _step_star: no lift lerp while pulling)
		_show_pull(cradle, _star.position, pull_speed(pixels))
	if _launch.is_empty() or _star == null:
		return
	_launch.t += delta
	var from: Vector3 = _launch.from
	var v: float = _launch.v
	var t: float = _launch.t
	var y := from.y + v * t - 0.5 * LAUNCH_G * t * t
	_star.position = Vector3(from.x, y, from.z)
	if y >= SKY_HIGH.y:
		_launch = {}
		_reach_sky()
	elif t > v / LAUNCH_G and y <= from.y:
		# It came back down (gravity): to the paws again, and Dugi says pull harder.
		_launch = {}
		misses += 1
		_star.position.y = from.y
		_lift = true
		SoundBoard.play(&"land")
		_move(_launch_shot(), 0.8)
		_retry_open = true
		dialogue.set_speaker("dugi", Story.finale_retry_face())
		dialogue.open(Story.finale_retry_line())
		_layout()


## The star got to the sky: the day comes back, the sea sparkles, the boats sail, and the island's
## mission is complete (#118, 2026-11-11 user: "섬 미션 완성을 알리는 좀 더 이펙트도 추가해주고"):
## fireworks, confetti and the "<island> 완성!" ribbon (RIBBON_S), the trio cheer; then the star settles
## in the map's sky, the cat hops home and the three say the words after the sky (_after_lines) on
## the square.
func _reach_sky() -> void:
	SoundBoard.play(&"finale")
	_night(0.0, 2.6)
	_sparkle_sea()
	sea.set_lanterns(true)
	_boats_sail = 0.0
	_move_star(Vector3(_star.position.x, SKY_HIGH.y, _star.position.z), 0.4)
	_move({"yaw": 15.0, "pitch": -14.0, "dist": 62.0, "target": Vector3(0.0, 4.0, -4.0)}, 2.6)
	_beat(CELEBRATE_AT_S, _celebrate_island)
	_beat(3.7, func() -> void:
		_move_star(SKY_STAR_AT, RETURN_S)
		_hop_cat(home.cat.position, home.trio_spot(home.cat), 1.0, 1.0))
	_beat(3.7 + AFTER_WORDS_S, func() -> void: _open_after(0))


## Fireworks and confetti over the view, the island's ribbon, the trio cheering (#118).
func _celebrate_island() -> void:
	SoundBoard.play(&"fanfare")
	home.add_child(Fireworks.new())
	home.add_child(Confetti.new())
	if ribbon != null:
		ribbon.queue_free()
	ribbon = IslandCards.ribbon(Locale.t("story.island_done") % IslandCards.island_name(home.island.id), RIBBON_FONT)
	ribbon.name = "IslandDone"
	home.add_child(ribbon)
	ribbon.size = ribbon.get_combined_minimum_size()
	ribbon.position = Vector2((home.size.x - ribbon.size.x) * 0.5, home.size.y * RIBBON_Y)
	ribbon.pivot_offset = ribbon.size * 0.5
	ribbon.scale = Vector2.ONE * RIBBON_FROM
	var tween := ribbon.create_tween()
	tween.tween_property(ribbon, "scale", Vector2.ONE, RIBBON_IN_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(RIBBON_S)
	tween.tween_property(ribbon, "modulate:a", 0.0, RIBBON_OUT_S)
	tween.tween_callback(ribbon.queue_free)
	home.cat.cheer(true, 3)
	home.puppy.celebrate()
	home.dugi.celebrate()


## The words after the sky: the island's finale_after pages, then (when the next island opened)
## Puppy's finale_next (#118: back to 섬 고르기, the voyage plays there).
func _after_lines() -> Array:
	var lines: Array = Story.finale_after().duplicate()
	if Story.voyage_due(ProgressStore.load(), true) != "" and Story.finale_next_line() != "":   # (marked seen only at its end)
		lines.append({"who": "puppy", "face": Story.finale_next_face(), "text": Story.finale_next_line()})
	return lines


## The line `i` of the words after the sky on the square (the three there); past the last, the end.
func _open_after(i: int) -> void:
	var lines := _after_lines()
	if i >= lines.size():
		_after = -1
		_end_cinematic()
		return
	_after = i
	if i == 0:
		var home_at := Vector3(home.island.home.x, 0.5, home.island.home.y)
		_move({"yaw": 0.0, "pitch": -22.0, "dist": 8.0, "target": home_at}, 1.6)
	var entry: Dictionary = lines[i]
	dialogue.set_speaker(str(entry.get("who", "dugi")), Story.face_or_default(entry.get("face")))
	dialogue.open(str(entry.get("text", "")))
	_layout()


func _paws_top() -> Vector3:
	return home.cat.position + Vector3.UP * (2.0 * IslandHomeScreen.ACTOR_SCALE + 0.3)   # over the map-size cat's paws


func _show_pull(cradle: Vector3, star_at: Vector3, speed: float) -> void:
	if _pull_dots == null:
		_pull_dots = PullDots.new()
		home.world.add_child(_pull_dots)
		_aim_dots = PullDots.new()
		_aim_dots.scale = Vector3.ONE * AIM_DOT_SCALE
		home.world.add_child(_aim_dots)
	_pull_dots.show_line(star_at, cradle)
	var top := minf(launch_top(cradle.y, speed), SKY_HIGH.y)   # it leaves from the paws (launch_star)
	if speed > 0.0:
		_aim_dots.show_line(star_at / AIM_DOT_SCALE, Vector3(star_at.x, top, star_at.z) / AIM_DOT_SCALE)
	else:
		_aim_dots.hide_line()



func _hide_pull() -> void:
	if _pull_dots != null:
		_pull_dots.hide_line()
		_aim_dots.hide_line()


# --- the sundial's finale (#106: the hutton island) -------------------------------------------------

## The gnomon's foot in its own frame (SundialDial.needle_node draws it at the sundial's foot).
func _needle_base() -> Vector3:
	return Vector3(MapLandmarks.GNOMON_AT.x, MapLandmarks.DIAL_Y, MapLandmarks.GNOMON_AT.z)


## The gnomon standing on the new land (big: the volcano pushed it up there).
func _needle_land_xf() -> Transform3D:
	var at := home.map.new_land_point(NEEDLE_LAND_AT, 0.0) if home.map.new_land else Vector3.ZERO
	if at == Vector3.ZERO and home.island.features.has("volcano"):   # (a map built before the volcano was found)
		var v: Array = home.island.features.volcano.at
		at = Vector3(float(v[0]) - 2.0, 0.0, float(v[1]) + 0.5)
		at.y = home.map.height_at(at.x, at.z)
	return Transform3D(Basis().scaled(Vector3.ONE * NEEDLE_LAND_SCALE), at - _needle_base() * NEEDLE_LAND_SCALE)


## The gnomon held up by the cat, standing upright in front of its chest (its long edge up).
func _needle_held_xf() -> Transform3D:
	var basis := Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3.ONE * NEEDLE_HELD_SCALE)
	var hold := home.cat.position + Vector3(0.4, NEEDLE_HOLD_Y, 0.25)   # beside it, on the camera side
	return Transform3D(basis, hold - basis * SundialDial.needle_middle())


## The gnomon in the dial (where the whole dial draws it).
func _needle_planted_xf() -> Transform3D:
	return home.dial.transform * SundialDial.gnomon_transform()


## The gnomon `k` of the way from the cat's paws into the dial (the child's drag).
func _needle_between(k: float) -> Transform3D:
	return _blend(_needle_held_xf(), _needle_planted_xf(), k)


## A transform `k` of the way from `a` to `b` (turn, uniform scale, place).
static func _blend(a: Transform3D, b: Transform3D, k: float) -> Transform3D:
	var q := a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(), k)
	var s := lerpf(a.basis.get_scale().x, b.basis.get_scale().x, k)
	return Transform3D(Basis(q).scaled(Vector3.ONE * s), a.origin.lerp(b.origin, k))


## Where the gnomon is held by (its middle; the dial's top before it exists).
func _needle_point() -> Vector3:
	return needle.transform * SundialDial.needle_middle() if needle != null else _dial_top()


## The top of the sundial (the plate's middle, where the gnomon rises).
func _dial_top() -> Vector3:
	return home.dial.position + Vector3.UP * MapLandmarks.SUNDIAL_HEIGHT


## A view of `target` from [yaw deg, pitch deg, distance m].
static func _shot(target: Vector3, yaw: float, pitch: float, dist: float) -> Dictionary:
	return {"yaw": yaw, "pitch": pitch, "dist": dist, "target": target}


## Before the words: the three on the square (the scene ends there), the gnomon on the new land, the
## camera goes to it at the volcano.
func _dial_intro() -> void:
	page = -1
	home.trio_home()
	home.dial.show_plate()   # (every wedge is in its place by now)
	needle = SundialDial.needle_node()
	home.world.add_child(needle)
	needle.transform = _needle_land_xf()
	_move(_shot(_needle_point(), -35.0, -38.0, 8.0), 2.2)
	_beat(1.4, func() -> void: SoundBoard.play(&"glint"))
	_beat(2.4, func() -> void: _open_page(0))


## Page `i` of the sundial's finale: its camera and beats (the lines: content/story/hutton.json).
func _dial_page(i: int) -> void:
	var land_mid := home.map.new_land_point(0.55, 0.0) if home.map.new_land else _needle_point()
	match i:
		0:   # the fox: the gnomon came up
			_move(_shot(_needle_point(), -20.0, -34.0, 7.0), 2.0)
		1:   # Puppy: to the sundial
			_move(_shot(_needle_point(), -50.0, -40.0, 9.0), 1.8)
		2:   # Dugi: the lava made new land: over the new land
			_move(_shot(land_mid, -60.0, -38.0, 9.5), 3.0)
		3:   # the fox: volcanoes help the island grow: the grass sprouts, the camera turns to the square
			_beat(0.6, _sprout_grass)
			_move(_shot(land_mid.lerp(_dial_top(), 0.3), -40.0, -40.0, 12.0), 3.4)
		PLANT_PAGE:   # Dugi: plant the gnomon: the cat holds it over its paws
			needle.transform = _needle_held_xf()
			_held = true
			home.cat.cheer(true, 2)
			_move(_plant_shot(), 1.2)
		5:   # Puppy: a shadow!
			_move(_shot(_dial_top(), -15.0, -42.0, 4.2), 1.6)
		6:   # the fox: the sun is back, the time flows: the island's mission is complete (#118)
			_move(_shot(_dial_top(), 25.0, -30.0, 6.5), 2.4)
			_beat(0.3, _celebrate_island)
		7:   # the fox: thank you
			_move(_shot(_dial_top() + Vector3(0.0, 0.0, 0.6), 0.0, -24.0, 7.0), 2.0)
		8:   # Puppy: we'll come again: the square and the island round it
			_move(_shot(_dial_top() + Vector3(0.0, -0.4, 0.5), 10.0, -30.0, 11.0), 2.4)


## The view while the child plants the gnomon: the cat holding it, the dial behind.
func _plant_shot() -> Dictionary:
	return _shot(home.cat.position.lerp(_dial_top(), 0.5) + Vector3.UP * 0.3, -20.0, -28.0, 5.0)


## The words of a page of the sundial's finale closed: the dial glints before Dugi's "plant it", the
## child's drag after it, the end after the last.
func _dial_page_closed() -> void:
	if page == PLANT_PAGE - 1:
		_glint_dial()
	elif page == PLANT_PAGE:
		_wait_plant()
	elif page < Story.pages("finale").size() - 1:
		_open_page(page + 1)
	else:
		_end_cinematic()


## The camera to the dial the wedges filled; it glints (a short swell); then Dugi's "plant it" page.
func _glint_dial() -> void:
	_move(_shot(_dial_top(), -20.0, -38.0, 5.0), DIAL_GLINT_IN_S)
	_beat(DIAL_GLINT_IN_S, func() -> void:
		SoundBoard.play(&"glint")
		_glint_t = 0.0)
	_beat(DIAL_GLINT_IN_S + DIAL_GLINT_S + 0.2, func() -> void: _open_page(PLANT_PAGE))


func _step_dial_glint(delta: float) -> void:
	if _glint_t < 0.0 or home.dial == null:
		return
	_glint_t += delta
	var k := _glint_t / DIAL_GLINT_S
	home.dial.plate.scale = Vector3.ONE * (1.0 + DIAL_GLINT_SWELL * sin(PI * minf(k, 1.0)))
	if k >= 1.0:
		home.dial.plate.scale = Vector3.ONE
		_glint_t = -1.0


## The new land's grass sprouts (a short pop).
func _sprout_grass() -> void:
	if home.new_land_grass == null:
		return
	home.new_land_grass.visible = true
	home.new_land_grass.scale = Vector3.ONE * 0.01
	_grass_t = 0.0
	SoundBoard.play(&"glint")


func _step_grass(delta: float) -> void:
	if _grass_t < 0.0 or home.new_land_grass == null:
		return
	_grass_t += delta
	var k := clampf(_grass_t / GRASS_GROW_S, 0.0, 1.0)
	home.new_land_grass.scale = Vector3(1.0, maxf(0.01, k * k * (3.0 - 2.0 * k)), 1.0)
	if k >= 1.0:
		_grass_t = -1.0


## Waits for the child's drag (the paw shows it: from the gnomon over the paws into the dial).
func _wait_plant() -> void:
	plant_waits = true
	_plant = {}
	_held = true
	_needle_motion = {}
	_move(_plant_shot(), 0.8)
	if Quality.cmdline_value("demo-story").get_slice(":", 0) == "finale":   # (finale:<island> too)
		_beat(2.0, plant_needle)   # the screenshot run: it plants by itself
	if launch_guide == null:
		launch_guide = HandGuide.new()
		home.add_child(launch_guide)
	home.move_child(launch_guide, shield.get_index() + 1)   # over the shield (the paw takes no touch)
	_show_plant_guide()


func _show_plant_guide() -> void:
	var from := func() -> Vector2:
		var at := home._world_to_screen(_needle_point())
		return at if at != Vector2.INF else HandGuide.OFF_VIEW
	var to := func() -> Vector2:
		var at := home._world_to_screen(_dial_top())
		return at if at != Vector2.INF else HandGuide.OFF_VIEW
	launch_guide.play("drag", from, to, 3)


## How far a drag from `press` to `now` (screen) took the gnomon from the paws to the dial (0..1):
## along the screen line between them.
func plant_share(press: Vector2, now: Vector2) -> float:
	var a := home._world_to_screen(_needle_held_xf() * SundialDial.needle_middle())
	var b := home._world_to_screen(_dial_top())
	if a == Vector2.INF or b == Vector2.INF:
		return 0.0
	var dir := b - a
	if dir.length_squared() < 1.0:
		return 1.0
	return clampf((now - press).dot(dir) / dir.length_squared(), 0.0, 1.0)


## The finger while the finale waits for the plant: press anywhere, drag towards the dial (the
## gnomon follows along the way), let go far enough: it is planted; short: back to the paws.
func _plant_input(kind: String, position: Vector2) -> void:
	match kind:
		"press":
			_plant = {"press": position, "now": position}
			_needle_motion = {}
			if launch_guide != null:
				launch_guide.stop()
		"move":
			if not _plant.is_empty():
				_plant.now = position
		"release", "cancel":
			if _plant.is_empty():
				return
			var k := plant_share(_plant.press, _plant.now) if kind == "release" else 0.0
			_plant = {}
			if k >= (PLANT_SHARE_HELPED if helped() else PLANT_SHARE):
				plant_needle()
			else:
				if kind == "release":   # (a cancelled touch is not the child's miss)
					misses += 1
				_ease_needle(_needle_held_xf(), Callable())
				_show_plant_guide()


## The gnomon goes into the dial (the drag's end; tests call it too).
func plant_needle() -> void:
	if not plant_waits or needle == null:
		return
	plant_waits = false
	plants += 1
	_held = false
	_plant = {}
	if launch_guide != null:
		launch_guide.stop()
	_ease_needle(_needle_planted_xf(), _planted)


func _ease_needle(to: Transform3D, then: Callable) -> void:
	_needle_motion = {"from": needle.transform, "to": to, "t": 0.0, "s": NEEDLE_MOVE_S, "then": then}


## The gnomon is in: the sundial is whole; the sun comes back and its shadow grows; the emblem gets
## the gnomon and the face; then Puppy's "a shadow!".
func _planted() -> void:
	if needle != null:
		needle.queue_free()
		needle = null
	home.dial.show_whole(false)
	SoundBoard.play(&"land")
	home.cat.cheer(true, 3)
	_move(_shot(_dial_top(), -15.0, -42.0, 4.2), 1.4)
	_beat(0.3, func() -> void:
		SoundBoard.play(&"finale")
		_night(0.0, 2.6)
		_shadow_t = 0.0
		(emblem as SundialEmblem).set_whole(true)
		emblem.set_filled(emblem.total, true))   # (the pop)
	_beat(2.2, func() -> void: _open_page(PLANT_PAGE + 1))


func _step_needle(delta: float) -> void:
	if needle == null:
		return
	if not _plant.is_empty():
		needle.transform = _needle_between(plant_share(_plant.press, _plant.now))
	elif not _needle_motion.is_empty():
		_needle_motion.t += delta
		var k := clampf(float(_needle_motion.t) / float(_needle_motion.s), 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		needle.transform = _blend(_needle_motion.from, _needle_motion.to, e)
		if k >= 1.0:
			var then: Callable = _needle_motion.then
			_needle_motion = {}
			if then.is_valid():
				then.call()
	elif _held:
		needle.transform = _needle_held_xf()


func _step_shadow(delta: float) -> void:
	if _shadow_t < 0.0 or home.dial == null:
		return
	_shadow_t += delta
	home.dial.grow_shadow(_shadow_t / SHADOW_GROW_S)
	if _shadow_t >= SHADOW_GROW_S:
		_shadow_t = -1.0


## The sundial's finale is over (its end or 건너뛰기): its own nodes gone, the map in its end state.
func _end_dial() -> void:
	if needle != null:
		needle.queue_free()
		needle = null
	_glint_t = -1.0
	if home.dial != null:
		home.dial.plate.scale = Vector3.ONE
	plant_waits = false
	_plant = {}
	_held = false
	_needle_motion = {}
	_shadow_t = -1.0
	_grass_t = -1.0
	home.dial.show_whole()
	if home.new_land_grass != null:
		home.new_land_grass.visible = true
		home.new_land_grass.scale = Vector3.ONE
	(emblem as SundialEmblem).set_whole(true)
	sea.set_lanterns(true)   # (as the map opens after any finale)


# --- flights -----------------------------------------------------------------------------------

## Starts the next found piece's flight (after the flag raises): the camera frames the spot and the
## lookout, the piece arcs over, the emblem fills a wedge. The store says "flown" at once (it never
## replays). After the last one, the finale when all are found (advance).
func _next_flight() -> void:
	if not _flight_queue.is_empty():
		var id: String = _flight_queue.pop_front()
		ProgressStore.set_mark(ProgressStore.PIECES, id, true)
		if id == home.island.gnomon_spot():
			# The gnomon (#106) never flies: it stands on the new land until the finale.
			placed_count += 1
			emblem.set_filled(placed_count)
			_night(map_night(), 1.2)
			# The next flight or the finale in this same frame: the map takes no tap in between.
			if not _flight_queue.is_empty():
				_next_flight()
			elif _finale_due:
				_finale_due = false
				play_finale()
			return
		var spot: Dictionary = {}
		for s in home._spots:
			if s.id == id:
				spot = s
		if spot.is_empty():
			return
		part = "flight"
		var from: Vector3 = spot.at + Vector3.UP * (float(spot.top) + 0.6)
		var to := _lookout_point()
		var slot := Transform3D()
		if _sundial():   # to its own sector of the dial (#114)
			slot = home.dial.transform * SundialDial.slot_transform(home.dial.filled)
			to = slot.origin
		var node := PieceArt.make(home.island.piece, PIECE_SIZE)
		home.world.add_child(node)
		node.position = from
		_flight = {"id": id, "node": node, "from": from, "to": to, "slot": slot, "spin": 0.0, "t": -FLIGHT_IN_S}
		var box := AABB(from, Vector3.ZERO).expand(to).expand(spot.at).grow(1.5)
		home.view.rig.focus({"box": box, "fill": 0.55, "anchor": Vector2(0.5, 0.55),
			"in_s": FLIGHT_IN_S, "hold_s": FLIGHT_S + 0.2, "out_s": FLIGHT_OUT_S})
		flights_played += 1
		SoundBoard.play(&"glint")


func _step_flight(delta: float) -> void:
	if _flight.is_empty():
		if part == "flight" and not home.view.rig.is_framing():
			part = ""
			ended.emit("flight")
		return
	var before: float = _flight.t
	_flight.t += delta
	if before < 0.0 and _flight.t >= 0.0:
		SoundBoard.play(&"piece_fly")
	var k := clampf(_flight.t / FLIGHT_S, 0.0, 1.0)
	var node: Node3D = _flight.node
	node.position = _arc(_flight.from, _flight.to, 4.0, k * k * (3.0 - 2.0 * k))
	if not _sundial():
		node.rotation.y += delta * 6.0
	else:   # it turns and shrinks into its sector over the last part of the way
		_flight.spin += delta * 6.0
		var spin := Transform3D(Basis(Vector3.UP, _flight.spin).scaled(Vector3.ONE * PIECE_SIZE), node.position)
		var slot: Transform3D = _flight.slot
		var settle := _blend(spin, slot, smoothstep(0.65, 1.0, k))
		node.transform = Transform3D(settle.basis.scaled(Vector3.ONE / PIECE_SIZE), node.position)
	if k >= 1.0:
		node.queue_free()
		_flight = {}
		placed_count += 1
		if _sundial():
			home.dial.show_filled(home.dial.filled + 1)
		emblem.set_filled(placed_count, true)
		_night(map_night(), 1.2)   # the night lifts a step
		SoundBoard.play(&"glint")


## Ends every flight now (a tap): the pieces at the lookout, the camera the child's at once.
func skip_flights() -> void:
	var any := not _flight.is_empty() or not _flight_queue.is_empty()
	for id in _flight_queue:
		ProgressStore.set_mark(ProgressStore.PIECES, id, true)
	_flight_queue.clear()
	if not _flight.is_empty():
		(_flight.node as Node3D).queue_free()
		_flight = {}
	if any or part == "flight":
		placed_count = Story.placed(ProgressStore.load()).size()
		emblem.set_filled(placed_count)
		if _sundial() and not home.dial.whole:
			home.dial.show_filled(home.placed_wedges(ProgressStore.load()))
		_night_s = 0.0
		_set_night(map_night())
		home.view.rig.cut_focus()
		part = ""


# --- the frame ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	advance(minf(delta, 0.05))


## Moves the story on by `delta` s (tests step it).
func advance(delta: float) -> void:
	_clock += delta
	if part == "flight":
		_step_flight(delta)
	if part == "" and not home.raising():
		if not _flight_queue.is_empty():
			_next_flight()
		elif _finale_due:
			_finale_due = false
			play_finale()
		elif _riddle_due and not home._walking:
			say_riddle()
	_step_hint(delta)
	_step_spot_glow(delta)
	_step_map_guide()
	for b in _beats.duplicate():
		b[0] -= delta
		if b[0] <= 0.0:
			_beats.erase(b)
			(b[1] as Callable).call()
	_step_night(delta)
	_step_star(delta)
	_step_launch(delta)
	_step_needle(delta)
	_step_dial_glint(delta)
	_step_shadow(delta)
	_step_grass(delta)
	_step_pieces(delta)
	_step_cat(delta)
	_step_boats(delta)
	_step_sparkles(delta)
	if _driving:
		_step_camera(delta)
	if sky_star != null:
		_sky_t += delta
		StarArt.face_camera(sky_star, home.view.rig, _sky_t)


# --- cinematic plumbing -------------------------------------------------------------------------

## A prologue or the finale starts: the director takes the camera and the screen.
func _begin(which: String) -> void:
	skip_flights()
	if riddle != null and riddle.active:
		riddle.close(true)
	_hide_hint()
	part = which
	_returning = false
	_beats.clear()
	var rig := home.view.rig
	rig.cut_focus()
	rig.set_process(false)
	_driving = true
	_cam_t = 0.0
	_cam_s = 0.0
	_cam_from = _pose_now()
	_cam_to = _cam_from
	home.set_cinematic(true)
	emblem.visible = which == "finale"
	if dialogue == null:
		shield = Control.new()
		shield.name = "StoryShield"
		shield.mouse_filter = Control.MOUSE_FILTER_STOP
		shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shield.gui_input.connect(_on_shield_input)
		home.add_child(shield)
		dialogue = DialogueBox.new("")
		home.add_child(dialogue)
		dialogue.closed.connect(_on_dialogue_closed)
		skip_button = Ui.button(Locale.t("story.skip"), "", 56)
		skip_button.name = "SkipButton"
		skip_button.pressed.connect(skip)
		home.add_child(skip_button)
	shield.visible = true
	skip_button.visible = true
	_layout()


## The last page is over: the camera eases back to the child's view, then everything is the map's
## again.
func _end_cinematic() -> void:
	if _returning:
		return
	_returning = true
	if dialogue.active:
		dialogue.close(true)
	dialogue.visible = false
	_move(_child_pose(), RETURN_S)
	_beat(RETURN_S, _finish)


## Skips the prologue or the finale now: its end state at once (day, the map clean, the child's
## camera exactly).
func skip() -> void:
	if not cinematic():
		return
	_beats.clear()
	_finish()


func _finish() -> void:
	var which := part
	_beats.clear()
	_returning = false
	if dialogue != null:
		if dialogue.active:
			dialogue.close(true)
		dialogue.visible = false
		shield.visible = false
		skip_button.visible = false
	if which == "finale":
		Story.mark_seen("finale")   # at its end or 건너뛰기 (#108: left half way, it plays again)
		_finale_done = true
	_after = -1
	if ribbon != null:
		ribbon.queue_free()
		ribbon = null
	_night_s = 0.0
	_set_night(map_night())   # prologue: the map's night; finale: day
	_riddle_due = next_id != ""   # then Puppy's riddle for the next spot
	_hint_t = 0.0
	_clear_pieces()
	if _star != null:
		_star.queue_free()
		_star = null
	_star_motion = {}
	_lift = false
	launch_waits = false
	_launch = {}
	_pull = {}
	_retry_open = false
	for node: Node in [_pull_dots, _aim_dots, launch_guide]:
		if node != null:
			node.queue_free()   # (the map stays clean: only the sky star is left)
	_pull_dots = null
	_aim_dots = null
	launch_guide = null
	for s in _sparkles:
		(s[0] as Node3D).queue_free()
	_sparkles.clear()
	_boats_wander = false
	_boats_sail = -1.0
	sea.rest_boats()
	_cat_hop = {}
	home.reset_trio()
	if which == "prologue":
		Story.mark_seen("prologue")
		sea.set_lanterns(Story.finale_seen())
	elif _sundial():
		_end_dial()   # the sundial whole, the grass, the emblem's gnomon and face; no star (#106)
	else:
		sea.set_lanterns(true)
		_place_sky_star()
	var rig := home.view.rig
	_driving = false
	rig.set_process(true)
	rig.snap()   # exactly the child's view (its goal was never touched)
	part = ""
	page = -1
	emblem.visible = true
	home.set_cinematic(false)
	_layout()   # the map buttons are back: the emblem goes under ←
	home.nudge_back(home.next_island_waits())   # (#118: a new island opened, ← leads to it)
	ended.emit(which)


## A tap anywhere but the box and 건너뛰기: the same as a tap on the box (the whole page, the next).
func _on_shield_input(event: InputEvent) -> void:
	if (launch_waits or plant_waits) and not (dialogue != null and dialogue.active):
		_launch_event(event)
		shield.accept_event()
		return
	var tap: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
			and event.device != InputEvent.DEVICE_ID_EMULATION)   # a touch's emulated click: one tap, one page
	if tap:
		tap_page()
		shield.accept_event()


## A pointer event on the shield while the finale waits for the pull (or the sundial's plant, #106: a
## touch, or the mouse that is not a touch's emulated click): press / move / release for _launch_input
## (_plant_input).
func _launch_event(event: InputEvent) -> void:
	var input := _plant_input if plant_waits else _launch_input
	if event is InputEventScreenTouch:
		if event.index == 0:
			input.call("press" if event.pressed else ("cancel" if event.canceled else "release"), event.position)
		elif event.pressed:
			input.call("cancel", event.position)   # a second finger: no throw
	elif event is InputEventScreenDrag:
		if event.index == 0:
			input.call("move", event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		input.call("press" if event.pressed else "release", event.position)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		input.call("move", event.position)


func tap_page() -> void:
	if dialogue != null and dialogue.active:
		dialogue.advance()


func _layout() -> void:
	var view_size := home.view.size if home.view != null else home.size
	if emblem != null:
		# Top left (2026-10-30 user), under the map's ← (#114; 2026-11-11 user: "돌아가기 아래로 두자");
		# the finale's 건너뛰기 is top right.
		emblem.position = home.emblem_at()
	if skip_button != null:
		skip_button.size = skip_button.get_combined_minimum_size()
		skip_button.position = Vector2(view_size.x - skip_button.size.x - DIALOGUE_MARGIN, DIALOGUE_MARGIN)
	var right := view_size.x - DIALOGUE_MARGIN   # the whole width (2026-10-29 user)
	if dialogue != null and dialogue.active:
		dialogue.set_card_avoid([emblem, skip_button])   # the explanation picture's card keeps clear of them
		dialogue.visible = dialogue.layout(Rect2(Vector2.ZERO, view_size), right, DIALOGUE_MARGIN)
	if riddle != null and riddle.active:
		riddle.visible = riddle.layout(Rect2(Vector2.ZERO, view_size), right, DIALOGUE_MARGIN)


# --- camera ------------------------------------------------------------------------------------

func _pose_now() -> Dictionary:
	var rig := home.view.rig
	return {"yaw": rad_to_deg(rig.cur_yaw), "pitch": rad_to_deg(rig.cur_pitch), "dist": rig.cur_distance, "target": rig.cur_target}


## The child's own view (the rig's goal: never changed by the story).
func _child_pose() -> Dictionary:
	var rig := home.view.rig
	return {"yaw": rad_to_deg(rig.goal_yaw), "pitch": rad_to_deg(rig.goal_pitch), "dist": rig.goal_distance, "target": rig._view_goal_target()}


func _set_camera(shot: Dictionary) -> void:
	_cam_from = shot.duplicate()
	_cam_to = shot.duplicate()
	_cam_t = 0.0
	_cam_s = 0.0
	_draw_camera(shot)


## Eases from the drawn view to `shot` over `seconds` (smoothstep). A sweep turns the long way the
## yaw says; any other move turns the short way.
func _move(shot: Dictionary, seconds: float, sweep := false) -> void:
	_cam_from = _pose_now()
	_cam_to = shot.duplicate()
	if not sweep:
		_cam_to.yaw = _cam_from.yaw + wrapf(float(shot.yaw) - float(_cam_from.yaw), -180.0, 180.0)
	_cam_t = 0.0
	_cam_s = maxf(seconds, 0.01)


func _step_camera(delta: float) -> void:
	if _cam_s <= 0.0:
		return
	_cam_t = minf(_cam_t + delta, _cam_s)
	var k := _cam_t / _cam_s
	k = k * k * (3.0 - 2.0 * k)
	_draw_camera({"yaw": lerpf(_cam_from.yaw, _cam_to.yaw, k), "pitch": lerpf(_cam_from.pitch, _cam_to.pitch, k),
		"dist": lerpf(_cam_from.dist, _cam_to.dist, k), "target": (_cam_from.target as Vector3).lerp(_cam_to.target, k)})


func _draw_camera(pose: Dictionary) -> void:
	var rig := home.view.rig
	rig.cur_yaw = deg_to_rad(float(pose.yaw))
	rig.cur_pitch = deg_to_rad(float(pose.pitch))
	rig.cur_distance = float(pose.dist)
	rig.cur_target = pose.target
	rig._apply()


func _beat(after: float, what: Callable) -> void:
	_beats.append([after, what])


# --- night -------------------------------------------------------------------------------------

func _night(to: float, seconds: float) -> void:
	_night_from = night
	_night_to = to
	_night_t = 0.0
	_night_s = seconds


func _step_night(delta: float) -> void:
	if _night_s <= 0.0:
		return
	_night_t = minf(_night_t + delta, _night_s)
	var k := _night_t / _night_s
	_set_night(lerpf(_night_from, _night_to, k * k * (3.0 - 2.0 * k)))
	if _night_t >= _night_s:
		_night_s = 0.0


## The night level: the shaders' global tint and the sea (the clear colour).
func _set_night(level: float) -> void:
	night = level
	var sea_color: Color
	if level <= 1.0:
		tint = Vector3.ONE.lerp(NIGHT_TINT, level)
		sea_color = _day_sea.lerp(NIGHT_SEA, level)
	else:
		tint = NIGHT_TINT.lerp(DARK_TINT, level - 1.0)
		sea_color = NIGHT_SEA.lerp(DARK_SEA, level - 1.0)
	if _can_tint:
		RenderingServer.global_shader_parameter_set(&"story_tint", tint)
	var sky := Vector3.ONE.lerp(NIGHT_SKY, minf(level, 1.0)) if level <= 1.0 else NIGHT_SKY.lerp(DARK_SKY, level - 1.0)
	MapIsland.sky_material().set_shader_parameter("own_tint", sky)
	if home != null and home.env != null and _day_sea != Color.BLACK:
		home.env.environment.background_color = sea_color


# --- the star, its pieces, the sparkles ----------------------------------------------------------

func _show_star() -> void:
	_star = StarArt.make(false, STAR_SIZE)
	_star.position = STAR_AT
	_star.scale = Vector3.ONE * 0.01
	home.world.add_child(_star)
	_star_motion = {"pop": 0.0}
	SoundBoard.play(&"glint")


func _shake_star(seconds: float) -> void:
	if _star != null:
		_star_motion = {"shake": 0.0, "s": seconds}


## The star cracks: it is gone, one piece per spot arcs down to the spot (staggered).
func _break_star() -> void:
	var from := STAR_AT
	if _star != null:
		from = _star.position
		_star.queue_free()
		_star = null
	_star_motion = {}
	SoundBoard.play(&"star_break")
	var i := 0
	for spot in home._spots:
		var to: Vector3 = spot.at + Vector3.UP * (float(spot.top) + 0.6)
		var ctrl := Vector3(to.x * 1.3, from.y + 3.0, to.z * 1.3).lerp(from, 0.3)
		_add_piece(from, ctrl, to, 1.7 + 0.08 * i, -0.06 * i)
		i += 1


func _add_piece(from: Vector3, ctrl: Vector3, to: Vector3, seconds: float, start: float) -> void:
	var node := PieceArt.make(home.island.piece, PIECE_SIZE)
	node.position = from
	node.visible = start >= 0.0
	home.world.add_child(node)
	_pieces.append({"node": node, "from": from, "ctrl": ctrl, "to": to, "t": start, "s": seconds, "spin": 3.0 + randf() * 2.0,
		"landed": false})


func _step_pieces(delta: float) -> void:
	for p in _pieces:
		var node: Node3D = p.node
		p.t += delta
		node.visible = p.t >= 0.0 and not p.get("gone", false)
		var k := clampf(p.t / p.s, 0.0, 1.0)
		var eased: float = k * k if p.get("fall", true) else k * k * (3.0 - 2.0 * k)
		var a: Vector3 = (p.from as Vector3).lerp(p.ctrl, eased)
		var b: Vector3 = (p.ctrl as Vector3).lerp(p.to, eased)
		node.position = a.lerp(b, eased)
		node.rotation.y += delta * float(p.spin)
		if k >= 1.0:
			if not p.landed:
				p.landed = true
				SoundBoard.play(&"glint")
			# Glint where it landed: a gentle pulse.
			var pulse := 1.0 + 0.18 * sin(_clock * 6.0 + float(p.spin))
			node.scale = Vector3.ONE * pulse * float(p.get("fade", 1.0))


## The prologue's pieces shrink away as the day comes back (the map is clean after the story).
func _fade_pieces() -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		for p in _pieces:
			p["fade"] = v, 1.0, 0.0, 1.0)


func _clear_pieces() -> void:
	for p in _pieces:
		(p.node as Node3D).queue_free()
	_pieces.clear()


## The finale: the 11 pieces appear round the lookout and spiral into the whole star.
func _gather_pieces() -> void:
	var at := _lookout_point()
	var n := Story.spots().size()
	for i in n:
		var a := TAU * i / n
		var from := at + Vector3(cos(a) * 2.6, sin(a * 2.0) * 0.4, sin(a) * 2.6)
		var ctrl := at + Vector3(cos(a + 1.2) * 1.6, 0.6, sin(a + 1.2) * 1.6)
		_add_piece(from, ctrl, at, 1.8, -0.04 * i)
		_pieces[-1]["fall"] = false
	SoundBoard.play(&"piece_fly")
	_beat(2.3, func() -> void:
		_clear_pieces()
		_star = StarArt.make(false, 1.0)
		_star.position = at
		_star.scale = Vector3.ONE * 0.01
		home.world.add_child(_star)
		_star_motion = {"pop": 0.0}
		SoundBoard.play(&"glint"))


func _move_star(to: Vector3, seconds: float) -> void:
	if _star != null:
		_star_motion = {"from": _star.position, "to": to, "t": 0.0, "s": seconds, "from_scale": _star.scale.x,
			"to_scale": SKY_STAR_SIZE if to == SKY_STAR_AT else _star.scale.x}


func _step_star(delta: float) -> void:
	if _star == null:
		return
	_star_t += delta
	StarArt.face_camera(_star, home.view.rig, _star_t)
	if _lift and _pull.is_empty() and home.cat != null:
		_star.position = _star.position.lerp(_paws_top(), 1.0 - exp(-8.0 * delta))
	if _star_motion.has("pop"):
		_star_motion.pop += delta
		var k := clampf(float(_star_motion.pop) / 0.5, 0.0, 1.0)
		_star.scale = Vector3.ONE * maxf(0.01, 1.0 + 0.3 * sin(PI * k) - (1.0 - k) * (1.0 - k))
		if k >= 1.0:
			_star.scale = Vector3.ONE
			_star_motion = {}
	elif _star_motion.has("shake"):
		_star_motion.shake += delta
		_star.rotation.z = sin(float(_star_motion.shake) * 60.0) * 0.12
	elif _star_motion.has("to"):
		_star_motion.t += delta
		var k := clampf(float(_star_motion.t) / float(_star_motion.s), 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		_star.position = (_star_motion.from as Vector3).lerp(_star_motion.to, e)
		_star.scale = Vector3.ONE * lerpf(_star_motion.from_scale, _star_motion.to_scale, e)
		if k >= 1.0:
			_star_motion = {}


## The star in the map's sky after the finale (it stays: small, bright, turning slowly).
func _place_sky_star() -> void:
	if sky_star == null:
		sky_star = StarArt.make(false, 1.0)
		sky_star.name = "SkyStar"
		home.world.add_child(sky_star)
	sky_star.position = SKY_STAR_AT
	sky_star.scale = Vector3.ONE * SKY_STAR_SIZE


## The sea sparkles again: little stars twinkle on the water round the island for a few seconds.
func _sparkle_sea() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 26:
		var a := rng.randf() * TAU
		var r := rng.randf_range(15.0, 34.0)
		var node := StarArt.make(false, 0.32)
		node.position = Vector3(cos(a) * r, MapIsland.SEA_Y + 0.35, sin(a) * r)
		node.scale = Vector3.ONE * 0.01
		home.world.add_child(node)
		_sparkles.append([node, rng.randf() * TAU, 0.0])


func _step_sparkles(delta: float) -> void:
	for s in _sparkles:
		s[2] += delta
		var life := clampf((5.0 - float(s[2])) / 1.0, 0.0, 1.0)
		var twinkle := 0.5 + 0.5 * sin(float(s[2]) * 7.0 + float(s[1]))
		(s[0] as Node3D).scale = Vector3.ONE * maxf(0.01, twinkle * life * minf(1.0, float(s[2]) * 3.0))


# --- the cat and the boats -----------------------------------------------------------------------

func _hop_cat(from: Vector3, to: Vector3, seconds: float, height: float) -> void:
	_cat_hop = {"from": from, "to": to, "t": 0.0, "s": seconds, "h": height}
	if from.distance_to(to) > 0.05:
		home.cat.rotation.y = atan2(to.x - from.x, to.z - from.z)


func _step_cat(delta: float) -> void:
	if _cat_hop.is_empty():
		return
	_cat_hop.t += delta
	var k := clampf(float(_cat_hop.t) / float(_cat_hop.s), 0.0, 1.0)
	var p := (_cat_hop.from as Vector3).lerp(_cat_hop.to, k)
	p.y = lerpf((_cat_hop.from as Vector3).y, (_cat_hop.to as Vector3).y, k) + float(_cat_hop.h) * sin(PI * k)
	home.cat.position = p
	if k >= 1.0:
		home.cat.rotation.y = 0.0
		_cat_hop = {}


func _step_boats(delta: float) -> void:
	if _boats_wander:
		for i in sea.boats.size():
			var t := _clock * 0.45 + i * 2.1
			var home_at: Vector3 = sea.boat_homes[i]
			sea.boats[i].position = home_at + Vector3(sin(t) * 3.0, 0.0, cos(t * 0.8) * 3.0)
			sea.boats[i].rotation.y = t + PI * 0.5
	elif _boats_sail >= 0.0:
		_boats_sail += delta
		for i in sea.boats.size():
			var boat := sea.boats[i]
			boat.position += boat.global_basis.z * delta * 2.5


## A point on an arc from `from` to `to` at k (0..1), `height` m above the straight line at its middle.
static func _arc(from: Vector3, to: Vector3, height: float, k: float) -> Vector3:
	return from.lerp(to, k) + Vector3.UP * height * 4.0 * k * (1.0 - k)
