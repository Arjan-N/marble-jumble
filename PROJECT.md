# Marble Jumble — Project Specification

**Status:** Pre-production / prototype planning  
**Version:** 0.3  
**Source of truth:** This document defines current product intent. Agents must not invent gameplay rules that contradict it.

**Document precedence.** Where documents disagree, the more specific and more recent one wins:

```text
DECISIONS.md            (locked decisions, dated)
        ↓
docs/PHASE_0_*.md       (locked scope for the current phase)
        ↓
PROJECT.md              (general product intent)
```

PROJECT.md remains authoritative for anything the other two do not cover.

## 1. Product definition

### One-liner

> **Marble Jumble is a casual mobile spectator game where your marble competes against other marbles in chaotic physics-based courses. Half the field is eliminated after each course until one marble wins the tournament.**

### Core fantasy

> **Watch your marble survive the chaos.**

The player owns one persistent marble. They customize it, then watch it compete. There is no direct control during the race.

The fun comes from anticipation, collisions, near misses, overtakes, unexpected physics, and seeing whether the player's marble survives to the next course.

### Positioning

- Casual
- Spectator / physics
- Family-friendly
- Mobile-first
- Short-session
- Landscape

Target platforms: iOS and Android. Development should remain browser-playable for rapid iteration and phone testing.

---

## 2. Fundamental principles

### 2.1 One persistent player marble

The player owns **one marble** rather than choosing from a roster before each race.

The same marble appears throughout the product:

- home screen
- customization
- every tournament
- results

The player can customize its appearance, but MVP gameplay attributes remain identical to the other marbles.

### 2.2 No direct race control

During a course, the player does not steer, jump, brake, aim, activate abilities, or otherwise influence the marble.

The one permitted interaction is releasing the starting barrier before the race begins (see `DECISIONS.md`). It is presentation and agency only and must not affect the outcome.

### 2.3 Physics is the entertainment

Prioritize:

- collisions
- overtakes
- pile-ups
- jumps
- shortcuts
- near misses
- falls
- obstacles interacting with marbles
- close finishes
- unexpected outcomes

### 2.4 Courses are the main content

Themes matter, but the physical interaction created by a course matters more than the visual theme.

### 2.5 Readability

The player must always be able to identify their marble without covering the race in UI.

---

## 3. Tournament structure

A tournament consists of **three courses / three elimination rounds**:

```text
Round 1
12 marbles → top 6 survive
        ↓
Round 2
6 marbles → top 3 survive
        ↓
Round 3
3 marbles → 1 winner
```

The three rounds should use **three different courses**. Each round selects a course randomly from the player's eligible/unlocked course pool. Repeats are permitted only if the eligible pool is too small to avoid them; the exact rule is TBD (§17).

The player watches one course, then experiences a transition sequence that visually removes eliminated marbles and selects the next course.

### Round result rules

- Round 1: first 6 finishers advance.
- Round 2: first 3 finishers advance.
- Round 3: first finisher wins the tournament.
- If the player's marble is eliminated, the tournament ends.

A marble finishes by reaching the course finish condition.

A marble that leaves the playable course is eliminated.

A marble that becomes stuck may need a timeout to resolve the round. Any such timeout is a **technical safeguard, not a gameplay feature**, and should only be added once a prototype demonstrates a real stuck-state problem. Phase 0 does not require it.

---

## 4. Round transition experience

This is a **core product feature**, not merely a loading screen.

### 4.1 Purpose

Between courses, the player should clearly feel:

1. **Who survived?**
2. **Who was eliminated?**
3. **What course is next?**
4. **The tournament is getting smaller and more intense.**

The transition should create anticipation before the next course starts.

### 4.2 Participant reveal / elimination

Before a course starts, show the current tournament field clearly.

For Round 1, this is 12 marbles.

After each course, the same field is shown again during the transition, with eliminated marbles visually removed/disabled and survivors remaining prominent.

