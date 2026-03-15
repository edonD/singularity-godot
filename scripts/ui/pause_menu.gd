extends CanvasLayer

## Pause menu with resume/quit options.

var _panel: PanelContainer
var _visible: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false
	GameManager.game_paused.connect(_show)
	GameManager.game_resumed.connect(_hide)


func _build_ui() -> void:
	# Dim overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(160, 120)
	_panel.position = Vector2(-80, -60)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.4, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.add_theme_font_size_override("font_size", 10)
	resume_btn.pressed.connect(func() -> void: GameManager.resume_game())
	vbox.add_child(resume_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.add_theme_font_size_override("font_size", 10)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	vbox.add_child(quit_btn)

	add_child(_panel)


func _show() -> void:
	_panel.visible = true
	_visible = true


func _hide() -> void:
	_panel.visible = false
	_visible = false
