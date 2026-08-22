class_name HomeScreen
extends Control

## The game's front door. Per docs/ui-reference/UI_VISUAL_REFERENCES.md ("Home"):
## make the player's marble the hero, keep the environment lighter and simpler
## than the illustrated reference, and lead with MARBLE / START / STORE.
##
## Round-start (course carousel, 4x3 marble grid) and Shop are not built yet —
## MARBLE and STORE show a "coming soon" toast rather than nothing, and START
## goes straight into the race scene. Revisit once those screens exist.
##
## Built entirely in code, no external art or custom fonts, matching every
## other screen in the project (`RaceHUD`, `ComicPopup`) — there is no art
## pipeline yet, and the comic-book "thick outline, bold display type" look is
## produced with outlined text and hard-edged flat colour instead.

const RACE_SCENE := "res://scenes/main.tscn"

## No customisation exists yet to persist a chosen colour, so the home screen's
## marble stands in with the same warm highlight tone the race gives the
## player's marble. Swap for a saved profile colour once one exists.
const MARBLE_COLOUR := Color(0.95, 0.75, 0.15)

const TITLE_FONT_SIZE := 64
const NAV_FONT_SIZE := 24
const TOAST_SECONDS := 1.6

## Inset from each edge so the marble visibly turns around rather than
## vanishing into the screen edge.
const TRACK_MARGIN := 48.0

var _backdrop: HomeBackdrop
var _marble: HomeMarble
var _toast: Label
var _toast_left := 0.0


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_backdrop()
	_build_title()
	_build_marble()
	_build_toast()
	_build_nav()

	resized.connect(_on_resized)


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.4, 0.0, 1.0)


func _build_backdrop() -> void:
	_backdrop = HomeBackdrop.new()
	_backdrop.anchor_right = 1.0
	_backdrop.anchor_bottom = 1.0
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)


func _build_title() -> void:
	var title := Label.new()
	title.text = "MARBLE JUMBLE"
	title.anchor_right = 1.0
	title.offset_top = 64.0
	title.offset_bottom = 64.0 + TITLE_FONT_SIZE * 1.4
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.06, 0.04))
	title.add_theme_constant_override("outline_size", 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func _build_marble() -> void:
	var bounds := _track_bounds()
	_marble = HomeMarble.create(MARBLE_COLOUR, bounds.x, bounds.y)
	_marble.position.y = _track_row_y()
	add_child(_marble)


## Left/right x-range the home marble rolls across, in this control's own
## coordinates. Deferred to `size` rather than a fixed design width so it
## still centres correctly on whatever portrait aspect the device stretches to.
## Falls back to the viewport's own size before the control's first layout
## pass has run, so the first frame doesn't hand `HomeMarble` a zero-width or
## negative track.
func _track_bounds() -> Vector2:
	var width := size.x if size.x > 0.0 else get_viewport_rect().size.x
	return Vector2(TRACK_MARGIN, width - TRACK_MARGIN)


func _track_row_y() -> float:
	var height := size.y if size.y > 0.0 else get_viewport_rect().size.y
	return height * (HomeBackdrop.TRACK_TOP_FRACTION + HomeBackdrop.TRACK_HEIGHT_FRACTION * 0.5)


func _on_resized() -> void:
	if _marble == null:
		return
	var bounds := _track_bounds()
	_marble.set_track(bounds.x, bounds.y)
	_marble.position.y = _track_row_y()


func _build_toast() -> void:
	_toast = Label.new()
	_toast.anchor_right = 1.0
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_top = -172.0
	_toast.offset_bottom = -140.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_left = TOAST_SECONDS


## Three tactile buttons, flat with a thick dark border rather than the
## engine's default beveled look — the same restrained, physical language
## `RaceHUD`'s restart button uses, per PROJECT.md section 8.
func _build_nav() -> void:
	var row := HBoxContainer.new()
	row.anchor_left = 0.06
	row.anchor_right = 0.94
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_top = -128.0
	row.offset_bottom = -32.0
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	row.add_child(_nav_button("MARBLE", func() -> void: _show_toast("Coming soon")))
	row.add_child(_nav_button("START", _on_start_pressed, true))
	row.add_child(_nav_button("STORE", func() -> void: _show_toast("Coming soon")))


func _nav_button(label: String, on_pressed: Callable, emphasised := false) -> Button:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 68 if emphasised else 56)
	button.add_theme_font_size_override("font_size", NAV_FONT_SIZE if emphasised else NAV_FONT_SIZE - 4)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	var fill := Color(0.93, 0.52, 0.20) if emphasised else Color(0.12, 0.08, 0.07, 0.72)
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.1, 0.05, 0.03)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = fill.darkened(0.2)
	pressed.set_corner_radius_all(12)
	pressed.set_border_width_all(3)
	pressed.border_color = Color(0.1, 0.05, 0.03)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.pressed.connect(on_pressed)
	return button


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(RACE_SCENE)
