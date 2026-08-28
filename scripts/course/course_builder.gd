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
	# --- Runoff, past the line -------------------------------------------------
	#
	# The course used to stop at the finish. Marbles crossed it, ran off the end
	# of the ribbon and dropped into open air, and the only thing that made that
	# survivable was that a FINISHED marble is exempt from the fall check — so
	# the round scored correctly while the field it scored was falling out of the
	# world. The other courses papered over the same shape with a wall six metres
	# past the line, which stops a marble rather than slowing one.
	#
	# These three points are the runoff `FinishZone` ramps damping across: still
	# descending as the line is crossed, so nothing changes underfoot at the
	# moment that matters, then flattening hard. 6.6 degrees, then 2.6, then
	# barely half a degree of holding area for the field to settle in.
	Vector3(0.0, -35.4, -171.0), # runoff, easing off the descent
	Vector3(0.0, -36.0, -184.0), # runoff, near level
	Vector3(0.0, -36.1, -193.0), # holding area
]

## Index of the finish in `CONTROL_POINTS`. Everything after it is runoff, and
## ratio 1.0 still means the finish rather than the end of the geometry — every
## `WIDTH_KEYS`, `SPLIT_RANGE`, `JUMP_GAP_RANGE` and `VIADUCT_RANGES` value is
## written against that, so the race is laid out exactly where it always was.
const FINISH_POINT_INDEX := 12

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
	# Past the line the trough opens out. A six-metre channel is a fine final
	# stretch and a bad runoff: twelve marbles arriving into one at speed stack
	# up nose to tail, and the finishing order stops being something you can see
	# on the track. Flared over roughly fifteen metres rather than at the line,
	# so the walls read as opening rather than as a step outward.
	Vector2(1.10, 4.6),
	Vector2(1.24, 5.4),
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
## The ramp turns arrival speed into an arc, but it cannot invent speed a
## marble does not have, and too much of the field was arriving under the
## ramp's own break-even and dropping straight into the river. A speed floor on
## the run-in is the fix every other course with a gap ended up at — see
## `BoostPad`'s header for why a floor rather than a multiplier, and why it
## cannot reorder a field that is already running well.
##
## There is a cliff here, not a gradient, and this sits just past it. Measured
## over eight full 12-marble rounds each, marbles crossing the gap:
##
##   no boost  16/96      13.0  75/96      14.0  90/96
##   12.0      32/96      13.5  89/96      18.0  92/96
##
## Which is what the ballistics predict: a 16-degree launch needs about 9.7 m/s
## to carry the 5.1m gap in vacuum, and the ramp itself costs a few m/s to
## climb, so anything under ~13 at the pad is short no matter how well it is
## aimed. Below the cliff the boost is wasted; well above it nothing further is
## bought — 18.0 lands within noise of 14.0 while making the jump trivial and
## the top-up large enough to feel. 14.0 is the smallest number that clears.
##
## Six of 96 still miss, which is what a jump is for.
const JUMP_BOOST_SPEED := 14.0
## Far enough back that the top-up is spent rolling onto the ramp rather than
## applied mid-launch, where it would read as a kick.
const JUMP_BOOST_LEAD := 2.0
const ROUGH_UNTIL := 0.55 ## Rough canyon stone before here, smoother build after.

const ROUGH_FRICTION := 0.55
const SMOOTH_FRICTION := 0.25
## Warm sandstone, the rougher upper track. Pushed further from the smooth
## section than before: the two surfaces carry different friction, and with the
## banded shader flattening every gradient the colour step between them is now
## the only cue that the ground under a marble has changed.
const ROUGH_COLOUR := Color(0.74, 0.58, 0.42)
## Pale poured stone — the bone-coloured deck the Home screen art's viaduct is
## paved with. Was a near-neutral (0.48, 0.50, 0.54) two revisions ago; a colour
## that close to grey shows the sky's own blue rather than any tone of its own,
## the same problem `slope_course.gd`'s SURFACE_SMOOTH had.
const SMOOTH_COLOUR := Color(0.78, 0.72, 0.60)

## Marbles below this are out of bounds. Must stay clear of the finish, which
## is the lowest point of the course. Tunable, per the spec.
const FALL_THRESHOLD_Y := -60.0

# --- Canyon dressing (visual only) ---------------------------------------------
##
## Everything below is cosmetic. It follows the same ring frames the collision
## surface is built from, but never adds a StaticBody or a PhysicsMaterial — the
## marbles' world is exactly the swept ribbon above; this dresses the air around
## it in the Home screen's stylized Southwestern-canyon language (stacked
## red-rock strata, saguaro cacti, distant mesas, a vivid desert sky) so the
## placeholder trough reads as a canyon rather than a grey chute.

## Every Nth ring. Rings are `RING_SPACING` (0.35m) apart, which is far finer
## than dressing needs — striding keeps the extra mesh cheap over a course this
## long and gives the cliff face a slightly faceted, rock-like silhouette rather
## than a perfectly smooth one.
const DRESSING_RING_STEP := 6

## Bands rising from the collision wall's own top edge, stepping outward as they
## climb. The first point of each ring's dressing profile sits exactly on the
## existing wall top, so there is no seam between collidable and cosmetic rock.
##
## Each entry is now a *step*, not a ramp: the profile emits a vertical face of
## `height` and then a horizontal shelf of `outset`, where it used to emit one
## diagonal between tier tops. That diagonal is why the first pass read as
## smooth putty — the Home screen art's rock is built out of hard-edged
## rectangular blocks with a flat top to each shelf catching the sun, and a
## slope has no flat top to catch anything.
##
## Height stays modest and the outsets stay large, for the reason the two-tier
## version recorded: an early 10m near-vertical version turned the course into a
## slot with no sky over it. Four short steps that retreat 7m in total open the
## walls outward as they rise, which is the shape in the art.
const DRESSING_TIERS := [
	{"height": 1.0, "outset": 1.2, "colour": Color(0.46, 0.17, 0.12)},
	{"height": 1.2, "outset": 1.6, "colour": Color(0.66, 0.26, 0.14)},
	{"height": 1.3, "outset": 2.0, "colour": Color(0.80, 0.36, 0.17)},
	{"height": 1.2, "outset": 2.4, "colour": Color(0.88, 0.47, 0.24)},
]
const DRESSING_RIM_COLOUR := Color(0.92, 0.62, 0.36)
## How much a band's colour may drift from its base, so the strata are not flat
## ribbons. Deterministic, like slope_course.gd's `_weathered` — a restart must
## rebuild the same course.
const DRESSING_COLOUR_VARIANCE := 0.10

