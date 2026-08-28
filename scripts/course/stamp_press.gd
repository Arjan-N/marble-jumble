class_name StampPress
extends AnimatableBody3D

## A slab that drops out of the gantry onto one lane, sits there, and lifts.
##
## The fourth machine on `FoundryCourse`, and the first obstacle in the codebase
## that *occupies* rather than strikes. Everything else here is an event with a
## duration of nothing: a bumper arm sweeps past, a ram punches and withdraws, a
## hammer connects once. A press is a piece of the track that is missing for a
## while — a marble does not get hit by it, it gets *shut out* by it, and has to
## be somewhere else instead.
##
## That makes it the timing obstacle a wide plate actually needs. `PistonRam`
## reaches a little over a quarter of the way across and is therefore something
## you can be beside; a press closes a whole lane and stays closed for a third of
## its cycle, so the field has to spread around it rather than wait it out.
##
## **It seats high on purpose.** The closed slab stops `SEAT` above the plate,
## which is *below* a marble's equator. A press that seated flush would catch a
## marble under a descending face and drive it into a floor with nowhere to go —
## the concave plate mesh is one-sided, so anything forced through it is gone.
## Meeting the marble under its widest point instead means the closing face
## wedges it sideways out of the lane, which is the outcome that reads as a
## machine shoving something out of the way rather than as physics failing.
##
## Like `PistonRam`, the body itself never moves — the collider child does. The
## guide columns are siblings of it, so they stand still while the slab runs
## between them.

const SLAB_HEIGHT := 1.4
## Down-course. Short: a press is a shut door, not a tunnel, and a marble should
## be able to see past it to the lane it has to take instead.
const SLAB_LENGTH := 1.3

## Height of the underside above the plate when open. Clear of a 0.9m marble
## with enough room over it that a marble thrown by a hammer still passes.
const OPEN_LIFT := 2.4
## Height of the underside above the plate when closed. See the header: this is
## deliberately under a marble's radius, not zero.
const SEAT := 0.30

const GUIDE_THICKNESS := 0.22

const SLAB_COLOUR := Color(0.62, 0.45, 0.16)
const STRIPE_COLOUR := Color(0.16, 0.16, 0.18)
const GUIDE_COLOUR := Color(0.42, 0.43, 0.46)

## One full down-and-up, in seconds. Longer than `PistonRam.CYCLE` because the
## closed phase has to last long enough for the field to have to go round it; at
## the ram's 2.3 the lane reopens before anybody has committed to another one.
const CYCLE := 3.2
## Fractions of `CYCLE`: drop, sit closed, lift, then dwell open.
##
## The lift is slower than the drop, for the reason `PistonRam` gives about its
## own withdrawal — a fast lift picks up whatever the slab has wedged and flicks
## it into the gantry.
const DROP_END := 0.20
const CLOSED_END := 0.46
const LIFT_END := 0.74

## Across-track span of the slab.
@export var slab_width: float = 4.0
## Where in the cycle this press starts, 0..1. A line of presses on one phase is
## a single door; staggered, it is a slalom whose gates move.
@export var phase: float = 0.0

var _time := 0.0
var _collider: CollisionShape3D


static func create(width: float, start_phase: float) -> StampPress:
	var press := StampPress.new()
	press.name = "StampPress"
	press.slab_width = width
	press.phase = start_phase
	press._build()
	return press


func _build() -> void:
	sync_to_physics = true

	var shape := BoxShape3D.new()
	shape.size = Vector3(slab_width, SLAB_HEIGHT, SLAB_LENGTH)
	_collider = CollisionShape3D.new()
	_collider.shape = shape
	add_child(_collider)

	var mesh := BoxMesh.new()
	mesh.size = shape.size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(SLAB_COLOUR)
	_collider.add_child(visual)

	# Hazard banding on the leading face. The slab is the one thing here that is
	# sometimes not where it was a second ago, and a plain block reads as scenery
	# until it has already closed on somebody.
	for side: float in [-1.0, 1.0]:
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(slab_width * 0.98, 0.26, SLAB_LENGTH * 1.02)
		var stripe := MeshInstance3D.new()
		stripe.mesh = stripe_mesh
		stripe.material_override = _material(STRIPE_COLOUR)
		stripe.position = Vector3(0.0, side * 0.34, 0.0)
		stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_collider.add_child(stripe)

	_build_guides()
	_apply(0.0)


## Visual only, and siblings of the collider rather than children, so they stay
## put while the slab runs. Colliding them would put two permanent posts in the
## middle of the track, which is the thing the press is specifically not.
func _build_guides() -> void:
	var height := OPEN_LIFT + SLAB_HEIGHT
	for side: float in [-1.0, 1.0]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(GUIDE_THICKNESS, height, GUIDE_THICKNESS)
		var guide := MeshInstance3D.new()
		guide.mesh = mesh
		guide.material_override = _material(GUIDE_COLOUR)
		guide.position = Vector3(
			side * (slab_width * 0.5 + GUIDE_THICKNESS * 0.5), height * 0.5, 0.0
		)
		add_child(guide)


func _physics_process(delta: float) -> void:
	_time += delta
	_apply(_closure())


## 0 fully open, 1 seated.
func _closure() -> float:
	var p := fposmod(_time / CYCLE + phase, 1.0)

	if p < DROP_END:
		return smoothstep(0.0, 1.0, p / DROP_END)
	if p < CLOSED_END:
		return 1.0
	if p < LIFT_END:
		return 1.0 - smoothstep(0.0, 1.0, (p - CLOSED_END) / (LIFT_END - CLOSED_END))
	return 0.0


func _apply(closure: float) -> void:
	var underside := lerpf(OPEN_LIFT, SEAT, closure)
	_collider.position = Vector3(0.0, underside + SLAB_HEIGHT * 0.5, 0.0)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.75
	material.metallic = 0.2
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material
