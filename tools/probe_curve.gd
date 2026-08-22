extends SceneTree

## Diagnostic: prints the baked centreline's height and local grade along the
## course, so a bulge or flat spot can be found by measurement rather than by
## reading control points. Run with:
##   godot --headless --path . --script tools/probe_curve.gd

const COURSE: GDScript = preload("res://scripts/course/course_builder.gd")


func _init() -> void:
	var course: Course = COURSE.new()
	get_root().add_child(course)
	course.build()

	var curve := course.curve
	var length := curve.get_baked_length()
	print("baked length = %.1f" % length)

	var step := 2.0
	var s := 0.0
	var previous := curve.sample_baked(0.0)
	while s <= length:
		var here := curve.sample_baked(s)
		var rise := here.y - previous.y
		var run := Vector2(here.x - previous.x, here.z - previous.z).length()
		var grade := 0.0
		if run > 0.0001:
			grade = rad_to_deg(atan2(-rise, run))
		var flag := ""
		if rise > 0.001:
			flag = "   <<< RISES"
		elif grade < 3.0:
			flag = "   <<< near-flat"
		print("s=%7.1f  y=%8.3f  grade=%6.2f deg%s" % [s, here.y, grade, flag])
		previous = here
		s += step

	quit()
