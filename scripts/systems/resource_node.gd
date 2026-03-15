extends Area2D

## Resource node — harvestable world objects (bushes, ore, scrap piles).

enum ResourceType { BERRY_BUSH, SCRAP_PILE, CRYSTAL }

var resource_type: ResourceType = ResourceType.BERRY_BUSH
var _sprite: Sprite2D
var _label: Label
var _is_player_near: bool = false
var _harvested: bool = false
var _respawn_timer: float = 0.0
var _bob_time: float = 0.0

const RESPAWN_TIME := 60.0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)

	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	_label.position = Vector2(-20, -18)
	_label.visible = false
	add_child(_label)
	_update_label()

	_bob_time = randf() * TAU


func _generate_visual() -> void:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	match resource_type:
		ResourceType.BERRY_BUSH:
			# Green bush with red berries
			for y in range(3, 11):
				for x in range(2, 10):
					img.set_pixel(x, y, Color(0.15, 0.35, 0.12))
			# Berries
			img.set_pixel(4, 5, Color(0.8, 0.2, 0.2))
			img.set_pixel(7, 6, Color(0.8, 0.2, 0.2))
			img.set_pixel(5, 8, Color(0.8, 0.2, 0.2))

		ResourceType.SCRAP_PILE:
			for y in range(6, 12):
				for x in range(2, 10):
					if randf() > 0.3:
						img.set_pixel(x, y, Color(0.4, 0.4, 0.45))
			for i in 3:
				var sx := randi_range(3, 8)
				var sy := randi_range(4, 8)
				img.set_pixel(sx, sy, Color(0.6, 0.4, 0.2))

		ResourceType.CRYSTAL:
			var crystal_color := Color(0.3, 0.6, 0.8)
			# Crystal shape
			for y in range(2, 10):
				var width: int = 1 if y < 4 or y > 8 else 2
				for x in range(6 - width, 6 + width):
					if x >= 0 and x < 12:
						img.set_pixel(x, y, crystal_color.lightened(randf() * 0.2))

	_sprite.texture = ImageTexture.create_from_image(img)


func _update_label() -> void:
	match resource_type:
		ResourceType.BERRY_BUSH:
			_label.text = "[E] Forage"
		ResourceType.SCRAP_PILE:
			_label.text = "[E] Scavenge"
		ResourceType.CRYSTAL:
			_label.text = "[E] Mine"


func _process(delta: float) -> void:
	_bob_time += delta
	_sprite.position.y = sin(_bob_time * 1.5) * 0.5

	if _harvested:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_harvested = false
			_sprite.modulate = Color.WHITE
			_sprite.scale = Vector2(1, 1)

	if _is_player_near and not _harvested and Input.is_action_just_pressed("interact"):
		_harvest()


func _harvest() -> void:
	_harvested = true
	_respawn_timer = RESPAWN_TIME
	AudioManager.play_sfx("pickup")

	var inv := get_tree().get_first_node_in_group("inventory")
	if not inv or not inv.has_method("add_item"):
		return

	match resource_type:
		ResourceType.BERRY_BUSH:
			inv.add_item("canned_food", 1) # Using as generic food
			GameManager.player_stats.hunger = minf(GameManager.player_stats.hunger + 15, 100)
		ResourceType.SCRAP_PILE:
			inv.add_item("scrap_metal", randi_range(2, 4))
			if randf() < 0.3:
				inv.add_item("wire", randi_range(1, 2))
		ResourceType.CRYSTAL:
			inv.add_item("battery", 1)
			if randf() < 0.2:
				inv.add_item("circuit_board", 1)

	GameManager.add_xp(5)

	# Shrink animation
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(0.3, 0.3), 0.2)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.3, 0.2)

	_label.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player and not _harvested:
		_is_player_near = true
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = false
		_label.visible = false