The visual language should communicate elimination without copying Fall Guys' exact presentation, layout, art direction, or UI style.

Possible visual treatment:

- eliminated marble fades, drops away, gets greyed out, or otherwise visually leaves the field
- survivors remain active
- player's marble is clearly identifiable
- the field count updates prominently

The exact animation is TBD.

### 4.3 Next-course roulette

While the elimination sequence is playing, a course selector simultaneously cycles through eligible courses like a fast carousel / roulette.

The selector should:

- show multiple course candidates
- visibly tick/cycle through them
- slow down and land on the selected course
- clearly reveal the winning course
- feel like a deliberate game moment rather than a loading indicator

This is inspired by the **mechanic** of Fall Guys' course carousel, but the visual execution must be original to Marble Jumble.

### 4.4 Suggested combined transition flow

```text
COURSE FINISH
      ↓
Show current tournament field
      ↓
Course roulette begins
      ↓
Eliminated marbles visually leave / deactivate
      ↓
Field count updates
      ↓
Course roulette slows
      ↓
Next course revealed
      ↓
Short anticipation beat
      ↓
NEXT COURSE
```

The elimination animation and course roulette should feel like one coherent transition sequence rather than two unrelated screens.

Whether this is literally one screen or a closely connected two-state sequence is a UI implementation detail, but it should feel seamless to the player.

### 4.5 Round 1 presentation

Before the first course, show all 12 competing marbles.

The player's marble must be clearly identifiable.

Do not force the player to pick a marble.

---

## 5. Core gameplay loop

```text
Home
  ↓
Start tournament
  ↓
Show current field
  ↓
Select next course via roulette
  ↓
Watch course
  ↓
Determine finish order
  ↓
Eliminate non-survivors visually
  ↓
If player's marble eliminated → Results
  ↓
Otherwise select next course
  ↓
Repeat until Round 3 winner
  ↓
Rewards
  ↓
Customize / unlock
  ↓
Play again
```

### Course selection

Each round selects a course randomly from the player's unlocked/eligible course pool.

The exact weighting system is TBD.

The game should avoid repeating a course within the same tournament unless the content pool becomes too small; exact rule TBD.

---

## 6. Course design

### Course duration

Target: approximately **20–30 seconds per course**.

A complete tournament therefore contains three short races plus transitions.

### Course design principle

A course should produce interesting physical events throughout the run rather than mostly straight rolling.

A useful conceptual rhythm:

```text
Start / positioning
        ↓
Early interaction
        ↓
Major obstacle / route split
        ↓
Chaos / collision section
        ↓
Late interaction
        ↓
Finish / final stretch
```

This is a guideline, not a rigid formula.

### Course themes

Initial content directions:

- Canyon
- Space
- Factory
- Ice / Frozen
- Volcano
- Jungle
- Steampunk
- Inside an airplane

Example mechanics:

**Canyon:** ramps, narrow bridges, falling rocks, split paths, jumps  
**Space:** low gravity, force fields, rotating/floating platforms, gaps  
**Factory:** conveyor belts, pistons, rotating mechanisms, moving platforms

### Course representation

Courses should be data-driven:

```text
Course
├── metadata
│   ├── id
│   ├── name
│   ├── theme
│   └── difficulty
├── spawn configuration
├── finish configuration
├── terrain / track segments
└── obstacles
```

Adding a course should not require changing tournament logic.

---

## 7. Player marble and cosmetics

### Identity

The player has one persistent marble with:

- stable internal ID
- current cosmetic configuration
- clear visual identity in races

### Customization

Potential cosmetic categories:

- colours
- patterns
- materials
- visual effects
- decorative elements

### Gameplay attributes

For MVP, all marbles use the same physical attributes.

Do not add speed, mass, size, bounce, special powers, or other gameplay advantages unless explicitly approved later.

---

## 8. Visual direction

### Overall

