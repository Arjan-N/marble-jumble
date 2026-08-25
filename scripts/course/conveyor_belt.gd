class_name ConveyorBelt
extends StaticBody3D

## A powered belt set into the floor: whatever rolls onto it gets dragged.
##
## `DECISIONS.md` §"Future obstacle vocabulary" parks conveyor belts along with
## launchers, pistons and moving platforms as post-Phase-0. This one exists
## because Arjan asked for a course carried by new obstacles rather than by new
## terrain; the decision is recorded there as a request, not invented here.
##
## Physically this is the cheapest honest way to move a marble: a `StaticBody3D`
## with `constant_linear_velocity`, which Godot's solver feeds into the contact
## as surface motion. Friction does the rest, so a marble arriving fast is barely
## deflected and one that has stopped is carried outright — the belt affects
## whoever the course has already slowed, the same property `BoostPad`'s header
## argues for. Nothing is teleported and no force is applied directly.
##
## The belt sits 5cm proud of the floor rather than flush. Flush would need the
## floor mesh cut around it; 5cm against a 0.45m marble is not a lip, it is the
## reason the belt wins the contact instead of the plate underneath it.

## How far the belt top stands above the floor it is set into.
const PROUD := 0.05
const THICKNESS := 0.5
## High on purpose: `constant_linear_velocity` only reaches a marble through
## friction, and a slick belt is a painted stripe.
const FRICTION := 0.85
const BOUNCE := 0.04

const BELT_COLOUR := Color(0.16, 0.17, 0.19)
const CHEVRON_COLOUR := Color(0.82, 0.66, 0.18)
## Spacing of the moving chevrons, in metres along the drive direction.
const CHEVRON_PITCH := 2.0

var _size := Vector3(6.0, THICKNESS, 8.0)
## Belt motion in the *belt's own* local space: +X drags across it, -Z drags
## down-course. A course hands this in, so a crossbelt and a brake belt are the
## same object placed differently.
var _drive := Vector3.ZERO
var _chevrons: Array[MeshInstance3D] = []
var _scroll := 0.0


## `width` spans the track, `length` runs down-course, `drive` is metres per
## second in the belt's local frame.
static func create(width: float, length: float, drive: Vector3) -> ConveyorBelt:
	var belt := ConveyorBelt.new()
	belt.name = "ConveyorBelt"
	belt._size = Vector3(width, THICKNESS, length)
	belt._drive = drive
	belt._build()
	return belt


func _build() -> void:
	var surface := PhysicsMaterial.new()
	surface.friction = FRICTION
	surface.bounce = BOUNCE
	physics_material_override = surface

	# In global space, because that is what the solver reads. The belt is placed
	# by the course's frame, so a local +X drive becomes "across the track here".
	constant_linear_velocity = _drive

	var shape := BoxShape3D.new()
	shape.size = _size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	# Dropped so only `PROUD` of it stands above the floor plane the course
	# placed this at; the rest is buried and never touched.
	collider.position = Vector3(0.0, PROUD - THICKNESS * 0.5, 0.0)
	add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = _size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(BELT_COLOUR)
	visual.position = collider.position
	add_child(visual)

	_build_chevrons()


## Painted markers that travel with the belt. Purely visual and non-colliding:
## a surface that moves marbles without visibly moving reads as the physics
## being broken, which is the same argument `BoostPad` makes for being visible
## at all.
func _build_chevrons() -> void:
	var along := _drive.normalized()
	if along.is_zero_approx():
		return

	# Which of the belt's two axes the drive runs along decides how far the
	# chevrons have to travel before they wrap.
	var span := _size.x if absf(along.x) > absf(along.z) else _size.z
	var count := int(span / CHEVRON_PITCH)
	var bar := Vector3(0.35, 0.04, _size.z * 0.8) if absf(along.x) > absf(along.z) \
		else Vector3(_size.x * 0.8, 0.04, 0.35)

	for i in count:
		var mesh := BoxMesh.new()
		mesh.size = bar
		var chevron := MeshInstance3D.new()
		chevron.mesh = mesh
		chevron.material_override = _material(CHEVRON_COLOUR)
		chevron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(chevron)
		_chevrons.append(chevron)


func _process(delta: float) -> void:
	if _chevrons.is_empty():
		return

	var along := _drive.normalized()
	# The drive is in global space; the chevrons are children, so the belt's own
	# rotation has to come back out of it.
	var local := global_transform.basis.inverse() * along
	var span := _size.x if absf(local.x) > absf(local.z) else _size.z

	_scroll = fposmod(_scroll + _drive.length() * delta, CHEVRON_PITCH)

	for i in _chevrons.size():
		var distance := fposmod(_scroll + float(i) * CHEVRON_PITCH, span) - span * 0.5
		_chevrons[i].position = local * distance + Vector3(0.0, PROUD + 0.03, 0.0)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material
