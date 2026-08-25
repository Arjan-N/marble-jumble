class_name PistonRam
extends AnimatableBody3D

## A ram that punches out of the wall, across the track, and withdraws.
##
## The second of the three new obstacles `FoundryCourse` is built on, and the
## one that makes the field's position matter: a bumper is somewhere the whole
## time, a ram is somewhere only sometimes. What it produces is a queue —
## marbles that arrive on the wrong beat get shoved sideways into whoever was
## beside them, and marbles that arrive on the right one go past untouched.
##
## `AnimatableBody3D` with `sync_to_physics`, for the same reason
## `RotatingBumper` is one: the movement has to transfer momentum rather than
## teleport through the field.
##
## **Out fast, back slow.** The punch is the event; the withdrawal must not be,
## or the ram drags marbles back into the wall it came from on every cycle. The
## asymmetry is the whole tuning.

const HEAD_LENGTH := 0.8
const HEAD_HEIGHT := 0.9
## Across-track thickness of the head. Wide enough to be an event, short enough
## that a marble beside one is not automatically in the next one.
const HEAD_WIDTH := 1.6
const SHAFT_RADIUS := 0.18

const HEAD_COLOUR := Color(0.72, 0.31, 0.20)
const SHAFT_COLOUR := Color(0.55, 0.56, 0.58)

## One full out-and-back, in seconds. Scaled to the same 1.75x the rest of the
## game got from gravity 30 (see `RotatingBumper.revolutions_per_second`): at
## 4s a ram is scenery the field files past between cycles.
const CYCLE := 2.3
## Fractions of `CYCLE`. Punch, hold extended, withdraw, then dwell retracted
## until the cycle repeats.
##
## The punch was a tenth of the cycle to begin with. A 3m stroke in 0.23s is a
## head crossing the track at 13m/s on average and roughly double that at the
## end of its squared ramp, which does not deflect a marble — it throws it clear
## off the plate, and a probe run lost most of a field to exactly that. Two
## thirds of a second, eased, still reads as a punch and leaves the marble on
## the course.
const PUNCH_END := 0.30
const HOLD_END := 0.46
const WITHDRAW_END := 0.78

## Metres the head travels from its retracted position.
@export var stroke: float = 2.6
## Where in the cycle this ram starts, 0..1. A row of rams on the same phase is
## a wall that appears and vanishes; staggered, it is a gauntlet.
@export var phase: float = 0.0

var _time := 0.0
var _shaft: MeshInstance3D
var _collider: CollisionShape3D


## The head always travels along local +X, so a ram on the other edge is the
## same object yawed 180 degrees by whoever places it rather than a mirrored
## variant of this.
static func create(stroke_length: float, start_phase: float) -> PistonRam:
	var ram := PistonRam.new()
	ram.name = "PistonRam"
	ram.stroke = stroke_length
	ram.phase = start_phase
	ram._build()
	return ram


func _build() -> void:
	sync_to_physics = true

	var shape := BoxShape3D.new()
	shape.size = Vector3(HEAD_WIDTH, HEAD_HEIGHT, HEAD_LENGTH)
	_collider = CollisionShape3D.new()
	_collider.shape = shape
	add_child(_collider)

	var mesh := BoxMesh.new()
	mesh.size = shape.size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(HEAD_COLOUR)
	_collider.add_child(visual)

	# The shaft is visual only. Colliding it would put a thin bar across the
	# track behind the head, which is a marble trap rather than an obstacle —
	# the head is the thing that is meant to hit anybody.
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = SHAFT_RADIUS
	shaft_mesh.bottom_radius = SHAFT_RADIUS
	shaft_mesh.height = 1.0
	_shaft = MeshInstance3D.new()
	_shaft.mesh = shaft_mesh
	_shaft.material_override = _material(SHAFT_COLOUR)
	# Lying across the track rather than standing up.
	_shaft.rotation = Vector3(0.0, 0.0, PI * 0.5)
	add_child(_shaft)

	_apply(0.0)


func _physics_process(delta: float) -> void:
	_time += delta
	_apply(_extension())


## 0 retracted, 1 fully out.
func _extension() -> float:
	var p := fposmod(_time / CYCLE + phase, 1.0)

	if p < PUNCH_END:
		# Eased at both ends rather than squared. A squared punch is quickest at
		# the moment it reaches the track, which peaks at twice its own average
		# and threw marbles clean off the plate in a probe run; smoothstep peaks
		# at roughly 1.5x instead, and the ram still arrives faster than it
		# leaves.
		return smoothstep(0.0, 1.0, p / PUNCH_END)
	if p < HOLD_END:
		return 1.0
	if p < WITHDRAW_END:
		var t := (p - HOLD_END) / (WITHDRAW_END - HOLD_END)
		return 1.0 - smoothstep(0.0, 1.0, t)
	return 0.0


func _apply(extension: float) -> void:
	var reach := stroke * extension
	_collider.position = Vector3(reach, 0.0, 0.0)
	# The shaft grows out of the wall behind the head rather than sliding with
	# it, so there is never a gap between mounting and ram.
	_shaft.position = Vector3(reach * 0.5, 0.0, 0.0)
	_shaft.scale = Vector3(1.0, maxf(reach, 0.05), 1.0)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	material.metallic = 0.2
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material
