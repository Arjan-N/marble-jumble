class_name MarbleRowView
extends SubViewportContainer

## A horizontal row of the tournament's actual marbles, rendered in 3D into the
## UI — the survivors row and the eliminated row of the end-of-round screen.
##
## Same approach as `home_marble_preview.gd`, and for the same reason: `Marble`
## builds its own mesh and material in `_build`/`_build_material`, so the only
## way to show a marble's real appearance (including a patterned skin from
## `marble_skin.gd`) is to ask `Marble.create` for one and strip the gameplay
## off it. Flat 2D circles would show the colour and lose the skin, which is the
## thing the player bought.
##
## Where this differs from the Home preview is that it holds up to twelve
## marbles at once, so they share a single `SubViewport` and a single camera
## rather than getting one each. The camera is orthogonal and centred, which
## makes the world-to-pixel mapping along the row exactly linear — that is what
## lets `cell_centre_x` hand out positions for the 2D overlays (rank captions,
## the YOU pill, the red crosses) without any unprojection.
##
## Nothing in `marble.gd`, `marble_tuning.gd` or the race is altered by this.

## Cell width in marble radii. At 2.5 the ball fills 80% of its cell, which is
## the proportion the mock-up is drawn at — chunky, with a visible gutter.
const CELL_RADII := 2.5

## How far the marbles turn, in radians per second. Slow: this is a results
## screen, and a patterned skin only needs to show that it is a sphere rather
## than a disc. Each marble gets a phase offset so the row does not spin as one
## rigid object.
const SPIN := 0.55

## Ink line thickness in design-space pixels, matching the 4px
## `home_marble_preview.gd` draws. The player's is heavier so the gold reads at
## this smaller size.
const OUTLINE_PX := 3.5
const PLAYER_OUTLINE_PX := 6.0

## The outline colour for a dimmed marble.
##
## `UIKit.INK` is within a hair of the panel's own fill, which is fine for a
## bright marble — the ball itself provides the contrast — but a dimmed one has
## a dark lower hemisphere, and with a near-black line around it the bottom of
## the ball merged into the plate and every eliminated marble looked as though
## it had a flat base. A lifted warm grey keeps the silhouette closed all the
## way round while still reading as ink.
const DIM_INK := Color(0.30, 0.20, 0.18)

## Warm key light, in the same family as the Home preview's.
##
## Dimmer than Home's, and tonemapped (`_build_environment`), because this row
## shows up to twelve marbles rather than one. Home only ever renders whatever
## the player has equipped; here a bright saturated skin — Ocean's cyan, Toxic's
## green — is guaranteed to be on screen, and the Home rig's ambient + key sum
## above 2.0 drives every channel of those past 1.0 and clips them to flat
## white. Backing the lights off and letting the tonemapper roll the highlights
## off instead keeps them recognisably their own colour.
const AMBIENT := Color(1.0, 0.92, 0.86)
const KEY_LIGHT := Color(1.0, 0.97, 0.92)
const KEY_SPECULAR := 0.35
## Light coming back up off the plate, standing in for a soft floor bounce.
const BOUNCE_LIGHT := Color(1.0, 0.86, 0.72)
const AMBIENT_ENERGY := 0.62
const KEY_ENERGY := 1.15

## Applied to the eliminated row. Desaturated and darkened rather than faded:
## the brief is that they stay recognisable, and alpha over a dark panel would
## take the pattern with it.
##
## Held deliberately light. At 0.62 the unlit lower half of a dimmed marble came
## out at about the panel's own fill value and the ball appeared to have a flat
## bottom, because its ink outline had nothing left to separate it from the
## plate. The red crosses are what say "out"; this only has to say "not in the
## running".
const DIM_SHADER := "shader_type canvas_item;
uniform float grey : hint_range(0.0, 1.0) = 0.45;
uniform float dim : hint_range(0.0, 1.0) = 0.80;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luma = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	source.rgb = mix(source.rgb, vec3(luma), grey) * dim;
	COLOR = source * COLOR;
}"

