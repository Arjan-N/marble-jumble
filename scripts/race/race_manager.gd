extends Node3D

## Race and tournament orchestration.
##
## Owns the sequence: build course, settle the field, release, watch, resolve,
## repeat with survivors on a new course. Progression, currency and the
## transition spectacle (course roulette, elimination reveal) from PROJECT.md
## section 4 still don't live here — this is the plain version: a leaderboard
## and a short pause between rounds.
##
## Physics never touches game state directly. Marbles are simulated; this node
## observes them through triggers and reports what happened.

const MARBLE_COUNT := 12
const PLAYER_MARBLE_INDEX_UNSET := -1
const PLAYER_COLOUR := Color(0.25, 0.78, 1.0)

## Opponent names, drawn at random each race. Cosmetic — nothing here reaches the
## physics, and opponents remain identical to the player (PROJECT.md section 7).
##
## They exist because standings need something to be *about*. A row reading
## "P4" is a number; a row reading "Bramble" is somebody you can be annoyed at.
## The list is longer than the field so the same eleven do not turn up every
## race, and every name is short enough to sit in a portrait HUD without
## wrapping. Family-friendly, per the positioning in section 1.
const OPPONENT_NAMES := [
	"Pebble", "Nimbus", "Comet", "Biscuit", "Marlow", "Tuck",
	"Juno", "Basil", "Otto", "Wren", "Fig", "Sable",
	"Pip", "Clover", "Rook", "Hazel", "Mango", "Dot",
]

## How many places either side of the cut count as "close enough to care".
const CUT_ATTENTION := 2

## Seconds before release at which the countdown starts appearing.
##
## The five seconds before the barrier drops were the least interesting part of
## the race: twelve marbles sat still, a number ticked down in small text, and
## nothing said the race was about to start. A countdown is the cheapest tension
## there is, and it makes the barrier tap feel like skipping a queue rather than
## like nothing.
const COUNTDOWN_FROM := 3

## The player's marble. `PROJECT.md` section 2.1 wants one persistent, named,
## customisable marble; naming it is Phase 1's job, along with the rest of
## customisation. Until then it says what it is, which is the one thing the
## player never has to look up.
const PLAYER_NAME := "You"

## Every course a round may run on. Preloaded by path rather than named
## directly: a global class name is not a constant expression, so an array of
## bare class names does not parse.
##
## `CourseBuilder` (the curved Canyon) is included as-is even though its own
## comments note it can stall its field around ratio 0.66 — a known rough edge
## in the pool, not a reason to quietly drop it.
## `course_builder.gd` (the curved Canyon) is deliberately absent: its field
## reliably stalls part-way down and almost nobody finishes. Investigated and
## not yet solved — the centreline itself is clean (monotonic descent, minimum
## grade ~5 degrees, measured with `tools/probe_curve.gd`), and removing the
## split divider does not fix it either, so the cause is elsewhere in the swept
## geometry. Left in the repo to be fixed later rather than deleted.
const COURSE_POOL: Array[GDScript] = [
	preload("res://scripts/course/slope_course.gd"),
	preload("res://scripts/course/jungle_course.gd"),
	preload("res://scripts/course/orbital_course.gd"),
]

enum Phase { SETTLING, RACING, COMPLETE }

var _course: Course
var _active_course_script: GDScript
var _barrier: StartBarrier
var _camera: ChaseCamera
var _hud: RaceHUD
var _sound: SoundManager
var _cut_marker: CutMarker
var _cut_marker_offset := -1.0
var _rank_tag: RankTag
## Set when a new field spawns, so the tag jumps to the new player marble
## instead of sliding across the course from where the last round left it.
var _rank_tag_needs_snap := true
var _tuning: MarbleTuning

## Carries survivors' cosmetic identity (colour, name, is_player) from one
## round to the next. Empty means "start a fresh tournament" — `_spawn_field`
## generates a full field of `MARBLE_COUNT` when it finds nothing here.
var _roster: Array = []
var _round_number := 1
## "" while the tournament is ongoing; "won" or "eliminated" once the player's
## run through it is decided. Only ever set in `_resolve_round`.
var _tournament_outcome := ""

var _marbles: Array[Marble] = []
var _player: Marble
## Set once the player's own marble finishes or falls, so the HUD can switch to
## the full leaderboard while the rest of the field is still settling — there
## is nothing left for the player to watch about their own run at that point.
var _player_done := false

## The staggered entrance: which marbles are still frozen, waiting their turn,
## in the order they will be released.
const SETTLE_STAGGER := 0.12
var _settle_order: Array[Marble] = []
var _settle_index := 0
var _settle_elapsed := 0.0
var _finish_order: Array[Marble] = []

var _phase: Phase = Phase.SETTLING
var _race_time: float = 0.0
var _rng := RandomNumberGenerator.new()

