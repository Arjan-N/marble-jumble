class_name JungleRiverCourse
extends Course

## Jungle River — course 9, and the prototype for how course 10 onwards get
## built.
##
## The brief this exists to answer is not "another jungle map". It is the
## observation that every course in the pool reads as *a floating track with
## scenery around it*, and that the two ways the project has tried to fix that
## both cost more than they are worth: a swept trough (`CourseBuilder`,
## `JungleCourse`) is expensive to author and still has an outside edge, and a
## flat plane with a kerb (`TempleRunCourse`, `GlacierFaultCourse`) is cheap and
## reads as a board.
##
## The answer here is neither. There is no track. There is a valley floor —
## `TerrainShell` — and the racing surface is the flat bottom of it. The mud
## verge, the dirt banks and the jungle floor the trees stand on are the *same
## continuous mesh* as the bed the marbles roll along, welded vertex to vertex,
## so there is no edge anywhere for the eye to read as "this stops here". The
## containment is the bank, not a wall; the boundary is terrain, not fixture.
##
## Everything that follows from that is cheap:
##
## - Elevation, width, banking and jumps are all profiles, not geometry. A jump
##   is `bed_drop` dipping for three metres; a narrow section is `WIDTH` getting
##   smaller. Nothing has to be modelled.
## - The jungle is nine meshes (`JungleKit`) instanced through `MultiMesh`, so
##   four hundred trees and eight hundred ferns are about nine draw calls.
## - The distant treeline is not geometry at all — it is the far end of the
##   ground profile rising into frame, which the ground mesh was going to draw
##   anyway.
##
## If Factory, Ice and Volcano are built on `TerrainShell` with their own kit and
## their own profiles, they get the same grounding for the same price. That is
## the thing this course is really testing.
##
## ## Route
##
## ```text
##  wide riverbed   rock    narrow    fallen    sweeping    stream
##    opening       split   passage    tree    banked turn  crossing
##       |            |        |         |          |          |
##  0.00 ------ 0.22 --- 0.36 --- 0.455 --- 0.50-0.68 ---- 0.745 ---- 0.82 -- 1.00
##                                                                      |       |
##                                                                  clearing  winding
##                                                                          + finish
## ```
##
## ## Two deliberate departures, both flagged rather than assumed
##
## **Length.** `DECISIONS.md` locks 20-30 seconds per course; the brief for this
## one asks for 60-90. The brief is the more recent and more specific
## instruction, so the course is built to it — 380m rather than the pool's
## 130-190 — but it is a product decision that outlives this file and the two
## documents now disagree. `DECISIONS.md` needs an entry either way.
##
## **The stream does not eliminate.** `CourseBuilder`'s river drowns a marble
## that lands in it. This one is ankle-deep with a ramped far wall, so a marble
## that comes up short wades out having lost most of its speed. The brief asks
## for a *shallow* stream and a *modest* jump, and the two together only mean
## anything if falling in is a cost rather than a death — a 2.6m gap that kills
## is a coin flip on entry speed, which is not racing. `in_water` therefore
## stays `false` here; the water is visual.

# --- Shape --------------------------------------------------------------------

const LENGTH := 380.0
const RAMP_LENGTH := 14.0
const RUNOFF_LENGTH := 32.0

## Where the features sit, as fractions of `LENGTH`. Named because they are
## referenced from the profiles, from the fixtures and from the scenery, and
## three copies of 0.455 in three tables is how a feature and its dressing drift
## apart.
const SPLIT_AT := 0.22
const NARROW_FROM := 0.31
const NARROW_TO := 0.42
const TREE_AT := 0.455
const BEND_TO := 0.68
const STREAM_AT := 0.745
const CLEARING_TO := 0.86

## Gentle throughout — this is a riverbed, not a flume — with the descent eased
## further through the banked turn and the winding run-in, for the reason every
## turning course in this project has had to learn twice: speed into a corner is
## what throws a marble at the outside, not what carries it round.
##
## Floor of 7 degrees, raised from 6.5 after a probe run finished 12 of 12 but
## strung the field from 66 to 117 seconds. Nothing may be shallow enough to hold
## a marble that arrives slowly, and on a course this long the cost of getting
## that wrong is paid by the tail rather than by the leaders: a marble that loses
## its speed on a 6.5-degree stretch never gets it back, and the round waits.
## A single stall at 380m is a very long round.
const PITCH := [
	[0.06, 9.0],   ## Off the line into the riverbed.
	[0.14, 7.0],   ## The wide opening, deliberately unhurried.
	[0.24, 8.0],   ## Rolling down at the boulder.
	[0.31, 8.5],
	[0.42, 7.5],   ## Narrow passage — slow, so the walls are a nuisance not a wreck.
	[0.48, 9.5],   ## Run at the fallen tree.
	[0.52, 8.0],
	[BEND_TO, 7.5],  ## Banked turn, held back.
	[0.73, 11.0],  ## Released at the stream.
	[0.79, 8.0],
	[0.87, 7.5],   ## The clearing.
	[0.97, 7.0],   ## Winding.
	[1.00, 11.0],  ## Sprint to the line.
]

## Absolute bearing in degrees, positive turning right.
##
## A drift left through the narrow passage, one long sweeping right-hander, and
## an S on the run-in. Every step is 15m of course or more, which keeps the turn
## rate under 0.6 degrees per metre — the figure every course here that races
## cleanly stays below, and the figure above which `CoursePath`'s smoothing
## window stops being wide enough to turn a step into a ramp.
const HEADING := [
	[0.24, 0.0],
	[0.30, -4.0],
	[0.36, -9.0],   ## Into the narrow passage.
	[0.44, -9.0],
	[0.48, -5.0],
	[0.52, 2.0],
	[0.56, 10.0],
	[0.60, 18.0],
	[0.64, 25.0],
	[BEND_TO, 29.0],  ## The sweeper, at its tightest.
	[0.76, 29.0],   ## Straight through the stream crossing.
	[0.80, 24.0],
	[0.84, 16.0],
	[0.88, 8.0],
	[0.91, 1.0],
	[0.94, -5.0],   ## Last flick the other way.
	[0.97, -1.0],
	[1.00, 0.0],
]

## Authored camber, added to whatever `CoursePath` derives from the turn rate.
##
## The brief asks for a banked turn "strong enough to create interesting racing
## lines", and derived bank alone cannot deliver one: `BANK_GAIN` is 6 degrees of
## camber per degree-per-metre of turn, so a corner turning at the 0.6 the
## geometry allows comes out at 3.6 degrees, which is a cross-fall, not a bank.
## Sixteen on top of it puts the sweeper near 20 — enough that a marble carrying
## speed rides up the outside and comes back down ahead of one that took the
## inside, which is the whole point of building a corner.
##
## Eased in and out over 20m either side. A step in roll is a twist marbles hit
## rather than ride.
##
## The ease-out is deliberately finished before the stream crossing. It was not,
## and a probe stalled a marble on the take-off lip at fraction 0.661: the lip
## rises about as fast as the course descends, so its net grade is nearly level,
## and a nearly level stretch with twelve degrees of camber on it is somewhere a
## slow marble settles against the low side and stays. A jump wants to be entered
## flat.
const ROLL := [
	[0.52, 0.0],
	[0.56, 6.0],
	[0.60, 13.0],
	[0.64, 16.0],
	[BEND_TO, 16.0],
	[0.71, 10.0],
	[0.74, 2.0],   ## Level again before the jump — see below.
	[0.78, 0.0],
	[1.00, 0.0],
]

## Half-width of the flat racing bed.
##
## Never below 3.5. Two marbles abreast is 1.8m; the Canyon's notes record its
## field dying in a 2.0m squeeze, and a narrow section the field cannot
## physically resolve is a jam rather than a funnel.
##
## Every entry is about fifteen per cent narrower than the first pass, and the
## reason is the lens rather than the racing. `Mode.LOW` sees roughly seven
## metres of width at the focus; at a 7.4m half-width the bed alone overflowed
## the frame and the first render was a screen of bare ground with no jungle in
## it at all. Width on this course is bounded above by the camera before it is
## bounded by anything else, and that is a fact any course built on
## `TerrainShell` will have to respect.
const WIDTH := [
	[0.09, 5.8],       ## Wide riverbed opening — twelve marbles, room to spread.
	[0.16, 5.0],
	[0.26, 6.2],       ## Rock split: wide enough that both lines round the
	                   ## boulder are real racing lines rather than one gap.
	[NARROW_FROM, 4.4],
	[0.36, 3.8],       ## Narrow jungle passage — 3.5 before the pinch rocks were
	                   ## found to wedge a small field here.
	[NARROW_TO, 3.7],
	[0.48, 4.4],       ## Fallen tree.
	[0.56, 5.0],
	[BEND_TO, 4.9],    ## The sweeper.
	[0.74, 4.4],       ## Stream approach — tight, so nobody misses the lip.
	[0.80, 6.4],       ## The clearing.
	[0.92, 4.3],       ## Winding.
	[1.00, 5.4],       ## Finish.
]

