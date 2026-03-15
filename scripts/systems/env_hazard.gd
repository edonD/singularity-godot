extends Area2D

## Environmental hazard — toxic pools, electric fences, etc.

enum HazardType { TOXIC_POOL, ELECTRIC_FENCE, NEXUS_FIELD }

var hazard_type: HazardType = HazardType.TOXIC_POOL
var _sprite: Sprite2D
var _damage_tick: float = 0.0
var _glow_time: float = 0.0
var _player_inside: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	col.shape = shape
	add_child(col)

	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)


func _generate_visual() -> void:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	match hazard_type:
		HazardType.TOXIC_POOL:
			for y in 24:
				for x in 24:
					var dx: int = abs(x - 12)
					var dy: int = abs(y - 12)
					if dx * dx + dy * dy < 144:
						var c := Color(0.2, 0.5, 0.15, 0.6)
						if (x + y) % 3 == 0:
							c = c.lightened(0.1)
						img.set_pixel(x, y, c)
		HazardType.ELECTRIC_FENCE:
			for y in range(0, 24, 4):
				for x in 24:
					img.set_pixel(x, y, Color(0.5, 0.5, 0.55))
					img.set_pixel(x, y + 1, Color(0.5, 0.5, 0.55))
			# Sparks
			for i in 5:
				var sx := randi_range(2, 21)
				var sy := randi_range(2, 21)
				img.set_pixel(sx, sy, Color(1.0, 1.0, 0.5))
		HazardType.NEXUS_FIELD:
			for y in 24:
				for x in 24:
					if (x + y) % 2 == 0:
						img.set_pixel(x, y, Color(0.1, 0.3, 0.5, 0.3))

	_sprite.texture = ImageTexture.create_from_image(img)


func setup(type: HazardType) -> void:
	hazard_type = type
	if _sprite:
		_generate_visual()


func _process(delta: float) -> void:
	_glow_time += delta

	match hazard_type:
		HazardType.TOXIC_POOL:
			_sprite.modulate.a = 0.6 + sin(_glow_time * 2.0) * 0.1
		HazardType.ELECTRIC_FENCE:
			if fmod(_glow_time, 0.5) < 0.05:
				_sprite.modulate = Color(1.5, 1.5, 2.0)
			else:
				_sprite.modulate = Color.WHITE
		HazardType.NEXUS_FIELD:
			_sprite.modulate = Color(1.0, 1.0, 1.0, 0.4 + sin(_glow_time * 3.0) * 0.2)

	if _player_inside:
		_damage_tick += delta
		var interval := 1.0
		match hazard_type:
			HazardType.TOXIC_POOL:
				interval = 1.5
			HazardType.ELECTRIC_FENCE:
				interval = 0.8
			HazardType.NEXUS_FIELD:
				interval = 2.0

		if _damage_tick >= interval:
			_damage_tick = 0.0
			_deal_damage()


func _deal_damage() -> void:
	if not GameManager.player or not GameManager.player.has_method("take_damage"):
		return

	var dmg := 5
	match hazard_type:
		HazardType.TOXIC_POOL:
			dmg = 3
			# Apply poison via status effects if available
			var se := get_tree().get_first_node_in_group("status_effects")
			if se and se.has_method("apply_effect"):
				se.apply_effect(GameManager.player, "poison", 3.0)
		HazardType.ELECTRIC_FENCE:
			dmg = 8
			CameraManager.shake(4.0)
		HazardType.NEXUS_FIELD:
			dmg = 4
			# Slow player
			var se := get_tree().get_first_node_in_group("status_effects")
			if se and se.has_method("apply_effect"):
				se.apply_effect(GameManager.player, "slow", 2.0)

	GameManager.player.take_damage(dmg, Vector2.ZERO)


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player_inside = false
		_damage_tick = 0.0
