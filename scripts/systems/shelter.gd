extends Node

## Shelter Building — place walls, doors, storage, workbench.
## Press B to enter build mode. Place structures with left click.
## Shelter provides warmth, rest point, and storage.

signal shelter_built(position: Vector2)
signal shelter_destroyed

var build_mode: bool = false
var _selected_piece: int = 0 # 0=wall, 1=door, 2=workbench, 3=storage, 4=campfire
var placed_pieces: Array[Dictionary] = [] # [{type, position, node}]
var shelter_center: Vector2 = Vector2.ZERO
var has_shelter: bool = false

const PIECE_COSTS: Array[Dictionary] = [
	{"name": "Wall", "cost": {"scrap_metal": 3}, "color": Color(0.4, 0.35, 0.25)},
	{"name": "Door", "cost": {"scrap_metal": 2, "wire": 1}, "color": Color(0.35, 0.3, 0.2)},
	{"name": "Workbench", "cost": {"scrap_metal": 5, "wire": 2}, "color": Color(0.5, 0.4, 0.25)},
	{"name": "Storage", "cost": {"scrap_metal": 4}, "color": Color(0.45, 0.4, 0.3)},
	{"name": "Campfire", "cost": {"scrap_metal": 2}, "color": Color(0.7, 0.4, 0.2)},
]

var _build_preview: Node2D = null
var _build_label: Label = null


func _ready() -> void:
	add_to_group("shelter")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			_toggle_build_mode()
			get_viewport().set_input_as_handled()

	if build_mode and event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_1:
			_selected_piece = 0
		elif event.physical_keycode == KEY_2:
			_selected_piece = 1
		elif event.physical_keycode == KEY_3:
			_selected_piece = 2
		elif event.physical_keycode == KEY_4:
			_selected_piece = 3
		elif event.physical_keycode == KEY_5:
			_selected_piece = 4

	if build_mode and event is InputEventMouseButton and event.pressed and event.button_index == 1:
		_place_piece()


func _toggle_build_mode() -> void:
	build_mode = not build_mode
	if build_mode:
		_create_preview()
	else:
		_remove_preview()


func _process(_delta: float) -> void:
	if not build_mode or not GameManager.player:
		return
	# Update preview position (snap to grid)
	if _build_preview:
		var mouse_pos := GameManager.player.get_global_mouse_position()
		var snapped := Vector2(snapped(mouse_pos.x, 16), snapped(mouse_pos.y, 16))
		_build_preview.global_position = snapped
		# Update label
		var piece: Dictionary = PIECE_COSTS[_selected_piece]
		if _build_label:
			_build_label.text = "[B]Build: %s (1-5 to switch)" % piece.name


func _create_preview() -> void:
	_remove_preview()
	_build_preview = Node2D.new()
	_build_preview.z_index = 50

	var sprite := Sprite2D.new()
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var piece: Dictionary = PIECE_COSTS[_selected_piece]
	var color: Color = piece.color
	color.a = 0.5
	for y in 16:
		for x in 16:
			if x == 0 or x == 15 or y == 0 or y == 15:
				img.set_pixel(x, y, color.lightened(0.2))
			else:
				img.set_pixel(x, y, color)
	sprite.texture = ImageTexture.create_from_image(img)
	_build_preview.add_child(sprite)

	# Build mode label
	_build_label = Label.new()
	_build_label.text = "[B]Build: " + piece.name
	_build_label.add_theme_font_size_override("font_size", 7)
	_build_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	_build_label.position = Vector2(-20, -20)
	_build_preview.add_child(_build_label)

	GameManager.player.get_parent().add_child(_build_preview)


func _remove_preview() -> void:
	if _build_preview and is_instance_valid(_build_preview):
		_build_preview.queue_free()
		_build_preview = null
		_build_label = null