## Saguaro cacti perched along the canyon rim, alternating sides.
const CACTUS_SPACING := 9.0
const CACTUS_COLOUR := Color(0.26, 0.42, 0.27)

## Distant stepped buttes beyond the rim, the same silhouette the Home screen
## backdrop recedes into. Pushed much further out and made much taller than the
## first pass, where they sat 9-16m away and 12m high: at that size they were
## indistinguishable from the canyon wall directly behind them and simply read
## as more wall. The art's buttes are separated from the near rock by a visible
## gulf of hazy air, and only distance produces that.
const MESA_SPACING := 30.0
const MESA_COLOUR := Color(0.62, 0.28, 0.18)
const MESA_RIM_COLOUR := Color(0.84, 0.50, 0.28)

# --- Painted look --------------------------------------------------------------

## Everything in this course draws through one banded shader. See its own header
## for why: the art is painted, and a smooth lambert gradient reads as plastic
## no matter how the albedo is tuned.
const ROCK_SHADER: Shader = preload("res://scripts/course/canyon_rock.gdshader")

## Paving joints across the deck, in metres. The art's viaduct is laid in slabs
## roughly a marble-and-a-half wide, and the lines between them are most of what
## makes it read as a built road rather than a poured ribbon — they also give
## speed something to register against, which a featureless surface does not.
const SLAB_SPACING := 2.4
const SLAB_JOINT_COLOUR := Color(0.44, 0.33, 0.25)

## Timber kerb capping the track walls, as in the art, where a dark beam runs the
## length of the deck and separates the pale paving from the drop. Visual only:
## it sits outside the collision wall rather than inside it, so nothing a marble
## can touch changes.
const KERB_COLOUR := Color(0.34, 0.22, 0.15)
const KERB_HEIGHT := 0.45
const KERB_WIDTH := 0.4
## The viaduct's own flank, below the kerb. Warm stone rather than timber: the
## skirt is nearly three metres tall (wall top down past the deck underside), and
## at that size the timber colour stopped reading as a beam and became a
## chocolate wall running the length of the course, dark enough to pull the eye
## off the track it was meant to frame. Only a thin band of that dark is wanted,
## and the geometry here is not thin.
const SKIRT_COLOUR := Color(0.64, 0.47, 0.34)

# --- Viaduct -------------------------------------------------------------------
##
## Stretches where the canyon wall pulls away and the track crosses open air on
## arched piers, as it does on the right-hand side of the Home screen art.
##
## This is the one thing in that image the course could not say at all. The
## dressing walls used to run unbroken from start to finish, so the track was
## always a trench cut through rock; the art's track is a *structure* standing in
## a landscape, and you cannot read it as one while its edges are welded to the
## cliff for the whole run. Two stretches rather than the whole course, because
## the art has both — enclosed canyon on one side, open span on the other — and
## alternating between them is what makes either one legible.
##
## Ranges are course ratios. The second deliberately contains the river gap
## (`JUMP_GAP_RANGE`) and the bumper: the jump is the moment the floor is already
## gone, so it is the moment where being able to see what is underneath pays.
const VIADUCT_RANGES := [
	Vector2(0.28, 0.45),
	Vector2(0.72, 0.96),
]
## How far the canyon floor sits below the track through a viaduct stretch. Deep
## enough that the piers read as tall, shallow enough that the floor stays inside
## the frame from the race camera rather than falling out of the bottom of it.
const VIADUCT_DROP := 15.0
## Along-course spacing of the piers. Each pier carries an arch to its
## neighbour, so this is also the arch span.
const PIER_SPACING := 11.0
const PIER_WIDTH := 1.7
const PIER_COLOUR := Color(0.80, 0.72, 0.58)
## Segments per arch. Six is enough that the span reads as a curve at the
## distance the camera ever sees it from, and it stays a handful of boxes rather
## than a mesh.
const ARCH_SEGMENTS := 6
const ARCH_RISE := 3.2
const ARCH_THICKNESS := 0.55
## The canyon floor far below the spans — dry riverbed, not shadow. The void it
## replaces is what made the first viaduct sketch read as a hole in the world.
const CANYON_FLOOR_COLOUR := Color(0.52, 0.28, 0.20)
const CANYON_FLOOR_WIDTH := 130.0

# --- Light ---------------------------------------------------------------------

## The desert sky in the art is deeper and less hazy than the pool's shared one,
## and — the part that matters most — its shadows are warm. See
## `decorate_environment`.
const SKY_TOP := Color(0.16, 0.38, 0.72)
const SKY_HORIZON := Color(0.72, 0.66, 0.58)
const AMBIENT_COLOUR := Color(0.88, 0.62, 0.52)
const AMBIENT_ENERGY := 0.42
const SUN_COLOUR := Color(1.0, 0.93, 0.80)
const FOG_COLOUR := Color(0.86, 0.55, 0.36)
const FOG_DENSITY := 0.0026

