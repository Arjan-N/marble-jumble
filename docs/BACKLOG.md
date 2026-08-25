# Backlog — wanted, not yet built

Things that are worth doing and are deliberately not done yet, with enough
context to pick them up cold. Distinct from `PROJECT.md` §19's parking lot, which
is for ideas explicitly **not** wanted as requirements — everything here *is*
wanted, it just has not been built.

Distinct from `PROJECT.md` §17 too: those are decisions nobody has taken. These
are decisions already implied by the spec, waiting on work.

---

## Sound

**Status:** implemented, 2026-08-22. **Wanted since:** 2026-08-21.

`SoundManager`/`SoundSynth` give the player marble's impacts a procedurally
synthesised tone (pitch by impact energy), triggered off `Marble.collided`.
Synthesis was chosen over sampled assets to stay code-only and vary per hit
rather than audibly repeat across twelve marbles colliding constantly.

**Not yet done:** timbre does not vary by surface. `SlopeCourse.SURFACES`
carries surface identity but it is not exposed through `Course`, so
`SoundManager` cannot yet ask what a marble is rolling on. Also only the
player's own impacts sound — the other eleven marbles are silent.

## Screens: round-start and shop

**Status:** shop built, round-start not started. **Wanted since:** 2026-08-22,
when the home screen (below) needed somewhere for its buttons to lead.

`docs/ui-reference/UI_VISUAL_REFERENCES.md` specifies three screens: home,
round-start (course carousel + 4x3 marble grid, no marble selection), and
shop (cosmetic marble/course unlocks).

Home and shop are built. `PlayerProfile` (autoload) holds coins and the
equipped skin, so a purchase now shows on the track and on the home screen's
marble — both were hardcoded colours before. A finished tournament awards
coins and returns to the home screen instead of parking in a dead race scene.

**Not yet done:** round-start is still missing — `HomeScreen`'s START skips
straight into `scenes/main.tscn` and MARBLE still shows a "Coming soon" toast.
The shop's own visuals are placeholder; it is the flow that is real. Reward
amounts are invented (`REWARD_*` in `race_manager.gd`) — `PROJECT.md` §17
item 10 still has the real values TBD.

## Round transition: the course roulette

**Status:** results half built, roulette not started. **Wanted since:**
`PROJECT.md` §4, which calls the whole between-rounds moment a core product
feature rather than a loading screen.

§4.4's flow is: show the field → run the course roulette → eliminate → update
the count → reveal the next course → start it. `RoundResultsScreen`
(`scripts/ui/round_results_screen.gd`) now does everything up to the reveal:
it presents the finished field as two rows of the real 3D marbles, marks the
eliminated, states the player's position, pays and animates the reward when a
tournament ends, and — the part that makes it a moment rather than a pause —
holds until the player presses CONTINUE.

`tools/preview_results.gd` renders it on its own with a synthetic result, for
the two states a real tournament takes several rounds to reach.

**Not yet done:** the roulette itself (§4.3). `race_manager._pick_course`
still chooses the next course silently, inside `_start_race`, *after* the
player has already pressed CONTINUE — so the reveal has nowhere to happen. It
would need the pick hoisted out of `_start_race` and handed to the results
screen to play out before the scene changes.

## Volcano Run: visual identity

**Status:** course built, presentation not. **Wanted since:** 2026-08-22
(issues #2 and #3).

`VolcanoCourse` implements the full seven-section physical course from issue
#2 — Ash Slope, Cracking Ridge, Lava Crossing, The Eruption, Lava Tube,
Obsidian Drop, Final Escape — with a physics-driven split/merge, falling-rock
debris, a rotating bumper and the Obsidian Drop kicker. It is in
`race_manager.gd`'s `COURSE_POOL` and races correctly.

What is missing is issue #3: it does not yet **look** like a volcano. Baseline
stills (`tools\shots.ps1`, 2026-08-22) show:

- The sky is a blue-grey daytime `ProceduralSkyMaterial` with a neutral midday
  sun. It is set in `race_manager._setup_environment` and is shared by every
  course, so Volcano Run races under the same sky as the canyon. This is the
  single largest reason it does not read as a volcano.
- **The eruption is not in shot.** `PLUME_OFFSET` stands the cone 20m to the
  side; the overhead camera's frame is roughly 13m across, so the course's
  signature spectacle never appears at ratio 0.50 where it fires.
- Ash Slope (0.06), Cracking Ridge (0.20) and Final Escape (0.94) render as a
  featureless brown plane against empty sky — no walls, no cliffs, no lava, no
  background layers at all. Only the Lava Crossing and Lava Tube have any
  vertical geometry framing the track.
- At the Obsidian Drop (0.79) the lava floor reads as a flat orange stripe
  laid across the frame rather than as molten rock far below, and a plume
  smoke puff intersects the shot as a murky olive slab.

Issue #3's direction is explicitly **not** more 3D geometry: simple physical
course plus layered 2D/2.5D volcanic fiction (background silhouettes, smoke
columns, lavafalls, midground cliffs) and a lava-driven palette and light.
