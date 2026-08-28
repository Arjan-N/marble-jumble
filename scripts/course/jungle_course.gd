class_name JungleCourse
extends Course

## The second course, and deliberately not the first one repainted.
##
## `PROJECT.md` Â§2.4 says the physical interaction a course creates matters more
## than its theme, so a green canyon would be a reskin, not a course. This
## differs from `SlopeCourse` on four axes at once, and each one changes how it
## plays rather than how it looks:
##
## | | Canyon | Jungle |
## | --- | --- | --- |
## | Plan | dead straight | turns, with camber that follows the corners |
## | Section | flat floor, vertical walls | rounded channel, marbles ride the sides |
## | Edges | walled, no escape | open â a fast corner can throw you out |
## | Surface | fast stone, faster poured track | slow mud, fast wet wood â inverted |
## | Falls | one committed jump | several small gaps to thread |
##
## The canyon's identity is hard, dry, enclosed, one big jump you either make or
## do not. This one is soft, wet, open, and constantly nibbling at you.
##
## Obstacles are the rotating bumper (as a spinning log) plus terrain â trunks,
## roots, stones, mud. `DECISIONS.md` fixes the bumper as the only Phase 0
## obstacle and parks launchers, conveyors and moving platforms, which rules out
## the bouncy mushrooms and swinging vines this theme is asking for. They need a
## decision, not a commit. Everything here is either that one obstacle or
## geometry, on the same justification the canyon's pillars were given: a thing
## to bounce off, the same way a wall is.

# --- Shape --------------------------------------------------------------------

const LENGTH := 190.0
const RAMP_LENGTH := 14.0
## The run-out past the line, where the field actually comes to rest now.
##
## Was 8 metres, which was only ever enough to reach a wall: a marble crossed,
## rolled for a moment and was stopped. `FinishZone` ramps damping across this
## distance instead, so it has to be long enough for that ramp to do the work â
## the marble slows because the runoff slows it, not because something is in the
## way. `CoursePath` also eases the descent off across it (see `RUNOFF_FLATTEN`),
## so the far end is near level.
const RUNOFF_LENGTH := 30.0

## Gentler overall than the canyon, with the drop concentrated in one place. The
## canyon accelerates you almost everywhere; this holds you back and then lets go
## at 0.52, so speed here is something the course gives and takes rather than
## something that only accumulates.
##
## Same floor of 5 degrees as the canyon, for the same reason: nothing may be
## shallow enough to hold a marble that arrives slowly.
const PITCH := [
	[0.10, 11.0], ## Off the line under the canopy.
	[0.26, 6.0],  ## Winding and slow; the first corners are taken at low speed.
	[0.40, 13.0],
	[0.52, 5.0],  ## The mud. Shallow *and* slow, which is the point.
	[0.66, 16.0], ## Released down the drop, straight at the stones.
	[0.80, 7.0],
	[1.00, 12.0],
]

## Absolute bearing in degrees, positive turning right. The thing `SlopeCourse`
## structurally cannot do.
##
## Two corners, then the S-curve the phase spec has always asked for and no
## course has ever had. Written as bearings rather than turn rates so the shape
## is readable here: the course points right for a while, then left, then right
## again, and `CoursePath` works out how hard it has to turn to get between them
## and banks the corner accordingly.
##
## Kept under 30 degrees throughout. The camera holds about 22m of course and
## steers by the centreline tangent, so a corner sharper than this starts hiding
## the track behind its own outside edge.
const HEADING := [
	[0.08, 0.0],
	[0.22, 24.0],  ## First bend, taken slowly â an introduction to camber.
	[0.36, 4.0],
	[0.52, -22.0], ## Into the S.
	[0.68, 12.0],  ## And back out of it, at the fastest part of the course.
	[0.80, 0.0],
	[0.90, -10.0], ## A last drift, so the run-in is not a straight line.
	[1.00, 0.0],
]

## Widest the channel ever gets, and the number the camera lens is sized against.
## The actual width at any point comes from `WIDTH`.
const HALF_WIDTH := 5.4

## Half-width along the course, as `[[fraction, metres], ...]`.
##
## The canyon's width is a constant with two funnels bolted on as angled walls
## standing in it. Expressing it as a profile instead means a funnel is not a
## thing built on the course, it is the course being narrower there â no walls to
## place, no crease where they meet the floor, and the whole shape readable in
## one table.
##
## Three jobs are done entirely with this. **The equaliser** at 0.58 squeezes to
## 2.9m: too narrow for a spread field to pass abreast, so whoever is ahead has
## to queue with whoever is not, and a race that had strung out arrives at the
## drop stacked again. **The log** at 0.74 is tight and deep together, which is
## what makes it a tube rather than a narrow bit. **The run-in** at 0.92 closes
## once more so the finish is a scramble.
##
## Never below 2.7m. Two marbles abreast is 1.8m, and a squeeze the field cannot
## physically resolve is a jam, not a funnel â the Canyon's own notes record its
## field dying in a 2.0m one.
const WIDTH := [
	[0.10, 5.0],
	[0.22, 6.4], ## Opens through the first bend, so the camber has room to work.
	[0.34, 4.4],
	[0.46, 6.2],
	[0.58, 3.9], ## The equaliser.
	[0.68, 5.6],
	[0.78, 3.7], ## The hollow log.
	[0.88, 6.0],
	[0.95, 4.1], ## Run-in.
	[1.00, 5.2],
]
## How far the channel lifts at its edge. This is the number that decides whether
## the course feels like a gutter or a plate: at 0 it is the canyon's flat floor,
## and too high turns every corner into a wall the field simply parks against.
const CHANNEL_RISE := 1.05
## Extra depth through the hollow log, added to `CHANNEL_RISE`.
##
## Depth and width together are what make a tube. The log used to be a low
## friction band with an evocative name and the same cross-section as everything
## else; narrow *and* deep, the sides come up past a marble's own height and
## there is no camber escape from it â you are in there until it ends.
const LOG_RISE := 0.3
const LOG_AT := 0.72
const LOG_LENGTH := 22.0
## Length of one piece of the fixtures that are still built from boxes â the
## root, the undergrowth. Those sit along the centreline rather than across it,
## so the banking problem that forced the channel into a mesh does not reach
## them.
const SEGMENT := 5.0

## Distance between generated cross-sections. The channel is a mesh, not a run of
## boxes, and this is its resolution along the course.
##
## The canyon is built from boxes and that works because it is straight and flat:
## two neighbouring boxes differ only in pitch, by well under a degree, so the
## join between them is invisible and unhittable. Neither holds here. A banked
## corner rolls the frame as well as pitching it, and the roll changes fastest
## exactly where the corner starts â at 5m segments that put a **0.6m step**
## between neighbours at the channel edge, which to a 0.45m marble is a wall. The
## whole field parked against the first one.
##
## No box can fix that, because the two ends of a segment on a banked turn are
## rolled differently and a box has one orientation. A generated surface has a
## vertex row at every station instead, so the channel is continuous by
## construction â and it has no seams anywhere either, which the canyon needed a
## deliberate overlap to fake.
const MESH_STEP := 1.0

