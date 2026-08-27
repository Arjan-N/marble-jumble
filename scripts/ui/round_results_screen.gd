class_name RoundResultsScreen
extends CanvasLayer

## The end-of-round results screen: who survived, who is out, and what happens
## next. `PROJECT.md` section 4 calls the moment between courses a core product
## feature rather than a loading screen, and until now it was a three-second
## `QUALIFIED!` shout over a frozen race.
##
## It holds no tournament state of its own. `race_manager.gd` scores the round
## exactly as it always did and hands the finished result over through
## `create`; everything here is presentation. The three signals are the only
## way out, so the race cannot advance until the player asks it to.
##
## The marbles are the game's real `Marble` instances rendered in 3D
## (`marble_row_view.gd`), not swatches — a player who bought a Cat's Eye should
## see a Cat's Eye on the results screen.

## Emitted when a surviving player asks for the next round.
signal continue_pressed
## Emitted when a finished tournament should be replaced with a fresh one.
signal play_again_pressed
## Emitted when the player would rather leave the race scene entirely.
signal home_pressed

const COIN_INDICATOR_TEXTURE := preload("res://assets/ui/coins_indicator.png")
## The coin's own circle inside that pill artwork (1812x517), used on its own
## for the reward particles. Measured off the source image.
const COIN_REGION := Rect2(88.0, 74.0, 376.0, 376.0)

## Design space, matching `project.godot`'s 720x1280 viewport. Every size below
## is in these units and is scaled by `_scale()` at layout time, so the screen
## keeps its proportions on a phone whose aspect is not exactly 9:16.
const DESIGN := Vector2(720.0, 1280.0)

## Panel geometry, in design pixels. The panels measure themselves from these
## and from how many marbles they hold (`_panel_metrics`) rather than carrying a
## fixed height, because the marble diameter follows the cell width and the
## field shrinks 12 → 6 → 3 → 1 across a tournament.
const TAB_HEIGHT := 52.0
const SUBTITLE_HEIGHT := 30.0
const SUBTITLE_GAP := 4.0
## Vertical room reserved above the row for the finishing-place captions and the
## red crosses respectively, and below it for the YOU pill.
const CAPTION_BAND := 38.0
const CROSS_BAND := 30.0
const PILL_BAND := 44.0
## Room below the row for each marble's name, on every panel.
const NAME_BAND := 32.0
const PANEL_PAD := 28.0
const ROW_INSET := 14.0
## Widest a single marble's cell may get. Without a cap, the final round's lone
## winner would be drawn as one ball across the whole plate.
const MAX_CELL := 118.0
## Row height as a multiple of the cell, leaving a little air above and below the
## ball so the ink outline is never clipped by the plate.
const ROW_HEIGHT_RATIO := 1.06
const SUMMARY_HEIGHT := 62.0
const ACTION_HEIGHT_CONTINUE := 112.0
const ACTION_HEIGHT_GAME_OVER := 192.0
const MARGIN_X := 24.0
const BOTTOM_MARGIN := 22.0

## Beat gaps for the reveal, in seconds. The whole surviving-player sequence
## runs in about 1.9s — the brief asks for 1.5-2.5s and explicitly not to make
## the player wait. A tournament-ending round adds the reward beat on the end.
const BEAT_TITLE := 0.05
const BEAT_PLACE := 0.28
const BEAT_SURVIVORS := 0.24
const BEAT_ELIMINATED := 0.42
const BEAT_CROSSES := 0.40
const BEAT_SUMMARY := 0.30
const BEAT_ACTIONS := 0.22
const BEAT_REWARD := 0.25
const BEAT_OUTCOME := 1.35
## Stagger between marbles inside a row, and between the crosses.
const MARBLE_STAGGER := 0.05

const COIN_PARTICLES := 9
const COIN_FLIGHT := 0.55
const COIN_STAGGER := 0.055

var _results: Dictionary = {}

var _root: Control
var _dim: TextureRect
var _title_round: Label
var _title_complete: Label
var _place_badge: Control
var _survivors_panel: Control
var _eliminated_panel: Control
var _summary: Control
var _actions: Control
var _continue_button: ChunkyButton
var _play_again_button: ChunkyButton
var _home_button: ChunkyButton
var _coin_pill: TextureRect
var _coins_label: Label
var _coin_layer: Control
var _reward_label: Label

## The screen's own voice. The race's `SoundManager` lives on `race_manager`
## and dies with the race scene on the way to the shop, so the results screen
## carries one rather than borrowing it.
var _sound: SoundManager
## How many coins have landed, counted as they arrive so the ding run rises in
## the order the player hears them.
var _coins_landed := 0

