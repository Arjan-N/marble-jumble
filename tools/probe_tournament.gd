extends Node

## Runs a whole tournament headlessly, pressing CONTINUE for itself.
##
##     godot --headless --path . res://tools/probe_tournament.tscn \
##       --fixed-fps 60 --disable-render-loop --quit-after 12000
##
## `tools/probe_course.gd` answers "does the field get down this course". This
## answers the question above that one: does a round *resolve* correctly, and
## does the next one start with the right marbles. It exists because the finish
## rework (`scripts/course/finish_zone.gd`) changed when a round ends — the grace
## period now starts once the survivors are decided *and* the player's own run is
## over, rather than at the 50% mark — and that is exactly the kind of change
## that scores a round right and hands the wrong field to the next one.
##
## It drives the real `race_manager.gd` rather than a copy of it, and reads the
## results screen's own payload, so there is nothing here to keep in step with
## the rules: if the survivor rule changes, this reports the new one.
##
## A **scene**, not a `--script` SceneTree, for the reason `probe_course.gd`
## records: `--headless --script` compiles before the autoloads exist and
## `marble.gd`'s `PlayerProfile` reference fails.

const MAIN: PackedScene = preload("res://scenes/main.tscn")

## How long to wait on a results screen before pressing CONTINUE. Long enough
## that the screen is genuinely up rather than mid-construction; short enough
## that three rounds fit in a sensible frame budget.
const CONTINUE_DELAY := 0.5

var _race: Node3D
var _screen_seen: Node = null
var _wait := 0.0
var _rounds := 0


func _ready() -> void:
	_race = MAIN.instantiate()
	add_child(_race)


func _process(delta: float) -> void:
	if _race == null or not is_instance_valid(_race):
		return

	var screen := _find_results_screen()

	if screen == null:
		_screen_seen = null
		return

	if screen != _screen_seen:
		_screen_seen = screen
		_wait = CONTINUE_DELAY
		_rounds += 1
		_report(screen)
		return

	_wait -= delta
	if _wait > 0.0:
		return

	# A finished tournament has nothing to continue to; the round count and the
	# reports above are the whole result.
	if not screen.has_signal("continue_pressed"):
		get_tree().quit()
		return

	if _tournament_over(screen):
		print("tournament over after %d round(s)" % _rounds)
		get_tree().quit()
		return

	screen.continue_pressed.emit()
	_wait = CONTINUE_DELAY


## The results screen is built by `race_manager._show_results` and parented to
## the race node, so it is found by type rather than by a path this probe would
## otherwise have to guess at.
func _find_results_screen() -> Node:
	for child in _race.get_children():
		if child is RoundResultsScreen:
			return child
	return null


## Read off the screen's own payload rather than reaching into the race
## manager's private state, so this measures what the player is actually shown.
func _tournament_over(screen: Node) -> bool:
	var data: Dictionary = screen.get("_results")
	return bool(data.get("tournament_over", false))


func _report(screen: Node) -> void:
	var data: Dictionary = screen.get("_results")
	var survivors: Array = data.get("survivors", [])
	var names := PackedStringArray()
	for entry: Dictionary in survivors:
		names.append(String(entry.get("name", "?")))

	print(
		"round %d | field %d | player %s (place %s) | survivors %d: %s"
		% [
			int(data.get("round_number", 0)),
			int(data.get("field_size", 0)),
			"through" if bool(data.get("player_survived", false)) else "out",
			data.get("player_place", 0),
			survivors.size(),
			", ".join(names),
		]
	)
