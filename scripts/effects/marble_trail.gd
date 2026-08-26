class_name MarbleTrail
extends MeshInstance3D

## A short ribbon left behind the player's marble, in the marble's own colour.
##
## The rim highlight and emission pulse on `marble.gd` were the only in-world
## identification, and neither survives the way the game actually renders: the
## Compatibility renderer has no glow, so emission reads as plain brightness, and
## a rim light is a grazing-angle effect that all but vanishes under the steeply
## pitched camera in `chase_camera.gd`. A trail has none of those problems —
## it is a moving band of colour with real screen area, and it is still readable
## when the marble itself is buried in a pile-up.
##
## Drawn procedurally, like every other visual in the project: Phase 0 has no
## art pipeline, and `cut_marker.gd` is the template for the material.

## How far back the trail reaches, as a number of samples at SAMPLE_INTERVAL.
## Roughly 0.8s — long enough to read as a streak, short enough that it does not
## draw a map of the last corner across the track.
const MAX_SAMPLES := 24
const SAMPLE_INTERVAL := 1.0 / 30.0
## A marble sitting still would otherwise pile every sample onto the same point
## and collapse the ribbon into a flickering blob.
const MIN_SAMPLE_DISTANCE := 0.15
## Width at the head, as a fraction of the marble's radius. Narrower than the
## marble so the ribbon reads as trailing from it rather than as a second body.
const HEAD_WIDTH_RATIO := 1.2
const MAX_ALPHA := 0.7

var _colour: Color
var _radius: float
var _samples: PackedVector3Array = PackedVector3Array()
var _sample_age := 0.0
var _mesh: ImmediateMesh
## Overridable by a shop trail style (player_profile.gd's TRAILS); otherwise
## the plain ribbon this always was.
var _width_ratio := HEAD_WIDTH_RATIO
var _alpha := MAX_ALPHA
var _sparks: CPUParticles3D
var _bubbles: CPUParticles3D
var _confetti: CPUParticles3D
## Drives the "Rainbow" style's hue cycle. Wall-clock time rather than a
## sample count, so the cycle keeps the same speed whether the marble is
## sprinting or crawling.
var _rainbow := false
var _time := 0.0
## One full hue cycle per second along the marble's own position in it —
## fast enough to read as "rainbow" rather than a slow colour drift.
const RAINBOW_CYCLE_SECONDS := 1.4
## A bright near-white filament drawn over the ribbon's centre, Rocket
## League "plasma"-style: the coloured body reads as a sheath around a hot core
## rather than one flat band.
var _core := false
## Renders the ribbon as separated blocks instead of one continuous band —
## Rocket League's blocky "Structure"-style trails.
var _segmented := false
## Longest run of samples drawn together, and the gap between runs, in sample
## counts. 4-on/2-off reads as distinct blocks without the ribbon dissolving
## into confetti of its own at 30 samples/second.
const SEGMENT_ON := 4
const SEGMENT_OFF := 2


## `style` is a TRAILS entry from player_profile.gd, or `{}` for the free
## default — the plain ribbon in the marble's own colour, exactly as before.
static func create(colour: Color, radius: float, style: Dictionary = {}) -> MarbleTrail:
	var trail := MarbleTrail.new()
	trail.name = "MarbleTrail"
	trail._colour = style.get("colour", colour)
	trail._radius = radius
	trail._width_ratio = float(style.get("width_ratio", HEAD_WIDTH_RATIO))
	trail._alpha = float(style.get("alpha", MAX_ALPHA))
	trail._rainbow = bool(style.get("rainbow", false))
	trail._core = bool(style.get("core", false))
	trail._segmented = bool(style.get("segmented", false))
	trail._build()
	if bool(style.get("sparkle", false)):
		trail._build_sparks()
	if bool(style.get("bubbles", false)):
		trail._build_bubbles()
	if bool(style.get("confetti", false)):
		trail._build_confetti()
	return trail


func _build() -> void:
	# The marble is a RigidBody3D sphere that spins fast. Without this the
	# ribbon inherits that rotation and whips around the marble instead of
	# lying in the world where it was laid down.
	top_level = true

	_mesh = ImmediateMesh.new()
	mesh = _mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# The fade along the ribbon lives in the vertex colours, so one material
	# covers the whole strip rather than a gradient texture per marble.
	material.vertex_color_use_as_albedo = true
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## `CPUParticles3D` draws nothing per particle until it is given a `Mesh` — the
## node's own emission/physics properties (amount, velocity, colour...) are
## simulated regardless, which is why an unmeshed emitter emits invisibly
## instead of failing loudly. A small unshaded sphere, coloured the same way
## the ribbon material is (vertex colour as albedo), so `.color` and
## `.hue_variation_*` on the emitter actually show up instead of being lit away
## under this renderer's flat ambient.
static func _particle_mesh(radius: float) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	sphere.material = material
	return sphere


