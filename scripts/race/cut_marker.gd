class_name CutMarker
extends Node3D

## A visible line across the track at the current elimination cut, following
## whichever marble currently holds the last surviving place — the same
## boundary the standings column already draws as text (PROJECT.md section 3:
## the top half of the field survives each round), made spatial so a viewer
## can see how far ahead or behind the cut the pack is without reading a rank
## number in the corner.

## Matches the HUD's own cut-line colour (#ff9d4d in race_hud.gd).
const MARKER_COLOUR := Color(1.0, 0.616, 0.302)
const HEIGHT := 0.5
const THICKNESS := 0.12

var _material: StandardMaterial3D


static func create() -> CutMarker:
	var marker := CutMarker.new()
	marker.name = "CutMarker"
	marker._build()
	return marker


func _build() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, HEIGHT, THICKNESS) # x is rescaled per-frame to the track width.

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(MARKER_COLOUR.r, MARKER_COLOUR.g, MARKER_COLOUR.b, 0.55)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.emission_enabled = true
	_material.emission = MARKER_COLOUR
	_material.emission_energy_multiplier = 0.6

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)


## Places the bar at `at`, facing `forward` (down-course), spanning `width`.
func place(at: Vector3, forward: Vector3, width: float) -> void:
	var right := forward.cross(Vector3.UP).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var up := right.cross(forward).normalized()

	global_transform = Transform3D(
		Basis(right, up, -forward), at + Vector3(0.0, HEIGHT * 0.5, 0.0)
	)
	scale = Vector3(width, 1.0, 1.0)
