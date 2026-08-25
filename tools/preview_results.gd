extends Node

## Renders `RoundResultsScreen` on its own, with a synthetic round result, so
## the layout can be looked at without racing a full course first.
##
## The screen is fed exactly the dictionary `race_manager.gd._show_results`
## builds, so what appears here is what appears in a real tournament — but a
## real one takes 30 seconds of race to reach, and reaching the *eliminated* or
## *won* states on purpose takes several.
##
## Usage (needs a window, so no `--headless` — see the note in
## `marble-jumble-headless-render` about `--write-movie`):
##
##     godot --path . --fixed-fps 60 --quit-after 150 \
##         --write-movie <dir>/f.png tools/preview_results.tscn -- survived
##
## The trailing word picks the case: `survived` (default), `eliminated`, `won`.

const SKINS := PlayerProfile.SKINS


func _ready() -> void:
	var mode := "survived"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]

	var field := _field(12)
	var results: Dictionary = {}
	match mode:
		"eliminated":
			results = {
				"round_number": 2,
				"field_size": 12,
				"player_place": 9,
				"player_survived": false,
				"tournament_over": true,
				"player_won": false,
				"survivors": field.slice(0, 6),
				"eliminated": _with_player(field.slice(6, 12), 2),
				"coins_awarded": 125,
			}
		"won":
			results = {
				"round_number": 3,
				"field_size": 3,
				"player_place": 1,
				"player_survived": true,
				"tournament_over": true,
				"player_won": true,
				"survivors": _with_player(field.slice(0, 1), 0),
				"eliminated": field.slice(1, 3),
				"coins_awarded": 100,
			}
		_:
			results = {
				"round_number": 1,
				"field_size": 12,
				"player_place": 4,
				"player_survived": true,
				"tournament_over": false,
				"player_won": false,
				"survivors": _with_player(field.slice(0, 6), 3),
				"eliminated": field.slice(6, 12),
				"coins_awarded": 0,
			}

	var screen := RoundResultsScreen.create(results)
	add_child(screen)
	print("preview: %s" % mode)


## Eleven opponents plus a slot for the player, built the way a real round
## builds them: opponents are flat colours with no skin (`race_manager.gd`
## `_opponent_colour`), and only the player carries an entry from
## `PlayerProfile.SKINS`. The shop's palette is borrowed for the flat colours so
## the row spans the same hue range a real field does.
func _field(count: int) -> Array:
	var entries: Array = []
	for i in count:
		var skin: Dictionary = SKINS[i % SKINS.size()]
		entries.append({
			"colour": skin["colour"],
			"name": "M%d" % i,
			"is_player": false,
			"skin": {},
		})
	return entries


func _with_player(entries: Array, index: int) -> Array:
	var out := entries.duplicate(true)
	if index < out.size():
		out[index]["is_player"] = true
		out[index]["name"] = "You"
		out[index]["colour"] = PlayerProfile.equipped_colour()
		out[index]["skin"] = PlayerProfile.equipped_skin_data()
	return out
