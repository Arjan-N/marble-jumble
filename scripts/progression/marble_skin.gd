class_name MarbleSkin
extends RefCounted

## Turns a skin entry from `PlayerProfile.SKINS` into a marble material.
##
## The first five skins are flat colours and stay that way: `finish` is absent
## on them and everything here falls through to the plain albedo `marble.gd`
## has always built. The elaborate skins carry a `finish` naming one of the
## generators below, which paints an equirectangular albedo (and, where the look
## needs it, an emission map) and sets the metallic/roughness that go with it.
##
## Painted in code, not imported: the project still has no art pipeline
## (marble_trail.gd), and a procedural sphere map has the useful property that
## the shop swatch can be drawn from the very same pixels — `swatch_texture`
## lights the pattern on a sphere rather than showing a second, hand-kept
## approximation of it.
##
## Textures are built once per finish and cached. A twelve-marble field only
## ever contains one skinned marble (opponents are plain colours), but Home, the
## shop and the race each ask for the equipped one, and every round of a
## tournament rebuilds the field.

## Equirectangular, and small on purpose. The marble is ~70px across on Home and
## smaller than that in a race, and it spins fast enough that fine detail turns
## into crawl. Width is twice height so texels stay roughly square.
const MAP_WIDTH := 256
const MAP_HEIGHT := 128

## Cache keyed by finish name. Two entries: "albedo" and, optionally, "emission".
static var _maps: Dictionary = {}

## Cache for `apply_marbled`, keyed by colour (its HTML hex) rather than a
## finish name — every plain colour, not just a fixed set of named skins,
## gets one of these.
static var _marbled_maps: Dictionary = {}


## Applies `skin` to a material already carrying its flat albedo colour.
## A skin with no `finish` is left exactly as it was.
static func apply(material: StandardMaterial3D, skin: Dictionary) -> void:
	var finish := String(skin.get("finish", ""))
	if finish == "":
		return

	var maps := _maps_for(finish, skin)
	if maps.is_empty():
		return

	# White albedo under the texture: the pattern already carries the skin's
	# colours, and tinting it by the base colour would mud every one of them.
	material.albedo_color = Color.WHITE
	material.albedo_texture = maps["albedo"]
	material.metallic = float(skin.get("metallic", 0.1))
	material.roughness = float(skin.get("roughness", 0.25))

	if maps.has("emission"):
		material.emission_enabled = true
		# White, for the same reason as the albedo: the map is coloured.
		material.emission = Color.WHITE
		material.emission_texture = maps["emission"]
		# ADD rather than the default MULTIPLY — the veins and the stars are
		# lights in their own right, not a brightening of the albedo under them.
		material.emission_operator = BaseMaterial3D.EMISSION_OP_ADD


## True when the skin paints its own emission, so `marble.gd` knows not to
## overwrite it with the player's flat identification glow.
static func has_emission(skin: Dictionary) -> bool:
	var finish := String(skin.get("finish", ""))
	if finish == "":
		return false
	return _maps_for(finish, skin).has("emission")


static func _maps_for(finish: String, skin: Dictionary) -> Dictionary:
	if _maps.has(finish):
		return _maps[finish]

	var maps := {}
	match finish:
		"cats_eye":
			maps["albedo"] = _texture(_paint_cats_eye(skin))
		"sunburst":
			maps["albedo"] = _texture(_paint_sunburst(skin))
		"galaxy":
			var galaxy := _paint_galaxy(skin)
			maps["albedo"] = _texture(galaxy[0])
			maps["emission"] = _texture(galaxy[1])
		"magma":
			var magma := _paint_magma(skin)
			maps["albedo"] = _texture(magma[0])
			maps["emission"] = _texture(magma[1])
		"chrome":
			maps["albedo"] = _texture(_paint_chrome(skin))
		"stormcell":
			var storm := _paint_stormcell(skin)
			maps["albedo"] = _texture(storm[0])
			maps["emission"] = _texture(storm[1])
		"quicksilver":
			# Same generator as `chrome`, under its own finish name and cache
			# entry — the cache below is keyed by finish string alone, so two
			# skins sharing "chrome" would silently bake one skin's `ribbon`
			# over the other's. `marble.gd` retints this one's ALBEDO every
			# frame by speed; the static bands painted here are its rest state.
			maps["albedo"] = _texture(_paint_chrome(skin))
		_:
			push_warning("Unknown marble skin finish: %s" % finish)
			return {}

	_maps[finish] = maps
	return maps


