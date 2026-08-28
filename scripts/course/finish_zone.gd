class_name FinishZone
extends Node3D

## The finish, as a system rather than a line and a wall.
##
## Replaces `FinishArea`, which was a box that emitted a signal. The flow it
## produced was RACE -> LINE -> WALL -> STOP: a marble crossed, the geometry six
## metres later stopped it dead, and once the player's marble was among them
## there was nothing left to look at. What the round actually wants is
##
##     RACE -> LINE -> KEEP ROLLING -> SLOW DOWN -> WATCH THE REST ARRIVE
##
## so this owns three things that used to be nobody's job:
##
## - **The trigger.** A thin `Area3D` on the finish frame. It decides finishing
##   order and nothing else — a marble that crosses keeps every bit of its
##   momentum, and where it eventually comes to rest is irrelevant to its place.
## - **The slowdown.** Damping ramped by how far past the line a marble is, so
##   the runoff brings the field to a stop the way gravel does rather than the
##   way a wall does. It is applied per marble rather than by putting friction on
##   the surface, because the surface is the course's and every course would
##   otherwise have to author the same ramp.
## - **The feedback.** A small particle burst and a floating place tag per
##   finisher, so the order is legible on the track itself and not only in the
##   standings column.
##
## What it deliberately does **not** own is anything the player can see as part
## of the map: the runoff floor, the walls that contain it, the backstop at the
## far end, and the finish's own dressing all belong to the course
## (`Course.create_finish_visual` and `Course.finish_runoff`), because a
## sandstone arch has no business being reused in an ice valley. The race
## manager talks to this class; this class talks to `Course` through the same
## small interface everything else does.

## Emitted once per marble, in the order they crossed. The race manager decides
## what a place *means*; this only says who got there first.
signal marble_finished(marble: Marble)

# --- Trigger ------------------------------------------------------------------

## Tall enough that a marble arriving airborne still trips it, deep enough that
## one arriving at 20 m/s (a third of a metre per physics frame) cannot step over
## it. Area3D has no continuous collision detection to fall back on, and the
## sweep in `_physics_process` is the second line of defence rather than the
## first.
const TRIGGER_HEIGHT := 7.0
const TRIGGER_DEPTH := 2.0
## How far outboard of the track the trigger reaches. Generous: a marble riding
## up a banked wall as it crosses is still finishing, and the alternative failure
## — a marble that finishes and is never recorded — hangs the round.
const TRIGGER_WIDTH_MARGIN := 3.0

# --- Slowdown -----------------------------------------------------------------

## Damping at the far end of the runoff. Angular is the one that does the work:
## `MarbleTuning` notes that angular damping opposes rolling directly and that
## small increases cost a lot of speed, which is exactly what is wanted *after*
## the line and exactly why the racing value is 0.02.
const RUNOFF_LINEAR_DAMP := 2.4
const RUNOFF_ANGULAR_DAMP := 4.2
## Shape of the ramp. Above 1.0 the first stretch past the line is nearly free
## and the bite arrives later, so a marble crosses at speed and is visibly still
## racing for a moment instead of hitting treacle on the line.
const DAMP_RAMP_POWER := 1.8
## Fraction of the runoff over which the ramp reaches full strength; the rest is
## the holding area, where marbles are already rolling slowly and simply settle.
const DAMP_RAMP_SPAN := 0.7

# --- Feedback -----------------------------------------------------------------

## One-shot burst emitters, reused round-robin. Twelve marbles can finish inside
## a few seconds and a pool is what keeps that from being twelve emitter nodes
## built at the busiest moment of the round — the same reasoning `SoundManager`
## uses for its coin voices.
const BURST_VOICES := 4
const BURST_AMOUNT := 12
const BURST_LIFETIME := 0.5

## How long an opponent's place tag stays up. The player's does not expire —
## their own result is the one thing they should not have to remember.
const TAG_SECONDS := 2.8
const TAG_FADE := 0.9
const TAG_OFFSET := 1.3
const TAG_FONT_SIZE := 52
const TAG_PIXEL_SIZE := 0.00028
const TAG_SMOOTHING := 12.0

var _course: Course
## The finish line's own frame: local -Z runs down-course, so "past the line" is
## `-local.z`.
##
## Kept twice deliberately. `_frame` is in the course's own space, which is what
## every child placed under this node is positioned in; `_inverse` is the inverse
## of the same frame in *world* space, because the marbles measured against it
## every physics frame report `global_position`. The two are the same today —
## nothing ever transforms the course node — and a race that quietly broke the
## moment someone did would be a bad way to find that out.
var _frame := Transform3D.IDENTITY
var _world_frame := Transform3D.IDENTITY
var _inverse := Transform3D.IDENTITY
var _runoff := 1.0
var _half_width := 6.0

