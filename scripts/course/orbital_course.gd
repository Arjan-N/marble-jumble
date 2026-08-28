class_name OrbitalCourse
extends Course

## The third course: a derelict orbital transfer duct.
##
## Space, and rectangular in section like the canyon — flat floor, vertical
## walls, no dish. `PROJECT.md` §2.4 says the physical interaction a course
## creates matters more than its theme, so a canyon painted black with stars
## behind it would be a reskin. Keeping the canyon's *section* and changing
## everything that section is used for is the opposite trade: it looks like the
## course you know and plays like one you do not.
##
## | | Canyon | Jungle | Orbital |
## | --- | --- | --- | --- |
## | Section | flat floor, vertical walls | rounded channel | flat floor, vertical walls, **and a roof** |
## | Grip | friction varies, bounce fixed | friction varies, bounce fixed | **bounce varies, friction near-fixed** |
## | Up | fixed | camber follows the corners | **authored roll: the duct corkscrews** |
## | Descent | continuous | held back, then released | **flat runs punctuated by plunges** |
## | Split | two lanes, unequal width | one ridge, pick a side | **three lanes, unequal *length*** |
## | Falling | into a hole | into several holes | **sideways, off one unwalled truss** |
##
## The ten things done differently from the canyon, each of which changes how the
## course plays rather than what it looks like:
##
## 1. **It is closed.** Floor, walls *and* a roof. Nothing else here has a lid,
##    and most of what follows only works because it does.
## 2. **Bounce is the surface property that varies**, not friction. The canyon
##    runs rough stone against poured track at a fixed 0.3 restitution; this runs
##    0.05 to 0.58 at a near-constant, low friction. Marbles skip and ricochet
##    where they used to grip and roll.
## 3. **The roof is what makes 2 survivable.** A 0.58 restitution stretch in an
##    open trough throws a third of the field out of the level; under a lid the
##    same stretch is a pinball hall. The lid is glass, for the camera's sake —
##    see `_build_roof`.
## 4. **Speed arrives in bursts.** The canyon descends continuously and the field
##    simply accumulates; `PITCH` here alternates near-flat 5.5–6.5 degree runs
##    with three short plunges, so a marble is either being given speed or
##    spending it, and rarely both.
## 5. **The duct rolls.** `CoursePath` gained an authored roll profile for this:
##    between 0.36 and 0.58 the whole section corkscrews ±26 degrees, so "down"
##    walks onto what was the left wall and then onto the right. The racing line
##    crosses the full width of the course twice without anyone steering.
## 6. **Three lanes, and their difference is length.** The split sits inside the
##    course's one real corner, so the inside lane is genuinely shorter — the
##    thing `SlopeCourse`'s own notes say a straight course structurally cannot
##    offer. The canyon's lanes trade width for obstacles; these trade distance
##    for the angle you arrive at the truss with.
## 7. **The jump has a ceiling.** The roof drops to `ROOF_LOW` over the kicker,
##    so a marble that arrives too fast clips it and drops into the gap. Every
##    other jump in this project fails one way, by being too slow; this one fails
##    at both ends, which is why the boost pad below it can be generous.
## 8. **Falling is a place, not an event.** The truss is the only unwalled stretch
##    on the course — nine metres of narrow floor with open sides. Everywhere
##    else is sealed, so "off the course" has one address, and the field arrives
##    at it knowing.
## 9. **The truss surface is the deadest on the course.** Bounce 0.05 exactly
##    where there is nothing to bounce off. `DECISIONS.md` asks for low overall
##    fall risk, and this is how a course gets both an open edge and a field that
##    survives it.
## 10. **The field is bunched by friction, not by width.** The canyon closes to
##     3.4m before the line; this opens out and lays down grip plating instead. A
##     marble that is genuinely clear is not slowed by a narrowing it never
##     touches, but every marble is slowed by ground it has to cross.
##
## Obstacles remain the rotating bumper (`DECISIONS.md`), three of them: a
## counter-rotating pair in quick succession, and one on the run-in. The boost
## pad is the same deliberate exception `JungleCourse` documents, for the same
## reason — it is what makes a gap sizeable at all.

