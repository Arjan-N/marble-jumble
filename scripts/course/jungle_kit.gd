class_name JungleKit
extends RefCounted

## The reusable jungle prop set: nine meshes, one palette, and the placement
## helpers that turn them into a forest.
##
## The rule this is built to is the brief's, and it is a performance rule before
## it is an art one: **visual richness without geometric richness**. There is one
## trunk in the game and one crown, and the four hundred trees beside the course
## are that pair scaled, rotated and tinted. Everything here goes out through
## `Landscape.scatter`, which is a `MultiMesh` — so a band of two hundred ferns
## is one draw call. Measured on `JungleRiverCourse` with `probe_river_cost.gd`:
## about 2,250 instances across 24 `MultiMesh` draw calls.
##
## Nothing built here collides or casts a shadow. Props that a marble can touch
## are the course's business (`JungleRiverCourse` builds its boulders and its
## fallen tree itself, with their own colliders); everything in this file is
## scenery, and the moment scenery can be hit it stops being scenery and becomes
## geometry that has to be probed and tuned. `Landscape`'s header makes the same
## argument at more length.
##
## ## Distance bands
##
## The brief asks for three levels of detail and this is where they are defined,
## as metres out from the bank crest rather than as an LOD system — a static
## course under a locked camera does not need one, and a `visibility_range` per
## instance would cost more than the triangles it saved.
##
## - `NEAR` — ferns, leaves, roots and mossy rocks along the crest. Small meshes,
##   many of them, all within the ten metres either side that the low camera
##   actually resolves.
## - `MID` — trees. Trunk plus two crowns each, because one sphere on a stick
##   reads as a lollipop and two overlapping ones read as a canopy.
## - `FAR` — big crowns only, no trunks. At sixty metres through fog a trunk is
##   two pixels of brown, and the shape of the treeline is the entire content of
##   that band. The treeline *itself* is not built here — it is the far end of
##   `TerrainShell.ground_profile` rising into the frame, which costs nothing
##   because the ground mesh has to exist anyway.

# --- Palette ------------------------------------------------------------------
#
# Written darker and less saturated than they look on a swatch, for the reason
# `TempleRunCourse` records: the ambient here is green and the sun is bright, so
# a colour painted at full strength renders as fluorescent. The green has to
# arrive from the light as much as from the albedo.

const CANOPY := Color(0.14, 0.26, 0.14)
const FOLIAGE := Color(0.20, 0.36, 0.17)
const UNDERGROWTH := Color(0.17, 0.29, 0.14)
const FROND := Color(0.20, 0.36, 0.16)
const TRUNK := Color(0.24, 0.18, 0.13)
const ROOT := Color(0.28, 0.21, 0.14)
const ROCK := Color(0.29, 0.28, 0.25)
const MOSS := Color(0.20, 0.31, 0.16)

const DIRT := Color(0.31, 0.22, 0.15)
const DIRT_DARK := Color(0.22, 0.16, 0.11)
const MUD := Color(0.27, 0.21, 0.14)
const RIVERBED := Color(0.42, 0.35, 0.25)
const WATER := Color(0.14, 0.32, 0.31, 0.80)

# --- Bands --------------------------------------------------------------------

## Measured out from the bank crest, not from the centreline.
##
## Pulled hard inwards after the first render. `ChaseCamera.Mode.LOW` is a 26
## degree horizontal lens at 30m, which is about seven metres of visible width at
## the focus — so a band that starts eight metres past a crest that is itself
## eleven metres from the centreline puts its nearest tree twenty metres off
## axis, and twenty metres off axis is off camera. The first pass rendered a
## dense, convincing jungle that was almost entirely invisible from the only
## viewpoint the game ever uses.
const NEAR_INNER := 0.2
const NEAR_OUTER := 7.0
## Trunks start a couple of metres past the crest. Nearer than that and a tree
## stands in the racing line; further and it never enters the frame at all.
const MID_INNER := 1.2
const MID_OUTER := 38.0
const FAR_INNER := 44.0
const FAR_OUTER := 100.0

