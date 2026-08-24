class_name HomeMarble
extends Node2D

## The home screen's hero marble: the player's own marble, presented.
##
## This node is the *visual representation* only. It carries no physics and no
## race behaviour — the simulation marble is `Marble` (a `RigidBody3D`), which
## this screen never instantiates and never modifies. Keeping the two apart is
## what lets the marble be customised: a skin picks what is drawn here and the
## colour handed to `Marble`, and nothing else.
##
## The artwork is `marble_player.png`, cut from the home mock-up by
## `tools/extract_home_art.gd`. It is a painted, glossy, striped ball, so it is
## drawn as a sprite rather than rebuilt from primitives.
##
## Rotation is tied to horizontal speed (angle = distance / radius) rather than
## a fixed spin rate, so it reads as rolling rather than just spinning in
## place — the same physical honesty the race itself insists on.

const DEFAULT_TEXTURE := preload("res://assets/ui/marble_player.png")

## One painted marble per skin id. Only the default marble has been painted so
## far — `PlayerProfile.SKINS` still describes the rest as flat colours, which
## is a placeholder economy, not art — so every skin falls back to it. A new
## skin drops in as `id: preload(...)` and needs no other change here.
##
## Multiplying the painted artwork by a flat skin colour was tried and dropped:
## it turns the stripes and the gloss into a single muddy wash, which is the
## look this artwork replaced.
const SKIN_TEXTURES := {
	0: DEFAULT_TEXTURE,
}

## The painted ball's radius as a fraction of the texture's half-width. The cut
## leaves a few pixels of transparent padding so the dark outline is never
## clipped; the shadow and the roll both need the ball, not the padding.
const BALL_FRACTION := 178.0 / 187.0

const SPEED := 46.0 ## px/s across the design-space (720-wide) surface.

var _radius := 68.0
var _left := 0.0
var _right := 0.0
var _sprite: Sprite2D
var _distance := 0.0
## Where the roll started, so the marble faces the way the mock-up paints it
## when it is at rest rather than at some arbitrary angle.
var _rest_distance := 0.0
## The ball's own spin, kept separate from the node's `rotation` — the node
## only moves horizontally, and spinning it would carry the flat ground shadow
## around with it.
var _spin := 0.0


static func create(radius: float, skin_id: int) -> HomeMarble:
	var marble := HomeMarble.new()
	marble._radius = radius
	marble._build()
	marble.set_skin(skin_id)
	return marble


func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = DEFAULT_TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	set_radius(_radius)


## Re-scales the sprite to a new on-screen radius (the viewport is stretched
## to the device, so this changes with the screen). The sprite is scaled from
## the painted ball rather than the padded texture, so `_radius` is always the
## radius of what is actually on screen.
func set_radius(radius: float) -> void:
	_radius = radius
	var painted := (_sprite.texture.get_width() * 0.5) * BALL_FRACTION
	_sprite.scale = Vector2.ONE * (radius / painted)
	queue_redraw()


## Called when the screen resizes, since the surface spans its width.
func set_travel(left: float, right: float) -> void:
	_left = left
	_right = right


## Places the marble where the mock-up rests it — roughly centred on the play
## surface — and starts the roll from there rather than from one end.
func rest_at(x: float) -> void:
	_distance = clampf(x, _left, _right) - _left
	_rest_distance = _distance
	position.x = _left + _distance


## Shows the artwork the equipped skin is painted as.
func set_skin(skin_id: int) -> void:
	_sprite.texture = SKIN_TEXTURES.get(skin_id, DEFAULT_TEXTURE)
	set_radius(_radius)


func _process(delta: float) -> void:
	var span := _right - _left
	if span <= 0.0:
		return
	_distance += SPEED * delta
	# A triangle wave, so the marble rolls back rather than jumping to the far
	# end when it runs out of surface.
	var swept := fmod(_distance, span * 2.0)
	var offset := swept if swept <= span else span * 2.0 - swept
	position.x = _left + offset
	# Measured from the resting spot, so the painted gloss sits where the
	# mock-up puts it when the marble is where the mock-up puts it.
	_spin = (offset - _rest_distance) / _radius
	_sprite.rotation = _spin
	queue_redraw()


func _draw() -> void:
	# Contact shadow, flat on the surface and thrown to the right by the same
	# low sun the mock-up's artwork is lit by. Drawn here rather than baked into
	# the play surface so it travels with the marble.
	# CanvasItem's own draw_ellipse takes a centre and two radii, not a Rect2.
	draw_ellipse(
		Vector2(_radius * 0.50, _radius * 1.02),
		_radius * 1.25,
		_radius * 0.30,
		Color(0.13, 0.05, 0.02, 0.40)
	)
