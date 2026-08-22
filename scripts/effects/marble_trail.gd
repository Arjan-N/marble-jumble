class_name MarbleTrail
extends MeshInstance3D

## A short ribbon left behind the player's marble, in the marble's own colour.
##
## The rim highlight and emission pulse on `marble.gd` were the only in-world
## identification, and neither survives the way the game actually renders: the
## Compatibility renderer has no glow, so emission reads as plain brightness, and
## a rim light is a grazing-angle effect that all but vanishes under the steeply
## pitched camera in `chase_camera.gd`. A trail has none of those problems —
## it is a moving band of colour with real screen area, and it is still readable
## when the marble itself is buried in a pile-up.
##
## Drawn procedurally, like every other visual in the project: Phase 0 has no
## art pipeline, and `cut_marker.gd` is the template for the material.

## How far back the trail reaches, as a number of samples at SAMPLE_INTERVAL.
## Roughly 0.8s — long enough to read as a streak, short enough that it does not
## draw a map of the last corner across the track.
const MAX_SAMPLES := 24
const SAMPLE_INTERVAL := 1.0 / 30.0
## A marble sitting still would otherwise pile every sample onto the same point
## and collapse the ribbon into a flickering blob.
const MIN_SAMPLE_DISTANCE := 0.15
## Width at the head, as a fraction of the marble's radius. Narrower than the
## marble so the ribbon reads as trailing from it rather than as a second body.
const HEAD_WIDTH_RATIO := 1.2
const MAX_ALPHA := 0.7

var _colour: Color
var _radius: float
var _samples: PackedVector3Array = PackedVector3Array()
var _sample_age := 0.0
var _mesh: ImmediateMesh


static func create(colour: Color, radius: float) -> MarbleTrail:
	var trail := MarbleTrail.new()
	trail.name = "MarbleTrail"
	trail._colour = colour
	trail._radius = radius
	trail._build()
	return trail


func _build() -> void:
	# The marble is a RigidBody3D sphere that spins fast. Without this the
	# ribbon inherits that rotation and whips around the marble instead of
	# lying in the world where it was laid down.
	top_level = true

	_mesh = ImmediateMesh.new()
	mesh = _mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# The fade along the ribbon lives in the vertex colours, so one material
	# covers the whole strip rather than a gradient texture per marble.
	material.vertex_color_use_as_albedo = true
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Drops the whole ribbon. Called when the marble is reset or is not racing, so
## a fresh round does not open with a streak stretching back to where the
## previous round's marble happened to be.
func clear() -> void:
	_samples.clear()
	_sample_age = 0.0
	_mesh.clear_surfaces()


func _process(delta: float) -> void:
	var marble := get_parent() as Marble
	if marble == null:
		return

	if marble.state != Marble.State.RACING:
		if not _samples.is_empty():
			clear()
		return

	_sample_age += delta
	if _sample_age >= SAMPLE_INTERVAL:
		_sample_age = 0.0
		_add_sample(marble.global_position)

	_rebuild()


func _add_sample(at: Vector3) -> void:
	if not _samples.is_empty() and _samples[_samples.size() - 1].distance_to(at) < MIN_SAMPLE_DISTANCE:
		return

	_samples.append(at)
	if _samples.size() > MAX_SAMPLES:
		_samples.remove_at(0)


## Rebuilt every frame rather than appended to: the ribbon has to face the
## camera, and the camera moves even when the marble does not.
func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var camera_position := camera.global_position
	var head_width := _radius * HEAD_WIDTH_RATIO
	var last := _samples.size() - 1

	# Collected before drawing: `surface_end` on an empty surface is an error,
	# and degenerate segments — two samples on top of each other, or one the
	# camera happens to be looking straight down the length of — drop out here.
	var strip: Array = []
	for i in _samples.size():
		var point := _samples[i]
		# The direction the ribbon runs in at this point, taken from its
		# neighbours so the band stays smooth through a corner instead of kinking.
		var previous := _samples[maxi(i - 1, 0)]
		var following := _samples[mini(i + 1, last)]
		var along := following - previous
		if along.is_zero_approx():
			continue

		var side := along.cross(camera_position - point)
		if side.is_zero_approx():
			continue
		side = side.normalized()

		# 0 at the oldest sample, 1 at the marble: the ribbon is widest and most
		# opaque where it leaves the marble, and dies out behind it.
		var t := float(i) / float(last)
		var half := head_width * t * 0.5
		strip.append([point, side * half, Color(_colour.r, _colour.g, _colour.b, MAX_ALPHA * t)])

	if strip.size() < 2:
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for entry: Array in strip:
		var point: Vector3 = entry[0]
		var offset: Vector3 = entry[1]
		var colour: Color = entry[2]
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(point - offset)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(point + offset)
	_mesh.surface_end()
