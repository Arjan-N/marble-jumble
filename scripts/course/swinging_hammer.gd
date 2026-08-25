class_name SwingingHammer
extends AnimatableBody3D

## A weight on an arm, swinging across the track from a gantry overhead.
##
## The third new obstacle, and the one that acts in the axis nothing else here
## does. A bumper sweeps around a fixed post and a ram comes out of a wall;
## both are things a marble meets at the height it is already at. A hammer
## arrives from above and leaves upward, so the marble it catches is thrown
## rather than deflected — and on a plate with open edges, thrown is a
## different outcome from deflected.
##
## Swings rather than rotates. A full-circle hammer spends most of its cycle
## somewhere no marble can reach and passes through the racing line at a speed
## nothing survives; a pendulum is slowest at the ends of its arc, fastest at
## the bottom, and the bottom is exactly where the marbles are. That is a
## timing puzzle instead of a coin flip.
##
## `AnimatableBody3D` with `sync_to_physics`, like `RotatingBumper` and
## `PistonRam`, so the swing carries momentum into whatever it strikes.

const ARM_LENGTH := 3.0
const ARM_THICKNESS := 0.2
const HEAD_RADIUS := 0.62

const ARM_COLOUR := Color(0.48, 0.49, 0.52)
const HEAD_COLOUR := Color(0.34, 0.36, 0.40)

## Half-angle of the swing, in degrees. Past about 50 the head lifts clear of
## the track at the ends of its arc and the obstacle stops existing for half
## its cycle; under about 20 it never reaches the edges of the track.
@export var amplitude_degrees: float = 34.0
## Seconds for one full there-and-back. Not derived from `ARM_LENGTH` — this is
## a driven mechanism, not a free pendulum, and the useful rate is the one that
## matches how fast the field arrives.
@export var period: float = 2.4
## Where in the swing this hammer starts, 0..1. A row on the same phase is one
## wall; offset, they are a gauntlet a marble threads.
@export var phase: float = 0.0

var _time := 0.0
## The frame the course placed this in. The swing is applied on top of it: a
## hammer that wrote straight to `transform.basis` would throw away the pitch
## and heading of the track it was hung over and swing about the world axes.
var _rest := Basis.IDENTITY


static func create(swing_period: float, start_phase: float) -> SwingingHammer:
	var hammer := SwingingHammer.new()
	hammer.name = "SwingingHammer"
	hammer.period = swing_period
	hammer.phase = start_phase
	hammer._build()
	return hammer


## The node's own origin is the pivot, which is what lets a course place one by
## putting the pivot on the gantry above the track and leaving the geometry to
## hang from it.
func _build() -> void:
	sync_to_physics = true

	var arm_shape := BoxShape3D.new()
	arm_shape.size = Vector3(ARM_THICKNESS, ARM_LENGTH, ARM_THICKNESS)
	var arm_collider := CollisionShape3D.new()
	arm_collider.shape = arm_shape
	arm_collider.position = Vector3(0.0, -ARM_LENGTH * 0.5, 0.0)
	add_child(arm_collider)

	var arm_mesh := BoxMesh.new()
	arm_mesh.size = arm_shape.size
	var arm_visual := MeshInstance3D.new()
	arm_visual.mesh = arm_mesh
	arm_visual.material_override = _material(ARM_COLOUR)
	arm_collider.add_child(arm_visual)

	var head_shape := SphereShape3D.new()
	head_shape.radius = HEAD_RADIUS
	var head_collider := CollisionShape3D.new()
	head_collider.shape = head_shape
	head_collider.position = Vector3(0.0, -ARM_LENGTH, 0.0)
	add_child(head_collider)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = HEAD_RADIUS
	head_mesh.height = HEAD_RADIUS * 2.0
	head_mesh.radial_segments = 12
	head_mesh.rings = 7
	var head_visual := MeshInstance3D.new()
	head_visual.mesh = head_mesh
	head_visual.material_override = _material(HEAD_COLOUR)
	head_collider.add_child(head_visual)


## The rest frame is read once the course has finished placing this, not in
## `_build` — `create` runs before the caller has set the transform.
func _ready() -> void:
	_rest = transform.basis


## Swings about the frame's own Z, which is the down-course axis in a course
## frame — so the head travels across the track rather than along it.
func _physics_process(delta: float) -> void:
	_time += delta
	var angle := deg_to_rad(amplitude_degrees) * sin(TAU * (_time / period + phase))
	transform.basis = _rest * Basis(Vector3.FORWARD, angle)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.75
	material.metallic = 0.25
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material
