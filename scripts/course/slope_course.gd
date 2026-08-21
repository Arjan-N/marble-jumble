class_name SlopeCourse
extends Course

## A plain straight test slope: one rectangle, guard rails, a handful of
## obstacles, a choke, a jump, a finish line.
##
## This is not a Canyon and is not trying to be. It exists so that camera,
## marble feel and pacing can be judged against geometry that cannot itself be
## the problem. The Canyon prototype in `course_builder.gd` mixes a swept
## ribbon, banking, curvature, variable width and a split all at once â€” when
## the field stalls on it, the cause is ambiguous. Here the track is flat,
## straight and constant-width, so anything that goes wrong is the marbles, the
## obstacles or the camera.
##
## Straightness is also what makes it a clean camera test. The overhead spike
## (`docs/CAMERA_SPIKE.md`) is asking whether a top-down frame reads, and a
## course that never turns removes yaw from the question entirely.
##
## Layout, as fractions of the run:
##
##   0.00  release, clean run to build speed
##   0.16  pillar row
##   0.30  rotating bumper, left of centre
##   0.42  pillar row, staggered against the first
##   0.55  choke
##   0.68  kicker and gap
##   0.80  rotating bumper, right of centre
##   0.90  clean final stretch
##   1.00  finish line

# --- Shape --------------------------------------------------------------------

## Shallow enough that marbles keep accelerating the whole way rather than
## slamming into a terminal speed early. Tuned against the 20-30s target by
## measuring, not by derivation: rolling resistance and obstacle losses dominate
## and neither is worth predicting on paper.
const GRADE := deg_to_rad(9.5)
## Along-slope distance from the start line to the finish.
const LENGTH := 195.0
## Starting ramp behind the line, where the field settles.
const RAMP_LENGTH := 14.0
## Floor and rails carry on past the finish, far enough to reach the backstop the
## field piles up against. Two metres of margin beyond it, so a marble that
## arrives fast enough to bounce back off it lands on floor rather than on air.
const RUNOFF_LENGTH := 8.0

## Half the floor width. The full 12m spans most of the overhead camera's ~13.2m
## frame at `OVERHEAD_DISTANCE` / `OVERHEAD_FOV`, which is what "the width of the
## camera" means here. Retune together with those two.
const HALF_WIDTH := 6.0
const FLOOR_THICKNESS := 1.0
const RAIL_HEIGHT := 2.2
const RAIL_THICKNESS := 0.6

const FRICTION := 0.3
## Restitution of every surface in the course — floor, rails, pillars, bumper.
##
## This is the constant that decides whether an obstacle deflects the field or
## filters it, which `DECISIONS.md` has an opinion about. At 0.1 a marble that
## met a pillar head-on kept almost none of its forward speed: it stopped dead,
## sat there while the field went past, and occasionally never restarted — one
## race in six failed to finish inside 100 seconds. At 0.3 the same hit glances
## off. The field still gets scattered, which is the point; it stops being
## eliminated by a stationary cylinder.
##
## Not a fix for gravity being at 30. Obstacles cost the marble the same
## *fraction* of its speed at either gravity (47% held before, 44% after) — they
## only look more brutal because that fraction is now a bigger number, and
## because the camera turned round and holds less course either side.
const BOUNCE := 0.3

# --- Features -----------------------------------------------------------------

const PILLAR_ROW_A := 0.16
const PILLAR_ROW_B := 0.42
const PILLAR_RADIUS := 0.6
const PILLAR_HEIGHT := 1.6
## Every gap a marble can be pushed into â€” between two pillars, or between a
## pillar and a rail â€” must clear this. A marble is 0.9m across, and the first
## layout left 0.5m against the rail: the player wedged there at t=25 and the
## race never ended. Obstacles are supposed to deflect the field, not filter it.
const MIN_GAP := 1.4

const BUMPER_A := Vector2(0.30, -2.4) ## fraction along, lateral offset
const BUMPER_B := Vector2(0.80, 2.4)

const CHOKE_AT := 0.55
const CHOKE_LENGTH := 14.0
## Wide enough that the field squeezes through rather than jamming. The Canyon's
## funnel closes to 2.0 and that is where its field piles up and dies.
const CHOKE_HALF_WIDTH := 2.6

const JUMP_AT := 0.68
const KICKER_LENGTH := 5.0
const KICKER_ANGLE := deg_to_rad(11.0)
const KICKER_THICKNESS := 0.8
## Marbles reach the kicker at roughly 6-7 m/s, which throws them about 3m down a
## slope of this grade. 5.5m dropped most of the field into the hole, and
## DECISIONS.md wants falls occasional rather than the dominant failure mode.
const GAP_LENGTH := 2.5

## Cross-stripes every this many metres. Purely visual, no collision. The first
## overhead render came back as an unbroken beige mass with no sense of motion
## in it (`docs/CAMERA_SPIKE.md`); a top-down camera needs something on the
## surface to move past.
const STRIPE_SPACING := 12.0
const STRIPE_LENGTH := 1.2

