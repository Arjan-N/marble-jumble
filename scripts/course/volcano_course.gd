class_name VolcanoCourse
extends Course

## Volcano Run — Heart of the Mountain. github.com/Arjan-N/marble-jumble#2
##
## Core fantasy: get out before the volcano erupts. The channel-mesh approach
## is `JungleCourse`'s (open dish, no seams on a turning/banked course) rather
## than `OrbitalCourse`'s walled duct — the issue asks to reuse the existing
## modular course architecture rather than invent a new one, and the dish is
## the one of the two that already reads as "open ground with a drop at the
## edges", which is what a mountain flank needs to feel like. The one span
## that wants to feel enclosed (Lava Tube) gets a deeper dish, darker surface
## and a purely decorative non-colliding rock ceiling rather than a second
## geometry system — see `_build_tube_ceiling`.
##
## Seven beats, mapped onto fractions of `LENGTH`:
##
##   Ash Slope | Cracking Ridge | Lava Crossing | The Eruption | Lava Tube |
##   Obsidian Drop | Final Escape
##
## Physical ideas per the issue: heat (lava glow along the open edges and
## below every gap), impact (rockfall through the ridge and eruption — see
## `FallingRock`), escape (pitch climbs from a calm ~7° opening to a ~15°
## plunge into the tube and a fast ~12° sprint to the line).
##
## Non-goals kept: no AI, no player route choice, no scripted outcome, no
## destruction system, no camera system of its own — the "screen shake" the
## issue describes is left to the rockfall actually landing near marbles
## rather than a scripted camera effect, which would be exactly the kind of
## Volcano-Run-specific camera work the issue rules out.

# --- Shape --------------------------------------------------------------------

const LENGTH := 205.0
const RAMP_LENGTH := 14.0
const RUNOFF_LENGTH := 8.0

## Section boundaries, as fractions of `LENGTH`. Named so every other table in
## this file can be read against the same seven beats the issue describes.
const ASH_SLOPE_END := 0.14
const CRACKING_RIDGE_END := 0.28
const LAVA_CROSSING_END := 0.45
const ERUPTION_END := 0.60
const LAVA_TUBE_END := 0.76
const OBSIDIAN_DROP_END := 0.86
## Final Escape runs from OBSIDIAN_DROP_END to 1.00.

## Calm, then rumbling, then held back for the crossing, then escalating
## through the eruption into the tube's plunge, then the drop, then the
## sprint out. Floor of 5.5° throughout, the same minimum every course here
## holds to — nothing may be shallow enough to strand a marble that arrives
## slowly.
const PITCH := [
	[0.10, 7.0],   ## Ash Slope: calm opening, clearly dangerous underneath.
	[0.24, 10.5],  ## Cracking Ridge: the ground starts giving way underfoot.
	[0.40, 6.0],   ## Lava Crossing: held back so the split reads clearly.
	[0.55, 9.5],   ## The Eruption: urgency building.
	[0.68, 15.0],  ## Lava Tube: the steepest, darkest stretch on the course.
	[0.80, 8.0],   ## Obsidian Drop approach.
	[1.00, 12.0],  ## Final Escape: a fast sprint into the open.
]

## Two bends either side of the lava crossing's corner (kept, like every other
## course here, under the ~30° the chase camera's look-ahead can hold), then a
## drift through the tube and a last bend to the line.
const HEADING := [
	[0.10, 0.0],
	[0.26, -16.0],  ## Into Cracking Ridge / Lava Crossing.
	[0.42, -20.0],  ## The corner the split sits inside — see `_build_split`.
	[0.58, 0.0],    ## Straightened for the eruption's open ground.
	[0.72, 12.0],   ## Drifting into the tube.
	[0.86, 0.0],
	[1.00, -8.0],   ## Final bend before the line.
]

