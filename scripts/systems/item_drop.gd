extends Area2D

## Pickup item in the world. Floats and can be collected.

var item_id: String = ""
var amount: int = 1
var _bob_time: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 32 # Pickups layer
	collision_mask = 1   # Player layer
	_bob_time = randf() * TAU

	body_entered.connect(_on_body_entered)

	# Create collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)

	# Create sprite
	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)


func _generate_visual() -> void:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Get color from item database if possible
	var color := Color(0.7, 0.7, 0.7)
	# Simple colored square with highlight
	for y in range(1, 7):
		for x in range(1, 7):
			img.set_pixel(x, y, color)
	# Highlight
	for x in range(2, 5):
		img.set_pixel(x, 2, color.lightened(0.3))

	_sprite.texture = ImageTexture.create_from_image(img)


func setup(p_item_id: String, p_amount: int = 1, color: Color = Color(0.7, 0.7, 0.7)) -> void:
	item_id = p_item_id
	amount = p_amount
	# Regenerate with correct color
	if _sprite:
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for y in range(1, 7):
			for x in range(1, 7):
				img.set_pixel(x, y, color)
		for x in range(2, 5):
			img.set_pixel(x, 2, color.lightened(0.3))
		_sprite.texture = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_bob_time += delta * 2.0
	_sprite.position.y = sin(_bob_time) * 2.0


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		# Try to add to inventory
		var inv_node := get_tree().get_first_node_in_group("inventory")
		if inv_node and inv_node.has_method("add_item"):
			if inv_node.add_item(item_id, amount):
				AudioManager.play_sfx("pickup")
				# Flash effect
				var tween := create_tween()
				tween.tween_property(_sprite, "modulate", Color(2, 2, 2, 0), 0.2)
				tween.tween_callback(queue_free)
			else:
				# Inventory full
				pass
