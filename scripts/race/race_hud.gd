class_name RaceHUD
extends CanvasLayer

## Minimal race information, per PROJECT.md section 9. The race is the thing
## being watched; the UI stays out of its way.

var _label: Label


static func create() -> RaceHUD:
	var hud := RaceHUD.new()
	hud.name = "RaceHUD"
	hud._build()
	return hud


func _build() -> void:
	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)


func show_text(text: String) -> void:
	_label.text = text