# --- Shape --------------------------------------------------------------------

const LENGTH := 175.0
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

## Alternating plunges and near-flat runs. The weighted mean is ~9.4 degrees,
## just under the canyon's 9.8, over a course 20m shorter — the difference is
## meant to come back as bounce, which costs a marble speed every time it lands.
##
## Nothing is shallower than 5.5 degrees, the same floor both other courses hold
## to: on anything flatter a marble that arrives stopped has nothing to restart
## it, and a race that hangs is worth more than any amount of pacing.
const PITCH := [
	[0.08, 12.0], ## Out of the dock.
	[0.22, 8.0],  ## The pinball hall.
	[0.34, 16.0], ## First plunge.
	[0.50, 9.0],  ## The corkscrew. Held shallow so the roll is what is felt, but
	              ## not as shallow as it wants to be: a leaning duct needs more
	              ## along-course gravity than a level one to keep a marble that
	              ## has slid into the low corner moving through it.
	[0.60, 15.0], ## Second plunge, into the split at speed.
	[0.72, 8.0],  ## Lanes and truss: the two places speed is a liability.
	[0.84, 13.0], ## The charge at the gap.
	[1.00, 7.5],  ## Grip run-in.
]

## One real corner, and it is where the split is. Kept under the ~30 degrees the
## chase camera can hold, per `JungleCourse`'s note.
const HEADING := [
	[0.10, 0.0],
	[0.26, 16.0],  ## A drift through the bumper pair, so the pair is not square-on.
	[0.38, 0.0],
	[0.56, 0.0],   ## Straight through the corkscrew: the roll is the only roll.
	[0.68, -22.0], ## The corner the split sits in. Left is the inside lane.
	[0.80, -6.0],
	[0.90, 8.0],
	[1.00, 0.0],
]

## Authored roll, in degrees, positive rolling the track's right side down — the
## same sign `CoursePath.bank_at` uses, because it is added to it.
##
## This is the one thing here that needed a change outside the course. Bank in
## `CoursePath` is derived from the heading and deliberately so: a camber that
## disagrees with its corner is worse than none. But a duct in free fall has no
## reason to keep its floor down, and a rolled *straight* is not something a
## derived bank can ever produce. So roll is authored and bank stays derived, and
## the two add.
##
## ±18 rather than a full barrel, and the ceiling is not aesthetic. A rolled
## rectangle leans its low wall *over* the marbles sitting against it, and a
## marble in an overhanging corner has two contact points and no way out — the
## first build ran this at ±26 with a small fillet and left three marbles parked
## in the corkscrew every race. `_chamfer_at` opens the corner where the roll is;
## this keeps the lean itself inside what that can absorb.
const ROLL := [
	[0.36, 0.0],
	[0.44, 18.0],  ## Over onto the left wall.
	[0.52, -18.0], ## And across to the right.
	[0.58, 0.0],
	[1.00, 0.0],
]
## The largest number in `ROLL`, ignoring sign. `_chamfer_at` measures how rolled
## the duct is against it.
const ROLL_PEAK := 18.0

## Half-width of the duct, as `[[fraction, metres], ...]`. Never below 4.4: two
## marbles abreast is 1.8m, and the canyon's notes record a field dying in a 2.0m
## funnel.
##
## **The truss does not narrow.** It was 3.6m half-width for one build, on the
## theory that an open section should also be a tight one, and it took ten of
## twelve marbles every race. A narrowing with no walls is not a funnel, it is a
## ramp off the side: the taper is the only thing pushing a marble sideways and
## there is nothing out there to push it back. Open edges have to be paid for by
## being *wide*, so leaving the course means arriving already travelling across
## it rather than simply being squeezed.
const WIDTH := [
	[0.10, 4.4], ## The dock. Narrowest start of the three courses, on purpose.
	[0.32, 5.8], ## The hall, and it has to stay wide until the second bumper is
	             ## past: the sweep is 2.6m and the assertion in `_build_bumpers`
	             ## is what caught the narrowing arriving too early.
	[0.42, 4.6],
	[0.52, 5.2], ## The corkscrew needs width to climb.
	[0.70, 5.4], ## The split.
	[0.78, 5.0], ## The truss, and it barely narrows at all — see below.
	[0.88, 5.0], ## Jump approach.
	[1.00, 4.8], ## The run-in stays open — see difference 10.
]
## Widest the duct ever gets. What the camera lens is sized against; the width
## anywhere in particular comes from `WIDTH`.
const HALF_WIDTH := 5.8

