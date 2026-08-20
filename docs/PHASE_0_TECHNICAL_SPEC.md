# Marble Jumble — Phase 0 Technical Specification

**Status:** Locked for prototype implementation  
**Date:** 2026-08-20  
**Engine:** Godot 4  
**Purpose:** Prove that a physically simulated marble race is satisfying to watch before expanding the game architecture.

## 1. Phase 0 goal

Build a small, browser-playable prototype that demonstrates the core feel of Marble Jumble:

> **The player releases the field, then watches a genuine physics simulation produce an unpredictable marble race.**

The prototype is deliberately narrow. It should establish camera, physics, track geometry, marble readability and course pacing before tournament/progression systems are built.

## 2. Locked experience

### Display and camera

- Landscape presentation.
- 2.5D / 3D physical course viewed from a controlled angled perspective.
- The course progresses generally longitudinally/down-course, away from the player.
- The camera follows the player's marble.
- Camera movement should include deliberate look-ahead rather than simply centering the player's marble.
- Target look-ahead: approximately 3–4 seconds of upcoming course.
- Avoid excessive cinematic camera movement.

### Physics feel

Physics is **stylised-realistic**:

- believable gravity
- believable momentum
- believable friction
- convincing collisions
- visible response to slopes and obstacles
- occasional surprising outcomes

Real-world accuracy is not the goal. Physics constants may be tuned for entertainment and readability.

### Simulation rule

Phase 0 uses **fully physical simulation**.

Do not use:

- scripted race outcomes
- hidden rubber-banding
- invisible corrective forces
- deterministic winner selection
- AI steering

The baseline prototype should reveal what genuine physics produces before any assistance is considered.

### Marble scale and readability

Marbles should sit between realistic and oversized:

- sufficiently large to read clearly on a phone
- large enough that collisions are visually obvious
- still visually believable as marbles rather than generic balls

Exact diameter is a tuning parameter to be established visually and physically.

The player's marble uses its customized appearance plus a **subtle persistent highlight/rim**. No floating arrow or large marker.

## 3. Race participants

Phase 0 should validate the physics with a single player marble first, but the physical design must be compatible with the eventual 12-marble race.

When 12-marble simulation is introduced:

- all marbles use identical physical attributes
- visual differences are cosmetic
- there is no opponent AI
- all marbles are physics-driven participants
- starting positions are randomized
- starting slots are subtly varied between races

The player does **not** control the marble once released.

## 4. Start sequence

The start should establish the physical presentation language of the game:

1. Marbles roll into a funnel/grid-style starting formation.
2. They settle behind a physical barrier.
3. The player can tap the barrier to release the field.
4. If the player does nothing, the barrier automatically opens after 5 seconds.
5. Opening the barrier has no effect on the race outcome; it is an agency/presentation interaction.

The eventual game also includes course roulette and tournament transitions, but those are outside the core Phase 0 physics test unless they are needed for the prototype flow.

## 5. First course: Canyon

The first course should be a single approximately **20–30 second** Canyon run.

The course is intentionally simple. Its job is to test whether watching physical marble movement is satisfying.

Required rhythm:

```text
Start
  ↓
Gentle downhill opening
  ↓
Wide rolling section
  ↓
Narrowing / funnel collision section
  ↓
Short meaningful jump
  ↓
Rotating bumper
  ↓
Short final stretch
  ↓
Finish
```

### Geometry

- Mostly a solid trough/channel.
- A few constructed sections are allowed.
- Track is generally wide enough for marbles to spread out.
- Narrow sections are deliberate collision points, not the default width.
- Include one gentle S-curve.
- Curves may be naturally banked.
- Mostly downhill overall.
- Include flat terrain and one small uphill/slowdown section.
- Open edges should be possible, but unintended falls should be kept to a minimum in the first course.

### Surface treatment

Use mixed surfaces:

- rough Canyon/stone/concrete-like sections
- smoother constructed track sections

Surface differences may affect friction/speed, but should remain subtle enough that the physics remain understandable.

### Jump

The first jump is a **meaningful but short** jump:

- clear airborne moment
- landing position can differ
- not a stunt-game spectacle

### Obstacle

Use one **rotating bumper** as the active obstacle.

Keep the mechanism mechanically simple so the prototype tests marble/obstacle collision physics rather than an elaborate obstacle system.

## 6. Falls and finish

For Phase 0:

- reaching the finish condition determines completion
- leaving the playable course means elimination
- the course should minimize accidental/out-of-bounds deaths
- stuck timeout behaviour remains configurable/TBD

## 7. Branching

The Phase 0 course does not need a major strategic branch, but any split/merge geometry introduced later should follow this rule:

> **Physics determines which route a marble takes.**

There is no player route selection and no AI route planning.

The long-term game may develop branches into risk/reward structures, but Phase 0 should not depend on that system.

## 8. Race variability

The course layout remains consistent between runs.

The physical outcome should vary meaningfully because of the simulation and slightly varied starting conditions. The design goal is:

> Players can learn where interesting things happen without being able to reliably predict the winner.

Do not intentionally make the race repeat the same result from run to run.

## 9. Technical baseline

### Physics timestep

Start with Godot's normal/default physics configuration. Tune only after testing simulation stability and performance.

### Renderer

Use the Godot Compatibility renderer initially so browser playability remains a first-class requirement.

### Browser-first iteration

The prototype should support a rapid loop:

```text
Implement → run in browser → test on phone → tune → repeat
```

Avoid architecture that requires an APK build for every tiny iteration.

### Architecture constraints

Even in Phase 0, keep these concerns separable:

- marble simulation
- track/course representation
- camera
- course start/reset
- finish/fall detection
- presentation/UI

Do not build tournament, progression, shop, accounts or monetisation as part of this prototype.

## 10. Phase 0 success criteria

The prototype is successful when:

1. A marble rolls with satisfying momentum.
2. Slopes visibly and predictably influence speed.
3. Collisions produce convincing, readable deflections.
4. The camera keeps the player's marble readable while showing ~3–4 seconds ahead.
5. The Canyon course feels visually coherent and physically plausible.
6. The jump and rotating bumper produce interesting outcomes without looking scripted.
7. A complete run lands around 20–30 seconds.
8. Falls are possible but not a dominant source of failure.
9. Restarting immediately produces a clean race state.
10. The result makes it worth watching/restarting rather than immediately feeling like a deterministic demo.

## 11. Explicit Phase 0 non-goals

Do not add without a separate decision:

- race steering
- player nudging
- boost/brake abilities
- opponent AI
- different marble gameplay stats
- tournament elimination logic
- course progression/unlocks
- coins/shop
- ads/IAP
- online features
- multiplayer
- procedural course generation
- large obstacle library
