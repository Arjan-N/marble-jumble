class_name CanyonFinish
extends Node3D

## The Canyon course's finish dressing.
##
## One of possibly many: `Course.create_finish_visual` is the seam, and a factory
## floor's steel gantry or an ice valley's frozen gate would be a sibling of this
## file rather than a flag inside it. Nothing here is referenced by the race, by
## `FinishZone`, or by any other course — `CourseBuilder.create_finish_visual` is
## the only thing that names it.
##
## **Visual only.** Not one node here is a `StaticBody3D`, and that is a rule
## rather than an accident: `DECISIONS.md` requires that helper geometry never
## manipulate race outcomes, and a finish that is dressing cannot. Everything a
## marble can touch at this end of the course — the runoff floor, its walls, the
## kerb that closes it — is built by `CourseBuilder` with the rest of the
## collision geometry.
##
## Shapes follow the Home screen art the rest of the Canyon is drawn from:
## hard-edged sandstone blocks stepping outward as they rise, warm terracotta
## through ochre, and no smooth gradients anywhere. The gateway is deliberately
## **tall**. `TempleRunCourse._build_finish_gate` records why a lintel was wrong
## there — a beam anywhere between two and seven metres up crosses the frame
## exactly where the marbles are at the one moment the player most needs to see
## them — and the same camera looks at this one. An arch that springs above that
## band reads as an arch and still leaves the middle of the shot empty.

## Height the arch springs from at the pylons. It rises from there, so what
## actually matters is the height over the *track*, which works out around eight
## metres at the track edge — above the two-to-seven-metre band the header rules
## out, and below the top of the frame.
##
## The first pass sprang from 8.4 and the crown left the frame entirely: the race
## camera looks down at 32 degrees from 30m and its shot runs out around eleven
## metres of height at the finish. An arch nobody can see the top of is a pair of
## pillars with extra geometry.
const ARCH_CLEARANCE := 6.2
## Segments per half of the arch. Six a side is enough that it reads as a curve
## from any distance the race camera sees it from, and it stays twelve boxes.
const ARCH_SEGMENTS := 6
const ARCH_THICKNESS := 0.75
const ARCH_DEPTH := 1.8

## How far outboard of the trough's own wall top the pylons stand. The finish is
## where the field arrives widest and most abreast; nothing about the gateway may
## narrow it, so this is never negative — but it is small, because a pylon set
## far enough out to clear the canyon's dressing strata entirely ends up standing
## in the cliff at the edge of frame rather than beside the track.
const PYLON_CLEARANCE := 0.35
const PYLON_WIDTH := 1.9
const PYLON_DEPTH := 2.4
## Stepped like `CourseBuilder.DRESSING_TIERS`, retreating slightly as they rise
## so the pylon has the same silhouette as the strata behind it.
const PYLON_TIERS := [
	{"height": 2.6, "shrink": 1.00, "colour": Color(0.52, 0.22, 0.14)},
	{"height": 2.2, "shrink": 0.88, "colour": Color(0.72, 0.32, 0.16)},
	{"height": 1.4, "shrink": 0.78, "colour": Color(0.84, 0.44, 0.22)},
	{"height": 0.8, "shrink": 0.92, "colour": Color(0.90, 0.60, 0.34)},
]

## The line itself, as chequers laid into the deck rather than a painted stripe.
##
## Two rows, offset against each other. One row of thirteen narrow cells was the
## first pass and from the race camera — which sees the line from thirty metres
## up-course, foreshortened — it read as a dashed line rather than as a chequer.
## Two rows of seven give roughly square cells and the alternation between the
## rows is what actually says "finish".
##
## An odd count per row guarantees the two ends of a row differ, so the offset
## between the rows is visible at both edges.
const CHEQUER_COUNT := 7
const CHEQUER_ROWS := 2
## Depth of one row, chosen so a cell is close to square at the track's width.
const CHEQUER_DEPTH := 0.85
const CHEQUER_LIFT := 0.05
const CHEQUER_LIGHT := Color(0.92, 0.88, 0.78)
const CHEQUER_DARK := Color(0.30, 0.20, 0.16)

