class_name SlopeCourse
extends Course

## A canyon run, straight in plan, with a shaped vertical profile: pillars, two
## funnels, a split/merge, a staggered jump with a bridge beside it, two rotating
## bumpers, a finish line.
##
## Themed per PROJECT.md section 6's Canyon direction and the phase spec's
## surface notes — a solid trough between rock walls, alternating rough stone and
## smoother constructed track, with the difference in friction as well as colour.
## Of the Canyon mechanics the spec lists (ramps, narrow bridges, falling rocks,
## split paths, jumps) everything but falling rocks is here; those are an
## obstacle, and `DECISIONS.md` fixes the rotating bumper as the only Phase 0
## obstacle, so they need a decision rather than a commit.
##
## Straight in plan, deliberately. `PROJECT.md` §2.4 says the physical
## interaction a course creates matters more than its theme, and everything on
## the §2.3 list — collisions, overtakes, pile-ups, near misses, falls, close
## finishes — can be built without ever turning. Staying straight also keeps this
## a clean camera test while `docs/CAMERA_SPIKE.md` is open, because it removes
## yaw from the question entirely.
##
## It is not the Canyon (`course_builder.gd`) and is not trying to be. The Canyon
## has curvature, banking and a swept ribbon, and it stalls its field at the
## split/merge; when something goes wrong there the cause is ambiguous. Here the
## plan is a straight line and the width is known everywhere, so anything that
## goes wrong is the profile, the obstacles or the marbles.
##
## Layout, as fractions of the run:
##
##   0.00  release onto the steep opening, clean run to build speed
##   0.10  pillar row
##   0.22  rotating bumper, left of centre
##   0.32  funnel
##   0.44  split/merge — divider island, two unequal lanes
##   0.57  merge, onto the shallowest stretch: the field compresses
##   0.66  kicker and gap, approached down the steepest drop on the course
##   0.78  pillar row, staggered against the first
##   0.86  rotating bumper, right of centre
##   0.90  final funnel — the field has to interact again before the line
##   1.00  finish line

# --- Shape --------------------------------------------------------------------

## Along-slope distance from the start line to the finish.
const LENGTH := 195.0
## Starting ramp behind the line, where the field settles.
const RAMP_LENGTH := 14.0
## Floor and rails carry on past the finish, far enough to reach the backstop the
## field piles up against. Two metres of margin beyond it, so a marble that
## arrives fast enough to bounce back off it lands on floor rather than on air.
const RUNOFF_LENGTH := 8.0

## The vertical profile, as `[fraction_along, grade_degrees]` pairs giving the
## grade *up to* that fraction. Phase 0 criterion 2 asks that slopes visibly and
## predictably influence speed, which a single constant grade cannot demonstrate:
## every marble simply accelerates for 195m. Shaping the profile is also what
## produces most of the §2.3 list for free — the shallow stretch compresses a
## spread field back together, and the steep drop before the jump means arrival
## speed at the gap depends on what happened to you upstream.
##
## Every entry descends. The spec's course rhythm names a "short uphill", and a
## dip or a plateau would read better, but both can hold a marble that arrives
## slowly: on level ground a stopped marble has nothing to restart it, and in a
## dip it settles at the bottom. The course already has one unexplained
## no-finish in roughly six races (`docs/CAMERA_SPIKE.md`); it does not need a
## second cause. The shallowest grade here is 5 degrees, which still puts about
## 1.9 m/s² down the slope — enough to always restart a stopped marble.
##
## The weighted mean is ~9.8 degrees, close to the 9.5 this course ran at when it
## was a constant grade, so the run still lands in the 20-30s target.
const PROFILE := [
	[0.10, 13.0], ## Steep launch: the field is moving before the first pillars.
	[0.28, 6.0],  ## Rolling. Shallow enough that gaps open on their own.
	[0.42, 15.0], ## Surge into the split, so lane choice happens at speed.
	[0.62, 5.0],  ## Split, merge and run-out. Shallowest stretch: the field bunches.
	[0.74, 16.0], ## The charge at the gap. Steepest on the course, and the reason
	              ## a clipped marble arrives too slow to clear it.
	[0.86, 7.0],
	[1.00, 11.0], ## Final stretch, quick enough to close a gap on the line.
]

## Half-width of the window used to smooth `PROFILE`'s steps into ramps. Taking
## the grade straight from the table puts a crease across the floor at every
## boundary — a 10 degree crease is a step a marble slams into at speed. Smoothed
## over this distance, neighbouring floor segments differ by well under a degree.
const GRADE_BLEND := 7.0
## Length of one floor/rail box. Short enough to follow the profile without
## visible faceting, long enough not to put a seam every stride: each box's top
## face is a chord through the two surface points at its ends, so consecutive
## boxes meet exactly at a shared point with no step for a marble to catch.
const SEGMENT := 6.0
## Resolution of the baked centreline. The profile is integrated rather than
## solved, because grade varies continuously once smoothed.
const BAKE_STEP := 0.5

## How far each segment runs past its own end, into the start of the next one.
##
## Boxes that meet exactly do not stay met. The two top faces are chords at
## slightly different angles sharing one point, and at that point the renderer
## has two coplanar edges and finite depth precision — so the join shows as a
## hairline of whatever is behind the course, once every `SEGMENT` metres, all
## the way down. Overlapping hides it: there is always solid geometry behind the
## seam.
##
## Overlap runs down-course only, so each segment reaches forward into the next
## rather than both reaching into each other. Where the grade steepens that
## leaves the upper segment's lip fractionally proud of the lower one, but the
## angle between neighbours is under a degree by construction (`GRADE_BLEND`), so
## the step is around a millimetre — three orders of magnitude under the marble
## radius, and facing down-course where a marble rolls off it rather than into
## it.
const SEAM_OVERLAP := 0.06

