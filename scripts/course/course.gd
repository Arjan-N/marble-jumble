class_name Course
extends Node3D

## What a course has to provide for a race to run on it.
##
## Two implementations exist: `CourseBuilder` (the Canyon prototype) and
## `SlopeCourse` (a straight test track). `PROJECT.md` section 6 wants courses
## data-driven eventually, and this is deliberately not that format. It is the
## smaller step that has to come first — naming the seam the race sequences
## against — because a data format would have to serialise exactly this and
## nothing else. Inventing the format with two hand-written courses in existence
## would be guessing at what the third one needs.
##
## `race_manager.gd` talks to courses only through what is declared here.

## Centreline, running from the top of the starting ramp to the finish. The
## camera samples it for look-ahead and framing, so a course without one gets a
## camera steering by marble velocity instead.
var curve: Curve3D
## Where the field is released from. Carries the full frame, not just a point:
## the barrier has to sit square to a sloped, possibly banked start line.
var start_transform: Transform3D
var finish_position: Vector3


func build() -> void:
	pass


func get_spawn_transforms(_count: int, _rng: RandomNumberGenerator) -> Array[Transform3D]:
	return []


## Below this a marble has left the course. Per-course rather than a shared
## constant because it has to clear the course's own lowest point, and two
## courses do not descend by the same amount.
func fall_threshold_y() -> float:
	return -1.0e9


## How wide the finish gate has to be to span the track.
func finish_width() -> float:
	return 12.0


## How wide the starting barrier has to be to close the track.
func start_width() -> float:
	return 6.8


## Signed distance, in metres, from a position to the far edge of the course's
## jump: negative while short of the landing, positive once past it. `INF` when
## the position is nowhere near a jump, and for courses that have none.
##
## The race watches the sign flip to spot a marble that only just got across —
## the best moment the course produces and, until this existed, one that passed
## without comment. It lives here because only the course knows where its own
## landing edge is, and on a course whose gap is not square to the track it
## depends on where across the marble is, not only how far along.
func jump_clearance(_position: Vector3) -> float:
	return INF
