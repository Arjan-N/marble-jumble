extends SceneTree

## Renders a whole coin payout — the nine coins of `SoundManager.COIN_STEPS`,
## spaced by the flight stagger `round_results_screen.gd` actually uses — into a
## single WAV so the run can be listened to without racing a tournament, and
## prints peak/RMS per coin so clipping or a dead partial shows up as a number.
##
## Usage:
##
##     godot --path . --headless --script tools/coin_sound_probe.gd -- <out.wav>

const STAGGER := 0.055
const MIX_RATE := 44100
## `SoundManager.play_coin`'s level, applied here too so the summed peak this
## prints is the peak the player actually hears — summing the voices at unity
## reports a clip that never happens in game.
const VOICE_GAIN := 0.25


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://coin_payout.wav"

	var steps := SoundManager.COIN_STEPS
	var variants := SoundManager.COIN_VARIANTS
	var stride := int(MIX_RATE * STAGGER)
	var mix := PackedFloat32Array()

	for i in steps.size():
		var stream := SoundSynth.coin(float(steps[i]), i % variants)
		var voice := _samples(stream)
		var offset := i * stride
		if mix.size() < offset + voice.size():
			mix.resize(offset + voice.size())
		var peak := 0.0
		var sum := 0.0
		for n in voice.size():
			mix[offset + n] += voice[n] * VOICE_GAIN
			peak = maxf(peak, absf(voice[n]))
			sum += voice[n] * voice[n]
		print(
			"coin %d  step %+3d st  peak %.3f  rms %.4f  %.2fs"
			% [i, steps[i], peak, sqrt(sum / voice.size()), float(voice.size()) / MIX_RATE]
		)

	var mix_peak := 0.0
	for value in mix:
		mix_peak = maxf(mix_peak, absf(value))
	print("payout: %.2fs, peak %.3f%s" % [
		float(mix.size()) / MIX_RATE, mix_peak, "  CLIPPING" if mix_peak > 1.0 else ""
	])

	# Written at the summed level, unnormalised, so the printed peak is the peak
	# that is heard.
	var render := AudioStreamWAV.new()
	render.format = AudioStreamWAV.FORMAT_16_BITS
	render.mix_rate = MIX_RATE
	render.stereo = false
	var data := PackedByteArray()
	data.resize(mix.size() * 2)
	for i in mix.size():
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))
	render.data = data
	render.save_to_wav(out)
	print("wrote ", out)

	quit()


func _samples(stream: AudioStreamWAV) -> PackedFloat32Array:
	var data := stream.data
	var out := PackedFloat32Array()
	out.resize(data.size() / 2)
	for i in out.size():
		out[i] = float(data.decode_s16(i * 2)) / 32767.0
	return out
