class_name SkyRuinsCourse
extends Course

## Sky Ruins — an ancient stone complex adrift above the clouds.
##
## Where `VolcanoCourse` is enclosed, hot and descending into danger, this one
## is open, bright and exposed: nothing stands between the racing line and a
## long fall to a landscape nobody is meant to survive reaching. The physical
## idea is exposure rather than heat — every hazard here is a version of "the
## edge is right there", from the wide courtyard down to the sprint at the end.
##
## Six beats: Temple Courtyard | Broken Bridge | Spiral | Crumbling Terrace |
## The Leap | Final Temple.
##
## `JungleCourse`'s header records that "several small gaps to thread" does not
## survive contact with physics — a hole with no ramp before it is either wide
## enough that most of the field goes in, or narrow enough that a marble
## bridges and wedges it, and the workable window sits inside a marble's own
## diameter. So Broken Bridge does not put literal holes in the floor; it gets
## its risk the way `JungleCourse`'s open channel does, from a narrow deck with
## nothing but air past its edges. The one hole on this course is The Leap, and
## it gets the ramp-plus-boost treatment `VolcanoCourse` and `JungleCourse` both
## needed to make a gap survivable rather than a filter.
##
## Obstacles stay inside what this codebase already has: one `RotatingBumper`
## (a swinging temple weight, on the bridge) and one `FallingRock` spawner
## (crumbling debris, through the terrace) — no new obstacle types.

# --- Shape --------------------------------------------------------------------

const LENGTH := 175.0
const RAMP_LENGTH := 14.0
const RUNOFF_LENGTH := 8.0

## Section boundaries, as fractions of `LENGTH`.
const COURTYARD_END := 0.16
const BRIDGE_END := 0.38
const SPIRAL_END := 0.62
const TERRACE_END := 0.76
## The Leap's gap sits just past TERRACE_END; Final Temple runs from its
## landing to 1.00.

## Gentle at the start (a courtyard is meant to be crossed, not survived),
## tightening on the bridge, held back through the spiral so the turn reads
## clearly rather than as a slide, urgent through the terrace and into the
## leap, then a fast sprint home. Floor of 5.5°, same minimum every course
## here holds to.
const PITCH := [
	[0.10, 7.0],   ## Temple Courtyard: wide open, barely descending.
	[0.20, 10.5],  ## Onto the Broken Bridge.
	[0.36, 8.5],   ## Broken Bridge proper.
	[0.50, 6.5],   ## Into the Spiral — held back well below the rest of the
	               ## course: extra speed here throws marbles up the banked
	               ## shoulder hard enough to stall them oscillating against
	               ## it rather than carrying them through the turn.
	[0.62, 6.5],   ## Spiral held back so the bank reads as a turn, not a drop.
	[0.70, 12.0],  ## Crumbling Terrace: ground failing underfoot.
	[0.76, 9.0],   ## Approach to the Leap: pitch eases, the boost does the work.
	[0.90, 10.5],  ## Final Temple opens.
	[1.00, 13.5],  ## Sprint to the line.
]

## One long turn is the spiral's whole identity: heading swings hard through
## it and nowhere else. Kept inside `CoursePath.BANK_LIMIT_DEGREES`'s reach by
## spreading the turn across a long span rather than a short one — a sharp
## heading change over a short distance is a corner tight enough to throw
## marbles off the open edge, which is a real hazard here (no walls) rather
## than a texture choice.
const HEADING := [
	[0.16, 0.0],
	[0.30, -10.0],  ## Broken Bridge drifts left, off the courtyard's square line.
	[0.38, -14.0],
	## The Spiral: one long banked arc. Spread across many small steps rather
	## than one jump straight to the end value — `CoursePath`'s smoothing
	## window is a fixed width (`BLEND`), so a single big step still turns
	## sharply inside it no matter how large the step is; this is what
	## `VolcanoCourse` and `JungleCourse`'s own corners do too.
	##
	## Total turn cut back twice: 110° stalled the field mid-corner (marbles
	## thrown up the open, wall-less shoulder and stuck oscillating there
	## rather than carrying through), and cutting to 70° over the same span
	## still stalled it in the same place. `VolcanoCourse` and `JungleCourse`
	## never turn faster than roughly 0.6°/m; this course has no walls to
	## catch a marble the corner throws wide, so it gets less room for error
	## than either, not more. 38° over 63m (0.6°/m) is the turn rate actually
	## proven elsewhere in this codebase, not a guess.
	[0.42, 2.0],
	[0.46, 8.0],
	[0.50, 15.0],
	[0.54, 22.0],
	[0.58, 29.0],
	[0.64, 38.0],
	[0.76, 40.0],  ## Straightened out for the Crumbling Terrace and the Leap.
	[1.00, 30.0],  ## One last easy bend into Final Temple.
]

