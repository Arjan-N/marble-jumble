class_name TerrainShell
extends RefCounted

## A racing surface cut *into* the ground, rather than laid on top of it.
##
## Every course in the pool so far builds a ribbon and then decorates around it.
## `CourseBuilder` and `JungleCourse` sweep a trough; `TempleRunCourse` and
## `GlacierFaultCourse` lay flat planes with a kerb and drop a skirt off the
## outside edge. All four share one failure, and it is the single loudest visual
## problem the game has: the racing surface has an *edge*. Past that edge is
## either empty space or a separate ground mesh that does not meet it, so the
## track reads as a board held up in front of scenery.
##
## The fix is not more scenery. It is to stop building a track at all and build a
## **trench**: one continuous surface that runs from far out on the left, down a
## dirt bank, across the racing bed, up the other bank and away to the right. The
## bed is the flat middle of that surface. There is no seam at the edge of the
## course because there is no edge — the ground the marbles roll on and the
## ground the trees stand on are the same mesh, welded vertex to vertex at the
## bank crest.
##
## ```text
##    far ground                                              far ground
##  ~~~~~~~~~~~~\                                            /~~~~~~~~~~~~
##               \  bank          bed             bank      /
##                \______        ______        _______     /
##                       \______/      \______/
##                        verge   racing surface   verge
##  |<- no collision ->|<---------- one collider ---------->|<- no collision ->|
## ```
##
## ## What it knows and does not know
##
## Nothing in here is jungle, ice or factory. It takes a `CoursePath`, five
## callables describing the shape at a given distance along it, and a set of
## materials. `JungleRiverCourse` is the first user; the intent (see the brief
## this was written for) is that Factory, Ice and Volcano reuse the same class
## with a different palette and a different `bank_height`, and get the same
## grounding for free.
##
## ## Rolled frames and unrolled ground
##
## The trench is built on the path's own banked frame, so a cambered corner
## carries its banks round with it. The ground past the crest cannot be — hung
## off a rolled frame, the whole jungle leans twenty degrees through a banked
## turn and the trees lean with it.
##
## So the ground starts at the trench's own crest vertices, in world terms, and
## walks outwards along the *unrolled* horizontal. It is welded to the trench at
## the crest and level with the world at distance, which is the only combination
## that has neither a seam nor a leaning forest.
##
## ## Performance
##
## The trench is one `StaticBody3D` per `RUN_SPLIT` metres, each with a single
## `ConcavePolygonShape3D` covering every column and one `MeshInstance3D` per
## *material* — the section is mirror-symmetric, so nine columns are five draws.
## The ground is one mesh per side for the whole course, no collider at all.
##
## Measured on `JungleRiverCourse` (380m) with `tools/probe_river_cost.gd`: 27
## draw calls and about 10,000 triangles for the entire terrain, banks, verges,
## bed and jungle floor included.

## Metres of course per collision body. One shape for a whole course would work,
## but a 400m concave shape is also a 400m bounding box, which defeats every
## broadphase and culling decision the engine would otherwise make for free.
##
## 90 rather than the 48 this started at. Each run is a body *and* five
## `MeshInstance3D`, so the split is a draw-call multiplier as much as a culling
## aid: at 48 a four-hundred-metre course spent forty-five draw calls on its own
## terrain, which was most of the frame's budget on a target where the whole
## scene is meant to fit in well under a hundred. The camera holds about sixty
## metres, so runs of ninety still cull usefully.
const RUN_SPLIT := 90.0
## Rows overlap by one step at a run boundary, so two adjacent bodies share a
## face rather than meeting at a hairline a marble can find.
const RUN_OVERLAP := 0.5

# --- Shape --------------------------------------------------------------------