- 2.5D physical marble tracks
- stylised environments
- strong silhouettes
- readable geometry
- restrained materials
- subtle lighting
- track and physics as visual heroes

### Avoid

- generic AI-looking artwork
- photorealism
- overly glossy mobile-game UI
- excessive gradients
- excessive bloom
- fake glass UI
- RPG-style interfaces
- clutter
- excessive particles
- visual noise that hides the player's marble

### Camera

Locked (`DECISIONS.md`): landscape 2.5D, controlled weak-perspective angled camera, following the player's marble with roughly 3–4 seconds of look-ahead. Exact angle and focal parameters remain TBD.

The eventual camera should:

- keep the player's marble readable
- provide enough look-ahead
- show relevant groups of marbles when useful
- avoid excessive cinematic movement

---

## 9. UI / screen structure

### Home

- Play
- Courses
- Marble
- Shop
- Settings

The player's marble should visibly exist in the home presentation, ideally rolling on a physical track so its customization is always visible.

#### Home layout direction — 2026-08-20

Design inspiration captured for later; not a Phase 0 requirement.

```text
┌─────────────────────────────────────┐
│  ☰                          ⬤ 1,240 │   settings (top-left) · coins (top-right)
│                                     │
│                                     │
│              ( marble )             │   player's marble, rolling, centre stage
│                                     │
│                                     │
├───────────┬─────────────┬───────────┤
│           │             │           │
│           │    RACE     │           │   bottom bar = exactly 3 buttons,
│           │             │           │   spanning full width, middle
└───────────┴─────────────┴───────────┘   slightly larger, starts a race
```

- The bottom bar is the whole bar — three buttons, no gaps or floating tabs.
- The middle button is slightly larger and starts a race.
- Settings collapses to a hamburger at top-left; coins sit top-right.
- The marble rolls in the centre, keeping cosmetics permanently visible.

**Open:** the screen list above has five entries but the bar has two non-race slots. Which two of Courses / Marble / Shop get the flanking buttons — and where the third goes — is undecided.

### Pre-course / transition

- current field of marbles
- player's marble clearly identifiable
- elimination animation
- remaining-count feedback
- next-course roulette
- selected-course reveal

### Gameplay

- physical starting barrier (tap to release, auto-opens after 5s) — no separate 3–2–1 countdown
- race
- minimal race information
- transition to elimination/course selection

### Results

Show at minimum:

- player's finishing position
- whether the marble advanced / was eliminated
- tournament victory or loss
- rewards
- relevant unlock information

Exact visual treatment is TBD.

---

## 10. Progression and economy

### Currency

**Coins** are the initial common currency.

Coins are earned through matches and can be spent on:

- cosmetic marble items
- course unlocks

Exact economy is TBD.

### MVP rule

No gameplay-stat upgrades.

Progression is focused on content and cosmetics.

---

## 11. Technical direction

### Platform strategy

Primary: iOS + Android.  
Development: browser-playable prototype wherever practical.

The development loop should be:

```text
Agent → code → browser → phone test → iterate
```

rather than requiring an APK build for every tiny iteration.

### Technology stack

**Godot 4** (locked 2026-08-20, see `DECISIONS.md`). Prototype with the Compatibility renderer so the browser target stays viable. Exact 4.x version TBD.

It was selected on:

- reliable physics
- mobile performance
- browser support
- 2.5D suitability
- fast iteration
- agentic AI workflow
- straightforward iOS/Android packaging

### Architecture

Keep these concerns separated:

```text
Game
├── Tournament
│   ├── Round management
│   ├── Course selection
│   └── Elimination/results
├── Simulation
│   ├── Marble physics
│   ├── Track physics
│   └── Obstacles
├── Transition
│   ├── Field presentation
│   ├── Elimination animation
│   └── Course roulette
├── Content
│   ├── Courses
│   └── Marble cosmetics
├── Progression
│   ├── Coins
│   └── Unlocks
└── UI
    ├── Home
    ├── Courses
    ├── Marble
    ├── Race
    ├── Results
    └── Settings
```