## How often the field is re-ranked. Position is read by a human watching a race,
## not by anything that needs to be correct between frames, and re-ranking every
## physics tick means twelve closest-point searches against a baked curve sixty
## times a second to move a number that changes a handful of times a race.
const STANDINGS_INTERVAL := 0.1

var _standings: Array[Marble] = []
var _standings_age: float = 0.0
## Distance along the course per marble, cached from the last ranking so gaps can
## be shown without repeating the closest-point searches.
var _progress: Dictionary = {}

## Overtakes are the drama of a race you cannot steer — the standings renumber
## and, until this existed, that was the entire event. PROJECT.md section 2.3
## lists overtakes second, right after collisions.
##
## Only the player's are called. Twelve marbles trading places produce a
## constant churn of swaps that mean nothing to anyone; the one that matters is
## the one that happened to you.
var _last_place: int = 0
var _overtake_cooldown: float = 0.0
## Highest count already called, so each number is announced once rather than
## every frame it is true for.
var _countdown_called: int = 0

## Last jump clearance seen per marble, so the crossing can be spotted as a sign
## change rather than by trying to catch the instant of landing.
var _clearance: Dictionary = {}

## How little a marble can have to spare and still be said to have "just made
## it", in metres. Generous, because the field is only sampled ten times a second
## and a marble crossing at 15 m/s moves a metre and a half between looks — a
## tighter threshold would mostly measure sampling luck.
const NEAR_MISS_MARGIN := 2.5
## Marbles still in the running at the last ranking. A fall promotes everyone
## below it by a place, and that is not an overtake — announcing "passed Basil"
## because Basil fell into a hole reads as a lie.
var _last_contenders: int = -1

## How long after calling one swap before another can be called. Two marbles
## running side by side cross and re-cross several times a second, and without
## this the notice line strobes.
const OVERTAKE_COOLDOWN := 1.6

## Half the field finishing is what ends a round (PROJECT.md section 3: the
## top half advance); cutting the moment that happens would strand whoever is
## mid-course, so stragglers get this long to land, finish or fall before the
## round is scored. Falling never buys a place, however long the grace runs.
const ROUND_GRACE_PERIOD := 6.0
## Negative while no round has reached its 50% mark yet.
var _grace_timer := -1.0

## Backstop for a course whose field genuinely stalls rather than merely runs
## slow — `course_builder.gd`'s own comments document exactly that, around
## ratio 0.66, and confirmed reproducing it: without this, a round where
## nobody ever crosses the line waits forever for a 50%-finished mark that
## never arrives. Well above the ~20-30s target for a healthy course.
const MAX_ROUND_DURATION := 75.0

## How long the result screen holds before the next round's field spawns.
const NEXT_ROUND_DELAY := 3.0
## Longer than the countdown/GO shout (0.85s) — "QUALIFIED!" needs a moment to
## actually be read, not just flash past. Comfortably inside NEXT_ROUND_DELAY.
const OUTCOME_SHOUT_SECONDS := 1.8


func _ready() -> void:
	_tuning = MarbleTuning.new()
	_setup_environment()
	_start_race()


func _unhandled_input(event: InputEvent) -> void:
	# Bound directly rather than through an input map action: Phase 0 has two
	# debug keys, and InputMap entries would be config to keep in sync for no gain.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_restart()
		elif event.keycode == KEY_C and _camera != null and is_instance_valid(_camera):
			# Camera spike only — remove with Mode.OVERHEAD once the phone test
			# settles the projection. See docs/CAMERA_SPIKE.md.
			_camera.cycle_mode()


const DEBUG_TRACE := true
var _trace_accumulator := 0.0


func _physics_process(delta: float) -> void:
	if _phase == Phase.RACING:
		_race_time += delta
		_check_for_falls()
		if _grace_timer < 0.0 and _race_time >= MAX_ROUND_DURATION:
			_resolve_round()

	if _grace_timer > 0.0:
		_grace_timer -= delta
		if _grace_timer <= 0.0:
			_grace_timer = 0.0
			_resolve_round()

	if _phase == Phase.SETTLING and _settle_index < _settle_order.size():
		_settle_elapsed += delta
		if _settle_elapsed >= SETTLE_STAGGER:
			_settle_elapsed = 0.0
			_release_next_marble()

	_overtake_cooldown = maxf(_overtake_cooldown - delta, 0.0)

	_standings_age -= delta
	if _standings_age <= 0.0:
		_standings_age = STANDINGS_INTERVAL
		_rank_field()
		if _phase == Phase.RACING:
			_check_for_overtakes()
			_check_for_near_misses()

	_update_cut_marker(delta)
	_update_rank_tag(delta)

	if DEBUG_TRACE:
		_trace_accumulator += delta
		if _trace_accumulator >= 2.0:
			_trace_accumulator = 0.0
			var racing := 0
			var furthest := 0.0
			var moving := 0
			for marble in _marbles:
				if marble.state == Marble.State.RACING:
					racing += 1
				furthest = minf(furthest, marble.global_position.z)
				if marble.linear_velocity.length() > 0.2:
					moving += 1
			var p := _player.global_position
			print(
				"t=%5.1f phase=%d racing=%2d moving=%2d furthest_z=%7.1f player=(%.2f, %.2f, %.2f) v=%.2f"
				% [
					_race_time,
					_phase,
					racing,
					moving,
					furthest,
					p.x,
					p.y,
					p.z,
					_player.linear_velocity.length(),
				]
			)

	_update_hud()