func _place_piece() -> void:
	if not _build_preview or not GameManager.player:
		return

	var piece: Dictionary = PIECE_COSTS[_selected_piece]
	var inv := get_tree().get_first_node_in_group("inventory")
	if not inv:
		return

	# Check costs
	for item_id: String in piece.cost:
		if not inv.has_item(item_id, int(piece.cost[item_id])):
			AudioManager.play_sfx("hurt")
			return

	# Deduct costs
	for item_id: String in piece.cost:
		inv.remove_item(item_id, int(piece.cost[item_id]))

	# Place the piece
	var pos := _build_preview.global_position
	var node := _create_piece_node(_selected_piece, pos)
	GameManager.player.get_parent().add_child(node)

	placed_pieces.append({"type": _selected_piece, "position": pos})
	AudioManager.play_sfx("click")
	CameraManager.shake(2.0)

	# Mark shelter if enough pieces
	if placed_pieces.size() >= 3 and not has_shelter:
		has_shelter = true
		shelter_center = pos
		shelter_built.emit(pos)

	# Recreate preview with updated piece type
	_create_preview()


func _create_piece_node(piece_type: int, pos: Vector2) -> Node2D:
	var piece: Dictionary = PIECE_COSTS[piece_type]
	var color: Color = piece.color

	match piece_type:
		0, 1: # Wall / Door
			var body := StaticBody2D.new()
			body.global_position = pos
			body.collision_layer = 4
			body.collision_mask = 0
			var col := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(16, 16)
			col.shape = shape
			body.add_child(col)
			var sprite := Sprite2D.new()
			var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			_draw_piece(img, color, piece_type)
			sprite.texture = ImageTexture.create_from_image(img)
			body.add_child(sprite)
			return body
		2: # Workbench — no collision, interactable
			var area := Area2D.new()
			area.global_position = pos
			area.collision_layer = 64; area.collision_mask = 1
			var col := CollisionShape2D.new()
			var shape := CircleShape2D.new()
			shape.radius = 12.0
			col.shape = shape
			area.add_child(col)
			var sprite := Sprite2D.new()
			var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			_draw_piece(img, color, piece_type)
			sprite.texture = ImageTexture.create_from_image(img)
			area.add_child(sprite)
			return area
		3: # Storage crate
			var area := Area2D.new()
			area.global_position = pos
			area.collision_layer = 64; area.collision_mask = 1
			var col := CollisionShape2D.new()
			var shape := CircleShape2D.new()
			shape.radius = 10.0
			col.shape = shape
			area.add_child(col)
			var sprite := Sprite2D.new()
			var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
			_draw_piece(img, color, piece_type)
			sprite.texture = ImageTexture.create_from_image(img)
			area.add_child(sprite)
			return area
		4: # Campfire
			var CampfireScene := preload("res://scenes/world/Campfire.tscn")
			var fire: Area2D = CampfireScene.instantiate()
			fire.global_position = pos
			return fire

	return Node2D.new()


func _draw_piece(img: Image, color: Color, piece_type: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			match piece_type:
				0: # Wall - solid block
					if x == 0 or x == w - 1 or y == 0 or y == h - 1:
						img.set_pixel(x, y, color.darkened(0.2))
					else:
						img.set_pixel(x, y, color)
				1: # Door - gap in middle
					if y > 4 and y < h - 2 and x > 3 and x < w - 3:
						img.set_pixel(x, y, color.darkened(0.3))
					else:
						img.set_pixel(x, y, color)
				2: # Workbench - table shape
					if y > 2 and y < h - 4:
						img.set_pixel(x, y, color)
					elif y >= h - 4 and (x < 3 or x > w - 4):
						img.set_pixel(x, y, color.darkened(0.2))
				3: # Storage - box
					if x > 1 and x < w - 2 and y > 1 and y < h - 2:
						img.set_pixel(x, y, color)
					if x == w / 2 and y > 2 and y < h - 3:
						img.set_pixel(x, y, color.lightened(0.2))


func get_save_data() -> Dictionary:
	var pieces: Array[Dictionary] = []
	for p in placed_pieces:
		pieces.append({"type": p.type, "x": p.position.x, "y": p.position.y})
	return {"pieces": pieces, "has_shelter": has_shelter, "cx": shelter_center.x, "cy": shelter_center.y}


func load_save_data(data: Dictionary) -> void:
	has_shelter = data.get("has_shelter", false)
	shelter_center = Vector2(data.get("cx", 0), data.get("cy", 0))
