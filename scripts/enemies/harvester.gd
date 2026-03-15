extends "res://scripts/enemies/enemy_base.gd"

## Harvester — slow, relentless. Massive HP. Deploys capture net area.

var _net_cooldown: float = 0.0
var _net_deployed: bool = false
var _step_timer: float = 0.0


func _ready() -> void:
	max_hp = 120
	attack_damage = 12
	move_speed = 30.0
	detection_range = 90.0
	attack_range = 24.0
	xp_value = 40
	knockback_resistance = 0.8
	super._ready()


func _generate_sprite() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var body_color := Color(0.4, 0.3, 0.25)
	var metal_color := Color(0.5, 0.5, 0.55)
	var eye_color := Color(0.0, 1.0, 0.5)
	var claw_color := Color(0.6, 0.55, 0.5)

	# Large boxy body
	for y in range(4, 14):
		for x in range(3, 13):
			img.set_pixel(x, y, body_color)

	# Metal plating
	for y in range(4, 8):
		for x in range(4, 12):
			img.set_pixel(x, y, metal_color)

	# Eyes - wide scanner bar
	for x in range(5, 11):
		img.set_pixel(x, 5, eye_color)
		img.set_pixel(x, 6, eye_color)

	# Claws/arms
	for y in range(8, 14):
		img.set_pixel(1, y, claw_color)
		img.set_pixel(2, y, claw_color)
		img.set_pixel(13, y, claw_color)
		img.set_pixel(14, y, claw_color)

	# Claw tips
	img.set_pixel(0, 13, claw_color)
	img.set_pixel(15, 13, claw_color)

	# Treads
	for x in range(4, 12):
		img.set_pixel(x, 14, Color(0.2, 0.2, 0.25))
		img.set_pixel(x, 15, Color(0.2, 0.2, 0.25))

	_sprite.texture = ImageTexture.create_from_image(img)


func _ai_process(delta: float) -> void:
	_net_cooldown -= delta
	_step_timer += delta

	match detection_state:
		DetectionState.UNAWARE, DetectionState.SUSPICIOUS:
			# Slowly wander
			if _step_timer > 2.0:
				_step_timer = 0.0
				var angle := randf() * TAU
				velocity = Vector2(cos(angle), sin(angle)) * move_speed * 0.3
			velocity = velocity.move_toward(Vector2.ZERO, 10.0 * delta)

		DetectionState.ALERT, DetectionState.HUNTING:
			if not _target:
				return
			var dir := (_target.global_position - global_position).normalized()
			var dist := global_position.distance_to(_target.global_position)

			# Relentlessly pursue
			velocity = dir * move_speed

			# Deploy net when close
			if dist < 60.0 and _net_cooldown <= 0.0 and not _net_deployed:
				_deploy_net()

	# Sprite faces movement
	if velocity.x != 0:
		_sprite.flip_h = velocity.x < 0

	# Heavy footstep feel - slight scale bounce
	if velocity.length() > 5.0:
		var bounce: float = abs(sin(_step_timer * 4.0)) * 0.1
		_sprite.scale = Vector2(1.0 + bounce * 0.5, 1.0 - bounce)


func _deploy_net() -> void:
	_net_cooldown = 8.0
	_net_deployed = true
	AudioManager.play_sfx("shoot")

	# Create a net area that slows player
	var net := Area2D.new()
	net.collision_layer = 0
	net.collision_mask = 1
	net.global_position = _target.global_position if _target else global_position

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	net.add_child(shape)

	# Visual
	var visual := Sprite2D.new()
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for y in 48:
		for x in 48:
			var dx: int = abs(x - 24)
			var dy: int = abs(y - 24)
			if dx * dx + dy * dy < 576: # radius 24
				if (x + y) % 4 < 2:
					img.set_pixel(x, y, Color(0.3, 0.8, 0.3, 0.3))
	visual.texture = ImageTexture.create_from_image(img)
	net.add_child(visual)

	get_parent().add_child(net)

	# Net effect: slow player on enter
	net.body_entered.connect(func(body: Node2D) -> void:
		if body == GameManager.player:
			GameManager.player_stats.speed = 40.0
	)
	net.body_exited.connect(func(body: Node2D) -> void:
		if body == GameManager.player:
			GameManager.player_stats.speed = 120.0
	)

	# Net disappears after 4 seconds
	var tween := get_tree().create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(visual, "modulate:a", 0.0, 1.0)
	tween.tween_callback(net.queue_free)
	tween.tween_callback(func() -> void: _net_deployed = false)
