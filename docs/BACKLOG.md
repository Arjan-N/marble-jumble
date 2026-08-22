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

**Status:** not started. **Wanted since:** 2026-08-22, when the home screen
(below) needed somewhere for its buttons to lead.

`docs/ui-reference/UI_VISUAL_REFERENCES.md` specifies three screens: home,
round-start (course carousel + 4x3 marble grid, no marble selection), and
shop (cosmetic marble/course unlocks). Only home is built. `HomeScreen`'s
START button skips straight to the race (`scenes/main.tscn`); MARBLE and
STORE show a "Coming soon" toast. There is also no save/profile system yet,
so the home screen's rolling marble uses a hardcoded stand-in colour rather
than the player's actual customisation.