var _trigger: Area3D
var _field: Array[Marble] = []
## Marbles already recorded, so a marble that bounces back through the line and
## crosses it again is not counted twice.
var _crossed: Dictionary = {}
## Crossings seen this physics step, flushed on the next one. Buffering is what
## makes a near-simultaneous pair resolve by how far past the line each actually
## is rather than by the order the physics server happened to report them in.
var _pending: Array[Marble] = []

var _bursts: Array[CPUParticles3D] = []
var _burst_voice := 0
var _tags: Array = []


## Everything the zone needs comes off the `Course` interface the race manager
## already talks to, so adding a course adds a finish with it.
static func create(course: Course) -> FinishZone:
	var zone := FinishZone.new()
	zone.name = "FinishZone"
	zone._course = course
	zone._build()
	return zone


func _build() -> void:
	_half_width = maxf(_course.finish_width() * 0.5, 1.0)
	_runoff = maxf(_course.finish_runoff(), 1.0)

	# Placed through the course's own frame rather than through
	# `finish_position` plus a world-up offset: a banked or descending finish
	# leaves an axis-aligned box with one corner through the floor and the
	# opposite one over open air.
	if _course.curve != null:
		_frame = _course.frame_at(_course.curve.get_closest_offset(_course.finish_position))
	else:
		_frame = Transform3D(Basis.IDENTITY, _course.finish_position)
	# The frame is sampled from the baked curve, which cuts corners and so lands
	# a few centimetres off the point the course itself calls the finish. The
	# orientation is what was wanted from it; the origin comes from the course.
	_frame.origin = _course.finish_position
	# A placeholder until `_ready` can ask the scene tree where this node
	# actually is; `create` runs before the zone is parented to anything.
	_world_frame = _frame
	_inverse = _frame.affine_inverse()

	_build_trigger()
	_build_bursts()

	var visual := _course.create_finish_visual()
	if visual != null:
		add_child(visual)


## `_frame` is in the course's space; only once this node is in the tree is there
## anything to say what that is in world terms. Everything placed as a child uses
## `_frame`; everything measured against a marble uses `_inverse`.
func _ready() -> void:
	_world_frame = global_transform * _frame
	_inverse = _world_frame.affine_inverse()


func _build_trigger() -> void:
	_trigger = Area3D.new()
	_trigger.name = "FinishTrigger"
	# Nothing reads the area's own body list; it is a line to cross, not a
	# volume to be inside. Monitorable off keeps it out of every other area's
	# overlap tests for free.
	_trigger.monitorable = false

	var shape := BoxShape3D.new()
	shape.size = Vector3(
		(_half_width + TRIGGER_WIDTH_MARGIN) * 2.0, TRIGGER_HEIGHT, TRIGGER_DEPTH
	)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	_trigger.add_child(collider)

	# Sunk slightly below the deck and lifted mostly above it, so a marble
	# rolling on the surface passes through the box's middle.
	_trigger.transform = _frame.translated_local(
		Vector3(0.0, TRIGGER_HEIGHT * 0.5 - 0.6, 0.0)
	)
	_trigger.body_entered.connect(_on_body_entered)
	add_child(_trigger)


func _build_bursts() -> void:
	for i in BURST_VOICES:
		var burst := CPUParticles3D.new()
		burst.name = "FinishBurst%d" % i
		burst.emitting = false
		burst.one_shot = true
		burst.amount = BURST_AMOUNT
		burst.lifetime = BURST_LIFETIME
		burst.explosiveness = 1.0
		burst.direction = Vector3.UP
		burst.spread = 60.0
		burst.gravity = Vector3(0.0, -6.0, 0.0)
		burst.initial_velocity_min = 2.0
		burst.initial_velocity_max = 4.5
		burst.scale_amount_min = 0.8
		burst.scale_amount_max = 1.4
		# `local_coords` off and an explicit `visibility_aabb` for the reasons
		# `MarbleTrail._configure_particles` documents: without the box the
		# renderer culls almost every particle before it is drawn.
		burst.local_coords = false
		burst.visibility_aabb = AABB(Vector3(-4.0, -4.0, -4.0), Vector3(8.0, 8.0, 8.0))
		burst.mesh = _burst_mesh()
		add_child(burst)
		_bursts.append(burst)


## Small unshaded flecks, coloured through vertex colour so the emitter's own
## `color` actually shows — see `MarbleTrail._particle_mesh`, which this follows.
func _burst_mesh() -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(0.11, 0.11, 0.11)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	box.material = material
	return box


