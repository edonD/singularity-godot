extends CanvasLayer

## Level-up screen — choose a stat bonus when leveling up.

var _panel: Control
var _is_showing: bool = false
var _last_level: int = 1

var stat_options: Array[Dictionary] = [
	{"name": "Vitality", "desc": "+20 Max HP", "stat": "max_hp", "amount": 20, "color": Color(0.8, 0.2, 0.2)},
	{"name": "Endurance", "desc": "+15 Max Stamina", "stat": "max_stamina", "amount": 15.0, "color": Color(0.2, 0.7, 0.3)},
	{"name": "Strength", "desc": "+4 Attack", "stat": "attack", "amount": 4, "color": Color(0.8, 0.6, 0.2)},
	{"name": "Toughness", "desc": "+3 Defense", "stat": "defense", "amount": 3, "color": Color(0.4, 0.4, 0.6)},
	{"name": "Precision", "desc": "+5% Crit Chance", "stat": "crit_chance", "amount": 0.05, "color": Color(0.8, 0.8, 0.2)},
	{"name": "Swiftness", "desc": "+15 Speed", "stat": "speed", "amount": 15.0, "color": Color(0.3, 0.6, 0.8)},
]


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_panel.visible = false


func _process(_delta: float) -> void:
	var current_level: int = GameManager.player_stats.level
	if current_level > _last_level and not _is_showing:
		_last_level = current_level
		_show_level_up()


func _build_panel() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0.05, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(overlay)


func _show_level_up() -> void:
	_is_showing = true
	_panel.visible = true
	get_tree().paused = true

	# Clear old buttons
	for child in _panel.get_children():
		if child is PanelContainer:
			child.queue_free()

	# Pick 3 random options
	var options := stat_options.duplicate()
	options.shuffle()
	var picks := options.slice(0, 3)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(280, 180)
	vbox.position = Vector2(-140, -90)
	vbox.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "LEVEL UP! (Lv %d)" % GameManager.player_stats.level
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose an upgrade:"
	subtitle.add_theme_font_size_override("font_size", 8)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	for option in picks:
		var btn := Button.new()
		btn.text = "%s — %s" % [option.name, option.desc]
		btn.add_theme_font_size_override("font_size", 9)

		var opt: Dictionary = option # capture
		btn.pressed.connect(func() -> void:
			_apply_upgrade(opt)
		)
		vbox.add_child(btn)

	var container := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	style.border_color = Color(0.4, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", style)
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.custom_minimum_size = Vector2(280, 180)
	container.position = Vector2(-140, -90)
	container.add_child(vbox)
	_panel.add_child(container)

	AudioManager.play_sfx("levelup")


func _apply_upgrade(option: Dictionary) -> void:
	var s := GameManager.player_stats
	var stat_name: String = option.stat
	if s.has(stat_name):
		if option.amount is float:
			s[stat_name] = s[stat_name] + option.amount
		else:
			s[stat_name] = s[stat_name] + option.amount

	# Heal on level up
	s.hp = s.max_hp

	AudioManager.play_sfx("pickup")
	_panel.visible = false
	_is_showing = false
	get_tree().paused = false
