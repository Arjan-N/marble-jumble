class_name FoundryCourse
extends Course

## Foundry Floor — one flat plate, tilted, with machinery on it.
##
## Every other course in the pool gets its character from its *terrain*: the
## canyon's shaped vertical profile, the jungle's dish and camber, the duct's
## roll, the volcano's plunges, the ruins' spiral. This one deliberately has
## none. `PITCH` is a single constant and `HEADING` is empty, so the running
## surface is literally one inclined plane from the start line to the finish —
## no dish, no bank, no crease, no elevation change beyond the tilt itself.
##
## That is the point, and it is why this is not a reskin. On a plate, terrain
## can no longer be the answer to anything, so everything interesting has to be
## a *machine* — and a machine differs from terrain in the one way that matters:
## it is somewhere different depending on when you arrive. A funnel narrows the
## course for everybody equally. A ram is either out or in.
##
## | | Every other course | Foundry |
## | --- | --- | --- |
## | Descent | shaped profile | **one constant angle, nothing held back** |
## | Plan | straight or turning | **straight; the plate never bends** |
## | Section | dish, duct or trough | **flat, with kerbs bolted on where needed** |
## | Interest from | terrain, with obstacles on it | **machines, on nothing** |
## | Timing | the same course for everyone | **when you arrive decides what you meet** |
##
## Six obstacles are new, and each acts in an axis nothing here had before:
##
## - `ConveyorBelt` moves a marble *sideways* without touching its speed, which
##   makes it the only thing in this codebase that steers.
## - `PistonRam` is *intermittent* — the first obstacle that can be absent.
## - `SwingingHammer` arrives from *above* and leaves upward, so what it catches
##   is thrown rather than deflected.
## - `StampPress` *occupies*: it does not hit a marble, it shuts a lane and
##   stays shut, so the field has to be somewhere else rather than wait.
## - `PaddleDrum` turns about the *across-track* axis, so its strike is forward
##   and downward at once — the only one that is not a deflection.
## - `Turntable` steers by *where* you cross it rather than by when, which makes
##   it the course's one spreader against belts that all gather.
##
## `DECISIONS.md` §"Future obstacle vocabulary" parks conveyors, pistons,
## launchers and moving platforms as post-Phase-0, and `RotatingBumper` has been
## the only permitted obstacle until now. Building the six above is a
## deliberate departure, made because Arjan asked for a course whose content is
## new obstacles rather than new ground, and then asked for more of them. It is
## recorded here rather than assumed: if the answer is that Phase 0 stays on one
## obstacle, this course is the thing to drop, not the plate.
##
## Fourteen beats over 340m — by a distance the longest thing in the pool,
## because a flat plate has no drops to spend and needs the length to hold
## fourteen machines without any two of them acting on the same marble at once:
##
##   Loading Bay | Crossbelts | Ram Row | Spin Yard | Drum Line | Drift Bay |
##   Hammer Alley | Press Line | Turn Yard | Gauntlet | Brake Belt |
##   Casting Pit | Quench Line | Sorter Run
##
## The five new beats are interleaved rather than appended. A course whose
## second half is all new machinery reads as two courses joined; alternating
## them with the beats that were already here keeps the plate feeling like one
## building the field is travelling through.
##
## **On duration, and it is not settled.** `DECISIONS.md` §"Course length"
## targets 20–30 seconds. This course was already over it at 240m — a 12-marble
## probe ran 31–45s — and at 340m the same probe runs **54–65s**. The pitch
## increase below claws back some of the per-metre pace and nothing like all of
## it, because the field here is limited by what the machines take off it rather
## than by the slope.
##
## That overrun is real and it is the course's, not the probe's. It is left
## standing rather than fixed by deleting beats, because the length and the
## machine count are what was asked for and dropping either to hit a number is a
## scope decision rather than a tuning one. The lever if it has to come down is
## the beat list above — Turn Yard and Quench Line are the two that cost the most
## time for the least elimination — not the plate and not the pitch.

# --- Shape --------------------------------------------------------------------

const LENGTH := 340.0
const RAMP_LENGTH := 14.0
## The run-out past the line, where the field actually comes to rest now.
##
## Was 8 metres, which was only ever enough to reach a wall: a marble crossed,
## rolled for a moment and was stopped. `FinishZone` ramps damping across this
## distance instead, so it has to be long enough for that ramp to do the work —
## the marble slows because the runoff slows it, not because something is in the
## way. `CoursePath` also eases the descent off across it (see `RUNOFF_FLATTEN`),
## so the far end is near level.
const RUNOFF_LENGTH := 30.0

