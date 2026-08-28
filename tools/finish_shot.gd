extends Node3D

## Photographs one finish effect, on its own, from the side.
##
##     MJ_FINISH=5 godot --path . res://tools/finish_shot.tscn \
##       --fixed-fps 60 --quit-after 120 --write-movie shots/finish/f.png
##
## `tools/probe_tournament.gd` can tell you that an effect *fired*; only frames
## can tell you what it looked like, and rendering a whole race to see one second
## of it costs a thousand frames of encoding to keep sixty. So this stands a
## marble on a plain deck, detonates the effect named by `MJ_FINISH`, and holds
## the camera still — the same trade `tools/course_shot.gd` makes for course
## dressing.
##
## It is deliberately not the race: no runoff, no other marbles, no chase rig.
## What it answers is "is the effect the right size, colour and length", which
## is a question about the effect and not about the round it lands in.

## Which entry of `PlayerProfile.FINISHES` to fire. Supernova by default — the
## loudest one, and so the one whose scale is most likely to be wrong.
const DEFAULT_FINISH := 5

## Where the camera stands. Back and up a little, looking at the detonation
## point, roughly where the chase rig sits when a marble crosses the line.
const CAMERA_POSITION := Vector3(0.0, 3.2, 9.5)

## A beat of nothing before the effect fires, so the first frames show the
## unlit deck and the jump to full brightness is visible in the sequence.
const DELAY := 0.25

var _age := 0.0
var _fired := false


func _ready() -> void:
	_build_deck()
	_build_light()
	_build_camera()
	_build_marble()


func _process(delta: float) -> void:
	_age += delta
	if _fired or _age < DELAY:
		return
	_fired = true

	var id := DEFAULT_FINISH
	var raw := OS.get_environment("MJ_FINISH")
	if raw != "":
		id = int(raw)

	var style := PlayerProfile.finish_by_id(id)
	if style.is_empty():
		push_error("MJ_FINISH=%d is not an id in PlayerProfile.FINISHES" % id)
		return

	print("firing finish effect %d (%s)" % [id, style["name"]])
	var effect := FinishEffect.create(style, PlayerProfile.equipped_colour())
	add_child(effect)


func _build_deck() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.30, 0.32, 0.36)
	plane.material = material

	var deck := MeshInstance3D.new()
	deck.mesh = plane
	add_child(deck)


## One directional light, dim enough that the effect's own flash is the
## brightest thing in frame — which is the point of looking at it at all.
func _build_light() -> void:
	var light := DirectionalLight3D.new()
	light.light_energy = 0.55
	light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	add_child(light)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.09, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.27, 0.32)
	environment.ambient_light_energy = 0.6

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = CAMERA_POSITION
	camera.look_at_from_position(CAMERA_POSITION, Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)


## A stand-in for the marble that just crossed. Static, because the effect does
## not move with it and this is a picture of the effect.
func _build_marble() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0

	var material := StandardMaterial3D.new()
	material.albedo_color = PlayerProfile.equipped_colour()
	MarbleSkin.apply(material, PlayerProfile.equipped_skin_data())
	sphere.material = material

	var marble := MeshInstance3D.new()
	marble.mesh = sphere
	marble.position = Vector3(0.0, 0.5, 0.0)
	add_child(marble)
