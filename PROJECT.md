# Marble Jumble — Project Specification

**Status:** Pre-production / prototype planning  
**Version:** 0.1  
**Source of truth:** This document defines the current product intent. Code should not invent product rules that contradict it.

---

## 1. Product definition

### One-liner

> Marble Jumble is a casual mobile spectator game where 12 marbles race through chaotic physics-based courses. The player owns one persistent marble, watches it compete, and tries to survive three elimination rounds until one marble is crowned the winner.

### Core fantasy

> **Watch your marble survive the chaos.**

The player does not directly control the marble during a race. The entertainment comes from anticipation, physics, collisions, near misses, unexpected outcomes, and seeing whether the player's marble survives to the next round.

### Genre

- Casual
- Spectator / physics
- Family-friendly
- Mobile-first
- Short-session

### Target platform

- Primary: iOS and Android
- Development/testing: browser prototype first
- Orientation: landscape

---

## 2. Fundamental product principles

These principles should guide product and technical decisions.

### 2.1 The player's marble is persistent

The player owns **one marble**.

The player does not choose a different marble before each tournament.

The same marble should appear:

- on the home screen
- in customization
- in every tournament
- in results
- anywhere else the player's marble is represented

This persistence is important for attachment and identity.

### 2.2 The player does not control the race

During the race, there is no steering, jumping, braking, aiming, ability activation, or other direct player control.

The player watches the simulation and reacts emotionally to what happens.

### 2.3 Physics is the core entertainment

The game should feel physical rather than scripted.

Important moments include:

- collisions
- overtakes
- pile-ups
- jumps
- shortcuts
- near misses
- falls
- getting stuck and escaping
- unexpected interactions with obstacles
- close finishes

### 2.4 Courses are the main long-term content

Themes are useful, but courses are the actual gameplay content.

A good course should create interesting physical interactions rather than merely providing a visual reskin.

### 2.5 The game should remain readable

The player must be able to identify their own marble during a chaotic race.

The camera and visual treatment should make the marble's current state understandable without covering the screen with UI.

---

## 3. Core gameplay

### 3.1 Tournament structure

Every tournament consists of three elimination rounds:

```text
12 marbles
    ↓
Round 1: top 6 advance
    ↓
6 marbles
    ↓
Round 2: top 3 advance
    ↓
3 marbles
    ↓
Round 3: 1 winner
```

The player's persistent marble is always one of the competing marbles.

### 3.2 Round rules

For each round:

1. Spawn the required marbles at the start area.
2. Run the physics simulation.
3. Record finish order based on reaching the finish condition.
4. Eliminate all marbles outside the advancing positions.
5. If the player's marble is eliminated, the tournament ends.
6. If the player's marble advances, start the next round.
7. The tournament ends when one marble wins Round 3.

### 3.3 Finish and elimination

Initial rule:

- A marble finishes when it reaches the course's finish trigger.
- A marble that leaves the playable course is eliminated.
- A marble that becomes permanently stuck should be eliminated after a timeout.

Exact timeout and edge-case handling are TBD and should be kept configurable.

### 3.4 Race length

Target race duration: approximately **30–40 seconds per round**.

This is a target, not a hard requirement. Courses should be allowed to vary somewhat as long as the experience remains suitable for short mobile sessions.

### 3.5 Player outcome

The player can experience four meaningful states:

- **Round 1 survival:** player's marble finishes in the top 6
- **Round 2 survival:** player's marble finishes in the top 3
- **Final round:** player's marble is one of the final 3
- **Tournament victory:** player's marble finishes first

The tournament ends immediately from the player's perspective when their marble is eliminated.

---

## 4. Core gameplay loop

```text
Start tournament
      ↓
Select a random unlocked course
      ↓
12 marbles enter
      ↓
Watch Round 1
      ↓
Survive or get eliminated
      ↓
Watch Round 2 if alive
      ↓
Survive or get eliminated
      ↓
Watch Round 3 if alive
      ↓
Win / lose
      ↓
Earn rewards
      ↓
Customize marble / unlock content
      ↓
Play again
```

