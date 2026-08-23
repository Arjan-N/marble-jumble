class_name HomeIcon
extends Control

enum Kind { MARBLE, CART, COIN, MENU, PLUS }

var kind: Kind = Kind.MARBLE
var fill := Color.WHITE
var stroke := Color(0.05, 0.02, 0.01)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var w := maxf(2.0, s * 0.055)
	if kind == Kind.MARBLE:
		_draw_marble(c, s * 0.72, w)
	elif kind == Kind.CART:
		_draw_cart(c, s * 0.72, w)
	elif kind == Kind.COIN:
		_draw_coin(c, s * 0.76, w)
	elif kind == Kind.MENU:
		for y in [-0.22, 0.0, 0.22]:
			draw_line(Vector2(c.x - s * 0.25, c.y + s * y), Vector2(c.x + s * 0.25, c.y + s * y), fill, w * 1.35, true)
	elif kind == Kind.PLUS:
		draw_line(Vector2(c.x - s * 0.22, c.y), Vector2(c.x + s * 0.22, c.y), fill, w * 1.4, true)
		draw_line(Vector2(c.x, c.y - s * 0.22), Vector2(c.x, c.y + s * 0.22), fill, w * 1.4, true)

func _draw_marble(c: Vector2, r: float, w: float) -> void:
	draw_circle(c, r * 0.5, fill)
	draw_arc(c, r * 0.5, -2.5, -0.8, 18, stroke, w, true)
	draw_arc(c, r * 0.5, 0.0, 1.5, 18, stroke, w, true)
	draw_arc(c, r * 0.5, 2.0, 3.2, 18, stroke, w, true)
	draw_circle(c + Vector2(-r * 0.16, -r * 0.18), r * 0.07, Color(1, 1, 1, 0.9))

func _draw_coin(c: Vector2, r: float, w: float) -> void:
	draw_circle(c, r * 0.5, Color(1.0, 0.65, 0.05))
	draw_arc(c, r * 0.5, 0, TAU, 40, stroke, w, true)
	draw_circle(c, r * 0.34, Color(1.0, 0.78, 0.16))
	draw_arc(c, r * 0.34, 0, TAU, 40, Color(0.82, 0.35, 0.03), w * 0.55, true)
	draw_circle(c, r * 0.11, Color(1.0, 0.9, 0.45))

func _draw_cart(c: Vector2, r: float, w: float) -> void:
	var left := c + Vector2(-r * 0.34, -r * 0.22)
	var right := c + Vector2(r * 0.34, -r * 0.22)
	draw_line(c + Vector2(-r * 0.42, -r * 0.38), left, fill, w * 1.5, true)
	draw_line(left, right, fill, w * 1.5, true)
	draw_line(left + Vector2(0, r * 0.05), left + Vector2(r * 0.08, r * 0.28), fill, w * 1.5, true)
	draw_line(left + Vector2(r * 0.08, r * 0.28), right + Vector2(-r * 0.05, r * 0.28), fill, w * 1.5, true)
	draw_circle(left + Vector2(r * 0.12, r * 0.43), w * 1.35, fill)
	draw_circle(right + Vector2(-r * 0.02, r * 0.43), w * 1.35, fill)
