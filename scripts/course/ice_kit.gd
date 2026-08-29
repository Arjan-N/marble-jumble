class_name IceKit
extends RefCounted

## The reusable glacier prop set: seven meshes from one builder, one palette, and
## the placement helpers that turn them into an icefield.
##
## Built to the same rule as `JungleKit` — **visual richness without geometric
## richness**. There is one serac mesh in the game and one pinnacle, and the two
## hundred ice towers beside the course are that pair scaled, rotated and tinted
## through `Landscape.scatter`, which is a `MultiMesh`. Nothing here collides or
## casts a shadow; props a marble can touch are the course's own business, with
## their own colliders, for the reason `Landscape`'s header argues at length.
##
## ## The palette, and why a glacier is not white
##
## `GlacierFaultCourse` is the cautionary example and it is worth being precise
## about what went wrong there, because "add more blue" is not the fix. Every
## colour in that file sits between 0.72 and 0.98 luminance — bed, stone, walls,
## haze and fog alike — so nothing in the frame is darker than anything else and
## the course has no contrast to read shape by. Fog at 0.80/0.90/0.97 then lifts
## the far half further. The result is not "too blue", it is *too evenly lit*: a
## white course photographed on a white day.
##
## What an actual meltwater channel looks like, and what this palette is:
##
## - **The ice is dark.** Wet, polished channel ice is deep cyan — `ICE_DEEP` is
##   0.13/0.31/0.40, darker than the jungle's mud. Ice is only white when it is
##   full of air, which snow is and glacier ice is not.
## - **A cut ice face is the most saturated thing in frame.** `ICE_BLUE` on the
##   bank, because that is the surface with metres of ice behind it.
## - **Glaciers are dirty.** `CRYOCONITE` — wind-blown silt that collects in melt
##   channels — is 0.13 grey, near-black, and it is what stops the bed reading as
##   a bathroom floor. `MORAINE` gravel and `STONE` do the same past the crest.
## - **Snow is the brightest thing here and it is used least**, on the far ground
##   only, and at 0.74 rather than 0.95 — grey-white, not paper.
##
## So the value range runs 0.13 to 0.80 where the old ice course ran 0.72 to
## 0.98. That range is the whole design; the hue is secondary.

# --- Palette ------------------------------------------------------------------
#
# Written for a low warm sun against a deep sky (see `MeltwaterCourse`'s
# environment): the ice reads cold because the *light* is warm and the ambient is
# blue, not because the albedo is cranked. A course that paints cold colours and
# then lights them coldly gets a grey-blue wash, which is the other half of what
# went wrong on the older ice course.

## Wet, polished, load-bearing channel ice. The fast line.
const ICE_DEEP := Color(0.13, 0.31, 0.40)
## The cut face of the bank — metres of compressed ice seen end-on.
const ICE_BLUE := Color(0.20, 0.42, 0.52)
## Bed margins: ice with air and grit in it, walked on by the weather.
const ICE_PALE := Color(0.38, 0.55, 0.60)
## Frost and rime, for edges and highlights. Sparse by design.
const ICE_RIME := Color(0.60, 0.70, 0.73)
## Meltwater standing in the crevasse floor.
const MELT := Color(0.09, 0.28, 0.35, 0.78)

## Wind-blown silt in the melt channels. The reason this course is not white.
const CRYOCONITE := Color(0.13, 0.13, 0.12)
const MORAINE := Color(0.29, 0.26, 0.22)
const MORAINE_DARK := Color(0.18, 0.16, 0.14)
const STONE := Color(0.25, 0.24, 0.25)
const STONE_DARK := Color(0.13, 0.13, 0.14)

## Old compacted snow, and fresh. The brightest values in the kit, and the
## rarest — both live past the crest, never on the bed.
const FIRN := Color(0.60, 0.65, 0.68)
const SNOW := Color(0.73, 0.77, 0.80)

# --- Bands --------------------------------------------------------------------
#
# Metres out from the bank crest, not from the centreline, and sized to the same
# lens `JungleKit` records: `ChaseCamera.Mode.LOW` is a 26 degree horizontal
# view at 30m, which resolves about seven metres of width at the focus. A band
# that starts past ten metres is a band the player never sees.

## Shards, cobbles and rime along the crest — the only band where one instance
## reads as an object rather than as texture.
const NEAR_INNER := 0.2
const NEAR_OUTER := 7.5
## The serac field. Towers, pinnacles and drifts, the band that gives the course
## its skyline.
const MID_INNER := 1.5
const MID_OUTER := 42.0
## Dark rock ridges — nunataks standing out of the ice. Silhouettes only: at
## sixty metres through fog the shape is the entire content.
const FAR_INNER := 48.0
const FAR_OUTER := 110.0