## How far past the racing width the bowl keeps climbing before it ends.
##
## There is no lip, and there were two attempts at one before it became clear
## there should not be. A lip is a separate thing standing on the surface, so it
## has a crease where it meets â and a crease running along a banked course is a
## gutter whose depth changes with the camber. Where the bank reverses, that
## gutter closes into a bowl, and four marbles sat in the one at the S-curve exit
## with nothing to roll down.
##
## Instead the section simply keeps rising past `HALF_WIDTH` on the same curve.
## No crease exists to trap anything, containment comes from the climb being
## steep out there, and a marble carrying enough speed still goes over the top â
## which is the open-edged feel this course is for.
##
## It has to clear 1.4m, which is the one number here that was ever measured
## against a real field: at that depth "open edges" was not a distinctive failure
## mode, it was the *only* failure mode, with nine or ten of twelve going over
## the side every race. Nothing steers, and a banked corner throws everything
## outwards by design. A course that eliminates five-sixths of the field on
## geometry is not harder, it is just less of a race.
##
## Everything else this comment used to say about depth is void, because the
## depth it was reasoning about was not the depth being built â see `SHOULDER`.
##
## The racing surface is still shallow â `CHANNEL_RISE` over `HALF_WIDTH` is a
## dish, not a gutter. Past that the climb steepens quadratically into something
## closer to a wall, so a marble drifting wide loses ground and comes back, and
## only one arriving genuinely fast still goes over. Still no crease anywhere:
## the whole section is one monotonic curve, which is the property that stops it
## trapping anything.
##
## In **metres** past the racing edge, which it did not used to be.
##
## It was 2.2 with the comment on SHOULDER_CURVE below claiming a 3m outer edge,
## and the two never agreed: `_section_norms` spends this in normalised `t` while
## `_section_point` converted with `over := (absolute - 1.0) * half_width`, so
## 2.2 bought 2.2 *half-widths*. At the course's widest that is 11.9m of shoulder
## rising 38m â a gorge, not a bank. Every tuning note above about marbles going
## over the side was written against a wall nothing could actually leave, and
## nothing outside it was ever going to be on camera.
##
## Metres cannot be the mesh's parameter, though: `_section_norms` needs the same
## node count in every row or the rows will not stitch where the width varies. So
## the normalised span stays, as `SHOULDER_T`, and this is the distance that span
## is mapped onto â constant in metres however wide the channel is, which the old
## formula was not either.
const SHOULDER := 3.0
## The shoulder's width in normalised `t`: purely a meshing quantity, how much of
## each section row is spent out past the racing surface. Unchanged from when
## `SHOULDER` was doing both jobs, so a row costs exactly the vertices and
## collider faces it always did.
const SHOULDER_T := 2.2
## How hard the shoulder steepens past the racing width, in metres of rise per
## metre squared. With `SHOULDER` at 3m this puts the outer edge about 4.3m up:
## triple the 1.4m that emptied the field, and low enough to see over.
const SHOULDER_CURVE := 0.23

# --- Surfaces -----------------------------------------------------------------

## The canyon runs fast stone against faster poured track. This inverts it: the
## default here is slow, and the fast surface is the exception. A course where
## the ground is working against you is a different feel from one where it is
## not, and it costs nothing but numbers.
const SURFACE_MOSS := {"friction": 0.52, "colour": Color(0.29, 0.35, 0.22)}
## Still the slowest ground on the course, but nothing like the 0.82 it started
## at. Every stall in this course's first day was on the mud or just past it: a
## sphere on a shallow, banked surface at that much friction stops being
## something the solver reliably keeps rolling, and it stops in the middle of the
## bowl where nothing can dislodge it. Slow is a feel; stuck is a bug, and the
## line between them is lower than it looks.
const SURFACE_MUD := {"friction": 0.55, "colour": Color(0.26, 0.21, 0.16)}
const SURFACE_WOOD := {"friction": 0.17, "colour": Color(0.38, 0.30, 0.21)}
const SURFACE_STONE := {"friction": 0.40, "colour": Color(0.34, 0.35, 0.31)}

const SURFACES := [
	[0.18, SURFACE_MOSS],
	[0.30, SURFACE_STONE],
	[0.44, SURFACE_MOSS],
	[0.56, SURFACE_MUD],  ## The wallow. The field arrives spread and leaves stacked.
	[0.72, SURFACE_WOOD], ## The hollow log: the fastest ground on the course.
	[0.86, SURFACE_MOSS],
	[1.00, SURFACE_STONE],
]

const BOUNCE := 0.12

# --- Features -----------------------------------------------------------------

## Buttress roots: a raised root down the middle that the field has to pick a
## side of. Same job as the canyon's divider island and a different shape â it is
## low enough to ride over if you arrive fast and high enough to turn you if you
## do not, so which side you come out is not purely where you went in.
const ROOT_AT := 0.22
const ROOT_LENGTH := 18.0
const ROOT_HEIGHT := 0.9
const ROOT_THICKNESS := 1.6

## Tree trunks standing in the channel, in the S-curve where the racing line
## already wants to cross. Fewer and fatter than the canyon's pillar rows.
## Placed where the channel is wide, which is now a real constraint rather than
## a preference: the second row used to sit at 0.58, and once `WIDTH` squeezed
## that to 2.9m for the equaliser the trunks left a 1.43m gap and the assertion
## refused to build the course. Obstacles and narrowings are the same tool, and
## stacking them is how a funnel becomes a wall.
## Rows are given a count and a lean, not positions.
##
## Fixed offsets were tried and abandoned. Once `WIDTH` varies, a row that fits
## at 6.2m blocks the course at 4.5m, and the smoothing means the width where a
## row actually lands is not the number written next to that fraction â three
## attempts at hand-placing them all tripped the assertion. Spacing the trunks
## evenly across whatever width is there makes them passable by construction, and
## `lean` shifts the whole row off centre so consecutive rows still stagger
## against each other rather than lining up.
const TRUNK_ROWS := [
	{"at": 0.40, "count": 2, "lean": -0.2},
	{"at": 0.46, "count": 2, "lean": 0.15},
	{"at": 0.86, "count": 2, "lean": 0.2},
]
const TRUNK_RADIUS := 0.8
const TRUNK_HEIGHT := 4.5
## Radius of the flared root the trunk stands on, and how tall that flare is.
##
## A vertical trunk on a dished floor is a marble trap and the geometry says so:
## a marble that loses its speed against one is being pushed into it by the only
## gradient available, and the trunk is blocking the single direction that could
## restart it. Nothing about the course can fix that, because the course is doing
## the right thing â the obstacle is the problem.
##
## A flare removes the vertical face at marble height. Anything that comes to
## rest against this is resting on a 24 degree slope instead, which pushes it
## sideways and out. The trunk above the flare can stay vertical; a marble is
## never up there at rest.
##
## It is what the canyon's pillars have as a decorative skirt, made load-bearing:
## there it is a mesh child and collides with nothing, which looks the same and
## does none of this.
const TRUNK_FLARE := 1.25
const TRUNK_FLARE_HEIGHT := 1.0
## Every gap a marble can be pushed into must clear this. A marble is 0.9m
## across; the canyon learned this the expensive way.
const MIN_GAP := 1.5

