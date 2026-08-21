extends Node3D

## Phase 0 race orchestration.
##
## Owns the sequence only: build course, settle the field, release, watch,
## resolve. It deliberately knows nothing about tournaments, rounds,
## elimination brackets, progression or currency, none of which exist in
## Phase 0 (spec section 10).
##
## Physics never touches game state directly. Marbles are simulated; this node
## observes them through triggers and reports what happened.

const MARBLE_COUNT := 12
const PLAYER_MARBLE_INDEX_UNSET := -1
const PLAYER_COLOUR := Color(0.25, 0.78, 1.0)

## Which course the prototype runs. `SlopeCourse` is a plain straight test track
## deliberately too simple to be the cause of anything; `CourseBuilder` is the
## Canyon, which currently stalls its field around ratio 0.66. Swap this line to
## get the Canyon back.
## Preloaded by path rather than named directly: a global class name is not a
## constant expression, so `const COURSE := SlopeCourse` does not parse.
const COURSE: GDScript = preload("res://scripts/course/slope_course.gd")

enum Phase { SETTLING, RACING, COMPLETE }

var _course: Course
var _barrier: StartBarrier
var _camera: ChaseCamera
var _hud: RaceHUD
var _tuning: MarbleTuning

var _marbles: Array[Marble] = []
var _player: Marble
var _finish_order: Array[Marble] = []

var _phase: Phase = Phase.SETTLING
var _race_time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_tuning = MarbleTuning.new()
	_setup_environment()
	_start_race()


func _unhandled_input(event: InputEvent) -> void:
	# Bound directly rather than through an input map action: Phase 0 has two
	# debug keys, and InputMap entries would be config to keep in sync for no gain.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_restart()
		elif event.keycode == KEY_C and _camera != null and is_instance_valid(_camera):
			# Camera spike only — remove with Mode.OVERHEAD once the phone test
			# settles the projection. See docs/CAMERA_SPIKE.md.
			_camera.cycle_mode()


const DEBUG_TRACE := true
var _trace_accumulator := 0.0


func _physics_process(delta: float) -> void:
	if _phase == Phase.RACING:
		_race_time += delta
		_check_for_falls()

	if DEBUG_TRACE:
		_trace_accumulator += delta
		if _trace_accumulator >= 2.0:
			_trace_accumulator = 0.0
			var racing := 0
			var furthest := 0.0
			var moving := 0
			for marble in _marbles:
				if marble.state == Marble.State.RACING:
					racing += 1
				furthest = minf(furthest, marble.global_position.z)
				if marble.linear_velocity.length() > 0.2:
					moving += 1
			var p := _player.global_position
			print(
				"t=%5.1f phase=%d racing=%2d moving=%2d furthest_z=%7.1f player=(%.2f, %.2f, %.2f) v=%.2f"
				% [
					_race_time,
					_phase,
					racing,
					moving,
					furthest,
					p.x,
					p.y,
					p.z,
					_player.linear_velocity.length(),
				]
			)

	_update_hud()


# --- Race lifecycle -----------------------------------------------------------


func _start_race() -> void:
	_rng.randomize()

	_course = COURSE.new()
	_course.name = "Course"
	add_child(_course)
	_course.build()

	_spawn_field()
	_add_barrier()
	_add_finish()
	_add_camera()

	_phase = Phase.SETTLING
	_race_time = 0.0


## Tears the race down completely and rebuilds it. Rebuilding rather than
## repositioning is what guarantees the clean restart state the spec asks for:
## no residual velocities, no half-open barrier, no stale finish order.
func _restart() -> void:
	for node in [_course, _barrier, _camera]:
		if node != null and is_instance_valid(node):
			node.queue_free()

	for marble in _marbles:
		if is_instance_valid(marble):
			marble.queue_free()

	_marbles.clear()
	_finish_order.clear()
	_player = null

	_start_race()


func _spawn_field() -> void:
	var spawns := _course.get_spawn_transforms(MARBLE_COUNT, _rng)

	# The player's slot is drawn at random. Identification comes from the
	# marble's own look, not from a fixed, learnable position.
	var player_index := _rng.randi_range(0, MARBLE_COUNT - 1)

	for i in MARBLE_COUNT:
		var is_player := i == player_index
		var colour := PLAYER_COLOUR if is_player else _opponent_colour(i)
		var marble := Marble.create(i, _tuning, colour, is_player)

		add_child(marble)
		marble.reset_to(spawns[i])
		_marbles.append(marble)

		if is_player:
			_player = marble


