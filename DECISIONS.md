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
- **Platform:** the shipped game is intended to be native mobile (Android/iOS). Browser play is a development/testing target, not the shipping platform.
- **Camera/projection:** landscape 2.5D using a controlled, weak-perspective angled camera rather than an orthographic/isometric or side-on view. The course runs longitudinally/down-course, generally away from the player.
- **Camera movement:** follow the player's marble with deliberate look-ahead.
- **Camera look-ahead:** approximately 3–4 seconds of course ahead.
- **Physics:** stylised-realistic; believable gravity, momentum, friction and collisions tuned for entertaining outcomes rather than literal real-world accuracy.
- **Physics space:** genuine 3D rigid-body physics constrained by the physical course geometry; the course defines where marbles can roll rather than relying on mostly-2D simulation.
- **Marble scale:** between realistic and oversized; large enough for mobile readability while still reading clearly as marbles. Treat size as a tuning parameter.
- **Track width:** generally wide enough for marbles to spread out, with deliberate collision/chaos sections.
- **Race control:** watch-only during the race. No steering, nudging or abilities in Phase 0.
- **Player marble identification:** customized appearance plus the normal subtle persistent highlight/rim. No floating arrow or oversized marker.
- **Opponent marbles:** identical physical attributes; cosmetic differences only.
- **Opponent behaviour:** no AI; opponents are physics-driven participants.
- **Simulation:** fully physically simulated in Phase 0, with no invisible assistance, scripted outcomes or corrective forces.
- **Race variability:** course layout remains consistent; physics should create meaningful variation in outcomes.
- **Course length:** target 20–30 seconds per course. This supersedes the 30–40 second figure in PROJECT.md v0.2.
- **Course geometry:** hybrid long-term, but Phase 0 is primarily a solid trough/channel with a few constructed sections.
- **Elevation:** mostly downhill, with flat sections and a small uphill/slowdown section.
- **Curves:** natural 3D path curves with banking; Phase 0 includes a gentle S-curve.
- **Surfaces:** mixed rough Canyon/stone and smoother constructed sections.
- **Starting sequence:** 12 marbles physically roll into a funnel/grid formation and settle behind a physical barrier.
- **Start interaction:** player can tap the physical barrier itself to release the marbles. If untouched, it opens automatically after 5 seconds. Tapping has no effect on race outcome. No separate countdown is required.
- **Starting position:** player's marble is assigned a random starting position; its normal persistent highlight provides identification.
- **Starting slots:** subtly varied per race so opening states are not identical, while avoiding an obviously advantageous slot.
- **Course flow:** one simple Canyon prototype with gentle downhill opening → wider rolling section → gentle S-curve → narrowing/funnel → physics-driven split/merge → short uphill/slowdown → meaningful short jump → rotating bumper → short final stretch → finish.
- **Branching:** include one simple split/merge in Phase 0. Which route a marble takes is determined naturally by physics; there is no deliberate player route choice and no AI route selection.
- **Falls:** leaving the course means elimination for now. The Phase 0 course should have **low** fall/elimination risk overall; falling should be an occasional consequence, not the dominant failure mode.
- **Finish:** use a physical finish area plus a reliable trigger/finish condition for game-state detection.
- **Stuck handling:** configurable stuck detection is not required for the first physics experiment; add it if the prototype demonstrates a real stuck-state problem. Any future timeout should be a technical parameter rather than a gameplay feature.
- **Phase 0 obstacle:** rotating bumper.
- **Future obstacle vocabulary:** boosters, launchers, moving platforms, bumpers, conveyor belts and similar mechanics remain planned for later courses, but are not required for Phase 0.
- **Prototype physics parameters:** marble diameter, mass, friction, restitution/bounce, damping and related constants are tuning parameters and should be established through prototype testing rather than treated as fixed design decisions.
- **Course boundaries:** use physical course geometry as the primary containment. Limited helper collision geometry is acceptable where needed for reliable physical boundaries; it must not manipulate race outcomes.
- **Browser testing:** browser support should be available for fast iteration and phone testing, but mobile native Android/iOS remains the actual product target. Neither desktop nor mobile browser is a shipping platform; at least one fast browser loop plus real native-device testing must exist, and whichever browser target proves materially harder to support may be dropped.
- **Performance baseline:** start with a low-to-mid-range modern mobile target and tune after real-device testing.

### Phase 0 field size — 2026-08-20

**Decision:** Phase 0 ships with the full **12-marble** field, not a single marble.

**Rationale:**
- The Phase 0 success criteria include readable collision deflections and interesting split/merge outcomes. Neither can be evaluated with one marble.
- The locked start sequence (funnel formation behind a physical barrier) is inherently a multi-marble presentation; building it for one marble means building it twice.

**Implication:**
- A single-marble build remains a valid internal checkpoint for tuning marble feel, but it does not satisfy Phase 0.
- Supersedes the "one marble" line in the PROJECT.md v0.2 Phase 0 list.

### Still undecided

- Exact Godot 4.x version
- Exact camera angle/focal parameters
- **Whether the locked camera/projection and landscape presentation survive.** An
  open spike is testing a portrait, near-top-down framing against them on a real
  phone, because the locked chase camera cannot show a twelve-marble field. The
  locked decisions above stand until that test is written up — see
  `docs/CAMERA_SPIKE.md`. Do not treat the portrait settings currently in
  `project.godot`, or `Mode.OVERHEAD` in `scripts/camera/chase_camera.gd`, as
  decided.
- Exact physics tuning values (friction, restitution, gravity scaling, etc.)
- Exact mobile performance target / frame-rate target after first real-device test
- Determinism guarantees of the physics simulation
- Exact visual language for elimination and course roulette
- Course weighting and duplicate-course rules
- Economy/reward values and course unlock structure
- Survivor rule when fewer marbles finish a round than the round requires
- Whether Round 1's course is also chosen by roulette, or only rounds 2 and 3
- Which two of Courses / Marble / Shop occupy the flanking home-screen buttons