## Half the floor width. The full 12m spans most of the overhead camera's ~13.2m
## frame at `OVERHEAD_DISTANCE` / `OVERHEAD_FOV`, which is what "the width of the
## camera" means here. Retune together with those two.
const HALF_WIDTH := 6.0
const FLOOR_THICKNESS := 1.0

## Interior fixtures — funnel walls, the backstop, the wall behind the grid.
## Waist-high on a marble, so they read as things placed on the course rather
## than as the course's own sides.
const RAIL_HEIGHT := 2.2
const RAIL_THICKNESS := 0.6

## The canyon itself. The phase spec asks for "mostly a solid trough/channel",
## and thin kerbs on an open plain are not that: the track read as a table with
## edging, with the frame's corners showing bare ground beyond it.
##
## Tall enough to fill the frame at both camera distances — the lens covers
## 13.2m across at rest and 15.9m pulled back, against 18m of track plus walls —
## so the shot is bounded by rock at every speed instead of by nothing. Six
## metres cannot occlude the floor either: the camera sits over the centreline,
## so the ray to the outermost floor is only ~11 degrees off vertical and clears
## a wall of this height with a metre to spare.
const WALL_HEIGHT := 6.0
const WALL_THICKNESS := 3.0

## Fallback friction, for fixtures that are not track surface.
const FRICTION := 0.3

## Mixed surfaces, which the phase spec asks for by name: rough canyon stone
## alternating with smoother constructed track, with the difference showing in
## friction as well as colour.
##
## This is the cheapest gameplay in the whole course. It costs one lookup per
## floor segment and it gives criterion 2 something to demonstrate beyond
## gradient — a marble visibly picks up on the poured sections and scrubs off on
## the rock, and the bands are wide enough to see it happen. The spec is explicit
## that the difference stay subtle enough for the physics to remain
## understandable, so the two are 0.22 against 0.45 rather than ice against tar.
const SURFACE_ROUGH := {"friction": 0.45, "colour": Color(0.47, 0.34, 0.26)}
const SURFACE_SMOOTH := {"friction": 0.22, "colour": Color(0.45, 0.42, 0.39)}

## Which surface runs up to each fraction of the course. Deliberately not aligned
## to `PROFILE`: if the smooth sections were the steep ones the course would just
## have fast bits and slow bits, and every marble would experience them the same
## way. Offset, they interact — a shallow smooth run holds speed a shallow rough
## one would have eaten, and the rough band above the jump is what makes arrival
## speed there depend on the line you took rather than only on the gradient.
const SURFACES := [
	[0.20, SURFACE_ROUGH],
	[0.34, SURFACE_SMOOTH],
	[0.50, SURFACE_ROUGH],
	[0.64, SURFACE_SMOOTH],
	[0.78, SURFACE_ROUGH],
	[0.92, SURFACE_SMOOTH],
	[1.00, SURFACE_ROUGH],
]
## Restitution of every surface in the course — floor, rails, pillars, bumper.
##
## This is the constant that decides whether an obstacle deflects the field or
## filters it, which `DECISIONS.md` has an opinion about. At 0.1 a marble that
## met a pillar head-on kept almost none of its forward speed: it stopped dead,
## sat there while the field went past, and occasionally never restarted. At 0.3
## the same hit glances off. The field still gets scattered, which is the point;
## it stops being eliminated by a stationary cylinder.
##
## Not a fix for gravity being at 30. Obstacles cost the marble the same
## *fraction* of its speed at either gravity (47% held before, 44% after) — they
## only look more brutal because that fraction is now a bigger number, and
## because the camera turned round and holds less course either side.
const BOUNCE := 0.3

# --- Features -----------------------------------------------------------------

const PILLAR_ROW_A := 0.10
const PILLAR_ROW_B := 0.78
const PILLAR_RADIUS := 0.6
const PILLAR_HEIGHT := 1.6
## Every gap a marble can be pushed into — between two pillars, between a pillar
## and a rail, or either side of the split divider — must clear this. A marble is
## 0.9m across, and the first layout left 0.5m against the rail: the player
## wedged there at t=25 and the race never ended. Obstacles are supposed to
## deflect the field, not filter it.
const MIN_GAP := 1.4

const BUMPER_A := Vector2(0.22, -2.4) ## fraction along, lateral offset
const BUMPER_B := Vector2(0.86, 2.4)

const CHOKE_AT := 0.32
const CHOKE_LENGTH := 14.0
## Wide enough that the field squeezes through rather than jamming. The Canyon's
## funnel closes to 2.0 and that is where its field piles up and dies.
const CHOKE_HALF_WIDTH := 2.6

## A second, gentler funnel just before the line, there to produce the close
## finishes on PROJECT.md's section 2.3 list. By the final stretch the field is
## strung out over most of the course and the leader crosses alone, which is the
## least interesting way a race can end.
##
## It has to be geometry rather than any kind of catch-up, because every marble
## is physically identical by decision (section 7) and nothing may make the
## leader slower for being the leader. A narrowing does it honestly: marbles
## arriving together have to interact to get through, so a gap that was going to
## be a second becomes a scramble, while a marble that is genuinely clear is not
## slowed at all.
##
## Wider than `CHOKE_HALF_WIDTH` and shorter, deliberately. This one sits where a
## jam would ruin the whole race rather than the middle of it.
const FINAL_FUNNEL_AT := 0.90
const FINAL_FUNNEL_LENGTH := 9.0
const FINAL_FUNNEL_HALF_WIDTH := 3.4

# --- Split / merge ------------------------------------------------------------