var _sequence: Tween
var _revealed: Array[Control] = []
var _finished := false
var _coins_paid := false


static func create(results: Dictionary) -> RoundResultsScreen:
	var screen := RoundResultsScreen.new()
	screen.name = "RoundResultsScreen"
	# Above the race HUD's default layer so nothing from the race shows through
	# the panels.
	screen.layer = 20
	screen._results = results
	screen._build()
	return screen


# --- Construction -------------------------------------------------------------


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Stops every stray tap reaching the race underneath (the barrier is still
	# listening) and gives the sequence something to be skipped by.
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_root_input)
	add_child(_root)

	_sound = SoundManager.create()
	add_child(_sound)

	_build_dim()
	_build_coin_pill()
	_build_title()
	_build_place_badge()
	_build_panels()
	_build_summary()
	_build_actions()
	_build_reward_label()

	_coin_layer = Control.new()
	_coin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_coin_layer)

	_root.resized.connect(_layout)


func _ready() -> void:
	_layout()
	for control in _revealed:
		control.modulate.a = 0.0
		control.scale = Vector2(0.72, 0.72)
	_dim.modulate.a = 0.0
	_run_sequence()


## A vertical wash rather than a flat scrim: the course still reads at the top
## of the frame, where the mock-up shows it, and the panels sit on something
## solid enough to be legible at the bottom.
func _build_dim() -> void:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.02, 0.015, 0.02, 0.30))
	ramp.set_color(1, Color(0.02, 0.015, 0.02, 0.86))
	ramp.add_point(0.34, Color(0.02, 0.015, 0.02, 0.62))
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 4
	texture.height = 256

	_dim = TextureRect.new()
	_dim.texture = texture
	_dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dim.stretch_mode = TextureRect.STRETCH_SCALE
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)


## The same coin pill the home screen wears, in the same corner — it is the
## target the reward animation flies into, so it has to be the counter the
## player already recognises.
func _build_coin_pill() -> void:
	_coin_pill = TextureRect.new()
	_coin_pill.texture = COIN_INDICATOR_TEXTURE
	_coin_pill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_pill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_coin_pill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_coin_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_coin_pill)

	_coins_label = UIKit.label("%d" % PlayerProfile.coins, 30, UIKit.CREAM, 5)
	_coins_label.anchor_left = 0.26
	_coins_label.anchor_right = 0.96
	_coins_label.anchor_bottom = 1.0
	_coin_pill.add_child(_coins_label)


## Two lines, so the comic-book stack of the mock-up survives. A round the
## player came through is "ROUND 2 / COMPLETE!"; the round that ends the
## tournament — won or lost — says so instead, because "ROUND 3 COMPLETE" reads
## as though there is a Round 4 coming.
func _build_title() -> void:
	var over: bool = bool(_results.get("tournament_over", false))
	var lead := "TOURNAMENT" if over else "ROUND %d" % int(_results.get("round_number", 1))
	_title_round = UIKit.label(lead, 62, UIKit.CREAM, 12)
	_title_complete = UIKit.label("COMPLETE!", 96, UIKit.GOLD, 14)
	for label in [_title_round, _title_complete]:
		_root.add_child(label)
		_revealed.append(label)


## "YOU FINISHED 4TH", with the position in the player's own highlight colour.
## Two labels in a row rather than one string, because the two halves are set at
## different sizes and colours in the mock-up.
func _build_place_badge() -> void:
	var place := int(_results.get("player_place", 0))
	var survived: bool = bool(_results.get("player_survived", false))

	_place_badge = Control.new()
	_place_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_place_badge)
	_revealed.append(_place_badge)

	var accent := UIKit.CYAN if survived else UIKit.RED
	var background := UIKit.panel(UIKit.plate(UIKit.PANEL_TAB_INK, UIKit.INK, 5, 16))
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_place_badge.add_child(background)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	_place_badge.add_child(row)

	var lead := UIKit.label("YOU FINISHED", 34, UIKit.MUTED, 6)
	lead.name = "Lead"
	row.add_child(lead)
	var value := UIKit.label(UIKit.ordinal(place), 48, accent, 7)
	value.name = "Value"
	row.add_child(value)


