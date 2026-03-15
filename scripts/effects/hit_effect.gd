extends Node2D

## Hit flash effect — a brief white flash at impact point.

var _timer: float = 0.1
var _size: float = 8.0
var _color: Color = Color(1, 1, 1, 0.9)


func setup(pos: Vector2, size: float = 8.0, color: Color = Color(1, 1, 1, 0.9)) -> void:
	global_position = pos
	_size = size
	_color = color


func _process(delta: float) -> void:
	_timer -= delta
	_size *= 1.1
	_color.a -= delta * 8.0
	queue_redraw()
	if _timer <= 0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _size, _color)