## Phase 0 criterion 6 asks that the split/merge produce interesting outcomes
## without looking scripted, and `DECISIONS.md` is specific about how: which
## route a marble takes is decided by physics, with no player choice and no AI.
## A divider island does exactly that — a marble arrives where the field left it
## and goes the side it was already going.
##
## The lanes are deliberately unequal, and neither is the right answer. Offset
## from the centreline, the left lane is the wider of the two but carries a
## pillar; the right is clear but narrow enough that a crowd entering it has to
## sort itself out. Equal lanes would make the split a coin-flip that changes
## nothing, which is the "looks scripted" failure in a different costume.
##
## What the lanes trade is **speed, not distance**. On a course this straight no
## lane can be meaningfully shorter — angling the divider enough to shift a lane
## three metres across its 25m length buys 0.18m of path, a fifth of a marble.
## So the right lane's payoff is that it is clear of obstacles and it feeds the
## short side of the jump: its centre sits at x≈3.8, inside the rightmost landing
## lane, which is the `GAP_MIN` end of the staggered edge. Tight line in, easy
## jump out. Move `DIVIDER_OFFSET` or the gap's stagger and that pairing breaks
## silently — nothing asserts it, because "which landing lane is this lane
## pointed at" is a judgement about racing lines, not a constraint.
const SPLIT_AT := 0.44
const SPLIT_LENGTH := 25.0
const DIVIDER_OFFSET := 1.0 ## Lateral, so the two lanes come out unequal.
const DIVIDER_THICKNESS := 1.2
const DIVIDER_HEIGHT := 1.8
## Pillar in the wider lane, placed to leave two passable gaps rather than one
## wide one — so the wider lane is busier, not just better.
const DIVIDER_LANE_PILLAR := -2.8

const JUMP_AT := 0.66
const KICKER_LENGTH := 5.0
## Launch angle **above horizontal**, not above the local slope.
##
## It used to be relative to the frame, which worked while the course was one
## constant grade and silently broke when it stopped being one: `PROFILE` runs 16
## degrees here, so a ramp tilted 11 degrees out of that frame points five
## degrees *downhill*. The kicker had become a down-ramp, and marbles were
## skimming the gap on a flat trajectory rather than being thrown over it.
## Measured from horizontal, it kicks the same way whatever the profile does.
const KICKER_LAUNCH := deg_to_rad(8.0)
const KICKER_THICKNESS := 0.8
## Phase 0 criterion 8 wants falls possible but not the dominant failure — and it
## was inverted here: at 2.5m every marble in the field cleared the gap every
## time, so the jump was a bump and nothing was ever at stake.
##
## The far edge of the gap is staggered across the track rather than square to
## it, so the jump is a different length depending on the line you are on:
## `GAP_MAX` on the left, `GAP_MIN` on the right, in `GAP_LANES` steps.
##
## A square edge makes the jump a threshold, and a threshold has to be tuned to a
## knife edge — range goes with the square of speed, so 3.4m took nobody and 6m
## took the entire field, with the interesting band somewhere in between and
## moving every time anything upstream changes. A staggered edge is a gradient
## instead: there is always a line that clears and always a line that does not,
## and which one you are on is decided by the split and the bumper above it. That
## holds without retuning.
##
## The short side is the right, which is also the narrower of the split's two
## lanes — so the tight lane pays out at the jump. Making the narrow lane both
## harder to get through *and* worse to land in would just make it the wrong
## answer, and a route nobody wants is not a route.
const GAP_LANES := 4
const GAP_MIN := 2.2
const GAP_MAX := 4.5
## Distance past the lip at which the floor goes back to full width.
const GAP_RECOVER := 8.0

## A narrow bridge across the gap, hard against the left wall — one of the
## Canyon mechanics the spec lists by name, and the thing that makes the left
## side of the jump a decision rather than a penalty.
##
## The stagger already makes the left the long jump. On its own that is just a
## worse place to be, and a route that is only worse is not a route. With the
## bridge, the left is: thread 1.8m of stone, or carry enough speed for 4.5m of
## air. The right stays the plain short jump. Nothing steers, so which of these a
## marble faces was decided back at the split — which is exactly the physics-
## decides-the-route rule `DECISIONS.md` sets for the split itself.
##
## Narrow enough to be a real thread — a marble is 0.9m across, so this is two
## marble widths and change, and a crowd arriving together will knock some of
## each other off it.
const BRIDGE_WIDTH := 1.8

## Cross-stripes every this many metres. Purely visual, no collision. The first
## overhead render came back as an unbroken beige mass with no sense of motion
## in it (`docs/CAMERA_SPIKE.md`); a top-down camera needs something on the
## surface to move past.

## Canyon palette. Floor colour now comes from `SURFACES`, so what is left here
## is everything that is not track surface.
##
## Warm rock against a cool sky, which is what makes the marbles readable: the
## field is saturated primaries (`_opponent_colour` runs the full hue wheel at
## 0.45 saturation) and the player's is cyan, none of which any of this competes
## with. The old palette put an orange kerb next to orange marbles.
## Everything below is deliberately low-saturation. The first canyon palette was
## right in hue and wrong in intensity — a bright orange kerb beside a red-brown
## floor beside a pale grey track reads as moulded plastic, because saturated
## flat colour is what toys are made of and weathered rock is not. Real stone
## sits between 0.10 and 0.25 saturation; the contrast that makes a course
## readable should come from value and from the marbles, which are the only
## saturated things in frame and are supposed to be.
const WALL_COLOUR := Color(0.36, 0.25, 0.20)
## Wall tops catch the sun; the strip along the rim is what gives the trough a
## readable height rather than looking like a painted border.
const WALL_RIM_COLOUR := Color(0.72, 0.52, 0.36)

