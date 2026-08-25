class_name UIKit
extends Object

## Shared comic-book styling for the game's chunky arcade screens.
##
## The project had no palette or typography module — `home_screen.gd`,
## `home_icon.gd` and `home_marble_preview.gd` each carry their own near-black,
## and every label reaches for the engine's default font. This collects the
## values the end-of-round screen needs in one place so its panels, badges and
## buttons cannot drift apart from each other.
##
## Only `round_results_screen.gd` and its parts use this today. The existing
## screens are deliberately left alone (they were not part of this work); when
## they are next touched, they should move onto these constants rather than
## growing a fourth near-black.

## Lilita One (SIL Open Font License, see `assets/fonts/LilitaOne-OFL.txt`) —
## a heavy display face with the rounded, slightly condensed weight the
## mock-ups are drawn with. The engine's default font is a UI face and cannot
## carry a 100px title without looking like a dialog box.
const DISPLAY_FONT := preload("res://assets/fonts/LilitaOne-Regular.ttf")

## Comic-book ink. Same value `home_screen.gd` and `home_marble_preview.gd`
## already outline with, so this screen sits in the same drawing.
const INK := Color(0.075, 0.032, 0.018)
const CREAM := Color(1.0, 0.965, 0.86)
const GOLD := Color(1.0, 0.76, 0.16)
const GOLD_DEEP := Color(0.93, 0.52, 0.06)
const GOLD_LIGHT := Color(1.0, 0.87, 0.42)
## The player's own colour language on this screen: the cyan the mock-up uses
## for "4TH" and for the live half of "6 / 12". Not the equipped skin colour —
## that changes per player, and the highlight has to stay legible whatever the
## marble happens to look like.
const CYAN := Color(0.30, 0.84, 0.95)
const RED := Color(0.90, 0.22, 0.22)
const RED_DEEP := Color(0.45, 0.09, 0.09)
const TEAL := Color(0.18, 0.62, 0.58)
const PANEL_FILL := Color(0.086, 0.078, 0.082, 0.94)
const PANEL_TAB_INK := Color(0.14, 0.12, 0.13, 0.98)
const MUTED := Color(0.72, 0.70, 0.68)


## A display-font label. `outline` is the ink line thickness in pixels; every
## piece of text on this screen carries one, because it is drawn over a live
## 3D course and nothing without an outline survives that background.
static func label(
	text: String,
	font_size: int,
	fill: Color = CREAM,
	outline: int = 8,
	align: int = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_override("font", DISPLAY_FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", fill)
	node.add_theme_color_override("font_outline_color", INK)
	node.add_theme_constant_override("outline_size", outline)
	node.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	node.add_theme_constant_override("shadow_offset_x", 0)
	node.add_theme_constant_override("shadow_offset_y", 6)
	node.add_theme_constant_override("shadow_outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## The dark framed plate the panels, badges and summary bar are all built on.
static func plate(fill: Color, border: Color, border_px: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_px)
	style.border_color = border
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 7.0)
	return style


static func panel(style: StyleBoxFlat) -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel", style)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## "1ST", "2ND", "3RD", "4TH"… `race_manager.gd` has its own private copy for
## its debug/status lines; this one exists so the results screen does not have
## to reach into the race for a string helper.
static func ordinal(value: int) -> String:
	var suffix := "TH"
	if value % 100 < 11 or value % 100 > 13:
		match value % 10:
			1: suffix = "ST"
			2: suffix = "ND"
			3: suffix = "RD"
	return "%d%s" % [value, suffix]