var path: CoursePath
var from_s := 0.0
var to_s := 0.0
## Metres between cross-sections. 1.5 is the coarsest that still reads as smooth
## under the low camera; below about 1.0 the vertex count stops buying anything.
var step := 1.5
## Distances that must be sampled exactly, whatever `step` would otherwise land
## on. Features with a hard edge — the lip of a jump, the wall of a streambed —
## are a step change in `bed_drop`, and a step change only becomes a vertical
## face if there are rows on both sides of it. Left to a fixed stride the same
## edge comes out as a random ramp whose angle depends on where the stride
## happened to fall, which is not a thing a course can tune.
var key_stations: Array[float] = []

## `(s: float) -> float` — half-width of the flat racing bed, in metres.
var half_width: Callable
## `(s: float, side: float) -> float` — height of the bank crest above the bed,
## per side, so the outside of a corner can be walled higher than the inside.
var bank_height: Callable
## `(s: float) -> float` — how far the bed drops below the path frame. Zero
## almost everywhere; a course uses it to sink a streambed under a jump without
## needing a second geometry path for the gap.
var bed_drop: Callable = func(_s: float) -> float: return 0.0
## `(s: float) -> Transform3D` — the path frame with the camber taken out and Y
## left pointing at the sky, valid past both ends of the path. Supplied by the
## course because only it knows how far it wants the world extrapolated.
var ground_frame: Callable

## The low mud lip between the bed and the bank. Deliberately small: this is the
## "slightly recessed" cue, not containment. A marble that touches it is nudged;
## a marble that means it goes over.
var verge_width := 0.9
## `(s: float) -> float` — height of that lip, per station rather than a
## constant.
##
## It is a profile because a lip is a *corner* wherever something else crosses
## the bed, and a course needs to be able to flatten its own lip at that point.
##
## `JungleRiverCourse` uses it where its fallen log crosses the route. In fairness
## to whoever reads this next: flattening the lip did **not**, on its own, fix the
## stall that prompted it — the marble parked against the log's face rather than
## in the corner beside it, and the fix was raising the ground under the log (see
## that course's `LOG_MOUND`). The profile stays because a raised lip abutting a
## crossing obstacle is a real corner whether or not it was the culprit that day,
## and because the flattened verge is what makes the mound read as silt rather
## than as a bump in a channel.
var verge_lift: Callable = func(_s: float) -> float: return 0.45
## How far out the bank runs from the verge to its crest. Together with
## `bank_height` this sets the bank angle — 3.4m to a 2.2m crest is about 33
## degrees, steep enough to turn a marble back and shallow enough that one which
## climbs it does not simply stop dead against it.
var bank_run := 3.4
## Where the bank splits into a lower and an upper band, as a fraction of its
## height. Purely a material seam, but an important one: the lower band is the
## cut face of whatever the course is carved into, and the upper band is the
## ground surface folding over the top of it. Painted as one material the bank is
## a wall of dirt that stops abruptly where the jungle starts, and the crest
## becomes exactly the hard edge this whole class exists to abolish.
var crest_fraction := 0.45
## Fraction of the bed's half-width taken by the centre strip. Purely a material
## split — the whole bed is flat and at one height. It exists because 400m of
## unbroken colour tells the eye nothing about how fast anything is moving.
var centre_fraction := 0.42
## Index of the centre strip in the nine-column section, for `centre_friction`.
## Named rather than written as 4 in `_build_run`, because the column order is
## `set_materials`' business and a bare index there would be the second place
## that has to agree with it.
const CENTRE_COLUMN := 4

var friction := 0.34
var bounce := 0.08
## Friction of the bed's **centre strip**, when it differs from `friction`.
##
## Negative means "no split": one body per run at `friction`, which is what every
## course before `MeltwaterCourse` gets and is byte-identical to the behaviour
## before this existed.
##
## Set it and the run builds two colliders instead of one — the centre column at
## this value, everything else at `friction` — so the fast line across the bed
## can be a *surface* rather than a shape. `MeltwaterCourse` is polished ice down
## the middle and wind-packed snow on the margins, which turns being shoved wide
## into a cost that camber alone cannot express.
##
## Collision only. The visual split already exists (`centre_fraction`), and the
## two want to agree: a friction change the player cannot see is a change they
## can only learn by losing. It costs no draw calls, because the meshes are still
## grouped by material exactly as before — only the collider is cut in two.
var centre_friction := -1.0

