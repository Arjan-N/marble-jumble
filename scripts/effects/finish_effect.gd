class_name FinishEffect
extends Node3D

## The player's finish, detonated.
##
## Rocket League's goal explosion is the reference: the moment you score, the
## thing you have been steering for a minute turns into a shower you did not
## have to earn twice. This is that moment for a marble crossing the line, and
## it is deliberately the loudest thing in the game — PROJECT.md section 8 asks
## for restraint everywhere else, and this is the exception that pays for the
## rule.
##
## What it is **not**:
##
## - It is not a camera effect. No cut, no shake, no `time_scale`. The chase
##   rig's hand-off to `FinishZone.spectate_focus` is the round's framing and it
##   stays exactly as it is; everything below happens in the world, in front of
##   whatever camera is already looking at it.
## - It is not the marble's death. Unlike the ball it is modelled on, the marble
##   rolls out through the runoff as it always has — `FinishZone`'s whole
##   slowdown ramp assumes a live body past the line.
## - It is not tied to a skin or a trail. `PlayerProfile.FINISHES` is its own
##   catalogue, and any effect combines with any skin and any trail.
##
## Built procedurally, like `MarbleTrail` and `ComicPopup`, because Phase 0 has
## no art pipeline to bring a particle asset through.

## Total node lifetime. Longer than anything visible, so a late shard or a
## fading ring is never cut off by the node freeing itself out from under it.
const LIFETIME := 2.6

## The headline burst. Loud by design: an order of magnitude more particles than
## `FinishZone`'s per-finisher fleck, thrown far enough to leave the marble.
const CORE_AMOUNT := 150
const CORE_LIFETIME := 1.1
const CORE_SPEED_MIN := 5.0
const CORE_SPEED_MAX := 13.0

## The shockwave ring: a flat torus scaled outwards and faded off. A second one
## behind the first reads as a detonation rather than a bubble.
const RING_SECONDS := 0.55
const RING_RADIUS := 3.2
const RING_DELAY := 0.16

## The flash. An `OmniLight3D` rather than a screen overlay, so it lights the
## runoff and the marbles standing in it and stays a thing in the world.
const FLASH_SECONDS := 0.22
const FLASH_RANGE := 18.0

## Secondary shower, for styles carrying `mortar`: the first burst goes up, this
## one opens above it a beat later.
const MORTAR_DELAY := 0.45
const MORTAR_AMOUNT := 60
const MORTAR_HEIGHT := 3.4

var _style: Dictionary = {}
var _colour := Color.WHITE
var _age := 0.0

var _rings: Array[MeshInstance3D] = []
var _flash: OmniLight3D
var _flash_energy := 0.0
var _mortar: CPUParticles3D
var _mortar_fired := false


## `style` is an entry from `PlayerProfile.FINISHES`; `colour` is the marble's
## own, used wherever the style does not name one of its own — the arrangement
## `MarbleTrail` uses, so a skin and an effect can be mixed freely without the
## pair ever clashing by construction.
static func create(style: Dictionary, colour: Color) -> FinishEffect:
	var effect := FinishEffect.new()
	effect.name = "FinishEffect"
	effect._style = style
	effect._colour = style.get("colour", colour)
	return effect


func _ready() -> void:
	_build_core()
	if float(_style.get("ring", 0.0)) > 0.0:
		_build_rings()
	if float(_style.get("flash", 0.0)) > 0.0:
		_build_flash()
	if bool(_style.get("mortar", false)):
		_build_mortar()


# --- Pieces -------------------------------------------------------------------


## The radial burst every style has, scaled by the style's `power`.
func _build_core() -> void:
	var power := float(_style.get("power", 1.0))
	var core := _emitter("FinishCore", int(CORE_AMOUNT * power), CORE_LIFETIME)
	core.direction = Vector3.UP
	# Not a full sphere: a little upward bias keeps the shower over the track
	# instead of half of it inside the deck.
	core.spread = 88.0
	core.initial_velocity_min = CORE_SPEED_MIN * power
	core.initial_velocity_max = CORE_SPEED_MAX * power
	core.gravity = Vector3(0.0, -11.0, 0.0)
	core.scale_amount_min = 0.5 * power
	core.scale_amount_max = 1.0 * power
	core.damping_min = 1.0
	core.damping_max = 3.0
	_tint(core)
	add_child(core)
	core.emitting = true
	core.restart()

	if bool(_style.get("shards", false)):
		_build_shards(power)


