@tool
extends SceneTree

# Generates the launcher/window icon sizes from assets/icons/app_icon.png.
# Run: godot --headless --path . --script tools/gen_icons.gd

const SRC := "res://assets/icons/app_icon.png"

func _init() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	if src == null:
		push_error("could not load %s" % SRC)
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)

	_save_scaled(src, 192, "res://assets/icons/app_icon_192.png")
	_save_scaled(src, 256, "res://assets/icons/app_icon_256.png")
	# Adaptive foreground: Android crops to a circle of ~66% of the 432px canvas,
	# so the artwork is inset rather than filling the frame edge to edge.
	_save_adaptive_foreground(src, 432, "res://assets/icons/app_icon_adaptive_fg_432.png")
	_save_background(src, 432, "res://assets/icons/app_icon_adaptive_bg_432.png")
	quit()

func _save_scaled(src: Image, size: int, path: String) -> void:
	var img := src.duplicate() as Image
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(path))

func _save_adaptive_foreground(src: Image, size: int, path: String) -> void:
	var inner := int(round(size * 0.66))
	var img := src.duplicate() as Image
	img.resize(inner, inner, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(size, size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	var off := (size - inner) / 2
	canvas.blit_rect(img, Rect2i(Vector2i.ZERO, Vector2i(inner, inner)), Vector2i(off, off))
	canvas.save_png(ProjectSettings.globalize_path(path))

func _save_background(src: Image, size: int, path: String) -> void:
	# Solid fill sampled from the frame at top-centre — the corners are
	# transparent, and the ring left around the inset foreground should read as
	# more of the icon's own border rather than as black.
	var c := src.get_pixel(src.get_width() / 2, int(src.get_height() * 0.04))
	# Darkened: the raw frame highlight is a near-pure yellow, far too loud as a
	# full-bleed field behind the icon. Bronze reads as the frame's own shadow.
	c = Color(c.r * 0.45, c.g * 0.42, c.b * 0.30, 1.0)
	var canvas := Image.create(size, size, false, Image.FORMAT_RGBA8)
	canvas.fill(c)
	canvas.save_png(ProjectSettings.globalize_path(path))
