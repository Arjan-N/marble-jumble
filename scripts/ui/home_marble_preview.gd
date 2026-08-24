class_name HomeMarblePreview
extends SubViewportContainer

## The player's marble on the Home screen — the same `Marble` the race
## simulates, rendered into the UI through a `SubViewport`.
##
## There is deliberately no second marble implementation here. `Marble` builds
## its own mesh and material in `_build`/`_build_material` (there is no marble
## scene file to instance), so this asks `Marble.create` for a real one and then
## strips everything that is gameplay rather than appearance: the collision
## shape, the trail, and physics processing. What is left is the authored mesh,
## the authored material and the equipped skin colour, unmodified — change the
## marble's look in `marble.gd` and this preview changes with it.
##
## The skin is read from `PlayerProfile` when Home is built, and the shop
## returns to Home through `change_scene_to_file`, so equipping a marble shows
## up here without this needing to watch for it.
##
## Nothing in `marble.gd`, `marble_tuning.gd` or the race is altered by this.

## Half the visible field, in marble radii. The marble is centred, so this is
## how much clear space surrounds it — enough for the contact shadow to spread
## without the ball itself shrinking away from the mock-up's proportions.
const VIEW_RADII := 2.2

## Average px per second across the design-space (720-wide) platform; the eased
## turnarounds below make the mid-platform speed about half again this. Rolling
## the ball along the stone is the only motion that reads — the skins are flat
## colours, so spinning a sphere on the spot changes nothing on screen.
const SPEED := 110.0

## Warm canyon light, matched to the backdrop rather than to any one course's
## lighting rig.
const AMBIENT := Color(1.0, 0.78, 0.58)
const KEY_LIGHT := Color(1.0, 0.88, 0.72)
## Light coming back up off the sunlit sandstone. Without it the underside falls
## to flat ambient and the ball looks cut out and dropped in.
const BOUNCE_LIGHT := Color(1.0, 0.72, 0.45)
## The marble's own roughness belongs to `marble.gd` and is not ours to change,
## so the raytraced pinpoint is damped at the light instead. Zero would read as
## matte clay and throw away the one cue that says "marble".
const KEY_SPECULAR := 0.3

## Comic-book ink, the same near-black `HomeScreen` outlines its panels with.
## Duplicated rather than referenced: `home_screen.gd` already depends on this
## class, and a `const` reaching back the other way has to resolve at parse time,
## which closes the cycle and fails to load. The project has no shared palette
## module yet — `home_icon.gd` carries a third, slightly different near-black.
const INK := Color(0.075, 0.032, 0.018)

## Thickness of the ink line in design-space pixels (720 wide). Sits at the
## chunky end of the band the rest of the screen uses: `HomeScreen` panel borders
## are 5px, its label outlines 4-5px, and the ink between the platform blocks in
## `play_surface.png` comes out at 2.5-4px once the mock-up is scaled down.
const OUTLINE_PX := 4.0

var _marble: Marble
var _outline: MeshInstance3D
var _shadow: MeshInstance3D
var _camera: Camera3D
var _viewport: SubViewport
var _radius_world := 0.45
var _radius := 68.0
var _side := 300.0
var _centre := Vector2.ZERO
var _left := 0.0
var _right := 0.0
var _distance := 0.0


static func create(colour: Color) -> HomeMarblePreview:
	var preview := HomeMarblePreview.new()
	preview._build(colour)
	return preview


