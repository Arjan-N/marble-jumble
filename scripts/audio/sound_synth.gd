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


## A struck metal disc, `semitones` above the base pitch — the ring of a real
## coin rather than a tuned bell.
##
## Three things separate the two, and all three come from how a coin actually
## behaves. A thin disc's bending modes are inharmonic (roughly 1 : 2.3 : 3.7 :
## 5.4 : 6.8 of the fundamental, not a neat octave stack), so the partials beat
## against each other into a shimmer instead of fusing into one clean pitch.
## The strike itself is broadband — a couple of milliseconds of noise is what
## makes it read as metal being *hit*, and without it even the right partials
## sound like a synth pad. And a dropped coin never lands once: it bounces, so
## a quieter second strike follows a few tens of milliseconds later, slightly
## sharper because a coin on its edge rings higher than one lying flat.
##
## `variant` picks the jitter — mode ratios, bounce delay and level all wobble a
## little with it, because nine identical coins are the giveaway that they came
## from one sample. Games do the same thing: Mario's coin is a fixed two-note
## motif and reads as a *token*, while a Temple Run pickup scatters slightly
## every time and reads as an object.
const COIN_MODES: Array[float] = [1.0, 2.31, 3.74, 5.42, 6.83]
const COIN_MODE_GAIN: Array[float] = [0.5, 0.34, 0.22, 0.13, 0.08]
## Higher modes shed energy faster in real metal, which is what turns the bright
## clink into a warmer tail over the first tenth of a second.
const COIN_MODE_DECAY: Array[float] = [11.0, 17.0, 26.0, 38.0, 52.0]


static func coin(semitones: float, variant: int = 0) -> AudioStreamWAV:
	var duration := 0.34
	var count := int(MIX_RATE * duration)
	var freq := 1180.0 * pow(2.0, semitones / 12.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2(semitones, float(variant)))

	var samples := PackedFloat32Array()
	samples.resize(count)
	_coin_strike(samples, 0, freq * rng.randf_range(0.98, 1.02), 1.0, rng)
	# The bounce. Late enough to be heard as a second contact rather than as
	# part of the first, early enough that it is still the same coin landing.
	var bounce := int(MIX_RATE * rng.randf_range(0.038, 0.062))
	_coin_strike(samples, bounce, freq * rng.randf_range(1.02, 1.09), 0.3, rng)

	for i in count:
		# Mild saturation. Struck metal clips its own transient; a perfectly
		# linear sum of sines sounds synthetic next to it.
		samples[i] = tanh(samples[i] * 1.4)
	return _make_stream(samples)


## Adds one contact — noise crack plus decaying inharmonic modes — into
## `samples` starting at `offset`. Additive so the bounce overlaps the tail of
## the first strike instead of cutting it off.
static func _coin_strike(
	samples: PackedFloat32Array, offset: int, freq: float, gain: float, rng: RandomNumberGenerator
) -> void:
	# Partials above Nyquist would fold back down as an audible whistle at the
	# top of the pitch run, so they are simply dropped.
	var ceiling := float(MIX_RATE) * 0.45
	for i in range(offset, samples.size()):
		var t := float(i - offset) / MIX_RATE
		var value := 0.0
		for m in COIN_MODES.size():
			var partial := freq * COIN_MODES[m]
			if partial > ceiling:
				break
			value += (
				sin(TAU * partial * t) * COIN_MODE_GAIN[m] * exp(-t * COIN_MODE_DECAY[m])
			)
		var crack := rng.randf_range(-1.0, 1.0) * exp(-t * 1400.0) * 0.45
		samples[i] += (value + crack) * gain


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
