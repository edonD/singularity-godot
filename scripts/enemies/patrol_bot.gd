extends "res://scripts/enemies/enemy_base.gd"

## Patrol Bot — walks routes, has a cone of vision, heavily armored front.

var _patrol_points: Array[Vector2] = []
var _current_patrol_idx: int = 0
var _facing_dir: Vector2 = Vector2.DOWN
var _charge_timer: float = 0.0
var _is_charging: bool = false


func _ready() -> void:
	max_hp = 60
	attack_damage = 15
	move_speed = 45.0
	detection_range = 100.0
	attack_range = 18.0
	xp_value = 25
	knockback_resistance = 0.5
	super._ready()

	# Generate patrol route around spawn
	var center := global_position
	for i in 4:
		var angle := i * TAU / 4.0 + randf() * 0.5
		var dist := randf_range(40, 80)
		_patrol_points.append(center + Vector2(cos(angle), sin(angle)) * dist)


func _generate_sprite() -> void:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var body_color := Color(0.35, 0.35, 0.4)
	var armor_color := Color(0.5, 0.5, 0.55)
	var eye_color := Color(1.0, 0.6, 0.0)
	var track_color := Color(0.25, 0.25, 0.3)

	# Tracks
	for y in range(10, 14):
		for x in range(1, 5):
			img.set_pixel(x, y, track_color)
		for x in range(9, 13):
			img.set_pixel(x, y, track_color)

	# Body - boxy
	for y in range(3, 11):
		for x in range(3, 11):
			img.set_pixel(x, y, body_color)

	# Front armor plate (top section)
	for y in range(2, 5):
		for x in range(2, 12):
			img.set_pixel(x, y, armor_color)

	# Eyes
	img.set_pixel(5, 4, eye_color)
	img.set_pixel(8, 4, eye_color)
	img.set_pixel(5, 5, eye_color)
	img.set_pixel(8, 5, eye_color)

	# Gun barrel
	img.set_pixel(6, 1, armor_color)
	img.set_pixel(7, 1, armor_color)
	img.set_pixel(6, 2, armor_color)
	img.set_pixel(7, 2, armor_color)

	_sprite.texture = ImageTexture.create_from_image(img)


func take_damage(amount: int, knockback_dir: Vector2, is_crit: bool = false) -> void:
	# Front armor reduces damage
	var dot := _facing_dir.dot(-knockback_dir)
	if dot > 0.5: # Hit from front
		amount = int(amount * 0.4) # 60% damage reduction
		knockback_dir *= 0.3 # Barely knocked back
	super.take_damage(amount, knockback_dir, is_crit)


func _ai_process(delta: float) -> void:
	match detection_state:
		DetectionState.UNAWARE, DetectionState.SUSPICIOUS:
			_patrol(delta)
		DetectionState.ALERT:
			_face_target()
			_charge_timer += delta
			if _charge_timer > 1.0:
				detection_state = DetectionState.HUNTING
				_charge_timer = 0.0
		DetectionState.HUNTING:
			_hunt(delta)

	# Update sprite facing
	if velocity.length() > 1.0:
		_facing_dir = velocity.normalized()
	if _facing_dir.x != 0:
		_sprite.flip_h = _facing_dir.x < 0


func _patrol(delta: float) -> void:
	if _patrol_points.is_empty():
		return

	var target := _patrol_points[_current_patrol_idx]
	var dist := global_position.distance_to(target)

	if dist < 5.0:
		_current_patrol_idx = (_current_patrol_idx + 1) % _patrol_points.size()
	else:
		var dir := (target - global_position).normalized()
		velocity = dir * move_speed * 0.6
		_facing_dir = dir


func _face_target() -> void:
	if _target:
		_facing_dir = (_target.global_position - global_position).normalized()
		velocity = Vector2.ZERO


func _hunt(delta: float) -> void:
	if not _target:
		return

	var dir := (_target.global_position - global_position).normalized()
	var dist := global_position.distance_to(_target.global_position)

	if not _is_charging and dist < 80.0:
		_charge_timer += delta
		# Telegraph: flash red before charging
		if _charge_timer > 0.4:
			_sprite.modulate = Color(1.5, 0.5, 0.5) if fmod(_charge_timer, 0.15) > 0.075 else Color.WHITE
		if _charge_timer > 0.8:
			_is_charging = true
			_charge_timer = 0.0
			_sprite.modulate = Color.WHITE
			AudioManager.play_sfx("alert")

	if _is_charging:
		# Charge at player!
		velocity = dir * move_speed * 2.5
		_charge_timer += delta
		if _charge_timer > 0.6:
			_is_charging = false
			_charge_timer = 0.0
	else:
		velocity = dir * move_speed
