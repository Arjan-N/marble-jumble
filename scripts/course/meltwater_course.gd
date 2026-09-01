class_name MeltwaterCourse
extends Course

## Meltwater Channel — a runnel cut into the surface of a glacier by its own
## summer melt, and the second course built on `TerrainShell`.
##
## `docs/COURSE_RECIPE.md` is the brief. `JungleRiverCourse` proved the trench —
## one continuous surface from far ground down the bank across the bed and up the
## other side, no edge anywhere for the eye to read as "the track stops here" —
## and this is the second theme through it, which is the thing `terrain_shell.gd`
## says it was written to test. The formation story is deliberately the same as
## the river's: water cut this, and the bank is the cut.
##
## ## What is new here
##
## **A fast line made of surface, not shape.** Every course in the pool so far
## has one friction. This one has two: `TerrainShell.centre_friction` puts
## polished ice down the middle of the bed and wind-packed snow on the margins,
## so being shoved wide is a cost even where the course is straight. Camber makes
## a racing line out of *shape*; this makes one out of *material*, and the two
## compose — the sweeper at 0.52-0.70 is banked ice with snow either side, where
## holding the high line and holding the fast surface are the same problem.
##
## The visual split (`centre_fraction`) and the physical one are set to agree.
## They have to: a friction change the player cannot see is one they can only
## learn by losing.
##
## **Ice that is not white.** `IceKit`'s header argues this at length and it is
## the other half of the brief. Short version: `GlacierFaultCourse` renders
## between 0.72 and 0.98 luminance with nothing darker than anything else, which
## is not "too blue" but too evenly lit. Wet channel ice is *dark* — `ICE_DEEP`
## is darker than the jungle's mud — the cut bank face is the most saturated
## thing in frame, glaciers are full of near-black silt, and snow is the rarest
## colour here rather than the ground note. The value range runs 0.13 to 0.80.
##
## ## Route
##
## ```text
##  spillway   ice     cryoconite   serac gate    banked      crevasse   firn    winding
##   opening  island     narrows    + icefall    sweeper        jump      basin  + finish
##      |        |          |           |           |             |         |       |
##  0.00 --- 0.17 --- 0.26-0.38 ---- 0.44 ---- 0.52-0.70 ------ 0.76 --- 0.88 --- 1.00
## ```
##
## Eight features against the river's eight, and one of them moves: the serac
## wall calves ice across the gate. That is the one deliberate answer to "the
## river has no obstacles" — and it is `FallingRock`, the body Volcano already
## uses, because a glacier that drops ice on you is diegetic where a rotating
## bumper on an icefield would be exactly the bolted-on fixture
## `docs/COURSE_RECIPE.md` R7 argues against.
##
## ## Not in `COURSE_POOL` yet
##
## Deliberately. It has never been run — the environment it was written in has no
## Godot binary, so nothing here has been compiled, let alone raced. Every number
## below is reasoned from `docs/COURSE_RECIPE.md` and from the river's recorded
## findings, which is exactly the state `GlacierFaultCourse` shipped in and the
## reason that course is still carrying a "revert before shipping" comment.
##
## Before it goes in the pool:
##
## 1. `MJ_COURSE=meltwater godot --headless --path . res://tools/probe_course.tscn
##    --fixed-fps 60 --disable-render-loop --quit-after 9000` — 420m at this pitch
##    needs a longer budget than the pool's usual 4800.
## 2. Then the same through `race_manager` with a **round-three field of three**.
##    The river's narrows stall was invisible to a fixed-seed probe and only
##    appeared with nobody behind to push; the narrows here are the same feature
##    built to the same shape, so they are the first place to look.
## 3. Then `MJ_COURSE=meltwater ... res://tools/course_shot.tscn` at each station,
##    because the palette is the half of this that cannot be probed at all.
##
## ## Two departures, both flagged
##
## **Length.** 420m, against the river's 380 and the pool's 130-205.
## `DECISIONS.md` still locks 20-30 seconds per course and two courses now
## disagree with it; the river's header raised this and it is still unresolved.
## Asked for explicitly ("not too short"), so built that way, but the decision
## outlives this file.
##
## **The crevasse does not eliminate.** Same call the river made about its
## stream, for the same reason and with less comfort: a 3m gap that kills is a
## coin flip on entry speed rather than racing. The floor is meltwater and slush,
## the far wall is a ramp obeying the river's own exit rule, and a marble that
## comes up short climbs out having lost everything it had. On a course whose
## whole conceit is that surface decides the race, losing your speed *is* the
## penalty.

# --- Shape --------------------------------------------------------------------

const LENGTH := 420.0
const RAMP_LENGTH := 14.0
const RUNOFF_LENGTH := 32.0

## Feature positions as fractions of `LENGTH`, named because the profiles, the
## fixtures and the scenery all reference them. Three copies of 0.44 in three
## tables is how a feature and its dressing drift apart.
const ISLAND_AT := 0.17
## The braid. The channel splits around the ice island and runs as two lanes
## until it closes again ahead of the narrows.
##
## `FORK_FROM` is where the bed starts widening to carry two lanes, not where the
## split begins — the island at `ISLAND_AT` is the fork head, and the ridge grows
## out of its down-course face.
const FORK_FROM := 0.15
const FORK_TO := 0.225
const NARROW_FROM := 0.26
const NARROW_TO := 0.38
const GATE_AT := 0.44
const ICEFALL_FROM := 0.41
const ICEFALL_TO := 0.50
const BEND_FROM := 0.52
const BEND_TO := 0.70
const CREVASSE_AT := 0.76
const BASIN_TO := 0.88

## Shallower than the river throughout, and that is a consequence of the ice
## rather than a style choice. At 0.11 friction down the centre a marble slides
## where the river's marbles rolled, and a grade that produced 26 seconds on mud
## produces a course that arrives at the first corner already out of control.
##
## Floor of 7.0, held there rather than dropped to match the gentler feel,
## because the margins are snow at 0.30 and the river's note applies to them
## exactly: "nothing may be shallow enough to hold a marble that arrives slowly",
## and a marble that has been pushed onto the snow *is* the marble arriving
## slowly. The floor is set by the slowest surface on the course, not the fastest.
const PITCH := [
	[0.05, 8.5],   ## Off the ramp into the channel.
	[0.13, 7.0],   ## The spillway, deliberately unhurried.
	[0.22, 8.0],   ## Rolling down at the island.
	[NARROW_FROM, 8.5],
	[NARROW_TO, 7.5],   ## Narrows — slow, so the shards are a nuisance not a wreck.
	[GATE_AT, 9.0],     ## Run at the gate.
	[BEND_FROM, 7.5],
	[BEND_TO, 7.0],     ## The sweeper, held right back.
	[0.745, 10.5],      ## Released at the crevasse.
	[0.80, 8.0],
	[BASIN_TO, 7.0],    ## The basin.
	[0.97, 7.5],        ## Winding.
	[1.00, 10.5],       ## Sprint to the line.
]

## Absolute bearing in degrees, positive turning right.
##
## A drift right through the narrows, one long sweeping **left**-hander — the
## river's sweeper turns right, and two flagship corners the same way would make
## the two courses feel like one course — and an S onto the line.
##
## Every step is 15m of course or more, holding the turn rate under 0.6 degrees
## per metre. That is the figure every course here that races cleanly stays
## below, and the figure above which `CoursePath`'s smoothing window stops being
## wide enough to turn a step into a ramp.
const HEADING := [
	[0.20, 0.0],
	[0.26, 4.0],
	[0.32, 8.0],    ## Into the narrows.
	[0.40, 8.0],
	[GATE_AT, 5.0],
	[0.50, -2.0],
	[0.54, -10.0],
	[0.58, -18.0],
	[0.62, -25.0],
	[0.66, -30.0],
	[BEND_TO, -32.0],  ## The sweeper, at its tightest.
	[0.78, -32.0],     ## Straight through the crevasse.
	[0.82, -26.0],
	[0.86, -17.0],
	[0.90, -8.0],
	[0.93, -1.0],
	[0.96, 5.0],       ## Last flick the other way.
	[0.99, 1.0],
	[1.00, 0.0],
]

## Authored camber, added to whatever `CoursePath` derives from the turn rate.
##
## Same argument the river's `ROLL` makes: `BANK_GAIN` is 6 degrees of camber per
## degree-per-metre of turn, so a corner turning at the 0.6 the geometry allows
## arrives at 3.6 degrees, which is a cross-fall rather than a bank. Seventeen on
## top puts the sweeper near 21.
##
## It matters more here than it did there. On mud, camber decides which line is
## shorter; on ice it decides which line a marble can *hold at all*, and a marble
## that slides off the banked centre lands on snow and stops being in the race.
## This corner is the course's whole thesis in one feature.
##
## Negative because the turn is left: camber rolls the bed towards the inside of
## the corner, and `CoursePath` reads positive roll as a right-hander's bank.
##
## Eased out and level again before the crevasse, twenty metres early. The river
## records what happens otherwise — its ease-out ran into the take-off lip, whose
## net grade is near level, and a near-level stretch under twelve degrees of
## camber is where a slow marble settles against the low side and stays. A jump
## wants to be entered flat.
const ROLL := [
	[0.50, 0.0],
	[0.54, -6.0],
	[0.58, -13.0],
	[0.62, -17.0],
	[BEND_TO, -17.0],
	[0.72, -9.0],
	[0.745, -1.0],   ## Level for the crevasse.
	[0.80, 0.0],
	[1.00, 0.0],
]

