extends Node

## Camera manager — screen shake and effects.

var _camera: Camera2D = null
var _shake_amount: float = 0.0
var _shake_decay: float = 8.0
var _trauma: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO


func register_camera(camera: Camera2D) -> void:
	_camera = camera
	_original_offset = camera.offset


func shake(amount: float = 4.0, decay: float = 8.0) -> void:
	_trauma = minf(_trauma + amount / 10.0, 1.0)
	_shake_amount = amount
	_shake_decay = decay


func _process(delta: float) -> void:
	if not _camera:
		return

	if _trauma > 0.0:
		_trauma = maxf(_trauma - _shake_decay * delta, 0.0)
		var shake_val := _trauma * _trauma # Quadratic for better feel
		var offset := Vector2(
			randf_range(-1.0, 1.0) * _shake_amount * shake_val,
			randf_range(-1.0, 1.0) * _shake_amount * shake_val
		)
		_camera.offset = _original_offset + offset
	else:
		_camera.offset = _original_offset
