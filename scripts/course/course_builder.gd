class_name CourseBuilder
extends Course

## Placeholder Canyon geometry for the Phase 0 physics prototype.
##
## The trough is generated as one continuous mesh ribbon swept along a spline,
## with trimesh collision. An earlier version laid discrete boxes segment by
## segment; on a descending, curving centreline consecutive boxes never meet
## flush, and every seam became a wedge that trapped marbles at low speed. A
## swept surface has no seams to trap anything, and is also the shape authored
## geometry will take, so nothing here is throwaway scaffolding in the way the
## box version was.
##
## The course rhythm below is locked by the spec:
##
##   downhill opening -> wide rolling -> S-curve -> narrowing funnel ->
##   split/merge -> small uphill -> short jump -> rotating bumper ->
##   final stretch -> finish
##
## The layout constants are gathered at the top as a step towards the
## data-driven course format PROJECT.md section 6 calls for. They are not that
## format yet, and inventing one before a second course exists would be
## premature.

## Rings must be small relative to the marble. At 1.0 the ribbon behaved like a
## washboard under a 0.45-radius marble: every facet edge and every twisted quad
## cost energy, and the field arrived at the far end having lost roughly 90% of
## what the descent gave it.
const RING_SPACING := 0.35
## Baseline over which curvature is measured for banking. Sampling curvature
## between adjacent rings instead would make the bank depend on ring spacing and
## turn to noise as rings get finer.
const BANK_BASELINE := 3.0
## Taller than it looks like it needs to be: the fillet is quadratic, so at
## halfway up the wall the surface has only risen a quarter of this. A 1.4 wall
## let marbles fly straight out of the S-curve.
const WALL_HEIGHT := 2.4
## Walls lean outwards. A vertical wall catches a marble riding up it; a leaning
## one lets it ride up and fall back into the channel.
const WALL_LEAN := 0.55
## Points per side of the trough cross-section, and how much of the half-width
## stays flat before the fillet begins.
const PROFILE_STEPS := 4
const FLAT_FRACTION := 0.5

const BANK_GAIN := 12.0
const MAX_BANK := deg_to_rad(22.0)
## Catmull-Rom expressed as cubic Bezier handles wants exactly 1/6 of the chord
## across the neighbouring points. Larger values overshoot: at 0.35 the spline
## bulged past its own control points hard enough to manufacture a local uphill
## in the S-curve, and the field stalled there every run.
const CURVE_TENSION := 1.0 / 6.0

## The barrier sits at the origin. Everything at positive Z is the starting
## ramp; the race proper runs from here down -Z, away from the player.
const RACE_START_POINT := Vector3.ZERO

## Grade matters more than any other number here. An earlier layout dropped
## 15.5m over 204m — a 4.3 degree average — and the field plateaued near 4 m/s,
## putting the run past 60s against a 20-30s target. This descends roughly 12
## degrees, which is what a marble actually needs to build speed.
const CONTROL_POINTS := [
	Vector3(0.0, 1.25, 10.0),    # top of the starting grid ramp
	RACE_START_POINT,            # barrier line
	Vector3(0.0, -3.5, -16.0),   # gentle downhill opening
	Vector3(0.0, -7.5, -35.0),   # wide rolling section
	Vector3(6.0, -12.0, -55.0),  # S-curve, first bend
	Vector3(-6.0, -16.5, -74.0), # S-curve, second bend
	Vector3(0.0, -21.0, -92.0),  # narrowing funnel
	Vector3(0.0, -25.0, -108.0), # split / merge
	Vector3(0.0, -24.6, -119.0), # small uphill, slowdown
	Vector3(0.0, -27.5, -131.0), # jump approach
	Vector3(0.0, -31.0, -145.0), # rotating bumper
	Vector3(0.0, -34.0, -159.0), # finish
]

## Half-width of the trough, keyed by progress through the race. Narrow
## sections are deliberate collision points, not the default width.
const WIDTH_KEYS := [
	Vector2(0.00, 3.0),
	Vector2(0.12, 4.5),  # wide rolling
	Vector2(0.45, 4.5),
	Vector2(0.58, 2.0),  # funnel
	Vector2(0.66, 3.6),  # split / merge
	Vector2(0.78, 3.0),
	Vector2(1.00, 3.0),
]

const SPLIT_RANGE := Vector2(0.63, 0.71)
const JUMP_GAP_RANGE := Vector2(0.795, 0.825)
const BUMPER_AT := 0.885
const ROUGH_UNTIL := 0.55 ## Rough canyon stone before here, smoother build after.

const ROUGH_FRICTION := 0.55
const SMOOTH_FRICTION := 0.25
const ROUGH_COLOUR := Color(0.62, 0.47, 0.36)
const SMOOTH_COLOUR := Color(0.48, 0.50, 0.54)

## Marbles below this are out of bounds. Must stay clear of the finish, which
## is the lowest point of the course. Tunable, per the spec.
const FALL_THRESHOLD_Y := -60.0