func _build_panels() -> void:
	var survivors: Array = _results.get("survivors", [])
	var eliminated: Array = _results.get("eliminated", [])
	var won: bool = bool(_results.get("player_won", false))

	var survivor_title := "WINNER" if won else "SURVIVORS"
	var survivor_subtitle := (
		"TOURNAMENT CHAMPION" if won else "%d REMAIN" % survivors.size()
	)
	_survivors_panel = _build_marble_panel(
		survivor_title, survivor_subtitle, survivors, UIKit.GOLD_DEEP, UIKit.TEAL, false, true
	)
	_eliminated_panel = _build_marble_panel(
		"ELIMINATED", "%d OUT" % eliminated.size(), eliminated, UIKit.RED, UIKit.RED_DEEP, true, false
	)


## One dark framed plate with a header tab straddling its top edge, a row of
## real marbles, and — for the survivors — a finishing-place caption over each
## and a YOU pill under the player's.
func _build_marble_panel(
	title: String,
	subtitle: String,
	entries: Array,
	border: Color,
	tab_colour: Color,
	dimmed: bool,
	show_ranks: bool
) -> Control:
	var panel := Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)
	_revealed.append(panel)

	var background := UIKit.panel(UIKit.plate(UIKit.PANEL_FILL, border, 5, 22))
	background.name = "Background"
	panel.add_child(background)

	# Behind the row, so the player's marble sits in a pool of its own light.
	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.texture = _glow_texture()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	panel.add_child(glow)

	var row := MarbleRowView.create(entries, dimmed)
	row.name = "Row"
	panel.add_child(row)

	var tab := UIKit.panel(UIKit.plate(tab_colour, UIKit.INK, 5, 14))
	tab.name = "Tab"
	panel.add_child(tab)
	var tab_label := UIKit.label(title, 40, UIKit.CREAM, 7)
	tab_label.name = "TabLabel"
	tab_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab.add_child(tab_label)

	var subtitle_label := UIKit.label(subtitle, 26, border.lightened(0.35), 6)
	subtitle_label.name = "Subtitle"
	panel.add_child(subtitle_label)

	var captions: Array[Label] = []
	var crosses: Array[CrossMark] = []
	var names: Array[Label] = []
	var you_pill: Control = null
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var is_player: bool = bool(entry.get("is_player", false))
		if show_ranks:
			var caption := UIKit.label(
				UIKit.ordinal(i + 1), 30, UIKit.GOLD if i == 0 else UIKit.MUTED, 6
			)
			if is_player:
				caption.add_theme_color_override("font_color", UIKit.CYAN)
			panel.add_child(caption)
			captions.append(caption)
		if dimmed:
			var cross := CrossMark.create(44.0)
			panel.add_child(cross)
			crosses.append(cross)
		var name_label := UIKit.label(
			String(entry.get("name", "")).to_upper(), 22, UIKit.CYAN if is_player else UIKit.MUTED, 4
		)
		name_label.clip_text = true
		panel.add_child(name_label)
		names.append(name_label)
		if is_player:
			you_pill = _build_you_pill()
			panel.add_child(you_pill)
			glow.visible = true
			glow.set_meta("cell", i)

	panel.set_meta("row", row)
	panel.set_meta("captions", captions)
	panel.set_meta("crosses", crosses)
	panel.set_meta("names", names)
	panel.set_meta("you_pill", you_pill)
	panel.set_meta("entries", entries.size())
	return panel


## The player's YOU pill, or null when the player is not in this panel.
##
## Guarded with `has_meta` rather than a default on `get_meta`: setting a meta
## to `null` erases the key, and `get_meta(key, null)` is indistinguishable from
## `get_meta(key)` to the engine, so both spellings raise instead of returning
## nothing. Every round has exactly one panel without a player in it.
func _you_pill(panel: Control) -> Control:
	if not panel.has_meta("you_pill"):
		return null
	return panel.get_meta("you_pill") as Control


func _build_you_pill() -> Control:
	var pill := Control.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := UIKit.panel(UIKit.plate(UIKit.PANEL_TAB_INK, UIKit.GOLD, 4, 12))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pill.add_child(background)
	var label := UIKit.label("YOU", 24, UIKit.GOLD, 5)
	label.name = "Label"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pill.add_child(label)
	return pill


## Radial gold wash marking the player's cell. A `GradientTexture2D` rather
## than a drawn circle so it falls off smoothly against the panel fill.
func _glow_texture() -> GradientTexture2D:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(UIKit.GOLD, 0.42))
	ramp.set_color(1, Color(UIKit.GOLD, 0.0))
	ramp.add_point(0.45, Color(UIKit.GOLD, 0.22))
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