func _opponent_colour(index: int) -> Color:
	# Cosmetic only. Opponents are physically identical to the player
	# (PROJECT.md section 7).
	return Color.from_hsv(fmod(float(index) * 0.13, 1.0), 0.45, 0.85)


func _add_barrier() -> void:
	_barrier = StartBarrier.create(_course.start_width())
	add_child(_barrier)
	# Placed with the start line's full frame, not just its origin: on a sloped
	# or banked start a barrier left axis-aligned leaves a gap under one edge.
	_barrier.global_transform = _course.start_transform.translated_local(
		Vector3(0.0, StartBarrier.HEIGHT * 0.5, 0.0)
	)
	_barrier.opened.connect(_on_barrier_opened)


func _add_finish() -> void:
	var finish := FinishArea.create(_course.finish_width())
	_course.add_child(finish)
	finish.global_position = _course.finish_position + Vector3(0.0, 2.0, 0.0)
	finish.marble_finished.connect(_on_marble_finished)


func _add_camera() -> void:
	_camera = ChaseCamera.create()
	add_child(_camera)
	_camera.target = _player
	_camera.course = _course


func _on_barrier_opened() -> void:
	_phase = Phase.RACING
	_race_time = 0.0
	for marble in _marbles:
		marble.state = Marble.State.RACING
		marble.sleeping = false


# --- Outcomes -----------------------------------------------------------------


func _on_marble_finished(marble: Marble) -> void:
	marble.state = Marble.State.FINISHED
	_finish_order.append(marble)
	_check_for_completion()


## Out-of-bounds detection. A simple height threshold is enough for Phase 0;
## the spec explicitly defers stuck detection until a prototype proves it is a
## real problem.
func _check_for_falls() -> void:
	for marble in _marbles:
		if marble.state != Marble.State.RACING:
			continue
		if marble.global_position.y < _course.fall_threshold_y():
			marble.state = Marble.State.ELIMINATED
			marble.visible = false
			marble.freeze = true

	_check_for_completion()


func _check_for_completion() -> void:
	for marble in _marbles:
		if marble.state == Marble.State.RACING:
			return

	if _phase == Phase.COMPLETE:
		return
	_phase = Phase.COMPLETE

	# The prototype exists to be measured: run length against the 20-30s target
	# and how many marbles fell are the two numbers Phase 0 is tuning towards.
	var fallen := MARBLE_COUNT - _finish_order.size()
	print(
		"Race complete in %.1fs | finished %d/%d | fell %d | player %s"
		% [_race_time, _finish_order.size(), MARBLE_COUNT, fallen, _player_status()]
	)


# --- Presentation -------------------------------------------------------------


func _setup_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.5, 0.72)
	sky_material.sky_horizon_color = Color(0.78, 0.72, 0.62)
	sky_material.ground_bottom_color = Color(0.3, 0.26, 0.22)
	sky_material.ground_horizon_color = Color(0.6, 0.52, 0.44)

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.6

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

	_hud = RaceHUD.create()
	add_child(_hud)


func _update_hud() -> void:
	match _phase:
		Phase.SETTLING:
			_hud.show_text(
				"Tap the barrier to start  (auto %.1fs)%s" % [
					_barrier.time_remaining(), _camera_debug()
				]
			)
		Phase.RACING:
			_hud.show_text(
				"%.1fs    %s%s" % [_race_time, _player_status(), _camera_debug()]
			)
		Phase.COMPLETE:
			_hud.show_text(
				"%.1fs    %s    R to restart%s" % [
					_race_time, _player_status(), _camera_debug()
				]
			)


## Camera spike only. Which projection you are looking at is the whole question
## the spike asks, and after a few toggles it stops being obvious. Remove with
## Mode.OVERHEAD.
func _camera_debug() -> String:
	if _camera == null or not is_instance_valid(_camera):
		return ""
	return "\ncam: %s  (C)" % _camera.mode_name()


func _player_status() -> String:
	if _player == null or not is_instance_valid(_player):
		return ""

	match _player.state:
		Marble.State.ELIMINATED:
			return "fell"
		Marble.State.FINISHED:
			return "finished %d/%d" % [_finish_order.find(_player) + 1, MARBLE_COUNT]
		_:
			return "racing"