## Long, slow, heavy pieces thrown alongside the flecks. They outlive the core
## burst, so the effect has a tail instead of stopping all at once.
func _build_shards(power: float) -> void:
	var shards := _emitter("FinishShards", int(22 * power), 1.9)
	shards.direction = Vector3.UP
	shards.spread = 55.0
	shards.initial_velocity_min = 7.0 * power
	shards.initial_velocity_max = 15.0 * power
	shards.gravity = Vector3(0.0, -14.0, 0.0)
	shards.scale_amount_min = 1.0
	shards.scale_amount_max = 1.8
	shards.angular_velocity_min = -420.0
	shards.angular_velocity_max = 420.0
	shards.mesh = _particle_mesh(Vector3(0.06, 0.24, 0.06))
	_tint(shards)
	add_child(shards)
	shards.emitting = true
	shards.restart()


## Flat expanding rings, sitting on the deck rather than floating over it: a
## shockwave that clips into the runoff floor reads as travelling along it.
func _build_rings() -> void:
	var count := 2 if float(_style.get("ring", 0.0)) >= 1.5 else 1
	for i in count:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.93
		torus.outer_radius = 1.0
		torus.rings = 72
		torus.ring_segments = 6

		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = _colour.lightened(0.4)
		torus.material = material

		var ring := MeshInstance3D.new()
		ring.name = "FinishRing%d" % i
		ring.mesh = torus
		# A hair above the deck: co-planar with it and the two z-fight.
		ring.position = Vector3(0.0, 0.12, 0.0)
		ring.scale = Vector3.ZERO
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)


func _build_flash() -> void:
	_flash_energy = float(_style.get("flash", 0.0)) * 9.0
	_flash = OmniLight3D.new()
	_flash.name = "FinishFlash"
	_flash.light_color = _colour.lightened(0.55)
	_flash.light_energy = _flash_energy
	_flash.omni_range = FLASH_RANGE
	# One bright frame of shadow work on a light that lives a fifth of a second
	# buys nothing and costs a shadow map on every marble in the runoff.
	_flash.shadow_enabled = false
	_flash.position = Vector3(0.0, 1.2, 0.0)
	add_child(_flash)


## Built now, fired later — `CPUParticles3D` is cheap to hold, and building it
## at the moment it is needed would land the allocation inside the effect.
func _build_mortar() -> void:
	_mortar = _emitter("FinishMortar", MORTAR_AMOUNT, 1.4)
	_mortar.direction = Vector3.UP
	_mortar.spread = 180.0
	_mortar.initial_velocity_min = 3.0
	_mortar.initial_velocity_max = 8.0
	_mortar.gravity = Vector3(0.0, -7.5, 0.0)
	_mortar.scale_amount_min = 0.8
	_mortar.scale_amount_max = 1.5
	_mortar.damping_min = 0.5
	_mortar.damping_max = 2.0
	_mortar.position = Vector3(0.0, MORTAR_HEIGHT, 0.0)
	_tint(_mortar)
	add_child(_mortar)


# --- Shared emitter plumbing --------------------------------------------------


