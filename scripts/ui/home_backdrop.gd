class_name HomeBackdrop
extends TextureRect

## Illustrated 2D Canyon backdrop for the Home screen.
## The detailed artwork remains the primary asset. If Godot cannot import the
## embedded-raster SVG on a given build, use the render-safe vector fallback
## instead of showing a blank/grey screen.

const BACKGROUND_PATH := "res://assets/ui/home_background.svg"
const FALLBACK_TEXTURE := preload("res://assets/ui/home_background_fallback.svg")

func _ready() -> void:
	var artwork := load(BACKGROUND_PATH) as Texture2D
	texture = artwork if artwork != null else FALLBACK_TEXTURE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