## Wall above the chamfer, and the chamfer itself.
##
## The section is a rectangle with its bottom corners rounded off. A true right
## angle between floor and wall gives a marble two contact points at once and
## with any friction that locks it rotationally — the canyon builder's own notes
## call this out, and it is worse here because a rolled duct pushes the field
## into that corner by design.
##
## The fillet is a **circular quarter**, tangent to the floor at one end and to
## the wall at the other, so there is no crease at either join. The first build
## used the canyon's quadratic instead and it meets a vertical wall at about 63
## degrees — a 27 degree crease, and marbles sat in it on a 5.5 degree grade with
## nothing wrong anywhere else on the course.
##
## `CHAMFER_ROLLED` is what the radius opens to through the corkscrew. Where the
## duct leans, the low corner is an overhang, and the only thing that keeps an
## overhang from being a pocket is making it a wide enough curve that a marble
## rests on one point of it and rolls on.
const WALL_HEIGHT := 3.4
const CHAMFER := 0.7
const CHAMFER_ROLLED := 1.8

## Roof clearance above the floor, and what it drops to over the jump.
const ROOF_HEIGHT := 4.2
const ROOF_LOW := 3.0

## Resolution of the generated section, along and across.
##
## Same reasoning as `JungleCourse.MESH_STEP`: a rolled or banked course changes
## the frame's orientation as well as its position, so boxes laid along it leave
## steps at every join. A generated surface has a vertex row at every station and
## is continuous by construction.
const MESH_STEP := 1.0
const FLOOR_STEPS := 12
const CHAMFER_STEPS := 5
const WALL_STEPS := 3

## How far a mesh run reaches into its neighbour, so two runs interpenetrate
## rather than sharing an edge a marble can pass through.
const RUN_OVERLAP := 0.35

## Where the duct is roofed and walled, as `[from, to]` fractions. The truss is
## simply absent from both.
const ROOF_SPANS := [[-0.10, 0.72], [0.83, 1.06]]
const WALL_SPANS := [[-0.10, 0.73], [0.82, 1.06]]

# --- Surfaces -----------------------------------------------------------------

## Plating, by restitution. Friction barely moves — every one of these is
## polished metal — so what a band changes is how a marble *leaves* the floor,
## not how it holds it.
##
## `MarbleTuning.bounce` is 0.3 and the solver combines the two, so these read
## against that rather than in absolute terms: `DAMPER` is a marble that stops
## bouncing, `SPRING` is one that stops touching down.
const SURFACE_PLATE := {"friction": 0.24, "bounce": 0.24, "colour": Color(0.34, 0.36, 0.41)}
const SURFACE_DAMPER := {"friction": 0.36, "bounce": 0.05, "colour": Color(0.20, 0.21, 0.25)}
const SURFACE_SPRING := {"friction": 0.16, "bounce": 0.58, "colour": Color(0.27, 0.42, 0.47)}
## The only high-friction ground on the course, and it is the last 8%.
const SURFACE_GRIP := {"friction": 0.52, "bounce": 0.08, "colour": Color(0.42, 0.34, 0.29)}

const SURFACES := [
	[0.16, SURFACE_PLATE],
	[0.30, SURFACE_SPRING], ## The pinball hall, under the roof.
	[0.42, SURFACE_PLATE],
	[0.58, SURFACE_SPRING], ## Bouncing while the duct rolls under you.
	[0.72, SURFACE_PLATE],  ## The lanes: something to actually push off.
	[0.83, SURFACE_DAMPER], ## The truss. Dead plating where there are no walls.
	[0.92, SURFACE_PLATE],
	[1.00, SURFACE_GRIP],   ## The run-in.
]

# --- Features -----------------------------------------------------------------