## A river crossing the gap. The first attempt was a flat plane far below —
## still read as a square hole with a blue floor, because there was 16m of
## unlit empty air between the floor's cut edge and the water with nothing
## bridging them. This version instead slopes the floor edge down into the
## water on both sides, close enough that the gap reads as a crossing rather
## than a shaft.
##
## No longer visual-only: it used to be safe to skip collision because a
## marble that reached it was already eliminated by the global
## `fall_threshold_y` long before falling this far — the water sat only
## `RIVER_BED_DEPTH` below the local floor, but the course descends so much
## between here and the finish (which has to stay above the one fixed
## threshold that applies everywhere) that a marble fell the better part of
## 30m through empty space before that threshold ever caught it. Real
## collision plus `in_water` (below) replaces that: a marble that misses the
## jump now visibly lands in the water and is caught there — see race_manager
## `_check_for_falls` — rather than free-falling well past it.
## Raised from 1.8 to 1.0 alongside that — the point wasn't ever really "how
## deep is the river", it was "how far below the floor a marble had to fall
## before anything happened", and that distance reads better close.
##
## This is the *bed*, not the water line. They used to be the same number, and
## that made "raise the water" a change with no visible effect: the banks
## sloped from the floor down to exactly this depth and the water surface sat
## at exactly this depth too, so the waterline always landed on the bank's
## bottom edge and the strip of visible water was the same width no matter
## what the depth was. Bed and level are separate now — see `RIVER_LEVEL`.
const RIVER_BED_DEPTH := 1.0
## Where the water surface sits, below the floor. Smaller is higher water.
##
## Because the banks slope, this is what actually decides how wide the river
## reads from above: the waterline is wherever the bank has descended this
## far, so raising the level walks the edges up the slopes and floods more of
## the gap. At the old bed-locked value the river was a ribbon covering about
## a sixth of the gap; at 0.35 it covers most of it and the banks read as
## banks rather than as the whole crossing.
const RIVER_LEVEL := 0.35
## Fraction of the gap's own length each bank consumes sloping from the floor
## down to `RIVER_BED_DEPTH`. Symmetric, so the two banks always leave *some*
## bed between them regardless of how long the gap ends up.
## Raised from 0.38 alongside the shallower bed so the slope actually faces
## the sun rather than its own shadow.
const RIVER_BANK_FRACTION := 0.42
## Sunlit wet sand, not shadowed mud — the first attempt at this colour was
## dark enough that ambient-only light rendered it almost black, which read as
## exactly the void this bank exists to get rid of.
const RIVER_BANK_COLOUR := Color(0.58, 0.44, 0.30)
const WATER_SHADER: Shader = preload("res://scripts/course/water.gdshader")
## How far a position may be above the water's own local surface height and
## still count as "in the water" for `in_water` — enough that the countdown
## starts the moment a marble visibly breaks the surface rather than only once
## it has come fully to rest.
##
## Tied to `RIVER_LEVEL`, not independent of it: margin and level are added
## together in `in_water`, so the old 1.0 against the old depth of 1.0 put the
## trigger exactly at floor height. At the raised water line a fixed 1.0 would
## put it *above* the floor, and a marble arcing low but cleanly across the gap
## would be eliminated in mid-air. Keeping it equal to the level pins the
## trigger back at floor height, which is still well clear of the surface a
## marble comes to rest at on the bed.
const WATER_CONTACT_MARGIN := RIVER_LEVEL
## How far the river's collider reaches past the gap's own edges, flush with
## the floor there — closes the seam against `_build_surface`'s ribbon. Same
## idea, same size, as `JungleCourse.RUN_OVERLAP`.
const RIVER_OVERLAP := 0.4

var _length := 0.0
var _race_start_offset := 0.0
var _race_length := 0.0
## Where the finish line sits along `curve`, and how much curve is left after it.
var _finish_offset := 0.0
var _runoff_length := 0.0
var _rings: Array[Dictionary] = []
## The waterline span — where the sloping banks meet `RIVER_LEVEL` — as
## along-course offsets. Drawing only: wider than the flat bed below it,
## because the water climbs part-way up both banks.
var _water_start_offset := 0.0
var _water_end_offset := 0.0
## The flat bed between the two bank slopes. Collision geometry, and the span
## `in_water` eliminates within — see that function for why elimination stays
## on the bed rather than following the wider waterline.
var _bed_start_offset := 0.0
var _bed_end_offset := 0.0


func build() -> void:
	_build_curve()

	_race_start_offset = curve.get_closest_offset(RACE_START_POINT)
	# The curve now runs past the finish (see `FINISH_POINT_INDEX`), so the race
	# is the stretch up to the finish point and the rest is runoff. `_race_length`
	# is what every ratio in this file is measured against; it must not pick up
	# the runoff, or the whole course slides up-track.
	_finish_offset = curve.get_closest_offset(CONTROL_POINTS[FINISH_POINT_INDEX])
	_race_length = _finish_offset - _race_start_offset
	_runoff_length = _length - _finish_offset
	start_transform = _frame_at(_race_start_offset)
	finish_position = curve.sample_baked(_finish_offset)

	_sample_rings()

	# Split into two bodies so the rough and smooth sections can carry
	# different friction: one body can only hold one physics material.
	var boundary := _ring_index_for_ratio(ROUGH_UNTIL)
	_build_surface(0, boundary, ROUGH_FRICTION, ROUGH_COLOUR)
	_build_surface(boundary, _rings.size() - 1, SMOOTH_FRICTION, SMOOTH_COLOUR)

	_add_back_wall()
	_add_runoff_backstop()
	_add_split_divider()
	_add_jump_ramp()
	_add_jump_boost()
	_add_bumper()
	_add_river()

	_build_deck_skirt()
	_build_viaduct()
	_build_canyon_dressing()
	_build_mesas()
	_build_cacti()


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


## `Course.frame_at` in terms of the banked frame the whole course is swept from,
## so a marker placed through the seam sits on the same camber the floor has.
func frame_at(offset: float) -> Transform3D:
	return _frame_at(offset)


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
			var u_here := float(i) * RING_SPACING
			var u_ahead := float(i + 1) * RING_SPACING
			_add_quad_uv(
				tool,
				here[strip], here[strip + 1], ahead[strip + 1], ahead[strip],
				u_here, u_ahead, float(strip)
			)

	tool.generate_normals()
	var mesh := tool.commit()

	# Slab joints run across the deck; see `SLAB_SPACING`. The walls and fillets
	# get them too, which is right — the art paves the kerb line as well, and a
	# joint that stops dead at the wall foot would draw attention to the seam.
	var material := _rock_material(colour, SLAB_SPACING)

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


## As `_add_quad`, but carrying the along-course distance the banded shader
## needs to place slab joints. `u` is metres down the course and `v` is the
## strip index across the profile — only `u` is read, but a UV with a constant
## second channel would collapse the whole deck onto one texture line if
## anything ever samples it properly.
func _add_quad_uv(
	tool: SurfaceTool,
	a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	u_near: float, u_far: float, v: float
) -> void:
	var uvs := [
		Vector2(u_near, v), Vector2(u_near, v + 1.0),
		Vector2(u_far, v + 1.0), Vector2(u_near, v),
		Vector2(u_far, v + 1.0), Vector2(u_far, v),
	]
	var points := [a, b, c, a, c, d]
	for i in points.size():
		tool.set_uv(uvs[i])
		tool.add_vertex(points[i])


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