## Half-width along the course. Wide courtyard for the field to spread out and
## overtake cleanly, squeezed hard on the bridge (the open-edge risk, per the
## header), opened for the spiral's banked line, squeezed again on the
## crumbling terrace, and wide again for the leap's approach and the final
## sprint. Never below 3.2 — under `MIN_GAP`-checked obstacles this stays
## comfortably above two marbles abreast (1.8m).
const WIDTH := [
	[0.05, 7.5],
	[COURTYARD_END, 7.0],
	[0.24, 3.6],   ## Broken Bridge: the deck narrows hard.
	[BRIDGE_END, 3.6],
	[0.46, 6.5],   ## Opening into the Spiral — wide, so a marble thrown out by
	               ## the bank has room to recover rather than climbing the
	               ## shoulder far enough to stall against it.
	[SPIRAL_END, 6.0],
	[0.68, 3.4],   ## Crumbling Terrace: the tightest span on the course.
	[TERRACE_END, 4.4],  ## Widens for the Leap's approach.
	[0.86, 5.4],
	[0.94, 6.4],   ## Final Temple opens out for the sprint.
	[1.00, 5.0],
]

## Dish depth and shoulder, the same proven shape `JungleCourse` and
## `VolcanoCourse` both use unchanged: no crease anywhere, monotonic outward,
## so nothing traps a marble on a track with no walls to fall back on.
const CHANNEL_RISE := 0.85
const SHOULDER := 2.0
const SHOULDER_CURVE := 0.22

const MESH_STEP := 1.0
const SECTION_STEP := 0.4
const RUN_OVERLAP := 0.35

# --- Surfaces -----------------------------------------------------------------

const SURFACE_COURTYARD := {"friction": 0.38, "colour": Color(0.86, 0.76, 0.56)}
const SURFACE_BRIDGE := {"friction": 0.34, "colour": Color(0.78, 0.68, 0.50)}
const SURFACE_SPIRAL := {"friction": 0.30, "colour": Color(0.82, 0.70, 0.48)}
const SURFACE_TERRACE := {"friction": 0.28, "colour": Color(0.72, 0.60, 0.44)}
const SURFACE_LEAP := {"friction": 0.24, "colour": Color(0.80, 0.68, 0.46)}
const SURFACE_TEMPLE := {"friction": 0.32, "colour": Color(0.90, 0.82, 0.62)}

const SURFACES := [
	[COURTYARD_END, SURFACE_COURTYARD],
	[BRIDGE_END, SURFACE_BRIDGE],
	[SPIRAL_END, SURFACE_SPIRAL],
	[TERRACE_END, SURFACE_TERRACE],
	[0.86, SURFACE_LEAP],
	[1.00, SURFACE_TEMPLE],
]
const BOUNCE := 0.14

# --- Temple Courtyard pillars --------------------------------------------------

## A pair of fallen column drums early on — the "early interaction" beat, and
## the field's first split. Round, like `VolcanoCourse`'s boulders, so there is
## no flat face to pin a slow marble against.
const PILLAR_AT := 0.09
const PILLAR_RADIUS := 0.75
const PILLAR_COLOUR := Color(0.80, 0.72, 0.56)
const MIN_GAP := 1.5

# --- Broken Bridge weight -------------------------------------------------------

const BUMPER_AT := 0.30

# --- Crumbling Terrace rockfall -------------------------------------------------

## Debris shaken loose by the terrace failing underfoot — the same spawner
## `VolcanoCourse` uses for its eruption, reused rather than reinvented: one
## `FallingRock` every couple of seconds is enough to make the terrace read as
## collapsing without becoming the race's outcome.
const RUBBLE_FROM := 0.64
const RUBBLE_TO := 0.76
const RUBBLE_INTERVAL_MIN := 1.7
const RUBBLE_INTERVAL_MAX := 2.7
const RUBBLE_DROP_HEIGHT := 9.0

# --- The Leap --------------------------------------------------------------------