## Stepping stones. The canyon's failure mode is one committed jump; this is
## several small ones in a row, so it is a stretch you thread rather than a line
## you clear. Gaps are short enough that speed is not the only thing that saves
## you â where you are across the channel matters as much.
const STONES_AT := 0.70
## Short. There is no kicker here â the canyon throws you at its gap off a ramp,
## and these are simply holes in the floor taken at whatever speed you arrive
## with. At 2.3m the field did not clear them: ten of twelve went in, which makes
## the stones a filter rather than a hazard, and the survivors were decided
## before the stretch rather than during it.
## The jump: a ramp, then a hole.
##
## This is what the stepping stones needed and did not have. A hole in the floor
## with no ramp before it has no workable size â above about 1.4m the field does
## not clear it, below that a marble is wider than the gap and wedges in it, and
## the whole range sits inside a marble's own diameter. Crossing has to be a
## trajectory, not a roll off a ledge.
##
## The ramp is the channel floor lifting, not a slab standing on it. Nothing
## meets anything, so there is no crease and no seam â the lesson this course
## taught four separate times. It rises `KICKER_RISE` over `KICKER_LENGTH`, which
## against the 16 degree drop it sits on is still net downhill: a slow marble
## crawls over it rather than stalling on it, which a real ramp would not
## guarantee.
const KICKER_AT := 0.63
const KICKER_LENGTH := 6.0
const KICKER_RISE := 1.25
## Wide enough that it cannot be bridged, which is the constraint the stones
## could never satisfy: comfortably over a marble's 0.9m, so anything that does
## not fly it goes in.
const JUMP_GAP := 3.2
## Minimum speed the boost guarantees into the ramp. Sized against the gap: at
## this speed off a 0.65m ramp a marble carries comfortably past 2.4m, so the
## jump is something the course does *to* the field rather than a filter that
## selects whoever happened to arrive quickly.
const BOOST_SPEED := 13.0
##
## The idea is right â several small gaps to thread, against the canyon's one
## committed jump â but a hole in the floor with no ramp before it has no
## workable size. Above about 1.4m the field does not clear it: the marbles
## arrive off mud at eight or nine metres a second and nine of twelve go in,
## which makes the stretch a filter rather than a hazard. Below that a marble is
## wider than the gap, bridges it, and wedges â two races in four never finished.
## There is no window between those two because a marble is 0.9m across and the
## whole range is inside its own diameter.
##
## What it needs is what the canyon's jump has: something to leave the ground
## from, so crossing is a trajectory rather than a roll off a ledge. That is a
## real piece of work, not a constant, and the course races well without it â
## 12/12 finishing, no falls, no stalls. Filed rather than bodged.

## The spinning log â the one Phase 0 obstacle, in jungle clothes. Sits inside
## the hollow log section, where the channel is tight and there is no room to go
## round it.
const BUMPER_AT := 0.84
const LOG_OFFSET := -1.8


const LIP_COLOUR := Color(0.30, 0.26, 0.19)
const ROOT_COLOUR := Color(0.35, 0.28, 0.20)
const TRUNK_COLOUR := Color(0.27, 0.23, 0.18)
const CANOPY_COLOUR := Color(0.16, 0.24, 0.14)
const UNDERGROWTH_COLOUR := Color(0.20, 0.28, 0.17)
const FINISH_COLOUR := Color(0.92, 0.91, 0.86)
## Jungle floor, far below the stepping stones, so a gap reads as a drop into
## canopy rather than a hole cut in the level.
const FLOOR_BELOW := 22.0

# --- Landscape ----------------------------------------------------------------
#
# Scenery, all of it visual and none of it collidable â see `landscape.gd` for
# why that line is drawn hard, and for the camera arithmetic every number below
# is sized against.

## Fog colour, and the colour the sky is retinted to match. Warm green-grey
## rather than green: air over a forest is haze first and foliage second, and a
## saturated green fog turns every distant trunk into a silhouette of itself.
const HAZE_COLOUR := Color(0.46, 0.53, 0.44)
## Exponential, so there is no distance at which the world visibly ends.
##
## Halved from the first pass, which was set by the distance the fog needed to
## close and not by what it did on the way there. Closing at 160m meant the
## nearest trees were already milk, the marbles were sitting in haze at 30m, and
## the whole frame went one flat green. At this density the causeway and the
## trees beside it are unaffected, the far bank is softened, and the world still
## runs out before it runs out of mesh.
const FOG_DENSITY := 0.0062

## How far either side of the centreline the jungle floor is drawn. Past the fog
## close-out, deliberately: the floor has to run out of visibility rather than
## run out of mesh, and it is 10 quads wide however far it goes.
const FLOOR_EXTENT := 95.0
## Rows along the course, and columns either side of it. Coarse on purpose â this
## is ground 22m below the racing surface seen through fog, and its silhouette
## against the trees is doing all the work, not its resolution.
const FLOOR_STEP := 9.0
const FLOOR_COLUMNS := 10
## How far the columns bunch towards the track. 1 is even spacing; above that the
## near ground, which is the part actually in shot under the causeway, gets the
## vertices and the far ground coasts.
const FLOOR_BUNCH := 1.7
const FLOOR_RELIEF := 3.2

## How deep the causeway reads from the side, measured down from the centreline.
##
## This is the piece that stops the track being a ribbon. A surface with no
## underside is a decal on the air from any angle that can see past its edge, and
## the locked camera sees past both edges on every corner.
const SKIRT_DEPTH := 2.6

## Piers down to the jungle floor, which is the Trackmania trick: what reads as
## "floating" is not the absence of distant scenery, it is the absence of
## anything connecting the structure to the ground under it. Spacing is loose
## enough that they read as supports rather than as a wall.
const PIER_SPACING := 16.0
const PIER_RADIUS := 1.1
const PIER_FLARE := 2.2

## Trees, rooted on the jungle floor rather than on the course.
##
## The heights are the whole point of the section. Rooted 22m down, a tree has to
## clear about 30m before its crown reaches the ~8m band above the racing surface
## that the camera can still see, so the range straddles that: the short ones
## fill the flanks below the causeway and the tall ones are the only scenery that
## ever crosses the top of the frame.
const TREE_SPACING := 3.4
## Nearest and furthest a trunk stands from the centreline. The near limit clears
## the causeway skirt and its piers; nothing is gained by a tree inside them and
## a trunk intersecting the structure reads as a bug.
const TREE_NEAR := 12.0
const TREE_FAR := 88.0
const TREE_HEIGHT_MIN := 14.0
const TREE_HEIGHT_MAX := 38.0
## Shapes the height distribution. Above 1 most trees come out short and the tall
## ones are rare, which is what a forest looks like and what a uniform draw does
## not — evenly spread heights read as a planted field, and the emergents that
## are the only trees tall enough to cross the top of the frame stop being
## special because every third tree is one.
const TREE_HEIGHT_BIAS := 2.1
## Same, for how far out a tree stands: squared towards the causeway, so the
## flanks are dense where they are actually in shot and the far ground thins out
## into the fog rather than being uniformly stippled with trunks.
const TREE_LATERAL_BIAS := 1.9
## Fatter than the first pass, which paired thin stalks with wide flat crowns
## and produced mushrooms. Trunk mass against crown mass is most of what says
## "tree" at a distance where nothing else about it is resolvable.
const TREE_RADIUS_MIN := 0.8
const TREE_RADIUS_MAX := 2.2
## Crowns, as low-poly spheres at the top of every trunk. Sized generously: at
## 60m through fog a crown is a shape and a tone, and detail spent on it is detail
## spent below the noise floor.
##
## Two per tree, the second smaller and lower, because one ellipsoid on a stick
## is a lollipop from every angle and two overlapping ones are a silhouette with
## a bite out of it. It costs one extra instance in an existing draw call.
const CANOPY_RADIUS_MIN := 3.0
const CANOPY_RADIUS_MAX := 8.0
## How tall a crown is against its own spread. The first pass had this at 0.55,
## which is a disc; a rainforest crown is closer to as tall as it is wide.
const CANOPY_SQUASH := 0.82