## Height of the dirt bank crest above the bed, before the per-corner boost in
## `_bank_height`. This is the containment: there are no walls on this course and
## nothing on it is a fixture whose job is to keep a marble in.
##
## 2.2 is nearly two and a half marble diameters, which a marble climbing a
## 33-degree slope does not clear at the speeds this course reaches. It drops in
## the clearing on purpose — an open section that is open on camera as well as in
## plan is worth a small risk of losing somebody there.
const BANK := [
	[0.09, 2.4],
	[0.20, 2.0],
	[0.30, 2.6],
	[NARROW_TO, 3.4],  ## Deep in the jungle, cut right down into the hillside.
	[0.52, 2.6],
	[BEND_TO, 2.8],    ## Outside of the sweeper is boosted further below.
	[0.78, 2.2],
	[CLEARING_TO, 1.7],  ## The clearing genuinely opens up.
	[0.95, 2.6],
	[1.00, 2.1],
]

## Degrees of derived camber per extra metre of bank on the outside of a corner.
## Automatic rather than authored for the same reason `CoursePath` derives bank
## at all: a wall that disagrees with the corner it is in is worse than no wall.
const CORNER_BANK_GAIN := 0.09
const CORNER_BANK_LIMIT := 1.8

const MESH_STEP := 1.5

# --- Surfaces -----------------------------------------------------------------

## Damp riverbed grit. Slower than the pool's stone courses — this is mud and
## gravel, and the 380m length means the friction budget has to buy time as well
## as feel — but never slow enough to hold a marble that arrives at walking pace.
const FRICTION := 0.33
const BOUNCE := 0.08

# --- Stream crossing ----------------------------------------------------------

## Absolute distance along the course, so the lip, the water, the collision
## geometry and `jump_clearance` all measure from one number.
const STREAM_S := STREAM_AT * LENGTH

## The take-off. A lip rising over 3m to 0.7m above the bed is about 13 degrees,
## which against a course descending at 11 leaves the marble launching a couple
## of degrees above horizontal — enough hang to cross, nothing like a stunt ramp.
const LIP_RUN := 3.0
const LIP_RISE := 0.7
## The near wall of the streambed: short, so it is a drop rather than a slope a
## marble can crawl down.
const STREAM_WALL := 0.3
## How far the streambed sits below the racing bed, and the number that decides
## whether the crossing is a feature or a trap.
##
## The first pass cut 1.05m deep and climbed out over 2m. `tools/probe_course.gd`
## put three of twelve marbles in the water and none of them ever came out: at
## that depth the exit ramp rises faster than the course descends across it, so
## the streambed is a **basin**, and a marble that stops in a basin is stopped for
## the rest of the race. It is not visible in the section — the ramp looks like a
## way out, and for a marble still carrying speed it is — which is why it survived
## being written down and had to be found by running a field down it.
##
## The rule these numbers now satisfy: the climb out must be smaller than the
## course's own descent across the same span, so that even the exit ramp is
## downhill in world terms. At 11 degrees of pitch 4.5m of course drops 0.87m,
## and the ramp lifts 0.75. Anything that lands in the water rolls out of it.
const STREAM_DEPTH := 0.75
## The flat, wet span. This is the gap: 2.6m at 6 m/s is 0.43 seconds of air.
const STREAM_BED := 2.6
## The far bank, ramped rather than walled, and long enough to obey the rule
## above. A marble that came up short climbs out having paid for it.
const STREAM_EXIT := 4.5
## How far below the bed the water surface sits. Ankle-deep by construction.
const WATER_DEPTH := 0.44

# --- Fixtures -----------------------------------------------------------------

## The boulder that splits the field, and the two smaller ones that keep the two
## lines apart long enough for the split to mean something.
const SPLIT_ROCK_SIZE := Vector3(2.9, 2.4, 4.0)
const SPLIT_TRAIL := [
	[0.245, -3.4, 1.5],
	[0.262, 3.1, 1.4],
]

## Rocks and root balls protruding from the verge through the narrow passage.
## `[fraction, side, protrusion]` — how far each reaches in over the mud lip.
##
## Reach was cut by about a third after a full tournament run through
## `race_manager` wedged three marbles here at exactly zero velocity and hung the
## round until its 95-second cap. `tools/probe_course.gd` had never shown it: at
## its fixed seed the field arrives bunched and shoves itself through, and it is
## a round-three field of three marbles — nobody behind to push — that actually
## gets stuck.
##
## The trap is the pocket between a convex boulder and the sloped verge behind
## it. Reaching less makes the pocket shallower; `PINCH_YAW` is what removes it,
## by turning each rock so its up-course face is a deflector rather than the back
## wall of a V.
const PINCH_ROCKS := [
	[0.325, 1.0, 0.78],
	[0.345, -1.0, 0.70],
	[0.368, 1.0, 0.64],
	[0.392, -1.0, 0.82],
	[0.412, 1.0, 0.68],
]
## Degrees each pinch rock is turned about its own vertical, leading edge towards
## the centreline. A rock square to the course presents its flank to an arriving
## marble; a rock at an angle presents a face that slides it back into the bed.
const PINCH_YAW := 28.0

## The fallen tree. Half-buried rather than resting on the surface, so what a
## marble meets is a rolling shoulder it can ride over and not a wall it stops
## against.
## Radius and burial depth, tuned together so the log stands 0.42m proud — just
## under a marble diameter, the height at which the field pops over it rather
## than piling into it — while still showing enough of its own curvature to read
## as a log.
##
## The first pass got the physics right and the picture wrong: a 0.78m radius
## buried to -0.36 leaves only the top quarter of the cylinder above ground, and
## a quarter of a cylinder is a flat band. The rendered frame showed a plank
## lying across the riverbed. Two thirds of a smaller cylinder shows a curve, and
## the jump height is identical.
const LOG_RADIUS := 0.70
const LOG_CENTRE := -0.28
## Degrees of tilt about the course direction. The whole point: one end sits
## lower, so there is an easy line and a launching line and the field has to
## choose. Without it twelve marbles take the same jump the same way.
const LOG_TILT := 5.0

# --- Scenery ------------------------------------------------------------------

const SCENERY_SEED := 20260828
## Metres between scenery stations. Everything is placed on this grid and
## jittered, so a restart rebuilds the same jungle.
const SCENERY_STEP := 6.0
## How far past each end of the course the jungle carries on. At the start line
## the low camera is already up-course of the ramp looking at whatever is there,
## and the run-out is the flattest ground on the map and therefore the one place
## the lens can reach the horizon.
const SCENERY_BEFORE := 60.0
const SCENERY_AFTER := 95.0

# --- Environment --------------------------------------------------------------

const SKY_TOP := Color(0.29, 0.50, 0.60)
const SKY_HORIZON := Color(0.63, 0.72, 0.60)
## Barely tinted and modest in energy. A saturated green ambient turns every
## brown face lime and flattens the banks into the jungle behind them; the tint
## has to be small enough that shadowed dirt still reads as dirt, and the energy
## high enough that a marble in a bank's shadow is still findable.
const AMBIENT_COLOUR := Color(0.82, 0.87, 0.79)
const AMBIENT_ENERGY := 0.52
const SUN_COLOUR := Color(1.0, 0.97, 0.86)
const FOG_COLOUR := Color(0.44, 0.55, 0.50)
## Tuned against the ground profile: at 0.006 the treeline 110m out is about half
## dissolved, which pushes it back without turning the middle distance — where
## the trees the player actually reads are — into one flat green wall.
const FOG_DENSITY := 0.006

var _path: CoursePath
var _shell: TerrainShell


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING, ROLL)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_shell()
	_build_back_wall()
	_build_split_rocks()
	_build_pinch_rocks()
	_build_fallen_tree()
	_build_stream()
	_build_runoff_backstop()
	_build_jungle()


# --- Path ---------------------------------------------------------------------


func _point(s: float) -> Vector3:
	return _path.point_at(s)


func _frame_at(s: float) -> Transform3D:
	return _path.frame_at(s)


func frame_at(offset: float) -> Transform3D:
	if curve == null:
		return Transform3D.IDENTITY

	var length := curve.get_baked_length()
	var clamped := clampf(offset, 0.0, length)
	var frame := _frame_at(_path.s_at_curve_offset(clamped, length))
	return Transform3D(frame.basis, curve.sample_baked(clamped))