func _build_summary() -> void:
	var survivors: int = int(_results.get("survivors", []).size())
	var field: int = int(_results.get("field_size", 0))

	_summary = Control.new()
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_summary)
	_revealed.append(_summary)

	var background := UIKit.panel(UIKit.plate(UIKit.PANEL_TAB_INK, UIKit.INK, 5, 16))
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary.add_child(background)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	_summary.add_child(row)

	var live := UIKit.label("%d" % survivors, 42, UIKit.CYAN, 7)
	live.name = "Live"
	row.add_child(live)
	var slash := UIKit.label("/", 38, UIKit.MUTED, 6)
	slash.name = "Slash"
	row.add_child(slash)
	var total := UIKit.label("%d" % field, 42, UIKit.CREAM, 7)
	total.name = "Total"
	row.add_child(total)
	var caption := UIKit.label("SURVIVED", 32, UIKit.MUTED, 6)
	caption.name = "Caption"
	row.add_child(caption)


func _build_actions() -> void:
	_actions = Control.new()
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_actions)
	_revealed.append(_actions)

	var over: bool = bool(_results.get("tournament_over", false))
	if over:
		_play_again_button = ChunkyButton.create("PLAY AGAIN", 46, true)
		_play_again_button.pressed.connect(func() -> void: play_again_pressed.emit())
		_actions.add_child(_play_again_button)
		_home_button = ChunkyButton.create("HOME", 30, false)
		_home_button.pressed.connect(func() -> void: home_pressed.emit())
		_actions.add_child(_home_button)
	else:
		_continue_button = ChunkyButton.create("CONTINUE  >", 46, true)
		_continue_button.pressed.connect(func() -> void: continue_pressed.emit())
		_actions.add_child(_continue_button)


## The "+125 COINS" line. Transient by design — it appears with the coins, rides
## upward and fades — so it is allowed to pass over the panels below it rather
## than being given a row of its own. There is no row to give it: a
## tournament-ending screen already carries the taller PLAY AGAIN / HOME stack.
##
## The verdict itself has no widget here. It is delivered by rewriting the
## title's second line in `_reveal_outcome` — see the note there.
func _build_reward_label() -> void:
	if not bool(_results.get("tournament_over", false)):
		return
	_reward_label = UIKit.label(
		"+%d COINS" % int(_results.get("coins_awarded", 0)), 54, UIKit.GOLD, 10
	)
	_reward_label.visible = false
	_root.add_child(_reward_label)


# --- Layout -------------------------------------------------------------------


## Uniform scale from the 720x1280 design space, taking whichever axis is
## tighter so the composition never overflows a phone whose aspect is not
## exactly 9:16. The stack is placed bottom-up from the CONTINUE button and
## top-down from the title; any slack lands in the middle, which is where the
## course is meant to show through.
func _scale() -> float:
	var view := _root.size
	if view.x <= 0.0 or view.y <= 0.0:
		return 1.0
	return minf(view.x / DESIGN.x, view.y / DESIGN.y)


func _layout() -> void:
	if _root == null:
		return
	var view := _root.size
	var s := _scale()
	var content_width := DESIGN.x * s
	var x0 := (view.x - content_width) * 0.5
	var inner_x := x0 + MARGIN_X * s
	var inner_width := content_width - MARGIN_X * 2.0 * s

	# Top-down.
	var pill_width := 235.0 * s
	var pill_height := 67.0 * s
	_coin_pill.position = Vector2(x0 + content_width - 19.0 * s - pill_width, 10.0 * s)
	_coin_pill.size = Vector2(pill_width, pill_height)
	_set_font(_coins_label, 30.0 * s)

	_place_label(_title_round, x0, 88.0 * s, content_width, 68.0 * s, 62.0 * s)
	_place_label(_title_complete, x0, 146.0 * s, content_width, 106.0 * s, 96.0 * s)

	var badge_width := 470.0 * s
	_place_badge.position = Vector2(x0 + (content_width - badge_width) * 0.5, 262.0 * s)
	_place_badge.size = Vector2(badge_width, 66.0 * s)
	_layout_centre_row(_place_badge, [["Lead", 34.0], ["Value", 48.0]], s)

	# Bottom-up.
	var over: bool = bool(_results.get("tournament_over", false))
	var action_height := (ACTION_HEIGHT_GAME_OVER if over else ACTION_HEIGHT_CONTINUE) * s
	var action_top := view.y - BOTTOM_MARGIN * s - action_height
	_actions.position = Vector2(inner_x, action_top)
	_actions.size = Vector2(inner_width, action_height)
	_layout_actions(s, inner_width)

	var summary_height := SUMMARY_HEIGHT * s
	var summary_width := 560.0 * s
	var summary_top := action_top - 18.0 * s - summary_height
	_summary.position = Vector2(x0 + (content_width - summary_width) * 0.5, summary_top)
	_summary.size = Vector2(summary_width, summary_height)
	_layout_centre_row(
		_summary, [["Live", 42.0], ["Slash", 38.0], ["Total", 42.0], ["Caption", 32.0]], s
	)

	var eliminated_metrics := _panel_metrics(_eliminated_panel, s, inner_width)
	var eliminated_top := summary_top - 20.0 * s - float(eliminated_metrics["height"])
	_eliminated_panel.position = Vector2(inner_x, eliminated_top)
	_eliminated_panel.size = Vector2(inner_width, float(eliminated_metrics["height"]))
	_layout_panel(_eliminated_panel, s, eliminated_metrics)

	var survivor_metrics := _panel_metrics(_survivors_panel, s, inner_width)
	var survivors_top := eliminated_top - 26.0 * s - float(survivor_metrics["height"])
	_survivors_panel.position = Vector2(inner_x, survivors_top)
	_survivors_panel.size = Vector2(inner_width, float(survivor_metrics["height"]))
	_layout_panel(_survivors_panel, s, survivor_metrics)

	# The reward line starts in the gap under the place badge and rises out of
	# it; `_start_reward` remembers this as its resting position.
	if _reward_label != null:
		_place_label(
			_reward_label,
			x0,
			_place_badge.position.y + _place_badge.size.y + 24.0 * s,
			content_width,
			64.0 * s,
			54.0 * s
		)