### Random course selection

For the MVP, a course should be randomly selected from the player's unlocked courses.

The exact weighting system is TBD.

---

## 5. Session design

The game should be usable in very short sessions.

A complete tournament should generally feel like a quick burst rather than a long commitment.

Target:

- one round: ~30–40 seconds
- complete tournament: roughly 30–120 seconds depending on progression and result screens

Avoid unnecessary loading, menu friction, or long transitions.

---

## 6. Player marble

### 6.1 Identity

The player has one persistent marble.

It should have:

- a stable internal ID
- a current appearance configuration
- a clear visual identity during races

### 6.2 Customization

Cosmetics are expected to evolve from simple to more expressive.

Possible categories:

- colours
- patterns
- materials
- visual effects
- decorative elements

The exact system is intentionally not fully defined yet.

### 6.3 Gameplay attributes

For the MVP, the player's marble and AI marbles should have **the same physical attributes**.

Do not implement gameplay advantages, stats, upgrades, special abilities, size differences, weight differences, bounce differences, speed differences, etc. unless explicitly added to the specification later.

This keeps the MVP focused on the course and physics.

---

## 7. Courses

Courses should be treated as reusable data-driven content rather than hard-coded special cases.

### 7.1 Course themes

Initial ideas:

- Canyon
- Space
- Factory
- Ice / Frozen
- Volcano
- Jungle
- Steampunk
- Airplane / inside an airplane

Themes are a content direction, not a requirement that every theme be implemented immediately.

### 7.2 Example course mechanics

**Canyon**
- ramps
- narrow bridges
- falling rocks
- split paths
- jumps

**Space**
- low gravity
- force fields
- rotating or floating platforms
- gaps

**Factory**
- conveyor belts
- pistons
- rotating mechanisms
- moving platforms

### 7.3 Course design principle

Courses should create a sequence of interesting physical moments.

A target 30–40 second course should not be a long straight section with little happening.

A useful conceptual rhythm is:

```text
Start / positioning
        ↓
Early interaction
        ↓
Major obstacle or route choice
        ↓
Chaos / collision section
        ↓
Late interaction
        ↓
Finish / final stretch
```

This is a design guideline, not a rigid formula.

### 7.4 Course data

Courses should be represented as data so that new content can be created without modifying core gameplay code.

Conceptually:

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

The exact format depends on the chosen engine.

---

## 8. Visual direction

### 8.1 Overall direction

- 2.5D physical marble tracks
- stylised environments
- strong silhouettes
- readable geometry
- restrained materials
- subtle lighting
- physical rather than UI-heavy presentation

### 8.2 Avoid

- generic AI-looking artwork
- photorealism
- overly glossy mobile-game presentation
- excessive gradients
- excessive bloom
- fake glass UI
- RPG-style interfaces
- clutter
- excessive particle effects
- visual noise that makes the marble difficult to identify

### 8.3 Track is the visual hero

The course and its physical interactions should dominate the visual experience.

The environment should support the simulation rather than distract from it.

### 8.4 Camera

Camera design is currently **TBD** and should not be over-engineered before gameplay is proven.

It should eventually support:

- clear visibility of the player's marble
- enough look-ahead to understand upcoming obstacles
- readable views of relevant groups of marbles
- smooth transitions without excessive cinematic movement

---

## 9. UI / screen structure

### Home

Primary sections:

- Play
- Courses
- Marble
- Shop
- Settings

The player's marble should visibly exist in the home presentation, ideally moving/rolling over a track so the user can immediately see its current appearance.

### Gameplay

- countdown
- race
- elimination / round transition
- results

Gameplay UI should be minimal.

The current intended experience is to watch the simulation rather than monitor a large dashboard.

### Results

Results should clearly communicate:

- player's marble finishing position
- whether it advanced
- whether the tournament was won/lost
- rewards earned
- progression/unlock information where relevant

Exact presentation is TBD.

---

## 10. Progression and economy

### 10.1 Currency

Initial currency:

**Coins** — common currency earned through playing matches.

Coins can be used for:

- cosmetic marble items
- course unlocks

Exact pricing and economy are TBD.

### 10.2 No gameplay upgrades in MVP

The MVP should not contain power progression that changes the marble's physics.

The initial progression model is intentionally cosmetic/content-focused.

### 10.3 Unlocks

Potential unlock categories:

- additional courses
- marble colours
- patterns
- materials
- effects

Exact unlock structure is TBD.

---

## 11. Technical direction

### 11.1 Platform strategy

The game must eventually run on:

- iOS
- Android

During development, there should be a browser-playable prototype whenever technically practical.

The browser prototype is important because fast iteration and phone testing are priorities.

### 11.2 Technology stack

**TBD.**

The stack should be selected based on:

- reliable physics
- good mobile performance
- fast iteration
- browser deployment/prototyping
- suitability for 2.5D presentation
- agentic AI development workflow
- straightforward packaging for iOS and Android

Do not lock the stack in code until this decision is made.

### 11.3 Simulation architecture

Keep the following concerns separated:

```text
Game
├── Tournament
│   ├── Round management
│   └── Elimination / results
│
├── Simulation
│   ├── Marble physics
│   ├── Track physics
│   └── Obstacles
│
├── Content
│   ├── Courses
│   └── Marble cosmetics
│
├── Progression
│   ├── Coins
│   └── Unlocks
│
└── UI
    ├── Home
    ├── Courses
    ├── Marble
    ├── Race
    ├── Results
    └── Settings
```

The physics simulation should not directly own progression, shop logic, or menu state.

### 11.4 Deterministic simulation

A race should be reproducible from a known seed where practical.

Conceptually:

```text
seed + course + starting configuration
        ↓
reproducible race simulation
```

Benefits:

- reproducible bugs
- automated testing
- debugging
- future replays
- future daily challenges
- future leaderboard possibilities

The exact implementation depends on the physics engine and platform, but this requirement should influence the architecture from the beginning.

### 11.5 Data-driven content

Courses and cosmetic definitions should be data-driven.

Adding a new course should ideally not require changing tournament code.

Adding a new cosmetic should ideally not require changing race logic.

---

## 12. Performance requirements

The game is intended for mobile hardware and must remain responsive on a reasonable range of supported devices.

Priorities:

1. stable simulation
2. stable frame rate
3. responsive UI
4. low memory usage
5. short loading times

The exact device baseline and frame-rate target are TBD.

Do not optimise prematurely, but avoid architecture that obviously assumes desktop-class resources.

---

## 13. MVP scope

### Phase 0 — Physics prototype

**Goal:** Determine whether watching a marble roll through a course is visually satisfying.

Implement only:

- one marble
- one 2.5D course
- realistic physics
- camera following the marble
- mobile-friendly input/UI shell as necessary to launch/restart
- start
- finish
- fall/off-course detection
- restart
- browser-playable build
- phone testing

Do **not** implement yet:

- 12-marble tournament
- progression
- shop
- ads
- IAP
- accounts
- missions
- daily challenges
- multiple complex systems

### Phase 0 success criterion

> Watching the marble complete a course should feel satisfying enough that the player wants to run it again.

### Phase 1 — Playable MVP

**Goal:** Determine whether the core spectator tournament is fun.

Implement:

- persistent player marble
- 12-marble simulation
- 3 elimination rounds
- 12 → 6 → 3 → 1 progression
- player elimination
- tournament victory
- race results
- home screen
- basic course selection/unlock flow
- 3–5 courses
- 3–5 basic cosmetic marble options
- basic coins
- browser testing
- mobile testing

Still exclude:

- advertising
- IAP
- online accounts
- online leaderboards
- missions
- seasons
- multiplayer
- user-generated maps
- procedural course generation
- marble abilities
- gameplay-stat upgrades

### Phase 2 — Retention

Possible features:

- more courses
- more cosmetics
- daily challenge
- missions
- improved rewards
- better progression

Only add features that support the core spectator loop.

### Phase 3 — Monetisation

Possible features:

- shop
- cosmetic purchases
- rewarded ads
- IAP

Monetisation must not undermine the casual/family-friendly experience.

### Phase 4 — Launch

Possible launch requirements:

- analytics
- crash reporting
- store listing
- App Store release
- Google Play release

---

## 14. Non-goals

Unless explicitly added later, do not build:

- direct race controls
- multiplayer races
- competitive online ranking
- online accounts
- user-generated courses
- procedural course generation
- marble gameplay abilities
- marble stat progression
- pay-to-win mechanics
- seasons / battle passes
- complex social systems
- elaborate RPG progression
- elaborate inventory systems

Ideas that are not in the current scope belong in the parking lot below.

---

## 15. Testing and acceptance criteria

Features should be implemented with testable acceptance criteria rather than relying on visual inspection alone.

### Example: tournament elimination

Given 12 active marbles, after Round 1 exactly 6 must advance.

Given 6 active marbles, after Round 2 exactly 3 must advance.

Given 3 active marbles, after Round 3 exactly 1 must be declared the winner.

### Example: player elimination

Given the player's marble does not finish within the advancing positions, the tournament must end for that player.

### Example: player identity

The player's marble must remain identifiable throughout the race and must use the same saved cosmetic configuration between races.

### Example: restart

Restarting a race must return the game to a clean initial state without retaining physics state from the previous run.

### Example: deterministic seed

Given the same deterministic seed, course, and starting configuration, the simulation should produce the same race outcome whenever deterministic simulation is supported by the selected engine.

Agents should add tests whenever practical for gameplay rules and state transitions.

---

## 16. Agent development rules

This repository is intended to be developed heavily with agentic AI.

Agents should follow these rules:

### Product discipline

- Read `PROJECT.md` before making architectural or gameplay changes.
- Do not invent new gameplay systems because they seem useful.
- Prefer the smallest implementation that proves the current hypothesis.
- Do not implement parking-lot ideas without explicit approval.
- Keep MVP scope narrow.

### Architecture discipline

- Keep gameplay rules separate from presentation.
- Keep physics simulation separate from progression/economy.
- Prefer data-driven course/content definitions.
- Avoid hard-coding individual courses into tournament logic.
- Avoid unnecessary dependencies.
- Prefer simple systems that can later be extended.

### Iteration discipline

- Keep browser testing easy.
- Make changes in small, testable increments.
- Preserve the ability to restart a race quickly.
- When changing physics, verify behaviour on an actual phone as soon as practical.

### Visual discipline

- Match the stated 2.5D physical visual direction.
- Do not introduce generic AI-generated mobile-game UI patterns.
- Avoid unnecessary visual complexity.
- Prioritise marble readability and course readability.

### Code quality

- Keep public APIs and data structures understandable.
- Add tests for deterministic/game-state logic where practical.
- Avoid large abstractions before they are justified.
- Prefer configuration/data over code duplication.

---

## 17. Open decisions — do not silently guess

These are intentionally unresolved. They should be decided before the relevant system becomes difficult to change.

### Critical

1. **Technology stack:** Which engine/framework should be used?
2. **Camera:** What exact 2.5D camera/projection should the game use?
3. **Physics:** What does “realistic” mean for this game? Real-world gravity and friction, or stylised but believable physics?
4. **Race continuity between rounds:** Is Round 2 a continuation of the same course/run, or does the surviving marbles start a new section/re-run?
5. **Course structure:** Are all three rounds played on the same course, or does each round use a different course/segment?
6. **Outcome fairness:** Should all marbles have exactly equal physics, or should the simulation contain controlled variability to make the player's marble slightly more/less likely to survive?
7. **Player marble visibility:** How should the player's marble be identified without making the race UI cluttered?
8. **Course failure:** What exactly happens when a marble gets stuck?
9. **Reward model:** How many coins are earned for advancing, losing, and winning?
10. **Unlock model:** Are courses unlocked permanently, sequentially, randomly, or through another system?

