class_name RankTag
extends Label3D

## The player's current place, floating just above their own marble.
##
## The standings column already carries this (`race_hud.gd`), but reading it
## means looking away from the race to the top-right corner. `PROJECT.md`
## section 2.5 asks that the player be able to follow their marble without the UI
## covering the track; a place they have to hunt for in a corner is the same
## problem in reverse.
##
## This is a floating marker, which the 2026-08-20 entry in `DECISIONS.md` ruled
## out. That clause is superseded by the 2026-08-22 entry — see the decision log
## for why. It stays small and fixed-size so it remains a tag rather than the
## oversized marker the original clause was written against.

## Distance above the marble, in metres, along the camera's own up axis. A world
## +Y offset would nearly vanish under the 61-degree overhead camera; measuring
## the offset in the camera's frame keeps the same gap on screen in both camera
## modes. `race_manager.gd` uses the same reasoning to place comic popups.
const TAG_OFFSET := 1.2

## Screen size, via `fixed_size`. Together these put the text at roughly the
## height of the HUD's status line.
const TAG_FONT_SIZE := 64
const TAG_PIXEL_SIZE := 0.0003

## How quickly the tag catches up to the marble. The marble is a rigid body being
## hit by eleven others; following it exactly makes the text jitter on every
## contact.
const TAG_SMOOTHING := 14.0

var _place := 0


static func create(colour: Color) -> RankTag:
	var tag := RankTag.new()
	tag.name = "RankTag"
	tag._build(colour)
	return tag


func _build(colour: Color) -> void:
	font_size = TAG_FONT_SIZE
	pixel_size = TAG_PIXEL_SIZE
	# Constant on screen regardless of distance. Mode.OVERHEAD pulls from 34m to
	# 41m with speed and Mode.CHASE sits at 14m; without this the tag would grow
	# and shrink with the camera rather than reading as a label.
	fixed_size = true
	billboard = BaseMaterial3D.BILLBOARD_ENABLED

	# The moment the player most needs to know where they are is the moment they
	# are in the middle of a pile-up and cannot see their own marble. Drawing
	# through the geometry is the whole point.
	no_depth_test = true
	render_priority = 10
	outline_render_priority = 9

	modulate = colour
	outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	outline_size = 12
	shaded = false
	text = ""


## `place` is one-based; 0 means the player is out of the running, and the tag
## hides itself rather than showing a rank that no longer means anything.
func set_place(place: int) -> void:
	if place == _place:
		return
	_place = place
	text = ordinal(place) if place > 0 else ""


## Follows `at`, offset along the camera's up axis. `snap` skips the smoothing,
## for the frame the tag appears or a marble is respawned — otherwise it would
## slide in across the track from wherever the last round left it.
func follow(at: Vector3, camera: Camera3D, delta: float, snap := false) -> void:
	if camera == null or not is_instance_valid(camera):
		return

	var target := at + camera.global_basis.y * TAG_OFFSET
	if snap:
		global_position = target
	else:
		global_position = global_position.lerp(target, minf(delta * TAG_SMOOTHING, 1.0))


## "1st", "2nd", "3rd", "4th"... A twelve-marble field never reaches the 11-13
## exception, but the helper handles it so it does not become a trap when field
## sizes change.
static func ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [n, suffix]
