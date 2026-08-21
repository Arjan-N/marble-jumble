# marble-jumble

A casual mobile spectator game: your marble races eleven others down chaotic
physics courses, and half the field is eliminated after each course.

Currently at **Phase 0** — a physics prototype whose only job is to answer
whether watching a marble race is satisfying enough to restart immediately.

## Documents

| File | Purpose |
| --- | --- |
| [`PROJECT.md`](PROJECT.md) | Product intent, scope, non-goals |
| [`DECISIONS.md`](DECISIONS.md) | Dated decision log |
| [`docs/PHASE_0_TECHNICAL_SPEC.md`](docs/PHASE_0_TECHNICAL_SPEC.md) | Locked scope for the current phase |
| [`docs/CAMERA_SPIKE.md`](docs/CAMERA_SPIKE.md) | Open camera experiment — decides nothing yet |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | Wanted and not yet built, with enough context to pick up cold |

Where they disagree, the more specific and more recent one wins:
`DECISIONS.md` > phase spec > `PROJECT.md`.

## Running the prototype

Requires **Godot 4** (Compatibility renderer, so the browser export stays
viable). Open the project folder in Godot and press F5, or:

```sh
godot --path .
```

Controls, such as they are:

- **Tap/click the red barrier** to release the field. Leave it alone and it
  opens by itself after 5 seconds. Either way the outcome is the same.
- **R** restarts the race.
- **C** cycles the camera between the locked chase framing and the portrait
  overhead one currently being spiked — see
  [`docs/CAMERA_SPIKE.md`](docs/CAMERA_SPIKE.md).

There is no steering. That is the point.

### Measuring a race without watching one

```sh
godot --path . --headless --fixed-fps 60 --disable-render-loop --quit-after 4800
```

`--fixed-fps` is the flag that matters. Without it the engine paces itself
against the wall clock even headless, so a 30-second race costs 30 seconds to
measure; with it, each iteration advances a fixed 1/60s as fast as the CPU
allows and the same race takes **under a second**. `--quit-after` then counts
iterations, so 4800 is 80 seconds of simulated time — enough for a race that
hangs to prove it. `DEBUG_TRACE` in `race_manager.gd` prints the field every two
seconds, and the run ends on a `Race complete` line.

Races are seeded randomly, so a single run says little: spread over five or six
before believing a number.

To look at a frame rather than a number, `--write-movie shots/f.png` writes a PNG
per frame (this one needs a window, so no `--headless`).

## Layout

```text
scenes/
  main.tscn              Entry point; everything else is built at runtime
scripts/
  camera/                Follow camera with look-ahead
  course/                Track geometry, barrier, finish, obstacle
  race/                  Race sequencing and HUD
  simulation/            Marble body and its tuning constants
```

The separation matters more than the file count: the spec requires marble
simulation, course, camera, race sequencing and presentation to stay
independently replaceable, because the course geometry here is scaffolding that
authored meshes will replace.

## State of the prototype

Two courses exist and `race_manager.gd` picks one by a single `const`.

`SlopeCourse` is the one it runs. Straight in plan with a shaped vertical
profile (5°–16°), it carries pillars, a funnel, a split/merge, a staggered jump,
two bumpers and a final funnel. It is not the Canyon and is not trying to be —
staying straight is what keeps it a clean camera test while
[`docs/CAMERA_SPIKE.md`](docs/CAMERA_SPIKE.md) is open, and everything on
`PROJECT.md` §2.3's list can be built without ever turning.

`CourseBuilder` is the Canyon the phase spec actually asks for — curvature,
banking, a swept ribbon — and it still stalls its field at the split/merge.
Phase 0 criteria 5 and 6 are about the Canyon and stay unevaluated until that is
fixed.

Both are generated from primitives along a centreline, not modelled, and both
are scaffolding for authored meshes.

Known bug: roughly one race in six never finishes. Unexplained.

Physics constants live in `scripts/simulation/marble_tuning.gd` and are
expected to change. None of them have been validated on a device yet.

### Pacing

`DECISIONS.md` wants 20–30 seconds per course. At Earth gravity the course took
**53s** — the length was never the problem, the marbles were just slow. They are
0.9m across, some fifty times a real marble, and a world built at that scale
moves in slow motion when things fall at 9.8: real-marble speeds across
fifty-marble distances.

Raising `physics/3d/default_gravity` fixes that, and is the cleanest lever
available because it is a pure time-rescale — the same race, every marble in the
same place, played 1.75x faster. Steepening `GRADE` is not: it changes which
marble wins. Five races per row, measured with the harness above:

| `default_gravity` | Race (avg) | |
| --- | --- | --- |
| 9.8 | 53.4s | far too slow |
| 24 | 30.0s | |
| **30** | **26.8s** | current |
| 36 | 24.0s | |

Steepening the slope instead does much less than it looks: `GRADE` at 13° *and*
16° both landed on 40.9s, because past a point the race is not waiting on the
leader, it is waiting on whichever marble is stuck behind a bumper.

Two things move with gravity and have to be dragged along by hand, since neither
is expressed in gravity's units: `RotatingBumper.revolutions_per_second`, and
anything measured in seconds-of-travel — see `OVERHEAD_LEAD` in
`chase_camera.gd`, which is now in metres for exactly this reason.
