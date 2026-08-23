class_name HomeBackdrop
extends TextureRect

## Illustrated 2D Canyon backdrop for the Home screen.
## The reference artwork is kept as a single SVG asset. Load the SVG through
## Godot's image decoder at runtime so the embedded image is handled by the
## same SVG pipeline as the rest of the project.

const BACKGROUND_PATH := "res://assets/ui/home_background.svg"

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
	texture = _load_svg(BACKGROUND_PATH)
	if texture == null:
		self_modulate = Color(0.08, 0.12, 0.18, 1.0)

func _load_svg(path: String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("HomeBackdrop: could not open %s" % path)
		return null

	var svg := file.get_as_text()
	file.close()

	var image := Image.new()
	var error := image.load_svg_from_string(svg, 1.0)
	if error != OK:
		push_error("HomeBackdrop: SVG failed to decode: %s" % error)
		return null

	return ImageTexture.create_from_image(image)