## Cloth banners hung from the pylons' inner faces. Kept short and high so they
## hang beside the gateway rather than over the track.
const BANNER_COLOURS := [
	Color(0.78, 0.30, 0.20),
	Color(0.86, 0.60, 0.22),
	Color(0.52, 0.36, 0.46),
]
const BANNER_WIDTH := 0.9
const BANNER_HEIGHT := 2.6
const BANNER_TOP := 6.4

## Blown desert dust either side of the line. Two emitters, twelve particles
## each, no collision and no shadow — this has to survive twelve marbles
## arriving on a low-end Android device, so it is the cheapest thing that still
## says "desert" and it is not per-marble. The finish *burst* per marble lives in
## `FinishZone`; this is ambience that runs at a constant cost regardless of how
## many marbles are in the zone.
const DUST_AMOUNT := 12
const DUST_LIFETIME := 3.2
const DUST_COLOUR := Color(0.86, 0.68, 0.48, 0.30)

var _frame := Transform3D.IDENTITY
var _half_width := 3.0
var _runoff := 20.0
## Supplied by the course so the gateway is shaded by the same banded rock shader
## the canyon walls are. See `CourseBuilder.create_finish_visual`.
var _make_material: Callable


## `frame` is the finish line's own frame — local -Z down-course, local Y the
## surface normal — so everything below is placed in track space and inherits
## whatever descent and camber the course has there.
static func create(
	frame: Transform3D, half_width: float, runoff: float, make_material: Callable
) -> CanyonFinish:
	var finish := CanyonFinish.new()
	finish.name = "CanyonFinish"
	finish._frame = frame
	finish._half_width = half_width
	finish._runoff = runoff
	finish._make_material = make_material
	finish._build()
	return finish


func _build() -> void:
	_build_chequers()
	_build_gateway()
	_build_dust()


# --- The line -----------------------------------------------------------------


func _build_chequers() -> void:
	var span := _half_width * 2.0
	var square := span / float(CHEQUER_COUNT)
	var band := CHEQUER_DEPTH * float(CHEQUER_ROWS)

	for row in CHEQUER_ROWS:
		# Local -Z is down-course, so the band is laid centred on the line rather
		# than starting at it: the line is the middle of the markings, which is
		# where the trigger plane sits.
		var along := band * 0.5 - CHEQUER_DEPTH * (float(row) + 0.5)
		for i in CHEQUER_COUNT:
			var x := -_half_width + square * (float(i) + 0.5)
			var light := (i + row) % 2 == 0
			_add_mesh(
				_frame.translated_local(Vector3(x, CHEQUER_LIFT, -along)),
				Vector3(square, 0.06, CHEQUER_DEPTH),
				CHEQUER_LIGHT if light else CHEQUER_DARK
			)


# --- The gateway --------------------------------------------------------------


func _build_gateway() -> void:
	var pylon_x := _half_width + PYLON_CLEARANCE + PYLON_WIDTH * 0.5

	for side: float in [-1.0, 1.0]:
		_build_pylon(side * pylon_x)
		_build_banners(side * (pylon_x - PYLON_WIDTH * 0.5 - 0.15))

	_build_arch(pylon_x)


func _build_pylon(x: float) -> void:
	var rise := 0.0
	for tier: Dictionary in PYLON_TIERS:
		var height: float = tier["height"]
		var shrink: float = tier["shrink"]
		_add_mesh(
			_frame.translated_local(Vector3(x, rise + height * 0.5, 0.0)),
			Vector3(PYLON_WIDTH * shrink, height, PYLON_DEPTH * shrink),
			tier["colour"]
		)
		rise += height


## A segmented semicircle springing from the pylon tops. Boxes rather than a
## generated mesh: at twelve of them the silhouette is already smooth at race
## distance, and every other fixture in this course is built the same way.
## Flatter than a semicircle: the span between the pylons is wide and a true
## half-round over it would put the crown absurdly high. This is the vertical
## squash applied to the circle, so the arch is a segmental one.
const ARCH_SQUASH := 0.5

