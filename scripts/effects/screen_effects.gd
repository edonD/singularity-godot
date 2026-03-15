extends CanvasLayer

## Screen effects — damage flash, level up flash, etc.

var _flash_rect: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(0, 0, 0, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)


func flash_color(color: Color, duration: float = 0.15) -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration)


func flash_damage() -> void:
	flash_color(Color(0.5, 0, 0, 0.3), 0.2)


func flash_heal() -> void:
	flash_color(Color(0, 0.5, 0, 0.2), 0.3)


func flash_level_up() -> void:
	flash_color(Color(1.0, 0.9, 0.4, 0.3), 0.5)
