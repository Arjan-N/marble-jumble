class_name HomeMarble
extends Node2D

## The home screen's hero: a single marble rolling across the foreground strip,
## purely for presentation — no physics body, no relation to `Marble`. Drawn
## the same procedural way as `ComicPopup` and `SoundSynth`, since Phase 0 has
## no art pipeline to add a sprite through (see UI_VISUAL_REFERENCES.md, Home).
##
## Rotation is tied to horizontal speed (angle = distance / radius) rather than
## a fixed spin rate, so it reads as rolling rather than just spinning in
## place — the same physical honesty the race itself insists on.

const RADIUS := 34.0
const SPEED := 70.0 ## px/s across the design-space (720-wide) track.

var _colour: Color
var _track_left: float
var _track_right: float
var _distance := 0.0
## The marble's own spin, kept separate from the node's `rotation` — the node
## only moves horizontally, and spinning it would carry the flat ground shadow
## around with it.
var _spin := 0.0


static func create(colour: Color, track_left: float, track_right: float) -> HomeMarble:
	var marble := HomeMarble.new()
	marble._colour = colour
	marble._track_left = track_left
	marble._track_right = track_right
	return marble


## Called when the screen resizes, since the track spans its width.
func set_track(track_left: float, track_right: float) -> void:
	_track_left = track_left
	_track_right = track_right


func _process(delta: float) -> void:
	_distance += SPEED * delta
	var span := _track_right - _track_left
	var x := _track_left + fmod(_distance, span)
	position.x = x
	_spin = -_distance / RADIUS
	queue_redraw()


func _draw() -> void:
	# Contact shadow, flat on the ground — drawn with no rotation applied.
	# CanvasItem's own draw_ellipse takes a centre and two radii, not a Rect2.
	var shadow_centre := Vector2(0.0, RADIUS * 0.9)
	draw_ellipse(shadow_centre, RADIUS * 0.9, RADIUS * 0.25, Color(0.0, 0.0, 0.0, 0.28))

	draw_circle(Vector2.ZERO, RADIUS, _colour)
	# Thick dark rim, per the shared comic-book visual language (thick outlines,
	# strong silhouettes) rather than a soft anti-aliased edge.
	draw_arc(Vector2.ZERO, RADIUS - 1.5, 0.0, TAU, 48, Color(0.05, 0.04, 0.05), 3.0, true)

	# A single bright highlight, orbiting with the marble's own spin, so the
	# roll — and the customisation the design doc asks be "immediately
	# apparent" — actually reads at a glance rather than as a flat disc.
	var highlight_offset := Vector2(-RADIUS * 0.35, -RADIUS * 0.4).rotated(_spin)
	draw_circle(highlight_offset, RADIUS * 0.28, Color(1.0, 1.0, 1.0, 0.55))
