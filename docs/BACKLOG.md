# Backlog — wanted, not yet built

Things that are worth doing and are deliberately not done yet, with enough
context to pick them up cold. Distinct from `PROJECT.md` §19's parking lot, which
is for ideas explicitly **not** wanted as requirements — everything here *is*
wanted, it just has not been built.

Distinct from `PROJECT.md` §17 too: those are decisions nobody has taken. These
are decisions already implied by the spec, waiting on work.

---

## Sound

**Status:** not started. **Wanted since:** 2026-08-21.

The prototype is silent, and this is the largest single gap between what it is
and what it is trying to be.

`PROJECT.md` §2.3 says physics is the entertainment and lists collisions first.
A marble race is a *tactile* thing, and almost all of that is carried by sound:
the click of glass on glass, a rumble on rough stone that goes quiet on the
smooth sections, the clack of a bumper arm connecting, the moment a marble stops
making noise because it has left the track. None of it exists. Watching the
current build with the volume up and the volume down is the same experience.

It would do more for how the race *feels* than any further geometry. The course
now has a shaped profile, mixed surfaces, a split, a staggered jump and a
bridge; adding a seventh feature is worth less than making the six that exist
audible.

**Not blocked by any decision.** Audio is not on the Phase 0 non-goals list
(§10 of the phase spec), and nothing in `DECISIONS.md` speaks to it.

**Open question, needs an answer before starting:** real assets or synthesised?

- *Assets* sound better and cost sourcing, licensing and repository weight, and
  the repo currently has no binary content at all.
- *Synthesis* keeps the project code-only and procedurally variable — pitch by
  impact energy, timbre by surface — which suits twelve marbles colliding
  constantly far better than a handful of fixed samples that will audibly
  repeat. It is more work and it can sound cheap if done badly.

Synthesis is probably right for a prototype whose whole point is that every
collision is different. Worth prototyping one impact sound before committing.

**Where it would hook in:** `Marble` would need contact reporting
(`max_contacts_reported`, `contact_monitor`), which is currently off and is not
free at twelve bodies — measure before assuming it is fine. Surface identity for
timbre already exists in `SlopeCourse.SURFACES` but is not exposed through
`Course`; it would need a way to ask what a marble is rolling on.