func _half_width_at(s: float) -> float:
	return _path.sample(WIDTH, s)


## Bank crest height, with the outside of a corner given extra.
##
## `CoursePath.bank_at` is positive in a right-hand turn, which is also the
## direction a marble is thrown — so the outside of any corner is the side whose
## sign disagrees with the bank's. One expression covers every corner on the
## course, including the ones authored roll makes sharper than the geometry
## implies.
func _bank_height(s: float, side: float) -> float:
	var base := _path.sample(BANK, s)
	var camber := rad_to_deg(_path.bank_at(s))
	var boost := clampf(-side * camber * CORNER_BANK_GAIN, 0.0, CORNER_BANK_LIMIT)
	return base + boost


## An unrolled frame: the position and heading of the course with the camber
## taken out and Y left pointing at the sky, defined past both ends of the path.
##
## Scenery cannot use `_frame_at`. That frame banks with the corners, which is
## right for anything sitting on the racing surface and wrong for everything
## else — hung off it the jungle floor tilts twenty degrees through the sweeper
## and the trees lean with it.
func _ground_frame(s: float) -> Transform3D:
	var last := LENGTH + RUNOFF_LENGTH
	var clamped := clampf(s, -RAMP_LENGTH, last)
	var frame := _frame_at(clamped)

	var forward := -frame.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.is_zero_approx():
		forward = Vector3.FORWARD

	var origin := frame.origin + forward * (s - clamped)
	var backward := -forward
	var right := Vector3.UP.cross(backward).normalized()
	return Transform3D(Basis(right, Vector3.UP, backward), origin)


# --- Bed profile --------------------------------------------------------------


## How far the bed drops below the path frame at `s`.
##
## Zero for all but ten metres of a four-hundred-metre course. The whole stream
## crossing — the take-off lip, the drop, the wet span and the ramp out — is this
## one function, and `TerrainShell` turns it into geometry that is continuous
## with the rest of the trench by construction. There is no separate jump mesh,
## no gap in the collider and no seam to tune.
func _bed_drop(s: float) -> float:
	var mound := _log_mound(s)
	var stream := _stream_drop(s)
	# The mound is a lift and the stream is a drop; they are hundreds of metres
	# apart, so summing them is only a convenience for keeping one profile.
	return stream - mound


## The low bank of silt the fallen tree lies on.
##
## Without it the log is a 0.42m face rising out of a flat bed, and a marble that
## arrives at the back of the field with almost no speed left simply parks
## against it — which the probe did, at fraction 0.438, through four separate
## attempts at reshaping the log itself. Removing the log removed the stall, so
## the log was the cause; but the log is a spec'd feature and the height that
## traps a slow marble is also the height that launches a fast one.
##
## Raising the ground the log sits in resolves both. The step a marble has to
## climb becomes 0.20 rather than 0.42, which a marble at walking pace can manage,
## while a marble arriving at speed still leaves the top of the log at exactly the
## height it did before — the mound is under both of them. It is also what a
## fallen trunk in a riverbed actually looks like, silted up on the upstream side.
const LOG_MOUND := 0.22
const LOG_MOUND_RUN := 4.5


func _log_mound(s: float) -> float:
	var distance := absf(s - TREE_AT * LENGTH)
	if distance >= LOG_MOUND_RUN:
		return 0.0
	return LOG_MOUND * smoothstep(1.0, 0.0, distance / LOG_MOUND_RUN)


func _stream_drop(s: float) -> float:
	var lip_start := STREAM_S - LIP_RUN
	var wall_end := STREAM_S + STREAM_WALL
	var bed_end := wall_end + STREAM_BED
	var exit_end := bed_end + STREAM_EXIT

	if s <= lip_start or s >= exit_end:
		return 0.0
	if s < STREAM_S:
		return -LIP_RISE * smoothstep(0.0, 1.0, inverse_lerp(lip_start, STREAM_S, s))
	if s < wall_end:
		return lerpf(-LIP_RISE, STREAM_DEPTH, inverse_lerp(STREAM_S, wall_end, s))
	if s < bed_end:
		return STREAM_DEPTH
	return lerpf(
		STREAM_DEPTH, 0.0, smoothstep(0.0, 1.0, inverse_lerp(bed_end, exit_end, s))
	)


## Standing height of the mud lip, and how far either side of the fallen tree it
## is flattened away.
const VERGE_LIFT := 0.42
const LOG_VERGE_CLEAR := 4.0


## The mud lip, flattened where the fallen tree crosses the bed.
##
## The log's up-course flank and the raised lip meet in a corner at the verge,
## and a corner beside a racing surface is a marble trap: a probe run parked a
## marble there at fraction 0.438 and it never moved again. Shortening the log
## did not help, because the log is only half of the corner — moving its end
## moved the corner with it, and the field probe came back byte-identical.
##
## Taking the lip out for four metres either side removes the other half. The bed
## runs flat into the bank across the whole width of the obstacle, so a marble
## pushed sideways by the log has an unobstructed slope to roll back down.
func _verge_lift_at(s: float) -> float:
	var distance := absf(s - TREE_AT * LENGTH)
	if distance >= LOG_VERGE_CLEAR:
		return VERGE_LIFT
	return VERGE_LIFT * smoothstep(0.0, 1.0, distance / LOG_VERGE_CLEAR)


## Distances the shell must sample exactly. Every corner of `_bed_drop`, plus a
## row either side of the two hard edges so the take-off face and the streambed
## floor meet at something the marble reads as a lip.
func _key_stations() -> Array[float]:
	var wall_end := STREAM_S + STREAM_WALL
	var bed_end := wall_end + STREAM_BED
	return [
		TREE_AT * LENGTH - LOG_MOUND_RUN,
		TREE_AT * LENGTH + LOG_MOUND_RUN,
		TREE_AT * LENGTH - LOG_VERGE_CLEAR,
		TREE_AT * LENGTH,
		TREE_AT * LENGTH + LOG_VERGE_CLEAR,
		STREAM_S - LIP_RUN,
		STREAM_S - LIP_RUN * 0.5,
		STREAM_S - 0.05,
		STREAM_S,
		wall_end,
		wall_end + STREAM_BED * 0.5,
		bed_end,
		bed_end + STREAM_EXIT * 0.5,
		bed_end + STREAM_EXIT,
	]


# --- Terrain ------------------------------------------------------------------


func _build_shell() -> void:
	_shell = TerrainShell.create(_path, -RAMP_LENGTH, LENGTH + RUNOFF_LENGTH)
	_shell.step = MESH_STEP
	_shell.key_stations = _key_stations()
	_shell.half_width = _half_width_at
	_shell.bank_height = _bank_height
	_shell.bed_drop = _bed_drop
	_shell.ground_frame = _ground_frame
	_shell.friction = FRICTION
	_shell.bounce = BOUNCE
	_shell.verge_width = 0.85
	_shell.verge_lift = _verge_lift_at
	_shell.bank_run = 2.8
	# The green band covers the top seventy per cent of the bank rather than the
	# default fifty-five. Under this lens the bank faces *are* the flanks of the
	# frame, so where that seam sits decides how much of the shot is dirt: at the
	# default the banked turn — which has the tallest banks on the course and
	# therefore the most bank in frame — rendered as a brown corridor.
	_shell.crest_fraction = 0.30
	_shell.centre_fraction = 0.36

	# The jungle floor leaves the bank crest almost level, climbs a hillside
	# through the band the trees stand in, and then rises hard into the treeline.
	# That last entry is doing the most work on this course: under `Mode.LOW` the
	# top of the frame is about ten degrees below the horizon, so a ground plane
	# that stays flat draws a band of bare sky where the jungle should be. Sixteen
	# metres at 110 out is what puts a wall of green across the top of the shot.
	# Steepened hard after the first render. The first pass rose 1.6m in the first
	# sixteen metres, which is a flood plain, and through a 26-degree lens a flood
	# plain is a screen of flat brown: the trees standing on it were all outside
	# the frame and the course read as a strip of dirt with nothing around it.
	#
	# Four metres of rise in the first twelve is a valley side. It puts the
	# hillside itself into the shot, it lifts everything growing on that hillside
	# into the shot with it, and it is what makes the route read as *cut into*
	# something rather than laid across it. The far entry is the treeline.
	_shell.ground_profile = [
		[4.0, 1.2], [12.0, 4.0], [30.0, 8.0], [60.0, 13.0], [110.0, 22.0]
	]
	_shell.ground_columns = 8
	_shell.ground_relief = 4.0
	# The crest band is painted in the jungle floor's own colours, not the bank's.
	# It is the fold where the ground turns over the lip of the cut, and painting
	# it as dirt puts a hard brown-to-green line exactly where this class is
	# supposed to have no line at all.
	_shell.set_materials(
		_ground_material(
			JungleKit.UNDERGROWTH.lerp(JungleKit.DIRT, 0.3),
			JungleKit.CANOPY, 0.05, 0.5, 0.4
		),
		_ground_material(JungleKit.DIRT, JungleKit.DIRT_DARK, 0.09, 0.6, 0.3),
		_material(JungleKit.MUD.lightened(0.05)),
		_material(JungleKit.MUD),
		_ground_material(JungleKit.RIVERBED, JungleKit.MUD, 0.16, 1.1, 0.1)
	)
	_shell.ground_material = _ground_material(
		JungleKit.UNDERGROWTH, JungleKit.CANOPY.darkened(0.1), 0.026, 0.28, 0.45
	)
	_shell.build(self)