## Section boundaries, as fractions of `LENGTH`.
const BAY_END := 0.055
const CROSSBELT_END := 0.120
const RAM_ROW_END := 0.185
const SPIN_YARD_END := 0.245
const DRUM_END := 0.310
const DRIFT_END := 0.375
const HAMMER_END := 0.435
const PRESS_END := 0.505
const TURN_END := 0.575
const GAUNTLET_END := 0.650
const BRAKE_END := 0.710
const PIT_END := 0.800
const QUENCH_END := 0.890

## One number, and it never changes. A pitch *profile* is exactly the tool this
## course is refusing to use — the whole premise is that the ground does nothing
## anywhere, so speed is only ever given or taken by a machine.
##
## 14.5 degrees sits at the top of the other courses' plunges (13–16), and it is
## a degree and a half steeper than the 240m version of this course ran at. That
## is not a taste change: the course is 100m longer, `DECISIONS.md` §"Course
## length" wants 20–30 seconds, and the 240m plate was already over it. Pitch is
## the only lever that shortens the race without removing a machine — and it is a
## weak one here, worth single-digit percent, because the field's speed is set by
## what the belts and hammers take off it rather than by the slope. It is not
## pushed further for that reason: every machine is tuned against the rate the
## field arrives at it, so buying a few more seconds with pitch alone would mean
## re-tuning all fourteen beats.
##
## The old comment's objection to going steeper was that the field would arrive
## at the hammers faster than they can swing. That is still true and it is why
## `HAMMER_PERIOD` came down with this — the two numbers only make sense
## together, and changing one without the other is what turns Hammer Alley into
## either a wall or a decoration.
##
## Shallower and the brake belt at `BRAKE_AT` stops being a delay and becomes a
## wall.
const PITCH := [[1.00, 14.5]]

## Empty. `CoursePath` treats an absent heading profile as dead straight, which
## is what a plate is.
const HEADING := []

## Half-width along the course, as `[[fraction, metres], ...]`. The one thing
## that does vary, because it costs nothing on a plate — the plate is simply
## wider or narrower, with no camber or section change implied.
##
## Never below 3.4: two marbles abreast is 1.8m, and every squeeze here has a
## machine in it, so the field needs room to resolve one.
const WIDTH := [
	[0.045, 7.4],
	[BAY_END, 7.0],
	[0.085, 6.2],          ## Crossbelts.
	[CROSSBELT_END, 6.2],
	[0.130, 5.4],          ## Ram Row: tight enough that a ram covers half of it.
	[RAM_ROW_END, 5.4],
	[SPIN_YARD_END, 7.2],  ## Spin Yard: two bumpers in it.
	[0.255, 6.4],          ## Drum Line: three wheels, and lanes past each.
	[DRUM_END, 6.4],
	[0.335, 6.6],
	[DRIFT_END, 6.6],      ## Drift Bay, and the only span with no kerbs.
	[0.385, 5.4],          ## Hammer Alley.
	[HAMMER_END, 5.4],
	[0.445, 6.8],          ## Press Line: a press shuts a lane, so there
	[PRESS_END, 6.8],      ## have to be lanes it is not shutting.
	[0.520, 7.2],          ## Turn Yard: widest on the course. A table needs the
	[TURN_END, 7.2],       ## room to throw somebody a lane over and not off.
	[0.590, 5.6],          ## Gauntlet.
	[GAUNTLET_END, 5.6],
	[BRAKE_END, 5.8],      ## Brake Belt.
	[0.740, 6.2],          ## Casting Pit approach.
	[PIT_END, 6.2],
	[0.825, 6.4],          ## Quench Line.
	[QUENCH_END, 6.4],
	[0.955, 5.0],          ## Sorter Run.
	[1.00, 4.6],
]

## How far the plate continues past the racing width. Not a shoulder — it is
## flat, like the rest — but a marble knocked to the edge deserves the chance to
## come back rather than being eliminated by the width profile.
const OVERHANG := 0.7

const MESH_STEP := 1.0
const SECTION_STEP := 0.5
const RUN_OVERLAP := 0.35

# --- Kerbs --------------------------------------------------------------------

## Kerb, not wall: 0.8m against a 0.9m marble stops a roll and does not stop a
## marble the hammers have thrown. A plate with full walls would make every
## machine here consequence-free, and a plate with none would let the drift belt
## alone eliminate half the field.
const KERB_HEIGHT := 0.8
const KERB_THICKNESS := 0.35
const KERB_STEP := 4.0
## Spans, as fractions, that get kerbs. Drift Bay is deliberately absent — being
## quietly steered towards an edge that is really there is the whole of that
## beat — and so is the Casting Pit itself, whose edges are the jump.
##
## The kerbs run right up to the take-off lip and resume on the landing rather
## than leaving the whole approach open. Left open, the landing was where the
## course lost most of its field: a marble touching down with any lateral speed
## at all simply carried on sideways off the plate.
const KERBED := [
	[-RAMP_LENGTH / LENGTH, DRIFT_END - 0.055],
	[DRIFT_END, KICKER_AT + KICKER_LENGTH / LENGTH],
	[KICKER_AT + (KICKER_LENGTH + JUMP_GAP) / LENGTH, 1.0 + RUNOFF_LENGTH / LENGTH],
]

