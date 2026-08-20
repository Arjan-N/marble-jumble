# Marble Jumble — Project Decisions

## Decision log

### Technology stack — 2026-08-20

**Decision:** Use **Godot 4** as the game engine.

**Rationale:**
- 2.5D / 3D physics is a core requirement.
- Mobile is the primary target.
- A browser-playable prototype is important for rapid iteration and phone testing.
- Godot provides an integrated scene/editor/physics workflow without the additional complexity of a larger commercial engine.
- The project is intended to be developed heavily with agentic AI, so keeping the architecture and project structure relatively lightweight is valuable.

**Implication:**
- Future technical decisions should assume Godot 4 unless explicitly reconsidered.
- Prototype with the Godot Compatibility renderer first so the browser target remains viable.
- Do not introduce engine-specific complexity until the Phase 0 prototype proves the core marble-run experience.

### Phase 0 technical direction — 2026-08-20

**Decision:** Lock the initial physics/camera/course feel before implementation.

**Locked decisions:**
- **Camera/projection:** landscape 2.5D; course runs longitudinally/down-course, generally away from the player. Use a controlled angled perspective rather than a side-on view.
- **Camera movement:** follow the player's marble with deliberate look-ahead.
- **Camera look-ahead:** approximately 3–4 seconds of course ahead.
- **Physics:** stylised-realistic; believable gravity, momentum, friction and collisions tuned for entertaining outcomes rather than literal real-world accuracy.
- **Marble scale:** between realistic and oversized; large enough for mobile readability while still reading clearly as marbles. Treat size as a tuning parameter.
- **Track width:** generally wide enough for marbles to spread out, with deliberate collision/chaos sections.
- **Race control:** watch-only during the race. No steering, nudging or abilities in Phase 0.
- **Player marble identification:** customized appearance plus the normal subtle persistent highlight/rim. No floating arrow or oversized marker.
- **Opponent marbles:** identical physical attributes; cosmetic differences only.
- **Opponent behaviour:** no AI; opponents are physics-driven participants.
- **Simulation:** fully physically simulated in Phase 0, with no invisible assistance, scripted outcomes or corrective forces.
- **Race variability:** course layout remains consistent; physics should create meaningful variation in outcomes.
- **Course length:** target 20–30 seconds per course.
- **Course geometry:** hybrid long-term, but Phase 0 is primarily a solid trough/channel with a few constructed sections.
- **Elevation:** mostly downhill, with flat sections and a small uphill/slowdown section.
- **Curves:** natural 3D path curves with banking; Phase 0 includes a gentle S-curve.
- **Surfaces:** mixed rough Canyon/stone and smoother constructed sections.
- **Starting sequence:** 12 marbles physically roll into a funnel/grid formation, settle, then the course-selection/starting presentation occurs.
- **Start interaction:** player can tap the physical barrier to release the marbles. If untouched, it opens automatically after 5 seconds. Tapping has no effect on race outcome.
- **Starting position:** player's marble is assigned a random starting position; its normal persistent highlight provides identification.
- **Starting slots:** subtly varied per race so opening states are not identical, while avoiding an obviously advantageous slot.
- **Course flow:** one simple Canyon prototype with gentle downhill opening → wider rolling section → narrowing/funnel → one jump → one simple active obstacle → short final stretch → finish.
- **Branching:** any branch outcome is determined naturally by physics; no deliberate player route choice and no AI route selection.
- **Falls:** leaving the course means elimination for now; the Phase 0 course should minimize unintended/excessive falls.
- **Phase 0 obstacle:** rotating bumper.
- **Future obstacle vocabulary:** boosters, launchers, moving platforms, bumpers, conveyor belts and similar mechanics remain planned for later courses, but are not required for Phase 0.

### Still undecided

- Exact Godot 4.x version
- Rendering approach beyond the initial compatibility-oriented prototype
- Exact camera angle/projection parameters
- Exact physics tuning values (friction, restitution, gravity scaling, etc.)
- Exact mobile performance baseline / target frame rate
- Determinism guarantees of the physics simulation
- Exact finish/stuck timeout behaviour
- Course weighting and duplicate-course rules
- Final visual language for elimination and course roulette
- Economy/reward values and course unlock structure
