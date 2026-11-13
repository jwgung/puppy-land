## Term marks (2026-11-03 playtest: a child should see which word Dugi is teaching): in the kid texts a
## science word at the spot where Dugi introduces it is written between MARK pairs
## ("이 힘을 **마찰력**이라고 해."). Dugi's dialogue box (DialogueBox) draws it bold on a yellow
## highlight; every other reader takes plain() (the science note's AI question, lengths, comparisons).
## Only the introduction spots carry marks (kid.intro and the stage say that names the word), not every
## use of the word.
class_name TermMarks
extends RefCounted

const MARK := "**"


## `text` without its marks.
static func plain(text: String) -> String:
	return text.replace(MARK, "")


## Whether `text` has a mark.
static func marked(text: String) -> bool:
	return text.contains(MARK)


## The pieces of `text` between the marks: [[piece, is a term], ...] (no empty pieces). `open`: the
## text starts inside a term (a line after one that ended inside it).
static func spans(text: String, open := false) -> Array:
	var out := []
	var term := open
	for piece in text.split(MARK):
		if piece != "":
			out.append([piece, term])
		term = not term
	return out


## Whether a term is still open at the end of `text` (an odd number of marks), starting `open`.
static func ends_open(text: String, open := false) -> bool:
	return (text.count(MARK) % 2 == 1) != open


## `text` (marked) as RichTextLabel BBCode: the terms bold on `highlight`, every "[" of the words
## escaped. Only the first `visible` characters of the plain text (-1 = all: the typewriter shows a
## prefix, and only what is shown has its highlight).
static func bbcode(text: String, highlight: Color, visible := -1) -> String:
	var out := ""
	var left := visible
	for s in spans(text):
		var piece: String = s[0]
		if left >= 0:
			if left == 0:
				break
			piece = piece.left(left)
			left -= piece.length()
		piece = piece.replace("[", "[lb]")
		out += "[b][bgcolor=#%s]%s[/bgcolor][/b]" % [highlight.to_html(), piece] if s[1] else piece
	return out


## Lines (marked, a term may run over a line break) closed and opened again at each break, so every
## line has its own pairs of marks; plain(line) is unchanged.
static func balance(lines: Array) -> Array:
	var out := []
	var open := false
	for line: String in lines:
		var shown := (MARK + line) if open else line
		open = ends_open(line, open)
		out.append(shown + MARK if open else shown)
	return out
