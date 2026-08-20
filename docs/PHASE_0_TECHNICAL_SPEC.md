# Marble Jumble — Phase 0 Technical Specification

**Status:** Locked for prototype implementation  
**Date:** 2026-08-20  
**Engine:** Godot 4  
**Purpose:** Prove that a physically simulated marble race is satisfying to watch before expanding the game architecture.

## 1. Phase 0 goal

Build a small, browser-playable prototype that demonstrates the core feel of Marble Jumble:

> **The player releases the field, then watches a genuine physics simulation produce an unpredictable marble race.**

The prototype is deliberately narrow. It should establish camera, physics, track geometry, marble readability and course pacing before tournament/progression systems are built.

The shipped game is intended to be **native mobile (Android/iOS)**. Browser play is a **development/testing target**, not the shipping platform.

## 2. Locked experience

### Display and camera

- Landscape presentation.
- 2.5D / 3D physical course viewed from a **controlled weak-perspective angled camera**.
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

### Physics space and course constraint

Use **genuine 3D rigid-body physics constrained by the physical course geometry**.

The course itself defines where marbles can roll and how they move through slopes, banking, jumps and collisions. Limited helper collision geometry is acceptable where needed for reliable containment, but it must not manipulate race outcomes.

### Marble scale and readability

Marbles should sit between realistic and oversized:

- sufficiently large to read clearly on a phone
- large enough that collisions are visually obvious
- still visually believable as marbles rather than generic balls

Exact diameter is a tuning parameter to be established visually and physically.

The player's marble uses its customized appearance plus a **subtle persistent highlight/rim**. No floating arrow or large marker.

### Race participants

Phase 0 may begin with a single player marble to validate the core physics, but the physical design must be compatible with the eventual 12-marble race.

When 12-marble simulation is introduced:

- all marbles use identical physical attributes
- visual differences are cosmetic
- there is no opponent AI
- all marbles are physics-driven participants
- starting positions are randomized
- starting slots are subtly varied between races

The player does **not** control the marble once released.

## 3. Start sequence

The start should establish the physical presentation language of the game:

1. Marbles roll into a funnel/grid-style starting formation.
2. They settle behind a physical barrier.
3. The player can tap the **barrier itself** to release the field.
4. If the player does nothing, the barrier automatically opens after 5 seconds.
5. Opening the barrier has no effect on the race outcome; it is an agency/presentation interaction.
6. No separate 3–2–1 countdown is required for Phase 0.

The eventual game also includes course roulette and tournament transitions, but those are outside the core Phase 0 physics test unless they are needed for the prototype flow.

## 4. First course: Canyon

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
Gentle S-curve
  ↓
Narrowing / funnel collision section
  ↓
Physics-driven split / merge
  ↓
Small uphill / slowdown
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
- Include one simple split/merge; which route a marble takes is determined naturally by physics.
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

## 5. Falls and finish

For Phase 0:

- use a physical finish area plus a reliable trigger/finish condition for game-state detection
- leaving the playable course means elimination
- the first Canyon should have **low overall fall/elimination risk**; falling is an occasional consequence, not the dominant failure mode
- use a sensible configurable out-of-bounds threshold for initial fall detection and tune it during testing
- stuck detection is **not required for the first physics experiment**; add it only if the prototype demonstrates a real stuck-state problem

## 6. Branching

Phase 0 includes one simple split/merge.

> **Physics determines which route a marble takes.**

There is no player route selection and no AI route planning.

The branch should be simple enough that it tests natural physical divergence rather than becoming a strategic route-selection system.

## 7. Race variability

The course layout remains consistent between runs.

The physical outcome should vary meaningfully because of the simulation and slightly varied starting conditions. The design goal is:

> Players can learn where interesting things happen without being able to reliably predict the winner.

Do not intentionally make the race repeat the same result from run to run.

## 8. Technical baseline

### Physics timestep

Start with Godot's normal/default physics configuration. Tune only after testing simulation stability and performance.

### Renderer

Use the Godot Compatibility renderer initially so browser playability remains a first-class development/testing requirement.

### Native mobile target

The shipped game is intended for **Android/iOS native builds**. Browser support exists to accelerate development and testing and does not need to be a separate shipping platform.

### Browser-first iteration

The prototype should support a rapid loop:

```text
Implement → run in browser → test on phone → tune → repeat
```

Neither desktop browser nor mobile browser is a shipping platform. At least one fast browser loop must exist, plus real native-device testing; whichever browser target proves materially harder to support may be dropped.

Avoid architecture that requires an APK build for every tiny iteration.

### Performance baseline

Start by targeting **low-to-mid-range modern mobile hardware**. Establish a concrete frame-rate target after the first real-device performance test rather than guessing one in advance.

### Architecture constraints

Even in Phase 0, keep these concerns separable:

- marble simulation
- track/course representation
- camera
- course start/reset
- finish/fall detection
- presentation/UI

Do not build tournament, progression, shop, accounts or monetisation as part of this prototype.

## 9. Phase 0 success criteria

The prototype is successful when:

1. A marble rolls with satisfying momentum.
2. Slopes visibly and predictably influence speed.
3. Collisions produce convincing, readable deflections.
4. The camera keeps the player's marble readable while showing ~3–4 seconds ahead.
5. The Canyon course feels visually coherent and physically plausible.
6. The split/merge, jump and rotating bumper produce interesting outcomes without looking scripted.
7. A complete run lands around 20–30 seconds.
8. Falls are possible but not a dominant source of failure.
9. Restarting immediately produces a clean race state.
10. The result makes it worth watching/restarting rather than immediately feeling like a deterministic demo.

## 10. Explicit Phase 0 non-goals

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
