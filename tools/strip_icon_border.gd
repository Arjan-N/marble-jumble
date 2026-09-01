extends Node

## Regenerates the app icons from the existing art with the gold frame removed.
##
## The icon was drawn as a badge: a thick gold rounded-square border around the
## canyon scene. Arjan asked for the same icon without it. The border is painted
## into the art rather than being a layer, so "removing" it means cropping to the
## inside edge of the ring and scaling the artwork back up to the icon's own
## footprint — every output keeps the pixel size it had, so nothing downstream
## (`project.godot`, `export_presets.cfg`) needs touching.
##
## Godot does the image work because nothing else here can: there is no
## ImageMagick, no ffmpeg and no usable Python on this machine, and `Image`
## already has crop, resize and PNG encode. Run it as a *scene* rather than with
## `--script`, for the autoload reason `tools/probe_course.tscn` records:
##
##     godot --path . --headless res://tools/strip_icon_border.tscn --quit-after 5
##
## It reads and rewrites `assets/icons/` in place. The originals are recoverable
## from git; this is deliberately not a two-way tool.

const SOURCE := "res://assets/icons/app_icon.png"
const ADAPTIVE := "res://assets/icons/app_icon_adaptive_fg_432.png"
const ICO := "res://assets/icons/app_icon.ico"

## What the square PNGs are written back out at, keyed by path.
const SIZES := {
	"res://assets/icons/app_icon.png": 1254,
	"res://assets/icons/app_icon_256.png": 256,
	"res://assets/icons/app_icon_192.png": 192,
}

## The sizes Windows wants inside the `.ico`. Largest first, which is the order
## explorer and the taskbar prefer to read them in.
const ICO_SIZES := [256, 128, 64, 48, 32, 16]

## A pixel counts as frame if it is a saturated yellow.
##
## The green threshold is the load-bearing one and it is set high on purpose: the
## canyon rock inside the badge is warm too (about r 0.72, g 0.44, b 0.30) and a
## looser test finds "frame" several hundred pixels into the artwork. The ring
## itself runs pale yellow to amber, and both are well above this.
const FRAME_MIN_RED := 0.80
const FRAME_MIN_GREEN := 0.60
const FRAME_MAX_BLUE := 0.45

## How far in from an edge the ring is looked for, as a fraction of the image.
## Past this the search is into artwork, and anything yellow there — a lit rock
## face, the marble's own swirl — is not the frame.
const SEARCH_DEPTH := 0.22

## Consecutive artwork pixels that end the walk. See `_walk`.
const ART_RUN := 8

## Bitten off the crop on every side after the ring is found, to swallow the
## thin dark outline drawn just inside it and any anti-aliased gold fringe. A
## fringe survives scaling as a coloured halo, which is exactly the thing being
## removed here.
const BLEED := 3


func _ready() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null:
		push_error("could not load %s" % SOURCE)
		return

	var inner := _inner_rect(source)
	print("source %dx%d, art inside the frame: %s" % [
		source.get_width(), source.get_height(), inner
	])

	var art := source.get_region(inner)
	for path: String in SIZES:
		var out := Image.new()
		out.copy_from(art)
		out.resize(SIZES[path], SIZES[path], Image.INTERPOLATE_LANCZOS)
		out.save_png(ProjectSettings.globalize_path(path))
		print("wrote %s at %d" % [path, SIZES[path]])

	_write_ico(art)
	_write_adaptive(art)
	print("done")


## The artwork's bounds inside the gold ring.
##
## Walks in from each side along the middle row or column: past anything
## transparent (the badge's corners are cut away), then past the ring itself,
## stopping at the first pixel that is neither. Each side is measured on its own
## because the ring is not perfectly even.
func _inner_rect(image: Image) -> Rect2i:
	var width := image.get_width()
	var height := image.get_height()

	# Three scanlines a side rather than one through the middle. A single line
	# can cross a highlight or a gap in the ring and come back short, and one
	# short side is all it takes to leave a sliver of gold in a corner.
	var inset := 0
	for fraction: float in [0.25, 0.5, 0.75]:
		var y := int(height * fraction)
		var x := int(width * fraction)
		inset = maxi(inset, _walk(image, Vector2i(0, y), Vector2i(1, 0)))
		inset = maxi(inset, _walk(image, Vector2i(width - 1, y), Vector2i(-1, 0)))
		inset = maxi(inset, _walk(image, Vector2i(x, 0), Vector2i(0, 1)))
		inset = maxi(inset, _walk(image, Vector2i(x, height - 1), Vector2i(0, -1)))

	# One inset on all four sides, not four measured ones. The ring is even, the
	# art behind it is not, and a per-side crop slides the composition sideways
	# by however much the two disagree — the first run put the marble off centre
	# and still kept gold in one corner.
	inset += BLEED
	return Rect2i(inset, inset, width - inset * 2, height - inset * 2)