## Half-width of the flat racing bed.
##
## Never below 3.6. Two marbles abreast is 1.8m and the Canyon's field died in a
## 2.0m squeeze; a narrow section the field cannot physically resolve is a jam
## rather than a funnel.
##
## Bounded above by the lens rather than by the racing, which the river had to
## learn by rendering a screen of bare ground with no jungle in it: `Mode.LOW` is
## a 26-degree horizontal view at 30m, and a bed much past 6.5 fills the frame
## edge to edge and pushes every serac out of shot. Any course on `TerrainShell`
## inherits this ceiling.
##
## The width profile does a second job here that it does not do on the river.
## `centre_fraction` is a fraction, so a wide bed has proportionally more snow
## either side of the ice and a narrow one is almost all ice: the spillway and
## the basin are open but punishing to wander in, and the narrows are tight but
## fast underfoot. That falls out of the geometry rather than being authored, and
## it is why the widths and the features line up the way they do.
const WIDTH := [
	[0.08, 6.0],       ## Spillway — twelve marbles, room to spread.
	[FORK_FROM, 6.2],  ## Opening out to carry two lanes.
	[ISLAND_AT, 6.5],  ## Fork head. Held at the camera's ceiling for the whole
	                   ## braid: 13m of bed less the 2.4m ridge leaves 5.3m a
	                   ## lane, which is three marbles abreast on each. Both
	                   ## lines have to be real racing lines, not one gap and
	                   ## one squeeze.
	[FORK_TO, 6.5],
	[0.245, 5.6],      ## Closed again, and back to one channel.
	[NARROW_FROM, 4.4],
	[0.32, 3.8],       ## The narrows, at their tightest.
	[NARROW_TO, 3.9],
	[GATE_AT, 4.6],    ## The gate.
	[0.52, 5.2],
	[BEND_TO, 5.0],    ## The sweeper.
	[0.745, 4.4],      ## Crevasse approach — tight, so nobody misses the lip.
	[0.81, 6.5],       ## The basin opens up.
	[0.93, 4.2],       ## Winding.
	[1.00, 5.5],       ## Finish.
]

## Height of the ice bank crest above the bed, before the per-corner boost in
## `_bank_height`. This is the containment: there are no walls on this course,
## and nothing on it is a fixture whose job is to keep a marble in.
##
## Deeper than the river's banks almost everywhere, because a melt channel cuts
## down rather than spreading out, and because ice does not slump — a 2.6m dirt
## bank is a slope, a 2.6m ice bank is a wall with a lip on it. It drops through
## the basin on purpose: an open section that is open on camera as well as in
## plan is worth a small risk of losing somebody there.
const BANK := [
	[0.08, 2.4],
	[0.18, 2.2],
	[0.28, 3.0],
	[NARROW_TO, 3.6],  ## Deep in the channel, cut right down into the ice.
	[GATE_AT, 3.0],
	[BEND_TO, 2.9],    ## Outside of the sweeper is boosted further below.
	[0.80, 2.3],
	[BASIN_TO, 1.6],   ## The basin genuinely opens up.
	[0.95, 2.6],
	[1.00, 2.1],
]

const CORNER_BANK_GAIN := 0.09
const CORNER_BANK_LIMIT := 1.9

const MESH_STEP := 1.5

# --- Surfaces -----------------------------------------------------------------

## The margins, verges and banks: wind-packed snow and rimed ice with grit in it.
##
## 0.30 rather than something dramatically slower, and this is the number the
## course's safety rests on. The temptation is 0.5 — snow is *slow* — but the
## river's floor lesson bites hardest exactly here: a marble that has been shoved
## onto the margin is by definition the marble that is already struggling, and a
## surface that stops it is a stall rather than a penalty. Three times the centre
## strip is plenty to feel.
const FRICTION := 0.30
## Polished, wet, load-bearing channel ice. The fast line.
const CENTRE_FRICTION := 0.11
## Higher than the river's 0.08: ice is hard, and a marble landing out of the
## crevasse should skitter rather than settle.
const BOUNCE := 0.11

# --- Crevasse -----------------------------------------------------------------

## Absolute distance along the course, so the lip, the meltwater, the collision
## geometry and `jump_clearance` all measure from one number.
const CREVASSE_S := CREVASSE_AT * LENGTH

## The take-off. 0.75m over 3.2m is about 13 degrees, which against a course
## descending at 10.5 leaves a marble launching a couple of degrees above
## horizontal — enough hang to cross, nothing like a stunt ramp.
const LIP_RUN := 3.2
const LIP_RISE := 0.75
## The near wall: short, so it reads as a drop rather than a slope a marble can
## crawl down.
const CREVASSE_WALL := 0.32
## How far the floor sits below the bed, and the number that decides whether this
## is a feature or a trap.
##
## The rule it satisfies is the river's, learned there by putting three of twelve
## marbles into a streambed that none of them ever came out of: **the climb out
## must be smaller than the course's own descent across the same span**, so that
## even the exit ramp is downhill in world terms. At 10.5 degrees, 5.0m of course
## drops 0.93m and the ramp lifts 0.85. Anything that lands in this rolls out of
## it.
##
## It is not visible in section — an exit ramp looks like a way out, and for a
## marble still carrying speed it is — which is why the river's version survived
## being written down and had to be found by running a field at it.
const CREVASSE_DEPTH := 0.85
## The flat span. This is the gap: 3.0m at 7 m/s is about 0.43 seconds of air.
const CREVASSE_BED := 3.0
## The far wall, ramped rather than walled, long enough to obey the rule above.
const CREVASSE_EXIT := 5.0
## How far below the bed the meltwater sits. Ankle-deep by construction, and
## visual only — see the class docs.
const WATER_DEPTH := 0.5

# --- Fixtures -----------------------------------------------------------------

## The ice island that splits the field, and the two smaller blocks that keep the
## two lines apart long enough for the split to mean something.
##
## Sized against the bed rather than against nothing, per the river: at 0.17 the
## bed is 13m across and the island is 4.2m of it, leaving four and a half metres
## either side — two to three marbles abreast on each line, which is what makes
## both of them real. A block that left one gap wide enough for the field would
## be scenery.
const ISLAND_SIZE := Vector3(2.1, 2.6, 4.2)

## The medial ridge: the island's down-course tail, and what makes the split a
## braid rather than a single obstacle to steer round.
##
## It replaces the two offset blocks that used to sit at 0.192 and 0.208. Those
## kept the two lines apart for about seven metres and then let them merge; a
## marble that took the left of the island was back in the middle before the
## choice had cost or paid anything. A continuous ridge means the lane you enter
## is the lane you are in until `FORK_TO`.
##
## Height is set against the marble, not the eye: 1.15m to a 0.45m marble is not
## climbable at racing speed, and it is still low enough to see the far lane over
## — which matters, because a player who cannot see the lane they didn't take has
## no way to learn they chose wrong.
const RIDGE_HALF_WIDTH := 1.2
const RIDGE_HEIGHT := 1.15
const RIDGE_STEP := 2.2

## The left lane's floor: polished channel ice laid over the shell's snow.
##
## `TerrainShell.centre_friction` cannot express this. That is one strip down the
## middle of the bed, and the middle of the bed is exactly where the ridge now
## stands — left to itself the braid would be two lanes of `FRICTION` snow with
## the fast surface buried under the divide, which is the whole thesis of the
## course thrown away at the one place it should bite hardest.
##
## So the fast line is laid as its own collider, and it goes on the **left**. The
## channel is drifting right here (`HEADING` 4 degrees at `NARROW_FROM`, 8 by
## 0.32), so the right lane is already the shorter line into the narrows. Putting
## the ice there too would make one lane better in both ways and the choice would
## not be a choice. Left is longer and fast, right is shorter and slow.
const LANE_SIDE := -1.0
## Inset from the ridge and from the verge, so the strip's own edges are never
## the thing a marble catches on entry.
const LANE_INSET := 0.35
## Thin enough to read as a surface rather than a kerb: 0.05m of lip against a
## 0.45m marble.
const LANE_THICKNESS := 0.10

# --- Snow bridges -------------------------------------------------------------

## Two snow bridges across the crevasse, and the course's second moving hazard.
##
## The crevasse already asks a question — carry enough speed to cross 3.0m — and
## the class docs are explicit that failing it costs everything you had rather
## than eliminating you. The bridges do not change that. They add a second, worse
## answer: a span that holds, until it doesn't.
##
## `[lateral, width]`. Both sit off centre with a gap between them, so the
## straight-line fast approach still has to jump and only a marble that steers
## for a bridge gets to use one.
const BRIDGES := [
	[-2.05, 1.9],
	[2.05, 1.9],
]
## How long a bridge stands after the first marble touches it. Long enough for
## the marble that committed to get across, short enough that the pack behind it
## does not.
##
## This is the whole design in one number. A fuse that outlives the field is
## scenery; a fuse that drops the marble that triggered it is a punishment for
## being in front, which is backwards — the leader earned the crossing.
const BRIDGE_FUSE := 0.45
const BRIDGE_THICKNESS := 0.22
## Chunks thrown when a span goes. Debris, not hazard: they exist so a collapse
## behind you is something you can see happen.
const BRIDGE_DEBRIS := 3

