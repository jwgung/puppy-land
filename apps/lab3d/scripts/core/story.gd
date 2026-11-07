## The story "별 조각 찾기" (2026-10-28 user-approved): 과학섬 is one island of the sea country 퍼피랜드.
## Its guiding star (길잡이 별) lights the night sea for the boats; it breaks and 11 pieces fall, one
## at each lab spot. A spot's round completed (all its stamps) is its piece found; the pieces fly to
## the lookout (전망대) on the map and, all 11 there, the star goes back to the sky.
##
## Roles (fixed): 퍼피 the detective finds clues (what, where), 두기두기 the scientist gives the reason
## (why), the bread cat acts and never speaks. The story is pictures and words only: it never sets a
## control, runs an action or reads a body (the labs' physics, missions, controls and numbers are
## the same with or without it).
##
## This is the story's data and saved state: the words (the island's content/story/<island>.json with
## its words in content/locale/<lang>/story/<island>.json, each lab's story.clue),
## the marks in the ProgressStore (prologue / finale played, clue told, piece flown) and whether the
## story runs at all (`enabled`: App turns it on for the child's app, never for a measurement or a
## test that does not ask for it). The map's StoryDirector and the lab screen play it.
class_name Story
extends RefCounted

## The island's story (#69): content/story/<island>.json, its words content/locale/<lang>/story/<island>.json.
const CONTENT_ROOT := "res://content/story"
## Who speaks: [the name tag's Locale key, portrait path pattern (%s = the face)] (DialogueBox.set_speaker).
const SPEAKERS := {
	"dugi": ["speaker.dugi", "res://assets/characters/portraits/dugi_%s.webp"],
	"puppy": ["speaker.puppy", "res://assets/characters/portraits/puppy_%s.webp"],
	# The second island's keeper (#71, 2026-11-06 look chosen by the user), named 여우친구 / "Fox Friend"
	# by the user on 2026-11-06 (its tag: ui.json speaker.fox).
	"fox": ["speaker.fox", "res://assets/characters/portraits/fox_%s.webp"],
}
## The island keeper who speaks a spot's first line on Hutton Island (#74: story.keeper, before Puppy's
## clue). Its name tag is the speaker's (ui.json speaker.fox), never written here.
const KEEPER := "fox"
## The portraits' expressions (2026-10-29 user request "대화시 표정을 좀 더 다양하게"), one picture per
## speaker and face (art_src/characters/*_portrait.py). Each line of the content may name its face
## (`face`, `say_face`, `clue_face`, `map_clue_face`, `question_face`, `map_wrong_face`); an untagged
## line shows DEFAULT_FACE. Dugi's lines may also carry an explanation picture next to the
## face (`picture`, `say_picture`, `intro_picture`, `reason_picture`, `bridge_picture`:
## ExplainPictures). explain = Dugi's pointing stick / Puppy's raised paw (telling).
const FACES := ["explain", "happy", "surprised", "thinking", "worried"]
const DEFAULT_FACE := "explain"
## Dugi's face for the prediction's reason (told after the first run): a right guess is a happy
## reason, a wrong one a thinking one (nothing is a failure).
const REASON_FACE := {true: "happy", false: "thinking"}


## The face of a tagged line: `face` when it is one of FACES, else DEFAULT_FACE.
static func face_or_default(face: Variant) -> String:
	return str(face) if face is String and face in FACES else DEFAULT_FACE


## The portrait of `who` with `face` (an unknown face: the default).
## Puppy's portraits show his flag's word: the English ones are in portraits/en (2026-11-02).
static func portrait_path(who: String, face: String) -> String:
	var path := str(SPEAKERS[who][1]) % face_or_default(face)
	if who == "puppy" and Locale.lang == "en":
		path = path.get_base_dir().path_join("en").path_join(path.get_file())
	return path

## The story plays (App: the child's app; off for measurements, screenshots without --demo-story
## and tests that build screens directly).
static var enabled := false
## App may turn the story on (false: the headless tests' App instances never do; story_checks sets
## `enabled` itself).
static var app_may_enable := true
static var _content: Dictionary = {}
## The island whose story `_content` is.
static var _content_island := ""