## Low growth on the floor, which is what keeps the ground from reading as a
## sheet of painted cardboard between the trunks.
const UNDERSTORY_SPACING := 6.0
const UNDERSTORY_NEAR := 8.0

## Growth along the crest of the shoulder, and the only scenery on this course
## that the locked lens reliably has in frame.
##
## Worth stating plainly, because it is the opposite of where the effort wants to
## go. `Mode.LOW`'s lens is sized to the track (a 26 degree horizontal field at
## 30m spans about 13.8m, against a channel that is 12m wide across the
## shoulders), so at the focus there is no room either side for anything at all
## — the jungle floor, the piers and every trunk are outside the frame. What
## saves it is that the camera looks *up*-course: ground at the top of the frame
## is 60m or more from the lens and the same 26 degrees covers 27m there. So the
## verge is invisible beside the marbles and fills the upper third, which is the
## part of the shot that used to be sky.
##
## Sunk slightly into the shoulder so no clump shows its own base, and never
## given a collider — a marble thrown over the side passes through the leaves,
## which is the correct outcome and also the only affordable one.
const VERGE_SPACING := 2.4
const VERGE_LIFT := -0.4
## Clump size, smallest at the inner edge of the verge and largest at the crest.
##
## Not a flat random range, which is what the first pass had and it put 3.9m of
## foliage a metre outside the racing line: from a camera looking down the course
## the big clumps leaned over the channel and marbles went behind them. Section
## 2.5 wants twelve marbles readable at a glance, and scenery that occludes the
## field is worse than no scenery — the frame it improves is the one nobody is
## reading anyway.
##
## Tying size to distance out means the clumps nearest the track are small enough
## to sit under the sightline and the mass builds up where it cannot hurt.
const VERGE_SIZE_MIN := 0.7
const VERGE_SIZE_MAX := 2.4
## Where across the shoulder a clump sits, as a fraction of the shoulder past the
## racing edge. Never below 1: foliage on the racing surface is an obstacle that
## does not obstruct, which is worse than either a real one or none.
const VERGE_INNER := 1.25
const VERGE_OUTER := 1.0 + SHOULDER_T

## One seed, so a course built twice is the same course twice. Scenery drifting
## between a screenshot and the race it is supposed to document is a way to waste
## an afternoon.
const SCENERY_SEED := 0x5EED1E

var _path: CoursePath


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_channel()
	_build_landscape()
	_build_back_wall()
	_build_trunks()
	_build_log()
	_build_boost()
	_build_finish_line()


func _point(s: float) -> Vector3:
	return _path.point_at(s)


## `Course.frame_at` for a course laid out along a `CoursePath`.
##
## Camber comes from the path and the origin comes from the curve, rather than
## both from the path. The curve is a polyline through sampled points, so its
## arc length drifts against the path's by a metre or two over a course, and
## the offset handed in here was measured against the curve â by the camera,
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


func _at(fraction: float) -> Transform3D:
	return _frame_at(fraction * LENGTH)



func _surface_at(s: float) -> Dictionary:
	var fraction := s / LENGTH
	for entry: Array in SURFACES:
		if fraction <= entry[0]:
			return entry[1]
	return SURFACES[SURFACES.size() - 1][1]


# --- Channel ------------------------------------------------------------------


## The channel, generated as one surface per run.
##
## A "run" is a stretch with a single surface material and no hole in it, so the
## course is cut at every friction change and at every stepping-stone gap. Within
## a run the mesh is continuous â no joins, no seams, and nothing for a marble to
## catch on however hard the corner banks.
## How far a run reaches into its neighbour, so their meshes interpenetrate
## rather than meeting on a shared edge a marble can pass through.
const RUN_OVERLAP := 0.35


func _build_channel() -> void:
	for run: Dictionary in _runs():
		var from_s: float = run["from"] - (RUN_OVERLAP if run["lead"] else 0.0)
		var to_s: float = run["to"] + (RUN_OVERLAP if run["trail"] else 0.0)
		_build_run(from_s, to_s, run["surface"])


## The course split into stretches of constant surface with the gaps taken out.
func _runs() -> Array:
	# Every distance at which the surface has to be cut: band boundaries, the
	# ends of the course, and both sides of every gap.
	var cuts := [-RAMP_LENGTH, LENGTH + RUNOFF_LENGTH]
	for entry: Array in SURFACES:
		cuts.append(entry[0] * LENGTH)
	var holes := _stone_spans()
	for hole: Vector2 in holes:
		cuts.append(hole.x)
		cuts.append(hole.y)

	cuts.sort()

	var runs := []
	for i in range(cuts.size() - 1):
		var from_s: float = cuts[i]
		var to_s: float = cuts[i + 1]
		if to_s - from_s < 0.2:
			continue
		if _in_hole((from_s + to_s) * 0.5, holes):
			continue
		runs.append({
			"from": from_s,
			"to": to_s,
			"surface": _surface_at((from_s + to_s) * 0.5),
			# Runs are separate bodies and meet exactly, which is not good enough:
			# two trimeshes sharing an edge have no thickness between them, and a
			# marble arriving at the join goes through it. Every stepping stone
			# adds two more joins, which is why the stones were eating ten of
			# twelve marbles â they were not falling into the gaps, they were
			# falling through the edges of them.
			#
			# So runs reach into their neighbours. Not into the gaps, though:
			# extending a run into a hole would close the hole.
			"lead": not _touches_hole(from_s, holes),
			"trail": not _touches_hole(to_s, holes),
		})
	return runs


func _touches_hole(s: float, holes: Array) -> bool:
	for hole: Vector2 in holes:
		if absf(s - hole.x) < 0.01 or absf(s - hole.y) < 0.01:
			return true
	return false


func _in_hole(s: float, holes: Array) -> bool:
	for hole: Vector2 in holes:
		if s > hole.x and s < hole.y:
			return true
	return false


## Where the floor is missing, as `[start, end]` distances. One hole: the jump,
## immediately past the top of the kicker.
func _stone_spans() -> Array:
	var lip := KICKER_AT * LENGTH + KICKER_LENGTH
	return [Vector2(lip, lip + JUMP_GAP)]


## How much the floor is lifted by the kicker at `s`.
##
## Eased in and out rather than switched on, so the ramp grows out of the channel
## and settles back into it. The trailing ease matters as much as the leading
## one: it is what puts the lip at the top of a curve rather than at a corner, so
## a marble leaves along the surface it has been following instead of clipping an
## edge on the way off.
func _kicker_lift(s: float) -> float:
	var from_s := KICKER_AT * LENGTH
	var lip := from_s + KICKER_LENGTH
	var landing := lip + JUMP_GAP
	var settle := 6.0

	if s <= from_s:
		return 0.0
	if s < lip:
		# Squared, not smoothstepped. Smoothstep flattens at *both* ends, so the
		# last metre of ramp was parallel to the hillside it sits on and marbles
		# rolled off the lip travelling straight down the slope â a ramp that was
		# geometrically a ramp and did nothing whatsoever. A parabola is flat where
		# it meets the floor, which is the end that has to be smooth, and steepest
		# at the lip, which is the end that has to throw.
		#
		# The launch angle is therefore atan(2 * KICKER_RISE / KICKER_LENGTH) above
		# the local slope â the rise is not "how high", it is "how hard".
		var t := (s - from_s) / KICKER_LENGTH
		return KICKER_RISE * t * t
	# Past the gap the landing sinks back to the channel's own level. Left raised,
	# the ramp would lift every remaining metre of course with it and the marble
	# would be jumping *up* onto the far side.
	return KICKER_RISE * (1.0 - smoothstep(0.0, settle, s - landing))


