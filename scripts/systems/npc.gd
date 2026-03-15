extends Area2D

## NPC survivor — can be rescued, gives dialogue and rewards.

var _sprite: Sprite2D
var _label: Label
var _is_player_near: bool = false
var _rescued: bool = false
var _bob_time: float = 0.0

var npc_name: String = "Survivor"
var dialogue_lines: Array[String] = [
	"Thank god... I thought I was the last one.",
	"NEXUS took everyone from the camp. I hid.",
	"Take this — I found it in the bunker nearby.",
	"The machines come in waves. At night, more.",
	"I heard Dr. Morrow is somewhere north. Be careful.",
	"There's a signal jammer in the ruins. Could help.",
	"I've been tracking patrol routes. They change at dusk.",
	"Don't trust the quiet. NEXUS is always watching.",
]
var _dialogue_idx: int = 0


func _ready() -> void:
	collision_layer = 64
	collision_mask = 1

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)

	# Sprite
	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)

	# Label
	_label = Label.new()
	_label.text = "[E] Talk"
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	_label.position = Vector2(-15, -22)
	_label.visible = false
	add_child(_label)

	_dialogue_idx = randi() % dialogue_lines.size()
	_bob_time = randf() * TAU


func _generate_visual() -> void:
	var img := Image.create(12, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var skin := Color(0.8, 0.65, 0.5)
	var hair := Color(0.3, 0.2, 0.15)
	var shirt := Color(0.4, 0.5, 0.35)
	var pants := Color(0.3, 0.3, 0.25)

	# Hair
	for x in range(3, 9):
		img.set_pixel(x, 1, hair)
		img.set_pixel(x, 2, hair)

	# Face
	for x in range(4, 8):
		img.set_pixel(x, 3, skin)
		img.set_pixel(x, 4, skin)
	img.set_pixel(5, 4, Color(0.1, 0.1, 0.1)) # eyes
	img.set_pixel(7, 4, Color(0.1, 0.1, 0.1))

	# Body
	for y in range(5, 11):
		for x in range(3, 9):
			img.set_pixel(x, y, shirt)

	# Legs
	for y in range(11, 14):
		for x in range(4, 6):
			img.set_pixel(x, y, pants)
		for x in range(6, 8):
			img.set_pixel(x, y, pants)

	# Boots
	for x in range(3, 6):
		img.set_pixel(x, 14, Color(0.25, 0.2, 0.15))
	for x in range(6, 9):
		img.set_pixel(x, 14, Color(0.25, 0.2, 0.15))

	_sprite.texture = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_bob_time += delta
	_sprite.position.y = sin(_bob_time * 1.5) * 1.0

	if _is_player_near and Input.is_action_just_pressed("interact"):
		_interact()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = true
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = false
		_label.visible = false


var dialogue_id: String = "" # If set, use branching dialogue system


func _interact() -> void:
	AudioManager.play_sfx("click")

	# Try branching dialogue system first
	if not dialogue_id.is_empty():
		var ds := get_tree().get_first_node_in_group("dialogue_system")
		if ds and ds.has_method("start_dialogue"):
			ds.start_dialogue(dialogue_id)
			if not _rescued:
				_rescued = true
				GameManager.add_xp(20)
			return

	if not _rescued:
		_rescued = true
		# Give rewards
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("add_item"):
			var rewards: Array[String] = ["bandage", "canned_food", "scrap_metal", "circuit_board", "arrow"]
			var reward: String = rewards[randi() % rewards.size()]
			inv.add_item(reward, randi_range(1, 3))
			AudioManager.play_sfx("pickup")

		GameManager.add_xp(20)

		# Emotional: helped NPC
		var emo := get_tree().get_first_node_in_group("emotional_state")
		if emo and emo.has_method("on_npc_helped"):
			emo.on_npc_helped()

	_show_dialogue()


func _show_dialogue() -> void:
	var text: String = dialogue_lines[_dialogue_idx]
	_dialogue_idx = (_dialogue_idx + 1) % dialogue_lines.size()

	var popup := CanvasLayer.new()
	popup.layer = 24

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(400, 50)
	panel.position = Vector2(40, -70)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.9)
	style.border_color = Color(0.5, 0.5, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = npc_name + ": \"" + text + "\""
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)

	popup.add_child(panel)
	get_tree().root.add_child(popup)

	var tween := get_tree().create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)