# --- Ice boulders -------------------------------------------------------------

## Two loose boulders that run the course with the field.
##
## Not `FallingRock`: that is debris with a `LIFETIME`, and these have to survive
## the whole race. Not `Marble` either — a `Marble` is a racer, and `RaceManager`
## would have to be taught that two of its bodies are not in the running.
## A plain `RigidBody3D` is neither, which is exactly right.
##
## Mass 3.4 against a marble's 1.0, radius 0.95 against 0.45. Heavy enough that
## being hit by one is an event and light enough that it is still pushed around
## by a pack of twelve — a boulder that cannot be moved is a rolling wall, and
## the point is that it is loose.
const BOULDER_RADIUS := 0.95
const BOULDER_MASS := 3.4
## Flanking the grid rather than in it: the field spawns six abreast at 1.8m
## spacing, so it spans ±4.5 and anything inside that displaces a racer at the
## line. Behind the barrier with everyone else, released by the same drop.
## On the grid, in the gaps between the columns rather than out by the bank.
##
## The first version put them at ±5.0 to keep them clear of the field, which kept
## them clear of the race as well: they hugged the margin for 464m and nobody
## ever touched one. The grid is six abreast at 1.8m spacing, so the columns sit
## at ±0.9, ±2.7 and ±4.5 — ±3.6 is exactly between two of them and displaces
## nobody.
const BOULDERS := [
	[-3.6, -1.6],
	[3.6, -2.4],
]

## Boulders calved off the banks mid-race, so the second half has them too.
##
## The grid pair is gone by a third of the way down — a heavy sphere on polished
## ice outruns a marble — and a hazard that only exists at the start is a hazard
## the race has forgotten by the sweeper.
##
## ## Placed against the field, not against the course
##
## The first version dropped these into two fixed bands on a timer, from nine
## metres up, regardless of where anybody was. Both halves of that were wrong.
##
## `ChaseCamera.Mode.LOW` sits **down-course of the marble and looks back up it**.
## So the visible frame is the ground *behind* the leader, and a boulder placed
## ahead of the field is behind the camera: it exists, it is rolling, and nobody
## sees it until they hit it. Anything meant to be watched has to arrive level
## with the field or slightly up-course of it.
##
## And a boulder that materialises above the channel is a spawn. One that comes
## down the bank is a calving — same body, same physics, and the difference is
## entirely in where it starts and which way it is already moving.
##
## So calving is now measured from the front of the field: a short way ahead, off
## the bank face, rolling inwards. It crosses the channel in front of whoever is
## leading, which is on camera for everybody behind them.
const CALVING_INTERVAL_MIN := 5.0
const CALVING_INTERVAL_MAX := 9.0
## How far down-course of the leading marble a boulder comes in.
##
## Small, and it has to be. At 20m the boulder is off the top of the frame before
## it reaches the bed; at 4m it lands on the leader with no warning at all. Eight
## metres is about a second of travel at racing speed — enough to see it coming
## down the bank, not enough to steer round it for free.
const CALVING_LEAD := 8.0
## Where on the bank face it lets go: 0 is the verge, 1 the crest.
const CALVING_HEIGHT := 0.72
## Pushed off the wall rather than merely dropped, so it crosses the bed instead
## of settling at the foot of the bank it came from.
const CALVING_INWARD := 3.4
## Given some of the course's own speed on release, so it does not read as a
## bowling ball rolled across a moving race.
const CALVING_ALONG := 4.5
## Calving is confined to the middle of the course. Before this the field is
## still packed and a boulder through it is a pile-up; after it, there is not
## enough course left to recover from one.
const CALVING_FROM := 0.30
const CALVING_TO := 0.90

# --- Slush ---------------------------------------------------------------------

## Patches of wet slush lying on the bed: the answer to a field that only ever
## spreads out.
##
## Everything else on this course rewards speed. Ice rewards it, the fast lane
## rewards it, and no feature anywhere costs a leader more than a straggler — so
## the field can only diverge, which is exactly what the 39-second spread was.
## Random hazards do not fix that; they hit everyone equally and add variance
## without compressing anything.
##
## ## Why this is not the ripples it replaces
##
## The first version of this was sastrugi — transverse wind ridges, 0.09m high.
## They compressed the field exactly as intended (39 seconds of spread down to
## 17) and they were **horrible to race**: every band was a rattle, and a marble
## crossing four of them spent the straights being bounced rather than driven.
## A tax the player feels as noise is the wrong tax however well it works.
##
## Slush does the same arithmetic without touching the marble. It is flush with
## the bed — no lip, no bump, nothing to skip off — and it costs speed by
## friction alone. That is still speed-proportional in the way that matters: a
## marble carrying 14 m/s into a patch loses far more of it than one arriving at
## 8, because what it gives up is a fraction of what it has.
##
## It is also better looking. `MELT` over `CRYOCONITE` is the darkest thing on
## the course, laid on the palest part of the bed, and it tells the player where
## the slow ground is before they are in it — the same argument the fast lane
## makes, in reverse.
##
## Bands avoid the fork, the narrows, the gate and the crevasse approach —
## everywhere the course already asks a question — and the basin, where `BANK`
## drops to 1.6 and a marble that loses its speed has nothing to reclaim it with.
const SLUSH_BANDS := [
	[0.055, 0.135],
	[0.295, 0.375],
	[0.505, 0.575],
	[0.905, 0.955],
]
const SLUSH_STEP := 5.5
## Half the length of one patch, along the course.
const SLUSH_RUN := 1.9
## Fraction of the bed one patch spans. Never the full width: slush wall to wall
## is a toll every marble pays equally, and a patch that leaves a margin is a
## line to be found.
const SLUSH_SPAN := 0.40
## Slower than the snow margins' 0.30, and the reason it can be: unlike the
## margins this is not where a struggling marble ends up, it is on the racing
## line where there is always something behind to push. The margin's floor
## argument does not apply.
const SLUSH_FRICTION := 0.46
const SLUSH_THICKNESS := 0.12
## How far the patch's top stands above the bed. Small enough not to be a step —
## 15mm against a 0.45m marble — and non-zero so the collider is never coplanar
## with the bed underneath it.
const SLUSH_PROUD := 0.015

# --- Ice arches ---------------------------------------------------------------

## Remnant snow bridges spanning the channel overhead, well above marble height.
##
## Visual only, and the one thing here that a river cannot have. Both courses are
## a trench seen through the same locked 26-degree lens, and everything that
## fills the frame on either of them sits at or below the crest — so they compose
## identically no matter how differently they are painted. An arch puts structure
## across the *top* of the shot and gives the channel a roof line, which is the
## cheapest large change available to how this course reads.
##
## Placed on straights where the span reads as a span rather than as a chord
## across a corner.
const ARCHES := [
	[0.115, 5.6],
	[0.335, 6.4],
	[0.545, 5.9],
	[0.865, 6.8],
]
const ARCH_THICKNESS := 1.5

## Ice shards protruding from the verges through the narrows.
## `[fraction, side, protrusion]` — how far each reaches in over the lip.
##
## Reach and yaw are both set from the river's finding rather than rediscovered:
## the trap is the pocket between a convex prop and the sloped verge behind it,
## reaching less makes the pocket shallower, and yawing each prop so its
## up-course face is a deflector removes the back wall of the V entirely. That
## course found it with a round-three field of three marbles — nobody behind to
## push — after a fixed-seed probe had shown nothing, so these start conservative
## and should be probed with a small field before they are opened up.
const PINCH_SHARDS := [
	[0.285, 1.0, 0.72],
	[0.315, -1.0, 0.80],
	[0.345, 1.0, 0.66],
	[0.368, -1.0, 0.62],
]
const PINCH_YAW := 28.0

## The two towers of the serac gate, as `[side, protrusion, height]`. They stand
## on the verge and lean in over the bed, so the gap between them is narrower
## than the bed and reads from much further up-course than a floor marking would.
const GATE_TOWERS := [
	[-1.0, 0.55, 4.6],
	[1.0, 0.48, 5.2],
]
const GATE_LEAN := 9.0

## The icefall. A serac wall calves across the gate — the course's one moving
## hazard, and the reason it is here rather than anywhere else is that this is
## the one place on the course with something overhead to fall off.
##
## Interval and drop height are the two knobs. `FallingRock` is issue 2's tuning
## — mass 0.6 against a marble's 1.0 — deliberately light enough to deflect
## without deciding a race, and none of that is re-tuned here.
const ICEFALL_INTERVAL_MIN := 1.5
const ICEFALL_INTERVAL_MAX := 3.4
const ICEFALL_HEIGHT := 9.0