# --- Surfaces -----------------------------------------------------------------

const SURFACE_PLATE := {"friction": 0.30, "colour": Color(0.42, 0.44, 0.47)}
const SURFACE_GRATING := {"friction": 0.42, "colour": Color(0.32, 0.34, 0.37)}
const SURFACE_OILED := {"friction": 0.15, "colour": Color(0.24, 0.25, 0.29)}
const SURFACE_RUBBER := {"friction": 0.48, "colour": Color(0.30, 0.26, 0.26)}
const SURFACE_HOT := {"friction": 0.26, "colour": Color(0.52, 0.38, 0.31)}
## Quench Line: wet steel. Slicker than the oiled floor of the Drift Bay,
## because the Drift Bay has a belt doing the work and this one has to make a
## single wheel and a pair of crossbelts matter on their own.
const SURFACE_QUENCH := {"friction": 0.13, "colour": Color(0.22, 0.30, 0.35)}

## Friction is the varying surface property here, as on the canyon and the
## jungle — not bounce. A plate with no walls and a bouncy floor is a course
## that eliminates the field at random, which `OrbitalCourse` only gets away
## with because it has a roof.
const SURFACES := [
	[BAY_END, SURFACE_PLATE],
	[CROSSBELT_END, SURFACE_PLATE],
	[RAM_ROW_END, SURFACE_GRATING],
	[SPIN_YARD_END, SURFACE_PLATE],
	[DRUM_END, SURFACE_RUBBER],   ## Drum Line: grip, so a slapped marble goes
	                              ## where it was slapped instead of sliding on.
	[DRIFT_END, SURFACE_OILED],   ## Drift Bay: slick, so the belt wins.
	[HAMMER_END, SURFACE_GRATING],
	[PRESS_END, SURFACE_PLATE],
	[TURN_END, SURFACE_GRATING],  ## Turn Yard: the tables are the slick thing
	                              ## here, and only if the floor is not.
	[GAUNTLET_END, SURFACE_HOT],
	[BRAKE_END, SURFACE_RUBBER],  ## Brake Belt: grippy floor either side of it.
	[PIT_END, SURFACE_HOT],
	[QUENCH_END, SURFACE_QUENCH],
	[1.00, SURFACE_PLATE],
]
const BOUNCE := 0.08

# --- Machines -----------------------------------------------------------------

## Crossbelts: two belts abreast, driving *towards each other*. A field that has
## spread across the bay is folded back into the middle of the course without
## the course narrowing — the equaliser `JungleCourse` builds out of a funnel,
## built out of surface motion instead, and it works on a marble that has
## stopped as well as on one still moving.
## Two pairs: one folding the field out of the Loading Bay, one on the wet steel
## of the Quench Line where there is no grip to resist them with.
const CROSSBELT_ROW := [
	[0.092, 2.6],
	[0.832, 2.2],   ## Quench Line: gentler, because the floor under it is not.
]
const CROSSBELT_LENGTH := 9.0

## Ram Row: three rams alternating sides, on thirds of a cycle, in the narrowest
## span before the hammers. The stroke is a little over half the local width on
## purpose — a ram that could reach the far kerb would be a gate.
const RAM_ROW := [
	[0.135, -1.0, 0.00],
	[0.159, 1.0, 0.34],
	[0.183, -1.0, 0.67],
]
const RAM_STROKE := 2.6

## Spin Yard: the obstacle Phase 0 already had, twice, offset either side of the
## centreline. Familiar, deliberately — it is the beat where the player
## recognises something.
const BUMPER_ROW := [
	[0.203, -1.7],
	[0.235, 1.9],
]

## Drum Line: three paddle wheels, laid out so no two of them cover the same
## lane and the lane past each one is on the opposite side to the last. A wheel
## slaps a marble forward, so this beat is the one place on the course where
## arriving badly makes you *quicker* — it is the counterweight to the brake
## belt, and it is deliberately early, where the field is still bunched.
##
## `[fraction, lateral, phase]`.
const DRUM_ROW := [
	[0.262, -2.6, 0.00],
	[0.283, 2.6, 0.33],
	[0.303, 0.0, 0.66],
	## Gauntlet: one on the centreline, immediately after the second ram, so a
	## marble shoved into the middle by a ram is the marble the wheel gets.
	[0.645, 0.0, 0.20],
	## Quench Line: the last wheel, on wet steel, where a slap carries.
	[0.868, 0.0, 0.50],
]
const DRUM_WIDTH := 4.6

