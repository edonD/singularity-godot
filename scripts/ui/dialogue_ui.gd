extends CanvasLayer

## Dialogue UI — bottom-screen box with NPC portrait, text, and choice buttons.
## Typewriter text effect. Pauses game during dialogue.

var _panel: Control
var _is_showing: bool = false
var _dialogue_system: Node = null
var _portrait_rect: ColorRect
var _speaker_label: Label
var _text_label: Label
var _choices_container: VBoxContainer
var _typewriter_timer: float = 0.0
var _full_text: String = ""
var _displayed_chars: int = 0
const TYPE_SPEED := 40.0 # chars per second


func _ready() -> void:
	layer = 23
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false
	_connect.call_deferred()


func _connect() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var nodes := get_tree().get_nodes_in_group("dialogue_system")
	if nodes.size() > 0:
		_dialogue_system = nodes[0]
		_dialogue_system.dialogue_started.connect(_on_dialogue_started)
		_dialogue_system.dialogue_ended.connect(_on_dialogue_ended)


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	# Semi-transparent overlay top portion
	var top_dim := ColorRect.new()
	top_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_dim.color = Color(0, 0, 0, 0.3)
	top_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(top_dim)

	# Dialogue box at bottom
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.custom_minimum_size = Vector2(480, 90)
	box.position = Vector2(0, -90)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	box.add_theme_stylebox_override("panel", style)
	_panel.add_child(box)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	box.add_child(hbox)

	# Portrait
	_portrait_rect = ColorRect.new()
	_portrait_rect.custom_minimum_size = Vector2(48, 48)
	_portrait_rect.color = Color(0.5, 0.4, 0.3)
	hbox.add_child(_portrait_rect)

	# Text area
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	_speaker_label = Label.new()
	_speaker_label.text = "NPC"
	_speaker_label.add_theme_font_size_override("font_size", 9)
	_speaker_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	text_vbox.add_child(_speaker_label)

	_text_label = Label.new()
	_text_label.text = ""
	_text_label.add_theme_font_size_override("font_size", 7)
	_text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text_label.custom_minimum_size = Vector2(350, 30)
	text_vbox.add_child(_text_label)

	# Choices
	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 2)
	text_vbox.add_child(_choices_container)


func _process(delta: float) -> void:
	if not _is_showing:
		return

	# Typewriter effect
	if _displayed_chars < _full_text.length():
		_typewriter_timer += delta * TYPE_SPEED
		while _typewriter_timer >= 1.0 and _displayed_chars < _full_text.length():
			_displayed_chars += 1
			_typewriter_timer -= 1.0
		_text_label.text = _full_text.substr(0, _displayed_chars)

		# Skip on click
		if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact"):
			_displayed_chars = _full_text.length()
			_text_label.text = _full_text
			_show_choices()


func _on_dialogue_started(_npc_id: String) -> void:
	_is_showing = true
	_panel.visible = true
	get_tree().paused = true
	_show_current_node()


func _on_dialogue_ended(_npc_id: String) -> void:
	_is_showing = false
	_panel.visible = false
	get_tree().paused = false


func _show_current_node() -> void:
	if not _dialogue_system:
		return

	var node: Dictionary = _dialogue_system.get_current_node()
	if node.is_empty():
		_dialogue_system.end_dialogue()
		return

	# Set portrait color
	_portrait_rect.color = node.get("portrait_color", Color(0.5, 0.5, 0.5))

	# Set speaker
	_speaker_label.text = node.get("speaker", "???")

	# Start typewriter
	_full_text = node.get("text", "")
	_displayed_chars = 0
	_typewriter_timer = 0.0
	_text_label.text = ""

	# Clear old choices
	for child in _choices_container.get_children():
		child.queue_free()

	AudioManager.play_sfx("click")


func _show_choices() -> void:
	if not _dialogue_system:
		return

	# Clear old
	for child in _choices_container.get_children():
		child.queue_free()

	var choices: Array[Dictionary] = _dialogue_system.get_available_choices()

	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "> " + choice.text
		btn.add_theme_font_size_override("font_size", 7)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.05, 0.05, 0.08)
		btn_style.border_color = Color(0.3, 0.3, 0.4)
		btn_style.set_border_width_all(0)
		btn_style.set_content_margin_all(2)
		btn.add_theme_stylebox_override("normal", btn_style)

		# Color based on condition type
		var condition: String = choice.get("condition", "")
		if condition.begins_with("emotion_"):
			btn.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
		elif condition.begins_with("morality_"):
			btn.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		elif condition.begins_with("skill_"):
			btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))

		var idx := i
		btn.pressed.connect(func() -> void: _on_choice(idx))
		_choices_container.add_child(btn)


func _on_choice(idx: int) -> void:
	if not _dialogue_system:
		return
	_dialogue_system.make_choice(idx)

	# Check if dialogue continues
	if _dialogue_system.is_active:
		_show_current_node()