var _viewport: SubViewport
var _camera: Camera3D
var _world: Node3D
var _marbles: Array[Marble] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _outlines: Array[MeshInstance3D] = []
var _outline_widths: PackedFloat32Array = PackedFloat32Array()
var _radius_world := 0.45
var _count := 0
var _row_width_world := 1.0
## The size `layout` was last told to use — see the note there on why this is
## kept rather than read back off `size`.
var _pixel_size := Vector2.ONE


## `entries` are roster dictionaries straight off the race — `colour`, `name`,
## `is_player`, `skin` — in the order they should read left to right.
static func create(entries: Array, dimmed: bool) -> MarbleRowView:
	var view := MarbleRowView.new()
	view._build(entries, dimmed)
	return view


func _build(entries: Array, dimmed: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_count = entries.size()

	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	# Its own 3D world, or this row's marbles and the other row's land in the
	# same space and each camera renders both sets on top of each other. A
	# `SubViewport` inherits its parent viewport's `World3D` unless told
	# otherwise; `home_marble_preview.gd` never had to say so because Home only
	# ever builds one of these, and the results screen builds two.
	_viewport.own_world_3d = true
	_viewport.handle_input_locally = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# 2x for the same reason `home_marble_preview.gd` caps it there: the
	# Compatibility renderer resolves 4x multisampling against a transparent
	# background wrongly and the marbles come out inverted.
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)

	_world = Node3D.new()
	_viewport.add_child(_world)
	_world.add_child(_build_environment())
	_world.add_child(_build_light())
	_world.add_child(_build_bounce_light())

	var tuning := MarbleTuning.new()
	_radius_world = tuning.radius
	var cell := _radius_world * CELL_RADII
	_row_width_world = maxf(cell * float(maxi(_count, 1)), 0.001)

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	# Only a slight tilt, and only about X: any yaw would break the linear
	# screen-x mapping that `cell_centre_x` depends on.
	#
	# There is deliberately no ground-shadow quad here, unlike the Home preview.
	# Home looks down at roughly 23 degrees, where a flat quad under the ball
	# reads as a shadow; this camera is nearly side-on and the same quad comes
	# out edge-on, as a hard dark line across the bottom of every marble that
	# looks like the ball has been sliced off. These sit on a dark plate behind
	# a thick ink outline and do not need one.
	_camera.position = Vector3(0.0, _radius_world * 0.9, 6.0)
	_camera.look_at_from_position(_camera.position, Vector3.ZERO, Vector3.UP)
	_world.add_child(_camera)

	for i in _count:
		var entry: Dictionary = entries[i]
		var is_player: bool = bool(entry.get("is_player", false))
		var x := (float(i) + 0.5 - float(_count) * 0.5) * cell

		var marble := _build_marble(
			i, tuning, entry.get("colour", Color.WHITE), is_player, entry.get("skin", {})
		)
		marble.position = Vector3(x, 0.0, 0.0)
		_world.add_child(marble)
		_marbles.append(marble)
		_phases.append(float(i) * 0.83)

		var outline_px := PLAYER_OUTLINE_PX if is_player else OUTLINE_PX
		var outline_colour := UIKit.INK
		if is_player:
			outline_colour = UIKit.GOLD
		elif dimmed:
			outline_colour = DIM_INK
		var outline := _build_outline(outline_colour)
		outline.position = Vector3(x, 0.0, 0.0)
		_world.add_child(outline)
		_outlines.append(outline)
		_outline_widths.append(outline_px)

	if dimmed:
		var shader := Shader.new()
		shader.code = DIM_SHADER
		var shader_material := ShaderMaterial.new()
		shader_material.shader = shader
		material = shader_material


func _ready() -> void:
	# Godot re-enables physics processing on any node whose script defines
	# `_physics_process` as it enters the tree, so — as in the Home preview —
	# switching it off has to wait until after that. `_process` stays on: the
	# emission pulse is appearance, not bookkeeping.
	for marble in _marbles:
		marble.set_physics_process(false)


func _build_environment() -> WorldEnvironment:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = AMBIENT_ENERGY
	# A gentle filmic roll-off rather than clipping. `tonemap_white` is set high
	# on purpose: the curve then only bites near the top of the range, where the
	# blow-out was, and leaves the midtones — which is where a marble's colour
	# actually lives — close to linear. A tighter white point fixes the clipping
	# but takes the saturation with it, and PROJECT.md section 8 asks for bright
	# saturated marbles.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 4.0
	environment.environment = env
	return environment


