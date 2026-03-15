extends CharacterBody2D
class_name EnemyBase

## Base class for all enemies. Handles HP, damage, knockback, drops, detection states.

signal died(enemy: EnemyBase)

enum DetectionState { UNAWARE, SUSPICIOUS, ALERT, HUNTING }

@export var max_hp: int = 30
@export var attack_damage: int = 8
@export var move_speed: float = 60.0
@export var detection_range: float = 120.0
@export var attack_range: float = 20.0
@export var xp_value: int = 15
@export var knockback_resistance: float = 0.0

var hp: int
var detection_state: DetectionState = DetectionState.UNAWARE
var _knockback_vel: Vector2 = Vector2.ZERO
var _flash_timer: float = 0.0
var _is_dead: bool = false
var _target: Node2D = null
var _sprite: Sprite2D
var _attack_cooldown: float = 0.0
var _suspicion: float = 0.0
var _health_bar: ProgressBar
var _health_bar_visible: bool = false


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5 # World + Player

	# Create sprite if not already present
	if not has_node("Sprite2D"):
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)
	else:
		_sprite = $Sprite2D

	# Create collision shape if not present
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12, 12)
		col.shape = shape
		add_child(col)

	# Create hurtbox area for dealing damage to player
	var hurtbox := Area2D.new()
	hurtbox.name = "DamageArea"
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 1
	var hurtbox_shape := CollisionShape2D.new()
	var hshape := RectangleShape2D.new()
	hshape.size = Vector2(14, 14)
	hurtbox_shape.shape = hshape
	hurtbox.add_child(hurtbox_shape)
	add_child(hurtbox)
	hurtbox.body_entered.connect(_on_body_entered)

	_generate_sprite()
	_create_health_bar()


func _generate_sprite() -> void:
	# Override in subclasses
	pass


func _create_health_bar() -> void:
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(16, 2)
	_health_bar.max_value = max_hp
	_health_bar.value = hp
	_health_bar.show_percentage = false
	_health_bar.position = Vector2(-8, -14)
	_health_bar.size = Vector2(16, 2)
	_health_bar.visible = false

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15)
	bg.set_corner_radius_all(0)
	_health_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.15, 0.15)
	fill.set_corner_radius_all(0)
	_health_bar.add_theme_stylebox_override("fill", fill)

	add_child(_health_bar)


func _update_health_bar() -> void:
	if _health_bar:
		_health_bar.value = hp
		_health_bar.visible = hp < max_hp and not _is_dead


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_update_flash(delta)
	_update_detection(delta)
	_update_attack_cooldown(delta)
	_apply_knockback(delta)
	_ai_process(delta)
	move_and_slide()


func _update_flash(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		_sprite.modulate = Color(2.0, 2.0, 2.0) if fmod(_flash_timer, 0.1) > 0.05 else Color.WHITE
		if _flash_timer <= 0:
			_sprite.modulate = Color.WHITE


func _update_detection(delta: float) -> void:
	_target = GameManager.player
	if not _target or _target.get("state") == null:
		return

	var dist := global_position.distance_to(_target.global_position)

	match detection_state:
		DetectionState.UNAWARE:
			if dist < detection_range * 0.6:
				detection_state = DetectionState.ALERT
				AudioManager.play_sfx("alert")
			elif dist < detection_range:
				_suspicion += delta
				if _suspicion > 1.5:
					detection_state = DetectionState.SUSPICIOUS
		DetectionState.SUSPICIOUS:
			if dist < detection_range * 0.7:
				detection_state = DetectionState.ALERT
				AudioManager.play_sfx("alert")
			elif dist > detection_range * 1.5:
				_suspicion -= delta
				if _suspicion <= 0:
					detection_state = DetectionState.UNAWARE
		DetectionState.ALERT:
			if dist < detection_range * 1.2:
				detection_state = DetectionState.HUNTING
			elif dist > detection_range * 2.0:
				detection_state = DetectionState.SUSPICIOUS
				_suspicion = 1.0
		DetectionState.HUNTING:
			if dist > detection_range * 2.5:
				detection_state = DetectionState.ALERT


func _update_attack_cooldown(delta: float) -> void:
	if _attack_cooldown > 0:
		_attack_cooldown -= delta


func _apply_knockback(delta: float) -> void:
	if _knockback_vel.length() > 1.0:
		velocity = _knockback_vel
		_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 600.0 * delta)
	# else velocity is set by AI


func _ai_process(_delta: float) -> void:
	# Override in subclasses
	pass


func take_damage(amount: int, knockback_dir: Vector2, is_crit: bool = false) -> void:
	if _is_dead:
		return

	hp -= amount
	_flash_timer = 0.2
	_knockback_vel = knockback_dir * (200.0 * (1.0 - knockback_resistance))
	_update_health_bar()

	# Spawn damage number
	_spawn_damage_number(amount, is_crit)

	# Alert on hit
	if detection_state == DetectionState.UNAWARE or detection_state == DetectionState.SUSPICIOUS:
		detection_state = DetectionState.HUNTING

	if hp <= 0:
		_die()


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var label := Label.new()
	label.text = str(amount) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", 14 if is_crit else 8)
	label.add_theme_color_override("font_color", Color.YELLOW if is_crit else Color.WHITE)
	label.position = Vector2(-8, -20)
	label.z_index = 100
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 24, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _die() -> void:
	_is_dead = true
	GameManager.kills += 1
	GameManager.add_xp(xp_value)
	AudioManager.play_sfx("death")
	died.emit(self)
	_drop_loot()

	# Report kill to mission manager
	var mm := get_tree().get_first_node_in_group("mission_manager")
	if mm and mm.has_method("report_kill"):
		mm.report_kill(name)

	# Death animation
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1, 0, 0, 0), 0.3)
	tween.parallel().tween_property(_sprite, "scale", Vector2(1.3, 0.3), 0.3)
	tween.tween_callback(queue_free)


func _drop_loot() -> void:
	var ItemDropScene := preload("res://scenes/items/ItemDrop.tscn")
	var loot_table: Array[Array] = [
		["scrap_metal", 0.6, Color(0.5, 0.5, 0.55)],
		["circuit_board", 0.3, Color(0.2, 0.6, 0.3)],
		["battery", 0.15, Color(0.7, 0.7, 0.2)],
		["wire", 0.4, Color(0.8, 0.4, 0.2)],
		["bandage", 0.2, Color(0.9, 0.9, 0.9)],
		["canned_food", 0.1, Color(0.6, 0.5, 0.3)],
		["arrow", 0.25, Color(0.5, 0.4, 0.3)],
	]

	for entry in loot_table:
		if randf() < float(entry[1]):
			var drop: Area2D = ItemDropScene.instantiate()
			drop.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
			if drop.has_method("setup"):
				drop.call_deferred("setup", entry[0], randi_range(1, 3), entry[2])
			get_parent().call_deferred("add_child", drop)


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player and _attack_cooldown <= 0 and not _is_dead:
		if body.has_method("take_damage"):
			var dir := (body.global_position - global_position).normalized()
			body.take_damage(attack_damage, dir)
			_attack_cooldown = 1.0
