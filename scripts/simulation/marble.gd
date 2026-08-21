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

var _tuning: MarbleTuning


static func create(
	id: int, tuning: MarbleTuning, colour: Color, player: bool, marble_name := ""
) -> Marble:
	var marble := Marble.new()
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
	visual.material_override = _build_material(colour)
	add_child(visual)


func _build_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.metallic = 0.1
	material.roughness = 0.25

	if is_player:
		# The persistent identification the spec calls for: a subtle rim, not a
		# floating arrow or oversized marker.
		material.rim_enabled = true
		material.rim = 0.75
		material.rim_tint = 0.2

	return material


## Returns the marble to a settled pre-race state with no leaked physics.
func reset_to(spawn: Transform3D) -> void:
	state = State.WAITING
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = spawn