## The field this round. Held so the sweep in `_physics_process` can catch a
## marble the trigger missed and so the damping ramp knows what to look at.
func register(marbles: Array[Marble]) -> void:
	_field = marbles.duplicate()
	_crossed.clear()
	_pending.clear()
	clear_tags()


# --- Crossing -----------------------------------------------------------------


func _on_body_entered(body: Node3D) -> void:
	var marble := body as Marble
	if marble == null or marble.state != Marble.State.RACING:
		return
	if _crossed.has(marble) or _pending.has(marble):
		return
	_pending.append(marble)


func _physics_process(delta: float) -> void:
	_flush_crossings()
	_sweep_for_missed()
	_apply_slowdown()
	_update_tags(delta)


## Reports the step's crossings deepest-first.
##
## Two marbles arriving in the same physics step are reported to the race in the
## order the physics server iterated them, which has nothing to do with which one
## was actually in front. Sorting by how far each is past the line puts the
## marble that crossed earlier — and is therefore further through the trigger —
## first, which is the answer a viewer watching the two of them would give.
func _flush_crossings() -> void:
	if _pending.is_empty():
		return

	var crossings := _pending
	_pending = []

	if crossings.size() > 1:
		crossings.sort_custom(
			func(a: Marble, b: Marble) -> bool: return _past(a) > _past(b)
		)

	for marble in crossings:
		if not is_instance_valid(marble) or marble.state != Marble.State.RACING:
			continue
		if _crossed.has(marble):
			continue
		_crossed[marble] = true
		marble_finished.emit(marble)


## Catches a marble that got past the line without the trigger seeing it.
##
## The trigger is an `Area3D` and areas have no continuous collision detection,
## so a marble that is airborne over the box, or moving fast enough to step over
## it in one frame, would otherwise never finish — and a marble that never
## finishes holds the round open until the grace period expires and then scores
## as if it had fallen. Cheap enough to run unconditionally: one matrix multiply
## per still-racing marble.
func _sweep_for_missed() -> void:
	for marble in _field:
		if not is_instance_valid(marble) or marble.state != Marble.State.RACING:
			continue
		if _crossed.has(marble) or _pending.has(marble):
			continue

		var local := _inverse * marble.global_position
		if -local.z < TRIGGER_DEPTH * 0.5:
			continue
		# The same bounds the trigger box has, so a marble that left the course
		# sideways near the line is not credited with a finish it never made.
		if absf(local.x) > _half_width + TRIGGER_WIDTH_MARGIN:
			continue
		if local.y < -2.0 or local.y > TRIGGER_HEIGHT:
			continue

		_pending.append(marble)


## Distance past the finish line, in metres, negative before it.
func _past(marble: Marble) -> float:
	if not is_instance_valid(marble):
		return 0.0
	return -(_inverse * marble.global_position).z


# --- Slowdown -----------------------------------------------------------------


## Ramps damping with distance into the runoff.
##
## Measured against the finish frame rather than by re-sampling the course curve
## per marble: `get_closest_offset` is the expensive call the race manager rations
## to ten times a second, and a runoff is the one stretch of a course that is
## near enough to straight for a plane distance to stand in for an arc length.
## The error only ever shows up as slightly softer or firmer damping, never as a
## wrong place.
func _apply_slowdown() -> void:
	for marble: Marble in _crossed.keys():
		if not is_instance_valid(marble) or marble.state != Marble.State.FINISHED:
			continue

		var t := clampf(_past(marble) / (_runoff * DAMP_RAMP_SPAN), 0.0, 1.0)
		var ramp := pow(t, DAMP_RAMP_POWER)
		# Lerped from the marble's own racing values rather than from zero, so
		# the ramp starts at exactly what the marble had a frame before it
		# crossed and there is no step on the line itself.
		var tuning := marble.tuning()
		marble.linear_damp = lerpf(tuning.linear_damp, RUNOFF_LINEAR_DAMP, ramp)
		marble.angular_damp = lerpf(tuning.angular_damp, RUNOFF_ANGULAR_DAMP, ramp)


# --- Feedback -----------------------------------------------------------------


## Presentation for one finisher. `place` is one-based and comes from the race —
## the zone never numbers anything itself, so there is exactly one finishing
## order in the game and it is the race manager's.
##
## `detonate` asks for the player's equipped finish effect instead of the small
## burst. The race manager decides when that is true (the player's own marble,
## finishing inside the cut) for the same reason it owns `place`: whether a
## finish is worth celebrating is a fact about the round, and the zone has no
## business knowing the survivor count.
func celebrate(marble: Marble, place: int, detonate: bool = false) -> void:
	if not is_instance_valid(marble):
		return
	if detonate:
		_fire_finish_effect(marble)
	else:
		_fire_burst(marble.global_position, marble.colour)
	_add_tag(marble, place)


