class_name GlacierFaultCourse
extends Course

## Glacier Fault — a stone gate frozen into a glacier wall.
##
## First pass tried to contain its one turn by steepening the swept
## quadratic-shoulder shape `course_builder.gd`/`sky_ruins_course.gd` use for
## their dish floor, and it went wrong two ways: the shoulder curve has no
## natural sense of scale and produced a wall tens of metres tall before being
## caught, and even scaled down the course played as too complex and blocked
## the camera's view of the track. This version is deliberately plain: a flat
## floor plane throughout, a pair of literal flat vertical wall planes (fixed
## at 1.8m — twice a marble's own diameter, not derived from any curve) only
## through the one turn that needs containment, one obstacle, no jump.
##
## Three beats: Frozen Entry | Ice Bend | Sprint. The Bend is the only place
## marbles are ever banked, and it is the only place with walls.

# --- Shape --------------------------------------------------------------------

const LENGTH := 110.0
const RAMP_LENGTH := 12.0
const RUNOFF_LENGTH := 8.0

## Section boundaries, as fractions of `LENGTH`.
const BEND_START := 0.28
const BEND_END := 0.60

## Gentle throughout — this course's whole point is to be simple and to work,
## not to be fast. Held flat through the Bend for the same reason
## `SkyRuinsCourse` holds its own turn back: extra speed into a turn is what
## throws marbles at a wall hard enough to cause trouble, not what carries
## them through it.
const PITCH := [
	[0.14, 6.0],   ## Frozen Entry: wide, barely descending.
	[BEND_START, 7.0],
	[BEND_END, 6.0],   ## Ice Bend: held back.
	[0.80, 9.5],   ## Sprint opens up.
	[1.00, 12.0],  ## Sprint to the line.
]

## One mild turn, well under the turn rate `VolcanoCourse`/`JungleCourse` race
## at (roughly 0.6°/m) even though this bend has walls to fall back on and
## those courses don't — the wall is a backstop, not a licence to turn harder.
## 22° over 35m is 0.63°/m at the steepest single step; spread across several
## small steps per `CoursePath`'s fixed smoothing window, same technique every
## turning course here uses.
const HEADING := [
	[BEND_START, 0.0],
	[0.36, -6.0],
	[0.44, -12.0],
	[0.52, -18.0],
	[BEND_END, -22.0],
	[1.00, -22.0],
]

## Half-width along the course. Narrower through the Bend so the wall sits
## close enough to catch a marble the bank throws wide without giving it room
## to build speed across open floor first.
const WIDTH := [
	[0.10, 4.6],
	[BEND_START, 4.6],
	[0.44, 3.6],
	[BEND_END, 3.6],
	[1.00, 4.6],
]

## Wall height along the course — a low curb everywhere (so the track always
## reads as having sides, not open floor), raised only through the Bend where
## containment actually matters. Fixed values, not derived from any curve:
## twice a marble's own diameter (~0.9m) in the Bend, comfortably taller than
## `CoursePath.BANK_LIMIT_DEGREES`' 26° bank would ever throw a marble, without
## dwarfing the track the way the old quadratic shoulder did. Sampled through
## `CoursePath.sample` like `WIDTH` is, so the rise into and out of the Bend is
## smoothed rather than a step a marble would clip.
const CURB_HEIGHT := 0.4
const WALL_HEIGHT := 1.8
const WALL_HEIGHT_PROFILE := [
	[BEND_START, CURB_HEIGHT],
	[BEND_START + 0.02, WALL_HEIGHT],
	[BEND_END - 0.02, WALL_HEIGHT],
	[BEND_END, CURB_HEIGHT],
	[1.00, CURB_HEIGHT],
]

const MESH_STEP := 1.0
const RUN_OVERLAP := 0.35

# --- Surfaces -----------------------------------------------------------------

## Friction low throughout (ice), raised slightly in the Bend — the one lever
## this course has that a wall-less course doesn't, per
## `[[marble-jumble-sky-ruins-course-in-progress]]`'s own postmortem.
const SURFACE_ENTRY := {"friction": 0.20, "colour": Color(0.80, 0.88, 0.94)}
const SURFACE_BEND := {"friction": 0.24, "colour": Color(0.72, 0.83, 0.92)}
const SURFACE_SPRINT := {"friction": 0.14, "colour": Color(0.86, 0.93, 0.98)}

const SURFACES := [
	[BEND_START, SURFACE_ENTRY],
	[BEND_END, SURFACE_BEND],
	[1.00, SURFACE_SPRINT],
]
const BOUNCE := 0.12

# --- Frozen gate ---------------------------------------------------------------

## The single obstacle, placed on the open Sprint straight rather than in the
## Bend — a knock should not compound with the one section already carrying
## the course's only real risk.
const BUMPER_AT := 0.72
const STONE_COLOUR := Color(0.72, 0.78, 0.84)
const STONE_DARK := Color(0.42, 0.50, 0.58)

