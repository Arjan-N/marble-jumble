class_name RotatingBumper
extends AnimatableBody3D

## The single Phase 0 obstacle.
##
## Deliberately simple: the prototype is testing marble/obstacle collision
## physics, not an obstacle system. AnimatableBody3D rather than StaticBody3D so
## the rotation actually transfers momentum into the marbles it strikes.

const ARM_LENGTH := 2.6
const ARM_THICKNESS := 0.35
const ARM_HEIGHT := 0.8
const ARM_COUNT := 3

## Scaled with the marbles. Raising gravity to 30 replays the whole race 1.75x
## faster, but an arm on a fixed rev/s does not come along: at 0.35 it turned
## into a near-static post the field just bounced off. 0.35 x 1.75 keeps it
## hitting the field at the same rate per marble that passes.
@export var revolutions_per_second: float = 0.61


static func create() -> RotatingBumper:
	var bumper := RotatingBumper.new()
	bumper.name = "RotatingBumper"
	bumper._build()
	return bumper


func _build() -> void:
	sync_to_physics = true

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.55, 0.25)
	material.roughness = 0.6

	for i in ARM_COUNT:
		var angle := TAU * float(i) / float(ARM_COUNT)
		var arm := Transform3D(
			Basis(Vector3.UP, angle), Vector3.UP * (ARM_HEIGHT * 0.5)
		).translated_local(Vector3(0.0, 0.0, -ARM_LENGTH * 0.5))
		var size := Vector3(ARM_THICKNESS, ARM_HEIGHT, ARM_LENGTH)

		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.transform = arm
		add_child(collider)

		var mesh := BoxMesh.new()
		mesh.size = size
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = material
		visual.transform = arm
		add_child(visual)


func _physics_process(delta: float) -> void:
	rotate_object_local(Vector3.UP, TAU * revolutions_per_second * delta)