## The wall's cross-section, bottom tier first: how tall each band is, how far it
## steps back from the one below, and what colour the rock is.
##
## Two things were making the canyon read as a corridor. It was one flat slab of
## one colour, and it was perfectly vertical — so the only edge in the whole
## frame was where wall met floor, and nothing said how tall it was or what it
## was made of. Sedimentary banding and a stepped profile are the two things a
## real canyon has that a wall does not.
##
## Every tier steps *outward* going up, never in. An overhang would put a ledge
## over the track that a stray marble could land on and sit out the race, and
## this course has produced enough of those already. Stepping out also opens the
## trough towards the sky, which is what stops six metres of rock either side
## feeling like a lid.
##
## Colours run dark at the bottom to pale at the rim — shadowed rock below,
## sun-bleached stone above. That gradient does the same job as the rim strip,
## on the whole height rather than the last half metre.
const WALL_TIERS := [
	{"height": 2.1, "inset": 0.0, "colour": Color(0.34, 0.22, 0.17)},
	{"height": 1.5, "inset": 0.45, "colour": Color(0.50, 0.31, 0.23)},
	{"height": 1.2, "inset": 0.95, "colour": Color(0.42, 0.28, 0.22)},
	{"height": 1.7, "inset": 1.55, "colour": Color(0.63, 0.44, 0.31)},
]

## How much a segment's rock colour may drift from its tier's base colour. Rock
## is not painted: without this the strata are four perfectly even ribbons
## running the length of the course, which reads as architecture. Deterministic
## rather than random, so a course rebuilds identically — a restart that reshuffles
## the scenery looks like a glitch.
const WALL_COLOUR_VARIANCE := 0.09

## Dark scree where wall meets floor. The join is the strongest line in frame and
## a hard edge between two flat colours is what makes it look like a join rather
## than a place where rock meets sand.
const SCREE_COLOUR := Color(0.30, 0.20, 0.16)
const SCREE_WIDTH := 1.3
## Funnel walls, backstop, the wall behind the grid — the course's constructed
## sections, which the phase spec allows a few of. Weathered timber and old
## steel rather than fresh paint: they have to read as placed rather than
## natural, but a marble race is not a construction site.
const RAIL_COLOUR := Color(0.44, 0.36, 0.30)
const OBSTACLE_COLOUR := Color(0.50, 0.44, 0.38)
const ROCK_COLOUR := Color(0.41, 0.30, 0.24)
## The one thing in the course allowed to be bright, because it is the only thing
## the player is meant to be looking for besides the marbles.
const FINISH_COLOUR := Color(0.92, 0.91, 0.86)
## The canyon floor, far below the jump. Without it the gap is a hole with sky
## behind it, which reads as a hole in the *level*; with it, it reads as a drop.
const CHASM_COLOUR := Color(0.24, 0.17, 0.14)
const CHASM_DROP := 26.0

## Baked centreline, sampled every `BAKE_STEP` from `-RAMP_LENGTH`.
var _baked: PackedVector3Array = PackedVector3Array()


func build() -> void:
	_bake_centreline()
	_build_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_floor()
	_build_walls()
	_build_back_wall()
	_build_chasm_floor()
	_build_rubble()

	_build_pillar_row(PILLAR_ROW_A, [-3.4, 0.0, 3.4])
	_build_pillar_row(PILLAR_ROW_B, [-3.9, -1.3, 1.3, 3.9])
	_build_bumper(BUMPER_A)
	_build_bumper(BUMPER_B)
	_build_choke()
	_build_split()
	_build_kicker()
	_build_finish_line()


# --- Profile ------------------------------------------------------------------


## Grade at distance `s`, in radians, smoothed. `PROFILE` is a step function and
## a step in grade is a crease in the floor; this averages it over a window so
## the surface ramps between grades instead of hinging.
func _grade_at(s: float) -> float:
	var total := 0.0
	var taps := 5
	for i in taps:
		# Even spread across +/- GRADE_BLEND.
		var offset := (float(i) / float(taps - 1) - 0.5) * 2.0 * GRADE_BLEND
		total += _profile_grade(s + offset)
	return deg_to_rad(total / float(taps))


## The raw step function, before smoothing. Distances before the start line and
## past the finish hold the first and last grades respectively, so the starting
## ramp and the run-out are continuous with the course.
func _profile_grade(s: float) -> float:
	var fraction := s / LENGTH
	for entry: Array in PROFILE:
		if fraction <= entry[0]:
			return entry[1]
	return PROFILE[PROFILE.size() - 1][1]


## Integrates the grade into a centreline. Solved numerically rather than in
## closed form because the smoothed grade has no tidy antiderivative, and because
## a baked polyline is what `_point` and the camera's `Curve3D` both want anyway.
func _bake_centreline() -> void:
	_baked = PackedVector3Array()

	var point := Vector3.ZERO
	var s := -RAMP_LENGTH
	var last := LENGTH + RUNOFF_LENGTH

	while s <= last + BAKE_STEP:
		_baked.append(point)
		var grade := _grade_at(s)
		point += Vector3(0.0, -sin(grade), -cos(grade)) * BAKE_STEP
		s += BAKE_STEP

	# Re-origin so the start line sits at (0, 0, 0). Everything else in the
	# course — spawns, camera, fall threshold — is written against that.
	var origin := _sample_baked(0.0)
	for i in _baked.size():
		_baked[i] = _baked[i] - origin


func _sample_baked(s: float) -> Vector3:
	if _baked.is_empty():
		return Vector3.ZERO

	var index := (s + RAMP_LENGTH) / BAKE_STEP
	var low := int(floor(index))
	var last := _baked.size() - 1

	if low < 0:
		return _baked[0]
	if low >= last:
		return _baked[last]

	return _baked[low].lerp(_baked[low + 1], index - float(low))


# --- Frame --------------------------------------------------------------------


## Distance `s` is measured along the slope from the start line: negative is up
## the starting ramp, `LENGTH` is the finish.
func _point(s: float) -> Vector3:
	return _sample_baked(s)