## Where ice comes down. Four bands rather than the single 0.41-0.50 window.
##
## One band was 42m of a 464m course — nine percent — and the rest of the race
## had nothing in it at all. The gate band stays where it was because the serac
## towers announce it and that pairing is the course telling you what is coming;
## the other three are placed under the icefield's own serac walls, so each one
## has something overhead for the ice to have come off.
const ICEFALL_BANDS := [
	[0.20, 0.28],
	[ICEFALL_FROM, ICEFALL_TO],
	[0.58, 0.66],
	[0.82, 0.90],
]
## Heavier than `FallingRock.MASS`'s 0.6.
##
## That figure is Volcano's, and it is tuned to "deflect without deciding a
## race" — which on an ice course reads as no obstacle at all, because a marble
## already sliding at 12 m/s barely notices six tenths of its own mass. At 1.1 a
## block is slightly heavier than the marble it hits: it turns a line rather than
## ending one, and it is still nothing like the boulders.
const ICEFALL_MASS := 1.1

# --- Scenery ------------------------------------------------------------------

const SCENERY_SEED := 20260829
const SCENERY_STEP := 6.0
const SCENERY_BEFORE := 60.0
const SCENERY_AFTER := 95.0

# --- Light --------------------------------------------------------------------
#
# A low, late sun on a clear day. This is where "not white" is actually won: the
# ice is cold because the ambient is blue and the sun is warm, so every surface
# facing the light goes peach and every surface facing away goes deep blue. Paint
# cold colours and light them coldly — which is what the older ice course does —
# and the whole frame collapses into one grey-blue value with no shape in it.

const SKY_TOP := Color(0.12, 0.25, 0.47)
const SKY_HORIZON := Color(0.82, 0.73, 0.62)
const AMBIENT_COLOUR := Color(0.50, 0.62, 0.78)
const SUN_COLOUR := Color(1.0, 0.89, 0.72)
const FOG_COLOUR := Color(0.50, 0.60, 0.70)
const FOG_DENSITY := 0.005
## Unlike the river's flat haze, this fog has a direction: a low sun through ice
## crystals is the one atmospheric effect a glacier actually has, and it puts a
## warm glow down-sun that the geometry cannot supply.
const FOG_SUN_SCATTER := 0.28

## The sun's own angle, which this course had never actually set.
##
## `RaceManager._apply_default_environment` puts the sun at -68 degrees — near
## midday — and every course before this one overrode only `light_color`. So the
## low warm sun this entire palette is written for did not exist: the ice was
## being lit from almost overhead, every face got the same value, and the result
## was the flat even wash the class docs accuse `GlacierFaultCourse` of.
##
## 26 degrees is late afternoon. It is the single largest change to how this
## course reads, and it costs one line, because the geometry was always shaped
## for it — a channel cut into a plain has one bank lit and one in shade only if
## something is raking across it.
##
## Yawed well off-axis so the light comes across the channel rather than down it.
## Down-course light backlights every serac into the same silhouette and flattens
## the skyline the mid band exists to build.
const SUN_ANGLE := Vector3(-26.0, -54.0, 0.0)
## Up from the default 1.15, because a low sun spreads the same energy over more
## surface, and because the ambient here is deliberately dim.
const SUN_ENERGY := 1.45
## Up from 0.55. `RaceManager` learned this on the Canyon and wrote it down: a
## raking sun puts one wall's shadow across the bed, and at a low ambient the
## shaded half goes unreadable — which `PROJECT.md` section 2.5 does not allow.
## Raised just enough to keep a marble legible in shadow without lifting the
## blacks that make the cryoconite read as silt.
const AMBIENT_SHADED := 0.72

var _path: CoursePath
var _shell: TerrainShell


func build() -> void:
	_path = CoursePath.create(LENGTH, RAMP_LENGTH, RUNOFF_LENGTH, PITCH, HEADING, ROLL)
	curve = _path.to_curve()
	start_transform = _frame_at(0.0)
	finish_position = _point(LENGTH)

	_build_shell()
	_build_back_wall()
	_build_island()
	_build_fork()
	_build_pinch_shards()
	_build_gate()
	_build_crevasse()
	_build_bridges()
	_build_runoff_backstop()
	_build_slush()
	_build_arches()
	_build_icefield()
	_start_icefall()
	_build_boulders()
	_start_calving()


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
## direction a marble is thrown, so the outside of any corner is the side whose
## sign disagrees with the bank's. One expression covers every corner including
## this course's left-hand sweeper, which is the point of writing it this way
## rather than naming a side.
func _bank_height(s: float, side: float) -> float:
	var base := _path.sample(BANK, s)
	var camber := rad_to_deg(_path.bank_at(s))
	var boost := clampf(-side * camber * CORNER_BANK_GAIN, 0.0, CORNER_BANK_LIMIT)
	return base + boost


## An unrolled frame: the position and heading with the camber taken out and Y
## left pointing at the sky, defined past both ends of the path.
##
## Scenery cannot use `_frame_at`. That frame banks with the corners, which is
## right for anything sitting on the racing surface and wrong for everything
## else — hung off it the whole icefield leans twenty degrees through the sweeper
## and the seracs lean with it.
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
## Zero for all but twelve metres of a four-hundred-metre course. The whole
## crevasse — take-off lip, drop, floor and ramp out — is this one function, and
## `TerrainShell` turns it into geometry continuous with the rest of the trench
## by construction. There is no separate jump mesh, no gap in the collider and no
## seam to tune.
func _bed_drop(s: float) -> float:
	return _crevasse_drop(s)


func _crevasse_drop(s: float) -> float:
	var lip_start := CREVASSE_S - LIP_RUN
	var wall_end := CREVASSE_S + CREVASSE_WALL
	var bed_end := wall_end + CREVASSE_BED
	var exit_end := bed_end + CREVASSE_EXIT

	if s <= lip_start or s >= exit_end:
		return 0.0
	if s < CREVASSE_S:
		# The take-off ramps *up*, so the drop goes negative.
		return -LIP_RISE * (s - lip_start) / LIP_RUN
	if s < wall_end:
		# The near wall: from the lip's top straight down to the floor.
		var t := (s - CREVASSE_S) / CREVASSE_WALL
		return lerpf(-LIP_RISE, CREVASSE_DEPTH, t)
	if s < bed_end:
		return CREVASSE_DEPTH
	return CREVASSE_DEPTH * (1.0 - (s - bed_end) / CREVASSE_EXIT)


## The mud lip between bed and bank, flattened where the crevasse cuts through.
##
## A raised lip abutting a hole is a corner, and the river's note is explicit
## that flattening it did not on its own fix the stall it was written for — but a
## corner at the mouth of a crevasse is a real corner whether or not it is the
## culprit on any given day, and a lip that runs unbroken across a gap in the bed
## reads as a kerb bridging thin air.
func _verge_lift_at(s: float) -> float:
	var span := 3.0
	var from := CREVASSE_S - LIP_RUN - span
	var to := CREVASSE_S + CREVASSE_WALL + CREVASSE_BED + CREVASSE_EXIT + span
	if s <= from or s >= to:
		return 0.42
	var edge := minf(s - from, to - s)
	return lerpf(0.10, 0.42, clampf(edge / span, 0.0, 1.0))


