extends CanvasLayer

## Shows mission update notifications as toast messages.

var _vbox: VBoxContainer


func _ready() -> void:
	layer = 18

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	margin.custom_minimum_size = Vector2(200, 0)
	margin.position = Vector2(-210, 8)
	add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(_vbox)

	# Connect to mission manager after it's ready
	await get_tree().process_frame
	await get_tree().process_frame
	var mm := get_tree().get_first_node_in_group("mission_manager")
	if mm:
		if mm.has_signal("mission_updated"):
			mm.mission_updated.connect(_on_mission_updated)


func _on_mission_updated(_mission_id: String, text: String) -> void:
	_show_toast(text)


func _show_toast(text: String) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	style.border_color = Color(0.3, 0.5, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)

	_vbox.add_child(panel)

	# Fade out
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(panel.queue_free)
