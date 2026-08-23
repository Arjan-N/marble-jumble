class_name ComicPopup
extends Node2D

## A small, quiet callout — just a word, no background — for the moments a
## young player should feel rather than read: passing someone, being passed,
## or clearing a gap with nothing to spare. Purely procedural, drawn in code,
## the same reasoning `SoundSynth` uses for audio: Phase 0 has no art pipeline
## to add a sprite through.
##
## Deliberately calmer than earlier versions of this: a jagged "pow" burst,
## and then even a soft badge behind the text, both read as louder than the
## rest of the game's restrained presentation (PROJECT.md section 8).

const POP_TIME := 0.14
const HOLD_TIME := 0.35
const FADE_TIME := 0.45
const FONT_SIZE := 18

var _text: String
var _colour: Color
var _age := 0.0


static func create(text: String, colour: Color) -> ComicPopup:
	var popup := ComicPopup.new()
	popup._text = text
	popup._colour = colour
	popup.z_index = 200
	return popup


func _ready() -> void:
	scale = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	var total := POP_TIME + HOLD_TIME + FADE_TIME
	if _age >= total:
		queue_free()
		return

	if _age < POP_TIME:
		# A small, quick settle rather than an overshooting bounce — enough to
		# read as appearing, not as a cartoon pop.
		scale = Vector2.ONE * (_age / POP_TIME)
	elif _age < POP_TIME + HOLD_TIME:
		scale = Vector2.ONE
	else:
		var t := (_age - POP_TIME - HOLD_TIME) / FADE_TIME
		modulate.a = 1.0 - t
		position.y -= delta * 18.0


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	var pos := Vector2(-text_size.x * 0.5, text_size.y * 0.3)
	# Cheap outlined text: a black copy offset behind, the given colour on top —
	# with no badge left to carry it, the colour cue lives in the text itself.
	draw_string(
		font, pos + Vector2(1.0, 1.0), _text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE,
		Color(0.0, 0.0, 0.0, 0.8)
	)
	draw_string(font, pos, _text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, _colour)
