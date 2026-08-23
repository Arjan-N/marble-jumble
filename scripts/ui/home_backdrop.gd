class_name HomeBackdrop
extends TextureRect

## Illustrated 2D Canyon backdrop for the Home screen.
## The environment is intentionally authored as cheap 2D artwork; the only
## live 3D elements are the marble and its small physical track.

const BACKGROUND_TEXTURE := preload("res://assets/ui/home_background.svg")
const TRACK_TOP_FRACTION := 0.68
const TRACK_HEIGHT_FRACTION := 0.10

func _ready() -> void:
	texture = BACKGROUND_TEXTURE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1.0, 1.0, 1.0, 0.98)