## Darker and more saturated than any floor colour in `SURFACES`, so the wall
## panels built in `_build_run` read as sides against the floor at a glance
## rather than blending into it.
const WALL_COLOUR := Color(0.46, 0.62, 0.76)

# --- Decoration ---------------------------------------------------------------

const ICE_HAZE_COLOUR := Color(0.78, 0.90, 0.98, 0.55)
const FOG_COLOUR := Color(0.80, 0.90, 0.97)
const FINISH_COLOUR := Color(0.92, 0.97, 1.0)
const HAZE_BELOW := 16.0

var _path: CoursePath


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_channel()
	_build_ice_haze()
	_build_back_wall()
	_build_frozen_gate()
	_build_finish_line()


# --- Path -----------------------------------------------------------------------


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


func _surface_at(s: float) -> Dictionary:
	var fraction := s / LENGTH
	for entry: Array in SURFACES:
		if fraction <= entry[0]:
			return entry[1]
	return SURFACES[SURFACES.size() - 1][1]


func _wall_height_at(s: float) -> float:
	return _path.sample(WALL_HEIGHT_PROFILE, s)


# --- Channel ----------------------------------------------------------------


func _build_channel() -> void:
	for run: Dictionary in _runs():
		var from_s: float = run["from"] - (RUN_OVERLAP if run["lead"] else 0.0)
		var to_s: float = run["to"] + (RUN_OVERLAP if run["trail"] else 0.0)
		_build_run(from_s, to_s, run["surface"])


## The course split into stretches of constant surface — the Bend's wall
## height rises and falls smoothly within a run via `_wall_height_at` rather
## than needing its own cut, since every run shares the same four-point shape.
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


## One cross-section, as flat planes throughout: a floor plane plus two
## vertical wall planes, their height sampled from `_wall_height_at` — a low
## curb by default, raised only through the Bend. No curvature anywhere.
func _section_points(s: float) -> Array:
	var half_width := _half_width_at(s)
	var height := _wall_height_at(s)
	return [
		Vector2(-half_width, height),
		Vector2(-half_width, 0.0),
		Vector2(half_width, 0.0),
		Vector2(half_width, height),
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

	## Column 0 is the left wall panel, column 1 the floor, column 2 the right
	## wall panel (`_section_points`' four-vertex order). Split into two visual
	## meshes on that basis, coloured differently, so a wall reads as a wall
	## against the floor rather than blending into it — a single shared colour
	## made the earlier version's low curb invisible even though it was there.
	## Collision stays one shape across every column; physics doesn't care
	## which panel a marble is touching, only where the surface is.
	var all_faces := PackedVector3Array()
	var floor_faces := PackedVector3Array()
	var wall_faces := PackedVector3Array()
	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(near.size() - 1):
			var quad := PackedVector3Array([
				near[c], far[c], near[c + 1],
				near[c + 1], far[c], far[c + 1],
			])
			all_faces.append_array(quad)
			if c == 1:
				floor_faces.append_array(quad)
			else:
				wall_faces.append_array(quad)

	var body := StaticBody3D.new()
	body.physics_material_override = _surface_material(surface["friction"])

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(all_faces)
	shape.backface_collision = false
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	if not floor_faces.is_empty():
		body.add_child(_visual_from_faces(floor_faces, surface["colour"]))
	if not wall_faces.is_empty():
		body.add_child(_visual_from_faces(wall_faces, WALL_COLOUR))

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


# --- Decoration -------------------------------------------------------------


## A pale ice-blue haze plane below the course. Purely visual, standing in for
## depth below the track — anything that reaches it is already eliminated by
## `fall_threshold_y`.
func _build_ice_haze() -> void:
	var s := -RAMP_LENGTH
	while s < LENGTH + RUNOFF_LENGTH:
		var frame := _frame_at(s)

		var floor_mesh := BoxMesh.new()
		floor_mesh.size = Vector3(40.0, 1.0, 12.0)
		var floor_visual := MeshInstance3D.new()
		floor_visual.mesh = floor_mesh
		floor_visual.material_override = _haze_material()
		floor_visual.transform = frame.translated_local(Vector3(0.0, -HAZE_BELOW, 0.0))
		add_child(floor_visual)

		s += 12.0


func _haze_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = ICE_HAZE_COLOUR
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


## The single obstacle, reskinned frozen-stone rather than rusted steel.
func _build_frozen_gate() -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _frame_at(BUMPER_AT * LENGTH)
	_tint(bumper, STONE_COLOUR)
	add_child(bumper)


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
	material.friction = SURFACE_ENTRY["friction"] if friction < 0.0 else friction
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


func decorate_environment(environment: Environment, _sun: DirectionalLight3D) -> void:
	if environment.fog_enabled:
		environment.fog_light_color = FOG_COLOUR


func fall_threshold_y() -> float:
	return _point(LENGTH).y - 20.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 5
	var spacing := 1.5

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
