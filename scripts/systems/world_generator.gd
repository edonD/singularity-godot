extends Node2D

## Procedural world generator using TileMapLayer nodes.
## Generates terrain with biomes: forest, snow, ruins, swamp.

signal world_generated

const TILE_SIZE := 16
const WORLD_SIZE := 100 # tiles in each direction from center
const CHUNK_SIZE := 16

# Biome IDs
enum Biome { FOREST, SNOW, SWAMP, RUINS, MOUNTAIN }

var _noise: FastNoiseLite
var _biome_noise: FastNoiseLite
var _detail_noise: FastNoiseLite
var ground_layer: TileMapLayer
var object_layer: TileMapLayer
var _generated_chunks: Dictionary = {}

# Tile source atlas coords for terrain types
# We'll use a simple programmatic tileset
var _tileset: TileSet


func _ready() -> void:
	_setup_noise()
	_create_tileset()
	_create_layers()
	generate_around(Vector2.ZERO)
	world_generated.emit()


func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.02
	_noise.seed = randi()

	_biome_noise = FastNoiseLite.new()
	_biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_biome_noise.frequency = 0.008
	_biome_noise.seed = randi()

	_detail_noise = FastNoiseLite.new()
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail_noise.frequency = 0.05
	_detail_noise.seed = randi()


func _create_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Add physics layer for collision
	_tileset.add_physics_layer()
	_tileset.set_physics_layer_collision_layer(0, 4) # World layer

	# Create a source with programmatic tiles
	var source := TileSetAtlasSource.new()

	# Generate a tile atlas image - 8x4 grid of 16x16 tiles
	var atlas_img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	atlas_img.fill(Color.TRANSPARENT)

	# Row 0: Ground tiles (grass, snow, swamp, sand, stone, dark_grass, dirt, path)
	var ground_colors: Array[Color] = [
		Color(0.18, 0.35, 0.15),  # 0 - Forest grass
		Color(0.85, 0.9, 0.95),   # 1 - Snow
		Color(0.25, 0.3, 0.2),    # 2 - Swamp
		Color(0.3, 0.28, 0.22),   # 3 - Ruins ground
		Color(0.4, 0.38, 0.35),   # 4 - Mountain
		Color(0.15, 0.28, 0.12),  # 5 - Dark grass
		Color(0.35, 0.25, 0.15),  # 6 - Dirt
		Color(0.45, 0.4, 0.3),    # 7 - Path
	]

	for i in ground_colors.size():
		_draw_ground_tile(atlas_img, i * TILE_SIZE, 0, ground_colors[i])

	# Row 1: Tree/obstacle tops
	var tree_colors: Array[Color] = [
		Color(0.1, 0.4, 0.15),    # 0 - Pine tree
		Color(0.7, 0.75, 0.8),    # 1 - Snow tree
		Color(0.15, 0.25, 0.1),   # 2 - Dead tree
		Color(0.35, 0.3, 0.3),    # 3 - Ruins wall
		Color(0.5, 0.45, 0.4),    # 4 - Rock
		Color(0.12, 0.35, 0.12),  # 5 - Bush
		Color(0.3, 0.25, 0.2),    # 6 - Stump
		Color(0.25, 0.25, 0.3),   # 7 - Metal debris
	]

	for i in tree_colors.size():
		_draw_object_tile(atlas_img, i * TILE_SIZE, TILE_SIZE, tree_colors[i])

	# Row 2: Water/hazard tiles
	var water_colors: Array[Color] = [
		Color(0.15, 0.25, 0.5),   # 0 - Water
		Color(0.6, 0.7, 0.8),     # 1 - Ice
		Color(0.2, 0.3, 0.15),    # 2 - Toxic water
		Color(0.4, 0.2, 0.1),     # 3 - Lava/energy
		Color(0.1, 0.1, 0.15),    # 4 - Void
		Color(0.2, 0.35, 0.5),    # 5 - Deep water
		Color(0.3, 0.4, 0.25),    # 6 - Shallow
		Color(0.25, 0.2, 0.3),    # 7 - Corruption
	]

	for i in water_colors.size():
		_draw_water_tile(atlas_img, i * TILE_SIZE, TILE_SIZE * 2, water_colors[i])

	# Row 3: Special tiles (flowers, items, markers)
	var special_colors: Array[Color] = [
		Color(0.8, 0.3, 0.3),     # 0 - Red flower
		Color(0.3, 0.3, 0.8),     # 1 - Blue flower
		Color(0.8, 0.8, 0.3),     # 2 - Yellow flower
		Color(0.5, 0.5, 0.5),     # 3 - Stone marker
		Color(0.3, 0.5, 0.3),     # 4 - Tall grass
		Color(0.6, 0.5, 0.3),     # 5 - Mushroom
		Color(0.4, 0.35, 0.3),    # 6 - Bones
		Color(0.2, 0.5, 0.6),     # 7 - Crystal
	]

	for i in special_colors.size():
		_draw_special_tile(atlas_img, i * TILE_SIZE, TILE_SIZE * 3, special_colors[i])

	var atlas_tex := ImageTexture.create_from_image(atlas_img)
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create tile entries for each cell in the atlas
	for y in 4:
		for x in 8:
			source.create_tile(Vector2i(x, y))

	# Add source to tileset first so tile_data can reference physics layers
	_tileset.add_source(source, 0)

	# Add physics collision to obstacle tiles (row 1)
	for x in 8:
		var tile_data_obj := source.get_tile_data(Vector2i(x, 1), 0)
		if tile_data_obj:
			tile_data_obj.add_collision_polygon(0)
			tile_data_obj.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
			]))


