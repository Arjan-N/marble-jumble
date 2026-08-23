class_name MarbleTuning
extends Resource

## Central home for the Phase 0 marble physics constants.
##
## The spec treats every value here as a tuning parameter to be settled by
## testing, not as a design decision. Nothing outside this resource should
## hard-code a marble constant.
##
## All marbles share these values. Cosmetics never affect physics
## (PROJECT.md section 7).

## Diameter is roughly twice this. Sized between realistic and oversized so
## collisions read clearly on a phone.
@export var radius: float = 0.45
@export var mass: float = 1.0
@export var friction: float = 0.4
## Was 0.3. That value only ever showed up as a faint wall-clip, because the
## marble mostly tunnelled through hard landings (the jump) instead of actually
## contacting them at the old 60Hz physics rate. Now that landings resolve
## properly, 0.3 reads as a ball bouncing down the course rather than a marble
## settling into a roll — lowered to keep a landing looking like an impact
## without a bounce chain following it.
@export var bounce: float = 0.06
## Damping is the single most sensitive value here. Angular damping opposes
## rolling directly, so small increases cost a lot of speed: at 0.1 the field
## plateaued near 3 m/s and the run overshot the 20-30s target several times
## over. Real marbles have very little rolling resistance.
@export var linear_damp: float = 0.0
@export var angular_damp: float = 0.02
