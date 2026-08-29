# Course recipe — what Jungle River does that the other eight don't

**Status:** extraction, 2026-08-29. **Decides:** nothing on its own. Written
because `JungleRiverCourse` is the only course in the pool that reads as
finished, and the reasons were spread across 1698 lines of one file, a class
header, and a set of constants that record findings rather than intentions.

`jungle_river_course.gd` calls itself "course 9, and the prototype for how
course 10 onwards get built". `terrain_shell.gd` says the same thing from the
other end: the intent is that "Factory, Ice and Volcano reuse the same class
with a different palette and a different `bank_height`, and get the same
grounding for free". Neither says what the *rest* of the recipe is. This does.

Two dimensions, because the gap is in both: how a course sits in the world, and
how it plays as a race.

---

## Dimension 1: grounding

### The problem, in the code's own words

From `terrain_shell.gd`:

> Every course in the pool so far builds a ribbon and then decorates around it.
> […] All four share one failure, and it is the single loudest visual problem
> the game has: the racing surface has an *edge*. Past that edge is either empty
> space or a separate ground mesh that does not meet it, so the track reads as a
> board held up in front of scenery.

`TempleRunCourse` states the same construction as a positive: "the racing
surface is flat, the sides are low ridges rather than walls, and the jungle is
scenery — geometry the marbles never touch, placed past the ridge purely so the
frame is bounded by something." That is the board, described from the inside.

### R1. There is no track — there is a trench, and the bed is its floor

One continuous mesh runs from far ground, down a bank, across the racing bed, up
the far bank and away. Welded vertex to vertex at the crest. No edge exists for
the eye to find, because no edge exists.

Adoption across the pool:

| Course | Lines | `TerrainShell` |
| --- | --- | --- |
| jungle_river | 1698 | ✅ |
| course_builder (Canyon) | 1598 | ✗ |
| jungle | 1549 | ✗ |
| slope | 1234 | ✗ |
| foundry | 1005 | ✗ |
| orbital | 939 | ✗ |
| volcano | 898 | ✗ |
| temple_run | 829 | ✗ |
| glacier_fault | 473 | ✗ |

One of nine. This is the single largest carryable win in the repo.

### R2. Containment is terrain, not fixture

River has no walls. The `BANK` profile *is* the containment — 2.2m of dirt crest,
"nearly two and a half marble diameters, which a marble climbing a 33-degree
slope does not clear at the speeds this course reaches". It drops to 1.7 in the
clearing on purpose, because a section that is open in plan should be open on
camera too, and losing somebody there occasionally is the price.

Compare Temple Run, which has "only a 0.9m ridge to catch a marble thrown wide
rather than a real wall". A ridge is a fixture that fails quietly. A bank is
terrain that reads as the reason the marbles are where they are.

### R3. Bank height varies per corner, and derives from the corner

`CORNER_BANK_GAIN`/`CORNER_BANK_LIMIT` raise the outside bank through a turn
automatically, for the reason `CoursePath` derives camber at all: "a wall that
disagrees with the corner it is in is worse than no wall."

### R4. Scenery in three bands, by what the lens can resolve

`_near_band` / `_mid_band` / `_far_band`, explicitly split by camera legibility —
near is "the only one where a single instance is ever read as an object rather
than as texture". The distant treeline is not geometry at all: it is the far end
of the ground profile rising into frame, which the ground mesh was drawing
anyway. Nine `MultiMesh` groups cover four hundred trees and eight hundred ferns
in about nine draw calls.

### R5. Everything is a profile, not modelled geometry

Elevation, width, banking and jumps are `PITCH` / `WIDTH` / `ROLL` / `BANK` /
`_bed_drop` tables. "A jump is `bed_drop` dipping for three metres; a narrow
section is `WIDTH` getting smaller. Nothing has to be modelled." This is why
1698 lines buys 380m of course with eight features.

### R6. Force mesh vertices onto feature boundaries

`_key_stations()` hands `TerrainShell` the exact distances of the log mound, the
take-off lip, the stream walls and the exit ramp, so a 1.5m mesh step never
smears a 3m lip into a slope. Any course with a jump needs this.

---

## Dimension 2: how it races

### R7. The interest is terrain, not machinery

This is the finding that surprised me most.

| Course | Mechanical obstacles used |
| --- | --- |
| foundry | BoostPad, ConveyorBelt, PaddleDrum, PistonRam, RotatingBumper, StampPress, SwingingHammer, Turntable |
| volcano | BoostPad, FallingRock, RotatingBumper |
| jungle, orbital, course_builder | BoostPad, RotatingBumper |
| slope, glacier_fault, temple_run | RotatingBumper |
| **jungle_river** | **none** |

Seven of eight courses lean on `RotatingBumper`; Foundry stacks eight mechanism
types. The one course that reads as finished uses **zero**. Its features are all
terrain or static prop: a boulder that splits the field, pinch rocks through a
narrow passage, a fallen tree, a cambered sweeper, a stream to jump, a clearing,
a winding run-in.