# --- Meshes -------------------------------------------------------------------
#
# Nine in total. Every one is built once per course and instanced; the segment
# counts are as low as the silhouette survives, and none of them has a texture.


## Every mesh the kit has handed out, keyed by name.
##
## The brief asks for "approximately 10-20 unique environment meshes", and
## without this the kit quietly missed it by an order of magnitude: each
## `group(JungleKit.fern(), ...)` call built a *new* fern, and the course makes
## those calls from six places. A cost probe over the built scene reported 165
## unique meshes where the design called for nine.
##
## Static, so it also holds across the courses in one session. Every mesh here is
## immutable once built and every user instances it through a `MultiMesh` or a
## per-node transform, so sharing is safe.
static var _cache: Dictionary = {}


static func _shared(key: String, build: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


## Tapered, six-sided, one metre tall so a scale is a height in metres.
static func trunk() -> Mesh:
	return _shared("trunk", _build_trunk)


static func _build_trunk() -> Mesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.58
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


## The canopy ball. Seven segments rather than eight because an odd count means
## no two instances rotated 180 degrees apart present the same silhouette.
static func crown() -> Mesh:
	return _shared("crown", _build_crown)


static func _build_crown() -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 7
	mesh.rings = 4
	return mesh


## The cheap ball, for scrub near the track and for the whole far band.
static func blob() -> Mesh:
	return _shared("blob", _build_blob)


static func _build_blob() -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 5
	mesh.rings = 2
	return mesh


## One broad tropical leaf: a tapered strip, six triangles, lying in XZ with its
## stem at the origin and its tip at +Z. Single-sided — `emit` draws the kit with
## culling disabled, so a leaf is solid from beneath without a second copy of it.
static func leaf() -> Mesh:
	return _shared("leaf", _build_leaf)


static func _build_leaf() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Stem, shoulder, waist, tip. Lifted slightly along the length so the blade
	# arches instead of lying dead flat on the ground it is planted in.
	var spine := [
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.18, 0.35),
		Vector3(0.0, 0.22, 0.75),
		Vector3(0.0, 0.10, 1.0),
	]
	var widths := [0.05, 0.24, 0.18, 0.0]

	# One winding only. The blade used to be built twice, front and back, so it
	# would not be a hole seen from beneath — but `emit` already renders the whole
	# kit with `CULL_DISABLED`, so the second copy was drawing the same triangles
	# a second time for nothing. The fern is five of these and the fern is the
	# most numerous prop on the course, which made this the single largest
	# triangle saving available: 40 per fern down to 20.
	for i in range(spine.size() - 1):
		var a: Vector3 = spine[i]
		var b: Vector3 = spine[i + 1]
		var wa: float = widths[i]
		var wb: float = widths[i + 1]
		var quad := [
			a + Vector3(-wa, 0.0, 0.0), b + Vector3(-wb, 0.0, 0.0),
			a + Vector3(wa, 0.0, 0.0), b + Vector3(wb, 0.0, 0.0),
		]
		for index: int in [0, 1, 2, 2, 1, 3]:
			tool.add_vertex(quad[index])

	tool.generate_normals()
	return tool.commit()


## A fern: five leaves fanned about a common stem, as one mesh. Built as a single
## mesh rather than five instances because a fern is always five leaves — paying
## five transforms to say so would quintuple the instance count of the densest
## band on the course for no visual gain.
static func fern() -> Mesh:
	return _shared("fern", _build_fern)


static func _build_fern() -> Mesh:
	var blade := leaf()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in 5:
		var yaw := TAU * float(i) / 5.0 + 0.4
		var pitch := deg_to_rad(-22.0 - float(i % 2) * 14.0)
		var frame := Transform3D(
			Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch),
			Vector3(0.0, 0.12, 0.0)
		).scaled_local(Vector3(1.0, 1.0, 0.75 + float(i % 3) * 0.18))
		tool.append_from(blade, 0, frame)

	tool.generate_normals()
	return tool.commit()


