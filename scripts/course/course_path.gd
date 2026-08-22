class_name CoursePath
extends RefCounted

## A course centreline that can descend, turn and bank.
##
## `SlopeCourse` bakes its own centreline by integrating a pitch profile, which
## is why it is straight in plan: pitch is the only thing it tracks, so there is
## nothing in it that could ever turn. That was the right shape for a course
## whose whole job was to be too simple to be the cause of anything. It is the
## wrong shape for a second course, and it is the reason the phase spec's "one
## gentle S-curve" has never been buildable.
##
## This is that logic generalised and lifted out: pitch *and* heading, with bank
## derived from how hard the heading is turning. Courses hand it profiles and ask
## it for points and frames; it knows nothing about floors, walls or obstacles.
##
## `SlopeCourse` has deliberately not been moved onto it yet. It works, it is
## tuned, and it has produced three marble traps in one day — migrating it is a
## change worth making on its own, where a regression has only one possible
## cause.
##
## ## Profiles
##
## Both are `[[fraction_along, value], ...]`, giving the value that holds *up to*
## that fraction, and both are smoothed by a box filter rather than used raw. A
## step in pitch is a crease across the floor; a step in heading is a corner. The
## smoothing window is what turns each into a ramp.
##
## - **pitch** is descent in degrees, positive downhill.
## - **heading** is absolute bearing in degrees, positive turning right. A course
##   that stays on 0 is straight, and behaves exactly as `SlopeCourse` does.
##
## ## Banking
##
## Not a profile, because a bank that disagrees with the corner it is in is worse
## than no bank at all. It is computed from the rate the heading is changing, so
## a course author draws a line and the camber follows it. `DECISIONS.md` allows
## curves to be naturally banked; this is what makes that automatic rather than a
## thing to remember.

## Metres between baked samples. The profiles are integrated rather than solved,
## because a smoothed heading has no tidy antiderivative.
const BAKE_STEP := 0.5

## Half-width of the smoothing window, in metres. Wider than a course segment on
## purpose: neighbouring segments should differ by well under a degree in both
## pitch and heading, or the joins between them become things marbles hit.
const BLEND := 7.0
## Taps in the box filter. Five is enough to turn a step into a visually smooth
## ramp at this window size, and each one costs a profile lookup per sample.
const TAPS := 5

## Degrees of bank per degree-per-metre of turn. Tuned so a corner turning at the
## rate this kind of course actually turns at — very roughly one degree per metre
## — comes out near the middle of the allowed range rather than pinned at it.
const BANK_GAIN := 6.0
## Bank is clamped because the camber is generated, not authored, and a profile
## with a sharp heading change would otherwise ask for a wall. Past this a marble
## on the low side is being held there by the track rather than by the corner.
const BANK_LIMIT_DEGREES := 26.0
## Bank is smoothed again after it is derived. It comes from a rate of change, so
## it carries whatever noise the heading profile has and amplifies it; a track
## whose camber flickers is worse than one with none.
const BANK_BLEND := 14.0

var length: float
var ramp: float
var runoff: float

var _pitch: Array = []
var _heading: Array = []
var _baked: PackedVector3Array = PackedVector3Array()


static func create(
	course_length: float, ramp_length: float, runoff_length: float,
	pitch_profile: Array, heading_profile: Array
) -> CoursePath:
	var path := CoursePath.new()
	path.length = course_length
	path.ramp = ramp_length
	path.runoff = runoff_length
	path._pitch = pitch_profile
	path._heading = heading_profile
	path._bake()
	return path


# --- Profiles -----------------------------------------------------------------


## Value of a `[[fraction, value], ...]` profile at distance `s`, unsmoothed.
## Distances before the start line and past the finish hold the first and last
## entries, so the starting ramp and the run-out are continuous with the course.
func _raw(profile: Array, s: float) -> float:
	if profile.is_empty():
		return 0.0

	var fraction := s / length
	for entry: Array in profile:
		if fraction <= entry[0]:
			return entry[1]
	return profile[profile.size() - 1][1]