## The head of the riverbed. The full-width backstop every course here puts
## behind its start line — a marble knocked backwards off the ramp needs
## something to hit — dressed as a cut earth bank with roots out of it, because
## the camera spends the whole countdown looking straight at it.
func _build_back_wall() -> void:
	var half := _half_width_at(-RAMP_LENGTH)
	var frame := _frame_at(-RAMP_LENGTH)

	_add_box(
		frame.translated_local(Vector3(0.0, 1.3, 0.5)),
		Vector3(half * 2.0 + 2.0, 2.6, 1.0),
		JungleKit.DIRT_DARK
	)

	var roots := JungleKit.group(JungleKit.root(), "HeadwallRoots")
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED + 7
	for i in 7:
		var x := (float(i) / 6.0 - 0.5) * half * 1.9
		roots.add(
			frame.translated_local(Vector3(x, rng.randf_range(0.5, 2.2), 0.1))
				* Transform3D(
					Basis(Vector3.RIGHT, deg_to_rad(90.0)).rotated(
						Vector3.FORWARD, rng.randf_range(-1.0, 1.0)
					).scaled(Vector3.ONE * rng.randf_range(0.5, 1.1)),
					Vector3.ZERO
				),
			JungleKit.ROOT.darkened(rng.randf_range(0.0, 0.25))
		)
	JungleKit.emit(self, [roots])


## The kerb closing the run-out. Low, because the field the camera is watching
## arrive must not be hidden behind it, and present at all because `FinishZone`
## takes a finisher's speed with damping rather than with a wall — what is needed
## here is something to catch a slow roll, not something to stop a race.
func _build_runoff_backstop() -> void:
	var at := LENGTH + RUNOFF_LENGTH - 1.4
	_add_box(
		_frame_at(at).translated_local(Vector3(0.0, 0.4, 0.0)),
		Vector3(_half_width_at(at) * 2.0 + 2.0, 0.8, 0.7),
		JungleKit.DIRT_DARK
	)


# --- Rocks --------------------------------------------------------------------


## A colliding boulder, its collision hull the same six points its silhouette is
## built from.
##
## `ConvexPolygonShape3D` rather than a sphere or a box: a box stops a marble
## dead and a sphere is not a shape anything in a jungle is, whereas a squashed
## octahedron with its long axis down-course presents a prow that deflects. That
## matters most at the split, where a boulder that stopped marbles instead of
## turning them would be a wall with two doors rather than a fork.
func _add_rock(
	transform: Transform3D, size: Vector3, variant: int, colour: Color
) -> void:
	var body := StaticBody3D.new()
	body.transform = transform
	var surface := PhysicsMaterial.new()
	surface.friction = FRICTION
	surface.bounce = BOUNCE
	body.physics_material_override = surface

	var points := JungleKit.rock_points(variant)
	var scaled := PackedVector3Array()
	for point in points:
		scaled.append(point * size)

	var shape := ConvexPolygonShape3D.new()
	shape.points = scaled
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = JungleKit.rock(variant)
	visual.scale = size
	visual.material_override = _material(colour)
	body.add_child(visual)

	add_child(body)


## The rock split. One boulder in the middle of the widest part of the course,
## then two smaller ones offset to opposite sides so the two lines stay apart for
## a while instead of merging the moment they part.
##
## Sized against the bed rather than against nothing: at 0.26 the bed is 14.8m
## across and the boulder is 4m of it, leaving five and a half metres either
## side — three marbles abreast on each line, which is what makes both of them
## real. A boulder that left one gap wide enough for the field would be scenery.
func _build_split_rocks() -> void:
	var frame := _frame_at(SPLIT_AT * LENGTH)
	_add_rock(
		frame.translated_local(Vector3(0.0, SPLIT_ROCK_SIZE.y * 0.42, 0.0)),
		SPLIT_ROCK_SIZE,
		3,
		JungleKit.ROCK.darkened(0.08)
	)
	# Moss on the up-course shoulder only, where a river would leave it. Purely
	# visual and deliberately not part of the hull.
	# Hugging the crown rather than floating over it. A first pass sat a
	# half-scale cap a third of the boulder's height above its top, and from the
	# race camera — which passes within a few metres of this rock — it read as a
	# flat green plate hanging in the air.
	var moss := MeshInstance3D.new()
	moss.mesh = JungleKit.rock(3)
	var moss_scale := SPLIT_ROCK_SIZE * Vector3(0.80, 0.34, 0.76)
	moss.transform = frame.translated_local(
		Vector3(0.0, SPLIT_ROCK_SIZE.y * 0.50, -0.25)
	) * Transform3D(Basis.IDENTITY.scaled(moss_scale), Vector3.ZERO)
	moss.material_override = _material(JungleKit.MOSS)
	moss.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(moss)

	var variant := 5
	for entry: Array in SPLIT_TRAIL:
		var at: float = entry[0] * LENGTH
		var size := Vector3(1.7, 1.5, 2.3)
		_add_rock(
			_frame_at(at).translated_local(Vector3(entry[1], size.y * 0.36, 0.0)),
			size * float(entry[2]) / 1.45,
			variant,
			JungleKit.ROCK.lightened(0.06)
		)
		variant += 2


## The narrow passage: rocks and root balls shouldering in over the mud lip,
## alternating sides.
##
## Placed from the verge inward rather than from the centreline outward, so the
## racing line they leave is a zigzag through a passage rather than a slalom
## drawn on an open floor — and so a change to `WIDTH` moves them with it.
func _build_pinch_rocks() -> void:
	var variant := 11
	for entry: Array in PINCH_ROCKS:
		var at: float = entry[0] * LENGTH
		var side: float = entry[1]
		var reach: float = entry[2]
		var half := _half_width_at(at)
		var size := Vector3(1.5, 1.7, 2.0)
		_add_rock(
			_frame_at(at).translated_local(
				Vector3(side * (half + size.x * 0.55 - reach), size.y * 0.28, 0.0)
			).rotated_local(Vector3.UP, deg_to_rad(-side * PINCH_YAW)),
			size,
			variant,
			JungleKit.ROCK.darkened(0.05).lerp(JungleKit.MOSS, 0.22)
		)
		variant += 3


# --- Fallen tree --------------------------------------------------------------


