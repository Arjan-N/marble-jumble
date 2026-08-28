class_name PaddleDrum
extends AnimatableBody3D

## A paddle wheel turning across the track, low enough that its blades sweep
## through the field.
##
## The fifth machine on `FoundryCourse`. `RotatingBumper` turns about the
## surface normal, so its arms only ever push a marble sideways; this turns
## about the *across-track* axis, so its blades come down in front of a marble
## and leave down-course. It is the only thing in the pool whose strike has a
## vertical component and a forward one at the same time — a marble it catches
## is slapped along the plate and pressed into it, not deflected off the line.
##
## **It rolls forwards, not backwards.** A wheel turning the other way scoops a
## marble up its own up-course face and drops it behind where it started, which
## on a course this long is a marble that can be juggled at one machine for the
## rest of the race. Turning with the field, the worst case is a hard shove
## down-course; there is no cycle it can trap anybody in. Taking speed away is
## `FoundryCourse`'s brake belt's job, and that one does it without a collision.
##
## **The blades never reach the plate.** Lowest tip is `HUB_HEIGHT - RADIUS`
## above the floor, which is above zero by design: a blade that swept below the
## surface would pinch marbles against a one-sided concave mesh and push them
## through it. It still passes well under a marble's crown, so it connects with
## everything that comes past.
##
## `AnimatableBody3D` with `sync_to_physics` and real blades rather than a smooth
## drum: the momentum comes from geometry actually moving through the contact,
## the same way `RotatingBumper`'s does.

const BLADE_COUNT := 4
const RADIUS := 1.05
const BLADE_THICKNESS := 0.18
## Axle height above the plate. `RADIUS` short of it is where the blade tips
## pass, so this is what sets the 0.27m ground clearance.
const HUB_HEIGHT := 1.32
const HUB_RADIUS := 0.30

## Turns per second. Scaled like `RotatingBumper.revolutions_per_second` for
## gravity 30: much slower and the field files between blades untouched, much
## faster and the tip speed at the bottom is a launch rather than a shove.
const SPIN := 0.55

const BLADE_COLOUR := Color(0.66, 0.38, 0.20)
const HUB_COLOUR := Color(0.44, 0.45, 0.48)

## Across-track span of the wheel.
@export var drum_width: float = 4.6
## Where in the rotation this drum starts, 0..1.
@export var phase: float = 0.0


static func create(width: float, start_phase: float) -> PaddleDrum:
	var drum := PaddleDrum.new()
	drum.name = "PaddleDrum"
	drum.drum_width = width
	drum.phase = start_phase
	drum._build()
	return drum


## The wheel is built about its own axle, and the course lifts it to
## `HUB_HEIGHT` when it places it — so the node origin here is the axle, not the
## floor. See `FoundryCourse._build_drum_line`.
func _build() -> void:
	sync_to_physics = true

	for i in BLADE_COUNT:
		var angle := TAU * (float(i) / float(BLADE_COUNT) + phase)
		# Each blade stands out along the wheel's local +Y before being rolled
		# round the across-track axis, which is local X in a course frame.
		var blade := Transform3D(
			Basis(Vector3.RIGHT, angle), Vector3.ZERO
		).translated_local(Vector3(0.0, RADIUS * 0.5, 0.0))
		var size := Vector3(drum_width, RADIUS, BLADE_THICKNESS)

		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.transform = blade
		add_child(collider)

		var mesh := BoxMesh.new()
		mesh.size = size
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(BLADE_COLOUR)
		visual.transform = blade
		add_child(visual)

	_build_hub()


## Visual only. A colliding axle is a bar across the track at marble height with
## a wheel turning around it — a wedge, not an obstacle.
func _build_hub() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = HUB_RADIUS
	mesh.bottom_radius = HUB_RADIUS
	mesh.height = drum_width * 1.04
	mesh.radial_segments = 10
	var hub := MeshInstance3D.new()
	hub.mesh = mesh
	hub.material_override = _material(HUB_COLOUR)
	# Standing on end by default; laid across the track to match the axle.
	hub.rotation = Vector3(0.0, 0.0, PI * 0.5)
	add_child(hub)


## Positive rotation about local +X carries the *bottom* of the wheel towards
## local -Z, which is down-course in a course frame. That is the direction the
## header argues for, and reversing the sign here is the change that would make
## this a marble trap.
func _physics_process(delta: float) -> void:
	rotate_object_local(Vector3.RIGHT, TAU * SPIN * delta)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	material.metallic = 0.2
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material