## Closes the far end of the runoff.
##
## Not the old six-metres-past-the-line wall in a new place: by the time a marble
## reaches this, thirty metres of ramped damping have already taken almost all of
## its speed, so it is a kerb that stops a slow roll rather than the thing that
## ends a race. It exists at all because the ribbon has to end somewhere and a
## marble that rolls off it registers as having left the world.
##
## Low, at three-quarters of a marble's height above the deck, so it does not
## stand up in front of the finished field the camera is looking at.
const RUNOFF_KERB_HEIGHT := 0.7

func _add_runoff_backstop() -> void:
	var frame := _frame_at(_length - 0.6)
	var half_width := _width_at((_length - _race_start_offset) / _race_length)
	_add_box(
		frame.translated_local(Vector3(0.0, RUNOFF_KERB_HEIGHT * 0.5, 0.0)),
		Vector3(half_width * 2.2, RUNOFF_KERB_HEIGHT, 0.5),
		SMOOTH_COLOUR.darkened(0.35),
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


## The speed floor on the run-in to the jump, spanning the full trough width so
## no line through the funnel misses it. See `JUMP_BOOST_SPEED`.
##
## Unmarked, unlike every other course's boost. `BoostPad` shows itself by
## default so a speed change is never invisible to the player, and that is the
## right default — but here the take-off already has a visible ramp, and a
## second glowing slab immediately in front of it read as another obstacle to
## get past rather than as help. The ramp is the thing the player sees and the
## thing they credit the jump to; the floor underneath it stays quiet.
func _add_jump_boost() -> void:
	var at := (
		_offset_for_ratio(JUMP_GAP_RANGE.x) - JUMP_RAMP_LENGTH - JUMP_BOOST_LEAD
	)
	var frame := _frame_at(at)
	var pad := BoostPad.create(
		_width_at(JUMP_GAP_RANGE.x) * 2.0, -frame.basis.z, JUMP_BOOST_SPEED, false
	)
	pad.transform = frame.translated_local(Vector3(0.0, 1.2, 0.0))
	add_child(pad)


func _add_bumper() -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _frame_at(_offset_for_ratio(BUMPER_AT))
	add_child(bumper)


## The riverbed is three pieces, all sharing the gap's own width so nothing
## steps in from the walls: a bank sloping down from the takeoff floor, a flat
## bed in the middle, and a bank sloping back up to the landing floor. Both
## banks slope from y=0 (flush with the floor they grow out of, so there is no
## seam) down to -RIVER_BED_DEPTH at their own share of the gap.
##
## The water is a fourth, separate quad laid across that bed at -RIVER_LEVEL.
## It is *wider* than the bed: the banks are ramps, so a surface held above
## their bottom edge meets them part-way up, and the waterline sits at
## whatever fraction of each bank run has descended to `RIVER_LEVEL`. That is
## the whole reason level and bed are two numbers — see `RIVER_LEVEL`.
##
## Real collision (see `_add_river_collision`), so a marble that misses the
## jump lands in the gap rather than falling through it — `in_water` below is
## what turns landing there into an elimination. Collision follows the bed,
## not the water: the terrain is what a marble rests on, and the water surface
## is drawn over it.
func _add_river() -> void:
	var gap_start := _offset_for_ratio(JUMP_GAP_RANGE.x)
	var gap_end := _offset_for_ratio(JUMP_GAP_RANGE.y)
	var bank_run := (gap_end - gap_start) * RIVER_BANK_FRACTION
	_bed_start_offset = gap_start + bank_run
	_bed_end_offset = gap_end - bank_run

	# How far along each bank the waterline sits. Clamped because a level at or
	# below the bed would otherwise push the two waterlines past each other and
	# invert the water quad.
	var flood := clampf(RIVER_LEVEL / RIVER_BED_DEPTH, 0.0, 1.0)
	_water_start_offset = gap_start + bank_run * flood
	_water_end_offset = gap_end - bank_run * flood

	_add_river_collision(gap_start, gap_end)

	_add_river_visual(gap_start, _bed_start_offset, 0.0, -RIVER_BED_DEPTH, RIVER_BANK_COLOUR, false)
	_add_river_visual(gap_end, _bed_end_offset, 0.0, -RIVER_BED_DEPTH, RIVER_BANK_COLOUR, false)
	_add_river_visual(
		_water_start_offset, _water_end_offset, -RIVER_LEVEL, -RIVER_LEVEL, Color.WHITE, true
	)


## Four quads (bank, water, bank, ordered start to end, plus the two overlap
## slivers below) baked into *one* `ConcavePolygonShape3D` rather than one
## body per piece. `JungleCourse._runs`'s own comment already found this the
## hard way: "two trimeshes sharing an edge have no thickness between them,
## and a marble arriving at the join goes through it" — three separate river
## bodies meeting at bare edges tunnelled a marble clean through into an
## unbounded fall the first time this was tried.
##
## The two outer quads run `RIVER_OVERLAP` past `gap_start`/`gap_end` at
## y=0 — flush with, and overlapping into, `_build_surface`'s own floor,
## which already stops slightly before the gap (`_in_range` skips the ring
## exactly at the gap's edge). Same fix, same reasoning, for the same
## failure mode: `JungleCourse`'s `RUN_OVERLAP`.
func _add_river_collision(gap_start: float, gap_end: float) -> void:
	var faces := PackedVector3Array()
	faces.append_array(_river_quad(gap_start - RIVER_OVERLAP, gap_start, 0.0, 0.0))
	faces.append_array(_river_quad(gap_start, _bed_start_offset, 0.0, -RIVER_BED_DEPTH))
	faces.append_array(
		_river_quad(_bed_start_offset, _bed_end_offset, -RIVER_BED_DEPTH, -RIVER_BED_DEPTH)
	)
	faces.append_array(_river_quad(_bed_end_offset, gap_end, -RIVER_BED_DEPTH, 0.0))
	faces.append_array(_river_quad(gap_end, gap_end + RIVER_OVERLAP, 0.0, 0.0))

	var body := StaticBody3D.new()
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = SMOOTH_FRICTION
	# Water absorbs a fall rather than bouncing it — a marble that lands here
	# should visibly settle, not carry on bouncing across the surface.
	physics_material.bounce = 0.0
	body.physics_material_override = physics_material

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


## The two triangles of a quad between two along-course offsets, each end at
## its own height and spanning the full floor width there — so it reads (and
## collides) as growing straight out of the ribbon rather than as an inset
## shape floating inside the gap.
func _river_quad(
	from_offset: float, to_offset: float, from_y: float, to_y: float
) -> PackedVector3Array:
	var from_frame := _frame_at(from_offset)
	var to_frame := _frame_at(to_offset)
	var from_half_width := _width_at((from_offset - _race_start_offset) / _race_length)
	var to_half_width := _width_at((to_offset - _race_start_offset) / _race_length)

	var a: Vector3 = from_frame * Vector3(-from_half_width, from_y, 0.0)
	var b: Vector3 = from_frame * Vector3(from_half_width, from_y, 0.0)
	var c: Vector3 = to_frame * Vector3(to_half_width, to_y, 0.0)
	var d: Vector3 = to_frame * Vector3(-to_half_width, to_y, 0.0)
	return PackedVector3Array([a, b, c, a, c, d])


## Visual twin of one `_river_quad`, kept separate per piece (unlike
## collision) so the sand banks and the water can carry different materials.
func _add_river_visual(
	from_offset: float, to_offset: float, from_y: float, to_y: float, colour: Color, is_water: bool
) -> void:
	var points := _river_quad(from_offset, to_offset, from_y, to_y)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in points:
		tool.add_vertex(point)
	tool.generate_normals()

	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if is_water:
		# Unlike the rest of the canyon's matte rock (see `_dressing_material`),
		# water gets its own shader — a moving surface is what actually reads
		# as liquid rather than another tinted, static rock band at the bottom
		# of the gap.
		var shader_material := ShaderMaterial.new()
		shader_material.shader = WATER_SHADER
		visual.material_override = shader_material
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = colour
		material.metallic = 0.0
		# A single quad's winding can face either way depending on which end
		# is "from" and which is "to" — drawing both sides is simpler than
		# getting that right, and costs nothing on four small triangles.
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 1.0
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		visual.material_override = material

	add_child(visual)


# --- Canyon dressing (visual only) ---------------------------------------------


func _build_canyon_dressing() -> void:
	for side: float in [-1.0, 1.0]:
		_build_dressing_side(side)


func _build_dressing_side(side: float) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var i := 0
	while i < _rings.size() - 1:
		var next_i := mini(i + DRESSING_RING_STEP, _rings.size() - 1)
		# Where the course is a viaduct the canyon wall is not there at all, so
		# the strata simply stop. The cut end reads as the gorge opening out,
		# which is what it is; the collision walls carry on regardless, so the
		# track keeps its edges across the span.
		if not _in_viaduct(_rings[i]["ratio"]) and not _in_viaduct(_rings[next_i]["ratio"]):
			var here := _dressing_profile(_rings[i], i, side)
			var ahead := _dressing_profile(_rings[next_i], next_i, side)
			for band in here.size() - 1:
				_add_dressing_quad(
					tool, band, here[band], here[band + 1], ahead[band + 1], ahead[band]
				)
		i = next_i

	tool.generate_normals()
	var mesh := tool.commit()

	# White tint: the strata carry their colour per-vertex, and the shader
	# multiplies the two.
	var material := _rock_material(Color.WHITE)

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	# The whole point of the original 2.4m wall height was staying short enough
	# not to shadow the track (`_setup_environment`'s ambient-light comment).
	# This dressing rises to ~10m specifically to read as canyon walls from the
	# low camera, so it would re-introduce that problem for real if it cast
	# shadows — it does not need to, since it is backdrop, not a light-blocker.
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)


