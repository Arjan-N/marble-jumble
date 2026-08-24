class_name Marble
extends RigidBody3D

## A single race participant.
##
## Marbles are pure physics bodies: no steering, no AI, no corrective forces
## (PHASE_0_TECHNICAL_SPEC.md section 2). The player's marble differs from the
## rest only by its colour and a subtle rim highlight.

enum State {
	WAITING, ## Settled behind the barrier, race not started.
	RACING,
	FINISHED,
	ELIMINATED, ## Left the playable course.
}

## Emitted only for the player's marble (see `_build`) so the sound manager can
## react to impact speed without every marble in a 12-body field reporting.
signal collided(speed: float)

var marble_id: int = -1
## What the HUD calls this marble. Cosmetic, like the colour — it never reaches
## the physics, and two marbles with different names are the same marble as far
## as the simulation is concerned (PROJECT.md section 7).
var marble_name: String = ""
var is_player: bool = false
var state: State = State.WAITING
## The colour this marble was built with, kept so the HUD can draw a swatch that
## matches what is on the track without reaching into the mesh material.
var colour: Color = Color.WHITE
## The cosmetic finish painted over that colour, or `{}` for a plain one. Set
## before `_build` by `create`; nothing outside `_build_material` reads it, and
## nothing in the simulation does.
var skin: Dictionary = {}

var _tuning: MarbleTuning
## Previous frame's velocity, so an impact can be recognised as a sudden change
## rather than by which body was touched — the track is built from many
## separate static segments, and watching contacts fires on every ordinary
## segment-to-segment crossing, not just real hits.
var _last_velocity := Vector3.ZERO
## A collision spans a few physics frames; without this each one re-fires the
## signal every frame the velocity stays disturbed.
const IMPACT_COOLDOWN := 0.15
var _impact_cooldown := 0.0
## Per-frame change big enough to be a bump, wall clip or another marble, not
## the ordinary velocity drift from gravity, friction or rolling off a slope.
const IMPACT_DELTA_THRESHOLD := 3.0

## The player's material, kept so its glow can breathe. A gentle pulse reads as
## "alive" rather than "painted on" — the difference between a highlight a
## child's eye is drawn to and one that just sits there.
var _highlight_material: StandardMaterial3D
## False for a skin that paints its own emission map — see `_build_material`.
var _pulses := true
## The player's trail, kept so a reset can drop it rather than leaving a streak
## stretched between two rounds' spawn points.
var _trail: MarbleTrail
var _pulse_time := 0.0
const PULSE_SPEED := 2.2
const PULSE_MIN := 0.12
const PULSE_MAX := 0.32


## `skin` is the player's equipped entry from `PlayerProfile.SKINS`, and only
## ever decides how the marble looks (`marble_skin.gd`). Opponents pass nothing
## and get the flat colour they always had — they are physically identical to
## the player either way (PROJECT.md section 7).
static func create(
	id: int,
	tuning: MarbleTuning,
	colour: Color,
	player: bool,
	marble_name := "",
	skin: Dictionary = {}
) -> Marble:
	var marble := Marble.new()
	marble.skin = skin
	marble.name = "Marble%02d" % id
	marble.marble_id = id
	marble.marble_name = marble_name if marble_name != "" else "Marble %d" % id
	marble.is_player = player
	marble.colour = colour
	marble._tuning = tuning
	marble._build(colour)
	return marble


func _build(colour: Color) -> void:
	mass = _tuning.mass
	linear_damp = _tuning.linear_damp
	angular_damp = _tuning.angular_damp
	# A small, fast sphere against thin track walls tunnels without this.
	continuous_cd = true

	# Marbles settle against the barrier and fall asleep before the start.
	# Godot does not wake a sleeping body when the static geometry it rests
	# against moves away, so a sleeping field never notices the barrier drop.
	# At twelve bodies the saving is not worth the failure mode.
	can_sleep = false

	var surface := PhysicsMaterial.new()
	surface.friction = _tuning.friction
	surface.bounce = _tuning.bounce
	physics_material_override = surface

	var shape := SphereShape3D.new()
	shape.radius = _tuning.radius
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

	var mesh := SphereMesh.new()
	mesh.radius = _tuning.radius
	mesh.height = _tuning.radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var material := _build_material(colour)
	visual.material_override = material
	add_child(visual)

	if is_player:
		_highlight_material = material
		# The rim and emission above are what `DECISIONS.md` originally allowed,
		# and on their own they are not enough under this renderer and camera —
		# see the 2026-08-22 decision entry. The trail is the cue with real
		# screen area, and it survives being buried in a pile-up.
		_trail = MarbleTrail.create(colour, _tuning.radius)
		add_child(_trail)


func _build_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.metallic = 0.1
	material.roughness = 0.25
	# A patterned skin replaces the albedo above with its own map and brings its
	# own metallic/roughness. A plain one leaves all three exactly as set here.
	MarbleSkin.apply(material, skin)

	if is_player:
		# The persistent identification the spec calls for: prominent enough to
		# find at a glance in a field of twelve, still a highlight rather than a
		# floating arrow or oversized marker.
		material.rim_enabled = true
		material.rim = 0.9
		# Low rim_tint mixes toward the light's colour rather than the marble's,
		# which read as a plain white halo on the galaxy/magma skins. Tinting it
		# mostly toward the marble's own colour keeps the identification cue
		# without a white ring stamped over a skin's own palette.
		material.rim_tint = 0.8
		# A skin that paints its own emission — the galaxy's stars, the magma's
		# veins — keeps it; overwriting it with a flat colour would throw the
		# skin's whole look away for a cue the rim and the trail already carry.
		# It is not pulsed either (see `_process`): brightening an already-bright
		# baked-in map pushes its hottest pixels toward white and buries the
		# skin's own colours under the identification cue.
		_pulses = not MarbleSkin.has_emission(skin)
		if _pulses:
			material.emission_enabled = true
			material.emission = colour

	return material


func _process(delta: float) -> void:
	if not is_player or not _pulses or _highlight_material == null:
		return

	# A slow breathing glow rather than a fixed one — motion is what catches a
	# child's eye in a field of identical, constantly-moving spheres.
	_pulse_time += delta
	var pulse := (sin(_pulse_time * PULSE_SPEED) * 0.5) + 0.5
	_highlight_material.emission_energy_multiplier = lerpf(PULSE_MIN, PULSE_MAX, pulse)


func _physics_process(delta: float) -> void:
	if not is_player:
		return

	_impact_cooldown = maxf(_impact_cooldown - delta, 0.0)

	if state == State.RACING:
		var change := (linear_velocity - _last_velocity).length()
		if change >= IMPACT_DELTA_THRESHOLD and _impact_cooldown <= 0.0:
			_impact_cooldown = IMPACT_COOLDOWN
			collided.emit(change)

	_last_velocity = linear_velocity


## Returns the marble to a settled pre-race state with no leaked physics.
func reset_to(spawn: Transform3D) -> void:
	state = State.WAITING
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = spawn
	if _trail != null:
		_trail.clear()
