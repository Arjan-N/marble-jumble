class_name HomeScreen
extends Control

const RACE_SCENE := "res://scenes/main.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"
const LOGO_TEXTURE := preload("res://assets/ui/marble_jumble_logo.png")
const COIN_INDICATOR_TEXTURE := preload("res://assets/ui/coins_indicator.png")
const MARBLE_BUTTON_TEXTURE := preload("res://assets/ui/buttons/marble_button.png")
const START_BUTTON_TEXTURE := preload("res://assets/ui/buttons/start_button.png")
const STORE_BUTTON_TEXTURE := preload("res://assets/ui/buttons/store_button.png")
const ICON_SCRIPT := preload("res://scripts/ui/home_icon.gd")

# The play area is laid out from the mock-up (docs/ui-reference/home.png,
# 1882x3344 — the same 9:16 as this viewport), so these are that image's own
# measurements expressed as fractions of the screen.
const MARBLE_RADIUS_FRACTION := 178.0 / 1882.0
const MARBLE_CENTRE_Y_FRACTION := 2113.0 / 3344.0
const MARBLE_REST_X_FRACTION := 896.0 / 1882.0
## How far either side of its resting spot the marble rolls. The mock-up is a
## still; the marble on Home has always moved, and this keeps it doing so
## without ever leaving the platform.
const MARBLE_TRAVEL_FRACTION := 0.26
const MARBLE_EDGE_MARGIN := 14.0

const CREAM := Color(1.0, 0.965, 0.86)
const INK := Color(0.075, 0.032, 0.018)
const BLUE := Color(0.055, 0.38, 0.78)
const TOAST_SECONDS := 1.6

var _backdrop: HomeBackdrop
var _play_surface: HomePlaySurface
var _marble: HomeMarblePreview
var _toast: Label
var _toast_left := 0.0
var _coins_label: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_backdrop()
	_build_top_bar()
	_build_logo()
	_build_play_area()
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

	# Sized from the reference mock-up, measured in this 720x1280 space: the
	# indicator is as tall as the menu button and shares its centre line, with a
	# 19px gutter to the right edge. The width follows from the artwork's own
	# 3.505:1 aspect, so the pill fills the box exactly and nothing is letterboxed.
	var currency := TextureRect.new()
	currency.texture = COIN_INDICATOR_TEXTURE
	currency.anchor_left = 1.0
	currency.anchor_right = 1.0
	currency.anchor_top = 0.025
	currency.offset_left = -254.0
	currency.offset_right = -19.0
	currency.offset_top = 4.5
	currency.offset_bottom = 71.5
	currency.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	currency.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	currency.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(currency)

	_coins_label = Label.new()
	_coins_label.text = "%d" % PlayerProfile.coins
	# The coin sits in the leftmost 24% of the artwork; the balance is centred in
	# the dark trough that follows it rather than left-aligned against the coin,
	# because this pill is a good deal longer than the one in the mock-up.
	_coins_label.anchor_left = 0.26
	_coins_label.anchor_right = 0.96
	_coins_label.anchor_top = 0.0
	_coins_label.anchor_bottom = 1.0
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins_label.add_theme_font_size_override("font_size", 30)
	_coins_label.add_theme_color_override("font_color", CREAM)
	_coins_label.add_theme_color_override("font_outline_color", INK)
	_coins_label.add_theme_constant_override("outline_size", 4)
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency.add_child(_coins_label)
	PlayerProfile.coins_changed.connect(_on_coins_changed)

func _build_logo() -> void:
	var logo := TextureRect.new()
	logo.texture = LOGO_TEXTURE
	logo.anchor_left = 0.07
	logo.anchor_right = 0.93
	logo.anchor_top = 0.09
	logo.anchor_bottom = 0.40
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

func _build_play_area() -> void:
	# The mock-up's play area, in the mock-up's own proportions: an illustrated
	# stone platform across the lower middle of the screen with the player's
	# marble resting on it. The platform artwork and every number below come
	# from `docs/ui-reference/home.png`, which shares this viewport's 9:16
	# aspect, so the composition transfers directly. The marble itself is not
	# artwork — it is the game's own `Marble`, rendered in 3D by
	# `HomeMarblePreview`.
	_play_surface = HomePlaySurface.new()
	add_child(_play_surface)

	_marble = HomeMarblePreview.create(
		PlayerProfile.equipped_colour(), PlayerProfile.equipped_skin_data()
	)
	add_child(_marble)
	_layout_marble()
	resized.connect(_layout_marble)

## Puts the marble on the platform at whatever size the portrait viewport ends
## up: its resting spot, the height it sits at and its size are all fractions of
## the screen, taken from the mock-up, and its roll stays inside the platform
## and well clear of the nav row.
func _layout_marble() -> void:
	if _marble == null:
		return
	var radius := size.x * MARBLE_RADIUS_FRACTION
	var rest := size.x * MARBLE_REST_X_FRACTION
	_marble.set_display(Vector2(rest, size.y * MARBLE_CENTRE_Y_FRACTION), radius)
	var half_travel := size.x * MARBLE_TRAVEL_FRACTION
	_marble.set_travel(
		maxf(rest - half_travel, radius + MARBLE_EDGE_MARGIN),
		minf(rest + half_travel, size.x - radius - MARBLE_EDGE_MARGIN)
	)

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

func _on_coins_changed(balance: int) -> void:
	_coins_label.text = "%d" % balance

func _build_nav() -> void:
	var marble := _nav_button(MARBLE_BUTTON_TEXTURE, func() -> void: _show_toast("Marble collection coming soon"))
	marble.anchor_left = 0.0222
	marble.anchor_right = 0.2403
	marble.anchor_top = 1.0
	marble.anchor_bottom = 1.0
	marble.offset_top = -191.0
	marble.offset_bottom = -16.0
	add_child(marble)

	var start := _nav_button(START_BUTTON_TEXTURE, _on_start_pressed)
	start.anchor_left = 0.2570
	start.anchor_right = 0.7431
	start.anchor_top = 1.0
	start.anchor_bottom = 1.0
	start.offset_top = -203.0
	start.offset_bottom = -16.0
	add_child(start)

	var store := _nav_button(STORE_BUTTON_TEXTURE, func() -> void: get_tree().change_scene_to_file(SHOP_SCENE))
	store.anchor_left = 0.7598
	store.anchor_right = 0.9778
	store.anchor_top = 1.0
	store.anchor_bottom = 1.0
	store.offset_top = -191.0
	store.offset_bottom = -16.0
	add_child(store)

func _nav_button(button_texture: Texture2D, on_pressed: Callable) -> HomeNavButton:
	var button := HomeNavButton.new()
	button.texture_normal = button_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.pressed.connect(on_pressed)
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
