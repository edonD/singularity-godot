extends Node2D

## Attack trail — arc visual during melee swings.

var _points: Array[Dictionary] = []
var _timer: float = 0.2
var arc_color: Color = Color(0.9, 0.9, 1.0, 0.6)
var arc_direction: Vector2 = Vector2.RIGHT


func setup(pos: Vector2, direction: Vector2, color: Color = Color(0.9, 0.9, 1.0, 0.6)) -> void:
	global_position = pos
	arc_direction = direction
	arc_color = color

	# Generate arc points
	var perp := Vector2(-direction.y, direction.x)
	for i in 8:
		var t := float(i) / 7.0
		var angle := (t - 0.5) * 2.0
		var point := direction * 14.0 + perp * angle * 12.0
		_points.append({
			"pos": point,
			"alpha": 1.0 - abs(t - 0.5) * 1.5
		})


func _process(delta: float) -> void:
	_timer -= delta
	for p in _points:
		p.alpha -= delta * 5.0
	queue_redraw()
	if _timer <= 0:
		queue_free()


func _draw() -> void:
	for i in range(1, _points.size()):
		var p0: Dictionary = _points[i - 1]
		var p1: Dictionary = _points[i]
		if p0.alpha > 0 and p1.alpha > 0:
			var c := arc_color
			c.a *= minf(p0.alpha, p1.alpha)
			draw_line(p0.pos, p1.pos, c, 2.0)