## How many pixels in from `from` the artwork starts, walking along `step`.
##
## Follows the ring in from the edge and returns where it ends.
##
## The ring is one contiguous band: transparent corner, then gold, then the
## artwork. So the walk skips transparency, latches once it sees gold, and then
## keeps going through anything gold *or* dark — the band carries a near-black
## outline along both of its own edges, and stopping at the first non-gold pixel
## halts on that outline with most of the frame still in the crop.
##
## It ends at the first run of `ART_RUN` pixels that are neither, which is
## artwork. Requiring a run rather than a single pixel keeps a speck of sky
## showing through the ring from ending the walk early. Two failure modes are
## both guarded: `SEARCH_DEPTH` caps how far in this can ever look, and a walk
## that never sees gold returns nothing to crop.
func _walk(image: Image, from: Vector2i, step: Vector2i) -> int:
	var at := from
	var steps := 0
	var limit := int(maxi(image.get_width(), image.get_height()) * SEARCH_DEPTH)
	var latched := false
	var art_run := 0

	while steps < limit:
		var pixel := image.get_pixelv(at)
		var transparent := pixel.a < 0.5
		var frame := (
			not transparent
			and pixel.r >= FRAME_MIN_RED
			and pixel.g >= FRAME_MIN_GREEN
			and pixel.b <= FRAME_MAX_BLUE
		)
		var dark := not transparent and pixel.get_luminance() < 0.3

		if frame:
			latched = true
			art_run = 0
		elif latched and not dark and not transparent:
			art_run += 1
			if art_run >= ART_RUN:
				return steps - art_run + 1
		else:
			art_run = 0

		at += step
		steps += 1

	return 0


## The Android adaptive foreground, which is the same badge floating in
## transparent padding rather than filling its canvas.
##
## Its footprint is left exactly as it was — Android's mask crops this layer, and
## a foreground that suddenly fills more of its 432 canvas gets clipped by that
## mask instead of sitting inside it.
##
## The cleaned art is handed in rather than detected again on this file. Run on
## its own, `_inner_rect` measures a ring that is thinner here relative to a
## canvas that is mostly transparent padding, and it left a gold rim behind. One
## detection, on the master, is also the only way the two icons are guaranteed to
## be the same crop.
func _write_adaptive(source_art: Image) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(ADAPTIVE))
	if image == null:
		push_error("could not load %s" % ADAPTIVE)
		return

	var used := image.get_used_rect()
	# Square, centred on what the badge occupied: the old footprint is a few
	# pixels off square and stretching the art to match would show.
	var side: int = maxi(used.size.x, used.size.y)
	var badge := Rect2i(
		used.position.x + (used.size.x - side) / 2,
		used.position.y + (used.size.y - side) / 2,
		side,
		side
	)

	var art := Image.new()
	art.copy_from(source_art)
	art.resize(badge.size.x, badge.size.y, Image.INTERPOLATE_LANCZOS)

	var out := Image.create_empty(
		image.get_width(), image.get_height(), false, image.get_format()
	)
	out.blit_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), badge.position)
	out.save_png(ProjectSettings.globalize_path(ADAPTIVE))
	print("wrote %s, badge kept at %s" % [ADAPTIVE, badge])


## A PNG-embedded `.ico`, which every Windows version this game targets reads.
##
## Written by hand because `Image` has no ICO encoder: the format is a six-byte
## header, a sixteen-byte directory entry per size, then the payloads. A size of
## 256 is stored as 0, which is the format's way of saying "not 255 or less".
func _write_ico(art: Image) -> void:
	var payloads: Array[PackedByteArray] = []
	for size: int in ICO_SIZES:
		var scaled := Image.new()
		scaled.copy_from(art)
		scaled.resize(size, size, Image.INTERPOLATE_LANCZOS)
		payloads.append(scaled.save_png_to_buffer())

	var file := FileAccess.open(ProjectSettings.globalize_path(ICO), FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % ICO)
		return

	file.store_16(0)                    # reserved
	file.store_16(1)                    # type: icon
	file.store_16(ICO_SIZES.size())

	var offset := 6 + 16 * ICO_SIZES.size()
	for i in range(ICO_SIZES.size()):
		var size: int = ICO_SIZES[i]
		file.store_8(0 if size >= 256 else size)
		file.store_8(0 if size >= 256 else size)
		file.store_8(0)                 # palette colours
		file.store_8(0)                 # reserved
		file.store_16(1)                # colour planes
		file.store_16(32)               # bits per pixel
		file.store_32(payloads[i].size())
		file.store_32(offset)
		offset += payloads[i].size()

	for payload in payloads:
		file.store_buffer(payload)
	file.close()
	print("wrote %s with %d sizes" % [ICO, ICO_SIZES.size()])
