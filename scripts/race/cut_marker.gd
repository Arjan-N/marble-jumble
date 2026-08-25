class_name CutMarker
extends Node3D

## A visible line across the track at the current elimination cut, following
## whichever marble currently holds the last surviving place — the same
## boundary the standings column already draws as text (PROJECT.md section 3:
## the top half of the field survives each round), made spatial so a viewer
## can see how far ahead or behind the cut the pack is without reading a rank
## number in the corner.
##
## Fitted to the track by probing it rather than by being placed on it. It began
## as a single box spanning the track, which is only ever right on a course that
## is flat in cross-section, and no course is: the canyon's floor is flat across
## half its width and then curves up into walls 2.4m high, and every course banks
## into its corners. A straight bar across that is buried at both ends — the line
## vanished into the rock exactly where the pack was.
##
## So the shape is not assumed. Each frame the marker casts a row of rays down at
## the track and lays a ribbon through wherever they land, which fits a trough, a
## bank, a ramp and a gap identically, and needs no course to describe its own
## cross-section. The cost is a row of raycasts per physics tick, which for one
## marker is nothing.

## Matches the HUD's own cut-line colour (#ff9d4d in race_hud.gd).
const MARKER_COLOUR := Color(1.0, 0.616, 0.302)

## Probes across the track. The ribbon has to follow a quadratic wall fillet, and
## much coarser than this it visibly chords across the curve it is tracing. Kept
## generous because the width asked for is the finish gate's, not the trough's: at a
## narrow section most of the row lands outside the track and is discarded.
const SAMPLES := 25
## Down-course width of the ribbon, in metres. Wider than the old bar was thick:
## that one stood 0.5m proud of the floor and caught the eye side-on, where this
## lies flat and is seen at a glancing angle from a camera behind the pack.
const DEPTH := 0.6
## How far each vertex sits off the surface it found. Enough to clear z-fighting
## against a face the ray hit exactly; small enough that the line still reads as
## painted onto the track rather than hovering above it.
const LIFT := 0.05
## Vertical span of the probe either side of the centreline, in metres. Up has to
## start above the trough walls; down only has to reach a floor that has fallen
## away beneath them.
const PROBE_UP := 4.0
const PROBE_DOWN := 3.0
## Non-track hits a single probe will skip before giving up. A marble sitting on
## the cut line is by definition exactly where this marker is, and its roof is not
## the surface we are looking for.
const MAX_SKIPS := 4

var _mesh: ImmediateMesh
var _material: StandardMaterial3D


static func create() -> CutMarker:
	var marker := CutMarker.new()
	marker.name = "CutMarker"
	marker._build()
	return marker


func _build() -> void:
	_mesh = ImmediateMesh.new()

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(MARKER_COLOUR.r, MARKER_COLOUR.g, MARKER_COLOUR.b, 0.55)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.emission_enabled = true
	_material.emission = MARKER_COLOUR
	_material.emission_energy_multiplier = 0.6

	var visual := MeshInstance3D.new()
	visual.mesh = _mesh
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)


## Lays the ribbon across the track at `frame` — a course frame whose local -Z
## runs down-course and whose local Y is the surface normal — spanning `width`.
##
## Vertices are built in world space, so the node itself is pinned to the origin
## rather than moved to the cut. Nothing else reads its transform.
func place(frame: Transform3D, width: float) -> void:
	_mesh.clear_surfaces()
	if not is_inside_tree():
		return

	global_transform = Transform3D.IDENTITY

	var space := get_world_3d().direct_space_state
	var half := width * 0.5
	var run := frame.basis.z * (DEPTH * 0.5)

	var found := []
	for i in SAMPLES:
		found.append(_probe(space, frame, lerpf(-half, half, float(i) / float(SAMPLES - 1))))

	# Collected before anything is drawn: a row that found nothing at all must not
	# open a surface, and `surface_end` on an empty one is an error rather than an
	# empty mesh.
	var quads := []
	for i in SAMPLES - 1:
		if found[i] == null or found[i + 1] == null:
			continue
		quads.append([found[i], found[i + 1]])

	if quads.is_empty():
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for quad: Array in quads:
		var a: Vector3 = quad[0]
		var b: Vector3 = quad[1]
		_add_quad(a - run, b - run, b + run, a + run)
	_mesh.surface_end()


## Where the track is directly under `across` metres to the right of the frame's
## centre, or `null` if there is nothing there — the ribbon breaks over a gap in
## the floor rather than spanning it, because a line drawn across a hole claims a
## marble could be at that part of the cut.
func _probe(space: PhysicsDirectSpaceState3D, frame: Transform3D, across: float) -> Variant:
	var query := PhysicsRayQueryParameters3D.create(
		frame * Vector3(across, PROBE_UP, 0.0), frame * Vector3(across, -PROBE_DOWN, 0.0)
	)
	query.collide_with_areas = false

	var exclude: Array[RID] = []
	for attempt in MAX_SKIPS:
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return null
		# Courses build their collision as `StaticBody3D`; marbles are rigid bodies.
		if hit["collider"] is StaticBody3D:
			return hit["position"] + hit["normal"] * LIFT
		exclude.append(hit["rid"])

	return null


func _add_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex: Vector3 in [a, b, c, a, c, d]:
		_mesh.surface_add_vertex(vertex)
