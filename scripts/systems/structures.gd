extends Node2D

## Spawns structures in the world: cabins, bunkers, outposts.

const TerminalScene := preload("res://scenes/world/Terminal.tscn")

var _spawned: Array[Vector2] = []
var _check_timer: float = 0.0
var _structures_generated: int = 0

const MAX_STRUCTURES := 15
const STRUCTURE_SPACING := 250.0


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < 3.0 or not GameManager.player:
		return
	_check_timer = 0.0

	if _structures_generated >= MAX_STRUCTURES:
		return

	var player_pos := GameManager.player.global_position

	# Check distance from existing structures
	for pos in _spawned:
		if player_pos.distance_to(pos) < STRUCTURE_SPACING:
			return

	# Spawn a structure at a discoverable distance
	var angle := randf() * TAU
	var dist := randf_range(150.0, 300.0)
	var spawn_pos := player_pos + Vector2(cos(angle), sin(angle)) * dist

	var structure_type := randi() % 3
	match structure_type:
		0:
			_create_cabin(spawn_pos)
		1:
			_create_bunker(spawn_pos)
		2:
			_create_outpost(spawn_pos)

	_spawned.append(spawn_pos)
	_structures_generated += 1


func _create_cabin(pos: Vector2) -> void:
	var root := StaticBody2D.new()
	root.name = "Cabin"
	root.global_position = pos
	root.collision_layer = 4
	root.collision_mask = 0

	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 32)
	col.shape = shape
	root.add_child(col)

	# Visual
	var sprite := Sprite2D.new()
	var img := Image.create(48, 32, false, Image.FORMAT_RGBA8)
	_draw_cabin(img)
	sprite.texture = ImageTexture.create_from_image(img)
	root.add_child(sprite)

	get_parent().add_child(root)

	# Spawn items nearby
	_spawn_loot_nearby(pos, 2)


func _create_bunker(pos: Vector2) -> void:
	var root := StaticBody2D.new()
	root.name = "Bunker"
	root.global_position = pos
	root.collision_layer = 4
	root.collision_mask = 0

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	col.shape = shape
	root.add_child(col)

	var sprite := Sprite2D.new()
	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	_draw_bunker(img)
	sprite.texture = ImageTexture.create_from_image(img)
	root.add_child(sprite)

	get_parent().add_child(root)

	# Terminal inside
	var terminal: Area2D = TerminalScene.instantiate()
	terminal.global_position = pos + Vector2(25, 0)
	get_parent().add_child(terminal)

	_spawn_loot_nearby(pos, 4)


func _create_outpost(pos: Vector2) -> void:
	var root := StaticBody2D.new()
	root.name = "NexusOutpost"
	root.global_position = pos
	root.collision_layer = 4
	root.collision_mask = 0

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 48)
	col.shape = shape
	root.add_child(col)

	var sprite := Sprite2D.new()
	var img := Image.create(56, 48, false, Image.FORMAT_RGBA8)
	_draw_outpost(img)
	sprite.texture = ImageTexture.create_from_image(img)
	root.add_child(sprite)

	get_parent().add_child(root)

	# Terminal
	var terminal: Area2D = TerminalScene.instantiate()
	terminal.global_position = pos + Vector2(32, 0)
	get_parent().add_child(terminal)

	_spawn_loot_nearby(pos, 3)


func _draw_cabin(img: Image) -> void:
	# Wooden cabin
	var wall := Color(0.45, 0.3, 0.18)
	var roof := Color(0.3, 0.2, 0.12)
	var door := Color(0.25, 0.15, 0.08)
	var window := Color(0.5, 0.7, 0.8)

	# Roof
	for y in range(0, 10):
		for x in range(4 - y / 2, 44 + y / 2):
			if x >= 0 and x < 48:
				img.set_pixel(x, y, roof)

	# Walls
	for y in range(10, 30):
		for x in range(4, 44):
			img.set_pixel(x, y, wall)

	# Door
	for y in range(18, 30):
		for x in range(20, 28):
			img.set_pixel(x, y, door)

	# Windows
	for y in range(14, 20):
		for x in range(8, 14):
			img.set_pixel(x, y, window)
		for x in range(34, 40):
			img.set_pixel(x, y, window)

	# Foundation
	for y in range(30, 32):
		for x in range(2, 46):
			img.set_pixel(x, y, Color(0.3, 0.3, 0.3))


func _draw_bunker(img: Image) -> void:
	var concrete := Color(0.4, 0.4, 0.42)
	var metal := Color(0.35, 0.35, 0.38)
	var vent := Color(0.2, 0.2, 0.22)

	# Concrete block
	for y in range(8, 38):
		for x in range(4, 36):
			img.set_pixel(x, y, concrete)

	# Metal door
	for y in range(20, 36):
		for x in range(14, 26):
			img.set_pixel(x, y, metal)

	# Vents
	for y in range(10, 14):
		for x in range(8, 16):
			img.set_pixel(x, y, vent)
		for x in range(24, 32):
			img.set_pixel(x, y, vent)

	# Top
	for y in range(4, 8):
		for x in range(6, 34):
			img.set_pixel(x, y, concrete.darkened(0.1))


func _draw_outpost(img: Image) -> void:
	var metal := Color(0.3, 0.3, 0.35)
	var glow := Color(0.2, 0.8, 0.6)
	var dark := Color(0.15, 0.15, 0.2)

	# Main structure
	for y in range(8, 44):
		for x in range(8, 48):
			img.set_pixel(x, y, metal)

	# Glowing strips
	for y in range(12, 40):
		img.set_pixel(8, y, glow)
		img.set_pixel(47, y, glow)
	for x in range(8, 48):
		img.set_pixel(x, 8, glow)

	# Antenna tower
	for y in range(0, 12):
		img.set_pixel(4, y, dark)
		img.set_pixel(5, y, dark)
	img.set_pixel(3, 0, Color(1.0, 0.2, 0.2))
	img.set_pixel(6, 0, Color(1.0, 0.2, 0.2))

	# NEXUS symbol (glowing center)
	for y in range(22, 32):
		for x in range(22, 34):
			img.set_pixel(x, y, glow)


func _spawn_loot_nearby(pos: Vector2, count: int) -> void:
	var ItemDropScene := preload("res://scenes/items/ItemDrop.tscn")
	var loot: Array[Array] = [
		["scrap_metal", Color(0.5, 0.5, 0.55)],
		["circuit_board", Color(0.2, 0.6, 0.3)],
		["bandage", Color(0.9, 0.9, 0.9)],
		["canned_food", Color(0.6, 0.5, 0.3)],
		["water_bottle", Color(0.3, 0.5, 0.8)],
		["wire", Color(0.8, 0.4, 0.2)],
		["battery", Color(0.7, 0.7, 0.2)],
		["arrow", Color(0.5, 0.4, 0.3)],
	]

	for i in count:
		var entry: Array = loot[randi() % loot.size()]
		var drop: Area2D = ItemDropScene.instantiate()
		var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
		drop.global_position = pos + offset
		drop.call_deferred("setup", entry[0], randi_range(1, 3), entry[1])
		get_parent().call_deferred("add_child", drop)