func _forward_at(s: float) -> Vector3:
	var grade := _grade_at(s)
	return Vector3(0.0, -sin(grade), -cos(grade))


## Every fixture is placed through this, so nothing in the course has to know the
## profile. Local -Z runs down-slope, local Y is the floor normal.
func _frame_at(s: float) -> Transform3D:
	var forward := _forward_at(s)
	var right := Vector3.RIGHT
	var up := right.cross(forward).normalized()
	return Transform3D(Basis(right, up, -forward), _point(s))


func _at(fraction: float) -> Transform3D:
	return _frame_at(fraction * LENGTH)


## Sampled rather than given two endpoints: the camera steers by this curve's
## tangent, and a straight line between start and finish would tell it the course
## descends at a constant 9.8 degrees the whole way.
func _build_curve() -> void:
	curve = Curve3D.new()
	var s := -RAMP_LENGTH
	while s <= LENGTH + RUNOFF_LENGTH:
		curve.add_point(_point(s))
		s += 4.0


# --- Surface ------------------------------------------------------------------


## The floor follows the profile as a run of chords. Each box's top face passes
## through the surface points at both its ends, so consecutive boxes meet at a
## shared point — the joint changes angle but has no step, which matters because
## seams on a sloped surface are what the Canyon builder's own notes call out as
## marble traps.
##
## The floor is laid as two runs with the jump's gap between them, and each run
## is segmented to end exactly on its own boundary. Segmenting the whole length
## and skipping segments that overlap the gap is the obvious version and it is
## wrong: segments are 6m, so a 3.4m gap deletes the whole segment it falls in —
## two of them when it straddles a boundary. That made the gap 6-12m wide and
## took ten of twelve marbles with it.
func _build_floor() -> void:
	var lip := JUMP_AT * LENGTH
	var resume := lip + GAP_RECOVER

	_build_floor_run(-RAMP_LENGTH, lip)

	# The staggered landing edge: one strip per lane, each starting where that
	# lane's jump ends. Between the lip and `resume` the floor is these strips
	# only; past it, full width again.
	var lane_width := HALF_WIDTH * 2.0 / float(GAP_LANES)
	for lane in GAP_LANES:
		var across := float(lane) / float(GAP_LANES - 1)
		var gap := lerpf(GAP_MAX, GAP_MIN, across)
		var lateral := -HALF_WIDTH + lane_width * (float(lane) + 0.5)
		_build_floor_run(lip + gap, resume, lateral, lane_width)

	# The bridge spans the whole gap on the far left, where the jump is longest.
	_build_floor_run(lip, resume, -HALF_WIDTH + BRIDGE_WIDTH * 0.5, BRIDGE_WIDTH)

	_build_floor_run(resume, LENGTH + RUNOFF_LENGTH)


func _build_floor_run(from_s: float, to_s: float, lateral := 0.0, width := 0.0) -> void:
	if width <= 0.0:
		width = HALF_WIDTH * 2.0

	var s := from_s
	while s < to_s - 0.001:
		var to := minf(s + SEGMENT, to_s)
		# Sampled at the segment's midpoint, so a band boundary lands on whichever
		# segment straddles it rather than splitting one.
		var surface: Dictionary = _surface_at((s + to) * 0.5)
		# One flat colour per band, deliberately. Weathering the floor per segment
		# breaks up the flatness but it also draws a line at every segment
		# boundary, which is the opposite of what is wanted — the floor is most of
		# the frame, so it is where a seam shows worst. The rough/smooth banding
		# carries the variety instead, without drawing a line anywhere.
		_add_surface_box(
			s, to, lateral, width, FLOOR_THICKNESS, -FLOOR_THICKNESS * 0.5,
			surface["colour"], surface["friction"]
		)
		s = to


## Which surface the track has at distance `s`. Before the start line the course
## is rough, so the field settles and launches off stone rather than off whatever
## the first band happens to be.
func _surface_at(s: float) -> Dictionary:
	var fraction := s / LENGTH
	for entry: Array in SURFACES:
		if fraction <= entry[0]:
			return entry[1]
	return SURFACES[SURFACES.size() - 1][1]


## The canyon walls, one box per segment per side so they follow the profile.
##
## Each side gets a rim strip along its top in a lighter rock colour. It costs
## two more boxes per segment and it is what makes the wall read as a wall: a
## single flat slab of one colour at this camera angle looks like a border drawn
## on the ground, because there is no lighting change to tell you it has a top.
## Collision and appearance are built separately here, which is the only reason
## the tiers are safe. The collider is one plain slab with its inner face at
## `HALF_WIDTH` for the wall's full height, exactly as before — the physics of
## the trough are unchanged and unchangeable by anything cosmetic. The strata are
## meshes laid over and outside it.
##
## Where they disagree, the invisible wall is always *inside* the visible rock,
## so nothing ever appears to pass through stone; a marble bouncing high simply
## stops a few centimetres early against a face it cannot reach anyway.
func _build_walls() -> void:
	var offset := HALF_WIDTH + WALL_THICKNESS * 0.5
	var rim := 0.4

	for side: float in [-1.0, 1.0]:
		var s := -RAMP_LENGTH
		var index := 0
		while s < LENGTH + RUNOFF_LENGTH:
			var to := minf(s + SEGMENT, LENGTH + RUNOFF_LENGTH)

			_add_collider_box(s, to, side * offset, WALL_THICKNESS, WALL_HEIGHT, WALL_HEIGHT * 0.5)

			var base := 0.0
			for tier: Dictionary in WALL_TIERS:
				var height: float = tier["height"]
				var inset: float = tier["inset"]
				_add_visual_box(
					s, to,
					side * (offset + inset),
					WALL_THICKNESS, height, base + height * 0.5,
					_weathered(tier["colour"], index)
				)
				base += height

			_add_visual_box(
				s, to, side * (offset + WALL_TIERS[WALL_TIERS.size() - 1]["inset"]),
				WALL_THICKNESS, rim, base + rim * 0.5, WALL_RIM_COLOUR
			)

			# Scree, laid on the floor rather than against the wall so it never
			# becomes a lip. Purely a softener for the wall/floor join.
			_add_visual_box(
				s, to, side * (HALF_WIDTH - SCREE_WIDTH * 0.5),
				SCREE_WIDTH, 0.06, 0.03, _weathered(SCREE_COLOUR, index + 3)
			)

			s += SEGMENT
			index += 1


