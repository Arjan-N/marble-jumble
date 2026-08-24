class_name HomePlaySurface
extends TextureRect

## The illustrated stone platform the home marble sits on.
##
## `background_canyon_course.png` is a standalone strip (not cut from the home
## mock-up) with rock/cactus dressing above the actual tile surface, so unlike
## the old cropped-tight art it can't be stretched to exactly fill an
## aspect-matched box — that left the tile line floating wherever the rocks
## happened to land. Instead this crops in the same way `HomeBackdrop` does:
## `STRETCH_KEEP_ASPECT_COVERED` zooms until the box is filled and trims the
## sides, and the box itself is sized and positioned so the tile surface (not
## the box's own top edge) lines up with the marble on Home, which is
## positioned independently (see `MARBLE_CENTRE_Y_FRACTION`).

const SURFACE_TEXTURE := preload("res://assets/ui/background_canyon_course.png")

## Box the cropped platform fills, as fractions of the screen. Taller than the
## old strip on purpose — the marble needs the tile surface at a fixed screen
## position, and the rock dressing above it eats into the box before the tiles
## start, so the box has to run higher to compensate.
const TOP := 0.476
const BOTTOM := 0.746


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
	# Crops rather than stretches — see the class comment. Centred cropping trims
	# the sides evenly, which matches the art's roughly symmetric cactus/rock
	# dressing at both ends.
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
