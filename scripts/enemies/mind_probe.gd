extends "res://scripts/enemies/enemy_base.gd"

## Mind Probe — invisible until close, drains player stamina/HP, flickers in and out.

var _phase_timer: float = 0.0
var _visible_timer: float = 0.0
var _drain_tick: float = 0.0
var _is_visible: bool = false


func _ready() -> void:
	max_hp = 20
	attack_damage = 3
	move_speed = 50.0
	detection_range = 80.0
	attack_range = 30.0
	xp_value = 30
	knockback_resistance = 0.0
	super._ready()
	# Start invisible
	modulate.a = 0.0


func _generate_sprite() -> void:
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Ethereal, ghostly shape
	var body_color := Color(0.4, 0.2, 0.6)
	var eye_color := Color(0.8, 0.2, 1.0)

	# Wispy body
	for y in range(2, 9):
		var width: int = 3 if y < 4 or y > 7 else 4
		for x in range(5 - width, 5 + width):
			if x >= 0 and x < 10:
				var alpha := 0.6 + randf() * 0.3
				img.set_pixel(x, y, Color(body_color.r, body_color.g, body_color.b, alpha))

	# Eyes
	img.set_pixel(3, 4, eye_color)
	img.set_pixel(6, 4, eye_color)
	img.set_pixel(3, 5, eye_color)
	img.set_pixel(6, 5, eye_color)

	# Tendrils at bottom
	img.set_pixel(3, 9, Color(body_color.r, body_color.g, body_color.b, 0.3))
	img.set_pixel(6, 9, Color(body_color.r, body_color.g, body_color.b, 0.3))

	_sprite.texture = ImageTexture.create_from_image(img)


func _ai_process(delta: float) -> void:
	_phase_timer += delta

	match detection_state:
		DetectionState.UNAWARE, DetectionState.SUSPICIOUS:
			# Drift slowly, stay invisible
			velocity = Vector2(sin(_phase_timer * 0.5), cos(_phase_timer * 0.7)) * move_speed * 0.3
			modulate.a = lerpf(modulate.a, 0.05, delta * 2.0) # Almost invisible

		DetectionState.ALERT, DetectionState.HUNTING:
			if not _target:
				return
			var dir := (_target.global_position - global_position).normalized()
			var dist := global_position.distance_to(_target.global_position)

			# Approach slowly
			velocity = dir * move_speed * 0.6

			# Flicker visibility based on distance
			if dist < 40.0:
				_is_visible = true
				modulate.a = lerpf(modulate.a, 0.8, delta * 3.0)
			elif dist < 60.0:
				# Flicker
				modulate.a = 0.3 + sin(_phase_timer * 8.0) * 0.3
			else:
				modulate.a = lerpf(modulate.a, 0.1, delta * 2.0)

			# Drain player when very close
			if dist < attack_range:
				_drain_tick += delta
				if _drain_tick > 0.5:
					_drain_tick = 0.0
					_drain_player()

	# Bob effect
	_sprite.position.y = sin(_phase_timer * 2.0) * 2.0


func _drain_player() -> void:
	if not _target or not _target.has_method("take_damage"):
		return
	var s := GameManager.player_stats
	s.stamina = maxf(s.stamina - 10.0, 0.0)
	_target.take_damage(attack_damage, Vector2.ZERO)


func take_damage(amount: int, knockback_dir: Vector2, is_crit: bool = false) -> void:
	# Becomes fully visible when hit
	modulate.a = 1.0
	_is_visible = true
	super.take_damage(amount, knockback_dir, is_crit)
