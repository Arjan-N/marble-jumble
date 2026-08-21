class_name ChaseCamera
extends Camera3D

## Follows the player's marble with deliberate look-ahead.
##
## Two projections live here.
##
## `Mode.CHASE` is the one `DECISIONS.md` locks: landscape 2.5D, weak
## perspective, angled from behind the marble, course running away from the
## player. A narrow FOV from further back approximates weak perspective while
## keeping depth cues.
##
## `Mode.OVERHEAD` is a **spike**, not a decision. It is a steeply pitched,
## near-top-down portrait framing that looks back *up* the course, being measured
## against the locked camera on a real phone, because the locked one shows the
## player's marble and little else and the field is twelve marbles wide. Nothing
## in `DECISIONS.md` has changed.
## If the phone test does not clearly favour it, delete `Mode.OVERHEAD`, the
## constants tagged with it, the `C` binding in `race_manager.gd` and the
## portrait settings in `project.godot`; the locked camera is then back with no
## other trace. See `docs/CAMERA_SPIKE.md`.
##
## The class keeps its name through the spike deliberately — renaming it would
## touch `race_manager.gd` and the `.uid`, and make reverting a bigger edit than
## deleting the mode.
##
## Press **C** in a running build to cycle modes mid-race.

enum Mode { CHASE, OVERHEAD }

## What a fresh camera starts in. Set to `Mode.CHASE` to get the locked
## behaviour back without deleting anything.
const DEFAULT_MODE := Mode.OVERHEAD

const POSITION_SMOOTHING := 4.0
const AIM_SMOOTHING := 6.0

# --- Mode.CHASE (locked by DECISIONS.md) --------------------------------------

const LEAD_SECONDS := 3.5
const CHASE_DISTANCE := 14.0
const CHASE_HEIGHT := 6.5
const CHASE_FOV := 34.0

# --- Mode.OVERHEAD (spike) ----------------------------------------------------

## Pitch below the horizon. 90 degrees would be literally top-down, which
## flattens the course's descent into nothing and takes the depth cue that sells
## speed with it. This keeps enough obliquity that marbles and pillars stand up
## out of the surface rather than being seen down onto.
##
## It is no longer load-bearing the way it was when the camera faced down-course.
## Back then pitch was the only knob against a descent hidden along the view
## axis, and it was never going to be enough; now the descent runs towards the
## lens and pitch is a look, not a rescue. It also does not buy coverage — every
## degree it adds at one edge of the frame it takes from the other.
const OVERHEAD_PITCH := deg_to_rad(68.0)
## Further back behind a narrower lens than the chase camera. Same framing, less
## perspective divergence — which is what keeps the near-orthographic look the
## reference image has.
const OVERHEAD_DISTANCE := 34.0
## Horizontal FOV (see `set_mode`). At `OVERHEAD_DISTANCE` this spans roughly
## 13m across, against a widest-case track of ~9m of floor plus outward-leaning
## walls. The first render at 28 degrees spanned 17m and left the track using
## barely a third of a portrait frame.
##
## Since the camera turned to face up-course this is also the only knob that
## buys more course in shot, and the two uses pull against each other: 30 degrees
## covers ~30m of course instead of ~22m, at the price of the track no longer
## filling the frame edge to edge. See docs/CAMERA_SPIKE.md.
const OVERHEAD_FOV := 22.0
## How far up-course of the frame's centre the marble rides, in **metres, not
## seconds**. Because the rig looks back up the track, the course ahead of the
## marble is the ground between it and the lens — screen-down, not screen-up — so
## this constant is what decides how much of that is in shot. Metres rather than
## seconds-of-travel because the frame covers a fixed patch of ground: a
## speed-scaled lead does not widen the shot, it just slides the marble towards
## the top edge until it leaves. That mattered less at the old pace and matters a
## lot now gravity is at 30.
##
## Small, because the frame is smaller than it looks: it spans about 22m of
## course, ~11m either side of the focus. Facing down-course the same lens
## covered ~30m, since a slope falling away from the lens stretches the far
## ground out; facing up-course that slope rises to meet the ray instead and cuts
## the view short. 15m put the whole field off the top edge on the first render.
const OVERHEAD_LEAD := 5.0

var target: Marble
## Optional, and only `Mode.OVERHEAD` uses it. Without it that mode falls back
## to steering by the marble's own velocity, which is what the first render did
## and it swung the track diagonally across the frame.
var course: Course
var mode: Mode = DEFAULT_MODE

var _aim := Vector3.ZERO
var _initialised := false


