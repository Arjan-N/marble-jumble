class_name TempleRunCourse
extends Course

## Temple Run — a Mayan stone causeway threading a ruined jungle.
##
## The reference art is a raised stone flume with a mossy centre, low kerbed
## ridges either side, running past overgrown step-pyramids and vine-hung
## walls. The important word is *causeway*: this is not a trough and not a
## canyon. The racing surface is flat, the sides are low ridges rather than
## walls, and the jungle is scenery — geometry the marbles never touch, placed
## past the ridge purely so the frame is bounded by something.
##
## Geometry follows `GlacierFaultCourse` rather than the swept
## quadratic-shoulder shape `course_builder.gd` uses: flat planes at fixed,
## stated sizes, because that formula has no natural sense of
## scale and produced a thirty-metre wall the last time a new course reached
## for it (see `[[marble-jumble-course-geometry-use-planes]]`). Every height
## here is a number a marble diameter can be held against.
##
## Three beats: Plaza | Serpent Bends | Temple Approach. One obstacle, no jump,
## no spawner — a first pass that races cleanly is worth more than a first pass
## with six features, which is the lesson a six-feature course that never got
## past its own spiral stall (and was cut) taught the hard way.

# --- Shape --------------------------------------------------------------------

const LENGTH := 130.0
const RAMP_LENGTH := 12.0
const RUNOFF_LENGTH := 8.0

## Section boundaries, as fractions of `LENGTH`.
const PLAZA_END := 0.22
const BEND_ONE_END := 0.48
const BEND_TWO_START := 0.62
const BEND_TWO_END := 0.88

## Gentle throughout, easing further through both bends for the reason every
## turning course here has had to learn: speed into a corner is what throws a
## marble at the outside, not what carries it round. Floor of 6°, opening up
## only once the course is straight again for the run to the line.
const PITCH := [
	[0.12, 7.0],   ## Plaza: barely descending, the field spreads out.
	[PLAZA_END, 8.0],
	[BEND_ONE_END, 6.5],   ## First bend, held back.
	[BEND_TWO_START, 9.0], ## Short straight between the bends.
	[BEND_TWO_END, 6.5],   ## Second bend, held back the same amount.
	[1.00, 12.0],  ## Temple Approach: sprint to the line.
]

## An S: right, then left back onto the original bearing. Both turns are spread
## across many small steps rather than one jump, because `CoursePath`'s
## smoothing window is a fixed width — a single large step still turns sharply
## inside it. 18° over 32m is 0.56°/m, under the ~0.6°/m every course here that
## races cleanly stays below, and this one has only a 0.9m ridge to catch a
## marble thrown wide rather than a real wall.
const HEADING := [
	[PLAZA_END, 0.0],
	[0.28, 4.0],
	[0.34, 9.0],
	[0.41, 14.0],
	[BEND_ONE_END, 18.0],
	[BEND_TWO_START, 18.0],
	[0.68, 14.0],
	[0.75, 9.0],
	[0.82, 4.0],
	[BEND_TWO_END, 0.0],
	[1.00, 0.0],
]

## Half-width of the racing surface, ridge excluded. Wide in the Plaza so the
## field can spread and overtake, tighter through the bends so the ridge sits
## close enough to catch a wide marble before it has crossed open floor to get
## there, wide again for the finish. Never below 3.6 — two marbles abreast is
## 1.8m, and the bumper needs room to be passed either side.
const WIDTH := [
	[0.08, 5.4],
	[PLAZA_END, 5.2],
	[0.34, 4.0],
	[BEND_ONE_END, 4.0],
	[BEND_TWO_START, 4.6],
	[0.75, 4.0],
	[BEND_TWO_END, 4.2],
	[1.00, 5.2],
]