func _place_label(label: Label, x: float, y: float, width: float, height: float, font: float) -> void:
	label.position = Vector2(x, y)
	label.size = Vector2(width, height)
	label.pivot_offset = Vector2(width, height) * 0.5
	_set_font(label, font)


func _set_font(label: Label, font: float) -> void:
	label.add_theme_font_size_override("font_size", maxi(int(round(font)), 1))


## Centres a named HBox of labels inside a badge, re-applying each label's own
## design font size at the current scale. The row is sized to the badge and
## centred by the container, so nothing here has to measure text.
func _layout_centre_row(host: Control, entries: Array, s: float) -> void:
	var row := host.get_node_or_null("Row") as HBoxContainer
	if row == null:
		return
	row.position = Vector2.ZERO
	row.size = host.size
	row.add_theme_constant_override("separation", int(round(12.0 * s)))
	for entry in entries:
		var label := row.get_node_or_null(String(entry[0])) as Label
		if label != null:
			_set_font(label, float(entry[1]) * s)
	host.pivot_offset = host.size * 0.5


## What a panel needs to be, given how many marbles are in it.
##
## The row's marble size follows from its cell width, so a panel with three
## marbles in it would otherwise draw them at twice the diameter of a panel with
## six — and the final round's single winner at six times. `MAX_CELL` caps the
## cell so a short row draws normal-sized marbles and simply narrows, centred,
## instead of inflating to fill the plate. Everything else is stacked from that,
## which is why the height is measured here rather than being a constant: a
## fixed height with a width-derived marble in it clips the ball as soon as the
## field is small.
func _panel_metrics(panel: Control, s: float, width: float) -> Dictionary:
	var count: int = maxi(int(panel.get_meta("entries")), 1)
	var has_captions: bool = not (panel.get_meta("captions") as Array).is_empty()
	var has_crosses: bool = not (panel.get_meta("crosses") as Array).is_empty()
	var has_pill: bool = _you_pill(panel) != null

	var cell := minf((width - ROW_INSET * 2.0 * s) / float(count), MAX_CELL * s)
	var row_width := cell * float(count)
	var row_height := cell * ROW_HEIGHT_RATIO

	var head := (TAB_HEIGHT + SUBTITLE_HEIGHT + SUBTITLE_GAP) * s
	var caption_band := CAPTION_BAND * s if has_captions else 0.0
	var cross_band := CROSS_BAND * s if has_crosses else 0.0
	var name_band := NAME_BAND * s
	var pill_band := PILL_BAND * s if has_pill else 0.0

	return {
		"cell": cell,
		"row_width": row_width,
		"row_height": row_height,
		"row_top": head + caption_band + cross_band,
		"height": (
			head + caption_band + cross_band + row_height + name_band + pill_band + PANEL_PAD * s
		),
	}


