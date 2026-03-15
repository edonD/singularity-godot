extends CanvasLayer

## Death screen — shown when player dies.

var _panel: Control
var _stats_label: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false
	GameManager.player_died.connect(_show)


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# Darkening overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.1, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(250, 180)
	vbox.position = Vector2(-125, -90)
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.15, 0.15))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "NEXUS claims another."
	subtitle.add_theme_font_size_override("font_size", 8)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 8)
	_stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stats_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var retry_btn := Button.new()
	retry_btn.text = "Try Again"
	retry_btn.add_theme_font_size_override("font_size", 12)
	retry_btn.pressed.connect(func() -> void:
		GameManager.state = GameManager.GameState.PLAYING
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	)
	vbox.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.add_theme_font_size_override("font_size", 12)
	menu_btn.pressed.connect(func() -> void:
		GameManager.state = GameManager.GameState.MENU
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
	)
	vbox.add_child(menu_btn)


func _show() -> void:
	_panel.visible = true
	get_tree().paused = true
	GameManager.state = GameManager.GameState.GAME_OVER

	_stats_label.text = "Day %d | Level %d | Kills: %d" % [
		GameManager.day,
		GameManager.player_stats.level,
		GameManager.kills,
	]

	# Fade in
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_panel, "modulate:a", 1.0, 1.0)