## Two bumpers in quick succession turning opposite ways, offset to opposite
## sides. One bumper deflects; a counter-rotating pair sorts — whichever way the
## first throws you, the second is turning into you rather than away.
##
## Placed as `[fraction, lateral, revolutions]`. Sweep radius is `ARM_LENGTH`,
## and at these offsets against a 5.8m half-width each arm clears the wall by
## ~0.8m, the same margin `SlopeCourse` runs.
const BUMPERS := [
	[0.24, -2.4, 0.61],
	[0.28, 2.4, -0.61],
	[0.92, 0.0, 0.61], ## On the grip plating, so the run-in is not a procession.
]

## Three lanes through the corner. The dividers are what make it three; the
## corner is what makes them unequal.
const SPLIT_AT := 0.58
const SPLIT_LENGTH := 21.0
const DIVIDER_OFFSET := 1.9
const DIVIDER_THICKNESS := 0.9
const DIVIDER_HEIGHT := 1.6

## The truss: no walls, no roof, narrow, dead plating.
const TRUSS := Vector2(0.73, 0.82)

## The jump. A boost onto a lifted floor, a hole, and a low roof over both.
const KICKER_AT := 0.85
const KICKER_LENGTH := 6.0
## Low, and the number is not a taste: a parabolic ramp on a descending course
## is level where its own slope matches the pitch, and level is a basin. At 1.2m
## over 6m that point sat 3.5m up the ramp and two marbles a race settled in it
## and never moved again — a marble at rest in a basin has nothing to restart it,
## which is the same failure the phase spec's "short uphill" was rejected for.
##
## Held under `KICKER_LENGTH * tan(pitch) / 2` the ramp is descending everywhere,
## so nothing can stop on it. What it still does is *flatten* the descent, which
## is all a kicker has to do: a marble following a 13 degree drop and then
## meeting ground that falls away at nothing leaves the surface at the lip.
const KICKER_RISE := 0.65
const JUMP_GAP := 2.4
const BOOST_SPEED := 13.0

## Every gap a marble can be pushed into must clear this. A marble is 0.9m
## across; both other courses learned this the expensive way.
const MIN_GAP := 1.5

const HULL_COLOUR := Color(0.26, 0.27, 0.31)
const RIB_COLOUR := Color(0.44, 0.46, 0.52)
const DIVIDER_COLOUR := Color(0.38, 0.40, 0.46)
const GLASS_COLOUR := Color(0.62, 0.78, 0.86, 0.10)
const FINISH_COLOUR := Color(0.92, 0.91, 0.86)
## The dark below the truss and the gap, so an opening reads as a drop into
## nothing rather than as missing level.
const VOID_COLOUR := Color(0.06, 0.06, 0.09)
const VOID_DROP := 26.0

const BOUNCE_FIXTURE := 0.2

var _path: CoursePath


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING, ROLL)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_floor()
	_build_walls()
	_build_roof()
	_build_ribs()
	_build_void()
	_build_back_wall()

	_build_split()
	_build_bumpers()
	_build_boost()
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


## A `[from, to]` fraction span in metres, clipped to the course's own extent.
func _clamped_span(from_fraction: float, to_fraction: float) -> Vector2:
	return Vector2(
		maxf(from_fraction * LENGTH, -RAMP_LENGTH),
		minf(to_fraction * LENGTH, LENGTH + RUNOFF_LENGTH)
	)


# --- Section ------------------------------------------------------------------


## How much the floor is lifted by the kicker at `s`.
##
## Squared on the way up rather than smoothstepped: smoothstep flattens at both
## ends, and a ramp that is parallel to the slope at its lip is not a ramp. A
## parabola is flat where it meets the floor, which is the end that has to be
## smooth, and steepest at the lip, which is the end that has to throw. The same
## shape `JungleCourse` arrived at, for the same reason.
func _kicker_lift(s: float) -> float:
	var from_s := KICKER_AT * LENGTH
	var lip := from_s + KICKER_LENGTH
	var landing := lip + JUMP_GAP

	if s <= from_s:
		return 0.0
	if s < lip:
		var t := (s - from_s) / KICKER_LENGTH
		return KICKER_RISE * t * t
	if s < landing:
		return KICKER_RISE
	# The landing is the duct's own floor, a full `KICKER_RISE` below the lip.
	#
	# Easing it back up to the lip's height and down again over the following
	# metres is the obvious version and it is what makes a jump impossible: a
	# marble leaving a 1.2m ramp at 13 m/s and 9 degrees carries about a metre
	# before it is back at the height it left, and the gap is nearly three. The
	# whole field went in. Landing *below* the lip is what buys the range —
	# every jump is a fall, and how far you get is how long you have to fall.
	return 0.0


