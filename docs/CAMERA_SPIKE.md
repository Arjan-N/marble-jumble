# Camera spike — portrait overhead vs locked chase

**Status:** open experiment, started 2026-08-21. **Not a decision.**
**Decides:** nothing yet. `DECISIONS.md` is unchanged and still governs.

## Why this exists

`DECISIONS.md` (2026-08-20) locks the projection:

> **Camera/projection:** landscape 2.5D using a controlled, weak-perspective
> angled camera rather than an orthographic/isometric or side-on view. The
> course runs longitudinally/down-course, generally away from the player.

That lock has a problem the prototype exposed. A camera sitting 14m behind one
marble shows you that marble and perhaps three others. The field is twelve.
Everything the tournament layer will eventually need to show — who is ahead, who
is near the cut line, who just got knocked out of the running — is off-screen or
foreshortened into a clump. `PROJECT.md` §2.5 asks that the player always be
able to identify their marble; it does not ask that the other eleven be
invisible, and §1 positions the game as **spectator** and **mobile-first**.

A near-top-down portrait framing shows the whole field at once and matches how a
phone is actually held. So: test it, on a phone, before touching the lock.

`PROJECT.md` §17 lists "exact camera angle / focal parameters" as open. The
projection itself is not open, which is exactly why this is a spike and not a
change.

## What was built

Deliberately cheap and deliberately reversible. No course geometry was touched.

| File | Change |
| --- | --- |
| `scripts/camera/chase_camera.gd` | `Mode.OVERHEAD` added alongside the locked `Mode.CHASE` |
| `project.godot` | Portrait viewport + orientation, with a desktop window override |
| `scripts/race/race_manager.gd` | `C` cycles camera mode; HUD shows which is active |

Press **C** mid-race to switch. The switch snaps rather than sweeps, so you get
both framings of the same instant instead of a transition between them.

## What to look for on the phone

The first four are the ones the spike is actually asking about. The fifth is the
known risk, and the sixth is the only one that can end the experiment.

1. **Field readability.** Can you tell, without hunting, roughly where you sit in
   the field? This is the whole argument for overhead, and the thing chase
   cannot do.
2. **Your marble.** Can you still find it instantly? At 34m out, marbles are
   small. `DECISIONS.md` rules out arrows and oversized markers, so if the
   answer is no, the fix is marble scale or highlight strength — not a marker.
3. **Look-ahead.** Phase 0 acceptance criterion 4 wants ~3–4 seconds of course
   visible ahead. `OVERHEAD_LEAD_SECONDS` biases the focus forward; the frame's
   long axis supplies the rest. Check it still holds at full speed, not at the
   start line.
4. **Track width.** The lens is sized for ~17m across against a widest-case ~9m
   of floor plus outward-leaning walls. Confirm nothing clips on the S-curve,
   where banking swings the walls furthest.
5. **Does the course still read as descending?** This is the expected failure.
   The course drops ~35m over ~170m of `-Z` (`course_builder.gd:62-75`), and
   overhead looks straight down the axis that descent lives on. `OVERHEAD_PITCH`
   is held at 68° rather than 90° specifically to keep some obliquity. If the
   course reads flat and speed stops being legible, that is the finding — and it
   points at option A below rather than at a pitch tweak.
6. **Would you restart it?** Phase 0's actual success criterion. If overhead
   wins on everything above and still feels worse to watch, overhead loses.

## Desktop render, 2026-08-21 (before any phone test)

Rendered via `--write-movie`, portrait 450x800, first 20s of a race.

- **Field readability holds.** All 12 marbles legible at once through the
  S-curve. This is the thing chase cannot do, and it works.
- **Two framing bugs, fixed.** The lens was 28 degrees, leaving the track on
  about a third of the frame; now 22. Yaw came from the player's instantaneous
  velocity and swung the track diagonally across the frame as the field spread;
  it now rides the course tangent via `_course_lead()`, which also centres the
  track rather than the player.
- **Question 5 already failed on desktop.** The course reads as a flat beige
  ribbon. A 12 degree descent through a banked S-curve is invisible; the only
  depth cue in frame is the marbles' own shadows. Pitch is the obvious knob and
  it is unlikely to be enough — the descent is *along the view axis*, so no
  pitch that still shows the field will recover it.

That last point is the finding. The phone test is now about whether flatness is
disqualifying, not whether overhead is readable — it is.

## Turned to face up-course, 2026-08-21

The camera now sits **down**-course of its focus and looks back up the track, so
the field runs at the lens rather than away from it. In the code this is one
character — `desired +=` where a following camera has `-=` — but it inverts what
the frame is for, so the notes above about a camera looking down-course no longer
describe what is on screen.

The reason is question 5. Looking down-course, the descent runs *along the view
axis*, which is exactly the direction a camera cannot show; that is why the
course read as a flat ribbon and why no pitch was going to fix it. Turned round,
the same descent runs towards the viewer.

