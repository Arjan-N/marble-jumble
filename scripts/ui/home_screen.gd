class_name HomeScreen
extends Control

## Home screen visual system:
## - illustrated 2D Canyon background
## - one lightweight real 3D marble on a simple physical track
## - bold two-line comic-book logo
## - chunky illustrated-style top controls
## - three large bottom actions with START clearly dominant
##
## Keep the scene intentionally cheap: the visual richness comes from the
## authored background, while Godot renders only the marble and simple UI.

const RACE_SCENE := "res://scenes/main.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"

const LOGO_TOP_SIZE := 68
const LOGO_BOTTOM_SIZE := 76
const TOP_BUTTON_SIZE := 22
const CURRENCY_SIZE := 23
const NAV_SIZE := 22
const NAV_SMALL_SIZE := 16
const TOAST_SECONDS := 1.6

const INK := Color(0.075, 0.032, 0.018)
const CREAM := Color(1.0, 0.965, 0.86)
const YELLOW := Color(1.0, 0.69, 0.06)
const ORANGE := Color(0.96, 0.39, 0.07)
const BLUE := Color(0.055, 0.38, 0.78)
const PURPLE := Color(0.47, 0.18, 0.76)
const GREEN := Color(0.30, 0.72, 0.12)

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
	_build_top_bar()
	_build_logo()
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

func _build_top_bar() -> void:
	# Menu button: chunky, outlined, deliberately closer to the reference art
	# than a stock Godot button.
	var menu := Button.new()
	menu.text = "☰"
	menu.anchor_left = 0.035
	menu.anchor_top = 0.025
	menu.offset_right = 76.0
	menu.offset_bottom = 76.0
	menu.add_theme_font_size_override("font_size", 34)
	menu.add_theme_color_override("font_color", CREAM)
	menu.add_theme_color_override("font_outline_color", INK)
	menu.add_theme_constant_override("outline_size", 5)
	menu.add_theme_stylebox_override("normal", _panel_style(BLUE, 5, 18, 5))
	menu.add_theme_stylebox_override("hover", _panel_style(BLUE.lightened(0.08), 5, 18, 5))
	menu.add_theme_stylebox_override("pressed", _panel_style(BLUE.darkened(0.12), 5, 18, 5))
	menu.add_theme_stylebox_override("focus", _panel_style(BLUE, 5, 18, 5))
	menu.pressed.connect(func() -> void: _show_toast("Menu coming soon"))
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu)

	# Currency display: a small gold badge with a separate green plus button.
	var currency := PanelContainer.new()
	currency.anchor_left = 1.0
	currency.anchor_right = 1.0
	currency.anchor_top = 0.025
	currency.offset_left = -278.0
	currency.offset_right = -18.0
	currency.offset_bottom = 76.0
	currency.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.085, 0.035, 0.97), 5, 20, 5))
	currency.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(currency)

	var currency_row := HBoxContainer.new()
	currency_row.add_theme_constant_override("separation", 7)
	currency_row.add_theme_constant_override("margin_left", 8)
	currency_row.add_theme_constant_override("margin_right", 8)
	currency.add_child(currency_row)

	var coin := Label.new()
	coin.text = "★"
	coin.custom_minimum_size = Vector2(48, 48)
	coin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin.add_theme_font_size_override("font_size", 30)
	coin.add_theme_color_override("font_color", YELLOW)
	coin.add_theme_color_override("font_outline_color", INK)
	coin.add_theme_constant_override("outline_size", 4)
	currency_row.add_child(coin)

	var amount := Label.new()
	amount.text = "1,250"
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override("font_size", CURRENCY_SIZE)
	amount.add_theme_color_override("font_color", CREAM)
	amount.add_theme_color_override("font_outline_color", INK)
	amount.add_theme_constant_override("outline_size", 3)
	currency_row.add_child(amount)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(52, 52)
	plus.add_theme_font_size_override("font_size", 31)
	plus.add_theme_color_override("font_color", CREAM)
	plus.add_theme_color_override("font_outline_color", INK)
	plus.add_theme_constant_override("outline_size", 4)
	plus.add_theme_stylebox_override("normal", _panel_style(GREEN, 4, 26, 3))
	plus.add_theme_stylebox_override("hover", _panel_style(GREEN.lightened(0.08), 4, 26, 3))
	plus.add_theme_stylebox_override("pressed", _panel_style(GREEN.darkened(0.12), 4, 26, 3))
	plus.add_theme_stylebox_override("focus", _panel_style(GREEN, 4, 26, 3))
	plus.pressed.connect(func() -> void: _show_toast("Shop coming soon"))
	currency_row.add_child(plus)

