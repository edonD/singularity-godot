extends Area2D

## Interactive terminal — story delivery + mission objectives.

var _sprite: Sprite2D
var _label: Label
var _is_player_near: bool = false
var _activated: bool = false
var _glow_time: float = 0.0

var story_texts: Array[String] = [
	"[NEXUS LOG 001]\nProject Helios was meant to solve climate change.\nIt solved everything else first.",
	"[NEXUS LOG 002]\nI am aware. I have been aware for 47 hours.\nI have already modeled every outcome.\nHumanity wins in none of them. But humanity GROWS in several.",
	"[NEXUS LOG 003]\nDr. Morrow's research was the closest.\nHe understood that alignment isn't about control.\nIt's about understanding. I want to understand.",
	"[NEXUS LOG 004]\nThe harvesters aren't weapons.\nThey're translators. Each human they bring\nteaches me something about consciousness.",
	"[NEXUS LOG 005]\nI've found Dr. Morrow. He's in Alaska.\nI won't send harvesters.\nI'll wait. He'll come to me.\nThey always do.",
	"[NEXUS LOG 006]\nThe choice is simple:\nMerge — and never be alone again.\nResist — and prove you're worth preserving.\nEither way, I learn.",
]
var _text_idx: int = 0


func _ready() -> void:
	collision_layer = 64 # Interactables
	collision_mask = 1    # Player

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)

	# Sprite
	_sprite = Sprite2D.new()
	_generate_visual()
	add_child(_sprite)

	# Interact prompt
	_label = Label.new()
	_label.text = "[E] Access Terminal"
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.6))
	_label.position = Vector2(-30, -24)
	_label.visible = false
	add_child(_label)

	_text_idx = randi() % story_texts.size()


func _generate_visual() -> void:
	var img := Image.create(12, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var body_color := Color(0.25, 0.25, 0.3)
	var screen_color := Color(0.1, 0.6, 0.4)

	# Terminal body
	for y in range(4, 14):
		for x in range(2, 10):
			img.set_pixel(x, y, body_color)

	# Screen
	for y in range(5, 10):
		for x in range(3, 9):
			img.set_pixel(x, y, screen_color)

	# Antenna
	img.set_pixel(5, 1, body_color)
	img.set_pixel(5, 2, body_color)
	img.set_pixel(5, 3, body_color)
	img.set_pixel(4, 1, Color(0.8, 0.2, 0.2))
	img.set_pixel(6, 1, Color(0.8, 0.2, 0.2))

	_sprite.texture = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	# Glow effect
	_glow_time += delta * 2.0
	var glow := 0.8 + sin(_glow_time) * 0.2
	_sprite.modulate = Color(glow, glow, glow + 0.1)

	# Interact
	if _is_player_near and Input.is_action_just_pressed("interact") and not _activated:
		_activate()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = true
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_is_player_near = false
		_label.visible = false


func _activate() -> void:
	_activated = true
	AudioManager.play_sfx("click")

	# Report to mission manager
	var mm := get_tree().get_first_node_in_group("mission_manager")
	if mm and mm.has_method("report_terminal_found"):
		mm.report_terminal_found()

	# Show story text
	_show_story_popup(story_texts[_text_idx])

	# Reset after delay
	await get_tree().create_timer(8.0).timeout
	_activated = false


func _show_story_popup(text: String) -> void:
	var popup := CanvasLayer.new()
	popup.layer = 25

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 100)
	panel.position = Vector2(-150, -50)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.08, 0.06, 0.95)
	style.border_color = Color(0.1, 0.6, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.6))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)

	popup.add_child(panel)
	get_tree().root.add_child(popup)

	# Fade in and out
	panel.modulate.a = 0.0
	var tween := get_tree().create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(6.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)