# --- Materials ----------------------------------------------------------------

## One per column, left to right: bank, verge, bed margin, bed centre, bed
## margin, verge, bank. Set through `set_materials` rather than individually so a
## course cannot half-fill it.
var _column_materials: Array[Material] = []
var ground_material: Material

# --- Ground -------------------------------------------------------------------

## `[[metres_out_from_crest, metres_above_crest], ...]`, linearly interpolated.
## The last entry is where the ground stops, and on a course under a low camera
## it wants to be high: the far end of this profile is the horizon, and a profile
## that stays flat draws a strip of sky under the fog instead of a treeline.
var ground_profile: Array = [[10.0, 1.0], [30.0, 3.0], [70.0, 8.0], [110.0, 16.0]]
var ground_columns := 8
## How much the columns bunch towards the track. Above 1 the near ground — the
## part actually on camera — gets the vertices.
var ground_bunch := 1.7
## Amplitude of the seedless relief laid over the profile, at the outermost
## column. Faded to zero at the crest so the weld stays exact.
var ground_relief := 4.5


static func create(course_path: CoursePath, start_s: float, end_s: float) -> TerrainShell:
	var shell := TerrainShell.new()
	shell.path = course_path
	shell.from_s = start_s
	shell.to_s = end_s
	return shell


## Mirrored outwards from the centre strip: crest band, bank face, verge, bed
## margin, bed centre, and back out again.
func set_materials(
	crest: Material, bank: Material, verge: Material, margin: Material, centre: Material
) -> void:
	_column_materials = [
		crest, bank, verge, margin, centre, margin, verge, bank, crest
	]


func build(parent: Node3D) -> void:
	_build_trench(parent)
	_build_ground(parent)


# --- Cross-section ------------------------------------------------------------


## The eight nodes of one cross-section, in the path frame's own (x, y) plane.
##
## Seven columns fall out of it, and every one of them is a flat quad strip. No
## curvature anywhere: the same reasoning `TempleRunCourse` records — a swept
## quadratic shoulder has no natural sense of scale and produced a thirty-metre
## wall the last time a course reached for one.
func section_points(s: float) -> Array:
	var half: float = half_width.call(s)
	var drop: float = bed_drop.call(s)
	var inner := half + verge_width
	var mid := inner + bank_run * 0.5
	var outer := inner + bank_run
	var centre := half * centre_fraction
	var left: float = bank_height.call(s, -1.0)
	var right: float = bank_height.call(s, 1.0)
	var lip: float = verge_lift.call(s)

	# Every height is measured from the bed, not from the path frame, so a bed
	# that drops carries its verge, its banks and — through `crest_point` — the
	# jungle floor down with it. That is what makes a stream crossing a valley
	# cut through the whole trench rather than a slot in an otherwise unbroken
	# one, and it is what stops a raised take-off lip from standing *above* its
	# own mud verge and turning the lip into a cliff on both sides.
	return [
		Vector2(-outer, -drop + left),
		Vector2(-mid, -drop + lerpf(lip, left, crest_fraction)),
		Vector2(-inner, -drop + lip),
		Vector2(-half, -drop),
		Vector2(-centre, -drop),
		Vector2(centre, -drop),
		Vector2(half, -drop),
		Vector2(inner, -drop + lip),
		Vector2(mid, -drop + lerpf(lip, right, crest_fraction)),
		Vector2(outer, -drop + right),
	]


## One cross-section in the course's own space.
func section_row(s: float) -> Array:
	var frame: Transform3D = path.frame_at(s)
	var row := []
	for node: Vector2 in section_points(s):
		row.append(frame * Vector3(node.x, node.y, 0.0))
	return row


## The crest vertex on one side, which is where the ground picks up.
func crest_point(s: float, side: float) -> Vector3:
	var row := section_row(s)
	return row[row.size() - 1] if side > 0.0 else row[0]


