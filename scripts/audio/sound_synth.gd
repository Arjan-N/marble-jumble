class_name SoundSynth
extends RefCounted

## Small procedural sound effects, synthesised at runtime rather than shipped
## as asset files. Phase 0 has no audio assets or art pipeline to add them
## through; a few lines of waveform generation gets collision/impact/finish
## feedback in without starting one this early.

const MIX_RATE := 44100


static func _make_stream(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()

	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var value := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	stream.data = data
	return stream


## Linear attack/release envelope, 0..1.
static func _envelope(t: float, attack: float, release: float, duration: float) -> float:
	if t < attack:
		return t / attack
	var release_start := duration - release
	if t > release_start:
		return clampf((duration - t) / release, 0.0, 1.0)
	return 1.0


## A short glassy click, pitched by impact strength. A bass thump with noise
## read as a footstep or a crate, not a small hard sphere — this uses a bright
## fundamental plus two inharmonic overtones (glass and stone don't ring in
## clean octaves) and an exponential decay, with noise limited to the first
## couple of milliseconds as the crack of contact rather than sustained hiss.
static func impact(strength: float) -> AudioStreamWAV:
	var duration := 0.08
	var count := int(MIX_RATE * duration)
	var loudness := clampf(strength / 12.0, 0.0, 1.0)
	var freq := lerpf(1300.0, 1800.0, loudness)
	var rng := RandomNumberGenerator.new()
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var decay := exp(-t * 55.0)
		var tone := (
			sin(TAU * freq * t) * 0.6
			+ sin(TAU * freq * 2.42 * t) * 0.25
			+ sin(TAU * freq * 3.71 * t) * 0.15
		)
		var click := rng.randf_range(-1.0, 1.0) * exp(-t * 900.0) * 0.5
		samples[i] = (tone + click) * decay
	return _make_stream(samples)


## A soft click for the barrier release.
static func release() -> AudioStreamWAV:
	var duration := 0.09
	var count := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var env := _envelope(t, 0.001, duration - 0.02, duration)
		samples[i] = sin(TAU * 520.0 * t) * env
	return _make_stream(samples)


## A short rising chime for finishing the course.
static func finish() -> AudioStreamWAV:
	var duration := 0.4
	var count := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var env := _envelope(t, 0.01, duration - 0.15, duration)
		var freq := lerpf(520.0, 780.0, t / duration)
		samples[i] = sin(TAU * freq * t) * env * 0.8
	return _make_stream(samples)


## A low, descending tone for falling out of the course.
static func fall() -> AudioStreamWAV:
	var duration := 0.5
	var count := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var env := _envelope(t, 0.01, duration - 0.1, duration)
		var freq := lerpf(300.0, 90.0, t / duration)
		samples[i] = sin(TAU * freq * t) * env * 0.7
	return _make_stream(samples)