## A tier's colour, nudged per segment so the strata are not four even ribbons.
## Hashed off the segment index rather than drawn from an RNG: the course must
## rebuild identically on restart, and `_rng` belongs to the race, not the
## scenery.
func _weathered(base: Color, index: int) -> Color:
	var noise := fmod(sin(float(index) * 12.9898) * 43758.5453, 1.0)
	return base.lightened(absf(noise) * WALL_COLOUR_VARIANCE)


## Loose rock along the base of the walls. Canyon dressing, and it does a little
## work: it makes the trough's sides irregular, so a marble running the wall does
## not travel a perfectly smooth line. Kept under a metre so the usable width
## never drops near `MIN_GAP`.
func _build_rubble() -> void:
	var placed := 0.0
	var index := 0

	while placed < LENGTH:
		placed += 11.0
		index += 1
		var side := 1.0 if index % 2 == 0 else -1.0
		# Skipped over the jump, where there is no floor to sit on.
		if placed > JUMP_AT * LENGTH - 6.0 and placed < JUMP_AT * LENGTH + GAP_RECOVER:
			continue

		var radius := 0.55 + fmod(float(index) * 0.37, 0.35)
		var body := StaticBody3D.new()
		body.transform = _frame_at(placed).translated_local(
			Vector3(side * (HALF_WIDTH - radius * 0.4), radius * 0.35, 0.0)
		)
		body.physics_material_override = _surface(SURFACE_ROUGH["friction"])

		var shape := SphereShape3D.new()
		shape.radius = radius
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 6
		mesh.rings = 3 ## Faceted on purpose: smooth spheres read as more marbles.
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(ROCK_COLOUR)
		body.add_child(visual)

		add_child(body)


## A slab far below the jump so the gap reads as a drop into a canyon rather than
## a hole cut in the level with sky behind it. Visual only — anything that falls
## this far is already eliminated by `fall_threshold_y`.
func _build_chasm_floor() -> void:
	var lip := JUMP_AT * LENGTH
	var mesh := BoxMesh.new()
	mesh.size = Vector3(HALF_WIDTH * 2.0 + WALL_THICKNESS * 2.0, 1.0, GAP_RECOVER + 24.0)

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(CHASM_COLOUR)
	visual.transform = _frame_at(lip + GAP_RECOVER * 0.5).translated_local(
		Vector3(0.0, -CHASM_DROP, 0.0)
	)
	add_child(visual)


func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(
			Vector3(0.0, RAIL_HEIGHT * 0.5, RAIL_THICKNESS * 0.5)
		),
		Vector3(HALF_WIDTH * 2.0, RAIL_HEIGHT, RAIL_THICKNESS),
		RAIL_COLOUR.darkened(0.35)
	)


# --- Obstacles ----------------------------------------------------------------


## Static geometry, not a mechanic. `DECISIONS.md` fixes the rotating bumper as
## the only Phase 0 obstacle and parks boosters, launchers, moving platforms and
## conveyors for later courses; pillars are neither — they are something to
## bounce off, the same way a wall is.
func _build_pillar_row(fraction: float, offsets: Array) -> void:
	var frame := _at(fraction)
	_assert_gaps_passable(offsets, -HALF_WIDTH, HALF_WIDTH)

	for offset: float in offsets:
		_add_pillar(frame, offset)


func _add_pillar(frame: Transform3D, offset: float) -> void:
	var body := StaticBody3D.new()
	body.transform = frame.translated_local(Vector3(offset, PILLAR_HEIGHT * 0.5, 0.0))
	body.physics_material_override = _surface()

	var shape := CylinderShape3D.new()
	shape.radius = PILLAR_RADIUS
	shape.height = PILLAR_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	# Faceted and tapered, so it reads as a weathered rock column rather than a
	# turned plastic peg. The collider stays a clean cylinder — the facets are
	# only ever a few centimetres and marbles should bounce off the shape the
	# course was tuned with, not off whatever the mesh happens to do.
	var mesh := CylinderMesh.new()
	mesh.top_radius = PILLAR_RADIUS * 0.82
	mesh.bottom_radius = PILLAR_RADIUS * 1.12
	mesh.height = PILLAR_HEIGHT
	mesh.radial_segments = 7
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(
		_weathered(OBSTACLE_COLOUR, int(abs(offset) * 7.0))
	)
	body.add_child(visual)

	# A skirt of debris where the column meets the floor, so it looks eroded into
	# the ground rather than dropped onto it.
	var skirt := MeshInstance3D.new()
	var skirt_mesh := CylinderMesh.new()
	skirt_mesh.top_radius = PILLAR_RADIUS * 1.25
	skirt_mesh.bottom_radius = PILLAR_RADIUS * 1.75
	skirt_mesh.height = 0.22
	skirt_mesh.radial_segments = 7
	skirt.mesh = skirt_mesh
	skirt.material_override = _material(ROCK_COLOUR)
	skirt.position = Vector3(0.0, -PILLAR_HEIGHT * 0.5 + 0.11, 0.0)
	visual.add_child(skirt)

	add_child(body)