## A big log lying across the route, half sunk into the riverbed.
##
## Buried rather than resting on top: a cylinder sitting on the surface presents
## a vertical face at floor level and a marble arriving at 6 m/s hits it instead
## of climbing it. At `LOG_CENTRE` the log stands 0.42m proud, and what a marble
## meets first is a shoulder curving away from it, which is a ramp.
##
## The tilt is the feature. Twelve marbles meeting one level log all leave it the
## same way; tilted, the low end is a roll-over and the high end is a launch, and
## the field arrives at the sweeper spread across two lines rather than one.
##
## Extended a couple of metres past the verge at each end so there is no notch
## between the log and the bank for a marble to wedge into — the classic stall on
## every course here that has ever had one.
func _build_fallen_tree() -> void:
	var at := TREE_AT * LENGTH
	var half := _half_width_at(at)
	# Ends flush with the top of the mud verge, not driven on into the bank.
	#
	# A first pass ran the log 2.4m past the bed on each side, which puts a
	# horizontal cylinder through ground that is rising at thirty degrees — and
	# the pocket between the two caught a marble at fraction 0.438 and held it for
	# the rest of the race. Stopping at the verge lip means the log's end and the
	# lip are at the same height and there is no pocket; the bank beyond is
	# unbroken, so there is no way round the end either.
	#
	# The two visual sections in `_dress_fallen_tree` start inboard of this and
	# overlap it, so the trunk still reads as continuous.
	var span := (half + _shell.verge_width) * 2.0
	var frame := _frame_at(at).translated_local(Vector3(0.0, LOG_CENTRE, 0.0))
	frame = frame.rotated_local(Vector3.BACK, deg_to_rad(LOG_TILT))

	var body := StaticBody3D.new()
	var surface := PhysicsMaterial.new()
	# Wet bark: slicker than the bed, so the log gives back a little of what it
	# takes rather than being a pure brake.
	surface.friction = 0.24
	surface.bounce = 0.12
	body.physics_material_override = surface
	# `CylinderShape3D`'s axis is +Y, so the body is turned to lay it across the
	# course; the mesh is one metre tall along the same axis and scales with it.
	body.transform = frame.rotated_local(Vector3.BACK, deg_to_rad(90.0))

	# A capsule, not a cylinder. A cylinder ends in a flat disc, and the corner
	# between that disc and the rising bank is a marble trap — the probe parked a
	# marble against it at fraction 0.438 through three separate attempts at
	# reshaping the log and flattening the verge beside it. A capsule ends in a
	# hemisphere, which has no corner to hold anything: a marble pressed against it
	# rolls off. `height` is the total including both caps.
	var shape := CapsuleShape3D.new()
	shape.radius = LOG_RADIUS
	shape.height = maxf(span, LOG_RADIUS * 2.0 + 0.1)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = JungleKit.log_mesh()
	visual.scale = Vector3(LOG_RADIUS, span, LOG_RADIUS)
	# Darker than the riverbed it sits in. A first pass painted the log a shade
	# lighter than the mud and it disappeared into it — at this distance the only
	# thing separating a half-buried log from the ground is its own value.
	visual.material_override = _material(JungleKit.TRUNK.darkened(0.08))
	body.add_child(visual)
	add_child(body)

	_dress_fallen_tree(at, half, span, frame, body)


## The root plate at one end and the broken crown at the other, both well outside
## the bed and neither colliding. They are what makes the log read as a tree that
## fell here rather than a beam somebody laid across the course — which is the
## brief's actual requirement, and is entirely a scenery problem.
func _dress_fallen_tree(
	at: float, half: float, span: float, frame: Transform3D, body: StaticBody3D
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED + 31

	# The ends of the same tree, rising out of both banks at full thickness.
	#
	# The crossing section has to be mostly buried — a cylinder a marble can ride
	# over is one whose shoulder is already below marble-centre height, which
	# leaves only the top quarter of it above the riverbed, and a quarter of a
	# cylinder is a flat band. The rendered frame showed a plank.
	#
	# So the log is not thickened; the *rest of it* is drawn instead. A tree that
	# fell across a soft riverbed has sunk into the middle and is still proud at
	# the edges, and that is a shape the eye reads as a trunk immediately. These
	# two sections are non-colliding and sit outboard of the verge, where nothing
	# a marble can reach ever gets to them.
	# Placed along the log's own axis rather than aimed at the bank. A first pass
	# built a rotation that carried world up onto the vector from the verge to the
	# bank, and rendered two dark spikes standing vertically on the crests — the
	# log already has a correctly oriented frame, and the ends of a straight tree
	# are on the same line as its middle, so there is nothing here to aim.
	# Orientation from the log body — its local +Y already runs along the trunk —
	# but *position* from the bank surface, so each section rests on the slope
	# instead of being swallowed by it. Placing them along the log's own axis put
	# them at bed height two metres out, which is a metre and a half under the
	# bank at that point: correct, invisible, and useless.
	for side: float in [-1.0, 1.0]:
		var section := MeshInstance3D.new()
		section.mesh = JungleKit.log_mesh()
		# `scaled_local`, not `scaled`. `Basis.scaled` multiplies the basis *rows*,
		# which is a scale in world axes applied after the rotation — so asking a
		# horizontal log for 4.6 on Y stretched it vertically and produced two
		# dark posts standing on the banks. `scaled_local` scales along the log's
		# own axes, which is what "four and a half metres of trunk" means.
		# Collinear with the buried middle in plan — `bank_point` at this `t` sits
		# on the same lateral line the log runs along — and tilted down towards it
		# about the log's own forward axis, so the three pieces read as one broken
		# tree rather than as a plank with two beams parked either side of it.
		var tilt := Basis(Vector3.RIGHT, deg_to_rad(-side * 17.0))
		section.transform = Transform3D(
			(body.transform.basis * tilt).scaled_local(Vector3(0.9, 3.2, 0.9)),
			_shell.bank_point(at, side, 0.52) + Vector3.UP * 0.55
		)
		section.material_override = _material(JungleKit.TRUNK.darkened(0.12))
		section.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(section)

	var plate := MeshInstance3D.new()
	plate.mesh = JungleKit.rock(17)
	plate.scale = Vector3(1.0, 3.4, 3.4)
	plate.transform = frame.translated_local(Vector3(-span * 0.5, 0.4, 0.0)) \
		* Transform3D(Basis.IDENTITY.scaled(plate.scale), Vector3.ZERO)
	plate.material_override = _material(JungleKit.ROOT.darkened(0.15))
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plate)

	var roots := JungleKit.group(JungleKit.root(), "FallenRoots")
	var crowns := JungleKit.group(JungleKit.crown(), "FallenCrown")
	var ferns := JungleKit.group(JungleKit.fern(), "FallenFerns")

	for i in 9:
		roots.add(
			frame.translated_local(Vector3(-span * 0.5 - 0.3, 0.4, 0.0))
				* Transform3D(
					Basis(Vector3.FORWARD, rng.randf_range(0.0, TAU)).scaled(
						Vector3.ONE * rng.randf_range(0.8, 2.0)
					),
					Vector3(rng.randf_range(-0.4, 0.4), 0.0, 0.0)
				),
			JungleKit.ROOT.darkened(rng.randf_range(0.0, 0.3))
		)

	# The broken crown, dumped past the far verge and collapsed rather than
	# spherical — a canopy that has been lying on the ground for years.
	for i in 4:
		var size := rng.randf_range(2.0, 3.6)
		crowns.add(
			Transform3D(
				Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
					Vector3(size, size * 0.42, size)
				),
				_shell.ground_point(
					at + rng.randf_range(-4.0, 5.0), 1.0, rng.randf_range(1.0, 6.0)
				) + Vector3.UP * size * 0.2
			),
			JungleKit.FOLIAGE.darkened(rng.randf_range(0.0, 0.25))
		)

	# Ferns growing along the trunk itself, which is the single cue that says the
	# tree has been down a long time.
	for i in 8:
		var x := rng.randf_range(-half * 0.9, half * 0.9)
		var size := rng.randf_range(0.5, 0.9)
		ferns.add(
			frame.translated_local(Vector3(x, LOG_RADIUS * 0.55, 0.0))
				* Transform3D(
					Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3(size, size, size)
					),
					Vector3.ZERO
				),
			JungleKit.FROND.darkened(rng.randf_range(0.0, 0.2))
		)

	JungleKit.emit(self, [roots, crowns, ferns])


# --- Stream -------------------------------------------------------------------