## Where the section has a vertex, from left lip to right lip. Fixed, because
## every row of the mesh has to have the same number of nodes to be stitched to
## its neighbour â anything that varies along the course varies in *height*, at
## a node that is always there.
##
## The lips are section nodes rather than rails laid on top. So is the root
## ridge. Anything sitting *on* a surface has an edge where it meets, and on a
## course that turns, a run of boxes laid along the centreline leaves
## wedge-shaped gaps between consecutive chords on the inside of every corner â
## a marble found one and sat in it for the rest of the race. As section nodes
## they are simply places where the channel is higher.
## Spacing between section nodes, across the course.
##
## The first version placed them by hand and left 1.8m between them across the
## middle of the dish. That is not a curve, it is a set of flat panels meeting at
## angles, and a marble crossing the camber â which on a course that banks is
## most of what marbles do â bumps over every join. The field chattered the whole
## way down.
##
## Fine enough that the facet angle between neighbours is under two degrees
## anywhere on the dish. The cost is triangles in a static mesh, which is the
## cheapest thing in the scene.
const SECTION_STEP := 0.4


## Where the section has a vertex, as a fraction of the local half-width: -1 and
## +1 are the edges of the racing surface, beyond that is shoulder.
##
## Normalised rather than in metres, because the width now varies along the
## course and every row of the mesh still has to have the same number of nodes to
## be stitched to the next. In metres the node count would change with the width
## and the mesh would come apart exactly where the course gets interesting.
static func _section_norms() -> Array:
	var edge := 1.0 + SHOULDER_T
	var count := int(ceil(edge / SECTION_STEP))
	var norms := []
	for i in range(-count, count + 1):
		norms.append(clampf(float(i) * SECTION_STEP, -edge, edge))
	return norms


## Half-width of the racing surface at `s`.
func _half_width_at(s: float) -> float:
	return _path.sample(WIDTH, s)


## Depth of the dish at `s` â deeper through the log.
func _rise_at(s: float) -> float:
	var from_s := LOG_AT * LENGTH
	var to_s := from_s + LOG_LENGTH
	if s <= from_s or s >= to_s:
		return CHANNEL_RISE

	var ease_length := 5.0
	var inside := minf(
		smoothstep(0.0, ease_length, s - from_s),
		smoothstep(0.0, ease_length, to_s - s)
	)
	return CHANNEL_RISE + LOG_RISE * inside


## One section vertex, as `(lateral, lift)` in the local frame, for a normalised
## across-position `t` at distance `s`.
func _section_point(t: float, s: float) -> Vector2:
	var half_width := _half_width_at(s)
	var rise := _rise_at(s)
	var absolute := absf(t)
	var lift: float

	# Metres out past the racing edge, zero on the racing surface itself. Mapped
	# off `SHOULDER_T` rather than off `half_width`, so the shoulder is the same
	# 3m wide where the channel narrows to 3.7m as where it opens to 6.4m. Scaling
	# it by the width made the widest part of the course carry the tallest wall,
	# which is backwards: width is where the racing happens.
	var over := 0.0

	if absolute <= 1.0:
		lift = rise * absolute * absolute
	else:
		# Past the racing surface the same curve carries on, steepening. Continued
		# with the dish's own gradient at the join so the two halves meet with no
		# kink â a kink is a crease, and a crease on a banked course is a pocket.
		over = (absolute - 1.0) / SHOULDER_T * SHOULDER
		lift = rise + (2.0 * rise / half_width) * over + SHOULDER_CURVE * over * over

	# `over` carries magnitude only, so the side comes from `t`. On the racing
	# surface `over` is zero and this is the old `t * half_width` exactly.
	var lateral := signf(t) * (minf(absolute, 1.0) * half_width + over)
	return Vector2(lateral, lift + _root_lift(absf(lateral), s) + _kicker_lift(s))


## Height of the section at a lateral offset and distance, above the centreline.
## Monotonic in `abs(lateral)` outside the root, which is the property that
## matters: a section that rises all the way out has nowhere for a marble to
## settle except the middle.


## The buttress root, as a ridge in the middle of the channel: full height within
## half a metre of the centreline, tapering to nothing by 0.95m, and easing in
## and out along its length so it grows out of the floor rather than starting as
## a step. A marble arriving fast rides over it; one arriving slowly is turned by
## it. Which side you come out is decided by which side you were already on,
## which is what `DECISIONS.md` requires of a split.
func _root_lift(absolute_lateral: float, s: float) -> float:
	var from_s := ROOT_AT * LENGTH
	var to_s := from_s + ROOT_LENGTH
	if s <= from_s or s >= to_s or absolute_lateral >= 0.95:
		return 0.0

	var ease_length := 4.5
	var along := minf(
		smoothstep(0.0, ease_length, s - from_s),
		smoothstep(0.0, ease_length, to_s - s)
	)
	var across := 1.0 - smoothstep(0.5, 0.95, absolute_lateral)
	return ROOT_HEIGHT * along * across


## One continuous stretch of channel: an ArrayMesh for the look and a matching
## trimesh collider for the physics, both generated from the same vertex rows so
## they cannot disagree.
func _build_run(from_s: float, to_s: float, surface: Dictionary) -> void:
	var section := _section_norms()

	var rows := []
	var s := from_s
	while s < to_s - 0.01:
		rows.append(_section_row(s, section))
		s = minf(s + MESH_STEP, to_s)
	rows.append(_section_row(to_s, section))

	if rows.size() < 2:
		return

	var faces := PackedVector3Array()
	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(section.size() - 1):
			# Wound so the normals face up out of the channel; a trimesh with its
			# normals inverted is a floor marbles fall through.
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
	# Front faces only. Colliding from behind sounds like the safe choice and is
	# the opposite: a marble thrown over the lip in a corner came to rest against
	# the *underside* of the channel and sat there for the rest of the race, still
	# officially racing, because there was something solid under it. Off, a marble
	# that leaves the course keeps falling until the fall threshold collects it,
	# which is what leaving the course is supposed to mean.
	shape.backface_collision = false
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _surface_look(surface["colour"])
	body.add_child(visual)

	add_child(body)


## One row of section vertices in world space, at distance `s`.
func _section_row(s: float, section: Array) -> Array:
	var frame := _frame_at(s)
	var row := []
	for t: float in section:
		var node := _section_point(t, s)
		row.append(frame * Vector3(node.x, node.y, 0.0))
	return row