# --- Race lifecycle -----------------------------------------------------------


func _start_race() -> void:
	_teardown_race()
	_rng.randomize()

	_active_course_script = _pick_course()
	_course = _active_course_script.new()
	_course.name = "Course"
	add_child(_course)
	_course.build()

	_spawn_field()
	_add_barrier()
	_add_finish()
	_add_camera()

	_phase = Phase.SETTLING
	_race_time = 0.0
	_player_done = false
	_grace_timer = -1.0


## Picks the next round's course at random, excluding whichever one just ran
## where there's a choice — "a random *other* course" rather than a coin flip
## that can repeat itself.
func _pick_course() -> GDScript:
	var pool := COURSE_POOL.duplicate()
	if _active_course_script != null and pool.size() > 1:
		pool.erase(_active_course_script)
	return pool[_rng.randi_range(0, pool.size() - 1)]


## Frees whatever the previous race left behind and clears every per-race
## transient, so the very first race, a round transition, and a manual restart
## all begin from the same clean slate — only `_start_race` needs to know that.
func _teardown_race() -> void:
	# `queue_free` only defers deletion; a barrier still mid-teardown keeps
	# running `_process` and can still auto-open on its own timer, which would
	# fire this same handler against the *new* race's marbles. Disconnecting
	# first makes the old barrier inert rather than racing the deferred free.
	if _barrier != null and is_instance_valid(_barrier) and _barrier.opened.is_connected(_on_barrier_opened):
		_barrier.opened.disconnect(_on_barrier_opened)

	for node in [_course, _barrier, _camera]:
		if node != null and is_instance_valid(node):
			node.queue_free()

	for marble in _marbles:
		if is_instance_valid(marble):
			marble.queue_free()

	_marbles.clear()
	_finish_order.clear()
	_standings.clear()
	_progress.clear()
	_player = null
	_last_place = 0
	_last_contenders = -1
	_overtake_cooldown = 0.0
	_countdown_called = 0
	_clearance.clear()
	_cut_marker_offset = -1.0

	if _hud != null and is_instance_valid(_hud):
		_hud.clear_notice()


## A full reset rather than a round transition: clears the roster and round
## count too, so this starts a brand-new tournament instead of continuing a
## shrunken one.
func _restart() -> void:
	_roster = []
	_round_number = 1
	_tournament_outcome = ""
	_active_course_script = null
	_start_race()


## Builds the field from `_roster` — the survivors of the previous round, or
## (when empty, meaning a tournament is just starting) a freshly generated
## full field.
func _spawn_field() -> void:
	if _roster.is_empty():
		_roster = _generate_initial_roster()

	var count := _roster.size()
	var spawns := _course.get_spawn_transforms(count, _rng)

	for i in count:
		var entry: Dictionary = _roster[i]
		var marble := Marble.create(i, _tuning, entry["colour"], entry["is_player"], entry["name"])

		add_child(marble)
		marble.reset_to(spawns[i])
		# Held here rather than let loose all at once — released in
		# `_release_next_marble` so the field arrives like participants taking
		# their place, not a single simultaneous drop.
		marble.freeze = true
		_marbles.append(marble)

		if entry["is_player"]:
			_player = marble
			marble.collided.connect(_on_player_collided)

	_settle_order = _marbles.duplicate()
	_settle_order.shuffle()
	_settle_index = 0
	_settle_elapsed = 0.0
	_release_next_marble()


## Unfreezes the next marble in `_settle_order`, so it rolls in on its own
## rather than as part of the whole field. Shuffled rather than in spawn order,
## so the same seat is not always first to arrive.
func _release_next_marble() -> void:
	if _settle_index >= _settle_order.size():
		return
	var marble: Marble = _settle_order[_settle_index]
	if is_instance_valid(marble):
		marble.freeze = false
	_settle_index += 1


## A fresh field of `MARBLE_COUNT`: one random player slot, the rest drawn from
## `OPPONENT_NAMES`. Only ever called when `_roster` is empty, i.e. the start
## of a tournament.
func _generate_initial_roster() -> Array:
	var roster: Array = []
	var player_index := _rng.randi_range(0, MARBLE_COUNT - 1)

	var names := OPPONENT_NAMES.duplicate()
	names.shuffle()
	var next_name := 0

	for i in MARBLE_COUNT:
		var is_player := i == player_index
		var colour := PLAYER_COLOUR if is_player else _opponent_colour(i)
		var marble_name := PLAYER_NAME
		if not is_player:
			marble_name = names[next_name]
			next_name += 1
		roster.append({"colour": colour, "name": marble_name, "is_player": is_player})

	return roster


