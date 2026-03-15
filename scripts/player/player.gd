extends CharacterBody2D

## Player controller — snappy 8-directional movement with combat.
## Uses a state machine for clean animation/logic flow.

signal hp_changed(hp: int, max_hp: int)
signal stamina_changed(stamina: float, max_stamina: float)
signal hunger_changed(hunger: float)
signal thirst_changed(thirst: float)
signal xp_changed(xp: int, xp_to_next: int, level: int)
signal player_died

enum State { IDLE, RUN, SPRINT, ATTACK, ATTACK2, ATTACK3, DODGE, HURT, DEAD }

var state: State = State.IDLE
var facing: Vector2 = Vector2.DOWN
var attack_combo: int = 0
var combo_timer: float = 0.0
var dodge_timer: float = 0.0
var hurt_timer: float = 0.0
var attack_timer: float = 0.0
var invincible: bool = false
var invincible_timer: float = 0.0
var _input_buffer_attack: bool = false
var _input_buffer_dodge: bool = false

# Movement tuning — the secret sauce for game feel
const ACCELERATION := 1800.0
const FRICTION := 2400.0
const MAX_SPEED := 120.0
const SPRINT_SPEED := 195.0
const DODGE_SPEED := 280.0
const DODGE_DURATION := 0.22
const ATTACK_DURATION := 0.18
const ATTACK2_DURATION := 0.2
const ATTACK3_DURATION := 0.25
const HURT_DURATION := 0.15
const COMBO_WINDOW := 0.4
const STAMINA_REGEN := 25.0
const SPRINT_COST := 30.0
const DODGE_COST := 25.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	GameManager.player = self
	attack_shape.disabled = true
	# Generate sprite and setup camera
	var PlayerSetup := preload("res://scripts/player/player_setup.gd")
	PlayerSetup.setup_player_sprite(self)
	_emit_all_stats()


func _emit_all_stats() -> void:
	var s := GameManager.player_stats
	hp_changed.emit(s.hp, s.max_hp)
	stamina_changed.emit(s.stamina, s.max_stamina)
	hunger_changed.emit(s.hunger)
	thirst_changed.emit(s.thirst)
	xp_changed.emit(s.xp, s.xp_to_next, s.level)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_update_timers(delta)
	_update_invincibility(delta)
	_regen_stamina(delta)

	match state:
		State.IDLE, State.RUN, State.SPRINT:
			_handle_movement(delta)
			_handle_combat_input()
		State.ATTACK, State.ATTACK2, State.ATTACK3:
			_handle_attack_state(delta)
		State.DODGE:
			_handle_dodge_state(delta)
		State.HURT:
			_handle_hurt_state()

	move_and_slide()
	_update_sprite()


