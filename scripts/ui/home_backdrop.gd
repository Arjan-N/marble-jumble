class_name HomeBackdrop
extends Control

## The home screen's environment: a static, simplified Canyon silhouette.
## UI_VISUAL_REFERENCES.md asks that this stay lighter and simpler than the
## illustrated reference so the marble and buttons remain dominant — flat
## colour shapes, no gradients-as-decoration, no texture pass.
##
## Redrawn on resize rather than baked, since the design favours responsive
## portrait layouts over a fixed canvas size.

const SKY_TOP := Color(0.98, 0.78, 0.45)
const SKY_BOTTOM := Color(0.93, 0.52, 0.28)
const CANYON_FAR := Color(0.62, 0.32, 0.22)
const CANYON_NEAR := Color(0.47, 0.22, 0.16)
const GROUND_COLOUR := Color(0.36, 0.24, 0.18)
const TRACK_COLOUR := Color(0.55, 0.44, 0.33)

const TRACK_TOP_FRACTION := 0.74
const TRACK_HEIGHT_FRACTION := 0.10


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y

	_draw_sky(w, h)
	_draw_canyon_layer(w, h, 0.42, 0.60, CANYON_FAR)
	_draw_canyon_layer(w, h, 0.58, 0.74, CANYON_NEAR)
	_draw_ground(w, h)


func _draw_sky(w: float, h: float) -> void:
	var steps := 24
	for i in range(steps):
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var colour := SKY_TOP.lerp(SKY_BOTTOM, t0)
		draw_rect(Rect2(0.0, h * TRACK_TOP_FRACTION * t0, w, h * TRACK_TOP_FRACTION * (t1 - t0) + 1.0), colour)


## A row of blocky mesa silhouettes between `from_fraction` and
## `to_fraction` of the canyon band's height — flat colour, hard edges, per
## the shared comic-book visual language.
func _draw_canyon_layer(w: float, h: float, from_fraction: float, to_fraction: float, colour: Color) -> void:
	var base_y := h * TRACK_TOP_FRACTION
	var top_y := base_y * from_fraction
	var mesa_count := 5
	var mesa_width := w / float(mesa_count)

	for i in range(mesa_count):
		var cx := mesa_width * (float(i) + 0.5)
		var jitter := sin(float(i) * 1.7) * 0.5 + 0.5
		var mesa_top := lerpf(top_y, base_y * to_fraction, jitter)
		var half_width := mesa_width * lerpf(0.42, 0.6, jitter)
		var points := PackedVector2Array([
			Vector2(cx - half_width, base_y),
			Vector2(cx - half_width * 0.7, mesa_top),
			Vector2(cx + half_width * 0.7, mesa_top),
			Vector2(cx + half_width, base_y),
		])
		draw_colored_polygon(points, colour)


func _draw_ground(w: float, h: float) -> void:
	var track_top := h * TRACK_TOP_FRACTION
	var track_height := h * TRACK_HEIGHT_FRACTION
	draw_rect(Rect2(0.0, track_top, w, h - track_top), GROUND_COLOUR)
	draw_rect(Rect2(0.0, track_top, w, track_height), TRACK_COLOUR)