# --- Solids -------------------------------------------------------------------
#
# Every mesh here is one builder with a different vertical profile. `JungleKit`
# records why the obvious cheap convex solid — a jittered octahedron — was wrong
# for stone: eight flat faces meeting at six points is a cut gem, and its first
# render put emeralds in the riverbed. Ice is the one material where that read
# would almost be right, and it is still wrong at this scale: a serac is a
# calved block with a weathered top, not a crystal.

## `[[y, radius], ...]` top to bottom, in a unit solid. A leading or trailing
## entry with radius 0 is a pole; a non-zero one is a flat cap, which is what a
## drift sitting on the ground or a slab lying flat needs.
const SERAC := [[1.0, 0.0], [0.86, 0.46], [0.24, 0.66], [-0.42, 0.80], [-1.0, 0.72]]
const PINNACLE := [[1.0, 0.0], [0.18, 0.30], [-0.58, 0.54], [-1.0, 0.46]]
const COBBLE := [[1.0, 0.0], [0.42, 0.64], [-0.12, 0.80], [-0.62, 0.62], [-1.0, 0.0]]
const DRIFT := [[1.0, 0.0], [0.50, 0.56], [-0.24, 0.90], [-1.0, 0.88]]
const SHARD := [[1.0, 0.0], [0.05, 0.52], [-1.0, 0.30]]
const SLAB := [[1.0, 0.74], [0.05, 0.90], [-1.0, 0.72]]
const RIDGE := [[1.0, 0.0], [0.38, 0.52], [-0.30, 0.86], [-1.0, 0.92]]

## Deterministic per-vertex radius jitter. Hashed rather than seeded so that two
## props built from the same variant are identical without anything having to
## carry an RNG around.
static func _jitter(variant: int, ring: int, segment: int, amount: float) -> float:
	var salt := float(variant * 149 + ring * 37 + segment * 11)
	var noise := fmod(absf(sin(salt * 12.9898) * 43758.5453), 1.0)
	return 1.0 + (noise - 0.5) * 2.0 * amount


## The vertices of one solid: top centre, each ring in order, bottom centre.
##
## Public because a prop the course actually collides with — the ice island, the
## serac gate — needs the same points for a `ConvexPolygonShape3D` that the mesh
## was built from. A collider that disagrees with its own mesh is the one bug in
## this area nobody sees until a marble stops in mid-air.
static func solid_points(
	profile: Array, segments: int, jitter: float, variant: int
) -> PackedVector3Array:
	var points := PackedVector3Array()
	points.append(Vector3(0.0, profile.front()[0], 0.0))

	for ring in profile.size():
		var radius: float = profile[ring][1]
		if radius <= 0.0:
			continue
		var y: float = profile[ring][0]
		for segment in segments:
			var azimuth := TAU * float(segment) / float(segments)
			var r: float = radius * _jitter(variant, ring, segment, jitter)
			points.append(Vector3(cos(azimuth) * r, y, sin(azimuth) * r))

	points.append(Vector3(0.0, profile.back()[0], 0.0))
	return points


## Rings, in the order `solid_points` emits them: every profile entry with a
## radius. Needed to walk the vertex list without re-reading the profile's zeros.
static func _rings(profile: Array) -> Array:
	var rings := []
	for ring in profile.size():
		if profile[ring][1] > 0.0:
			rings.append(ring)
	return rings


static func _build_solid(
	profile: Array, segments: int, jitter: float, variant: int
) -> Mesh:
	var points := solid_points(profile, segments, jitter, variant)
	var rings := _rings(profile)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top := 0
	var bottom := points.size() - 1
	var index := func(ring: int, segment: int) -> int:
		return 1 + ring * segments + (segment % segments)

	var add := func(a: int, b: int, c: int) -> void:
		tool.add_vertex(points[a])
		tool.add_vertex(points[b])
		tool.add_vertex(points[c])

	for segment in segments:
		# Cap fan at the top, quad bands between rings, cap fan at the bottom.
		# Wound outward throughout. A flat cap and a pole are the same fan — the
		# only difference is whether the centre vertex sits level with the ring.
		add.call(top, index.call(0, segment), index.call(0, segment + 1))
		for ring in range(rings.size() - 1):
			var near_a: int = index.call(ring, segment)
			var near_b: int = index.call(ring, segment + 1)
			var far_a: int = index.call(ring + 1, segment)
			var far_b: int = index.call(ring + 1, segment + 1)
			add.call(near_a, far_a, near_b)
			add.call(near_b, far_a, far_b)
		var last := rings.size() - 1
		add.call(bottom, index.call(last, segment + 1), index.call(last, segment))

	tool.generate_normals()
	return tool.commit()