## Drift Bay: one belt across the full racing width, driving right, over oiled
## floor with no kerbs. Slower than the crossbelts and far longer, so it is a
## steady pull rather than a shove — roughly a metre and a half of sideways
## travel at racing speed, which is a lane, not a cliff.
const DRIFT_AT := 0.345
const DRIFT_LENGTH := 12.0
const DRIFT_SPEED := 2.9

## Hammer Alley: two hammers on a gantry over the narrowest span, in
## antiphase — the second is open exactly when the first is not. Three of them
## was the first draft and it was a wall: each hit costs a marble most of its
## speed, and a course this long cannot afford three of those in twelve metres. The kerbs are back for this, because a thrown marble has to land
## somewhere and "off the course" three times over is not a race.
##
## The third entry is not part of the Alley — it is the Gauntlet's single
## hammer, listed here so it gets a gantry from `_build_gantries` like the
## others. Two beats apart, a hammer is a callback rather than a repeat.
const HAMMER_ROW := [
	[0.390, 0.00],
	[0.425, 0.50],
	[0.618, 0.25],
]

## Press Line: four presses, each shutting one lane of the widest straight
## before the Turn Yard, on quarters of a cycle so the open lane walks across
## the course. A marble that holds its line through all four has been lucky;
## the beat is designed to be crossed diagonally.
##
## `[fraction, lateral, phase]`.
const PRESS_ROW := [
	[0.446, -2.6, 0.00],
	[0.464, 2.6, 0.25],
	[0.482, -2.6, 0.50],
	[0.500, 2.6, 0.75],
]
const PRESS_WIDTH := 4.0

## Turn Yard: two tables off either side of the centreline, counter-rotating, so
## the pair drives the middle of the course *forward* and the two outsides
## towards their own kerbs. A field that comes through the middle is squeezed
## and quick; one that spreads early gets walked into the kerbs it was heading
## for anyway.
##
## `[fraction, lateral, turns_per_second]`.
const TURNTABLE_ROW := [
	[0.528, -2.6, 0.32],
	[0.556, 2.6, -0.32],
]
const TURNTABLE_RADIUS := 3.2

## Gauntlet: the beat that has no new machine in it, and is the one place the
## course puts three *different* old ones inside twenty metres — ram, hammer,
## ram, wheel. Everything before it introduces something; this is where the
## course asks whether the field has learned anything, and it is placed
## immediately before the brake belt so whatever survives arrives slow.
const GAUNTLET_RAMS := [
	[0.598, -1.0, 0.15],
	[0.632, 1.0, 0.65],
]
## Pivot height, and it is derived rather than chosen: arm plus head plus a
## little clearance. Hung at 3.1 the head sat half a metre inside the plate and
## scooped marbles upward off the course instead of striking them across it —
## the single worst thing in the first probe run.
const HAMMER_PIVOT_HEIGHT := SwingingHammer.ARM_LENGTH + SwingingHammer.HEAD_RADIUS + 0.14
## Down from 2.4 with the pitch increase above, and for that reason only: a
## hammer's job is to be somewhere different depending on when you arrive, and a
## field arriving 10% faster past a swing that has not changed is a field that
## meets the same part of the arc every time.
const HAMMER_PERIOD := 2.2

## Brake Belt: a belt running back *up* the course. The only thing in the pool
## that takes speed away without a collision, and the reason the Casting Pit
## needs a boost pad in front of it.
const BRAKE_AT := 0.685
const BRAKE_LENGTH := 7.0
const BRAKE_SPEED := 1.9

## Casting Pit: the one hole. Ramp-then-gap with a boost in front of it, the
## recipe both `JungleCourse` and `VolcanoCourse` had to arrive at before a gap
## was survivable rather than a filter — see `BoostPad`'s header
## for why the boost is what makes the gap sizeable at all.
const KICKER_AT := 0.745
const KICKER_LENGTH := 6.0
const KICKER_RISE := 1.3
const JUMP_GAP := 3.4
const BOOST_SPEED := 14.0

## Sorter Run: a last pair of rams, half a cycle apart, so the run-in is never
## clear on both sides at once.
##
## Staggered along the course, not facing each other across it. Placed at the
## same point they periodically closed on a marble from both sides at once and
## extruded it straight off the plate — a probe run lost four marbles inside the
## last 25m to exactly that.
const SORTER_RAMS := [
	[0.918, -1.0, 0.00],
	[0.958, 1.0, 0.50],
]
const SORTER_STROKE := 1.6

const MIN_GAP := 1.5

# --- Decoration ---------------------------------------------------------------

