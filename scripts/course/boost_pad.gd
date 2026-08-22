class_name BoostPad
extends Area3D

## A patch of course that guarantees a minimum speed down-course.
##
## This is what makes a jump possible on a course that turns. Both attempts at a
## gap here failed the same way: sized so the field clears it, a marble is
## narrower than the hole and wedges; sized so nothing wedges, most of the field
## goes in. The window between those is inside a marble's own diameter, because
## arrival speed varies by a factor of three depending on what happened upstream.
## A floor under that speed collapses the range — everyone arrives fast enough,
## so the gap can be sized for one speed rather than for all of them.
##
## **It tops up rather than multiplying.** A marble already quicker than
## `target_speed` is not touched at all, which is the property that matters: a
## multiplier would reward the leader for leading and punish nobody, while this
## only ever helps whoever the course has already hurt, and helps them exactly
## enough to make the jump and no more. Nothing here changes the order of a field
## that is already travelling well.
##
## `DECISIONS.md` parks boosters along with launchers, conveyors and moving
## platforms as post-Phase-0 obstacles, so this is a deliberate exception rather
## than an oversight. It is arguably not one of those in spirit — it adds no
## energy to a marble running normally and exists to make one piece of terrain
## work — but it is a speed change the player did not cause, and that decision is
## Arjan's, not this file's.

## Nothing crossing this is allowed to be slower than this, along the course.
@export var target_speed: float = 13.0

var _direction := Vector3.FORWARD
var _size := Vector3(10.0, 3.0, 2.5)


## `direction` is the way the course runs here — the boost is along the track,
## never along whatever the marble happened to be doing, so a marble arriving
## sideways off a wall is straightened rather than fired into one.
static func create(width: float, direction: Vector3, speed: float) -> BoostPad:
	var pad := BoostPad.new()
	pad.name = "BoostPad"
	pad._size = Vector3(width, 3.0, 2.5)
	pad._direction = direction.normalized()
	pad.target_speed = speed
	pad._build()
	return pad


func _build() -> void:
	var shape := BoxShape3D.new()
	shape.size = _size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

	# Visible, because a speed change the player cannot see is a speed change
	# they will read as the physics being unfair. Unshaded and faint, like the
	# finish gate.
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.92, 0.55, 0.16)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh := BoxMesh.new()
	mesh.size = _size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null or marble.state != Marble.State.RACING:
		return

	var along := marble.linear_velocity.dot(_direction)
	if along >= target_speed:
		return

	# Only the shortfall, and only along the course: lateral and vertical motion
	# are left exactly as they were, so a marble bouncing across the channel keeps
	# bouncing across it and simply does so while travelling fast enough.
	marble.linear_velocity += _direction * (target_speed - along)
