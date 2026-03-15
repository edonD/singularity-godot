extends CanvasLayer

## HUD — HP, Stamina, Hunger, Thirst bars, minimap, day counter, kill count.

var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var level_label: Label
var day_label: Label
var kills_label: Label
var xp_bar: ProgressBar
var _low_hp_flash: float = 0.0
var _vignette: ColorRect
var emotion_label: Label
var background_label: Label
var temp_bar: ProgressBar
var sleep_bar: ProgressBar
var injury_label: Label


func _ready() -> void:
	layer = 10
	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	# Main container
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	# Top row - stats
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(top_hbox)

	# Left side - HP and Stamina
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 2)
	left_vbox.custom_minimum_size = Vector2(100, 0)
	top_hbox.add_child(left_vbox)

	hp_bar = _create_bar("HP", Color(0.8, 0.15, 0.15), 100)
	left_vbox.add_child(hp_bar)

	stamina_bar = _create_bar("ST", Color(0.2, 0.7, 0.3), 100)
	left_vbox.add_child(stamina_bar)

	xp_bar = _create_bar("XP", Color(0.3, 0.4, 0.9), 100)
	left_vbox.add_child(xp_bar)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	# Right side - survival stats
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 2)
	right_vbox.custom_minimum_size = Vector2(80, 0)
	top_hbox.add_child(right_vbox)

	hunger_bar = _create_bar("HN", Color(0.85, 0.6, 0.2), 100)
	right_vbox.add_child(hunger_bar)

	thirst_bar = _create_bar("TH", Color(0.2, 0.5, 0.85), 100)
	right_vbox.add_child(thirst_bar)

	temp_bar = _create_bar("TMP", Color(0.8, 0.5, 0.2), 100)
	right_vbox.add_child(temp_bar)

	sleep_bar = _create_bar("SLP", Color(0.5, 0.4, 0.7), 100)
	right_vbox.add_child(sleep_bar)

	injury_label = Label.new()
	injury_label.text = ""
	injury_label.add_theme_font_size_override("font_size", 6)
	injury_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	right_vbox.add_child(injury_label)

	# Bottom info
	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_spacer)

	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(bottom_hbox)

	level_label = Label.new()
	level_label.text = "LV 1"
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	bottom_hbox.add_child(level_label)

	day_label = Label.new()
	day_label.text = "Day 1"
	day_label.add_theme_font_size_override("font_size", 10)
	day_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	bottom_hbox.add_child(day_label)

	kills_label = Label.new()
	kills_label.text = "Kills: 0"
	kills_label.add_theme_font_size_override("font_size", 10)
	kills_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	bottom_hbox.add_child(kills_label)

	# Ability cooldown display
	var ability_hbox := HBoxContainer.new()
	ability_hbox.add_theme_constant_override("separation", 6)
	bottom_hbox.add_child(ability_hbox)

	var ability_names: Array[String] = ["[1]EMP", "[2]Cloak", "[3]Shield"]
	for i in 3:
		var ab_label := Label.new()
		ab_label.name = "Ability" + str(i)
		ab_label.text = ability_names[i]
		ab_label.add_theme_font_size_override("font_size", 7)
		ab_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		ability_hbox.add_child(ab_label)

	# Emotional state + background
	emotion_label = Label.new()
	emotion_label.text = "Determined"
	emotion_label.add_theme_font_size_override("font_size", 7)
	emotion_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	bottom_hbox.add_child(emotion_label)

	background_label = Label.new()
	background_label.text = "[Soldier]"
	background_label.add_theme_font_size_override("font_size", 7)
	background_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	bottom_hbox.add_child(background_label)

	# Minimap
	var minimap_container := PanelContainer.new()
	minimap_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_container.custom_minimum_size = Vector2(60, 60)
	minimap_container.position = Vector2(-68, 4)
	var mm_style := StyleBoxFlat.new()
	mm_style.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	mm_style.border_color = Color(0.2, 0.3, 0.4)
	mm_style.set_border_width_all(1)
	mm_style.set_corner_radius_all(2)
	minimap_container.add_theme_stylebox_override("panel", mm_style)
	add_child(minimap_container)

	# Low HP vignette overlay
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.color = Color(0.5, 0, 0, 0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)