const STEEL := Color(0.50, 0.52, 0.55)
const STEEL_DARK := Color(0.28, 0.29, 0.32)
const GANTRY_COLOUR := Color(0.44, 0.45, 0.48)
const GLOW_COLOUR := Color(1.0, 0.55, 0.18, 0.5)
const FINISH_COLOUR := Color(0.92, 0.86, 0.42)
## How far below the plate the dull orange floor-glow plane sits. Same
## relationship `VolcanoCourse.LAVA_BELOW` has to its own drop: purely visual,
## since anything that gets there is already
## eliminated by `fall_threshold_y`.
const GLOW_BELOW := 22.0

var _path: CoursePath


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_plate()
	_build_kerbs()
	_build_back_wall()
	_build_glow_floor()
	_build_crossbelts()
	_build_rams()
	_build_spin_yard()
	_build_drums()
	_build_drift_bay()
	_build_hammers()
	_build_presses()
	_build_turn_yard()
	_build_brake_belt()
	_build_boost()
	_build_gantries()
	_build_finish_line()


# --- Path ---------------------------------------------------------------------


func _point(s: float) -> Vector3:
	return _path.point_at(s)


## `Course.frame_at` for a course laid out along a `CoursePath`.
##
## Camber comes from the path and the origin comes from the curve, rather than
## both from the path. The curve is a polyline through sampled points, so its
## arc length drifts against the path's by a metre or two over a course, and
## the offset handed in here was measured against the curve — by the camera,
## and by the ranking that decided which marble the cut is at. Taking the
## position from the curve puts the marker where the rest of the race already
## agrees that offset is; the drift only shifts which bank angle is sampled,
## and over a metre of track that is a fraction of a degree.
func frame_at(offset: float) -> Transform3D:
	if curve == null:
		return Transform3D.IDENTITY

	var length := curve.get_baked_length()
	var clamped := clampf(offset, 0.0, length)
	var frame := _frame_at(_path.s_at_curve_offset(clamped, length))
	return Transform3D(frame.basis, curve.sample_baked(clamped))


func _frame_at(s: float) -> Transform3D:
	return _path.frame_at(s)


func _half_width_at(s: float) -> float:
	return _path.sample(WIDTH, s)


func _surface_at(s: float) -> Dictionary:
	var fraction := s / LENGTH
	for entry: Array in SURFACES:
		if fraction <= entry[0]:
			return entry[1]
	return SURFACES[SURFACES.size() - 1][1]


# --- The plate ----------------------------------------------------------------


func _build_plate() -> void:
	for run: Dictionary in _runs():
		var from_s: float = run["from"] - (RUN_OVERLAP if run["lead"] else 0.0)
		var to_s: float = run["to"] + (RUN_OVERLAP if run["trail"] else 0.0)
		_build_run(from_s, to_s, run["surface"])


## The plate split into stretches of constant surface with the Casting Pit's gap
## cut out.
func _runs() -> Array:
	var cuts := [-RAMP_LENGTH, LENGTH + RUNOFF_LENGTH]
	for entry: Array in SURFACES:
		cuts.append(entry[0] * LENGTH)
	var hole := _jump_span()
	cuts.append(hole.x)
	cuts.append(hole.y)
	cuts.sort()

	var runs := []
	for i in range(cuts.size() - 1):
		var from_s: float = cuts[i]
		var to_s: float = cuts[i + 1]
		if to_s - from_s < 0.2:
			continue
		if _in_hole((from_s + to_s) * 0.5, hole):
			continue
		runs.append({
			"from": from_s,
			"to": to_s,
			"surface": _surface_at((from_s + to_s) * 0.5),
			"lead": absf(from_s - hole.x) > 0.01 and absf(from_s - hole.y) > 0.01,
			"trail": absf(to_s - hole.x) > 0.01 and absf(to_s - hole.y) > 0.01,
		})
	return runs


func _jump_span() -> Vector2:
	var lip := KICKER_AT * LENGTH + KICKER_LENGTH
	return Vector2(lip, lip + JUMP_GAP)


func _in_hole(s: float, hole: Vector2) -> bool:
	return s > hole.x and s < hole.y


## The only departure from flat on the whole course, and it is a ramp rather
## than a shape: squared on the way up so the lip is where the kicker is
## steepest, held across the (unbuilt) gap, eased back down into the landing.
func _kicker_lift(s: float) -> float:
	var from_s := KICKER_AT * LENGTH
	var lip := from_s + KICKER_LENGTH
	var landing := lip + JUMP_GAP
	var settle := 6.0

	if s <= from_s:
		return 0.0
	if s < lip:
		var t := (s - from_s) / KICKER_LENGTH
		return KICKER_RISE * t * t
	return KICKER_RISE * (1.0 - smoothstep(0.0, settle, s - landing))


## `(lateral, lift)` in the local frame, for a lateral offset in *metres*. The
## dish courses normalise their lateral against the half-width because their
## lift depends on how far across the section a point is; here it never does,
## so this course works in metres directly.
func _section_point(lateral: float, s: float) -> Vector2:
	return Vector2(lateral, _kicker_lift(s))


