extends SceneTree

## One-off diagnostic for FoundryCourse: builds it, spawns a full field of
## real Marble bodies on it, and reports finishes/falls/stalls. Not wired into
## any pool — this only exists to check the course isn't broken before it goes
## into COURSE_POOL. Run with:
##   godot --headless --path . --script tools/probe_foundry.gd \
##     --fixed-fps 60 --disable-render-loop --quit-after 3600

const COURSE: GDScript = preload("res://scripts/course/foundry_course.gd")
const MARBLE: GDScript = preload("res://scripts/simulation/marble.gd")
const TUNING: GDScript = preload("res://scripts/simulation/marble_tuning.gd")

const MARBLE_COUNT := 12
const STALL_SPEED := 0.3
const STALL_SECONDS := 3.0

var _course: Course
var _marbles: Array[Marble] = []
var _stall_time: PackedFloat32Array
var _reported: Array[bool] = []
var _finished: Array[bool] = []
var _fallen: Array[bool] = []
var _frame := 0


## Not `_init()`: this script's own SceneTree isn't fully up yet at
## construction time, and `FoundryCourse.build()` starts a `Timer` (the
## rubble spawner) that needs `is_inside_tree()` true the moment it starts.
## `_initialize()` runs once the tree is actually ready.
func _initialize() -> void:
	_course = COURSE.new()
	get_root().add_child(_course)
	_course.build()
	print("finish = %s  fall_threshold_y = %.1f" % [_course.finish_position, _course.fall_threshold_y()])

	var tuning: MarbleTuning = TUNING.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var spawns := _course.get_spawn_transforms(MARBLE_COUNT, rng)

	for i in MARBLE_COUNT:
		var marble: Marble = MARBLE.create(i, tuning, Color.WHITE, false)
		get_root().add_child(marble)
		marble.global_transform = spawns[i]
		marble.state = Marble.State.RACING
		_marbles.append(marble)

	_stall_time.resize(MARBLE_COUNT)
	for i in MARBLE_COUNT:
		_reported.append(false)
		_finished.append(false)
		_fallen.append(false)

	physics_frame.connect(_on_physics_frame)


func _on_physics_frame() -> void:
	_frame += 1
	var delta := 1.0 / 60.0

	for i in MARBLE_COUNT:
		var marble := _marbles[i]
		if not is_instance_valid(marble) or _finished[i] or _fallen[i]:
			continue

		if marble.global_position.y < _course.fall_threshold_y():
			_fallen[i] = true
			print("t=%.2f marble %d FELL at %s" % [_frame / 60.0, i, marble.global_position])
			continue

		if marble.global_position.distance_to(_course.finish_position) < 3.0:
			_finished[i] = true
			print("t=%.2f marble %d FINISHED" % [_frame / 60.0, i])
			continue

		if marble.linear_velocity.length() < STALL_SPEED:
			_stall_time[i] += delta
		else:
			_stall_time[i] = 0.0

		if _stall_time[i] > STALL_SECONDS and not _reported[i]:
			_reported[i] = true
			var offset := _course.curve.get_closest_offset(marble.global_position)
			var fraction := offset / _course.curve.get_baked_length()
			print("t=%.2f marble %d STALLED at %s  offset=%.1f fraction=%.3f" % [
				_frame / 60.0, i, marble.global_position, offset, fraction
			])

	if _frame % 300 == 0:
		var done := 0
		for i in MARBLE_COUNT:
			if _finished[i] or _fallen[i]:
				done += 1
		print("t=%.2f  resolved=%d/%d" % [_frame / 60.0, done, MARBLE_COUNT])