## Distances the mesh must sample exactly, whatever `step` would otherwise land
## on. Every hard edge of the crevasse is a step change in `_bed_drop`, and a
## step change only becomes a vertical face if there are rows on both sides of
## it. Left to a fixed stride the take-off lip comes out as a random ramp whose
## angle depends on where the stride happened to fall.
func _key_stations() -> Array[float]:
	var wall_end := CREVASSE_S + CREVASSE_WALL
	var bed_end := wall_end + CREVASSE_BED
	return [
		CREVASSE_S - LIP_RUN,
		CREVASSE_S - LIP_RUN * 0.5,
		CREVASSE_S - 0.05,
		CREVASSE_S,
		wall_end,
		wall_end + CREVASSE_BED * 0.5,
		bed_end,
		bed_end + CREVASSE_EXIT * 0.5,
		bed_end + CREVASSE_EXIT,
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
	_shell.centre_friction = CENTRE_FRICTION
	_shell.bounce = BOUNCE
	_shell.verge_width = 0.8
	_shell.verge_lift = _verge_lift_at
	# Steeper than the river's banks. Ice does not slump to a talus angle the way
	# cut earth does, and 2.6m of bank over 2.4m of run is about 47 degrees —
	# something a marble is turned back by rather than something it climbs.
	_shell.bank_run = 2.4
	# The snow band covers the top third of the bank. Lower than the river's
	# crest fraction because the *ice* face is the thing worth seeing here: it is
	# the most saturated surface on the course and the one that says how deep the
	# channel is cut.
	_shell.crest_fraction = 0.34
	# The physical fast line and the visible one are the same strip. See the
	# class docs — this number is shared with `centre_friction` by intent, and
	# changing one without the other is the bug this course is most likely to
	# grow.
	_shell.centre_fraction = 0.38

	# The icefield leaves the crest almost level, climbs through the band the
	# seracs stand in, and then rises hard into a wall of broken ice. That last
	# entry does the most work: under `Mode.LOW` the top of the frame is about
	# ten degrees below the horizon, so a ground plane that stays flat draws a
	# band of bare sky where the glacier should be. Twenty metres at 110 out is
	# what puts a skyline across the top of the shot.
	_shell.ground_profile = [
		[4.0, 1.0], [12.0, 3.6], [30.0, 7.5], [60.0, 13.0], [110.0, 21.0]
	]
	_shell.ground_columns = 8
	# Less relief than the river's hillside. A glacier surface is broken but not
	# rolling, and large low-frequency waves in it read as sand dunes.
	_shell.ground_relief = 3.0

	# The crest band is painted in the icefield's own colours, not the bank's, so
	# there is no hard line exactly where this class exists to have none.
	_shell.set_materials(
		_ground_material(IceKit.FIRN, IceKit.MORAINE, 0.05, 0.5, 0.4),
		_ground_material(IceKit.ICE_BLUE, IceKit.ICE_DEEP, 0.10, 0.62, 0.34),
		_material(IceKit.CRYOCONITE.lightened(0.06)),
		_ground_material(IceKit.ICE_PALE, IceKit.CRYOCONITE, 0.14, 0.9, 0.12),
		_ground_material(IceKit.ICE_DEEP, IceKit.ICE_BLUE, 0.17, 1.2, 0.08)
	)
	_shell.ground_material = _ground_material(
		IceKit.FIRN, IceKit.STONE_DARK, 0.028, 0.30, 0.42
	)
	_shell.build(self)


## The head of the channel. The full-width backstop every course here puts behind
## its start line — a marble knocked backwards off the ramp needs something to
## hit — dressed as the cut ice face the melt runs out of, because the camera
## spends the whole countdown looking straight at it.
func _build_back_wall() -> void:
	var half := _half_width_at(-RAMP_LENGTH)
	var frame := _frame_at(-RAMP_LENGTH)
	var height := 5.0

	var body := StaticBody3D.new()
	body.name = "ChannelHead"
	body.transform = frame
	var surface := PhysicsMaterial.new()
	surface.friction = FRICTION
	surface.bounce = BOUNCE
	body.physics_material_override = surface

	var size := Vector3((half + 4.0) * 2.0, height, 1.2)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = Vector3(0.0, height * 0.5 - 0.6, 0.4)
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = collider.position
	visual.material_override = _ground_material(
		IceKit.ICE_BLUE, IceKit.ICE_DEEP, 0.12, 0.7, 0.3
	)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)

	add_child(body)


## A backstop at the far end of the run-out, so a marble that crosses the line
## with everything it had still comes to rest on the course.
func _build_runoff_backstop() -> void:
	var s := LENGTH + RUNOFF_LENGTH
	var half := _half_width_at(s)
	var frame := _frame_at(s)

	var body := StaticBody3D.new()
	body.name = "RunoffBackstop"
	body.transform = frame
	var surface := PhysicsMaterial.new()
	surface.friction = 0.6
	surface.bounce = 0.02
	body.physics_material_override = surface

	var size := Vector3((half + 3.0) * 2.0, 4.0, 1.0)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = Vector3(0.0, 1.4, -0.5)
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = collider.position
	visual.material_override = _material(IceKit.FIRN)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)

	add_child(body)


# --- Fixtures -----------------------------------------------------------------


## A colliding ice prop, mesh and convex hull built from the same points so the
## two can never disagree.
func _add_ice_block(
	transform: Transform3D, size: Vector3, variant: int, colour: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = "IceBlock"
	body.transform = transform
	var surface := PhysicsMaterial.new()
	# Fixtures carry the *centre* friction, not the margin's. They are ice, they
	# are standing in the middle of an ice channel, and a marble that glances one
	# should skate off it rather than stick to it.
	surface.friction = CENTRE_FRICTION
	surface.bounce = BOUNCE
	body.physics_material_override = surface

	var scaled := PackedVector3Array()
	for point in IceKit.serac_points(variant):
		scaled.append(point * size)

	var shape := ConvexPolygonShape3D.new()
	shape.points = scaled
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var visual := MeshInstance3D.new()
	visual.mesh = IceKit.serac(variant)
	visual.scale = size
	visual.material_override = _material(colour)
	body.add_child(visual)

	add_child(body)


## The island split. One block in the middle of the widest part of the channel,
## then two smaller ones offset to opposite sides so the two lines stay apart for
## a while instead of merging the moment they part.
func _build_island() -> void:
	var frame := _frame_at(ISLAND_AT * LENGTH)
	_add_ice_block(
		frame.translated_local(Vector3(0.0, ISLAND_SIZE.y * 0.40, 0.0)),
		ISLAND_SIZE, 3, IceKit.ICE_BLUE
	)


## The braid: the medial ridge and the fast lane beside it.
##
## Both are built station by station along the same stride rather than as one
## long box, because the channel is already turning here — `HEADING` reaches 4
## degrees by `NARROW_FROM` — and a single box would cut the corner off the bed
## and leave a wedge of ridge standing outside the lane it is meant to divide.
func _build_fork() -> void:
	var from := ISLAND_AT * LENGTH
	var to := FORK_TO * LENGTH

	var s := from
	var index := 0
	while s < to:
		var span := minf(RIDGE_STEP, to - s)
		var mid := s + span * 0.5
		# Overlapped by a whisker. Convex hulls that merely touch leave a seam a
		# marble at 7 m/s can find, and a ridge with a gap in it is a ridge the
		# field discovers before the player does.
		_add_ridge_segment(mid, span * 0.62, _ridge_taper(mid, from, to), index)
		_add_lane_segment(mid, span * 0.55)
		s += RIDGE_STEP
		index += 1


## The ridge's height at one station: full through the middle, eased to nothing
## at both ends.
##
## The down-course end matters more than it looks. A ridge that stops at full
## height is a 1.15m wall standing across the closing lanes exactly where the two
## halves of the field are converging on each other, which is a pile-up rather
## than a merge. Ramped away, the last two metres are something a marble rides
## over if it has to.
func _ridge_taper(s: float, from: float, to: float) -> float:
	var ease_in := 4.0
	var ease_out := 7.0
	var head := clampf((s - from) / ease_in, 0.0, 1.0)
	var tail := clampf((to - s) / ease_out, 0.0, 1.0)
	return RIDGE_HEIGHT * minf(head, tail)


func _add_ridge_segment(s: float, half_length: float, height: float, index: int) -> void:
	if height < 0.05:
		return
	var frame := _frame_at(s)
	_add_ice_block(
		frame.translated_local(Vector3(0.0, height * 0.42, 0.0)),
		Vector3(RIDGE_HALF_WIDTH, height * 0.62, half_length),
		3 + index % 5,
		IceKit.ICE_BLUE.lerp(IceKit.ICE_DEEP, 0.30)
	)


## One paving slab of the fast lane: polished ice laid on the snow, flush enough
## to roll onto without a step.
func _add_lane_segment(s: float, half_length: float) -> void:
	var half := _half_width_at(s)
	var inner := RIDGE_HALF_WIDTH + LANE_INSET
	var outer := half - LANE_INSET
	if outer <= inner:
		return

	var width := outer - inner
	var centre := LANE_SIDE * (inner + width * 0.5)
	var frame := _frame_at(s)

	var body := StaticBody3D.new()
	body.name = "FastLane"
	body.transform = frame.translated_local(
		Vector3(centre, -LANE_THICKNESS * 0.5, 0.0)
	)
	var surface := PhysicsMaterial.new()
	surface.friction = CENTRE_FRICTION
	surface.bounce = BOUNCE
	body.physics_material_override = surface

	var size := Vector3(width, LANE_THICKNESS, half_length * 2.0)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	# Darker than anything either side of it. The friction split has to be
	# legible before it is felt — see the class docs on ice that is not white.
	visual.material_override = _ground_material(
		IceKit.ICE_DEEP, IceKit.MELT, 0.10, 0.85, 0.2
	)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)

	add_child(body)


## Ice shards reaching in over the verge through the narrows.
##
## Each is yawed so its up-course face is a deflector rather than the back wall
## of a V — see `PINCH_YAW` and the river's finding. The yaw sign follows the
## side, so both walls throw a marble back towards the middle.
func _build_pinch_shards() -> void:
	for entry: Array in PINCH_SHARDS:
		var s: float = entry[0] * LENGTH
		var side: float = entry[1]
		var reach: float = entry[2]
		var half := _half_width_at(s)
		var frame := _frame_at(s)

		var size := Vector3(1.5, 1.7, 1.3)
		var at := frame.translated_local(
			Vector3(side * (half + _shell.verge_width - reach), 0.5, 0.0)
		)
		var yawed := at.rotated_local(Vector3.UP, deg_to_rad(-side * PINCH_YAW))
		_add_ice_block(
			yawed, size, 7 + int(entry[0] * 1000.0) % 4,
			IceKit.ICE_PALE.lerp(IceKit.CRYOCONITE, 0.25)
		)


