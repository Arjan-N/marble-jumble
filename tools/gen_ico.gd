@tool
extends SceneTree

# Packs the app icon into a multi-size Windows .ico (PNG-compressed entries,
# which Windows Vista and later read directly).
# Run: godot --headless --path . --script tools/gen_ico.gd

const SRC := "res://assets/icons/app_icon.png"
const OUT := "res://assets/icons/app_icon.ico"
const SIZES := [16, 24, 32, 48, 64, 128, 256]

func _init() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	if src == null:
		push_error("could not load %s" % SRC)
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)

	var blobs: Array[PackedByteArray] = []
	for size in SIZES:
		var img := src.duplicate() as Image
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		blobs.append(img.save_png_to_buffer())

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_16(0)              # reserved
	f.store_16(1)              # type: icon
	f.store_16(SIZES.size())
	# Image data follows the 6-byte header and one 16-byte entry per size.
	var offset := 6 + 16 * SIZES.size()
	for i in SIZES.size():
		var size: int = SIZES[i]
		f.store_8(0 if size >= 256 else size)   # 0 means 256
		f.store_8(0 if size >= 256 else size)
		f.store_8(0)           # palette colors
		f.store_8(0)           # reserved
		f.store_16(1)          # color planes
		f.store_16(32)         # bits per pixel
		f.store_32(blobs[i].size())
		f.store_32(offset)
		offset += blobs[i].size()
	for b in blobs:
		f.store_buffer(b)
	f.close()
	quit()