## Ridge height along the course. A kerb everywhere so the causeway always
## reads as having sides — that is what the reference art has, and an unkerbed
## flat plane reads as a road rather than a flume — raised through both bends
## where containment actually matters.
##
## Fixed numbers, not derived from any curve: 0.5 is just over half a marble
## (0.9m across), enough to be seen and to deflect a glancing marble without
## stopping one; 1.6 is nearly two marble diameters, comfortably taller than
## `CoursePath.BANK_LIMIT_DEGREES`' bank would ever throw one.
const KERB_HEIGHT := 0.5
const BEND_RIDGE_HEIGHT := 1.6
const RIDGE_HEIGHT_PROFILE := [
	[0.28, KERB_HEIGHT],
	[0.32, BEND_RIDGE_HEIGHT],
	[BEND_ONE_END, BEND_RIDGE_HEIGHT],
	[BEND_TWO_START, KERB_HEIGHT],
	[0.66, KERB_HEIGHT],
	[0.70, BEND_RIDGE_HEIGHT],
	[0.84, BEND_RIDGE_HEIGHT],
	[BEND_TWO_END, KERB_HEIGHT],
	[1.00, KERB_HEIGHT],
]

## Width of the ridge's flat top, and how far the causeway's outer face drops
## below the deck. Both purely visual: they give the structure mass from the
## side, which is most of what makes it read as built stone rather than a
## painted strip.
const RIDGE_WIDTH := 0.7
const SKIRT_DROP := 1.6

## Fraction of the full width taken by the mossy centre strip. Visual only —
## friction is per-run, so the moss does not actually slow a marble down. It is
## the single strongest cue in the reference art and costs two extra columns.
const MOSS_FRACTION := 0.44

const MESH_STEP := 1.0
const RUN_OVERLAP := 0.35

# --- Surfaces -----------------------------------------------------------------

## Weathered stone, gritty in the plaza where the field is still bunched,
## slicker through the bends and the sprint. All well inside the range the
## other stone courses race at.
##
## Values are lower than they look on a swatch on purpose. The ambient here is
## green and the sky is bright, and a first pass painted at "stone grey"
## rendered as pale lime — the causeway has to be dark enough that the light
## tints it rather than replaces it.
const SURFACE_PLAZA := {"friction": 0.36, "colour": Color(0.50, 0.50, 0.47)}
const SURFACE_BENDS := {"friction": 0.30, "colour": Color(0.47, 0.47, 0.44)}
const SURFACE_APPROACH := {"friction": 0.26, "colour": Color(0.53, 0.53, 0.49)}

const SURFACES := [
	[PLAZA_END, SURFACE_PLAZA],
	[BEND_TWO_END, SURFACE_BENDS],
	[1.00, SURFACE_APPROACH],
]
const BOUNCE := 0.12

# --- Palette ------------------------------------------------------------------

## The moss is the strongest cue in the reference art and the easiest thing to
## overdo: at full saturation it reads as painted line marking rather than as
## something growing on stone. Dark and desaturated, so the green arrives from
## the light as much as from the albedo.
const MOSS_COLOUR := Color(0.16, 0.24, 0.13)
const RIDGE_TOP_COLOUR := Color(0.50, 0.49, 0.44)
const RIDGE_FACE_COLOUR := Color(0.34, 0.33, 0.30)
const SKIRT_COLOUR := Color(0.26, 0.27, 0.24)

const STONE_COLOUR := Color(0.48, 0.48, 0.41)
const STONE_DARK := Color(0.28, 0.29, 0.26)
const RUIN_COLOUR := Color(0.44, 0.44, 0.38)
const RUIN_MOSS_COLOUR := Color(0.27, 0.36, 0.22)
const FINISH_COLOUR := Color(0.82, 0.79, 0.64)

const CANOPY_COLOUR := Color(0.09, 0.17, 0.10)
const FOLIAGE_COLOUR := Color(0.14, 0.26, 0.13)
const UNDERGROWTH_COLOUR := Color(0.11, 0.21, 0.11)
const JUNGLE_FLOOR_COLOUR := Color(0.07, 0.14, 0.08)

# --- Obstacle -----------------------------------------------------------------

## One rotating bumper, dressed as a stone roller, on the short straight
## between the bends — the only stretch on the course with neither a corner nor
## the finish to compound with.
const BUMPER_AT := 0.55

# --- Scenery ------------------------------------------------------------------