## Checked rather than eyeballed, because the failure is silent: a too-narrow gap
## does not look wrong in the editor, it just quietly swallows a marble twenty
## seconds into a run and hangs the race. Takes explicit edges so the split's
## lanes can be checked against the divider rather than the rails.
func _assert_gaps_passable(offsets: Array, left_edge: float, right_edge: float) -> void:
	var edges := [left_edge]
	for offset: float in offsets:
		edges.append(offset - PILLAR_RADIUS)
		edges.append(offset + PILLAR_RADIUS)
	edges.append(right_edge)

	for i in range(0, edges.size() - 1, 2):
		var gap: float = edges[i + 1] - edges[i]
		assert(
			gap >= MIN_GAP,
			"Gap of %.2fm is under MIN_GAP (%.2fm); marbles wedge." % [gap, MIN_GAP]
		)


func _build_bumper(placement: Vector2) -> void:
	var bumper := RotatingBumper.create()
	bumper.transform = _at(placement.x).translated_local(Vector3(placement.y, 0.0, 0.0))
	add_child(bumper)


## Two walls angled inwards. They narrow the track without narrowing the floor,
## so a marble that loses the squeeze is deflected rather than stopped.
func _build_choke() -> void:
	_build_funnel(CHOKE_AT, CHOKE_LENGTH, CHOKE_HALF_WIDTH)
	_build_funnel(FINAL_FUNNEL_AT, FINAL_FUNNEL_LENGTH, FINAL_FUNNEL_HALF_WIDTH)


func _build_funnel(at: float, length: float, half_width: float) -> void:
	var taper := HALF_WIDTH - half_width
	var angle := atan2(taper, length)
	var span := sqrt(taper * taper + length * length)
	var centre := at * LENGTH + length * 0.5

	for side: float in [-1.0, 1.0]:
		var frame := _frame_at(centre).translated_local(
			Vector3(side * (HALF_WIDTH + half_width) * 0.5, RAIL_HEIGHT * 0.5, 0.0)
		)
		_add_box(
			frame.rotated_local(Vector3.UP, side * angle),
			Vector3(RAIL_THICKNESS, RAIL_HEIGHT, span),
			RAIL_COLOUR.darkened(0.15)
		)


## The divider island, plus the pillar that makes the wider lane the busier one.
##
## Both ends are capped with a cylinder of the divider's own width. A flat face
## presented to an oncoming field is the worst object on a course: a marble that
## meets it square stops dead and blocks the split for everything behind it. A
## round nose sends that marble one way or the other, which is the whole point of
## the feature, and a round tail does the same job for the merge.
func _build_split() -> void:
	var from_s := SPLIT_AT * LENGTH
	var to_s := from_s + SPLIT_LENGTH
	var radius := DIVIDER_THICKNESS * 0.5

	var left_lane_edge := DIVIDER_OFFSET - radius
	var right_lane_edge := DIVIDER_OFFSET + radius
	# The wider lane and its pillar; the narrow lane is checked as one clear gap.
	_assert_gaps_passable([DIVIDER_LANE_PILLAR], -HALF_WIDTH, left_lane_edge)
	_assert_gaps_passable([], right_lane_edge, HALF_WIDTH)

	# Built in segments so it weathers along its length like the walls do. As one
	# box in one colour it was a twenty-five metre pale slab down the middle of
	# the frame — the most toy-like object on the course.
	var chunk := 5.0
	var at := from_s
	var index := 0
	while at < to_s - 0.001:
		var next := minf(at + chunk, to_s)
		_add_surface_box(
			at, next, DIVIDER_OFFSET,
			DIVIDER_THICKNESS, DIVIDER_HEIGHT, DIVIDER_HEIGHT * 0.5,
			_weathered(WALL_COLOUR.lightened(0.12), index + 11)
		)
		at = next
		index += 1

	for end_s: float in [from_s, to_s]:
		var body := StaticBody3D.new()
		body.transform = _frame_at(end_s).translated_local(
			Vector3(DIVIDER_OFFSET, DIVIDER_HEIGHT * 0.5, 0.0)
		)
		body.physics_material_override = _surface()

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
		visual.material_override = _material(OBSTACLE_COLOUR.darkened(0.1))
		body.add_child(visual)

		add_child(body)

	_add_pillar(_frame_at(from_s + SPLIT_LENGTH * 0.55), DIVIDER_LANE_PILLAR)


## Pivoted at its near end rather than its centre, so the top face starts flush
## with the floor and rises from there. Rotating about the centre would sink the
## near end and leave a step for marbles to slam into at speed.
## A curved ramp, not a tilted slab.
##
## A single box rotated to the launch angle meets the floor at whatever the
## difference between the two happens to be, and once the launch angle was
## measured from horizontal that difference became 24 degrees against a 16 degree
## floor. That is not a ramp, it is a V: a marble arriving slowly rolls into the
## crease and gravity holds it there, because the only direction out is up. Four
## of twelve parked at the foot of it and the race never ended.
##
## Built instead as a run of short segments whose pitch eases from exactly the
## floor's own grade to `KICKER_LAUNCH`, smoothstepped so the tangent matches the
## floor at the bottom and the launch angle at the lip. Same reasoning as
## `GRADE_BLEND` on the floor itself — a marble at speed does not care about a
## hinge, and a marble not at speed cannot get over one.
const KICKER_SEGMENTS := 8


func _build_kicker() -> void:
	var lip := JUMP_AT * LENGTH
	var start_s := lip - KICKER_LENGTH
	var grade := _grade_at(start_s)

	var point := _point(start_s)
	var step := KICKER_LENGTH / float(KICKER_SEGMENTS)

	for i in KICKER_SEGMENTS:
		# Pitch relative to horizontal: starts at the floor's own descent
		# (negative) and eases up to the launch angle (positive).
		var t := smoothstep(0.0, 1.0, (float(i) + 0.5) / float(KICKER_SEGMENTS))
		var pitch := lerpf(-grade, KICKER_LAUNCH, t)
		var direction := Vector3(0.0, sin(pitch), -cos(pitch))

		var next := point + direction * step
		_add_ramp_segment(point, next)
		point = next