## The player's equipped effect, at the point they crossed.
##
## It replaces the small burst rather than layering over it — two effects at the
## same point in the same frame is how a moment turns to mush — but the place
## tag stays, because the effect says "that was you" and only the tag says
## "third".
##
## Effect id 0 deliberately falls through to `_fire_burst`. It is the free
## default and it is defined as *what the game already did*, so the profile that
## has never visited the shop sees a finish that is byte-for-byte the one it saw
## before effects existed.
func _fire_finish_effect(marble: Marble) -> void:
	var style := PlayerProfile.equipped_finish_data()
	if style.is_empty() or int(style.get("id", 0)) == 0:
		_fire_burst(marble.global_position, marble.colour)
		return

	var effect := FinishEffect.create(style, marble.colour)
	# Parented before it is placed: `global_position` on a node outside the tree
	# is meaningless and silently leaves the effect at the origin — the same
	# trap `_add_tag` documents.
	add_child(effect)
	effect.global_position = marble.global_position


func _fire_burst(at: Vector3, colour: Color) -> void:
	if _bursts.is_empty():
		return
	var burst := _bursts[_burst_voice]
	_burst_voice = (_burst_voice + 1) % _bursts.size()
	burst.global_position = at
	burst.color = colour.lightened(0.35)
	# `restart()` alone does not re-arm a one-shot emitter built with
	# `emitting = false` — `MarbleTrail._add_sample` hit the same thing.
	burst.emitting = true
	burst.restart()


## A place floating over the marble that just earned it, so the order can be read
## off the runoff itself. The player's is worded and holds; an opponent's fades,
## because twelve permanent labels stacked in a holding area is a wall of text
## over the thing they are labelling.
func _add_tag(marble: Marble, place: int) -> void:
	var label := Label3D.new()
	label.font_size = TAG_FONT_SIZE
	label.pixel_size = TAG_PIXEL_SIZE
	label.fixed_size = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.shaded = false
	label.no_depth_test = true
	label.render_priority = 8 if marble.is_player else 6
	label.outline_render_priority = label.render_priority - 1
	label.outline_size = 10
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.modulate = marble.colour
	var ordinal := RankTag.ordinal(place).to_upper()
	label.text = "YOU — %s" % ordinal if marble.is_player else ordinal
	# Parented before it is placed: `global_position` is meaningless on a node
	# that is not in the tree yet, and setting it first silently leaves the tag
	# at the origin.
	add_child(label)
	label.global_position = marble.global_position

	_tags.append({
		"label": label,
		"marble": marble,
		"life": TAG_SECONDS,
		"hold": marble.is_player,
	})


## Drops every place tag. Called when the round is scored: the results screen
## lists the same order in a form the player can read at leisure, and leaving
## twelve labels floating over a frozen field behind it is the "no large UI
## interruption" rule failing in the other direction.
func clear_tags() -> void:
	for tag: Dictionary in _tags:
		var label: Label3D = tag["label"]
		if is_instance_valid(label):
			label.queue_free()
	_tags.clear()


func _update_tags(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var kept := []

	for tag: Dictionary in _tags:
		var label: Label3D = tag["label"]
		if not is_instance_valid(label):
			continue

		var marble: Marble = tag["marble"]
		if is_instance_valid(marble) and camera != null:
			# Offset along the camera's own up axis rather than world +Y, so the
			# gap stays the same on screen under a steeply pitched camera —
			# `RankTag.follow` is where that reasoning is written down.
			var target := marble.global_position + camera.global_basis.y * TAG_OFFSET
			label.global_position = label.global_position.lerp(
				target, minf(delta * TAG_SMOOTHING, 1.0)
			)

		if not bool(tag["hold"]):
			tag["life"] = float(tag["life"]) - delta
			if float(tag["life"]) <= 0.0:
				label.queue_free()
				continue
			label.modulate.a = minf(float(tag["life"]) / TAG_FADE, 1.0)

		kept.append(tag)

	_tags = kept


# --- Camera -------------------------------------------------------------------


## Where a camera should look to keep both the line and the marbles still
## arriving at it in shot: a little way into the runoff, so the finished field
## and the approach share the frame.
func spectate_focus() -> Vector3:
	return _world_frame * Vector3(0.0, 0.0, -_runoff * 0.28)


## Which way the course runs at the finish, for a camera that has to place itself
## relative to it.
func spectate_forward() -> Vector3:
	var forward := -_world_frame.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	return forward if not forward.is_zero_approx() else Vector3.FORWARD
