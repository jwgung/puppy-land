## Which piece an island's spots give (#101, 2026-11-07): the island's `piece` (Island.piece, its
## layout file; the first island's star when unset) picks the look everywhere a found piece shows: in
## the lab (LabGame.make_piece), in the bread cat's paws (ExperimentScreen), on the round-done card
## (RoundDoneCard), flying on the map and in the map's corner emblem (StoryDirector) and on the island
## cards (IslandCards). One switch here instead of island checks in each place.
## - "star": the guiding star's piece (StarArt) and StarEmblem (the mechanics island).
## - "sundial": a golden wedge of the sundial's dial (SundialArt) and SundialEmblem (the hutton island).
## - "lens": a rainbow wedge of the lighthouse's lens, or spot 12's flame (LensArt) and LensEmblem (the
##   curie island, #154). Its colour is its spot's place in the island's order (`slot`).
## The guiding star itself (the first island's prologue, the finale, the hint's twinkle) stays StarArt.
class_name PieceArt
extends RefCounted

const STAR := Island.PIECE_STAR
const SUNDIAL := Island.PIECE_SUNDIAL
const LENS := Island.PIECE_LENS
## The sundial wedge is thinner than the star (a tenth of the dial), so in the lab it is drawn this much
## bigger to keep its face readable (#101, 2026-11-07 user); the cat's paws, the card and the ending
## use their own sizes. The lens's eleventh is as thin (#154): the same.
const SUNDIAL_LAB_SCALE := 1.3


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


## The place in its island's order of the experiment `experiment_id`'s spot (0 when not on one): the
## lens piece's colour (`slot` below).
static func slot_of(experiment_id: String) -> int:
	var island := ExperimentRegistry.island_of(experiment_id)
	if island == "" or Island.entry(island).is_empty():
		return 0
	return maxi(0, Island.by_id(island).slot_of(experiment_id))


## How much bigger a piece of `kind` is drawn in the lab than the star (LabGame.full_size).
static func lab_scale(kind: String) -> float:
	return SUNDIAL_LAB_SCALE if kind in [SUNDIAL, LENS] else 1.0


## A piece node of `kind`, `size` m from its centre to its point (StarArt.face_camera turns either);
## `slot` (the spot's place in the order) picks the lens's colour or its flame.
static func make(kind: String, size: float, slot := 0) -> Node3D:
	match kind:
		SUNDIAL:
			return SundialArt.make(size)
		LENS:
			return LensArt.make(size, slot)
	return StarArt.make(true, size)


## The map corner's emblem of `kind` for an island of `total` spots.
static func emblem(kind: String, total: int) -> PieceEmblem:
	match kind:
		SUNDIAL:
			return SundialEmblem.new(total)
		LENS:
			return LensEmblem.new(total)
	return StarEmblem.new(total)


## The piece of `kind` (and `slot`, as make) in 2D (y down) on `canvas`, `r` px from its centre to its point.
static func draw_2d(kind: String, canvas: CanvasItem, c: Vector2, r: float, slot := 0) -> void:
	match kind:
		SUNDIAL:
			SundialArt.draw_piece_2d(canvas, c, r)
		LENS:
			LensArt.draw_piece_2d(canvas, c, r, slot)
		_:
			StarArt.draw_piece_2d(canvas, c, r)
