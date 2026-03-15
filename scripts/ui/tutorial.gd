extends CanvasLayer

## Tutorial hints — shows contextual tips early in the game.

var _shown_hints: Dictionary = {}
var _hint_label: Label
var _hint_timer: float = 0.0
var _check_timer: float = 0.0


func _ready() -> void:
	layer = 19
	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.position = Vector2(60, -40)
	_hint_label.add_theme_font_size_override("font_size", 8)
	_hint_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.visible = false
	add_child(_hint_label)


func _process(delta: float) -> void:
	if _hint_timer > 0:
		_hint_timer -= delta
		if _hint_timer <= 0:
			_hint_label.visible = false

	_check_timer += delta
	if _check_timer < 2.0:
		return
	_check_timer = 0.0

	_check_hints()


func _check_hints() -> void:
	var s := GameManager.player_stats

	if not _shown_hints.get("move", false) and GameManager.day == 1 and GameManager.time_of_day < 0.05:
		_show_hint("move", "WASD to move. Left Shift to sprint. Space to dodge.")

	if not _shown_hints.get("attack", false) and GameManager.kills == 0:
		var enemy_count := get_tree().get_nodes_in_group("enemies").size()
		if enemy_count > 0:
			_show_hint("attack", "Left Click for melee (3-hit combo). Right Click to shoot arrows.")

	if not _shown_hints.get("inventory", false) and GameManager.kills >= 2:
		_show_hint("inventory", "Press I to open Inventory and Crafting.")

	if not _shown_hints.get("terminal", false) and GameManager.kills >= 5:
		_show_hint("terminal", "Look for terminals (glowing screens). Press E to interact.")

	if not _shown_hints.get("survival", false) and s.hunger < 70:
		_show_hint("survival", "Watch your Hunger and Thirst! Use food items from inventory.")

	if not _shown_hints.get("ability", false) and s.level >= 3:
		_show_hint("ability", "NEW ABILITY! Press 1 for EMP Pulse.")

	if not _shown_hints.get("night", false) and GameManager.is_night and GameManager.day == 1:
		_show_hint("night", "Night falls. Enemies are more aggressive in the dark.")


func _show_hint(hint_id: String, text: String) -> void:
	_shown_hints[hint_id] = true
	_hint_label.text = text
	_hint_label.visible = true
	_hint_timer = 5.0
	_hint_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_hint_label, "modulate:a", 1.0, 0.3)
