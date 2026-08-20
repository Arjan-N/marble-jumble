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

## Still undecided

- Exact Godot 4.x version
- Rendering approach beyond the initial compatibility-oriented prototype
- Physics tuning: realistic vs stylised-believable
- Camera/projection
- Exact mobile performance baseline
- Determinism guarantees of the physics simulation
