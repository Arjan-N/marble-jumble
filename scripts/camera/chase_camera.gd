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

enum Mode { CHASE, OVERHEAD, LOW }

## What a fresh camera starts in. `Mode.LOW` is the approved gameplay camera —
## it shows more of the course than `Mode.OVERHEAD` at a shallower, less
## top-down angle. Set to `Mode.CHASE` to get the original locked behaviour
## back without deleting anything.
const DEFAULT_MODE := Mode.LOW

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
## Lowered from 68. On its own this buys almost no extra course — dropping the
## pitch at a fixed distance slides the rig backwards as it comes down, so the
## focus stays put and the up-course edge moves by centimetres. What it does buy
## is the look: a lower angle rakes along the canyon walls instead of peering
## down between them, so the trough has visible depth and the rock reads as
## something the marbles are running *through*.
const OVERHEAD_PITCH := deg_to_rad(61.0)
## Further back behind a narrower lens than the chase camera. Same framing, less
## perspective divergence — which is what keeps the near-orthographic look the
## reference image has.
const OVERHEAD_DISTANCE := 34.0
## How far back the rig is pulled when the marble is at racing speed.
##
## Nothing on screen conveyed speed. The marbles are simulated correctly at 5m/s
## and at 16, and they look the same at both — a top-down frame that tracks its
## subject perfectly cancels out the one thing it is supposed to be showing, and
## the surface stripes were carrying the entire sense of motion.
##
## Pulling back widens the shot, so the ground rushes past faster relative to the
## frame at exactly the moment the marble is going fastest. It also pays off
## criterion 4 where it counts: the ~22m of course this camera holds is short on
## look-ahead, and the frame grows precisely when the marble is covering ground
## quickly enough to need it.
##
## Kept to a fifth. Further and the marbles shrink past the point where
## `PROJECT.md` section 2.5 is satisfied, and the pull starts reading as the
## camera flinching rather than as speed.
const OVERHEAD_DISTANCE_FAST := 41.0
## Speeds the pull is mapped between. Below `SPEED_CALM` the camera sits at
## `OVERHEAD_DISTANCE`; above `SPEED_FAST` it is fully back.
const SPEED_CALM := 6.0
const SPEED_FAST := 16.0
## Smoothing on the speed the pull reads, which is heavier than the camera's own
## smoothing on purpose. Raw speed steps hard on every collision, and a camera
## that lurches backwards each time the marble clips a pillar looks broken
## rather than fast.
const SPEED_SMOOTHING := 1.5
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
##
## Cut from 5 to shift the whole frame up-course. Because the rig looks back, the
## marble sits *above* the focus, so lowering the lead moves it down the frame
## and everything up-course of it moves into shot. This is the constant that
## controls how far up the track you can see; pitch is not.
const OVERHEAD_LEAD := 2.5

# --- Mode.LOW (try) ------------------------------------------------------------

## Same rig as `Mode.OVERHEAD` — course-tangent focus, looks back up-course, pulls
## back with speed — just at a shallower pitch, on the theory that a lower angle
## trades some field-at-a-glance for more course visible ahead, which is the
## complaint about OVERHEAD. Untuned; this is a first try, not a locked value.
const LOW_PITCH := deg_to_rad(32.0)
const LOW_DISTANCE := 30.0
const LOW_DISTANCE_FAST := 38.0
const LOW_FOV := 26.0
const LOW_LEAD := 4.0

# --- Finish spectating ---------------------------------------------------------

## Where the camera goes once the player's own run is over.
##
## Their marble stops being the right subject at that moment: it is parked in the
## runoff and the race is still happening behind it, and if they fell it is not
## even visible. What is worth watching is the finish itself — the marbles still
## arriving, and the order building up in the runoff — so the rig re-aims at a
## fixed point in the finish area and stays there.
##
## Deliberately reuses `Mode.LOW`'s own geometry (looks back up-course, sits
## down-course of its focus) rather than inventing a second rig: the frame the
## player has been watching all race stays recognisable, it just stops moving.
## The transition is nothing but a change of `desired`/`aim`, so the existing
## position and aim smoothing carries the camera over rather than cutting.
const FINISH_PITCH := deg_to_rad(30.0)
## Further back than `LOW_DISTANCE`, because the shot now has to hold the line
## *and* the marbles still approaching it, not just one marble.
const FINISH_DISTANCE := 40.0
const FINISH_FOV := 30.0

var target: Marble
## Optional, and only `Mode.OVERHEAD` uses it. Without it that mode falls back
## to steering by the marble's own velocity, which is what the first render did
## and it swung the track diagonally across the frame.
var course: Course
var mode: Mode = DEFAULT_MODE

## Non-empty once `watch_finish` has been called: the point to aim at and the
## direction the course runs there.
var _finish_focus := Vector3.ZERO
var _finish_forward := Vector3.FORWARD
var _watching_finish := false

