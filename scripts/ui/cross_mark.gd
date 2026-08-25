class_name CrossMark
extends Control

## The red X over an eliminated marble.
##
## Drawn rather than set as a label's text: the display font
## (`ui_kit.gd`'s Lilita One) has no dedicated cross glyph, a letter "X" reads
## as a letter, and the mock-up's mark is a pair of thick tapered strokes with
## the same ink line every other element on the screen carries. Two
## `draw_line` passes — ink first, red over it — get exactly that for nothing.

const STROKE_RATIO := 0.30
const INK_EXTRA := 5.0
## The arms stop short of the corners so the mark reads as a drawn X rather
## than as a filled square with a cross cut out of it.
const INSET := 0.16

var colour := UIKit.RED
var ink := UIKit.INK


static func create(side: float) -> CrossMark:
	var mark := CrossMark.new()
	mark.custom_minimum_size = Vector2(side, side)
	mark.size = Vector2(side, side)
	mark.pivot_offset = Vector2(side, side) * 0.5
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark


func _draw() -> void:
	var a := size * INSET
	var b := size * (1.0 - INSET)
	var stroke := minf(size.x, size.y) * STROKE_RATIO
	var strokes := [
		[Vector2(a.x, a.y), Vector2(b.x, b.y)],
		[Vector2(b.x, a.y), Vector2(a.x, b.y)],
	]
	for pass_index in 2:
		var width := stroke + INK_EXTRA if pass_index == 0 else stroke
		var pass_colour := ink if pass_index == 0 else colour
		for line in strokes:
			draw_line(line[0], line[1], pass_colour, width, true)
