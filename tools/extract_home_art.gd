extends SceneTree

## Cuts the player marble and the foreground play surface out of the home
## mock-up and writes them into `assets/ui/` as shipping textures.
##
##     godot --path . --headless --script res://tools/extract_home_art.gd
##
## The mock-up is the only place either piece of artwork exists — there is no
## standalone marble or platform asset in the repository — and promoting art
## out of `docs/ui-reference/` is how `home_background.png` was produced too
## (see the header of `home_backdrop.gd`). Keeping the cut in a script rather
## than doing it by hand means the numbers below are reviewable and the
## textures can be regenerated if the mock-up is ever revised.
##
## All coordinates are in the mock-up's own 1882x3344 pixel space, which shares
## the project's 9:16 viewport aspect exactly, so everything here maps to the
## 720x1280 design space by a single 720/1882 scale factor.

const SOURCE := "res://docs/ui-reference/home.png"

## The marble's dark outline, measured off the mock-up.
const MARBLE_CENTRE := Vector2(896.0, 2113.0)
const MARBLE_RADIUS := 178.0
## A hair of padding so the outline is never clipped by the texture edge.
const MARBLE_PAD := 9

## The platform band: from the back edge of the top face down through the dark
## base under the front face.
const SURFACE_TOP := 2160
const SURFACE_BOTTOM := 2495

## The mock-up bakes the marble and its cast shadow onto the platform, so the
## strip has to be repaired before it can be used as a surface the live marble
## rolls along. `GAP` is the contaminated span, refilled by reflecting the clean
## stone to its left back across it. A reflection is seamless at its own axis,
## so the left join disappears; the right join is placed where the mock-up has a
## mortar line, which is the one kind of hard vertical edge the stone already
## has. Reflecting from one side only keeps the whole fill on the same stretch
## of platform, so the tile courses and the lit front edge stay at one height —
## reflecting each side inwards kinked them where the two met.
const GAP_LEFT := 700
const GAP_RIGHT := 1390
## The reflection runs the platform edge back the way it came, so where it meets
## the untouched stone again the edge would kink. The last stretch of the fill
## is cross-faded into the real pixels instead, which trades a hard kink for a
## soft one over more than a tile width.
const GAP_FEATHER := 120.0


func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null:
		push_error("Could not read %s" % SOURCE)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)

	_write(_cut_marble(source), "res://assets/ui/marble_player.png")
	_write(_cut_play_surface(source), "res://assets/ui/play_surface.png")
	quit(0)


func _write(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Could not write %s (%d)" % [path, error])
		quit(1)
		return
	print("%s  %s" % [path, image.get_size()])


## The marble, lifted off the canyon behind it as a round cut-out with a
## one-pixel feather so the outline stays crisp without an aliased fringe.
func _cut_marble(source: Image) -> Image:
	var side := int(MARBLE_RADIUS) * 2 + MARBLE_PAD * 2
	var origin := Vector2i(MARBLE_CENTRE) - Vector2i.ONE * (side / 2)
	var cut := source.get_region(Rect2i(origin, Vector2i(side, side)))
	var centre := Vector2(side, side) * 0.5

	for y in side:
		for x in side:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(centre)
			var alpha := clampf(MARBLE_RADIUS + 0.5 - distance, 0.0, 1.0)
			var pixel := cut.get_pixel(x, y)
			pixel.a = alpha
			cut.set_pixel(x, y, pixel)
	return cut


func _cut_play_surface(source: Image) -> Image:
	var strip := source.get_region(
		Rect2i(0, SURFACE_TOP, source.get_width(), SURFACE_BOTTOM - SURFACE_TOP)
	)
	var height := strip.get_height()
	var patched := Image.create_empty(strip.get_width(), height, false, Image.FORMAT_RGBA8)
	patched.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i.ZERO)

	for x in range(GAP_LEFT, GAP_RIGHT):
		var source_x := clampi(GAP_LEFT * 2 - x, 0, strip.get_width() - 1)
		var reflected := clampf((GAP_RIGHT - x) / GAP_FEATHER, 0.0, 1.0)
		for y in height:
			patched.set_pixel(
				x, y, strip.get_pixel(x, y).lerp(strip.get_pixel(source_x, y), reflected)
			)
	return patched