## The one true gap on the course. Ramp-then-hole, the shape both
## `JungleCourse` and `VolcanoCourse` needed before a gap here was survivable —
## see the header. Boost guarantees the arrival speed the ramp is sized for.
const KICKER_AT := 0.78
const KICKER_LENGTH := 6.0
const KICKER_RISE := 1.3
const JUMP_GAP := 3.4
const BOOST_SPEED := 13.5

# --- Final Temple -----------------------------------------------------------------

const FINALE_PILLAR_AT := 0.93
const FINALE_PILLAR_RADIUS := 0.7

# --- Decoration -------------------------------------------------------------------

const STONE_COLOUR := Color(0.87, 0.79, 0.61)
const STONE_DARK := Color(0.62, 0.54, 0.40)
const VOID_HAZE_COLOUR := Color(0.72, 0.83, 0.93, 0.55)
const CLOUD_COLOUR := Color(0.98, 0.98, 0.99)
const WATER_COLOUR := Color(0.30, 0.78, 0.75)
const FOLIAGE_COLOUR := Color(0.36, 0.58, 0.30)
const FINISH_COLOUR := Color(0.95, 0.90, 0.72)
## How far below the course the pale cloud-haze plane sits, standing in for
## the huge landscape far underneath — the same relationship
## `VolcanoCourse.LAVA_BELOW` has to its own drop, reskinned from menace to
## vertigo.
const VOID_BELOW := 30.0

var _path: CoursePath


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_channel()
	_build_void_haze()
	_build_back_wall()
	_build_courtyard_pillars()
	_build_bridge_weight()
	_build_clouds()
	_build_waterfalls()
	_build_boost()
	_build_finale_pillars()
	_build_finish_line()

	_start_rubble()


# --- Path -----------------------------------------------------------------------


func _point(s: float) -> Vector3:
	return _path.point_at(s)


## `Course.frame_at` for a course laid out along a `CoursePath`.
##
## Camber comes from the path and the origin comes from the curve, rather than
## both from the path. The curve is a polyline through sampled points, so its
## arc length drifts against the path's by a metre or two over a course, and
## the offset handed in here was measured against the curve — by the camera,
## and by the ranking that decided which marble the cut is at. Taking the
## position from the curve puts the marker where the rest of the race already
## agrees that offset is; the drift only shifts which bank angle is sampled,
## and over a metre of track that is a fraction of a degree.
func frame_at(offset: float) -> Transform3D:
	if curve == null:
		return Transform3D.IDENTITY

	var length := curve.get_baked_length()
	var clamped := clampf(offset, 0.0, length)
	var frame := _frame_at(_path.s_at_curve_offset(clamped, length))
	return Transform3D(frame.basis, curve.sample_baked(clamped))


func _frame_at(s: float) -> Transform3D:
	return _path.frame_at(s)


func _half_width_at(s: float) -> float:
	return _path.sample(WIDTH, s)


func _surface_at(s: float) -> Dictionary:
	var fraction := s / LENGTH
	for entry: Array in SURFACES:
		if fraction <= entry[0]:
			return entry[1]
	return SURFACES[SURFACES.size() - 1][1]


# --- Channel ----------------------------------------------------------------


func _build_channel() -> void:
	for run: Dictionary in _runs():
		var from_s: float = run["from"] - (RUN_OVERLAP if run["lead"] else 0.0)
		var to_s: float = run["to"] + (RUN_OVERLAP if run["trail"] else 0.0)
		_build_run(from_s, to_s, run["surface"])


## The course split into stretches of constant surface with the Leap's gap cut
## out — `VolcanoCourse._runs` unchanged bar the numbers.
func _runs() -> Array:
	var cuts := [-RAMP_LENGTH, LENGTH + RUNOFF_LENGTH]
	for entry: Array in SURFACES:
		cuts.append(entry[0] * LENGTH)
	var hole := _jump_span()
	cuts.append(hole.x)
	cuts.append(hole.y)
	cuts.sort()

	var runs := []
	for i in range(cuts.size() - 1):
		var from_s: float = cuts[i]
		var to_s: float = cuts[i + 1]
		if to_s - from_s < 0.2:
			continue
		if _in_hole((from_s + to_s) * 0.5, hole):
			continue
		runs.append({
			"from": from_s,
			"to": to_s,
			"surface": _surface_at((from_s + to_s) * 0.5),
			"lead": absf(from_s - hole.x) > 0.01 and absf(from_s - hole.y) > 0.01,
			"trail": absf(to_s - hole.x) > 0.01 and absf(to_s - hole.y) > 0.01,
		})
	return runs