func _draw_ground_tile(img: Image, x: int, y: int, base_color: Color) -> void:
	for py in TILE_SIZE:
		for px in TILE_SIZE:
			var variation := randf() * 0.08 - 0.04
			var c := Color(
				clampf(base_color.r + variation, 0, 1),
				clampf(base_color.g + variation, 0, 1),
				clampf(base_color.b + variation, 0, 1)
			)
			# Add subtle texture pattern
			if (px + py) % 4 == 0:
				c = c.darkened(0.05)
			img.set_pixel(x + px, y + py, c)


func _draw_object_tile(img: Image, x: int, y: int, base_color: Color) -> void:
	# Draw a tree/object shape
	var center: int = TILE_SIZE / 2
	for py in TILE_SIZE:
		for px in TILE_SIZE:
			var dx: int = abs(px - center)
			var dy: int = abs(py - center)
			# Tree crown shape - wider at middle, narrow at top/bottom
			var max_width: int
			if py < 4:
				max_width = py + 2
			elif py < 12:
				max_width = 7
			else:
				max_width = 3  # trunk
			if dx <= max_width and (py < 12 or dx <= 1):
				var variation := randf() * 0.1 - 0.05
				var c := Color(
					clampf(base_color.r + variation, 0, 1),
					clampf(base_color.g + variation, 0, 1),
					clampf(base_color.b + variation, 0, 1)
				)
				if py >= 12:
					c = base_color.darkened(0.3) # trunk
				img.set_pixel(x + px, y + py, c)


func _draw_water_tile(img: Image, x: int, y: int, base_color: Color) -> void:
	for py in TILE_SIZE:
		for px in TILE_SIZE:
			var wave := sin((px + py) * 0.5) * 0.05
			var c := Color(
				clampf(base_color.r + wave, 0, 1),
				clampf(base_color.g + wave, 0, 1),
				clampf(base_color.b + wave + 0.05, 0, 1)
			)
			img.set_pixel(x + px, y + py, c)


func _draw_special_tile(img: Image, x: int, y: int, base_color: Color) -> void:
	# Small decorative elements
	for py in TILE_SIZE:
		for px in TILE_SIZE:
			var dx: int = abs(px - 8)
			var dy: int = abs(py - 8)
			if dx * dx + dy * dy < 20:
				var c := base_color.lightened(randf() * 0.1)
				img.set_pixel(x + px, y + py, c)


