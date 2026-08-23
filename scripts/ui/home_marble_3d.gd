class_name HomeMarble3D
extends Node3D

## Lightweight 3D presentation of the player's actual marble style on Home.
## This intentionally mirrors Marble.gd's sphere/material setup without creating
## a RigidBody3D: the home marble is an idle visual, not a simulation body.
## Keep this cheap for low-end Android: one sphere, one shadowless light and a
## simple physical-looking track.

const MARBLE_RADIUS := 0.62
const TRACK_Y := 0.0
const MARBLE_Y := MARBLE_RADIUS + 0.03
const SPEED := 1.65
const TRACK_LEFT := -5.0
const TRACK_RIGHT := 5.0

var _marble: MeshInstance3D
var _marble_material: StandardMaterial3D
var _direction := 1.0

static func create(colour: Color) -> HomeMarble3D:
	var root := HomeMarble3D.new()
	root._build(colour)
	return root

func _ready() -> void:
	if _marble == null:
		_build(Color(0.95, 0.35, 0.12))

func _build(colour: Color) -> void:
	# Ground / track: deliberately simple geometry. The background provides the
	# illustrated world; this is the small physical surface the marble lives on.
	var track := MeshInstance3D.new()
	var track_mesh := BoxMesh.new()
	track_mesh.size = Vector3(11.8, 0.22, 1.7)
	track.mesh = track_mesh
	var track_material := StandardMaterial3D.new()
	track_material.albedo_color = Color(0.40, 0.22, 0.12)
	track_material.roughness = 0.9
	track.material_override = track_material
	track.position = Vector3(0.0, TRACK_Y - 0.11, 0.0)
	add_child(track)

	# A slightly raised lighter strip makes the track read as a designed piece,
	# not a floating brown rectangle.
	var surface := MeshInstance3D.new()
	var surface_mesh := BoxMesh.new()
	surface_mesh.size = Vector3(11.4, 0.08, 1.35)
	surface.mesh = surface_mesh
	var surface_material := StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.72, 0.39, 0.17)
	surface_material.roughness = 0.82
	surface.material_override = surface_material
	surface.position = Vector3(0.0, TRACK_Y + 0.01, 0.0)
	add_child(surface)

	# The same low-poly sphere proportions and material treatment as Marble.gd.
	_marble = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = MARBLE_RADIUS
	sphere.height = MARBLE_RADIUS * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	_marble.mesh = sphere
	_marble_material = StandardMaterial3D.new()
	_marble_material.albedo_color = colour
	_marble_material.metallic = 0.1
	_marble_material.roughness = 0.25
	_marble_material.rim_enabled = true
	_marble_material.rim = 0.75
	_marble_material.rim_tint = 0.35
	_marble.material_override = _marble_material
	_marble.position = Vector3(TRACK_LEFT, MARBLE_Y, 0.0)
	add_child(_marble)

	# Small dark contact pad. It is cheaper and more controllable than a real
	# shadow map, and remains readable on low-end devices and Web builds.
	var shadow := MeshInstance3D.new()
	var shadow_mesh := QuadMesh.new()
	shadow_mesh.size = Vector2(1.25, 0.42)
	shadow.mesh = shadow_mesh
	var shadow_material := StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0.08, 0.03, 0.015, 0.35)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.material_override = shadow_material
	shadow.position = Vector3(0.0, TRACK_Y + 0.045, 0.35)
	shadow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(shadow)

func set_colour(colour: Color) -> void:
	if _marble_material != null:
		_marble_material.albedo_color = colour

func _process(delta: float) -> void:
	if _marble == null:
		return

	_marble.position.x += SPEED * _direction * delta
	if _marble.position.x >= TRACK_RIGHT:
		_marble.position.x = TRACK_RIGHT
		_direction = -1.0
	elif _marble.position.x <= TRACK_LEFT:
		_marble.position.x = TRACK_LEFT
		_direction = 1.0

	# Real rolling: angular distance = linear distance / radius.
	_marble.rotate_z(-(_direction * SPEED * delta) / MARBLE_RADIUS)