## A box laid along the course between two distances, offset in the local frame
## and rolled about the direction of travel, hanging below the surface point.
func _add_rolled_box(
	from_s: float,
	to_s: float,
	lateral: float,
	lift: float,
	roll: float,
	section: Vector2,
	colour: Color,
	friction := -1.0
) -> void:
	var span := to_s - from_s
	if span < 0.01:
		return

	# Placed from the segment's midpoint rather than built between two endpoints,
	# because on a banked turn the two frames differ in roll as well as position
	# and there is no single box that has both as faces. At this segment length
	# the difference is under the marble radius.
	var mid := (from_s + to_s) * 0.5
	var frame := _frame_at(mid)
	frame = frame.translated_local(Vector3(lateral, lift, 0.0))
	frame = frame.rotated_local(Vector3.BACK, roll)
	frame = frame.translated_local(Vector3(0.0, -section.y * 0.5, 0.0))

	_add_box(frame, Vector3(section.x, section.y, span), colour, friction)



# --- Landscape ----------------------------------------------------------------


## The world the causeway runs through, in the order it matters: the ground
## below, then the structure holding the track up over it, then what grows on it.
func _build_landscape() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED

	_build_floor()
	_build_skirt()
	_build_piers()
	_build_forest(rng)
	_build_verge(rng)


## An unrolled frame at `s`: the position and heading of the course, with the
## camber taken out and `Y` left pointing at the sky.
##
## Scenery cannot use `_frame_at` directly. That frame banks with the corners,
## which is right for anything sitting on the racing surface and wrong for
## everything else â hung off it, the jungle floor tilts twenty degrees through
## the S-curve and the trees lean with it.
##
## Also defined outside the range of the path, by walking along the heading of
## the end frame, so the floor and the trees carry on past both ends of the
## course. Fog closes them out long before the extrapolation goes anywhere
## interesting.
func _ground_frame(s: float) -> Transform3D:
	var last := LENGTH + RUNOFF_LENGTH
	var clamped := clampf(s, -RAMP_LENGTH, last)
	var frame := _frame_at(clamped)

	var forward := -frame.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var origin := frame.origin + forward * (s - clamped)

	var backward := -forward
	var right := Vector3.UP.cross(backward).normalized()
	return Transform3D(Basis(right, Vector3.UP, backward), origin)


## Height of the jungle floor at a point, relative to the course beside it.
func _floor_point(s: float, lateral: float) -> Vector3:
	var frame := _ground_frame(s)
	var lift := -FLOOR_BELOW + Landscape.relief(s, lateral, FLOOR_RELIEF)
	return frame * Vector3(lateral, lift, 0.0)


## Lateral offsets of one floor row, bunched towards the track.
func _floor_columns() -> Array:
	var columns := []
	for i in range(-FLOOR_COLUMNS, FLOOR_COLUMNS + 1):
		var t := float(i) / float(FLOOR_COLUMNS)
		columns.append(signf(t) * pow(absf(t), FLOOR_BUNCH) * FLOOR_EXTENT)
	return columns


## Where the scenery starts and stops. Well past the course at both ends: at the
## start line the camera is looking up a course that does not exist yet, and the
## run-out is the flattest ground here and therefore the one place the lens can
## reach the horizon.
func _scenery_span() -> Vector2:
	return Vector2(-RAMP_LENGTH - 60.0, LENGTH + RUNOFF_LENGTH + 90.0)


func _build_floor() -> void:
	var span := _scenery_span()
	var columns := _floor_columns()

	var rows := []
	var s := span.x
	while s < span.y:
		rows.append(_floor_row(s, columns))
		s += FLOOR_STEP
	rows.append(_floor_row(span.y, columns))

	add_child(
		Landscape.stitch(
			rows,
			Landscape.detail_material(
				UNDERGROWTH_COLOUR, CANOPY_COLOUR.darkened(0.15), 0.028, 0.3, 0.45
			),
			"JungleFloor"
		)
	)


func _floor_row(s: float, columns: Array) -> Array:
	var row := []
	for lateral: float in columns:
		row.append(_floor_point(s, lateral))
	return row


## The flanks and underside of the causeway.
##
## Built from the outer edge of the channel down to a flat sole below the
## centreline, so the earth the track is cut into gets thicker as the shoulder
## climbs â which is what a real causeway looks like and, more usefully, means
## the silhouette from the side is the silhouette of the section rather than of
## a slab.
func _build_skirt() -> void:
	var section := _section_norms()
	var outer: float = section[section.size() - 1]

	var rows := []
	var s := -RAMP_LENGTH
	while s < LENGTH + RUNOFF_LENGTH:
		rows.append(_skirt_row(s, outer))
		s += MESH_STEP * 3.0
	rows.append(_skirt_row(LENGTH + RUNOFF_LENGTH, outer))

	var node := Landscape.stitch(
		rows,
		Landscape.detail_material(LIP_COLOUR, ROOT_COLOUR.darkened(0.35), 0.05, 0.5, 0.2),
		"CausewaySkirt"
	)
	# One winding is enough: the profile is traversed in a single rotational
	# direction (outer edge, down, across the sole, back up), so the flanks and the
	# sole share a consistent outward normal rather than needing a two-sided
	# material. `ShaderMaterial` has no `cull_mode` anyway — culling is a
	# `render_mode` on the shader, and disabling it there would cost the channel.
	add_child(node)


## One skirt row: down the left flank, across the sole, up the right flank.
func _skirt_row(s: float, outer: float) -> Array:
	var frame := _frame_at(s)
	var left := _section_point(-outer, s)
	var right := _section_point(outer, s)
	var sole := -SKIRT_DEPTH

	return [
		frame * Vector3(left.x, left.y, 0.0),
		frame * Vector3(left.x * 0.92, sole, 0.0),
		frame * Vector3(right.x * 0.92, sole, 0.0),
		frame * Vector3(right.x, right.y, 0.0),
	]


func _build_piers() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = PIER_RADIUS
	mesh.bottom_radius = PIER_FLARE
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 1

	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []

	var s := -RAMP_LENGTH + 4.0
	while s < LENGTH + RUNOFF_LENGTH:
		var head := _frame_at(s).origin - Vector3.UP * SKIRT_DEPTH
		var foot := _floor_point(s, 0.0)
		var height := head.y - foot.y
		if height > 1.0:
			transforms.append(
				Transform3D(
					Basis.IDENTITY.scaled(Vector3(1.0, height, 1.0)),
					Vector3(head.x, foot.y + height * 0.5, head.z)
				)
			)
			colours.append(ROOT_COLOUR.darkened(fmod(s * 0.037, 0.25)))
		s += PIER_SPACING

	var node := Landscape.scatter(mesh, transforms, colours, "Piers")
	node.material_override = Landscape.instance_material()
	add_child(node)


## Leaf clumps along both shoulder crests. One draw call; no colliders.
func _build_verge(rng: RandomNumberGenerator) -> void:
	var clump := SphereMesh.new()
	clump.radius = 1.0
	clump.height = 2.0
	clump.radial_segments = 6
	clump.rings = 3

	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []

	var s := -RAMP_LENGTH
	var last := LENGTH + RUNOFF_LENGTH

	while s < last:
		for side: float in [-1.0, 1.0]:
			# Skipped rather than thinned, so the gaps land in different places on
			# the two sides and the verge does not read as a pair of hedges.
			if rng.randf() < 0.22:
				continue

			var at := clampf(s + rng.randf_range(-VERGE_SPACING, VERGE_SPACING), -RAMP_LENGTH, last)
			var t := side * rng.randf_range(VERGE_INNER, VERGE_OUTER)
			var node := _section_point(t, at)

			var out := inverse_lerp(VERGE_INNER, VERGE_OUTER, absf(t))
			var size := lerpf(VERGE_SIZE_MIN, VERGE_SIZE_MAX, out) * rng.randf_range(0.8, 1.15)
			transforms.append(
				Transform3D(
					Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3(size * 1.35, size * rng.randf_range(0.5, 0.95), size * 1.35)
					),
					_frame_at(at) * Vector3(node.x, node.y + VERGE_LIFT, 0.0)
				)
			)
			colours.append(
				UNDERGROWTH_COLOUR.lerp(CANOPY_COLOUR, rng.randf()).lightened(
					rng.randf_range(0.06, 0.38)
				)
			)

		s += VERGE_SPACING

	var mesh_node := Landscape.scatter(clump, transforms, colours, "Verge")
	mesh_node.material_override = Landscape.instance_material()
	add_child(mesh_node)