static func create() -> ChaseCamera:
	var camera := ChaseCamera.new()
	camera.name = "ChaseCamera"
	camera.set_mode(DEFAULT_MODE)
	return camera


func _ready() -> void:
	current = true


## Snaps rather than sweeps. A smooth interpolation across the two positions
## looks better but is worse for the comparison the spike exists to make: you
## want both framings of the same instant, not a transition between them.
func set_mode(value: Mode) -> void:
	mode = value
	_initialised = false

	match mode:
		Mode.CHASE:
			keep_aspect = KEEP_HEIGHT
			fov = CHASE_FOV
		Mode.OVERHEAD:
			# Horizontal FOV is the binding constraint in portrait: the frame has
			# to hold the full track width. Under KEEP_HEIGHT the horizontal
			# angle narrows with the aspect ratio, and on a tall phone the walls
			# clip off both sides.
			keep_aspect = KEEP_WIDTH
			fov = OVERHEAD_FOV


func cycle_mode() -> void:
	set_mode(Mode.CHASE if mode == Mode.OVERHEAD else Mode.OVERHEAD)


func mode_name() -> String:
	return "chase" if mode == Mode.CHASE else "overhead"


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	var marble_position := target.global_position

	# Look-ahead is measured in seconds of course, so the camera opens up as
	# the marble gains speed and tightens when it slows.
	var travel := target.linear_velocity
	travel.y = 0.0

	# A stationary marble at the grid has no travel direction to lead from, so
	# fall back to the way the course runs.
	var direction := travel.normalized()
	if direction.is_zero_approx():
		direction = Vector3.FORWARD

	var aim: Vector3
	var desired: Vector3

	match mode:
		Mode.CHASE:
			aim = marble_position + travel * LEAD_SECONDS
			desired = marble_position - direction * CHASE_DISTANCE
			desired.y = maxf(marble_position.y, aim.y) + CHASE_HEIGHT
		Mode.OVERHEAD:
			# The focus rides the course centreline ahead of the marble, not the
			# marble itself. Two things fall out of that: the track sits centred
			# in a narrow portrait frame instead of wherever the player happens
			# to have drifted, and yaw comes from the course's own tangent rather
			# than from an instantaneous velocity that jitters every time the
			# marble is nudged. Aiming at the marble did both badly.
			var lead := _course_lead(marble_position)
			if lead.is_empty():
				aim = marble_position + direction * OVERHEAD_LEAD
			else:
				aim = lead["position"]
				direction = lead["tangent"]

			# `+=`, where a camera following from behind would use `-=`. That sign
			# is the whole difference: the rig sits *down*-course of its focus and
			# looks back up the track, so the field runs at the lens instead of
			# away from it, and the course's descent falls towards the viewer
			# instead of hiding along the view axis. Reading that gradient is the
			# question docs/CAMERA_SPIKE.md could not answer facing the other way.
			desired = aim
			desired += direction * (OVERHEAD_DISTANCE * cos(OVERHEAD_PITCH))
			desired.y += OVERHEAD_DISTANCE * sin(OVERHEAD_PITCH)

	if not _initialised:
		_initialised = true
		global_position = desired
		_aim = aim
	else:
		global_position = global_position.lerp(desired, 1.0 - exp(-POSITION_SMOOTHING * delta))
		_aim = _aim.lerp(aim, 1.0 - exp(-AIM_SMOOTHING * delta))

	look_at(_aim, Vector3.UP)


## Where on the course centreline to look, and which way it runs there, given
## where the marble is. Empty when there is no course to sample, which leaves the
## caller on its velocity-based fallback.
func _course_lead(from: Vector3) -> Dictionary:
	if course == null or not is_instance_valid(course) or course.curve == null:
		return {}

	var length := course.curve.get_baked_length()
	var offset := course.curve.get_closest_offset(from)
	var ahead := clampf(offset + OVERHEAD_LEAD, 0.0, length)

	# Sampled over a fixed baseline rather than between adjacent points, for the
	# same reason course_builder.gd measures banking that way: a short baseline
	# turns into noise.
	var behind_point := course.curve.sample_baked(maxf(ahead - 2.0, 0.0))
	var ahead_point := course.curve.sample_baked(minf(ahead + 2.0, length))

	var tangent := (ahead_point - behind_point)
	tangent.y = 0.0
	tangent = tangent.normalized()
	if tangent.is_zero_approx():
		tangent = Vector3.FORWARD

	return {"position": course.curve.sample_baked(ahead), "tangent": tangent}


func reset() -> void:
	_initialised = false