## The water, and the channel it runs in either side of the course.
##
## The streambed itself is already built — it is `_bed_drop` dipping, so the
## collision surface a marble lands on is the same trench mesh as the rest of the
## course. What is left is what the player sees: a water surface across the gap,
## and the same stream carrying on out into the jungle in both directions so it
## reads as a watercourse the route crosses rather than a puddle in a slot.
##
## No water shader. `water.gdshader` exists and is not expensive, but the brief
## is explicit about avoiding water shaders on this course, and at ankle depth
## under a canopy a flat translucent plane with a light edge is what the
## reference look actually is.
func _build_stream() -> void:
	var wall_end := STREAM_S + STREAM_WALL
	var bed_end := wall_end + STREAM_BED
	var centre := (wall_end + bed_end) * 0.5
	var frame := _frame_at(centre)
	var half := _half_width_at(centre)

	var water := StandardMaterial3D.new()
	water.albedo_color = JungleKit.WATER
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.25
	water.metallic = 0.0
	water.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	water.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Across the course, sunk to `WATER_DEPTH` below the streambed floor's own
	# level. Wide enough to reach into both banks so the waterline disappears
	# into the mud instead of ending in mid-air.
	var surface := PlaneMesh.new()
	# Reaching into both banks but stopping short of the crest: a first pass at
	# half+5 pushed the corners of the quad out over the top of the bank, where
	# they read as a flat rectangle of water lying on the hillside.
	surface.size = Vector2((half + 2.9) * 2.0, STREAM_BED + 1.4)
	var plane := MeshInstance3D.new()
	plane.mesh = surface
	plane.material_override = water
	plane.transform = frame.translated_local(
		Vector3(0.0, -STREAM_DEPTH + WATER_DEPTH, 0.0)
	)
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plane)

	# The stream continuing out through the jungle, as a short chain of quads
	# following the falling ground on each side. Non-colliding, and stopped well
	# before the fog does the rest.
	# One unit quad instanced eight times rather than eight `PlaneMesh` nodes:
	# the widening is carried in each instance's scale, so the whole side stream
	# is one draw call and one mesh.
	var unit := PlaneMesh.new()
	unit.size = Vector2(1.0, 1.0)
	var reaches := MultiMesh.new()
	reaches.transform_format = MultiMesh.TRANSFORM_3D
	reaches.mesh = unit
	var placements: Array[Transform3D] = []

	for side: float in [-1.0, 1.0]:
		var out := 5.0
		while out < 26.0:
			var here := _shell.ground_point(centre, side, out)
			var next := _shell.ground_point(centre, side, out + 5.0)
			var span := next - here
			# Sunk into the hillside rather than laid on it: the ground rises
			# going out, and a stream drawn on the surface of a slope reads as a
			# painted stripe.
			placements.append(Transform3D(
				Basis(Vector3.UP, atan2(span.x, span.z) + PI * 0.5).scaled_local(
					Vector3(5.4, 1.0, STREAM_BED + 1.0 + out * 0.16)
				),
				(here + next) * 0.5 - Vector3.UP * (0.5 + out * 0.06)
			))
			out += 5.0

	reaches.instance_count = placements.size()
	for i in placements.size():
		reaches.set_instance_transform(i, placements[i])

	var reach_node := MultiMeshInstance3D.new()
	reach_node.name = "StreamReaches"
	reach_node.multimesh = reaches
	reach_node.material_override = water
	reach_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(reach_node)

	_dress_stream_banks(centre, half)


## Wet stones in the streambed and reeds on both lips. The stones are visual —
## anything a marble can hit in a landing zone is a way to lose a marble to
## something it could not have seen.
func _dress_stream_banks(centre: float, half: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED + 53

	var stones := JungleKit.group(JungleKit.rock(23), "StreamStones")
	var reeds := JungleKit.group(JungleKit.fern(), "StreamReeds")

	for i in 14:
		var x := rng.randf_range(-half * 0.95, half * 0.95)
		var along := centre + rng.randf_range(-STREAM_BED * 0.4, STREAM_BED * 0.4)
		var size := rng.randf_range(0.18, 0.42)
		stones.add(
			_frame_at(along).translated_local(
				Vector3(x, -STREAM_DEPTH + size * 0.4, 0.0)
			) * Transform3D(
				Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
					Vector3(size, size * 0.6, size)
				),
				Vector3.ZERO
			),
			JungleKit.ROCK.lightened(rng.randf_range(0.0, 0.18))
		)

	for side: float in [-1.0, 1.0]:
		for i in 10:
			var size := rng.randf_range(0.7, 1.4)
			reeds.add(
				JungleKit.planted(
					_shell.ground_point(
						centre + rng.randf_range(-4.0, 4.0),
						side,
						rng.randf_range(0.2, 7.0)
					),
					Vector3(size, size * 1.5, size),
					rng
				),
				JungleKit.FROND.lightened(rng.randf_range(0.0, 0.22))
			)

	JungleKit.emit(self, [stones, reeds])


# --- Jungle -------------------------------------------------------------------


## Everything past the bank crest, in three distance bands, as about nine draw
## calls.
##
## One walk down the course filling nine `MultiMesh` buckets, rather than one
## walk per prop type. Placing a fern and the tree behind it from the same
## station and the same jitter stream is what makes them agree with each other
## instead of reading as two independent scatters that happen to overlap.
func _build_jungle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED

	var trunks := JungleKit.group(JungleKit.trunk(), "Trunks")
	var crowns := JungleKit.group(JungleKit.crown(), "Crowns")
	var far_crowns := JungleKit.group(JungleKit.blob(), "FarCanopy")
	var scrub := JungleKit.group(JungleKit.blob(), "Scrub")
	var ferns := JungleKit.group(JungleKit.fern(), "Ferns")
	var leaves := JungleKit.group(JungleKit.leaf(), "BroadLeaves")
	var roots := JungleKit.group(JungleKit.root(), "Roots")
	var stones := JungleKit.group(JungleKit.rock(41), "MossyStones")
	var vines := JungleKit.group(JungleKit.vine(), "Vines")

	var s := -RAMP_LENGTH - SCENERY_BEFORE
	var last := LENGTH + RUNOFF_LENGTH + SCENERY_AFTER
	var index := 0

	while s < last:
		for side: float in [-1.0, 1.0]:
			_near_band(s, side, rng, ferns, leaves, roots, stones)
			_mid_band(s, side, rng, trunks, crowns, scrub, vines)
			_far_band(s, side, rng, far_crowns)
		s += SCENERY_STEP
		index += 1

	JungleKit.emit(self, [
		trunks, crowns, far_crowns, scrub, ferns, leaves, roots, stones, vines
	])


## NEAR — the crest and the first nine metres. This is the band the low camera
## actually resolves, and the only one where a single instance is ever read as an
## object rather than as texture.
func _near_band(
	s: float, side: float, rng: RandomNumberGenerator,
	ferns: JungleKit.Group, leaves: JungleKit.Group,
	roots: JungleKit.Group, stones: JungleKit.Group
) -> void:
	# Ferns growing **on the bank face**, between the mud lip and the crest.
	#
	# This is the single highest-value placement on the course and it took a
	# render to see why. `Mode.LOW` is a 26-degree lens: at the focus it covers
	# about seven metres of width, so the two flanks of the frame are the bank
	# faces and nothing else. A first pass planted everything past the crest,
	# eleven metres off axis, and produced a screen of bare brown dirt with a
	# convincing jungle sitting entirely outside it.
	#
	# Kept above `t = 0.3` so nothing grows where a marble rides up the bank.
	for i in 3:
		var at := s + rng.randf_range(-SCENERY_STEP * 0.5, SCENERY_STEP * 0.5)
		var size := rng.randf_range(0.5, 1.1)
		ferns.add(
			JungleKit.planted(
				_shell.bank_point(at, side, rng.randf_range(0.3, 1.0)),
				Vector3(size, size * rng.randf_range(0.9, 1.4), size),
				rng
			),
			JungleKit.FROND.lerp(JungleKit.UNDERGROWTH, rng.randf()).lightened(
				rng.randf_range(0.0, 0.24)
			)
		)

	for i in 2:
		var out := rng.randf_range(JungleKit.NEAR_INNER, JungleKit.NEAR_OUTER)
		var at := s + rng.randf_range(-SCENERY_STEP * 0.5, SCENERY_STEP * 0.5)
		var size := rng.randf_range(0.9, 1.9)
		ferns.add(
			JungleKit.planted(
				_shell.ground_point(at, side, out),
				Vector3(size, size * rng.randf_range(0.9, 1.4), size),
				rng
			),
			JungleKit.FROND.lerp(JungleKit.UNDERGROWTH, rng.randf()).lightened(
				rng.randf_range(0.0, 0.24)
			)
		)

	# Broad leaves leaning out over the crest, which is the foreground the brief
	# asks for: something between the lens and the marbles at the very edge of
	# frame. Anchored on the upper bank so they actually reach into the shot.
	for i in 2:
		if rng.randf() > 0.6:
			continue
		var size := rng.randf_range(1.4, 2.6)
		leaves.add(
			JungleKit.leaning(
				_shell.bank_point(
					s + rng.randf_range(-2.0, 2.0), side, rng.randf_range(0.6, 1.0)
				) + Vector3.UP * rng.randf_range(0.2, 1.0),
				Vector3(size, size, size),
				0.6,
				rng
			),
			JungleKit.FROND.lightened(rng.randf_range(0.0, 0.3))
		)

	if rng.randf() < 0.32:
		var size := rng.randf_range(0.9, 2.1)
		roots.add(
			JungleKit.arched(
				_shell.ground_point(
					s + rng.randf_range(-2.5, 2.5), side, rng.randf_range(0.3, 4.0)
				),
				size,
				rng.randf_range(0.0, TAU),
				rng.randf_range(0.4, 0.62)
			),
			JungleKit.ROOT.darkened(rng.randf_range(0.0, 0.3))
		)

	if rng.randf() < 0.28:
		var size := rng.randf_range(0.5, 1.5)
		stones.add(
			JungleKit.planted(
				_shell.ground_point(
					s + rng.randf_range(-2.5, 2.5), side, rng.randf_range(0.4, 6.0)
				),
				Vector3(size, size * 0.7, size),
				rng
			),
			JungleKit.ROCK.lerp(JungleKit.MOSS, rng.randf_range(0.1, 0.6))
		)