func _build(colour: Color) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true

	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.handle_input_locally = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Smooths the one silhouette in here. Held at 2x: the Compatibility renderer
	# resolves a 4x multisampled target against a transparent background wrongly
	# and the marble comes out the complement of its own colour.
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)

	var world := Node3D.new()
	_viewport.add_child(world)
	world.add_child(_build_environment())
	world.add_child(_build_light())
	world.add_child(_build_bounce_light())

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# Looking down at roughly the angle the platform artwork is drawn from, so the
	# marble reads as a ball resting on the stone rather than a disc pasted onto
	# it, and its contact shadow has somewhere to fall.
	_camera.position = Vector3(0.0, 2.55, 6.0)
	_camera.look_at_from_position(_camera.position, Vector3.ZERO, Vector3.UP)
	world.add_child(_camera)

	_marble = _build_marble(colour)
	world.add_child(_marble)
	_outline = _build_outline()
	world.add_child(_outline)
	_shadow = _build_shadow()
	world.add_child(_shadow)


func _ready() -> void:
	# Impact detection is race bookkeeping and there is nothing here to hit, but
	# Godot re-enables physics processing on any node whose script defines
	# `_physics_process` as it enters the tree, so switching it off has to wait
	# until after that. `_process` stays on: the emission pulse is appearance.
	_marble.set_physics_process(false)


func _build_environment() -> WorldEnvironment:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = 0.72
	environment.environment = env
	return environment


func _build_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-32.0, -25.0, 0.0)
	light.light_color = KEY_LIGHT
	light.light_energy = 1.35
	light.light_specular = KEY_SPECULAR
	return light


## A dim warm fill from below, standing in for light thrown back off the stone.
func _build_bounce_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	# Up, and toward the side the key light throws the shadow onto.
	light.rotation_degrees = Vector3(53.0, 30.0, 0.0)
	light.light_color = BOUNCE_LIGHT
	# Enough to warm the underside, not enough to flatten the ball. At 0.4 the
	# lower half came up almost to the lit half and the form went out of it.
	light.light_energy = 0.22
	# Diffuse only. A fill that adds its own highlight defeats the point.
	light.light_specular = 0.0
	return light


## A real player marble with its gameplay stripped off. Everything that decides
## how it looks — mesh, material, rim, emission pulse, skin colour — is left
## exactly as `marble.gd` built it.
func _build_marble(colour: Color) -> Marble:
	var tuning := MarbleTuning.new()
	_radius_world = tuning.radius
	var marble := Marble.create(0, tuning, colour, true, "Home preview")

	marble.freeze = true
	marble.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	marble.gravity_scale = 0.0
	marble.can_sleep = true
	marble.continuous_cd = false

	for child in marble.get_children():
		# The collider would put a body in the physics space for no reason, and
		# the trail is a race-readability cue that has nothing to trail behind.
		if child is CollisionShape3D or child is MarbleTrail:
			marble.remove_child(child)
			child.queue_free()

	return marble


## The comic-book ink line every rock and block in the backdrop artwork carries,
## and the marble did not — which is what made it read as pasted on rather than
## painted in.
##
## An inverted hull, not a shader: a sphere a few screen pixels larger than the
## marble with its front faces culled, so only its back half survives the depth
## test and what is left over is a ring beyond the marble's silhouette. It stays
## opaque on purpose — it has to write depth for the marble to cover it, and
## making it transparent would drop it into the alpha pass alongside the contact
## shadow and leave the order between all three undefined.
##
## Nothing in `marble.gd` or the marble's material is touched by this. It sits at
## the origin as a sibling rather than a child because the marble never leaves
## the origin — travel is the Control moving, not the ball. Move the marble in
## world space and the outline comes off it.
func _build_outline() -> MeshInstance3D:
	var outline := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = _radius_world
	mesh.height = _radius_world * 2.0
	# Finer than the marble's own 16/8 (marble.gd:100). A hard black band makes
	# faceting explicit, and the marble spins while this does not, so two coarse
	# silhouettes would beat against each other and the line would throb as the
	# ball rolls.
	mesh.radial_segments = 48
	mesh.rings = 24
	outline.mesh = mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = INK
	material.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.material_override = material
	# No shadow-casting light in here today, but a back-face-only inflated sphere
	# is exactly the geometry that would throw a wrong one if anyone added one.
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.scale = Vector3.ONE * _outline_scale()
	return outline