## The serac gate: two towers standing on the verges and leaning in over the bed.
##
## They read from much further up-course than any floor marking would, which is
## the point — this is the course telling the player where the icefall is before
## the first block comes down.
func _build_gate() -> void:
	var s := GATE_AT * LENGTH
	var half := _half_width_at(s)
	var frame := _frame_at(s)

	var index := 0
	for entry: Array in GATE_TOWERS:
		var side: float = entry[0]
		var reach: float = entry[1]
		var height: float = entry[2]
		var at := frame.translated_local(
			Vector3(side * (half + _shell.verge_width - reach), height * 0.30, 0.0)
		)
		# Leaning *inwards*, so the gap narrows with height and the towers frame
		# the shot rather than standing outside it.
		var leaned := at.rotated_local(Vector3.FORWARD, deg_to_rad(side * GATE_LEAN))
		_add_ice_block(
			leaned, Vector3(1.7, height * 0.5, 1.7),
			11 + index, IceKit.ICE_BLUE.lerp(IceKit.ICE_RIME, 0.22)
		)
		index += 1


## The crevasse floor's meltwater. Purely visual — see the class docs on why
## falling in is a cost rather than an elimination.
func _build_crevasse() -> void:
	var wall_end := CREVASSE_S + CREVASSE_WALL
	var centre := wall_end + CREVASSE_BED * 0.5
	var half := _half_width_at(centre)
	var frame := _frame_at(centre)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(half * 2.0, 0.06, CREVASSE_BED)
	var water := MeshInstance3D.new()
	water.name = "Meltwater"
	water.mesh = mesh
	# `bed_drop` measures downwards but the frame does not: a surface
	# `WATER_DEPTH` below the bed sits at -WATER_DEPTH here. Written the other way
	# round this put the meltwater a third of a metre *above* the ice.
	water.transform = frame.translated_local(Vector3(0.0, -WATER_DEPTH, 0.0))
	var material := _material(IceKit.MELT)
	# Depth pre-pass, not plain alpha: this plane reaches sideways into both banks
	# on purpose, and a blended material that writes no depth draws *over* the bank
	# instead of being buried in it — a translucent sheet lying across the sides of
	# the course, which is what `Mode.WIDE` made obvious by showing more bank.
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


# --- Snow bridges -------------------------------------------------------------


## Two spans across the crevasse that hold until something crosses them.
##
## The trigger is an `Area3D` sitting on the deck rather than contact on the
## `StaticBody3D` itself, because a static body has no contact signal and giving
## each span a `RigidBody3D` would mean two more sleeping bodies per race that
## exist only to report being touched.
func _build_bridges() -> void:
	var wall_end := CREVASSE_S + CREVASSE_WALL
	var span := CREVASSE_BED + CREVASSE_WALL
	var centre := wall_end + CREVASSE_BED * 0.5
	var frame := _frame_at(centre)

	for entry: Array in BRIDGES:
		var lateral: float = entry[0]
		var width: float = entry[1]

		var body := StaticBody3D.new()
		body.name = "SnowBridge"
		# At bed level, not at the crevasse floor: the deck carries on from the
		# lip it springs off, which is what makes it read as a span rather than
		# as a step down into the hole.
		body.transform = frame.translated_local(
			Vector3(lateral, -BRIDGE_THICKNESS * 0.5, 0.0)
		)
		var surface := PhysicsMaterial.new()
		# Snow, not ice. A bridge you can carry full speed across is one nobody
		# ever has to decide about.
		surface.friction = FRICTION
		surface.bounce = 0.02
		body.physics_material_override = surface

		var size := Vector3(width, BRIDGE_THICKNESS, span)
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

		var mesh := BoxMesh.new()
		mesh.size = size
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = _material(IceKit.SNOW)
		body.add_child(visual)

		var trigger := Area3D.new()
		trigger.name = "Trigger"
		var trigger_shape := BoxShape3D.new()
		# Standing proud of the deck, so it catches a marble rolling over rather
		# than only one that has already sunk into the span.
		trigger_shape.size = Vector3(width, 1.2, span)
		var trigger_collider := CollisionShape3D.new()
		trigger_collider.shape = trigger_shape
		trigger_collider.position = Vector3(0.0, 0.7, 0.0)
		trigger.add_child(trigger_collider)
		trigger.body_entered.connect(_on_bridge_touched.bind(body))
		body.add_child(trigger)

		add_child(body)


func _on_bridge_touched(body: Node3D, bridge: StaticBody3D) -> void:
	if not (body is Marble) or not is_instance_valid(bridge):
		return
	if bridge.has_meta("collapsing"):
		return
	bridge.set_meta("collapsing", true)

	var fuse := Timer.new()
	fuse.name = "Fuse"
	fuse.one_shot = true
	fuse.timeout.connect(_collapse_bridge.bind(bridge))
	bridge.add_child(fuse)
	fuse.start(BRIDGE_FUSE)


func _collapse_bridge(bridge: StaticBody3D) -> void:
	if not is_instance_valid(bridge):
		return

	var at := bridge.global_transform
	for i in BRIDGE_DEBRIS:
		var chunk := FallingRock.create(IceKit.SNOW)
		chunk.transform = at.translated_local(
			Vector3(
				randf_range(-0.6, 0.6),
				randf_range(-0.2, 0.2),
				randf_range(-1.2, 1.2)
			)
		)
		add_child(chunk)

	bridge.queue_free()


# --- Slush ---------------------------------------------------------------------


## Slush lying on the bed, band by band. See `SLUSH_BANDS` for why this is the
## feature that answers the spread, and why it is not the ripples it replaces.
func _build_slush() -> void:
	var index := 0
	for band: Array in SLUSH_BANDS:
		var s: float = band[0] * LENGTH
		var to: float = band[1] * LENGTH
		while s < to:
			_add_slush(s, index)
			s += SLUSH_STEP * randf_range(0.75, 1.30)
			index += 1


func _add_slush(s: float, index: int) -> void:
	var half := _half_width_at(s)
	var frame := _frame_at(s)
	# Drifting across the bed rather than centred, so consecutive patches never
	# leave one clean lane down the middle of a whole band — the line through a
	# band has to be steered, not just held.
	var span := half * SLUSH_SPAN
	var shift := sin(float(index) * 1.7) * (half - span) * 0.92

	var body := StaticBody3D.new()
	body.name = "Slush"
	body.transform = frame.translated_local(
		Vector3(shift, SLUSH_PROUD - SLUSH_THICKNESS * 0.5, 0.0)
	)
	var surface := PhysicsMaterial.new()
	surface.friction = SLUSH_FRICTION
	# Dead, unlike everything else on this course. Slush does not skitter.
	surface.bounce = 0.0
	body.physics_material_override = surface

	var size := Vector3(span * 2.0, SLUSH_THICKNESS, SLUSH_RUN * 2.0)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _ground_material(
		IceKit.MELT, IceKit.CRYOCONITE, 0.18, 0.9, 0.25
	)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)

	add_child(body)


# --- Ice arches ---------------------------------------------------------------


## Remnant spans across the channel, overhead and non-colliding.
##
## No collider at all, deliberately. They sit `ARCHES[n][1]` metres up and a
## marble never reaches them, so a collision body would be 464m of physics that
## can only ever produce a bug — the icefield's own rule, applied to the one
## piece of scenery that hangs over the racing line.
func _build_arches() -> void:
	for entry: Array in ARCHES:
		var s: float = entry[0] * LENGTH
		var height: float = entry[1]
		var half := _half_width_at(s)
		var frame := _ground_frame(s)

		var reach := half + _shell.verge_width + _shell.bank_run

		var mesh := BoxMesh.new()
		mesh.size = Vector3(reach * 2.0, ARCH_THICKNESS, ARCH_THICKNESS * 2.2)
		var visual := MeshInstance3D.new()
		visual.name = "IceArch"
		visual.mesh = mesh
		visual.transform = frame.translated_local(Vector3(0.0, height, 0.0))
		# Lit from below by nothing, so it reads as a silhouette against the sky
		# — which is the whole job. Shadow casting stays *on*: the bar of shade it
		# throws across the bed is how the player reads that it is there.
		visual.material_override = _ground_material(
			IceKit.ICE_BLUE, IceKit.ICE_DEEP, 0.14, 0.6, 0.4
		)
		add_child(visual)


# --- Ice boulders -------------------------------------------------------------


## Two loose boulders on the start grid, released with the field.
func _build_boulders() -> void:
	for entry: Array in BOULDERS:
		var lateral: float = entry[0]
		var back: float = entry[1]
		_add_boulder(_frame_at(back), lateral, BOULDER_RADIUS)


## Fresh boulders calving off the serac walls, on a timer, in front of the field.
func _start_calving() -> void:
	var timer := Timer.new()
	timer.name = "Calving"
	timer.one_shot = true
	timer.timeout.connect(_on_calving_timeout.bind(timer))
	add_child(timer)
	timer.start(randf_range(CALVING_INTERVAL_MIN, CALVING_INTERVAL_MAX))