## Half-width along the course. Wide at the calm opening, squeezed hard at the
## ridge (the issue's "narrowing creates collisions"), opened out again for
## the crossing's split, and tight through the tube. Never below 3.4 — two
## marbles abreast is 1.8m, and every course here that tried tighter than
## about 2.7-3.0m recorded a jam, not a funnel.
const HALF_WIDTH := 6.5
const WIDTH := [
	[0.05, 6.5],
	[0.14, 6.5],
	[0.26, 3.4],  ## Cracking Ridge: the first squeeze.
	[0.38, 6.2],  ## Lava Crossing: wide enough for a real split.
	[0.50, 5.4],  ## The Eruption: open, not the widest.
	[0.62, 4.0],  ## Narrowing into the tube.
	[0.74, 3.6],  ## Lava Tube.
	[0.80, 5.0],  ## Obsidian Drop approach opens back up for the jump.
	[0.92, 3.4],  ## Final Escape narrows for a scramble finish.
	[1.00, 4.4],
]

## Dish depth and shoulder, inherited unchanged from `JungleCourse`: the same
## proven shape (no crease anywhere, monotonic outward, so nothing traps a
## marble), just re-themed. `TUBE_RISE` adds extra depth through the Lava Tube
## span only, eased in and out the same way `JungleCourse.LOG_RISE` deepens
## the hollow log — the geometry that makes an open dish read as enclosed
## without a second, walled/roofed mesh system.
const CHANNEL_RISE := 1.05
const SHOULDER := 2.2
const SHOULDER_CURVE := 0.23
const TUBE_RISE := 0.55
## Half-width of the open slot left down the middle of the tube's decorative
## roof. Wider than the tube's own 3.6m half-width would need for clearance —
## it is sized for the overhead camera's sightline onto the racing line, not for
## the marbles. See `_build_tube_ceiling`.
const TUBE_SLOT_HALF := 2.4

## Resolution of the generated channel, along and across. Same values every
## banked/turning course here uses — see `JungleCourse.MESH_STEP` for why a
## banked corner needs a vertex row at every station rather than boxes.
const MESH_STEP := 1.0
const SECTION_STEP := 0.4
const RUN_OVERLAP := 0.35

# --- Surfaces -----------------------------------------------------------------

const SURFACE_ASH := {"friction": 0.42, "colour": Color(0.16, 0.14, 0.13)}
const SURFACE_CRACKED := {"friction": 0.50, "colour": Color(0.24, 0.15, 0.12)}
const SURFACE_CROSSING := {"friction": 0.30, "colour": Color(0.32, 0.21, 0.15)}
const SURFACE_ERUPTION := {"friction": 0.38, "colour": Color(0.20, 0.16, 0.15)}
const SURFACE_TUBE := {"friction": 0.22, "colour": Color(0.09, 0.07, 0.08)}
const SURFACE_OBSIDIAN := {"friction": 0.16, "colour": Color(0.06, 0.05, 0.08)}
const SURFACE_ESCAPE := {"friction": 0.30, "colour": Color(0.42, 0.34, 0.26)}

const SURFACES := [
	[ASH_SLOPE_END, SURFACE_ASH],
	[CRACKING_RIDGE_END, SURFACE_CRACKED],
	[LAVA_CROSSING_END, SURFACE_CROSSING],
	[ERUPTION_END, SURFACE_ERUPTION],
	[LAVA_TUBE_END, SURFACE_TUBE],
	[OBSIDIAN_DROP_END, SURFACE_OBSIDIAN],
	[1.00, SURFACE_ESCAPE],
]
const BOUNCE := 0.12

# --- Lava Crossing split -------------------------------------------------------

## A single ridge down the middle, exactly `JungleCourse`'s buttress root: full
## height near the centreline, tapering to nothing well short of the edges, so
## which side a marble ends up on is decided by physics and where it already
## was — never a player or AI choice (PROJECT.md section 6).
const SPLIT_AT := 0.32
const SPLIT_LENGTH := 15.0
const SPLIT_HEIGHT := 0.9
const SPLIT_COLOUR := Color(0.30, 0.13, 0.08)

# --- Cracking Ridge boulders ----------------------------------------------------

## Squat half-buried boulders rather than upright trunks: a sphere has no
## vertical face to trap a slow marble against, so this needed none of
## `JungleCourse`'s separate flared-base collider for its trunks.
const BOULDER_AT := 0.24
const BOULDER_RADIUS := 0.85
const BOULDER_COLOUR := Color(0.14, 0.10, 0.09)
const MIN_GAP := 1.5