## Roof clearance at `s`, above the floor.
##
## The dip over the jump is difference 7: it turns arrival speed from a threshold
## into a window. Eased rather than stepped, because a step in the roof is a
## ledge, and a marble that meets a ledge in flight stops dead in mid-air.
func _roof_height_at(s: float) -> float:
	var from_s := KICKER_AT * LENGTH - 3.0
	var to_s := KICKER_AT * LENGTH + KICKER_LENGTH + JUMP_GAP + 5.0
	if s <= from_s or s >= to_s:
		return ROOF_HEIGHT

	var inside := minf(
		smoothstep(0.0, 4.0, s - from_s), smoothstep(0.0, 4.0, to_s - s)
	)
	return lerpf(ROOF_HEIGHT, ROOF_LOW, inside)


## The floor, as `(lateral, lift)` pairs in the local frame, running left to
## right. Node count is fixed — every row of the mesh has to have the same number
## of nodes to be stitched to its neighbour, so what varies along the course
## varies in position, never in count.
##
## Runs from the top of the left chamfer to the top of the right one. The walls
## are separate meshes that overlap it, so the two can be present or absent
## independently — which is what the truss needs.
func _floor_section(s: float) -> Array:
	var half_width := _half_width_at(s)
	var radius := _chamfer_at(s)
	var lift := _kicker_lift(s)
	var flat := half_width - radius
	var points := []

	# Left fillet, from the wall down to the floor: a quarter circle centred at
	# (flat, radius), so it leaves the wall vertically and meets the floor flat.
	for i in CHAMFER_STEPS + 1:
		var angle := PI * 0.5 * float(i) / float(CHAMFER_STEPS)
		points.append(
			Vector2(-flat - radius * cos(angle), lift + radius * (1.0 - sin(angle)))
		)
	for i in range(1, FLOOR_STEPS + 1):
		var t := float(i) / float(FLOOR_STEPS)
		points.append(Vector2(lerpf(-flat, flat, t), lift))
	for i in range(CHAMFER_STEPS - 1, -1, -1):
		var angle := PI * 0.5 * float(i) / float(CHAMFER_STEPS)
		points.append(
			Vector2(flat + radius * cos(angle), lift + radius * (1.0 - sin(angle)))
		)

	return points


## Fillet radius at `s`: the corner opens where the duct leans. Read off the roll
## profile itself rather than given its own table, so the two can never disagree
## about where the corkscrew is.
func _chamfer_at(s: float) -> float:
	var rolled := absf(_path.sample(ROLL, s, CoursePath.BANK_BLEND)) / ROLL_PEAK
	return lerpf(CHAMFER, CHAMFER_ROLLED, clampf(rolled, 0.0, 1.0))


## One wall, bottom to top. Its base sits at the floor's own level rather than at
## the top of the chamfer, so it interpenetrates the floor mesh instead of
## sharing an edge with it — two trimeshes meeting exactly have no thickness
## between them, and a marble arriving at the join goes through it.
func _wall_section(s: float, side: float) -> Array:
	var half_width := _half_width_at(s)
	var lift := _kicker_lift(s)
	var top := _chamfer_at(s) + WALL_HEIGHT
	var points := []
	for i in WALL_STEPS + 1:
		var t := float(i) / float(WALL_STEPS)
		points.append(Vector2(side * half_width, lift + top * t))
	return points


## The roof, running right to left — reversed relative to the floor, which is
## what puts its normals on the underside where the marbles are.
func _roof_section(s: float) -> Array:
	var half_width := _half_width_at(s)
	var height := _kicker_lift(s) + _roof_height_at(s)
	var points := []
	for i in FLOOR_STEPS + 1:
		var t := float(i) / float(FLOOR_STEPS)
		points.append(Vector2(lerpf(half_width, -half_width, t), height))
	return points