## Points (with per-vertex colour) running from the collision wall's own top
## rim outward and upward through `DRESSING_TIERS`, ending in a sun-bleached cap.
func _dressing_profile(ring: Dictionary, index: int, side: float) -> Array:
	var frame: Transform3D = ring["frame"]
	var half_width: float = ring["half_width"]
	var flat := half_width * FLAT_FRACTION
	var rise := half_width - flat + WALL_LEAN
	var top_out := flat + rise

	var out := top_out
	var height := WALL_HEIGHT
	var points := [{
		"pos": frame * Vector3(side * out, height, 0.0),
		"colour": _dressing_weathered(DRESSING_TIERS[0]["colour"], index),
	}]

	for t in DRESSING_TIERS.size():
		var tier: Dictionary = DRESSING_TIERS[t]
		out += float(tier["outset"])
		height += float(tier["height"])
		points.append({
			"pos": frame * Vector3(side * out, height, 0.0),
			"colour": _dressing_weathered(tier["colour"], index + t * 13),
		})

	points.append({
		"pos": frame * Vector3(side * out, height + 0.4, 0.0),
		"colour": DRESSING_RIM_COLOUR,
	})
	return points


func _dressing_weathered(base: Color, index: int) -> Color:
	var noise := fmod(sin(float(index) * 12.9898) * 43758.5453, 1.0)
	return base.lightened(absf(noise) * DRESSING_COLOUR_VARIANCE)


## One band of the cliff face.
##
## `band` becomes the smooth group, which is what gives the strata their edges:
## a vertical face and the shelf above it are different bands, so their normals
## are never averaged together and the step between them stays hard — while
## along the course, within one band, normals still blend and the wall reads as
## continuous rock rather than as a run of separate facets. A single flat group
## for the whole mesh did the first half and not the second, and turned the
## walls into a field of visibly distinct triangles.
func _add_dressing_quad(
	tool: SurfaceTool, band: int, a: Dictionary, b: Dictionary, c: Dictionary, d: Dictionary
) -> void:
	tool.set_smooth_group(band)
	for point: Dictionary in [a, b, c, a, c, d]:
		tool.set_color(point["colour"])
		tool.add_vertex(point["pos"])