Physics should not directly own progression or UI state.

### Deterministic simulation

Prefer a seed-driven simulation where practical:

```text
seed + course + starting configuration
        ↓
reproducible simulation
```

This supports reproducible bugs, testing, future replays, daily challenges, and leaderboards.

Reproducibility means *the same seed reproduces the same race*, not that races repeat. Every race draws a fresh seed, so outcomes still vary (see `docs/PHASE_0_TECHNICAL_SPEC.md` §7).

The exact determinism guarantees depend on the physics backend, and Godot's default configuration does not guarantee cross-platform reproducibility. If seeded replay becomes a requirement, it constrains the physics backend choice — decide before building on top of it, not after.

---

## 12. Performance requirements

Mobile is the primary target.

Priorities:

1. stable simulation
2. stable frame rate
3. responsive UI
4. reasonable memory use
5. short loading times

Exact device baseline and frame-rate target are TBD.

---

## 13. MVP roadmap

### Phase 0 — Physics prototype

**Goal:** Prove that watching a physically simulated marble race is satisfying.

See `docs/PHASE_0_TECHNICAL_SPEC.md` for the locked detail. In summary, implement:

- 12 physics-driven marbles, identical attributes, no AI
- one 2.5D Canyon course (20–30s)
- physics
- camera
- barrier start sequence
- finish
- fall/off-course detection
- restart
- browser-playable build
- phone testing

A single-marble build is a valid internal checkpoint for tuning marble feel, but Phase 0 is not complete until the 12-marble race runs — the collision and split/merge success criteria cannot be evaluated without a full field.

Exclude:

- tournament
- progression
- shop
- ads
- IAP
- accounts
- missions
- daily challenges

**Success criterion:** the run feels satisfying enough to restart immediately.

### Phase 1 — Playable MVP

**Goal:** Prove that the spectator tournament is fun.

Implement:

- persistent player marble
- 12-marble simulation
- three courses / three rounds
- 12 → 6 → 3 → 1 elimination
- player elimination
- tournament victory
- pre-course field presentation
- visual elimination transition
- next-course roulette
- results
- home screen
- 3–5 courses
- 3–5 basic cosmetics
- basic coins
- browser + mobile testing

Exclude:

- advertising
- IAP
- online accounts
- online leaderboards
- missions
- seasons
- multiplayer
- user-generated courses
- procedural generation
- marble abilities
- gameplay-stat upgrades

### Phase 2 — Retention

Possible:

- more courses
- more cosmetics
- daily challenge
- missions
- improved rewards/progression

### Phase 3 — Monetisation

Possible:

- shop
- cosmetic purchases
- rewarded ads
- IAP

### Phase 4 — Launch

Possible:

- analytics
- crash reporting
- store listing
- App Store
- Google Play

---

## 14. Non-goals

Do not build without explicit approval:

- direct race controls
- multiplayer races
- online ranking
- online accounts
- user-generated courses
- procedural courses
- marble abilities
- marble stat progression
- pay-to-win mechanics
- seasons / battle passes
- complex social systems
- RPG-style progression
- elaborate inventory systems

---

## 15. Acceptance criteria

### Tournament

Given 12 active marbles, Round 1 produces exactly 6 survivors.

Given 6 active marbles, Round 2 produces exactly 3 survivors.

Given 3 active marbles, Round 3 produces exactly 1 winner.

These hold when enough marbles finish. Because falling off the course also eliminates a marble, a round can produce fewer finishers than it needs survivors — the resolution rule for that case is an open decision (§17) and must not be silently invented.

### Player marble

The same player marble identity and cosmetic configuration persists across tournaments.

### Course transitions

After a course finishes:

1. The current field is presented.
2. Eliminated marbles are visually deactivated/removed.
3. The remaining count is clearly communicated.
4. A roulette cycles through eligible next courses.
5. The roulette settles on the selected next course.
6. The next course starts with the surviving field.

### Restart

Restarting a race or tournament produces a clean initial state with no leaked physics state.

### Tests

Game-state transitions and tournament rules should have automated tests where practical.

---

## 16. Agent development rules

Agents must:

- read `PROJECT.md` before major changes
- keep MVP scope narrow
- never silently implement parking-lot ideas
- separate simulation, game state, transition UI, progression, and presentation
- keep courses data-driven
- make browser testing easy
- make changes in small, testable increments
- add tests for state transitions where practical
- avoid large abstractions before they are justified

For product decisions not covered here, stop and ask rather than inventing a rule.

---

## 17. Open decisions — do not silently guess

1. Exact Godot 4.x version
2. Exact camera angle / focal parameters
3. Exact physics tuning values (friction, restitution, gravity scaling, marble diameter/mass)
4. Determinism guarantees of the physics simulation
5. Survivor rule when fewer marbles finish a round than the round requires (§15)
6. Whether Round 1's course is also chosen by roulette, or only rounds 2 and 3 (§4.5, §5)
7. Course weighting and duplicate-course rules
8. Exact visual language for elimination
9. Exact course-roulette presentation and pacing
10. Reward amounts and unlock prices
11. Course unlock structure
12. Target device baseline and frame-rate target
13. Save model
14. Exact difficulty / desired survival probabilities
15. Exact age positioning

Items resolved since v0.2 — engine, camera/projection, physics model, marble highlight strength, stuck-timeout behaviour — are recorded in `DECISIONS.md`.

---

## 18. Designer questions — grill before overbuilding

### Core fun

1. Why will someone watch the fifth race?
2. What is the emotional payoff of surviving a round?
3. What makes this more compelling than a generic marble run video?
4. What makes losing feel acceptable?

### The player's marble

5. If all marbles have identical physics, why does the player's marble feel meaningfully theirs?
6. How much customization is enough to create attachment?
7. How quickly should a new player get their first cosmetic choice?

### Courses and replayability

8. What changes between repeated runs of the same course?
9. Should players be able to learn courses or should outcomes remain highly unpredictable?
10. How much randomness feels exciting before it feels arbitrary?
11. How many genuinely different courses are needed before repetition becomes a problem?

### Progression

12. What is the first meaningful reward?
13. What should a player have unlocked after ~30 minutes?
14. Are course unlocks exciting enough on their own, or are cosmetics the main progression?

### Difficulty

15. What share of players should typically reach Round 2?
16. What share should reach Round 3?
17. What share should win?
18. Should these probabilities emerge naturally from physics or be deliberately tuned?

### Transition sequence

19. How long should the elimination + course roulette transition last?
20. Should the player see the full field from a fixed viewpoint or get a more tactile 2.5D presentation?
21. Should the selected course be completely random, or should the player have some control over the pool?
22. What should the transition feel like emotionally: suspenseful, playful, dramatic, calm?

### Scope

23. What is the smallest version you would genuinely want another person to play?
24. Which current roadmap idea is most tempting to build too early?
25. What evidence would make you stop the project instead of continuing to polish it?

---

## 19. Parking lot

- online leaderboards
- achievements
- ghost marbles
- seasonal themes
- additional tournament modes
- daily courses / daily challenge
- user-made courses
- generated/procedural courses
- different marble physical properties
- marble special abilities
- additional game modes
- more sophisticated progression

These are not active requirements.

---

## 20. First implementation target

Do not start by building the whole game.

Build:

> **One satisfying marble run playable repeatedly in a phone browser.**

The first prototype must answer:

1. Does the marble movement feel good?
2. Does the 2.5D presentation work on a phone?
3. Is watching the run enjoyable enough to restart immediately?

Only after those answers are positive should the 12-marble tournament and transition system be built.