# --- Mesh ---------------------------------------------------------------------


## One continuous stretch of duct: an ArrayMesh for the look and a matching
## trimesh collider for the physics, generated from the same vertex rows so they
## cannot disagree.
func _build_mesh_run(
	from_s: float,
	to_s: float,
	section: Callable,
	friction: float,
	bounce: float,
	colour: Color,
	two_sided := false
) -> void:
	if to_s - from_s < 0.2:
		return

	var rows := []
	var s := from_s
	while s < to_s - 0.01:
		rows.append(_section_row(s, section))
		s = minf(s + MESH_STEP, to_s)
	rows.append(_section_row(to_s, section))

	var across: int = (rows[0] as Array).size()
	var faces := PackedVector3Array()
	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(across - 1):
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
	body.name = "Run_%.0f_%.0f_%s" % [from_s, to_s, "wall" if two_sided else "surf"]
	body.physics_material_override = _physics_material(friction, bounce)

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	# Front faces only for the floor and the roof: a marble thrown out of the
	# course has to keep falling until the threshold collects it, not come to
	# rest on the underside of the floor still officially racing — `JungleCourse`
	# shipped that bug once. The walls are the exception: they are thin vertical
	# strips with nothing to rest on, so two-sided collision costs nothing there
	# and removes any question about which way a rolled duct's winding faces.
	shape.backface_collision = two_sided
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _material(colour, two_sided)
	# A glass roof that casts a shadow puts the whole duct in shade, which is the
	# one thing a transparent lid was chosen to avoid.
	if colour.a < 1.0:
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)

	add_child(body)


func _section_row(s: float, section: Callable) -> Array:
	var frame := _frame_at(s)
	var row := []
	for node: Vector2 in section.call(s):
		row.append(frame * Vector3(node.x, node.y, 0.0))
	return row


# --- Duct ---------------------------------------------------------------------


## The floor, cut at every surface change and at the jump's gap. Within a run the
## mesh is continuous: no joins, no seams, and nothing for a marble to catch on
## however hard the duct is rolling.
func _build_floor() -> void:
	var lip := KICKER_AT * LENGTH + KICKER_LENGTH
	var hole := Vector2(lip, lip + JUMP_GAP)

	var cuts := [-RAMP_LENGTH, LENGTH + RUNOFF_LENGTH, hole.x, hole.y]
	for entry: Array in SURFACES:
		cuts.append(entry[0] * LENGTH)
	cuts.sort()

	for i in range(cuts.size() - 1):
		var from_s: float = cuts[i]
		var to_s: float = cuts[i + 1]
		if to_s - from_s < 0.2:
			continue
		var middle := (from_s + to_s) * 0.5
		if middle > hole.x and middle < hole.y:
			continue

		# Runs reach into their neighbours, but never into the gap: extending a
		# run into the hole would close the hole.
		if not is_equal_approx(from_s, hole.y):
			from_s -= RUN_OVERLAP
		if not is_equal_approx(to_s, hole.x):
			to_s += RUN_OVERLAP

		var surface := _surface_at(middle)
		_build_mesh_run(
			from_s, to_s, _floor_section,
			surface["friction"], surface["bounce"], surface["colour"]
		)


func _build_walls() -> void:
	for span: Array in WALL_SPANS:
		var range_s := _clamped_span(span[0], span[1])
		for side: float in [-1.0, 1.0]:
			_build_mesh_run(
				range_s.x, range_s.y,
				func(s: float) -> Array: return _wall_section(s, side),
				SURFACE_PLATE["friction"], SURFACE_PLATE["bounce"], HULL_COLOUR,
				true
			)