## Metres between scenery stations. Everything past the ridge is placed on this
## grid, jittered deterministically so a restart rebuilds the same jungle.
const SCENERY_STEP := 9.0
## How far below the deck the jungle floor sits. Well above `fall_threshold_y`,
## so nothing a marble can reach is ever resting on it.
const JUNGLE_BELOW := 20.0
## Every Nth station gets a step-pyramid, sides alternating.
const RUIN_EVERY := 2

# --- Environment --------------------------------------------------------------

const SKY_TOP := Color(0.24, 0.46, 0.60)
const SKY_HORIZON := Color(0.60, 0.71, 0.62)
## Barely tinted, and at half the energy the first pass used. A saturated green
## ambient at 0.68 turned every stone face lime and flattened the causeway into
## the jungle behind it; the tint has to be small enough that shadowed stone
## still reads as stone.
const AMBIENT_COLOUR := Color(0.80, 0.84, 0.78)
const AMBIENT_ENERGY := 0.42
const SUN_COLOUR := Color(1.0, 0.97, 0.84)
const FOG_COLOUR := Color(0.38, 0.48, 0.46)
## Light enough to push the far jungle back without dissolving the middle
## distance — at 0.0055 everything past twenty metres was one flat green wall.
const FOG_DENSITY := 0.0022

var _path: CoursePath


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_causeway()
	_build_slab_joints()
	_build_jungle()
	_build_back_wall()
	_build_roller()
	_build_finish_gate()


# --- Path ---------------------------------------------------------------------


func _point(s: float) -> Vector3:
	return _path.point_at(s)


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


func _ridge_height_at(s: float) -> float:
	return _path.sample(RIDGE_HEIGHT_PROFILE, s)


func _surface_at(s: float) -> Dictionary:
	var fraction := s / LENGTH
	for entry: Array in SURFACES:
		if fraction <= entry[0]:
			return entry[1]
	return SURFACES[SURFACES.size() - 1][1]


# --- Causeway -----------------------------------------------------------------


func _build_causeway() -> void:
	for run: Dictionary in _runs():
		var from_s: float = run["from"] - (RUN_OVERLAP if run["lead"] else 0.0)
		var to_s: float = run["to"] + (RUN_OVERLAP if run["trail"] else 0.0)
		_build_run(from_s, to_s, run["surface"])


## The course split into stretches of constant surface. The ridge rises and
## falls smoothly within a run via `_ridge_height_at`, so it needs no cut of its
## own — every run shares the same ten-vertex section.
func _runs() -> Array:
	var cuts := [-RAMP_LENGTH, LENGTH + RUNOFF_LENGTH]
	for entry: Array in SURFACES:
		cuts.append(entry[0] * LENGTH)
	cuts.sort()

	var runs := []
	for i in range(cuts.size() - 1):
		var from_s: float = cuts[i]
		var to_s: float = cuts[i + 1]
		if to_s - from_s < 0.2:
			continue
		var mid := (from_s + to_s) * 0.5
		runs.append({
			"from": from_s,
			"to": to_s,
			"surface": _surface_at(mid),
			"lead": absf(from_s - (-RAMP_LENGTH)) > 0.01,
			"trail": absf(to_s - (LENGTH + RUNOFF_LENGTH)) > 0.01,
		})
	return runs


## One cross-section, left to right, entirely from flat planes:
##
##     outer skirt | ridge top | ridge face | stone | moss | stone | ridge face
##                                                   | ridge top | outer skirt
##
## Nine columns, ten vertices, no curvature anywhere. The racing surface is the
## three flat columns in the middle and they are all at y = 0 — this is a
## causeway, not a dish, so there is nothing for a marble to settle into.
func _section_points(s: float) -> Array:
	var half_width := _half_width_at(s)
	var height := _ridge_height_at(s)
	var moss := half_width * MOSS_FRACTION
	var outer := half_width + RIDGE_WIDTH
	return [
		Vector2(-outer, -SKIRT_DROP),
		Vector2(-outer, height),
		Vector2(-half_width, height),
		Vector2(-half_width, 0.0),
		Vector2(-moss, 0.0),
		Vector2(moss, 0.0),
		Vector2(half_width, 0.0),
		Vector2(half_width, height),
		Vector2(outer, height),
		Vector2(outer, -SKIRT_DROP),
	]


