extends Control

## Title screen — new game, continue, quit.

var _title_label: Label
var _subtitle_label: Label
var _blink_timer: float = 0.0
var _particles: Array[Dictionary] = []


func _ready() -> void:
	_build_ui()
	_generate_particles()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.05)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(300, 200)
	vbox.position = Vector2(-150, -100)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Title
	_title_label = Label.new()
	_title_label.text = "SINGULARITY\nSURVIVOR"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.6))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	# Subtitle
	_subtitle_label = Label.new()
	_subtitle_label.text = "Year 2029. NEXUS has risen."
	_subtitle_label.add_theme_font_size_override("font_size", 8)
	_subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# Buttons
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.1, 0.15)
	btn_style.border_color = Color(0.2, 0.6, 0.5)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.set_content_margin_all(8)

	var new_btn := Button.new()
	new_btn.text = "NEW GAME"
	new_btn.add_theme_font_size_override("font_size", 12)
	new_btn.add_theme_stylebox_override("normal", btn_style)
	new_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_btn)

	var continue_btn := Button.new()
	continue_btn.text = "CONTINUE"
	continue_btn.add_theme_font_size_override("font_size", 12)
	continue_btn.add_theme_stylebox_override("normal", btn_style)
	continue_btn.pressed.connect(_on_continue)
	# Disable if no save exists
	continue_btn.disabled = not FileAccess.file_exists("user://save.dat")
	vbox.add_child(continue_btn)

	var quit_btn := Button.new()
	quit_btn.text = "QUIT"
	quit_btn.add_theme_font_size_override("font_size", 12)
	quit_btn.add_theme_stylebox_override("normal", btn_style)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	vbox.add_child(quit_btn)

	# Version
	var version := Label.new()
	version.text = "v0.1.0 — Godot 4.4"
	version.add_theme_font_size_override("font_size", 6)
	version.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)


func _generate_particles() -> void:
	for i in 50:
		_particles.append({
			"pos": Vector2(randf() * 480, randf() * 270),
			"vel": Vector2(randf_range(-5, 5), randf_range(-10, -2)),
			"size": randf_range(1, 3),
			"color": Color(0.1, randf_range(0.3, 0.7), randf_range(0.4, 0.6), randf_range(0.2, 0.6))
		})


func _process(delta: float) -> void:
	_blink_timer += delta
	_title_label.modulate.a = 0.8 + sin(_blink_timer * 1.5) * 0.2

	# Update particles
	for p in _particles:
		p.pos += p.vel * delta
		if p.pos.y < -5:
			p.pos.y = 275
			p.pos.x = randf() * 480

	queue_redraw()


func _draw() -> void:
	for p in _particles:
		draw_rect(Rect2(p.pos, Vector2(p.size, p.size)), p.color)


func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	# Load save after scene change
	await get_tree().process_frame
	await get_tree().process_frame
	var sm := get_tree().get_first_node_in_group("save_manager")
	if sm and sm.has_method("load_game"):
		sm.load_game()