func _build_arch(pylon_x: float) -> void:
	var springing := ARCH_CLEARANCE
	var radius := pylon_x
	var total := ARCH_SEGMENTS * 2
	var step := PI / float(total)

	for i in total:
		# Sampled at segment centres so the two halves are symmetric and neither
		# end lands on a pylon's own centreline.
		var angle := step * (float(i) + 0.5)
		var x := -cos(angle) * radius
		var y := springing + sin(angle) * radius * ARCH_SQUASH

		# Each voussoir lies along the arch's tangent at its own centre, so the
		# ring reads as a curve rather than as a staircase of level blocks. The
		# tangent of `(-cos, sin * squash)` is `(sin, cos * squash)`; its angle
		# is the block's roll and its length sets the block's length, which is
		# what keeps the segments meeting where the ellipse is steepest.
		var tangent := Vector2(sin(angle), cos(angle) * ARCH_SQUASH)
		var roll := atan2(tangent.y, tangent.x)
		# 1.12 rather than 1.0: consecutive blocks meet at their corners, not
		# their faces, and a little overlap closes the wedge between them.
		var segment_length := tangent.length() * radius * step * 1.12

		var placed := _frame.translated_local(Vector3(x, y, 0.0))
		# Rotating about local Z rolls the block inside the gateway's own plane,
		# leaving its depth square to the track.
		placed.basis = placed.basis * Basis(Vector3(0.0, 0.0, 1.0), roll)

		var shade := 0.20 if i % 2 == 0 else 0.06
		_add_mesh(
			placed,
			Vector3(segment_length, ARCH_THICKNESS, ARCH_DEPTH),
			Color(0.80, 0.42, 0.22).lightened(shade)
		)

	# A keystone block sitting on the crown, so the arch has a top rather than a
	# seam where its two halves meet.
	_add_mesh(
		_frame.translated_local(Vector3(0.0, springing + radius * 0.55 + 0.5, 0.0)),
		Vector3(1.6, 1.0, ARCH_DEPTH + 0.4),
		Color(0.90, 0.60, 0.34)
	)


## Hung along the pylon's depth rather than stacked down its height, so three
## banners fit without any of them reaching into the band the marbles occupy on
## screen. Local -Z is down-course, so they run back up-course from the line.
func _build_banners(x: float) -> void:
	for i in BANNER_COLOURS.size():
		var along := (float(i) - 1.0) * (BANNER_WIDTH + 0.25)
		_add_mesh(
			_frame.translated_local(
				Vector3(x, BANNER_TOP - BANNER_HEIGHT * 0.5, along)
			),
			Vector3(0.12, BANNER_HEIGHT, BANNER_WIDTH),
			BANNER_COLOURS[i]
		)


# --- Dust ---------------------------------------------------------------------


func _build_dust() -> void:
	for side: float in [-1.0, 1.0]:
		var dust := CPUParticles3D.new()
		dust.name = "FinishDust"
		dust.amount = DUST_AMOUNT
		dust.lifetime = DUST_LIFETIME
		dust.direction = Vector3.UP
		dust.spread = 45.0
		# Drifting sideways and up, not falling: this is dust being carried
		# across the deck, which is what the canyon's own haze is (see
		# `CourseBuilder.FOG_DENSITY`'s comment — dust, not scattering).
		dust.gravity = Vector3(0.6 * side, 0.35, 0.0)
		dust.initial_velocity_min = 0.2
		dust.initial_velocity_max = 0.8
		dust.scale_amount_min = 0.7
		dust.scale_amount_max = 1.8
		dust.color = DUST_COLOUR
		dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		dust.emission_box_extents = Vector3(0.6, 0.3, _runoff * 0.3)
		dust.local_coords = false
		# Without an explicit box the renderer culls nearly every particle —
		# `MarbleTrail._configure_particles` documents the same trap.
		dust.visibility_aabb = AABB(
			Vector3(-6.0, -4.0, -_runoff), Vector3(12.0, 12.0, _runoff * 2.0)
		)
		dust.mesh = _dust_mesh()
		dust.transform = _frame.translated_local(
			Vector3(side * (_half_width - 0.4), 0.4, -_runoff * 0.3)
		)
		add_child(dust)


func _dust_mesh() -> Mesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = material
	return quad


# --- Helpers ------------------------------------------------------------------


## A box with no body under it. Shadows off throughout: the gateway is large, it
## sits directly over the finish line, and a shadow cast across the deck at the
## moment the field arrives would darken the exact patch of track the player is
## reading the order off.
func _add_mesh(transform: Transform3D, size: Vector3, colour: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _make_material.call(colour)
	visual.transform = transform
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