## A weathered boulder, convex by construction so the same points serve as a
## `ConvexPolygonShape3D` for the course's own colliding rocks — a rock whose
## collider is not its silhouette is a rock marbles bounce off thin air beside.
## `variant` re-proportions it so a handful of rocks are not obviously one rock.
##
## Segments around, and latitude bands from pole to pole. Six and four give
## twenty vertices and thirty-six triangles. Three bands was cheaper and came out
## flat-topped — the polar cap became a wide shallow fan and the boulders read as
## hexagonal paving slabs standing on edge in the riverbed.
const ROCK_SEGMENTS := 6
const ROCK_BANDS := 4


## Per-vertex radius, hashed so a variant is reproducible and two rocks built
## from the same variant are identical.
static func _rock_radius(variant: int, band: int, segment: int) -> float:
	var salt := float(variant * 137 + band * 31 + segment * 7)
	var noise := fmod(absf(sin(salt * 12.9898) * 43758.5453), 1.0)
	return 0.74 + noise * 0.52


## The vertices of one boulder, poles first, then each latitude ring.
##
## This replaced a jittered octahedron, which was the obvious cheap convex solid
## and was wrong for a reason only the rendered frames showed: eight flat
## triangles meeting at six points is a *cut gem*. The first render of this
## course had what looked like emeralds and quartz sitting in the riverbed, and
## no amount of jitter fixed it — the problem was the face count, not the
## symmetry. Fourteen vertices is still trivially cheap and reads as stone.
##
## Squashed on Y (0.62) because a boulder is wider than it is tall, and a
## unit-sphere rock reads as a ball.
static func rock_points(variant: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	points.append(Vector3(0.0, _rock_radius(variant, 0, 0) * 0.62, 0.0))
	points.append(Vector3(0.0, -_rock_radius(variant, ROCK_BANDS, 0) * 0.62, 0.0))

	for band in range(1, ROCK_BANDS):
		var polar := PI * float(band) / float(ROCK_BANDS)
		for segment in ROCK_SEGMENTS:
			var azimuth := TAU * float(segment) / float(ROCK_SEGMENTS)
			var radius := _rock_radius(variant, band, segment)
			points.append(Vector3(
				sin(polar) * cos(azimuth) * radius,
				cos(polar) * radius * 0.62,
				sin(polar) * sin(azimuth) * radius
			))
	return points


## Index of a ring vertex in `rock_points`' ordering.
static func _rock_index(band: int, segment: int) -> int:
	return 2 + (band - 1) * ROCK_SEGMENTS + (segment % ROCK_SEGMENTS)


static func rock(variant: int) -> Mesh:
	return _shared("rock%d" % variant, _build_rock.bind(variant))


static func _build_rock(variant: int) -> Mesh:
	var p := rock_points(variant)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var add := func(a: int, b: int, c: int) -> void:
		tool.add_vertex(p[a])
		tool.add_vertex(p[b])
		tool.add_vertex(p[c])

	for segment in ROCK_SEGMENTS:
		# Cap fan at the north pole, quad bands between the rings, cap fan at the
		# south pole. Wound outward throughout.
		add.call(0, _rock_index(1, segment), _rock_index(1, segment + 1))
		for band in range(1, ROCK_BANDS - 1):
			var near_a := _rock_index(band, segment)
			var near_b := _rock_index(band, segment + 1)
			var far_a := _rock_index(band + 1, segment)
			var far_b := _rock_index(band + 1, segment + 1)
			add.call(near_a, far_a, near_b)
			add.call(near_b, far_a, far_b)
		add.call(1, _rock_index(ROCK_BANDS - 1, segment + 1), _rock_index(ROCK_BANDS - 1, segment))

	tool.generate_normals()
	return tool.commit()


## A fallen log or a standing stump. Eight-sided and untapered, one metre long
## along +Y so a scale is a length.
static func log_mesh() -> Mesh:
	return _shared("log", _build_log)


static func _build_log() -> Mesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.92
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh


## An exposed root: a low arch, four-sided in section. Cheap enough to litter the
## bank crest with, and the single strongest "this ground has been here a long
## time" cue the kit has.
##
## Use it through `arched`, never with a bare `Basis`. `TorusMesh` lies in the XZ
## plane, so an instance placed upright reads as a hoop lying on the ground — the
## first render of this course had rings of them scattered down both banks like
## dropped tyres.
static func root() -> Mesh:
	return _shared("root", _build_root)


static func _build_root() -> Mesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.72
	mesh.outer_radius = 1.0
	mesh.rings = 7
	mesh.ring_segments = 4
	return mesh


## A root standing on edge with its lower half buried, so what shows above the
## ground is an arch. `yaw` turns it about the vertical; the sink is a fraction of
## the radius, because a root that clears the soil is a hoop again.
static func arched(at: Vector3, size: float, yaw: float, sink := 0.45) -> Transform3D:
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI * 0.5)
	return Transform3D(basis.scaled(Vector3(size, size, size)), at - Vector3.UP * size * sink)