## The look every marble without a shop `finish` gets: a swirl of the same
## colour, lighter and darker, instead of one flat sphere. Plain colours (the
## free default skin, every opponent) used to go straight to `marble.gd`'s
## flat `albedo_color`, which read as too uniform next to the elaborate skins
## rolling beside it.
static func apply_marbled(material: StandardMaterial3D, colour: Color) -> void:
	material.albedo_color = Color.WHITE
	material.albedo_texture = _texture(_marbled_maps_for(colour))


static func _marbled_maps_for(colour: Color) -> Image:
	var key := colour.to_html(false)
	if _marbled_maps.has(key):
		return _marbled_maps[key]

	var image := _paint_marbled(colour)
	_marbled_maps[key] = image
	return image


## Two noise fields at different scales swirled around the same hue: a broad
## one for the sweeping twist, a finer one layered in so the swirl has grain
## rather than reading as a smooth gradient. Seeded from the colour itself so
## the same opponent colour always paints the same swirl, and different
## opponents don't all share one pattern.
static func _paint_marbled(colour: Color) -> Image:
	var image := _blank()
	var seed_value := int(colour.to_rgba32())
	var swirl := _noise(seed_value, 1.6, 3)
	var grain := _noise(seed_value + 97, 4.5, 2)
	# Subtle on purpose — this is the base look every marble gets, not a shop
	# skin meant to stand out. The old 0.4/0.35 swing read as a much louder
	# pattern than a "faint marbling" was meant to be.
	var light := colour.lightened(0.16)
	var dark := colour.darkened(0.14)

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var dir := _direction(u, v)
			var t := swirl.get_noise_3dv(dir) * 0.7 + grain.get_noise_3dv(dir) * 0.3
			t = clampf(t * 0.5 + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, dark.lerp(light, t))
	return image


static func _texture(image: Image) -> ImageTexture:
	return ImageTexture.create_from_image(image)


static func _blank() -> Image:
	return Image.create(MAP_WIDTH, MAP_HEIGHT, false, Image.FORMAT_RGB8)


## The direction a texel faces on the sphere. `SphereMesh` runs u around the
## equator and v from the north pole down, so noise sampled through this is
## continuous across the seam instead of tearing at it.
static func _direction(u: float, v: float) -> Vector3:
	var theta := u * TAU
	var phi := v * PI
	return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))


## The tone the pattern is painted over. Usually the skin's own `colour`, but a
## skin whose ball is nearly black — the galaxy, the basalt — needs a brighter
## `colour` than that: the HUD swatch and the marble's trail are flat single
## colours and cannot show a pattern. Those skins carry a separate `backdrop`.
static func _backdrop(skin: Dictionary, fallback: Color) -> Color:
	return skin.get("backdrop", skin.get("colour", fallback))