## Which palette entry each column of `_section_points` is painted in.
const COLUMN_COLOURS := [
	SKIRT_COLOUR,       ## 0: left outer face
	RIDGE_TOP_COLOUR,   ## 1: left ridge top
	RIDGE_FACE_COLOUR,  ## 2: left ridge inner face
	null,               ## 3: left stone margin — the run's own surface colour
	MOSS_COLOUR,        ## 4: mossy centre
	null,               ## 5: right stone margin
	RIDGE_FACE_COLOUR,  ## 6: right ridge inner face
	RIDGE_TOP_COLOUR,   ## 7: right ridge top
	SKIRT_COLOUR,       ## 8: right outer face
]


func _build_run(from_s: float, to_s: float, surface: Dictionary) -> void:
	var rows := []
	var s := from_s
	while s < to_s - 0.01:
		rows.append(_section_row(s))
		s = minf(s + MESH_STEP, to_s)
	rows.append(_section_row(to_s))

	if rows.size() < 2:
		return

	# Collision is one shape across every column — physics does not care which
	# panel a marble is touching, only where the surface is. The visual is split
	# per column so the ridge, the moss and the stone read as three materials
	# rather than one flat ribbon, which is the whole look of the reference art.
	var all_faces := PackedVector3Array()
	var by_colour := {}
	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(near.size() - 1):
			var quad := PackedVector3Array([
				near[c], far[c], near[c + 1],
				near[c + 1], far[c], far[c + 1],
			])
			all_faces.append_array(quad)

			var colour: Color = COLUMN_COLOURS[c] if COLUMN_COLOURS[c] != null else surface["colour"]
			if not by_colour.has(colour):
				by_colour[colour] = PackedVector3Array()
			by_colour[colour].append_array(quad)

	var body := StaticBody3D.new()
	body.physics_material_override = _surface_material(surface["friction"])

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(all_faces)
	shape.backface_collision = false
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	for colour: Color in by_colour:
		body.add_child(_visual_from_faces(by_colour[colour], colour))

	add_child(body)