## MID — the trees. Trunk plus two crowns each: one sphere on a stick is a
## lollipop, and the second crown offset below and to one side is the whole
## difference between a lollipop and a canopy.
func _mid_band(
	s: float, side: float, rng: RandomNumberGenerator,
	trunks: JungleKit.Group, crowns: JungleKit.Group,
	scrub: JungleKit.Group, vines: JungleKit.Group
) -> void:
	# Biased towards the near end of the band, so the trees crowd the course
	# rather than standing off it in a hedge — the "jungle beside and partly
	# behind the course" the brief asks for is a density gradient, not a wall.
	var out := lerpf(JungleKit.MID_INNER, JungleKit.MID_OUTER, pow(rng.randf(), 1.7))
	var at := s + rng.randf_range(-SCENERY_STEP * 0.5, SCENERY_STEP * 0.5)
	var root := _shell.ground_point(at, side, out)

	var height := lerpf(7.0, 17.0, pow(rng.randf(), 1.4))
	var radius := lerpf(0.30, 0.62, inverse_lerp(7.0, 17.0, height))
	# Yaw only. A leaning trunk needs its crown leant with it and its heel sunk,
	# and where the lean would show is where the fog is.
	var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))

	trunks.add(
		Transform3D(basis.scaled(Vector3(radius, height, radius)),
			root + Vector3.UP * height * 0.5),
		JungleKit.TRUNK.lightened(rng.randf_range(0.0, 0.22))
	)

	var spread := lerpf(2.6, 5.4, inverse_lerp(7.0, 17.0, height))
	var tone := JungleKit.CANOPY.lerp(JungleKit.FOLIAGE, rng.randf()).lightened(
		rng.randf_range(0.0, 0.18)
	)
	# The main crown sits below the top of the trunk rather than on it, so the
	# trunk shows through the foliage instead of stopping at it.
	crowns.add(
		Transform3D(basis.scaled(Vector3(spread, spread * 0.62, spread)),
			root + Vector3.UP * height * 0.87),
		tone
	)
	var lower := spread * rng.randf_range(0.5, 0.78)
	crowns.add(
		Transform3D(
			Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
				Vector3(lower, lower * 0.62, lower)
			),
			root
				+ Vector3.UP * (height * rng.randf_range(0.62, 0.76))
				+ basis.x * (spread * rng.randf_range(0.35, 0.65))
		),
		tone.darkened(rng.randf_range(0.08, 0.26))
	)

	if rng.randf() < 0.45:
		var bush := rng.randf_range(1.2, 3.0)
		scrub.add(
			JungleKit.planted(
				_shell.ground_point(
					s + rng.randf_range(-SCENERY_STEP, SCENERY_STEP),
					side,
					rng.randf_range(JungleKit.NEAR_OUTER, JungleKit.MID_OUTER * 0.6)
				),
				Vector3(bush * 1.5, bush * 0.5, bush * 1.5),
				rng
			),
			JungleKit.UNDERGROWTH.lightened(rng.randf_range(0.0, 0.26))
		)

	# A vine hanging off the near trees only. Cheap depth: something vertical in
	# the midground at a different scale from the trunks, so the eye reads the
	# gap between them.
	if out < 22.0 and rng.randf() < 0.3:
		var drop := rng.randf_range(2.5, 6.0)
		vines.add(
			Transform3D(
				Basis.IDENTITY.scaled(Vector3(1.0, drop, 1.0)),
				root
					+ Vector3.UP * (height * 0.8 - drop * 0.5)
					+ basis.x * spread * rng.randf_range(0.4, 0.9)
			),
			JungleKit.FOLIAGE.darkened(rng.randf_range(0.1, 0.4))
		)


## There is deliberately **no overhead canopy band** on this course.
##
## One was built and cut. The brief asks for jungle "partially behind/around the
## course", which reads as a canopy overhead, and it cannot be had from this
## camera: the rig sits about sixteen metres above the surface and twenty-five
## behind, so anything hanging over the route is either far enough up-course to
## be above the frame entirely, or near enough to fill it. The render was
## unambiguous — a crown at nine metres blacked out the top half of the shot and
## hid two of the six marbles behind it, which is precisely the "must not
## obstruct the marble race" line in the brief.
##
## `Landscape`'s header had already worked this out from the lens geometry
## ("canopies and ceilings are wasted unless they hang lower than that"), and
## lower than that is inside the shot. The depth the canopy was meant to buy is
## bought instead by the bank-face planting in `_near_band` and by the valley
## sides in `ground_profile`, both of which sit in the flanks of the frame where
## this camera has room for them.


## FAR — silhouettes only, and not many. The treeline itself is the ground mesh
## rising to seventeen metres at the outer edge of `ground_profile`; these are
## the lumps on top of it that stop it reading as a smooth green ramp. No trunks:
## at sixty metres through fog a trunk is two pixels of brown.
func _far_band(
	s: float, side: float, rng: RandomNumberGenerator, far_crowns: JungleKit.Group
) -> void:
	if rng.randf() > 0.5:
		return
	var out := rng.randf_range(JungleKit.FAR_INNER, JungleKit.FAR_OUTER)
	var size := rng.randf_range(5.0, 11.0)
	far_crowns.add(
		JungleKit.planted(
			_shell.ground_point(s + rng.randf_range(-6.0, 6.0), side, out)
				+ Vector3.UP * size * 0.35,
			Vector3(size, size * 0.7, size),
			rng
		),
		JungleKit.CANOPY.lightened(rng.randf_range(0.0, 0.16))
	)


# --- Finish -------------------------------------------------------------------

const FINISH_LIGHT := Color(0.88, 0.86, 0.74)
const FINISH_DARK := Color(0.17, 0.16, 0.14)
const FLAG_COLOURS := [
	Color(0.90, 0.35, 0.20), Color(0.95, 0.76, 0.24),
	Color(0.30, 0.62, 0.86), Color(0.86, 0.44, 0.62),
]


## The jungle finish: two carved log totems, vines slung between the posts and
## the trees, a checkered band painted across the riverbed, and a lashed timber
## lookout beyond the run-out.
##
## Deliberately no lintel across the posts. `TempleRunCourse` learned this the
## expensive way: the low camera looks down the course from behind and above, and
## a beam anywhere between two and seven metres up crosses the frame exactly
## where the marbles are at the one moment of the race the player most needs to
## see. The posts carry the idea and leave the middle of the frame empty.
##
## Everything here is visual. `Course.create_finish_visual`'s contract is that a
## fixture can never be added to a finish by accident and change a race outcome,
## so the run-out floor, its banks and its backstop are all built in `build` with
## the rest of the collision geometry.
func create_finish_visual() -> Node3D:
	var node := Node3D.new()
	node.name = "JungleFinish"

	var frame := _frame_at(LENGTH)
	var half := _half_width_at(LENGTH)

	_finish_markings(node, frame, half)
	_finish_posts(node, frame, half)
	_finish_lookout(node)
	return node


## The line itself: a checkered band of alternating light and dark slabs across
## the bed, sat a couple of centimetres proud rather than sunk so it never shows
## through the surface from underneath on a banked stretch.
func _finish_markings(node: Node3D, frame: Transform3D, half: float) -> void:
	var squares := 14
	var size := (half * 2.0) / float(squares)

	# One `MultiMesh` over one box, tinted per instance, rather than
	# twenty-eight `MeshInstance3D` with twenty-eight `BoxMesh` resources behind
	# them. Same picture; one draw call instead of twenty-eight, and one mesh
	# instead of twenty-eight.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size, 0.03, size)
	var checkers := JungleKit.group(mesh, "FinishCheckers")

	for row in 2:
		for i in squares:
			checkers.add(
				frame.translated_local(Vector3(
					-half + size * (float(i) + 0.5),
					0.03,
					size * (0.5 - float(row))
				)),
				FINISH_LIGHT if (i + row) % 2 == 0 else FINISH_DARK
			)

	JungleKit.emit(node, [checkers])


