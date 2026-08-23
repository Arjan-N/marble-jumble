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

var _impact_player := AudioStreamPlayer.new()
var _oneshot_player := AudioStreamPlayer.new()

var _release_stream: AudioStreamWAV
var _finish_stream: AudioStreamWAV
var _fall_stream: AudioStreamWAV

var _impact_cooldown := 0.0


static func create() -> SoundManager:
	var manager := SoundManager.new()
	manager.name = "SoundManager"
	return manager


func _ready() -> void:
	_release_stream = SoundSynth.release()
	_finish_stream = SoundSynth.finish()
	_fall_stream = SoundSynth.fall()

	add_child(_impact_player)
	add_child(_oneshot_player)


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


func play_fall() -> void:
	_oneshot_player.stream = _fall_stream
	_oneshot_player.volume_db = -6.0
	_oneshot_player.play()