func _on_calving_timeout(timer: Timer) -> void:
	var front := _field_front()
	var s := front + CALVING_LEAD
	if front > 0.0 and s > CALVING_FROM * LENGTH and s < CALVING_TO * LENGTH:
		_calve(s, 1.0 if randf() < 0.5 else -1.0)

	if is_instance_valid(timer):
		timer.start(randf_range(CALVING_INTERVAL_MIN, CALVING_INTERVAL_MAX))


## How far down-course the leading marble is.
##
## The field are siblings, not children: `RaceManager` adds the course and the
## marbles to the same parent, and so does `tools/probe_course.tscn`. Reading the
## parent rather than being handed the field keeps this working under both
## without either of them having to know the course wants to watch.
##
## Zero when there is nobody racing, which is also what the first frame looks
## like — `_on_calving_timeout` treats that as "not yet" rather than as the start
## line, so nothing calves onto a grid that has not moved.
func _field_front() -> float:
	var parent := get_parent()
	if parent == null or curve == null:
		return 0.0

	var front := 0.0
	for node in parent.get_children():
		if node is Marble and is_instance_valid(node):
			front = maxf(front, curve.get_closest_offset(node.global_position))
	return front


## One boulder off one bank, already moving.
func _calve(s: float, side: float) -> void:
	var frame := _frame_at(s)
	var release: Vector3 = _shell.bank_point(s, side, CALVING_HEIGHT)

	var boulder := _add_boulder(
		Transform3D(frame.basis, release),
		0.0,
		BOULDER_RADIUS * randf_range(0.82, 1.0)
	)
	# Inwards across the bed and a little down-course, in the frame's own axes so
	# it still reads right through the sweeper where the channel is turning.
	boulder.linear_velocity = frame.basis * Vector3(
		-side * CALVING_INWARD, 0.0, -CALVING_ALONG
	)


func _add_boulder(frame: Transform3D, lateral: float, radius: float) -> RigidBody3D:
	var boulder := RigidBody3D.new()
	boulder.name = "IceBoulder"
	boulder.mass = BOULDER_MASS
	# Same reason `Marble` sets it: a body resting against the start barrier
	# falls asleep, and Godot does not wake it when the static geometry it is
	# leaning on moves away. A sleeping boulder never starts the race.
	boulder.can_sleep = false
	# It is bigger than a marble but it is also faster than one down the ice, and
	# a heavy sphere on a thin bridge deck tunnels through it without this.
	boulder.continuous_cd = true

	var surface := PhysicsMaterial.new()
	surface.friction = CENTRE_FRICTION
	surface.bounce = BOUNCE
	boulder.physics_material_override = surface

	var shape := SphereShape3D.new()
	shape.radius = radius
	var collider := CollisionShape3D.new()
	collider.shape = shape
	boulder.add_child(collider)

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	# Deliberately not a marble colour. `RaceManager` hands the field bright
	# skins, and a boulder that could be mistaken for a racer at speed makes the
	# rank tags look wrong.
	visual.material_override = _material(IceKit.ICE_RIME)
	boulder.add_child(visual)

	boulder.transform = Transform3D(
		Basis.IDENTITY, frame * Vector3(lateral, radius + 0.2, 0.0)
	)
	add_child(boulder)
	return boulder


# --- Icefall ------------------------------------------------------------------


## One free-running timer for the whole zone rather than one per block: a block
## is a `RigidBody3D` that lives until `FallingRock.LIFETIME` or a fall past the
## threshold, and the spawner's only job is to place a new one every so often.
##
## Follows `VolcanoCourse`'s rockfall exactly, including the reason it is a timer
## rather than anything cleverer: debris that arrives on a schedule the player
## can learn is a rhythm, and debris that arrives at random is a hazard. This is
## the second.
func _start_icefall() -> void:
	var timer := Timer.new()
	timer.name = "Icefall"
	timer.one_shot = true
	timer.timeout.connect(_on_icefall_timeout.bind(timer))
	add_child(timer)
	timer.start(randf_range(ICEFALL_INTERVAL_MIN, ICEFALL_INTERVAL_MAX))


func _on_icefall_timeout(timer: Timer) -> void:
	_spawn_ice()
	if is_instance_valid(timer):
		timer.start(randf_range(ICEFALL_INTERVAL_MIN, ICEFALL_INTERVAL_MAX))


func _spawn_ice() -> void:
	var band: Array = ICEFALL_BANDS[randi() % ICEFALL_BANDS.size()]
	var s := randf_range(band[0] * LENGTH, band[1] * LENGTH)
	var half := _half_width_at(s)
	var frame := _frame_at(s)
	var lateral := randf_range(-half * 0.8, half * 0.8)

	var block := FallingRock.create(IceKit.ICE_PALE)
	block.mass = ICEFALL_MASS
	block.transform = frame.translated_local(
		Vector3(lateral, ICEFALL_HEIGHT, 0.0)
	)
	add_child(block)


# --- Scenery ------------------------------------------------------------------


## The icefield, in three distance bands. Nothing here collides.
func _build_icefield() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCENERY_SEED

	var shards := IceKit.group(IceKit.shard(1), "Shards")
	var cobbles := IceKit.group(IceKit.cobble(2), "Cobbles")
	var slabs := IceKit.group(IceKit.slab(3), "Slabs")
	var seracs := IceKit.group(IceKit.serac(4), "Seracs")
	var towers := IceKit.group(IceKit.serac(9), "SeracsTall")
	var pinnacles := IceKit.group(IceKit.pinnacle(5), "Pinnacles")
	var drifts := IceKit.group(IceKit.drift(6), "Drifts")
	var ridges := IceKit.group(IceKit.ridge(7), "Ridges")

	var s := -RAMP_LENGTH - SCENERY_BEFORE
	var last := LENGTH + RUNOFF_LENGTH + SCENERY_AFTER

	while s < last:
		for side: float in [-1.0, 1.0]:
			_near_band(s, side, rng, shards, cobbles, slabs)
			_mid_band(s, side, rng, seracs, towers, pinnacles, drifts)
			_far_band(s, side, rng, ridges)
		s += SCENERY_STEP

	IceKit.emit(self, [
		shards, cobbles, slabs, seracs, towers, pinnacles, drifts, ridges
	])


## NEAR — the crest and the first seven metres. The only band the low camera
## resolves as objects, and the one that has to carry the grit: shards of broken
## ice, moraine cobbles and rimed plates. Without the cobbles this band is white
## on white and the crest disappears.
func _near_band(
	s: float, side: float, rng: RandomNumberGenerator,
	shards: IceKit.Group, cobbles: IceKit.Group, slabs: IceKit.Group
) -> void:
	# Ice fragments on the bank face itself, between the lip and the crest.
	if rng.randf() < 0.55:
		var t := rng.randf_range(0.30, 0.92)
		var shard_size := rng.randf_range(0.22, 0.52)
		shards.add(
			IceKit.leaning(
				_shell.bank_point(s + rng.randf_range(-2.0, 2.0), side, t),
				Vector3(shard_size, shard_size * rng.randf_range(0.8, 1.6), shard_size),
				0.5, rng
			),
			IceKit.varied(IceKit.ICE_RIME, rng, 0.12)
		)

	# Moraine on the crest. The dark values in the near field, and the single
	# most important scatter on the course for stopping it reading as white.
	var count := 2 if rng.randf() < 0.4 else 1
	for i in count:
		var cobble_out := rng.randf_range(IceKit.NEAR_INNER, IceKit.NEAR_OUTER)
		var cobble_size := rng.randf_range(0.20, 0.62)
		cobbles.add(
			IceKit.planted(
				_shell.ground_point(s + rng.randf_range(-3.0, 3.0), side, cobble_out),
				Vector3(
					cobble_size, cobble_size * 0.62,
					cobble_size * rng.randf_range(0.9, 1.4)
				),
				rng
			),
			IceKit.varied(
				IceKit.MORAINE if rng.randf() < 0.6 else IceKit.MORAINE_DARK,
				rng, 0.10
			)
		)

	# Plates of ice lying tilted near the crest, catching the low sun.
	if rng.randf() < 0.22:
		var slab_out := rng.randf_range(0.6, IceKit.NEAR_OUTER)
		var slab_size := rng.randf_range(0.7, 1.8)
		slabs.add(
			IceKit.leaning(
				_shell.ground_point(s + rng.randf_range(-3.0, 3.0), side, slab_out)
					+ Vector3.UP * 0.05,
				Vector3(
					slab_size, slab_size * 0.14,
					slab_size * rng.randf_range(0.7, 1.2)
				),
				0.35, rng
			),
			IceKit.varied(IceKit.ICE_PALE, rng, 0.14)
		)