const FLOOR_COLOUR := Color(0.42, 0.45, 0.52)
const STRIPE_COLOUR := Color(0.30, 0.33, 0.40)
const RAIL_COLOUR := Color(0.88, 0.62, 0.24)
const OBSTACLE_COLOUR := Color(0.62, 0.66, 0.74)
const FINISH_COLOUR := Color(0.95, 0.95, 0.98)


func build() -> void:
	_build_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_floor()
	_build_rails()
	_build_stripes()
	_build_back_wall()

	_build_pillar_row(PILLAR_ROW_A, [-3.4, 0.0, 3.4])
	_build_pillar_row(PILLAR_ROW_B, [-3.9, -1.3, 1.3, 3.9])
	_build_bumper(BUMPER_A)
	_build_bumper(BUMPER_B)
	_build_choke()
	_build_kicker()
	_build_finish_line()


# --- Frame --------------------------------------------------------------------


## Distance `s` is measured along the slope from the start line: negative is up
## the starting ramp, `LENGTH` is the finish.
func _point(s: float) -> Vector3:
	return _forward() * s


func _forward() -> Vector3:
	return Vector3(0.0, -sin(GRADE), -cos(GRADE))


## Every fixture is placed through this, so nothing in the course has to know
## the grade. Local -Z runs down-slope, local Y is the floor normal.
func _frame_at(s: float) -> Transform3D:
	var forward := _forward()
	var right := Vector3.RIGHT
	var up := right.cross(forward).normalized()
	return Transform3D(Basis(right, up, -forward), _point(s))


func _at(fraction: float) -> Transform3D:
	return _frame_at(fraction * LENGTH)


func _build_curve() -> void:
	# Two points and no handles: a straight line is exactly what this course is,
	# and the camera only needs somewhere to sample position and tangent.
	curve = Curve3D.new()
	curve.add_point(_point(-RAMP_LENGTH))
	curve.add_point(_point(LENGTH))


# --- Surface ------------------------------------------------------------------


## The floor is two rectangles rather than one because the jump needs a hole in
## it. Both lie in the same plane, so the join has no seam to catch a marble.
##
## It runs past `LENGTH` to reach the backstop. Ending it on the finish line left
## six metres of nothing in front of the backstop, and every marble that crossed
## the line rolled straight off the world — invisible at the old pace because
## `_check_for_falls()` ignores marbles that have already finished, and obvious
## at 30 gravity, where the whole field launches off the end.
func _build_floor() -> void:
	var jump_start := JUMP_AT * LENGTH
	_build_floor_span(-RAMP_LENGTH, jump_start)
	_build_floor_span(jump_start + GAP_LENGTH, LENGTH + RUNOFF_LENGTH)


func _build_floor_span(from_s: float, to_s: float) -> void:
	var span := to_s - from_s
	_add_box(
		_frame_at((from_s + to_s) * 0.5).translated_local(
			Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0)
		),
		Vector3(HALF_WIDTH * 2.0, FLOOR_THICKNESS, span),
		FLOOR_COLOUR
	)


## One box per side for the whole length. A run of shorter rails would put a
## seam every few metres, and seams on a sloped surface are what the Canyon
## builder's own notes call out as marble traps.
func _build_rails() -> void:
	var span := LENGTH + RAMP_LENGTH + RUNOFF_LENGTH
	var centre := (LENGTH + RUNOFF_LENGTH - RAMP_LENGTH) * 0.5
	var offset := HALF_WIDTH + RAIL_THICKNESS * 0.5

	for side: float in [-1.0, 1.0]:
		_add_box(
			_frame_at(centre).translated_local(
				Vector3(side * offset, RAIL_HEIGHT * 0.5, 0.0)
			),
			Vector3(RAIL_THICKNESS, RAIL_HEIGHT, span),
			RAIL_COLOUR
		)


## Visual only â€” no bodies, no collision.
func _build_stripes() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = STRIPE_COLOUR
	material.roughness = 0.95

	var s := STRIPE_SPACING
	while s < LENGTH:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(HALF_WIDTH * 2.0, 0.05, STRIPE_LENGTH)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = material
		visual.transform = _frame_at(s).translated_local(Vector3(0.0, 0.02, 0.0))
		add_child(visual)
		s += STRIPE_SPACING


func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(
			Vector3(0.0, RAIL_HEIGHT * 0.5, RAIL_THICKNESS * 0.5)
		),
		Vector3(HALF_WIDTH * 2.0, RAIL_HEIGHT, RAIL_THICKNESS),
		RAIL_COLOUR.darkened(0.35)
	)


# --- Obstacles ----------------------------------------------------------------


## Static geometry, not a mechanic. `DECISIONS.md` fixes the rotating bumper as
## the only Phase 0 obstacle and parks boosters, launchers, moving platforms and
## conveyors for later courses; pillars are neither â€” they are something to
## bounce off, the same way a wall is.
func _build_pillar_row(fraction: float, offsets: Array) -> void:
	var frame := _at(fraction)
	_assert_gaps_passable(offsets)

	for offset: float in offsets:
		var body := StaticBody3D.new()
		body.transform = frame.translated_local(
			Vector3(offset, PILLAR_HEIGHT * 0.5, 0.0)
		)
		body.physics_material_override = _surface()

		var shape := CylinderShape3D.new()
		shape.radius = PILLAR_RADIUS
		shape.height = PILLAR_HEIGHT
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

		var mesh := CylinderMesh.new()
		mesh.top_radius = PILLAR_RADIUS
		mesh.bottom_radius = PILLAR_RADIUS
		mesh.height = PILLAR_HEIGHT
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(OBSTACLE_COLOUR)
		body.add_child(visual)

		add_child(body)


