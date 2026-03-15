extends "res://scripts/enemies/enemy_base.gd"

## Scout Drone — fast, weak, flies in patterns, alerts others.

var _patrol_angle: float = 0.0
var _patrol_center: Vector2
var _patrol_radius: float = 40.0
var _bob_offset: float = 0.0


func _ready() -> void:
	max_hp = 15
	attack_damage = 5
	move_speed = 90.0
	detection_range = 150.0
	attack_range = 12.0
	xp_value = 10
	knockback_resistance = 0.0
	super._ready()
	_patrol_center = global_position
	_patrol_angle = randf() * TAU
	_bob_offset = randf() * TAU


func _generate_sprite() -> void:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Body - sleek triangular drone
	var body_color := Color(0.5, 0.55, 0.65)
	var eye_color := Color(1.0, 0.2, 0.2)
	var wing_color := Color(0.4, 0.45, 0.55)

	# Central body
	for y in range(3, 9):
		var width: int = 3 if y < 5 or y > 7 else 5
		var start: int = 6 - width
		for x in range(start, start + width * 2):
			if x >= 0 and x < 12:
				img.set_pixel(x, y, body_color)

	# Wings
	for x in range(1, 4):
		img.set_pixel(x, 5, wing_color)
		img.set_pixel(x, 6, wing_color)
	for x in range(8, 11):
		img.set_pixel(x, 5, wing_color)
		img.set_pixel(x, 6, wing_color)

	# Eye (red scanner)
	img.set_pixel(5, 5, eye_color)
	img.set_pixel(6, 5, eye_color)

	_sprite.texture = ImageTexture.create_from_image(img)


func _ai_process(delta: float) -> void:
	_bob_offset += delta * 3.0

	match detection_state:
		DetectionState.UNAWARE, DetectionState.SUSPICIOUS:
			# Patrol in circles
			_patrol_angle += delta * 1.2
			var target_pos := _patrol_center + Vector2(
				cos(_patrol_angle) * _patrol_radius,
				sin(_patrol_angle) * _patrol_radius + sin(_bob_offset) * 4.0
			)
			var dir := (target_pos - global_position).normalized()
			velocity = dir * move_speed * 0.5

		DetectionState.ALERT, DetectionState.HUNTING:
			if _target:
				var dir := (_target.global_position - global_position).normalized()
				var dist := global_position.distance_to(_target.global_position)

				# Alert nearby enemies
				_alert_nearby_enemies()

				if dist > attack_range:
					velocity = dir * move_speed
				else:
					# Strafe around player
					var perp := Vector2(-dir.y, dir.x)
					velocity = (perp + dir * 0.3).normalized() * move_speed

	# Bob effect
	_sprite.position.y = sin(_bob_offset) * 2.0

	# Face movement direction
	if velocity.x != 0:
		_sprite.flip_h = velocity.x < 0


func _alert_nearby_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and enemy is EnemyBase:
			var dist := global_position.distance_to(enemy.global_position)
			if dist < 100.0 and enemy.detection_state == DetectionState.UNAWARE:
				enemy.detection_state = DetectionState.ALERT