func _opponent_colour(index: int) -> Color:
	# Cosmetic only. Opponents are physically identical to the player
	# (PROJECT.md section 7).
	return Color.from_hsv(fmod(float(index) * 0.13, 1.0), 0.45, 0.85)


func _add_barrier() -> void:
	_barrier = StartBarrier.create(_course.start_width())
	add_child(_barrier)
	# Placed with the start line's full frame, not just its origin: on a sloped
	# or banked start a barrier left axis-aligned leaves a gap under one edge.
	_barrier.global_transform = _course.start_transform.translated_local(
		Vector3(0.0, StartBarrier.HEIGHT * 0.5, 0.0)
	)
	_barrier.opened.connect(_on_barrier_opened)


func _add_finish() -> void:
	var finish := FinishArea.create(_course.finish_width())
	_course.add_child(finish)
	finish.global_position = _course.finish_position + Vector3(0.0, 2.0, 0.0)
	finish.marble_finished.connect(_on_marble_finished)


func _add_camera() -> void:
	_camera = ChaseCamera.create()
	add_child(_camera)
	_camera.target = _player
	_camera.course = _course


func _on_barrier_opened() -> void:
	_phase = Phase.RACING
	_race_time = 0.0
	for marble in _marbles:
		marble.state = Marble.State.RACING
		marble.sleeping = false
		# A tap can land before the staggered entrance (`_release_next_marble`)
		# has freed every marble; nothing else ever clears `freeze`, so a marble
		# still waiting its turn would otherwise sit frozen through the whole race.
		marble.freeze = false

	_hud.shout("GO", Color(0.72, 0.95, 0.62))
	_sound.play_release()


func _on_player_collided(speed: float) -> void:
	_sound.play_impact(speed)


# --- Standings ----------------------------------------------------------------


## Orders the whole field, best first: marbles that have finished (in the order
## they did), then everyone still running by how far down the course they are,
## then anyone who fell.
##
## Distance is measured along the course centreline rather than by world
## position, so this does not assume a course runs in any particular direction —
## `SlopeCourse` happens to run down -Z, the Canyon does not stay straight, and
## a race that only ranks correctly on straight courses would be a trap for
## whoever writes the third one.
func _rank_field() -> void:
	# Guards against a marble that outlived a restart: `queue_free` defers the
	# actual deletion, and a marble freed but still referenced here used to
	# crash every standings update afterwards rather than just the one frame.
	_marbles = _marbles.filter(func(marble: Marble) -> bool: return is_instance_valid(marble))

	var progress := {}
	for marble in _marbles:
		progress[marble] = _course_offset(marble)
	_progress = progress

	var running: Array[Marble] = []
	var fallen: Array[Marble] = []
	for marble in _marbles:
		match marble.state:
			Marble.State.FINISHED:
				continue ## Already ordered, in _finish_order.
			Marble.State.ELIMINATED:
				fallen.append(marble)
			_:
				running.append(marble)

	running.sort_custom(func(a: Marble, b: Marble) -> bool:
		return progress[a] > progress[b]
	)

	_standings = []
	_standings.append_array(_finish_order)
	_standings.append_array(running)
	_standings.append_array(fallen)


## How fast the displayed marker chases its target offset, per second. Not
## instant on purpose: which marble holds the cut only refreshes with the
## standings (every `STANDINGS_INTERVAL`), and snapping straight to a
## different marble's position on that cadence is what read as rough — this
## turns both that and ordinary per-tick motion into one continuous slide.
const CUT_MARKER_SMOOTHING := 8.0

## Places the cut-line marker at whichever marble currently holds the last
## surviving place, so the boundary the standings column already names is
## visible on the track itself, not only as a row of text.
##
## Runs every physics tick, not just on the standings' own refresh cadence —
## sampling the curve is cheap for one marble, and doing it at full physics
## rate is what makes the marker glide instead of stepping.
func _update_cut_marker(delta: float) -> void:
	if _cut_marker == null or not is_instance_valid(_cut_marker):
		return

	var cut_index := _marbles.size() / 2 - 1
	var course_ready := _course != null and is_instance_valid(_course) and _course.curve != null
	if _phase != Phase.RACING or not course_ready or cut_index >= _standings.size():
		_cut_marker.visible = false
		_cut_marker_offset = -1.0
		return

	var marble: Marble = _standings[cut_index]
	if marble == null or not is_instance_valid(marble):
		_cut_marker.visible = false
		return

	var length := _course.curve.get_baked_length()
	var target := clampf(_course_offset(marble), 0.0, length)

	if _cut_marker_offset < 0.0:
		_cut_marker_offset = target
	else:
		_cut_marker_offset = lerpf(
			_cut_marker_offset, target, clampf(delta * CUT_MARKER_SMOOTHING, 0.0, 1.0)
		)

	var at := _course.curve.sample_baked(_cut_marker_offset)
	var ahead := _course.curve.sample_baked(minf(_cut_marker_offset + 0.5, length))
	var behind := _course.curve.sample_baked(maxf(_cut_marker_offset - 0.5, 0.0))
	var forward := ahead - behind
	if forward.is_zero_approx():
		forward = Vector3.FORWARD

	_cut_marker.place(at, forward.normalized(), _course.finish_width())
	_cut_marker.visible = true