# --- Viaduct ------------------------------------------------------------------


func _in_viaduct(ratio: float) -> bool:
	for span: Vector2 in VIADUCT_RANGES:
		if _in_range(ratio, span):
			return true
	return false


## Gives the track a visible thickness: an outer face down each side and a floor
## underneath, closing the swept ribbon into a slab.
##
## The collision surface is a bare trough, open on the outside, so before this
## the track had no underside at all — from the race camera it was a ribbon of
## zero thickness with the world showing through beneath its own edge. That is
## survivable when the ribbon is buried in rock for its whole length, and not at
## all survivable once `VIADUCT_RANGES` lifts stretches of it into open air,
## where the underside is exactly what the eye goes to.
##
## Visual only, and outside the collision surface in every direction, so nothing
## a marble can reach moves.
const DECK_THICKNESS := 0.55


func _build_deck_skirt() -> void:
	# Two ribbons, not one. The dark beam the art runs along the deck edge is a
	# narrow band right under the paving; the rest of the flank below it is
	# stone. Drawing the whole three-metre face in timber colour turned it into a
	# chocolate wall — see `SKIRT_COLOUR`.
	_add_skirt_ribbon(WALL_HEIGHT, WALL_HEIGHT - KERB_HEIGHT, KERB_COLOUR, false)
	_add_skirt_ribbon(WALL_HEIGHT - KERB_HEIGHT, -DECK_THICKNESS, SKIRT_COLOUR, true)


## One swept band down the outside of both track walls, optionally closed across
## the underside.
func _add_skirt_ribbon(y_top: float, y_bottom: float, colour: Color, floored: bool) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)

	for i in _rings.size() - 1:
		# The gap is meant to be a gap. Skirting it would floor the jump over.
		if _in_range(_rings[i]["ratio"], JUMP_GAP_RANGE):
			continue

		var here := _skirt_ring(_rings[i], y_top, y_bottom)
		var ahead := _skirt_ring(_rings[i + 1], y_top, y_bottom)
		var u_here := float(i) * RING_SPACING
		var u_ahead := float(i + 1) * RING_SPACING

		for edge in here.size() - 1:
			# Edge 1 is the underside. Only the lowest band closes it, so the
			# deck gets one bottom face rather than one per band.
			if edge == 1 and not floored:
				continue
			_add_quad_uv(
				tool,
				here[edge], here[edge + 1], ahead[edge + 1], ahead[edge],
				u_here, u_ahead, float(edge)
			)

	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _rock_material(colour, SLAB_SPACING)
	add_child(visual)


## Down the left outer face, across the underside, back up the right one. The
## middle edge is only drawn for the band that owns the underside — see the loop
## in `_add_skirt_ribbon`.
func _skirt_ring(ring: Dictionary, y_top: float, y_bottom: float) -> Array:
	var frame: Transform3D = ring["frame"]
	var half_width: float = ring["half_width"]
	var flat := half_width * FLAT_FRACTION
	var out := flat + (half_width - flat + WALL_LEAN) + KERB_WIDTH

	return [
		frame * Vector3(-out, y_top, 0.0),
		frame * Vector3(-out, y_bottom, 0.0),
		frame * Vector3(out, y_bottom, 0.0),
		frame * Vector3(out, y_top, 0.0),
	]
## Piers and arches under every `VIADUCT_RANGES` span, standing on a canyon floor
## far below.
func _build_viaduct() -> void:
	for span: Vector2 in VIADUCT_RANGES:
		_build_canyon_floor(span)

		var from_offset := _offset_for_ratio(span.x)
		var to_offset := _offset_for_ratio(span.y)
		# Piers land on a whole number of spacings so the arches between them are
		# all the same width; a remainder stretch at the end would give one arch
		# a span unlike every other, and an arcade reads as an arcade because it
		# repeats.
		var span_length := to_offset - from_offset
		var bays := maxi(int(span_length / PIER_SPACING), 1)
		var bay_length := span_length / float(bays)

		var previous := Vector3.ZERO
		var have_previous := false
		for bay in bays + 1:
			var at := from_offset + float(bay) * bay_length
			var top := _pier_top(at)
			_add_pier(top)
			if have_previous:
				_add_arch(previous, top)
			previous = top
			have_previous = true


## Where a pier meets the deck: clear of the track's own underside, on the
## centreline, in world space. Piers are vertical in the world however the deck
## above them is banked — a leaning pier reads as a mistake, not as camber.
##
## The clearance is what that verticality costs. A crown sitting only
## `DECK_THICKNESS` under the centreline is under the *centre* of the deck and
## not under its edges, and where the course banks hard the outer edge drops
## below that plane — the crown then surfaces through the paving as a bright
## wedge lying across the track, which is exactly what the first render showed.
const PIER_CLEARANCE := 0.6


func _pier_top(offset: float) -> Vector3:
	var here := curve.sample_baked(clampf(offset, 0.0, _length))
	return here - Vector3(0.0, DECK_THICKNESS + PIER_CLEARANCE, 0.0)