# --- Rockfall (Cracking Ridge tail through The Eruption) -----------------------

## "Occasional small falling rocks" through the ridge, escalating into real
## debris through the eruption — one spawner, one zone, tuned sparse enough
## that falls stay a consequence of bad luck near a landing rock rather than
## the run's outcome (issue: "avoid making random projectiles the dominant
## determinant of winning").
const ROCKFALL_FROM := 0.20
const ROCKFALL_TO := 0.58
const ROCKFALL_INTERVAL_MIN := 1.6
const ROCKFALL_INTERVAL_MAX := 2.6
const ROCKFALL_DROP_HEIGHT := 9.0

# --- Lava Tube obstacle ---------------------------------------------------------

const BUMPER_AT := 0.70

# --- Obsidian Drop --------------------------------------------------------------

## The biggest jump on the course, by design (issue: "the biggest jump of the
## course"). Shape and reasoning are `JungleCourse._kicker_lift`'s, scaled up:
## a parabolic ramp (flat at the floor, steepest at the lip) into a hole cut
## from the channel, with a boost pad on the approach guaranteeing everyone
## arrives fast enough to clear it.
const KICKER_AT := 0.78
const KICKER_LENGTH := 6.5
const KICKER_RISE := 1.4
const JUMP_GAP := 3.6
const BOOST_SPEED := 14.5

# --- Decoration -----------------------------------------------------------------

const LAVA_GLOW_COLOUR := Color(0.95, 0.35, 0.05)
const ROCK_COLOUR := Color(0.13, 0.10, 0.10)
const FINISH_COLOUR := Color(0.92, 0.91, 0.86)
## How far below the open edges the glowing lava floor sits. Deep enough that
## a fall reads as a drop into it rather than as missing level.
const LAVA_BELOW := 16.0

## The eruption plume: how far off to the side it stands, clear of the track
## and the camera's own framing, and how it breathes.
const PLUME_AT := 0.52
const PLUME_OFFSET := 20.0
const PLUME_PULSE_SPEED := 0.7
const PLUME_PULSE_MIN := 1.6
const PLUME_PULSE_MAX := 3.0

var _path: CoursePath
var _plume_light: OmniLight3D
var _plume_time := 0.0


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_channel()
	_build_lava_edges()
	_build_back_wall()
	_build_boulders()
	_build_split_caps()
	_build_tube_ceiling()
	_build_bumper()
	_build_boost()
	_build_eruption_plume()
	_build_finish_line()

	_start_rockfall()


func _process(delta: float) -> void:
	if _plume_light == null or not is_instance_valid(_plume_light):
		return
	# A slow breathing glow, the same idea `marble.gd`'s player highlight uses
	# for the same reason: motion reads as "alive" where a fixed light reads
	# as a fixture.
	_plume_time += delta
	var pulse := (sin(_plume_time * PLUME_PULSE_SPEED) * 0.5) + 0.5
	_plume_light.omni_range = lerpf(PLUME_PULSE_MIN, PLUME_PULSE_MAX, pulse) + 4.0
	_plume_light.light_energy = lerpf(1.6, 2.6, pulse)


# --- Path -----------------------------------------------------------------------


func _point(s: float) -> Vector3:
	return _path.point_at(s)


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


## The course split into stretches of constant surface with the jump's gap cut
## out — the same construction `JungleCourse._runs` uses for its stepping
## stone, generalised to nothing else here needing a second hole.
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


## Height added by the Obsidian Drop's kicker at `s`. Identical shape to
## `JungleCourse._kicker_lift` — squared on the way up so the lip is where the
## ramp is steepest rather than where it is flattest, held at full rise across
## the (unbuilt) gap, then eased back down into the landing so the rest of the
## course is not left sitting a metre and a half above itself.
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


## Extra dish depth through the Lava Tube, eased in and out like
## `JungleCourse.LOG_RISE` deepens the hollow log — the one piece of geometry
## doing the "enclosed" work, alongside the decorative ceiling in
## `_build_tube_ceiling`.
func _tube_lift(s: float) -> float:
	var from_s := LAVA_CROSSING_END * LENGTH
	var to_s := LAVA_TUBE_END * LENGTH
	if s <= from_s or s >= to_s:
		return 0.0
	var ease_length := 5.0
	var inside := minf(
		smoothstep(0.0, ease_length, s - from_s), smoothstep(0.0, ease_length, to_s - s)
	)
	return TUBE_RISE * inside


