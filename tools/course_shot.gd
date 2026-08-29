extends Node3D

## Renders one station of a course, using the same environment and camera
## framing the race uses. The visual work in issue #3 is not answerable by
## arithmetic — you have to look at the frames.
##
##     MJ_COURSE=canyon MJ_STATION=3 godot --path . res://tools/course_shot.tscn \
##       --fixed-fps 60 --write-movie shots/s3.png --quit-after 8
##
## One station per run, deliberately. An earlier version swept all seven in a
## single 42-frame recording, and the movie writer did not stay in step with
## `_process`: the last two stations wrote identical frames despite the camera
## demonstrably being in two different places. A separate run each costs a
## couple of seconds and cannot lie about which station you are looking at.
##
## Marbles are stand-in spheres, not `Marble` bodies: this tool is about what
## the environment looks like, and real marbles would have rolled away from
## the station by the time the frame is written.

## Which course to stand on, picked with `MJ_COURSE`. Volcano stays the default
## so existing shot runs keep meaning what they meant, but the tool was never
## really volcano-specific — every course wants looking at, and pointing it at
## one by editing a `preload` meant the edit had to be undone afterwards.
const COURSES := {
	"volcano": preload("res://scripts/course/volcano_course.gd"),
	"canyon": preload("res://scripts/course/course_builder.gd"),
	"jungle": preload("res://scripts/course/jungle_course.gd"),
	"foundry": preload("res://scripts/course/foundry_course.gd"),
	"orbital": preload("res://scripts/course/orbital_course.gd"),
	"slope": preload("res://scripts/course/slope_course.gd"),
	"glacier": preload("res://scripts/course/glacier_fault_course.gd"),
	"temple": preload("res://scripts/course/temple_run_course.gd"),
	"river": preload("res://scripts/course/jungle_river_course.gd"),
}

## Where along the course to stand, one per section of Volcano Run. Pick one
## with the `MJ_STATION` environment variable; the default is the opening.
const STATIONS := [0.06, 0.20, 0.34, 0.50, 0.68, 0.79, 0.94]

## `ChaseCamera.Mode.LOW`'s constants, duplicated rather than imported: the tool
## has no marble to drive the real rig with, and a copy that drifts is a better
## failure than a fake `Marble` that drives the real one wrongly.
##
## These used to be `Mode.OVERHEAD`'s. That mode is a spike; `Mode.LOW` is what
## `ChaseCamera.DEFAULT_MODE` actually races in, and the difference is not
## cosmetic — at 61 degrees the frame is almost top-down and shows no horizon at
## all, so every shot taken through it said the sky and the distant rock were
## invisible when in the real game they fill the top third.
const PITCH := deg_to_rad(32.0)
const DISTANCE := 30.0
const FOV := 26.0


## Rig overrides, in degrees and metres: `MJ_PITCH`, `MJ_DISTANCE`, `MJ_FOV`.
##
## The race rig is locked, so these are not for reframing the game — they are for
## answering questions the locked frame cannot, like what shape a course actually
## is out past the edges of the shot. Unset, every one of them leaves `Mode.LOW`
## exactly as it races.
static func _rig(name: String, fallback: float) -> float:
	var raw := OS.get_environment(name)
	return raw.to_float() if raw.is_valid_float() else fallback

var _course: Course
var _camera: Camera3D
var _marbles: Array[Node3D] = []


