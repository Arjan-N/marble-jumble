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
	# The funnel-to-split stretch (6→7 below) descends at ~14 degrees; the
	# original "small uphill" point right after it was a near-flat ~4 degrees —
	# a sudden deceleration at a single knot. Catmull-Rom's tangent at that knot
	# is blended from its neighbours (see CURVE_TENSION below), so a slope this
	# abrupt makes the baked curve overshoot: it bulges upward locally even
	# though both endpoints still descend, exactly matching the field's
	# documented stall near ratio 0.66 and the "sudden slope that almost cannot
	# be overcome" seen on screen. Split into two gentler steps (~11 degrees,
	# then ~9) instead of one sharp one so the tangent has room to catch up.
	Vector3(0.0, -23.5, -100.0), # funnel exit, tapering off the descent
	Vector3(0.0, -25.5, -108.0), # split / merge
	Vector3(0.0, -26.7, -119.0), # small uphill, slowdown
	Vector3(0.0, -28.4, -131.0), # jump approach
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

## The gap has no ramp of its own — the floor just stops, so a marble takes off
## carrying whatever vertical speed the descent already gave it, not an upward
## one. That is fine at a crawl; once the field is actually moving (see
## `_bank_at`'s comment — this jump used to be unreachable at speed because
## the field never got this far intact) a marble arrives already descending
## at several m/s, dips below the resumed floor's height before it gets there
## horizontally, and sails under its leading edge into open air for good.
## `tools/probe_bumper_speed_temp.gd`-style tracing (a marble's velocity
## logged across ratio 0.79-0.95) showed exactly that: a clean gravity-only
## trajectory from the moment the floor disappears, never interrupted by a
## landing. A short, smooth ramp right at the take-off edge — tilted upward
## rather than flat — turns that same speed into a genuine arc that clears
## the gap with room to spare instead of undercutting the landing.
const JUMP_RAMP_LENGTH := 3.0
const JUMP_RAMP_TILT := deg_to_rad(16.0)
const JUMP_RAMP_THICKNESS := 0.4
const ROUGH_UNTIL := 0.55 ## Rough canyon stone before here, smoother build after.

const ROUGH_FRICTION := 0.55
const SMOOTH_FRICTION := 0.25
const ROUGH_COLOUR := Color(0.62, 0.47, 0.36)
## Was a near-neutral (0.48, 0.50, 0.54). With default specular still on (see
## `_build_surface`) and roughness at 0.9 rather than fully killed, a colour
## this close to grey shows the sky's own blue rather than any tone of its
## own — the same problem `slope_course.gd`'s SURFACE_SMOOTH had. Warmed to
## read as pale stone instead of ice.
const SMOOTH_COLOUR := Color(0.58, 0.52, 0.42)

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
	_add_jump_ramp()
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
##
## Only the horizontal turn matters here — banking reacts to a bend, not to a
## change in descent grade. Feeding the raw 3D tangents to `signed_angle_to`
## measured the *full* angle between them, pitch included, so an ordinary
## easing of the slope (no lateral turn at all) read as a large turn rate.
## Worse, on a stretch straight in X the two tangents' X components are both
## essentially zero, so the sign of that spurious turn rate was decided by
## sub-millimetre floating-point noise — banking flipped by double digits of
## degrees between adjacent rings with nothing in the geometry to justify it,
## and that discontinuity in the swept cross-section is what trapped the
## field around ratio 0.66. Flattening both tangents onto the horizontal
## plane before comparing measures yaw alone, which is zero exactly where a
## straight course actually is straight.
func _bank_at(offset: float) -> float:
	var behind := _tangent_at(offset - BANK_BASELINE)
	var ahead := _tangent_at(offset + BANK_BASELINE)
	var behind_flat := Vector3(behind.x, 0.0, behind.z).normalized()
	var ahead_flat := Vector3(ahead.x, 0.0, ahead.z).normalized()
	var turn_rate := behind_flat.signed_angle_to(ahead_flat, Vector3.UP) / (2.0 * BANK_BASELINE)
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
	material.metallic = 0.0
	# Godot's default specular puts a soft sheen on every surface; against a
	# blue sky that sheen reads as a cool highlight on what is meant to be
	# rock. `slope_course.gd` disables this for the same reason.
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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


## A run of short boxes, each using its own local frame, not one long box built
## from a single frame at the range's midpoint. `WIDTH_KEYS` takes the trough
## from a 2.0 half-width funnel at ratio 0.58 to a 3.6 split/merge at 0.66 and
## back to 3.0 by 0.78 — the divider sits inside that change, and a single
## rigid box spanning it, oriented only at its centre, drifts away from the
## actual swept floor's width and banking at both ends. That mismatch is the
## likely cause of this course's documented stall near ratio 0.66: an invisible
## lip or pocket where the straight box and the curved floor disagree, wide
## enough to catch a marble and never let it go. Each segment here is short
## enough that the same drift over its own length is negligible.
##
## Which side a marble takes is still decided by physics alone, with no route
## selection and no AI (spec section 6) — segmenting the geometry doesn't
## touch that.
const DIVIDER_SEGMENT_LENGTH := 2.0

func _add_split_divider() -> void:
	var from_offset := _offset_for_ratio(SPLIT_RANGE.x)
	var to_offset := _offset_for_ratio(SPLIT_RANGE.y)

	var s := from_offset
	while s < to_offset - 0.001:
		var next := minf(s + DIVIDER_SEGMENT_LENGTH, to_offset)
		var frame := _frame_at((s + next) * 0.5)
		_add_box(
			frame.translated_local(Vector3(0.0, WALL_HEIGHT * 0.4, 0.0)),
			Vector3(0.5, WALL_HEIGHT * 0.8, next - s),
			Color(0.55, 0.45, 0.38),
			SMOOTH_FRICTION
		)
		s = next


## A short, upward-tilted lip right at the gap's take-off edge. See
## `JUMP_RAMP_LENGTH`'s comment for why the gap needs one at all.
##
## Built from the same `_frame_at` the rest of the ribbon uses, so it inherits
## the trough's own banking (none here, but the next jump this technique gets
## reused for might not be so lucky) rather than assuming the course is flat.
## Tilting a box around its local right axis lifts the end further along the
## track (`-forward` locally) and sinks the trailing end into the existing
## floor by the same amount; the sunk end is a harmless overlap between two
## static bodies, and the lifted end is the whole point.
func _add_jump_ramp() -> void:
	var gap_offset := _offset_for_ratio(JUMP_GAP_RANGE.x)
	var frame := _frame_at(gap_offset - JUMP_RAMP_LENGTH * 0.5)
	var half_width := _width_at(JUMP_GAP_RANGE.x)

	var tilt := Transform3D(Basis(Vector3.RIGHT, JUMP_RAMP_TILT), Vector3.ZERO)
	_add_box(
		frame * tilt,
		Vector3(half_width * 2.0, JUMP_RAMP_THICKNESS, JUMP_RAMP_LENGTH),
		ROUGH_COLOUR.darkened(0.15),
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