## Lateral offsets across the plate at `s`, in metres. The count is fixed and
## the spacing stretches with the width rather than the other way round: a
## constant spacing would change the vertex count as the plate widens, and two
## adjacent rows with different counts cannot be stitched into quads.
func _section_laterals(s: float) -> Array:
	var edge := _half_width_at(s) + OVERHANG
	var count := int(ceil((_max_half_width() + OVERHANG) / SECTION_STEP))
	var laterals := []
	for i in range(-count, count + 1):
		laterals.append(edge * float(i) / float(count))
	return laterals


func _max_half_width() -> float:
	var widest := 0.0
	for entry: Array in WIDTH:
		widest = maxf(widest, entry[1])
	return widest


func _section_row(s: float) -> Array:
	var frame := _frame_at(s)
	var row := []
	for lateral: float in _section_laterals(s):
		var node := _section_point(lateral, s)
		row.append(frame * Vector3(node.x, node.y, 0.0))
	return row


func _build_run(from_s: float, to_s: float, surface: Dictionary) -> void:
	var rows := []
	var s := from_s
	while s < to_s - 0.01:
		rows.append(_section_row(s))
		s = minf(s + MESH_STEP, to_s)
	rows.append(_section_row(to_s))

	if rows.size() < 2:
		return

	var faces := PackedVector3Array()
	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(near.size() - 1):
			faces.append(near[c])
			faces.append(far[c])
			faces.append(near[c + 1])

			faces.append(near[c + 1])
			faces.append(far[c])
			faces.append(far[c + 1])

	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.generate_normals()

	var body := StaticBody3D.new()
	body.physics_material_override = _surface_material(surface["friction"])

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = false
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _material(surface["colour"])
	body.add_child(visual)

	add_child(body)


## Kerbs are separate boxes rather than part of the section, so removing them
## for a span costs nothing and leaves the plate underneath exactly as flat as
## it is everywhere else.
func _build_kerbs() -> void:
	for span: Array in KERBED:
		var s: float = span[0] * LENGTH
		var end: float = span[1] * LENGTH
		while s < end - 0.01:
			var to_s := minf(s + KERB_STEP, end)
			var middle := (s + to_s) * 0.5
			var half_width := _half_width_at(middle)
			var colour := STEEL_DARK if int(s / KERB_STEP) % 2 == 0 else STEEL
			for side: float in [-1.0, 1.0]:
				_add_box(
					_frame_at(middle).translated_local(Vector3(
						side * (half_width + OVERHANG - KERB_THICKNESS * 0.5),
						_kicker_lift(middle) + KERB_HEIGHT * 0.5,
						0.0,
					)),
					Vector3(KERB_THICKNESS, KERB_HEIGHT, to_s - s),
					colour,
				)
			s = to_s


func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(Vector3(0.0, 1.2, 0.4)),
		Vector3(_half_width_at(-RAMP_LENGTH) * 2.0, 2.4, 0.8),
		STEEL_DARK,
	)


# --- Machines -----------------------------------------------------------------


## `ConveyorBelt.constant_linear_velocity` is read by the solver in global
## space, so the drive vector is turned into the course frame here rather than
## left local: +X in that frame is track-right, -Z is down-course.
func _add_belt(s: float, lateral: float, width: float, length: float, drive: Vector3) -> void:
	var frame := _frame_at(s)
	var belt := ConveyorBelt.create(width, length, frame.basis * drive)
	belt.transform = frame.translated_local(Vector3(lateral, _kicker_lift(s), 0.0))
	add_child(belt)


func _build_crossbelts() -> void:
	for entry: Array in CROSSBELT_ROW:
		var s: float = entry[0] * LENGTH
		var half_width := _half_width_at(s)
		for side: float in [-1.0, 1.0]:
			_add_belt(
				s,
				side * half_width * 0.5,
				half_width,
				CROSSBELT_LENGTH,
				Vector3(-side * float(entry[1]), 0.0, 0.0),
			)


func _build_rams() -> void:
	for entry: Array in RAM_ROW:
		_add_ram(entry[0] * LENGTH, entry[1], entry[2], RAM_STROKE)
	for entry: Array in GAUNTLET_RAMS:
		_add_ram(entry[0] * LENGTH, entry[1], entry[2], RAM_STROKE)
	for entry: Array in SORTER_RAMS:
		_add_ram(entry[0] * LENGTH, entry[1], entry[2], SORTER_STROKE)


