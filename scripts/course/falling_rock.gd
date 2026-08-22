class_name FallingRock
extends RigidBody3D

## A single piece of eruption debris. Physics-driven like everything else
## (PROJECT.md section 6: no scripted outcomes) — it falls under normal
## gravity and deflects whatever it lands near exactly the way any other
## collision would. `VolcanoCourse` is the spawner; this is just the body.
##
## Small and light on purpose. The issue this exists for (github.com/…/issues/2)
## is explicit that debris must "create unpredictable deflections and
## overtakes" without becoming "the dominant determinant of winning" — a rock
## close to marble mass nudges without being able to flatten a race the way a
## boulder would.

const RADIUS := 0.32
const MASS := 0.6
## Cleaned up whether or not it ever lands anywhere interesting, so a long
## race does not accumulate rocks forever.
const LIFETIME := 8.0

const COLOUR := Color(0.20, 0.11, 0.08)


static func create() -> FallingRock:
	var rock := FallingRock.new()
	rock.name = "FallingRock"
	rock._build()
	return rock


func _build() -> void:
	mass = MASS
	continuous_cd = true

	var surface := PhysicsMaterial.new()
	surface.friction = 0.7
	surface.bounce = 0.15
	physics_material_override = surface

	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

	var mesh := SphereMesh.new()
	mesh.radius = RADIUS
	mesh.height = RADIUS * 2.0
	mesh.radial_segments = 8
	mesh.rings = 5
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOUR
	material.roughness = 1.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)


## `get_tree()` is only valid once the node is actually inside it — `_build()`
## runs before `create()`'s caller has added the rock as a child, so the
## lifetime timer is started here instead.
func _ready() -> void:
	get_tree().create_timer(LIFETIME).timeout.connect(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)