## The Lava Crossing's split ridge: full height within half a metre of the
## centreline, tapering to nothing by 0.95m, eased in and out along its
## length — `JungleCourse._root_lift` unchanged bar the numbers.
func _split_lift(absolute_lateral: float, s: float) -> float:
	var from_s := SPLIT_AT * LENGTH
	var to_s := from_s + SPLIT_LENGTH
	if s <= from_s or s >= to_s or absolute_lateral >= 0.95:
		return 0.0
	var ease_length := 4.0
	var along := minf(
		smoothstep(0.0, ease_length, s - from_s), smoothstep(0.0, ease_length, to_s - s)
	)
	var across := 1.0 - smoothstep(0.5, 0.95, absolute_lateral)
	return SPLIT_HEIGHT * along * across


func _rise_at(s: float) -> float:
	return CHANNEL_RISE + _tube_lift(s)


## One section vertex, `(lateral, lift)` in the local frame, for normalised
## across-position `t` at distance `s`. Unchanged from `JungleCourse`: the
## dish inside the racing width, the same curve continuing (and steepening)
## past it so the shoulder has no crease anywhere to trap a marble.
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
	return Vector2(
		lateral, lift + _split_lift(absf(lateral), s) + _kicker_lift(s)
	)


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


## Glowing lava, visible below and beside the open sections. Visual only —
## anything that gets this far is already eliminated by `fall_threshold_y`,
## the same relationship `OrbitalCourse._build_void` has to its own gaps.
## Emission is left on: under the Compatibility renderer it reads as plain
## brightness rather than bloom, which is exactly what a lit lava floor
## should look like against the dark rock around it.
func _build_lava_edges() -> void:
	var s := -RAMP_LENGTH
	var index := 0

	while s < LENGTH + RUNOFF_LENGTH:
		var frame := _frame_at(s)

		var floor_mesh := BoxMesh.new()
		floor_mesh.size = Vector3(50.0, 1.0, 12.0)
		var floor_visual := MeshInstance3D.new()
		floor_visual.mesh = floor_mesh
		floor_visual.material_override = _lava_material()
		floor_visual.transform = frame.translated_local(Vector3(0.0, -LAVA_BELOW, 0.0))
		add_child(floor_visual)

		# A thin glowing seam right at the open edges, closer than the lava
		# floor far below — what actually sells "you can see it from here"
		# without lighting the whole scene.
		for side: float in [-1.0, 1.0]:
			var seam := MeshInstance3D.new()
			var seam_mesh := BoxMesh.new()
			seam_mesh.size = Vector3(0.6, 0.3, 11.0)
			seam.mesh = seam_mesh
			seam.material_override = _lava_material()
			seam.transform = frame.translated_local(
				Vector3(side * (HALF_WIDTH + SHOULDER + 1.2), -2.0, 0.0)
			)
			add_child(seam)

		s += 12.0
		index += 1


func _lava_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = LAVA_GLOW_COLOUR
	material.emission_enabled = true
	material.emission = LAVA_GLOW_COLOUR
	material.emission_energy_multiplier = 1.4
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(Vector3(0.0, 1.2, 0.4)),
		Vector3(_half_width_at(-RAMP_LENGTH) * 2.0, 2.4, 0.8),
		ROCK_COLOUR.darkened(0.3),
	)


## Squat boulders across Cracking Ridge — round, so unlike an upright trunk
## there is no vertical face for a slow marble to be pushed into and stop
## dead against.
func _build_boulders() -> void:
	var s := BOULDER_AT * LENGTH
	var half_width := _half_width_at(s)
	var count := 2
	var gap := (half_width * 2.0 - count * BOULDER_RADIUS * 2.0) / float(count + 1)
	_assert_gap(gap, "boulder row at %.2f" % BOULDER_AT)

	for i in count:
		var offset := -half_width + gap * float(i + 1) + BOULDER_RADIUS * float(i * 2 + 1)
		_add_boulder(s, offset)


