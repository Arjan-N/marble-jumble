class_name RaceHUD
extends CanvasLayer

## Minimal race information, per PROJECT.md section 9. The race is the thing
## being watched; the UI stays out of its way.
##
## Two lines, and they do different jobs. The status line is always-on state —
## clock and where you are in the field — and is what makes this a race rather
## than twelve spheres rolling downhill: `PROJECT.md` section 1 sells the game as
## a spectator sport, and a spectator who cannot tell whether they are third or
## eleventh has nothing to spectate. The notice line is for things that *happen*
## and then stop being true, so it clears itself.
##
## Deliberately still text. Section 2.5 asks that the player be able to read the
## race without the UI covering it, and a standings table over a portrait frame
## covers it.

## How long a notice stays up. Long enough to read while watching something else,
## short enough that two falls in quick succession do not queue up stale text.
const NOTICE_SECONDS := 2.6
## The last stretch of a notice's life is spent fading, so it leaves rather than
## disappearing between frames.
const NOTICE_FADE := 0.7

var _status: Label
var _notice: Label
var _notice_left: float = 0.0


static func create() -> RaceHUD:
	var hud := RaceHUD.new()
	hud.name = "RaceHUD"
	hud._build()
	return hud


func _build() -> void:
	_status = _make_label(Vector2(24, 20), 22)
	_notice = _make_label(Vector2(24, 96), 20)
	_notice.modulate.a = 0.0


func _make_label(at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label


func _process(delta: float) -> void:
	if _notice_left <= 0.0:
		return

	_notice_left -= delta
	if _notice_left <= 0.0:
		_notice.text = ""
		_notice.modulate.a = 0.0
	else:
		_notice.modulate.a = minf(_notice_left / NOTICE_FADE, 1.0)


func show_text(text: String) -> void:
	_status.text = text


## Something happened. Replaces whatever notice was up rather than queueing:
## during a pile-up several marbles can go within a second of each other, and a
## queue would still be reporting the first one long after the race moved on.
func announce(text: String, colour: Color = Color.WHITE) -> void:
	_notice.text = text
	_notice.add_theme_color_override("font_color", colour)
	_notice.modulate.a = 1.0
	_notice_left = NOTICE_SECONDS


func clear_notice() -> void:
	_notice_left = 0.0
	_notice.text = ""
	_notice.modulate.a = 0.0