func _update_timers(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			attack_combo = 0


func _update_invincibility(delta: float) -> void:
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
			modulate.a = 1.0
		else:
			# Flash effect
			modulate.a = 0.5 + 0.5 * sin(invincible_timer * 30.0)


func _regen_stamina(delta: float) -> void:
	var s := GameManager.player_stats
	if state != State.SPRINT and s.stamina < s.max_stamina:
		s.stamina = minf(s.stamina + STAMINA_REGEN * delta, s.max_stamina)
		stamina_changed.emit(s.stamina, s.max_stamina)


func _handle_movement(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var s := GameManager.player_stats

	if input.length() > 0:
		facing = input.normalized()
		var sprinting: bool = Input.is_action_pressed("sprint") and s.stamina > 0
		var max_spd: float = SPRINT_SPEED if sprinting else MAX_SPEED

		velocity = velocity.move_toward(input.normalized() * max_spd, ACCELERATION * delta)

		if sprinting:
			state = State.SPRINT
			s.stamina = maxf(s.stamina - SPRINT_COST * delta, 0)
			stamina_changed.emit(s.stamina, s.max_stamina)
		else:
			state = State.RUN
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		state = State.IDLE


func _handle_combat_input() -> void:
	if Input.is_action_just_pressed("attack") or _input_buffer_attack:
		_input_buffer_attack = false
		_start_attack()
	elif Input.is_action_just_pressed("dodge") or _input_buffer_dodge:
		_input_buffer_dodge = false
		_start_dodge()


func _start_attack() -> void:
	var s := GameManager.player_stats
	if combo_timer > 0 and attack_combo == 1:
		state = State.ATTACK2
		attack_combo = 2
		attack_timer = ATTACK2_DURATION
	elif combo_timer > 0 and attack_combo == 2:
		state = State.ATTACK3
		attack_combo = 3
		attack_timer = ATTACK3_DURATION
	else:
		state = State.ATTACK
		attack_combo = 1
		attack_timer = ATTACK_DURATION

	combo_timer = COMBO_WINDOW
	velocity = facing * 60.0 # Lunge forward

	# Position and enable attack hitbox
	_position_attack_area()
	attack_shape.disabled = false
	AudioManager.play_sfx("swing")

	# Deal damage to enemies in area after a tiny delay
	await get_tree().create_timer(0.05).timeout
	if not is_inside_tree():
		return
	_deal_attack_damage()
	attack_shape.disabled = true


func _position_attack_area() -> void:
	attack_area.position = facing * 16.0
	attack_area.rotation = facing.angle()


func _deal_attack_damage() -> void:
	var s := GameManager.player_stats
	var bodies := attack_area.get_overlapping_bodies()
	var hit_something := false
	var combo_mult := 1.0 + (attack_combo - 1) * 0.3
	var is_crit: bool = randf() < s.crit_chance

	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var dmg := int(s.attack * combo_mult)
			if is_crit:
				dmg = int(dmg * 2.0)
			var knockback_dir := (body.global_position - global_position).normalized()
			body.take_damage(dmg, knockback_dir, is_crit)
			hit_something = true

	if hit_something:
		AudioManager.play_sfx("critical" if is_crit else "hit")
		CameraManager.shake(5.0 + attack_combo * 2.0 if not is_crit else 10.0)
		GameManager.request_hitstop(0.04 + attack_combo * 0.01)


func _handle_attack_state(delta: float) -> void:
	attack_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * 1.5 * delta)
	if attack_timer <= 0:
		state = State.IDLE
		# Check input buffer for combo
		if Input.is_action_pressed("attack"):
			_input_buffer_attack = true


func _start_dodge() -> void:
	var s := GameManager.player_stats
	if s.stamina < DODGE_COST:
		return
	s.stamina -= DODGE_COST
	stamina_changed.emit(s.stamina, s.max_stamina)

	state = State.DODGE
	dodge_timer = DODGE_DURATION
	invincible = true
	invincible_timer = DODGE_DURATION
	velocity = facing * DODGE_SPEED
	AudioManager.play_sfx("dodge")


func _handle_dodge_state(delta: float) -> void:
	dodge_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * 0.5 * delta)
	if dodge_timer <= 0:
		state = State.IDLE


func _handle_hurt_state() -> void:
	if hurt_timer > 0:
		hurt_timer -= get_physics_process_delta_time()
	if hurt_timer <= 0:
		state = State.IDLE


func take_damage(amount: int, from_dir: Vector2 = Vector2.ZERO) -> void:
	if invincible or state == State.DEAD:
		return

	var s := GameManager.player_stats
	var actual_dmg := maxi(amount - s.defense, 1)
	s.hp -= actual_dmg
	hp_changed.emit(s.hp, s.max_hp)

	AudioManager.play_sfx("hurt")
	CameraManager.shake(6.0)

	# Knockback
	velocity = from_dir * 150.0

	if s.hp <= 0:
		_die()
	else:
		state = State.HURT
		hurt_timer = HURT_DURATION
		invincible = true
		invincible_timer = 0.5

		# Spawn damage number
		_spawn_damage_number(actual_dmg, false)


func _die() -> void:
	state = State.DEAD
	AudioManager.play_sfx("death")
	player_died.emit()
	GameManager.player_died.emit()
	# Fade out
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 12 if is_crit else 8)
	label.add_theme_color_override("font_color", Color.YELLOW if is_crit else Color.RED)
	label.position = Vector2(-8, -20)
	label.z_index = 100
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 20, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


func _update_sprite() -> void:
	# Flip sprite based on facing direction
	if facing.x != 0:
		sprite.flip_h = facing.x < 0

	# Color modulation based on state for visual feedback
	match state:
		State.ATTACK, State.ATTACK2, State.ATTACK3:
			sprite.modulate = Color(1.2, 1.2, 1.0)
		State.DODGE:
			sprite.modulate = Color(0.7, 0.7, 1.0, 0.6)
		State.HURT:
			sprite.modulate = Color(1.5, 0.5, 0.5)
		_:
			sprite.modulate = Color.WHITE