func _jump_span() -> Vector2:
	var lip := KICKER_AT * LENGTH + KICKER_LENGTH
	return Vector2(lip, lip + JUMP_GAP)


func _in_hole(s: float, hole: Vector2) -> bool:
	return s > hole.x and s < hole.y


## Height added by the Leap's kicker at `s` — `VolcanoCourse._kicker_lift`
## unchanged bar the numbers: squared on the way up so the lip is where the
## ramp is steepest, held across the (unbuilt) gap, eased back down into the
## landing.
func _kicker_lift(s: float) -> float:
	var from_s := KICKER_AT * LENGTH
	var lip := from_s + KICKER_LENGTH
	var landing := lip + JUMP_GAP
	var settle := 6.0

	if s <= from_s:
		return 0.0
	if s < lip:
		var t := (s - from_s) / KICKER_LENGTH
		return KICKER_RISE * t * t
	return KICKER_RISE * (1.0 - smoothstep(0.0, settle, s - landing))


func _rise_at(_s: float) -> float:
	return CHANNEL_RISE


## One section vertex, `(lateral, lift)` in the local frame — `VolcanoCourse`
## and `JungleCourse`'s dish shape unchanged: the racing width curves upward,
## then the shoulder continues (and steepens) past it so there is no crease
## anywhere to trap a marble.
func _section_point(t: float, s: float) -> Vector2:
	var half_width := _half_width_at(s)
	var rise := _rise_at(s)
	var absolute := absf(t)
	var lift: float

	if absolute <= 1.0:
		lift = rise * absolute * absolute
	else:
		var over := (absolute - 1.0) * half_width
		lift = rise + (2.0 * rise / half_width) * over + SHOULDER_CURVE * over * over

	var lateral := t * half_width
	return Vector2(lateral, lift + _kicker_lift(s))


func _section_norms() -> Array:
	var edge := 1.0 + SHOULDER
	var count := int(ceil(edge / SECTION_STEP))
	var norms := []
	for i in range(-count, count + 1):
		norms.append(clampf(float(i) * SECTION_STEP, -edge, edge))
	return norms


func _build_run(from_s: float, to_s: float, surface: Dictionary) -> void:
	var section := _section_norms()

	var rows := []
	var s := from_s
	while s < to_s - 0.01:
		rows.append(_section_row(s, section))
		s = minf(s + MESH_STEP, to_s)
	rows.append(_section_row(to_s, section))

	if rows.size() < 2:
		return

	var faces := PackedVector3Array()
	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(section.size() - 1):
			faces.append(near[c])
			faces.append(far[c])
			faces.append(near[c + 1])

			faces.append(near[c + 1])
			faces.append(far[c])
			faces.append(far[c + 1])

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.generate_normals()

	var body := StaticBody3D.new()
	body.physics_material_override = _surface_material(surface["friction"])

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = false
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _material(surface["colour"])
	body.add_child(visual)

	add_child(body)


func _section_row(s: float, section: Array) -> Array:
	var frame := _frame_at(s)
	var row := []
	for t: float in section:
		var node := _section_point(t, s)
		row.append(frame * Vector3(node.x, node.y, 0.0))
	return row


# --- Decoration -------------------------------------------------------------


## A pale haze plane far below the open edges, standing in for the huge
## landscape underneath — `VolcanoCourse._build_lava_edges` reskinned from a
## glowing hazard to open sky, the drop kept purely visual: anything that gets
## this far is already eliminated by `fall_threshold_y`.
func _build_void_haze() -> void:
	var s := -RAMP_LENGTH
	while s < LENGTH + RUNOFF_LENGTH:
		var frame := _frame_at(s)

		var floor_mesh := BoxMesh.new()
		floor_mesh.size = Vector3(60.0, 1.0, 14.0)
		var floor_visual := MeshInstance3D.new()
		floor_visual.mesh = floor_mesh
		floor_visual.material_override = _haze_material()
		floor_visual.transform = frame.translated_local(Vector3(0.0, -VOID_BELOW, 0.0))
		add_child(floor_visual)

		s += 14.0