func _build_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-34.0, -22.0, 0.0)
	light.light_color = KEY_LIGHT
	light.light_energy = KEY_ENERGY
	light.light_specular = KEY_SPECULAR
	return light


## A dim fill from below.
##
## Without it the underside of every ball falls to flat ambient, and against a
## near-black plate that reads as the bottom of the marble having been sliced
## off — most obviously on the dimmed eliminated row, where there is least light
## to spare. `home_marble_preview.gd` carries the same light for the same
## reason. Diffuse only: a fill that adds its own highlight defeats the point.
func _build_bounce_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(58.0, 24.0, 0.0)
	light.light_color = BOUNCE_LIGHT
	light.light_energy = 0.30
	light.light_specular = 0.0
	return light


## A real marble with its gameplay stripped off — collider and trail removed,
## frozen, no gravity. Mesh, material, rim and skin are exactly what
## `marble.gd` built.
func _build_marble(
	index: int, tuning: MarbleTuning, colour: Color, is_player: bool, skin: Dictionary
) -> Marble:
	var marble := Marble.create(index, tuning, colour, is_player, "Results", skin)
	marble.freeze = true
	marble.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	marble.gravity_scale = 0.0
	marble.can_sleep = true
	marble.continuous_cd = false

	for child in marble.get_children():
		if child is CollisionShape3D or child is MarbleTrail:
			marble.remove_child(child)
			child.queue_free()

	return marble


## The comic-book ink line, as an inverted hull rather than a shader — see the
## long note in `home_marble_preview.gd._build_outline` for why it is opaque and
## front-face-culled. It sits as a sibling because it must not inherit the
## marble's spin: a rotating outline would make the line's own faceting crawl.
func _build_outline(colour: Color) -> MeshInstance3D:
	var outline := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = _radius_world
	mesh.height = _radius_world * 2.0
	mesh.radial_segments = 48
	mesh.rings = 24
	outline.mesh = mesh

	var outline_material := StandardMaterial3D.new()
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.albedo_color = colour
	outline_material.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.material_override = outline_material
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return outline


## Sizes the control and its camera together so the row exactly fills
## `pixel_size` in width. The camera is orthogonal and its `size` is the
## vertical extent, so the horizontal extent is `size * aspect` — solving that
## for the row's world width is all this is.
##
## The caller passes the size it wants rather than this reading `size` back off
## the control, and the same argument feeds the camera, the cell positions and
## the ink line width. `stretch` keeps the `SubViewport` matched to the control
## (it refuses to be sized by hand while that is on), and everything downstream
## is derived from one number instead of from whatever the control happens to
## report mid-layout.
func layout(pixel_size: Vector2) -> void:
	if _camera == null or pixel_size.x <= 0.0 or pixel_size.y <= 0.0:
		return
	size = pixel_size
	_pixel_size = pixel_size
	_camera.size = _row_width_world * pixel_size.y / pixel_size.x
	# Pinned to the on-screen radius, so the ink line is a constant number of
	# pixels wide whatever size the row ends up.
	var px_per_world := pixel_size.x / _row_width_world
	for i in _outlines.size():
		_outlines[i].scale = (
			Vector3.ONE * (1.0 + _outline_widths[i] / (_radius_world * px_per_world))
		)


## Centre of cell `index` in this control's local pixels. Exact, because the
## camera is orthogonal and centred with no yaw.
func cell_centre_x(index: int) -> float:
	if _count <= 0:
		return _pixel_size.x * 0.5
	return _pixel_size.x * (float(index) + 0.5) / float(_count)


## On-screen marble radius in pixels, for placing the overlays that have to
## clear the ball.
func marble_radius_px() -> float:
	if _row_width_world <= 0.0:
		return 0.0
	return _radius_world * _pixel_size.x / _row_width_world


func _process(delta: float) -> void:
	for i in _marbles.size():
		# About Y so the pattern sweeps past the camera; the phase offset keeps
		# the row from reading as one rigid object turning.
		_marbles[i].rotate_y(SPIN * delta * (1.0 + 0.12 * sin(_phases[i])))
