extends SceneTree

## Diagnostic: races CourseBuilder's own field (real `Marble` bodies, real
## `MarbleTuning`, real spawn transforms) and logs where each marble actually
## stalls, so the stall documented in `course_builder.gd`'s comments can be
## pinned to a ratio/position instead of "part-way down". Run with:
##   godot --headless --path . --script tools/probe_stall.gd \
##     --fixed-fps 60 --disable-render-loop --quit-after 4800

const COURSE: GDScript = preload("res://scripts/course/course_builder.gd")
const MARBLE: GDScript = preload("res://scripts/simulation/marble.gd")
const TUNING: GDScript = preload("res://scripts/simulation/marble_tuning.gd")

const MARBLE_COUNT := 12
## Below this speed a marble counts as stopped, not just slowed by a corner.
const STALL_SPEED := 0.3
## How long a marble has to stay under STALL_SPEED before it's reported —
## long enough that a marble merely stuck behind a pile-up for a moment
## doesn't get flagged.
const STALL_SECONDS := 3.0
const SNAPSHOT_INTERVAL := 2.0

var _course: Course
var _marbles: Array[Marble] = []
var _stall_time: PackedFloat32Array
var _reported: Array[bool] = []
var _frame := 0
var _next_snapshot := 0.0


func _init() -> void:
	_course = COURSE.new()
	get_root().add_child(_course)
	_course.build()
	print("baked length = %.1f  race length = %.1f" % [_course._length, _course._race_length])

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

	physics_frame.connect(_on_physics_frame)


func _ratio_at(position: Vector3) -> float:
	var offset := _course.curve.get_closest_offset(position)
	return (offset - _course._race_start_offset) / _course._race_length


func _on_physics_frame() -> void:
	_frame += 1
	var t := float(_frame) / 60.0

	for i in _marbles.size():
		var marble := _marbles[i]
		var speed := marble.linear_velocity.length()
		if speed < STALL_SPEED:
			_stall_time[i] += 1.0 / 60.0
		else:
			_stall_time[i] = 0.0

		if _stall_time[i] >= STALL_SECONDS and not _reported[i]:
			_reported[i] = true
			print(
				"STALL  marble=%2d  t=%6.1fs  ratio=%.3f  pos=%s  speed=%.2f"
				% [i, t, _ratio_at(marble.global_position), marble.global_position, speed]
			)

	if t >= _next_snapshot:
		_next_snapshot += SNAPSHOT_INTERVAL
		var ratios := []
		var min_y := INF
		var max_y := -INF
		for marble in _marbles:
			ratios.append(_ratio_at(marble.global_position))
			min_y = minf(min_y, marble.global_position.y)
			max_y = maxf(max_y, marble.global_position.y)
		ratios.sort()
		print(
			"t=%6.1fs  ratio min=%.3f  median=%.3f  max=%.3f  y=[%.1f,%.1f]  stalled=%d/%d"
			% [t, ratios[0], ratios[ratios.size() / 2], ratios[-1], min_y, max_y, _reported.count(true), MARBLE_COUNT]
		)