func _haze_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = VOID_HAZE_COLOUR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(Vector3(0.0, 1.2, 0.4)),
		Vector3(_half_width_at(-RAMP_LENGTH) * 2.0, 2.4, 0.8),
		STONE_DARK,
	)


## Two fallen column drums astride the courtyard's centre — the field's first
## split, and its first thing to look at. Round, like `VolcanoCourse`'s
## boulders, so there is no flat face to pin a slow marble against.
func _build_courtyard_pillars() -> void:
	var s := PILLAR_AT * LENGTH
	var half_width := _half_width_at(s)
	var count := 2
	var gap := (half_width * 2.0 - count * PILLAR_RADIUS * 2.0) / float(count + 1)
	_assert_gap(gap, "courtyard pillar row at %.2f" % PILLAR_AT)

	for i in count:
		var offset := -half_width + gap * float(i + 1) + PILLAR_RADIUS * float(i * 2 + 1)
		_add_pillar_drum(s, offset, PILLAR_RADIUS)


func _add_pillar_drum(s: float, offset: float, radius: float) -> void:
	var lift := _section_point(offset / _half_width_at(s), s).y
	var body := StaticBody3D.new()
	body.transform = _frame_at(s).translated_local(Vector3(offset, lift + radius * 0.7, 0.0))
	body.physics_material_override = _surface_material(SURFACE_COURTYARD["friction"])

	var shape := SphereShape3D.new()
	shape.radius = radius
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(STONE_COLOUR)
	body.add_child(visual)

	add_child(body)


## The single Phase 0 obstacle, reskinned as a swinging temple weight over the
## Broken Bridge's narrowest, most exposed span — the course's "chaos/
## collision" beat, right where an open edge makes a knock actually matter.
func _build_bridge_weight() -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _frame_at(BUMPER_AT * LENGTH)
	add_child(bumper)


func _build_boost() -> void:
	var at := KICKER_AT * LENGTH - 3.5
	var frame := _frame_at(at)
	var pad := BoostPad.create(_half_width_at(at) * 2.0, -frame.basis.z, BOOST_SPEED)
	pad.transform = frame.translated_local(Vector3(0.0, 1.2, 0.0))
	add_child(pad)


## A handful of soft, overlapping, semi-transparent spheres standing in for
## clouds — the same construction `VolcanoCourse._build_eruption_plume` uses
## for smoke, reused for the opposite mood. Set well off to the side so none
## of them are ever mistaken for track.
func _build_clouds() -> void:
	var positions := [0.06, 0.34, 0.58, 0.72, 0.90]
	for i in positions.size():
		var s: float = positions[i] * LENGTH
		var side := -1.0 if i % 2 == 0 else 1.0
		var base := _frame_at(s) * Vector3(side * 18.0, -4.0 + float(i) * 1.5, 0.0)

		for j in 3:
			var puff_mesh := SphereMesh.new()
			puff_mesh.radius = 2.6 + float(j) * 1.1
			puff_mesh.height = puff_mesh.radius * 2.0
			var puff := MeshInstance3D.new()
			puff.mesh = puff_mesh
			var material := StandardMaterial3D.new()
			material.albedo_color = CLOUD_COLOUR
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			puff.material_override = material
			puff.position = base + Vector3(float(j) * 1.8, float(j) * 0.6, float(j) * -0.4)
			add_child(puff)


## Turquoise water sheeting off the ruins and vanishing into the haze below —
## purely decorative, the same non-colliding treatment `VolcanoCourse` gives
## its plume, placed clear of the racing line.
func _build_waterfalls() -> void:
	var positions := [0.20, 0.66]
	for fraction: float in positions:
		var s := fraction * LENGTH
		var frame := _frame_at(s)
		var half_width := _half_width_at(s)

		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.4, 16.0, 0.3)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = WATER_COLOUR
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.75
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		visual.material_override = material
		visual.transform = frame.translated_local(
			Vector3(half_width + SHOULDER + 1.5, -8.0, 0.0)
		)
		add_child(visual)

		var vine_mesh := BoxMesh.new()
		vine_mesh.size = Vector3(0.15, 2.5, 0.15)
		var vine := MeshInstance3D.new()
		vine.mesh = vine_mesh
		vine.material_override = _material(FOLIAGE_COLOUR)
		vine.transform = frame.translated_local(
			Vector3(half_width + 0.6, 1.5, 0.0)
		)
		add_child(vine)


