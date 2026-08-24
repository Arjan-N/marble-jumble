class_name HomePlaySurface
extends TextureRect

## The illustrated stone platform the home marble sits on.
##
## `play_surface.png` is cut from the home mock-up by
## `tools/extract_home_art.gd` — see that script for why the artwork comes from
## there. The mock-up and the project viewport share a 9:16 aspect, so the strip
## spans the full screen width at the same proportions it was painted at and
## needs no tiling or nine-patch.

const SURFACE_TEXTURE := preload("res://assets/ui/play_surface.png")

## Where the strip sat in the mock-up's 3344px-tall frame, as a fraction of the
## screen. Everything else on this screen — the marble's resting height, the gap
## to the nav row — is measured off these two numbers.
const TOP := 2160.0 / 3344.0
const BOTTOM := 2495.0 / 3344.0


func _ready() -> void:
	texture = SURFACE_TEXTURE
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = TOP
	anchor_bottom = BOTTOM
	offset_left = 0.0
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = 0.0
	# The strip's own aspect matches the box these anchors describe to within a
	# pixel, so scaling to fill costs no visible distortion and guarantees the
	# platform reaches both screen edges however the viewport is stretched.
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