func _layout_panel(panel: Control, s: float, metrics: Dictionary) -> void:
	var width := panel.size.x
	var height := panel.size.y
	panel.pivot_offset = Vector2(width, height) * 0.5

	var tab_height := TAB_HEIGHT * s
	var background := panel.get_node("Background") as Panel
	background.position = Vector2(0.0, tab_height * 0.5)
	background.size = Vector2(width, height - tab_height * 0.5)

	var tab := panel.get_node("Tab") as Panel
	var tab_width := 320.0 * s
	tab.position = Vector2((width - tab_width) * 0.5, 0.0)
	tab.size = Vector2(tab_width, tab_height)
	_set_font(tab.get_node("TabLabel") as Label, 40.0 * s)

	var subtitle := panel.get_node("Subtitle") as Label
	subtitle.position = Vector2(0.0, tab_height + SUBTITLE_GAP * s)
	subtitle.size = Vector2(width, SUBTITLE_HEIGHT * s)
	_set_font(subtitle, 26.0 * s)

	var captions: Array = panel.get_meta("captions")
	var crosses: Array = panel.get_meta("crosses")
	var names: Array = panel.get_meta("names")
	var you_pill := _you_pill(panel)
	var row := panel.get_meta("row") as MarbleRowView

	var row_top: float = metrics["row_top"]
	var row_width: float = metrics["row_width"]
	row.position = Vector2((width - row_width) * 0.5, row_top)
	row.layout(Vector2(row_width, float(metrics["row_height"])))

	var radius := row.marble_radius_px()
	var name_top := row.position.y + row.size.y
	for i in names.size():
		var name_label := names[i] as Label
		var name_width := row.cell_centre_x(1) - row.cell_centre_x(0) if names.size() > 1 else row_width
		name_width = maxf(name_width, 70.0 * s)
		name_label.position = Vector2(
			row.position.x + row.cell_centre_x(i) - name_width * 0.5, name_top
		)
		name_label.size = Vector2(name_width, NAME_BAND * s)
		_set_font(name_label, 22.0 * s)

	for i in captions.size():
		var caption := captions[i] as Label
		var caption_width := 120.0 * s
		caption.position = Vector2(
			row.position.x + row.cell_centre_x(i) - caption_width * 0.5, row_top - 36.0 * s
		)
		caption.size = Vector2(caption_width, 34.0 * s)
		caption.pivot_offset = caption.size * 0.5
		_set_font(caption, 30.0 * s)

	# Sat in the reserved band above the row and dipped slightly onto the top of
	# the ball, as in the mock-up — clear of the subtitle above it either way.
	for i in crosses.size():
		var cross := crosses[i] as CrossMark
		var side := 46.0 * s
		cross.size = Vector2(side, side)
		cross.pivot_offset = cross.size * 0.5
		cross.position = Vector2(
			row.position.x + row.cell_centre_x(i) - side * 0.5,
			row.position.y + row.size.y * 0.5 - radius - side * 0.55
		)
		cross.queue_redraw()

	var glow := panel.get_node("Glow") as TextureRect
	if glow.visible:
		var cell := int(glow.get_meta("cell"))
		var glow_side := radius * 3.4
		glow.position = Vector2(
			row.position.x + row.cell_centre_x(cell) - glow_side * 0.5,
			row.position.y + row.size.y * 0.5 - glow_side * 0.5
		)
		glow.size = Vector2(glow_side, glow_side)
		if you_pill != null:
			var pill_width := 118.0 * s
			var pill_height := 42.0 * s
			you_pill.position = Vector2(
				row.position.x + row.cell_centre_x(cell) - pill_width * 0.5,
				name_top + NAME_BAND * s
			)
			you_pill.size = Vector2(pill_width, pill_height)
			you_pill.pivot_offset = you_pill.size * 0.5
			_set_font(you_pill.get_node("Label") as Label, 24.0 * s)


func _layout_actions(s: float, width: float) -> void:
	var button_width := 470.0 * s
	var x := (width - button_width) * 0.5
	if _continue_button != null:
		_continue_button.position = Vector2(x, 0.0)
		_continue_button.size = Vector2(button_width, 104.0 * s)
	if _play_again_button != null:
		_play_again_button.position = Vector2(x, 0.0)
		_play_again_button.size = Vector2(button_width, 104.0 * s)
	if _home_button != null:
		var home_width := 240.0 * s
		_home_button.position = Vector2((width - home_width) * 0.5, 118.0 * s)
		_home_button.size = Vector2(home_width, 66.0 * s)
	_actions.pivot_offset = _actions.size * 0.5


# --- Reveal sequence ----------------------------------------------------------