## Glass, and it has to be.
##
## A solid roof is correct physics and an unusable picture: the overhead camera
## sits some thirty metres above the centreline and would spend the whole race
## looking at the outside of a lid, and the locked chase framing is not much
## better. A transparent, unshaded, shadowless slab collides exactly as a solid
## one does and is the only version of this course anybody can watch. It is also
## the cheapest possible reading of "orbital duct" — the marbles are visibly
## inside something.
func _build_roof() -> void:
	for span: Array in ROOF_SPANS:
		var range_s := _clamped_span(span[0], span[1])
		_build_mesh_run(
			range_s.x, range_s.y, _roof_section, 0.12, BOUNCE_FIXTURE, GLASS_COLOUR
		)


## Structural ribs outside the walls. Visual only, and they earn their keep: an
## even grey tube has no sense of motion in it, exactly as the canyon had none
## before it had strata. A rib every six metres is something to pass.
func _build_ribs() -> void:
	var s := -RAMP_LENGTH
	var index := 0
	while s < LENGTH + RUNOFF_LENGTH:
		var half_width := _half_width_at(s)
		for side: float in [-1.0, 1.0]:
			var visual := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(1.1, WALL_HEIGHT + CHAMFER + 0.6, 0.8)
			visual.mesh = mesh
			visual.material_override = _material(
				RIB_COLOUR.darkened(fmod(float(index) * 0.23, 0.2))
			)
			visual.transform = _frame_at(s).translated_local(
				Vector3(side * (half_width + 0.6), (WALL_HEIGHT + CHAMFER) * 0.5, 0.0)
			)
			add_child(visual)
		s += 6.0
		index += 1


## Dark slabs a long way below the two places the course is open, so a hole reads
## as a drop into nothing rather than as missing level. Visual only — anything
## that gets this far is already eliminated by `fall_threshold_y`.
func _build_void() -> void:
	for span: Array in [[TRUSS.x, TRUSS.y], [0.84, 0.94]]:
		var range_s := _clamped_span(span[0], span[1])
		var mesh := BoxMesh.new()
		mesh.size = Vector3(42.0, 1.0, range_s.y - range_s.x + 12.0)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(VOID_COLOUR)
		visual.transform = _frame_at((range_s.x + range_s.y) * 0.5).translated_local(
			Vector3(0.0, -VOID_DROP, 0.0)
		)
		add_child(visual)


## Closes the top of the dock so a marble cannot roll out backwards.
func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(Vector3(0.0, 1.2, 0.4)),
		Vector3(_half_width_at(-RAMP_LENGTH) * 2.0, 2.4, 0.8),
		HULL_COLOUR.darkened(0.35)
	)


# --- Features -----------------------------------------------------------------


## Two dividers, three lanes, inside the corner.
##
## Which lane a marble takes is decided by physics alone — it arrives where the
## field left it and goes the side it was already going (`DECISIONS.md`). What
## the lanes trade is distance: the course is turning left through here, so the
## left lane is the short way round and the right lane is the long one. The right
## is also the one that lines up with the truss entry, so the long way is the
## tidy way in and the short way arrives at the open section crossing it.
##
## Both ends of each divider are capped with a cylinder. A flat face presented to
## an oncoming field is the worst object a course can have: a marble that meets
## it square stops dead and blocks the lane for everything behind it.
func _build_split() -> void:
	var from_s := SPLIT_AT * LENGTH
	var to_s := from_s + SPLIT_LENGTH
	var half_width := _half_width_at((from_s + to_s) * 0.5)
	var radius := DIVIDER_THICKNESS * 0.5

	_assert_gap(half_width - DIVIDER_OFFSET - radius, "outer split lane")
	_assert_gap((DIVIDER_OFFSET - radius) * 2.0, "centre split lane")

	for side: float in [-1.0, 1.0]:
		var lateral := side * DIVIDER_OFFSET
		# Built in short chunks: a rolling, banked frame differs in orientation
		# from one end of a long box to the other, and no single box has both as
		# faces. At this chunk length the difference is under the marble radius.
		var chunk := 3.5
		var at := from_s
		while at < to_s - 0.01:
			var next := minf(at + chunk, to_s)
			_add_box(
				_frame_at((at + next) * 0.5).translated_local(
					Vector3(lateral, DIVIDER_HEIGHT * 0.5, 0.0)
				),
				Vector3(DIVIDER_THICKNESS, DIVIDER_HEIGHT, next - at + 0.1),
				DIVIDER_COLOUR
			)
			at = next

		for end_s: float in [from_s, to_s]:
			_add_divider_cap(end_s, lateral, radius)


