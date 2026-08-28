class_name Turntable
extends AnimatableBody3D

## A disc set flush into the plate, turning about the surface normal.
##
## The sixth machine on `FoundryCourse`, and the one whose effect depends on
## *where* you meet it rather than *when*. `ConveyorBelt` does the same thing to
## everything that crosses it — a belt driving right pushes every marble right.
## A turntable pushes a marble whichever way the disc happens to be going under
## it, so two marbles a metre apart across the same table are steered opposite
## ways, and one over the middle is barely touched at all. Crossing near the rim
## is the fast lane and the dangerous one.
##
## That gives the course a spreader to set against its belts, which are all
## gatherers: the crossbelts fold the field into the middle and the drift belt
## walks it sideways as one, while a table takes a bunch that is already
## together and opens it out.
##
## Built like `ConveyorBelt` — mostly buried, standing `PROUD` of the floor, with
## a high-friction surface, because surface motion only reaches a marble through
## friction and a slick turntable is a painted circle. Unlike the belt it is an
## `AnimatableBody3D` with `sync_to_physics`: the drag comes from the disc's own
## angular velocity, and the cleats give the solver real geometry moving through
## the contact rather than asking friction to carry all of it.

const PROUD := 0.05
const THICKNESS := 0.5
const FRICTION := 0.82
const BOUNCE := 0.04

## Low radial ribs on the deck. Tall enough to bite, well under a marble's
## radius so nothing trips over one.
const CLEAT_COUNT := 6
const CLEAT_HEIGHT := 0.10
const CLEAT_WIDTH := 0.24

const DECK_COLOUR := Color(0.25, 0.26, 0.30)
const CLEAT_COLOUR := Color(0.72, 0.58, 0.20)

@export var radius: float = 3.2
## Turns per second, signed: positive spins the near rim towards track-right.
## Around 0.3 the rim runs at roughly walking pace against a field arriving at
## several metres a second, which is a nudge across a lane rather than a throw.
@export var turns_per_second: float = 0.32


static func create(disc_radius: float, rate: float) -> Turntable:
	var table := Turntable.new()
	table.name = "Turntable"
	table.radius = disc_radius
	table.turns_per_second = rate
	table._build()
	return table


func _build() -> void:
	sync_to_physics = true

	var surface := PhysicsMaterial.new()
	surface.friction = FRICTION
	surface.bounce = BOUNCE
	physics_material_override = surface

	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = THICKNESS
	var collider := CollisionShape3D.new()
	collider.shape = shape
	# Dropped so only `PROUD` stands above the plane the course placed this at;
	# the rest is inside the plate and never touched.
	collider.position = Vector3(0.0, PROUD - THICKNESS * 0.5, 0.0)
	add_child(collider)

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = THICKNESS
	mesh.radial_segments = 24
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(DECK_COLOUR)
	visual.position = collider.position
	add_child(visual)

	_build_cleats()


func _build_cleats() -> void:
	for i in CLEAT_COUNT:
		var angle := TAU * float(i) / float(CLEAT_COUNT)
		var size := Vector3(CLEAT_WIDTH, CLEAT_HEIGHT, radius * 0.86)
		# Radial: rotated about the deck normal, then pushed out from the centre
		# so the bar runs from near the hub to just inside the rim.
		var placement := Transform3D(
			Basis(Vector3.UP, angle), Vector3(0.0, PROUD + CLEAT_HEIGHT * 0.5, 0.0)
		).translated_local(Vector3(0.0, 0.0, -radius * 0.5))

		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.transform = placement
		add_child(collider)

		var mesh := BoxMesh.new()
		mesh.size = size
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(CLEAT_COLOUR)
		visual.transform = placement
		add_child(visual)


func _physics_process(delta: float) -> void:
	rotate_object_local(Vector3.UP, TAU * turns_per_second * delta)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	material.metallic = 0.15
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material