var _length := 0.0
var _race_start_offset := 0.0
var _race_length := 0.0
var _rings: Array[Dictionary] = []


func build() -> void:
	_build_curve()

	_race_start_offset = curve.get_closest_offset(RACE_START_POINT)
	_race_length = _length - _race_start_offset
	start_transform = _frame_at(_race_start_offset)
	finish_position = curve.sample_baked(_length)

	_sample_rings()

	# Split into two bodies so the rough and smooth sections can carry
	# different friction: one body can only hold one physics material.
	var boundary := _ring_index_for_ratio(ROUGH_UNTIL)
	_build_surface(0, boundary, ROUGH_FRICTION, ROUGH_COLOUR)
	_build_surface(boundary, _rings.size() - 1, SMOOTH_FRICTION, SMOOTH_COLOUR)

	_add_back_wall()
	_add_split_divider()
	_add_bumper()


# --- Centreline ---------------------------------------------------------------


func _build_curve() -> void:
	curve = Curve3D.new()
	for point in CONTROL_POINTS:
		curve.add_point(point)

	# Zero handles make Curve3D a polyline, which puts a hard kink at every
	# control point. Catmull-Rom style handles give the smooth, bankable path
	# the course description assumes.
	var count := curve.point_count
	for i in count:
		var previous := curve.get_point_position(maxi(i - 1, 0))
		var next := curve.get_point_position(mini(i + 1, count - 1))
		var tangent := (next - previous) * CURVE_TENSION
		curve.set_point_in(i, -tangent)
		curve.set_point_out(i, tangent)

	_length = curve.get_baked_length()


func _tangent_at(offset: float) -> Vector3:
	var clamped := clampf(offset, 0.0, _length)
	var behind := curve.sample_baked(maxf(clamped - 0.5, 0.0))
	var ahead := curve.sample_baked(minf(clamped + 0.5, _length))

	var tangent := (ahead - behind).normalized()
	return tangent if not tangent.is_zero_approx() else Vector3.FORWARD


## Bank from the centreline's curvature, measured over a fixed baseline so the
## result is the same whatever the ring spacing is.
func _bank_at(offset: float) -> float:
	var behind := _tangent_at(offset - BANK_BASELINE)
	var ahead := _tangent_at(offset + BANK_BASELINE)
	var turn_rate := behind.signed_angle_to(ahead, Vector3.UP) / (2.0 * BANK_BASELINE)
	# Negated: rotating about the forward axis by a positive angle drops the
	# right-hand edge, so the raw turn rate banks the inside of the corner up and
	# tips marbles out of the channel instead of holding them in it.
	return clampf(-turn_rate * BANK_GAIN, -MAX_BANK, MAX_BANK)


## Builds a transform following the centreline, banked into its curves.
func _frame_at(offset: float) -> Transform3D:
	var here := curve.sample_baked(clampf(offset, 0.0, _length))
	var forward := _tangent_at(offset)

	var right := forward.cross(Vector3.UP).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var up := right.cross(forward).normalized()

	# Rotating about the forward axis leaves the tangent untouched.
	var basis := Basis(right, up, -forward).rotated(forward, _bank_at(offset))
	return Transform3D(basis, here)


func _sample_rings() -> void:
	_rings.clear()

	var count := int(_length / RING_SPACING)

	for i in count + 1:
		var offset := minf(float(i) * RING_SPACING, _length)
		var ratio := (offset - _race_start_offset) / _race_length
		_rings.append({
			"frame": _frame_at(offset),
			"ratio": ratio,
			"half_width": _width_at(ratio),
		})


# --- Surface ------------------------------------------------------------------


## Cross-section of the trough at a ring, in world space, running left wall top
## down through the floor and back up to right wall top.
##
## The walls meet the floor through a quadratic fillet rather than a corner. A
## sharp floor-to-wall crease gives a marble two contact points at once, and with
## any real friction that locks it rotationally: it stops dead against the wall
## instead of rolling along it. The fillet is tangent to the floor at its base,
## so there is no crease anywhere to catch on.
func _profile(ring: Dictionary) -> Array:
	var frame: Transform3D = ring["frame"]
	var half_width: float = ring["half_width"]
	var flat := half_width * FLAT_FRACTION
	var rise := half_width - flat + WALL_LEAN

	var points := []
	for side: float in [-1.0, 1.0]:
		for step in PROFILE_STEPS + 1:
			var t := float(step) / float(PROFILE_STEPS)
			if side < 0.0:
				t = 1.0 - t # left side runs from wall top down to the floor
			points.append(
				frame * Vector3(side * (flat + rise * t), WALL_HEIGHT * t * t, 0.0)
			)

	return points