What the render shows:

- **The field reads better than it did.** Marbles arrive out of the top of the
  frame and grow as they come, and a marble passing the lens is unambiguously
  ahead of you. The rows of pillars now stand up out of the surface with their
  own shadows instead of being seen down onto.
- **The frame got shorter, and this is geometric.** It spans about **22m** of
  course, ~11m either side of the focus, against ~30m facing the other way. A
  slope falling away from the lens stretches the far ground out; the same slope
  rising towards the lens cuts the view off early. Nothing but a wider lens
  recovers it — distance does not, because holding the track at frame width
  scales coverage back down again, and pitch trades one edge against the other
  for no net gain.
- **So criterion 3 is not met facing this way.** ~16m of course sits ahead of the
  marble, which at the new pace is about 1.5s, not the 3–4s the phase spec asks
  for. That criterion was written for a camera looking where the marble is going.
  A camera looking back at a field that cannot steer may simply not be the thing
  it was meant to constrain — but that is a judgement for the phone test, and it
  is now the sharpest question this spike has.
- **A wider lens is the lever if it fails.** `OVERHEAD_FOV := 30.0` covers ~30m
  of course, brings the second pillar row into shot, and leaves the track using
  about 85% of the frame width with ground either side rather than filling it
  edge to edge. Marbles get smaller but stayed legible in the render. One line,
  and worth trying before concluding anything about look-ahead.

`OVERHEAD_LEAD_SECONDS` is gone, replaced by `OVERHEAD_LEAD` in metres. Seconds
of travel made sense when the lead was pushing the marble *down* a frame that
stretched with the course; against a fixed 22m patch of ground it only slid the
marble towards the top edge until it left, which at 30 gravity happens fast. The
first render at 15m had the entire field off-screen.

## Knobs

All in `scripts/camera/chase_camera.gd`, all tagged `Mode.OVERHEAD`:

| Constant | Now | Effect |
| --- | --- | --- |
| `OVERHEAD_PITCH` | 68° | Toward 90° = flatter, more top-down, less elevation |
| `OVERHEAD_DISTANCE` | 34m | Further = weaker perspective, smaller marbles |
| `OVERHEAD_FOV` | 22° | Horizontal, not vertical — sets both track-width and how much course is in shot |
| `OVERHEAD_LEAD` | 5m | Higher pushes the marble **up** the frame — it was down, before the camera turned round |

`OVERHEAD_FOV` is horizontal because `set_mode` puts the camera in `KEEP_WIDTH`.
Under Godot's default `KEEP_HEIGHT` the horizontal angle narrows with the aspect
ratio, and on a tall phone the walls clip off both sides.

## How to revert

Delete `Mode.OVERHEAD` and the constants tagged with it, the `KEY_C` branch and
`_camera_debug()` in `race_manager.gd`, and the marked portrait block in
`project.godot`. The locked camera is then back with no other trace. The class
keeps the name `ChaseCamera` through the spike for this reason — renaming it
would make reverting a bigger edit than deleting a mode.

## Outcomes

Whatever happens, the result gets written down before more code is built on it.

- **Overhead clearly wins** → new dated `DECISIONS.md` entry superseding the
  camera/projection and landscape lines, plus `PROJECT.md` §1 and §8. Then
  consider **option A**: re-author `CONTROL_POINTS` so descent runs down-screen
  (a tilted table, pinball-style) so the course reads its own gradient again.
  The swept ribbon, banking, profile, split divider, jump gap and bumper all
  survive that; only the centreline moves.
- **Chase clearly wins** → revert as above, keep the lock, and get the field
  readability from the HUD layer instead: name labels, live standings, cut line.
  That work is independent of the projection and is Phase 1 either way.
- **Neither is clearly better** → the projection is not the problem. Revert and
  spend the time on the HUD layer.

## Unrelated, but blocking a real test

`run.log` shows the field dead-stopped at `z=-110.8` — the split/merge, ratio
≈0.66 — with `v=0.00` for 40+ seconds, never finishing. A course that stalls
cannot answer question 3 or question 6 above. If that reproduces, fix it first;
the camera test is not meaningful on a race that does not finish.

**Mostly resolved for the current course, 2026-08-21.** That log is the Canyon
(`course_builder.gd`), which `race_manager.gd` no longer runs. `SlopeCourse`
finishes 12/12 in roughly 24–32s and the camera test is unblocked.

But not every time. Roughly one race in six never finishes inside 80 seconds —
seen at both `BOUNCE := 0.1` and `0.3`, so raising restitution reduced how hard
marbles are stopped without closing the hole. Something on this course can still
trap a marble permanently. That is a real bug and it is unfixed; it is filed
here rather than chased because it does not block the camera question, which is
about what a race that *does* run looks like. It will block any pacing work.
The Canyon's own stall is separate, still there, and still unexplained.
