extends Area2D

## Projectile — travels in a direction, damages enemies on contact.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: int = 8
var is_crit: bool = false
var _lifetime: float = 2.0
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 8 # Projectiles
	collision_mask = 2   # Enemies

	# Create collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	col.shape = shape
	add_child(col)

	# Create sprite
	_sprite = Sprite2D.new()
	var img := Image.create(6, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# Arrow shape
	for x in 6:
		img.set_pixel(x, 1, Color(0.7, 0.6, 0.4))
	img.set_pixel(5, 0, Color(0.5, 0.5, 0.55))
	img.set_pixel(5, 2, Color(0.5, 0.5, 0.55))
	_sprite.texture = ImageTexture.create_from_image(img)
	add_child(_sprite)

	# Rotate to face direction
	rotation = direction.angle()

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, direction, is_crit)
		AudioManager.play_sfx("hit")
		CameraManager.shake(3.0)
		queue_free()


func _on_area_entered(_area: Area2D) -> void:
	pass