## Keeps the player's place floating above their own marble.
##
## Hidden outside `Phase.RACING` for the same reason `_update_hud` shows no
## standings while the field is settling: the pre-race order is the arbitrary one
## the marbles happen to be ranked in, and a tag reading "7th" over a stationary
## grid says something untrue. It goes away again once the player has finished or
## fallen — there is no place left to hold.
func _update_rank_tag(delta: float) -> void:
	if _rank_tag == null or not is_instance_valid(_rank_tag):
		return

	var racing := (
		_phase == Phase.RACING
		and not _player_done
		and _player != null
		and is_instance_valid(_player)
		and _player.state == Marble.State.RACING
	)
	if not racing:
		_rank_tag.visible = false
		_rank_tag_needs_snap = true
		return

	# Reads the cached ranking rather than recomputing one — `_player_place` is
	# documented as free to call every frame, and a second ranking path would be
	# a second thing to keep in step with the standings column.
	_rank_tag.set_place(_player_place())
	_rank_tag.follow(_player.global_position, _camera, delta, _rank_tag_needs_snap)
	_rank_tag_needs_snap = false
	_rank_tag.visible = true


## Four rows, not twelve: the leader, and the player with whoever is immediately
## either side of them.
##
## The full field was the obvious thing to show and it was too much — a quarter
## of a portrait screen of text next to a race nobody was looking at any more,
## against section 2.5's ask that the UI stay out of the way. These four are the
## ones that carry information: who is winning, and the two marbles whose
## positions you can actually change places with in the next few seconds. Rows
## eight through eleven are just a list.
##
## A gap in the numbering is drawn as an elision rather than closed up, so P2 and
## P7 never look adjacent.
func _standings_rows() -> Array:
	if _standings.is_empty():
		return []

	# Zero-based index of the last marble that survives the round. PROJECT.md
	# section 3: the top half go through, whatever the field's current size is.
	var cut_index := _marbles.size() / 2 - 1

	# The full board goes up once there is nothing left to watch for the
	# player specifically — either the round is fully over, or their own run
	# through it is (finished or fallen) and the rest is stragglers.
	if _phase == Phase.COMPLETE or _player_done:
		var all := {}
		for index in _standings.size():
			all[index] = true
		return _rows_for(all, cut_index, true)

	var wanted := {0: true}
	var player_index := _standings.find(_player)

	# The cut line is only drawn when the player is near enough for it to be the
	# question they are asking. Leading comfortably, it is noise; scrapping over
	# sixth, it is the only thing on screen that matters. Showing it always would
	# put a permanent line through the middle of a four-row panel.
	var near_cut := (
		player_index >= 0
		and cut_index < _standings.size()
		and absi(player_index - cut_index) <= CUT_ATTENTION
	)
	if near_cut:
		wanted[cut_index] = true
	if player_index >= 0:
		for index in [player_index - 1, player_index, player_index + 1]:
			if index >= 0 and index < _standings.size():
				wanted[index] = true

	return _rows_for(wanted, cut_index, near_cut)


## Turns a set of standings indices into HUD rows, in order, eliding the gaps.
func _rows_for(wanted: Dictionary, cut_index: int, show_cut: bool) -> Array:
	var indices := wanted.keys()
	indices.sort()

	var rows := []
	var previous := -1
	for index: int in indices:
		if previous >= 0 and index > previous + 1:
			rows.append({"elided": true})

		var marble: Marble = _standings[index]
		rows.append({
			"colour": marble.colour,
			"name": "%d %s" % [index + 1, marble.marble_name],
			"trailing": _gap_text(marble, index),
			"is_player": marble.is_player,
		})
		previous = index

		if show_cut and index == cut_index:
			rows.append({"cut": true})

	return rows


## What sits after the name: how far behind the leader this marble is, or why it
## is not racing any more. Metres rather than seconds because a marble that is
## stopped has no meaningful time gap, and a marble in mid-air has a misleading
## one.
func _gap_text(marble: Marble, index: int) -> String:
	match marble.state:
		Marble.State.ELIMINATED:
			return "out"
		Marble.State.FINISHED:
			return "fin"

	if index == 0 or _standings.is_empty():
		return ""

	var gap: float = _progress.get(_standings[0], 0.0) - _progress.get(marble, 0.0)
	if gap < 1.0:
		return ""
	return "%dm" % roundi(gap)


