extends Area2D

## Campfire — rest point that regenerates HP and cooks food.

var _sprite: Sprite2D
var _label: Label
var _glow_time: float = 0.0
var _is_player_near: bool = false
var _resting: bool = false


func _ready() -> void:
	collision_layer = 64
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

	# Sprite
	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)

	# Label
	_label = Label.new()
	_label.text = "[E] Rest"
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	_label.position = Vector2(-15, -18)
	_label.visible = false
	add_child(_label)


func _generate_visual() -> void:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Logs
	var log_color := Color(0.35, 0.2, 0.1)
	for x in range(2, 10):
		img.set_pixel(x, 9, log_color)
		img.set_pixel(x, 10, log_color)
	img.set_pixel(1, 8, log_color)
	img.set_pixel(10, 8, log_color)

	# Fire
	var fire_colors: Array[Color] = [
		Color(1.0, 0.3, 0.0),
		Color(1.0, 0.6, 0.0),
		Color(1.0, 0.9, 0.2),
	]
	for y in range(3, 9):
		var width: int = 2 if y < 5 else 3
		for x in range(6 - width, 6 + width):
			if x >= 0 and x < 12:
				var ci := mini(y - 3, 2)
				img.set_pixel(x, y, fire_colors[ci])

	_sprite.texture = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_glow_time += delta
	# Flicker effect
	var flicker := 0.8 + sin(_glow_time * 8.0) * 0.2
	_sprite.modulate = Color(flicker, flicker * 0.8, flicker * 0.5)

	if _is_player_near and Input.is_action_just_pressed("interact") and not _resting:
		_rest()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = true
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = false
		_label.visible = false


func _rest() -> void:
	_resting = true
	AudioManager.play_sfx("pickup")
	_label.text = "Resting..."

	var s := GameManager.player_stats
	# Heal over 3 seconds
	var tween := create_tween()
	tween.tween_interval(0.5)
	for i in 6:
		tween.tween_callback(func() -> void:
			s.hp = mini(s.hp + 5, s.max_hp)
			s.stamina = minf(s.stamina + 10.0, s.max_stamina)
			if GameManager.player:
				GameManager.player.hp_changed.emit(s.hp, s.max_hp)
				GameManager.player.stamina_changed.emit(s.stamina, s.max_stamina)
		)
		tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		_resting = false
		_label.text = "[E] Rest"
	)
