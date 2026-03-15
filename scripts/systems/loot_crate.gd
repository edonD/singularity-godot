extends Area2D

## Loot crate — breakable container with items inside.

var _sprite: Sprite2D
var _label: Label
var _hp: int = 3 # Takes 3 hits to break
var _is_broken: bool = false


func _ready() -> void:
	collision_layer = 64
	collision_mask = 1
	add_to_group("enemies") # So player attacks can hit it

	body_entered.connect(_on_body_entered)

	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 12)
	col.shape = shape
	add_child(col)

	# Sprite
	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)


func _generate_visual() -> void:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var wood := Color(0.45, 0.3, 0.15)
	var band := Color(0.4, 0.4, 0.45)
	var lid := Color(0.5, 0.35, 0.2)

	# Box body
	for y in range(3, 11):
		for x in range(1, 11):
			img.set_pixel(x, y, wood)

	# Metal bands
	for x in range(1, 11):
		img.set_pixel(x, 3, band)
		img.set_pixel(x, 7, band)
		img.set_pixel(x, 10, band)

	# Lid
	for x in range(0, 12):
		img.set_pixel(x, 2, lid)
		img.set_pixel(x, 1, lid)

	_sprite.texture = ImageTexture.create_from_image(img)


func take_damage(_amount: int, _knockback_dir: Vector2, _is_crit: bool = false) -> void:
	if _is_broken:
		return

	_hp -= 1
	AudioManager.play_sfx("hit")
	CameraManager.shake(2.0)

	# Visual feedback
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)

	if _hp <= 0:
		_break_open()


func _break_open() -> void:
	_is_broken = true
	AudioManager.play_sfx("death")

	# Spawn loot
	var ItemDropScene := preload("res://scenes/items/ItemDrop.tscn")
	var possible_loot: Array[Array] = [
		["scrap_metal", Color(0.5, 0.5, 0.55)],
		["circuit_board", Color(0.2, 0.6, 0.3)],
		["battery", Color(0.7, 0.7, 0.2)],
		["wire", Color(0.8, 0.4, 0.2)],
		["bandage", Color(0.9, 0.9, 0.9)],
		["canned_food", Color(0.6, 0.5, 0.3)],
		["water_bottle", Color(0.3, 0.5, 0.8)],
		["arrow", Color(0.5, 0.4, 0.3)],
	]

	var num_drops := randi_range(2, 4)
	for i in num_drops:
		var entry: Array = possible_loot[randi() % possible_loot.size()]
		var drop: Area2D = ItemDropScene.instantiate()
		drop.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		drop.call_deferred("setup", entry[0], randi_range(1, 3), entry[1])
		get_parent().call_deferred("add_child", drop)

	# Break animation
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.3, 0.3), 0.2)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


func _on_body_entered(_body: Node2D) -> void:
	pass