## Smoothed profile value, in degrees.
func _smoothed(profile: Array, s: float, window: float) -> float:
	var total := 0.0
	for i in TAPS:
		var offset := (float(i) / float(TAPS - 1) - 0.5) * 2.0 * window
		total += _raw(profile, s + offset)
	return total / float(TAPS)


## Descent at `s`, in radians, positive downhill.
func pitch_at(s: float) -> float:
	return deg_to_rad(_smoothed(_pitch, s, BLEND))


## Bearing at `s`, in radians, positive turning right.
func heading_at(s: float) -> float:
	return deg_to_rad(_smoothed(_heading, s, BLEND))


## Camber at `s`, in radians, positive rolling the track's right side down —
## which is the way a marble is thrown in a right-hand corner, so a right turn
## banks into itself.
##
## Sampled over a baseline rather than between adjacent points: heading changes
## by fractions of a degree over half a metre, and dividing that by the step
## turns rounding into camber.
func bank_at(s: float) -> float:
	var baseline := 3.0
	var ahead := _smoothed(_heading, s + baseline, BANK_BLEND)
	var behind := _smoothed(_heading, s - baseline, BANK_BLEND)
	var rate := (ahead - behind) / (baseline * 2.0)
	return deg_to_rad(clampf(rate * BANK_GAIN, -BANK_LIMIT_DEGREES, BANK_LIMIT_DEGREES))


# --- Baking -------------------------------------------------------------------


func _bake() -> void:
	_baked = PackedVector3Array()

	var point := Vector3.ZERO
	var s := -ramp
	var last := length + runoff

	while s <= last + BAKE_STEP:
		_baked.append(point)
		point += _direction_at(s) * BAKE_STEP
		s += BAKE_STEP

	# Re-origin so the start line sits at (0, 0, 0). Everything a course places —
	# spawns, fall threshold, the camera — is written against that.
	var origin := point_at(0.0)
	for i in _baked.size():
		_baked[i] = _baked[i] - origin


## Unit vector the course runs in at `s`: down-course, descending, and turned.
func _direction_at(s: float) -> Vector3:
	var pitch := pitch_at(s)
	var heading := heading_at(s)
	var level := cos(pitch)
	return Vector3(sin(heading) * level, -sin(pitch), -cos(heading) * level)


func point_at(s: float) -> Vector3:
	if _baked.is_empty():
		return Vector3.ZERO

	var index := (s + ramp) / BAKE_STEP
	var low := int(floor(index))
	var last := _baked.size() - 1

	if low < 0:
		return _baked[0]
	if low >= last:
		return _baked[last]

	return _baked[low].lerp(_baked[low + 1], index - float(low))


## The frame every fixture on a course is placed through, so nothing has to know
## about the profiles. Local -Z runs down-course, local X is track-right and local
## Y is the surface normal — both rolled by the bank, so a fixture placed at a
## lateral offset in a banked corner sits on the camber rather than through it.
func frame_at(s: float) -> Transform3D:
	var forward := _direction_at(s)
	var heading := heading_at(s)

	# Track-right before banking: perpendicular to the direction of travel in
	# plan, so it stays horizontal on a straight regardless of pitch.
	var right := Vector3(cos(heading), 0.0, sin(heading))
	var up := right.cross(forward).normalized()

	var bank := bank_at(s)
	if not is_zero_approx(bank):
		var roll := Basis(forward, bank)
		right = roll * right
		up = roll * up

	return Transform3D(Basis(right, up, -forward), point_at(s))


## Sampled rather than given endpoints: the camera steers by this curve's
## tangent, and on a course that turns, a straight line between start and finish
## would point it at the wrong place for most of the race.
func to_curve(spacing: float = 4.0) -> Curve3D:
	var curve := Curve3D.new()
	var s := -ramp
	while s <= length + runoff:
		curve.add_point(point_at(s))
		s += spacing
	return curve