## Shared setup for every particle emitter here: meshed (see `_particle_mesh`)
## and with `local_coords` off, so a mote stays where it was laid down in the
## world as the emitter itself moves on to the next sample, instead of being
## dragged along behind the marble in the emitter's own local space.
##
## `visibility_aabb` defaults to a zero-size box — CPUParticles3D does not
## grow it to fit the emission shape the way one might expect, so with no
## explicit box the renderer's own culling clips almost every particle before
## it reaches the screen, regardless of `mesh` or `emitting`. This one is
## sized generously against the small distances and short lifetimes any style
## here actually uses.
func _configure_particles(particles: CPUParticles3D, radius: float) -> void:
	particles.mesh = _particle_mesh(radius)
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-2.0, -2.0, -2.0), Vector3(4.0, 4.0, 4.0))
	add_child(particles)


## A handful of bright motes shed from the ribbon, for the "Ember Sparks" trail
## style. Built lazily — most styles never call this — as a one-shot burst
## re-triggered from the head position each time the ribbon advances, rather
## than a continuous emitter, so the sparks read as coming off the marble
## instead of as a haze following it around.
func _build_sparks() -> void:
	_sparks = CPUParticles3D.new()
	_sparks.name = "Sparks"
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.amount = 8
	_sparks.lifetime = 0.4
	_sparks.explosiveness = 1.0
	_sparks.direction = Vector3.UP
	_sparks.spread = 180.0
	_sparks.gravity = Vector3(0, -2.0, 0)
	_sparks.initial_velocity_min = 0.5
	_sparks.initial_velocity_max = 1.3
	# `mesh` size (below) and `scale_amount` both multiply the final size — the
	# earlier 0.20-radius mesh times a ~0.13 scale landed at roughly 1% of the
	# marble's own diameter, unreadable at any real race-camera distance.
	# `scale_amount` is left near 1 here so the mesh size below IS the size.
	_sparks.scale_amount_min = 0.85
	_sparks.scale_amount_max = 1.15
	_sparks.color = _colour.lightened(0.5)
	# Spawned on the marble's own surface rather than at its centre point — at
	# this lifetime and velocity a spark spawned at the centre never outruns
	# the marble's own (opaque) body before it expires, so it burns its whole
	# life hidden inside the sphere it was meant to be flying off of.
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	_sparks.emission_sphere_radius = _radius
	_configure_particles(_sparks, _radius * 0.16)


## A steady stream of drifting motes for the "Bubbles" trail style — unlike
## `_sparks`, this emits continuously rather than as a burst per sample, and
## floats upward slowly instead of scattering, so it reads as buoyant bubbles
## being left in the marble's wake rather than sparks thrown off by it.
func _build_bubbles() -> void:
	_bubbles = CPUParticles3D.new()
	_bubbles.name = "Bubbles"
	_bubbles.emitting = false
	_bubbles.amount = 16
	_bubbles.lifetime = 1.0
	_bubbles.direction = Vector3.UP
	_bubbles.spread = 20.0
	_bubbles.gravity = Vector3(0, 0.6, 0)
	_bubbles.initial_velocity_min = 0.2
	_bubbles.initial_velocity_max = 0.5
	_bubbles.scale_amount_min = 0.8
	_bubbles.scale_amount_max = 1.2
	_bubbles.color = Color(_colour.r, _colour.g, _colour.b, 0.55)
	# Same reasoning as `_sparks`: spawned on the marble's surface so they are
	# never born hidden inside its own opaque body, and sized so `mesh` sets
	# the real size rather than being shrunk again by `scale_amount`.
	_bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	_bubbles.emission_sphere_radius = _radius
	_configure_particles(_bubbles, _radius * 0.16)