## Checked rather than eyeballed, because the failure is silent: a too-narrow
## gap does not look wrong in the editor, it just quietly swallows a marble
## twenty seconds into a run and hangs the race.
func _assert_gaps_passable(offsets: Array) -> void:
	var edges := [-HALF_WIDTH]
	for offset: float in offsets:
		edges.append(offset - PILLAR_RADIUS)
		edges.append(offset + PILLAR_RADIUS)
	edges.append(HALF_WIDTH)

	for i in range(0, edges.size() - 1, 2):
		var gap: float = edges[i + 1] - edges[i]
		assert(
			gap >= MIN_GAP,
			"Pillar gap of %.2fm is under MIN_GAP (%.2fm); marbles wedge." % [gap, MIN_GAP]
		)


func _build_bumper(placement: Vector2) -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _at(placement.x).translated_local(
		Vector3(placement.y, 0.0, 0.0)
	)
	add_child(bumper)


## Two walls angled inwards. They narrow the track without narrowing the floor,
## so a marble that loses the squeeze is deflected rather than stopped.
func _build_choke() -> void:
	var taper := HALF_WIDTH - CHOKE_HALF_WIDTH
	var angle := atan2(taper, CHOKE_LENGTH)
	var span := sqrt(taper * taper + CHOKE_LENGTH * CHOKE_LENGTH)
	var centre := CHOKE_AT * LENGTH + CHOKE_LENGTH * 0.5

	for side: float in [-1.0, 1.0]:
		var frame := _frame_at(centre).translated_local(
			Vector3(side * (HALF_WIDTH + CHOKE_HALF_WIDTH) * 0.5, RAIL_HEIGHT * 0.5, 0.0)
		)
		_add_box(
			frame.rotated_local(Vector3.UP, side * angle),
			Vector3(RAIL_THICKNESS, RAIL_HEIGHT, span),
			RAIL_COLOUR.darkened(0.15)
		)


## Pivoted at its near end rather than its centre, so the top face starts flush
## with the floor and rises from there. Rotating about the centre would sink the
## near end and leave a step for marbles to slam into at speed.
func _build_kicker() -> void:
	var frame := _frame_at(JUMP_AT * LENGTH - KICKER_LENGTH)
	frame = frame.rotated_local(Vector3.RIGHT, KICKER_ANGLE)
	frame = frame.translated_local(
		Vector3(0.0, -KICKER_THICKNESS * 0.5, -KICKER_LENGTH * 0.5)
	)
	_add_box(
		frame,
		Vector3(HALF_WIDTH * 2.0, KICKER_THICKNESS, KICKER_LENGTH),
		OBSTACLE_COLOUR.darkened(0.15)
	)


## A visible line plus a backstop. The line is what the player reads; the
## backstop is so finishers pile up just past it instead of rolling off the end
## and registering as falls.
func _build_finish_line() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = FINISH_COLOUR
	material.roughness = 0.8

	var mesh := BoxMesh.new()
	mesh.size = Vector3(HALF_WIDTH * 2.0, 0.06, 1.0)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.transform = _frame_at(LENGTH).translated_local(Vector3(0.0, 0.03, 0.0))
	add_child(visual)

	_add_box(
		_frame_at(LENGTH + 6.0).translated_local(
			Vector3(0.0, RAIL_HEIGHT * 0.5, 0.0)
		),
		Vector3(HALF_WIDTH * 2.0, RAIL_HEIGHT, RAIL_THICKNESS),
		RAIL_COLOUR.darkened(0.35)
	)


# --- Helpers ------------------------------------------------------------------


func _surface() -> PhysicsMaterial:
	var surface := PhysicsMaterial.new()
	surface.friction = FRICTION
	surface.bounce = BOUNCE
	return surface


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	return material


func _add_box(transform: Transform3D, size: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new()
	body.transform = transform
	body.physics_material_override = _surface()

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


# --- Course interface ---------------------------------------------------------


func fall_threshold_y() -> float:
	# Only the gap can drop a marble out of this course, and the rails stop
	# everything else, so the threshold just has to sit clear of the finish.
	return _point(LENGTH).y - 20.0


func finish_width() -> float:
	return HALF_WIDTH * 2.0


func start_width() -> float:
	return HALF_WIDTH * 2.0


## Six across rather than the Canyon's four: the track is twice as wide, and a
## narrow huddle on a wide start line wastes the opening entirely.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 6
	var spacing := 1.7

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.5 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(
			Transform3D(Basis.IDENTITY, _frame_at(-back) * Vector3(x, 0.9, 0.0))
		)

	return spawns