## Two totems outboard of the mud lip, so nothing narrows the bed at the point
## the field is most likely to arrive several abreast. Each is a log with a
## carved band, a moss cap, and pennants on a short crossarm above head height.
func _finish_posts(node: Node3D, frame: Transform3D, half: float) -> void:
	var logs := JungleKit.group(JungleKit.log_mesh(), "FinishPosts")
	var bands := JungleKit.group(JungleKit.log_mesh(), "FinishBands")
	var vines := JungleKit.group(JungleKit.vine(), "FinishVines")
	var leaves := JungleKit.group(JungleKit.leaf(), "FinishLeaves")
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(0.9, 0.55, 0.04)
	var flags := JungleKit.group(flag_mesh, "FinishFlags")

	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED + 97
	var post_x := half + 1.9

	for side: float in [-1.0, 1.0]:
		var base := frame.translated_local(Vector3(side * post_x, 0.0, 0.0))

		logs.add(
			base.translated_local(Vector3(0.0, 2.6, 0.0))
				* Transform3D(Basis.IDENTITY.scaled(Vector3(0.42, 5.2, 0.42)), Vector3.ZERO),
			JungleKit.TRUNK.lightened(0.1)
		)
		# Carved bands, in the finish's own light stone colour so the posts read
		# as marked rather than merely wooden.
		for i in 3:
			bands.add(
				base.translated_local(Vector3(0.0, 3.4 + float(i) * 0.55, 0.0))
					* Transform3D(
						Basis.IDENTITY.scaled(Vector3(0.52, 0.18, 0.52)), Vector3.ZERO
					),
				FINISH_LIGHT if i != 1 else FINISH_DARK
			)
		bands.add(
			base.translated_local(Vector3(0.0, 5.3, 0.0))
				* Transform3D(Basis.IDENTITY.scaled(Vector3(0.66, 0.4, 0.66)), Vector3.ZERO),
			JungleKit.MOSS
		)

		# Pennants on a short arm, angled outward and away from the racing line.
		for i in 3:
			flags.add(
				base.translated_local(
					Vector3(side * (0.7 + float(i) * 0.95), 4.6 - float(i) * 0.35, 0.0)
				).rotated_local(Vector3.UP, deg_to_rad(side * 18.0)),
				FLAG_COLOURS[i % FLAG_COLOURS.size()]
			)

		# Vines running off the post into the bank, and a couple of broad leaves
		# at its foot. The post has to look grown-into, not planted this morning.
		for i in 5:
			var drop := rng.randf_range(1.2, 3.0)
			vines.add(
				base.translated_local(Vector3(
					side * rng.randf_range(0.3, 1.4),
					rng.randf_range(2.4, 4.4) - drop * 0.5,
					rng.randf_range(-0.5, 0.5)
				)) * Transform3D(
					Basis.IDENTITY.scaled(Vector3(1.0, drop, 1.0)), Vector3.ZERO
				),
				JungleKit.FOLIAGE.darkened(rng.randf_range(0.0, 0.3))
			)
		for i in 3:
			var size := rng.randf_range(1.1, 1.9)
			leaves.add(
				JungleKit.leaning(
					base.origin + base.basis.x * side * rng.randf_range(0.4, 1.6)
						+ Vector3.UP * 0.2,
					Vector3(size, size, size),
					0.4,
					rng
				),
				JungleKit.FROND.lightened(rng.randf_range(0.0, 0.25))
			)

	JungleKit.emit(node, [logs, bands, vines, leaves, flags])


## A lashed timber lookout on stilts, well past the run-out and off to one side.
##
## Beyond the field's reach, sunk below deck level and set off-centre for the
## same reason `TempleRunCourse` puts its temple eighteen metres back: it is the
## thing the last straight is aimed at, and it stops being that the moment it
## stands between the camera and the line.
func _finish_lookout(node: Node3D) -> void:
	var at := LENGTH + RUNOFF_LENGTH
	var base := _ground_frame(at).translated_local(Vector3(0.0, 0.0, -16.0))
	var floor_y := _shell.ground_point(at, 1.0, 12.0).y + 3.6

	var posts := JungleKit.group(JungleKit.log_mesh(), "LookoutPosts")
	var thatch := JungleKit.group(JungleKit.crown(), "LookoutThatch")

	var deck_origin := Vector3(base.origin.x + 9.0, floor_y, base.origin.z)

	for corner: Vector2 in [
		Vector2(-2.4, -2.4), Vector2(2.4, -2.4), Vector2(-2.4, 2.4), Vector2(2.4, 2.4)
	]:
		var foot := deck_origin + Vector3(corner.x, 0.0, corner.y)
		var height := floor_y - (_shell.ground_point(at, 1.0, 12.0).y - 1.0)
		posts.add(
			Transform3D(
				Basis.IDENTITY.scaled(Vector3(0.28, height, 0.28)),
				foot - Vector3.UP * height * 0.5
			),
			JungleKit.TRUNK
		)

	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(6.0, 0.35, 6.0)
	deck.mesh = deck_mesh
	deck.material_override = _material(JungleKit.TRUNK.lightened(0.18))
	deck.position = deck_origin
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(deck)

	# Four corner uprights and a thatched cap, which is the whole silhouette.
	for corner: Vector2 in [
		Vector2(-2.4, -2.4), Vector2(2.4, -2.4), Vector2(-2.4, 2.4), Vector2(2.4, 2.4)
	]:
		posts.add(
			Transform3D(
				Basis.IDENTITY.scaled(Vector3(0.22, 2.6, 0.22)),
				deck_origin + Vector3(corner.x, 1.5, corner.y)
			),
			JungleKit.TRUNK
		)
	thatch.add(
		Transform3D(
			Basis.IDENTITY.scaled(Vector3(4.6, 2.2, 4.6)),
			deck_origin + Vector3(0.0, 3.2, 0.0)
		),
		JungleKit.FROND.darkened(0.2)
	)

	JungleKit.emit(node, [posts, thatch])


# --- Helpers ------------------------------------------------------------------


func _add_box(transform: Transform3D, size: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new()
	body.transform = transform
	var surface := PhysicsMaterial.new()
	surface.friction = FRICTION
	surface.bounce = BOUNCE
	body.physics_material_override = surface

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


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


## Ground and bed panels get the project's world-space detail shader rather than
## flat albedo. It is the one place a texture would otherwise be needed, and the
## brief's texture budget is 512px — this costs none at all, and 380m of flat
## brown is 380m of nothing telling the eye how fast anything is moving.
func _ground_material(
	albedo: Color, alt: Color, macro_scale: float, detail_scale: float, slope: float
) -> ShaderMaterial:
	return Landscape.detail_material(albedo, alt, macro_scale, detail_scale, slope)


# --- Course interface ---------------------------------------------------------


## Green light under a bright, humid sky. The geometry here is all albedo, and
## albedo alone cannot make a shadowed bank look like it is under a canopy — the
## tinted ambient and the fog are what do that, and the fog is doing double duty
## as the far half of the LOD scheme.
func decorate_environment(environment: Environment, sun: DirectionalLight3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_bottom_color = JungleKit.CANOPY
	sky_material.ground_horizon_color = SKY_HORIZON

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOUR
	environment.ambient_light_energy = AMBIENT_ENERGY

	environment.fog_enabled = true
	environment.fog_light_color = FOG_COLOUR
	environment.fog_density = FOG_DENSITY
	# Even haze rather than a sun-facing glow: this is humidity between the
	# trees, which has no direction to it.
	environment.fog_sun_scatter = 0.0

	sun.light_color = SUN_COLOUR


## Well below the run-out, which is the lowest point on the course. A marble over
## a bank falls through the non-colliding jungle floor — `Landscape`'s founding
## rule — and keeps going until it reaches this.
func fall_threshold_y() -> float:
	return _point(LENGTH + RUNOFF_LENGTH).y - 14.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func finish_runoff() -> float:
	return RUNOFF_LENGTH


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


## The stream is ankle-deep and its far wall is a ramp, so a marble that comes up
## short wades out rather than drowning. See the class docs: a 2.6m gap that
## eliminates is a coin flip on entry speed, not racing.
func in_water(_position: Vector3) -> bool:
	return false


## Signed distance to the far edge of the water: negative while short of it,
## positive once past. The race watches the sign flip to call out a marble that
## only just got across.
func jump_clearance(position: Vector3) -> float:
	if curve == null:
		return INF

	var offset := curve.get_closest_offset(position)
	var s := _path.s_at_curve_offset(offset, curve.get_baked_length())
	var far_edge := STREAM_S + STREAM_WALL + STREAM_BED
	if absf(s - far_edge) > 24.0:
		return INF
	return s - far_edge


## Six abreast on the widest opening in the pool, which is what a "wide riverbed
## start" is for: the field spreads before the first feature instead of queuing
## through it.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 6
	var spacing := 1.8

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.6 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(
			Transform3D(Basis.IDENTITY, _frame_at(-back) * Vector3(x, 0.9, 0.0))
		)

	return spawns