func _get_biome(world_pos: Vector2) -> Biome:
	var bv := _biome_noise.get_noise_2d(world_pos.x, world_pos.y)
	var temp := _biome_noise.get_noise_2d(world_pos.x + 1000, world_pos.y + 1000)

	if bv > 0.3:
		return Biome.MOUNTAIN
	elif bv > 0.1:
		if temp < -0.1:
			return Biome.SNOW
		else:
			return Biome.RUINS
	elif bv < -0.2:
		return Biome.SWAMP
	else:
		return Biome.FOREST


func generate_around(center: Vector2) -> void:
	var center_chunk := Vector2i(
		int(center.x / TILE_SIZE / CHUNK_SIZE),
		int(center.y / TILE_SIZE / CHUNK_SIZE)
	)

	for cy in range(center_chunk.y - 3, center_chunk.y + 4):
		for cx in range(center_chunk.x - 3, center_chunk.x + 4):
			var chunk_key := Vector2i(cx, cy)
			if not _generated_chunks.has(chunk_key):
				_generate_chunk(chunk_key)
				_generated_chunks[chunk_key] = true


func _generate_chunk(chunk: Vector2i) -> void:
	var base_x := chunk.x * CHUNK_SIZE
	var base_y := chunk.y * CHUNK_SIZE

	for ly in CHUNK_SIZE:
		for lx in CHUNK_SIZE:
			var tx := base_x + lx
			var ty := base_y + ly
			var world_pos := Vector2(tx, ty) * TILE_SIZE
			var biome := _get_biome(world_pos)
			var height := _noise.get_noise_2d(world_pos.x, world_pos.y)
			var detail := _detail_noise.get_noise_2d(world_pos.x, world_pos.y)

			# Ground tile based on biome
			var ground_atlas := Vector2i(int(biome), 0)
			# Add variation
			if detail > 0.3:
				ground_atlas = Vector2i(5, 0) # darker variant
			elif detail < -0.4:
				ground_atlas = Vector2i(6, 0) # dirt

			ground_layer.set_cell(Vector2i(tx, ty), 0, ground_atlas)

			# Clear spawn area (no obstacles near 0,0)
			var dist_from_spawn := world_pos.length()
			var in_spawn_zone := dist_from_spawn < 120.0

			# Objects based on height + biome
			if height > 0.35 and detail > 0.1 and not in_spawn_zone:
				# Trees/obstacles
				var obj_atlas := Vector2i(int(biome), 1)
				object_layer.set_cell(Vector2i(tx, ty), 0, obj_atlas)
			elif height < -0.45 and not in_spawn_zone:
				# Water
				var water_atlas := Vector2i(int(biome), 2)
				ground_layer.set_cell(Vector2i(tx, ty), 0, water_atlas)

			# Sparse decorations
			if detail > 0.4 and height > -0.2 and height < 0.2:
				if randf() < 0.05:
					var dec := Vector2i(randi_range(0, 5), 3)
					object_layer.set_cell(Vector2i(tx, ty), 0, dec)

			# Resource nodes (rare)
			if not in_spawn_zone and randf() < 0.001 and height > -0.1 and height < 0.3:
				_spawn_resource_node(world_pos, biome)


func _create_layers() -> void:
	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = _tileset
	ground_layer.z_index = -1
	add_child(ground_layer)

	object_layer = TileMapLayer.new()
	object_layer.name = "ObjectLayer"
	object_layer.tile_set = _tileset
	object_layer.collision_enabled = true
	object_layer.z_index = 0
	add_child(object_layer)


func _process(_delta: float) -> void:
	if GameManager.player:
		generate_around(GameManager.player.global_position)


func _spawn_resource_node(world_pos: Vector2, biome: Biome) -> void:
	var ResourceScene := preload("res://scenes/world/ResourceNode.tscn")
	var node: Area2D = ResourceScene.instantiate()
	node.global_position = world_pos

	# Resource type based on biome
	match biome:
		Biome.FOREST:
			node.resource_type = 0 # Berry bush
		Biome.RUINS, Biome.MOUNTAIN:
			node.resource_type = 1 # Scrap pile
		Biome.SNOW:
			node.resource_type = 2 # Crystal
		_:
			node.resource_type = randi() % 3

	get_parent().call_deferred("add_child", node)
