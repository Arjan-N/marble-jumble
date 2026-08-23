class_name HomeScreen
extends Control

const RACE_SCENE := "res://scenes/main.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"
const LOGO_TEXTURE := preload("res://assets/ui/home_logo.svg")
const ICON_SCRIPT := preload("res://scripts/ui/home_icon.gd")

const CREAM := Color(1.0, 0.965, 0.86)
const INK := Color(0.075, 0.032, 0.018)
const YELLOW := Color(1.0, 0.69, 0.06)
const BLUE := Color(0.055, 0.38, 0.78)
const PURPLE := Color(0.47, 0.18, 0.76)
const GREEN := Color(0.30, 0.72, 0.12)
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
	var menu := Button.new()
	menu.anchor_left = 0.035
	menu.anchor_top = 0.025
	menu.offset_right = 76.0
	menu.offset_bottom = 76.0
	menu.add_theme_stylebox_override("normal", _panel_style(BLUE, 5, 18, 7))
	menu.add_theme_stylebox_override("hover", _panel_style(BLUE.lightened(0.08), 5, 18, 7))
	menu.add_theme_stylebox_override("pressed", _panel_style(BLUE.darkened(0.12), 5, 18, 4))
	menu.add_theme_stylebox_override("focus", _panel_style(BLUE, 5, 18, 7))
	var menu_icon := _icon(ICON_SCRIPT.Kind.MENU, CREAM, 46.0)
	menu_icon.position = Vector2(15, 15)
	menu.add_child(menu_icon)
	menu.pressed.connect(func() -> void: _show_toast("Menu coming soon"))
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu)

	var currency := PanelContainer.new()
	currency.anchor_left = 1.0
	currency.anchor_right = 1.0
	currency.anchor_top = 0.025
	currency.offset_left = -278.0
	currency.offset_right = -18.0
	currency.offset_bottom = 76.0
	currency.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.085, 0.035, 0.97), 5, 20, 7))
	currency.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(currency)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.add_theme_constant_override("margin_left", 8)
	row.add_theme_constant_override("margin_right", 7)
	currency.add_child(row)

	var coin := _icon(ICON_SCRIPT.Kind.COIN, CREAM, 48.0)
	coin.custom_minimum_size = Vector2(48, 48)
	row.add_child(coin)

	var amount := Label.new()
	amount.text = "1,250"
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override("font_size", 23)
	amount.add_theme_color_override("font_color", CREAM)
	amount.add_theme_color_override("font_outline_color", INK)
	amount.add_theme_constant_override("outline_size", 3)
	row.add_child(amount)

	var plus := Button.new()
	plus.custom_minimum_size = Vector2(52, 52)
	plus.add_theme_stylebox_override("normal", _panel_style(GREEN, 4, 26, 3))
	plus.add_theme_stylebox_override("hover", _panel_style(GREEN.lightened(0.08), 4, 26, 3))
	plus.add_theme_stylebox_override("pressed", _panel_style(GREEN.darkened(0.12), 4, 26, 3))
	plus.add_theme_stylebox_override("focus", _panel_style(GREEN, 4, 26, 3))
	var plus_icon := _icon(ICON_SCRIPT.Kind.PLUS, CREAM, 34.0)
	plus_icon.position = Vector2(9, 9)
	plus.add_child(plus_icon)
	plus.pressed.connect(func() -> void: _show_toast("Shop coming soon"))
	row.add_child(plus)

func _build_logo() -> void:
	var logo := TextureRect.new()
	logo.texture = LOGO_TEXTURE
	logo.anchor_left = 0.07
	logo.anchor_right = 0.93
	logo.anchor_top = 0.105
	logo.anchor_bottom = 0.315
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

func _build_marble_view() -> void:
	_marble_view = SubViewportContainer.new()
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
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.78, 0.58)
	env.ambient_light_energy = 0.72
	environment.environment = env
	world.add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-32.0, -25.0, 0.0)
	light.light_color = Color(1.0, 0.88, 0.72)
	light.light_energy = 1.35
	world.add_child(light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.4
	camera.position = Vector3(0.0, 1.55, 10.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.80, 0.0), Vector3.UP)
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
	row.offset_top = -160.0
	row.offset_bottom = -16.0
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(row)

	var marble := _nav_button("MARBLE", func() -> void: _show_toast("Marble collection coming soon"), BLUE, false, ICON_SCRIPT.Kind.MARBLE)
	marble.size_flags_stretch_ratio = 1.0
	row.add_child(marble)

	var start := _nav_button("START", _on_start_pressed, YELLOW, true, -1)
	start.size_flags_stretch_ratio = 1.42
	row.add_child(start)

	var store := _nav_button("STORE", func() -> void: get_tree().change_scene_to_file(SHOP_SCENE), PURPLE, false, ICON_SCRIPT.Kind.CART)
	store.size_flags_stretch_ratio = 1.0
	row.add_child(store)

func _nav_button(label: String, on_pressed: Callable, fill: Color, emphasised: bool, icon_kind: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 126 if emphasised else 118)
	button.add_theme_stylebox_override("normal", _panel_style(fill, 6, 22, 8))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.08), 6, 22, 8))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.14), 6, 22, 4))
	button.add_theme_stylebox_override("focus", _panel_style(fill, 6, 22, 8))
	button.pressed.connect(on_pressed)

	if icon_kind >= 0:
		var icon := _icon(icon_kind, CREAM, 54.0 if not emphasised else 44.0)
		icon.anchor_left = 0.5
		icon.anchor_top = 0.08
		icon.position = Vector2(-27, 4)
		button.add_child(icon)

	var text := Label.new()
	text.text = label
	text.anchor_left = 0.0
	text.anchor_right = 1.0
	text.anchor_top = 0.67 if not emphasised else 0.38
	text.anchor_bottom = 1.0
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 19 if not emphasised else 29)
	text.add_theme_color_override("font_color", INK if emphasised else CREAM)
	text.add_theme_color_override("font_outline_color", CREAM if emphasised else INK)
	text.add_theme_constant_override("outline_size", 5)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(text)
	return button

func _icon(kind: int, fill: Color, side: float) -> HomeIcon:
	var icon := HomeIcon.new()
	icon.kind = kind
	icon.fill = fill
	icon.custom_minimum_size = Vector2(side, side)
	icon.size = Vector2(side, side)
	return icon

func _panel_style(fill: Color, border: int, radius: int, shadow: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border)
	style.border_color = INK
	style.shadow_color = Color(0.03, 0.012, 0.006, 0.72)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0.0, 6.0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(RACE_SCENE)