func _build_surface(from_index: int, to_index: int, friction: float, colour: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(from_index, to_index):
		var here := _profile(_rings[i])
		var ahead := _profile(_rings[i + 1])
		var skip_floor := _in_range(_rings[i]["ratio"], JUMP_GAP_RANGE)
		var strips := here.size() - 1

		for strip in strips:
			# Over the jump, everything but the outermost sliver of each wall is
			# removed. Dropping only the centre strip would leave the fillets
			# still wide enough to carry a marble across.
			if skip_floor and strip > 0 and strip < strips - 1:
				continue
			_add_quad(tool, here[strip], here[strip + 1], ahead[strip + 1], ahead[strip])

	tool.generate_normals()
	var mesh := tool.commit()

	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	# The ribbon is a single-sided surface and winding varies with the banking;
	# for placeholder geometry, drawing both sides beats chasing normals.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material

	var surface := PhysicsMaterial.new()
	surface.friction = friction
	surface.bounce = 0.1

	var shape := mesh.create_trimesh_shape()
	# Trimesh collision is one-sided, and the swept ribbon's winding flips with
	# the banking. Without this, marbles pass straight through the stretches
	# whose collidable face ends up pointing away from them.
	shape.backface_collision = true

	var collider := CollisionShape3D.new()
	collider.shape = shape

	var body := StaticBody3D.new()
	body.physics_material_override = surface
	body.add_child(collider)
	body.add_child(visual)
	add_child(body)


func _add_quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)
	tool.add_vertex(a)
	tool.add_vertex(c)
	tool.add_vertex(d)


# --- Fixtures -----------------------------------------------------------------


## Closes the top of the starting ramp so a marble cannot roll out backwards.
func _add_back_wall() -> void:
	var ring: Dictionary = _rings[0]
	var frame: Transform3D = ring["frame"]
	var half_width: float = ring["half_width"]
	_add_box(
		frame.translated_local(Vector3(0.0, WALL_HEIGHT * 0.5, 0.5)),
		Vector3(half_width * 2.0, WALL_HEIGHT, 0.4),
		ROUGH_COLOUR.darkened(0.3),
		ROUGH_FRICTION
	)


## One divider, as a single long box rather than a run of short ones: the
## section is straight here, and a run of boxes would reintroduce the seams the
## swept surface exists to avoid. Which side a marble takes is decided by
## physics alone, with no route selection and no AI (spec section 6).
func _add_split_divider() -> void:
	var centre_ratio := (SPLIT_RANGE.x + SPLIT_RANGE.y) * 0.5
	var length := (SPLIT_RANGE.y - SPLIT_RANGE.x) * _race_length
	var frame := _frame_at(_offset_for_ratio(centre_ratio))
	_add_box(
		frame.translated_local(Vector3(0.0, WALL_HEIGHT * 0.4, 0.0)),
		Vector3(0.5, WALL_HEIGHT * 0.8, length),
		Color(0.55, 0.45, 0.38),
		SMOOTH_FRICTION
	)


func _add_bumper() -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _frame_at(_offset_for_ratio(BUMPER_AT))
	add_child(bumper)


func _add_box(
	transform: Transform3D, size: Vector3, colour: Color, friction: float
) -> void:
	var body := StaticBody3D.new()
	body.transform = transform

	var surface := PhysicsMaterial.new()
	surface.friction = friction
	surface.bounce = 0.1
	body.physics_material_override = surface

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)

	add_child(body)


# --- Queries ------------------------------------------------------------------


func _offset_for_ratio(ratio: float) -> float:
	return _race_start_offset + ratio * _race_length


func _ring_index_for_ratio(ratio: float) -> int:
	for i in _rings.size():
		if _rings[i]["ratio"] >= ratio:
			return i
	return _rings.size() - 1


func _width_at(ratio: float) -> float:
	# Negative ratios are the starting ramp, which keeps the opening width.
	if ratio <= WIDTH_KEYS[0].x:
		return float(WIDTH_KEYS[0].y)

	for i in range(WIDTH_KEYS.size() - 1):
		var from: Vector2 = WIDTH_KEYS[i]
		var to: Vector2 = WIDTH_KEYS[i + 1]
		if ratio >= from.x and ratio <= to.x:
			var t := inverse_lerp(from.x, to.x, ratio)
			return lerpf(from.y, to.y, smoothstep(0.0, 1.0, t))

	return float(WIDTH_KEYS[WIDTH_KEYS.size() - 1].y)


func _in_range(ratio: float, bounds: Vector2) -> bool:
	return ratio >= bounds.x and ratio <= bounds.y


func fall_threshold_y() -> float:
	return FALL_THRESHOLD_Y


## Starting slots on the ramp, subtly varied per race so opening states are
## never identical while no slot is obviously advantageous.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 4
	var spacing := 1.3

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.0 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		# Placed against the ramp's own frame, so the grid sits on the slope
		# however the ramp is shaped.
		var frame := _frame_at(maxf(_race_start_offset - back, 0.0))
		spawns.append(Transform3D(Basis.IDENTITY, frame * Vector3(x, 0.9, 0.0)))

	return spawns