## A shower of randomly-hued flecks for the "Confetti" trail style — a
## continuous emitter like `_bubbles`, but `hue_variation` gives every particle
## its own colour instead of all of them sharing the ribbon's, and gravity
## pulls them down and out to the sides like scattering paper rather than
## floating them up like bubbles.
func _build_confetti() -> void:
	_confetti = CPUParticles3D.new()
	_confetti.name = "Confetti"
	_confetti.emitting = false
	_confetti.amount = 32
	_confetti.lifetime = 0.8
	_confetti.direction = Vector3.UP
	_confetti.spread = 130.0
	_confetti.gravity = Vector3(0, -1.4, 0)
	_confetti.initial_velocity_min = 1.0
	_confetti.initial_velocity_max = 2.2
	_confetti.angular_velocity_min = -360.0
	_confetti.angular_velocity_max = 360.0
	_confetti.scale_amount_min = 0.8
	_confetti.scale_amount_max = 1.3
	# `hue_variation` shifts a colour's *hue*: a base of white has no saturation
	# for it to act on, so every particle stayed white regardless of the spread
	# below. A fully saturated base gives it a hue to actually rotate away from.
	_confetti.color = Color.from_hsv(0.0, 0.85, 1.0)
	_confetti.hue_variation_min = -0.5
	_confetti.hue_variation_max = 0.5
	_confetti.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	_confetti.emission_sphere_radius = _radius
	_configure_particles(_confetti, _radius * 0.13)


## Drops the whole ribbon. Called when the marble is reset or is not racing, so
## a fresh round does not open with a streak stretching back to where the
## previous round's marble happened to be.
func clear() -> void:
	_samples.clear()
	_sample_age = 0.0
	_mesh.clear_surfaces()
	if _sparks != null:
		_sparks.emitting = false
	if _bubbles != null:
		_bubbles.emitting = false
	if _confetti != null:
		_confetti.emitting = false


func _process(delta: float) -> void:
	var marble := get_parent() as Marble
	if marble == null:
		return

	if marble.state != Marble.State.RACING:
		if not _samples.is_empty():
			clear()
		return

	_time += delta
	if _bubbles != null:
		_bubbles.emitting = true
		_bubbles.global_position = marble.global_position
	if _confetti != null:
		_confetti.emitting = true
		_confetti.global_position = marble.global_position

	_sample_age += delta
	if _sample_age >= SAMPLE_INTERVAL:
		_sample_age = 0.0
		_add_sample(marble.global_position)

	_rebuild()


func _add_sample(at: Vector3) -> void:
	if not _samples.is_empty() and _samples[_samples.size() - 1].distance_to(at) < MIN_SAMPLE_DISTANCE:
		return

	_samples.append(at)
	if _samples.size() > MAX_SAMPLES:
		_samples.remove_at(0)

	if _sparks != null:
		_sparks.global_position = at
		# `restart()` alone does not turn emission back on for a one-shot
		# emitter that started life with `emitting = false` — without this it
		# silently never fires a single burst.
		_sparks.emitting = true
		_sparks.restart()


## Rebuilt every frame rather than appended to: the ribbon has to face the
## camera, and the camera moves even when the marble does not.
func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var camera_position := camera.global_position
	var head_width := _radius * _width_ratio
	var last := _samples.size() - 1

	# Collected before drawing: `surface_end` on an empty surface is an error,
	# and degenerate segments — two samples on top of each other, or one the
	# camera happens to be looking straight down the length of — drop out here.
	var strip: Array = []
	for i in _samples.size():
		var point := _samples[i]
		# The direction the ribbon runs in at this point, taken from its
		# neighbours so the band stays smooth through a corner instead of kinking.
		var previous := _samples[maxi(i - 1, 0)]
		var following := _samples[mini(i + 1, last)]
		var along := following - previous
		if along.is_zero_approx():
			continue

		var side := along.cross(camera_position - point)
		if side.is_zero_approx():
			continue
		side = side.normalized()

		# 0 at the oldest sample, 1 at the marble: the ribbon is widest and most
		# opaque where it leaves the marble, and dies out behind it.
		var t := float(i) / float(last)
		var half := head_width * t * 0.5
		var tint := _colour
		if _rainbow:
			# Offset by `i` rather than just time, so the hue is stationary
			# along the ribbon's length instead of flashing everywhere at once.
			var hue := fposmod(_time / RAINBOW_CYCLE_SECONDS - float(i) * 0.05, 1.0)
			tint = Color.from_hsv(hue, 0.85, 1.0)
		strip.append([point, side * half, Color(tint.r, tint.g, tint.b, _alpha * t)])

	if strip.size() < 2:
		return

	# Not segmented: the whole ribbon is one run. Segmented: broken into
	# SEGMENT_ON-sample blocks with SEGMENT_OFF-sample gaps, each its own
	# triangle strip — a single strip has no way to lift the pen mid-band.
	var runs: Array = []
	if _segmented:
		var i := 0
		while i < strip.size():
			var run: Array = strip.slice(i, mini(i + SEGMENT_ON, strip.size()))
			if run.size() >= 2:
				runs.append(run)
			i += SEGMENT_ON + SEGMENT_OFF
	else:
		runs.append(strip)

	for run: Array in runs:
		_draw_strip(run, 1.0, 0.0)

	# The hot core: a second, narrower pass straight down the centre of the
	# same runs, faded toward white — drawn after so it sits on top of the
	# coloured body rather than being covered by it.
	if _core:
		for run: Array in runs:
			_draw_strip(run, 0.35, 0.6)


