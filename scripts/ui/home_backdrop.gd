class_name HomeBackdrop
extends TextureRect

## Illustrated 2D Canyon backdrop for the Home screen.
## The supplied artwork is an SVG wrapper containing the reference JPEG.
## Decode the embedded JPEG directly; this is the known-good Compatibility
## renderer path for this asset.

const BACKGROUND_PATH := "res://assets/ui/home_background.svg"

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color.WHITE
	texture = _load_embedded_image(BACKGROUND_PATH)
	if texture == null:
		self_modulate = Color(0.08, 0.12, 0.18, 1.0)

func _load_embedded_image(path: String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("HomeBackdrop: could not open %s" % path)
		return null

	var svg := file.get_as_text()
	file.close()

	var marker := "base64,"
	var start := svg.find(marker)
	if start < 0:
		push_error("HomeBackdrop: no embedded base64 image found in %s" % path)
		return null
	start += marker.length()

	var end := svg.find('"', start)
	if end < 0:
		push_error("HomeBackdrop: malformed embedded image in %s" % path)
		return null

	var encoded := svg.substr(start, end - start)
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		push_error("HomeBackdrop: embedded image decoded to zero bytes")
		return null

	var image := Image.new()
	var error := image.load_jpg_from_buffer(bytes)
	if error != OK:
		push_error("HomeBackdrop: embedded JPEG failed to decode: %s" % error)
		return null

	return ImageTexture.create_from_image(image)
