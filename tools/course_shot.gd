extends Node3D

## Renders one station of a course, using the same environment and camera
## framing the race uses. The visual work in issue #3 is not answerable by
## arithmetic — you have to look at the frames.
##
##     MJ_STATION=3 godot --path . res://tools/course_shot.tscn \
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

const COURSE_SCRIPT := preload("res://scripts/course/volcano_course.gd")

## Where along the course to stand, one per section of Volcano Run. Pick one
## with the `MJ_STATION` environment variable; the default is the opening.
const STATIONS := [0.06, 0.20, 0.34, 0.50, 0.68, 0.79, 0.94]

## `ChaseCamera.Mode.OVERHEAD`'s constants, duplicated rather than imported:
## the tool has no marble to drive the real rig with, and a copy that drifts is
## a better failure than a fake `Marble` that drives the real one wrongly.
const PITCH := deg_to_rad(61.0)
const DISTANCE := 34.0
const FOV := 22.0

var _course: Course
var _camera: Camera3D
var _marbles: Array[Node3D] = []


func _ready() -> void:
	_course = COURSE_SCRIPT.new()
	add_child(_course)
	_course.build()

	_setup_environment()

	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.fov = FOV
	add_child(_camera)
	_camera.current = true

	for i in 6:
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

	_move_to(_requested_station())


## Clamped rather than validated: this is a look-at-it tool, and a typo that
## quietly shows you the opening is easier to spot in the frame than a crash is
## to read in a movie-writer log.
func _requested_station() -> int:
	var raw := OS.get_environment("MJ_STATION")
	return clampi(int(raw) if raw.is_valid_int() else 0, 0, STATIONS.size() - 1)


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

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-68.0, -22.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)


func _move_to(station: int) -> void:
	var length := _course.curve.get_baked_length()
	var at := length * float(STATIONS[station])
	var aim := _course.curve.sample_baked(at)
	var ahead := _course.curve.sample_baked(minf(at + 2.0, length))
	var behind := _course.curve.sample_baked(maxf(at - 2.0, 0.0))

	var tangent := ahead - behind
	tangent.y = 0.0
	tangent = tangent.normalized()

	_camera.global_position = (
		aim + tangent * (DISTANCE * cos(PITCH)) + Vector3.UP * (DISTANCE * sin(PITCH))
	)
	_camera.look_at(aim, Vector3.UP)
	print("station %d, ratio %.2f" % [station, STATIONS[station]])

	var across := tangent.cross(Vector3.UP)
	for i in _marbles.size():
		var offset := clampf(at - 6.0 + float(i) * 2.4, 0.0, length)
		_marbles[i].global_position = (
			_course.curve.sample_baked(offset)
			+ Vector3(0.0, 0.45, 0.0)
			+ across * (float(i % 3) - 1.0) * 1.2
		)