func _run_sequence() -> void:
	_sequence = create_tween()
	_sequence.tween_property(_dim, "modulate:a", 1.0, 0.18)
	_sequence.tween_callback(_reveal_title).set_delay(BEAT_TITLE)
	_sequence.tween_callback(_reveal_place).set_delay(BEAT_PLACE)
	_sequence.tween_callback(func() -> void: _reveal_panel(_survivors_panel, false)).set_delay(
		BEAT_SURVIVORS
	)
	_sequence.tween_callback(func() -> void: _reveal_panel(_eliminated_panel, false)).set_delay(
		BEAT_ELIMINATED
	)
	_sequence.tween_callback(_reveal_crosses).set_delay(BEAT_CROSSES)
	_sequence.tween_callback(func() -> void: _pop(_summary)).set_delay(BEAT_SUMMARY)

	if bool(_results.get("tournament_over", false)):
		_sequence.tween_callback(_start_reward).set_delay(BEAT_REWARD)
		_sequence.tween_callback(_reveal_outcome).set_delay(BEAT_OUTCOME)
	else:
		_sequence.tween_callback(func() -> void: _pop(_actions)).set_delay(BEAT_ACTIONS)
	_sequence.tween_callback(func() -> void: _finished = true)


func _reveal_title() -> void:
	_pop(_title_round)
	_pop(_title_complete, 0.06)


func _reveal_place() -> void:
	_pop(_place_badge)


## Panel plate first, then its marbles one at a time. The row itself is a single
## `SubViewport`, so the stagger is applied to the 2D furniture over each cell —
## the caption, the YOU pill — and the plate carries the row in with it.
func _reveal_panel(panel: Control, _unused: bool) -> void:
	_pop(panel)
	var captions: Array = panel.get_meta("captions")
	for i in captions.size():
		var caption := captions[i] as Control
		caption.modulate.a = 0.0
		caption.scale = Vector2(0.5, 0.5)
		_pop(caption, 0.10 + float(i) * MARBLE_STAGGER)
	var names: Array = panel.get_meta("names")
	for i in names.size():
		var name_label := names[i] as Control
		name_label.modulate.a = 0.0
		name_label.scale = Vector2(0.5, 0.5)
		_pop(name_label, 0.10 + float(i) * MARBLE_STAGGER)
	var you_pill := _you_pill(panel)
	if you_pill != null:
		you_pill.modulate.a = 0.0
		you_pill.scale = Vector2(0.5, 0.5)
		_pop(you_pill, 0.10 + float(names.size()) * MARBLE_STAGGER)


func _reveal_crosses() -> void:
	var crosses: Array = _eliminated_panel.get_meta("crosses")
	for i in crosses.size():
		var cross := crosses[i] as Control
		cross.modulate.a = 0.0
		cross.scale = Vector2(1.9, 1.9)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(cross, "modulate:a", 1.0, 0.10).set_delay(float(i) * 0.04)
		# Stamped on from above rather than grown: a cross that swells into place
		# reads as decoration, one that lands reads as a verdict.
		(
			tween
			. tween_property(cross, "scale", Vector2.ONE, 0.16)
			. set_delay(float(i) * 0.04)
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
		)


## The chunky arrival every element on this screen uses: overshoot in, settle.
func _pop(control: Control, delay: float = 0.0) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, 0.14).set_delay(delay)
	(
		tween
		. tween_property(control, "scale", Vector2.ONE, 0.30)
		. set_delay(delay)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


# --- Reward -------------------------------------------------------------------


## Pays the reward and flies it into the counter.
##
## `PlayerProfile.add_coins` is called up front rather than when the last coin
## lands: the balance is the real thing and must not depend on an animation
## finishing, or on the player not leaving the screen halfway through. The
## counter is then ticked up by hand across the flight so the number still
## arrives with the coins.
func _start_reward() -> void:
	var amount := int(_results.get("coins_awarded", 0))
	if amount <= 0 or _coins_paid:
		return
	_coins_paid = true

	var before := PlayerProfile.coins
	PlayerProfile.add_coins(amount)
	var after := PlayerProfile.coins

	_reward_label.visible = true
	_reward_label.modulate.a = 0.0
	_reward_label.scale = Vector2(0.6, 0.6)
	_pop(_reward_label)

	var origin := _reward_label.position + _reward_label.size * 0.5
	var target := _coin_pill.position + Vector2(_coin_pill.size.x * 0.13, _coin_pill.size.y * 0.5)
	var side := _coin_pill.size.y * 0.62

	for i in COIN_PARTICLES:
		_fly_coin(origin, target, side, float(i) * COIN_STAGGER)

	var counter := create_tween()
	counter.tween_method(
		func(value: float) -> void:
			_coins_label.text = "%d" % int(round(value)),
		float(before),
		float(after),
		COIN_FLIGHT + COIN_STAGGER * float(COIN_PARTICLES)
	)
	counter.tween_callback(func() -> void: _coins_label.text = "%d" % PlayerProfile.coins)


## One coin arcing from the reward line into the counter. The control point is
## pushed sideways and up so the coins fan out rather than sliding along a
## single straight line, which is what makes a handful of them read as a spill
## of coins rather than as one sprite drawn nine times.
func _fly_coin(origin: Vector2, target: Vector2, side: float, delay: float) -> void:
	var coin := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = COIN_INDICATOR_TEXTURE
	atlas.region = COIN_REGION
	coin.texture = atlas
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.size = Vector2(side, side)
	coin.pivot_offset = coin.size * 0.5
	coin.modulate.a = 0.0
	_coin_layer.add_child(coin)

	var spread := randf_range(-0.42, 0.42)
	var start := origin + Vector2(randf_range(-90.0, 90.0), randf_range(-18.0, 18.0)) - coin.size * 0.5
	var control := start.lerp(target - coin.size * 0.5, 0.5) + Vector2(spread * 260.0, -190.0)
	var finish := target - coin.size * 0.5

	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: coin.modulate.a = 1.0)
	tween.tween_method(
		func(t: float) -> void:
			coin.position = (
				start.lerp(control, t).lerp(control.lerp(finish, t), t)
			)
			coin.scale = Vector2.ONE * lerpf(1.0, 0.55, t),
		0.0,
		1.0,
		COIN_FLIGHT
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_land_coin)
	tween.tween_callback(coin.queue_free)


