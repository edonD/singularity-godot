extends Area2D

## Environmental Puzzle — interactive world puzzles that require solving.
## Types: power_redirect, water_drain, radio_repair, door_hack, generator_fix

signal puzzle_solved(puzzle_type: String)

enum PuzzleType { POWER_REDIRECT, WATER_DRAIN, RADIO_REPAIR, DOOR_HACK, GENERATOR_FIX }

@export var puzzle_type: PuzzleType = PuzzleType.POWER_REDIRECT

var is_solved: bool = false
var _is_player_near: bool = false
var _sprite: Sprite2D
var _label: Label
var _state: int = 0 # Puzzle-specific state
var _required_steps: int = 3
var _step_timer: float = 0.0

# Puzzle configs
var _configs: Dictionary = {
	PuzzleType.POWER_REDIRECT: {
		"name": "Power Junction",
		"desc": "Redirect power to open the locked door",
		"interact_text": "[E] Reroute Power (%d/%d)",
		"steps": 3,
		"color": Color(0.8, 0.7, 0.2),
		"solved_text": "Power restored! Door unlocked.",
		"reward_loot": {"circuit_board": 2, "battery": 1},
		"reward_xp": 40,
		"condition": "", # No special requirement
	},
	PuzzleType.WATER_DRAIN: {
		"name": "Flood Valve",
		"desc": "Drain the flooded tunnel to access supplies below",
		"interact_text": "[E] Turn Valve (%d/%d)",
		"steps": 4,
		"color": Color(0.3, 0.5, 0.8),
		"solved_text": "Water drained! Tunnel accessible.",
		"reward_loot": {"scrap_metal": 6, "wire": 4},
		"reward_xp": 50,
		"condition": "",
	},
	PuzzleType.RADIO_REPAIR: {
		"name": "Broken Radio",
		"desc": "Repair the radio to contact other survivors",
		"interact_text": "[E] Repair Component (%d/%d)",
		"steps": 3,
		"color": Color(0.5, 0.7, 0.5),
		"solved_text": "Radio repaired! Survivor frequency found.",
		"reward_loot": {"bandage": 3, "canned_food": 2},
		"reward_xp": 60,
		"condition": "wire_2", # Needs 2 wire
	},
	PuzzleType.DOOR_HACK: {
		"name": "NEXUS Security Door",
		"desc": "Hack the electronic lock to access the armory",
		"interact_text": "[E] Hack Lock (%d/%d)",
		"steps": 5,
		"color": Color(0.6, 0.3, 0.7),
		"solved_text": "Lock bypassed! Armory open.",
		"reward_loot": {"circuit_board": 3, "battery": 2, "arrow": 15},
		"reward_xp": 80,
		"condition": "circuit_1", # Needs 1 circuit board
	},
	PuzzleType.GENERATOR_FIX: {
		"name": "Emergency Generator",
		"desc": "Fix the generator to power the shelter's defenses",
		"interact_text": "[E] Repair Generator (%d/%d)",
		"steps": 4,
		"color": Color(0.7, 0.5, 0.2),
		"solved_text": "Generator running! Shelter defenses online.",
		"reward_loot": {"scrap_metal": 4, "wire": 3},
		"reward_xp": 55,
		"condition": "scrap_3", # Needs 3 scrap
	},
}


func _ready() -> void:
	collision_layer = 64
	collision_mask = 1
	add_to_group("env_puzzles")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var config: Dictionary = _configs.get(puzzle_type, _configs[PuzzleType.POWER_REDIRECT])
	_required_steps = config.steps

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

	# Sprite
	_sprite = Sprite2D.new()
	_generate_visual(config.color)
	add_child(_sprite)

	# Label
	_label = Label.new()
	_label.text = config.interact_text % [_state, _required_steps]
	_label.add_theme_font_size_override("font_size", 6)
	_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	_label.position = Vector2(-25, -24)
	_label.visible = false
	add_child(_label)


func _generate_visual(color: Color) -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Draw a gear/mechanical shape
	for y in 16:
		for x in 16:
			var dx := x - 8
			var dy := y - 8
			var dist := sqrt(dx * dx + dy * dy)
			if dist < 6 and dist > 2:
				img.set_pixel(x, y, color)
			elif dist <= 2:
				img.set_pixel(x, y, color.lightened(0.3))
			# Gear teeth
			if dist >= 5 and dist < 8:
				var angle := atan2(dy, dx)
				if fmod(abs(angle), 0.8) < 0.3:
					img.set_pixel(x, y, color.darkened(0.2))

	_sprite.texture = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	if is_solved:
		return

	# Pulse animation
	_step_timer += delta
	_sprite.modulate.a = 0.8 + sin(_step_timer * 2.0) * 0.2

	if _is_player_near and Input.is_action_just_pressed("interact"):
		_advance_puzzle()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = true
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = false
		_label.visible = false


func _advance_puzzle() -> void:
	if is_solved:
		return

	var config: Dictionary = _configs.get(puzzle_type, _configs[PuzzleType.POWER_REDIRECT])

	# Check if we need materials
	if _state == 0 and not config.condition.is_empty():
		var parts := config.condition.split("_")
		if parts.size() == 2:
			var item_id: String = parts[0]
			var amount := int(parts[1])
			# Map short names to full IDs
			var item_map := {"wire": "wire", "circuit": "circuit_board", "scrap": "scrap_metal"}
			var full_id: String = item_map.get(item_id, item_id)
			var inv := get_tree().get_first_node_in_group("inventory")
			if inv and inv.has_method("has_item"):
				if not inv.has_item(full_id, amount):
					_label.text = "Need %d %s!" % [amount, full_id.replace("_", " ")]
					return
				inv.remove_item(full_id, amount)

	_state += 1
	AudioManager.play_sfx("click")
	CameraManager.shake(2.0)

	_label.text = config.interact_text % [_state, _required_steps]

	# Visual progress
	var progress := float(_state) / _required_steps
	_sprite.modulate = config.color.lerp(Color(0.3, 0.9, 0.3), progress)

	if _state >= _required_steps:
		_solve_puzzle(config)


func _solve_puzzle(config: Dictionary) -> void:
	is_solved = true
	_label.text = config.solved_text
	_sprite.modulate = Color(0.3, 0.9, 0.3)
	AudioManager.play_sfx("levelup")
	CameraManager.shake(5.0)

	# Give rewards
	if config.has("reward_loot"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("add_item"):
			for item_id: String in config.reward_loot:
				inv.add_item(item_id, int(config.reward_loot[item_id]))

	if config.has("reward_xp"):
		GameManager.add_xp(config.reward_xp)

	# Emotional boost
	GameManager.adjust_emotion("determination", 5)
	GameManager.adjust_emotion("hope", 3)

	puzzle_solved.emit(_configs.get(puzzle_type, {}).get("name", ""))

	# Fade to solved state
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(_label, "modulate:a", 0.0, 1.0)
