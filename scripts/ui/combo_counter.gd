extends CanvasLayer

## Combo counter — tracks consecutive hits and displays multiplier.

var _combo: int = 0
var _combo_timer: float = 0.0
var _label: Label
var _best_combo: int = 0

const COMBO_TIMEOUT := 2.0


func _ready() -> void:
	layer = 16

	_label = Label.new()
	_label.position = Vector2(200, 40)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	_label.visible = false
	add_child(_label)
	add_to_group("combo_counter")


func _process(delta: float) -> void:
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_reset_combo()

	# Listen for hits via GameManager hitstop signal
	pass


func register_hit() -> void:
	_combo += 1
	_combo_timer = COMBO_TIMEOUT
	if _combo > _best_combo:
		_best_combo = _combo

	if _combo >= 3:
		_label.visible = true
		_label.text = "%dx COMBO!" % _combo
		_label.modulate = Color.WHITE

		# Scale pop effect
		_label.scale = Vector2(1.3, 1.3)
		var tween := create_tween()
		tween.tween_property(_label, "scale", Vector2(1.0, 1.0), 0.15)

		# Color based on combo size
		if _combo >= 10:
			_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # Red
		elif _combo >= 7:
			_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2)) # Orange
		elif _combo >= 5:
			_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Yellow
		else:
			_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8)) # White


func _reset_combo() -> void:
	_combo = 0
	_label.visible = false
