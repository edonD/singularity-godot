extends Node

## Ambient audio — procedural wind, cricket, NEXUS hum sounds.

var _wind_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var _is_combat: bool = false
var _combat_check_timer: float = 0.0


func _ready() -> void:
	# Wind
	_wind_player = AudioStreamPlayer.new()
	_wind_player.bus = "Master"
	_wind_player.volume_db = -18.0
	add_child(_wind_player)

	# Ambient (crickets at night)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = -20.0
	add_child(_ambient_player)

	# Combat pulse
	_combat_player = AudioStreamPlayer.new()
	_combat_player.bus = "Master"
	_combat_player.volume_db = -15.0
	add_child(_combat_player)

	# Start wind
	_play_wind()


func _process(delta: float) -> void:
	# Loop wind
	if not _wind_player.playing:
		_play_wind()

	# Check for nearby enemies for combat music
	_combat_check_timer += delta
	if _combat_check_timer > 1.0:
		_combat_check_timer = 0.0
		_check_combat_state()

	# Night ambient
	if GameManager.is_night and not _ambient_player.playing:
		_play_night_ambient()


func _play_wind() -> void:
	var sample_rate := 22050
	var duration := 3.0
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / sample_rate
		var wind := sin(t * 2.0) * 0.1 + sin(t * 0.7) * 0.05
		wind += (randf() * 2.0 - 1.0) * 0.03
		var value := int(clampf(wind, -1.0, 1.0) * 32000)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	_wind_player.stream = stream
	_wind_player.play()


func _play_night_ambient() -> void:
	var sample_rate := 22050
	var duration := 2.0
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / sample_rate
		# Cricket chirps
		var chirp := 0.0
		var chirp_phase := fmod(t, 0.3)
		if chirp_phase < 0.05:
			chirp = sin(t * 4000.0 * TAU) * 0.06 * (0.05 - chirp_phase) * 20.0
		var value := int(clampf(chirp, -1.0, 1.0) * 32000)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	_ambient_player.stream = stream
	_ambient_player.play()


func _check_combat_state() -> void:
	if not GameManager.player:
		return

	var player_pos := GameManager.player.global_position
	var enemies_near := false

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			var dist := player_pos.distance_to(enemy.global_position)
			if dist < 80.0:
				enemies_near = true
				break

	if enemies_near and not _is_combat:
		_is_combat = true
		_play_combat_pulse()
	elif not enemies_near and _is_combat:
		_is_combat = false
		_combat_player.stop()


func _play_combat_pulse() -> void:
	var sample_rate := 22050
	var duration := 1.5
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / sample_rate
		# Low rumble with heartbeat rhythm
		var beat := sin(t * 2.5 * TAU) * 0.15
		beat += sin(t * 5.0 * TAU) * 0.05
		var envelope := 0.5 + sin(t * 1.5 * TAU) * 0.5
		var sample := beat * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32000)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = num_samples
	_combat_player.stream = stream
	_combat_player.play()