## The story's pages: "prologue", "finale" or "voyage" -> [{who, face, text, picture, shot}, ...]
## (face optional; picture optional: an ExplainPictures kind on one of Dugi's pages, #73; shot: a
## voyage page's camera, VOYAGE_SHOTS).
static func pages(part: String) -> Array:
	return _load().get(part, [])


## The pages of `island`'s story (the island in use: pages(); another: its file read now).
static func pages_of(island: String, part: String) -> Array:
	if island == Island.current_id():
		return pages(part)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(content_path(island))) if FileAccess.file_exists(content_path(island)) else null
	parsed = Locale.overlay(parsed, Locale.words("story/%s.json" % island)) if parsed is Dictionary else null
	return parsed.get(part, []) if parsed is Dictionary else []


# --- the voyage to the next island (#75, 2026-11-06 user-approved: a short 3D scene on a boat) -----
# An island's story file may hold a "voyage": the trip by boat from the island before it, played once
# (VoyageScreen) when that island's finale was seen and this one opened, before this island's own
# prologue on its map; 이야기 다시 보기 on this island plays it again (then the prologue). The island
# picker (섬 고르기, TitleScreen) shows once a voyage was seen.

## A voyage page's camera and the boat's place on the way (VoyageScreen).
const VOYAGE_SHOTS := ["depart", "sea", "flicker", "arrive"]


## The island `island` has a voyage to it (its story's voyage pages).
static func has_voyage(island: String) -> bool:
	return not pages_of(island, "voyage").is_empty()


static func voyage_seen(island: String) -> bool:
	return ProgressStore.mark(ProgressStore.STORY, ProgressStore.island_key(island, "voyage"))


static func mark_voyage_seen(island: String) -> void:
	ProgressStore.set_mark(ProgressStore.STORY, ProgressStore.island_key(island, "voyage"), true)


## The island the trio sails to now ("" for none): the island after the one in use, once it is open
## (Island.is_open) and the finale of the one in use was seen, while its voyage was never played.
static func voyage_due(progress: Dictionary) -> String:
	if not enabled or not finale_seen():
		return ""
	var from := Island.current_id()
	for id in Island.ids():
		if Island.opens_after(id) == from and Island.is_open(id, progress) and not voyage_seen(id) and has_voyage(id):
			return id
	return ""


## Some voyage was played: the title shows 섬 고르기 (#75: the picker comes after the first voyage).
static func any_voyage_seen() -> bool:
	return Island.ids().any(func(id: String) -> bool: return voyage_seen(id))


## The explanation picture a story page shows: its `picture` on Dugi's page, "" on anyone else's
## (Puppy and the island keepers never explain science; Story.validate rejects such a page too).
static func page_picture(entry: Dictionary) -> String:
	return ExplainPictures.picture_or_none(entry.get("picture")) if str(entry.get("who", "dugi")) == "dugi" else ""


## The problems of a story file's pages (`content`: the island's story, Story pages): every `who`
## a speaker, every `face` one of FACES, every `picture` one of ExplainPictures.KINDS and only on
## Dugi's pages (Puppy and the island keepers never explain science). Empty = valid.
static func validate(content: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for part in ["prologue", "finale", "voyage"]:
		var entries: Variant = content.get(part, [])
		if not entries is Array:
			problems.append("%s must list pages" % part)
			continue
		for i in entries.size():
			var entry: Variant = entries[i]
			if not entry is Dictionary:
				problems.append("%s[%d] must be an object" % [part, i])
				continue
			var who := str(entry.get("who", "dugi"))
			if not SPEAKERS.has(who):
				problems.append("%s[%d].who must be one of Story.SPEAKERS" % [part, i])
			if entry.has("face") and not entry.face in FACES:
				problems.append("%s[%d].face must be one of Story.FACES" % [part, i])
			if part == "voyage" and not entry.get("shot") in VOYAGE_SHOTS:
				problems.append("%s[%d].shot must be one of Story.VOYAGE_SHOTS" % [part, i])
			var bad := ExplainPictures.check(entry, "picture", "%s[%d].picture" % [part, i])
			problems.append_array(bad)
			if entry.has("picture") and bad.is_empty() and who != "dugi":
				problems.append("%s[%d].picture is Dugi's only (the page is %s's)" % [part, i, who])
	return problems


## The story is read again on the next use (Locale.set_language: its words changed).
## (Not "reload": that is Script.reload, which recompiles the script and resets enabled and
## app_may_enable: a language picked in the settings switched the story off, 2026-11-02.)
static func forget_loaded() -> void:
	_content = {}
	_content_island = ""


## The story file of `island`.
static func content_path(island: String) -> String:
	return CONTENT_ROOT.path_join("%s.json" % island)


static func _load() -> Dictionary:
	var island := Island.current_id()
	if _content.is_empty() or _content_island != island:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(content_path(island)))
		parsed = Locale.overlay(parsed, Locale.words("story/%s.json" % island)) if parsed is Dictionary else null
		_content = parsed if parsed is Dictionary else {}
		_content_island = island
		var problems := validate(_content)
		if not problems.is_empty():
			push_error("Story: %s is invalid: %s" % [content_path(island), "; ".join(problems)])
	return _content


