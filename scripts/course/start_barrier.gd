class_name StartBarrier
extends StaticBody3D

## The physical gate the field settles behind.
##
## The player may tap the barrier itself to release the race, or do nothing and
## let it open on its own after AUTO_OPEN_DELAY. Tapping is agency and
## presentation only: it must never affect the outcome (spec section 3). There
## is deliberately no 3-2-1 countdown.

signal opened

const AUTO_OPEN_DELAY := 5.0
const WIDTH := 6.8
const HEIGHT := 1.6
const THICKNESS := 0.3
const DROP_DISTANCE := 2.2
const DROP_DURATION := 0.35

var _is_open := false
var _elapsed := 0.0
var _width := WIDTH


## Width comes from the course: a barrier narrower than the track leaves a gap
## the field escapes through before the race has started.
static func create(width: float = WIDTH) -> StartBarrier:
	var barrier := StartBarrier.new()
	barrier.name = "StartBarrier"
	barrier._width = width
	barrier._build()
	return barrier


func _build() -> void:
	var size := Vector3(_width, HEIGHT, THICKNESS)

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.3, 0.3)
	material.roughness = 0.5

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)

	input_ray_pickable = true
	input_event.connect(_on_input_event)


func _process(delta: float) -> void:
	if _is_open:
		return

	_elapsed += delta
	if _elapsed >= AUTO_OPEN_DELAY:
		open()


## Seconds remaining before the barrier opens by itself.
func time_remaining() -> float:
	return maxf(0.0, AUTO_OPEN_DELAY - _elapsed)


func open() -> void:
	if _is_open:
		return
	_is_open = true

	# Drop the gate out of the way rather than deleting it, so the release
	# reads as a physical event.
	var tween := create_tween()
	tween.tween_property(
		self, "position:y", position.y - DROP_DISTANCE, DROP_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	opened.emit()


func _on_input_event(
	_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int
) -> void:
	if event is InputEventMouseButton and event.pressed:
		open()
	elif event is InputEventScreenTouch and event.pressed:
		open()