func _add_pier(top: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(PIER_WIDTH, VIADUCT_DROP, PIER_WIDTH)

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _dressing_material(PIER_COLOUR)
	visual.position = top - Vector3(0.0, VIADUCT_DROP * 0.5, 0.0)
	add_child(visual)


## A round arch between two pier tops, as a short chain of boxes.
##
## Springs from `ARCH_RISE` below the deck at each pier and crowns just under it
## at mid-span, which is the way round an arch actually works: the piers carry
## the load down and the arch closes the gap between them beneath the road.
## Boxes rather than a swept mesh because at the distance the race camera ever
## sees this from, six of them are indistinguishable from a curve.
func _add_arch(from_top: Vector3, to_top: Vector3) -> void:
	var material := _dressing_material(PIER_COLOUR.darkened(0.08))
	var span := to_top - from_top
	if span.length() < 0.01:
		return

	for segment in ARCH_SEGMENTS:
		var a := _arch_point(from_top, span, float(segment) / float(ARCH_SEGMENTS))
		var b := _arch_point(from_top, span, float(segment + 1) / float(ARCH_SEGMENTS))
		var middle := (a + b) * 0.5
		var chord := b - a

		var mesh := BoxMesh.new()
		# Slightly long, so consecutive segments overlap rather than leaving a
		# hairline gap at every joint in the curve.
		mesh.size = Vector3(ARCH_THICKNESS, ARCH_THICKNESS, chord.length() * 1.15)

		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = material
		visual.position = middle
		visual.look_at_from_position(middle, middle + chord, Vector3.UP)
		add_child(visual)


func _arch_point(from_top: Vector3, span: Vector3, t: float) -> Vector3:
	var along := from_top + span * t
	# Full drop at the springing, none at the crown.
	return along - Vector3(0.0, ARCH_RISE * (1.0 - sin(PI * t)), 0.0)


## The dry canyon floor the piers stand on. Follows the course rather than being
## one flat plane, because the course descends 30-odd metres and a level floor
## would surface through the track before the span ended.
func _build_canyon_floor(span: Vector2) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var from_offset := _offset_for_ratio(span.x) - 8.0
	var to_offset := _offset_for_ratio(span.y) + 8.0
	var steps := maxi(int((to_offset - from_offset) / 4.0), 2)

	for step in steps:
		var a := from_offset + (to_offset - from_offset) * float(step) / float(steps)
		var b := from_offset + (to_offset - from_offset) * float(step + 1) / float(steps)
		var here := _floor_edges(a)
		var ahead := _floor_edges(b)
		_add_quad_uv(tool, here[0], here[1], ahead[1], ahead[0], a, b, 0.0)

	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _dressing_material(CANYON_FLOOR_COLOUR)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)


func _floor_edges(offset: float) -> Array:
	var here := curve.sample_baked(clampf(offset, 0.0, _length))
	var forward := _tangent_at(offset)
	var across := forward.cross(Vector3.UP).normalized()
	if across.is_zero_approx():
		across = Vector3.RIGHT
	var down := here - Vector3(0.0, VIADUCT_DROP, 0.0)
	return [
		down - across * (CANYON_FLOOR_WIDTH * 0.5),
		down + across * (CANYON_FLOOR_WIDTH * 0.5),
	]






## Distant stepped buttes beyond the rim — the Home screen backdrop's receding
## red-rock towers, rebuilt as a few stacked boxes per marker.
func _build_mesas() -> void:
	var placed := 0.0
	var index := 0
	while placed < _length:
		placed += MESA_SPACING
		index += 1
		var side := 1.0 if index % 2 == 0 else -1.0
		var jitter := fmod(float(index) * 0.71, 1.0)
		# Was 9-16m, which put every butte *inside* the canyon wall: the dressing
		# now steps 7m outward from a half-width of up to 4.5m, so anything
		# closer than about 12m is buried in the cliff it is supposed to be seen
		# beyond. At 34-70m they sit across the gorge with air in front of them,
		# which with `FOG_DENSITY` is what makes them read as distant.
		var distance := 34.0 + jitter * 36.0
		var here := curve.sample_baked(clampf(placed, 0.0, _length))
		var forward := _tangent_at(placed)
		var across := forward.cross(Vector3.UP).normalized()
		if across.is_zero_approx():
			across = Vector3.RIGHT
		# World-vertical, not frame-local. Placing these through `_frame_at`
		# leaned them with the track's banking, and a leaning butte reads as a
		# bug rather than as camber.
		var base := here + across * (side * distance) - Vector3(0.0, 9.0, 0.0)
		_add_mesa(Transform3D(Basis.IDENTITY, base), index)


func _add_mesa(base_transform: Transform3D, index: int) -> void:
	var height := 0.0
	# Scaled up with the distance. At the old 3-5m across and 12m tall, a butte
	# 50m away is a pebble on the horizon; the art's towers subtend a good part
	# of the sky.
	var width := 9.0 + fmod(float(index) * 0.53, 6.0)

	for t in 3:
		var tier_height := (11.0 - float(t) * 2.4) + fmod(float(index + t) * 0.37, 3.5)
		var tier_width := width * (1.0 - float(t) * 0.22)
		var colour := MESA_COLOUR.lightened(float(t) * 0.12 + fmod(float(index) * 0.05, 0.08))

		var mesh := BoxMesh.new()
		mesh.size = Vector3(tier_width, tier_height, tier_width)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _dressing_material(colour)
		visual.transform = base_transform.translated_local(Vector3(0.0, height + tier_height * 0.5, 0.0))
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(visual)

		height += tier_height

	var cap := BoxMesh.new()
	cap.size = Vector3(width * 0.5, 0.5, width * 0.5)
	var cap_visual := MeshInstance3D.new()
	cap_visual.mesh = cap
	cap_visual.material_override = _dressing_material(MESA_RIM_COLOUR)
	cap_visual.transform = base_transform.translated_local(Vector3(0.0, height + 0.25, 0.0))
	cap_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cap_visual)


## Saguaro cacti perched on the canyon rim. Alternating sides, some with one
## arm, a few with two — enough variety that a run down the course doesn't read
## as one prop copy-pasted.
func _build_cacti() -> void:
	var placed := 0.0
	var index := 0
	while placed < _length:
		placed += CACTUS_SPACING
		index += 1
		var side := 1.0 if index % 2 == 0 else -1.0

		var ratio := (placed - _race_start_offset) / _race_length

		# Nothing to perch on where the wall has pulled away for a span.
		if _in_viaduct(ratio):
			continue

		var half_width := _width_at(ratio)
		var flat := half_width * FLAT_FRACTION
		var rise := half_width - flat + WALL_LEAN
		var top_out := flat + rise
		var tier0: Dictionary = DRESSING_TIERS[0]

		var perch := _frame_at(placed).translated_local(Vector3(
			side * (top_out + float(tier0["outset"]) * 0.5),
			WALL_HEIGHT + float(tier0["height"]) * 0.25,
			0.0
		))
		_add_cactus(perch, index)