## The map plays the prologue when it opens: the story is on and it was never played, or the child
## asked for it again (`replay`, settings 이야기 다시 보기).
static func should_play_prologue(replay := false) -> bool:
	return enabled and (replay or not prologue_seen())


## Puppy's clue for a lab ("" when it has none).
static func clue(definition: Dictionary) -> String:
	return _story_text(definition, "clue")


## The island keeper's line on the spot's first visit, before Puppy's clue ("" when it has none: the
## mechanics island has no keeper). #74: the fox tells what is wrong at the spot.
static func keeper(definition: Dictionary) -> String:
	return _story_text(definition, "keeper")


static func keeper_face(definition: Dictionary) -> String:
	return face_or_default(_story_text(definition, "keeper_face"))


## The keeper's answer after Puppy's clue on the first visit ("" when it has none). #86: the fox tells
## how the piece's lid opens.
static func keeper_reply(definition: Dictionary) -> String:
	return _story_text(definition, "keeper_reply")


static func keeper_reply_face(definition: Dictionary) -> String:
	return face_or_default(_story_text(definition, "keeper_reply_face"))


## More first-visit lines after Puppy's clue (#98: the volcano's talk, Puppy and the keeper in turn):
## [{"speaker": Story.SPEAKERS key, "face", "text"}], [] when it has none.
static func more(definition: Dictionary) -> Array:
	var story: Variant = definition.get("story")
	var lines: Variant = story.get("more", []) if story is Dictionary else []
	var out := []
	for line: Variant in (lines if lines is Array else []):
		if line is Dictionary and str(line.get("text", "")) != "" and SPEAKERS.has(str(line.get("speaker", ""))):
			out.append({"speaker": str(line.speaker), "face": face_or_default(line.get("face")), "text": str(line.text)})
	return out


## Puppy's riddle on the night map while this spot is the next to find ("" when it has none).
static func map_clue(definition: Dictionary) -> String:
	return _story_text(definition, "map_clue")


## The faces of the clue and the riddle (`story.clue_face`, `story.map_clue_face`).
static func clue_face(definition: Dictionary) -> String:
	return face_or_default(_story_text(definition, "clue_face"))


static func map_clue_face(definition: Dictionary) -> String:
	return face_or_default(_story_text(definition, "map_clue_face"))


static func _story_text(definition: Dictionary, key: String) -> String:
	var story: Variant = definition.get("story")
	return str(story.get(key, "")) if story is Dictionary else ""


# --- the night map's exploration (2026-10-28 user-approved: explore the night map in a fixed order) --
# The spots are found one by one in a fixed order (the island's `order`, Island). Only the next spot
# (the first in the order whose piece is not found) and the found spots open; Puppy says the next
# one's riddle on the map. Nothing new is saved: all of it follows from the found pieces (stamps), so
# an old save (some spots complete, out of order) works: its found spots are open and lit, the next is
# the first unfound one in the order.

## The fixed order the spots are found in (the island's `order`: every spot once).
static func order() -> Array:
	return Island.current().order


## The next spot to find: the first in the order whose piece is not found ("" when all are found).
static func next_spot(progress: Dictionary) -> String:
	var done := found(progress)
	for id in order():
		if id not in done:
			return id
	return ""


