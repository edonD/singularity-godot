extends CanvasLayer

## World Map UI — fog of war, player position, discovered locations.
## Press M to toggle. Shows explored areas and POIs.

var _panel: Control
var _is_open: bool = false
var _map_rect: ColorRect
var _map_texture: ImageTexture
var _map_image: Image
var _marker_container: Control

const MAP_DISPLAY_SIZE := 200 # pixels for the map display
const MAP_WORLD_RANGE := 2000.0 # world units the map covers
const REVEAL_RADIUS := 5 # tiles revealed per update
const MAP_RES := 128 # map image resolution

var _explored: Dictionary = {} # Vector2i -> true (explored map tiles)
var _discovered_locations: Array[Dictionary] = [] # [{name, pos, color, type}]


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_map()
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			_toggle()
			get_viewport().set_input_as_handled()


func _toggle() -> void:
	_is_open = not _is_open
	_panel.visible = _is_open
	if _is_open:
		_update_map()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _init_map() -> void:
	_map_image = Image.create(MAP_RES, MAP_RES, false, Image.FORMAT_RGBA8)
	_map_image.fill(Color(0.05, 0.05, 0.08)) # Fog of war = dark
	_map_texture = ImageTexture.create_from_image(_map_image)


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0.02, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(overlay)

	# Map container
	var container := PanelContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.custom_minimum_size = Vector2(MAP_DISPLAY_SIZE + 80, MAP_DISPLAY_SIZE + 50)
	container.position = Vector2(-int((MAP_DISPLAY_SIZE + 80) / 2), -int((MAP_DISPLAY_SIZE + 50) / 2))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	style.border_color = Color(0.3, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", style)
	_panel.add_child(container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "WORLD MAP"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_hint := Label.new()
	close_hint.text = "[M] Close"
	close_hint.add_theme_font_size_override("font_size", 7)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.add_child(close_hint)

	# Map display
	var map_container := Control.new()
	map_container.custom_minimum_size = Vector2(MAP_DISPLAY_SIZE, MAP_DISPLAY_SIZE)
	vbox.add_child(map_container)

	_map_rect = ColorRect.new()
	_map_rect.custom_minimum_size = Vector2(MAP_DISPLAY_SIZE, MAP_DISPLAY_SIZE)
	_map_rect.size = Vector2(MAP_DISPLAY_SIZE, MAP_DISPLAY_SIZE)
	map_container.add_child(_map_rect)

	# Marker overlay
	_marker_container = Control.new()
	_marker_container.custom_minimum_size = Vector2(MAP_DISPLAY_SIZE, MAP_DISPLAY_SIZE)
	map_container.add_child(_marker_container)

	# Legend
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 8)
	vbox.add_child(legend)

	_add_legend_item(legend, Color(0.2, 0.8, 0.4), "You")
	_add_legend_item(legend, Color(0.8, 0.6, 0.2), "Structure")
	_add_legend_item(legend, Color(0.5, 0.5, 0.8), "POI")
	_add_legend_item(legend, Color(0.8, 0.3, 0.3), "Danger")

	# NEXUS threat level
	var threat := Label.new()
	threat.name = "ThreatLabel"
	threat.add_theme_font_size_override("font_size", 7)
	threat.add_theme_color_override("font_color", Color(0.6, 0.3, 0.6))
	vbox.add_child(threat)


func _add_legend_item(parent: HBoxContainer, color: Color, text: String) -> void:
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(6, 6)
	dot.color = color
	parent.add_child(dot)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	parent.add_child(label)


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING or not GameManager.player:
		return

	# Continuously reveal map around player
	var player_pos := GameManager.player.global_position
	var map_x := int((player_pos.x + MAP_WORLD_RANGE) / (MAP_WORLD_RANGE * 2) * MAP_RES)
	var map_y := int((player_pos.y + MAP_WORLD_RANGE) / (MAP_WORLD_RANGE * 2) * MAP_RES)
	map_x = clampi(map_x, 0, MAP_RES - 1)
	map_y = clampi(map_y, 0, MAP_RES - 1)

	# Reveal area around player
	for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			var rx := map_x + dx
			var ry := map_y + dy
			if rx >= 0 and rx < MAP_RES and ry >= 0 and ry < MAP_RES:
				var key := Vector2i(rx, ry)
				if not _explored.has(key):
					_explored[key] = true
					_reveal_tile(rx, ry)


func _reveal_tile(rx: int, ry: int) -> void:
	# Get approximate biome color for this world position
	var world_x := (float(rx) / MAP_RES * MAP_WORLD_RANGE * 2) - MAP_WORLD_RANGE
	var world_y := (float(ry) / MAP_RES * MAP_WORLD_RANGE * 2) - MAP_WORLD_RANGE

	# Simple biome color approximation
	var color := Color(0.2, 0.35, 0.2) # Default green
	# Vary based on position (pseudo-biome)
	var hash_val := sin(world_x * 0.003) * cos(world_y * 0.003)
	if hash_val > 0.4:
		color = Color(0.4, 0.38, 0.35) # Mountain
	elif hash_val > 0.15:
		color = Color(0.8, 0.85, 0.9) # Snow
	elif hash_val < -0.3:
		color = Color(0.2, 0.28, 0.18) # Swamp
	elif hash_val < -0.1:
		color = Color(0.3, 0.28, 0.22) # Ruins

	_map_image.set_pixel(rx, ry, color)


func _update_map() -> void:
	# Refresh texture
	_map_texture = ImageTexture.create_from_image(_map_image)
	_map_rect.material = null # Force refresh

	# Draw the map texture onto the rect using a TextureRect
	for child in _map_rect.get_children():
		child.queue_free()

	var tex_rect := TextureRect.new()
	tex_rect.texture = _map_texture
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.custom_minimum_size = Vector2(MAP_DISPLAY_SIZE, MAP_DISPLAY_SIZE)
	tex_rect.size = Vector2(MAP_DISPLAY_SIZE, MAP_DISPLAY_SIZE)
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_map_rect.add_child(tex_rect)

	# Clear markers
	for child in _marker_container.get_children():
		child.queue_free()

	# Player marker
	if GameManager.player:
		var player_pos := GameManager.player.global_position
		var px := (player_pos.x + MAP_WORLD_RANGE) / (MAP_WORLD_RANGE * 2) * MAP_DISPLAY_SIZE
		var py := (player_pos.y + MAP_WORLD_RANGE) / (MAP_WORLD_RANGE * 2) * MAP_DISPLAY_SIZE
		_add_marker(Vector2(px, py), Color(0.2, 0.9, 0.4), "YOU", 5)

	# POI markers
	var poi_sys := get_tree().get_first_node_in_group("poi_system")
	if poi_sys:
		for poi_id: String in poi_sys.discovered_pois:
			var poi: Dictionary = poi_sys.discovered_pois[poi_id]
			var pos: Vector2 = poi.position
			var mx := (pos.x + MAP_WORLD_RANGE) / (MAP_WORLD_RANGE * 2) * MAP_DISPLAY_SIZE
			var my := (pos.y + MAP_WORLD_RANGE) / (MAP_WORLD_RANGE * 2) * MAP_DISPLAY_SIZE
			var color := Color(0.5, 0.5, 0.8) if not poi.completed else Color(0.3, 0.4, 0.3)
			_add_marker(Vector2(mx, my), color, "", 3)

	# NEXUS threat
	var director := get_tree().get_first_node_in_group("nexus_director")
	if director:
		var threat_label := _panel.find_child("ThreatLabel", true, false)
		if threat_label:
			threat_label.text = "NEXUS Threat: %s (Level %d)" % [director.get_current_tier_name(), director.threat_level]


func _add_marker(pos: Vector2, color: Color, label_text: String, marker_size: int) -> void:
	var marker := ColorRect.new()
	marker.custom_minimum_size = Vector2(marker_size, marker_size)
	marker.color = color
	marker.position = pos - Vector2(marker_size / 2, marker_size / 2)
	_marker_container.add_child(marker)

	if not label_text.is_empty():
		var label := Label.new()
		label.text = label_text
		label.add_theme_font_size_override("font_size", 5)
		label.add_theme_color_override("font_color", color)
		label.position = pos + Vector2(4, -4)
		_marker_container.add_child(label)


func get_save_data() -> Dictionary:
	# Save explored tiles as packed array
	var tiles: Array[Vector2i] = []
	for key: Vector2i in _explored:
		tiles.append(key)
	return {"explored": tiles}


func load_save_data(data: Dictionary) -> void:
	_explored.clear()
	for tile: Vector2i in data.get("explored", []):
		_explored[tile] = true
		_reveal_tile(tile.x, tile.y)