## `side` is -1 for a ram mounted on the left kerb, +1 for the right. A ram only
## ever fires along its own +X, so the right-hand one is the same object yawed
## 180 degrees.
func _add_ram(s: float, side: float, phase: float, stroke: float) -> void:
	var half_width := _half_width_at(s)
	_assert_gap(
		half_width * 2.0 - stroke,
		"ram at %.3f with %.1fm stroke" % [s / LENGTH, stroke]
	)

	# Mounted so the *inner face* of the retracted head is flush with the kerb,
	# which is why the head's own half-width is in here. Centred on the kerb
	# instead, a retracted ram stood 0.8m out into the track as a permanent wall
	# square to the direction of travel, and a probe run had a marble park in the
	# corner between it and the kerb for the rest of the race.
	var ram := PistonRam.create(stroke, phase)
	var frame := _frame_at(s).translated_local(Vector3(
		side * (half_width + OVERHANG - KERB_THICKNESS + PistonRam.HEAD_WIDTH * 0.5),
		_kicker_lift(s) + PistonRam.HEAD_HEIGHT * 0.5,
		0.0,
	))
	if side > 0.0:
		frame.basis = frame.basis.rotated(frame.basis.y.normalized(), PI)
	ram.transform = frame
	add_child(ram)


func _build_spin_yard() -> void:
	for entry: Array in BUMPER_ROW:
		var s: float = entry[0] * LENGTH
		var bumper := RotatingBumper.create()
		bumper.transform = _frame_at(s).translated_local(
			Vector3(entry[1], _kicker_lift(s), 0.0)
		)
		add_child(bumper)


func _build_drift_bay() -> void:
	var s := DRIFT_AT * LENGTH
	_add_belt(
		s,
		0.0,
		_half_width_at(s) * 2.0,
		DRIFT_LENGTH,
		Vector3(DRIFT_SPEED, 0.0, 0.0),
	)


## Wheels sit on their axle, so the height handed in is `HUB_HEIGHT` rather than
## the floor — the blades hang from it and the ground clearance falls out of the
## radius. See `PaddleDrum`'s header for why that clearance is never zero.
func _build_drums() -> void:
	for entry: Array in DRUM_ROW:
		var s: float = entry[0] * LENGTH
		_assert_gap(
			_half_width_at(s) * 2.0 - DRUM_WIDTH,
			"paddle drum at %.3f" % [entry[0]]
		)
		var drum := PaddleDrum.create(DRUM_WIDTH, entry[2])
		drum.transform = _frame_at(s).translated_local(Vector3(
			entry[1], _kicker_lift(s) + PaddleDrum.HUB_HEIGHT, 0.0
		))
		add_child(drum)


## Presses hang from the same gantry line the hammers do — `StampPress.OPEN_LIFT`
## plus its slab is under `HAMMER_PIVOT_HEIGHT`, so an open press is clear of
## everything a hammer can throw.
func _build_presses() -> void:
	for entry: Array in PRESS_ROW:
		var s: float = entry[0] * LENGTH
		_assert_gap(
			_half_width_at(s) * 2.0 - PRESS_WIDTH,
			"stamp press at %.3f" % [entry[0]]
		)
		var press := StampPress.create(PRESS_WIDTH, entry[2])
		press.transform = _frame_at(s).translated_local(
			Vector3(entry[1], _kicker_lift(s), 0.0)
		)
		add_child(press)


func _build_turn_yard() -> void:
	for entry: Array in TURNTABLE_ROW:
		var s: float = entry[0] * LENGTH
		var table := Turntable.create(TURNTABLE_RADIUS, entry[2])
		table.transform = _frame_at(s).translated_local(
			Vector3(entry[1], _kicker_lift(s), 0.0)
		)
		add_child(table)


func _build_hammers() -> void:
	for entry: Array in HAMMER_ROW:
		var s: float = entry[0] * LENGTH
		var hammer := SwingingHammer.create(HAMMER_PERIOD, entry[1])
		hammer.transform = _frame_at(s).translated_local(
			Vector3(0.0, _kicker_lift(s) + HAMMER_PIVOT_HEIGHT, 0.0)
		)
		add_child(hammer)


## Drives back up the course, so a marble crossing it is slowed by friction
## against a surface travelling the other way rather than by anything scripted.
func _build_brake_belt() -> void:
	var s := BRAKE_AT * LENGTH
	_add_belt(
		s,
		0.0,
		_half_width_at(s) * 2.0,
		BRAKE_LENGTH,
		Vector3(0.0, 0.0, BRAKE_SPEED),
	)


func _build_boost() -> void:
	var at := KICKER_AT * LENGTH - 3.5
	var frame := _frame_at(at)
	var pad := BoostPad.create(_half_width_at(at) * 2.0, -frame.basis.z, BOOST_SPEED)
	pad.transform = frame.translated_local(Vector3(0.0, 1.2, 0.0))
	add_child(pad)


# --- Decoration ---------------------------------------------------------------