func _add_boulder(s: float, offset: float) -> void:
	var lift := _section_point(offset / _half_width_at(s), s).y
	var body := StaticBody3D.new()
	body.transform = _frame_at(s).translated_local(
		Vector3(offset, lift + BOULDER_RADIUS * 0.6, 0.0)
	)
	body.physics_material_override = _surface_material(SURFACE_CRACKED["friction"])

	var shape := SphereShape3D.new()
	shape.radius = BOULDER_RADIUS
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := SphereMesh.new()
	mesh.radius = BOULDER_RADIUS
	mesh.height = BOULDER_RADIUS * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(BOULDER_COLOUR)
	body.add_child(visual)

	add_child(body)


## End caps for the split ridge, the same reasoning `OrbitalCourse` gives its
## divider caps: a flat face square to an oncoming field stops whatever meets
## it dead and blocks the lane behind it, so both ends get a rounded cap
## instead. The ridge itself needs no separate geometry — it lives entirely in
## `_split_lift`, baked into the channel mesh.
func _build_split_caps() -> void:
	for end_s: float in [SPLIT_AT * LENGTH, SPLIT_AT * LENGTH + SPLIT_LENGTH]:
		var lift := _section_point(0.0, end_s).y
		var body := StaticBody3D.new()
		body.transform = _frame_at(end_s).translated_local(
			Vector3(0.0, lift + SPLIT_HEIGHT * 0.5, 0.0)
		)
		body.physics_material_override = _surface_material(SURFACE_CROSSING["friction"])

		var shape := CylinderShape3D.new()
		shape.radius = 0.5
		shape.height = SPLIT_HEIGHT
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.5
		mesh.bottom_radius = 0.5
		mesh.height = SPLIT_HEIGHT
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(SPLIT_COLOUR.lightened(0.1))
		body.add_child(visual)

		add_child(body)


## Purely decorative rock over the Lava Tube — no collider. The tunnel feel
## comes from the deepened dish (`_tube_lift`), the dark surface and narrowed
## width already in the channel; this is what keeps it from reading as an open
## dish with a dim floor. A couple of small glowing seams stand in for "lava
## visible through cracks" without a lighting system of its own.
##
## Two overhanging shelves rather than one slab across. The camera runs in
## `Mode.OVERHEAD` — a steep, near-top-down pitch — and a full-width lid at
## marble height is simply the only thing on screen through this whole section.
## The shelves keep the enclosed silhouette at the frame edges while `SLOT_HALF`
## leaves the racing line permanently in view, which is also what the issue's
## readability requirement asks for.
func _build_tube_ceiling() -> void:
	var from_s := LAVA_CROSSING_END * LENGTH
	var to_s := LAVA_TUBE_END * LENGTH
	var s := from_s
	var index := 0

	while s < to_s:
		var half_width := _half_width_at(s)
		var outer := half_width + 1.5
		var shelf := maxf(outer - TUBE_SLOT_HALF, 1.0)

		for side in [-1.0, 1.0]:
			var visual := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(shelf, 0.8, 6.5)
			visual.mesh = mesh
			visual.material_override = _material(ROCK_COLOUR)
			visual.transform = _frame_at(s).translated_local(
				Vector3(side * (TUBE_SLOT_HALF + shelf * 0.5), 3.4, 0.0)
			)
			add_child(visual)

		if index % 2 == 0:
			var crack := MeshInstance3D.new()
			var crack_mesh := BoxMesh.new()
			crack_mesh.size = Vector3(0.25, 0.85, 3.0)
			crack.mesh = crack_mesh
			crack.material_override = _lava_material()
			crack.transform = _frame_at(s).translated_local(
				Vector3(outer - 0.6, 3.0, 0.0)
			)
			add_child(crack)

		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.55, 0.25)
		light.light_energy = 0.9
		light.omni_range = 6.0
		light.transform = _frame_at(s).translated_local(Vector3(0.0, 1.4, 0.0))
		add_child(light)

		s += 6.0
		index += 1


func _build_bumper() -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _frame_at(BUMPER_AT * LENGTH)
	add_child(bumper)