func _create_bar(label_text: String, color: Color, max_val: float) -> ProgressBar:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(80, 8)
	bar.max_value = max_val
	bar.value = max_val
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Style the bar
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.12)
	bg_style.border_color = Color(0.3, 0.3, 0.35)
	bg_style.set_border_width_all(1)
	bg_style.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("fill", fill_style)

	return bar


func _connect_signals() -> void:
	# Wait for player to be ready
	await get_tree().process_frame
	await get_tree().process_frame

	var player := GameManager.player
	if player:
		if player.has_signal("hp_changed"):
			player.hp_changed.connect(_on_hp_changed)
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("hunger_changed"):
			player.hunger_changed.connect(_on_hunger_changed)
		if player.has_signal("thirst_changed"):
			player.thirst_changed.connect(_on_thirst_changed)
		if player.has_signal("xp_changed"):
			player.xp_changed.connect(_on_xp_changed)

	GameManager.day_changed.connect(_on_day_changed)


func _process(_delta: float) -> void:
	kills_label.text = "Kills: " + str(GameManager.kills)

	# Update day label with time indicator
	var time_str := "Dawn" if GameManager.time_of_day < 0.1 else "Day" if GameManager.time_of_day < 0.35 else "Dusk" if GameManager.time_of_day < 0.45 else "Night" if GameManager.time_of_day < 0.85 else "Pre-Dawn"
	day_label.text = "Day %d | %s" % [GameManager.day, time_str]

	# Difficulty color on day label
	if GameManager.day >= 7:
		day_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	elif GameManager.day >= 4:
		day_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

	# Update emotional state display
	var dominant := GameManager.get_dominant_emotion()
	var emotion_colors := {
		"fear": Color(0.8, 0.6, 0.2),
		"determination": Color(0.3, 0.7, 0.9),
		"despair": Color(0.5, 0.3, 0.5),
		"hope": Color(0.4, 0.8, 0.4),
	}
	emotion_label.text = dominant.capitalize()
	emotion_label.add_theme_color_override("font_color", emotion_colors.get(dominant, Color(0.6, 0.6, 0.6)))

	var bg_name: String = GameManager.player_stats.get("background", "soldier")
	background_label.text = "[%s]" % bg_name.capitalize()

	# Update survival bars
	var survival := get_tree().get_first_node_in_group("survival")
	if survival:
		temp_bar.value = survival.body_temp
		# Color temp bar based on danger
		if survival.body_temp < 20.0:
			temp_bar.get_theme_stylebox("fill").bg_color = Color(0.3, 0.5, 0.9) # Cold blue
		elif survival.body_temp > 80.0:
			temp_bar.get_theme_stylebox("fill").bg_color = Color(0.9, 0.3, 0.2) # Hot red
		else:
			temp_bar.get_theme_stylebox("fill").bg_color = Color(0.8, 0.5, 0.2) # Normal

		sleep_bar.value = survival.sleep_level

		# Injury display
		if survival.injuries.size() > 0:
			var inj_names: Array[String] = []
			for inj in survival.injuries:
				inj_names.append(inj.type.replace("_", " "))
			injury_label.text = "! " + ", ".join(inj_names)
		else:
			injury_label.text = ""

	# Low HP vignette pulse
	var s := GameManager.player_stats
	if s.hp < s.max_hp * 0.3:
		_low_hp_flash += _delta_safe() * 3.0
		_vignette.color.a = (sin(_low_hp_flash) * 0.5 + 0.5) * 0.15
	else:
		_vignette.color.a = 0.0


func _delta_safe() -> float:
	var d := get_process_delta_time()
	return d if d > 0 else 0.016


func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _on_stamina_changed(stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina


func _on_hunger_changed(hunger: float) -> void:
	hunger_bar.value = hunger


func _on_thirst_changed(thirst: float) -> void:
	thirst_bar.value = thirst


func _on_xp_changed(xp: int, xp_to_next: int, level: int) -> void:
	xp_bar.max_value = xp_to_next
	xp_bar.value = xp
	level_label.text = "LV " + str(level)


func _on_day_changed(day: int) -> void:
	day_label.text = "Day " + str(day)