## Overhead frames the hammers hang from, plus a few empty ones. Non-colliding:
## a beam over the track is a thing a thrown marble can wedge under.
func _build_gantries() -> void:
	# Every hammer needs one, since it hangs from it, and every press and wheel
	# gets one because a machine that appears out of nothing over a bare plate
	# reads as a bug. The rest are empty frames so the gantry line reads as a
	# building the course runs through rather than as isolated mountings.
	var positions := [0.075, 0.225, 0.355, 0.700, 0.935]
	for row: Array in [HAMMER_ROW, PRESS_ROW, DRUM_ROW]:
		for entry: Array in row:
			positions.append(entry[0])

	for fraction: float in positions:
		var s := fraction * LENGTH
		var half_width := _half_width_at(s)
		var frame := _frame_at(s)

		var beam := BoxMesh.new()
		beam.size = Vector3((half_width + OVERHANG) * 2.0, 0.28, 0.28)
		var beam_visual := MeshInstance3D.new()
		beam_visual.mesh = beam
		beam_visual.material_override = _material(GANTRY_COLOUR)
		beam_visual.transform = frame.translated_local(
			Vector3(0.0, HAMMER_PIVOT_HEIGHT + 0.2, 0.0)
		)
		add_child(beam_visual)

		for side: float in [-1.0, 1.0]:
			var post := BoxMesh.new()
			post.size = Vector3(0.26, HAMMER_PIVOT_HEIGHT + 0.2, 0.26)
			var post_visual := MeshInstance3D.new()
			post_visual.mesh = post
			post_visual.material_override = _material(GANTRY_COLOUR)
			post_visual.transform = frame.translated_local(Vector3(
				side * (half_width + OVERHANG),
				(HAMMER_PIVOT_HEIGHT + 0.2) * 0.5,
				0.0,
			))
			add_child(post_visual)


## A dull orange plane far below the plate — molten metal in the pit under the
## foundry floor, so falling off reads as a consequence rather than as the level
## simply ending. Visual only.
func _build_glow_floor() -> void:
	var s := -RAMP_LENGTH
	while s < LENGTH + RUNOFF_LENGTH:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(50.0, 1.0, 14.0)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = GLOW_COLOUR
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		visual.material_override = material
		visual.transform = _frame_at(s).translated_local(Vector3(0.0, -GLOW_BELOW, 0.0))
		add_child(visual)

		s += 14.0


func _build_finish_line() -> void:
	var width := _half_width_at(LENGTH) * 2.0

	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.06, 1.0)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(FINISH_COLOUR)
	visual.transform = _frame_at(LENGTH).translated_local(Vector3(0.0, 0.04, 0.0))
	add_child(visual)

	# The kerb closing the run-out. Was a 2.4m wall six metres past the line, and
	# it was what actually stopped a race: cross, roll, hit wall. `FinishZone`
	# has taken nearly all of a finisher's speed by the time it reaches this, so
	# it catches a slow roll rather than ending a race — and it is low enough not
	# to stand up in front of the field the camera is watching arrive.
	_add_box(
		_frame_at(LENGTH + RUNOFF_LENGTH - 1.2).translated_local(Vector3(0.0, 0.35, 0.0)),
		Vector3(width, 0.7, 0.6),
		STEEL_DARK,
	)


# --- Helpers ------------------------------------------------------------------


func _assert_gap(gap: float, what: String) -> void:
	assert(
		gap >= MIN_GAP,
		"%s leaves %.2fm, under MIN_GAP (%.2fm); marbles wedge." % [what, gap, MIN_GAP]
	)


func _add_box(transform: Transform3D, size: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new()
	body.transform = transform
	body.physics_material_override = _surface_material()

	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(colour)
	body.add_child(visual)

	add_child(body)


func _surface_material(friction := -1.0) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = SURFACE_PLATE["friction"] if friction < 0.0 else friction
	material.bounce = BOUNCE
	return material


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	material.metallic = 0.1
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


# --- Course interface ---------------------------------------------------------


func fall_threshold_y() -> float:
	return _point(LENGTH).y - 26.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func finish_runoff() -> float:
	return RUNOFF_LENGTH


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


func jump_clearance(position: Vector3) -> float:
	if curve == null:
		return INF

	var lip := KICKER_AT * LENGTH + KICKER_LENGTH
	var s := curve.get_closest_offset(position) - RAMP_LENGTH
	if s < lip - 3.0 or s > lip + JUMP_GAP + 6.0:
		return INF

	return s - (lip + JUMP_GAP)


## Six across, on the widest starting area in the pool. The plate is flat, so
## unlike the dish courses a marble spawned near the edge starts level with one
## spawned in the middle — which is why this course can afford a wider, shallower
## grid than they can.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 6
	var spacing := 1.75

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.5 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(
			Transform3D(Basis.IDENTITY, _frame_at(-back) * Vector3(x, 0.6, 0.0))
		)

	return spawns