## The spot opens from the map: its piece is found, or it is the next one.
static func enterable(progress: Dictionary, id: String) -> bool:
	return id in found(progress) or id == next_spot(progress)


## Puppy's line when a locked spot is tapped.
static func wrong_line() -> String:
	return str(_load().get("map_wrong", ""))


static func wrong_face() -> String:
	return face_or_default(_load().get("map_wrong_face"))


## Dugi's line when the finale's star came back down (2026-11-01: pull harder).
static func finale_retry_line() -> String:
	return str(_load().get("finale_retry", ""))


static func finale_retry_face() -> String:
	return face_or_default(_load().get("finale_retry_face"))


# --- who says what (2026-10-29 user: Puppy never explains science, that is Dugi's job) -----------
## Words that explain science (why / how fast / which force). Puppy's lines (clues, riddles, the
## wrong-spot line, his story pages) never use them; Dugi's are exempt. A content test reads them.
## They are the language's (ui.json story.science_words).
static func science_words() -> Array:
	return Locale.list("story.science_words")


## Every line Puppy says: his story pages, every lab's clue and riddle, the wrong-spot line.
static func puppy_lines() -> Array:
	var out := []
	for part in ["prologue", "finale", "voyage"]:
		for entry in pages(part):
			if str(entry.get("who", "")) == "puppy":
				out.append(str(entry.get("text", "")))
	for definition in ExperimentRegistry.load_all():
		for key in ["clue", "map_clue"]:
			var line := _story_text(definition, key)
			if line != "":
				out.append(line)
	out.append(wrong_line())
	return out


## The map's night (StoryDirector: 2 = the dark night after the star broke, 1 = the story's night,
## 0 = day) with `count` pieces at the lookout: the night lifts a step per piece, slowly at first
## (2026-10-28 user: the map should really be dark; with the linear 1 -> 0 the grass read as day and
## 7 pieces as almost day), so the island stays a night island until the last pieces. The last step
## (day) comes with the finale (`finale_done`: day from then on).
const NIGHT_CURVE := 0.7
static func night_level(count: int, finale_done: bool) -> float:
	if finale_done:
		return 0.0
	var total := spots().size()
	var left := 1.0 - float(clampi(count, 0, total - 1)) / total
	return 2.0 * pow(left, NIGHT_CURVE)


## The island's spots, in the map's order (Island.spots).
static func spots() -> Array:
	return Island.current().spots()


## The spots whose piece is found: every stage stamped (an old save counts too).
static func found(progress: Dictionary) -> Array:
	return Island.current().found(progress)


## The found pieces already at the lookout (their flight played, or an old save: no flight).
static func placed(progress: Dictionary) -> Array:
	var flying := ProgressStore.pending(ProgressStore.PIECES)
	return found(progress).filter(func(id: String) -> bool: return id not in flying)


## The found pieces whose flight to the lookout is still to play (in the map's order).
static func to_fly(progress: Dictionary) -> Array:
	var flying := ProgressStore.pending(ProgressStore.PIECES)
	return found(progress).filter(func(id: String) -> bool: return id in flying)


static func prologue_seen() -> bool:
	return ProgressStore.mark(ProgressStore.STORY, _part_key("prologue"))


static func finale_seen() -> bool:
	return ProgressStore.mark(ProgressStore.STORY, _part_key("finale"))


## The island's "prologue" or "finale" was played (once, even if the app closes during it).
static func mark_seen(part: String) -> void:
	ProgressStore.set_mark(ProgressStore.STORY, _part_key(part), true)


## The save key of the island in use's story part (ProgressStore.island_key).
static func _part_key(part: String) -> String:
	return ProgressStore.island_key(Island.current_id(), part)


static func clue_seen(id: String) -> bool:
	return ProgressStore.mark(ProgressStore.CLUES, id)


## A measurement or a device check (the launch args): no story, ever (--progress=bench, --auto-drag,
## --auto-release, --demo-celebrate, --demo-flag, --sound=0). --demo-story turns it on in the bench
## store (App).
static func measurement_run(args: PackedStringArray) -> bool:
	for arg in args:
		for prefix in ["--progress=bench", "--auto-drag=", "--auto-release=", "--demo-celebrate=", "--demo-flag=", "--sound=0"]:
			if arg.begins_with(prefix):
				return true
	return false