## A coin arriving: the pill kicks and a ding sounds, one step up the run each
## time, so the payout is heard as well as seen.
func _land_coin() -> void:
	_bump_coin_pill()
	_sound.play_coin(_coins_landed)
	_coins_landed += 1


## A small kick on the counter as each coin lands, so the pill acknowledges
## them instead of the number simply changing.
func _bump_coin_pill() -> void:
	_coin_pill.pivot_offset = _coin_pill.size * 0.5
	var tween := create_tween()
	tween.tween_property(_coin_pill, "scale", Vector2(1.07, 1.07), 0.06)
	tween.tween_property(_coin_pill, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)


## The verdict, delivered by rewriting the title's second line rather than by a
## banner of its own.
##
## A tournament-ending screen already carries the taller PLAY AGAIN / HOME stack
## at the bottom, and there is no row left between the place badge and the
## survivors panel to put a separate ELIMINATED plate in — it landed on top of
## the panel's header tab. Retitling costs no layout at all, and it keeps the
## beat the brief asks for: the screen says "TOURNAMENT COMPLETE!" through the
## reveal and the reward, and only then turns into "TOURNAMENT ELIMINATED" /
## "TOURNAMENT YOU WIN!" with a pop, so the verdict still arrives as its own
## moment instead of being on screen from the first frame.
func _reveal_outcome() -> void:
	var won: bool = bool(_results.get("player_won", false))
	_title_complete.text = "YOU WIN!" if won else "ELIMINATED"
	_title_complete.add_theme_color_override(
		"font_color", UIKit.GOLD if won else UIKit.RED
	)
	_title_complete.scale = Vector2(0.7, 0.7)
	_pop(_title_complete)

	if _reward_label != null:
		var fade := create_tween()
		fade.set_parallel(true)
		fade.tween_property(_reward_label, "modulate:a", 0.0, 0.3)
		fade.tween_property(
			_reward_label, "position:y", _reward_label.position.y - 46.0, 0.3
		)
	_pop(_actions)


# --- Input --------------------------------------------------------------------


## Tapping anywhere while the reveal is still running skips to the end of it.
## The sequence is short by design, but a player who has watched it three times
## in a tournament should not have to sit through a fourth.
func _on_root_input(event: InputEvent) -> void:
	var pressed: bool = (
		(event is InputEventMouseButton and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if not pressed or _finished:
		return
	_skip()


func _skip() -> void:
	if _sequence != null and _sequence.is_valid():
		_sequence.kill()
	_finished = true
	_dim.modulate.a = 1.0
	for control in _revealed:
		control.visible = true
		control.modulate.a = 1.0
		control.scale = Vector2.ONE
	for panel in [_survivors_panel, _eliminated_panel]:
		for group in ["captions", "crosses", "names"]:
			for control in panel.get_meta(group):
				control.modulate.a = 1.0
				control.scale = Vector2.ONE
		var you_pill := _you_pill(panel)
		if you_pill != null:
			you_pill.modulate.a = 1.0
			you_pill.scale = Vector2.ONE
	if bool(_results.get("tournament_over", false)):
		_start_reward()
		_reveal_outcome()