static func _noise(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	return noise


# --- Generators ---------------------------------------------------------------


## The toy every child pictures when they hear "marble": a milky glass ball with
## a twisted ribbon of colour suspended in the middle of it.
##
## The ribbon is a band around the equator whose centre line is pushed up and
## down twice per turn, which is what gives the vane its wrung look as the ball
## rolls. Inside the band, position across it picks one of the three ribbon
## colours, so the vane is striped rather than a single slab.
static func _paint_cats_eye(skin: Dictionary) -> Image:
	var image := _blank()
	var glass := _backdrop(skin, Color(0.94, 0.94, 0.92))
	var ribbon: Array = skin.get("ribbon", [Color.RED, Color.WHITE, Color.BLUE])
	# Half-width of the vane, in v. Wide enough to stay readable at 70px across.
	const HALF := 0.13
	# How far the vane's centre line wanders from the equator.
	const TWIST := 0.16

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var centre := 0.5 + TWIST * sin(u * TAU * 2.0)
			var across := (v - centre) / HALF
			var colour := glass
			if absf(across) < 1.0:
				# -1..1 across the vane -> one of the ribbon stripes.
				var stripe := int((across + 1.0) * 0.5 * ribbon.size())
				colour = ribbon[clampi(stripe, 0, ribbon.size() - 1)]
				# Glass over the vane's edges, so it looks suspended inside the
				# ball rather than painted onto its surface.
				colour = colour.lerp(glass, smoothstep(0.7, 1.0, absf(across)))
			image.set_pixel(x, y, colour)
	return image


## A pinwheel of wedges with an ink line down every seam — the comic-book
## treatment the home screen and the course artwork are drawn in, wrapped around
## a ball. The wedges are also what make the spin read: a rolling marble
## flickers between colours instead of staying one flat disc.
static func _paint_sunburst(skin: Dictionary) -> Image:
	var image := _blank()
	var wedge: Array = skin.get("ribbon", [Color.ORANGE, Color.WHITE])
	var ink: Color = skin.get("ink", Color(0.08, 0.04, 0.02))
	var cap: Color = skin.get("cap", wedge[0])
	const WEDGES := 12
	## Half-width of the seam, as a fraction of one wedge.
	const SEAM := 0.055
	## Where the polar cap starts, in v from either pole.
	const CAP := 0.14

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		var polar := minf(v, 1.0 - v)
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var position := u * WEDGES
			var into_wedge := fmod(position, 1.0)
			var colour: Color = wedge[int(position) % wedge.size()]
			# Seam: distance to the nearer wedge boundary, in wedge widths.
			if minf(into_wedge, 1.0 - into_wedge) < SEAM:
				colour = ink
			if polar < CAP:
				# Cap, with its own ink ring where it meets the wedges. Without
				# it twelve wedges converge on a point and the pole is mush.
				colour = ink if polar > CAP - 0.025 else cap
			image.set_pixel(x, y, colour)
	return image


## Deep space: a nebula of drifting colour, dusted with stars.
##
## Returns [albedo, emission]. Only the clouds and the stars emit — the dark
## field between them stays dark, which is what keeps this from reading as one
## plain glowing ball in the canyon's shadowed half.
static func _paint_galaxy(skin: Dictionary) -> Array:
	var albedo := _blank()
	var emission := _blank()
	var deep := _backdrop(skin, Color(0.07, 0.05, 0.16))
	var clouds: Array = skin.get("ribbon", [Color(0.45, 0.20, 0.75), Color(0.20, 0.55, 0.85)])

	var nebula := _noise(7301, 1.5, 4)
	# A second, coarser field decides which cloud colour wins where, so the
	# nebula is not one hue smeared at two densities.
	var tint := _noise(9187, 0.7, 2)
	var stars := _noise(4457, 8.5, 1)

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var dir := _direction(u, v)

			var density := clampf((nebula.get_noise_3dv(dir) + 0.35) * 1.5, 0.0, 1.0)
			# Squared: a linear ramp fills the whole ball with faint haze and
			# nothing reads as a cloud with an edge.
			density *= density
			var mix := clampf(tint.get_noise_3dv(dir) * 1.5 + 0.5, 0.0, 1.0)
			var cloud: Color = (clouds[0] as Color).lerp(clouds[1], mix)

			var colour := deep.lerp(cloud, density)
			var glow := cloud * (density * 0.55)

			# Stars are the sparse peaks of a high-frequency field rather than a
			# per-texel random roll, so each one covers a few texels and survives
			# the texture being filtered down.
			var star := stars.get_noise_3dv(dir)
			if star > 0.70:
				var brightness := smoothstep(0.70, 0.84, star)
				colour = colour.lerp(Color(1.0, 0.97, 0.9), brightness)
				glow += Color(1.0, 0.97, 0.9) * brightness

			albedo.set_pixel(x, y, colour)
			emission.set_pixel(x, y, glow.clamp())
	return [albedo, emission]


## A crust of cooled basalt with the melt still showing through the cracks.
##
## Returns [albedo, emission]. The veins are the ridges of a noise field — the
## places where it crosses zero — which is what gives them the branching,
## closing-up look of a cooling crust rather than of drawn-on stripes. The
## player's emission pulse (marble.gd) then breathes through the veins alone.
static func _paint_magma(skin: Dictionary) -> Array:
	var albedo := _blank()
	var emission := _blank()
	var crust := _backdrop(skin, Color(0.12, 0.10, 0.11))
	var heat: Array = skin.get("ribbon", [Color(0.95, 0.35, 0.06), Color(1.0, 0.85, 0.35)])

	var cracks := _noise(2213, 1.0, 3)
	var mottle := _noise(6091, 2.5, 2)

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var dir := _direction(u, v)

			# Near zero is the middle of a crack; away from it is cold crust.
			var ridge := absf(cracks.get_noise_3dv(dir))
			var vein := 1.0 - smoothstep(0.012, 0.075, ridge)

			# Cold rock is not one flat grey; the grain is what stops the unlit
			# half of the ball reading as a hole.
			var grain := mottle.get_noise_3dv(dir) * 0.06
			var colour := Color(
				clampf(crust.r + grain, 0.0, 1.0),
				clampf(crust.g + grain, 0.0, 1.0),
				clampf(crust.b + grain, 0.0, 1.0)
			)

			# Hottest along the centre of the vein, cooling towards its edges.
			var molten: Color = (heat[0] as Color).lerp(heat[1], smoothstep(0.45, 1.0, vein))
			colour = colour.lerp(molten, vein)
			albedo.set_pixel(x, y, colour)
			emission.set_pixel(x, y, (molten * vein * 0.9).clamp())
	return [albedo, emission]


## A storm-grey ball veined with lightning rather than lava — structurally the
## same generator as `_paint_magma` (a noise field's zero-crossings are the
## veins), recoloured cold and paired with `marble.gd`'s "impact_flash"
## reactive behaviour: this skin's veins hold at a dim resting glow between
## hits and spike bright on one, instead of magma's constant simmer.
##
## Returns [albedo, emission].
static func _paint_stormcell(skin: Dictionary) -> Array:
	var albedo := _blank()
	var emission := _blank()
	var cloud := _backdrop(skin, Color(0.10, 0.12, 0.18))
	var bolt: Array = skin.get("ribbon", [Color(0.55, 0.85, 1.0), Color(1.0, 1.0, 0.95)])

	var cracks := _noise(3583, 1.3, 3)
	var mottle := _noise(8117, 2.2, 2)

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var dir := _direction(u, v)

			var ridge := absf(cracks.get_noise_3dv(dir))
			# Thinner than magma's — a hairline crack of lightning reads better
			# than a lava-wide one, and it is meant to sit dim until the flash.
			var vein := 1.0 - smoothstep(0.008, 0.05, ridge)

			var grain := mottle.get_noise_3dv(dir) * 0.05
			var colour := Color(
				clampf(cloud.r + grain, 0.0, 1.0),
				clampf(cloud.g + grain, 0.0, 1.0),
				clampf(cloud.b + grain, 0.0, 1.0)
			)

			var charge: Color = (bolt[0] as Color).lerp(bolt[1], smoothstep(0.5, 1.0, vein))
			colour = colour.lerp(charge, vein * 0.7)
			albedo.set_pixel(x, y, colour)
			# Dimmer baseline than magma's own 0.9 — `marble.gd` holds this
			# skin's emission energy low at rest and only lets it read this
			# bright for the moment the flash decays through it.
			emission.set_pixel(x, y, (charge * vein * 0.6).clamp())
	return [albedo, emission]


## Polished steel.
##
## Under `gl_compatibility` a metallic sphere has only the sky to reflect, and
## in the Home preview — which has no sky at all, just flat ambient — it would
## come out as a grey ball. So the highlights are painted: a bright band where
## the sky would be, a dark one where the ground would be, and a tight horizon
## between them. Real reflection on the course then lands on top of this instead
## of being the only thing carrying the look.
static func _paint_chrome(skin: Dictionary) -> Image:
	var image := _blank()
	var steel := _backdrop(skin, Color(0.78, 0.80, 0.84))
	var bands: Array = skin.get("ribbon", [Color(0.97, 0.98, 1.0), Color(0.22, 0.24, 0.30)])
	var brushing := _noise(5501, 6.0, 2)

	for y in MAP_HEIGHT:
		var v := (float(y) + 0.5) / MAP_HEIGHT
		for x in MAP_WIDTH:
			var u := (float(x) + 0.5) / MAP_WIDTH
			var colour := steel
			# Sky above, ground below, meeting in a tight horizon. `v` runs from
			# the north pole down, so the bright half is the top half.
			colour = colour.lerp(bands[1], smoothstep(0.5, 0.62, v))
			colour = colour.lerp(bands[0], smoothstep(0.46, 0.16, v))
			# Brushed grain, faint enough to be a texture rather than a pattern.
			var grain := brushing.get_noise_3dv(_direction(u, v) * 4.0) * 0.05
			image.set_pixel(x, y, Color(
				clampf(colour.r + grain, 0.0, 1.0),
				clampf(colour.g + grain, 0.0, 1.0),
				clampf(colour.b + grain, 0.0, 1.0)
			))
	return image


# --- Shop swatch --------------------------------------------------------------


## The skin drawn as a lit ball, for the shop's row. A flat `ColorRect` says
## nothing about a skin whose whole point is its pattern, and a strip of the
## equirectangular map is a picture of a texture rather than of a marble.
##
## Cheap by design — it lights the same pixels the material samples, with one
## directional term and a highlight, rather than standing up a `SubViewport` per
## row the way Home does for the single marble it shows.
static func swatch_texture(skin: Dictionary, size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var finish := String(skin.get("finish", ""))
	var flat: Color = skin.get("colour", Color.WHITE)
	var maps := _maps_for(finish, skin) if finish != "" else {"albedo": _texture(_marbled_maps_for(flat))}
	var albedo: Image = maps["albedo"].get_image() if maps.has("albedo") else null
	var glow: Image = maps["emission"].get_image() if maps.has("emission") else null
	var shine := 1.0 - float(skin.get("roughness", 0.25))

	# Roughly the Home preview's raked key light, so a skin sits the same way up
	# in the shop as it does on the marble the player is about to equip.
	var light := Vector3(-0.45, 0.62, 0.64).normalized()
	var highlight := (light + Vector3.BACK).normalized()

	for y in size:
		# +y runs down the image and up the sphere.
		var ny := 1.0 - 2.0 * (float(y) + 0.5) / size
		for x in size:
			var nx := 2.0 * (float(x) + 0.5) / size - 1.0
			var radius := nx * nx + ny * ny
			if radius > 1.0:
				continue
			var normal := Vector3(nx, ny, sqrt(1.0 - radius))

			var base := flat
			var emitted := Color.BLACK
			if albedo != null:
				# The visible face of the ball, read back out of the same
				# equirectangular map the material samples.
				var u := fposmod(atan2(normal.z, normal.x) / TAU, 1.0)
				var v := acos(clampf(normal.y, -1.0, 1.0)) / PI
				var px := clampi(int(u * albedo.get_width()), 0, albedo.get_width() - 1)
				var py := clampi(int(v * albedo.get_height()), 0, albedo.get_height() - 1)
				base = albedo.get_pixel(px, py)
				if glow != null:
					emitted = glow.get_pixel(px, py)

			var lambert := maxf(normal.dot(light), 0.0)
			var lit := base * (0.42 + 0.72 * lambert)
			# One pinpoint, tightened by the finish's own smoothness — it is what
			# says "polished" on the chrome and stays nearly invisible on the
			# basalt.
			var specular := pow(maxf(normal.dot(highlight), 0.0), 12.0)
			lit += Color(1.0, 1.0, 1.0, 0.0) * (specular * shine * 0.7)
			lit += emitted * 0.5

			# A couple of texels of feather at the rim, so the ball is not a
			# jagged disc.
			lit.a = smoothstep(1.0, 1.0 - 2.5 / size, radius)
			image.set_pixel(x, y, lit.clamp())

	return ImageTexture.create_from_image(image)