## Two upright pillars framing the final sprint — decoration and a last thing
## to read speed against, kept well clear of the racing width so the finish
## stretch never narrows.
func _build_finale_pillars() -> void:
	var s := FINALE_PILLAR_AT * LENGTH
	var half_width := _half_width_at(s)
	for side: float in [-1.0, 1.0]:
		var offset := side * (half_width + 1.4)
		var lift := _section_point(offset / half_width, s).y
		var height := 4.0

		var body := StaticBody3D.new()
		body.transform = _frame_at(s).translated_local(
			Vector3(offset, lift + height * 0.5, 0.0)
		)
		body.physics_material_override = _surface_material(SURFACE_TEMPLE["friction"])

		var shape := CylinderShape3D.new()
		shape.radius = FINALE_PILLAR_RADIUS
		shape.height = height
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

		var mesh := CylinderMesh.new()
		mesh.top_radius = FINALE_PILLAR_RADIUS
		mesh.bottom_radius = FINALE_PILLAR_RADIUS * 1.15
		mesh.height = height
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(STONE_COLOUR)
		body.add_child(visual)

		add_child(body)


func _build_finish_line() -> void:
	var width := _half_width_at(LENGTH) * 2.0

	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.06, 1.0)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(FINISH_COLOUR)
	visual.transform = _frame_at(LENGTH).translated_local(Vector3(0.0, 0.04, 0.0))
	add_child(visual)

	_add_box(
		_frame_at(LENGTH + 6.0).translated_local(Vector3(0.0, 1.2, 0.0)),
		Vector3(width, 2.4, 0.7),
		STONE_DARK,
	)


# --- Crumbling Terrace rubble -------------------------------------------------


## One free-running timer for the whole zone — `VolcanoCourse._start_rockfall`
## unchanged: a rock is a RigidBody3D that lives until `FallingRock.LIFETIME`
## or a fall past the threshold, so the spawner's only job is to place a new
## one every so often while the race is on.
func _start_rubble() -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_rubble_timeout.bind(timer))
	add_child(timer)
	timer.start(randf_range(RUBBLE_INTERVAL_MIN, RUBBLE_INTERVAL_MAX))


func _on_rubble_timeout(timer: Timer) -> void:
	_spawn_rubble()
	if is_instance_valid(timer):
		timer.start(randf_range(RUBBLE_INTERVAL_MIN, RUBBLE_INTERVAL_MAX))


func _spawn_rubble() -> void:
	var s := randf_range(RUBBLE_FROM * LENGTH, RUBBLE_TO * LENGTH)
	var half_width := _half_width_at(s)
	# Kept inside the racing width, not the full shoulder — rubble landing out
	# on the shoulder is rubble nobody racing down the middle ever meets.
	var lateral := randf_range(-half_width * 0.8, half_width * 0.8)
	var lift := _section_point(lateral / half_width, s).y

	var rock := FallingRock.create()
	rock.transform = _frame_at(s).translated_local(
		Vector3(lateral, lift + RUBBLE_DROP_HEIGHT, 0.0)
	)
	add_child(rock)


# --- Helpers ------------------------------------------------------------------


func _assert_gap(gap: float, what: String) -> void:
	assert(
		gap >= MIN_GAP,
		"%s leaves %.2fm, under MIN_GAP (%.2fm); marbles wedge." % [what, gap, MIN_GAP]
	)


func _add_box(transform: Transform3D, size: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new()
	body.transform = transform
	body.physics_material_override = _surface_material()

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(colour)
	body.add_child(visual)

	add_child(body)


func _surface_material(friction := -1.0) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = SURFACE_COURTYARD["friction"] if friction < 0.0 else friction
	material.bounce = BOUNCE
	return material


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


# --- Course interface -----------------------------------------------------------


func fall_threshold_y() -> float:
	return _point(LENGTH).y - 26.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


## Five across, the same grid `VolcanoCourse` and `JungleCourse` both use: the
## channel is narrower than a flat-floored course and its edges are curved, so
## a marble spawned hard against the side starts partway up the camber rather
## than flat.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 5
	var spacing := 1.7

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.5 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(
			Transform3D(
				Basis.IDENTITY,
				_frame_at(-back) * Vector3(
					x, _section_point(x / _half_width_at(-back), -back).y + 0.9, 0.0
				)
			)
		)

	return spawns
