extends "res://scripts/enemies/enemy_base.gd"

## Sentinel — boss-tier. Adapts to player tactics. Multi-phase.

var _phase: int = 0 # 0 = ranged, 1 = melee rush, 2 = shield + summon
var _phase_timer: float = 0.0
var _shoot_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _summon_cooldown: float = 0.0
var _hits_taken_melee: int = 0
var _hits_taken_ranged: int = 0
var _adaptation_timer: float = 0.0


func _ready() -> void:
	max_hp = 250
	attack_damage = 20
	move_speed = 55.0
	detection_range = 160.0
	attack_range = 24.0
	xp_value = 150
	knockback_resistance = 0.7
	super._ready()


func _generate_sprite() -> void:
	var img := Image.create(16, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var body_color := Color(0.3, 0.3, 0.4)
	var armor_color := Color(0.6, 0.6, 0.7)
	var eye_color := Color(1.0, 0.0, 0.3)
	var glow_color := Color(0.8, 0.2, 0.2)

	# Head/crown
	for x in range(5, 11):
		img.set_pixel(x, 0, armor_color)
		img.set_pixel(x, 1, armor_color)
	img.set_pixel(4, 0, glow_color)
	img.set_pixel(11, 0, glow_color)

	# Face plate
	for y in range(2, 6):
		for x in range(4, 12):
			img.set_pixel(x, y, body_color)

	# Eyes - menacing visor
	for x in range(5, 11):
		img.set_pixel(x, 3, eye_color)
		img.set_pixel(x, 4, eye_color)

	# Body - large and imposing
	for y in range(6, 14):
		for x in range(3, 13):
			img.set_pixel(x, y, body_color)
	# Shoulder armor
	for y in range(6, 9):
		img.set_pixel(2, y, armor_color)
		img.set_pixel(3, y, armor_color)
		img.set_pixel(12, y, armor_color)
		img.set_pixel(13, y, armor_color)

	# Core (glowing)
	for y in range(9, 12):
		for x in range(6, 10):
			img.set_pixel(x, y, glow_color)

	# Legs
	for y in range(14, 18):
		for x in range(4, 7):
			img.set_pixel(x, y, Color(0.25, 0.25, 0.35))
		for x in range(9, 12):
			img.set_pixel(x, y, Color(0.25, 0.25, 0.35))

	_sprite.texture = ImageTexture.create_from_image(img)


func _ai_process(delta: float) -> void:
	_phase_timer += delta
	_shoot_cooldown -= delta
	_dash_cooldown -= delta
	_summon_cooldown -= delta
	_adaptation_timer += delta

	# Adapt every 8 seconds
	if _adaptation_timer > 8.0:
		_adaptation_timer = 0.0
		_adapt()

	match detection_state:
		DetectionState.UNAWARE, DetectionState.SUSPICIOUS:
			velocity = Vector2.ZERO
		DetectionState.ALERT, DetectionState.HUNTING:
			if not _target:
				return
			_execute_phase(delta)

	# Face target
	if _target:
		var dir := (_target.global_position - global_position).normalized()
		if dir.x != 0:
			_sprite.flip_h = dir.x < 0

	# Glow core animation
	var glow := 0.8 + sin(_phase_timer * 3.0) * 0.2
	_sprite.modulate = Color(glow, glow, glow)


func _execute_phase(delta: float) -> void:
	var dir := (_target.global_position - global_position).normalized()
	var dist := global_position.distance_to(_target.global_position)

	match _phase:
		0: # Ranged phase — keep distance and shoot
			if dist < 80.0:
				velocity = -dir * move_speed # Back away
			elif dist > 120.0:
				velocity = dir * move_speed * 0.5
			else:
				velocity = Vector2.ZERO

			if _shoot_cooldown <= 0:
				_shoot_cooldown = 1.2
				_shoot_at_player()

		1: # Melee rush — aggressive pursuit
			velocity = dir * move_speed * 1.8

			if _dash_cooldown <= 0 and dist < 60.0:
				_dash_cooldown = 2.0
				velocity = dir * move_speed * 4.0
				AudioManager.play_sfx("alert")

		2: # Shield + summon — defensive, calls for help
			# Circle the player
			var perp := Vector2(-dir.y, dir.x)
			velocity = perp * move_speed * 0.8

			# Reduced damage in this phase
			knockback_resistance = 0.9

			if _summon_cooldown <= 0:
				_summon_cooldown = 6.0
				_summon_help()


func _adapt() -> void:
	# Switch phase based on what player is doing
	if _hits_taken_melee > _hits_taken_ranged + 2:
		_phase = 0 # Player is meleeing — go ranged
	elif _hits_taken_ranged > _hits_taken_melee + 2:
		_phase = 1 # Player is shooting — rush them
	elif hp < max_hp * 0.3:
		_phase = 2 # Low HP — defensive mode

	_hits_taken_melee = 0
	_hits_taken_ranged = 0


func take_damage(amount: int, knockback_dir: Vector2, is_crit: bool = false) -> void:
	# Track how player is attacking
	if knockback_dir.length() > 0.5:
		var dist := global_position.distance_to(_target.global_position) if _target else 100.0
		if dist < 30.0:
			_hits_taken_melee += 1
		else:
			_hits_taken_ranged += 1

	# Phase 2 has damage reduction
	if _phase == 2:
		amount = int(amount * 0.6)

	super.take_damage(amount, knockback_dir, is_crit)


func _shoot_at_player() -> void:
	if not _target:
		return
	var ProjectileScene := preload("res://scenes/effects/Projectile.tscn")
	var dir := (_target.global_position - global_position).normalized()

	var proj: Area2D = ProjectileScene.instantiate()
	proj.global_position = global_position + dir * 10.0
	proj.direction = dir
	proj.speed = 150.0
	proj.damage = attack_damage
	proj.collision_layer = 8
	proj.collision_mask = 1 # Hit player instead of enemies

	get_parent().add_child(proj)
	AudioManager.play_sfx("shoot")


func _summon_help() -> void:
	var ScoutScene := preload("res://scenes/enemies/ScoutDrone.tscn")
	for i in 2:
		var drone: Node2D = ScoutScene.instantiate()
		var angle := randf() * TAU
		drone.global_position = global_position + Vector2(cos(angle), sin(angle)) * 30.0
		get_parent().add_child(drone)
	AudioManager.play_sfx("alert")


func _drop_loot() -> void:
	# Boss drops guaranteed high-tier loot
	var ItemDropScene := preload("res://scenes/items/ItemDrop.tscn")
	var boss_loot: Array[Array] = [
		["circuit_board", 5, Color(0.2, 0.6, 0.3)],
		["battery", 3, Color(0.7, 0.7, 0.2)],
		["scrap_metal", 8, Color(0.5, 0.5, 0.55)],
		["wire", 6, Color(0.8, 0.4, 0.2)],
	]
	for entry in boss_loot:
		var drop: Area2D = ItemDropScene.instantiate()
		drop.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
		drop.call_deferred("setup", entry[0], entry[1], entry[2])
		get_parent().call_deferred("add_child", drop)