var _aim := Vector3.ZERO
var _speed := 0.0
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
		Mode.LOW:
			keep_aspect = KEEP_WIDTH
			fov = LOW_FOV

	# The debug mode cycle (C) must not undo the wider finish lens mid-spectate.
	if _watching_finish:
		fov = FINISH_FOV


func cycle_mode() -> void:
	match mode:
		Mode.CHASE:
			set_mode(Mode.OVERHEAD)
		Mode.OVERHEAD:
			set_mode(Mode.LOW)
		Mode.LOW:
			set_mode(Mode.CHASE)


func mode_name() -> String:
	match mode:
		Mode.CHASE:
			return "chase"
		Mode.OVERHEAD:
			return "overhead"
		Mode.LOW:
			return "low"
	return ""


## Stop following the player and settle onto the finish area.
##
## `focus` is a point a little way into the runoff and `forward` is the direction
## the course runs there — both from `FinishZone`, which is the only thing that
## knows where its own holding area is. Called once, when the player's run ends;
## the rig then sweeps over under its normal smoothing rather than cutting, which
## is why nothing here touches `_initialised`.
func watch_finish(focus: Vector3, forward: Vector3) -> void:
	_finish_focus = focus
	_finish_forward = forward.normalized() if not forward.is_zero_approx() else Vector3.FORWARD
	if _watching_finish:
		return
	_watching_finish = true
	# The wider lens is part of holding both the line and the approach; changed
	# once rather than lerped, because `fov` is not interpolated anywhere else
	# here and a zoom would read as a second camera move on top of the first.
	fov = FINISH_FOV


func _physics_process(delta: float) -> void:
	if _watching_finish:
		_update_finish_view(delta)
		return

	if target == null or not is_instance_valid(target):
		return

	var marble_position := target.global_position

	# Look-ahead is measured in seconds of course, so the camera opens up as
	# the marble gains speed and tightens when it slows.
	var travel := target.linear_velocity
	travel.y = 0.0

	_speed = lerpf(_speed, travel.length(), 1.0 - exp(-SPEED_SMOOTHING * delta))

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
		Mode.OVERHEAD, Mode.LOW:
			var pitch := OVERHEAD_PITCH if mode == Mode.OVERHEAD else LOW_PITCH
			var dist_calm := OVERHEAD_DISTANCE if mode == Mode.OVERHEAD else LOW_DISTANCE
			var dist_fast := OVERHEAD_DISTANCE_FAST if mode == Mode.OVERHEAD else LOW_DISTANCE_FAST
			var lead_metres := OVERHEAD_LEAD if mode == Mode.OVERHEAD else LOW_LEAD

			# The focus rides the course centreline ahead of the marble, not the
			# marble itself. Two things fall out of that: the track sits centred
			# in a narrow portrait frame instead of wherever the player happens
			# to have drifted, and yaw comes from the course's own tangent rather
			# than from an instantaneous velocity that jitters every time the
			# marble is nudged. Aiming at the marble did both badly.
			var lead := _course_lead(marble_position, lead_metres)
			if lead.is_empty():
				aim = marble_position + direction * lead_metres
			else:
				aim = lead["position"]
				direction = lead["tangent"]

			# `+=`, where a camera following from behind would use `-=`. That sign
			# is the whole difference: the rig sits *down*-course of its focus and
			# looks back up the track, so the field runs at the lens instead of
			# away from it, and the course's descent falls towards the viewer
			# instead of hiding along the view axis. Reading that gradient is the
			# question docs/CAMERA_SPIKE.md could not answer facing the other way.
			var pull := clampf(
				inverse_lerp(SPEED_CALM, SPEED_FAST, _speed), 0.0, 1.0
			)
			var distance := lerpf(dist_calm, dist_fast, pull)

			desired = aim
			desired += direction * (distance * cos(pitch))
			desired.y += distance * sin(pitch)

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
func _course_lead(from: Vector3, lead_metres: float) -> Dictionary:
	if course == null or not is_instance_valid(course) or course.curve == null:
		return {}

	var length := course.curve.get_baked_length()
	var offset := course.curve.get_closest_offset(from)
	var ahead := clampf(offset + lead_metres, 0.0, length)

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


## The static shot over the finish. Same construction as `Mode.LOW`'s — the rig
## sits down-course of its focus and looks back up the track, so marbles still
## racing come at the lens — but with a fixed focus instead of one riding ahead
## of a marble.
func _update_finish_view(delta: float) -> void:
	var desired := _finish_focus
	desired += _finish_forward * (FINISH_DISTANCE * cos(FINISH_PITCH))
	desired.y += FINISH_DISTANCE * sin(FINISH_PITCH)

	if not _initialised:
		_initialised = true
		global_position = desired
		_aim = _finish_focus
	else:
		global_position = global_position.lerp(desired, 1.0 - exp(-POSITION_SMOOTHING * delta))
		_aim = _aim.lerp(_finish_focus, 1.0 - exp(-AIM_SMOOTHING * delta))

	look_at(_aim, Vector3.UP)


func reset() -> void:
	_initialised = false
	_watching_finish = false
	set_mode(mode)
