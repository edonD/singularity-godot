extends Control

## Character Background Selection — shown when starting a new game.
## Choose Soldier, Scientist, or Survivalist. Each has different stats + unique ability.

signal background_chosen(bg: String)

var _selected: String = ""

const BACKGROUNDS := {
	"soldier": {
		"name": "SOLDIER",
		"subtitle": "Former military. Combat is second nature.",
		"desc": "+5 Attack, +3 Defense, +20 Max HP\nUnique: War Cry — frighten nearby enemies",
		"stats": "ATK 15 | DEF 8 | HP 120",
		"color": Color(0.9, 0.3, 0.2),
		"icon_points": [
			Vector2(0, -8), Vector2(-6, 4), Vector2(-2, 4),
			Vector2(-2, 8), Vector2(2, 8), Vector2(2, 4),
			Vector2(6, 4),
		],
	},
	"scientist": {
		"name": "SCIENTIST",
		"subtitle": "Ex-AI researcher. You understand NEXUS.",
		"desc": "+10% Crit Chance, +20 Max Stamina\nUnique: Analyze — scan enemy weaknesses",
		"stats": "CRIT 20% | STA 120 | Insight",
		"color": Color(0.3, 0.6, 0.9),
		"icon_points": [
			Vector2(-4, -8), Vector2(-4, 8), Vector2(4, 8),
			Vector2(4, -8), Vector2(-2, -8), Vector2(0, -4),
			Vector2(2, -8),
		],
	},
	"survivalist": {
		"name": "SURVIVALIST",
		"subtitle": "Off-grid for years. The wild is home.",
		"desc": "+30 Max Hunger/Thirst, +15 Speed\nUnique: Forage — find food/water anywhere",
		"stats": "SPD 135 | HNG 130 | THR 130",
		"color": Color(0.3, 0.7, 0.3),
		"icon_points": [
			Vector2(0, -8), Vector2(-6, 0), Vector2(-3, 0),
			Vector2(-5, 8), Vector2(0, 3), Vector2(5, 8),
			Vector2(3, 0), Vector2(6, 0),
		],
	},
}

var _cards: Dictionary = {} # bg_name -> PanelContainer
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

	# Title
	var title := Label.new()
	title.text = "WHO WERE YOU BEFORE THE FALL?"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-140, 20)
	title.custom_minimum_size = Vector2(280, 20)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Your past shapes your survival"
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-140, 38)
	subtitle.custom_minimum_size = Vector2(280, 12)
	add_child(subtitle)

	# Cards container
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.custom_minimum_size = Vector2(420, 160)
	hbox.position = Vector2(-210, -70)
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	for bg_key: String in BACKGROUNDS:
		var data: Dictionary = BACKGROUNDS[bg_key]
		var card := _build_card(bg_key, data)
		hbox.add_child(card)
		_cards[bg_key] = card


func _build_card(bg_key: String, data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 155)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09)
	style.border_color = data.color * 0.5
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Class name
	var name_label := Label.new()
	name_label.text = data.name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", data.color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Subtitle
	var sub := Label.new()
	sub.text = data.subtitle
	sub.add_theme_font_size_override("font_size", 6)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(sub)

	# Stats preview
	var stats := Label.new()
	stats.text = data.stats
	stats.add_theme_font_size_override("font_size", 6)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)

	# Description
	var desc := Label.new()
	desc.text = data.desc
	desc.add_theme_font_size_override("font_size", 6)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Select button
	var btn := Button.new()
	btn.text = "CHOOSE"
	btn.add_theme_font_size_override("font_size", 9)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = data.color * 0.3
	btn_style.border_color = data.color * 0.7
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(2)
	btn_style.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)
	var key := bg_key
	btn.pressed.connect(func() -> void: _on_choose(key))
	vbox.add_child(btn)

	return panel


func _on_choose(bg_key: String) -> void:
	_selected = bg_key
	GameManager.apply_background(bg_key)
	background_chosen.emit(bg_key)

	# Transition to game
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	)


func _generate_particles() -> void:
	for i in 30:
		_particles.append({
			"pos": Vector2(randf() * 480, randf() * 270),
			"vel": Vector2(randf_range(-3, 3), randf_range(-5, -1)),
			"size": randf_range(1, 2),
			"color": Color(0.15, randf_range(0.2, 0.5), randf_range(0.3, 0.6), randf_range(0.1, 0.4))
		})


func _process(delta: float) -> void:
	for p in _particles:
		p.pos += p.vel * delta
		if p.pos.y < -5:
			p.pos.y = 275
			p.pos.x = randf() * 480
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		draw_rect(Rect2(p.pos, Vector2(p.size, p.size)), p.color)
