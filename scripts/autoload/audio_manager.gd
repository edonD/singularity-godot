extends Node

## Audio manager singleton — generates retro sounds procedurally.

var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 16


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)


func _get_free_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0] # Steal oldest


func play_sfx(type: String, pitch_variation: float = 0.1) -> void:
	var player := _get_free_player()
	var stream := _generate_sound(type)
	if stream:
		player.stream = stream
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		player.volume_db = -6.0
		player.play()


func _generate_sound(type: String) -> AudioStream:
	match type:
		"hit":
			return _make_noise(0.08, 800.0, 200.0)
		"swing":
			return _make_noise(0.06, 400.0, 100.0)
		"hurt":
			return _make_noise(0.12, 300.0, 100.0)
		"pickup":
			return _make_tone(0.08, 880.0, 1200.0)
		"dodge":
			return _make_noise(0.05, 200.0, 50.0)
		"death":
			return _make_noise(0.3, 200.0, 30.0)
		"alert":
			return _make_tone(0.1, 600.0, 900.0)
		"levelup":
			return _make_tone(0.3, 440.0, 880.0)
		"click":
			return _make_tone(0.03, 1000.0, 1000.0)
		"step":
			return _make_noise(0.03, 100.0, 50.0)
		"shoot":
			return _make_noise(0.07, 1200.0, 400.0)
		"critical":
			return _make_noise(0.1, 1000.0, 300.0)
	return null


func _make_noise(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / sample_rate
		var progress := float(i) / num_samples
		var freq := lerpf(freq_start, freq_end, progress)
		var envelope := 1.0 - progress
		envelope *= envelope
		# Simple noise-ish wave with frequency modulation
		var sample := sin(t * freq * TAU + sin(t * freq * 2.3 * TAU) * 2.0) * envelope
		sample += (randf() * 2.0 - 1.0) * 0.3 * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32000)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _make_tone(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / sample_rate
		var progress := float(i) / num_samples
		var freq := lerpf(freq_start, freq_end, progress)
		var envelope := 1.0 - progress
		# Clean square-ish wave for tonal sounds
		var sample: float = sign(sin(t * freq * TAU)) * 0.5 * envelope
		sample += sin(t * freq * TAU) * 0.3 * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32000)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