func _visual_from_faces(faces: PackedVector3Array, colour: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.generate_normals()

	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _material(colour)
	return visual


func _section_row(s: float) -> Array:
	var frame := _frame_at(s)
	var row := []
	for node: Vector2 in _section_points(s):
		row.append(frame * Vector3(node.x, node.y, 0.0))
	return row


## Dark seams across the deck, one every `SLAB_SPACING`. Purely visual and
## deliberately not geometry: `CourseBuilder` draws its slab joints in a shader
## off the along-course UV, but this course has no shader, and a real recessed
## joint would be a crease across the racing surface — the one thing every
## course here is careful never to build.
##
## They earn their place: without them the causeway is a hundred and thirty
## metres of unbroken flat colour, and nothing on it tells the eye how fast a
## marble is actually moving.
const SLAB_SPACING := 4.5
const SLAB_WIDTH := 0.18


func _build_slab_joints() -> void:
	var s := -RAMP_LENGTH
	while s < LENGTH + RUNOFF_LENGTH:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(_half_width_at(s) * 2.0, 0.02, SLAB_WIDTH)

		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(STONE_DARK)
		# Sat a couple of centimetres proud rather than sunk, so it never shows
		# through the deck from underneath on a banked stretch.
		visual.transform = _frame_at(s).translated_local(Vector3(0.0, 0.02, 0.0))
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(visual)

		s += SLAB_SPACING


# --- Jungle -------------------------------------------------------------------


## How far past each end of the course the jungle keeps going. The chase camera
## sits `ChaseCamera`'s distance behind the field, so at the start line it is
## already well up-course of the ramp and looking at whatever is there — which,
## before this existed, was empty sky either side of the back wall.
const SCENERY_OVERRUN := 30.0


## Station frame for the scenery grid, valid past both ends of the path.
##
## `CoursePath.point_at` clamps outside its baked range, so asking it for a
## station beyond the run-out returns the run-out's own point and every extra
## station piles up in one place. Past either end this carries the end frame
## straight on instead, which is what a jungle either side of a causeway looks
## like anyway.
func _scenery_frame(s: float) -> Transform3D:
	var last := LENGTH + RUNOFF_LENGTH
	if s < -RAMP_LENGTH:
		# Local +Z is up-course, so a positive offset walks back past the ramp.
		return _frame_at(-RAMP_LENGTH).translated_local(
			Vector3(0.0, 0.0, -RAMP_LENGTH - s)
		)
	if s > last:
		return _frame_at(last).translated_local(Vector3(0.0, 0.0, last - s))
	return _frame_at(s)


## Everything past the ridge. None of it collides and none of it casts shadow:
## it is a backdrop, not a light-blocker, and a marble that could reach it has
## already left the course.
##
## Placed on the path's own frames rather than in world space, so the jungle
## follows the causeway round both bends instead of drifting off it.
func _build_jungle() -> void:
	var s := -RAMP_LENGTH - SCENERY_OVERRUN
	var index := 0

	while s < LENGTH + RUNOFF_LENGTH + SCENERY_OVERRUN:
		var frame := _scenery_frame(s)
		var half_width := _half_width_at(clampf(s, -RAMP_LENGTH, LENGTH + RUNOFF_LENGTH))

		_add_scenery(
			frame.translated_local(Vector3(0.0, -JUNGLE_BELOW, 0.0)),
			Vector3(70.0, 1.0, SCENERY_STEP * 1.3),
			JUNGLE_FLOOR_COLOUR.darkened(_jitter(index, 3) * 0.25),
		)

		for side: float in [-1.0, 1.0]:
			var seed := index * 2 + int(side > 0.0)

			# Three bands, each further out and taller than the last. Jittered in
			# all three axes and cut short of `SCENERY_STEP` so there are gaps
			# between stations — a first pass used full-length blocks at fixed
			# offsets and the jungle rendered as three flat slab walls running
			# beside the track.
			_add_scenery(
				frame.translated_local(Vector3(
					side * (half_width + 4.0 + _jitter(seed, 11) * 1.5),
					-2.6 - _jitter(seed, 13) * 1.4,
					0.0,
				)),
				Vector3(5.5, 5.0, SCENERY_STEP * (0.55 + _jitter(seed, 17) * 0.3)),
				UNDERGROWTH_COLOUR.lightened(_jitter(seed, 19) * 0.16),
				_jitter(seed, 59) * 70.0 - 35.0,
			)

			_add_scenery(
				frame.translated_local(Vector3(
					side * (half_width + 9.0 + _jitter(seed, 23) * 3.0),
					-1.0 + _jitter(seed, 29) * 3.5,
					0.0,
				)),
				Vector3(8.0, 11.0, SCENERY_STEP * (0.6 + _jitter(seed, 31) * 0.35)),
				FOLIAGE_COLOUR.lightened(_jitter(seed, 37) * 0.18),
				_jitter(seed, 61) * 70.0 - 35.0,
			)

			# Canopy: the dark band that closes the top of the frame. Far enough
			# out that it never crosses the racing line, tall enough that it does.
			_add_scenery(
				frame.translated_local(Vector3(
					side * (half_width + 17.0 + _jitter(seed, 41) * 4.0),
					6.0 + _jitter(seed, 43) * 5.0,
					0.0,
				)),
				Vector3(14.0, 16.0, SCENERY_STEP * (0.7 + _jitter(seed, 47) * 0.5)),
				CANOPY_COLOUR.lightened(_jitter(seed, 53) * 0.14),
				_jitter(seed, 67) * 70.0 - 35.0,
			)

		if index % RUIN_EVERY == 0:
			var side := 1.0 if (index / RUIN_EVERY) % 2 == 0 else -1.0
			_add_ruin(frame, half_width, side, index)

		s += SCENERY_STEP
		index += 1


## A step-pyramid: four tapering slabs, the top two mossed over. Sized against
## the causeway rather than against nothing — the base is roughly the width of
## the track, so it reads as a building beside a road instead of a monolith.
func _add_ruin(frame: Transform3D, half_width: float, side: float, index: int) -> void:
	var lateral := side * (half_width + 23.0 + _jitter(index, 61) * 5.0)
	var base := 15.0 + _jitter(index, 67) * 5.0
	var tiers := 5
	var tier_height := 3.4
	# Deliberately tall enough to break the canopy band. A pyramid that stops
	# below the trees is a shape nobody ever sees.
	var y := -4.0 + _jitter(index, 71) * 3.0

	for tier in tiers:
		var shrink := 1.0 - float(tier) * 0.16
		var colour := RUIN_MOSS_COLOUR if tier < 2 else RUIN_COLOUR
		_add_scenery(
			frame.translated_local(Vector3(
				lateral, y + tier_height * (float(tier) + 0.5), 0.0
			)),
			Vector3(base * shrink, tier_height, base * shrink),
			colour.darkened(_jitter(index * 7 + tier, 53) * 0.18),
		)

	# The doorway slot in the top tier, the one detail that makes the stack read
	# as a temple rather than a cake.
	_add_scenery(
		frame.translated_local(Vector3(
			lateral, y + tier_height * (float(tiers) - 0.5), -base * 0.16
		)),
		Vector3(base * 0.16, tier_height * 0.7, base * 0.5),
		STONE_DARK,
	)


## `yaw` is in degrees about the station's own up axis. Every foliage box gets
## some: boxes all square to the path read as three flat slab walls running
## alongside the track no matter how much their sizes are jittered, and turning
## them is what breaks that line up. Ruin tiers pass zero on purpose — a
## step-pyramid is built square, and a crooked one reads as a mistake.
func _add_scenery(transform: Transform3D, size: Vector3, colour: Color, yaw := 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(colour)
	visual.transform = transform.rotated_local(Vector3.UP, deg_to_rad(yaw))
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)


## Deterministic 0..1 noise. A restart has to rebuild the same jungle, so this
## is a hash of the station index rather than an RNG — the same trick
## `CourseBuilder._dressing_weathered` uses.
func _jitter(index: int, salt: int) -> float:
	return fmod(absf(sin(float(index * salt) * 12.9898) * 43758.5453), 1.0)


# --- Fixtures -----------------------------------------------------------------


## The head of the causeway, as the mouth of a temple the field is released
## from. The collider is the same full-width backstop every course here puts
## behind its start line — it exists so a marble knocked backwards off the ramp
## has something to hit — but the chase camera starts up-course of it and spends
## the countdown looking straight at it, so it gets a face rather than being one
## dark slab against empty sky.
func _build_back_wall() -> void:
	var half_width := _half_width_at(-RAMP_LENGTH)
	var frame := _frame_at(-RAMP_LENGTH)

	_add_box(
		frame.translated_local(Vector3(0.0, 1.2, 0.4)),
		Vector3(half_width * 2.0, 2.4, 0.8),
		STONE_DARK,
	)

	# Jambs and a header framing the opening, stepping back as they rise.
	for side: float in [-1.0, 1.0]:
		_add_scenery(
			frame.translated_local(Vector3(side * (half_width + 1.4), 2.2, 0.9)),
			Vector3(3.0, 7.0, 3.0),
			RUIN_COLOUR,
		)
	for tier in 3:
		var shrink := 1.0 - float(tier) * 0.16
		_add_scenery(
			frame.translated_local(Vector3(0.0, 4.4 + 2.2 * float(tier), 1.6)),
			Vector3((half_width * 2.0 + 7.0) * shrink, 2.2, 4.0 * shrink),
			RUIN_MOSS_COLOUR if tier == 0 else RUIN_COLOUR,
		)


## The single obstacle, dressed as a stone roller rather than rusted steel.
func _build_roller() -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _frame_at(BUMPER_AT * LENGTH)
	_tint(bumper, STONE_DARK)
	add_child(bumper)


## Two pillars flanking the line and a stepped temple front closing off the
## run-out, so the finish is a place rather than a stripe.
##
## Explicitly *not* a gate with a lintel, which is what this was first: the
## chase camera looks down the course from behind and above, and a beam
## anywhere between two and seven metres up crosses the frame exactly where the
## marbles are at the one moment of the race the player most needs to see. The
## pillars carry the same idea and leave the middle of the frame empty.
func _build_finish_gate() -> void:
	var width := _half_width_at(LENGTH) * 2.0
	var frame := _frame_at(LENGTH)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.06, 1.0)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(FINISH_COLOUR)
	visual.transform = frame.translated_local(Vector3(0.0, 0.04, 0.0))
	add_child(visual)

	# Outboard of the ridge, so nothing narrows the track at the one point the
	# field is most likely to arrive at it several abreast.
	var pillar_x := width * 0.5 + RIDGE_WIDTH + 0.9
	for side: float in [-1.0, 1.0]:
		_add_box(
			frame.translated_local(Vector3(side * pillar_x, 2.4, 0.0)),
			Vector3(1.5, 4.8, 1.5),
			RUIN_COLOUR,
		)
		_add_box(
			frame.translated_local(Vector3(side * pillar_x, 5.0, 0.0)),
			Vector3(1.9, 0.5, 1.9),
			RUIN_MOSS_COLOUR,
		)

	# The temple itself, well beyond the run-out and sunk below deck level, so
	# only its upper tiers clear the causeway. It is scenery the field crosses
	# the line against, not a wall in front of them: at 18m past the end it is
	# still the thing the last straight is aimed at, but the finish line and the
	# pillars stay in front of it rather than behind it. A first pass put it one
	# run-out back at full height and it hid both.
	#
	# Non-colliding for the same reason — nothing should ever reach it, and a
	# collider out here is only a thing for a stray marble to rest on.
	var back := _frame_at(LENGTH + RUNOFF_LENGTH).translated_local(
		Vector3(0.0, 0.0, -12.0)  ## Local -Z is down-course.
	)
	for tier in 4:
		var shrink := 1.0 - float(tier) * 0.17
		_add_scenery(
			back.translated_local(Vector3(0.0, -1.2 + 2.6 * float(tier), 0.0)),
			Vector3((width + 3.0) * shrink, 2.6, 7.0 * shrink),
			RUIN_MOSS_COLOUR if tier < 2 else RUIN_COLOUR,
		)