### Important but later

11. **Camera behaviour during collisions:** Does the camera follow only the player marble or zoom/shift to show important groups?
12. **Course difficulty:** How is difficulty communicated to the player?
13. **Race variability:** How much randomness is desirable between runs of the same course?
14. **Physics determinism:** Is exact deterministic replay a hard requirement or only a desirable property?
15. **Save system:** Local-only initially, or account/cloud save later?
16. **Analytics:** Which player behaviours should be measured once Phase 1 is validated?
17. **Monetisation timing:** At what point should ads or IAP be introduced, if at all?
18. **Age positioning:** Is the target explicitly children/families, or more broadly casual players of all ages?

---

## 18. Questions to grill the designer on

These are deliberately blunt. Resolve them before asking an agent to build substantial systems.

### Core fun

1. **Why will someone watch a marble race for the fifth time?**
2. **What is the emotional payoff when your marble survives a round?**
3. **What makes Marble Jumble meaningfully different from watching a generic marble run?**
4. **How much of the fun comes from the course versus the tournament structure?**
5. **What makes losing feel acceptable rather than frustrating?**

### Player ownership

6. **If the player's marble has no gameplay advantages, what exactly makes it feel like “their” marble?**
7. **How quickly can a new player customise or personalise it?**
8. **Would the player care if the marble they own is eliminated in Round 1? Why?**

### Replayability

9. **What changes between two runs of the same course?**
10. **Should players be able to learn courses, or should outcomes always feel unpredictable?**
11. **How much randomness is fun before it feels arbitrary or rigged?**

### Progression

12. **What does the player work toward after the novelty of the first few races wears off?**
13. **Are course unlocks actually exciting enough to drive replay, or are cosmetics doing most of that work?**
14. **What is the first meaningful reward a new player receives?**
15. **What should a player have unlocked after roughly 30 minutes?**

### Difficulty

16. **How often should a typical player reach Round 2?**
17. **How often should they reach the final?**
18. **How often should they win?**
19. **Should those probabilities be controlled explicitly, or emerge naturally from physics?**

### Content

20. **How many genuinely different courses are needed before the game stops feeling repetitive?**
21. **What makes a course “good enough” to ship?**
22. **Can a course be fun with simple geometry, or does it require elaborate art and animation?**

### Product scope

23. **What is the smallest version you would be genuinely excited to put on someone else's phone?**
24. **Which feature in the current roadmap are you most tempted to build too early?**
25. **What would make you abandon the project rather than keep polishing it?**

---

## 19. Parking lot

Ideas that may be explored later, but are **not part of the current MVP**:

- online leaderboards
- achievements
- ghost marbles
- seasonal themes
- tournaments beyond the standard 12 → 6 → 3 → 1 structure
- daily courses / daily challenge
- user-made courses
- generated/procedural courses
- different marble physical properties
- marble special abilities
- additional game modes
- more sophisticated marble progression

Do not implement these without explicitly moving them into an active phase.

---

## 20. First implementation target

The first development milestone is not “build Marble Jumble.”

It is:

> **Build one satisfying marble run that can be played repeatedly in a phone browser.**

Everything else should wait until that experience is good.

The immediate prototype should answer three questions:

1. Does the marble movement feel good?
2. Does the 2.5D presentation look good on a phone?
3. Is watching the run enjoyable enough to restart immediately?

If the answer to any of these is no, do not compensate by adding progression, cosmetics, shops, missions, or other systems. Fix the core experience first.