func _ready() -> void:
	_course = _requested_course().new()
	add_child(_course)
	_course.build()

	# The finish dressing is hung off `FinishZone`, not built by `build`, so a
	# course photographed without one has no finish in it — which is the one
	# stretch this tool is most often pointed at. Nothing else about the zone
	# does anything here: it has no field registered, so its trigger and its
	# slowdown ramp have nothing to act on.
	var finish := FinishZone.create(_course)
	_course.add_child(finish)

	_setup_environment()

	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.fov = _rig("MJ_FOV", FOV)
	add_child(_camera)
	_camera.current = true

	# `MJ_BARE=1` renders the environment with nothing in it. It exists for the
	# grounding test in the Jungle River brief — "with no UI, no marble and no
	# debug elements, does the frame still read as an environment containing a
	# racing route, or as a floating track with decoration around it?" — which is
	# a question the stand-in marbles quietly answer for you, because six spheres
	# sitting on a surface are themselves a cue that the surface is ground.
	var bare := OS.get_environment("MJ_BARE") == "1"

	for i in (0 if bare else 6):
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.45
		sphere.height = 0.9
		ball.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = [
			Color(0.25, 0.78, 1.0), Color(0.9, 0.25, 0.25), Color(0.95, 0.85, 0.2),
			Color(0.3, 0.85, 0.4), Color(0.85, 0.4, 0.9), Color(0.95, 0.95, 0.95),
		][i]
		ball.material_override = material
		add_child(ball)
		_marbles.append(ball)

	_move_to_fraction(_requested_fraction())


func _requested_course() -> GDScript:
	var raw := OS.get_environment("MJ_COURSE").to_lower()
	return COURSES.get(raw, COURSES["volcano"])


## Clamped rather than validated: this is a look-at-it tool, and a typo that
## quietly shows you the opening is easier to spot in the frame than a crash is
## to read in a movie-writer log.
func _requested_station() -> int:
	var raw := OS.get_environment("MJ_STATION")
	return clampi(int(raw) if raw.is_valid_int() else 0, 0, STATIONS.size() - 1)


## `MJ_AT` overrides `MJ_STATION` with a raw fraction along the course, 0..1.
##
## A fraction of the *baked curve*, which is what `STATIONS` holds too — so it
## includes the starting ramp and the run-out and does not line up with the
## `[[fraction, ...]]` profiles a course is authored in. On `FoundryCourse` the
## curve is 384m against a 340m course, so a beat authored at 0.87 is at roughly
## 0.81 here.
##
## `STATIONS` is a fixed list sized to Volcano Run's sections, and every course
## added since has had beats that fall between two of them — there was no index
## that stood on `FoundryCourse`'s Turn Yard at all. Keeping the list as the
## default and letting a fraction override it means the existing shot runs still
## frame what they framed.
func _requested_fraction() -> float:
	var raw := OS.get_environment("MJ_AT")
	if raw.is_valid_float():
		return clampf(raw.to_float(), 0.0, 1.0)
	return STATIONS[_requested_station()]


## Copied from `race_manager.gd`'s `_setup_environment`, minus the HUD, sound
## and cut marker. Kept in sync by hand — if a shot's lighting looks unlike the
## game's, this is the first place to check.
func _setup_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.30, 0.47, 0.74)
	sky_material.sky_horizon_color = Color(0.85, 0.74, 0.60)
	sky_material.ground_bottom_color = Color(0.26, 0.18, 0.14)
	sky_material.ground_horizon_color = Color(0.62, 0.44, 0.31)

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.95
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 4.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.15
	environment.adjustment_contrast = 1.08

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-68.0, -22.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	_course.decorate_environment(environment, sun)


func _move_to_fraction(fraction: float) -> void:
	var length := _course.curve.get_baked_length()
	var at := length * fraction
	var aim := _course.curve.sample_baked(at)
	var ahead := _course.curve.sample_baked(minf(at + 2.0, length))
	var behind := _course.curve.sample_baked(maxf(at - 2.0, 0.0))

	var tangent := ahead - behind
	tangent.y = 0.0
	tangent = tangent.normalized()

	var pitch := deg_to_rad(_rig("MJ_PITCH", rad_to_deg(PITCH)))
	var distance := _rig("MJ_DISTANCE", DISTANCE)
	_camera.global_position = (
		aim + tangent * (distance * cos(pitch)) + Vector3.UP * (distance * sin(pitch))
	)
	_camera.look_at(aim, Vector3.UP)
	print("ratio %.3f" % [fraction])

	var across := tangent.cross(Vector3.UP)
	for i in _marbles.size():
		var offset := clampf(at - 6.0 + float(i) * 2.4, 0.0, length)
		_marbles[i].global_position = (
			_course.curve.sample_baked(offset)
			+ Vector3(0.0, 0.45, 0.0)
			+ across * (float(i % 3) - 1.0) * 1.2
		)