func _add_divider_cap(s: float, lateral: float, radius: float) -> void:
	var body := StaticBody3D.new()
	body.transform = _frame_at(s).translated_local(
		Vector3(lateral, DIVIDER_HEIGHT * 0.5, 0.0)
	)
	body.physics_material_override = _physics_material(
		SURFACE_PLATE["friction"], BOUNCE_FIXTURE
	)

	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = DIVIDER_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = DIVIDER_HEIGHT
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(DIVIDER_COLOUR.lightened(0.1))
	body.add_child(visual)

	add_child(body)


func _build_bumpers() -> void:
	for entry: Array in BUMPERS:
		var s: float = entry[0] * LENGTH
		var lateral: float = entry[1]
		# The arm may not reach into the wall. Not `MIN_GAP`, because the gap a
		# bumper leaves is a moving one and a marble in it is never held: what
		# has to be true is that the sweep stays inside the duct, or the arm
		# spends part of every turn inside solid geometry.
		assert(
			_half_width_at(s) - absf(lateral) >= RotatingBumper.ARM_LENGTH,
			"bumper at %.2f sweeps into the wall." % entry[0]
		)

		var bumper := RotatingBumper.create()
		bumper.revolutions_per_second = entry[2]
		bumper.transform = _frame_at(s).translated_local(Vector3(lateral, 0.0, 0.0))
		add_child(bumper)


## The boost, on the approach rather than on the ramp: added on the ramp it would
## be changing the speed of something already committed to a trajectory.
##
## Generous, because unlike every other jump here this one has a roof over it —
## a marble that arrives too fast clips `ROOF_LOW` and drops in. The floor under
## arrival speed can therefore be set for the slowest marble without turning the
## quickest into one that sails past the landing entirely.
func _build_boost() -> void:
	var at := KICKER_AT * LENGTH - 3.5
	var frame := _frame_at(at)
	var pad := BoostPad.create(_half_width_at(at) * 2.0, -frame.basis.z, BOOST_SPEED)
	pad.transform = frame.translated_local(Vector3(0.0, 1.2, 0.0))
	add_child(pad)


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
		HULL_COLOUR.darkened(0.35)
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
	body.physics_material_override = _physics_material(
		SURFACE_PLATE["friction"], BOUNCE_FIXTURE
	)

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


func _physics_material(friction: float, bounce: float) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = friction
	material.bounce = bounce
	return material


## Metal, not plastic: rough, the default sheen killed outright, and the marbles
## left as the only saturated, shiny things in frame — the same rule the canyon
## palette settled on. Everything here sits under 0.2 saturation.
func _material(colour: Color, double_sided := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	material.metallic = 0.1
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if colour.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if double_sided:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


# --- Course interface ---------------------------------------------------------


func fall_threshold_y() -> float:
	return _point(LENGTH).y - 20.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func finish_runoff() -> float:
	return RUNOFF_LENGTH


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


## Square across the duct rather than staggered: the roof is what makes this jump
## interesting, so the floor does not also need to be. Measured against the
## curve, whose offsets start at the top of the ramp rather than at the start
## line — hence the `RAMP_LENGTH`.
func jump_clearance(position: Vector3) -> float:
	if curve == null:
		return INF

	var lip := KICKER_AT * LENGTH + KICKER_LENGTH
	var s := curve.get_closest_offset(position) - RAMP_LENGTH
	if s < lip - 3.0 or s > lip + JUMP_GAP + 6.0:
		return INF

	return s - (lip + JUMP_GAP)


## Four across rather than the canyon's six. The dock is the narrowest opening of
## the three courses, which makes the grid three rows deep — the field is in
## contact with itself before the barrier drops, and the opening plunge is
## already a scramble rather than twelve marbles setting off in parallel.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 4
	var spacing := 1.8

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.5 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(
			Transform3D(Basis.IDENTITY, _frame_at(-back) * Vector3(x, 0.9, 0.0))
		)

	return spawns