## Calls the player gaining or losing a place, naming who it was against.
##
## Deliberately reports one place at a time even when several change at once. A
## marble that emerges from a pile-up four places up did not make four passes,
## and "passed Otto, Fig, Wren and Sable" is a sentence nobody reads mid-race —
## the marble it now sits behind is the one the viewer can see.
func _check_for_overtakes() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.state != Marble.State.RACING:
		_last_place = 0
		return

	var contenders := 0
	for marble in _marbles:
		if marble.state == Marble.State.RACING:
			contenders += 1

	var place := _player_place()
	var was := _last_place
	var field_changed := contenders != _last_contenders

	_last_place = place
	_last_contenders = contenders

	# First ranking of a race has nothing to compare against, and a ranking taken
	# across an elimination is measuring the wrong thing.
	if was <= 0 or place <= 0 or field_changed:
		return
	if place == was or _overtake_cooldown > 0.0:
		return

	if place < was:
		var passed := _neighbour(place)  # Now directly behind the player.
		if passed != null:
			_announce_overtake("Passed %s" % passed.marble_name, passed.colour)
			_pop_comic("ZOOM!", PLAYER_COLOUR)
	else:
		var passer := _neighbour(place - 2)  # Now directly ahead.
		if passer != null:
			_announce_overtake("%s passed you" % passer.marble_name, passer.colour)
			_pop_comic("OOF!", passer.colour)


## Calls a marble that got over the gap with almost nothing to spare.
##
## Watched as a sign change in the course's own clearance figure rather than by
## trying to catch the moment of landing: landing is one physics frame, the field
## is sampled ten times a second, and a marble that is short simply falls, so the
## sign never flips for it. Anything that crosses from negative to positive got
## across, and how small the positive is says by how much.
func _check_for_near_misses() -> void:
	for marble in _marbles:
		if marble.state != Marble.State.RACING:
			_clearance.erase(marble)
			continue

		var now: float = _course.jump_clearance(marble.global_position)
		var before: float = _clearance.get(marble, INF)
		_clearance[marble] = now

		if is_inf(now) or is_inf(before):
			continue
		if before >= 0.0 or now < 0.0:
			continue
		if now > NEAR_MISS_MARGIN or _overtake_cooldown > 0.0:
			continue

		# Shares the overtake cooldown deliberately. Both write the same line,
		# and a marble landing during someone else's pass should not stamp on it.
		_overtake_cooldown = OVERTAKE_COOLDOWN
		if marble.is_player:
			_hud.announce("You just made it", PLAYER_COLOUR)
			_pop_comic("PHEW!", PLAYER_COLOUR)
		else:
			_hud.announce("%s just made it" % marble.marble_name, marble.colour)


## The marble at a zero-based standings index, or null if there isn't one.
func _neighbour(index: int) -> Marble:
	if index < 0 or index >= _standings.size():
		return null
	return _standings[index]


func _announce_overtake(text: String, colour: Color) -> void:
	_overtake_cooldown = OVERTAKE_COOLDOWN
	if _hud != null and is_instance_valid(_hud):
		_hud.announce(text, colour)


## Anchored to the player's own marble regardless of which marble triggered the
## event — the camera always keeps the player on screen, an opponent might not
## be, and the pop is meant to land on the marble the child watching is
## actually tracking.
func _pop_comic(text: String, colour: Color) -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _camera == null or not is_instance_valid(_camera):
		return
	if _player == null or not is_instance_valid(_player):
		return

	# A small lift off the marble's centre so the projected point sits at its
	# side rather than its middle, then a fixed screen-space nudge to actually
	# clear it — a 3D offset would vary with camera angle, a 2D one doesn't.
	var beside := _player.global_position + Vector3(0.0, _tuning.radius * 0.6, 0.0)
	_hud.show_comic(_camera.unproject_position(beside) + Vector2(42.0, -6.0), text, colour)


func _course_offset(marble: Marble) -> float:
	if _course == null or not is_instance_valid(_course) or _course.curve == null:
		return 0.0
	return _course.curve.get_closest_offset(marble.global_position)


## One-based, or 0 when the player is gone. Reads off the cached ranking rather
## than recomputing, so calling it every frame from the HUD is free.
func _player_place() -> int:
	if _player == null or not is_instance_valid(_player):
		return 0
	return _standings.find(_player) + 1


# --- Outcomes -----------------------------------------------------------------


func _on_marble_finished(marble: Marble) -> void:
	marble.state = Marble.State.FINISHED
	_finish_order.append(marble)
	if marble.is_player:
		_sound.play_finish()
		_player_done = true
	_check_round_progress()


