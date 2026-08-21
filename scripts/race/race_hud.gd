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

## Rows in the standings column, top right. Colour is how a marble is named —
## `DECISIONS.md` rules out arrows and oversized markers, and a number the player
## cannot map onto anything on screen is worse than nothing, so each row carries
## the marble's own colour as a dot.
const STANDINGS_FONT := 19

var _status: Label
var _notice: Label
var _standings: RichTextLabel
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
	_build_standings()


## Anchored to the right edge rather than positioned, because the design space is
## 720x1280 (see project.godot) while the window is 450x800, and only the anchor
## survives that.
func _build_standings() -> void:
	_standings = RichTextLabel.new()
	_standings.bbcode_enabled = true
	_standings.scroll_active = false
	_standings.fit_content = true
	_standings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_standings.anchor_left = 1.0
	_standings.anchor_right = 1.0
	_standings.offset_left = -290
	_standings.offset_right = -20
	_standings.offset_top = 18
	_standings.offset_bottom = 640
	_standings.add_theme_font_size_override("normal_font_size", STANDINGS_FONT)
	_standings.add_theme_font_size_override("bold_font_size", STANDINGS_FONT)
	_standings.add_theme_color_override("font_outline_color", Color.BLACK)
	_standings.add_theme_constant_override("outline_size", 5)
	add_child(_standings)


## `rows` is what the race decided should be on screen, already ordered and
## already trimmed. The HUD does not know what a cut line is or which marble the
## player owns beyond what each row tells it.
func show_standings(rows: Array) -> void:
	var out := PackedStringArray()
	out.append("[right]")

	for row: Dictionary in rows:
		if row.get("elided", false):
			out.append("[color=#7d8595]···[/color]")
			continue

		# The elimination line. Drawn as a rule rather than a labelled row so it
		# reads as a boundary between the marbles above and below it, which is
		# what it is — everything above survives the round.
		if row.get("cut", false):
			out.append("[color=#ff9d4d]───── cut ─────[/color]")
			continue

		var colour: Color = row["colour"]
		var line := "[color=#%s]●[/color]  %s  [color=#c8cede]%s[/color]" % [
			colour.to_html(false), row["name"], row["trailing"]
		]
		if row.get("is_player", false):
			line = "[b]%s[/b]" % line
		out.append(line)

	out.append("[/right]")
	_standings.text = "\n".join(out)


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
