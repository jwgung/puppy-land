## Which piece an island's spots give (#101, 2026-11-07): the island's `piece` (Island.piece, its
## layout file; the first island's star when unset) picks the look everywhere a found piece shows: in
## the lab (LabGame.make_piece), in the bread cat's paws (ExperimentScreen), on the round-done card
## (RoundDoneCard), flying on the map and in the map's corner emblem (StoryDirector) and on the island
## cards (IslandCards). One switch here instead of island checks in each place.
## - "star": the guiding star's piece (StarArt) and StarEmblem (the mechanics island).
## - "sundial": a golden wedge of the sundial's dial (SundialArt) and SundialEmblem (the hutton island).
## The guiding star itself (the first island's prologue, the finale, the hint's twinkle) stays StarArt.
class_name PieceArt
extends RefCounted

const STAR := "star"
const SUNDIAL := "sundial"


## The piece kind of `island_id` (an unknown island: the star).
static func of_island(island_id: String) -> String:
	if Island.entry(island_id).is_empty():
		return STAR
	return Island.by_id(island_id).piece


## The piece kind of the experiment `experiment_id`: its island's (ExperimentRegistry.island_of; the
## first island's labs and an unknown id: the first island's).
static func of_experiment(experiment_id: String) -> String:
	var island := ExperimentRegistry.island_of(experiment_id)
	if island == "":
		var ids := Island.ids()
		island = str(ids[0]) if not ids.is_empty() else ""
	return of_island(island)


## A piece node of `kind`, `size` m from its centre to its point (StarArt.face_camera turns either).
static func make(kind: String, size: float) -> Node3D:
	return SundialArt.make(size) if kind == SUNDIAL else StarArt.make(true, size)


## The map corner's emblem of `kind` for an island of `total` spots.
static func emblem(kind: String, total: int) -> PieceEmblem:
	return SundialEmblem.new(total) if kind == SUNDIAL else StarEmblem.new(total)


## The piece of `kind` in 2D (y down) on `canvas`, `r` px from its centre to its point.
static func draw_2d(kind: String, canvas: CanvasItem, c: Vector2, r: float) -> void:
	if kind == SUNDIAL:
		SundialArt.draw_piece_2d(canvas, c, r)
	else:
		StarArt.draw_piece_2d(canvas, c, r)