## Trunks, crowns and low growth, as three draw calls total.
func _build_forest(rng: RandomNumberGenerator) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.62
	trunk.bottom_radius = 1.0
	trunk.height = 1.0
	trunk.radial_segments = 6
	trunk.rings = 1

	var crown := SphereMesh.new()
	crown.radius = 1.0
	crown.height = 2.0
	crown.radial_segments = 7
	crown.rings = 4

	var scrub := SphereMesh.new()
	scrub.radius = 1.0
	scrub.height = 2.0
	scrub.radial_segments = 5
	scrub.rings = 3

	var trunks: Array[Transform3D] = []
	var trunk_colours: Array[Color] = []
	var crowns: Array[Transform3D] = []
	var crown_colours: Array[Color] = []
	var scrubs: Array[Transform3D] = []
	var scrub_colours: Array[Color] = []

	var span := _scenery_span()
	var s := span.x

	while s < span.y:
		for side: float in [-1.0, 1.0]:
			var lateral := side * lerpf(
				TREE_NEAR, TREE_FAR, pow(rng.randf(), TREE_LATERAL_BIAS)
			)
			var at := s + rng.randf_range(-TREE_SPACING, TREE_SPACING)
			var root := _floor_point(at, lateral)

			var height := lerpf(
				TREE_HEIGHT_MIN, TREE_HEIGHT_MAX, pow(rng.randf(), TREE_HEIGHT_BIAS)
			)
			var radius := lerpf(
				TREE_RADIUS_MIN,
				TREE_RADIUS_MAX,
				inverse_lerp(TREE_HEIGHT_MIN, TREE_HEIGHT_MAX, height)
			)

			# Yaw only. A leaning trunk needs its crown leant with it and its base
			# sunk to hide the heel, and neither is worth it for a shape read
			# through fog â where the lean would show is where the fog is.
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))

			trunks.append(
				Transform3D(
					basis.scaled(Vector3(radius, height, radius)),
					root + Vector3.UP * (height * 0.5)
				)
			)
			trunk_colours.append(TRUNK_COLOUR.lightened(rng.randf_range(0.0, 0.22)))

			var spread := lerpf(
				CANOPY_RADIUS_MIN,
				CANOPY_RADIUS_MAX,
				inverse_lerp(TREE_HEIGHT_MIN, TREE_HEIGHT_MAX, height)
			)
			# The main crown sits below the top of the trunk rather than on it, so
			# the trunk shows through the foliage instead of stopping at it.
			var tone := CANOPY_COLOUR.lightened(rng.randf_range(0.0, 0.18))
			crowns.append(
				Transform3D(
					basis.scaled(Vector3(spread, spread * CANOPY_SQUASH, spread)),
					root + Vector3.UP * (height * 0.88)
				)
			)
			crown_colours.append(tone)

			var lower := spread * rng.randf_range(0.5, 0.75)
			crowns.append(
				Transform3D(
					Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3(lower, lower * CANOPY_SQUASH, lower)
					),
					root
						+ Vector3.UP * (height * rng.randf_range(0.66, 0.78))
						+ basis.x * (spread * rng.randf_range(0.3, 0.6))
				)
			)
			crown_colours.append(tone.darkened(rng.randf_range(0.08, 0.26)))

			var bush := rng.randf_range(1.1, 2.8)
			var bush_at := _floor_point(
				s + rng.randf_range(-UNDERSTORY_SPACING, UNDERSTORY_SPACING),
				side * rng.randf_range(UNDERSTORY_NEAR, TREE_FAR)
			)
			scrubs.append(
				Transform3D(
					Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3(bush * 1.6, bush * 0.5, bush * 1.6)
					),
					bush_at
				)
			)
			scrub_colours.append(UNDERGROWTH_COLOUR.lightened(rng.randf_range(0.0, 0.26)))

		s += TREE_SPACING

	var material := Landscape.instance_material()

	for entry: Array in [
		[trunk, trunks, trunk_colours, "Trunks"],
		[crown, crowns, crown_colours, "Crowns"],
		[scrub, scrubs, scrub_colours, "Understory"],
	]:
		var node := Landscape.scatter(entry[0], entry[1], entry[2], entry[3])
		node.material_override = material
		add_child(node)


func _build_back_wall() -> void:
	_add_box(
		_frame_at(-RAMP_LENGTH).translated_local(Vector3(0.0, 1.1, 0.4)),
		Vector3(HALF_WIDTH * 2.0, 2.2, 0.8),
		ROOT_COLOUR.darkened(0.3)
	)


# --- Features -----------------------------------------------------------------




func _build_trunks() -> void:
	for row: Dictionary in TRUNK_ROWS:
		var s: float = row["at"] * LENGTH
		for offset: float in _trunk_offsets(s, row["count"], row["lean"]):
			_add_trunk(s, offset)


## Evenly spaced trunk positions across the channel at `s`, leaving equal gaps
## between them and the two edges, then leant to one side.
##
## `lean` is a fraction of one gap, so leaning can never eat a gap entirely â it
## takes from one side and gives to the other, and the assertion below still has
## the final say.
func _trunk_offsets(s: float, count: int, lean: float) -> Array:
	var half_width := _half_width_at(s)
	# Measured against the flare, not the trunk: the flare is what a marble meets
	# at floor level, and spacing to the narrower shaft would leave gaps that only
	# exist above the field.
	var gap := (half_width * 2.0 - count * TRUNK_FLARE * 2.0) / float(count + 1)
	_assert_gap(gap - absf(lean) * gap, "trunk row at %.2f" % (s / LENGTH))

	var offsets := []
	for i in count:
		var centre := -half_width + gap * float(i + 1) + TRUNK_FLARE * float(i * 2 + 1)
		offsets.append(centre + lean * gap * 0.5)
	return offsets




func _assert_gap(gap: float, what: String) -> void:
	assert(
		gap >= MIN_GAP,
		"%s leaves %.2fm, under MIN_GAP (%.2fm); marbles wedge." % [what, gap, MIN_GAP]
	)


func _add_trunk(s: float, offset: float) -> void:
	var lift := _section_point(offset / _half_width_at(s), s).y
	var body := StaticBody3D.new()
	body.transform = _frame_at(s).translated_local(
		Vector3(offset, lift + TRUNK_HEIGHT * 0.5, 0.0)
	)
	body.physics_material_override = _surface_material()

	var shape := CylinderShape3D.new()
	shape.radius = TRUNK_RADIUS
	shape.height = TRUNK_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := CylinderMesh.new()
	mesh.top_radius = TRUNK_RADIUS * 0.88
	mesh.bottom_radius = TRUNK_RADIUS
	mesh.height = TRUNK_HEIGHT
	mesh.radial_segments = 8
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(TRUNK_COLOUR)
	body.add_child(visual)

	_add_flare(body, lift)
	add_child(body)