## A point on the bank face itself: `t` runs 0 at the top of the verge to 1 at
## the crest.
##
## This is where a course plants the vegetation the player actually sees. Under
## `ChaseCamera.Mode.LOW` the flanks of the frame *are* the bank faces — anything
## past the crest is off-axis and off camera except far up-course — so scenery
## placed only on the ground beyond the crest is scenery nobody ever looks at.
func bank_point(s: float, side: float, t: float) -> Vector3:
	var frame: Transform3D = path.frame_at(s)
	var half: float = half_width.call(s)
	var drop: float = bed_drop.call(s)
	var inner := half + verge_width
	var height: float = bank_height.call(s, side)

	var across := inner + bank_run * clampf(t, 0.0, 1.0)
	var lift := lerpf(verge_lift.call(s), height, clampf(t, 0.0, 1.0))
	return frame * Vector3(side * across, -drop + lift, 0.0)


# --- Trench -------------------------------------------------------------------


func _build_trench(parent: Node3D) -> void:
	var s := from_s
	while s < to_s - 0.01:
		var run_end := minf(s + RUN_SPLIT, to_s)
		_build_run(parent, s, run_end)
		s = run_end - RUN_OVERLAP if run_end < to_s else run_end


## The distances one run is sampled at: the fixed stride, plus every key station
## inside the run, in order and without duplicates.
func _stations(run_from: float, run_to: float) -> Array:
	var stations := []
	var s := run_from
	while s < run_to - 0.01:
		stations.append(s)
		s += step
	stations.append(run_to)

	for key: float in key_stations:
		if key > run_from + 0.001 and key < run_to - 0.001:
			stations.append(key)
	stations.sort()

	var unique := []
	for value: float in stations:
		if unique.is_empty() or value - float(unique[unique.size() - 1]) > 0.002:
			unique.append(value)
	return unique


func _build_run(parent: Node3D, run_from: float, run_to: float) -> void:
	var rows := []
	for s: float in _stations(run_from, run_to):
		rows.append(section_row(s))

	if rows.size() < 2:
		return

	# One collision shape across every column — physics has no opinion about
	# which panel a marble is touching, only where the surface is. The visual is
	# split per column so the bed, the mud lip and the dirt bank read as three
	# materials, which is the whole point of building them as one surface.
	# Grouped by *material*, not by column. The section is a mirror image about
	# its centre, so the two crest bands share one material and so do the two
	# banks, the two verges and the two bed margins — nine columns are five
	# materials. Drawing them per column meant nine `MeshInstance3D` per run and
	# eighty-one for a four-hundred-metre course, which on its own was half the
	# scene's draw calls.
	var all_faces := PackedVector3Array()
	var centre_faces := PackedVector3Array()
	var split_friction := centre_friction >= 0.0
	var by_material := {}

	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(near.size() - 1):
			var quad := PackedVector3Array([
				near[c], far[c], near[c + 1],
				near[c + 1], far[c], far[c + 1],
			])
			if split_friction and c == CENTRE_COLUMN:
				centre_faces.append_array(quad)
			else:
				all_faces.append_array(quad)

			var material: Material = _column_materials[c]
			if not by_material.has(material):
				by_material[material] = PackedVector3Array()
			by_material[material].append_array(quad)

	var body := _collision_body(all_faces, friction)

	# The centre strip's collider is a sibling rather than a second shape on the
	# same body, because `physics_material_override` is per body: two frictions
	# means two bodies. It carries no visual — the meshes below cover the whole
	# section regardless of how the collision was cut.
	if split_friction and not centre_faces.is_empty():
		var centre := _collision_body(centre_faces, centre_friction)
		centre.name = "TrenchCentre"
		parent.add_child(centre)

	for material: Material in by_material:
		body.add_child(_visual(by_material[material], material))

	parent.add_child(body)


