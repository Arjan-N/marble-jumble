class_name SoundManager
extends Node

## Phase 0 audio: one-shots for barrier release, finish, falling and impacts,
## all synthesised by SoundSynth (see that script for why there are no asset
## files). A continuous rolling rumble was tried and dropped — every version
## either read as rain/wind or was simply too prominent under everything else;
## the one-shots carry the feedback without a constant background layer.
##
## Only the player's marble drives any of this — Marble only wires up its
## collision signal when is_player is true — matching how the HUD already only
## reports the player's own overtakes and falls rather than all twelve.

## Marble already gates on velocity change and its own cooldown; these are a
## second, looser gate in case something else ever calls play_impact directly.
const IMPACT_COOLDOWN := 0.12
const IMPACT_MIN_CHANGE := 2.5

## Semitones above the coin base pitch, one per coin in a payout: a major scale
## climbing to the octave and holding there. Nearly every game that pays out a
## handful of pickups at once does some version of this — the rise is what turns
## a row of identical clinks into one gesture that resolves. It stops at the
## octave rather than running further up because a coin's partials sit well
## above its fundamental already, and a run that keeps climbing stops sounding
## like metal and starts sounding like a whistle.
const COIN_STEPS: Array[int] = [0, 2, 4, 5, 7, 9, 11, 12, 12]
## Distinct synthesised takes per step, picked from at random. Real coins landing
## in a pile never repeat exactly; one stream per pitch is audibly a sample being
## retriggered.
const COIN_VARIANTS := 3
## A coin outlasts the gap before the next one lands, so they overlap and need a
## small pool of players instead of the single one-shot voice.
const COIN_VOICES := 4

var _impact_player := AudioStreamPlayer.new()
var _oneshot_player := AudioStreamPlayer.new()
var _coin_players: Array[AudioStreamPlayer] = []

var _release_stream: AudioStreamWAV
var _finish_stream: AudioStreamWAV
var _fall_stream: AudioStreamWAV
var _coin_streams: Array[AudioStreamWAV] = []

var _impact_cooldown := 0.0
var _coin_voice := 0


static func create() -> SoundManager:
	var manager := SoundManager.new()
	manager.name = "SoundManager"
	return manager


func _ready() -> void:
	_release_stream = SoundSynth.release()
	_finish_stream = SoundSynth.finish()
	_fall_stream = SoundSynth.fall()
	# Flattened to step-major order so `play_coin` can index it arithmetically.
	for step in COIN_STEPS:
		for variant in COIN_VARIANTS:
			_coin_streams.append(SoundSynth.coin(float(step), variant))

	add_child(_impact_player)
	add_child(_oneshot_player)
	for i in COIN_VOICES:
		var player := AudioStreamPlayer.new()
		_coin_players.append(player)
		add_child(player)


func _process(delta: float) -> void:
	_impact_cooldown = maxf(_impact_cooldown - delta, 0.0)


## `change` is the velocity change (m/s) that triggered the impact, not a speed.
func play_impact(change: float) -> void:
	if change < IMPACT_MIN_CHANGE or _impact_cooldown > 0.0:
		return
	_impact_cooldown = IMPACT_COOLDOWN
	_impact_player.stream = SoundSynth.impact(change)
	_impact_player.volume_db = lerpf(-18.0, -4.0, clampf(change / 16.0, 0.0, 1.0))
	_impact_player.play()


func play_release() -> void:
	_oneshot_player.stream = _release_stream
	_oneshot_player.volume_db = -6.0
	_oneshot_player.play()


func play_finish() -> void:
	_oneshot_player.stream = _finish_stream
	_oneshot_player.volume_db = -4.0
	_oneshot_player.play()


## One coin landing in the counter. `index` is its place in the payout, which
## picks the pitch; the caller counts, so the run rises in the order the coins
## actually arrive rather than in the order the tweens were started.
func play_coin(index: int) -> void:
	if _coin_streams.is_empty():
		return
	var step := clampi(index, 0, COIN_STEPS.size() - 1)
	var player := _coin_players[_coin_voice]
	_coin_voice = (_coin_voice + 1) % _coin_players.size()
	player.stream = _coin_streams[step * COIN_VARIANTS + randi() % COIN_VARIANTS]
	# Nine of these land inside half a second; each one has to sit under the
	# reward line rather than on top of it. A touch of level scatter as well —
	# coins do not all land equally hard.
	player.volume_db = -12.0 + randf_range(-1.5, 1.5)
	player.play()


func play_fall() -> void:
	_oneshot_player.stream = _fall_stream
	_oneshot_player.volume_db = -6.0
	_oneshot_player.play()
