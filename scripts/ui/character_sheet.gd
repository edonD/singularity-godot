extends CanvasLayer

## Character Sheet — full stat display. Press C to toggle.
## Shows: stats, background, emotions, morality, injuries, equipment, dilemma history.

var _panel: Control
var _is_open: bool = false
var _content: VBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C:
			_toggle()
			get_viewport().set_input_as_handled()


func _toggle() -> void:
	_is_open = not _is_open
	_panel.visible = _is_open
	if _is_open:
		_refresh()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0.02, 0.75)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(overlay)

	var main := PanelContainer.new()
	main.set_anchors_preset(Control.PRESET_CENTER)
	main.custom_minimum_size = Vector2(420, 240)
	main.position = Vector2(-210, -120)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.95)
	style.border_color = Color(0.4, 0.5, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	main.add_theme_stylebox_override("panel", style)
	_panel.add_child(main)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 3)
	scroll.add_child(_content)


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var s := GameManager.player_stats

	# Title
	_add_header("DR. KAEL MORROW — CHARACTER SHEET", Color(0.9, 0.85, 0.6))
	_add_label("[C] Close", Color(0.5, 0.5, 0.5), 6)

	# Background
	var bg_name: String = s.get("background", "soldier")
	_add_header("Background: %s" % bg_name.capitalize(), Color(0.7, 0.7, 0.8), 9)

	# Core Stats — two columns
	_add_header("— STATS —", Color(0.6, 0.8, 0.6), 8)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 12)
	stats_grid.add_theme_constant_override("v_separation", 1)
	_content.add_child(stats_grid)

	_add_stat_pair(stats_grid, "Level", str(s.level))
	_add_stat_pair(stats_grid, "XP", "%d/%d" % [s.xp, s.xp_to_next])
	_add_stat_pair(stats_grid, "HP", "%d/%d" % [s.hp, s.max_hp])
	_add_stat_pair(stats_grid, "Stamina", "%d/%d" % [int(s.stamina), int(s.max_stamina)])
	_add_stat_pair(stats_grid, "Attack", str(s.attack))
	_add_stat_pair(stats_grid, "Defense", str(s.defense))
	_add_stat_pair(stats_grid, "Speed", str(int(s.speed)))
	_add_stat_pair(stats_grid, "Crit", "%d%%" % int(s.crit_chance * 100))
	_add_stat_pair(stats_grid, "Hunger", "%d/%d" % [int(s.hunger), int(s.max_hunger)])
	_add_stat_pair(stats_grid, "Thirst", "%d/%d" % [int(s.thirst), int(s.max_thirst)])
	_add_stat_pair(stats_grid, "Day", str(GameManager.day))
	_add_stat_pair(stats_grid, "Kills", str(GameManager.kills))

	# Emotional State
	_add_header("— EMOTIONAL STATE —", Color(0.6, 0.7, 0.9), 8)
	var emo := GameManager.emotional_state
	var emo_grid := GridContainer.new()
	emo_grid.columns = 4
	emo_grid.add_theme_constant_override("h_separation", 8)
	_content.add_child(emo_grid)

	var emo_colors := {
		"fear": Color(0.8, 0.6, 0.2),
		"determination": Color(0.3, 0.7, 0.9),
		"despair": Color(0.5, 0.3, 0.5),
		"hope": Color(0.4, 0.8, 0.4),
	}
	for key: String in emo:
		_add_stat_pair(emo_grid, key.capitalize(), str(emo[key]) + "/100", emo_colors.get(key, Color.WHITE))

	# Morality
	_add_header("— MORALITY —", Color(0.8, 0.7, 0.5), 8)
	var mor := GameManager.morality
	var mor_hbox := HBoxContainer.new()
	mor_hbox.add_theme_constant_override("separation", 16)
	_content.add_child(mor_hbox)

	for key: String in mor:
		var lbl := Label.new()
		lbl.text = "%s: %d" % [key.capitalize(), mor[key]]
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
		mor_hbox.add_child(lbl)

	# Injuries
	var survival := get_tree().get_first_node_in_group("survival")
	if survival and survival.injuries.size() > 0:
		_add_header("— INJURIES —", Color(0.9, 0.3, 0.3), 8)
		for inj in survival.injuries:
			var inj_text := "%s (severity %d, %ds remaining)" % [
				inj.type.replace("_", " ").capitalize(),
				inj.severity,
				int(inj.timer),
			]
			_add_label(inj_text, Color(0.8, 0.4, 0.3), 6)

	# Survival
	if survival:
		_add_header("— SURVIVAL —", Color(0.7, 0.6, 0.5), 8)
		_add_label("Temperature: %d° (%s)" % [int(survival.body_temp),
			"Freezing!" if survival.body_temp < 20 else "Cold" if survival.body_temp < 35 else "Comfortable" if survival.body_temp < 70 else "Hot" if survival.body_temp < 85 else "Burning!"],
			Color(0.6, 0.6, 0.65), 6)
		_add_label("Sleep: %d%% (%s)" % [int(survival.sleep_level),
			"Collapsing!" if survival.sleep_level < 10 else "Hallucinating" if survival.sleep_level < 20 else "Exhausted" if survival.sleep_level < 40 else "Tired" if survival.sleep_level < 60 else "Rested"],
			Color(0.6, 0.6, 0.65), 6)

	# NEXUS Awareness
	_add_header("— NEXUS AWARENESS —", Color(0.5, 0.3, 0.7), 8)
	var awareness := GameManager.nexus_awareness
	var awareness_desc := "Unknown" if awareness < 10 else "Monitored" if awareness < 30 else "Tracked" if awareness < 60 else "Hunted" if awareness < 80 else "PRIORITY TARGET"
	_add_label("Threat Level: %d%% — %s" % [int(awareness), awareness_desc],
		Color(0.7, 0.4, 0.7) if awareness > 50 else Color(0.5, 0.5, 0.6), 7)

	# Dilemma History
	if GameManager.dilemma_history.size() > 0:
		_add_header("— CHOICES MADE —", Color(0.7, 0.6, 0.4), 8)
		for entry in GameManager.dilemma_history:
			_add_label("Day %d: %s — chose %s" % [entry.day, entry.id.replace("_", " "), entry.choice],
				Color(0.5, 0.5, 0.5), 6)


func _add_header(text: String, color: Color, size: int = 10) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)


func _add_label(text: String, color: Color, size: int = 7) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(label)


func _add_stat_pair(grid: GridContainer, key: String, value: String, color: Color = Color(0.7, 0.7, 0.7)) -> void:
	var key_label := Label.new()
	key_label.text = key + ":"
	key_label.add_theme_font_size_override("font_size", 7)
	key_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	grid.add_child(key_label)

	var val_label := Label.new()
	val_label.text = value
	val_label.add_theme_font_size_override("font_size", 7)
	val_label.add_theme_color_override("font_color", color)
	grid.add_child(val_label)
