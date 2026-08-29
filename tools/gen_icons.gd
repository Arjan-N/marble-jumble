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
	# Adaptive foreground: the art is a full-bleed scene, so it fills the 432px
	# canvas and Android's ~66% safe circle crops into it. Insetting it instead
	# would float a visible square of artwork on the background field.
	_save_adaptive_foreground(src, 432, "res://assets/icons/app_icon_adaptive_fg_432.png")
	_save_background(src, 432, "res://assets/icons/app_icon_adaptive_bg_432.png")
	quit()

func _save_scaled(src: Image, size: int, path: String) -> void:
	var img := src.duplicate() as Image
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(path))

func _save_adaptive_foreground(src: Image, size: int, path: String) -> void:
	var img := src.duplicate() as Image
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(path))

func _save_background(src: Image, size: int, path: String) -> void:
	# Solid fill sampled from the top-centre of the art. The full-bleed foreground
	# covers this on a static launcher, but it still shows through during the
	# parallax shift, so it should read as the icon's own sky rather than black.
	var c := src.get_pixel(src.get_width() / 2, int(src.get_height() * 0.04))
	# Darkened so the field sits behind the artwork instead of competing with it.
	c = Color(c.r * 0.45, c.g * 0.42, c.b * 0.30, 1.0)
	var canvas := Image.create(size, size, false, Image.FORMAT_RGBA8)
	canvas.fill(c)
	canvas.save_png(ProjectSettings.globalize_path(path))