One course is not a proof, and Foundry's machinery may be doing something River
doesn't need. But it lines up with `PROJECT.md` §2.4 — the physical interaction a
course creates matters more than its theme — and with the grounding thesis: a
bolted-on mechanism is a fixture, and fixtures are what make a course read as
assembled rather than found. **The rotating bumper is the pool's crutch.** Treat
reaching for it as a signal the terrain isn't doing enough work yet.

### R8. Authored camber, because derived camber cannot make a racing line

`BANK_GAIN` gives 6° of camber per degree-per-metre of turn, so a corner at the
0.6°/m the geometry allows comes out at 3.6° — "a cross-fall, not a bank". River
adds 16° on top, putting the sweeper near 20°, "enough that a marble carrying
speed rides up the outside and comes back down ahead of one that took the inside,
which is the whole point of building a corner".

Only River and Orbital have a `ROLL` table at all. Every other course races on
whatever camber the turn rate happens to produce — which is to say, on none.

### R9. Eight features, spaced and named

Named fractions (`SPLIT_AT`, `NARROW_FROM`, `TREE_AT`, `BEND_TO`, `STREAM_AT`,
`CLEARING_TO`) are referenced from the profiles, the fixtures *and* the scenery,
"because three copies of 0.455 in three tables is how a feature and its dressing
drift apart". The result is the §6 rhythm actually delivered end to end.

Temple Run, by contrast, deliberately ships "three beats, one obstacle, no jump,
no spawner" — a defensible first pass, but it is the whole course.

### R10. Width is bounded above by the camera, not by the racing

`Mode.LOW` sees roughly 7m at the focus. At a 7.4m half-width "the bed alone
overflowed the frame and the first render was a screen of bare ground with no
jungle in it at all". Every `WIDTH` entry came down about 15% for the lens, not
for the marbles. Floor of 3.5 half-width, because the Canyon's field died in a
2.0m squeeze and "a narrow section the field cannot physically resolve is a jam
rather than a funnel".

Any course on `TerrainShell` inherits this constraint.

### R11. Ease the descent into corners, always

`PITCH` holds back through the sweeper and the winding run-in, "for the reason
every turning course in this project has had to learn twice: speed into a corner
is what throws a marble at the outside, not what carries it round". Temple Run's
header says the same sentence almost verbatim. This one is already shared
vocabulary — it just needs to stay that way.

### R12. Every trap was found by running a field, never by reading

The constants carry findings, not intentions, and this is the part that cannot be
copied — only repeated:

- **Stream depth 1.05 → 0.75.** At 1.05 the exit ramp rose faster than the
  course descended across it, making the streambed a *basin*: three of twelve
  marbles went in and none came out. Invisible in section — "the ramp looks like
  a way out, and for a marble still carrying speed it is". The rule that
  replaced it: the climb out must be smaller than the course's own descent
  across the same span, so even the exit ramp is downhill in world terms.
- **Camber ease-out moved before the jump.** A marble stalled on the take-off
  lip at fraction 0.661: the lip's net grade is near level, and a near-level
  stretch with 12° of camber is where a slow marble settles against the low side
  and stays. "A jump wants to be entered flat."
- **Pinch rock reach cut by a third, and `PINCH_YAW` added.** A full tournament
  run wedged three marbles at exactly zero velocity and hung the round to its
  95-second cap. `probe_course.gd` had never shown it — at its fixed seed the
  field arrives bunched and shoves itself through. It takes a *round-three field
  of three*, with nobody behind to push, to find it.
- **Pitch floor 6.5 → 7.0.** A run finished 12/12 but strung the field from 66 to
  117 seconds. "Nothing may be shallow enough to hold a marble that arrives
  slowly."

Three of those four are stalls, and two were invisible to the standard probe.
That is the strongest argument yet for the drama/triage probe: **the failures
that matter are pace failures, and a finish count doesn't see them.**

---

## What this implies for the other eight

River is ahead on both dimensions at once, which means porting grounding alone
would leave seven courses looking right and still racing thin. Triage first:

1. **`ROLL` and feature count are cheap to check and cheap to fix.** A course
   with no authored camber and one bumper is not a course that a `TerrainShell`
   port will rescue.
2. **Then port grounding**, in the order the triage says is worth it.
3. **Foundry is the interesting case.** Eight mechanism types and still not
   right; it is the direct test of R7. Either its machinery is the problem, or
   it is the one course where machinery is the point.

## Open tensions this raises

- **Length.** River is built to a 60–90s brief at 380m; `DECISIONS.md` locks
  20–30s and the pool's other courses run 130–190m. The file flags this itself
  and says an entry is needed either way. If River is the template, this is now
  a live product decision, not a footnote — and it interacts with R12, since a
  single stall at 380m is a very long round.
- **The stream doesn't eliminate.** River makes falling in a cost rather than a
  death, arguing "a 2.6m gap that kills is a coin flip on entry speed, which is
  not racing". `CourseBuilder`'s river drowns you. Worth deciding once, globally.
- **`Mode.LOW` is load-bearing for R10 and R4** and still describes itself as
  "Untuned; this is a first try, not a locked value" (`chase_camera.gd:127`),
  while `chase_camera.gd:31` calls it the approved gameplay camera. Course width
  is being authored against a camera whose own file disagrees about whether it is
  settled.