## `RotatingBumper` has no colour parameter, so its material override is
## replaced after `create()` rather than adding a constructor argument to a
## shared obstacle class for one course's palette.
func _tint(node: Node, colour: Color) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = _material(colour)


# --- Helpers ------------------------------------------------------------------


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
	material.friction = SURFACE_PLAZA["friction"] if friction < 0.0 else friction
	material.bounce = BOUNCE
	return material


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


# --- Course interface ---------------------------------------------------------


## Green light under a green sky. The jungle geometry is all albedo, and albedo
## alone cannot make a shadowed face look like it is under a canopy — the
## coloured ambient is what does that. Energy stays well above `CourseBuilder`'s
## 0.42 because this course's shadows are cast by scenery the player is not
## meant to be reading, and a marble in one still has to be findable.
func decorate_environment(environment: Environment, sun: DirectionalLight3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_bottom_color = JUNGLE_FLOOR_COLOUR
	sky_material.ground_horizon_color = SKY_HORIZON

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOUR
	environment.ambient_light_energy = AMBIENT_ENERGY

	environment.fog_enabled = true
	environment.fog_light_color = FOG_COLOUR
	environment.fog_density = FOG_DENSITY
	# Even haze rather than a sun-facing glow: this is humidity between the
	# trees, which has no direction to it.
	environment.fog_sun_scatter = 0.0

	sun.light_color = SUN_COLOUR


func fall_threshold_y() -> float:
	return _point(LENGTH).y - 18.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 5
	var spacing := 1.6

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
				_frame_at(-back) * Vector3(x, 0.9, 0.0)
			)
		)

	return spawns
