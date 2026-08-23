class_name FinishArea
extends Area3D

## Finish detection.
##
## The spec asks for a physical finish area plus a reliable trigger, so the
## trigger is what drives game state: relying on geometry alone would make
## finish order depend on where a marble happens to come to rest.

signal marble_finished(marble: Marble)

const SIZE := Vector3(12.0, 6.0, 2.0)

var _size := SIZE


## Width comes from the course, so the gate spans the track it is closing.
static func create(width: float = SIZE.x) -> FinishArea:
	var area := FinishArea.new()
	area.name = "FinishArea"
	area._size = Vector3(width, SIZE.y, SIZE.z)
	area._build()
	return area


func _build() -> void:
	var shape := BoxShape3D.new()
	shape.size = _size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

	# A faint gate rather than a solid green block. At 0.35 alpha over a six-metre
	# box this tinted a quarter of the frame at exactly the moment the race ends
	# and the results go up — the one screen the player is actually meant to read.
	# Kept visible at all because the finish should be somewhere you can see
	# coming, and unshaded so it reads as a marker rather than as geometry.
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.95, 0.65, 0.10)
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
	if marble != null and marble.state == Marble.State.RACING:
		marble_finished.emit(marble)