## The flared root, as a real collider rather than decoration. A convex hull off
## a tapered cylinder, because Godot has no cone shape and a stack of cylinders
## would reintroduce the steps this course has spent all day removing.
func _add_flare(body: StaticBody3D, lift: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = TRUNK_RADIUS
	mesh.bottom_radius = TRUNK_FLARE
	mesh.height = TRUNK_FLARE_HEIGHT
	mesh.radial_segments = 10

	# Positioned relative to the trunk's own centre, which sits half a trunk above
	# the surface â so the flare's base lands on the floor.
	var at := Vector3(
		0.0, -TRUNK_HEIGHT * 0.5 + TRUNK_FLARE_HEIGHT * 0.5, 0.0
	)

	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_convex_shape()
	collider.position = at
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(ROOT_COLOUR)
	visual.position = at
	body.add_child(visual)


## The boost, sitting on the approach to the kicker rather than on it.
##
## Before the ramp, so a marble is already up to speed when the ground starts
## tilting: on the ramp it would be adding speed to something already committed
## to a trajectory, which is how a launch turns into a marble fired over the
## landing entirely.
func _build_boost() -> void:
	var at := KICKER_AT * LENGTH - 3.0
	var frame := _frame_at(at)
	var pad := BoostPad.create(
		_half_width_at(at) * 2.0,
		-frame.basis.z, ## Local -Z is down-course.
		BOOST_SPEED
	)
	pad.transform = frame.translated_local(Vector3(0.0, 1.2, 0.0))
	add_child(pad)


func _build_log() -> void:
	var bumper := RotatingBumper.create()
	var s := BUMPER_AT * LENGTH
	var lift := _section_point(LOG_OFFSET / _half_width_at(s), s).y
	bumper.transform = _frame_at(s).translated_local(Vector3(LOG_OFFSET, lift, 0.0))
	add_child(bumper)




func _build_finish_line() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = FINISH_COLOUR
	material.roughness = 0.9

	var mesh := BoxMesh.new()
	mesh.size = Vector3(HALF_WIDTH * 2.0, 0.06, 1.0)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.transform = _frame_at(LENGTH).translated_local(Vector3(0.0, 0.04, 0.0))
	add_child(visual)

	# The kerb closing the run-out. Was a 2.4m wall six metres past the line, and
	# it was what actually stopped a race: cross, roll, hit wall. `FinishZone`
	# has taken nearly all of a finisher's speed by the time it reaches this, so
	# it catches a slow roll rather than ending a race â and it is low enough not
	# to stand up in front of the field the camera is watching arrive.
	_add_box(
		_frame_at(LENGTH + RUNOFF_LENGTH - 1.2).translated_local(Vector3(0.0, 0.35, 0.0)),
		Vector3(HALF_WIDTH * 2.0, 0.7, 0.6),
		ROOT_COLOUR.darkened(0.3)
	)


# --- Helpers ------------------------------------------------------------------


func _surface_material(friction := -1.0) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = SURFACE_MOSS["friction"] if friction < 0.0 else friction
	material.bounce = BOUNCE
	return material


## The look of the racing surface, as opposed to `_material`, which is still what
## every prop and fixture uses.
##
## The channel is one generated mesh per surface run, with no UVs and no way to
## sensibly author them for something that banks and changes width, so the
## variation has to come from world space. It also has to agree with the jungle
## floor 22m below, which is a different mesh entirely â and does, because both
## sample the same noise at the same world coordinates.
##
## Kept a per-call material rather than a shared one: each run passes its own
## surface colour, and mud reading as moss would undo the point of `SURFACES`.
func _surface_look(colour: Color) -> ShaderMaterial:
	return Landscape.detail_material(colour, colour.darkened(0.4), 0.115, 0.85, 0.28)


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
	body.physics_material_override = _surface_material(friction)

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


## Fog, and a sky retinted to match it.
##
## Fog is the whole backdrop on this course, not an atmospheric garnish. The
## locked camera cannot see the horizon except over the flattest ground, so there
## is no skybox to fade into and nowhere to hide the edge of the world; without
## this the run-out is a slab of track over an empty grey-blue plate, which is
## what the course looked like before any of the scenery below it existed.
##
## Exponential rather than depth-ranged. A depth fog has a near and a far and the
## far is a visible boundary â trees crossing it pop from lit to flat â whereas an
## exponential curve has no distance at which anything happens.
##
## The sky is retinted even though it is almost never in frame. Almost is the
## problem: the run-out flattens out and the top of the lens catches the horizon
## exactly where the field is being watched across the line, and a desert horizon
## band over a jungle is worse for showing up rarely, not better.
func decorate_environment(environment: Environment, sun: DirectionalLight3D) -> void:
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = HAZE_COLOUR
	environment.fog_density = FOG_DENSITY
	# Low. Scatter puts the colour of the sun into the fog around it, which on a
	# course lit from almost overhead means a bright patch in the middle of the
	# distance rather than anywhere near a sun.
	environment.fog_sun_scatter = 0.08
	environment.fog_aerial_perspective = 0.4

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = HAZE_COLOUR.darkened(0.25)
	sky_material.sky_horizon_color = HAZE_COLOUR.lightened(0.12)
	sky_material.ground_horizon_color = HAZE_COLOUR.lightened(0.06)
	sky_material.ground_bottom_color = UNDERGROWTH_COLOUR.darkened(0.3)

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky

	# Down from the pool's 0.95. That number was chosen to fill a grey canyon and
	# it is ambient *from the sky*, so retinting the sky green turned it into a
	# green floodlight with no direction in it — every trunk, crown and bank came
	# out the same value and the forest read as one mass. Marble legibility is
	# what sets the floor here, and it still has the sun.
	environment.ambient_light_energy = 0.72

	# Warmed and very slightly greened, as light through a canopy is, and left at
	# the pool's angle and energy. Section 2.5 wants twelve marbles readable at a
	# glance and the sun is what makes them legible against ground this dark;
	# dimming it for mood is the one change here that would cost gameplay.
	sun.light_color = Color(1.0, 0.98, 0.9)


func fall_threshold_y() -> float:
	return _point(LENGTH).y - 18.0


func finish_width() -> float:
	return HALF_WIDTH * 2.0


func finish_runoff() -> float:
	return RUNOFF_LENGTH


func start_width() -> float:
	return HALF_WIDTH * 2.0


## Five across rather than the canyon's six: the channel is narrower and its
## edges are curved, so a marble spawned hard against the side starts halfway up
## the camber.
func get_spawn_transforms(count: int, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var spawns: Array[Transform3D] = []
	var per_row := 5
	var spacing := 1.7

	for i in count:
		var row := i / per_row
		var column := i % per_row
		var x := (float(column) - float(per_row - 1) * 0.5) * spacing
		var back := 2.5 + float(row) * spacing

		x += rng.randf_range(-0.12, 0.12)
		back += rng.randf_range(-0.12, 0.12)

		spawns.append(
			Transform3D(
				Basis.IDENTITY,
				_frame_at(-back) * Vector3(x, _section_point(x / _half_width_at(-back), -back).y + 0.9, 0.0)
			)
		)

	return spawns
