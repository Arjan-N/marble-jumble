class_name HomeMarble3D
extends Node3D

## Home-only presentation layer for the player's marble.
## The visual mesh/material is sourced from the same Marble implementation used
## by the race; Home never changes the race physics or camera.

const RACE_RADIUS := 0.45
const DISPLAY_SCALE := 1.72
const DISPLAY_RADIUS := RACE_RADIUS * DISPLAY_SCALE
const TRACK_Y := 0.0
const MARBLE_Y := DISPLAY_RADIUS + 0.035
const TRACK_LEFT := -3.85
const TRACK_RIGHT := 3.85
const CRUISE_SPEED := 1.15
const ACCELERATION := 2.8
const END_BRAKE_DISTANCE := 1.0

var _marble_visual: MeshInstance3D
var _marble_material: StandardMaterial3D
var _shadow: MeshInstance3D
var _velocity := 0.0
var _direction := 1.0
var _phase := 0.0

static func create(colour: Color) -> HomeMarble3D:
	var root := HomeMarble3D.new()
	root._build(colour)
	return root

func _ready() -> void:
	if _marble_visual == null:
		_build(Color(0.95, 0.35, 0.12))

func _build(colour: Color) -> void:
	_build_track()
	_build_player_marble(colour)
	_build_shadow()

func _build_track() -> void:
	# A shallow chunky foreground platform. The Canyon artwork remains the main
	# environment; this simply gives the marble a physical place to roll.
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(9.25, 0.24, 1.55)
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color("#7c3d1e")
	base_mat.roughness = 0.92
	base.material_override = base_mat
	base.position = Vector3(0.0, TRACK_Y - 0.12, 0.0)
	add_child(base)

	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(9.0, 0.10, 1.25)
	top.mesh = top_mesh
	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color("#c87536")
	top_mat.roughness = 0.88
	top.material_override = top_mat
	top.position = Vector3(0.0, TRACK_Y + 0.02, 0.0)
	add_child(top)

	# Tiny lifted lips make the ends read as a physical U-like turnaround while
	# remaining cheap enough for low-end Android.
	for x in [TRACK_LEFT + 0.20, TRACK_RIGHT - 0.20]:
		var lip := MeshInstance3D.new()
		var lip_mesh := BoxMesh.new()
		lip_mesh.size = Vector3(0.38, 0.22, 1.18)
		lip.mesh = lip_mesh
		lip.position = Vector3(x, TRACK_Y + 0.13, 0.0)
		lip.rotation.z = 0.10 * (-_direction if x < 0.0 else _direction)
		lip.material_override = top_mat
		add_child(lip)

func _build_player_marble(colour: Color) -> void:
	# Reuse the actual race Marble material construction rather than maintaining
	# a second home-specific look. A temporary race marble is used only to obtain
	# its authored mesh/material; no physics body is kept alive on Home.
	var source := Marble.create(0, MarbleTuning.new(), colour, true, "Home")
	for child in source.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if mesh.mesh is SphereMesh:
				_marble_visual = MeshInstance3D.new()
				_marble_visual.mesh = mesh.mesh
				_marble_material = mesh.get_active_material(0)
				if _marble_material != null:
					_marble_material = _marble_material.duplicate()
				_marble_visual.material_override = _marble_material
				break
	source.queue_free()

	if _marble_visual == null:
		_marble_visual = MeshInstance3D.new()
		var fallback := SphereMesh.new()
		fallback.radius = RACE_RADIUS
		fallback.height = RACE_RADIUS * 2.0
		fallback.radial_segments = 20
		fallback.rings = 10
		_marble_visual.mesh = fallback
		_marble_material = StandardMaterial3D.new()
		_marble_material.albedo_color = colour
		_marble_material.roughness = 0.25
		_marble_material.rim_enabled = true
		_marble_material.rim = 0.9
		_marble_material.rim_tint = 0.35
		_marble_visual.material_override = _marble_material

	_marble_visual.scale = Vector3.ONE * DISPLAY_SCALE
	_marble_visual.position = Vector3(TRACK_LEFT, MARBLE_Y, 0.0)
	add_child(_marble_visual)

func _build_shadow() -> void:
	_shadow = MeshInstance3D.new()
	var shadow_mesh := QuadMesh.new()
	shadow_mesh.size = Vector2(1.65, 0.50)
	_shadow.mesh = shadow_mesh
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.albedo_color = Color(0.08, 0.025, 0.01, 0.30)
	_shadow.material_override = shadow_mat
	_shadow.position = Vector3(TRACK_LEFT, TRACK_Y + 0.045, 0.38)
	_shadow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(_shadow)

func set_colour(colour: Color) -> void:
	if _marble_material != null:
		_marble_material.albedo_color = colour

func _process(delta: float) -> void:
	if _marble_visual == null:
		return

	# Smoothly accelerate and brake near each end instead of hitting a hard
	# position clamp. The slight vertical lift at the ends sells the turnaround.
	var distance_to_end := (TRACK_RIGHT - _marble_visual.position.x) if _direction > 0.0 else (_marble_visual.position.x - TRACK_LEFT)
	var target_speed := CRUISE_SPEED
	if distance_to_end < END_BRAKE_DISTANCE:
		target_speed *= smoothstep(0.0, END_BRAKE_DISTANCE, distance_to_end)

	_velocity = move_toward(_velocity, target_speed * _direction, ACCELERATION * delta)
	_marble_visual.position.x += _velocity * delta

	if _marble_visual.position.x >= TRACK_RIGHT:
		_marble_visual.position.x = TRACK_RIGHT
		_direction = -1.0
		_velocity = 0.0
	elif _marble_visual.position.x <= TRACK_LEFT:
		_marble_visual.position.x = TRACK_LEFT
		_direction = 1.0
		_velocity = 0.0

	_phase += delta * 2.2
	var end_factor := clampf(1.0 - distance_to_end / END_BRAKE_DISTANCE, 0.0, 1.0)
	_marble_visual.position.y = MARBLE_Y + sin(_phase) * 0.018 + end_factor * 0.035
	_marble_visual.rotate_z(-(_velocity * delta) / DISPLAY_RADIUS)

	if _shadow != null:
		_shadow.position.x = _marble_visual.position.x
		_shadow.scale.x = 1.0 + end_factor * 0.10
