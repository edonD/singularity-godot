extends CanvasLayer

## Dilemma UI — presents moral choices with dramatic presentation.
## Pauses the game, shows the dilemma text, and lets player choose.

var _panel: Control
var _is_showing: bool = false
var _current_dilemma_id: String = ""
var _result_label: Label
var _dilemma_system: Node = null


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false
	# Connect to dilemma system after a frame
	_connect_dilemma_system.call_deferred()


func _connect_dilemma_system() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var nodes := get_tree().get_nodes_in_group("dilemma_system")
	if nodes.size() > 0:
		_dilemma_system = nodes[0]
		_dilemma_system.dilemma_triggered.connect(_on_dilemma_triggered)


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(overlay)

	# Result label (shown after choice)
	_result_label = Label.new()
	_result_label.set_anchors_preset(Control.PRESET_CENTER)
	_result_label.position = Vector2(-180, 60)
	_result_label.custom_minimum_size = Vector2(360, 40)
	_result_label.add_theme_font_size_override("font_size", 7)
	_result_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_result_label.visible = false
	_panel.add_child(_result_label)


func _on_dilemma_triggered(dilemma_id: String) -> void:
	if _is_showing:
		return
	if not _dilemma_system:
		return

	var dilemma: Dictionary = _dilemma_system.dilemmas.get(dilemma_id, {})
	if dilemma.is_empty():
		return

	_current_dilemma_id = dilemma_id
	_is_showing = true
	_panel.visible = true
	get_tree().paused = true

	_show_dilemma(dilemma)


func _show_dilemma(dilemma: Dictionary) -> void:
	# Clear old content (except overlay and result label)
	for child in _panel.get_children():
		if child is PanelContainer:
			child.queue_free()
	_result_label.visible = false

	# Main panel
	var container := PanelContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.custom_minimum_size = Vector2(340, 190)
	container.position = Vector2(-170, -95)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	style.border_color = Color(0.6, 0.4, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", style)
	_panel.add_child(container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	container.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = dilemma.title
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Divider
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(300, 1)
	divider.color = Color(0.4, 0.3, 0.2, 0.5)
	vbox.add_child(divider)

	# Description text
	var text := Label.new()
	text.text = dilemma.text
	text.add_theme_font_size_override("font_size", 7)
	text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.custom_minimum_size = Vector2(310, 0)
	vbox.add_child(text)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# Choice buttons
	for i in dilemma.choices.size():
		var choice: Dictionary = dilemma.choices[i]
		var btn := Button.new()
		btn.text = choice.text
		btn.add_theme_font_size_override("font_size", 8)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.08, 0.08, 0.12)
		btn_style.border_color = Color(0.4, 0.4, 0.5)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(2)
		btn_style.set_content_margin_all(5)
		btn.add_theme_stylebox_override("normal", btn_style)

		var idx := i
		btn.pressed.connect(func() -> void: _on_choice(idx))
		vbox.add_child(btn)

	AudioManager.play_sfx("click")


func _on_choice(choice_idx: int) -> void:
	if not _dilemma_system:
		return

	var dilemma: Dictionary = _dilemma_system.dilemmas.get(_current_dilemma_id, {})
	if dilemma.is_empty():
		return

	var choice: Dictionary = dilemma.choices[choice_idx]
	var description: String = choice.effects.get("description", "")

	# Resolve the dilemma (apply effects)
	_dilemma_system.resolve_dilemma(_current_dilemma_id, choice_idx)

	# Show result text
	_result_label.text = description
	_result_label.visible = true

	# Remove the choice panel
	for child in _panel.get_children():
		if child is PanelContainer:
			child.queue_free()

	# Show result in a new small panel
	var result_panel := PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.custom_minimum_size = Vector2(300, 80)
	result_panel.position = Vector2(-150, -40)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	style.border_color = Color(0.5, 0.5, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(10)
	result_panel.add_theme_stylebox_override("panel", style)
	_panel.add_child(result_panel)

	var rvbox := VBoxContainer.new()
	rvbox.add_theme_constant_override("separation", 6)
	result_panel.add_child(rvbox)

	var result_text := Label.new()
	result_text.text = description
	result_text.add_theme_font_size_override("font_size", 7)
	result_text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.65))
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	rvbox.add_child(result_text)

	var continue_btn := Button.new()
	continue_btn.text = "Continue..."
	continue_btn.add_theme_font_size_override("font_size", 8)
	continue_btn.pressed.connect(_close_dilemma)
	rvbox.add_child(continue_btn)

	AudioManager.play_sfx("pickup")


func _close_dilemma() -> void:
	_is_showing = false
	_panel.visible = false
	_current_dilemma_id = ""
	get_tree().paused = false
