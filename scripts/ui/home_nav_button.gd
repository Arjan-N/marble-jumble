class_name HomeNavButton
extends TextureButton

## Nav button that keeps the supplied artwork as its only appearance and adds
## chunky mobile-game press feedback on top: the whole button scales down while
## held and springs back on release. Input handling stays with TextureButton so
## the existing `pressed` callbacks are untouched.

const PRESSED_SCALE := 0.96
const HOVER_SCALE := 1.02
const NORMAL_TINT := Color(1.0, 1.0, 1.0)
const HOVER_TINT := Color(1.07, 1.07, 1.07)
const PRESS_SECONDS := 0.06
const RELEASE_SECONDS := 0.16
const HOVER_SECONDS := 0.09

# Scaling about a pivot below the centre makes the button sink downwards as it
# shrinks, which reads as being physically pushed into the screen.
const PIVOT_Y_RATIO := 0.7

var _tween: Tween
var _hovered := false
var _touch_held := false
var _touch_input := false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_update_pivot()
	resized.connect(_update_pivot)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent) -> void:
	# Android touch: works even if mouse-from-touch emulation is disabled, and
	# is harmless when it is enabled because this only drives the visual state.
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	_touch_input = true
	if touch.pressed:
		_touch_held = true
		_animate(PRESSED_SCALE, NORMAL_TINT, PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)
	elif _touch_held:
		_touch_held = false
		_animate(1.0, NORMAL_TINT, RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _touch_held:
		_touch_held = false
		_animate(1.0, NORMAL_TINT, RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)

func _update_pivot() -> void:
	pivot_offset = Vector2(size.x * 0.5, size.y * PIVOT_Y_RATIO)

func _on_button_down() -> void:
	_animate(PRESSED_SCALE, NORMAL_TINT, PRESS_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)

func _on_button_up() -> void:
	_touch_held = false
	_animate(_rest_scale(), _rest_tint(), RELEASE_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)

func _on_mouse_entered() -> void:
	_hovered = true
	if _touch_input or button_pressed:
		return
	_animate(HOVER_SCALE, HOVER_TINT, HOVER_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	_hovered = false
	if _touch_input or button_pressed:
		return
	_animate(1.0, NORMAL_TINT, HOVER_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)

func _rest_scale() -> float:
	return HOVER_SCALE if _hovered and not _touch_input else 1.0

func _rest_tint() -> Color:
	return HOVER_TINT if _hovered and not _touch_input else NORMAL_TINT

func _animate(target: float, tint: Color, seconds: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(trans)
	_tween.set_ease(ease_type)
	_tween.tween_property(self, "scale", Vector2(target, target), seconds)
	_tween.tween_property(self, "modulate", tint, seconds)
