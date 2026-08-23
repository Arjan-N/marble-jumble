class_name HomeBackdrop
extends TextureRect

## Illustrated 2D Canyon backdrop for the Home screen.
## Imported through Godot's normal texture pipeline like any other asset —
## the SVG-wrapping-a-JPEG data URI carries JPEG bytes that no in-engine
## decoder (Compatibility SVG import, runtime SVG, runtime JPEG) can
## reliably parse; see home_background.png, a clean re-export.

const BACKGROUND_TEXTURE := preload("res://assets/ui/home_background.png")

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
	texture = BACKGROUND_TEXTURE