## One slab of the kicker, with its top face running between the two points.
func _add_ramp_segment(from_point: Vector3, to_point: Vector3) -> void:
	var along := to_point - from_point
	var span := along.length()
	if span < 0.001:
		return

	var forward := along / span
	var right := Vector3.RIGHT
	var up := right.cross(forward).normalized()

	var centre := (from_point + to_point) * 0.5 - up * (KICKER_THICKNESS * 0.5)
	_add_box(
		Transform3D(Basis(right, up, -forward), centre),
		Vector3(HALF_WIDTH * 2.0, KICKER_THICKNESS, span),
		OBSTACLE_COLOUR.darkened(0.15)
	)


## A visible line plus a backstop. The line is what the player reads; the
## backstop is so finishers pile up just past it instead of rolling off the end
## and registering as falls.
func _build_finish_line() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = FINISH_COLOUR
	material.roughness = 0.8

	var mesh := BoxMesh.new()
	mesh.size = Vector3(HALF_WIDTH * 2.0, 0.06, 1.0)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.transform = _frame_at(LENGTH).translated_local(Vector3(0.0, 0.03, 0.0))
	add_child(visual)

	_add_box(
		_frame_at(LENGTH + 6.0).translated_local(Vector3(0.0, RAIL_HEIGHT * 0.5, 0.0)),
		Vector3(HALF_WIDTH * 2.0, RAIL_HEIGHT, RAIL_THICKNESS),
		RAIL_COLOUR.darkened(0.35)
	)


# --- Helpers ------------------------------------------------------------------


## A box following the surface between two distances, offset laterally and lifted
## in the local frame. Built from its two endpoints rather than from a midpoint
## and a length, which is what keeps consecutive segments meeting exactly.
func _add_surface_box(
	from_s: float,
	to_s: float,
	lateral: float,
	width: float,
	height: float,
	lift: float,
	colour: Color,
	friction := -1.0
) -> void:
	var start: Vector3 = _frame_at(from_s) * Vector3(lateral, lift, 0.0)
	var end: Vector3 = _frame_at(to_s + SEAM_OVERLAP) * Vector3(lateral, lift, 0.0)

	var along := end - start
	var span := along.length()
	if span < 0.001:
		return

	var forward := along / span
	var right := Vector3.RIGHT
	var up := right.cross(forward).normalized()

	_add_box(
		Transform3D(Basis(right, up, -forward), (start + end) * 0.5),
		Vector3(width, height, span),
		colour,
		friction
	)


## Same placement as `_add_surface_box` but collision only, for shapes whose
## appearance is built separately — the canyon walls, where the strata are meshes
## laid over one plain slab.
func _add_collider_box(
	from_s: float,
	to_s: float,
	lateral: float,
	width: float,
	height: float,
	lift: float
) -> void:
	var start: Vector3 = _frame_at(from_s) * Vector3(lateral, lift, 0.0)
	var end: Vector3 = _frame_at(to_s + SEAM_OVERLAP) * Vector3(lateral, lift, 0.0)

	var along := end - start
	var span := along.length()
	if span < 0.001:
		return

	var forward := along / span
	var right := Vector3.RIGHT
	var up := right.cross(forward).normalized()

	var body := StaticBody3D.new()
	body.transform = Transform3D(Basis(right, up, -forward), (start + end) * 0.5)
	body.physics_material_override = _surface()

	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, span)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	add_child(body)


## Same placement as `_add_surface_box` but mesh only, for dressing that must
## never be something a marble can hit.
func _add_visual_box(
	from_s: float,
	to_s: float,
	lateral: float,
	width: float,
	height: float,
	lift: float,
	colour: Color
) -> void:
	var start: Vector3 = _frame_at(from_s) * Vector3(lateral, lift, 0.0)
	var end: Vector3 = _frame_at(to_s + SEAM_OVERLAP) * Vector3(lateral, lift, 0.0)

	var along := end - start
	var span := along.length()
	if span < 0.001:
		return

	var forward := along / span
	var right := Vector3.RIGHT
	var up := right.cross(forward).normalized()

	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, span)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(colour)
	visual.transform = Transform3D(Basis(right, up, -forward), (start + end) * 0.5)
	add_child(visual)


func _surface(friction := -1.0) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = FRICTION if friction < 0.0 else friction
	material.bounce = BOUNCE
	return material


## Rock is not plastic: fully rough, no metallic, and specular killed outright.
## Godot's default specular puts a soft sheen on every surface, and a sheen
## across a whole canyon is most of what made it look moulded. The marbles keep
## their own material and stay the only shiny things in frame.
func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


func _add_box(transform: Transform3D, size: Vector3, colour: Color, friction := -1.0) -> void:
	var body := StaticBody3D.new()
	body.transform = transform
	body.physics_material_override = _surface(friction)

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


# --- Course interface ---------------------------------------------------------


func fall_threshold_y() -> float:
	# Only the gap can drop a marble out of this course, and the rails stop
	# everything else, so the threshold just has to sit clear of the finish.
	return _point(LENGTH).y - 20.0


func finish_width() -> float:
	return HALF_WIDTH * 2.0


func start_width() -> float:
	return HALF_WIDTH * 2.0


## Six across rather than the Canyon's four: the track is twice as wide, and a
## narrow huddle on a wide start line wastes the opening entirely.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 6
	var spacing := 1.7

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.5 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(Transform3D(Basis.IDENTITY, _frame_at(-back) * Vector3(x, 0.9, 0.0)))

	return spawns
