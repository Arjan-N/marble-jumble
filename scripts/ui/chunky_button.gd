class_name ChunkyButton
extends Button

## The gold arcade plate the mock-ups put at the bottom of a screen.
##
## `HomeNavButton` already owns this press language — scale down about a pivot
## below centre while held, spring back on release, brighten on hover — but it
## is a `TextureButton` wrapped around a piece of authored artwork, and there is
## no artwork for CONTINUE / PLAY AGAIN. This is the same feedback applied to a
## drawn plate instead, deliberately keeping the same constants so the two kinds
## of button feel identical under the thumb.

const PRESSED_SCALE := 0.96
const HOVER_SCALE := 1.02
const PRESS_SECONDS := 0.06
const RELEASE_SECONDS := 0.16
const HOVER_SECONDS := 0.09
const PIVOT_Y_RATIO := 0.7

var _tween: Tween
var _hovered := false
var _touch_held := false
var _touch_input := false
var _highlight: Panel


## `primary` is the gold CONTINUE / PLAY AGAIN plate; the quiet variant is the
## smaller dark HOME button that sits under it.
static func create(text: String, font_size: int, primary: bool = true) -> ChunkyButton:
	var button := ChunkyButton.new()
	button.text = text
	button._build(font_size, primary)
	return button


func _build(font_size: int, primary: bool) -> void:
	var fill := UIKit.GOLD if primary else Color(0.16, 0.15, 0.16, 0.94)
	var ink := UIKit.INK if primary else Color(0.06, 0.05, 0.05)
	var text_colour := UIKit.INK if primary else UIKit.CREAM

	add_theme_stylebox_override("normal", UIKit.plate(fill, ink, 6, 18))
	add_theme_stylebox_override("hover", UIKit.plate(fill.lightened(0.08), ink, 6, 18))
	add_theme_stylebox_override("pressed", UIKit.plate(fill.darkened(0.12), ink, 6, 18))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", UIKit.plate(fill.darkened(0.45), ink, 6, 18))

	add_theme_font_override("font", UIKit.DISPLAY_FONT)
	add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, text_colour)
	add_theme_color_override("font_disabled_color", Color(text_colour, 0.5))
	if not primary:
		add_theme_color_override("font_outline_color", UIKit.INK)
		add_theme_constant_override("outline_size", 6)

	# The bevel: a translucent band across the top half, clipped to the plate's
	# own corner radius. Flat gold reads as a coloured rectangle; the band is
	# what makes it read as a moulded piece of plastic.
	_highlight = Panel.new()
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1.0, 1.0, 1.0, 0.20 if primary else 0.07)
	gloss.corner_radius_top_left = 12
	gloss.corner_radius_top_right = 12
	gloss.corner_radius_bottom_left = 4
	gloss.corner_radius_bottom_right = 4
	_highlight.add_theme_stylebox_override("panel", gloss)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight)


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_update_layout()
	resized.connect(_update_layout)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	# Same reasoning as `home_nav_button.gd`: drives the visual state only, so
	# it is harmless whether or not mouse-from-touch emulation is on.
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	_touch_input = true
	if touch.pressed:
		_touch_held = true
		_animate(PRESSED_SCALE, PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)
	elif _touch_held:
		_touch_held = false
		_animate(1.0, RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _update_layout() -> void:
	pivot_offset = Vector2(size.x * 0.5, size.y * PIVOT_Y_RATIO)
	if _highlight != null:
		_highlight.position = Vector2(10.0, 9.0)
		_highlight.size = Vector2(maxf(size.x - 20.0, 0.0), size.y * 0.42)


func _on_button_down() -> void:
	_animate(PRESSED_SCALE, PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_up() -> void:
	_touch_held = false
	_animate(_rest_scale(), RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _on_mouse_entered() -> void:
	_hovered = true
	if _touch_input or button_pressed:
		return
	_animate(HOVER_SCALE, HOVER_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	_hovered = false
	if _touch_input or button_pressed:
		return
	_animate(1.0, HOVER_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _rest_scale() -> float:
	return HOVER_SCALE if _hovered and not _touch_input else 1.0


func _animate(target: float, seconds: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(trans)
	_tween.set_ease(ease_type)
	_tween.tween_property(self, "scale", Vector2(target, target), seconds)