func _collision_body(faces: PackedVector3Array, surface_friction: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Trench"
	var surface := PhysicsMaterial.new()
	surface.friction = surface_friction
	surface.bounce = bounce
	body.physics_material_override = surface

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = false
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	return body


func _visual(faces: PackedVector3Array, material: Material) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.generate_normals()

	var node := MeshInstance3D.new()
	node.mesh = tool.commit()
	node.material_override = material
	# The trench casts no shadow on itself. One directional shadow map has to
	# cover a four-hundred-metre course, and spending its resolution on the banks
	# shadowing their own bed is what turns marble shadows — the only cue that
	# says a marble is airborne — into mush.
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


# --- Ground -------------------------------------------------------------------


## Lateral offsets of the ground columns, measured out from the bank crest.
func _ground_offsets() -> Array:
	var last: Array = ground_profile[ground_profile.size() - 1]
	var extent: float = last[0]
	var offsets := []
	for i in range(1, ground_columns + 1):
		var t := float(i) / float(ground_columns)
		offsets.append(pow(t, ground_bunch) * extent)
	return offsets


## Height above the crest at `out` metres from it.
func _ground_lift(out: float) -> float:
	var previous_out := 0.0
	var previous_lift := 0.0
	for entry: Array in ground_profile:
		var node_out: float = entry[0]
		var node_lift: float = entry[1]
		if out <= node_out:
			var t := inverse_lerp(previous_out, node_out, out)
			return lerpf(previous_lift, node_lift, smoothstep(0.0, 1.0, t))
		previous_out = node_out
		previous_lift = node_lift
	return previous_lift


## Everything past the bank crest, as one mesh per side, no collider.
##
## Started from the trench's own crest vertex and walked outward along the
## unrolled horizontal, so the first column is exactly the trench's last column
## and there is no seam to find however hard the corner is banked.
func _build_ground(parent: Node3D) -> void:
	var offsets := _ground_offsets()
	var extent: float = offsets[offsets.size() - 1]

	for side: float in [-1.0, 1.0]:
		# Half the trench's row density — the ground is smooth by construction and
		# nothing rolls on it — but the key stations are kept, because the crest
		# it welds to steps at exactly those distances and a ground row that
		# straddles the step opens a hole beside the jump.
		var rows := []
		var previous := from_s - step * 2.0
		var stations := _stations(from_s, to_s)
		for i in stations.size():
			var s: float = stations[i]
			var keep := i == 0 or i == stations.size() - 1 or key_stations.has(s)
			if not keep and s - previous < step * 1.9:
				continue
			previous = s
			rows.append(_ground_row(s, side, offsets, extent))

		# Rows run down-course and columns run away from the track on the left,
		# but *towards* the viewer's other hand on the right, so one side has to
		# be traversed in reverse for both to wind the same way and face the sky.
		if side > 0.0:
			for i in rows.size():
				(rows[i] as Array).reverse()

		var node := Landscape.stitch(rows, ground_material, "Ground")
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)


func _ground_row(s: float, side: float, offsets: Array, extent: float) -> Array:
	var row := [crest_point(s, side)]
	for offset: float in offsets:
		row.append(ground_point(s, side, offset, extent))
	return row


## A point on the jungle floor: `out` metres from the bank crest on `side`.
##
## Public because everything a course stands on that ground — trees, ferns,
## rocks, a stream running away from the track — has to agree with it to the
## centimetre, and a course computing its own version of this is a course whose
## forest floats.
func ground_point(s: float, side: float, out: float, extent := -1.0) -> Vector3:
	if extent < 0.0:
		var last: Array = ground_profile[ground_profile.size() - 1]
		extent = last[0]

	var crest := crest_point(s, side)
	var level: Transform3D = ground_frame.call(s)
	var direction := (level.basis.x * side).normalized()
	# Relief faded in from the crest so the weld is exact and the landscape is
	# only lumpy where a lump cannot open a hole beside the racing surface.
	var fade := clampf(out / (extent * 0.35), 0.0, 1.0)
	var lift := _ground_lift(out) + Landscape.relief(s, out * side, ground_relief) * fade
	return crest + direction * out + Vector3.UP * lift