## MID — the serac field, and the band that gives the course its skyline.
##
## Two serac meshes rather than one because a tower is read by its silhouette and
## the eye finds a repeated silhouette immediately, in a way it does not find a
## repeated tree. Leaned in every axis: a block that calved off an ice cliff and
## settled is never plumb, and a field of vertical towers reads as a fence.
func _mid_band(
	s: float, side: float, rng: RandomNumberGenerator,
	seracs: IceKit.Group, towers: IceKit.Group,
	pinnacles: IceKit.Group, drifts: IceKit.Group
) -> void:
	if rng.randf() < 0.62:
		var serac_out := rng.randf_range(IceKit.MID_INNER, IceKit.MID_OUTER)
		# Bigger further out, so the field reads as receding rather than as a
		# uniform crop. The near seracs stay small enough not to wall the shot in.
		var reach := serac_out / IceKit.MID_OUTER
		var serac_size := rng.randf_range(1.1, 2.4) + reach * rng.randf_range(1.0, 4.5)
		var group := towers if rng.randf() < 0.45 else seracs
		group.add(
			IceKit.leaning(
				_shell.ground_point(s + rng.randf_range(-3.0, 3.0), side, serac_out)
					+ Vector3.UP * serac_size * 0.42,
				Vector3(
					serac_size * rng.randf_range(0.6, 0.9),
					serac_size * 1.5,
					serac_size * 0.75
				),
				0.13, rng
			),
			IceKit.varied(
				IceKit.ICE_BLUE.lerp(IceKit.ICE_RIME, rng.randf_range(0.1, 0.55)),
				rng, 0.10
			)
		)

	if rng.randf() < 0.30:
		var spike_out := rng.randf_range(IceKit.MID_INNER, IceKit.MID_OUTER * 0.7)
		var spike_size := rng.randf_range(0.8, 2.2)
		pinnacles.add(
			IceKit.leaning(
				_shell.ground_point(s + rng.randf_range(-3.0, 3.0), side, spike_out)
					+ Vector3.UP * spike_size * 0.9,
				Vector3(spike_size * 0.34, spike_size * 2.0, spike_size * 0.34),
				0.10, rng
			),
			IceKit.varied(IceKit.ICE_PALE, rng, 0.12)
		)

	# Snow drifts, kept to the mid band. Snow on the crest would put the
	# brightest value in the kit right beside the darkest, which is the one
	# contrast this palette does not want — the bed is meant to be the dark thing.
	if rng.randf() < 0.34:
		var drift_out := rng.randf_range(IceKit.MID_INNER + 3.0, IceKit.MID_OUTER)
		var drift_size := rng.randf_range(1.6, 4.5)
		drifts.add(
			IceKit.planted(
				_shell.ground_point(s + rng.randf_range(-4.0, 4.0), side, drift_out)
					- Vector3.UP * drift_size * 0.25,
				Vector3(
					drift_size, drift_size * 0.42,
					drift_size * rng.randf_range(0.8, 1.5)
				),
				rng
			),
			IceKit.varied(IceKit.SNOW, rng, 0.06)
		)


## FAR — dark rock ridges standing out of the ice. Nunataks: the one thing on a
## glacier that is neither white nor blue, and the reason the skyline reads as a
## mountain range rather than as fog.
func _far_band(
	s: float, side: float, rng: RandomNumberGenerator, ridges: IceKit.Group
) -> void:
	if rng.randf() > 0.34:
		return
	var out := rng.randf_range(IceKit.FAR_INNER, IceKit.FAR_OUTER)
	var size := rng.randf_range(7.0, 16.0)
	ridges.add(
		IceKit.leaning(
			_shell.ground_point(s + rng.randf_range(-8.0, 8.0), side, out)
				+ Vector3.UP * size * 0.30,
			Vector3(size * rng.randf_range(1.2, 2.6), size * 0.85, size),
			0.09, rng
		),
		IceKit.varied(
			IceKit.STONE_DARK.lerp(IceKit.STONE, rng.randf_range(0.0, 0.5)),
			rng, 0.08
		)
	)


# --- Finish -------------------------------------------------------------------

const ARCH_COLOUR := Color(0.24, 0.46, 0.56)
const FLAG_COLOURS := [
	Color(0.86, 0.34, 0.22),
	Color(0.94, 0.72, 0.26),
	Color(0.30, 0.62, 0.72),
]


## A remnant ice bridge over the line — the last span of a roof that used to
## cover the whole channel.
##
## Purely visual, per `Course.create_finish_visual`: anything a marble can touch
## belongs in `build` with the rest of the collision geometry, so a fixture can
## never be added here by accident and change a race outcome. The arch is
## therefore built high and wide enough that it would not be touched even if it
## could be.
func create_finish_visual() -> Node3D:
	var root := Node3D.new()
	root.name = "IceArch"
	# In the course's own space, the way `CourseBuilder` hands `CanyonFinish` its
	# frame: `FinishZone` adds this as a plain child and places its own pieces
	# through a `_frame` of its own, so a visual returned at identity would stand
	# at the start line.
	root.transform = _frame_at(LENGTH)

	var half := _half_width_at(LENGTH)
	var material := _ground_material(
		ARCH_COLOUR, IceKit.ICE_DEEP, 0.10, 0.7, 0.30
	)

	# Two piers and a span, all from the serac mesh: a bridge that is visibly
	# made of the same ice as the banks it grows out of.
	for side: float in [-1.0, 1.0]:
		var pier := MeshInstance3D.new()
		pier.mesh = IceKit.serac(4)
		pier.scale = Vector3(2.0, 4.4, 2.2)
		pier.position = Vector3(side * (half + 0.7), 1.9, 0.0)
		pier.material_override = material
		pier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(pier)

	var span := MeshInstance3D.new()
	span.mesh = IceKit.slab(3)
	span.scale = Vector3(half * 2.3, 0.9, 2.6)
	span.position = Vector3(0.0, 5.0, 0.0)
	span.rotation = Vector3(0.0, 0.0, deg_to_rad(4.0))
	span.material_override = material
	span.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(span)

	# Marker flags on the crest either side, the one warm colour in the frame.
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var along := float(i / 2) * 2.4 - 2.4
		var flag := MeshInstance3D.new()
		flag.mesh = IceKit.slab(5)
		flag.scale = Vector3(0.5, 0.06, 0.34)
		flag.position = Vector3(side * (half + 1.4), 2.4, along)
		flag.rotation = Vector3(0.0, 0.0, deg_to_rad(side * 22.0))
		flag.material_override = _material(FLAG_COLOURS[i % FLAG_COLOURS.size()])
		flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(flag)

	return root


# --- Materials ----------------------------------------------------------------


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


## Ground and bed panels get the project's world-space detail shader rather than
## flat albedo. Four hundred metres of one colour tells the eye nothing about how
## fast anything is moving, and on ice that matters more than it did on mud —
## a polished surface with no texture in it has no visible speed at all.
func _ground_material(
	albedo: Color, alt: Color, macro_scale: float, detail_scale: float, slope: float
) -> ShaderMaterial:
	return Landscape.detail_material(albedo, alt, macro_scale, detail_scale, slope)


# --- Course interface ---------------------------------------------------------


## Cold light on warm-lit ice. The geometry here is all albedo, and albedo alone
## cannot make a shadowed ice bank look like ice — the blue ambient against the
## warm sun is what does that, and it is the single largest difference between
## this course and the older ice one.
func decorate_environment(environment: Environment, sun: DirectionalLight3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_bottom_color = IceKit.STONE_DARK
	sky_material.ground_horizon_color = SKY_HORIZON

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOUR
	environment.ambient_light_energy = AMBIENT_SHADED

	environment.fog_enabled = true
	environment.fog_light_color = FOG_COLOUR
	environment.fog_density = FOG_DENSITY
	environment.fog_sun_scatter = FOG_SUN_SCATTER
	# Depth by distance rather than a flat curtain. The river's haze sits at one
	# value across the whole frame; this pulls the far nunataks towards the sky
	# colour and leaves the near bank alone, which is what separates three
	# scenery bands that are otherwise the same shapes at three sizes.
	environment.fog_aerial_perspective = 0.55

	sun.light_color = SUN_COLOUR
	sun.rotation_degrees = SUN_ANGLE
	sun.light_energy = SUN_ENERGY


## Well below the run-out, which is the lowest point on the course. A marble over
## a bank falls through the non-colliding icefield — `Landscape`'s founding rule
## — and keeps going until it reaches this.
func fall_threshold_y() -> float:
	return _point(LENGTH + RUNOFF_LENGTH).y - 14.0


func finish_width() -> float:
	return _half_width_at(LENGTH) * 2.0


func finish_runoff() -> float:
	return RUNOFF_LENGTH


func start_width() -> float:
	return _half_width_at(0.0) * 2.0


## The crevasse floor is meltwater over ice, not open water, and its far wall is
## a ramp. See the class docs: a 3m gap that eliminates is a coin flip on entry
## speed, not racing.
func in_water(_position: Vector3) -> bool:
	return false


## Signed distance to the far edge of the crevasse: negative while short of it,
## positive once past. The race watches the sign flip to call out a marble that
## only just got across.
func jump_clearance(position: Vector3) -> float:
	if curve == null:
		return INF

	var offset := curve.get_closest_offset(position)
	var s := _path.s_at_curve_offset(offset, curve.get_baked_length())
	var far_edge := CREVASSE_S + CREVASSE_WALL + CREVASSE_BED
	if absf(s - far_edge) > 24.0:
		return INF
	return s - far_edge


## Six abreast on a wide spillway, so the field spreads before the first feature
## instead of queuing through it.
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
