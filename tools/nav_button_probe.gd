extends Node

## Drives the three home nav buttons with real input events and prints the
## scale each one is at through a press, so the feedback added in
## `HomeNavButton` is checked by pushing pixels rather than by reading the code.
##
##     MJ_BUTTON=marble MJ_INPUT=mouse godot --path . --headless \
##       res://tools/nav_button_probe.tscn --fixed-fps 60 --quit-after 90
##
## `MJ_BUTTON` picks marble/start/store and `MJ_INPUT` picks mouse/touch. One
## button per run, because START and STORE navigate away the moment their
## callback fires and take the probe with them.
##
## `MJ_NAV=live` leaves the real callbacks connected and lets that happen — the
## probe reports from `_exit_tree`, so a run that ends there is the proof the
## callback still fires. The default, `MJ_NAV=block`, prints the real callbacks
## and then unhooks them for the length of the run so the release animation has
## somewhere to play out. Nothing in the shipped scene is changed either way.

const HOME_SCENE := preload("res://scenes/home.tscn")

## Which nav button each index in `_nav_buttons()` is, in creation order.
const NAMES := ["marble", "start", "store"]

var _home: Control
var _button: HomeNavButton
var _label := ""
var _use_touch := false
var _live := false
var _frame := 0
var _hover_scale := 1.0
var _pressed_scale := 1.0
var _released_scale := 1.0
var _fired := false
var _navigated := false

func _ready() -> void:
	_label = OS.get_environment("MJ_BUTTON")
	if _label == "":
		_label = "marble"
	_use_touch = OS.get_environment("MJ_INPUT") == "touch"
	_live = OS.get_environment("MJ_NAV") == "live"
	_home = HOME_SCENE.instantiate()
	add_child(_home)

func _exit_tree() -> void:
	if _navigated:
		print("[%s] callback navigated away from the home screen" % _label)

func _process(_delta: float) -> void:
	_frame += 1
	match _frame:
		2:
			_resolve_button()
		4:
			_hover()
		10:
			_hover_scale = _button.scale.x
			print("[%s] hover scale=%.3f tint=%.3f" % [_label, _hover_scale, _button.modulate.r])
			_press()
		16:
			_pressed_scale = _button.scale.x
			print("[%s] pressed scale=%.3f" % [_label, _pressed_scale])
			_navigated = _live
			_release()
		40:
			_navigated = false
			_released_scale = _button.scale.x
			print("[%s] released scale=%.3f" % [_label, _released_scale])
			_report()

func _resolve_button() -> void:
	_button = _nav_buttons()[NAMES.find(_label)]
	var connections := _button.pressed.get_connections()
	print("[%s] rect=%s pressed_connections=%d" % [_label, _button.get_global_rect(), connections.size()])
	for connection in connections:
		var callable: Callable = connection["callable"]
		var name_of := callable.get_method()
		print("[%s] real callback -> %s" % [_label, name_of if name_of != "" else "<lambda>"])
		if not _live:
			_button.pressed.disconnect(callable)
	_button.pressed.connect(func() -> void: _fired = true)

func _nav_buttons() -> Array[HomeNavButton]:
	var found: Array[HomeNavButton] = []
	for child in _home.get_children():
		var button := child as HomeNavButton
		if button != null:
			found.append(button)
	return found

func _centre() -> Vector2:
	return _button.get_global_rect().get_center()

## `in_local_coords` is true throughout: `_centre()` is already in the 720x1280
## viewport space, and the project stretches that to a smaller window, so
## letting `push_input` apply the window transform would land the pointer
## somewhere else entirely.
func _push(event: InputEvent) -> void:
	get_viewport().push_input(event, true)

func _hover() -> void:
	if _use_touch:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = _centre()
	motion.global_position = motion.position
	_push(motion)

func _press() -> void:
	_push(_pointer(true))

func _release() -> void:
	_push(_pointer(false))

func _pointer(pressed: bool) -> InputEvent:
	if _use_touch:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = _centre()
		touch.pressed = pressed
		return touch
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = _centre()
	click.global_position = click.position
	click.pressed = pressed
	return click

func _report() -> void:
	var shrank := _pressed_scale > 0.94 and _pressed_scale < 0.99
	var restored := absf(_released_scale - 1.0) < 0.03
	print("[%s] input=%s shrank=%s restored=%s fired=%s" % [
		_label,
		"touch" if _use_touch else "mouse",
		shrank, restored, _fired,
	])
	get_tree().quit(0 if shrank and restored and _fired else 1)
