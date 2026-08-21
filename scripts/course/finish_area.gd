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

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.9, 0.5, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := BoxMesh.new()
	mesh.size = _size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble != null and marble.state == Marble.State.RACING:
		marble_finished.emit(marble)