## Draws one triangle strip from `strip` entries. `width_scale` narrows the
## band around its own centre line; `whiten` lerps its colour toward white,
## used together for the "core" pass over an already-drawn body.
func _draw_strip(strip: Array, width_scale: float, whiten: float) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for entry: Array in strip:
		var point: Vector3 = entry[0]
		var offset: Vector3 = entry[1] * width_scale
		var colour: Color = entry[2]
		if whiten > 0.0:
			colour = colour.lerp(Color(1.0, 1.0, 1.0, colour.a), whiten)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(point - offset)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(point + offset)
	_mesh.surface_end()


# --- Shop swatch --------------------------------------------------------------


## A flat streak in `style`'s colours, for the shop's trail row. Painted
## directly rather than by spawning a real `MarbleTrail` and photographing it —
## the shop has no track for a marble to lay one down on.
static func swatch_texture(style: Dictionary, fallback_colour: Color, size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var colour: Color = style.get("colour", fallback_colour)
	var alpha := float(style.get("alpha", MAX_ALPHA))
	var width_ratio := float(style.get("width_ratio", HEAD_WIDTH_RATIO))
	var half_width := size * 0.09 * (width_ratio / HEAD_WIDTH_RATIO)

	var rainbow := bool(style.get("rainbow", false))
	var core := bool(style.get("core", false))
	var segmented := bool(style.get("segmented", false))

	# A diagonal streak, thin tail to wide head, matching how the ribbon itself
	# tapers away from the marble in `_rebuild`.
	for x in size:
		if segmented and (x / 3) % 2 == 1:
			continue ## Blocks with gaps, echoing `_rebuild`'s SEGMENT_ON/OFF runs.

		var t := float(x) / float(size - 1)
		var centre_y := size * (0.8 - 0.6 * t)
		var half := half_width * (0.2 + 0.8 * t)
		var top := int(centre_y - half)
		var bottom := int(centre_y + half)
		# A static rainbow streak reads more like the moving one than any single
		# frozen frame would: the whole cycle laid out along the streak's length.
		var tint := Color.from_hsv(t, 0.85, 1.0) if rainbow else colour
		for y in range(maxi(top, 0), mini(bottom, size)):
			var pixel := tint
			if core and absf(y - centre_y) < half * 0.35:
				pixel = tint.lerp(Color.WHITE, 0.6)
			image.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, alpha * t))

	if bool(style.get("bubbles", false)):
		var bubble := Color(colour.r, colour.g, colour.b, 0.55)
		var centres := [
			Vector2(size * 0.30, size * 0.40),
			Vector2(size * 0.50, size * 0.68),
			Vector2(size * 0.68, size * 0.24),
		]
		var radii := [size * 0.07, size * 0.05, size * 0.04]
		for j in centres.size():
			var centre: Vector2 = centres[j]
			var radius: int = int(radii[j])
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					if Vector2(dx, dy).length() > radius:
						continue
					var px := int(centre.x) + dx
					var py := int(centre.y) + dy
					if px >= 0 and px < size and py >= 0 and py < size:
						image.set_pixel(px, py, bubble)

	if bool(style.get("confetti", false)):
		var hues := [0.02, 0.33, 0.6, 0.83, 0.95]
		var confetti_positions := [
			Vector2(size * 0.28, size * 0.30),
			Vector2(size * 0.44, size * 0.62),
			Vector2(size * 0.58, size * 0.22),
			Vector2(size * 0.70, size * 0.50),
			Vector2(size * 0.80, size * 0.72),
		]
		for j in confetti_positions.size():
			var fleck: Color = Color.from_hsv(hues[j], 0.8, 1.0)
			var centre: Vector2 = confetti_positions[j]
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var px := int(centre.x) + dx
					var py := int(centre.y) + dy
					if px >= 0 and px < size and py >= 0 and py < size:
						image.set_pixel(px, py, fleck)

	if bool(style.get("sparkle", false)):
		var spark := colour.lightened(0.4)
		var positions := [
			Vector2(size * 0.35, size * 0.55),
			Vector2(size * 0.55, size * 0.30),
			Vector2(size * 0.72, size * 0.62),
		]
		for centre: Vector2 in positions:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var px := int(centre.x) + dx
					var py := int(centre.y) + dy
					if px >= 0 and px < size and py >= 0 and py < size:
						image.set_pixel(px, py, spark)

	return ImageTexture.create_from_image(image)
