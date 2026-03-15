extends Node

## Player abilities — unlocked at milestones. Cooldown-based.

signal ability_used(ability_name: String)
signal cooldown_updated(ability_name: String, remaining: float, total: float)

var abilities: Dictionary = {
	"emp_pulse": {
		"name": "EMP Pulse",
		"desc": "Stuns all enemies in range for 3 seconds.",
		"cooldown": 15.0,
		"remaining": 0.0,
		"unlocked": false,
		"unlock_level": 3,
		"radius": 100.0,
		"key": "1",
	},
	"cloaking": {
		"name": "Cloaking",
		"desc": "Become invisible for 5 seconds.",
		"cooldown": 20.0,
		"remaining": 0.0,
		"unlocked": false,
		"unlock_level": 5,
		"duration": 5.0,
		"key": "2",
	},
	"signal_shield": {
		"name": "Signal Shield",
		"desc": "Block all damage for 3 seconds.",
		"cooldown": 25.0,
		"remaining": 0.0,
		"unlocked": false,
		"unlock_level": 8,
		"duration": 3.0,
		"key": "3",
	},
}


func _process(delta: float) -> void:
	# Tick cooldowns
	for aid: String in abilities:
		var ab: Dictionary = abilities[aid]
		if ab.remaining > 0:
			ab.remaining = maxf(ab.remaining - delta, 0.0)
			cooldown_updated.emit(aid, ab.remaining, ab.cooldown)

	# Check unlocks
	var level: int = GameManager.player_stats.level
	for aid: String in abilities:
		if not abilities[aid].unlocked and level >= abilities[aid].unlock_level:
			abilities[aid].unlocked = true

	# Input
	if Input.is_action_just_pressed("ability_1"):
		use_ability("emp_pulse")
	elif Input.is_action_just_pressed("ability_2"):
		use_ability("cloaking")
	elif Input.is_action_just_pressed("ability_3"):
		use_ability("signal_shield")


func use_ability(ability_id: String) -> bool:
	if not abilities.has(ability_id):
		return false
	var ab: Dictionary = abilities[ability_id]
	if not ab.unlocked or ab.remaining > 0:
		return false

	ab.remaining = ab.cooldown
	ability_used.emit(ability_id)

	match ability_id:
		"emp_pulse":
			_do_emp_pulse(ab)
		"cloaking":
			_do_cloaking(ab)
		"signal_shield":
			_do_signal_shield(ab)

	return true


func _do_emp_pulse(ab: Dictionary) -> void:
	if not GameManager.player:
		return
	var pos := GameManager.player.global_position
	AudioManager.play_sfx("shoot")
	CameraManager.shake(8.0)

	# Stun all enemies in radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is CharacterBody2D:
			var dist := pos.distance_to(enemy.global_position)
			if dist < ab.radius:
				enemy.velocity = Vector2.ZERO
				# Flash blue
				var tween := create_tween()
				tween.tween_property(enemy, "modulate", Color(0.3, 0.3, 1.0), 0.1)
				tween.tween_interval(3.0)
				tween.tween_property(enemy, "modulate", Color.WHITE, 0.3)

	# Visual pulse
	var DustParticles := preload("res://scripts/effects/dust_particles.gd")
	var effect := Node2D.new()
	effect.set_script(DustParticles)
	GameManager.player.get_parent().add_child(effect)
	effect.emit_burst(pos, 20, Color(0.3, 0.5, 1.0, 0.8), 100.0)


func _do_cloaking(ab: Dictionary) -> void:
	if not GameManager.player:
		return
	AudioManager.play_sfx("dodge")
	var player := GameManager.player

	# Make player semi-invisible
	var tween := create_tween()
	tween.tween_property(player, "modulate:a", 0.2, 0.3)
	tween.tween_interval(ab.duration)
	tween.tween_property(player, "modulate:a", 1.0, 0.3)

	# Set invincible during cloak
	player.invincible = true
	player.invincible_timer = ab.duration


func _do_signal_shield(ab: Dictionary) -> void:
	if not GameManager.player:
		return
	AudioManager.play_sfx("click")
	var player := GameManager.player

	player.invincible = true
	player.invincible_timer = ab.duration

	# Visual shield
	var tween := create_tween()
	tween.tween_property(player, "modulate", Color(0.5, 0.8, 1.0), 0.2)
	tween.tween_interval(ab.duration - 0.4)
	tween.tween_property(player, "modulate", Color.WHITE, 0.2)