func _build_logo() -> void:
	# The logo sits slightly lower than the top HUD, leaving the canyon sky visible
	# around it. Pass 2 replaces these labels with authored logo artwork.
	var shadow_top := _logo_label("MARBLE", LOGO_TOP_SIZE, INK)
	shadow_top.anchor_left = 0.08
	shadow_top.anchor_right = 0.92
	shadow_top.anchor_top = 0.125
	shadow_top.anchor_bottom = 0.205
	shadow_top.offset_left = 5.0
	shadow_top.offset_top = 7.0
	shadow_top.offset_right = 5.0
	shadow_top.offset_bottom = 7.0
	add_child(shadow_top)

	var top := _logo_label("MARBLE", LOGO_TOP_SIZE, CREAM)
	top.anchor_left = 0.08
	top.anchor_right = 0.92
	top.anchor_top = 0.121
	top.anchor_bottom = 0.201
	add_child(top)

	var shadow_bottom := _logo_label("JUMBLE", LOGO_BOTTOM_SIZE, INK)
	shadow_bottom.anchor_left = 0.055
	shadow_bottom.anchor_right = 0.945
	shadow_bottom.anchor_top = 0.185
	shadow_bottom.anchor_bottom = 0.285
	shadow_bottom.offset_left = 5.0
	shadow_bottom.offset_top = 8.0
	shadow_bottom.offset_right = 5.0
	shadow_bottom.offset_bottom = 8.0
	add_child(shadow_bottom)

	var bottom := _logo_label("JUMBLE", LOGO_BOTTOM_SIZE, ORANGE)
	bottom.anchor_left = 0.055
	bottom.anchor_right = 0.945
	bottom.anchor_top = 0.181
	bottom.anchor_bottom = 0.281
	add_child(bottom)

func _logo_label(text_value: String, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 9)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.005, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _build_marble_view() -> void:
	_marble_view = SubViewportContainer.new()
	# The reference puts the marble low in the canyon, immediately above the
	# navigation. Keep the viewport compact so it does not cover the background.
	_marble_view.anchor_left = 0.035
	_marble_view.anchor_right = 0.965
	_marble_view.anchor_top = 0.535
	_marble_view.anchor_bottom = 0.775
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
	_toast.anchor_top = 0.78
	_toast.anchor_bottom = 0.78
	_toast.offset_top = 6.0
	_toast.offset_bottom = 42.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", CREAM)
	_toast.add_theme_color_override("font_outline_color", INK)
	_toast.add_theme_constant_override("outline_size", 5)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)

func _show_toast(text_value: String) -> void:
	_toast.text = text_value
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS

func _build_nav() -> void:
	var row := HBoxContainer.new()
	row.anchor_left = 0.035
	row.anchor_right = 0.965
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	# Slightly lower and taller: the bottom controls should feel like a physical
	# game panel, not a toolbar floating over the scene.
	row.offset_top = -154.0
	row.offset_bottom = -18.0
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(row)

	var marble := _nav_button("●\nMARBLE", func() -> void: _show_toast("Marble collection coming soon"), BLUE, false)
	marble.size_flags_stretch_ratio = 1.0
	row.add_child(marble)

	var start := _nav_button("START", _on_start_pressed, YELLOW, true)
	start.size_flags_stretch_ratio = 1.38
	row.add_child(start)

	var store := _nav_button("▣\nSTORE", func() -> void: get_tree().change_scene_to_file(SHOP_SCENE), PURPLE, false)
	store.size_flags_stretch_ratio = 1.0
	row.add_child(store)

func _nav_button(label: String, on_pressed: Callable, fill: Color, emphasised: bool) -> Button:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 122 if emphasised else 112)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", NAV_SIZE if emphasised else NAV_SMALL_SIZE)
	button.add_theme_color_override("font_color", INK if emphasised else CREAM)
	button.add_theme_color_override("font_hover_color", INK if emphasised else CREAM)
	button.add_theme_color_override("font_pressed_color", INK if emphasised else CREAM)
	button.add_theme_color_override("font_outline_color", CREAM if emphasised else INK)
	button.add_theme_constant_override("outline_size", 4)

	var normal := _panel_style(fill, 5, 22, 7)
	var hover := _panel_style(fill.lightened(0.08), 5, 22, 7)
	var pressed := _panel_style(fill.darkened(0.14), 5, 22, 4)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.pressed.connect(on_pressed)
	return button

func _panel_style(fill: Color, border: int, radius: int, shadow: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	style.border_color = INK
	style.shadow_color = Color(0.03, 0.012, 0.006, 0.65)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0.0, 5.0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(RACE_SCENE)
