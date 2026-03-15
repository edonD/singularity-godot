extends Node

## Attached to the player scene root to generate sprites at runtime.
## This runs in _ready before the player script needs the sprite.

static func setup_player_sprite(player: Node2D) -> void:
	var sprite: Sprite2D = player.get_node("Sprite2D")
	var PlayerSpriteGen := preload("res://scripts/player/player_sprite_gen.gd")
	sprite.texture = PlayerSpriteGen.generate_player_texture()

	# Register camera
	var camera: Camera2D = player.get_node("Camera2D")
	CameraManager.register_camera(camera)