func _build_boost() -> void:
	var at := KICKER_AT * LENGTH - 3.5
	var frame := _frame_at(at)
	var pad := BoostPad.create(_half_width_at(at) * 2.0, -frame.basis.z, BOOST_SPEED)
	pad.transform = frame.translated_local(Vector3(0.0, 1.2, 0.0))
	add_child(pad)


## The signature spectacle: a volcano cone and a bright crater glow, well off
## to the side (`PLUME_OFFSET`) so it never occupies the racing line or blocks
## the chase camera's own framing, with a breathing light for drama —
## `_process` does the pulsing.
func _build_eruption_plume() -> void:
	var s := PLUME_AT * LENGTH
	var base := _frame_at(s) * Vector3(PLUME_OFFSET, -6.0, 0.0)

	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 1.5
	cone_mesh.bottom_radius = 11.0
	cone_mesh.height = 20.0
	cone_mesh.radial_segments = 12
	var cone := MeshInstance3D.new()
	cone.mesh = cone_mesh
	cone.material_override = _material(ROCK_COLOUR)
	cone.position = base + Vector3(0.0, 10.0, 0.0)
	add_child(cone)

	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 2.4
	glow_mesh.height = 2.4
	var glow := MeshInstance3D.new()
	glow.mesh = glow_mesh
	glow.material_override = _lava_material()
	glow.position = base + Vector3(0.0, 19.5, 0.0)
	add_child(glow)

	# Ash/smoke, stood in for by a handful of soft, overlapping, semi-
	# transparent spheres rather than a particle system — nothing in this
	# project uses one (see `marble_trail.gd`), and a plume this far off to
	# the side does not need one either.
	for i in 4:
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 2.2 + float(i) * 0.9
		puff_mesh.height = puff_mesh.radius * 2.0
		var puff := MeshInstance3D.new()
		puff.mesh = puff_mesh
		var puff_material := StandardMaterial3D.new()
		puff_material.albedo_color = Color(0.35, 0.32, 0.30, 0.35 - float(i) * 0.05)
		puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		puff.material_override = puff_material
		puff.position = base + Vector3(float(i) * 0.6, 22.0 + float(i) * 2.6, 0.0)
		add_child(puff)

	_plume_light = OmniLight3D.new()
	_plume_light.light_color = Color(1.0, 0.5, 0.2)
	_plume_light.position = base + Vector3(0.0, 19.5, 0.0)
	add_child(_plume_light)


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
		ROCK_COLOUR.darkened(0.3),
	)


# --- Rockfall ---------------------------------------------------------------


## One free-running timer for the whole zone rather than one per rock: a rock
## is a RigidBody3D that lives until `FallingRock.LIFETIME` or a fall past the
## threshold, and the spawner's only job is to place a new one every so often
## while the race is on.
func _start_rockfall() -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_rockfall_timeout.bind(timer))
	add_child(timer)
	timer.start(randf_range(ROCKFALL_INTERVAL_MIN, ROCKFALL_INTERVAL_MAX))


func _on_rockfall_timeout(timer: Timer) -> void:
	_spawn_rock()
	if is_instance_valid(timer):
		timer.start(randf_range(ROCKFALL_INTERVAL_MIN, ROCKFALL_INTERVAL_MAX))


func _spawn_rock() -> void:
	var s := randf_range(ROCKFALL_FROM * LENGTH, ROCKFALL_TO * LENGTH)
	var half_width := _half_width_at(s)
	# Kept inside the racing width, not the full shoulder — a rock landing
	# out on the shoulder is one nobody racing down the middle ever meets.
	var lateral := randf_range(-half_width * 0.8, half_width * 0.8)
	var lift := _section_point(lateral / half_width, s).y

	var rock := FallingRock.create()
	rock.transform = _frame_at(s).translated_local(
		Vector3(lateral, lift + ROCKFALL_DROP_HEIGHT, 0.0)
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
	material.friction = SURFACE_ASH["friction"] if friction < 0.0 else friction
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
	return _point(LENGTH).y - 24.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


## Five across, the same grid `JungleCourse` uses: the channel is narrower
## than the flat-floored courses and its edges are curved, so a marble spawned
## hard against the side starts partway up the camber rather than flat.
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