## The camera is orthogonal and spans a fixed number of marble radii, so world
## units map to pixels at exactly `_radius / _radius_world` and a screen-space
## line width is just this much uniform inflation. Uniform positive scale keeps
## the winding, so `CULL_FRONT` still means back-faces-only.
func _outline_scale() -> float:
	return 1.0 + OUTLINE_PX / _radius


## Contact shadow, flat under the ball and thrown to the right by the same low
## sun the platform artwork is lit by.
func _build_shadow() -> MeshInstance3D:
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(_radius_world * 2.8, _radius_world * 1.6)
	shadow.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# A plain coloured quad reads as a grey rectangle lying on the stone. The
	# radial ramp is what makes it a shadow.
	material.albedo_texture = _shadow_gradient()
	shadow.material_override = material
	# Pulled forward and out to the side, or the shallow camera angle and the ink
	# line between them leave nothing of it showing past the ball.
	shadow.position = Vector3(_radius_world * 0.8, _shadow_height(), _radius_world * 0.5)
	shadow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	return shadow


## Below the ink line, not below the marble. The outline hangs a few pixels
## lower than the ball itself, and a quad at the ball's own base gets the hull's
## bottom cap punched through the middle of it as a disc of solid black —
## opaque geometry wins the depth test against an alpha-blended quad.
func _shadow_height() -> float:
	return -_radius_world * (_outline_scale() + 0.06)


func _shadow_gradient() -> GradientTexture2D:
	const SHADOW_INK := Color(0.16, 0.055, 0.02, 1.0)
	var ramp := Gradient.new()
	# Both default stops first, then the plateau. A new Gradient is black-to-white
	# and `add_point` renumbers, so setting the far stop after inserting sets the
	# inserted one instead and leaves an opaque white ring on the quad.
	ramp.set_color(0, Color(SHADOW_INK, 0.72))
	ramp.set_color(1, Color(SHADOW_INK, 0.0))
	# A plateau rather than a plain falloff. The camera is close to side-on, so a
	# ground quad's dense middle sits behind the ball and only its faint outer
	# edge clears the silhouette — a straight centre-to-nothing ramp leaves
	# nothing visible at all.
	ramp.add_point(0.72, Color(SHADOW_INK, 0.58))
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


## Sizes the preview so the marble lands on screen at `radius` pixels, resting
## at `centre`. The viewport spans a fixed number of marble radii, so the
## orthogonal camera and the container scale together.
func set_display(centre: Vector2, radius: float) -> void:
	_radius = radius
	_centre = centre
	_side = radius * 2.0 * VIEW_RADII
	size = Vector2(_side, _side)
	_camera.size = _radius_world * 2.0 * VIEW_RADII
	# Both are pinned to the on-screen radius, so they follow it here rather than
	# keeping whatever `_build` guessed from the default.
	_outline.scale = Vector3.ONE * _outline_scale()
	_shadow.position.y = _shadow_height()
	_place(centre.x)


## The stretch of platform the marble rolls along, in screen pixels.
func set_travel(left: float, right: float) -> void:
	_left = left
	_right = right
	_distance = clampf(_centre.x, left, right) - left


func _place(x: float) -> void:
	position = Vector2(x, _centre.y) - Vector2(_side, _side) * 0.5


func _process(delta: float) -> void:
	var span := _right - _left
	if span <= 0.0:
		return
	_distance += SPEED * delta
	# A cosine sweep rather than a triangle one: the marble still crosses and
	# comes back, but it eases into each turn instead of reversing at full speed.
	var phase := fmod(_distance, span * 2.0) / (span * 2.0)
	var offset := span * (1.0 - cos(TAU * phase)) * 0.5
	var previous := position.x
	_place(_left + offset)
	# Angle from distance travelled, not a fixed spin rate, so the ball rolls
	# rather than skids — and it is the real marble geometry doing the turning.
	_marble.rotate_z(-(position.x - previous) / _radius)