# --- Shared meshes ------------------------------------------------------------

static var _cache := {}


static func _shared(key: String, build: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


## A calved ice tower. Five-sided and strongly jittered, because a serac is a
## block that broke rather than a shape that grew.
static func serac(variant := 1) -> Mesh:
	return _shared("serac%d" % variant, func() -> Mesh:
		return _build_solid(SERAC, 5, 0.30, variant)
	)


static func serac_points(variant := 1) -> PackedVector3Array:
	return solid_points(SERAC, 5, 0.30, variant)


## A narrow spike of ice — the sun-carved kind that stands in fields on a melting
## glacier surface. Cheap, and reads at any distance because it is a silhouette.
static func pinnacle(variant := 1) -> Mesh:
	return _shared("pinnacle%d" % variant, func() -> Mesh:
		return _build_solid(PINNACLE, 5, 0.20, variant)
	)


## Moraine stone. Six-sided and squashed at the instance, per `JungleKit`'s note
## that a unit-sphere rock reads as a ball.
static func cobble(variant := 1) -> Mesh:
	return _shared("cobble%d" % variant, func() -> Mesh:
		return _build_solid(COBBLE, 6, 0.28, variant)
	)


static func cobble_points(variant := 1) -> PackedVector3Array:
	return solid_points(COBBLE, 6, 0.28, variant)


## A snow drift: a dome with a flat base, so it sits *in* the ground rather than
## floating a hemisphere on it.
static func drift(variant := 1) -> Mesh:
	return _shared("drift%d" % variant, func() -> Mesh:
		return _build_solid(DRIFT, 7, 0.14, variant)
	)


## A broken fragment for the near band. Four-sided and heavily jittered — this is
## the one place the cut-gem read is wanted, because at half a metre across
## against dark ice it is exactly what a shard of ice looks like.
static func shard(variant := 1) -> Mesh:
	return _shared("shard%d" % variant, func() -> Mesh:
		return _build_solid(SHARD, 4, 0.40, variant)
	)


## A flat plate of ice, for lying tilted against a bank. Scaled flat in Y at the
## instance rather than in the profile, so one mesh covers every thickness.
static func slab(variant := 1) -> Mesh:
	return _shared("slab%d" % variant, func() -> Mesh:
		return _build_solid(SLAB, 5, 0.22, variant)
	)


## A dark rock ridge for the far band — a nunatak, the rock that stands out
## through the ice. No detail: at sixty metres through fog this is a shape.
static func ridge(variant := 1) -> Mesh:
	return _shared("ridge%d" % variant, func() -> Mesh:
		return _build_solid(RIDGE, 6, 0.24, variant)
	)


# --- Scatter helpers ----------------------------------------------------------
#
# `Group`, `emit`, `planted` and `leaning` are the same four helpers `JungleKit`
# defines, and they are duplicated here on purpose rather than shared yet.
# `course.gd`'s header makes the argument this follows: inventing the shared
# form with two implementations in existence is guessing at what the third one
# needs. Two kits now agree on this shape; a third is the point at which it
# should be hoisted into `Landscape`, next to `scatter` and `instance_material`
# which both of them already call.

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


## One `MultiMeshInstance3D` per non-empty group, all sharing one material that
## reads the per-instance colour as albedo — so every tint of every serac is one
## draw call per mesh.
static func emit(parent: Node3D, groups: Array) -> int:
	var material := Landscape.instance_material()

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


## The same, plus a lean. Séracs lean — a block that calved off an ice cliff and
## settled is never plumb, and a field of vertical towers reads as a fence.
static func leaning(
	at: Vector3, size: Vector3, lean: float, rng: RandomNumberGenerator
) -> Transform3D:
	var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
	basis = basis * Basis(Vector3.RIGHT, rng.randf_range(-lean, lean))
	basis = basis * Basis(Vector3.FORWARD, rng.randf_range(-lean, lean))
	return Transform3D(basis.scaled(size), at)


## A colour walked off a base by a small random amount, for breaking up a band
## without adding a second material. Ice varies in how much air is in it, which
## is a value change rather than a hue change — so this moves lightness only.
static func varied(base: Color, rng: RandomNumberGenerator, spread: float) -> Color:
	var shift := rng.randf_range(-spread, spread)
	if shift >= 0.0:
		return base.lightened(shift)
	return base.darkened(-shift)