## Out-of-bounds detection. A simple height threshold is enough for Phase 0;
## the spec explicitly defers stuck detection until a prototype proves it is a
## real problem.
func _check_for_falls() -> void:
	for marble in _marbles:
		if marble.state != Marble.State.RACING:
			continue
		if marble.global_position.y < _course.fall_threshold_y():
			marble.state = Marble.State.ELIMINATED
			marble.visible = false
			marble.freeze = true
			if marble.is_player:
				_player_done = true
			_announce_fall(marble)

	_check_round_progress()


## A fall used to be a silent deletion: `visible = false` and the marble was
## simply never mentioned again. PROJECT.md section 2.3 lists falls as one of the
## things the physics is supposed to be entertaining *with*, and the most
## dramatic event on the course was producing no moment at all.
##
## The marble is already visibly falling by the time this runs — it has to clear
## the threshold, which is 20m below the finish — so this is the caption on
## something the viewer has just watched, not news.
func _announce_fall(marble: Marble) -> void:
	if marble.is_player:
		_sound.play_fall()

	if _hud == null or not is_instance_valid(_hud):
		return

	var left := 0
	for other in _marbles:
		if other.state == Marble.State.RACING or other.state == Marble.State.FINISHED:
			left += 1

	if marble.is_player:
		_hud.announce("You fell", PLAYER_COLOUR)
	else:
		# By name, which the standings column is also showing — so the row that
		# just went grey and the line that just appeared refer to each other.
		_hud.announce("%s is out — %d left" % [marble.marble_name, left], marble.colour)


## Starts the grace period once half the field has finished, and resolves the
## round immediately if the whole field is already done before that timer
## would otherwise run out — no point waiting out a grace period for nobody.
func _check_round_progress() -> void:
	if _phase == Phase.COMPLETE:
		return

	var still_racing := false
	for marble in _marbles:
		if marble.state == Marble.State.RACING:
			still_racing = true
			break

	if not still_racing:
		_resolve_round()
		return

	if _grace_timer < 0.0:
		var half := _marbles.size() / 2
		if half > 0 and _finish_order.size() >= half:
			_grace_timer = ROUND_GRACE_PERIOD


## Scores the round, decides the tournament's fate for the player, and — if
## they survive and it isn't already down to a winner — schedules the next
## round on a new course with the survivors' roster.
##
## Survivors are the top half of `_finish_order` by finish time, per
## PROJECT.md section 3; falling never counts as finishing, however few
## marbles actually crossed the line before the grace period ran out.
func _resolve_round() -> void:
	if _phase == Phase.COMPLETE:
		return
	_phase = Phase.COMPLETE
	_grace_timer = -1.0

	var survivor_count := maxi(1, _marbles.size() / 2)
	var survivors := _finish_order.slice(0, mini(survivor_count, _finish_order.size()))
	var player_survives := (
		_player != null and is_instance_valid(_player) and survivors.has(_player)
	)

	print(
		"Round %d complete in %.1fs | finished %d/%d | player %s"
		% [_round_number, _race_time, _finish_order.size(), _marbles.size(), _player_status()]
	)

	if not player_survives:
		_tournament_outcome = "eliminated"
		_hud.shout("ELIMINATED!", Color(0.95, 0.35, 0.35), OUTCOME_SHOUT_SECONDS)
		return
	if survivors.size() <= 1:
		_tournament_outcome = "won"
		_hud.shout("WINNER!", Color(1.0, 0.85, 0.3), OUTCOME_SHOUT_SECONDS)
		return

	_hud.shout("QUALIFIED!", Color(0.72, 0.95, 0.62), OUTCOME_SHOUT_SECONDS)

	var next_roster: Array = []
	for marble in survivors:
		next_roster.append({
			"colour": marble.colour, "name": marble.marble_name, "is_player": marble.is_player
		})

	_round_number += 1
	await get_tree().create_timer(NEXT_ROUND_DELAY).timeout
	_roster = next_roster
	_start_race()


# --- Presentation -------------------------------------------------------------