func _add_cactus(cactus_transform: Transform3D, index: int) -> void:
	var root := Node3D.new()
	root.transform = cactus_transform
	add_child(root)

	var material := _dressing_material(CACTUS_COLOUR.lightened(fmod(float(index) * 0.13, 0.12)))
	var trunk_height := 1.8 + fmod(float(index) * 0.31, 1.2)
	_add_cactus_limb(root, trunk_height, 0.22, material)

	if index % 3 != 0:
		_add_cactus_arm(root, Vector3(0.28, trunk_height * 0.55, 0.0), trunk_height * 0.45, material)
	if index % 5 == 0:
		_add_cactus_arm(root, Vector3(-0.26, trunk_height * 0.4, 0.0), trunk_height * 0.35, material)


func _add_cactus_limb(root: Node3D, height: float, radius: float, material: ShaderMaterial) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position = Vector3(0.0, height * 0.5, 0.0)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(visual)


func _add_cactus_arm(root: Node3D, base: Vector3, height: float, material: ShaderMaterial) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.14
	mesh.bottom_radius = 0.16
	mesh.height = height
	mesh.radial_segments = 6
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	var lean := 0.35 * signf(base.x)
	visual.transform = Transform3D(
		Basis(Vector3.BACK, lean), base + Vector3(0.0, height * 0.5, 0.0)
	)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(visual)


## Every visible surface in the Canyon draws through `canyon_rock.gdshader`.
##
## `tint` multiplies the vertex colour, so the same material serves the strata
## (which carry per-vertex colour) and the flat props (which do not, and whose
## COLOR is white). `joint_spacing` of zero leaves rock unpaved.
func _rock_material(colour: Color, joint_spacing := 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ROCK_SHADER
	material.set_shader_parameter("tint", colour)
	material.set_shader_parameter("bands", 3)
	material.set_shader_parameter("joint_spacing", joint_spacing)
	material.set_shader_parameter("joint_tint", SLAB_JOINT_COLOUR)
	return material


## Kept as the name the mesas, cacti and props already call, now a thin wrapper.
## Rock is not plastic, which the shader enforces for every surface at once
## rather than three properties at a time — same reasoning as
## `slope_course.gd`'s `_material`, arrived at from the other direction.
func _dressing_material(colour: Color) -> ShaderMaterial:
	return _rock_material(colour)


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
	var material := _rock_material(colour)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)

	add_child(body)




# --- Light --------------------------------------------------------------------


## The Canyon's own desert light, over the pool's shared neutral sky.
##
## Three departures, and the middle one is the whole point:
##
## The sky goes deeper and less hazy at the top, which is what the art has above
## the buttes and what makes the rock read as saturated rather than dusty.
##
## Ambient becomes a warm orange *colour* rather than the sky's own average. In
## the art nothing in shadow is grey — a shadowed face is deep red-brown,
## because the only thing lighting it is bounce off several hundred metres of
## sunlit orange rock. Sky-sourced ambient gives the opposite: it fills shadow
## with the blue overhead, and no amount of albedo tuning recovers from that,
## because a shadowed surface shows ambient and nothing else. `canyon_rock.gdshader`
## deliberately does not try to solve this itself for the same reason.
##
## Fog, thin and orange, so the buttes recede. Distance in that art is carried
## almost entirely by haze rather than by size, and without it the far towers
## sit in the same plane as the near wall however far away they are.
func decorate_environment(environment: Environment, sun: DirectionalLight3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_bottom_color = Color(0.30, 0.14, 0.10)
	sky_material.ground_horizon_color = SKY_HORIZON

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOUR
	# Slightly under the shared 0.95. The shared value was raised specifically to
	# keep marbles readable in wall shadow, and that requirement has not gone
	# away — but a coloured ambient at full strength washes the banding out,
	# and the bands are what make this course look like its own art. This is the
	# lowest setting at which a marble in the deepest wall shadow still reads.
	environment.ambient_light_energy = AMBIENT_ENERGY

	environment.fog_enabled = true
	environment.fog_light_color = FOG_COLOUR
	environment.fog_density = FOG_DENSITY
	# Sun-facing fog only would put the glow on one side of the course; the haze
	# in the art is even, because it is dust rather than scattering.
	environment.fog_sun_scatter = 0.0

	sun.light_color = SUN_COLOUR

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


func finish_width() -> float:
	return _width_at(1.0) * 2.0


func finish_runoff() -> float:
	return _runoff_length


## The Canyon's own finish: a sandstone gateway with checkered markings, banners
## and blown dust. Built by a separate class rather than inline here, because the
## whole point of `Course.create_finish_visual` is that the next course swaps this
## line for its own and nothing else moves.
##
## Materials are handed over rather than rebuilt: everything in this course draws
## through the banded rock shader (see `ROCK_SHADER`), and a finish arch shaded by
## Godot's default lambert next to a canyon that is not would read as an asset
## dropped in from another game.
func create_finish_visual() -> Node3D:
	return CanyonFinish.create(
		_frame_at(_finish_offset),
		_width_at(1.0),
		_runoff_length,
		func(colour: Color) -> Material: return _rock_material(colour)
	)


## True once `position` is at or below the river's own surface height, within
## `WATER_CONTACT_MARGIN` of the along-course span `_add_river` recorded.
## Position is checked in the water quad's own frame rather than world space
## because the course descends and turns — "at the water's height" only means
## anything measured against the frame at that point along it.
##
## Deliberately the *bed* span, not the wider waterline the player sees. The
## two used to be the same, and widening the visual water alone was enough to
## start eliminating marbles in mid-air: the height test sits at floor level,
## which a clean but low arc dips below near the far lip, and stretching the
## along-course window to the waterline put that whole arc inside it. Only 16
## of 96 crossed. Keeping elimination on the flat bed — the part a marble can
## actually come to rest in — leaves the check exactly as strict as it was
## before the water was raised, and is why raising it is a visual change only.
func in_water(position: Vector3) -> bool:
	var offset := curve.get_closest_offset(position)
	if offset < _bed_start_offset - 1.0 or offset > _bed_end_offset + 1.0:
		return false

	var clamped := clampf(offset, _bed_start_offset, _bed_end_offset)
	var frame := _frame_at(clamped)
	var half_width := _width_at((clamped - _race_start_offset) / _race_length)
	var local := frame.affine_inverse() * position
	if absf(local.x) > half_width + 0.5:
		return false

	return local.y < -RIVER_LEVEL + WATER_CONTACT_MARGIN


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