func _emitter(node_name: String, amount: int, lifetime: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = node_name
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = maxi(amount, 1)
	particles.lifetime = lifetime
	# `local_coords` off and an explicit `visibility_aabb`, for the reason
	# `MarbleTrail._configure_particles` writes down: without the box the
	# renderer culls almost everything before it is drawn.
	particles.local_coords = false
	particles.visibility_aabb = AABB(
		Vector3(-16.0, -16.0, -16.0), Vector3(32.0, 32.0, 32.0)
	)
	particles.mesh = _particle_mesh(Vector3(0.075, 0.075, 0.075))
	return particles


## Colour, either one hue or the whole wheel. `color_initial_ramp` is what makes
## a per-particle hue possible on `CPUParticles3D`; sampled once at spawn, it is
## the only way to get a dozen different colours out of one emitter. Note that
## it takes a bare `Gradient` here, unlike the `GradientTexture1D` its
## `GPUParticles3D` counterpart wants.
func _tint(particles: CPUParticles3D) -> void:
	if bool(_style.get("rainbow", false)):
		particles.color = Color.WHITE
		var gradient := Gradient.new()
		# A fresh Gradient arrives with two points of its own; they would sit at
		# 0 and 1 alongside everything added below and wash the spread out.
		gradient.offsets = PackedFloat32Array()
		gradient.colors = PackedColorArray()
		for i in 6:
			gradient.add_point(float(i) / 5.0, Color.from_hsv(float(i) / 6.0, 0.85, 1.0))
		particles.color_initial_ramp = gradient
	else:
		particles.color = _colour.lightened(float(_style.get("lighten", 0.3)))


## Unshaded flecks coloured through vertex colour so the emitter's own `color`
## actually reaches them — `MarbleTrail._particle_mesh`, which this follows.
func _particle_mesh(size: Vector3) -> Mesh:
	var box := BoxMesh.new()
	box.size = size

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	box.material = material
	return box


# --- Life ---------------------------------------------------------------------


func _process(delta: float) -> void:
	_age += delta

	_animate_rings()
	_animate_flash()
	_fire_mortar()

	if _age >= LIFETIME:
		queue_free()


## Each ring opens out and fades as it goes, the second one behind the first.
## Eased so it leaves fast and arrives slowly, which is what a shockwave does
## and what a linear scale conspicuously does not.
func _animate_rings() -> void:
	for i in _rings.size():
		var ring := _rings[i]
		var t := (_age - RING_DELAY * i) / RING_SECONDS
		if t < 0.0 or t >= 1.0:
			ring.visible = false
			continue

		ring.visible = true
		var eased := 1.0 - pow(1.0 - t, 3.0)
		var radius := RING_RADIUS * eased * float(_style.get("power", 1.0))
		# Flattened on Y: a torus scaled evenly is a doughnut standing in the
		# air, and this wants to be a ripple lying on the deck.
		ring.scale = Vector3(radius, radius * 0.18, radius)

		var material := ring.mesh.surface_get_material(0) as StandardMaterial3D
		if material != null:
			material.albedo_color.a = (1.0 - t) * 0.55


func _animate_flash() -> void:
	if _flash == null:
		return
	if _age >= FLASH_SECONDS:
		if _flash.light_energy > 0.0:
			_flash.light_energy = 0.0
		return
	# Squared falloff: bright immediately, gone before it can read as a lamp
	# someone left on in the runoff.
	var t := _age / FLASH_SECONDS
	_flash.light_energy = _flash_energy * pow(1.0 - t, 2.0)


func _fire_mortar() -> void:
	if _mortar == null or _mortar_fired or _age < MORTAR_DELAY:
		return
	_mortar_fired = true
	# `restart()` alone does not re-arm a one-shot emitter built with
	# `emitting = false` — the same thing `MarbleTrail._add_sample` ran into.
	_mortar.emitting = true
	_mortar.restart()


# --- Shop preview -------------------------------------------------------------


## A still frame of the effect at its peak, for the shop row.
##
## Static on purpose for now: the shop draws trails and skins as swatches, and a
## lone animated cell in that column would read as a bug. When the real shop
## lands with animated previews, this is what it replaces.
static func swatch_texture(style: Dictionary, fallback: Color, size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var colour: Color = style.get("colour", fallback)
	var power := float(style.get("power", 1.0))
	var rainbow := bool(style.get("rainbow", false))
	var centre := Vector2(size * 0.5, size * 0.5)

	# Rays out of the middle, longer and denser with `power`, which is the one
	# key that separates a pop from a detonation at a glance.
	var rays := int(10 + 14 * power)
	for i in rays:
		var angle := TAU * float(i) / float(rays)
		var direction := Vector2(cos(angle), sin(angle))
		var length := size * 0.42 * (0.55 + 0.45 * fmod(float(i) * 0.37, 1.0)) * power
		var tint := Color.from_hsv(float(i) / float(rays), 0.85, 1.0) if rainbow else colour
		var steps := maxi(int(length), 1)
		for s in steps:
			var t := float(s) / float(maxi(steps - 1, 1))
			_plot(image, centre + direction * float(s), tint, (1.0 - t) * 0.95, size)

	if float(style.get("ring", 0.0)) > 0.0:
		var radius := size * 0.40
		var ring_colour := colour.lightened(0.4)
		for i in 180:
			var angle := TAU * float(i) / 180.0
			var unit := Vector2(cos(angle), sin(angle))
			_plot(image, centre + unit * radius, ring_colour, 0.8, size)
			_plot(image, centre + unit * (radius - 1.0), ring_colour, 0.5, size)

	if float(style.get("flash", 0.0)) > 0.0:
		var core_radius := int(size * 0.10)
		for dx in range(-core_radius, core_radius + 1):
			for dy in range(-core_radius, core_radius + 1):
				var offset := Vector2(dx, dy)
				if offset.length() > core_radius:
					continue
				var fade := 1.0 - offset.length() / float(core_radius)
				_plot(image, centre + offset, colour.lerp(Color.WHITE, 0.75), fade, size)

	return ImageTexture.create_from_image(image)


## Writes one pixel, brightest-wins, so overlapping rays do not punch holes in
## each other by writing a dim alpha over a bright one.
static func _plot(image: Image, at: Vector2, colour: Color, alpha: float, size: int) -> void:
	var x := int(at.x)
	var y := int(at.y)
	if x < 0 or y < 0 or x >= size or y >= size:
		return
	if image.get_pixel(x, y).a >= alpha:
		return
	image.set_pixel(x, y, Color(colour.r, colour.g, colour.b, clampf(alpha, 0.0, 1.0)))