func _setup_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.30, 0.47, 0.74)
	sky_material.sky_horizon_color = Color(0.85, 0.74, 0.60)
	sky_material.ground_bottom_color = Color(0.26, 0.18, 0.14)
	sky_material.ground_horizon_color = Color(0.62, 0.44, 0.31)

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Lifted from 0.6 once the course grew six-metre canyon walls. They throw a
	# long shadow across the track, and at the old ambient level half the width
	# went nearly black — a marble in that half was unreadable, which section 2.5
	# does not allow. Ambient is what fills a canyon floor in reality too.
	environment.ambient_light_energy = 0.95

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	# Steeper and more square-on than the old 52/38. A low sun down a narrow
	# trough puts one wall's shadow across most of the track; near midday the
	# walls shade their own bases and the racing surface stays lit. Not quite
	# overhead, because some rake is what gives the marbles their own shadows,
	# and those shadows are the only cue that tells a viewer a marble is airborne
	# over the gap rather than rolling.
	sun.rotation_degrees = Vector3(-68.0, -22.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	_hud = RaceHUD.create()
	add_child(_hud)
	_hud.restart_requested.connect(_restart)

	_sound = SoundManager.create()
	add_child(_sound)

	_cut_marker = CutMarker.create()
	_cut_marker.visible = false
	add_child(_cut_marker)

	# Owned here rather than by the marble: it has to be positioned against the
	# camera every frame, and it outlives any one round's field.
	_rank_tag = RankTag.create(PLAYER_COLOUR)
	_rank_tag.visible = false
	add_child(_rank_tag)


func _update_hud() -> void:
	# Nothing to stand on before the barrier drops — the field is a stationary
	# grid and any order shown would be the arbitrary one they happen to be
	# ranked in. A column of noise is worse than an empty corner.
	_hud.show_standings([] if _phase == Phase.SETTLING else _standings_rows())

	match _phase:
		Phase.SETTLING:
			_run_countdown()
			_hud.show_text(
				"Round %d\nTap the barrier to start%s" % [_round_number, _camera_debug()]
			)
		Phase.RACING:
			_hud.show_text(
				"Round %d   %.1fs    %s%s"
				% [_round_number, _race_time, _live_position(), _camera_debug()]
			)
		Phase.COMPLETE:
			_hud.show_text("%s\nR restarts the tournament%s" % [_result_line(), _camera_debug()])


## Counts the field down to the release. Reads the barrier's own clock rather
## than keeping a second one, so tapping the barrier early simply ends the
## countdown instead of leaving it running against a race that already started.
func _run_countdown() -> void:
	if _barrier == null or not is_instance_valid(_barrier):
		return

	var count := ceili(_barrier.time_remaining())
	if count > COUNTDOWN_FROM or count <= 0:
		return

	# Counts must be called once each and in descending order; `_countdown_called`
	# starts at 0, so the first eligible number always passes.
	if _countdown_called == 0 or count < _countdown_called:
		_countdown_called = count
		_hud.shout(str(count), Color(0.95, 0.86, 0.62))


## Camera spike only. Which projection you are looking at is the whole question
## the spike asks, and after a few toggles it stops being obvious. Remove with
## Mode.OVERHEAD.
func _camera_debug() -> String:
	if _camera == null or not is_instance_valid(_camera):
		return ""
	return "\ncam: %s  (C)" % _camera.mode_name()


## Where the player is *right now*, which is the number the whole spectator
## premise rests on and which the HUD did not show until this existed: the race
## reported "racing" for twenty-eight seconds and then a finishing place, so
## there was no way to care about the middle.
##
## The cut line is called out because that is what the tournament will eliminate
## on (PROJECT.md section 3, top half survive), and being 6th or 7th is the only
## distinction on screen that will ever have stakes.
func _live_position() -> String:
	if _player == null or not is_instance_valid(_player):
		return ""

	match _player.state:
		Marble.State.ELIMINATED:
			return "out"
		Marble.State.FINISHED:
			return "finished %d/%d" % [_finish_order.find(_player) + 1, _marbles.size()]

	var place := _player_place()
	if place <= 0:
		return "racing"

	# Just the place. Whether that is above or below the cut is the standings
	# column's job, and saying it in two places at once is how a HUD gets busy.
	return "P%d of %d" % [place, _marbles.size()]


## The one line the race ends on.
##
## It used to end on "34.6s  finished 8/12  R to restart", which states an
## outcome without saying what the outcome means. The round eliminates the bottom
## half (PROJECT.md section 3), so eighth of twelve is not a score, it is being
## knocked out — and Phase 0's actual success criterion is whether you want to go
## again, which nothing was ever asking.
func _result_line() -> String:
	if _player == null or not is_instance_valid(_player):
		return "Race over"

	var total := _marbles.size()

	if _player.state == Marble.State.ELIMINATED:
		return "You fell.  Tournament over"

	var place := _finish_order.find(_player) + 1
	if place <= 0:
		return "Race over"

	var verdict := "Knocked out"
	if _tournament_outcome == "won":
		verdict = "Tournament won!"
	elif _tournament_outcome == "":
		verdict = "Through to Round %d" % _round_number

	return "Finished %s of %d.  %s" % [_ordinal(place), total, verdict]


func _ordinal(value: int) -> String:
	# 11th through 13th are the exceptions the naive rule gets wrong; the field
	# is twelve, so this is not hypothetical.
	var suffix := "th"
	if value % 100 < 11 or value % 100 > 13:
		match value % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [value, suffix]


func _player_status() -> String:
	if _player == null or not is_instance_valid(_player):
		return ""

	match _player.state:
		Marble.State.ELIMINATED:
			return "fell"
		Marble.State.FINISHED:
			return "finished %d/%d" % [_finish_order.find(_player) + 1, _marbles.size()]
		_:
			return "racing"
