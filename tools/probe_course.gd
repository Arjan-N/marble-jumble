extends Node3D

## Field probe for any course in `course_shot.gd`'s `COURSES`: builds it, spawns
## a full field of real `Marble` bodies on it, and reports finishes, falls and
## stalls. Nothing is rendered and no `RaceManager` is involved — this only
## answers "does the field get down this course", which is the question that has
## to be answered before a course goes into `COURSE_POOL`.
##
##     MJ_COURSE=temple godot --headless --path . res://tools/probe_course.tscn \
##       --fixed-fps 60 --disable-render-loop --quit-after 3600
##
## A **scene**, not a `--script` SceneTree, unlike `probe_glacier_fault.gd` and
## the other one-off `--script` probes. Those cannot run at all in this environment:
## `--headless --script` compiles the script's dependencies before the autoloads
## exist, so `marble.gd`'s reference to `PlayerProfile` fails to resolve and the
## whole probe dies before it builds anything. Running the same logic as a scene
## goes through normal project startup, autoloads included.
##
## Courses are shared with `course_shot.gd` rather than preloaded one per probe,
## so a new course becomes screenshot-able and probe-able in the same edit.

const COURSE_SHOT: GDScript = preload("res://tools/course_shot.gd")

const MARBLE_COUNT := 12
## Below this speed for `STALL_SECONDS` a marble is stuck, not slow.
const STALL_SPEED := 0.3
const STALL_SECONDS := 3.0
var _course: Course
var _marbles: Array[Marble] = []
var _stall_time := PackedFloat32Array()
var _reported: Array[bool] = []
var _finished: Array[bool] = []
var _fallen: Array[bool] = []
var _frame := 0


func _ready() -> void:
	var key := OS.get_environment("MJ_COURSE")
	if key.is_empty():
		key = "temple"
	var courses: Dictionary = COURSE_SHOT.COURSES
	if not courses.has(key):
		push_error("MJ_COURSE=%s is not one of %s" % [key, courses.keys()])
		get_tree().quit(1)
		return

	_course = (courses[key] as GDScript).new()
	add_child(_course)
	_course.build()
	print("course=%s  finish=%s  fall_threshold_y=%.1f  curve_length=%.1f" % [
		key, _course.finish_position, _course.fall_threshold_y(),
		_course.curve.get_baked_length(),
	])

	var tuning := MarbleTuning.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var spawns := _course.get_spawn_transforms(MARBLE_COUNT, rng)

	for i in MARBLE_COUNT:
		var marble := Marble.create(i, tuning, Color.WHITE, false)
		add_child(marble)
		marble.global_transform = spawns[i]
		marble.state = Marble.State.RACING
		_marbles.append(marble)

	_stall_time.resize(MARBLE_COUNT)
	for i in MARBLE_COUNT:
		_reported.append(false)
		_finished.append(false)
		_fallen.append(false)


## Half the finish gate plus a marble, rather than a fixed 3m: on a wide course
## a marble finishing down the outside passes further than 3m from the
## centreline, and a fixed radius counts it as running off the end instead —
## which is exactly what `probe_glacier_fault.gd`'s copy of this loop would do.
func _finish_radius() -> float:
	return _course.finish_width() * 0.5 + 1.0


func _physics_process(delta: float) -> void:
	_frame += 1

	for i in MARBLE_COUNT:
		var marble := _marbles[i]
		if not is_instance_valid(marble) or _finished[i] or _fallen[i]:
			continue

		if marble.global_position.y < _course.fall_threshold_y():
			_fallen[i] = true
			print("t=%.2f marble %d FELL at %s" % [_frame / 60.0, i, marble.global_position])
			continue

		if marble.global_position.distance_to(_course.finish_position) < _finish_radius():
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
		var resolved := 0
		var finished := 0
		for i in MARBLE_COUNT:
			if _finished[i]:
				finished += 1
			if _finished[i] or _fallen[i]:
				resolved += 1
		print("t=%.2f  finished=%d  resolved=%d/%d" % [
			_frame / 60.0, finished, resolved, MARBLE_COUNT
		])
		if resolved == MARBLE_COUNT:
			print("all resolved at t=%.2f" % [_frame / 60.0])
			get_tree().quit()