## A hanging vine. Four-sided, one metre long, drawn downward from its anchor.
static func vine() -> Mesh:
	return _shared("vine", _build_vine)


static func _build_vine() -> Mesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.06
	mesh.bottom_radius = 0.03
	mesh.height = 1.0
	mesh.radial_segments = 4
	mesh.rings = 1
	return mesh


# --- Placement ----------------------------------------------------------------


## An accumulating bucket of instances for one mesh.
##
## Courses fill several of these while walking the path once, then hand the lot
## to `emit`. Keeping the walk in one loop rather than one loop per prop is what
## makes the props agree with each other — a fern and the tree behind it are
## placed from the same station and the same jitter stream.
class Group:
	var mesh: Mesh
	var name: String
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []

	func _init(prop: Mesh, group_name: String) -> void:
		mesh = prop
		name = group_name

	func add(transform: Transform3D, colour: Color) -> void:
		transforms.append(transform)
		colours.append(colour)

	func count() -> int:
		return transforms.size()


static func group(mesh: Mesh, name: String) -> Group:
	return Group.new(mesh, name)


## One `MultiMeshInstance3D` per non-empty group, all sharing one material.
##
## `Landscape.instance_material` reads the per-instance colour as albedo, so the
## whole jungle — every tint of every leaf — is one material and one shader.
static func emit(parent: Node3D, groups: Array) -> int:
	var material := Landscape.instance_material()
	# Two-sided because `leaf` and `fern` are open shells seen from every angle,
	# and a single material for the whole kit is worth more than culling the
	# back faces of a few hundred spheres.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var total := 0
	for entry in groups:
		var bucket: Group = entry
		if bucket.count() == 0:
			continue
		var node := Landscape.scatter(
			bucket.mesh, bucket.transforms, bucket.colours, bucket.name
		)
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
		total += bucket.count()
	return total


## An upright frame with a random yaw and a size, for a prop standing on ground.
static func planted(at: Vector3, size: Vector3, rng: RandomNumberGenerator) -> Transform3D:
	return Transform3D(
		Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(size), at
	)


## The same, plus a small lean. Used only for props whose heel is buried — a
## leaning trunk shows its base and needs sinking, which is not worth the cost
## for a shape read through fog.
static func leaning(
	at: Vector3, size: Vector3, lean: float, rng: RandomNumberGenerator
) -> Transform3D:
	var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
	basis = basis * Basis(Vector3.RIGHT, rng.randf_range(-lean, lean))
	return Transform3D(basis.scaled(size), at)
