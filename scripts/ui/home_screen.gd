class_name HomeScreen
extends Control

## Polished Home screen: illustrated 2D Canyon + one lightweight 3D marble.
## The background is authored artwork; the marble and its simple track are real
## 3D so the home screen previews the same physical marble language as races.

const RACE_SCENE := "res://scenes/main.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"

const TITLE_FONT_SIZE := 58
const NAV_FONT_SIZE := 23
const TOAST_SECONDS := 1.6

var _backdrop: HomeBackdrop
var _marble_view: SubViewportContainer
var _marble_root: HomeMarble3D
var _toast: Label
var _toast_left := 0.0

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_backdrop()
	_build_title()
	_build_marble_view()
	_build_toast()
	_build_nav()

func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.4, 0.0, 1.0)

func _build_backdrop() -> void:
	_backdrop = HomeBackdrop.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)

func _build_title() -> void:
	# Offset shadow first: the logo should read like an illustrated game mark,
	# not a stock Godot Label.
	var shadow := Label.new()
	shadow.text = "MARBLE JUMBLE"
	shadow.set_anchors_preset(Control.PRESET_CENTER_TOP)
	shadow.position = Vector2(4.0, 68.0)
	shadow.size = Vector2(0.0, 86.0)
	shadow.grow_horizontal = Control.GROW_DIRECTION_BOTH
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	shadow.add_theme_color_override("font_color", Color(0.12, 0.055, 0.035, 0.9))
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	var title := shadow.duplicate() as Label
	title.position = Vector2(0.0, 64.0)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78))
	title.add_theme_color_override("font_outline_color", Color(0.10, 0.045, 0.025))
	title.add_theme_constant_override("outline_size", 10)
	add_child(title)

func _build_marble_view() -> void:
	_marble_view = SubViewportContainer.new()
	_marble_view.anchor_left = 0.035
	_marble_view.anchor_right = 0.965
	_marble_view.anchor_top = 0.48
	_marble_view.anchor_bottom = 0.77
	_marble_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marble_view.stretch = true
	add_child(_marble_view)

	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	_marble_view.add_child(viewport)

	var world := Node3D.new()
	viewport.add_child(world)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.78, 0.58)
	env.ambient_light_energy = 0.72
	environment.environment = env
	world.add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38.0, -25.0, 0.0)
	light.light_color = Color(1.0, 0.88, 0.72)
	light.light_energy = 1.25
	light.shadow_enabled = false
	world.add_child(light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.0
	camera.position = Vector3(0.0, 3.0, 10.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	world.add_child(camera)

	_marble_root = HomeMarble3D.create(PlayerProfile.equipped_colour())
	world.add_child(_marble_root)

func _build_toast() -> void:
	_toast = Label.new()
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 0.77
	_toast.anchor_bottom = 0.77
	_toast.offset_top = 8.0
	_toast.offset_bottom = 42.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", Color(1.0, 0.98, 0.88))
	_toast.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.02))
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)

func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS

func _build_nav() -> void:
	var row := HBoxContainer.new()
	row.anchor_left = 0.055
	row.anchor_right = 0.945
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_top = -132.0
	row.offset_bottom = -30.0
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(row)

	row.add_child(_nav_button("MARBLE", func() -> void: _show_toast("Coming soon"), false))
	row.add_child(_nav_button("START", _on_start_pressed, true))
	row.add_child(_nav_button("STORE", func() -> void: get_tree().change_scene_to_file(SHOP_SCENE), false))

func _nav_button(label: String, on_pressed: Callable, emphasised: bool) -> Button:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 70 if emphasised else 60)
	button.add_theme_font_size_override("font_size", NAV_FONT_SIZE if emphasised else NAV_FONT_SIZE - 3)
	button.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.90))

	var fill := Color(0.95, 0.43, 0.12) if emphasised else Color(0.16, 0.075, 0.045, 0.94)
	var normal := _button_style(fill, 5, 10)
	var hover := _button_style(fill.lightened(0.08), 5, 10)
	var pressed := _button_style(fill.darkened(0.16), 5, 10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.pressed.connect(on_pressed)
	return button

func _button_style(fill: Color, border: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	style.border_color = Color(0.10, 0.045, 0.025)
	style.shadow_color = Color(0.06, 0.025, 0.015, 0.45)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 4.0)
	return style

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(RACE_SCENE)
