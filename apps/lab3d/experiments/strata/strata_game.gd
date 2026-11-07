## The 지층 쌓기 piece game (#96; hutton-lines.md 9: "무너진 틈에 조각이 보여! 그런데 줄이 너무 많아서 어느
## 줄인지 모르겠어."): the piece is hidden in the cliff's layer just under the grey ash; only a glint
## deep in the crack, on the line between two layers, shows something is there. Stages 1 and 2 (the
## tank's layers, the fossil): the glint swells and flashes, the bread cat cheers. Stage 3: the dug
## layer's hole opens (StrataProps) with the piece in it, which jumps out onto the terrace at the cliff's
## foot ("조각이다! 옛날에 화산이 터졌었네?"); the screen then flies it to the bread cat. Visual only.
class_name StrataGame
extends LabGame

const HIDDEN_SIZE := 0.16
## The glint's swell at a stamp (of its size) and how long it lasts; its idle twinkle.
const GLINT_S := 0.8
const GLINT_SWELL := 1.2
const TWINKLE := 0.25
const FLIGHT_S := 1.0
## The piece shows in its hole this long before it jumps.
const SHOW_S := 0.5
## Where it lands: on the terrace at the cliff's foot, in front (the cat watches from the cliff top).
const LAND_AT := Vector3(2.25, 0.0, 1.9)
const HIGHLIGHT_R := 0.9

var _glint_at := NEVER
var _out_at := NEVER


func _props() -> StrataProps:
	return (host().props as StrataProps) if host() != null else null


func build() -> void:
	make_piece(StrataProps.dent_at(StrataModel.TARGET) + Vector3(0.0, 0.0, 0.05), HIDDEN_SIZE)
	_jump(0)


func _cleared(stage_index: int, last: bool) -> void:
	cheer_cat(last)
	_glint_at = _t
	if last:
		_out_at = _t + SHOW_S


func _jump(stamps: int) -> void:
	_out_at = NEVER
	if _props() != null:
		_props().glint.visible = stamps < stages


## The glow while Puppy tells the clue: on the crack's glint, not on a layer (which one is the riddle).
func highlight_spots() -> Array:
	var p := _props()
	if p == null:
		return []
	return [{"at": p.glint.position, "radius": HIGHLIGHT_R}]


func _process(delta: float) -> void:
	super(delta)
	var p := _props()
	if p == null or piece == null:
		return
	var swell := GLINT_SWELL * pulse(_glint_at, GLINT_S)
	if progress(_glint_at, GLINT_S) >= 1.0:
		_glint_at = NEVER
	p.glint.scale = Vector3.ONE * (1.0 + TWINKLE * sin(_t * 4.0) + swell)
	if piece_state == "held":
		# Seen only in its open hole (the layer under the ash dug).
		var lab: Variant = host()
		piece.visible = lab != null and (lab.model as StrataModel).found() and (lab.model as StrataModel).input("dig") > 0.6
		if due(_out_at):
			_out_at = NEVER
			p.glint.visible = false
			piece.visible = true
			launch_to(LAND_AT + Vector3.UP * StrataProps.TERRACE_TOP, FLIGHT_S, StrataProps.TERRACE_TOP, true)
